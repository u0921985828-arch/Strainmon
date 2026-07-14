#!/usr/bin/env node
/* ============================================================
   Strainmon — generador de sprites con Gemini
   Lee la API key SOLO desde .secrets/gemini.key o env GEMINI_API_KEY.
   Nunca imprime la key ni la escribe en ningún artefacto versionado.
   Uso:  node scripts/gen-sprites.mjs <archivo-de-prompts.json> [outDir]
   ============================================================ */
import fs from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');

function loadKey() {
  if (process.env.GEMINI_API_KEY && process.env.GEMINI_API_KEY.trim()) return process.env.GEMINI_API_KEY.trim();
  const f = path.join(ROOT, '.secrets', 'gemini.key');
  if (fs.existsSync(f)) return fs.readFileSync(f, 'utf8').trim();
  console.error('❌ No hay key. Crea .secrets/gemini.key o exporta GEMINI_API_KEY.');
  process.exit(1);
}

const MODEL = process.env.GEMINI_IMAGE_MODEL || 'gemini-2.5-flash-image';
// Sufijo canónico universal: sujeto único centrado + fondo magenta (chroma en post-proceso).
const SUFFIX = ' Un único elemento centrado y completo, sin recortar por los bordes.'
  + ' Fondo de un color liso magenta puro #FF00FF que rellena todo el lienzo, sin escena,'
  + ' sin paisaje, sin suelo, sin sombra proyectada, sin texto ni marca de agua.';
const API = (m, key) => `https://generativelanguage.googleapis.com/v1beta/models/${m}:generateContent?key=${key}`;

async function listModels(key) {
  const r = await fetch(`https://generativelanguage.googleapis.com/v1beta/models?key=${key}`);
  const j = await r.json();
  if (!r.ok) throw new Error('list ' + r.status + ' ' + JSON.stringify(j.error || j));
  return (j.models || []).map(m => m.name.replace('models/', ''));
}

async function genImage(key, text, model, refBuf) {
  // refBuf: imagen de referencia opcional (para mantener consistencia de personaje
  // entre direcciones). Se envía como parte inlineData antes del texto.
  const parts = [];
  if (refBuf) parts.push({ inlineData: { mimeType: 'image/png', data: refBuf.toString('base64') } });
  parts.push({ text });
  const body = {
    contents: [{ parts }],
    generationConfig: { responseModalities: ['IMAGE'] },
  };
  const r = await fetch(API(model, key), {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
  });
  const j = await r.json();
  if (!r.ok) throw new Error('gen ' + r.status + ' ' + JSON.stringify(j.error || j).slice(0, 300));
  const respParts = j.candidates?.[0]?.content?.parts || [];
  const img = respParts.find(p => p.inlineData?.data);
  if (!img) throw new Error('sin imagen en respuesta: ' + JSON.stringify(respParts).slice(0, 200));
  return Buffer.from(img.inlineData.data, 'base64');
}

async function main() {
  const key = loadKey();
  const promptsFile = process.argv[2];
  const outDir = path.resolve(process.argv[3] || path.join(ROOT, 'assets', 'gen'));
  fs.mkdirSync(outDir, { recursive: true });

  // Diagnóstico de conectividad + modelos (sin exponer la key)
  let models = [];
  try { models = await listModels(key); }
  catch (e) { console.error('❌ Fallo al listar modelos:', e.message); process.exit(1); }
  const imageModels = models.filter(m => /image|imagen/i.test(m));
  console.log('✅ Key válida. Modelos de imagen disponibles:', imageModels.join(', ') || '(ninguno detectado)');
  const model = imageModels.includes(MODEL) ? MODEL : (imageModels[0] || MODEL);
  console.log('→ Usando modelo:', model);

  if (!promptsFile) { console.log('ℹ️  Sin archivo de prompts: solo diagnóstico. Pasa un JSON [{name,prompt}] para generar.'); return; }
  const jobs = JSON.parse(fs.readFileSync(promptsFile, 'utf8'));
  const RESUME = process.env.GEN_RESUME === '1'; // salta los que ya existen
  for (const job of jobs) {
    try {
      const out = path.join(outDir, job.name.endsWith('.png') ? job.name : job.name + '.png');
      if (RESUME && fs.existsSync(out)) { console.log('↷ salto (existe):', job.name); continue; }
      // job.raw = usar el prompt tal cual (sin sufijo magenta); útil para láminas con fondo negro.
      const text = job.raw ? job.prompt : job.prompt + SUFFIX;
      // job.ref = nombre de archivo (en outDir) usado como imagen de referencia.
      let refBuf;
      if (job.ref) {
        const rp = path.isAbsolute(job.ref) ? job.ref : path.join(outDir, job.ref);
        if (fs.existsSync(rp)) refBuf = fs.readFileSync(rp);
        else console.warn('   (ref no encontrada, genero sin ella):', job.ref);
      }
      const buf = await genImage(key, text, model, refBuf);
      fs.writeFileSync(out, buf);
      console.log('🖼️  ', path.relative(ROOT, out), '(' + (buf.length / 1024).toFixed(1) + ' KB)' + (refBuf ? ' [ref]' : ''));
    } catch (e) {
      console.error('⚠️  ', job.name, '→', e.message);
    }
  }
}
main();

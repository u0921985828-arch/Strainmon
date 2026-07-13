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
const API = (m, key) => `https://generativelanguage.googleapis.com/v1beta/models/${m}:generateContent?key=${key}`;

async function listModels(key) {
  const r = await fetch(`https://generativelanguage.googleapis.com/v1beta/models?key=${key}`);
  const j = await r.json();
  if (!r.ok) throw new Error('list ' + r.status + ' ' + JSON.stringify(j.error || j));
  return (j.models || []).map(m => m.name.replace('models/', ''));
}

async function genImage(key, prompt, model) {
  const body = {
    contents: [{ parts: [{ text: prompt }] }],
    generationConfig: { responseModalities: ['IMAGE'] },
  };
  const r = await fetch(API(model, key), {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
  });
  const j = await r.json();
  if (!r.ok) throw new Error('gen ' + r.status + ' ' + JSON.stringify(j.error || j).slice(0, 300));
  const parts = j.candidates?.[0]?.content?.parts || [];
  const img = parts.find(p => p.inlineData?.data);
  if (!img) throw new Error('sin imagen en respuesta: ' + JSON.stringify(parts).slice(0, 200));
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
  for (const job of jobs) {
    try {
      const buf = await genImage(key, job.prompt, model);
      const out = path.join(outDir, job.name.endsWith('.png') ? job.name : job.name + '.png');
      fs.writeFileSync(out, buf);
      console.log('🖼️  ', path.relative(ROOT, out), '(' + (buf.length / 1024).toFixed(1) + ' KB)');
    } catch (e) {
      console.error('⚠️  ', job.name, '→', e.message);
    }
  }
}
main();

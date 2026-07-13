#!/usr/bin/env node
/* ============================================================
   Strainmon — re-embebe los PNG de assets/ como base64 en los
   módulos de arte (el juego renderiza SIEMPRE desde estos data-URI
   inline, no desde los ficheros en disco). Idempotente: un asset sin
   cambios produce el mismo base64 y no genera diff. Ejecutar tras
   editar/limpiar sprites para que el cambio llegue al juego.
   Uso:  node scripts/embed-assets.mjs
   ============================================================ */
import fs from 'node:fs';
import path from 'node:path';

// módulo JS  ->  carpeta de assets y prefijo de fichero (clave -> <prefijo><clave>.png)
const MODULES = [
  { js: 'src/sprites.js',  dir: 'assets/sprites', prefix: '' },
  { js: 'src/plantart.js', dir: 'assets/plants',  prefix: '' },
  { js: 'src/charart.js',  dir: 'assets/chars',   prefix: '' },
  { js: 'src/furniart.js', dir: 'assets/furni',   prefix: 'furni_' },
];

// captura:  clave (con o sin comillas)  :  "data:image/png;base64,<b64>"
const RE = /(["']?)([A-Za-z0-9_\-]+)\1(\s*:\s*"data:image\/png;base64,)([^"]*)(")/g;

let totalUpdated = 0;
for (const m of MODULES) {
  if (!fs.existsSync(m.js)) { console.warn('· sin módulo', m.js); continue; }
  let src = fs.readFileSync(m.js, 'utf8');
  let updated = 0, missing = 0;
  src = src.replace(RE, (whole, q, key, mid, oldB64, endq) => {
    const file = path.join(m.dir, m.prefix + key + '.png');
    if (!fs.existsSync(file)) { missing++; return whole; }
    const b64 = fs.readFileSync(file).toString('base64');
    if (b64 !== oldB64) updated++;
    return `${q}${key}${q}${mid}${b64}${endq}`;
  });
  fs.writeFileSync(m.js, src);
  totalUpdated += updated;
  console.log(`${m.js}: ${updated} sprite(s) actualizado(s)${missing ? `, ${missing} sin PNG en disco (sin tocar)` : ''}`);
}
console.log(`\nListo: ${totalUpdated} sprite(s) re-embebido(s).`);

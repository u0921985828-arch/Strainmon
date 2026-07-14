#!/usr/bin/env node
/* Build autocontenido: inlina assets/style.css y todos los src/*.js de
   index.html en un único HTML jugable. Salida: dist/Strainmon.html */
import fs from 'node:fs';
import path from 'node:path';
const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');

let html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');

// CSS
html = html.replace(/<link rel="stylesheet" href="([^"]+)"\s*\/>/g, (_m, href) => {
  const css = fs.readFileSync(path.join(ROOT, href), 'utf8');
  return `<style>\n${css}\n</style>`;
});

// JS (en orden de aparición)
html = html.replace(/<script src="([^"]+)"><\/script>/g, (_m, src) => {
  const js = fs.readFileSync(path.join(ROOT, src), 'utf8');
  return `<script>\n${js}\n</script>`;
});

const outDir = path.join(ROOT, 'dist');
fs.mkdirSync(outDir, { recursive: true });
const out = path.join(outDir, 'Strainmon.html');
fs.writeFileSync(out, html);
console.log(`✅ ${path.relative(ROOT, out)} — ${(Buffer.byteLength(html) / 1024 / 1024).toFixed(2)} MB`);

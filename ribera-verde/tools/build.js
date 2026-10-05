#!/usr/bin/env node
/*
  Ribera Verde — build
  Une src/shell.html + src/styles.css + src/js/*.js (en orden alfabético) y genera:
    1. index.html                       → juego completo, offline, fuentes embebidas. Doble clic y a jugar.
    2. dist/ribera-verde.artifact.html  → misma página en formato Artifact de Claude
                                          (sin <!doctype>/<head>/<body>, fuentes desde Google Fonts).
  Uso:  node tools/build.js
*/
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const read = (p, enc = 'utf8') => fs.readFileSync(path.join(ROOT, p), enc);

const shell = read('src/shell.html');
const css = read('src/styles.css');
const jsDir = path.join(ROOT, 'src/js');
const js = fs.readdirSync(jsDir).filter(f => f.endsWith('.js')).sort()
  .map(f => fs.readFileSync(path.join(jsDir, f), 'utf8')).join('');

// Reemplazo con función: el código contiene "$'" y "${", que String.replace interpretaría.
const artifact = shell.replace('/*@@CSS@@*/', () => css).replace('//@@JS@@', () => js);

// ---- versión standalone ----
const font = (file, family, weight) =>
  `@font-face{font-family:"${family}";font-style:normal;font-weight:${weight};font-display:swap;` +
  `src:url(data:font/woff2;base64,${read('assets/fonts/' + file, null).toString('base64')}) format("woff2")}`;
const fontCss = [
  font('pixelify-sans-latin-400-normal.woff2', 'Pixelify Sans', 400),
  font('pixelify-sans-latin-600-normal.woff2', 'Pixelify Sans', 600),
  font('press-start-2p-latin-400-normal.woff2', 'Press Start 2P', 400),
].join('\n');

const cut = artifact.indexOf('</style>') + '</style>'.length;
let head = artifact.slice(0, cut);
const body = artifact.slice(cut).replace(/^\n+/, '');
head = head.replace(/<link rel="preconnect"[^>]*>\n/g, '')
           .replace(/<link rel="stylesheet" href="https:\/\/fonts\.googleapis\.com[^>]*>\n/, () => `<style>\n${fontCss}\n</style>\n`);

const standalone =
`<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
${head}
</head>
<body>
${body.trimEnd()}
</body>
</html>
`;

fs.mkdirSync(path.join(ROOT, 'dist'), { recursive: true });
fs.writeFileSync(path.join(ROOT, 'dist/ribera-verde.artifact.html'), artifact);
fs.writeFileSync(path.join(ROOT, 'index.html'), standalone);
const kb = n => (n / 1024).toFixed(1) + ' KB';
console.log(`index.html                      ${kb(Buffer.byteLength(standalone))}`);
console.log(`dist/ribera-verde.artifact.html ${kb(Buffer.byteLength(artifact))}`);

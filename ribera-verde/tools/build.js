#!/usr/bin/env node
/*
  Ribera Verde — build
  Une src/shell.html + src/styles.css + src/js/*.js (en orden alfabético) y genera:
    1. index.html                       → juego completo, offline, fuentes embebidas. Doble clic y a jugar.
    2. dist/ribera-verde.artifact.html  → misma página en formato Artifact de Claude
                                          (sin <!doctype>/<head>/<body>, fuentes desde Google Fonts).
  Si existen assets/sprites/atlas.png y atlas.json (los genera tools/sprites/procesar.js --atlas),
  se incrustan como const ATLAS = { png, def }. Si no, const ATLAS = null y todo es procedural.
  Uso:  node tools/build.js [--atlas-dir dir] [--salida dir]
*/
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const read = (p, enc = 'utf8') => fs.readFileSync(path.join(ROOT, p), enc);
const argv = process.argv.slice(2), opt = (k, d) => { const i = argv.indexOf(k); return i >= 0 ? path.resolve(argv[i + 1]) : d; };
const ATLAS_DIR = opt('--atlas-dir', path.join(ROOT, 'assets', 'sprites'));
const SALIDA = opt('--salida', ROOT);

const shell = read('src/shell.html');
const css = read('src/styles.css');
const jsDir = path.join(ROOT, 'src/js');
const js = fs.readdirSync(jsDir).filter(f => f.endsWith('.js')).sort()
  .map(f => fs.readFileSync(path.join(jsDir, f), 'utf8')).join('');

// Reemplazo con función: el código contiene "$'" y "${", que String.replace interpretaría.
const atlasPng = path.join(ATLAS_DIR, 'atlas.png'), atlasJson = path.join(ATLAS_DIR, 'atlas.json');
let atlasJs = 'const ATLAS = null;', atlasInfo = 'sin atlas (arte procedural)';
if (fs.existsSync(atlasPng) && fs.existsSync(atlasJson)) {
  const def = JSON.parse(fs.readFileSync(atlasJson, 'utf8'));
  atlasJs = `const ATLAS = { png: 'data:image/png;base64,${fs.readFileSync(atlasPng).toString('base64')}', def: ${JSON.stringify(def)} };`;
  atlasInfo = `atlas: ${Object.keys(def.frames).length} fotogramas`;
}
const artifact = shell.replace('/*@@CSS@@*/', () => css).replace('//@@ATLAS@@', () => atlasJs).replace('//@@JS@@', () => js);

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
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover">
${head}
</head>
<body>
${body.trimEnd()}
</body>
</html>
`;

fs.mkdirSync(path.join(SALIDA, 'dist'), { recursive: true });
fs.writeFileSync(path.join(SALIDA, 'dist/ribera-verde.artifact.html'), artifact);
fs.writeFileSync(path.join(SALIDA, 'index.html'), standalone);
const kb = n => (n / 1024).toFixed(1) + ' KB';
console.log(`index.html                      ${kb(Buffer.byteLength(standalone))}`);
console.log(`dist/ribera-verde.artifact.html ${kb(Buffer.byteLength(artifact))}`);
console.log(atlasInfo);

#!/usr/bin/env node
/*
  Ribera Verde — plantas de la vista de carpa (1.8) a partir del arte de cepas de Strainmon (../assets/plants)
  Strainmon trae 18 cepas × 5 fases (SM-xxx_1..5: plántula, vegetativo temprano, vegetativo tardío, floración y cosecha),
  de 150 px de alto con su tiesto de barro. Aquí se quita el tiesto (el juego pinta la maceta de cada plaza),
  se reduce a la escala de la vista (×0,45: una planta lista mide como mucho ~56 px = 88 cm a 64 px/m)
  por media de área con alfa premultiplicado y se deja en art/crudo/plantas-vista/smNN-F/unica/00.png.
  Después: node tools/sprites/procesar.js plantas-vista --atlas

  Uso:  node tools/sprites/plantas-vista.js [--crudo dir]
*/
const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const ROOT = path.join(__dirname, '..', '..');
const SRC = path.join(ROOT, '..', 'assets', 'plants');
const args = process.argv.slice(2), ci = args.indexOf('--crudo');
const OUT = path.join(ci >= 0 ? path.resolve(args[ci + 1]) : path.join(ROOT, 'art', 'crudo'), 'plantas-vista');
const K = 0.45, N = 18, FASES = 5;

// barro del tiesto: rojo anaranjado, saturado y no muy oscuro
function barro(d, i) {
  if (d[i + 3] < 128) return false;
  const r = d[i] / 255, g = d[i + 1] / 255, b = d[i + 2] / 255, mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2, s = mx === mn ? 0 : (mx - mn) / (1 - Math.abs(2 * l - 1));
  let h = 0; if (mx !== mn) h = mx === r ? ((g - b) / (mx - mn)) % 6 : mx === g ? (b - r) / (mx - mn) + 2 : (r - g) / (mx - mn) + 4; h = (h * 60 + 360) % 360;
  return (h < 25 || h > 342) && s > 0.3 && l > 0.2 && d[i] > 90;
}
// fila del borde del tiesto: la primera del bloque de filas con barro que llega hasta abajo
function bordeTiesto(p) {
  const fila = y => { let n = 0; for (let x = 0; x < p.width; x++) if (barro(p.data, (y * p.width + x) * 4)) n++; return n; };
  let y = p.height - 1; while (y > 0 && !fila(y)) y--;
  while (y > 0 && fila(y)) y--;
  return y + 1;
}
// reducción por media de área (alfa premultiplicado) y alfa binario
function reducir(p, alto, k) {
  const W = Math.max(1, Math.round(p.width * k)), H = Math.max(1, Math.round(alto * k)), o = new PNG({ width: W, height: H });
  for (let oy = 0; oy < H; oy++) for (let ox = 0; ox < W; ox++) {
    const x0 = ox / k, x1 = (ox + 1) / k, y0 = oy / k, y1 = (oy + 1) / k; let a = 0, r = 0, g = 0, b = 0, w = 0;
    for (let y = Math.floor(y0); y < Math.min(alto, Math.ceil(y1)); y++) for (let x = Math.floor(x0); x < Math.min(p.width, Math.ceil(x1)); x++) {
      const f = (Math.min(x + 1, x1) - Math.max(x, x0)) * (Math.min(y + 1, y1) - Math.max(y, y0)); if (f <= 0) continue;
      const i = (y * p.width + x) * 4, al = p.data[i + 3] / 255; w += f; a += al * f; r += p.data[i] * al * f; g += p.data[i + 1] * al * f; b += p.data[i + 2] * al * f;
    }
    const j = (oy * W + ox) * 4; if (!w || a / w < 0.43) continue;
    o.data[j] = Math.round(r / a); o.data[j + 1] = Math.round(g / a); o.data[j + 2] = Math.round(b / a); o.data[j + 3] = 255;
  }
  return o;
}
fs.rmSync(OUT, { recursive: true, force: true });
let n = 0;
for (let i = 0; i < N; i++) for (let f = 1; f <= FASES; f++) {
  const src = path.join(SRC, `SM-${String(i).padStart(3, '0')}_${f}.png`), p = PNG.sync.read(fs.readFileSync(src));
  const o = reducir(p, bordeTiesto(p), K), d = path.join(OUT, `sm${String(i).padStart(2, '0')}-${f}`, 'unica');
  fs.mkdirSync(d, { recursive: true }); fs.writeFileSync(path.join(d, '00.png'), PNG.sync.write(o)); n++;
}
console.log(`plantas-vista: ${n} PNG en ${path.relative(ROOT, OUT)}`);

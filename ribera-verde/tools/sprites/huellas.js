#!/usr/bin/env node
/*
  Ribera Verde — huellas de las láminas de la vista B (plan de producción, §5 y §5.1, láminas 1-9)
  Cada lámina sale del arte procedural del motor (09b-carpa.js), a la medida real y en su rejilla de celdas, para pasarla
  a PixelLab como init_image. Como mucho 16 colores por lámina (si hay más, los raros pasan al más cercano); los
  cogollos de las plantas, en la rampa magenta.
  No pisa las huellas de la 1.8 (huella-carpas-mapa.png y compañía): las nuevas llevan -34 o -5 en el nombre.

  Uso:  node tools/build.js && node tools/sprites/huellas.js
  Sale: art/crudo/_ref/huella-{cuarto-cultivo-34,carpas-vista-34,carpas-mapa-5,focos-34,macetas-34,extras-34,plantas-34-<porte>}.png
*/
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..', '..');
const OUT = path.join(ROOT, 'art', 'crudo', '_ref');

(async () => {
  const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
  const page = await browser.newPage();
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.goto('file://' + path.join(ROOT, 'index.html') + '?arte=procedural');
  await page.waitForFunction(() => typeof mode !== 'undefined' && mode === 'title');

  const hojas = await page.evaluate(() => {
    // lámina de celdas cw × ch en cols columnas; cada sprite centrado y apoyado abajo (o colgado arriba, los focos)
    const lamina = (cw, ch, cols, sprites, arriba) => {
      const [c, x] = mkCanvas(cw * cols, ch * Math.ceil(sprites.length / cols));
      sprites.forEach((s, i) => x.drawImage(s, (i % cols) * cw + ((cw - s.width) >> 1), Math.floor(i / cols) * ch + (arriba ? 0 : ch - s.height)));
      return c;
    };
    // como mucho 16 colores: los que pasan se quedan los 16 más usados y el resto va al más cercano de ellos
    const dieciseis = c => {
      const x = c.getContext('2d'), im = x.getImageData(0, 0, c.width, c.height), d = im.data, n = new Map();
      for (let i = 0; i < d.length; i += 4) if (d[i + 3]) { d[i + 3] = 255; const k = (d[i] << 16) | (d[i + 1] << 8) | d[i + 2]; n.set(k, (n.get(k) || 0) + 1); }
      const antes = n.size;
      if (antes > 16) {
        const pal = [...n.entries()].sort((a, b) => b[1] - a[1]).slice(0, 16).map(([k]) => [k >> 16, (k >> 8) & 255, k & 255]);
        for (let i = 0; i < d.length; i += 4) if (d[i + 3]) {
          let m = pal[0], dm = 1e9; for (const p of pal) { const e = (p[0] - d[i]) ** 2 + (p[1] - d[i + 1]) ** 2 + (p[2] - d[i + 2]) ** 2; if (e < dm) { dm = e; m = p; } }
          d[i] = m[0]; d[i + 1] = m[1]; d[i + 2] = m[2];
        }
      }
      x.putImageData(im, 0, 0);
      return { png: c.toDataURL('image/png'), w: c.width, h: c.height, colores: Math.min(antes, 16), antes };
    };
    const MAG = '#ff00ff', out = {};
    out['huella-cuarto-cultivo-34'] = dieciseis(lamina(240, 160, 1, [cuarto34()]));
    out['huella-carpas-vista-34'] = dieciseis(lamina(104, 152, 5, Object.keys(CARPAS).map(carpa34)));
    out['huella-carpas-mapa-5'] = dieciseis(lamina(32, 48, 5, Object.keys(CARPAS).map(carpaMapa)));
    out['huella-focos-34'] = dieciseis(lamina(64, 16, 4, Object.keys(FOCOS).map(foco34), true));
    out['huella-macetas-34'] = dieciseis(lamina(24, 24, 4, Object.keys(MACETAS).map(maceta34)));
    out['huella-extras-34'] = dieciseis(lamina(60, 80, 4, ['vent', 'filtro', 'goteo', 'garrafas'].map(extra34)));
    for (const [po, n] of [['i', 'indica'], ['s', 'sativa'], ['h', 'hibrida']])
      out['huella-plantas-34-' + n] = dieciseis(lamina(48, 80, 5, [0, 1, 2, 3, 4].map(st => planta34(po, st, false, MAG))));
    return out;
  });

  fs.mkdirSync(OUT, { recursive: true });
  for (const [n, h] of Object.entries(hojas)) {
    fs.writeFileSync(path.join(OUT, n + '.png'), Buffer.from(h.png.split(',')[1], 'base64'));
    console.log(`  art/crudo/_ref/${n}.png · ${h.w}×${h.h} · ${h.colores} colores${h.antes > 16 ? ` (de ${h.antes})` : ''}`);
  }
  await browser.close();
  if (errors.length) { console.log('Errores:', errors); process.exit(1); }
})();

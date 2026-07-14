/* Retratos de diálogo = recorte de cabeza del personaje nuevo (front/south),
   recoloreados por rol para casar con el cuerpo. Genera src/faceart.js. */
import fs from 'node:fs'; import sharp from 'sharp';
const SRC = process.argv[2] || '/tmp/claude-0/-home-user-Strainmon/0f1a7ef5-8d47-53c6-8255-3b41a3c54115/scratchpad/char3/Personajes_para_juegos_retro_pixel_cannabis/rotations';
const OUT = 64;
const ROLES = {
  player: null, dealer: { hue: 265, saturation: 1.05 }, neighbor: { hue: 35, saturation: 1.1 },
  botanist: { hue: 190 }, merchant: { hue: 90, saturation: 1.05 }, customer1: { hue: 150 },
  customer2: { hue: 320, saturation: 1.05 }, walker: { hue: 20, saturation: 1.1 },
};
// caja de cabeza (medida sobre el bbox de contenido {left:52,top:36,w:36,h:69})
const HEAD = { left: 49, top: 33, width: 42, height: 42 };
const DATA = {};
for (const [role, mod] of Object.entries(ROLES)) {
  let img = sharp(`${SRC}/south.png`).extract(HEAD).resize({ width: OUT, height: OUT, kernel: 'nearest' });
  if (mod) img = img.modulate(mod);
  const buf = await img.png().toBuffer();
  DATA[role] = 'data:image/png;base64,' + buf.toString('base64');
}
const lines = Object.keys(DATA).map(k => `    "${k}": "${DATA[k]}",`).join('\n');
fs.writeFileSync('src/faceart.js', `/* STRAINMON — faceart.js (retratos de diálogo, recorte de cabeza del personaje nuevo, recolor por rol). Generado: scripts/build-faceart.mjs */
(function (PH) {
  'use strict';
  const DATA = {
${lines}
  };
  const images = {};
  function preload() { for (const k of Object.keys(DATA)) { const im = new Image(); im.src = DATA[k]; images[k] = im; } }
  function has(role) { return !!DATA[role]; }
  function uri(role) { return DATA[role] || null; }
  function img(role) { return images[role] || null; }
  PH.faceart = { DATA, preload, has, uri, img };
})(window.PH = window.PH || {});
`);
// preview montage
const sc = 3, names = Object.keys(DATA), comps = [];
for (let i = 0; i < names.length; i++) { const b64 = DATA[names[i]].split(',')[1]; const buf = await sharp(Buffer.from(b64, 'base64')).resize(OUT * sc, OUT * sc, { kernel: 'nearest' }).png().toBuffer(); comps.push({ input: buf, left: i * (OUT * sc + 6), top: 0 }); }
await sharp({ create: { width: names.length * (OUT * sc + 6), height: OUT * sc, channels: 4, background: { r: 30, g: 22, b: 24, alpha: 1 } } }).composite(comps).png().toFile('/tmp/claude-0/-home-user-Strainmon/0f1a7ef5-8d47-53c6-8255-3b41a3c54115/scratchpad/faces.png');
console.log('faceart.js ->', names.length, 'retratos');

#!/usr/bin/env node
/* Iconos pixel-art 16x16 (arte propio, sin assets de terceros) para la CHROME del
   juego (HUD, pestañas, barra superior). Se dibujan como máscara alfa (glifo
   opaco / fondo transparente) y se inyectan como data-URI en assets/style.css
   entre los marcadores ICONS. En CSS se tiñen con currentColor vía mask-image,
   así heredan el estado (atenuado / activo) sin duplicar arte. */
import fs from 'node:fs'; import sharp from 'sharp';
const S = 16;
const B = () => new Uint8Array(S * S * 4);
const on = (b, x, y, a = 255) => { x |= 0; y |= 0; if (x < 0 || y < 0 || x >= S || y >= S) return; const o = (y * S + x) * 4; b[o] = b[o + 1] = b[o + 2] = 255; b[o + 3] = Math.max(b[o + 3], a); };
const rect = (b, x0, y0, x1, y1) => { for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) on(b, x, y); };
const frame = (b, x0, y0, x1, y1) => { for (let x = x0; x <= x1; x++) { on(b, x, y0); on(b, x, y1); } for (let y = y0; y <= y1; y++) { on(b, x0, y); on(b, x1, y); } };
const hline = (b, x0, x1, y) => { for (let x = x0; x <= x1; x++) on(b, x, y); };
const vline = (b, y0, y1, x) => { for (let y = y0; y <= y1; y++) on(b, x, y); };
const disc = (b, cx, cy, r) => { for (let y = -r; y <= r; y++) for (let x = -r; x <= r; x++) if (x * x + y * y <= r * r + 1) on(b, cx + x, cy + y); };
const ring = (b, cx, cy, r) => { for (let a = 0; a < 360; a += 6) on(b, cx + Math.round(Math.cos(a * Math.PI / 180) * r), cy + Math.round(Math.sin(a * Math.PI / 180) * r)); };
const line = (b, x0, y0, x1, y1) => { const dx = Math.abs(x1 - x0), dy = Math.abs(y1 - y0), sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1; let e = dx - dy, x = x0, y = y0; for (; ;) { on(b, x, y); if (x === x1 && y === y1) break; const e2 = 2 * e; if (e2 > -dy) { e -= dy; x += sx; } if (e2 < dx) { e += dx; y += sy; } } };

const I = {
  // ---- pestañas ----
  bag(b) { line(b, 6, 2, 9, 2); line(b, 5, 3, 5, 4); line(b, 10, 3, 10, 4); // asa
    frame(b, 3, 5, 12, 13); rect(b, 3, 5, 12, 6); rect(b, 6, 8, 9, 11); }, // mochila con bolsillo
  leaf(b) { const wp = [0, 1, 2, 3, 4, 4, 4, 4, 3, 2, 1]; for (let i = 0; i < wp.length; i++) rect(b, 8 - wp[i], 2 + i, 8 + wp[i], 2 + i); // lámina en punta
    vline(b, 3, 12, 8, 0); on(b, 8, 13); on(b, 8, 14); // nervio (hueco) + peciolo
    for (const y of [5, 8]) { on(b, 8 - wp[y - 2], y, 0); on(b, 8 + wp[y - 2], y, 0); } }, // dientes
  flask(b) { rect(b, 6, 2, 9, 4); line(b, 6, 5, 3, 13); line(b, 9, 5, 12, 13); hline(b, 3, 12, 13); rect(b, 5, 9, 10, 12); }, // matraz con líquido
  helix(b) { for (let y = 2; y <= 13; y++) { const p = Math.round(3 * Math.sin((y - 2) / 11 * Math.PI * 2)); on(b, 8 + p, y); on(b, 8 - p, y); } for (const y of [4, 7, 10]) hline(b, 8 - 2, 8 + 2, y); }, // ADN
  book(b) { frame(b, 2, 3, 7, 13); frame(b, 8, 3, 13, 13); vline(b, 3, 13, 7); vline(b, 3, 13, 8); hline(b, 4, 6, 6); hline(b, 9, 11, 6); hline(b, 4, 6, 9); hline(b, 9, 11, 9); }, // libro abierto
  clip(b) { frame(b, 3, 3, 12, 14); rect(b, 6, 1, 9, 3); hline(b, 5, 10, 6); hline(b, 5, 10, 8); hline(b, 5, 9, 10); }, // portapapeles
  save(b) { rect(b, 2, 2, 13, 13); // cuerpo lleno
    for (let y = 6; y <= 12; y++) for (let x = 4; x <= 11; x++) { const o = (y * S + x) * 4; b[o + 3] = 0; } // hueco etiqueta
    frame(b, 4, 8, 11, 12); vline(b, 8, 12, 6); vline(b, 8, 12, 10); // etiqueta
    for (let y = 2; y <= 5; y++) for (let x = 5; x <= 8; x++) { const o = (y * S + x) * 4; b[o + 3] = 0; } // hueco obturador
    on(b, 9, 3); on(b, 9, 4); }, // disquete
  // ---- HUD ----
  pin(b) { disc(b, 8, 6, 4); line(b, 4, 8, 8, 14); line(b, 12, 8, 8, 14); rect(b, 7, 5, 9, 7, 0); for (const [x, y] of [[7, 5], [8, 5], [9, 5], [7, 6], [9, 6], [7, 7], [8, 7], [9, 7]]) { const o = (y * S + x) * 4; b[o + 3] = 0; } }, // gota + hueco
  clock(b) { ring(b, 8, 8, 6); line(b, 8, 8, 8, 4); line(b, 8, 8, 11, 9); }, // reloj
  moon(b) { disc(b, 8, 8, 6); for (let y = 0; y < S; y++) for (let x = 0; x < S; x++) { const dx = x - 11, dy = y - 6; if (dx * dx + dy * dy <= 25) { const o = (y * S + x) * 4; b[o + 3] = 0; } } }, // luna creciente
  sun(b) { disc(b, 8, 8, 3); for (let a = 0; a < 360; a += 45) { const c = Math.cos(a * Math.PI / 180), s = Math.sin(a * Math.PI / 180); line(b, 8 + Math.round(c * 5), 8 + Math.round(s * 5), 8 + Math.round(c * 7), 8 + Math.round(s * 7)); } }, // sol
  medal(b) { line(b, 5, 2, 7, 6); line(b, 11, 2, 9, 6); on(b, 5, 2); on(b, 6, 2); on(b, 10, 2); on(b, 11, 2); // cintas
    disc(b, 8, 10, 4); // disco
    for (const [x, y] of [[8, 8], [7, 9], [9, 9], [8, 10], [7, 11], [9, 11]]) { const idx = (y * S + x) * 4; b[idx + 3] = 0; } }, // estrella-hueco
  coin(b) { disc(b, 8, 8, 6); for (let y = 0; y < S; y++) for (let x = 0; x < S; x++) { if ((x + y) % 2 === 0) continue; } vline(b, 5, 11, 8, 0); // marca
    for (const y of [5, 6, 7, 8, 9, 10, 11]) { const idx = (y * S + 8) * 4; b[idx + 3] = 0; } hline(b, 7, 9, 6, 0); for (const x of [7, 8, 9]) { const idx = (6 * S + x) * 4; b[idx + 3] = 0; } }, // moneda con símbolo
  grid(b) { rect(b, 3, 3, 6, 6); rect(b, 9, 3, 12, 6); rect(b, 3, 9, 6, 12); rect(b, 9, 9, 12, 12); }, // cuadrícula (colección)
  alert(b) { line(b, 8, 2, 2, 13); line(b, 8, 2, 13, 13); hline(b, 2, 13, 13); vline(b, 6, 9, 8, 0); on(b, 8, 6, 0); on(b, 8, 7, 0); on(b, 8, 8, 0); on(b, 8, 11, 0); }, // triángulo alerta
  // ---- barra superior ----
  palette(b) { disc(b, 8, 8, 6); for (let y = 0; y < S; y++) for (let x = 0; x < S; x++) { const dx = x - 10, dy = y - 10; if (dx * dx + dy * dy <= 3) { const o = (y * S + x) * 4; b[o + 3] = 0; } } for (const [x, y] of [[6, 5], [10, 5], [5, 9], [11, 8]]) { const o = (y * S + x) * 4; b[o + 3] = 0; } }, // paleta con hueco pulgar
  sound(b) { rect(b, 3, 6, 5, 9); line(b, 5, 6, 8, 3); line(b, 5, 9, 8, 12); vline(b, 3, 12, 8); line(b, 10, 5, 11, 8); line(b, 11, 8, 10, 11); line(b, 12, 3, 13, 8); line(b, 13, 8, 12, 13); }, // altavoz con ondas
  mute(b) { rect(b, 3, 6, 5, 9); line(b, 5, 6, 8, 3); line(b, 5, 9, 8, 12); vline(b, 3, 12, 8); line(b, 10, 5, 13, 11); line(b, 13, 5, 10, 11); }, // altavoz mudo (X)
  // ---- clima ----
  cloud(b) { disc(b, 6, 8, 3); disc(b, 10, 8, 3); rect(b, 5, 8, 11, 11); hline(b, 4, 12, 11); }, // nube
  rain(b) { disc(b, 6, 6, 3); disc(b, 10, 6, 3); rect(b, 5, 6, 11, 9); for (const x of [5, 8, 11]) line(b, x, 11, x - 1, 13); }, // lluvia
  storm(b) { disc(b, 6, 6, 3); disc(b, 10, 6, 3); rect(b, 5, 6, 11, 9); line(b, 8, 10, 6, 13); line(b, 6, 13, 9, 12); }, // tormenta (rayo)
  wind(b) { hline(b, 3, 10, 5); line(b, 10, 5, 12, 4); hline(b, 3, 12, 8); line(b, 12, 8, 13, 9); hline(b, 3, 9, 11); line(b, 9, 11, 11, 12); }, // viento
  // ---- extra chrome ----
  cart(b) { on(b, 2, 3); on(b, 3, 3); line(b, 3, 3, 4, 4); line(b, 4, 4, 5, 10); hline(b, 4, 13, 5); line(b, 13, 5, 12, 10); hline(b, 5, 11, 10); disc(b, 6, 13, 1); disc(b, 11, 13, 1); }, // carrito
  home(b) { line(b, 8, 2, 2, 8); line(b, 8, 2, 13, 8); rect(b, 4, 8, 11, 13); rect(b, 6, 9, 9, 13, 0); for (let y = 9; y <= 13; y++) for (let x = 6; x <= 9; x++) { const o = (y * S + x) * 4; b[o + 3] = 0; } rect(b, 6, 9, 9, 13); for (let y = 10; y <= 12; y++) for (let x = 7; x <= 8; x++) { const o = (y * S + x) * 4; b[o + 3] = 0; } }, // casa con puerta
  drop(b) { const wp = [0, 0, 1, 2, 2, 3]; for (let i = 0; i < wp.length; i++) rect(b, 8 - wp[i], 2 + i, 8 + wp[i], 2 + i); disc(b, 8, 10, 4); // punta + bulbo
    for (const [x, y] of [[6, 9], [6, 10], [7, 11]]) { const o = (y * S + x) * 4; b[o + 3] = 0; } }, // brillo
  heart(b) { disc(b, 5, 6, 3); disc(b, 11, 6, 3); for (let y = 6; y <= 13; y++) { const w = 13 - y; rect(b, 8 - w, y, 8 + w, y); } rect(b, 3, 6, 13, 7); }, // corazón
  trash(b) { hline(b, 4, 11, 3); rect(b, 6, 1, 9, 2); rect(b, 3, 4, 12, 5); frame(b, 4, 5, 11, 13); vline(b, 6, 12, 6); vline(b, 6, 12, 8); vline(b, 6, 12, 10); }, // papelera
  sprout(b) { vline(b, 6, 13, 8); disc(b, 5, 6, 2); disc(b, 11, 6, 2); rect(b, 5, 6, 7, 8); rect(b, 9, 6, 11, 8); line(b, 8, 9, 5, 7); line(b, 8, 8, 11, 6); }, // brote
  nova(b) { vline(b, 2, 13, 8); hline(b, 2, 13, 8); on(b, 6, 6); on(b, 10, 6); on(b, 6, 10); on(b, 10, 10); on(b, 7, 7); on(b, 9, 7); on(b, 7, 9); on(b, 9, 9); }, // destello
  doc(b) { frame(b, 3, 2, 11, 13); line(b, 9, 2, 11, 4); for (let y = 2; y <= 4; y++) for (let x = 9 + (y - 2); x <= 11; x++) on(b, x, y); hline(b, 5, 9, 6); hline(b, 5, 9, 8); hline(b, 5, 8, 10); }, // documento
  power(b) { ring(b, 8, 9, 5); ring(b, 8, 9, 4); // aro doble (grosor)
    for (const [x, y] of [[7, 4], [8, 4], [9, 4], [7, 5], [8, 5], [9, 5], [8, 3]]) { const o = (y * S + x) * 4; b[o + 3] = 0; } // hueco superior
    rect(b, 7, 2, 8, 9); }, // barra vertical (símbolo de encendido)
};

let css = '';
const names = Object.keys(I);
for (const n of names) {
  const b = B(); I[n](b);
  const buf = await sharp(Buffer.from(b), { raw: { width: S, height: S, channels: 4 } }).png().toBuffer();
  css += `.pic-${n}{--u:url("data:image/png;base64,${buf.toString('base64')}")}\n`;
}

// inyecta en style.css entre marcadores
const CSSPATH = 'assets/style.css';
let s = fs.readFileSync(CSSPATH, 'utf8');
const START = '/* ICONS:START (generado por scripts/gen-icons.mjs — no editar a mano) */';
const END = '/* ICONS:END */';
const block = `${START}\n${css}${END}`;
if (s.includes(START)) s = s.replace(new RegExp(START.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '[\\s\\S]*?' + END.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')), block);
else s = s.trimEnd() + '\n\n' + block + '\n';
fs.writeFileSync(CSSPATH, s);
console.log(`iconos: ${names.length} -> ${CSSPATH}`);

// preview
const sc = 8, cols = 8, rows = Math.ceil(names.length / cols), comps = [];
for (let i = 0; i < names.length; i++) { const b = B(); I[names[i]](b); const buf = await sharp(Buffer.from(b), { raw: { width: S, height: S, channels: 4 } }).resize(S * sc, S * sc, { kernel: 'nearest' }).png().toBuffer(); comps.push({ input: buf, left: (i % cols) * (S * sc + 6) + 3, top: ((i / cols) | 0) * (S * sc + 6) + 3 }); }
await sharp({ create: { width: cols * (S * sc + 6), height: rows * (S * sc + 6), channels: 4, background: { r: 30, g: 22, b: 24, alpha: 1 } } }).composite(comps).png().toFile('/tmp/claude-0/-home-user-Strainmon/0f1a7ef5-8d47-53c6-8255-3b41a3c54115/scratchpad/icons-preview.png');
console.log('preview -> icons-preview.png');

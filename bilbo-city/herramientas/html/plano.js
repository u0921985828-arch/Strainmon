/**
 * Renderiza el plano completo de la ciudad a PNG y saca sus métricas.
 * Sirve para ver de un vistazo si un cambio en la generación ha roto Bilbao.
 *
 *   node herramientas/html/plano.js [salida.png]
 */
require('./arnes.js');
const fs = require('fs'), path = require('path');
const { createCanvas } = require('canvas');

const salida = process.argv[2] || path.join(__dirname, '..', '..', 'referencia', 'capturas', 'plano-bilbo.png');

// Igual que en la batería: se espera a que la ciudad esté trazada, no un plazo fijo.
const listo = async () => {
  for (let t = 0; t < 20000; t += 25) {
    if (global.__ && global.__.map && global.__.POI.length) return;
    await new Promise(r => setTimeout(r, 25));
  }
  throw new Error('la ciudad no se generó en 20 s');
};

listo().then(() => {
  const A = global.__;
  const Z = 4;
  const c = createCanvas(A.MW * Z, A.MH * Z), g = c.getContext('2d');
  g.imageSmoothingEnabled = false;
  const col = { 0:'#4a505a', 1:'#8a8578', 2:'#5c5148', 3:'#3c6338', 4:'#1c4652',
                5:'#8d99a4', 6:'#a8a294', 7:'#6b5f45', 8:'#3f3a34', 9:'#241f1c' };
  for (let y = 0; y < A.MH; y++)
    for (let x = 0; x < A.MW; x++) {
      g.fillStyle = col[A.map[y * A.MW + x]] || '#f0f';
      g.fillRect(x * Z, y * Z, Z, Z);
    }
  // ── mobiliario de plano: rejilla, barrios y leyenda ─────────────────────────────
  // Sin esto el plano es una mancha bonita que no dice dónde está nada. Con la rejilla
  // y los nombres se puede señalar un sitio por escrito — «el puente de D3» — que es
  // justo para lo que se saca este PNG.
  const CEL = 64;                                  // casillas por cuadro de rejilla
  g.strokeStyle = 'rgba(255,255,255,.20)'; g.lineWidth = 1;
  g.font = 'bold 13px sans-serif'; g.textBaseline = 'top';
  for (let x = CEL; x < A.MW; x += CEL) {
    g.beginPath(); g.moveTo(x*Z + .5, 0); g.lineTo(x*Z + .5, A.MH*Z); g.stroke();
  }
  for (let y = CEL; y < A.MH; y += CEL) {
    g.beginPath(); g.moveTo(0, y*Z + .5); g.lineTo(A.MW*Z, y*Z + .5); g.stroke();
  }
  g.fillStyle = 'rgba(255,255,255,.55)';
  for (let i = 0, x = 0; x < A.MW; x += CEL, i++)
    g.fillText(String.fromCharCode(65+i), x*Z + 5, 4);
  for (let i = 0, y = 0; y < A.MH; y += CEL, i++)
    g.fillText(String(i+1), 4, y*Z + 5);

  // nombre de cada barrio en su centro de masas, saltándose monte y parques
  const centro = {};
  for (let y = 0; y < A.MH; y++)
    for (let x = 0; x < A.MW; x++) {
      const z = A.distDe(x, y);
      if (z.monte || z.verde) continue;
      (centro[z.n] = centro[z.n] || {x:0, y:0, n:0});
      centro[z.n].x += x; centro[z.n].y += y; centro[z.n].n++;
    }
  g.textAlign = 'center'; g.textBaseline = 'middle';
  g.font = 'bold 15px sans-serif';
  for (const n of Object.keys(centro)) {
    const s = centro[n], px = s.x/s.n*Z, py = s.y/s.n*Z;
    g.lineWidth = 3; g.strokeStyle = 'rgba(0,0,0,.75)'; g.strokeText(n.toUpperCase(), px, py);
    g.fillStyle = '#f2ede0'; g.fillText(n.toUpperCase(), px, py);
  }

  A.POI.forEach(p => {
    g.fillStyle = '#000'; g.fillRect(p.p.x * Z - 5, p.p.y * Z - 5, 11, 11);
    g.fillStyle = p.c;    g.fillRect(p.p.x * Z - 3, p.p.y * Z - 3, 7, 7);
  });

  // leyenda: los sitios, en dos columnas, sobre un panel con el mismo aire que el plano
  const filas = Math.ceil(A.POI.length / 2);
  // abajo a la izquierda: es la esquina con menos ciudad, y arriba a la derecha el panel
  // tapaba Begoña y Txurdinaga
  const LW = 430, LH = 34 + filas * 18, LX = 14, LY = A.MH*Z - LH - 14;
  g.textAlign = 'left'; g.textBaseline = 'middle';
  g.fillStyle = 'rgba(20,18,15,.86)'; g.fillRect(LX, LY, LW, LH);
  g.strokeStyle = 'rgba(242,237,224,.45)'; g.lineWidth = 2; g.strokeRect(LX+.5, LY+.5, LW, LH);
  g.fillStyle = '#f2ede0'; g.font = 'bold 15px sans-serif';
  g.fillText('BILBAO · SITIOS', LX + 12, LY + 17);
  g.font = '12px sans-serif';
  A.POI.forEach((p, i) => {
    const cx = LX + 12 + (i < filas ? 0 : LW/2), cy = LY + 34 + (i % filas) * 18 + 8;
    g.fillStyle = '#000'; g.fillRect(cx, cy - 5, 10, 10);
    g.fillStyle = p.c;    g.fillRect(cx + 2, cy - 3, 6, 6);
    g.fillStyle = '#e6e0d2'; g.fillText(p.n, cx + 16, cy);
  });

  fs.writeFileSync(salida, c.toBuffer('image/png'));

  const cuenta = {};
  for (let i = 0; i < A.MW * A.MH; i++) cuenta[A.map[i]] = (cuenta[A.map[i]] || 0) + 1;
  const total = A.MW * A.MH;
  const nom = { 0:'calzada', 1:'acera', 2:'edificio', 3:'verde', 4:'agua',
                5:'puente', 6:'plaza', 7:'muelle', 8:'patio', 9:'vía' };
  console.log('plano escrito en ' + salida + '\n');
  Object.keys(cuenta).sort().forEach(k =>
    console.log('  ' + (nom[k] || k).padEnd(9) + (cuenta[k] / total * 100).toFixed(1) + '%'));
  console.log('\n  barrios   ' + Object.keys(A.ZONAS).length);
  console.log('  sitios    ' + A.POI.length);
});

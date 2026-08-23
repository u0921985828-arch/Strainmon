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

setTimeout(() => {
  const A = global.__;
  const Z = 4;
  const c = createCanvas(A.MW * Z, A.MH * Z), g = c.getContext('2d');
  g.imageSmoothingEnabled = false;
  const col = { 0:'#4a505a', 1:'#8a8578', 2:'#5c5148', 3:'#3c6338', 4:'#1c4652',
                5:'#8d99a4', 6:'#a8a294', 7:'#6b5f45', 8:'#3f3a34' };
  for (let y = 0; y < A.MH; y++)
    for (let x = 0; x < A.MW; x++) {
      g.fillStyle = col[A.map[y * A.MW + x]] || '#f0f';
      g.fillRect(x * Z, y * Z, Z, Z);
    }
  A.POI.forEach(p => {
    g.fillStyle = '#000'; g.fillRect(p.p.x * Z - 5, p.p.y * Z - 5, 11, 11);
    g.fillStyle = p.c;    g.fillRect(p.p.x * Z - 3, p.p.y * Z - 3, 7, 7);
  });
  fs.writeFileSync(salida, c.toBuffer('image/png'));

  const cuenta = {};
  for (let i = 0; i < A.MW * A.MH; i++) cuenta[A.map[i]] = (cuenta[A.map[i]] || 0) + 1;
  const total = A.MW * A.MH;
  const nom = { 0:'calzada', 1:'acera', 2:'edificio', 3:'verde', 4:'agua',
                5:'puente', 6:'plaza', 7:'muelle', 8:'patio' };
  console.log('plano escrito en ' + salida + '\n');
  Object.keys(cuenta).sort().forEach(k =>
    console.log('  ' + (nom[k] || k).padEnd(9) + (cuenta[k] / total * 100).toFixed(1) + '%'));
  console.log('\n  barrios   ' + Object.keys(A.ZONAS).length);
  console.log('  sitios    ' + A.POI.length);
}, 500);

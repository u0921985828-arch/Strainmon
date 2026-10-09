/**
 * Mide la trama de manzanas: cuántas hay, de qué tamaño y cuál es la mayor.
 *
 * Una ciudad de verdad no se reconoce por tener calles, sino por el grano: manzanas
 * de tamaños parecidos, muchas, y ninguna losa de cien metros sin partir. Este medidor
 * es la única forma de saber si un cambio en la generación mejora eso o solo lo mueve.
 *
 *   node herramientas/html/manzanas.js
 */
require('./arnes.js');

const listo = async () => {
  for (let t = 0; t < 30000; t += 25) {
    if (global.__ && global.__.map && global.__.POI.length) return;
    await new Promise(r => setTimeout(r, 25));
  }
  throw new Error('la ciudad no se cargó en 20 s');
};

listo().then(() => {
  const A = global.__, { map, MW, MH, EDIF } = A;
  const esManzana = t => t === EDIF;
  const visto = new Uint8Array(MW * MH);
  // El borde del mapa es una tira de manzana puesta para cerrar el término municipal.
  // Contarla uniría todas las manzanas del perímetro en una sola de seis mil casillas,
  // que es un artefacto del cierre y no una manzana de Bilbao.
  for (let x = 0; x < MW; x++) { visto[x] = 1; visto[(MH - 1) * MW + x] = 1; }
  for (let y = 0; y < MH; y++) { visto[y * MW] = 1; visto[y * MW + MW - 1] = 1; }
  const tam = [];
  let mayor = null;
  for (let y = 1; y < MH - 1; y++) for (let x = 1; x < MW - 1; x++) {
    const k = y * MW + x;
    if (visto[k] || !esManzana(map[k])) continue;
    let n = 0, x0 = x, x1 = x, y0 = y, y1 = y;
    const pila = [k]; visto[k] = 1;
    while (pila.length) {
      const j = pila.pop(); n++;
      const cx = j % MW, cy = (j / MW) | 0;
      if (cx < x0) x0 = cx; if (cx > x1) x1 = cx;
      if (cy < y0) y0 = cy; if (cy > y1) y1 = cy;
      for (const [dx, dy] of [[1,0],[-1,0],[0,1],[0,-1]]) {
        const nx = cx + dx, ny = cy + dy;
        if (nx < 0 || ny < 0 || nx >= MW || ny >= MH) continue;
        const m = ny * MW + nx;
        if (!visto[m] && esManzana(map[m])) { visto[m] = 1; pila.push(m); }
      }
    }
    if (n < 9) continue;                       // ruido, no manzana
    const b = { n, w: x1 - x0 + 1, h: y1 - y0 + 1, x: x0, y: y0 };
    tam.push(b);
    if (!mayor || n > mayor.n) mayor = b;
  }
  tam.sort((a, b) => a.n - b.n);
  const med = tam[tam.length >> 1];
  const pct = p => tam[Math.min(tam.length - 1, Math.floor(tam.length * p))].n;
  const grandes = tam.filter(b => b.n > 400).length;
  console.log(`mapa                 ${MW}x${MH} casillas`);
  console.log(`manzanas (>=9 cas.)  ${tam.length}`);
  console.log(`superficie mediana   ${med.n} casillas  (~${med.w}x${med.h})`);
  console.log(`percentil 90         ${pct(.9)} casillas`);
  console.log(`la mayor             ${mayor.n} casillas  (${mayor.w}x${mayor.h}) en ${mayor.x},${mayor.y}`);
  console.log(`losas (>400 cas.)    ${grandes}`);
  process.exit(0);
});

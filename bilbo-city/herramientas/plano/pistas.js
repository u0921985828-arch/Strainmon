/**
 * Recalcula las pistas de los sitios a partir del mapa generado.
 *
 *   node herramientas/plano/pistas.js
 *
 * Cada sitio se coloca buscando suelo pisable de su barrio cerca de una pista. Cuando el
 * trazado se mueve, las pistas viejas apuntan a monte y el sitio acaba en el centro del
 * mapa — que es lo que pasó al refitar la ciudad al plano oficial. Esto imprime, por
 * barrio, el centro de masas de sus casillas pisables, que es la pista que no falla.
 */
require('../html/arnes.js');

setTimeout(() => {
  const A = global.__;
  const suma = {};
  for (let y = 0; y < A.MH; y++) {
    for (let x = 0; x < A.MW; x++) {
      const t = A.Tc(x, y);
      if (t !== A.ACERA && t !== A.PLAZA && t !== A.PARQUE) continue;
      const z = A.distDe(x, y).n;
      (suma[z] = suma[z] || { x: 0, y: 0, n: 0 });
      suma[z].x += x; suma[z].y += y; suma[z].n++;
    }
  }
  const letra = {};
  for (const k of Object.keys(A.ZONAS)) letra[A.ZONAS[k].n] = k;
  for (const n of Object.keys(suma).sort()) {
    const s = suma[n];
    console.log((letra[n] || '?') + '  ' + n.padEnd(16) +
                ' pista [' + Math.round(s.x / s.n) + ',' + Math.round(s.y / s.n) + ']' +
                '  pisables ' + s.n);
  }
  process.exit(0);
}, 400);

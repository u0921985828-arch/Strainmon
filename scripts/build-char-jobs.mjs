#!/usr/bin/env node
/* Construye los jobs de personajes para gen-sprites.mjs (estilo sprite único
   detallado, calidad "planta"). 8 personajes × 4 direcciones isométricas.
   Emite dos manifiestos: la pose SE primero, y luego SW/NW/NE usando la SE
   como imagen de referencia (consistencia entre direcciones).
   Salida: prompts/gen/chars-se.json, prompts/gen/chars-rest.json */
import fs from 'node:fs';
import path from 'node:path';
const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');

const CHARS = {
  player: 'joven cazador de plantas: gorra snapback verde, sudadera con capucha verde oscuro, pantalón cargo caqui, mochila pequeña a la espalda, botas marrones, expresión amable',
  botanist: 'botánica científica: bata blanca abierta sobre camiseta verde, gafas de seguridad en la frente, pelo oscuro recogido en moño, sonrisa curiosa',
  dealer: 'trapichero callejero de actitud turbia: sudadera oscura con capucha puesta, gafas de sol, fina cadena de oro, vaqueros holgados, zapatillas',
  merchant: 'comerciante amable: delantal verde sobre camisa de mangas remangadas, gorra plana, bigote poblado, aire jovial',
  customer1: 'aldeano casual y delgado: camiseta lisa de color, vaqueros sencillos, peinado corto',
  customer2: 'aldeano corpulento y alegre: sudadera holgada, pantalón corto, mejillas redondas',
  walker: 'anciano paseante: cárdigan de punto, gorra plana, bastón de madera, gafas redondas',
  neighbor: 'vecino jardinero: peto vaquero sobre camiseta, sombrero de paja, guantes de jardinería',
};
// charart.js: 1=SE 2=SW 3=NW 4=NE
const DIRS = {
  1: 'orientado hacia ABAJO-DERECHA (sureste). Vista DE FRENTE en 3/4 hacia la esquina inferior derecha: se ve el pecho y la cara. Cabeza y torso alineados en la MISMA dirección. No se ve la espalda',
  2: 'orientado hacia ABAJO-IZQUIERDA (suroeste). Vista DE FRENTE en 3/4 hacia la esquina inferior izquierda: se ve el pecho y la cara. Cabeza y torso alineados en la MISMA dirección. NO se ve la espalda ni la mochila',
  3: 'orientado hacia ARRIBA-IZQUIERDA (noroeste). Vista DE ESPALDAS en 3/4 hacia la esquina superior izquierda: se ve la espalda y la nuca. La cara NO es visible; la cabeza NO está girada hacia la cámara',
  4: 'orientado hacia ARRIBA-DERECHA (noreste). Vista DE ESPALDAS en 3/4 hacia la esquina superior derecha: se ve la espalda y la nuca. La cara NO es visible; la cabeza NO está girada hacia la cámara',
};
const BASE = 'Pixel art 16-bit estilo Game Boy Advance, original, sin antialias, contorno oscuro 1px (#20161f), sombreado suave con luz cenital y volumen, paleta saturada limitada, alta definición de pixel. UN ÚNICO personaje, una sola figura completa y aislada centrada en el lienzo; NO es una hoja de turnaround, NO dupliques la figura ni muestres varias vistas ni versiones pequeñas. Personaje humano de cuerpo entero en perspectiva isométrica 3/4 desde arriba, proporción chibi (cabeza algo grande, cuerpo compacto), de pie.';

function prompt(desc, dir, ref) {
  const facing = `Personaje ${DIRS[dir]}.`;
  const who = `${desc}.`;
  const consist = ref ? ' Es EXACTAMENTE el mismo personaje que la imagen de referencia (misma ropa, colores y proporciones), pero cambiando la orientación a la indicada arriba; NO copies la orientación de la referencia, SOLO su aspecto.' : '';
  return `${BASE} ${facing} ${who}${consist} Detalle nítido en ropa y pliegues, como un sprite de criatura cuidado. Sprite único centrado y completo, sin recortar.`;
}

const se = [], rest = [];
for (const [name, desc] of Object.entries(CHARS)) {
  se.push({ name: `${name}_1`, prompt: prompt(desc, 1, false) });
  for (const d of [2, 3, 4]) {
    rest.push({ name: `${name}_${d}`, ref: `${name}_1.png`, prompt: prompt(desc, d, true) });
  }
}
fs.mkdirSync(path.join(ROOT, 'prompts', 'gen'), { recursive: true });
fs.writeFileSync(path.join(ROOT, 'prompts', 'gen', 'chars-se.json'), JSON.stringify(se, null, 2));
fs.writeFileSync(path.join(ROOT, 'prompts', 'gen', 'chars-rest.json'), JSON.stringify(rest, null, 2));
console.log(`✅ chars-se.json (${se.length}) + chars-rest.json (${rest.length})`);

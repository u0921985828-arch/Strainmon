/**
 * Nombres declarados dos veces en el mismo ámbito del prototipo.
 *
 *   node herramientas/html/duplicados.js
 *
 * JavaScript no se queja cuando dos `function` comparten nombre: se izan las dos y gana la
 * última, en todo el ámbito, también por encima de las llamadas que había antes.
 *
 * Esto no es teoría. `ruido` era el grano de las texturas y también el ruido del sigilo, y
 * ganaba el del sigilo: las treinta y una llamadas del arte le pasaban un lienzo donde
 * esperaba una coordenada, no pintaban nada, y el juego entero llevaba sin grano —el
 * asfalto, la acera, el ladrillo, el suelo de todos los interiores— sin que saltara un solo
 * aviso, porque el resultado de no pintar es un tile liso, que es un tile válido.
 *
 * Un `const` repetido sí revienta al cargar, así que ese no hace falta cazarlo aquí.
 */
const fs = require('fs');
const path = require('path');

const RUTA = process.env.BILBO_HTML ||
  path.join(__dirname, '..', '..', 'referencia', 'bilbo-city.html');
const js = fs.readFileSync(RUTA, 'utf8').match(/<script>([\s\S]*)<\/script>/)[1];

// Se recorre el fichero contando llaves, comillas y comentarios para saber a qué
// profundidad está cada declaración: `function` dentro de otra función es un ámbito
// distinto y ahí un nombre repetido no pisa nada de fuera.
const decl = new Map();
let prof = 0, i = 0, linea = 1;
const n = js.length;
while (i < n) {
  const c = js[i], d = js[i + 1];
  if (c === '\n') { linea++; i++; continue; }
  if (c === '/' && d === '/') { while (i < n && js[i] !== '\n') i++; continue; }
  if (c === '/' && d === '*') { i += 2; while (i < n && !(js[i] === '*' && js[i + 1] === '/')) { if (js[i] === '\n') linea++; i++; } i += 2; continue; }
  if (c === '"' || c === "'" || c === '`') {
    const q = c; i++;
    while (i < n && js[i] !== q) { if (js[i] === '\\') i++; else if (js[i] === '\n') linea++; i++; }
    i++; continue;
  }
  if (c === '{') { prof++; i++; continue; }
  if (c === '}') { prof--; i++; continue; }
  const m = /^function\s+([A-Za-z_$][\w$]*)\s*\(/.exec(js.slice(i, i + 80));
  if (m && (i === 0 || !/[\w$.]/.test(js[i - 1]))) {
    const clave = m[1] + '@' + prof;
    if (!decl.has(clave)) decl.set(clave, []);
    decl.get(clave).push(linea);
    i += m[0].length; continue;
  }
  i++;
}

const chocan = [...decl.entries()].filter(([, ls]) => ls.length > 1);
for (const [clave, ls] of chocan) {
  const [nombre, p] = clave.split('@');
  console.log('  FALLO function ' + nombre + '() declarada ' + ls.length +
    ' veces en el mismo ámbito (profundidad ' + p + '), líneas ' + ls.join(' y ') +
    ' — gana la última y las llamadas de arriba van a parar a ella');
}
if (chocan.length) {
  console.log('\n' + chocan.length + ' nombres pisados');
  process.exit(1);
}
console.log('  ok    ' + decl.size + ' funciones, ninguna declarada dos veces en su ámbito');

#!/usr/bin/env node
/*
  Ribera Verde — regenera docs/GENETICA.md y docs/MAPA.md leyendo los datos reales del juego
  (STRAINS, RECIPES, MAPS, NPCDEF, ITEMS, SHOP) desde index.html. Así la documentación no se desfasa.
  Uso:  node tools/build.js && node tools/generar-docs.js
*/
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const ROOT = path.join(__dirname, '..');

(async () => {
  const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
  const page = await browser.newPage();
  await page.goto('file://' + path.join(ROOT, 'index.html'));
  await page.waitForFunction(() => typeof mode !== 'undefined' && mode === 'title');
  const D = await page.evaluate(() => {
    S = newState(); S.carpas = [{ t: 'p60', foco: 'cfl' }, { t: 'g150', foco: 'cfl' }]; montarCasa();   // el piso con el armario y la carpa grande
    const strains = DEX.map((k, i) => ({ k, idx: i + 1, ...STRAINS[k] }));
    const recipes = Object.entries(RECIPES).map(([pair, out]) => ({ a: pair.split('+')[0], b: pair.split('+')[1], out }));
    const G = { grass: '.', flowers: '*', tallgrass: '"', dirt: ':', walk: '-', roadT: '=', roadB: '=', plaza: '+', water: '~', bridgeT: 'H', bridgeB: 'H', dock: '#',
      floor: '.', floorB: '.', floorS: '.', tent: 'o', mat: 'm', void: ' ' };
    const O = { tree: 'T', bush: 'b', fence: 'f', sign: 'S', lamp: 'L', bench: 'n', fountain: 'O', crate: 'c', bedT: 'B', bedB: 'B', pc: 'P', lab: 'G', lab2: 'G',
      table: 't', fridge: 'F', shelfW: 's', counter: 'C', display: 'd', plantDeco: 'p', barcounter: 'C', bottles: 's', stool: 'x', btable: 't', jukebox: 'J', iwin: 'v', poster: 'v' };
    const maps = {};
    for (const [name, m] of Object.entries(MAPS)) {
      const rows = [];
      for (let y = 0; y < m.h; y++) {
        let r = '';
        for (let x = 0; x < m.w; x++) {
          const g = m.g[y][x], o = m.o[y][x];
          let ch = o ? (O[o] || '?') : (G[g] ?? (/^roof/.test(g) ? '^' : /^door/.test(g) ? 'D' : /^(wall|win|iw)/.test(g) ? '█' : '?'));
          const it = ITEMS.find(i => i.map === name && i.x === x && i.y === y);
          if (it) ch = it.hidden ? '$' : 'i';
          if (name === 'home') { if (/^cp(?!Puerta)/.test(g)) ch = '▒'; if (g === 'cpPuerta') ch = 'z'; const pi = huecos().findIndex(h => h.x === x && h.y === y); if (pi >= 0) ch = String(pi + 1); }
          const npc = NPCDEF.find(d => d.map === name && d.x === x && d.y === y);
          if (npc) ch = '@';
          r += ch;
        }
        rows.push(r);
      }
      maps[name] = { w: m.w, h: m.h, rows, doors: m.doors, exits: m.exits };
    }
    const npcs = NPCDEF.map(d => ({ id: d.id, map: d.map, x: d.x, y: d.y, wander: d.wander || 0, cond: d.cond ? d.cond.toString().replace(/^\(\)=>/, '') : '' }));
    const items = ITEMS.map(i => ({ id: i.id, map: i.map, x: i.x, y: i.y, hidden: !!i.hidden, give: i.give.toString().match(/got\('([^']+)'/)?.[1] || i.give.toString().match(/money\+=(\d+)/)?.[0] }));
    const shop = SHOP.map(s => ({ lbl: s.lbl, p: s.p, ch: s.ch, desc: (s.desc || '').replace(/\n/g, ' · ') }));
    const signs = SIGNS;
    return { strains, recipes, maps, npcs, items, shop, signs };
  });
  await browser.close();

  const pct = n => String(n).replace('.', ',');
  const name = k => D.strains.find(s => s.k === k).n;
  const ORIGIN = { ria: 'Growshop (cap. 1)', limon: 'Growshop (cap. 2)', txoko: 'Growshop (cap. 2)', niebla: 'Growshop (cap. 3)', mango: 'Growshop (cap. 3)', purpura: 'Growshop (cap. 4)',
    rif: 'Regalo de Kiko al abrir la mesa de genética (cap. 4)', hindu: 'Abuela Txaro, a cambio de 5 g (parque)', acapulco: 'Escondida en un arbusto del parque (2,26)', malawi: 'Iñaki, el marinero, tras venderle 10 g (muelle)' };

  // ---------- GENETICA.md ----------
  let g = `# Genética de Ribera Verde

> Generado automáticamente con \`node tools/generar-docs.js\` a partir de los datos del juego. No editar a mano: cambia \`src/js/03-datos.js\` y regenera.

## Las ${D.strains.length} variedades de la Genoteca

| # | Variedad | THC | Rinde (g/planta) | Días | Resist. | Color | Cómo se consigue |
|---|---|---|---|---|---|---|---|
`;
  for (const s of D.strains) {
    const how = ORIGIN[s.k] || 'Cruce: ' + s.o.replace(' · LEGENDARIA', '') + (s.o.includes('LEGENDARIA') ? ' · **legendaria**' : '');
    g += `| ${String(s.idx).padStart(2, '0')} | ${s.n} | ${pct(s.thc)}% | ${s.y} | ${pct(s.d)} | ${s.r}% | \`${s.c}\` | ${how} |\n`;
  }
  g += `
## Recetas de cruce (${D.recipes.length})

El orden de los padres da igual. Cada cruce gasta 1 semilla de cada padre y da 2 semillas del resultado.

| Madre | Padre | Resultado | THC |
|---|---|---|---|
`;
  for (const r of D.recipes) g += `| ${name(r.a)} | ${name(r.b)} | **${name(r.out)}** | ${pct(D.strains.find(s => s.k === r.out).thc)}% |\n`;
  g += `
## Árbol hasta la Leyenda

\`\`\`mermaid
flowchart LR
`;
  for (const r of D.recipes) g += `  ${r.a}["${name(r.a)}"] --> ${r.out}["${name(r.out)}"]\n  ${r.b}["${name(r.b)}"] --> ${r.out}\n`;
  g += `  style leyenda fill:#40e0a0,color:#062\n\`\`\`

## Híbridos propios (cruces sin receta)

Cualquier pareja que no esté en la tabla de recetas genera un híbrido «propio», determinista (la misma pareja da siempre el mismo resultado) y guardado en \`S.custom\`:

- **Nombre:** primera palabra de la madre + última palabra del padre (si coincide con un padre, al revés; si ya existe, se añade «F2…F8»).
- **THC:** media de los padres + aleatorio entre −1,5 y +2,0 (tope 33 %).
- **Rendimiento:** media ± 4 g. **Días:** media ± 0,3 (redondeado a medios días). **Resistencia:** media ± 5 (entre 20 y 95).
- **Color:** mezcla al 50 % de los colores de los padres.
- Aparecen en la Genoteca con ★ y cuentan para el objetivo de «descubrir 8 variedades».

## Fórmulas de cultivo

- **Crecimiento por hora:** \`1 / (días × 24) × crec\`, ×0,4 si el agua < 20 %, 0 si el agua llega a 0, ×1,1 con abono. \`crec\`, \`rend\`, \`thc\` y \`riego\` salen del foco y de la maceta de cada plaza (ver la sección 4 del [GDD](GDD.md)).
- **Agua:** baja 3,5 × riego puntos por hora (con CFL y maceta de 7 L una planta regada aguanta ~28 h).
- **Salud:** −4/h sin agua, −2,5/h con plaga, +1/h si agua > 30 % y sin plaga. A 0 la planta muere.
- **Plagas:** probabilidad por hora \`0,006 × (100 − resistencia) / 40\` mientras no está madura.
- **Cosecha (g):** \`rinde × (0,4 + 0,6 × salud/100) × (abono ? 1,25 : 1) × rend\`.
- **THC final:** \`THC × (0,85 + 0,15 × salud/100) + thc + (abono ? 0,3 : 0)\`.
- **Semillas al cosechar:** 1 + (0 a 2).
`;
  fs.writeFileSync(path.join(ROOT, 'docs/GENETICA.md'), g);

  // ---------- MAPA.md ----------
  const legend = `Leyenda: \`.\` suelo/hierba · \`*\` flores · \`"\` hierba alta (ladrones ×3, a cualquier hora) · \`:\` tierra · \`-\` acera · \`=\` carretera · \`+\` plaza · \`~\` agua · \`H\` puente · \`#\` muelle
\`^\` tejado · \`█\` pared/ventana · \`D\` puerta · \`T\` árbol · \`b\` arbusto · \`$\` arbusto con objeto oculto · \`i\` objeto en el suelo · \`f\` valla · \`S\` cartel · \`L\` farola · \`n\` banco · \`O\` fuente · \`c\` cajas · \`@\` personaje
Interiores: \`B\` cama · \`P\` ordenador · \`G\` mesa de genética · \`t\` mesa · \`F\` nevera · \`▒\` pared de la carpa · \`z\` puerta de la carpa · \`o\` suelo de la carpa · \`1-8\` plazas (mesa + maceta; 1-2 el armario de 60, 3-8 la carpa de 150) · \`C\` mostrador · \`s\` estantería · \`d\` expositor · \`x\` taburete · \`J\` gramola · \`v\` ventana/póster · \`m\` felpudo (salida)`;
  let m = `# Mapa de Ribera Verde

> Generado automáticamente con \`node tools/generar-docs.js\`. Coordenadas (x, y) en casillas de 16 px; (0,0) es la esquina superior izquierda.

${legend}
`;
  const titles = { town: 'Barrio (exterior) — 40 × 30', home: 'Piso de la tía Maite — 20 × 12 (con el armario de 60 y la carpa de 150)', shop: 'Growshop Kiko — 10 × 8', bar: 'Bar El Ancla — 10 × 8' };
  for (const [k, mp] of Object.entries(D.maps)) {
    const pad = String(mp.w - 1).length;
    let header = '    ' + Array.from({ length: mp.w }, (_, x) => x % 10 === 0 ? String(x / 10 % 10) : ' ').join('') + '\n    ' + Array.from({ length: mp.w }, (_, x) => x % 10).join('');
    m += `\n## ${titles[k]}\n\n\`\`\`\n${header}\n${mp.rows.map((r, y) => String(y).padStart(2, ' ') + '  ' + r).join('\n')}\n\`\`\`\n`;
    const doors = Object.entries(mp.doors).map(([xy, w]) => `puerta (${xy}) → ${w.to} (${w.x},${w.y})`);
    const exits = Object.entries(mp.exits).map(([xy, w]) => `salida (${xy}) pulsando abajo → ${w.to} (${w.x},${w.y})`);
    if (doors.length || exits.length) m += '\n' + doors.concat(exits).map(s => '- ' + s).join('\n') + '\n';
  }
  m += `\n## Personajes\n\n| id | Mapa | Posición | Deambula | Aparece cuando |\n|---|---|---|---|---|\n`;
  for (const n of D.npcs) m += `| ${n.id} | ${n.map} | (${n.x},${n.y}) | ${n.wander ? 'radio ' + n.wander : 'no'} | ${n.cond ? '`' + n.cond + '`' : 'siempre'} |\n`;
  m += `\nLos **clientes** ($) aparecen cada día desde el capítulo 2 en casillas de acera, plaza y tierra (4 + reputación/15, +1 desde el capítulo 4, máximo 10).\n`;
  m += `\n## Objetos\n\n| id | Posición | Tipo | Contenido |\n|---|---|---|---|\n`;
  for (const i of D.items) m += `| ${i.id} | ${i.map} (${i.x},${i.y}) | ${i.hidden ? 'oculto en arbusto (pulsa A delante)' : 'bolsa en el suelo'} | ${i.give || ''} |\n`;
  m += `\n## Carteles\n\n`;
  for (const [k, v] of Object.entries(D.signs)) m += `- **${k}** — ${v.replace(/\n/g, ' · ')}\n`;
  m += `\n## Tienda de Kiko\n\n| Artículo | Precio | Desde cap. | Nota |\n|---|---|---|---|\n`;
  for (const s of D.shop) m += `| ${s.lbl} | ${s.p} € | ${s.ch} | ${s.desc} |\n`;
  fs.writeFileSync(path.join(ROOT, 'docs/MAPA.md'), m);
  console.log('docs/GENETICA.md y docs/MAPA.md regenerados');
})();

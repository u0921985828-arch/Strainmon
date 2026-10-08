#!/usr/bin/env node
/*
  Ribera Verde — regenera docs/GENETICA.md, docs/ECONOMIA.md y docs/MAPA.md leyendo los datos reales del juego
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
    const strains = DEX.map((k, i) => ({ k, idx: i + 1, ...STRAINS[k], tipo: TIPO_GEN[k] || (/^Landrace/.test(STRAINS[k].o) ? 'landrace' : 'cruce'), padres: PADRES[k], gm2: gm2(STRAINS[k]) }));
    const gen = Object.entries(GENETICA).map(([k, G]) => ({ k, ...G }));
    const focos = Object.entries(FOCOS).map(([k, F]) => ({ k, ...F, kwh: kwhFoco(k), eur: Math.round(kwhFoco(k) * KWH) }));
    const macetas = Object.entries(MACETAS).map(([k, M]) => ({ k, ...M }));
    const recipes = Object.entries(RECIPES).map(([pair, out]) => ({ a: pair.split('+')[0], b: pair.split('+')[1], out }));
    const G = { grass: '.', flowers: '*', tallgrass: '"', dirt: ':', walk: '-', roadT: '=', roadB: '=', plaza: '+', water: '~', bridgeT: 'H', bridgeB: 'H', dock: '#',
      rotoT: '%', rotoB: '%', hormigon: '_', pista: ',', floor: '.', floorB: '.', floorS: '.', mat: 'm', void: ' ' };
    const O = { tree: 'T', bush: 'b', fence: 'f', sign: 'S', lamp: 'L', bench: 'n', fountain: 'O', crate: 'c', bedT: 'B', bedB: 'B', pc: 'P', lab: 'G', lab2: 'G',
      table: 't', fridge: 'F', shelfW: 's', counter: 'C', display: 'd', plantDeco: 'p', barcounter: 'C', bottles: 's', stool: 'x', btable: 't', jukebox: 'J', iwin: 'v', poster: 'v', carpa: 'K',
      monte: 'M', monte2: 'M', seto: 'h', parada: 'A', tree2: 'T', manzano: 'Y' };
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
    const shop = SHOP.map(s => ({ lbl: s.lbl, p: s.p, ch: s.ch, sid: s.sid, foco: s.foco, maceta: s.maceta, carpa: s.carpa, desc: (s.desc || '').replace(/\n/g, ' · ') }));
    const carpas = Object.entries(CARPAS).map(([k, C]) => ({ k, ...C, tierra: Math.round(C.cm[0] * C.cm[2] / 1e4 * LITROS_M2) }));
    // montajes de ejemplo: Skunk #1 sana y abonada, fenotipo medio, ciclo de 2,5 días
    const S0 = S, sk = { sid: 'ria', prog: 1, water: 100, health: 100, fert: true, pest: false, f: { t: 1, y: 1 } };
    const montajes = [['Armario 60 + CFL 125 W, 2 × 7 L', 'p60', 'cfl', 'plastico7'], ['Armario 60 + LED 200 W, 2 × 7 L', 'p60', 'led200', 'plastico7'],
      ['Carpa 100 + LED 480 W, 4 × 18 L', 'm100', 'led480', 'plastico18'], ['Carpa 150 + LED 720 W, 6 × 25 L', 'g150', 'led720', 'tela25']].map(([n, t, foco, mac]) => {
      S = JSON.parse(JSON.stringify(S0)); S.carpas = [{ t, foco }]; S.macetas = Array(CARPAS[t].plazas).fill(mac);
      const g = huecos().reduce((a, h, i) => a + gramosPlanta(sk, factores(i)), 0), tope = huecos().every((h, i) => gramosPlanta(sk, factores(i)) === MACETAS[mac].cap);
      return { n, g, gw: g / FOCOS[foco].w, luz: luzCarpa(0) * STRAINS.ria.d, tope };
    });
    S = S0;
    const signs = SIGNS;
    return { litrosM2: LITROS_M2, strains, recipes, maps, npcs, items, shop, signs, banco: BANCO, sobre: SOBRE, gen, focos, macetas, carpas, zonas: ZONAS, patrullas: PATRULLAS, paradas: PARADAS, busHoras: BUS_HORAS,
      montajes, c: { CAJA, CAJA_P, CAJA_REDADA, MAITE_CAJA, ENCARGO, PAGO_ENCARGO, ENCARGO_DIAS, SOBORNO, CUOTA_DIAS, KWH, H_LUZ, H_24, W_M2, Y_MEDIA, FENO_ESTRELLA, FENO_FLOJO, ESQUEJE_DIAS, SEMILLA_HERMA, GARRAFA_X, GOTEO_X, DEUDA, PLAZOS, INTERES, PREMIO_COPA, mayor: [precioMayor(12), precioMayor(30)], calle: [precioCalle(12), precioCalle(30)], ROSIN, rosin: [36, 54, 75].map(t => [t, precioRosin(t)]), prensa: SHOP.find(i => i.item === 'prensa').p, IMPERIO, SOBRES, GRANEL } };
  });
  await browser.close();

  const pct = n => String(n).replace('.', ',');
  const name = k => D.strains.find(s => s.k === k).n;
  const ORIGIN = { ria: 'Growshop (cap. 1)', limon: 'Growshop (cap. 2)', txoko: 'Growshop (cap. 2)', niebla: 'Growshop (cap. 3)', mango: 'Growshop (cap. 3)', purpura: 'Growshop (cap. 4)',
    rif: 'Kiko, al montar la mesa de genética: de un amigo de Mazar-i-Sharif (cap. 4)', hindu: 'Txaro, a cambio de 5 g para hacer aceite (parque): del viaje de su marido a Pakistán en 1976', acapulco: 'En un bote de carrete escondido en un arbusto del parque (2,26), «Guerrero, 1979»', malawi: 'Iñaki, el marinero, tras venderle 10 g (muelle): de un marinero de Malaui en Mombasa' };

  for (const [k, p, ch] of D.banco) ORIGIN[k] = `Banco de semillas del PC, sobre de ${D.sobre} por ${p} € (cap. ${ch}; llega al día siguiente)`;
  for (const it of D.shop) if (it.sid) ORIGIN[it.sid] = `Growshop (cap. ${it.ch}), ${it.p} € la semilla`;
  const TIPO = { estable: 'línea estable', f1: 'cruce F1', poli: 'polihíbrido', landrace: 'landrace', cruce: 'cruce (F1 en la mesa)' };
  const n0 = n => String(Math.round(n)).replace(/\B(?=(\d{3})+(?!\d))/g, '.');

  // ---------- GENETICA.md ----------
  let g = `# Genética de Ribera Verde

> Generado automáticamente con \`node tools/generar-docs.js\` a partir de los datos del juego. No editar a mano: cambia \`src/js/03-datos.js\` y regenera.

## Las ${D.strains.length} variedades de la Genoteca

| # | Variedad | THC | Rinde (g/m²) | Días | Resist. | Índica | Tipo | Cogollo | Hoja | Cómo se consigue |
|---|---|---|---|---|---|---|---|---|---|---|
`;
  for (const s of D.strains) {
    const how = ORIGIN[s.k] || 'Cruce: ' + s.o.replace(' · LEGENDARIA', '') + (s.o.includes('LEGENDARIA') ? ' · **legendaria**' : '');
    g += `| ${String(s.idx).padStart(2, '0')} | ${s.n} | ${pct(s.thc)}% | ${s.gm2} | ${pct(s.d)} | ${s.r}% | ${s.ind} % | ${TIPO[s.tipo]}${s.padres ? ' (' + s.padres + ')' : ''} | \`${s.c}\` | \`${s.hj}\` | ${how} |\n`;
  }
  g += `
**Índica** es el % índica (el resto, sativa), con datos reales de cada variedad; **hoja**, el tono de su hoja. Dan la forma de la planta en la carpa (\`porteInd\`): 70 % o más, índica (hoja ancha de 7 foliolos, colas gordas y cortas, internudo corto); menos de 30 %, sativa (9 foliolos finos y largos, colas finas y largas, internudo largo); en medio, híbrida. La sativa tiene la hoja clara y amarillenta; la índica, oscura.

## Historia de cada variedad

Las landraces y los híbridos clásicos de la 1.9 salen del catálogo de Strainmon (\`../src/species.js\`): mismas regiones y perfiles, con su nombre real. Se lee en la Genoteca.

| Variedad | Origen | Historia |
|---|---|---|
`;
  for (const s of D.strains.filter(s => s.h)) g += `| ${s.n} | ${s.o} | ${s.h} |\n`;
  g += `
## Recetas de cruce (${D.recipes.length})

El orden de los padres da igual. Cada cruce gasta 1 semilla de cada padre y da 2 semillas del resultado.

| Madre | Padre | Resultado | THC |
|---|---|---|---|
`;
  for (const r of D.recipes) g += `| ${name(r.a)} | ${name(r.b)} | **${name(r.out)}** | ${pct(D.strains.find(s => s.k === r.out).thc)}% |\n`;
  g += `
## Árbol hasta la Ghost Train Haze

\`\`\`mermaid
flowchart LR
`;
  for (const r of D.recipes) g += `  ${r.a}["${name(r.a)}"] --> ${r.out}["${name(r.out)}"]\n  ${r.b}["${name(r.b)}"] --> ${r.out}\n`;
  g += `  style leyenda fill:#40e0a0,color:#062\n\`\`\`

## Estabilizar (F1 → estable)

Lo que sale de un cruce nuevo (receta o híbrido propio) es una **F1**: una línea inestable en la que cada planta sale distinta.

- En la mesa de genética, al elegir como padre la misma variedad («· estabilizar»), se cruzan dos plantas de la línea: gasta 2 semillas, guarda 1 y sube una generación (F1 → F2 → F3 → **estable** en la F4). Entre generaciones hay que cultivar la línea para tener otra vez 2 semillas.
- Una línea sin fijar la estás criando: sus plantas se polinizan entre ellas y cada una da 2-5 semillas al cosecharla (las demás: las de tienda son feminizadas y casi nunca dan, ${pct(D.c.SEMILLA_HERMA * 100)} % de que una flor hermafrodita deje 1-3; las landraces (como el Afghani que te da Kiko) y tus líneas ya fijadas son regulares y algún macho poliniza unas flores: 1-3 por planta).
- Las landraces y las de la tienda llevan su tipo genético (abajo); las de receta, estabilizadas, son líneas estables.

## Fenotipos (1.10)

Cada semilla es una planta distinta. Al germinar, tira su fenotipo: THC × (1 + σ·z) y gramos × (1 + σ·z), cada uno por su lado (z normal; entre ×0,6 y ×1,5). σ depende de lo pura que sea la genética. Si THC × gramos ≥ ${pct(D.c.FENO_ESTRELLA)}, es un **fenotipo estrella**: va a un lote aparte (★) que se vende y se presenta a la Copa por separado. Si ≤ ${pct(D.c.FENO_FLOJO)}, es **floja**. El fenotipo se sabe al cosecharla.

| Tipo | σ | σ índica | Estrella | Qué es |
|---|---|---|---|---|
`;
  for (const t of D.gen) g += `| ${t.n} | ${pct(t.sigma)} | ${t.si} | 1 de cada ~${n0(t.uno)} | ${t.d} |\n`;
  g += `
Cada planta tira también su % índica alrededor del de su variedad (σ índica, en puntos): da su forma y el tono de su hoja, así que hasta que la línea se estabiliza (F4) cada planta sale distinta; una línea estable sale toda igual.

Con 50 semillas de un polihíbrido sale de media casi 1 estrella (58 % de que salga al menos una); con 50 de una línea estable, casi nunca. \`test-historia\` tira 200.000 plantas de cada tipo y comprueba esas tasas.

**Esquejes:** a una planta en crecimiento (20-65 %) se le saca un esqueje (−5 de salud): es la misma planta, con su fenotipo. Enraíza en el propagador (hasta 12) y hay que plantarlo antes de que acabe el día siguiente (${D.c.ESQUEJE_DIAS} día de juego ≈ 4 semanas); entra ya de plántula (12 %). Cuando cosechas la madre o un clon y sale estrella, sus esquejes se marcan con ★: así se guarda un fenotipo.
`;
  g += `

## Híbridos propios (cruces sin receta)

Cualquier pareja que no esté en la tabla de recetas genera un híbrido «propio», determinista (la misma pareja da siempre el mismo resultado) y guardado en \`S.custom\`:

- **Nombre:** primera palabra de la madre + última palabra del padre (si coincide con un padre, al revés; si ya existe, se añade «F2…F8»).
- **THC:** media de los padres + aleatorio entre −1,5 y +2,0 (tope 33 %).
- **Rendimiento:** media ± 4 g. **Días:** media ± 0,3 (redondeado a medios días). **Resistencia:** media ± 5 (entre 20 y 95).
- **De la madre y del padre:** en un cruce nuevo (sin receta), la madre (la primera que eliges) pasa un m % al azar entre 30 y 70 y el padre el resto. El híbrido se guarda la primera vez: si luego cruzas las mismas al revés, sale el mismo, con la madre y el reparto de entonces (la ficha lo enseña: «60 % madre · 40 % padre»). Con ese reparto se mezclan el % índica, el tono de la hoja y el color del cogollo.
- Aparecen en la Genoteca con ★ y cuentan para el objetivo de «descubrir 8 variedades».

## Fórmulas de cultivo

- **Crecimiento por hora:** \`1 / (días × 24) × crec\`, ×0,4 si el agua < 20 %, 0 si el agua llega a 0, ×1,1 con abono. \`crec\`, \`thc\` y \`riego\` salen del foco (a plena intensidad desde ${D.c.W_M2} W/m²) y de la maceta de cada plaza; \`crec\`, también del clima de la sala (−6 % por grado fuera de 18-30 °C, hasta ×0,4; −1,5 % por punto fuera del 40-60 % de humedad, hasta ×0,7). Equipo, precios y luz: [ECONOMIA.md](ECONOMIA.md).
- **Agua:** baja 3,5 × riego puntos por hora (con CFL y maceta de 7 L una planta regada aguanta ~28 h). El riego automático riega solo la que baja del 50 %: las garrafas (${String(D.c.GARRAFA_X).replace('.', ',')} L por litro de tierra de la maceta, media cosecha) o el depósito del goteo (${String(D.c.GOTEO_X).replace('.', ',')} L por litro de tierra que admite la carpa, unas cinco cosechas con la carpa llena).
- **Salud:** −4/h sin agua, −2,5/h con plaga, +1/h si agua > 30 % y sin plaga; en floración, moho con la humedad por encima del 60 %: −0,1/h por punto de más. A 0 la planta muere.
- **Plagas:** probabilidad por hora \`0,006 × (100 − resistencia) / 40\` mientras no está madura.
- **Cosecha (g):** \`mín(tope de la maceta, W × g/W ÷ plazas de la carpa × rend de la maceta × rinde/${D.c.Y_MEDIA} × (0,4 + 0,6 × salud/100) × (abono ? 1,25 : 1) × fenotipo)\`. Una plaza vacía es luz perdida.
- **THC final:** \`THC × fenotipo × (0,85 + 0,15 × salud/100) + thc del foco + (abono ? 0,3 : 0)\` (tope 35 %).
- **Rinde (g/m²) de la tabla:** lo que daría con un LED a ${D.c.W_M2} W/m², abonada y sana.
`;
  fs.writeFileSync(path.join(ROOT, 'docs/GENETICA.md'), g);

  // ---------- ECONOMIA.md ----------
  const c = D.c, eu = n => n0(n) + ' €', dec = n => String(Math.round(n * 100) / 100).replace('.', ',');
  const precio = f => (D.shop.find(f) || {}).p;
  let e = `# Economía de Ribera Verde (1.10)

> Generado automáticamente con \`node tools/generar-docs.js\` a partir de los datos del juego. No editar a mano: cambia \`src/js/09-cultivo.js\`, \`10-calle.js\` u \`11-historia.js\` y regenera.

Desde la 1.10, unidades, precios y potencias son los reales de un growshop y un cultivo de interior en España. Lo único comprimido es el tiempo: una cosecha dura de 2,5 a 5 días de juego (unas 4 semanas reales por día), así que lo que va «por día» (la luz) cuenta las horas de esas 4 semanas.

## Focos

Un día de juego cuenta ${c.H_LUZ} h de foco (4 semanas a 18 h en crecimiento y 12 h en floración) a ${dec(c.KWH)} €/kWh. g/W: gramos por vatio de una cosecha con la carpa llena, sin abono (abonando, ×1,25).

| Foco | Precio | Ilumina | g/W | kWh/día | Luz/día | Desde |
|---|---|---|---|---|---|---|
`;
  for (const F of D.focos) { const it = D.shop.find(s => s.foco === F.k); e += `| ${F.n} | ${it ? eu(it.p) : 'de serie'} | ${F.lado}×${F.lado} cm | ${dec(F.gpw)} | ${F.kwh} | ${eu(F.eur)} | ${it ? 'cap. ' + it.ch : '—'} |\n`; }
  e += `
## Carpas y macetas

| Carpa | Precio | Plazas | Foco máx. | Maceta máx. | Tierra máx. (todas las macetas) |
|---|---|---|---|---|---|
`;
  for (const C of D.carpas) { const it = D.shop.find(s => s.carpa === C.k); e += `| ${C.n}×${C.cm[1]} | ${it ? eu(it.p) + ' (cap. ' + it.ch + ')' : 'la de la tía'} | ${C.plazas} | ${C.wmax} W | ${C.lmax} L | ${C.tierra} L |\n`; }
  e += `
La tierra de todas las macetas de una carpa no pasa de ${D.litrosM2} L por m² de suelo (\`LITROS_M2\`: 4 macetas de 25 L en 1 m²); «Cambiar maceta» no ofrece las que la pasarían.

| Maceta | Precio | Tope por planta | Extra |
|---|---|---|---|
`;
  for (const M of D.macetas) { const it = D.shop.find(s => s.maceta === M.k); e += `| ${M.n} | ${it ? eu(it.p) : 'de serie'} | ${M.cap} g | ${M.rend > 1 ? 'tela: +5 % y menos plagas' : '—'} |\n`; }
  e += `
Tope: unos 8 g por litro de tierra (la de tela, +5 %). Por mucho foco que pongas, una planta en 7 L no pasa de ${D.macetas[0].cap} g.

Extras: ventilador ${eu(precio(s => s.lbl.startsWith('Ventilador')))} (25 W día y noche), extractor con filtro de carbón ${eu(precio(s => s.lbl.startsWith('Extractor')))} (75 W día y noche; ${c.H_24} h por día de juego), garrafas de riego ${eu(precio(s => s.lbl.startsWith('Garrafas')))} y riego por goteo ${eu(precio(s => s.lbl.startsWith('Riego')))}.

## Cuánto da una cosecha

\`gramos por planta = mín(tope de la maceta, W × g/W ÷ plazas × rend de la maceta × rinde de la variedad / ${c.Y_MEDIA} × salud × abono × fenotipo)\`

Skunk #1 sana y abonada, fenotipo medio (cosecha de 2,5 días):

| Montaje | Gramos por cosecha | g/W | Luz por cosecha |
|---|---|---|---|
`;
  for (const m of D.montajes) e += `| ${m.n} | ${m.g} g${m.tope ? ' (tope de la maceta)' : ''} | ${dec(m.gw)} | ${eu(m.luz)} |\n`;
  e += `
## Vender

- **Calle:** ${dec(c.calle[0])}-${dec(c.calle[1])} €/g según el THC (× 0,85 estudiante, × 1 currela, × 1,15 turista, × 1,35 pijo; rebaja × 0,85, caro × 1,3). Cada cliente quiere 2-12 g.
- **Al por mayor (Iñaki, en el muelle, desde el capítulo 3):** ${dec(c.mayor[0])}-${dec(c.mayor[1])} €/g, lotes de 100 g para arriba, una carga al día de hasta ${dec(c.IMPERIO[0].mayor / 1000)} kg (más en el imperio). Cada carga sube el calor 2 + 1 por cada 100 g.
- **Rosin (desde el capítulo 3, con la prensa de Kiko, ${c.prensa} €):** en la mesa del piso, ${dec(c.ROSIN.rend * 100)} % del peso de la flor con ${c.ROSIN.thc} veces su THC (hasta el ${c.ROSIN.tope} %), en media hora. Lo compran los catadores (bocadillo con una gota ámbar; 1-3 g; 2 al día en el barrio y 1 en los astilleros, en Puerto Viejo y en Valdehierro) a ${c.rosin.map(([t, p]) => `${dec(p)} €/g al ${t} %`).join(', ')}: prensar compensa desde el 12,5 % de THC de la flor. Cada gramo vendido sube el calor 2,5 (la flor, 0,5).
- **Zonas:** ${Object.values(D.zonas).filter(z => z.precio !== 1).map(z => `en ${z.n === 'Astilleros' ? 'los astilleros' : z.n}, el gramo × ${dec(z.precio)}`).join('; ')} (las esquinas de Darko: 1 de cada 3 ventas acaba en pelea).
- **Encargos de Don Baltasar (capítulo 8):** ${c.PAGO_ENCARGO} €/g por ${[...new Set(c.ENCARGO)].map(g => dec(g / 1000)).join(', ').replace(/, ([^,]*)$/, ' o $1')} kg según el rango del imperio, entregados de noche en el almacén de los astilleros en ${c.ENCARGO_DIAS} días.
- **Multas:** policía en la calle, 601 € (la mínima de la Ley de Seguridad Ciudadana); redada en el piso, hasta 3.000 € y se llevan las plantas y los cogollos de fuera de la caja fuerte.
- **Protección del sargento Molina:** ${eu(c.SOBORNO)} cada ${c.CUOTA_DIAS} días.

## La caja fuerte

Lo que hay dentro no va encima: no cuenta para los encuentros ni se lo llevan un control, un ladrón o Darko. En una redada la encuentran ${Math.round(c.CAJA_REDADA * 100)} de cada 100 veces (sus gramos y la mitad de su dinero).

| Caja | Cómo se consigue | Capacidad |
|---|---|---|
| ${c.CAJA[1].n} | Detrás del diploma (la combinación, en las notas del ordenador), con ${eu(c.MAITE_CAJA)} dentro | ${eu(c.CAJA[1].money)} y ${dec(c.CAJA[1].g / 1000)} kg |
| ${c.CAJA[2].n} | Por el ordenador desde el capítulo 4, con la de la tía ya abierta: ${eu(c.CAJA_P)}. La instala Kiko al día siguiente, con lo que ya hubiera dentro | ${eu(c.CAJA[2].money)} y ${dec(c.CAJA[2].g / 1000)} kg |

## Semillas

Feminizadas de tienda, ${D.shop.filter(s => s.sid).map(s => s.lbl.replace('Semillas ', '') + ' ' + eu(s.p)).join(', ')} la semilla. Sobres: ${c.SOBRES.map(([n, f]) => n + (f < 1 ? ' (−' + Math.round((1 - f) * 100) + ' %)' : '')).join(', ')}; desde el capítulo 3, bolsa de ${c.GRANEL[0]} a granel (−${Math.round((1 - c.GRANEL[1]) * 100)} %). Landraces del banco del PC: sobres de ${D.sobre} por 20-45 €.

## La deuda

${eu(c.DEUDA)} en tres plazos: ${eu(c.PLAZOS[3])} en 7 días (capítulo 3), ${eu(c.PLAZOS[5])} en 10 días (capítulo 5) y ${eu(c.PLAZOS[7])} en 7 días tras la Copa (capítulo 7; el premio de la Copa son ${eu(c.PREMIO_COPA)}). El primer plazo corre desde que aparece Toño. Si un plazo vence, Toño suma un ${Math.round(c.INTERES * 100)} % del plazo y da 5 días más; al tercer plazo vencido, además, se lleva la carpa más grande del piso (sin carpas, la mitad del dinero que llevas encima).

Por qué ${eu(c.DEUDA)}: con equipo, precios y venta al por mayor reales, un jugador que reinvierte cada cosecha en lo que más rinde por euro (focos LED, macetas grandes, carpas) paga el primer plazo en unas 4 cosechas (6 días), el segundo en unas 8 y el último en unas 9: lo mismo que la deuda de 5.000 € con los números de la 1.9 (3, 5 y 11 cosechas). Con los plazos viejos, la historia se acabaría en 7 cosechas.

## Tu imperio

Saldada la deuda, el juego sigue: cada rango se gana facturando desde el último pago y sube lo que Iñaki carga al día.

| Rango | Facturado | Carga al día |
|---|---|---|
`;
  for (const r of c.IMPERIO) e += `| ${r.n} | ${eu(r.meta)} | ${r.mayor >= 1000 ? dec(r.mayor / 1000) + ' kg' : r.mayor + ' g'} |\n`;
  fs.writeFileSync(path.join(ROOT, 'docs/ECONOMIA.md'), e);

  // ---------- MAPA.md ----------
  const legend = `Leyenda: \`.\` suelo/hierba · \`*\` flores · \`"\` hierba alta (ladrones ×3, a cualquier hora) · \`:\` tierra · \`-\` acera · \`=\` carretera · \`%\` carretera rota (baches y parches) · \`_\` hormigón · \`,\` pista de tierra · \`+\` plaza · \`~\` agua · \`H\` puente · \`#\` muelle
\`^\` tejado · \`█\` pared/ventana · \`D\` puerta · \`T\` árbol · \`Y\` manzano · \`b\` arbusto · \`$\` arbusto con objeto oculto · \`i\` objeto en el suelo · \`f\` valla · \`S\` cartel · \`L\` farola · \`n\` banco · \`O\` fuente · \`c\` cajas · \`@\` personaje · \`M\` monte (el bosque de los lindes) · \`h\` seto · \`A\` parada del autobús
Interiores: \`B\` cama · \`P\` ordenador · \`G\` mesa de genética · \`t\` mesa · \`F\` nevera · \`K\` carpa (mueble: el armario de 60 u 80 en x 8, la carpa de 100 o 150 en x 10-11 y la de 120 en x 2-3; sus plazas se ven por dentro, en la vista de carpa) · \`C\` mostrador · \`s\` estantería · \`d\` expositor · \`x\` taburete · \`J\` gramola · \`v\` ventana/póster · \`m\` felpudo (salida)`;
  let m = `# Mapa de Ribera Verde

> Generado automáticamente con \`node tools/generar-docs.js\`. Coordenadas (x, y) en casillas de 16 px; (0,0) es la esquina superior izquierda.

${legend}
`;
  const titles = { town: 'Barrio (exterior) — 40 × 30', home: 'Piso de la tía Maite — 12 × 8 (1 casilla = 1 m; con el armario de 60 y la carpa de 150)', shop: 'Growshop Kiko — 10 × 8', bar: 'Bar El Ancla — 10 × 8',
    alto: 'Barrio alto (exterior, al norte) — 40 × 30', astilleros: 'Astilleros (exterior, al este del muelle) — 40 × 30', txaro: 'Casa de la abuela Txaro — 10 × 8',
    comisaria: 'Comisaría del barrio alto — 10 × 8', almacen: 'Almacén de los astilleros — 10 × 8',
    mendialde: 'Mendialde (pueblo de caseríos, de donde eres; el prólogo) — 48 × 34', 'casa-ama': 'Caserío de la familia, en Mendialde — 10 × 8',
    puerto: 'Puerto Viejo (ciudad pequeña, pesquera) — 40 × 24', valdehierro: 'Valdehierro (ciudad pequeña, del hierro) — 40 × 24',
    errotabarri: 'Errotabarri (pueblo del molino) — 36 × 24' };
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
  m += `\nLos **clientes** ($) aparecen cada día desde el capítulo 2 en casillas de acera, plaza y tierra: en el barrio, 4 + reputación/15 (+1 desde el capítulo 4, máximo 10); en los astilleros, 2 (3 desde el capítulo 4), estudiantes y currelas, que pagan el gramo un 20 % más; en el barrio alto, desde el capítulo 3, 2 (3 desde el 4), pijos y turistas; en Puerto Viejo, 2 (3 desde el 4), turistas, currelas y estudiantes; en Valdehierro, 2 (3 desde el 4), estudiantes y currelas; y en los pueblos, 1: un currela en Mendialde y un currela o un turista en Errotabarri.\n`;
  const P0 = D.paradas, hh = m => `${Math.floor(m / 60)}:${String(m % 60).padStart(2, '0')}`;
  m += `\n## Autobús de la comarca\n\nEn el poste de cada parada (\`A\`), de ${hh(D.busHoras[0])} a ${hh(D.busHoras[1])}. Cada parada está a un tramo de Ribera Verde; entre dos de fuera se suman los dos tramos. El reloj corre lo que dura el viaje. El primero (Mendialde → Ribera Verde, en el prólogo) lo paga ama.\n\n| Parada | Posición | Llegas a | Desde Ribera Verde |\n|---|---|---|---|\n`;
  for (const [k, p] of Object.entries(P0)) m += `| ${p.n} | ${k} (${p.x},${p.y}) | (${p.a[0]},${p.a[1]}) | ${k === 'town' ? '—' : `${p.min} min · ${p.eur} €`} |\n`;
  m += `\n**Zonas** (\`ZONAS\` y \`PATRULLAS\`): factor de ladrones y de precio en cada mapa de fuera, y los agentes que patrullan de día y de noche (desde el capítulo 2). ${Object.entries(D.zonas).map(([k, z]) => `${z.n}: ladrones ×${String(z.lad).replace('.', ',')}, precio ×${String(z.precio).replace('.', ',')}, ${D.patrullas[k].join('/')} agentes`).join(' · ')}. Dentro de las casas no hay encuentros.\n`;
  m += `\n## Objetos\n\n| id | Posición | Tipo | Contenido |\n|---|---|---|---|\n`;
  for (const i of D.items) m += `| ${i.id} | ${i.map} (${i.x},${i.y}) | ${i.hidden ? 'oculto en arbusto (pulsa A delante)' : 'bolsa en el suelo'} | ${i.give || ''} |\n`;
  m += `\n## Carteles\n\n`;
  for (const [k, v] of Object.entries(D.signs)) m += `- **${k}** — ${v.replace(/\n/g, ' · ')}\n`;
  m += `\n## Tienda de Kiko\n\n| Artículo | Precio | Desde cap. | Nota |\n|---|---|---|---|\n`;
  for (const s of D.shop) m += `| ${s.lbl} | ${n0(s.p)} € | ${s.ch} | ${s.desc} |\n`;
  fs.writeFileSync(path.join(ROOT, 'docs/MAPA.md'), m);
  console.log('docs/GENETICA.md, docs/ECONOMIA.md y docs/MAPA.md regenerados');
})();

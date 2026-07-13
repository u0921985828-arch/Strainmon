/* ============================================================
   PHENO HUNTER — world.js
   Mapas por tiles, colisiones, warps, flora y NPCs.
   ============================================================ */
(function (PH) {
  'use strict';

  const TILE = {
    '.': { name: 'grass', solid: false },
    ',': { name: 'tallgrass', solid: false, enc: true },
    'T': { name: 'tree', solid: true },
    '#': { name: 'rock', solid: true },
    'W': { name: 'water', solid: true },
    '~': { name: 'deepwater', solid: true },
    'P': { name: 'path', solid: false },
    'H': { name: 'house', solid: true },
    'D': { name: 'door', solid: true },
    'F': { name: 'flowers', solid: false },
    'b': { name: 'bush', solid: true },
    's': { name: 'sand', solid: false },
    'm': { name: 'mud', solid: false, enc: true },
    'n': { name: 'snow', solid: false },
    'c': { name: 'cavefloor', solid: false },
    '=': { name: 'bridge', solid: false },
    'l': { name: 'lava', solid: true },
    'r': { name: 'ash', solid: false },
    'i': { name: 'ice', solid: false },
    'o': { name: 'stalag', solid: true },
    'p': { name: 'palm', solid: true },
  };
  const isWarp = (ch) => ch >= '0' && ch <= '9';

  /* ------------------------- CIUDAD (hub) ------------------------- */
  const laboratorio = {
    id: 'lab', name: 'Villa Semilla', biome: null, theme: 'town',
    grid: [
      'TTTTTTTTTTTTTTTTTTTT',
      'T..................T',
      'T..HHHH....HHHH....T',
      'T..HHHH....HHHH....T',
      'T..H1HH....HH2H....T',
      'T..PP........PP....T',
      'T...P........P.....T',
      'T...PPPPPPPPPP.....T',
      'T........P.........T',
      'T..FF....P....FF...T',
      'T..FF....P....FF...T',
      'T........P.........T',
      'T..HHHHH.P.........T',
      'T..H3HHH.P.........T',
      'T..PPPPP.P.........T',
      'T........P.........T',
      'T........P.........T',
      'TTTTTTT00TTTTTTTTTTT',
    ],
    warps: {
      '0': { to: 'pradera', x: 9, y: 1 },
      '1': { to: '@lab_interior', name: 'Laboratorio' },
      '2': { to: '@tienda', name: 'Mercado' },
      '3': { to: '@casa', name: 'Tu casa' },
    },
    npcs: [
      { id: 'mentor', x: 9, y: 8, name: 'Dra. Elna', sprite: 'mentor', dialog: 'mentor' },
      { id: 'coleccionista', x: 15, y: 9, name: 'Bru', sprite: 'npc2', dialog: 'coleccionista' },
      { id: 'criador', x: 4, y: 9, name: 'Wex', sprite: 'npc3', dialog: 'criador' },
      { id: 'genetista', x: 12, y: 5, name: 'Dr. Vane', sprite: 'npc5', dialog: 'genetista' },
    ],
    spawn: { x: 9, y: 15 },
  };

  /* ------------------------- PRADERA ------------------------- */
  const pradera = {
    id: 'pradera', name: 'Altiplano de Michoacán', biome: 'pradera', theme: 'meadow',
    grid: [
      'TTTTTTTT00TTTTTTTTTT',
      'T....,,....,,......T',
      'T..,,,,..FF,,,,....T',
      'T..,,,,....,,,,..b.T',
      'T....PP....PP......5',
      'T....P......P......5',
      'T,,..P.,,,,.P..,,..T',
      'T,,..P.,,,,.P..,,..T',
      'T....P......P......T',
      'T....PPPPPPPP......T',
      'T.......P.........bT',
      'T..b....P....,,....T',
      'T.......P....,,....T',
      'TWWWW...P.........,T',
      'TWWWW===P====......T',
      'T~~~~...P....,,,,..T',
      'T.......P....,,,,..T',
      'TTTTTTT11TTTTTT22TTT',
    ],
    warps: {
      '0': { to: 'lab', x: 9, y: 16 },
      '1': { to: 'bosque', x: 9, y: 1 },
      '2': { to: 'pantano', x: 3, y: 1 },
      '5': { to: 'desierto', x: 1, y: 9 },
    },
    npcs: [{ id: 'explorador', x: 14, y: 11, name: 'Ino', sprite: 'npc4', dialog: 'explorador' }],
    spawn: { x: 9, y: 2 },
  };

  /* ------------------------- BOSQUE ------------------------- */
  const bosque = {
    id: 'bosque', name: 'Triángulo Dorado', biome: 'bosque', theme: 'forest',
    grid: [
      'TTTTTTTT00TTTTTTTTTT',
      'T..TT..PP..TT..TTT.T',
      'T.,,T..P...T,,.TT..T',
      'T.,,...P...,,,,....T',
      'T....T.P.T....,,...T',
      'TT,,.T.P.T.TT..,,..T',
      'T.,,...P......TT...T',
      'T....TTPTT........,T',
      'T.b....P....,,,,..,T',
      'T....,,P,,...,,,,..T',
      'T..T.,,P,,...T.....T',
      'T....,,P........TT.T',
      'TTT..T.P..TT...T...T',
      'T..,,..P...,,......T',
      'T..,,..PPPPPPPP....T',
      'T.....TT......P..TTT',
      'T..b.......TT.P...bT',
      'TTTTTTTTTTTTT33TTTTT',
    ],
    warps: {
      '0': { to: 'pradera', x: 9, y: 16 },
      '3': { to: 'cueva', x: 9, y: 1 },
    },
    npcs: [{ id: 'botanica', x: 4, y: 8, name: 'Sella', sprite: 'npc5', dialog: 'botanica' }],
    spawn: { x: 9, y: 2 },
  };

  /* ------------------------- PANTANO ------------------------- */
  const pantano = {
    id: 'pantano', name: 'Delta del Congo', biome: 'pantano', theme: 'swamp',
    grid: [
      'TTT00TTTTTTTTTTTTTTT',
      'T..P....mm....WWW..T',
      'T..P.mmmmmm...WWW..T',
      'T..PPP.mm.....mm...T',
      'Tmm..P........mm...T',
      'Tmm..P..mmmm......bT',
      'T....PPP.mm...mmm..T',
      'TWW....P......mm...T',
      'TWW....P...mmmm....T',
      'T~~....PPP....mm...T',
      'T........P..mmmm...T',
      'Tmm......P...mm....T',
      'Tmm..mm..P........,T',
      'T....mm..PPPP.....,T',
      'T.......mm..P..mm..T',
      'T..b....mm..P..mm..T',
      'T...........P.....bT',
      'TTTTTTTTTTTT44TTTTTT',
    ],
    warps: {
      '0': { to: 'pradera', x: 15, y: 16 },
      '4': { to: 'isla', x: 9, y: 1 },
    },
    npcs: [{ id: 'contrabandista', x: 4, y: 12, name: 'Kez', sprite: 'npc6', dialog: 'contrabandista' }],
    spawn: { x: 3, y: 1 },
  };

  /* ------------------------- DESIERTO ------------------------- */
  const desierto = {
    id: 'desierto', name: 'Rif de Marruecos', biome: 'desierto', theme: 'desert',
    grid: [
      'TT###############TTT',
      '0ss,,.sss,,ss..sssbT',
      'ssss..s,,s..ss,,sssT',
      'Tss,,ss..sssss..ssbT',
      'Tsssss.b.ss,,s.ssssT',
      'Ts,,s.sssss..ss,,ssT',
      'Tssss.s,,ss.ssssssbT',
      'Ts.b.ss..s,,ss.s,,sT',
      'Tss,,sssss..sss..ssT',
      'Ts..ssb.ss,,ss.sssbT',
      'Tsss,,s.sssss.s,,ssT',
      'Ts.ssss.b.ss..ssssbT',
      'Ts,,s.ssss,,sssss..T',
      'Tssss.s,,ss.sss.b.sT',
      'Ts.b.sssss..ss,,sssT',
      'Tss,,s.sss,,ssss..sT',
      'Tssssssss..sssss66sT',
      'TT##############TTTT',
    ],
    warps: {
      '0': { to: 'pradera', x: 18, y: 4 },
      '6': { to: 'volcan', x: 9, y: 1 },
    },
    npcs: [{ id: 'nomada', x: 10, y: 8, name: 'Zahra', sprite: 'npc4', dialog: 'nomada' }],
    spawn: { x: 1, y: 1 },
  };

  /* ------------------------- VOLCÁN ------------------------- */
  const volcan = {
    id: 'volcan', name: 'Cráteres de Oaxaca', biome: 'volcan', theme: 'volcano',
    grid: [
      'TTTTTTTT00TTTTTTTTTT',
      'T#rr,,rr#rrr,,rr##.T',
      'T#rrrrr#rr,,rrrr#..T',
      'Trr,,rrr#lll#rr,,r.T',
      'Trrrrr,,#lll#,,rrr.T',
      'T#rr#rrr#ll#rrrr#r.T',
      'Trr,,rr#lll#rr,,rr.T',
      'Trrrrrr#ll#rrrrrrr.T',
      'T#r,,r#lll#r,,rr#r.T',
      'Trrrrr#ll#rr,,rrrr.T',
      'Trr,,rrr##rrrrr,,r.T',
      'Trrrrr,,rrrr,,rrrrrT',
      'T#rrr#rrrr#rrrr#rr.T',
      'Trr,,rrrrrrrr,,rrr.T',
      'Trrrrrrr,,rrrrrrrrrT',
      'Tr,,rrr#rr#rr,,rrr.T',
      'Trrrrrrrrrrrrrrr77.T',
      'TTTTTTTTTTTTTTTTTTTT',
    ],
    warps: {
      '0': { to: 'desierto', x: 9, y: 16 },
      '7': { to: 'nieve', x: 9, y: 16 },
    },
    npcs: [{ id: 'vulcanologo', x: 4, y: 11, name: 'Draco', sprite: 'npc6', dialog: 'vulcanologo' }],
    spawn: { x: 9, y: 2 },
  };

  /* ------------------------- NIEVE ------------------------- */
  const nieve = {
    id: 'nieve', name: 'Cumbres del Hindú Kush', biome: 'nieve', theme: 'snow',
    grid: [
      'TTTTTTTTTTTTTTTTTTTT',
      'Tnn,,nnnn,,nnnn,,n.T',
      'Tnnnniinnnnii nnnn.T',
      'Tn,,nnnn,,nniinn,,.T',
      'Tnnii nn,,nnnnnnii.T',
      'Tn,,nnnnnniinn,,nn.T',
      'Tnnnn,,nn nniinnnn.T',
      'Tnniinn nn,,nn,,nn.T',
      'Tn,,nn,,nniinnnnii.T',
      'Tnnnnnnnn nn,,nnnn.T',
      'Tnii,,nn,,nniinn,,.T',
      'Tnnnnnnnniinnnnnnn.T',
      'Tn,,nnii,,nn,,nniin.T',
      'Tnnnn,,nnnnnnii nn.T',
      'Tnniinnnn,,nn,,nnn.T',
      'Tn,,nn,,nnii nnnn..T',
      'Tnnnnnnnnnnnnnnn88.T',
      'TTTTTTTTTTTTTTTTTTTT',
    ],
    warps: {
      '8': { to: 'volcan', x: 9, y: 1 },
    },
    npcs: [{ id: 'glaciologa', x: 5, y: 9, name: 'Frey', sprite: 'npc5', dialog: 'glaciologa' }],
    spawn: { x: 9, y: 15 },
  };

  /* ------------------------- CUEVA ------------------------- */
  const cueva = {
    id: 'cueva', name: 'Cuevas de Chitral', biome: 'cueva', theme: 'cave',
    grid: [
      '####################',
      '#cc,,cco cccc,,cccc#',
      '#ccccco ccc,,ccooc.#',
      '#cc,,cccooc cccc,,c#',
      '#cccco,,ccccoccccc.#',
      '#occ ccc,,ccc ,,cco#',
      '#cc,,ccoocccccooccc#',
      '#cccccc ccc,,cc,,cc#',
      '#occ,,ccooc cccccco#',
      '#ccccccc,,cccc,,ccc#',
      '#cc,,ccoocccoocccc.#',
      '#cccccccc,,cccccooc#',
      '#occ,,ccc ccc,,cccc#',
      '#ccccooc,,cccccccc.#',
      '#cc,,ccccooc,,ccooc#',
      '#cccccccccccccccc99#',
      '####################',
    ],
    warps: {
      '9': { to: 'bosque', x: 9, y: 16 },
    },
    npcs: [{ id: 'espeleologo', x: 6, y: 8, name: 'Mox', sprite: 'npc6', dialog: 'espeleologo' }],
    spawn: { x: 9, y: 15 },
  };

  /* ------------------------- ISLA ------------------------- */
  const isla = {
    id: 'isla', name: 'Costa de Jamaica', biome: 'isla', theme: 'island',
    grid: [
      '~~~~~~~~WW~~~~~~~~~~~',
      '~~WWssssssssssWW~~~~',
      '~Wsss,,ssp ss,,sssW~',
      '~Wssssssss,,ssspssW~',
      '~Wsp,,ssFFss.ss,,sW~',
      '~Wsssss.p.sssss.ssW~',
      '~Wss,,sssss,,ss.spW~',
      '~Wpsssss.b.sssss,,W~',
      '~Wss,,ss,,sssspss.W~',
      '~Wssssssssss,,sssW~~',
      '~~Wss,,ssp ss.sssW~~',
      '~~Wsssss,,ssss,,sW~~',
      '~~~Wssssssssssss W~~',
      '~~~~WWsssssssWWW~~~~',
      '~~~~~~WW==WW~~~~~~~~~',
      '~~~~~~~=aa=~~~~~~~~~~',
      '~~~~~~~~WW~~~~~~~~~~~',
      '~~~~~~~~~~~~~~~~~~~~~',
    ],
    warps: {
      'a': null, // decorativo (muelle)
    },
    npcs: [{ id: 'marinera', x: 9, y: 6, name: 'Nira', sprite: 'npc2', dialog: 'marinera' }],
    spawn: { x: 9, y: 4 },
    exitBack: { to: 'pantano', x: 9, y: 2 }, // salir por el muelle
  };
  // La isla se sale interactuando: añadimos un warp de retorno en las celdas inferiores
  isla.grid[15] = '~~~~~~~b0b~~~~~~~~~~~';
  isla.warps['0'] = { to: 'pantano', x: 9, y: 2 };

  const MAPS = { lab: laboratorio, pradera, bosque, pantano, desierto, volcan, nieve, cueva, isla };

  // Normaliza cada mapa a una cuadrícula rectangular (robusto ante erratas).
  (function normalizeAll() {
    const FILL = { cave: '#', desert: '#', volcano: 'T', island: '~', snow: 'T' };
    for (const m of Object.values(MAPS)) {
      const fill = FILL[m.theme] || 'T';
      let w = 0; for (const r of m.grid) w = Math.max(w, r.length);
      m.grid = m.grid.map(r => r.length < w ? r + fill.repeat(w - r.length) : r.slice(0, w));
    }
  })();

  function tileAt(map, x, y) {
    if (y < 0 || y >= map.grid.length) return '#';
    const row = map.grid[y];
    if (x < 0 || x >= row.length) return '#';
    return row[x];
  }
  function solidAt(map, x, y) {
    const ch = tileAt(map, x, y);
    if (isWarp(ch)) return false;
    const t = TILE[ch];
    return t ? !!t.solid : true;
  }
  function encounterAt(map, x, y) {
    const ch = tileAt(map, x, y);
    const t = TILE[ch];
    return !!(t && t.enc);
  }
  function warpAt(map, x, y) {
    const ch = tileAt(map, x, y);
    if (isWarp(ch)) return map.warps[ch] || null;
    return null;
  }
  function dims(map) { return { w: map.grid[0].length, h: map.grid.length }; }

  // Mapea id de región a su bioma (para desbloqueos por prestigio)
  const REGION_ORDER = ['pradera', 'bosque', 'cueva', 'pantano', 'isla', 'desierto', 'volcan', 'nieve'];

  PH.world = { TILE, MAPS, isWarp, tileAt, solidAt, encounterAt, warpAt, dims, REGION_ORDER };
})(window.PH = window.PH || {});

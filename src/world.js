/* ============================================================
   PHENO HUNTER — world.js
   Mapas por tiles, colisiones, warps, flora y NPCs.
   Mapas definidos como cuadrículas de caracteres para legibilidad.
   ============================================================ */
(function (PH) {
  'use strict';

  // Leyenda de tiles:
  //  .  césped        ,  césped alto (flora/encuentros)
  //  T  árbol         #  roca/pared    W  agua       ~  agua profunda
  //  P  camino        H  edificio      D  puerta (bloqueante deco)
  //  F  flores deco   b  arbusto       s  arena       m  barro/pantano
  //  n  nieve         c  suelo cueva   =  puente
  //  Dígitos 0-9 = warps (definidos por mapa)
  //  Letras mayúsculas reservadas arriba; NPCs se colocan por coordenada.

  const TILE = {
    '.': { name: 'grass', solid: false, enc: false },
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
  };
  const isWarp = (ch) => ch >= '0' && ch <= '9';

  /* ------------------------- MAPA: CIUDAD BASE (hub) ------------------------- */
  const laboratorio = {
    id: 'lab', name: 'Ciudad Semilla', biome: null, theme: 'town',
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
      '0': { to: 'pradera', x: 9, y: 1 },   // salida sur -> pradera
      '1': { to: '@lab_interior', name: 'Laboratorio' }, // menú especial
      '2': { to: '@tienda', name: 'Mercado' },
      '3': { to: '@casa', name: 'Tu casa' },
    },
    npcs: [
      { id: 'mentor', x: 9, y: 8, name: 'Dra. Elna', sprite: 'mentor', dialog: 'mentor' },
      { id: 'coleccionista', x: 15, y: 9, name: 'Coleccionista Bru', sprite: 'npc2', dialog: 'coleccionista' },
      { id: 'criador', x: 4, y: 9, name: 'Criador Wex', sprite: 'npc3', dialog: 'criador' },
    ],
    spawn: { x: 9, y: 15 },
  };

  /* ------------------------- MAPA: PRADERA ------------------------- */
  const pradera = {
    id: 'pradera', name: 'Pradera de Auralia', biome: 'pradera', theme: 'meadow',
    grid: [
      'TTTTTTTT00TTTTTTTTTT',
      'T....,,....,,......T',
      'T..,,,,..FF,,,,....T',
      'T..,,,,....,,,,..b.T',
      'T....PP....PP......T',
      'T....P......P......T',
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
    },
    npcs: [
      { id: 'explorador', x: 14, y: 11, name: 'Explorador Ino', sprite: 'npc4', dialog: 'explorador' },
    ],
    spawn: { x: 9, y: 2 },
  };

  /* ------------------------- MAPA: BOSQUE ------------------------- */
  const bosque = {
    id: 'bosque', name: 'Bosque de Vael', biome: 'bosque', theme: 'forest',
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
      '3': { to: '@cueva', name: 'Cueva de Vael' },
    },
    npcs: [
      { id: 'botanica', x: 4, y: 8, name: 'Botánica Sella', sprite: 'npc5', dialog: 'botanica' },
    ],
    spawn: { x: 9, y: 2 },
  };

  /* ------------------------- MAPA: PANTANO ------------------------- */
  const pantano = {
    id: 'pantano', name: 'Cenagal de Mureb', biome: 'pantano', theme: 'swamp',
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
      '4': { to: '@expedicion', name: 'Muelle de expediciones' },
    },
    npcs: [
      { id: 'contrabandista', x: 4, y: 12, name: 'Contrabandista Kez', sprite: 'npc6', dialog: 'contrabandista' },
    ],
    spawn: { x: 3, y: 1 },
  };

  const MAPS = { lab: laboratorio, pradera, bosque, pantano };

  // Envuelve un mapa con métodos de consulta
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

  PH.world = { TILE, MAPS, isWarp, tileAt, solidAt, encounterAt, warpAt, dims };
})(window.PH = window.PH || {});

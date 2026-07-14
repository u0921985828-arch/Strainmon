/* ============================================================
   STRAINMON — isogame.js
   Controlador del sandbox isométrico (híbrido "salas + grow", single-player,
   todo NPC, roam libre). Reemplaza al overworld top-down. Reutiliza
   PH.state / PH.ui / PH.iso / PH.genetics / PH.plantart / PH.garden.
   Arte y diseño originales (sin relación con Habbo/Sulake).
   ============================================================ */
(function (PH) {
  'use strict';
  const { clamp, lerp } = PH.util;
  const ISO = PH.iso;
  const G = () => PH.state.get();

  // Movimiento por ejes de rejilla (cada tecla recorre una arista del rombo).
  // Up=NE(gy-1), Down=SW(gy+1), Left=NW(gx-1), Right=SE(gx+1).
  const DIRV = { NE: [0, -1], SW: [0, 1], NW: [-1, 0], SE: [1, 0] };

  /* ------------------------- SALAS ------------------------- */
  // grid: '.'=suelo  '#'=pared  ' '=vacío(bloqueado)  'D'=puerta(suelo)
  const ROOMS = {
    apt: {
      id: 'apt', name: 'Tu Grow-Room', theme: 'room', wallH: 54, bg: '#1a120e',
      pal: { floorA: '#c8a06a', floorB: '#bd9560', floorEdge: 'rgba(80,50,20,.35)', door: '#8a5a30', wall: { top: '#cfd6ac', left: '#96a074', right: '#b2bb90' } },
      rugPal: { col: '#9a4636', edge: '#6a2f26' },
      grid: [
        '#############',
        '#...........#',
        '#...........#',
        '#...........#',
        '#....mmm....#',
        '#....mmm....#',
        '#...........#',
        '#.....D.....#',
        '#############',
      ],
      spawn: { gx: 6, gy: 6 },
      doors: [{ gx: 6, gy: 7, to: 'street', tgx: 6, tgy: 3 }],
      npcs: [],
      objects: [
        { gx: 2, gy: 1, kind: 'grow', solid: true, label: 'Mesa de cultivo' },
        { gx: 10, gy: 1, kind: 'pc', solid: true, label: 'Ordenador' },
        { gx: 2, gy: 6, kind: 'bed', solid: true, label: 'Cama' },
        { gx: 6, gy: 1, kind: 'closet', solid: true, w: 2, label: 'Armario de Cultivo', to: 'tent', tgx: 4, tgy: 4 },
        { gx: 9, gy: 1, kind: 'plant', solid: true, label: 'Planta' },
        { gx: 10, gy: 5, kind: 'shelf', solid: true, label: 'Estante' },
        { gx: 2, gy: 4, kind: 'crate', solid: true, label: 'Caja' },
      ],
    },
    // ---------------- CARPA INDOOR (instancia del Armario de Cultivo) ----------------
    tent: {
      id: 'tent', name: 'Armario · Carpa Indoor', theme: 'room', wallH: 46, bg: '#0d0c10',
      pal: { floorA: '#3a3630', floorB: '#332f2a', floorEdge: 'rgba(0,0,0,.45)', door: '#8a5a30', wall: { top: '#cbd0d6', left: '#8f949c', right: '#b0b5bd' } },
      grid: [
        '##########',
        '#........#',
        '#........#',
        '#........#',
        '#........#',
        '####D#####',
      ],
      spawn: { gx: 4, gy: 4 },
      doors: [{ gx: 4, gy: 5, to: 'apt', tgx: 6, tgy: 2 }],
      npcs: [],
      leds: [{ gx: 1, gy: 1, w: 4, h: 4 }, { gx: 5, gy: 1, w: 4, h: 4 }],   // 2 focos cenitales, cuadrantes 4×4 exactos
      objects: [
        { gx: 2, gy: 1, kind: 'duct', solid: true, label: 'Tubo de ventilación' },
        { gx: 7, gy: 1, kind: 'duct', solid: true, label: 'Tubo de ventilación' },
        { gx: 5, gy: 1, kind: 'extractor', solid: true, label: 'Extractor de aire' },
        { gx: 2, gy: 2, kind: 'slot', idx: 0, solid: true, label: 'Slot de cultivo' },
        { gx: 3, gy: 2, kind: 'slot', idx: 1, solid: true, label: 'Slot de cultivo' },
        { gx: 6, gy: 2, kind: 'slot', idx: 2, solid: true, label: 'Slot de cultivo' },
        { gx: 7, gy: 2, kind: 'slot', idx: 3, solid: true, label: 'Slot de cultivo' },
      ],
    },
    street: {
      id: 'street', name: 'Calle Verde', theme: 'street',
      grid: [
        '.............',
        '.HH..HH..HH..',
        '.HD..HD..HD..',
        'D............',
        '.....P.......',
        '.gg.........',
        '.gg......gg..',
        '......D......',
      ],
      spawn: { gx: 6, gy: 3 },
      doors: [
        { gx: 2, gy: 2, to: 'apt', tgx: 6, tgy: 6 },
        { gx: 6, gy: 2, to: 'shop', tgx: 5, tgy: 6 },
        { gx: 10, gy: 2, to: 'lab', tgx: 5, tgy: 6 },
        { gx: 6, gy: 7, to: 'park', tgx: 5, tgy: 6 },
        { gx: 0, gy: 3, to: 'wilds', tgx: 9, tgy: 8 },
      ],
      npcs: [
        { gx: 6, gy: 5, name: 'Dealer Kez', sprite: 'npc6', dialog: 'contrabandista', dir: 'SW', role: 'dealer', char: 'dealer' },
        { gx: 3, gy: 4, name: 'Vecina Bru', sprite: 'npc2', dialog: 'coleccionista', dir: 'SE', role: 'neighbor', char: 'neighbor' },
        { gx: 8, gy: 3, name: 'Cliente', sprite: 'npc3', dir: 'SW', role: 'customer', char: 'customer1' },
        { gx: 4, gy: 6, name: 'Cliente', sprite: 'npc4', dir: 'NE', role: 'customer', char: 'customer2' },
        { gx: 11, gy: 5, name: 'Transeúnte', sprite: 'npc5', dir: 'NW', role: 'walker', char: 'walker' },
      ],
      objects: [],
      wild: true, // 'g' = parterres con cepas silvestres
    },
    shop: {
      id: 'shop', name: 'Mercado', theme: 'room', wallH: 50, bg: '#1c140e',
      pal: { floorA: '#cbb083', floorB: '#c0a476', floorEdge: 'rgba(90,60,25,.35)', door: '#8a5a30', wall: { top: '#c79a5e', left: '#8f6a38', right: '#a9803f' } },
      rugPal: { col: '#b0742f', edge: '#7a4c1e' },
      grid: [
        '###########',
        '#.........#',
        '#.........#',
        '#....m....#',
        '#...mmm...#',
        '#....m....#',
        '#.........#',
        '#....D....#',
        '###########',
      ],
      spawn: { gx: 5, gy: 6 },
      doors: [{ gx: 5, gy: 7, to: 'street', tgx: 6, tgy: 3 }],
      npcs: [{ gx: 5, gy: 1, name: 'Mercader', sprite: 'npc4', dialog: 'nomada', dir: 'SW', role: 'merchant', char: 'merchant' }],
      objects: [
        { gx: 3, gy: 1, kind: 'shop', solid: true, label: 'Mostrador' },
        { gx: 7, gy: 1, kind: 'shop', solid: true, label: 'Mostrador' },
        { gx: 2, gy: 4, kind: 'crate', solid: true, label: 'Caja' },
        { gx: 8, gy: 4, kind: 'barrel', solid: true, label: 'Barril' },
        { gx: 2, gy: 6, kind: 'plant', solid: true, label: 'Planta' },
      ],
    },
    lab: {
      id: 'lab', name: 'Laboratorio', theme: 'room', wallH: 52, bg: '#12161a',
      pal: { floorA: '#c4ccd2', floorB: '#b8c1c8', floorEdge: 'rgba(60,80,95,.35)', door: '#7a8a96', wall: { top: '#dbe6ee', left: '#9fb4c2', right: '#c2d0da' } },
      rugPal: { col: '#3f7a6a', edge: '#2c564b' },
      grid: [
        '###########',
        '#.........#',
        '#.........#',
        '#.........#',
        '#...mmm...#',
        '#...mmm...#',
        '#.........#',
        '#....D....#',
        '###########',
      ],
      spawn: { gx: 5, gy: 6 },
      doors: [{ gx: 5, gy: 7, to: 'street', tgx: 10, tgy: 3 }],
      npcs: [{ gx: 3, gy: 1, name: 'Dr. Vane', sprite: 'npc5', dialog: 'genetista', dir: 'SE', role: 'botanist', char: 'botanist' }],
      objects: [
        { gx: 5, gy: 1, kind: 'lab', solid: true, label: 'Mesa de cruces' },
        { gx: 7, gy: 1, kind: 'pc', solid: true, label: 'Terminal ADN' },
        { gx: 2, gy: 5, kind: 'shelf', solid: true, label: 'Estante' },
        { gx: 8, gy: 4, kind: 'plant', solid: true, label: 'Planta' },
        { gx: 2, gy: 2, kind: 'crate', solid: true, label: 'Caja' },
      ],
    },
    park: {
      id: 'park', name: 'Descampado', theme: 'street', natural: true, borderKind: 'fence', bg: '#26241d',
      pal: { floorA: '#9a8f6a', floorB: '#8f8460', floorEdge: 'rgba(45,38,20,.35)', door: '#8a5a30', wall: { top: '#9a8f6a', left: '#6f6748', right: '#82795a' } },
      wildPal: { col: '#5f9e3a', edge: '#3d6b24' },
      grid: [
        '###########',
        '#.........#',
        '#.gg...gg.#',
        '#.gg...gg.#',
        '#.........#',
        '#..gg.gg..#',
        '#..gg.gg..#',
        '#....D....#',
        '###########',
      ],
      spawn: { gx: 5, gy: 6 },
      doors: [{ gx: 5, gy: 7, to: 'street', tgx: 6, tgy: 6 }],
      npcs: [
        { gx: 8, gy: 1, name: 'Rasta Dodo', sprite: 'npc6', dialog: 'descampado', dir: 'SW', role: 'neighbor', char: 'dealer' },
      ],
      objects: [],
      wild: true, // maleza 'g' = cepas silvestres del descampado
    },
    // ---------------- SENDERO SALVAJE (hub de biomas) ----------------
    wilds: {
      id: 'wilds', name: 'Sendero Salvaje', theme: 'grass', natural: true, borderKind: 'hedge', bg: '#2f4a2c',
      pal: { floorA: '#8a7a52', floorB: '#7e6f49', floorEdge: 'rgba(40,30,15,.35)', door: '#caa96b', wall: { top: '#7a8a5a', left: '#54633a', right: '#657548' } },
      grid: [
        '###D##D##D###',
        '#...........#',
        'D...........D',
        '#...........#',
        '#....P......#',
        'D...........D',
        '#...........#',
        '#...........#',
        '#...........#',
        '###D#####D###',
      ],
      spawn: { gx: 9, gy: 8 },
      doors: [
        { gx: 3, gy: 0, to: 'pradera', tgx: 5, tgy: 6 },
        { gx: 6, gy: 0, to: 'bosque', tgx: 5, tgy: 6 },
        { gx: 9, gy: 0, to: 'desierto', tgx: 5, tgy: 6 },
        { gx: 0, gy: 2, to: 'nieve', tgx: 5, tgy: 6 },
        { gx: 12, gy: 2, to: 'volcan', tgx: 5, tgy: 6 },
        { gx: 0, gy: 5, to: 'cueva', tgx: 5, tgy: 6 },
        { gx: 12, gy: 5, to: 'pantano', tgx: 5, tgy: 6 },
        { gx: 3, gy: 9, to: 'isla', tgx: 5, tgy: 6 },
        { gx: 9, gy: 9, to: 'street', tgx: 1, tgy: 3 },
      ],
      npcs: [{ gx: 6, gy: 6, name: 'Guía Fenn', sprite: 'npc2', dialog: 'descampado', dir: 'SW', role: 'neighbor', char: 'neighbor' }],
      objects: [],
    },
    // ---------------- BIOMAS ----------------
    pradera: {
      id: 'pradera', name: 'Pradera', theme: 'grass', biome: 'pradera', wild: true, natural: true, borderKind: 'hedge', encounterRate: 0.28, bg: '#3a5a34',
      pal: { floorA: '#7cbd50', floorB: '#72b048', floorEdge: 'rgba(30,60,20,.3)', door: '#caa96b', wall: { top: '#9ab06a', left: '#6f8347', right: '#82995a' } },
      wildPal: { col: '#4f9e3a', edge: '#356b26' },
      grid: ['###########', '#.........#', '#.g.g.g.g.#', '#.........#', '#.g.g.g.g.#', '#.........#', '#.g.g.g.g.#', '#....D....#', '###########'],
      spawn: { gx: 5, gy: 6 }, doors: [{ gx: 5, gy: 7, to: 'wilds', tgx: 3, tgy: 1 }], npcs: [], objects: [],
    },
    bosque: {
      id: 'bosque', name: 'Bosque', theme: 'grass', biome: 'bosque', wild: true, natural: true, borderKind: 'hedgeDark', propKind: 'tree', encounterRate: 0.28, bg: '#22331d',
      pal: { floorA: '#4f8f45', floorB: '#468038', floorEdge: 'rgba(20,45,15,.35)', door: '#8a5a30', wall: { top: '#5a7a3a', left: '#3c5426', right: '#496630' } },
      wildPal: { col: '#3f7d34', edge: '#2c5a22' },
      grid: ['###########', '#..#....#.#', '#.g.g.g.g.#', '#.........#', '#.g.g#g.g.#', '#.........#', '#.g.g.g.g.#', '#....D....#', '###########'],
      spawn: { gx: 5, gy: 6 }, doors: [{ gx: 5, gy: 7, to: 'wilds', tgx: 6, tgy: 1 }], npcs: [], objects: [],
    },
    desierto: {
      id: 'desierto', name: 'Desierto', theme: 'grass', biome: 'desierto', wild: true, natural: true, borderKind: 'fence', propKind: 'cactus', encounterRate: 0.28, bg: '#7a6238',
      pal: { floorA: '#e0c380', floorB: '#d4b673', floorEdge: 'rgba(120,90,40,.3)', door: '#a9793f', wall: { top: '#d8b673', left: '#a07b3e', right: '#bd914f' } },
      wildPal: { col: '#b7a24a', edge: '#8a7730' },
      grid: ['###########', '#.........#', '#..g...g..#', '#.........#', '#.g..#..g.#', '#.........#', '#..g...g..#', '#....D....#', '###########'],
      spawn: { gx: 5, gy: 6 }, doors: [{ gx: 5, gy: 7, to: 'wilds', tgx: 9, tgy: 1 }], npcs: [], objects: [],
    },
    nieve: {
      id: 'nieve', name: 'Nieve', theme: 'grass', biome: 'nieve', wild: true, natural: true, borderKind: 'snow', propKind: 'snow', encounterRate: 0.28, bg: '#8aa0b0',
      pal: { floorA: '#e8eef2', floorB: '#dbe6ee', floorEdge: 'rgba(120,140,160,.3)', door: '#a9b6c0', wall: { top: '#cfe0ea', left: '#9fb4c2', right: '#b8ccd8' } },
      wildPal: { col: '#b8d0c4', edge: '#8aa89a' },
      grid: ['###########', '#.........#', '#.g.g.g.g.#', '#....#....#', '#.g.g.g.g.#', '#....#....#', '#.g.g.g.g.#', '#....D....#', '###########'],
      spawn: { gx: 5, gy: 6 }, doors: [{ gx: 5, gy: 7, to: 'wilds', tgx: 1, tgy: 2 }], npcs: [], objects: [],
    },
    volcan: {
      id: 'volcan', name: 'Volcán', theme: 'grass', biome: 'volcan', wild: true, natural: true, borderKind: 'rockDark', propKind: 'rockDark', encounterRate: 0.28, bg: '#241614',
      pal: { floorA: '#4a3a3a', floorB: '#3f3232', floorEdge: 'rgba(0,0,0,.45)', door: '#7a4a30', wall: { top: '#5a3a34', left: '#2e1e1c', right: '#42302c' } },
      wildPal: { col: '#c56a3a', edge: '#8a3f22' }, lavaPal: { col: '#d5713f', edge: '#8a3f22' },
      grid: ['###########', '#.g.l.g...#', '#....l....#', '#.lg...gl.#', '#.........#', '#.gl..g.l.#', '#..l.....g#', '#....D....#', '###########'],
      spawn: { gx: 5, gy: 6 }, doors: [{ gx: 5, gy: 7, to: 'wilds', tgx: 11, tgy: 2 }], npcs: [], objects: [],
    },
    cueva: {
      id: 'cueva', name: 'Cueva', theme: 'grass', biome: 'cueva', wild: true, natural: true, borderKind: 'rock', propKind: 'rock', encounterRate: 0.28, bg: '#1a1620',
      pal: { floorA: '#6a6470', floorB: '#5c5766', floorEdge: 'rgba(0,0,0,.45)', door: '#7a6a55', wall: { top: '#8b8492', left: '#57525f', right: '#6b6675' } },
      wildPal: { col: '#9a94a2', edge: '#6a6472' },
      grid: ['###########', '#.#.....#.#', '#.g.g.g.g.#', '#..#...#..#', '#.g.g.g.g.#', '#..#...#..#', '#.g.g.g.g.#', '#....D....#', '###########'],
      spawn: { gx: 5, gy: 6 }, doors: [{ gx: 5, gy: 7, to: 'wilds', tgx: 1, tgy: 5 }], npcs: [], objects: [],
    },
    pantano: {
      id: 'pantano', name: 'Pantano', theme: 'grass', biome: 'pantano', wild: true, natural: true, borderKind: 'reed', encounterRate: 0.28, bg: '#232a20',
      pal: { floorA: '#6b7a45', floorB: '#5f6d3c', floorEdge: 'rgba(30,35,15,.4)', door: '#6a5a30', wall: { top: '#4a4636', left: '#332f22', right: '#3f3a2b' } },
      wildPal: { col: '#7a8a3a', edge: '#556123' }, waterPal: { col: '#3f5a52', edge: '#2c4038' },
      grid: ['###########', '#.g.w.g...#', '#....w....#', '#.wg...gw.#', '#.........#', '#.gw..g.w.#', '#..w.....g#', '#....D....#', '###########'],
      spawn: { gx: 5, gy: 6 }, doors: [{ gx: 5, gy: 7, to: 'wilds', tgx: 11, tgy: 5 }], npcs: [], objects: [],
    },
    isla: {
      id: 'isla', name: 'Isla', theme: 'grass', biome: 'isla', wild: true, natural: true, borderKind: 'palm', encounterRate: 0.28, bg: '#2f5a6a',
      pal: { floorA: '#86c46a', floorB: '#7ab85e', floorEdge: 'rgba(30,60,20,.3)', door: '#caa96b', wall: { top: '#5a8a4a', left: '#3c5e30', right: '#4a7440' } },
      wildPal: { col: '#4faf6a', edge: '#357b4a' }, waterPal: { col: '#5aa6c0', edge: '#3f8aa4' },
      grid: ['###########', '#ww.....ww#', '#.g.g.g.g.#', '#.........#', '#.g.g.g.g.#', '#.........#', '#wwg...gww#', '#....D....#', '###########'],
      spawn: { gx: 5, gy: 6 }, doors: [{ gx: 5, gy: 7, to: 'wilds', tgx: 3, tgy: 8 }], npcs: [], objects: [],
    },
  };
  // Lista BLANCA de tiles caminables. Todo lo demás bloquea (paredes '#',
  // vacío ' ', fachadas 'H', farolas 'P', dígitos, o cualquier char extraño).
  const WALKABLE = { '.': 1, 'D': 1, 'g': 1, 'm': 1 };   // 'm' = alfombra/estera (decorativa, caminable)
  function walkableChar(ch) { return !!WALKABLE[ch]; }

  function room(id) { return ROOMS[id]; }
  function tileAt(m, gx, gy) {
    if (gy < 0 || gy >= m.grid.length) return '#';
    const r = m.grid[gy]; if (gx < 0 || gx >= r.length) return '#';
    return r[gx];
  }
  // Objeto en (gx,gy): soporta huella multi-baldosa (o.w × o.h, por defecto 1×1),
  // anclado a la rejilla. Su hitbox ocupa el 100% de cada baldosa cubierta.
  function objAt(m, gx, gy) { return (m.objects || []).find(o => gx >= o.gx && gx < o.gx + (o.w || 1) && gy >= o.gy && gy < o.gy + (o.h || 1)); }
  function doorAt(m, gx, gy) { return (m.doors || []).find(d => d.gx === gx && d.gy === gy); }
  function npcAt(m, gx, gy) { return (m.npcs || []).find(n => n.gx === gx && n.gy === gy && !n._inactive); }
  // Horario de cada rol (Fase 4): la ciudad cobra vida según la hora.
  function hourNow() { return G().env.time / 60; }
  function npcActive(n) {
    const h = hourNow();
    switch (n.role) {
      case 'dealer': return h >= 18 || h < 4;      // el camello trapichea de noche
      case 'walker': return h >= 7 && h < 21;
      case 'customer': return h >= 9 && h < 23;
      case 'merchant': return h >= 8 && h < 20;
      case 'botanist': return h >= 8 && h < 22;
      case 'neighbor': return true;                 // la vecina siempre ronda
      default: return true;
    }
  }
  // Bloqueado si el tile no es caminable, o hay objeto sólido, o hay un NPC.
  // (ignoreNpc: al comprobar puertas no cuenta el NPC de destino.)
  function solidAt(m, gx, gy, ignoreNpc) {
    if (!walkableChar(tileAt(m, gx, gy))) return true;
    const o = objAt(m, gx, gy); if (o && o.solid !== false) return true;
    if (!ignoreNpc && npcAt(m, gx, gy)) return true;
    return false;
  }
  // Auditoría: colocaciones inválidas de NPCs/objetos (para QA).
  function audit() {
    const problems = [];
    for (const id of Object.keys(ROOMS)) {
      const m = ROOMS[id];
      for (const n of (m.npcs || [])) {
        if (!walkableChar(tileAt(m, n.gx, n.gy))) problems.push(`${id}: NPC ${n.name} en tile no caminable (${n.gx},${n.gy})`);
        if (objAt(m, n.gx, n.gy)) problems.push(`${id}: NPC ${n.name} solapa objeto (${n.gx},${n.gy})`);
        if (doorAt(m, n.gx, n.gy)) problems.push(`${id}: NPC ${n.name} sobre puerta (${n.gx},${n.gy})`);
      }
      for (const o of (m.objects || [])) {
        if (!walkableChar(tileAt(m, o.gx, o.gy))) problems.push(`${id}: objeto ${o.label} en tile no caminable (${o.gx},${o.gy})`);
      }
      for (const d of (m.doors || [])) {
        if (tileAt(m, d.gx, d.gy) !== 'D') problems.push(`${id}: puerta->${d.to} no está sobre 'D' (${d.gx},${d.gy})`);
        const t = ROOMS[d.to]; if (!t) { problems.push(`${id}: puerta a sala inexistente '${d.to}'`); continue; }
        if (solidAt(t, d.tgx, d.tgy, true)) problems.push(`${id}: destino de puerta a ${d.to} es sólido (${d.tgx},${d.tgy})`);
      }
      // spawn caminable
      if (solidAt(m, m.spawn.gx, m.spawn.gy, true)) problems.push(`${id}: spawn sólido (${m.spawn.gx},${m.spawn.gy})`);
    }
    return problems;
  }

  /* ------------------------- ESTADO ------------------------- */
  const game = {
    mode: 'boot', canvas: null, ctx: null, scale: 3,
    W: 480, H: 320,                 // resolución interna del canon (×2 GBA, 15×10 tiles)
    dmg: false, _dmg: null,          // modo DMG (4 tonos, 160x144)
    moving: false, from: null, to: null, moveT: 0, moveDur: 170, frame: 0, animT: 0,
    keys: {}, tapLatch: null, lastSave: 0, cam: { x: 0, y: 0 }, cop: null, contrast: 1,
  };
  // Mapa tecla->dirección (para taps rápidos: un toque = un paso, como en GB).
  const KEYDIR = { arrowup: 'NE', w: 'NE', arrowdown: 'SW', s: 'SW', arrowleft: 'NW', a: 'NW', arrowright: 'SE', d: 'SE' };
  PH.game = game;

  function init() {
    game.canvas = document.getElementById('screen');
    game.ctx = game.canvas.getContext('2d');
    if (PH.sprites) PH.sprites.preload();
    if (PH.plantart) PH.plantart.preload();
    if (PH.strainart) PH.strainart.preload();
    if (PH.budart) PH.budart.preload();
    if (PH.charart) PH.charart.preload();
    if (PH.faceart) PH.faceart.preload();
    if (PH.furniart) PH.furniart.preload();
    PH.ui.init();
    bindInput();
    resize();
    window.addEventListener('resize', resize);
    applyContrast();
    powerScreen();
    requestAnimationFrame(loop);
  }

  /* ------------------------- ENCENDIDO / BOOT ------------------------- */
  // Ritual de "power on" original: botón de encender -> desbloquea el audio,
  // reproduce la melodía de arranque y anima el logo antes del título.
  function powerScreen() {
    game.mode = 'boot';
    const ov = document.getElementById('overlay');
    ov.className = 'active boot';
    ov.innerHTML = `
      <div class="boot-screen">
        <button id="pwr" class="pwr-btn" aria-label="Encender"><i class="pic pic-power"></i></button>
        <div class="pwr-label">ENCENDER</div>
      </div>`;
    document.getElementById('pwr').onclick = () => { if (PH.audio) PH.audio.ensure(); bootSequence(); };
  }
  function bootSequence() {
    game.mode = 'boot';
    const ov = document.getElementById('overlay');
    ov.className = 'active boot on';
    ov.innerHTML = `<div class="boot-screen"><div class="boot-logo">STRAIN<span>BOY</span></div><div class="boot-tm">© STRAINMON</div></div>`;
    if (PH.audio) PH.audio.bootChime();
    setTimeout(titleScreen, 1500);
  }

  function resize() {
    // El lienzo sigue la PROPORCIÓN real del escenario (llena la pantalla, sin
    // franjas negras). Presupuesto horizontal fijo (~cabe la sala más ancha);
    // el alto lo marca la pantalla. Píxeles nítidos (object-fit: cover).
    const st = game.canvas.parentElement || document.getElementById('stage');
    const r = st.getBoundingClientRect();
    const w = Math.max(1, r.width), h = Math.max(1, r.height);
    game.W = 640;
    game.H = Math.round(game.W * h / w);
    game.canvas.width = game.W; game.canvas.height = game.H;
    game.canvas.style.width = '100%'; game.canvas.style.height = '100%';
    game.ctx.imageSmoothingEnabled = false;
    game._dmg = null;   // se recrea con la proporción nueva en applyDMG
  }

  /* ------------------------- TÍTULO ------------------------- */
  function titleScreen() {
    game.mode = 'title';
    const ov = document.getElementById('overlay');
    ov.className = 'active title';
    const cont = PH.state.hasSave() ? '<button class="btn primary big" id="t_continue">Continuar</button>' : '';
    ov.innerHTML = `
      <div class="title-screen">
        <div class="logo">STRAIN<span>MON</span></div>
        <div class="tagline">Sandbox isométrico · cultiva · trapichea · colecciona</div>
        <div class="title-btns">${cont}
          <button class="btn ${cont ? 'ghost' : 'primary'} big" id="t_new">Nueva partida</button></div>
        <div class="title-help">Mover: WASD / Flechas (diagonales) · Interactuar: Espacio o E<br>
          I Mochila · B Banco · C Strain-dex · L Lab · G Invernadero · Q Misiones · M Guardar</div>
      </div>`;
    if (cont) document.getElementById('t_continue').onclick = () => { PH.state.load(); startGame(false); };
    document.getElementById('t_new').onclick = () => { PH.state.reset(); startGame(true); };
  }

  function normalizePlayer() {
    const p = G().player;
    if (!ROOMS[p.map]) { p.map = 'apt'; const sp = ROOMS.apt.spawn; p.x = sp.gx; p.y = sp.gy; }
    if (!p.dir || !DIRV[p.dir]) p.dir = 'SW';
  }
  function startGame(fresh) {
    PH.ui.close();
    const p = G().player;
    // Partida nueva -> siempre en el apartamento. Continuar -> respeta sala iso guardada.
    if (fresh || !ROOMS[p.map] || !p.iso) { p.map = 'apt'; p.x = ROOMS.apt.spawn.gx; p.y = ROOMS.apt.spawn.gy; p.dir = 'SW'; }
    p.iso = true;
    game.dmg = !!p.dmg;
    if (p.contrast != null) { game.contrast = p.contrast; applyContrast(); }
    if (PH.audio) PH.audio.musicStart();
    normalizePlayer();
    game.mode = 'overworld';
    centerCam(true);
    PH.ui.updateHUD();
    PH.ui.toast('Bienvenido a tu grow-room. Sal por la puerta (abajo).', 'ok');
  }

  /* ------------------------- ENTRADA ------------------------- */
  const MOVE_KEYS = { arrowup: 1, arrowdown: 1, arrowleft: 1, arrowright: 1, w: 1, a: 1, s: 1, d: 1 };
  // Acción de un botón/tecla (A=espacio/confirmar, B=escape/volver, atajos de panel).
  const A = (k) => { if (PH.audio) PH.audio.sfx(k); };
  function doAction(k) {
    if (k === 'n') { const m = PH.audio && PH.audio.toggleMute(); PH.ui.toast(m ? '🔇 Silencio' : '🔊 Sonido', ''); return; }
    if (game.mode === 'title') return;
    if (game.mode === 'dialog') { if (k === ' ' || k === 'e' || k === 'enter') { A('confirm'); PH.ui.dialogNext(); } return; }
    if (game.mode === 'menu') { if (k === 'escape' || k === 'b' || k === 'i' || k === 'c' || k === 'q' || k === 'g' || k === 'l') { A('cancel'); PH.ui.close(); } return; }
    if (game.mode !== 'overworld') return;
    if (k === ' ' || k === 'e') interact();
    else if (k === 'i') { A('open'); PH.ui.bag(); } else if (k === 'b') { A('open'); PH.ui.bank(); }
    else if (k === 'c') { A('open'); PH.ui.catalog(); } else if (k === 'q' || k === 'start' || k === 'enter') { A('open'); PH.ui.quests(); }
    else if (k === 'l') { A('open'); PH.ui.lab(); } else if (k === 'g') { A('open'); PH.ui.greenhouse(); }
    else if (k === 'select' || k === 'p') { A('blip'); toggleDMG(); }
    else if (k === 'm') { A('confirm'); PH.state.save(); PH.ui.toast('Partida guardada.', 'ok'); }
  }
  function toggleDMG() {
    game.dmg = !game.dmg;
    G().player.dmg = game.dmg;
    PH.state.save();
    PH.ui.toast(game.dmg ? '🟩 Modo DMG (4 tonos)' : '🌈 Modo color', '');
  }

  // Rueda de CONTRASTE (como el potenciómetro físico de la Game Boy): ajusta
  // el filtro de la LCD por niveles y gira el mando para dar realimentación.
  const CONTRAST_LEVELS = [
    { f: 'contrast(.9) brightness(.96) saturate(.95)', deg: -60 },
    { f: 'none', deg: -20 },
    { f: 'contrast(1.15) brightness(1.04) saturate(1.05)', deg: 20 },
    { f: 'contrast(1.32) brightness(1.1) saturate(1.1)', deg: 60 },
  ];
  function applyContrast() {
    const lv = CONTRAST_LEVELS[game.contrast] || CONTRAST_LEVELS[1];
    const sc = document.getElementById('screen'); if (sc) sc.style.filter = lv.f;
    const kn = document.querySelector('[data-contrast] i'); if (kn) kn.style.transform = `rotate(${lv.deg}deg)`;
  }
  function cycleContrast() {
    game.contrast = (game.contrast + 1) % CONTRAST_LEVELS.length;
    G().player.contrast = game.contrast;
    applyContrast();
    if (PH.audio) PH.audio.sfx('blip');
    PH.ui.toast('🔆 Contraste ' + (game.contrast + 1) + '/' + CONTRAST_LEVELS.length, '');
    PH.state.save();
  }
  function bindInput() {
    window.addEventListener('keydown', (e) => {
      const k = e.key.toLowerCase(); game.keys[k] = true;
      if (MOVE_KEYS[k]) game.tapLatch = k;         // registra el toque para taps ultrarrápidos
      if (PH.audio) PH.audio.ensure();
      if (MOVE_KEYS[k] || k === ' ') e.preventDefault();
      if (!MOVE_KEYS[k]) doAction(k);
    });
    window.addEventListener('keyup', (e) => { game.keys[e.key.toLowerCase()] = false; });
    document.querySelectorAll('[data-key]').forEach(btn => {
      const key = btn.dataset.key;
      const down = (e) => { e.preventDefault(); if (PH.audio) PH.audio.ensure(); if (MOVE_KEYS[key]) { game.keys[key] = true; game.tapLatch = key; } else doAction(key); };
      const up = (e) => { if (e) e.preventDefault(); if (MOVE_KEYS[key]) game.keys[key] = false; };
      btn.addEventListener('touchstart', down, { passive: false }); btn.addEventListener('touchend', up, { passive: false });
      btn.addEventListener('mousedown', down); btn.addEventListener('mouseup', up); btn.addEventListener('mouseleave', up);
    });
    // rueda de VOLUMEN = silencio
    const kn = document.querySelector('[data-mute]');
    if (kn) kn.addEventListener('click', () => { const m = PH.audio && PH.audio.toggleMute(); PH.ui.toast(m ? '🔇 Silencio' : '🔊 Sonido', ''); });
    // rueda de CONTRASTE = ajuste de LCD por niveles
    const ck = document.querySelector('[data-contrast]');
    if (ck) ck.addEventListener('click', cycleContrast);
  }

  /* ------------------------- INTERACCIÓN ------------------------- */
  function facing() {
    const p = G().player, d = DIRV[p.dir] || [1, 1];
    return { gx: p.x + d[0], gy: p.y + d[1] };
  }
  function interact() {
    const p = G().player, m = room(p.map); if (!m) return;
    const f = facing();
    if (npcAt(m, f.gx, f.gy) || objAt(m, f.gx, f.gy) || doorAt(m, f.gx, f.gy)) A('confirm');
    const npc = npcAt(m, f.gx, f.gy);
    if (npc) {
      npc.dir = { NE: 'SW', SW: 'NE', NW: 'SE', SE: 'NW' }[p.dir] || 'SW';
      if (npc.role === 'customer') return dealWith(npc);
      if (npc.role === 'walker') return PH.ui.dialog(['...cruza la calle sin mirarte.'], null, { sprite: npc.sprite, name: npc.name, char: npc.char });
      const pages = PH.quests.DIALOGS[npc.dialog] ? PH.quests.DIALOGS[npc.dialog](G()) : ['...'];
      PH.ui.dialog(pages, null, { sprite: npc.sprite, name: npc.name, char: npc.char });
      return;
    }
    const o = objAt(m, f.gx, f.gy);
    if (o) return useObject(o);
  }
  function useObject(o) {
    if (o.kind === 'grow') return PH.ui.greenhouse();
    if (o.kind === 'lab') return PH.ui.lab();
    if (o.kind === 'shop') return PH.ui.shop();
    if (o.kind === 'pc') return pcMenu();
    if (o.kind === 'bed') { PH.state.save(); return PH.ui.toast('Descansas y guardas la partida.', 'ok'); }
    if (o.kind === 'closet') { A('warp'); return warp({ to: o.to, tgx: o.tgx, tgy: o.tgy }); }   // Armario -> Carpa Indoor
    if (o.kind === 'slot') return PH.ui.tentSlot(o.idx);
    if (o.kind === 'extractor') return PH.ui.toast('Extractor de aire activo: renueva el aire y controla la humedad.', '');
    if (o.kind === 'duct') return PH.ui.toast('Tubo de ventilación: canaliza el flujo de aire de la carpa.', '');
    if (o.kind === 'bench') return PH.ui.toast('Un banco. Nadie se sienta aquí.', '');
    if (o.label) return PH.ui.toast(o.label + '.', '');   // atrezzo etiquetado (papelera, jardinera, farola…)
  }
  // Estado persistente de cada slot del Armario de Cultivo.
  game.tentSlot = function (idx) { const s = G(); if (!s.tent) s.tent = {}; return (s.tent[idx] = s.tent[idx] || { hasPot: false, spec: null, grow: 0 }); };
  function pcMenu() {
    PH.ui.dialog(['Terminal: accede a tu Banco (B), Strain-dex (C) o Misiones (Q).'], null, null);
  }

  // Trato callejero: el cliente compra una cepa de tu banco (premium sobre el
  // mercado). Base de la economía "dealer" (heat/reputación en fase futura).
  function dealWith(npc) {
    const s = G();
    const stock = s.bank.filter(x => x.form !== 'polen');
    if (!stock.length) {
      return PH.ui.dialog(['Cliente: ¿No llevas género? Vuelve cuando tengas algo bueno.'], null, { sprite: npc.sprite, name: npc.name, char: npc.char });
    }
    // pide la más valiosa que lleves
    const want = stock.slice().sort((a, b) => b.rarity - a.rarity)[0];
    const price = Math.round((30 + want.rarity * want.rarity * 1.1 + want.quality * 1.8) * 1.35); // premium callejero
    PH.ui.open(`
      <div class="panel">
        <div class="panel-head"><h2><i class="pic pic-coin"></i> Trato callejero</h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body center-col">
          <p><b>${npc.name}:</b> te compro tu <b>${want.nickname || want.name}</b> (${want.speciesId}) por <b><i class="pic pic-coin sm"></i> ${price}</b>.</p>
          <div style="width:120px">${PH.ui.specimenCard(want)}</div>
          <div class="row">
            <button class="btn primary" id="d_yes">Vender <i class="pic pic-coin sm"></i>${price}</button>
            <button class="btn ghost" id="d_no">Paso</button>
          </div>
        </div>
      </div>`, 'center');
    PH.ui.paintPlant('pc_' + want.uid, want, 2);
    document.getElementById('p_close').onclick = PH.ui.close;
    document.getElementById('d_no').onclick = PH.ui.close;
    document.getElementById('d_yes').onclick = () => {
      PH.state.bankRemove(want.uid); PH.state.addCredits(price);
      s.stats.deals = (s.stats.deals || 0) + 1; if (PH.audio) PH.audio.sfx('cash');
      // trapicheo en la calle -> sube el nivel de búsqueda (más si es de día)
      if (PH.heat) PH.heat.add(G().env.night ? 12 : 20);
      PH.ui.toast(`Vendido a ${npc.name}: 💰${price}`, 'ok');
      PH.ui.updateHUD(); PH.game.afterQuestCheck(); PH.ui.close();
    };
  }

  /* ------------------------- MOVIMIENTO ------------------------- */
  function tryMove() {
    if (game.moving || game.mode !== 'overworld') { return; }
    const p = G().player; let dir = null;
    if (game.keys['arrowup'] || game.keys['w']) dir = 'NE';
    else if (game.keys['arrowdown'] || game.keys['s']) dir = 'SW';
    else if (game.keys['arrowleft'] || game.keys['a']) dir = 'NW';
    else if (game.keys['arrowright'] || game.keys['d']) dir = 'SE';
    // tap rápido: si ninguna tecla sigue pulsada, usa el latch (un toque = un paso)
    if (!dir && game.tapLatch) dir = KEYDIR[game.tapLatch] || null;
    game.tapLatch = null;
    if (!dir) return;
    p.dir = dir;
    const m = room(p.map), d = DIRV[dir];
    const nx = p.x + d[0], ny = p.y + d[1];
    const door = doorAt(m, nx, ny);
    if (door) { warp(door); return; }
    if (solidAt(m, nx, ny)) return;
    game.moving = true; game.moveT = 0; game.from = { x: p.x, y: p.y }; game.to = { x: nx, y: ny };
  }
  function finishMove() {
    const p = G().player; p.x = game.to.x; p.y = game.to.y; game.moving = false;
    G().stats.distance++;
    A('step');
    // parterres silvestres 'g' -> posible encuentro
    const m = room(p.map);
    if (m.wild && tileAt(m, p.x, p.y) === 'g') {
      // en un bioma, sólo aparecen las cepas de su linaje; en parterres urbanos, mezcla
      const biome = m.biome || PH.util.RNG.pick(['pradera', 'bosque', 'pantano', 'desierto', 'nieve', 'volcan', 'cueva', 'isla']);
      const B = PH.species.BIOMES[biome];
      const rate = (B && B.baseEncounter) || m.encounterRate || 0.22;   // prob. por paso en hierba alta
      if (PH.util.RNG.chance(rate)) {
        A('encounter');
        PH.ui.encounter(PH.species.rollEncounter(biome, G().env), biome);
      }
    }
  }
  function warp(d) {
    const p = G().player; const t = room(d.to); if (!t) return;
    A('warp');
    const hadCop = !!game.cop;
    p.map = d.to; p.x = d.tgx; p.y = d.tgy; game.moving = false;
    if (hadCop && t.id !== 'street') { game.cop = null; PH.ui.toast('🚪 Despistaste a la patrulla.', 'ok'); }
    centerCam(true); PH.ui.updateHUD(); PH.ui.toast('📍 ' + t.name, '');
  }

  /* ------------------------- IA DE NPCs ------------------------- */
  // Estados: 'idle' | 'walk'. Deambulan por tiles caminables respetando
  // colisión (paredes, objetos, jugador y otros NPCs). Los 'dealer'/'neighbor'
  // se quedan cerca de su sitio; 'customer'/'walker' pasean más.
  const NPC_STEP = 240;
  function npcSolid(m, gx, gy, self) {
    if (solidAt(m, gx, gy, true)) return true;              // pared/objeto/fuera
    const p = G().player; if (p.x === gx && p.y === gy) return true; // jugador
    for (const n of m.npcs) if (n !== self && n.gx === gx && n.gy === gy) return true; // otros NPCs
    return false;
  }
  function updateNPCs(dt) {
    const m = room(G().player.map); if (!m) return;
    for (const n of m.npcs) {
      // horario: fuera de su ventana, el NPC "se retira" (no colisiona ni se dibuja)
      const on = npcActive(n);
      if (!on) { n._inactive = true; n._mv = false; continue; }
      n._inactive = false;
      if (n._talk) continue;                                 // pausado al hablar
      if (n._mv) {
        n._t += dt;
        if (n._t >= NPC_STEP) { n.gx = n._tx; n.gy = n._ty; n._mv = false; n._wait = PH.util.RNG.i(500, 2600); }
        continue;
      }
      n._wait = (n._wait == null) ? PH.util.RNG.i(300, 1800) : n._wait - dt;
      if (n._wait > 0) continue;
      // homebound: dealer/neighbor no se alejan de su origen
      if (n._hx == null) { n._hx = n.gx; n._hy = n.gy; }
      const roam = (n.role === 'customer' || n.role === 'walker') ? 6 : 2;
      const dirs = PH.util.RNG.shuffle([['NE', 0, -1], ['SW', 0, 1], ['NW', -1, 0], ['SE', 1, 0]]);
      let moved = false;
      for (const d of dirs) {
        const nx = n.gx + d[1], ny = n.gy + d[2];
        if (Math.abs(nx - n._hx) + Math.abs(ny - n._hy) > roam) continue;
        if (npcSolid(m, nx, ny, n)) continue;
        n.dir = d[0]; n._tx = nx; n._ty = ny; n._fx = n.gx; n._fy = n.gy; n._mv = true; n._t = 0; moved = true; break;
      }
      if (!moved) n._wait = PH.util.RNG.i(600, 2000);        // atrapado -> espera
    }
  }
  function npcRender(n) {
    let gx = n.gx, gy = n.gy, frame = 0;
    if (n._mv) { const t = clamp(n._t / NPC_STEP, 0, 1); gx = lerp(n._fx, n._tx, t); gy = lerp(n._fy, n._ty, t); frame = (Math.floor(n._t / (NPC_STEP / 2)) % 2 === 0 ? 1 : 2); }
    return { gx, gy, dir: n.dir || 'SW', frame, pal: PH.render.NPC_PALETTES[n.sprite], char: n.char };
  }

  /* ------------------------- POLICÍA / HEAT (Fase 4) ------------------------- */
  // Con nivel de búsqueda alto aparece una patrulla en la calle que te
  // persigue. Si te alcanza: multa + confiscación. Métete en un interior
  // para despistarla (no entra a las salas). Paleta azul, sprite reutilizado.
  const COP_STEP = 210, COP_PAL = { skin: '#e8c49a', hair: '#1a2740', shirt: '#26407a', pants: '#182238' };
  function copRender(c) {
    let gx = c.gx, gy = c.gy, frame = 0;
    if (c._mv) { const t = clamp(c._t / COP_STEP, 0, 1); gx = lerp(c._fx, c._tx, t); gy = lerp(c._fy, c._ty, t); frame = (Math.floor(c._t / (COP_STEP / 2)) % 2 === 0 ? 1 : 2); }
    return { gx, gy, dir: c.dir || 'SW', frame, pal: COP_PAL, char: 'walker' };
  }
  function copSpawnPoint(m) {
    // aparece por un borde caminable de la calle, lejos del jugador
    const p = G().player, cand = [];
    for (let gy = 0; gy < m.grid.length; gy++) for (let gx = 0; gx < m.grid[gy].length; gx++) {
      if (!walkableChar(tileAt(m, gx, gy))) continue;
      if (doorAt(m, gx, gy)) continue;
      const d = Math.abs(gx - p.x) + Math.abs(gy - p.y);
      if (d >= 5) cand.push({ gx, gy, d });
    }
    if (!cand.length) return null;
    cand.sort((a, b) => b.d - a.d);
    return cand[Math.min(cand.length - 1, PH.util.RNG.i(0, Math.min(3, cand.length - 1)))];
  }
  function copBlocked(m, gx, gy) {
    if (!walkableChar(tileAt(m, gx, gy))) return true;
    const o = objAt(m, gx, gy); if (o && o.solid !== false) return true;
    for (const n of m.npcs) if (!n._inactive && n.gx === gx && n.gy === gy) return true;
    return false;
  }
  function updateCop(dt) {
    const p = G().player, m = room(p.map);
    const active = PH.heat && PH.heat.copsActive() && m && m.id === 'street';
    if (!active) {
      // sin heat o fuera de la calle -> la patrulla se marcha (despiste)
      if (game.cop) { if (game.cop.map !== p.map && PH.heat && PH.heat.heat() > 0) { /* despistado */ }
        game.cop = null; }
      return;
    }
    if (!game.cop || game.cop.map !== 'street') {
      const sp = copSpawnPoint(m); if (!sp) return;
      game.cop = { map: 'street', gx: sp.gx, gy: sp.gy, dir: 'SW', _mv: false, _wait: 300 };
      PH.ui.toast('🚔 ¡Patrulla en la calle! Piérdete en un interior.', 'bad');
      if (PH.audio) PH.audio.sfx('encounter');
    }
    const c = game.cop;
    // ¿alcanzado? adyacencia manhattan 1 (o misma casilla)
    const md = Math.abs(c.gx - p.x) + Math.abs(c.gy - p.y);
    if (!c._mv && md <= 1) { bust(); return; }
    if (c._mv) {
      c._t += dt;
      if (c._t >= COP_STEP) { c.gx = c._tx; c.gy = c._ty; c._mv = false; c._wait = 40; }
      return;
    }
    c._wait = (c._wait == null ? 0 : c._wait - dt);
    if (c._wait > 0) return;
    // persecución voraz: elige el eje que más acerca al jugador
    const opts = [];
    if (p.x !== c.gx) opts.push(p.x > c.gx ? ['SE', 1, 0] : ['NW', -1, 0]);
    if (p.y !== c.gy) opts.push(p.y > c.gy ? ['SW', 0, 1] : ['NE', 0, -1]);
    // prioriza el eje de mayor distancia
    opts.sort((a, b) => Math.abs((a[1] ? p.x - c.gx : p.y - c.gy)) < Math.abs((b[1] ? p.x - c.gx : p.y - c.gy)) ? 1 : -1);
    for (const d of opts) {
      const nx = c.gx + d[1], ny = c.gy + d[2];
      if (nx === p.x && ny === p.y) { bust(); return; }
      if (copBlocked(m, nx, ny)) continue;
      c.dir = d[0]; c._fx = c.gx; c._fy = c.gy; c._tx = nx; c._ty = ny; c._mv = true; c._t = 0; return;
    }
    c._wait = 160; // bloqueado: espera un pelín
  }
  function bust() {
    const s = G(), c = game.cop; game.cop = null;
    if (PH.audio) PH.audio.sfx('error');
    // multa proporcional + confiscación de la muestra menos valiosa
    const fine = Math.min(s.player.credits, Math.max(40, Math.round(s.player.credits * 0.3)));
    PH.state.addCredits(-fine);
    let seized = null;
    const stock = s.bank.filter(x => x.form !== 'polen');
    if (stock.length) {
      seized = stock.slice().sort((a, b) => a.rarity - b.rarity)[0];
      PH.state.bankRemove(seized.uid);
    }
    s.player.busts = (s.player.busts || 0) + 1;
    if (PH.heat) PH.heat.set(18); // te sueltan con un aviso; el heat baja
    const msg = seized ? `🚨 ¡Te pillaron! Multa 💰${fine} y confiscan ${seized.nickname || seized.name}.`
      : `🚨 ¡Te pillaron! Multa 💰${fine}.`;
    PH.ui.toast(msg, 'bad');
    PH.ui.updateHUD();
  }

  game.roomName = function () { const m = room(G().player.map); return m ? m.name : ''; };
  game.audit = audit;
  game.canWalk = function (mapId, gx, gy) { const m = room(mapId); return m ? !solidAt(m, gx, gy) : false; };
  game.ROOMS = ROOMS;
  game.afterQuestCheck = function () {
    const done = PH.quests.checkAll();
    for (const q of done) PH.ui.toast('✅ Misión completada: ' + q.name, 'ok');
    PH.ui.updateHUD();
  };

  /* ------------------------- CÁMARA ------------------------- */
  function playerScreen() {
    const p = G().player; let gx = p.x, gy = p.y;
    if (game.moving) { const t = clamp(game.moveT / game.moveDur, 0, 1); gx = lerp(game.from.x, game.to.x, t); gy = lerp(game.from.y, game.to.y, t); }
    return ISO.project(gx, gy, { x: 0, y: 0 });
  }
  function centerCam(snap) {
    // Todas las salas caben en pantalla: centramos la SALA (estable y centrada)
    // en vez de seguir al jugador, que dejaba huecos negros descentrados.
    const m = room(G().player.map);
    let tx, ty;
    if (m && m.grid) {
      const W = m.grid[0].length, H = m.grid.length;
      const c = ISO.project((W - 1) / 2, (H - 1) / 2, { x: 0, y: 0 });
      tx = game.W / 2 - c.x;
      // -TH/2 baja al centro del rombo; +6 compensa el alto de props/paredes arriba
      ty = game.H / 2 - c.y - ISO.TH / 2 + 6;
    } else {
      const ps = playerScreen();
      tx = game.W / 2 - ps.x; ty = game.H / 2 - ps.y - 20;
    }
    if (snap) { game.cam.x = tx; game.cam.y = ty; }
    else { game.cam.x = lerp(game.cam.x, tx, 0.15); game.cam.y = lerp(game.cam.y, ty, 0.15); }
  }

  /* ------------------------- BUCLE ------------------------- */
  let last = performance.now();
  function loop(now) {
    const dt = Math.min(50, now - last); last = now;
    game.animT += dt;
    if (game.animT > 240) { game.frame ^= 1; game.animT = 0; }
    if (game.mode === 'overworld' || game.mode === 'menu' || game.mode === 'dialog' || game.mode === 'encounter') {
      PH.state.updateEnv(dt); if (PH.events) PH.events.update(dt); if (PH.garden) PH.garden.update(dt);
      if (PH.heat) PH.heat.update(dt);
      // Crecimiento en la carpa: bajo LED, cada slot plantado madura (0..100).
      const tent = G().tent;
      if (tent) for (const k in tent) { const st = tent[k]; if (st.spec && st.grow < 100) st.grow = Math.min(100, st.grow + dt * 0.010); }
    }
    if (game.mode === 'overworld') {
      tryMove();
      if (game.moving) { game.moveT += dt; if (game.moveT >= game.moveDur) finishMove(); }
      updateNPCs(dt);
      updateCop(dt);
      centerCam(false);
      if (now - game.lastSave > 20000) { PH.state.save(); game.lastSave = now; }
    }
    if (game.mode !== 'title' && game.mode !== 'boot') render(now);
    if (game.mode === 'overworld' && game.frame === 0) PH.ui.updateHUD();
    requestAnimationFrame(loop);
  }

  /* ------------------------- RENDER ------------------------- */
  function render(now) {
    const ctx = game.ctx, m = room(G().player.map); if (!m) return;
    // fondo por tema/bioma
    ctx.fillStyle = m.bg || (m.theme === 'street' ? '#2a3550' : '#14100c');
    ctx.fillRect(0, 0, game.W, game.H);

    // suelos especiales: 'g' parterre silvestre · 'w' agua · 'l' lava · 'H' fachadas
    const extraFloors = [];
    const walls = [];
    const propTiles = [];   // bordes/escenario natural (seto, valla, roca…) por tile
    for (let gy = 0; gy < m.grid.length; gy++) for (let gx = 0; gx < m.grid[gy].length; gx++) {
      const ch = m.grid[gy][gx];
      if (ch === 'g') { const wp = m.wildPal || { col: '#3f7d34', edge: '#2f5b26' }; extraFloors.push({ gx, gy, col: wp.col, edge: wp.edge }); propTiles.push({ gx, gy, kind: 'grass', opt: { col: wp.col } }); }
      else if (ch === 'w') { const wp = m.waterPal || { col: '#5aa6c0', edge: '#3f8aa4' }; extraFloors.push({ gx, gy, col: wp.col, edge: wp.edge }); }
      else if (ch === 'l') { const wp = m.lavaPal || { col: '#d5713f', edge: '#8a3f22' }; extraFloors.push({ gx, gy, col: wp.col, edge: wp.edge }); }
      else if (ch === 'm') { const rp = m.rugPal || { col: '#9a4636', edge: '#6a2f26' }; extraFloors.push({ gx, gy, col: rp.col, edge: rp.edge }); }
      else if (ch === '#' && m.natural) {
        // suelo del bioma bajo el prop + tipo: perímetro = borde (seto/valla), interior = escenario
        const fa = (m.pal && m.pal.floorA) || '#7cbd50', fe = (m.pal && m.pal.floorEdge) || 'rgba(30,60,20,.3)';
        extraFloors.push({ gx, gy, col: fa, edge: fe });
        const edge = gy === 0 || gy === m.grid.length - 1 || gx === 0 || gx === m.grid[gy].length - 1;
        propTiles.push({ gx, gy, kind: edge ? (m.borderKind || 'hedge') : (m.propKind || m.borderKind || 'hedge') });
      }
      else if (ch === 'H') walls.push({ gx, gy, h: 56, pal: ISO.THEMES.street.wall });
      else if (ch === 'P') walls.push({ gx, gy, h: 30, lamp: true, pal: { top: '#ffd34d', left: '#7c6a2a', right: '#9a8330' } });
    }

    const p = G().player;
    const pss = playerScreen();
    const px = pss.x, py = pss.y;
    // actores
    const actors = [];
    for (const n of (m.npcs || [])) { if (n._inactive) continue; actors.push(npcRender(n)); }
    if (game.cop && game.cop.map === p.map) actors.push(copRender(game.cop));
    // jugador con posición interpolada -> insertamos como actor con coords fraccionarias
    let pgx = p.x, pgy = p.y;
    if (game.moving) { const t = clamp(game.moveT / game.moveDur, 0, 1); pgx = lerp(game.from.x, game.to.x, t); pgy = lerp(game.from.y, game.to.y, t); }
    const walkFrame = game.moving ? (Math.floor(game.moveT / (game.moveDur / 2)) % 2 === 0 ? 1 : 2) : 0;
    actors.push({ gx: pgx, gy: pgy, dir: p.dir, frame: walkFrame, pal: { skin: '#f0c088', hair: '#3a2a1a', shirt: '#2f9e6b', pants: '#33333f' }, char: 'player', hero: true });

    // objetos: dibujarlos como parte del render (cubos etiquetados / grow con planta)
    const objects = (m.objects || []).map(o => ({ gx: o.gx, gy: o.gy, draw: (ctx, sx, sy) => drawObject(ctx, sx, sy, o) }));

    // combinar extraFloors dentro de renderRoom: hack -> dibujar suelos extra antes
    for (const ef of extraFloors) { const s = ISO.project(ef.gx, ef.gy, game.cam); ISO.floorDiamond(ctx, s.x, s.y, ef.col, ef.edge); }

    // props naturales (bordes/escenario) como objetos con profundidad
    for (const pt of propTiles) objects.push({ gx: pt.gx, gy: pt.gy, draw: (ctx, sx, sy) => ISO.prop(ctx, sx, sy, pt.kind, pt.opt) });

    // paredes 'H' como objetos altos; farolas 'P' con su sprite si existe
    for (const w of walls) objects.push({
      gx: w.gx, gy: w.gy, draw: (ctx, sx, sy) => {
        if (w.lamp && drawFurni(ctx, sx, sy, 'lamp', 52)) return;
        ISO.cube(ctx, sx, sy, w.h, w.pal);
      }
    });

    ISO.renderRoom(ctx, m, game.cam, now, actors, objects);
    if (m.leds) drawLeds(ctx, m);   // focos LED: cuadrantes 4×4 exactos

    // etiqueta del objeto/npc al frente si el jugador mira algo interactuable
    hudFacingLabel(ctx, m);
    envTint(ctx);
    if (game.dmg) applyDMG();
  }

  // Iluminación de precisión: cada foco tiñe su cuadrante 4×4 (sin difuminado
  // fuera de la rejilla) y dibuja la barra LED cenital.
  function drawLeds(ctx, m) {
    const TW = ISO.TW, TH = ISO.TH;
    const diamond = (sx, sy, fill) => { ctx.beginPath(); ctx.moveTo(sx, sy); ctx.lineTo(sx + TW / 2, sy + TH / 2); ctx.lineTo(sx, sy + TH); ctx.lineTo(sx - TW / 2, sy + TH / 2); ctx.closePath(); ctx.fillStyle = fill; ctx.fill(); };
    ctx.save(); ctx.globalCompositeOperation = 'lighter';
    for (const led of m.leds) {
      for (let dy = 0; dy < led.h; dy++) for (let dx = 0; dx < led.w; dx++) {
        const s = ISO.project(led.gx + dx, led.gy + dy, game.cam);
        diamond(s.x, s.y, 'rgba(216,130,224,0.09)');   // luz LED de cultivo (magenta suave)
      }
    }
    ctx.restore();
    // barra LED cenital sobre el centro de cada cuadrante
    for (const led of m.leds) {
      const s = ISO.project(led.gx + led.w / 2 - 0.5, led.gy, game.cam);
      const bx = s.x, by = s.y - 30;
      ctx.fillStyle = '#20161f'; ctx.fillRect(bx - 22, by - 4, 44, 6);
      ctx.fillStyle = '#e6b8ea'; ctx.fillRect(bx - 20, by - 3, 40, 3);
      ctx.fillStyle = 'rgba(230,184,234,0.5)'; ctx.fillRect(bx - 20, by, 40, 2);
    }
  }

  // Post-proceso "modo DMG": reduce a 160x144, cuantiza luminancia a 4 tonos
  // (paleta verde-oliva clásica) y reescala. Barato (~23k px/frame).
  const DMG_PAL = [[15, 56, 15], [48, 98, 48], [139, 172, 15], [155, 188, 15]];
  function applyDMG() {
    const DW = 160, DH = Math.max(1, Math.round(DW * game.H / game.W));   // proporción de pantalla
    if (!game._dmg || game._dmg.width !== DW || game._dmg.height !== DH) { const c = game._dmg || document.createElement('canvas'); c.width = DW; c.height = DH; game._dmg = c; }
    const sc = game._dmg.getContext('2d'); sc.imageSmoothingEnabled = false;
    sc.drawImage(game.canvas, 0, 0, DW, DH);
    const id = sc.getImageData(0, 0, DW, DH), d = id.data;
    for (let i = 0; i < d.length; i += 4) {
      const l = d[i] * 0.3 + d[i + 1] * 0.59 + d[i + 2] * 0.11;
      const c = DMG_PAL[l < 48 ? 0 : l < 108 ? 1 : l < 176 ? 2 : 3];
      d[i] = c[0]; d[i + 1] = c[1]; d[i + 2] = c[2];
    }
    sc.putImageData(id, 0, 0);
    const ctx = game.ctx; ctx.imageSmoothingEnabled = false;
    ctx.drawImage(game._dmg, 0, 0, game.W, game.H);
  }

  // Dibuja un sprite de mueble anclado a la base del tile (fallback: cubo).
  function drawFurni(ctx, sx, sy, kind, hCap) {
    const im = PH.furniart && PH.furniart.forKind(kind);
    if (im && im.complete && im.naturalWidth) {
      const H = hCap || 46, s = H / im.naturalHeight, w = Math.round(im.naturalWidth * s), h = Math.round(im.naturalHeight * s);
      const base = sy + ISO.TH * 0.85;
      ctx.drawImage(im, Math.round(sx - w / 2), Math.round(base - h), w, h);
      return true;
    }
    return false;
  }
  function drawObject(ctx, sx, sy, o) {
    if (PH.furniart && PH.furniart.has(o.kind)) {
      const done = drawFurni(ctx, sx, sy, o.kind, o.kind === 'grow' ? 40 : 48);
      if (o.kind === 'grow') {
        // planta encima de la mesa de cultivo (fase 4 de una cepa del banco)
        const bank = G().bank.find(b => b.form !== 'polen');
        const key = bank && PH.plantart ? PH.plantart.stageKey(bank.speciesId, 4) : null;
        const im = key && PH.plantart.img(key);
        if (im && im.complete) { const h = 34; ctx.drawImage(im, sx - h * 0.4, sy + ISO.TH * 0.85 - 30 - h, h * 0.8, h); }
      }
      if (done) return;
    }
    if (o.kind === 'grow') {
      ISO.cube(ctx, sx, sy, 12, { top: '#6b4a2a', left: '#4a3320', right: '#5a3f28' }); // mesa
      // planta encima (retrato de una cepa del banco si hay)
      const bank = G().bank.find(b => b.form !== 'polen');
      const key = bank && PH.plantart ? PH.plantart.stageKey(bank.speciesId, 4) : null;
      const im = key && PH.plantart.img(key);
      if (im && im.complete) { const h = 40; ctx.drawImage(im, sx - h * 0.4, sy - h + 6, h * 0.8, h); }
      else ISO.cube(ctx, sx, sy - 12, 22, { top: '#5aa64a', left: '#2f6b2a', right: '#3f8f3a' });
    } else if (o.kind === 'pc') ISO.cube(ctx, sx, sy, 20, { top: '#3a6ea5', left: '#233f5a', right: '#2d5273' });
    else if (o.kind === 'bed') ISO.cube(ctx, sx, sy, 8, { top: '#d64a6b', left: '#8f2f45', right: '#b03a55' });
    else if (o.kind === 'lab') ISO.cube(ctx, sx, sy, 14, { top: '#cfe0ea', left: '#8fa3b0', right: '#aebfc9' });
    else if (o.kind === 'shop') ISO.cube(ctx, sx, sy, 14, { top: '#ffb02e', left: '#9a6a18', right: '#c98d22' });
    else if (o.kind === 'plant') { ISO.cube(ctx, sx, sy, 9, { top: '#b06a42', left: '#6e3f26', right: '#8a5236' }); ISO.prop(ctx, sx, sy - 9, 'hedge'); } // maceta + fronda
    else if (o.kind === 'crate') ISO.cube(ctx, sx, sy, 16, { top: '#c79a5e', left: '#7a5533', right: '#9a6f3f' });
    else if (o.kind === 'barrel') { ISO.cube(ctx, sx, sy, 20, { top: '#8a5a30', left: '#5c3f26', right: '#6e4a2c' }); }
    else if (o.kind === 'shelf') ISO.cube(ctx, sx, sy, 34, { top: '#7a5533', left: '#4a3320', right: '#5c3f26' });
    else if (o.kind === 'sign') ISO.cube(ctx, sx, sy, 26, { top: '#b98a52', left: '#6e4a2c', right: '#8a5a30' });
    else if (o.kind === 'closet') {   // armario 2×1: mueble plateado con puertas
      const rx = sx + ISO.TW / 2, ry = sy + ISO.TH / 2;
      ISO.cube(ctx, rx, ry, 42, { top: '#c6cbd1', left: '#7c818a', right: '#9ea3ac' });
      ISO.cube(ctx, sx, sy, 42, { top: '#c6cbd1', left: '#7c818a', right: '#9ea3ac' });
      ctx.strokeStyle = '#565b62'; ctx.lineWidth = 1;
      ctx.beginPath(); ctx.moveTo(sx, sy + ISO.TH - 42); ctx.lineTo(sx, sy + ISO.TH); ctx.stroke();
      ctx.fillStyle = '#3f8f4a'; ctx.fillRect(sx - 5, sy - 8, 3, 3); ctx.fillRect(rx + 2, ry - 8, 3, 3);   // pilotos LED
    }
    else if (o.kind === 'duct') {
      ISO.cube(ctx, sx, sy, 22, { top: '#b6bbc3', left: '#7f848c', right: '#9aa0a8' });
      ctx.strokeStyle = '#767b83'; ctx.lineWidth = 1;
      for (let y = sy + ISO.TH - 20; y < sy + ISO.TH - 2; y += 4) { ctx.beginPath(); ctx.moveTo(sx - 8, y); ctx.lineTo(sx + 8, y); ctx.stroke(); }
    }
    else if (o.kind === 'extractor') {
      ISO.cube(ctx, sx, sy, 26, { top: '#9aa0a6', left: '#5f646a', right: '#7d828a' });
      const t = performance.now() / 110, cx = sx, cy = sy + ISO.TH - 26 - 6;
      ctx.strokeStyle = '#2e3339'; ctx.lineWidth = 2;
      for (let i = 0; i < 4; i++) { const a = t + i * Math.PI / 2; ctx.beginPath(); ctx.moveTo(cx, cy); ctx.lineTo(cx + Math.cos(a) * 8, cy + Math.sin(a) * 5); ctx.stroke(); }
      ctx.fillStyle = '#cbd0d6'; ctx.beginPath(); ctx.arc(cx, cy, 2, 0, 6.283); ctx.fill();
    }
    else if (o.kind === 'slot') {
      const st = game.tentSlot(o.idx);
      ISO.cube(ctx, sx, sy, 10, { top: '#5a4a3a', left: '#3a2f24', right: '#4a3d2e' });   // superficie de mesa
      if (st.hasPot) {
        ISO.cube(ctx, sx, sy - 10, 8, { top: '#c07048', left: '#7a4028', right: '#9a5636' });   // maceta
        if (st.spec) {
          const stage = Math.min(4, Math.floor(st.grow / 25));
          const key = PH.plantart && PH.plantart.stageKey(st.spec.speciesId, stage);
          const im = key && PH.plantart.img(key);
          if (im && im.complete && im.naturalWidth) { const h = 10 + stage * 7; ctx.drawImage(im, sx - h * 0.4, sy + ISO.TH - 22 - h, h * 0.8, h); }
          else PH.render.drawPlant(ctx, sx, sy + ISO.TH - 20, st.spec.pheno, 0.55 + stage * 0.22, performance.now());
        }
      }
    }
    else if (o.kind === 'bench') {   // banco decorativo (atrezzo, sólido: nadie se sienta)
      ISO.cube(ctx, sx, sy, 8, { top: '#a9803f', left: '#6e4a2c', right: '#8a5a30' });                 // asiento
      ISO.cube(ctx, sx - 11, sy - 5, 20, { top: '#8a5a30', left: '#5c3f26', right: '#6e4a2c' });        // respaldo (al fondo)
      ctx.fillStyle = '#4a3320'; ctx.fillRect(sx - 13, sy + ISO.TH - 8, 3, 8); ctx.fillRect(sx + 10, sy + ISO.TH - 8, 3, 8);
    }
    else if (o.kind === 'trash') {   // papelera / basura
      ISO.cube(ctx, sx, sy, 20, { top: '#455040', left: '#263022', right: '#2f3a2c' });
      ctx.fillStyle = '#586551'; ctx.beginPath(); ctx.ellipse(sx, sy + ISO.TH * 0.5 - 20, ISO.TW * 0.22, ISO.TH * 0.28, 0, 0, 6.283); ctx.fill();
      ctx.fillStyle = '#c9b46a'; ctx.fillRect(sx - 4, sy + ISO.TH * 0.5 - 27, 3, 6);
      ctx.fillStyle = '#8a6a3a'; ctx.fillRect(sx + 2, sy + ISO.TH * 0.5 - 26, 4, 5);
      ctx.fillStyle = '#a8442f'; ctx.fillRect(sx - 1, sy + ISO.TH * 0.5 - 24, 3, 3);
    }
    else if (o.kind === 'planter') {   // jardinera con arbusto
      ISO.cube(ctx, sx, sy, 12, { top: '#b06a42', left: '#6e3f26', right: '#8a5236' });
      ISO.prop(ctx, sx, sy - 12, 'hedge');
    }
    else if (o.kind === 'lamppost') {   // farola
      ctx.fillStyle = '#2e2a30'; ctx.fillRect(sx - 2, sy + ISO.TH - 48, 4, 48);
      ISO.cube(ctx, sx, sy, 6, { top: '#3a3640', left: '#232028', right: '#2e2a32' });
      ctx.fillStyle = '#f2d47a'; ctx.beginPath(); ctx.ellipse(sx, sy + ISO.TH - 50, 5, 4, 0, 0, 6.283); ctx.fill();
      ctx.fillStyle = 'rgba(242,212,122,.35)'; ctx.beginPath(); ctx.ellipse(sx, sy + ISO.TH - 50, 9, 7, 0, 0, 6.283); ctx.fill();
    }
    else if (o.kind === 'hydrant') {   // boca de riego / hidrante
      ISO.cube(ctx, sx, sy, 16, { top: '#c34638', left: '#7a2a22', right: '#9a352b' });
      ctx.fillStyle = '#8a2f26'; ctx.fillRect(sx - 8, sy + ISO.TH * 0.5 - 10, 3, 4); ctx.fillRect(sx + 5, sy + ISO.TH * 0.5 - 10, 3, 4);
      ctx.fillStyle = '#e0b23c'; ctx.beginPath(); ctx.ellipse(sx, sy + ISO.TH * 0.5 - 16, 4, 3, 0, 0, 6.283); ctx.fill();
    }
    else if (o.kind === 'sacks') {   // sacos de sustrato apilados
      const sack = (dx, dy, c) => { ctx.fillStyle = c; ctx.beginPath(); ctx.ellipse(sx + dx, sy + ISO.TH * 0.5 + dy, 11, 8, 0, 0, 6.283); ctx.fill(); ctx.strokeStyle = 'rgba(0,0,0,.2)'; ctx.beginPath(); ctx.moveTo(sx + dx - 6, sy + ISO.TH * 0.5 + dy - 6); ctx.lineTo(sx + dx + 6, sy + ISO.TH * 0.5 + dy - 6); ctx.stroke(); };
      sack(-5, 2, '#b39a68'); sack(6, 3, '#a8946a'); sack(0, -7, '#c9b482');
    }
    else ISO.cube(ctx, sx, sy, 14, { top: '#999', left: '#555', right: '#777' });
  }

  function hudFacingLabel(ctx, m) {
    if (game.mode !== 'overworld' || game.moving) return;
    const f = facing();
    const target = npcAt(m, f.gx, f.gy) || objAt(m, f.gx, f.gy) || doorAt(m, f.gx, f.gy);
    if (!target) return;
    const s = ISO.project(f.gx, f.gy, game.cam);
    const label = target.name || target.label || (target.to ? '→ ' + (room(target.to) ? room(target.to).name : '') : '');
    if (!label) return;
    ctx.font = '8px monospace'; ctx.textAlign = 'center';
    const w = ctx.measureText(label).width + 8;
    ctx.fillStyle = 'rgba(0,0,0,.6)'; ctx.fillRect(s.x - w / 2, s.y - 6, w, 11);
    ctx.fillStyle = '#fff'; ctx.fillText(label, s.x, s.y + 2);
  }

  function envTint(ctx) {
    const env = G().env; const t = env.time; let a = 0;
    if (t < 5 * 60) a = 0.42; else if (t < 7 * 60) a = lerp(0.42, 0, (t - 300) / 120);
    else if (t < 18 * 60) a = 0; else if (t < 20 * 60) a = lerp(0, 0.38, (t - 1080) / 120); else a = 0.42;
    if (a > 0) { ctx.fillStyle = `rgba(0,0,25,${a})`; ctx.fillRect(0, 0, game.W, game.H); }
  }

  PH.game.init = init;
  window.addEventListener('DOMContentLoaded', init);
})(window.PH = window.PH || {});

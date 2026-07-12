/* ============================================================
   PHENO HUNTER — state.js
   Estado global: jugador, banco genético, catálogo, misiones,
   ambiente (clima/estación/ciclo día-noche) y guardado.
   ============================================================ */
(function (PH) {
  'use strict';
  const { RNG, clamp } = PH.util;

  const SAVE_KEY = 'phenohunter_save_v1';

  function freshState() {
    return {
      version: 1,
      player: {
        name: 'Aprendiz',
        map: 'lab',
        x: PH.world.MAPS.lab.spawn.x,
        y: PH.world.MAPS.lab.spawn.y,
        dir: 'down',
        credits: 300,
        prestige: 0,
        tools: ['frasco', 'polen'],   // ids de herramientas poseídas
        gear: [],                      // ids de equipo
        activeTool: 'frasco',
        cebosActivos: 0,               // encuentros con feromona
      },
      bank: [],          // especímenes almacenados
      catalog: {},       // signature -> {sig, speciesId, name, tier, rarity, count, firstAt, pheno}
      species: {},       // speciesId -> {seen, obtained}
      quests: {},        // questId -> {state:'active'|'done', progress}
      flags: {},         // banderas de historia
      stats: { discoveries: 0, crosses: 0, mutationsFound: 0, distance: 0 },
      env: makeEnv(),
      playtime: 0,
    };
  }

  function makeEnv() {
    return {
      time: 8 * 60,          // minutos del día (0..1440)
      dayLength: 8 * 60 * 1000, // ms reales por día de juego
      season: 'primavera',
      weather: 'despejado',
      weatherTimer: 30000,
      night: false,
      heat: false,
    };
  }

  const SEASONS = ['primavera', 'verano', 'otono', 'invierno'];
  const WEATHERS = [
    { key: 'despejado', w: 40 },
    { key: 'lluvia', w: 16 },
    { key: 'niebla', w: 12 },
    { key: 'tormenta', w: 6 },
    { key: 'ola_calor', w: 6 },
    { key: 'nublado', w: 20 },
  ];

  const state = { data: freshState() };

  function get() { return state.data; }

  // Avanza el ambiente (dt en ms)
  function updateEnv(dt) {
    const env = state.data.env;
    // ciclo día/noche: mapea dayLength al reloj interno
    env.time += (dt / env.dayLength) * 1440;
    if (env.time >= 1440) { env.time -= 1440; advanceSeason(env); }
    env.night = env.time < 5 * 60 || env.time >= 20 * 60;
    env.heat = env.weather === 'ola_calor';
    // clima
    env.weatherTimer -= dt;
    if (env.weatherTimer <= 0) {
      env.weather = RNG.weighted(WEATHERS, 'w').key;
      env.weatherTimer = RNG.i(20000, 60000);
    }
  }
  function advanceSeason(env) {
    const i = SEASONS.indexOf(env.season);
    env.season = SEASONS[(i + 1) % 4];
  }

  function timeLabel(env) {
    const h = Math.floor(env.time / 60), m = Math.floor(env.time % 60);
    return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
  }

  /* ---------------- BANCO GENÉTICO ---------------- */
  function bankAdd(specimen) {
    state.data.bank.push(specimen);
    registerCatalog(specimen);
  }
  function bankRemove(uid) {
    const i = state.data.bank.findIndex(s => s.uid === uid);
    if (i >= 0) return state.data.bank.splice(i, 1)[0];
    return null;
  }
  function bankGet(uid) { return state.data.bank.find(s => s.uid === uid); }

  /* ---------------- CATÁLOGO ---------------- */
  // Devuelve {isNewSignature, isNewSpecies, entry}
  function registerCatalog(specimen) {
    const sp = state.data.species[specimen.speciesId] || { seen: 0, obtained: 0 };
    const isNewSpecies = sp.obtained === 0;
    sp.obtained++;
    state.data.species[specimen.speciesId] = sp;

    const sig = specimen.signature;
    let entry = state.data.catalog[sig];
    let isNewSignature = false;
    if (!entry) {
      isNewSignature = true;
      entry = {
        sig, speciesId: specimen.speciesId, name: specimen.name,
        tier: specimen.tier, rarity: specimen.rarity,
        count: 0, firstAt: PH.state.timeLabel(state.data.env),
        pheno: specimen.pheno, genotype: specimen.genotype,
        mutations: specimen.pheno.mutations.slice(),
      };
      state.data.catalog[sig] = entry;
      state.data.stats.discoveries++;
      if (specimen.pheno.mutations.length) state.data.stats.mutationsFound++;
      // Prestigio por descubrimiento, escalado por rareza
      addPrestige(Math.round(3 + specimen.rarity / 3));
    }
    entry.count++;
    return { isNewSignature, isNewSpecies, entry };
  }

  function markSeen(speciesId) {
    const sp = state.data.species[speciesId] || { seen: 0, obtained: 0 };
    sp.seen++;
    state.data.species[speciesId] = sp;
  }

  function addPrestige(n) {
    state.data.player.prestige += n;
  }
  function addCredits(n) { state.data.player.credits = Math.max(0, state.data.player.credits + n); }

  // Umbrales de prestigio que desbloquean contenido
  const PRESTIGE_UNLOCKS = [
    { at: 0, id: 'pradera', label: 'Pradera de Auralia' },
    { at: 10, id: 'bosque', label: 'Bosque de Vael' },
    { at: 30, id: 'pantano', label: 'Cenagal de Mureb' },
    { at: 60, id: 'expedicion', label: 'Expediciones marítimas' },
    { at: 100, id: 'reliquias', label: 'Licencia de reliquias' },
  ];
  function unlocked(id) {
    const u = PRESTIGE_UNLOCKS.find(x => x.id === id);
    if (!u) return true;
    return state.data.player.prestige >= u.at;
  }

  /* ---------------- GUARDADO ---------------- */
  function save() {
    try {
      localStorage.setItem(SAVE_KEY, JSON.stringify(state.data));
      return true;
    } catch (e) { return false; }
  }
  function load() {
    try {
      const raw = localStorage.getItem(SAVE_KEY);
      if (!raw) return false;
      const d = JSON.parse(raw);
      if (d && d.version) { state.data = Object.assign(freshState(), d); return true; }
    } catch (e) {}
    return false;
  }
  function reset() { state.data = freshState(); localStorage.removeItem(SAVE_KEY); }
  function hasSave() { try { return !!localStorage.getItem(SAVE_KEY); } catch (e) { return false; } }

  PH.state = {
    SAVE_KEY, freshState, get, updateEnv, timeLabel, SEASONS, WEATHERS, PRESTIGE_UNLOCKS,
    bankAdd, bankRemove, bankGet, registerCatalog, markSeen,
    addPrestige, addCredits, unlocked, save, load, reset, hasSave,
  };
})(window.PH = window.PH || {});

/* ============================================================
   STRAINMON — species.js
   Cepas landrace por región, perfiles genéticos y aparición.
   Nombres de parodia originales inspirados en genéticas landrace.
   ============================================================ */
(function (PH) {
  'use strict';
  const { RNG } = PH.util;
  const { wildGenotype, express, rarityScore, rarityTier, phenoSignature } = PH.gen;

  // Cada cepa es una landrace: pura, adaptada a su región de origen.
  const SPECIES = (PH.speciesData || []);

  const SPECIES_BY_ID = Object.fromEntries(SPECIES.map(s => [s.id, s]));

  // Cruce canónico del árbol: un nodo se reconoce cuando el CONJUNTO de cepas
  // aportadas por los dos parentales del cruce coincide con sus parentales
  // (cualquier aridad). Cada muestra arrastra su "receta" (strainSet); cruces
  // encadenados van uniendo conjuntos hasta completar nodos de 3-4 parentales
  // (afghani×acapulco -> {afghani,acapulco}; ×colombian -> Skunk #1).
  const CANON_CROSS = {};
  for (const s of SPECIES) {
    if (s.parents && s.parents.length >= 2) CANON_CROSS[[...new Set(s.parents)].sort().join('+')] = s.id;
  }
  function canonicalBySet(strainIds) {
    const hit = CANON_CROSS[[...new Set(strainIds)].sort().join('+')];
    return hit ? SPECIES_BY_ID[hit] : null;
  }
  function canonicalCross(idA, idB) { return canonicalBySet([idA, idB]); }

  // --- Motor de restricciones de cruce (cierre de matriz) ---
  // Retrocruces estabilizados: única autopolinización válida (A×A). Del spec:
  // sólo Bubblegum×Bubblegum = Sour Bubble.
  const SELF_CROSS = { bubblegum: 'sour_bubble' };
  // Clones / fenotipos aislados: NODOS de 1 parental que NO son retrocruce.
  // No se obtienen por cruce; requieren "Selección fenotípica / esqueje" (ítem).
  const CLONE_BY_PARENT = {};   // parentId -> [cloneId, ...]
  const CLONE_IDS = new Set();
  for (const s of SPECIES) {
    if (s.parents && s.parents.length === 1) {
      const p = s.parents[0];
      if (SELF_CROSS[p] === s.id) continue;   // es retrocruce, no clon
      (CLONE_BY_PARENT[p] = CLONE_BY_PARENT[p] || []).push(s.id);
      CLONE_IDS.add(s.id);
    }
  }
  function isClone(id) { return CLONE_IDS.has(id); }
  function cloneOptions(speciesId) { return CLONE_BY_PARENT[speciesId] || []; }
  // Selección fenotípica: sobre un nodo base, devuelve su clon (RNG si hay varios).
  function phenotypeSelect(speciesId) {
    const opts = CLONE_BY_PARENT[speciesId];
    return (opts && opts.length) ? SPECIES_BY_ID[RNG.pick(opts)] : null;
  }

  // Resuelve un cruce según las reglas duras. Devuelve { node, reason }:
  // reason: 'canon' (nodo del árbol), 'backcross' (retrocruce), 'self' (autopol.
  // bloqueada), 'closed' (fuera de la matriz -> bloqueado, sin sprite procedural).
  // Resuelve una FUSIÓN de 2-4 parentales (cada uno con su strainSet/receta).
  // Devuelve { node, reason, union, toward?, missing? }.
  // reason: 'need' (<2), 'canon', 'backcross', 'self' (autopol. bloqueada),
  // 'partial' (faltan parentales para un nodo multi-parental), 'closed'.
  function resolveCross(sets) {
    sets = (sets || []).filter(Boolean);
    if (sets.length < 2) return { node: null, reason: 'need' };
    const uniq = [...new Set(sets.flat())];
    // Autopolinización: todos los parentales son la MISMA cepa mono-nodo.
    if (sets.every(s => s.length === 1) && uniq.length === 1) {
      const child = SELF_CROSS[uniq[0]];
      return child ? { node: SPECIES_BY_ID[child], reason: 'backcross', union: uniq } : { node: null, reason: 'self', union: uniq };
    }
    const node = canonicalBySet(uniq);
    if (node) return { node, reason: 'canon', union: uniq };
    // ¿subconjunto propio de un nodo multi-parental? -> faltan parentales.
    const toward = SPECIES.find(sp => sp.parents && sp.parents.length > uniq.length &&
      uniq.every(u => sp.parents.includes(u)));
    if (toward) return { node: null, reason: 'partial', union: uniq, toward, missing: toward.parents.filter(p => !uniq.includes(p)) };
    return { node: null, reason: 'closed', union: uniq };
  }

  // Biomas = regiones landrace del mundo.
  const BIOMES = {
    pradera:  { name: 'Altiplano de Michoacán', baseEncounter: 0.14 },
    bosque:   { name: 'Triángulo Dorado',       baseEncounter: 0.16 },
    pantano:  { name: 'Delta del Congo',        baseEncounter: 0.18 },
    desierto: { name: 'Rif de Marruecos',       baseEncounter: 0.15 },
    nieve:    { name: 'Cumbres del Hindú Kush',  baseEncounter: 0.16 },
    volcan:   { name: 'Cráteres de Oaxaca',     baseEncounter: 0.17 },
    cueva:    { name: 'Cuevas de Chitral',      baseEncounter: 0.20 },
    isla:     { name: 'Costa de Jamaica',       baseEncounter: 0.17 },
  };

  function envMultiplier(species, env) {
    let m = 1;
    if (env.weather === 'niebla' && species.biomes.includes('pantano')) m *= 1.6;
    if (env.weather === 'lluvia' && species.biomes.includes('pantano')) m *= 1.5;
    if (env.night && (species.id === 'SM-016' || species.id === 'SM-014' || species.relic)) m *= 2;
    if (env.weather === 'tormenta' && species.mutBoost) m *= 1.4;
    if (env.season === 'invierno' && species.biomes.includes('nieve')) m *= 1.4;
    if (env.season === 'verano' && species.biomes.includes('desierto')) m *= 1.3;
    if ((env.heat || env.weather === 'ola_calor') && (species.biomes.includes('desierto') || species.biomes.includes('volcan'))) m *= 1.6;
    if (PH.events && PH.events.spawnMultiplier) m *= PH.events.spawnMultiplier(species, env);
    return m;
  }

  // Peso base de aparición (sin clima). Determina la probabilidad relativa.
  function spawnWeight(s) { return s.relic ? 1 : (s.tier === 1 ? 5 : 20); }

  // Clasificación de rareza de APARICIÓN (distinta de la rareza del fenotipo).
  function spawnRarity(s) {
    if (s.relic) return { key: 'legendaria', label: 'Legendaria', color: '#e0b23c' };
    if (s.tier >= 2) return { key: 'muyrara', label: 'Muy rara', color: '#a06fd6' };
    if (s.tier === 1) return { key: 'rara', label: 'Rara', color: '#5aa6c0' };
    return { key: 'comun', label: 'Común', color: '#5ab04f' };
  }

  // Probabilidad (%) base de que una cepa salga en la hierba alta de un bioma.
  function biomeChance(s, biome) {
    if (!s.biomes.includes(biome)) return 0;
    const list = SPECIES.filter(x => x.biomes.includes(biome));
    const tot = list.reduce((a, x) => a + spawnWeight(x), 0);
    return tot ? (spawnWeight(s) / tot) * 100 : 0;
  }

  // Tabla de probabilidades de un bioma (base, ordenada de más a menos probable).
  function biomeOdds(biome) {
    const list = SPECIES.filter(s => s.biomes.includes(biome));
    const tot = list.reduce((a, s) => a + spawnWeight(s), 0);
    return list.map(s => ({ ref: s, w: spawnWeight(s), pct: tot ? (spawnWeight(s) / tot) * 100 : 0 }))
      .sort((a, b) => b.pct - a.pct);
  }

  function spawnTable(biome, env) {
    const list = SPECIES.filter(s => s.biomes.includes(biome));
    return list.map(s => {
      let w = spawnWeight(s) * envMultiplier(s, env);   // tier-1 más raras que las landrace
      return { ref: s, w };
    });
  }

  let uidc = 0;
  function makeSpecimen(species, env, opts) {
    opts = opts || {};
    const genotype = opts.genotype || wildGenotype(species.profile);
    const pheno = express(genotype);
    const score = rarityScore(genotype);
    const tier = rarityTier(score);
    const sig = phenoSignature(genotype);
    const form = opts.form || 'salvaje';
    // Pureza landrace: 100% en cepas salvajes gen 0; los híbridos la diluyen.
    const purity = opts.purity != null ? opts.purity : (form === 'cruce' ? 50 : 100);
    const landrace = opts.landrace != null ? opts.landrace : (form !== 'cruce');
    return {
      uid: 'S' + (++uidc) + Date.now().toString(36).slice(-3),
      speciesId: species.id, name: species.name,
      genotype, pheno, rarity: score, tier: tier.key, signature: sig,
      form, quality: opts.quality != null ? opts.quality : 100,
      parents: opts.parents || null,
      caughtAt: opts.caughtAt || null,
      generation: opts.generation || 0,
      sequenced: opts.sequenced || false,
      purity, landrace,
      strainSet: opts.strainSet || [species.id],   // "receta" de cepas para cruces encadenados
      nickname: null,
    };
  }

  function rollEncounter(biome, env) {
    const table = spawnTable(biome, env);
    const chosen = RNG.weighted(table, 'w').ref;
    return makeSpecimen(chosen, env, { form: 'salvaje', caughtAt: null });
  }

  PH.species = { SPECIES, SPECIES_BY_ID, BIOMES, spawnTable, spawnWeight, spawnRarity, biomeChance, biomeOdds, makeSpecimen, rollEncounter, envMultiplier, canonicalCross, canonicalBySet, resolveCross, isClone, cloneOptions, phenotypeSelect, CLONE_BY_PARENT, SELF_CROSS };
})(window.PH = window.PH || {});

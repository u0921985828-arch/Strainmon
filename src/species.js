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

  // Cruce canónico del árbol: dos parentales que coinciden EXACTAMENTE con los
  // de un nodo de 2 parentales producen esa cepa nombrada (Blueberry × SSH ->
  // Blue Dream). Los nodos de 3+ parentales requieren cruces encadenados.
  const CANON_CROSS = {};
  for (const s of SPECIES) {
    if (s.parents && s.parents.length === 2) CANON_CROSS[[...s.parents].sort().join('+')] = s.id;
  }
  function canonicalCross(idA, idB) {
    const hit = CANON_CROSS[[idA, idB].sort().join('+')];
    return hit ? SPECIES_BY_ID[hit] : null;
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

  function spawnTable(biome, env) {
    const list = SPECIES.filter(s => s.biomes.includes(biome));
    return list.map(s => {
      let w = s.relic ? 1 : (s.tier === 1 ? 5 : 20);   // tier-1 más raras que las landrace
      w *= envMultiplier(s, env);
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
      nickname: null,
    };
  }

  function rollEncounter(biome, env) {
    const table = spawnTable(biome, env);
    const chosen = RNG.weighted(table, 'w').ref;
    return makeSpecimen(chosen, env, { form: 'salvaje', caughtAt: null });
  }

  PH.species = { SPECIES, SPECIES_BY_ID, BIOMES, spawnTable, makeSpecimen, rollEncounter, envMultiplier, canonicalCross };
})(window.PH = window.PH || {});

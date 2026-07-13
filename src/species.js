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
  const SPECIES = [
    // ---------- ALTIPLANO DE MICHOACÁN (pradera) ----------
    { id: 'SM-001', name: 'Michoacana', family: 'Sativa de altura', biomes: ['pradera'],
      origin: 'Altiplano de Michoacán', region: 'américa',
      story: 'Landrace mexicana de tierras altas. Sativa espigada, cerebral y resistente al sol.',
      profile: { colors: [{ key: 'lima', w: 4 }, { key: 'verde', w: 3 }], leaves: [{ key: 'estrecha', w: 4 }, { key: 'digitada', w: 2 }], terps: [{ key: 'citrico', w: 3 }, { key: 'especiado', w: 2 }], quant: { altura: 65, produccion: 55, vigor: 60, resistencia: 55, velocidad: 45, resina: 40, aroma: 60 } } },
    { id: 'SM-002', name: 'Oro de Acapulco', family: 'Sativa costera', biomes: ['pradera'],
      origin: 'Costas de Guerrero', region: 'américa',
      story: 'Legendaria landrace dorada. Cogollos de un ámbar cálido y aroma cítrico intenso.',
      profile: { colors: [{ key: 'oro', w: 3 }, { key: 'ambar', w: 4 }], leaves: [{ key: 'digitada', w: 3 }], terps: [{ key: 'citrico', w: 4 }, { key: 'dulce', w: 2 }], quant: { altura: 70, produccion: 60, vigor: 65, resistencia: 50, velocidad: 40, resina: 55, aroma: 75 }, mutBoost: 1.3 } },
    { id: 'SM-003', name: 'Punto Rojo', family: 'Sativa andina', biomes: ['pradera', 'bosque'],
      origin: 'Cordillera colombiana', region: 'américa',
      story: 'Landrace colombiana de pistilos rojizos. Larga floración y efecto eufórico.',
      profile: { colors: [{ key: 'carmesi', w: 3 }, { key: 'ambar', w: 2 }, { key: 'verde', w: 2 }], leaves: [{ key: 'estrecha', w: 3 }], terps: [{ key: 'dulce', w: 3 }, { key: 'floral', w: 2 }], quant: { altura: 72, produccion: 58, vigor: 60, resistencia: 45, velocidad: 35, resina: 55, aroma: 70 } } },
    // ---------- TRIÁNGULO DORADO (bosque) ----------
    { id: 'SM-004', name: 'Tailandesa', family: 'Sativa ecuatorial', biomes: ['bosque'],
      origin: 'Selvas del Triángulo Dorado', region: 'asia',
      story: 'Landrace tailandesa esbelta y trepadora. Floración larguísima, terpenos exóticos.',
      profile: { colors: [{ key: 'lima', w: 4 }, { key: 'verde', w: 2 }], leaves: [{ key: 'estrecha', w: 4 }, { key: 'aciculada', w: 1 }], terps: [{ key: 'especiado', w: 3 }, { key: 'citrico', w: 2 }], quant: { altura: 80, produccion: 55, vigor: 55, resistencia: 40, velocidad: 30, resina: 60, aroma: 80 }, mutBoost: 1.4 } },
    { id: 'SM-005', name: 'Laosiana', family: 'Sativa de selva', biomes: ['bosque'],
      origin: 'Montes de Laos', region: 'asia',
      story: 'Landrace de las tierras altas de Laos. Aroma dulce y madera, muy vigorosa.',
      profile: { colors: [{ key: 'verde', w: 3 }, { key: 'purpura', w: 2 }], leaves: [{ key: 'digitada', w: 3 }], terps: [{ key: 'dulce', w: 3 }, { key: 'terroso', w: 2 }], quant: { altura: 68, produccion: 60, vigor: 65, resistencia: 50, velocidad: 40, resina: 55, aroma: 70 } } },
    // ---------- CUEVAS DE CHITRAL (cueva) ----------
    { id: 'SM-006', name: 'Charas de Chitral', family: 'Índica de charas', biomes: ['cueva'],
      origin: 'Valle de Chitral', region: 'asia',
      story: 'Landrace productora de charas. Resina abundante que se frota a mano.',
      profile: { colors: [{ key: 'verde', w: 3 }, { key: 'ambar', w: 2 }], leaves: [{ key: 'ancha', w: 4 }], terps: [{ key: 'terroso', w: 4 }, { key: 'especiado', w: 2 }], quant: { altura: 45, produccion: 60, vigor: 60, resistencia: 65, velocidad: 60, resina: 85, aroma: 65 }, mutBoost: 1.6 } },
    { id: 'SM-007', name: 'Nepalí de Montaña', family: 'Híbrida himalaya', biomes: ['cueva', 'nieve'],
      origin: 'Colinas de Nepal', region: 'asia',
      story: 'Landrace nepalí de altura. Compacta, resinosa y de aroma a incienso.',
      profile: { colors: [{ key: 'purpura', w: 3 }, { key: 'verde', w: 2 }], leaves: [{ key: 'ancha', w: 3 }, { key: 'palmada', w: 2 }], terps: [{ key: 'incienso', w: 3 }, { key: 'floral', w: 2 }], quant: { altura: 50, produccion: 55, vigor: 55, resistencia: 60, velocidad: 55, resina: 80, aroma: 78 }, mutBoost: 1.7 } },
    // ---------- DELTA DEL CONGO (pantano) ----------
    { id: 'SM-008', name: 'Reina del Congo', family: 'Sativa africana', biomes: ['pantano'],
      origin: 'Cuenca del Congo', region: 'áfrica',
      story: 'Landrace africana rápida para ser sativa. Efecto claro, aroma a fruta ácida.',
      profile: { colors: [{ key: 'lima', w: 3 }, { key: 'verde', w: 3 }], leaves: [{ key: 'estrecha', w: 3 }], terps: [{ key: 'citrico', w: 3 }, { key: 'dulce', w: 2 }], quant: { altura: 66, produccion: 62, vigor: 70, resistencia: 55, velocidad: 55, resina: 50, aroma: 72 } } },
    { id: 'SM-009', name: 'Malawi Dorada', family: 'Sativa ecuatorial', biomes: ['pantano', 'pradera'],
      origin: 'Lago Malawi', region: 'áfrica',
      story: 'Landrace africana de cogollos enormes y dorados. Una de las sativas más potentes.',
      profile: { colors: [{ key: 'oro', w: 3 }, { key: 'lima', w: 2 }], leaves: [{ key: 'digitada', w: 3 }], terps: [{ key: 'especiado', w: 3 }, { key: 'incienso', w: 1 }], quant: { altura: 78, produccion: 68, vigor: 70, resistencia: 55, velocidad: 35, resina: 65, aroma: 82 }, mutBoost: 1.5, ploidyBoost: 1.4 } },
    // ---------- COSTA DE JAMAICA (isla) ----------
    { id: 'SM-010', name: 'Jamaicana Costera', family: 'Sativa isleña', biomes: ['isla'],
      origin: 'Costas de Jamaica', region: 'américa',
      story: 'Landrace caribeña tolerante a la brisa salina. Aroma marino y dulce tropical.',
      profile: { colors: [{ key: 'lima', w: 3 }, { key: 'turquesa', w: 2 }], leaves: [{ key: 'palmada', w: 3 }], terps: [{ key: 'marino', w: 3 }, { key: 'dulce', w: 2 }], quant: { altura: 64, produccion: 60, vigor: 65, resistencia: 60, velocidad: 50, resina: 55, aroma: 74 }, mutBoost: 1.4 } },
    // ---------- RIF DE MARRUECOS (desierto) ----------
    { id: 'SM-011', name: 'Rifeña Kif', family: 'Índica de hachís', biomes: ['desierto'],
      origin: 'Montañas del Rif', region: 'áfrica',
      story: 'Landrace marroquí para hachís. Seca, compacta y de tricomas abundantes.',
      profile: { colors: [{ key: 'lima', w: 3 }, { key: 'ambar', w: 2 }], leaves: [{ key: 'ancha', w: 3 }, { key: 'serrada', w: 2 }], terps: [{ key: 'especiado', w: 3 }, { key: 'terroso', w: 3 }], quant: { altura: 50, produccion: 55, vigor: 55, resistencia: 80, velocidad: 65, resina: 78, aroma: 62 }, mutBoost: 1.3 } },
    { id: 'SM-012', name: 'Beldia', family: 'Landrace del Rif', biomes: ['desierto'],
      origin: 'Ketama', region: 'áfrica',
      story: 'Antigua landrace del Rif, casi desplazada por híbridos. Rústica y aromática.',
      profile: { colors: [{ key: 'verde', w: 3 }, { key: 'rosa', w: 2 }], leaves: [{ key: 'serrada', w: 3 }], terps: [{ key: 'floral', w: 3 }, { key: 'dulce', w: 2 }], quant: { altura: 55, produccion: 50, vigor: 55, resistencia: 75, velocidad: 60, resina: 60, aroma: 68 } } },
    // ---------- CRÁTERES DE OAXACA (volcán) ----------
    { id: 'SM-013', name: 'Oaxaqueña', family: 'Sativa volcánica', biomes: ['volcan'],
      origin: 'Sierra de Oaxaca', region: 'américa',
      story: 'Landrace de suelos volcánicos. Vigorosa, de aroma ahumado y terroso.',
      profile: { colors: [{ key: 'carmesi', w: 3 }, { key: 'ambar', w: 2 }, { key: 'oro', w: 1 }], leaves: [{ key: 'lobulada', w: 3 }], terps: [{ key: 'ahumado', w: 3 }, { key: 'especiado', w: 2 }], quant: { altura: 68, produccion: 62, vigor: 72, resistencia: 65, velocidad: 45, resina: 60, aroma: 72 }, mutBoost: 1.7, ploidyBoost: 1.3 } },
    { id: 'SM-014', name: 'Rojo de Panamá', family: 'Sativa tropical', biomes: ['volcan', 'isla'],
      origin: 'Istmo de Panamá', region: 'américa',
      story: 'Landrace roja legendaria del istmo. Cerebral, veteada de rojo y púrpura.',
      profile: { colors: [{ key: 'carmesi', w: 3 }, { key: 'purpura', w: 2 }], leaves: [{ key: 'digitada', w: 3 }], terps: [{ key: 'dulce', w: 3 }, { key: 'floral', w: 2 }], quant: { altura: 74, produccion: 58, vigor: 65, resistencia: 50, velocidad: 35, resina: 60, aroma: 80 }, mutBoost: 1.6, ploidyBoost: 1.5 } },
    // ---------- CUMBRES DEL HINDÚ KUSH (nieve) ----------
    { id: 'SM-015', name: 'Kush Ancestral', family: 'Índica de montaña', biomes: ['nieve'],
      origin: 'Cordillera del Hindú Kush', region: 'asia',
      story: 'La índica original de las montañas. Compacta, resinosa y resistente al frío.',
      profile: { colors: [{ key: 'verde', w: 3 }, { key: 'purpura', w: 3 }], leaves: [{ key: 'ancha', w: 4 }], terps: [{ key: 'terroso', w: 3 }, { key: 'incienso', w: 2 }], quant: { altura: 45, produccion: 65, vigor: 60, resistencia: 78, velocidad: 65, resina: 85, aroma: 72 }, mutBoost: 1.6 } },
    { id: 'SM-016', name: 'Afgana Púrpura', family: 'Índica pura', biomes: ['nieve'],
      origin: 'Valles de Afganistán', region: 'asia',
      story: 'Landrace índica de hoja ancha y flores púrpura por el frío nocturno.',
      profile: { colors: [{ key: 'purpura', w: 4 }, { key: 'violeta', w: 2 }], leaves: [{ key: 'ancha', w: 4 }], terps: [{ key: 'dulce', w: 3 }, { key: 'terroso', w: 2 }], quant: { altura: 42, produccion: 68, vigor: 60, resistencia: 75, velocidad: 68, resina: 82, aroma: 70 }, mutBoost: 1.8, ploidyBoost: 1.5 } },
    // ---------- RELIQUIAS ----------
    { id: 'SM-000', name: 'Cepa Primigenia', family: 'Landrace madre', biomes: ['pradera', 'bosque', 'pantano', 'desierto', 'nieve', 'volcan'],
      origin: 'Origen desconocido — ancestro de todas las cepas', region: 'reliquia',
      story: 'La landrace ancestral de la que, según la leyenda, descienden todas las demás.',
      profile: { colors: [{ key: 'oro', w: 4 }, { key: 'obsidiana', w: 2 }], leaves: [{ key: 'digitada', w: 3 }], terps: [{ key: 'incienso', w: 4 }], quant: { altura: 75, produccion: 82, vigor: 78, resistencia: 70, velocidad: 45, resina: 90, aroma: 92 }, mutBoost: 2.4, ploidyBoost: 2.2 }, relic: true },
    { id: 'SM-017', name: 'Semilla del Edén', family: 'Reliquia fósil', biomes: ['cueva', 'volcan', 'nieve'],
      origin: 'Fósil viviente — anterior a todo registro', region: 'reliquia',
      story: 'La cepa más antigua conocida. Se dice que guarda linajes landrace ya extinguidos.',
      profile: { colors: [{ key: 'obsidiana', w: 3 }, { key: 'oro', w: 3 }, { key: 'turquesa', w: 2 }], leaves: [{ key: 'reticulada', w: 3 }], terps: [{ key: 'incienso', w: 5 }], quant: { altura: 78, produccion: 85, vigor: 82, resistencia: 72, velocidad: 45, resina: 92, aroma: 94 }, mutBoost: 2.8, ploidyBoost: 2.6 }, relic: true },
  ];

  const SPECIES_BY_ID = Object.fromEntries(SPECIES.map(s => [s.id, s]));

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
      let w = s.relic ? 1 : 20;
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

  PH.species = { SPECIES, SPECIES_BY_ID, BIOMES, spawnTable, makeSpecimen, rollEncounter, envMultiplier };
})(window.PH = window.PH || {});

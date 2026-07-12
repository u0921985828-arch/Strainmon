/* ============================================================
   PHENO HUNTER — species.js
   Especies base, perfiles genéticos, biomas y tablas de aparición.
   ============================================================ */
(function (PH) {
  'use strict';
  const { RNG } = PH.util;
  const { wildGenotype, express, rarityScore, rarityTier, phenoSignature } = PH.gen;

  const SPECIES = [
    // ---------- PRADERA / BOSQUE / PANTANO ----------
    { id: 'PH-001', name: 'Musgolita', family: 'Briófita antigua', biomes: ['pradera', 'bosque'],
      origin: 'Praderas templadas del Valle Umbral',
      story: 'La primera variedad que todo aprendiz cataloga. Resistente y humilde.',
      profile: { colors: [{ key: 'verde', w: 5 }, { key: 'lima', w: 3 }], leaves: [{ key: 'ancha', w: 4 }, { key: 'serrada', w: 2 }], terps: [{ key: 'terroso', w: 3 }, { key: 'pino', w: 2 }], quant: { altura: 40, produccion: 45, vigor: 55, resistencia: 60, velocidad: 55, resina: 30, aroma: 40 } } },
    { id: 'PH-002', name: 'Solandra', family: 'Heliófita', biomes: ['pradera'],
      origin: 'Llanuras soleadas de Auralia',
      story: 'Gira sus flores siguiendo la luz. Aroma cítrico brillante.',
      profile: { colors: [{ key: 'oro', w: 2 }, { key: 'ambar', w: 4 }, { key: 'lima', w: 3 }], leaves: [{ key: 'palmada', w: 3 }], terps: [{ key: 'citrico', w: 5 }, { key: 'dulce', w: 2 }], quant: { altura: 55, produccion: 60, vigor: 60, resistencia: 45, velocidad: 60, resina: 45, aroma: 65 } } },
    { id: 'PH-003', name: 'Nébula', family: 'Umbrófita', biomes: ['bosque'],
      origin: 'Suelos sombríos del Bosque de Vael',
      story: 'Crece en penumbra; sus flores púrpura toman color con el frío.',
      profile: { colors: [{ key: 'purpura', w: 4 }, { key: 'violeta', w: 2 }, { key: 'verde', w: 2 }], leaves: [{ key: 'digitada', w: 3 }, { key: 'estrecha', w: 2 }], terps: [{ key: 'floral', w: 4 }, { key: 'dulce', w: 2 }], quant: { altura: 60, produccion: 55, vigor: 50, resistencia: 40, velocidad: 45, resina: 60, aroma: 60 } } },
    { id: 'PH-004', name: 'Ferralia', family: 'Xerófita', biomes: ['bosque', 'pantano'],
      origin: 'Cortezas ferrosas del Bosque de Vael',
      story: 'Sus tallos acumulan minerales; resistente como el hierro.',
      profile: { colors: [{ key: 'ambar', w: 3 }, { key: 'carmesi', w: 2 }, { key: 'verde', w: 2 }], leaves: [{ key: 'serrada', w: 3 }, { key: 'reticulada', w: 1 }], terps: [{ key: 'combustible', w: 3 }, { key: 'especiado', w: 2 }], quant: { altura: 50, produccion: 50, vigor: 55, resistencia: 80, velocidad: 35, resina: 55, aroma: 45 }, mutBoost: 1.4 } },
    { id: 'PH-005', name: 'Cienófaga', family: 'Higrófita', biomes: ['pantano'],
      origin: 'Turberas del Cenagal de Mureb',
      story: 'Prospera en el agua estancada; libera un vapor combustible.',
      profile: { colors: [{ key: 'lima', w: 3 }, { key: 'verde', w: 3 }, { key: 'azur', w: 1 }], leaves: [{ key: 'ancha', w: 4 }], terps: [{ key: 'combustible', w: 4 }, { key: 'terroso', w: 3 }], quant: { altura: 65, produccion: 70, vigor: 65, resistencia: 55, velocidad: 45, resina: 50, aroma: 55 } } },
    { id: 'PH-006', name: 'Brumaria', family: 'Nefelófita', biomes: ['pantano', 'bosque'],
      origin: 'Nieblas perpetuas de Mureb',
      story: 'Solo florece entre la niebla; sus pétalos parecen humo condensado.',
      profile: { colors: [{ key: 'azur', w: 3 }, { key: 'violeta', w: 2 }, { key: 'blanco', w: 1 }], leaves: [{ key: 'estrecha', w: 3 }, { key: 'reticulada', w: 2 }], terps: [{ key: 'mentolado', w: 3 }, { key: 'floral', w: 3 }], quant: { altura: 55, produccion: 50, vigor: 45, resistencia: 45, velocidad: 40, resina: 70, aroma: 70 }, mutBoost: 1.6, ploidyBoost: 1.5 } },
    // ---------- DESIERTO ----------
    { id: 'PH-008', name: 'Solárida', family: 'Suculenta', biomes: ['desierto'],
      origin: 'Dunas ardientes del Erg de Sael',
      story: 'Almacena agua en hojas gruesas; florece con el calor extremo.',
      profile: { colors: [{ key: 'ambar', w: 3 }, { key: 'oro', w: 2 }, { key: 'carmesi', w: 2 }], leaves: [{ key: 'aciculada', w: 3 }, { key: 'lobulada', w: 2 }], terps: [{ key: 'especiado', w: 3 }, { key: 'ahumado', w: 2 }], quant: { altura: 35, produccion: 45, vigor: 55, resistencia: 85, velocidad: 30, resina: 65, aroma: 50 }, mutBoost: 1.3 } },
    { id: 'PH-009', name: 'Duníscara', family: 'Psamófita', biomes: ['desierto'],
      origin: 'Arenas movedizas del Erg de Sael',
      story: 'Sus raíces recorren metros bajo la arena buscando humedad.',
      profile: { colors: [{ key: 'rosa', w: 3 }, { key: 'magenta', w: 2 }, { key: 'ambar', w: 2 }], leaves: [{ key: 'estrecha', w: 3 }], terps: [{ key: 'dulce', w: 3 }, { key: 'floral', w: 2 }], quant: { altura: 50, produccion: 55, vigor: 60, resistencia: 70, velocidad: 55, resina: 45, aroma: 60 } } },
    // ---------- NIEVE ----------
    { id: 'PH-010', name: 'Gélida', family: 'Criófita', biomes: ['nieve'],
      origin: 'Neveros eternos del Manto de Yrr',
      story: 'Genera un anticongelante natural; su resina cristaliza al aire.',
      profile: { colors: [{ key: 'azur', w: 3 }, { key: 'turquesa', w: 3 }, { key: 'blanco', w: 2 }], leaves: [{ key: 'aciculada', w: 3 }, { key: 'estrecha', w: 2 }], terps: [{ key: 'mentolado', w: 4 }, { key: 'marino', w: 2 }], quant: { altura: 45, produccion: 50, vigor: 50, resistencia: 75, velocidad: 40, resina: 80, aroma: 65 }, mutBoost: 1.7 } },
    { id: 'PH-011', name: 'Aurora', family: 'Fotófita', biomes: ['nieve'],
      origin: 'Bajo las luces boreales del Manto de Yrr',
      story: 'De noche, bajo la aurora, sus tejidos emiten un brillo tenue.',
      profile: { colors: [{ key: 'turquesa', w: 2 }, { key: 'violeta', w: 3 }, { key: 'magenta', w: 2 }], leaves: [{ key: 'digitada', w: 3 }], terps: [{ key: 'floral', w: 3 }, { key: 'incienso', w: 1 }], quant: { altura: 55, produccion: 55, vigor: 45, resistencia: 55, velocidad: 45, resina: 70, aroma: 75 }, mutBoost: 2.0, ploidyBoost: 1.6 } },
    // ---------- VOLCÁN ----------
    { id: 'PH-012', name: 'Ígnea', family: 'Pirófita', biomes: ['volcan'],
      origin: 'Laderas de ceniza del Monte Calder',
      story: 'Germina solo tras el fuego; su savia arde con aroma a azufre.',
      profile: { colors: [{ key: 'carmesi', w: 4 }, { key: 'oro', w: 2 }, { key: 'obsidiana', w: 1 }], leaves: [{ key: 'lobulada', w: 3 }, { key: 'serrada', w: 2 }], terps: [{ key: 'ahumado', w: 4 }, { key: 'combustible', w: 3 }], quant: { altura: 60, produccion: 65, vigor: 70, resistencia: 65, velocidad: 50, resina: 60, aroma: 70 }, mutBoost: 1.8, ploidyBoost: 1.4 } },
    { id: 'PH-013', name: 'Obsidiónida', family: 'Litófita', biomes: ['volcan'],
      origin: 'Grietas de obsidiana del Monte Calder',
      story: 'Rarísima flor negra que crece sobre roca volcánica vidriada.',
      profile: { colors: [{ key: 'obsidiana', w: 4 }, { key: 'violeta', w: 2 }], leaves: [{ key: 'reticulada', w: 2 }, { key: 'digitada', w: 2 }], terps: [{ key: 'incienso', w: 3 }, { key: 'especiado', w: 2 }], quant: { altura: 55, produccion: 60, vigor: 60, resistencia: 70, velocidad: 40, resina: 85, aroma: 80 }, mutBoost: 2.2, ploidyBoost: 2.0 } },
    // ---------- CUEVA ----------
    { id: 'PH-014', name: 'Fungália', family: 'Micótrofa', biomes: ['cueva'],
      origin: 'Galerías sin luz de la Cueva de Vael',
      story: 'Vive de la oscuridad y de hongos simbiontes; brilla en tinieblas.',
      profile: { colors: [{ key: 'turquesa', w: 2 }, { key: 'lima', w: 2 }, { key: 'blanco', w: 2 }], leaves: [{ key: 'reticulada', w: 3 }], terps: [{ key: 'terroso', w: 4 }, { key: 'mentolado', w: 1 }], quant: { altura: 35, produccion: 45, vigor: 55, resistencia: 50, velocidad: 40, resina: 60, aroma: 50 }, mutBoost: 2.4 } },
    // ---------- ISLA ----------
    { id: 'PH-015', name: 'Coralina', family: 'Halófita', biomes: ['isla'],
      origin: 'Arrecifes emergidos de las Islas Vireo',
      story: 'Tolera la sal marina; sus flores imitan pólipos de coral.',
      profile: { colors: [{ key: 'rosa', w: 2 }, { key: 'turquesa', w: 3 }, { key: 'magenta', w: 2 }], leaves: [{ key: 'palmada', w: 3 }], terps: [{ key: 'marino', w: 4 }, { key: 'floral', w: 2 }], quant: { altura: 50, produccion: 60, vigor: 60, resistencia: 60, velocidad: 55, resina: 55, aroma: 70 }, mutBoost: 1.5 } },
    // ---------- RELIQUIA ----------
    { id: 'PH-007', name: 'Aurífera', family: 'Reliquia', biomes: ['pradera', 'bosque', 'pantano', 'desierto', 'nieve', 'volcan'],
      origin: 'Desconocido — reliquia perdida',
      story: 'Variedad casi extinta. Sus flores doradas son leyenda entre cazadores.',
      profile: { colors: [{ key: 'oro', w: 5 }, { key: 'ambar', w: 2 }], leaves: [{ key: 'digitada', w: 3 }, { key: 'palmada', w: 2 }], terps: [{ key: 'incienso', w: 4 }, { key: 'especiado', w: 2 }], quant: { altura: 70, produccion: 80, vigor: 70, resistencia: 60, velocidad: 40, resina: 85, aroma: 85 }, mutBoost: 2.2, ploidyBoost: 2.0 }, relic: true },
    { id: 'PH-016', name: 'Cronólita', family: 'Reliquia', biomes: ['cueva', 'volcan', 'nieve'],
      origin: 'Fósil viviente — anterior a los registros del gremio',
      story: 'La más antigua conocida. Se dice que su genoma guarda variedades perdidas.',
      profile: { colors: [{ key: 'obsidiana', w: 3 }, { key: 'oro', w: 3 }, { key: 'turquesa', w: 2 }], leaves: [{ key: 'reticulada', w: 3 }], terps: [{ key: 'incienso', w: 5 }], quant: { altura: 75, produccion: 85, vigor: 80, resistencia: 70, velocidad: 45, resina: 90, aroma: 90 }, mutBoost: 2.8, ploidyBoost: 2.6 }, relic: true },
  ];

  const SPECIES_BY_ID = Object.fromEntries(SPECIES.map(s => [s.id, s]));

  const BIOMES = {
    pradera:  { name: 'Pradera de Auralia', baseEncounter: 0.14 },
    bosque:   { name: 'Bosque de Vael',     baseEncounter: 0.16 },
    pantano:  { name: 'Cenagal de Mureb',   baseEncounter: 0.18 },
    desierto: { name: 'Erg de Sael',        baseEncounter: 0.15 },
    nieve:    { name: 'Manto de Yrr',       baseEncounter: 0.16 },
    volcan:   { name: 'Monte Calder',       baseEncounter: 0.17 },
    cueva:    { name: 'Cueva de Vael',      baseEncounter: 0.20 },
    isla:     { name: 'Islas Vireo',        baseEncounter: 0.17 },
  };

  function envMultiplier(species, env) {
    let m = 1;
    if (env.weather === 'niebla' && species.id === 'PH-006') m *= 3;
    if (env.weather === 'lluvia' && species.biomes.includes('pantano')) m *= 1.5;
    if (env.night && (species.id === 'PH-003' || species.id === 'PH-011' || species.relic)) m *= 2;
    if (env.weather === 'tormenta' && species.mutBoost) m *= 1.4;
    if (env.season === 'invierno' && (species.id === 'PH-003' || species.biomes.includes('nieve'))) m *= 1.4;
    if (env.season === 'verano' && species.biomes.includes('desierto')) m *= 1.3;
    if ((env.heat || env.weather === 'ola_calor') && (species.id === 'PH-002' || species.biomes.includes('desierto') || species.biomes.includes('volcan'))) m *= 1.6;
    // Eventos raros globales
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
    return {
      uid: 'S' + (++uidc) + Date.now().toString(36).slice(-3),
      speciesId: species.id, name: species.name,
      genotype, pheno, rarity: score, tier: tier.key, signature: sig,
      form: opts.form || 'salvaje',
      quality: opts.quality != null ? opts.quality : 100,
      parents: opts.parents || null,
      caughtAt: opts.caughtAt || null,
      generation: opts.generation || 0,
      sequenced: opts.sequenced || false,
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

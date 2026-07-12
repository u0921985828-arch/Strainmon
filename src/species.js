/* ============================================================
   PHENO HUNTER — species.js
   Especies base, perfiles genéticos, biomas y tablas de aparición.
   ============================================================ */
(function (PH) {
  'use strict';
  const { RNG } = PH.util;
  const { wildGenotype, express, rarityScore, rarityTier, phenoSignature } = PH.gen;

  // Cada especie define un "arquetipo" con sesgos genéticos y lore.
  const SPECIES = [
    {
      id: 'PH-001', name: 'Musgolita', family: 'Briófita antigua',
      biomes: ['pradera', 'bosque'], origin: 'Praderas templadas del Valle Umbral',
      story: 'La primera variedad que todo aprendiz cataloga. Resistente y humilde.',
      profile: { colors: [{ key: 'verde', w: 5 }, { key: 'lima', w: 3 }], leaves: [{ key: 'ancha', w: 4 }, { key: 'serrada', w: 2 }], terps: [{ key: 'terroso', w: 3 }, { key: 'pino', w: 2 }], quant: { altura: 40, produccion: 45, vigor: 55, resistencia: 60, velocidad: 55, resina: 30 } },
    },
    {
      id: 'PH-002', name: 'Solandra', family: 'Heliófita',
      biomes: ['pradera'], origin: 'Llanuras soleadas de Auralia',
      story: 'Gira sus flores siguiendo la luz. Aroma cítrico brillante.',
      profile: { colors: [{ key: 'oro', w: 2 }, { key: 'ambar', w: 4 }, { key: 'lima', w: 3 }], leaves: [{ key: 'palmada', w: 3 }], terps: [{ key: 'citrico', w: 5 }, { key: 'dulce', w: 2 }], quant: { altura: 55, produccion: 60, vigor: 60, resistencia: 45, velocidad: 60, resina: 45 } },
    },
    {
      id: 'PH-003', name: 'Nébula', family: 'Umbrófita',
      biomes: ['bosque'], origin: 'Suelos sombríos del Bosque de Vael',
      story: 'Crece en penumbra; sus flores púrpura toman color con el frío.',
      profile: { colors: [{ key: 'purpura', w: 4 }, { key: 'violeta', w: 2 }, { key: 'verde', w: 2 }], leaves: [{ key: 'digitada', w: 3 }, { key: 'estrecha', w: 2 }], terps: [{ key: 'floral', w: 4 }, { key: 'dulce', w: 2 }], quant: { altura: 60, produccion: 55, vigor: 50, resistencia: 40, velocidad: 45, resina: 60 } },
    },
    {
      id: 'PH-004', name: 'Ferralia', family: 'Xerófita',
      biomes: ['bosque', 'pantano'], origin: 'Cortezas ferrosas del Bosque de Vael',
      story: 'Sus tallos acumulan minerales; resistente como el hierro.',
      profile: { colors: [{ key: 'ambar', w: 3 }, { key: 'carmesi', w: 2 }, { key: 'verde', w: 2 }], leaves: [{ key: 'serrada', w: 3 }, { key: 'reticulada', w: 1 }], terps: [{ key: 'combustible', w: 3 }, { key: 'especiado', w: 2 }], quant: { altura: 50, produccion: 50, vigor: 55, resistencia: 80, velocidad: 35, resina: 55 }, mutBoost: 1.4 },
    },
    {
      id: 'PH-005', name: 'Cienófaga', family: 'Higrófita',
      biomes: ['pantano'], origin: 'Turberas del Cenagal de Mureb',
      story: 'Prospera en el agua estancada; libera un vapor combustible.',
      profile: { colors: [{ key: 'lima', w: 3 }, { key: 'verde', w: 3 }, { key: 'azur', w: 1 }], leaves: [{ key: 'ancha', w: 4 }], terps: [{ key: 'combustible', w: 4 }, { key: 'terroso', w: 3 }], quant: { altura: 65, produccion: 70, vigor: 65, resistencia: 55, velocidad: 45, resina: 50 } },
    },
    {
      id: 'PH-006', name: 'Brumaria', family: 'Nefelófita',
      biomes: ['pantano', 'bosque'], origin: 'Nieblas perpetuas de Mureb',
      story: 'Solo florece entre la niebla; sus pétalos parecen humo condensado.',
      profile: { colors: [{ key: 'azur', w: 3 }, { key: 'violeta', w: 2 }, { key: 'blanco', w: 1 }], leaves: [{ key: 'estrecha', w: 3 }, { key: 'reticulada', w: 2 }], terps: [{ key: 'mentolado', w: 3 }, { key: 'floral', w: 3 }], quant: { altura: 55, produccion: 50, vigor: 45, resistencia: 45, velocidad: 40, resina: 70 }, mutBoost: 1.6, ploidyBoost: 1.5 },
    },
    {
      id: 'PH-007', name: 'Aurífera', family: 'Reliquia',
      biomes: ['pradera', 'bosque', 'pantano'], origin: 'Desconocido — reliquia perdida',
      story: 'Variedad casi extinta. Sus flores doradas son leyenda entre cazadores.',
      profile: { colors: [{ key: 'oro', w: 5 }, { key: 'ambar', w: 2 }], leaves: [{ key: 'digitada', w: 3 }, { key: 'palmada', w: 2 }], terps: [{ key: 'incienso', w: 4 }, { key: 'especiado', w: 2 }], quant: { altura: 70, produccion: 80, vigor: 70, resistencia: 60, velocidad: 40, resina: 85 }, mutBoost: 2.2, ploidyBoost: 2.0 },
      relic: true, minRarityBias: true,
    },
  ];

  const SPECIES_BY_ID = Object.fromEntries(SPECIES.map(s => [s.id, s]));

  /* ----- Definición de biomas y modificadores ambientales ----- */
  const BIOMES = {
    pradera: { name: 'Pradera de Auralia', baseEncounter: 0.14, tempPref: 'templado' },
    bosque:  { name: 'Bosque de Vael',    baseEncounter: 0.16, tempPref: 'fresco' },
    pantano: { name: 'Cenagal de Mureb',  baseEncounter: 0.18, tempPref: 'humedo' },
  };

  // Ambiente -> multiplicadores sobre especies concretas
  function envMultiplier(species, env) {
    let m = 1;
    // Niebla favorece Brumaria; noche favorece púrpuras/reliquias; lluvia favorece pantano
    if (env.weather === 'niebla' && species.id === 'PH-006') m *= 3;
    if (env.weather === 'lluvia' && species.biomes.includes('pantano')) m *= 1.5;
    if (env.night && (species.id === 'PH-003' || species.relic)) m *= 2;
    if (env.weather === 'tormenta' && species.mutBoost) m *= 1.4;
    if (env.season === 'invierno' && species.id === 'PH-003') m *= 1.4;
    if (env.heat && species.id === 'PH-002') m *= 1.6;
    return m;
  }

  // Construye la tabla de aparición de un bioma según ambiente
  function spawnTable(biome, env) {
    const list = SPECIES.filter(s => s.biomes.includes(biome));
    return list.map(s => {
      let w = s.relic ? 1 : 20;
      // reliquias mucho más raras
      w *= envMultiplier(s, env);
      return { ref: s, w };
    });
  }

  /* ----- Genera un espécimen salvaje concreto ----- */
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
      speciesId: species.id,
      name: species.name,
      genotype,
      pheno,
      rarity: score,
      tier: tier.key,
      signature: sig,
      // metadatos de captura
      form: opts.form || 'salvaje',      // semilla / esqueje / clon / cruce
      quality: opts.quality != null ? opts.quality : 100,
      parents: opts.parents || null,
      caughtAt: opts.caughtAt || null,   // {biome, weather, time}
      generation: opts.generation || 0,
      nickname: null,
    };
  }

  // Espécimen salvaje aleatorio para un encuentro
  function rollEncounter(biome, env) {
    const table = spawnTable(biome, env);
    const chosen = RNG.weighted(table, 'w').ref;
    return makeSpecimen(chosen, env, { form: 'salvaje', caughtAt: null });
  }

  PH.species = {
    SPECIES, SPECIES_BY_ID, BIOMES,
    spawnTable, makeSpecimen, rollEncounter, envMultiplier,
  };
})(window.PH = window.PH || {});

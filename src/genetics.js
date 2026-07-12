/* ============================================================
   PHENO HUNTER — genetics.js
   Motor genético diploide con dominancia, poligenes, mutaciones,
   poliploidía, patrones, secuencia de ADN y parentesco.
   Es el corazón del juego.
   ============================================================ */
(function (PH) {
  'use strict';
  const { RNG, clamp, hslToHex, cap } = PH.util;

  /* --------------------------------------------------------
     Definición de GENES
     -------------------------------------------------------- */

  // Color de flor — cualitativo. hue base para render.
  const COLORS = [
    { key: 'verde',    dom: 5, hue: 110, rarity: 1 },
    { key: 'lima',     dom: 4, hue: 85,  rarity: 2 },
    { key: 'ambar',    dom: 4, hue: 40,  rarity: 3 },
    { key: 'purpura',  dom: 6, hue: 280, rarity: 4 },
    { key: 'violeta',  dom: 6, hue: 300, rarity: 5 },
    { key: 'carmesi',  dom: 7, hue: 350, rarity: 6 },
    { key: 'azur',     dom: 7, hue: 205, rarity: 8 },
    { key: 'turquesa', dom: 6, hue: 175, rarity: 7 },
    { key: 'oro',      dom: 8, hue: 48,  rarity: 9 },
    { key: 'rosa',     dom: 3, hue: 330, rarity: 4 },
    { key: 'magenta',  dom: 7, hue: 320, rarity: 7 },
    { key: 'obsidiana',dom: 9, hue: 260, rarity: 11, dark: true },
    { key: 'blanco',   dom: 1, hue: 0,   rarity: 12, albino: true }, // recesivo -> albinismo
  ];
  const COLOR_BY_KEY = Object.fromEntries(COLORS.map(c => [c.key, c]));

  // Forma de hoja — cualitativo
  const LEAF = [
    { key: 'ancha',     dom: 5, rarity: 1 },
    { key: 'estrecha',  dom: 5, rarity: 1 },
    { key: 'serrada',   dom: 4, rarity: 2 },
    { key: 'palmada',   dom: 3, rarity: 3 },
    { key: 'digitada',  dom: 6, rarity: 4 },
    { key: 'lobulada',  dom: 4, rarity: 3 },
    { key: 'aciculada', dom: 5, rarity: 5 },
    { key: 'reticulada',dom: 2, rarity: 7 },
  ];

  // Terpeno dominante / aroma — cualitativo
  const TERP = [
    { key: 'citrico',    dom: 4, rarity: 1 },
    { key: 'pino',       dom: 4, rarity: 1 },
    { key: 'floral',     dom: 5, rarity: 2 },
    { key: 'terroso',    dom: 3, rarity: 2 },
    { key: 'combustible',dom: 6, rarity: 4 },
    { key: 'dulce',      dom: 4, rarity: 3 },
    { key: 'especiado',  dom: 5, rarity: 4 },
    { key: 'mentolado',  dom: 7, rarity: 6 },
    { key: 'ahumado',    dom: 6, rarity: 5 },
    { key: 'marino',     dom: 5, rarity: 5 },
    { key: 'incienso',   dom: 8, rarity: 9 },
  ];

  // Patrón de pigmentación — cualitativo, afecta al render de la flor
  const PATTERN = [
    { key: 'liso',      dom: 5, rarity: 1 },
    { key: 'moteado',   dom: 4, rarity: 3 },
    { key: 'rayado',    dom: 4, rarity: 4 },
    { key: 'jaspeado',  dom: 3, rarity: 5 },
    { key: 'aureolado', dom: 6, rarity: 7 },
  ];

  // Genes cuantitativos: cada alelo aporta un valor 0..100
  const QUANT = ['altura', 'produccion', 'vigor', 'resistencia', 'velocidad', 'resina', 'aroma'];

  // Mutaciones especiales (flags fenotípicos).
  const MUTATIONS = {
    variegacion:  { rarity: 8,  label: 'Variegación',     desc: 'Sectores sin clorofila; patrón jaspeado único.' },
    gigantismo:   { rarity: 9,  label: 'Gigantismo',      desc: 'Crecimiento descomunal; +altura +producción.' },
    enanismo:     { rarity: 7,  label: 'Enanismo',        desc: 'Porte minúsculo; densa y compacta.' },
    quimera:      { rarity: 11, label: 'Quimera',         desc: 'Dos genotipos coexistiendo en un cuerpo.' },
    fasciacion:   { rarity: 10, label: 'Fasciación',      desc: 'Tallos fusionados en forma de cresta.' },
    fluorescente: { rarity: 13, label: 'Bioluminiscencia',desc: 'Tejidos que brillan en la oscuridad.' },
    cristalina:   { rarity: 12, label: 'Cristalina',      desc: 'Resina hipertrófica; recubre la planta de escarcha.' },
    hexaploide:   { rarity: 14, label: 'Aura hexaploide', desc: 'Duplicación genómica extrema; vigor legendario.' },
  };

  const PLOIDY = {
    2: { label: 'Diploide',    yieldMul: 1.0,  sizeMul: 1.0,  rarity: 1 },
    3: { label: 'Triploide',   yieldMul: 1.25, sizeMul: 1.15, rarity: 8,  sterile: true },
    4: { label: 'Tetraploide', yieldMul: 1.45, sizeMul: 1.3,  rarity: 10 },
  };

  const QUAL_GENES = [
    { key: 'color', list: COLORS },
    { key: 'leaf', list: LEAF },
    { key: 'terp', list: TERP },
    { key: 'pattern', list: PATTERN },
  ];

  /* --------------------------------------------------------
     Construcción de un GENOTIPO
     -------------------------------------------------------- */
  function randAlleleFrom(list, biasCommon) {
    const arr = list.map(a => ({ ref: a, w: biasCommon ? 1 / a.rarity : 1 }));
    return RNG.weighted(arr, 'w').ref.key;
  }
  function wildQuant(base, spread) {
    return clamp(Math.round(base + RNG.gauss() * spread), 1, 100);
  }

  function wildGenotype(profile) {
    const g = { color: [], leaf: [], terp: [], pattern: [], quant: {}, ploidy: 2, mut: {} };
    for (let i = 0; i < 2; i++) g.color.push(pickProfile(profile.colors, COLORS));
    for (let i = 0; i < 2; i++) g.leaf.push(pickProfile(profile.leaves, LEAF));
    for (let i = 0; i < 2; i++) g.terp.push(pickProfile(profile.terps, TERP));
    for (let i = 0; i < 2; i++) g.pattern.push(pickProfile(profile.patterns, PATTERN));
    for (const q of QUANT) {
      const base = (profile.quant && profile.quant[q]) || 45;
      g.quant[q] = [wildQuant(base, 14), wildQuant(base, 14)];
    }
    maybeWildMutation(g, profile.mutBoost || 1);
    maybeWildPloidy(g, profile.ploidyBoost || 1);
    return g;
  }

  function pickProfile(pool, list) {
    if (pool && pool.length) {
      if (typeof pool[0] === 'string') return RNG.pick(pool);
      return RNG.weighted(pool, 'w').key;
    }
    return randAlleleFrom(list, true);
  }

  function globalMutBoost() {
    // Eventos activos y equipo de laboratorio pueden amplificar mutaciones.
    let b = 1;
    if (PH.events && PH.events.mutationBoost) b *= PH.events.mutationBoost();
    return b;
  }

  function maybeWildMutation(g, boost) {
    const gb = globalMutBoost();
    for (const [k, m] of Object.entries(MUTATIONS)) {
      const p = (0.5 / (m.rarity * m.rarity)) * boost * gb;
      if (RNG.chance(p)) g.mut[k] = true;
    }
  }
  function maybeWildPloidy(g, boost) {
    const gb = globalMutBoost();
    if (RNG.chance(0.01 * boost * gb)) g.ploidy = 4;
    else if (RNG.chance(0.02 * boost * gb)) g.ploidy = 3;
  }

  /* --------------------------------------------------------
     EXPRESIÓN — genotipo -> fenotipo observable
     -------------------------------------------------------- */
  function expressQual(alleles, list) {
    const A = list.find(x => x.key === alleles[0]) || list[0];
    const B = list.find(x => x.key === alleles[1]) || list[0];
    if (A.dom === B.dom && A.key !== B.key) return { expressed: A.key, hidden: B.key, co: B.key };
    const dom = A.dom >= B.dom ? A : B;
    const rec = A.dom >= B.dom ? B : A;
    return { expressed: dom.key, hidden: rec.key, co: null };
  }

  function express(genotype) {
    const p = PLOIDY[genotype.ploidy] || PLOIDY[2];
    const color = expressQual(genotype.color, COLORS);
    const leaf = expressQual(genotype.leaf, LEAF);
    const terp = expressQual(genotype.terp, TERP);
    const pattern = expressQual(genotype.pattern || ['liso', 'liso'], PATTERN);

    const q = {};
    for (const key of QUANT) {
      const a = genotype.quant[key] || [45, 45];
      q[key] = clamp(Math.round((a[0] + a[1]) / 2), 1, 100);
    }
    const mut = Object.keys(genotype.mut || {}).filter(k => genotype.mut[k]);
    if (genotype.mut.gigantismo) { q.altura = clamp(q.altura + 30, 1, 130); q.produccion = clamp(q.produccion + 20, 1, 130); }
    if (genotype.mut.enanismo)  { q.altura = clamp(Math.round(q.altura * 0.4), 1, 100); q.resina = clamp(q.resina + 15, 1, 100); }
    if (genotype.mut.cristalina) { q.resina = clamp(q.resina + 25, 1, 130); }
    if (genotype.mut.hexaploide) { q.vigor = clamp(q.vigor + 25, 1, 130); q.produccion = clamp(q.produccion + 25, 1, 150); }
    q.produccion = clamp(Math.round(q.produccion * p.yieldMul), 1, 150);
    q.altura = clamp(Math.round(q.altura * p.sizeMul), 1, 150);

    const colorInfo = COLOR_BY_KEY[color.expressed] || COLORS[0];

    return {
      color: color.expressed, colorHidden: color.hidden, colorCo: color.co,
      hue: colorInfo.hue, albino: colorInfo.albino || false, dark: colorInfo.dark || false,
      leaf: leaf.expressed, leafHidden: leaf.hidden,
      terp: terp.expressed, terpHidden: terp.hidden,
      pattern: pattern.expressed,
      quant: q, ploidy: genotype.ploidy, ploidyLabel: p.label, sterile: !!p.sterile,
      mutations: mut,
    };
  }

  /* --------------------------------------------------------
     RAREZA
     -------------------------------------------------------- */
  function rarityScore(genotype) {
    const ph = express(genotype);
    let score = 0;
    score += (COLOR_BY_KEY[ph.color]?.rarity || 1) * 1.4;
    if (ph.colorCo) score += 6;
    score += (LEAF.find(l => l.key === ph.leaf)?.rarity || 1);
    score += (TERP.find(t => t.key === ph.terp)?.rarity || 1) * 1.2;
    score += (PATTERN.find(t => t.key === ph.pattern)?.rarity || 1) * 1.1;
    for (const k of QUANT) {
      const v = ph.quant[k];
      if (v >= 95) score += 5; else if (v >= 88) score += 3; else if (v >= 80) score += 1.5;
      if (v <= 6) score += 2;
    }
    for (const m of ph.mutations) score += (MUTATIONS[m]?.rarity || 5) * 1.6;
    score += (PLOIDY[ph.ploidy]?.rarity || 1) * 1.2;
    return Math.round(clamp(score, 1, 100));
  }

  function rarityTier(score) {
    if (score >= 82) return { key: 'quimerica', label: 'Quimérica', color: '#ff3d7f', stars: 7 };
    if (score >= 70) return { key: 'mitica', label: 'Mítica', color: '#ff5da2', stars: 6 };
    if (score >= 55) return { key: 'legendaria', label: 'Legendaria', color: '#ffb02e', stars: 5 };
    if (score >= 40) return { key: 'rara', label: 'Rara', color: '#8a7dff', stars: 4 };
    if (score >= 28) return { key: 'inusual', label: 'Inusual', color: '#37c2ff', stars: 3 };
    if (score >= 16) return { key: 'comun', label: 'Común', color: '#7bd66b', stars: 2 };
    return { key: 'basica', label: 'Básica', color: '#a8b0b8', stars: 1 };
  }

  /* --------------------------------------------------------
     FIRMA fenotípica
     -------------------------------------------------------- */
  function phenoSignature(genotype) {
    const ph = express(genotype);
    const bucket = (v) => Math.round(v / 20);
    return [
      ph.color, ph.leaf, ph.terp, ph.pattern,
      'a' + bucket(ph.quant.altura),
      'p' + bucket(ph.quant.produccion),
      'r' + bucket(ph.quant.resina),
      ph.ploidy,
      ph.mutations.slice().sort().join('+') || '-'
    ].join('|');
  }

  /* --------------------------------------------------------
     ADN — cadena legible derivada del genotipo (para investigación)
     -------------------------------------------------------- */
  const BASES = ['A', 'T', 'C', 'G'];
  function alleleCodon(list, key) {
    const idx = Math.max(0, list.findIndex(x => x.key === key));
    // 3 bases codificando el índice en base 4
    return BASES[(idx) % 4] + BASES[(idx >> 2) % 4] + BASES[(idx >> 4) % 4];
  }
  function dnaSequence(genotype) {
    let seq = '';
    for (const g of QUAL_GENES) {
      const list = g.list;
      const al = genotype[g.key] || [list[0].key, list[0].key];
      seq += alleleCodon(list, al[0]) + alleleCodon(list, al[1]);
    }
    for (const q of QUANT) {
      const a = genotype.quant[q] || [45, 45];
      for (const v of a) {
        const n = Math.round(v / 25); // 0..4
        seq += BASES[n % 4] + BASES[(n >> 2) % 4];
      }
    }
    // marcador de ploidía y mutaciones
    seq += 'GG'.repeat(genotype.ploidy - 1);
    for (const k of Object.keys(MUTATIONS)) if (genotype.mut[k]) seq += 'CATG';
    return seq;
  }

  // Parentesco 0..1 comparando alelos compartidos
  function relatedness(gA, gB) {
    let match = 0, total = 0;
    for (const g of QUAL_GENES) {
      const a = gA[g.key] || [], b = gB[g.key] || [];
      total += 2;
      const bb = b.slice();
      for (const x of a) { const i = bb.indexOf(x); if (i >= 0) { match++; bb.splice(i, 1); } }
    }
    for (const q of QUANT) {
      total += 1;
      const va = gA.quant[q] || [45, 45], vb = gB.quant[q] || [45, 45];
      const d = Math.abs((va[0] + va[1]) / 2 - (vb[0] + vb[1]) / 2);
      match += clamp(1 - d / 60, 0, 1);
    }
    return clamp(match / total, 0, 1);
  }

  /* --------------------------------------------------------
     CRUCE / BREEDING
     -------------------------------------------------------- */
  function inheritQual(pA, pB) { return [RNG.pick(pA), RNG.pick(pB)]; }

  function breed(genoA, genoB, opts) {
    opts = opts || {};
    const mutRate = (opts.mutRate != null ? opts.mutRate : 0.06) * globalMutBoost();
    const child = { color: [], leaf: [], terp: [], pattern: [], quant: {}, ploidy: 2, mut: {} };

    child.color = inheritQual(genoA.color, genoB.color);
    child.leaf = inheritQual(genoA.leaf, genoB.leaf);
    child.terp = inheritQual(genoA.terp, genoB.terp);
    child.pattern = inheritQual(genoA.pattern || ['liso', 'liso'], genoB.pattern || ['liso', 'liso']);

    for (const q of QUANT) {
      const a = RNG.pick(genoA.quant[q] || [45, 45]);
      const b = RNG.pick(genoB.quant[q] || [45, 45]);
      child.quant[q] = [clamp(Math.round(a + RNG.gauss() * 6), 1, 100), clamp(Math.round(b + RNG.gauss() * 6), 1, 100)];
    }

    const pa = genoA.ploidy, pb = genoB.ploidy;
    child.ploidy = 2;
    if (RNG.chance(0.02)) child.ploidy = 4;
    else if ((pa >= 3 || pb >= 3) && RNG.chance(0.25)) child.ploidy = RNG.chance(0.5) ? 3 : 4;

    for (const k of Object.keys(MUTATIONS)) {
      const parents = (genoA.mut[k] ? 1 : 0) + (genoB.mut[k] ? 1 : 0);
      if (parents === 2 && RNG.chance(0.6)) child.mut[k] = true;
      else if (parents === 1 && RNG.chance(0.3)) child.mut[k] = true;
    }
    for (const [k, m] of Object.entries(MUTATIONS)) {
      const p = (mutRate / m.rarity) * (opts.mutBoost || 1);
      if (RNG.chance(p)) child.mut[k] = true;
    }
    if (RNG.chance(mutRate * 0.5)) {
      const idx = RNG.i(0, 1);
      child.color[idx] = RNG.weighted(COLORS.map(c => ({ ref: c, w: 1 / c.rarity })), 'w').ref.key;
    }
    return child;
  }

  /* --------------------------------------------------------
     Presentación
     -------------------------------------------------------- */
  function paletteFor(pheno) {
    let hue = pheno.hue;
    let sat = pheno.albino ? 6 : 62;
    let lig = pheno.albino ? 88 : (pheno.dark ? 26 : 48);
    if (pheno.mutations.includes('fluorescente')) { sat = 90; lig = 62; }
    if (pheno.mutations.includes('cristalina')) { lig = Math.min(80, lig + 14); }
    const base = hslToHex(hue, sat, lig);
    const dark = hslToHex(hue, sat, Math.max(10, lig - 22));
    const light = hslToHex(hue, sat, Math.min(96, lig + 22));
    const leafC = pheno.albino ? '#e8e2c8' : hslToHex(120, pheno.mutations.includes('variegacion') ? 24 : 46, 34);
    return { base, dark, light, leaf: leafC };
  }

  function describe(pheno) {
    const bits = [];
    bits.push(`Flor ${pheno.color}${pheno.colorCo ? '/' + pheno.colorCo : ''}`);
    if (pheno.pattern && pheno.pattern !== 'liso') bits.push(`patrón ${pheno.pattern}`);
    bits.push(`hoja ${pheno.leaf}`);
    bits.push(`aroma ${pheno.terp}`);
    if (pheno.ploidy !== 2) bits.push(pheno.ploidyLabel.toLowerCase());
    for (const m of pheno.mutations) bits.push(MUTATIONS[m].label.toLowerCase());
    return cap(bits.join(', ')) + '.';
  }

  PH.gen = {
    COLORS, LEAF, TERP, PATTERN, QUANT, MUTATIONS, PLOIDY, COLOR_BY_KEY, QUAL_GENES,
    wildGenotype, express, rarityScore, rarityTier, phenoSignature,
    breed, paletteFor, describe, dnaSequence, relatedness,
  };
})(window.PH = window.PH || {});

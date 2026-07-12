/* ============================================================
   PHENO HUNTER — research.js
   Investigación de ADN: secuenciación (revela alelos ocultos),
   comparación/parentesco y árbol filogenético del banco.
   ============================================================ */
(function (PH) {
  'use strict';
  const { cap } = PH.util;

  // Secuenciar un espécimen: marca sequenced y revela alelos recesivos ocultos.
  function sequence(spec) {
    spec.sequenced = true;
    const g = spec.genotype;
    const ph = spec.pheno;
    const hidden = [];
    for (const gene of PH.gen.QUAL_GENES) {
      const alleles = g[gene.key] || [];
      if (alleles[0] !== alleles[1]) {
        // hay heterocigosis: reporta el recesivo oculto
        const list = gene.list;
        const A = list.find(x => x.key === alleles[0]);
        const B = list.find(x => x.key === alleles[1]);
        const rec = (A.dom <= B.dom ? A : B).key;
        const dom = (A.dom > B.dom ? A : B).key;
        if (rec !== dom) hidden.push({ gene: gene.key, hidden: rec, expressed: dom });
      }
    }
    return { seq: PH.gen.dnaSequence(g), hidden };
  }

  // Compara dos especímenes -> parentesco y diferencias
  function compare(a, b) {
    const rel = PH.gen.relatedness(a.genotype, b.genotype);
    const relation = rel > 0.85 ? 'clones/idénticos' : rel > 0.6 ? 'parientes cercanos' : rel > 0.35 ? 'parientes lejanos' : 'no emparentados';
    return { rel: Math.round(rel * 100), relation };
  }

  // Construye un árbol de linaje a partir de `parents` en el banco.
  function lineage(spec, bankIndex) {
    function node(s, depth) {
      if (!s || depth > 4) return null;
      const n = { name: s.nickname || s.name, tier: s.tier, gen: s.generation, children: [] };
      if (s.parents) {
        for (const pid of s.parents) {
          const p = bankIndex[pid];
          const child = node(p, depth + 1);
          if (child) n.children.push(child);
        }
      }
      return n;
    }
    return node(spec, 0);
  }

  // Agrupa el catálogo por especie -> ramas filogenéticas simples
  function phylogeny(catalog) {
    const bySpecies = {};
    for (const e of Object.values(catalog)) {
      (bySpecies[e.speciesId] = bySpecies[e.speciesId] || []).push(e);
    }
    return bySpecies;
  }

  PH.research = { sequence, compare, lineage, phylogeny };
})(window.PH = window.PH || {});

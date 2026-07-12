/* ============================================================
   PHENO HUNTER — encounter.js
   Resolución de recolección: éxito, calidad y forma obtenida.
   ============================================================ */
(function (PH) {
  'use strict';
  const { RNG, clamp } = PH.util;
  const { TOOLS, toolQuality } = PH.items;

  // Intenta recolectar `wild` con la herramienta `toolId`.
  // Devuelve { success, specimen?, form, quality, msg }
  function harvest(wild, toolId) {
    const s = PH.state.get();
    const tool = TOOLS[toolId];
    if (!tool) return { success: false, msg: 'Herramienta no válida.' };

    // Modificadores de equipo
    const hasStab = s.player.gear.includes('estabilizador');
    const qualityBonus = hasStab ? 8 : 0;

    // Probabilidad de éxito baja con la rareza (rarezas se resisten)
    let successP = tool.success - (wild.rarity / 300);
    successP = clamp(successP, 0.15, 0.98);
    const ok = RNG.chance(successP);

    if (!ok) {
      return { success: false, form: tool.form, msg: `La ${wild.name} se resistió. No obtuviste ${tool.form}.` };
    }

    const quality = toolQuality(tool, qualityBonus);
    // El polen no crea un espécimen completo: crea material de cruce (guardamos como espécimen "polen")
    const form = tool.form;

    // Construye el espécimen recolectado. Copia el genotipo salvaje.
    const spec = PH.species.makeSpecimen(
      PH.species.SPECIES_BY_ID[wild.speciesId],
      s.env,
      {
        genotype: JSON.parse(JSON.stringify(wild.genotype)),
        form, quality,
        caughtAt: { biome: mapBiome(), weather: s.env.weather, time: PH.state.timeLabel(s.env) },
        generation: 0,
      }
    );
    // conserva firma/rareza del salvaje (mismo genotipo => misma firma)
    spec.signature = wild.signature;
    spec.rarity = wild.rarity;
    spec.tier = wild.tier;

    return { success: true, specimen: spec, form, quality, msg: `¡Obtuviste ${form} de ${wild.name}! (calidad ${quality})` };
  }

  function mapBiome() {
    const s = PH.state.get();
    const map = PH.world.MAPS[s.player.map];
    return map ? map.biome : null;
  }

  // Probabilidad de encuentro al pisar hierba alta
  function encounterChance(biome) {
    const s = PH.state.get();
    const b = PH.species.BIOMES[biome];
    let p = b ? b.baseEncounter : 0.12;
    if (s.player.cebosActivos > 0) p += 0.05;
    if (PH.events && PH.events.encounterBoost) p *= PH.events.encounterBoost();
    return Math.min(0.6, p);
  }

  PH.encounter = { harvest, encounterChance };
})(window.PH = window.PH || {});

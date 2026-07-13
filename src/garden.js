/* ============================================================
   PHENO HUNTER — garden.js
   Invernadero / cultivo: planta clones y semillas, obsérvalos crecer
   por fases (plántula → veg → floración → cosecha) y cosecha para
   propagar la genética. Usa los sprites de cultivo (sprites.js).
   ============================================================ */
(function (PH) {
  'use strict';
  const { RNG, clamp } = PH.util;
  const G = () => PH.state.get();

  // Umbrales acumulados (ms reales) por fase. Ciclo completo ~130s base.
  const STAGE_TIMES = [0, 25000, 55000, 90000, 130000];
  const FINAL = STAGE_TIMES.length - 1;

  function capacity() {
    const s = G();
    return clamp(3 + Math.floor(s.player.prestige / 40), 3, 8);
  }

  function growRate(plant) {
    // velocidad y vigor aceleran; floración global también
    let r = 1 + ((plant.pheno.quant.velocidad || 50) - 50) / 120;
    if (PH.events && PH.events.current() && PH.events.current().id === 'floracion') r *= 1.6;
    return clamp(r, 0.5, 2.2);
  }

  function stageOf(growMs) {
    let idx = 0;
    for (let i = 0; i < STAGE_TIMES.length; i++) if (growMs >= STAGE_TIMES[i]) idx = i;
    return idx;
  }

  function plantFromBank(uid) {
    const s = G();
    if (!s.garden) s.garden = [];
    if (s.garden.length >= capacity()) return { ok: false, msg: 'No hay parcelas libres en el invernadero.' };
    const sp = PH.state.bankGet(uid);
    if (!sp) return { ok: false, msg: 'Muestra no encontrada.' };
    if (sp.form === 'polen') return { ok: false, msg: 'El polen no se planta; úsalo en cruces.' };
    PH.state.bankRemove(uid);
    const plant = {
      id: 'G' + Date.now().toString(36) + RNG.i(100, 999),
      name: sp.nickname || sp.name, speciesId: sp.speciesId,
      genotype: sp.genotype, pheno: sp.pheno, rarity: sp.rarity, tier: sp.tier,
      quality: sp.quality, generation: sp.generation, form: sp.form,
      growMs: 0, stage: 0, ready: false,
      seedSprite: RNG.pick(PH.sprites.SEEDLING_VARIANTS),
      vegSprite: RNG.pick(PH.sprites.VEG_VARIANTS),
    };
    s.garden.push(plant);
    return { ok: true, plant, msg: `Plantaste ${plant.name} en el invernadero.` };
  }

  function update(dt) {
    const s = G();
    if (!s.garden || !s.garden.length) return;
    for (const p of s.garden) {
      if (p.ready) continue;
      p.growMs += dt * growRate(p);
      p.stage = stageOf(p.growMs);
      if (p.growMs >= STAGE_TIMES[FINAL]) { p.ready = true; p.stage = FINAL; }
    }
  }

  // Sprite de la fase actual: arte real por cepa (fase 1..5). Fallback a sprites.
  function spriteKey(p) {
    const k = PH.plantart && PH.plantart.stageKey(p.speciesId, (p.stage || 0) + 1);
    return k || (PH.sprites ? PH.sprites.LIFECYCLE[Math.min(p.stage, 4)].sprite : null);
  }
  function spriteUri(p) {
    const k = PH.plantart && PH.plantart.stageKey(p.speciesId, (p.stage || 0) + 1);
    if (k) return PH.plantart.uri(k);
    return PH.sprites ? PH.sprites.uri(spriteKey(p)) : null;
  }

  function progressPct(p) {
    const total = STAGE_TIMES[FINAL];
    return clamp((p.growMs / total) * 100, 0, 100);
  }

  function regar(id) {
    const s = G();
    const p = (s.garden || []).find(x => x.id === id);
    if (!p || p.ready) return false;
    p.growMs += 9000; // riego: acelera el cultivo
    p.stage = stageOf(p.growMs);
    if (p.growMs >= STAGE_TIMES[FINAL]) { p.ready = true; p.stage = FINAL; }
    return true;
  }

  function harvest(id) {
    const s = G();
    const i = (s.garden || []).findIndex(x => x.id === id);
    if (i < 0) return { ok: false };
    const p = s.garden[i];
    if (!p.ready) return { ok: false, msg: 'Aún no está lista para cosechar.' };
    s.garden.splice(i, 1);

    // Rendimiento: nº de clones propagados según producción y ploidía
    const ploid = p.pheno.ploidy || 2;
    let clones = 1 + Math.floor((p.pheno.quant.produccion || 50) / 30) + (ploid > 2 ? 1 : 0);
    if (p.pheno.mutations.includes('gigantismo')) clones += 1;
    clones = clamp(clones, 1, 6);

    const made = [];
    for (let k = 0; k < clones; k++) {
      const spec = PH.species.makeSpecimen(PH.species.SPECIES_BY_ID[p.speciesId], s.env, {
        genotype: JSON.parse(JSON.stringify(p.genotype)),
        form: 'clon', quality: clamp((p.quality || 80) + RNG.i(-3, 5), 5, 100),
        generation: p.generation, caughtAt: { biome: 'invernadero', weather: '-', time: PH.state.timeLabel(s.env) },
      });
      PH.state.bankAdd(spec);
      made.push(spec);
    }
    // Crédito por cosecha según resina/producción/rareza
    const credits = Math.round(40 + (p.pheno.quant.resina || 40) * 1.4 + (p.pheno.quant.produccion || 40) * 1.2 + p.rarity * 3);
    PH.state.addCredits(credits);
    s.stats.harvests = (s.stats.harvests || 0) + 1;
    PH.state.addPrestige(2);
    return { ok: true, clones: made, credits, name: p.name };
  }

  function compost(id) {
    const s = G();
    const i = (s.garden || []).findIndex(x => x.id === id);
    if (i >= 0) s.garden.splice(i, 1);
  }

  PH.garden = { STAGE_TIMES, capacity, update, plantFromBank, spriteKey, spriteUri, progressPct, regar, harvest, compost, stageOf };
})(window.PH = window.PH || {});

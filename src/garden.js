/* ============================================================
   PHENO HUNTER — garden.js
   Invernadero / cultivo: planta clones y semillas, obsérvalos crecer
   por fases (plántula → veg → floración → cosecha) y cosecha para
   propagar la genética. Usa los sprites de cultivo (sprites.js).

   FASE 3 — estrés de cultivo: el agua se consume con el tiempo; sin
   agua la planta se estresa y detiene su crecimiento. La humedad alta
   (riego excesivo, eventos de bruma/niebla) puede provocar la aparición
   de moho/patógenos, que se resuelven con manejo BIOLÓGICO limpio y no
   tóxico (poda sanitaria + control de humedad), nunca con fungicidas
   agresivos. La salud final modula el rendimiento de la cosecha.
   ============================================================ */
(function (PH) {
  'use strict';
  const { RNG, clamp } = PH.util;
  const G = () => PH.state.get();

  // Umbrales acumulados (ms reales) por fase. Ciclo completo ~130s base.
  const STAGE_TIMES = [0, 25000, 55000, 90000, 130000];
  const FINAL = STAGE_TIMES.length - 1;

  // Modelo hídrico/sanitario (Fase 3).
  const WATER_MAX = 100;
  const WATER_DECAY = 100 / 42000;   // se seca por completo en ~42 s reales
  const WATER_FULL = 96;             // nivel tras regar
  const THIRST = 22;                 // por debajo: estrés hídrico
  const SOGGY = 88;                  // por encima: encharcamiento (favorece hongos)
  const HEALTH_MAX = 100;
  const DRY_DMG = 100 / 60000;       // seca sin agua: pierde salud en ~60 s
  const MOLD_DMG = 100 / 45000;      // infectada: pierde salud en ~45 s
  const HEALTH_REGEN = 100 / 80000;  // en buenas condiciones se recupera lento

  function capacity() {
    const s = G();
    return clamp(3 + Math.floor(s.player.prestige / 40), 3, 8);
  }

  function growRate(plant) {
    // velocidad y vigor aceleran; floración global también
    let r = 1 + ((plant.pheno.quant.velocidad || 50) - 50) / 120;
    if (PH.events && PH.events.current() && PH.events.current().id === 'floracion') r *= 1.6;
    // el estrés hídrico frena el desarrollo; la enfermedad también
    if (plant.water < THIRST) r *= 0.15;
    else if (plant.water < THIRST * 1.8) r *= 0.6;
    if (plant.diseased) r *= 0.4;
    if (plant.health < 40) r *= 0.7;
    return clamp(r, 0.06, 2.2);
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
    // resistencia al moho: rasgo cualitativo/mutación reduce el riesgo
    let resist = 0.5 + (((sp.pheno && sp.pheno.quant && sp.pheno.quant.resistencia) || 50) - 50) / 120;
    if (sp.pheno && sp.pheno.mutations && sp.pheno.mutations.includes('resina_blindada')) resist += 0.35;
    const plant = {
      id: 'G' + Date.now().toString(36) + RNG.i(100, 999),
      name: sp.nickname || sp.name, speciesId: sp.speciesId,
      genotype: sp.genotype, pheno: sp.pheno, rarity: sp.rarity, tier: sp.tier,
      quality: sp.quality, generation: sp.generation, form: sp.form,
      growMs: 0, stage: 0, ready: false,
      water: 78, health: HEALTH_MAX, diseased: false, moldResist: clamp(resist, 0.35, 1.6),
      seedSprite: RNG.pick(PH.sprites.SEEDLING_VARIANTS),
      vegSprite: RNG.pick(PH.sprites.VEG_VARIANTS),
    };
    s.garden.push(plant);
    return { ok: true, plant, msg: `Plantaste ${plant.name} en el invernadero.` };
  }

  // Presión ambiental de humedad: bruma/niebla y floración húmeda suben el riesgo.
  function humidityPressure() {
    let h = 1;
    const ev = PH.events && PH.events.current();
    if (ev) {
      if (ev.id === 'bruma_astral') h = 2.4;
      else if (ev.id === 'floracion') h = 1.5;
    }
    return h;
  }

  function update(dt) {
    const s = G();
    if (!s.garden || !s.garden.length) return;
    const hum = humidityPressure();
    for (const p of s.garden) {
      // compat. con partidas antiguas sin campos de Fase 3
      if (p.water == null) p.water = 78;
      if (p.health == null) p.health = HEALTH_MAX;
      if (p.diseased == null) p.diseased = false;
      if (p.moldResist == null) p.moldResist = 1;

      // 1) consumo de agua (crecer da sed; el calor de floración seca más)
      p.water = clamp(p.water - dt * WATER_DECAY * (0.8 + growRate(p) * 0.4), 0, WATER_MAX);

      // 2) salud según condiciones
      if (p.diseased) {
        p.health = clamp(p.health - dt * MOLD_DMG, 0, HEALTH_MAX);
      } else if (p.water < 4) {
        p.health = clamp(p.health - dt * DRY_DMG, 0, HEALTH_MAX);
      } else if (p.water >= THIRST && p.water <= SOGGY) {
        p.health = clamp(p.health + dt * HEALTH_REGEN, 0, HEALTH_MAX);
      }

      // 3) aparición de moho/patógenos: encharcamiento + humedad ambiental
      if (!p.diseased && !p.ready && p.stage >= 1) {
        let risk = 0;
        if (p.water > SOGGY) risk += (p.water - SOGGY) / 12; // exceso de riego
        risk *= hum / p.moldResist;
        // prob. por segundo → por dt
        if (RNG.f() < risk * (dt / 1000) * 0.06) {
          p.diseased = true;
          if (PH.ui && PH.ui.toast) PH.ui.toast(`🍄 ${p.name} muestra moho. Trátala (poda + ventilación).`, 'warn');
          if (PH.audio) PH.audio.sfx('error');
        }
      }

      // 4) avance del cultivo (modulado por growRate → estrés y enfermedad frenan)
      if (p.ready) continue;
      p.growMs += dt * growRate(p);
      p.stage = stageOf(p.growMs);
      if (p.growMs >= STAGE_TIMES[FINAL]) { p.ready = true; p.stage = FINAL; }
    }
  }

  // Estado sanitario legible para la UI.
  function statusOf(p) {
    if (p.ready) return { key: 'ready', label: 'Lista', tone: 'ok' };
    if (p.diseased) return { key: 'mold', label: 'Moho', tone: 'bad' };
    if ((p.water != null ? p.water : 78) < THIRST) return { key: 'thirsty', label: 'Sed', tone: 'warn' };
    if ((p.water != null ? p.water : 78) > SOGGY) return { key: 'soggy', label: 'Encharcada', tone: 'warn' };
    if ((p.health != null ? p.health : 100) < 45) return { key: 'weak', label: 'Débil', tone: 'warn' };
    return { key: 'healthy', label: 'Sana', tone: 'ok' };
  }
  function waterPct(p) { return clamp(p.water != null ? p.water : 78, 0, 100); }
  function healthPct(p) { return clamp(p.health != null ? p.health : 100, 0, 100); }

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

  // Riego: repone agua. El exceso encharca (riesgo de hongos), no acelera.
  function regar(id) {
    const s = G();
    const p = (s.garden || []).find(x => x.id === id);
    if (!p) return false;
    p.water = WATER_FULL;
    return true;
  }

  // Tratamiento biológico limpio (Fase 3): poda sanitaria + ventilación.
  // Cura el moho sin químicos agresivos; baja la humedad de la maceta y
  // deja algo de estrés (leve pérdida de salud) por la poda.
  function treat(id) {
    const s = G();
    const p = (s.garden || []).find(x => x.id === id);
    if (!p) return { ok: false };
    if (!p.diseased) return { ok: false, msg: 'La planta no necesita tratamiento.' };
    p.diseased = false;
    p.water = clamp(p.water - 22, 0, WATER_MAX); // ventilar seca el sustrato
    p.health = clamp(p.health - 6, 0, HEALTH_MAX); // la poda estresa un poco
    p.moldResist = clamp(p.moldResist + 0.08, 0.35, 1.8); // sanidad reforzada
    return { ok: true, msg: `Trataste ${p.name}: poda sanitaria y ventilación. Moho eliminado.` };
  }

  function harvest(id) {
    const s = G();
    const i = (s.garden || []).findIndex(x => x.id === id);
    if (i < 0) return { ok: false };
    const p = s.garden[i];
    if (!p.ready) return { ok: false, msg: 'Aún no está lista para cosechar.' };
    s.garden.splice(i, 1);

    // Factor de salud: una planta descuidada rinde menos y de peor calidad.
    const hf = clamp((p.health != null ? p.health : 100) / 100, 0.25, 1);

    // Rendimiento: nº de clones propagados según producción, ploidía y salud
    const ploid = p.pheno.ploidy || 2;
    let clones = 1 + Math.floor(((p.pheno.quant.produccion || 50) * hf) / 30) + (ploid > 2 ? 1 : 0);
    if (p.pheno.mutations.includes('gigantismo')) clones += 1;
    if (hf < 0.4) clones = Math.min(clones, 1);
    clones = clamp(clones, 1, 6);

    const made = [];
    for (let k = 0; k < clones; k++) {
      const spec = PH.species.makeSpecimen(PH.species.SPECIES_BY_ID[p.speciesId], s.env, {
        genotype: JSON.parse(JSON.stringify(p.genotype)),
        form: 'clon', quality: clamp(Math.round((p.quality || 80) * (0.6 + hf * 0.4)) + RNG.i(-3, 5), 5, 100),
        generation: p.generation, caughtAt: { biome: 'invernadero', weather: '-', time: PH.state.timeLabel(s.env) },
      });
      PH.state.bankAdd(spec);
      made.push(spec);
    }
    // Crédito por cosecha según resina/producción/rareza, modulado por salud
    const credits = Math.round((40 + (p.pheno.quant.resina || 40) * 1.4 + (p.pheno.quant.produccion || 40) * 1.2 + p.rarity * 3) * (0.5 + hf * 0.5));
    PH.state.addCredits(credits);
    s.stats.harvests = (s.stats.harvests || 0) + 1;
    if (hf >= 0.9) s.stats.perfectHarvests = (s.stats.perfectHarvests || 0) + 1;
    PH.state.addPrestige(2);
    return { ok: true, clones: made, credits, name: p.name, health: Math.round(hf * 100) };
  }

  function compost(id) {
    const s = G();
    const i = (s.garden || []).findIndex(x => x.id === id);
    if (i >= 0) s.garden.splice(i, 1);
  }

  PH.garden = {
    STAGE_TIMES, capacity, update, plantFromBank, spriteKey, spriteUri, progressPct,
    regar, treat, harvest, compost, stageOf, statusOf, waterPct, healthPct,
  };
})(window.PH = window.PH || {});

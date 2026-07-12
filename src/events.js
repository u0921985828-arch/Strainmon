/* ============================================================
   PHENO HUNTER — events.js
   Eventos raros temporizados que alteran apariciones y mutaciones.
   Algunos se anuncian y duran pocos minutos reales.
   ============================================================ */
(function (PH) {
  'use strict';
  const { RNG } = PH.util;

  // Definición de eventos. effect: modificadores globales mientras dura.
  const EVENTS = {
    eclipse: {
      id: 'eclipse', name: 'Eclipse', icon: '🌑',
      desc: 'La luz se apaga. Las variedades de sombra y las reliquias emergen.',
      duration: 90000, mutMul: 1.4,
      spawn: (sp) => (sp.relic || sp.id === 'PH-003' || sp.id === 'PH-011') ? 3 : 1,
      tint: 'rgba(20,10,40,0.5)',
    },
    meteoros: {
      id: 'meteoros', name: 'Lluvia de meteoros', icon: '☄️',
      desc: 'Radiación cósmica: la tasa de mutaciones se dispara.',
      duration: 75000, mutMul: 3.0,
      spawn: (sp) => sp.mutBoost ? 1.5 : 1,
      tint: 'rgba(40,20,60,0.25)', particles: 'meteor',
    },
    floracion: {
      id: 'floracion', name: 'Floración masiva', icon: '🌸',
      desc: 'Todo florece a la vez. Encuentros mucho más frecuentes.',
      duration: 120000, mutMul: 1.1, encMul: 2.2,
      spawn: () => 1, tint: 'rgba(255,150,200,0.10)', particles: 'petal',
    },
    tormenta_e: {
      id: 'tormenta_e', name: 'Tormenta eléctrica', icon: '⚡',
      desc: 'Descargas que inducen poliploidía y anomalías raras.',
      duration: 80000, mutMul: 2.2, ploidyMul: 3,
      spawn: (sp) => sp.mutBoost ? 1.4 : 1, tint: 'rgba(120,140,255,0.12)',
    },
    bruma_astral: {
      id: 'bruma_astral', name: 'Bruma astral', icon: '🌌',
      desc: 'Una niebla luminiscente favorece fenotipos bioluminiscentes.',
      duration: 90000, mutMul: 1.8,
      spawn: (sp) => sp.id === 'PH-006' ? 2.5 : 1, tint: 'rgba(80,120,180,0.22)', particles: 'spark',
    },
  };

  const active = { ev: null, remaining: 0 };
  let cooldown = 45000; // primer evento algo tardío

  function update(dt) {
    if (active.ev) {
      active.remaining -= dt;
      if (active.remaining <= 0) {
        const ended = active.ev;
        active.ev = null; active.remaining = 0;
        cooldown = RNG.i(60000, 150000);
        if (PH.ui && PH.ui.toast) PH.ui.toast(`${ended.icon} El evento «${ended.name}» ha terminado.`, '');
      }
      return;
    }
    cooldown -= dt;
    if (cooldown <= 0) trigger();
  }

  function trigger(forceId) {
    const keys = Object.keys(EVENTS);
    const id = forceId || RNG.pick(keys);
    const ev = EVENTS[id];
    active.ev = ev; active.remaining = ev.duration;
    if (PH.ui && PH.ui.toast) PH.ui.toast(`${ev.icon} ¡EVENTO RARO! «${ev.name}» — ${ev.desc}`, 'ok');
  }

  function current() { return active.ev; }
  function remaining() { return Math.max(0, Math.round(active.remaining / 1000)); }

  // Hooks consumidos por genetics/species
  function mutationBoost() { return active.ev ? (active.ev.mutMul || 1) : 1; }
  function spawnMultiplier(species) { return active.ev && active.ev.spawn ? active.ev.spawn(species) : 1; }
  function encounterBoost() { return active.ev ? (active.ev.encMul || 1) : 1; }
  function tint() { return active.ev ? active.ev.tint : null; }
  function particles() { return active.ev ? active.ev.particles : null; }

  PH.events = {
    EVENTS, update, trigger, current, remaining,
    mutationBoost, spawnMultiplier, encounterBoost, tint, particles,
  };
})(window.PH = window.PH || {});

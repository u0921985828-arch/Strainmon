/* ============================================================
   STRAINMON — heat.js
   FASE 4 — presión policial ("heat", estilo GTA-lite). Trapichear en
   la calle sube el nivel de búsqueda (0..5 estrellas). Con suficiente
   heat aparecen patrullas que te persiguen por la calle; si te pillan,
   pagas una multa y te confiscan género. El heat se enfría solo con el
   tiempo, y basta con meterte en un interior para despistar a la poli.
   Estado en s.player.heat para persistir en el guardado.
   ============================================================ */
(function (PH) {
  'use strict';
  const { clamp } = PH.util;
  const G = () => PH.state.get();

  const MAX = 100;
  const DECAY = 100 / 90000;   // se enfría por completo en ~90 s reales
  const COP_THRESHOLD = 55;    // a partir de aquí patrullan
  let lastLevel = 0;

  function heat() { const p = G().player; if (p.heat == null) p.heat = 0; return p.heat; }
  function set(v) { G().player.heat = clamp(v, 0, MAX); }
  function level() { return clamp(Math.floor(heat() / 20), 0, 5); } // 0..5 estrellas
  function copsActive() { return heat() >= COP_THRESHOLD; }

  function add(n) {
    const before = level();
    set(heat() + n);
    const lv = level();
    if (lv > before && PH.ui && PH.ui.toast) {
      PH.ui.toast(`🚨 Nivel de búsqueda ${'★'.repeat(lv)} — baja el perfil.`, 'warn');
      if (PH.audio) PH.audio.sfx('error');
    }
    lastLevel = lv;
  }
  function cool(n) { set(heat() - n); lastLevel = level(); }

  function update(dt) {
    if (heat() > 0) { set(heat() - dt * DECAY); lastLevel = level(); }
  }

  PH.heat = { MAX, COP_THRESHOLD, heat, add, cool, set, level, copsActive, update };
})(window.PH = window.PH || {});

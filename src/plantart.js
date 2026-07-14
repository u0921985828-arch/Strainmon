/* ============================================================
   STRAINMON — plantart.js  (compat / API de arte por fase)
   El roster oficial son las 100 cepas de linaje cerrado: sus RETRATOS
   viven en strainart.js (128²) y el crecimiento en invernadero usa los
   sprites genéricos de sprites.js (plant_1..8). Este módulo mantiene la
   API histórica (stageKey/portrait/uri/img/has) por compatibilidad;
   DATA queda vacío y las llamadas devuelven null -> fallback limpio.
   ============================================================ */
(function (PH) {
  'use strict';
  const DATA = {};
  const images = {};
  function preload() { for (const k of Object.keys(DATA)) { const im = new Image(); im.src = DATA[k]; images[k] = im; } }
  function img(k) { return images[k] || null; }
  function uri(k) { return DATA[k] || null; }
  function has(id) { return !!DATA[id + '_5']; }
  function stageKey(id, s) { s = Math.max(1, Math.min(5, s | 0)); return DATA[id + '_' + s] ? id + '_' + s : null; }
  function portrait(id) { return (PH.strainart && PH.strainart.has(id)) ? id : stageKey(id, 5); }
  PH.plantart = { DATA, preload, img, uri, has, stageKey, portrait };
})(window.PH = window.PH || {});

/* ============================================================
   PHENO HUNTER — util.js
   Núcleo de utilidades: RNG, matemáticas, helpers de color.
   ============================================================ */
(function (PH) {
  'use strict';

  // ---- RNG con semilla (mulberry32) para generación reproducible ----
  function mulberry32(seed) {
    let a = seed >>> 0;
    return function () {
      a |= 0; a = (a + 0x6D2B79F5) | 0;
      let t = Math.imul(a ^ (a >>> 15), 1 | a);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }

  // RNG global del juego (no sembrado -> usa Math.random para el mundo vivo)
  const RNG = {
    // número flotante [0,1)
    f: () => Math.random(),
    // entero [min,max] inclusivo
    i: (min, max) => Math.floor(Math.random() * (max - min + 1)) + min,
    // rango flotante
    r: (min, max) => min + Math.random() * (max - min),
    // probabilidad p (0..1)
    chance: (p) => Math.random() < p,
    // elemento aleatorio de un array
    pick: (arr) => arr[Math.floor(Math.random() * arr.length)],
    // elección ponderada: [{w, ...}] devuelve el objeto
    weighted: (arr, wkey) => {
      let total = 0;
      for (const it of arr) total += (wkey ? it[wkey] : it.w) || 0;
      let roll = Math.random() * total;
      for (const it of arr) {
        roll -= (wkey ? it[wkey] : it.w) || 0;
        if (roll <= 0) return it;
      }
      return arr[arr.length - 1];
    },
    // baraja Fisher-Yates (in place)
    shuffle: (arr) => {
      for (let i = arr.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [arr[i], arr[j]] = [arr[j], arr[i]];
      }
      return arr;
    },
    // gaussiana aproximada, media 0, desv 1
    gauss: () => {
      let u = 0, v = 0;
      while (u === 0) u = Math.random();
      while (v === 0) v = Math.random();
      return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v);
    }
  };

  const clamp = (v, a, b) => v < a ? a : (v > b ? b : v);
  const lerp = (a, b, t) => a + (b - a) * t;

  // ---- Color helpers ----
  function hsl(h, s, l) { return `hsl(${h},${s}%,${l}%)`; }
  function hslToHex(h, s, l) {
    s /= 100; l /= 100;
    const k = (n) => (n + h / 30) % 12;
    const a = s * Math.min(l, 1 - l);
    const f = (n) => {
      const c = l - a * Math.max(-1, Math.min(k(n) - 3, Math.min(9 - k(n), 1)));
      return Math.round(255 * c).toString(16).padStart(2, '0');
    };
    return `#${f(0)}${f(8)}${f(4)}`;
  }
  function shade(hex, amt) {
    // amt: -1..1  oscurece/aclara
    const n = parseInt(hex.replace('#', ''), 16);
    let r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255;
    const t = amt < 0 ? 0 : 255;
    const p = Math.abs(amt);
    r = Math.round((t - r) * p) + r;
    g = Math.round((t - g) * p) + g;
    b = Math.round((t - b) * p) + b;
    return `#${((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1)}`;
  }

  // Formato: 12345 -> "12.3k"
  function fmt(n) {
    if (n < 1000) return '' + n;
    if (n < 1e6) return (n / 1000).toFixed(n < 1e4 ? 1 : 0) + 'k';
    return (n / 1e6).toFixed(1) + 'M';
  }

  function id() { return 'g' + (id._c = (id._c || 0) + 1) + '_' + Math.floor(Math.random() * 1e6).toString(36); }

  // capitaliza
  const cap = (s) => s ? s.charAt(0).toUpperCase() + s.slice(1) : s;

  PH.util = { mulberry32, RNG, clamp, lerp, hsl, hslToHex, shade, fmt, id, cap };
})(window.PH = window.PH || {});

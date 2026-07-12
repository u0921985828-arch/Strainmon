/* ============================================================
   PHENO HUNTER — items.js
   Herramientas de recolección, mochila y tienda.
   ============================================================ */
(function (PH) {
  'use strict';

  // Herramientas de recolección. Cada una obtiene una "forma" con calidad.
  const TOOLS = {
    frasco: {
      id: 'frasco', name: 'Frasco de semillas', form: 'semilla',
      success: 0.72, quality: 0.55, price: 0, tier: 1,
      desc: 'Recolecta semillas. Barato y fiable, pero baja fidelidad genética.',
    },
    tijeras: {
      id: 'tijeras', name: 'Tijeras de esqueje', form: 'esqueje',
      success: 0.62, quality: 0.75, price: 350, tier: 2,
      desc: 'Corta un esqueje que conserva bien la genética del ejemplar.',
    },
    kitclon: {
      id: 'kitclon', name: 'Kit de clonación', form: 'clon',
      success: 0.55, quality: 0.92, price: 1500, tier: 3,
      desc: 'Clon de altísima fidelidad: preserva casi intacto el genotipo.',
    },
    dron: {
      id: 'dron', name: 'Dron recolector', form: 'clon',
      success: 0.8, quality: 0.97, price: 6000, tier: 4,
      desc: 'Recolección asistida: máxima tasa de éxito y fidelidad.',
    },
    polen: {
      id: 'polen', name: 'Cepillo de polen', form: 'polen',
      success: 0.85, quality: 0.6, price: 200, tier: 1,
      desc: 'Recoge polen para cruces. No captura la planta entera.',
    },
  };

  // Consumibles / equipo que modifica probabilidades
  const GEAR = {
    lupa:     { id: 'lupa', name: 'Lupa de campo', price: 500, desc: 'Revela la rareza estimada antes de recolectar.' },
    medidor:  { id: 'medidor', name: 'Medidor ambiental', price: 800, desc: 'Muestra clima, estación y su efecto en las apariciones.' },
    cebo:     { id: 'cebo', name: 'Feromona floral', price: 120, desc: 'Aumenta la probabilidad de encuentros raros un rato.', consumable: true },
    estabilizador: { id: 'estabilizador', name: 'Estabilizador genético', price: 2500, desc: 'Reduce pérdida de calidad al recolectar.', passive: true },
  };

  function toolQuality(tool, playerBonus) {
    // calidad final 0..100 con algo de suerte
    const { RNG, clamp } = PH.util;
    const base = tool.quality * 100;
    const luck = RNG.gauss() * 8;
    return Math.round(clamp(base + luck + (playerBonus || 0), 5, 100));
  }

  PH.items = { TOOLS, GEAR, toolQuality };
})(window.PH = window.PH || {});

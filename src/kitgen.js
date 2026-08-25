/* ============================================================
   STRAINMON — kitgen.js
   Compositor de sprites por piezas. Lee los atlas generados por
   scripts/pack-kit.mjs (PH.kitdata[<kit>]) y monta un sprite final a partir
   de una "receta": qué pieza va en cada ranura, en qué dirección y con qué
   tinte. Todo en canvas, sin dependencias, pixel-perfect (sin suavizado).

   Receta:
     { dir: 'south-east',
       parts: { body: 'hoodie', head: 'round', hair: { part: 'crop' },
                floor: { part: 'brick', repeat: 3 } },
       tints: { cloth: 'azul', skin: { h: -4, s: 1, l: .95 } } }
   ============================================================ */
(function (PH) {
  'use strict';

  const images = {};          // kitId -> HTMLImageElement del atlas
  const loading = {};         // kitId -> Promise

  const data = (id) => (PH.kitdata || {})[id] || null;
  const list = () => Object.keys(PH.kitdata || {});

  /** Carga (una vez) la imagen del atlas de un kit. */
  function ready(id) {
    if (loading[id]) return loading[id];
    const d = data(id);
    if (!d) return Promise.reject(new Error('kit desconocido: ' + id));
    loading[id] = new Promise((res, rej) => {
      const im = new Image();
      im.onload = () => { images[id] = im; res(im); };
      im.onerror = () => rej(new Error('no se pudo cargar el atlas de ' + id));
      im.src = d.png || (d.atlas && d.atlas.file) || '';
    });
    return loading[id];
  }

  // ---- color: desplazamiento HSL por píxel (sin difuminar el pixel art) ----
  function rgb2hsl(r, g, b) {
    r /= 255; g /= 255; b /= 255;
    const mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2;
    if (mx === mn) return [0, 0, l];
    const d = mx - mn;
    const s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn);
    let h;
    if (mx === r) h = ((g - b) / d + (g < b ? 6 : 0));
    else if (mx === g) h = (b - r) / d + 2;
    else h = (r - g) / d + 4;
    return [h * 60, s, l];
  }
  function hue2rgb(p, q, t) {
    if (t < 0) t += 1; if (t > 1) t -= 1;
    if (t < 1 / 6) return p + (q - p) * 6 * t;
    if (t < 1 / 2) return q;
    if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
    return p;
  }
  function hsl2rgb(h, s, l) {
    h = ((h % 360) + 360) % 360 / 360;
    if (s === 0) { const v = Math.round(l * 255); return [v, v, v]; }
    const q = l < 0.5 ? l * (1 + s) : l + s - l * s, p = 2 * l - q;
    return [
      Math.round(hue2rgb(p, q, h + 1 / 3) * 255),
      Math.round(hue2rgb(p, q, h) * 255),
      Math.round(hue2rgb(p, q, h - 1 / 3) * 255),
    ];
  }

  const clamp01 = (v) => v < 0 ? 0 : v > 1 ? 1 : v;

  /** Aplica un tinte {h,s,l} a un ImageData (in place). */
  function tintPixels(img, t) {
    const dh = t.h || 0, ms = t.s == null ? 1 : t.s, ml = t.l == null ? 1 : t.l;
    if (!dh && ms === 1 && ml === 1) return img;
    const p = img.data;
    for (let i = 0; i < p.length; i += 4) {
      if (p[i + 3] === 0) continue;
      const [h, s, l] = rgb2hsl(p[i], p[i + 1], p[i + 2]);
      const [r, g, b] = hsl2rgb(h + dh, clamp01(s * ms), clamp01(l * ml));
      p[i] = r; p[i + 1] = g; p[i + 2] = b;
    }
    return img;
  }

  function resolveTint(d, group, value) {
    if (!value) return null;
    if (typeof value === 'object') return value;
    const set = (d.tints || {})[group] || [];
    return set.find(t => t.id === value) || null;
  }

  function anchorOffset(anchor, w, h) {
    switch (anchor || 'bottom-center') {
      case 'center': return [w / 2, h / 2];
      case 'top-center': return [w / 2, 0];
      case 'top-left': return [0, 0];
      case 'bottom-left': return [0, h];
      case 'bottom-right': return [w, h];
      default: return [w / 2, h];
    }
  }

  const newCanvas = (w, h) => {
    const c = document.createElement('canvas');
    c.width = w; c.height = h;
    const x = c.getContext('2d');
    x.imageSmoothingEnabled = false;
    return c;
  };

  /** Busca el fotograma de una pieza; si falta esa dirección, usa la primera que exista. */
  function frameFor(d, slotId, partId, dir) {
    const code = d.dirCode[dir];
    const direct = d.frames[`${slotId}__${partId}__${code}`];
    if (direct) return { f: direct, dir };
    for (const alt of d.directions) {
      const f = d.frames[`${slotId}__${partId}__${d.dirCode[alt]}`];
      if (f) return { f, dir: alt };
    }
    return null;
  }

  const partEntry = (v) => (typeof v === 'string' ? { part: v } : (v || {}));

  /** Cuántas veces se dibuja una ranura repetible (0 si no está en la receta). */
  function repeatCount(slot, raw) {
    const entry = partEntry(raw);
    if (!entry.part) return 0;
    if (!slot.repeat) return 1;
    const lo = slot.repeat.min || 0, hi = slot.repeat.max || 1;
    return Math.max(lo, Math.min(hi, entry.repeat == null ? 1 : entry.repeat));
  }

  /**
   * Compone una receta y devuelve un canvas nuevo.
   * opts: { scale = 1, canvas } — scale entero para mantener el pixel-perfect.
   */
  function compose(id, recipe, opts) {
    opts = opts || {};
    const d = data(id);
    if (!d) throw new Error('kit desconocido: ' + id);
    const atlas = images[id];
    if (!atlas) throw new Error('atlas no cargado; llama antes a PH.kitgen.ready("' + id + '")');
    const dir = recipe.dir || d.directions[0];
    const scale = Math.max(1, Math.round(opts.scale || 1));
    const out = opts.canvas || newCanvas(d.canvas.width * scale, d.canvas.height * scale);
    const ctx = out.getContext('2d');
    ctx.imageSmoothingEnabled = false;
    ctx.clearRect(0, 0, out.width, out.height);

    const slots = d.slots.slice().sort((a, b) => (a.z || 0) - (b.z || 0));

    // Desplazamiento acumulado de las ranuras repetibles: lo que se apila
    // encima (p. ej. el remate de un edificio) sube tantos pasos como pisos.
    const shift = {};
    for (const s of slots) {
      if (!s.repeat) continue;
      const n = repeatCount(s, (recipe.parts || {})[s.id]);
      shift[s.id] = [n * (s.repeat.stepX || 0), n * (s.repeat.stepY || 0)];
    }

    for (const slot of slots) {
      const entry = partEntry((recipe.parts || {})[slot.id]);
      if (!entry.part) continue;
      if (slot.dirs && slot.dirs.indexOf(dir) < 0) continue;
      const meta = slot.parts.find(p => p.id === entry.part);
      if (!meta) continue;
      const hit = frameFor(d, slot.id, entry.part, dir);
      if (!hit) continue;
      const f = hit.f;

      // capa recortada (con tinte si toca)
      let layer = newCanvas(f.w, f.h);
      const lc = layer.getContext('2d');
      lc.imageSmoothingEnabled = false;
      lc.drawImage(atlas, f.x, f.y, f.w, f.h, 0, 0, f.w, f.h);
      const tint = resolveTint(d, slot.tint, (recipe.tints || {})[slot.tint]);
      if (tint) {
        const px = lc.getImageData(0, 0, f.w, f.h);
        lc.putImageData(tintPixels(px, tint), 0, 0);
      }
      // espejado horizontal si la dirección real no es la pedida y son simétricas
      if (hit.dir !== dir && opts.mirrorFallback !== false && isMirror(hit.dir, dir)) {
        const m = newCanvas(f.w, f.h);
        const mc = m.getContext('2d');
        mc.imageSmoothingEnabled = false;
        mc.translate(f.w, 0); mc.scale(-1, 1);
        mc.drawImage(layer, 0, 0);
        layer = m;
      }

      const [ax, ay] = anchorOffset(slot.anchor, f.w, f.h);
      const nudge = (meta.dirNudge && meta.dirNudge[d.dirCode[dir]]) || meta.nudge || [0, 0];
      const st = (slot.stackAfter && shift[slot.stackAfter]) || [0, 0];
      const baseX = slot.place[0] - ax + nudge[0] + st[0];
      const baseY = slot.place[1] - ay + nudge[1] + st[1];

      const rep = repeatCount(slot, entry) || (slot.repeat ? 0 : 1);
      for (let i = 0; i < rep; i++) {
        const y = baseY + (slot.repeat ? i * (slot.repeat.stepY || 0) : 0);
        const x = baseX + (slot.repeat ? i * (slot.repeat.stepX || 0) : 0);
        ctx.drawImage(layer, 0, 0, f.w, f.h,
          Math.round(x) * scale, Math.round(y) * scale, f.w * scale, f.h * scale);
      }
    }
    return out;
  }

  const MIRROR = { 'south-east': 'south-west', 'south-west': 'south-east', 'north-east': 'north-west', 'north-west': 'north-east', 'east': 'west', 'west': 'east' };
  const isMirror = (a, b) => MIRROR[a] === b;

  // ---- aleatorio reproducible ----
  function lcg(seed) {
    let s = (seed >>> 0) || 1;
    return () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; };
  }

  /** Receta aleatoria válida. opts: { dir, optionalChance = .6, tint = true } */
  function randomRecipe(id, seed, opts) {
    opts = opts || {};
    const d = data(id);
    if (!d) throw new Error('kit desconocido: ' + id);
    const rnd = lcg(seed == null ? Math.floor(Math.random() * 1e9) : seed);
    const pick = (arr) => arr[Math.floor(rnd() * arr.length) % arr.length];
    const recipe = { dir: opts.dir || pick(d.directions), parts: {}, tints: {}, seed: seed };
    for (const slot of d.slots) {
      if (!slot.parts.length) continue;
      if (slot.optional && rnd() > (opts.optionalChance == null ? 0.6 : opts.optionalChance)) continue;
      const entry = { part: pick(slot.parts).id };
      if (slot.repeat) {
        const lo = slot.repeat.min || 0, hi = slot.repeat.max || 1;
        entry.repeat = lo + Math.floor(rnd() * (hi - lo + 1));
      }
      recipe.parts[slot.id] = entry;
    }
    if (opts.tint !== false) {
      for (const g of Object.keys(d.tints || {})) {
        const set = d.tints[g];
        if (set && set.length) recipe.tints[g] = pick(set).id;
      }
    }
    return recipe;
  }

  /** Receta con la primera pieza de cada ranura obligatoria (base para editar). */
  function defaultRecipe(id, dir) {
    const d = data(id);
    const recipe = { dir: dir || d.directions[0], parts: {}, tints: {} };
    for (const slot of d.slots) {
      if (slot.optional || !slot.parts.length) continue;
      recipe.parts[slot.id] = { part: slot.parts[0].id, repeat: slot.repeat ? (slot.repeat.min || 1) : undefined };
    }
    for (const g of Object.keys(d.tints || {})) recipe.tints[g] = (d.tints[g][0] || {}).id;
    return recipe;
  }

  /** Todas las direcciones de una receta, una tras otra (hoja de sprites). */
  function sheet(id, recipe, opts) {
    const d = data(id);
    const dirs = (opts && opts.dirs) || d.directions;
    const scale = Math.max(1, Math.round((opts && opts.scale) || 1));
    const w = d.canvas.width * scale, h = d.canvas.height * scale;
    const out = newCanvas(w * dirs.length, h);
    const ctx = out.getContext('2d');
    ctx.imageSmoothingEnabled = false;
    dirs.forEach((dir, i) => {
      const c = compose(id, Object.assign({}, recipe, { dir }), { scale });
      ctx.drawImage(c, i * w, 0);
    });
    return out;
  }

  const dataURL = (id, recipe, opts) => compose(id, recipe, opts).toDataURL('image/png');

  PH.kitgen = { data, list, ready, compose, sheet, dataURL, randomRecipe, defaultRecipe, tintPixels, anchorOffset };
})(window.PH = window.PH || {});

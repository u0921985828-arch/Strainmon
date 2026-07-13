/* ============================================================
   PHENO HUNTER — ui.js
   Capa de interfaz: HUD, notificaciones y paneles superpuestos
   (diálogo, mochila, banco, catálogo, laboratorio, mercado,
   encuentro y menú). Los paneles pausan el mundo.
   ============================================================ */
(function (PH) {
  'use strict';
  const { fmt, cap } = PH.util;
  const G = () => PH.state.get();

  let overlay, hud, toastBox;

  function init() {
    overlay = document.getElementById('overlay');
    hud = document.getElementById('hud');
    toastBox = document.getElementById('toasts');
  }

  /* ---------------- Notificaciones ---------------- */
  function toast(msg, kind) {
    const el = document.createElement('div');
    el.className = 'toast ' + (kind || '');
    el.innerHTML = msg;
    toastBox.appendChild(el);
    setTimeout(() => { el.classList.add('show'); }, 10);
    setTimeout(() => { el.classList.remove('show'); setTimeout(() => el.remove(), 400); }, 3200);
  }

  /* ---------------- HUD ---------------- */
  function updateHUD() {
    const s = G();
    const env = s.env;
    // En modo iso, el nombre de sala manda; si no, el mapa top-down.
    const isoName = PH.game && PH.game.roomName ? PH.game.roomName() : '';
    const map = isoName ? { name: isoName } : (PH.world.MAPS && PH.world.MAPS[s.player.map]);
    const wIcon = { despejado: '☀️', lluvia: '🌧️', niebla: '🌫️', tormenta: '⛈️', ola_calor: '🔥', nublado: '☁️' }[env.weather] || '☀️';
    const ev = PH.events && PH.events.current();
    const evPill = ev ? `<span class="pill event">${ev.icon} ${ev.name} · ${PH.events.remaining()}s</span>` : '';
    hud.innerHTML = `
      <div class="hud-left">
        <span class="pill">📍 ${map ? map.name : ''}</span>
        <span class="pill">🕑 ${PH.state.timeLabel(env)} ${env.night ? '🌙' : '☀️'}</span>
        <span class="pill">${wIcon} ${cap(env.weather.replace('_', ' '))}</span>
        <span class="pill">🍂 ${cap(env.season)}</span>
        ${evPill}
      </div>
      <div class="hud-right">
        ${PH.heat && PH.heat.level() > 0 ? `<span class="pill heat">🚨 ${'★'.repeat(PH.heat.level())}</span>` : ''}
        <span class="pill">🏅 ${s.player.prestige}</span>
        <span class="pill">💰 ${fmt(s.player.credits)}</span>
        <span class="pill">🌿 ${Object.keys(s.catalog).length}</span>
      </div>`;
  }

  /* ---------------- Utilidades de paneles ---------------- */
  function open(html, cls) {
    overlay.className = 'active ' + (cls || '');
    overlay.innerHTML = html;
    PH.game.mode = 'menu';
  }
  function close() {
    overlay.className = '';
    overlay.innerHTML = '';
    PH.game.mode = 'overworld';
  }
  function isOpen() { return overlay.className.indexOf('active') >= 0; }

  // Dibuja una planta en un <canvas> por id tras insertar el HTML
  // Acepta un espécimen {pheno,speciesId,form} o un pheno suelto.
  function paintPlant(canvasId, specOrPheno, scale) {
    const c = document.getElementById(canvasId);
    if (!c) return;
    const ctx = c.getContext('2d');
    ctx.imageSmoothingEnabled = false;
    const spec = specOrPheno && specOrPheno.pheno ? specOrPheno : null;
    const pheno = spec ? spec.pheno : specOrPheno;
    const speciesId = spec ? spec.speciesId : null;
    // Retrato de cepa (fase 5). Híbridos (cruce) usan procedural.
    const key = speciesId && spec.form !== 'cruce' && PH.plantart ? PH.plantart.portrait(speciesId) : null;
    const im = key && PH.plantart.img(key);
    const drawProc = () => { ctx.clearRect(0, 0, c.width, c.height); PH.render.drawPlant(ctx, c.width / 2, c.height - 8, pheno, scale || 2, performance.now()); };
    const drawImg = () => {
      const pad = 3, aw = c.width - pad * 2, ah = c.height - pad * 2;
      const r = Math.min(aw / im.naturalWidth, ah / im.naturalHeight);
      const w = Math.round(im.naturalWidth * r), h = Math.round(im.naturalHeight * r);
      ctx.clearRect(0, 0, c.width, c.height);
      ctx.drawImage(im, (c.width - w) / 2, c.height - h - 2, w, h);
    };
    if (im && im.complete && im.naturalWidth) drawImg();
    else if (im) { drawProc(); im.addEventListener('load', drawImg, { once: true }); }
    else drawProc();
  }

  /* ---------------- Ficha de espécimen (HTML) ---------------- */
  function statBar(label, v, max) {
    max = max || 100;
    const pct = Math.min(100, (v / max) * 100);
    return `<div class="stat"><span>${label}</span><div class="bar"><i style="width:${pct}%"></i></div><b>${v}</b></div>`;
  }
  function tierBadge(spec) {
    const t = PH.gen.rarityTier(spec.rarity);
    return `<span class="tier" style="--tc:${t.color}">${'★'.repeat(t.stars)} ${t.label}</span>`;
  }
  function lineageBadge(spec) {
    if (spec.landrace) return `<span class="landrace">🌍 Landrace pura</span>`;
    if (spec.form === 'cruce') return `<span class="hybrid">🧬 Híbrido F${spec.generation || 1}</span>`;
    return '';
  }
  function specimenCard(spec, opts) {
    opts = opts || {};
    const ph = spec.pheno;
    const cid = 'pc_' + spec.uid;
    const muts = ph.mutations.map(m => `<span class="mut">${PH.gen.MUTATIONS[m].label}</span>`).join('');
    return `
      <div class="spec-card">
        <div class="spec-art"><canvas id="${cid}" width="90" height="110"></canvas></div>
        <div class="spec-info">
          <div class="spec-title">${spec.nickname || spec.name} <small>${spec.speciesId}</small></div>
          ${tierBadge(spec)} ${lineageBadge(spec)}
          <div class="spec-desc">${PH.gen.describe(ph)}</div>
          <div class="spec-meta">Forma: <b>${cap(spec.form)}</b> · Calidad: <b>${spec.quality}</b>${spec.generation ? ' · Gen ' + spec.generation : ''} · Pureza: <b>${spec.purity != null ? spec.purity : 100}%</b></div>
          <div class="spec-stats">
            ${statBar('Altura', ph.quant.altura, 150)}
            ${statBar('Producción', ph.quant.produccion, 150)}
            ${statBar('Vigor', ph.quant.vigor)}
            ${statBar('Resina', ph.quant.resina)}
            ${statBar('Resist.', ph.quant.resistencia)}
          </div>
          ${muts ? '<div class="muts">' + muts + '</div>' : ''}
          ${ph.sterile ? '<div class="warn">⚠ Estéril (no apta para cruce)</div>' : ''}
        </div>
      </div>`;
  }

  /* ---------------- DIÁLOGO ---------------- */
  let dlgPages = [], dlgIndex = 0, dlgAfter = null, dlgMeta = null;
  function dialog(pages, after, meta) {
    dlgPages = pages; dlgIndex = 0; dlgAfter = after || null; dlgMeta = meta || null;
    renderDialog();
  }
  function renderDialog() {
    const portrait = dlgMeta && dlgMeta.sprite
      ? `<div class="dlg-portrait"><canvas id="dlg_face" width="48" height="48"></canvas>${dlgMeta.name ? `<span>${dlgMeta.name}</span>` : ''}</div>` : '';
    open(`<div class="dialog-box ${portrait ? 'has-portrait' : ''}">${portrait}<div class="dlg-text"><p>${dlgPages[dlgIndex]}</p><div class="dlg-hint">▼ Espacio / Click para continuar</div></div></div>`, 'bottom');
    PH.game.mode = 'dialog';
    if (portrait) {
      const c = document.getElementById('dlg_face');
      const ctx = c.getContext('2d'); ctx.imageSmoothingEnabled = false;
      ctx.scale(3, 3);
      PH.render.drawActor(ctx, 0, 0, 'down', 0, PH.render.NPC_PALETTES[dlgMeta.sprite]);
    }
  }
  function dialogNext() {
    dlgIndex++;
    if (dlgIndex >= dlgPages.length) { close(); const cb = dlgAfter; dlgAfter = null; if (cb) cb(); PH.game.afterQuestCheck(); }
    else renderDialog();
  }

  /* ---------------- ENCUENTRO ---------------- */
  function encounter(wild) {
    const s = G();
    PH.state.markSeen(wild.speciesId);
    const hasLupa = s.player.gear.includes('lupa');
    const hasMed = s.player.gear.includes('medidor');
    const tools = s.player.tools.map(id => PH.items.TOOLS[id]).filter(Boolean);
    const toolBtns = tools.map(t =>
      `<button class="btn tool" data-tool="${t.id}">${t.name}<small>${Math.round(t.success * 100)}% · fid ${Math.round(t.quality * 100)}%</small></button>`
    ).join('');
    const rarityHint = hasLupa ? `${'★'.repeat(PH.gen.rarityTier(wild.rarity).stars)} ${PH.gen.rarityTier(wild.rarity).label}` : '¿? (necesitas Lupa)';
    const envHint = hasMed ? `<div class="enc-env">Clima: ${cap(s.env.weather)} · ${s.env.night ? 'Noche' : 'Día'} · ${cap(s.env.season)}</div>` : '';

    open(`
      <div class="encounter">
        <div class="enc-head">¡Cepa landrace salvaje!</div>
        <div class="enc-body">
          <div class="enc-art"><canvas id="enc_canvas" width="140" height="170"></canvas></div>
          <div class="enc-side">
            <div class="enc-name">${wild.name} <small>${wild.speciesId}</small></div>
            <div class="enc-rare">Rareza estimada: ${rarityHint}</div>
            <div class="enc-desc">${PH.gen.describe(wild.pheno)}</div>
            ${envHint}
            <div class="enc-fields">
              <span>Altura ${wild.pheno.quant.altura}</span>
              <span>Prod ${wild.pheno.quant.produccion}</span>
              <span>Resina ${wild.pheno.quant.resina}</span>
              <span>Vigor ${wild.pheno.quant.vigor}</span>
            </div>
          </div>
        </div>
        <div class="enc-tools">${toolBtns}</div>
        <div class="enc-actions"><button class="btn ghost" id="enc_flee">Dejar y marchar</button></div>
        <div class="enc-msg" id="enc_msg"></div>
      </div>`, 'center');
    PH.game.mode = 'encounter';
    paintPlant('enc_canvas', wild, 2.4);

    overlay.querySelectorAll('.tool').forEach(b => b.onclick = () => resolveHarvest(wild, b.dataset.tool));
    document.getElementById('enc_flee').onclick = () => close();
  }

  function resolveHarvest(wild, toolId) {
    const res = PH.encounter.harvest(wild, toolId);
    const msg = document.getElementById('enc_msg');
    if (res.success) {
      if (res.form === 'polen') {
        // polen: material de cruce; se guarda igualmente en banco marcado
        PH.state.bankAdd(res.specimen);
      } else {
        PH.state.bankAdd(res.specimen);
      }
      const reg = PH.state.registerCatalog ? null : null;
      msg.className = 'enc-msg ok';
      msg.textContent = res.msg;
      // ¿nuevo descubrimiento?
      setTimeout(() => { close(); PH.game.afterQuestCheck(); updateHUD(); }, 900);
      toast(res.msg, 'ok');
    } else {
      msg.className = 'enc-msg bad';
      msg.textContent = res.msg;
      // permite reintentar con otra herramienta; deshabilita nada
      setTimeout(() => { close(); }, 1100);
    }
  }

  /* ---------------- MOCHILA ---------------- */
  function bag() {
    const s = G();
    const tools = s.player.tools.map(id => PH.items.TOOLS[id]);
    const gear = s.player.gear.map(id => PH.items.GEAR[id]);
    open(`
      <div class="panel">
        <div class="panel-head"><h2>🎒 Mochila</h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body">
          <h3>Herramientas de recolección</h3>
          <div class="grid">
            ${tools.map(t => `<div class="item ${s.player.activeTool === t.id ? 'sel' : ''}" data-tool="${t.id}">
              <b>${t.name}</b><small>${t.desc}</small>
              <span class="tag">éxito ${Math.round(t.success * 100)}% · fidelidad ${Math.round(t.quality * 100)}%</span></div>`).join('')}
          </div>
          <h3>Equipo</h3>
          <div class="grid">
            ${gear.length ? gear.map(g => `<div class="item"><b>${g.name}</b><small>${g.desc}</small></div>`).join('') : '<p class="dim">Sin equipo aún. Visita el Mercado.</p>'}
          </div>
          <p class="dim">Consejo: haz clic en una herramienta para marcarla como activa.</p>
        </div>
      </div>`, 'center');
    document.getElementById('p_close').onclick = close;
    overlay.querySelectorAll('.item[data-tool]').forEach(el => el.onclick = () => { s.player.activeTool = el.dataset.tool; bag(); });
  }

  /* ---------------- BANCO GENÉTICO ---------------- */
  function bank() {
    const s = G();
    if (!s.bank.length) {
      open(`<div class="panel"><div class="panel-head"><h2>🧬 Bóveda de cepas</h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body"><p class="dim">La bóveda está vacía. Recolecta cepas en las regiones.</p></div></div>`, 'center');
      document.getElementById('p_close').onclick = close; return;
    }
    const sorted = s.bank.slice().sort((a, b) => b.rarity - a.rarity);
    open(`
      <div class="panel wide">
        <div class="panel-head"><h2>🧬 Bóveda de cepas <small>${s.bank.length} muestras</small></h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body list">
          ${sorted.map(sp => `
            <div class="bank-row">
              ${specimenCard(sp)}
              <div class="bank-actions">
                <button class="btn small" data-seq="${sp.uid}">${sp.sequenced ? '🧾 ADN' : '🔬 Secuenciar'}</button>
                <button class="btn small" data-sell="${sp.uid}">Vender 💰${sellPrice(sp)}</button>
                <button class="btn small ghost" data-rel="${sp.uid}">Liberar</button>
              </div>
            </div>`).join('')}
        </div>
      </div>`, 'center');
    document.getElementById('p_close').onclick = close;
    sorted.forEach(sp => paintPlant('pc_' + sp.uid, sp, 2));
    overlay.querySelectorAll('[data-sell]').forEach(b => b.onclick = () => { sell(b.dataset.sell); bank(); });
    overlay.querySelectorAll('[data-rel]').forEach(b => b.onclick = () => { PH.state.bankRemove(b.dataset.rel); toast('Muestra liberada.'); bank(); });
    overlay.querySelectorAll('[data-seq]').forEach(b => b.onclick = () => sequencePanel(b.dataset.seq));
  }

  /* ---------------- INVESTIGACIÓN: SECUENCIACIÓN Y ADN ---------------- */
  function sequencePanel(uid) {
    const s = G();
    const sp = PH.state.bankGet(uid);
    if (!sp) return;
    const wasSequenced = sp.sequenced;
    const res = PH.research.sequence(sp);
    if (!wasSequenced) { s.stats.sequenced++; PH.game.afterQuestCheck(); }
    const dna = res.seq.match(/.{1,3}/g).join(' ');
    const hidden = res.hidden.length
      ? res.hidden.map(h => `<li><b>${cap(h.gene)}</b>: expresa <i>${h.expressed}</i>, oculta recesivo <i>${h.hidden}</i></li>`).join('')
      : '<li class="dim">Homocigoto en genes visibles: sin recesivos ocultos.</li>';
    // parientes en el banco
    const rels = s.bank.filter(x => x.uid !== uid).map(x => ({ x, c: PH.research.compare(sp, x) }))
      .sort((a, b) => b.c.rel - a.c.rel).slice(0, 3);
    open(`
      <div class="panel">
        <div class="panel-head"><h2>🧬 Secuenciación de ADN</h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body">
          <div class="seq-head">${specimenCard(sp)}</div>
          <h3>Cadena genómica</h3>
          <div class="dna">${dna}</div>
          <h3>Genes recesivos ocultos</h3>
          <ul class="hidden-list">${hidden}</ul>
          <h3>Parentesco en tu banco</h3>
          ${rels.length ? rels.map(r => `<div class="rel-row"><span>${r.x.nickname || r.x.name}</span>
            <div class="bar"><i style="width:${r.c.rel}%"></i></div><b>${r.c.rel}%</b> <small>${r.c.relation}</small></div>`).join('') : '<p class="dim">No hay otras muestras para comparar.</p>'}
        </div>
      </div>`, 'center');
    document.getElementById('p_close').onclick = bank;
    paintPlant('pc_' + sp.uid, sp, 2);
  }
  function sellPrice(sp) {
    return Math.round(30 + sp.rarity * sp.rarity * 0.9 + sp.quality * 1.5);
  }
  function sell(uid) {
    const sp = PH.state.bankGet(uid);
    if (!sp) return;
    // no permitir vender la última copia única del catálogo si es la única muestra de esa firma? Permitimos, el catálogo persiste.
    const price = sellPrice(sp);
    PH.state.bankRemove(uid);
    PH.state.addCredits(price);
    toast(`Vendido por 💰${price}.`, 'ok');
    updateHUD();
  }

  /* ---------------- CATÁLOGO ---------------- */
  function catalog() {
    const s = G();
    const entries = Object.values(s.catalog).sort((a, b) => b.rarity - a.rarity);
    const total = PH.species.SPECIES.length;
    const seenSpecies = Object.keys(s.species).filter(id => s.species[id].obtained > 0).length;
    open(`
      <div class="panel wide">
        <div class="panel-head"><h2>🌿 Strain-dex mundial <small>${entries.length} fenotipos · ${seenSpecies}/${total} cepas</small></h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body">
          ${entries.length ? `<div class="cat-grid">${entries.map(e => catCard(e)).join('')}</div>` : '<p class="dim">Aún no has catalogado nada.</p>'}
        </div>
      </div>`, 'center');
    document.getElementById('p_close').onclick = close;
    entries.forEach((e, i) => paintPlant('cat_' + i, e, 1.7));
  }
  function catCard(e) {
    const idx = catCard._i = (catCard._i || 0);
    const t = PH.gen.rarityTier(e.rarity);
    catCard._i++;
    const cid = 'cat_' + idx;
    const muts = e.mutations.map(m => PH.gen.MUTATIONS[m].label).join(', ');
    return `<div class="cat-card">
      <canvas id="${cid}" width="70" height="90"></canvas>
      <div class="cc-name">${e.name}</div>
      <div class="cc-tier" style="color:${t.color}">${'★'.repeat(t.stars)}</div>
      <div class="cc-meta">${cap(e.pheno.color)} · ${cap(e.pheno.terp)}</div>
      ${muts ? `<div class="cc-mut">${muts}</div>` : ''}
      <div class="cc-count">×${e.count} · desc. ${e.firstAt}</div>
    </div>`;
  }

  /* ---------------- LABORATORIO (CRUCE) ---------------- */
  let breedSel = [];
  function lab() {
    const s = G();
    const fertile = s.bank.filter(sp => sp.form !== 'polen' && !sp.pheno.sterile);
    const pollen = s.bank.filter(sp => sp.form === 'polen');
    const usable = fertile.concat(pollen);
    breedSel = breedSel.filter(uid => s.bank.find(x => x.uid === uid));
    open(`
      <div class="panel wide">
        <div class="panel-head"><h2>🔬 Laboratorio — Cruces genéticos</h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body">
          <p class="dim">Selecciona dos parentales. La descendencia hereda un alelo de cada uno por gen; pueden surgir fenotipos, colores y mutaciones nuevos.</p>
          <div class="breed-slots">
            <div class="slot">${slotView(0)}</div>
            <div class="cross-sign">✕</div>
            <div class="slot">${slotView(1)}</div>
            <div class="cross-eq">→</div>
            <button class="btn primary" id="do_cross" ${breedSel.length === 2 ? '' : 'disabled'}>Cruzar</button>
          </div>
          <h3>Parentales disponibles (${usable.length})</h3>
          <div class="cat-grid select">
            ${usable.map(sp => `<div class="cat-card pick ${breedSel.includes(sp.uid) ? 'picked' : ''}" data-pick="${sp.uid}">
              <canvas id="lp_${sp.uid}" width="70" height="90"></canvas>
              <div class="cc-name">${sp.nickname || sp.name}</div>
              <div class="cc-tier" style="color:${PH.gen.rarityTier(sp.rarity).color}">${'★'.repeat(PH.gen.rarityTier(sp.rarity).stars)}</div>
              <div class="cc-meta">${cap(sp.form)} · ${cap(sp.pheno.color)}</div>
            </div>`).join('')}
          </div>
        </div>
      </div>`, 'center');
    document.getElementById('p_close').onclick = () => { breedSel = []; close(); };
    usable.forEach(sp => paintPlant('lp_' + sp.uid, sp, 1.7));
    overlay.querySelectorAll('[data-pick]').forEach(el => el.onclick = () => togglePick(el.dataset.pick));
    document.getElementById('do_cross').onclick = doCross;
  }
  function slotView(i) {
    const uid = breedSel[i];
    if (!uid) return '<span class="dim">vacío</span>';
    const sp = PH.state.bankGet(uid);
    return `<canvas id="slot_${i}" width="70" height="90"></canvas><div class="cc-name">${sp.name}</div>`;
  }
  function togglePick(uid) {
    const i = breedSel.indexOf(uid);
    if (i >= 0) breedSel.splice(i, 1);
    else if (breedSel.length < 2) breedSel.push(uid);
    lab();
    breedSel.forEach((u, k) => paintPlant('slot_' + k, PH.state.bankGet(u), 1.7));
  }
  function doCross() {
    if (breedSel.length !== 2) return;
    const s = G();
    const A = PH.state.bankGet(breedSel[0]);
    const B = PH.state.bankGet(breedSel[1]);
    const labBonus = 1 + (s.player.labLevel - 1) * 0.6; // mejoras de laboratorio
    const childGeno = PH.gen.breed(A.genotype, B.genotype, { mutRate: 0.08, mutBoost: labBonus });
    const sameStrain = A.speciesId === B.speciesId;
    const purity = Math.max(0, Math.round(((A.purity != null ? A.purity : 100) + (B.purity != null ? B.purity : 100)) / 2 * (sameStrain ? 0.98 : 0.6)));
    const spec = PH.species.makeSpecimen(PH.species.SPECIES_BY_ID[A.speciesId], s.env, {
      genotype: childGeno, form: 'cruce', quality: Math.round((A.quality + B.quality) / 2),
      parents: [A.uid, B.uid], generation: Math.max(A.generation, B.generation) + 1,
      purity, landrace: sameStrain && purity >= 90,
    });
    s.stats.crosses++;
    const before = Object.keys(s.catalog).length;
    PH.state.bankAdd(spec);
    const isNew = Object.keys(s.catalog).length > before;
    breedSel = [];
    // pantalla de resultado
    crossResult(spec, isNew, A, B);
    PH.game.afterQuestCheck();
  }
  function crossResult(spec, isNew, A, B) {
    open(`
      <div class="panel">
        <div class="panel-head"><h2>🌱 Descendencia obtenida</h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body center-col">
          ${isNew ? '<div class="newbadge">✨ ¡FENOTIPO NUEVO PARA EL CATÁLOGO! ✨</div>' : '<div class="dim">Fenotipo ya conocido.</div>'}
          ${specimenCard(spec)}
          <p class="dim">Parentales: ${A.name} ✕ ${B.name}</p>
          <div class="row">
            <button class="btn primary" id="again">Volver al laboratorio</button>
            <button class="btn ghost" id="p_close2">Cerrar</button>
          </div>
        </div>
      </div>`, 'center');
    paintPlant('pc_' + spec.uid, spec, 2.4);
    document.getElementById('p_close').onclick = close;
    document.getElementById('p_close2').onclick = close;
    document.getElementById('again').onclick = lab;
    if (isNew) toast('✨ Nuevo fenotipo catalogado: ' + spec.name, 'ok');
  }

  /* ---------------- INVERNADERO / CULTIVO ---------------- */
  let plantPicker = false;
  function greenhouse() {
    const s = G();
    if (!s.garden) s.garden = [];
    const cap = PH.garden.capacity();
    const plots = [];
    for (let i = 0; i < cap; i++) {
      const p = s.garden[i];
      if (p) plots.push(plotView(p));
      else plots.push(`<div class="plot empty"><div class="plot-add" data-add="1">＋<small>Plantar</small></div></div>`);
    }
    open(`
      <div class="panel wide">
        <div class="panel-head"><h2>🌿 Invernadero <small>${s.garden.length}/${cap} parcelas</small></h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body">
          <p class="dim">Planta clones o semillas y obsérvalos crecer por fases. Riega cuando tengan sed: sin agua se estresan y frenan. El riego excesivo y la humedad ambiental favorecen el moho — trátalo con poda sanitaria y ventilación (bio, sin químicos). Una planta sana rinde más al cosechar.</p>
          <div class="garden-grid">${plots.join('')}</div>
        </div>
      </div>`, 'center');
    document.getElementById('p_close').onclick = () => { plantPicker = false; close(); };
    overlay.querySelectorAll('[data-add]').forEach(b => b.onclick = plantPickerView);
    overlay.querySelectorAll('[data-water]').forEach(b => b.onclick = () => { PH.garden.regar(b.dataset.water); if (PH.audio) PH.audio.sfx('blip'); greenhouse(); });
    overlay.querySelectorAll('[data-treat]').forEach(b => b.onclick = () => { const r = PH.garden.treat(b.dataset.treat); if (r.msg) toast(r.msg, r.ok ? 'ok' : 'bad'); if (r.ok && PH.audio) PH.audio.sfx('confirm'); greenhouse(); });
    overlay.querySelectorAll('[data-harv]').forEach(b => b.onclick = () => doHarvest(b.dataset.harv));
    overlay.querySelectorAll('[data-comp]').forEach(b => b.onclick = () => { if (confirm('¿Compostar esta planta? Se pierde.')) { PH.garden.compost(b.dataset.comp); greenhouse(); } });
  }

  const STAGE_LABELS = ['Plántula', 'Vegetativo temp.', 'Vegetativo', 'Floración', 'Cosecha'];
  function plotView(p) {
    const label = STAGE_LABELS[p.stage] || 'Cosecha';
    const uri = PH.garden.spriteUri(p);
    const pct = PH.garden.progressPct(p);
    const t = PH.gen.rarityTier(p.rarity);
    const pal = PH.gen.paletteFor(p.pheno);
    const st = PH.garden.statusOf(p);
    const wp = PH.garden.waterPct(p), hp = PH.garden.healthPct(p);
    const wtone = wp < 22 ? 'bad' : (wp > 88 ? 'warn' : 'ok');
    return `<div class="plot ${p.ready ? 'ready' : ''} ${p.diseased ? 'sick' : ''}">
      <div class="plot-sprite"><img src="${uri}" alt=""><span class="phdot" style="background:${pal.base}"></span>
        <span class="plot-badge ${st.tone}">${st.label}</span></div>
      <div class="plot-name">${p.name}</div>
      <div class="plot-stage" style="color:${t.color}">${p.ready ? '✅ Lista' : label}</div>
      <div class="bar grow"><i style="width:${pct}%"></i></div>
      <div class="vitals">
        <span class="vit water ${wtone}" title="Agua ${Math.round(wp)}%">💧<b><i style="width:${wp}%"></i></b></span>
        <span class="vit health ${hp < 45 ? 'bad' : 'ok'}" title="Salud ${Math.round(hp)}%">❤️<b><i style="width:${hp}%"></i></b></span>
      </div>
      <div class="plot-actions">
        ${p.ready
          ? `<button class="btn small primary" data-harv="${p.id}">Cosechar</button>`
          : (p.diseased
            ? `<button class="btn small warn" data-treat="${p.id}">🌿 Tratar</button>`
            : `<button class="btn small" data-water="${p.id}">💧 Regar</button>`)}
        <button class="btn small ghost" data-comp="${p.id}">🗑</button>
      </div>
    </div>`;
  }

  function plantPickerView() {
    const s = G();
    const usable = s.bank.filter(sp => sp.form !== 'polen');
    open(`
      <div class="panel wide">
        <div class="panel-head"><h2>🌱 Plantar en el invernadero</h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body">
          <p class="dim">Elige una muestra del banco para cultivar. La cosecha te devolverá varios clones de esa misma genética.</p>
          ${usable.length ? `<div class="cat-grid select">${usable.map(sp => `<div class="cat-card pick" data-plant="${sp.uid}">
            <canvas id="gp_${sp.uid}" width="70" height="90"></canvas>
            <div class="cc-name">${sp.nickname || sp.name}</div>
            <div class="cc-tier" style="color:${PH.gen.rarityTier(sp.rarity).color}">${'★'.repeat(PH.gen.rarityTier(sp.rarity).stars)}</div>
            <div class="cc-meta">${cap(sp.form)} · ${cap(sp.pheno.color)}</div>
          </div>`).join('')}</div>` : '<p class="dim">No tienes cepas plantables. Recolecta o cruza primero.</p>'}
          <div class="row"><button class="btn ghost" id="back">Volver al invernadero</button></div>
        </div>
      </div>`, 'center');
    document.getElementById('p_close').onclick = close;
    document.getElementById('back').onclick = greenhouse;
    usable.forEach(sp => paintPlant('gp_' + sp.uid, sp, 1.7));
    overlay.querySelectorAll('[data-plant]').forEach(el => el.onclick = () => {
      const res = PH.garden.plantFromBank(el.dataset.plant);
      toast(res.msg, res.ok ? 'ok' : 'bad');
      greenhouse();
    });
  }

  function doHarvest(id) {
    const res = PH.garden.harvest(id);
    if (!res.ok) { toast(res.msg || 'No se pudo cosechar.', 'bad'); return; }
    if (PH.audio) PH.audio.sfx('harvest'); toast(`🌾 Cosechaste ${res.name} (salud ${res.health}%): ${res.clones.length} clones + 💰${res.credits}`, 'ok');
    updateHUD();
    PH.game.afterQuestCheck();
    greenhouse();
  }

  /* ---------------- MERCADO ---------------- */
  function shop() {
    const s = G();
    const toolStock = Object.values(PH.items.TOOLS).filter(t => t.price > 0 && !s.player.tools.includes(t.id));
    const gearStock = Object.values(PH.items.GEAR).filter(g => !g.consumable && !s.player.gear.includes(g.id))
      .concat(Object.values(PH.items.GEAR).filter(g => g.consumable));
    open(`
      <div class="panel wide">
        <div class="panel-head"><h2>🛒 Mercado <small>💰 ${fmt(s.player.credits)}</small></h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body">
          <h3>Herramientas</h3>
          <div class="shop-grid">
            ${toolStock.length ? toolStock.map(t => shopItem(t, 'tool')).join('') : '<p class="dim">Tienes todas las herramientas.</p>'}
          </div>
          <h3>Equipo y consumibles</h3>
          <div class="shop-grid">
            ${gearStock.map(g => shopItem(g, 'gear')).join('')}
          </div>
        </div>
      </div>`, 'center');
    document.getElementById('p_close').onclick = close;
    overlay.querySelectorAll('[data-buy]').forEach(b => b.onclick = () => { buy(b.dataset.buy, b.dataset.kind); });
  }
  function shopItem(it, kind) {
    return `<div class="shop-item">
      <b>${it.name}</b><small>${it.desc}</small>
      <button class="btn small" data-buy="${it.id}" data-kind="${kind}">💰 ${fmt(it.price)}</button>
    </div>`;
  }
  function buy(id, kind) {
    const s = G();
    const it = kind === 'tool' ? PH.items.TOOLS[id] : PH.items.GEAR[id];
    if (s.player.credits < it.price) { toast('Créditos insuficientes.', 'bad'); return; }
    PH.state.addCredits(-it.price);
    if (kind === 'tool') { if (!s.player.tools.includes(id)) s.player.tools.push(id); }
    else if (it.consumable) { s.player.cebosActivos += 8; }
    else { if (!s.player.gear.includes(id)) s.player.gear.push(id); }
    toast('Comprado: ' + it.name, 'ok');
    updateHUD(); shop();
  }

  /* ---------------- MISIONES ---------------- */
  function quests() {
    const list = PH.quests.activeList();
    open(`
      <div class="panel">
        <div class="panel-head"><h2>📋 Misiones</h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body">
          ${list.length ? list.map(q => `<div class="quest ${q.state}">
            <div class="q-name">${q.state === 'done' ? '✅' : '◻️'} ${q.name}</div>
            <div class="q-desc">${q.desc}</div>
            <div class="q-reward">Recompensa: ${rewardText(q.reward)}</div>
          </div>`).join('') : '<p class="dim">Habla con los NPC de la Ciudad para conseguir misiones.</p>'}
        </div>
      </div>`, 'center');
    document.getElementById('p_close').onclick = close;
  }
  function rewardText(r) {
    const bits = [];
    if (r.credits) bits.push('💰' + r.credits);
    if (r.prestige) bits.push('🏅' + r.prestige);
    if (r.tool) bits.push(PH.items.TOOLS[r.tool].name);
    if (r.gear) bits.push(PH.items.GEAR[r.gear].name);
    return bits.join(' · ');
  }

  /* ---------------- MENÚ / ubicaciones especiales ---------------- */
  function labHub() {
    open(`
      <div class="panel">
        <div class="panel-head"><h2>🔬 Laboratorio</h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body center-col">
          <p class="dim">Instalaciones de investigación del gremio.</p>
          <div class="hub-grid">
            <button class="btn big hub" id="hb_cross">🧬<br>Cruces genéticos</button>
            <button class="btn big hub" id="hb_green">🌿<br>Invernadero</button>
            <button class="btn big hub" id="hb_bank">🗄️<br>Bóveda de cepas</button>
          </div>
        </div>
      </div>`, 'center');
    document.getElementById('p_close').onclick = close;
    document.getElementById('hb_cross').onclick = lab;
    document.getElementById('hb_green').onclick = greenhouse;
    document.getElementById('hb_bank').onclick = bank;
  }

  function placeMenu(kind) {
    if (kind === '@lab_interior') return labHub();
    if (kind === '@tienda') return shop();
    if (kind === '@casa') return houseMenu();
    if (kind === '@cueva') return toast('La cueva está sellada. (Contenido futuro)', 'bad');
    if (kind === '@expedicion') {
      if (!PH.state.unlocked('expedicion')) return toast('Necesitas 60 de prestigio para las expediciones.', 'bad');
      return toast('Muelle de expediciones — próximamente.', 'ok');
    }
  }
  function houseMenu() {
    const s = G();
    const cost = labUpgradeCost();
    open(`
      <div class="panel">
        <div class="panel-head"><h2>🏠 Tu casa</h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body center-col">
          <p>Un lugar tranquilo para descansar y organizar tu trabajo.</p>
          <div class="stats-box">
            <div>🏅 Prestigio: <b>${s.player.prestige}</b></div>
            <div>📖 Fenotipos: <b>${Object.keys(s.catalog).length}</b></div>
            <div>🧬 Cruces: <b>${s.stats.crosses}</b> · Mutaciones: <b>${s.stats.mutationsFound}</b></div>
            <div>🔬 Nivel de laboratorio: <b>${s.player.labLevel}</b> <small>(+${Math.round((s.player.labLevel - 1) * 60)}% mutación en cruce)</small></div>
            <div>👣 Distancia recorrida: <b>${s.stats.distance}</b></div>
          </div>
          <div class="row">
            <button class="btn primary" id="h_lab" ${s.player.credits < cost ? 'disabled' : ''}>🔬 Mejorar laboratorio (💰${cost})</button>
          </div>
          <div class="row">
            <button class="btn" id="h_events">☄️ Códice de eventos</button>
            <button class="btn primary" id="h_save">💾 Guardar</button>
            <button class="btn ghost" id="h_reset">Reiniciar</button>
          </div>
        </div>
      </div>`, 'center');
    document.getElementById('p_close').onclick = close;
    document.getElementById('h_save').onclick = () => { PH.state.save(); toast('Partida guardada.', 'ok'); };
    document.getElementById('h_events').onclick = eventsCodex;
    document.getElementById('h_lab').onclick = () => {
      if (s.player.credits < cost) return;
      PH.state.addCredits(-cost); s.player.labLevel++; toast('🔬 Laboratorio mejorado a nivel ' + s.player.labLevel, 'ok');
      updateHUD(); houseMenu();
    };
    document.getElementById('h_reset').onclick = () => {
      if (confirm('¿Reiniciar TODO el progreso? Esto no se puede deshacer.')) { PH.state.reset(); location.reload(); }
    };
  }
  function labUpgradeCost() { return G().player.labLevel * 2500; }

  function eventsCodex() {
    const evs = Object.values(PH.events.EVENTS);
    open(`
      <div class="panel">
        <div class="panel-head"><h2>☄️ Códice de eventos raros</h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body">
          <p class="dim">Fenómenos temporales que alteran apariciones y mutaciones. Aparecen al azar mientras exploras.</p>
          ${evs.map(e => `<div class="ev-row"><span class="ev-ico">${e.icon}</span><div><b>${e.name}</b><small>${e.desc}</small></div></div>`).join('')}
        </div>
      </div>`, 'center');
    document.getElementById('p_close').onclick = houseMenu;
  }

  PH.ui = {
    init, toast, updateHUD, open, close, isOpen,
    dialog, dialogNext, encounter, bag, bank, catalog, lab, shop, quests, placeMenu, greenhouse,
    specimenCard, paintPlant,
    get mode() { return PH.game ? PH.game.mode : 'overworld'; }
  };
})(window.PH = window.PH || {});

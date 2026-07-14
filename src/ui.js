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
    const ic = n => `<i class="pic pic-${n} sm"></i>`;
    const wIcon = { despejado: ic('sun'), lluvia: ic('rain'), niebla: ic('cloud'), tormenta: ic('storm'), ola_calor: ic('alert'), nublado: ic('cloud') }[env.weather] || ic('sun');
    const ev = PH.events && PH.events.current();
    const evPill = ev ? `<span class="pill event">${ic('alert')} ${ev.name} · ${PH.events.remaining()}s</span>` : '';
    const html = `
      <div class="hud-left">
        <span class="pill">${ic('pin')} ${map ? map.name : ''}</span>
        <span class="pill">${ic('clock')} ${PH.state.timeLabel(env)} ${env.night ? ic('moon') : ic('sun')}</span>
        <span class="pill">${wIcon} ${cap(env.weather.replace('_', ' '))}</span>
        <span class="pill">${ic('leaf')} ${cap(env.season)}</span>
        ${evPill}
      </div>
      <div class="hud-right">
        ${PH.heat && PH.heat.level() > 0 ? `<span class="pill heat">${ic('alert')} ${'★'.repeat(PH.heat.level())}</span>` : ''}
        <span class="pill">${ic('medal')} ${s.player.prestige}</span>
        <span class="pill">${ic('coin')} ${fmt(s.player.credits)}</span>
        <span class="pill">${ic('grid')} ${Object.keys(s.catalog).length}</span>
      </div>`;
    // dirty-check: evita reflow/repaint si el HUD no cambió (~30×/s -> sólo en cambio)
    if (hud._last === html) return;
    hud._last = html;
    hud.innerHTML = html;
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
    // Retrato de cepa (arte 128² del pack): landraces, cruces canónicos y clones
    // (nodos del árbol). Solo las fusiones parciales intermedias usan procedural.
    const isInter = spec && spec.intermediate;
    const im = (speciesId && !isInter && PH.strainart && PH.strainart.has(speciesId)) ? PH.strainart.img(speciesId) : null;
    const drawProc = () => { ctx.clearRect(0, 0, c.width, c.height); PH.render.drawPlant(ctx, c.width / 2, Math.round(c.height * 0.86), pheno, scale || 2, performance.now()); };
    const drawImg = () => {
      const pad = 3, aw = c.width - pad * 2, ah = c.height - pad * 2;
      const r = Math.min(aw / im.naturalWidth, ah / im.naturalHeight);
      const w = Math.round(im.naturalWidth * r), h = Math.round(im.naturalHeight * r);
      ctx.clearRect(0, 0, c.width, c.height);
      ctx.drawImage(im, Math.round((c.width - w) / 2), Math.round((c.height - h) / 2), w, h);  // centrado
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
    if (spec.landrace) return `<span class="landrace"><i class="pic pic-pin sm"></i> Landrace pura</span>`;
    if (spec.form === 'cruce') return `<span class="hybrid"><i class="pic pic-helix sm"></i> Híbrido F${spec.generation || 1}</span>`;
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
          ${ph.sterile ? '<div class="warn"><i class="pic pic-alert sm"></i> Estéril (no apta para cruce)</div>' : ''}
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
    // Retrato: cara del personaje nuevo (faceart) por rol; si no, dibujo procedural.
    const faceUri = dlgMeta && dlgMeta.char && PH.faceart && PH.faceart.has(dlgMeta.char) ? PH.faceart.uri(dlgMeta.char) : null;
    const hasPortrait = dlgMeta && (faceUri || dlgMeta.sprite);
    const inner = faceUri
      ? `<img class="dlg-face" src="${faceUri}" alt="">`
      : `<canvas id="dlg_face" width="48" height="48"></canvas>`;
    const portrait = hasPortrait
      ? `<div class="dlg-portrait">${inner}${dlgMeta.name ? `<span>${dlgMeta.name}</span>` : ''}</div>` : '';
    open(`<div class="dialog-box ${portrait ? 'has-portrait' : ''}">${portrait}<div class="dlg-text"><p>${dlgPages[dlgIndex]}</p><div class="dlg-hint">▼ Espacio / Click para continuar</div></div></div>`, 'bottom');
    PH.game.mode = 'dialog';
    const c = document.getElementById('dlg_face');
    if (c) {
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
  function encounter(wild, biome) {
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
    // Aparición: rareza de spawn + probabilidad en la hierba alta de este bioma
    const spSp = PH.species.SPECIES_BY_ID[wild.speciesId];
    const srar = spSp ? PH.species.spawnRarity(spSp) : null;
    const pct = (spSp && biome) ? PH.species.biomeChance(spSp, biome) : 0;
    const bname = biome && PH.species.BIOMES[biome] ? PH.species.BIOMES[biome].name : '';
    const spawnHint = srar ? `<div class="enc-spawn">Aparición: <b style="color:${srar.color}">${srar.label}</b>${biome ? ` · ${pct.toFixed(0)}% en ${bname}` : ''}</div>` : '';

    open(`
      <div class="encounter">
        <div class="enc-head">¡Cepa landrace salvaje!</div>
        <div class="enc-body">
          <div class="enc-art"><canvas id="enc_canvas" width="140" height="170"></canvas></div>
          <div class="enc-side">
            <div class="enc-name">${wild.name} <small>${wild.speciesId}</small></div>
            <div class="enc-rare">Rareza estimada: ${rarityHint}</div>
            ${spawnHint}
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
        <div class="panel-head"><h2><i class="pic pic-bag"></i> Mochila</h2><button class="x" id="p_close">✕</button></div>
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
      open(`<div class="panel"><div class="panel-head"><h2><i class="pic pic-helix"></i> Bóveda de cepas</h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body"><p class="dim">La bóveda está vacía. Recolecta cepas en las regiones.</p></div></div>`, 'center');
      document.getElementById('p_close').onclick = close; return;
    }
    const sorted = s.bank.slice().sort((a, b) => b.rarity - a.rarity);
    open(`
      <div class="panel wide">
        <div class="panel-head"><h2><i class="pic pic-helix"></i> Bóveda de cepas <small>${s.bank.length} muestras · <i class="pic pic-trash sm"></i>kits ${s.player.esquejes || 0}</small></h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body list">
          ${sorted.map(sp => {
      const clones = PH.species.cloneOptions ? PH.species.cloneOptions(sp.speciesId) : [];
      const canClip = clones.length && !sp.intermediate;
      return `
            <div class="bank-row">
              ${specimenCard(sp)}
              <div class="bank-actions">
                <button class="btn small" data-seq="${sp.uid}">${sp.sequenced ? '<i class="pic pic-doc sm"></i> ADN' : '<i class="pic pic-flask sm"></i> Secuenciar'}</button>
                ${canClip ? `<button class="btn small" data-clip="${sp.uid}" title="Selección fenotípica (esqueje)"><i class="pic pic-sprout sm"></i> Esquejar</button>` : ''}
                <button class="btn small" data-sell="${sp.uid}">Vender <i class="pic pic-coin sm"></i>${sellPrice(sp)}</button>
                <button class="btn small ghost" data-rel="${sp.uid}">Liberar</button>
              </div>
            </div>`;
    }).join('')}
        </div>
      </div>`, 'center');
    document.getElementById('p_close').onclick = close;
    sorted.forEach(sp => paintPlant('pc_' + sp.uid, sp, 2));
    overlay.querySelectorAll('[data-sell]').forEach(b => b.onclick = () => { sell(b.dataset.sell); bank(); });
    overlay.querySelectorAll('[data-rel]').forEach(b => b.onclick = () => { PH.state.bankRemove(b.dataset.rel); toast('Muestra liberada.'); bank(); });
    overlay.querySelectorAll('[data-seq]').forEach(b => b.onclick = () => sequencePanel(b.dataset.seq));
    overlay.querySelectorAll('[data-clip]').forEach(b => b.onclick = () => cloneSelect(b.dataset.clip));
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
        <div class="panel-head"><h2><i class="pic pic-helix"></i> Secuenciación de ADN</h2><button class="x" id="p_close">✕</button></div>
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
    toast(`Vendido por <i class="pic pic-coin sm"></i>${price}.`, 'ok');
    updateHUD();
  }

  /* ---------------- STRAIN-DEX (árbol filogenético) ---------------- */
  function catalog() {
    const s = G();
    const list = PH.species.SPECIES;
    const byId = PH.species.SPECIES_BY_ID;
    const tiers = PH.strainTiers || {};
    const got = (id) => s.species[id] && s.species[id].obtained > 0;
    const total = list.length;
    const found = list.filter(x => got(x.id)).length;
    const phenos = Object.keys(s.catalog).length;
    const groups = {};
    for (const sp of list) (groups[sp.tier] = groups[sp.tier] || []).push(sp);
    const sections = Object.keys(groups).sort((a, b) => a - b).map(t => `
      <div class="dex-tier">
        <h3>Nivel ${t} · ${tiers[t] || ''} <small>(${groups[t].filter(x => got(x.id)).length}/${groups[t].length})</small></h3>
        <div class="dex-grid">${groups[t].map(sp => dexCard(sp, got(sp.id), byId)).join('')}</div>
      </div>`).join('');
    open(`
      <div class="panel wide">
        <div class="panel-head"><h2><i class="pic pic-book"></i> Strain-dex <small>${found}/${total} cepas · ${phenos} fenotipos</small></h2>
          <div class="head-actions"><button class="btn small" id="dex_guide"><i class="pic pic-helix sm"></i> Cruces</button><button class="btn small" id="dex_odds"><i class="pic pic-grid sm"></i> Probabilidades</button><button class="x" id="p_close">✕</button></div></div>
        <div class="panel-body"><p class="dim">Toca una cepa para ver su árbol de linaje.</p>${sections}</div>
      </div>`, 'center');
    document.getElementById('p_close').onclick = close;
    document.getElementById('dex_odds').onclick = habitatStats;
    document.getElementById('dex_guide').onclick = crossGuide;
    overlay.querySelectorAll('.dex-card[data-strain]').forEach(el => el.onclick = () => lineageView(el.dataset.strain));
  }
  // Tarjeta de receta: parentales × ... → descendiente (bloqueado si no obtenido).
  // Icono compacto de una cepa: cogollo (budart) con respaldo al retrato.
  function budIcon(id) { return (PH.budart && PH.budart.uri(id)) || (PH.strainart && PH.strainart.uri(id)) || null; }
  function recipeCard(parentsArr, node, byId, gotFn, tailIcon) {
    const thumb = pid => {
      const u = budIcon(pid);
      return `<div class="rc-par" title="${byId[pid] ? byId[pid].name : pid}">${u ? `<img src="${u}" alt="" loading="lazy">` : '<i class="pic pic-leaf"></i>'}</div>`;
    };
    const parents = parentsArr.map(thumb).join('<span class="rc-x">×</span>');
    const isGot = gotFn(node.id);
    const cu = budIcon(node.id);
    return `<div class="recipe ${isGot ? 'got' : 'locked'}">
      <div class="rc-parents">${parents}${tailIcon ? `<span class="rc-x">${tailIcon}</span>` : ''}</div>
      <span class="rc-eq">→</span>
      <div class="rc-child" data-strain="${node.id}">
        <div class="rc-art">${cu ? `<img src="${cu}" class="${isGot ? '' : 'locked'}" alt="" loading="lazy">` : '<i class="pic pic-leaf"></i>'}${isGot ? '' : '<span class="rc-lock"><i class="pic pic-alert sm"></i></span>'}</div>
        <div class="rc-name">${isGot ? node.name : '? ? ?'}</div>
      </div>
    </div>`;
  }

  // Guía de cruces: recetas del árbol con el descendiente bloqueado/oculto.
  function crossGuide() {
    const S = PH.species.SPECIES, byId = PH.species.SPECIES_BY_ID, st = G();
    const got = id => st.species[id] && st.species[id].obtained > 0;
    const tiers = PH.strainTiers || {};
    const crosses = S.filter(s => s.parents && s.parents.length >= 2);
    const byTier = {};
    crosses.forEach(s => (byTier[s.tier] = byTier[s.tier] || []).push(s));
    const crossSecs = Object.keys(byTier).sort((a, b) => a - b).map(t => `
      <h3>Nivel ${t} · ${tiers[t] || ''} <small>(${byTier[t].filter(x => got(x.id)).length}/${byTier[t].length})</small></h3>
      <div class="recipe-grid">${byTier[t].map(n => recipeCard(n.parents, n, byId, got)).join('')}</div>`).join('');
    // Retrocruces (autopolinización estabilizada)
    const self = PH.species.SELF_CROSS || {};
    const backNodes = Object.keys(self).map(p => byId[self[p]]).filter(Boolean);
    const backSec = backNodes.length ? `<h3><i class="pic pic-helix sm"></i> Retrocruces <small>(${backNodes.filter(n => got(n.id)).length}/${backNodes.length})</small></h3>
      <div class="recipe-grid">${backNodes.map(n => recipeCard([n.parents[0], n.parents[0]], n, byId, got)).join('')}</div>` : '';
    // Selección fenotípica (esqueje, ítem)
    const CB = PH.species.CLONE_BY_PARENT || {};
    const clones = [];
    Object.keys(CB).forEach(p => CB[p].forEach(cid => clones.push(byId[cid])));
    const cloneSec = clones.length ? `<h3><i class="pic pic-sprout sm"></i> Selección fenotípica (esqueje) <small>(${clones.filter(c => got(c.id)).length}/${clones.length})</small></h3>
      <div class="recipe-grid">${clones.map(n => recipeCard([n.parents[0]], n, byId, got, '<i class="pic pic-sprout sm"></i>')).join('')}</div>` : '';
    const total = crosses.length + backNodes.length + clones.length;
    const done = crosses.filter(x => got(x.id)).length + backNodes.filter(x => got(x.id)).length + clones.filter(x => got(x.id)).length;
    open(`
      <div class="panel wide">
        <div class="panel-head"><h2><i class="pic pic-helix"></i> Guía de cruces <small>${done}/${total} recetas</small></h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body"><p>Todas las recetas del árbol filogenético. Los descendientes que aún no has obtenido aparecen <b>bloqueados</b>: crúzalos en el laboratorio, esqueja el nodo base o repite el retrocruce para revelar su sprite y su nombre.</p>${crossSecs}${backSec}${cloneSec}</div>
      </div>`, 'center');
    document.getElementById('p_close').onclick = close;
    overlay.querySelectorAll('.recipe.got .rc-child[data-strain]').forEach(el => el.onclick = () => lineageView(el.dataset.strain));
  }

  function dexCard(sp, gotIt, byId) {
    const uri = PH.strainart && PH.strainart.uri(sp.id);
    const parents = (sp.parents || []).map(p => (byId[p] ? byId[p].name : p));
    const lineage = parents.length ? '◄ ' + parents.join(' × ') : 'landrace / base';
    const art = uri ? `<img src="${uri}" alt="" loading="lazy">` : `<div class="dex-noart"><i class="pic pic-leaf"></i></div>`;
    const canSpawn = sp.biomes && sp.biomes.length;
    const rar = canSpawn ? PH.species.spawnRarity(sp) : null;
    const pct = canSpawn ? PH.species.biomeChance(sp, sp.biomes[0]) : 0;
    const spawn = rar
      ? `<div class="dex-spawn"><span class="srar ${rar.key}">${rar.label}</span> <span class="spct">${pct.toFixed(0)}%</span></div>`
      : `<div class="dex-spawn dim2">solo por cruce</div>`;
    return `<div class="dex-card ${gotIt ? 'got' : 'todo'}" data-strain="${sp.id}" title="${sp.name}">
      <div class="dex-art">${art}${gotIt ? '<span class="dex-chk">✓</span>' : ''}</div>
      <div class="dex-name">${sp.name}</div>
      <div class="dex-badges"><span class="dex-type ${sp.type}">${sp.type}</span></div>
      ${spawn}
      <div class="dex-lin">${lineage}</div>
    </div>`;
  }

  // Panel de probabilidades de aparición por bioma (hierba alta).
  function habitatStats() {
    const B = PH.species.BIOMES;
    const sections = Object.keys(B).map(bk => {
      const odds = PH.species.biomeOdds(bk);
      const rows = odds.map(o => {
        const rar = PH.species.spawnRarity(o.ref);
        return `<div class="odds-row"><span class="odds-name">${o.ref.name}</span><span class="srar ${rar.key}">${rar.label}</span><div class="odds-bar"><i style="width:${o.pct}%; background:${rar.color}"></i></div><b>${o.pct.toFixed(0)}%</b></div>`;
      }).join('');
      return `<div class="odds-biome"><h3>${cap(bk)} — ${B[bk].name} <small>${Math.round(B[bk].baseEncounter * 100)}% / paso</small></h3>${rows}</div>`;
    }).join('');
    open(`
      <div class="panel wide">
        <div class="panel-head"><h2><i class="pic pic-grid"></i> Probabilidades de aparición</h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body"><p class="dim">Al pisar hierba alta puede salir una cepa. La cifra "/paso" es la probabilidad de encuentro; el % de cada cepa es su peso relativo dentro del bioma (base, sin clima ni hora, que lo modifican).</p>${sections}</div>
      </div>`, 'center');
    document.getElementById('p_close').onclick = close;
  }

  // Árbol de linaje LIMPIO: la cepa arriba y sus parentales colgando debajo,
  // recursivamente hasta las landraces. Árbol anidado (sin líneas cruzadas);
  // los ancestros compartidos se repiten para que cada rama sea un árbol puro.
  function lineageNode(id, byId, depth) {
    const sp = byId[id]; if (!sp) return '';
    const uri = PH.strainart && PH.strainart.uri(id);
    const isLand = !sp.parents || !sp.parents.length;
    const kids = (!isLand && depth < 8) ? sp.parents.map(p => lineageNode(p, byId, depth + 1)).join('') : '';
    return `<li>
      <div class="tnode ${depth === 0 ? 'root' : ''} ${isLand ? 'land' : ''}" data-strain="${id}" title="${sp.name}">
        <div class="tnode-art">${uri ? `<img src="${uri}" alt="">` : '<i class="pic pic-leaf"></i>'}</div>
        <div class="tnode-name">${sp.name}</div>
        ${isLand ? '<div class="tnode-tag">landrace</div>' : ''}
      </div>
      ${kids ? `<ul>${kids}</ul>` : ''}
    </li>`;
  }
  function lineageView(rootId) {
    const byId = PH.species.SPECIES_BY_ID;
    const root = byId[rootId]; if (!root) return;
    let count = 0; (function c(id) { const s = byId[id]; if (!s) return; count++; (s.parents || []).forEach(c); })(rootId);
    open(`
      <div class="panel wide">
        <div class="panel-head"><h2><i class="pic pic-helix"></i> Linaje — ${root.name}</h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body">
          <p class="dim">De la cepa (arriba) hasta sus landraces (abajo). Toca un ancestro para ver el suyo.</p>
          <div class="ltree2"><ul>${lineageNode(rootId, byId, 0)}</ul></div>
          <div class="row"><button class="btn ghost" id="back">◄ Strain-dex</button></div>
        </div>
      </div>`, 'center');
    document.getElementById('p_close').onclick = close;
    document.getElementById('back').onclick = catalog;
    overlay.querySelectorAll('.tnode[data-strain]').forEach(el => el.onclick = () => { if (el.dataset.strain !== rootId) lineageView(el.dataset.strain); });
  }

  /* ---------------- LABORATORIO (CRUCE) ---------------- */
  let breedSel = [];
  // "receta" de una muestra: sus cepas canónicas aportadas (para cruces encadenados)
  const setOf = (x) => (x && x.strainSet && x.strainSet.length ? x.strainSet : [x.speciesId]);
  function lab() {
    const s = G();
    const fertile = s.bank.filter(sp => sp.form !== 'polen' && !sp.pheno.sterile);
    const pollen = s.bank.filter(sp => sp.form === 'polen');
    const usable = fertile.concat(pollen);
    breedSel = breedSel.filter(uid => s.bank.find(x => x.uid === uid));
    // Vista previa de viabilidad (fusión 2-4 parentales): gatea el botón y, si
    // faltan parentales para un nodo, los INDICA. No crea intermedios.
    const byIdSp = PH.species.SPECIES_BY_ID;
    const res = PH.species.resolveCross(breedSel.map(uid => setOf(PH.state.bankGet(uid))));
    const cross = { can: false, hint: '' };
    if (res.reason === 'need') cross.hint = '<div class="cross-hint dim">Selecciona 2–4 parentales del árbol. Algunas cepas requieren 3-4 parentales a la vez.</div>';
    else if (res.reason === 'self' || res.reason === 'closed') cross.hint = '<div class="cross-hint bad"><i class="pic pic-alert sm"></i> Fusión no viable — fuera de la matriz filogenética.</div>';
    else if (res.reason === 'partial') cross.hint = `<div class="cross-hint"><i class="pic pic-helix sm"></i> Hacia <b>${res.toward.name}</b> — añade: ${res.missing.map(m => byIdSp[m] ? byIdSp[m].name : m).join(', ')}.</div>`;
    else if (res.node) { cross.can = true; cross.hint = `<div class="cross-hint ok"><i class="pic pic-sprout sm"></i> → <b>${res.node.name}</b>${res.reason === 'backcross' ? ' (retrocruce)' : ''}</div>`; }
    open(`
      <div class="panel wide">
        <div class="panel-head"><h2><i class="pic pic-flask"></i> Laboratorio — Cruces genéticos</h2>
          <div class="head-actions"><button class="btn small" id="lab_guide"><i class="pic pic-helix sm"></i> Guía</button><button class="x" id="p_close">✕</button></div></div>
        <div class="panel-body">
          <p>Selecciona <b>2 a 4 parentales</b> del árbol filogenético. La mayoría de cepas nacen de 2, pero algunas (Skunk #1, Haze, OG Kush, AK-47…) exigen 3-4 parentales a la vez. Solo se permiten fusiones que completen un nodo del árbol.</p>
          <div class="breed-slots">
            ${Array.from({ length: Math.min(4, Math.max(2, breedSel.length)) }, (_, i) => `${i ? '<div class="cross-sign">×</div>' : ''}<div class="slot">${slotView(i)}</div>`).join('')}
            <div class="cross-eq">→</div>
            <button class="btn primary" id="do_cross" ${cross.can ? '' : 'disabled'}>Fusionar</button>
          </div>
          ${cross.hint}
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
    document.getElementById('lab_guide').onclick = crossGuide;
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
    else if (breedSel.length < 4) breedSel.push(uid);   // fusión de hasta 4 parentales
    lab();
    breedSel.forEach((u, k) => paintPlant('slot_' + k, PH.state.bankGet(u), 1.7));
  }
  function doCross() {
    if (breedSel.length < 2) return;
    const s = G();
    const parents = breedSel.map(uid => PH.state.bankGet(uid)).filter(Boolean);
    if (parents.length < 2) return;
    // CIERRE DE MATRIZ: la fusión de 2-4 parentales solo produce cepa si su
    // receta completa un nodo del árbol. Los inválidos ya vienen gateados.
    const res = PH.species.resolveCross(parents.map(setOf));
    if (!res.node) { toast('<i class="pic pic-alert sm"></i> Fusión no viable', 'bad'); return; }
    const canon = res.node;
    const avgQ = Math.round(parents.reduce((a, p) => a + p.quality, 0) / parents.length);
    const avgPur = Math.round(parents.reduce((a, p) => a + (p.purity != null ? p.purity : 100), 0) / parents.length);
    const maxGen = Math.max(...parents.map(p => p.generation || 0));
    const spec = PH.species.makeSpecimen(canon, s.env, {
      form: 'cruce', quality: avgQ, parents: parents.map(p => p.uid),
      generation: maxGen + 1, purity: Math.max(avgPur, 70), landrace: false, strainSet: [canon.id],
    });
    s.stats.crosses++;
    const before = Object.keys(s.catalog).length;
    PH.state.bankAdd(spec);
    const isNew = Object.keys(s.catalog).length > before;
    breedSel = [];
    crossResult(spec, isNew, parents, canon);
    PH.game.afterQuestCheck();
  }
  // Selección fenotípica / esqueje: aísla un clon élite de un nodo base (§4).
  // No es hibridación; consume un "Kit de selección fenotípica".
  function cloneSelect(uid) {
    const s = G();
    const sp = PH.state.bankGet(uid);
    if (!sp) return;
    const opts = PH.species.cloneOptions(sp.speciesId);
    if (!opts.length) return;
    if ((s.player.esquejes || 0) < 1) { toast('Necesitas un <b>Kit de selección fenotípica</b> (Mercado).', 'bad'); return; }
    s.player.esquejes--;
    const clone = PH.species.phenotypeSelect(sp.speciesId);
    const spec = PH.species.makeSpecimen(clone, s.env, {
      form: 'esqueje', quality: Math.min(100, sp.quality + 4),
      parents: [sp.uid], generation: sp.generation, purity: Math.max(sp.purity || 100, 90),
      landrace: false, strainSet: [clone.id],
    });
    const before = Object.keys(s.catalog).length;
    PH.state.bankAdd(spec);
    const isNew = Object.keys(s.catalog).length > before;
    open(`
      <div class="panel">
        <div class="panel-head"><h2><i class="pic pic-sprout"></i> Selección fenotípica</h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body center-col">
          <div class="newbadge">${isNew ? '<i class="pic pic-nova sm"></i> ' : ''}FENOTIPO AISLADO: ${clone.name}</div>
          <p class="dim">Has esquejado un clon élite de <b>${sp.name}</b>${opts.length > 1 ? ' (fenotipo al azar entre sus variantes)' : ''}.</p>
          ${specimenCard(spec)}
          <div class="row"><button class="btn primary" id="again">Volver a la bóveda</button></div>
        </div>
      </div>`, 'center');
    paintPlant('pc_' + spec.uid, spec, 2.4);
    document.getElementById('p_close').onclick = close;
    document.getElementById('again').onclick = bank;
    toast('<i class="pic pic-sprout sm"></i> Fenotipo aislado: ' + clone.name, 'ok');
    updateHUD();
  }

  // Cruce fuera de la matriz: bloqueado (sin genética procedural).
  function crossBlocked(A, B, reason) {
    const s = G();
    const sameId = A.speciesId === B.speciesId;
    // ¿faltan parentales para completar un nodo? (pista de linaje)
    const union = [...new Set([...setOf(A), ...setOf(B)])];
    const near = PH.species.SPECIES.filter(sp => sp.parents && sp.parents.length >= 2 &&
      union.every(u => sp.parents.includes(u)) && sp.parents.length > union.length)
      .map(sp => sp.name).slice(0, 3);
    const msg = reason === 'self'
      ? `La autopolinización de <b>${A.name}</b> no está estabilizada: no produce un nodo del árbol. Sólo algunos retrocruces son viables.`
      : `<b>${A.name} × ${B.name}</b> no corresponde a ningún nodo del árbol filogenético. En este mundo sólo son viables los cruces canónicos.`;
    const hint = near.length ? `<p class="warn">Podría faltar linaje. Con esta combinación se acerca a: ${near.join(', ')} (necesita más parentales).</p>` : '';
    open(`
      <div class="panel">
        <div class="panel-head"><h2><i class="pic pic-alert"></i> Cruce no viable</h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body center-col">
          <div class="blocked-badge"><i class="pic pic-alert sm"></i> CRUCE BLOQUEADO</div>
          <p class="dim">${msg}</p>
          ${hint}
          <div class="row"><button class="btn primary" id="again">Volver al laboratorio</button></div>
        </div>
      </div>`, 'center');
    document.getElementById('p_close').onclick = close;
    document.getElementById('again').onclick = lab;
    toast('<i class="pic pic-alert sm"></i> Cruce no viable: fuera de la matriz', 'bad');
  }

  function crossResult(spec, isNew, parents, canon) {
    const pnames = parents.map(p => p.nickname || p.name).join(' × ');
    open(`
      <div class="panel">
        <div class="panel-head"><h2><i class="pic pic-sprout"></i> Descendencia obtenida</h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body center-col">
          <div class="newbadge"><i class="pic pic-helix sm"></i> ¡NODO DEL ÁRBOL: ${canon.name}!</div>
          <p>Fusión canónica reconocida: has replicado <b>${canon.name}</b>, una genética del árbol filogenético${parents.length > 2 ? ` (${parents.length} parentales)` : ''}.</p>
          ${specimenCard(spec)}
          <p class="dim">Parentales: ${pnames}</p>
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
    if (canon) toast('<i class="pic pic-helix sm"></i> Nodo desbloqueado: ' + canon.name, 'ok');
    else if (isNew) toast('<i class="pic pic-nova sm"></i> Nuevo fenotipo catalogado: ' + spec.name, 'ok');
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
        <div class="panel-head"><h2><i class="pic pic-leaf"></i> Invernadero <small>${s.garden.length}/${cap} parcelas</small></h2><button class="x" id="p_close">✕</button></div>
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
      <div class="plot-stage" style="color:${t.color}">${p.ready ? '✓ Lista' : label}</div>
      <div class="bar grow"><i style="width:${pct}%"></i></div>
      <div class="vitals">
        <span class="vit water ${wtone}" title="Agua ${Math.round(wp)}%"><i class="pic pic-drop sm"></i><b><i style="width:${wp}%"></i></b></span>
        <span class="vit health ${hp < 45 ? 'bad' : 'ok'}" title="Salud ${Math.round(hp)}%"><i class="pic pic-heart sm"></i><b><i style="width:${hp}%"></i></b></span>
      </div>
      <div class="plot-actions">
        ${p.ready
          ? `<button class="btn small primary" data-harv="${p.id}">Cosechar</button>`
          : (p.diseased
            ? `<button class="btn small warn" data-treat="${p.id}"><i class="pic pic-leaf sm"></i> Tratar</button>`
            : `<button class="btn small" data-water="${p.id}"><i class="pic pic-drop sm"></i> Regar</button>`)}
        <button class="btn small ghost" data-comp="${p.id}"><i class="pic pic-trash"></i></button>
      </div>
    </div>`;
  }

  function plantPickerView() {
    const s = G();
    const usable = s.bank.filter(sp => sp.form !== 'polen');
    open(`
      <div class="panel wide">
        <div class="panel-head"><h2><i class="pic pic-sprout"></i> Plantar en el invernadero</h2><button class="x" id="p_close">✕</button></div>
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
    if (PH.audio) PH.audio.sfx('harvest'); toast(`<i class="pic pic-sprout sm"></i> Cosechaste ${res.name} (salud ${res.health}%): ${res.clones.length} clones + <i class="pic pic-coin sm"></i>${res.credits}`, 'ok');
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
        <div class="panel-head"><h2><i class="pic pic-cart"></i> Mercado <small><i class="pic pic-coin sm"></i> ${fmt(s.player.credits)}</small></h2><button class="x" id="p_close">✕</button></div>
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
      <button class="btn small" data-buy="${it.id}" data-kind="${kind}"><i class="pic pic-coin sm"></i> ${fmt(it.price)}</button>
    </div>`;
  }
  function buy(id, kind) {
    const s = G();
    const it = kind === 'tool' ? PH.items.TOOLS[id] : PH.items.GEAR[id];
    if (s.player.credits < it.price) { toast('Créditos insuficientes.', 'bad'); return; }
    PH.state.addCredits(-it.price);
    if (kind === 'tool') { if (!s.player.tools.includes(id)) s.player.tools.push(id); }
    else if (it.kind === 'esqueje') { s.player.esquejes = (s.player.esquejes || 0) + 1; }
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
        <div class="panel-head"><h2><i class="pic pic-clip"></i> Misiones</h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body">
          ${list.length ? list.map(q => `<div class="quest ${q.state}">
            <div class="q-name">${q.state === 'done' ? '<span style="color:var(--green-hi)">✓</span>' : '<span class="dim">○</span>'} ${q.name}</div>
            <div class="q-desc">${q.desc}</div>
            <div class="q-reward">Recompensa: ${rewardText(q.reward)}</div>
          </div>`).join('') : '<p class="dim">Habla con los NPC de la Ciudad para conseguir misiones.</p>'}
        </div>
      </div>`, 'center');
    document.getElementById('p_close').onclick = close;
  }
  function rewardText(r) {
    const bits = [];
    if (r.credits) bits.push('<i class="pic pic-coin sm"></i> ' + r.credits);
    if (r.prestige) bits.push('<i class="pic pic-medal sm"></i> ' + r.prestige);
    if (r.tool) bits.push(PH.items.TOOLS[r.tool].name);
    if (r.gear) bits.push(PH.items.GEAR[r.gear].name);
    return bits.join(' · ');
  }

  /* ---------------- MENÚ / ubicaciones especiales ---------------- */
  function labHub() {
    open(`
      <div class="panel">
        <div class="panel-head"><h2><i class="pic pic-flask"></i> Laboratorio</h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body center-col">
          <p class="dim">Instalaciones de investigación del gremio.</p>
          <div class="hub-grid">
            <button class="btn big hub" id="hb_cross"><i class="pic pic-helix"></i><br>Cruces genéticos</button>
            <button class="btn big hub" id="hb_green"><i class="pic pic-leaf"></i><br>Invernadero</button>
            <button class="btn big hub" id="hb_bank"><i class="pic pic-save"></i><br>Bóveda de cepas</button>
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
        <div class="panel-head"><h2><i class="pic pic-home"></i> Tu casa</h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body center-col">
          <p>Un lugar tranquilo para descansar y organizar tu trabajo.</p>
          <div class="stats-box">
            <div><i class="pic pic-medal sm"></i> Prestigio: <b>${s.player.prestige}</b></div>
            <div><i class="pic pic-book sm"></i> Fenotipos: <b>${Object.keys(s.catalog).length}</b></div>
            <div><i class="pic pic-helix sm"></i> Cruces: <b>${s.stats.crosses}</b> · Mutaciones: <b>${s.stats.mutationsFound}</b></div>
            <div><i class="pic pic-flask sm"></i> Nivel de laboratorio: <b>${s.player.labLevel}</b> <small>(+${Math.round((s.player.labLevel - 1) * 60)}% mutación en cruce)</small></div>
            <div><i class="pic pic-pin sm"></i> Distancia recorrida: <b>${s.stats.distance}</b></div>
          </div>
          <div class="row">
            <button class="btn primary" id="h_lab" ${s.player.credits < cost ? 'disabled' : ''}><i class="pic pic-flask sm"></i> Mejorar laboratorio (<i class="pic pic-coin sm"></i>${cost})</button>
          </div>
          <div class="row">
            <button class="btn" id="h_events">☄️ Códice de eventos</button>
            <button class="btn primary" id="h_save"><i class="pic pic-save sm"></i> Guardar</button>
            <button class="btn ghost" id="h_reset">Reiniciar</button>
          </div>
        </div>
      </div>`, 'center');
    document.getElementById('p_close').onclick = close;
    document.getElementById('h_save').onclick = () => { PH.state.save(); toast('Partida guardada.', 'ok'); };
    document.getElementById('h_events').onclick = eventsCodex;
    document.getElementById('h_lab').onclick = () => {
      if (s.player.credits < cost) return;
      PH.state.addCredits(-cost); s.player.labLevel++; toast('<i class="pic pic-flask sm"></i> Laboratorio mejorado a nivel ' + s.player.labLevel, 'ok');
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

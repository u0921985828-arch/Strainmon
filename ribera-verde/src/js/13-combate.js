/* =========================================================
   COMBATE
   ========================================================= */
const THIEVES=['ENCAPUCHADO','ATRACADOR','DESCONOCIDO','TIRONERO','CARTERISTA'],COPS=['AGENTE LÓPEZ','AGENTE ETXEBERRIA','AGENTE RUIZ','AGENTE GARAI'];
const hpCol=f=>f>.5?'#58d080':f>.2?'#f0c040':'#f05050';
function bhudBuild(){
  const e=$('bE'),p=$('bP');
  e.innerHTML=`<div class="row"><span>${esc(B.name)}</span></div><div class="hp">${B.kind==='thief'?'VIDA':'SOSP.'}<span><i id="bEbar"></i></span></div>`;
  p.innerHTML=`<div class="row"><span>${esc(S.name)}</span><span id="bPg"></span></div><div class="hp">VIDA<span><i id="bPbar"></i></span></div><div class="num" id="bPn"></div>`;
  e.hidden=false;p.hidden=false;bhud();
}
function bhud(){
  const eb=$('bEbar');if(!eb)return;
  const f=B.kind==='thief'?B.hp/B.hpMax:S.heat/100;eb.style.width=Math.max(0,f*100)+'%';eb.style.background=B.kind==='thief'?hpCol(f):'#e05050';
  const pf=S.hp/S.hpMax;$('bPbar').style.width=Math.max(0,pf*100)+'%';$('bPbar').style.background=hpCol(pf);
  $('bPn').textContent=`${S.hp}/${S.hpMax} · ${eur(S.money)}`;$('bPg').textContent=Math.floor(totalBuds())+' g';
}
function prompt(t){dlg.hidden=false;dlgName.hidden=true;dlgMore.hidden=true;dlgText.textContent=nm(t);}
async function battle(kind){
  lock++;let res=null;
  try{
    music('battle');sfx('enc');
    fadeEl.style.transition='none';fadeEl.classList.add('white');
    for(let i=0;i<3;i++){fadeEl.style.opacity=.85;await wait(70);fadeEl.style.opacity=0;await wait(70);}
    fadeEl.style.transition='';fadeEl.classList.remove('white');
    const w=$('wipe');w.hidden=false;w.classList.remove('go');void w.offsetWidth;w.classList.add('go');await wait(480);
    const ch=S.ch;
    B=kind==='thief'?{kind,name:pick(THIEVES),look:randLook('th'+Math.random(),'thief'),t:0,flashE:0,shakeP:0}:{kind,name:pick(COPS),look:LOOKS.cop,t:0,flashE:0,shakeP:0};
    if(kind==='thief'){B.hpMax=12+ch*2+ri(0,4);B.hp=B.hpMax;B.atk=[2+(ch>>2),4+(ch>>1)];}
    mode='battle';updateHUD();w.hidden=true;w.classList.remove('go');
    await wait(650);bhudBuild();
    if(kind==='thief'){await say(`Un ${B.name.toLowerCase()} te corta el paso.`);await say(pick(['«La mochila. Dámela y no pasa nada.»','«Eh, tú. Sé lo que llevas encima.»','«Quieto. El dinero y lo que lleves.»']),B.name);}
    else{bAnim('E','alto');await say(`${B.name} te da el alto.`);await say(pick(['«Control rutinario. ¿Llevas algo encima?»','«Documentación. Y vacía los bolsillos.»','«Aquí huele a marihuana. ¿Es tuya?»']),B.name);}
    while(!res)res=kind==='thief'?await thiefRound():await copRound();
  }catch(e){console.error(e);res=res||'flee';}
  finally{
    $('bE').hidden=true;$('bP').hidden=true;dlg.hidden=true;menuEl.hidden=true;
    await fade(1);mode='world';B=null;
    if(res==='ko'){advanceTime(360);S.hp=S.hpMax;enterMap('home',2,4,'down');}else music(mapMusic());
    updateHUD();await fade(0);
    if(res==='ko')await say('Te despiertas en casa con la cabeza vendada. Un vecino te encontró en el portal.');
    S.cool=25;heatWarn();lock--;
  }
}
async function enemyHits(){
  const dmg=ri(B.atk[0],B.atk[1]);
  bAnim('E','ataque');
  await say(`El ${B.name.toLowerCase()} ${pick(['te golpea','te empuja contra un portal','te da una patada','te tira al suelo'])}.`);
  bAnim('P','herido');vfxCombate('vfx-golpe',64,112);B.shakeP=450;sfx('hurt');S.hp=Math.max(0,S.hp-dmg);bhud();await wait(450);
  if(S.hp<=0){
    bAnim('P','desmayo');await say('Pierdes el conocimiento.');
    let lost=0;for(const b of Object.values(S.buds)){const l=Math.floor(b.g/2);lost+=l;b.g-=l;}
    for(const k of Object.keys(S.buds))if(S.buds[k].g<.5)delete S.buds[k];
    const lm=Math.round(S.money*.3);S.money-=lm;
    await say(`Te roba ${lost} g y ${eur(lm)}.`);
    return 'ko';
  }
  return null;
}
async function thiefRound(){
  prompt('¿Qué haces?');
  const c=await menu(['LUCHAR','MOCHILA','HABLAR','HUIR'],{cls:'battle',cancel:false});
  if(c===0){
    prompt('Elige un golpe.');
    const m=await menu(['PUÑETAZO','PATADA'],{cls:'battle'});if(m<0)return null;
    const mv=m?{n:'PATADA',acc:.65,d:[8,12]}:{n:'PUÑETAZO',acc:.92,d:[4,7]};
    await wait(bAnim('P',m?'patada':'golpe')*.6);await say(mv.n==='PATADA'?'Le das una patada.':'Le das un puñetazo.');
    if(Math.random()<mv.acc){const d=ri(mv.d[0],mv.d[1]);bAnim('E','herido');vfxCombate('vfx-golpe',178,40);B.flashE=500;sfx('hit');B.hp-=d;bhud();await wait(500);if(m&&d>=11)await say('Le has hecho daño de verdad.');}
    else await say('Fallas.');
  }else if(c===1){
    prompt('¿Qué usas?');
    const it=await menu([{label:`SPRAY ×${S.items.spray}`,ic:icono('spray')},{label:`BOCATA ×${S.items.bocata}`,ic:icono('bocadillo')}],{cls:'battle'});if(it<0)return null;
    if(it===0){if(!S.items.spray){await say('No te queda SPRAY.');return null;}S.items.spray--;bAnim('P','spray');vfxCombate('vfx-spray',178,48);await say('Le echas SPRAY DE PIMIENTA a la cara.');bAnim('E','herido');B.flashE=700;sfx('hit');B.hp-=ri(12,16);bhud();await wait(500);await say('No puede abrir los ojos.');}
    else{if(!S.items.bocata){await say('No te quedan BOCATAS.');return null;}S.items.bocata--;bAnim('P','comer');S.hp=Math.min(S.hpMax,S.hp+15);sfx('get');bhud();await say('Te comes un BOCATA. Recuperas vida.');}
  }else if(c===2){
    await say(`${S.name}: «Tranquilo. Somos del mismo barrio.»`);
    if(Math.random()<clamp(.25+S.rep/300,.25,.7)){await say('«Vale... Tú eres el de Maite. Olvídalo.»');return 'talk';}
    await say('«No me cuentes historias.»');
  }else if(c===3){
    if(Math.random()<.5){sfx('door');await say('Consigues escapar.');return 'flee';}
    await say('Te corta el paso. No puedes escapar.');
  }
  if(B.hp<=0){
    B.gone=true;bAnim('E','huir');await say(`El ${B.name.toLowerCase()} sale corriendo.`);
    const loot=ri(20,40)+S.ch*10;S.money+=loot;S.rep+=2;sfx('coin');bhud();
    await say(`Al huir se le cae la cartera: +${eur(loot)}.`);
    if(S.hpMax<60){S.hpMax+=2;S.hp+=2;bhud();await say(`Aguantas más. VIDA máxima: ${S.hpMax}.`);}
    return 'win';
  }
  return enemyHits();
}
function confiscate(extraFine=true){
  const g=Math.floor(totalBuds()),fine=extraFine?Math.min(S.money,Math.round(60+S.heat*1.5)):0;
  if(B)bAnim('E','multa');S.buds={};S.money-=fine;S.heat=Math.max(0,S.heat-15);return [g,fine];
}
async function copRound(){
  const cost=Math.round(40+S.heat*4+totalBuds()*.5);
  prompt('¿Qué haces?');
  const c=await menu(['SOBORNAR','HABLAR','HUIR','ENTREGAR'],{cls:'battle',cancel:false});
  if(c===0){
    if(await ask(`¿Ofrecerle ${eur(cost)} con disimulo?`,['Sí','No'])!==0)return null;
    if(S.money<cost){await say('No llevas tanto dinero encima.');return null;}
    if(!S.protect&&S.ch>=3&&Math.random()<.15){
      await say(`${B.name}: «¿Me intentas sobornar a mí? Esto me lo quedo.»`);
      const [g,f]=confiscate();S.heat=Math.min(100,S.heat+20);sfx('bad');await say(`Te requisan ${g} g y te multan con ${eur(f)}.`);return 'caught';}
    S.money-=cost;S.heat=Math.max(0,S.heat-10);sfx('coin');bhud();bAnim('E','soborno');
    await say(`${B.name} se guarda el sobre. «Aquí no ha pasado nada.»`);return 'bribe';
  }
  if(c===1){
    await say(`${S.name}: «Solo estaba dando un paseo, agente.»`);
    if(Math.random()<clamp(.3+S.rep/250-S.heat/300,.1,.85)){await say(`${B.name}: «Bien. Circula.»`);return 'talk';}
    await say(`${B.name}: «No. Vacía los bolsillos.»`);
    const [g,f]=confiscate();sfx('bad');bhud();await say(`Te requisan ${g} g y te multan con ${eur(f)}.`);return 'caught';
  }
  if(c===2){
    if(Math.random()<.45+(isNight()?.15:0)){sfx('door');S.heat=Math.min(100,S.heat+8);await say('Sales corriendo entre los coches y lo pierdes.');return 'flee';}
    bAnim('E','perseguir');await say(`${B.name} te alcanza y te reduce en el suelo.`);
    const [g,f]=confiscate();S.hp=Math.max(1,S.hp-5);sfx('hurt');bhud();await say(`Te requisan ${g} g y te multan con ${eur(f)}.`);return 'caught';
  }
  const [g]=confiscate(false);bhud();await say(`Le entregas ${g} g. «Buena decisión. Por esta vez, sin multa.»`);return 'caught';
}


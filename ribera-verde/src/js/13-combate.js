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
    B=kind==='thief'?{kind,name:pick(THIEVES),look:randLook('th'+Math.random(),'thief'),t:0,flashE:0,shakeP:0}:kind==='rival'||kind==='darko'?rivalB(kind):{kind,name:pick(COPS),look:LOOKS.cop,t:0,flashE:0,shakeP:0};
    // desde el capítulo 5 (1.10), ladrones más duros: +4 de vida y +1 a cada golpe; un rival (1.16), RIVAL.vida más y +1 a cada golpe; Darko (1.17), DARKO.vida más
    if(B.kind==='thief'){const d=ch>=5?1:0,r=B.rival?1:0;B.hpMax=12+ch*2+ri(0,4)+4*d+RIVAL.vida*r+(B.jefe?DARKO.vida:0);B.hp=B.hpMax;B.atk=[2+(ch>>2)+d+r,4+(ch>>1)+d+r];}
    mode='battle';updateHUD();w.hidden=true;w.classList.remove('go');
    await wait(650);bhudBuild();
    if(B.jefe){await say('Darko se quita la sudadera y la tira al suelo.');await say('«Ni Iñaki ni mi tío. Tú y yo.»',B.name);}
    else if(B.rival){await say(`${B.rival} se te planta delante.`);await say(pick(['«Te lo he dicho por las buenas.»','«Aquí se vende lo mío.»','«Vamos a arreglarlo.»']),B.name);}
    else if(kind==='thief'){await say(`Un ${B.name.toLowerCase()} te corta el paso.`);await say(pick(['«La mochila. Dámela y no pasa nada.»','«Eh, tú. Sé lo que llevas encima.»','«Quieto. El dinero y lo que lleves.»']),B.name);}
    else{bAnim('E','alto');await say(`${B.name} te da el alto.`);await say(pick(['«Control rutinario. ¿Llevas algo encima?»','«Documentación. Y vacía los bolsillos.»','«Aquí huele a marihuana. ¿Es tuya?»']),B.name);}
    while(!res)res=B.kind==='thief'?await thiefRound():await copRound();
  }catch(e){console.error(e);res=res||'flee';}
  finally{
    $('bE').hidden=true;$('bP').hidden=true;dlg.hidden=true;menuEl.hidden=true;
    await fade(1);mode='world';B=null;
    if(res==='ko'){advanceTime(360);S.hp=S.hpMax;enterMap('home',2,4,'down');}else music(mapMusic());
    updateHUD();await fade(0);
    if(res==='ko')await say('Te despiertas en casa con la cabeza vendada. Un vecino te encontró en el portal.');
    S.cool=25;heatWarn();lock--;
  }
  return res;
}
const elB=()=>B.rival||'El '+B.name.toLowerCase();
async function enemyHits(){
  // la carga de Darko (1.17): a veces coge la barra y el golpe siguiente vale el doble (CUBRIRSE lo deja en la mitad). La guardia o la
  // esquiva de esta ronda se gastan con ella (1.24): contra la barra hay que cubrirse o apartarse en la ronda del golpe
  if(B.jefe&&!B.carga&&Math.random()<DARKO.carga){B.carga=1;B.cubre=B.esquiva=0;await say(`${elB()} coge una barra de hierro del suelo. El próximo golpe va a doler.`);return null;}
  // ESQUIVAR (1.18): con suerte (probEsquiva, los reflejos) no te toca y tu golpe siguiente no falla y hace PELEA.contra más
  // (B.contra); si no, te da entero. La amenaza fallida (B.furia) suma PELEA.furia al golpe
  if(B.esquiva){B.esquiva=0;
    if(Math.random()<probEsquiva()){bAnim('E','ataque');await say(B.carga?`${elB()} baja la barra y te apartas a tiempo.`:`${elB()} se lanza y te apartas a tiempo.`);B.carga=B.furia=0;B.contra=1;return null;}
    await say('No te apartas a tiempo.');}
  const dmg=(ri(B.atk[0],B.atk[1])+(B.furia?PELEA.furia:0))*(B.carga?2:1);
  bAnim('E','ataque');
  await say(B.carga?`${elB()} te da con la barra.`:`${elB()} ${pick(['te golpea','te empuja contra un portal','te da una patada','te tira al suelo'])}.`);B.carga=B.furia=0;
  const dd=B.cubre?Math.ceil(dmg/2):dmg;if(B.cubre){B.cubre=0;await say('Te cubres: el golpe duele la mitad.');}   // CUBRIRSE (1.16)
  bAnim('P','herido');vfxCombate('vfx-golpe',64,112);B.shakeP=450;sfx('hurt');S.hp=Math.max(0,S.hp-dd);bhud();await wait(450);
  if(S.hp<=0){
    bAnim('P','desmayo');await say('Pierdes el conocimiento.');
    let lost=0;for(const b of Object.values(S.buds)){const l=Math.floor(b.g/2);lost+=l;b.g-=l;}
    for(const k of Object.keys(S.buds))if(S.buds[k].g<.5)delete S.buds[k];
    let lr=0;for(const k of Object.keys(S.rosin)){const q=Math.round(S.rosin[k].g*5)/10;lr+=q;useRosin(k,q);}   // y la mitad del rosin (1.10)
    const lm=Math.round(S.money*.3);S.money-=lm;
    await say(`Te roba ${lost} g${lr>0?', '+rosinTxt(lr):''} y ${eur(lm)}.`);
    return 'ko';
  }
  return null;
}
async function thiefRound(){
  prompt('¿Qué haces?');
  const c=await menu(['LUCHAR','MOCHILA','HABLAR','HUIR'],{cls:'battle',cancel:false});
  if(c===0){
    prompt('Elige un golpe.');
    const m=await menu(['PUÑETAZO','PATADA','CUBRIRSE','ESQUIVAR'],{cls:'battle'});if(m<0)return null;
    if(m===2){B.cubre=B.guardia=1;B.esquiva=0;await say('Te pones en guardia: el próximo golpe no fallará.');return enemyHits();}
    if(m===3){B.esquiva=1;B.cubre=0;await say('Te quedas atento para apartarte.');return enemyHits();}   // ESQUIVAR (1.18)
    const mv=m?{n:'PATADA',acc:.65,d:[8,12]}:{n:'PUÑETAZO',acc:.92,d:[4,7]};
    await wait(bAnim('P',m?'patada':'golpe')*.6);await say(mv.n==='PATADA'?'Le das una patada.':'Le das un puñetazo.');
    const g=B.guardia,k=B.contra;B.guardia=B.contra=0;   // la fuerza suma al golpe y los reflejos, a la puntería (1.18)
    if(g||k||Math.random()<Math.min(PELEA.accMax,mv.acc+S.pelea.ref*PELEA.acc)){const d=ri(mv.d[0],mv.d[1])+S.pelea.fue+(k?PELEA.contra:0);if(k)await say('Le pillas abierto.');bAnim('E','herido');vfxCombate('vfx-golpe',178,40);B.flashE=500;sfx('hit');B.hp-=d;bhud();await wait(500);if(m&&d>=11)await say('Le has hecho daño de verdad.');}
    else await say('Fallas.');
  }else if(c===1){
    prompt('¿Qué usas?');
    const it=await menu([{label:`SPRAY ×${S.items.spray}`,ic:icono('spray')},{label:`BOCATA ×${S.items.bocata}`,ic:icono('bocadillo')}],{cls:'battle'});if(it<0)return null;
    if(it===0){if(!S.items.spray){await say('No te queda SPRAY.');return null;}S.items.spray--;bAnim('P','spray');vfxCombate('vfx-spray',178,48);await say('Le echas SPRAY DE PIMIENTA a la cara.');bAnim('E','herido');B.flashE=700;sfx('hit');B.hp-=ri(12,16);bhud();await wait(500);await say('No puede abrir los ojos.');}
    else{if(!S.items.bocata){await say('No te quedan BOCATAS.');return null;}S.items.bocata--;bAnim('P','comer');S.hp=Math.min(S.hpMax,S.hp+15);sfx('get');bhud();await say('Te comes un BOCATA. Recuperas vida.');}
  }else if(c===2){
    prompt('¿Qué le dices?');
    const h=await menu(['CALMAR','AMENAZAR'],{cls:'battle'});if(h<0)return null;
    if(h===0){
      await say(`${S.name}: «Tranquilo. Somos del mismo barrio.»`);
      if(!B.jefe&&Math.random()<clamp(.25+S.rep/300,.25,.7)){await say('«Vale... Tú eres el de Maite. Olvídalo.»');return 'talk';}
      await say(B.jefe?'«Aquí ya no hay nada que hablar.»':'«No me cuentes historias.»');
    }else{   // AMENAZAR (1.18): funciona mejor cuanto más tocado está y cuanta más fuerza tienes; si falla, te pega con rabia
      await say(`${S.name}: «Lárgate ahora que puedes.»`);
      if(!B.jefe&&Math.random()<probAmenaza()){await say(B.rival?`${elB()} se lo piensa mejor.`:`${elB()} se lo piensa mejor y se va.`);return 'talk';}
      B.furia=1;await say(B.jefe?'«A mí no me amenaza nadie.»':'«¿A mí? Ahora vas a ver.»');
    }
  }else if(c===3){
    if(Math.random()<Math.min(PELEA.huirMax,.5+S.pelea.ref*PELEA.huir)){sfx('door');await say('Consigues escapar.');return 'flee';}
    await say('Te corta el paso. No puedes escapar.');
  }
  if(B.hp<=0){
    if(B.jefe){bAnim('E','herido');await say(`${elB()} cae al suelo, sin aire.`);}   // Darko (1.17) no huye, y la reputación la da ajusteDarko
    else{B.gone=true;bAnim('E','huir');await say(`${elB()} sale corriendo.`);}
    if(B.rival){if(!B.jefe)S.rep+=RIVAL.rep;if(S.hpMax<60){S.hpMax+=2;S.hp+=2;bhud();await say(`Aguantas más. VIDA máxima: ${S.hpMax}.`);}await experiencia();return 'win';}
    const loot=ri(20,40)+S.ch*10;S.money+=loot;S.rep+=2;sfx('coin');bhud();
    await say(`Al huir se le cae la cartera: +${eur(loot)}.`);
    if(S.hpMax<60){S.hpMax+=2;S.hp+=2;bhud();await say(`Aguantas más. VIDA máxima: ${S.hpMax}.`);}
    await experiencia();
    return 'win';
  }
  return enemyHits();
}
// la experiencia (1.18): cada pelea ganada da PELEA.xp (un ladrón, un rival, Darko) y con cada PELEA.nv subes un nivel y eliges qué
// entrenas: FUERZA (+1 al daño de cada golpe) o REFLEJOS (+PELEA.acc de puntería, +PELEA.esq de esquivar y +PELEA.huir de escapar),
// hasta PELEA.max cada una. Con las dos al máximo (nivel 10) ya no sube
const PELEA={xp:{thief:1,rival:2,darko:3},nv:[2,5,9,14,20,27,35,44,54,65],max:5,acc:.02,accMax:.98,esq0:.45,esq:.06,huir:.04,huirMax:.7,contra:3,amen0:.1,amen:.6,amenF:.03,amenMax:.8,furia:2};
const nivelPelea=()=>PELEA.nv.filter(n=>S.pelea.xp>=n).length;
const probEsquiva=()=>PELEA.esq0+S.pelea.ref*PELEA.esq;
const probAmenaza=()=>clamp(PELEA.amen0+(1-B.hp/B.hpMax)*PELEA.amen+S.pelea.fue*PELEA.amenF,PELEA.amen0,PELEA.amenMax);
async function experiencia(){
  const P=S.pelea;P.xp+=PELEA.xp[B.jefe?'darko':B.rival?'rival':'thief'];
  while(nivelPelea()>P.fue+P.ref&&(P.fue<PELEA.max||P.ref<PELEA.max)){
    sfx('get');await say(`Subes a nivel ${P.fue+P.ref+1} de pelea.`);
    const f=P.fue<PELEA.max,r=P.ref<PELEA.max;let o=f?0:1;
    if(f&&r){await typeText('¿Qué entrenas?');o=await menu(['Fuerza','Reflejos'],{cls:'right',cancel:false});dlg.hidden=true;}   // sin cancelar: las dos son una elección
    if(o===0){P.fue++;await say(`FUERZA ${P.fue}: cada golpe hace ${P.fue} más.`);}
    else{P.ref++;await say(`REFLEJOS ${P.ref}: aciertas, esquivas y escapas mejor.`);}
  }
}
function fichaPelea(){   // la fila Pelea de la MOCHILA
  const P=S.pelea,n=nivelPelea(),s=PELEA.nv[n];
  return `Fuerza ${P.fue} · reflejos ${P.ref} · ${P.xp} de experiencia${s?` (nivel ${n+1} con ${s})`:''}.\nSube ganando peleas: un ladrón da ${PELEA.xp.thief}, un rival ${PELEA.xp.rival}.`;
}
// los rivales (1.16): en las zonas de venta lejos de Darko, un camello que no quiere competencia. Cada venta en la calle de su zona
// le suma una (S.rivales[zona]); con RIVAL.umbral sale a buscarte (queue('rival')): pelear, pagarle su cuota o irte. Si le ganas,
// se va RIVAL.dias días (S.rivalFuera[zona] = el último) y sus clientes te pagan un RIVAL.f más (rivalF, en talkClient)
const RIVAL={ch:3,umbral:8,cuota:200,dias:7,rep:5,f:1.05,vida:6,vuelve:2};
const RIVALES={alto:{n:'ROBER',sitio:'el barrio alto',frase:'Los pijos de esta plaza son míos desde hace años.'},
  puerto:{n:'KEPA',sitio:'el puerto',frase:'Aquí los marineros me compran a mí.'},
  valdehierro:{n:'MONTXO',sitio:'Valdehierro',frase:'En esta ciudad no entra nadie sin pasar por mí.'},
  ibarbide:{n:'ENEKO',sitio:'el Casco Viejo',frase:'Las calles del Casco tienen dueño.'},
  ensanche:{n:'YOLANDA',sitio:'el Ensanche',frase:'Los del Ensanche pagan bien. Y me pagan a mí.'},
  callejon:{n:'TXUSMA',sitio:'Kale Zaharra',frase:'Este callejón es mío. Pregunta a cualquiera.'}};
const nomRival=R=>R.n[0]+R.n.slice(1).toLowerCase();
const rivalF=z=>(S.rivalFuera[z]||0)>=S.day?RIVAL.f:1;
const cuotaRival=z=>Math.round(RIVAL.cuota*ZONAS[z].precio);
function rivalB(kind){
  if(kind==='darko')return {kind:'thief',rival:'Darko',jefe:1,name:'DARKO',look:LOOKS.darko,t:0,flashE:0,shakeP:0};
  const R=RIVALES[S.map]||RIVALES.alto;return {kind:'thief',rival:nomRival(R),name:R.n,look:randLook('rival'+R.n,'thief'),t:0,flashE:0,shakeP:0};
}
function rivalVenta(z){
  if(S.ch<RIVAL.ch||!RIVALES[z]||(S.rivalFuera[z]||0)>=S.day)return;
  S.rivales[z]=(S.rivales[z]||0)+1;if(S.rivales[z]>=RIVAL.umbral)queue('rival',()=>rivalEvent(z));
}
async function rivalEvent(z){
  const R=RIVALES[z];if(S.map!==z)return;   // si te has ido de su zona, te buscará en la próxima venta
  const N=R.n,nom=nomRival(R),c=cuotaRival(z);
  await talk(N,[`Eh, tú. Llevas ${S.rivales[z]} ventas en ${R.sitio}.`,R.frase,`O me pagas ${eur(c)} o lo arreglamos aquí.`]);
  const o=await ask('¿Qué haces?',['Pelear',`Pagarle ${eur(c)}`,'Irte'],N);
  if(o===0){
    const r=await battle('rival');
    if(r==='win'){S.rivalFuera[z]=S.day+RIVAL.dias;S.rivales[z]=0;sfx('get');
      return say(`${nom} no volverá por ${R.sitio} en ${RIVAL.dias} días. Mientras, sus clientes te pagan un ${Math.round((RIVAL.f-1)*100)} % más.`);}
    if(r==='talk'){S.rivales[z]=0;return say(`${nom}: «Vale. Pero no te quiero ver tanto por aquí.»`);}
    S.rivales[z]=r==='ko'?0:RIVAL.umbral-RIVAL.vuelve;return;
  }
  if(o===1&&S.money>=c){S.money-=c;S.rivales[z]=0;sfx('coin');updateHUD();return say(`${nom} se guarda el dinero. «Así me gusta. Hasta la próxima.»`);}
  if(o===1)await say('No llevas tanto dinero encima.');
  S.rivales[z]=RIVAL.umbral-RIVAL.vuelve;return say(`Te apartas. ${nom} se queda mirándote.`);
}
// Darko (1.17): en el capítulo 8, el ajuste de cuentas en sus esquinas de los astilleros. Pelea como un rival con DARKO.vida más
// y la carga (enemyHits). Si le ganas, se va (S.flags.darkoFin = el día): ni él ni sus chicos vuelven por los astilleros
const DARKO={ch:8,vida:4,carga:.3,rep:10};
async function ajusteDarko(){
  const N='DARKO';
  await talk(N,['Mírate. Cargas en el barco de Iñaki y mi tío te llama socio.','A mí me trata como a un recadero. Y todo empezó contigo.','Esto lo arreglamos tú y yo. Aquí y ahora.']);
  if(await ask('¿Peleas con Darko?',['Pelear','Ahora no'],N)!==0)return say('Ya sabes dónde estoy. Mis chicos también.',N);
  const r=await battle('darko');
  if(r==='ko')return;
  if(r!=='win')return say('Corre, corre. Aquí te espero.',N);
  S.flags.darkoFin=S.day;S.rep+=DARKO.rep;sfx('get');
  await talk(N,['Vale. Vale. Ya está.','Las esquinas son tuyas. Yo me largo de aquí una temporada.']);
  await fade(1);buildEnts();await fade(0);
  await talk('SMS · DON BALTASAR',['Me han contado lo de mi sobrino.','Se va a trabajar a un pesquero de fuera. Le vendrá bien.','Tú y yo seguimos como siempre.']);
}
const MULTA_CALLE=601;   // tenencia en la vía pública: la mínima de la Ley de Seguridad Ciudadana (601-30.000 €). Devuelve lo requisado en texto
// (cogollos y, si hay, rosin) y la multa
function confiscate(extraFine=true){
  const g=Math.floor(totalBuds()),r=totalRosin(),fine=extraFine?Math.min(S.money,MULTA_CALLE):0;
  if(B)bAnim('E','multa');S.buds={};S.rosin={};S.money-=fine;S.heat=Math.max(0,S.heat-15);return [g+' g'+(r?' y '+rosinTxt(r):''),fine];
}
// el soborno (1.10) sube también con el dinero que llevas encima: un 5 %
const precioSoborno=()=>Math.round(40+S.heat*4+cargaSosp()*.5+S.money*.05);
async function copRound(){
  const cost=precioSoborno();
  prompt('¿Qué haces?');
  const c=await menu(['SOBORNAR','HABLAR','HUIR','ENTREGAR'],{cls:'battle',cancel:false});
  if(c===0){
    if(await ask(`¿Ofrecerle ${eur(cost)} con disimulo?`,['Sí','No'])!==0)return null;
    if(S.money<cost){await say('No llevas tanto dinero encima.');return null;}
    if(!S.protect&&S.ch>=3&&Math.random()<.15){
      await say(`${B.name}: «¿Me intentas sobornar a mí? Esto me lo quedo.»`);
      const [g,f]=confiscate();S.heat=Math.min(100,S.heat+20);sfx('bad');await say(`Te requisan ${g} y te multan con ${eur(f)}.`);return 'caught';}
    S.money-=cost;S.heat=Math.max(0,S.heat-10);sfx('coin');bhud();bAnim('E','soborno');
    await say(`${B.name} se guarda el sobre. «Aquí no ha pasado nada.»`);return 'bribe';
  }
  if(c===1){
    await say(`${S.name}: «Solo estaba dando un paseo, agente.»`);
    if(Math.random()<clamp(.3+S.rep/250-S.heat/300,.1,.85)){await say(`${B.name}: «Bien. Circula.»`);return 'talk';}
    await say(`${B.name}: «No. Vacía los bolsillos.»`);
    const [g,f]=confiscate();sfx('bad');bhud();await say(`Te requisan ${g} y te multan con ${eur(f)}.`);return 'caught';
  }
  if(c===2){
    if(Math.random()<.45+(isNight()?.15:0)){sfx('door');S.heat=Math.min(100,S.heat+8);await say('Sales corriendo entre los coches y lo pierdes.');return 'flee';}
    bAnim('E','perseguir');await say(`${B.name} te alcanza y te reduce en el suelo.`);
    const [g,f]=confiscate();S.hp=Math.max(1,S.hp-5);sfx('hurt');bhud();await say(`Te requisan ${g} y te multan con ${eur(f)}.`);return 'caught';
  }
  const [g]=confiscate(false);bhud();await say(`Le entregas ${g}. «Buena decisión. Por esta vez, sin multa.»`);return 'caught';
}


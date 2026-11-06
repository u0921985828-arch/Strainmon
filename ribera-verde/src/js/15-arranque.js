/* =========================================================
   TÍTULO, PARTIDA, BUCLE
   ========================================================= */
const SAVE_KEY='riberaVerde_v1';
function save(){try{S.x=P.x;S.y=P.y;S.dir=P.dir;localStorage.setItem(SAVE_KEY,JSON.stringify(S));return true;}catch(e){return false;}}
function loadSave(){try{const t=localStorage.getItem(SAVE_KEY);return t?JSON.parse(t):null;}catch(e){return null;}}
function migrate(){
  if(!S.carpas){   // partidas de antes de la 1.6: macetas extra → carpa de 100; lámpara LED → LED en cada carpa; plantas, en el mismo orden
    S.carpas=[{t:'p60',foco:S.led?'led200':'cfl'}];if((S.potsOwned||2)>2)S.carpas[1]={t:'m100',foco:S.led?'led480':'cfl'};
    const n=S.carpas.reduce((a,c)=>a+CARPAS[c.t].plazas,0),old=S.pots||[];
    S.pots=Array.from({length:n},(_,i)=>i<(S.potsOwned||2)?old[i]||null:null);S.macetas=Array(n).fill('plastico7');
    delete S.potsOwned;delete S.led;
  }
  if(!S.eco){   // partidas de antes de la 1.10: la deuda pasa a la escala real del capítulo en que estás (los intereses cobrados se
    // pierden) y el plazo abierto vuelve a contar desde hoy, con los días que da Baltasar (7, 10 o 7), para pagar la cifra nueva
    S.debt=S.ch>=8?0:{4:DEUDA-PLAZOS[3],5:DEUDA-PLAZOS[3],6:PLAZOS[7],7:PLAZOS[7]}[S.ch]||DEUDA;
    if(S.due>0){S.due=S.ch===3||S.ch===5?PLAZOS[S.ch]:S.debt;S.deadline=Math.max(S.deadline,S.day+(S.ch===5?10:7));}
    if(S.ch>=8){S.imp0=S.sales;S.impN=0;}
  }
  // partidas guardadas por chapter() antes de poner el plazo (hasta la 1.10): capítulo 5 o 7 sin nada que pagar
  if((S.ch===5||S.ch===7)&&!(S.due>0)&&S.debt>0){S.due=S.ch===5?Math.min(PLAZOS[5],S.debt):S.debt;S.deadline=Math.max(S.deadline||0,S.day+(S.ch===5?10:7));}
  // 1.34: en los clubs donde ya vendías, el encargado y el presidente ya se fían de ti
  if(S.nave&&S.nave.r==null)S.nave.r=S.day+RECIBO.dias;if(S.setas&&S.setas.r==null)S.setas.r=S.day+RECIBO.dias;   // 1.35: los recibos, cada RECIBO.dias
  if(!S.clubReg&&S.clubDia)for(const k in PRESI)if(S.clubDia[k]!=null||S.clubEnc&&S.clubEnc.k===k)[k,'pres_'+k].forEach(id=>S.rel[id]=Math.max(rel(id),CLUB.confia));
  if(S.arcon){   // 1.36 (lo pidió el usuario): sin el arcón; los cogollos, a la caja fuerte (o encima, sin ella) y los extractos, a la nevera
    for(const k of Object.keys(S.arcon.buds||{}))moverLote(S.arcon.buds,S.caja?S.caja.buds:S.buds,k,S.arcon.buds[k].g);
    for(const k of Object.keys(S.arcon.rosin||{}))moverRosin(S.arcon.rosin,nevera().rosin,k,S.arcon.rosin[k].g);delete S.arcon;}
  if(S.caja&&S.caja.rosin){for(const k of Object.keys(S.caja.rosin))moverRosin(S.caja.rosin,nevera().rosin,k,S.caja.rosin[k].g);delete S.caja.rosin;}
  const sinMis=!S.misiones,sinItin=!S.itin,sinLog=!S.logros,d=newState();for(const k in d)if(!(k in S))S[k]=d[k];for(const k in d.items)if(!(k in S.items))S.items[k]=0;
  if(sinMis)MISIONES.forEach(m=>{if(m.ch<S.ch)S.misiones[m.id]=0;});   // 1.11: las de capítulos pasados, hechas y sin regalo
  if(S.ch>6)cerrarCopa();   // 1.28: las de la Copa, en una partida que ya la ganó
  if(sinItin)ITINERARIO.forEach(p=>{if(p.ok())S.itin[p.id]=0;});   // 1.23: lo hecho, sin aviso
  // 1.10: el plazo del capítulo 3 corre desde Toño (las partidas sin él, desde hoy) y la protección de Molina dura 10 días desde hoy
  if(S.ch===3&&!S.flags.metB&&!(S.due>0)){S.due=PLAZOS[3];S.deadline=S.day+7;S.flags.tono=S.day;}
  if(S.flags.metB&&!('tono' in S.flags))S.flags.tono=S.day;   // ya conoces a Toño: sale en el móvil (12b-movil)
  if(S.protect&&!S.protHasta)S.protHasta=S.day+CUOTA_DIAS;
  if(!('diario' in S.flags))S.flags.diario=1;   // 1.25: el diario sale bajo la almohada; las partidas de antes ya lo tenían
  if(S.nave&&!S.nave.m){const o=S.nave;S.nave=naveNueva();   // 1.30: la nave de antes (una variedad para todos) pasa a 4 mesas con ella, ya dando, y lo que había, en la 1.ª
    if(o.sid)S.nave.m=S.nave.m.map((_,i)=>({k:o.sid,thc:o.thc,y:1,dia:S.day-NAVE.crece,g:i?0:Math.round(o.g*10)/10,t:o.thc,abo:0}));}
  // 1.31: cada trabajador de la nave, su mesa (w.mesa); los de antes, la que les tocaba por el orden de la plantilla
  naveros().forEach(w=>{if(w.mesa==null)w.mesa=[...Array(NAVE.max).keys()].find(i=>!naveroDe(i));});
  if(S.nave&&!S.nave.f)Object.assign(S.nave,{f:Array(NAVE.max).fill('led'),ex:0,rg:0});   // 1.33: el equipo de la nave; la de antes, con los LED de serie y nada más
  if(S.nave&&!S.nave.ma)S.nave.ma=[];   // 1.34: la carpa de las madres, vacía
  // 1.31: el pH− de 250 ml ya no se vende; lo pedido a Kiko de antes llega como la botella de 1 L
  if(S.envio)S.envio=S.envio.map(l=>/^pH− .* 250 ml$/.test(l)?l.replace(/ 250 ml$/,' 1 L'):l);
  if(!('vendDia' in S.flags)){S.curro.vend.forEach(v=>delete v.dia);S.flags.vendDia=1;}   // 1.29.1: el dia de un vendedor era el de la entrega; ahora, el de la cosecha (los de antes no pierden)
  for(const k in S.custom){   // 1.11: los cruces con nombre largo («A × B», de antes) pasan a uno corto, con la misma clave; 1.24: y
    // los que se llaman como una variedad nueva (Purple Thai × Haze, sin receta antes, se llamaba «Purple Haze»)
    const C=S.custom[k];if(!C.n.includes(' × ')&&C.n.length<=NOM_MAX&&!DEX.some(d=>STRAINS[d].n.toLowerCase()===C.n.toLowerCase()))continue;
    const p=C.n.split(' × '),t=palabras(C.n),h=Math.ceil(t.length/2),wa=p.length>1?palabras(p[0]):t.slice(0,h),wb=p.length>1?palabras(p[p.length-1]):t.slice(h);
    C.n=nombreCruce(wa,wb,n=>DEX.some(d=>STRAINS[d].n.toLowerCase()===n.toLowerCase())||Object.values(S.custom).some(c=>c!==C&&c.n.toLowerCase()===n.toLowerCase()));
  }
  const n=huecos().length;while(S.pots.length<n)S.pots.push(null);while(S.macetas.length<n)S.macetas.push('plastico7');
  if(sinLog)LOGROS.forEach(l=>{if(l.ok())S.logros[l.id]=0;});   // 1.27: lo conseguido, sin aviso (al final: con el diario de arriba)
}
function showTitle(){mode='title';$('title').hidden=false;updateHUD();music('title');}
async function titlePress(b){
  if((b!=='A'&&b!=='START')||lock)return;lock++;
  try{
    sfx('sel');const sv=loadSave();let c=1;
    if(sv){c=await menu(['CONTINUAR','NUEVA PARTIDA'],{cls:'start'});if(c<0)return;}
    if(c===0){S=sv;migrate();await fade(1);$('title').hidden=true;enterGame();await fade(0);showObjective();return;}
    if(sv&&await ask('Hay una partida guardada. ¿Empezar de cero y sobrescribirla?',['Sí','No'])!==0)return;
    await newGame();
  }finally{lock--;}
}
async function chooseName(){
  const opts=['EDDIE','ÁLEX','LUR','ANDER','Otro...'];const i=await menu(opts,{cls:'start',cancel:false,title:'NOMBRE'});
  if(i<4)return opts[i];
  return (await pedirTexto('¿Cómo te llamas?','',8,true,false)).toUpperCase().slice(0,8)||'EDDIE';
}
async function newGame(){
  // prólogo (1.10): en el caserío de la familia, en Mendialde; el piso de la tía, en Ribera Verde, está a un autobús
  S=newState();Object.assign(S,{map:'casa-ama',x:2,y:4,dir:'down'});S.flags.llegada=false;
  await fade(1);$('title').hidden=true;mode='intro';music('home');await fade(0);
  await talk('???',['¿Diga? ¿Eres familia de Maite, la de Ribera Verde? Un barrio obrero a orillas de la ría.','Me llamo Kiko. Llevo treinta años con el growshop de su calle.']);
  await talk('KIKO',['Conservo genéticas: variedades locales de Afganistán, México o la India, y los cruces que salen de ellas.','Las apunto todas en un registro, una GENOTECA. Tu tía Maite me ayudaba a mantenerla.','Perdona. ¿Cómo te llamabas?']);
  S.name=await chooseName();
  await talk('KIKO',['{N}. Hacía años que no te veía por el barrio.','Maite murió hace tres semanas. Te ha dejado su piso, su armario de cultivo... y una deuda.','Coge el autobús en la plaza del pueblo: te deja enfrente del piso. La llave está en el buzón.','Lee la carta que te dejó. Después pásate por el growshop.']);
  await fade(1);enterGame();await wait(300);await fade(0);
  await chapter(1);await wait(2600);showObjective();
}
function enterGame(){
  mode='world';enterMap(S.map,S.x,S.y,S.dir);
  if(tileSolid(MAPS[S.map],P.x,P.y))enterMap(S.map,...(S.map==='home'?[2,4]:[5,9]),'down');   // partidas viejas: la casilla puede ser ahora una carpa
  if(S.clientsDay!==S.day)spawnClients();
  // 1.13: lo que se quedó en la cola al guardar (la cama guarda antes de que salgan los avisos de la noche)
  if(S.orden&&S.day>S.orden)queue('raid',raidEvent);else if(S.orden&&S.orden===S.day)queue('orden',avisoOrden);if(S.due>0&&S.day>S.deadline)queue('penalty',penaltyEvent);
  updateHUD();
}
function update(dt){
  if(mode==='world'&&S){
    updatePlayer(dt);updateEnts(dt);if(isFree())updatePatrullas(dt);
    if(isFree()){timeAcc+=dt;while(timeAcc>=MS_PER_MIN){timeAcc-=MS_PER_MIN;tickMinute();}
      if(pending.length&&!P.moving)run(pending.shift());}
    hudT-=dt;if(hudT<=0||sospHUD()!==hudSosp){hudT=250;updateHUD();}   // la barra de sospecha, en el fotograma en que cambia (1.10)
  }else if(mode==='battle'&&B){B.t+=dt;if(B.flashE>0)B.flashE-=dt;if(B.shakeP>0)B.shakeP-=dt;}
}
function render(now){if(mode==='world'&&S)renderWorld(now);else if(mode==='battle'&&B)renderBattle(now);else if(mode==='carpa'&&VC)renderCarpa(now);else if(mode==='title'||mode==='intro')renderTitle(now);}
let last=performance.now();
function loop(now){const dt=Math.min(50,now-last);last=now;try{update(dt);render(now);colocaToast();verMovil();}catch(e){console.error(e);}requestAnimationFrame(loop);}
function boot(data){
  buildTiles();makeMisc();buildMaps();computeClientTiles();makeArt();arteListo();
  try{if(localStorage.getItem('rv_sound')==='0')setSound(false);}catch(e){}
  if(data&&data.S){S=data.S;migrate();enterGame();}else showTitle();
  requestAnimationFrame(loop);
  try{window.claude?.hot?.snapshot?.(()=>({S:S&&(mode==='world'||mode==='battle')?Object.assign(S,{x:P.x,y:P.y,dir:P.dir}):null}));}catch(e){}
}
window.claude?.hot?.ready?window.claude.hot.ready(boot):boot(window.claude?.hot?.data??{});

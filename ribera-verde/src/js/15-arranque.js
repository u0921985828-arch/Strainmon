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
  const d=newState();for(const k in d)if(!(k in S))S[k]=d[k];for(const k in d.items)if(!(k in S.items))S.items[k]=0;
  const n=huecos().length;while(S.pots.length<n)S.pots.push(null);while(S.macetas.length<n)S.macetas.push('plastico7');
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
  return new Promise(res=>{const box=$('nameBox'),inp=$('nameInput');box.hidden=false;inp.value='';setTimeout(()=>inp.focus(),30);
    const done=()=>{const v=(inp.value.trim().toUpperCase().slice(0,8))||'EDDIE';box.hidden=true;inp.onkeydown=null;inp.blur();pop();res(v);};
    push(b=>{if(b==='A')done();});inp.onkeydown=e=>{e.stopPropagation();if(e.key==='Enter'){e.preventDefault();done();}};});
}
async function newGame(){
  S=newState();await fade(1);$('title').hidden=true;mode='intro';music('home');await fade(0);
  await talk('???',['¡Aupa! Bienvenido a RIBERA VERDE, un barrio a orillas de la ría.','Me llamo KIKO. En el barrio me llaman el Cazasemillas.']);
  await talk('KIKO',['Este mundo está lleno de variedades de cannabis. Unas crecen en cualquier balcón...','...y otras solo en valles perdidos del Rif o del Hindu Kush.','Yo me dedico a buscarlas, cruzarlas y catalogarlas en una GENOTECA.','Pero cuéntame de ti. ¿Cómo te llamas?']);
  S.name=await chooseName();
  await talk('KIKO',['¡{N}! Claro, el sobrino de Maite... o la sobrina, que con esa gorra no se ve bien.','Tu tía nos dejó hace unas semanas. Te ha dejado su piso... y algo más.','Tu historia en Ribera Verde está a punto de empezar.','¡Te espero en el growshop!']);
  await fade(1);enterGame();await wait(300);await fade(0);
  await chapter(1);await wait(2600);showObjective();
}
function enterGame(){
  mode='world';enterMap(S.map,S.x,S.y,S.dir);
  if(tileSolid(MAPS[S.map],P.x,P.y))enterMap(S.map,...(S.map==='home'?[2,4]:[5,9]),'down');   // partidas viejas: la casilla puede ser ahora una carpa
  if(S.clientsDay!==S.day)spawnClients();updateHUD();
}
function update(dt){
  if(mode==='world'&&S){
    updatePlayer(dt);updateEnts(dt);
    if(isFree()){timeAcc+=dt;while(timeAcc>=MS_PER_MIN){timeAcc-=MS_PER_MIN;tickMinute();}
      if(pending.length&&!P.moving)run(pending.shift());}
    hudT-=dt;if(hudT<=0){hudT=250;updateHUD();}
  }else if(mode==='battle'&&B){B.t+=dt;if(B.flashE>0)B.flashE-=dt;if(B.shakeP>0)B.shakeP-=dt;}
}
function render(now){if(mode==='world'&&S)renderWorld(now);else if(mode==='battle'&&B)renderBattle(now);else if(mode==='title'||mode==='intro')renderTitle(now);}
let last=performance.now();
function loop(now){const dt=Math.min(50,now-last);last=now;try{update(dt);render(now);}catch(e){console.error(e);}requestAnimationFrame(loop);}
function boot(data){
  buildTiles();makeMisc();buildMaps();computeClientTiles();makeArt();arteListo();
  try{if(localStorage.getItem('rv_sound')==='0')setSound(false);}catch(e){}
  if(data&&data.S){S=data.S;migrate();enterGame();}else showTitle();
  requestAnimationFrame(loop);
  try{window.claude?.hot?.snapshot?.(()=>({S:S&&(mode==='world'||mode==='battle')?Object.assign(S,{x:P.x,y:P.y,dir:P.dir}):null}));}catch(e){}
}
window.claude?.hot?.ready?window.claude.hot.ready(boot):boot(window.claude?.hot?.data??{});

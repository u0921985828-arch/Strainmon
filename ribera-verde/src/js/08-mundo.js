/* =========================================================
   ESTADO Y MUNDO
   ========================================================= */
let S=null,mode='boot',lock=0,ents=[],B=null,timeAcc=0,hudT=0;
const pending=[],queued=new Set();
const MS_PER_MIN=1000/6;
const P={x:0,y:0,px:0,py:0,dir:'down',moving:false,fx:0,fy:0,t:0,dur:240,parity:0,hold:0,chain:false,bumpT:0};
const DV={up:[0,-1],down:[0,1],left:[-1,0],right:[1,0]},OPP={up:'down',down:'up',left:'right',right:'left'};
const CH_TITLES={1:'La herencia',2:'La calle',3:'La deuda',4:'Genética',5:'El sargento',6:'La Copa de Ribera',7:'Libertad',8:'Leyenda'};
function newState(){return{v:1,name:'EDDIE',map:'home',x:2,y:4,dir:'down',day:1,min:8*60,money:150,hp:30,hpMax:30,heat:0,rep:0,ch:0,flags:{},sales:0,
  seeds:{},buds:{},items:Object.assign({fert:0,insect:0,spray:0,bocata:1},...Object.keys(MACETAS).map(k=>({['m_'+k]:0})),...Object.keys(FOCOS).map(k=>({['f_'+k]:0}))),
  carpas:[{t:'p60',foco:'cfl'}],macetas:['plastico7','plastico7'],pots:[null,null],luz:null,protect:false,
  disc:{},custom:{},debt:5000,due:0,deadline:0,clients:[],clientsDay:0,taken:{},cool:0,steps:0,patxi:0,iDay:0};}
const isFree=()=>mode==='world'&&lock===0&&handlers.length===0;
const isNight=()=>S.min>=21*60||S.min<6*60;
async function run(fn){lock++;try{await fn();}catch(e){console.error(e);}finally{lock--;}}
function queue(key,fn){if(queued.has(key))return;queued.add(key);pending.push(async()=>{try{await fn();}finally{queued.delete(key);}});}
const totalBuds=()=>Object.values(S.buds).reduce((a,b)=>a+b.g,0);
const discCount=()=>Object.keys(S.disc).length;
function strainLine(k){const s=getStrain(k);return `THC ${pct(s.thc)}% · ${s.y} g/planta · ${String(s.d).replace('.',',')} días · Resist. ${s.r}%\n${s.o}`;}
function discover(sid){if(!S.disc[sid]){S.disc[sid]=true;toast(`<small>NUEVA EN LA GENOTECA</small>${esc(getStrain(sid).n)}`);queue('historia',checkStory);}}
function addSeeds(sid,n){S.seeds[sid]=(S.seeds[sid]||0)+n;discover(sid);}
function addBuds(sid,g,thc){const b=S.buds[sid];if(b){b.thc=(b.thc*b.g+thc*g)/(b.g+g);b.g+=g;}else S.buds[sid]={g,thc};discover(sid);}
function useBuds(sid,g){const b=S.buds[sid];b.g-=g;if(b.g<.5)delete S.buds[sid];}
function budLots(min,minThc=0){return Object.entries(S.buds).filter(([k,b])=>b.g>=min&&b.thc>=minThc);}
const lotItem=([k,b])=>({label:getStrain(k).n,right:`${Math.floor(b.g)} g · ${pct(b.thc)}%`,sw:getStrain(k).c});
async function got(t){sfx('get');await say(`¡${S.name} obtiene ${t}!`);}

/* ---------- NPCs ---------- */
const NPCDEF=[
  {id:'kiko',map:'shop',x:4,y:2,look:'kiko',talk:()=>talkKiko()},
  {id:'josune',map:'bar',x:2,y:2,look:'josune',talk:()=>talkJosune()},
  {id:'baltasar',map:'bar',x:7,y:4,look:'baltasar',talk:()=>talkBaltasar()},
  {id:'tono',map:'bar',x:5,y:4,look:'tono',cond:()=>S.ch>=3&&S.ch<8,talk:()=>say(pick(['Don Baltasar está ocupado. Habla con él si traes la pasta.','¿Qué miras? ¿Tengo monos en la cara?']),'TOÑO')},
  {id:'begona',map:'town',x:10,y:12,wander:2,look:'begona',talk:()=>say(pick(['Las plantas beben mucho bajo la lámpara. Riégalas a diario, majo.','Sin agua se ponen amarillas y se mueren. Como mi geranio.','Tu tía siempre tenía el piso oliendo a limón. Ahora sé por qué.']),'BEGOÑA')},
  {id:'unai',map:'town',x:17,y:18,wander:3,look:'kid',talk:()=>say(pick(['¡Mantén pulsado B para correr! Lo sabe todo el mundo.','De noche, en la hierba alta del parque, salen chorizos. Lo dice mi hermano.','Con START ves tu GENOTECA. ¡Yo quiero una!','Dicen que los arbustos del parque esconden cosas. Pulsa A delante de ellos.']),'UNAI')},
  {id:'patxi',map:'town',x:21,y:21,dir:'up',look:'oldman',talk:()=>talkPatxi()},
  {id:'txaro',map:'town',x:3,y:18,look:'granny',talk:()=>talkTxaro()},
  {id:'inaki',map:'town',x:37,y:21,dir:'left',look:'sailor',cond:()=>S.ch>=2,talk:()=>talkInaki()},
  {id:'cop',map:'town',x:22,y:17,wander:3,look:'cop',cond:()=>S.ch>=2,talk:()=>talkCop()},
  {id:'darko',map:'town',x:20,y:14,dir:'up',look:'darko',cond:()=>(S.ch>=2&&!S.flags.darko1)||S.ch===6,talk:()=>talkDarko()},
  {id:'molina',map:'town',x:23,y:15,look:'molina',cond:()=>S.ch>=5&&!S.protect,talk:()=>talkMolina()},
  {id:'jurado',map:'town',x:18,y:15,look:'judge',cond:()=>S.ch===6,talk:()=>talkJurado()},
];
function mkEnt(d){return{id:d.id,x:d.x,y:d.y,px:d.x*16,py:d.y*16,hx:d.x,hy:d.y,dir:d.dir||'down',look:d.lookObj||LOOKS[d.look],def:d,wander:d.wander||0,wt:800+Math.random()*2400,moving:false,t:0,fx:d.x,fy:d.y};}
function buildEnts(){
  const old={};ents.forEach(e=>old[e.id]=e);ents=[];
  for(const d of NPCDEF){if(d.map!==S.map||(d.cond&&!d.cond()))continue;ents.push(old[d.id]&&old[d.id].def===d?old[d.id]:mkEnt(d));}
  if(S.map==='town')for(const c of S.clients){const o=old[c.id];ents.push(o||mkEnt({id:c.id,x:c.x,y:c.y,wander:2,lookObj:c.look,client:c}));}
}
const ITEMS=[
  {id:'i_spray',map:'town',x:8,y:25,give:async()=>{S.items.spray+=2;await got('2 × SPRAY DE PIMIENTA');}},
  {id:'i_fert',map:'town',x:36,y:24,give:async()=>{S.items.fert+=3;await got('3 × FERTILIZANTE');}},
  {id:'i_boc',map:'town',x:15,y:23,give:async()=>{S.items.bocata+=2;await got('2 × BOCATA');}},
  {id:'h_acap',map:'town',x:2,y:26,hidden:1,give:async()=>{addSeeds('acapulco',2);await got('2 semillas de ACAPULCO ORO');await say('Alguien las escondió aquí hace años. Huelen a playa.');}},
  {id:'h_50',map:'town',x:9,y:16,hidden:1,give:async()=>{S.money+=50;await got('50 € arrugados');}},
  {id:'h_ins',map:'town',x:10,y:24,hidden:1,give:async()=>{S.items.insect+=1;await got('1 × INSECTICIDA');}},
];
const itemAt=(x,y)=>ITEMS.find(it=>!it.hidden&&it.map===S.map&&it.x===x&&it.y===y&&!S.taken[it.id]);
async function pickItem(it){S.taken[it.id]=true;await it.give();}
function tileSolid(m,x,y){
  if(x<0||y<0||x>=m.w||y>=m.h)return true;
  if(SOLID_G.test(m.g[y][x])||m.o[y][x])return true;
  return !!itemAt(x,y);
}
const entAt=(x,y)=>ents.find(e=>(e.x===x&&e.y===y)||(e.moving&&e.fx===x&&e.fy===y));
function enterMap(name,x,y,dir){S.map=name;if(name==='home')montarCasa();Object.assign(P,{x,y,px:x*16,py:y*16,fx:x,fy:y,moving:false,chain:false,hold:0});if(dir)P.dir=dir;S.x=x;S.y=y;S.dir=P.dir;ents=[];buildEnts();music(mapMusic());}
const mapMusic=()=>S.map==='town'?(isNight()?'night':'town'):'home';
async function warp(w){sfx('door');await fade(1);enterMap(w.to,w.x,w.y,w.dir);updateHUD();await wait(80);await fade(0);}

/* ---------- movement ---------- */
function updatePlayer(dt){
  if(P.moving){P.t+=dt;const k=Math.min(1,P.t/P.dur);P.px=(P.fx+(P.x-P.fx)*k)*16;P.py=(P.fy+(P.y-P.fy)*k)*16;
    if(k<1)return;P.moving=false;P.px=P.x*16;P.py=P.y*16;onStepEnd();P.chain=true;}
  if(!isFree()){P.chain=false;return;}
  const d=dirOrder[dirOrder.length-1];
  if(!d){P.chain=false;P.hold=0;return;}
  if(d!==P.dir){P.dir=d;if(!P.chain){P.hold=90;return;}}
  if(P.hold>0){P.hold-=dt;return;}
  tryMove(d);
}
function tryMove(d){
  const m=MAPS[S.map],[dx,dy]=DV[d];
  const ex=m.exits[P.x+','+P.y];
  if(d==='down'&&ex){P.chain=false;run(()=>warp(ex));return;}
  const nx=P.x+dx,ny=P.y+dy;
  if(tileSolid(m,nx,ny)||entAt(nx,ny)){const n=performance.now();if(n-P.bumpT>350){sfx('bump');P.bumpT=n;}P.chain=false;return;}
  P.fx=P.x;P.fy=P.y;P.x=nx;P.y=ny;P.t=0;P.moving=true;P.pisT=performance.now();P.dur=held.B?130:240;P.parity^=1;
}
function onStepEnd(){
  S.x=P.x;S.y=P.y;S.dir=P.dir;S.steps++;if(S.cool>0)S.cool--;
  const m=MAPS[S.map],door=m.doors[P.x+','+P.y];
  if(door){run(()=>warp(door));return;}
  if(S.map!=='town')return;
  if(P.y>=13&&P.y<=14&&P.x>=18&&P.x<=22){
    if(S.ch>=2&&!S.flags.darko1){queue('darko',async()=>{const e=ents.find(e=>e.id==='darko');if(e)e.dir='up';await talkDarko();});return;}
    if(S.ch>=5&&!S.flags.molina1&&!S.protect){queue('molina',talkMolina);return;}
  }
  if(S.ch>=2&&S.cool<=0){
    const g=totalBuds(),tall=m.g[P.y][P.x]==='tallgrass';
    const pp=g>0?(.002+S.heat*.00025)*(S.protect?.4:1):0;
    const pt=(g>=5||S.money>=150)?.004*(isNight()?2.5:1)*(tall?3:1):0;
    const r=Math.random();
    if(r<pp){S.cool=25;run(()=>battle('police'));}else if(r<pp+pt){S.cool=25;run(()=>battle('thief'));}
  }
}
function updateEnts(dt){
  const free=isFree(),m=MAPS[S.map];
  for(const e of ents){
    if(e.moving){e.t+=dt;const k=Math.min(1,e.t/320);e.px=(e.fx+(e.x-e.fx)*k)*16;e.py=(e.fy+(e.y-e.fy)*k)*16;if(k>=1){e.moving=false;e.fx=e.x;e.fy=e.y;}continue;}
    if(!free||!e.wander)continue;e.wt-=dt;if(e.wt>0)continue;e.wt=1200+Math.random()*2600;
    const d=pick(['up','down','left','right']);e.dir=d;const [dx,dy]=DV[d],nx=e.x+dx,ny=e.y+dy;
    if(Math.abs(nx-e.hx)>e.wander||Math.abs(ny-e.hy)>e.wander)continue;
    if(tileSolid(m,nx,ny)||entAt(nx,ny)||(nx===P.x&&ny===P.y)||(P.moving&&nx===P.fx&&ny===P.fy)||m.doors[nx+','+ny]||m.exits[nx+','+ny])continue;
    e.fx=e.x;e.fy=e.y;e.x=nx;e.y=ny;e.t=0;e.moving=true;
  }
}
function worldPress(b){
  if(mode==='title'){titlePress(b);return;}
  if(!isFree()||P.moving)return;
  if(b==='A')interact();else if(b==='START')run(startMenu);
}
function interact(){
  const [dx,dy]=DV[P.dir],m=MAPS[S.map];let tx=P.x+dx,ty=P.y+dy;
  let e=entAt(tx,ty);
  if(!e&&m.o[ty]&&COUNTERS.has(m.o[ty][tx]))e=entAt(tx+dx,ty+dy);
  if(e){run(async()=>{if(!e.moving)e.dir=OPP[P.dir];if(e.def.client)await talkClient(e.def.client);else await e.def.talk(e);});return;}
  const it=itemAt(tx,ty);if(it){run(()=>pickItem(it));return;}
  run(()=>objectAction(tx,ty));
}
const SIGNS={'town:9,8':'Calle Ribera, 3.\nPiso de la tía Maite.','town:13,8':'GROWSHOP KIKO\nSemillas, abonos y consejos gratis.','town:22,8':'BAR EL ANCLA\nPintxos, kalimotxo y negocios turbios.',
  'town:4,13':'PARQUE DE LOS SAUCES\nProhibido pisar el césped. Nadie hace caso.','town:17,13':'PLAZA DE RIBERA VERDE\nFuente inaugurada en 1987.','town:29,18':'MUELLE VIEJO →\nCuidado con las gaviotas.'};
async function objectAction(x,y){
  const m=MAPS[S.map],o=m.o[y]&&m.o[y][x];
  if(S.map==='home'){
    const pi=huecos().findIndex(h=>h.x===x&&h.y===y);if(pi>=0)return potAction(pi);
    const ci=(m.carpas||[]).findIndex(t=>x>=t.x0&&x<=t.x1&&y>=t.y0&&y<=t.y1);if(ci>=0)return carpaAction(m.carpas[ci].ci);
    if(sitioLibre(x,y))return say('Aquí cabe una carpa de cultivo. Kiko vende carpas de 100×100.');
    if(o==='bedT'||o==='bedB')return bedAction();
    if(o==='pc')return pcAction();
    if(o==='lab'||o==='lab2')return labAction();
    if(o==='table')return letterAction();
    if(o==='fridge')return say('La nevera: medio limón, un kalimotxo y un táper de la tía con alubias.');
    if(o==='plantDeco')return say('Una monstera. La tía Maite le hablaba cada mañana.');
    if(o==='iwin')return say('Por la ventana se ve la ría. Huele a salitre.');
    if(o==='poster')return say('Un póster: «COPA DE RIBERA 1998 · 2º PREMIO: MAITE».');
  }
  if(o==='sign')return say(SIGNS[S.map+':'+x+','+y]||'Está tan desgastado que no se lee.');
  if(o==='bush'){const h=ITEMS.find(it=>it.hidden&&it.map===S.map&&it.x===x&&it.y===y&&!S.taken[it.id]);if(h)return pickItem(h);return;}
  if(o==='fountain')return say('El agua de la fuente está sorprendentemente limpia.');
  if(o==='shelfW')return say('Botes de abono, sustrato de coco... y una pipa de agua con forma de faro.');
  if(o==='display')return say('Sobres de semillas de medio mundo. Algunos no tienen ni nombre.');
  if(o==='bottles')return say('Txakoli, pacharán y una botella sin etiqueta que da miedo.');
  if(o==='jukebox'){sfx('get');return say('La gramola suena: un éxito del rock radikal de los 80.');}
  if(o==='crate')return say('Cajas de pescado. Mejor no abrirlas.');
}


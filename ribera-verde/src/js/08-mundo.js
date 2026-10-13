/* =========================================================
   ESTADO Y MUNDO
   ========================================================= */
let S=null,mode='boot',lock=0,ents=[],B=null,timeAcc=0,hudT=0;
const pending=[],queued=new Set();
const MS_PER_MIN=1000/6;
const P={x:0,y:0,px:0,py:0,dir:'down',moving:false,fx:0,fy:0,t:0,dur:240,parity:0,hold:0,chain:false,bumpT:0};
const DV={up:[0,-1],down:[0,1],left:[-1,0],right:[1,0]},OPP={up:'down',down:'up',left:'right',right:'left'};
const CH_TITLES={1:'La herencia',2:'La calle',3:'La deuda',4:'Genética',5:'El sargento',6:'La Copa de Ribera',7:'Libertad',8:'Tu imperio'};
function newState(){return{v:1,name:'EDDIE',map:'home',x:2,y:4,dir:'down',day:1,min:8*60,money:150,hp:30,hpMax:30,heat:0,rep:0,ch:0,flags:{diario:0,vendDia:1},sales:0,
  seeds:{},buds:{},rosin:{},items:Object.assign({fert:0,fertv:0,phm:0,ofert:0,ofertv:0,ophm:0,medidor:0,insect:0,spray:0,bocata:1,prensa:0,bolsa:0,analizador:0,tarros:0},...Object.keys(MACETAS).map(k=>({['m_'+k]:0})),...Object.keys(FOCOS).map(k=>({['f_'+k]:0})),...Object.keys(EXTRAS).map(k=>({['x_'+k]:0}))),
  carpas:[{t:'p60',foco:'cfl'}],macetas:['plastico7','plastico7'],pots:[null,null],luz:null,protect:false,
  disc:{},custom:{},gen:{},pedido:[],esquejes:[],bandejas:[],fenos:{},fenoN:0,fnom:{},eco:2,debt:DEUDA,due:0,deadline:0,mDay:0,clients:[],clientsDay:0,taken:{},cool:0,steps:0,patxi:0,iDay:0,
  caja:null,rec:{},vencidos:0,protHasta:0,encargo:null,encVeto:0,arcon:{buds:{},rosin:{}},sala:{},fijos:[],sms:[],envio:[],orden:0,misiones:{},itin:{},lonja:0,trueque:0,chatarra:null,
  rel:{},relDia:{},curro:{jard:null,vend:[]},clubs:{},clubDia:{},clubCompra:{},clubEnc:null,clubEncDia:0,catas:{},rivales:{},rivalFuera:{},deco:{},pelea:{xp:0,fue:0,ref:0},plantilla:[],plN:0,nave:null,setas:null,ropa:{},obra:{},logros:{}};}   // la gente (1.15, 11e-gente)
const isFree=()=>mode==='world'&&lock===0&&handlers.length===0;
const isNight=()=>S.min>=21*60||S.min<6*60;
async function run(fn){lock++;try{await fn();}catch(e){console.error(e);}finally{lock--;}if(!lock&&S&&S.misiones)revisaMisiones();}
function queue(key,fn){if(queued.has(key))return;queued.add(key);pending.push(async()=>{try{await fn();}finally{queued.delete(key);}});}
const totalBuds=()=>Object.values(S.buds).reduce((a,b)=>a+b.g,0);
const discCount=()=>Object.keys(S.disc).length;
// variedades de receta (RECIPES) sacadas en la mesa (S.rec[sid] = 1) y ya cosechadas (2): el capítulo 4 pide 2 (1.10)
const recCount=()=>Object.values(S.rec).filter(v=>v===2).length;
// ficha de una variedad: cifras, tipo genético (si es un cruce y qué fenotipos da) y origen
// % índica de la variedad y, en un híbrido propio, lo que sacó de la madre (la 1.ª del cruce, la de la izquierda en «o») y del padre
const lineaInd=k=>{const s=getStrain(k),i=indDe(k);return `Índica ${i} % · sativa ${100-i} %${s.m?` · ${s.m} % madre · ${100-s.m} % padre`:''}`;};
function strainLine(k){const s=getStrain(k),G=GENETICA[tipoGen(k)];return `THC ${pct(s.thc)}% · ~${gm2(s)} g/m² · ${coma(s.d)} días · Resist. ${s.r}%\n${lineaInd(k)}\n${G.n}${PADRES[k]?' ('+PADRES[k]+')':''}: ${G.d}. Estrella: 1 de cada ~${miles(G.uno)}.\n${s.gen?s.gen+'.ª generación · ':''}${s.o}`;}
function discover(sid){if(!S.disc[sid]){S.disc[sid]=true;toast(`<small>NUEVA EN LA GENOTECA${STRAINS[sid]?' · '+DEX.filter(k=>S.disc[k]).length+'/'+DEX.length:''}</small>${esc(getStrain(sid).n)}`);queue('historia',checkStory);}}
function addSeeds(sid,n){S.seeds[sid]=(S.seeds[sid]||0)+n;discover(sid);}
// cogollos por lotes: clave = variedad, o variedad + '*' para lo de un fenotipo estrella (se vende y se presenta aparte)
const lotSid=k=>k.replace(/\*$/,''),lotNombre=k=>getStrain(lotSid(k)).n+(k.endsWith('*')?' ★':'');
function addBuds(k,g,thc,L=S.buds,cu=0,dia=S.day){const b=L[k];if(b){juntaLote(b,g,thc,cu,dia);delete b.cata;delete b.ana;}else{L[k]=Object.assign({g,thc},dia!=null?{dia}:{});if(cu)L[k].cu=cu;}discover(lotSid(k));}   // L: otro sitio (el arcón); cu y dia: el curado y el día de la cosecha (1.29, 09c-sala; sin dar dia, hoy; dia null, sin día, como los de antes)
function useBuds(k,g){const b=S.buds[k];b.g-=g;if(b.g<.5)delete S.buds[k];}
function budLots(min,minThc=0){return Object.entries(S.buds).filter(([k,b])=>b.g>=min&&b.thc>=minThc);}
// rosin (1.10): lo que sale de prensar cogollos en la mesa (prensar, 09-cultivo), por lotes como ellos y al décimo de gramo
const totalRosin=()=>Object.values(S.rosin).reduce((a,b)=>a+b.g,0);
function addRosin(k,g,thc){const b=S.rosin[k];if(b){b.thc=(b.thc*b.g+thc*g)/(b.g+g);b.g=Math.round((b.g+g)*10)/10;}else S.rosin[k]={g,thc};}
function useRosin(k,g){const b=S.rosin[k];b.g=Math.round((b.g-g)*10)/10;if(b.g<.1)delete S.rosin[k];}
const rosinTxt=r=>coma(Math.round(r*10)/10)+' g de rosin';
// lo que llevas encima en gramos de flor: el rosin, como la flor de la que sale (1 g ↔ 1 / ROSIN.rend = 5 g). Ladrones y Darko
const gramosFlor=()=>totalBuds()+totalRosin()/ROSIN.rend;
function rosinLots(min){return Object.entries(S.rosin).filter(([k,b])=>b.g>=min);}
const rosinItem=([k,b])=>({label:'Rosin · '+lotNombre(k),right:`${coma(b.g)} g · ${pct(b.thc)}%`,sw:'#d89a18',ic:iconoCogollo(lotSid(k))});
const lotItem=([k,b])=>({label:lotNombre(k),right:`${Math.floor(b.g)} g · ${pct(b.thc)}%`,sw:getStrain(lotSid(k)).c,ic:iconoCogollo(lotSid(k))});
async function got(t){sfx('get');await say(`Consigues ${t}.`);}

/* ---------- NPCs ---------- */
const NPCDEF=[
  {id:'kiko',map:'shop',x:4,y:2,look:'kiko',talk:()=>talkKiko()},
  // Julen, el hijo de Kiko (1.23, 11h-guia): en el piso, delante del armario, hasta la primera cosecha; después, en el growshop
  {id:'julen',map:'home',x:9,y:3,dir:'left',look:'julen',cond:()=>!!S.flags.kiko1&&!S.flags.harvest1,talk:()=>talkJulen()},
  {id:'julen',map:'shop',x:7,y:2,look:'julen',cond:()=>!!S.flags.harvest1,talk:()=>talkJulen()},
  {id:'josune',map:'bar',x:2,y:2,look:'josune',talk:()=>talkJosune()},
  {id:'baltasar',map:'bar',x:7,y:4,look:'baltasar',talk:()=>talkBaltasar()},
  {id:'tono',map:'bar',x:5,y:4,look:'tono',cond:()=>S.ch>=3&&S.ch<8,talk:()=>say(pick(['Don Baltasar está ocupado. Habla con él si traes el dinero.','Aquí dentro no se hacen preguntas.']),'TOÑO')},
  {id:'begona',map:'town',x:10,y:12,wander:2,look:'begona',talk:()=>talkBegona()},   // 1.15: consejos, regalos y la jardinera (11e-gente),
  {id:'unai',map:'town',x:17,y:18,wander:3,look:'kid',talk:()=>say(pick(['Si mantienes pulsado B, corres.','Mi hermano dice que de noche, en la hierba alta del parque, roban a la gente.','Con START abres tu GENOTECA y la mochila.','En los arbustos del parque la gente esconde cosas. Mira delante de ellos con A.']),'UNAI')},
  {id:'patxi',map:'town',x:21,y:21,dir:'up',look:'oldman',talk:()=>talkPatxi()},
  {id:'txaro',map:'town',x:3,y:18,look:'granny',cond:()=>!S.flags.txaro,talk:()=>talkTxaro()},
  {id:'txaro',map:'txaro',x:6,y:3,look:'granny',cond:()=>!!S.flags.txaro,talk:()=>talkTxaro()},   // después del aceite, en su casa (1.10)
  {id:'inaki',map:'town',x:37,y:21,dir:'left',look:'sailor',cond:()=>S.ch>=2,talk:()=>talkInaki()},
  {id:'cop',map:'town',x:22,y:17,wander:3,look:'cop',cond:()=>S.ch>=2,talk:()=>talkCop()},
  {id:'darko',map:'town',x:20,y:14,dir:'up',look:'darko',cond:()=>(S.ch>=2&&S.ch<7&&!S.flags.darko1)||S.ch===6,talk:()=>talkDarko()},
  {id:'darko2',map:'astilleros',x:24,y:16,look:'darko',cond:()=>S.ch>=7&&!S.flags.darkoFin,talk:()=>talkDarko()},   // sus esquinas (1.10)
  {id:'molina',map:'town',x:23,y:15,look:'molina',cond:()=>S.ch>=5&&!S.flags.molina1,talk:()=>talkMolina()},
  {id:'molina',map:'comisaria',x:4,y:2,look:'molina',cond:()=>S.ch>=5&&!!S.flags.molina1,talk:()=>talkMolina()},   // la cuota, en la comisaría (1.10)
  {id:'tono2',map:'almacen',x:5,y:2,look:'tono',cond:()=>!!S.encargo,talk:()=>talkTonoAlmacen()},   // los encargos de Baltasar (1.10)
  {id:'jurado',map:'town',x:18,y:15,look:'judge',cond:()=>S.ch===6,talk:()=>talkJurado()},
  // la comarca (1.10)
  {id:'vecina',map:'mendialde',x:22,y:21,wander:1,look:'vecina',talk:()=>say(pick(['En Mendialde el autobús para en la plaza. El último sale a las nueve.','Tu ama dice que en la ciudad no comes. Llévate el táper.','Aquí el maíz se siembra en mayo y se recoge en octubre. Como toda la vida.']),'VECINA')},
  {id:'excursionista',map:'errotabarri',x:14,y:14,wander:2,look:'excursionista',talk:()=>say(pick(['El molino tiene trescientos años. Todavía muele algún domingo.','Del puente para arriba, el río baja limpio. Para abajo, ya no tanto.','Vengo en el autobús de Ribera Verde: treinta minutos y tres euros.']),'EXCURSIONISTA')},
  {id:'turista',map:'puerto',x:14,y:11,wander:2,look:'turista',talk:()=>say(pick(['Las casas son de colores para que cada pescador viera la suya desde el mar.','Dicen que en este puerto se paga bien... y que la policía mira poco.','He venido a por anchoas y me han ofrecido de todo.']),'TURISTA')},
  {id:'obrero',map:'valdehierro',x:28,y:14,wander:1,look:'obrero',talk:()=>say(pick(['La fundición cerró hace años. Ahora el solar es del chatarrero.','Aquí la gente cobra poco y paga poco. Y de noche, cuidado con la cartera.','De Valdehierro a Ribera Verde, veinte minutos de autobús.']),'OBRERO')},
];
function mkEnt(d){return{id:d.id,x:d.x,y:d.y,px:d.x*16,py:d.y*16,hx:d.x,hy:d.y,dir:d.dir||'down',look:d.lookObj||LOOKS[d.look],def:d,wander:d.wander||0,wt:800+Math.random()*2400,moving:false,t:0,fx:d.x,fy:d.y};}
function buildEnts(){
  const old={};ents.forEach(e=>old[e.id]=e);ents=[];
  for(const d of NPCDEF){if(d.map!==S.map||(d.cond&&!d.cond()))continue;ents.push(old[d.id]&&old[d.id].def===d?old[d.id]:mkEnt(d));}
  for(const c of S.clients)if((c.map||'town')===S.map){const o=old[c.id];ents.push(o||mkEnt({id:c.id,x:c.x,y:c.y,wander:2,lookObj:c.look,client:c}));}
  for(const e of Object.values(old))if(e.pat&&e.mapa===S.map)ents.push(e);ponPatrullas();   // las patrullas (10b-patrulla)
}
// los sitios con función (1.14, 11d-comarca): la tienda de la ciudad, la lonja, la chatarrería y el molino
NPCDEF.push({id:'ane',map:'growcity',x:4,y:2,look:'ane',talk:()=>talkAne()},{id:'nerea',map:'puerto',x:23,y:17,dir:'down',look:'nerea',talk:()=>talkNerea()},
  {id:'bixente',map:'valdehierro',x:30,y:15,dir:'down',look:'bixente',talk:()=>talkBixente()},{id:'andoni',map:'errotabarri',x:24,y:19,dir:'down',look:'andoni',talk:()=>talkAndoni()},
  {id:'miren',map:'errotabarri',x:24,y:10,dir:'down',look:'miren',cond:()=>S.ch>=MIREN.ch,talk:()=>talkMiren()},   // la amiga de la tía Maite (1.17)
  {id:'ibarbitarra',map:'ensanche',x:22,y:14,wander:2,look:'ibarbitarra',talk:()=>say(pick(['Esto es el Ensanche: pisos, oficinas y el parque. El Casco Viejo, por la avenida.','En Ibarbide hay policía en cada esquina. Y aun así...','Los de los pueblos venís en autobús, ¿no? La estación está en el Casco.']),'VECINO')});
const ITEMS=[
  {id:'i_spray',map:'town',x:8,y:25,give:async()=>{S.items.spray+=2;await got('2 × SPRAY DE PIMIENTA');}},
  {id:'i_fert',map:'town',x:36,y:24,give:async()=>{S.items.fert+=3;await got('3 dosis de MEATZA FLORACIÓN');}},
  {id:'i_boc',map:'town',x:15,y:23,give:async()=>{S.items.bocata+=2;await got('2 × BOCATA');}},
  {id:'h_acap',map:'town',x:2,y:26,hidden:1,give:async()=>{addSeeds('acapulco',2);await got('2 semillas de ACAPULCO GOLD');await say('Un bote de carrete con dos semillas y una etiqueta a boli: «Guerrero, 1979».');}},
  {id:'h_50',map:'town',x:9,y:16,hidden:1,give:async()=>{S.money+=50;await got('50 € en billetes doblados');}},
  {id:'h_ins',map:'town',x:10,y:24,hidden:1,give:async()=>{S.items.insect+=1;await got('1 tratamiento de INSECTICIDA');}},
  {id:'i_ast',map:'astilleros',x:4,y:5,give:async()=>{S.items.spray+=2;await got('2 × SPRAY DE PIMIENTA');}},
  {id:'h_alto',map:'alto',x:2,y:10,hidden:1,give:async()=>{S.money+=80;await got('80 € en un sobre arrugado');}},
  {id:'h_kale',map:'callejon',x:21,y:10,hidden:1,give:async()=>{S.money+=120;await got('120 € en una riñonera abandonada');}},   // la Kale Zaharra (1.14)
  // las semillas que escondió la tía Maite (1.25): landraces que no están en el banco (su nota en el diario dice dónde)
  {id:'h_lamb',map:'puerto',x:37,y:6,hidden:1,give:()=>semillasTia('lamb','Una lata de tabaco oxidada con una etiqueta a boli: «Jamaica». Es la letra de la tía Maite.')},
  {id:'h_kerala',map:'mendialde',x:42,y:11,hidden:1,give:()=>semillasTia('kerala','Un bote de carrete envuelto en plástico: «Kerala, India». Es la letra de la tía Maite.')},
  {id:'h_manga',map:'errotabarri',x:28,y:10,hidden:1,give:()=>semillasTia('mangarosa','Un sobre en una bolsa de congelar: «Manga Rosa · Brasil». Es la letra de la tía Maite.')},
  {id:'h_hawai',map:'ensanche',x:16,y:14,hidden:1,give:()=>semillasTia('hawai','Un tubo de pastillas con semillas dentro: «Hawái». Es la letra de la tía Maite.')},
];
const itemAt=(x,y)=>ITEMS.find(it=>!it.hidden&&it.map===S.map&&it.x===x&&it.y===y&&!S.taken[it.id]);
async function pickItem(it){S.taken[it.id]=true;await it.give();}
async function semillasTia(k,txt,n=2){addSeeds(k,n);await got(`${n} semillas de ${STRAINS[k].n.toUpperCase()}`);return say(txt);}
function tileSolid(m,x,y){
  if(x<0||y<0||x>=m.w||y>=m.h)return true;
  if(SOLID_G.test(m.g[y][x])||m.o[y][x])return true;
  return !!itemAt(x,y);
}
const entAt=(x,y)=>ents.find(e=>(e.x===x&&e.y===y)||(e.moving&&e.fx===x&&e.fy===y));
function enterMap(name,x,y,dir){S.map=name;if(name==='home')montarCasa();Object.assign(P,{x,y,px:x*16,py:y*16,fx:x,fy:y,moving:false,chain:false,hold:0});if(dir)P.dir=dir;S.x=x;S.y=y;S.dir=P.dir;ents=[];resetSosp();buildEnts();music(mapMusic());}
// cada mapa lleva su canción (04-mapas); en la calle, de noche, su versión nocturna (Ribera: night)
const mapMusic=()=>{const m=MAPS[S.map].music;return ZONAS[S.map]&&isNight()?(m==='town'?'night':m+'_n'):m;};
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
  P.fx=P.x;P.fy=P.y;P.x=nx;P.y=ny;P.t=0;P.moving=true;P.pisT=performance.now();P.dur=pasoMs();P.parity^=1;
}
const pasoMs=()=>{const v=vehiculo();return v?VEHICULOS[v].paso[held.B?1:0]:held.B?130:240;};   // ms por casilla: a pie, corriendo o montado (1.13)
function onStepEnd(){
  S.x=P.x;S.y=P.y;S.dir=P.dir;S.steps++;if(S.cool>0)S.cool--;
  const m=MAPS[S.map],door=m.doors[P.x+','+P.y];
  if(door){run(()=>warp(door));return;}
  const Z=ZONAS[S.map];if(!Z)return;
  if(S.map==='town'&&P.y>=13&&P.y<=14&&P.x>=18&&P.x<=22){
    if(S.ch>=2&&S.ch<7&&!S.flags.darko1){queue('darko',async()=>{const e=ents.find(e=>e.id==='darko');if(e)e.dir='up';await talkDarko();});return;}
    if(S.ch>=5&&!S.flags.molina1){queue('molina',talkMolina);return;}
  }
  // ladrones al azar por paso; la policía ya no (1.10): patrulla por la calle (10b-patrulla). Con la alarma, nada
  if(S.ch>=2&&S.cool<=0&&!SOSP.alarma){
    const g=gramosFlor(),tall=m.g[P.y][P.x]==='tallgrass';   // el rosin también atrae ladrones (1.10)
    const pt=(g>=5||S.money>=150)?.004*(isNight()?2.5:1)*(tall?3:1)*Z.lad:0;
    if(Math.random()<pt){S.cool=25;run(()=>battle('thief'));}
  }
}
function updateEnts(dt){
  const free=isFree(),m=MAPS[S.map];
  for(const e of ents){
    if(e.pat)continue;   // las patrullas andan en updatePatrullas
    if(e.moving){e.t+=dt;const k=Math.min(1,e.t/320);e.px=(e.fx+(e.x-e.fx)*k)*16;e.py=(e.fy+(e.y-e.fy)*k)*16;if(k>=1){e.moving=false;e.fx=e.x;e.fy=e.y;}continue;}
    if(!free||!e.wander)continue;e.wt-=dt;if(e.wt>0)continue;e.wt=1200+Math.random()*2600;
    const d=pick(['up','down','left','right']);e.dir=d;const [dx,dy]=DV[d],nx=e.x+dx,ny=e.y+dy;
    if(Math.abs(nx-e.hx)>e.wander||Math.abs(ny-e.hy)>e.wander)continue;
    if(tileSolid(m,nx,ny)||entAt(nx,ny)||(nx===P.x&&ny===P.y)||(P.moving&&nx===P.fx&&ny===P.fy)||m.doors[nx+','+ny]||m.exits[nx+','+ny]||(PARADAS[S.map]&&PARADAS[S.map].a[0]===nx&&PARADAS[S.map].a[1]===ny))continue;   // ni en la llegada del autobús (1.10)
    e.fx=e.x;e.fy=e.y;e.x=nx;e.y=ny;e.t=0;e.moving=true;
  }
}
function worldPress(b){
  if(mode==='title'){titlePress(b);return;}
  if(!isFree()||P.moving)return;
  if(b==='A')interact();else if(b==='START')run(startMenu);else if(b==='MOVIL')run(movilMenu);
}
// la casilla de delante; si es una silla (1.27.1), la de encima, desde cualquier lado: el ordenador que tiene delante
function delante(){const [dx,dy]=DV[P.dir],m=MAPS[S.map];let tx=P.x+dx,ty=P.y+dy;if(m.o[ty]&&SILLAS.has(m.o[ty][tx]))ty--;return [tx,ty];}
function interact(){
  const [dx,dy]=DV[P.dir],m=MAPS[S.map],[tx,ty]=delante();
  let e=entAt(tx,ty);
  if(!e&&m.o[ty]&&COUNTERS.has(m.o[ty][tx]))e=entAt(tx+dx,ty+dy);
  if(e){run(async()=>{if(!e.moving)e.dir=OPP[P.dir];if(e.def.client)await talkClient(e.def.client);else{await e.def.talk(e);if(!e.pat)saludo(e.id.startsWith('club_')?e.id.slice(5):e.id==='darko2'?'darko':e.id);}});return;}
  const it=itemAt(tx,ty);if(it){run(()=>pickItem(it));return;}
  run(()=>objectAction(tx,ty));
}
const SIGNS={'town:9,8':'Calle Ribera, 3.\nPiso de la tía Maite.','town:13,8':'GROWSHOP KIKO\nSemillas, abonos y consejos gratis.','town:22,8':'BAR EL ANCLA\nPintxos y menú del día.',
  'town:4,13':'PARQUE DE LOS SAUCES\nHorario: de 7:00 a 23:00.','town:17,13':'PLAZA DE RIBERA VERDE\nFuente inaugurada en 1987.','town:29,18':'MUELLE VIEJO →\nPeligro: borde sin barandilla.',
  'town:10,4':'↑ BARRIO ALTO\nPlaza del Ensanche · Comisaría.','town:38,19':'ASTILLEROS DE RIBERA →\nZona industrial. Sin salida.',
  'alto:10,18':'PLAZA DEL ENSANCHE\nUrbanizada en 1964.','alto:22,7':'JARDINES DEL ENSANCHE\nNo pisar el césped.','alto:23,19':'COMISARÍA DE RIBERA\nAtención al público: de 9:00 a 14:00.',
  'astilleros:15,13':'ALMACÉN 3\nPropiedad privada. Prohibido el paso.','astilleros:2,18':'ASTILLEROS DE RIBERA\nCerrados desde 1992.',
  'mendialde:2,19':'MENDIALDE\nCaseríos, huertas y la parada del autobús.','puerto:2,9':'PUERTO VIEJO\nCofradía de pescadores desde 1890.',
  'valdehierro:2,8':'VALDEHIERRO\nCiudad del hierro desde 1911.','valdehierro:27,12':'CHATARRERÍA DEL SOLAR\nCompro y vendo. Material de segunda mano.',
  'errotabarri:2,10':'ERROTABARRI\nEl pueblo del molino.','errotabarri:26,18':'ERROTA ZAHARRA\nMolino harinero del siglo XVIII. Semillas viejas: pregunta por Andoni.',
  'puerto:25,15':'LONJA DE PUERTO VIEJO\nSubasta de madrugada. Cargas para los barcos de fuera.',
  'ibarbide:13,9':'GROW IBARBIDE\nTodo para el cultivo, a precio de ciudad.','ibarbide:12,19':'PLAZA NUEVA\nCasco Viejo de Ibarbide.','ibarbide:41,20':'ENSANCHE →\nAvenida de la Estación.',
  'ibarbide:21,8':'↑ KALE ZAHARRA\nPor el callejón.','callejon:8,10':'KALE ZAHARRA\nLa calle vieja. Aquí no entra la patrulla.',
  'ensanche:2,12':'IBARBIDE · ENSANCHE\n← Casco Viejo y estación de autobuses.'};
async function objectAction(x,y){
  const m=MAPS[S.map],o=m.o[y]&&m.o[y][x];
  if(S.map==='home'){
    const t=(m.carpas||[]).find(t=>x>=t.x0&&x<=t.x1&&y===t.y);if(t)return abrirCarpa(t.ci);
    const sl=sitioLibre(x,y);
    if(sl>=0)return say(sl===2?'Hueco junto a la cama: aquí cabe una carpa de 120×120.'+(S.ch<5?' Kiko las tendrá más adelante.':' Kiko las vende.'):'Aquí cabe una carpa de cultivo. Kiko vende carpas de 100×100.');
    if(o==='bedT'||o==='bedB')return bedAction();
    if(o==='pc')return pcAction();
    if(o==='lab'||o==='lab2')return labAction();
    if(o==='table')return letterAction();
    if(o==='fridge'){if(S.flags.nevera)return say('La nevera: medio limón, leche y un táper de alubias que dejó la tía.');   // 1.25: el bote de la tía
      S.flags.nevera=S.day;await say('Detrás del táper de alubias hay un bote de cristal con una etiqueta: «Choco Thai. NO TOCAR».');return semillasTia('choco','El frío las ha conservado: siguen buenas.',3);}
    if(o==='crate')return arconAction();
    if(muebleDe(o))return muebleAction(muebleDe(o));
    {const k=Object.keys(MUEBLES).find(k=>(x===MUEBLES[k].x||!MUEBLES[k].uno&&x===MUEBLES[k].x+1)&&y===MUEBLES[k].y&&!(MUEBLES[k].suelo&&mueblesYa().includes(k)));   // el sitio vacío de un mueble del salón (la alfombra puesta no es un objeto: nada)
      if(k&&(!MUEBLES[k].grow||S.muebles&&S.muebles[k]))return say(S.muebles&&S.muebles[k]?`Aquí va ${MUEBLES[k].art}: llega mañana.`:`Aquí iría bien ${MUEBLES[k].art}. Se compra por internet: en el ordenador de la tía o con el móvil.`);}
    if(o==='plantDeco')return say('Una monstera. La tía Maite le hablaba cada mañana.');
    if(o==='iwin')return say('Por la ventana se ve la ría. Huele a salitre.');
    if(o==='poster')return diplomaAction();
  }
  if(S.map==='txaro'){
    if(o==='bedT'||o==='bedB')return say('Una cama con colcha de ganchillo.');
    if(o==='table')return say('Un bote de aceite con una etiqueta a mano: «Para dormir. 2 gotas».');
    if(o==='fridge')return say('Nevera de las de antes. No es tuya.');
    if(o==='iwin')return say('Por la ventana se ve el parque de los Sauces.');
  }
  if(S.map==='casa-ama'){   // el caserío de la familia, en Mendialde (1.10)
    if(o==='table'){const n=!S.flags.notaAma;S.flags.notaAma=true;return say(n?'Una nota de tu ama: «Te he dejado un táper de alubias en la nevera. Llama cuando llegues. Y no te metas en líos».':'La nota de ama: «...y no te metas en líos».');}
    if(o==='fridge'){if(S.flags.taper)return say('La nevera de casa. El táper ya va en la mochila.');S.flags.taper=true;S.items.bocata+=1;return got('el táper de alubias de ama (1 × BOCATA)');}
    if(o==='bedT'||o==='bedB')return bedAction('Tu cama de siempre, con la colcha de cuadros.');   // si pierdes el último autobús
    if(o==='iwin')return say('Por la ventana se ven el monte y la carretera de la comarca.');
    if(o==='plantDeco')return say('Los geranios de ama. Les sobra agua.');
  }
  if(S.map==='comisaria'){
    if(o==='iwin')return say('Por la ventana se ve la plaza del Ensanche.');
    if(o==='shelfW')return say('Archivadores con expedientes. Hay uno con tu calle.');
    if(o==='counter')return say('El mostrador de denuncias. No hay nadie detrás.');
  }
  if(S.map==='almacen'){
    if(o==='crate')return say('Cajas precintadas con el sello de una conservera que cerró hace años.');
    if(o==='btable')return say('Una mesa con una báscula y rollos de film transparente.');
  }
  if(o==='sign')return say(SIGNS[S.map+':'+x+','+y]||'Está tan desgastado que no se lee.');
  if(o==='parada')return paradaAction();
  if(o==='bush'){const h=ITEMS.find(it=>it.hidden&&it.map===S.map&&it.x===x&&it.y===y&&!S.taken[it.id]);if(h)return pickItem(h);return;}
  if(o==='fountain')return say('La fuente de la plaza. Lleva años sin agua potable.');
  if(o==='shelfW')return say('Botes de abono, sustrato de coco y medidores de pH.');
  if(o==='display')return say('Sobres de semillas de bancos de todo el mundo, ordenados por tipo.');
  if(o==='bottles')return say('Txakoli, pacharán y orujo casero.');
  if(o==='jukebox'){sfx('get');return say('La gramola suena: rock vasco de los 80.');}
  if(o==='crate')return say(S.map==='astilleros'?'Cajas de madera de los astilleros, podridas por la humedad.':S.map==='valdehierro'?'Cajas de piezas de la fundición, oxidadas.':S.map==='callejon'?'Cajas de fruta vacías. La frutería de la esquina cerró en verano.':'Cajas de pescado vacías del puerto.');
}
// el autobús de la comarca (1.10): en el poste de la parada, a dónde, cuánto y cuánto tarda; el reloj corre lo que dura el viaje.
// El primer viaje (del pueblo al piso: S.flags.llegada === false) lo paga ama y solo va a Ribera Verde. Fuera de horario, esperar
// al primero o, en Mendialde, dormir en casa de ama (bedAction)
async function paradaAction(){
  const aqui=S.map,pa=PARADAS[aqui];
  if(S.min<BUS_HORAS[0]||S.min>BUS_HORAS[1]){   // fuera de horario: se puede esperar al primero (el reloj corre hasta las 7:00)
    if(await ask(`PARADA DE ${pa.n.toUpperCase()}\nEl primer autobús pasa a las 7:00 y el último, a las 21:00.`,['Esperar al de las 7:00','Nada'])!==0)return;
    await fade(1);advanceTime((BUS_HORAS[0]-S.min+1440)%1440);buildEnts();updateHUD();await wait(300);await fade(0);
    await say('Las siete. Llega el primer autobús, medio vacío.');
  }
  const ama=S.flags.llegada===false,ds=ama?['town']:Object.keys(PARADAS).filter(k=>k!==aqui&&S.ch>=PARADAS[k].cap);   // las líneas, por capítulos (1.14)
  const i=await menu(ds.map(k=>{const v=viaje(aqui,k);return{label:PARADAS[k].n,right:ama?'billete de ama':`${eur(v.eur)} · ${v.min} min`};}).concat([{label:'Nada'}]),{cls:'right',title:'¿A dónde vas?'});
  if(i<0||i>=ds.length)return;
  const k=ds[i],v=viaje(aqui,k);
  if(!ama){if(S.money<v.eur)return say(`El billete hasta ${PARADAS[k].n} cuesta ${eur(v.eur)}. No te llega.`);S.money-=v.eur;}
  sfx('door');await fade(1);advanceTime(v.min);enterMap(k,...PARADAS[k].a);if(S.clientsDay!==S.day)spawnClients();updateHUD();await wait(80);await fade(0);
  if(ama){S.flags.llegada=true;await say('Ribera Verde. El piso de la tía es el del tejado rojo, al otro lado de la calle.');showObjective();}
}


/* =========================================================
   LOS LOCALES (1.30): los clubs por dentro, la nave y GAUA
   ========================================================= */
// Los clubs (CLUBS, 11e-gente), la nave de Valdehierro (NAVE, 11f-plantilla) y la discoteca GAUA, en el Ensanche, son sitios a los
// que se entra como a una casa (entraLocal, desde la puerta). En el club: el dispensario (el encargado, detrás de la vitrina), los
// sofás con su mesa baja y un socio con el que compartir (SOCIO), y el billar bajo la lámpara, con apuesta (BILLAR). En la nave: las
// cuatro mesas de cultivo (una por trabajador; plantas tú, con semilla o esqueje, y eliges su abono), la estantería de los abonos, el
// secadero y el escritorio. En GAUA (DISCO: de 23:00 a 6:00, desde el capítulo DISCO.ch; la entrada, una vez por noche): la barra,
// la pista, la cabina del DJ y el reservado, donde la RRPP te presenta un cliente VIP para la agenda (CTYPES.vip)
const BILLAR={apuestas:[10,20,50],tiros:3,dia:3,min:20,hab:.55,verde:.08,amarillo:.2,centro:.7,periodo:1400,n:{puerto:'Ander',valde:'Izaskun',ibar:'Txetxu',ens:'Olatz'}};
const SOCIO={g:1,rel:3,min:30,n:{puerto:'Gotzon',valde:'Maribel',ibar:'Joseba',ens:'Lorea'},
  charla:['Aquí cada socio retira lo suyo y se consume dentro. Así funciona una asociación.','Los sábados se llena. Entre semana se está mejor.',
    'Dicen que el del billar no ha perdido una partida este año. Yo no me lo creo.','El encargado prueba todo lo que entra. Si no le convence, no entra.']};
const DISCO={n:'GAUA',ch:4,abre:23*60,cierra:6*60,entrada:15,copa:10,copaMax:3,ronda:40,mesa:300,ligar:.5,vip:['Kepa','Garbiñe','Aitor','Nekane','Borja','Ainhoa']};
const MESAS_X=[1,4,8,11],FASE_MESA=['vacía','recién plantada','creciendo','en flor','dando cogollos'];
// la mitad de la derecha de los muebles de 2 casillas de los locales: la pinta la de la izquierda (01b-arte)
const LOCAL2=new Set(['billar2','sofaF2','sofaV2','sofaB2','cabina2','escritorio2','mesaN2']);
// la luz de los locales (luzLocal, 14-render): el club, en penumbra cálida, con la lámpara del billar y el brillo de la vitrina
// ([x, y, radio, color, alfa], en px del mapa); GAUA, oscura, con tres focos de colores que giran sobre la pista (centro c, radios r)
const LUZ_CLUB={fondo:'rgba(24,14,4,.28)',l:[[144,70,30,'255,206,120',.6],[24,56,22,'200,240,255',.35]]};
const LUZ_DISCO={fondo:'rgba(10,4,30,.55)',focos:[['255,79,200',0],['64,224,240',2.1],['240,208,64',4.2]],c:[120,88],r:[30,14],R:26};
function mapasLocales(){
  // ---------- LOS CLUBS: 12 × 8, el dispensario a la izquierda, los sofás en medio y el billar a la derecha ----------
  for(const k in CLUBS){const C=CLUBS[k],m=newMap('club-'+k,12,8,'floorC');m.music='club';
    rect(m,0,0,11,0,(x,y)=>gr(m,x,y,'iwT_club'));rect(m,0,1,11,1,(x,y)=>gr(m,x,y,'iwB_club'));
    [[0,'tarros'],[1,'pizarra'],[2,'tarros'],[4,'cartelC'],[7,'poster'],[10,'tacos']].forEach(([x,o])=>ob(m,x,1,o));
    rect(m,0,3,2,3,(x,y)=>ob(m,x,y,'vitrina'));ob(m,3,2,'plantDeco');
    ob(m,5,2,'sofaF');ob(m,6,2,'sofaF2');ob(m,5,3,'mesita');ob(m,6,3,'mesita');ob(m,5,4,'sofaB');ob(m,6,4,'sofaB2');
    ob(m,8,4,'billar');ob(m,9,4,'billar2');ob(m,11,2,'jukebox');ob(m,0,6,'plantDeco');ob(m,11,6,'plantDeco');
    [5,6].forEach(x=>{gr(m,x,7,'mat');m.exits[x+',7']={to:C.map,x:C.x+(C.ancha?x-5:0),y:C.y,dir:'down'};});}
  // ---------- LA NAVE: 14 × 8, las cuatro mesas en fila; la estantería, el secadero y el escritorio al fondo ----------
  const n=newMap('nave',14,8,'floorN');n.music='nave';
  rect(n,0,0,13,0,(x,y)=>gr(n,x,y,'iwT_nave'));rect(n,0,1,13,1,(x,y)=>gr(n,x,y,'iwB_nave'));
  ob(n,0,2,'estanteN');ob(n,6,2,'secadero');ob(n,11,2,'escritorio');ob(n,12,2,'escritorio2');ob(n,13,2,'crate');
  MESAS_X.forEach(x=>{ob(n,x,4,'mesaN');ob(n,x+1,4,'mesaN2');});
  [6,7].forEach(x=>{gr(n,x,7,'mat');n.exits[x+',7']={to:'valdehierro',x:x+6,y:8,dir:'down'};});
  // ---------- GAUA: 14 × 8, la barra a la izquierda, la cabina y la pista en medio y el reservado a la derecha ----------
  const d=newMap('disco',14,8,'floorD');d.music='disco';
  rect(d,0,0,13,0,(x,y)=>gr(d,x,y,'iwT_disco'));rect(d,0,1,13,1,(x,y)=>gr(d,x,y,'iwB_disco'));rect(d,5,4,9,6,(x,y)=>gr(d,x,y,'baile'));
  rect(d,0,1,2,1,(x,y)=>ob(d,x,y,'bottles'));ob(d,3,1,'neon');ob(d,11,1,'neon');rect(d,0,3,3,3,(x,y)=>ob(d,x,y,'barraD'));
  ob(d,5,2,'altavoz');ob(d,8,2,'altavoz');ob(d,6,3,'cabina');ob(d,7,3,'cabina2');
  ob(d,11,2,'sofaV');ob(d,12,2,'sofaV2');ob(d,11,3,'mesaV');ob(d,12,3,'mesaV');ob(d,11,4,'cordon');ob(d,12,4,'cordon');ob(d,13,4,'cordonF');
  [6,7].forEach(x=>{gr(d,x,7,'mat');d.exits[x+',7']={to:'ensanche',x:x+32,y:9,dir:'down'};});
}
// la gente de los locales: en cada club, un socio en los sofás y el del billar; en la nave, cada trabajador junto a su mesa; en GAUA,
// el portero (fuera), la camarera, el DJ, la RRPP y tres en la pista
Object.keys(CLUBS).forEach((k,i)=>NPCDEF.push({id:'socio',map:'club-'+k,x:7,y:3,dir:'left',look:i%2?'socia':'socio',talk:()=>talkSocio(k)},
  {id:'billarista',map:'club-'+k,x:10,y:4,dir:'left',look:i%2?'billarista2':'billarista',talk:()=>talkBillar(k)}));
MESAS_X.forEach((x,i)=>NPCDEF.push({id:'nv'+i,map:'nave',x,y:5,dir:'up',look:'navero'+(i+1),cond:()=>!!(S.nave&&naveros()[i]),talk:()=>talkNavero(i)}));
NPCDEF.push({id:'gorila',map:'ensanche',x:40,y:9,dir:'left',look:'gorila',cond:()=>S.ch>=DISCO.ch,talk:()=>talkGorila()},
  {id:'camarera',map:'disco',x:1,y:2,look:'camarera',talk:()=>talkBarra()},{id:'dj',map:'disco',x:6,y:2,look:'dj',talk:()=>talkDJ()},
  {id:'rrpp',map:'disco',x:12,y:5,look:'rrpp',talk:()=>talkRRPP()},
  ...[[5,5],[8,5],[7,4]].map(([x,y],i)=>({id:'baila'+(i+1),map:'disco',x,y,wander:1,look:'baila'+(i+1),talk:()=>talkBaila(i)})));
// de quién es la confianza que suma hablar con alguien (saludo, 08-mundo): el club del encargado, del socio y del del billar; GAUA,
// la de su gente; los de la nave, ninguna (son de tu plantilla)
const relDe=id=>id.startsWith('club_')?id.slice(5):id==='socio'||id==='billarista'?S.map.slice(5):id==='darko2'?'darko':/^(gorila|camarera|dj|rrpp|baila\d)$/.test(id)?'gaua':/^nv\d$/.test(id)?null:id;
// la puerta de un local (onStepEnd, 08-mundo): cerrada, te deja delante; el club, la primera vez, el carné; GAUA, la entrada de la noche
async function entraLocal(d){
  const [t,k]=d.gate.split(':'),cerrada=async txt=>{atrasPuerta();await say(txt);};
  if(t==='club'){if(S.ch<CLUBS[k].ch)return cerrada('Una puerta sin rótulo, con un timbre. No abre nadie.');if(!S.clubs[k]){atrasPuerta();if(!await carneClub(k))return;}}
  else if(t==='nave'){if(!S.nave)return cerrada('La persiana está echada con un candado. La llave la tiene Arrieta, el dueño.');}
  else if(t==='disco'){if(S.ch<DISCO.ch||!discoAbierta())return cerrada(`${DISCO.n} abre de 23:00 a 6:00.`);if(!nocheYa()){atrasPuerta();if(!await entradaDisco())return;}}
  return warp(d);
}
function atrasPuerta(){const y=P.y+1;Object.assign(P,{fy:y,y,py:y*16,dir:'down'});S.y=y;S.dir='down';}
// lo que hay dentro de los locales (objectAction, 08-mundo); null si no es de un local
function objLocal(x,y,o){
  if(!o)return null;
  if(S.map.startsWith('club-')){const k=S.map.slice(5),C=CLUBS[k];
    if(o==='tarros')return say('Tarros de cristal con la etiqueta de cada variedad que ha pasado por el club.');
    if(o==='pizarra')return say(`En la pizarra, a tiza: «Hoy, ${STRAINS[C.sid[S.day%C.sid.length]].n}».`);
    if(o==='cartelC')return say(`NORMAS DE ${C.n}\nSolo socios mayores de edad, con el carné a la vista. Lo que se retira, se consume dentro.`);
    if(o==='tacos')return say('El taquero: seis tacos, la tiza y el triángulo.');
    if(o==='vitrina')return say('La vitrina del dispensario: tarros con muestras y una báscula de precisión.');
    if(o==='mesita')return say('Una mesa baja con un cenicero, un grinder y un librillo.');
    if(/^sofa[FB]2?$/.test(o))return say('Un sofá chester de cuero verde, gastado de tanto uso.');
    if(o==='billar'||o==='billar2')return say(`La mesa de billar, con el tapete recién cepillado. ${BILLAR.n[k]} juega con apuesta.`);
    if(o==='poster')return say('Un cartel antiguo de una feria del cáñamo.');
    if(o==='plantDeco')return say('Una kentia en una maceta de barro.');
  }
  if(S.map==='nave'){
    if(!S.nave)return say('La nave está vacía.');
    if(o==='mesaN'||o==='mesaN2')return mesaNave(MESAS_X.indexOf(o==='mesaN'?x:x-1));
    if(o==='estanteN')return estanteNave();
    if(o==='secadero')return secaderoNave();
    if(o==='escritorio'||o==='escritorio2')return escritorioNave();
    if(o==='crate')return say('Sacos de sustrato y macetas apiladas.');
  }
  if(S.map==='disco'){
    if(o==='bottles')return say('Botellas de ginebra, ron y vodka, iluminadas desde abajo.');
    if(o==='neon')return say(`El neón de ${DISCO.n}: la luna rosa.`);
    if(o==='altavoz')return say('El altavoz retumba en el pecho.');
    if(o==='cabina'||o==='cabina2')return say('La cabina del DJ: dos platos y la mesa de mezclas.');
    if(o==='sofaV'||o==='sofaV2'||o==='mesaV')return say('El reservado: sofá de terciopelo y una cubitera en la mesa.');
    if(o==='cordon'||o==='cordonF')return say('El cordón del reservado. Lo abre la RRPP.');
  }
  return null;
}

/* ---------- el club: el socio y el billar ---------- */
async function talkSocio(k){
  const n=SOCIO.n[k],N=n.toUpperCase();
  const c=await ask(pick(['¿Qué tal? Siéntate, hay sitio.','Aquí se está tranquilo, ¿eh?']),['Charlar','Compartir uno','Nada'],N);
  if(c===0)return say(pick(SOCIO.charla),N);
  if(c!==1)return;
  if(S.porro[k]===S.day)return say('Hoy ya hemos compartido. Mañana, más.',N);
  const lots=budLots(SOCIO.g);if(!lots.length)return say(`Cuando tengas algo encima, lo compartimos. Con ${gTxt(SOCIO.g)} vale.`,N);
  const i=await menu(lots.map(lotItem).concat([{label:'Nada'}]),{cls:'right',title:'¿Qué compartes?'});if(i<0||i>=lots.length)return;
  const [kk,b]=lots[i],thc=b.thc;useBuds(kk,SOCIO.g);S.porro[k]=S.day;confia(k,SOCIO.rel);advanceTime(SOCIO.min);updateHUD();sfx('sel');
  return say(`Compartes ${lotNombre(kk)} en el sofá. ${n}: «${thc>=20?'Esto es otra liga. Se lo cuento a los del club.':'Suave, de los de charlar. Gracias.'}»`);
}
// el billar: hasta BILLAR.dia partidas al día con cada uno, de BILLAR.tiros tiros. Cada tiro, la barra de fuerza va y viene: con A
// en el verde, la bola dentro (3 puntos); en el amarillo, la rozas (1). El otro mete con BILLAR.hab × 0,6 y la roza hasta BILLAR.hab
let TIRO=null;   // la barra mientras apuntas: {t0}
const fuerzaTiro=ms=>{const f=ms%BILLAR.periodo/BILLAR.periodo;return f<.5?f*2:2-f*2;};
const puntosTiro=p=>{const d=Math.abs(p-BILLAR.centro);return d<=BILLAR.verde?3:d<=BILLAR.amarillo?1:0;};
const tiroRival=()=>{const r=Math.random();return r<BILLAR.hab*.6?3:r<BILLAR.hab?1:0;};
// un tiro: el texto y, con A, dónde estaba la barra (de 0 a 1); las pruebas lo cambian por una función
async function tiroBillar(txt){
  await typeText(txt,'BILLAR');
  const p=await new Promise(res=>{TIRO={t0:performance.now()};push(b=>{if(b==='A'){pop();res(fuerzaTiro(performance.now()-TIRO.t0));}});});
  TIRO=null;dlg.hidden=true;sfx('hit');return p;
}
async function talkBillar(k){
  const n=BILLAR.n[k],N=n.toUpperCase();
  const D=S.billar[k]&&S.billar[k].d===S.day?S.billar[k]:(S.billar[k]={d:S.day,n:0});
  if(D.n>=BILLAR.dia)return say('Por hoy ya está bien. Mañana te doy la revancha.',N);
  const c=await ask(`¿Unas bolas? ${BILLAR.tiros} tiros cada uno: la bola dentro, 3 puntos; si la rozas, 1. Quien sume más se lleva la apuesta.`,BILLAR.apuestas.map(e=>'A '+eur(e)).concat(['Nada']),N);
  if(c<0||c>=BILLAR.apuestas.length)return;
  const e=BILLAR.apuestas[c];if(S.money<e){sfx('bad');return say('Sin dinero encima no se juega.',N);}
  D.n++;let yo=0,el=0;const T=['Fallas','La rozas: 1 punto','¡Dentro! 3 puntos'],R=['falla','la roza','¡dentro!'];
  for(let i=0;i<BILLAR.tiros;i++){
    const p=puntosTiro(await tiroBillar(`Tiro ${i+1} de ${BILLAR.tiros} · tú ${yo}, ${n} ${el}. Pulsa A con la barra en el verde.`)),q=tiroRival();yo+=p;el+=q;
    await say(`${T[[0,1,3].indexOf(p)]}. ${n}: ${R[[0,1,3].indexOf(q)]}.`);
  }
  if(yo>el){S.money+=e;confia(k,1);sfx('coin');}else if(yo<el){S.money-=e;sfx('bad');}
  advanceTime(BILLAR.min);updateHUD();
  return say(yo>el?`${yo} a ${el}: ganas tú. ${n} te paga ${eur(e)}: «La próxima, la revancha».`:yo<el?`${yo} a ${el}: gana ${n}. Le pagas ${eur(e)}.`:`${yo} a ${el}: empate. Nadie paga.`);
}

/* ---------- la nave: mesas, estantería, secadero y escritorio ---------- */
// S.nave: {m: las NAVE.max mesas (null, vacía, o {k: el lote, f: el fenotipo, thc, y: × cosecha, dia: el de plantar, g y t: lo que hay
// en el secadero y su THC medio, abo: 0 sin abono, 1 MEATZA, 2 ORTUA BIO}), ab: {m, o}: dosis de floración de cada marca en la estantería}
const naveNueva=()=>({m:Array(NAVE.max).fill(null),ab:{m:0,o:0}});
const naveStock=()=>S.nave?S.nave.m.reduce((a,M)=>a+(M?M.g:0),0):0;
function faseMesa(i){const M=S.nave&&S.nave.m[i];if(!M)return 0;const d=S.day-M.dia;return d<1?1:d<3?2:d<NAVE.crece?3:4;}
const thcNave=(sid,f)=>Math.round(getStrain(sid).thc*(f?f.t:1)*NAVE.thc*10)/10;
const ABONO_MESA=['sin abono','MEATZA','ORTUA BIO'];
const mesaTxt=M=>getStrain(lotSid(M.k)).n+etiq(M.f);
async function mesaNave(i){
  const N=S.nave,M=N.m[i],w=naveros()[i],ops=[M?'Arrancar y plantar':'Plantar'].concat(M?['Abono']:[],['Nada']);
  const op=ops[await ask(`Mesa ${i+1} · ${M?mesaTxt(M)+' · '+FASE_MESA[faseMesa(i)]+' · '+ABONO_MESA[M.abo]:'vacía'}\n${w?'La cuida '+w.n+'.':'Nadie la cuida: pon a alguien de tu plantilla en la nave.'}`,ops)];
  if(op==='Plantar'||op==='Arrancar y plantar'){if(M&&M.g>=1)return say('Antes, descuelga del secadero lo de esta mesa.');return plantarMesa(i);}
  if(op==='Abono'){const c=await ask(`¿Qué abono le echa cada día? En la estantería: MEATZA ×${N.ab.m} · ORTUA BIO ×${N.ab.o}.`,['Sin abono','MEATZA Floración','ORTUA BIO Floración','Nada']);
    if(c<3){M.abo=c;sfx('sel');}}
}
// con una semilla o un esqueje, tu gente saca una madre y llena la mesa de clones: toda la mesa, con su fenotipo
async function plantarMesa(i){
  const own=Object.entries(S.seeds).filter(([,v])=>v>0),esq=S.esquejes.map(e=>[e,S.esquejes]).concat(S.bandejas.map(e=>[e,S.bandejas]));
  if(!own.length&&!esq.length)return say('No llevas semillas ni esquejes.');
  const items=own.map(([k,v])=>({label:getStrain(k).n,right:'×'+v,sw:getStrain(k).c,ic:iconoCogollo(k),desc:strainLine(k)}))
    .concat(esq.map(([e,l])=>{const s=getStrain(e.sid);return {label:'Esqueje '+s.n+etiq(e.f),right:l===S.bandejas?'bandeja':'esqueje',sw:s.c,ic:iconoCogollo(e.sid),desc:'Clon enraizado: la mesa entera sale con su fenotipo.'};}))
    .concat([{label:'Cancelar',desc:''}]);
  const j=await menu(items,{cls:'full',title:'¿QUÉ PLANTAS EN LA MESA?',desc:true});
  if(j<0||j>=own.length+esq.length)return;
  let sid,f;
  if(j<own.length){sid=own[j][0];S.seeds[sid]--;if(!S.seeds[sid])delete S.seeds[sid];f=rollFeno(sid);}
  else{const [e,l]=esq[j-own.length];l.splice(l.indexOf(e),1);sid=e.sid;f=e.f;}
  S.nave.m[i]={k:sid+(claseFeno(f)==='estrella'?'*':''),f,thc:thcNave(sid,f),y:f.y,dia:S.day,g:0,t:0,abo:0};sfx('sel');
  return say(`Mesa ${i+1}: ${getStrain(sid).n}${etiq(f)}. De la madre salen los clones para toda la mesa. A los ${NAVE.crece} días empieza a dar.`);
}
async function estanteNave(){
  const N=S.nave,ops=(S.items.fert?[`Dejar MEATZA ×${S.items.fert}`]:[]).concat(S.items.ofert?[`Dejar ORTUA BIO ×${S.items.ofert}`]:[],['Nada']);
  const op=ops[await ask(`La estantería de los abonos: MEATZA FLORACIÓN ×${N.ab.m} · ORTUA BIO FLORACIÓN ×${N.ab.o}. Cada mesa con abono gasta una dosis al día.`,ops)];
  if(op&&op.startsWith('Dejar MEATZA')){N.ab.m+=S.items.fert;S.items.fert=0;sfx('sel');}
  else if(op&&op.startsWith('Dejar ORTUA')){N.ab.o+=S.items.ofert;S.items.ofert=0;sfx('sel');}
}
// descolgar del secadero lo que quepa en la mochila, mesa por mesa (cada una, su lote, sin curar)
async function secaderoNave(){
  if(naveStock()<1)return say(`El secadero está vacío. Cada mesa da cada mañana, a los ${NAVE.crece} días de plantarla.`);
  let lleva=0;const cabe=Math.floor(libreMochila());
  for(const M of S.nave.m){if(!M||M.g<1)continue;const q=Math.min(Math.floor(M.g),cabe-lleva);if(q<1)break;addBuds(M.k,q,M.t);M.g=Math.round((M.g-q)*10)/10;lleva+=q;}
  if(!lleva)return say('No te cabe nada más en la mochila.');
  sfx('get');updateHUD();return say(`Descuelgas ${gTxt(lleva)} del secadero.`+(naveStock()>=1?` Quedan ${gTxt(naveStock())}: no te caben.`:''));
}
async function escritorioNave(){
  const N=S.nave,rows=N.m.map((M,i)=>{const w=naveros()[i];return {label:`Mesa ${i+1} · ${M?getStrain(lotSid(M.k)).n:'vacía'}`,right:M?FASE_MESA[faseMesa(i)]:'',
    desc:`${w?'La cuida '+w.n:'Nadie la cuida'}.`+(M?` ${ABONO_MESA[M.abo][0].toUpperCase()+ABONO_MESA[M.abo].slice(1)} · en el secadero, ${gTxt(M.g)}.`:'')};});
  rows.push({label:'Estantería',right:`${N.ab.m} + ${N.ab.o} dosis`,desc:'MEATZA FLORACIÓN y ORTUA BIO FLORACIÓN: una dosis al día por mesa con abono.'});
  let i=0;do{i=await menu(rows,{cls:'full',title:'LA NAVE',title2:`${eur(NAVE.dia)} al día`,desc:true,initial:i});}while(i>=0);
}
async function talkNavero(i){
  const w=naveros()[i],M=S.nave&&S.nave.m[i];if(!w)return;const f=faseMesa(i);
  return say(!M?'Mi mesa está vacía. Plántame algo y la saco adelante.':f<4?`La ${getStrain(lotSid(M.k)).n} va bien: ${FASE_MESA[f]}. A los ${NAVE.crece} días empieza a dar.`
    :'Cada mañana cuelgo lo de mi mesa en el secadero.'+(M.abo&&!S.nave.ab[M.abo===1?'m':'o']?' Se ha acabado el abono de la estantería.':''),w.n.toUpperCase());
}

/* ---------- GAUA ---------- */
// la noche empieza a las 23:00: lo de después de medianoche es de la noche del día anterior (S.noche: lo pagado y hecho esa noche)
const nocheId=()=>S.min>=DISCO.abre?S.day:S.day-1;
const discoAbierta=()=>S.min>=DISCO.abre||S.min<DISCO.cierra;
const nocheYa=()=>!!(S.noche&&S.noche.id===nocheId());
const nocheGaua=()=>nocheYa()?S.noche:(S.noche={id:nocheId(),copas:0,ronda:0,baile:0,mesa:0});
async function entradaDisco(){
  const N='PORTERO';
  if(await ask(`La entrada, ${eur(DISCO.entrada)}. Se paga una vez por noche.`,['Pagar','No'],N)!==0)return false;
  if(S.money<DISCO.entrada){sfx('bad');await say('Sin entrada no se pasa.',N);return false;}
  S.money-=DISCO.entrada;nocheGaua();sfx('coin');updateHUD();return true;
}
async function echarDisco(){await say('Las seis. Se encienden las luces y el portero echa a todo el mundo.','PORTERO');return warp({to:'ensanche',x:38,y:9,dir:'down'});}
const talkGorila=()=>say(!discoAbierta()?'Abrimos a las once de la noche. Hasta las seis.':nocheYa()?'Ya has pagado esta noche. Pasa.':`La entrada, ${eur(DISCO.entrada)}. En la puerta.`,'PORTERO');
async function talkBarra(){
  const N='CAMARERA',X=nocheGaua();
  const c=await ask('¿Qué te pongo?',[`Una copa · ${eur(DISCO.copa)}`,`Invitar a una ronda · ${eur(DISCO.ronda)}`,'Nada'],N);
  if(c===0){if(X.copas>=DISCO.copaMax)return say('Por hoy ya vale. Agua, si quieres.',N);
    if(S.money<DISCO.copa){sfx('bad');return say('Sin dinero no hay copa.',N);}
    S.money-=DISCO.copa;X.copas++;if(X.copas===1)confia('gaua',1);advanceTime(10);sfx('coin');updateHUD();
    return say(['Un gin-tonic con mucho hielo.','Otra. La música sube.','La tercera. Mejor que sea la última.'][X.copas-1]);}
  if(c===1){if(X.ronda)return say('Ya has invitado esta noche. Con una, ya te conocen.',N);
    if(S.money<DISCO.ronda){sfx('bad');return say('No te llega para la ronda.',N);}
    S.money-=DISCO.ronda;X.ronda=1;S.rep+=1;confia('gaua',3);advanceTime(10);sfx('coin');updateHUD();
    return say('Invitas a la barra entera. Medio local brinda por ti.');}
}
async function talkDJ(){
  const c=await ask(pick(['¿Qué tal suena?','Esta noche se llena.']),['Bailar','Pedir una canción','Nada'],'DJ');
  if(c===0)return bailar();
  if(c===1){sfx('sel');return say(pick(['Te la pongo después de esta.','¿Esa? Hace años que no la pincho. Venga, va.','Esa no la tengo. Te pongo algo parecido.']),'DJ');}
}
// bailar (una vez por noche): media hora y, la mitad de las veces, alguien te pide el número (un pijo para la agenda)
async function bailar(){
  const X=nocheGaua();if(X.baile)return say('Ya has bailado esta noche. Las piernas no dan para más.');
  X.baile=1;await fade(1);advanceTime(30);updateHUD();await wait(200);await fade(0);confia('gaua',2);
  const id='gaua'+X.id;
  if(S.fijos.length<FIJOS_MAX&&!S.fijos.some(f=>f.id===id)&&Math.random()<DISCO.ligar){const n=nombreFijo(id);S.fijos.push({id,n,t:'pij',dia:0});sfx('get');
    return say(`Bailas media hora sin parar. ${n} te pide el número: «Si tienes de lo bueno, llámame».`);}
  return say('Bailas media hora sin parar. Sales de la pista con la camiseta empapada.');
}
// el reservado (una vez por noche): una hora y la RRPP te presenta a un cliente VIP (CTYPES.vip) para la agenda
async function talkRRPP(){
  const N='RRPP',X=nocheGaua();
  if(X.mesa)return say('Disfruta del reservado. Si conoces a alguien que merezca la pena, me lo presentas.',N);
  if(await ask(`El reservado: sofá, mesa y botella, ${eur(DISCO.mesa)} la noche. Ahí se sienta la gente que importa.`,['Reservar','No'],N)!==0)return;
  if(S.money<DISCO.mesa){sfx('bad');return say('Para el reservado hace falta dinero. Otra noche.',N);}
  S.money-=DISCO.mesa;X.mesa=1;confia('gaua',5);sfx('coin');await fade(1);advanceTime(60);updateHUD();await wait(200);await fade(0);
  if(S.fijos.length>=FIJOS_MAX)return say('Una hora en el reservado. Conoces a mucha gente, pero tu agenda ya está llena.');
  const n=DISCO.vip[S.vipN%DISCO.vip.length],id='vip'+S.vipN;S.vipN++;S.fijos.push({id,n,t:'vip',dia:0});sfx('get');
  return say(`Una hora en el reservado. La RRPP te presenta a ${n}: «Me han dicho que lo tuyo es de lo mejor. Llámame». Apuntas su número.`);
}
const BAILA=['¡Esta canción es la mejor!','No pares, que viene el estribillo.','Vengo cada sábado. El DJ es amigo mío.'];
const talkBaila=i=>say(BAILA[i],'GENTE');

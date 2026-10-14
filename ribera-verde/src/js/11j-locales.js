/* =========================================================
   LOS LOCALES (1.30): los clubs por dentro, la nave y GAUA
   ========================================================= */
// Los clubs (CLUBS, 11e-gente), la nave de Valdehierro (NAVE, 11f-plantilla) y la discoteca GAUA, en el Ensanche, son sitios a los
// que se entra como a una casa (entraLocal, desde la puerta). En el club: el dispensario (el encargado, detrás de la vitrina), los
// sofás con su mesa baja y un socio con el que compartir (SOCIO), y el billar bajo la lámpara, con apuesta (BILLAR). En la nave: las
// cuatro mesas de cultivo (una por trabajador; plantas tú, con semilla o esqueje, y eliges su abono), la estantería de los abonos, el
// secadero y el escritorio. En GAUA (DISCO: de 23:00 a 6:00, desde el capítulo DISCO.ch; la entrada, una vez por noche): la barra,
// la pista, la cabina del DJ y el reservado, donde la RRPP te presenta un cliente VIP para la agenda (CTYPES.vip)
const BILLAR={apuestas:[10,20,50],tiros:3,dia:3,min:20,hab:.55,verde:.08,amarillo:.2,centro:.7,periodo:1400,n:{puerto:'Ander',valde:'Izaskun',ibar:'Txetxu',ens:'Olatz',rv:'Koldo'}};
const SOCIO={g:1,rel:3,min:30,n:{puerto:'Gotzon',valde:'Maribel',ibar:'Joseba',ens:'Lorea',rv:'Imanol'},
  charla:['Aquí cada socio retira lo suyo y se consume dentro. Así funciona una asociación.','Los sábados se llena. Entre semana se está mejor.',
    'Dicen que el del billar no ha perdido una partida este año. Yo no me lo creo.','El encargado prueba todo lo que entra. Si no le convence, no entra.']};
const DISCO={n:'GAUA',ch:4,abre:23*60,cierra:6*60,entrada:15,copa:10,copaMax:3,ronda:40,mesa:300,ligar:.5,vip:['Kepa','Garbiñe','Aitor','Nekane','Borja','Ainhoa']};
const MESAS_X=[1,4,8,11],FASE_MESA=['vacía','recién plantada','creciendo','en flor','dando cogollos'];
// la mitad de la derecha de los muebles de 2 casillas de los locales: la pinta la de la izquierda (01b-arte)
const LOCAL2=new Set(['billar2','sofaF2','sofaV2','sofaB2','cabina2','escritorio2','mesaN2','fotoMaite2']);   // 1.33: la foto de la tía, de 2
// la luz de los locales (luzLocal, 14-render): el club, en penumbra cálida, con la lámpara del billar y el brillo de la vitrina
// ([x, y, radio, color, alfa], en px del mapa); GAUA, oscura, con tres focos de colores que giran sobre la pista (centro c, radios r)
const LUZ_CLUB={fondo:'rgba(24,14,4,.28)',l:[[144,70,30,'255,206,120',.6],[24,56,22,'200,240,255',.35]]};
const LUZ_DISCO={fondo:'rgba(10,4,30,.55)',focos:[['255,79,200',0],['64,224,240',2.1],['240,208,64',4.2]],c:[120,88],r:[30,14],R:26};
// la nave (1.31): bajo cada uno de los dos LED de una mesa plantada (encendidos), su luz en las plantas, del color de la de los LED de las
// carpas (FOCO_LUZ.led); [dx desde la casilla de la mesa, y, radio, color, alfa]
const LUZ_MESA=[[6,59,15,'240,170,255',.2],[26,59,15,'240,170,255',.2]];
const luzNave=()=>({l:MESAS_X.flatMap((x,i)=>faseMesa(i)?LUZ_MESA.map(([dx,y,r,c,a])=>[x*16+dx,y,r,FOCO_NAVE[S.nave.f[i]].luz,a]):[])});   // 1.33: del color de sus focos
function mapasLocales(){
  // ---------- LOS CLUBS: 12 × 8, el dispensario a la izquierda, los sofás en medio y el billar a la derecha ----------
  for(const k in CLUBS){const C=CLUBS[k],m=newMap('club-'+k,12,8,'floorC');m.music='club';
    rect(m,0,0,11,0,(x,y)=>gr(m,x,y,'iwT_club'));rect(m,0,1,11,1,(x,y)=>gr(m,x,y,'iwB_club'));
    [[0,'tarros'],[1,'pizarra'],[2,'tarros'],[4,'cartelC'],[7,k==='rv'?'fotoMaite':'poster'],[10,'tacos']].forEach(([x,o])=>ob(m,x,1,o));   // 1.32: en la asociación, la foto de la tía
    if(k==='rv')ob(m,8,1,'fotoMaite2');   // 1.33: más grande, de 2 casillas
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
MESAS_X.forEach((x,i)=>NPCDEF.push({id:'nv'+i,map:'nave',x,y:5,dir:'up',look:'navero'+(i+1),cond:()=>!!(S.nave&&naveroDe(i)),talk:()=>talkNavero(i)}));
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
  if(t==='club'){if(S.ch<CLUBS[k].ch)return cerrada('Una puerta sin rótulo, con un timbre. No abre nadie.');if(!S.clubs[k]){atrasPuerta();if(!await carneClub(k))return;}
    if(k==='rv')return entraAso(d);}
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
    if(o==='fotoMaite'||o==='fotoMaite2')return say(`${aso().tio?'La tía Maite y Delroy, de jóvenes':'La tía Maite, joven, con un hombre de rastas negras'}, en un campo. En la placa: «Maite, presidenta fundadora».`);
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
// un tiro: el texto y, con A, dónde estaba la barra (de 0 a 1; 1.31: arranca en un punto al azar, para que no baste con contar); las
// pruebas lo cambian por una función
async function tiroBillar(txt){
  await typeText(txt,'BILLAR');
  const p=await new Promise(res=>{TIRO={t0:performance.now()-Math.random()*BILLAR.periodo};push(b=>{if(b==='A'){pop();res(fuerzaTiro(performance.now()-TIRO.t0));}});});
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
const naveNueva=()=>({m:Array(NAVE.max).fill(null),ab:{m:0,o:0},f:Array(NAVE.max).fill('led'),ex:0,rg:0});
const naveStock=()=>S.nave?S.nave.m.reduce((a,M)=>a+(M?M.g:0),0):0;
function faseMesa(i){const M=S.nave&&S.nave.m[i];if(!M)return 0;const d=S.day-M.dia;return d<1?1:d<3?2:d<NAVE.crece?3:4;}
const thcNave=(sid,f)=>Math.round(getStrain(sid).thc*(f?f.t:1)*NAVE.thc*10)/10;
const ABONO_MESA=['sin abono','MEATZA','ORTUA BIO'];
// el equipo de la nave (1.33, lo pidió el usuario), por niveles: se compra en el escritorio (MEJORAS) y lo monta Arrieta en el momento.
// Los focos, por mesa (S.nave.f, en la mesa: FOCOS): los LED de barras de serie, sodio o cerámica (CMH), con su rendimiento (rend), el THC que
// suben (thc), lo que calientan encendidos (calor) y el color de su luz. Para toda la nave, la extracción (S.nave.ex, EXTR_NAVE: el
// calor que saca, cap, y lo que deja salir del olor, × la probabilidad de la redada) y el riego (S.nave.rg, RIEGO_NAVE: de la
// estantería a mano, el tanque con su bomba, el controlador con goteros o la máquina de fertirrigación; rendimiento, THC y lo que
// gasta cada mesa con abono de la estantería, dosis). El calor de los focos que pasa de lo que saca la extracción quita un 8 % por
// punto (sofocoNave, hasta un 40 %). La nave sube de nivel con la extracción y el riego (NIVEL_NAVE)
const FOCO_NAVE={led:{n:'LED de barras',d:'Dos de 720 W y 8 barras: gastan poco y apenas calientan.',p:1800,rend:1,thc:0,calor:1,luz:'240,170,255'},
  sodio:{n:'Sodio 600 W',d:'Dos campanas de 600 W con su balastro: más gramos, pero calientan el doble.',p:600,rend:1.1,thc:0,calor:2,luz:'255,170,80'},
  lec:{n:'Cerámica 315 W',d:'Cuatro de halogenuro metálico cerámico (CMH) de 315 W, dos por campana: luz de día con algo de ultravioleta, más resina.',p:1400,rend:1,thc:1,calor:1.5,luz:'225,235,255'}};
const EXTR_NAVE=[{n:'Sin extracción',d:'La puerta y las rejillas: el olor sale a la calle.',p:0,cap:4,olor:1},
  {n:'Extractor de 250 mm',a:'un extractor de 250 mm con su filtro de carbón',d:'Uno en la pared, con un filtro de carbón.',p:450,cap:6,olor:.7},
  {n:'Extractor de 315 mm',a:'un extractor de 315 mm con dos filtros',d:'Uno grande, con dos filtros de carbón.',p:1200,cap:9,olor:.45},
  {n:'Dos de 315 mm',a:'otro de 315 mm y dos filtros más',d:'Dos grandes y cuatro filtros de carbón: ni calor ni olor.',p:2600,cap:12,olor:.25}];
const RIEGO_NAVE=[{n:'A mano',d:'Tu gente riega con regadera y el abono de la estantería.',p:0,rend:0,thc:0,dosis:1},
  {n:'Tanque de 1.000 L',a:'el tanque de 1.000 L con su bomba',d:'Un depósito con su bomba y una manguera a cada mesa: el abono, ya mezclado.',p:650,rend:.05,thc:0,dosis:1},
  {n:'Controlador de riego',a:'el controlador de riego y los goteros',d:'Programador con electroválvulas y un gotero por maceta: riega a su hora y gasta menos abono.',p:1600,rend:.1,thc:0,dosis:.8},
  {n:'Máquina de fertirrigación',a:'la máquina de fertirrigación',d:'Mide el pH y la EC y dosifica el abono sola en cada riego.',p:4500,rend:.18,thc:.5,dosis:.7}];
const NIVEL_NAVE=['pelada','apañada','en marcha','seria','profesional','de concurso','industrial'];
const calorNave=()=>S.nave.m.reduce((a,M,i)=>a+(M?FOCO_NAVE[S.nave.f[i]].calor:0),0);
const sofocoNave=()=>Math.max(.6,1-.08*Math.max(0,calorNave()-EXTR_NAVE[S.nave.ex].cap));
const dosisTxt=n=>String(Math.round(n*10)/10).replace('.',',');   // con el controlador o la máquina se gastan 0,8 o 0,7: lo que queda, con su decimal
// lo que se ve del equipo (montarNave, al entrar y al comprar): [x, y, objeto, de qué (ex, rg), desde el nivel, hasta el nivel];
// en la pared, los extractores (extrN, el de 250 mm; extrG, el de 315), los filtros de carbón y el controlador; en el suelo, junto a la
// estantería, el tanque y la máquina
const EQUIPO_NAVE=[[10,1,'extrN','ex',1,1],[10,1,'extrG','ex',2,3],[3,1,'extrG','ex',3,3],[9,1,'filtroN','ex',1,3],[7,1,'filtroN','ex',2,3],
  [4,1,'filtroN','ex',3,3],[2,1,'filtroN','ex',3,3],[5,1,'ctrlN','rg',2,3],[1,2,'tanqueN','rg',1,3],[2,2,'riegoN','rg',3,3]];
function montarNave(){
  const n=MAPS.nave;if(!n)return;
  for(const [x,y] of EQUIPO_NAVE)ob(n,x,y,null);
  if(S&&S.nave)for(const [x,y,o,k,a,b] of EQUIPO_NAVE)if(S.nave[k]>=a&&S.nave[k]<=b)ob(n,x,y,o);
}
// la manguera del riego (1.33): del tanque, por el pie de la pared, y una bajada a cada mesa, por detrás (rectángulos [x, y, w, h, color])
function mangueraNave(){
  if(!S.nave||!S.nave.rg)return [];const y=34,o=[[1*16+15,y,12*16+16-(1*16+15),1,'#3a3c44'],[1*16+15,y+1,12*16+16-(1*16+15),1,'#1c1d22']];
  for(const x of MESAS_X)o.push([x*16+16,y+2,1,57-(y+2),'#1c1d22']);
  return o;
}
// los dos focos de la mesa i (1.33): de su tipo, encendidos con la mesa plantada (focoN-<tipo>-<0|1>), colgados a FOCO_AIRE px de lo
// más alto de sus plantas (sin plantas, recogidos a FOCO_ALTO px de la bandeja), que suben al crecer, como en las carpas; cada uno de
// dos poleas a FOCO_POLEA px del techo, con la cuerda que sube desvaneciéndose hacia el techo (FOCO_DEG pasos), la que baja al asa y
// la del tirador, por fuera (como vcPoleas). yb: la fila de abajo del foco
const FOCO_DX=[-10,10],FOCO_AIRE=3,FOCO_ALTO=14,FOCO_ASA=9,FOCO_POLEA=14,FOCO_DEG=8;
const filasArriba=new WeakMap();
function filaArriba(c){if(filasArriba.has(c))return filasArriba.get(c);const d=c.getContext('2d').getImageData(0,0,c.width,c.height).data;let r=c.height;
  for(let i=3;i<d.length;i+=4)if(d[i]){r=Math.floor((i>>2)/c.width);break;}filasArriba.set(c,r);return r;}
function focoNaveY(yp,pl){const top=pl?yp-47+filaArriba(pl):yp-47+25-FOCO_ALTO;return Math.max(FOCO_POLEA+12,top-FOCO_AIRE-1);}
function poleasNave(x0,yb){
  const K=VC_CUERDA,[M,H]=VC_POLEA,y0=FOCO_POLEA,asa=yb-15+FOCO_ASA,o=[];
  for(const [X,s] of [[x0+1,-1],[x0+14,1]]){const cx=X+2*s,T=X+4*s;
    for(let y=0;y<y0;y++)o.push([cx,y,1,1,`rgba(28,29,34,${Math.ceil((y+1)/y0*FOCO_DEG)/FOCO_DEG})`]);   // la cuerda del techo, que se desvanece hacia arriba
    o.push([X,y0+3,1,asa-(y0+3),K],[T,y0+3,1,8,K],[T-1,y0+11,3,3,K],[T,y0+12,1,1,M],
      [cx-1,y0+1,3,5,K],[cx-2,y0+2,5,3,K],[cx-1,y0+2,3,3,M],[cx,y0+3,1,1,K],[cx-1,y0+2,1,1,H]);}
  return o.filter(e=>e[3]>0);
}
// (xp, yp: el ancla de la mesa en el mapa; pl: el lienzo de sus plantas, si las hay)
function focosMesa(i,xp,yp,fm,pl,cam){
  const g=ARTE.cubre['obj:focoN'],f=g&&frameDe(g,`focoN-${S.nave?S.nave.f[i]:'led'}-${fm?1:0}`,'unica',0,{i:0});if(!f)return;
  const yb=focoNaveY(yp,pl);ctx.save();ctx.translate(-cam.x,-cam.y);
  for(const dx of FOCO_DX){pintaRects(poleasNave(xp+dx,yb));pinta(f,xp+8+dx,yb);}
  ctx.restore();
}
const mesaTxt=M=>getStrain(lotSid(M.k)).n+etiq(M.f);
async function mesaNave(i){
  const N=S.nave,M=N.m[i],w=naveroDe(i),ops=[M?'Arrancar y plantar':'Plantar'].concat(M?['Abono']:[],['Focos','Nada']);
  const op=ops[await ask(`Mesa ${i+1} · ${M?mesaTxt(M)+' · '+FASE_MESA[faseMesa(i)]+' · '+ABONO_MESA[M.abo]:'vacía'} · ${FOCO_NAVE[N.f[i]].n}\n${w?'La cuida '+w.n+'.':'Nadie la cuida: pon a alguien de tu plantilla en la nave.'}`,ops)];
  if(op==='Focos')return focosNave(i);
  if(op==='Plantar'||op==='Arrancar y plantar'){if(M&&M.g>=1)return say('Antes, descuelga del secadero lo de esta mesa.');return plantarMesa(i);}
  if(op==='Abono'){const c=await ask(`¿Qué abono le echa cada día? En la estantería: MEATZA ×${dosisTxt(N.ab.m)} · ORTUA BIO ×${dosisTxt(N.ab.o)}.`,['Sin abono','MEATZA Floración','ORTUA BIO Floración','Nada']);
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
// los focos de la mesa i (1.33): cambiarlos por los de otro tipo (los de antes se los queda Arrieta)
async function focosNave(i){
  const N=S.nave,k=N.f[i],ks=Object.keys(FOCO_NAVE).filter(x=>x!==k);
  const c=await ask(`Mesa ${i+1}: ${FOCO_NAVE[k].n}. ${FOCO_NAVE[k].d}\n¿Los cambias? Los de ahora se los queda Arrieta.`,ks.map(x=>`${FOCO_NAVE[x].n} · ${eur(FOCO_NAVE[x].p)}`).concat(['Nada']));
  if(c<0||c>=ks.length)return;const F=FOCO_NAVE[ks[c]];
  if(S.money<F.p){sfx('bad');return say('No te llega.');}
  S.money-=F.p;N.f[i]=ks[c];sfx('coin');updateHUD();
  return say(`Arrieta cuelga los ${F.n} en la mesa ${i+1}. ${F.d}`+(calorNave()>EXTR_NAVE[N.ex].cap?' Con tanto foco, la nave se calienta: hará falta más extracción.':''));
}
// las mejoras de la nave (1.33): la extracción y el riego, nivel a nivel
async function mejorasNave(){
  const N=S.nave;let j=0;
  for(;;){
    const fila=(L,k,t)=>{const a=L[N[k]],b=L[N[k]+1];return {label:`${t}: ${a.n}`,right:b?eur(b.p):'a tope',desc:b?`Siguiente: ${b.n}. ${b.d}`:a.d};};
    j=await menu([fila(EXTR_NAVE,'ex','Extracción'),fila(RIEGO_NAVE,'rg','Riego'),{label:'Volver',desc:''}],{cls:'full',title:'MEJORAS DE LA NAVE',title2:'Nave '+NIVEL_NAVE[N.ex+N.rg],desc:true,initial:j});
    if(j<0||j>1)return;
    const [L,k]=j?[RIEGO_NAVE,'rg']:[EXTR_NAVE,'ex'],b=L[N[k]+1];if(!b)continue;
    if(await ask(`${b.n}: ${b.d} ${eur(b.p)}, montado hoy mismo.`,['Comprar','No'])!==0)continue;
    if(S.money<b.p){sfx('bad');await say('No te llega.');continue;}
    S.money-=b.p;N[k]++;sfx('coin');updateHUD();montarNave();
    await say(`Arrieta y los suyos montan ${b.a}. La nave ya es una nave ${NIVEL_NAVE[N.ex+N.rg]}.`);
  }
}
async function estanteNave(){
  const N=S.nave,ops=(S.items.fert?[`Dejar MEATZA ×${S.items.fert}`]:[]).concat(S.items.ofert?[`Dejar ORTUA BIO ×${S.items.ofert}`]:[],['Nada']);
  const op=ops[await ask(`La estantería de los abonos: MEATZA FLORACIÓN ×${dosisTxt(N.ab.m)} · ORTUA BIO FLORACIÓN ×${dosisTxt(N.ab.o)}. Cada mesa con abono gasta ${N.rg>=2?'menos de ':''}una dosis al día.`,ops)];
  if(op&&op.startsWith('Dejar MEATZA')){N.ab.m+=S.items.fert;S.items.fert=0;sfx('sel');}
  else if(op&&op.startsWith('Dejar ORTUA')){N.ab.o+=S.items.ofert;S.items.ofert=0;sfx('sel');}
}
// descolgar del secadero lo que quepa en la mochila, mesa por mesa (cada una, su lote, sin curar y con el día de su cosecha, M.cd: 1.31)
async function secaderoNave(){
  if(naveStock()<1)return say(`El secadero está vacío. Cada mesa da cada mañana, a los ${NAVE.crece} días de plantarla.`);
  let lleva=0;const cabe=Math.floor(libreMochila());
  for(const M of S.nave.m){if(!M||M.g<1)continue;const q=Math.min(Math.floor(M.g),cabe-lleva);if(q<1)break;addBuds(M.k,q,M.t,S.buds,0,M.cd??S.day);M.g=Math.round((M.g-q)*10)/10;lleva+=q;}
  if(!lleva)return say('No te cabe nada más en la mochila.');
  sfx('get');updateHUD();return say(`Descuelgas ${gTxt(lleva)} del secadero.`+(naveStock()>=1?` Quedan ${gTxt(naveStock())}: no te caben.`:''));
}
async function escritorioNave(){
  const N=S.nave,filas=()=>{const rows=N.m.map((M,i)=>{const w=naveroDe(i);return {label:`Mesa ${i+1} · ${M?getStrain(lotSid(M.k)).n:'vacía'}`,right:M?FASE_MESA[faseMesa(i)]:'',
    desc:`${w?'La cuida '+w.n:'Nadie la cuida'}. ${FOCO_NAVE[N.f[i]].n}.`+(M?` ${ABONO_MESA[M.abo][0].toUpperCase()+ABONO_MESA[M.abo].slice(1)} · en el secadero, ${gTxt(M.g)}.`:'')};});
  rows.push({label:'Estantería',right:`${dosisTxt(N.ab.m)} + ${dosisTxt(N.ab.o)} dosis`,desc:`MEATZA FLORACIÓN y ORTUA BIO FLORACIÓN: ${N.rg>=2?'menos de ':''}una dosis al día por mesa con abono.`},
    {label:'Clima',right:`${calorNave()} de ${EXTR_NAVE[N.ex].cap}`,desc:`El calor de los focos encendidos y lo que saca la extracción (${EXTR_NAVE[N.ex].n}).`+(sofocoNave()<1?` Hace demasiado calor: las mesas dan un ${Math.round((1-sofocoNave())*100)} % menos.`:'')},
    {label:'Mejoras',right:'Nave '+NIVEL_NAVE[N.ex+N.rg],desc:`Extracción: ${EXTR_NAVE[N.ex].n}. Riego: ${RIEGO_NAVE[N.rg].n}. Pulsa A para mejorarlas.`});return rows;};
  let i=0;do{const rows=filas();i=await menu(rows,{cls:'full',title:'LA NAVE',title2:`${eur(NAVE.dia)} al día`,desc:true,initial:i});if(i===rows.length-1)await mejorasNave();}while(i>=0);
}
async function talkNavero(i){
  const w=naveroDe(i),M=S.nave&&S.nave.m[i];if(!w)return;const f=faseMesa(i);
  return say(!M?'Mi mesa está vacía. Plántame algo y la saco adelante.':f<4?`La ${getStrain(lotSid(M.k)).n} va bien: ${FASE_MESA[f]}. A los ${NAVE.crece} días empieza a dar.`
    :'Cada mañana cuelgo lo de mi mesa en el secadero.'+(M.abo&&S.nave.ab[M.abo===1?'m':'o']<RIEGO_NAVE[S.nave.rg].dosis?' Se ha acabado el abono de la estantería.':'')
      +(sofocoNave()<1?' Y aquí dentro hace un calor que no veas: hace falta más extracción.':''),w.n.toUpperCase());
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
// la barra, el DJ y la RRPP, solo con GAUA abierta (1.31): si te quedas quieto pasadas las seis, el portero te echa al hablar con ellos
async function talkBarra(){
  if(!discoAbierta())return echarDisco();
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
  if(!discoAbierta())return echarDisco();
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
  if(!discoAbierta())return echarDisco();
  const N='RRPP',X=nocheGaua();
  if(X.mesa)return say('Disfruta del reservado. Si conoces a alguien que merezca la pena, me lo presentas.',N);
  if(S.fijos.length>=FIJOS_MAX)return say('Tu agenda ya está llena. Cuando tengas sitio para alguien que importa, vuelve.',N);   // 1.31: antes de cobrar
  if(await ask(`El reservado: sofá, mesa y botella, ${eur(DISCO.mesa)} la noche. Ahí se sienta la gente que importa.`,['Reservar','No'],N)!==0)return;
  if(S.money<DISCO.mesa){sfx('bad');return say('Para el reservado hace falta dinero. Otra noche.',N);}
  S.money-=DISCO.mesa;X.mesa=1;confia('gaua',5);sfx('coin');await fade(1);advanceTime(60);updateHUD();await wait(200);await fade(0);
  const n=DISCO.vip[S.vipN%DISCO.vip.length],id='vip'+S.vipN;S.vipN++;S.fijos.push({id,n,t:'vip',dia:0});sfx('get');
  return say(`Una hora en el reservado. La RRPP te presenta a ${n}: «Me han dicho que lo tuyo es de lo mejor. Llámame». Apuntas su número.`);
}
const BAILA=['¡Esta canción es la mejor!','No pares, que viene el estribillo.','Vengo cada sábado. El DJ es amigo mío.'];
const talkBaila=i=>say(BAILA[i],'GENTE');

/* ---------- LA ASOCIACIÓN (1.32): la de la tía Maite, en el barrio alto (CLUBS.rv) ---------- */
// La segunda vez que entras (en otro día: S.aso.v), está Delroy junto a la foto de la tía: su compañero de treinta años, el tío que
// nunca lo fue de papeles. Te cuenta que ella la fundó y la presidió muchos años y que ahora la lleva una gestora, con la presidencia
// vacía. Dos caminos: presentarte (la asamblea, ASO.dias después, al amanecer: ganas con ASO.mayoria de ASO.votos; votan por ti los
// de siempre de Maite, Delroy, ASO.amigo por cada uno del barrio con REL.amigo y uno por cada ASO.relV de confianza con la asociación;
// si pierdes, otra en ASO.espera días) o refundarla (pagar ASO.refunda: deudas y registro). De presidente, el dispensario: le dejas un
// lote y cada mañana los socios retiran ASO.dia g a precio de club (× ASO.f y la calidad), que van a tu buzón
const ASO={visitas:2,dias:3,votos:40,mayoria:21,base:8,delroy:4,amigo:4,relV:10,espera:7,refunda:3000,dia:20,f:1.15,g:[50,100,200],
  gente:['kiko','julen','josune','begona','patxi','txaro','inaki'],rival:'Ugarte'};
const DELROY={n:'DELROY',
  revela:['¿Tú eres el sobrino de Maite? Tienes sus ojos. Yo soy Delroy.',
    'Vine de Kingston de joven y me quedé por ella. Treinta años juntos, sin papeles ni boda. Tu tío, aunque nunca lo fuera oficialmente.',
    'Esta asociación la fundó ella y la presidió muchos años: los estatutos, la cuota, que nada saliera a la calle. Todo era Maite.',
    `Desde que se fue la lleva una gestora, con ${ASO.rival} al frente. Deudas y socios que se van. La presidencia está vacía.`,
    `Hay dos caminos, sobrino: presentarte a la asamblea y ganarte los votos de los socios, o pagar lo que se debe, ${eur(ASO.refunda)}, y refundarla tú.`],
  charla:['Maite decía que una planta te cuenta lo que le pasa, si sabes mirarla.','Estos zapatos de ante los compré en Londres hace cuarenta años. Lo bueno, si se cuida, dura.',
    'Una asociación no es una tienda, sobrino. Es la gente que viene a sentarse en esos sofás.','Tu tía no fumaba nunca antes de las siete. «Primero, el trabajo», decía.']};
const aso=()=>S.aso||(S.aso={v:0,d:0,tio:false,asam:0,otra:0,pres:false,votos:0,lote:null});
const delroyAqui=()=>aso().v>=ASO.visitas;
const votosAso=()=>Math.min(ASO.votos,ASO.base+(aso().tio?ASO.delroy:0)+ASO.amigo*ASO.gente.filter(id=>rel(id)>=REL.amigo).length+Math.floor(rel('rv')/ASO.relV));
NPCDEF.push({id:'delroy',map:'club-rv',x:8,y:2,dir:'down',look:'delroy',cond:()=>delroyAqui(),talk:()=>talkDelroy()});
// la puerta (entraLocal): cada día que entras cuenta una visita; la segunda, Delroy está dentro
async function entraAso(d){
  const A=aso();if(A.d!==S.day){A.v++;A.d=S.day;}
  await warp(d);if(delroyAqui()&&!A.tio)await say('Junto a la foto de la tía Maite, un hombre mayor con las rastas y la barba canas no te quita ojo.');
}
async function talkDelroy(){
  const A=aso(),N=DELROY.n;
  if(!A.tio){await talk(N,DELROY.revela);A.tio=true;confia('delroy',5);}
  const ops=['Charlar',A.pres?'El dispensario':'La presidencia','Nada'],c=await ask(A.pres?'¿Qué tal, presidente?':'Dime, sobrino.',ops,N);
  if(c===0)return say(pick(DELROY.charla),N);
  if(c===1)return A.pres?dispensarioAso():presidenciaAso();
}
async function presidenciaAso(){
  const A=aso(),N=DELROY.n;
  if(A.asam){   // con la asamblea pendiente, todavía se puede refundar
    if(await ask(`La asamblea es el día ${A.asam}, por la mañana. Habla con la gente del barrio: cada amigo trae votos. O la refundas ya, por ${eur(ASO.refunda)}.`,['Refundarla','Nada'],N)!==0)return;
  }else{
    const c=await ask(`Hacen falta ${ASO.mayoria} votos de ${ASO.votos}. Hoy tendrías ${votosAso()}. O pagas ${eur(ASO.refunda)} de deudas y registro y la refundas tú.`,['Presentarme','Refundarla','Nada'],N);
    if(c===0){
      if(S.day<A.otra)return say(`Hasta el día ${A.otra} no hay otra asamblea. Gánate al barrio mientras.`,N);
      A.asam=S.day+ASO.dias;sfx('sel');return say(`Apuntado. La asamblea, el día ${A.asam}. ${ASO.rival} también se presenta.`,N);
    }
    if(c!==1)return;
  }
  if(S.money<ASO.refunda){sfx('bad');return say(`Sin los ${eur(ASO.refunda)} no hay refundación.`,N);}
  S.money-=ASO.refunda;A.pres=true;A.asam=0;confia('delroy',10);confia('rv',10);updateHUD();sfx('get');
  return say('Pagas las deudas de la gestora y el registro. La asociación vuelve a nacer, con tus estatutos. Maite estaría orgullosa.',N);
}
// el dispensario: un lote a la vez; dice cuánto queda y lo que llevas
async function dispensarioAso(){
  const A=aso(),N=DELROY.n,L=A.lote;
  if(L)return say(`En el dispensario quedan ${gTxt(L.g)} de ${lotNombre(L.k)}, a ${coma(L.pg.toFixed(2))} € el gramo. Llevas ${eur(L.tot)}.`,N);
  const lots=budLots(ASO.g[0]);if(!lots.length)return say(`Déjame ${ASO.g[0]} g o más y los socios lo retiran, ${ASO.dia} g al día. El dinero, a tu buzón.`,N);
  const i=await menu(lots.map(lotItem).concat([{label:'Nada'}]),{cls:'right',title:'¿Qué lote?'});if(i<0||i>=lots.length)return;
  const [k,b]=lots[i],pg=Math.round(precioClub(b.thc)*calidad(b)*ASO.f*100)/100,ops=ASO.g.filter(g=>g<=Math.floor(b.g));
  const j=await ask(`${lotNombre(k)} a ${coma(pg.toFixed(2))} € el gramo para los socios. ¿Cuánto dejas?`,ops.map(g=>`${g} g · ${eur(g*pg)}`).concat(['Nada']),N);if(j<0||j>=ops.length)return;
  useBuds(k,ops[j]);A.lote={k,g:ops[j],pg,tot:0};sfx('sel');return say(`Al dispensario. Cada mañana, ${ASO.dia} g para los socios.`,N);
}
// al amanecer (curroDia): la asamblea, si toca, y lo que retiran los socios del dispensario
function asoDia(){
  const A=aso();
  if(A.asam&&S.day>=A.asam){const v=votosAso(),gana=v>=ASO.mayoria;A.asam=0;A.votos=v;
    if(gana){A.pres=true;confia('delroy',10);}else A.otra=S.day+ASO.espera;
    queue('aso',()=>talk('SMS · DELROY',[gana?`¡${v} votos de ${ASO.votos}! Eres el presidente de la asociación, sobrino. Como tu tía.`:`${v} votos de ${ASO.votos}: gana ${ASO.rival}. Gánate al barrio y preséntate otra vez desde el día ${A.otra}.`]));}
  const L=A.lote;if(!A.pres||!L)return;
  const g=Math.min(L.g,ASO.dia),e=Math.round(g*L.pg);L.g-=g;L.tot+=e;S.money+=e;S.sales+=e;queue('historia',checkStory);
  if(L.g<1){A.lote=null;queue('asoLote',()=>talk('SMS · DELROY',[`Se acabó lo del dispensario: ${eur(L.tot)} en total, en tu buzón.`]));}
}

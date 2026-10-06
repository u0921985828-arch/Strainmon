/* =========================================================
   TIEMPO Y CULTIVO
   ========================================================= */
/* ---------- equipo: carpas, focos y macetas ----------
   Carpa: en el piso es un mueble (w casillas de ancho, 1 de fondo; 1 casilla = 1 m) y por dentro se ve en su vista de frente
   (09b-carpa): cm = ancho y alto reales; las plazas van en filas de cols macetas (fila 0 delante).
   wmax: el foco más potente que admite (calor) · lmax: la maceta más grande que cabe.
   Foco: cubre N plazas a pleno rendimiento; si la carpa tiene más, la luz se reparte (cob < 1) y rinde menos.
   Maceta: la de tela airea las raíces (más cosecha y menos plagas, bebe más); la grande da más pero crece algo más lenta.
   Lo de serie (CFL + plástico 7 L en el armario) da justo lo de antes de la 1.6: factores 1. */
const CARPAS={
  p60:{n:'Armario 60×60',w:1,cm:[60,160,60],cols:2,filas:1,plazas:2,wmax:250,lmax:11},
  p80:{n:'Armario 80×80',w:1,cm:[80,180,80],cols:2,filas:2,plazas:3,wmax:400,lmax:18},
  m100:{n:'Carpa 100×100',w:1,cm:[100,200,100],cols:2,filas:2,plazas:4,wmax:480,lmax:25},
  m120:{n:'Carpa 120×120',w:2,cm:[120,200,120],cols:3,filas:2,plazas:6,wmax:720,lmax:25},
  g150:{n:'Carpa 150×100',w:2,cm:[150,200,100],cols:3,filas:2,plazas:6,wmax:720,lmax:25}};
const SITIOS=[{x:8,y:2,w:1},{x:10,y:2,w:2},{x:2,y:2,w:2}];   // A: el armario de la tía (60 y, después, 80) · B: la carpa que compras (100 y, después, 150), al fondo · C: la carpa 120, junto a la cama
const FOCOS={
  cfl:{n:'CFL 125 W',tipo:'cfl',w:125,cubre:2,rend:1,crec:1,thc:0,agua:1},
  sodio250:{n:'Sodio 250 W',tipo:'sodio',w:250,cubre:2,rend:1.25,crec:1.05,thc:.3,agua:1.3},
  sodio400:{n:'Sodio 400 W',tipo:'sodio',w:400,cubre:4,rend:1.35,crec:1.05,thc:.5,agua:1.4},
  sodio600:{n:'Sodio 600 W',tipo:'sodio',w:600,cubre:6,rend:1.45,crec:1.05,thc:.7,agua:1.5},
  led100:{n:'LED 100 W',tipo:'led',w:100,cubre:2,rend:1.15,crec:1.05,thc:.3,agua:1},
  led200:{n:'LED 200 W',tipo:'led',w:200,cubre:2,rend:1.3,crec:1.1,thc:.6,agua:1.05},
  led480:{n:'LED 480 W',tipo:'led',w:480,cubre:4,rend:1.45,crec:1.1,thc:1,agua:1.1},
  led720:{n:'LED 720 W',tipo:'led',w:720,cubre:6,rend:1.6,crec:1.15,thc:1.4,agua:1.15}};
const MACETAS={
  plastico7:{n:'Plástico 7 L',l:7,rend:1,crec:1,agua:1,plaga:1},
  tela11:{n:'Tela 11 L',l:11,rend:1.15,crec:1.05,agua:1.25,plaga:.8},
  plastico18:{n:'Plástico 18 L',l:18,rend:1.25,crec:.95,agua:.8,plaga:1},
  tela25:{n:'Tela 25 L',l:25,rend:1.4,crec:1,agua:1.1,plaga:.8}};
// extras (1.10): uno de cada por carpa (S.carpas[ci][k] = true); se compran en el growshop (S.items['x_'+k]) y se ponen desde la vista de carpa
const EXTRAS={
  vent:{n:'Ventilador de pinza',c:'Ventilador',d:'Mueve el aire de la carpa: plagas ×0,7.'},
  filtro:{n:'Extractor con filtro de carbón',c:'Filtro de carbón',d:'Sin filtro, cada carpa con plantas en floración suma +2 de calor policial al día por el olor. Con él, nada.'},
  goteo:{n:'Riego por goteo',c:'Goteo',d:'Depósito con goteros: el agua baja a la mitad de rápido.'}};
const OLOR=2;   // calor al día por carpa sin filtro con alguna planta en floración (o lista)
const TARIFA=.02;   // € por vatio y día, solo en las carpas con alguna planta viva (vacías, el foco va apagado)
const signo=v=>(v>=0?'+':'−')+String(Math.abs(Math.round(v))),pc=(t,f)=>Math.abs(f-1)<.001?'':` · ${t} ${signo((f-1)*100)}%`;
const descFoco=k=>{const F=FOCOS[k];return `${F.w} W · cubre ${F.cubre} plantas${pc('cosecha',F.rend)}${pc('crece',F.crec)}${F.thc?' · THC +'+pct(F.thc):''} · riego ×${String(F.agua).replace('.',',')}\nLuz: ${eur(Math.round(F.w*TARIFA))} al día con plantas.`;};
const descMaceta=k=>{const M=MACETAS[k];return `${M.l} L${pc('cosecha',M.rend)}${pc('crece',M.crec)} · riego ×${String(M.agua).replace('.',',')}${M.plaga<1?' · menos plagas':''}`;};
// plazas de cultivo de todas las carpas, en orden: S.pots[i] y S.macetas[i] son la planta y la maceta de la plaza i
let _hk='',_hu=[];
function huecos(){
  const k=S.carpas.map(c=>c?c.t:'-').join();if(k===_hk)return _hu;_hk=k;_hu=[];
  S.carpas.forEach((c,ci)=>{if(!c)return;for(let j=0;j<CARPAS[c.t].plazas;j++)_hu.push({c:ci,j});});
  return _hu;
}
function factores(i){
  const h=huecos()[i],c=S.carpas[h.c],C=CARPAS[c.t],F=FOCOS[c.foco],M=MACETAS[S.macetas[i]]||MACETAS.plastico7;
  const cob=Math.min(1,F.cubre/C.plazas);
  return {rend:(1+(F.rend-1)*cob)*(.6+.4*cob)*M.rend,crec:F.crec*(.85+.15*cob)*M.crec,thc:F.thc*cob,agua:F.agua*M.agua*(c.goteo?.5:1),plaga:M.plaga*(c.vent?.7:1),cob};
}
const plantasVivas=ci=>huecos().some((h,i)=>h.c===ci&&S.pots[i]&&!S.pots[i].dead);
const enFlor=ci=>huecos().some((h,i)=>h.c===ci&&S.pots[i]&&!S.pots[i].dead&&S.pots[i].prog>=.65);
const olorDia=()=>S.carpas.reduce((a,c,ci)=>a+(c&&!c.filtro&&enFlor(ci)?OLOR:0),0);
const luzCarpa=ci=>Math.round(FOCOS[S.carpas[ci].foco].w*TARIFA);
function facturaLuz(){let e=0;S.carpas.forEach((c,ci)=>{if(c&&plantasVivas(ci))e+=luzCarpa(ci);});return e;}
function plantStep(p,h,f){
  if(p.dead)return;const s=getStrain(p.sid);
  p.water=Math.max(0,p.water-3.5*h*f.agua);
  if(!p.pest&&p.prog<1&&Math.random()<.006*h*(100-s.r)/40*f.plaga)p.pest=true;
  let g=h/(s.d*24)*f.crec;if(p.water<20)g*=.4;if(p.water<=0)g=0;if(p.fert)g*=1.1;
  if(p.prog<1)p.prog=Math.min(1,p.prog+g);
  if(p.water<=0)p.health-=4*h;if(p.pest)p.health-=2.5*h;if(p.water>30&&!p.pest)p.health+=h;
  p.health=clamp(p.health,0,100);if(p.health<=0)p.dead=true;
}
function plantsAdvance(min){S.pots.forEach((p,i)=>{if(p)plantStep(p,min/60,factores(i));});}
function advanceTime(min){while(min>0){const st=Math.min(60,min);min-=st;S.min+=st;plantsAdvance(st);if(S.min>=1440){S.min-=1440;newDay();}}}
function tickMinute(){
  S.min++;if(S.min%10===0)plantsAdvance(10);
  if(S.min%30===0&&S.hp<S.hpMax)S.hp++;
  if(S.min>=1440){S.min-=1440;newDay();}
  if(S.min%30===0&&S.map==='town')music(mapMusic());
}
function newDay(){
  S.day++;
  if(S.heat>=90)queue('raid',raidEvent); // se comprueba antes de que el calor baje con el nuevo día
  S.heat=Math.max(0,S.heat-(S.protect?20:12));
  const luz=facturaLuz(),olor=olorDia(),av=[];S.luz={d:S.day,e:luz,o:olor};if(luz>0){S.money=Math.max(0,S.money-luz);av.push('Factura de la luz: −'+eur(luz));}
  if(olor){S.heat=Math.min(100,S.heat+olor);av.push('Olor a cogollo: calor +'+olor);}   // después de bajar el calor: cuenta para la redada de mañana
  if(av.length&&mode==='world')toast(av.join('<br>'),1600);
  spawnClients();recibirPedido();
  if(S.due>0&&S.flags.metB&&S.day>S.deadline)queue('penalty',penaltyEvent);
}
function stageName(p){return p.prog<.12?'Germinando':p.prog<.35?'Plántula':p.prog<.65?'Vegetativo':'Floración';}
async function potAction(i){
  const p=S.pots[i];
  if(!p){
    if(macetasLibres(i).length){const c=await ask(`Plaza vacía con una maceta de ${MACETAS[S.macetas[i]].n}.`,['Plantar','Cambiar maceta','Salir']);if(c===1)return cambiarMaceta(i);if(c!==0)return;}
    const own=Object.entries(S.seeds).filter(([,v])=>v>0);
    if(!own.length)return say('Maceta vacía. No tienes semillas: cómpralas en el growshop de Kiko.');
    const j=await menu(own.map(([k,v])=>({label:getStrain(k).n,right:'×'+v,sw:getStrain(k).c,ic:iconoCogollo(k),desc:strainLine(k)})).concat([{label:'Cancelar',desc:''}]),{cls:'full',title:'¿QUÉ PLANTAS?',desc:true});
    if(j<0||j>=own.length)return;
    const sid=own[j][0];S.seeds[sid]--;if(!S.seeds[sid])delete S.seeds[sid];
    S.pots[i]={sid,prog:0,water:70,health:100,fert:false,pest:false};sfx('sel');
    await accion('plantar');return say(`Has plantado ${getStrain(sid).n}.`);
  }
  const s=getStrain(p.sid);
  if(p.dead){await say(`La ${s.n} se ha secado del todo.`);S.pots[i]=null;return say('Retiras la planta muerta.');}
  if(p.prog>=1){const c=await ask(`${s.n} lista para cosechar.\nSalud ${Math.round(p.health)}% · Agua ${Math.round(p.water)}%`,['Cosechar','Esperar']);if(c===0)await harvest(i);return;}
  const opts=['Regar'];if(!p.fert)opts.push('Abonar');if(p.pest)opts.push('Tratar plaga');opts.push('Arrancar','Salir');
  const c=await ask(`${s.n} · ${stageName(p)} ${Math.floor(p.prog*100)}%\nAgua ${Math.round(p.water)}% · Salud ${Math.round(p.health)}%${p.pest?' · PLAGA':''}`,opts);
  const op=opts[c];
  if(op==='Regar'){const [vx,vy]=posPlaza(i);await accion('regar',{id:'vfx-gotas',x:vx,y:vy-6});p.water=100;sfx('sel');await say('Riegas la planta. Agua al 100%.');}
  else if(op==='Abonar'){if(S.items.fert>0){S.items.fert--;p.fert=true;sfx('sel');await say('Echas FERTILIZANTE. Dará más cosecha.');}else await say('No te queda FERTILIZANTE.');}
  else if(op==='Tratar plaga'){if(S.items.insect>0){S.items.insect--;p.pest=false;sfx('sel');await say('Aplicas INSECTICIDA con guantes y mascarilla. Plaga eliminada.');}else await say('No tienes INSECTICIDA. Kiko lo vende.');}
  else if(op==='Arrancar'){if(await ask('¿Seguro que quieres arrancarla?',['Sí','No'])===0){S.pots[i]=null;await say('Arrancas la planta.');}}
}
// macetas de repuesto que caben en la carpa de la plaza i (y no son la que ya tiene)
function macetasLibres(i){const h=huecos()[i],C=CARPAS[S.carpas[h.c].t];return Object.keys(MACETAS).filter(k=>S.items['m_'+k]>0&&MACETAS[k].l<=C.lmax&&k!==S.macetas[i]);}
async function cambiarMaceta(i){
  const l=macetasLibres(i);if(!l.length)return say('No tienes otra maceta que quepa aquí.');
  const j=await menu(l.map(k=>({label:'Maceta '+MACETAS[k].n,right:'×'+S.items['m_'+k],ic:icono('maceta'),desc:descMaceta(k)})),{cls:'full',title:'CAMBIAR MACETA',title2:'Ahora: '+MACETAS[S.macetas[i]].n,desc:true});
  if(j<0)return;const k=l[j];S.items['m_'+k]--;S.items['m_'+S.macetas[i]]=(S.items['m_'+S.macetas[i]]||0)+1;S.macetas[i]=k;sfx('sel');
  return say(`Pones la maceta de ${MACETAS[k].n}. La vieja va a la mochila.`);
}
const focosLibres=ci=>Object.keys(FOCOS).filter(k=>S.items['f_'+k]>0&&FOCOS[k].w<=CARPAS[S.carpas[ci].t].wmax&&k!==S.carpas[ci].foco);
function instalarFoco(ci,k){const c=S.carpas[ci];S.items['f_'+k]--;S.items['f_'+c.foco]=(S.items['f_'+c.foco]||0)+1;c.foco=k;sfx('sel');}
async function cambiarFoco(ci){
  const l=focosLibres(ci);if(!l.length)return say('No tienes otro foco que aguante esta carpa.');
  const j=await menu(l.map(k=>({label:'Foco '+FOCOS[k].n,right:'×'+S.items['f_'+k],ic:icono('lampara'),desc:descFoco(k)})),{cls:'full',title:'CAMBIAR FOCO',title2:'Ahora: '+FOCOS[S.carpas[ci].foco].n,desc:true});
  if(j<0)return;instalarFoco(ci,l[j]);return say(`Cuelgas el foco ${FOCOS[l[j]].n}. El viejo va a la mochila.`);
}
const extrasLibres=ci=>Object.keys(EXTRAS).filter(k=>!S.carpas[ci][k]&&S.items['x_'+k]>0);
function ponerExtra(ci,k){S.items['x_'+k]--;S.carpas[ci][k]=true;sfx('sel');}
async function carpaAction(ci){
  const c=S.carpas[ci],C=CARPAS[c.t],F=FOCOS[c.foco],f=focosLibres(ci).length,ex=extrasLibres(ci);
  const opts=(f?['Cambiar foco']:[]).concat(ex.map(k=>'Poner '+EXTRAS[k].c.toLowerCase()),['Salir']);
  const k=await ask(`${C.n} · ${C.plazas} plantas\nFoco ${F.n} · luz ${eur(luzCarpa(ci))} al día con plantas`,opts);
  if(opts[k]==='Cambiar foco')return cambiarFoco(ci);
  const x=ex[k-(f?1:0)];if(k<0||!x)return;
  ponerExtra(ci,x);return say(`Pones el ${EXTRAS[x].n.toLowerCase()} en ${/^Armario/.test(C.n)?'el':'la'} ${C.n.toLowerCase()}.\n${EXTRAS[x].d}`);
}
async function harvest(i){
  const p=S.pots[i],s=getStrain(p.sid),f=factores(i);
  const v=genDe(p.sid)<GEN_ESTABLE?.8+Math.random()*.3:1;   // línea inestable: cada planta sale distinta
  const g=Math.max(1,Math.round(s.y*(.4+.6*p.health/100)*(p.fert?1.25:1)*f.rend*v));
  const thc=Math.round((s.thc*(.85+.15*p.health/100)+f.thc+(p.fert?.3:0))*10)/10;
  const [vx,vy]=posPlaza(i);await accion('cosechar');await accion('oler',{id:'vfx-brillo',x:vx,y:vy-12});
  const n=1+ri(0,2);addBuds(p.sid,g,thc);addSeeds(p.sid,n);S.pots[i]=null;sfx('get');
  await say(`Cosechas ${g} g de ${s.n}. THC: ${pct(thc)}%.`);
  await say(`También recoges ${n} semilla${n>1?'s':''} de ${s.n}.`);
  S.flags.harvest1=true;await checkStory();
}
// estabilizar: la línea cruzada consigo misma sube una generación (F1 → F2 → F3 → estable)
async function estabilizar(k){
  const s=getStrain(k),g=genDe(k);
  if(await ask(`¿Estabilizar ${s.n} (F${g})? Gastas 2 semillas y guardas 1.`,['Estabilizar','Cancelar'])!==0)return;
  S.seeds[k]-=2;if(!S.seeds[k])delete S.seeds[k];
  await accion('cruzar',{id:'vfx-polen',x:P.px+8,y:P.py-4});sfx('enc');await fade(1,true);await wait(450);await fade(0,true);
  if(g+1>=GEN_ESTABLE){delete S.gen[k];sfx('get');addSeeds(k,1);await say(`${s.n} ya es una línea estable: todas sus plantas salen iguales.\nGuardas 1 semilla.`);}
  else{S.gen[k]=g+1;addSeeds(k,1);await say(`Guardas 1 semilla F${g+1} de ${s.n}: cultívala para tener más.\n${GEN_ESTABLE-g-1===1?'Falta una generación':'Faltan '+(GEN_ESTABLE-g-1)+' generaciones'} para fijarla.`);}
}
async function bedAction(){
  const c=await ask('Tu cama. Todavía huele a la colonia de la tía.',['Dormir hasta las 7','Siesta de 3 h','Nada']);
  if(c>1)return;
  await fade(1);
  const mins=c===1?180:(((7*60-S.min)+1440)%1440||1440);
  advanceTime(mins);S.hp=S.hpMax;buildEnts();updateHUD();await wait(500);await fade(0);
  const hoy=S.luz&&S.luz.d===S.day&&S.luz;
  save();toast('Has descansado'+(hoy&&hoy.e?' · Luz −'+eur(hoy.e):'')+(hoy&&hoy.o?' · Olor: calor +'+hoy.o:'')+' · Partida guardada',1800);
}
async function pcAction(){
  const o=['Genoteca'].concat(S.ch>=2?['Banco de semillas']:[],['Guardar partida','Apagar']);
  const c=o[await ask('El ordenador de la tía. Tiene su registro de cultivos de veinte años.',o)];
  if(c==='Genoteca')await genoteca();else if(c==='Banco de semillas')await bancoSemillas();
  else if(c==='Guardar partida')await say(save()?'Partida guardada.':'No se ha podido guardar en este navegador.');
}
// banco de semillas (1.9): las landraces de Strainmon, en sobres de 3; el pedido llega por mensajero al día siguiente (newDay)
const BANCO=[['mich',40,2],['punto',55,2],['thai',60,2],['kif',35,2],['beldia',35,2],['chitral',70,3],['nepal',65,3],['congo',60,3],['lamb',60,3],['oaxaca',55,3],['lao',80,4],['panama',90,4]];
async function bancoSemillas(){
  let i=0;
  for(;;){
    const l=BANCO.filter(([,,ch])=>S.ch>=ch);
    const items=l.map(([k,p])=>{const s=STRAINS[k],n=S.pedido.filter(x=>x===k).length;return {label:s.n+(n?' · pedida':''),right:eur(p),sw:s.c,ic:iconoCogollo(k),desc:strainLine(k)+'\n'+s.h};});
    items.push({label:'Salir',desc:'Los pedidos llegan mañana por la mañana.'});
    i=await menu(items,{cls:'full',title:'BANCO DE SEMILLAS',title2:'Sobres de 3 · tienes '+eur(S.money),desc:true,initial:i});
    if(i<0||i>=l.length)return;
    const [k,p]=l[i];
    if(S.money<p){sfx('bad');await say('No te llega el dinero.');continue;}
    S.money-=p;S.pedido.push(k);sfx('coin');toast('Pedido: '+STRAINS[k].n+' · llega mañana',1400);
  }
}
function recibirPedido(){
  if(!S.pedido.length)return;
  const c={};for(const k of S.pedido)c[k]=(c[k]||0)+3;S.pedido=[];
  const n=Object.entries(c).map(([k,v])=>{S.seeds[k]=(S.seeds[k]||0)+v;discover(k);return `${STRAINS[k].n} ×${v}`;});
  queue('pedido',async()=>{sfx('get');await say(`Llega el paquete del banco de semillas:\n${n.join(', ')} semillas.`);await checkStory();});
}
async function letterAction(){
  if(S.flags.letter)return say('La carta de la tía Maite. «Cuida el armario. Y perdona lo de Baltasar.»');
  await say('Hay una carta encima de la mesa. Es de la tía Maite.');
  await talk('CARTA',['«{N}: si lees esto, el piso es tuyo. Cuídalo.»','«Al fondo del salón está mi armario de cultivo. Lo he tenido treinta años y nunca me ha fallado.»','«Pásate por el growshop de Kiko, aquí al lado. Él te enseñará lo que yo no pude.»','«Le debo dinero a Baltasar, el del bar El Ancla. No es buena gente. Lo siento.»']);
  S.flags.letter=true;showObjective();
}
async function labAction(){
  if(!S.flags.lab)return say('Una mesa con un microscopio viejo y frascos. Kiko sabrá qué hacer con esto.');
  const own=()=>Object.entries(S.seeds).filter(([,v])=>v>0);
  if(own().length<2&&!own().some(([k,v])=>v>=2&&genDe(k)<GEN_ESTABLE))return say('MESA DE GENÉTICA: necesitas semillas de dos variedades distintas para cruzar, o 2 de una línea sin estabilizar.');
  const mk=l=>l.map(([k,v])=>({label:getStrain(k).n,right:'×'+v,sw:getStrain(k).c,ic:iconoCogollo(k),desc:strainLine(k)}));
  const l1=own();const a=await menu(mk(l1),{cls:'full',title:'CRUCE · MADRE',desc:true});if(a<0)return;
  const A=l1[a][0];const l2=own().filter(([k])=>k!==A),ga=genDe(A);
  const it2=mk(l2);if(ga<GEN_ESTABLE&&S.seeds[A]>=2)it2.unshift({label:`${getStrain(A).n} · estabilizar`,right:`F${ga}→${ga+1<GEN_ESTABLE?'F'+(ga+1):'estable'}`,sw:getStrain(A).c,ic:iconoCogollo(A),
    desc:`Cruzas dos plantas de la misma línea y guardas la mejor semilla. Gastas 2 y te quedas 1.\nEn la F${GEN_ESTABLE} la variedad queda fijada: todas sus plantas salen iguales.`});
  if(!it2.length)return say(`Para cruzar ${getStrain(A).n} necesitas semillas de otra variedad.`);
  const b=await menu(it2,{cls:'full',title:'CRUCE · PADRE',title2:getStrain(A).n,desc:true});if(b<0)return;
  if(it2.length>l2.length&&b===0)return estabilizar(A);
  const Bk=l2[b-(it2.length-l2.length)][0];
  if(await ask(`¿Cruzar ${getStrain(A).n} × ${getStrain(Bk).n}? Gastas 1 semilla de cada.`,['Cruzar','Cancelar'])!==0)return;
  S.seeds[A]--;S.seeds[Bk]--;for(const k of [A,Bk])if(!S.seeds[k])delete S.seeds[k];
  const r=crossResult(A,Bk),isNew=!S.disc[r],s=getStrain(r);if(isNew)S.gen[r]=1;
  await accion('cruzar',{id:'vfx-polen',x:P.px+8,y:P.py-4});
  sfx('enc');await fade(1,true);await wait(450);await fade(0,true);
  addSeeds(r,2);
  if(isNew){sfx('get');await say(`Nueva variedad: ${s.n}.`);await say(`THC ${pct(s.thc)}% · ${s.y} g/planta · ${String(s.d).replace('.',',')} días.\nObtienes 2 semillas F1: la línea aún no es estable.`);
    if(r==='leyenda'){await say('Te tiemblan las manos: es GHOST TRAIN HAZE.');await talk('SMS · KIKO',['¿Ghost Train Haze? ¿De semilla propia? Llevo veinte años detrás de ella.','Tu tía estaría orgullosa. Estabilízala y guárdala bien: eso vale más que el piso.']);}}
  else await say(`Obtienes 2 semillas de ${s.n}.`);
  await checkStory();
}


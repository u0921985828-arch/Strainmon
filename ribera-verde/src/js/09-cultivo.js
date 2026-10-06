/* =========================================================
   TIEMPO Y CULTIVO
   ========================================================= */
/* ---------- equipo: carpas, focos y macetas ----------
   Carpa: w casillas de ancho (paredes incluidas), 5 de fondo; plazas = w − 2 mesas con una maceta cada una.
   wmax: el foco más potente que admite (calor) · lmax: la maceta más grande que cabe.
   Foco: cubre N plazas a pleno rendimiento; si la carpa tiene más, la luz se reparte (cob < 1) y rinde menos.
   Maceta: la de tela airea las raíces (más cosecha y menos plagas, bebe más); la grande da más pero crece algo más lenta.
   Lo de serie (CFL + plástico 7 L en el armario) da justo lo de antes de la 1.6: factores 1. */
const CARPAS={
  p60:{n:'Armario 60×60',w:4,plazas:2,wmax:250,lmax:11},
  m100:{n:'Carpa 100×100',w:6,plazas:4,wmax:480,lmax:25},
  g150:{n:'Carpa 150×100',w:8,plazas:6,wmax:720,lmax:25}};
const SITIOS=[{x:7,y:2,w:4},{x:12,y:2,w:8}];   // A: el armario de la tía · B: la carpa que compras (100 y, después, 150)
const FOCOS={
  cfl:{n:'CFL 125 W',tipo:'cfl',w:125,cubre:2,rend:1,crec:1,thc:0,agua:1},
  sodio250:{n:'Sodio 250 W',tipo:'sodio',w:250,cubre:2,rend:1.25,crec:1.05,thc:.3,agua:1.3},
  sodio400:{n:'Sodio 400 W',tipo:'sodio',w:400,cubre:4,rend:1.35,crec:1.05,thc:.5,agua:1.4},
  sodio600:{n:'Sodio 600 W',tipo:'sodio',w:600,cubre:6,rend:1.45,crec:1.05,thc:.7,agua:1.5},
  led200:{n:'LED 200 W',tipo:'led',w:200,cubre:2,rend:1.3,crec:1.1,thc:.6,agua:1.05},
  led480:{n:'LED 480 W',tipo:'led',w:480,cubre:4,rend:1.45,crec:1.1,thc:1,agua:1.1},
  led720:{n:'LED 720 W',tipo:'led',w:720,cubre:6,rend:1.6,crec:1.15,thc:1.4,agua:1.15}};
const MACETAS={
  plastico7:{n:'Plástico 7 L',l:7,rend:1,crec:1,agua:1,plaga:1},
  tela11:{n:'Tela 11 L',l:11,rend:1.15,crec:1.05,agua:1.25,plaga:.8},
  plastico18:{n:'Plástico 18 L',l:18,rend:1.25,crec:.95,agua:.8,plaga:1},
  tela25:{n:'Tela 25 L',l:25,rend:1.4,crec:1,agua:1.1,plaga:.8}};
const TARIFA=.02;   // € por vatio y día, solo en las carpas con alguna planta viva (vacías, el foco va apagado)
const signo=v=>(v>=0?'+':'−')+String(Math.abs(Math.round(v))),pc=(t,f)=>Math.abs(f-1)<.001?'':` · ${t} ${signo((f-1)*100)}%`;
const descFoco=k=>{const F=FOCOS[k];return `${F.w} W · cubre ${F.cubre} plantas${pc('cosecha',F.rend)}${pc('crece',F.crec)}${F.thc?' · THC +'+pct(F.thc):''} · riego ×${String(F.agua).replace('.',',')}\nLuz: ${eur(Math.round(F.w*TARIFA))} al día con plantas.`;};
const descMaceta=k=>{const M=MACETAS[k];return `${M.l} L${pc('cosecha',M.rend)}${pc('crece',M.crec)} · riego ×${String(M.agua).replace('.',',')}${M.plaga<1?' · menos plagas':''}`;};
// plazas de cultivo de todas las carpas, en orden: S.pots[i] y S.macetas[i] son la planta y la maceta de la plaza i
let _hk='',_hu=[];
function huecos(){
  const k=S.carpas.map(c=>c?c.t:'-').join();if(k===_hk)return _hu;_hk=k;_hu=[];
  S.carpas.forEach((c,ci)=>{if(!c)return;const s=SITIOS[ci];for(let j=0;j<CARPAS[c.t].plazas;j++)_hu.push({c:ci,j,x:s.x+1+j,y:s.y+2});});
  return _hu;
}
function factores(i){
  const h=huecos()[i],c=S.carpas[h.c],C=CARPAS[c.t],F=FOCOS[c.foco],M=MACETAS[S.macetas[i]]||MACETAS.plastico7;
  const cob=Math.min(1,F.cubre/C.plazas);
  return {rend:(1+(F.rend-1)*cob)*(.6+.4*cob)*M.rend,crec:F.crec*(.85+.15*cob)*M.crec,thc:F.thc*cob,agua:F.agua*M.agua,plaga:M.plaga,cob};
}
const plantasVivas=ci=>huecos().some((h,i)=>h.c===ci&&S.pots[i]&&!S.pots[i].dead);
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
  const luz=facturaLuz();S.luz={d:S.day,e:luz};if(luz>0){S.money=Math.max(0,S.money-luz);if(mode==='world')toast('Factura de la luz: −'+eur(luz),1600);}
  spawnClients();
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
    await accion('plantar');return say(`Has plantado ${getStrain(sid).n}. ¡A crecer!`);
  }
  const s=getStrain(p.sid);
  if(p.dead){await say(`La ${s.n} se ha secado del todo. Una pena.`);S.pots[i]=null;return say('Retiras la planta muerta.');}
  if(p.prog>=1){const c=await ask(`¡${s.n} lista para cosechar!\nSalud ${Math.round(p.health)}% · Agua ${Math.round(p.water)}%`,['Cosechar','Esperar']);if(c===0)await harvest(i);return;}
  const opts=['Regar'];if(!p.fert)opts.push('Abonar');if(p.pest)opts.push('Tratar plaga');opts.push('Arrancar','Salir');
  const c=await ask(`${s.n} · ${stageName(p)} ${Math.floor(p.prog*100)}%\nAgua ${Math.round(p.water)}% · Salud ${Math.round(p.health)}%${p.pest?' · ¡PLAGA!':''}`,opts);
  const op=opts[c];
  if(op==='Regar'){const h=huecos()[i];await accion('regar',{id:'vfx-gotas',x:h.x*16+8,y:h.y*16+8-MESA_ALTO});p.water=100;sfx('sel');await say('Riegas la planta. Agua al 100%.');}
  else if(op==='Abonar'){if(S.items.fert>0){S.items.fert--;p.fert=true;sfx('sel');await say('Echas FERTILIZANTE. Dará más cogollos.');}else await say('No te queda FERTILIZANTE.');}
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
async function carpaAction(ci){
  const c=S.carpas[ci],C=CARPAS[c.t],F=FOCOS[c.foco],f=focosLibres(ci).length;
  const opts=f?['Cambiar foco','Salir']:['Salir'];
  const k=await ask(`${C.n} · ${C.plazas} plantas\nFoco ${F.n} · luz ${eur(luzCarpa(ci))} al día con plantas`,opts);
  if(opts[k]==='Cambiar foco')await cambiarFoco(ci);
}
async function harvest(i){
  const p=S.pots[i],s=getStrain(p.sid),f=factores(i);
  const g=Math.max(1,Math.round(s.y*(.4+.6*p.health/100)*(p.fert?1.25:1)*f.rend));
  const thc=Math.round((s.thc*(.85+.15*p.health/100)+f.thc+(p.fert?.3:0))*10)/10;
  await accion('cosechar');await accion('oler',{id:'vfx-brillo',x:P.px+8,y:P.py+2});
  const n=1+ri(0,2);addBuds(p.sid,g,thc);addSeeds(p.sid,n);S.pots[i]=null;sfx('get');
  await say(`¡Cosechas ${g} g de ${s.n} con ${pct(thc)}% de THC!`);
  await say(`También recoges ${n} semilla${n>1?'s':''} de ${s.n}.`);
  S.flags.harvest1=true;await checkStory();
}
async function bedAction(){
  const c=await ask('Tu cama. Todavía huele a la colonia de la tía.',['Dormir hasta las 7','Siesta de 3 h','Nada']);
  if(c>1)return;
  await fade(1);
  const mins=c===1?180:(((7*60-S.min)+1440)%1440||1440);
  advanceTime(mins);S.hp=S.hpMax;buildEnts();updateHUD();await wait(500);await fade(0);
  save();toast('Has descansado'+(S.luz&&S.luz.d===S.day&&S.luz.e?' · Luz −'+eur(S.luz.e):'')+' · Partida guardada',1800);
}
async function pcAction(){
  const c=await ask('El ordenador de la tía. Tiene una pegatina de un cogollo.',['Genoteca','Guardar partida','Apagar']);
  if(c===0)await genoteca();else if(c===1){await say(save()?'Partida guardada.':'No se ha podido guardar en este navegador.');}
}
async function letterAction(){
  if(S.flags.letter)return say('La carta de la tía Maite. «Cuida el armario. Y perdona lo de Baltasar.»');
  await say('Hay una carta encima de la mesa. Es de la tía Maite.');
  await talk('CARTA',['«{N}: si lees esto, el piso es tuyo. Cuídalo, que la escalera cruje.»','«Al fondo del salón está mi armario de cultivo. Ya sabes de qué hablo.»','«Pásate por el growshop de Kiko, aquí al lado. Él te enseñará.»','«P.D.: Si alguien pregunta por mí en el bar El Ancla... yo no estoy. Lo siento.»']);
  S.flags.letter=true;showObjective();
}
async function labAction(){
  if(!S.flags.lab)return say('Una mesa con un microscopio viejo y frascos. Kiko sabrá qué hacer con esto.');
  const own=()=>Object.entries(S.seeds).filter(([,v])=>v>0);
  if(own().length<2)return say('MESA DE GENÉTICA: necesitas semillas de dos variedades distintas para cruzar.');
  const mk=l=>l.map(([k,v])=>({label:getStrain(k).n,right:'×'+v,sw:getStrain(k).c,ic:iconoCogollo(k),desc:strainLine(k)}));
  const l1=own();const a=await menu(mk(l1),{cls:'full',title:'CRUCE · MADRE',desc:true});if(a<0)return;
  const A=l1[a][0];const l2=own().filter(([k])=>k!==A);
  const b=await menu(mk(l2),{cls:'full',title:'CRUCE · PADRE',title2:getStrain(A).n,desc:true});if(b<0)return;
  const Bk=l2[b][0];
  if(await ask(`¿Cruzar ${getStrain(A).n} × ${getStrain(Bk).n}? Gastas 1 semilla de cada.`,['Cruzar','Cancelar'])!==0)return;
  S.seeds[A]--;S.seeds[Bk]--;for(const k of [A,Bk])if(!S.seeds[k])delete S.seeds[k];
  const r=crossResult(A,Bk),isNew=!S.disc[r],s=getStrain(r);
  await accion('cruzar',{id:'vfx-polen',x:P.px+8,y:P.py-4});
  sfx('enc');await fade(1,true);await wait(450);await fade(0,true);
  addSeeds(r,2);
  if(isNew){sfx('get');await say(`¡NUEVA VARIEDAD! ${s.n}`);await say(`THC ${pct(s.thc)}% · ${s.y} g/planta · ${String(s.d).replace('.',',')} días.\nObtienes 2 semillas.`);
    if(r==='leyenda'){await say('Te tiemblan las manos. Es la LEYENDA DE LA RÍA.');await talk('SMS · KIKO',['¿¿LA LEYENDA DE LA RÍA?? La busco desde hace veinte años.','Tu tía estaría dando saltos. Yo estoy llorando un poco.']);}}
  else await say(`Obtienes 2 semillas de ${s.n}.`);
  await checkStory();
}


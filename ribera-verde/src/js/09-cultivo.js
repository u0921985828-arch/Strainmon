/* =========================================================
   TIEMPO Y CULTIVO
   ========================================================= */
/* ---------- equipo: carpas, focos y macetas ----------
   Carpa: en el piso es un mueble (w casillas de ancho, 1 de fondo; 1 casilla = 1 m) y por dentro se ve en su vista B
   (09b-carpa): cm = ancho, alto y fondo reales; las plazas van en filas de cols macetas (fila 0 delante).
   wmax: el foco más potente que admite (calor) · lmax: la maceta más grande que cabe.
   Cifras reales (1.10): una cosecha da gramos por vatio (gpw) según el foco, repartidos entre las plazas de la carpa (una
   plaza vacía es luz perdida), con el tope de la maceta (≈ 8 g por litro de tierra; la de tela, +5 %) y × el vigor de la
   variedad (s.y / Y_MEDIA), la salud, el abono y el fenotipo. Cultivador medio y bien abonado: CFL ≈ 0,3 g/W, sodio
   0,55-0,7, LED 0,8-1,05. Un día de juego son unas 4 semanas de cultivo: el foco gasta H_LUZ horas (18 h en crecimiento y
   12 en floración) y el extractor y el ventilador, H_24. */
const CARPAS={
  p60:{n:'Armario 60×60',w:1,cm:[60,160,60],cols:2,filas:1,plazas:2,wmax:250,lmax:11},
  p80:{n:'Armario 80×80',w:1,cm:[80,180,80],cols:2,filas:2,plazas:3,wmax:400,lmax:18},
  m100:{n:'Carpa 100×100',w:1,cm:[100,200,100],cols:2,filas:2,plazas:4,wmax:480,lmax:25},
  m120:{n:'Carpa 120×120',w:2,cm:[120,200,120],cols:3,filas:2,plazas:6,wmax:720,lmax:25},
  g150:{n:'Carpa 150×100',w:2,cm:[150,200,100],cols:3,filas:2,plazas:6,wmax:720,lmax:25}};
const SITIOS=[{x:8,y:2,w:1},{x:10,y:2,w:2},{x:2,y:2,w:2}];   // A: el armario de la tía (60 y, después, 80) · B: la carpa que compras (100 y, después, 150), al fondo · C: la carpa 120, junto a la cama
// lado: el cuadrado (cm) que ilumina bien · gpw: g/W sin abono · crec, thc (puntos de THC) y agua: a plena intensidad (W/m² ≥ W_M2)
const FOCOS={
  cfl:{n:'CFL 125 W',tipo:'cfl',w:125,gpw:.25,lado:60,crec:1,thc:0,agua:1},
  sodio250:{n:'Sodio 250 W',tipo:'sodio',w:250,gpw:.45,lado:70,crec:1.05,thc:.3,agua:1.3},
  sodio400:{n:'Sodio 400 W',tipo:'sodio',w:400,gpw:.5,lado:100,crec:1.05,thc:.5,agua:1.4},
  sodio600:{n:'Sodio 600 W',tipo:'sodio',w:600,gpw:.55,lado:120,crec:1.05,thc:.7,agua:1.5},
  led100:{n:'LED 100 W',tipo:'led',w:100,gpw:.65,lado:60,crec:1.05,thc:.3,agua:1},
  led200:{n:'LED 200 W',tipo:'led',w:200,gpw:.7,lado:80,crec:1.1,thc:.6,agua:1.05},
  led480:{n:'LED 480 W',tipo:'led',w:480,gpw:.8,lado:120,crec:1.1,thc:1,agua:1.1},
  led720:{n:'LED 720 W',tipo:'led',w:720,gpw:.85,lado:150,crec:1.15,thc:1.4,agua:1.15}};
// rend: la de tela airea las raíces · cap: gramos como mucho por planta · la grande crece algo más lenta
const MACETAS={
  plastico7:{n:'Plástico 7 L',l:7,rend:1,cap:56,crec:1,agua:1,plaga:1},
  tela11:{n:'Tela 11 L',l:11,rend:1.05,cap:92,crec:1.05,agua:1.25,plaga:.8},
  plastico18:{n:'Plástico 18 L',l:18,rend:1,cap:144,crec:.95,agua:.8,plaga:1},
  tela25:{n:'Tela 25 L',l:25,rend:1.05,cap:210,crec:1,agua:1.1,plaga:.8}};
// extras (1.10): uno de cada por carpa (S.carpas[ci][k] = true); se compran en el growshop (S.items['x_'+k]) y se ponen desde la vista de carpa
const EXTRAS={
  vent:{n:'Ventilador de pinza',c:'Ventilador',w:25,d:'Mueve el aire de la carpa: plagas ×0,7. Gasta 25 W día y noche.'},
  filtro:{n:'Extractor con filtro de carbón',c:'Filtro de carbón',w:75,d:'Sin filtro, cada carpa con plantas en floración suma +2 de calor policial al día por el olor. Con él, nada. Gasta 75 W día y noche.'},
  goteo:{n:'Riego por goteo',c:'Goteo',w:0,d:'Depósito con goteros: el agua baja a la mitad de rápido.'}};
const OLOR=2;   // calor al día por carpa sin filtro con alguna planta en floración (o lista)
const KWH=.16,H_LUZ=392,H_24=672,W_M2=400,Y_MEDIA=34;   // €/kWh (tarifa doméstica) · horas por día de juego · W/m² a plena intensidad · g/planta medio de STRAINS
const signo=v=>(v>=0?'+':'−')+String(Math.abs(Math.round(v))),pc=(t,f)=>Math.abs(f-1)<.001?'':` · ${t} ${signo((f-1)*100)}%`,coma=n=>String(n).replace('.',',');
const gm2=s=>Math.round(W_M2*.85*1.25*s.y/Y_MEDIA/10)*10;   // g/m² de la ficha: LED a 400 W/m², abonada, variedad sana
const kwhFoco=k=>Math.round(FOCOS[k].w*H_LUZ/1000);
const descFoco=k=>{const F=FOCOS[k];return `${F.w} W · ilumina ${F.lado}×${F.lado} cm · ${coma(F.gpw)} g/W (${coma(Math.round(F.gpw*1.25*100)/100)} abonando)${pc('crece',F.crec)}${F.thc?' · THC +'+pct(F.thc):''} · riego ×${coma(F.agua)}\nLuz: ${kwhFoco(k)} kWh (${eur(kwhFoco(k)*KWH)}) al día con plantas.`;};
const descMaceta=k=>{const M=MACETAS[k];return `${M.l} L · hasta ${M.cap} g por planta${pc('cosecha',M.rend)}${pc('crece',M.crec)} · riego ×${coma(M.agua)}${M.plaga<1?' · menos plagas':''}`;};
// plazas de cultivo de todas las carpas, en orden: S.pots[i] y S.macetas[i] son la planta y la maceta de la plaza i
let _hk='',_hu=[];
function huecos(){
  const k=S.carpas.map(c=>c?c.t:'-').join();if(k===_hk)return _hu;_hk=k;_hu=[];
  S.carpas.forEach((c,ci)=>{if(!c)return;for(let j=0;j<CARPAS[c.t].plazas;j++)_hu.push({c:ci,j});});
  return _hu;
}
// g: gramos por planta de la variedad media, sana y sin abono, antes del tope de la maceta · dens: intensidad (W/m² ÷ W_M2, hasta 1)
function factores(i){
  const h=huecos()[i],c=S.carpas[h.c],C=CARPAS[c.t],F=FOCOS[c.foco],M=MACETAS[S.macetas[i]]||MACETAS.plastico7;
  const dens=Math.min(1,F.w/(C.cm[0]*C.cm[2]/1e4*W_M2));
  return {g:F.w*F.gpw/C.plazas*M.rend,cap:M.cap,crec:F.crec*(.85+.15*dens)*M.crec,thc:F.thc*dens,agua:F.agua*M.agua*(c.goteo?.5:1),plaga:M.plaga*(c.vent?.7:1),dens};
}
// gramos de una planta al cosecharla (f: factores de su plaza)
const gramosPlanta=(p,f)=>{const s=getStrain(p.sid),fe=p.f||{y:1};return Math.max(1,Math.round(Math.min(f.cap,f.g*s.y/Y_MEDIA*(.4+.6*p.health/100)*(p.fert?1.25:1)*fe.y)));};
const plantasVivas=ci=>huecos().some((h,i)=>h.c===ci&&S.pots[i]&&!S.pots[i].dead);
const enFlor=ci=>huecos().some((h,i)=>h.c===ci&&S.pots[i]&&!S.pots[i].dead&&S.pots[i].prog>=.65);
const olorDia=()=>S.carpas.reduce((a,c,ci)=>a+(c&&!c.filtro&&enFlor(ci)?OLOR:0),0);
const luzCarpa=ci=>{const c=S.carpas[ci];return Math.round((FOCOS[c.foco].w*H_LUZ+Object.keys(EXTRAS).reduce((a,k)=>a+(c[k]?EXTRAS[k].w:0),0)*H_24)/1000*KWH);};
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
  const sec=S.esquejes.filter(e=>S.day-e.dia>ESQUEJE_DIAS).length;if(sec){S.esquejes=S.esquejes.filter(e=>S.day-e.dia<=ESQUEJE_DIAS);av.push(`Se ${sec>1?'han secado '+sec+' esquejes':'ha secado un esqueje'} sin plantar`);}
  if(av.length&&mode==='world')toast(av.join('<br>'),1600);
  spawnClients();recibirPedido();
  if(S.due>0&&S.flags.metB&&S.day>S.deadline)queue('penalty',penaltyEvent);
}
/* ---------- fenotipo (1.10) ----------
   Cada planta de semilla tira el suyo al germinar (t: THC, y: gramos; σ según tipoGen, 03-datos). Un esqueje es la misma
   planta: copia el fenotipo de su madre, id incluido. Se sabe al cosechar (S.fenos[id] = 'estrella' | 'floja' | 'normal'),
   así que de una planta que sale estrella solo te quedas con ella si antes le sacaste esquejes. */
const ESQUEJE_DIAS=1;   // días que aguanta un esqueje enraizando sin plantar (un día de juego ≈ 4 semanas)
const gauss=()=>{let u=0,v=0;while(!u)u=Math.random();while(!v)v=Math.random();return Math.sqrt(-2*Math.log(u))*Math.cos(2*Math.PI*v);};
const tiraFeno=sg=>{const m=()=>Math.round(clamp(1+sg*gauss(),.6,1.5)*100)/100;return {t:m(),y:m()};};
function rollFeno(sid){S.fenoN++;return Object.assign({id:S.fenoN},tiraFeno(GENETICA[tipoGen(sid)].sigma));}
const claseFeno=f=>!f?'normal':f.t*f.y>=FENO_ESTRELLA?'estrella':f.t*f.y<=FENO_FLOJO?'floja':'normal';
const fenoVisto=f=>f&&f.id&&S.fenos[f.id];   // undefined hasta que se cosecha esa planta o uno de sus esquejes
const marcaFeno=f=>fenoVisto(f)==='estrella'?' ★':fenoVisto(f)==='floja'?' (floja)':'';
async function plantar(i){
  const own=Object.entries(S.seeds).filter(([,v])=>v>0),esq=S.esquejes;
  if(!own.length&&!esq.length)return say('Maceta vacía. No tienes semillas: cómpralas en el growshop de Kiko.');
  const items=own.map(([k,v])=>({label:getStrain(k).n,right:'×'+v,sw:getStrain(k).c,ic:iconoCogollo(k),desc:strainLine(k)}))
    .concat(esq.map(e=>{const s=getStrain(e.sid),v=fenoVisto(e.f);return {label:'Esqueje '+s.n+marcaFeno(e.f),right:'esqueje',sw:s.c,ic:iconoCogollo(e.sid),
      desc:`Clon enraizado: la misma planta que su madre, con su fenotipo.\n${v==='estrella'?`Fenotipo estrella: THC ×${coma(e.f.t)} y cosecha ×${coma(e.f.y)}.`:v==='floja'?'Fenotipo flojo: rinde menos que la media.':'Su fenotipo se sabrá cuando coseches a la madre o a un clon suyo.'}\nSe seca si no lo plantas antes del día ${e.dia+ESQUEJE_DIAS+1}.`};}))
    .concat([{label:'Cancelar',desc:''}]);
  const j=await menu(items,{cls:'full',title:'¿QUÉ PLANTAS?',desc:true});
  if(j<0||j>=own.length+esq.length)return;
  if(j>=own.length){
    const e=esq.splice(j-own.length,1)[0];
    S.pots[i]={sid:e.sid,prog:.12,water:70,health:100,fert:false,pest:false,f:e.f};sfx('sel');   // ya enraizado: empieza de plántula
    await accion('plantar');return say(`Plantas el esqueje de ${getStrain(e.sid).n}${marcaFeno(e.f)}.`);
  }
  const sid=own[j][0];S.seeds[sid]--;if(!S.seeds[sid])delete S.seeds[sid];
  S.pots[i]={sid,prog:0,water:70,health:100,fert:false,pest:false,f:rollFeno(sid)};sfx('sel');
  await accion('plantar');return say(`Has plantado ${getStrain(sid).n}.`);
}
async function sacarEsqueje(i){
  const p=S.pots[i],s=getStrain(p.sid);
  if(S.esquejes.length>=12)return say('El propagador está lleno: 12 esquejes. Planta alguno antes.');
  S.esquejes.push({sid:p.sid,f:p.f||rollFeno(p.sid),dia:S.day});if(!p.f)p.f=S.esquejes[S.esquejes.length-1].f;
  p.health=Math.max(1,p.health-5);sfx('sel');
  return say(`Cortas una punta de la ${s.n} y la pones a enraizar.\nPlántala antes del día ${S.day+ESQUEJE_DIAS+1}: es la misma planta.`);
}
function stageName(p){return p.prog<.12?'Germinando':p.prog<.35?'Plántula':p.prog<.65?'Vegetativo':'Floración';}
async function potAction(i){
  const p=S.pots[i];
  if(!p){
    if(macetasLibres(i).length){const c=await ask(`Plaza vacía con una maceta de ${MACETAS[S.macetas[i]].n}.`,['Plantar','Cambiar maceta','Salir']);if(c===1)return cambiarMaceta(i);if(c!==0)return;}
    return plantar(i);
  }
  const s=getStrain(p.sid);
  if(p.dead){await say(`La ${s.n} se ha secado del todo.`);S.pots[i]=null;return say('Retiras la planta muerta.');}
  if(p.prog>=1){const c=await ask(`${s.n}${marcaFeno(p.f)} lista para cosechar.\nSalud ${Math.round(p.health)}% · Agua ${Math.round(p.water)}%`,['Cosechar','Esperar']);if(c===0)await harvest(i);return;}
  const opts=['Regar'];if(!p.fert)opts.push('Abonar');if(p.pest)opts.push('Tratar plaga');if(p.prog>=.2&&p.prog<.65)opts.push('Sacar esqueje');opts.push('Arrancar','Salir');
  const c=await ask(`${s.n}${marcaFeno(p.f)} · ${stageName(p)} ${Math.floor(p.prog*100)}%\nAgua ${Math.round(p.water)}% · Salud ${Math.round(p.health)}%${p.pest?' · PLAGA':''}`,opts);
  const op=opts[c];
  if(op==='Regar'){const [vx,vy]=posPlaza(i);await accion('regar',{id:'vfx-gotas',x:vx,y:vy-6});p.water=100;sfx('sel');await say('Riegas la planta. Agua al 100%.');}
  else if(op==='Abonar'){if(S.items.fert>0){S.items.fert--;p.fert=true;sfx('sel');await say('Echas una dosis de ABONO. Dará más cosecha.');}else await say('No te queda ABONO.');}
  else if(op==='Tratar plaga'){if(S.items.insect>0){S.items.insect--;p.pest=false;sfx('sel');await say('Aplicas INSECTICIDA con guantes y mascarilla. Plaga eliminada.');}else await say('No tienes INSECTICIDA. Kiko lo vende.');}
  else if(op==='Sacar esqueje')await sacarEsqueje(i);
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
  const k=await ask(`${C.n} · ${C.plazas} plantas · ${F.n}\n${Math.round(F.w/(C.cm[0]*C.cm[2]/1e4))} W/m² · luz ${eur(luzCarpa(ci))} al día con plantas`,opts);
  if(opts[k]==='Cambiar foco')return cambiarFoco(ci);
  const x=ex[k-(f?1:0)];if(k<0||!x)return;
  ponerExtra(ci,x);return say(`Pones el ${EXTRAS[x].n.toLowerCase()} en ${/^Armario/.test(C.n)?'el':'la'} ${C.n.toLowerCase()}.\n${EXTRAS[x].d}`);
}
// cosecha: gramos y THC con el fenotipo de la planta; un fenotipo estrella va a un lote aparte (clave sid + '*', ver lotSid).
// Semillas: las de tienda (SHOP) son feminizadas y salen sin semilla salvo alguna flor hermafrodita (SEMILLA_HERMA); las
// demás (las landraces, como el Afghani que te da Kiko, y tus líneas fijadas) son regulares: algún macho poliniza unas flores y dan 1-3; una línea sin
// fijar (F1-F3) la estás criando: se polinizan entre ellas y das 2-5 semillas por planta para seguir estabilizando
const SEMILLA_HERMA=.12;
async function harvest(i){
  const p=S.pots[i],s=getStrain(p.sid),f=factores(i),fe=p.f||{t:1,y:1},cl=claseFeno(p.f);
  const g=gramosPlanta(p,f);
  const thc=Math.min(35,Math.round((s.thc*fe.t*(.85+.15*p.health/100)+f.thc+(p.fert?.3:0))*10)/10);
  const [vx,vy]=posPlaza(i);await accion('cosechar');await accion('oler',{id:'vfx-brillo',x:vx,y:vy-12});
  const cria=genDe(p.sid)<GEN_ESTABLE,fem=SHOP.some(it=>it.sid===p.sid),n=cria?ri(2,5):!fem||Math.random()<SEMILLA_HERMA?ri(1,3):0;
  addBuds(cl==='estrella'?p.sid+'*':p.sid,g,thc);if(n)addSeeds(p.sid,n);if(p.f&&p.f.id)S.fenos[p.f.id]=cl;S.pots[i]=null;sfx('get');
  await say(`Cosechas ${g} g de ${s.n}. THC: ${pct(thc)}%.`);
  if(cl==='estrella'){sfx('enc');await say(`¡Fenotipo estrella! THC ×${coma(fe.t)} y cosecha ×${coma(fe.y)} sobre la media de la ${s.n}.`);await say('Va a un lote aparte (★). Si le sacaste esquejes, guárdalos: son esta misma planta.');}
  else if(cl==='floja')await say(`Fenotipo flojo: THC ×${coma(fe.t)} y cosecha ×${coma(fe.y)} de la media.`);
  if(n)await say(cria?`Las plantas de la línea se han polinizado entre ellas: recoges ${n} semillas de ${s.n}.`:!fem?`Son semillas regulares: algún macho ha polinizado unas flores. Recoges ${n} semilla${n>1?'s':''} de ${s.n}.`:`Una flor hermafrodita ha polinizado unas pocas: recoges ${n} semilla${n>1?'s':''} de ${s.n}.`);
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
// banco de semillas (1.9): las landraces de Strainmon en sobres de SOBRE semillas, a precio de bancos de conservación
// (1.10: 2-4,50 € la semilla); el pedido llega por mensajero al día siguiente (newDay)
const SOBRE=10,BANCO=[['mich',25,2],['punto',30,2],['thai',30,2],['kif',20,2],['beldia',20,2],['chitral',35,3],['nepal',30,3],['congo',30,3],['lamb',30,3],['oaxaca',25,3],['lao',40,4],['panama',45,4]];
async function bancoSemillas(){
  let i=0;
  for(;;){
    const l=BANCO.filter(([,,ch])=>S.ch>=ch);
    const items=l.map(([k,p])=>{const s=STRAINS[k],n=S.pedido.filter(x=>x===k).length;return {label:s.n+(n?' · pedida':''),right:eur(p),sw:s.c,ic:iconoCogollo(k),desc:strainLine(k)+'\n'+s.h};});
    items.push({label:'Salir',desc:'Los pedidos llegan mañana por la mañana.'});
    i=await menu(items,{cls:'full',title:'BANCO DE SEMILLAS',title2:`Sobres de ${SOBRE} · tienes `+eur(S.money),desc:true,initial:i});
    if(i<0||i>=l.length)return;
    const [k,p]=l[i];
    if(S.money<p){sfx('bad');await say('No te llega el dinero.');continue;}
    S.money-=p;S.pedido.push(k);sfx('coin');toast('Pedido: '+STRAINS[k].n+' · llega mañana',1400);
  }
}
function recibirPedido(){
  if(!S.pedido.length)return;
  const c={};for(const k of S.pedido)c[k]=(c[k]||0)+SOBRE;S.pedido=[];
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
  if(isNew){sfx('get');await say(`Nueva variedad: ${s.n}.`);await say(`THC ${pct(s.thc)}% · ~${gm2(s)} g/m² · ${coma(s.d)} días.\nObtienes 2 semillas F1: la línea aún no es estable.`);
    if(r==='leyenda'){await say('Te tiemblan las manos: es GHOST TRAIN HAZE.');await talk('SMS · KIKO',['¿Ghost Train Haze? ¿De semilla propia? Llevo veinte años detrás de ella.','Tu tía estaría orgullosa. Estabilízala y guárdala bien: eso vale más que el piso.']);}}
  else await say(`Obtienes 2 semillas de ${s.n}.`);
  await checkStory();
}


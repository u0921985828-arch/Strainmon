/* =========================================================
   LA PLANTILLA (1.19): gente del barrio que trabaja para ti
   ========================================================= */
// MÓVIL → PLANTILLA (desde el capítulo PLANTILLA.ch): Patxi te manda a alguien del barrio por un sobre (no sabes a quién hasta que
// llega) con tres números del 1 al 5: labia (vende más y le timan menos), cuidado (le pillan y le atracan menos; en la nave, cultiva
// más) y lealtad (se larga menos con lo tuyo y, de gerente, sisa menos). Hasta PLANTILLA.max. Trabajos: a la calle con un lote (vende a
// precio de calle del barrio y se queda PLANTILLA.com), de gerente en casa (uno: cuida las plantas como Begoña, cosecha lo que esté
// listo al arcón quitando su sisa y, con él, los de la calle se largan la mitad) o en la nave de Valdehierro (NAVE: la alquila
// Arrieta desde el capítulo NAVE.ch; cada trabajador saca naveG gramos al día de la variedad que elijas). Gerente y nave cobran
// cada mañana; sin dinero, lo dejan. 1.30: se entra en la nave (11j-locales); cuatro mesas de cultivo (S.nave.m), una por
// trabajador, que plantas tú con una semilla o un esqueje; a los NAVE.crece días dan cada mañana naveG × su rendimiento, con el
// abono de floración que elijas por mesa (una dosis al día de la estantería, S.nave.ab) al secadero
const BARRIO=['Mikel','Jaione','Koldo','Edurne','Txema','Arantza','Iker','Garazi','Peio','Amaia','Oier','Itziar'];
const PLANTILLA={ch:3,sobre:150,max:6,lotes:[25,50,100],com:.3,g:[2,4],poli:.05,poliC:.01,robo:.08,roboC:.015,timo:.06,timoL:.01,fuga:.06,calor:.5,calorPoli:10,sueldo:{gerente:40,nave:30,madres:30},sisa:.03};
const NAVE={ch:5,fianza:3000,dia:60,max:4,g:20,gC:2,thc:.9,redada:.02,redadaC:.003,calor:20,crece:5};
const fichaGente=w=>`Labia ${w.lab} · cuidado ${w.cui} · lealtad ${w.lea}`;
const gerente=()=>S.plantilla.find(w=>w.rol==='gerente')||null,naveros=()=>S.plantilla.filter(w=>w.rol==='nave');
const deLaNave=()=>S.plantilla.filter(w=>w.rol==='nave'||w.rol==='madres');   // 1.34: con el de las madres (cuidaMadres, 11j-locales)
// llevar a la gente (1.34, lo pidió el usuario: «menús para controlar más a la peña»): una prima (MANDO.prima: lealtad +1) y un curso
// (MANDO.curso: cuidado +1; a los de la calle, labia +1), hasta 5, cada uno una vez cada MANDO.dias días por persona (w.pr, w.cu1)
const MANDO={prima:100,curso:250,dias:7};
const cursoDe=w=>w.rol==='calle'?['lab','labia']:['cui','cuidado'];
// la mesa de cada trabajador de la nave (1.31: w.mesa, la suya mientras trabaje allí; antes, el orden de la plantilla): quién cuida la
// mesa i y la mesa que le toca al que llega (la primera plantada sin nadie y, si no, la primera libre)
const naveroDe=i=>S.plantilla.find(w=>w.rol==='nave'&&w.mesa===i)||null;
function mesaLibre(){const L=[...Array(NAVE.max).keys()].filter(i=>!naveroDe(i));return L.find(i=>S.nave.m[i])??L[0];}
const naveG=w=>NAVE.g+NAVE.gC*(w.cui-3);
const rolTxt=w=>w.rol==='calle'?'calle · '+gTxt(w.g):w.rol||'sin trabajo';
function rolDesc(w){const P=PLANTILLA;
  return w.rol==='calle'?`Vende ${lotNombre(w.k)} en la calle: le quedan ${gTxt(w.g)}.`:w.rol==='gerente'?`Cuida el piso y cosecha al arcón por ${eur(P.sueldo.gerente)} al día.`
    :w.rol==='nave'?`Cultiva la mesa ${w.mesa+1} de la nave por ${eur(P.sueldo.nave)} al día: ${naveG(w)} g.`
    :w.rol==='madres'?`Cuida las madres de la nave por ${eur(P.sueldo.madres)} al día y les saca esquejes.`:'Dale trabajo: calle, gerente, nave o las madres.';}
// deja el trabajo; lo que le quedaba del lote vuelve al arcón
function libre(w){if(w.rol==='calle'&&w.g>=1)addBuds(w.k,w.g,w.thc,S.arcon.buds,w.cu,w.dia??null);w.rol=null;delete w.k;delete w.thc;delete w.g;delete w.cu;delete w.dia;delete w.mesa;}
async function plantilla(){
  let i=0;
  for(;;){
    const L=S.plantilla,rows=L.map(w=>({label:w.n,right:rolTxt(w),desc:fichaGente(w)+'. '+rolDesc(w)}));
    if(L.length<PLANTILLA.max)rows.push({label:'Pedir gente a Patxi',right:eur(PLANTILLA.sobre),desc:'Patxi te manda a alguien del barrio que quiere currar. No sabes a quién hasta que llega.'});
    i=await menu(rows,{cls:'full',title:'PLANTILLA',title2:`${L.length} de ${PLANTILLA.max}`+(S.nave?` · nave ${gTxt(naveStock())}`:''),desc:true,initial:Math.min(i,rows.length-1)});
    if(i<0)return;
    if(i>=L.length)await pedirGente();else await trabajo(L[i]);
  }
}
async function pedirGente(){
  const P=PLANTILLA,libres=BARRIO.filter(n=>!S.plantilla.some(w=>w.n===n));
  if(S.money<P.sobre){sfx('bad');return say(`Patxi cobra ${eur(P.sobre)} por el sobre. No te llega.`);}
  if(!libres.length)return say('Patxi ya no conoce a nadie más que quiera currar.');
  S.money-=P.sobre;
  const n=pick(libres),w={id:'pl'+(++S.plN),n,lab:ri(1,5),cui:ri(1,5),lea:ri(1,5),rol:null},t=w.lab+w.cui+w.lea;sfx('get');
  await talk('SMS · PATXI',[`Te mando a ${n}. ${t>=12?'Vale oro.':t<=6?'No es gran cosa, pero quiere currar.':'Gente normal del barrio.'}`]);
  if(await ask(`${n}: ${fichaGente(w)}. ¿Le contratas?`,['Contratar','No'])!==0)return say(`${n} se va por donde ha venido. El sobre ya es de Patxi.`);
  S.plantilla.push(w);sfx('sel');return say(`${n} entra en tu plantilla. Dale trabajo desde aquí.`);
}
// un lote de los de encima para la calle: [clave, THC, gramos, {dia, cu} (1.29)] o null
async function loteCalle(w){
  const P=PLANTILLA,lots=budLots(P.lotes[0]);
  if(!lots.length){await say(`Para la calle hace falta un lote de ${P.lotes[0]} g o más encima.`);return null;}
  const i=await menu(lots.map(lotItem).concat([{label:'Nada'}]),{cls:'right',title:'¿Qué lote le das?'});if(i<0||i>=lots.length)return null;
  const [k,b]=lots[i],ops=P.lotes.filter(g=>g<=Math.floor(b.g));
  const j=await ask(`${w.n} vende a precio de calle y se queda el ${pct0(P.com)} %. ¿Cuánto le das?`,ops.map(g=>g+' g').concat(['Nada']));if(j<0||j>=ops.length)return null;
  const thc=b.thc,c=curaDe(b);useBuds(k,ops[j]);return [k,thc,ops[j],c];
}
async function trabajo(w){
  const P=PLANTILLA,ops=[];
  if(w.rol!=='calle')ops.push('A la calle');
  if(w.rol!=='gerente'&&!gerente())ops.push('De gerente');
  if(w.rol!=='nave'&&S.nave&&naveros().length<NAVE.max)ops.push('A la nave');
  if(w.rol!=='madres'&&S.nave&&!cuidaMadres())ops.push('A las madres');
  if(w.rol)ops.push('Dejarlo libre');ops.push(`Prima · ${eur(MANDO.prima)}`,`Curso · ${eur(MANDO.curso)}`,'Despedir','Nada');
  const op=ops[await ask(`${w.n} · ${fichaGente(w)} · ${rolTxt(w)}`,ops)];
  if(op==='A la calle'){const r=await loteCalle(w);if(!r)return;libre(w);w.rol='calle';[w.k,w.thc,w.g]=r;Object.assign(w,r[3]);sfx('sel');return say(`${w.n}: «Hecho. Cada día te dejo lo vendido en el buzón».`);}
  if(op==='De gerente'){libre(w);w.rol='gerente';sfx('sel');return say(`${w.n}: «Cada mañana me paso por el piso: riego, trato las plagas y lo que esté listo lo cosecho y lo dejo en el arcón. ${eur(P.sueldo.gerente)} al día».`);}
  if(op==='A la nave'){libre(w);w.mesa=mesaLibre();w.rol='nave';sfx('sel');return say(`${w.n}: «Mañana empiezo en la mesa ${w.mesa+1} de la nave. ${eur(P.sueldo.nave)} al día».`);}
  if(op==='A las madres'){libre(w);w.rol='madres';sfx('sel');return say(`${w.n}: «Mañana empiezo con las madres de la nave: riego, poda y esquejes. ${eur(P.sueldo.madres)} al día».`);}
  if(op&&op.startsWith('Prima'))return prima(w);
  if(op&&op.startsWith('Curso'))return curso(w);
  if(op==='Dejarlo libre'){const g=w.rol==='calle'?w.g:0;libre(w);return say(g>=1?`${w.n} te deja lo que le quedaba en el arcón: ${gTxt(g)}.`:`${w.n} se queda sin trabajo.`);}
  if(op==='Despedir'){if(await ask(`¿Despides a ${w.n}?`,['Despedir','No'])!==0)return;
    const g=w.rol==='calle'?w.g:0;libre(w);S.plantilla=S.plantilla.filter(x=>x!==w);return say(`${w.n} se va.`+(g>=1?` Lo que le quedaba, ${gTxt(g)}, está en el arcón.`:''));}
}
async function prima(w){
  if(S.day-(w.pr??-MANDO.dias)<MANDO.dias)return say(`A ${w.n} ya le diste una prima el día ${w.pr}. Hasta el ${w.pr+MANDO.dias}, no.`);
  if(w.lea>=5)return say(`${w.n} ya te es leal del todo: una prima no le cambia nada.`);
  if(S.money<MANDO.prima){sfx('bad');return say('No te llega.');}
  S.money-=MANDO.prima;w.pr=S.day;w.lea++;sfx('coin');updateHUD();
  return say(`${w.n}: «Gracias, jefe. Aquí me tienes». Lealtad ${w.lea}.`);
}
async function curso(w){
  const [k,n]=cursoDe(w);
  if(w[k]>=5)return say(`${w.n} ya tiene ${n} 5: no hay curso que le enseñe más.`);
  if(S.day-(w.cu1??-MANDO.dias)<MANDO.dias)return say(`${w.n} hizo un curso el día ${w.cu1}. Hasta el ${w.cu1+MANDO.dias}, no.`);
  if(S.money<MANDO.curso){sfx('bad');return say('No te llega.');}
  S.money-=MANDO.curso;w.cu1=S.day;w[k]++;sfx('coin');updateHUD();
  return say(`${w.n} hace un curso ${k==='lab'?'de venta: a tratar con la gente':'de cultivo: riego, plagas y poda'}. ${n[0].toUpperCase()+n.slice(1)} ${w[k]}.`);
}
// el gerente, cada mañana: cuida las plantas y cosecha las que están listas al arcón (su sisa, por la lealtad); da los gramos
function cuidarCasa(w){
  cuidarPlantas();let tot=0;
  S.pots.forEach((p,i)=>{if(!p||p.dead||p.prog<1)return;
    const f=factores(i),g=gramosPlanta(p,f),thc=thcCosecha(p,f),cl=claseFeno(p.f),{n}=semillasCosecha(p),q=g-Math.floor(g*PLANTILLA.sisa*(5-w.lea));
    if(q>=1)addBuds(cl==='estrella'?p.sid+'*':p.sid,q,thc,S.arcon.buds);if(n)addSeeds(p.sid,n);
    if(p.f&&p.f.id)S.fenos[p.f.id]=cl;if(S.rec[p.sid]===1)S.rec[p.sid]=2;S.pots[i]=null;tot+=q;});
  if(tot){S.flags.harvest1=true;queue('gerente',()=>talk('SMS · '+w.n.toUpperCase(),[`He cosechado ${tot} g. Está en el arcón.`]));queue('historia',checkStory);}
  return tot;
}
// al amanecer (desde curroDia): sueldos, el gerente, la calle y la nave
function plantillaDia(){
  const P=PLANTILLA,fuera=[];let vende=false;naveAlquiler();
  for(const w of S.plantilla){if(!P.sueldo[w.rol])continue;   // gerente, nave y madres (1.34)
    if(S.money<P.sueldo[w.rol]){w.rol=null;queue('pl'+w.id,()=>talk('SMS · '+w.n.toUpperCase(),['Sin cobrar no curro. Cuando tengas el dinero, me llamas.']));}
    else S.money-=P.sueldo[w.rol];}
  const ger=gerente();if(ger)cuidarCasa(ger);
  for(const w of S.plantilla){if(w.rol!=='calle')continue;
    const N='SMS · '+w.n.toUpperCase(),lote=lotNombre(w.k),r=Math.random(),pp=P.poli-P.poliC*(w.cui-1),pr=pp+P.robo-P.roboC*(w.cui-1),
      pf=pr+P.fuga*(5-w.lea)/4*(ger?.5:1),pt=pf+P.timo-P.timoL*(w.lab-1);let m;
    if(r<pp){S.heat=Math.min(100,S.heat+P.calorPoli);m=`Me ha parado la policía. Se han quedado con ${gTxt(w.g)} de ${lote}. Lo siento.`;w.g=0;}
    else if(r<pr){const q=Math.ceil(w.g/2);w.g-=q;m=`Me han atracado en un portal. Se han llevado ${gTxt(q)} de ${lote}.`+(w.g>=1?` Me quedan ${gTxt(w.g)}.`:'');}
    else if(r<pf){fuera.push(w);const g=w.g;queue('pl'+w.id,()=>say(`${w.n} no contesta al móvil. Se ha largado con ${gTxt(g)} de ${lote}.`));continue;}
    else{const q=Math.min(Math.floor(w.g),ri(P.g[0],P.g[1])*w.lab);w.g-=q;
      if(r<pt)m=`Me han pagado ${q} g con billetes falsos. No me he dado cuenta hasta el banco.`;
      else{const e=Math.round(precioCalle(w.thc)*calidad(w)*ZONAS.town.precio*q*(1-P.com));S.money+=e;S.sales+=e;S.heat=Math.min(100,S.heat+P.calor);vende=true;
        m=w.g>=1?`Vendidos ${q} g: ${eur(e)} en tu buzón. Me quedan ${gTxt(w.g)}.`:`Vendidos los últimos ${q} g: ${eur(e)} en tu buzón. Dame más cuando quieras.`;}}
    if(w.g<1)libre(w);queue('pl'+w.id,()=>talk(N,[m]));
  }
  if(fuera.length)S.plantilla=S.plantilla.filter(w=>!fuera.includes(w));
  if(vende)queue('historia',checkStory);   // 1.22: lo vendido cuenta para la historia
  naveDia();
}
// la nave: el alquiler, lo primero de la mañana (antes que los sueldos; sin él, Arrieta cambia la cerradura y se queda la fianza)
function naveAlquiler(){
  if(!S.nave)return;
  if(S.money<NAVE.dia){deLaNave().forEach(libre);S.nave=null;queue('nave',()=>talk('SMS · ARRIETA',['No me has pagado la nave. Cambio la cerradura y me quedo la fianza.']));return;}
  S.money-=NAVE.dia;
}
// después de la calle, la redada (menos con cuidado) y lo que da cada mesa que ya da (1.30): cada trabajador cuida la suya (w.mesa);
// naveG × el rendimiento de lo plantado y, con su abono y dosis en la estantería, lo del abono (ABONO, ABONO_BIO), al secadero de
// esa mesa (M.g, con su THC medio, M.t, y el día de la cosecha de lo más viejo que cuelga, M.cd: 1.31; lo de menos de 1 g no se recoge y no cuenta)
function naveDia(){
  const N=S.nave;if(!N)return;
  madresDia();   // 1.34
  const W=naveros();if(!W.length||!N.m.some(Boolean))return;
  if(Math.random()<Math.max(0,NAVE.redada-NAVE.redadaC*Math.max(...W.map(w=>w.cui)))*EXTR_NAVE[N.ex].olor){   // 1.33: con los filtros, huele menos
    const ns=deLaNave().map(w=>w.n),quien=ns.length>1?ns.slice(0,-1).join(', ')+' y '+ns[ns.length-1]:ns[0],g=naveStock();
    S.nave=null;S.plantilla=S.plantilla.filter(w=>w.rol!=='nave'&&w.rol!=='madres');S.heat=Math.min(100,S.heat+NAVE.calor);sfx('bad');
    queue('nave',()=>say(`La policía ha entrado en la nave de Valdehierro. Se lleva las plantas${g>=1?', '+gTxt(g):''} y a ${quien}.`));return;}
  // 1.33: × los focos de su mesa (FOCO_NAVE), el riego (RIEGO_NAVE: también lo que gasta de abono, R.dosis) y el calor que no saca la extracción
  const R=RIEGO_NAVE[N.rg],so=sofocoNave();
  W.forEach(w=>{const M=N.m[w.mesa];if(!M||S.day-M.dia<NAVE.crece)return;const F=FOCO_NAVE[N.f[w.mesa]];
    let g=naveG(w)*M.y*F.rend*(1+R.rend)*so,thc=M.thc+F.thc+R.thc;
    if(M.abo===1&&N.ab.m>=R.dosis){N.ab.m=Math.round((N.ab.m-R.dosis)*10)/10;g*=1+ABONO.rend;thc+=ABONO.thc;}
    else if(M.abo===2&&N.ab.o>=R.dosis){N.ab.o=Math.round((N.ab.o-R.dosis)*10)/10;g*=1+ABONO_BIO.rend;thc+=ABONO_BIO.thc;}
    g=Math.round(g*10)/10;if(!(M.g>=1))M.cd=S.day;M.t=Math.round((M.t*M.g+thc*g)/(M.g+g)*10)/10;M.g=Math.round((M.g+g)*10)/10;});
}
// las madres de la nave, cada mañana (1.34, MADRES en 11j-locales): con quien las cuide, a 100 de vigor y con sus esquejes; sin nadie,
// se apagan y, a 0, se mueren
function madresDia(){
  const N=S.nave,c=cuidaMadres();if(!N.ma.length)return;let muertas=0;
  N.ma=N.ma.filter(M=>{if(c){M.v=100;M.e=Math.min(MADRES.tope,M.e+MADRES.esq+(c.cui>=4?1:0));return true;}
    M.v=Math.max(0,M.v-MADRES.pierde);if(M.v>0)return true;muertas++;return false;});
  if(muertas)queue('madres',()=>say(muertas>1?`Sin nadie que las cuide, se han muerto ${muertas} madres de la nave.`:'Sin nadie que la cuide, se ha muerto una madre de la nave.'));
}
// Arrieta, el dueño de la nave de Valdehierro
NPCDEF.push({id:'arrieta',map:'valdehierro',x:17,y:7,dir:'down',look:'arrieta',talk:()=>talkNave()});
async function talkNave(){
  const A='ARRIETA',N=S.nave;
  if(S.ch<NAVE.ch)return say('La nave no se alquila. Ahora mismo, no.',A);
  if(!N){
    if(await ask(`La nave está vacía: ${eur(NAVE.fianza)} de fianza y ${eur(NAVE.dia)} al día, que te cobro cada mañana. Sin preguntas.`,['Alquilarla','No'],A)!==0)return;
    if(S.money<NAVE.fianza){sfx('bad');return say('Sin la fianza no hay llave.',A);}
    S.money-=NAVE.fianza;S.nave=naveNueva();sfx('coin');await got('la llave de la nave');
    return say(`Dentro hay ${NAVE.max} mesas de cultivo, una por persona. Pon a tu gente desde el móvil y planta tú lo que quieras.`,A);
  }
  const op=['Dejar la nave','Nada'][await ask(`La nave: ${N.m.filter(Boolean).length} de ${NAVE.max} mesas plantadas · ${naveros().length} de ${NAVE.max} trabajando. Lo demás, dentro.`,['Dejar la nave','Nada'],A)];
  if(op==='Dejar la nave'){
    if(await ask(`¿Dejas la nave? Te devuelvo la fianza${naveStock()>=1?'; lo que no recojas se queda aquí':''}.`,['Dejarla','No'],A)!==0)return;
    deLaNave().forEach(libre);S.nave=null;S.money+=NAVE.fianza;sfx('coin');return say('Trato hecho. Si la quieres otra vez, ya sabes dónde estoy.',A);
  }
}

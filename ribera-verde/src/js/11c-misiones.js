/* =========================================================
   MISIONES GUIADAS (1.11)
   ========================================================= */
// lo que hay que montar para llegar a los plazos de la deuda: la ruta guiada de docs/ANALISIS.md. Salen desde que conoces a Kiko,
// las de tu capítulo y las de antes, en START → OBJETIVO. ok() mira lo que tienes, no lo que pasó: lo que ya tengas se cumple al
// llegar a su capítulo. Al cumplir una, Kiko manda un SMS y deja un regalo (p: objetos, s: semillas; nunca dinero).
// S.misiones[id] = día en que se cumplió (0: partida vieja, de un capítulo anterior, sin regalo)
const precioDe=f=>SHOP.find(f).p;
const conFoco=()=>S.carpas.filter(c=>c&&FOCOS[c.foco]);
// 1.28: las de receta que pasan la marca de Darko (COPA_THC) con su THC, el LED de 720 W y el abono de floración entero
const POTENTES=(r=>DEX.filter(k=>r.has(k)&&STRAINS[k].thc+FOCOS.led720.thc+ABONO.thc>COPA_THC))(new Set(Object.values(RECIPES).concat(Object.values(RECETA_ORD))));
const MISIONES=[
  {id:'caja',ch:1,t:'La caja de la tía',d:'Tu tía guardaba dinero en casa. Mira sus notas en el ordenador: la combinación de la caja fuerte, detrás del diploma.',
    ok:()=>!!S.caja,sms:['Lo de la caja de tu tía ya lo sabía yo. Gástalo bien.']},
  {id:'luz',ch:1,t:'Luz de verdad',d:`El CFL da poco. En el growshop: un LED de 100 W (${eur(precioDe(it=>it.foco==='led100'))}) y macetas de tela de 11 L (${eur(precioDe(it=>it.maceta==='tela11'))} cada una).`,
    ok:()=>conFoco().some(c=>c.foco!=='cfl'),p:{fertv:2},sms:['Ese LED da casi el triple que el CFL por vatio.']},
  {id:'carpa',ch:2,t:'Una carpa',d:`Con el armario no llegas al primer plazo. Una carpa de 100 (${eur(precioDe(it=>it.carpa==='m100'))}) y un sodio de 250 W (${eur(precioDe(it=>it.foco==='sodio250'))}): cuatro plantas más.`,
    ok:()=>S.carpas.filter(Boolean).length>=2,s:{txoko:3},sms:['Con la carpa ya produces de verdad. Ponle buena luz.','Y un extractor con filtro: el olor sube el calor.']},
  {id:'olor',ch:2,t:'Sin olor',d:`Las plantas en flor huelen y el olor sube el calor cada día. Un extractor de 100 mm con filtro (${eur(precioDe(it=>it.extra==='filtro100'))}) en la carpa.`,
    ok:()=>S.carpas.some(c=>kitDe(c)),p:{insect:1},sms:['Sin olor, los vecinos no hablan.']},
  {id:'inaki',ch:2,t:'Iñaki',d:`Iñaki, en el muelle, compra 10 g al día: paga más que la calle y sube menos el calor. Si el calor llega a ${NIVEL_POLI[2][0]}, la policía investiga.`,
    ok:()=>!!S.flags.inaki,p:{fert:2},sms:['Iñaki es de fiar. Cuando empiece lo de la deuda, te comprará también al por mayor.']},
  {id:'mayor',ch:3,t:'El barco',d:'Iñaki ya compra al por mayor: de 100 g para arriba, una carga al día. Es lo que paga la deuda: en la calle, el calor sube demasiado.',
    ok:()=>S.mDay>0,p:{fert:4},sms:['Así se paga una deuda: por kilos y sin ruido.']},
  {id:'potencia',ch:3,t:'Más luz',d:`Un sodio de 400 W (${eur(precioDe(it=>it.foco==='sodio400'))}) en la carpa de 100 y el de 250 W al armario: más vatios, más gramos.`,
    ok:()=>conFoco().some(c=>FOCOS[c.foco].w>=400),p:{phm:10},sms:['Más vatios, más gramos. Vigila el riego: el sodio seca las macetas.']},
  {id:'led',ch:4,t:'Escalar',d:`Un LED de 480 W (${eur(precioDe(it=>it.foco==='led480'))}): más gramos por vatio y menos calor en la carpa. El segundo plazo es de ${eur(PLAZOS[5])}.`,
    ok:()=>conFoco().some(c=>FOCOS[c.foco].tipo==='led'&&FOCOS[c.foco].w>=480),p:{fert:4},sms:['Con LED grandes, la luz se paga sola.']},
  {id:'seis',ch:4,t:'Seis plazas',d:`La carpa de 150 en lugar de la de 100 (${eur(precioDe(it=>it.carpa==='g150'))}) y, en el capítulo 5, la de 120 junto a la cama: seis plantas cada una.`,
    ok:()=>S.carpas.some(c=>c&&CARPAS[c.t].plazas>=6),s:{txoko:5},sms:['Seis plantas por carpa. Esto ya es un negocio.']},
  // 1.28: la Copa, hasta pasar la marca de Darko (al ganarla, las que falten se cierran: cerrarCopa)
  {id:'potente',ch:6,t:'Una genética potente',d:`Darko presenta una Amnesia Haze del ${pct(COPA_THC)} %. Para pasarla, una de receta del ${Math.min(...POTENTES.map(k=>STRAINS[k].thc))} % o más (${yLista(POTENTES.map(k=>STRAINS[k].n))}). La más a mano, la ${STRAINS.dragon.n}: ${STRAINS.chemdawg.n} (${eur(precioDe(it=>it.sid==='chemdawg'))}) × ${STRAINS.txoko.n} (${eur(precioDe(it=>it.sid==='txoko'))}) en la mesa.`,
    ok:()=>POTENTES.some(k=>S.rec[k]),p:{fert:4,phm:4},sms:['Con esa ya puedes plantarle cara a Darko. Ahora, a sacarle todo el THC.']},
  {id:'flor27',ch:6,t:'Floración a tope',d:`El THC sube con la luz y el abono: el LED de 720 W (${eur(precioDe(it=>it.foco==='led720'))}, en la carpa de 120 o la de 150), +${pct(FOCOS.led720.thc)}, y MEATZA FLORACIÓN con pH− y el medidor de pH y EC (${eur(precioDe(it=>it.item==='medidor'))}), +${pct(ABONO.thc)} si lo aprovecha entero (ORTUA BIO, +${pct(ABONO_BIO.thc)}).`,
    ok:()=>S.pots.some((p,i)=>{const h=huecos()[i];return p&&!p.dead&&fq(p)>=1&&h&&S.carpas[h.c].foco==='led720';}),p:{ofert:2,ophm:2},sms:['Así, a tope. Ahí tienes ORTUA BIO para la próxima: el orgánico da algo más de THC.']},
  {id:'copa27',ch:6,t:'Llegar al 27 %',d:`20 g de un solo lote con más del ${pct(COPA_THC)} % de THC, en la mochila. Cosecha la mejor y preséntala antes de cosechar otra de la misma variedad: el lote se queda con la media (la de fenotipo estrella ★ va aparte). Sin curar, a los ${CURADO.fresco} días empieza a perder THC: preséntala antes o cúrala en el arcón con tarros.`,
    ok:()=>budLots(20).some(([,b])=>Math.round(b.thc*10)/10>COPA_THC),sms:['Con eso le ganas a Darko. Llévaselo al jurado de la plaza antes de venderlo.']}];
const cerrarCopa=()=>MISIONES.forEach(m=>{if(m.ch===6&&!(m.id in S.misiones))S.misiones[m.id]=0;});   // ganada la Copa, sin aviso ni regalo
const PREMIO_N={fert:'dosis de MEATZA FLORACIÓN',fertv:'dosis de MEATZA CRECIMIENTO',phm:'dosis de pH− MEATZA',ofert:'dosis de ORTUA BIO FLORACIÓN',ofertv:'dosis de ORTUA BIO CRECIMIENTO',ophm:'dosis de pH− ORTUA BIO',insect:'tratamiento de INSECTICIDA'};
const premioTxt=m=>Object.entries(m.p||{}).map(([k,n])=>`${n} ${PREMIO_N[k]}`).concat(Object.entries(m.s||{}).map(([k,n])=>`${n} semillas de ${STRAINS[k].n.toUpperCase()}`));
const misionesVer=()=>S.flags.kiko1?MISIONES.filter(m=>m.ch<=S.ch):[];
const misionSig=()=>misionesVer().find(m=>!(m.id in S.misiones));
let misionAviso=[];
// run() la llama al acabar cada guion: marca las cumplidas, da el regalo y encola el SMS
function revisaMisiones(){
  revisaItinerario();   // 1.23 (11h-guia)
  for(const m of misionesVer())if(!(m.id in S.misiones)&&m.ok()){
    S.misiones[m.id]=S.day;misionAviso.push(m.id);
    for(const k in m.p||{})S.items[k]+=m.p[k];for(const k in m.s||{})addSeeds(k,m.s[k]);
  }
  if(misionAviso.length)queue('mision',avisoMision);
  revisaLogros();   // 1.27 (11i-logros)
}
async function avisoMision(){
  while(misionAviso.length){
    const id=misionAviso.shift(),m=MISIONES.find(x=>x.id===id);sfx('get');toast(`<small>MISIÓN CUMPLIDA</small>${m.t}`,2400);
    await talk('SMS · KIKO',m.sms);for(const t of premioTxt(m))await got(t);
  }
  const s=misionSig(),h=conLogro(s?`<small>MISIÓN</small>${s.t}`:'');if(h)toast(h,3200);
}
// el plazo (1.11): Toño avisa cuando quedan 3 días y el último, con lo que llevas
async function recuerdoPlazo(){
  const n=S.deadline-S.day,ll=S.money+cajaE();   // los días, como los cuenta Baltasar (talkBaltasar)
  await talk('SMS · TOÑO',[n>0?`Don Baltasar quiere ${eur(S.due)} antes de que acabe el día ${S.deadline}. Te quedan ${n} días.`:`Hoy es el último día para los ${eur(S.due)} de Don Baltasar.`]);
  await say(ll<S.due?`Llevas ${eur(ll)} entre el bolsillo y la caja: te faltan ${eur(S.due-ll)}.`:`Llevas ${eur(ll)} entre el bolsillo y la caja: ya lo tienes.${S.money<S.due?' Saca lo que falte de la caja y':''} Ve al bar El Ancla.`);
}
// START → OBJETIVO: el del capítulo, las misiones (con lo que hay que hacer abajo) y la deuda
// (1.23: y el ITINERARIO hasta el primer plazo, hasta el capítulo 4; con A, sus pasos)
async function objetivoMenu(){
  for(;;){
    const iti=S.ch<=4?[itinRow()]:[],j=misionesVer().findIndex(m=>!(m.id in S.misiones));
    const it=[{label:`CAPÍTULO ${S.ch}`,desc:`${CH_TITLES[S.ch]||''}\n${objectiveText()}`}].concat(iti)
      .concat(misionesVer().map(m=>({label:m.t,right:m.id in S.misiones?'HECHA':null,desc:m.d})))
      .concat([{label:'LOGROS',right:`${logrosN()}/${LOGROS.length}`,desc:'Lo que llevas conseguido en la partida. Pulsa A para verlos.'},{label:'DEUDA',right:eur(S.debt),desc:(S.due>0?`Plazo: ${eur(S.due)} antes de que acabe el día ${S.deadline}. Llevas ${eur(S.money+cajaE())}.\n`:'')+`Ventas ${eur(S.sales)} · Reputación ${S.rep} · Calor ${Math.round(S.heat)} %`},{label:'Volver',desc:''}]);
    const i=await menu(it,{cls:'full',title:'OBJETIVO',title2:'cap. '+S.ch,desc:true,initial:iti.length&&itinSig()?1:j<0?0:j+1+iti.length});
    if(iti.length&&i===1){await itinerarioMenu();continue;}
    if(i===it.length-3){await logrosMenu();continue;}   // 1.27
    return;
  }
}

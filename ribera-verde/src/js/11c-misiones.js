/* =========================================================
   MISIONES GUIADAS (1.11)
   ========================================================= */
// lo que hay que montar para llegar a los plazos de la deuda: la ruta guiada de docs/ANALISIS.md. Salen desde que conoces a Kiko,
// las de tu capítulo y las de antes, en START → OBJETIVO. ok() mira lo que tienes, no lo que pasó: lo que ya tengas se cumple al
// llegar a su capítulo. Al cumplir una, Kiko manda un SMS y deja un regalo (p: objetos, s: semillas; nunca dinero).
// S.misiones[id] = día en que se cumplió (0: partida vieja, de un capítulo anterior, sin regalo)
const precioDe=f=>SHOP.find(f).p;
const conFoco=()=>S.carpas.filter(c=>c&&FOCOS[c.foco]);
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
    ok:()=>S.carpas.some(c=>c&&CARPAS[c.t].plazas>=6),s:{txoko:5},sms:['Seis plantas por carpa. Esto ya es un negocio.']}];
const PREMIO_N={fert:'dosis de ABONO DE FLORACIÓN',fertv:'dosis de ABONO DE CRECIMIENTO',phm:'dosis de pH−',insect:'tratamiento de INSECTICIDA'};
const premioTxt=m=>Object.entries(m.p||{}).map(([k,n])=>`${n} ${PREMIO_N[k]}`).concat(Object.entries(m.s||{}).map(([k,n])=>`${n} semillas de ${STRAINS[k].n.toUpperCase()}`));
const misionesVer=()=>S.flags.kiko1?MISIONES.filter(m=>m.ch<=S.ch):[];
const misionSig=()=>misionesVer().find(m=>!(m.id in S.misiones));
let misionAviso=[];
// run() la llama al acabar cada guion: marca las cumplidas, da el regalo y encola el SMS
function revisaMisiones(){
  for(const m of misionesVer())if(!(m.id in S.misiones)&&m.ok()){
    S.misiones[m.id]=S.day;misionAviso.push(m.id);
    for(const k in m.p||{})S.items[k]+=m.p[k];for(const k in m.s||{})addSeeds(k,m.s[k]);
  }
  if(misionAviso.length)queue('mision',avisoMision);
}
async function avisoMision(){
  while(misionAviso.length){
    const id=misionAviso.shift(),m=MISIONES.find(x=>x.id===id);sfx('get');toast(`<small>MISIÓN CUMPLIDA</small>${m.t}`,2400);
    await talk('SMS · KIKO',m.sms);for(const t of premioTxt(m))await got(t);
  }
  const s=misionSig();if(s)toast(`<small>MISIÓN</small>${s.t}`,3200);
}
// el plazo (1.11): Toño avisa cuando quedan 3 días y el último, con lo que llevas
async function recuerdoPlazo(){
  const n=S.deadline-S.day,ll=S.money+cajaE();   // los días, como los cuenta Baltasar (talkBaltasar)
  await talk('SMS · TOÑO',[n>0?`Don Baltasar quiere ${eur(S.due)} antes de que acabe el día ${S.deadline}. Te quedan ${n} días.`:`Hoy es el último día para los ${eur(S.due)} de Don Baltasar.`]);
  await say(ll<S.due?`Llevas ${eur(ll)} entre el bolsillo y la caja: te faltan ${eur(S.due-ll)}.`:`Llevas ${eur(ll)} entre el bolsillo y la caja: ya lo tienes.${S.money<S.due?' Saca lo que falte de la caja y':''} Ve al bar El Ancla.`);
}
// START → OBJETIVO: el del capítulo, las misiones (con lo que hay que hacer abajo) y la deuda
async function objetivoMenu(){
  const it=[{label:`CAPÍTULO ${S.ch}`,desc:`${CH_TITLES[S.ch]||''}\n${objectiveText()}`}]
    .concat(misionesVer().map(m=>({label:m.t,right:m.id in S.misiones?'HECHA':null,desc:m.d})))
    .concat([{label:'DEUDA',right:eur(S.debt),desc:(S.due>0?`Plazo: ${eur(S.due)} antes de que acabe el día ${S.deadline}. Llevas ${eur(S.money+cajaE())}.\n`:'')+`Ventas ${eur(S.sales)} · Reputación ${S.rep} · Calor ${Math.round(S.heat)} %`},{label:'Volver',desc:''}]);
  await menu(it,{cls:'full',title:'OBJETIVO',title2:'cap. '+S.ch,desc:true,initial:Math.max(0,misionesVer().findIndex(m=>!(m.id in S.misiones))+1)});
}

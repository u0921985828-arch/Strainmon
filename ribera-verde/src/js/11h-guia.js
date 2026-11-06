/* =========================================================
   JULEN Y EL ITINERARIO (1.23)
   ========================================================= */
// Julen, el hijo de Kiko (estudia Agrónomas): desde que conoces a Kiko hasta la primera cosecha está en el piso, delante del armario,
// y te lleva de la mano (el pH, el riego, los abonos); después, en el growshop con su padre. El ITINERARIO (START → OBJETIVO) son los
// pasos de la partida hasta el primer plazo de la deuda: S.itin[id] = día en que se cumplió (0: partida vieja, sin aviso). Un paso
// está hecho si está apuntado o si ok() se cumple ya; los tres primeros se apuntan sin aviso (ya los cuenta el objetivo)
const ITINERARIO=[
  {id:'bus',t:'Llegar a Ribera Verde',d:'Coge el autobús en la plaza de Mendialde hasta Ribera Verde.',ok:()=>S.flags.llegada!==false},
  {id:'carta',t:'La carta de la tía',d:'Entra en el piso de la tía Maite y lee la carta que hay en la mesa.',ok:()=>!!S.flags.letter},
  {id:'kiko',t:'Kiko, en el growshop',d:'Visita el growshop de Kiko, al lado de casa.',ok:()=>!!S.flags.kiko1},
  {id:'julen',t:'Julen',d:'Julen, el hijo de Kiko, te espera en el piso.',ok:()=>!!S.flags.julen1||!!S.flags.harvest1},
  {id:'plantar',t:'Plantar',d:'Delante del armario de la tía, A: planta una semilla en una maceta.',ok:()=>S.pots.some(Boolean)||!!S.flags.harvest1},
  {id:'regar',t:'Regar',d:'Cuando el agua de la maceta baje del 30 %, riega.',ok:()=>!!S.flags.gRiego||!!S.flags.harvest1||S.pots.some(Boolean)&&S.carpas.some(c=>c&&(c.goteo||c.garrafas))},   // o riego automático
  {id:'veg',t:'Abono de crecimiento',d:'Mientras crece, una dosis de abono de crecimiento con su pH−.',
    ok:()=>!!(S.flags.gVeg||S.flags.gFlor||S.flags.harvest1)||S.pots.some(p=>p&&(p.prog>=.65||p.fv||p.fert))},   // ya en flor, no toca (p.fv, p.fert: partidas de antes de gVeg)
  {id:'flor',t:'Abono de floración',d:'Cuando florezca, una dosis de abono de floración con su pH−.',ok:()=>!!S.flags.gFlor||!!S.flags.harvest1||S.pots.some(p=>p&&p.fert)},
  {id:'cosecha',t:'Primera cosecha',d:'Cuando la planta esté lista, cosecha. Si ves araña roja, insecticida.',ok:()=>!!S.flags.harvest1},
  {id:'vender',t:'Primera venta',d:'Véndele a alguien que lleve un $ encima, en la calle.',ok:()=>S.sales>0},
  {id:'ventas',t:`${META_VENTAS} € en ventas`,d:`Gana ${META_VENTAS} € vendiendo.`,ok:()=>S.ch>=3},
  {id:'baltasar',t:'Don Baltasar',d:'Don Baltasar te espera en el bar El Ancla.',ok:()=>!!S.flags.metB||S.ch>=4},
  {id:'juntar',t:`Juntar ${eur(PLAZOS[3])}`,d:'Junta el primer plazo entre el bolsillo y la caja.',ok:()=>S.ch>=4||(S.ch===3&&S.due>0&&S.money+cajaE()>=S.due)},
  {id:'pagar',t:'El primer plazo',d:'Paga el primer plazo a Don Baltasar, en el bar El Ancla.',ok:()=>S.ch>=4}];
const ITIN_MUDO=3;
const itinHecho=p=>p.id in S.itin||p.ok();
const itinSig=()=>ITINERARIO.find(p=>!itinHecho(p));
const itinN=()=>ITINERARIO.filter(itinHecho).length;
const julenAqui=()=>S.map==='home'&&!!S.flags.julen1&&!S.flags.harvest1;   // ya te ha saludado y sigue en el piso
const JULEN={
  hola:['Kaixo. Soy Julen, el hijo de Kiko. Estudio Agrónomas en Ibarbide y le echo una mano en la tienda.','Mi aita me ha pedido que te ayude hasta tu primera cosecha. A él también le enseñaba tu tía.',
    `Lo primero, el agua. La del grifo sale a pH ${coma(ABONO.ph[0])} y las raíces la quieren a ${coma(ABONO.ph[2])}: con el pH alto, la planta no puede comer el abono.`],
  ph:['Cada dosis de abono gasta una de pH−. Con un medidor de pH aciertas siempre; a ojo, casi.','El abono que te ha dado mi aita es mineral, MEATZA. El que te doy yo es orgánico, ORTUA BIO.'],
  aqui:['Lo que toca hacer lo tienes en START → OBJETIVO → ITINERARIO. Yo me quedo por aquí hasta que coseches.'],
  ok:{plantar:'Bien plantada. Ahora, el agua: riega cuando la barra azul baje del 30 %.',regar:'Así. Mientras crece, échale el abono de crecimiento: con su pH−, lo aprovecha entero.',
    veg:'Eso es. Cuando empiece a florecer, el de floración. Una dosis por planta.',flor:'Ya está todo. Ahora, paciencia: cuando esté lista, cosecha.'},
  tarde:['Kaixo. Soy Julen, el hijo de Kiko. Estudio Agrónomas en Ibarbide y le echo una mano en la tienda.','Ya has cosechado sin mí. Aun así, toma: para que pruebes el orgánico.'],
  adios:['Primera cosecha. Ya no me necesitas.','Me vuelvo al growshop con mi aita. Pásate cuando quieras: algún consejo te daré.'],
  tips:['Con el medidor de pH aciertas siempre: la planta aprovecha el abono entero.','El orgánico no acelera la floración. Si te aprieta un plazo, mineral.',
    'Si solo le echas orgánico, con su pH− cítrico, el sustrato se queda vivo: menos plagas.','El pH− MEATZA es ácido fosfórico, mineral: con él ya no hay sustrato vivo.',
    `Con mineral y sin pH−, el ${pct0(1-ABONO.q[0])} % del abono se queda bloqueado en la tierra.`,'Con abono de crecimiento, la planta llega antes a florecer.']};
const MINERAL_ORG=[`El mineral come deprisa: con el pH corregido, un ${pct0(ABONO.rend)} % más de cosecha y florece antes. Sin pH−, aprovecha solo el ${pct0(ABONO.q[0])} %.`,
  `El orgánico va lento: un ${pct0(ABONO_BIO.rend)} % más de cosecha, sin prisas, pero algo más potente. Y perdona el pH: sin pH−, aprovecha el ${pct0(ABONO_BIO.q[0])} %.`,
  'Si solo le echas orgánico, con su pH− cítrico, el sustrato sigue vivo y frena las plagas. Un poco de mineral y se acaba.'];
// lo que toca ahora, con lo que te falta para hacerlo
function pasoCultivo(){
  const s=itinSig();if(!s)return pick(JULEN.tips);
  const sin=ks=>!ks.some(k=>S.items[k]>0);let t=s.d;
  if(s.id==='plantar'&&!Object.values(S.seeds).some(n=>n>0))t+=' Si no te quedan semillas, mi aita tiene.';
  else if((s.id==='veg'&&sin(['fertv','ofertv']))||(s.id==='flor'&&sin(['fert','ofert'])))t+=' No te queda: mi aita lo vende en el growshop.';
  else if((s.id==='veg'||s.id==='flor')&&sin(['phm','ophm']))t+=' Y te falta pH−: lo tiene mi aita.';
  return t;
}
async function talkJulen(){
  const N='JULEN';
  if(!S.flags.julen1){
    await talk(N,S.flags.harvest1?JULEN.tarde:JULEN.hola);
    S.items.ofertv+=2;await got('2 dosis de ORTUA BIO CRECIMIENTO');S.items.ophm+=4;await got('4 dosis de pH− ORTUA BIO');
    await talk(N,JULEN.ph.concat(MINERAL_ORG,S.flags.harvest1?[]:JULEN.aqui));S.flags.julen1=true;return;
  }
  if(!S.flags.harvest1){
    const c=await ask('¿Qué pasa?',['¿Qué hago ahora?','Mineral u orgánico','Nada'],N);
    if(c===0)await say(pasoCultivo(),N);else if(c===1)await talk(N,MINERAL_ORG);else await say('Aquí estoy si me necesitas.',N);return;
  }
  const c=await ask('¿Qué tal la cosecha?',['Un consejo','Mineral u orgánico','Nada'],N);
  if(c===0)await say(pick(JULEN.tips),N);else if(c===1)await talk(N,MINERAL_ORG);else await say('Agur. Saluda a las plantas de mi parte.',N);
}
// run() → revisaMisiones → aquí: apunta los pasos hechos y avisa del último (y del siguiente); si Julen está delante, lo comenta
let itinAviso=[];
function revisaItinerario(){
  if(!S.itin)return;
  ITINERARIO.forEach((p,i)=>{if(!(p.id in S.itin)&&p.ok()){S.itin[p.id]=S.day;if(i>=ITIN_MUDO)itinAviso.push(p.id);}});
  if(itinAviso.length)queue('itin',avisoItin);
}
async function avisoItin(){
  const ids=itinAviso.splice(0),p=ITINERARIO.find(x=>x.id===ids[ids.length-1]),s=itinSig();
  toast(conLogro(`<small>ITINERARIO · ${itinN()}/${ITINERARIO.length}</small>${p.t}`+(s?`<br>Ahora: ${s.t}`:'')),2800);
  const j=ids.map(id=>JULEN.ok[id]).filter(Boolean);
  if(julenAqui()&&j.length)await say(j[j.length-1],'JULEN');
}
// START → OBJETIVO → ITINERARIO
function itinRow(){const s=itinSig(),i=s?ITINERARIO.indexOf(s):-1,n=ITINERARIO[i+1];
  return {label:'ITINERARIO',right:`${itinN()}/${ITINERARIO.length}`,itin:1,desc:s?`Ahora: ${s.t}. ${s.d}`+(n?`\nDespués: ${n.t}.`:''):'Hecho: el primer plazo, pagado.'};}
async function itinerarioMenu(){
  const s=itinSig(),cur=s?ITINERARIO.indexOf(s):-1;
  await menu(ITINERARIO.map(p=>({label:p.t,right:itinHecho(p)?'HECHO':p===s?'AHORA':null,desc:p.d})).concat([{label:'Volver',desc:''}]),
    {cls:'full',title:'ITINERARIO',title2:`${itinN()}/${ITINERARIO.length}`,desc:true,initial:Math.max(0,cur)});
}

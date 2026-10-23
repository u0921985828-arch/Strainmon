/* =========================================================
   LOGROS (1.27)
   ========================================================= */
// lo conseguido en la partida, en START → OBJETIVO → LOGROS. ok() mira lo que tienes, como las misiones: revisaLogros (desde
// revisaMisiones, al acabar cada guion) marca los nuevos (S.logros[id] = el día; 0: los que ya tenía una partida de antes de la 1.27,
// sin aviso) y los avisa con un toast. Si en la cola viene detrás el aviso del itinerario o el de la misión, el logro va en el suyo,
// debajo (conLogro), para que el último no lo pise. Sin premio: es para seguir la partida.
// En Godot, los textos de aquí (D.LOGROS) y lo que mira cada uno en logro_ok (trama.gd)
const LANDRACES=DEX.filter(k=>/^Landrace/.test(STRAINS[k].o));
const TIA_DEJO=['choco','oaxaca','lamb','kerala','mangarosa','hawai','lao'];   // las 7 de la tía (1.25): nevera, caja, 4 arbustos y Miren
const LOGROS=[
  {id:'venta',t:'Primera venta',d:'Vende hierba por primera vez.',ok:()=>S.sales>0},
  {id:'cosecha',t:'Primera cosecha',d:'Cosecha tu primera planta.',ok:()=>!!S.flags.harvest1},
  {id:'diario',t:'El diario de la tía',d:'Encuentra el diario de la tía Maite.',ok:()=>!!S.flags.diario},
  {id:'estrella',t:'Fenotipo estrella',d:'Cosecha una planta con fenotipo estrella.',ok:()=>Object.values(S.fenos).includes('estrella')},
  {id:'receta',t:'Primera receta',d:'Saca en la mesa y cosecha una variedad de receta del diario.',ok:()=>recCount()>=1},
  {id:'recetas10',t:'Diez recetas',d:'Cosecha diez variedades de receta.',ok:()=>recCount()>=10},
  {id:'jack',t:'La meta de la tía',d:'Cosecha la Jack Herer.',ok:()=>S.rec.leyenda===2},
  {id:'mitad',t:'Media Genoteca',d:`Ten ${Math.ceil(DEX.length/2)} de las ${DEX.length} variedades en la Genoteca.`,ok:()=>DEX.filter(k=>S.disc[k]).length>=Math.ceil(DEX.length/2)},
  {id:'genoteca',t:'Genoteca completa',d:`Las ${DEX.length} variedades en la Genoteca.`,ok:()=>DEX.every(k=>S.disc[k])},
  {id:'landraces',t:'Cazador de landraces',d:`Las ${LANDRACES.length} landraces en la Genoteca.`,ok:()=>LANDRACES.every(k=>S.disc[k])},
  {id:'tia',t:'Tras la pista de la tía',d:`Las ${TIA_DEJO.length} landraces que dejó la tía Maite (en casa, por la comarca y con Miren), en la Genoteca.`,ok:()=>TIA_DEJO.every(k=>S.disc[k])},
  {id:'rosin',t:'Prensado',d:'Prensa tu primer rosin.',ok:()=>Object.keys(S.rosin).length>0||neveraR()>0},
  {id:'cata',t:'Catador',d:'Cata tu propia hierba.',ok:()=>Object.keys(S.catas).length>0},
  {id:'club',t:'Socio',d:'Hazte el carné de un club cannábico.',ok:()=>Object.values(S.clubs).some(Boolean)},
  {id:'presidente',t:'Como la tía Maite',d:'Preside la Asociación Cannábica Ribera Verde.',ok:()=>!!(S.aso&&S.aso.pres)},
  {id:'goteo',t:'Riego automático',d:'Monta el goteo en una carpa.',ok:()=>S.carpas.some(c=>c&&c.goteo)},
  {id:'carpas',t:'Tres carpas',d:'Ten tres carpas montadas en el piso.',ok:()=>S.carpas.filter(Boolean).length>=3},
  {id:'plazo',t:'Primer plazo',d:'Paga el primer plazo de la deuda.',ok:()=>S.ch>=4},
  {id:'libre',t:'Sin deudas',d:'Salda la deuda con Don Baltasar.',ok:()=>S.debt<=0},
  {id:'ventas10',t:'10.000 € en ventas',d:'Llega a 10.000 € vendidos.',ok:()=>S.sales>=10000},
  {id:'ventas100',t:'100.000 € en ventas',d:'Llega a 100.000 € vendidos.',ok:()=>S.sales>=100000},
  {id:'rival',t:'Esta es mi calle',d:'Gana a un rival de zona.',ok:()=>Object.keys(S.rivalFuera).length>0},
  {id:'darko',t:'Ajuste de cuentas',d:'Gana a Darko.',ok:()=>!!S.flags.darkoFin},
  {id:'plantilla',t:'Tu gente',d:'Ten a alguien del barrio en la plantilla.',ok:()=>S.plantilla.length>0},
  {id:'nave',t:'La nave',d:'Alquila la nave de Valdehierro.',ok:()=>!!S.nave},
  {id:'ruedas',t:'Sobre ruedas',d:'Cómprate el patinete o la bici.',ok:()=>Object.values(S.veh||{}).some(d=>d&&d<=S.day)},
  {id:'casa',t:'A tu gusto',d:'Cambia el suelo o las paredes del piso.',ok:()=>decoV('suelo')>0||decoV('pared')>0}];
const logrosN=()=>LOGROS.filter(l=>l.id in S.logros).length;
let logroAviso=[];
function revisaLogros(){
  for(const l of LOGROS)if(!(l.id in S.logros)&&l.ok()){S.logros[l.id]=S.day;logroAviso.push(l.id);}
  if(logroAviso.length)queue('logro',avisoLogro);
}
function logroTxt(){
  const l=logroAviso.map(id=>LOGROS.find(x=>x.id===id).t);logroAviso=[];if(!l.length)return '';
  sfx('get');return `<small>${l.length>1?'LOGROS':'LOGRO'} · ${logrosN()}/${LOGROS.length}</small>${l.map(esc).join(' · ')}`;
}
// el aviso h (del itinerario o de la misión, que está en la cola mientras corre) con los logros debajo, si el otro no viene después
function conLogro(h){if(queued.has('itin')&&queued.has('mision'))return h;const l=logroTxt();return l?(h?h+'<br>':'')+l:h;}
async function avisoLogro(){
  if(queued.has('itin')||queued.has('mision'))return;   // lo dirán ellos
  const l=logroTxt();if(l)toast(l,2600);
}
// START → OBJETIVO → LOGROS: los conseguidos, con su día, y los que faltan
async function logrosMenu(){
  const it=LOGROS.map(l=>{const h=l.id in S.logros;return {label:l.t,right:h?(S.logros[l.id]?'día '+S.logros[l.id]:'HECHO'):null,desc:l.d};});
  await menu(it.concat([{label:'Volver',desc:''}]),{cls:'full',title:'LOGROS',title2:`${logrosN()} de ${LOGROS.length}`,desc:true});
}

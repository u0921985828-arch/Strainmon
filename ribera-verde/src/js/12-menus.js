/* =========================================================
   MENÚ START
   ========================================================= */
async function startMenu(){
  let i=0;
  for(;;){   // 1.10: con su icono y lo que hay en cada uno, y arriba el día, la hora y el dinero
    const sms=S.sms.length,vivas=S.pots.filter(p=>p&&!p.dead).length;
    i=await menu([{label:'GENOTECA',right:`${DEX.filter(k=>S.disc[k]).length}/${DEX.length}`,ic:icono('cogollo')},{label:'MOCHILA',right:kgTxt(Math.floor(pesoEncima())),ic:icono('bolsa')},
      {label:'MÓVIL',right:sms?sms+' SMS':null,ic:icono('movil')},{label:'PLANTAS',right:String(vivas),ic:icono('maceta')},{label:'OBJETIVO',right:'cap. '+S.ch,ic:icono('trofeo')},
      {label:'GUARDAR',ic:icono('guardar')},{label:'OPCIONES',ic:icono('altavoz')},{label:'SALIR',ic:icono('salir')}],
      {cls:'start',initial:i,startCloses:true,title:`DÍA ${S.day} · ${relojTxt()}`,title2:eur(S.money)});
    if(i<0||i===7)return;
    if(i===0)await genoteca();else if(i===1)await mochila();else if(i===2)await movilMenu();else if(i===3)await plantas();
    else if(i===4)await objetivoMenu();
    else if(i===5)await say(save()?'Partida guardada.':'No se ha podido guardar en este navegador.');
    else if(i===6)await opciones();
  }
}
// OPCIONES: A cambia cada fila (la música y los efectos de 25 en 25 %, el texto y SONIDO); se guardan al momento
const TEXTO_VEL=['NORMAL','RÁPIDO','AL MOMENTO'];
async function opciones(){
  let i=0;
  for(;;){
    i=await menu([{label:'MÚSICA',right:AJ.musica*25+' %'},{label:'EFECTOS',right:AJ.efectos*25+' %'},{label:'TEXTO',right:TEXTO_VEL[AJ.texto]},{label:'SONIDO',right:soundOn?'SÍ':'NO'},{label:'EXPORTAR PARTIDA'},{label:'IMPORTAR PARTIDA'},{label:'VOLVER'}],
      {cls:'start',initial:i,title:'OPCIONES'});
    if(i<0||i===6)return;
    if(i===4){await exportar();continue;}
    if(i===5){await importar();continue;}
    if(i===0)AJ.musica=(AJ.musica+1)%5;else if(i===1)AJ.efectos=(AJ.efectos+1)%5;else if(i===2)AJ.texto=(AJ.texto+1)%3;else setSound(!soundOn);
    guardaAjustes();if(i===1)sfx('coin');
  }
}
// exportar la partida (1.11): el JSON de S al portapapeles, para guardarlo en una nota (y luego importarla, 1.22)
async function exportar(){
  const t=JSON.stringify(S);let ok=false;
  try{await navigator.clipboard.writeText(t);ok=true;}catch(e){}
  if(!ok){const a=document.createElement('textarea');a.value=t;document.body.appendChild(a);a.select();try{ok=document.execCommand('copy');}catch(e){}a.remove();}
  return say(ok?'Partida copiada al portapapeles. Pégala en una nota o en un correo para guardarla.':'No se ha podido copiar en este navegador.');
}
// importar la partida (1.22): la exportada, pegada en la caja de texto (lo que haya en el portapapeles sale ya escrito);
// sustituye a la de ahora (migrate, como CONTINUAR) y se guarda; la cola de avisos de la otra partida se vacía
const IMPORTA_MAX=2000000;
const partidaValida=s=>!!s&&typeof s==='object'&&!Array.isArray(s)&&typeof s.name==='string'&&typeof s.day==='number'&&typeof s.ch==='number'
  &&typeof s.map==='string'&&Object.prototype.hasOwnProperty.call(MAPS,s.map)&&Array.isArray(s.pots)&&!!s.flags&&typeof s.flags==='object'&&!Array.isArray(s.flags);
// lo pegado no trae <, >, " ni ` (los nombres van a menús y avisos en HTML)
const limpiaImport=v=>typeof v==='string'?v.replace(/[<>"`]/g,''):Array.isArray(v)?v.map(limpiaImport)
  :v&&typeof v==='object'?Object.fromEntries(Object.entries(v).map(([k,x])=>[limpiaImport(k),limpiaImport(x)])):v;
async function importar(){
  let ini='';try{ini=String(await navigator.clipboard.readText()||'').trim();}catch(e){}
  if(ini.length>IMPORTA_MAX)ini='';
  const t=await pedirTexto('Pega aquí la partida exportada',ini,IMPORTA_MAX,false,true,true);if(t==null)return;
  let s=null;try{s=limpiaImport(JSON.parse(t));}catch(e){}
  if(!partidaValida(s))return say('Eso no es una partida exportada.');
  if(await ask(`¿Cargar la partida de ${s.name}, día ${s.day}? La de ahora se pierde.`,['Cargar','No'])!==0)return;
  S=s;pending.length=0;queued.clear();migrate();enterGame();const ok=save();sfx('coin');
  return say(ok?'Partida cargada.':'Partida cargada, pero no se ha podido guardar.');
}
// recetario (1.11): cada variedad de receta con sus maneras de sacarla (RECIPES, en cualquier orden; RECETA_ORD, madre × padre)
// y, de cada una que entra, dónde se consiguen las semillas
function recetas(){const R={},add=(t,o)=>(R[t]=R[t]||[]).push(o);
  for(const [h,t] of Object.entries(RECIPES))add(t,{k:h.split('+'),ord:false});
  for(const [h,t] of Object.entries(RECETA_ORD))add(t,{k:h.split('>'),ord:true});
  return R;}
const recetaTxt=o=>o.k.map(k=>STRAINS[k].n).join(o.ord?' × ':' + ')+(o.ord?', en ese orden':'');
// 1.25: las landraces que no están en el banco (BANCO), en casa de la tía, en arbustos de la comarca (ITEMS) y con Miren (MIREN.s2);
// a Godot por datos.json (1.26), y el trueque de Andoni (landraceTrueque) las vuelve a dar ya descubiertas
const REGALO={ria:'te las da Kiko al conocerlo',rif:'te las da Kiko con la mesa de genética',hindu:'Txaro, la vecina, por 5 g de cogollo',
  chitral:'Txaro, por 10 g de una índica',malawi:'Iñaki, el del muelle, al venderle 10 g',acapulco:'escondidas en el parque del barrio',
  choco:'en la nevera del piso, en un bote de cristal',oaxaca:'en un sobre al fondo de la caja fuerte de la tía',lamb:'escondidas en Puerto Viejo, en un arbusto al fondo del callejón del este',
  kerala:'escondidas en un arbusto junto a una borda, al este de Mendialde',mangarosa:'escondidas en un arbusto de Errotabarri',hawai:'escondidas en un seto del Ensanche, en Ibarbide',
  lao:'Miren, en Errotabarri, con la última página del diario'};
// el diario de la tía Maite (1.16): el recetario es su cuaderno; una nota suya por variedad (1.25: todas, no solo las de receta)
const DIARIO={ria:'La primera que fijamos Kiko y yo. Tres padres y mucha paciencia: cuando huele a mofeta, va bien.',
  haze:'Tarda una eternidad en flor. En el armario no cabe; en la carpa grande, y a 12/12 pronto.',
  nl:'Afgana y tailandesa. Aguanta el frío de la ría y no huele tanto: la de los años malos.',
  amanecer:'Las noches frías de octubre le sacan el morado. Que no te engañe el color: pega suave.',
  sollimon:'Huele a limón y a pino. Ata las colas, que pesan y se tronchan.',
  ak47:'Cuatro sangres y florece en ocho semanas. Si solo tienes sitio para una, esta.',
  buddha:'Tailandesa con jamaicana. La que le daba la risa a Txaro los domingos.',
  cannalope:'Haze con mexicana: huele a melón maduro. Pide sitio a lo alto.',
  afkush:'Las dos montañas juntas. Resina de la de verdad; la que tamizábamos en seco.',
  purpurah:'Hindu Kush con la púrpura: morada hasta el tallo. La del aceite de Txaro.',
  congopan:'Dos ecuatoriales: eléctrica y lenta. En el armario, ni lo intentes.',
  malapan:'Africana y panameña. Muy alta y muy clara de efecto; ponle tutor.',
  malapck:'Malawi con la de Chitral. La rara del cuaderno: si te sale, guárdale semillas.',
  niebla:'Sabe a arándanos de verdad. Tres generaciones me costó que oliera así.',
  shiva:'Skunk con Northern Lights: corta, gorda y obediente. La de mi primer año.',
  neville:'Haze con NL5 × Haze: la sativa más alta que he tenido. Doce semanas largas de flor.',
  chocolope:'Chocolate y melón. No la cuelgues a secar con otra, que se le pega el olor.',
  orotrop:'Sabe a piña. Kiko decía que era la de los veranos.',
  brumaog:'Pela una mandarina: así huele la carpa cuando florece.',
  tormenta:'Tres landraces y una Haze. Si la sacas, ya sabes cruzar.',
  leyenda:'La que nunca terminé. Haze, Northern Lights y Shiva: el cuaderno acaba aquí. Termínala tú.',
  ssh:'Plateada de tricomas. Skunk, Northern Lights y Haze en un solo cogollo.',
  nieblamor:'Blueberry con Haze: dulce y despierta. La que más me pedían en el muelle.',
  bluetx:'Blueberry con queso. Huele fuerte: extractor y filtro antes de plantarla.',
  limon:'Huele a limón recién cortado. Cosecha con los tricomas lechosos.',
  dragon:'Huele a gasoil. Ni el mejor filtro la tapa del todo.',
  kali47:'Una sativa que florece a tiempo. Un milagro, en esta ría.',
  reina:'Produce como ninguna: la de pagar las facturas.',
  txoko:'Skunk #1 de madre y Afghani de padre. Al revés sale otra: la madre manda.',
  kushrif:'Afghani de madre y Skunk #1 de padre. Cogollos tan densos que hay que vigilar el moho.',
  nlhaze:'Northern Lights de madre y Haze de padre: la más fácil de las Haze.',
  silver:'Haze de madre y Northern Lights de padre. Al revés no sale igual.',
  ww:'Brasileña con la del sur de la India: se cubre de escarcha blanca. La que todos pedían en el 95.',
  purplehaze:'Purple Thai con Haze: morada y eléctrica. Ponía música en la carpa cuando florecía.',
  whiterussian:'White Widow con AK-47: aún más blanca. Kiko la llamaba «la del invierno».',
  bluewidow:'Blueberry con White Widow: dulce y escarchada. Con noches frías le sale el azul.',
  superlemon:'Lemon Skunk con Super Silver Haze: limón y escarcha. Larga de flor, pero merece la pena.',
  mango:'Cogollos como puños. Kiko la tiene en la tienda: ponle malla, que las ramas se doblan.',
  purpura:'La afgana morada de la tienda. Con la Hindu Kush sale la Purple Kush.',
  citrus:'Skunk que huele a limón. Con Silver Haze, la Lemon Haze; con Super Silver Haze, la Super Lemon Haze.',
  kali:'Una sativa de la tienda que florece a tiempo. Con AK-47, la Kali 47; con Critical Mass, la Critical Kali Mist.',
  cheese:'Huele a queso curado y no hay filtro que lo tape. Con Blueberry, la Blue Cheese.',
  calorange:'Naranja de California. Con Skunk #1 sale la Tangie.',
  chemdawg:'Huele a gasoil del bueno. Con Super Skunk, la Sour Diesel.',
  rif:'La afgana de Kiko: medio cuaderno sale de ella. Corta, ancha y llena de resina.',
  hindu:'La de Txaro: baja y ancha como un abeto. Con la de Chitral, la Master Kush.',
  acapulco:'La dorada de Guerrero. La escondí en el parque del barrio, en un bote de carrete, entre los arbustos.',
  malawi:'Africana de flor eterna: Iñaki la trajo en un barco. Con Panama Red o con Chitral Kush.',
  mich:'Mexicana de altura. Con Thai y Punto Rojo, la Haze; con Thai y Afghani, la Trainwreck.',
  punto:'Colombiana de punta roja. Con Thai, la Haze: la madre de todas las largas.',
  colgold:'Colombiana dorada. Con Afghani y Acapulco Gold, la Skunk #1.',
  thai:'Tailandesa fina, de flor larga. Entra en la Haze, la Northern Lights y la AK-47.',
  choco:'Huele a cacao. Guardé unas en la nevera, en un bote de cristal: el frío las conserva.',
  hthai:'La tailandesa de montaña. Con Purple Thai y Afghani, la Blueberry.',
  lao:'La de Laos se la dejé a Miren, en Errotabarri. La guardábamos para la Amnesia.',
  chitral:'Kush del valle de Chitral, densa y oscura. Txaro guarda unas; con Hindu Kush, la Master Kush.',
  nepal:'Del Himalaya: resina de templo. No entra en ninguna receta; para cruzar a tu aire.',
  congo:'Del Congo: eléctrica y lenta. Con Panama Red, la Congo × Panama.',
  lamb:'La jamaicana. Dejé unas en Puerto Viejo, en un arbusto al fondo del callejón del este. Con Thai, la Laughing Buddha.',
  hawai:'Huele a piña. Unas, en un seto del Ensanche, en Ibarbide. Con Trainwreck, la Pineapple Express.',
  kif:'La del Rif, para tamizar. No entra en ninguna receta: cruza tú.',
  beldia:'La vieja de Ketama, la de antes de los híbridos. Para tamizar en seco.',
  oaxaca:'Mexicana de la sierra. Las guardé bajo llave, en la caja de detrás del diploma. Con Chocolate Thai, la Purple Thai.',
  panama:'Roja de Panamá, de flor larguísima. Con Congolese o con Malawi Gold.',
  kerala:'Del sur de la India. Escondí unas en un arbusto junto a una borda, al este de Mendialde. Con Manga Rosa, la White Widow.',
  libano:'Del valle de la Bekaa: el hachís rubio. Ninguna receta; prueba tú.',
  mangarosa:'Brasileña, de cogollo rosado. Dejé unas en Errotabarri, en un arbusto. Con Kerala, la White Widow.',
  durban:'Sudafricana, de las sativas más rápidas. Ninguna receta: para tus cruces.',
  // 1.26
  swazi:'De los montes de Esuatini: dorada y cítrica. Ninguna receta; para tus cruces.',
  zamal:'De la isla de la Reunión: altísima y de flor eterna. Ninguna receta: si la cruzas, ten paciencia.',
  malana:'La del charas del valle de Parvati, frotada a mano. Ninguna receta; para cruzar a tu aire.',
  kashmir:'De los valles de Cachemira: baja, oscura y no le asusta el frío. Ninguna receta; prueba tú.',
  vietblack:'Vietnamita de cogollo casi negro, con olor a especia. Ninguna receta: para tus cruces.',
  etiopia:'De las tierras altas de Etiopía: florece antes que las de la costa. Ninguna receta; cruza tú.',
  chronic:'Skunk, Northern Lights y AK-47: tres de las fáciles en una. La de llenar el arcón.',
  whiterhino:'White Widow con una índica: más baja y más pesada. Para el armario pequeño.',
  whiteshark:'Super Skunk con las dos de la White Widow. Huele fuerte: filtro antes de plantarla.',
  hawaisnow:'Tres Haze y la de Hawái: no me cabía en ninguna carpa. Si la sacas, a 12/12 pronto.',
  jackflash:'La Jack Herer con más Haze y Super Skunk. Termina la Jack primero.',
  jack47:'Si terminas la Jack, con la AK-47: la Jack para los que tienen prisa.',
  sourtangie:'Gasoil y mandarina. Suena raro, pero funciona.',
  ice:'Tanta resina que parece helada. La de las extracciones.',
  nlbigbud:'Northern Lights con Big Bud: el arcón lleno. Ponle malla, que las ramas no aguantan.',
  criticaljack:'Si terminas la Jack, con la Critical Mass: la producción con el efecto. Hay quien dice que su Critical era otra.',
  critical47:'Critical Mass con AK-47: corta y generosa. La de los balcones.',
  criticalcheese:'Critical Mass con Cheese. Huele a queso hasta en la escalera.',
  nlblue:'Northern Lights con Blueberry: dulce, corta y obediente.'};
// la página que falta (1.17): Miren te la da en Errotabarri (S.flags.pagina) y sale al final del diario
const PAGINA='Si lees esto, Miren te ha encontrado. El segundo premio del 98 lo sacamos entre las dos, aunque el diploma lo colgué yo. Lo de Baltasar no fue por el piso: le pedí el dinero cuando a Miren le querían quitar el caserío, y no se lo conté a nadie. No le debas nada a quien no sabe perder. Y cuida las semillas: son lo único que no se puede comprar. M.';
const diarioTxt=t=>(DIARIO[t]?`«${DIARIO[t]}»\n`:'');
function dondeSemilla(k){
  const b=BANCO.find(x=>x[0]===k),t=SHOP.find(it=>it.sid===k),l=[];
  if(REGALO[k])l.push(REGALO[k]);if(t)l.push(`en el growshop de Kiko desde el cap. ${t.ch}`);if(b)l.push(`en el banco de semillas del PC desde el cap. ${b[2]}`);
  if(MISIONES.some(m=>m.s&&m.s[k]))l.push('de premio en una misión');if(recetas()[k])l.push('de su receta');
  return 'Semillas: '+l.join('; ')+'.';
}
// 1.25: todas las de la Genoteca, en su orden; las de receta abren lo que entra; las demás dicen dónde están sus semillas
const tipoDiario=(t,R)=>R[t]?(R[t].length>1?R[t].length+' recetas':'receta'):SHOP.some(it=>it.sid===t)?'tienda':'landrace';
async function recetario(){
  const R=recetas(),ts=DEX;let i=0;
  for(;;){
    i=await menu(ts.map(t=>({label:(S.disc[t]?'✓ ':'  ')+STRAINS[t].n,right:tipoDiario(t,R),sw:STRAINS[t].c,ic:iconoCogollo(t),
      desc:diarioTxt(t)+(R[t]?R[t].map(recetaTxt).join('\no '):dondeSemilla(t)),k:t})).concat(S.flags.pagina?[{label:'  La última página',desc:`«${PAGINA}»`}]:[],[{label:'Volver',desc:''}]),{cls:'full',title:'DIARIO DE LA TÍA MAITE',title2:`${ts.filter(t=>S.disc[t]).length}/${ts.length}`,desc:true,initial:i});
    if(i===ts.length&&S.flags.pagina)continue;
    if(i<0||i>=ts.length)return;
    if(!R[ts[i]])continue;
    const t=ts[i],ks=[...new Set(R[t].flatMap(o=>o.k))];
    await menu(ks.map(k=>({label:(S.disc[k]?'✓ ':'  ')+STRAINS[k].n,right:S.seeds[k]?'×'+S.seeds[k]:'',sw:STRAINS[k].c,ic:iconoCogollo(k),desc:dondeSemilla(k)}))
      .concat([{label:'Volver',desc:''}]),{cls:'full',title:STRAINS[t].n.toUpperCase(),title2:'lo que entra',desc:true});
  }
}
// cambiar el nombre a una variedad propia (1.11): sin repetir el de otra
async function renombrarVariedad(k){
  const C=S.custom[k],v=await pedirTexto('Nuevo nombre de la variedad',C.n,NOM_MAX);if(!v||v===C.n)return;
  const l=v.toLowerCase();if(DEX.some(d=>STRAINS[d].n.toLowerCase()===l)||Object.values(S.custom).some(c=>c!==C&&c.n.toLowerCase()===l))return say('Ya hay una variedad con ese nombre.');
  const a=C.n;C.n=v;sfx('sel');return say(`La ${a} pasa a llamarse ${v}.`);
}
async function genoteca(){
  let i=0;
  for(;;){
    const items=(S.flags.diario?[{label:'DIARIO DE LA TÍA MAITE',right:`${DEX.filter(t=>S.disc[t]).length}/${DEX.length}`,ic:icono('guardar'),diario:1,desc:`Su cuaderno: las ${DEX.length} variedades, lo que apuntó de cada una, las recetas de los cruces y dónde conseguir las semillas.`}]:[])
      .concat(DEX.map((k,n)=>{const s=STRAINS[k],nn=String(n+1).padStart(2,'0');return S.disc[k]?{label:`${nn} ${s.n}`,right:pct(s.thc)+'%',sw:s.c,ic:iconoCogollo(k),desc:strainLine(k)+(s.h?'\n'+s.h:'')+(S.catas[k]?'\nCata: '+S.catas[k]:'')}:{label:`${nn} ??????`,desc:'Sin descubrir.'};}));
    const cust=Object.keys(S.custom).filter(k=>S.disc[k]);
    cust.forEach(k=>{const s=S.custom[k];items.push({label:'★ '+s.n,right:pct(s.thc)+'%',sw:s.c,ic:iconoCogollo(k),desc:strainLine(k)+'\nPulsa A para cambiarle el nombre.',c:k});});
    i=await menu(items,{cls:'full',title:'GENOTECA',title2:`${DEX.filter(k=>S.disc[k]).length}/${DEX.length} · ${cust.length} propias`,desc:true,initial:i});
    if(i<0)return;
    if(items[i].diario)await recetario();else if(items[i].c)await renombrarVariedad(items[i].c);
  }
}
async function mochila(){
  let i=0;
  for(;;){
    const M=MOCHILAS[S.items.bolsa||0];
    const rows=[{label:'Dinero',right:eur(S.money),ic:icono('billetes'),desc:'Lo que llevas encima. Don Baltasar también lo cuenta.'},
      {label:M.n,right:`${Math.floor(pesoEncima())} de ${kgTxt(M.g)}`,ic:icono('bolsa'),desc:'Cogollos y rosin que llevas encima. Lo que no cabe al cosechar va al arcón de casa.'}].concat(arconG()>=1||arconR()>=.1?[{label:'Arcón',right:arconTxt(),ic:icono('cogollo'),
      desc:'En casa, entre la cama y la nevera. Un control en la calle no lo ve; una redada se lo lleva.'}]:[],S.caja?[{label:'Caja fuerte',right:`${eur(cajaE())} · ${Math.floor(cajaG())} g${cajaR()>=.1?' · '+coma(Math.round(cajaR()*10)/10)+' g rosin':''}`,ic:icono('billetes'),
      desc:`${CAJA[S.caja.nivel].n}, detrás del diploma. Caben ${eur(CAJA[S.caja.nivel].money)} y ${kgTxt(CAJA[S.caja.nivel].g)}.\nLo que está dentro no lo llevas encima.`}]:[],[{label:'Vida',right:`${S.hp}/${S.hpMax}`,desc:'Se recupera durmiendo, comiendo o con el tiempo.'},
      ...(S.pelea.xp>0?[{label:'Pelea',right:'nivel '+nivelPelea(),desc:fichaPelea()}]:[]),].concat(Object.keys(PRODUCTOS).filter(k=>k==='fert'||S.items[k]>0).map(k=>({label:PRODUCTOS[k].n,right:'×'+S.items[k],ic:icono('abono'),desc:descProducto(k)})),   // abonos y pH− por marca (1.23)
      S.items.medidor?[{label:'Medidor de pH y EC',right:'×1',desc:'Con él corriges el pH justo y ves la EC y el pH de cada maceta en PLANTAS.'}]:[],
      S.items.tarros?[{label:'Tarros de curado',right:'en el arcón',desc:`Lo que guardas en el arcón se cura en ${CURADO.dias} días: se vende un ${pct0(CURADO.precio)} % más caro y ya no pierde THC.`}]:[],[{label:'Insecticida (tratamientos)',right:'×'+S.items.insect,ic:icono('insecticida'),desc:'Úsalo en una maceta con plaga.'},
      {label:'Spray de pimienta',right:'×'+S.items.spray,ic:icono('spray'),desc:'Solo en combate.'},{label:'Bocata',right:'×'+S.items.bocata,ic:icono('bocadillo'),desc:'Pulsa A para comerlo: +15 de vida.',k:'bocata'}]));
    for(const k in MACETAS)if(S.items['m_'+k]>0)rows.push({label:'Maceta '+MACETAS[k].n,right:'×'+S.items['m_'+k],ic:icono('maceta'),desc:descMaceta(k)+'\nSe cambia en una plaza vacía de la carpa.'});
    for(const k in FOCOS)if(S.items['f_'+k]>0)rows.push({label:'Foco '+FOCOS[k].n,right:'×'+S.items['f_'+k],ic:icono(icoFoco(k)),desc:descFoco(k)+'\nSe cuelga desde la vista de carpa: ▲ hasta el foco y A.'});
    for(const k in EXTRAS)if(S.items['x_'+k]>0)rows.push({label:EXTRAS[k].n,right:'×'+S.items['x_'+k],ic:icono(ICX[k]),desc:EXTRAS[k].d+`\nSe pone${EXTRAS[k].pl?'n':''} desde la vista de carpa: ▲ hasta el foco y A.`});
    for(const [k,v] of Object.entries(S.seeds))rows.push({label:'Semilla '+getStrain(k).n,right:'×'+v,sw:getStrain(k).c,ic:icono('semillas'),desc:strainLine(k)+'\nPulsa A para tirarlas.',k:'s',sid:k});
    for(const e of S.esquejes)rows.push({label:'Esqueje '+getStrain(e.sid).n+etiq(e.f),right:'día '+(e.dia+ESQUEJE_DIAS),sw:getStrain(e.sid).c,ic:iconoCogollo(e.sid),desc:`Enraizando en el propagador. Plántalo en una plaza vacía antes de que acabe el día ${e.dia+ESQUEJE_DIAS}.\nPulsa A para ponerle nombre o tirarlo.`,k:'e',e});
    for(const [k,b] of Object.entries(S.buds))rows.push({label:lotNombre(k),right:`${Math.floor(b.g)} g · ${pct(b.thc)}%`,sw:getStrain(lotSid(k)).c,ic:iconoCogollo(lotSid(k)),desc:(k.endsWith('*')?'Cogollos de un fenotipo estrella, en lote aparte.\n':'Cogollos listos para vender.\n')+(curaTxt(b)?curaTxt(b)+'\n':'')+(S.catas[lotSid(k)]?S.catas[lotSid(k)]+'\n':'')+getStrain(lotSid(k)).o+'\nPulsa A para catarlo'+(S.items.analizador?' o analizarlo.':'.'),k:'b',key:k});
    for(const [k,b] of Object.entries(S.rosin))rows.push({label:'Rosin · '+lotNombre(k),right:`${coma(b.g)} g · ${pct(b.thc)}%`,sw:'#d89a18',ic:iconoCogollo(lotSid(k)),desc:'Rosin: extracción prensada sin disolventes. Lo compran los catadores.\n'+getStrain(lotSid(k)).o});
    if(S.items.prensa)rows.push({label:'Prensa de rosin',right:'en la mesa',desc:'De 5 g de cogollo, 1 g de rosin con el triple de THC. Se usa en la mesa del piso.'});
    i=await menu(rows,{cls:'full',title:'MOCHILA',title2:`${Math.floor(totalBuds())} g encima`+(S.caja?` · ${Math.floor(cajaG())} g en la caja`:''),desc:true,initial:i});
    if(i<0)return;
    if(rows[i].k==='bocata'){if(S.items.bocata>0&&S.hp<S.hpMax){S.items.bocata--;S.hp=Math.min(S.hpMax,S.hp+15);sfx('get');toast('Te comes el bocata. +15 de vida',1200);}else sfx('bump');}
    else if(rows[i].k==='e')await esquejeAccion(rows[i].e,S.esquejes);
    else if(rows[i].k==='b')await loteAccion(rows[i].key);   // la cata y el análisis (1.15)
    else if(rows[i].k==='s'){   // tirar semillas (1.11)
      const sid=rows[i].sid,n=S.seeds[sid],o=n>1?['Tirar 1','Tirar todas','Nada']:['Tirar','Nada'],c=await ask(`${n>1?n+' semillas':'1 semilla'} de ${getStrain(sid).n}.`,o);
      if(o[c]&&o[c]!=='Nada'){const q=o[c]==='Tirar todas'?n:1;S.seeds[sid]-=q;if(!S.seeds[sid])delete S.seeds[sid];sfx('sel');await say(q>1?`Tiras las ${q} semillas.`:'Tiras 1 semilla.');}
    }
  }
}
async function plantas(){
  const rows=[],H=huecos(),cl=climaSala();
  rows.push({label:'Sala',right:S.sala.termo?tClima(cl):'¿?',desc:S.sala.termo?salaDesc():'Sin termohigrómetro no sabes la temperatura ni la humedad de la sala. Kiko lo vende.'});
  S.carpas.forEach((c,ci)=>{
    if(!c)return;const C=CARPAS[c.t],F=FOCOS[c.foco],wm2=Math.round(F.w/(C.cm[0]*C.cm[2]/1e4));
    rows.push({label:C.n,right:F.n,ic:icono(icoCarpa(c.t)),desc:`${C.plazas} plantas · foco ${F.n}, ${wm2} W/m²${wm2<W_M2?' (poca luz: crecen más despacio y con menos THC)':''}\nLuz: ${eur(luzCarpa(ci))} al día con plantas · hasta ${C.wmax} W, macetas de ${C.lmax} L y ${litrosMax(ci)} L de tierra (${litrosCarpa(ci)} puestos).\n${extTxt(ci)}${S.sala.termo&&plantasVivas(ci)?' · dentro, de día '+tClima(climaCarpa(ci,false)):''}`});
    H.forEach((h,i)=>{if(h.c!==ci)return;const p=S.pots[i],M=MACETAS[S.macetas[i]];
      if(!p){rows.push({label:`  ${h.j+1} · vacía`,right:M.l+' L',ic:icono('maceta'),desc:`Maceta de ${M.n}. Planta algo desde la carpa de tu piso.`});return;}
      const s=getStrain(p.sid);
      rows.push({label:`  ${h.j+1} · ${s.n}${etiq(p.f)}`,sw:s.c,ic:iconoCogollo(p.sid),right:p.dead?'muerta':p.prog>=1?'LISTA':`${Math.floor(p.prog*100)}%`,desc:p.dead?'Se ha secado. Retírala.':`${p.prog>=1?'Lista para cosechar':stageName(p)} · Agua ${Math.round(p.water)}% · Salud ${Math.round(p.health)}%\n${p.pest?'PLAGA: trátala con insecticida. ':''}${abonoTxt(p)} · maceta de ${M.n}.`});});
  });
  const luz=facturaLuz();
  let i=0;do{i=await menu(rows,{cls:'full',title:'CULTIVO',title2:luz?'Luz '+eur(luz)+'/día':'Luz apagada',desc:true,initial:i});}while(i>=0);
}

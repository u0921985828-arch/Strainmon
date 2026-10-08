/* =========================================================
   PERSONAJES Y GUION
   ========================================================= */
// precios de growshop reales (1.10). Semillas: lo que cuesta una feminizada; se venden en sobres (SOBRES), más baratas cuanto
// más grande el sobre, y desde el capítulo 3 en bolsas de 50 a granel. n: dosis que trae el bote
const SHOP=[
  {lbl:'Semillas Skunk #1',p:5,ch:1,sid:'ria'},{lbl:'Semillas Lemon Haze',p:9,ch:2,sid:'limon'},{lbl:'Semillas OG Kush',p:10,ch:2,sid:'txoko'},
  {lbl:'Semillas Blueberry',p:8,ch:3,sid:'niebla'},{lbl:'Semillas Mango',p:7,ch:3,sid:'mango'},{lbl:'Semillas Purple Afghani',p:8,ch:4,sid:'purpura'},
  {lbl:'Abono de floración 1 L',p:14,ch:1,item:'fert',n:4,desc:'4 dosis. Una por planta: +25% de cosecha.'},
  {lbl:'Insecticida de neem 500 ml',p:12,ch:1,item:'insect',n:3,desc:'3 tratamientos. Cada uno elimina una plaga de araña roja.'},
  {lbl:'Bocata',p:5,ch:1,item:'bocata',desc:'Recupera 15 de vida. En combate o desde la mochila.'},
  {lbl:'Spray de pimienta',p:15,ch:2,item:'spray',desc:'En combate: 12-16 de daño seguro a un ladrón.'},
  {lbl:'Maceta de tela 11 L',p:3,ch:1,maceta:'tela11'},{lbl:'Maceta de plástico 18 L',p:2,ch:2,maceta:'plastico18'},{lbl:'Maceta de tela 25 L',p:4,ch:3,maceta:'tela25'},
  {lbl:'Foco LED 100 W',p:110,ch:1,foco:'led100'},{lbl:'Ventilador de pinza',p:20,ch:1,extra:'vent'},{lbl:'Garrafas de riego',p:15,ch:1,extra:'garrafas'},
  {lbl:'Extractor con filtro de carbón',p:110,ch:2,extra:'filtro'},{lbl:'Riego por goteo',p:1200,ch:4,extra:'goteo'},
  {lbl:'Foco sodio 250 W',p:85,ch:2,foco:'sodio250'},{lbl:'Foco LED 200 W',p:220,ch:2,foco:'led200'},
  {lbl:'Foco sodio 400 W',p:100,ch:3,foco:'sodio400'},{lbl:'Foco LED 480 W',p:500,ch:3,foco:'led480'},
  {lbl:'Foco sodio 600 W',p:120,ch:4,foco:'sodio600'},{lbl:'Foco LED 720 W',p:950,ch:5,foco:'led720'},
  {lbl:'Armario 80×80',p:90,ch:3,carpa:'p80',ci:0,desc:'Cambia el armario de tu tía por uno de 80: 3 plantas, focos de hasta 400 W y macetas de hasta 18 L. Tus plantas, foco y macetas se quedan.',cond:()=>S.carpas[0].t==='p60'},
  {lbl:'Carpa 100×100',p:120,ch:2,carpa:'m100',ci:1,desc:'Segunda carpa para el piso: 4 plantas, focos de hasta 480 W y macetas de hasta 25 L. Trae un CFL y macetas de 7 L.',cond:()=>!S.carpas[1]},
  {lbl:'Carpa 150×100',p:140,ch:4,carpa:'g150',ci:1,desc:'Cambia tu carpa de 100 por una de 150: 6 plantas y focos de hasta 720 W. Tus plantas, foco y macetas se quedan.',cond:()=>S.carpas[1]&&S.carpas[1].t==='m100'},
  {lbl:'Carpa 120×120',p:150,ch:5,carpa:'m120',ci:2,desc:'Tercera carpa, junto a la cama: 6 plantas, focos de hasta 720 W y macetas de hasta 25 L. Trae un CFL y macetas de 7 L. Antes necesitas la del fondo.',cond:()=>!!S.carpas[1]&&!S.carpas[2]},
  {lbl:'Termohigrómetro',p:12,ch:1,aparato:'termo'},{lbl:'Calefactor',p:35,ch:2,aparato:'calef'},{lbl:'Humidificador',p:40,ch:2,aparato:'humi'},
  {lbl:'Deshumidificador',p:190,ch:3,aparato:'deshu'},{lbl:'Aire acondicionado portátil',p:320,ch:3,aparato:'aire'},
  {lbl:'Bolsa de deporte',p:35,ch:3,bolsa:1,desc:'Llevas encima hasta 3 kg de cogollos y rosin (la mochila, 1 kg).',cond:()=>bolsaYa()<1},
  {lbl:'Maleta con ruedas',p:90,ch:5,bolsa:2,desc:'Llevas encima hasta 10 kg de cogollos y rosin.',cond:()=>bolsaYa()<2},
  {lbl:'Prensa de rosin',p:250,ch:3,item:'prensa',desc:'Prensa manual de calor (1.10): de 5 g de cogollo, 1 g de rosin con el triple de THC. Se usa en la mesa del piso. Lo compran los catadores.',cond:()=>!S.items.prensa},
];
const SOBRES=[[1,1],[3,.95],[5,.9],[10,.85]],GRANEL=[50,.6];   // [semillas, precio por semilla relativo]
const precioSobre=(it,[n,f])=>Math.round(it.p*n*f);
async function comprarSemillas(it){
  const l=SOBRES.concat(S.ch>=3?[GRANEL]:[]);
  const j=await ask(`Semillas feminizadas de ${STRAINS[it.sid].n}. ¿Cuántas?`,l.map(([n,f])=>`${n===1?'1 semilla':n>=50?'Bolsa de '+n:'Sobre de '+n} · ${eur(precioSobre(it,[n,f]))}`).concat(['Nada']),'KIKO');
  if(j<0||j>=l.length)return;
  const e=precioSobre(it,l[j]);if(S.money<e){sfx('bad');return say('No te llega el dinero.','KIKO');}
  S.money-=e;sfx('coin');addSeeds(it.sid,l[j][0]);toast(`Comprado: ${l[j][0]} × ${STRAINS[it.sid].n}`,1200);
}
// la deuda de la tía (1.10, a escala real): 30.000 € en tres plazos (capítulos 3, 5 y 7). Con equipo y precios reales, un
// jugador que reinvierte paga cada plazo en las mismas cosechas que antes (simulación en docs/ECONOMIA.md). Si un plazo
// vence, Toño suma INTERES. META_VENTAS: lo que hay que vender en la calle en el capítulo 2
const DEUDA=30000,PLAZOS={3:3000,5:12000,7:15000},INTERES=.2,PREMIO_COPA=5000,SOBORNO=1500,MULTA_REDADA=3000,META_VENTAS=300;
const yLista=l=>l.length>1?l.slice(0,-1).join(', ')+' y '+l[l.length-1]:l[0];
for(const it of SHOP){if(it.maceta)it.desc=descMaceta(it.maceta)+'\nSe cambia en una plaza vacía de la carpa.';if(it.foco)it.desc=descFoco(it.foco)+'\nAguanta en carpas de '+yLista(Object.values(CARPAS).filter(C=>FOCOS[it.foco].w<=C.wmax).map(C=>C.cm[0]))+'.';if(it.extra){const k=it.extra;it.desc=EXTRAS[k].d+(EXTRAS[k].pl?'\nUna tanda por carpa.':'\nUno por carpa.');it.cond=()=>S.carpas.filter(c=>faltaExtra(c,k)).length>S.items['x_'+k]+S.envio.filter(l=>l===it.lbl).length;}
  if(it.aparato){const k=it.aparato;it.desc=APARATOS[k].d+'\nUno para la sala: Kiko lo deja puesto.';it.cond=()=>!S.sala[k]&&!S.envio.includes(it.lbl);}}   // lo pedido por el móvil (12b-movil) no se vuelve a vender
// carpa comprada (en un sitio libre) o ampliada (mismo sitio, se quedan foco, extras, plantas y macetas): cada plaza
// conserva su planta y su maceta por (carpa, plaza); las nuevas, vacías y con maceta de 7 L. La casa se vuelve a montar al entrar
function comprarCarpa(t,ci){
  const antes=huecos().map(h=>h.c+':'+h.j),pots=S.pots,mac=S.macetas;
  if(S.carpas[ci])S.carpas[ci].t=t;else S.carpas[ci]={t,foco:'cfl'};
  const k=huecos().map(h=>antes.indexOf(h.c+':'+h.j));
  S.pots=k.map(j=>j>=0?pots[j]||null:null);S.macetas=k.map(j=>j>=0?mac[j]||'plastico7':'plastico7');
}
const DICHO_CARPA={m100:'Te la monto esta tarde en el piso, al fondo, al lado del armario. Viene con un CFL; si quieres más luz, aquí tienes focos.',
  g150:'Me llevo la de 100 y te monto la de 150 en su sitio. Las plantas ni se enteran.',
  p80:'Te guardo el armario de tu tía en el trastero y te monto uno de 80 en su sitio. Las plantas ni se enteran.',
  m120:'Te la monto junto a la cama. Viene con un CFL y macetas de 7 L.'};
async function shop(){
  let i=0;
  for(;;){
    const list=SHOP.filter(it=>S.ch>=it.ch&&(!it.cond||it.cond()));
    const IC={fert:'abono',insect:'insecticida',spray:'spray',bocata:'bocadillo'};
    const items=list.map(it=>({label:it.lbl,right:eur(it.p)+(it.sid?'/u':''),sw:it.sid?STRAINS[it.sid].c:null,ic:it.sid?icono('semillas'):it.item?icono(IC[it.item]):it.maceta?icono('maceta'):it.foco?icono(icoFoco(it.foco)):it.extra?icono(ICX[it.extra]):it.carpa?icono(icoCarpa(it.carpa)):null,desc:it.sid?strainLine(it.sid):it.desc}));
    items.push({label:'Salir',desc:'Volver al mostrador.'});
    i=await menu(items,{cls:'full',title:'GROWSHOP KIKO',title2:'Tienes '+eur(S.money),desc:true,initial:i});
    if(i<0||i>=list.length)break;
    const it=list[i];
    if(it.sid){await comprarSemillas(it);await checkStory();continue;}
    if(S.money<it.p){sfx('bad');await say('No te llega el dinero.','KIKO');continue;}
    S.money-=it.p;sfx('coin');
    if(it.item)S.items[it.item]+=it.n||1;if(it.maceta)S.items['m_'+it.maceta]++;if(it.bolsa)S.items.bolsa=it.bolsa;if(it.aparato)S.sala[it.aparato]=true;
    if(!it.foco&&!it.carpa&&!it.extra)toast('Comprado: '+it.lbl,1200);
    if(it.carpa){comprarCarpa(it.carpa,it.ci);await say(DICHO_CARPA[it.carpa],'KIKO');}
    if(it.extra){S.items['x_'+it.extra]++;const ok=S.carpas.map((c,ci)=>faltaExtra(c,it.extra)?ci:-1).filter(ci=>ci>=0);
      const pl=EXTRAS[it.extra].pl;
      if(!ok.length)await say(pl?'Ya tienes unas en cada carpa. Te las guardo en la mochila.':'Ya tienes uno en cada carpa. Te lo guardo en la mochila.','KIKO');
      else{const c=await ask(pl?'¿Te las pongo ya?':'¿Te lo pongo ya?',ok.map(ci=>CARPAS[S.carpas[ci].t].n).concat(['Luego']),'KIKO');
        if(c>=0&&c<ok.length){const vu=it.extra==='goteo'&&S.carpas[ok[c]].garrafas;ponerExtra(ok[c],it.extra);toast((pl?'Puestas: ':'Puesto: ')+it.lbl,1200);
          if(vu)await say('Las garrafas de esa carpa vuelven a la mochila.','KIKO');}}}
    if(it.foco){S.items['f_'+it.foco]++;const ok=S.carpas.map((c,ci)=>c&&FOCOS[it.foco].w<=CARPAS[c.t].wmax?ci:-1).filter(ci=>ci>=0);
      if(!ok.length)await say('Ese foco calienta demasiado para tus carpas. Guárdalo hasta que tengas una más grande.','KIKO');
      else{const c=await ask('¿Lo cuelgo ya? El que quites va a tu mochila.',ok.map(ci=>`${CARPAS[S.carpas[ci].t].n} (${FOCOS[S.carpas[ci].foco].n})`).concat(['Luego']),'KIKO');
        if(c>=0&&c<ok.length){instalarFoco(ok[c],it.foco);toast('Instalado: '+it.lbl,1200);}}}
    await checkStory();
  }
  await say('Ten cuidado ahí fuera.','KIKO');
}
const RECIPE_HINTS=['Skunk #1 polinizada con Lemon Haze: así salió la Lemon Skunk.','OG Kush con Blueberry da Blueberry Kush. Índica, de color azulado.','Afghani con Skunk #1 es la Critical Mass. Produce como ninguna.','Hindu Kush con Purple Afghani: la Purple Kush.','Mango con Hindu Kush: Mango Kush.','Blueberry con una Haze da Blue Dream. Con la Lemon Haze te vale.','Acapulco Gold con Afghani: así se hizo la Trainwreck.','Las de segunda generación se cruzan entre ellas: Critical Kush, Super Lemon Haze, Purple Haze...','La Amnesia Haze de Darko viene de una Super Lemon Haze y una Trainwreck.','La Fire OG sale de Critical Kush con Blueberry Kush. Hace falta paciencia.','Una Amnesia Haze con una Fire OG... de ahí sale la Ghost Train Haze. Yo nunca lo he conseguido.'];
function kikoTip(){
  const t=[['Riega cuando el agua baje del 30 %. Una planta seca enferma.','El abono se echa una vez por planta. Merece la pena.','Las plantas crecen mientras duermes. No hace falta mirarlas cada hora.','Un CFL da poco: unos 0,3 gramos por vatio. Un LED, el triple.'],
    ['Los clientes cambian cada día. No los hagas esperar.','Pedir caro funciona con turistas, con gente de dinero y con cogollo potente.','Si la presión policial (CALOR) sube mucho, deja de vender unos días.','Una carpa más grande es la mejor inversión que puedes hacer.','Tu tía pedía landraces a un banco de semillas por internet. Mira en su ordenador.','Lo que sale de un cruce es una F1: cada planta sale distinta. Crúzala consigo misma hasta fijarla.','Las macetas de tela airean las raíces: más cosecha y menos plagas, pero hay que regar más.','Cada semilla es una planta distinta. Si compras muchas, alguna sale estrella: más potente y más productiva.','Si una planta promete, sácale esquejes en crecimiento. Un esqueje es la misma planta: así se guarda un fenotipo estrella.','Una maceta pequeña no da más de unos 8 gramos por litro de tierra, por mucho foco que le pongas.'],
    ['El LED cuesta más, pero rinde más y apenas da calor. El sodio es barato y seca las macetas.','Un foco pequeño en una carpa grande no llega a todas las plantas.','La luz se paga: cada carpa con plantas suma su factura cada día. Un LED de 720 W gasta unos 280 kWh al día: 45 €.','Una plaza vacía es luz que pagas y no aprovechas.','Iñaki, el del muelle, compra cantidad. Paga menos por gramo que la calle, pero se lo lleva todo.','De noche, en el parque, roban. Lleva el spray de pimienta.'],
    RECIPE_HINTS.concat(['Las landraces no las vendo. Pregunta por el barrio: Txaro, Iñaki el del muelle... y mira bien en el parque.'])];
  return pick(t[Math.min(3,Math.max(0,S.ch-1))].concat(S.ch>3?t[1]:[]));
}
async function talkKiko(){
  const N='KIKO';
  if(!S.flags.kiko1){
    await talk(N,['{N}, pasa. Te pareces a tu tía.','Maite y yo cultivamos juntos desde que cerraron los astilleros. Ella tenía mano; yo, paciencia.','Para empezar, toma esto.']);
    addSeeds('ria',3);await got('3 semillas de SKUNK #1');S.items.fert+=2;await got('2 dosis de ABONO');
    await talk(N,['La Skunk #1 aguanta casi todo: errores de riego, plagas, frío. Es la mejor para aprender.','Planta en las macetas del armario de tu tía y riega cuando baje el agua.','El abono da más cogollo. Si ves araña roja, insecticida: lo tengo aquí.','Cuando esté lista, cosecha. Son feminizadas: casi nunca dan semilla, pero si sale alguna, guárdala.','Las plantas siguen creciendo mientras duermes.']);
    S.flags.kiko1=true;showObjective();return;
  }
  if(S.ch===4&&!S.flags.lab){
    await talk(N,['Ya me han contado que has pagado a Baltasar. Bien hecho.','Te he montado en el piso mi equipo de polinización: pinceles, bolsas de papel y una lupa.']);
    S.flags.lab=true;await got('la MESA DE GENÉTICA');
    addSeeds('rif',3);await got('3 semillas de AFGHANI');
    await talk(N,['Me las trajo un amigo de Mazar-i-Sharif en los ochenta. Las he ido renovando desde entonces.','En la mesa polinizas una variedad con otra: gastas una semilla de cada y obtienes 2 del cruce.','Algunos cruces dan variedades conocidas. Otros, híbridos que solo tendrás tú.','Apúntalo todo en la GENOTECA. Las mejores genéticas salen de cruzar cruces.',
      'Empieza por las conocidas: saca dos de receta en la mesa y cosecha una planta de cada. Patxi, el de la plaza, se sabe unas cuantas.']);
    showObjective();await checkStory();return;
  }
  if(!Object.keys(S.seeds).length&&!S.pots.some(Boolean)&&!totalBuds()&&!totalRosin()&&!cajaG()&&!cajaR()&&!arconG()&&!arconR()&&S.money+cajaE()<15){   // lo de la caja y el arcón también cuenta (1.10)
    await say('¿Sin semillas y sin dinero? Toma. Ya me lo pagarás.',N);addSeeds('ria',2);await got('2 semillas de SKUNK #1');
  }
  const c=await ask('¿Qué necesitas?',['Comprar','Un consejo','Nada'],N);
  if(c===0)await shop();else if(c===1)await say(kikoTip(),N);else await say('Ten cuidado ahí fuera.',N);
}
async function talkJosune(){
  const N='JOSUNE';
  const c=await ask('¡Kaixo! ¿Qué te pongo?',['Pintxo · 4 €','Kalimotxo · 3 €','¿Algún rumor?','Nada'],N);
  if(c===0||c===1){const cost=c?3:4,hp=c?6:12;if(S.money<cost)return say('Aquí no se fía.',N);
    S.money-=cost;S.hp=Math.min(S.hpMax,S.hp+hp);sfx('coin');return say(c?'Un kalimotxo. Recuperas algo de vida.':'Pintxo de tortilla, recién hecha. Recuperas vida.',N);}
  if(c===2)return say(pick(['Dicen que alguien escondía cosas en los arbustos del parque.','Iñaki, el del muelle, trae semillas de sus viajes.','Txaro está con la quimio. Lo está pasando muy mal.','Darko es sobrino de Baltasar. Por eso nadie le dice nada.','El sargento Molina cobra por mirar hacia otro lado. Lo sabe todo el barrio.']),N);
}
async function talkPatxi(){S.patxi=(S.patxi||0)+1;await say(S.ch<4?'Cuando tengas una mesa de genética, ven a verme. Algo sé de cruces.':'Cuarenta años cultivando en el monte. Te digo una cosa: '+RECIPE_HINTS[S.patxi%RECIPE_HINTS.length],'PATXI');}
async function talkTxaro(){
  const N='ABUELA TXARO';
  if(S.flags.txaro&&(S.flags.txaro2||S.ch<4))return say(pick(['Ya duermo de un tirón. Gracias, de verdad.','Tu tía me ayudaba igual. No se lo contábamos a nadie.']),N);
  // segunda misión (1.10), en su casa desde el capítulo 4: 10 g de una índica (70 % o más)
  if(S.flags.txaro){
    await talk(N,['El aceite me ha devuelto el sueño. Gracias, de verdad.','Pero el dolor no se va. El médico dice que, para eso, mejor una índica: relaja más.','¿Me traerías 10 gramos de una índica? De las de hoja ancha.']);
    const lots=budLots(10).filter(([k])=>indDe(lotSid(k))>=70);if(!lots.length)return say('Cuando tengas 10 gramos de una índica, ven a verme. Aquí estaré.',N);
    const i=await menu(lots.map(lotItem).concat([{label:'Ahora no'}]),{cls:'right',title:'¿Qué le das?'});
    if(i<0||i>=lots.length)return say('No pasa nada. Aquí estaré.',N);
    useBuds(lots[i][0],10);S.rep+=5;
    await say('Toma, las últimas de mi Paco. Las trajo de Chitral, en las montañas de Pakistán.',N);
    addSeeds('chitral',3);await got('3 semillas de CHITRAL KUSH');S.items.bocata+=3;await got('3 × BOCATA');S.flags.txaro2=true;return;
  }
  await talk(N,['Tú vives en el piso de Maite. Tu tía me ayudaba con... ya sabes.','Desde la quimio apenas duermo y no tengo hambre. Las pastillas no me hacen nada.','Me vendrían bien 5 gramos, para hacer aceite como me enseñó ella. ¿Me los das?']);
  const lots=budLots(5);if(!lots.length)return say('Cuando tengas 5 gramos, acuérdate de mí.',N);
  const i=await menu(lots.map(lotItem).concat([{label:'Ahora no'}]),{cls:'right',title:'¿Qué le das?'});
  if(i<0||i>=lots.length)return say('No pasa nada. Aquí estaré.',N);
  useBuds(lots[i][0],5);
  await say('Gracias. Toma: las trajo mi Paco de Pakistán en el setenta y seis. Nunca supe qué hacer con ellas.',N);
  addSeeds('hindu',2);await got('2 semillas de HINDU KUSH');S.items.bocata+=3;await say('Y llévate estos bocadillos, que comes poco.',N);await got('3 × BOCATA');S.flags.txaro=true;
  await say('Me voy a casa a preparar el aceite. Vivo en la casa gris, al lado del bar. Pásate cuando quieras.',N);
  if(S.map==='town'){await fade(1);buildEnts();await fade(0);}
}
// Iñaki: 10 g para el viaje, una vez al día; desde el capítulo 3 también compra al por mayor (ventaMayor)
async function talkInaki(){
  const N='IÑAKI';
  if(S.ch>=3){const c=await ask('Aupa. ¿Qué traes?',['10 g para el viaje','Venta al por mayor','Nada'],N);if(c===1)return ventaMayor(N);if(c!==0)return;}
  if(S.iDay===S.day)return say('Ya me has vendido hoy. Mañana más, que el barco sale temprano.',N);
  await say('Aupa. Me voy tres semanas a la mar. ¿Tienes 10 g para el viaje? Pago bien.',N);
  const lots=budLots(10);if(!lots.length)return say('Pues nada. Si consigues 10 g, aquí estaré.',N);
  const i=await menu(lots.map(lotItem).concat([{label:'Nada'}]),{cls:'right',title:'¿Qué le vendes?'});
  if(i<0||i>=lots.length)return;
  const [sid,b]=lots[i],amt=Math.round(precioCalle(b.thc)*1.2*10);
  if(await ask(`Te doy ${amt} € por 10 g de ${lotNombre(sid)}. ¿Hecho?`,['Hecho','No'],N)!==0)return;
  useBuds(sid,10);S.money+=amt;S.sales+=amt;S.heat=Math.min(100,S.heat+3);S.iDay=S.day;S.rep+=2;sfx('coin');
  if(!S.flags.inaki){S.flags.inaki=true;await say('Toma. Me las dio un marinero de Malaui en Mombasa, en el último viaje.',N);addSeeds('malawi',2);await got('2 semillas de MALAWI GOLD');}
  else await say('Eskerrik asko. Hasta la vuelta.',N);
  await checkStory();
}
// al por mayor (1.10): lotes de 100 g para arriba a precioMayor (10-calle), una carga al día y hasta mayorDia() gramos;
// sube el calor 2 + 1 por cada 100 g (1.10: antes, por cada 250 g)
const mayorDia=()=>IMPERIO[S.ch>=8?imperioNivel():0].mayor;
const kgTxt=g=>g>=1000?coma(g/1000)+' kg':g+' g';
async function ventaMayor(N){
  if(S.mDay===S.day)return say('Hoy ya he cargado. Mañana sale otro barco.',N);
  const lots=budLots(100);
  if(!lots.length)return say(`Al por mayor, de 100 g para arriba. Pago entre ${coma(precioMayor(12).toFixed(2))} y ${coma(precioMayor(30).toFixed(2))} € el gramo, según lo bueno que sea. Hasta ${mayorDia()>=1000?coma(mayorDia()/1000)+' kg':mayorDia()+' g'} por carga.`,N);
  const i=await menu(lots.map(lotItem).concat([{label:'Nada'}]),{cls:'right',title:'¿Qué lote?'});
  if(i<0||i>=lots.length)return say('Otro día.',N);
  const [k,b]=lots[i],pg=Math.round(precioMayor(b.thc)*100)/100,tope=Math.min(Math.floor(b.g),mayorDia());
  const ops=[100,250,500,1000,2000,5000,10000].filter(g=>g<tope).concat([tope]),kg=kgTxt;
  const j=await ask(`${lotNombre(k)} a ${coma(pg.toFixed(2))} € el gramo. ¿Cuánto cargas?`,ops.map(g=>`${kg(g)} · ${eur(g*pg)}`).concat(['Nada']),N);
  if(j<0||j>=ops.length)return;
  const g=ops[j],e=Math.round(g*pg);
  useBuds(k,g);S.money+=e;S.sales+=e;S.mDay=S.day;S.heat=Math.min(100,S.heat+2+g/100);S.rep+=1;sfx('coin');
  await accion('vender',{id:'vfx-monedas',x:P.px+8,y:P.py+2});
  toast(`+${eur(e)} · ${kg(g)} al por mayor`,1600);
  await say('Cargado. Esta noche sale en el barco.',N);heatWarn();await checkStory();
}
async function talkCop(){
  if(cargaSosp()>0&&!S.protect){await say('¿Y ese olor? Quieto ahí.','AGENTE');await battle('police');return;}
  await say(pick(['Circule.','Todo tranquilo por aquí. Que siga así.','De noche hay robos en el parque. Tenga cuidado.']),'AGENTE');
}
async function talkDarko(){
  const N='DARKO';
  if(S.ch===6)return talk(N,['¿Vienes a la Copa? Mi AMNESIA HAZE dio un 26,8 % de THC en el laboratorio.','Nadie en Ribera ha pasado del 26. No vas a ser tú el primero.']);
  if(S.ch>=7)return talk(N,[S.flags.robo?'¿Has dormido bien últimamente?':'Mi tío dice que ya no le debes nada. A mí, sí.','Estas esquinas son mías. Si vendes aquí, mis chicos te lo van a recordar.']);   // en los astilleros (1.10)
  S.flags.darko1=true;
  await talk(N,['Así que tú te has quedado el piso de Maite.','Soy DARKO. La hierba de este barrio la muevo yo.','Vende lo tuyo si quieres, pero lejos de mis esquinas.','No me hagas repetirlo.']);
  await fade(1);buildEnts();await fade(0);
}
// la cuota de Molina (1.10): SOBORNO cada CUOTA_DIAS días (S.protHasta, el último día cubierto; newDay la da por acabada).
// La primera vez, en la plaza; después, en la comisaría del barrio alto
const CUOTA_DIAS=10;
async function talkMolina(){
  const N='SARGENTO MOLINA',plaza=S.map==='town';
  if(!S.flags.molina1){S.flags.molina1=true;await talk(N,['Así que eres tú quien vende en la plaza.','Podría detenerte ahora mismo. O podemos entendernos.',`Por ${eur(SOBORNO)} cada ${CUOTA_DIAS} días, mis patrullas no pasan por tu calle. Y nada de registros en tu piso.`]);}
  else if(S.protect)await say(`Estás cubierto hasta el día ${S.protHasta}. ${S.protHasta>S.day?`Te quedan ${S.protHasta-S.day} días.`:'Se acaba HOY.'}`,N);
  const c=await ask(S.protect?'¿Pagar ya los diez días siguientes?':'¿Aceptas el trato del sargento?',['Pagar '+eur(SOBORNO),'No'],N);
  if(c===0){if(S.money<SOBORNO)await say('¿Con qué dinero? Vuelve cuando lo tengas.',N);
    else{S.money-=SOBORNO;S.protHasta=Math.max(S.day,S.protect?S.protHasta:0)+CUOTA_DIAS;S.protect=true;sfx('coin');await say(`Bien. Mis agentes mirarán hacia otro lado hasta el día ${S.protHasta}.`,N);}}
  else if(!S.protect){S.heat=Math.min(100,S.heat+10);await say('Tú sabrás. Mis agentes van a estar muy atentos.',N);heatWarn();}
  if(plaza){await say('Si me necesitas, estoy en la comisaría del barrio alto.',N);await fade(1);buildEnts();await fade(0);}
}
async function talkJurado(){
  const N='JURADO';
  await talk(N,['Esto es la COPA DE RIBERA, la de la asociación cannábica del barrio.','Para competir, trae 20 g de una sola variedad. Se analizan en laboratorio.','Marca a batir: DARKO, con AMNESIA HAZE, 26,8 % de THC.']);
  const lots=budLots(20);if(!lots.length)return say('Vuelve cuando tengas 20 g de algo.',N);
  const i=await menu(lots.map(lotItem).concat([{label:'Todavía no'}]),{cls:'right',title:'¿Qué presentas?'});
  if(i<0||i>=lots.length)return;
  const [sid,b]=lots[i],thc=Math.round(b.thc*10)/10,name=lotNombre(sid).replace(' ★','');useBuds(sid,20);
  await fade(1);await wait(500);await fade(0);
  await say('Resultado del laboratorio. AMNESIA HAZE de Darko: 26,8 % de THC.',N);
  await say(`${name} de {N}: ${pct(thc)} % de THC.`,N);
  if(thc>26.8){
    sfx('get');await say('Nueva marca. {N} gana la COPA DE RIBERA.',N);
    S.money+=PREMIO_COPA;S.rep+=20;await got(eur(PREMIO_COPA)+' y el trofeo de la Copa');
    await talk('DARKO',['Esto no se acaba aquí.','Mi tío se va a enterar.']);
    S.flags.copa=true;S.due=S.debt;S.deadline=S.day+7;await chapter(7);showObjective();   // el plazo, antes: chapter() guarda
  }else{sfx('bad');await say('Gana DARKO. La Copa sigue abierta: vuelve con algo más potente.',N);}
}
async function talkBaltasar(){
  const N='DON BALTASAR';
  if(S.ch<3)return say('¿Y tú quién eres? No tengo nada que hablar contigo.',N);
  // el plazo corre desde que Toño te avisa (1.10): si tardas más de 2 días en venir, «Llegas tarde»
  if(S.ch===3&&!S.flags.metB){
    await talk(N,[S.day-S.flags.tono>2?'Llegas tarde, {N}. Toño te dijo «hoy».':'Siéntate, {N}. Vamos al grano.',`Tu tía Maite me debía ${eur(DEUDA).replace(' €',' euros')}. Las deudas no se mueren con la gente.`,`Me los vas a pagar a plazos. El primero, ${eur(S.due)}${S.due>PLAZOS[3]?', con los intereses de tu retraso':''}.`,`Tienes hasta el día ${S.deadline}. Si no, Toño te hará una visita. Y Toño cobra intereses.`]);
    S.flags.metB=true;showObjective();return;
  }
  if(S.ch>=8)return encargoBaltasar(N);
  if(S.ch===4)return say('Tranquilo. Ya te avisaré cuando toque el siguiente pago.',N);
  if(S.ch===6)return say('Primero, la Copa. Darko te espera en la plaza.',N);
  const left=S.deadline-S.day;
  await say(`Me debes ${eur(S.due)} para el día ${S.deadline}. ${left>0?`Te quedan ${left} días.`:'Es HOY.'}`,N);
  if(S.money<S.due)return say('Vuelve cuando tengas el dinero.',N);
  if(await ask('¿Pagar ahora?',['Pagar','Todavía no'],N)!==0)return;
  S.money-=S.due;S.debt-=S.due;const paid=S.due;S.due=0;sfx('coin');toast(`Pagado: ${eur(paid)}`,1500);
  if(S.ch===3){
    await talk(N,['Puntual. Así me gusta.',`Quedan ${eur(S.debt).replace(' €','')}. Ya te avisaré del siguiente plazo.`]);
    await chapter(4);await talk('SMS · KIKO',['Pásate por el growshop. Tengo algo para ti.']);showObjective();
  }else if(S.ch===5){
    await talk(N,['Me sorprendes, {N}.',`Quedan ${eur(S.debt).replace(' €','')}. Te propongo algo.`,`La COPA DE RIBERA se juega estos días en la plaza. Premio: ${eur(PREMIO_COPA)}.`,'Mi sobrino Darko compite. No ha perdido nunca.','Gana la Copa y, con el premio y lo que vendas, me pagas lo que queda. Si puedes.']);
    await chapter(6);showObjective();
  }else if(S.ch===7){
    await talk(N,[`${eur(paid)}. Contados.`,'Deuda saldada. Lo de tu tía queda cerrado.','Una cosa más, {N}: si algún día quieres trabajar para mí, ya sabes dónde estoy.']);
    S.debt=0;S.imp0=S.sales;S.impN=0;await ending();
  }
}
// el rótulo del capítulo dura 2,8 s: el objetivo que se pida mientras tanto sale cuando acaba (sin parar el juego)
let capHasta=0;
async function chapter(n){S.ch=n;sfx('get');toast(`<small>CAPÍTULO ${n}</small>${CH_TITLES[n]}`,2800);capHasta=Date.now()+2800;buildEnts();await wait(400);save();}
function objectiveText(){
  switch(S.ch){
    case 1:return S.flags.llegada===false?'Coge el autobús en la plaza de Mendialde hasta Ribera Verde.':!S.flags.letter?(S.map==='home'?'Lee la carta que hay en la mesa.':'Entra en el piso de la tía Maite, enfrente de la parada, y lee la carta que hay en la mesa.'):!S.flags.kiko1?'Visita el growshop de Kiko, al lado de casa.':'Planta y consigue tu primera cosecha.';
    case 2:return `Gana ${META_VENTAS} € vendiendo (${Math.min(META_VENTAS,Math.round(S.sales))}/${META_VENTAS}).`;
    case 3:return !S.flags.metB?`Ve al bar El Ancla antes del día ${S.deadline}: Don Baltasar quiere ${eur(S.due)}.`:`Paga ${eur(S.due)} a Don Baltasar antes del día ${S.deadline}.`;
    case 4:return !S.flags.lab?'Kiko quiere verte en el growshop.':`Saca en la mesa 2 variedades de receta y cosecha una planta de cada (${recCount()}/2).`;
    case 5:return `Paga ${eur(S.due)} a Don Baltasar antes del día ${S.deadline}.`;
    case 6:return 'Gana la Copa: 20 g con más de 26,8% de THC al jurado de la plaza.';
    case 7:return `Paga los últimos ${eur(S.due)} a Don Baltasar antes del día ${S.deadline}.`;
    default:{if(S.encargo)return `Encargo de Don Baltasar: lleva ${kgTxt(S.encargo.g)} al almacén de los astilleros, de noche, antes de que acabe el día ${S.encargo.hasta}.`;
      const n=imperioNivel(),sig=IMPERIO[n+1],gen=`Genoteca ${DEX.filter(k=>S.disc[k]).length}/${DEX.length}`;
      return sig?`Tu imperio · ${IMPERIO[n].n}. Facturado desde la deuda: ${eur(Math.min(sig.meta,facturado()))} de ${eur(sig.meta)} para ser ${sig.n.toLowerCase()}. ${gen}.`:`Tu imperio · ${IMPERIO[n].n}. Completa la ${gen}.`;}
  }
}
function showObjective(){const d=capHasta-Date.now();if(d>0){setTimeout(showObjective,d);return;}toast(`<small>OBJETIVO</small>${esc(objectiveText())}`,3200);}
// el imperio (1.10): saldada la deuda, empieza. Cada rango se gana facturando desde el último pago (S.imp0) y sube lo que
// Iñaki carga al día
const IMPERIO=[{n:'Cultivador',meta:0,mayor:1000},{n:'Proveedor del barrio',meta:25000,mayor:2000},{n:'Distribuidor de la ría',meta:100000,mayor:5000},{n:'Mayorista del norte',meta:250000,mayor:10000}];
const facturado=()=>Math.max(0,S.sales-(S.imp0||0));
const imperioNivel=()=>{let n=0;IMPERIO.forEach((r,i)=>{if(facturado()>=r.meta)n=i;});return n;};
async function checkStory(){
  if(S.ch===1&&S.flags.harvest1){
    await chapter(2);spawnClients();
    await talk('SMS · KIKO',['Primera cosecha. Bien hecho.','La gente que busca material lleva un $ encima. Puedes venderles en la calle.','Cuanto más vendas, más se fijará la policía: es el CALOR. Y de noche hay quien roba.']);showObjective();
  }
  if(S.ch===2&&S.sales>=META_VENTAS){
    S.due=PLAZOS[3];S.deadline=S.day+7;S.flags.tono=S.day;await chapter(3);   // el plazo, desde ya (1.10)
    await say('Un hombre enorme en chándal te corta el paso.');
    await talk('TOÑO',['Tú vives en el piso de Maite, ¿no?','Don Baltasar quiere verte. En el bar El Ancla. Hoy.','Y ve contando: tienes siete días para el primer pago.','No me hagas venir a buscarte.']);showObjective();
  }
  if(S.ch>=8&&imperioNivel()>(S.impN||0)){
    S.impN=imperioNivel();const r=IMPERIO[S.impN];sfx('get');toast(`<small>TU IMPERIO</small>${r.n}`,2800);
    await talk('SMS · IÑAKI',[`Se corre la voz: ${eur(facturado())} vendidos desde que pagaste a Baltasar.`,`Desde hoy te cargo hasta ${r.mayor>=1000?coma(r.mayor/1000)+' kg':r.mayor+' g'} al día en el barco.`]);showObjective();
  }
  if(S.ch===4&&S.flags.lab&&recCount()>=2){
    S.due=PLAZOS[5];S.deadline=S.day+10;await chapter(5);
    await talk('SMS · TOÑO',[`Don Baltasar quiere ${eur(PLAZOS[5])} en diez días.`,'Otra cosa: un tal SARGENTO MOLINA pregunta por ti en la plaza.']);showObjective();
  }
}
async function penaltyEvent(){
  await say('TOÑO te estaba esperando.');
  const int=Math.round(S.due*INTERES/100)*100;S.vencidos++;
  await talk('TOÑO',['Don Baltasar dice que llegas tarde.',`Son ${eur(int)} más de intereses. Y esto, para que no se te olvide.`]);
  sfx('hurt');S.hp=Math.max(1,S.hp-15);S.due+=int;S.debt+=int;S.deadline=S.day+5;
  await say(`La deuda del plazo sube a ${eur(S.due)}. Nuevo límite: día ${S.deadline}.`);
  if(S.vencidos>=3){S.vencidos=0;await embargo();}
}
// al tercer plazo vencido (1.10), Toño se lleva la carpa más grande del fondo o de junto a la cama (B o C), con su foco, sus
// extras y sus plantas; sin ninguna de las dos, la mitad del dinero que llevas encima
const areaCarpa=ci=>CARPAS[S.carpas[ci].t].cm[0]*CARPAS[S.carpas[ci].t].cm[2];
function quitarCarpa(ci){
  const antes=huecos().map(h=>h.c+':'+h.j),pots=S.pots,mac=S.macetas;
  S.carpas[ci]=null;
  const k=huecos().map(h=>antes.indexOf(h.c+':'+h.j));
  S.pots=k.map(j=>pots[j]||null);S.macetas=k.map(j=>mac[j]||'plastico7');montarCasa();
}
async function embargo(){
  const l=[1,2].filter(ci=>S.carpas[ci]),ci=l.length?l.reduce((a,b)=>areaCarpa(b)>areaCarpa(a)?b:a):-1;
  await talk('TOÑO',['Tres plazos tarde. Don Baltasar se cobra en especie.']);
  if(ci>=0){const n=CARPAS[S.carpas[ci].t].n;quitarCarpa(ci);sfx('bad');await say(`TOÑO se lleva tu ${n}, con su foco y sus plantas.`);}
  else{const e=Math.floor(S.money/2);S.money-=e;sfx('bad');await say(`TOÑO te vacía los bolsillos: se lleva ${eur(e)}.`);}
}
// la redada (1.10, con la caja): lo de fuera, siempre; la caja, 1 de cada 4 veces (sus gramos, su rosin y la mitad de su dinero). La
// multa sale de lo de fuera y, si no llega, de la caja
async function raidEvent(){
  if(S.protect){S.heat=50;return talk('SMS · MOLINA',['Esta noche había orden de entrada en tu piso. La he parado.','Baja el ritmo.']);}
  sfx('bad');await say('REDADA. La policía entra en tu piso.');
  const g=Math.floor(totalBuds()+arconG()),r=totalRosin()+arconR();   // lo de encima y el arcón (1.10)
  S.pots=S.pots.map(()=>null);S.buds={};S.rosin={};S.arcon={buds:{},rosin:{}};S.heat=30;
  const hallada=!!S.caja&&Math.random()<CAJA_REDADA,cg=hallada?Math.floor(cajaG()):0,cr=hallada?cajaR():0,ce=hallada?Math.floor(S.caja.money/2):0;
  if(hallada){S.caja.buds={};delete S.caja.rosin;S.caja.money-=ce;}
  const fine=MULTA_REDADA-pagarCasa(MULTA_REDADA);
  await say(`Se llevan todas las plantas${r?`${g?`, ${g} g`:''} y ${rosinTxt(r)}`:` y ${g} g`}. Multa: ${eur(fine)}.`);
  const L=[...(cg||cr<.1?[cg+' g']:[]),...(cr>=.1?[rosinTxt(cr)]:[]),eur(ce)];   // sin «0 g» si solo había rosin
  if(S.caja)await say(hallada?`Encuentran la caja de detrás del diploma: se llevan ${L.slice(0,-1).join(', ')} y ${L[L.length-1]}.`:'La caja de detrás del diploma ni la ven.');
  await say('Toca empezar de nuevo. Y vender menos una temporada.');
}
async function ending(){
  await fade(1);const e=$('endcard');
  e.innerHTML=`<h2>DEUDA SALDADA</h2><div>Has saldado los ${eur(DEUDA)} de tu tía Maite en ${S.day} días.</div><div>Variedades: ${discCount()} · Ventas totales: ${eur(S.sales)}</div><div>Ahora empieza tu imperio: cuanto más factures, más carga Iñaki en el barco.<br>¿Completarás la GENOTECA? ¿Conseguirás la GHOST TRAIN HAZE?</div><div style="opacity:.7">Pulsa A</div>`;
  e.hidden=false;await fade(0);sfx('get');
  await new Promise(r=>push(b=>{if(b==='A'||b==='START'){pop();r();}}));
  await fade(1);e.hidden=true;await fade(0);await chapter(8);showObjective();
}


/* =========================================================
   PERSONAJES Y GUION
   ========================================================= */
const SHOP=[
  {lbl:'Semilla Skunk #1',p:15,ch:1,sid:'ria'},{lbl:'Semilla Lemon Haze',p:25,ch:2,sid:'limon'},{lbl:'Semilla OG Kush',p:30,ch:2,sid:'txoko'},
  {lbl:'Semilla Blueberry',p:40,ch:3,sid:'niebla'},{lbl:'Semilla Mango',p:35,ch:3,sid:'mango'},{lbl:'Semilla Purple Afghani',p:50,ch:4,sid:'purpura'},
  {lbl:'Fertilizante',p:15,ch:1,item:'fert',desc:'Una dosis por planta: +25% de cosecha.'},
  {lbl:'Insecticida',p:20,ch:1,item:'insect',desc:'Elimina una plaga de araña roja.'},
  {lbl:'Bocata',p:6,ch:1,item:'bocata',desc:'Recupera 15 de vida. En combate o desde la mochila.'},
  {lbl:'Spray de pimienta',p:25,ch:2,item:'spray',desc:'En combate: 12-16 de daño seguro a un ladrón.'},
  {lbl:'Maceta de tela 11 L',p:20,ch:1,maceta:'tela11'},{lbl:'Maceta de plástico 18 L',p:30,ch:2,maceta:'plastico18'},{lbl:'Maceta de tela 25 L',p:45,ch:3,maceta:'tela25'},
  {lbl:'Foco sodio 250 W',p:120,ch:2,foco:'sodio250'},{lbl:'Foco LED 200 W',p:260,ch:2,foco:'led200'},
  {lbl:'Foco sodio 400 W',p:220,ch:3,foco:'sodio400'},{lbl:'Foco LED 480 W',p:600,ch:3,foco:'led480'},
  {lbl:'Foco sodio 600 W',p:350,ch:4,foco:'sodio600'},{lbl:'Foco LED 720 W',p:1000,ch:5,foco:'led720'},
  {lbl:'Carpa 100×100',p:450,ch:2,carpa:'m100',desc:'Segunda carpa para el piso: 4 plantas, focos de hasta 480 W y macetas de hasta 25 L. Trae un CFL y macetas de 7 L.',cond:()=>!S.carpas[1]},
  {lbl:'Carpa 150×100',p:900,ch:4,carpa:'g150',desc:'Cambia tu carpa de 100 por una de 150: 6 plantas y focos de hasta 720 W. Tus plantas, foco y macetas se quedan.',cond:()=>S.carpas[1]&&S.carpas[1].t==='m100'},
];
for(const it of SHOP){if(it.maceta)it.desc=descMaceta(it.maceta)+'\nSe cambia en una plaza vacía de la carpa.';if(it.foco)it.desc=descFoco(it.foco)+'\nAguanta en carpas de '+(FOCOS[it.foco].w<=250?'60, 100 y 150':FOCOS[it.foco].w<=480?'100 y 150':'150')+'.';}
// carpa comprada (o ampliada): plazas nuevas al final, con maceta de 7 L; la casa se vuelve a montar al entrar
function comprarCarpa(t){
  if(t==='m100')S.carpas[1]={t,foco:'cfl'};else S.carpas[1].t=t;
  const n=huecos().length;while(S.pots.length<n)S.pots.push(null);while(S.macetas.length<n)S.macetas.push('plastico7');
}
async function shop(){
  let i=0;
  for(;;){
    const list=SHOP.filter(it=>S.ch>=it.ch&&(!it.cond||it.cond()));
    const IC={fert:'abono',insect:'insecticida',spray:'spray',bocata:'bocadillo'};
    const items=list.map(it=>({label:it.lbl,right:eur(it.p),sw:it.sid?STRAINS[it.sid].c:null,ic:it.sid?icono('semillas'):it.item?icono(IC[it.item]):it.maceta?icono('maceta'):it.foco?icono('lampara'):null,desc:it.sid?strainLine(it.sid):it.desc}));
    items.push({label:'Salir',desc:'Volver al mostrador.'});
    i=await menu(items,{cls:'full',title:'GROWSHOP KIKO',title2:'Tienes '+eur(S.money),desc:true,initial:i});
    if(i<0||i>=list.length)break;
    const it=list[i];
    if(S.money<it.p){sfx('bad');await say('No te llega el dinero.','KIKO');continue;}
    S.money-=it.p;sfx('coin');
    if(it.sid)addSeeds(it.sid,1);if(it.item)S.items[it.item]++;if(it.maceta)S.items['m_'+it.maceta]++;
    if(!it.sid&&!it.foco&&!it.carpa)toast('Comprado: '+it.lbl,1200);
    if(it.carpa){comprarCarpa(it.carpa);await say(it.carpa==='m100'?'Te la monto esta tarde en el piso, al lado del armario de tu tía. Viene con un CFL; si quieres más luz, aquí tienes focos.':'Me llevo la de 100 y te monto la de 150 en su sitio. Las plantas ni se enteran.','KIKO');}
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
  const t=[['Riega cuando el agua baje del 30 %. Una planta seca enferma.','El fertilizante se echa una vez por planta. Merece la pena.','Las plantas crecen mientras duermes. No hace falta mirarlas cada hora.'],
    ['Los clientes cambian cada día. No los hagas esperar.','Pedir caro funciona con turistas, con gente de dinero y con cogollo potente.','Si la presión policial (CALOR) sube mucho, deja de vender unos días.','Una carpa más grande es la mejor inversión que puedes hacer.','Las macetas de tela airean las raíces: más cosecha y menos plagas, pero hay que regar más.'],
    ['El LED cuesta más, pero rinde más y apenas da calor. El sodio es barato y seca las macetas.','Un foco pequeño en una carpa grande no llega a todas las plantas.','La luz se paga: cada carpa con plantas suma su factura cada día.','De noche, en el parque, roban. Lleva el spray de pimienta.'],
    RECIPE_HINTS.concat(['Las landraces no las vendo. Pregunta por el barrio: Txaro, Iñaki el del muelle... y mira bien en el parque.'])];
  return pick(t[Math.min(3,Math.max(0,S.ch-1))].concat(S.ch>3?t[1]:[]));
}
async function talkKiko(){
  const N='KIKO';
  if(!S.flags.kiko1){
    await talk(N,['{N}, pasa. Te pareces a tu tía.','Maite y yo cultivamos juntos desde que cerraron los astilleros. Ella tenía mano; yo, paciencia.','Para empezar, toma esto.']);
    addSeeds('ria',3);await got('3 semillas de SKUNK #1');S.items.fert+=2;await got('2 × FERTILIZANTE');
    await talk(N,['La Skunk #1 aguanta casi todo: errores de riego, plagas, frío. Es la mejor para aprender.','Planta en las macetas del armario de tu tía y riega cuando baje el agua.','El fertilizante da más cogollo. Si ves araña roja, insecticida: lo tengo aquí.','Cuando esté lista, cosecha. Guarda las semillas que salgan: siempre se poliniza alguna flor.','Las plantas siguen creciendo mientras duermes.']);
    S.flags.kiko1=true;showObjective();return;
  }
  if(S.ch===4&&!S.flags.lab){
    await talk(N,['Ya me han contado que has pagado a Baltasar. Bien hecho.','Te he montado en el piso mi equipo de polinización: pinceles, bolsas de papel y una lupa.']);
    S.flags.lab=true;await got('la MESA DE GENÉTICA');
    addSeeds('rif',3);await got('3 semillas de AFGHANI');
    await talk(N,['Me las trajo un amigo de Mazar-i-Sharif en los ochenta. Las he ido renovando desde entonces.','En la mesa polinizas una variedad con otra: gastas una semilla de cada y obtienes 2 del cruce.','Algunos cruces dan variedades conocidas. Otros, híbridos que solo tendrás tú.','Apúntalo todo en la GENOTECA. Las mejores genéticas salen de cruzar cruces.']);
    showObjective();await checkStory();return;
  }
  if(!Object.keys(S.seeds).length&&!S.pots.some(Boolean)&&!totalBuds()&&S.money<15){
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
  if(S.flags.txaro)return say(pick(['Ya duermo de un tirón. Gracias, de verdad.','Tu tía me ayudaba igual. No se lo contábamos a nadie.']),N);
  await talk(N,['Tú vives en el piso de Maite. Tu tía me ayudaba con... ya sabes.','Desde la quimio apenas duermo y no tengo hambre. Las pastillas no me hacen nada.','Me vendrían bien 5 gramos, para hacer aceite como me enseñó ella. ¿Me los das?']);
  const lots=budLots(5);if(!lots.length)return say('Cuando tengas 5 gramos, acuérdate de mí.',N);
  const i=await menu(lots.map(lotItem).concat([{label:'Ahora no'}]),{cls:'right',title:'¿Qué le das?'});
  if(i<0||i>=lots.length)return say('No pasa nada. Aquí estaré.',N);
  useBuds(lots[i][0],5);
  await say('Gracias. Toma: las trajo mi Paco de Pakistán en el setenta y seis. Nunca supe qué hacer con ellas.',N);
  addSeeds('hindu',2);await got('2 semillas de HINDU KUSH');S.items.bocata+=3;await say('Y llévate estos bocadillos, que comes poco.',N);await got('3 × BOCATA');S.flags.txaro=true;
}
async function talkInaki(){
  const N='IÑAKI';
  if(S.iDay===S.day)return say('Ya me has vendido hoy. Mañana más, que el barco sale temprano.',N);
  await say('Aupa. Me voy tres semanas a la mar. ¿Tienes 10 g para el viaje? Pago bien.',N);
  const lots=budLots(10);if(!lots.length)return say('Pues nada. Si consigues 10 g, aquí estaré.',N);
  const i=await menu(lots.map(lotItem).concat([{label:'Nada'}]),{cls:'right',title:'¿Qué le vendes?'});
  if(i<0||i>=lots.length)return;
  const [sid,b]=lots[i],amt=Math.round((3+b.thc*.4)*1.2*10);
  if(await ask(`Te doy ${amt} € por 10 g de ${getStrain(sid).n}. ¿Hecho?`,['Hecho','No'],N)!==0)return;
  useBuds(sid,10);S.money+=amt;S.sales+=amt;S.heat=Math.min(100,S.heat+3);S.iDay=S.day;S.rep+=2;sfx('coin');
  if(!S.flags.inaki){S.flags.inaki=true;await say('Toma. Me las dio un marinero de Malaui en Mombasa, en el último viaje.',N);addSeeds('malawi',2);await got('2 semillas de MALAWI GOLD');}
  else await say('Eskerrik asko. Hasta la vuelta.',N);
  await checkStory();
}
async function talkCop(){
  if(totalBuds()>0&&!S.protect){await say('¿Y ese olor? Quieto ahí.','AGENTE');await battle('police');return;}
  await say(pick(['Circule.','Todo tranquilo por aquí. Que siga así.','De noche hay robos en el parque. Tenga cuidado.']),'AGENTE');
}
async function talkDarko(){
  const N='DARKO';
  if(S.ch===6)return talk(N,['¿Vienes a la Copa? Mi AMNESIA HAZE dio un 26,8 % de THC en el laboratorio.','Nadie en Ribera ha pasado del 26. No vas a ser tú el primero.']);
  S.flags.darko1=true;
  await talk(N,['Así que tú te has quedado el piso de Maite.','Soy DARKO. La hierba de este barrio la muevo yo.','Vende lo tuyo si quieres, pero lejos de mis esquinas.','No me hagas repetirlo.']);
  await fade(1);buildEnts();await fade(0);
}
async function talkMolina(){
  const N='SARGENTO MOLINA';
  if(!S.flags.molina1){S.flags.molina1=true;await talk(N,['Así que eres tú quien vende en la plaza.','Podría detenerte ahora mismo. O podemos entendernos.','Por 500 € mis patrullas no pasan por tu calle. Y nada de registros en tu piso.']);}
  const c=await ask('¿Aceptas el trato del sargento?',['Pagar 500 €','No'],N);
  if(c===0){if(S.money<500)return say('¿Con qué dinero? Vuelve cuando lo tengas.',N);
    S.money-=500;S.protect=true;sfx('coin');await say('Bien. Mis agentes mirarán hacia otro lado.',N);await fade(1);buildEnts();await fade(0);}
  else{S.heat=Math.min(100,S.heat+10);await say('Tú sabrás. Mis agentes van a estar muy atentos.',N);heatWarn();}
}
async function talkJurado(){
  const N='JURADO';
  await talk(N,['Esto es la COPA DE RIBERA, la de la asociación cannábica del barrio.','Para competir, trae 20 g de una sola variedad. Se analizan en laboratorio.','Marca a batir: DARKO, con AMNESIA HAZE, 26,8 % de THC.']);
  const lots=budLots(20);if(!lots.length)return say('Vuelve cuando tengas 20 g de algo.',N);
  const i=await menu(lots.map(lotItem).concat([{label:'Todavía no'}]),{cls:'right',title:'¿Qué presentas?'});
  if(i<0||i>=lots.length)return;
  const [sid,b]=lots[i],thc=Math.round(b.thc*10)/10,name=getStrain(sid).n;useBuds(sid,20);
  await fade(1);await wait(500);await fade(0);
  await say('Resultado del laboratorio. AMNESIA HAZE de Darko: 26,8 % de THC.',N);
  await say(`${name} de {N}: ${pct(thc)} % de THC.`,N);
  if(thc>26.8){
    sfx('get');await say('Nueva marca. {N} gana la COPA DE RIBERA.',N);
    S.money+=2500;S.rep+=20;await got('2.500 € y el trofeo de la Copa');
    await talk('DARKO',['Esto no se acaba aquí.','Mi tío se va a enterar.']);
    S.flags.copa=true;await chapter(7);S.due=2000;S.deadline=S.day+7;showObjective();
  }else{sfx('bad');await say('Gana DARKO. La Copa sigue abierta: vuelve con algo más potente.',N);}
}
async function talkBaltasar(){
  const N='DON BALTASAR';
  if(S.ch<3)return say('¿Y tú quién eres? No tengo nada que hablar contigo.',N);
  if(S.ch===3&&!S.flags.metB){
    await talk(N,['Siéntate, {N}. Vamos al grano.','Tu tía Maite me debía 5.000 euros. Las deudas no se mueren con la gente.','Me los vas a pagar a plazos. El primero, 1.000 €.','Tienes siete días. Si no, Toño te hará una visita. Y Toño cobra intereses.']);
    S.flags.metB=true;S.due=1000;S.deadline=S.day+7;showObjective();return;
  }
  if(S.ch>=8)return say('Ya no me debes nada. Que te vaya bien, {N}.',N);
  if(S.ch===4)return say('Tranquilo. Ya te avisaré cuando toque el siguiente pago.',N);
  if(S.ch===6)return say('Primero, la Copa. Darko te espera en la plaza.',N);
  const left=S.deadline-S.day;
  await say(`Me debes ${eur(S.due)} para el día ${S.deadline}. ${left>0?`Te quedan ${left} días.`:'Es HOY.'}`,N);
  if(S.money<S.due)return say('Vuelve cuando tengas el dinero.',N);
  if(await ask('¿Pagar ahora?',['Pagar','Todavía no'],N)!==0)return;
  S.money-=S.due;S.debt-=S.due;const paid=S.due;S.due=0;sfx('coin');toast(`Pagado: ${eur(paid)}`,1500);
  if(S.ch===3){
    await talk(N,['Puntual. Así me gusta.','Quedan 4.000. Ya te avisaré del siguiente plazo.']);
    await chapter(4);await talk('SMS · KIKO',['Pásate por el growshop. Tengo algo para ti.']);showObjective();
  }else if(S.ch===5){
    await talk(N,['Me sorprendes, {N}.','Quedan 2.000. Te propongo algo.','El sábado es la COPA DE RIBERA. Premio: 2.500 €.','Mi sobrino Darko compite. No ha perdido nunca.','Gana la Copa y págame con el premio. Si puedes.']);
    await chapter(6);showObjective();
  }else if(S.ch===7){
    await talk(N,['Dos mil. Contados.','Deuda saldada. Lo de tu tía queda cerrado.','Una cosa más, {N}: si algún día quieres trabajar para mí, ya sabes dónde estoy.']);
    S.ch=8;S.debt=0;await ending();
  }
}
async function chapter(n){S.ch=n;sfx('get');toast(`<small>CAPÍTULO ${n}</small>${CH_TITLES[n]}`,2800);buildEnts();await wait(400);save();}
function objectiveText(){
  switch(S.ch){
    case 1:return !S.flags.letter?'Lee la carta que hay en la mesa.':!S.flags.kiko1?'Visita el growshop de Kiko, al lado de casa.':'Planta y consigue tu primera cosecha.';
    case 2:return `Gana 300 € vendiendo en la calle (${Math.min(300,Math.round(S.sales))}/300).`;
    case 3:return !S.flags.metB?'Ve al bar El Ancla.':`Paga ${eur(S.due)} a Don Baltasar antes del día ${S.deadline}.`;
    case 4:return !S.flags.lab?'Kiko quiere verte en el growshop.':`Descubre 8 variedades (${discCount()}/8).`;
    case 5:return `Paga ${eur(S.due)} a Don Baltasar antes del día ${S.deadline}.`;
    case 6:return 'Gana la Copa: 20 g con más de 26,8% de THC al jurado de la plaza.';
    case 7:return `Paga los últimos ${eur(S.due)} a Don Baltasar antes del día ${S.deadline}.`;
    default:return `Juego libre: completa la Genoteca (${DEX.filter(k=>S.disc[k]).length}/${DEX.length}).`;
  }
}
function showObjective(){toast(`<small>OBJETIVO</small>${esc(objectiveText())}`,3200);}
async function checkStory(){
  if(S.ch===1&&S.flags.harvest1){
    await chapter(2);spawnClients();
    await talk('SMS · KIKO',['Primera cosecha. Bien hecho.','La gente que busca material lleva un $ encima. Puedes venderles en la calle.','Cuanto más vendas, más se fijará la policía: es el CALOR. Y de noche hay quien roba.']);showObjective();
  }
  if(S.ch===2&&S.sales>=300){
    await chapter(3);
    await say('Un hombre enorme en chándal te corta el paso.');
    await talk('TOÑO',['Tú vives en el piso de Maite, ¿no?','Don Baltasar quiere verte. En el bar El Ancla. Hoy.','No me hagas venir a buscarte.']);showObjective();
  }
  if(S.ch===4&&S.flags.lab&&discCount()>=8){
    await chapter(5);S.due=2000;S.deadline=S.day+10;
    await talk('SMS · TOÑO',['Don Baltasar quiere 2.000 € en diez días.','Otra cosa: un tal SARGENTO MOLINA pregunta por ti en la plaza.']);showObjective();
  }
}
async function penaltyEvent(){
  await say('TOÑO te estaba esperando.');
  await talk('TOÑO',['Don Baltasar dice que llegas tarde.','Son 300 € más de intereses. Y esto, para que no se te olvide.']);
  sfx('hurt');S.hp=Math.max(1,S.hp-15);S.due+=300;S.debt+=300;S.deadline=S.day+5;
  await say(`La deuda del plazo sube a ${eur(S.due)}. Nuevo límite: día ${S.deadline}.`);
}
async function raidEvent(){
  if(S.protect){S.heat=50;return talk('SMS · MOLINA',['Esta noche había orden de entrada en tu piso. La he parado.','Baja el ritmo.']);}
  sfx('bad');await say('REDADA. La policía entra en tu piso.');
  const g=Math.floor(totalBuds()),fine=Math.min(S.money,300);
  S.pots=S.pots.map(()=>null);S.buds={};S.heat=30;S.money-=fine;
  await say(`Se llevan todas las plantas y ${g} g. Multa: ${eur(fine)}.`);
  await say('Toca empezar de nuevo. Y vender menos una temporada.');
}
async function ending(){
  await fade(1);const e=$('endcard');
  e.innerHTML=`<h2>FIN</h2><div>Has saldado la deuda de tu tía Maite en ${S.day} días.</div><div>Variedades: ${discCount()} · Ventas totales: ${eur(S.sales)}</div><div>El barrio sigue. ¿Completarás la GENOTECA?<br>¿Conseguirás la GHOST TRAIN HAZE?</div><div style="opacity:.7">Pulsa A</div>`;
  e.hidden=false;await fade(0);sfx('get');
  await new Promise(r=>push(b=>{if(b==='A'||b==='START'){pop();r();}}));
  await fade(1);e.hidden=true;await fade(0);save();showObjective();
}


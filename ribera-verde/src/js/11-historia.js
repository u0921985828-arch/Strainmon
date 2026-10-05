/* =========================================================
   PERSONAJES Y GUION
   ========================================================= */
const SHOP=[
  {lbl:'Semilla Ría Skunk',p:15,ch:1,sid:'ria'},{lbl:'Semilla Limón Haze',p:25,ch:2,sid:'limon'},{lbl:'Semilla Txoko Kush',p:30,ch:2,sid:'txoko'},
  {lbl:'Semilla Niebla Blue',p:40,ch:3,sid:'niebla'},{lbl:'Semilla Mango Rompeolas',p:35,ch:3,sid:'mango'},{lbl:'Semilla Púrpura Monte',p:50,ch:4,sid:'purpura'},
  {lbl:'Fertilizante',p:15,ch:1,item:'fert',desc:'Una dosis por planta: +25% de cosecha.'},
  {lbl:'Insecticida',p:20,ch:1,item:'insect',desc:'Elimina una plaga de araña roja.'},
  {lbl:'Bocata',p:6,ch:1,item:'bocata',desc:'Recupera 15 de vida. En combate o desde la mochila.'},
  {lbl:'Spray de pimienta',p:25,ch:2,item:'spray',desc:'En combate: 12-16 de daño seguro a un ladrón.'},
  {lbl:'Maceta extra',p:150,ch:2,pot:1,desc:'Una maceta más en el armario (máximo 6).',cond:()=>S.potsOwned<6},
  {lbl:'Lámpara LED',p:500,ch:3,led:1,desc:'+30% de cosecha y algo más de THC. Para siempre.',cond:()=>!S.led},
];
async function shop(){
  let i=0;
  for(;;){
    const list=SHOP.filter(it=>S.ch>=it.ch&&(!it.cond||it.cond()));
    const items=list.map(it=>({label:it.lbl,right:eur(it.p),sw:it.sid?STRAINS[it.sid].c:null,desc:it.sid?strainLine(it.sid):it.desc}));
    items.push({label:'Salir',desc:'Volver al mostrador.'});
    i=await menu(items,{cls:'full',title:'GROWSHOP KIKO',title2:'Tienes '+eur(S.money),desc:true,initial:i});
    if(i<0||i>=list.length)break;
    const it=list[i];
    if(S.money<it.p){sfx('bad');await say('No te llega, colega.','KIKO');continue;}
    S.money-=it.p;sfx('coin');
    if(it.sid)addSeeds(it.sid,1);if(it.item)S.items[it.item]++;if(it.pot)S.potsOwned++;if(it.led)S.led=true;
    if(!it.sid)toast('Comprado: '+it.lbl,1200);
    await checkStory();
  }
  await say('¡Buenos humos!','KIKO');
}
const RECIPE_HINTS=['Ría Skunk con Limón Haze da un cítrico de los buenos.','Un Txoko Kush con Niebla Blue sale azul como la ría en invierno.','Lo del Rif con el Txoko... eso sí que pega fuerte.','Púrpura Monte y Hindú Valle: morado de reyes.','Acapulco Oro con Mango: oro tropical, chaval.','Niebla Blue y Púrpura Monte: una niebla morada.','Limón Haze con Malawi Sol: el sol metido en un cogollo.','Si cruzas las de segunda generación entre ellas, salen cosas que no vienen ni en los libros.','La LEYENDA DE LA RÍA nace de una tormenta y un dragón. O eso cuentan.'];
function kikoTip(){
  const t=[['Riega cuando el agua baje del 30%. Sin agua, la planta enferma.','El FERTILIZANTE solo se echa una vez por planta, pero merece la pena.','Duerme para que pase el tiempo. Las plantas crecen igual.'],
    ['Los clientes con $ cambian cada día. No los hagas esperar.','Pedir CARO funciona mejor con turistas, pijos y cogollos potentes.','Si el CALOR policial se dispara, deja de vender un par de días.','Una maceta extra es la mejor inversión que puedes hacer.'],
    ['La LÁMPARA LED sube la cosecha un 30% y el THC un poco.','Lleva SPRAY DE PIMIENTA. De noche, en el parque, lo agradecerás.'],
    RECIPE_HINTS.concat(['Las landraces no las vendo yo. Pregunta por el barrio: la abuela Txaro, el marinero Iñaki, los arbustos del parque...'])];
  return pick(t[Math.min(3,Math.max(0,S.ch-1))].concat(S.ch>3?t[1]:[]));
}
async function talkKiko(){
  const N='KIKO';
  if(!S.flags.kiko1){
    await talk(N,['¡{N}! Pasa, pasa. Te pareces a tu tía, ¿eh? Misma cara de liarla.','Maite y yo cultivábamos juntos cuando esto era un barrio de astilleros.','Para empezar, toma esto.']);
    addSeeds('ria',3);await got('3 semillas de RÍA SKUNK');S.items.fert+=2;await got('2 × FERTILIZANTE');
    await talk(N,['La Ría Skunk es dura como una piedra del muelle. Perfecta para aprender.','Planta en las macetas del armario de tu piso y riega cuando baje el agua.','El abono da más cogollos. Si ves bichos rojos, INSECTICIDA: aquí lo vendo.','Cuando esté lista, cosecha. Siempre caen semillas para repetir.','Y si te aburres de esperar, duerme. Las plantas crecen igual.']);
    S.flags.kiko1=true;showObjective();return;
  }
  if(S.ch===4&&!S.flags.lab){
    await talk(N,['¡Ahí estás! Me han dicho que has pagado a Baltasar. Tienes madera.','Te he montado mi viejo KIT DE POLINIZACIÓN en la mesa de tu piso.']);
    S.flags.lab=true;await got('la MESA DE GENÉTICA');
    addSeeds('rif',3);await got('3 semillas de ATLAS RIF');
    await talk(N,['Las traje de las montañas del Rif hace años. Resistentes como ellas solas.','En la mesa cruzas dos variedades: gastas una semilla de cada y salen 2 de la nueva.','Algunas mezclas dan variedades únicas. Otras, híbridos tuyos y de nadie más.','Ve llenando tu GENOTECA. Las mejores genéticas salen de cruzar cruces.']);
    showObjective();await checkStory();return;
  }
  if(!Object.keys(S.seeds).length&&!S.pots.some(Boolean)&&!totalBuds()&&S.money<15){
    await say('¿Sin semillas y sin un duro? Anda, toma, que te veo tieso.',N);addSeeds('ria',2);await got('2 semillas de RÍA SKUNK');
  }
  const c=await ask('¿Qué necesitas?',['Comprar','Un consejo','Nada'],N);
  if(c===0)await shop();else if(c===1)await say(kikoTip(),N);else await say('¡Buenos humos!',N);
}
async function talkJosune(){
  const N='JOSUNE';
  const c=await ask('¡Kaixo! ¿Qué te pongo?',['Pintxo · 4 €','Kalimotxo · 3 €','¿Algún rumor?','Nada'],N);
  if(c===0||c===1){const cost=c?3:4,hp=c?6:12;if(S.money<cost)return say('Aquí no se fía, cariño.',N);
    S.money-=cost;S.hp=Math.min(S.hpMax,S.hp+hp);sfx('coin');return say(c?'Kalimotxo fresquito. Recuperas algo de vida.':'Tortilla poco hecha, como debe ser. Recuperas vida.',N);}
  if(c===2)return say(pick(['Dicen que alguien escondió cosas en los arbustos del parque.','Iñaki, el del muelle, trae cosas raras de sus viajes.','La abuela Txaro guarda un bote de semillas de la India.','Darko es sobrino de Don Baltasar. Por eso va tan chulo.','El sargento Molina cobra por mirar hacia otro lado. Todo el barrio lo sabe.']),N);
}
async function talkPatxi(){S.patxi=(S.patxi||0)+1;await say(S.ch<4?'Cuando tengas una mesa de genética, ven a verme. Sé un par de cosas de cruces.':'Mi abuelo decía: '+RECIPE_HINTS[S.patxi%RECIPE_HINTS.length],'PATXI');}
async function talkTxaro(){
  const N='ABUELA TXARO';
  if(S.flags.txaro)return say(pick(['Las magdalenas me salieron de cine. Las de la petanca no paraban de reír.','Tu tía y yo íbamos a bailar a la plaza. ¡Qué tiempos!']),N);
  await talk(N,['Ay, el de Maite. ¡Qué mayor estás!','Oye, para mis magdalenas especiales necesito 5 gramos de lo tuyo. ¿Me los das?']);
  const lots=budLots(5);if(!lots.length)return say('Cuando tengas 5 gramos, acuérdate de esta vieja.',N);
  const i=await menu(lots.map(lotItem).concat([{label:'Ahora no'}]),{cls:'right',title:'¿Qué le das?'});
  if(i<0||i>=lots.length)return say('Bueno, bueno. Aquí estaré.',N);
  useBuds(lots[i][0],5);
  await say('¡Ay, qué rico huele! Toma, esto me lo trajo mi Paco de la India.',N);
  addSeeds('hindu',2);await got('2 semillas de HINDÚ VALLE');S.items.bocata+=3;await got('3 × BOCATA');S.flags.txaro=true;
}
async function talkInaki(){
  const N='IÑAKI';
  if(S.iDay===S.day)return say('Ya me has vendido hoy. Mañana más, que el barco sale temprano.',N);
  await say('Aupa. Me paso tres semanas en alta mar. ¿Tienes 10 g para el viaje? Pago bien.',N);
  const lots=budLots(10);if(!lots.length)return say('Pues nada. Si consigues 10 g, aquí estaré.',N);
  const i=await menu(lots.map(lotItem).concat([{label:'Nada'}]),{cls:'right',title:'¿Qué le vendes?'});
  if(i<0||i>=lots.length)return;
  const [sid,b]=lots[i],amt=Math.round((3+b.thc*.4)*1.2*10);
  if(await ask(`Te doy ${amt} € por 10 g de ${getStrain(sid).n}. ¿Hecho?`,['Hecho','No'],N)!==0)return;
  useBuds(sid,10);S.money+=amt;S.sales+=amt;S.heat=Math.min(100,S.heat+3);S.iDay=S.day;S.rep+=2;sfx('coin');
  if(!S.flags.inaki){S.flags.inaki=true;await say('¡Eso es! Toma, un regalo de mi último viaje a Mombasa.',N);addSeeds('malawi',2);await got('2 semillas de MALAWI SOL');}
  else await say('Eskerrik asko. ¡Buen viento!',N);
  await checkStory();
}
async function talkCop(){
  if(totalBuds()>0&&!S.protect){await say('¿Y ese olor? Quieto ahí.','AGENTE');await battle('police');return;}
  await say(pick(['Circule, circule.','Todo tranquilo por aquí. Que siga así.','Ojo con los chorizos de noche, que hay mucho listo.']),'AGENTE');
}
async function talkDarko(){
  const N='DARKO';
  if(S.ch===6)return talk(N,['¿Vienes a la Copa? Mi TORMENTA FINAL da un 26,8% de THC.','Nadie en Ribera ha pasado del 26. Y tú no vas a ser el primero.']);
  S.flags.darko1=true;
  await talk(N,['Así que tú eres quien ha heredado el piso de la vieja Maite.','Soy DARKO. Este barrio tiene dueño, y lo tienes delante.','Mis plantas tienen más THC que tu vida entera.','Vende tus hierbajos mientras puedas, novato.']);
  await fade(1);buildEnts();await fade(0);
}
async function talkMolina(){
  const N='SARGENTO MOLINA';
  if(!S.flags.molina1){S.flags.molina1=true;await talk(N,['Vaya, vaya. La nueva estrella del menudeo de Ribera Verde.','Podría detenerte ahora mismo... o podríamos ser amigos.','Por 500 € te garantizo protección: menos controles y ninguna redada.']);}
  const c=await ask('¿Aceptas el trato del sargento?',['Pagar 500 €','No'],N);
  if(c===0){if(S.money<500)return say('¿Con qué dinero? Vuelve cuando lo tengas.',N);
    S.money-=500;S.protect=true;sfx('coin');await say('Un placer. Mis chicos mirarán hacia otro lado.',N);await fade(1);buildEnts();await fade(0);}
  else{S.heat=Math.min(100,S.heat+10);await say('Tú verás. Mis chicos estarán MUY atentos.',N);heatWarn();}
}
async function talkJurado(){
  const N='JURADO';
  await talk(N,['Bienvenido a la COPA DE RIBERA.','Para competir, trae 20 g de una sola variedad.','Récord a batir: DARKO, con TORMENTA FINAL, 26,8% de THC.']);
  const lots=budLots(20);if(!lots.length)return say('Vuelve cuando tengas 20 g de algo.',N);
  const i=await menu(lots.map(lotItem).concat([{label:'Todavía no'}]),{cls:'right',title:'¿Qué presentas?'});
  if(i<0||i>=lots.length)return;
  const [sid,b]=lots[i],thc=Math.round(b.thc*10)/10,name=getStrain(sid).n;useBuds(sid,20);
  await fade(1);await wait(500);await fade(0);
  await say('El jurado prueba la TORMENTA FINAL de Darko... 26,8% de THC.',N);
  await say(`Ahora, ${name} de {N}... ¡${pct(thc)}% de THC!`,N);
  if(thc>26.8){
    sfx('get');await say('¡¡NUEVO CAMPEÓN!! ¡{N} gana la COPA DE RIBERA!',N);
    S.money+=2500;S.rep+=20;await got('2.500 € y el trofeo de la Copa');
    await talk('DARKO',['No... no puede ser.','¡Tío Baltasar se va a enterar de esto!']);
    S.flags.copa=true;await chapter(7);S.due=2000;S.deadline=S.day+7;showObjective();
  }else{sfx('bad');await say('Gana DARKO. Vuelve con algo más potente: la Copa sigue abierta.',N);}
}
async function talkBaltasar(){
  const N='DON BALTASAR';
  if(S.ch<3)return say('¿Y tú quién eres? Lárgate, estoy ocupado.',N);
  if(S.ch===3&&!S.flags.metB){
    await talk(N,['Siéntate, {N}. ¿Un kalimotxo? No, mejor no.','Tu tía Maite me debía 5.000 euros. Las deudas no se mueren con la gente.','Me los vas a pagar a plazos. Primero, 1.000 €.','Tienes 7 días. Si no, Toño se pone nervioso. Y cuando Toño se pone nervioso, cobra intereses.']);
    S.flags.metB=true;S.due=1000;S.deadline=S.day+7;showObjective();return;
  }
  if(S.ch>=8)return say('Ya no me debes nada. ¿Un café? Invita la casa... esta vez.',N);
  if(S.ch===4)return say('Tranquilo. Ya te avisaré cuando toque el siguiente pago.',N);
  if(S.ch===6)return say('Primero, la Copa. Darko te espera en la plaza.',N);
  const left=S.deadline-S.day;
  await say(`Me debes ${eur(S.due)} para el día ${S.deadline}. ${left>0?`Te quedan ${left} días.`:'Es HOY.'}`,N);
  if(S.money<S.due)return say('Vuelve cuando tengas la pasta.',N);
  if(await ask('¿Pagar ahora?',['Pagar','Todavía no'],N)!==0)return;
  S.money-=S.due;S.debt-=S.due;const paid=S.due;S.due=0;sfx('coin');toast(`Pagado: ${eur(paid)}`,1500);
  if(S.ch===3){
    await talk(N,['Puntual. Me gusta.','Quedan 4.000. Ya te avisaré del siguiente plazo.']);
    await chapter(4);await talk('SMS · KIKO',['Pásate por el growshop. Tengo algo para ti.']);showObjective();
  }else if(S.ch===5){
    await talk(N,['Me sorprendes, {N}.','Quedan 2.000. Te propongo algo.','Este sábado se celebra la COPA DE RIBERA. El premio: 2.500 €.','Mi sobrino Darko compite. Nunca ha perdido.','Gana la Copa y págame con el premio. Si puedes.']);
    await chapter(6);showObjective();
  }else if(S.ch===7){
    await talk(N,['Dos mil. Contados.','Deuda saldada. Maite estaría orgullosa... o no, quién sabe.','Una última cosa, {N}: Darko necesita un maestro. Piénsalo.']);
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
    await talk('SMS · KIKO',['¡Primera cosecha! Bien hecho.','La gente con un $ encima busca material. Véndeles en la calle.','Ojo: cuanto más vendas, más CALOR policial. Y de noche salen los chorizos.']);showObjective();
  }
  if(S.ch===2&&S.sales>=300){
    await chapter(3);
    await say('Un tipo enorme en chándal te corta el paso...');
    await talk('TOÑO',['Tú eres lo de Maite, ¿no?','Don Baltasar quiere verte. En el bar El Ancla. Hoy.','Y no me hagas venir a buscarte.']);showObjective();
  }
  if(S.ch===4&&S.flags.lab&&discCount()>=8){
    await chapter(5);S.due=2000;S.deadline=S.day+10;
    await talk('SMS · TOÑO',['Don Baltasar quiere 2.000 € en 10 días. No es una pregunta.','Por cierto: un tal SARGENTO MOLINA pregunta por ti en la plaza.']);showObjective();
  }
}
async function penaltyEvent(){
  await say('Llaman a la puerta... o te paran en la calle. Da igual: es TOÑO.');
  await talk('TOÑO',['Don Baltasar dice que llegas tarde.','Te pongo 300 € de intereses. Y esto, de regalo.']);
  sfx('hurt');S.hp=Math.max(1,S.hp-15);S.due+=300;S.debt+=300;S.deadline=S.day+5;
  await say(`La deuda del plazo sube a ${eur(S.due)}. Nuevo límite: día ${S.deadline}.`);
}
async function raidEvent(){
  if(S.protect){S.heat=50;return talk('SMS · MOLINA',['Esta noche iba a haber redada en tu casa. La he parado.','De nada. Y baja el ritmo.']);}
  sfx('bad');await say('¡REDADA! La policía entra en tu piso...');
  const g=Math.floor(totalBuds()),fine=Math.min(S.money,300);
  S.pots=S.pots.map(()=>null);S.buds={};S.heat=30;S.money-=fine;
  await say(`Se llevan todas las plantas y ${g} g. Multa: ${eur(fine)}.`);
  await say('Toca empezar de nuevo. Y bajar el CALOR.');
}
async function ending(){
  await fade(1);const e=$('endcard');
  e.innerHTML=`<h2>FIN</h2><div>Has saldado la deuda de la tía Maite en ${S.day} días.</div><div>Variedades: ${discCount()} · Ventas totales: ${eur(S.sales)}</div><div>El barrio sigue. ¿Completarás la GENOTECA?<br>¿Encontrarás la LEYENDA DE LA RÍA?</div><div style="opacity:.7">Pulsa A</div>`;
  e.hidden=false;await fade(0);sfx('get');
  await new Promise(r=>push(b=>{if(b==='A'||b==='START'){pop();r();}}));
  await fade(1);e.hidden=true;await fade(0);save();showObjective();
}


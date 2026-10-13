/* =========================================================
   LA COMARCA CON FUNCIÓN (1.14): en cada sitio, algo que hacer
   ========================================================= */
// Ibarbide: GROW IBARBIDE (TIENDAS.ane, 11-historia). Puerto Viejo: la lonja (NEREA), al por mayor a un 15 % más que Iñaki, hasta
// 500 g y cada 3 días. Valdehierro: la chatarrería del solar (BIXENTE), 3 piezas de segunda mano al día a mitad de precio.
// Errotabarri: el molino (ANDONI), 20 g de cogollo por 3 semillas de una landrace del banco que aún no tengas, una vez por semana
const LONJA={f:1.15,g:500,dias:3,ch:3};
const CHATARRA={n:3,f:.5,ch:2,piezas:['Foco sodio 250 W','Foco sodio 400 W','Foco sodio 600 W','Foco LED 100 W','Foco LED 200 W','Extractor 100 mm con filtro',
  'Extractor 125 mm con filtro','Intractor 100 mm','Ventilador de pinza','Calefactor','Humidificador']};
const TRUEQUE={g:20,n:3,dias:7,ch:3};
async function talkAne(){
  const N='ANE';
  await say(S.flags.ane?'¿Qué te hace falta hoy?':'Kaixo. Esto es GROW IBARBIDE: el equipo, un 10 % más barato que en el barrio, y lo nuevo antes que nadie.',N);
  S.flags.ane=true;await shop(TIENDAS.ane);
}
// las 3 piezas del día: las mismas para todos (hashT del día), sin repetir
function chatarraDia(){const l=CHATARRA.piezas.slice(),r=[];for(let i=0;i<CHATARRA.n;i++)r.push(l.splice(hashT(S.day,i+7)%l.length,1)[0]);return r;}
async function talkBixente(){
  const N='BIXENTE';
  if(S.ch<CHATARRA.ch)return say('Compro chatarra y vendo lo que se puede aprovechar. Vuelve cuando cultives en serio.',N);
  let i=0;
  for(;;){
    const ya=S.chatarra&&S.chatarra.d===S.day?S.chatarra.v:[],l=chatarraDia().filter(lbl=>!ya.includes(lbl)).map(lbl=>SHOP.find(it=>it.lbl===lbl)).filter(it=>it&&S.ch>=it.ch&&(!it.cond||it.cond()));   // solo lo de su capítulo
    if(!l.length)return say('Hoy no me queda nada que te sirva. Mañana entra más.',N);
    const items=l.map(it=>({label:it.lbl,right:eur(precioT({f:CHATARRA.f},it)),desc:(it.desc||'')+'\nDe segunda mano: funciona, pero sin garantía.'}));
    items.push({label:'Nada',desc:'Cada día entran tres piezas.'});
    i=await menu(items,{cls:'full',title:'CHATARRERÍA DEL SOLAR',title2:'Tienes '+eur(S.money),desc:true,initial:i});
    if(i<0||i>=l.length)return say('Lo que entra, sale. Si lo quieres, no tardes.',N);
    const it=l[i],p=precioT({f:CHATARRA.f},it);
    if(S.money<p){sfx('bad');await say('Sin dinero no hay trato.',N);continue;}
    S.money-=p;sfx('coin');if(!S.chatarra||S.chatarra.d!==S.day)S.chatarra={d:S.day,v:[]};S.chatarra.v.push(it.lbl);
    await entregar(it,N);await checkStory();
  }
}
async function talkNerea(){
  const N='NEREA',L=LONJA;
  if(S.ch<L.ch)return say('De madrugada se subasta el pescado. Lo otro, cuando te conozca más gente.',N);
  if(S.lonja&&S.day<S.lonja+L.dias)return say(`Los barcos de fuera vuelven el día ${S.lonja+L.dias}. Tráelo entonces.`,N);
  const lots=budLots(100);
  if(!lots.length)return say(`Cargo para los barcos de fuera: de 100 a ${L.g} g, un ${Math.round((L.f-1)*100)} % por encima de lo que paga Iñaki. Cada ${L.dias} días.`,N);
  const i=await menu(lots.map(lotItem).concat([{label:'Nada'}]),{cls:'right',title:'¿Qué lote?'});
  if(i<0||i>=lots.length)return say('Otro día.',N);
  const [k,b]=lots[i],pg=Math.round(precioMayor(b.thc)*L.f*100)/100,tope=Math.min(Math.floor(b.g),L.g);
  const ops=[100,250].filter(g=>g<tope).concat([tope]);
  const j=await ask(`${lotNombre(k)} a ${coma(pg.toFixed(2))} € el gramo. ¿Cuánto cargas?`,ops.map(g=>`${kgTxt(g)} · ${eur(g*pg)}`).concat(['Nada']),N);
  if(j<0||j>=ops.length)return;
  const g=ops[j],e=Math.round(g*pg);
  useBuds(k,g);S.money+=e;S.sales+=e;S.lonja=S.day;S.heat=Math.min(100,S.heat+2+g/100);S.rep+=1;sfx('coin');
  await accion('vender',{id:'vfx-monedas',x:P.px+8,y:P.py+2});
  toast(`+${eur(e)} · ${kgTxt(g)} en la lonja`,1600);
  await say('Hecho. Sale con el pesquero de las cinco.',N);heatWarn();await checkStory();
}
// la landrace del trueque: la primera del banco (las de su capítulo) que no tienes en la Genoteca; si no, una según el día. 1.26: también
// las que no se venden (REGALO), ya descubiertas, y antes que nada una de esas de la que no te queden semillas: que no se pierdan
function landraceTrueque(){const r=Object.keys(REGALO).filter(k=>S.disc[k]&&/^Landrace/.test(STRAINS[k].o)),l=BANCO.filter(([,,ch])=>S.ch>=ch).map(b=>b[0]).concat(r);
  return l.find(k=>!S.disc[k])||r.find(k=>!S.seeds[k])||l[S.day%l.length];}
async function talkAndoni(){
  const N='ANDONI',T=TRUEQUE;
  if(S.ch<T.ch)return say('El molino muele los domingos. Si te interesan las semillas viejas, vuelve más adelante.',N);
  if(S.trueque&&S.day<S.trueque+T.dias)return say(`Hasta el día ${S.trueque+T.dias} no tengo más semillas para cambiar.`,N);
  const k=landraceTrueque();
  await say(`Mi abuelo guardaba semillas en botes de cristal, junto a la harina. Tengo de ${STRAINS[k].n}.`,N);
  const lots=budLots(T.g);if(!lots.length)return say(`Te doy ${T.n} por ${T.g} g de lo tuyo. Cuando los tengas, aquí estoy.`,N);
  const i=await menu(lots.map(lotItem).concat([{label:'Nada'}]),{cls:'right',title:`${T.n} semillas por ${T.g} g`});
  if(i<0||i>=lots.length)return say('Tú verás. El bote no se mueve de aquí.',N);
  useBuds(lots[i][0],T.g);addSeeds(k,T.n);S.trueque=S.day;
  await got(`${T.n} semillas de ${STRAINS[k].n.toUpperCase()}`);await say('Cuídalas. Ya no quedan muchas así.',N);
}
// Miren (1.17): la amiga de la tía Maite, en Errotabarri desde el capítulo MIREN.ch. Le llevas MIREN.g g de la variedad que
// cultivaban juntas (MIREN.sid) y te da la página que falta del diario (S.flags.pagina, PAGINA en 12-menus) y MIREN.n semillas;
// 1.25: y MIREN.n2 de la de Laos (MIREN.s2, que no está en el banco; S.flags.lao: las partidas de antes, al volver a hablarle)
const MIREN={ch:4,sid:'amanecer',g:20,s:'haze',n:5,s2:'lao',n2:3};
async function laoMiren(N){S.flags.lao=S.day;addSeeds(MIREN.s2,MIREN.n2);await say('Y esto también era de las dos. La de Laos: la guardábamos para la Amnesia.',N);
  return got(`${MIREN.n2} semillas de ${STRAINS[MIREN.s2].n.toUpperCase()}`);}
async function talkMiren(){
  const N='MIREN',M=MIREN,v=STRAINS[M.sid].n.toUpperCase();
  if(S.flags.pagina&&!S.flags.lao)return laoMiren(N);
  if(S.flags.pagina)return say(pick(['Tu tía subía cada otoño con un táper de cogollos y se quedaba a dormir.','Del caserío no me echó nadie gracias a ella. Eso no se olvida.','Cuando la Haze te salga sola, acuérdate de nosotras.']),N);
  if(!S.flags.miren){S.flags.miren=S.day;
    return talk(N,['¿Tú eres el de Maite? Tienes sus ojos.','Me llamo Miren. Tu tía y yo cultivábamos juntas en este caserío, hace treinta años.','Su diario tiene una página arrancada. Me la dio la última vez que subió.',`Tráeme ${M.g} g de ${v}, la que hacíamos las dos, y es tuya.`]);}
  const ks=Object.keys(S.buds).filter(k=>lotSid(k)===M.sid).sort((a,b)=>a.endsWith('*')-b.endsWith('*')),tot=ks.reduce((s,k)=>s+S.buds[k].g,0);   // primero lo que no es estrella
  if(tot<M.g)return say(`¿Me traes los ${M.g} g de ${v}? Sin prisa: aquí estoy.`,N);
  if(await ask(`¿Le das ${M.g} g de ${v}?`,['Dárselos','Todavía no'],N)!==0)return say('Cuando quieras.',N);
  let q=M.g;for(const k of ks){const t=Math.min(q,S.buds[k].g);useBuds(k,t);q-=t;if(q<=0)break;}
  S.flags.pagina=S.day;addSeeds(M.s,M.n);
  await talk(N,['Huele igual que entonces.','Toma. La página que falta, y unas semillas de su Haze.']);
  await got(`la última página del diario y ${M.n} semillas de ${STRAINS[M.s].n.toUpperCase()}`);
  await laoMiren(N);
  return say('Léela en casa, con calma.',N);
}

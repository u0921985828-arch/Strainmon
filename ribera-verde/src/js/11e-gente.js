/* =========================================================
   LA GENTE (1.15): confianza, trabajadores, clubs y la cata
   ========================================================= */
// Confianza (S.rel, 0-100) con cada persona con nombre: sube hablando (una vez al día), vendiendo a buen precio a los de la agenda,
// con regalos y favores; baja pidiendo caro o fallando. Con REL.amigo: Kiko hace un 5 %, Iñaki paga un 5 % más al por mayor y Begoña
// se deja contratar; un cliente de la agenda acepta mejor el precio (+confianza/250). Con REL.socio, uno de la agenda vende para ti
const REL={amigo:20,socio:50,max:100,charla:1,regalo:5,regaloG:2};
const rel=id=>(S.rel&&S.rel[id])||0;
function confia(id,d){S.rel[id]=clamp(Math.round(rel(id)+d),0,REL.max);}
const relNivel=id=>rel(id)>=REL.socio?'socio':rel(id)>=REL.amigo?'amigo':'conocido';
function saludo(id){if(S.relDia[id]===S.day)return;S.relDia[id]=S.day;confia(id,REL.charla);}   // al hablar con alguien, +1 el primer día
// Trabajadores (S.curro): Begoña, de jardinera (riega, rellena garrafas y depósito y trata las plagas con tu insecticida, por SUELDO
// cada mañana; sin dinero se va), y hasta CURRO.vend.max vendedores a comisión: un cliente de la agenda con REL.socio al que le dejas
// un lote; cada día vende de 5 a 15 g a precio de calle del barrio y te deja el 70 % en el buzón. Riesgo diario: que lo pille la
// policía (pierde lo que lleva y sube el calor) o que se largue con todo (menos cuanta más confianza; sale de la agenda)
const CURRO={jard:{sueldo:20,calor:.5,ch:3},vend:{com:.3,g:[5,15],calor:.5,pilla:.04,estafa:.1,calorPilla:10,max:2,lotes:[25,50,100]}};
function curroDia(){
  const C=S.curro,J=CURRO.jard,V=CURRO.vend;
  if(C.jard){
    if(S.money<J.sueldo){C.jard=null;confia('begona',-10);queue('jard',()=>talk('SMS · BEGOÑA',['Sin cobrar no vuelvo, majo. Cuando tengas el dinero, hablamos.']));}
    else{S.money-=J.sueldo;cuidarPlantas();S.heat=Math.min(100,S.heat+J.calor);}
  }
  const fin=[];let vende=false;
  for(const v of C.vend){
    const r=Math.random(),N='SMS · '+v.n.toUpperCase();
    if(r<V.pilla){fin.push(v);S.heat=Math.min(100,S.heat+V.calorPilla);confia(v.id,-5);queue('vend'+v.id,()=>talk(N,[`Me ha parado la policía. Se han quedado con ${gTxt(v.g)} de ${lotNombre(v.k)}. Lo siento.`]));continue;}
    if(r<V.pilla+V.estafa*(REL.max-rel(v.id))/REL.max){fin.push(v);S.fijos=S.fijos.filter(f=>f.id!==v.id);S.rel[v.id]=0;queue('vend'+v.id,()=>say(`${v.n} no contesta al móvil. Se ha largado con ${gTxt(v.g)} de ${lotNombre(v.k)}.`));continue;}
    const g=Math.min(Math.floor(v.g),ri(V.g[0],V.g[1])),e=Math.round(precioCalle(v.thc)*ZONAS.town.precio*g*(1-V.com));
    v.g-=g;S.money+=e;S.sales+=e;S.heat=Math.min(100,S.heat+V.calor);confia(v.id,1);vende=true;
    if(v.g<1){fin.push(v);queue('vend'+v.id,()=>talk(N,[`Vendidos los últimos ${g} g: ${eur(e)} en tu buzón. Si quieres que siga, déjame más.`]));}
    else queue('vend'+v.id,()=>talk(N,[`Vendidos ${g} g: ${eur(e)} en tu buzón. Me quedan ${gTxt(v.g)}.`]));
  }
  if(fin.length)C.vend=C.vend.filter(v=>!fin.includes(v));
  if(vende)queue('historia',checkStory);   // 1.22: lo vendido cuenta para la historia
  plantillaDia();   // la plantilla (1.19, 11f-plantilla)
}
// regar, tratar las plagas con tu insecticida y rellenar garrafas y depósitos (Begoña y el gerente de la plantilla)
function cuidarPlantas(){
  S.pots.forEach(p=>{if(!p||p.dead)return;p.water=100;if(p.pest&&S.items.insect>0){S.items.insect--;p.pest=false;}});
  S.carpas.forEach((c,ci)=>{if(!c)return;if(c.garrafas)delete c.gar;if(c.goteo)c.dep=goteoL(ci);});
}
// un cliente de la agenda, desde el móvil: que venga, un regalo (una vez al día), cómo va su venta o que venda para ti
async function fijoMenu(f){
  const v=S.curro.vend.find(v=>v.id===f.id),puede=rel(f.id)>=REL.socio&&S.curro.vend.length<CURRO.vend.max;
  const ops=['Que venga'].concat(totalBuds()>=REL.regaloG?[`Regalarle ${REL.regaloG} g`]:[],v?['Cómo va la venta']:puede?['Que venda para mí']:[],['Nada']);
  const op=ops[await ask(`${f.n} · ${CTYPES[f.t].label.toLowerCase()} · confianza ${rel(f.id)} (${relNivel(f.id)})`,ops)];
  if(op==='Que venga')return llamarFijo(f);
  if(op&&op.startsWith('Regalarle')){
    if(f.regalo===S.day){await say(`${f.n}: «¿Otra vez? Gracias, pero hoy ya me has invitado».`);return false;}
    const lots=budLots(REL.regaloG),i=await menu(lots.map(lotItem).concat([{label:'Nada'}]),{cls:'right',title:'¿Qué le regalas?'});if(i<0||i>=lots.length)return false;
    useBuds(lots[i][0],REL.regaloG);f.regalo=S.day;confia(f.id,REL.regalo);sfx('get');await say(`${f.n}: «¡Gracias! Se lo cuento a todo el mundo».`);return false;
  }
  if(op==='Cómo va la venta'){await say(`${f.n}: «Me quedan ${gTxt(v.g)} de ${lotNombre(v.k)}. Cada día vendo lo que puedo y te dejo el ${pct0(1-CURRO.vend.com)} % en el buzón».`);return false;}
  if(op==='Que venda para mí')return contratarVendedor(f);
  return false;
}
async function contratarVendedor(f){
  const V=CURRO.vend,lots=budLots(V.lotes[0]);
  if(!lots.length){await say(`${f.n}: «Cuando tengas ${V.lotes[0]} g o más, hablamos».`);return false;}
  const i=await menu(lots.map(lotItem).concat([{label:'Nada'}]),{cls:'right',title:'¿Qué lote le dejas?'});if(i<0||i>=lots.length)return false;
  const [k,b]=lots[i],ops=V.lotes.filter(g=>g<=Math.floor(b.g));
  const j=await ask(`${f.n} vende a precio de calle y se queda el ${pct0(V.com)} %. ¿Cuánto le dejas?`,ops.map(g=>g+' g').concat(['Nada']));if(j<0||j>=ops.length)return false;
  useBuds(k,ops[j]);S.curro.vend.push({id:f.id,n:f.n,k,thc:b.thc,g:ops[j],dia:S.day});sfx('sel');
  await say(`${f.n}: «Hecho. Cada día te dejo lo vendido en el buzón».`);return false;
}
// MÓVIL → GENTE: a quién conoces y cuánto se fía de ti
const GENTE={kiko:'Kiko',josune:'Josune',begona:'Begoña',patxi:'Patxi',txaro:'Txaro',inaki:'Iñaki',ane:'Ane',nerea:'Nerea',bixente:'Bixente',andoni:'Andoni',baltasar:'Don Baltasar',molina:'Sgto. Molina',darko:'Darko'};
const QUE_DA={kiko:`Con ${REL.amigo}: un 5 % menos en el growshop. Cada compra suma.`,inaki:`Con ${REL.amigo}: un 5 % más al por mayor. Cada venta suma.`,begona:`Con ${REL.amigo} (desde el cap. ${CURRO.jard.ch}): te cuida las plantas por ${CURRO.jard.sueldo} € al día.`,txaro:'Sus semillas, por sus favores.'};
async function gente(){
  const rows=[];
  for(const [id,n] of Object.entries(GENTE))if(S.rel[id]!=null)rows.push({label:n,right:`${rel(id)} · ${id==='begona'&&S.curro.jard?'jardinera':relNivel(id)}`,desc:QUE_DA[id]||'Hablar cada día suma confianza.'});
  for(const k in CLUBS)if(S.rel[k]!=null)rows.push({label:CLUBS[k].n,right:`${rel(k)} · ${relNivel(k)}`,desc:S.clubs[k]?'Eres socio. Vender y cumplir los encargos suma.':'Hazte socio para vender y comprar.'});
  for(const f of S.fijos){const v=S.curro.vend.find(v=>v.id===f.id);rows.push({label:f.n,right:`${rel(f.id)} · ${v?'vende para ti':relNivel(f.id)}`,desc:v?`Le dejaste ${lotNombre(v.k)}: le quedan ${gTxt(v.g)}.`:`Cliente de la agenda. Buen precio y regalos suman; con ${REL.socio} vende para ti.`});}
  if(!rows.length)return say('Todavía no conoces a nadie.');
  let i=0;do{i=await menu(rows,{cls:'full',title:'GENTE',title2:`${rows.length} persona${rows.length>1?'s':''}`,desc:true,initial:i});}while(i>=0);
}
// Begoña (la vecina): consejos, un regalo al día y, con confianza y desde el capítulo 3, la jardinera
const BEGONA_TIPS=['Bajo una lámpara las plantas beben mucho. Riégalas a diario, majo.','Si se te ponen amarillas las hojas de abajo, les falta agua o abono.','Tu tía siempre tenía el piso oliendo a limón. Ahora sé por qué.'];
async function talkBegona(){
  const N='BEGOÑA',J=CURRO.jard;
  if(S.curro.jard){const c=await ask(`¿Qué tal las plantas, majo? Paso cada mañana: ${eur(J.sueldo)} al día.`,['Charlar','Que lo deje','Nada'],N);
    if(c===0)return say(pick(BEGONA_TIPS),N);if(c===1){S.curro.jard=null;return say('Como quieras. Si me necesitas, aquí estoy.',N);}return;}
  const ops=['Charlar'].concat(totalBuds()>=REL.regaloG?[`Regalarle ${REL.regaloG} g`]:[],S.ch>=J.ch&&rel('begona')>=REL.amigo?['Contratarla']:[],['Nada']);
  const op=ops[await ask(S.ch>=J.ch&&rel('begona')<REL.amigo?'Tu tía me dejaba cuidarle las plantas cuando se iba. Con confianza, se habla de todo.':'Hola, majo. ¿Cómo van esas plantas?',ops,N)];
  if(op==='Charlar')return say(pick(BEGONA_TIPS),N);
  if(op&&op.startsWith('Regalarle')){
    if(S.flags.regBeg===S.day)return say('Hoy ya me has dado, majo. Mañana más.',N);
    const lots=budLots(REL.regaloG),i=await menu(lots.map(lotItem).concat([{label:'Nada'}]),{cls:'right',title:'¿Qué le das?'});if(i<0||i>=lots.length)return;
    useBuds(lots[i][0],REL.regaloG);S.flags.regBeg=S.day;confia('begona',REL.regalo);sfx('get');return say('Ay, gracias. Para dormir, como hacía tu tía.',N);
  }
  if(op==='Contratarla'){
    if(await ask(`Te riego, relleno las garrafas y el depósito y, si tienes insecticida, trato las plagas. ${eur(J.sueldo)} al día, cada mañana. ¿Hecho?`,['Hecho','Ahora no'],N)!==0)return;
    S.curro.jard={dia:S.day};return say('Mañana empiezo. Ya sé dónde dejaba la llave tu tía.',N);
  }
}
// Clubs cannábicos (CLUBS): uno en Puerto Viejo y otro en Valdehierro (cap. 3) y dos en Ibarbide (cap. 4). Con el carné (la cuota, una
// vez): vender un lote al día (de 50 a 200 g, entre lo de Iñaki y la calle, calor +1), comprar 10 g de la variedad del día (entra en
// la Genoteca) y encargos de semillas (10 de una variedad, en 7 días; las de receta pagan más). Un encargo a la vez
const CLUBS={puerto:{n:'CLUB ITSASO',map:'puerto',x:10,y:8,ch:3,cuota:30,sid:['limon','cheese']},valde:{n:'CLUB LA FUNDICIÓN',map:'valdehierro',x:12,y:8,ch:3,cuota:30,sid:['txoko','mango']},
  ibar:{n:'CLUB KALEA',map:'ibarbide',x:6,y:18,ch:4,cuota:50,sid:['kali','chemdawg']},ens:{n:'CLUB ENSANCHE',map:'ensanche',x:12,y:9,ch:4,cuota:50,sid:['niebla','calorange']}};
const CLUB={g:[50,100,200],compra:10,compraF:1.2,calor:1,enc:{n:10,dias:7,f:1.2,receta:80}};
const precioClub=thc=>3+thc*.15;
// el encargado de cada club, en la puerta, desde su capítulo
Object.keys(CLUBS).forEach((k,i)=>{const C=CLUBS[k];NPCDEF.push({id:'club_'+k,map:C.map,x:C.x,y:C.y,dir:'down',look:i%2?'portera':'portero',cond:()=>S.ch>=C.ch,talk:()=>talkClub(k)});});
async function talkClub(k){
  const C=CLUBS[k],N=C.n;
  if(!S.clubs[k]){
    if(await ask(`${C.n}, asociación de consumidores. Dentro no se vende nada: lo tuyo entra por la puerta de atrás. La cuota son ${eur(C.cuota)}. ¿Te haces socio?`,['Hacerme socio','No'],N)!==0)return;
    if(S.money<C.cuota){sfx('bad');return say('Sin la cuota no hay carné.',N);}
    S.money-=C.cuota;S.clubs[k]=true;S.rep+=1;confia(k,2);sfx('coin');await got('el carné de '+C.n);
  }
  const E=S.clubEnc,c=await ask('¿Qué te trae?',['Vender al club',`Comprar ${CLUB.compra} g`,E&&E.k===k?'Entregar las semillas':'Encargo de semillas','Nada'],N);
  if(c===0)return venderClub(k);if(c===1)return comprarClub(k);if(c===2)return encargoClub(k);
}
async function venderClub(k){
  const C=CLUBS[k],N=C.n;
  if(S.clubDia[k]===S.day)return say('Hoy ya hemos cerrado caja. Mañana.',N);
  const lots=budLots(CLUB.g[0]);if(!lots.length)return say(`De ${CLUB.g[0]} g para arriba, entre ${coma(precioClub(12).toFixed(2))} y ${coma(precioClub(30).toFixed(2))} € el gramo según el THC. Una entrega al día.`,N);
  const i=await menu(lots.map(lotItem).concat([{label:'Nada'}]),{cls:'right',title:'¿Qué lote?'});if(i<0||i>=lots.length)return;
  const [kk,b]=lots[i],pg=Math.round(precioClub(b.thc)*(b.ana?1.05:1)*100)/100,ops=CLUB.g.filter(g=>g<=Math.floor(b.g));
  const j=await ask(`${lotNombre(kk)} a ${coma(pg.toFixed(2))} € el gramo${b.ana?' (analizado)':''}. ¿Cuánto?`,ops.map(g=>`${g} g · ${eur(g*pg)}`).concat(['Nada']),N);if(j<0||j>=ops.length)return;
  const g=ops[j],e=Math.round(g*pg);useBuds(kk,g);S.money+=e;S.sales+=e;S.heat=Math.min(100,S.heat+CLUB.calor);S.rep+=1;S.clubDia[k]=S.day;confia(k,2);sfx('coin');
  await accion('vender',{id:'vfx-monedas',x:P.px+8,y:P.py+2});toast(`+${eur(e)} · ${g} g al club`,1600);await say('Por la puerta de atrás, como siempre. Gracias.',N);await checkStory();
}
async function comprarClub(k){
  const C=CLUBS[k],N=C.n;if(S.clubCompra[k]===S.day)return say('Lo de hoy ya está repartido. Mañana hay más.',N);
  const sid=C.sid[S.day%C.sid.length],s=STRAINS[sid],p=Math.round(precioCalle(s.thc)*CLUB.compraF*CLUB.compra);
  if(await ask(`Hoy tenemos ${s.n} (${pct(s.thc)} %): ${CLUB.compra} g por ${eur(p)}. ¿Te los llevas?`,['Comprar','No'],N)!==0)return;
  if(S.money<p){sfx('bad');return say('Sin dinero no hay reparto.',N);}
  if(libreMochila()<CLUB.compra)return say('No te caben en la bolsa.',N);
  S.money-=p;S.clubCompra[k]=S.day;addBuds(sid,CLUB.compra,s.thc);discover(sid);sfx('coin');toast(`Comprado: ${CLUB.compra} g de ${s.n}`,1200);
}
async function encargoClub(k){
  const C=CLUBS[k],N=C.n,E=S.clubEnc;
  if(E){
    if(E.k!==k)return say(`Ya tienes un encargo pendiente en ${CLUBS[E.k].n}. Cumple ese primero.`,N);
    const s=getStrain(E.sid),t=S.seeds[E.sid]||0;if(t<E.n)return say(`Nos faltan ${E.n-t} semillas de ${s.n}. Hasta el día ${E.hasta}.`,N);
    S.seeds[E.sid]-=E.n;if(!S.seeds[E.sid])delete S.seeds[E.sid];S.money+=E.pago;S.sales+=E.pago;S.rep+=3;confia(k,5);S.clubEnc=null;S.clubEncDia=S.day;sfx('coin');
    toast(`+${eur(E.pago)} · ${E.n} semillas de ${s.n}`,1600);await say('Las sembramos para los socios. Buen trabajo.',N);await checkStory();return;
  }
  if(S.clubEncDia===S.day)return say('Hoy ya no hay más encargos. Mañana.',N);
  const cand=SHOP.filter(it=>it.sid&&S.ch>=it.ch).map(it=>[it.sid,Math.round(it.p*CLUB.enc.n*CLUB.enc.f)]).concat(S.ch>=4?[...new Set(Object.values(RECIPES))].filter(s=>S.disc[s]).map(s=>[s,CLUB.enc.receta*CLUB.enc.n]):[]);
  const [sid,pago]=pick(cand),s=STRAINS[sid];
  if(await ask(`Los socios quieren ${CLUB.enc.n} semillas de ${s.n}. Pagamos ${eur(pago)}, en ${CLUB.enc.dias} días. ¿Te encargas?`,['Aceptar','No'],N)!==0)return say('Si cambias de idea, aquí estamos.',N);
  S.clubEnc={k,sid,n:CLUB.enc.n,hasta:S.day+CLUB.enc.dias,pago};await say(`Hasta el día ${S.clubEnc.hasta}. Las semillas, aquí.`,N);
}
function vencerEncargoClub(){
  const E=S.clubEnc;if(!E||S.day<=E.hasta)return;
  S.clubEnc=null;S.rep=Math.max(0,S.rep-3);confia(E.k,-10);queue('clubEnc',()=>talk('SMS · '+CLUBS[E.k].n,['Se acabó el plazo de las semillas. Los socios no se olvidan.']));
}
// La cata (desde la mochila): fumar CATA.g de un lote (CATA.min minutos) deja su nota (aroma por variedad, efecto por el % índica y la
// potencia, exacta con el analizador de THC) en la Genoteca, y el lote catado se vende algo mejor; el analizado (el aparato del
// growshop, uno), mejor aún y un 5 % más en los clubs
const CATA={g:.5,min:30},AROMAS=['cítrico','a pino','terroso','dulce','a especias','a gasóleo','afrutado','a incienso'];
// el analizador de cannabinoides y terpenos: THC, CBD (del 0,2 al 1 % según el % índica) y el terpeno principal, por el aroma
const TERPENOS={'cítrico':'limoneno','a pino':'pineno','terroso':'mirceno','dulce':'linalool','a especias':'cariofileno','a gasóleo':'mirceno y cariofileno','afrutado':'mirceno','a incienso':'humuleno'};
const aromaDe=sid=>AROMAS[hashStr(sid)%AROMAS.length],cbdDe=sid=>Math.round(20+indDe(sid)*.8)/100;
function notaCata(sid,thc){const ind=indDe(sid),a=aromaDe(sid),e=ind>=65?'relaja y pesa':ind<=35?'sube y despeja':'equilibrado';
  return `Aroma ${a}${S.items.analizador?' ('+TERPENOS[a]+')':''} · ${e} · ${S.items.analizador?pct(thc)+' % de THC':thc<12?'floja':thc<18?'media':thc<24?'fuerte':'muy fuerte'}`;}
async function catar(k){
  const b=S.buds[k];if(!b||b.g<CATA.g)return;
  const sid=lotSid(k),thc=b.thc;useBuds(k,CATA.g);if(S.buds[k])S.buds[k].cata=true;S.catas[sid]=notaCata(sid,thc);advanceTime(CATA.min);updateHUD();
  await say(`Catas ${lotNombre(k)}: ${S.catas[sid]}.`);
}
async function analizar(k){const b=S.buds[k];if(!b||!S.items.analizador)return;const sid=lotSid(k);b.ana=true;sfx('get');await say(`Analizado: ${lotNombre(k)} · THC ${pct(b.thc)} % · CBD ${pct(cbdDe(sid))} % · terpeno principal, ${TERPENOS[aromaDe(sid)]}. Lo que va con análisis se vende mejor.`);}
async function loteAccion(k){
  const b=S.buds[k],ops=[`Catar ${coma(CATA.g)} g`].concat(S.items.analizador&&!b.ana?['Analizar']:[],['Nada']);
  const op=ops[await ask(`${lotNombre(k)}: ${Math.floor(b.g)} g · ${pct(b.thc)} %${b.cata?' · catado':''}${b.ana?' · analizado':''}`,ops)];
  if(op&&op.startsWith('Catar'))return catar(k);if(op==='Analizar')return analizar(k);
}

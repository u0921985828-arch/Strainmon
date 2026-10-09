/* =========================================================
   LA CAJA FUERTE, EL ROBO DE DARKO Y LOS ENCARGOS DE BALTASAR (1.10)
   ========================================================= */
// la caja: C, la de la tía Maite, detrás del diploma de la Copa de 1998 (la pista está en sus notas del ordenador): 20.000 € y
// 2 kg; B, la empotrada, por el ordenador desde el capítulo 4 (CAJA_P, la instala Kiko al día siguiente): 50.000 € y 2,5 kg.
// Lo que hay dentro no va encima: no cuenta para los encuentros ni te lo quitan un control, un ladrón o Darko. En una redada no la
// tocan (1.11: raidEvent; solo pagan de ella la multa que no llegue de fuera). El rosin (con la prensa) va en S.caja.rosin, que no existe hasta que guardas el
// primero, y ocupa el hueco de los cogollos. La luz y lo que se compra por el ordenador se pagan de fuera y, si no llega, de la caja
const CAJA=[null,{n:'La caja de la tía',money:20000,g:2000},{n:'La caja empotrada',money:50000,g:2500}],CAJA_P=380,CAJA_ANIO=1998,MAITE_CAJA=300;
const cajaG=()=>S.caja?Object.values(S.caja.buds).reduce((a,b)=>a+b.g,0):0,cajaE=()=>S.caja?S.caja.money:0;
const cajaR=()=>S.caja&&S.caja.rosin?Object.values(S.caja.rosin).reduce((a,b)=>a+b.g,0):0;
// pagar desde el piso: primero lo de fuera y después la caja. Devuelve lo que falta
function pagarCasa(e){const a=Math.min(S.money,e);S.money-=a;e-=a;if(e>0&&S.caja){const b=Math.min(S.caja.money,e);S.caja.money-=b;e-=b;}return e;}
// g gramos del lote k de «de» a «a»: si el lote ya está, se juntan con el THC medio por gramos
function moverLote(de,a,k,g){const b=de[k],t=a[k];if(t){t.thc=(t.thc*t.g+b.thc*g)/(t.g+g);t.g+=g;}else a[k]={g,thc:b.thc};b.g-=g;if(b.g<.5)delete de[k];}
// lo mismo con el rosin, al décimo de gramo (como addRosin y useRosin)
function moverRosin(de,a,k,g){const b=de[k],t=a[k];if(t){t.thc=(t.thc*t.g+b.thc*g)/(t.g+g);t.g=Math.round((t.g+g)*10)/10;}else a[k]={g,thc:b.thc};b.g=Math.round((b.g-g)*10)/10;if(b.g<.1)delete de[k];}
// «300 € y 50 g», «300 €, 50 g y 2 g de rosin» o, sin cogollos, «300 € y 2 g de rosin»
function loQue(e,g,r){const L=[eur(e)];if(g>=1||r<.1)L.push(gTxt(g));if(r>=.1)L.push(rosinTxt(r));return L.slice(0,-1).join(', ')+' y '+L[L.length-1];}
async function diplomaAction(){
  if(S.caja)return cajaAction();
  if(await ask('Un diploma enmarcado: «COPA DE RIBERA 1998 · 2º PREMIO: MAITE».',['Mirar detrás','Dejarlo'])!==0)return;
  await say('Detrás del marco hay una caja fuerte empotrada en la pared. Tiene una rueda de cuatro cifras.');
  const ops=['1976','1979','1987','1998'],j=await ask('¿Qué combinación pruebas?',ops.concat(['Dejarlo']));
  if(j<0||j>=ops.length)return;
  if(+ops[j]!==CAJA_ANIO){sfx('bump');return say('Clac. No se abre.');}
  S.caja={money:MAITE_CAJA,buds:{},nivel:1};sfx('get');
  await say('Clic. La caja se abre.');
  await say(`Dentro hay ${eur(MAITE_CAJA)} y una nota de la tía: «Para ti, {N}. Lo que guardes aquí no te lo quita nadie en la calle».`);
  await say(`Caben ${eur(CAJA[1].money)} y ${kgTxt(CAJA[1].g)}. Lo que está dentro no lo llevas encima.`);
}
// cuánto: los pasos que caben por debajo del máximo y el máximo; 0 si no eliges nada
async function cuanto(txt,max,pasos,fmt){
  const ops=pasos.filter(v=>v<max).concat([max]),j=await ask(txt,ops.map(fmt).concat(['Nada']));
  return j>=0&&j<ops.length?ops[j]:0;
}
const gTxt=g=>Math.floor(g)+' g';
async function cajaAction(){
  for(;;){
    const C=CAJA[S.caja.nivel],ro=!!S.items.prensa||cajaR()>0;   // con la prensa (o rosin dentro), también el rosin
    const ops=['Guardar todo','Guardar dinero','Guardar cogollos'].concat(ro?['Guardar rosin']:[],['Sacar dinero','Sacar cogollos'],ro?['Sacar rosin']:[],['Sacar todo','Cerrar']);
    const op=ops[await ask(`${C.n}: ${loQue(S.caja.money,cajaG(),cajaR())} (caben ${eur(C.money)} y ${kgTxt(C.g)}).\nEncima: ${loQue(S.money,totalBuds(),totalRosin())}.`,ops)];
    if(!op||op==='Cerrar')return;
    const hueco=()=>C.g-cajaG()-cajaR(),huecoR=()=>Math.floor(hueco()*10+1e-9)/10;
    if(op==='Guardar todo'){
      const e=Math.min(S.money,C.money-S.caja.money);S.money-=e;S.caja.money+=e;let g=0,r=0;
      for(const [k,b] of Object.entries(S.buds)){const q=Math.min(b.g,hueco());if(q<.5)break;/* menos de medio gramo no es un lote (moverLote) */g+=q;moverLote(S.buds,S.caja.buds,k,q);}
      for(const [k,b] of Object.entries(S.rosin)){const q=Math.min(b.g,huecoR());if(q<.1)break;S.caja.rosin=S.caja.rosin||{};r+=q;moverRosin(S.rosin,S.caja.rosin,k,q);}
      sfx('sel');await say(`Guardas ${loQue(e,g,r)}.${S.money>=1||totalBuds()>=1||totalRosin()>=.1?' No cabe todo: el resto se queda fuera.':''}`);
    }else if(op==='Sacar todo'){   // los gramos, hasta el tope de la mochila (1.10)
      const e=S.caja.money;S.money+=e;S.caja.money=0;let g=0,r=0;
      for(const [k,b] of Object.entries(S.caja.buds)){const q=Math.min(b.g,Math.floor(libreMochila()));if(q<.5)break;g+=q;moverLote(S.caja.buds,S.buds,k,q);}
      if(S.caja.rosin){for(const [k,b] of Object.entries(S.caja.rosin)){const q=Math.min(b.g,Math.floor(libreMochila()*10+1e-9)/10);if(q<.1)break;r+=q;moverRosin(S.caja.rosin,S.rosin,k,q);}
        if(!Object.keys(S.caja.rosin).length)delete S.caja.rosin;}
      sfx('sel');await say(`Sacas ${loQue(e,g,r)}.${cajaG()>=.5||cajaR()>=.1?' No te cabe todo encima: el resto se queda en la caja.':''}`);
    }else if(op==='Guardar rosin'||op==='Sacar rosin'){
      const mete=op==='Guardar rosin',de=mete?S.rosin:S.caja.rosin||{},lots=Object.entries(de);
      if(!lots.length){await say(mete?'No llevas rosin encima.':'La caja no tiene rosin.');continue;}
      if(mete&&huecoR()<.1){await say('No cabe más.');continue;}
      if(!mete&&libreMochila()<.1){await say('No te cabe nada más encima.');continue;}
      const i=await menu(lots.map(rosinItem).concat([{label:'Nada'}]),{cls:'right',title:mete?'¿Qué guardas?':'¿Qué sacas?'});
      if(i<0||i>=lots.length)continue;
      const [k,b]=lots[i],g=await cuanto(`Rosin · ${lotNombre(k)}: ¿cuánto?`,mete?Math.min(b.g,huecoR()):Math.min(b.g,Math.floor(libreMochila()*10+1e-9)/10),[1,5,10,50],r=>coma(r)+' g');if(!g)continue;
      if(mete)S.caja.rosin=S.caja.rosin||{};
      moverRosin(de,mete?S.caja.rosin:S.rosin,k,g);if(!mete&&!Object.keys(S.caja.rosin).length)delete S.caja.rosin;sfx('sel');
    }else if(op==='Guardar dinero'||op==='Sacar dinero'){
      const mete=op==='Guardar dinero',max=mete?Math.min(S.money,C.money-S.caja.money):S.caja.money;
      if(max<1){await say(mete?(S.money<1?'No llevas dinero encima.':'No cabe más dinero.'):'La caja no tiene dinero.');continue;}
      const e=await cuanto(mete?'¿Cuánto guardas?':'¿Cuánto sacas?',max,[100,500,1000,5000,10000,20000],eur);if(!e)continue;
      S.money+=mete?-e:e;S.caja.money+=mete?e:-e;sfx('sel');
    }else{
      const mete=op==='Guardar cogollos',de=mete?S.buds:S.caja.buds,a=mete?S.caja.buds:S.buds,lots=Object.entries(de);
      if(!lots.length){await say(mete?'No llevas cogollos encima.':'La caja no tiene cogollos.');continue;}
      if(mete&&hueco()<1){await say('No caben más cogollos.');continue;}
      if(!mete&&libreMochila()<1){await say('No te cabe nada más encima.');continue;}
      const i=await menu(lots.map(lotItem).concat([{label:'Nada'}]),{cls:'right',title:mete?'¿Qué guardas?':'¿Qué sacas?'});
      if(i<0||i>=lots.length)continue;
      const [k,b]=lots[i],g=await cuanto(`${lotNombre(k)}: ¿cuánto?`,mete?Math.min(b.g,hueco()):Math.min(b.g,Math.floor(libreMochila())),[10,50,100,500,1000],gTxt);if(!g)continue;
      moverLote(de,a,k,g);sfx('sel');
    }
  }
}
// el ordenador: las notas de la tía (la pista de la combinación) y la caja empotrada
async function notasTia(){await talk('NOTAS DE LA TÍA',['«Veinte años de cultivos, apuntados día a día.»','«Lo que no quiero llevar a la calle lo guardo detrás de mi premio. La combinación, el año en que lo gané.»']);}
async function pedirCaja(){
  if(await ask(`Caja empotrada: ${eur(CAJA[2].money)} y ${kgTxt(CAJA[2].g)}. Kiko la instala mañana detrás del diploma, con lo que ya tengas dentro. ${eur(CAJA_P)}.`,['Pedirla','Nada'])!==0)return;
  if(S.money+cajaE()<CAJA_P){sfx('bad');return say('No te llega el dinero.');}
  pagarCasa(CAJA_P);S.caja.mejora=1;sfx('coin');toast('Pedida: caja empotrada · llega mañana',1400);
}
function instalarCaja(){
  if(!S.caja||!S.caja.mejora)return;
  delete S.caja.mejora;S.caja.nivel=2;
  queue('caja',async()=>{sfx('get');await talk('SMS · KIKO',['Ya está: la caja empotrada, detrás del diploma. Lo de la vieja lo tienes dentro.',`Caben ${eur(CAJA[2].money)} y ${kgTxt(CAJA[2].g)}.`]);});
}
// el robo de Darko: la primera noche del capítulo 7 que duermes con más de 1.000 € o 100 g fuera de la caja (el rosin cuenta
// como la flor de la que sale: gramosFlor), se llevan la mitad
async function roboDarko(){
  S.flags.robo=true;const e=Math.floor(S.money/2);let g=0,r=0;
  for(const b of Object.values(S.buds)){const l=Math.floor(b.g/2);g+=l;b.g-=l;}
  for(const k of Object.keys(S.buds))if(S.buds[k].g<.5)delete S.buds[k];
  for(const k of Object.keys(S.rosin)){const q=Math.round(S.rosin[k].g*5)/10;r+=q;useRosin(k,q);}   // y la mitad del rosin, como un ladrón
  const A=S.arcon;   // y la mitad de lo del arcón (1.10)
  for(const k of Object.keys(A.buds)){const l=Math.floor(A.buds[k].g/2);g+=l;A.buds[k].g-=l;if(A.buds[k].g<.5)delete A.buds[k];}
  for(const k of Object.keys(A.rosin)){const q=Math.round(A.rosin[k].g*5)/10;r+=q;A.rosin[k].g=Math.round((A.rosin[k].g-q)*10)/10;if(A.rosin[k].g<.1)delete A.rosin[k];}
  S.money-=e;sfx('bad');
  await say('Te despierta un portazo. La cerradura está forzada y el piso, revuelto.');
  await say(`Se han llevado ${loQue(e,g,r)}.${S.caja?' La caja de detrás del diploma sigue cerrada.':''}`);
  await talk('SMS · DARKO',['Te dije que esto no se acababa ahí.']);
  if(!S.caja)await say('Si la tía guardaba sus cosas en algún sitio, ahora te vendría bien saber dónde.');
  save();
}
// los encargos de Baltasar (capítulo 8): llevar ENCARGO[nivel del imperio] gramos al almacén de los astilleros, de noche, en 2 días,
// a PAGO_ENCARGO €/g. Si no llegas, reputación −10 y 5 días sin encargos
const ENCARGO=[2000,2000,5000,10000],PAGO_ENCARGO=6,ENCARGO_DIAS=2,ENCARGO_VETO=5;
async function encargoBaltasar(N){
  if(S.encargo)return say(`Toño te espera en el almacén de los astilleros, de noche, con ${kgTxt(S.encargo.g)}. Hasta el día ${S.encargo.hasta}.`,N);
  if(S.encVeto>S.day)return say(`Me fallaste, {N}. Vuelve el día ${S.encVeto}.`,N);
  const g=ENCARGO[imperioNivel()];
  await talk(N,['Ya no me debes nada, {N}. Pero tengo trabajo, si lo quieres.',`${kgTxt(g)} en el almacén de los astilleros, de noche. Toño los recoge.`,`Pago ${PAGO_ENCARGO} € el gramo: ${eur(g*PAGO_ENCARGO)}. Tienes ${ENCARGO_DIAS} días.`]);
  if(await ask('¿Aceptas el encargo?',['Aceptar','No'],N)!==0)return say('Tú sabrás. La oferta sigue en pie.',N);
  S.encargo={g,hasta:S.day+ENCARGO_DIAS};
  await say(`Toño estará allí cada noche hasta el día ${S.encargo.hasta}. No le hagas esperar.`,N);showObjective();
}
async function talkTonoAlmacen(){
  const N='TOÑO',E=S.encargo;
  if(!E)return say('El plazo se acabó. Don Baltasar ya te escribirá.',N);   // vencido con él delante (sigue en pantalla hasta el próximo buildEnts)
  if(!isNight())return say('¿De día? ¿Tú estás loco? Vuelve de noche, a partir de las nueve.',N);
  if(totalBuds()<E.g)return say(`Don Baltasar dijo ${kgTxt(E.g)}. Llevas ${gTxt(totalBuds())}. Vuelve con todo.`,N);
  if(await ask(`¿Entregas ${kgTxt(E.g)}? Toño se lleva primero los lotes más flojos.`,['Entregar','Todavía no'],N)!==0)return;
  let q=E.g;
  for(const [k] of Object.entries(S.buds).sort((a,b)=>a[1].thc-b[1].thc)){const t=Math.min(q,S.buds[k].g);useBuds(k,t);q-=t;if(q<=0)break;}
  const e=E.g*PAGO_ENCARGO;S.money+=e;S.sales+=e;S.heat=Math.min(100,S.heat+3);S.rep+=2;S.encargo=null;sfx('coin');
  toast(`+${eur(e)} · encargo de Don Baltasar`,1600);
  await say('Contado. Don Baltasar estará contento.',N);await fade(1);buildEnts();await fade(0);showObjective();await checkStory();
}
function vencerEncargo(){
  if(!S.encargo||S.day<=S.encargo.hasta)return;
  S.encargo=null;S.rep=Math.max(0,S.rep-10);S.encVeto=S.day+ENCARGO_VETO;
  queue('encargo',()=>talk('SMS · TOÑO',['No apareciste. Don Baltasar no se olvida.',`Reputación −10. Nada de encargos hasta el día ${S.encVeto}.`]));
}

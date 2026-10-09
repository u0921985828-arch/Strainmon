/* =========================================================
   EL MÓVIL (1.10)
   ========================================================= */
// desde el menú START, estés donde estés: llamar (Kiko, Toño, Iñaki y la agenda de clientes, S.fijos), pedir a Kiko (llega
// mañana a casa, ENVIO más caro: recibirEnvio en newDay) y los mensajes (los SMS que te llegan, S.sms; los apunta talk).
// Un cliente de la agenda (te da su número al comprarte) viene a buscarte a la calle: una vez al día, LLAMADA_MIN minutos
// de espera y +1 de calor, y no con la policía detrás
const ENVIO=1.15,SMS_MAX=30,FIJOS_MAX=8,LLAMADA_MIN=20;
const NOMBRES_FIJO=['Asier','Leire','Ibai','Nerea','Unax','Ane','Gorka','Maialen','Jon','Irati','Xabi','Uxue'];
const nombreFijo=id=>NOMBRES_FIJO[[...id].reduce((a,ch)=>(a*31+ch.charCodeAt(0))%9973,0)%NOMBRES_FIJO.length];
function apuntaFijo(c){if(c.fijo||S.fijos.length>=FIJOS_MAX||S.fijos.some(f=>f.id===c.id))return;S.fijos.push({id:c.id,n:nombreFijo(c.id),t:c.type,dia:0});}
const relojTxt=()=>String(Math.floor(S.min/60)).padStart(2,'0')+':'+String(S.min%60).padStart(2,'0');
async function movilMenu(){
  for(;;){
    const ops=['Llamar'].concat(S.flags.kiko1?['Pedir a Kiko']:[],['Mensajes','Tienda online','Colgar']);
    const op=ops[await ask(`MÓVIL · día ${S.day}, ${relojTxt()}${S.sms.length?` · ${S.sms.length} mensaje${S.sms.length>1?'s':''}`:''}`,ops)];
    if(!op||op==='Colgar')return;
    if(op==='Llamar'){if(await llamar())return;}
    else if(op==='Pedir a Kiko')await pedirKiko();
    else if(op==='Tienda online')await tiendaOnline();
    else await mensajes();
  }
}
// devuelve true si ha venido un cliente (el móvil se cierra)
async function llamar(){
  const C=[];
  if(S.flags.kiko1)C.push({label:'Kiko',right:'growshop',desc:'Consejos de cultivo. Los pedidos, desde «Pedir a Kiko».',k:'kiko'});
  if(S.flags.tono)C.push({label:'Toño',right:'Don Baltasar',desc:'Lo que debes y hasta cuándo.',k:'tono'});
  if(S.flags.inaki)C.push({label:'Iñaki',right:'muelle',desc:'Compra al por mayor.',k:'inaki'});
  for(const f of S.fijos)C.push({label:f.n,right:CTYPES[f.t].label.toLowerCase(),desc:f.dia===S.day?'Ya ha venido hoy.':'Te compró en la calle. Si estás fuera, viene a buscarte.',f});
  if(!C.length){await say('La agenda está vacía.');return false;}
  const i=await menu(C.concat([{label:'Nada'}]),{cls:'right',title:'LLAMAR'});
  if(i<0||i>=C.length)return false;
  const c=C[i];
  if(c.k==='kiko'){await talk('KIKO',[kikoTip()]);return false;}
  if(c.k==='tono'){await talk('TOÑO',[S.due>0?`Te quedan ${eur(S.due)} hasta el día ${S.deadline}. Don Baltasar no espera.`:'Ahora mismo no debes nada. Que siga así.']);return false;}
  if(c.k==='inaki'){await talk('IÑAKI',[S.ch<3?'Ahora estoy en la mar. A la vuelta hablamos.':S.mDay===S.day?'Hoy ya he cargado. Mañana sale otro barco.':`Al por mayor, de 100 g para arriba y hasta ${kgTxt(mayorDia())} por carga. Pásate por el muelle.`]);return false;}
  return llamarFijo(c.f);
}
async function llamarFijo(f){
  if(f.dia===S.day){await say(`${f.n} ya ha venido hoy.`);return false;}
  if(!ZONAS[S.map]){await say(`${f.n}: «¿Dónde estás? Quedamos en la calle».`);return false;}
  if(SOSP.alarma){await say(`${f.n}: «¿Con la policía detrás? Ni de broma».`);return false;}
  const ct=CTYPES[f.t];f.dia=S.day;S.heat=Math.min(100,S.heat+1);
  await say(`${f.n}: «Vale, voy para allá».`);
  advanceTime(LLAMADA_MIN);updateHUD();
  await talkClient({id:'tel-'+f.id,fijo:true,n:f.n.toUpperCase(),map:S.map,x:P.x,y:P.y,type:f.t,want:ri(ct.g[0],ct.g[1]),minThc:f.t==='pij'?Math.min(24,15+S.ch):0});
  return true;
}
// lo que Kiko manda a casa: lo del growshop que no son semillas, carpas ni la prensa, más caro; lo que ya está pedido no se repite
const precioEnvio=it=>Math.round(it.p*ENVIO);
const pedible=it=>!it.sid&&!it.carpa&&it.item!=='prensa'&&S.ch>=it.ch&&(!it.cond||it.cond());   // cond ya cuenta lo pedido (aparatos, bolsas, extras)
async function pedirKiko(){
  let i=0,ult=null;
  for(;;){
    const l=SHOP.filter(pedible),j=l.findIndex(it=>it.lbl===ult);if(j>=0)i=j;   // el cursor, en lo último pedido si sigue en la lista
    const items=l.map(it=>{const n=S.envio.filter(x=>x===it.lbl).length;return {label:it.lbl+(n?' · ×'+n:''),right:eur(precioEnvio(it)),desc:it.desc};});
    items.push({label:'Salir',desc:'Lo pedido llega mañana por la mañana a casa.'});
    i=await menu(items,{cls:'full',title:'PEDIR A KIKO',title2:`Envío a casa +${Math.round((ENVIO-1)*100)} % · tienes ${eur(S.money)}`,desc:true,initial:i});
    if(i<0||i>=l.length)return;
    const it=l[i],e=precioEnvio(it);
    if(S.money<e){sfx('bad');await say('No te llega el dinero.');continue;}
    S.money-=e;S.envio.push(it.lbl);ult=it.lbl;sfx('coin');toast('Pedido: '+it.lbl+' · llega mañana',1400);
  }
}
function recibirEnvio(){
  if(!S.envio.length)return;
  const c={};
  for(const lbl of S.envio){const it=SHOP.find(x=>x.lbl===lbl);if(!it)continue;c[lbl]=(c[lbl]||0)+1;
    if(it.item)S.items[it.item]+=it.n||1;if(it.maceta)S.items['m_'+it.maceta]++;if(it.foco)S.items['f_'+it.foco]++;if(it.extra)S.items['x_'+it.extra]++;
    if(it.bolsa)S.items.bolsa=Math.max(S.items.bolsa||0,it.bolsa);if(it.aparato)S.sala[it.aparato]=true;}
  S.envio=[];
  const t=Object.entries(c).map(([l,n])=>n>1?`${l} ×${n}`:l).join(', ');
  queue('envio',()=>talk('SMS · KIKO',[`Te he dejado el paquete en casa: ${t}.`]));
}
async function mensajes(){
  if(!S.sms.length)return say('No tienes mensajes.');
  let i=0;
  do{i=await menu(S.sms.map(m=>({label:m.n,right:'día '+m.d,desc:m.t})),{cls:'full',title:'MENSAJES',title2:`${S.sms.length} de ${SMS_MAX}`,desc:true,initial:i});}while(i>=0);
}

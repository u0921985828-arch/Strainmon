/* =========================================================
   SALÓN (1.10): a la derecha del piso (x 12-17), vacío al llegar; los muebles se compran por internet (el ordenador de
   la tía, el PC gaming o el móvil) y llegan al día siguiente (newDay → llegaMueble), montados por montarCasa.
   Cada uno ocupa 2 casillas: k en (x, y) y k+'2' en (x+1, y), que no se pinta (arteObj) y hace lo mismo al tocarlo.
   El carro de esquejes (1.11, grow: 1) va en medio del piso, delante de las carpas: lo vende Kiko en el growshop (no la tienda
   online) y lo sube él al día siguiente. En su mesita, la tabla de corte: los esquejes del propagador se pinchan en las bandejas
   (S.bandejas, CARRO en 09-cultivo) y se plantan desde ahí (plantar).
   ========================================================= */
const MUEBLES={
  sofa:{n:'Sofá de 2 plazas',art:'el sofá',p:399,x:13,y:5,d:'Sofá de 180 cm, de tela azul, mirando a la tele. Para echar una cabezada sin meterte en la cama.'},
  tv:{n:'Tele de 43" con mueble',art:'la tele',p:449,x:13,y:2,d:'Smart TV de 43 pulgadas y un mueble bajo de 140 cm con hueco para la consola. Noticias y documentales.'},
  gpc:{n:'PC gaming con mesa',art:'el PC gaming',p:1490,x:16,y:2,d:'Torre con gráfica, monitor de 27", teclado mecánico y mesa de 140 cm con LED. Para jugar, leer el foro de cultivo y comprar.'},
  carro:{n:'Carro de esquejes',art:'el carro de esquejes',p:CARRO.p,x:8,y:5,grow:1,d:`Carro con ruedas, dos bandejas de ${CARRO.plazas} tacos tapadas bajo tubos T5 y una mesita con la tabla de corte.`}};
// el patinete y la bici (1.13): por la tienda online, llegan al día siguiente (S.veh[k] = ese día) y, en la calle (las ZONAS), vas
// montado en el mejor que tengas (vehiculo()). paso: ms por casilla [sin B, con B] (a pie, 240 y 130; la policía corre a 210 y 180);
// sube: los px que sube el protagonista (en la tabla o en el sillín; dibujarPJ, arte de tools/sprites/a-mano/vehiculos.py).
const VEHICULOS={
  patinete:{n:'Patinete',art:'el patinete',p:119,paso:[150,110],sube:3,d:'Patinete de aluminio con ruedas de 200 mm. Más rápido que andar y, con B, que correr; se pliega para el autobús.'},
  bici:{n:'Bici de segunda mano',art:'la bici',p:239,paso:[110,80],sube:5,d:'Bici urbana de segunda mano, cuadro mostaza. La más rápida: la policía no te sigue.'}};
const vehiculo=()=>{const v=S&&S.veh;if(!v||!ZONAS[S.map])return null;return ['bici','patinete'].find(k=>v[k]&&v[k]<=S.day)||null;};
const SEGUNDA=new Set(Object.keys(MUEBLES).map(k=>k+'2'));
const muebleDe=o=>o&&(MUEBLES[o]?o:SEGUNDA.has(o)?o.slice(0,-1):null);
const mueblesYa=()=>Object.keys(MUEBLES).filter(k=>S.muebles&&S.muebles[k]&&S.muebles[k]<=S.day);
const carroYa=()=>mueblesYa().includes('carro');
// el foro (consejos de cultivo de verdad), los documentales de la tele y las partidas: uno por hora del día, sin azar
const FORO=['pH del agua de riego: entre 6 y 6,5 en tierra (en coco o hidro, 5,5-6). Fuera de ahí la planta no coge bien el abono.',
  'En floración, la humedad por debajo del 50 % y el aire moviéndose: el moho empieza por dentro del cogollo y no se ve hasta tarde.',
  'Las madres, siempre a 18/6. Un esqueje es un clon: mismo sexo y mismo fenotipo que la madre. Saca esquejes antes de pasarla a flor.',
  'Una fuga de luz en la noche del 12/12 estresa a la planta y puede salir hermafrodita. La carpa, bien cerrada y el temporizador, fijo.',
  'Cosecha con los tricomas lechosos y algo de ámbar. Transparentes, pronto; todos ámbar, el efecto es más pesado.',
  'Secado lento: 10-14 días a 18-20 °C y 55-60 % de humedad, a oscuras. Después, curado en tarros, abriéndolos un rato cada día.',
  'Con el abono, mejor quedarse corto: las puntas de las hojas quemadas son exceso. Y riega cuando la maceta pese poco, no por calendario.',
  'El foco, a su distancia: si las hojas de arriba amarillean o se curvan hacia arriba, está demasiado cerca. Súbelo.'];
const DOCU=['Documental: en el Hindu Kush las índicas se cultivan desde hace siglos para hacer hachís a mano, tamizando la resina.',
  'Documental: las sativas del ecuador (Tailandia, Colombia, Panamá) tardan hasta cuatro meses en florecer; por eso fuera de allí cuesta acabarlas.',
  'Documental: en el Rif, el kif tradicional se cultiva en terrazas y se tamiza en seco después de la cosecha.',
  'Documental: los bancos de conservación guardan las landraces para que no se pierdan entre tantos híbridos.'];
const JUEGOS=['Echas unas partidas de fútbol online. Pierdes la última en el descuento.','Una misión larga de un juego de rol. Se te va el tiempo sin darte cuenta.',
  'Juegas a un simulador de granja. Las plantas de mentira crecen más rápido que las tuyas.','Unas carreras con gente de medio mundo. Quedas tercero.'];
const porHora=l=>l[(S.day*24+Math.floor(S.min/60))%l.length];
function noticia(){
  if(S.heat>=60)return 'Noticias: la policía busca un cultivo de interior en Ribera Verde. Los vecinos denuncian olor a marihuana en varios portales.';
  if(S.heat>=30)return 'Noticias: detenido en el puerto un hombre con dos kilos de marihuana escondidos en una furgoneta de reparto.';
  return 'Noticias: el tiempo. Nubes y claros en la costa y la ría en calma. Nada que contar en Ribera Verde.';
}
async function muebleAction(k){
  if(k==='carro')return carroAction();
  if(k==='sofa'){
    const o=['Echar una cabezada (1 h)'].concat(mueblesYa().includes('tv')?['Ver la tele']:[],['Nada']);const c=o[await ask('Tu sofá. Todavía huele a nuevo.',o)];
    if(c==='Ver la tele')return muebleAction('tv');
    if(c!=='Echar una cabezada (1 h)')return;
    await fade(1);advanceTime(60);S.hp=Math.min(S.hpMax,S.hp+5);buildEnts();updateHUD();await wait(300);await fade(0);
    return say('Una cabezada en el sofá: +5 de vida.');
  }
  if(k==='tv'){
    const o=['Noticias','Documental','Nada'],c=o[await ask('La tele.',o)];
    if(c==='Nada'||!c)return;
    const t=c==='Noticias'?noticia():porHora(DOCU);advanceTime(60);updateHUD();return say(t);
  }
  const o=['Jugar (2 h)','Foro de cultivo','Tienda online','Apagar'],c=o[await ask('El PC gaming. Los ventiladores brillan de colores.',o)];
  if(c==='Jugar (2 h)'){const t=porHora(JUEGOS);await fade(1);advanceTime(120);buildEnts();updateHUD();await wait(300);await fade(0);return say(t);}
  if(c==='Foro de cultivo'){const t=porHora(FORO);advanceTime(30);updateHUD();return say('Foro de cultivo · '+t);}
  if(c==='Tienda online')return tiendaOnline();
}
async function tiendaOnline(){
  let i=0;
  for(;;){
    const ks=Object.keys(MUEBLES).filter(k=>!MUEBLES[k].grow),vs=Object.keys(VEHICULOS),ya=mueblesYa();
    const items=ks.map(k=>{const m=MUEBLES[k],en=ya.includes(k),pd=!en&&S.muebles&&S.muebles[k];
      return {label:m.n+(en?' · en casa':pd?' · pedido':''),right:eur(m.p),disabled:!!(en||pd),desc:m.d+(en?'':pd?'\nLlega mañana: te lo suben al salón.':'\nLlega mañana y te lo suben al salón.')};});
    for(const k of vs){const v=VEHICULOS[k],d=S.veh&&S.veh[k],en=d&&d<=S.day;
      items.push({label:v.n+(en?' · tuyo':d?' · pedido':''),right:eur(v.p),disabled:!!d,desc:v.d+(en?'':'\nLlega mañana: te lo dejan en el portal.')});}
    items.push({label:'Salir',desc:'Pagas con lo que llevas y, si no llega, con la caja fuerte.'});
    i=await menu(items,{cls:'full',title:'TIENDA ONLINE',title2:'Muebles y transporte · tienes '+eur(S.money+cajaE()),desc:true,initial:i});
    if(i<0||i>=ks.length+vs.length)return;
    const k=i<ks.length?ks[i]:vs[i-ks.length],m=i<ks.length?MUEBLES[k]:VEHICULOS[k];
    if(S.money+cajaE()<m.p){sfx('bad');await say('No te llega el dinero.');continue;}
    pagarCasa(m.p);(i<ks.length?S.muebles||(S.muebles={}):S.veh||(S.veh={}))[k]=S.day+1;sfx('coin');toast('Pedido: '+m.n+' · llega mañana',1400);
  }
}
function llegaMueble(){
  const vs=Object.keys(VEHICULOS).filter(k=>S.veh&&S.veh[k]===S.day);
  if(vs.length)queue('vehiculo',async()=>{sfx('get');await say(`Llega el mensajero con ${yLista(vs.map(k=>VEHICULOS[k].art))}. En la calle vas montado; con B, aún más rápido.`);});
  const l=Object.keys(MUEBLES).filter(k=>S.muebles&&S.muebles[k]===S.day);if(!l.length)return;
  montarCasa();
  // si estás donde lo montan, te apartas a la casilla libre más cercana (de dentro afuera; arriba, abajo, izquierda, derecha)
  if(S.map==='home'&&tileSolid(MAPS.home,P.x,P.y))for(let r=1,ok=false;r<4&&!ok;r++)for(let dy=-r;dy<=r&&!ok;dy++)for(let dx=-r;dx<=r&&!ok;dx++){
    const x=P.x+dx,y=P.y+dy;if(Math.max(Math.abs(dx),Math.abs(dy))!==r||tileSolid(MAPS.home,x,y))continue;
    Object.assign(P,{x,y,px:x*16,py:y*16,fx:x,fy:y,moving:false});S.x=x;S.y=y;ok=true;}
  const on=l.filter(k=>!MUEBLES[k].grow),gr=l.filter(k=>MUEBLES[k].grow);
  queue('mueble',async()=>{sfx('get');if(on.length)await say(`Llega el mensajero con ${yLista(on.map(k=>MUEBLES[k].art))}: te lo dejan montado en el salón.`);
    if(gr.length)await say(`Kiko te sube ${yLista(gr.map(k=>MUEBLES[k].art))} y te lo deja montado delante de las carpas.`);});
}
// el carro de esquejes (1.11): en la tabla de corte, los esquejes del propagador (S.esquejes, ESQUEJE_DIAS) se pinchan en las
// bandejas, donde aguantan CARRO.dias desde ese día hasta que haya hueco en una carpa; se plantan desde la plaza vacía (plantar)
async function carroAction(){
  const n=S.bandejas.length,cap=CARRO.bandejas*CARRO.plazas,o=[];
  if(S.esquejes.length&&n<cap)o.push('Pinchar esquejes');if(n)o.push('Ver las bandejas');o.push('Nada');
  const c=o[await ask(`El carro de esquejes: ${n} de ${cap} tacos ocupados.${S.esquejes.length?` En el propagador llevas ${S.esquejes.length}.`:''}`,o)];
  if(c==='Pinchar esquejes'){
    const m=Math.min(cap-n,S.esquejes.length);for(const e of S.esquejes.splice(0,m))S.bandejas.push({sid:e.sid,f:e.f,dia:S.day});sfx('sel');
    await say(`En la tabla de corte, corte en bisel y hormona: ${m>1?'pinchas '+m+' esquejes':'pinchas 1 esqueje'}.`);
    await say(`En las bandejas aguantan hasta el día ${S.day+CARRO.dias}: plántalos cuando haya hueco.`);
    const q=S.esquejes.length;if(q)return say(q>1?`No caben ${q}: se quedan en el propagador.`:'No cabe 1: se queda en el propagador.');
  }
  if(c==='Ver las bandejas'){const j=await menu(S.bandejas.map(e=>({label:'Esqueje '+getStrain(e.sid).n+etiq(e.f),right:'día '+(e.dia+CARRO.dias),sw:getStrain(e.sid).c,ic:iconoCogollo(e.sid),
    desc:`Pinchado el día ${e.dia}. Plántalo en una plaza vacía antes de que acabe el día ${e.dia+CARRO.dias}.\nPulsa A para ponerle nombre o tirarlo.`})).concat([{label:'Volver',desc:''}]),{cls:'full',title:'BANDEJAS',title2:`${n} de ${cap}`,desc:true});
    if(j>=0&&j<n)await esquejeAccion(S.bandejas[j],S.bandejas);}
}

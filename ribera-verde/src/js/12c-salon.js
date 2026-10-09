/* =========================================================
   SALÓN (1.10): a la derecha del piso (x 12-17), vacío al llegar; los muebles se compran por internet (el ordenador de
   la tía, el PC gaming o el móvil) y llegan al día siguiente (newDay → llegaMueble), montados por montarCasa.
   Cada uno ocupa 2 casillas: k en (x, y) y k+'2' en (x+1, y), que no se pinta (arteObj) y hace lo mismo al tocarlo.
   ========================================================= */
const MUEBLES={
  sofa:{n:'Sofá de 2 plazas',art:'el sofá',p:399,x:13,y:5,d:'Sofá de 180 cm, de tela azul, mirando a la tele. Para echar una cabezada sin meterte en la cama.'},
  tv:{n:'Tele de 43" con mueble',art:'la tele',p:449,x:13,y:2,d:'Smart TV de 43 pulgadas y un mueble bajo de 140 cm con hueco para la consola. Noticias y documentales.'},
  gpc:{n:'PC gaming con mesa',art:'el PC gaming',p:1490,x:16,y:2,d:'Torre con gráfica, monitor de 27", teclado mecánico y mesa de 140 cm con LED. Para jugar, leer el foro de cultivo y comprar.'}};
const SEGUNDA=new Set(Object.keys(MUEBLES).map(k=>k+'2'));
const muebleDe=o=>o&&(MUEBLES[o]?o:SEGUNDA.has(o)?o.slice(0,-1):null);
const mueblesYa=()=>Object.keys(MUEBLES).filter(k=>S.muebles&&S.muebles[k]&&S.muebles[k]<=S.day);
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
    const ks=Object.keys(MUEBLES),ya=mueblesYa();
    const items=ks.map(k=>{const m=MUEBLES[k],en=ya.includes(k),pd=!en&&S.muebles&&S.muebles[k];
      return {label:m.n+(en?' · en casa':pd?' · pedido':''),right:eur(m.p),disabled:!!(en||pd),desc:m.d+(en?'':pd?'\nLlega mañana: te lo suben al salón.':'\nLlega mañana y te lo suben al salón.')};});
    items.push({label:'Salir',desc:'Pagas con lo que llevas y, si no llega, con la caja fuerte.'});
    i=await menu(items,{cls:'full',title:'TIENDA ONLINE',title2:'Muebles · tienes '+eur(S.money+cajaE()),desc:true,initial:i});
    if(i<0||i>=ks.length)return;
    const k=ks[i],m=MUEBLES[k];
    if(S.money+cajaE()<m.p){sfx('bad');await say('No te llega el dinero.');continue;}
    pagarCasa(m.p);(S.muebles||(S.muebles={}))[k]=S.day+1;sfx('coin');toast('Pedido: '+m.n+' · llega mañana',1400);
  }
}
function llegaMueble(){
  const l=Object.keys(MUEBLES).filter(k=>S.muebles&&S.muebles[k]===S.day);if(!l.length)return;
  montarCasa();
  // si estás donde lo montan, te apartas a la casilla libre más cercana (de dentro afuera; arriba, abajo, izquierda, derecha)
  if(S.map==='home'&&tileSolid(MAPS.home,P.x,P.y))for(let r=1,ok=false;r<4&&!ok;r++)for(let dy=-r;dy<=r&&!ok;dy++)for(let dx=-r;dx<=r&&!ok;dx++){
    const x=P.x+dx,y=P.y+dy;if(Math.max(Math.abs(dx),Math.abs(dy))!==r||tileSolid(MAPS.home,x,y))continue;
    Object.assign(P,{x,y,px:x*16,py:y*16,fx:x,fy:y,moving:false});S.x=x;S.y=y;ok=true;}
  queue('mueble',async()=>{sfx('get');await say(`Llega el mensajero con ${yLista(l.map(k=>MUEBLES[k].art))}: te lo dejan montado en el salón.`);});
}

/* =========================================================
   EL BAJO DE LAS SETAS (1.20): el local clandestino de la Kale Zaharra
   ========================================================= */
// Txomin, el setero viejo de la Kale Zaharra, alquila el bajo de su casa desde el capítulo SETAS.ch (fianza y SETAS.dia al día, que
// cobra cada mañana; sin él, cambia la cerradura y se queda la fianza y lo que haya dentro). Él prepara las bandejas (SETAS.bandeja €
// cada una, hasta SETAS.max): tú las tienes húmedas (PULVERIZAR, 10 min, las deja a 100; cada día pierden SETAS.seca) y esperas:
// SETAS.colon días el micelio coge la bandeja, SETAS.fruto días más y están listas. Cada mañana, cada bandeja puede contaminarse
// (SETAS.cont; SETAS.contSeca más si está por debajo de la mitad de humedad) y, a 0, se seca: las dos se tiran. Lo cosechado se seca
// en el bajo (S.setas.g) y Txomin te lo compra a SETAS.precio el gramo (calor +SETAS.calor). Una redada en el bajo (SETAS.redada al
// día con bandejas) se lo lleva todo, el local incluido
const SETAS={ch:4,fianza:1500,dia:20,max:6,bandeja:45,colon:6,fruto:4,seca:34,cont:.02,contSeca:.15,g:[25,40],precio:9,calor:3,redada:.01,calorRedada:15,min:10};
const FASES_SETA={colonizando:['colonizando','colonizando'],fructificando:['fructificando','fructificando'],lista:['lista','listas'],contaminada:['contaminada','contaminadas'],seca:['seca','secas']};
const faseSeta=b=>b.mala?b.mala:S.day-b.d<SETAS.colon?'colonizando':S.day-b.d<SETAS.colon+SETAS.fruto?'fructificando':'lista';
function setasDia(){
  const L=S.setas;if(!L)return;
  if(S.money<SETAS.dia){S.setas=null;queue('setas',()=>talk('SMS · TXOMIN',['No me has pagado el bajo. Cambio la cerradura; lo de dentro y la fianza, para mí.']));return;}
  S.money-=SETAS.dia;
  const vivas=L.bandejas.filter(b=>!b.mala);if(!vivas.length)return;
  if(Math.random()<SETAS.redada){S.setas=null;S.heat=Math.min(100,S.heat+SETAS.calorRedada);sfx('bad');
    queue('setas',()=>say(`La policía ha entrado en el bajo de la Kale Zaharra. Se lleva las bandejas${L.g>=1?' y '+gTxt(L.g)+' de setas':''}.`));return;}
  const malas=[];
  for(const b of vivas){
    b.hum=Math.max(0,b.hum-SETAS.seca);
    if(!b.hum){b.mala='seca';malas.push('seca');continue;}
    if(faseSeta(b)!=='lista'&&Math.random()<SETAS.cont+(b.hum<50?SETAS.contSeca:0)){b.mala='contaminada';malas.push('contaminada');}
  }
  if(malas.length)queue('setas',()=>talk('SMS · TXOMIN',[malas.length>1?`Se te han echado a perder ${malas.length} bandejas. Tíralas.`:`Una bandeja se te ha ${malas[0]==='seca'?'secado':'contaminado'}. Tírala.`]));
}
// pulverizar las bandejas vivas (SETAS.min): false si, pasada la medianoche, setasDia ha cerrado el bajo
async function pulverizarBajo(){
  const L=S.setas;L.bandejas.filter(b=>!b.mala).forEach(b=>b.hum=100);advanceTime(SETAS.min);updateHUD();if(!S.setas)return false;sfx('sel');
  const v=L.bandejas.filter(b=>!b.mala);   // pasada la medianoche, setasDia ya las ha secado (o echado a perder)
  await say(v.length?`Pulverizas las bandejas: humedad al ${Math.round(v.reduce((a,b)=>a+b.hum,0)/v.length)} %.`:'Pulverizas las bandejas.');return true;
}
// Txomin y su bajo, en la Kale Zaharra (1.34: el bajo, por la puerta de al lado, 11j-locales)
NPCDEF.push({id:'txomin',map:'callejon',x:17,y:8,dir:'down',look:'txomin',talk:()=>talkTxomin()});
async function talkTxomin(){
  const T='TXOMIN',L=S.setas;
  if(S.ch<SETAS.ch)return say('¿Setas? Eso era antes, chaval. Ahora solo paseo.',T);
  if(!L){
    if(await ask(`El bajo de mi casa: oscuro, húmedo y nadie pregunta. ${eur(SETAS.fianza)} de fianza y ${eur(SETAS.dia)} al día, que te cobro cada mañana. Las bandejas te las preparo yo.`,['Alquilarlo','No'],T)!==0)return;
    if(S.money<SETAS.fianza){sfx('bad');return say('Sin la fianza no hay llave.',T);}
    S.money-=SETAS.fianza;S.setas={bandejas:[],g:0};sfx('coin');await got('la llave del bajo');
    return say('Compra las bandejas y tenlas húmedas. Lo demás lo hace el tiempo.',T);
  }
  return bajoMenu(T);
}
// las bandejas del bajo: con Txomin, en la puerta (T), todo; 1.34: dentro, en las baldas (sin T), lo de las bandejas: ni comprar
// (las prepara él), ni venderle, ni dejar el bajo
async function bajoMenu(T){
  const L=S.setas;
  for(;;){
    const B=L.bandejas,n=k=>B.filter(b=>faseSeta(b)===k).length,hum=B.filter(b=>!b.mala);
    const est=B.length?Object.keys(FASES_SETA).filter(k=>n(k)).map(k=>`${n(k)} ${FASES_SETA[k][n(k)>1?1:0]}`).join(', '):'sin bandejas';
    const ops=(T&&B.length<SETAS.max?[`Comprar bandeja (${eur(SETAS.bandeja)})`]:[]).concat(hum.length?['Pulverizar']:[],n('lista')?['Recoger']:[],B.some(b=>b.mala)?['Tirar las malas']:[],T&&L.g>=1?[`Venderle ${gTxt(L.g)}`]:[],T?['Dejar el bajo']:[],['Nada']);
    const op=ops[await ask(`El bajo: ${est}${hum.length?' · humedad '+Math.round(hum.reduce((a,b)=>a+b.hum,0)/hum.length)+' %':''}.`+(T||B.length?'':' Las bandejas las prepara Txomin, en la puerta.'),ops,T||undefined)];
    if(!op||op==='Nada')return;
    if(op.startsWith('Comprar')){if(S.money<SETAS.bandeja){sfx('bad');await say('Sin dinero no hay bandeja.',T);continue;}
      S.money-=SETAS.bandeja;B.push({d:S.day,hum:100});sfx('coin');await say(`Lista para colonizar. En ${SETAS.colon} días la habrá cogido el micelio; ${SETAS.fruto} más y a recoger.`,T);continue;}
    if(op==='Pulverizar'){if(!await pulverizarBajo())return;continue;}
    if(op==='Recoger'){let g=0;L.bandejas=B.filter(b=>{if(faseSeta(b)!=='lista')return true;g+=ri(SETAS.g[0],SETAS.g[1]);return false;});L.g+=g;sfx('get');
      await say(`Recoges las setas y las dejas secando en el bajo: ${g} g.`);continue;}
    if(op==='Tirar las malas'){const k=B.filter(b=>b.mala).length;L.bandejas=B.filter(b=>!b.mala);await say(k>1?`Tiras ${k} bandejas.`:'Tiras la bandeja.');continue;}
    if(op.startsWith('Venderle')){const g=Math.floor(L.g),e=g*SETAS.precio;L.g-=g;S.money+=e;S.sales+=e;S.heat=Math.min(100,S.heat+SETAS.calor);sfx('coin');
      toast(`+${eur(e)} · ${g} g de setas`,1600);await say(`Para mis clientes de siempre. ${eur(e)}.`,T);await checkStory();continue;}
    if(op==='Dejar el bajo'){if(await ask(`¿Dejas el bajo? Te devuelvo la fianza; lo que haya dentro se queda.`,['Dejarlo','No'],T)!==0)continue;
      S.setas=null;S.money+=SETAS.fianza;sfx('coin');return say('Como quieras. La puerta, cerrada al salir.',T);}
  }
}

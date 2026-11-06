/* ---------- la caja fuerte y la nevera por dentro (1.36, lo pidió el usuario) ----------
   Al abrirlas se ven por dentro (14-render; Godot, rects_almacen en trama): en la caja fuerte, los fajos de billetes y los tarros
   de cogollos según lo lleno que está (CAJA[nivel].money y .g, por porcentajes); en la nevera, un piso por tipo de extracción
   (EXTR, en su orden) con sus tarros de mayor a menor THC. Con las flechas se elige (las filas corren en carrusel) y con A se
   saca o se abre el menú del dinero; B cierra. ALMACEN = {t: 'caja' | 'nevera', i: el elegido}. Todo son rectángulos [x, y, w, h,
   color] en la pantalla, como la mesa del billar, y sprites ['@', nombre, x, y] (misc:alm-*, a mano en almacen.py, con el ancla
   arriba a la izquierda). En la caja, el primer tarro es GUARDAR (+) y, en la nevera, la fila de arriba; a la derecha, la ventana
   del elegido (panelAlmacen). */
const NEVERA={g:200};   // gramos de extracto que caben en la nevera
const ALM={fajos:12,tarros:8,fila:4,piso:8};   // los fajos del dinero, los tarros a la vista en la caja (2 filas de 4) y en cada piso de la nevera
const COLOR_EXTR={rosin:'#e0a828',seco:'#cdb878',ice:'#f2e2a4',charas:'#6a4426',hash:'#8a5a32',moon:'#7a9a48',stat:'#f6ecc8'};
let ALMACEN=null;
const porTHC=L=>Object.entries(L).sort((a,b)=>b[1].thc-a[1].thc||(a[0]<b[0]?-1:1));
// lo que se puede elegir: en la caja, el dinero y los tarros (cogollos y luego extractos, de mayor a menor THC); en la nevera, por pisos
function itemsAlmacen(t){
  if(t==='caja')return [{k:'$'},{k:'+'}].concat(porTHC(S.caja.buds).map(([k,b])=>({k,b,r:0})));   // +: GUARDAR, el primer tarro (vacío)
  const o=[{k:'+',s:-1,j:0}];TIPOS_EXTR().forEach((e,s)=>porTHC(nevera().rosin).filter(([k])=>tipoExtr(k)===e).forEach(([k,b],j)=>o.push({k,b,r:1,s,j})));return o;
}
// las flechas: en la caja, ← → de uno en uno y ↑ ↓ de fila en fila; en la nevera, ← → dentro del piso y ↑ ↓ al piso con algo más cerca
function mueveAlmacen(A,b){
  const it=itemsAlmacen(A.t),n=it.length,i=A.i;if(!n)return false;
  let j=i;
  if(A.t==='caja'){
    if(b==='left')j=i-1;else if(b==='right')j=i+1;else if(b==='up')j=i<=ALM.fila?0:i-ALM.fila;else if(b==='down')j=i===0?1:i+ALM.fila;
    j=Math.max(0,Math.min(n-1,j));
  }else{
    const c=it[i];
    if(b==='left'&&c.j>0)j=i-1;else if(b==='right'&&i+1<n&&it[i+1].s===c.s)j=i+1;
    else if(b==='up'||b==='down'){const d=b==='up'?-1:1;let mejor=-1;
      for(let s=c.s+d;s>=-1&&s<TIPOS_EXTR().length&&mejor<0;s+=d){const en=it.map((x,q)=>[x,q]).filter(([x])=>x.s===s);if(en.length)mejor=en[Math.min(c.j,en.length-1)][1];}
      if(mejor>=0)j=mejor;}
  }
  if(j===i)return false;A.i=j;return true;
}
const pctTxt=p=>Math.round(p*100)+' %';
// lo que dice el cuadro de texto del elegido
function descAlmacen(A){
  const it=itemsAlmacen(A.t)[A.i];
  if(A.t==='caja'){
    const C=CAJA[S.caja.nivel],g=cajaG();
    if(it&&it.k==='+')return `GUARDAR: llevas ${gTxt(totalBuds())} de cogollos y en la caja caben ${gTxt(Math.max(0,C.g-g))} más.${S.items.tarros?` Con los tarros se curan en ${CURADO.dias} días.`:''}\nA: guardar · B: cerrar.`;
    if(!it||it.k==='$')return `Dinero: ${eur(S.caja.money)} de ${eur(C.money)} (${pctTxt(S.caja.money/C.money)}). Tarros: ${gTxt(g)} de ${kgTxt(C.g)} (${pctTxt(g/C.g)}).\nA: guardar o sacar · B: cerrar.`;
    return `${it.r?extrNombre(it.k):lotNombre(it.k)}: ${it.r?coma(it.b.g):Math.floor(it.b.g)} g · ${pct(it.b.thc)} % THC${it.r?(it.b.cu>=1?' · curado':''):curaCorto(it.b)}.\nA: sacarlo · B: cerrar.`;
  }
  const r=neveraR();
  if(!it||it.k==='+')return `GUARDAR: llevas ${coma(Math.round(totalRosin()*10)/10)} g de extractos y en la nevera caben ${coma(Math.max(0,Math.floor((NEVERA.g-r)*10+1e-9)/10))} g más.${S.items.tarros?` En los tarros, en frío, se curan en ${CURADO.dias} días.`:' Con tarros, se curarían en frío.'}\nA: guardar · B: cerrar.`;
  return `${extrNombre(it.k)}: ${coma(it.b.g)} g · ${pct(it.b.thc)} % THC · ${it.b.cu>=1?'curado':it.b.cu?'curándose':'sin curar'}. Nevera: ${coma(Math.round(r*10)/10)} g de ${NEVERA.g} (${pctTxt(r/NEVERA.g)}).\nA: sacarlo · B: cerrar.`;
}
function dlgFijo(t,n){dlg.hidden=false;dlgName.hidden=!n;dlgName.textContent=n||'';dlgMore.hidden=true;dlgText.textContent=nm(t);}
// la vista: hasta que eliges (A) o cierras (B: null); i0, el que sale elegido
async function elegirAlmacen(t,i0=0){
  const n=itemsAlmacen(t).length;ALMACEN={t,i:Math.max(0,Math.min(n-1,i0))};const N=t==='caja'?'CAJA FUERTE':'NEVERA';
  const muestra=()=>dlgFijo(descAlmacen(ALMACEN),N);muestra();
  const r=await new Promise(res=>push(b=>{
    if(b==='B'){pop();res(null);return;}
    if(b==='A'){const it=itemsAlmacen(t)[ALMACEN.i];if(it){pop();res(Object.assign({i:ALMACEN.i},it));}return;}
    if(mueveAlmacen(ALMACEN,b)){sfx('sel');muestra();}}));
  ALMACEN=null;dlg.hidden=true;return r;
}
// un tarro de w × h en (x, y), a escala k: por dentro, lo que lleva (den: alm-cog-p/-s o alm-x-<tipo>, almacen.py) a su nivel,
// de 1 a 4 cuartos de f (0-1), sobre el color c (el de la variedad, que asoma por los cogollos) o, en los botes, el v de detrás
// del cristal (en la nevera, el blanco); encima, el cristal y la tapa (spr: alm-tarro, alm-tarro-s o alm-bote; -g al doble) y la
// etiqueta de papel con el sello verde del curado (1.36.1; 1.36.2, lo pidió el usuario: cada cosa, como es)
function tarro(o,x,y,w,h,c,f,cu,spr,den,k=1,v='#2a343a'){
  const g=k>1?'-g':'',n=Math.max(1,Math.min(4,Math.ceil(f*4-1e-9)));
  o.push([x+k,y+4*k,(w-2)*k,(h-5)*k,w>=14?c:v],['@',den+'-'+n+g,x+k,y+4*k],['@',spr+g,x,y]);
  if(w>=14){const yl=y+Math.round(h/2)*k;o.push(['@','alm-etiqueta'+g,x+4*k,yl]);if(cu)o.push([x+11*k,yl+k,2*k,2*k,'#3f8a46']);}
  else if(cu)o.push([x+(w-3)*k,y+4*k,2*k,2*k,'#58c070']);
}
// lo de dentro de un lote: los cogollos pelados (manicurados) o sin pelar; el extracto por su tipo, y el rosin curado, cremoso
function dentroLote(k,b,r){
  if(!r)return 'alm-cog-'+((b.mc||0)>=1?'p':'s');
  const t=tipoExtr(k);return 'alm-x-'+t+(t==='rosin'&&(b.cu||0)>=1?'-cu':'');
}
// el marco amarillo del elegido
const marco=(o,x,y,w,h)=>o.push([x,y,w,1,'#f8d040'],[x,y+h-1,w,1,'#f8d040'],[x,y,1,h,'#f8d040'],[x+w-1,y,1,h,'#f8d040']);
const colorLote=k=>(getStrain(lotSid(k))||{}).c||'#7aa63e';
// la ventana del elegido (lo pidió el usuario), a la derecha: en grande y con sus barras (THC, curado y manicurado o gramos;
// en el dinero, lo lleno de la caja; en GUARDAR, lo que llevas y lo que cabe)
function panelAlmacen(o,A,px,py){
  const it=itemsAlmacen(A.t)[A.i],barra=(n,ic,f,c)=>{const y=py+66+n*10;o.push(['@','alm-ic-'+ic,px+4,y-1],[px+15,y,Math.round(40*Math.max(0,Math.min(1,f))),5,c]);};
  o.push(['@','alm-panel',px,py]);if(!it)return;
  const caja=A.t==='caja',C=caja&&CAJA[S.caja.nivel];
  if(it.k==='$'){const n=S.caja.money>0?Math.max(1,Math.ceil(Math.min(1,S.caja.money/C.money)*3)):0;
    for(let q=0;q<n;q++)o.push(['@','alm-fajo-g',px+15,py+38-q*12]);
    barra(0,'eur',S.caja.money/C.money,'#7cc07a');barra(1,'cu',cajaG()/C.g,'#d8b048');return;}
  if(it.k==='+'){o.push(['@','alm-mas-g',px+12,py+8]);barra(0,'g',pesoEncima()/capMochila(),'#e0a040');barra(1,'cu',caja?cajaG()/C.g:neveraR()/NEVERA.g,'#58b0e0');return;}
  if(!it.r){tarro(o,px+12,py+8,18,25,colorLote(it.k),it.b.g/(C.g/ALM.tarros),it.b.cu>=1,it.k.includes('*')?'alm-tarro-s':'alm-tarro',dentroLote(it.k,it.b),2);
    barra(0,'thc',it.b.thc/30,'#e8d070');barra(1,'cu',it.b.cu||0,'#58c070');barra(2,'mc',it.b.mc||0,'#a0c8f0');return;}
  const cap=NEVERA.g/ALM.piso/3;tarro(o,px+18,py+20,12,12,COLOR_EXTR[tipoExtr(it.k)],it.b.g/cap,it.b.cu>=1,'alm-bote',dentroLote(it.k,it.b,1),2);
  barra(0,'thc',it.b.thc/90,'#e8d070');barra(1,'cu',it.b.cu||0,'#58c070');barra(2,'g',it.b.g/cap,'#e0a040');
}
// la vista: la caja (168 × 100) o la nevera (152 × 120) y, a su derecha, la ventana del elegido (60 × 100), centradas juntas
function rectsAlmacen(A){
  const o=[],it=itemsAlmacen(A.t);
  if(A.t==='caja'){
    const C=CAJA[S.caja.nivel],x0=(SW-232)>>1,y0=4,pm=Math.min(1,S.caja.money/C.money),pg=Math.min(1,cajaG()/C.g);
    o.push(['@','alm-caja',x0,y0]);
    // el dinero: los fajos llenos según lo que hay (por porcentaje), y su barra
    const nf=S.caja.money>0?Math.max(1,Math.ceil(pm*ALM.fajos)):0;
    for(let q=0;q<ALM.fajos;q++){const x=x0+8+(q%3)*17,y=y0+52-Math.floor(q/3)*12;
      if(q<nf)o.push(['@','alm-fajo',x,y]);else o.push([x,y+6,15,2,'#22252c']);}
    o.push([x0+8,y0+70,49,6,'#2a2d34'],[x0+9,y0+71,Math.round(47*pm),4,'#7cc07a']);
    if(A.i===0)marco(o,x0+6,y0+8,53,66);
    // los tarros: dos baldas de cuatro, en carrusel por filas; el primero, GUARDAR; cada uno, lleno según su parte de la capacidad
    const jar=it.slice(1),sel=A.i-1,fila0=sel<ALM.fila?0:Math.floor(sel/ALM.fila)-1,cap=C.g/ALM.tarros;
    for(let f=0;f<2;f++){const y=y0+8+f*34;
      for(let c=0;c<ALM.fila;c++){const q=(fila0+f)*ALM.fila+c,J=jar[q];if(!J)continue;const x=x0+69+c*23;
        if(J.k==='+')o.push(['@','alm-mas',x,y]);
        else tarro(o,x,y,18,25,colorLote(J.k),J.b.g/cap,J.b.cu>=1,J.k.includes('*')?'alm-tarro-s':'alm-tarro',dentroLote(J.k,J.b));
        if(q===sel)marco(o,x-2,y-2,22,29);}}
    if(fila0>0)o.push([x0+160,y0+8,2,1,'#f8d040'],[x0+159,y0+9,4,1,'#f8d040']);   // hay más arriba
    if(jar.length>(fila0+2)*ALM.fila)o.push([x0+159,y0+71,4,1,'#f8d040'],[x0+160,y0+72,2,1,'#f8d040']);   // y abajo
    o.push([x0+68,y0+82,92,6,'#2a2d34'],[x0+69,y0+83,Math.round(90*pg),4,'#d8b048']);
    panelAlmacen(o,A,x0+172,y0);
    return o;
  }
  // la nevera: GUARDAR arriba, un piso de cristal por tipo y, a la derecha, lo lleno que está
  const x0=(SW-216)>>1,y0=4,p=Math.min(1,neveraR()/NEVERA.g),c=it[A.i];
  o.push(['@','alm-nevera',x0,y0],['@','alm-guardar',x0+6,y0+5]);
  if(c&&c.k==='+')marco(o,x0+5,y0+4,46,13);
  TIPOS_EXTR().forEach((e,s)=>{
    const y=y0+19+s*14,L=it.filter(x=>x.s===s),off=c&&c.s===s?Math.max(0,c.j-ALM.piso+1):0;
    o.push([x0+6,y+2,5,10,COLOR_EXTR[e]],[x0+6,y+2,5,1,'#ffffff']);
    L.slice(off,off+ALM.piso).forEach((J,q)=>{const x=x0+15+q*15;tarro(o,x,y+1,12,12,COLOR_EXTR[e],J.b.g/(NEVERA.g/ALM.piso/3),J.b.cu>=1,'alm-bote',dentroLote(J.k,J.b,1),1,'#c4d6dc');
      if(c&&c.s===s&&J.j===c.j)marco(o,x-2,y-1,16,16);});
    if(off>0)o.push([x0+12,y+6,1,3,'#f8a020'],[x0+11,y+7,1,1,'#f8a020']);
    if(L.length>off+ALM.piso)o.push([x0+136,y+6,1,3,'#f8a020'],[x0+137,y+7,1,1,'#f8a020']);
  });
  const hb=Math.round(94*p);o.push([x0+143,y0+20+94-hb,3,hb,'#58b0e0']);
  panelAlmacen(o,A,x0+156,y0);
  return o;
}
// GUARDAR (1.36, lo pidió el usuario): el primer tarro de la caja (los cogollos que llevas) y la fila de arriba de la nevera (los
// extractos): todo lo que quepa o un lote
async function guardarAlmacen(t){
  const caja=t==='caja',L=caja?budLots(1):rosinLots(.1),de=caja?S.buds:S.rosin,a=caja?S.caja.buds:nevera().rosin,min=caja?1:.1,mueve=caja?moverLote:moverRosin;
  const hueco=()=>caja?Math.floor(CAJA[S.caja.nivel].g-cajaG()):Math.floor((NEVERA.g-neveraR())*10+1e-9)/10;
  if(!L.length)return say(caja?'No llevas cogollos encima.':'No llevas extractos encima.');
  if(hueco()<min)return say(caja?'En la caja no caben más cogollos.':'En la nevera ya no cabe más.');
  const j=await ask(caja?'¿Qué guardas en la caja?':'¿Qué guardas en la nevera?',[caja?'Todos los cogollos':'Todos los extractos',caja?'Un lote':'Un extracto','Nada']);
  if(j===0){let q=0;for(const [k,b] of L){const g=Math.min(b.g,hueco());if(g<min)break;q+=g;mueve(de,a,k,g);}
    sfx('sel');return say(`Guardas ${caja?gTxt(q):coma(Math.round(q*10)/10)+' g'} en ${caja?'la caja':'la nevera'}.${(caja?totalBuds()>=1:totalRosin()>=.1)?' No cabe todo: el resto se queda fuera.':''}`);}
  if(j!==1)return;
  const i=await menu(L.map(caja?lotItem:rosinItem).concat([{label:'Nada'}]),{cls:'right',title:'¿Qué guardas?'});if(i<0||i>=L.length)return;
  const [k,b]=L[i],g=await cuanto(`${caja?lotNombre(k):extrNombre(k)}: ¿cuánto?`,caja?Math.min(Math.floor(b.g),hueco()):Math.min(b.g,hueco()),caja?[10,50,100,500,1000]:[1,5,10,50],caja?gTxt:q=>coma(q)+' g');if(!g)return;
  mueve(de,a,k,g);sfx('sel');
}
// la nevera (1.36): en la vista, GUARDAR arriba y, en los pisos, sacar un extracto
async function neveraAction(){
  let i=0;
  for(;;){const e=await elegirAlmacen('nevera',i);if(!e)return;i=e.i;
    if(e.k==='+'){await guardarAlmacen('nevera');continue;}
    const g=Math.min(e.b.g,Math.floor(libreMochila()*10+1e-9)/10);
    if(g<.1){await say('No te cabe nada más encima.');continue;}
    moverRosin(nevera().rosin,S.rosin,e.k,g);sfx('sel');await say(`Sacas ${coma(g)} g de ${extrNombre(e.k,1)}.`);}
}
// la mesa de manicurar (1.36, junto a la de genética): tijeras, guantes y bandeja; pela un lote de los que llevas encima
async function manicuraAction(){
  if(extrYa().includes('charas')){const j=await ask('La mesa de manicurar. ¿Qué haces?',['Manicurar un lote',EXTR.charas.v,'Nada']);if(j===1)return extraer('charas');if(j!==0)return;}
  const lots=budLots(1).filter(([,b])=>(b.mc||0)<1);
  if(!lots.length)return say(`La mesa de manicurar: tijeras de punta fina, guantes y una bandeja con rejilla. ${totalBuds()>=1?'Lo que llevas ya está manicurado.':'Trae cogollos para pelarlos.'}`);
  const i=await menu(lots.map(lotItem).concat([{label:'Nada'}]),{cls:'right',title:'Manicurar: ¿qué lote?'});
  if(i<0||i>=lots.length)return;
  const [k,b]=lots[i],m=Math.min(MANICURA.max,Math.max(15,Math.round(b.g*(1-(b.mc||0))*MANICURA.min)));
  await say('Con las tijeras, cogollo a cogollo: fuera las hojitas con poca resina, que quede limpio y redondo.','MANICURA');
  b.mc=1;advanceTime(m);sfx('get');
  await say(`${lotNombre(k)}: ${gTxt(b.g)} manicurados en ${m>=60?Math.floor(m/60)+' h'+(m%60?' '+m%60+' min':''):m+' min'}. Se venden un ${pct0(MANICURA.precio)} % más caros.`);
}
// un mueble por máquina (1.36, lo pidió el usuario), montado en el piso cuando la tienes (montarCasa): la prensa (rosin, hachís y
// moonrock), los tamices, el cubo con las mallas, la lavadora y la static; el charas, en la mesa de manicurar
// 1.36.2 (lo pidió el usuario: en medio cortaban el paso del salón a la cama y la nevera): el taller, en fila contra la pared de
// abajo, a los dos lados de la puerta: lavadora, cubo, static y manicura a la izquierda; prensa y tamices a la derecha
const MUEBLE_EXTR={prensaM:{x:6,y:7,item:'prensa',t:['rosin','hash','moon'],n:'La prensa de rosin, en su mesita'},tamizM:{x:7,y:7,item:'tamiz',alt:'mallas00',t:['seco'],n:'Los tamices de seda, en su bastidor'},
  mallas:{x:2,y:7,item:'ice',t:['ice'],n:'El cubo con las bolsas de malla'},lavadora:{x:1,y:7,item:'lavadora',t:['lava'],n:'La lavadora de extracción'},staticM:{x:3,y:7,item:'estatica',t:['stat'],n:'La máquina de static'}};
const muebleYa=E=>!!(S.items[E.item]||E.alt&&S.items[E.alt]);
async function muebleExtr(o){
  const M=MUEBLE_EXTR[o],ya=extrYa(),L=M.t.filter(t=>ya.includes(t));
  if(!L.length)return say(M.n+'.');
  if(L.length===1)return extraer(L[0]);
  const j=await ask(M.n+'. ¿Qué haces?',L.map(t=>EXTR[t].v).concat(['Nada']));if(j>=0&&j<L.length)return extraer(L[j]);
}

/* =========================================================
   PANTALLA: el juego a pantalla completa, en horizontal, con los mandos flotando encima
   Mide el hueco real (visualViewport, menos los márgenes seguros del notch) y fija:
   · la resolución del juego: 160 px de alto y el ancho que pida el móvil (SW, de 240 a 400, par), así la imagen llena
     la pantalla sin deformarse; en tablets más cuadradas que 3:2 se queda en 240 y sobran bandas arriba y abajo;
   · --u (CSS px por píxel del juego), con píxeles enteros si se pierde menos de un 6 % de alto;
   · los mandos en milímetros, donde descansa el pulgar (geoMandos);
   · el escenario de diálogos y menús (--uiw, --us): 240 px del juego centrados; si los mandos lo pisarían, se encoge
     hasta caber entre la cruceta y A/B (hasta la mitad, sin bajar de 1,3 px por píxel: letra de 13 px como mínimo) y,
     si SONIDO le cae encima, empieza debajo (--ut); la caja de vida del combate (#bP) se aparta de A, B y START (--bpr).
   En vertical sale el aviso de girar el móvil (la app de Android ya va fija en horizontal).
   ========================================================= */
let menuRedraw=null;   // menú abierto (07-interfaz): al cambiar el tamaño se vuelve a medir cuántas filas caben
// mandos en mm para el pulgar en reposo (1 px CSS = 1 dp = 1/160 de pulgada): cruceta de 24 mm (brazos de 8) con el centro a 16 mm
// del lado y 18 de abajo; A y B de 10,5 mm con 3,5 de hueco, inclinados 28° (B abajo a la izquierda), A a 12 mm del lado y 19 de
// abajo; START (15 × 7) encima de A, MÓVIL (igual) encima de la cruceta y SONIDO arriba a la derecha. Zonas de toque: 3 mm alrededor de la cruz y 2,5 alrededor de A/B
// (1 mm por el lado del escenario). Si el escenario (med px a cada lado del centro de la pantalla, que con márgenes seguros distintos
// no es el de la ventana) no cabe entre ellos, o no caben en alto, encogen: los tamaños y los márgenes de abajo y de arriba por f, y
// los de los lados por f³, que se van antes. Devuelve f, la mitad del ancho que les deja al escenario (med) y los rectángulos
// [x, y, ancho, alto] en px de la ventana.
const MM=160/25.4;
function geoMandos(W,H,il,ir,it,ib,med){
  const c=(W+il-ir)/2,ocupa=f=>{const s=f*MM,m=f*f*f*MM;return [il+4*m+25*s+2,ir+6.75*m+23.86*s+2,ib+35.25*s+it+10*s+MM];};   // +2 px: redondeos
  const cabe=([l,r,h])=>l+med<=c&&r+med<=W-c&&h<=H;
  let f=1;while(f>.3&&!cabe(ocupa(f)))f-=.005;
  const [l,r]=ocupa(f);
  const s=f*MM,m=f*f*f*MM,R=(x,y,w,h)=>[x,y,w,h].map(Math.round);
  const cx=il+4*m+12*s,cy=H-ib-18*s,dx=Math.max(il,cx-15*s),dy=cy-15*s;
  const ax=W-ir-6.75*m-5.25*s,ay=H-ib-19*s,bx=ax-12.361*s,by=ay+6.573*s,
    abx=bx-6.25*s,aby=ay-7.75*s,abr=Math.min(W-ir,ax+7.75*s),abb=Math.min(H-ib,by+7.75*s),stx=Math.min(ax,W-ir-8*s);
  return {f,k:s,med:Math.min(c-l,W-r-c),
    dpad:R(dx,dy,cx+13*s-dx,Math.min(H-ib,cy+15*s)-dy),cruz:R(cx-12*s,cy-12*s,24*s,24*s),
    ab:R(abx,aby,abr-abx,abb-aby),A:R(ax-5.25*s,ay-5.25*s,10.5*s,10.5*s),B:R(bx-5.25*s,by-5.25*s,10.5*s,10.5*s),
    start:R(stx-7.5*s,ay-16.25*s,15*s,7*s),movil:R(cx-7.5*s,cy-23*s,15*s,7*s),sonido:R(W-ir-4.5*m-15*s,it+3*s,15*s,7*s)};
}
function ajustarPantalla(){
  const el=$('consola');if(!el)return;
  const vv=window.visualViewport,W=vv?vv.width:innerWidth,H=vv?vv.height:innerHeight;
  const cs=getComputedStyle(el),pl=parseFloat(cs.paddingLeft)||0,pr=parseFloat(cs.paddingRight)||0,pt=parseFloat(cs.paddingTop)||0,pb=parseFloat(cs.paddingBottom)||0;
  const rim=Math.round(clamp(Math.min(W,H)*.008,2,5)),w=W-pl-pr-2*rim,h=H-pt-pb-2*rim;
  const girar=$('girar');if(girar)girar.hidden=!(h>w);
  const dpr=window.devicePixelRatio||1;
  let s=h/160;const k=Math.floor(s*dpr);if(k>=2&&k/dpr>=s*.94)s=k/dpr;
  let sw=clamp(Math.floor(w/s/2)*2,240,400);if(sw*s>w)s=w/sw;
  const cw=Math.floor(sw*s),ch=Math.floor(160*s),x=Math.round(pl+rim+(w-cw)/2),y=Math.round(pt+rim+(h-ch)/2);
  if(SW!==sw){SW=sw;cv.width=sw;ctx.imageSmoothingEnabled=false;}
  const usMin=Math.min(s,Math.max(s*.5,1.3)),G=geoMandos(W,H,pl,pr,pt,pb,120*usMin),us=clamp(G.med/120,usMin,s);
  const set=(n,v)=>el.style.setProperty(n,v+'px');
  set('--u',s);set('--us',us);set('--uiw',Math.min(cw,Math.round(240*us)));
  set('--sw',cw);set('--sh',ch);set('--sx',x);set('--sy',y);set('--k',G.k);
  const pon=(q,r,o)=>{const e=el.querySelector(q);if(e)[e.style.left,e.style.top,e.style.width,e.style.height]=r.map((v,i)=>v-(o&&i<2?o[i]:0)+'px');};
  pon('#dpad',G.dpad);pon('#dpad .cruz',G.cruz,G.dpad);pon('#ab',G.ab);pon('#ab [data-k=A]',G.A,G.ab);pon('#ab [data-k=B]',G.B,G.ab);
  pon('#bStart',G.start);pon('#bMovil',G.movil);pon('#bSound',G.sonido);
  const so=G.sonido,der=x+cw/2+Math.min(cw,Math.round(240*us))/2;
  set('--ut',so[0]<der&&so[1]+so[3]>y?Math.round(so[1]+so[3]-y+G.k*1.5):0);
  // el rótulo del título (RIBERA VERDE: 212 u de ancho y 3 de sombra) baja si SONIDO le pisa la esquina (--tt, arriba del texto)
  set('--tt',so[0]<x+cw/2+109*s&&so[1]+so[3]>y+20*s?Math.max(20*s,Math.round(so[1]+so[3]-y+G.k*1.5)):20*s);
  // caja de vida del jugador en el combate (#bP, abajo a la derecha de la escena, ~46u de alto): a la izquierda de A, B y START si le caen encima
  const er=x+cw/2+120*s,bb=y+ch-49*s;let bpr=6*s;
  for(const r of [G.A,G.B,G.start])if(r[1]<bb+G.k&&r[1]+r[3]>bb-46*s-G.k)bpr=Math.max(bpr,er-r[0]+G.k);
  set('--bpr',Math.round(Math.min(bpr,130*s)));
  if(menuRedraw)menuRedraw();
  colocaToast(true);
}
ajustarPantalla();
addEventListener('resize',ajustarPantalla);addEventListener('orientationchange',()=>setTimeout(ajustarPantalla,120));
if(window.visualViewport)visualViewport.addEventListener('resize',ajustarPantalla);
// web en el móvil: al primer toque, pantalla completa y bloqueo en horizontal (si el navegador lo deja; si no, queda el aviso)
addEventListener('pointerdown',function fijar(){
  removeEventListener('pointerdown',fijar);
  if(!matchMedia('(pointer:coarse)').matches)return;
  const de=document.documentElement;
  try{const p=de.requestFullscreen&&de.requestFullscreen({navigationUI:'hide'});if(p&&p.then)p.then(()=>screen.orientation&&screen.orientation.lock&&screen.orientation.lock('landscape').catch(()=>{})).catch(()=>{});}catch(e){}
},{passive:true});

/* =========================================================
   PANTALLA: el juego a pantalla completa, en horizontal, con los mandos flotando encima
   Mide el hueco real (visualViewport, menos los márgenes seguros del notch) y fija:
   · la resolución del juego: 160 px de alto y el ancho que pida el móvil (SW, de 240 a 400, par), así la imagen llena
     la pantalla sin deformarse; en tablets más cuadradas que 3:2 se queda en 240 y sobran bandas arriba y abajo;
   · --u (CSS px por píxel del juego), con píxeles enteros si se pierde menos de un 6 % de alto;
   · los mandos a tamaño de pulgar (--d cruceta, --ab A/B, --pill SONIDO/START, --m margen);
   · el escenario de diálogos y menús (--uiw, --us): 240 px del juego centrados; si los mandos lo pisarían, se encoge
     hasta caber entre la cruceta y A/B (hasta la mitad, sin bajar de 1,3 px por píxel: letra de 13 px como mínimo) y,
     si SONIDO/START le caen encima, empieza debajo de ellos (--ut).
   En vertical sale el aviso de girar el móvil (la app de Android ya va fija en horizontal).
   ========================================================= */
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
  const d=Math.round(clamp(H*.34,104,150)),ab=Math.round(d*.44),m=Math.round(clamp(H*.035,8,22)),pill=Math.round(clamp(H*.07,24,34));
  const col=Math.max(pl,pr)+m+Math.max(d,ab*2.25)+m*.5,us=clamp((W-2*col)/240,Math.min(s,Math.max(s*.5,1.3)),s);
  const set=(n,v)=>el.style.setProperty(n,v+'px');
  set('--u',s);set('--us',us);set('--uiw',Math.min(cw,Math.round(240*us)));
  set('--sw',cw);set('--sh',ch);set('--sx',x);set('--sy',y);set('--d',d);set('--ab',ab);set('--m',m);set('--pill',pill);
  const P=el.querySelector('.pills');let ut=0;
  if(P){const p=P.getBoundingClientRect(),der=x+cw/2+Math.min(cw,Math.round(240*us))/2;if(p.left<der&&p.bottom>y)ut=Math.round(p.bottom-y+m*.4);}
  set('--ut',ut);
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

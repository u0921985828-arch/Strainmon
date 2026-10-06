/* =========================================================
   PANTALLA: encaja la consola en cualquier móvil (y en tablet o PC)
   Mide el hueco real (visualViewport, sin las barras del sistema ni el teclado) y fija los límites de cada parte:
   --sw ancho de la pantalla del juego (3:2) · --d cruceta · --ab botones A/B · --pill SONIDO/START · --pb marco · --lbl etiqueta.
   Vertical: pantalla arriba a todo el ancho y mandos debajo (mínimo un tercio del alto para ellos).
   Horizontal (.land): cruceta | pantalla a toda la altura | A/B, con SONIDO y START debajo de cada lado.
   Si el ancho escalado queda a menos de un 8 % de un múltiplo entero de 240 píxeles físicos, se ajusta a él (píxeles nítidos).
   ========================================================= */
function ajustarPantalla(){
  const el=$('consola');if(!el)return;
  const vv=window.visualViewport,W=vv?vv.width:innerWidth,H=vv?vv.height:innerHeight,m=Math.min(W,H);
  const gap=Math.round(clamp(m*.025,6,14));el.style.setProperty('--gap',gap+'px');
  const cs=getComputedStyle(el),w=W-parseFloat(cs.paddingLeft)-parseFloat(cs.paddingRight),h=H-parseFloat(cs.paddingTop)-parseFloat(cs.paddingBottom);
  const land=w>h*1.05,pb=Math.round(clamp(m*.015,4,10)),pill=Math.round(clamp(m*.075,24,34));
  let sw,d,ab,lbl;
  if(land){
    lbl=h<420?0:Math.round(Math.min(16,h*.03));                       // horizontal bajo: sin etiqueta, todo el alto para el juego
    const lado=clamp(w*.17,120,260);                                     // ancho mínimo de cada lado para los mandos
    sw=Math.min(w-2*lado-2*gap-2*pb,(h-pb-lbl)*1.5,960);
    const side=(w-sw-2*pb-2*gap)/2;
    d=Math.min(side*.92,(h-pill-gap)*.62,200);ab=Math.min(d*.42,side/2.4);
  }else{
    lbl=Math.round(clamp(w*.035,10,16));
    const ctl=clamp(h*.34,170,330);                                      // alto mínimo para cruceta, A/B y START
    sw=Math.min(w-2*pb,(h-ctl-gap-pb-lbl)*1.5,960);
    const hc=h-(sw*2/3+pb+lbl)-2*gap-pill;
    d=Math.min(hc*.9,w*.44,210);ab=Math.min(d*.42,w*.2);
  }
  const dpr=window.devicePixelRatio||1,k=Math.floor(sw*dpr/240);
  if(k>=1&&k*240/dpr>=sw*.92)sw=k*240/dpr;
  sw=Math.max(120,Math.floor(sw*dpr)/dpr);
  el.classList.toggle('land',land);
  const set=(k,v)=>el.style.setProperty(k,Math.max(0,Math.round(v))+'px');
  el.style.setProperty('--sw',sw+'px');set('--d',Math.max(96,d));set('--ab',Math.max(40,ab));set('--pill',pill);set('--pb',pb);set('--lbl',lbl);
}
ajustarPantalla();
addEventListener('resize',ajustarPantalla);addEventListener('orientationchange',()=>setTimeout(ajustarPantalla,120));
if(window.visualViewport)visualViewport.addEventListener('resize',ajustarPantalla);

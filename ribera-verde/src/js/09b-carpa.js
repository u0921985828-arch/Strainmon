/* =========================================================
   VISTA DE CARPA · B (plan de producción, D1 y P2)
   En el piso (1 casilla = 1 m) cada carpa es un mueble de 1-2 casillas. A delante de ella la abre recortada en 3/4, como
   en la 1.6-1.7 (sin techo, sin frente y sin lateral derecho), pero a escala real: escena compuesta a 240 px, 48 px/m de
   ancho y de alto y 24 px/m de fondo; lo de atrás se corre 6 px/m a la derecha, así la pared izquierda se ve por dentro.
   La carpa tiene la espalda contra la pared del cuarto (y VB_PARED): la de 150 × 100 × 200 cm mide 72 × 120 px y una
   sativa lista, 67 px más su maceta.
   Las plazas van en filas de CARPAS[t].cols macetas: la fila 0 delante y la 1 detrás (pintada antes). Cada maceta va en el centro
   de su parte de la carpa, lo más separada posible, y la copa de su planta se dibuja como mucho del ancho que cabe sin tocar a las
   vecinas ni las paredes (distancia segura, q.cw) y como mucho del alto que deja la distancia al foco (FOCO_SEP, q.ch).
   ◀ ▶ cambian de plaza y ▲ ▼ de fila; desde la fila de atrás, ▲ elige el foco. A cuida la planta (potAction) o abre el
   foco y los extras (carpaAction); B sale. El tiempo no corre mientras se mira.
   Todo es procedural (y es la huella de las láminas de P3-P4, tools/sprites/huellas.js) hasta que lleguen esas láminas.
   Con el arte de la imagen A en el atlas, la carpa se ve por dentro a pantalla completa (vista C, abajo).
   ========================================================= */
const VB_M=.48,VB_F=.24,VB_X=.06,VB_PARED=126;   // px por cm de ancho y alto · de fondo · corrimiento a la derecha por cm de fondo · y de la pared
// porte de cada variedad para dibujar su planta (i: índica, s: sativa, h: híbrida); los híbridos propios, por sus días de floración
const PORTE={ria:'h',limon:'s',txoko:'i',niebla:'i',mango:'i',purpura:'i',rif:'i',hindu:'i',acapulco:'s',malawi:'s',citrus:'h',bluetx:'i',sollimon:'h',
  kushrif:'i',purpurah:'i',orotrop:'i',nieblamor:'h',brumaog:'s',reina:'i',amanecer:'s',tormenta:'s',dragon:'h',leyenda:'s',
  mich:'s',punto:'s',thai:'s',lao:'s',chitral:'i',nepal:'h',congo:'s',lamb:'s',kif:'i',beldia:'i',oaxaca:'s',panama:'s',haze:'s',nl:'i',afkush:'i',shiva:'i',silver:'h',ssh:'s'};
const porteDe=sid=>{if(PORTE[sid])return PORTE[sid];const d=(getStrain(sid)||{d:3.5}).d;return d<=3?'i':d>=4.5?'s':'h';};
// alto y ancho reales (cm, sin maceta) por fase: germinando, plántula, vegetativo, floración y lista. Las dos primeras, a ×2 para que se vean
const PLANTA_CM={i:{h:[10,30,45,75,90],w:[8,20,45,65,70]},s:{h:[10,30,70,120,140],w:[8,18,35,55,60]},h:{h:[10,30,55,95,110],w:[8,18,40,58,60]}};
// macetas: diámetro y alto (cm), cuerpo, borde y si es de tela
const MACETA_CM={plastico7:[22,20,'#2c2c30','#4a4a52',0],tela11:[25,22,'#45474e','#5e6068',1],plastico18:[30,28,'#2c2c30','#4a4a52',0],tela25:[35,26,'#7a6c50','#988a6c',1]};
const FOCO_CM={cfl:35,sodio250:45,sodio400:50,sodio600:55,led100:25,led200:30,led480:60,led720:100};   // ancho real de cada foco
// distancia segura (cm) de la cima de la planta al foco, la que se recomienda para no quemarla: el CFL casi no calienta; el sodio, mucho
const FOCO_SEP={cfl:10,led100:25,led200:25,led480:35,led720:40,sodio250:30,sodio400:40,sodio600:50},HOLGURA=4;   // HOLGURA: aire entre copas (cm)
const macetaPx=k=>{const [d,h]=MACETA_CM[k]||MACETA_CM.plastico7;return {w:Math.round(d*VB_M),e:Math.max(3,Math.round(d*VB_F)),hb:Math.round(h*VB_M)};};
let VC=null;                              // carpa abierta: {ci, sel: plaza (índice de huecos()) o −1 = el foco, ocupado}
// geometría de la carpa ci en la escena de 240: P(x, y, z) pasa cm (x desde la izquierda, y de fondo desde el frente, z de alto) a px
function vcGeo(ci){
  const c=S.carpas[ci],C=CARPAS[c.t],[W,H,D]=C.cm,w=Math.round(W*VB_M),s=Math.round(D*VB_X),x0=120-((w+s)>>1),yf=VB_PARED+Math.round(D*VB_F);
  const P=(x,y,z)=>[Math.round(x0+x*VB_M+y*VB_X),Math.round(yf-y*VB_F-z*VB_M)];
  // cada maceta en el centro de su parte (cx, cy en cm; una fila incompleta se reparte todo el ancho). La copa (cw) cabe en el
  // círculo que no toca a ninguna vecina ni las paredes, menos la HOLGURA; la planta (ch), bajo el foco a su FOCO_SEP sobre la maceta
  const pl=[];huecos().forEach((q,i)=>{if(q.c!==ci)return;
    const col=q.j%C.cols,fila=Math.floor(q.j/C.cols),n=Math.min(C.cols,C.plazas-fila*C.cols);
    pl.push({i,col,fila,cx:(col+.5)*W/n,cy:(fila+.5)*D/C.filas});});
  for(const a of pl){let d=2*Math.min(a.cx,W-a.cx,a.cy,D-a.cy);for(const b of pl)if(b!==a)d=Math.min(d,Math.hypot(a.cx-b.cx,a.cy-b.cy));
    a.cw=d-HOLGURA;a.ch=H-28-(FOCO_SEP[c.foco]||40)-(MACETA_CM[S.macetas[a.i]]||MACETA_CM.plastico7)[1];[a.x,a.y]=P(a.cx,a.cy,0);}
  // el foco, en el centro a medio fondo: fx su centro y fy su parte de abajo (a 28 cm del techo); barra: la barra de la que cuelga
  const g={c,C,W,H,D,w,s,x0,yf,P,pl,fx:P(W/2,D/2,0)[0],fy:P(0,D/2,H-28)[1],barra:P(0,D/2,H-4)[1]};
  g.vc=vistaC(g);if(g.vc){g.fx=120;g.fy=VCA.boca;g.fw=g.vc.foco.a;}
  return g;
}
// dónde lanzar un efecto sobre la plaza i (riego, cosecha): en la vista, sobre la planta; si no, sobre el jugador
function posPlaza(i){
  const q=VC&&vcGeo(VC.ci).pl.find(q=>q.i===i);if(!q)return [P.px+8,P.py+2];
  if(q.v)return [q.x,q.y-q.v.tierra-(q.v.hp>>1)];
  const p=S.pots[i],h=p?altoPlanta(p,q):0;return [q.x,q.y-macetaPx(S.macetas[i]).hb-Math.round(h/2)];
}
// alto en px de la planta; en una plaza q, con el tope de alto de la plaza (q.ch)
const altoPlanta=(p,q)=>{const D=PLANTA_CM[porteDe(p.sid)];return Math.min(Math.round(D.h[p.dead?2:plantStage(p)]*VB_M),q?Math.floor(q.ch*VB_M):1e9)-(p.dead?4:0);};

/* ---------- vista C (P3): la carpa por dentro a pantalla completa, como la imagen A ----------
   La pared (misc:carpa-c-pared) es la imagen A sin plantas, sin foco y sin su luz: solo la tela, con sus brillos y sombras. La luz
   del foco (misc:carpa-c-luz) es otro sprite, por delante de la pared y detrás de las macetas; con el foco apagado no se pinta.
   Cada carpa va a su escala (px/cm): Z = 134 / (alto − 28), así la boca del foco (y 16, donde está en la imagen A) queda a su altura
   real sobre el suelo (y 150, a medio fondo). La pared del fondo se recorta al ancho de la carpa (W·Z px) alrededor de x 120, entre
   los laterales de la imagen A (columnas 0-43 y 196-239); el suelo baja de y 140 a 159 y se abre 16 px por lado. Macetas y copas,
   como en la vista B: en el centro de su parte y como mucho de cw × ch (distancia segura), a escala Z.
   Solo se usa si hay arte para todo lo que hay en la carpa (por ahora, focos de sodio y CFL, macetas de 7 L sin extras, índicas en
   floración y lista, e híbridas en sus fases); si no, la vista B. */
const VCA={lado:44,boca:16,base:150,fondo:140},VC_FILA=[[152],[156,146]];   // y de la base de las macetas: una fila · dos (delante, detrás)
const VC_TIERRA={'maceta-c-22':23,'maceta-c-15':10};                         // px de la base de la maceta a la tierra, donde nace el tallo
const vcAnchos=pre=>Object.keys(ARTE.cubre||{}).filter(k=>k.startsWith('misc:'+pre)).map(k=>+k.slice(5+pre.length)).filter(n=>n>0);
// el sprite de la familia (prefijo + ancho en px) más cercano a «px», si se aparta como mucho un 25 %
function vcSprite(pre,px){let m=null;for(const a of vcAnchos(pre))if(Math.abs(a-px)<=px*.25&&(!m||Math.abs(a-px)<Math.abs(m.a-px)))m={a,n:pre+a};return m&&{...m,f:fotoMisc(m.n)};}
// la planta: el sprite de su porte y fase más ancho que no pasa de su copa (distancia segura) ni baja de ×0,75. Floración y lista
// comparten sprite (planta-c-<porte>-NN); germinando, plántula y vegetativo llevan la fase (planta-c-<porte><fase>-NN). Si ninguno
// cabe, el más estrecho de los más anchos hasta ×1,33 (la tolerancia de la vista B) que no pase del sitio (tope), y entonces se dibuja
// así de grande también de alto (k = su ancho / el real: no se aplasta para meterla en el alto real); si no, la vista B
function vcPlantaSprite(po,st,px,tope){const pre='planta-c-'+po+(st>=3?'':st)+'-';let m=null,e=null;
  for(const a of vcAnchos(pre)){if(a<=px+1&&a>=px*.75&&(!m||a>m.a))m={a,n:pre+a};if(a>px+1&&a<=Math.min(px*1.33,tope)&&(!e||a<e.a))e={a,n:pre+a};}
  m=m||e&&{...e,k:e.a/px};return m&&{...m,f:fotoMisc(m.n)};}
const vcAltos=new WeakMap();   // alto del dibujo (de la última fila a la primera con algo) de cada celda
function vcAlto(c){if(vcAltos.has(c))return vcAltos.get(c);const d=c.getContext('2d').getImageData(0,0,c.width,c.height).data;let y=0;
  for(let i=3;i<d.length;i+=4)if(d[i]){y=Math.floor((i>>2)/c.width);break;}vcAltos.set(c,c.height-y);return c.height-y;}
// la geometría de la vista C sobre la de la vista B (g), o null si falta arte para algo de la carpa
function vistaC(g){
  const {c,W,H,pl}=g,tipo=FOCOS[c.foco].tipo;if(!ARTE.ok||Object.keys(EXTRAS).some(k=>c[k]))return null;
  // las campanas de sodio son foco-c-NN; las demás llevan su tipo (foco-c-cfl-NN)
  const Z=(VCA.base-VCA.boca)/(H-28),w=Math.round(W*Z),foco=vcSprite(tipo==='sodio'?'foco-c-':'foco-c-'+tipo+'-',(FOCO_CM[c.foco]||45)*Z);
  if(!fotoMisc('carpa-c-pared')||!fotoMisc('carpa-c-luz')||!foco||!foco.f)return null;
  const filas=VC_FILA[CARPAS[c.t].filas-1],v=[];
  for(const q of pl){
    const k=S.macetas[q.i],m=k==='plastico7'&&vcSprite('maceta-c-',MACETA_CM[k][0]*Z),p=S.pots[q.i];if(!m||!m.f)return null;
    const y=filas[Math.min(q.fila,filas.length-1)],x=Math.round(120+(q.cx/W-.5)*(w+32*(y-VCA.fondo)/19)),r={x,y,m,tierra:VC_TIERRA[m.n]||Math.round(m.f.c.height*.7),hp:0};
    if(p){const st=p.dead?9:plantStage(p),po=porteDe(p.sid),D=PLANTA_CM[po];if(st>4)return null;
      const s=vcPlantaSprite(po,st,Math.min(D.w[st],q.cw)*Z,q.cw*Z+1);if(!s||!s.f)return null;
      // tope: su alto real (ch) y, en pantalla, la distancia segura a la boca del foco (el sprite de la maceta es más alto que la real)
      r.p=s;r.hp=Math.min(vcAlto(s.f.c),Math.round(Math.min(D.h[st]*(s.k||1),q.ch)*Z),Math.floor(y-r.tierra-VCA.boca-FOCO_SEP[c.foco]*Z));}
    v.push(r);}
  pl.forEach((q,j)=>{q.v=v[j];q.x=v[j].x;q.y=v[j].y;q.alto=v[j].tierra+4+v[j].hp;});
  return {Z,w,xl:120-(w>>1),foco,tipo};
}
// pared o luz de la carpa t: la de la imagen A con la pared del fondo recortada a su ancho (240 × 160)
function vcFondo(t,vc,capa){
  const key='vc|'+t+'|'+capa;if(carpaCache[key])return carpaCache[key];
  const s=fotoMisc('carpa-c-'+capa).c,[c,x]=mkCanvas(240,160),L=VCA.lado,xl=vc.xl,xr=xl+vc.w;
  x.drawImage(s,0,0,L,160,xl-L,0,L,160);x.drawImage(s,xl,0,vc.w,160,xl,0,vc.w,160);x.drawImage(s,240-L,0,L,160,xr,0,L,160);
  return carpaCache[key]=c;
}
// la luz de cada tipo de foco: la del sodio es la de la imagen A tal cual; las demás, la misma capa con su color (misma luminosidad) y su fuerza
const LUZ_C={cfl:[[220,240,255],.6]};
function vcLuz(t,vc){const L=vcFondo(t,vc,'luz'),k=LUZ_C[vc.tipo];if(!k)return L;
  const key='vc|'+t+'|luz|'+vc.tipo;if(carpaCache[key])return carpaCache[key];
  const [c,x]=mkCanvas(240,160),[r,g,b]=k[0],lk=.299*r+.587*g+.114*b;x.drawImage(L,0,0);const im=x.getImageData(0,0,240,160),d=im.data;
  for(let i=0;i<d.length;i+=4)if(d[i+3]){const l=(.299*d[i]+.587*d[i+1]+.114*d[i+2])/lk;d[i]=Math.min(255,r*l);d[i+1]=Math.min(255,g*l);d[i+2]=Math.min(255,b*l);}
  x.putImageData(im,0,0);return carpaCache[key]=c;}
// la planta más baja que su sprite pierde filas enteras, nunca se escala (los píxeles no se aplastan). Primero pisos de ramas enteros
// (VC_PISOS), del medio, el más bajo que quepa primero: más baja = menos nudos. Siempre quedan el 1.º y el último (su borde de abajo es el
// único que se ve en la planta entera; el de los de en medio va tapado por el de debajo y, al aire, sería un estante). Lo que falte, las filas con
// menos píxeles (tallo pelado y entrenudos) de debajo de la cola; la cola (el 40 % de arriba) solo si no basta. La base del tallo (las 2
// últimas filas) se queda, en la última fila de la celda; las demás, en su orden
// pisos de cada sprite (filas desde arriba del dibujo, ambas incluidas; la cola y el tallo pelado no son pisos). La híbrida está montada
// con los de la índica (ver el manifiesto)
const VC_PISOS={'planta-c-i-24':[[18,29],[30,46],[47,57],[58,73]],'planta-c-h-24':[[18,29],[30,46],[47,63],[64,74],[75,90]],'planta-c-h2-24':[[18,29],[30,36],[37,47]]};
const vcBajas=new WeakMap();
function vcAplasta(c,h,pisos){
  const a=vcAlto(c),key=(pisos?'p':'')+h;if(h>=a)return c;let m=vcBajas.get(c);if(!m)vcBajas.set(c,m=new Map());if(m.has(key))return m.get(key);
  const W=c.width,H=c.height,y0=H-a,d=c.getContext('2d').getImageData(0,0,W,H).data,cola=y0+Math.round(a*.4),n=[],filas=[],fuera=new Set();let falta=a-h;
  const P=pisos||[];for(let i=P.length-2;i>0&&falta>0;i--){const k=P[i][1]-P[i][0]+1;if(k<=falta){for(let y=P[i][0];y<=P[i][1];y++)fuera.add(y0+y);falta-=k;}}
  for(let y=y0;y<H-2;y++){if(fuera.has(y))continue;let k=0;for(let x=0;x<W;x++)if(d[(y*W+x)*4+3])k++;n[y]=k;filas.push(y);}
  filas.sort((p,q)=>(p<cola)-(q<cola)||n[p]-n[q]||q-p).slice(0,falta).forEach(y=>fuera.add(y));
  const [o,x]=mkCanvas(W,H);let y=H;for(let s=H-1;s>=y0;s--)if(!fuera.has(s))x.drawImage(c,0,s,W,1,0,--y,W,1);
  m.set(key,o);return o;
}

// la campana con la boca apagada: los tonos cálidos y los casi blancos (el tubo del CFL) pasan a gris oscuro
function vcApagado(c){let m=vcBajas.get(c);if(!m)vcBajas.set(c,m=new Map());if(m.has('off'))return m.get('off');
  const [o,x]=mkCanvas(c.width,c.height);x.drawImage(c,0,0);const im=x.getImageData(0,0,c.width,c.height),d=im.data;
  for(let i=0;i<d.length;i+=4)if(d[i+3]&&(d[i]>d[i+2]+40||Math.min(d[i],d[i+1],d[i+2])>190)){const l=Math.round((d[i]*.3+d[i+1]*.59+d[i+2]*.11)*.3);d[i]=l;d[i+1]=l+2;d[i+2]=l+4;}
  x.putImageData(im,0,0);m.set('off',o);return o;}
function renderCarpaC(g,now){
  const {c,vc}=g,on=plantasVivas(VC.ci);
  ctx.fillStyle='#000';ctx.fillRect(0,0,SW,SH);
  ctx.save();ctx.translate(OX(),0);
  ctx.drawImage(vcFondo(c.t,vc,'pared'),0,0);
  const fsel=(g.pl.find(q=>q.i===VC.sel)||{fila:0}).fila;
  for(const q of [...g.pl].sort((a,b)=>a.y-b.y||a.x-b.x)){ctx.globalAlpha=q.fila<fsel?.35:1;vcPlantaC(q,now);}
  ctx.globalAlpha=1;
  // la luz del foco es su propia capa y va delante de pared, macetas y plantas (ninguna lleva la luz pintada); la campana, encima
  if(on){ctx.globalCompositeOperation='overlay';ctx.globalAlpha=(LUZ_C[vc.tipo]||[0,1])[1];ctx.drawImage(vcLuz(c.t,vc),0,0);ctx.globalAlpha=1;ctx.globalCompositeOperation='source-over';}
  const fc=vc.foco.f.c;ctx.drawImage(on?fc:vcApagado(fc),120-24,VCA.boca-15);
  vcCursor(g,now);
  if(ARTE.ok)pintarVfx(now,{x:0,y:0},'home');
  ctx.restore();
}
function vcPlantaC(q,now){
  const v=q.v,p=S.pots[q.i];ctx.drawImage(v.m.f.c,q.x-16,q.y-31);
  if(!p)return;
  const s=getStrain(p.sid),rk=((ARTE.d.rampas||{})['carpa-c-plantas']||{}).cogollo,c0=v.p.f.c,yb=q.y-v.tierra;
  const c1=rk&&s?conRampa(c0,{[rk.rampa[0]]:shade(s.c,50),[rk.rampa[1]]:s.c,[rk.rampa[2]]:shade(s.c,-60)},'g|'+s.c):c0;
  if(p.water<=0)ctx.filter='saturate(.4) sepia(.7)';   // seca: amarillenta
  const pc=vcAplasta(c1,v.hp,VC_PISOS[v.p.n]),b=pc.height-1;balanceo(pc,q.x-24,yb-b,b,p.water>0?1:0,now+q.x*37);
  ctx.filter='none';
  if(p.pest){ctx.fillStyle='#e02828';for(let n=0;n<6;n++)ctx.fillRect(q.x-8+((n*5+Math.floor(now/300))%16),yb-12-((n*7)%20),1,1);}
}

/* ---------- arte procedural ---------- */
const VK={pole:'#5a5e68',hi:'#8a8e98',tela:'#26272c',osc:'#1c1d22',techo:'#3e4048',my:'#d4d8e2',my2:'#b2b8c4',my3:'#f2f4f8',my4:'#c8ccd6',som:'#a8aebb',
  marco:'#2e3038',marco2:'#5a5e68',lado:'#9aa0ac',lado2:'#8a909c'};
// el mueble del piso: frente de tela negra (ancho × alto reales a 16 px/m) y techo visto desde arriba (medio fondo); pies en (cw/2, ch−1)
function carpaMapa(tk){
  const key='cm|'+tk;if(carpaCache[key])return carpaCache[key];
  const [W,H,D]=CARPAS[tk].cm,w=Math.round(W*.16),hf=Math.round(H*.16),ht=Math.round(D*.08),[c,x]=mkCanvas(w,hf+ht),t=painter(x,rngSeed(w));
  t.F(0,0,w,ht,VK.techo);t.F(0,0,w,1,VK.hi);t.F(0,ht-1,w,1,VK.hi);t.F(0,0,1,ht,VK.pole);t.F(w-1,0,1,ht,VK.pole);
  if(ht>=6){t.F(w-7,2,4,3,VK.osc);t.F(w-6,2,2,1,VK.som);}                                      // salida del extractor
  t.F(0,ht,w,hf,VK.tela);t.F(0,ht,1,hf,VK.pole);t.F(w-1,ht,1,hf,VK.pole);t.F(0,ht+hf-1,w,1,VK.osc);
  const dw=w<12?6:8,dx=w>=19?3:(w-dw)>>1,dy=ht+3;                                              // puerta de cremallera (a la izquierda en las anchas)
  t.F(dx,dy+1,dw,hf-5,'#2e3036');t.F(dx+1,dy,dw-2,1,'#a0a4ac');t.F(dx,dy+1,1,hf-5,'#a0a4ac');t.F(dx+dw-1,dy+1,1,hf-5,'#a0a4ac');t.P(dx+dw-2,dy+3,'#e0e2e8');
  if(w>=19){t.F(w-9,ht+hf-9,6,4,VK.osc);for(let i=0;i<6;i+=2)t.F(w-9+i,ht+hf-9,1,4,'#3a3c44');}   // rejilla de ventilación
  return carpaCache[key]=c;
}
function pintarCarpaMapa(t,cam){
  const xc=(t.x0+t.x1+1)*8-cam.x,yb=t.y*16+15-cam.y;
  if(!arteCarpaMapa(t.t,xc,yb)){const c=carpaMapa(t.t);ctx.drawImage(c,xc-(c.width>>1),yb-c.height+1);}
  if(plantasVivas(t.ci)){ctx.fillStyle=FOCO_LUZ[FOCOS[S.carpas[t.ci].foco].tipo]+'.6)';ctx.fillRect(xc-3,yb+1,6,1);}   // la luz se escapa bajo la puerta
}
function linea(t,a,b,col){const n=Math.max(Math.abs(b[0]-a[0]),Math.abs(b[1]-a[1]),1);for(let k=0;k<=n;k++)t.P(Math.round(a[0]+(b[0]-a[0])*k/n),Math.round(a[1]+(b[1]-a[1])*k/n),col);}
// la carpa abierta en 3/4: pared del fondo y pared izquierda de mylar acolchado, suelo plateado, marco negro y barra del foco.
// Lienzo de (ancho + corrimiento + 2) × (alto + fondo + 3); el frente izquierdo del suelo en (1, alto − 2)
function carpa34(tk){
  const key='c34|'+tk;if(carpaCache[key])return carpaCache[key];
  const [W,H,D]=CARPAS[tk].cm,w=Math.round(W*VB_M),s=Math.round(D*VB_X),hp=Math.round(H*VB_M),dp=Math.round(D*VB_F);
  const [c,x]=mkCanvas(w+s+2,hp+dp+3),t=painter(x,rngSeed(w*5+3)),YF=hp+dp+1,P=(a,y,z)=>[Math.round(1+a*VB_M+y*VB_X),Math.round(YF-y*VB_F-z*VB_M)];
  const bx0=1+s,bx1=s+w,by0=YF-dp-hp,by1=YF-dp;
  for(let y=by0;y<=by1;y++)for(let xx=bx0;xx<=bx1;xx++){const u=xx-bx0,v=y-by0,a=(u+v)%8,b=(u-v+800)%8;   // fondo: rombos del acolchado
    t.P(xx,y,a===0||b===0?VK.my2:a===4&&b===4?VK.my3:a<3&&b<3?VK.my4:VK.my);}
  for(let xx=bx0+3;xx<bx1;xx+=17)t.F(xx,by0+2,1,hp-4,'#e6e9f0');                                // brillos verticales del mylar
  for(let k=1;k<=s;k++){const xx=bx0-k,y0=by0+Math.round(k*dp/s),y1=by1+Math.round(k*dp/s);   // pared izquierda, de fondo a frente
    for(let y=y0;y<=y1;y++)t.P(xx,y,(y-y0+k*3)%8===0?VK.som:k>s/2?VK.lado2:VK.lado);}
  for(let y=by1+1;y<=YF;y++){const k=(YF-y)/dp,xl=1+Math.round(k*s);t.F(xl,y,w,1,(YF-y)%6===5?VK.my4:VK.my3);}   // suelo con juntas
  for(let a=25;a<W;a+=25)linea(t,P(a,0,0),P(a,D,0),VK.my4);
  t.F(bx0,by1,w,1,VK.som);                                                                      // rincón entre el fondo y el suelo
  const ef=(k,col)=>[[[0,D,0],[0,D,H]],[[W,D,0],[W,D,H]],[[0,D,H],[W,D,H]],[[0,D,H],[0,0,H]],[[0,0,0],[0,0,H]],[[W,0,H],[W,D,H]],[[W,0,0],[W,0,H]],[[W,0,0],[W,D,0]]]
    .forEach(([a,b])=>linea(t,P(...a),P(...b),col));
  ef(0,VK.marco);                                                                               // marco (sin el travesaño de delante, para ver dentro)
  t.F(1,YF,w,2,VK.marco);t.F(1,YF,w,1,VK.marco2);                                               // riel del suelo
  linea(t,P(0,D/2,H-4),P(W,D/2,H-4),VK.marco2);                                                 // barra de colgar el foco
  const [px,py]=P(W-12,D,H-14);t.blob(px,py,3.5,3.5,'#26272c',VK.som);                          // boca del extractor
  return carpaCache[key]=c;
}
// el cuarto: pared del piso y suelo de tarima en 3/4, a 48 px/m (240 × 160: la pared llega a VB_PARED)
let cuartoC=null;
function cuarto34(){
  if(cuartoC)return cuartoC;const [c,x]=mkCanvas(240,160),t=painter(x,rngSeed(11)),col='#ead8b4',y0=VB_PARED;
  t.F(0,0,240,y0,col);for(let i=3;i<240;i+=8)t.F(i,0,1,y0-5,shade(col,-8));
  t.F(0,y0-5,240,5,'#f4ecd8');t.F(0,y0-5,240,1,'#c8b896');t.F(0,y0-1,240,1,'#a89470');           // rodapié de 10 cm
  for(let y=y0;y<160;y++)t.F(0,y,240,1,(y-y0)%4===3?'#b48446':'#d8a868');                       // tarima: tablas de 15 cm de fondo
  for(let y=y0;y<160;y+=4)for(let i=0;i<5;i++){const xx=Math.floor(t.R()*236)+2;t.F(xx,y,1,3,'#b48446');}
  t.noise(240,['#e6bc80'],0,y0,240,160-y0);
  t.F(190,104,7,5,'#f4f4ee');t.F(190,104,7,1,'#c8c8c0');t.P(192,106,'#3a3a44');t.P(194,106,'#3a3a44');   // enchufe a 35 cm del suelo
  t.F(193,109,1,y0-109-5,'#5a5e68');
  return cuartoC=c;
}
// maceta en 3/4: borde y tierra en elipse arriba, cuerpo y media elipse abajo. Lienzo w × (hb + e); el centro de la base en (w/2, e/2 + hb)
function maceta34(k){
  const key='m34|'+k;if(carpaCache[key])return carpaCache[key];
  const [,,cu,bo,tela]=MACETA_CM[k]||MACETA_CM.plastico7,{w,e,hb}=macetaPx(k),[c,x]=mkCanvas(w,hb+e),t=painter(x,rngSeed(w));
  const r=w/2,ry=e/2,dentro=(px,py,cy,rx,ryy)=>{const dx=(px+.5-r)/rx,dy=(py+.5-cy)/ryy;return dx*dx+dy*dy<=1;};
  for(let py=0;py<hb+e;py++)for(let px=0;px<w;px++){
    const cuerpo=py>=ry&&py<=ry+hb&&(tela||Math.abs(px+.5-r)<=r-(py-ry)/hb),fondo=dentro(px,py,ry+hb,r-(tela?0:1),ry);
    if(cuerpo||fondo)t.P(px,py,px<r*.5?shade(cu,14):px>r*1.4?shade(cu,-10):cu);}
  for(let py=0;py<e;py++)for(let px=0;px<w;px++)if(dentro(px,py,ry,r,ry))t.P(px,py,dentro(px,py,ry,r-1.2,ry-1)?(py<ry?'#3a2a1c':'#5a3a20'):bo);
  if(tela){t.F(1,Math.round(ry+hb*.45),w-2,1,shade(cu,-18));t.F(0,Math.round(ry+1),1,2,shade(bo,-20));t.F(w-1,Math.round(ry+1),1,2,shade(bo,-20));}   // costura y asas
  return carpaCache[key]=c;
}
// planta en 3/4 de un porte y una fase (9 = muerta): tallo y pisos de ramas que suben en diagonal, con su hoja de abanico en la
// punta (en abeto en índicas e híbridas, más parejos y espaciados en sativas) y, en floración, cogollos en las puntas y la cola
// arriba. Ocupa el alto y el ancho reales de PLANTA_CM, como mucho cw de ancho y ch de alto (cm: lo que cabe en su plaza, ver
// vcGeo). Lienzo 48 × 80 con la base del tallo en (24, 79)
function planta34(po,st,dry,bud,cw=1e9,ch=1e9){
  const key='p34|'+po+st+dry+bud+'|'+Math.round(Math.min(cw,999))+'|'+Math.round(Math.min(ch,999));if(plantCache[key])return plantCache[key];
  const [c,x]=mkCanvas(48,80),t=painter(x,rngSeed(st*7+po.charCodeAt(0))),B=79,cx=24,mu=st===9,f=mu?2:st,D=PLANTA_CM[po];
  const H=Math.min(Math.round(D.h[f]*VB_M),Math.floor(ch*VB_M))-(mu?4:0),A=Math.min(D.w[f],cw)*VB_M/2,top=B-H+1;
  const g1=dry?'#b8aa48':'#3c9a3e',g2=dry?'#8a7c30':'#22662a',g3=dry?'#d8cc78':'#74d064',ta=mu?'#6a5430':g2;
  const hoja=(hx,hy,s)=>{if(mu){drawLeafPx(t,hx,hy+s*.8,s*.8,'#5a4a28');return;}drawLeafPx(t,hx,hy,s+.6,g2);drawLeafPx(t,hx,hy,s,g1);if(s>2.2)drawLeafPx(t,hx,hy-.5,s*.45,g3);};
  const cogollo=(bx,by,rx,ry)=>t.blob(bx,by,rx,ry,bud,shade(bud,-60),shade(bud,50));
  if(st===0){t.F(cx,top+2,1,H-2,g2);t.blob(cx-2,top+1.5,2,1.2,g1,g2,g3);t.blob(cx+3,top+1.5,2,1.2,g1,g2,g3);return plantCache[key]=c;}
  if(f===1){t.F(cx,top+3,1,H-3,g2);hoja(cx-3,B-H*.45,1.5);hoja(cx+3,B-H*.6,1.5);hoja(cx+.5,top+3,1.6);return plantCache[key]=c;}
  const pisos=po==='s'?5:6,abeto=po==='s'?.3:.62,flor=f>=3&&!mu,ry=flor?(st===4?1.25:.95)*(po==='s'?1.5:po==='i'?.9:1.15):0;
  const cima=top+(flor?Math.round(ry*5):4);                                                       // donde acaba el tallo
  t.F(cx-(f>=3?1:0),cima,f>=3?2:1,B-cima,ta);
  for(let n=0;n<pisos;n++){
    const k=n/(pisos-1),y=Math.round(B-H*(.22+.62*k))+(mu?2:0),hw=A*(1-abeto*k),s=Math.max(1.3,Math.min(4.2,hw*.3)),bx=hw-s*1.1,by=Math.round(bx*(mu?-.1:.45));
    const ty=Math.max(y-by,top+Math.ceil((s+.6)*1.75)),r=1.1+s*.28;   // ni la hoja ni el cogollo de la punta suben por encima de la planta
    for(const d of [-1,1]){linea(t,[cx,y],[Math.round(cx+d*bx),ty],ta);hoja(cx+d*bx,ty,s);
      if(k<.7&&!mu)hoja(cx+d*bx*.45,y-Math.round(by*.45)+1,s*.7);
      if(flor&&n>0)cogollo(cx+d*bx,Math.max(ty-s*1.3,top+r*ry*1.3),r,r*ry*1.3);}
  }
  if(flor){const r=st===4?2.6:2,rr=r*ry*1.9;cogollo(cx+.5,top+rr,r,rr);if(st===4)for(let i=0;i<8;i++)t.P(cx-2+Math.floor(t.R()*5),top+1+Math.floor(t.R()*rr*1.6),'#ffffff');}
  else hoja(cx+.5,top+4.5,mu?1.6:2.2);
  return plantCache[key]=c;
}
// foco colgado, en 3/4 (un poco desde arriba), a su ancho real; lienzo (ancho + 2) × 10 con la parte de abajo en la última fila
function foco34(id){
  const key='f34|'+id;if(carpaCache[key])return carpaCache[key];
  const tipo=FOCOS[id].tipo,w=Math.round((FOCO_CM[id]||40)*VB_M),W=w+2,[c,x]=mkCanvas(W,10),t=painter(x,rngSeed(w)),cx=W>>1;
  const trap=(y0,y1,a0,a1,col,hi)=>{for(let y=y0;y<=y1;y++){const a=Math.round(a0+(a1-a0)*(y-y0)/Math.max(1,y1-y0));t.F(cx-(a>>1),y,a,1,y===y0&&hi?hi:col);}};
  if(tipo==='cfl'){trap(1,5,6,w,'#e8eaf0','#ffffff');t.F(cx-(w>>1),5,w,1,'#a8aebb');t.F(cx-1,0,2,1,'#5a5e68');for(let i=-2;i<=2;i+=2)t.F(cx+i,6,1,3,'#fffbe8');t.F(cx-2,9,5,1,'#d8d8c8');}
  else if(tipo==='sodio'){trap(1,6,Math.round(w*.55),w,'#c8ccd6','#e8eaf0');t.F(cx-(w>>1),6,w,1,'#8a8e98');t.F(cx-Math.round(w*.3),7,Math.round(w*.6),2,'#ffb040');t.F(cx-Math.round(w*.25),7,Math.round(w*.5),1,'#ffe0a0');t.F(cx-3,0,6,1,'#5a5e68');}
  else if(id==='led720'){t.F(1,4,w,1,'#2a2b30');t.F(1,8,w,1,'#2a2b30');for(let i=0;i<6;i++){const bx=1+Math.round(i*(w-4)/5);t.F(bx,4,4,5,'#1c1d22');t.F(bx,9,4,1,i%2?'#ff70c0':'#f4f0ff');}}
  else{t.F(1,5,w,1,'#3a3c44');t.F(1,6,w,3,'#1c1d22');t.F(2,7,w-2,1,'#2a2b30');const d=['#ff70c0','#f4f0ff','#c070ff'];for(let i=0;i<Math.floor(w/3);i++)t.F(2+i*3,9,2,1,d[i%3]);t.F(cx-3,4,6,1,'#5a5e68');}
  return carpaCache[key]=c;
}
// extras de la carpa (1.10): ventilador de pinza, filtro de carbón con su extractor y depósito de goteo; base en la última fila, centrada
function extra34(k){
  const key='x34|'+k;if(carpaCache[key])return carpaCache[key];let c,x,t;
  if(k==='vent'){[c,x]=mkCanvas(11,14);t=painter(x,rngSeed(5));t.blob(5.5,5,5,5,'#c8ccd6','#3a3c44','#e8eaf0');t.blob(5.5,5,1.6,1.6,'#5a5e68','#2a2b30');
    for(const [a,b] of [[2,2],[8,2],[2,8],[8,8]])t.P(a,b,'#8a8e98');t.F(5,10,1,2,'#3a3c44');t.F(3,12,5,2,'#2a2b30');}   // aspas, eje y pinza
  else if(k==='filtro'){[c,x]=mkCanvas(32,12);t=painter(x,rngSeed(6));t.F(8,1,24,10,'#4a4c54');for(let i=9;i<31;i+=2)t.F(i,2,1,8,'#5e6068');
    t.F(8,1,24,1,'#6a6e78');t.F(8,10,24,1,'#2a2b30');t.F(30,1,2,10,'#2a2b30');t.blob(4,6,3.5,3.5,'#3a3c44','#1c1d22','#6a6e78');t.F(6,4,2,4,'#a8aebb');}   // filtro, extractor y abrazadera
  else{[c,x]=mkCanvas(16,24);t=painter(x,rngSeed(7));t.F(1,6,14,18,'#2e4a66');t.F(1,6,14,1,'#5a7a98');t.F(1,12,14,1,'#4a6a88');t.F(2,13,12,10,'#3a5a7c');   // depósito y nivel del agua
    t.blob(8,4,7,3,'#26303a','#1c1d22','#3a4a5a');t.F(6,0,1,4,'#1c1d22');t.F(9,0,1,4,'#1c1d22');}   // tapa y tubos
  return carpaCache[key]=c;
}

/* ---------- la escena ---------- */
function renderCarpa(now){
  const g=vcGeo(VC.ci),{c,P,W,H,D}=g,F=FOCOS[c.foco],on=plantasVivas(VC.ci);
  if(g.vc)return renderCarpaC(g,now);
  fondoAncho(cuarto34());
  ctx.save();ctx.translate(OX(),0);
  if(c.goteo){const e=extra34('goteo'),gx=g.x0+g.w+g.s+12,gy=VB_PARED+8;ctx.drawImage(e,gx-(e.width>>1),gy-e.height+1);   // el depósito, fuera de la carpa
    const [tx,ty]=P(W-6,D*.7,4);ctx.fillStyle='#1c1d22';ctx.fillRect(tx,gy-e.height+1,gx-tx-1,1);ctx.fillRect(tx,gy-e.height+1,1,ty-(gy-e.height+1));}
  const cv=carpa34(c.t);ctx.drawImage(cv,g.x0-1,g.yf+2-cv.height);
  if(c.filtro){const e=extra34('filtro'),[fx,fy]=P(W*.55,D*.85,H-24);ctx.drawImage(e,fx-(e.width>>1),fy-e.height+1);}
  if(c.vent){const e=extra34('vent'),[vx,vy]=P(2,D*.8,110);ctx.drawImage(e,vx,vy-e.height+1);}
  ctx.save();ctx.beginPath();ctx.rect(g.x0+1,0,g.w+g.s-1,SH);ctx.clip();   // la luz y las copas no salen de la carpa por los lados
  if(on){ctx.globalCompositeOperation='lighter';const a=.05+.09*Math.min(1,F.w/600),lw=Math.round((FOCO_CM[c.foco]||40)*VB_M/2),hw=g.w/2+g.s;
    const gr=ctx.createLinearGradient(0,g.fy,0,g.yf);gr.addColorStop(0,FOCO_LUZ[F.tipo]+a+')');gr.addColorStop(1,FOCO_LUZ[F.tipo]+'0)');
    ctx.fillStyle=gr;ctx.beginPath();ctx.moveTo(g.fx-lw,g.fy);ctx.lineTo(g.fx+lw,g.fy);ctx.lineTo(g.fx+hw,g.yf);ctx.lineTo(g.fx-hw,g.yf);ctx.fill();
    ctx.globalCompositeOperation='source-over';}
  // con una plaza de atrás elegida, la fila de delante se pinta en transparencia para que se vea la planta que tapa
  const fsel=(g.pl.find(q=>q.i===VC.sel)||{fila:0}).fila;
  for(const q of [...g.pl].sort((a,b)=>a.y-b.y||a.x-b.x)){ctx.globalAlpha=q.fila<fsel?.35:1;vcPlanta(q,now);}
  ctx.globalAlpha=1;
  ctx.restore();
  const fc=foco34(c.foco),x0=g.fx-(fc.width>>1),y0=g.fy-fc.height+1,ty=y0+(F.tipo==='led'?4:0);   // cuelga de dos cuerdas
  ctx.fillStyle='#2a2b30';if(ty>g.barra){ctx.fillRect(x0+2,g.barra,1,ty-g.barra);ctx.fillRect(x0+fc.width-3,g.barra,1,ty-g.barra);}
  ctx.drawImage(fc,x0,y0);
  vcCursor(g,now);
  if(ARTE.ok)pintarVfx(now,{x:0,y:0},'home');
  ctx.restore();
}
// maceta y planta de una plaza (q.alto: lo que se ve por encima del suelo, para la flecha)
function vcPlanta(q,now){
  const p=S.pots[q.i],k=S.macetas[q.i],m=maceta34(k),{e,hb}=macetaPx(k);
  ctx.drawImage(m,q.x-(m.width>>1),q.y-Math.round(e/2+hb));q.alto=hb+Math.round(e/2);
  if(!p)return;
  const s=getStrain(p.sid),st=p.dead?9:plantStage(p),pc=planta34(porteDe(p.sid),st,!p.dead&&p.water<=0,s?s.c:'#9bd35a',q.cw,q.ch),yb=q.y-hb+1;
  q.alto+=altoPlanta(p,q);
  balanceo(pc,q.x-24,yb-79,79,!p.dead&&p.water>0&&st>=2?1:0,now+q.x*37);
  if(p.pest&&!p.dead){ctx.fillStyle='#e02828';for(let n=0;n<6;n++)ctx.fillRect(q.x-6+((n*5+Math.floor(now/300))%12),yb-8-((n*7)%14),1,1);}
}
function vcCursor(g,now){
  const b=Math.floor(now/300)%2;let x,y;
  if(VC.sel<0){const fw=g.fw||foco34(g.c.foco).width;x=g.fx-(fw>>1)-8;y=g.fy-5;ctx.fillStyle='#26262e';ctx.fillRect(x-1,y-4,6,9);ctx.fillStyle='#f8f8f0';for(let k=0;k<4;k++)ctx.fillRect(x+b+k,y-3+k,1,7-2*k);return;}
  const q=g.pl.find(q=>q.i===VC.sel);if(!q)return;
  ctx.fillStyle='rgba(255,255,240,.35)';ctx.fillRect(q.x-7,q.y,14,2);
  x=q.x;y=q.y-(q.alto||12)-9+b;
  ctx.fillStyle='#26262e';ctx.fillRect(x-4,y-1,9,6);ctx.fillStyle='#f8f8f0';for(let k=0;k<4;k++)ctx.fillRect(x-3+k,y+k,7-2*k,1);
}
function vcInfo(){
  const el=$('vcInfo');if(!VC||VC.ocupado){el.hidden=true;return;}
  const c=S.carpas[VC.ci],L=[];
  if(VC.sel<0){L.push(esc(FOCOS[c.foco].n),plantasVivas(VC.ci)?'Luz '+eur(luzCarpa(VC.ci))+' al día':'Apagado');for(const k in EXTRAS)if(c[k])L.push(EXTRAS[k].c);}
  else{const i=VC.sel,p=S.pots[i];L.push(`Plaza ${huecos()[i].j+1} · ${MACETAS[S.macetas[i]].l} L`);
    if(!p)L.push('Vacía');
    else{L.push(esc(getStrain(p.sid).n));
      if(p.dead)L.push('Seca');else L.push(p.prog>=1?'Cosecha lista':stageName(p)+' '+Math.floor(p.prog*100)+' %','Agua '+Math.round(p.water)+' %','Salud '+Math.round(p.health)+' %');
      if(p.pest&&!p.dead)L.push('<em>PLAGA</em>');}}
  el.innerHTML=`<b>${esc(CARPAS[c.t].n)}</b>`+L.map(l=>`<div>${l}</div>`).join('');el.hidden=false;
}
function vcMover(b){
  const pl=vcGeo(VC.ci).pl,cur=pl.find(q=>q.i===VC.sel),cerca=(l,x)=>l.reduce((m,q)=>Math.abs(q.x-x)<Math.abs(m.x-x)?q:m);
  if(!cur){if(b==='down'){const fm=Math.max(...pl.map(q=>q.fila));VC.sel=cerca(pl.filter(q=>q.fila===fm),120).i;}return;}
  if(b==='left'||b==='right'){const f=pl.filter(q=>q.fila===cur.fila).sort((a,c)=>a.x-c.x),k=f.indexOf(cur)+(b==='left'?-1:1);if(k>=0&&k<f.length)VC.sel=f[k].i;}
  else if(b==='up'){const f=pl.filter(q=>q.fila===cur.fila+1);VC.sel=f.length?cerca(f,cur.x).i:-1;}
  else if(b==='down'){const f=pl.filter(q=>q.fila===cur.fila-1);if(f.length)VC.sel=cerca(f,cur.x).i;}
}
async function abrirCarpa(ci){
  sfx('door');await fade(1);
  const pl=vcGeo(ci).pl;VC={ci,sel:pl.length?pl[0].i:-1,ocupado:false};mode='carpa';updateHUD();vcInfo();
  await fade(0);
  if(!S.flags.vista){S.flags.vista=true;toast('◀ ▶ ▲ ▼ eliges planta o foco · A la cuidas · B sales',2800);}
  await new Promise(res=>push(b=>{
    if(VC.ocupado)return;
    if(b==='B'){pop();res();return;}
    if(b==='A'){VC.ocupado=true;vcInfo();(VC.sel<0?carpaAction(VC.ci):potAction(VC.sel)).then(()=>{VC.ocupado=false;vcInfo();});return;}
    if(DV[b]){const s=VC.sel;vcMover(b);if(s!==VC.sel){sfx('tick');vcInfo();}}
  }));
  VC.ocupado=true;vcInfo();await fade(1);mode='world';VC=null;updateHUD();await fade(0);
}

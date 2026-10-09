/* =========================================================
   ARTE — sprites y animaciones de PixelLab desde el atlas
   (assets/sprites/atlas.*, incrustado por tools/build.js como ATLAS).
   Todo lo que no esté en el atlas se dibuja con el procedural de siempre.
   ?arte=procedural en la URL fuerza el procedural para comparar.
   ========================================================= */
const ARTE={ok:false,fr:{},mir:{},rec:new WeakMap(),vfx:[],st:new WeakMap(),sobre:{},cubre:{},prisa:1};
const DIR4={down:'south',up:'north',left:'west',right:'east'};
const FASES=['germinando','plantula','vegetativo','floracion','lista'];
const FUMA=/fum|puro|pipa|vap/;
function arteListo(){
  if(ARTE.p)return ARTE.p;
  let off=false;try{off=/[?&]arte=procedural/.test(location.search);}catch(e){}
  if(typeof ATLAS==='undefined'||!ATLAS||off)return ARTE.p=Promise.resolve(false);
  return ARTE.p=new Promise(res=>{
    const img=new Image();
    img.onload=()=>{try{
      const d=ATLAS.def;
      for(const k in d.frames){const f=d.frames[k];const [c,x]=mkCanvas(f.w,f.h);x.drawImage(img,f.x,f.y,f.w,f.h,0,0,f.w,f.h);ARTE.fr[k]=c;}
      for(const g in d.anims)for(const s in d.anims[g]){const a=d.anims[g][s];if(a.sobre)(ARTE.sobre[a.sobre]=ARTE.sobre[a.sobre]||[]).push([g,s]);}
      ARTE.d=d;ARTE.cubre=d.cubre||{};ARTE.ok=true;res(true);
    }catch(e){console.error(e);res(false);}};
    img.onerror=()=>{console.warn('atlas: no se pudo cargar la imagen');res(false);};
    img.src=ATLAS.png;
  });
}
const animDe=(g,s)=>!!g&&ARTE.ok&&ARTE.d.anims[g]?ARTE.d.anims[g][s]||null:null;
// fotogramas de una dirección; si falta, la más cercana (este ↔ oeste en espejo, después sur)
function clavesDe(g,s,dir){
  const a=animDe(g,s);if(!a)return null;const D=a.dirs;
  if(D[dir])return [D[dir],false];
  if(dir==='east'&&D.west)return [D.west,true];
  if(dir==='west'&&D.east)return [D.east,true];
  return [D.south||D.unica||D[Object.keys(D)[0]],false];
}
function tieneDir(g,s,dir){const a=animDe(g,s);if(!a)return false;const D=a.dirs;return !!(D[dir]||(dir==='east'&&D.west)||(dir==='west'&&D.east));}
function espejo(k){
  if(ARTE.mir[k])return ARTE.mir[k];
  const s=ARTE.fr[k];const [c,x]=mkCanvas(s.width,s.height);x.translate(s.width,0);x.scale(-1,1);x.drawImage(s,0,0);return ARTE.mir[k]=c;
}
function nFotos(g,s){const a=animDe(g,s);if(!a)return 0;return Math.max(...Object.values(a.dirs).map(v=>v.length));}
const duracion=(g,s)=>{const a=animDe(g,s);return a?nFotos(g,s)*1000/(a.fps||8):0;};
// o.i: índice fijo · o.ph: fase 0-1 del ciclo · si no, por tiempo t (ms) con fps y bucle del atlas
function frameDe(g,s,dir,t,o={}){
  const r=clavesDe(g,s,dir);if(!r)return null;
  const [ks,m]=r,a=animDe(g,s),n=ks.length;let i;
  if(o.i!=null)i=((o.i%n)+n)%n;
  else if(o.ph!=null)i=Math.floor(o.ph*n)%n;
  else{i=Math.floor(Math.max(0,t)*(a.fps||8)/1000);i=(o.bucle??a.bucle)?i%n:Math.min(n-1,i);}
  return {c:m!==!!o.esp?espejo(ks[i]):ARTE.fr[ks[i]],i,n,cel:a.celda||ARTE.d.celdas[g]};   // o.esp (orgánico): en espejo
}
// cambia colores exactos (rampa clave → rampa destino); se calcula una vez por fotograma y rampa
function conRampa(c,map,id){
  let m=ARTE.rec.get(c);if(!m){m=new Map();ARTE.rec.set(c,m);}
  if(m.has(id))return m.get(id);
  const [o,x]=mkCanvas(c.width,c.height);x.drawImage(c,0,0);
  const im=x.getImageData(0,0,c.width,c.height),px=im.data,tb={};
  for(const k in map){const a=parseInt(k.slice(1),16),b=parseInt(map[k].slice(1),16);tb[a]=[b>>16,(b>>8)&255,b&255];}
  for(let j=0;j<px.length;j+=4){if(!px[j+3])continue;const t=tb[(px[j]<<16)|(px[j+1]<<8)|px[j+2]];if(t){px[j]=t[0];px[j+1]=t[1];px[j+2]=t[2];}}
  x.putImageData(im,0,0);m.set(id,o);return o;
}
function pinta(f,xP,yP,c){ctx.drawImage(c||f.c,Math.round(xP-f.cel.ancla[0]),Math.round(yP-f.cel.ancla[1]));}
function dibujar(g,s,dir,t,xP,yP,o){const f=frameDe(g,s,dir,t,o);if(f)pinta(f,xP,yP);return f;}
function sombra(x,y){ctx.fillStyle='rgba(0,0,0,.22)';ctx.fillRect(x-4,y-1,8,3);ctx.fillRect(x-5,y,10,1);}

/* ---------- personajes ---------- */
function grupoLook(look){
  if(!ARTE.ok||!look)return null;
  const g=ARTE.cubre['look:'+look.id];if(g)return g;
  const id=String(look.id);
  if(id[0]==='n')return ARTE.cubre['look:cliente'+(1+hashStr(id)%6)]||null;   // clientes aleatorios → 6 familias
  if(id[0]==='t')return ARTE.cubre['look:ladron'+(1+hashStr(id)%3)]||null;     // ladrones aleatorios → 3 familias
  return null;
}
function pjFrame(e,g,now,isP,dur){
  if(e.act&&!isP&&e.moving)e.act=null;
  if(e.act){const t=now-e.act.t0,f=frameDe(g,e.act.n,DIR4[e.dir],t);if(f&&t<duracion(g,e.act.n))return f;e.act=null;}
  if(e.moving){
    const s=isP&&dur<200&&animDe(g,'run')?'run':animDe(g,'walk')?'walk':null;
    if(s){const par=isP?e.parity:(e.x+e.y)&1;return frameDe(g,s,DIR4[e.dir],0,{ph:(par+Math.min(1,e.t/dur))/2});}   // un ciclo cada 2 casillas
  }
  if(tieneDir(g,'idle',DIR4[e.dir]))return frameDe(g,'idle',DIR4[e.dir],now+hashStr(String(e.id||'p'))%5000,{bucle:true}); // fase propia por NPC; sin idle en esa dirección, base
  return frameDe(g,'base',DIR4[e.dir],0,{i:0});
}
function dibujarPJ(e,look,now,cam,isP,dur){
  const g=grupoLook(look);if(!g)return false;
  const f=pjFrame(e,g,now,isP,dur);if(!f)return false;
  const xp=Math.round(e.px-cam.x)+8,yp=Math.round(e.py-cam.y)+15;   // pies en la última fila de la casilla
  sombra(xp,yp);pinta(f,xp,yp);
  const a=e.act;
  if(a&&a.humo&&!a.humoHecho&&f.i>=a.humo.frame){a.humoHecho=1;lanzarVfx(a.humo.vfx,e.px+8+a.humo.off[0],e.py+15+a.humo.off[1],now,S.map,true);}
  return true;
}
// ambiente: solo quieto, en pantalla y sin diálogo; al hablarle se corta
function ambiente(e,now,cam){
  const g=grupoLook(e.look);if(!g)return;
  const am=ARTE.d.ambiente&&ARTE.d.ambiente[g];if(!am)return;
  const dt=()=>(am.cada_s[0]+Math.random()*(am.cada_s[1]-am.cada_s[0]))*1000*ARTE.prisa;
  let s=ARTE.st.get(e);if(!s){s={next:now+dt()};ARTE.st.set(e,s);}
  if(!isFree()){if(e.act){e.act=null;s.next=now+dt();}return;}
  const sx=e.px-cam.x,sy=e.py-cam.y;
  if(e.act||e.moving||sx<-16||sy<-16||sx>SW||sy>SH||now<s.next)return;
  s.next=now+dt();
  const menor=(ARTE.d.menores||[]).includes(g);
  const ops=am.acciones.filter(n=>animDe(g,n)&&!(menor&&FUMA.test(n)));if(!ops.length)return;
  const n=ops[Math.floor(Math.random()*ops.length)],fu=!menor&&ARTE.d.fumador&&ARTE.d.fumador[g];
  e.act={n,t0:now};
  if(fu&&FUMA.test(n))e.act.humo={vfx:fu.vfx,frame:fu.frame_humo,off:fu.offset_boca};
  if(e.id){ARTE.log=ARTE.log||[];ARTE.log.push(e.id+':'+n);if(ARTE.log.length>300)ARTE.log.shift();}
}
// acciones del jugador: devuelve una promesa que acaba con la animación (inmediata sin atlas)
function accion(n,vfx){
  const g=grupoLook(LOOKS.player);
  if(!g||!animDe(g,n))return Promise.resolve();
  const now=performance.now();P.act={n,t0:now};
  if(vfx)lanzarVfx(vfx.id,vfx.x,vfx.y,now,S.map,false);
  return wait(duracion(g,n)).then(()=>{if(P.act&&P.act.n===n)P.act=null;});
}

/* ---------- efectos ---------- */
function lanzarVfx(id,x,y,now,capa,sube){if(animDe(id,'efecto'))ARTE.vfx.push({id,x,y,t0:now,capa,sube});}
function pintarVfx(now,cam,capa){
  ARTE.vfx=ARTE.vfx.filter(v=>now-v.t0<duracion(v.id,'efecto'));
  for(const v of ARTE.vfx){
    if(v.capa!==capa)continue;
    const t=now-v.t0,fi=Math.floor(t*(animDe(v.id,'efecto').fps||10)/1000);
    const dy=v.sube?Math.floor(fi/3):0,dx=v.sube&&capa==='town'?Math.floor(fi/6):0;   // sube 1 px cada 3 fotogramas; viento en la calle
    dibujar(v.id,'efecto','unica',t,v.x-cam.x+dx,v.y-cam.y-dy);
  }
}

/* ---------- mundo: tiles, objetos, edificios, plantas ---------- */
function arteTile(k,tx,ty,sx,sy,now){
  if(!ARTE.ok)return false;
  const an=ARTE.sobre['tile:'+k];
  if(an){
    const [g,s]=an[0],a=animDe(g,s);
    const pis=!a.bucle;   // p. ej. hierba pisada: solo con el jugador encima
    if(!pis||(P.x===tx&&P.y===ty)){
      const f=frameDe(g,s,'unica',pis?now-(P.pisT||now):now,{bucle:!pis});
      if(f){if(f.c.width>=32)ctx.drawImage(f.c,(tx&1)*16,(ty&1)*16,16,16,sx,sy,16,16);else ctx.drawImage(f.c,sx,sy);return true;}
    }
  }
  const f=frameDe(ARTE.cubre['tile:'+k],k,'unica',0,{i:0});if(!f)return false;
  if(f.c.width>16&&f.c.height===16){ctx.drawImage(f.c,variante(k,tx,ty)*16,0,16,16,sx,sy,16,16);return true;}   // tira de variantes (orgánico)
  ctx.drawImage(f.c,sx,sy,16,16);
  if(k==='grass')detalle(tx,ty,sx,sy);
  return true;
}
// orgánico (1.10): un hash de la casilla (el mismo en pinta.gd) para que nada vaya a compás de la rejilla: qué variante de un firme
// sale (la 0, la lisa, la que más: de 8 o de 6 tiradas, las que pasan de 3 son la 0), qué detalle lleva la hierba y dónde, y
// cuánto se corre (y si va en espejo) cada árbol y cada monte
const hashT=(x,y)=>{const a=(x*1103+y*2459+x*y*31)%9973;return (a*a+x*7+y*3)%9973;};
const TIRADAS={hormigon:8,pista:8,rotoT:6,rotoB:6};
function variante(k,tx,ty){const v=(hashT(tx,ty)>>2)%(TIRADAS[k]||4);return v<4?v:0;}
// en 1 de cada 4 casillas de hierba, uno de los 5 detalles (8 × 8) en cualquier sitio de la casilla (sin salirse: la de al lado lo taparía)
function detalle(tx,ty,sx,sy){
  if(P.x===tx&&P.y===ty)return;const h=hashT(tx,ty);if(h%4)return;
  const f=frameDe(ARTE.cubre['misc:detalles'],'detalles','unica',0,{i:0});if(!f)return;
  ctx.drawImage(f.c,Math.floor(h/3)%5*8,0,8,8,sx+Math.floor(h/7)%9,sy+Math.floor(h/11)%9,8,8);
}
// cuánto se corre cada objeto alto de su casilla ([±x, ±y] px) y si va en espejo
const DESF={tree:[6,3],tree2:[6,3],manzano:[5,3],monte:[4,2],monte2:[4,2]};
function desfase(o,x,y){const r=DESF[o];if(!r)return {dx:0,dy:0,esp:0};const h=hashT(x,y),n=2*r[0]+1;
  return {dx:h%n-r[0],dy:Math.floor(h/n)%(2*r[1]+1)-r[1],esp:Math.floor(h/97)%2};}
// orillas (F4b): sobre el agua, la tierra o la plaza que toca hierba, la transición Wang de PixelLab.
// Cada esquina es «hierba» si alguna de las 3 casillas que la comparten es hierba; máscara NW=1 NE=2 SW=4 SE=8.
// La superposición deja ver el tile de debajo (el agua sigue animada); rodeada del todo (15) no se pinta.
const TRANS={water:'agua',dirt:'tierra',plaza:'plaza',pista:'tierra'},HIERBA=/^(grass|flowers|tallgrass)$/;
function mascaraOrilla(m,tx,ty){
  const H=(x,y)=>x>=0&&y>=0&&x<m.w&&y<m.h&&HIERBA.test(m.g[y][x]);
  const n=H(tx,ty-1),s=H(tx,ty+1),w=H(tx-1,ty),e=H(tx+1,ty);
  return (w||n||H(tx-1,ty-1))|(e||n||H(tx+1,ty-1))<<1|(w||s||H(tx-1,ty+1))<<2|(e||s||H(tx+1,ty+1))<<3;
}
function arteOrilla(m,k,tx,ty,sx,sy){
  const t=TRANS[k];if(!t||!ARTE.ok)return false;
  const mk=mascaraOrilla(m,tx,ty);if(!mk||mk===15)return false;
  const f=frameDe('tileset-transiciones',t+'-'+String(mk).padStart(2,'0'),'unica',0,{i:0});if(!f)return false;
  ctx.drawImage(f.c,sx,sy,16,16);return true;
}
// objetos: los de 1 casilla en el suelo; los altos van a la lista ordenada por Y (tapan al jugador si está detrás). Los de la
// pared (fila de abajo de la pared, 2 m a 16 px/m), subidos a su altura (1.10, ALZA px): ventanas y cuadros con el alféizar a
// 0,9 m, las baldas de las plantas a 1 m y la de las botellas a 1,05 m (antes, todos a ras de suelo)
const ALZA={iwin:-13,poster:-13,shelfW:-16,bottles:-13};
// los muebles que dejan sombra en el suelo (1.10 P5): como la de los personajes, 1 px a cada lado del dibujo en sus 2 últimas filas y
// la fila de debajo, sin pisar el objeto de la casilla de al lado ni el de debajo. Van a «sombras» y se pintan con todo el suelo ya puesto
const SOMBRA_OBJ=new Set(['fridge','crate','table','btable','stool','plantDeco','lab','lab2','pc','display','counter','barcounter','jukebox','bench','bedB']);
function arteObj(o,tx,ty,cam,now,list,sombras){
  if(!ARTE.ok)return false;
  if(SEGUNDA.has(o))return !!ARTE.cubre['obj:'+o.slice(0,-1)];   // la mitad de la derecha de un mueble del salón: la pinta la de la izquierda
  const g=ARTE.cubre['obj:'+o];if(!g)return false;
  const an=ARTE.sobre['obj:'+o],d=desfase(o,tx,ty);
  const f=an?frameDe(an[0][0],an[0][1],'unica',now,{bucle:true}):frameDe(g,o,'unica',0,{i:0,esp:d.esp});
  if(!f)return false;
  const xp=tx*16+8+d.dx-cam.x,yp=ty*16+15+d.dy+(ALZA[o]||0)-cam.y;
  if(sombras&&SOMBRA_OBJ.has(o)){
    const m=MAPS[S.map],ob=(x,y)=>{const r=m.o[y];return !!(r&&r[x]);},[a,b]=vcCaja(f.c),x0=Math.round(xp-f.cel.ancla[0])+a,x1=x0+b-a,sx=tx*16-cam.x;
    if(x0-1>=sx||!ob(tx-1,ty))sombras.push([x0-1,yp-1,1,2]);
    if(x1+1<=sx+15||!ob(tx+1,ty))sombras.push([x1+1,yp-1,1,2]);
    if(!ob(tx,ty+1))sombras.push([x0,yp+1,x1-x0+1,1]);}
  if(f.cel.h>16&&list)list.push([ty*16+Math.min(0,d.dy),()=>pinta(f,xp,yp)]);else pinta(f,xp,yp);   // corrido hacia abajo, no pasa delante de quien está en su fila
  return true;
}
// edificios grises con puerta (1.10): su fachada (b.fachada, con hueco para la puerta), la puerta de otra (b.puerta) y, con b.mascara,
// sin su trozo de pared (PARED: los colores de la fachada del piso, quitados desde el borde del fotograma hacia dentro mientras sigan siendo pared)
const PARED=new Set(['248,248,240','246,232,200','224,206,170','220,214,198']),_sinPared=new Map();
function puertaSinPared(c){
  let o=_sinPared.get(c);if(o)return o;
  const w=c.width,h=c.height,[d,x]=mkCanvas(w,h);x.drawImage(c,0,0);const im=x.getImageData(0,0,w,h),p=im.data,st=[];
  for(let i=0;i<w;i++)st.push(i,(h-1)*w+i);for(let j=0;j<h;j++)st.push(j*w,j*w+w-1);
  while(st.length){const i=st.pop();if(!p[i*4+3]||!PARED.has(p[i*4]+','+p[i*4+1]+','+p[i*4+2]))continue;p[i*4+3]=0;
    const xi=i%w,yi=(i-xi)/w;if(xi>0)st.push(i-1);if(xi<w-1)st.push(i+1);if(yi>0)st.push(i-w);if(yi<h-1)st.push(i+w);}
  x.putImageData(im,0,0);_sinPared.set(c,d);return d;
}
function arteEdificios(m,cam){
  if(!ARTE.ok||!m.blds)return;
  for(const b of m.blds){
    const g='edificio-'+(b.fachada||b.id),f=frameDe(g,'base','unica',0,{i:0});if(!f)continue;
    ctx.drawImage(f.c,b.x0*16-cam.x,b.y0*16-cam.y);
    const gp='edificio-'+(b.puerta||b.id);
    if(b.doorX!=null&&animDe(gp,'puerta')){
      const dy=b.y0+b.h-1,abierta=P.x>=b.doorX&&P.x<=b.doorX+(b.ancha?1:0)&&(P.y===dy||P.y===dy+1);
      const p=frameDe(gp,'puerta','unica',0,{i:abierta?-1:0});
      if(p)ctx.drawImage(b.mascara?puertaSinPared(p.c):p.c,b.doorX*16-8+(b.dx||0)-cam.x,(dy+1)*16-32-cam.y);
    }
  }
}
// carpas: en el piso, un mueble ('carpa-<t>-mapa', celda carpa_mapa, pies en el centro de su base); por dentro, la
// vista B (09b-carpa.js), de frente con 'carpa-<t>-vista' (VB_PLATA)
const fotoMisc=n=>ARTE.ok&&frameDe(ARTE.cubre['misc:'+n],n,'unica',0,{i:0});
function arteCarpaMapa(t,xc,yb){const f=fotoMisc('carpa-'+t+'-mapa');if(!f)return false;pinta(f,xc,yb);return true;}
// pinta c en (x, y) por franjas de 2 filas desplazadas con un seno: la base (fila b) quieta y la copa hasta ±a px
function balanceo(c,x,y,b,a,t){
  if(!a){ctx.drawImage(c,Math.round(x),Math.round(y));return;}
  const s=Math.sin(t/950)*.7+Math.sin(t/410)*.3;
  for(let r=0;r<c.height;r+=2){const dx=Math.round(a*s*Math.max(0,(b-r)/b)**1.5);ctx.drawImage(c,0,r,c.width,2,Math.round(x)+dx,Math.round(y)+r,c.width,2);}
}
// criaturas de ambiente: paloma junto a Patxi, gaviotas en el muelle
function arteCriaturas(now,cam,list){
  if(!ARTE.ok||S.map!=='town')return;
  const m=MAPS.town;
  if(animDe('paloma','idle')){const e=ents.find(e=>e.id==='patxi');if(e)list.push([e.py,()=>dibujar('paloma','idle','unica',now,e.px+24-cam.x,e.py+15-cam.y)]);}
  if(animDe('gaviota','idle')){
    if(!m.docks){m.docks=[];for(let y=0;y<m.h;y++)for(let x=0;x<m.w;x++)if(m.g[y][x]==='dock'&&!m.o[y][x])m.docks.push([x,y]);m.docks=m.docks.filter((_,i)=>i%5===2).slice(0,2);}
    for(const [x,y] of m.docks)list.push([y*16,()=>dibujar('gaviota','idle','unica',now+x*311,x*16+8-cam.x,y*16+15-cam.y)]);
  }
}

/* ---------- combate ---------- */
function grupoCombate(who){
  if(!ARTE.ok||!B)return null;
  if(who==='P')return ARTE.cubre['combate:espalda:player']||null;
  if(B.kind==='thief')return grupoLook(B.look)||ARTE.cubre['combate:frente:ladron']||null;
  return ARTE.cubre['combate:frente:policia']||null;
}
// lanza una animación de combate; devuelve su duración en ms (0 sin atlas)
function bAnim(who,n){const g=grupoCombate(who);if(!g||!animDe(g,n))return 0;B['a'+who]={n,t0:performance.now()};return duracion(g,n);}
function vfxCombate(id,x,y){if(ARTE.ok)lanzarVfx(id,x,y,performance.now(),'*',false);}
function combFrame(who,now){
  const g=grupoCombate(who);if(!g)return null;
  const a=B['a'+who],dir=who==='P'?'north':'south';
  if(a){const t=now-a.t0;if(t<duracion(g,a.n)||a.n==='desmayo')return frameDe(g,a.n,a.n==='huir'?'east':dir,t,{bucle:a.n==='huir'});B['a'+who]=null;}
  return frameDe(g,'idle',dir,now,{bucle:true})||frameDe(g,'base',dir,0,{i:0});
}
// personaje del atlas a ×k (intro: Kiko presentándose), de frente, con su idle si lo tiene; pies en (cx, fy)
function arteRetrato(look,cx,fy,now,k=2){
  const g=grupoLook(look);if(!g)return false;
  const f=(tieneDir(g,'idle','south')&&frameDe(g,'idle','south',now,{bucle:true}))||frameDe(g,'base','south',0,{i:0});if(!f)return false;
  ctx.drawImage(f.c,Math.round(cx-f.cel.ancla[0]*k),Math.round(fy-f.cel.ancla[1]*k),f.c.width*k,f.c.height*k);return true;
}
// iconos de PixelLab para los menús (DOM): data URL de un fotograma; el cogollo de la Genoteca con el color de la variedad
// (los de la lámina de iconos-menu, dibujados a mano, primero: el cogollo fresco sustituye al de PixelLab)
const ICO={},ICO_N={};
// el icono, centrado en su celda por lo que pinta (sin el aire de arriba o de abajo que traiga): así queda a la altura del texto
function icoCentrado(c){
  const w=c.width,h=c.height,d=c.getContext('2d').getImageData(0,0,w,h).data;let x0=w,y0=h,x1=-1,y1=-1;
  for(let y=0;y<h;y++)for(let x=0;x<w;x++)if(d[(y*w+x)*4+3]){if(x<x0)x0=x;if(x>x1)x1=x;if(y<y0)y0=y;if(y>y1)y1=y;}
  if(x1<0)return c;const bw=x1-x0+1,bh=y1-y0+1,[o,ox]=mkCanvas(w,h);ox.drawImage(c,x0,y0,bw,bh,(w-bw)>>1,(h-bh)>>1,bw,bh);return o;
}
const icoURL=c=>{const u=icoCentrado(c).toDataURL();ICO_N[u]=c.width;return u;};
// lado del icono en el menú (px CSS): unas 12 u, a un múltiplo entero de sus píxeles en la pantalla (o a la mitad, un tercio…): cada píxel, igual
function icPx(n){const us=parseFloat($('consola').style.getPropertyValue('--us'))||1,d=window.devicePixelRatio||1,t=12*us*d/n,k=t>=1?Math.round(t):1/Math.round(1/t);return n*k/d;}
function icono(n){
  if(!ARTE.ok)return null;if(n in ICO)return ICO[n];
  const f=frameDe('iconos-menu',n,'unica',0,{i:0})||frameDe('iconos',n,'unica',0,{i:0})||frameDe('iconos-equipo',n,'unica',0,{i:0});return ICO[n]=f?icoURL(f.c):null;
}
// el icono del equipo (lámina 12): los LED, su panel; los demás focos, la lámpara; armarios (60 y 80) y carpas; cada extra, el suyo
const icoFoco=k=>FOCOS[k]&&FOCOS[k].tipo==='led'?'led':'lampara',icoCarpa=t=>t==='p60'||t==='p80'?'armario':'carpa',
  ICX={vent:'ventilador',filtro:'filtro',garrafas:'garrafa',goteo:'goteo',intra:'ventilador',filtro100:'filtro',filtro150:'filtro'};
function iconoCogollo(sid){
  if(!ARTE.ok)return null;const s=getStrain(sid),key='c|'+sid+'|'+(s&&s.c);if(key in ICO)return ICO[key];
  const t=TIPO_COGOLLO[sid]||'hibrido',f=frameDe('cogollos-genoteca',t,'unica',0,{i:0});if(!f||!s)return ICO[key]=null;
  const rk=ARTE.d.rampas&&ARTE.d.rampas['cogollos-genoteca']&&ARTE.d.rampas['cogollos-genoteca'].cogollo;
  const c=rk?conRampa(f.c,{[rk.rampa[0]]:shade(s.c,50),[rk.rampa[1]]:s.c,[rk.rampa[2]]:shade(s.c,-60)},'g|'+s.c):f.c;
  return ICO[key]=icoURL(c);
}
function arteTitulo(){
  const g=ARTE.ok&&ARTE.cubre['misc:hoja-titulo'];if(!g)return false;
  const f=frameDe(g,'base','unica',0,{i:0});if(!f)return false;fondoAncho(f.c);return true;
}
function arteFondoCombate(){
  const g=ARTE.ok&&ARTE.cubre['combate:fondo-'+(B.kind==='thief'?'ladron':'policia')];if(!g)return false;
  const f=frameDe(g,'base','unica',0,{i:0});if(!f)return false;fondoAncho(f.c,CORTES_COMBATE);return true;
}

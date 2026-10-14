/* =========================================================
   RENDER
   ========================================================= */
const camera=()=>{const m=MAPS[S.map];let cx=P.px+8-SW/2,cy=P.py+8-SH/2;const mw=m.w*16,mh=m.h*16;
  cx=mw<=SW?(mw-SW)/2:clamp(cx,0,mw-SW);cy=mh<=SH?(mh-SH)/2:clamp(cy,0,mh-SH);return{x:Math.round(cx),y:Math.round(cy)};};
const GLYPH={'$':['..#..','.####','#.#..','.###.','..#.#','####.','..#..'],'!':['..#..','..#..','..#..','..#..','..#..','.....','..#..'],'gota':['..#..','..#..','.###.','.###.','#####','#####','.###.']};   // gota: el catador de rosin (1.10)
function bubble(x,y,ch,col){ctx.fillStyle='#26262e';ctx.fillRect(x-1,y-1,9,10);ctx.fillStyle='#ffffff';ctx.fillRect(x,y,7,8);ctx.fillRect(x+2,y+8,3,1);
  ctx.fillStyle=col;GLYPH[ch].forEach((r,j)=>{for(let i=0;i<5;i++)if(r[i]==='#')ctx.fillRect(x+1+i,y+(j>3?j-0:j)+0,1,1);});}
function storyMark(id){
  switch(id){case 'kiko':return !S.flags.kiko1||(S.ch===4&&!S.flags.lab);case 'baltasar':return (S.ch===3&&!S.flags.metB)||(S.due>0&&S.money>=S.due)||(S.ch>=8&&!S.encargo&&!(S.encVeto>S.day));case 'tono2':return isNight();
    case 'jurado':return true;case 'molina':return !S.flags.molina1||!S.protect;case 'darko':return S.ch<6;case 'darko2':return S.ch>=DARKO.ch&&!S.flags.darkoFin;case 'txaro':return S.ch>=2&&!S.flags.txaro||S.ch>=4&&!S.flags.txaro2;case 'inaki':return !S.flags.inaki;case 'julen':return !S.flags.julen1;}
  return false;
}
let LAMPS={};   // farolas de cada zona de fuera (1.10): su luz de noche
function renderWorld(now,camFija){   // camFija: cámara explícita y sin jugador (tools/plano.js pinta los mapas enteros a trozos)
  const m=MAPS[S.map],cam=camFija||camera();
  ctx.fillStyle='#000';ctx.fillRect(0,0,SW,SH);
  const wf=Math.floor(now/500)%2,tx0=Math.floor(cam.x/16),ty0=Math.floor(cam.y/16);
  const list=[],sombras=[];
  // hasta 6 filas por debajo y 2 casillas a cada lado de la pantalla (1.10): los objetos altos (el árbol, de 6 filas; el monte, 3 de
  // ancho) se ven aunque su pie esté fuera; antes la copa salía de golpe al entrar el pie
  for(let ty=ty0;ty<=ty0+Math.ceil(SH/16)+6;ty++)for(let tx=tx0-2;tx<=tx0+Math.ceil(SW/16)+2;tx++){
    if(tx<0||ty<0||tx>=m.w||ty>=m.h)continue;
    const sx=tx*16-cam.x,sy=ty*16-cam.y,k=m.g[ty][tx],a=TILES[k];
    if(!arteTile(k,tx,ty,sx,sy,now))ctx.drawImage(a[a.length>1?wf:0],sx,sy);
    else arteOrilla(m,k,tx,ty,sx,sy);
    const o=m.o[ty][tx];
    if(o&&o!=='carpa'&&!arteObj(o,tx,ty,cam,now,list,sombras))ctx.drawImage(TILES[o][0],sx,sy);
  }
  ctx.fillStyle='rgba(0,0,0,.22)';for(const r of sombras)ctx.fillRect(...r);
  arteEdificios(m,cam);
  if(S.map==='home'){
    // carpas: muebles de 1-2 casillas, pintados enteros desde su base (tapan al jugador si pasa por detrás); con plantas,
    // la luz se escapa bajo la puerta. Sitio libre: el hueco marcado en el suelo.
    for(const t of m.carpas)list.push([t.y*16,()=>pintarCarpaMapa(t,cam)]);
    SITIOS.forEach((st,ci)=>{if(!sitioVisible(ci))return;ctx.strokeStyle='rgba(60,70,90,.45)';ctx.setLineDash([3,2]);ctx.strokeRect(st.x*16+1.5-cam.x,st.y*16+.5-cam.y,st.w*16-3,15);ctx.setLineDash([]);});
    if(!S.flags.letter){const lx=3*16-cam.x,ly=5*16-cam.y;ctx.fillStyle='#fafaf2';ctx.fillRect(lx+5,ly+5,7,5);ctx.fillStyle='#c04040';ctx.fillRect(lx+8,ly+7,2,1);}
  }
  if(S.map==='nave')list.push([2*16-1,()=>{ctx.save();ctx.translate(-cam.x,-cam.y);pintaRects(mangueraNave());ctx.restore();}]);   // 1.33: la manguera del riego, detrás de lo de la fila 2
  const fr=(e,dur)=>e.moving&&e.t/dur<.5?1+((e.x+e.y)&1):0;
  if(ARTE.ok)for(const e of ents)ambiente(e,now,cam);
  if(ZONAS[S.map])pintarVistas(cam);   // por dónde miran las patrullas, de día (10b-patrulla)
  for(const e of ents)list.push([e.py,()=>{if(!dibujarPJ(e,e.look,now,cam,false,e.dur||320))ctx.drawImage(spriteFor(e.look,e.dir,fr(e,e.dur||320)),Math.round(e.px-cam.x),Math.round(e.py-cam.y-4));}]);
  if(!camFija)list.push([P.py,()=>{if(!dibujarPJ(P,LOOKS.player,now,cam,true,P.dur))ctx.drawImage(spriteFor(LOOKS.player,P.dir,P.moving&&P.t/P.dur<.5?1+P.parity:0),Math.round(P.px-cam.x),Math.round(P.py-cam.y-4));}]);
  const bolsa=ARTE.ok&&frameDe(ARTE.cubre['misc:bolsa'],'bolsa','unica',0,{i:0});
  for(const it of ITEMS)if(!it.hidden&&it.map===S.map&&!S.taken[it.id])list.push([it.y*16,()=>{const x=it.x*16-cam.x,y=it.y*16-cam.y;if(bolsa)pinta(bolsa,x+8,y+8);else ctx.drawImage(bagSprite,x,y);}]);
  arteCriaturas(now,cam,list);
  list.sort((a,b)=>a[0]-b[0]).forEach(o=>o[1]());
  if(ARTE.ok)pintarVfx(now,cam,S.map);
  const bob=Math.floor(now/400)%2;
  for(const e of ents){const bx=Math.round(e.px-cam.x)+4,by=Math.round(e.py-cam.y)-16+bob;
    if(e.def.client)bubble(bx,by,...e.def.client.type==='ext'?['gota','#d08a10']:['$','#2a9a4a']);else if(storyMark(e.id)||e.caza)bubble(bx,by,'!','#e03030');}
  // el piso de noche (1.10 P5): se oscurece como la calle y cada carpa encendida deja delante una mancha de la luz de su foco
  if(S.map==='home'){const a=nocheA();
    if(a>0){ctx.fillStyle=`rgba(14,20,72,${a})`;ctx.fillRect(0,0,SW,SH);ctx.globalCompositeOperation='lighter';
      for(const t of m.carpas){if(!plantasVivas(t.ci))continue;const xc=(t.x0+t.x1+1)*8-cam.x,yb=t.y*16+15-cam.y,k=FOCO_LUZ[FOCOS[S.carpas[t.ci].foco].tipo];
        const g=ctx.createRadialGradient(xc,yb+5,1,xc,yb+5,18);g.addColorStop(0,k+(a*1.2)+')');g.addColorStop(1,k+'0)');ctx.fillStyle=g;ctx.fillRect(xc-20,yb-4,40,24);}
      ctx.globalCompositeOperation='source-over';}}
  if(ZONAS[S.map]){
    const h=S.min/60;let a=nocheA();
    if(h>=17.5&&h<20.5){ctx.fillStyle=`rgba(255,130,50,${.13*Math.sin((h-17.5)/3*Math.PI)})`;ctx.fillRect(0,0,SW,SH);}
    if(a>0){ctx.fillStyle=`rgba(14,20,72,${a})`;ctx.fillRect(0,0,SW,SH);
      if(a>.2){ctx.globalCompositeOperation='lighter';for(const [lx,ly] of LAMPS[S.map]){const x=lx*16+8-cam.x,y=ly*16+2-cam.y;if(x<-30||y<-30||x>SW+30||y>SH+30)continue;
        const g=ctx.createRadialGradient(x,y+8,1,x,y+8,28);g.addColorStop(0,`rgba(255,214,120,${a*.7})`);g.addColorStop(1,'rgba(255,214,120,0)');ctx.fillStyle=g;ctx.fillRect(x-30,y-22,60,60);}
        ctx.globalCompositeOperation='source-over';}}
  }
  if(!camFija){luzLocal(cam,now);if(MESA_B)pintaRects(rectsMesaBillar(MESA_B));if(TIRO)pintaTiro(now);}   // los locales (1.30, 11j-locales)
  if(ALMACEN)pintaRects(rectsAlmacen(ALMACEN));   // la caja fuerte y la nevera por dentro (1.36, 11m-almacen)
}
// la luz de los locales (LUZ_CLUB, LUZ_DISCO y, 1.31, los LED de la nave, luzNave): el fondo, si lo hay, encima de todo, y cada luz, un degradado radial (r 1 → r) sumado ('lighter');
// los focos de GAUA dan una vuelta a la pista cada 7 s (0,9 rad/s), cada uno desde su fase
function luzLocal(cam,now){
  const L=S.map.startsWith('club-')?LUZ_CLUB[S.map.slice(5)]:S.map==='disco'?LUZ_DISCO:S.map==='nave'?luzNave():S.map==='setas'?LUZ_BAJO:null;if(!L)return;
  if(L.fondo){ctx.fillStyle=L.fondo;ctx.fillRect(0,0,SW,SH);}ctx.globalCompositeOperation='lighter';
  const luz=(x,y,r,c,a)=>{const g=ctx.createRadialGradient(x,y,1,x,y,r);g.addColorStop(0,`rgba(${c},${a})`);g.addColorStop(1,`rgba(${c},0)`);ctx.fillStyle=g;ctx.fillRect(x-r,y-r,2*r,2*r);};
  for(const [x,y,r,c,a] of L.l||[])luz(x-cam.x,y-cam.y,r,c,a);
  for(const [c,f] of L.focos||[]){const t=now/1000*.9+f;luz(Math.round(L.c[0]+Math.cos(t)*L.r[0])-cam.x,Math.round(L.c[1]+Math.sin(t)*L.r[1])-cam.y,L.R,c,.5);}
  ctx.globalCompositeOperation='source-over';
}
// la barra del billar (1.30; 1.35, dos): la que va y viene; en la de la dirección, el verde es la tronera (TIRO.a); en la de la
// fuerza, el verde mete y el rojo del final cuela la blanca (BILLAR.falta)
function pintaTiro(now){
  const L=BILLAR,w=120,x0=(SW-w)>>1,y0=(SH-8)>>1,p=posTiro(TIRO,now),a=TIRO.f==='dir'?TIRO.a:L.verde;
  ctx.fillStyle='#26262e';ctx.fillRect(x0-2,y0-2,w+4,12);ctx.fillStyle='#3a3446';ctx.fillRect(x0,y0,w,8);
  if(TIRO.f!=='dir'){ctx.fillStyle='#e04040';ctx.fillRect(x0+Math.round(L.falta*w),y0,w-Math.round(L.falta*w),8);}
  ctx.fillStyle='#58d080';ctx.fillRect(x0+Math.round((centroTiro(TIRO,now)-a)*w),y0,Math.round(2*a*w),8);
  ctx.fillStyle='#ffffff';ctx.fillRect(x0+Math.round(p*(w-2)),y0-1,2,10);
}
// lo oscura que está la noche (0 de día, .5 de 21 a 5, en rampa de 19 a 21 y de 5 a 7)
function nocheA(){const h=S.min/60;return h>=21||h<5?.5:h>=19?(h-19)/2*.5:h<7?(7-h)/2*.5:0;}
/* ---------- luz de los focos y caché de la carpa (09b-carpa.js) ---------- */
const FOCO_LUZ={cfl:'rgba(220,240,255,',sodio:'rgba(255,170,70,',led:'rgba(240,170,255,'};
const carpaCache={};
let titleArt,battleBg={};
function makeArt(){
  {const [c,x]=mkCanvas(64,64);const t=painter(x,rngSeed(2));drawLeafPx(t,32,38,13.6,'#164a26');drawLeafPx(t,32,38,12.4,'#4cc066');drawLeafPx(t,32,38,7,'#7ee08a');titleArt=c;}
  for(const kind of ['thief','police']){
    const [c,x]=mkCanvas(240,160);const R=rngSeed(kind==='thief'?3:4);const nite=kind==='thief';
    const sky=nite?['#241c48','#3a2a66','#5a3a78','#7a4a80']:['#4a78c0','#6a98d8','#94bce8','#c0dcf4'];
    for(let y=0;y<92;y++){x.fillStyle=sky[Math.min(3,Math.floor(y/23))];x.fillRect(0,y,240,1);}
    if(nite)for(let i=0;i<30;i++){x.fillStyle='#f0f0ff';x.fillRect(Math.floor(R()*240),Math.floor(R()*50),1,1);}
    let bx=-4;while(bx<240){const w=18+Math.floor(R()*24),h=22+Math.floor(R()*40);x.fillStyle=nite?'#1a1630':'#5c6c8c';x.fillRect(bx,92-h,w,h);x.fillStyle=nite?'#221d3c':'#6a7a9a';x.fillRect(bx,92-h,w,2);
      for(let wy=92-h+5;wy<86;wy+=7)for(let wx=bx+3;wx<bx+w-3;wx+=6)if(R()<.55){x.fillStyle=nite?(R()<.7?'#f0d070':'#f09a50'):'#aac8ea';x.fillRect(wx,wy,2,3);}bx+=w+2;}
    x.fillStyle=nite?'#3a3a4a':'#8a92a2';x.fillRect(0,92,240,68);
    for(let y=94;y<160;y+=7){x.fillStyle=nite?'#343444':'#808898';x.fillRect(0,y,240,2);}
    const ell=(cx,cy,rx,ry,f,rim)=>{x.fillStyle=rim;x.beginPath();x.ellipse(cx,cy,rx,ry,0,0,Math.PI*2);x.fill();x.fillStyle=f;x.beginPath();x.ellipse(cx,cy-1,rx-3,ry-2.5,0,0,Math.PI*2);x.fill();};
    ell(178,64,44,10,nite?'#4a4a5e':'#a8b0be',nite?'#2a2a38':'#6a7282');ell(66,142,56,12,nite?'#4a4a5e':'#a8b0be',nite?'#2a2a38':'#6a7282');
    battleBg[kind]=c;
  }
  LAMPS={};for(const k in ZONAS){const m=MAPS[k],l=LAMPS[k]=[];for(let y=0;y<m.h;y++)for(let x=0;x<m.w;x++)if(m.o[y][x]==='lamp')l.push([x,y]);}
}
// escenas compuestas a 240 × 160 (título, intro, combate y carpa): van centradas y abajo (OY: los 20 px de más de arriba) y el
// fondo se alarga a los lados con su reflejo, y arriba con el reflejo de sus primeras filas.
// cortes: franjas [y0,y1,lado] que toman las dos bandas del mismo borde ('izq'/'dch': reflejo en su lado, copia en el otro),
// para no repetir trozos de las tarimas del combate; sin cortes, cada banda refleja su borde.
const OX=()=>(SW-240)>>1,OY=()=>SH-160;
const CORTES_COMBATE=[[0,92,'izq'],[92,160,'dch']];   // cielo y edificios del borde izquierdo; suelo del derecho (fondos de 240×160)
function fondoAncho(img,cortes){
  const ox=OX(),oy=OY();ctx.drawImage(img,ox,oy);
  if(ox)for(const [y0,y1,lado] of cortes||[[0,160,'']]){const h=y1-y0,y=y0+oy;
    ctx.save();ctx.scale(-1,1);
    if(lado!=='dch')ctx.drawImage(img,0,y0,ox,h,-ox,y,ox,h);
    if(lado!=='izq')ctx.drawImage(img,240-ox,y0,ox,h,-SW,y,ox,h);
    ctx.restore();
    if(lado==='dch')ctx.drawImage(img,240-ox,y0,ox,h,0,y,ox,h);
    if(lado==='izq')ctx.drawImage(img,0,y0,ox,h,240+ox,y,ox,h);
  }
  if(oy){ctx.save();ctx.scale(1,-1);ctx.drawImage(cv,0,oy,SW,oy,0,-oy,SW,oy);ctx.restore();}   // arriba, las primeras oy filas del todo, al revés
}
function renderBattle(now){
  if(!arteFondoCombate())fondoAncho(battleBg[B.kind],CORTES_COMBATE);
  ctx.save();ctx.translate(OX(),OY());
  const k=Math.min(1,B.t/700),e=1-Math.pow(1-k,3);
  const ex=Math.round(154-(1-e)*180),px=Math.round(40+(1-e)*190);
  const fE=combFrame('E',now),fP=combFrame('P',now);
  const sh=B.shakeP>0?Math.round(Math.sin(B.shakeP/18)*3):0;
  if(fE){if(B.gone&&B.aE&&B.aE.n==='huir')pinta(fE,ex+24+Math.round((now-B.aE.t0)*.12),66);
    else if(!B.gone&&!(B.flashE>0&&Math.floor(B.flashE/70)%2===0))pinta(fE,ex+24,66);}
  else if(!B.gone&&!(B.flashE>0&&Math.floor(B.flashE/70)%2===0))ctx.drawImage(spriteFor(B.look,'down',0),ex,6,48,60);
  if(fP)pinta(fP,px+24+sh,142,ropaC(fP,grupoCombate('P')));else ctx.drawImage(spriteFor(LOOKS.player,'up',0),px+sh,82,48,60);
  if(ARTE.ok)pintarVfx(now,{x:0,y:0},'*');
  ctx.restore();
}
/* ---------- el título (1.35, lo pidió el usuario) ----------
   Detrás del azul, una partida que se juega sola: el barrio al atardecer, el protagonista sale del portal, se para con un cliente,
   sigue la calle y vuelve, y un agente hace la ronda. Todo sale del reloj (demoEn): el mismo instante se ve igual en el HTML y en
   Godot. Rutas cerradas de [x, y, pausa al llegar en ms, hacia dónde mira en la pausa], a dur ms por casilla; azul: el alfa de la
   capa de arriba abajo, por bandas (DEMO.bandas), más opaca donde va el rótulo */
const DEMO={map:'town',min:1200,P:{dur:320,ruta:[[5,9,700,'down'],[5,10],[12,10,1600,'up'],[33,10,900,'down'],[5,10]]},
  poli:{dur:420,ruta:[[36,11],[2,11,600,'right']]},cliente:[12,9],azul:[14,22,60],alfa:[.66,.34],bandas:12};
let demoS=null,demoE=null;
function demoEn(R,T){
  const tr=R.ruta.map((a,i)=>{const b=R.ruta[(i+1)%R.ruta.length];return [a,b,Math.abs(b[0]-a[0])+Math.abs(b[1]-a[1])];});
  const tot=tr.reduce((s,[,b,n])=>s+n*R.dur+(b[2]||0),0);let t=T%tot;
  for(const [a,b,n] of tr){const dx=Math.sign(b[0]-a[0]),dy=Math.sign(b[1]-a[1]),dir=dx>0?'right':dx<0?'left':dy>0?'down':'up';
    if(t<n*R.dur){const k=Math.floor(t/R.dur),f=t-k*R.dur,x=a[0]+dx*k,y=a[1]+dy*k;
      return {x:x+dx,y:y+dy,px:(x+dx*f/R.dur)*16,py:(y+dy*f/R.dur)*16,dir,moving:true,t:f,dur:R.dur,parity:k&1};}
    t-=n*R.dur;const p=b[2]||0;
    if(t<p)return {x:b[0],y:b[1],px:b[0]*16,py:b[1]*16,dir:b[3]||dir,moving:false,t:0,dur:R.dur,parity:0};
    t-=p;}
  const a=R.ruta[0];return {x:a[0],y:a[1],px:a[0]*16,py:a[1]*16,dir:'down',moving:false,t:0,dur:R.dur,parity:0};
}
// la partida de fondo: S, los personajes y el jugador de la demo mientras se pinta (lo de la partida, intacto)
function renderDemo(now){
  const s0=S,e0=ents;
  if(!demoS)demoS=Object.assign(newState(),{map:DEMO.map,min:DEMO.min});
  S=demoS;
  try{
    if(!demoE){const [cx,cy]=DEMO.cliente,quieto=(id,x,y,dir,look,def)=>({id,x,y,px:x*16,py:y*16,hx:x,hy:y,fx:x,fy:y,dir,look,def,moving:false,t:0,dur:320});
      demoE=NPCDEF.filter(d=>d.map===DEMO.map&&(!d.cond||d.cond())).map(d=>quieto(d.id,d.x,d.y,d.dir||'down',d.lookObj||LOOKS[d.look],d))
        .concat([quieto('demo1',cx,cy,'down',randLook('demo1','client'),{client:{type:'cur'}}),quieto('demo2',0,0,'left',LOOKS.cop,{})]);}
    ents=demoE;Object.assign(demoE[demoE.length-1],demoEn(DEMO.poli,now));Object.assign(P,demoEn(DEMO.P,now));
    renderWorld(now);
  }finally{S=s0;ents=e0;}
  const [r,g,b]=DEMO.azul,[a0,a1]=DEMO.alfa,n=DEMO.bandas,h=Math.ceil(SH/n);
  for(let i=0;i<n;i++){ctx.fillStyle=`rgba(${r},${g},${b},${Math.round((a0+(a1-a0)*i/(n-1))*100)/100})`;ctx.fillRect(0,i*h,SW,h);}
}
function renderTitle(now){
  if(mode==='title')return renderDemo(now);
  const t=now/1000,ox=OX(),oy=OY(),art=arteTitulo();   // con atlas: el fondo de PixelLab (cielo, barrio, río y hoja); sin él, el procedural
  ctx.save();ctx.translate(ox,oy);
  if(!art){
    const sky=['#0e1638','#162250','#20306a','#2c3e7c','#3a4a86'];
    for(let y=-oy;y<110;y++){ctx.fillStyle=sky[clamp(Math.floor(y/22),0,4)];ctx.fillRect(-ox,y,SW,1);}
    for(let i=0;i<60;i++){const sx=(i*53)%SW-ox,sy=(i*29)%90;if(((i*7+Math.floor(t*2))%9)>1){ctx.fillStyle=i%5?'#c8d0ff':'#ffffff';ctx.fillRect(sx,sy,1,1);}}
    ctx.fillStyle='#0a0f1e';for(let i=0;i*18-6<SW;i++){const w=14+(i*37)%20,h=18+(i*53)%34;ctx.fillRect(i*18-6-ox,110-h,w,h);}
    ctx.fillStyle='#f0d070';for(let i=0;i<60;i++){const wx=(i*61)%SW-ox,wy=82+(i*13)%24;if((i+Math.floor(t))%7)ctx.fillRect(wx,wy,1,2);}
    ctx.fillStyle='#14284a';ctx.fillRect(-ox,110,SW,50);
  }
  for(const b of [-240,0,240])for(let y=112;y<160;y+=4){const o=Math.sin(t*1.5+y)*6;ctx.fillStyle='#1e3a64';ctx.fillRect(b+20+o+(y*7)%60,y,30,1);ctx.fillRect(b+140-o+(y*5)%50,y,24,1);}
  if(mode==='title'){if(!art){const by=Math.round(Math.sin(t*1.6)*2);ctx.globalAlpha=.55;ctx.drawImage(titleArt,88,62+by,64,64);ctx.globalAlpha=1;}}
  else{ctx.fillStyle='rgba(0,0,0,.35)';ctx.fillRect(-ox,-oy,SW,SH);ctx.fillStyle='#2a6a48';ctx.beginPath();ctx.ellipse(120,104,34,7,0,0,Math.PI*2);ctx.fill();if(!arteRetrato(LOOKS.kiko,120,104,now))ctx.drawImage(spriteFor(LOOKS.kiko,'down',0),96,44,48,60);}
  ctx.restore();
}
function updateHUD(){
  const h=$('hud');if(mode!=='world'||!S){h.hidden=true;return;}h.hidden=false;
  const hh=String(Math.floor(S.min/60)).padStart(2,'0'),mm=String(Math.floor(S.min%60/10)*10).padStart(2,'0'),heat=Math.round(S.heat);
  const r=totalRosin(),sv=Math.round(SOSP.v);hudSosp=sospHUD();
  h.innerHTML=`DÍA ${S.day} · ${hh}:${mm}<br>${eur(S.money)} · ${Math.floor(totalBuds())} g${r?' · '+coma(Math.round(r*10)/10)+' g rosin':''}<div class="heat">${S.orden?'ORDEN':'CALOR'}<span class="bar"><i class="${heat>=70?'hot':''}" style="width:${heat}%"></i></span></div>`
    +(nPatrullas()?`<div class="heat sosp">${SOSP.alarma?'¡ALARMA!':'SOSPECHA'}<span class="bar"><i class="${SOSP.alarma?'hot':''}" style="width:${SOSP.alarma?100:sv}%"></i></span></div>`:'');
}


/* =========================================================
   RENDER
   ========================================================= */
const camera=()=>{const m=MAPS[S.map];let cx=P.px+8-SW/2,cy=P.py+8-SH/2;const mw=m.w*16,mh=m.h*16;
  cx=mw<=SW?(mw-SW)/2:clamp(cx,0,mw-SW);cy=mh<=SH?(mh-SH)/2:clamp(cy,0,mh-SH);return{x:Math.round(cx),y:Math.round(cy)};};
const GLYPH={'$':['..#..','.####','#.#..','.###.','..#.#','####.','..#..'],'!':['..#..','..#..','..#..','..#..','..#..','.....','..#..']};
function bubble(x,y,ch,col){ctx.fillStyle='#26262e';ctx.fillRect(x-1,y-1,9,10);ctx.fillStyle='#ffffff';ctx.fillRect(x,y,7,8);ctx.fillRect(x+2,y+8,3,1);
  ctx.fillStyle=col;GLYPH[ch].forEach((r,j)=>{for(let i=0;i<5;i++)if(r[i]==='#')ctx.fillRect(x+1+i,y+(j>3?j-0:j)+0,1,1);});}
function storyMark(id){
  switch(id){case 'kiko':return !S.flags.kiko1||(S.ch===4&&!S.flags.lab);case 'baltasar':return (S.ch===3&&!S.flags.metB)||(S.due>0&&S.money>=S.due);
    case 'jurado':return true;case 'molina':return !S.flags.molina1;case 'darko':return S.ch<6;case 'txaro':return S.ch>=2&&!S.flags.txaro;case 'inaki':return !S.flags.inaki;}
  return false;
}
let LAMPS=[];
function renderWorld(now){
  const m=MAPS[S.map],cam=camera();
  ctx.fillStyle='#000';ctx.fillRect(0,0,SW,SH);
  const wf=Math.floor(now/500)%2,tx0=Math.floor(cam.x/16),ty0=Math.floor(cam.y/16);
  const list=[];
  for(let ty=ty0;ty<=ty0+11;ty++)for(let tx=tx0;tx<=tx0+15;tx++){
    if(tx<0||ty<0||tx>=m.w||ty>=m.h)continue;
    const sx=tx*16-cam.x,sy=ty*16-cam.y,k=m.g[ty][tx],a=TILES[k];
    if(m.carpas&&/^(cp|tent)/.test(k)){   // carpa por dentro: suelo del piso debajo y la carpa encima (atlas o procedural)
      if(!arteTile('floor',tx,ty,sx,sy,now))ctx.drawImage(TILES.floor[0],sx,sy);
      if(!arteCarpaTile(m,tx,ty,sx,sy)&&!arteTile(k,tx,ty,sx,sy,now))ctx.drawImage(a[0],sx,sy);
    }
    else if(!arteTile(k,tx,ty,sx,sy,now))ctx.drawImage(a[a.length>1?wf:0],sx,sy);
    else arteOrilla(m,k,tx,ty,sx,sy);
    const o=m.o[ty][tx];if(o&&!arteObj(o,tx,ty,cam,now,list))ctx.drawImage(TILES[o][0],sx,sy);
  }
  arteEdificios(m,cam);
  if(S.map==='home'){
    // carpas: desde fuera, cerradas (fachada con la puerta); con el jugador dentro, sin techo ni paredes de delante/derecha
    for(const t of m.carpas){
      if(dentroCarpa(t)){list.push([(t.y0+2)*16-1,()=>pintarFocos(t,cam,true)],[(t.y0+2)*16+1,()=>pintarFocos(t,cam,false)]);continue;}   // luz detrás de las plantas, focos delante
      const x=t.x0*16-cam.x,y=t.y0*16-cam.y;
      if(!arteCarpaFuera(t,x,y))ctx.drawImage(carpaFuera(t.x1-t.x0+1),x,y);
      if(plantasVivas(t.ci)){ctx.fillStyle=FOCO_LUZ[FOCOS[S.carpas[t.ci].foco].tipo]+'.55)';ctx.fillRect((t.door)*16+3-cam.x,t.y1*16+7-cam.y,10,1);}   // la luz se escapa bajo la puerta
    }
    SITIOS.forEach((st,ci)=>{if(S.carpas[ci])return;ctx.strokeStyle='rgba(60,70,90,.45)';ctx.setLineDash([3,2]);ctx.strokeRect(st.x*16+8.5-cam.x,st.y*16+.5-cam.y,6*16-17,71);ctx.setLineDash([]);});
    if(!S.flags.letter){const lx=3*16-cam.x,ly=6*16-cam.y;ctx.fillStyle='#fafaf2';ctx.fillRect(lx+5,ly+5,7,5);ctx.fillStyle='#c04040';ctx.fillRect(lx+8,ly+7,2,1);}
  }
  const fr=(e,dur)=>e.moving&&e.t/dur<.5?1+((e.x+e.y)&1):0;
  if(ARTE.ok)for(const e of ents)ambiente(e,now,cam);
  for(const e of ents)list.push([e.py,()=>{if(!dibujarPJ(e,e.look,now,cam,false,320))ctx.drawImage(spriteFor(e.look,e.dir,fr(e,320)),Math.round(e.px-cam.x),Math.round(e.py-cam.y-4));}]);
  list.push([P.py,()=>{if(!dibujarPJ(P,LOOKS.player,now,cam,true,P.dur))ctx.drawImage(spriteFor(LOOKS.player,P.dir,P.moving&&P.t/P.dur<.5?1+P.parity:0),Math.round(P.px-cam.x),Math.round(P.py-cam.y-4));}]);
  if(S.map==='home'){const vis=new Set(m.carpas.filter(dentroCarpa).map(t=>t.ci));   // plantas sobre su mesa, solo en la carpa abierta
    huecos().forEach((h,i)=>{if(!vis.has(h.c))return;list.push([h.y*16,()=>{const p=S.pots[i],k=S.macetas[i],x=h.x*16-cam.x,y=h.y*16-cam.y-MESA_ALTO;
      if(!artePlanta(p,x,y,now,k))ctx.drawImage(p?plantSprite(p,k):potVacia(k),x,y-10);}]);});}
  const bolsa=ARTE.ok&&frameDe(ARTE.cubre['misc:bolsa'],'bolsa','unica',0,{i:0});
  for(const it of ITEMS)if(!it.hidden&&it.map===S.map&&!S.taken[it.id])list.push([it.y*16,()=>{const x=it.x*16-cam.x,y=it.y*16-cam.y;if(bolsa)pinta(bolsa,x+8,y+8);else ctx.drawImage(bagSprite,x,y);}]);
  arteCriaturas(now,cam,list);
  list.sort((a,b)=>a[0]-b[0]).forEach(o=>o[1]());
  if(ARTE.ok)pintarVfx(now,cam,S.map);
  const bob=Math.floor(now/400)%2;
  for(const e of ents){const bx=Math.round(e.px-cam.x)+4,by=Math.round(e.py-cam.y)-16+bob;
    if(e.def.client)bubble(bx,by,'$','#2a9a4a');else if(storyMark(e.id))bubble(bx,by,'!','#e03030');}
  if(S.map==='town'){
    const h=S.min/60;let a=h>=21||h<5?.5:h>=19?(h-19)/2*.5:h<7?(7-h)/2*.5:0;
    if(h>=17.5&&h<20.5){ctx.fillStyle=`rgba(255,130,50,${.13*Math.sin((h-17.5)/3*Math.PI)})`;ctx.fillRect(0,0,SW,SH);}
    if(a>0){ctx.fillStyle=`rgba(14,20,72,${a})`;ctx.fillRect(0,0,SW,SH);
      if(a>.2){ctx.globalCompositeOperation='lighter';for(const [lx,ly] of LAMPS){const x=lx*16+8-cam.x,y=ly*16+2-cam.y;if(x<-30||y<-30||x>SW+30||y>SH+30)continue;
        const g=ctx.createRadialGradient(x,y+8,1,x,y+8,28);g.addColorStop(0,`rgba(255,214,120,${a*.7})`);g.addColorStop(1,'rgba(255,214,120,0)');ctx.fillStyle=g;ctx.fillRect(x-30,y-22,60,60);}
        ctx.globalCompositeOperation='source-over';}}
  }
}
/* ---------- carpa: fachada cerrada y focos colgando (procedurales; con atlas, arteCarpaFuera/arteFoco) ---------- */
const FOCO_LUZ={cfl:'rgba(220,240,255,',sodio:'rgba(255,170,70,',led:'rgba(240,170,255,'};
const carpaCache={};
function carpaFuera(w){
  if(carpaCache[w])return carpaCache[w];
  const W=w*16,[c,x]=mkCanvas(W,80),t=painter(x,rngSeed(w)),L=8,R=W-8,ww=R-L;
  const pole='#5a5e68',hi='#8a8e98',tela='#26272c',osc='#1c1d22',techo='#3e4048';
  // techo visto desde arriba (y 0-23) y frente (y 24-71) con la puerta de cremallera en la columna 1
  t.F(L,0,ww,24,techo);t.F(L,2,ww,1,'#4a4c54');for(let sx=L+16;sx<R-4;sx+=16)t.F(sx,2,1,20,'#33353c');
  t.F(L,0,ww,2,pole);t.F(L,0,ww,1,hi);t.F(L,22,ww,2,hi);t.F(L,23,ww,1,pole);t.F(L,0,2,24,pole);t.F(R-2,0,2,24,pole);
  t.blob(R-14,10,4.5,3.4,osc,'#4a4c54');t.F(R-16,4,4,5,'#b2b8c4');t.F(R-16,5,4,1,'#8a8e98');t.F(R-16,7,4,1,'#8a8e98');   // salida del extractor
  t.F(L,24,ww,48,tela);t.F(L,70,ww,2,osc);t.F(L,24,2,48,pole);t.F(R-2,24,2,48,pole);t.F(L+2,24,1,46,'#3a3c44');
  for(let sx=L+16;sx<R-4;sx+=16)if(sx!==24)t.F(sx,26,1,44,osc);
  const dx=17,dy=30;t.F(dx,dy+3,14,38,'#2e3036');t.F(dx,dy+2,14,1,'#a0a4ac');t.F(dx-1,dy+3,1,38,'#a0a4ac');t.F(dx+14,dy+3,1,38,'#a0a4ac');
  t.F(dx+1,dy+1,12,1,'#a0a4ac');t.F(dx+12,dy+4,2,3,'#e0e2e8');t.F(dx+5,dy+20,4,1,'#3a3c44');
  if(ww>48){const vx=R-22;t.F(vx,58,14,8,osc);for(let i=0;i<14;i+=3)t.F(vx+i,58,1,8,'#3a3c44');t.F(vx,58,14,1,'#3a3c44');}   // rejilla de ventilación
  return carpaCache[w]=c;
}
function focoProc(tipo){
  const key='foco|'+tipo;if(carpaCache[key])return carpaCache[key];const [c,x]=mkCanvas(32,12),t=painter(x,rngSeed(9));
  if(tipo==='led'){t.F(4,2,24,5,'#1c1d22');t.F(5,3,22,3,'#2a2b30');for(let i=6;i<26;i+=3)t.F(i,0,1,2,'#5a5e68');const d=['#ff70c0','#f4f0ff','#c070ff'];for(let i=0;i<7;i++)t.F(6+i*3,6,2,1,d[i%3]);}
  else if(tipo==='sodio'){t.F(8,1,16,2,'#5a5e68');t.F(5,3,22,3,'#c8ccd6');t.F(5,3,22,1,'#e8eaf0');t.F(4,6,24,1,'#5a5e68');for(let i=7;i<26;i+=4)t.P(i,4,'#a8aebb');t.F(10,7,12,2,'#ffb040');t.F(11,7,10,1,'#ffe0a0');}
  else{t.F(11,1,10,2,'#5a5e68');t.F(9,3,14,2,'#e8eaf0');t.F(8,5,16,1,'#5a5e68');for(let i=0;i<3;i++){t.F(11+i*4,6,2,4,'#fffbe8');t.P(11+i*4,7,'#d8d8c8');t.P(12+i*4,9,'#d8d8c8');}}
  return carpaCache[key]=c;
}
// focos de la carpa abierta: medio transparentes para que se vean las plantas; luz encendida si hay alguna planta viva.
// Dos pasadas: luz (cono sobre la pared y el suelo, por detrás de las plantas) y focos (por delante)
function pintarFocos(t,cam,luz){
  const c=S.carpas[t.ci],C=CARPAS[c.t],F=FOCOS[c.foco],n=Math.max(1,Math.round(Math.min(F.cubre,C.plazas)/2));
  const ix=(t.x0+1)*16-cam.x,iw=C.plazas*16,top=t.y0*16-cam.y,on=plantasVivas(t.ci),a=.08+.14*Math.min(1,F.w/600);
  for(let k=0;k<n;k++){
    const cx=Math.round(ix+(k+.5)*iw/n),y=top+14,hw=iw/n/2;   // y: parte de abajo del foco, justo por encima de las plantas más altas
    if(luz){if(on){ctx.globalCompositeOperation='lighter';const g=ctx.createLinearGradient(0,y,0,y+44);g.addColorStop(0,FOCO_LUZ[F.tipo]+a+')');g.addColorStop(1,FOCO_LUZ[F.tipo]+'0)');
      ctx.fillStyle=g;ctx.beginPath();ctx.moveTo(cx-9,y);ctx.lineTo(cx+9,y);ctx.lineTo(cx+hw,y+44);ctx.lineTo(cx-hw,y+44);ctx.fill();ctx.globalCompositeOperation='source-over';}continue;}
    ctx.globalAlpha=.55;
    if(!arteFoco(F.tipo,cx,y,top)){ctx.fillStyle='#2a2b30';ctx.fillRect(cx-7,top+1,1,y-top-8);ctx.fillRect(cx+6,top+1,1,y-top-8);ctx.drawImage(focoProc(F.tipo),cx-16,y-10);}
    ctx.globalAlpha=1;
  }
}
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
  LAMPS=[];const m=MAPS.town;for(let y=0;y<m.h;y++)for(let x=0;x<m.w;x++)if(m.o[y][x]==='lamp')LAMPS.push([x,y]);
}
function renderBattle(now){
  if(!arteFondoCombate())ctx.drawImage(battleBg[B.kind],0,0);
  const k=Math.min(1,B.t/700),e=1-Math.pow(1-k,3);
  const ex=Math.round(154-(1-e)*180),px=Math.round(40+(1-e)*190);
  const fE=combFrame('E',now),fP=combFrame('P',now);
  const sh=B.shakeP>0?Math.round(Math.sin(B.shakeP/18)*3):0;
  if(fE){if(B.gone&&B.aE&&B.aE.n==='huir')pinta(fE,ex+24+Math.round((now-B.aE.t0)*.12),66);
    else if(!B.gone&&!(B.flashE>0&&Math.floor(B.flashE/70)%2===0))pinta(fE,ex+24,66);}
  else if(!B.gone&&!(B.flashE>0&&Math.floor(B.flashE/70)%2===0))ctx.drawImage(spriteFor(B.look,'down',0),ex,6,48,60);
  if(fP)pinta(fP,px+24+sh,142);else ctx.drawImage(spriteFor(LOOKS.player,'up',0),px+sh,82,48,60);
  if(ARTE.ok)pintarVfx(now,{x:0,y:0},'*');
}
function renderTitle(now){
  const t=now/1000,art=arteTitulo();   // con atlas: el fondo de PixelLab (cielo, barrio, río y hoja); sin él, el procedural
  if(!art){
    const sky=['#0e1638','#162250','#20306a','#2c3e7c','#3a4a86'];
    for(let y=0;y<110;y++){ctx.fillStyle=sky[Math.min(4,Math.floor(y/22))];ctx.fillRect(0,y,SW,1);}
    for(let i=0;i<40;i++){const sx=(i*53)%240,sy=(i*29)%90;if(((i*7+Math.floor(t*2))%9)>1){ctx.fillStyle=i%5?'#c8d0ff':'#ffffff';ctx.fillRect(sx,sy,1,1);}}
    ctx.fillStyle='#0a0f1e';for(let i=0;i<14;i++){const w=14+(i*37)%20,h=18+(i*53)%34;ctx.fillRect(i*18-6,110-h,w,h);}
    ctx.fillStyle='#f0d070';for(let i=0;i<40;i++){const wx=(i*61)%240,wy=82+(i*13)%24;if((i+Math.floor(t))%7)ctx.fillRect(wx,wy,1,2);}
    ctx.fillStyle='#14284a';ctx.fillRect(0,110,SW,50);
  }
  for(let y=112;y<160;y+=4){const o=Math.sin(t*1.5+y)*6;ctx.fillStyle='#1e3a64';ctx.fillRect(20+o+(y*7)%60,y,30,1);ctx.fillRect(140-o+(y*5)%50,y,24,1);}
  if(mode==='title'){if(!art){const by=Math.round(Math.sin(t*1.6)*2);ctx.globalAlpha=.55;ctx.drawImage(titleArt,88,62+by,64,64);ctx.globalAlpha=1;}}
  else{ctx.fillStyle='rgba(0,0,0,.35)';ctx.fillRect(0,0,SW,SH);ctx.fillStyle='#2a6a48';ctx.beginPath();ctx.ellipse(120,104,34,7,0,0,Math.PI*2);ctx.fill();if(!arteRetrato(LOOKS.kiko,120,104,now))ctx.drawImage(spriteFor(LOOKS.kiko,'down',0),96,44,48,60);}
}
function updateHUD(){
  const h=$('hud');if(mode!=='world'||!S){h.hidden=true;return;}h.hidden=false;
  const hh=String(Math.floor(S.min/60)).padStart(2,'0'),mm=String(Math.floor(S.min%60/10)*10).padStart(2,'0'),heat=Math.round(S.heat);
  h.innerHTML=`DÍA ${S.day} · ${hh}:${mm}<br>${eur(S.money)} · ${Math.floor(totalBuds())} g<div class="heat">CALOR<span class="bar"><i class="${heat>=70?'hot':''}" style="width:${heat}%"></i></span></div>`;
}


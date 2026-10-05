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
    if(!arteTile(k,tx,ty,sx,sy,now))ctx.drawImage(a[a.length>1?wf:0],sx,sy);
    const o=m.o[ty][tx];if(o&&!arteObj(o,tx,ty,cam,now,list))ctx.drawImage(TILES[o][0],sx,sy);
  }
  arteEdificios(m,cam);
  if(S.map==='home'){
    const x0=7*16-cam.x,y0=3*16-cam.y;
    if(!arteCarpa(cam)){ctx.fillStyle='rgba(255,246,214,.13)';ctx.fillRect(x0,y0,64,96);ctx.strokeStyle='#2c3038';ctx.lineWidth=1;ctx.strokeRect(x0+.5,y0+.5,63,95);
    ctx.fillStyle='#22262e';ctx.fillRect(x0+4,y0-3,56,4);ctx.fillStyle='#fff4c0';ctx.fillRect(x0+6,y0,52,1);}
    POTS.forEach(([px,py],i)=>{if(i>=S.potsOwned){ctx.strokeStyle='rgba(60,70,90,.5)';ctx.setLineDash([2,2]);ctx.strokeRect(px*16-cam.x+3.5,py*16-cam.y+9.5,9,6);ctx.setLineDash([]);}});
    if(!S.flags.letter){const lx=3*16-cam.x,ly=6*16-cam.y;ctx.fillStyle='#fafaf2';ctx.fillRect(lx+5,ly+5,7,5);ctx.fillStyle='#c04040';ctx.fillRect(lx+8,ly+7,2,1);}
  }
  const fr=(e,dur)=>e.moving&&e.t/dur<.5?1+((e.x+e.y)&1):0;
  if(ARTE.ok)for(const e of ents)ambiente(e,now,cam);
  for(const e of ents)list.push([e.py,()=>{if(!dibujarPJ(e,e.look,now,cam,false,320))ctx.drawImage(spriteFor(e.look,e.dir,fr(e,320)),Math.round(e.px-cam.x),Math.round(e.py-cam.y-4));}]);
  list.push([P.py,()=>{if(!dibujarPJ(P,LOOKS.player,now,cam,true,P.dur))ctx.drawImage(spriteFor(LOOKS.player,P.dir,P.moving&&P.t/P.dur<.5?1+P.parity:0),Math.round(P.px-cam.x),Math.round(P.py-cam.y-4));}]);
  if(S.map==='home')POTS.forEach(([px,py],i)=>{if(i<S.potsOwned)list.push([py*16,()=>{const p=S.pots[i],x=px*16-cam.x,y=py*16-cam.y;if(!artePlanta(p,x,y,now))ctx.drawImage(p?plantSprite(p):emptyPot,x,y-10);}]);});
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
let emptyPot,titleArt,battleBg={};
function makeArt(){
  {const [c,x]=mkCanvas(16,26);const t=painter(x,rngSeed(1));t.F(3,20,10,6,'#2c2c30');t.F(3,20,10,1,'#4a4a52');t.F(4,21,8,1,'#5a3a20');t.F(3,25,10,1,'#18181c');emptyPot=c;}
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
  const t=now/1000;
  const sky=['#0e1638','#162250','#20306a','#2c3e7c','#3a4a86'];
  for(let y=0;y<110;y++){ctx.fillStyle=sky[Math.min(4,Math.floor(y/22))];ctx.fillRect(0,y,SW,1);}
  for(let i=0;i<40;i++){const sx=(i*53)%240,sy=(i*29)%90;if(((i*7+Math.floor(t*2))%9)>1){ctx.fillStyle=i%5?'#c8d0ff':'#ffffff';ctx.fillRect(sx,sy,1,1);}}
  ctx.fillStyle='#0a0f1e';for(let i=0;i<14;i++){const w=14+(i*37)%20,h=18+(i*53)%34;ctx.fillRect(i*18-6,110-h,w,h);}
  ctx.fillStyle='#f0d070';for(let i=0;i<40;i++){const wx=(i*61)%240,wy=82+(i*13)%24;if((i+Math.floor(t))%7)ctx.fillRect(wx,wy,1,2);}
  ctx.fillStyle='#14284a';ctx.fillRect(0,110,SW,50);
  for(let y=112;y<160;y+=4){const o=Math.sin(t*1.5+y)*6;ctx.fillStyle='#1e3a64';ctx.fillRect(20+o+(y*7)%60,y,30,1);ctx.fillRect(140-o+(y*5)%50,y,24,1);}
  if(mode==='title'){const by=Math.round(Math.sin(t*1.6)*2);ctx.globalAlpha=.55;ctx.drawImage(titleArt,88,62+by,64,64);ctx.globalAlpha=1;}
  else{ctx.fillStyle='rgba(0,0,0,.35)';ctx.fillRect(0,0,SW,SH);ctx.fillStyle='#2a6a48';ctx.beginPath();ctx.ellipse(120,104,34,7,0,0,Math.PI*2);ctx.fill();ctx.drawImage(spriteFor(LOOKS.kiko,'down',0),96,44,48,60);}
}
function updateHUD(){
  const h=$('hud');if(mode!=='world'||!S){h.hidden=true;return;}h.hidden=false;
  const hh=String(Math.floor(S.min/60)).padStart(2,'0'),mm=String(Math.floor(S.min%60/10)*10).padStart(2,'0'),heat=Math.round(S.heat);
  h.innerHTML=`DÍA ${S.day} · ${hh}:${mm}<br>${eur(S.money)} · ${Math.floor(totalBuds())} g<div class="heat">CALOR<span class="bar"><i class="${heat>=70?'hot':''}" style="width:${heat}%"></i></span></div>`;
}


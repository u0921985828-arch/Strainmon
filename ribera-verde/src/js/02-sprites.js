/* ---------- characters ---------- */
const OUT='#26262e';
const sprCache={};
function spriteFor(look,dir,frame){
  const key=look.id+'|'+dir+'|'+frame;
  if(sprCache[key])return sprCache[key];
  const [c,x]=mkCanvas(16,20);
  if(dir==='right'){const src=spriteFor(look,'left',frame);x.save();x.translate(16,0);x.scale(-1,1);x.drawImage(src,0,0);x.restore();sprCache[key]=c;return c;}
  const parts=[];const R=(a,b,w,h,col)=>parts.push([a,b,w,h,col]);
  const L=look,sk=L.skin,hair=L.hair,sh=L.shirt,sh2=L.shirt2||shade(L.shirt,-30),pa=L.pants,shoe=L.shoes||'#2a2a30';
  const l1=frame===1?3:4,l2=frame===2?3:4;
  if(dir==='down'||dir==='up'){
    R(5,14,3,l1,pa);R(8,14,3,l2,pa);R(5,13+l1,3,1,shoe);R(8,13+l2,3,1,shoe);
    R(4,9,8,6,sh);R(3,10,1,4-(frame===1?1:0),sh);R(12,10,1,4-(frame===2?1:0),sh);
    R(3,14-(frame===1?1:0),1,1,sk);R(12,14-(frame===2?1:0),1,1,sk);
    if(L.style==='hood')R(2,1,12,9,L.hat||sh);
    R(4,1,8,8,sk);R(3,2,10,6,sk);
  }else{
    R(6,14,3,l1,pa);R(8,14,3,l2,shade(pa,-18));R(5,13+l1,4,1,shoe);R(8,13+l2,3,1,shoe);
    R(5,9,6,6,sh);R(7,10,2,4,sh2);R(7,14,2,1,sk);
    if(L.style==='hood')R(3,1,11,9,L.hat||sh);
    R(4,1,8,8,sk);R(3,2,10,6,sk);
  }
  const fills=[];const H=(a,b,w,h,col)=>fills.push([a,b,w,h,col,1]);const D=(a,b,w,h,col)=>fills.push([a,b,w,h,col,0]);
  if(dir==='down'){
    if(L.style==='short'||L.style==='long'||L.style==='bun'||L.style==='curly'){H(3,1,10,3,hair);H(4,0,8,1,hair);H(3,4,1,2,hair);H(12,4,1,2,hair);
      if(L.style==='long'){H(3,4,1,6,hair);H(12,4,1,6,hair);H(2,5,1,4,hair);H(13,5,1,4,hair);}
      if(L.style==='bun'){H(6,-1,4,2,hair);}
      if(L.style==='curly'){H(2,2,1,4,hair);H(13,2,1,4,hair);}}
    if(L.style==='cap'){H(3,0,10,3,L.hat);H(3,3,10,1,L.hat2||shade(L.hat,-35));H(3,4,1,2,hair);H(12,4,1,2,hair);}
    if(L.style==='bald'){D(3,4,1,2,hair);D(12,4,1,2,hair);}
    if(L.style==='hood'){D(3,1,10,2,L.hat);}
    D(5,5,1,2,OUT);D(10,5,1,2,OUT);
    if(L.beard)D(4,7,8,2,L.beard===1?hair:L.beard);
    if(L.glasses){D(4,5,3,1,'#2a2a30');D(9,5,3,1,'#2a2a30');}
    if(L.stache)D(6,7,4,1,L.stache);
    D(7,9,2,5,sh2);
  }else if(dir==='up'){
    if(L.style==='cap'){H(3,0,10,4,L.hat);H(3,4,10,4,hair);}
    else if(L.style==='hood'){D(3,1,10,8,L.hat);}
    else if(L.style==='bald'){D(3,5,10,3,hair);}
    else{H(3,0,10,8,hair);if(L.style==='long'){H(2,4,12,6,hair);}if(L.style==='bun')H(6,-1,4,2,hair);}
  }else{
    if(L.style==='cap'){H(3,0,10,3,L.hat);H(1,3,7,1,L.hat2||shade(L.hat,-35));H(8,3,5,4,hair);}
    else if(L.style==='hood'){D(7,1,7,8,L.hat);D(3,1,5,2,L.hat);}
    else if(L.style==='bald'){D(9,4,4,3,hair);}
    else{H(3,0,10,3,hair);H(8,3,5,4,hair);if(L.style==='long')H(8,3,5,7,hair);if(L.style==='bun')H(9,-1,4,2,hair);}
    D(4,5,1,2,OUT);
    if(L.beard)D(3,7,6,2,L.beard===1?hair:L.beard);
    if(L.glasses)D(3,5,3,1,'#2a2a30');
    if(L.stache)D(3,7,3,1,L.stache);
  }
  x.fillStyle='rgba(0,0,0,.22)';x.fillRect(4,18,8,2);x.fillRect(3,19,10,1);
  x.fillStyle=OUT;
  for(const [a,b,w,h] of parts)x.fillRect(a-1,b,w+2,h+2);
  for(const [a,b,w,h,,o] of fills)if(o)x.fillRect(a-1,b,w+2,h+2);
  for(const [a,b,w,h,col] of parts){x.fillStyle=col;x.fillRect(a,b+1,w,h);}
  for(const [a,b,w,h,col] of fills){x.fillStyle=col;x.fillRect(a,b+1,w,h);}
  sprCache[key]=c;return c;
}
/* ---------- plantas (se pintan en la vista de carpa: 09b-carpa) ---------- */
const plantCache={};
const plantStage=p=>p.prog>=1?4:p.prog<.12?0:p.prog<.35?1:p.prog<.65?2:3;
let bagSprite;
function makeMisc(){
  const [c,x]=mkCanvas(16,16);const t=painter(x,rngSeed(7));
  t.F(4,5,8,10,'#5a3a20');t.F(5,6,6,8,'#c8a068');t.F(4,4,8,2,'#9a7040');t.F(6,3,4,1,'#5a3a20');drawLeafPx(t,8,10,1.8,'#3a8a3a');t.F(4,15,8,1,'rgba(0,0,0,.25)');
  bagSprite=c;
}


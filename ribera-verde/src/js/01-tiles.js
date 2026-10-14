/* ---------- painter helpers ---------- */
function painter(x,R){
  const t={x,R};
  t.F=(a,b,w,h,c)=>{x.fillStyle=c;x.fillRect(a,b,w,h);};
  t.P=(a,b,c)=>{x.fillStyle=c;x.fillRect(a,b,1,1);};
  t.blob=(cx,cy,rx,ry,fill,out,hi,dark)=>{
    const ins=(px,py)=>{const dx=(px+.5-cx)/rx,dy=(py+.5-cy)/ry;return dx*dx+dy*dy<=1;};
    for(let py=Math.floor(cy-ry-1);py<=cy+ry+1;py++)for(let px=Math.floor(cx-rx-1);px<=cx+rx+1;px++){
      if(!ins(px,py))continue;
      const edge=!ins(px-1,py)||!ins(px+1,py)||!ins(px,py-1)||!ins(px,py+1);
      let col=edge?out:fill;
      if(!edge){const dx=(px+.5-cx)/rx,dy=(py+.5-cy)/ry;
        if(hi&&dx+dy<-.55&&R()<.75)col=hi;else if(dark&&dx+dy>.5&&R()<.55)col=dark;}
      t.P(px,py,col);
    }
  };
  t.noise=(n,cols,x0=0,y0=0,w=16,h=16)=>{for(let i=0;i<n;i++)t.P(x0+Math.floor(R()*w),y0+Math.floor(R()*h),cols[Math.floor(R()*cols.length)]);};
  t.box=(a,b,w,h,fill,out)=>{t.F(a,b,w,h,out);t.F(a+1,b+1,w-2,h-2,fill);};
  return t;
}
const TILES={};
function T(name,fn,frames=1){const arr=[];for(let f=0;f<frames;f++){const [c,x]=mkCanvas(16,16);const t=painter(x,rngSeed(hashStr(name)+f*7919));t.f=f;fn(t);arr.push(c);}TILES[name]=arr;}

const C={g1:'#84cc6c',g2:'#62aa56',g3:'#b0e48c',g4:'#3f8a46',
  dirt1:'#dcc08a',dirt2:'#c4a46c',dirt3:'#ecd6a4',
  walk1:'#dcd6c6',walk2:'#bcb4a2',walk3:'#eeeadc',
  road1:'#6c7482',road2:'#5e6674',road3:'#7e8694',
  w1:'#4a92e0',w2:'#76b4f2',w3:'#b4dcfa',w4:'#3474c4',
  wood1:'#c48a52',wood2:'#a46e40',wood3:'#dcac6c',wood4:'#74502e',out:'#2a302c'};

function grass(t,base=C.g1){t.F(0,0,16,16,base);
  for(let i=0;i<5;i++){const a=Math.floor(t.R()*13)+1,b=Math.floor(t.R()*13)+2;t.P(a,b,C.g2);t.P(a+2,b,C.g2);t.P(a+1,b+1,C.g2);}
  t.noise(5,[C.g3]);}
function buildTiles(){
  T('grass',t=>grass(t));
  T('flowers',t=>{grass(t);const cols=[['#f05858','#ffd0d0'],['#f8d838','#fff4b0'],['#f8f8f8','#f8d838']];
    [[3,3],[11,5],[6,11],[13,12]].forEach(([a,b],i)=>{const [p,c]=cols[(i+Math.floor(t.R()*3))%3];t.P(a,b-1,p);t.P(a-1,b,p);t.P(a+1,b,p);t.P(a,b+1,p);t.P(a,b,c);});});
  T('tallgrass',t=>{t.F(0,0,16,16,C.g2);for(let x=0;x<16;x+=3){const h=4+Math.floor(t.R()*4),o=Math.floor(t.R()*2);for(let row=0;row<2;row++){const y0=row*8+8-h+o;t.F(x,y0,1,h,C.g4);t.F(x+1,y0+1,1,h-1,C.g1);t.P(x,y0,C.g3);}}});
  T('dirt',t=>{t.F(0,0,16,16,C.dirt1);t.noise(14,[C.dirt2,C.dirt3]);});
  T('walk',t=>{t.F(0,0,16,16,C.walk1);t.F(0,7,16,1,C.walk2);t.F(0,15,16,1,C.walk2);t.F(7,0,1,7,C.walk2);t.F(15,8,1,7,C.walk2);t.noise(6,[C.walk3,C.walk2]);});
  T('roadT',t=>{t.F(0,0,16,16,C.road1);t.noise(18,[C.road2,C.road3]);t.F(0,0,16,2,'#4a515c');t.F(1,14,6,2,'#f0d860');t.F(9,14,6,2,'#f0d860');});
  T('roadB',t=>{t.F(0,0,16,16,C.road1);t.noise(18,[C.road2,C.road3]);t.F(0,14,16,2,'#4a515c');});
  T('plaza',t=>{t.F(0,0,16,16,'#e8d6b0');for(let y=0;y<16;y+=8)for(let x=0;x<16;x+=8){t.F(x,y,8,1,'#d0bc94');t.F(x,y,1,8,'#d0bc94');t.P(x+2,y+2,'#f6e8c8');t.P(x+3,y+2,'#f6e8c8');}t.noise(4,['#d6c29c']);});
  T('water',t=>{t.F(0,0,16,16,C.w1);const o=t.f*3;for(let i=0;i<4;i++){const y=(i*4+1+(i%2?o:0))%16,x=(i*5+o)%12;t.F(x,y,4,1,C.w2);t.P(x+1,y-1<0?15:y-1,C.w3);}t.noise(3,[C.w4]);},2);
  T('bridgeT',t=>{t.F(0,0,16,16,C.wood1);for(let x=0;x<16;x+=4)t.F(x,0,1,16,C.wood2);t.F(0,0,16,3,C.wood4);t.F(0,1,16,1,C.wood3);});
  T('bridgeB',t=>{t.F(0,0,16,16,C.wood1);for(let x=0;x<16;x+=4)t.F(x,0,1,16,C.wood2);t.F(0,13,16,3,C.wood4);t.F(0,14,16,1,C.wood3);});
  T('dock',t=>{t.F(0,0,16,16,C.wood3);for(let y=3;y<16;y+=4)t.F(0,y,16,1,C.wood2);t.P(2,1,C.wood4);t.P(13,5,C.wood4);t.P(6,9,C.wood4);t.P(10,13,C.wood4);t.noise(5,[C.wood1]);});
  // firmes (orgánico): hormigón de los pueblos, pista de tierra y asfalto roto (sin arte, como estos; con arte, mundo.py y sus variantes)
  T('hormigon',t=>{t.F(0,0,16,16,'#c4beb0');t.noise(10,['#d8d3c6','#948e80']);t.F(7,0,1,16,'#a49e90');});
  T('pista',t=>{t.F(0,0,16,16,C.dirt1);t.noise(12,['#c0ae8a','#7a5a3a','#a0744c']);});
  T('rotoT',t=>{t.F(0,0,16,16,C.road1);t.noise(18,[C.road2,C.road3]);t.F(0,0,16,2,'#4a515c');t.F(1,14,4,2,'#b8a058');t.F(4,6,6,3,'#3c3c44');});
  T('rotoB',t=>{t.F(0,0,16,16,C.road1);t.noise(18,[C.road2,C.road3]);t.F(0,14,16,2,'#4a515c');t.F(8,3,5,3,'#40464f');});
  T('void',t=>t.F(0,0,16,16,'#000'));
  // buildings
  // 1.10: las fachadas por bioma de mundo.py (comisaría, nave del almacén, caseríos, casas marineras, bloque de ladrillo y fábrica)
  const B={home:['#d65a4a','#f0dcae','doorW'],shop:['#46a262','#d8ecc4','doorG'],bar:['#4a72c2','#d4dbe8','doorD'],gray:['#8a92a2','#e4cec4','doorW'],
    comisaria:['#4e5664','#cfc8b8','doorD'],nave:['#5f7e80','#8c98a2','doorD'],caserio:['#b04a32','#f2eee2','doorD'],caserio2:['#b04a32','#ece0c4','doorD'],
    marinera:['#b04a32','#3f8a5a','doorD'],marinera2:['#b04a32','#3c6eb4','doorD'],marinera3:['#b04a32','#b8403a','doorD'],marinera4:['#b04a32','#e0b84a','doorD'],
    ladrillo:['#9a9690','#a04a34','doorD'],fabrica:['#4e5258','#a04a34','doorD'],
    caserio3:['#b04a32','#ece6d6','none'],borda:['#b04a32','#a69c8a','none'],marinera5:['#b04a32','#ece6d8','none'],marinera6:['#b04a32','#d8846a','none'],   // orgánico: sin puerta
    casco:['#b04a32','#c89a52','doorD'],casco2:['#b04a32','#7a96a4','none'],casco3:['#b04a32','#c07a5e','doorD'],growcity:['#b04a32','#e8dcc0','doorG'],
    bloque:['#9a9690','#e6dcc8','doorG'],bloque2:['#9a9690','#b8bcc0','doorG']};   // Ibarbide (1.14); con puerta, el club de la Kalea, el del Ensanche y GAUA (1.30) y la asociación (1.32, casco3)
  for(const [id,[roof,wall,door]] of Object.entries(B)){
    const shingles=(t)=>{t.F(0,0,16,16,roof);for(let y=3;y<16;y+=4){t.F(0,y,16,1,shade(roof,-38));for(let x=((y>>2)%2)*4;x<16;x+=8)t.F(x,y-3,1,3,shade(roof,-22));}t.noise(4,[shade(roof,22)]);};
    T('roofT_'+id,t=>{shingles(t);t.F(0,0,16,2,shade(roof,30));t.F(0,2,16,1,shade(roof,-45));});
    T('roofB_'+id,t=>{shingles(t);t.F(0,12,16,2,shade(roof,-55));t.F(0,14,16,2,'#3c3434');});
    const wallT=(t)=>{t.F(0,0,16,16,wall);for(let y=3;y<16;y+=4)t.F(0,y,16,1,shade(wall,-14));t.F(0,0,16,2,shade(wall,-40));};
    T('wall_'+id,wallT);
    T('win_'+id,t=>{wallT(t);t.box(2,3,12,10,'#f8f8f8','#5a5a66');t.F(4,5,8,6,'#7cbcec');t.F(7,5,2,6,'#f8f8f8');t.P(5,6,'#d8f0ff');t.P(6,6,'#d8f0ff');t.P(5,7,'#d8f0ff');t.F(2,13,12,1,shade(wall,-50));});
    if(door!=='none')T('door_'+id,t=>{wallT(t);const dc=door==='doorG'?'#8cc8e4':door==='doorD'?'#5a3420':'#86502e';t.box(3,3,10,13,dc,'#2e2a2a');
      if(door==='doorG'){t.F(4,4,8,11,'#a8dcf0');t.F(7,4,2,11,'#5a5a66');t.P(5,5,'#ffffff');t.P(5,6,'#ffffff');}
      else{t.F(5,5,6,4,shade(dc,18));t.F(5,10,6,4,shade(dc,18));t.P(11,10,'#f0d050');}});
  }
  // interiors
  const IW={home:'#ead8b4',shop:'#cfe6bc',bar:'#a8805a'};
  for(const [id,col] of Object.entries(IW)){
    const paper=t=>{t.F(0,0,16,16,col);for(let x=1;x<16;x+=4)t.F(x,0,1,16,shade(col,-10));};
    T('iwT_'+id,t=>{paper(t);t.F(0,0,16,4,shade(col,-60));t.F(0,4,16,1,shade(col,-30));});
    T('iwB_'+id,t=>{paper(t);t.F(0,11,16,5,shade(col,-42));t.F(0,11,16,1,shade(col,-62));t.F(0,12,16,1,shade(col,-25));});
  }
  T('floor',t=>{t.F(0,0,16,16,'#d8a868');for(let y=3;y<16;y+=4)t.F(0,y,16,1,'#b48446');for(let r=0;r<4;r++){const x=Math.floor(t.R()*14)+1;t.F(x,r*4,1,3,'#b48446');}t.noise(4,['#e6bc80']);});
  T('floorB',t=>{t.F(0,0,16,16,'#8e623e');for(let y=3;y<16;y+=4)t.F(0,y,16,1,'#6e4a2c');for(let r=0;r<4;r++){const x=Math.floor(t.R()*14)+1;t.F(x,r*4,1,3,'#6e4a2c');}t.noise(4,['#a0744c']);});
  T('floorS',t=>{for(let y=0;y<2;y++)for(let x=0;x<2;x++)t.F(x*8,y*8,8,8,(x+y)%2?'#e8eadc':'#cfdcc4');});
  T('mat',t=>{t.F(0,0,16,16,'#d8a868');t.box(1,3,14,11,'#c44a4a','#7a2626');for(let x=3;x<13;x+=3)t.F(x,5,1,7,'#a83636');});
  // objects (transparent)
  T('tree2',t=>{t.F(6,11,3,5,C.wood4);t.blob(8,6,7.2,6.2,'#3a8e42','#1f4f2a','#6cc262','#2c6e36');});   // orgánico: el segundo árbol y el manzano
  T('manzano',t=>{t.F(7,10,2,6,C.wood4);t.blob(8,6.5,7,5.4,'#4a9a44','#1f4f2a','#7acc66','#2c6e36');t.P(5,6,'#d8403a');t.P(10,5,'#d8403a');t.P(8,9,'#d8403a');});
  T('tree',t=>{t.F(6,11,4,5,C.wood4);t.F(7,11,1,5,'#8c6438');t.blob(8,6.5,7.6,6.6,'#3e9446','#1f4f2a','#72c868','#2c6e36');t.noise(6,['#2c6e36'],3,2,10,8);});
  T('bush',t=>{t.blob(8,9.5,7,5.6,'#4ea04e','#22522c','#86d474','#357a3c');});
  // linde de los mapas (1.10): monte espeso y seto; con arte, los de prop-monte y prop-seto (mundo.py)
  T('monte',t=>{t.F(7,12,2,4,C.wood4);t.blob(8,7,7.8,6.4,'#2f7a3a','#183f24','#5ca850','#245c30');t.noise(6,['#245c30'],2,2,12,9);});
  T('monte2',t=>{t.F(6,12,2,4,C.wood4);t.blob(8,7.5,7.8,6.2,'#327e3c','#183f24','#62ae54','#245c30');t.noise(5,['#245c30'],2,3,12,8);});
  T('parada',t=>{t.F(7,5,2,11,'#7c848e');t.box(2,0,12,7,'#2c5aa0','#26262e');t.F(4,2,8,3,'#f4f4ee');t.F(3,5,10,1,'#f0d050');t.F(5,14,6,2,'#4c545e');});   // el poste del autobús (1.10)
  T('seto',t=>{t.F(0,3,16,13,'#357a3c');t.F(0,2,16,1,'#22522c');t.F(0,4,16,2,'#4ea04e');t.F(0,15,16,1,'#22522c');t.noise(8,['#86d474','#22522c'],0,5,16,9);});
  T('fence',t=>{const p=(x)=>{t.F(x,3,3,12,'#5a3a20');t.F(x+1,4,1,10,'#e8c890');};t.F(0,6,16,3,'#5a3a20');t.F(0,7,16,1,'#e8c890');t.F(0,11,16,3,'#5a3a20');t.F(0,12,16,1,'#e8c890');p(1);p(12);});
  T('sign',t=>{t.F(7,9,2,7,C.wood4);t.box(1,2,14,9,C.wood3,C.wood4);t.F(3,4,10,1,C.wood2);t.F(3,6,8,1,C.wood2);t.F(3,8,6,1,C.wood2);});
  T('lamp',t=>{t.F(7,3,2,12,'#3c444e');t.F(5,14,6,2,'#2c333c');t.F(4,0,8,3,'#4c5560');t.F(5,2,6,2,'#fff2a0');t.P(8,4,'#6a7480');});
  T('bench',t=>{t.F(1,3,14,3,C.wood1);t.F(1,3,14,1,C.wood3);t.F(1,8,14,3,C.wood1);t.F(1,8,14,1,C.wood3);t.F(1,6,14,2,'#3c444e');t.F(2,11,2,4,'#3c444e');t.F(12,11,2,4,'#3c444e');});
  T('fountain',t=>{t.blob(8,9,7.5,6,'#c8ccd6','#5a6070');t.blob(8,9,5.5,4,'#70b4f0','#4a88cc','#b4dcfa');t.F(7,1,2,8,'#b4dcfa');t.P(6,2,'#ffffff');t.P(9,2,'#ffffff');t.P(8,0,'#ffffff');});
  // los muebles del salón (1.10), de 2 casillas: la mitad de la izquierda (k) y la de la derecha (k2), sin atlas
  T('sofa',t=>{t.F(2,6,14,9,'#3e5272');t.F(2,6,14,2,'#566e94');t.F(2,6,1,9,'#566e94');t.F(2,4,3,2,'#566e94');t.F(3,15,1,1,'#3a2a1c');});
  T('sofa2',t=>{t.F(0,6,13,9,'#3e5272');t.F(0,6,13,2,'#566e94');t.F(12,6,1,9,'#2c3a52');t.F(10,4,3,2,'#566e94');t.F(0,6,1,9,'#2c3a52');t.F(11,15,1,1,'#3a2a1c');});
  T('tv',t=>{t.F(5,9,11,7,'#5e4028');t.F(5,9,11,1,'#9e744a');t.F(7,0,9,8,'#18181e');t.F(8,1,8,6,'#232834');t.F(13,8,3,1,'#2a2a34');});
  T('tv2',t=>{t.F(0,9,11,7,'#5e4028');t.F(0,9,11,1,'#9e744a');t.F(0,0,9,8,'#18181e');t.F(0,1,8,6,'#232834');t.F(0,8,3,1,'#2a2a34');t.P(7,6,'#e04040');});
  T('gpc',t=>{t.F(5,7,11,4,'#383a42');t.F(5,10,11,1,'#e040e0');t.F(5,11,2,5,'#24262c');t.F(10,0,6,6,'#141518');t.F(11,1,5,4,'#2a4a9a');});
  T('gpc2',t=>{t.F(0,7,11,4,'#383a42');t.F(0,10,11,1,'#40c0f0');t.F(9,11,2,5,'#24262c');t.F(0,0,2,6,'#141518');t.F(0,1,1,4,'#2a4a9a');t.F(2,0,4,7,'#24262c');t.P(3,2,'#e040e0');t.P(3,4,'#40c0f0');});
  T('silla',t=>{t.F(4,1,8,2,'#c48a52');t.F(4,1,8,1,'#e6bc80');t.F(4,3,1,8,'#c48a52');t.F(11,3,1,8,'#74502e');t.F(7,3,2,4,'#a46e40');t.F(5,6,6,1,'#d8a868');});
  T('sillaG',t=>{t.F(12,0,4,12,'#24262c');t.F(13,2,1,8,'#e040e0');t.F(15,12,1,3,'#55585f');t.F(10,14,6,1,'#24262c');});
  T('sillaG2',t=>{t.F(0,0,4,12,'#24262c');t.F(2,2,1,8,'#e040e0');t.F(0,12,1,3,'#55585f');t.F(0,14,6,1,'#24262c');});
  // el sillón con la lámpara de pie y el cuadro (1.16)
  T('sillon',t=>{t.F(4,6,12,9,'#b08a30');t.F(4,6,12,2,'#d0aa48');t.F(4,4,3,3,'#d0aa48');t.F(5,15,1,1,'#3a2a1c');t.F(14,15,1,1,'#3a2a1c');});
  T('sillon2',t=>{t.F(4,0,1,15,'#3a3a44');t.F(1,0,7,4,'#f0d890');t.F(2,15,5,1,'#3a3a44');});
  T('cuadro',t=>{t.box(3,1,10,12,'#a46e40','#74502e');t.F(4,2,8,5,'#76b4f2');t.F(4,7,8,5,'#3f8a46');});
  // reformas del piso, el póster y la alfombra (1.27; con el atlas, los de tools/sprites/a-mano/casa.py y salon.py): sin él, el suelo
  // y la pared lisos con sus juntas, y la alfombra, un rectángulo de su color sobre el suelo que haya
  const SUELO_V=['#d8a868','#8a5e3c','#b0aca4','#e4e0d6'];
  SUELO_V.slice(1).forEach((c,i)=>T('floor-'+(i+1),t=>{t.F(0,0,16,16,c);for(let y=3;y<16;y+=4)t.F(0,y,16,1,shade(c,-30));}));
  ['#b2c4a6','#aabac6','#a8503a'].forEach((c,i)=>{T('iwT_home-'+(i+1),t=>{t.F(0,0,16,16,c);t.F(0,0,16,4,shade(c,-60));t.F(0,4,16,1,shade(c,-30));});
    T('iwB_home-'+(i+1),t=>{t.F(0,0,16,16,c);t.F(0,11,16,5,'#dfdfe1');t.F(0,12,16,1,'#fffffe');});});
  ['#e4dcc6','#8c2c30','#84878c'].forEach((c,v)=>SUELO_V.forEach((s,f)=>[[2,5,14,11],[0,5,15,11],[2,0,14,11],[0,0,15,11]].forEach(([x,y,w,h],q)=>
    T('alf'+v+'abcd'[q]+(f?'-'+f:''),t=>{t.F(0,0,16,16,s);t.F(x,y,w,h,c);}))));
  T('cartel',t=>{t.box(3,1,11,14,'#f0e6cc','#8a8e96');t.F(4,9,9,5,'#3a5e9a');});
  // los locales (1.30; con el atlas, los de tools/sprites/a-mano/locales.py): el club, la nave y GAUA, sin él, con lo justo. Los de 2
  // casillas, la mitad de la izquierda (k) y la de la derecha (k2, LOCAL2 en 11j-locales)
  const suelo=(k,c,c2)=>T(k,t=>{t.F(0,0,16,16,c);for(let y=3;y<16;y+=4)t.F(0,y,16,1,c2);});
  suelo('floorC','#a8743e','#7e5226');suelo('floorN','#9a9a96','#82827e');suelo('floorD','#1a1622','#26202e');
  [['club','#3e6a48'],['nave','#8c98a2'],['disco','#2a2236']].forEach(([k,c])=>{T('iwT_'+k,t=>{t.F(0,0,16,16,c);t.F(0,0,16,4,shade(c,-60));t.F(0,4,16,1,shade(c,-30));});
    T('iwB_'+k,t=>{t.F(0,0,16,16,c);t.F(0,11,16,5,shade(c,-42));t.F(0,11,16,1,shade(c,-62));});});
  T('baile',t=>{['#e040b0','#40d0e8','#f0d040','#9050e0'].forEach((c,i)=>t.F((i%2)*8,(i>>1)*8,8,8,c));});
  T('vitrina',t=>{t.box(0,4,16,12,'#c8d8dc','#4a3a2a');t.F(1,5,14,5,'#dff0f0');t.F(3,7,3,3,'#6fb04a');t.F(9,7,3,3,'#9bd35a');});
  T('tarros',t=>{t.F(0,12,16,2,C.wood4);for(let i=0;i<3;i++){t.box(1+i*5,5,4,7,'#dfeef2','#8a9aa0');t.F(2+i*5,8,2,3,'#6fb04a');}});
  T('pizarra',t=>{t.box(2,2,12,10,'#2a3a2c','#7a5a3a');t.F(4,4,7,1,'#e0e0d0');t.F(4,6,5,1,'#e0e0d0');t.F(4,8,6,1,'#e0e0d0');});
  T('cartelC',t=>{t.box(4,1,8,11,'#f4f0e4','#8a8e96');t.F(5,3,6,1,'#3a8a4a');t.F(5,5,5,1,'#8a8e96');t.F(5,7,4,1,'#8a8e96');});
  T('tacos',t=>{t.F(2,2,12,2,C.wood4);t.F(2,11,12,2,C.wood4);for(let x=3;x<14;x+=3)t.F(x,1,1,12,'#d8b080');});
  T('mesita',t=>{t.F(1,5,14,6,'#7a4a2a');t.F(1,5,14,1,'#a46e40');t.F(2,11,2,4,'#4a2c18');t.F(12,11,2,4,'#4a2c18');t.F(6,3,3,2,'#e8e8f0');});
  T('barraD',t=>{t.F(0,4,16,12,'#1e1a26');t.F(0,4,16,3,'#3a3446');t.F(0,7,16,1,'#ff4fc8');t.F(0,15,16,1,'#0e0c12');});
  T('neon',t=>{for(let a=0;a<12;a++){const r=a/11*Math.PI*1.2+Math.PI*.4;t.P(8+Math.round(Math.cos(r)*4),7+Math.round(Math.sin(r)*4),'#ff4fc8');}t.P(11,4,'#40e0f0');});
  T('mesaV',t=>{t.F(2,5,12,5,'#2a2632');t.F(2,5,12,1,'#4a4456');t.F(7,10,2,5,'#1a1820');t.F(6,2,2,4,'#3a8a4a');t.F(9,3,2,2,'#e8e8f0');});
  T('cordon',t=>{t.F(2,4,2,11,'#c0c4cc');t.F(1,14,4,2,'#8a8e96');t.F(4,6,12,2,'#b0203a');});
  T('cordonF',t=>{t.F(2,4,2,11,'#c0c4cc');t.F(1,14,4,2,'#8a8e96');});
  T('estanteN',t=>{t.box(1,0,14,16,'#7a8494','#3a4048');t.F(2,5,12,1,'#3a4048');t.F(2,10,12,1,'#3a4048');t.F(3,1,4,4,'#3a8a4a');t.F(9,6,4,4,'#c8b080');t.F(3,11,5,4,'#4a6aa8');});
  T('secadero',t=>{t.F(7,0,2,16,'#3a4048');for(let y=2;y<15;y+=4){t.F(2,y,12,1,'#5a6070');t.F(3,y+1,10,2,'#5a8a4a');}});
  T('altavoz',t=>{t.box(2,0,12,16,'#1a1820','#0a0a0e');t.F(6,3,4,4,'#3a3446');t.F(5,9,6,5,'#3a3446');});
  const doble=(k,a,b)=>{T(k,a);T(k+'2',b);},sofaL=(k,c,c2)=>doble(k,t=>{t.F(2,6,14,9,c);t.F(2,6,14,2,c2);t.F(2,6,1,9,c2);t.F(2,4,3,2,c2);},
    t=>{t.F(0,6,13,9,c);t.F(0,6,13,2,c2);t.F(10,4,3,2,c2);t.F(12,6,1,9,shade(c,-30));});
  sofaL('sofaF','#6e3a22','#9a5634');sofaL('sofaV','#5a2e7a','#8048a8');sofaL('sofaB','#6e3a22','#9a5634');
  doble('billar',t=>{t.F(2,4,14,10,'#5a3418');t.F(4,6,12,6,'#2e8a4a');t.F(3,14,2,2,'#3a2010');t.P(8,8,'#f8f8f0');t.P(11,9,'#e04040');},
    t=>{t.F(0,4,14,10,'#5a3418');t.F(0,6,12,6,'#2e8a4a');t.F(11,14,2,2,'#3a2010');t.P(4,8,'#f0d040');});
  doble('cabina',t=>{t.F(1,4,15,12,'#1e1a26');t.F(1,4,15,2,'#3a3446');t.F(3,8,4,4,'#40e0f0');},t=>{t.F(0,4,15,12,'#1e1a26');t.F(0,4,15,2,'#3a3446');t.F(6,8,4,4,'#ff4fc8');});
  doble('escritorio',t=>{t.F(1,6,15,4,'#8a6a46');t.F(1,6,15,1,'#a8865a');t.F(2,10,2,6,'#5a4028');t.box(5,0,8,6,'#2e2e3a','#1a1a22');},
    t=>{t.F(0,6,15,4,'#8a6a46');t.F(0,6,15,1,'#a8865a');t.F(12,10,2,6,'#5a4028');t.F(3,3,6,3,'#e8e8f0');});
  doble('mesaN',t=>{t.F(1,8,15,6,'#8a8e96');t.F(2,14,2,2,'#5a5e66');for(let x=3;x<16;x+=5)t.blob(x+1,6,2.5,3,'#4ea04e','#22522c');t.F(1,0,15,1,'#e8e8f0');},
    t=>{t.F(0,8,15,6,'#8a8e96');t.F(12,14,2,2,'#5a5e66');for(let x=1;x<14;x+=5)t.blob(x+1,6,2.5,3,'#4ea04e','#22522c');t.F(0,0,15,1,'#e8e8f0');});
  // el equipo de la nave (1.33) y la foto de la tía (1.32, de 2 casillas desde la 1.33)
  T('extrN',t=>{t.F(4,6,8,8,'#3a3c44');t.F(6,0,4,6,'#b8bcc4');});T('extrG',t=>{t.F(3,4,10,10,'#3a3c44');t.F(6,0,4,4,'#b8bcc4');});
  T('filtroN',t=>{t.F(4,3,8,11,'#2a2c32');t.F(4,3,8,2,'#8a8e96');});T('ctrlN',t=>{t.box(3,3,10,10,'#e8e8e0','#5a5e66');t.F(4,4,7,3,'#2a5a3a');});
  T('tanqueN',t=>{t.box(1,0,14,14,'#e4e8e6','#8a8e96');t.F(2,5,12,8,'#8aa86a');t.F(1,14,14,2,'#2a2a30');});
  T('riegoN',t=>{t.box(2,2,12,14,'#8c98a2','#4a525a');t.F(4,4,8,3,'#2a3a5a');});
  doble('fotoMaite',t=>{t.box(10,2,6,11,'#e8dcc0','#74502e');},t=>{t.box(0,2,6,11,'#e8dcc0','#74502e');});
  // 1.34: los suelos y las paredes de cada club (CLUB_PLANO), el bajo de las setas, lo de sus paredes y la carpa de las madres
  [['kalea','#8a8478','#6e685e','#5a4636'],['itsaso','#b08454','#7a5434','#2a4a6a'],['fundicion','#9a9690','#82807a','#8a4a32'],['ensanche','#e4e2dc','#c8c6c0','#d8dcd8']].forEach(([k,c,c2,p])=>{
    suelo('floorC_'+k,c,c2);T('iwT_club_'+k,t=>{t.F(0,0,16,16,p);t.F(0,0,16,4,shade(p,-60));t.F(0,4,16,1,shade(p,-30));});
    T('iwB_club_'+k,t=>{t.F(0,0,16,16,p);t.F(0,11,16,5,shade(p,-42));t.F(0,11,16,1,shade(p,-62));});});
  suelo('floorSe','#6a6a62','#5a5a52');T('iwT_bajo',t=>{t.F(0,0,16,16,'#8a8a7e');t.F(0,0,16,4,'#4a4a42');});T('iwB_bajo',t=>{t.F(0,0,16,16,'#8a8a7e');t.F(0,11,16,5,'#5a5a52');t.P(5,6,'#5a6a4a');});
  T('libreria',t=>{t.box(1,0,14,16,'#6a4a2a','#3a2414');for(let y=3;y<15;y+=4)for(let x=2;x<14;x+=2)t.F(x,y-2,1,3,['#8a3a3a','#3a5a8a','#c8a040','#3a7a4a'][(x+y)%4]);});
  T('copas',t=>{t.F(1,12,14,2,'#74502e');[3,8,12].forEach(x=>{t.F(x,7,3,4,'#e0b040');t.F(x+1,11,1,1,'#c8a040');});});
  T('fotoK',t=>{t.box(3,2,10,10,'#a0a0a0','#3a2a1a');t.F(5,6,6,4,'#6a6a6a');});
  T('ojoBuey',t=>{t.blob(8,7,5,5,'#8ec0d2','#c8a040');});T('timon',t=>{t.blob(8,7,5,5,'#a87646','#5a3a24');t.F(7,6,2,2,'#c8a040');});
  T('red',t=>{for(let i=2;i<14;i+=3){t.F(i,2,1,11,'#8a8270');t.F(2,i,11,1,'#8a8270');}t.F(4,12,2,2,'#e05a3a');t.F(10,12,2,2,'#e05a3a');});
  T('diana',t=>{t.blob(8,7,5,5,'#e8e0c8','#1a1a1a');t.blob(8,7,2,2,'#c03030','#1a1a1a');});T('engranaje',t=>{t.blob(8,7,6,6,'#6a6a6e','#3a3a40');t.blob(8,7,2,2,'#2a2a30','#3a3a40');});
  T('neonH',t=>{for(let y=3;y<13;y++)t.P(8,y,'#58f080');t.P(6,6,'#58f080');t.P(10,6,'#58f080');t.P(5,8,'#58f080');t.P(11,8,'#58f080');});
  T('baldaS',t=>{t.F(1,0,2,16,'#8a8e96');t.F(13,0,2,16,'#8a8e96');t.F(1,5,14,1,'#b8bcc4');t.F(1,13,14,1,'#b8bcc4');});
  T('humidS',t=>{t.box(4,4,8,11,'#e0e4e8','#5a5e66');t.F(6,1,1,4,'#3a3a40');});T('secaS',t=>{t.F(7,0,2,16,'#3a4048');for(let y=3;y<15;y+=4)t.F(2,y,12,1,'#5a6070');});
  T('cajero',t=>{t.box(3,1,10,15,'#c8ccd0','#4a4e56');t.F(5,3,6,4,'#3a6ab8');t.F(5,9,6,2,'#2a2a30');t.F(6,12,4,1,'#2a2a30');});   // 1.35 (11k-banco)
  T('trim',t=>{t.box(1,8,14,3,'#c8935a','#5a3a20');t.F(4,6,3,2,'#6fae4a');t.F(9,7,4,1,'#d0d4d8');});   // 1.36 (11m-almacen): manicura y muebles de extraer
  T('prensaM',t=>{t.box(1,10,14,3,'#c8935a','#5a3a20');t.F(4,1,1,9,'#c03a2a');t.F(11,1,1,9,'#c03a2a');t.F(4,1,8,1,'#c03a2a');t.F(5,6,6,2,'#b8bcc4');});
  T('tamizM',t=>{t.box(1,10,14,3,'#c8935a','#5a3a20');t.F(3,4,10,2,'#8a5a32');t.F(4,7,8,2,'#c8b878');});
  T('mallas',t=>{t.box(3,6,10,10,'#e8ecee','#5a5e66');t.F(4,7,8,2,'#a8d8f0');t.F(2,4,2,6,'#e0c040');t.F(12,4,2,6,'#7ac060');});
  T('lavadora',t=>{t.box(2,1,12,15,'#eef2f4','#5a5e66');t.F(4,3,8,2,'#3a3e46');t.F(5,7,6,6,'#a8d8f0');});
  T('staticM',t=>{t.box(1,10,14,3,'#c8935a','#5a3a20');t.F(3,6,10,3,'#24262c');t.F(3,2,10,2,'#c8e4f0');});
  T('rotuloL',t=>{t.F(4,9,1,7,'#5a3a24');t.F(11,9,1,7,'#5a3a24');t.box(2,2,12,9,'#f4f0e0','#5a3a24');t.F(4,5,8,2,'#c03030');});
  T('tuboS',t=>{t.F(0,5,16,3,'#7a6a5a');t.P(9,9,'#a8c8e0');});T('cuboS',t=>{t.box(4,6,8,9,'#3a6ab8','#1a3a6a');t.F(5,4,6,1,'#8a8e96');});
  doble('carpaM',t=>{t.box(4,0,12,16,'#c8ccd0','#5a5e66');t.F(6,6,10,8,'#2a1a2a');t.blob(10,11,3,3,'#4ea04e','#22522c');},t=>{t.box(0,0,12,16,'#c8ccd0','#5a5e66');t.F(0,6,10,8,'#2a1a2a');t.blob(5,11,3,3,'#4ea04e','#22522c');});
  // 1.34: GROW IBARBIDE (baldosa gris, ladrillo blanco) y lo nuevo de los dos grows
  suelo('floorG','#a8aaa8','#9a9c9a');T('iwT_grow',t=>{t.F(0,0,16,16,'#e8e4dc');t.F(0,0,16,4,'#8a8680');for(let y=6;y<16;y+=3)t.F(0,y,16,1,'#d0ccc4');});
  T('iwB_grow',t=>{t.F(0,0,16,16,'#e8e4dc');for(let y=2;y<11;y+=3)t.F(0,y,16,1,'#d0ccc4');t.F(0,11,16,5,'#5a8a5a');});
  T('sacos',t=>{t.box(1,5,14,10,'#c8b48a','#6a5a3a');t.F(3,8,10,3,'#5a8a4a');});T('macetasP',t=>{t.box(3,3,10,12,'#3a3a3e','#1a1a1e');t.F(3,6,10,1,'#5a5a60');t.F(3,9,10,1,'#5a5a60');});
  T('botesW',t=>{t.F(1,12,14,2,'#74502e');[2,6,10].forEach((x,i)=>t.box(x,5,4,7,['#3a6ab8','#4ea04e','#3a6ab8'][i],'#1a1a2a'));});
  T('neonG',t=>{t.F(2,2,12,10,'#1a2a1a');for(let y=4;y<10;y++)t.P(8,y,'#58f080');t.P(6,6,'#58f080');t.P(10,6,'#58f080');t.F(4,10,8,1,'#58f080');});
  T('semillero',t=>{t.box(1,6,14,9,'#2a2a30','#1a1a1e');t.F(2,3,12,4,'#d0e8f0');for(let x=3;x<14;x+=3)t.P(x,8,'#84cc6c');});
  doble('carpaDemo',t=>{t.box(4,0,12,16,'#c8ccd0','#5a5e66');t.F(6,6,10,8,'#f0e8c0');t.blob(10,11,3,3,'#4ea04e','#22522c');},t=>{t.box(0,0,12,16,'#c8ccd0','#5a5e66');t.F(0,6,10,8,'#f0e8c0');t.blob(5,11,3,3,'#4ea04e','#22522c');});
  // el carro de esquejes (1.11): el carro con sus dos bandejas tapadas y, a la derecha, la mesita con la tabla de corte
  T('carro',t=>{t.F(0,1,16,15,'#26262e');t.F(1,1,14,2,'#a8b0bc');t.F(1,8,14,1,'#a8b0bc');t.F(1,14,14,1,'#a8b0bc');t.F(2,4,12,3,'#8ec0d2');t.F(2,10,12,3,'#8ec0d2');
    for(let x=3;x<14;x+=2){t.P(x,6,'#84cc6c');t.P(x,12,'#84cc6c');}t.F(2,3,12,1,'#fff6d0');t.F(2,9,12,1,'#fff6d0');});
  T('carro2',t=>{t.F(1,5,12,3,'#c48a52');t.F(1,5,12,1,'#dcac6c');t.F(1,8,2,8,'#a46e40');t.F(11,8,2,8,'#a46e40');t.F(3,3,6,2,'#dcac6c');t.F(4,3,3,1,'#dfe5ec');t.F(10,2,2,3,'#d4eef6');});
  T('crate',t=>{t.box(1,3,14,13,C.wood1,C.wood4);t.F(2,4,12,1,C.wood3);for(let i=0;i<11;i++){t.P(2+i,4+i,C.wood4);t.P(13-i,4+i,C.wood4);}});
  T('bedT',t=>{t.box(1,1,14,15,'#9a6a40',C.wood4);t.box(3,3,10,5,'#f8f8f8','#a0a0b0');t.F(2,9,12,7,'#5a86d6');t.F(2,9,12,1,'#86aaee');});
  T('bedB',t=>{t.F(1,0,14,13,C.wood4);t.F(2,0,12,12,'#5a86d6');t.F(2,5,12,1,'#3e64b2');t.F(1,12,14,4,'#9a6a40');t.F(1,15,14,1,C.wood4);});
  T('pc',t=>{t.F(0,9,16,7,C.wood2);t.F(0,9,16,2,C.wood3);t.box(2,0,12,9,'#2e2e3a','#1a1a22');t.F(3,1,10,6,'#58d49c');for(let y=2;y<7;y+=2)t.F(4,y,6+((y*3)%3),1,'#2a8a5a');t.F(7,9,2,1,'#1a1a22');});
  T('lab',t=>{t.F(0,9,16,7,'#c8ccd6');t.F(0,9,16,2,'#e8eaf0');t.F(0,15,16,1,'#8a90a0');t.F(5,7,7,2,'#3a3a48');t.F(9,1,2,7,'#4a4a5a');t.F(6,2,5,2,'#4a4a5a');t.F(6,4,2,2,'#88c8f0');t.F(8,0,3,2,'#2a2a34');});
  T('lab2',t=>{t.F(0,9,16,7,'#c8ccd6');t.F(0,9,16,2,'#e8eaf0');t.F(0,15,16,1,'#8a90a0');t.F(3,3,2,3,'#a0e8c0');t.box(2,5,4,5,'#58d080','#2a6a40');t.F(9,4,5,6,'#f0f0f8');t.F(10,5,3,4,'#e070c0');t.F(9,4,5,1,'#8a90a0');});
  T('table',t=>{t.F(1,3,14,9,'#a26c3e');t.F(1,3,14,8,'#c48a52');t.F(2,4,12,1,'#dcac6c');t.F(2,12,2,4,C.wood4);t.F(12,12,2,4,C.wood4);});
  T('fridge',t=>{t.box(2,0,12,16,'#e8eef4','#7a8494');t.F(3,6,10,1,'#7a8494');t.F(11,2,1,3,'#7a8494');t.F(11,8,1,5,'#7a8494');});
  T('shelfW',t=>{t.box(1,1,14,14,C.wood4,'#3a2414');t.F(2,7,12,1,C.wood2);t.F(2,13,12,1,C.wood2);
    const j=['#f0c040','#58c070','#e06060','#80b0f0','#c080e0'];for(let i=0;i<3;i++){t.F(3+i*4,3,3,4,j[(i+1)%5]);t.F(3+i*4,9,3,4,j[(i+3)%5]);t.P(3+i*4,3,'#ffffff');}});
  T('counter',t=>{t.F(0,4,16,12,'#7a5838');t.F(0,4,16,4,'#c49464');t.F(0,4,16,1,'#e0b480');t.F(0,15,16,1,'#4a3220');for(let x=2;x<16;x+=5)t.F(x,9,3,5,'#8c6a46');});
  T('barcounter',t=>{t.F(0,4,16,12,'#4a2c1c');t.F(0,4,16,4,'#8a5a36');t.F(0,4,16,1,'#b07a4a');t.F(0,15,16,1,'#2a1a10');t.F(0,10,16,1,'#c0a040');});
  T('display',t=>{t.box(1,2,14,14,'#e8e8e0','#6a6a74');const c=['#9bd35a','#e8e05a','#7aa6e0','#f0a048','#a070d0','#6fb04a'];for(let i=0;i<6;i++)t.F(3+(i%3)*4,4+Math.floor(i/3)*6,3,4,c[i]);});
  T('plantDeco',t=>{t.box(4,10,8,6,'#c86a3a','#6a3018');t.blob(8,6,6,6,'#3e9a4a','#1f4f2a','#78cc6c');});
  T('bottles',t=>{t.F(0,10,16,2,C.wood4);const c=['#3a8a3a','#a03030','#d0b040','#4060a0','#c0c0c8'];for(let i=0;i<5;i++){const h=5+(i%3);t.F(1+i*3,10-h,2,h,c[i]);t.P(1+i*3,10-h-1,'#3a3a3a');}t.F(0,3,16,1,C.wood4);for(let i=0;i<3;i++)t.F(2+i*5,0,3,3,'#e8e8f0');});
  T('stool',t=>{t.blob(8,7,5,2.6,'#c83838','#6a1818','#f06060');t.F(7,9,2,6,'#3c3c44');t.F(5,14,6,1,'#3c3c44');});
  T('btable',t=>{t.blob(8,8,7,4.5,'#8a5a36','#3a2414','#b07a4a');t.F(7,12,2,4,'#3a2414');t.F(5,4,2,3,'#f0e8a0');t.F(10,5,2,2,'#c03030');});
  T('jukebox',t=>{t.box(2,1,12,15,'#c03070','#4a1028');t.blob(8,5,4.5,3.5,'#f8d060','#a06010');t.F(4,9,8,4,'#2a2a34');for(let x=5;x<11;x+=2)t.F(x,10,1,2,'#58d0f0');});
  T('iwin',t=>{t.box(2,2,12,9,'#f8f8f8','#6a6a74');t.F(3,3,10,7,'#8cc8f0');t.F(3,8,10,2,'#5aa860');t.F(7,3,2,7,'#f8f8f8');t.P(4,4,'#ffffff');});
  T('poster',t=>{t.box(3,1,10,10,'#1e3a2a','#0e1a12');drawLeafPx(t,8,6,3.6,'#7ee08a');});
}
/* cannabis leaf, pixel version (cx,cy centre, s size) */
function drawLeafPx(t,cx,cy,s,col){
  const leaflets=[[-90,1],[-60,.82],[-120,.82],[-28,.58],[-152,.58],[0,.32],[180,.32]];
  for(const [deg,l] of leaflets){const a=deg*Math.PI/180,dx=Math.cos(a),dy=Math.sin(a),len=s*2*l,w=Math.max(.6,s*.34*l);
    for(let py=Math.floor(cy-len-2);py<=cy+len+2;py++)for(let px=Math.floor(cx-len-2);px<=cx+len+2;px++){
      const vx=px+.5-cx,vy=py+.5-cy,tt=(vx*dx+vy*dy)/len;if(tt<0||tt>1)continue;
      const d=Math.abs(vx*dy-vy*dx);if(d<=w*Math.sin(Math.PI*tt)+.15)t.P(px,py,col);}}
  t.F(Math.round(cx)-0,Math.round(cy),1,Math.max(2,Math.round(s)),col);
}
const SOLID_G=/^(water|roof|wall|win|iwT|iwB|void)/;
const COUNTERS=new Set(['counter','barcounter','btable','vitrina','barraD','cabina','cabina2']);   // 1.30: la vitrina del dispensario, la barra y la cabina del DJ
const SILLAS=new Set(['silla','sillaG','sillaG2']);   // 1.27.1: delante de un ordenador; con A, el ordenador de encima (delante, 08-mundo)


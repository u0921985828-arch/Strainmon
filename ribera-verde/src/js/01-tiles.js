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
  T('void',t=>t.F(0,0,16,16,'#000'));
  // buildings
  const B={home:['#d65a4a','#f0dcae','doorW'],shop:['#46a262','#d8ecc4','doorG'],bar:['#4a72c2','#d4dbe8','doorD'],gray:['#8a92a2','#e4cec4','none']};
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
  T('tent',t=>{t.F(0,0,16,16,'#d4d8e2');t.F(0,7,16,1,'#b2b8c4');t.F(7,0,1,16,'#b2b8c4');for(let i=0;i<5;i++)t.P(2+i,10-i,'#f2f4f8');for(let i=0;i<4;i++)t.P(10+i,5-i,'#f2f4f8');});
  // carpa de cultivo por dentro (montarCasa): capas sobre el suelo del piso (lo transparente deja ver el suelo).
  // Borde de la carpa a 8 px del borde de las casillas de los lados y de la fila de delante; las paredes de delante
  // y de la derecha están cortadas (se ve solo el riel del suelo) y no hay techo: se mira desde fuera de la carpa.
  {const K={pole:'#5a5e68',hi:'#8a8e98',tela:'#26272c',osc:'#1c1d22',my:'#d4d8e2',my2:'#b2b8c4',my3:'#f2f4f8',som:'#a8aebb'};
   const suelo=(t,x,y,w,h)=>{t.F(x,y,w,h,K.my);for(let i=0;i<3;i++)if(2+i*4<w)t.P(x+2+i*4,y+Math.min(h-1,4+i),K.my3);};
   // pared del fondo: mylar en vertical (arrugas en columnas claras y oscuras), más oscura abajo
   const fondo=(t,x,w,alto)=>{t.F(x,0,w,16,'#c8ccd6');for(let i=x;i<x+w;i++){const r=(i*7+3)%11;if(r<2)t.F(i,0,1,16,'#e6e9f0');else if(r===5)t.F(i,0,1,16,K.my2);}
     if(alto){t.F(x,0,w,2,K.pole);t.F(x,0,w,1,K.hi);t.F(x,2,w,1,K.som);}else{t.F(x,10,w,3,K.my2);t.F(x,13,w,2,K.som);t.F(x,15,w,1,K.pole);}};
   const izq=(t,h)=>{t.F(8,0,1,h,K.osc);t.F(9,0,1,h,K.pole);t.F(10,0,1,h,K.tela);t.F(11,0,2,h,K.som);};
   const dch=(t,h,poste)=>{t.F(5,0,1,h,poste?K.hi:K.pole);t.F(6,0,1,h,K.pole);t.F(7,0,1,h,K.osc);};
   const riel=(t,x,w)=>{t.F(x,6,w,1,K.hi);t.F(x,7,w,1,K.pole);t.F(x,8,w,1,K.osc);};
   T('cpT',t=>fondo(t,0,16,1));T('cpM',t=>fondo(t,0,16,0));
   T('cpTL',t=>{fondo(t,13,3,1);izq(t,16);});T('cpML',t=>{fondo(t,13,3,0);izq(t,16);});
   T('cpTR',t=>{fondo(t,0,5,1);dch(t,16,1);});T('cpMR',t=>{fondo(t,0,5,0);dch(t,16,1);});
   T('cpL',t=>{suelo(t,13,0,3,16);izq(t,16);});
   T('cpR',t=>{suelo(t,0,0,5,16);dch(t,16,0);});
   T('cpB',t=>{suelo(t,0,0,16,6);riel(t,0,16);});
   T('cpBL',t=>{suelo(t,13,0,3,6);izq(t,9);riel(t,8,8);});
   T('cpBR',t=>{suelo(t,0,0,5,6);t.F(5,0,3,6,K.pole);riel(t,0,8);});
   T('cpPuerta',t=>{suelo(t,0,0,16,9);t.F(0,6,2,3,K.hi);t.F(14,6,2,3,K.hi);t.F(2,8,12,1,K.my2);});}
  // bandeja de cultivo: una casilla por plaza, pero las de una carpa se unen en una sola bandeja de plástico sobre un bastidor
  // metálico (paleta de la carpa). Fotogramas: 0 suelta · 1 extremo izquierdo · 2 tramo central · 3 extremo derecho (14-render elige).
  // La maceta se apoya dentro de la cubeta, MESA_ALTO px más arriba que en el suelo.
  T('mesa',t=>{const iz=t.f<2,de=t.f===0||t.f===3,O='#2a2d34',a=iz?1:0,b=de?15:16;
    t.F(a,13,b-a,3,'rgba(60,66,84,.22)');                                   // sombra en el mylar
    t.F(a,14,b-a,1,'#5a5e68');                                              // larguero del bastidor
    if(iz){t.F(1,12,2,4,'#5a5e68');t.F(1,12,1,4,'#8a8e98');}if(de){t.F(13,12,2,4,'#5a5e68');t.F(13,12,1,4,'#8a8e98');}
    t.F(a,5,b-a,1,O);t.F(a,12,b-a,1,O);                                     // canto de arriba y de abajo
    t.F(a,6,b-a,1,'#f2f4f8');t.F(a,7,b-a,1,'#7d8492');t.F(a,8,b-a,1,'#9aa1ae'); // borde trasero, sombra y fondo de la cubeta
    t.F(a,9,b-a,1,'#f2f4f8');t.F(a,10,b-a,1,'#d4d8e2');t.F(a,11,b-a,1,'#b2b8c4'); // labio delantero con volumen
    if(iz){t.F(0,6,1,6,O);t.F(1,6,1,6,'#e6e9f0');}
    if(de){t.F(15,6,1,6,O);t.F(14,6,1,6,'#b2b8c4');t.F(14,9,1,1,'#d4d8e2');t.F(11,10,2,2,'#3a3e47');t.P(11,10,'#5a5e68');}   // desagüe
    if(!iz&&!de&&t.f===2)for(let x=3;x<16;x+=8)t.P(x,8,'#8b92a0');           // marcas del molde
  },4);
  T('mat',t=>{t.F(0,0,16,16,'#d8a868');t.box(1,3,14,11,'#c44a4a','#7a2626');for(let x=3;x<13;x+=3)t.F(x,5,1,7,'#a83636');});
  // objects (transparent)
  T('tree',t=>{t.F(6,11,4,5,C.wood4);t.F(7,11,1,5,'#8c6438');t.blob(8,6.5,7.6,6.6,'#3e9446','#1f4f2a','#72c868','#2c6e36');t.noise(6,['#2c6e36'],3,2,10,8);});
  T('bush',t=>{t.blob(8,9.5,7,5.6,'#4ea04e','#22522c','#86d474','#357a3c');});
  T('fence',t=>{const p=(x)=>{t.F(x,3,3,12,'#5a3a20');t.F(x+1,4,1,10,'#e8c890');};t.F(0,6,16,3,'#5a3a20');t.F(0,7,16,1,'#e8c890');t.F(0,11,16,3,'#5a3a20');t.F(0,12,16,1,'#e8c890');p(1);p(12);});
  T('sign',t=>{t.F(7,9,2,7,C.wood4);t.box(1,2,14,9,C.wood3,C.wood4);t.F(3,4,10,1,C.wood2);t.F(3,6,8,1,C.wood2);t.F(3,8,6,1,C.wood2);});
  T('lamp',t=>{t.F(7,3,2,12,'#3c444e');t.F(5,14,6,2,'#2c333c');t.F(4,0,8,3,'#4c5560');t.F(5,2,6,2,'#fff2a0');t.P(8,4,'#6a7480');});
  T('bench',t=>{t.F(1,3,14,3,C.wood1);t.F(1,3,14,1,C.wood3);t.F(1,8,14,3,C.wood1);t.F(1,8,14,1,C.wood3);t.F(1,6,14,2,'#3c444e');t.F(2,11,2,4,'#3c444e');t.F(12,11,2,4,'#3c444e');});
  T('fountain',t=>{t.blob(8,9,7.5,6,'#c8ccd6','#5a6070');t.blob(8,9,5.5,4,'#70b4f0','#4a88cc','#b4dcfa');t.F(7,1,2,8,'#b4dcfa');t.P(6,2,'#ffffff');t.P(9,2,'#ffffff');t.P(8,0,'#ffffff');});
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
const SOLID_G=/^(water|roof|wall|win|iwT|iwB|void|cp(?!Puerta))/;
const MESA_ALTO=6;
const COUNTERS=new Set(['counter','barcounter','btable']);


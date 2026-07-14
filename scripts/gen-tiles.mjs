#!/usr/bin/env node
/* TILESET ORIGINAL 32x32 (arte propio por código), estilo GBA suave para pegar
   con los personajes detallados. Sin assets de terceros. Salida: PNGs + preview. */
import fs from 'node:fs'; import sharp from 'sharp';
const S = 32;
const OUT = process.argv[2] || 'unity/Assets/StreamingAssets/tiles';
fs.mkdirSync(OUT, { recursive: true });

function rng(seed){ let a=seed>>>0; return ()=>{ a=(a+0x6D2B79F5)|0; let t=Math.imul(a^(a>>>15),1|a); t=(t+Math.imul(t^(t>>>7),61|t))^t; return ((t^(t>>>14))>>>0)/4294967296; }; }
const hex=h=>[parseInt(h.slice(1,3),16),parseInt(h.slice(3,5),16),parseInt(h.slice(5,7),16)];
const B=()=>new Uint8Array(S*S*4);
const px=(b,x,y,c,a=255)=>{ x|=0;y|=0; if(x<0||y<0||x>=S||y>=S)return; const o=(y*S+x)*4; b[o]=c[0];b[o+1]=c[1];b[o+2]=c[2];b[o+3]=a; };
const fill=(b,c)=>{ for(let y=0;y<S;y++)for(let x=0;x<S;x++)px(b,x,y,c); };
const rect=(b,x0,y0,x1,y1,c)=>{ for(let y=y0;y<=y1;y++)for(let x=x0;x<=x1;x++)px(b,x,y,c); };
const disc=(b,cx,cy,r,c)=>{ for(let y=-r;y<=r;y++)for(let x=-r;x<=r;x++) if(x*x+y*y<=r*r)px(b,cx+x,cy+y,c); };
const noise=(b,c,n,seed)=>{ const r=rng(seed); for(let i=0;i<n;i++)px(b,(r()*S)|0,(r()*S)|0,c); };

const P={
  g0:'#6f9c4e', g1:'#7fae5b', g2:'#8dbb66', g3:'#5c8642',
  dirt:'#c2a06a', dirt2:'#ad8a55', dirt3:'#d6bd8b', peb:'#9a7c4e',
  w0:'#5aa6c0', w1:'#74bcd2', w2:'#9fd6e2', w3:'#3f8aa4',
  tr0:'#3f6b34', tr1:'#4e7f40', tr2:'#65a052', tr3:'#2e5027', trunk:'#7a5533', trunkD:'#5c3f26',
  wall:'#d7c39c', wallD:'#bda57e', wallL:'#e7d8b6', roof:'#c06a52', roofD:'#9c5140', door:'#6e4527',
  sand:'#e3d3a0', sand2:'#d0bd85', wood:'#b98a52', wood2:'#96693a',
  rock:'#a7a29a', rock2:'#857f77', rockL:'#c2beb6', snow:'#e9eef1', ice:'#c4dbe6',
  cave:'#8b8492', lava:'#d5713f', lavaG:'#f0b24a', mud:'#977f57',
  f1:'#d98ab0', f2:'#ead06a', f3:'#c98ad9', fc:'#f4efe0',
};
const c=k=>hex(P[k]);

function grassBase(b,seed){ fill(b,c('g1')); const r=rng(seed);
  for(let i=0;i<70;i++){ const x=(r()*S)|0,y=(r()*S)|0; px(b,x,y,c(r()<0.5?'g0':'g2')); }
  for(let i=0;i<10;i++){ const x=(r()*S)|0,y=(r()*S)|0; px(b,x,y,c('g3')); px(b,x,y-1,c('g3')); }
}
const T={
  grass(b){ grassBase(b,1); },
  grass2(b){ grassBase(b,7); const r=rng(70); for(let i=0;i<4;i++){ const x=4+((r()*24)|0),y=4+((r()*24)|0); px(b,x,y,c('f2')); px(b,x+1,y,c('fc')); } },
  tallgrass(b){ grassBase(b,2); for(let x=2;x<S;x+=4){ const h=6+((x*5)%6); for(let y=0;y<h;y++){ px(b,x,S-1-y,c('g3')); px(b,x+1,S-1-y,c('g0')); } } },
  path(b){ fill(b,c('dirt')); noise(b,c('dirt2'),90,3); noise(b,c('dirt3'),40,4);
    const r=rng(30); for(let i=0;i<7;i++){ const x=3+((r()*26)|0),y=3+((r()*26)|0); disc(b,x,y,1,c('peb')); } },
  water(b){ fill(b,c('w0')); for(let y=0;y<S;y++)for(let x=0;x<S;x++){ if((y+((x/6)|0))%6===0)px(b,x,y,c('w3')); }
    const r=rng(5); for(let i=0;i<26;i++){ const x=(r()*S)|0,y=(r()*S)|0; px(b,x,y,c('w2')); px(b,x+1,y,c('w1')); } },
  tree(b){ grassBase(b,6); rect(b,14,22,17,27,c('trunk')); rect(b,14,22,14,27,c('trunkD'));
    disc(b,16,13,11,c('tr1')); disc(b,12,11,7,c('tr2')); disc(b,20,12,7,c('tr0'));
    const r=rng(7); for(let i=0;i<60;i++){ const a=r()*6.28,rr=r()*10; const x=16+Math.cos(a)*rr,y=13+Math.sin(a)*rr; px(b,x,y,c(r()<0.5?'tr3':'tr2')); }
    disc(b,13,9,3,c('tr2')); },
  pine(b){ grassBase(b,20); rect(b,15,25,17,29,c('trunk'));
    for(let l=0;l<4;l++){ const cy=6+l*5, hw=4+l*3.4; for(let y=cy;y<cy+7;y++)for(let x=0;x<S;x++){ if(Math.abs(x-16)<=hw-(y-cy)*0.7){ px(b,x,y,(x+y)%3?c('tr0'):c('tr1')); } } } },
  bush(b){ grassBase(b,8); disc(b,16,19,9,c('tr1')); disc(b,12,17,5,c('tr2')); disc(b,21,18,5,c('tr0')); },
  wall(b){ fill(b,c('wall')); for(let y=0;y<S;y+=8){ rect(b,0,y,S-1,y,c('wallD')); rect(b,0,y+1,S-1,y+1,c('wallL')); }
    for(let y=0;y<S;y+=8)for(let x=(y%16?4:12);x<S;x+=8)rect(b,x,y,x,y+7,c('wallD')); },
  roof(b){ fill(b,c('roof')); for(let y=0;y<S;y+=5){ for(let x=0;x<S;x++)px(b,x,y,c('roofD')); for(let x=(y%10?0:4);x<S;x+=8)rect(b,x,y+1,x,y+4,c('roofD')); } },
  door(b){ T.wall(b); rect(b,9,6,22,31,c('door')); rect(b,9,6,9,31,c('roofD')); rect(b,22,6,22,31,c('roofD')); px(b,20,19,c('f2')); },
  flowers(b){ grassBase(b,9); const spots=[[7,9,'f1'],[20,7,'f2'],[13,20,'f3'],[24,22,'f2'],[6,24,'f1'],[17,13,'f2']];
    for(const [x,y,k] of spots){ disc(b,x,y,2,c(k)); px(b,x,y,c('fc')); } },
  sand(b){ fill(b,c('sand')); noise(b,c('sand2'),80,9); },
  bridge(b){ fill(b,c('wood')); for(let x=0;x<S;x+=8)rect(b,x,0,x,S-1,c('wood2')); for(let y=0;y<S;y+=15)rect(b,0,y,S-1,y+1,c('wood2')); },
  rock(b){ grassBase(b,10); disc(b,16,19,9,c('rock')); disc(b,13,16,4,c('rockL')); const r=rng(11); for(let i=0;i<20;i++){ const a=r()*6.28,rr=6+r()*4; px(b,16+Math.cos(a)*rr,19+Math.sin(a)*rr*0.8,c('rock2')); } },
  snow(b){ fill(b,c('snow')); noise(b,c('ice'),50,11); },
  ice(b){ fill(b,c('ice')); for(let y=2;y<S;y+=8)rect(b,0,y,S-1,y,c('snow')); },
  cavefloor(b){ fill(b,c('cave')); noise(b,c('rock2'),90,12); },
  lava(b){ fill(b,c('lava')); for(let y=3;y<S;y+=7)rect(b,0,y,S-1,y,c('roofD')); noise(b,c('lavaG'),18,13); },
  mud(b){ fill(b,c('mud')); noise(b,c('dirt2'),80,14); },
  fence(b){ grassBase(b,15); rect(b,0,14,S-1,17,c('wood')); rect(b,0,14,S-1,14,c('wood2')); for(let x=2;x<S;x+=10)rect(b,x,10,x+2,26,c('wood2')); },
  sign(b){ grassBase(b,16); rect(b,14,20,17,31,c('wood2')); rect(b,7,7,24,21,c('wood')); rect(b,7,7,24,7,c('wood2')); rect(b,10,12,21,12,c('wood2')); rect(b,10,16,19,16,c('wood2')); },
  shore(b){ grassBase(b,41); for(let y=20;y<S;y++)for(let x=0;x<S;x++)px(b,x,y,c('w0')); for(let y=23;y<S;y+=6)rect(b,0,y,S-1,y,c('w3')); rect(b,0,19,S-1,20,c('sand2')); const r=rng(42); for(let i=0;i<10;i++)px(b,(r()*S)|0,20+((r()*11)|0),c('w2')); },
};

const names=Object.keys(T);
for(const n of names){ const b=B(); T[n](b); await sharp(Buffer.from(b),{raw:{width:S,height:S,channels:4}}).png().toFile(`${OUT}/${n}.png`); }
console.log(`tiles ${S}px: ${names.length} -> ${OUT}`);
const per=6, sc=5, cols=per, rows=Math.ceil(names.length/per), comps=[];
for(let i=0;i<names.length;i++){ const buf=await sharp(`${OUT}/${names[i]}.png`).resize(S*sc,S*sc,{kernel:'nearest'}).png().toBuffer(); comps.push({input:buf,left:(i%cols)*(S*sc+4),top:((i/cols)|0)*(S*sc+4)}); }
await sharp({create:{width:cols*(S*sc+4),height:rows*(S*sc+4),channels:4,background:{r:20,g:16,b:15,alpha:1}}}).composite(comps).png().toFile('/tmp/claude-0/-home-user-Strainmon/0f1a7ef5-8d47-53c6-8255-3b41a3c54115/scratchpad/tileset32.png');
console.log('preview -> tileset32.png');

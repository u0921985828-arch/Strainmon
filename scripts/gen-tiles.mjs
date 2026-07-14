#!/usr/bin/env node
/* Genera un TILESET ORIGINAL lush top-down (16x16, arte propio por código;
   sin assets de terceros). Salida: PNGs + un preview compuesto. */
import fs from 'node:fs'; import sharp from 'sharp';
const S = 16;
const OUT = process.argv[2] || 'unity/Assets/StreamingAssets/tiles';
fs.mkdirSync(OUT, { recursive: true });

function rng(seed){ let a=seed>>>0; return ()=>{ a=(a+0x6D2B79F5)|0; let t=Math.imul(a^(a>>>15),1|a); t=(t+Math.imul(t^(t>>>7),61|t))^t; return ((t^(t>>>14))>>>0)/4294967296; }; }
const hex = h => [parseInt(h.slice(1,3),16),parseInt(h.slice(3,5),16),parseInt(h.slice(5,7),16)];
function canvas(){ return new Uint8Array(S*S*4); }
function px(b,x,y,c,a=255){ if(x<0||y<0||x>=S||y>=S)return; const o=(y*S+x)*4; b[o]=c[0];b[o+1]=c[1];b[o+2]=c[2];b[o+3]=a; }
function fill(b,c){ for(let y=0;y<S;y++)for(let x=0;x<S;x++)px(b,x,y,c); }
function speck(b,c,n,seed){ const r=rng(seed); for(let i=0;i<n;i++)px(b,(r()*S)|0,(r()*S)|0,c); }

// paleta soft
const P = {
  grass:'#8fb46a', grassD:'#7ba257', grassL:'#a6c583',
  tall:'#6f9a4e', tallD:'#5c8440',
  dirt:'#c9a878', dirtD:'#b2905f', dirtL:'#d8bd90',
  water:'#7ab6c8', waterD:'#5f9fb4', waterL:'#9fd0dd',
  tree:'#4e7a42', treeD:'#3c6234', treeL:'#6b9a58', trunk:'#7b5a3a',
  wall:'#d8c7a6', wallD:'#c1ac86', roof:'#c8735e', roofD:'#a85846', door:'#7b4a2c',
  sand:'#e4d6a8', sandD:'#d3c08c', wood:'#b98f5a', woodD:'#986f42',
  rock:'#a9a29a', rockD:'#8b847c', snow:'#e8eef0', ice:'#c6dbe4',
  cave:'#8f8896', lava:'#d97a52', mud:'#9a8560', bush:'#5e8c4a',
  flower1:'#d98ab0', flower2:'#e6c65a', flowerC:'#f2efe0',
};
const c = k => hex(P[k]);

const TILES = {
  grass(b){ fill(b,c('grass')); speck(b,c('grassD'),22,1); speck(b,c('grassL'),14,2);
    for(const [x,y] of [[3,4],[10,7],[6,12],[13,2]]){ px(b,x,y,c('grassD')); px(b,x,y-1,c('grassD')); } },
  tallgrass(b){ TILES.grass(b); for(let x=1;x<S;x+=3){ const h=3+((x*7)%4); for(let y=0;y<h;y++){ px(b,x,S-1-y,c('tall')); if(x+1<S)px(b,x+1,S-1-y,c('tallD')); } } },
  path(b){ fill(b,c('dirt')); speck(b,c('dirtD'),26,3); speck(b,c('dirtL'),12,4); },
  water(b){ fill(b,c('water')); for(let y=2;y<S;y+=4){ for(let x=0;x<S;x++) px(b,x,y,c('waterD')); }
    speck(b,c('waterL'),18,5); },
  tree(b){ fill(b,c('grass')); speck(b,c('grassD'),10,6);
    // copa
    for(let y=0;y<12;y++)for(let x=0;x<S;x++){ const dx=x-8,dy=y-6; if(dx*dx*0.9+dy*dy<38){ px(b,x,y,c('tree')); } }
    speck2(b,'treeD',30,7,0,12); speck2(b,'treeL',22,8,0,10);
    px(b,7,12,c('trunk')); px(b,8,12,c('trunk')); px(b,7,13,c('trunk')); px(b,8,13,c('trunk')); },
  bush(b){ fill(b,c('grass')); for(let y=3;y<14;y++)for(let x=2;x<14;x++){ const dx=x-8,dy=y-9; if(dx*dx+dy*dy<26)px(b,x,y,c('bush')); } speck2(b,'treeL',12,9,4,10); },
  wall(b){ fill(b,c('wall')); for(let y=0;y<S;y+=4)for(let x=0;x<S;x++)px(b,x,y,c('wallD')); for(let x=0;x<S;x+=6)for(let y=0;y<S;y++)px(b,x,y,c('wallD')); },
  roof(b){ fill(b,c('roof')); for(let y=0;y<S;y+=3)for(let x=0;x<S;x++)px(b,x,y,c('roofD')); },
  door(b){ TILES.wall(b); for(let y=3;y<S;y++)for(let x=5;x<11;x++)px(b,x,y,c('door')); px(b,9,9,c('flowerC')); },
  flowers(b){ TILES.grass(b); const spots=[[4,5,'flower1'],[10,4,'flower2'],[7,10,'flower1'],[12,11,'flower2'],[3,12,'flower2']];
    for(const [x,y,k] of spots){ px(b,x,y,c(k)); px(b,x+1,y,c(k)); px(b,x,y+1,c(k)); px(b,x+1,y+1,c(k)); px(b,x,y,c('flowerC')); } },
  sand(b){ fill(b,c('sand')); speck(b,c('sandD'),20,9); },
  bridge(b){ fill(b,c('wood')); for(let x=0;x<S;x+=4)for(let y=0;y<S;y++)px(b,x,y,c('woodD')); for(let y=0;y<S;y+=8)for(let x=0;x<S;x++)px(b,x,y,c('woodD')); },
  rock(b){ fill(b,c('grass')); for(let y=4;y<14;y++)for(let x=3;x<13;x++){ const dx=x-8,dy=y-9; if(dx*dx+dy*dy<24)px(b,x,y,c('rock')); } speck2(b,'rockD',14,10,3,13); },
  snow(b){ fill(b,c('snow')); speck(b,c('ice'),16,11); },
  ice(b){ fill(b,c('ice')); for(let y=1;y<S;y+=5)for(let x=0;x<S;x++)px(b,x,y,c('snow')); },
  cavefloor(b){ fill(b,c('cave')); speck(b,c('rockD'),24,12); },
  lava(b){ fill(b,c('lava')); for(let y=2;y<S;y+=5)for(let x=0;x<S;x++)px(b,x,y,c('roofD')); speck(b,c('flower2'),8,13); },
  mud(b){ fill(b,c('mud')); speck(b,c('dirtD'),22,14); },
};
function speck2(b,k,n,seed,y0,y1){ const r=rng(seed); for(let i=0;i<n;i++){ const y=y0+((r()*(y1-y0))|0); px(b,(r()*S)|0,y,c(k)); } }

const names=Object.keys(TILES);
for(const n of names){ const b=canvas(); TILES[n](b); await sharp(Buffer.from(b),{raw:{width:S,height:S,channels:4}}).png().toFile(`${OUT}/${n}.png`); }
console.log(`tiles: ${names.length} -> ${OUT}`);
// preview compuesto x10
const per=8, scale=10; const cols=per, rows=Math.ceil(names.length/per);
const comps=[]; for(let i=0;i<names.length;i++){ const buf=await sharp(`${OUT}/${names[i]}.png`).resize(S*scale,S*scale,{kernel:'nearest'}).extend({top:2,bottom:14,left:2,right:2,background:'#20161f'}).png().toBuffer(); comps.push({input:buf,left:(i%cols)*(S*scale+4),top:((i/cols)|0)*(S*scale+16)}); }
await sharp({create:{width:cols*(S*scale+4),height:rows*(S*scale+16),channels:4,background:{r:0x14,g:0x10,b:0x0f,alpha:1}}}).composite(comps).png().toFile('/tmp/claude-0/-home-user-Strainmon/0f1a7ef5-8d47-53c6-8255-3b41a3c54115/scratchpad/tileset_preview.png');
console.log('preview -> scratchpad/tileset_preview.png');

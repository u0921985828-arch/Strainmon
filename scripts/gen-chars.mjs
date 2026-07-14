#!/usr/bin/env node
/* Sprites de personaje ORIGINALES 4-dir (16x24, chibi top-down, arte por código,
   sin assets de terceros). down/up/left/right por rol. */
import fs from 'node:fs'; import sharp from 'sharp';
const W=16,H=24, OUT=process.argv[2]||'unity/Assets/StreamingAssets/chars';
fs.mkdirSync(OUT,{recursive:true});
const hex=h=>[parseInt(h.slice(1,3),16),parseInt(h.slice(3,5),16),parseInt(h.slice(5,7),16)];
const B=()=>new Uint8Array(W*H*4);
const px=(b,x,y,c,a=255)=>{ if(x<0||y<0||x>=W||y>=H)return; const o=(y*W+x)*4; b[o]=c[0];b[o+1]=c[1];b[o+2]=c[2];b[o+3]=a; };
const rect=(b,x0,y0,x1,y1,c)=>{ for(let y=y0;y<=y1;y++)for(let x=x0;x<=x1;x++)px(b,x,y,c); };
const OL=hex('#20161f'); // contorno
const ROLES={
  player:{skin:'#e6b98f',hair:'#5a3a22',shirt:'#3f8f4a',pants:'#33506b',cap:'#2f6b3a'},
  botanist:{skin:'#e6b98f',hair:'#4a3520',shirt:'#eef1f2',pants:'#7a8792',cap:null},
  neighbor:{skin:'#d9a97e',hair:'#8a5a2a',shirt:'#4a76b0',pants:'#35455a',cap:null},
  merchant:{skin:'#c98f63',hair:'#3a2a1a',shirt:'#b0733a',pants:'#4a3a2a',cap:'#8a5a2a'},
};
function outline(b){ // añade contorno oscuro alrededor de píxeles opacos
  const cp=b.slice();
  for(let y=0;y<H;y++)for(let x=0;x<W;x++){ const o=(y*W+x)*4; if(cp[o+3]>0)continue;
    let near=false; for(const [dx,dy] of [[1,0],[-1,0],[0,1],[0,-1]]){ const nx=x+dx,ny=y+dy; if(nx<0||ny<0||nx>=W||ny>=H)continue; if(cp[(ny*W+nx)*4+3]>0){near=true;break;} }
    if(near)px(b,x,y,OL); }
}
function body(b,p,dir){
  const skin=hex(p.skin),hair=hex(p.hair),shirt=hex(p.shirt),pants=hex(p.pants),cap=p.cap&&hex(p.cap);
  // piernas
  rect(b,5,18,7,22,pants); rect(b,8,18,10,22,pants);
  rect(b,5,22,7,23,OL); rect(b,8,22,10,23,OL); // pies
  // torso
  rect(b,4,11,11,18,shirt);
  // brazos
  rect(b,3,11,4,16,shirt); rect(b,11,11,12,16,shirt);
  rect(b,3,16,4,17,skin); rect(b,11,16,12,17,skin);
  // cabeza
  rect(b,5,4,10,10,skin);
  // pelo / gorra
  if(cap){ rect(b,4,3,11,5,cap); rect(b,4,5,5,6,cap); rect(b,10,5,11,6,cap); if(dir==='down'||dir==='left'||dir==='right') rect(b,4,6,11,6,cap); }
  else { rect(b,4,3,11,5,hair); rect(b,4,5,4,7,hair); rect(b,11,5,11,7,hair); }
  // cara según dir
  if(dir==='down'){ px(b,6,7,OL);px(b,9,7,OL); px(b,7,9,hex('#b57'.padEnd(7,'0'))); }
  else if(dir==='up'){ rect(b,4,4,11,8,cap?cap:hair); } // nuca
  else { // side (left); right = espejo
    rect(b,5,4,9,10,skin); if(!cap)rect(b,5,3,10,5,hair); else rect(b,5,3,10,5,cap);
    px(b,6,7,OL); // un ojo
  }
}
function mirror(b){ const o=B(); for(let y=0;y<H;y++)for(let x=0;x<W;x++){ const s=(y*W+(W-1-x))*4,d=(y*W+x)*4; o[d]=b[s];o[d+1]=b[s+1];o[d+2]=b[s+2];o[d+3]=b[s+3]; } return o; }

for(const [role,p] of Object.entries(ROLES)){
  for(const dir of ['down','up','left']){ const b=B(); body(b,p,dir); outline(b); await sharp(Buffer.from(b),{raw:{width:W,height:H,channels:4}}).png().toFile(`${OUT}/${role}_${dir}.png`); }
  const left=fs.readFileSync(`${OUT}/${role}_left.png`); const rb=B(); body(rb,p,'left'); outline(rb); await sharp(Buffer.from(mirror(rb)),{raw:{width:W,height:H,channels:4}}).png().toFile(`${OUT}/${role}_right.png`);
}
console.log('chars:', Object.keys(ROLES).length,'roles x4 dir ->',OUT);
// preview
const roles=Object.keys(ROLES), dirs=['down','up','left','right'], sc=6;
const comps=[]; for(let r=0;r<roles.length;r++)for(let d=0;d<4;d++){ const buf=await sharp(`${OUT}/${roles[r]}_${dirs[d]}.png`).resize(W*sc,H*sc,{kernel:'nearest'}).png().toBuffer(); comps.push({input:buf,left:d*(W*sc+6),top:r*(H*sc+6)}); }
await sharp({create:{width:4*(W*sc+6),height:roles.length*(H*sc+6),channels:4,background:{r:0x2a,g:0x1f,b:0x26,alpha:1}}}).composite(comps).png().toFile('/tmp/claude-0/-home-user-Strainmon/0f1a7ef5-8d47-53c6-8255-3b41a3c54115/scratchpad/chars_preview.png');
console.log('preview listo');

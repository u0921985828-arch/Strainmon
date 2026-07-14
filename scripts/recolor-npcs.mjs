/* Recolores NPC del personaje nuevo (arte propio). Rota tono + tinte por rol.
   Mismo layout que player: 4 dir x [idle + walk_0..3]. */
import fs from 'node:fs'; import sharp from 'sharp';
const SRC='unity/Assets/StreamingAssets/actors/player';
const DIRS=['down','up','left','right'];
const FILES=['idle','walk_0','walk_1','walk_2','walk_3'];
// hue en grados, brillo, saturación
const ROLES={
  stoner:   {hue: 300, sat:1.05, bri:1.0},   // púrpura
  townie_a: {hue: 40,  sat:1.1,  bri:1.02},  // cálido/ámbar
  townie_b: {hue: 190, sat:1.0,  bri:1.0},   // azul
  townie_c: {hue: 120, sat:0.95, bri:1.0},   // verde
};
for(const [role,m] of Object.entries(ROLES)){
  const dst=`unity/Assets/StreamingAssets/actors/${role}`;
  // limpia frames viejos (6-frame) para no dejar walk_4/5 huérfanos
  fs.rmSync(dst,{recursive:true,force:true}); fs.mkdirSync(dst,{recursive:true});
  for(const d of DIRS)for(const f of FILES){
    const inp=`${SRC}/${d}_${f}.png`;
    await sharp(inp).modulate({hue:m.hue,saturation:m.sat,brightness:m.bri}).png().toFile(`${dst}/${d}_${f}.png`);
  }
  console.log('recolor',role);
}
console.log('done');

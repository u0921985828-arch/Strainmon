/* =========================================================
   DATOS: variedades, recetas, personajes
   ========================================================= */
const STRAINS={
  ria:{n:'Ría Skunk',thc:12,y:40,d:2.5,r:75,c:'#9bd35a',o:'Growshop · robusta, ideal para empezar'},
  limon:{n:'Limón Haze',thc:15,y:30,d:3.5,r:50,c:'#e8e05a',o:'Growshop · cítrica y lenta'},
  txoko:{n:'Txoko Kush',thc:16,y:34,d:3,r:65,c:'#6fb04a',o:'Growshop · índica de sobremesa'},
  niebla:{n:'Niebla Blue',thc:17,y:32,d:3.5,r:55,c:'#7aa6e0',o:'Growshop · azulada, olor a bruma'},
  mango:{n:'Mango Rompeolas',thc:15,y:45,d:3,r:60,c:'#f0a048',o:'Growshop · productiva y afrutada'},
  purpura:{n:'Púrpura Monte',thc:18,y:28,d:4,r:45,c:'#a070d0',o:'Growshop · delicada, tonos morados'},
  rif:{n:'Atlas Rif',thc:16,y:38,d:3,r:85,c:'#c8b070',o:'Landrace · montañas del Rif'},
  hindu:{n:'Hindú Valle',thc:18,y:30,d:3,r:80,c:'#4a8a3a',o:'Landrace · valles del Hindu Kush'},
  acapulco:{n:'Acapulco Oro',thc:19,y:26,d:4.5,r:60,c:'#f0c838',o:'Landrace · costa del Pacífico'},
  malawi:{n:'Malawi Sol',thc:20,y:24,d:5,r:55,c:'#d8e070',o:'Landrace · África oriental'},
  citrus:{n:'Citrus Bruma',thc:18,y:40,d:3,r:70,c:'#c8e050',o:'Ría Skunk × Limón Haze'},
  bluetx:{n:'Blue Txoko',thc:20,y:36,d:3,r:65,c:'#5a90c8',o:'Txoko Kush × Niebla Blue'},
  sollimon:{n:'Sol de Limón',thc:21,y:30,d:4,r:55,c:'#f0e878',o:'Limón Haze × Malawi Sol'},
  kushrif:{n:'Kush del Rif',thc:21,y:40,d:3,r:85,c:'#a8a050',o:'Atlas Rif × Txoko Kush'},
  purpurah:{n:'Púrpura Hindú',thc:22,y:32,d:3.5,r:70,c:'#8050b0',o:'Hindú Valle × Púrpura Monte'},
  orotrop:{n:'Oro Tropical',thc:21,y:38,d:3.5,r:60,c:'#f8b030',o:'Acapulco Oro × Mango Rompeolas'},
  nieblamor:{n:'Niebla Morada',thc:22,y:30,d:4,r:55,c:'#9080e0',o:'Niebla Blue × Púrpura Monte'},
  brumaog:{n:'Bruma Azul OG',thc:23,y:40,d:3,r:70,c:'#70b0b0',o:'Citrus Bruma × Blue Txoko'},
  reina:{n:'Reina del Atlas',thc:25,y:38,d:3.5,r:80,c:'#b060a0',o:'Kush del Rif × Púrpura Hindú'},
  amanecer:{n:'Amanecer Dorado',thc:24,y:36,d:3.5,r:60,c:'#f8d050',o:'Sol de Limón × Oro Tropical'},
  tormenta:{n:'Tormenta Violeta',thc:26,y:36,d:3.5,r:65,c:'#7058d0',o:'Niebla Morada × Bruma Azul OG'},
  dragon:{n:'Dragón de Ribera',thc:27,y:42,d:3.5,r:75,c:'#e05050',o:'Reina del Atlas × Amanecer Dorado'},
  leyenda:{n:'Leyenda de la Ría',thc:31,y:45,d:4,r:80,c:'#40e0a0',o:'Tormenta Violeta × Dragón de Ribera · LEGENDARIA'},
};
const DEX=Object.keys(STRAINS);
// forma del cogollo en los menús (cogollos-genoteca del atlas); los híbridos propios, 'hibrido'
const TIPO_COGOLLO={ria:'hibrido',limon:'sativa',txoko:'indica',niebla:'hibrido',mango:'sativa',purpura:'indica',rif:'indica',hindu:'indica',acapulco:'sativa',malawi:'sativa',
  citrus:'sativa',bluetx:'hibrido',sollimon:'sativa',kushrif:'indica',purpurah:'indica',orotrop:'sativa',nieblamor:'hibrido',brumaog:'hibrido',reina:'indica',amanecer:'sativa',tormenta:'hibrido',dragon:'legendario',leyenda:'legendario'};
const RECIPES={};
[['ria','limon','citrus'],['txoko','niebla','bluetx'],['limon','malawi','sollimon'],['rif','txoko','kushrif'],['hindu','purpura','purpurah'],
 ['acapulco','mango','orotrop'],['niebla','purpura','nieblamor'],['citrus','bluetx','brumaog'],['kushrif','purpurah','reina'],
 ['sollimon','orotrop','amanecer'],['nieblamor','brumaog','tormenta'],['reina','amanecer','dragon'],['tormenta','dragon','leyenda']]
 .forEach(([a,b,c])=>{RECIPES[[a,b].sort().join('+')]=c;});
function getStrain(id){return STRAINS[id]||(S&&S.custom[id])||null;}
function crossResult(a,b){
  const key=[a,b].sort().join('+');
  if(RECIPES[key])return RECIPES[key];
  const id='x'+hashStr(key).toString(36);
  if(!S.custom[id]){
    const A=getStrain(a),B=getStrain(b),R=rngSeed(hashStr(key));
    const w=s=>s.n.split(' ');const wa=w(A),wb=w(B);
    let name=wa[0]+' '+wb[wb.length-1];if(name===A.n||name===B.n)name=wb[0]+' '+wa[wa.length-1];
    if(Object.values(S.custom).some(c=>c.n===name))name+=' F'+(2+Math.floor(R()*7));
    S.custom[id]={n:name,thc:Math.min(33,Math.round(((A.thc+B.thc)/2+R()*3.5-1.5)*10)/10),y:Math.round((A.y+B.y)/2+R()*8-4),
      d:Math.round(((A.d+B.d)/2+R()*.6-.3)*2)/2,r:clamp(Math.round((A.r+B.r)/2+R()*10-5),20,95),c:mix(A.c,B.c,.5),o:A.n+' × '+B.n+' · híbrido propio'};
  }
  return id;
}
/* looks */
const LOOKS={
  player:{id:'player',skin:'#f6c8a0',hair:'#3a2a20',style:'cap',hat:'#2fa868',hat2:'#1a6a40',shirt:'#e65040',pants:'#36466e'},
  kiko:{id:'kiko',skin:'#e8b088',hair:'#c48a3a',style:'long',beard:1,shirt:'#5aa848',pants:'#7a5a3a'},
  josune:{id:'josune',skin:'#f0c0a0',hair:'#2a1a14',style:'bun',shirt:'#f4f4f4',shirt2:'#2a2a30',pants:'#2a2a30'},
  baltasar:{id:'baltasar',skin:'#e0aa84',hair:'#9a9aa4',style:'bald',beard:'#9a9aa4',shirt:'#4a2a5a',shirt2:'#e8e8e8',pants:'#2a2030'},
  tono:{id:'tono',skin:'#d49a74',hair:'#1a1a1a',style:'bald',shirt:'#202024',shirt2:'#3a3a40',pants:'#3a3a48',stache:'#1a1a1a'},
  begona:{id:'begona',skin:'#f6cca8',hair:'#8a4a2a',style:'curly',shirt:'#e078a8',pants:'#5a5a9a'},
  kid:{id:'kid',skin:'#f6cca8',hair:'#2a2a2a',style:'short',shirt:'#f0c838',pants:'#4a6aa8'},
  oldman:{id:'oldman',skin:'#e8b894',hair:'#d8d8d8',style:'bald',beard:'#d8d8d8',shirt:'#b8a070',pants:'#5a5048'},
  granny:{id:'granny',skin:'#f0c8a8',hair:'#e0e0e8',style:'bun',shirt:'#8a5aa8',pants:'#4a3a5a',glasses:1},
  sailor:{id:'sailor',skin:'#d8a07a',hair:'#5a3a24',style:'cap',hat:'#24346a',hat2:'#f4f4f4',shirt:'#f4f4f4',shirt2:'#3050a0',pants:'#24346a',beard:1},
  cop:{id:'cop',skin:'#eab890',hair:'#2a2a2a',style:'cap',hat:'#1e2a5a',hat2:'#0e1430',shirt:'#8ab0e0',shirt2:'#1e2a5a',pants:'#1e2a5a'},
  molina:{id:'molina',skin:'#dca07c',hair:'#4a4a4a',style:'cap',hat:'#1e2a5a',hat2:'#f0c040',shirt:'#6a8ac0',shirt2:'#f0c040',pants:'#1e2a5a',stache:'#3a3a3a'},
  darko:{id:'darko',skin:'#f2c4a0',hair:'#101014',style:'hood',hat:'#202024',shirt:'#202024',shirt2:'#c02828',pants:'#303038'},
  judge:{id:'judge',skin:'#f0c4a0',hair:'#6a4a2a',style:'short',shirt:'#3a3a48',shirt2:'#c0a040',pants:'#2a2a34',glasses:1},
};
const SKINS=['#f6c8a0','#e8b088','#d49a74','#b07850','#8a5a3a','#f0d0b8'];
const HAIRS=['#2a1a14','#5a3a24','#c48a3a','#1a1a1a','#8a2a1a','#d8c070'];
const CLOTH=['#e65040','#4a8ad0','#5ab868','#f0c838','#a060c0','#f08a40','#3a3a48','#e0e0e8','#c04870','#40a0a0'];
function randLook(seed,kind){
  const R=rngSeed(hashStr(seed));const p=a=>a[Math.floor(R()*a.length)];
  if(kind==='thief')return {id:'t'+seed,skin:p(SKINS),hair:p(HAIRS),style:'hood',hat:p(['#2a2a30','#3a2a4a','#2a3a2a','#4a2a2a']),shirt:'#2a2a30',shirt2:p(['#c02828','#e0e0e0','#3a8a3a']),pants:'#3a3a44'};
  return {id:'n'+seed,skin:p(SKINS),hair:p(HAIRS),style:p(['short','short','long','curly','bun','cap','bald']),hat:p(CLOTH),shirt:p(CLOTH),pants:p(['#36466e','#3a3a44','#5a4a3a','#4a6aa8','#2a2a30']),beard:R()<.15?1:0,glasses:R()<.15?1:0};
}
const CTYPES={
  est:{label:'ESTUDIANTE',mult:.85,g:[2,5],greet:['¡Ey! Tengo examen el lunes, necesito relajarme.','Aupa, ¿tienes algo? Voy justo de pasta.']},
  cur:{label:'CURRELA',mult:1,g:[3,8],greet:['Buenas. Salgo de doble turno y me lo merezco.','Qué pasa. Lo de siempre, sin líos.']},
  tur:{label:'TURISTA',mult:1.15,g:[4,9],greet:['Hello! Eh... ¿tú tienes... marihuana? Pago bien.','Bonjour! Me han dicho que aquí hay de la buena.']},
  pij:{label:'PIJO',mult:1.35,g:[5,12],greet:['Busco algo premium para una fiesta en Neguri.','Solo quiero lo mejor. El precio me da igual.']},
};


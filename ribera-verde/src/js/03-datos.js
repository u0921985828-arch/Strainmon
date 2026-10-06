/* =========================================================
   DATOS: variedades, recetas, personajes
   ========================================================= */
// Variedades reales (nombres de uso común entre cultivadores; ninguna marca de banco de semillas). Los ids internos son
// los de las primeras versiones para no romper partidas guardadas. c = tono del cogollo (verde con el matiz de la variedad).
const STRAINS={
  ria:{n:'Skunk #1',thc:12,y:40,d:2.5,r:75,c:'#9bd35a',o:'Growshop · un clásico de los setenta: robusta, estable y fácil'},
  limon:{n:'Lemon Haze',thc:15,y:30,d:3.5,r:50,c:'#d8e060',o:'Growshop · sativa cítrica, de floración lenta'},
  txoko:{n:'OG Kush',thc:16,y:34,d:3,r:65,c:'#6fb04a',o:'Growshop · índica dominante, olor a gasóleo y pino'},
  niebla:{n:'Blueberry',thc:17,y:32,d:3.5,r:55,c:'#7a9ec8',o:'Growshop · índica afrutada; con frío de noche azulea'},
  mango:{n:'Mango',thc:15,y:45,d:3,r:60,c:'#b8c850',o:'Growshop · índica muy productiva, aroma a fruta madura'},
  purpura:{n:'Purple Afghani',thc:18,y:28,d:4,r:45,c:'#9070b8',o:'Growshop · índica delicada que se vuelve morada al final'},
  rif:{n:'Afghani',thc:16,y:38,d:3,r:85,c:'#88a050',o:'Landrace · montañas del norte de Afganistán'},
  hindu:{n:'Hindu Kush',thc:18,y:30,d:3,r:80,c:'#4a8a3a',o:'Landrace · cordillera del Hindu Kush, entre Afganistán y Pakistán'},
  acapulco:{n:'Acapulco Gold',thc:19,y:26,d:4.5,r:60,c:'#d0c048',o:'Landrace · costa de Guerrero, México'},
  malawi:{n:'Malawi Gold',thc:20,y:24,d:5,r:55,c:'#c8d068',o:'Landrace · sativa de África oriental, floración muy larga'},
  citrus:{n:'Lemon Skunk',thc:18,y:40,d:3,r:70,c:'#c0dc50',o:'Skunk #1 × Lemon Haze'},
  bluetx:{n:'Blueberry Kush',thc:20,y:36,d:3,r:65,c:'#6a94b8',o:'OG Kush × Blueberry'},
  sollimon:{n:'Trainwreck',thc:21,y:30,d:4,r:55,c:'#a8cc58',o:'Acapulco Gold × Afghani'},
  kushrif:{n:'Critical Mass',thc:21,y:40,d:3,r:85,c:'#8cbc4c',o:'Afghani × Skunk #1'},
  purpurah:{n:'Purple Kush',thc:22,y:32,d:3.5,r:70,c:'#7a5aa8',o:'Hindu Kush × Purple Afghani'},
  orotrop:{n:'Mango Kush',thc:21,y:38,d:3.5,r:60,c:'#a8c040',o:'Mango × Hindu Kush'},
  nieblamor:{n:'Blue Dream',thc:22,y:34,d:4,r:55,c:'#80a8c0',o:'Blueberry × Lemon Haze'},
  brumaog:{n:'Super Lemon Haze',thc:23,y:38,d:4,r:65,c:'#d0e458',o:'Lemon Skunk × Lemon Haze'},
  reina:{n:'Critical Kush',thc:24,y:42,d:3.5,r:80,c:'#78ac44',o:'Critical Mass × OG Kush'},
  amanecer:{n:'Purple Haze',thc:23,y:34,d:4,r:60,c:'#8a64b0',o:'Purple Kush × Lemon Haze'},
  tormenta:{n:'Amnesia Haze',thc:26,y:36,d:4.5,r:65,c:'#bcd468',o:'Super Lemon Haze × Trainwreck'},
  dragon:{n:'Fire OG',thc:27,y:40,d:3.5,r:75,c:'#90b448',o:'Critical Kush × Blueberry Kush'},
  leyenda:{n:'Ghost Train Haze',thc:29,y:42,d:4.5,r:75,c:'#d8ecb0',o:'Amnesia Haze × Fire OG · LEGENDARIA'},
};
const DEX=Object.keys(STRAINS);
// forma del cogollo en los menús (cogollos-genoteca del atlas)
const TIPO_COGOLLO={ria:'hibrido',limon:'sativa',txoko:'indica',niebla:'indica',mango:'indica',purpura:'indica',rif:'indica',hindu:'indica',acapulco:'sativa',malawi:'sativa',
  citrus:'sativa',bluetx:'indica',sollimon:'sativa',kushrif:'indica',purpurah:'indica',orotrop:'hibrido',nieblamor:'hibrido',brumaog:'sativa',reina:'indica',amanecer:'sativa',tormenta:'sativa',dragon:'legendario',leyenda:'legendario'};
const RECIPES={};
[['ria','limon','citrus'],['txoko','niebla','bluetx'],['acapulco','rif','sollimon'],['rif','ria','kushrif'],['hindu','purpura','purpurah'],
 ['mango','hindu','orotrop'],['niebla','limon','nieblamor'],['citrus','limon','brumaog'],['kushrif','txoko','reina'],
 ['purpurah','limon','amanecer'],['brumaog','sollimon','tormenta'],['reina','bluetx','dragon'],['tormenta','dragon','leyenda']]
 .forEach(([a,b,c])=>{RECIPES[[a,b].sort().join('+')]=c;});
function getStrain(id){return STRAINS[id]||(S&&S.custom[id])||null;}
function crossResult(a,b){
  const key=[a,b].sort().join('+');
  if(RECIPES[key])return RECIPES[key];
  const id='x'+hashStr(key).toString(36);
  if(!S.custom[id]){
    const A=getStrain(a),B=getStrain(b),R=rngSeed(hashStr(key));
    const w=s=>s.n.split(' ').filter(p=>!p.startsWith('#'));const wa=w(A),wb=w(B);
    const usado=n=>n===A.n||n===B.n||DEX.some(k=>STRAINS[k].n===n)||Object.values(S.custom).some(c=>c.n===n);
    let name=wa[0]+' '+wb[wb.length-1];if(wa[0]===wb[wb.length-1]||usado(name))name=wb[0]+' '+wa[wa.length-1];
    if(usado(name))name=A.n+' × '+B.n;
    if(usado(name))name+=' F'+(2+Math.floor(R()*7));
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
  est:{label:'ESTUDIANTE',mult:.85,g:[2,5],greet:['Hola. Me ha dicho un amigo que tienes.','Aupa, ¿tienes algo? Voy justo de dinero.']},
  cur:{label:'CURRELA',mult:1,g:[3,8],greet:['Buenas. Salgo de doble turno.','Qué tal. Lo de siempre, sin líos.']},
  tur:{label:'TURISTA',mult:1.15,g:[4,9],greet:['Hello. ¿Tú vendes... marihuana? Pago bien.','Bonjour. Me han dicho que aquí se cultiva bien.']},
  pij:{label:'PIJO',mult:1.35,g:[5,12],greet:['Busco algo de calidad para una cena en Neguri.','Solo quiero lo mejor. El precio me da igual.']},
};


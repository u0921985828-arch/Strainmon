/* =========================================================
   DATOS: variedades, recetas, personajes
   ========================================================= */
// Variedades reales (nombres de uso común entre cultivadores; ningún banco de semillas, criador ni persona). Los ids internos
// son los de las primeras versiones para no romper partidas guardadas (1.11: algunos cambian de variedad). c = tono del cogollo.
// h = historia (Genoteca). gen (1.11): generación del árbol de híbridos clásicos (1.ª, 2.ª o 3.ª); «≈ origen incierto» en o
// cuando los padres no están documentados. Las landraces salen del catálogo de Strainmon (src/species.js), con su nombre real.
const STRAINS={
  // de growshop (SHOP)
  ria:{n:'Skunk #1',thc:12,y:40,d:2.5,r:75,c:'#9bd35a',ind:65,hj:'#57a33e',gen:1,o:'Afghani × Colombian Gold × Acapulco Gold',h:'Fijada a finales de los setenta con tres landraces: robusta, estable y fácil. Es la base de media genética moderna.'},
  limon:{n:'Lemon Haze',thc:15,y:30,d:3.5,r:50,c:'#d8e060',ind:20,hj:'#7aa63e',gen:3,o:'Lemon Skunk × Silver Haze · ≈ origen incierto',h:'Sativa cítrica de floración lenta. Su linaje exacto no está publicado.'},
  txoko:{n:'Super Skunk',thc:19,y:46,d:2.5,r:85,c:'#6fb04a',ind:80,hj:'#50973b',gen:2,o:'Skunk #1 × Afghani',h:'La Skunk #1 vuelta a cruzar con Afghani: más índica, más rápida y más olorosa.'},
  niebla:{n:'Blueberry',thc:17,y:32,d:3.5,r:55,c:'#7a9ec8',ind:80,hj:'#4a8a4c',gen:2,o:'Purple Thai × Highland Thai × Afghani',h:'Índica afrutada de los setenta; con frío de noche azulea.'},
  mango:{n:'Big Bud',thc:17,y:50,d:3,r:75,c:'#b8c850',ind:85,hj:'#4f9a3c',gen:3,o:'base Afghani · ≈ origen incierto',h:'Famosa por el tamaño de sus cogollos. Sus padres exactos no se conocen.'},
  purpura:{n:'Purple Afghani',thc:18,y:28,d:4,r:45,c:'#9070b8',ind:95,hj:'#4c6c44',o:'Landrace · Afganistán, selección morada',h:'Índica delicada de montaña que se vuelve morada al final.'},
  citrus:{n:'Lemon Skunk',thc:18,y:40,d:3,r:70,c:'#c0dc50',ind:40,hj:'#6ba53e',o:'Selección cítrica de Skunk #1',h:'Dos plantas de Skunk #1 con olor a limón, cruzadas entre sí hasta fijarlo.'},
  kali:{n:'Kali Mist',thc:18,y:30,d:4,r:60,c:'#c4d878',ind:10,hj:'#82a73e',gen:1,o:'sativa asiática · ≈ origen incierto (padres sin publicar)',h:'Sativa de floración larga y efecto claro. Nunca se publicaron sus padres.'},
  cheese:{n:'Cheese',thc:17,y:40,d:2.5,r:75,c:'#b4c868',ind:60,hj:'#5ba33e',gen:2,o:'Fenotipo de Skunk #1 (Reino Unido)',h:'Una planta de Skunk #1 con olor a queso curado, guardada por esquejes durante años.'},
  calorange:{n:'California Orange',thc:16,y:36,d:3,r:70,c:'#d8b850',ind:40,hj:'#6ba53e',o:'Híbrido de California de los setenta',h:'Planta de aroma a naranja, conservada en California desde los setenta.'},
  chemdawg:{n:'Chemdawg',thc:22,y:34,d:3.5,r:60,c:'#8cb050',ind:45,hj:'#67a53e',o:'Híbrido de los noventa · ≈ origen incierto',h:'Olor químico, a gasóleo. Salió de unas semillas sin papeles a principios de los noventa.'},
  // landraces
  rif:{n:'Afghani',thc:16,y:38,d:3,r:85,c:'#88a050',ind:100,hj:'#3f7a34',o:'Landrace · montañas del norte de Afganistán'},
  hindu:{n:'Hindu Kush',thc:18,y:30,d:3,r:80,c:'#4a8a3a',ind:100,hj:'#3f7a34',o:'Landrace · cordillera del Hindu Kush, entre Afganistán y Pakistán'},
  acapulco:{n:'Acapulco Gold',thc:19,y:26,d:4.5,r:60,c:'#d0c048',ind:0,hj:'#8aa83e',o:'Landrace · costa de Guerrero, México'},
  malawi:{n:'Malawi Gold',thc:20,y:24,d:5,r:55,c:'#c8d068',ind:0,hj:'#8aa83e',o:'Landrace · sativa de África oriental, floración muy larga'},
  mich:{n:'Michoacán',thc:15,y:30,d:4,r:55,c:'#b8d860',ind:0,hj:'#8aa83e',o:'Landrace · altiplano de Michoacán, México',h:'Sativa de altura, espigada y cerebral. Aguanta bien el sol fuerte.'},
  punto:{n:'Punto Rojo',thc:16,y:30,d:4.5,r:45,c:'#b4a24c',ind:0,hj:'#8aa83e',o:'Landrace · cordillera de Colombia',h:'Sativa colombiana de pistilos rojizos. Floración larga y efecto eufórico.'},
  colgold:{n:'Colombian Gold',thc:16,y:30,d:4.5,r:55,c:'#ccc050',ind:0,hj:'#8aa83e',o:'Landrace · sierra de Santa Marta, Colombia',h:'La sativa dorada de la costa colombiana. Una de las tres madres de la Skunk #1.'},
  thai:{n:'Thai',thc:17,y:26,d:5,r:40,c:'#b0d468',ind:0,hj:'#8aa83e',o:'Landrace · selvas del norte de Tailandia',h:'Sativa esbelta, de floración larguísima y aroma especiado. Es madre de la Haze y de la Northern Lights.'},
  choco:{n:'Chocolate Thai',thc:16,y:24,d:5,r:40,c:'#9a8a50',ind:0,hj:'#8aa83e',o:'Landrace · Tailandia',h:'Sativa tailandesa de cogollo oscuro y aroma a cacao. Llegaba a Occidente atada en palitos.'},
  hthai:{n:'Highland Thai',thc:15,y:26,d:4.5,r:50,c:'#a8c870',ind:10,hj:'#82a73e',o:'Landrace · montañas del norte de Tailandia',h:'La Thai de altura: algo más corta y fresca que la de la selva.'},
  lao:{n:'Luang Prabang',thc:15,y:30,d:4.5,r:50,c:'#8a9a5c',ind:0,hj:'#8aa83e',o:'Landrace · montes del norte de Laos',h:'Sativa de las tierras altas de Laos. Muy vigorosa, con aroma dulce y a madera.'},
  chitral:{n:'Chitral Kush',thc:17,y:32,d:3,r:70,c:'#7a9a48',ind:100,hj:'#4a6e3c',o:'Landrace · valle de Chitral, Pakistán',h:'Índica de charas: su resina se frota a mano. Puede salir con tonos morados.'},
  nepal:{n:'Nepalese',thc:16,y:28,d:3.5,r:65,c:'#88906a',ind:50,hj:'#63a43e',o:'Landrace · colinas del Himalaya, Nepal',h:'Planta de altura, compacta y resinosa, con aroma a incienso.'},
  congo:{n:'Congolese',thc:16,y:32,d:3.5,r:55,c:'#b4d058',ind:0,hj:'#8aa83e',o:'Landrace · cuenca del Congo',h:'Sativa africana rápida para su tipo. Efecto claro y aroma a fruta ácida.'},
  lamb:{n:"Lamb's Bread",thc:16,y:30,d:4,r:60,c:'#a8d070',ind:0,hj:'#8aa83e',o:'Landrace · costa de Jamaica',h:'Sativa caribeña que tolera la brisa salina. Aroma dulce, tropical y marino.'},
  hawai:{n:'Hawaiian',thc:15,y:30,d:4,r:55,c:'#b8d870',ind:20,hj:'#7aa63e',o:'Landrace · islas de Hawái',h:'Sativa de isla, de aroma a fruta tropical. Crece en suelo volcánico.'},
  kif:{n:'Kif',thc:13,y:28,d:3,r:80,c:'#a8c060',ind:80,hj:'#4d913a',o:'Landrace · montañas del Rif, Marruecos',h:'La planta del hachís marroquí: seca, compacta y cargada de tricomas.'},
  beldia:{n:'Beldia',thc:12,y:24,d:3,r:75,c:'#98b45c',ind:80,hj:'#4d913a',o:'Landrace · Ketama, en el Rif',h:'La vieja landrace del Rif, casi desplazada por los híbridos. Rústica y aromática.'},
  oaxaca:{n:'Highland Oaxacan Gold',thc:15,y:32,d:4,r:65,c:'#b0a84a',ind:0,hj:'#8aa83e',o:'Landrace · sierra de Oaxaca, México',h:'Sativa de altura y suelo volcánico, vigorosa, con aroma ahumado y terroso.'},
  panama:{n:'Panama Red',thc:17,y:28,d:4.5,r:50,c:'#b8984c',ind:0,hj:'#8aa83e',o:'Landrace · istmo de Panamá',h:'La sativa legendaria de los setenta, veteada de rojo. Muy cerebral y de floración lenta.'},
  // 1.ª generación: cruces de landraces
  haze:{n:'Haze',thc:20,y:32,d:5,r:45,c:'#c8dc68',ind:10,hj:'#82a73e',gen:1,o:'Colombia × México × Tailandia (quizá India del Sur) · ≈ origen incierto',h:'Se fijó en California en los años setenta con sativas de Colombia, México y Tailandia. Se cruza Punto Rojo o Michoacán con Thai.'},
  nl:{n:'Northern Lights',thc:18,y:42,d:3,r:80,c:'#7cae4c',ind:90,hj:'#468637',gen:1,o:'Afghani, con algo de Thai · ≈ origen incierto',h:'Índica compacta y muy resinosa, fijada en los ochenta. En la mesa: Afghani × Thai.'},
  amanecer:{n:'Purple Thai',thc:18,y:28,d:4.5,r:50,c:'#9a74b8',ind:10,hj:'#82a73e',gen:1,o:'Chocolate Thai × Highland Oaxacan Gold',h:'Sativa morada de los setenta. Es la abuela de la Blueberry.'},
  sollimon:{n:'Trainwreck',thc:21,y:30,d:4,r:55,c:'#a8cc58',ind:35,hj:'#6fa53e',gen:1,o:'Mexicana × Thai × Afghani · ≈ origen incierto',h:'Una de las primeras grandes de California. En la mesa: Michoacán, Thai y Afghani.'},
  ak47:{n:'AK-47',thc:20,y:40,d:3,r:75,c:'#a0c858',ind:35,hj:'#6fa53e',gen:1,o:'Colombiana × mexicana × thai × afgana (1992)',h:'Cuatro landraces en una: rápida para ser tan sativa y muy fácil de cultivar.'},
  buddha:{n:'Laughing Buddha',thc:19,y:32,d:4,r:55,c:'#bcd870',ind:20,hj:'#7aa63e',gen:1,o:'Thai × Jamaicana',h:"Sativa alegre de Thai y Lamb's Bread. Aroma dulce y especiado."},
  cannalope:{n:'Cannalope Haze',thc:20,y:30,d:3.5,r:55,c:'#d0d878',ind:10,hj:'#82a73e',gen:1,o:'Haze × Michoacán',h:'Una Haze más rápida, con aroma a melón.'},
  afkush:{n:'Master Kush',thc:20,y:38,d:3,r:85,c:'#6e9a44',ind:100,hj:'#3f7a34',gen:1,o:'dos landraces del Hindu Kush · ≈ origen incierto',h:'Dos índicas de la cordillera juntas: compacta, resinosa y de floración corta. En la mesa: Hindu Kush × Chitral Kush.'},
  purpurah:{n:'Purple Kush',thc:22,y:32,d:3.5,r:70,c:'#7a5aa8',ind:100,hj:'#486640',gen:1,o:'Hindu Kush × Purple Afghani · ≈ origen incierto',h:'Índica pura morada, de efecto pesado.'},
  congopan:{n:'Congo × Panama',thc:18,y:28,d:4.5,r:50,c:'#b8c058',ind:0,hj:'#8aa83e',gen:1,o:'Congolese × Panama Red',h:'Dos sativas legendarias: la rapidez africana con el efecto de la Panama Red.'},
  malapan:{n:'Malawi × Panama',thc:20,y:26,d:5,r:50,c:'#c4b860',ind:0,hj:'#8aa83e',gen:1,o:'Malawi Gold × Panama Red',h:'Sativa pura de floración larguísima y efecto muy potente.'},
  malapck:{n:'Malawi × PCK',thc:19,y:32,d:4,r:60,c:'#a8b858',ind:40,hj:'#6ba53e',gen:1,o:'Malawi Gold × Chitral Kush (PCK)',h:'La Malawi domada con la índica de Chitral: florece antes y produce más.'},
  // 2.ª generación
  kushrif:{n:'Critical Mass',thc:21,y:40,d:3,r:85,c:'#8cbc4c',ind:80,hj:'#4d913a',gen:2,o:'Afghani × Skunk #1',h:'La madre es la Afghani: cogollos tan gordos que hay que sujetarlos.'},
  shiva:{n:'Shiva Skunk',thc:19,y:44,d:3,r:85,c:'#8cbc50',ind:80,hj:'#4d913a',gen:2,o:'Skunk #1 × Northern Lights',h:'Northern Lights con Skunk #1: robusta, rápida y muy productiva.'},
  nlhaze:{n:'NL5 × Haze',thc:21,y:34,d:4,r:60,c:'#b0cc68',ind:40,hj:'#6ba53e',gen:2,o:'Northern Lights × Haze',h:'La madre es la Northern Lights: la Haze con más cogollo y algo más rápida.'},
  neville:{n:"Neville's Haze",thc:22,y:30,d:4.5,r:50,c:'#c8dc80',ind:10,hj:'#82a73e',gen:2,o:'Haze × (NL5 × Haze)',h:'Tres cuartos de Haze: de las sativas más potentes y lentas que hay.'},
  silver:{n:'Silver Haze',thc:21,y:36,d:4.5,r:55,c:'#c0d880',ind:35,hj:'#6fa53e',gen:2,o:'Haze × Northern Lights · ≈ origen incierto',h:'La madre es la Haze: conserva el efecto y acorta la floración.'},
  chocolope:{n:'Chocolope',thc:21,y:32,d:4,r:55,c:'#a89c58',ind:10,hj:'#82a73e',gen:2,o:'Chocolate Thai × Cannalope Haze',h:'Sativa con aroma a cacao y café.'},
  orotrop:{n:'Pineapple Express',thc:21,y:38,d:3.5,r:60,c:'#c8d050',ind:40,hj:'#6ba53e',gen:2,o:'Trainwreck × Hawaiian · ≈ origen incierto',h:'Trainwreck con una sativa de Hawái: aroma a piña.'},
  brumaog:{n:'Tangie',thc:20,y:36,d:3.5,r:60,c:'#e0b848',ind:30,hj:'#72a63e',gen:2,o:'California Orange × Skunk #1',h:'La California Orange con Skunk #1: huele a mandarina.'},
  tormenta:{n:'Amnesia Haze',thc:26,y:36,d:4.5,r:65,c:'#bcd468',ind:20,hj:'#7aa63e',gen:2,o:'Haze + jamaicana + afgana o hawaiana + Laos · ≈ origen incierto',h:"Haze con Lamb's Bread, Luang Prabang y una índica (Afghani o Hawaiian). Muy potente."},
  // 3.ª generación
  leyenda:{n:'Jack Herer',thc:28,y:40,d:3.5,r:70,c:'#d8ecb0',ind:45,hj:'#6ba53e',gen:3,o:'Haze × (NL5 × Shiva Skunk) · LEGENDARIA',h:'Haze, Northern Lights y Shiva Skunk en una sola línea. Premiada como pocas en los noventa.'},
  ssh:{n:'Super Silver Haze',thc:23,y:40,d:4,r:70,c:'#c8e090',ind:20,hj:'#7aa63e',gen:3,o:'Skunk #1 × Northern Lights × Haze',h:'Haze, Northern Lights y Skunk #1 en una sola línea. Una de las sativas más premiadas de los noventa.'},
  nieblamor:{n:'Blue Dream',thc:22,y:34,d:4,r:55,c:'#80a8c0',ind:40,hj:'#5c9a48',gen:3,o:'Blueberry × Haze',h:'La Blueberry con una Haze: dulce y equilibrada.'},
  bluetx:{n:'Blue Cheese',thc:19,y:40,d:3,r:70,c:'#6a94b8',ind:75,hj:'#468650',gen:3,o:'Blueberry × Cheese',h:'La Cheese con el dulzor de la Blueberry.'},
  dragon:{n:'Sour Diesel',thc:27,y:36,d:4,r:60,c:'#90b448',ind:30,hj:'#6fa53e',gen:3,o:'Chemdawg × Super Skunk · ≈ origen incierto',h:'Olor a gasóleo agrio y efecto rápido. Una de las más buscadas.'},
  kali47:{n:'Kali 47',thc:21,y:36,d:3.5,r:65,c:'#b0cc68',ind:30,hj:'#72a63e',gen:3,o:'Kali Mist × AK-47',h:'La Kali Mist con la AK-47: sativa más rápida y productiva.'},
  reina:{n:'Critical Kali Mist',thc:21,y:42,d:3.5,r:75,c:'#98c058',ind:45,hj:'#5c9a48',gen:3,o:'Critical Mass × Kali Mist',h:'La producción de la Critical Mass con el efecto de la Kali Mist.'},
};
const DEX=Object.keys(STRAINS);
// forma del cogollo en los menús (cogollos-genoteca del atlas)
const TIPO_COGOLLO={dragon:'legendario',leyenda:'legendario'};
DEX.forEach(k=>{if(!TIPO_COGOLLO[k]){const i=STRAINS[k].ind;TIPO_COGOLLO[k]=i>=65?'indica':i<=35?'sativa':'hibrido';}});
// tipo genético (1.10): cuánto se parecen entre sí las plantas de una misma semilla. Cada planta tira su fenotipo al germinar
// (rollFeno, 09-cultivo): THC y gramos × (1 + σ·z), cada uno por su lado. Estrella si THC × gramos ≥ FENO_ESTRELLA; floja si
// ≤ FENO_FLOJO. Las de tienda llevan el suyo en TIPO_GEN; las que empiezan por «Landrace», landrace; las de receta y los
// híbridos propios salen de la mesa como F1-F3 (S.gen) y, estabilizadas, son líneas estables. uno = 1 estrella de cada N
// plantas (lo comprueba test-historia con 200.000 plantas por tipo). si: σ del % índica de cada planta (puntos), que le da la forma
// (portePlanta) y el tono de la hoja; una línea estable sale toda igual
const TIPO_GEN={ria:'estable',limon:'poli',txoko:'f1',niebla:'estable',mango:'estable',purpura:'estable',citrus:'estable',kali:'estable',cheese:'estable',calorange:'estable',chemdawg:'poli'};
const PADRES={};   // (1.11) el linaje va en o
const GENETICA={
  estable:{n:'Línea estable',sigma:.06,si:0,uno:16000,d:'fijada a lo largo de generaciones: casi todas las plantas salen iguales'},
  f1:{n:'Cruce F1',sigma:.07,si:3,uno:2000,d:'hijo directo de dos líneas estables: uniforme y con vigor híbrido'},
  F1:{n:'F1',sigma:.08,si:8,uno:500,d:'línea inestable, cosechas desiguales. Estabilízala en la mesa'},
  F2:{n:'F2',sigma:.12,si:15,uno:40,d:'línea inestable, la generación que más se separa. Estabilízala en la mesa'},
  F3:{n:'F3',sigma:.1,si:10,uno:100,d:'línea inestable, ya seleccionada. Estabilízala en la mesa'},
  landrace:{n:'Landrace',sigma:.1,si:10,uno:100,d:'población silvestre de su región: plantas variadas'},
  poli:{n:'Polihíbrido',sigma:.11,si:12,uno:60,d:'cruce de cruces: cada planta sale distinta'}};
const FENO_ESTRELLA=1.35,FENO_FLOJO=.75;
function tipoGen(id){const g=genDe(id);if(g<GEN_ESTABLE)return 'F'+g;if(TIPO_GEN[id])return TIPO_GEN[id];const s=getStrain(id);return s&&/^Landrace/.test(s.o)?'landrace':'estable';}
// recetas (1.11): el árbol de los híbridos clásicos por generaciones (docs/GENETICA.md). Cada receta es un conjunto de «hojas»:
// las variedades con nombre de las que sale. Un híbrido propio guarda las hojas de sus padres (S.custom[id].hojas), así que las
// de 3 o 4 padres se hacen en varios cruces: Skunk #1 = (Afghani × Colombian Gold) × Acapulco Gold, en cualquier orden que no
// pase antes por otra receta. RECETA_ORD (madre>padre): cuando el orden cambia la variedad (Afghani × Skunk #1 = Critical
// Mass; Skunk #1 × Afghani = Super Skunk)
const RECIPES={},RECETA_ORD={};
[[['rif','colgold','acapulco'],'ria'],[['punto','thai'],'haze'],[['mich','thai'],'haze'],[['punto','mich','thai'],'haze'],[['rif','thai'],'nl'],
 [['choco','oaxaca'],'amanecer'],[['mich','thai','rif'],'sollimon'],[['colgold','mich','thai','rif'],'ak47'],[['thai','lamb'],'buddha'],
 [['haze','mich'],'cannalope'],[['hindu','chitral'],'afkush'],[['hindu','purpura'],'purpurah'],[['congo','panama'],'congopan'],
 [['malawi','panama'],'malapan'],[['malawi','chitral'],'malapck'],
 [['amanecer','hthai','rif'],'niebla'],[['ria','nl'],'shiva'],[['haze','nlhaze'],'neville'],[['choco','cannalope'],'chocolope'],
 [['sollimon','hawai'],'orotrop'],[['calorange','ria'],'brumaog'],[['haze','lamb','rif','lao'],'tormenta'],[['haze','lamb','hawai','lao'],'tormenta'],
 [['haze','nl','shiva'],'leyenda'],[['ria','nl','haze'],'ssh'],[['silver','ria'],'ssh'],[['niebla','haze'],'nieblamor'],[['niebla','cheese'],'bluetx'],
 [['citrus','silver'],'limon'],[['chemdawg','txoko'],'dragon'],[['kali','ak47'],'kali47'],[['kushrif','kali'],'reina']]
 .forEach(([h,c])=>{RECIPES[h.slice().sort().join('+')]=c;});
[['ria','rif','txoko'],['rif','ria','kushrif'],['nl','haze','nlhaze'],['haze','nl','silver']].forEach(([a,b,c])=>{RECETA_ORD[a+'>'+b]=c;});
const hojasDe=id=>(S&&S.custom&&S.custom[id]&&S.custom[id].hojas)||[id];
const hojasCruce=(a,b)=>[...new Set(hojasDe(a).concat(hojasDe(b)))].sort();
// la variedad de receta que sale de madre a × padre b, o null
function recetaDe(a,b){return RECETA_ORD[a+'>'+b]||(a!==b&&RECIPES[hojasCruce(a,b).join('+')])||null;}
// estabilizar (1.9): lo que sale de un cruce nuevo es F1, una línea inestable (S.gen[id] = 1..3); cruzándola consigo misma
// en la mesa sube de generación y en la F4 queda fijada (se borra de S.gen). Landraces, tienda y partidas viejas: estables
const GEN_ESTABLE=4,genDe=id=>(S&&S.gen&&S.gen[id])||GEN_ESTABLE;
function getStrain(id){return STRAINS[id]||(S&&S.custom[id])||null;}
// % índica (ind: 0 sativa pura … 100 índica pura) y tono de la hoja (hj) de cada variedad: dan la forma y el color de la planta
// (porte, 09b-carpa). Las de STRAINS los traen con datos reales; los híbridos propios, de sus padres (crossResult); los de partidas
// viejas, de sus días de floración. tonoHoja: la sativa, clara y amarillenta; la índica, oscura (la Skunk #1, 65 %, es la paleta A)
const tonoHoja=i=>i<=65?mix('#8aa83e','#57a33e',i/65):mix('#57a33e','#3f7a34',(i-65)/35);
const indDe=sid=>{const s=getStrain(sid)||{d:3.5};return s.ind!=null?s.ind:s.d<=3?75:s.d>=4.5?20:50;};
const hojaDe=sid=>{const s=getStrain(sid);return s&&s.hj||tonoHoja(indDe(sid));};
// a: la madre, b: el padre
function crossResult(a,b){
  const rc=recetaDe(a,b);if(rc)return rc;
  const key=[a,b].sort().join('+');
  const id='x'+hashStr(key).toString(36);
  if(!S.custom[id]){
    const A=getStrain(a),B=getStrain(b),R=rngSeed(hashStr(key));
    const w=s=>s.n.split(' ').filter(p=>!p.startsWith('#'));const wa=w(A),wb=w(B);
    const usado=n=>n===A.n||n===B.n||DEX.some(k=>STRAINS[k].n===n)||Object.values(S.custom).some(c=>c.n===n);
    let name=wa[0]+' '+wb[wb.length-1];if(wa[0]===wb[wb.length-1]||usado(name))name=wb[0]+' '+wa[wa.length-1];
    if(usado(name))name=A.n+' × '+B.n;
    if(usado(name))name+=' F'+(2+Math.floor(R()*7));
    S.custom[id]={n:name,thc:Math.min(33,Math.round(((A.thc+B.thc)/2+R()*3.5-1.5)*10)/10),y:Math.round((A.y+B.y)/2+R()*8-4),
      d:Math.round(((A.d+B.d)/2+R()*.6-.3)*2)/2,r:clamp(Math.round((A.r+B.r)/2+R()*10-5),20,95),o:A.n+' × '+B.n+' · híbrido propio'};
    // de la madre (a) hereda el m % (30-70) y del padre el resto: el % índica, el tono de la hoja y el color del cogollo
    const m=30+Math.floor(R()*41),C=S.custom[id];
    Object.assign(C,{m,ma:a,pa:b,hojas:hojasCruce(a,b),ind:Math.round((m*indDe(a)+(100-m)*indDe(b))/100),hj:mix(hojaDe(b),hojaDe(a),m/100),c:mix(B.c,A.c,m/100)});
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
  // la comarca (1.10): un vecino en cada sitio, con el arte de una familia de clientes (id: look:clienteN del atlas)
  vecina:{id:'cliente6',skin:'#f6c8a0',hair:'#d8c070',style:'bun',shirt:'#a060c0',pants:'#4a6aa8'},
  excursionista:{id:'cliente1',skin:'#e8b088',hair:'#5a3a24',style:'short',shirt:'#4a8ad0',pants:'#5a5a64'},
  turista:{id:'cliente3',skin:'#f0d0b8',hair:'#c48a3a',style:'cap',hat:'#e8d8a0',hat2:'#c8b880',shirt:'#40a0a0',pants:'#c8b080'},
  obrero:{id:'cliente2',skin:'#d49a74',hair:'#1a1a1a',style:'short',shirt:'#f08a40',shirt2:'#6a6a70',pants:'#3a3a44'},
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
  ext:{label:'CATADOR',mult:1,g:[1,3],greet:['¿Tienes rosin? Me han dicho que prensas tú mismo.','Busco extracción sin disolventes. Rosin, nada de BHO.']},   // solo rosin (1.10)
};


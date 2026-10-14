/* =========================================================
   DATOS: variedades, recetas, personajes
   ========================================================= */
// Variedades reales (nombres de uso común entre cultivadores; ningún banco de semillas, criador ni persona). Los ids internos
// son los de las primeras versiones para no romper partidas guardadas (1.11: algunos cambian de variedad). c = tono del cogollo.
// h = historia (Genoteca). gen (1.11): generación del árbol de híbridos clásicos (1.ª a 4.ª); «≈ origen incierto» en o
// cuando los padres no están documentados. Las landraces salen del catálogo de Strainmon (src/species.js), con su nombre real;
// las de 1.24 (India del Sur, Líbano, Brasil y Sudáfrica), de las regiones clásicas, con su forma de planta. Van al final para no
// cambiar el número de las demás en la Genoteca.
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
  // 1.24: más landraces (del banco de semillas) y sus cruces
  kerala:{n:'Kerala',thc:16,y:28,d:5,r:50,c:'#b8cc60',ind:10,hj:'#82a73e',o:'Landrace · sierras de Kerala, India del Sur',h:'Sativa de la India del Sur: tronco recio, hasta tres metros y ramas laterales como las de un helecho. Flores pequeñas, curvadas y muy resinosas, de aroma especiado.'},
  libano:{n:'Lebanese',thc:14,y:30,d:3,r:75,c:'#a4b45c',ind:85,hj:'#4f9a3c',o:'Landrace · valle de la Bekaa, Líbano',h:'La planta del hachís libanés: baja, de tallos finos y pocas ramas, hoja ancha de verde medio y cogollo resinoso con bastante hoja. Efecto narcótico.'},
  mangarosa:{n:'Manga Rosa',thc:15,y:30,d:4.5,r:55,c:'#c4c060',ind:5,hj:'#86a83e',o:'Landrace · nordeste de Brasil',h:'Sativa brasileña de cogollo largo y pistilos rosados, con aroma a fruta tropical.'},
  durban:{n:'Durban Poison',thc:18,y:34,d:3.5,r:65,c:'#b4d060',ind:0,hj:'#8aa83e',o:'Landrace · puerto de Durban, Sudáfrica',h:'Sativa sudafricana, rápida para su tipo y muy resinosa. Aroma dulce, a anís, y efecto claro.'},
  ww:{n:'White Widow',thc:20,y:40,d:3.5,r:70,c:'#e4eed0',ind:60,hj:'#5ba33e',gen:1,o:'sativa de Brasil × planta resinosa del sur de la India · ≈ origen incierto',h:'Se cubre de tricomas hasta verse blanca. Arrasó a mediados de los noventa. Su padre fue una índica resinosa del sur de la India sin documentar, por eso sale más índica que las sativas de la mesa: Manga Rosa × Kerala.'},
  purplehaze:{n:'Purple Haze',thc:19,y:30,d:4.5,r:50,c:'#a07cc0',ind:15,hj:'#7ea63e',gen:2,o:'Purple Thai × Haze · ≈ origen incierto',h:'Una Haze morada: el efecto eléctrico de la Haze con el color de la Purple Thai.'},
  whiterussian:{n:'White Russian',thc:22,y:40,d:3.5,r:70,c:'#dce8c8',ind:60,hj:'#5ba33e',gen:2,o:'White Widow × AK-47',h:'La White Widow con la AK-47: todavía más resina y floración corta. Premiada a mediados de los noventa.'},
  bluewidow:{n:'Blue Widow',thc:19,y:40,d:3.5,r:65,c:'#a8c0d8',ind:65,hj:'#57a33e',gen:3,o:'Blueberry × White Widow',h:'La White Widow con el dulzor y el azul de la Blueberry.'},
  superlemon:{n:'Super Lemon Haze',thc:23,y:38,d:4,r:65,c:'#dce870',ind:30,hj:'#72a63e',gen:4,o:'Lemon Skunk × Super Silver Haze',h:'Limón y escarcha: la Super Silver Haze con la Lemon Skunk. Campeona dos años seguidos a finales de los 2000.'},
  // 1.26: más landraces (del banco de semillas) y más cruces clásicos, todos con su linaje publicado (≈ si no está claro)
  swazi:{n:'Swazi Gold',thc:16,y:30,d:4,r:60,c:'#d4c058',ind:10,hj:'#82a73e',o:'Landrace · montes de Esuatini (Suazilandia)',h:'Sativa del sur de África, de cogollo dorado y aroma cítrico. Se cultiva al aire libre en los montes desde hace generaciones.'},
  zamal:{n:'Zamal',thc:15,y:26,d:5,r:50,c:'#a8cc68',ind:0,hj:'#8aa83e',o:'Landrace · isla de la Reunión',h:'Sativa de isla, altísima y de floración larguísima, con aroma a incienso y madera.'},
  malana:{n:'Malana',thc:17,y:26,d:3.5,r:70,c:'#7a8a50',ind:70,hj:'#549d3d',o:'Landrace · valle de Parvati, Himachal Pradesh, India',h:'La planta del charas del Himalaya indio: su resina se frota a mano en los bancales de las aldeas.'},
  kashmir:{n:'Kashmiri',thc:15,y:28,d:3,r:75,c:'#6e8a48',ind:85,hj:'#498c38',o:'Landrace · valle de Cachemira',h:'Índica de altura, baja y compacta, de hoja ancha y oscura. Aguanta el frío de los valles.'},
  vietblack:{n:'Vietnamese Black',thc:15,y:30,d:5,r:55,c:'#6a7a4a',ind:20,hj:'#7aa63e',o:'Landrace · montes de Vietnam',h:'Sativa del sudeste asiático de cogollo oscuro, casi negro al final, y aroma a especia y tierra.'},
  etiopia:{n:'Ethiopian Highland',thc:14,y:26,d:4,r:60,c:'#b0c060',ind:10,hj:'#82a73e',o:'Landrace · tierras altas de Etiopía',h:'Sativa africana de altura: florece antes que las de la costa y huele a fruta y especias.'},
  chronic:{n:'Chronic',thc:20,y:48,d:3.5,r:80,c:'#9cc858',ind:70,hj:'#549d3d',gen:2,o:'Skunk #1 × Northern Lights × AK-47',h:'Índica de mucha producción: la Skunk #1 y la Northern Lights con la AK-47. Cogollos grandes sin perder potencia.'},
  whiterhino:{n:'White Rhino',thc:20,y:44,d:3.5,r:80,c:'#d8e4c4',ind:80,hj:'#4d913a',gen:2,o:'White Widow × índica norteamericana · ≈ origen incierto',h:'La White Widow con una índica de Norteamérica sin documentar: más baja, más pesada y de cogollo más denso. En la mesa, con Afghani.'},
  whiteshark:{n:'White Shark',thc:19,y:42,d:3.5,r:75,c:'#d0e0cc',ind:75,hj:'#50973b',gen:3,o:'Super Skunk × brasileña × India del Sur',h:'La Super Skunk con las dos madres de la White Widow: blanca de resina, rápida y aromática.'},
  hawaisnow:{n:'Hawaiian Snow',thc:22,y:32,d:5,r:50,c:'#d4ecc8',ind:10,hj:'#82a73e',gen:3,o:"Hawaiian Haze × Neville's Haze × Haze",h:'Tres Haze y una sativa de Hawái: altísima, lenta y de efecto muy claro.'},
  jackflash:{n:'Jack Flash',thc:21,y:40,d:3.5,r:65,c:'#c4dc88',ind:45,hj:'#67a53e',gen:4,o:'Jack Herer × Super Skunk × Haze',h:'La Jack Herer con más Haze y la Super Skunk: algo más rápida y productiva.'},
  jack47:{n:'Jack 47',thc:21,y:40,d:3.5,r:70,c:'#bcd47c',ind:40,hj:'#6ba53e',gen:4,o:'Jack Herer × AK-47',h:'La Jack Herer con la AK-47: más fácil de cultivar y de floración más corta.'},
  sourtangie:{n:'Sour Tangie',thc:23,y:36,d:4,r:60,c:'#d0b848',ind:20,hj:'#7aa63e',gen:4,o:'Sour Diesel × Tangie',h:'El gasóleo agrio de la Sour Diesel con la mandarina de la Tangie.'},
  ice:{n:'Ice',thc:20,y:44,d:3.5,r:80,c:'#c8dccc',ind:80,hj:'#4d913a',gen:3,o:'Afghani × Northern Lights × Shiva Skunk',h:'Índica tan cargada de resina que parece helada: de las preferidas para las extracciones. Rápida y fácil.'},
  nlbigbud:{n:'NL × Big Bud',thc:18,y:50,d:3,r:80,c:'#a4c050',ind:85,hj:'#498c38',gen:4,o:'Northern Lights × Big Bud',h:'La Northern Lights con el tamaño de la Big Bud: de las que más producen.'},
  criticaljack:{n:'Critical Jack',thc:21,y:44,d:3.5,r:70,c:'#bcd870',ind:40,hj:'#6ba53e',gen:4,o:'Critical × Jack Herer · ≈ origen incierto',h:'La producción de una Critical con el efecto de la Jack Herer. Qué Critical se usó no está claro; en la mesa, la Critical Mass.'},
  critical47:{n:'Critical 47',thc:20,y:44,d:3,r:75,c:'#a8cc60',ind:55,hj:'#5fa43e',gen:3,o:'Critical × AK-47 · ≈ origen incierto',h:'Una Critical con la AK-47: corta, productiva y fácil. En la mesa, con la Critical Mass.'},
  criticalcheese:{n:'Critical Cheese',thc:19,y:44,d:3,r:75,c:'#b0c464',ind:70,hj:'#549d3d',gen:3,o:'Critical × Cheese · ≈ origen incierto',h:'Una Critical con el olor a queso de la Cheese. En la mesa, con la Critical Mass.'},
  nlblue:{n:'Northern Light Blue',thc:19,y:40,d:3,r:75,c:'#7aa0b8',ind:85,hj:'#498c38',gen:3,o:'Northern Lights × Blueberry',h:'La Northern Lights con el dulzor y el azul de la Blueberry.'},
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
 [['citrus','silver'],'limon'],[['chemdawg','txoko'],'dragon'],[['kali','ak47'],'kali47'],[['kushrif','kali'],'reina'],
 [['mangarosa','kerala'],'ww'],[['punto','mich','thai','kerala'],'haze'],[['amanecer','haze'],'purplehaze'],[['ww','ak47'],'whiterussian'],
 [['niebla','ww'],'bluewidow'],[['citrus','ssh'],'superlemon'],
 // 1.26
 [['ria','nl','ak47'],'chronic'],[['shiva','ak47'],'chronic'],[['ww','rif'],'whiterhino'],[['txoko','ww'],'whiteshark'],[['txoko','mangarosa','kerala'],'whiteshark'],
 [['hawai','haze','neville'],'hawaisnow'],[['leyenda','txoko','haze'],'jackflash'],[['leyenda','ak47'],'jack47'],[['dragon','brumaog'],'sourtangie'],
 [['rif','nl','ria'],'ice'],[['rif','shiva'],'ice'],[['nl','mango'],'nlbigbud'],[['kushrif','leyenda'],'criticaljack'],[['kushrif','ak47'],'critical47'],
 [['kushrif','cheese'],'criticalcheese'],[['nl','niebla'],'nlblue']]
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
// nombre corto de un cruce (1.11): dos palabras de los padres (la 1.ª de uno y la última del otro antes que las demás), de hasta
// NOM_MAX letras y sin repetir otra variedad (ni cambiando mayúsculas); si no queda ninguna, la más corta con « #2», « #3»… Nunca «A × B»: al cruzar cruces
// se hacía larguísimo. El orden de las parejas, por largo y luego por cómo salen (igual en Godot, que no ordena estable)
const NOM_MAX=20;
const palabras=n=>n.split(' ').filter(p=>p&&p!=='×'&&!p.startsWith('#')&&!/^F\d+$/.test(p));
function nombreCruce(wa,wb,usado){
  const c=[],add=n=>{if(!c.includes(n))c.push(n);},r=[];
  if(wa.length&&wb.length){add(wa[0]+' '+wb[wb.length-1]);add(wb[0]+' '+wa[wa.length-1]);}
  for(const x of wa)for(const y of wb)if(x!==y)r.push(x+' '+y,y+' '+x);
  r.map((n,i)=>[n,i]).sort((p,q)=>p[0].length-q[0].length||p[1]-q[1]).forEach(([n])=>add(n));
  const ok=c.filter(n=>{const [x,y]=n.split(' ');return x!==y&&n.length<=NOM_MAX;});
  for(const n of ok)if(!usado(n))return n;
  const base=ok.find(n=>n.length<=NOM_MAX-4)||(wa[0]||wb[0]||'Cruce').slice(0,NOM_MAX-4);
  for(let k=2;;k++){const n=base.slice(0,NOM_MAX-2-String(k).length).trimEnd()+' #'+k;if(!usado(n))return n;}
}
function crossResult(a,b){
  const rc=recetaDe(a,b);if(rc)return rc;
  const key=[a,b].sort().join('+');
  const id='x'+hashStr(key).toString(36);
  if(!S.custom[id]){
    const A=getStrain(a),B=getStrain(b),R=rngSeed(hashStr(key));
    const l=n=>n.toLowerCase(),name=nombreCruce(palabras(A.n),palabras(B.n),n=>l(n)===l(A.n)||l(n)===l(B.n)||DEX.some(k=>l(STRAINS[k].n)===l(n))||Object.values(S.custom).some(c=>l(c.n)===l(n)));
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
  julen:{id:'julen',skin:'#e8b088',hair:'#7a5236',style:'long',beard:1,shirt:'#c8642c',pants:'#46557a'},   // el hijo de Kiko (1.23)
  delroy:{id:'delroy',skin:'#8a5a3c',hair:'#b4b0a8',style:'long',beard:'#b4b0a8',shirt:'#e8e0c8',pants:'#4a4c56'},   // el «tío» jamaicano (1.32)
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
  // los sitios con función (1.14): también con el arte de una familia de clientes (o el de Patxi, el molinero)
  ane:{id:'cliente4',skin:'#f0c0a0',hair:'#2a1a14',style:'long',shirt:'#5ab868',pants:'#3a3a44'},
  nerea:{id:'cliente5',skin:'#e8b088',hair:'#8a2a1a',style:'bun',shirt:'#e0b84a',pants:'#24346a'},
  bixente:{id:'cliente6',skin:'#d49a74',hair:'#5a3a24',style:'short',beard:1,shirt:'#7a5a3a',pants:'#3a3a44'},
  miren:{id:'miren',skin:'#f0c8a8',hair:'#b8b8c0',style:'bun',shirt:'#4a8a5a',pants:'#4a3a3a'},
  andoni:{id:'oldman',skin:'#e8b894',hair:'#d8d8d8',style:'bald',beard:'#d8d8d8',shirt:'#b8a070',pants:'#5a5048'},
  ibarbitarra:{id:'cliente1',skin:'#f0d0b8',hair:'#1a1a1a',style:'short',shirt:'#3a3a48',pants:'#2a2a30',glasses:1},
  portero:{id:'cliente2',skin:'#b07850',hair:'#1a1a1a',style:'bald',beard:1,shirt:'#2a2a30',pants:'#2a2a30'},   // los clubs (1.15)
  arrieta:{id:'cliente1',skin:'#d8a880',hair:'#6a6a70',style:'short',stache:'#6a6a70',shirt:'#5a6a7a',pants:'#3a3a44'},   // el de la nave (1.19)
  txomin:{id:'oldman',skin:'#e0aa84',hair:'#c8c8c8',style:'cap',hat:'#5a4a3a',hat2:'#3a2a20',shirt:'#6a7a4a',pants:'#4a4038'},   // el setero de la Kale Zaharra (1.20)
  portera:{id:'cliente5',skin:'#f6c8a0',hair:'#8a2a1a',style:'long',shirt:'#2a2a30',pants:'#3a3a44',glasses:1},
  // los locales (1.30, 11j-locales): los socios y los del billar de los clubs, los de la nave, y la gente de GAUA
  socio:{id:'cliente3',skin:'#e8b088',hair:'#5a3a24',style:'short',beard:1,shirt:'#5a7a4a',pants:'#3a3a44'},
  socia:{id:'cliente6',skin:'#f0c8a8',hair:'#2a1a14',style:'long',shirt:'#c04870',pants:'#2a2a30'},
  billarista:{id:'cliente1',skin:'#d49a74',hair:'#1a1a1a',style:'short',stache:'#1a1a1a',shirt:'#e0e0e8',pants:'#2a2a30'},
  billarista2:{id:'cliente4',skin:'#f6c8a0',hair:'#8a2a1a',style:'bun',shirt:'#3a3a48',pants:'#2a2a30'},
  navero1:{id:'cliente1',skin:'#e8b088',hair:'#5a3a24',style:'short',shirt:'#5ab868',pants:'#3a3a44'},
  navero2:{id:'cliente2',skin:'#d49a74',hair:'#1a1a1a',style:'short',shirt:'#5ab868',shirt2:'#6a6a70',pants:'#3a3a44'},
  navero3:{id:'cliente4',skin:'#f0c0a0',hair:'#2a1a14',style:'long',shirt:'#5ab868',pants:'#3a3a44'},
  navero4:{id:'cliente6',skin:'#d49a74',hair:'#5a3a24',style:'short',beard:1,shirt:'#5ab868',pants:'#3a3a44'},
  gorila:{id:'cliente2',skin:'#b07850',hair:'#1a1a1a',style:'bald',shirt:'#101014',pants:'#101014'},
  camarera:{id:'cliente5',skin:'#f0d0b8',hair:'#1a1a1a',style:'bun',shirt:'#101014',pants:'#101014'},
  dj:{id:'cliente3',skin:'#e8b088',hair:'#c48a3a',style:'cap',hat:'#c04870',hat2:'#101014',shirt:'#3a3a48',pants:'#2a2a30'},
  rrpp:{id:'cliente4',skin:'#f6c8a0',hair:'#d8c070',style:'long',shirt:'#a060c0',pants:'#101014'},
  baila1:{id:'cliente3',skin:'#f0d0b8',hair:'#2a1a14',style:'curly',shirt:'#40a0a0',pants:'#36466e'},
  baila2:{id:'cliente6',skin:'#b07850',hair:'#1a1a1a',style:'long',shirt:'#f0c838',pants:'#2a2a30'},
  baila3:{id:'cliente1',skin:'#e8b088',hair:'#8a2a1a',style:'short',shirt:'#e65040',pants:'#36466e'},
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
  vip:{label:'VIP',mult:1.6,g:[10,25],greet:['Me ha dicho la RRPP de GAUA que tienes lo mejor.','Para el fin de semana. Que sea lo bueno, el precio da igual.']},   // el reservado de GAUA (1.30)
  ext:{label:'CATADOR',mult:1,g:[1,3],greet:['¿Tienes rosin? Me han dicho que prensas tú mismo.','Busco extracción sin disolventes. Rosin, nada de BHO.']},   // solo rosin (1.10)
};


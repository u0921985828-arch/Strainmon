using System.Collections.Generic;
using UnityEngine;

namespace BilboCity {

/// <summary>
/// El callejero: qué calle es cada casilla.
///
/// Andabas por «Abando» y ya está. Ahora el HUD dice también por qué calle vas, y son las
/// calles de Bilbao: la Gran Vía, Urquijo, Autonomía, Zabalbide, Lehendakari Agirre.
///
/// De dónde salen, y qué NO son. El plano municipal trae su callejero rotulado, pero el
/// PDF no entra en el repositorio —esa es una norma nuestra— y el extractor solo se queda
/// con la geometría. Así que estas calles no están leídas de un rótulo: están puestas por
/// su trazado, que es el hecho geográfico que sí se puede afirmar. La Gran Vía va de Moyúa
/// a la Circular; Urquijo, de la Circular a San Mamés; Zabalbide, del Casco a Santutxu.
///
/// Y por eso las coordenadas son referencias, no medidas: lo que manda es la calle de
/// verdad. Cada calle se apunta a unos cuantos puntos de paso y el juego busca el camino
/// que los une, así que si un punto está seis casillas corrido, la calle sigue cayendo en
/// la calle que va de un sitio al otro — que es exactamente lo que identifica a una calle.
/// Lo que no se puede afirmar no se nombra: las Siete Calles miden dos casillas de ancho
/// cada una y a 5,16 m por casilla no caben, así que del Casco solo van Bidebarrieta,
/// Iturribide y la Ribera.
/// </summary>
public static class Callejero {

    public class Calle { public string Nombre; public int[,] Puntos; }

    static Calle C(string nombre, params int[] xy) {
        var p = new int[xy.Length/2, 2];
        for (int i = 0; i < xy.Length/2; i++) { p[i,0] = xy[i*2]; p[i,1] = xy[i*2+1]; }
        return new Calle { Nombre = nombre, Puntos = p };
    }

    // Esta tabla la escribe el extractor: `python3 herramientas/plano/extraer.py plano.pdf`
    // saca los rótulos de calle del plano y la reemplaza entera. Lo de abajo es lo que hay
    // hasta que se vuelva a extraer — los ejes principales, puestos por su trazado. NO se
    // edita a mano esperando que sobreviva: la próxima extracción lo pisa.
    /*<<<CALLES*/
    public static readonly Calle[] Calles = {
        C("Abaitua Eulalia", 1300,337, 1301,361),
        C("Abandoibarra", 575,275, 621,213),
        C("Abaro", 23,284, 24,284),
        C("Abasolo", 882,71, 896,75),
        C("Acebal Idígoras", 878,246, 879,246),
        C("Agarre", 881,479, 882,479),
        C("Aguirre Máximo", 682,336, 681,287),
        C("Aixeona", 1249,117, 1250,117),
        C("Ajuriaguerra Juan", 742,247, 676,253),
        C("Alazne López Etxebarria", 86,333, 87,333),
        C("Albia", 828,277, 829,277),
        C("Aldamiz Monte", 926,96, 927,96),
        C("Aldapeta", 57,335, 71,355),
        C("Alicante", 1184,374, 1185,374),
        C("Alicia Aretxabaleta", 141,259, 142,259),
        C("Almería", 1187,380, 1188,380),
        C("Altamira", 233,511, 306,504, 321,534),
        C("Alzaga Toribio", 221,153, 222,153),
        C("Alzola Pablo de", 297,363, 298,363),
        C("Amistad", 884,295, 885,295),
        C("Amparo", 832,447, 833,447),
        C("Anboto", 652,654, 653,654),
        C("Andalucía", 103,89, 104,89),
        C("Andramaría de Begoña", 1070,173, 1071,173),
        C("Aoiz / Agoitz", 206,161, 207,161),
        C("Araba", 452,239, 453,239),
        C("Arabella", 1098,181, 1086,159),
        C("Aragón", 127,93, 107,113),
        C("Aralar", 910,128, 911,128),
        C("Aranekobidea", 339,160, 378,172),
        C("Aranzadi Telesforo", 747,349, 748,349),
        C("Arbidea", 1178,304, 1180,298),
        C("Arbieto", 771,325, 772,325),
        C("Arbolagana", 306,202, 307,202),
        C("Arbolantxa", 813,249, 814,249),
        C("Arbolantxabidea", 1337,122, 1346,99, 1409,97),
        C("Arechavaleta", 654,408, 655,408),
        C("Areilza Doctor", 626,378, 627,378),
        C("Arenal", 925,292, 926,292),
        C("Arenal Celestino Ma del", 273,174, 274,174),
        C("Aresti Gabriel", 1204,222, 1297,237),
        C("Arnotegi", 856,430, 857,430),
        C("Arregui Angela", 1334,194, 1335,194),
        C("Arriaga", 909,320, 910,320),
        C("Arriquíbar", 735,386, 736,386),
        C("Arsuaga", 1162,364, 1163,364),
        C("Artalandio", 1284,260, 1285,260),
        C("Artapeta", 909,663, 910,663),
        C("Artatzamina", 796,124, 797,124),
        C("Artazubekoa", 742,640, 743,640),
        C("Artazubidea", 721,658, 722,658),
        C("Artazuriña", 1174,288, 1218,282),
        C("Artsenalbidea", 38,232, 53,235),
        C("Artxanda", 821,76, 759,13),
        C("Artxanda-La Salve", 578,123, 690,95, 748,151, 755,139),
        C("Artxanda-Santo Domingo", 1004,3, 1005,3),
        C("Askao", 957,307, 958,307),
        C("Askatasuna", 887,542, 957,499, 1018,505),
        C("Astarloa", 787,321, 785,296),
        C("Astillero", 30,300, 47,277, 55,195),
        C("Asturias", 155,86, 118,123),
        C("Asunción", 784,67, 785,67),
        C("Atxetabidea", 1113,130, 1089,167),
        C("Atxuri", 1019,436, 1009,427),
        C("Auntzetxeta", 450,543, 451,543),
        C("Aurrekoetxea", 1083,315, 1084,315),
        C("Autonomía", 585,501, 658,476, 761,442),
        C("Ayuntamiento del", 885,243, 895,217),
        C("Azkaraibidea", 1390,228, 1391,228),
        C("Azpeitia Sancho de", 541,228, 542,228),
        C("Azurleku", 1227,440, 1228,440),
        C("Badajoz", 170,86, 171,86),
        C("Bailén", 877,353, 872,377),
        C("Baiona", 804,513, 805,513),
        C("Bakio", 963,102, 964,102),
        C("Baldezate Filomena", 701,650, 702,650),
        C("Ballets Olaeta", 416,331, 417,331),
        C("Barinaga", 24,214, 25,214),
        C("Barraincúa", 719,235, 720,235),
        C("Barrenkalebarrena", 924,377, 925,377),
        C("Barroeta Aldamar", 862,259, 863,259),
        C("Basarrate", 1197,422, 1198,422),
        C("Basterra Ramón", 589,326, 590,326),
        C("Bastida Ricardo Arqto.", 1148,376, 1149,376),
        C("Basurtu-Kastrexana", 487,504, 392,504),
        C("Basurtubekoa", 514,524, 515,524),
        C("Begoñalde", 1051,208, 1052,208),
        C("Begoñazpi", 1193,157, 1189,139),
        C("Benidorm", 289,194, 277,232),
        C("Benita Asas", 168,135, 169,135),
        C("Bentazarra", 422,515, 423,515),
        C("Berastegui", 842,292, 843,292),
        C("Bergara", 802,542, 803,542),
        C("Bergé y Salcedo", 671,274, 672,274),
        C("Berriz", 402,19, 403,19),
        C("Berrizbidea", 392,133, 393,133),
        C("Bertendona", 799,346, 795,353),
        C("Bidarte", 404,217, 405,217),
        C("Bidebarrieta", 931,347, 915,337),
        C("Bidegain", 87,316, 88,316),
        C("Bilbao Izaurieta", 157,262, 158,262),
        C("Bilbao La Vieja", 965,424, 966,424),
        C("Bilbao-Galdakao", 1244,456, 1295,443),
        C("Bilintx", 1035,263, 1036,263),
        C("Birjinetxe", 1236,260, 1178,200),
        C("Bizkaia", 723,372, 724,372),
        C("Bizkargi", 685,658, 686,658),
        C("Bolivar Elorduy Julián", 1104,384, 1105,384),
        C("Bolivar Simón", 590,428, 610,426),
        C("Bonaparte Luis Luciano", 1178,440, 1179,440),
        C("Botica Vieja", 585,206, 517,260),
        C("Briñas Luis", 536,449, 538,377),
        C("Buen Pastor", 984,146, 985,146),
        C("Buenavista", 505,167, 506,138),
        C("Buenos Aires", 875,280, 876,280),
        C("Burgos", 455,245, 456,245),
        C("Butrón", 112,338, 113,338),
        C("Campo Volantín", 775,170, 857,208),
        C("Campuzano Emilio", 1009,404, 1010,404),
        C("Cantalojas", 893,432, 894,432),
        C("Cantarranas", 977,437, 978,437),
        C("Cantera", 867,431, 890,447),
        C("Cantábria", 143,71, 144,71),
        C("Canárias Islas", 189,196, 205,213),
        C("Capuchinos de Basurtu", 468,434, 469,434),
        C("Capuchinos de Deustu", 437,181, 438,181),
        C("Caramelo Monte", 549,630, 550,630),
        C("Careaga Plácido", 422,234, 423,234),
        C("Cargueras", 346,379, 347,379),
        C("Casals Pau", 1305,177, 1306,177),
        C("Caserío Garro", 384,182, 385,182),
        C("Caserío Landaburu", 1137,390, 1138,390),
        C("Casilla", 653,509, 641,492),
        C("Castaños", 823,155, 824,155),
        C("Castillo General", 870,403, 871,403),
        C("Catalunya", 127,67, 128,67),
        C("Caños de los", 773,493, 774,493),
        C("Chávarri Victor", 560,404, 561,404),
        C("Circo Amateur del Club Deportivo", 1245,411, 1246,411),
        C("Circular", 868,304, 869,304),
        C("Ciudad Jardín", 779,105, 799,86, 860,113),
        C("Clara Campoamor", 13,217, 14,217),
        C("Cocherito de Bilbao", 1210,363, 1237,429),
        C("Colón de Larreategui", 731,291, 813,283),
        C("Concepción", 861,443, 862,459, 875,461),
        C("Concordia", 1161,406, 1162,406),
        C("Constantino Tenor", 864,478, 865,478),
        C("Consulado de Bilbao", 972,409, 973,409),
        C("Convivencia de la", 798,217, 799,217),
        C("Cordelería", 33,250, 34,250),
        C("Corredor del Cadagua", 119,412, 138,384),
        C("Correo", 939,331, 940,331),
        C("Cortes Pedro Médico Municipal", 861,143, 862,143),
        C("Cosa Juan de la", 1161,416, 1162,416),
        C("Costa", 774,414, 775,414),
        C("Cristo del", 902,175, 903,175),
        C("Cáceres", 173,83, 174,83),
        C("Diputación", 772,304, 773,304),
        C("Dique", 456,375, 457,375),
        C("Don Diego Berguices", 1287,154, 1288,154),
        C("Donostia-San Sebastián", 953,525, 954,525),
        C("Durrio Francisco, Escultor", 248,180, 249,180),
        C("Echaniz Bombero", 687,442, 688,442),
        C("Echave Alfredo de", 1287,346, 1287,367),
        C("Echevarrieta Cosme", 757,227, 758,227),
        C("Echevarriía “Camarón”Julián", 965,383, 966,383),
        C("Egaña", 693,439, 749,428),
        C("Egileor", 438,145, 439,145),
        C("Eguillor Pedro", 764,343, 765,343),
        C("Eguía General", 575,468, 646,460),
        C("El Canal", 188,228, 189,228),
        C("Elcano", 688,283, 743,330, 795,382),
        C("Elexabarri", 640,551, 641,551),
        C("Elizalde", 1062,256, 1063,256),
        C("Elizondo", 1174,367, 1175,367),
        C("Ellacuría Ignacio", 81,60, 82,60),
        C("Elorrieta", 28,34, 72,58),
        C("Encarnación", 1024,438, 1022,422, 1034,417),
        C("Encartaciones", 226,164, 227,164),
        C("Enderika", 853,155, 854,155),
        C("Enekuri", 430,207, 431,207),
        C("Enekuri-Artxanda", 244,81, 245,81),
        C("Ensanche", 782,279, 783,279),
        C("Epalza", 821,174, 834,175),
        C("Epalza Viuda de", 833,171, 834,171),
        C("Epetxa", 388,162, 389,162),
        C("Eraso General", 423,283, 424,283),
        C("Ercilla", 681,382, 688,382, 698,357, 715,334, 758,273, 776,248),
        C("Erdikoetxe", 250,227, 251,227),
        C("Erkoreka Ernesto", 900,227, 901,227),
        C("Errekako", 1202,158, 1203,158),
        C("Errekakoetxe", 750,394, 751,394),
        C("Erronkari", 232,155, 233,155),
        C("Escuelas de las", 998,405, 999,405),
        C("Escuza José María", 583,434, 584,434),
        C("Esnarritzaga", 893,126, 894,126),
        C("Esperanto", 676,662, 677,662),
        C("Esperanza", 934,270, 949,279),
        C("Espinos de los", 386,379, 387,379),
        C("Estrauntza", 634,340, 646,336),
        C("Estufa", 938,287, 939,287),
        C("Etxenagusia Pintor", 251,245, 252,245),
        C("Etxepare", 212,118, 168,161),
        C("Etxezuri", 868,84, 894,90),
        C("Etxezuribidea", 305,271, 306,271),
        C("Euskalduna", 552,289, 505,297),
        C("Extremadura", 167,90, 168,90),
        C("Fagoaga Tenor", 1112,368, 1113,368),
        C("Fernández del Campo", 767,403, 768,403),
        C("Ferrocarril del", 629,527, 630,527),
        C("Figuera Ángela", 859,499, 860,499),
        C("Fleming Doctor", 828,434, 829,434),
        C("Fontecha y Salazar", 791,157, 792,157),
        C("Fraternidad La", 1346,238, 1347,238),
        C("Fray Juan", 6,265, 7,265),
        C("Fueros", 945,308, 946,308),
        C("Funicular del", 863,4, 864,4),
        C("Galicia", 151,143, 152,143),
        C("Galleteras", 116,218, 117,218),
        C("Ganekogorta Monte", 451,143, 452,143),
        C("Garaizar", 1257,159, 1222,159),
        C("Garamendi Vicente Rv.", 1029,372, 1030,372),
        C("Garay Juan de", 827,493, 828,493),
        C("García Rivero Maestro", 1002,414, 1003,414),
        C("García Salazar", 824,400, 818,436),
        C("Gardeazabal Juan", 1130,433, 1131,433),
        C("Gardoqui Cardenal", 803,333, 804,333),
        C("Garellano", 531,494, 532,494),
        C("Georgia", 1128,492, 1129,492),
        C("Gernika", 891,523, 942,546),
        C("Gipuzkoa", 465,260, 466,260),
        C("Goitia", 960,550, 961,550),
        C("Gorbeia", 461,141, 462,141),
        C("Gordóniz", 667,509, 680,459, 700,412),
        C("Gorliz", 972,96, 973,96),
        C("Gortazar Juan Carlos de", 958,511, 987,525),
        C("Gurtubay", 502,460, 503,460),
        C("Gutiérrez Abascal R.", 63,50, 64,50),
        C("Henao", 686,270, 731,265, 793,258),
        C("Hernani", 880,406, 881,406),
        C("Heros", 748,259, 742,204),
        C("Hijas de la Caridad", 983,364, 984,364),
        C("Hurtado de Amézaga", 833,357, 849,328),
        C("Ibaizabal", 1043,637, 1041,662),
        C("Ibarrekolanda", 269,215, 302,191, 310,213, 361,216),
        C("Ibarreta Enrique", 1171,340, 1172,340),
        C("Ibarretxe Pedro", 839,272, 840,272),
        C("Ibarruri Dolores", 718,503, 719,503),
        C("Ibarsusi-Santo Domingo", 1118,81, 1119,81),
        C("Ibarsusibidea", 1319,449, 1349,408),
        C("Ibañez de Bilbao", 823,269, 824,269),
        C("Ibeni", 997,415, 998,415),
        C("Ikastalde", 68,322, 69,322),
        C("Indautxu", 612,418, 646,383, 664,404),
        C("Inmaculada", 207,96, 208,96),
        C("Insausti “Uzturre” Jesús", 867,141, 868,141),
        C("Iparraguirre", 697,257, 703,315, 708,365, 714,426),
        C("Irala", 775,519, 774,541, 794,551),
        C("Iruarrizaga Luis", 892,405, 893,405),
        C("Irumineta", 1362,197, 1363,197),
        C("Iruña", 432,230, 456,278),
        C("Isleta", 822,232, 823,232),
        C("Iturburu", 990,443, 991,443),
        C("Iturralde", 1094,320, 1095,320),
        C("Iturriaga", 1179,356, 1192,381, 1205,419),
        C("Iturribarria", 536,525, 537,525),
        C("Iturribide", 1001,323, 1042,325, 1083,343, 1089,340, 1087,356),
        C("Iturriondo", 1047,147, 1048,147),
        C("Izarra", 206,137, 207,137),
        C("Jardines", 1193,190, 1193,228, 1212,224),
        C("Jardintxikerra", 627,550, 628,550),
        C("Jardín de Zorrotza", 20,254, 21,254),
        C("Juan Ma Vidarte", 800,238, 801,238),
        C("Julita Berrojalbiz", 992,301, 1000,294),
        C("Kalamua", 1157,447, 1158,447),
        C("Karmelo", 1132,370, 1133,379),
        C("Kirikiño", 785,519, 788,483),
        C("Kobetabidea", 193,448, 194,448),
        C("Labayru", 692,484, 740,468),
        C("Lagunetxea", 523,161, 524,161),
        C("Lamana", 874,388, 875,388),
        C("Landaorlegi", 1145,419, 1146,419),
        C("Landetabidea", 1013,120, 1014,120),
        C("Langaran", 1319,144, 1320,144),
        C("Lapurdi", 789,470, 790,470),
        C("Larrakoetxe", 1315,159, 1316,159),
        C("Larrakotorre", 185,175, 245,232),
        C("Larratundu", 1298,137, 1299,137),
        C("Larrazabal", 1008,168, 1009,168),
        C("Larrea Carmelo", 107,67, 108,67),
        C("Larrinaga", 1001,362, 1002,362),
        C("Larroque Ángel Pintor", 1233,481, 1234,481),
        C("Lasalle Santiago Reverendo", 1078,436, 1079,436),
        C("Latorre General", 605,525, 606,525),
        C("Lauaxeta", 1225,401, 1226,401),
        C("Lazurtegui Julio", 398,240, 399,240),
        C("Lecuona Pintor", 586,521, 587,521),
        C("Ledesma", 810,294, 855,289),
        C("Lersundi", 737,220, 738,220),
        C("Levante", 149,100, 150,100),
        C("Lezeaga", 415,527, 435,536, 453,511),
        C("Logroño", 468,265, 469,265),
        C("Losada Pintor", 1191,436, 1192,436),
        C("Lotería", 948,350, 949,350),
        C("Lozoño", 1278,196, 1299,209),
        C("Lucía Yarza", 833,115, 834,115),
        C("Lutxana", 822,351, 823,351),
        C("Luzarra", 467,195, 468,195),
        C("Machín", 749,479, 750,479),
        C("Madariaga", 411,251, 353,281),
        C("Makaldi", 1366,212, 1367,212),
        C("Makua José María", 1128,307, 1129,307),
        C("Mandobide", 793,135, 794,135),
        C("Manning Mrs. Leah", 1193,196, 1194,196),
        C("Mar Mediterráneo", 261,197, 262,197),
        C("Martzana", 935,415, 936,415),
        C("Masustegi", 1084,297, 1112,314),
        C("Matiko", 856,149, 881,156),
        C("Mazarredo", 803,249, 686,229),
        C("Mendiarte", 1083,41, 1084,41),
        C("Mendigain", 117,353, 118,353),
        C("Mendipe", 631,652, 632,652),
        C("Mendiri Maestro", 1071,281, 1072,281),
        C("Menéndez y Pelayo Marcelino", 1094,456, 1095,456),
        C("Merced", 905,392, 896,381),
        C("Migoya Eliseo", 394,249, 395,249),
        C("Mikol", 170,279, 171,279),
        C("Mina San Luís", 943,460, 895,485),
        C("Mirador a Bilbao", 851,78, 852,78),
        C("Miraflores", 1049,483, 1050,483),
        C("Miramar", 282,114, 328,141, 380,144),
        C("Miranda Ignacio", 57,348, 58,348),
        C("Miribilla", 940,431, 925,455),
        C("Mogrobejo Nemesío", 49,34, 50,34),
        C("Molino de Viento", 761,68, 762,68),
        C("Montaño", 877,134, 866,124, 875,65),
        C("Monte Elorriaga", 366,194, 367,194),
        C("Montevideo", 371,456, 439,482, 521,508),
        C("Moraza", 836,149, 837,149),
        C("Morgan", 250,275, 321,314, 411,319, 453,305),
        C("Moyúa Federíco", 728,315, 729,315),
        C("Museo", 972,332, 973,332),
        C("Mérida", 176,79, 177,79),
        C("Múgica y Butrón", 805,165, 806,165),
        C("Nadal Goyo", 1052,453, 1053,453),
        C("Navarro Villoslada", 204,193, 205,193),
        C("Negueruela Celso", 798,101, 799,101),
        C("Novia Salcedo", 593,539, 594,539),
        C("Nueva", 912,343, 913,343),
        C("Nueva Aurora", 924,86, 925,86),
        C("Obreros Jabonera Tapia", 57,360, 57,367),
        C("Obreros Talleres Deusto", 593,110, 594,110),
        C("Ogoño", 1183,461, 1184,461),
        C("Olabarrieta Eugenio", 293,370, 294,370),
        C("Olabarría José", 624,496, 625,496),
        C("Olabeaga", 393,409, 427,462),
        C("Olagorta", 279,339, 280,339),
        C("Olano", 951,438, 915,449),
        C("Olite", 627,515, 628,515),
        C("Ollerías Altas", 1040,454, 1041,454),
        C("Ollerías Bajas", 1041,463, 1042,463),
        C("Ondarroa", 1290,318, 1273,351),
        C("Orixe", 119,57, 179,75, 236,133, 280,169),
        C("Ornilla Doctor", 1255,234, 1256,234),
        C("Ortutxueta", 1074,473, 1073,497),
        C("Otxarkoagabidea", 1301,452, 1302,452),
        C("Padura Batalla de", 767,553, 768,553),
        C("Pagasarri", 902,670, 903,670),
        C("Patxi Aita", 263,166, 264,166),
        C("Pelota", 920,376, 921,376),
        C("Pernet Esteban Padre", 1129,355, 1130,355),
        C("Pinadia", 121,327, 122,327),
        C("Plentzia", 973,91, 974,91),
        C("Power Luís", 469,228, 470,228),
        C("Poza Licenciado", 577,379, 578,379),
        C("Prieto Indalecio", 857,336, 858,336),
        C("Profesionales Sanitarios", 525,444, 526,444),
        C("Pérez Galdós", 538,456, 592,450, 612,449, 651,445),
        C("Quintana", 922,216, 923,216),
        C("Ramón y Cajal", 501,180, 423,202),
        C("Ravel Maurice", 812,110, 813,110),
        C("Recalde", 721,247, 731,346, 738,416),
        C("República de Abando", 668,231, 669,231),
        C("República de Begoña", 1053,445, 1054,445),
        C("Revilla Gregorio de La", 657,335, 658,335),
        C("Ribera", 956,405, 957,405),
        C("Rioja", 157,155, 158,155),
        C("Rodríguez Arias", 575,356, 691,344, 756,337),
        C("Roncesvalles Batalla de", 929,155, 930,155),
        C("Ronda", 977,382, 978,382),
        C("Sabina de La Cruz", 109,225, 134,223),
        C("Sagarminaga", 1153,470, 1212,478, 1216,462),
        C("Sagrada Família", 383,244, 384,244),
        C("Sagrado Corazón de Jesús", 554,330, 555,330),
        C("Salces Anselma de", 879,166, 880,166),
        C("San Agustín", 884,188, 885,188),
        C("San Antón", 367,149, 368,149),
        C("San Felicísimo", 385,264, 386,264),
        C("San Francisquito", 1083,461, 1084,461),
        C("San Francísco Javier", 684,248, 685,248),
        C("San Ignacio", 202,551, 203,551),
        C("San Isidro", 1065,214, 1091,230),
        C("San Joaquín", 1193,495, 1252,476),
        C("San Justo", 490,638, 491,638),
        C("San Mamés", 717,411, 758,420),
        C("San Miguel", 68,293, 33,220),
        C("San Nicolás de Olabeaga", 305,414, 320,429, 396,417),
        C("San Vicente", 826,257, 827,257),
        C("Santa Ana", 363,478, 364,478),
        C("Santa Ana de Bolueta", 1292,470, 1311,475),
        C("Santa Cecilía", 1178,451, 1179,451),
        C("Santa Clara", 1147,336, 1148,336),
        C("Santa Lucía", 1177,440, 1178,440),
        C("Santa Marina", 1226,55, 1227,55),
        C("Santa María", 905,357, 906,357),
        C("Santa Mónica", 1132,289, 1142,286),
        C("Santander", 472,269, 473,269),
        C("Santiago", 727,517, 728,517),
        C("Santo Domingo de Guzmán", 989,297, 990,297),
        C("Santo Rosario", 1146,387, 1147,387),
        C("Santos Juanes", 971,342, 981,394),
        C("Santurtzi", 970,99, 971,99),
        C("Santutxu", 1115,404, 1081,378),
        C("Saralegi", 958,451, 959,451),
        C("Sarrikoalde", 270,278, 271,278),
        C("Sarrikue", 1113,167, 1114,167),
        C("Saturraran", 231,147, 232,147),
        C("Sendeja", 911,241, 912,241),
        C("Serantes", 665,658, 666,658),
        C("Siervas de Jesús", 885,346, 886,346),
        C("Sirgueras", 81,260, 82,260),
        C("Sollube", 666,664, 667,664),
        C("Solokoetxe", 983,353, 984,353),
        C("Sombrerería", 954,332, 955,332),
        C("Somosierra Alto", 793,541, 794,541),
        C("Sorkunde", 1002,377, 1003,377),
        C("Tellaetxebidea", 61,21, 62,21),
        C("Tellagorri", 553,537, 554,537),
        C("Tellería", 1334,449, 1348,448, 1375,397, 1362,389, 1381,328),
        C("Tendería", 956,382, 957,382),
        C("Tere Verdes", 790,128, 791,128),
        C("Tiboli", 832,132, 857,176, 843,183),
        C("Torre Gorostitzaga", 1192,354, 1193,354),
        C("Torres Quevedo Ingeniero", 502,413, 503,413),
        C("Torreurizar", 817,549, 818,549),
        C("Trauko", 903,129, 921,140, 943,140, 969,134),
        C("Tres Pilares", 961,430, 962,430),
        C("Trokabidea", 452,386, 453,386),
        C("Tutúlu", 947,103, 952,84),
        C("Txirrita", 1256,451, 1257,451),
        C("Txotena", 1344,159, 1354,184),
        C("Ugalde", 751,510, 752,510),
        C("Ugarte", 1261,170, 1262,170),
        C("Ugarteko", 319,225, 320,225),
        C("Ugaskobidea", 494,66, 535,96, 554,155),
        C("Unceta Párroco", 1149,456, 1150,456),
        C("Universidad de Oñati", 146,130, 166,110),
        C("Universidades", 624,163, 661,167, 658,214),
        C("Unión Begoñesa", 1205,443, 1206,443),
        C("Urazurrutia", 993,439, 1002,450, 1046,506),
        C("Urgozo", 298,416, 299,416),
        C("Uribarri Escuelas", 904,148, 905,148),
        C("Uribarri “C”", 895,114, 896,114),
        C("Uribitarte", 764,191, 779,211, 802,244, 839,227, 830,244, 852,255),
        C("Urkiola", 610,542, 611,542),
        C("Urquijo", 817,334, 764,380),
        C("Urquijo Julio", 390,309, 391,309),
        C("Usandizaga Músico", 72,298, 73,298),
        C("Valle Aureliano", 683,425, 684,425),
        C("Valle del Baztán", 214,150, 215,150),
        C("Venezuela", 886,257, 887,257),
        C("Ventas", 458,515, 459,515),
        C("Ventosa", 457,394, 492,360),
        C("Villarías", 885,282, 886,282),
        C("Virgen de Begoña", 1017,274, 1018,274),
        C("Virgen del Pinar", 378,131, 379,131),
        C("Vista Alegre", 753,496, 767,481),
        C("Vitoria-Gasteiz", 902,443, 903,443),
        C("Vía Vieja de Lezama", 1034,160, 1035,160),
        C("Xalbador", 692,653, 693,653),
        C("Xenpelar", 887,505, 837,516),
        C("Ybarra Rafaela", 495,219, 508,237),
        C("Yolanda González", 283,377, 284,377),
        C("Zabala", 847,476, 855,526),
        C("Zabala Bruno Mauricio", 844,451, 845,451),
        C("Zabala Vicente Párroco", 20,300, 21,300),
        C("Zabalbide", 1088,364, 1138,323, 1154,288, 1138,269, 1149,266, 1105,222, 1122,182, 1125,111),
        C("Zabalburu", 944,272, 945,272),
        C("Zalbidea", 19,312, 20,312),
        C("Zamacola", 1067,543, 1068,543),
        C("Zamarripa Pablo", 1122,308, 1123,308),
        C("Zankoeta", 584,490, 552,494),
        C("Zarandoa", 100,120, 101,120),
        C("Zarate Mikel", 239,175, 240,175),
        C("Zazpilanda", 114,386, 89,341),
        C("Zizeruena", 1280,128, 1281,128),
        C("Zorrotza-Kastrexana", 53,287, 54,287),
        C("Zorrotzabaso", 105,377, 106,377),
        C("Zorrotzaurre", 123,262, 124,262),
        C("Zorrozgoiti", 1,300, 27,362, 140,344),
        C("Zuberoa", 796,512, 798,485),
        C("Zubiaurrre Pintores", 634,511, 635,511),
        C("Zubiría Ybarra Tomás", 972,154, 973,154),
        C("Zugastinobia", 661,487, 662,487),
        C("Zuhatzu", 1241,225, 1242,225),
        C("Zuloaga Ignacio Pintor", 220,324, 221,324),
        C("Zumaia", 994,131, 1004,142, 1014,160),
        C("Zumalacárregui", 1032,218, 963,174),
        C("Zumarraga", 1006,366, 1010,347),
        C("Zurbaran", 999,173, 1000,173),
        C("Zurbaranbarri", 1061,124, 1077,90, 1076,80),
        C("Zuricalday Felipa", 1186,405, 1187,405),
        C("Ávila", 709,467, 710,467),
    };
/*CALLES>>>*/

    /// <summary>Qué calle es cada casilla: 0 es «ninguna», y si no, el índice más uno.</summary>
    static readonly short[] _de = new short[Ciudad.MW*Ciudad.MH];
    /// <summary>Cuántas casillas le han salido a cada calle. Lo mira la batería: una calle
    /// que se queda en cuatro casillas es una calle que no se ha encontrado, sin dar error.</summary>
    public static readonly int[] Largo = new int[Calles.Length];

    public static string En(int x, int y) {
        if (x < 0 || y < 0 || x >= Ciudad.MW || y >= Ciudad.MH) return null;
        int i = _de[y*Ciudad.MW + x];
        return i > 0 ? Calles[i-1].Nombre : null;
    }

    /// <summary>Qué casillas son «calle». No solo la calzada: la acera es calle, y en el
    /// Casco Viejo la calle ES la acera —las Siete Calles y media Bilbao la Vieja son
    /// peatonales y el plano no les pinta trazo de rodadura, así que buscando solo asfalto
    /// el Casco entero se quedaba sin nombrar—. Y andando, que es como se va la mitad del
    /// rato, se va por la acera: con la calzada sola el rótulo solo salía conduciendo.</summary>
    public static bool EsCalle(int x, int y) {
        var t = Ciudad.T(x,y);
        return t == Suelo.Road || t == Suelo.Acera || t == Suelo.Plaza
            || t == Suelo.Puente || t == Suelo.Muelle;
    }

    const int Holgura = 60, PrecioAcera = 4;

    /// <summary>
    /// El camino de calle entre dos puntos, encerrado en la caja de los dos extremos con
    /// holgura: sin la caja, un tramo que no se puede unir se pone a recorrer los siete
    /// kilómetros de ciudad antes de rendirse.
    ///
    /// No es una anchura a secas sino un Dijkstra con dos precios —la calzada vale 1 y la
    /// acera 4— porque si los dos cuestan igual el camino se va por la acera en cuanto
    /// ahorra una casilla, y entonces la Gran Vía sale nombrada por el portal en vez de por
    /// la avenida. Con tan pocos valores no hace falta un montículo: valen unos cubos por
    /// distancia, que se recorren en orden.
    /// </summary>
    static List<Vector2Int> Camino(int ax, int ay, int bx, int by) {
        // La holgura, a la medida del tramo. Con sesenta fijas, dos rótulos de la misma
        // calle a quince casillas montaban una caja de 135×135 para un camino de quince:
        // con las mil y pico calles que saca el extractor del plano, eso son minutos.
        int hol = Mathf.Clamp(Mathf.Max(Mathf.Abs(bx-ax), Mathf.Abs(by-ay)), 24, Holgura);
        int x0 = Mathf.Max(1, Mathf.Min(ax,bx)-hol), x1 = Mathf.Min(Ciudad.MW-2, Mathf.Max(ax,bx)+hol);
        int y0 = Mathf.Max(1, Mathf.Min(ay,by)-hol), y1 = Mathf.Min(Ciudad.MH-2, Mathf.Max(ay,by)+hol);
        int an = x1-x0+1, al = y1-y0+1, N = an*al;
        var dist = new int[N]; var de = new int[N];
        for (int i = 0; i < N; i++) { dist[i] = int.MaxValue; de[i] = -1; }
        int tope = (an+al)*PrecioAcera + 8;
        var cubos = new List<int>[tope];
        System.Action<int,int> Mete = (i,d) => {
            int c = d % tope;
            if (cubos[c] == null) cubos[c] = new List<int>();
            cubos[c].Add(i);
        };
        int ini = (ay-y0)*an + (ax-x0), fin = (by-y0)*an + (bx-x0);
        dist[ini] = 0; Mete(ini, 0);
        int[] dxs = {1,-1,0,0}, dys = {0,0,1,-1};
        for (int d = 0; d < N*PrecioAcera; d++) {
            var lote = cubos[d % tope];
            if (lote == null || lote.Count == 0) continue;
            cubos[d % tope] = null;
            foreach (int i in lote) {
                if (dist[i] != d) continue;               // entrada vieja, ya mejorada
                if (i == fin) {
                    var cam = new List<Vector2Int>();
                    for (int j = i; j >= 0; j = de[j]) cam.Add(new Vector2Int(x0 + j%an, y0 + j/an));
                    return cam;
                }
                int x = x0 + i%an, y = y0 + i/an;
                for (int k = 0; k < 4; k++) {
                    int nx = x+dxs[k], ny = y+dys[k];
                    if (nx < x0 || ny < y0 || nx > x1 || ny > y1 || !EsCalle(nx,ny)) continue;
                    int nd = d + (Ciudad.Rodable(nx,ny) ? 1 : PrecioAcera);
                    int j = (ny-y0)*an + (nx-x0);
                    if (nd < dist[j]) { dist[j] = nd; de[j] = i; Mete(j, nd); }
                }
            }
        }
        return null;
    }

    /// <summary>El apaño de cuando no hay camino: la recta entre los extremos, casilla a
    /// casilla. Pasa donde el plano deja la calle partida —la acera sale de erosionar la
    /// calzada y en una diagonal estrecha el interior se queda en una hilera que solo se
    /// toca por la esquina—. Es menos exacto que seguir la calle, pero el trazado que se
    /// afirma es el mismo y así ninguna calle de la tabla se queda sin una sola casilla.</summary>
    static List<Vector2Int> Recta(int ax, int ay, int bx, int by) {
        int n = Mathf.Max(Mathf.Abs(bx-ax), Mathf.Abs(by-ay));
        var cam = new List<Vector2Int>();
        for (int i = 0; i <= n; i++) {
            int x = Mathf.RoundToInt(ax + (bx-ax)*(float)i/n);
            int y = Mathf.RoundToInt(ay + (by-ay)*(float)i/n);
            if (EsCalle(x,y)) cam.Add(new Vector2Int(x,y));
        }
        return cam.Count > 0 ? cam : null;
    }

    static bool Cerca(int cx, int cy, out int rx, out int ry) { return Cerca(cx, cy, 24, out rx, out ry); }

    static bool Cerca(int cx, int cy, int r, out int rx, out int ry) {
        var q = Ciudad.CercaDe(EsCalle, cx, cy, r);
        rx = Mathf.FloorToInt(q.x); ry = Mathf.FloorToInt(q.y);
        return EsCalle(rx, ry);
    }

    /// <summary>
    /// Primero todos los trazados, y después las faldas. En una sola pasada la falda de
    /// una calle se comía el trazado de su vecina: en el Ensanche, Colón de Larreátegui va
    /// a una manzana de la Gran Vía y se quedaba en veinte casillas, porque la Gran Vía
    /// iba antes en la tabla y le pintaba encima. El trazado de cualquiera pesa más que la
    /// falda de cualquiera; entre dos trazados que se cruzan, manda el orden de la tabla.
    /// </summary>
    public static void Nombrar() {
        System.Array.Clear(_de, 0, _de.Length);
        var caminos = new List<Vector2Int>[Calles.Length];
        for (int c = 0; c < Calles.Length; c++) {
            var via = Calles[c];
            caminos[c] = new List<Vector2Int>();
            for (int t = 0; t+1 < via.Puntos.GetLength(0); t++) {
                int ax, ay, bx, by;
                if (!Cerca(via.Puntos[t,0],   via.Puntos[t,1],   out ax, out ay)) continue;
                if (!Cerca(via.Puntos[t+1,0], via.Puntos[t+1,1], out bx, out by)) continue;
                var cam = Camino(ax,ay,bx,by) ?? Recta(ax,ay,bx,by);
                if (cam != null) caminos[c].AddRange(cam);
            }
            Largo[c] = 0;
        }
        // Se nombra el trazado y la calle pegada a él: una avenida son tres o cuatro
        // casillas de calzada más dos aceras, y el camino solo va por una, así que
        // cruzándola por el otro carril el HUD se quedaba en blanco.
        System.Action<int,int> Pinta = (c, r) => {
            foreach (var p in caminos[c])
                for (int dy = -r; dy <= r; dy++)
                    for (int dx = -r; dx <= r; dx++) {
                        int px = p.x+dx, py = p.y+dy;
                        if (px < 0 || py < 0 || px >= Ciudad.MW || py >= Ciudad.MH) continue;
                        int i = py*Ciudad.MW + px;
                        if (_de[i] != 0 || !EsCalle(px,py)) continue;
                        _de[i] = (short)(c+1); Largo[c]++;
                    }
        };
        for (int c = 0; c < Calles.Length; c++) Pinta(c, 0);
        for (int c = 0; c < Calles.Length; c++) Pinta(c, 2);
        // Y si alguna se ha quedado a cero —el rótulo cayó en un trozo de calle que no
        // conecta con nada, o se lo comió entero la vecina— se nombra al menos su propio
        // sitio. Una calle que existe en el plano y no aparece nunca es peor que una
        // nombrada de más.
        for (int c = 0; c < Calles.Length; c++) {
            if (Largo[c] > 0) continue;
            for (int t = 0; t < Calles[c].Puntos.GetLength(0); t++) {
                int qx, qy;
                // Aquí se busca más lejos que en el trazado: el rótulo de una calle de
                // monte puede caer a cuarenta casillas de la calzada más próxima.
                if (!Cerca(Calles[c].Puntos[t,0], Calles[c].Puntos[t,1], 80, out qx, out qy)) continue;
                caminos[c] = new List<Vector2Int> { new Vector2Int(qx, qy) };
                Pinta(c, 2);
                if (Largo[c] > 0) break;
            }
            if (Largo[c] > 0) continue;
            // Y si aun así sigue a cero es que su sitio se lo ha quedado entero la calle
            // de al lado. Entonces se le quita una casilla: la de su propio rótulo. Que
            // dos calles se disputen una esquina pasa en Bilbao también; que una
            // desaparezca del juego, no.
            for (int t = 0; t < Calles[c].Puntos.GetLength(0); t++) {
                int qx, qy;
                if (!Cerca(Calles[c].Puntos[t,0], Calles[c].Puntos[t,1], 80, out qx, out qy)) continue;
                _de[qy*Ciudad.MW + qx] = (short)(c+1); Largo[c] = 1; break;
            }
        }
    }
}

}

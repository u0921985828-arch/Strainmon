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
        C("Achúcarro Doctor", 694,334, 695,334),
        C("Agarre", 881,479, 882,479),
        C("Agirre José Ma Ertzaina", 692,215, 693,215),
        C("Aguirre Domingo de", 1001,274, 1002,274),
        C("Aguirre Hermanos", 578,188, 579,188),
        C("Aguirre Lehendakari", 274,224, 275,224),
        C("Aguirre Máximo", 682,336, 681,287),
        C("Agüero Martín", 763,482, 764,482),
        C("Aixeona", 1249,117, 1250,117),
        C("Ajuriaguerra Juan", 742,247, 676,253),
        C("Alazne López Etxebarria", 86,333, 87,333),
        C("Albacete", 1181,385, 1182,385),
        C("Alberca Doctor", 1002,155, 1003,155),
        C("Albia", 828,277, 829,277),
        C("Alcorta Nicolás", 792,449, 793,449),
        C("Aldamiz Monte", 926,96, 927,96),
        C("Alicante", 1184,374, 1185,374),
        C("Alicia Aretxabaleta", 141,259, 142,259),
        C("Allende Manuel", 648,424, 649,424),
        C("Allende Particular", 1139,409, 1140,409),
        C("Almería", 1187,380, 1188,380),
        C("Altamira", 233,511, 306,504, 321,534),
        C("Altube", 323,478, 324,478),
        C("Altube Seber", 209,132, 210,132),
        C("Aluzetabidea", 450,573, 451,573),
        C("Alzaga Toribio", 221,153, 222,153),
        C("Alzola Pablo de", 604,514, 605,514),
        C("Amistad", 884,295, 885,295),
        C("Amparo", 832,447, 833,447),
        C("Anboto", 652,654, 653,654),
        C("Andalucía", 103,89, 104,89),
        C("Andramaría de Begoña", 1070,173, 1071,173),
        C("Antxeta Juan de", 133,49, 233,118, 280,155),
        C("Aoiz / Agoitz", 206,161, 207,161),
        C("Araba", 452,239, 453,239),
        C("Arabella", 1098,181, 1086,159),
        C("Aragón", 127,93, 107,113),
        C("Aralar", 910,128, 911,128),
        C("Arambarri Músico", 990,171, 991,171),
        C("Arana Sabino", 561,378, 562,378),
        C("Arane", 508,507, 509,507),
        C("Araneko", 374,171, 375,171),
        C("Aranekobidea", 339,160, 378,172),
        C("Aranzadi Telesforo", 747,349, 748,349),
        C("Arbidea", 1178,304, 1180,298),
        C("Arbieto", 771,325, 772,325),
        C("Arbolagana", 306,202, 307,202),
        C("Arbolantxa", 813,249, 814,249),
        C("Arbolantxabidea", 1337,122, 1346,99, 1409,97),
        C("Archer Marino", 28,179, 29,179),
        C("Arechavaleta", 654,408, 655,408),
        C("Areilza Doctor", 626,378, 627,378),
        C("Arenal", 931,312, 932,312),
        C("Arenal Celestino Ma del", 273,174, 274,174),
        C("Arenal del", 931,312, 932,312),
        C("Arenaza Cueva", 437,275, 438,275),
        C("Aresti Gabriel", 1213,314, 1204,222, 1297,240),
        C("Arno Monte", 934,133, 935,133),
        C("Arnotegi", 856,430, 857,430),
        C("Arregui Angela", 1334,194, 1357,346),
        C("Arregui Ricardo", 846,126, 847,126),
        C("Arriaga", 897,126, 898,126),
        C("Arriaga Emiliano", 909,320, 910,320),
        C("Arrieta Emilio", 760,224, 761,224),
        C("Arriquíbar", 735,386, 736,386),
        C("Arróspide Jon", 455,292, 456,292),
        C("Arrúe Pintores", 262,177, 263,177),
        C("Arsuaga", 1162,364, 1163,364),
        C("Artalandio", 1284,260, 1285,260),
        C("Artapeta", 909,663, 910,663),
        C("Artatzamina", 796,124, 797,124),
        C("Artazubekoa", 742,640, 743,640),
        C("Artazubidea", 721,658, 722,658),
        C("Artazuriña", 1174,288, 1218,282),
        C("Arteche Conde de", 550,295, 551,295),
        C("Arteta Aurelio Pintor", 1154,388, 1155,388),
        C("Artsenalbidea", 38,232, 53,235),
        C("Artxanda-La Salve", 579,123, 580,123),
        C("Artxanda-Santo Domingo", 1004,3, 1005,3),
        C("Askao", 957,307, 958,307),
        C("Askatasuna", 887,542, 957,499, 1018,505),
        C("Astarloa", 787,321, 785,296),
        C("Astigarraga Pedro", 213,214, 214,214),
        C("Astillero", 30,300, 47,277, 55,195),
        C("Asturias", 155,86, 118,123),
        C("Asunción", 784,67, 785,67),
        C("Ategorri Txakolindegia", 913,320, 914,320),
        C("Atxetabidea", 1113,130, 1089,167),
        C("Atxuri", 1019,436, 1009,427),
        C("Auntzetxeta", 450,543, 451,543),
        C("Aurrekoetxea", 1083,315, 1084,315),
        C("Autonomía", 585,501, 658,476, 761,442),
        C("Avril Monte", 1143,43, 1144,43),
        C("Ayala Canciller", 833,323, 834,323),
        C("Ayuntamiento del", 885,243, 895,217),
        C("Azkaraibidea", 1390,228, 1391,228),
        C("Azkue Resurrección Ma de", 1100,404, 1101,404),
        C("Aznar Santiago", 999,478, 1000,478),
        C("Azoka", 84,429, 85,429),
        C("Azpeitia Sancho de", 541,228, 542,228),
        C("Azurleku", 1227,440, 1228,440),
        C("Badajoz", 170,86, 171,86),
        C("Bailén", 877,353, 872,377),
        C("Baiona", 804,513, 805,513),
        C("Bakio", 963,102, 964,102),
        C("Baldezate Filomena", 701,650, 702,650),
        C("Balears Illes", 185,179, 186,179),
        C("Ballets Olaeta", 416,331, 417,331),
        C("Balparda Gregorio", 214,141, 215,141),
        C("Banco España", 933,269, 934,269),
        C("Barinaga", 24,214, 25,214),
        C("Baroja Pío", 855,241, 856,241),
        C("Barraincúa", 719,235, 720,235),
        C("Barrenkale", 934,380, 935,380),
        C("Barrenkalebarrena", 924,377, 925,377),
        C("Barrio Lagunetxea", 523,161, 524,161),
        C("Barrio San Miguel", 68,293, 33,220),
        C("Barroeta Aldamar", 862,259, 863,259),
        C("Barua Picaza Martín", 776,453, 777,453),
        C("Basarrate", 1197,422, 1198,422),
        C("Basterra Ramón", 589,326, 590,326),
        C("Bastida Ricardo Arqto.", 1148,376, 1149,376),
        C("Basurtu Estación de", 524,528, 525,528),
        C("Basurtu-Kastrexana", 487,504, 392,504),
        C("Basurtubekoa", 514,524, 515,524),
        C("Begoñazpi", 1193,157, 1189,139),
        C("Beiti", 682,642, 683,642),
        C("Benidorm", 289,194, 277,232),
        C("Benita Asas", 168,135, 169,135),
        C("Bentazarra", 422,515, 423,515),
        C("Berastegui", 842,292, 843,292),
        C("Bergara", 802,542, 803,542),
        C("Bergé y Salcedo", 671,274, 672,274),
        C("Bernaola Carmelo", 331,263, 332,263),
        C("Berriotxoa San Valentín", 960,128, 961,128),
        C("Berriz", 402,19, 403,19),
        C("Berrizbidea", 392,133, 393,133),
        C("Bertendona", 799,346, 795,353),
        C("Bidebarrieta", 931,347, 915,337),
        C("Bidegain", 87,316, 88,316),
        C("Bilbao Izaurieta", 157,262, 158,262),
        C("Bilbao La Vieja", 965,424, 966,424),
        C("Bilbao-Galdakao", 1244,456, 1295,443),
        C("Bilintx", 1035,263, 1036,263),
        C("Birjinetxe", 1178,200, 1179,200),
        C("Bizkaia", 723,372, 724,372),
        C("Bizkargi", 685,658, 686,658),
        C("Bolivar Elorduy Julián", 1104,384, 1105,384),
        C("Bolivar Simón", 590,428, 610,426),
        C("Bonaparte Luis Luciano", 1165,385, 1178,440),
        C("Bosco Don", 327,236, 328,236),
        C("Bosque del", 1026,397, 1027,397),
        C("Botica Vieja", 585,206, 517,260),
        C("Braille Luis", 227,227, 228,227),
        C("Briñas Luis", 538,377, 536,449, 540,486),
        C("Brouard Santiago", 727,517, 728,517),
        C("Buen Pastor", 984,146, 985,146),
        C("Buenavista", 505,167, 506,138),
        C("Buenos Aires", 875,280, 876,280),
        C("Burgos", 455,245, 456,245),
        C("Butrón", 112,338, 113,338),
        C("C. Deprit Lasa Amadeo", 1046,310, 1047,310),
        C("Caleros", 747,651, 748,651),
        C("Campión Arturo", 133,78, 180,125, 215,160),
        C("Campo Volantín", 775,170, 857,208),
        C("Campuzano Emilio", 1009,404, 1010,404),
        C("Cantalojas", 893,432, 894,432),
        C("Cantarranas", 977,437, 978,437),
        C("Cantera", 867,431, 890,447),
        C("Cantábria", 143,71, 144,71),
        C("Canárias Islas", 136,141, 189,196, 205,213),
        C("Capuchinos de Basurtu", 468,434, 469,434),
        C("Capuchinos de Deustu", 437,181, 438,181),
        C("Caramelo Monte", 549,630, 550,630),
        C("Careaga Plácido", 422,234, 423,234),
        C("Cargueras", 346,379, 347,379),
        C("Carmelo Gil Doctores", 705,479, 706,479),
        C("Carnicería Vieja", 941,387, 942,387),
        C("Casals Pau", 1305,177, 1306,177),
        C("Caserío Garro", 384,182, 385,182),
        C("Caserío Landaburu", 1137,390, 1138,390),
        C("Caserío Larrazabal", 1003,168, 1004,168),
        C("Casilla", 653,509, 641,492),
        C("Castaños", 823,155, 824,155),
        C("Castillo General", 870,403, 871,403),
        C("Catalunya", 127,67, 128,67),
        C("Católicos Reyes", 800,499, 801,499),
        C("Caños de los", 1072,521, 1056,410),
        C("Chávarri Victor", 560,404, 561,404),
        C("Circo Amateur del Club Deportivo", 1245,411, 1246,411),
        C("Circular", 868,304, 869,304),
        C("Ciudad Jardín", 779,105, 799,86, 860,113),
        C("Clara Campoamor", 13,217, 13,250),
        C("Clavé José Anselmo", 586,318, 587,318),
        C("Cocherito de Bilbao", 1210,363, 1237,429),
        C("Colón de Larreategui", 731,291, 813,283),
        C("Concepción", 861,443, 862,459, 875,461),
        C("Concha General", 765,442, 757,360),
        C("Concordia", 1161,406, 1162,406),
        C("Constantino Tenor", 864,478, 865,478),
        C("Consulado de Bilbao", 972,409, 973,409),
        C("Convivencia de la", 798,217, 799,217),
        C("Cordelería", 33,250, 34,250),
        C("Corredor del Cadagua", 119,412, 138,384),
        C("Correo", 939,331, 808,362),
        C("Cortes", 807,363, 808,363),
        C("Cortes Pedro Médico Municipal", 861,143, 862,143),
        C("Cosa Juan de la", 1161,416, 1162,416),
        C("Costa", 774,414, 775,414),
        C("Cristo del", 902,175, 903,175),
        C("Cruz de la", 961,353, 1000,278),
        C("Cáceres", 173,83, 174,83),
        C("Deprit Lasa Amadeo", 1041,307, 1028,262),
        C("Deustu de", 237,356, 238,356),
        C("Dieciséis de Agosto", 985,405, 986,405),
        C("Diputación", 772,304, 773,304),
        C("Dique", 456,375, 457,375),
        C("Don Diego Berguices", 1286,151, 1287,151),
        C("Donostia Aita", 538,518, 539,518),
        C("Donostia-San Sebastián", 953,525, 907,511),
        C("Durrio Francisco, Escultor", 248,180, 249,180),
        C("Díaz Emparanza Doctor", 624,359, 625,359),
        C("Díaz de Haro María", 593,361, 594,361),
        C("Díez Calixto", 681,488, 682,488),
        C("Echaniz Bombero", 693,439, 687,442),
        C("Echave Alfredo de", 1287,346, 1287,367),
        C("Echevarrieta Cosme", 757,227, 758,227),
        C("Echevarriía “Camarón”Julián", 965,383, 966,383),
        C("Echevarría Federico", 945,382, 946,382),
        C("Echevarría Lúis", 945,382, 946,382),
        C("Egaña", 749,428, 750,428),
        C("Egileor", 438,145, 439,145),
        C("Eguillor Pedro", 764,343, 765,343),
        C("Eguiluz Antonio Médico", 1174,428, 1175,428),
        C("Eguren Enrique", 729,468, 730,468),
        C("Eguía General", 575,468, 646,460),
        C("El Canal", 188,228, 102,129),
        C("Elcano", 688,283, 743,330, 795,382),
        C("Elexabarri", 640,551, 641,551),
        C("Elizalde", 1062,256, 1063,256),
        C("Elizondo", 1174,367, 1175,367),
        C("Ellacuría Ignacio", 81,60, 82,60),
        C("Elorrieta", 28,34, 72,58),
        C("Enbeita “Uretxindorra”Kepa", 1288,168, 1289,168),
        C("Encarnación", 1024,438, 1022,422, 1034,417),
        C("Encartaciones", 226,164, 227,164),
        C("Enderika", 853,155, 854,155),
        C("Enekuri", 430,207, 431,207),
        C("Enekuri-Artxanda", 244,81, 359,49),
        C("Ensanche", 782,279, 783,279),
        C("Entrambasaguas", 402,478, 403,478),
        C("Entrecanales Doctor", 624,359, 625,359),
        C("Epalza", 817,181, 818,181),
        C("Epalza Viuda de", 833,171, 923,268),
        C("Epetxa", 388,162, 389,162),
        C("Eraso General", 423,283, 424,283),
        C("Ercilla", 681,382, 688,382, 698,357, 715,334, 758,273, 776,248),
        C("Erdikoetxe", 250,227, 251,227),
        C("Eretza Monte", 778,269, 779,269),
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
        C("Espinosa Orive Dr.", 778,269, 779,269),
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
        C("Ferrocarril del", 591,475, 629,527, 682,548, 735,534),
        C("Figuera Ángela", 859,499, 860,499),
        C("Fleming Doctor", 828,434, 829,434),
        C("Fontecha y Salazar", 791,157, 792,157),
        C("Fraternidad La", 1346,238, 1382,199),
        C("Fray Juan", 6,265, 7,265),
        C("Fueros", 945,308, 946,308),
        C("Funicular del", 863,4, 814,146),
        C("Gabika Monte", 712,372, 713,372),
        C("Gaiarre Julían", 1318,236, 1319,236),
        C("Galicia", 151,143, 152,143),
        C("Gallastegui, Don Claudio", 981,465, 982,465),
        C("Galleteras", 116,218, 195,287, 336,364),
        C("Galíndez Jesús", 1230,191, 1160,234),
        C("Ganekogorta Monte", 451,143, 452,143),
        C("Ganeta Monte", 429,136, 430,136),
        C("Garai", 869,400, 870,400),
        C("Garaizar", 1257,159, 1222,159),
        C("Garaizar Bernardino", 958,638, 959,638),
        C("Garamendi Vicente Rv.", 1029,368, 1030,368),
        C("Garat Txomin", 1178,270, 1236,260),
        C("Garate", 1029,371, 1030,371),
        C("Garate Venerable Hermano", 523,160, 524,160),
        C("Garay Juan de", 808,446, 827,493, 830,537),
        C("García Rivero Maestro", 672,358, 673,358),
        C("García Salazar", 824,400, 818,436),
        C("Gardeazabal Juan", 1130,433, 1131,433),
        C("Gardoqui Cardenal", 803,333, 804,333),
        C("Garellano", 531,494, 532,494),
        C("Gaztañeta Antonio Almirante", 638,509, 639,509),
        C("Georgia", 1128,492, 1129,492),
        C("Gernika", 891,523, 942,546),
        C("Gipuzkoa", 465,260, 466,260),
        C("Goiko Torre", 713,371, 714,371),
        C("Goitia", 808,483, 809,483),
        C("González Damían Maestro", 808,116, 809,116),
        C("Gorbeia", 461,141, 462,141),
        C("Gordóniz", 667,509, 680,459, 700,412),
        C("Gorliz", 972,96, 973,96),
        C("Gortazar Juan Carlos de", 958,511, 987,525),
        C("Gran Vía López de Haro D. Diego", 624,327, 804,308),
        C("Grupo Aldapeta", 48,383, 70,383, 57,356, 57,335, 71,355, 90,338, 117,350),
        C("Grupo Begoñalde", 1051,208, 1052,208),
        C("Grupo Inmaculada", 593,106, 506,134),
        C("Grupo Popular La", 921,167, 922,167),
        C("Guezala Antonio Pintor", 234,144, 235,144),
        C("Guiard Teófilo", 692,296, 693,296),
        C("Guimón Rezola Doctor", 202,139, 203,139),
        C("Guinea Anselmo Pintor", 1217,400, 1218,400),
        C("Guisasola Juan", 1257,467, 1258,467),
        C("Guridi Músico", 744,116, 745,116),
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
        C("Ibañez de Bilbao", 823,269, 753,158),
        C("Iciar Maestro", 1005,354, 1006,354),
        C("Ikastalde", 68,322, 69,322),
        C("Indautxu", 612,418, 646,383, 664,404),
        C("Insausti “Uzturre” Jesús", 867,141, 868,141),
        C("Intxorta Monte", 771,517, 772,517),
        C("Iparraguirre", 697,257, 703,315, 708,365, 714,426),
        C("Irala", 775,519, 774,541, 794,551),
        C("Irigoyen Juan de", 1238,483, 1239,483),
        C("Iruarrizaga Luis", 892,405, 893,405),
        C("Irumineta", 1362,197, 1363,197),
        C("Iruña", 432,230, 456,278),
        C("Isasi Andrés", 740,549, 741,549),
        C("Isleta", 822,232, 823,232),
        C("Iturburu", 990,443, 991,443),
        C("Iturralde", 1094,320, 1095,320),
        C("Iturriaga", 1179,356, 1192,381, 1205,419),
        C("Iturribarria", 536,525, 537,525),
        C("Iturribide", 1001,323, 1042,325, 1083,343, 1089,340, 1087,356),
        C("Iturriondo", 1047,147, 1048,147),
        C("Izaro Monte", 918,128, 919,128),
        C("Izarra", 206,137, 207,137),
        C("Jardines", 671,271, 828,274, 917,355),
        C("Jardintxikerra", 627,550, 628,550),
        C("Jardín de Zorrotza", 63,387, 86,331),
        C("Jaro de Arana", 577,527, 562,452),
        C("Jata Monte", 417,158, 418,158),
        C("Juan Ma Vidarte", 800,238, 801,238),
        C("Juan XXIII S.S.", 1094,269, 1095,269),
        C("Julita Berrojalbiz", 992,301, 1000,294),
        C("Kalamua", 1157,447, 1158,447),
        C("Karmelo", 991,339, 1132,370, 1133,379),
        C("Kirikiño", 785,519, 788,483),
        C("Kobeta", 187,445, 188,445),
        C("Kobetabidea", 193,448, 194,448),
        C("Labayru", 692,484, 740,468),
        C("Laguna La", 884,433, 885,433),
        C("Lamana", 874,388, 875,388),
        C("Landabaso", 242,239, 243,239),
        C("Landaorlegi", 1145,419, 1146,419),
        C("Landetabidea", 1013,120, 1014,120),
        C("Landín Félix Doctor", 626,506, 627,506),
        C("Langaran", 1319,144, 1320,144),
        C("Lapurdi", 789,470, 790,470),
        C("Larrakoetxe", 1315,159, 1316,159),
        C("Larrakotorre", 185,175, 245,232),
        C("Larramendi Padre", 825,336, 826,336),
        C("Larraskitu", 759,621, 760,621),
        C("Larratundu", 1298,137, 1299,137),
        C("Larrazabal", 1003,168, 1004,168),
        C("Larrea Carmelo", 107,67, 108,67),
        C("Larrinaga", 1001,362, 1002,362),
        C("Larroque Ángel Pintor", 1233,481, 1234,481),
        C("Lasalle Santiago Reverendo", 1078,436, 1079,436),
        C("Latorre General", 605,525, 606,525),
        C("Lauaxeta", 1225,401, 1226,401),
        C("Laurencín Marqués", 1223,415, 1224,415),
        C("Lazurtegui Julio", 398,240, 399,240),
        C("Lecuona Pintor", 561,522, 586,521),
        C("Ledesma", 810,294, 855,289),
        C("Leguina Calixto", 947,154, 948,154),
        C("Leguizamón Tristán de", 770,147, 771,147),
        C("Leizaola Lehendakari", 608,259, 609,259),
        C("Lekeitio", 174,128, 175,128),
        C("Lepanto Batalla de", 1017,282, 1018,282),
        C("Lersundi", 737,220, 738,220),
        C("Levante", 149,100, 150,100),
        C("Lezeaga", 415,527, 435,536, 453,511),
        C("Lidón José María", 1106,502, 1107,502),
        C("Logroño", 468,265, 469,265),
        C("Lojendio Padre", 831,339, 832,339),
        C("Losada Pintor", 1191,436, 1206,490),
        C("Lotería", 948,350, 949,350),
        C("Lozoño", 1278,196, 1299,209),
        C("Lucía Yarza", 833,115, 834,115),
        C("Lutxana", 822,351, 823,351),
        C("Luzarra", 467,195, 468,195),
        C("Machín", 749,479, 750,479),
        C("Macía Francesc", 555,206, 556,206),
        C("Madariaga", 353,281, 411,251, 510,207),
        C("Makaldi", 1366,212, 1367,212),
        C("Makua José María", 1128,307, 1129,307),
        C("Mala de", 602,531, 603,531),
        C("Mallona de", 980,288, 977,277),
        C("Mandobide", 793,135, 794,135),
        C("Mandoia Monte", 1211,389, 1212,389),
        C("Manning Mrs. Leah", 1193,196, 1194,196),
        C("Mar Mediterráneo", 261,197, 262,197),
        C("Martínez Artola Pedro", 778,448, 779,448),
        C("Masustegi", 1084,297, 1112,314),
        C("Matiko", 856,149, 881,156),
        C("Matos Manuel", 645,413, 646,413),
        C("Mazarredo", 803,249, 686,229),
        C("Mañaricua Andrés Eliseo de", 871,509, 872,509),
        C("Meabe Tomás", 982,324, 983,324),
        C("Medina de Pomar", 788,359, 789,359),
        C("Mendiarte", 1083,41, 1084,41),
        C("Mendigain", 117,353, 118,353),
        C("Mendipe", 631,652, 632,652),
        C("Mendiri Maestro", 1071,281, 1072,281),
        C("Menéndez y Pelayo Marcelino", 1085,428, 1094,456),
        C("Merced", 906,366, 907,366),
        C("Migoya Eliseo", 394,249, 395,249),
        C("Mikol", 170,279, 171,279),
        C("Mina Julía", 992,301, 993,301),
        C("Mina San Luís", 943,460, 895,485),
        C("Mirador a Bilbao", 851,78, 852,78),
        C("Miraflores", 1049,483, 1206,514),
        C("Miramar", 282,114, 328,141, 380,144),
        C("Miranda Ignacio", 57,348, 58,348),
        C("Mirasol Conde", 919,420, 838,475),
        C("Miribilla", 940,431, 925,455),
        C("Mogrobejo Nemesío", 49,34, 50,34),
        C("Molino de Viento", 761,68, 762,68),
        C("Montaño", 877,134, 866,124, 875,65),
        C("Monte Elorriaga", 113,300, 114,300),
        C("Montevideo", 371,456, 439,482, 521,508),
        C("Montserrat Na. Señora de", 771,517, 772,517),
        C("Moraza", 836,149, 837,149),
        C("Moreno “Pitxitxi” Rafael", 487,403, 488,403),
        C("Morgan", 250,275, 321,314, 411,319, 453,305),
        C("Moyúa Federíco", 728,315, 729,315),
        C("Muelle Campa de los Ingleses", 678,181, 679,181),
        C("Muelle Churruca y Brunet Evaristo", 595,221, 596,221),
        C("Muelle Ibeni", 997,415, 998,415),
        C("Muelle Martzana", 935,415, 936,415),
        C("Muelle Merced de La", 661,266, 662,266),
        C("Muelle Olabeaga", 393,409, 394,409),
        C("Muelle Siervas de Jesús", 885,346, 886,346),
        C("Muelle Sirgueras", 81,260, 168,324, 300,407),
        C("Muelle Sota Ramón de La", 502,317, 503,317),
        C("Mujeres 25 de Noviembre de las", 890,317, 891,317),
        C("Muros de San Pedro", 896,318, 897,318),
        C("Museo", 972,332, 897,415),
        C("Muñoz María", 977,340, 978,340),
        C("Mérida", 176,79, 177,79),
        C("Múgica y Butrón", 805,165, 806,165),
        C("Nadal Goyo", 1052,453, 1053,453),
        C("Navarra", 877,304, 878,304),
        C("Navarro Villoslada", 204,193, 245,157),
        C("Negueruela Celso", 798,101, 799,101),
        C("Norte Particular del", 847,404, 848,404),
        C("Novia Salcedo", 561,533, 593,539),
        C("Nueva", 912,343, 913,343),
        C("Nueva Aurora", 924,86, 925,86),
        C("Obreros Jabonera Tapia", 57,360, 57,367),
        C("Obreros Talleres Deusto", 362,185, 410,272, 542,153, 587,167, 592,113, 624,167, 659,217),
        C("Ogoño", 1183,461, 1184,461),
        C("Oiz Monte", 925,131, 926,131),
        C("Olabarrieta Eugenio", 293,370, 294,370),
        C("Olabarría José", 624,496, 625,496),
        C("Olagorta", 279,339, 280,339),
        C("Olano", 951,438, 915,449),
        C("Olite", 627,515, 628,515),
        C("Ollerías Altas", 1040,454, 1043,450),
        C("Ollerías Bajas", 1041,463, 1042,463),
        C("Ondarroa", 1290,318, 1273,351),
        C("Oquendo Almirantes", 930,148, 931,148),
        C("Oreja Marcelino", 698,451, 699,451),
        C("Orixe", 119,57, 179,75, 236,133, 280,169),
        C("Ornilla Doctor", 1255,234, 1234,299),
        C("Ortutxueta", 1074,473, 1073,497),
        C("Ortíz Alfau Ángel", 906,443, 907,443),
        C("Orueta Obispo", 780,253, 781,253),
        C("Otero Blas de", 419,276, 477,247, 540,218),
        C("Otxarkoagabidea", 1301,452, 1302,452),
        C("Padura Batalla de", 767,553, 768,553),
        C("Pagasarri", 902,670, 903,670),
        C("Parque Bidarte", 404,217, 405,217),
        C("Parque Eskurtze", 749,571, 759,580, 797,570),
        C("Parque República de Abando", 668,231, 669,231),
        C("Patxi Aita", 263,166, 264,166),
        C("Paz la", 713,371, 714,371),
        C("Pelota", 920,376, 921,376),
        C("Pernet Esteban Padre", 1129,355, 1130,355),
        C("Perro del", 927,361, 928,361),
        C("Peña Lemona", 501,319, 502,319),
        C("Picasso Pablo", 793,459, 794,459),
        C("Piedritas las", 940,169, 941,169),
        C("Pinadia", 121,327, 122,327),
        C("Plentzia", 973,91, 974,91),
        C("Polvorín del", 1008,251, 1009,251),
        C("Pontón del", 1236,514, 1237,514),
        C("Portal de Zamudio", 960,356, 961,356),
        C("Power Luís", 469,228, 483,259),
        C("Poza Licenciado", 577,379, 578,379),
        C("Prieto Indalecio", 857,336, 858,336),
        C("Profesionales Sanitarios", 525,444, 526,444),
        C("Príncipe", 892,267, 893,267),
        C("Puerto Marqués del", 760,310, 761,310),
        C("Pérez Galdós", 538,456, 592,450, 612,449, 651,445),
        C("Quintana", 922,216, 923,216),
        C("Raimundo Pérez Lezama", 473,379, 474,379),
        C("Ramón y Cajal", 501,180, 423,202),
        C("Ravel Maurice", 777,117, 812,110, 913,105),
        C("Recalde", 721,247, 731,346, 738,416),
        C("Regoyos Darío de", 621,320, 622,320),
        C("Remar", 901,414, 902,414),
        C("República de Begoña", 1053,445, 1054,445),
        C("Revilla Gregorio de La", 657,335, 661,367),
        C("Ribera", 790,356, 791,356),
        C("Ribera de la", 956,405, 957,405),
        C("Rioja", 157,155, 158,155),
        C("Rodríguez Arias", 575,356, 691,344, 756,337),
        C("Roncesvalles Batalla de", 929,155, 930,155),
        C("Ronda", 977,382, 978,382),
        C("Rubial Ramón", 644,225, 645,225),
        C("Sabina de La Cruz", 109,225, 134,223),
        C("Sagarminaga", 1153,470, 1212,478, 1216,462),
        C("Sagrada Família", 383,244, 384,244),
        C("Sagrado Corazón de Jesús", 554,330, 555,330),
        C("Saibigain Monte", 771,517, 772,517),
        C("Salazar General", 692,503, 693,503),
        C("Salazar Zubia L.", 795,147, 796,147),
        C("Salces Anselma de", 860,165, 879,166),
        C("Salve La", 577,123, 578,123),
        C("Salve La-Ugasko", 576,125, 577,125),
        C("San Adrián", 1110,339, 1111,339),
        C("San Agustín", 884,188, 885,188),
        C("San Antonio de Iturrigorri", 715,565, 716,565),
        C("San Antón", 367,149, 368,149),
        C("San Antón de", 714,557, 715,557),
        C("San Felicísimo", 373,290, 385,264),
        C("San Francisquito", 1083,461, 1120,447),
        C("San Francísco", 811,425, 812,425),
        C("San Francísco Javier", 684,248, 685,248),
        C("San Ignacio", 202,551, 203,551),
        C("San Isidro", 1065,214, 1091,230),
        C("San Joaquín", 1193,495, 1252,476),
        C("San Justo", 490,638, 491,638),
        C("San Mamés", 717,411, 758,420),
        C("San Nicolás", 944,297, 945,297),
        C("San Nicolás de Olabeaga", 305,414, 320,429, 396,417, 427,462),
        C("San Pedro", 481,187, 482,187),
        C("San Roke", 865,151, 866,151),
        C("San Vicente", 826,257, 827,257),
        C("Santa Ana", 363,478, 364,478),
        C("Santa Ana de Bolueta", 1292,470, 1311,475),
        C("Santa Cecilía", 1178,451, 1179,451),
        C("Santa Clara", 1147,336, 1148,336),
        C("Santa Lucía", 1177,440, 1178,440),
        C("Santa Marina", 1226,55, 1227,55),
        C("Santa María", 905,357, 906,357),
        C("Santa Mónica", 1092,317, 1132,289, 1142,286),
        C("Santander", 472,269, 473,269),
        C("Santiago", 416,486, 417,486),
        C("Santiago de Compostela", 921,558, 922,558),
        C("Santo Domingo", 1026,11, 1027,11),
        C("Santo Domingo de Guzmán", 989,297, 990,297),
        C("Santo Domingo-El Gallo", 1015,5, 1016,5),
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
        C("Serrate Felipe", 532,369, 533,369),
        C("Sollube", 666,664, 667,664),
        C("Solokoetxe", 984,352, 985,352),
        C("Solokoetxe de", 983,353, 984,353),
        C("Sombrerería", 954,332, 955,332),
        C("Somera", 972,382, 973,382),
        C("Somosierra Alto", 793,541, 794,541),
        C("Sorkunde", 1002,377, 1003,377),
        C("Sota Alejandro de La", 971,368, 972,368),
        C("Steer George", 1010,273, 1011,273),
        C("Tellaetxe Pintor", 228,132, 229,132),
        C("Tellaetxebidea", 61,21, 62,21),
        C("Tellagorri", 553,537, 554,537),
        C("Tellería", 1334,449, 1348,448, 1375,397, 1362,389, 1381,328),
        C("Tendería", 956,382, 957,382),
        C("Tere Verdes", 790,128, 791,128),
        C("Tiboli", 832,132, 857,176, 843,183),
        C("Tolosa", 539,517, 540,517),
        C("Torre Gorostitzaga", 1192,354, 1193,354),
        C("Torre Heliodoro de La", 526,224, 527,224),
        C("Torre de La", 934,364, 935,364),
        C("Torres Quevedo Ingeniero", 502,413, 520,417),
        C("Torreurizar", 817,549, 818,549),
        C("Trauko", 903,129, 921,140, 943,140, 969,134),
        C("Tres Pilares", 961,430, 962,430),
        C("Trokabidea", 452,386, 453,386),
        C("Trueba Antonio de", 520,429, 521,429),
        C("Tutúlu", 947,103, 952,84),
        C("Txirrita", 1256,451, 1257,451),
        C("Txotena", 1344,159, 1354,184),
        C("Ugalde", 751,510, 752,510),
        C("Ugarte", 1261,170, 1262,170),
        C("Ugarteburu José María", 1094,217, 1095,217),
        C("Ugarteko", 319,225, 320,225),
        C("Ugaskobidea", 494,66, 535,96, 554,155),
        C("Ugaz Párroco", 1048,244, 1049,244),
        C("Uhagón Felipe Alcalde", 695,420, 696,420),
        C("Unamúno Miguel", 787,349, 979,325),
        C("Unceta Párroco", 1149,456, 1150,456),
        C("Universidad de Oñati", 146,130, 166,110),
        C("Universidades", 624,163, 661,167, 658,214),
        C("Unión Begoñesa", 1205,443, 1206,443),
        C("Unzúe Severo", 903,319, 904,319),
        C("Urazurrutia", 993,439, 1002,450, 1046,506),
        C("Urbieta Juan de", 273,185, 274,185),
        C("Urgozo", 298,416, 299,416),
        C("Uribarri", 898,115, 899,115),
        C("Uribarri Escuelas", 904,148, 905,148),
        C("Uribarri “A”", 906,152, 907,152),
        C("Uribarri “B”", 881,111, 882,111),
        C("Uribarri “C”", 895,114, 896,114),
        C("Uribe Laso Ma Victoria", 599,271, 600,271),
        C("Uribitarte", 764,191, 779,211, 802,244, 839,227, 830,244, 852,255),
        C("Urkiola", 610,542, 611,542),
        C("Urquijo", 542,405, 543,405),
        C("Urquijo Julio", 390,309, 391,309),
        C("Urrutia", 675,408, 676,408),
        C("Usandizaga Músico", 72,298, 73,298),
        C("Valle Aureliano", 683,425, 684,425),
        C("Valle del Baztán", 214,150, 215,150),
        C("Venezuela", 886,257, 887,257),
        C("Ventas", 458,515, 459,515),
        C("Ventosa", 457,394, 492,360),
        C("Viana Príncipe", 873,183, 874,183),
        C("Viar Juan", 1094,428, 1095,428),
        C("Victor del", 935,341, 936,341),
        C("Victoria de Lecea Eduardo", 602,270, 603,270),
        C("Villabaso Camilo", 654,348, 655,348),
        C("Villarías", 885,282, 886,282),
        C("Virgen de Begoña", 1017,274, 1118,270, 1117,354),
        C("Virgen del Pinar", 378,131, 379,131),
        C("Vista Alegre", 753,496, 767,481),
        C("Vitoria-Gasteiz", 902,443, 903,443),
        C("Vía Vieja de Lezama", 1034,160, 1035,160),
        C("Xalbador", 692,653, 693,653),
        C("Xenpelar", 887,505, 837,516),
        C("Ybarra Rafaela", 495,219, 508,237),
        C("Yolanda González", 283,377, 284,377),
        C("Zabala", 847,486, 848,486),
        C("Zabala Bruno Mauricio", 844,451, 847,476),
        C("Zabala Vicente Párroco", 20,300, 21,300),
        C("Zabalbide", 1088,364, 1138,323, 1154,288, 1138,269, 1149,266, 1105,222, 1122,182, 1125,111),
        C("Zabalburu", 944,272, 945,272),
        C("Zalbide David Bombero", 1138,322, 1139,322),
        C("Zalbidea", 19,312, 20,312),
        C("Zamacois Eduardo Pintor (P.E.Z.)", 673,296, 674,296),
        C("Zamacola", 1067,543, 1068,543),
        C("Zamarripa Pablo", 1122,308, 1123,308),
        C("Zankoeta", 584,490, 552,494),
        C("Zarandoa", 100,120, 175,197),
        C("Zarate Mikel", 239,175, 240,175),
        C("Zarra Telmo", 524,387, 525,387),
        C("Zazpilanda", 114,386, 89,341),
        C("Zizeruena", 1280,128, 1281,128),
        C("Zorrotza Estación de", 43,315, 44,315),
        C("Zorrotza-Kastrexana", 53,287, 83,428),
        C("Zorrotzabaso", 105,377, 106,377),
        C("Zorrotzaurre", 123,262, 124,262),
        C("Zorrozgoiti", 1,300, 27,362, 140,344),
        C("Zuberoa", 796,512, 798,485),
        C("Zubiaurrre Pintores", 633,513, 634,513),
        C("Zubiría Ybarra Tomás", 972,150, 973,150),
        C("Zubiskubidea", 1141,194, 1142,194),
        C("Zugastinobia", 661,487, 662,487),
        C("Zugazagoitia Julían", 960,550, 961,550),
        C("Zuhatzu", 1241,225, 1242,225),
        C("Zuloaga Ignacio Pintor", 220,324, 221,324),
        C("Zumaia", 994,131, 1004,142, 1014,160),
        C("Zumalacárregui", 963,174, 1032,218, 1132,152),
        C("Zumarraga", 1006,366, 1010,347),
        C("Zunzunegui Juan Antonio", 526,431, 527,431),
        C("Zurbaran", 1005,174, 1006,174),
        C("Zurbaranbarri", 1061,124, 1077,90, 1076,80),
        C("Zurbaranbidea", 1026,151, 1027,151),
        C("Zuricalday Felipa", 1187,402, 1188,402),
        C("Ávila", 709,467, 710,467),
    };
/*CALLES>>>*/

    /// <summary>Qué calle es cada casilla: 0 es «ninguna», y si no, el índice más uno.</summary>
    static readonly short[] _de = new short[Ciudad.MW*Ciudad.MH];
    /// <summary>Cuántas casillas le han salido a cada calle. Lo mira la batería: una calle
    /// que se queda en cuatro casillas es una calle que no se ha encontrado, sin dar error.</summary>
    public static readonly int[] Largo = new int[Calles.Length];

    /// <summary>El nombre para el HUD. En la tabla van los nombres completos del callejero
    /// —'Gran Vía López de Haro D. Diego'— porque es lo que dice el plano, pero en pantalla
    /// eso son cuarenta caracteres y se come media franja. Se abrevia como se abrevia en un
    /// callejero de papel, y si aun así no cabe se corta.</summary>
    static readonly string[,] Abrev = {
        {"Avenida","Av."},{"Alameda","Al."},{"Plaza","Pl."},{"Paseo","Ps."},
        {"Carretera","Ctra."},{"Camino","Cm."},{"Jardines","Jdns."},{"Jardín","Jdín."},
        {"Escalinata","Esc."},{"Grupo","Gp."},{"Muelle","Mu."},{"Puente","Pte."},
        {"Caserío","Cs."},{"Travesía","Trv."},{"Pasaje","Psj."},{"Ronda","Rda."},
        {"Callejón","Cjón."},{"Doctora","Dra."},{"Doctor","Dr."},{"General","Gral."},
        {"Santa","Sta."},{"Santo","Sto."},{"Universidad","Univ."},{"Reverendo","Rvdo."},
        {"Monseñor","Mons."},{"Profesor","Prof."},{"Ingeniero","Ing."},
        {"Arquitecto","Arqto."},{"Pintores","Ptor."},{"Pintor","Ptor."},
        {"Viaducto","Vdto."},{"Barrio","Bo."},
    };
    const int TopeCalle = 26;
    static readonly Dictionary<string,string> _cortos = new Dictionary<string,string>();

    public static string Corto(string n) {
        string v;
        if (_cortos.TryGetValue(n, out v)) return v;
        v = n;
        for (int i = 0; i < Abrev.GetLength(0); i++)
            v = System.Text.RegularExpressions.Regex.Replace(
                v, @"\b" + Abrev[i,0] + @"\b", Abrev[i,1]);
        v = System.Text.RegularExpressions.Regex.Replace(v, @"\s+", " ").Trim();
        if (v.Length > TopeCalle) v = v.Substring(0, TopeCalle - 1).TrimEnd() + ".";
        return _cortos[n] = v;
    }

    public static string En(int x, int y) {
        if (x < 0 || y < 0 || x >= Ciudad.MW || y >= Ciudad.MH) return null;
        int i = _de[y*Ciudad.MW + x];
        return i > 0 ? Corto(Calles[i-1].Nombre) : null;
    }

    /// <summary>Qué casillas son «calle». No solo la calzada: la acera es calle, y en el
    /// Casco Viejo la calle ES la acera —las Siete Calles y media Bilbao la Vieja son
    /// peatonales y el plano no les pinta trazo de rodadura, así que buscando solo asfalto
    /// el Casco entero se quedaba sin nombrar—. Y andando, que es como se va la mitad del
    /// rato, se va por la acera: con la calzada sola el rótulo solo salía conduciendo.</summary>
    public static bool EsCalle(int x, int y) {
        var t = Ciudad.T(x,y);
        // El puente no cuenta como calle a efectos de nombrar. Un puente sí es calle para
        // andar, pero deja que el trazado salte de una orilla a la otra: 'Correo', que es
        // del Casco Viejo, salía cruzando a San Francisco porque sus dos rótulos se unían
        // por el Arenal. Ninguna calle de Bilbao está en las dos orillas.
        return t == Suelo.Road || t == Suelo.Acera || t == Suelo.Plaza || t == Suelo.Muelle;
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

using System.Collections.Generic;
using UnityEngine;

namespace BilboCity {

public enum Pose {
    Quieto, Andar1, Andar2, Andar3, Andar4,
    Correr1, Correr2, Correr3, Correr4,
    Pega1, Pega2, Apunta, Dispara, Herido,
    Agacha, Agacha2
}

public struct Arquetipo {
    public string Nombre, Pelo, Gorro, Torso, Piernas, Calzado, Acces, Complexion;
    public Color32 Piel, PielS, PeloCol, GorroCol;
    public bool Cabezona;
}

/// <summary>
/// Personajes montados por capas: complexión, piel, pelo, gorro, prenda, pantalón, calzado
/// y accesorio. 8 direcciones × 14 poses por arquetipo, todo en una hoja.
/// </summary>
public static class ForjaChar {
    // La figura se dibuja en una caja de 20×26 y esas coordenadas no se tocan. Lo de
    // alrededor es margen, y hace falta: el puñetazo, el fogonazo y el carro de la compra
    // se salen de la caja, y el moño, la txapela y el casco de obra asoman por arriba.
    // Contra el borde de la celda se cortaban en seco, y encima no quedaba sitio para el
    // contorno de la silueta.
    // Los fija CONTEXT.md §18.1: celda de 24×32 con el pivote en (12,30). La figura sigue
    // siendo la caja de 20×26, así que queda 2 de margen a los lados, 5 arriba y 1 abajo.
    public const int MG_X = 2, MG_ARR = 5, MG_ABA = 1;
    public const int CW = 20 + MG_X * 2, CH = 26 + MG_ARR + MG_ABA;   // tamaño de celda
    public const int NPOSES = 16, NDIRS = 8;

    const int AB = 0, AR = 1, IZ = 2, DE = 3;
    // base cardinal + si vemos la cara (f) o el cogote (e) en las diagonales
    static readonly int[] BaseDir = { AB, DE, DE, DE, AR, IZ, IZ, IZ };
    static readonly bool[] Frente = { false, true, false, false, false, false, false, true };
    static readonly bool[] Espalda = { false, false, false, true, false, true, false, false };

    // `y` mueve la figura entera; `yt` solo el cuerpo, dejando los pies en el suelo. Hace
    // falta desde que la celda es de 24×32: bajar la figura entera hunde el contorno de las
    // botas fuera de la celda, y además al agacharse los pies no se mueven, baja la cabeza.
    struct Postura { public int p0, p1, b0, b1, y, yt, ataque, apunta; public bool herido, fog; }
    static readonly Postura[] Posturas = {
        new Postura{ p0=0,p1=0,b0=0,b1=0,y=0 },                       // Quieto
        new Postura{ p0=0,p1=1,b0=1,b1=-1,y=0 },                      // Andar1
        new Postura{ p0=1,p1=0,b0=0,b1=0,y=-1 },                      // Andar2
        new Postura{ p0=1,p1=0,b0=-1,b1=1,y=0 },                      // Andar3
        new Postura{ p0=0,p1=1,b0=0,b1=0,y=-1 },                      // Andar4
        new Postura{ p0=-2,p1=2,b0=2,b1=-2,y=-1 },                    // Correr1
        new Postura{ p0=2,p1=-2,b0=-2,b1=2,y=-1 },                    // Correr2
        new Postura{ p0=-3,p1=3,b0=3,b1=-3,y=-1 },                    // Correr3
        new Postura{ p0=3,p1=-3,b0=-3,b1=3,y=-1 },                    // Correr4
        new Postura{ p0=0,p1=0,b0=0,b1=0,y=0, ataque=1 },             // Pega1
        new Postura{ p0=0,p1=1,b0=0,b1=0,y=0, ataque=2 },             // Pega2
        new Postura{ p0=0,p1=0,b0=0,b1=0,y=0, apunta=1 },             // Apunta
        new Postura{ p0=0,p1=0,b0=0,b1=0,y=-1, apunta=1, fog=true },  // Dispara
        new Postura{ p0=1,p1=1,b0=2,b1=2,y=0, yt=1, herido=true },    // Herido
        // Agachado no lleva dibujo nuevo: se acortan las dos piernas y se baja el cuerpo.
        // A veintiséis píxeles de alto eso ya se lee como unas cuclillas, y no hay que
        // tocar la forja ni volver a cuadrar los gorros. Y no baja más de dos píxeles:
        // con tres, el contorno de los pies se sale de la celda.
        new Postura{ p0=3,p1=3,b0=1,b1=1,y=0, yt=2 },                 // Agacha
        new Postura{ p0=2,p1=4,b0=0,b1=2,y=0, yt=2 },                 // Agacha2
    };

    struct Prenda { public Color32 b, s, l; public bool corta, sinMangas, capucha, peto, bandas, mandil, placa, largo; public Color32 raya; public bool tieneRaya; }
    static Dictionary<string,Prenda> _torsos;
    static Dictionary<string,Prenda> Torsos {
        get {
            if (_torsos != null) return _torsos;
            _torsos = new Dictionary<string,Prenda> {
                {"camisa",     new Prenda{ b=Paleta.Blanco, s=Paleta.Crema, l=Paleta.Blanco }},
                {"camisaRem",  new Prenda{ b=Paleta.Blanco, s=Paleta.Crema, l=Paleta.Blanco, corta=true }},
                {"chaqueta",   new Prenda{ b=Paleta.Azul, s=Paleta.AzulO, l=Paleta.AzulL }},
                {"cazadora",   new Prenda{ b=Paleta.Asfalto, s=Paleta.Carbon, l=Paleta.GrisL }},
                {"sudadera",   new Prenda{ b=Paleta.GrisL, s=Paleta.Gris, l=Paleta.Acero, capucha=true }},
                {"chandal",    new Prenda{ b=Paleta.Verde, s=Paleta.VerdeO, l=Paleta.VerdeL, raya=Paleta.Hueso, tieneRaya=true }},
                {"mono",       new Prenda{ b=Paleta.AzulL, s=Paleta.Azul, l=Paleta.Acero, peto=true }},
                {"abrigo",     new Prenda{ b=Paleta.TejaO, s=Paleta.MaderaO, l=Paleta.Teja, largo=true }},
                {"gabardina",  new Prenda{ b=Paleta.Crema, s=Paleta.HormigonO, l=Paleta.Hueso, largo=true }},
                {"jersey",     new Prenda{ b=Paleta.RojoO, s=Paleta.Sangre, l=Paleta.Rojo }},
                {"bata",       new Prenda{ b=Paleta.Blanco, s=Paleta.Crema, l=Paleta.Blanco, largo=true }},
                {"uniforme",   new Prenda{ b=Paleta.AzulO, s=Paleta.Ria1, l=Paleta.Azul, placa=true }},
                {"camiseta",   new Prenda{ b=Paleta.Mostaza, s=Paleta.MostazaO, l=Paleta.Mostaza, corta=true }},
                {"polo",       new Prenda{ b=Paleta.VerdeL, s=Paleta.Verde, l=Paleta.VerdeL, corta=true }},
                {"reflectante",new Prenda{ b=Paleta.Rojo, s=Paleta.RojoO, l=Paleta.Mostaza, corta=true, bandas=true }},
                {"delantal",   new Prenda{ b=Paleta.Asfalto, s=Paleta.Carbon, l=Paleta.GrisL, corta=true, mandil=true }},
                {"tirantes",   new Prenda{ b=Paleta.Blanco, s=Paleta.Hormigon6, l=Paleta.Blanco, corta=true, sinMangas=true }},
            };
            return _torsos;
        }
    }

    struct Pantalon { public Color32 b, s, l, raya; public bool tieneRaya, falda, corto; }
    static Dictionary<string,Pantalon> _piernas;
    static Dictionary<string,Pantalon> Piernas {
        get {
            if (_piernas != null) return _piernas;
            _piernas = new Dictionary<string,Pantalon> {
                {"vaquero",   new Pantalon{ b=Paleta.H("#3a4f6b"), s=Paleta.H("#2c3d53"), l=Paleta.Ria5 }},
                {"vestir",    new Pantalon{ b=Paleta.Asfalto, s=Paleta.Carbon, l=Paleta.Gris }},
                {"chandalP",  new Pantalon{ b=Paleta.VerdeO, s=Paleta.H("#24422a"), l=Paleta.Verde, raya=Paleta.Hueso, tieneRaya=true }},
                {"monoP",     new Pantalon{ b=Paleta.AzulL, s=Paleta.Azul, l=Paleta.Ria5 }},
                {"falda",     new Pantalon{ b=Paleta.Morado, s=Paleta.H("#443759"), l=Paleta.Ria5, falda=true }},
                {"short",     new Pantalon{ b=Paleta.Crema, s=Paleta.HormigonO, l=Paleta.Hueso, corto=true }},
                {"cargo",     new Pantalon{ b=Paleta.H("#5d5b45"), s=Paleta.H("#474535"), l=Paleta.Verde5 }},
                {"uniformeP", new Pantalon{ b=Paleta.AzulO, s=Paleta.Ria1, l=Paleta.Azul }},
            };
            return _piernas;
        }
    }

    struct Zapato { public Color32 b, s; }
    static Zapato Calzado(string k) {
        switch (k) {
            case "deportivas": return new Zapato{ b=Paleta.Blanco,   s=Paleta.Acero };
            case "botas":      return new Zapato{ b=Paleta.H("#3a2d22"), s=Paleta.Ladrillo0 };
            case "katiuskas":  return new Zapato{ b=Paleta.MostazaO, s=Paleta.Luz2 };
            default:           return new Zapato{ b=Paleta.Asfalto,  s=Paleta.Carbon };
        }
    }

    static readonly Color32[] Pieles = { Paleta.Piel1, Paleta.Piel2, Paleta.Piel3, Paleta.Piel4, Paleta.Piel5, Paleta.Piel6 };
    static readonly Color32[] PielesS = {
        Paleta.H("#d2ac89"), Paleta.H("#c1946e"), Paleta.H("#a5734f"),
        Paleta.H("#8a5b36"), Paleta.H("#6f4a31"), Paleta.H("#523524")
    };

    public static Arquetipo A(string nombre, string comp, int pielI, string pelo, Color32 peloCol,
                              string gorro, Color32 gorroCol, string torso, string piernas,
                              string calzado, string acces) {
        return new Arquetipo {
            Nombre = nombre, Complexion = comp, Piel = Pieles[pielI], PielS = PielesS[pielI],
            Pelo = pelo, PeloCol = peloCol, Gorro = gorro, GorroCol = gorroCol,
            Torso = torso, Piernas = piernas, Calzado = calzado, Acces = acces
        };
    }

    static Dictionary<string,Arquetipo> _arq;
    public static Dictionary<string,Arquetipo> Arq {
        get {
            if (_arq != null) return _arq;
            _arq = new Dictionary<string,Arquetipo>();
            void Add(Arquetipo a) { _arq[a.Nombre] = a; }
            Add(A("protagonista","media",1,"corto",Paleta.Pelo1,"txapela",Paleta.Carbon,"cazadora","vaquero","botas","ninguno"));
            Add(A("ertzaina","corpulenta",1,"rapado",Paleta.Pelo1,"policia",Paleta.AzulO,"uniforme","uniformeP","botas","ninguno"));
            Add(A("maton","corpulenta",3,"rapado",Paleta.Pelo1,"ninguno",Paleta.Carbon,"tirantes","vaquero","botas","gafas"));
            Add(A("maton2","media",5,"corto",Paleta.Pelo1,"capucha",Paleta.Carbon,"sudadera","chandalP","deportivas","ninguno"));
            Add(A("josu","media",1,"corto",Paleta.Pelo2,"ninguno",Paleta.Carbon,"camisaRem","vestir","zapatos","ninguno"));
            Add(A("txema","corpulenta",2,"corto",Paleta.Pelo1,"ninguno",Paleta.Carbon,"abrigo","vestir","zapatos","ninguno"));
            Add(A("mikel","media",1,"canoso",Paleta.Pelo5,"txapela",Paleta.Carbon,"jersey","vestir","zapatos","bufanda"));
            Add(A("iker","media",2,"corto",Paleta.Pelo2,"gorra",Paleta.Azul,"mono","monoP","botas","ninguno"));
            Add(A("bego","media",0,"mono",Paleta.Pelo2,"ninguno",Paleta.Carbon,"bata","vestir","katiuskas","ninguno"));
            Add(A("koldo","corpulenta",1,"calvo",Paleta.Pelo1,"ninguno",Paleta.Carbon,"camisa","cargo","botas","ninguno"));
            Add(A("amaia","media",0,"mono",Paleta.Pelo5,"ninguno",Paleta.Carbon,"jersey","falda","zapatos","bolso"));
            Add(A("enfermera","delgada",3,"coleta",Paleta.Pelo1,"ninguno",Paleta.Carbon,"bata","vestir","deportivas","ninguno"));
            Add(A("p1","media",0,"corto",Paleta.Pelo2,"ninguno",Paleta.Carbon,"camisa","vestir","zapatos","bandolera"));
            Add(A("p2","delgada",1,"melena",Paleta.Pelo2,"ninguno",Paleta.Carbon,"gabardina","falda","zapatos","bolso"));
            Add(A("p3","media",2,"mono",Paleta.Pelo3,"ninguno",Paleta.Carbon,"jersey","falda","zapatos","carrito"));
            Add(A("p4","media",0,"canoso",Paleta.Pelo5,"txapela",Paleta.Carbon,"abrigo","vestir","zapatos","ninguno"));
            Add(A("p5","delgada",3,"corto",Paleta.Pelo1,"gorra",Paleta.Rojo,"chandal","chandalP","deportivas","mochila"));
            Add(A("p6","corpulenta",2,"corto",Paleta.Pelo2,"cascoObra",Paleta.Mostaza,"reflectante","cargo","botas","ninguno"));
            Add(A("p7","corpulenta",4,"rapado",Paleta.Pelo1,"lana",Paleta.RojoO,"reflectante","monoP","botas","ninguno"));
            Add(A("p8","delgada",5,"coleta",Paleta.Pelo1,"ninguno",Paleta.Carbon,"delantal","vestir","deportivas","ninguno"));
            // Los del mostrador. Se les ve mucho rato y de cerca, así que van con pinta
            // propia y no con la de un peatón cualquiera.
            Add(A("nerea","delgada",0,"melena",Paleta.Pelo2,"ninguno",Paleta.Carbon,"polo","vestir","deportivas","ninguno"));
            Add(A("patxi","corpulenta",1,"calvo",Paleta.Pelo1,"ninguno",Paleta.Carbon,"delantal","vestir","zapatos","ninguno"));
            Add(A("gorka","media",2,"corto",Paleta.Pelo1,"gorra",Paleta.Azul,"mono","monoP","botas","ninguno"));
            Add(A("maite","media",3,"coleta",Paleta.Pelo1,"ninguno",default(Color32),"chaqueta","falda","zapatos","ninguno"));
            // Más gente por la calle. Ocho tipos no llenan una ciudad de siete kilómetros:
            // a la tercera manzana ya has visto a todo el mundo dos veces.
            Add(A("p9", "media",   1,"canoso",Paleta.Pelo5,"ninguno",  Paleta.Carbon,"gabardina","vestir",  "zapatos",   "ninguno"));
            Add(A("p10","delgada", 3,"mono",  Paleta.Pelo2,"ninguno",  Paleta.Carbon,"chaqueta", "falda",   "zapatos",   "bolso"));
            Add(A("p11","delgada", 4,"corto", Paleta.Pelo1,"ninguno",  Paleta.Carbon,"sudadera", "vaquero", "deportivas","mochila"));
            Add(A("p12","corpulenta",1,"calvo",Paleta.Pelo1,"lana",    Paleta.Carbon,"jersey",   "cargo",   "botas",     "ninguno"));
            Add(A("p13","delgada", 5,"coleta",Paleta.Pelo3,"ninguno",  Paleta.Carbon,"camiseta", "short",   "deportivas","ninguno"));
            Add(A("p14","media",   0,"corto", Paleta.Pelo4,"visera",   Paleta.Blanco,"camisaRem","short",   "deportivas","mochila"));
            Add(A("p15","corpulenta",3,"rapado",Paleta.Pelo1,"cascoObra",Paleta.Carbon,"mono",   "monoP",   "botas",     "ninguno"));
            Add(A("p16","media",   2,"corto", Paleta.Pelo2,"ninguno",  Paleta.Carbon,"delantal", "vestir",  "zapatos",   "bandolera"));
            Add(A("p17","media",   4,"afro",  Paleta.Pelo1,"ninguno",  Paleta.Carbon,"polo",     "vaquero", "deportivas","bandolera"));
            Add(A("p18","media",   1,"melena",Paleta.Pelo5,"txapela",  Paleta.Carbon,"abrigo",   "vestir",  "zapatos",   "carrito"));
            // Los de la esquina. No son enemigos —no atacan— pero visten como los matones
            // y por eso se leen distinto de un viandante: en un barrio con banda, ver una
            // esquina con gente así dice dónde estás sin un solo rótulo.
            Add(A("banda1","delgada",   5,"rapado",Paleta.Pelo1,"ninguno",Paleta.Carbon,"tirantes","chandalP","deportivas","gafas"));
            Add(A("banda2","corpulenta",3,"corto", Paleta.Pelo1,"gorra",  Paleta.Rojo,  "chandal", "chandalP","deportivas","ninguno"));
            Add(A("banda3","media",     4,"rapado",Paleta.Pelo1,"ninguno",Paleta.Carbon,"cazadora","vaquero", "botas",     "gafas"));
            // De momento solo el protagonista. Arquetipo es un struct, así que hay que
            // volver a meterlo en el diccionario para que el cambio no se quede en la copia.
            var prota = _arq["protagonista"]; prota.Cabezona = true; _arq["protagonista"] = prota;
            return _arq;
        }
    }

    public static readonly string[] PeatonArq = { "p1","p2","p3","p4","p5","p6","p7","p8",
        "p9","p10","p11","p12","p13","p14","p15","p16","p17","p18","banda1","banda2","banda3" };
    /// <summary>Quién anda por dónde. En la Gran Vía hay gabardinas y en Zorrotzaurre monos
    /// de faena, y el plano ya nos dice cuál es cuál: no hay que repartir a nadie a mano.</summary>
    static readonly Dictionary<string,string[]> PeatonBarrio = new Dictionary<string,string[]> {
        {"senorial",  new[]{"p1","p2","p4","p9","p10","p16","p18"}},
        {"denso",     new[]{"p1","p3","p5","p8","p11","p16","p17","p18","banda3"}},
        {"bloques",   new[]{"p1","p3","p5","p8","p11","p12","p13","p17","p18","banda1","banda2","banda3"}},
        {"industrial",new[]{"p6","p7","p12","p15","p15","p5","banda2"}},
        {"abierto",   new[]{"p13","p13","p14","p11","p5","p12"}},
    };
    public static string ArqPeaton(Vector2 p) {
        var b = Ciudad.BarrioDe(Mathf.RoundToInt(p.x), Mathf.RoundToInt(p.y));
        string[] l;
        if (b != null && PeatonBarrio.TryGetValue(b.Estilo, out l)) return l[Utiles.RndI(0, l.Length-1)];
        return PeatonArq[Utiles.RndI(0, PeatonArq.Length-1)];
    }

    /// <summary>Dibuja un fotograma de personaje: caja de 20×26 con margen alrededor.</summary>
    public static Lienzo Dibujar(Arquetipo cfg, Pose pose, int d8) {
        var L = new Lienzo(CW, CH);
        int dir = BaseDir[d8];
        bool frente = Frente[d8], espalda = Espalda[d8];
        var P_ = Posturas[(int)pose];
        var T = Torsos[cfg.Torso];
        var PN = Piernas[cfg.Piernas];

        int compW = cfg.Complexion == "delgada" ? 6 : cfg.Complexion == "corpulenta" ? 10 : 8;
        int hom0  = cfg.Complexion == "delgada" ? 7 : cfg.Complexion == "corpulenta" ? 11 : 9;

        bool diag = frente || espalda;
        bool lateral = (dir == DE || dir == IZ) && !diag;
        int cx = MG_X + 10 + (diag ? (dir == DE ? -1 : 1) : 0) + (lateral ? (dir == DE ? 1 : -1) : 0);
        int oy = P_.y;
        int hom = hom0 - (diag ? 1 : 0) - (lateral ? 2 : 0);
        bool izqV = dir == IZ, derV = dir == DE, arr = (dir == AR) || espalda;
        // La cabezona. Los pies no se mueven —CONTEXT.md §18.1 los clava en la fila 30— así
        // que los dos píxeles que gana la cabeza salen de una fila del torso y otra de las
        // perneras. Sube la proporción de 8/26 (1/3,25) a 10/26 (1/2,6), que es lo que da el
        // aire cabezón de un cenital: la cara es lo único que distingue las ocho direcciones,
        // y a ocho píxeles no le cabe. Va por arquetipo, para verlo en uno antes que en todos.
        bool cabez = cfg.Cabezona;
        int HW = cabez ? 10 : 8, HH = cabez ? 10 : 8, h2 = HW/2, PH = cabez ? 7 : 8;

        // ── piernas ──
        int py = MG_ARR + (cabez ? 18 : 17) + oy, l1 = P_.p0, l2 = P_.p1;
        // La pernera de delante lleva su canto claro a la izquierda, que es de donde viene
        // la luz, y la de detrás se queda en sombra: sin eso las dos piernas son un bloque.
        if (PN.falda) {
            L.P(cx - compW/2 - 1, py - 1, compW + 2, 6, PN.b);
            L.P(cx - compW/2 - 1, py - 1, compW + 2, 1, PN.l);
            L.P(cx - compW/2 - 1, py + 4, compW + 2, 1, PN.s);
            L.P(cx - 3, py + 5, 2, 4, cfg.Piel);
            L.P(cx + 1, py + 5, 2, 4, cfg.Piel);
            L.P(cx - 3, py + 8, 2, 1, cfg.PielS);
            L.P(cx + 1, py + 8, 2, 1, cfg.PielS);
        } else if (lateral) {
            int dx = derV ? 1 : -1;
            L.P(cx - 2 - dx, py + l2, 3, PH - l2, PN.s);
            L.P(cx - 2 + dx, py + l1, 3, PH - l1, PN.b);
            L.P(cx - 2 + dx, py + l1, 1, PH - l1, PN.l);
            if (PN.corto) L.P(cx - 2 + dx, py + 4, 3, 4, cfg.Piel);
        } else {
            L.P(cx - 3, py + l1, 3, PH - l1, PN.b);
            L.P(cx, py + l2, 3, PH - l2, PN.s);
            L.P(cx - 3, py + l1, 1, PH - l1, PN.l);
            if (PN.tieneRaya) { L.P(cx - 3, py + l1, 1, PH - l1, PN.raya); L.P(cx + 2, py + l2, 1, PH - l2, PN.raya); }
            if (PN.corto) { L.P(cx - 3, py + 4, 3, 4, cfg.Piel); L.P(cx, py + 4, 3, 4, cfg.Piel); }
        }
        // Bajo falda los pies van donde la falda deja las piernas —dos píxeles— y no donde
        // los pone la plantilla lateral, que son tres y cuatro: descuadrados asomaba medio
        // zapato por fuera de la pernera.
        var zap = Calzado(cfg.Calzado);
        int zy = MG_ARR + 24 + oy;
        if (PN.falda) {
            L.P(cx - 3, zy, 2, 2, zap.b); L.P(cx + 1, zy, 2, 2, zap.b);
            L.P(cx - 3, zy + 1, 2, 1, zap.s); L.P(cx + 1, zy + 1, 2, 1, zap.s);
        } else if (lateral) {
            int dx = derV ? 1 : -1;
            L.P(cx - 2 - dx, zy, 3, 2, zap.b); L.P(cx - 2 + dx, zy, 4, 2, zap.b);
            L.P(cx - 2 - dx, zy + 1, 3, 1, zap.s); L.P(cx - 2 + dx, zy + 1, 4, 1, zap.s);
        } else {
            L.P(cx - 3, zy, 3, 2, zap.b); L.P(cx, zy, 3, 2, zap.b);
            L.P(cx - 3, zy + 1, 3, 1, zap.s); L.P(cx, zy + 1, 3, 1, zap.s);
        }

        // ── torso ──
        int ty = MG_ARR + (cabez ? 11 : 9) + oy + P_.yt, th = (T.largo ? 10 : 8) - (cabez ? 1 : 0);
        // Antes el tono claro eran las dos filas de arriba enteras: eso no es volumen, es
        // una franja, y el torso quedaba de cartón. La regla de ESTILO.md es 1 px claro
        // arriba y a la izquierda, base en el cuerpo y oscuro abajo y a la derecha. La fila
        // oscura de abajo hace además de dobladillo y despega el torso de las perneras.
        L.P(cx - hom/2, ty, hom, th, T.b);
        L.P(cx - hom/2, ty, hom, 1, T.l);
        L.P(cx - hom/2, ty, 1, th, T.l);
        L.P(cx + hom/2 - 1, ty, 1, th, T.s);
        L.P(cx - hom/2, ty + th - 1, hom, 1, T.s);
        if (T.tieneRaya) L.P(cx - hom/2, ty, 1, th, T.raya);
        if (T.peto) { L.P(cx - hom/2 + 1, ty + 2, hom - 2, 5, T.l); L.P(cx - 1, ty + 3, 2, 2, T.s); }
        if (T.bandas) { L.P(cx - hom/2, ty + 3, hom, 1, Paleta.Hueso); L.P(cx - hom/2, ty + 6, hom, 1, Paleta.Hueso); }
        if (T.mandil && !arr) L.P(cx - hom/2 + 1, ty + 2, hom - 2, th - 3, Paleta.Crema);
        if (T.placa && !arr) L.P(cx - hom/2 + 1, ty + 3, 2, 2, Paleta.Mostaza);
        // Dos píxeles de cuello bajo la barbilla. Sin ellos la cabeza se apoya en los
        // hombros sin transición y la figura parece un muñeco de dos piezas. Bajo capucha
        // no van: ahí lo que hay es tela.
        if (!T.capucha) L.P(cx - 1, ty, 2, 1, cfg.PielS);
        if (T.capucha) L.P(cx - hom/2, ty - 1, hom, 3, T.s);

        // ── brazos ──
        int b1 = P_.b0, b2 = P_.b1;
        // Sin mangas el brazo es piel, no tela, y conserva el mismo volumen que una
        // manga: el tono claro pasa a ser la piel y el oscuro su sombra. El brazo de
        // detrás va en sombra en las dos, que si no los dos brazos son la misma mancha.
        Color32 bB = T.sinMangas ? cfg.Piel : T.b;
        Color32 bL = T.sinMangas ? cfg.Piel : T.l;
        Color32 bS = T.sinMangas ? cfg.PielS : T.s;
        int manoY = T.corta ? ty + 4 : ty + 7;
        int bx1 = cx - hom/2 - 2, bx2 = cx + hom/2;
        if (P_.ataque > 0) {
            // El alcance cabe en el margen lateral, que con la celda de 24 son dos. Con
            // los cuatro de antes el puño se cortaba contra el canto.
            int ex = P_.ataque == 2 ? 1 : 0;
            if (derV || dir == AB) { L.P(bx2, ty + 2, 2 + ex, 3, bB); L.P(bx2 + 2 + ex, ty + 2, 2, 3, cfg.Piel); }
            else { L.P(bx1 - ex, ty + 2, 2 + ex, 3, bB); L.P(bx1 - ex - 2, ty + 2, 2, 3, cfg.Piel); }
            if (!lateral) L.P(bx1, ty + 2 + b2, 2, 6, bS);
        } else if (P_.apunta > 0) {
            if (derV) { L.P(bx2, ty + 3, 3, 2, bB); L.P(bx2 + 3, ty + 3, 2, 2, cfg.Piel); }
            else if (izqV) { L.P(bx1 - 1, ty + 3, 3, 2, bB); L.P(bx1 - 3, ty + 3, 2, 2, cfg.Piel); }
            else { L.P(bx2 - 1, ty + 2, 3, 5, bB); L.P(bx2 - 1, ty + 7, 3, 2, cfg.Piel); }
            if (!lateral) L.P(bx1, ty + 3, 2, 5, bS);
        } else if (lateral) {
            int bf = derV ? bx2 : bx1;
            L.P(bf, ty + 1 + b1, 2, 6, bL);
            L.P(bf, manoY + b1, 2, 2, cfg.Piel);
        } else {
            L.P(bx1, ty + 1 + b1, 2, 6, bL);
            L.P(bx2, ty + 1 + b2, 2, 6, bS);
            L.P(bx1, manoY + b1, 2, 2, cfg.Piel);
            L.P(bx2, manoY + b2, 2, 2, cfg.Piel);
        }

        // ── cabeza ──
        int hy = MG_ARR + 1 + oy + P_.yt;
        int hx = cx - h2, ey = hy + (cabez ? 5 : 4), my = hy + HH - (cabez ? 2 : 1), eo = cabez ? 3 : 2;
        L.P(hx, hy, HW, HH, cfg.Piel);
        L.P(hx + HW - 1, hy, 1, HH, cfg.PielS);
        L.P(hx, hy, HW, 1, cfg.PielS);
        if (dir == AB) { L.P(cx - eo, ey, 1, 2, Paleta.Negro); L.P(cx + eo - 1, ey, 1, 2, Paleta.Negro); L.P(cx - 1, my, 2, 1, cfg.PielS); }
        if (izqV) { L.P(hx, ey, 1, 2, Paleta.Negro); L.P(hx, hy, h2, HH, cfg.PielS); }
        if (derV) { L.P(hx + HW - 1, ey, 1, 2, Paleta.Negro); L.P(cx, hy, h2, HH, cfg.PielS); }
        if (frente) {
            if (derV) { L.P(cx, hy, h2, HH, cfg.Piel); L.P(cx, ey, 1, 2, Paleta.Negro); L.P(cx + 2, ey + 2, 1, 1, cfg.PielS); }
            else { L.P(cx - 1, hy, h2, HH, cfg.Piel); L.P(cx + 2, ey, 1, 2, Paleta.Negro); L.P(cx - 3, ey + 2, 1, 1, cfg.PielS); }
        }
        if (espalda) L.P(hx, hy, HW, HH, cfg.PielS);
        if (P_.herido && dir == AB) L.P(cx - eo, ey, 4, 1, Paleta.Sangre);

        // ── pelo ──
        Color32 pc = cfg.Pelo == "canoso" ? Paleta.Pelo5 : cfg.PeloCol;
        string est = cfg.Pelo;
        if (est != "calvo") {
            if (est == "rapado") L.P(cx - h2, hy - 1, HW, 3, pc);
            else if (est == "corto") { L.P(cx - h2, hy - 2, HW, 4, pc); if (!arr) L.P(cx - h2, hy + 2, 2, 2, pc); }
            else if (est == "melena") { L.P(cx - h2 - 1, hy - 2, HW + 2, 4, pc); L.P(cx - h2 - 1, hy + 2, 2, 7, pc); L.P(cx + h2 - 1, hy + 2, 2, 7, pc); }
            else if (est == "coleta") { L.P(cx - h2, hy - 2, HW, 4, pc); L.P(cx - h2 - 2, hy + 1, 2, 6, pc); }
            else if (est == "mono") { L.P(cx - h2, hy - 2, HW, 4, pc); L.P(cx - 2, hy - 4, 4, 2, pc); }
            else if (est == "afro") L.P(cx - h2 - 2, hy - 4, HW + 4, 7, pc);
            else L.P(cx - h2, hy - 2, HW, 4, pc);
            if (arr) L.P(cx - h2, hy - 2, HW, HH, pc);
        }

        // ── gorro ──
        switch (cfg.Gorro) {
            // Los gorros llevan su brillo de arriba a la izquierda como todo lo demás, y
            // todos se miden desde la cabeza (HW), no desde el ocho de siempre: con la
            // cabezona, un gorro clavado a ocho se queda de bufón.
            case "txapela":
                L.P(cx - h2, hy - 3, HW, 3, Paleta.Carbon); L.P(cx - h2, hy - 3, HW - 3, 1, Paleta.Gris);
                L.P(cx - h2 - 1, hy, HW + 2, 1, Paleta.Carbon); L.P(cx - h2 - 1, hy, 4, 1, Paleta.Gris);
                L.P(cx - 1, hy - 4, 2, 1, Paleta.Gris); break;
            case "gorra":
                L.P(cx - h2, hy - 3, HW, 3, cfg.GorroCol); L.P(cx - h2, hy - 3, HW - 3, 1, Paleta.Hueso);
                if (!arr) L.P(cx - h2, hy, HW - 2, 1, cfg.GorroCol); break;
            case "visera":
                L.P(cx - h2, hy - 2, HW, 2, cfg.GorroCol); L.P(cx - h2, hy - 2, HW - 3, 1, Paleta.Hueso);
                if (!arr) L.P(cx - h2 - 1, hy, HW - 1, 1, cfg.GorroCol); break;
            case "cascoObra":
                L.P(cx - h2 - 1, hy - 4, HW + 2, 5, Paleta.Mostaza); L.P(cx - h2 - 1, hy - 4, HW - 2, 1, Paleta.Hueso);
                L.P(cx + h2, hy - 4, 1, 5, Paleta.MostazaO); L.P(cx - h2 - 2, hy, HW + 4, 1, Paleta.MostazaO);
                L.P(cx - 1, hy - 4, 2, 1, Paleta.MostazaO); break;
            case "cascoMoto":
                L.P(cx - h2 - 1, hy - 3, HW + 2, 9, Paleta.Rojo); L.P(cx - h2 - 1, hy - 3, HW - 2, 1, Paleta.RojoL);
                L.P(cx + h2, hy - 3, 1, 9, Paleta.RojoO);
                if (!arr) L.P(cx - 3, hy + 2, 6, 3, Paleta.Carbon); break;
            case "lana":
                L.P(cx - 4, hy - 3, 8, 4, Paleta.RojoO); L.P(cx - 4, hy - 3, 5, 1, Paleta.Rojo);
                L.P(cx - 4, hy + 1, 8, 1, Paleta.Rojo); break;
            case "policia":
                L.P(cx - 4, hy - 3, 8, 3, Paleta.AzulO); L.P(cx - 4, hy - 3, 5, 1, Paleta.Azul);
                if (!arr) { L.P(cx - 5, hy, 8, 1, Paleta.AzulO); L.P(cx - 1, hy - 2, 2, 1, Paleta.Mostaza); }
                break;
            case "capucha":
                L.P(cx - 5, hy - 2, 10, 6, T.s); if (!arr) L.P(cx - 3, hy + 1, 6, 5, cfg.Piel); break;
        }

        // ── accesorio ──
        switch (cfg.Acces) {
            case "mochila":
                if (arr) L.P(cx - 4, ty + 1, 8, 7, Paleta.VerdeO);
                else { L.P(cx - hom/2 - 1, ty + 2, 2, 5, Paleta.VerdeO); L.P(cx + hom/2 - 1, ty + 2, 2, 5, Paleta.VerdeO); }
                break;
            // El bolso va colgado de un hombro y por eso no puede quedarse clavado en el
            // mismo costado en las ocho direcciones, que es lo que hacía: de espaldas se ve
            // al otro lado y la correa cruza entera; de perfil, solo el bulto que mira.
            case "bolso":
                if (arr) { L.P(cx - hom/2 - 1, ty + 5, 3, 3, Paleta.MaderaO); L.P(cx - hom/2, ty + 1, hom, 1, Paleta.Madera); }
                else if (izqV) { L.P(cx - hom/2 - 2, ty + 5, 3, 3, Paleta.MaderaO); L.P(cx - hom/2, ty + 1, hom/2, 1, Paleta.Madera); }
                else if (derV) { L.P(cx + hom/2 - 1, ty + 5, 3, 3, Paleta.MaderaO); L.P(cx, ty + 1, hom/2, 1, Paleta.Madera); }
                else { L.P(cx + hom/2 - 1, ty + 5, 3, 3, Paleta.MaderaO); L.P(cx - 1, ty + 1, hom/2, 1, Paleta.Madera); }
                break;
            case "bandolera":
                L.P(cx - hom/2, ty + 1, hom, 1, Paleta.MaderaO); L.P(cx - hom/2 - 1, ty + 5, 2, 3, Paleta.Madera); break;
            case "bufanda":
                L.P(cx - 4, ty - 1, 8, 2, Paleta.Rojo); L.P(cx + 1, ty + 1, 2, 4, Paleta.RojoO); break;
            // Las gafas tapan los ojos, así que van en las cinco direcciones en las que
            // se ve la cara y en ninguna de las tres de espaldas. Antes solo se dibujaban
            // mirando abajo: en las otras siete el tipo se las quitaba solo.
            case "gafas":
                if (!arr) {
                    if (izqV) { L.P(cx - h2, ey, 3, 2, Paleta.Carbon); L.P(cx - h2, ey, 3, 1, Paleta.Gris); }
                    else if (derV) { L.P(cx + h2 - 3, ey, 3, 2, Paleta.Carbon); L.P(cx + h2 - 3, ey, 3, 1, Paleta.Gris); }
                    else { L.P(cx - 3, ey, 6, 2, Paleta.Carbon); L.P(cx - 3, ey, 6, 1, Paleta.Gris); L.P(cx - 1, ey + 1, 2, 1, Paleta.Carbon); }
                }
                break;
            case "carrito":
                if (!arr) {
                    L.P(cx + 4, ty + 5, 5, 8, Paleta.RojoO); L.P(cx + 4, ty + 5, 5, 2, Paleta.Rojo);
                    L.P(cx + 5, ty + 13, 1, 2, Paleta.Carbon); L.P(cx + 7, ty + 13, 1, 2, Paleta.Carbon);
                }
                break;
        }

        if (P_.fog) {
            if (derV) L.P(cx + hom/2 + 2, ty + 2, 3, 3, Paleta.Mostaza);
            else if (izqV) L.P(cx - hom/2 - 3, ty + 2, 3, 3, Paleta.Mostaza);
            else L.P(cx + hom/2 - 1, ty + 9, 3, 3, Paleta.Mostaza);
        }
        // Contorno solo por fuera, como los iconos y por lo mismo: la gente cruza del
        // asfalto a la acera y de la acera al parque, y una cazadora gris sobre hormigón
        // gris sin borde se deshace. Las costuras de la ropa no llevan, que a 20 píxeles
        // taparían el dibujo.
        L.Contorno(Paleta.Negro);
        return L;
    }

    static readonly Dictionary<string, Sprite[]> Hojas = new Dictionary<string, Sprite[]>();

    /// <summary>Hacia dónde mira una de las ocho direcciones, en radianes.</summary>
    public static float AngDe(int d8) { return (2 - d8) * Mathf.PI / 4f; }

    /// <summary>Vestir al protagonista: cambia su arquetipo y tira su hoja para que la
    /// forja la vuelva a compilar con la ropa nueva.</summary>
    public static void Vestir(string torso, string piernas, string calzado, string gorro) {
        // Arquetipo es un struct: sin volver a meterlo en el diccionario se cambia una
        // copia y el protagonista sigue vestido igual.
        var a = Arq["protagonista"];
        a.Torso = torso; a.Piernas = piernas; a.Calzado = calzado;
        a.Gorro = gorro; a.GorroCol = Paleta.Carbon;
        Arq["protagonista"] = a;
        Hojas.Remove("protagonista");
    }

    /// <summary>Hoja de un arquetipo: 8 columnas × una fila por pose. Se compila la primera vez que hace falta.</summary>
    public static Sprite[] Hoja(string arq) {
        Sprite[] s;
        if (Hojas.TryGetValue(arq, out s)) return s;
        int aw = CW * NDIRS, ah = CH * NPOSES;
        var px = new Color32[aw * ah];
        var cfg = Arq[arq];
        for (int p = 0; p < NPOSES; p++)
            for (int d = 0; d < NDIRS; d++)
                Dibujar(cfg, (Pose)p, d).VolcarEn(px, aw, ah, d * CW, p * CH);
        Paleta.Cuantizar(px);
        var tex = Utiles.Textura(aw, ah, px);
        s = new Sprite[NPOSES * NDIRS];
        for (int p = 0; p < NPOSES; p++)
            for (int d = 0; d < NDIRS; d++) {
                int rx = d * CW;
                int ry = ah - (p + 1) * CH;   // la textura va de abajo arriba
                // El pivote es el de la caja de 20×26, corrido por el margen: si se deja
                // en el centro de la celda, el personaje flota sobre sus propios pies.
                s[p * NDIRS + d] = Utiles.Rebanada(tex, rx, ry, CW, CH, 10f + MG_X, 6f + MG_ABA);
            }
        Hojas[arq] = s;
        return s;
    }

    public static Sprite Frame(string arq, Pose pose, int d8) {
        return Hoja(arq)[(int)pose * NDIRS + d8];
    }

    /// <summary>Dirección de 8 sectores. En pantalla la Y crece hacia abajo, como en el prototipo.</summary>
    public static int Dir8(float dx, float dy) {
        int i = 2 - Mathf.RoundToInt(Mathf.Atan2(dy, dx) / (Mathf.PI / 4f));
        return ((i % 8) + 8) % 8;
    }
}

}

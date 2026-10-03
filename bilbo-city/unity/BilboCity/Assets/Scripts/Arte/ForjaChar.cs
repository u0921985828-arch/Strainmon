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

    struct Prenda { public Color32 b, s, l; public bool corta, capucha, peto, bandas, mandil, placa, largo; public Color32 raya; public bool tieneRaya; }
    static Dictionary<string,Prenda> _torsos;
    static Dictionary<string,Prenda> Torsos {
        get {
            if (_torsos != null) return _torsos;
            _torsos = new Dictionary<string,Prenda> {
                {"camisa",     new Prenda{ b=Paleta.Blanco, s=Paleta.Crema, l=Paleta.Blanco }},
                {"camisaRem",  new Prenda{ b=Paleta.Blanco, s=Paleta.Crema, l=Paleta.Blanco, corta=true }},
                {"chaqueta",   new Prenda{ b=Paleta.Azul, s=Paleta.AzulO, l=Paleta.AzulL }},
                {"cazadora",   new Prenda{ b=Paleta.Carbon, s=Paleta.Negro, l=Paleta.Gris }},
                {"sudadera",   new Prenda{ b=Paleta.GrisL, s=Paleta.Gris, l=Paleta.Acero, capucha=true }},
                {"chandal",    new Prenda{ b=Paleta.Verde, s=Paleta.VerdeO, l=Paleta.VerdeL, raya=Paleta.Hueso, tieneRaya=true }},
                {"mono",       new Prenda{ b=Paleta.AzulL, s=Paleta.Azul, l=Paleta.Acero, peto=true }},
                {"abrigo",     new Prenda{ b=Paleta.TejaO, s=Paleta.MaderaO, l=Paleta.Teja, largo=true }},
                {"gabardina",  new Prenda{ b=Paleta.Crema, s=Paleta.HormigonO, l=Paleta.Hueso, largo=true }},
                {"jersey",     new Prenda{ b=Paleta.RojoO, s=Paleta.Sangre, l=Paleta.Rojo }},
                {"bata",       new Prenda{ b=Paleta.Blanco, s=Paleta.Crema, l=Paleta.Blanco, largo=true }},
                {"uniforme",   new Prenda{ b=Paleta.AzulO, s=Paleta.Negro, l=Paleta.Azul, placa=true }},
                {"camiseta",   new Prenda{ b=Paleta.Mostaza, s=Paleta.MostazaO, l=Paleta.Mostaza, corta=true }},
                {"polo",       new Prenda{ b=Paleta.VerdeL, s=Paleta.Verde, l=Paleta.VerdeL, corta=true }},
                {"reflectante",new Prenda{ b=Paleta.Rojo, s=Paleta.RojoO, l=Paleta.Mostaza, corta=true, bandas=true }},
                {"delantal",   new Prenda{ b=Paleta.Carbon, s=Paleta.Negro, l=Paleta.Gris, corta=true, mandil=true }},
            };
            return _torsos;
        }
    }

    struct Pantalon { public Color32 b, s, raya; public bool tieneRaya, falda, corto; }
    static Dictionary<string,Pantalon> _piernas;
    static Dictionary<string,Pantalon> Piernas {
        get {
            if (_piernas != null) return _piernas;
            _piernas = new Dictionary<string,Pantalon> {
                {"vaquero",   new Pantalon{ b=Paleta.H("#3a4f6b"), s=Paleta.H("#2c3d53") }},
                {"vestir",    new Pantalon{ b=Paleta.Carbon, s=Paleta.Negro }},
                {"chandalP",  new Pantalon{ b=Paleta.VerdeO, s=Paleta.H("#24422a"), raya=Paleta.Hueso, tieneRaya=true }},
                {"monoP",     new Pantalon{ b=Paleta.AzulL, s=Paleta.Azul }},
                {"falda",     new Pantalon{ b=Paleta.Morado, s=Paleta.H("#443759"), falda=true }},
                {"short",     new Pantalon{ b=Paleta.Crema, s=Paleta.HormigonO, corto=true }},
                {"cargo",     new Pantalon{ b=Paleta.H("#5d5b45"), s=Paleta.H("#474535") }},
                {"uniformeP", new Pantalon{ b=Paleta.AzulO, s=Paleta.Negro }},
            };
            return _piernas;
        }
    }

    static Color32 Calzado(string k) {
        switch (k) {
            case "deportivas": return Paleta.Blanco;
            case "botas":      return Paleta.H("#3a2d22");
            case "katiuskas":  return Paleta.MostazaO;
            default:           return Paleta.Negro;
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
            Add(A("maton","corpulenta",2,"rapado",Paleta.Pelo1,"gorra",Paleta.Carbon,"cazadora","vaquero","deportivas","ninguno"));
            Add(A("maton2","media",4,"corto",Paleta.Pelo1,"capucha",Paleta.Carbon,"sudadera","chandalP","deportivas","ninguno"));
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
            Add(A("p3","media",1,"mono",Paleta.Pelo3,"ninguno",Paleta.Carbon,"jersey","falda","zapatos","carrito"));
            Add(A("p4","media",0,"canoso",Paleta.Pelo5,"txapela",Paleta.Carbon,"abrigo","vestir","zapatos","ninguno"));
            Add(A("p5","delgada",2,"corto",Paleta.Pelo1,"gorra",Paleta.Rojo,"chandal","chandalP","deportivas","mochila"));
            Add(A("p6","corpulenta",2,"corto",Paleta.Pelo2,"cascoObra",Paleta.Mostaza,"reflectante","cargo","botas","ninguno"));
            Add(A("p7","corpulenta",4,"rapado",Paleta.Pelo1,"lana",Paleta.RojoO,"reflectante","monoP","botas","ninguno"));
            Add(A("p8","delgada",3,"coleta",Paleta.Pelo1,"ninguno",Paleta.Carbon,"delantal","vestir","deportivas","ninguno"));
            // Los del mostrador. Se les ve mucho rato y de cerca, así que van con pinta
            // propia y no con la de un peatón cualquiera.
            Add(A("nerea","delgada",0,"melena",Paleta.Pelo2,"ninguno",Paleta.Carbon,"polo","vestir","deportivas","ninguno"));
            Add(A("patxi","corpulenta",1,"calvo",Paleta.Pelo1,"ninguno",Paleta.Carbon,"delantal","vestir","zapatos","ninguno"));
            Add(A("gorka","media",2,"corto",Paleta.Pelo1,"gorra",Paleta.Azul,"mono","monoP","botas","ninguno"));
            Add(A("maite","media",3,"coleta",Paleta.Pelo1,"ninguno",default(Color32),"chaqueta","falda","zapatos","ninguno"));
            // Más gente por la calle. Ocho tipos no llenan una ciudad de siete kilómetros:
            // a la tercera manzana ya has visto a todo el mundo dos veces.
            Add(A("p9", "media",   0,"canoso",Paleta.Pelo5,"ninguno",  Paleta.Carbon,"gabardina","vestir",  "zapatos",   "ninguno"));
            Add(A("p10","delgada", 1,"mono",  Paleta.Pelo2,"ninguno",  Paleta.Carbon,"chaqueta", "falda",   "zapatos",   "bolso"));
            Add(A("p11","delgada", 2,"corto", Paleta.Pelo1,"ninguno",  Paleta.Carbon,"sudadera", "vaquero", "deportivas","mochila"));
            Add(A("p12","corpulenta",1,"calvo",Paleta.Pelo1,"lana",    Paleta.Carbon,"jersey",   "cargo",   "botas",     "ninguno"));
            Add(A("p13","delgada", 0,"coleta",Paleta.Pelo3,"ninguno",  Paleta.Carbon,"camiseta", "short",   "deportivas","ninguno"));
            Add(A("p14","media",   0,"corto", Paleta.Pelo4,"visera",   Paleta.Blanco,"camisaRem","short",   "deportivas","mochila"));
            Add(A("p15","corpulenta",3,"rapado",Paleta.Pelo1,"cascoObra",Paleta.Carbon,"mono",   "monoP",   "botas",     "ninguno"));
            Add(A("p16","media",   1,"corto", Paleta.Pelo2,"ninguno",  Paleta.Carbon,"delantal", "vestir",  "zapatos",   "bandolera"));
            Add(A("p17","media",   4,"afro",  Paleta.Pelo1,"ninguno",  Paleta.Carbon,"polo",     "vaquero", "deportivas","bandolera"));
            Add(A("p18","media",   0,"melena",Paleta.Pelo5,"txapela",  Paleta.Carbon,"abrigo",   "vestir",  "zapatos",   "carrito"));
            return _arq;
        }
    }

    public static readonly string[] PeatonArq = { "p1","p2","p3","p4","p5","p6","p7","p8",
        "p9","p10","p11","p12","p13","p14","p15","p16","p17","p18" };
    /// <summary>Quién anda por dónde. En la Gran Vía hay gabardinas y en Zorrotzaurre monos
    /// de faena, y el plano ya nos dice cuál es cuál: no hay que repartir a nadie a mano.</summary>
    static readonly Dictionary<string,string[]> PeatonBarrio = new Dictionary<string,string[]> {
        {"senorial",  new[]{"p1","p2","p4","p9","p10","p16","p18"}},
        {"denso",     new[]{"p1","p3","p5","p8","p11","p16","p17","p18"}},
        {"bloques",   new[]{"p1","p3","p5","p8","p11","p12","p13","p17","p18"}},
        {"industrial",new[]{"p6","p7","p12","p15","p15","p5"}},
        {"abierto",   new[]{"p13","p13","p14","p11","p5","p12"}},
    };
    public static string ArqPeaton(Vector2 p) {
        var b = Ciudad.BarrioDe(Mathf.RoundToInt(p.x), Mathf.RoundToInt(p.y));
        string[] l;
        if (b != null && PeatonBarrio.TryGetValue(b.Estilo, out l)) return l[Utiles.RndI(0, l.Length-1)];
        return PeatonArq[Utiles.RndI(0, PeatonArq.Length-1)];
    }

    /// <summary>Los peinados que asoman por fuera de la cabeza y no caben en una hoja.</summary>
    static readonly HashSet<string> PelosGrandes = new HashSet<string> { "melena", "coleta", "mono", "afro" };

    /// <summary>
    /// Lo que va encima del cuerpo: pelo, gorro, accesorio y fogonazo. Está aparte porque
    /// se dibuja dos veces — sobre la figura forjada y sobre la silueta traída, que viene
    /// con el cuerpo pero no con el sombrero.
    ///
    /// Sobre una hoja traída no se usa esta: la figura dibujada tiene otra cabeza y otro
    /// tronco, y para eso está CapasSobreHoja.
    /// </summary>
    static void CapasEncima(Lienzo L, Arquetipo cfg, int cx, int hy, int ty, int hom,
                            int dir, bool arr, Prenda T, bool izqV, bool derV, bool fog) {
        // ── pelo ──
        Color32 pc = cfg.Pelo == "canoso" ? Paleta.Pelo5 : cfg.PeloCol;
        string est = cfg.Pelo;
        if (est != "calvo") {
            if (est == "rapado") L.P(cx - 4, hy - 1, 8, 3, pc);
            else if (est == "corto") { L.P(cx - 4, hy - 2, 8, 4, pc); if (!arr) L.P(cx - 4, hy + 2, 2, 2, pc); }
            else if (est == "melena") { L.P(cx - 5, hy - 2, 10, 4, pc); L.P(cx - 5, hy + 2, 2, 7, pc); L.P(cx + 3, hy + 2, 2, 7, pc); }
            else if (est == "coleta") { L.P(cx - 4, hy - 2, 8, 4, pc); L.P(cx - 6, hy + 1, 2, 6, pc); }
            else if (est == "mono") { L.P(cx - 4, hy - 2, 8, 4, pc); L.P(cx - 2, hy - 4, 4, 2, pc); }
            else if (est == "afro") L.P(cx - 6, hy - 4, 12, 7, pc);
            else L.P(cx - 4, hy - 2, 8, 4, pc);
            if (arr) L.P(cx - 4, hy - 2, 8, 8, pc);
        }

        // ── gorro ──
        switch (cfg.Gorro) {
            // Los gorros llevan su brillo de arriba a la izquierda como todo lo demás. Y
            // ninguno pasa de diez píxeles de ancho: la cabeza mide ocho, y con el contorno
            // alrededor un gorro de doce deja de parecer un gorro y parece una nube.
            case "txapela":
                L.P(cx - 4, hy - 3, 8, 3, Paleta.Carbon); L.P(cx - 4, hy - 3, 5, 1, Paleta.Gris);
                L.P(cx - 5, hy, 10, 1, Paleta.Carbon); L.P(cx - 5, hy, 4, 1, Paleta.Gris);
                L.P(cx - 1, hy - 4, 2, 1, Paleta.Gris); break;
            case "gorra":
                L.P(cx - 4, hy - 3, 8, 3, cfg.GorroCol); L.P(cx - 4, hy - 3, 5, 1, Paleta.Hueso);
                if (!arr) L.P(cx - 4, hy, 6, 1, cfg.GorroCol); break;
            case "visera":
                L.P(cx - 4, hy - 2, 8, 2, cfg.GorroCol); L.P(cx - 4, hy - 2, 5, 1, Paleta.Hueso);
                if (!arr) L.P(cx - 5, hy, 7, 1, cfg.GorroCol); break;
            case "cascoObra":
                L.P(cx - 5, hy - 4, 10, 5, Paleta.Mostaza); L.P(cx - 5, hy - 4, 6, 1, Paleta.Hueso);
                L.P(cx + 4, hy - 4, 1, 5, Paleta.MostazaO); L.P(cx - 6, hy, 12, 1, Paleta.MostazaO);
                L.P(cx - 1, hy - 4, 2, 1, Paleta.MostazaO); break;
            case "cascoMoto":
                L.P(cx - 5, hy - 3, 10, 9, Paleta.Rojo); L.P(cx - 5, hy - 3, 6, 1, Paleta.RojoL);
                L.P(cx + 4, hy - 3, 1, 9, Paleta.RojoO);
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
            case "bolso":
                L.P(cx + hom/2 - 1, ty + 5, 3, 3, Paleta.MaderaO); L.P(cx - 1, ty + 1, hom/2, 1, Paleta.Madera); break;
            case "bandolera":
                L.P(cx - hom/2, ty + 1, hom, 1, Paleta.MaderaO); L.P(cx - hom/2 - 1, ty + 5, 2, 3, Paleta.Madera); break;
            case "bufanda":
                L.P(cx - 4, ty - 1, 8, 2, Paleta.Rojo); L.P(cx + 1, ty + 1, 2, 4, Paleta.RojoO); break;
            case "gafas":
                if (dir == AB) { L.P(cx - 3, hy + 4, 2, 2, Paleta.Carbon); L.P(cx + 1, hy + 4, 2, 2, Paleta.Carbon); L.P(cx - 1, hy + 4, 2, 1, Paleta.Carbon); }
                break;
            case "carrito":
                if (!arr) {
                    L.P(cx + 4, ty + 5, 5, 8, Paleta.RojoO); L.P(cx + 4, ty + 5, 5, 2, Paleta.Rojo);
                    L.P(cx + 5, ty + 13, 1, 2, Paleta.Carbon); L.P(cx + 7, ty + 13, 1, 2, Paleta.Carbon);
                }
                break;
        }

        if (fog) {
            if (derV) L.P(cx + hom/2 + 2, ty + 2, 3, 3, Paleta.Mostaza);
            else if (izqV) L.P(cx - hom/2 - 3, ty + 2, 3, 3, Paleta.Mostaza);
            else L.P(cx + hom/2 - 1, ty + 9, 3, 3, Paleta.Mostaza);
        }
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

        // ── piernas ──
        int py = MG_ARR + 17 + oy, l1 = P_.p0, l2 = P_.p1;
        if (PN.falda) {
            L.P(cx - compW/2 - 1, py - 1, compW + 2, 6, PN.b);
            L.P(cx - compW/2 - 1, py + 4, compW + 2, 1, PN.s);
            L.P(cx - 3, py + 5, 2, 4, cfg.Piel);
            L.P(cx + 1, py + 5, 2, 4, cfg.Piel);
        } else if (lateral) {
            int dx = derV ? 1 : -1;
            L.P(cx - 2 - dx, py + l2, 3, 8 - l2, PN.s);
            L.P(cx - 2 + dx, py + l1, 3, 8 - l1, PN.b);
            if (PN.corto) L.P(cx - 2 + dx, py + 4, 3, 4, cfg.Piel);
        } else {
            L.P(cx - 3, py + l1, 3, 8 - l1, PN.b);
            L.P(cx, py + l2, 3, 8 - l2, PN.s);
            if (PN.tieneRaya) { L.P(cx - 3, py + l1, 1, 8 - l1, PN.raya); L.P(cx + 2, py + l2, 1, 8 - l2, PN.raya); }
            if (PN.corto) { L.P(cx - 3, py + 4, 3, 4, cfg.Piel); L.P(cx, py + 4, 3, 4, cfg.Piel); }
        }
        var zap = Calzado(cfg.Calzado);
        int zy = MG_ARR + 24 + oy;
        if (lateral) { int dx = derV ? 1 : -1; L.P(cx - 2 - dx, zy, 3, 2, zap); L.P(cx - 2 + dx, zy, 4, 2, zap); }
        else { L.P(cx - 3, zy, 3, 2, zap); L.P(cx, zy, 3, 2, zap); }

        // ── torso ──
        int ty = MG_ARR + 9 + oy + P_.yt, th = T.largo ? 10 : 8;
        L.P(cx - hom/2, ty, hom, th, T.b);
        L.P(cx - hom/2, ty, hom, 2, T.l);
        L.P(cx + hom/2 - 1, ty, 1, th, T.s);
        if (T.tieneRaya) L.P(cx - hom/2, ty, 1, th, T.raya);
        if (T.peto) { L.P(cx - hom/2 + 1, ty + 2, hom - 2, 5, T.l); L.P(cx - 1, ty + 3, 2, 2, T.s); }
        if (T.bandas) { L.P(cx - hom/2, ty + 3, hom, 1, Paleta.Hueso); L.P(cx - hom/2, ty + 6, hom, 1, Paleta.Hueso); }
        if (T.mandil && !arr) L.P(cx - hom/2 + 1, ty + 2, hom - 2, th - 1, Paleta.Crema);
        if (T.placa && !arr) L.P(cx - hom/2 + 1, ty + 3, 2, 2, Paleta.Mostaza);
        if (T.capucha) L.P(cx - hom/2, ty - 1, hom, 3, T.s);

        // ── brazos ──
        int b1 = P_.b0, b2 = P_.b1;
        int manoY = T.corta ? ty + 4 : ty + 7;
        int bx1 = cx - hom/2 - 2, bx2 = cx + hom/2;
        if (P_.ataque > 0) {
            // El alcance cabe en el margen lateral, que con la celda de 24 son dos. Con
            // los cuatro de antes el puño se cortaba contra el canto.
            int ex = P_.ataque == 2 ? 1 : 0;
            if (derV || dir == AB) { L.P(bx2, ty + 2, 2 + ex, 3, T.b); L.P(bx2 + 2 + ex, ty + 2, 2, 3, cfg.Piel); }
            else { L.P(bx1 - ex, ty + 2, 2 + ex, 3, T.b); L.P(bx1 - ex - 2, ty + 2, 2, 3, cfg.Piel); }
            if (!lateral) L.P(bx1, ty + 2 + b2, 2, 6, T.s);
        } else if (P_.apunta > 0) {
            if (derV) { L.P(bx2, ty + 3, 3, 2, T.b); L.P(bx2 + 3, ty + 3, 2, 2, cfg.Piel); }
            else if (izqV) { L.P(bx1 - 1, ty + 3, 3, 2, T.b); L.P(bx1 - 3, ty + 3, 2, 2, cfg.Piel); }
            else { L.P(bx2 - 1, ty + 2, 3, 5, T.b); L.P(bx2 - 1, ty + 7, 3, 2, cfg.Piel); }
            if (!lateral) L.P(bx1, ty + 3, 2, 5, T.s);
        } else if (lateral) {
            int bf = derV ? bx2 : bx1;
            L.P(bf, ty + 1 + b1, 2, 6, T.l);
            L.P(bf, manoY + b1, 2, 2, cfg.Piel);
        } else {
            L.P(bx1, ty + 1 + b1, 2, 6, T.l);
            L.P(bx2, ty + 1 + b2, 2, 6, T.s);
            L.P(bx1, manoY + b1, 2, 2, cfg.Piel);
            L.P(bx2, manoY + b2, 2, 2, cfg.Piel);
        }

        // ── cabeza ──
        int hy = MG_ARR + 1 + oy + P_.yt;
        L.P(cx - 4, hy, 8, 8, cfg.Piel);
        L.P(cx + 3, hy, 1, 8, cfg.PielS);
        L.P(cx - 4, hy, 8, 1, cfg.PielS);
        if (dir == AB) { L.P(cx - 2, hy + 4, 1, 2, Paleta.Negro); L.P(cx + 1, hy + 4, 1, 2, Paleta.Negro); L.P(cx - 1, hy + 7, 2, 1, cfg.PielS); }
        if (izqV) { L.P(cx - 4, hy + 4, 1, 2, Paleta.Negro); L.P(cx - 4, hy, 4, 8, cfg.PielS); }
        if (derV) { L.P(cx + 3, hy + 4, 1, 2, Paleta.Negro); L.P(cx, hy, 4, 8, cfg.PielS); }
        if (frente) {
            if (derV) { L.P(cx, hy, 4, 8, cfg.Piel); L.P(cx, hy + 4, 1, 2, Paleta.Negro); L.P(cx + 2, hy + 6, 1, 1, cfg.PielS); }
            else { L.P(cx - 1, hy, 4, 8, cfg.Piel); L.P(cx + 2, hy + 4, 1, 2, Paleta.Negro); L.P(cx - 3, hy + 6, 1, 1, cfg.PielS); }
        }
        if (espalda) L.P(cx - 4, hy, 8, 8, cfg.PielS);
        if (P_.herido && dir == AB) L.P(cx - 2, hy + 4, 4, 1, Paleta.Sangre);

        CapasEncima(L, cfg, cx, hy, ty, hom, dir, arr, T, izqV, derV, P_.fog);

        // Contorno solo por fuera, como los iconos y por lo mismo: la gente cruza del
        // asfalto a la acera y de la acera al parque, y una cazadora gris sobre hormigón
        // gris sin borde se deshace. Las costuras de la ropa no llevan, que a 20 píxeles
        // taparían el dibujo.
        L.Contorno(Paleta.Negro);
        return L;
    }

    /*══════════ HOJAS DE SILUETA: UNA HOJA, MUCHOS VECINOS ══════════*/
    /* Una hoja no se dibuja para un personaje: se dibuja para una silueta, y de esa
       silueta salen todos los que la comparten. Viene pintada con colores de plantilla
       —cada parte del cuerpo en su propia rampa de la paleta— y cada arquetipo la repinta
       cambiando índices por índices: la chaqueta al color de su chaqueta, el pantalón al
       suyo, la piel a la suya. Encima se le forja el pelo largo, el gorro y la bolsa, que
       es justo lo que habría multiplicado las hojas por setenta si viniera dibujado.

       Siete hojas visten a los treinta y cuatro arquetipos, y el vecino número treinta y
       cinco no cuesta ni un dibujo más. Es el mismo camino que sigue el prototipo. */

    /// <summary>
    /// De la ropa de un arquetipo a la hoja que le sirve. Lo que decide es la silueta, no
    /// el color: manga larga o corta, abrigo, capucha; pantalón, falda o pantalón corto.
    /// Si la hoja exacta no está, se prueba con la más parecida, así que una sola ya viste
    /// a todo el mundo y tenerlas todas afina.
    /// </summary>
    public static string SetDe(Arquetipo cfg) {
        var T = Torsos[cfg.Torso];
        var PN = Piernas[cfg.Piernas];
        string arriba = T.largo ? "abrigo" : T.capucha ? "capucha" : T.corta ? "corto" : "largo";
        string abajo = PN.falda ? "falda" : PN.corto ? "short" : "pantalon";
        var bases = Siluetas.Bases;
        foreach (var k in new[] { arriba + "_" + abajo, arriba + "_pantalon",
                                  "largo_" + abajo, "largo_pantalon" })
            if (bases.ContainsKey(k)) return k;
        return null;
    }

    /// <summary>
    /// El índice de un color en la paleta. Los tonos de piel oscura de la forja no están
    /// en la lista —se cuantizan al pintar—, así que aquí se cuantizan igual antes de
    /// indexar, o el repintado dejaría la cara en blanco.
    /// </summary>
    static int IndiceDe(Color32 c) {
        var pal = Paleta.Lista;
        int mejor = 0, md = int.MaxValue;
        for (int k = 0; k < pal.Length; k++) {
            if (pal[k].r == c.r && pal[k].g == c.g && pal[k].b == c.b) return k;
            int dr = pal[k].r - c.r, dg = pal[k].g - c.g, db = pal[k].b - c.b;
            int d = dr*dr + dg*dg + db*db;
            if (d < md) { md = d; mejor = k; }
        }
        return mejor;
    }

    /// <summary>
    /// La tabla de repintado de un arquetipo: 256 bytes que dicen en qué se convierte cada
    /// índice de la hoja de plantilla. Una rampa de tres tonos que va a parar a una de dos
    /// se reparte proporcionalmente; la de un solo color aplana.
    /// </summary>
    static byte[] LutDe(Arquetipo cfg) {
        var lut = new byte[256];
        for (int i = 0; i < 256; i++) lut[i] = (byte)i;
        System.Action<string, Color32[]> pinta = (nombre, cols) => {
            int[] rampa;
            if (!Siluetas.Rampas.TryGetValue(nombre, out rampa)) return;
            if (rampa.Length == 0 || cols.Length == 0) return;
            int n = rampa.Length, m = cols.Length;
            for (int i = 0; i < n; i++) {
                // El mismo redondeo que el prototipo, y con el mismo cuidado: Math.Round
                // de .NET redondea al par y Math.round de JS hacia arriba.
                int j = m < 2 ? 0 : Mathf.FloorToInt(i * (m - 1) / (float)(n - 1) + 0.5f);
                lut[rampa[i]] = (byte)(1 + IndiceDe(cols[j]));
            }
        };
        var T = Torsos[cfg.Torso];
        var PN = Piernas[cfg.Piernas];
        pinta("piel", new[] { cfg.PielS, cfg.Piel });
        // Calvo no necesita hoja propia: se le manda el pelo al color de su piel y desaparece.
        pinta("pelo", cfg.Pelo == "calvo" ? new[] { cfg.PielS, cfg.Piel }
                    : new[] { cfg.Pelo == "canoso" ? Paleta.Pelo5 : cfg.PeloCol });
        pinta("torso", new[] { T.s, T.b, T.l });
        pinta("piernas", new[] { PN.s, PN.b });
        pinta("calzado", new[] { Calzado(cfg.Calzado) });
        return lut;
    }

    /// <summary>
    /// Dónde tiene la cabeza esta casilla de la hoja: la caja de verdad, no la de la
    /// forja. Se mide desde la coronilla hasta que el ancho cae a la mitad, que es el
    /// cuello. Hace falta porque la cabeza dibujada es más pequeña que la forjada —seis
    /// píxeles de cara contra ocho— y va tres filas más arriba: nada de lo que va encima
    /// se puede colocar por una coordenada fija.
    /// </summary>
    struct Caja { public int x0, y0, x1, y1; public int W { get { return x1-x0; } } public int H { get { return y1-y0; } } }

    static bool CajaCabeza(byte[] bytes, int w, int cw, int ch, int d, int fy, bool[] masc,
                           out Caja caja) {
        caja = new Caja();
        var an = new int[ch]; var iz = new int[ch]; var de = new int[ch];
        for (int y = 0; y < ch; y++) {
            int f = (fy*ch + y)*w + d*cw, n = 0, a = cw, b = -1;
            for (int x = 0; x < cw; x++) if (masc[bytes[f + x]]) { n++; if (x < a) a = x; if (x > b) b = x; }
            an[y] = n; iz[y] = a; de[y] = b;
        }
        int y0 = -1;
        for (int y = 0; y < ch && y0 < 0; y++) if (an[y] > 0) y0 = y;
        if (y0 < 0) return false;
        int max = 0, yM = y0;
        for (int y = y0; y < ch && an[y] > 0; y++) if (an[y] > max) { max = an[y]; yM = y; }
        int y1 = yM;
        while (y1 + 1 < ch && an[y1 + 1] >= max/2f) y1++;
        caja = new Caja { x0 = iz[yM], x1 = de[yM] + 1, y0 = y0, y1 = y1 + 1 };
        return true;
    }

    /// <summary>La caja de lo que pinte una rampa en esta casilla. Para el tronco, que es
    /// donde van la bolsa, la bufanda y el fogonazo.</summary>
    static bool CajaRampa(byte[] bytes, int w, int cw, int ch, int d, int fy, bool[] masc,
                          out Caja caja) {
        int x0 = cw, y0 = ch, x1 = -1, y1 = -1;
        for (int y = 0; y < ch; y++) {
            int f = (fy*ch + y)*w + d*cw;
            for (int x = 0; x < cw; x++) if (masc[bytes[f + x]]) {
                if (x < x0) x0 = x; if (x > x1) x1 = x;
                if (y < y0) y0 = y; if (y > y1) y1 = y;
            }
        }
        caja = new Caja { x0 = x0, y0 = y0, x1 = x1 + 1, y1 = y1 + 1 };
        return x1 >= 0;
    }

    /// <summary>
    /// Lo que va encima de una hoja traída, dibujado sobre la cabeza y el tronco que TRAE
    /// la hoja y no sobre los de la forja. Trasladar los de la forja fue el primer intento
    /// y no vale: una txapela pensada para una cabeza de ocho píxeles le tapa los ojos a
    /// una de seis, y una bolsa colgada del pecho de la forja se le sube al cuello a la
    /// silueta. Aquí todo va en fracciones de la caja medida, que es como se dibuja el
    /// resto del arte del juego.
    ///
    /// No lleva contorno propio: se pinta aparte y Pegar/contorno se lo dan solo por donde
    /// asoma. Con un contorno por capa, el gorro salía con su propio marco negro por
    /// dentro y parecía una boina de luto.
    /// </summary>
    static void CapasSobreHoja(Lienzo L, Arquetipo cfg, Caja cab, bool hayTor, Caja tor,
                               int d8, Prenda T, bool fog) {
        int dir = BaseDir[d8];
        bool arr = dir == AR || Espalda[d8], derV = dir == DE, izqV = dir == IZ;
        int hx = cab.x0, hw = cab.W, hy = cab.y0, hh = cab.H, hcx = hx + hw/2;
        int ala = Mathf.Max(2, R(hh*0.34f));         // lo que baja un gorro sobre la frente
        Color32 pc = cfg.Pelo == "canoso" ? Paleta.Pelo5 : cfg.PeloCol;

        // Solo los peinados que se salen de la cabeza, y solo el añadido: el corto y el
        // rapado ya vienen en la hoja, y repintar la coronilla de un color plano se lleva
        // por delante el volumen que trae dibujado.
        string est = cfg.Pelo;
        if (PelosGrandes.Contains(est)) {
            if (est == "melena") {
                L.P(hx-1, hy + R(hh*.35f), 2, R(hh*.9f), pc);
                L.P(hx+hw-1, hy + R(hh*.35f), 2, R(hh*.9f), pc);
            } else if (est == "coleta") L.P(hx-2, hy + R(hh*.25f), 2, R(hh*.8f), pc);
            else if (est == "mono") L.P(hcx-1, hy-2, 2, 3, pc);
            else if (est == "afro") {
                L.P(hx-2, hy-1, hw+4, R(hh*.6f)+1, pc);
                L.P(hx-2, hy-1, R((hw+4)*.5f), 1, Igual(Paleta.Pelo5, pc) ? Paleta.Pelo4 : pc);
            }
        }

        // Cada gorro se mide contra la cabeza que hay debajo. Y ninguno pasa de la cabeza
        // más dos píxeles a cada lado: más ancho deja de parecer un gorro y parece una nube.
        switch (cfg.Gorro) {
            case "txapela":
                L.P(hx-1, hy, hw+2, ala, Paleta.Carbon); L.P(hx-1, hy, R((hw+2)*.6f), 1, Paleta.Gris);
                L.P(hx-2, hy+ala, hw+4, 1, Paleta.Carbon); L.P(hx-2, hy+ala, R((hw+4)*.4f), 1, Paleta.Gris);
                break;
            case "gorra":
                L.P(hx-1, hy, hw+2, ala, cfg.GorroCol); L.P(hx-1, hy, R((hw+2)*.6f), 1, Paleta.Hueso);
                if (!arr) L.P(hx-1, hy+ala, R(hw*.85f), 1, cfg.GorroCol);
                break;
            case "visera":
                L.P(hx-1, hy, hw+2, Mathf.Max(1, ala-1), cfg.GorroCol);
                L.P(hx-1, hy, R((hw+2)*.6f), 1, Paleta.Hueso);
                if (!arr) L.P(hx-2, hy+ala-1, R(hw*.9f), 1, cfg.GorroCol);
                break;
            case "cascoObra":
                L.P(hx-2, hy-1, hw+4, ala+1, Paleta.Mostaza);
                L.P(hx-2, hy-1, R((hw+4)*.6f), 1, Paleta.Hueso);
                L.P(hx+hw+1, hy-1, 1, ala+1, Paleta.MostazaO);
                L.P(hx-3, hy+ala, hw+6, 1, Paleta.MostazaO);
                break;
            case "cascoMoto":
                L.P(hx-2, hy-1, hw+4, hh+1, Paleta.Rojo);
                L.P(hx-2, hy-1, R((hw+4)*.6f), 1, Paleta.RojoL);
                L.P(hx+hw+1, hy-1, 1, hh+1, Paleta.RojoO);
                if (!arr) L.P(hx, hy + R(hh*.45f), hw, Mathf.Max(2, R(hh*.35f)), Paleta.Carbon);
                break;
            case "lana":
                L.P(hx-1, hy, hw+2, ala+1, Paleta.RojoO); L.P(hx-1, hy, R((hw+2)*.6f), 1, Paleta.Rojo);
                L.P(hx-1, hy+ala, hw+2, 1, Paleta.Rojo);
                break;
            case "policia":
                L.P(hx-1, hy, hw+2, ala, Paleta.AzulO); L.P(hx-1, hy, R((hw+2)*.6f), 1, Paleta.Azul);
                if (!arr) { L.P(hx-2, hy+ala, R(hw*.9f), 1, Paleta.AzulO); L.P(hcx-1, hy+1, 2, 1, Paleta.Mostaza); }
                break;
            case "capucha":
                L.P(hx-2, hy-1, hw+4, hh+2, T.s);
                if (!arr) L.P(hx, hy + R(hh*.3f), hw, hh - R(hh*.3f), cfg.Piel);
                break;
        }

        if (!hayTor) return;
        int tx = tor.x0, tw = tor.W, ty = tor.y0, th = tor.H, tcx = tx + tw/2;

        // Lo que distingue una prenda de otra dentro de la misma silueta. La hoja trae el
        // corte —manga larga, abrigo, capucha— pero no la placa del uniforme ni las bandas
        // del chaleco, y sin eso un ertzaina es un señor de azul y un peón de obra un señor
        // de rojo. Va aquí y no en la hoja a propósito: son cuatro rectángulos y meterlos
        // dentro multiplicaría las siluetas por cada prenda.
        if (T.bandas) { L.P(tx, ty + R(th*.34f), tw, 1, Paleta.Hueso); L.P(tx, ty + R(th*.60f), tw, 1, Paleta.Hueso); }
        if (T.tieneRaya) { L.P(tx, ty+1, 1, th-2, T.raya); L.P(tx+tw-1, ty+1, 1, th-2, T.raya); }
        if (T.peto) { L.P(tx + R(tw*.24f), ty + R(th*.14f), R(tw*.52f), R(th*.44f), T.l);
                      L.P(tcx-1, ty + R(th*.28f), 2, 2, T.s); }
        if (T.mandil && !arr) L.P(tx + R(tw*.2f), ty + R(th*.3f), R(tw*.6f), R(th*.68f), Paleta.Crema);
        if (T.placa && !arr) L.P(tx + R(tw*.22f), ty + R(th*.26f), 2, 2, Paleta.Mostaza);

        switch (cfg.Acces) {
            case "mochila":
                if (arr) L.P(tx+1, ty+1, tw-2, R(th*.7f), Paleta.VerdeO);
                else { L.P(tx-1, ty + R(th*.15f), 2, R(th*.5f), Paleta.VerdeO);
                       L.P(tx+tw-1, ty + R(th*.15f), 2, R(th*.5f), Paleta.VerdeO); }
                break;
            case "bolso":
                L.P(tx+tw-1, ty + R(th*.55f), 3, 3, Paleta.MaderaO);
                L.P(tcx-1, ty+1, R(tw*.5f), 1, Paleta.Madera);
                break;
            case "bandolera":
                L.P(tx, ty+1, tw, 1, Paleta.MaderaO); L.P(tx-1, ty + R(th*.5f), 2, 3, Paleta.Madera);
                break;
            case "bufanda":
                L.P(hx-1, ty-1, hw+2, 2, Paleta.Rojo);
                L.P(hx + R(hw*.55f), ty+1, 2, R(th*.4f), Paleta.RojoO);
                break;
            case "carrito":
                if (!arr) {
                    L.P(tx+tw+1, ty + R(th*.35f), 5, 8, Paleta.RojoO);
                    L.P(tx+tw+1, ty + R(th*.35f), 5, 2, Paleta.Rojo);
                    L.P(tx+tw+2, ty + R(th*.35f) + 8, 1, 2, Paleta.Carbon);
                    L.P(tx+tw+4, ty + R(th*.35f) + 8, 1, 2, Paleta.Carbon);
                }
                break;
        }
        // El fogonazo sale del cañón, y el cañón está donde acaba la mano.
        if (fog) {
            if (derV) L.P(tx+tw+1, ty + R(th*.2f), 3, 3, Paleta.Mostaza);
            else if (izqV) L.P(tx-4, ty + R(th*.2f), 3, 3, Paleta.Mostaza);
            else L.P(tx+tw-2, ty + R(th*.75f), 3, 3, Paleta.Mostaza);
        }
    }

    /// <summary>
    /// La silueta no trae cara: el SVG dibuja el bulto de la cabeza y se acaba ahí. A
    /// veinte píxeles los ojos son lo único que separa a un vecino de un maniquí. Se
    /// ponen al final, encima del gorro, porque una capucha o un casco redibujan la cara
    /// entera debajo, y sin contorno: dos píxeles negros con marco negro son una mancha.
    /// </summary>
    static void CaraEncima(Lienzo L, Arquetipo cfg, Caja cab, int d8) {
        int dir = BaseDir[d8];
        if (dir == AR || Espalda[d8]) return;          // de espaldas no hay ojos
        if (cfg.Gorro == "cascoMoto") return;          // detrás de la pantalla no se ve nada
        int hx = cab.x0, hw = cab.W, hy = cab.y0, hh = cab.H;
        int y = hy + R(hh*.55f), alto = Mathf.Max(1, R(hh*.2f));
        System.Action<float> ojo = f => L.P(hx + R(hw*f), y, 1, alto, Paleta.Negro);
        if (dir == AB) { ojo(.22f); ojo(.68f); }
        else if (Frente[d8]) { if (dir == DE) { ojo(.46f); ojo(.82f); } else { ojo(.08f); ojo(.44f); } }
        else ojo(dir == DE ? .78f : .12f);
        if (cfg.Acces == "gafas" && dir == AB) {
            L.P(hx + R(hw*.14f), y, R(hw*.3f), alto, Paleta.Carbon);
            L.P(hx + R(hw*.6f), y, R(hw*.3f), alto, Paleta.Carbon);
            L.P(hx + R(hw*.44f), y, R(hw*.16f), 1, Paleta.Carbon);
        }
    }

    /// <summary>
    /// Tres tonos alrededor de un color, dentro de su propia familia de la paleta.
    /// El pelo y el calzado se pedían con un color solo, y eso aplanaba la hoja: los
    /// cuatro tonos que trae dibujado un pelo acababan todos en el mismo y la melena se
    /// quedaba en una mancha recortada. Las familias de CONTEXT.md §18.6 son de ocho
    /// tonos en fila, así que la rampa está hecha ya; solo hay que quedarse con el trozo.
    /// </summary>
    static Color32[] RampaFamilia(Color32 c, int n) {
        int i = IndiceDe(c);
        if (i >= 48 || n < 2) return new[] { c };
        int f = i >> 3, t = i & 7;
        var pal = Paleta.Lista;
        var r = new Color32[n];
        for (int k = 0; k < n; k++) r[k] = pal[f*8 + Mathf.Clamp(t - 1 + k, 0, 7)];
        return r;
    }

    static int R(float v) { return Mathf.FloorToInt(v + 0.5f); }
    static bool Igual(Color32 a, Color32 b) { return a.r == b.r && a.g == b.g && a.b == b.b; }

    /// <summary>
    /// La hoja de un arquetipo a partir de la silueta que le toca: repintar y poner
    /// encima. Devuelve null si no hay silueta que le sirva, y entonces se forja.
    /// </summary>
    static Color32[] HojaDeSilueta(string arq, out int aw, out int ah) {
        aw = 0; ah = 0;
        Arquetipo cfg;
        if (!Arq.TryGetValue(arq, out cfg)) return null;
        // La celda de la hoja tiene que ser la de la forja. No se comprueba aquí porque
        // son dos constantes —el generador lee la celda del propio HTML—; lo comprueban
        // el tamaño de cada base en Siluetas.Bases y herramientas/plano/siluetas.py.
        string s = SetDe(cfg);
        if (s == null) return null;
        var bas = Siluetas.Bases[s];
        var T = Torsos[cfg.Torso];

        int w = CW * NDIRS, h = CH * NPOSES;
        var lut = LutDe(cfg);
        var pal = Paleta.Lista;
        var atlas = new Lienzo(w, h);
        for (int i = 0; i < bas.Length; i++) {
            int v = lut[bas[i]];
            if (v == 0) continue;                    // 0 es transparente, no un color
            atlas.Px[i] = pal[(v - 1) % pal.Length];
        }
        var masc = new bool[256]; var mTor = new bool[256];
        foreach (var r in new[] { "piel", "pelo" }) {
            int[] idx;
            if (Siluetas.Rampas.TryGetValue(r, out idx)) foreach (var v in idx) masc[v] = true;
        }
        { int[] idx; if (Siluetas.Rampas.TryGetValue("torso", out idx)) foreach (var v in idx) mTor[v] = true; }

        var sobre = new Lienzo(CW, CH);
        for (int p = 0; p < NPOSES; p++)
            for (int d = 0; d < NDIRS; d++) {
                Caja cab;
                if (!CajaCabeza(bas, w, CW, CH, d, p, masc, out cab)) continue;
                Caja tor; bool hayTor = CajaRampa(bas, w, CW, CH, d, p, mTor, out tor);
                System.Array.Clear(sobre.Px, 0, sobre.Px.Length);
                CapasSobreHoja(sobre, cfg, cab, hayTor, tor, d, T, Posturas[p].fog);
                PegaEncima(atlas, d*CW, p*CH, sobre, Paleta.Negro);
                CaraEncima(atlas, cfg, DesplazadaCaja(cab, d*CW, p*CH), d);
            }
        aw = w; ah = h;
        var px = new Color32[w*h];
        atlas.VolcarEn(px, w, h, 0, 0);
        Paleta.Cuantizar(px);
        return px;
    }

    static Caja DesplazadaCaja(Caja c, int dx, int dy) {
        return new Caja { x0 = c.x0 + dx, x1 = c.x1 + dx, y0 = c.y0 + dy, y1 = c.y1 + dy };
    }

    /// <summary>
    /// Pega las capas sobre la celda y les da contorno SOLO por donde asoman. La silueta
    /// ya viene con el suyo dibujado: bordear la celda entera otra vez le ponía un segundo
    /// anillo alrededor y todo el mundo salía con dos píxeles de luto.
    /// </summary>
    static void PegaEncima(Lienzo dest, int ox, int oy, Lienzo sobre, Color32 col) {
        int w = sobre.W, h = sobre.H;
        System.Func<int,int,bool> hay = (x,y) =>
            x >= 0 && y >= 0 && x < w && y < h && sobre.Px[y*w + x].a > 0;
        for (int y = 0; y < h; y++) {
            int dy = oy + y;
            if (dy < 0 || dy >= dest.H) continue;
            for (int x = 0; x < w; x++) {
                int dx = ox + x;
                if (dx < 0 || dx >= dest.W) continue;
                var c = sobre.Px[y*w + x];
                if (c.a > 0) { dest.Px[dy*dest.W + dx] = c; continue; }
                if (dest.Px[dy*dest.W + dx].a > 0) continue;   // ahí ya hay silueta
                bool v = false;
                for (int jy = -1; jy <= 1 && !v; jy++)
                    for (int jx = -1; jx <= 1 && !v; jx++) if (hay(x+jx, y+jy)) v = true;
                if (v) dest.Px[dy*dest.W + dx] = col;
            }
        }
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
    /// Primero se intenta repintar la silueta que le toque, que es arte dibujado; si no
    /// hay ninguna, se forja por capas como siempre. Nunca se queda nadie sin dibujar.
    public static Sprite[] Hoja(string arq) {
        Sprite[] s;
        if (Hojas.TryGetValue(arq, out s)) return s;
        int aw, ah;
        var px = HojaDeSilueta(arq, out aw, out ah);
        if (px == null) {
            aw = CW * NDIRS; ah = CH * NPOSES;
            px = new Color32[aw * ah];
            var cfg = Arq[arq];
            for (int p = 0; p < NPOSES; p++)
                for (int d = 0; d < NDIRS; d++)
                    Dibujar(cfg, (Pose)p, d).VolcarEn(px, aw, ah, d * CW, p * CH);
            Paleta.Cuantizar(px);
        }
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

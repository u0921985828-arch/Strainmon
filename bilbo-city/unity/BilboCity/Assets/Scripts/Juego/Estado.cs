using System.Collections.Generic;
using UnityEngine;

namespace BilboCity {

public class Arma {
    public string Id, Nombre;
    public float Dmg, Alc, Cad, Vel, Spread;
    public int Disp = 1, Precio, Balas, Pack;
    public bool Cuerpo, Infinita;
    public int Largo, Grosor = 1;
    public Color32 Col, Mango;
    public string Fog;
}

public static class Armas {
    public static readonly List<Arma> Todas = new List<Arma> {
        new Arma{ Id="punos", Nombre="Puños", Dmg=11, Alc=1.0f, Cad=.34f, Cuerpo=true, Infinita=true, Largo=0 },
        new Arma{ Id="bate", Nombre="Bate", Dmg=30, Alc=1.4f, Cad=.5f, Cuerpo=true, Infinita=true, Precio=120,
                  Largo=9, Grosor=2, Col=Paleta.MaderaL, Mango=Paleta.MaderaO },
        new Arma{ Id="pistola", Nombre="Pistola", Dmg=24, Alc=9, Cad=.3f, Vel=26, Spread=.05f, Precio=450,
                  Balas=60, Pack=24, Largo=5, Col=Paleta.Carbon, Mango=Paleta.Negro, Fog="pistola" },
        new Arma{ Id="uzi", Nombre="Uzi", Dmg=13, Alc=8, Cad=.085f, Vel=24, Spread=.14f, Precio=1400,
                  Balas=200, Pack=80, Largo=7, Grosor=2, Col=Paleta.Carbon, Mango=Paleta.Negro, Fog="subfusil" },
        new Arma{ Id="escopeta", Nombre="Escopeta", Dmg=15, Alc=5.5f, Cad=.85f, Vel=20, Disp=6, Spread=.3f,
                  Precio=900, Balas=40, Pack=16, Largo=11, Grosor=2, Col=Paleta.MaderaO, Mango=Paleta.Carbon, Fog="escopeta" },
    };
    public static Arma De(string id) { return Todas.Find(a => a.Id == id); }
}

public class Curro {
    public string Id, Titulo, Desc, Gremio, Icono;
    public bool Turbio, NecesitaFurgo;
    public int Base_, Req;
}

/// <summary>Un contrato con un gremio: haces N curros suyos y cobras el bonus.</summary>
[System.Serializable]
public class Contrato {
    public string Gremio;
    public int Meta, Hechos, Bonus;
    public bool Cerrado { get { return Hechos >= Meta; } }
}

public class Sitio {
    public string Id, Nombre, Interior;
    public Color32 Color;
    public Vector2 Pos;
    public bool Mirador;
    public int Cx, Cy;
    /// <summary>Redes de transporte que paran aquí: "metro", "tren" o las dos.</summary>
    public string Red;
    public bool EsDeRed(string red) { return Red != null && Red.Contains(red); }
}

/// <summary>Estado de la partida. Lo que se guarda y lo que consulta todo lo demás.</summary>
public class Estado {
    public static Estado I = new Estado();

    public float Dinero = 60, Hp = 100, Energia = 1, Hambre = 1;
    public int Estrellas, Min = 8*60, Dia = 1;
    public Dictionary<string,int> Rep = new Dictionary<string,int> {
        {"hosteleria",0},{"obra",0},{"transporte",0},{"calle",0}
    };
    public int Deuda, Alquiler = 220, UltCobro = 1;
    public bool TieneFurgo, TieneDeportivo, TieneSilenciador;
    /// Lo que el HUD pinta en el ojo: la sospecha más alta de los que te rodean, y si
    /// alguno te tiene a la vista ahora mismo.
    public float Sospecha;
    public bool Visto;
    public Dictionary<string,int> Municion = new Dictionary<string,int>();
    public string ArmaAct = "punos";
    public int MisionIdx;
    public float Muerto;
    public bool EnInterior;
    /// <summary>La ropa puesta. La forja del personaje ya sabe montar cualquier
    /// combinación —es como se dibujan los peatones—, así que vestirse es cambiar cuatro
    /// campos del arquetipo del protagonista y tirar su hoja para que se vuelva a forjar.</summary>
    public string Torso = "cazadora", Piernas = "vaquero", Calzado = "botas", Gorro = "txapela";
    public readonly List<Contrato> Contratos = new List<Contrato>();

    public Contrato ContratoDe(string gremio) { return Contratos.Find(c => c.Gremio == gremio && !c.Cerrado); }

    /// <summary>Firma un contrato si no hay ya uno abierto de ese gremio.</summary>
    public bool Firmar(string gremio, int meta, int bonus) {
        if (ContratoDe(gremio) != null) return false;
        Contratos.Add(new Contrato { Gremio = gremio, Meta = meta, Bonus = bonus });
        return true;
    }

    /// <summary>Apunta un curro terminado. Devuelve el bonus si acaba de cerrar el contrato.</summary>
    public int ApuntarCurro(string gremio) {
        var c = ContratoDe(gremio);
        if (c == null) return 0;
        c.Hechos++;
        if (!c.Cerrado) return 0;
        Dinero += c.Bonus;
        return c.Bonus;
    }

    public int Nivel(string g) { return Rep[g] / 4; }
    public float Multip(string g) { return 1f + Nivel(g) * 0.18f; }

    public bool TieneArma(string id) {
        var a = Armas.De(id);
        if (a == null) return false;
        if (a.Infinita) return id == "punos" || Municion.ContainsKey(id);
        int m;
        return Municion.TryGetValue(id, out m) && m > 0;
    }
    public int Mun(string id) {
        int m;
        return Municion.TryGetValue(id, out m) ? m : 0;
    }
    public bool TieneArmaFuego() {
        foreach (var a in Armas.Todas) if (!a.Cuerpo && Mun(a.Id) > 0) return true;
        return false;
    }

    public static readonly List<Curro> ListaCurros = new List<Curro> {
        new Curro{ Id="reparto", Icono="🛵", Titulo="Reparto de pintxos", Desc="Recoges en el Zurito y llevas el pedido.", Gremio="hosteleria", Base_=16 },
        new Curro{ Id="lonja",   Icono="🐟", Titulo="Cajas en la Ribera", Desc="Madrugón en el mercado.", Gremio="hosteleria", Base_=30 },
        new Curro{ Id="taxi",    Icono="🚕", Titulo="Turno de taxi", Desc="Con coche. Recoges y dejas.", Gremio="transporte", Base_=34 },
        new Curro{ Id="obra",    Icono="🚧", Titulo="Peón en la obra", Desc="Jornada dura. Paga fijo.", Gremio="obra", Base_=44 },
        new Curro{ Id="puerto",  Icono="⚓", Titulo="Descarga en el muelle", Desc="Contenedores en el Nervión.", Gremio="obra", Base_=62, Req=1 },
        new Curro{ Id="mudanza", Icono="📦", Titulo="Mudanza exprés", Desc="Necesitas furgoneta.", Gremio="transporte", Base_=95, Req=1, NecesitaFurgo=true },
        new Curro{ Id="recado",  Icono="🎒", Titulo="Recado sin preguntas", Desc="De A a B. Nadie mira dentro.", Gremio="calle", Base_=100, Turbio=true },
        new Curro{ Id="fuga",    Icono="🏁", Titulo="Conductor de fuga", Desc="Ruta corta, mucha estrella.", Gremio="calle", Base_=230, Req=2, Turbio=true },
    };

    public bool Disponible(Curro c) {
        return (!c.NecesitaFurgo || TieneFurgo) && Nivel(c.Gremio) >= c.Req;
    }
    public int PagoDe(Curro c) {
        return Mathf.RoundToInt(c.Base_ * Multip(c.Gremio) * Utiles.Rnd(0.9f, 1.25f));
    }

    // ═══════════ SITIOS ═══════════
    public static readonly List<Sitio> Sitios = new List<Sitio>();
    public static void ColocarSitios() {
        Sitios.Clear();
        // Las coordenadas salen del plano municipal: se buscó el rótulo de cada sitio y
        // se pasó su posición a casillas. Por eso ya no hace falta decirle a cada uno en
        // qué barrio va — cae en el suyo solo, porque está donde está de verdad.
        void S(string id, string n, Color32 c, string inter, int cx, int cy, bool mira = false, string red = null) {
            var s = new Sitio { Id=id, Nombre=n, Color=c, Interior=inter, Cx=cx, Cy=cy, Mirador=mira, Red=red };
            s.Pos = mira ? Ciudad.PuntoZona(cx,cy,40) : Ciudad.PuntoPortal(cx,cy,40);
            Sitios.Add(s);
        }
        S("piso",     "Tu piso",                Paleta.Mostaza,      "piso",     1184,440);
        S("portal",   "Portal",                 Paleta.H("#c98fd0"), "portal",   1188,436);
        S("bar",      "Bar Zurito",             Paleta.RojoL,        "bar",       934,352);
        S("merca",    "Mercado de la Ribera",   Paleta.VerdeL,       "merca",     956,403);
        S("armeria",  "Bazar Nervión",          Paleta.Sangre,       "armeria",  1170,430);
        S("taller",   "Taller Iker",            Paleta.H("#9d8ec4"), "taller",    732,672);
        S("hospital", "Hospital de Basurto",    Paleta.Blanco,       "hospital",  470,456);
        S("obra",     "Obra de Zorrotzaurre",   Paleta.H("#e8a33d"), null,        470,268);
        S("puerto",   "Muelle de Olabeaga",     Paleta.H("#4d9de0"), null,        384,420);
        S("poli",     "Comisaría",              Paleta.H("#4dd0e1"), null,        692,414);
        // Los emblemáticos, cada uno donde lo pone el plano
        S("guggen",   "El Guggenheim",          Paleta.H("#b8c4cc"), null,        692,183, true);
        S("iberdrola","Torre Iberdrola",        Paleta.H("#9fb4c4"), null,        705,205, true);
        S("euskalduna","Palacio Euskalduna",    Paleta.H("#8fa0ad"), null,        552,289, true);
        S("maritimo", "Museo Marítimo",         Paleta.H("#6f9ab5"), null,        575,300, true);
        S("bellasartes","Museo de Bellas Artes",Paleta.H("#b09a6e"), null,        661,285, true);
        S("casilla",  "Parque de Doña Casilda", Paleta.Cesped,       null,        640,299, true);
        S("moyua",    "Plaza Moyúa",            Paleta.H("#a8bcc8"), null,        728,319, true);
        S("abando",   "Estación de Abando",     Paleta.H("#c9a13f"), null,        857,329, true, "metrotren");
        S("alhondiga","Azkuna Zentroa",         Paleta.H("#c07f52"), null,        721,396, true);
        S("sanmames", "San Mamés",              Paleta.VerdeL,       null,        497,384, true);
        S("deustuni", "Universidad de Deusto",  Paleta.H("#b8a05c"), null,        624,163, true);
        S("arriaga",  "Teatro Arriaga",         Paleta.H("#d0a05a"), null,        909,322, true);
        S("plazanueva","La Plaza Nueva",        Paleta.H("#bfa878"), null,        950,321, true);
        S("catedral", "Catedral de Santiago",   Paleta.H("#c2b8a8"), null,        950,365, true);
        S("ayto",     "El Ayuntamiento",        Paleta.H("#a8b4bc"), null,        895,217, true);
        S("etxebarria","Parque Etxebarria",     Paleta.H("#7fae63"), null,        955,217, true);
        S("funicular","Funicular de Artxanda",  Paleta.H("#7fbf9f"), null,        814,146, true);
        S("begonia",  "Basílica de Begoña",     Paleta.H("#cbbf9c"), null,       1087,269, true);
        S("atxuri",   "Estación de Atxuri",     Paleta.H("#b58a5a"), null,       1009,424, true, "tren");
        S("arena",    "Bilbao Arena",           Paleta.H("#c4693f"), null,        961,484, true);
        S("zorrotza", "Estación de Zorrotza",   Paleta.H("#8fa66b"), null,        120,335, true, "tren");
        // Comercios. Nombres inventados, sitios reales: la Gran Vía, las Siete Calles,
        // Pozas, Deustu, Abandoibarra, Artxanda, Atxuri y Rekalde.
        S("ropagranvia", "Trapos Gran Vía",       Paleta.H("#c98fd0"), "ropa",      790,325);
        S("ropacasco",   "Ropero del Casco",      Paleta.H("#b878c0"), "ropa",      944,340);
        S("tascapozas",  "Tasca Ondarra",         Paleta.RojoL,        "tasca",     560,370);
        S("tascadeustu", "Tasca Iparragirre",     Paleta.RojoL,        "tasca",     620,205);
        S("asador",      "Asador de Artxanda",    Paleta.H("#d08a4a"), "resto",     806,120);
        S("sidreria",    "Sidrería Atxuri",       Paleta.H("#d08a4a"), "resto",    1000,412);
        S("galeria",     "Galería Abandoibarra",  Paleta.H("#7fbfd0"), "centro",    645,232);
        S("gasodeustu",  "Gasolinera Deustu",     Paleta.H("#e05a3c"), "gasoli",    612,192);
        S("gasorekalde", "Gasolinera Rekalde",    Paleta.H("#e05a3c"), "gasoli",    700,560);
        // Estaciones de metro. Las de verdad, en el barrio que les toca. Abando está
        // arriba porque además es de cercanías: allí se cambia de una red a la otra.
        S("mtinazio",    "Metro San Inazio",      Paleta.RojoL, null,  500,120, false, "metro");
        S("mtsarriko",   "Metro Sarriko",         Paleta.RojoL, null,  585,150, false, "metro");
        S("mtdeustu",    "Metro Deustu",          Paleta.RojoL, null,  640,175, false, "metro");
        S("mtsanmames",  "Metro San Mamés",       Paleta.RojoL, null,  500,378, false, "metro");
        S("mtindautxu",  "Metro Indautxu",        Paleta.RojoL, null,  628,345, false, "metro");
        S("mtmoyua",     "Metro Moyúa",           Paleta.RojoL, null,  728,322, false, "metro");
        S("mtcasco",     "Metro Casco Viejo",     Paleta.RojoL, null,  940,330, false, "metro");
        S("mtsantutxu",  "Metro Santutxu",        Paleta.RojoL, null, 1160,420, false, "metro");
        S("mtbasarrate", "Metro Basarrate",       Paleta.RojoL, null, 1110,400, false, "metro");
        S("mtbolueta",   "Metro Bolueta",         Paleta.RojoL, null, 1258,400, false, "metro");
        // Cercanías: los apeaderos del fondo del valle, que es donde el metro no llega.
        S("trolabeaga",  "Apeadero de Olabeaga",  Paleta.H("#8fa66b"), null, 392,412, false, "tren");
        S("trametzola",  "Apeadero de Ametzola",  Paleta.H("#8fa66b"), null, 640,470, false, "tren");
        S("trbasurto",   "Apeadero de Basurto",   Paleta.H("#8fa66b"), null, 482,438, false, "tren");
    }
    public static Sitio Sitio_(string id) { return Sitios.Find(s => s.Id == id); }
}

}

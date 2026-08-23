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
    public char Zona;
    public int Cx, Cy;
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
    public bool TieneFurgo, TieneDeportivo;
    public Dictionary<string,int> Municion = new Dictionary<string,int>();
    public string ArmaAct = "punos";
    public int MisionIdx;
    public float Muerto;
    public bool EnInterior;
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
        void S(string id, string n, Color32 c, string inter, int cx, int cy, char z, bool mira = false) {
            var s = new Sitio { Id=id, Nombre=n, Color=c, Interior=inter, Cx=cx, Cy=cy, Zona=z, Mirador=mira };
            s.Pos = mira ? Ciudad.PuntoZona(cx,cy,30,z) : Ciudad.PuntoPortal(cx,cy,30,z);
            Sitios.Add(s);
        }
        S("piso",     "Tu piso",                Paleta.Mostaza,      "piso",     372,104, 'S');
        S("portal",   "Portal",                 Paleta.H("#c98fd0"), "portal",   384,116, 'S');
        S("bar",      "Bar Zurito",             Paleta.RojoL,        "bar",      360,156, 'C');
        S("merca",    "Mercado de la Ribera",   Paleta.VerdeL,       "merca",    372,168, 'C');
        S("armeria",  "Bazar Nervión",          Paleta.Sangre,       "armeria",  392,128, 'S');
        S("taller",   "Taller Iker",            Paleta.H("#9d8ec4"), "taller",   264,228, 'R');
        S("hospital", "Hospital de Basurto",    Paleta.Blanco,       "hospital",  148,220, 'B');
        S("obra",     "Obra de Zorrotzaurre",   Paleta.H("#e8a33d"), null,        152,168, 'Z');
        S("puerto",   "Muelle de Olabeaga",     Paleta.H("#4d9de0"), null,        80,224, 'O');
        S("poli",     "Comisaría",              Paleta.H("#4dd0e1"), null,       224,180, 'I');
        S("guggen",   "El Guggenheim",          Paleta.H("#b8c4cc"), null,       248,140, 'X', true);
        S("sanmames", "San Mamés",              Paleta.VerdeL,       null,        180,196, 'E', true);
        S("abando",   "Estación de Abando",     Paleta.H("#c9a13f"), null,       300,168, 'A', true);
        S("ayto",     "El Ayuntamiento",        Paleta.H("#a8b4bc"), null,       264,76, 'U', true);
        S("casilla",  "Parque de Doña Casilda", Paleta.Cesped,       null,       204,172, 'P', true);
        // Los emblemáticos, cada uno en su barrio de verdad
        S("arriaga",  "Teatro Arriaga",         Paleta.H("#d0a05a"), null,       344,132, 'C', true);
        S("catedral", "Catedral de Santiago",   Paleta.H("#c2b8a8"), null,       364,156, 'C', true);
        S("plazanueva","La Plaza Nueva",        Paleta.H("#bfa878"), null,       356,144, 'C', true);
        S("euskalduna","Palacio Euskalduna",    Paleta.H("#8fa0ad"), null,       224,136, 'X', true);
        S("iberdrola","Torre Iberdrola",        Paleta.H("#9fb4c4"), null,       268,136, 'X', true);
        S("bellasartes","Museo de Bellas Artes",Paleta.H("#b09a6e"), null,       220,168, 'P', true);
        S("alhondiga","Azkuna Zentroa",         Paleta.H("#c07f52"), null,       232,176, 'I', true);
        S("begonia",  "Basílica de Begoña",     Paleta.H("#cbbf9c"), null,       332,88, 'G', true);
        S("funicular","Funicular de Artxanda",  Paleta.H("#7fbf9f"), null,       280,60, 'U', true);
        S("moyua",    "Plaza Moyúa",            Paleta.H("#a8bcc8"), null,       320,160, 'A', true);
        S("deustuni", "Universidad de Deusto",  Paleta.H("#b8a05c"), null,        152,96, 'D', true);
        S("maritimo", "Museo Marítimo",         Paleta.H("#6f9ab5"), null,        96,192, 'O', true);
        S("arena",    "Bilbao Arena",           Paleta.H("#c4693f"), null,       360,220, 'M', true);
    }
    public static Sitio Sitio_(string id) { return Sitios.Find(s => s.Id == id); }
}

}

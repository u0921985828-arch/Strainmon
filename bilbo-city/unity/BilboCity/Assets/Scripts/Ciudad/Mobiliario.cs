using System.Collections.Generic;
using UnityEngine;

namespace BilboCity {

/// <summary>
/// Siembra el mobiliario urbano. Sin esto la ciudad se ve desnuda: son las farolas,
/// los árboles y los contenedores los que hacen que una calle parezca una calle.
/// Cada pieza se decide por hash de la casilla, así que la ciudad sale siempre igual.
/// </summary>
public static class Mobiliario {

    /// <summary>Cuántas piezas se han plantado. Útil para el presupuesto de dibujado.</summary>
    public static int Sembradas { get; private set; }

    /// <summary>Internal, no privado: Vision.TapaAlJugador reaprovecha esta misma tabla de
    /// siembra para saber qué le taparía al jugador, en vez de duplicarla.</summary>
    internal struct Pieza { public string Clave; public float Dx, Dy; }

    static bool JuntoA(int x, int y, Suelo t) {
        return Ciudad.T(x+1,y) == t || Ciudad.T(x-1,y) == t || Ciudad.T(x,y+1) == t || Ciudad.T(x,y-1) == t;
    }

    /// <summary>Un paso de cebra, y en qué sentido van las bandas. 0 = no hay; 'V' = calle
    /// norte-sur, bandas verticales; 'H' = calle este-oeste. Se encuentran solos: en mitad
    /// de una calle la acera acompaña a los dos lados y justo en la bocacalle se interrumpe,
    /// que es donde cruza la gente. Las bandas van paralelas al tráfico, como se pintan.</summary>
    public static char Cebra(int x, int y) {
        if (Ciudad.T(x,y) != Suelo.Road) return '\0';
        bool eo = Pisable(x-1,y) && Pisable(x+1,y), ns = Pisable(x,y-1) && Pisable(x,y+1);
        if (eo && !ns) {
            if (!Pisable(x-1,y-1) || !Pisable(x+1,y-1) || !Pisable(x-1,y+1) || !Pisable(x+1,y+1)) return 'V';
        } else if (ns && !eo) {
            if (!Pisable(x-1,y-1) || !Pisable(x-1,y+1) || !Pisable(x+1,y-1) || !Pisable(x+1,y+1)) return 'H';
        }
        return '\0';
    }

    static bool Pisable(int x, int y) {
        var t = Ciudad.T(x,y);
        return t == Suelo.Acera || t == Suelo.Plaza;
    }

    static bool CebraAlLado(int x, int y) {
        return Cebra(x,y-1) != '\0' || Cebra(x,y+1) != '\0'
            || Cebra(x+1,y) != '\0' || Cebra(x-1,y) != '\0';
    }

    static bool Cruce(int x, int y) {
        int n = 0;
        if (Ciudad.Rodable(x+1,y)) n++;
        if (Ciudad.Rodable(x-1,y)) n++;
        if (Ciudad.Rodable(x,y+1)) n++;
        if (Ciudad.Rodable(x,y-1)) n++;
        return n >= 3;
    }

    /// <summary>Qué se puede abrir en cada tipo de barrio. Se repite alguno a propósito: si
    /// todos los locales fueran distintos, una calle parecería una feria.</summary>
    static readonly Dictionary<string,string[]> FachBarrio = new Dictionary<string,string[]> {
        {"denso",     new[]{"fachTasca","fachPersiana","fachPortal","fachEscaparate","fachPortal","fachPersiana","fachTasca","fachCiega"}},
        {"senorial",  new[]{"fachEscaparate","fachPortalPiedra","fachEscaparate","fachCiega","fachPortalPiedra","fachPersiana"}},
        {"bloques",   new[]{"fachPortal","fachCiega","fachPersiana","fachPortal","fachEscaparate","fachGaraje","fachCiega","fachPortal"}},
        {"industrial",new[]{"fachPorton","fachPorton","fachGaraje","fachCiega","fachPersiana","fachPorton"}},
        {"abierto",   new[]{"fachPortal","fachCiega","fachGaraje","fachCiega"}},
    };

    internal static bool Elegir(int x, int y, out Pieza p) {
        p = new Pieza();
        var t = Ciudad.T(x,y);
        var Z = Ciudad.BarrioDe(x,y);
        int h = Utiles.Hash(x*7+1, y*13+5);
        bool juntoCalle = JuntoA(x,y,Suelo.Road) || JuntoA(x,y,Suelo.Puente);

        // Cada familia de tejado lleva lo suyo: en la teja, chimeneas; en la azotea,
        // depósitos y tendederos; en la nave, lucernarios.
        if (t == Suelo.Edif) {
            var fam = Ciudad.FamiliaDe(Ciudad.Roof[y*Ciudad.MW+x]);
            int hr = Utiles.Hash(x,y);
            if (fam == "teja" || fam == "pizarra") {
                if (hr % 23 == 0) { p.Clave = "chimenea"; p.Dx = 0.31f; p.Dy = 0.13f; return true; }
                if (hr % 71 == 0) { p.Clave = "antenaTv"; p.Dx = 0.28f; p.Dy = 0.06f; return true; }
            } else if (fam == "azotea") {
                if (hr % 37 == 0) { p.Clave = "deposito";     p.Dx = 0.22f; p.Dy = 0.16f; return true; }
                if (hr % 41 == 0) { p.Clave = "tendedero";    p.Dx = 0.06f; p.Dy = 0.28f; return true; }
                if (hr % 43 == 0) { p.Clave = "climatizador"; p.Dx = 0.22f; p.Dy = 0.25f; return true; }
                if (hr % 47 == 0) { p.Clave = "caseta";       p.Dx = 0.16f; p.Dy = 0.19f; return true; }
                if (hr % 53 == 0) { p.Clave = "antenaTv";     p.Dx = 0.28f; p.Dy = 0.06f; return true; }
            } else if (hr % 29 == 0) { p.Clave = "lucernario"; p.Dx = 0.13f; p.Dy = 0.25f; return true; }
            return false;
        }

        if (t == Suelo.Acera) {
            // Una calle no es una acera con cosas repartidas por un hash: es un bordillo con
            // todo alineado encima. Nada fuera de la fila que toca calzada, y a paso fijo a lo
            // largo de la calle — una farola cada cuatro casillas son 21 m, y en Bilbao hay
            // una cada 25.
            if (!juntoCalle) return false;
            bool cE = Ciudad.T(x+1,y) == Suelo.Road, cO = Ciudad.T(x-1,y) == Suelo.Road;
            bool cN = Ciudad.T(x,y-1) == Suelo.Road, cS = Ciudad.T(x,y+1) == Suelo.Road;
            // El semáforo va en la esquina y solo si tiene un paso al lado. En cada acera que
            // toca un cruce salían veinticuatro mil, uno cada cinco metros.
            if ((cN || cS) && (cE || cO) && CebraAlLado(x,y) && h % 3 == 0) {
                p.Clave = "semaforo"; p.Dx = 0.5f; p.Dy = 0.9f; return true;
            }
            int l = (cE || cO) ? y : x;          // el paso, a lo largo de la calle
            if (l % 4 == 0) { p.Clave = "farola"; p.Dx = 0.5f; p.Dy = 0.95f; return true; }
            if ((Z.Estilo == "senorial" || Z.Estilo == "abierto") && l % 4 == 2) {
                p.Clave = "arbolPodado"; p.Dx = 0.5f; p.Dy = 0.95f; return true; }
            if (Z.Estilo == "denso" && l % 3 == 1) { p.Clave = "bolardo"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            // Los contenedores van en batería, que es como están en la calle.
            if (l % 37 < 3) { p.Clave = h % 2 == 0 ? "contenedor" : "contenedor2"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            if (l % 9 == 4) { p.Clave = "papelera"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            if ((Z.Estilo == "senorial" || Z.Estilo == "abierto") && l % 13 == 6) {
                p.Clave = "banco"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            if (l % 97 == 0) { p.Clave = "cabina"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            return false;
        }

        if (t == Suelo.Plaza) {
            if (h % 9 == 0)  { p.Clave = "arbolPodado"; p.Dx = 0.5f; p.Dy = 0.95f; return true; }
            if (h % 14 == 0) { p.Clave = "banco";       p.Dx = 0.5f; p.Dy = 0.9f;  return true; }
            if (h % 37 == 0) { p.Clave = "papelera";    p.Dx = 0.5f; p.Dy = 0.9f;  return true; }
            return false;
        }

        if (t == Suelo.Parque || t == Suelo.Monte) {
            // el monte va más tupido que un parque urbano, y sin bancos
            if (t == Suelo.Monte) {
                if (h % 4 == 0) { p.Clave = "arbol"; p.Dx = 0.5f; p.Dy = 0.95f; return true; }
                return false;
            }
            if (h % 7 == 0)  { p.Clave = "arbol"; p.Dx = 0.5f; p.Dy = 0.95f; return true; }
            if (h % 23 == 0) { p.Clave = "banco"; p.Dx = 0.5f; p.Dy = 0.9f;  return true; }
            return false;
        }

        if (t == Suelo.Muelle) {
            if (h % 11 == 0) { p.Clave = "contMaritimo"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            if (h % 19 == 0) { p.Clave = "pales";        p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            if (h % 53 == 0) { p.Clave = "grua";         p.Dx = 0.5f; p.Dy = 0.95f; return true; }
            return false;
        }

        if (t == Suelo.Patio) {
            if (h % 13 == 0) { p.Clave = "arbolPodado"; p.Dx = 0.5f; p.Dy = 0.95f; return true; }
            if (h % 21 == 0) { p.Clave = "contenedor";  p.Dx = 0.5f; p.Dy = 0.9f;  return true; }
            return false;
        }
        return false;
    }

    /// <summary>
    /// Reserva sitio a los quince marcadores para no plantarles un árbol en la puerta,
    /// y siembra el resto de la ciudad.
    /// </summary>
    public static void Sembrar(Transform padre) {
        Sembradas = 0;
        var vetado = new HashSet<int>();
        foreach (var s in Estado.Sitios) {
            int sx = Mathf.RoundToInt(s.Pos.x), sy = Mathf.RoundToInt(s.Pos.y);
            for (int dy = -1; dy <= 1; dy++)
                for (int dx = -1; dx <= 1; dx++)
                    vetado.Add((sy+dy) * Ciudad.MW + (sx+dx));
        }

        for (int y = 1; y < Ciudad.MH-1; y++)
            for (int x = 1; x < Ciudad.MW-1; x++) {
                if (vetado.Contains(y * Ciudad.MW + x)) continue;
                Pieza p;
                if (!Elegir(x, y, out p)) continue;
                // Ley 6 · tope de sitio: una acera de dos metros y medio no admite una
                // grúa de doce, y algo que pase la altura que cabe en su suelo deja de
                // ser mobiliario y pasa a ser un muro. No es un límite de estilo, es el
                // mismo que exige la batería del HTML (TOPE_ALTO/Vision.TopeAlto): si el
                // día de mañana una pieza nueva de Forja.MedidasMob se cuela por encima,
                // se frena aquí, no se descubre mirando la calle.
                float[] medida;
                if (Forja.MedidasMob.TryGetValue(p.Clave, out medida)
                    && medida[1] > Vision.TopeAlto(Ciudad.T(x, y)) + 1e-4f) continue;
                Sprite sp;
                if (!Forja.Props.TryGetValue(p.Clave, out sp)) continue;
                var go = new GameObject(p.Clave);
                go.transform.SetParent(padre, false);
                go.transform.position = Mundo.AMundoPixel(new Vector2(x + p.Dx, y + p.Dy));
                go.isStatic = true;
                var sr = go.AddComponent<SpriteRenderer>();
                sr.sprite = sp;
                sr.sortingOrder = Mundo.OrdenY(y + p.Dy);
                Sembradas++;
            }
    }
}

}

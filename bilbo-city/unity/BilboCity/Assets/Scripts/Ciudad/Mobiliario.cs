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

    /// Lado hacia el que mira la marca: 0 norte, 1 sur, 2 oeste, 3 este. El mismo orden que
    /// usa Cebra() para decidir qué vecino es el paso. Internal, no privado: Ciudad y Juego
    /// reaprovechan el mismo orden para orientar los coches aparcados.
    internal static readonly int[] DxLado = {0,0,-1,1}, DyLado = {-1,1,0,0};

    /// <summary>Línea de detención: delante de cada paso de cebra, y solo por donde se llega
    /// a él —la cebra vertical cruza una calle norte-sur, así que se para por arriba y por
    /// abajo, y la horizontal al revés—. -1 si esta calzada no lleva.</summary>
    public static int Stop(int x, int y) {
        if (Ciudad.T(x,y) != Suelo.Road) return -1;
        if (Cebra(x,y) != '\0') return -1;     // la propia cebra no lleva línea encima
        for (int lado = 0; lado < 4; lado++) {
            int dx = DxLado[lado], dy = DyLado[lado];
            char v = Cebra(x+dx, y+dy);
            if ((v == 'V' && dx == 0) || (v == 'H' && dy == 0)) return lado;
        }
        return -1;
    }

    /// <summary>Plaza de aparcamiento en línea: una casilla mide 5,16 m, justo lo que ocupa
    /// un coche aparcado, así que cada casilla de calzada pegada al bordillo en tramo recto
    /// es una plaza. De cada tres se deja una sin marcar —vados, contenedores, la parada del
    /// bus—. -1 si esta calzada no lleva.</summary>
    public static int Aparca(int x, int y) {
        if (Ciudad.T(x,y) != Suelo.Road || Stop(x,y) >= 0) return -1;
        if (Utiles.Hash(x,y) % 3 == 0) return -1;
        for (int lado = 0; lado < 4; lado++) {
            int dx = DxLado[lado], dy = DyLado[lado];
            var t2 = Ciudad.T(x+dx, y+dy);
            if (t2 != Suelo.Acera && t2 != Suelo.Plaza && t2 != Suelo.Muelle) continue;
            bool recto = dx == 0
                ? Ciudad.T(x-1,y) == Suelo.Road && Ciudad.T(x+1,y) == Suelo.Road
                : Ciudad.T(x,y-1) == Suelo.Road && Ciudad.T(x,y+1) == Suelo.Road;
            if (!recto) continue;
            return lado;
        }
        return -1;
    }

    /// <summary>Flecha de carril: antes del cruce y en el sentido de la marcha, pero solo
    /// en el cruce que tiene paso al lado —pintada en cada bocacalle salían 36 000, una de
    /// cada cinco casillas de calzada, y eso no es una ciudad, es un parking; con la
    /// condición del paso quedan 1 700—. Un cruce es una casilla de calzada con salida por
    /// tres lados o más, y la flecha va en la casilla de antes, que es donde se pinta de
    /// verdad. -1 si esta calzada no lleva.</summary>
    public static int Flecha(int x, int y) {
        if (Ciudad.T(x,y) != Suelo.Road) return -1;
        if (Cebra(x,y) != '\0' || Stop(x,y) >= 0) return -1;
        // La flecha ocupa justo las casillas que Aparca() descarta por vado —de cada tres,
        // una no lleva plaza—, así que las dos marcas nunca se pisan.
        if (Utiles.Hash(x,y) % 3 != 0) return -1;
        for (int lado = 0; lado < 4; lado++) {
            int dx = DxLado[lado], dy = DyLado[lado];
            int cx = x+dx, cy = y+dy;
            if (!Cruce(cx,cy)) continue;
            if (Cebra(cx-1,cy) == '\0' && Cebra(cx+1,cy) == '\0'
                && Cebra(cx,cy-1) == '\0' && Cebra(cx,cy+1) == '\0') continue;
            // Y solo si por detrás sigue habiendo calle: una flecha en una casilla suelta
            // no señala nada.
            if (!Ciudad.Rodable(x-dx, y-dy)) continue;
            return lado;
        }
        return -1;
    }

    /// <summary>Dónde va un coche aparcado y hacia dónde mira, sacados de la marca de
    /// aparcamiento del suelo: el lado de Aparca() dice de qué lado queda el bordillo, así
    /// que el coche se arrima a él —0,28 casillas del centro— y se orienta a lo largo de
    /// la calle.</summary>
    public struct Aparcamiento { public Vector2 Pos; public float Ang; }

    /// <summary>Busca una plaza de aparcamiento cerca de (cx,cy). Null si no encuentra
    /// ninguna en los intentos, igual que puntoAparcamiento() del prototipo vuelve
    /// undefined y quien llama recurre a una casilla de calzada cualquiera.</summary>
    public static Aparcamiento? PuntoAparcamiento(int cx, int cy, int rad) {
        for (int i = 0; i < 500; i++) {
            int x = Mathf.Clamp(cx + Utiles.RndI(-rad, rad), 2, Ciudad.MW-3);
            int y = Mathf.Clamp(cy + Utiles.RndI(-rad, rad), 2, Ciudad.MH-3);
            int lado = Aparca(x, y);
            if (lado < 0) continue;
            int dx = DxLado[lado], dy = DyLado[lado];
            // El bordillo a los lados (dx≠0) quiere decir calle de norte a sur, y al
            // revés. El sentido de la marcha lo da la paridad de la casilla: los coches de
            // un lado miran a un lado, y los del otro justo al contrario.
            float ang = dx != 0 ? (y % 2 != 0 ? Mathf.PI/2f : -Mathf.PI/2f)
                                 : (x % 2 != 0 ? Mathf.PI : 0f);
            return new Aparcamiento {
                Pos = new Vector2(x + 0.5f + dx*0.28f, y + 0.5f + dy*0.28f), Ang = ang
            };
        }
        return null;
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

    /// <summary>Lo que se siembra fuera de la acera, y a qué hash, para cada suelo. Gana la
    /// primera pieza que case —lo raro va primero, que si no se lo come el arbolado— y todas
    /// a la misma posición dentro de la casilla. Es la misma tabla SIEMBRA del HTML, en el
    /// mismo orden: cambiar el orden aquí cambia qué sale en cada casilla.</summary>
    static readonly Dictionary<Suelo, (int Mod, string Clave)[]> Siembra = new Dictionary<Suelo, (int, string)[]> {
        // Un parque no es césped con árboles: es donde está el columpio, el tobogán, el
        // arenero y la fuente de beber. Van antes que el árbol en la lista porque el árbol
        // se lleva una de cada cuatro casillas y si no, no saldría ninguno.
        { Suelo.Parque, new (int, string)[] {
            (53,"columpio"), (59,"tobogan"), (67,"arenero"), (71,"porteria"), (37,"fuenteBeber"),
            (4,"arbol"), (19,"matorral"), (23,"banco"), (43,"papelera") } },
        // El monte es el 39% del mapa —Artxanda, Pagasarri, las laderas— y estaba pelado:
        // verde con manchas y ni un árbol. Es pino de repoblación y eucalipto, no el
        // plátano de sombra de la Gran Vía, así que lleva su propio arbolado y su matorral.
        { Suelo.Monte, new (int, string)[] { (4,"pino"), (9,"matorral"), (13,"arbol") } },
        // La plaza tiene lo que tiene una plaza de Bilbao: fuente, quiosco de prensa, el
        // reloj, la estatua de alguien y bancos alrededor. Lo raro va primero, que si no se
        // lo come el arbolado.
        { Suelo.Plaza, new (int, string)[] {
            (97,"fuente"), (89,"estatua"), (83,"reloj"), (151,"quiosco"), (59,"jardinera"),
            (23,"arbolPodado"), (31,"banco"), (41,"papelera") } },
        // El muelle es sitio de trabajo: grúa, contenedores apilados, palés, bidones, la
        // hormigonera y el noray donde se amarra.
        { Suelo.Muelle, new (int, string)[] {
            (29,"grua"), (37,"pilaCont"), (17,"contMaritimo"), (13,"pales"), (11,"bidon"),
            (23,"hormigonera"), (31,"escombros"), (43,"contObra"), (7,"noray") } },
        // El patio de manzana: trastos, el tendedero, la bici del vecino y el contenedor.
        { Suelo.Patio, new (int, string)[] {
            (13,"trastos"), (19,"contenedor"), (29,"tendedero"), (17,"bici"),
            (7,"arbolPodado"), (9,"pales") } },
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
            // El Casco no lleva la farola de aluminio de la Gran Vía: lleva la de
            // fundición, más baja y con capitel. Es la misma cadencia, otra pieza.
            if (l % 4 == 0) {
                p.Clave = Z.Estilo == "denso" ? "farolaCasco" : "farola";
                p.Dx = 0.5f; p.Dy = 0.95f; return true;
            }
            if ((Z.Estilo == "senorial" || Z.Estilo == "abierto") && l % 4 == 2) {
                p.Clave = "arbolPodado"; p.Dx = 0.5f; p.Dy = 0.95f; return true; }
            if (Z.Estilo == "denso" && l % 3 == 1) { p.Clave = "bolardo"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            // Los contenedores van en batería, que es como están en la calle.
            if (l % 37 < 3) { p.Clave = h % 2 == 0 ? "contenedor" : "contenedor2"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            if (l % 9 == 4) { p.Clave = "papelera"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            if ((Z.Estilo == "senorial" || Z.Estilo == "abierto") && l % 13 == 6) {
                p.Clave = "banco"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            if (l % 97 == 0) { p.Clave = "cabina"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            // Y lo demás, que es lo que hace que una acera no sea una fila de farolas: el
            // buzón, el parquímetro donde se aparca, la señal, el hidrante, los iglús del
            // vidrio y del papel, el aparcabicis, la jardinera del Ensanche y el seto de
            // los bloques. Cada uno con su paso a lo largo de la calle, así que salen
            // repartidos y no en corro.
            if (l % 53 == 7) { p.Clave = "buzon"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            if ((Z.Estilo == "senorial" || Z.Estilo == "denso") && l % 29 == 11) {
                p.Clave = "parquimetro"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            if (l % 23 == 5) { p.Clave = "senal"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            if (l % 61 == 13) { p.Clave = "hidrante"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            if ((Z.Estilo == "senorial" || Z.Estilo == "abierto") && l % 17 == 9) {
                p.Clave = "jardinera"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            if ((Z.Estilo == "bloques" || Z.Estilo == "abierto") && l % 19 == 7) {
                p.Clave = "seto"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            if (l % 41 == 15) { p.Clave = "aparcabicis"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            if (l % 31 == 12) { p.Clave = h % 2 != 0 ? "contVidrio" : "contPapel"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            if (l % 149 == 0) { p.Clave = "quiosco"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            if (l % 73 == 33) { p.Clave = "moto"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            if (l % 79 == 41) { p.Clave = "bici"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            return false;
        }

        // El resto de suelos siembra por la tabla, primera pieza que case el hash.
        (int Mod, string Clave)[] tabla;
        if (Siembra.TryGetValue(t, out tabla)) {
            foreach (var pieza in tabla)
                if (h % pieza.Mod == 0) { p.Clave = pieza.Clave; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
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

        // Y la boca de metro donde está la estación. Once agujeros en la acera con su
        // barandilla y su rótulo: hasta ahora el metro se cogía tocando una chincheta sobre
        // una manzana. Se busca la acera o plaza más cercana en anillos crecientes, y se
        // veta la casilla para que el barrido de abajo no le plante encima otra cosa.
        foreach (var q in Transporte.Nodos("metro")) {
            int cx = Mathf.FloorToInt(q.Pos.x), cy = Mathf.FloorToInt(q.Pos.y);
            bool puesta = false;
            for (int r = 0; r < 3 && !puesta; r++)
                for (int dy = -r; dy <= r && !puesta; dy++)
                    for (int dx = -r; dx <= r; dx++) {
                        if (Mathf.Max(Mathf.Abs(dx), Mathf.Abs(dy)) != r) continue;
                        int nx = cx+dx, ny = cy+dy;
                        if (nx < 1 || ny < 1 || nx >= Ciudad.MW-1 || ny >= Ciudad.MH-1) continue;
                        var t = Ciudad.T(nx, ny);
                        if (t != Suelo.Acera && t != Suelo.Plaza) continue;
                        if (Colocar(padre, nx, ny, "bocaMetro", 0.5f, 0.9f))
                            vetado.Add(ny * Ciudad.MW + nx);
                        puesta = true; break;
                    }
        }

        for (int y = 1; y < Ciudad.MH-1; y++)
            for (int x = 1; x < Ciudad.MW-1; x++) {
                if (vetado.Contains(y * Ciudad.MW + x)) continue;
                Pieza p;
                if (!Elegir(x, y, out p)) continue;
                Colocar(padre, x, y, p.Clave, p.Dx, p.Dy);
            }
    }

    /// <summary>Planta una pieza ya elegida: comprueba tope de altura y sprite, y crea el
    /// GameObject. Lo comparten el barrido general y la boca de metro, que se coloca aparte
    /// porque no sale del hash de su casilla sino de la estación más cercana.</summary>
    static bool Colocar(Transform padre, int x, int y, string clave, float dx, float dy) {
        // Ley 6 · tope de sitio: una acera de dos metros y medio no admite una grúa de
        // doce, y algo que pase la altura que cabe en su suelo deja de ser mobiliario y
        // pasa a ser un muro. No es un límite de estilo, es el mismo que exige la batería
        // del HTML (TOPE_ALTO/Vision.TopeAlto): si el día de mañana una pieza nueva de
        // Forja.MedidasMob se cuela por encima, se frena aquí, no se descubre mirando la
        // calle.
        float[] medida;
        if (Forja.MedidasMob.TryGetValue(clave, out medida)
            && medida[1] > Vision.TopeAlto(Ciudad.T(x, y)) + 1e-4f) return false;
        Sprite sp;
        if (!Forja.Props.TryGetValue(clave, out sp)) return false;
        var go = new GameObject(clave);
        go.transform.SetParent(padre, false);
        go.transform.position = Mundo.AMundoPixel(new Vector2(x + dx, y + dy));
        go.isStatic = true;
        var sr = go.AddComponent<SpriteRenderer>();
        sr.sprite = sp;
        sr.sortingOrder = Mundo.OrdenY(y + dy);
        Sembradas++;
        return true;
    }
}

}

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
        // El Ensanche de Abando. La retícula que se ve desde el aire, con Moyúa en medio.
        C("Gran Vía",             634,310, 728,319, 846,330),
        C("Alameda Recalde",      714,276, 728,319, 736,390),
        C("Alameda Mazarredo",    668,292, 740,300, 842,318),
        C("Alameda Urquijo",      836,344, 740,352, 650,368, 566,380),
        C("Rodríguez Arias",      648,330, 724,336, 800,344),
        C("Licenciado Poza",      696,328, 640,350, 592,368),
        C("Iparraguirre",         748,313, 716,268, 700,218),
        C("Ercilla",              760,316, 752,356),
        C("Colón de Larreátegui", 756,308, 838,322),
        C("Hurtado de Amézaga",   852,332, 846,306, 842,282),
        C("Autonomía",            560,400, 660,398, 780,394),
        C("Gordóniz",             700,400, 706,462, 714,516),
        C("Sabino Arana",         516,388, 542,438, 566,486),
        // Abandoibarra y la ría: lo que se hizo donde estaba el astillero.
        C("Abandoibarra",         688,192, 640,232, 580,272),
        C("Uribitarte",           806,268, 756,244, 716,218),
        // Deustu y la Ribera, al otro lado del canal.
        C("Lehendakari Agirre",   346,332, 452,296, 556,238, 628,186),
        C("Ribera de Deustu",     408,308, 500,262, 586,222),
        C("Avenida Universidades",596,196, 632,170),
        C("Blas de Otero",        420,306, 486,278),
        // El Casco Viejo y la orilla de enfrente.
        C("Bidebarrieta",         920,326, 936,346, 948,362),
        C("Iturribide",           942,340, 996,340, 1046,348),
        C("La Ribera",            930,392, 958,402, 986,408),
        C("San Francisco",        866,412, 902,418, 936,424),
        C("Las Cortes",           870,424, 910,430),
        // Ladera de Begoña, Santutxu y el fondo del valle.
        C("Zabalbide",            972,344, 1044,362, 1120,400, 1178,428),
        C("Zumalakarregi",        1020,420, 1120,452, 1240,478, 1298,486),
        C("Karmelo",              1150,424, 1198,442),
        C("Miraflores",           958,486, 994,570, 1022,660),
        C("Rekalde Zumarkalea",   716,520, 726,596, 732,664),
        // Los extremos: Basurtu, Olabeaga y Zorrotza, río abajo.
        C("Montevideo",           516,404, 488,432, 474,452),
        C("Olabeaga",             354,428, 408,422),
        C("Camino de Zorrotza",   114,356, 174,364),
        C("Doctor Areilza",       626,362, 566,376),
        C("Zabala",               838,458, 856,476),
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

    static bool Cerca(int cx, int cy, out int rx, out int ry) {
        var q = Ciudad.CercaDe(EsCalle, cx, cy, 24);
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
    }
}

}

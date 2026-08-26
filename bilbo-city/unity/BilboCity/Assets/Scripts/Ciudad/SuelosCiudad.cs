using System.Collections.Generic;

namespace BilboCity {

/// <summary>
/// Del plano salen siete cosas: calzada, acera, manzana, parque, agua, puente y monte. La
/// ciudad tiene más —muelle, patio de manzana, plaza— y el juego tenía el arte hecho
/// —la grúa y el contenedor marítimo se forjaban al arrancar— sin una sola casilla donde
/// ponerlo, y Zorrotzaurre era césped.
///
/// Esto no inventa geometría, no mueve una casilla: le pone nombre a la que ya hay, que es
/// lo que decide con qué se pinta y qué se le planta encima. Las preguntas se contestan con
/// la propia trama, así que la ciudad sigue saliendo igual en cada partida.
/// </summary>
public static class SuelosCiudad {
    static readonly int[] Dx4 = {1,-1,0,0}, Dy4 = {0,0,1,-1};

    /// <summary>
    /// Se llama desde Ciudad.Generar(), justo después de los tejados: clasifica muelle y
    /// patio de manzana por geometría pura, antes de que nadie haya nombrado una calle.
    /// </summary>
    public static void Clasificar() {
        int mw = Ciudad.MW, mh = Ciudad.MH, n = mw * mh;
        var map = Ciudad.Map;

        // 1 · El muelle es la orilla de trabajo: acera pegada al agua en barrio industrial
        // —Zorrotza, Olabeaga, Bolueta—. Tres condiciones a la vez, y cada una quita algo:
        // la orilla de Abandoibarra también toca el agua y no es muelle sino paseo, así que
        // manda el barrio; y el césped de la ladera de Olabeaga tampoco es muelle aunque
        // llegue al agua, así que solo cuenta lo que ya estaba pavimentado.
        var dAgua = new byte[n];
        for (int i = 0; i < n; i++) dAgua[i] = 255;
        var cola = new List<int>();
        for (int i = 0; i < n; i++) if ((Suelo)map[i] == Suelo.Agua) { dAgua[i] = 0; cola.Add(i); }
        for (int d = 0; d < 2; d++) {
            var sig = new List<int>();
            foreach (int i in cola) {
                int x = i % mw, y = i / mw;
                for (int k = 0; k < 4; k++) {
                    int nx = x + Dx4[k], ny = y + Dy4[k];
                    if (nx < 0 || ny < 0 || nx >= mw || ny >= mh) continue;
                    int j = ny * mw + nx;
                    if (dAgua[j] != 255) continue;
                    dAgua[j] = (byte)(d + 1); sig.Add(j);
                }
            }
            cola = sig;
        }
        cola = new List<int>();
        for (int i = 0; i < n; i++) {
            if (dAgua[i] > 2 || (Suelo)map[i] != Suelo.Acera) continue;
            var b = Ciudad.BarrioDe(i % mw, i / mw);
            if (b.Estilo != "industrial") continue;
            map[i] = (byte)Suelo.Muelle; cola.Add(i);
        }
        // Y el muelle no es la línea del borde: es la explanada. Desde la orilla tira tres
        // casillas —quince metros— tierra adentro por lo que ya estuviera pavimentado, que
        // es donde caben la grúa, los contenedores y el camión que viene a cargar.
        for (int d = 0; d < 3 && cola.Count > 0; d++) {
            var sig = new List<int>();
            foreach (int i in cola) {
                int x = i % mw, y = i / mw;
                for (int k = 0; k < 4; k++) {
                    int nx = x + Dx4[k], ny = y + Dy4[k];
                    if (nx < 1 || ny < 1 || nx >= mw - 1 || ny >= mh - 1) continue;
                    int j = ny * mw + nx;
                    if ((Suelo)map[j] != Suelo.Acera) continue;
                    var b = Ciudad.BarrioDe(nx, ny);
                    if (b.Estilo != "industrial") continue;
                    map[j] = (byte)Suelo.Muelle; sig.Add(j);
                }
            }
            cola = sig;
        }

        // 2 · El patio de manzana es el hueco que queda dentro de una manzana y no toca la
        // calle. Se busca al revés: trozos de suelo pisable cerrados por edificio, sin
        // salida a calzada ni al borde del mapa, y pequeños —si mide más de trescientas
        // casillas (ocho mil metros cuadrados) no es un patio, es un parque al que se llega
        // por otro lado.
        var visto = new bool[n];
        var trozo = new List<int>();
        var pila = new Stack<int>();
        for (int i0 = 0; i0 < n; i0++) {
            var t0 = (Suelo)map[i0];
            if (visto[i0] || (t0 != Suelo.Acera && t0 != Suelo.Parque)) continue;
            trozo.Clear(); bool abierto = false;
            pila.Clear(); pila.Push(i0); visto[i0] = true;
            while (pila.Count > 0) {
                int i = pila.Pop(); trozo.Add(i);
                int x = i % mw, y = i / mw;
                if (x == 0 || y == 0 || x == mw - 1 || y == mh - 1) abierto = true;
                for (int k = 0; k < 4; k++) {
                    int nx = x + Dx4[k], ny = y + Dy4[k];
                    if (nx < 0 || ny < 0 || nx >= mw || ny >= mh) continue;
                    int j = ny * mw + nx; var tj = (Suelo)map[j];
                    if (tj == Suelo.Road || tj == Suelo.Puente || tj == Suelo.Monte || tj == Suelo.Via || tj == Suelo.Agua) {
                        abierto = true; continue;
                    }
                    if (visto[j] || (tj != Suelo.Acera && tj != Suelo.Parque)) continue;
                    visto[j] = true; pila.Push(j);
                }
            }
            if (abierto || trozo.Count > 300) continue;
            foreach (int i in trozo) map[i] = (byte)Suelo.Patio;
        }

        // 3 · La plaza es la acera que se ensancha tanto que deja de ser acera: Moyúa, el
        // Arriaga, la Plaza Nueva. Se mide por holgura —cuánto hay hasta lo primero que no
        // es acera— y no por superficie: una acera larguísima de la Gran Vía sigue siendo
        // una acera. Núcleo a partir de tres casillas de holgura (15 m), y de ahí se
        // extiende por lo que tenga dos, que es el borde de la plaza.
        var holg = new byte[n];
        cola = new List<int>();
        for (int i = 0; i < n; i++) if ((Suelo)map[i] != Suelo.Acera) cola.Add(i);
        for (int d = 0; d < 4 && cola.Count > 0; d++) {
            var sig = new List<int>();
            foreach (int i in cola) {
                int x = i % mw, y = i / mw;
                for (int dy = -1; dy <= 1; dy++)
                    for (int dx = -1; dx <= 1; dx++) {
                        int nx = x + dx, ny = y + dy;
                        if (nx < 0 || ny < 0 || nx >= mw || ny >= mh) continue;
                        int j = ny * mw + nx;
                        if (holg[j] != 0 || (Suelo)map[j] != Suelo.Acera) continue;
                        holg[j] = (byte)(d + 1); sig.Add(j);
                    }
            }
            cola = sig;
        }
        cola = new List<int>();
        for (int i = 0; i < n; i++) if (holg[i] >= 3) { map[i] = (byte)Suelo.Plaza; cola.Add(i); }
        while (cola.Count > 0) {
            var sig = new List<int>();
            foreach (int i in cola) {
                int x = i % mw, y = i / mw;
                for (int k = 0; k < 4; k++) {
                    int nx = x + Dx4[k], ny = y + Dy4[k];
                    if (nx < 0 || ny < 0 || nx >= mw || ny >= mh) continue;
                    int j = ny * mw + nx;
                    if ((Suelo)map[j] != Suelo.Acera || holg[j] < 2) continue;
                    map[j] = (byte)Suelo.Plaza; sig.Add(j);
                }
            }
            cola = sig;
        }
    }

    /// <summary>
    /// La plaza no sale midiendo el ancho de la acera: en el plano ninguna pasa de una
    /// casilla de holgura, ni la del Arenal. Pero el callejero sí lo sabe —setenta y siete
    /// de las 513 calles se llaman «Plaza …»—, así que lo que hace plaza a una casilla es
    /// su nombre, que es un dato del plano y no una corazonada. Se toma la acera de esas
    /// calles y se extiende por acera contigua: el rótulo cae por el centro y el borde de
    /// la plaza es la misma piedra. La plaza crece dos casillas y el muelle tres, que una
    /// explanada de carga es más ancha que el corro de un quiosco.
    ///
    /// Va después de Callejero.Nombrar(), que es quien reparte los nombres.
    /// </summary>
    public static void ClasificarNombres() {
        int mw = Ciudad.MW, mh = Ciudad.MH;
        var map = Ciudad.Map;

        Marca(new System.Text.RegularExpressions.Regex(@"^(plaza|plazuela)\b",
            System.Text.RegularExpressions.RegexOptions.IgnoreCase), Suelo.Plaza, 2, mw, mh, map);
        Marca(new System.Text.RegularExpressions.Regex(@"^muelle\b",
            System.Text.RegularExpressions.RegexOptions.IgnoreCase), Suelo.Muelle, 3, mw, mh, map);
    }

    static void Marca(System.Text.RegularExpressions.Regex re, Suelo tipo, int pasos, int mw, int mh, byte[] map) {
        var calles = Callejero.Calles;
        var suyas = new bool[calles.Length];
        for (int k = 0; k < calles.Length; k++) if (re.IsMatch(calles[k].Nombre)) suyas[k] = true;
        var cola = new List<int>();
        for (int i = 0; i < map.Length; i++) {
            int c = Callejero.Indice(i % mw, i / mw);
            if (c == 0 || !suyas[c - 1] || (Suelo)map[i] != Suelo.Acera) continue;
            map[i] = (byte)tipo; cola.Add(i);
        }
        for (int d = 0; d < pasos && cola.Count > 0; d++) {
            var sig = new List<int>();
            foreach (int i in cola) {
                int x = i % mw, y = i / mw;
                for (int k = 0; k < 4; k++) {
                    int nx = x + Dx4[k], ny = y + Dy4[k];
                    if (nx < 1 || ny < 1 || nx >= mw - 1 || ny >= mh - 1) continue;
                    int j = ny * mw + nx;
                    if ((Suelo)map[j] != Suelo.Acera) continue;
                    map[j] = (byte)tipo; sig.Add(j);
                }
            }
            cola = sig;
        }
    }
}

}

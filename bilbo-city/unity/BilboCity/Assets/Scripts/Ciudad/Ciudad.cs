using System;
using System.IO;
using System.IO.Compression;
using UnityEngine;

namespace BilboCity {

/// <summary>Un barrio de Bilbao: cómo se llama, de qué es su pavimento y a qué tira su luz.</summary>
public class Barrio {
    public readonly string Nombre, Estilo;
    public readonly Color32 Tinte;
    /// Donde el plano municipal pone su rótulo, en casillas.
    public readonly int X, Y;
    public Barrio(string nombre, string estilo, string tinte, int x, int y) {
        Nombre = nombre; Estilo = estilo; Tinte = Paleta.H(tinte); X = x; Y = y;
    }
}

/// <summary>
/// La planta de Bilbao. Ya no se genera: se carga.
///
/// El plano municipal es vectorial y trae la ciudad en dos capas que se separan limpias:
/// las manzanas, los parques y la ría son polígonos con su relleno, y la calzada es un
/// trazo blanco con el ancho real de cada calle. herramientas/plano/extraer.py separa
/// esas capas, las pasa a casillas y las deja en Plano.cs comprimidas. Lo que se dibuja
/// aquí son las calles de Bilbao —la retícula del Ensanche, la diagonal de la Gran Vía,
/// la elipse de Moyúa, la Ribera de Deustu entre el canal y la ría— y no unas calles
/// verosímiles.
///
/// El mapa mide 1440×776 casillas a 5,16 m cada una: 7,4 km de este a oeste por 4 de
/// norte a sur. Es rectangular porque el valle lo es.
/// </summary>
public static class Ciudad {
    public const int MW = Plano.MW, MH = Plano.MH;
    public static readonly byte[] Map = new byte[MW*MH];
    public static readonly byte[] Roof = new byte[MW*MH];
    /// Índice del barrio de cada casilla, en el orden de Plano.Barrios.
    public static readonly byte[] BarrioIdx = new byte[MW*MH];

    public static Barrio BarrioDe(int x, int y) {
        int k = Mathf.Clamp(y,0,MH-1)*MW + Mathf.Clamp(x,0,MW-1);
        int i = BarrioIdx[k];
        return i < Plano.Barrios.Length ? Plano.Barrios[i] : Plano.Barrios[0];
    }

    public static Suelo T(int x, int y) {
        if (x < 0 || y < 0 || x >= MW || y >= MH) return Suelo.Edif;
        return (Suelo)Map[y*MW+x];
    }
    public static bool Rodable(int x, int y) {
        var t = T(x,y);
        return t == Suelo.Road || t == Suelo.Puente || t == Suelo.Muelle;
    }
    public static bool Andable(Suelo t) { return t != Suelo.Edif && t != Suelo.Agua; }

    /// <summary>
    /// Deflate crudo, sin cabecera zlib: los mismos bytes que descomprime el prototipo
    /// con DecompressionStream("deflate-raw"), y sin meter una biblioteca en ninguno de
    /// los dos lados. Sin comprimir, a byte por casilla, serían 1,1 MB por capa.
    /// </summary>
    static byte[] Inflar(string b64) {
        var bin = Convert.FromBase64String(b64);
        using (var ms = new MemoryStream(bin))
        using (var ds = new DeflateStream(ms, CompressionMode.Decompress))
        using (var salida = new MemoryStream(MW*MH)) {
            ds.CopyTo(salida);
            return salida.ToArray();
        }
    }

    public static void Generar() {
        var trama = Inflar(Plano.Trama());
        var barrios = Inflar(Plano.TramaBarrio());
        Array.Copy(trama, Map, Mathf.Min(trama.Length, Map.Length));
        Array.Copy(barrios, BarrioIdx, Mathf.Min(barrios.Length, BarrioIdx.Length));
        Tejados();
        SuelosCiudad.Clasificar();
        // borde cerrado: fuera del término municipal no hay nada que visitar
        for (int x = 0; x < MW; x++) { Map[x] = (byte)Suelo.Edif; Map[(MH-1)*MW+x] = (byte)Suelo.Edif; }
        for (int y = 0; y < MH; y++) { Map[y*MW] = (byte)Suelo.Edif; Map[y*MW+MW-1] = (byte)Suelo.Edif; }
    }

    /// <summary>Un tejado por edificio contiguo.</summary>
    /// Esto sí se calcula aquí y no en el extractor: depende de cuántos tejados haya
    /// forjado el arte, que es cosa del juego y no del plano.
    /// <summary>Dónde empieza cada familia dentro de Forja.Tejados y cuántas variantes
    /// tiene: teja, pizarra, azotea y nave, en ese orden.</summary>
    static readonly System.Collections.Generic.Dictionary<string,int[]> FamRango =
        new System.Collections.Generic.Dictionary<string,int[]> {
            {"teja", new[]{0,5}}, {"pizarra", new[]{5,4}}, {"azotea", new[]{9,5}}, {"nave", new[]{14,5}}
        };

    /// <summary>Qué sombrero le toca a un edificio. Los umbrales salen de medir el plano,
    /// no de suponer: la mediana de una manzana son 44 casillas, el percentil 90 son 220 y
    /// el Casco Viejo entero es una sola pieza de 6366. El barrio manda antes que el tamaño
    /// donde se vive, o el casco sale de chapa ondulada.</summary>
    public static string FamiliaTejado(string estilo, int celdas) {
        if (estilo == "industrial") return celdas >= 110 ? "nave" : "azotea";
        if (estilo == "denso") return "teja";
        if (estilo == "senorial") return celdas >= 70 ? "pizarra" : "teja";
        if (celdas >= 900) return "nave";            // cocheras, lonjas, recintos feriales
        if (estilo == "bloques") return celdas >= 45 ? "azotea" : "teja";
        return celdas >= 90 ? "azotea" : "teja";
    }

    public static string FamiliaDe(int idx) {
        foreach (var kv in FamRango)
            if (idx >= kv.Value[0] && idx < kv.Value[0] + kv.Value[1]) return kv.Key;
        return "azotea";
    }

    /// <summary>Casillas de lado del parche de tejado. Una manzana del casco son seis mil
    /// casillas: con un solo tile es una plancha lisa, y por parches se lee lo que es —
    /// muchas casas pegadas— sin inventarse un plano que el municipal no da.</summary>
    const int Parche = 6;

    static void Tejados() {
        var visto = new bool[MW*MH];
        var celdas = new System.Collections.Generic.List<int>();
        System.Array.Clear(Roof, 0, Roof.Length);
        var pila = new System.Collections.Generic.Stack<int>();
        int[] dx = {1,-1,0,0}, dy = {0,0,1,-1};
        for (int y = 0; y < MH; y++)
            for (int x = 0; x < MW; x++) {
                int i0 = y*MW + x;
                if (T(x,y) != Suelo.Edif || visto[i0]) continue;
                celdas.Clear();
                pila.Push(i0); visto[i0] = true;
                while (pila.Count > 0) {
                    int i = pila.Pop(); celdas.Add(i);
                    int cx = i % MW, cy = i / MW;
                    for (int k = 0; k < 4; k++) {
                        int nx = cx + dx[k], ny = cy + dy[k];
                        if (nx < 0 || ny < 0 || nx >= MW || ny >= MH) continue;
                        int j = ny*MW + nx;
                        if (T(nx,ny) == Suelo.Edif && !visto[j]) { visto[j] = true; pila.Push(j); }
                    }
                }
                // El tamaño es del edificio entero, pero el material lo pone el barrio de
                // cada casilla: la manzana del Casco Viejo cruza a Abando, y tomando el
                // estilo del origen el casco entero salía de pizarra.
                int n = celdas.Count;
                foreach (int i in celdas) {
                    var b = BarrioDe(i % MW, i / MW);
                    var r = FamRango[FamiliaTejado(b != null ? b.Estilo : "bloques", n)];
                    Roof[i] = (byte)(r[0] + Utiles.Hash((i % MW)/Parche, (i / MW)/Parche) % r[1]);
                }
            }
    }

    // ═══════════ BÚSQUEDAS ═══════════
    /// <summary>Una casilla cualquiera del vecindario que cumpla la condición.</summary>
    /// Vale para lo que da igual dónde caiga: un peatón, un coche aparcado.
    public static Vector2 Buscar(System.Func<int,int,bool> cond, int cx, int cy, int rad) {
        for (int i = 0; i < 900; i++) {
            int x = cx < 0 ? Utiles.RndI(2, MW-3) : Mathf.Clamp(cx + Utiles.RndI(-rad,rad), 2, MW-3);
            int y = cy < 0 ? Utiles.RndI(2, MH-3) : Mathf.Clamp(cy + Utiles.RndI(-rad,rad), 2, MH-3);
            if (cond(x,y)) return new Vector2(x+0.5f, y+0.5f);
        }
        return new Vector2(MW/2f, MH/2f);
    }

    /// <summary>La casilla válida MÁS cercana al punto, buscando en anillos hacia fuera.</summary>
    /// Los sitios de verdad llevan la coordenada del plano municipal, y correr la catedral
    /// cien metros la saca del Casco Viejo. Los anillos son cuadrados, así que la esquina
    /// de uno queda más lejos que el centro del lado del siguiente: no vale quedarse con
    /// el primero que aparezca, hay que seguir mientras el anillo pueda mejorar.
    public static Vector2 CercaDe(System.Func<int,int,bool> cond, int cx, int cy, int rmax) {
        cx = Mathf.Clamp(cx, 1, MW-2); cy = Mathf.Clamp(cy, 1, MH-2);
        if (cond(cx,cy)) return new Vector2(cx+0.5f, cy+0.5f);
        int mx = -1, my = -1; float mejor = float.MaxValue;
        for (int r = 1; r <= rmax && r < mejor; r++)
            for (int d = -r; d <= r; d++) {
                int[] xs = { cx+d, cx+d, cx-r, cx+r };
                int[] ys = { cy-r, cy+r, cy+d, cy+d };
                for (int k = 0; k < 4; k++) {
                    int x = xs[k], y = ys[k];
                    if (x < 1 || y < 1 || x >= MW-1 || y >= MH-1) continue;
                    float q = Mathf.Sqrt((x-cx)*(x-cx) + (y-cy)*(y-cy));
                    if (q < mejor && cond(x,y)) { mejor = q; mx = x; my = y; }
                }
            }
        return mx < 0 ? new Vector2(cx+0.5f, cy+0.5f) : new Vector2(mx+0.5f, my+0.5f);
    }

    public static Vector2 PuntoAcera(int cx = -1, int cy = -1, int r = 40) {
        return Buscar((x,y) => { var t = T(x,y); return t == Suelo.Acera || t == Suelo.Plaza; }, cx, cy, r);
    }
    public static Vector2 PuntoCalle(int cx = -1, int cy = -1, int r = 40) {
        return Buscar((x,y) => T(x,y) == Suelo.Road, cx, cy, r);
    }
    /// <summary>Acera con fachada detrás y calle delante: donde va un portal de verdad.</summary>
    public static Vector2 PuntoPortal(int cx, int cy, int r = 60) {
        return CercaDe((x,y) => {
            if (T(x,y) != Suelo.Acera) return false;
            int fach = 0, calle = 0;
            int[] dxs = {1,-1,0,0}, dys = {0,0,1,-1};
            for (int k = 0; k < 4; k++) {
                var t = T(x+dxs[k], y+dys[k]);
                if (t == Suelo.Edif) fach++;
                if (t == Suelo.Road) calle++;
            }
            return fach > 0 && calle > 0;
        }, cx, cy, r);
    }
    /// <summary>Para los monumentos: la casilla pisable más próxima que no sea ladera.</summary>
    public static Vector2 PuntoZona(int cx, int cy, int r = 60) {
        return CercaDe((x,y) => { var t = T(x,y); return Andable(t) && t != Suelo.Monte; }, cx, cy, r);
    }
}

}

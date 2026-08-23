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

    struct Pieza { public string Clave; public float Dx, Dy; }

    static bool JuntoA(int x, int y, Suelo t) {
        return Ciudad.T(x+1,y) == t || Ciudad.T(x-1,y) == t || Ciudad.T(x,y+1) == t || Ciudad.T(x,y-1) == t;
    }

    static bool Cruce(int x, int y) {
        int n = 0;
        if (Ciudad.Rodable(x+1,y)) n++;
        if (Ciudad.Rodable(x-1,y)) n++;
        if (Ciudad.Rodable(x,y+1)) n++;
        if (Ciudad.Rodable(x,y-1)) n++;
        return n >= 3;
    }

    static bool Elegir(int x, int y, out Pieza p) {
        p = new Pieza();
        var t = Ciudad.T(x,y);
        var Z = Ciudad.ZonaDe(x,y);
        int h = Utiles.Hash(x*7+1, y*13+5);
        bool juntoCalle = JuntoA(x,y,Suelo.Road) || JuntoA(x,y,Suelo.Puente);

        if (t == Suelo.Acera) {
            // semáforo en las esquinas de los cruces grandes
            if (juntoCalle && Cruce(x,y) && h % 3 == 0) {
                p.Clave = "semaforo"; p.Dx = 0.5f; p.Dy = 0.9f; return true;
            }
            // farolas a intervalos regulares a lo largo de la acera
            if (juntoCalle && ((x*3 + y*5) % 11 == 0)) {
                p.Clave = "farola"; p.Dx = 0.5f; p.Dy = 0.95f; return true;
            }
            if (Z.Estilo == "industrial") {
                if (h % 23 == 0) { p.Clave = "pales";  p.Dx = 0.5f; p.Dy = 0.9f; return true; }
                if (h % 29 == 0) { p.Clave = "bidon";  p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            }
            if (Z.Estilo == "denso") {
                // terrazas y papeleras en el casco viejo
                if (h % 17 == 0) { p.Clave = "terraza";  p.Dx = 0.5f; p.Dy = 0.9f; return true; }
                if (h % 19 == 0) { p.Clave = "papelera"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            }
            if (juntoCalle && h % 31 == 0) { p.Clave = h % 2 == 0 ? "contenedor" : "contenedor2"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            if (h % 41 == 0) { p.Clave = "papelera"; p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            if (h % 97 == 0) { p.Clave = "cabina";   p.Dx = 0.5f; p.Dy = 0.9f; return true; }
            if (Z.Estilo == "senorial" && h % 13 == 0) { p.Clave = "arbolPodado"; p.Dx = 0.5f; p.Dy = 0.95f; return true; }
            return false;
        }

        if (t == Suelo.Plaza) {
            if (h % 9 == 0)  { p.Clave = "arbolPodado"; p.Dx = 0.5f; p.Dy = 0.95f; return true; }
            if (h % 14 == 0) { p.Clave = "banco";       p.Dx = 0.5f; p.Dy = 0.9f;  return true; }
            if (h % 37 == 0) { p.Clave = "papelera";    p.Dx = 0.5f; p.Dy = 0.9f;  return true; }
            return false;
        }

        if (t == Suelo.Parque) {
            // el monte va más tupido que un parque urbano
            int cada = Ciudad.ZonaDe(x,y).Monte ? 4 : 7;
            if (h % cada == 0) { p.Clave = "arbol"; p.Dx = 0.5f; p.Dy = 0.95f; return true; }
            if (h % 23 == 0)   { p.Clave = "banco"; p.Dx = 0.5f; p.Dy = 0.9f;  return true; }
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

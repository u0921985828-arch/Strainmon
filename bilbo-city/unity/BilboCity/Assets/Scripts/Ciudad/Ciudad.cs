using System.Collections.Generic;
using UnityEngine;

namespace BilboCity {

public class Zona {
    public string Nombre, Estilo;
    public int Sp, W, Ox, Oy;
    public bool Verde, Monte, Estadio;
    public Color32 Tinte;
}

/// <summary>
/// La planta de Bilbao. El atlas de 20×20 celdas reparte los barrios, y encima se tallan
/// la ría en arco, el Canal de Deusto, la Gran Vía y los puentes.
/// </summary>
public static class Ciudad {
    public const int MW = 160, MH = 160, CEL = 8;
    public static readonly byte[] Map = new byte[MW*MH];
    public static readonly byte[] Roof = new byte[MW*MH];

    static readonly string[] ATLAS = {
        "FFFFDDDDFFUUGGTTTTFF",
        "FFFDDDDDDFUUUGGTTTTF",
        "FFDDDDDDDDUUUGGTTTTT",
        "FFDDDDDDDDUUUGGGTTTT",
        "FFDDDDDDDDUUUGGGTTTT",
        "FFFDDDDDXCCCGGSSSTTT",
        "FZZDDDDXXXCCCSSSSSTT",
        "FZZZDDXXXACCCSSSSSTT",
        "FZZZZXXAAAACMSSSSSST",
        "OZZZZAAAAAMMMSSSSSSF",
        "OOZZZAAAAAMMMMSSSSFF",
        "OOOZPIIAAAMMMMMSSFFF",
        "OOOPPIIIAAMMMMMFFFFF",
        "OOOBPEIIIARMMMMFFFFF",
        "FOBBBEEIIRRRMMFFFFFF",
        "FBBBBBEIRRRRRFFFFFFF",
        "FBBBBBBRRRRRRFFFFFFF",
        "FFBBBBRRRRRRFFFFFFFF",
        "FFBBBBRRRRRFFFFFFFFF",
        "FFFBBBRRRFFFFFFFFFFF",
    };

    public static readonly Dictionary<char, Zona> Zonas = new Dictionary<char, Zona> {
        {'C', new Zona{ Nombre="Casco Viejo",  Sp=7,  W=2, Ox=1, Oy=2, Estilo="denso",      Tinte=Paleta.H("#6b4a2e") }},
        {'A', new Zona{ Nombre="Abando",       Sp=15, W=3, Ox=5, Oy=3, Estilo="senorial",   Tinte=Paleta.H("#4a4f5c") }},
        {'I', new Zona{ Nombre="Indautxu",     Sp=12, W=2, Ox=2, Oy=6, Estilo="senorial",   Tinte=Paleta.H("#55505f") }},
        {'X', new Zona{ Nombre="Abandoibarra", Sp=18, W=3, Ox=7, Oy=1, Estilo="abierto",    Tinte=Paleta.H("#5f6b74") }},
        {'D', new Zona{ Nombre="Deusto",       Sp=12, W=2, Ox=3, Oy=5, Estilo="bloques",    Tinte=Paleta.H("#4e5a52") }},
        {'Z', new Zona{ Nombre="Zorrotzaurre", Sp=22, W=3, Ox=2, Oy=2, Estilo="industrial", Tinte=Paleta.H("#6b5f45") }},
        {'O', new Zona{ Nombre="Olabeaga",     Sp=22, W=2, Ox=6, Oy=4, Estilo="industrial", Tinte=Paleta.H("#5a5340") }},
        {'S', new Zona{ Nombre="Santutxu",     Sp=11, W=2, Ox=4, Oy=1, Estilo="bloques",    Tinte=Paleta.H("#5c4a3a") }},
        {'G', new Zona{ Nombre="Begoña",       Sp=12, W=2, Ox=6, Oy=7, Estilo="bloques",    Tinte=Paleta.H("#57505a") }},
        {'U', new Zona{ Nombre="Uribarri",     Sp=12, W=2, Ox=0, Oy=3, Estilo="bloques",    Tinte=Paleta.H("#4f5a63") }},
        {'T', new Zona{ Nombre="Txurdinaga",   Sp=16, W=2, Ox=2, Oy=5, Estilo="bloques",    Tinte=Paleta.H("#4d5750") }},
        {'M', new Zona{ Nombre="Miribilla",    Sp=16, W=3, Ox=9, Oy=2, Estilo="senorial",   Tinte=Paleta.H("#525a63") }},
        {'B', new Zona{ Nombre="Basurto",      Sp=16, W=2, Ox=4, Oy=6, Estilo="bloques",    Tinte=Paleta.H("#4e5548") }},
        {'R', new Zona{ Nombre="Rekalde",      Sp=11, W=2, Ox=7, Oy=4, Estilo="denso",      Tinte=Paleta.H("#584c46") }},
        {'P', new Zona{ Nombre="Parque",       Verde=true, Estilo="parque", Tinte=Paleta.H("#46603f") }},
        {'E', new Zona{ Nombre="San Mamés",    Estadio=true, Sp=16, W=3, Estilo="abierto", Tinte=Paleta.H("#4a5f52") }},
        {'F', new Zona{ Nombre="Los montes",   Verde=true, Monte=true, Estilo="monte", Tinte=Paleta.H("#3f5a3c") }},
    };

    public static char CharDe(int x, int y) {
        int cy = Mathf.Clamp(y / CEL, 0, 19), cx = Mathf.Clamp(x / CEL, 0, 19);
        return ATLAS[cy][cx];
    }
    public static Zona ZonaDe(int x, int y) { return Zonas[CharDe(x,y)]; }

    public static Suelo T(int x, int y) {
        if (x < 0 || y < 0 || x >= MW || y >= MH) return Suelo.Edif;
        return (Suelo)Map[y*MW + x];
    }
    public static bool Rodable(int x, int y) {
        var t = T(x,y);
        return t == Suelo.Road || t == Suelo.Puente || t == Suelo.Muelle;
    }
    public static bool Andable(Suelo t) { return t != Suelo.Edif && t != Suelo.Agua; }

    static void Pon(int x, int y, Suelo t) { if (x >= 0 && y >= 0 && x < MW && y < MH) Map[y*MW+x] = (byte)t; }
    static void Rect(int x0, int y0, int w, int h, Suelo t) {
        for (int y = y0; y < y0+h; y++) for (int x = x0; x < x0+w; x++) Pon(x,y,t);
    }

    static readonly Vector2[] RIA = {
        new Vector2(158,120), new Vector2(142,102), new Vector2(126,84), new Vector2(110,64),
        new Vector2(95,48),   new Vector2(80,38),   new Vector2(66,38),  new Vector2(54,48),
        new Vector2(44,64),   new Vector2(34,86),   new Vector2(22,108), new Vector2(10,130),
        new Vector2(0,146)
    };
    static readonly Vector2[] CANAL = {
        new Vector2(46,52), new Vector2(36,68), new Vector2(26,88), new Vector2(16,110), new Vector2(6,130)
    };

    static void Linea(Vector2[] pts, float ancho, Suelo t, System.Func<int,int,bool> soloSi) {
        for (int i = 0; i < pts.Length-1; i++) {
            Vector2 a = pts[i], b = pts[i+1];
            int n = Mathf.CeilToInt(Vector2.Distance(a,b) * 2);
            for (int k = 0; k <= n; k++) {
                float px = Mathf.Lerp(a.x,b.x,k/(float)n), py = Mathf.Lerp(a.y,b.y,k/(float)n);
                int r = Mathf.CeilToInt(ancho/2f);
                for (int dy = -r; dy <= r; dy++)
                    for (int dx = -r; dx <= r; dx++) {
                        if (dx*dx + dy*dy > (ancho/2f)*(ancho/2f)) continue;
                        int qx = Mathf.RoundToInt(px+dx), qy = Mathf.RoundToInt(py+dy);
                        if (soloSi != null && !soloSi(qx,qy)) continue;
                        Pon(qx,qy,t);
                    }
            }
        }
    }

    struct PuntoRuta { public float x, y, ang; }
    static PuntoRuta EnRuta(Vector2[] pts, float t) {
        float total = 0;
        var seg = new float[pts.Length-1];
        for (int i = 0; i < pts.Length-1; i++) { seg[i] = Vector2.Distance(pts[i],pts[i+1]); total += seg[i]; }
        float rec = t * total;
        for (int i = 0; i < seg.Length; i++) {
            if (rec <= seg[i]) {
                float f = rec / seg[i];
                return new PuntoRuta {
                    x = Mathf.Lerp(pts[i].x, pts[i+1].x, f),
                    y = Mathf.Lerp(pts[i].y, pts[i+1].y, f),
                    ang = Mathf.Atan2(pts[i+1].y-pts[i].y, pts[i+1].x-pts[i].x)
                };
            }
            rec -= seg[i];
        }
        var l = pts[pts.Length-1];
        return new PuntoRuta { x = l.x, y = l.y, ang = 0 };
    }

    public static void Generar() {
        // 1 · relleno por zona
        for (int y = 0; y < MH; y++)
            for (int x = 0; x < MW; x++)
                Map[y*MW+x] = (byte)(ZonaDe(x,y).Verde ? Suelo.Parque : Suelo.Edif);

        // 2 · avenidas en las fronteras entre barrios
        for (int cy = 0; cy < 20; cy++)
            for (int cx = 0; cx < 20; cx++) {
                char c = ATLAS[cy][cx];
                if (cx < 19 && ATLAS[cy][cx+1] != c) Rect((cx+1)*CEL-2, cy*CEL, 4, CEL, Suelo.Road);
                if (cy < 19 && ATLAS[cy+1][cx] != c) Rect(cx*CEL, (cy+1)*CEL-2, CEL, 4, Suelo.Road);
            }

        // 3 · trama interior de cada barrio
        for (int y = 0; y < MH; y++)
            for (int x = 0; x < MW; x++) {
                var Z = ZonaDe(x,y);
                if (Z.Verde) {
                    if (((x+3) % 24) < 1 || ((y+7) % 24) < 1) Map[y*MW+x] = (byte)Suelo.Acera;
                    continue;
                }
                if (Z.Estadio) continue;
                if (((x+Z.Ox) % Z.Sp) < Z.W || ((y+Z.Oy) % Z.Sp) < Z.W) Map[y*MW+x] = (byte)Suelo.Road;
            }

        // 4 · la Gran Vía, con Moyúa y Sagrado Corazón
        Linea(new[]{ new Vector2(102,54), new Vector2(86,64), new Vector2(70,76), new Vector2(56,88) },
              5, Suelo.Road, (x,y) => !ZonaDe(Mathf.Clamp(x,0,MW-1),Mathf.Clamp(y,0,MH-1)).Verde);
        for (int dy = -7; dy <= 7; dy++) for (int dx = -7; dx <= 7; dx++) {
            if (dx*dx+dy*dy > 49) continue;
            Pon(86+dx, 64+dy, dx*dx+dy*dy > 30 ? Suelo.Road : Suelo.Plaza);
        }
        for (int dy = -5; dy <= 5; dy++) for (int dx = -5; dx <= 5; dx++) {
            if (dx*dx+dy*dy > 25) continue;
            Pon(56+dx, 88+dy, dx*dx+dy*dy > 15 ? Suelo.Road : Suelo.Plaza);
        }

        // 5 · San Mamés
        int sx = 0, sy = 0, n = 0;
        for (int cy = 0; cy < 20; cy++) for (int cx = 0; cx < 20; cx++)
            if (ATLAS[cy][cx] == 'E') { Rect(cx*CEL, cy*CEL, CEL, CEL, Suelo.Plaza); sx += cx*CEL+4; sy += cy*CEL+4; n++; }
        if (n > 0) {
            int ex = sx/n, ey = sy/n;
            for (int dy = -11; dy <= 11; dy++)
                for (int dx = -13; dx <= 13; dx++) {
                    float e = (dx*dx)/169f + (dy*dy)/121f;
                    if (e > 1) continue;
                    Pon(ex+dx, ey+dy, e > 0.62f ? Suelo.Edif : (e > 0.5f ? Suelo.Plaza : Suelo.Parque));
                }
            Rect(ex-6, ey-1, 12, 2, Suelo.Plaza);
        }

        // 6 · la ría y el canal
        Linea(RIA, 9, Suelo.Agua, null);
        Linea(CANAL, 7, Suelo.Agua, null);

        // 7 · puentes
        float[] tsRia = { .14f,.27f,.36f,.44f,.5f,.58f,.68f,.79f };
        foreach (float t in tsRia) Puente(RIA, t, 13);
        foreach (float t in new[]{ .3f,.6f }) Puente(CANAL, t, 11);

        // 8 · muelles del puerto viejo
        for (int x = 1; x < MW-1; x++)
            for (int y = 1; y < MH-1; y++) {
                if (Map[y*MW+x] != (byte)Suelo.Edif) continue;
                if (ZonaDe(x,y).Estilo != "industrial") continue;
                if (Map[(y+1)*MW+x] == (byte)Suelo.Agua || Map[(y-1)*MW+x] == (byte)Suelo.Agua ||
                    Map[y*MW+x+1] == (byte)Suelo.Agua || Map[y*MW+x-1] == (byte)Suelo.Agua)
                    Map[y*MW+x] = (byte)Suelo.Muelle;
            }

        // 9 · patios de manzana
        Patios();

        // 10 · aceras: toda fachada que da a la calle
        var cop = (byte[])Map.Clone();
        for (int y = 0; y < MH; y++)
            for (int x = 0; x < MW; x++) {
                if (cop[y*MW+x] != (byte)Suelo.Edif) continue;
                bool borde = false;
                int[] dxs = {1,-1,0,0}, dys = {0,0,1,-1};
                for (int k = 0; k < 4; k++) {
                    int nx = x+dxs[k], ny = y+dys[k];
                    if (nx < 0 || ny < 0 || nx >= MW || ny >= MH) continue;
                    var t = (Suelo)cop[ny*MW+nx];
                    if (t == Suelo.Road || t == Suelo.Puente || t == Suelo.Plaza || t == Suelo.Muelle || t == Suelo.Parque)
                    { borde = true; break; }
                }
                if (borde) Map[y*MW+x] = (byte)Suelo.Acera;
            }

        // 11 · un tejado por edificio contiguo, para que el bloque se lea entero
        Tejados();

        for (int i = 0; i < MW; i++) {
            Pon(i,0,Suelo.Edif); Pon(i,MH-1,Suelo.Edif); Pon(0,i,Suelo.Edif); Pon(MW-1,i,Suelo.Edif);
        }
    }

    static void Puente(Vector2[] ruta, float t, int alcance) {
        var p = EnRuta(ruta, t);
        float per = p.ang + Mathf.PI/2f;
        for (int d = -alcance; d <= alcance; d++)
            for (int w = -2; w <= 2; w++) {
                int px = Mathf.RoundToInt(p.x + Mathf.Cos(per)*d + Mathf.Cos(p.ang)*w);
                int py = Mathf.RoundToInt(p.y + Mathf.Sin(per)*d + Mathf.Sin(p.ang)*w);
                if (T(px,py) == Suelo.Agua) Pon(px,py,Suelo.Puente);
            }
    }

    static void Patios() {
        var visto = new bool[MW*MH];
        var pila = new Stack<Vector2Int>();
        for (int y = 0; y < MH; y++)
            for (int x = 0; x < MW; x++) {
                if (Map[y*MW+x] != (byte)Suelo.Edif || visto[y*MW+x]) continue;
                int x0 = x, x1 = x, y0 = y, y1 = y, cuenta = 0;
                pila.Clear(); pila.Push(new Vector2Int(x,y)); visto[y*MW+x] = true;
                while (pila.Count > 0) {
                    var c = pila.Pop(); cuenta++;
                    if (c.x < x0) x0 = c.x; if (c.x > x1) x1 = c.x;
                    if (c.y < y0) y0 = c.y; if (c.y > y1) y1 = c.y;
                    int[] dxs = {1,-1,0,0}, dys = {0,0,1,-1};
                    for (int k = 0; k < 4; k++) {
                        int nx = c.x+dxs[k], ny = c.y+dys[k];
                        if (nx < 0 || ny < 0 || nx >= MW || ny >= MH || visto[ny*MW+nx]) continue;
                        if (Map[ny*MW+nx] == (byte)Suelo.Edif) { visto[ny*MW+nx] = true; pila.Push(new Vector2Int(nx,ny)); }
                    }
                }
                int w = x1-x0+1, h = y1-y0+1;
                var Z = ZonaDe(x0,y0);
                if (w < 6 || h < 6 || cuenta < 36) continue;
                int hh = Utiles.Hash(x0,y0);
                if (Z.Estilo == "denso" && hh % 3 != 0) continue;
                if (hh % 10 < 6) {
                    int pw = Mathf.Max(2, (int)(w*0.4f)), ph = Mathf.Max(2, (int)(h*0.4f));
                    Rect(x0 + (w-pw)/2, y0 + (h-ph)/2, pw, ph, Suelo.Patio);
                } else if (hh % 10 < 8) {
                    int cw = (int)(w*0.45f), ch = (int)(h*0.45f);
                    Rect((hh>>3)%2 == 1 ? x0 : x1-cw+1, (hh>>4)%2 == 1 ? y0 : y1-ch+1, cw, ch,
                         Z.Estilo == "abierto" ? Suelo.Plaza : Suelo.Patio);
                }
            }
    }

    static void Tejados() {
        System.Array.Clear(Roof, 0, Roof.Length);
        var visto = new bool[MW*MH];
        var pila = new Stack<Vector2Int>();
        for (int y = 0; y < MH; y++)
            for (int x = 0; x < MW; x++) {
                if (Map[y*MW+x] != (byte)Suelo.Edif || visto[y*MW+x]) continue;
                int idx = Utiles.Hash(x,y) % 8;
                bool az = Utiles.Hash(x*3, y*5) % 5 == 0;
                pila.Clear(); pila.Push(new Vector2Int(x,y)); visto[y*MW+x] = true;
                while (pila.Count > 0) {
                    var c = pila.Pop();
                    Roof[c.y*MW+c.x] = (byte)(az ? 8 + (idx % 8) : idx);
                    int[] dxs = {1,-1,0,0}, dys = {0,0,1,-1};
                    for (int k = 0; k < 4; k++) {
                        int nx = c.x+dxs[k], ny = c.y+dys[k];
                        if (nx < 0 || ny < 0 || nx >= MW || ny >= MH || visto[ny*MW+nx]) continue;
                        if (Map[ny*MW+nx] == (byte)Suelo.Edif) { visto[ny*MW+nx] = true; pila.Push(new Vector2Int(nx,ny)); }
                    }
                }
            }
    }

    // ═══════════ BÚSQUEDAS ═══════════
    public static Vector2 Buscar(System.Func<int,int,bool> cond, int cx, int cy, int rad) {
        for (int i = 0; i < 900; i++) {
            int x = cx < 0 ? Utiles.RndI(2, MW-3) : Mathf.Clamp(cx + Utiles.RndI(-rad,rad), 2, MW-3);
            int y = cy < 0 ? Utiles.RndI(2, MH-3) : Mathf.Clamp(cy + Utiles.RndI(-rad,rad), 2, MH-3);
            if (cond(x,y)) return new Vector2(x+0.5f, y+0.5f);
        }
        return new Vector2(MW/2f, MH/2f);
    }
    public static Vector2 PuntoAcera(int cx = -1, int cy = -1, int r = 40) {
        return Buscar((x,y) => { var t = T(x,y); return t == Suelo.Acera || t == Suelo.Plaza; }, cx, cy, r);
    }
    public static Vector2 PuntoCalle(int cx = -1, int cy = -1, int r = 40) {
        return Buscar((x,y) => T(x,y) == Suelo.Road, cx, cy, r);
    }
    /// <summary>Acera con fachada detrás y calle delante: donde va un portal de verdad.</summary>
    public static Vector2 PuntoPortal(int cx, int cy, int r, char zona) {
        return Buscar((x,y) => {
            if (T(x,y) != Suelo.Acera) return false;
            if (zona != '\0' && CharDe(x,y) != zona) return false;
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
    public static Vector2 PuntoZona(int cx, int cy, int r, char zona) {
        return Buscar((x,y) => {
            var t = T(x,y);
            if (t != Suelo.Acera && t != Suelo.Plaza && t != Suelo.Parque) return false;
            return zona == '\0' || CharDe(x,y) == zona;
        }, cx, cy, r);
    }
}

}

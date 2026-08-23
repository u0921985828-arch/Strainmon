using UnityEngine;

namespace BilboCity {

/// <summary>Paleta bloqueada de 48 colores y cuantizador. Ningún sprite se sale de aquí.</summary>
public static class Paleta {
    public static Color32 H(string hex) {
        int r = System.Convert.ToInt32(hex.Substring(1,2),16);
        int g = System.Convert.ToInt32(hex.Substring(3,2),16);
        int b = System.Convert.ToInt32(hex.Substring(5,2),16);
        return new Color32((byte)r,(byte)g,(byte)b,255);
    }

    public static readonly Color32 Negro     = H("#0b0e12");
    public static readonly Color32 Carbon    = H("#1c2229");
    public static readonly Color32 Asfalto   = H("#33383e");
    public static readonly Color32 AsfaltoO  = H("#2a2f34");
    public static readonly Color32 AsfaltoL  = H("#3f454c");
    public static readonly Color32 Gris      = H("#4a444c");
    public static readonly Color32 GrisO     = H("#3a353c");
    public static readonly Color32 GrisL     = H("#5f5a63");
    public static readonly Color32 Acero     = H("#8d99a4");
    public static readonly Color32 AceroO    = H("#6d7883");
    public static readonly Color32 Hueso     = H("#e6e2d6");
    public static readonly Color32 Hormigon  = H("#7b7669");
    public static readonly Color32 HormigonO = H("#655f55");
    public static readonly Color32 HormigonL = H("#948e80");
    public static readonly Color32 Piel1     = H("#f0cfae");
    public static readonly Color32 Piel2     = H("#e0b48c");
    public static readonly Color32 Piel3     = H("#c69068");
    public static readonly Color32 Piel4     = H("#a87247");
    public static readonly Color32 Piel5     = H("#8d6142");
    public static readonly Color32 Piel6     = H("#6b482f");
    public static readonly Color32 Pelo1     = H("#2a2018");
    public static readonly Color32 Pelo2     = H("#4a3520");
    public static readonly Color32 Pelo3     = H("#7a5a2a");
    public static readonly Color32 Pelo4     = H("#b09a72");
    public static readonly Color32 Pelo5     = H("#8d99a4");
    public static readonly Color32 Azul      = H("#1f3a5f");
    public static readonly Color32 AzulO     = H("#152741");
    public static readonly Color32 AzulL     = H("#2f5182");
    public static readonly Color32 Rojo      = H("#b7451f");
    public static readonly Color32 RojoO     = H("#8e3316");
    public static readonly Color32 RojoL     = H("#d05c33");
    public static readonly Color32 Sangre    = H("#951f18");
    public static readonly Color32 Verde     = H("#3d6b4a");
    public static readonly Color32 VerdeO    = H("#2d5137");
    public static readonly Color32 VerdeL    = H("#508a5f");
    public static readonly Color32 Cesped    = H("#3c6338");
    public static readonly Color32 CespedO   = H("#2f5330");
    public static readonly Color32 Agua      = H("#1c4652");
    public static readonly Color32 AguaL     = H("#2a6473");
    public static readonly Color32 Mostaza   = H("#e8c547");
    public static readonly Color32 MostazaO  = H("#b89a2c");
    public static readonly Color32 Morado    = H("#5b4a76");
    public static readonly Color32 Teja      = H("#7a5f52");
    public static readonly Color32 TejaO     = H("#5f4840");
    public static readonly Color32 Madera    = H("#6b4326");
    public static readonly Color32 MaderaO   = H("#4d3019");
    public static readonly Color32 MaderaL   = H("#8a5c37");
    public static readonly Color32 Blanco    = H("#f4f2ea");
    public static readonly Color32 Crema     = H("#d8d4c4");

    static Color32[] _lista;
    public static Color32[] Lista {
        get {
            if (_lista == null) _lista = new Color32[] {
                Negro,Carbon,Asfalto,AsfaltoO,AsfaltoL,Gris,GrisO,GrisL,Acero,AceroO,Hueso,
                Hormigon,HormigonO,HormigonL,Piel1,Piel2,Piel3,Piel4,Piel5,Piel6,
                Pelo1,Pelo2,Pelo3,Pelo4,Pelo5,Azul,AzulO,AzulL,Rojo,RojoO,RojoL,Sangre,
                Verde,VerdeO,VerdeL,Cesped,CespedO,Agua,AguaL,Mostaza,MostazaO,Morado,
                Teja,TejaO,Madera,MaderaO,MaderaL,Blanco,Crema
            };
            return _lista;
        }
    }

    public static void Cuantizar(Color32[] px) {
        var pal = Lista;
        for (int i = 0; i < px.Length; i++) {
            if (px[i].a < 128) { px[i] = new Color32(0,0,0,0); continue; }
            int mejor = 0, md = int.MaxValue;
            for (int k = 0; k < pal.Length; k++) {
                int dr = pal[k].r - px[i].r, dg = pal[k].g - px[i].g, db = pal[k].b - px[i].b;
                int d = dr*dr + dg*dg + db*db;
                if (d < md) { md = d; mejor = k; }
            }
            var c = pal[mejor];
            px[i] = new Color32(c.r, c.g, c.b, 255);
        }
    }
}

/// <summary>Lienzo en memoria con origen arriba-izquierda, como en el prototipo web.</summary>
public class Lienzo {
    public readonly int W, H;
    public readonly Color32[] Px;

    public Lienzo(int w, int h) { W = w; H = h; Px = new Color32[w*h]; }

    public void P(int x, int y, int w, int h, Color32 c) {
        int x1 = Mathf.Min(W, x+w), y1 = Mathf.Min(H, y+h);
        for (int j = Mathf.Max(0,y); j < y1; j++)
            for (int i = Mathf.Max(0,x); i < x1; i++)
                Px[j*W + i] = c;
    }
    public void P(float x, float y, float w, float h, Color32 c) {
        P(Mathf.FloorToInt(x), Mathf.FloorToInt(y), Mathf.RoundToInt(w), Mathf.RoundToInt(h), c);
    }
    public void Rellenar(Color32 c) { for (int i = 0; i < Px.Length; i++) Px[i] = c; }

    /// <summary>Abre un hueco de verdad.</summary>
    /// Pintar con un color transparente no borra: escribe alfa cero encima, sí, pero
    /// hacerlo con P() y un Color32 a cero es justo esto, y con nombre se entiende.
    public void Borrar(int x, int y, int w, int h) { P(x, y, w, h, new Color32(0,0,0,0)); }

    /// <summary>Rodea de un color todo lo dibujado.</summary>
    /// Un icono se mira a 24 píxeles y sobre fondos de cualquier color: la caja oscura
    /// del HUD, la fila del móvil, el marco claro de la tienda. Sin contorno, la mitad se
    /// pierden contra el fondo.
    public void Contorno(Color32 col) {
        var copia = (Color32[])Px.Clone();
        System.Func<int,int,bool> hay = (x,y) =>
            x >= 0 && y >= 0 && x < W && y < H && copia[y*W+x].a > 0;
        for (int y = 0; y < H; y++)
            for (int x = 0; x < W; x++) {
                if (copia[y*W+x].a > 0) continue;
                bool v = false;
                for (int dy = -1; dy <= 1 && !v; dy++)
                    for (int dx = -1; dx <= 1 && !v; dx++) if (hay(x+dx, y+dy)) v = true;
                if (v) Px[y*W+x] = col;
            }
    }

    public void Ruido(Color32[] cols, int densidad) {
        for (int y = 0; y < H; y++)
            for (int x = 0; x < W; x++) {
                int v = (x*7 + y*13 + ((x*3)^(y*5))) % 100;
                if (v < densidad) Px[y*W+x] = cols[(x*3 + y*7) % cols.Length];
            }
    }

    /// <summary>Relleno de polígono por test de interior: sólido, sin dientes.</summary>
    public void Poligono(Vector2[] pts, Color32 c) {
        for (int y = 0; y < H; y++)
            for (int x = 0; x < W; x++) {
                float px = x + 0.5f, py = y + 0.5f;
                bool dentro = false;
                for (int i = 0, j = pts.Length-1; i < pts.Length; j = i++) {
                    if ((pts[i].y > py) != (pts[j].y > py) &&
                        px < (pts[j].x - pts[i].x) * (py - pts[i].y) / (pts[j].y - pts[i].y) + pts[i].x)
                        dentro = !dentro;
                }
                if (dentro) Px[y*W+x] = c;
            }
    }

    public static Vector2[] Girar(Vector2[] pts, float ang, float cx, float cy) {
        float ca = Mathf.Cos(ang), sa = Mathf.Sin(ang);
        var r = new Vector2[pts.Length];
        for (int i = 0; i < pts.Length; i++)
            r[i] = new Vector2(cx + pts[i].x*ca - pts[i].y*sa, cy + pts[i].x*sa + pts[i].y*ca);
        return r;
    }

    /// <summary>Vuelca en un atlas volteando la Y, porque Unity numera las texturas de abajo arriba.</summary>
    public void VolcarEn(Color32[] destino, int destW, int destH, int ox, int oy) {
        for (int y = 0; y < H; y++) {
            int dy = destH - 1 - (oy + y);
            if (dy < 0 || dy >= destH) continue;
            for (int x = 0; x < W; x++) {
                int dx = ox + x;
                if (dx < 0 || dx >= destW) continue;
                destino[dy*destW + dx] = Px[y*W + x];
            }
        }
    }
}

public static class Utiles {
    public static int Hash(int a, int b) {
        int h = (a * 73856093) ^ (b * 19349663);
        h = (h ^ (h >> 13)) * 1274126177;
        return Mathf.Abs(h ^ (h >> 16));
    }
    public static float Rnd(float a, float b) { return a + Random.value * (b - a); }
    public static int RndI(int a, int b) { return Random.Range(a, b + 1); }

    public static Texture2D Textura(int w, int h, Color32[] px) {
        var t = new Texture2D(w, h, TextureFormat.RGBA32, false);
        t.filterMode = FilterMode.Point;
        t.wrapMode = TextureWrapMode.Clamp;
        t.SetPixels32(px);
        t.Apply();
        return t;
    }

    /// <summary>Sprite recortado de un atlas. El pivote va en píxeles del recorte.</summary>
    public static Sprite Rebanada(Texture2D tex, int x, int y, int w, int h, float pivX, float pivY) {
        return Sprite.Create(tex, new Rect(x, y, w, h),
            new Vector2(pivX / w, pivY / h), 32f, 0, SpriteMeshType.FullRect);
    }
}

}

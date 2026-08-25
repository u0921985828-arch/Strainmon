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

    // La paleta de CONTEXT.md §18.6: seis familias de ocho tonos y los acentos. La
    // familia de piel se llama Tez porque Piel1..Piel6 ya eran los tonos de la forja.
    // herramientas/plano/paleta.py compara esta lista con la del HTML.
    public static readonly Color32 Hormigon0  = H("#1a1c21");
    public static readonly Color32 Hormigon1  = H("#2b2f36");
    public static readonly Color32 Hormigon2  = H("#3d434c");
    public static readonly Color32 Hormigon3  = H("#525963");
    public static readonly Color32 Hormigon4  = H("#6b7280");
    public static readonly Color32 Hormigon5  = H("#8a919c");
    public static readonly Color32 Hormigon6  = H("#a9b0ba");
    public static readonly Color32 Hormigon7  = H("#c8cdd5");
    public static readonly Color32 Ladrillo0  = H("#2a1512");
    public static readonly Color32 Ladrillo1  = H("#43231c");
    public static readonly Color32 Ladrillo2  = H("#5e3227");
    public static readonly Color32 Ladrillo3  = H("#7a4232");
    public static readonly Color32 Ladrillo4  = H("#96543e");
    public static readonly Color32 Ladrillo5  = H("#b06b52");
    public static readonly Color32 Ladrillo6  = H("#c68a6e");
    public static readonly Color32 Ladrillo7  = H("#d9a98f");
    public static readonly Color32 Verde0     = H("#121a14");
    public static readonly Color32 Verde1     = H("#1d2c20");
    public static readonly Color32 Verde2     = H("#2b412e");
    public static readonly Color32 Verde3     = H("#3a573d");
    public static readonly Color32 Verde4     = H("#4c6e4c");
    public static readonly Color32 Verde5     = H("#63875f");
    public static readonly Color32 Verde6     = H("#7fa277");
    public static readonly Color32 Verde7     = H("#9fbc94");
    public static readonly Color32 Ria0       = H("#0d1424");
    public static readonly Color32 Ria1       = H("#141f38");
    public static readonly Color32 Ria2       = H("#1e2a4a");
    public static readonly Color32 Ria3       = H("#2a3a61");
    public static readonly Color32 Ria4       = H("#3a4e7a");
    public static readonly Color32 Ria5       = H("#4e6595");
    public static readonly Color32 Ria6       = H("#6681af");
    public static readonly Color32 Ria7       = H("#84a0c8");
    public static readonly Color32 Luz0       = H("#2e1f08");
    public static readonly Color32 Luz1       = H("#4a3210");
    public static readonly Color32 Luz2       = H("#69481a");
    public static readonly Color32 Luz3       = H("#8a6127");
    public static readonly Color32 Luz4       = H("#ab7c37");
    public static readonly Color32 Luz5       = H("#c8974b");
    public static readonly Color32 Luz6       = H("#e0b468");
    public static readonly Color32 Luz7       = H("#f2d294");
    public static readonly Color32 Tez0       = H("#3d2419");
    public static readonly Color32 Tez1       = H("#573424");
    public static readonly Color32 Tez2       = H("#734833");
    public static readonly Color32 Tez3       = H("#8f5f45");
    public static readonly Color32 Tez4       = H("#ab7a5c");
    public static readonly Color32 Tez5       = H("#c29578");
    public static readonly Color32 Tez6       = H("#d6b096");
    public static readonly Color32 Tez7       = H("#e8cab4");
    public static readonly Color32 Peligro0   = H("#8b1a1a");
    public static readonly Color32 Peligro1   = H("#b82424");
    public static readonly Color32 Peligro2   = H("#d94040");
    public static readonly Color32 Aviso0     = H("#c8971e");
    public static readonly Color32 Aviso1     = H("#e5b62f");
    public static readonly Color32 Titanio0   = H("#c4d4e0");
    public static readonly Color32 Titanio1   = H("#e8f4ff");
    public static readonly Color32 Policia0   = H("#1b3a8c");
    public static readonly Color32 Policia1   = H("#2d55c4");
    public static readonly Color32 Senal      = H("#1f7a4c");
    public static readonly Color32 Nieve      = H("#f5f7fa");
    public static readonly Color32 Tinta      = H("#000000");
    public static readonly Color32 Interfaz   = H("#e8e4dc");

    // Los de siempre, ahora apodos. Los usa todo el arte forjado.
    public static readonly Color32 Negro      = Tinta;
    public static readonly Color32 Carbon     = Hormigon0;
    public static readonly Color32 Asfalto    = Hormigon1;
    public static readonly Color32 AsfaltoO   = Hormigon0;
    public static readonly Color32 AsfaltoL   = Hormigon2;
    public static readonly Color32 Gris       = Hormigon2;
    public static readonly Color32 GrisO      = Hormigon1;
    public static readonly Color32 GrisL      = Hormigon3;
    public static readonly Color32 Acero      = Hormigon5;
    public static readonly Color32 AceroO     = Hormigon4;
    public static readonly Color32 Hueso      = Hormigon7;
    public static readonly Color32 Hormigon   = Hormigon4;
    public static readonly Color32 HormigonO  = Hormigon3;
    public static readonly Color32 HormigonL  = Hormigon5;
    public static readonly Color32 Piel1      = Tez7;
    public static readonly Color32 Piel2      = Tez6;
    public static readonly Color32 Piel3      = Tez5;
    public static readonly Color32 Piel4      = Tez4;
    public static readonly Color32 Piel5      = Tez3;
    public static readonly Color32 Piel6      = Tez2;
    public static readonly Color32 Pelo1      = Ladrillo0;
    public static readonly Color32 Pelo2      = Ladrillo1;
    public static readonly Color32 Pelo3      = Luz2;
    public static readonly Color32 Pelo4      = Luz6;
    public static readonly Color32 Pelo5      = Hormigon5;
    public static readonly Color32 Azul       = Ria3;
    public static readonly Color32 AzulO      = Ria2;
    public static readonly Color32 AzulL      = Ria4;
    public static readonly Color32 Rojo       = Peligro1;
    public static readonly Color32 RojoO      = Peligro0;
    public static readonly Color32 RojoL      = Peligro2;
    public static readonly Color32 Sangre     = Peligro0;
    public static readonly Color32 Verde      = Verde4;
    public static readonly Color32 VerdeO     = Verde3;
    public static readonly Color32 VerdeL     = Verde5;
    public static readonly Color32 Cesped     = Verde3;
    public static readonly Color32 CespedO    = Verde2;
    public static readonly Color32 Agua       = Ria1;
    public static readonly Color32 AguaL      = Ria2;
    public static readonly Color32 Mostaza    = Aviso1;
    public static readonly Color32 MostazaO   = Aviso0;
    public static readonly Color32 Morado     = Ria4;
    public static readonly Color32 Teja       = Ladrillo2;
    public static readonly Color32 TejaO      = Ladrillo1;
    public static readonly Color32 Madera     = Ladrillo2;
    public static readonly Color32 MaderaO    = Ladrillo0;
    public static readonly Color32 MaderaL    = Ladrillo4;
    public static readonly Color32 Blanco     = Nieve;
    public static readonly Color32 Crema      = Interfaz;

    static Color32[] _lista;
    public static Color32[] Lista {
        get {
            if (_lista == null) _lista = new Color32[] {
                Hormigon0,Hormigon1,Hormigon2,Hormigon3,Hormigon4,Hormigon5,Hormigon6,Hormigon7,
                Ladrillo0,Ladrillo1,Ladrillo2,Ladrillo3,Ladrillo4,Ladrillo5,Ladrillo6,Ladrillo7,
                Verde0,Verde1,Verde2,Verde3,Verde4,Verde5,Verde6,Verde7,
                Ria0,Ria1,Ria2,Ria3,Ria4,Ria5,Ria6,Ria7,
                Luz0,Luz1,Luz2,Luz3,Luz4,Luz5,Luz6,Luz7,
                Tez0,Tez1,Tez2,Tez3,Tez4,Tez5,Tez6,Tez7,
                Peligro0,Peligro1,Peligro2,Aviso0,Aviso1,Titanio0,Titanio1,Policia0,
                Policia1,Senal,Nieve,Tinta,Interfaz
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

    /// <summary>Quita el píxel de cada esquina recta de la silueta.</summary>
    /// Todo lo que dibuja la forja son rectángulos —P() no sabe hacer otra cosa— y a 26
    /// píxeles la suma de rectángulos se lee como un montón de cajas apiladas: el cráneo,
    /// el hombro y la puntera son cantos de noventa grados. Quitando la esquina, la
    /// silueta se redondea sin dibujar una forma nueva.
    /// La condición es apretada a propósito —los dos vecinos de fuera transparentes y los
    /// dos de dentro opacos— porque con la suelta un detalle de un píxel de ancho, como la
    /// correa del bolso, se lo come entero. Y se recogen todas las esquinas antes de
    /// borrar ninguna: borrando sobre la marcha, el hueco recién hecho convierte al vecino
    /// en esquina y el chaflán se come la figura en diagonal.
    public void Chaflan() {
        var copia = (Color32[])Px.Clone();
        System.Func<int,int,bool> op = (x,y) =>
            x >= 0 && y >= 0 && x < W && y < H && copia[y*W+x].a > 0;
        for (int y = 0; y < H; y++)
            for (int x = 0; x < W; x++) {
                if (!op(x,y)) continue;
                bool iz = op(x-1,y), de = op(x+1,y), ar = op(x,y-1), ab = op(x,y+1);
                if ((!iz && !ar && de && ab) || (!de && !ar && iz && ab) ||
                    (!iz && !ab && de && ar) || (!de && !ab && iz && ar))
                    Px[y*W+x] = new Color32(0,0,0,0);
            }
    }

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

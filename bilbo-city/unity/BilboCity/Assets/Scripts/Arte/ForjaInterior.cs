using System.Collections.Generic;
using UnityEngine;

namespace BilboCity {

/// <summary>El arte de dentro de los sitios, a su escala.
///
/// Fuera, una casilla son 5,16 m. Dentro no puede serlo: con esa vara el piso medía 72×41 m,
/// una cama 5 m de ancho y cruzar el salón costaba cincuenta segundos. La casilla de interior
/// mide 0,80 m —el ancho de una puerta de paso— y se dibuja a 16 px: 20 px/m, que es la
/// densidad a la que está dibujada la gente. Dentro de una casa la vara de medir es una
/// persona, no un coche.
///
/// Y el mobiliario no es un tile repetido sino una pieza entera —una cama de 0,8×2,4 m se
/// dibuja de una vez, con su cabecero y su almohada—, igual que los edificios singulares se
/// dibujan a su tamaño y no a base de baldosas.</summary>
public static class ForjaInterior {
    public const int Px = 16;              // píxeles por casilla de interior
    public const float Metro = 0.8f;       // metros por casilla de interior

    public static readonly Dictionary<string, Sprite> Suelos = new Dictionary<string, Sprite>();
    public static readonly Dictionary<string, Sprite> Paredes = new Dictionary<string, Sprite>();
    public static Sprite Puerta, PasoV, PasoH;
    static readonly Dictionary<string, Sprite> _muebles = new Dictionary<string, Sprite>();

    static Lienzo T() { return new Lienzo(Px, Px); }

    public static void Generar() {
        if (Suelos.Count > 0) return;
        // Una baldosa hidráulica de 20 cm son 4 px y se ve. Con la casilla de fuera, el suelo
        // de una casa era un cuadrado de cinco metros con una junta pintada.
        var g = T(); g.Rellenar(Paleta.MaderaL); g.Ruido(new[]{Paleta.Madera}, 4);
        // Tabla de 1,2 m por 12 cm: a 20 px/m son veinticuatro píxeles de largo y tres de
        // ancho. Con la junta cada ocho, la tabla salía cuadrada y el suelo se leía como un
        // muro de ladrillo.
        for (int y = 3; y < 16; y += 4) g.P(0, y, 16, 1, Paleta.Madera);
        Suelos["parquet"] = Forja.SpriteDe(g);

        g = T(); g.Rellenar(Paleta.Crema);
        for (int y = 0; y < 16; y += 8) for (int x = 0; x < 16; x += 8) {
            g.P(x+1, y+1, 6, 6, Paleta.AzulL); g.P(x+3, y+3, 2, 2, Paleta.Crema);
            g.P(x, y, 8, 1, Paleta.HormigonO); g.P(x, y, 1, 8, Paleta.HormigonO);
        }
        Suelos["hidraulico"] = Forja.SpriteDe(g);

        g = T(); g.Rellenar(Paleta.HormigonL); g.Ruido(new[]{Paleta.Acero,Paleta.Crema,Paleta.HormigonO}, 34);
        g.P(0, 0, 16, 1, Paleta.HormigonO); g.P(0, 0, 1, 16, Paleta.HormigonO);
        Suelos["terrazo"] = Forja.SpriteDe(g);

        g = T(); g.Rellenar(Paleta.H("#4d5157")); g.Ruido(new[]{Paleta.H("#42464b"),Paleta.H("#5b6067")}, 16);
        Suelos["chapa"] = Forja.SpriteDe(g);

        g = T(); g.Rellenar(Paleta.H("#8fa8a0")); g.Ruido(new[]{Paleta.H("#7d968e"),Paleta.H("#a3bab2")}, 12);
        g.P(0, 0, 1, 16, Paleta.H("#7d968e"));
        Suelos["hospital"] = Forja.SpriteDe(g);

        // El muro lleva la luz arriba y la sombra abajo, como todo lo demás: es lo que hace
        // que una habitación se lea como una caja y no como una retícula de cuadros.
        g = T(); g.Rellenar(Paleta.H("#c9c4b6")); g.Ruido(new[]{Paleta.H("#b8b3a5")}, 10);
        g.P(0, 0, 16, 2, Paleta.Blanco); g.P(0, 14, 16, 2, Paleta.H("#a9a496"));
        Paredes["yeso"] = Forja.SpriteDe(g);

        g = T(); g.Rellenar(Paleta.H("#2f5f5a"));
        for (int y = 0; y < 16; y += 4) for (int x = 0; x < 16; x += 4) {
            g.P(x, y, 3, 3, Paleta.H("#3a7570")); g.P(x, y, 3, 1, Paleta.H("#4d908a"));
        }
        g.P(0, 0, 16, 2, Paleta.H("#4d908a")); g.P(0, 15, 16, 1, Paleta.H("#22403d"));
        Paredes["azulejo"] = Forja.SpriteDe(g);

        g = T(); g.Rellenar(Paleta.H("#566060"));
        for (int x = 0; x < 16; x += 3) g.P(x, 0, 1, 16, Paleta.H("#454e4e"));
        g.P(0, 0, 16, 2, Paleta.H("#6e7a7a"));
        Paredes["chapa"] = Forja.SpriteDe(g);

        g = T(); g.Rellenar(Paleta.H("#4b3b32")); g.Ruido(new[]{Paleta.H("#43342c"),Paleta.H("#57453a")}, 16);
        for (int y = 0; y < 16; y += 4) {
            g.P(0, y, 16, 1, Paleta.H("#3a2d26"));
            for (int x = (y % 8 != 0 ? 4 : 0); x < 16; x += 8) g.P(x, y, 1, 4, Paleta.H("#3a2d26"));
        }
        g.P(0, 0, 16, 2, Paleta.H("#5e4a3d"));
        Paredes["ladrillo"] = Forja.SpriteDe(g);

        g = T(); g.P(0, 0, 16, 16, Paleta.MaderaO); g.P(1, 1, 14, 14, Paleta.Madera);
        g.P(2, 3, 12, 4, Paleta.H("#93663f")); g.P(2, 9, 12, 4, Paleta.H("#93663f"));
        g.P(12, 7, 2, 2, Paleta.Mostaza);
        Puerta = Forja.SpriteDe(g);

        g = T(); g.P(0, 0, 2, 16, Paleta.HormigonL); g.P(14, 0, 2, 16, Paleta.HormigonL);
        PasoV = Forja.SpriteDe(g);
        g = T(); g.P(0, 0, 16, 2, Paleta.HormigonL); g.P(0, 14, 16, 2, Paleta.HormigonL);
        PasoH = Forja.SpriteDe(g);
    }

    /// <summary>El dibujo de una pieza al tamaño que ocupe en el plano. Los que pueden ir en
    /// fila o en columna miran cuál es su lado largo: una estantería contra la pared de arriba
    /// y otra contra la de la izquierda son la misma pieza girada.</summary>
    public static Sprite Mueble(char ch, int cw, int cf) {
        string k = ch + "" + cw + "x" + cf;
        Sprite s;
        if (_muebles.TryGetValue(k, out s)) return s;
        var L = new Lienzo(cw * Px, cf * Px);
        Dibujar(ch, L);
        s = Forja.SpriteDe(L);
        _muebles[k] = s;
        return s;
    }

    static void Dibujar(char ch, Lienzo g) {
        int w = g.W, h = g.H;
        bool hz = w >= h;
        switch (ch) {
        case 'C':
            g.P(0,0,w,h,Paleta.H("#5a4433")); g.P(1,1,w-2,3,Paleta.MaderaL);
            g.P(1,4,w-2,h-6,Paleta.H("#8a9bb0")); g.P(2,5,w-4,5,Paleta.Hueso);
            g.P(1,Mathf.RoundToInt(h*0.55f),w-2,1,Paleta.H("#6f7d8f")); g.P(0,h-2,w,2,Paleta.MaderaO); break;
        case 'A': {
            g.P(0,0,w,h,Paleta.H("#5c4630")); g.P(1,1,w-2,h-2,Paleta.H("#6d543a"));
            int n = Mathf.Max(1, Mathf.RoundToInt((hz ? w : h) / 16f));
            for (int i = 1; i < n; i++) {
                int p = i*16;
                if (hz) g.P(p,1,1,h-2,Paleta.H("#4a3826")); else g.P(1,p,w-2,1,Paleta.H("#4a3826"));
            }
            for (int i = 0; i < n; i++) {
                if (hz) g.P(i*16+12,(h>>1)-1,2,3,Paleta.Mostaza); else g.P((w>>1)-1,i*16+12,3,2,Paleta.Mostaza);
            }
            break; }
        case 'U':
            g.P(1,2,w-2,h-3,Paleta.MaderaO); g.P(2,3,w-4,3,Paleta.MaderaL);
            g.P((w>>1)-2,7,4,4,Paleta.Mostaza); g.P((w>>1)-1,6,2,1,Paleta.Hueso); break;
        case 'F':
            g.P(0,0,w,h,Paleta.H("#4d5b6b"));
            if (hz) { g.P(0,0,w,4,Paleta.H("#3d4a58"));
                for (int x = 1; x < w-1; x += 16) g.P(x,5,Mathf.Min(14,w-1-x),h-7,Paleta.H("#5f7182")); }
            else { g.P(0,0,4,h,Paleta.H("#3d4a58"));
                for (int y = 1; y < h-1; y += 16) g.P(5,y,w-7,Mathf.Min(14,h-1-y),Paleta.H("#5f7182")); }
            break;
        case 'M':
            g.P(0,1,w,h-1,Paleta.Negro); g.P(0,0,w,h-2,Paleta.H("#7a5233")); g.P(1,1,w-2,3,Paleta.H("#93663f"));
            if (w >= 32 && h >= 32) { g.P(6,7,6,6,Paleta.Crema); g.P(w-13,h-16,5,8,Paleta.H("#8fae8a")); }
            else g.P((w>>1)-2,(h>>1)-2,4,4,Paleta.Crema);
            break;
        case 'S':
            g.P(3,2,10,3,Paleta.Madera); g.P(3,5,10,9,Paleta.MaderaO); g.P(4,6,8,7,Paleta.H("#93663f")); break;
        case 'K':
            g.P(0,0,w,h,Paleta.H("#6d543a"));
            if (hz) { g.P(0,0,w,3,Paleta.HormigonL);
                for (int x = 0; x < w; x += 16) g.P(x+1,4,14,h-5,Paleta.H("#7d6244"));
                g.P(4,5,8,6,Paleta.Acero); g.P(w-12,5,8,6,Paleta.Carbon); }
            else { g.P(0,0,3,h,Paleta.HormigonL);
                for (int y = 0; y < h; y += 16) g.P(4,y+1,w-5,14,Paleta.H("#7d6244"));
                g.P(5,4,8,6,Paleta.Acero); g.P(5,h-12,8,6,Paleta.Carbon); }
            break;
        case 'N':
            g.P(0,0,w,h,Paleta.HormigonL); g.P(1,1,w-2,h-2,Paleta.Hueso);
            g.P(1,h>>1,w-2,1,Paleta.HormigonO); g.P(w-4,3,2,6,Paleta.Acero); g.P(w-4,(h>>1)+3,2,6,Paleta.Acero); break;
        case 'T':
            g.P(4,2,8,4,Paleta.Blanco); g.P(3,6,10,8,Paleta.Blanco);
            g.P(5,8,6,5,Paleta.H("#b9c6cf")); g.P(4,14,8,1,Paleta.HormigonO); break;
        case 'V':
            g.P(2,3,12,10,Paleta.Blanco); g.P(4,5,8,6,Paleta.H("#b9c6cf")); g.P(7,2,2,3,Paleta.Acero); break;
        case 'H':
            g.P(0,0,w,h,Paleta.H("#b9c6cf")); g.P(1,1,w-2,h-2,Paleta.H("#8fa8a0"));
            for (int i = 2; i < w-2; i += 3) g.P(i,2,1,h-4,Paleta.H("#a3bab2"));
            g.P(w-6,2,4,4,Paleta.Acero); break;
        case 'E': {
            g.P(0,0,w,h,Paleta.GrisO);
            var cols = new[]{Paleta.MostazaO,Paleta.RojoO,Paleta.Azul,Paleta.VerdeO,Paleta.Crema,Paleta.Morado};
            if (hz) { g.P(0,0,w,2,Paleta.Gris);
                for (int x = 1, i = 0; x < w-2; x += 4, i++) g.P(x,3,3,h-5,cols[i%cols.Length]); }
            else { g.P(0,0,2,h,Paleta.Gris);
                for (int y = 1, i = 0; y < h-2; y += 4, i++) g.P(3,y,w-5,3,cols[i%cols.Length]); }
            break; }
        case 'B':
            g.P(0,0,w,h,Paleta.Madera); g.Ruido(new[]{Paleta.MaderaO,Paleta.MaderaL}, 12);
            g.P(0,0,w,2,Paleta.MaderaL); g.P(0,h-3,w,3,Paleta.MaderaO); g.P(0,h-1,w,1,Paleta.Acero); break;
        case 'O':
            g.P(0,2,w,h-2,Paleta.MaderaO); g.P(0,0,w,3,Paleta.MaderaL);
            g.P(3,5,7,6,Paleta.Crema); if (w > 16) g.P(w-9,5,6,6,Paleta.Carbon); break;
        case 'X':
            g.P(0,0,w,h,Paleta.GrisO); g.P(1,2,w-2,h-4,Paleta.H("#66727f")); g.P(0,0,w,2,Paleta.RojoO);
            for (int i = 2; i < (hz ? w : h)-3; i += 5) {
                if (hz) g.P(i,4,3,h-8,Paleta.Acero); else g.P(4,i,w-8,3,Paleta.Acero);
            }
            break;
        case 'P':
            g.P(0,0,w,h,Paleta.Acero); g.P(1,1,w-2,h-4,Paleta.H("#cfd6dd"));
            for (int x = 2; x < w-4; x += 5) g.P(x,3,4,h-8,Paleta.H("#7fa8c4"));
            g.P(0,0,w,2,Paleta.RojoO); g.P(0,h-3,w,3,Paleta.AceroO); break;
        case 'L':
            g.P(0,0,w,h,Paleta.Blanco); g.P(1,2,w-2,h-4,Paleta.H("#8fa8a0"));
            g.P(2,3,w-4,4,Paleta.Crema); g.P(0,h-2,w,2,Paleta.Acero); break;
        case 'Q':
            g.P(0,0,w,h,Paleta.H("#5f7182"));
            for (int i = 0; i < (hz ? w : h); i += 8) {
                if (hz) { g.P(i,0,7,h,Paleta.H("#6b7f92")); g.P(i+5,4,1,3,Paleta.Acero); }
                else { g.P(0,i,w,7,Paleta.H("#6b7f92")); g.P(4,i+5,3,1,Paleta.Acero); }
            }
            break;
        case 'R': {
            g.P(0,0,w,h,Paleta.GrisO); g.P(0,2,w,1,Paleta.Acero);
            var tr = new[]{Paleta.RojoO,Paleta.Azul,Paleta.VerdeO,Paleta.MostazaO,Paleta.Morado,Paleta.Carbon};
            for (int x = 0, i = 0; x < w-2; x += 3, i++) {
                g.P(x+1,3,2,h-5,tr[i%tr.Length]); g.P(x+1,3,2,1,Paleta.Hueso);
            }
            break; }
        case 'Z':
            g.P(3,2,w-6,h-4,Paleta.RojoO); g.P(2,5,w-4,h-10,Paleta.RojoO);
            g.P(4,8,w-8,9,Paleta.Carbon); g.P(4,h-19,w-8,8,Paleta.Carbon);
            g.P(0,6,2,6,Paleta.Negro); g.P(w-2,6,2,6,Paleta.Negro);
            g.P(0,h-13,2,6,Paleta.Negro); g.P(w-2,h-13,2,6,Paleta.Negro);
            g.P(5,3,w-10,2,Paleta.Hueso); break;
        case 'Y':
            g.P(0,0,w,h,Paleta.Acero);
            for (int y = 0; y < h; y += 4) { g.P(1,y,w-2,3,Paleta.AceroO); g.P(1,y,w-2,1,Paleta.HormigonL); }
            g.P(0,0,1,h,Paleta.Gris); g.P(w-1,0,1,h,Paleta.GrisO); break;
        case 'W':
            g.P(0,1,w,h-1,Paleta.H("#5c4630")); g.P(0,0,w,2,Paleta.MaderaL);
            for (int x = 2; x < w-3; x += 6) { g.P(x,4,5,h-7,Paleta.H("#6d543a")); g.P(x+2,h-6,2,1,Paleta.Mostaza); }
            break;
        case 'J':
            g.P(5,10,6,5,Paleta.H("#8a5b36")); g.P(4,9,8,2,Paleta.H("#6f4a31"));
            g.P(4,3,8,6,Paleta.VerdeO); g.P(6,1,4,4,Paleta.Cesped); break;
        // Atrezzo de dentro. Un piso con cama, armario y sofá está amueblado, pero no está
        // habitado. Ahora hay televisión mirando al sofá, lavadora en la cocina, radiador
        // debajo de la ventana y alfombra en el suelo; taburetes en la barra del bar, con su
        // futbolín y su máquina recreativa al fondo; banco de trabajo y neumáticos en el
        // taller. Las piezas nuevas van en minúscula porque las mayúsculas se acabaron: el
        // plano es un carácter por casilla.
        case 'g':
            g.P(1,h-6,w-2,5,Paleta.MaderaO); g.P(2,2,w-4,h-8,Paleta.Carbon);
            g.P(3,3,w-6,h-11,Paleta.H("#2b3a4a")); g.P((w>>1)-2,h-7,4,1,Paleta.Acero); break;
        case 'i':
            g.P(0,0,w,h,Paleta.Hueso); g.P(1,1,w-2,h-2,Paleta.Blanco);
            g.P(3,4,w-6,h-8,Paleta.H("#8fa8a0")); g.P(4,5,w-8,h-10,Paleta.H("#b9c6cf"));
            g.P(1,1,w-2,2,Paleta.HormigonL); break;
        case 'r':
            g.P(0,1,w,h-2,Paleta.HormigonL);
            if (hz) { for (int x = 1; x < w-1; x += 3) g.P(x,2,2,h-4,Paleta.Hueso); }
            else { for (int y = 1; y < h-1; y += 3) g.P(2,y,w-4,2,Paleta.Hueso); }
            break;
        // La alfombra se pisa: es lo único del plano que se dibuja y no frena.
        case 'a':
            g.P(0,0,w,h,Paleta.H("#7a3f37")); g.P(1,1,w-2,h-2,Paleta.H("#96543e"));
            g.P(3,3,w-6,h-6,Paleta.H("#7a3f37")); if (w > 12 && h > 12) g.P(5,5,w-10,h-10,Paleta.MostazaO);
            break;
        case 't':
            g.P(4,4,8,8,Paleta.MaderaO); g.P(5,5,6,6,Paleta.MaderaL); g.P(6,12,4,2,Paleta.Carbon); break;
        case 'e':
            g.P(0,1,w,h-1,Paleta.MaderaO); g.P(0,0,w,2,Paleta.MaderaL);
            g.P(3,4,7,6,Paleta.Crema); if (w > 16) g.P(w-8,4,5,5,Paleta.Carbon);
            break;
        case 'b':
            g.P(0,0,w,h,Paleta.Blanco); g.P(2,2,w-4,h-4,Paleta.H("#b9c6cf"));
            g.P(3,3,w-6,h-6,Paleta.H("#8fa8a0")); g.P(w-5,2,2,3,Paleta.Acero); break;
        case 'w':
            g.P(0,2,w,h-2,Paleta.H("#5c4630")); g.P(0,0,w,3,Paleta.HormigonL);
            for (int x = 2; x < w-3; x += 6) g.P(x,4,4,h-7,Paleta.H("#6d543a"));
            g.P(3,1,5,1,Paleta.Acero);
            break;
        case 'n':
            for (int y = 0; y < h-3; y += 6) { g.P(1,y,w-2,5,Paleta.Carbon); g.P(3,y+1,w-6,3,Paleta.GrisO); }
            break;
        case 'f':
            g.P(0,0,w,h,Paleta.H("#3a5a3a")); g.P(1,1,w-2,h-2,Paleta.VerdeO);
            for (int i = 4; i < (hz ? w : h)-3; i += 5) {
                if (hz) g.P(i,0,2,h,Paleta.Acero); else g.P(0,i,w,2,Paleta.Acero);
            }
            break;
        case 'x':
            g.P(0,0,w,h,Paleta.RojoO); g.P(2,2,w-4,h-8,Paleta.Carbon);
            g.P(3,3,w-6,h-11,Paleta.H("#2b3a4a")); g.P(3,h-5,w-6,3,Paleta.Mostaza);
            break;
        case 'p':
            g.P(0,0,w,h,Paleta.MaderaO);
            for (int x = 1; x < w-1; x += 4) g.P(x,1,3,h-2,Paleta.Madera);
            g.P(0,h-2,w,2,Paleta.H("#4a3826"));
            break;
        }
    }
}

}

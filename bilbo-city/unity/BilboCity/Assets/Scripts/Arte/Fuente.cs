using System.Collections.Generic;
using UnityEngine;

namespace BilboCity {

/// <summary>Fuente de bits propia de 5×7 con contorno y bisel de tres tonos, más los iconos del HUD.</summary>
public static class Fuente {
    static readonly Dictionary<char,int[]> Glifos = new Dictionary<char,int[]> {
        {'A',new[]{14,17,17,31,17,17,17}}, {'B',new[]{30,17,17,30,17,17,30}}, {'C',new[]{14,17,16,16,16,17,14}},
        {'D',new[]{30,17,17,17,17,17,30}}, {'E',new[]{31,16,16,30,16,16,31}}, {'F',new[]{31,16,16,30,16,16,16}},
        {'G',new[]{14,17,16,23,17,17,14}}, {'H',new[]{17,17,17,31,17,17,17}}, {'I',new[]{14,4,4,4,4,4,14}},
        {'J',new[]{7,2,2,2,2,18,12}},      {'K',new[]{17,18,20,24,20,18,17}}, {'L',new[]{16,16,16,16,16,16,31}},
        {'M',new[]{17,27,21,21,17,17,17}}, {'N',new[]{17,25,21,19,17,17,17}}, {'O',new[]{14,17,17,17,17,17,14}},
        {'P',new[]{30,17,17,30,16,16,16}}, {'Q',new[]{14,17,17,17,21,18,13}}, {'R',new[]{30,17,17,30,20,18,17}},
        {'S',new[]{15,16,16,14,1,1,30}},   {'T',new[]{31,4,4,4,4,4,4}},       {'U',new[]{17,17,17,17,17,17,14}},
        {'V',new[]{17,17,17,17,17,10,4}},  {'W',new[]{17,17,17,21,21,27,17}}, {'X',new[]{17,17,10,4,10,17,17}},
        {'Y',new[]{17,17,10,4,4,4,4}},     {'Z',new[]{31,1,2,4,8,16,31}},
        {'0',new[]{14,17,19,21,25,17,14}}, {'1',new[]{4,12,4,4,4,4,14}},      {'2',new[]{14,17,1,2,4,8,31}},
        {'3',new[]{31,2,4,2,1,17,14}},     {'4',new[]{2,6,10,18,31,2,2}},     {'5',new[]{31,16,30,1,1,17,14}},
        {'6',new[]{6,8,16,30,17,17,14}},   {'7',new[]{31,1,2,4,8,8,8}},       {'8',new[]{14,17,17,14,17,17,14}},
        {'9',new[]{14,17,17,15,1,2,12}},
        {'.',new[]{0,0,0,0,0,12,12}},      {',',new[]{0,0,0,0,12,4,8}},       {':',new[]{0,12,12,0,12,12,0}},
        {'!',new[]{4,4,4,4,4,0,4}},        {'?',new[]{14,17,1,2,4,0,4}},      {'\'',new[]{4,4,0,0,0,0,0}},
        {'-',new[]{0,0,0,31,0,0,0}},       {'+',new[]{0,4,4,31,4,4,0}},       {'/',new[]{1,2,2,4,8,8,16}},
        {'(',new[]{2,4,8,8,8,4,2}},        {')',new[]{8,4,2,2,2,4,8}},        {'€',new[]{7,8,30,8,30,8,7}},
        {'×',new[]{0,17,10,4,10,17,0}},    {'>',new[]{0,4,2,31,2,4,0}},       {'%',new[]{17,1,2,4,8,16,17}},
        {'Ñ',new[]{14,0,17,25,21,19,17}},  {'Á',new[]{2,0,14,17,31,17,17}},   {'É',new[]{2,0,31,16,30,16,31}},
        {'Í',new[]{2,0,14,4,4,4,14}},      {'Ó',new[]{2,0,14,17,17,17,14}},   {'Ú',new[]{2,0,17,17,17,17,14}},
        {' ',new[]{0,0,0,0,0,0,0}},
    };

    public enum Tinta { Ambar, Hueso, Rojo, Verde }
    static Color32[] Tonos(Tinta t) {
        switch (t) {
            case Tinta.Hueso: return new[]{ Paleta.Blanco, Paleta.Hueso, Paleta.Acero, Paleta.AceroO };
            case Tinta.Rojo:  return new[]{ Paleta.Crema, Paleta.RojoL, Paleta.Rojo, Paleta.Sangre };
            case Tinta.Verde: return new[]{ Paleta.Crema, Paleta.VerdeL, Paleta.Verde, Paleta.VerdeO };
            default:          return new[]{ Paleta.Crema, Paleta.Mostaza, Paleta.H("#d9891f"), Paleta.RojoO };
        }
    }

    public const int GW = 9, GH = 11, AVANCE = 6, ESPACIO = 4;
    static readonly Dictionary<string, Sprite> Cache = new Dictionary<string, Sprite>();

    public static Sprite Glifo(char ch, Tinta tinta) {
        ch = char.ToUpperInvariant(ch);
        string clave = tinta + "" + ch;
        Sprite s;
        if (Cache.TryGetValue(clave, out s)) return s;
        int[] f;
        if (!Glifos.TryGetValue(ch, out f)) f = Glifos['?'];
        var T = Tonos(tinta);
        var L = new Lienzo(GW, GH);
        System.Func<int,int,bool> on = (x,y) => y >= 0 && y < 7 && x >= 0 && x < 5 && ((f[y] >> (4-x)) & 1) != 0;
        for (int y = -1; y < 8; y++)
            for (int x = -1; x < 6; x++) {
                if (on(x,y)) continue;
                bool v = false;
                for (int dy = -1; dy <= 1; dy++) for (int dx = -1; dx <= 1; dx++) if (on(x+dx,y+dy)) v = true;
                if (v) L.P(x+2, y+2, 1, 1, Paleta.Carbon);
            }
        for (int y = 0; y < 7; y++)
            for (int x = 0; x < 5; x++)
                if (on(x,y)) L.P(x+2, y+2, 1, 1, y < 2 ? T[1] : (y < 5 ? T[2] : T[3]));
        for (int x = 0; x < 5; x++) if (on(x,0)) L.P(x+2, 1, 1, 1, T[0]);
        s = Forja.SpriteDe(L);
        Cache[clave] = s;
        return s;
    }

    public static int Ancho(string s, int esc) {
        int w = 0;
        foreach (char c in s) w += (c == ' ' ? ESPACIO : AVANCE) * esc;
        return w;
    }

    // ═══════════ ICONOS ═══════════
    public static readonly Dictionary<string, Sprite> Ico = new Dictionary<string, Sprite>();
    static Lienzo I24() { return new Lienzo(24,24); }

    public static void GenerarIconos() {
        if (Ico.Count > 0) return;
        Lienzo L;
        L = I24(); L.P(7,9,10,8,Paleta.Piel2); L.P(7,9,10,2,Paleta.Piel1); L.P(5,11,2,4,Paleta.Piel3);
        Ico["punos"] = Forja.SpriteDe(L);
        L = I24(); L.P(4,16,6,3,Paleta.MaderaO); L.P(9,8,10,10,Paleta.MaderaL);
        Ico["bate"] = Forja.SpriteDe(L);
        L = I24(); L.P(5,9,13,4,Paleta.Carbon); L.P(6,13,4,7,Paleta.Negro); L.P(5,9,13,1,Paleta.Gris);
        Ico["pistola"] = Forja.SpriteDe(L);
        L = I24(); L.P(4,8,15,5,Paleta.Carbon); L.P(8,13,4,8,Paleta.Negro); L.P(15,4,3,5,Paleta.Gris);
        Ico["uzi"] = Forja.SpriteDe(L);
        L = I24(); L.P(3,10,18,4,Paleta.MaderaO); L.P(3,10,18,1,Paleta.Acero); L.P(4,14,6,5,Paleta.Carbon);
        Ico["escopeta"] = Forja.SpriteDe(L);
        var estrella = new[]{ new Vector2(12,1), new Vector2(15,9), new Vector2(23,9), new Vector2(16,14),
            new Vector2(19,22), new Vector2(12,17), new Vector2(5,22), new Vector2(8,14),
            new Vector2(1,9), new Vector2(9,9) };
        L = I24(); L.Poligono(estrella, Paleta.H("#ff5a3c")); Ico["estrella"] = Forja.SpriteDe(L);
        L = I24(); L.Poligono(estrella, Paleta.GrisO); Ico["estrellaOff"] = Forja.SpriteDe(L);
        L = I24(); L.P(7,5,10,3,Paleta.Mostaza); L.P(5,8,4,8,Paleta.Mostaza); L.P(7,16,10,3,Paleta.Mostaza);
        L.P(3,10,10,2,Paleta.Mostaza); L.P(3,13,10,2,Paleta.Mostaza); Ico["euro"] = Forja.SpriteDe(L);
        L = I24(); L.P(12,2,6,10,Paleta.H("#4d9de0")); L.P(6,10,6,12,Paleta.H("#4d9de0"));
        L.P(8,9,8,4,Paleta.H("#4d9de0")); Ico["energia"] = Forja.SpriteDe(L);
        L = I24(); L.P(5,4,3,10,Paleta.Crema); L.P(10,4,2,7,Paleta.Crema); L.P(13,4,2,7,Paleta.Crema);
        L.P(10,10,5,3,Paleta.Crema); L.P(11,13,3,8,Paleta.Crema); L.P(5,14,3,7,Paleta.Crema);
        Ico["hambre"] = Forja.SpriteDe(L);
        L = I24(); L.P(9,4,6,16,Paleta.Sangre); L.P(4,9,16,6,Paleta.Sangre); Ico["salud"] = Forja.SpriteDe(L);
    }
}

}

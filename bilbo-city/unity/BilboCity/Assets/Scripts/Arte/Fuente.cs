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
        // El infinito y el punto volado van pensando en que la fuente los engorda
        // después: un trazo de un píxel sale sólido y deja de leerse.
        {'∞',new[]{0,0,17,10,17,0,0}},     {'·',new[]{0,0,0,4,0,0,0}},
    };

    public enum Tinta { Ambar, Hueso, Rojo, Verde }

    /// <summary>Relleno y sombra de cada tinta.</summary>
    /// La sombra va en un color de la paleta y no en negro: sobre las cajas oscuras del
    /// HUD un negro no se ve y la letra se queda plana.
    static Color32[] Tonos(Tinta t) {
        switch (t) {
            case Tinta.Hueso: return new[]{ Paleta.Hueso, Paleta.AceroO };
            case Tinta.Rojo:  return new[]{ Paleta.RojoL, Paleta.Sangre };
            case Tinta.Verde: return new[]{ Paleta.VerdeL, Paleta.VerdeO };
            default:          return new[]{ Paleta.Mostaza, Paleta.RojoO };
        }
    }

    /// <summary>
    /// La fuente es BLOQUE: el alfabeto de 5×7 engordado a 6 de ancho, relleno plano y
    /// sombra dura de un píxel abajo a la derecha. Se eligió sobre otras cinco porque a
    /// tamaño 1 en un móvil se lee sin acercar la cara y a tamaño 3 aguanta como rótulo.
    /// El engorde se hace aquí y no en la tabla para que la tabla siga siendo la misma
    /// que la del prototipo, letra por letra.
    /// </summary>
    public const int GW = 8, GH = 9, AVANCE = 7, ESPACIO = 5;
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
        System.Func<int,int,bool> on = (x,y) => {
            if (y < 0 || y >= 7 || x < 0 || x >= 6) return false;
            int r = (f[y] | (f[y] << 1)) & 63;
            return ((r >> (5-x)) & 1) != 0;
        };
        for (int y = 0; y < 7; y++) for (int x = 0; x < 6; x++) if (on(x,y)) L.P(x+1, y+1, 1, 1, T[1]);
        for (int y = 0; y < 7; y++) for (int x = 0; x < 6; x++) if (on(x,y)) L.P(x, y, 1, 1, T[0]);
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

    /// <summary>
    /// Los iconos de la interfaz. Antes los curros y los menús iban con emoji del
    /// sistema: cada móvil los dibuja a su manera, no están en la paleta y al lado del
    /// pixel art cantan. Estos son del juego, y son los mismos que los del prototipo.
    ///
    /// Todos pasan por Contorno: se miran a 24 píxeles sobre fondos de cualquier color y
    /// sin un borde negro la mitad se pierden contra el fondo.
    /// </summary>
    public static void GenerarIconos() {
        if (Ico.Count > 0) return;
        Lienzo L;
        void Guardar(string nombre, Lienzo l) { l.Contorno(Paleta.Negro); Ico[nombre] = Forja.SpriteDe(l); }

        // ── armas ──
        // El puño se mira de tres cuartos: cuatro nudillos y el pulgar cruzado por
        // delante. De frente y liso se lee como una caja de cartón.
        L = I24();
        L.P(7,7,11,12,Paleta.Piel2); L.P(7,7,11,3,Paleta.Piel1);
        for (int i = 0; i < 4; i++) { L.P(8+i*3,7,2,3,Paleta.Piel1); L.P(8+i*3,10,2,2,Paleta.Piel3); }
        L.P(5,12,4,6,Paleta.Piel3); L.P(5,12,4,2,Paleta.Piel2); L.P(7,17,11,2,Paleta.Piel4);
        L.P(10,19,8,3,Paleta.Piel4); Guardar("punos", L);

        L = I24();
        for (int i = 0; i < 7; i++) L.P(4+i,17-i,3,3,Paleta.MaderaO);
        for (int i = 0; i < 8; i++) L.P(10+i,11-i,4,4,Paleta.MaderaL);
        L.P(5,16,3,3,Paleta.Carbon); Guardar("bate", L);

        L = I24();
        L.P(4,8,15,5,Paleta.Carbon); L.P(4,8,15,1,Paleta.Gris); L.P(17,10,4,2,Paleta.GrisO);
        L.P(6,13,5,8,Paleta.Negro); L.P(7,14,3,6,Paleta.GrisO); L.P(11,12,3,2,Paleta.Carbon);
        Guardar("pistola", L);

        L = I24();
        L.P(3,7,16,6,Paleta.Carbon); L.P(3,7,16,1,Paleta.Gris);
        L.P(8,13,4,9,Paleta.Negro); L.P(15,3,3,5,Paleta.GrisO); L.P(4,4,3,4,Paleta.GrisO);
        L.P(19,9,2,2,Paleta.Gris); Guardar("uzi", L);

        L = I24();
        L.P(7,8,15,3,Paleta.GrisO); L.P(7,11,15,3,Paleta.Carbon); L.P(7,8,15,1,Paleta.Acero);
        L.P(20,8,2,6,Paleta.Negro);
        for (int i = 0; i < 7; i++) L.P(3+i,14+i,4,3,Paleta.MaderaO);
        L.P(4,15,3,3,Paleta.MaderaL); L.P(9,13,4,3,Paleta.Madera); Guardar("escopeta", L);

        // ── herramientas de curro, una por oficio ──
        L = I24();
        L.P(4,7,16,14,Paleta.RojoO); L.P(4,7,16,3,Paleta.Rojo); L.P(9,4,6,4,Paleta.Carbon);
        L.P(7,12,10,6,Paleta.Crema); L.P(9,14,6,2,Paleta.Rojo); Guardar("reparto", L);

        L = I24();
        L.P(3,10,18,10,Paleta.MaderaO); L.P(3,10,18,2,Paleta.MaderaL);
        for (int i = 0; i < 4; i++) L.P(5+i*4,13,3,7,Paleta.Madera);
        L.P(6,6,10,5,Paleta.Acero); L.P(14,5,4,7,Paleta.AceroO); L.P(8,8,2,2,Paleta.Negro);
        Guardar("lonja", L);

        L = I24();
        L.P(4,9,16,7,Paleta.Mostaza); L.P(4,9,16,2,Paleta.Crema); L.P(6,16,12,4,Paleta.Carbon);
        L.P(7,11,4,3,Paleta.Carbon); L.P(13,11,4,3,Paleta.Carbon); L.P(2,17,20,2,Paleta.Negro);
        Guardar("taxi", L);

        L = I24();
        L.P(5,9,14,8,Paleta.Mostaza); L.P(7,5,10,5,Paleta.Mostaza); L.P(11,4,2,6,Paleta.MostazaO);
        L.P(3,17,18,3,Paleta.MostazaO); L.P(5,9,14,1,Paleta.Crema); Guardar("obra", L);

        L = I24();
        L.P(11,2,3,10,Paleta.Acero); L.P(8,2,9,2,Paleta.AceroO);
        L.P(11,12,3,3,Paleta.Acero); L.P(7,14,7,3,Paleta.Acero); L.P(6,16,3,5,Paleta.Acero);
        L.P(8,20,5,2,Paleta.AceroO); Guardar("puerto", L);

        L = I24();
        L.P(3,7,18,14,Paleta.H("#a07a4a")); L.P(3,7,18,2,Paleta.H("#c09760"));
        L.P(11,7,2,14,Paleta.Crema); L.P(3,12,18,2,Paleta.Crema); L.P(5,16,5,3,Paleta.H("#8a6538"));
        Guardar("mudanza", L);

        L = I24();
        L.P(4,8,16,13,Paleta.H("#b09a72")); L.P(4,8,16,2,Paleta.H("#c9b48c"));
        L.P(11,8,2,13,Paleta.MaderaO); L.P(4,13,16,2,Paleta.MaderaO); L.P(9,4,6,5,Paleta.MaderaO);
        Guardar("recado", L);

        L = I24();
        L.P(11,3,2,18,Paleta.Carbon); L.P(3,11,18,2,Paleta.Carbon);
        for (int i = 0; i < 8; i++) {
            float a = i * Mathf.PI / 4f;
            L.P(12 + Mathf.Cos(a)*9 - 1, 12 + Mathf.Sin(a)*9 - 1, 3, 3, i%2 == 1 ? Paleta.Crema : Paleta.Carbon);
        }
        L.P(9,9,6,6,Paleta.GrisO); Guardar("fuga", L);

        L = I24();
        for (int i = 0; i < 10; i++) L.P(7+i,16-i,3,3,Paleta.Acero);
        L.P(2,14,8,8,Paleta.AceroO); L.Borrar(5,16,4,4); L.Borrar(2,14,3,3);
        L.P(14,2,8,8,Paleta.AceroO); L.Borrar(15,4,4,4); L.Borrar(19,7,3,3);
        Guardar("llaveInglesa", L);

        L = I24();
        L.P(2,8,20,9,Paleta.Crema); L.P(2,8,20,2,Paleta.Blanco); L.P(14,9,7,5,Paleta.AzulL);
        L.P(2,17,20,2,Paleta.GrisO); L.P(5,17,4,4,Paleta.Carbon); L.P(15,17,4,4,Paleta.Carbon);
        Guardar("furgo", L);

        L = I24();
        L.P(2,11,20,6,Paleta.Rojo); L.P(6,7,12,5,Paleta.RojoO); L.P(8,8,8,3,Paleta.AzulL);
        L.P(2,11,20,1,Paleta.RojoL); L.P(2,17,20,2,Paleta.Carbon);
        L.P(4,16,4,5,Paleta.Carbon); L.P(16,16,4,5,Paleta.Carbon); Guardar("deportivo", L);

        // ── marcas de la interfaz ──
        L = I24();
        L.P(4,10,16,4,Paleta.RojoL); L.P(10,4,4,16,Paleta.RojoL);
        L.P(8,8,8,8,Paleta.Crema); L.P(10,10,4,4,Paleta.Sangre); Guardar("diana", L);

        L = I24();
        L.Poligono(new[]{ new Vector2(12,2), new Vector2(22,20), new Vector2(2,20) }, Paleta.Mostaza);
        L.P(11,8,2,7,Paleta.Carbon); L.P(11,16,2,2,Paleta.Carbon); Guardar("aviso", L);

        L = I24();
        L.P(4,3,2,18,Paleta.GrisO);
        for (int y = 0; y < 4; y++) for (int x = 0; x < 4; x++)
            L.P(6+x*4, 4+y*3, 4, 3, (x+y)%2 == 1 ? Paleta.Carbon : Paleta.Crema);
        Guardar("meta", L);

        L = I24();
        L.P(3,4,18,16,Paleta.RojoO); L.P(5,6,14,12,Paleta.Crema); L.P(11,4,2,16,Paleta.RojoO);
        for (int i = 0; i < 3; i++) { L.P(6,8+i*3,4,1,Paleta.Acero); L.P(14,8+i*3,4,1,Paleta.Acero); }
        Guardar("libro", L);

        L = I24();
        L.P(4,3,16,18,Paleta.Crema); L.P(4,3,16,3,Paleta.Acero);
        for (int i = 0; i < 4; i++) L.P(7,9+i*3,10,1,Paleta.AceroO);
        L.P(9,2,6,4,Paleta.GrisO); Guardar("contrato", L);

        L = I24();
        L.P(4,9,7,7,Paleta.Mostaza); L.Borrar(6,11,3,3);
        L.P(11,11,10,3,Paleta.Mostaza); L.P(17,14,2,4,Paleta.Mostaza); L.P(20,14,2,3,Paleta.Mostaza);
        Guardar("llave", L);

        L = I24();
        L.P(4,4,16,16,Paleta.Sangre); L.P(6,6,12,12,Paleta.RojoO);
        for (int i = 0; i < 12; i++) L.P(6+i,6+i,2,2,Paleta.Crema); Guardar("prohibido", L);

        L = I24();
        L.P(7,2,10,20,Paleta.Carbon); L.P(8,5,8,12,Paleta.H("#4d9de0"));
        L.P(10,3,4,1,Paleta.GrisO); L.P(10,18,4,2,Paleta.GrisO); Guardar("movil", L);

        // ── consumibles ──
        L = I24();
        L.P(4,12,16,6,Paleta.H("#c9a86a")); L.P(4,12,16,2,Paleta.H("#e0c48c"));
        L.P(6,9,12,4,Paleta.RojoO); L.P(8,7,3,3,Paleta.Verde); L.P(12,15,1,7,Paleta.MaderaL);
        Guardar("pintxo", L);

        L = I24();
        L.P(9,2,6,4,Paleta.VerdeO); L.P(8,6,8,15,Paleta.Verde); L.P(10,9,4,9,Paleta.H("#7ab06a"));
        L.P(8,13,8,5,Paleta.Crema); L.P(9,1,6,2,Paleta.Mostaza); Guardar("botellin", L);

        L = I24();
        L.P(3,6,18,14,Paleta.Crema); L.P(3,6,18,2,Paleta.Acero);
        L.P(10,9,4,9,Paleta.Sangre); L.P(7,12,10,3,Paleta.Sangre); L.P(9,4,6,3,Paleta.GrisO);
        Guardar("botiquin", L);

        L = I24();
        L.P(7,6,10,14,Paleta.Carbon); L.P(7,6,10,2,Paleta.Gris);
        for (int i = 0; i < 4; i++) L.P(9,9+i*3,6,2,Paleta.MostazaO); Guardar("cargador", L);

        // El ojo del sigilo: abierto cuando te tienen a la vista, tachado mientras solo
        // sospechan.
        L = I24();
        L.P(2,9,20,6,Paleta.Hueso); L.P(4,7,16,10,Paleta.Hueso); L.P(7,7,10,10,Paleta.Blanco);
        L.P(8,8,8,8,Paleta.AzulL); L.P(10,10,4,4,Paleta.Carbon);
        L.P(4,6,16,1,Paleta.Acero); Guardar("ojo", L);

        L = I24();
        L.P(3,10,18,4,Paleta.GrisO); L.P(5,9,14,6,Paleta.GrisO); L.P(8,10,8,4,Paleta.Acero);
        for (int i = 0; i < 16; i++) L.P(4+i,18-i,3,3,Paleta.Carbon); Guardar("ojoTachado", L);

        // Ropa, mesa y transporte.
        L = I24();
        L.P(6,4,12,16,Paleta.AzulL); L.P(6,4,12,2,Paleta.H("#a8c4dd"));
        L.P(2,5,5,8,Paleta.AzulL); L.P(17,5,5,8,Paleta.Azul); L.P(11,4,2,15,Paleta.Azul);
        L.P(8,3,3,3,Paleta.Hueso); L.P(13,3,3,3,Paleta.Hueso);
        L.P(11,9,1,1,Paleta.Hueso); L.P(11,14,1,1,Paleta.Hueso); Guardar("camisa", L);

        L = I24();
        L.P(5,3,14,5,Paleta.H("#3a4f6b")); L.P(5,3,14,2,Paleta.Acero);
        L.P(5,8,6,13,Paleta.H("#3a4f6b")); L.P(13,8,6,13,Paleta.H("#2c3d53"));
        L.P(11,8,2,5,Paleta.H("#2c3d53")); L.P(5,3,1,18,Paleta.Acero);
        L.P(7,10,1,4,Paleta.H("#2c3d53")); Guardar("pantalon", L);

        L = I24();
        L.P(3,12,13,7,Paleta.MaderaO); L.P(3,12,13,2,Paleta.H("#8a6a44"));
        L.P(14,14,7,5,Paleta.MaderaO); L.P(3,19,18,2,Paleta.Negro);
        L.P(6,14,7,2,Paleta.Crema); Guardar("zapato", L);

        L = I24();
        L.P(5,7,14,7,Paleta.RojoO); L.P(5,7,14,2,Paleta.Rojo);
        L.P(3,13,17,3,Paleta.RojoO); L.P(11,4,2,4,Paleta.Rojo); Guardar("gorra", L);

        L = I24();
        L.P(2,5,20,13,Paleta.RojoO); L.P(2,5,20,2,Paleta.Rojo);
        L.P(4,8,6,5,Paleta.AzulL); L.P(12,8,8,5,Paleta.AzulL); L.P(4,15,16,2,Paleta.Mostaza);
        L.P(5,18,4,3,Paleta.Carbon); L.P(15,18,4,3,Paleta.Carbon); Guardar("bus", L);

        L = I24();
        L.P(3,4,18,14,Paleta.RojoO); L.P(3,4,18,2,Paleta.Rojo); L.P(5,7,14,6,Paleta.AzulL);
        L.P(3,18,18,2,Paleta.Carbon); L.P(6,20,3,2,Paleta.Mostaza); L.P(15,20,3,2,Paleta.Mostaza);
        L.P(11,7,2,6,Paleta.Carbon); Guardar("metro", L);

        L = I24();
        L.P(2,6,17,11,Paleta.VerdeO); L.P(2,6,17,2,Paleta.Verde);
        L.P(4,9,5,5,Paleta.AzulL); L.P(11,9,6,5,Paleta.AzulL); L.P(19,10,3,7,Paleta.GrisO);
        L.P(2,17,20,2,Paleta.Carbon); L.P(5,19,4,3,Paleta.Carbon);
        L.P(14,19,4,3,Paleta.Carbon); Guardar("tren", L);

        L = I24();
        L.P(2,9,20,3,Paleta.Hueso); L.P(4,12,16,3,Paleta.Blanco); L.P(7,5,10,4,Paleta.MaderaO);
        L.P(8,3,8,3,Paleta.H("#8a6a44")); L.P(9,6,3,2,Paleta.Crema);
        L.P(2,16,20,2,Paleta.GrisO); Guardar("plato", L);

        // ── HUD ──
        var estrella = new[]{ new Vector2(12,1), new Vector2(15,9), new Vector2(23,9), new Vector2(16,14),
            new Vector2(19,22), new Vector2(12,17), new Vector2(5,22), new Vector2(8,14),
            new Vector2(1,9), new Vector2(9,9) };
        L = I24(); L.Poligono(estrella, Paleta.H("#ff5a3c")); Guardar("estrella", L);
        L = I24(); L.Poligono(estrella, Paleta.GrisO); Guardar("estrellaOff", L);
        L = I24();
        L.P(7,5,10,3,Paleta.Mostaza); L.P(5,8,4,8,Paleta.Mostaza); L.P(7,16,10,3,Paleta.Mostaza);
        L.P(3,10,10,2,Paleta.Mostaza); L.P(3,13,10,2,Paleta.Mostaza); Guardar("euro", L);
        L = I24();
        L.P(12,2,6,10,Paleta.H("#4d9de0")); L.P(6,10,6,12,Paleta.H("#4d9de0"));
        L.P(8,9,8,4,Paleta.H("#4d9de0")); Guardar("energia", L);
        L = I24();
        L.P(5,4,3,10,Paleta.Crema); L.P(10,4,2,7,Paleta.Crema); L.P(13,4,2,7,Paleta.Crema);
        L.P(10,10,5,3,Paleta.Crema); L.P(11,13,3,8,Paleta.Crema); L.P(5,14,3,7,Paleta.Crema);
        Guardar("hambre", L);
        L = I24();
        L.P(9,4,6,16,Paleta.Sangre); L.P(4,9,16,6,Paleta.Sangre); Guardar("salud", L);
    }
}

}

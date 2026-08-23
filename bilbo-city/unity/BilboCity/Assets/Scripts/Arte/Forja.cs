using System.Collections.Generic;
using UnityEngine;

namespace BilboCity {

/// <summary>Tipos de casilla del mundo.</summary>
public enum Suelo { Road = 0, Acera = 1, Edif = 2, Parque = 3, Agua = 4, Puente = 5, Plaza = 6, Muelle = 7, Patio = 8 }

/// <summary>Todo el arte que no son personajes: suelo, vehículos, mobiliario, armas y HUD.</summary>
public static class Forja {

    // ═══════════ TILES ═══════════
    public const int TS = 32;
    public static readonly Dictionary<string, Sprite> Tiles = new Dictionary<string, Sprite>();
    public static Sprite[] Tejados, Azoteas, AguaFrames;
    static Texture2D _atlasTiles;
    static readonly List<Lienzo> _pend = new List<Lienzo>();
    static readonly List<string> _pendNom = new List<string>();

    static Lienzo T32() { return new Lienzo(TS, TS); }
    static void Reg(string nombre, Lienzo l) { _pendNom.Add(nombre); _pend.Add(l); }

    public static void GenerarTiles() {
        if (_atlasTiles != null) return;
        var g = T32(); g.Rellenar(Paleta.Asfalto); g.Ruido(new[]{Paleta.AsfaltoO,Paleta.AsfaltoL}, 22); Reg("road", g);

        g = T32(); g.Rellenar(Paleta.Asfalto); g.Ruido(new[]{Paleta.AsfaltoO,Paleta.AsfaltoL}, 22);
        for (int i = 0; i < 26; i++) g.P(4 + i*0.9f, 6 + Mathf.Sin(i/3f)*4, 1, 1, Paleta.AsfaltoO); Reg("roadGrieta", g);

        g = T32(); g.Rellenar(Paleta.Asfalto); g.Ruido(new[]{Paleta.AsfaltoO,Paleta.AsfaltoL}, 22);
        g.P(8,15,16,2,Paleta.Crema); Reg("lineaH", g);

        g = T32(); g.Rellenar(Paleta.Asfalto); g.Ruido(new[]{Paleta.AsfaltoO,Paleta.AsfaltoL}, 22);
        g.P(15,8,2,16,Paleta.Crema); Reg("lineaV", g);

        g = T32(); g.Rellenar(Paleta.Asfalto);
        for (int y = 2; y < 32; y += 8) g.P(0,y,32,5,Paleta.Crema); Reg("cebraH", g);

        g = T32(); g.Rellenar(Paleta.Asfalto);
        for (int x = 2; x < 32; x += 8) g.P(x,0,5,32,Paleta.Crema); Reg("cebraV", g);

        g = T32(); g.Rellenar(Paleta.Asfalto); g.Ruido(new[]{Paleta.AsfaltoO}, 18);
        g.P(9,9,14,14,Paleta.Gris);
        for (int i = 11; i < 22; i += 3) g.P(i,11,1,10,Paleta.Carbon); Reg("alcantarilla", g);

        g = T32(); g.Rellenar(Paleta.Hormigon); g.Ruido(new[]{Paleta.HormigonO,Paleta.HormigonL}, 16);
        for (int i = 0; i < 32; i += 8) { g.P(i,0,1,32,Paleta.HormigonO); g.P(0,i,32,1,Paleta.HormigonO); } Reg("acera", g);

        g = T32(); g.Rellenar(Paleta.HormigonO); g.Ruido(new[]{Paleta.Hormigon,Paleta.Carbon}, 26);
        for (int i = 0; i < 32; i += 8) g.P(0,i,32,1,Paleta.Carbon); Reg("aceraGast", g);

        g = T32(); g.Rellenar(Paleta.HormigonO);
        for (int y = 0; y < 32; y += 6) for (int x = (y%12 != 0 ? 3 : 0); x < 32; x += 7) {
            g.P(x,y,6,5,Paleta.Hormigon); g.P(x,y,6,1,Paleta.HormigonL); } Reg("adoquin", g);

        g = T32(); g.Rellenar(Paleta.TejaO);
        for (int y = 0; y < 32; y += 6) for (int x = (y%12 != 0 ? 3 : 0); x < 32; x += 7) {
            g.P(x,y,6,5,Paleta.Teja); g.P(x,y,6,1,Paleta.H("#96786a")); } Reg("adoquinRojo", g);

        g = T32(); g.Rellenar(Paleta.H("#8a8375")); g.Ruido(new[]{Paleta.H("#7d766a"),Paleta.H("#968f81")}, 14);
        for (int i = 0; i < 32; i += 16) { g.P(i,0,1,32,Paleta.H("#6d6659")); g.P(0,i,32,1,Paleta.H("#6d6659")); }
        g.P(14,14,4,4,Paleta.H("#6d6659")); Reg("plaza", g);

        g = T32(); g.Rellenar(Paleta.HormigonO); g.Ruido(new[]{Paleta.Hormigon,Paleta.CespedO}, 20);
        for (int i = 0; i < 32; i += 11) g.P(i,0,1,32,Paleta.Carbon); Reg("patio", g);

        g = T32(); g.Rellenar(Paleta.Cesped); g.Ruido(new[]{Paleta.CespedO,Paleta.H("#4d7c48")}, 28); Reg("parque", g);

        g = T32(); g.Rellenar(Paleta.CespedO); g.Ruido(new[]{Paleta.Cesped,Paleta.H("#4d7c48")}, 34);
        for (int i = 0; i < 10; i++) g.P((i*7)%30,(i*11)%28,1,4,Paleta.H("#4d7c48")); Reg("parqueAlto", g);

        for (int f = 0; f < 2; f++) {
            g = T32(); g.Rellenar(Paleta.Agua); g.Ruido(new[]{Paleta.H("#193f4a"),Paleta.H("#20505e")}, 20);
            for (int y = (f*4)%8; y < 32; y += 8) g.P(0,y,32,1,Paleta.AguaL);
            for (int y = (f*4+4)%8; y < 32; y += 8) g.P(4,y,22,1,Paleta.H("#35798a"));
            Reg("agua"+f, g);
        }

        g = T32(); g.Rellenar(Paleta.Gris); g.Ruido(new[]{Paleta.GrisO,Paleta.GrisL}, 18);
        for (int x = 0; x < 32; x += 4) { g.P(x,0,2,2,Paleta.Acero); g.P(x,30,2,2,Paleta.Acero); } Reg("puente", g);

        g = T32(); g.Rellenar(Paleta.H("#5e5346")); g.Ruido(new[]{Paleta.H("#524839"),Paleta.H("#6b6052")}, 18);
        for (int y = 0; y < 32; y += 6) g.P(0,y,32,1,Paleta.H("#463d31")); Reg("muelle", g);

        string[,] tej = {
            {"#6b5d52","#554a41","#867567"}, {"#5c5a63","#4a4850","#75727d"},
            {"#7a5f52","#635047","#95776a"}, {"#566060","#454e4e","#6e7a7a"},
            {"#6e6656","#5a5346","#8a806c"}, {"#4d4a52","#3d3b42","#656169"},
            {"#7d6a4e","#66563e","#998364"}, {"#5a4f4a","#48403c","#736660"}
        };
        for (int i = 0; i < 8; i++) {
            g = T32(); g.Rellenar(Paleta.H(tej[i,0]));
            g.Ruido(new[]{Paleta.H(tej[i,1]),Paleta.H(tej[i,2])}, 14);
            for (int y = 6; y < 28; y += 7) g.P(3,y,26,1,Paleta.H(tej[i,1]));
            Reg("tejado"+i, g);
        }
        // azoteas: lucernario, aire acondicionado, tendedero, antenas, depósito, chapa, óxido, pizarra
        g = T32(); g.Rellenar(Paleta.H("#5c5a63")); g.Ruido(new[]{Paleta.H("#4a4850")},16);
        g.P(9,9,14,14,Paleta.H("#7f9aa8")); g.P(11,11,10,10,Paleta.H("#a8c4d0")); Reg("azotea0", g);
        g = T32(); g.Rellenar(Paleta.H("#5c5a63")); g.Ruido(new[]{Paleta.H("#4a4850")},16);
        g.P(6,8,14,12,Paleta.Acero); g.P(8,10,10,8,Paleta.AceroO);
        for (int i = 9; i < 18; i += 3) g.P(i,10,1,8,Paleta.Acero); Reg("azotea1", g);
        g = T32(); g.Rellenar(Paleta.H("#6e6656")); g.Ruido(new[]{Paleta.H("#5a5346")},14);
        g.P(4,10,24,1,Paleta.Acero);
        var ropa = new[]{Paleta.Rojo,Paleta.Blanco,Paleta.Azul,Paleta.Mostaza};
        for (int i = 0; i < 4; i++) g.P(6+i*6,11,4,7,ropa[i]); Reg("azotea2", g);
        g = T32(); g.Rellenar(Paleta.H("#5c5a63")); g.Ruido(new[]{Paleta.H("#4a4850")},16);
        g.P(15,6,2,20,Paleta.Acero); for (int y = 8; y < 22; y += 4) g.P(10,y,12,1,Paleta.Acero); Reg("azotea3", g);
        g = T32(); g.Rellenar(Paleta.H("#5c5a63")); g.Ruido(new[]{Paleta.H("#4a4850")},16);
        g.P(8,8,16,16,Paleta.Crema); g.P(10,10,12,12,Paleta.Hormigon); g.P(14,4,4,5,Paleta.Acero); Reg("azotea4", g);
        g = T32(); g.Rellenar(Paleta.H("#566060"));
        for (int x = 0; x < 32; x += 4) { g.P(x,0,1,32,Paleta.H("#454e4e")); g.P(x+1,0,1,32,Paleta.H("#6e7a7a")); } Reg("azotea5", g);
        g = T32(); g.Rellenar(Paleta.H("#6b4f3a"));
        for (int x = 0; x < 32; x += 4) g.P(x,0,1,32,Paleta.H("#4d3728"));
        g.Ruido(new[]{Paleta.H("#8a5c37"),Paleta.RojoO}, 22); Reg("azotea6", g);
        g = T32(); g.Rellenar(Paleta.H("#3f4348")); g.Ruido(new[]{Paleta.H("#33373b"),Paleta.H("#4d5257")},20);
        for (int y = 0; y < 32; y += 8) g.P(0,y,32,1,Paleta.H("#2c3033")); Reg("azotea7", g);

        // suelos y paredes de interior
        g = T32(); g.Rellenar(Paleta.HormigonL); g.Ruido(new[]{Paleta.Acero,Paleta.Crema,Paleta.HormigonO}, 38);
        for (int i = 0; i < 32; i += 16) { g.P(i,0,1,32,Paleta.HormigonO); g.P(0,i,32,1,Paleta.HormigonO); } Reg("terrazo", g);
        g = T32(); g.Rellenar(Paleta.Crema);
        for (int y = 0; y < 32; y += 16) for (int x = 0; x < 32; x += 16) {
            g.P(x+2,y+2,12,12,Paleta.AzulL); g.P(x+5,y+5,6,6,Paleta.Crema);
            g.P(x,y,16,1,Paleta.HormigonO); g.P(x,y,1,16,Paleta.HormigonO); } Reg("hidraulico", g);
        g = T32(); g.Rellenar(Paleta.H("#4d5157")); g.Ruido(new[]{Paleta.H("#42464b"),Paleta.H("#5b6067")},18);
        g.P(0,15,32,2,Paleta.MostazaO); Reg("sueloTaller", g);
        g = T32(); g.Rellenar(Paleta.H("#8fa8a0")); g.Ruido(new[]{Paleta.H("#7d968e"),Paleta.H("#a3bab2")},14);
        for (int i = 0; i < 32; i += 16) g.P(i,0,1,32,Paleta.H("#7d968e")); Reg("sueloHosp", g);
        g = T32(); g.Rellenar(Paleta.H("#4b3b32")); g.Ruido(new[]{Paleta.H("#43342c"),Paleta.H("#57453a")},16);
        for (int y = 0; y < 32; y += 8) { g.P(0,y,32,1,Paleta.H("#3a2d26"));
            for (int x = (y%16 != 0 ? 8 : 0); x < 32; x += 16) g.P(x,y,1,8,Paleta.H("#3a2d26")); }
        g.P(0,0,32,3,Paleta.H("#5e4a3d")); Reg("pared", g);
        g = T32(); g.Rellenar(Paleta.H("#2f5f5a"));
        for (int y = 0; y < 32; y += 8) for (int x = 0; x < 32; x += 8) {
            g.P(x,y,7,7,Paleta.H("#3a7570")); g.P(x,y,7,1,Paleta.H("#4d908a")); }
        g.P(0,0,32,3,Paleta.H("#4d908a")); Reg("paredAzul", g);
        g = T32(); g.Rellenar(Paleta.H("#566060"));
        for (int x = 0; x < 32; x += 4) g.P(x,0,2,32,Paleta.H("#454e4e"));
        g.P(0,0,32,3,Paleta.H("#6e7a7a")); Reg("paredChapa", g);
        g = T32(); g.Rellenar(Paleta.H("#c9c4b6")); g.Ruido(new[]{Paleta.H("#b8b3a5")},10);
        g.P(0,0,32,3,Paleta.Blanco); Reg("paredBlanca", g);

        // mobiliario
        g = T32(); g.Rellenar(Paleta.Madera); g.Ruido(new[]{Paleta.MaderaO,Paleta.MaderaL},14);
        g.P(0,0,32,4,Paleta.MaderaL); g.P(0,28,32,4,Paleta.MaderaO); Reg("barra", g);
        g = T32(); g.P(4,6,24,22,Paleta.Negro); g.P(3,4,25,23,Paleta.H("#7a5233")); g.P(5,6,21,4,Paleta.H("#93663f"));
        g.P(7,12,6,6,Paleta.Crema); g.P(18,15,5,8,Paleta.H("#8fae8a")); Reg("mesa", g);
        g = T32(); g.P(3,2,26,28,Paleta.H("#5a4433")); g.P(5,4,22,24,Paleta.H("#8a9bb0"));
        g.P(5,4,22,8,Paleta.H("#c9d2dd")); g.P(8,5,16,5,Paleta.Blanco); Reg("cama", g);
        g = T32(); g.P(2,4,28,24,Paleta.H("#5c4630")); g.P(4,6,11,20,Paleta.H("#6d543a")); g.P(17,6,11,20,Paleta.H("#6d543a"));
        g.P(13,14,3,3,Paleta.Mostaza); g.P(16,14,3,3,Paleta.Mostaza); Reg("mueble", g);
        g = T32(); g.P(1,4,30,24,Paleta.GrisO); g.P(3,6,26,14,Paleta.H("#66727f"));
        g.P(5,9,10,2,Paleta.Carbon); g.P(5,14,13,2,Paleta.Carbon); g.P(20,9,8,3,Paleta.Acero);
        g.P(1,2,30,3,Paleta.RojoO); Reg("vitrina", g);
        g = T32(); g.Rellenar(Paleta.H("#3d3d44")); g.Ruido(new[]{Paleta.H("#35353b"),Paleta.H("#46464e")},18);
        g.P(4,10,24,12,Paleta.RojoO); g.P(10,12,12,8,Paleta.Carbon); Reg("cocheEx", g);
        g = T32(); g.P(1,6,30,22,Paleta.Acero); g.P(3,8,26,10,Paleta.H("#cfd6dd"));
        for (int i = 0; i < 5; i++) g.P(4+i*5,10,4,6,Paleta.H("#7fa8c4"));
        g.P(1,4,30,3,Paleta.RojoO); Reg("puesto", g);
        g = T32(); g.P(3,4,26,24,Paleta.Blanco); g.P(5,6,22,20,Paleta.H("#8fa8a0")); g.P(5,6,22,6,Paleta.Crema);
        g.P(4,28,3,3,Paleta.Acero); g.P(25,28,3,3,Paleta.Acero); Reg("camilla", g);
        g = T32(); g.P(1,10,30,18,Paleta.MaderaO); g.P(1,8,30,4,Paleta.MaderaL); g.P(6,14,8,6,Paleta.Crema); Reg("mostrador", g);
        g = T32(); g.Rellenar(Paleta.H("#5f7182"));
        for (int x = 0; x < 32; x += 8) { g.P(x,0,7,32,Paleta.H("#6b7f92"));
            g.P(x+5,6,1,3,Paleta.Acero); g.P(x+5,20,1,3,Paleta.Acero); } Reg("taquilla", g);
        g = T32(); g.Rellenar(Paleta.H("#8fa8a0"));
        for (int x = 2; x < 30; x += 9) { g.P(x,8,7,12,Paleta.AzulL); g.P(x,6,7,3,Paleta.Azul); } Reg("sillas", g);
        g = T32(); g.Rellenar(Paleta.GrisO);
        for (int y = 2; y < 30; y += 9) { g.P(0,y+7,32,2,Paleta.Gris);
            for (int x = 2; x < 30; x += 6) g.P(x,y,4,7,Paleta.MostazaO); } Reg("estante", g);

        // ── volcado al atlas ──
        int cols = 8;
        int filas = Mathf.CeilToInt(_pend.Count / (float)cols);
        int aw = cols * TS, ah = filas * TS;
        var px = new Color32[aw * ah];
        for (int i = 0; i < _pend.Count; i++)
            _pend[i].VolcarEn(px, aw, ah, (i % cols) * TS, (i / cols) * TS);
        Paleta.Cuantizar(px);
        _atlasTiles = Utiles.Textura(aw, ah, px);
        for (int i = 0; i < _pend.Count; i++) {
            int rx = (i % cols) * TS;
            int ry = ah - ((i / cols) + 1) * TS;
            Tiles[_pendNom[i]] = Utiles.Rebanada(_atlasTiles, rx, ry, TS, TS, 0f, 0f);
        }
        Tejados = new Sprite[8]; for (int i = 0; i < 8; i++) Tejados[i] = Tiles["tejado"+i];
        Azoteas = new Sprite[8]; for (int i = 0; i < 8; i++) Azoteas[i] = Tiles["azotea"+i];
        AguaFrames = new[]{ Tiles["agua0"], Tiles["agua1"] };
        _pend.Clear(); _pendNom.Clear();
    }

    // ═══════════ VEHÍCULOS ═══════════
    public struct Chasis { public int l, an, morro, cabX, cabW, cajaX, cajaW; public bool taxi, rotativo, cruz, bus, volquete, alto; }
    public static readonly Dictionary<string, Chasis> Chasises = new Dictionary<string, Chasis> {
        {"utilitario", new Chasis{ l=32,an=18,morro=4,cabX=9,cabW=11 }},
        {"berlina",    new Chasis{ l=38,an=18,morro=6,cabX=12,cabW=12 }},
        {"ranchera",   new Chasis{ l=40,an=18,morro=6,cabX=11,cabW=18 }},
        {"furgoCorta", new Chasis{ l=36,an=20,morro=5,cabX=8,cabW=8, cajaX=17,cajaW=15 }},
        {"furgoLarga", new Chasis{ l=44,an=20,morro=5,cabX=8,cabW=8, cajaX=17,cajaW=24 }},
        {"deportivo",  new Chasis{ l=38,an=17,morro=8,cabX=14,cabW=11 }},
        {"todoterreno",new Chasis{ l=38,an=21,morro=5,cabX=11,cabW=16, alto=true }},
        {"taxi",       new Chasis{ l=38,an=18,morro=6,cabX=12,cabW=12, taxi=true }},
        {"patrulla",   new Chasis{ l=38,an=18,morro=6,cabX=12,cabW=12, rotativo=true }},
        {"ambulancia", new Chasis{ l=44,an=21,morro=5,cabX=8,cabW=8, cajaX=16,cajaW=26, rotativo=true, cruz=true }},
        {"basura",     new Chasis{ l=46,an=21,morro=5,cabX=8,cabW=9, cajaX=18,cajaW=26 }},
        {"autobus",    new Chasis{ l=56,an=22,morro=3,cabX=6,cabW=46, bus=true }},
        {"camionObra", new Chasis{ l=46,an=21,morro=6,cabX=9,cabW=10, volquete=true }},
    };
    public static readonly string[][] Libreas = {
        new[]{"#c23b22","#952914","#e05b3c"}, new[]{"#3f6f8f","#2f5469","#5b93b5"},
        new[]{"#8f8f3f","#6e6e2f","#b3b35b"}, new[]{"#3f8f6f","#2f6c53","#5bb392"},
        new[]{"#8f5f3f","#6c472f","#b37f5b"}, new[]{"#c9c9c9","#9d9d9d","#eaeaea"},
        new[]{"#2f3f4f","#22303c","#48606f"}
    };
    public static readonly Dictionary<string, Sprite[]> Veh = new Dictionary<string, Sprite[]>();
    public static readonly Dictionary<string, Sprite> VehQuemado = new Dictionary<string, Sprite>();
    public static Sprite[] PatrullaRot;

    static Lienzo DibVeh(string tipo, string[] lib, string estado) {
        var K = Chasises[tipo];
        var L = new Lienzo(K.l + 6, K.an + 6);
        int ox = 3, oy = 3, l = K.l, an = K.an;
        Color32 baseC = Paleta.H(lib[0]), osc = Paleta.H(lib[1]), cl = Paleta.H(lib[2]);
        if (estado == "quemado") { baseC = Paleta.H("#2a2622"); osc = Paleta.H("#191612"); cl = Paleta.H("#3a352f"); }
        L.P(ox, oy+1, l, an-2, Paleta.Negro);
        L.P(ox+1, oy+1, l-2, an-2, baseC);
        L.P(ox+1, oy+1, l-2, 2, cl);
        L.P(ox+1, oy+an-3, l-2, 2, osc);
        L.P(ox+2, oy+3, K.morro, an-6, cl);
        L.P(ox+K.cabX, oy+3, K.cabW, an-6, Paleta.Carbon);
        L.P(ox+K.cabX+1, oy+4, 3, an-8, Paleta.H("#3f5566"));
        L.P(ox+K.cabX+K.cabW-3, oy+4, 2, an-8, Paleta.H("#31424f"));
        if (K.cajaW > 0) { L.P(ox+K.cajaX, oy+2, K.cajaW, an-4, cl); L.P(ox+K.cajaX+1, oy+3, K.cajaW-2, an-6, baseC); }
        if (K.bus) for (int i = 8; i < l-6; i += 7) L.P(ox+i, oy+2, 5, 2, Paleta.H("#3f5566"));
        if (K.volquete) L.P(ox+K.cabX+K.cabW, oy+2, l-K.cabX-K.cabW-2, an-4, Paleta.MostazaO);
        L.P(ox+l-4, oy+4, 3, 3, Paleta.H("#e8dfa8"));
        L.P(ox+l-4, oy+an-7, 3, 3, Paleta.H("#e8dfa8"));
        L.P(ox+1, oy+4, 2, 3, Paleta.Crema);
        L.P(ox+1, oy+an-7, 2, 3, Paleta.Crema);
        int rw = K.alto ? 4 : 3;
        L.P(ox+5, oy-1, 6, rw, Paleta.Negro); L.P(ox+l-12, oy-1, 6, rw, Paleta.Negro);
        L.P(ox+5, oy+an-2, 6, rw, Paleta.Negro); L.P(ox+l-12, oy+an-2, 6, rw, Paleta.Negro);
        if (K.taxi) {
            L.P(ox+K.cabX+2, oy-1, 6, 3, Paleta.Mostaza);
            for (int i = 0; i < l-8; i += 4) L.P(ox+2+i, oy+an/2-1, 2, 2, Paleta.Carbon);
        }
        if (K.rotativo) {
            L.P(ox+K.cabX, oy+1, 3, an-2, estado == "rotA" ? Paleta.H("#2f6bff") : Paleta.Gris);
            L.P(ox+K.cabX+3, oy+1, 3, an-2, estado == "rotA" ? Paleta.Gris : Paleta.H("#ff3b30"));
        }
        if (K.cruz) { L.P(ox+18, oy+an/2-1, 10, 2, Paleta.Rojo); L.P(ox+22, oy+an/2-5, 2, 10, Paleta.Rojo); }
        if (estado == "quemado")
            for (int i = 0; i < 14; i++) L.P(ox+2+((i*5)%(l-4)), oy+2+((i*3)%(an-4)), 2, 2, Paleta.H("#1a1714"));
        return L;
    }

    public static void GenerarVehiculos() {
        if (Veh.Count > 0) return;
        foreach (var kv in Chasises) {
            string tipo = kv.Key;
            var sp = new Sprite[Libreas.Length];
            for (int i = 0; i < Libreas.Length; i++) sp[i] = SpriteDe(DibVeh(tipo, Libreas[i], "normal"));
            Veh[tipo] = sp;
            VehQuemado[tipo] = SpriteDe(DibVeh(tipo, Libreas[0], "quemado"));
        }
        PatrullaRot = new[] {
            SpriteDe(DibVeh("patrulla", Libreas[5], "rotA")),
            SpriteDe(DibVeh("patrulla", Libreas[5], "rotB"))
        };
    }

    /// <summary>Sprite suelto con pivote centrado, para cosas que rotan.</summary>
    public static Sprite SpriteDe(Lienzo L) {
        var px = new Color32[L.W * L.H];
        L.VolcarEn(px, L.W, L.H, 0, 0);
        Paleta.Cuantizar(px);
        var tex = Utiles.Textura(L.W, L.H, px);
        return Utiles.Rebanada(tex, 0, 0, L.W, L.H, L.W/2f, L.H/2f);
    }
    /// <summary>Sprite con el pivote en la base, para props apoyados en el suelo.</summary>
    public static Sprite SpriteBase(Lienzo L) {
        var px = new Color32[L.W * L.H];
        L.VolcarEn(px, L.W, L.H, 0, 0);
        Paleta.Cuantizar(px);
        var tex = Utiles.Textura(L.W, L.H, px);
        return Utiles.Rebanada(tex, 0, 0, L.W, L.H, L.W/2f, 0f);
    }

    // ═══════════ PROPS ═══════════
    public static readonly Dictionary<string, Sprite> Props = new Dictionary<string, Sprite>();
    public static void GenerarProps() {
        if (Props.Count > 0) return;
        Lienzo L;
        L = new Lienzo(12,28); L.P(5,8,2,20,Paleta.AsfaltoL); L.P(4,27,4,1,Paleta.Carbon);
        L.P(5,6,5,2,Paleta.AsfaltoL); L.P(8,7,4,3,Paleta.Gris); L.P(9,8,2,2,Paleta.H("#f2e2a8"));
        Props["farola"] = SpriteBase(L);
        L = new Lienzo(10,30); L.P(4,13,2,17,Paleta.Carbon); L.P(2,1,6,13,Paleta.GrisO);
        L.P(3,2,4,3,Paleta.Rojo); L.P(3,6,4,3,Paleta.Mostaza); L.P(3,10,4,3,Paleta.VerdeL);
        Props["semaforo"] = SpriteBase(L);
        L = new Lienzo(28,30); L.P(12,18,4,12,Paleta.H("#4a3524")); L.P(6,4,16,16,Paleta.H("#2e5b2c"));
        L.P(8,2,12,4,Paleta.H("#3a7038")); L.P(4,8,20,8,Paleta.H("#356b33")); L.P(9,6,8,5,Paleta.H("#4a8746"));
        Props["arbol"] = SpriteBase(L);
        L = new Lienzo(20,26); L.P(9,14,3,12,Paleta.H("#4a3524")); L.P(5,5,11,10,Paleta.H("#356b33"));
        L.P(7,3,7,4,Paleta.H("#4a8746")); Props["arbolPodado"] = SpriteBase(L);
        L = new Lienzo(22,18); L.P(1,3,20,15,Paleta.H("#2f6b4a")); L.P(2,4,18,4,Paleta.H("#3d8a60"));
        L.P(1,1,20,3,Paleta.H("#22503a")); Props["contenedor"] = SpriteBase(L);
        L = new Lienzo(22,18); L.P(1,3,20,15,Paleta.MostazaO); L.P(2,4,18,4,Paleta.Mostaza);
        L.P(1,1,20,3,Paleta.H("#8c7420")); Props["contenedor2"] = SpriteBase(L);
        L = new Lienzo(12,16); L.P(2,4,8,12,Paleta.GrisO); L.P(1,2,10,3,Paleta.Gris);
        for (int i = 3; i < 9; i += 2) L.P(i,6,1,8,Paleta.Carbon); Props["papelera"] = SpriteBase(L);
        L = new Lienzo(24,12); L.P(1,2,22,8,Paleta.Madera); L.P(1,2,22,2,Paleta.MaderaL);
        L.P(3,10,3,2,Paleta.Carbon); L.P(18,10,3,2,Paleta.Carbon); Props["banco"] = SpriteBase(L);
        L = new Lienzo(16,22); L.P(1,1,14,21,Paleta.RojoO); L.P(3,3,10,14,Paleta.H("#7f9aa8"));
        L.P(1,0,14,3,Paleta.Rojo); Props["cabina"] = SpriteBase(L);
        L = new Lienzo(48,48); L.P(4,20,10,10,Paleta.Rojo); L.P(8,4,3,26,Paleta.Crema);
        L.P(8,4,36,3,Paleta.Crema); L.P(40,7,2,14,Paleta.Acero); L.P(38,20,6,4,Paleta.Mostaza);
        Props["grua"] = SpriteBase(L);
        L = new Lienzo(40,20); L.P(0,0,40,20,Paleta.RojoO);
        for (int x = 2; x < 40; x += 4) L.P(x,1,2,18,Paleta.Rojo);
        L.P(0,0,40,3,Paleta.H("#7a2c12")); Props["contMaritimo"] = SpriteBase(L);
        L = new Lienzo(22,16); L.P(1,4,20,10,Paleta.Madera);
        for (int x = 2; x < 20; x += 5) L.P(x,4,3,10,Paleta.MaderaL);
        L.P(1,2,20,3,Paleta.MaderaO); Props["pales"] = SpriteBase(L);
        L = new Lienzo(12,14); L.P(2,2,8,12,Paleta.AzulL); L.P(2,4,8,1,Paleta.Azul);
        L.P(2,9,8,1,Paleta.Azul); L.P(3,1,6,2,Paleta.Acero); Props["bidon"] = SpriteBase(L);
        L = new Lienzo(20,18); L.P(3,3,14,12,Paleta.Crema); L.P(3,3,14,3,Paleta.Blanco);
        L.P(5,15,2,3,Paleta.Acero); L.P(13,15,2,3,Paleta.Acero); L.P(8,6,4,4,Paleta.VerdeL);
        Props["terraza"] = SpriteBase(L);
    }

    // ═══════════ ARMAS EN MANO Y FOGONAZOS ═══════════
    public static readonly Dictionary<string, Sprite[]> ArmaMano = new Dictionary<string, Sprite[]>();
    public static readonly Dictionary<string, Sprite[]> Fogonazos = new Dictionary<string, Sprite[]>();

    public static void GenerarArmas() {
        if (ArmaMano.Count > 0) return;
        foreach (var a in Armas.Todas) {
            if (a.Largo <= 0) continue;
            var arr = new Sprite[8];
            for (int d8 = 0; d8 < 8; d8++) {
                int dir = d8 == 0 ? 0 : (d8 == 4 ? 1 : (d8 >= 5 ? 2 : 3));
                bool diag = d8 == 1 || d8 == 3 || d8 == 5 || d8 == 7;
                var L = new Lienzo(ForjaChar.CW, ForjaChar.CH);
                int gr = a.Grosor, y = 13, dg = diag ? 1 : 0;
                if (dir == 3) { L.P(13-dg, y+dg, a.Largo, gr, a.Col); L.P(11-dg, y+dg, 2, gr+1, a.Mango); }
                else if (dir == 2) { L.P(7+dg-a.Largo, y+dg, a.Largo, gr, a.Col); L.P(7+dg, y+dg, 2, gr+1, a.Mango); }
                else if (dir == 0) { L.P(12, y+2, gr, a.Largo, a.Col); L.P(12, y, gr+1, 2, a.Mango); }
                else { L.P(7, y-a.Largo, gr, a.Largo, a.Col); L.P(7, y, gr+1, 2, a.Mango); }
                var px = new Color32[L.W*L.H];
                L.VolcarEn(px, L.W, L.H, 0, 0);
                Paleta.Cuantizar(px);
                arr[d8] = Utiles.Rebanada(Utiles.Textura(L.W, L.H, px), 0, 0, L.W, L.H, 10f, 6f);
            }
            ArmaMano[a.Id] = arr;
        }
        var calibres = new[] {
            new object[]{"pistola", 6f, 3.2f}, new object[]{"subfusil", 8f, 4f}, new object[]{"escopeta", 11f, 6f}
        };
        foreach (var c in calibres) {
            string nom = (string)c[0]; float largo = (float)c[1], ancho = (float)c[2];
            var arr = new Sprite[8];
            for (int d = 0; d < 8; d++) {
                var L = new Lienzo(24,24);
                float ang = d * Mathf.PI/4f - Mathf.PI/2f;
                L.Poligono(Lienzo.Girar(new[]{ new Vector2(0,-1.6f), new Vector2(0,1.6f),
                    new Vector2(largo,ancho), new Vector2(largo,-ancho) }, ang, 12, 12), Paleta.RojoL);
                L.Poligono(Lienzo.Girar(new[]{ new Vector2(0,-1f), new Vector2(0,1f),
                    new Vector2(largo*0.5f,ancho*0.5f), new Vector2(largo*0.5f,-ancho*0.5f) }, ang, 12, 12), Paleta.Mostaza);
                L.Poligono(Lienzo.Girar(new[]{ new Vector2(0,-0.6f), new Vector2(0,0.6f),
                    new Vector2(largo*0.28f,ancho*0.3f), new Vector2(largo*0.28f,-ancho*0.3f) }, ang, 12, 12), Paleta.Blanco);
                arr[d] = SpriteDe(L);
            }
            Fogonazos[nom] = arr;
        }
    }

    /// <summary>Marcador colgante sobre un sitio del mapa.</summary>
    public static Sprite Marca(Color32 col) {
        var L = new Lienzo(14,18);
        for (int i = 0; i < 6; i++) L.P(2+i, 2+i, 10-i*2, 1, Paleta.Carbon);
        for (int i = 0; i < 5; i++) L.P(3+i, 3+i, 8-i*2, 1, col);
        L.P(4,3,6,1,Paleta.Hueso);
        return SpriteBase(L);
    }

    /// <summary>Flecha de brújula en una de las 8 direcciones.</summary>
    public static Sprite Flecha(int d8, Color32 col) {
        var L = new Lienzo(16,16);
        float ang = d8 * Mathf.PI/4f - Mathf.PI/2f;
        L.Poligono(Lienzo.Girar(new[]{ new Vector2(7.6f,0), new Vector2(-2,-6.4f), new Vector2(-2,-3.3f),
            new Vector2(-7.4f,-3.3f), new Vector2(-7.4f,3.3f), new Vector2(-2,3.3f), new Vector2(-2,6.4f) },
            ang, 8, 8), Paleta.Carbon);
        L.Poligono(Lienzo.Girar(new[]{ new Vector2(6,0), new Vector2(-1,-5), new Vector2(-1,-2),
            new Vector2(-6,-2), new Vector2(-6,2), new Vector2(-1,2), new Vector2(-1,5) },
            ang, 8, 8), col);
        return SpriteDe(L);
    }
}

}

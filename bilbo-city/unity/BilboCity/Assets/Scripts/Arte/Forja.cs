using System.Collections.Generic;
using UnityEngine;

namespace BilboCity {

/// <summary>Tipos de casilla del mundo.</summary>
public enum Suelo { Road = 0, Acera = 1, Edif = 2, Parque = 3, Agua = 4, Puente = 5, Plaza = 6, Muelle = 7, Patio = 8, Via = 9, Monte = 10 }

/// <summary>Todo el arte que no son personajes: suelo, vehículos, mobiliario, armas y HUD.</summary>
public static class Forja {

    // ═══════════ TILES ═══════════
    public const int TS = 32;
    public static readonly Dictionary<string, Sprite> Tiles = new Dictionary<string, Sprite>();
    /// Los 19 tejados: 5 de teja, 4 de pizarra, 5 de azotea y 5 de nave, en ese orden.
    public static Sprite[] Tejados, AguaFrames;
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

        // La vía se forja en las dos orientaciones y al volcar se elige según por dónde
        // sigue el trazado: una sola horizontal quedaría con las traviesas atravesadas.
        g = T32(); g.Rellenar(Paleta.H("#6e6660")); g.Ruido(new[]{Paleta.H("#5f5852"),Paleta.H("#7d746c")}, 26);
        for (int x = 1; x < 32; x += 5) g.P(x,10,3,12,Paleta.H("#4a423c"));
        g.P(0,12,32,2,Paleta.H("#9aa0a4")); g.P(0,19,32,2,Paleta.H("#9aa0a4")); Reg("via", g);

        g = T32(); g.Rellenar(Paleta.H("#6e6660")); g.Ruido(new[]{Paleta.H("#5f5852"),Paleta.H("#7d746c")}, 26);
        for (int y = 1; y < 32; y += 5) g.P(10,y,12,3,Paleta.H("#4a423c"));
        g.P(12,0,2,32,Paleta.H("#9aa0a4")); g.P(19,0,2,32,Paleta.H("#9aa0a4")); Reg("viaV", g);

        g = T32(); g.Rellenar(Paleta.Cesped); g.Ruido(new[]{Paleta.CespedO,Paleta.H("#4d7c48")}, 28); Reg("parque", g);

        g = T32(); g.Rellenar(Paleta.CespedO); g.Ruido(new[]{Paleta.Cesped,Paleta.H("#4d7c48")}, 34);
        for (int i = 0; i < 10; i++) g.P((i*7)%30,(i*11)%28,1,4,Paleta.H("#4d7c48")); Reg("parqueAlto", g);

        // Medio término municipal de Bilbao es ladera. No es parque: es argoma, helecho y
        // roca, y se pisa pero no se conduce.
        g = T32(); g.Rellenar(Paleta.H("#4a6340")); g.Ruido(new[]{Paleta.H("#3f5638"),Paleta.H("#57704a")}, 30);
        Reg("monte", g);

        g = T32(); g.Rellenar(Paleta.H("#456039")); g.Ruido(new[]{Paleta.H("#3a5232"),Paleta.H("#5b7550")}, 36);
        for (int i = 0; i < 8; i++) g.P((i*11)%29,(i*7)%27,2,3,Paleta.H("#6b7f4a")); Reg("monteMata", g);

        g = T32(); g.Rellenar(Paleta.H("#4a6340")); g.Ruido(new[]{Paleta.H("#3f5638")}, 26);
        g.P(9,12,10,7,Paleta.H("#7a7468")); g.P(11,10,6,3,Paleta.H("#8a8478")); Reg("monteRoca", g);

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

        // Vista desde arriba, un edificio es su tejado, y hasta aquí todos llevaban el
        // mismo: el Casco Viejo, el Ensanche y una nave de Zorrotzaurre se veían igual.
        // Ahora hay cuatro familias y la elige el barrio de cada casilla (Ciudad.Tejados).
        // Poco contraste dentro del tile a propósito: a treinta y dos píxeles por cinco
        // metros un tejado tiene que leerse como material y no como rayas.
        string[,] teja = { {"#8e4f2c","#5f3520"}, {"#8a5c37","#5f4840"}, {"#7a4630","#54301f"},
                           {"#7a5f52","#4d3728"}, {"#96603a","#63402a"} };
        for (int i = 0; i < 5; i++) {
            g = T32(); g.Rellenar(Paleta.H(teja[i,0])); g.Ruido(new[]{Paleta.H(teja[i,1])}, 9);
            for (int y = 0; y < 32; y += 5) {
                g.P(0,y,32,1,Paleta.H(teja[i,1]));
                for (int x = (y/5%2)*4; x < 32; x += 8) g.P(x,y+1,2,4,Paleta.H(teja[i,1]));
            }
            Reg("tejado"+i, g);
        }
        string[,] piz = { {"#585665","#3f3d4a"}, {"#4e545c","#383d44"},
                          {"#615d69","#46434e"}, {"#4a5460","#353d47"} };
        for (int i = 0; i < 4; i++) {
            g = T32(); g.Rellenar(Paleta.H(piz[i,0])); g.Ruido(new[]{Paleta.H(piz[i,1])}, 10);
            for (int y = 0; y < 32; y += 5)
                for (int x = (y/5%2)*4; x < 32; x += 8) g.P(x,y,7,4,Paleta.H(piz[i,1]));
            Reg("tejado"+(5+i), g);
        }
        // La azotea es grava y nada más: lo que va encima va suelto, en Mobiliario. Un
        // depósito dibujado en el tile sale una vez por casilla y parece papel pintado.
        string[,] gra = { {"#5c5a63","#4a4850"}, {"#63615a","#4e4c46"}, {"#55524b","#423f3a"},
                          {"#4a5257","#3a4145"}, {"#6b6052","#524839"} };
        for (int i = 0; i < 5; i++) {
            g = T32(); g.Rellenar(Paleta.H(gra[i,0])); g.Ruido(new[]{Paleta.H(gra[i,1])}, 30);
            Reg("tejado"+(9+i), g);
        }
        // Naves: chapa ondulada y diente de sierra con los lucernarios.
        string[,] nav = { {"#7d8a90","#66727a"}, {"#8f8578","#736a5f"}, {"#6d7883","#57616b"} };
        for (int i = 0; i < 3; i++) {
            g = T32(); g.Rellenar(Paleta.H(nav[i,0]));
            for (int x = 0; x < 32; x += 5) g.P(x,0,2,32,Paleta.H(nav[i,1]));
            Reg("tejado"+(14+i), g);
        }
        string[,] sie = { {"#8a949a","#6d787f"}, {"#7f8a86","#65706c"} };
        for (int i = 0; i < 2; i++) {
            g = T32(); g.Rellenar(Paleta.H(sie[i,0]));
            for (int y = 0; y < 32; y += 10) {
                g.P(0,y,32,6,Paleta.H(sie[i,1]));
                g.P(0,y+6,32,3,Paleta.H("#a8c4d0"));
            }
            Reg("tejado"+(17+i), g);
        }

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
        g = T32(); g.Rellenar(Paleta.GrisO); g.P(0,5,32,2,Paleta.Acero); g.P(0,4,32,1,Paleta.HormigonL);
        var trapos = new[]{ Paleta.RojoO, Paleta.Azul, Paleta.VerdeO, Paleta.MostazaO, Paleta.Morado, Paleta.Carbon };
        for (int i = 0; i < 6; i++) { int x = 1 + i*5;
            g.P(x+1,3,2,3,Paleta.AceroO);
            g.P(x,7,4,15,trapos[i]); g.P(x,7,4,2,Paleta.Hueso); g.P(x+3,7,1,15,Paleta.Negro); }
        g.P(0,28,32,4,Paleta.Gris); Reg("perchero", g);
        g = T32(); g.Rellenar(Paleta.Acero);
        for (int y = 0; y < 32; y += 4) { g.P(2,y,28,3,Paleta.AceroO); g.P(2,y,28,1,Paleta.HormigonL); }
        g.P(0,0,2,32,Paleta.Gris); g.P(30,0,2,32,Paleta.GrisO); Reg("escalera", g);
        g = T32(); g.Rellenar(Paleta.Hormigon);
        g.P(5,2,22,26,Paleta.RojoO); g.P(5,2,22,3,Paleta.Rojo); g.P(26,2,1,26,Paleta.Sangre);
        g.P(8,6,15,11,Paleta.Carbon); g.P(10,8,11,4,Paleta.Mostaza); g.P(10,13,7,2,Paleta.Acero);
        g.P(27,12,4,9,Paleta.Carbon); g.P(4,20,24,3,Paleta.GrisO); Reg("surtidor", g);

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
        Tejados = new Sprite[19]; for (int i = 0; i < 19; i++) Tejados[i] = Tiles["tejado"+i];
        AguaFrames = new[]{ Tiles["agua0"], Tiles["agua1"] };
        _pend.Clear(); _pendNom.Clear();
    }

    // ═══════════ VEHÍCULOS ═══════════
    public struct Chasis { public int l, an, morro, cabX, cabW, cajaX, cajaW;
        public bool taxi, rotativo, cruz, bus, volquete, alto, moto, escalera, brazo, rejilla; }
    // Las medidas salen de las de verdad, no de lo que quedaba bonito. La escala del mapa
    // es 1 casilla = 32 px = 5,16 m, o sea 0,161 m por píxel, y todo lo vivo y lo rodante
    // va a una sola sobreescala, x2,1: es la más pequeña con la que un personaje sigue
    // siendo dibujable —a escala real unos hombros son 3 px— y aplicarla igual a todos es
    // lo que hace que la calle deje de contradecirse. Antes cada chasis iba por libre: el
    // utilitario a x1,32, la moto a x1,54 y el autobús a x0,75, más corto que una
    // ambulancia. Si tocas uno, sácalo de su medida real: metros x 2,1 / 0,161, a par.
    public static readonly Dictionary<string, Chasis> Chasises = new Dictionary<string, Chasis> {
        {"utilitario", new Chasis{ l=52,an=22,morro=7,cabX=15,cabW=18 }},
        {"berlina",    new Chasis{ l=60,an=24,morro=9,cabX=19,cabW=19 }},
        {"ranchera",   new Chasis{ l=64,an=24,morro=10,cabX=18,cabW=29 }},
        {"furgoCorta", new Chasis{ l=66,an=26,morro=9,cabX=15,cabW=15, cajaX=31,cajaW=28 }},
        {"furgoLarga", new Chasis{ l=78,an=26,morro=9,cabX=14,cabW=14, cajaX=30,cajaW=43 }},
        {"deportivo",  new Chasis{ l=58,an=24,morro=12,cabX=21,cabW=17 }},
        {"todoterreno",new Chasis{ l=60,an=26,morro=8,cabX=17,cabW=25, alto=true }},
        {"taxi",       new Chasis{ l=60,an=24,morro=9,cabX=19,cabW=19, taxi=true }},
        {"patrulla",   new Chasis{ l=60,an=24,morro=9,cabX=19,cabW=19, rotativo=true }},
        {"ambulancia", new Chasis{ l=72,an=28,morro=8,cabX=13,cabW=13, cajaX=26,cajaW=43, rotativo=true, cruz=true }},
        {"basura",     new Chasis{ l=98,an=34,morro=11,cabX=17,cabW=19, cajaX=38,cajaW=55 }},
        {"autobus",    new Chasis{ l=156,an=34,morro=8,cabX=17,cabW=128, bus=true }},
        {"camionObra", new Chasis{ l=92,an=34,morro=12,cabX=18,cabW=20, volquete=true }},
        // Lo que faltaba por la calle: dos ruedas, los bomberos, la grúa municipal, el
        // microbús de barrio y el furgón de la Ertzaintza.
        {"moto",       new Chasis{ l=28,an=10,morro=4,cabX=10,cabW=7, moto=true }},
        {"bomberos",   new Chasis{ l=104,an=34,morro=10,cabX=19,cabW=25, cajaX=46,cajaW=50, rotativo=true, escalera=true }},
        {"grua",       new Chasis{ l=86,an=30,morro=10,cabX=16,cabW=20, cajaX=37,cajaW=31, brazo=true }},
        {"microbus",   new Chasis{ l=92,an=30,morro=9,cabX=13,cabW=70, bus=true }},
        {"furgonPoli", new Chasis{ l=72,an=26,morro=8,cabX=13,cabW=13, cajaX=26,cajaW=39, rotativo=true, rejilla=true }},
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
        // La moto no es un coche estrecho: no tiene morro, ni cabina, ni cuatro ruedas.
        if (K.moto) {
            L.P(ox+2, oy+2, l-4, an-4, Paleta.Negro);
            L.P(ox+3, oy+3, l-6, an-6, baseC); L.P(ox+3, oy+3, l-6, 1, cl);
            L.P(ox+l-9, oy+3, 4, an-6, osc);
            L.P(ox+1, oy+an/2-3, 6, 6, Paleta.Carbon); L.P(ox+l-7, oy+an/2-3, 6, 6, Paleta.Carbon);
            L.P(ox+9, oy+1, 7, an-2, Paleta.Carbon);          // el que va encima
            L.P(ox+10, oy+2, 5, 3, Paleta.Piel2);
            L.P(ox+l-5, oy+an/2-2, 3, 3, Paleta.H("#e8dfa8"));
            return L;
        }
        L.P(ox, oy+1, l, an-2, Paleta.Negro);
        L.P(ox+1, oy+1, l-2, an-2, baseC);
        // Los remates iban en píxeles absolutos —faros de 3, ruedas de 6, ventanillas de
        // 3— y con la escala vieja colaban. Sobre un autobús de 156 px se quedan de
        // juguete, así que van al doble: una rueda mide 0,65 m de verdad, que a x2,1 son
        // 8 px, no 3. Y un faro es 60x25 cm: una tira, no un cuadrado.
        L.P(ox+1, oy+1, l-2, 3, cl);
        L.P(ox+1, oy+an-4, l-2, 3, osc);
        L.P(ox+2, oy+3, K.morro, an-6, cl);
        L.P(ox+K.cabX, oy+3, K.cabW, an-6, Paleta.Carbon);
        L.P(ox+K.cabX+2, oy+5, 5, an-10, Paleta.H("#3f5566"));
        L.P(ox+K.cabX+K.cabW-6, oy+5, 4, an-10, Paleta.H("#31424f"));
        if (K.cajaW > 0) { L.P(ox+K.cajaX, oy+2, K.cajaW, an-4, cl); L.P(ox+K.cajaX+2, oy+4, K.cajaW-4, an-8, baseC); }
        if (K.bus) for (int i = 16; i < l-12; i += 15) L.P(ox+i, oy+3, 9, 3, Paleta.H("#3f5566"));
        if (K.volquete) L.P(ox+K.cabX+K.cabW, oy+2, l-K.cabX-K.cabW-2, an-4, Paleta.MostazaO);
        L.P(ox+l-6, oy+4, 4, 3, Paleta.H("#e8dfa8"));
        L.P(ox+l-6, oy+an-7, 4, 3, Paleta.H("#e8dfa8"));
        L.P(ox+2, oy+4, 3, 3, Paleta.Crema);
        L.P(ox+2, oy+an-7, 3, 3, Paleta.Crema);
        int rw = K.alto ? 6 : 5;
        L.P(ox+8, oy-2, 10, rw, Paleta.Negro); L.P(ox+l-18, oy-2, 10, rw, Paleta.Negro);
        L.P(ox+8, oy+an-3, 10, rw, Paleta.Negro); L.P(ox+l-18, oy+an-3, 10, rw, Paleta.Negro);
        if (K.taxi) {
            L.P(ox+K.cabX+4, oy-2, 10, 5, Paleta.Mostaza);
            for (int i = 0; i < l-14; i += 8) L.P(ox+4+i, oy+an/2-2, 4, 4, Paleta.Carbon);
        }
        if (K.rotativo) {
            L.P(ox+K.cabX, oy+1, 5, an-2, estado == "rotA" ? Paleta.H("#2f6bff") : Paleta.Gris);
            L.P(ox+K.cabX+5, oy+1, 5, an-2, estado == "rotA" ? Paleta.Gris : Paleta.H("#ff3b30"));
        }
        // La cruz, centrada en la caja y no a dieciocho píxeles del morro: con la
        // ambulancia a 72 px, ese dieciocho la dejaba montada sobre la cabina.
        if (K.cruz) { L.P(ox+l/2-9, oy+an/2-2, 18, 4, Paleta.Rojo); L.P(ox+l/2-2, oy+an/2-9, 4, 18, Paleta.Rojo); }
        if (K.escalera) {
            L.P(ox+K.cajaX+2, oy+an/2-7, K.cajaW-4, 14, Paleta.GrisO);
            for (int i = 3; i < K.cajaW-5; i += 7) L.P(ox+K.cajaX+i, oy+an/2-7, 3, 14, Paleta.Acero);
        }
        if (K.brazo) {
            L.P(ox+K.cajaX+K.cajaW-3, oy+an/2-4, l-K.cajaX-K.cajaW, 8, Paleta.MostazaO);
            L.P(ox+l-10, oy+an/2-7, 7, 14, Paleta.Carbon);
            L.P(ox+K.cajaX, oy+2, 7, an-4, Paleta.Mostaza);
        }
        if (K.rejilla)
            for (int i = 2; i < K.cajaW-2; i += 6) L.P(ox+K.cajaX+i, oy+4, 2, an-8, Paleta.GrisO);
        if (estado == "quemado")
            for (int i = 0; i < 22; i++) L.P(ox+3+((i*9)%(l-6)), oy+3+((i*5)%(an-6)), 3, 3, Paleta.H("#1a1714"));
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
    /// <summary>Lo que mide cada pieza de mobiliario, en metros. Estaba dibujado a ojo: una
    /// papelera de 1,9 m de ancho, un bolardo más gordo que una farola, un contenedor de barco
    /// de cuatro metros y árboles de dos. Cada pieza sale de su medida real y se forja a
    /// 20 px/m —la densidad a la que está dibujada la gente, que es con lo que se compara en
    /// la calle—; lo que pasa de cuatro metros de alto se recorta ahí, que una farola de nueve
    /// tapa media manzana.</summary>
    public static readonly Dictionary<string, float[]> MedidasMob = new Dictionary<string, float[]> {
        {"deposito", new[]{2.0f,2.2f}}, {"climatizador", new[]{1.2f,1.0f}},
        {"antenaTv", new[]{1.2f,2.4f}}, {"tendedero", new[]{3.0f,1.4f}},
        {"caseta", new[]{2.4f,2.4f}},   {"chimenea", new[]{0.8f,1.6f}},
        {"lucernario", new[]{2.4f,1.6f}}, {"farola", new[]{1.0f,4.0f}},
        {"semaforo", new[]{0.9f,3.4f}}, {"arbol", new[]{5.0f,5.6f}},
        {"arbolPodado", new[]{3.4f,3.8f}}, {"contenedor", new[]{1.4f,1.4f}},
        {"contenedor2", new[]{1.4f,1.4f}}, {"papelera", new[]{0.5f,1.0f}},
        {"banco", new[]{1.8f,1.0f}},    {"marquesina", new[]{4.0f,2.6f}},
        {"cabina", new[]{1.0f,2.4f}},   {"bolardo", new[]{0.3f,0.9f}},
        {"valla", new[]{2.5f,1.2f}},    {"andamio", new[]{3.0f,6.0f}},
        {"pales", new[]{1.2f,1.0f}},    {"cono", new[]{0.4f,0.7f}},
        {"grua", new[]{8.0f,12.0f}},    {"contMaritimo", new[]{12.0f,2.6f}},
        {"bidon", new[]{0.6f,0.9f}},    {"toldo", new[]{3.0f,1.2f}},
        {"terraza", new[]{1.6f,1.4f}},  {"placa", new[]{0.9f,0.4f}},
        // Atrezzo. Cada medida es la de verdad, tomada de lo que hay en la calle: un buzón
        // de Correos son 50 cm de frente, una señal se lee a 2,20 del suelo, un iglú de
        // vidrio tiene metro y medio y un contenedor de barco apilado de dos son 5,20 de
        // alto.
        {"buzon", new[]{0.5f,1.2f}},     {"parquimetro", new[]{0.4f,1.5f}},
        {"senal", new[]{0.6f,2.2f}},     {"hidrante", new[]{0.4f,0.9f}},
        {"jardinera", new[]{1.2f,0.9f}}, {"seto", new[]{1.8f,1.1f}},
        {"bici", new[]{1.7f,1.1f}},      {"moto", new[]{2.0f,1.2f}},
        {"aparcabicis", new[]{2.2f,0.9f}}, {"contVidrio", new[]{1.5f,1.6f}},
        {"contPapel", new[]{1.4f,1.5f}}, {"bocaMetro", new[]{3.0f,2.4f}},
        {"farolaCasco", new[]{1.2f,3.6f}}, {"quiosco", new[]{2.4f,2.8f}},
        {"fuente", new[]{2.6f,1.4f}},    {"estatua", new[]{1.4f,3.2f}},
        {"reloj", new[]{0.7f,3.6f}},     {"noray", new[]{0.5f,0.6f}},
        {"pilaCont", new[]{12.0f,5.2f}}, {"trastos", new[]{1.6f,1.0f}},
        {"columpio", new[]{2.4f,2.2f}},  {"tobogan", new[]{2.6f,2.0f}},
        {"arenero", new[]{3.0f,0.4f}},   {"porteria", new[]{3.2f,2.0f}},
        {"fuenteBeber", new[]{0.4f,1.0f}}, {"hormigonera", new[]{2.0f,2.4f}},
        {"escombros", new[]{2.0f,0.8f}}, {"contObra", new[]{6.0f,2.6f}},
    };

    /// <summary>Lo que lleva canto negro: lo que se apoya en el suelo y se ve contra él. Sobre
    /// el asfalto o el adoquín, un objeto sin contorno se funde con el fondo.</summary>
    public static readonly string[] MobContorno = {
        "farola","semaforo","arbol","arbolPodado","contenedor","contenedor2","papelera","banco",
        "marquesina","cabina","bolardo","valla","andamio","pales","cono","grua","contMaritimo",
        "bidon","terraza","deposito","climatizador","antenaTv","tendedero","caseta","chimenea",
        "lucernario",
        "buzon","parquimetro","senal","hidrante","jardinera","seto","bici","moto","aparcabicis",
        "contVidrio","contPapel","bocaMetro","farolaCasco","quiosco","fuente","estatua","reloj",
        "noray","pilaCont","trastos","columpio","tobogan","arenero","porteria","fuenteBeber",
        "hormigonera","escombros","contObra" };

    /// <summary>El sprite de una pieza de mobiliario, con canto negro si le toca.</summary>
    static Sprite SpriteMob(string k, Lienzo L) {
        if (System.Array.IndexOf(MobContorno, k) >= 0) L.Contorno(Paleta.Negro);
        return SpriteBase(L);
    }

    public static void GenerarProps() {
        if (Props.Count > 0) return;
        Lienzo L;
        // 10 y no 20 porque el tile del mundo va al doble: la cuenta es metros × 20 px.
        System.Func<string, Lienzo> Mob = k => {
            var m = MedidasMob[k];
            return new Lienzo(Mathf.RoundToInt(m[0]*10), Mathf.RoundToInt(m[1]*10));
        };

        L = Mob("farola"); L.P(4,4,2,36,Paleta.AsfaltoL); L.P(3,39,4,1,Paleta.Carbon);
        L.P(4,3,5,2,Paleta.AsfaltoL); L.P(7,4,3,3,Paleta.Gris); L.P(8,5,2,2,Paleta.H("#f2e2a8"));
        Props["farola"] = SpriteMob("farola", L);

        // Lo que hay encima de un tejado. Va suelto y sembrado por hash, como el mobiliario
        // de la acera: dibujado dentro del tile se repetiría en cada casilla del edificio y
        // la azotea parecería papel pintado.
        L = Mob("deposito"); L.P(2,4,16,16,Paleta.H("#7f9aa8")); L.P(2,4,16,3,Paleta.H("#a8c4d0"));
        L.P(17,4,2,16,Paleta.AceroO); L.P(3,20,3,2,Paleta.Carbon); L.P(14,20,3,2,Paleta.Carbon);
        L.P(6,1,8,3,Paleta.Acero); Props["deposito"] = SpriteMob("deposito", L);
        L = Mob("climatizador"); L.P(0,1,12,9,Paleta.Acero); L.P(0,1,12,2,Paleta.Hueso);
        L.P(11,1,1,9,Paleta.AceroO); L.P(2,3,8,5,Paleta.AceroO);
        for (int i = 3; i < 10; i += 2) L.P(i,3,1,5,Paleta.Acero);
        Props["climatizador"] = SpriteMob("climatizador", L);
        L = Mob("antenaTv"); L.P(5,8,2,16,Paleta.AceroO);
        for (int y = 2; y < 12; y += 3) { L.P(1,y,10,1,Paleta.Acero); L.P(6,y,1,3,Paleta.Acero); }
        Props["antenaTv"] = SpriteMob("antenaTv", L);
        L = Mob("tendedero"); L.P(1,2,1,12,Paleta.AceroO); L.P(28,2,1,12,Paleta.AceroO);
        L.P(1,3,28,1,Paleta.Acero); L.P(1,8,28,1,Paleta.Acero);
        var trapos = new[]{Paleta.Rojo,Paleta.Hueso,Paleta.Azul,Paleta.Mostaza,Paleta.VerdeL};
        for (int i = 0; i < 5; i++) L.P(3+i*5,4,4,4,trapos[i]);
        Props["tendedero"] = SpriteMob("tendedero", L);
        L = Mob("caseta"); L.P(1,2,22,22,Paleta.Hormigon); L.P(1,2,22,3,Paleta.HormigonL);
        L.P(22,2,1,22,Paleta.HormigonO); L.P(9,12,6,12,Paleta.MaderaO); L.P(13,17,1,2,Paleta.Mostaza);
        Props["caseta"] = SpriteMob("caseta", L);
        L = Mob("chimenea"); L.P(1,3,6,13,Paleta.TejaO); L.P(1,3,6,2,Paleta.Teja);
        L.P(6,3,1,13,Paleta.H("#4d3728")); L.P(0,1,8,3,Paleta.HormigonO); L.P(0,1,8,1,Paleta.HormigonL);
        Props["chimenea"] = SpriteMob("chimenea", L);
        L = Mob("lucernario"); L.P(1,1,22,14,Paleta.AceroO); L.P(3,3,18,10,Paleta.H("#a8c4d0"));
        for (int i = 6; i < 21; i += 5) L.P(i,3,1,10,Paleta.AceroO);
        Props["lucernario"] = SpriteMob("lucernario", L);

        // Las fachadas. La vista es cenital escorada, así que el canto sur de cada manzana
        // es lo único que se ve de la calle a pie de obra: estaba liso, una ciudad entera
        // de paredes ciegas con cincuenta y seis sitios y ni un escaparate más.
        // Cada local mide lo que mide de verdad. Iban todos a 16 px —2,58 m, el ancho de un
        // portal— y por eso un utilitario ocupaba dos escaparates: un escaparate de Bilbao
        // mide cuatro o cinco metros, no dos y medio. Medio local (16 px = 2,58 m) para
        // portal, portal de piedra y garaje; entero (32 px = 5,16 m) para el resto.
        Lienzo Fach(int w, System.Action<Lienzo,int> fn, Color32 col) {
            var f = new Lienzo(w,13);
            f.P(0,0,w,13,Paleta.Negro); f.P(1,1,w-2,12,col);
            fn(f,w); return f;
        }
        L = Fach(16, (f,w) => { f.P(4,3,w-8,10,Paleta.Madera); f.P(4,3,w-8,1,Paleta.MaderaL);
                        f.P(w-6,8,2,2,Paleta.MostazaO); f.P(2,1,w-4,1,Paleta.HormigonL); }, Paleta.MaderaO);
        Props["fachPortal"] = SpriteBase(L);
        L = Fach(16, (f,w) => { f.P(3,2,w-6,11,Paleta.Carbon); f.P(4,3,w-8,10,Paleta.MaderaO);
                        f.P(2,1,w-4,2,Paleta.HormigonL); f.P(w-5,8,1,2,Paleta.Mostaza); }, Paleta.HormigonO);
        Props["fachPortalPiedra"] = SpriteBase(L);
        L = Fach(32, (f,w) => { f.P(2,4,w-4,9,Paleta.H("#3f5566")); f.P(3,5,w-6,4,Paleta.H("#7f9aa8"));
                        f.P(w/2-1,4,2,9,Paleta.HormigonO);   // el montante que parte el cristal
                        f.P(2,2,w-4,2,Paleta.RojoO);
                        for (int i = 2; i < w-2; i += 3) f.P(i,2,2,2,Paleta.Crema); }, Paleta.HormigonO);
        Props["fachEscaparate"] = SpriteBase(L);
        L = Fach(32, (f,w) => { f.P(2,5,w-4,8,Paleta.Carbon); f.P(3,6,w-8,3,Paleta.H("#e8dfa8"));
                        f.P(w-6,6,3,7,Paleta.MaderaO);       // la puerta, a un lado del ventanal
                        f.P(2,2,w-4,3,Paleta.VerdeO); f.P(2,2,w-4,1,Paleta.VerdeL); }, Paleta.MaderaO);
        Props["fachTasca"] = SpriteBase(L);
        L = Fach(32, (f,w) => { for (int y = 2; y < 13; y += 2) f.P(2,y,w-4,1,Paleta.Gris);
                        f.P(2,2,w-4,1,Paleta.GrisL); f.P(w/2-2,7,4,1,Paleta.MostazaO); }, Paleta.GrisO);
        Props["fachPersiana"] = SpriteBase(L);
        L = Fach(16, (f,w) => { for (int y = 3; y < 13; y += 3) f.P(1,y,w-2,2,Paleta.Acero);
                        f.P(1,1,w-2,2,Paleta.HormigonO); }, Paleta.AceroO);
        Props["fachGaraje"] = SpriteBase(L);
        L = Fach(32, (f,w) => { f.P(1,2,w-2,11,Paleta.AceroO);
                        for (int x = 2; x < w-1; x += 4) f.P(x,2,1,11,Paleta.Acero);
                        f.P(1,1,w-2,1,Paleta.HormigonL); }, Paleta.GrisO);
        Props["fachPorton"] = SpriteBase(L);
        L = Fach(32, (f,w) => { f.P(2,2,w-4,3,Paleta.Hormigon);
                        foreach (int vx in new[]{ w/4-3, w-w/4-3 }) {
                            f.P(vx,7,6,5,Paleta.Carbon); f.P(vx+1,8,4,3,Paleta.H("#3f5566")); } }, Paleta.HormigonO);
        Props["fachCiega"] = SpriteBase(L);

        L = Mob("semaforo"); L.P(4,12,2,22,Paleta.Carbon); L.P(3,33,4,1,Paleta.Carbon);
        L.P(2,1,6,12,Paleta.GrisO); L.P(3,2,4,3,Paleta.Rojo); L.P(3,6,4,3,Paleta.Mostaza);
        L.P(3,10,4,2,Paleta.VerdeL); Props["semaforo"] = SpriteMob("semaforo", L);
        // Un plátano de sombra de la Gran Vía: cinco metros de copa. El de antes medía dos y
        // parecía un arbusto al lado de un coche de cuatro.
        L = Mob("arbol"); L.P(22,38,6,18,Paleta.H("#4a3524")); L.P(9,6,32,30,Paleta.H("#2e5b2c"));
        L.P(14,2,22,7,Paleta.H("#3a7038")); L.P(4,14,42,14,Paleta.H("#356b33"));
        L.P(16,10,16,9,Paleta.H("#4a8746")); Props["arbol"] = SpriteMob("arbol", L);
        L = Mob("arbolPodado"); L.P(15,24,4,14,Paleta.H("#4a3524")); L.P(5,4,24,22,Paleta.H("#356b33"));
        L.P(10,1,14,6,Paleta.H("#4a8746")); L.P(3,12,28,8,Paleta.H("#2e5b2c"));
        Props["arbolPodado"] = SpriteMob("arbolPodado", L);
        L = Mob("contenedor"); L.P(0,2,14,12,Paleta.H("#2f6b4a")); L.P(1,3,12,4,Paleta.H("#3d8a60"));
        L.P(0,0,14,3,Paleta.H("#22503a")); L.P(1,13,2,1,Paleta.Carbon); L.P(11,13,2,1,Paleta.Carbon);
        Props["contenedor"] = SpriteMob("contenedor", L);
        L = Mob("contenedor2"); L.P(0,2,14,12,Paleta.MostazaO); L.P(1,3,12,4,Paleta.Mostaza);
        L.P(0,0,14,3,Paleta.H("#8c7420")); L.P(1,13,2,1,Paleta.Carbon); L.P(11,13,2,1,Paleta.Carbon);
        Props["contenedor2"] = SpriteMob("contenedor2", L);
        L = Mob("papelera"); L.P(1,3,3,7,Paleta.GrisO); L.P(0,2,5,2,Paleta.Gris);
        L.P(2,7,1,3,Paleta.Carbon); Props["papelera"] = SpriteMob("papelera", L);
        L = Mob("banco"); L.P(0,1,18,6,Paleta.Madera); L.P(0,1,18,2,Paleta.MaderaL);
        L.P(2,7,2,3,Paleta.Carbon); L.P(14,7,2,3,Paleta.Carbon); Props["banco"] = SpriteMob("banco", L);
        L = Mob("marquesina"); L.P(0,0,40,4,Paleta.GrisO); L.P(1,4,2,22,Paleta.Gris);
        L.P(37,4,2,22,Paleta.Gris); L.P(3,5,34,14,Paleta.H("#7f9aa8")); L.P(5,20,30,3,Paleta.Madera);
        Props["marquesina"] = SpriteMob("marquesina", L);
        L = Mob("cabina"); L.P(0,0,10,24,Paleta.RojoO); L.P(2,3,6,14,Paleta.H("#7f9aa8"));
        L.P(0,0,10,3,Paleta.Rojo); Props["cabina"] = SpriteMob("cabina", L);
        L = Mob("bolardo"); L.P(0,1,3,8,Paleta.Carbon); L.P(0,0,3,2,Paleta.Mostaza);
        Props["bolardo"] = SpriteMob("bolardo", L);
        L = Mob("valla"); L.P(0,1,25,4,Paleta.Mostaza); L.P(0,6,25,4,Paleta.Rojo);
        L.P(1,10,3,2,Paleta.Carbon); L.P(21,10,3,2,Paleta.Carbon); Props["valla"] = SpriteMob("valla", L);
        L = Mob("andamio");
        for (int x = 0; x < 30; x += 9) L.P(x,0,2,60,Paleta.Acero);
        for (int y = 2; y < 60; y += 14) L.P(0,y,30,2,Paleta.AceroO);
        L.P(0,30,30,2,Paleta.Madera); Props["andamio"] = SpriteMob("andamio", L);
        L = Mob("pales"); L.P(0,2,12,8,Paleta.Madera);
        for (int x = 1; x < 11; x += 3) L.P(x,2,2,8,Paleta.MaderaL);
        L.P(0,1,12,2,Paleta.MaderaO); Props["pales"] = SpriteMob("pales", L);
        L = Mob("cono"); L.P(1,1,2,5,Paleta.Rojo); L.P(1,3,2,1,Paleta.Crema);
        L.P(0,6,4,1,Paleta.RojoO); Props["cono"] = SpriteMob("cono", L);
        // La grúa del muelle: doce metros de alto, no cuatro. Es lo que se ve desde el otro
        // lado de la ría y lo que dice que eso es un puerto.
        L = Mob("grua"); L.P(20,84,40,36,Paleta.Rojo); L.P(30,12,8,108,Paleta.Crema);
        L.P(4,10,72,6,Paleta.Crema); L.P(66,16,3,44,Paleta.Acero); L.P(60,58,16,8,Paleta.Mostaza);
        L.P(24,116,10,4,Paleta.Carbon); L.P(46,116,10,4,Paleta.Carbon);
        Props["grua"] = SpriteMob("grua", L);
        // Un contenedor de barco mide doce metros: dos coches y medio en fila.
        L = Mob("contMaritimo"); L.P(0,0,120,26,Paleta.RojoO);
        for (int x = 2; x < 120; x += 5) L.P(x,2,3,22,Paleta.Rojo);
        L.P(0,0,120,3,Paleta.H("#7a2c12")); L.P(0,23,120,3,Paleta.H("#7a2c12"));
        Props["contMaritimo"] = SpriteMob("contMaritimo", L);
        L = Mob("bidon"); L.P(0,1,6,8,Paleta.AzulL); L.P(0,3,6,1,Paleta.Azul);
        L.P(0,6,6,1,Paleta.Azul); L.P(1,0,4,2,Paleta.Acero); Props["bidon"] = SpriteMob("bidon", L);
        L = Mob("toldo");
        for (int x = 0; x < 30; x += 6) { L.P(x,0,3,10,Paleta.RojoO); L.P(x+3,0,3,10,Paleta.Crema); }
        L.P(0,10,30,2,Paleta.Carbon); Props["toldo"] = SpriteMob("toldo", L);
        L = Mob("terraza"); L.P(2,2,12,9,Paleta.Crema); L.P(2,2,12,2,Paleta.Blanco);
        L.P(4,11,2,3,Paleta.Acero); L.P(10,11,2,3,Paleta.Acero); L.P(6,5,4,3,Paleta.VerdeL);
        Props["terraza"] = SpriteMob("terraza", L);
        L = Mob("placa"); L.P(0,0,9,4,Paleta.Blanco); L.P(0,0,9,1,Paleta.Azul);
        L.P(1,1,7,2,Paleta.Azul); Props["placa"] = SpriteMob("placa", L);

        // ── Atrezzo de acera ──
        L = Mob("buzon"); L.P(0,2,5,8,Paleta.MostazaO); L.P(0,2,5,2,Paleta.Mostaza);
        L.P(1,4,3,1,Paleta.Carbon); L.P(1,10,3,2,Paleta.Carbon);
        Props["buzon"] = SpriteMob("buzon", L);
        L = Mob("parquimetro"); L.P(1,7,2,8,Paleta.GrisO); L.P(0,0,4,8,Paleta.Gris);
        L.P(1,1,2,3,Paleta.Carbon); L.P(1,5,2,1,Paleta.Mostaza);
        Props["parquimetro"] = SpriteMob("parquimetro", L);
        // La señal se lee a 2,20 del suelo: el poste es casi todo el sprite.
        L = Mob("senal"); L.P(2,7,2,15,Paleta.Acero); L.P(0,0,6,7,Paleta.Rojo);
        L.P(1,2,4,3,Paleta.Blanco);
        Props["senal"] = SpriteMob("senal", L);
        L = Mob("hidrante"); L.P(1,3,2,6,Paleta.RojoO); L.P(0,1,4,3,Paleta.Rojo);
        L.P(0,5,4,1,Paleta.RojoO);
        Props["hidrante"] = SpriteMob("hidrante", L);
        L = Mob("jardinera"); L.P(0,4,12,5,Paleta.Hormigon); L.P(0,4,12,1,Paleta.HormigonL);
        L.P(1,0,10,5,Paleta.H("#356b33")); L.P(3,0,6,3,Paleta.H("#4a8746"));
        Props["jardinera"] = SpriteMob("jardinera", L);
        L = Mob("seto"); L.P(0,2,18,9,Paleta.H("#2e5b2c")); L.P(0,2,18,3,Paleta.H("#356b33"));
        for (int x = 2; x < 17; x += 5) L.P(x,3,2,2,Paleta.H("#4a8746"));
        Props["seto"] = SpriteMob("seto", L);
        // Una bici de perfil: rueda de 70 cm, cuadro y manillar.
        L = Mob("bici"); L.P(1,4,5,5,Paleta.Carbon); L.P(11,4,5,5,Paleta.Carbon);
        L.P(2,5,3,3,Paleta.GrisO); L.P(12,5,3,3,Paleta.GrisO); L.P(5,4,7,1,Paleta.Rojo);
        L.P(8,2,1,3,Paleta.Rojo); L.P(4,1,3,1,Paleta.Carbon); L.P(11,1,2,1,Paleta.Carbon);
        Props["bici"] = SpriteMob("bici", L);
        L = Mob("moto"); L.P(0,5,6,6,Paleta.Carbon); L.P(14,5,6,6,Paleta.Carbon);
        L.P(1,6,4,4,Paleta.GrisO); L.P(15,6,4,4,Paleta.GrisO); L.P(4,3,13,4,Paleta.RojoO);
        L.P(5,1,6,3,Paleta.Carbon); L.P(15,2,4,2,Paleta.Acero);
        Props["moto"] = SpriteMob("moto", L);
        // Tres arcos de acero, no una valla: en blanco y con seis barrotes parecía un
        // cierre de obra desde arriba.
        L = Mob("aparcabicis");
        for (int x = 2; x < 20; x += 8) {
            L.P(x,3,1,6,Paleta.AceroO); L.P(x+5,3,1,6,Paleta.AceroO); L.P(x,2,6,1,Paleta.Acero);
        }
        Props["aparcabicis"] = SpriteMob("aparcabicis", L);
        // Los iglús del vidrio y del papel: los de la calle, no un cubo de basura.
        L = Mob("contVidrio"); L.P(1,5,13,11,Paleta.H("#2f6b4a")); L.P(2,3,11,3,Paleta.H("#3d8a60"));
        L.P(4,1,7,3,Paleta.H("#22503a")); L.P(6,7,3,3,Paleta.Carbon);
        Props["contVidrio"] = SpriteMob("contVidrio", L);
        L = Mob("contPapel"); L.P(1,4,12,11,Paleta.Azul); L.P(2,2,10,3,Paleta.AzulL);
        L.P(4,0,6,3,Paleta.AzulO); L.P(5,6,4,2,Paleta.Carbon);
        Props["contPapel"] = SpriteMob("contPapel", L);
        // Una boca de metro: el hueco de la escalera, la barandilla y el rótulo.
        L = Mob("bocaMetro"); L.P(0,11,30,13,Paleta.Carbon); L.P(2,13,26,9,Paleta.Hormigon0);
        for (int x = 0; x < 29; x += 4) L.P(x,8,2,4,Paleta.Acero);
        L.P(10,0,10,7,Paleta.Rojo); L.P(12,2,6,3,Paleta.Blanco);
        Props["bocaMetro"] = SpriteMob("bocaMetro", L);
        // La farola de fundición del Casco: tres metros y medio, columna gorda y capitel.
        L = Mob("farolaCasco"); L.P(5,7,3,28,Paleta.Carbon); L.P(3,34,7,2,Paleta.Carbon);
        L.P(4,31,5,2,Paleta.GrisO); L.P(2,2,9,6,Paleta.GrisO); L.P(3,3,7,4,Paleta.H("#f2e2a8"));
        L.P(4,0,5,2,Paleta.Carbon);
        Props["farolaCasco"] = SpriteMob("farolaCasco", L);
        L = Mob("quiosco"); L.P(0,5,24,23,Paleta.VerdeO); L.P(0,3,24,3,Paleta.Verde);
        L.P(0,0,24,3,Paleta.RojoO); L.P(2,9,20,9,Paleta.Crema); L.P(3,10,18,7,Paleta.Hueso);
        L.P(2,20,20,6,Paleta.MaderaO); L.P(4,21,6,4,Paleta.Hueso); L.P(13,21,7,4,Paleta.Hueso);
        Props["quiosco"] = SpriteMob("quiosco", L);

        // ── Plaza ──
        L = Mob("fuente"); L.P(0,6,26,8,Paleta.Hormigon); L.P(1,7,24,5,Paleta.AguaL);
        L.P(0,6,26,2,Paleta.HormigonL); L.P(11,0,4,8,Paleta.HormigonL); L.P(9,2,8,2,Paleta.Hueso);
        Props["fuente"] = SpriteMob("fuente", L);
        L = Mob("estatua"); L.P(1,20,12,12,Paleta.HormigonO); L.P(0,18,14,3,Paleta.Hormigon);
        L.P(5,7,4,12,Paleta.AceroO); L.P(4,2,6,6,Paleta.AceroO); L.P(9,9,3,7,Paleta.AceroO);
        Props["estatua"] = SpriteMob("estatua", L);
        L = Mob("reloj"); L.P(2,7,3,29,Paleta.Carbon); L.P(1,34,5,2,Paleta.Carbon);
        L.P(0,0,7,8,Paleta.GrisO); L.P(1,1,5,6,Paleta.Crema); L.P(3,2,1,4,Paleta.Carbon);
        Props["reloj"] = SpriteMob("reloj", L);

        // ── Muelle ──
        L = Mob("noray"); L.P(1,2,3,4,Paleta.Carbon); L.P(0,0,5,3,Paleta.GrisO);
        Props["noray"] = SpriteMob("noray", L);
        L = Mob("pilaCont");
        System.Action<int, Color32, Color32> caja = (y, c, cl) => {
            L.P(0,y,120,26,c);
            for (int x = 2; x < 117; x += 5) L.P(x,y+3,3,20,cl);
            L.P(0,y,120,3,Paleta.Carbon); L.P(0,y+23,120,3,Paleta.Carbon);
        };
        caja(0,Paleta.AzulO,Paleta.Azul); caja(26,Paleta.RojoO,Paleta.Rojo);
        Props["pilaCont"] = SpriteMob("pilaCont", L);

        // ── Patio de manzana y obra ──
        L = Mob("trastos"); L.P(0,5,16,5,Paleta.MaderaO); L.P(2,1,6,5,Paleta.Acero);
        L.P(9,2,5,4,Paleta.RojoO); L.P(1,8,14,2,Paleta.Carbon);
        Props["trastos"] = SpriteMob("trastos", L);
        L = Mob("hormigonera"); L.P(2,4,14,12,Paleta.MostazaO); L.P(3,2,12,4,Paleta.Mostaza);
        L.P(0,16,20,4,Paleta.Carbon); L.P(2,20,4,4,Paleta.GrisO); L.P(14,20,4,4,Paleta.GrisO);
        Props["hormigonera"] = SpriteMob("hormigonera", L);
        L = Mob("escombros"); L.P(0,4,20,4,Paleta.HormigonO); L.P(2,2,6,3,Paleta.Hormigon);
        L.P(10,1,7,4,Paleta.Hormigon); L.P(5,3,3,2,Paleta.TejaO);
        Props["escombros"] = SpriteMob("escombros", L);
        L = Mob("contObra"); L.P(0,2,60,24,Paleta.MostazaO); L.P(0,2,60,3,Paleta.Mostaza);
        for (int x = 4; x < 57; x += 8) L.P(x,7,3,16,Paleta.H("#8c7420"));
        L.P(0,24,60,2,Paleta.Carbon);
        Props["contObra"] = SpriteMob("contObra", L);

        // ── Parque ──
        L = Mob("columpio"); L.P(1,4,2,18,Paleta.Acero); L.P(21,4,2,18,Paleta.Acero);
        L.P(0,2,24,3,Paleta.AceroO); L.P(6,5,1,10,Paleta.Carbon); L.P(17,5,1,10,Paleta.Carbon);
        L.P(4,15,5,2,Paleta.Mostaza); L.P(15,15,5,2,Paleta.Mostaza);
        Props["columpio"] = SpriteMob("columpio", L);
        L = Mob("tobogan"); L.P(0,2,10,4,Paleta.RojoO); L.P(1,6,2,14,Paleta.Acero);
        L.P(7,6,2,14,Paleta.Acero);
        for (int i = 0; i < 8; i++) L.P(10+i*2,4+i*2,4,3,Paleta.Mostaza);
        L.P(24,17,2,3,Paleta.AceroO);
        Props["tobogan"] = SpriteMob("tobogan", L);
        L = Mob("arenero"); L.P(0,0,30,4,Paleta.H("#8a7f66")); L.P(0,0,30,1,Paleta.H("#9c9078"));
        Props["arenero"] = SpriteMob("arenero", L);
        // Una portería vista desde arriba es el larguero, los dos postes y la red: la red
        // va rala y gris, que tupida se lee como una reja.
        L = Mob("porteria"); L.P(0,0,32,3,Paleta.Hueso); L.P(0,0,3,20,Paleta.Hueso);
        L.P(29,0,3,20,Paleta.Hueso);
        for (int x = 5; x < 28; x += 6) L.P(x,3,1,14,Paleta.GrisL);
        for (int y = 5; y < 18; y += 6) L.P(3,y,26,1,Paleta.GrisL);
        Props["porteria"] = SpriteMob("porteria", L);
        L = Mob("fuenteBeber"); L.P(1,3,2,7,Paleta.GrisO); L.P(0,0,4,4,Paleta.Gris);
        L.P(1,4,1,1,Paleta.AzulL);
        Props["fuenteBeber"] = SpriteMob("fuenteBeber", L);
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
                // El arma en la mano va en su propia caja de 20×26 con el mismo pivote que
                // la figura, no en la celda del personaje: el margen de la celda es para el
                // fogonazo y el puñetazo, y aquí solo descolocaría el cañón.
                var L = new Lienzo(20, 26);
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

using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;

namespace BilboCity {

/// <summary>
/// Vuelca el mapa a dos Tilemaps: uno de suelo y otro de detalle (contornos y sombras
/// de los bloques). Usa Tiles creados en memoria a partir de los sprites de la forja.
/// </summary>
public class RenderCiudad : MonoBehaviour {
    Tilemap _suelo, _detalle;
    Tile _sombraAbajo, _luzArriba;
    Tile _aguaA, _aguaB;
    float _relojAgua;

    static Tile TileDe(Sprite s) {
        var t = ScriptableObject.CreateInstance<Tile>();
        t.sprite = s;
        t.colliderType = Tile.ColliderType.None;
        return t;
    }

    static Tile TilePlano(Color32 c, int alto) {
        var L = new Lienzo(Forja.TS, alto);
        L.P(0, 0, Forja.TS, alto, c);
        var px = new Color32[L.W*L.H];
        L.VolcarEn(px, L.W, L.H, 0, 0);
        var tex = Utiles.Textura(L.W, L.H, px);
        return TileDe(Utiles.Rebanada(tex, 0, 0, L.W, L.H, 0f, 0f));
    }

    public void Construir() {
        var grid = new GameObject("Rejilla").AddComponent<Grid>();
        grid.transform.SetParent(transform, false);
        grid.cellSize = new Vector3(1,1,0);

        _suelo   = NuevoTilemap(grid.transform, "Suelo", 0);
        _detalle = NuevoTilemap(grid.transform, "Detalle", 1);

        // cache de tiles por nombre de sprite
        var T = Forja.Tiles;
        _aguaA = TileDe(T["agua0"]); _aguaB = TileDe(T["agua1"]);
        var road = TileDe(T["road"]); var roadG = TileDe(T["roadGrieta"]);
        var lineaH = TileDe(T["lineaH"]); var lineaV = TileDe(T["lineaV"]);
        var alcant = TileDe(T["alcantarilla"]);
        var cebraH = TileDe(T["cebraH"]); var cebraV = TileDe(T["cebraV"]);
        var acera = TileDe(T["acera"]); var aceraG = TileDe(T["aceraGast"]);
        var adoquin = TileDe(T["adoquin"]); var adoquinR = TileDe(T["adoquinRojo"]);
        var plaza = TileDe(T["plaza"]); var patio = TileDe(T["patio"]);
        var via = TileDe(T["via"]); var viaV = TileDe(T["viaV"]);
        var parque = TileDe(T["parque"]); var parqueA = TileDe(T["parqueAlto"]);
        var monte = TileDe(T["monte"]); var monteM = TileDe(T["monteMata"]);
        var monteR = TileDe(T["monteRoca"]);
        var puente = TileDe(T["puente"]); var muelle = TileDe(T["muelle"]);
        var camino = TileDe(T["camino"]);
        var stop = new Tile[4]; for (int i = 0; i < 4; i++) stop[i] = TileDe(T["stop"+i]);
        var aparca = new Tile[4]; for (int i = 0; i < 4; i++) aparca[i] = TileDe(T["aparca"+i]);
        var tejados = new Tile[Forja.Tejados.Length];
        for (int i = 0; i < tejados.Length; i++) tejados[i] = TileDe(Forja.Tejados[i]);

        int MW = Ciudad.MW, MH = Ciudad.MH;
        var bloque = new TileBase[MW*MH];
        // Un tile por trozo de singular. Se cachean porque el estadio son ochocientas
        // casillas y crear un Tile por cada una en el bucle grande es tirar memoria.
        var singular = new Dictionary<Sprite,Tile>();
        for (int y = 0; y < MH; y++)
            for (int x = 0; x < MW; x++) {
                var t = Ciudad.T(x,y);
                Tile elegido;
                // El estadio, la catedral, el Ayuntamiento: donde hay singular manda el
                // singular, y el tejado genérico no llega a verse.
                var trozo = Singulares.En(x,y);
                if (trozo != null) {
                    if (!singular.TryGetValue(trozo, out elegido))
                        singular[trozo] = elegido = TileDe(trozo);
                    bloque[(MH-1-y)*MW + x] = elegido;
                    continue;
                }
                switch (t) {
                    case Suelo.Edif: elegido = tejados[Ciudad.Roof[y*MW+x]]; break;
                    case Suelo.Agua: elegido = _aguaA; break;
                    case Suelo.Road: {
                        int h = Utiles.Hash(x,y);
                        char cb = Mobiliario.Cebra(x,y);
                        if (cb == 'V') { elegido = cebraV; break; }
                        if (cb == 'H') { elegido = cebraH; break; }
                        // La marca vial: línea de detención delante del paso, y si no,
                        // plaza de aparcamiento en el tramo recto pegado al bordillo.
                        int ladoStop = Mobiliario.Stop(x,y);
                        if (ladoStop >= 0) { elegido = stop[ladoStop]; break; }
                        int ladoAparca = Mobiliario.Aparca(x,y);
                        if (ladoAparca >= 0) { elegido = aparca[ladoAparca]; break; }
                        if (h % 37 == 0) elegido = alcant;
                        else if (h % 19 == 0) elegido = roadG;
                        else {
                            bool vert = Ciudad.Rodable(x,y-1) && Ciudad.Rodable(x,y+1) && !Ciudad.Rodable(x-1,y) && !Ciudad.Rodable(x+1,y);
                            bool horz = Ciudad.Rodable(x-1,y) && Ciudad.Rodable(x+1,y) && !Ciudad.Rodable(x,y-1) && !Ciudad.Rodable(x,y+1);
                            elegido = vert ? lineaV : (horz ? lineaH : road);
                        }
                        break;
                    }
                    case Suelo.Acera: {
                        var Z = Ciudad.BarrioDe(x,y);
                        if (Z.Estilo == "denso") elegido = adoquin;
                        else if (Z.Estilo == "abierto") elegido = adoquinR;
                        else elegido = Utiles.Hash(x,y) % 11 == 0 ? aceraG : acera;
                        break;
                    }
                    case Suelo.Parque: {
                        // A un parque no se entra pisando el césped: se anda por el borde
                        // que da a la calle. El tile del camino estaba forjado y sin usar.
                        bool borde = EsBordeParque(x,y,1,0) || EsBordeParque(x,y,-1,0)
                                  || EsBordeParque(x,y,0,1) || EsBordeParque(x,y,0,-1);
                        elegido = borde ? camino : (Utiles.Hash(x,y) % 4 == 0 ? parqueA : parque);
                        break;
                    }
                    case Suelo.Monte: {
                        int hm = Utiles.Hash(x,y) % 9;
                        elegido = hm == 0 ? monteR : (hm < 4 ? monteM : monte);
                        break;
                    }
                    case Suelo.Plaza:  elegido = plaza; break;
                    case Suelo.Patio:  elegido = patio; break;
                    case Suelo.Via:
                        elegido = (Ciudad.T(x-1,y) == Suelo.Via || Ciudad.T(x+1,y) == Suelo.Via) ? via : viaV;
                        break;
                    case Suelo.Puente: elegido = puente; break;
                    case Suelo.Muelle: elegido = muelle; break;
                    default: elegido = acera; break;
                }
                // la Y del mundo crece hacia abajo, la del Tilemap hacia arriba
                bloque[(MH-1-y)*MW + x] = elegido;
            }
        _suelo.SetTilesBlock(new BoundsInt(0, 0, 0, MW, MH, 1), bloque);

        // contorno y sombra proyectada de los bloques
        _sombraAbajo   = TilePlano(new Color32(0,0,0,86), Forja.TS);
        _luzArriba     = TilePlano(new Color32(255,255,255,36), Forja.TS);

        var det = new TileBase[MW*MH];
        for (int y = 0; y < MH; y++)
            for (int x = 0; x < MW; x++) {
                if (Ciudad.T(x,y) != Suelo.Edif) continue;
                bool abajo = Ciudad.T(x,y+1) != Suelo.Edif;
                bool arriba = Ciudad.T(x,y-1) != Suelo.Edif;
                if (abajo && y+1 < MH) det[(MH-1-(y+1))*MW + x] = _sombraAbajo;
                else if (arriba) det[(MH-1-y)*MW + x] = _luzArriba;
            }

        // La orilla. La ría llegaba pegada a la ciudad sin un canto, dos colores planos: un
        // río tiene borde —la espuma contra el muro— y la ciudad tiene muro —el paramento
        // en sombra y su albardilla—, que es lo que dice que del agua a la calle hay tres
        // metros de subida y no un charco. Se cachea por máscara de vecinos porque son solo
        // dieciséis combinaciones y el mapa tiene cientos de miles de casillas de ría.
        var cacheEspuma = new Dictionary<int,Tile>();
        var cacheOrilla = new Dictionary<int,Tile>();
        for (int y = 0; y < MH; y++)
            for (int x = 0; x < MW; x++) {
                var t = Ciudad.T(x,y);
                if (t == Suelo.Agua) {
                    int m = MascaraOrilla(x, y, tj => tj != Suelo.Agua && tj != Suelo.Puente);
                    if (m == 0) continue;
                    Tile tile;
                    if (!cacheEspuma.TryGetValue(m, out tile)) cacheEspuma[m] = tile = TileEspuma(m);
                    det[(MH-1-y)*MW + x] = tile;
                } else if (t != Suelo.Puente && t != Suelo.Edif) {
                    int m = MascaraOrilla(x, y, tj => tj == Suelo.Agua);
                    if (m == 0) continue;
                    Tile tile;
                    if (!cacheOrilla.TryGetValue(m, out tile)) cacheOrilla[m] = tile = TileOrilla(m);
                    det[(MH-1-y)*MW + x] = tile;
                }
            }

        _detalle.SetTilesBlock(new BoundsInt(0, 0, 0, MW, MH, 1), det);
    }

    /// <summary>Bitmask de vecinos que cumplen la condición: bit0 este, bit1 oeste,
    /// bit2 sur, bit3 norte. Lo comparten la espuma del agua y el muro de la orilla.</summary>
    static int MascaraOrilla(int x, int y, System.Func<Suelo,bool> cond) {
        int m = 0;
        if (cond(Ciudad.T(x+1,y))) m |= 1;
        if (cond(Ciudad.T(x-1,y))) m |= 2;
        if (cond(Ciudad.T(x,y+1))) m |= 4;
        if (cond(Ciudad.T(x,y-1))) m |= 8;
        return m;
    }

    static Tile TileDeLienzo(Lienzo l) {
        var px = new Color32[l.W*l.H];
        l.VolcarEn(px, l.W, l.H, 0, 0);
        var tex = Utiles.Textura(l.W, l.H, px);
        return TileDe(Utiles.Rebanada(tex, 0, 0, l.W, l.H, 0f, 0f));
    }

    /// <summary>La espuma del agua contra la orilla, del lado que da a tierra.</summary>
    static Tile TileEspuma(int mascara) {
        int ts = Forja.TS;
        var l = new Lienzo(ts, ts);
        var col = new Color32(132,160,200,89);
        if ((mascara & 1) != 0) l.P(ts-3,0,3,ts,col);
        if ((mascara & 2) != 0) l.P(0,0,3,ts,col);
        if ((mascara & 4) != 0) l.P(0,ts-3,ts,3,col);
        if ((mascara & 8) != 0) l.P(0,0,ts,3,col);
        return TileDeLienzo(l);
    }

    /// <summary>El paramento en sombra de la orilla, con su albardilla clara justo encima,
    /// del lado que da al agua.</summary>
    static Tile TileOrilla(int mascara) {
        int ts = Forja.TS;
        var l = new Lienzo(ts, ts);
        var osc = new Color32(7,9,12,115);
        var clr = new Color32(232,228,220,56);
        if ((mascara & 1) != 0) { l.P(ts-3,0,3,ts,osc); l.P(ts-4,0,1,ts,clr); }
        if ((mascara & 2) != 0) { l.P(0,0,3,ts,osc);    l.P(3,0,1,ts,clr); }
        if ((mascara & 4) != 0) { l.P(0,ts-3,ts,3,osc); l.P(0,ts-4,ts,1,clr); }
        if ((mascara & 8) != 0) { l.P(0,0,ts,3,osc);    l.P(0,3,ts,1,clr); }
        return TileDeLienzo(l);
    }

    /// <summary>Por dónde se anda en un parque: acera, plaza o calzada, y solo cuando
    /// detrás hay parque de verdad —dos casillas más, no una—. Sin la segunda condición,
    /// una mediana de dos casillas de ancho es «el borde que da a la calle» por los dos
    /// lados a la vez y el césped desaparece entero.</summary>
    static bool EsBordeParque(int x, int y, int dx, int dy) {
        var v = Ciudad.T(x+dx, y+dy);
        if (v != Suelo.Acera && v != Suelo.Plaza && v != Suelo.Road) return false;
        return Ciudad.T(x-dx, y-dy) == Suelo.Parque && Ciudad.T(x-2*dx, y-2*dy) == Suelo.Parque;
    }

    static Tilemap NuevoTilemap(Transform padre, string nombre, int orden) {
        var go = new GameObject(nombre);
        go.transform.SetParent(padre, false);
        var tm = go.AddComponent<Tilemap>();
        var tr = go.AddComponent<TilemapRenderer>();
        tr.sortingOrder = orden - 100;   // el suelo siempre por debajo de las entidades
        tr.mode = TilemapRenderer.Mode.Chunk;
        return tm;
    }

    void Update() {
        // animación del agua: se cambia el tile cada 0,38 s
        _relojAgua += Time.deltaTime;
        if (_relojAgua < 0.38f) return;
        _relojAgua = 0;
        // solo repinta el agua visible alrededor de la cámara
        var cam = Camera.main;
        if (cam == null || _suelo == null) return;
        Vector3 c = cam.transform.position;
        int cx = Mathf.RoundToInt(c.x), cy = Mathf.RoundToInt(c.y);
        int r = 22;
        var frame = (Mathf.FloorToInt(Time.time / 0.38f) % 2 == 0) ? _aguaA : _aguaB;
        for (int y = cy-r; y <= cy+r; y++)
            for (int x = cx-r; x <= cx+r; x++) {
                if (x < 0 || y < 0 || x >= Ciudad.MW || y >= Ciudad.MH) continue;
                int my = Ciudad.MH - 1 - y;
                if (Ciudad.T(x, my) == Suelo.Agua)
                    _suelo.SetTile(new Vector3Int(x, y, 0), frame);
            }
    }
}

}

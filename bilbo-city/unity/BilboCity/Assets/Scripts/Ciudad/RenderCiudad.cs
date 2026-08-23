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
        var acera = TileDe(T["acera"]); var aceraG = TileDe(T["aceraGast"]);
        var adoquin = TileDe(T["adoquin"]); var adoquinR = TileDe(T["adoquinRojo"]);
        var plaza = TileDe(T["plaza"]); var patio = TileDe(T["patio"]);
        var via = TileDe(T["via"]); var viaV = TileDe(T["viaV"]);
        var parque = TileDe(T["parque"]); var parqueA = TileDe(T["parqueAlto"]);
        var puente = TileDe(T["puente"]); var muelle = TileDe(T["muelle"]);
        var tejados = new Tile[8]; for (int i = 0; i < 8; i++) tejados[i] = TileDe(Forja.Tejados[i]);
        var azoteas = new Tile[8]; for (int i = 0; i < 8; i++) azoteas[i] = TileDe(Forja.Azoteas[i]);

        int MW = Ciudad.MW, MH = Ciudad.MH;
        var bloque = new TileBase[MW*MH];
        for (int y = 0; y < MH; y++)
            for (int x = 0; x < MW; x++) {
                var t = Ciudad.T(x,y);
                Tile elegido;
                switch (t) {
                    case Suelo.Edif: {
                        byte r = Ciudad.Roof[y*MW+x];
                        elegido = r >= 8 ? azoteas[r-8] : tejados[r];
                        break;
                    }
                    case Suelo.Agua: elegido = _aguaA; break;
                    case Suelo.Road: {
                        int h = Utiles.Hash(x,y);
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
                        var Z = Ciudad.ZonaDe(x,y);
                        if (Z.Estilo == "denso") elegido = adoquin;
                        else if (Z.Estilo == "abierto") elegido = adoquinR;
                        else elegido = Utiles.Hash(x,y) % 11 == 0 ? aceraG : acera;
                        break;
                    }
                    case Suelo.Parque: elegido = Utiles.Hash(x,y) % 4 == 0 ? parqueA : parque; break;
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
        _detalle.SetTilesBlock(new BoundsInt(0, 0, 0, MW, MH, 1), det);
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

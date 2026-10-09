using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;

namespace BilboCity {

/// <summary>
/// Vuelca el mapa a dos Tilemaps: uno de suelo y otro de detalle (contornos y sombras
/// de los bloques). Usa Tiles creados en memoria a partir de los sprites de la forja.
/// </summary>
public class RenderCiudad : MonoBehaviour {
    public static RenderCiudad I;

    Tilemap _suelo, _viario, _detalle, _tapa;
    Tile _sombraAbajo, _luzArriba;
    Tile _aguaA, _aguaB;
    float _relojAgua;
    /// Casillas del patio en el que está el jugador, y cuánto se ha ido su tapa.
    HashSet<int> _patioAbierto;
    float _patioF;

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
        I = this;
        var grid = new GameObject("Rejilla").AddComponent<Grid>();
        grid.transform.SetParent(transform, false);
        grid.cellSize = new Vector3(1,1,0);

        _suelo   = NuevoTilemap(grid.transform, "Suelo", 0);
        // El bordillo y las flechas van en su propia capa, encima del suelo y debajo de la
        // sombra de los bloques: son transparentes y no pueden ser el tile de la casilla.
        _viario  = NuevoTilemap(grid.transform, "Viario", 1);
        _detalle = NuevoTilemap(grid.transform, "Detalle", 2);

        // cache de tiles por nombre de sprite
        var T = Forja.Tiles;
        _aguaA = TileDe(T["agua0"]); _aguaB = TileDe(T["agua1"]);
        var road = TileDe(T["road"]); var roadG = TileDe(T["roadGrieta"]);
        var alcant = TileDe(T["alcantarilla"]);
        var acera = TileDe(T["acera"]); var aceraG = TileDe(T["aceraGast"]);
        var adoquin = TileDe(T["adoquin"]); var adoquinR = TileDe(T["adoquinRojo"]);
        var plaza = TileDe(T["plaza"]); var patio = TileDe(T["patio"]);
        var via = TileDe(T["via"]); var viaV = TileDe(T["viaV"]);
        var parque = TileDe(T["parque"]); var parqueA = TileDe(T["parqueAlto"]);
        var monte = TileDe(T["monte"]); var monteM = TileDe(T["monteMata"]);
        var monteR = TileDe(T["monteRoca"]);
        var puente = TileDe(T["puente"]); var muelle = TileDe(T["muelle"]);
        var tejados = new Tile[Forja.Tejados.Length];
        for (int i = 0; i < tejados.Length; i++) tejados[i] = TileDe(Forja.Tejados[i]);
        var calzada = new Tile[Forja.Calzada.Length];
        for (int i = 1; i < calzada.Length; i++) calzada[i] = TileDe(Forja.Calzada[i]);
        var bordes = new Tile[Forja.Borde.Length];
        for (int i = 1; i < bordes.Length; i++) bordes[i] = TileDe(Forja.Borde[i]);
        var flechas = new Tile[5];
        for (int i = Ciudad.SenE; i <= Ciudad.SenN; i++) flechas[i] = TileDe(Forja.FlechaVia[i]);

        int MW = Ciudad.MW, MH = Ciudad.MH;
        var bloque = new TileBase[MW*MH];
        var viario = new TileBase[MW*MH];
        // Un tile por trozo de singular. Se cachean porque el estadio son ochocientas
        // casillas y crear un Tile por cada una en el bucle grande es tirar memoria.
        var singular = new Dictionary<Sprite,Tile>();
        for (int y = 0; y < MH; y++)
            for (int x = 0; x < MW; x++) {
                var t = Ciudad.T(x,y);
                Tile elegido;
                // El viario se decide antes que el suelo y aparte de él: un singular puede
                // ocupar una acera, y el bordillo de esa acera se sigue viendo.
                if (t == Suelo.Road) {
                    // Una flecha cada tantas casillas del mismo carril. Pintarlas todas
                    // sería una alfombra; esto deja una cada ocho o nueve casillas de
                    // carril, que es más o menos lo que hay en la calle.
                    int sen = Ciudad.ViaSentido[y*MW+x];
                    if (sen != Ciudad.SenNo && Utiles.Hash(x,y) % 23 == 0)
                        viario[(MH-1-y)*MW + x] = flechas[sen];
                } else if (t == Suelo.Acera) {
                    int b = Ciudad.BordeMarca[y*MW+x];
                    if (b != 0) viario[(MH-1-y)*MW + x] = bordes[b];
                }
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
                        // La marca manda sobre el detalle: una tapa de alcantarilla en
                        // mitad de la línea continua la partiría.
                        int m = Ciudad.ViaMarca[y*MW+x];
                        if (m != 0) { elegido = calzada[m]; break; }
                        int h = Utiles.Hash(x,y);
                        if (h % 37 == 0) elegido = alcant;
                        else if (h % 19 == 0) elegido = roadG;
                        else elegido = road;
                        break;
                    }
                    case Suelo.Acera: {
                        var Z = Ciudad.BarrioDe(x,y);
                        if (Z.Estilo == "denso") elegido = adoquin;
                        else if (Z.Estilo == "abierto") elegido = adoquinR;
                        else elegido = Utiles.Hash(x,y) % 11 == 0 ? aceraG : acera;
                        break;
                    }
                    case Suelo.Parque: elegido = Utiles.Hash(x,y) % 4 == 0 ? parqueA : parque; break;
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
        _viario.SetTilesBlock(new BoundsInt(0, 0, 0, MW, MH, 1), viario);

        // contorno y sombra proyectada de los bloques
        _sombraAbajo   = TilePlano(new Color32(0,0,0,86), Forja.TS);
        _luzArriba     = TilePlano(new Color32(255,255,255,36), Forja.TS);

        var det = new TileBase[MW*MH];
        for (int y = 0; y < MH; y++)
            for (int x = 0; x < MW; x++) {
                if (Ciudad.T(x,y) != Suelo.Edif) continue;
                // El patio cuenta como bloque aquí, y no solo cuando está tapado: esta
                // capa se hornea una vez. Si el patio contara como hueco, el filo claro
                // caería sobre la casilla de edificio que lo bordea —que NO la tapa el
                // tejado del patio— y desde la calle se vería una raya de luz en mitad de
                // una manzana maciza, que es justo lo que la oclusión quiere evitar. Lo
                // que se pierde a cambio es la sombra dentro del patio al entrar; el
                // prototipo sí la tiene porque dibuja esta pasada cada fotograma.
                bool abajo = !Macizo(x,y+1), arriba = !Macizo(x,y-1);
                if (abajo && y+1 < MH) det[(MH-1-(y+1))*MW + x] = _sombraAbajo;
                else if (arriba) det[(MH-1-y)*MW + x] = _luzArriba;
            }
        _detalle.SetTilesBlock(new BoundsInt(0, 0, 0, MW, MH, 1), det);

        // La tapa del interior de manzana: el tejado del propio bloque encima del patio.
        // Va por encima del detalle para esconder lo que el bloque echa hacia dentro, y
        // se destapa casilla a casilla con el color del tile, que es lo único que un
        // Tilemap deja animar sin rehacerlo.
        _tapa = NuevoTilemap(grid.transform, "Tapa", 3);
        var tapa = new TileBase[MW*MH];
        for (int y = 0; y < MH; y++)
            for (int x = 0; x < MW; x++) {
                if (Ciudad.T(x,y) != Suelo.Patio || Ciudad.EsBoca(x,y)) continue;
                tapa[(MH-1-y)*MW + x] = tejados[Ciudad.Roof[y*MW+x]];
            }
        _tapa.SetTilesBlock(new BoundsInt(0, 0, 0, MW, MH, 1), tapa);
    }

    /// <summary>Cuánto tapa el tejado esa casilla: 1 maciza, 0 patio a la vista. Lo
    /// preguntan los sprites que puedan estar dentro, que van por encima de la tapa.</summary>
    public static float TapaDe(int x, int y) {
        if (Ciudad.T(x,y) != Suelo.Patio || Ciudad.EsBoca(x,y)) return 0;
        if (I == null || I._patioAbierto == null) return 1;
        return I._patioAbierto.Contains(y*Ciudad.MW + x) ? 1 - I._patioF : 1;
    }

    /// <summary>Para la capa de detalle: edificio o patio, que desde fuera es lo mismo.</summary>
    static bool Macizo(int x, int y) {
        var t = Ciudad.T(x,y);
        return t == Suelo.Edif || t == Suelo.Patio;
    }

    /// <summary>Destapa el patio en el que entra el jugador y lo vuelve a tapar al salir.
    /// Solo se repintan las casillas de ese patio: son treinta contadas.</summary>
    void PasoPatios() {
        var j = Juego.I != null ? Juego.I.Jug : null;
        if (j == null || _tapa == null) return;
        int px = Mathf.FloorToInt(j.Pos.x), py = Mathf.FloorToInt(j.Pos.y);
        bool dentro = Ciudad.T(px,py) == Suelo.Patio;
        int i = py*Ciudad.MW + px;
        if (dentro && (_patioAbierto == null || !_patioAbierto.Contains(i))) {
            if (_patioAbierto != null) VerDentro(false);
            _patioAbierto = Ciudad.PatioDe(px, py);
            _patioF = 0;
            VerDentro(true);
        }
        if (_patioAbierto == null) return;
        float antes = _patioF;
        _patioF = Mathf.Clamp01(_patioF + (dentro ? Time.deltaTime : -Time.deltaTime) / Ciudad.PatioSeg);
        if (Mathf.Approximately(antes, _patioF)) return;
        var c = new Color(1, 1, 1, 1 - _patioF);
        foreach (int k in _patioAbierto) {
            var pos = new Vector3Int(k % Ciudad.MW, Ciudad.MH - 1 - k / Ciudad.MW, 0);
            _tapa.SetTileFlags(pos, TileFlags.None);
            _tapa.SetColor(pos, c);
        }
        if (!dentro && _patioF <= 0) { VerDentro(false); _patioAbierto = null; }
    }

    /// <summary>Enciende o apaga lo que hay plantado dentro del patio abierto.</summary>
    void VerDentro(bool si) {
        if (_patioAbierto == null) return;
        foreach (int k in _patioAbierto) {
            GameObject go;
            if (Mobiliario.EnPatio.TryGetValue(k, out go) && go != null) go.SetActive(si);
        }
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
        PasoPatios();
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

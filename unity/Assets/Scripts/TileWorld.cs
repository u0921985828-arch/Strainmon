// Mundo top-down por tiles. Mapa original + TILESET ORIGINAL (PNGs propios en
// StreamingAssets/tiles, generados por scripts/gen-tiles.mjs; sin assets de
// terceros). Carga las texturas en runtime (Android/WebGL/desktop) con filtro
// Point y PPU 16. Fallback a color liso si faltara alguna.
using UnityEngine;
using UnityEngine.Networking;
using System.Collections;
using System.Collections.Generic;

public class TileWorld : MonoBehaviour
{
    // .=hierba ,=hierba alta(encuentro) P=camino W=agua T=árbol H=muro D=puerta F=flores
    static readonly string[] MAP = {
        "BBBBBBBBBBBBBBBBBBBB",
        "B..g......,,,......B",
        "B.HHH.....,,,.....bB",
        "B.HDH......,......bB",
        "B..P......PPPPP....B",
        "B..P......P...P.S..B",
        "B.gPggg...P...P....B",
        "B..P..b...PPPPP...sB",
        "B..P.........P...ssB",
        "B..PPPPP.HHH.P...ssB",
        "B.,,...P.HDH.P.....B",
        "B.,,...P..P..PPP...B",
        "B..b...PPPP....P...B",
        "B..g......,,,..P..rB",
        "B..r...bb.,,,..g...B",
        "BBBBBBBBBBBBBBBBBBBB",
    };
    static readonly Dictionary<char, string> TILE = new Dictionary<char, string> {
        { '.', "grass" }, { ',', "tallgrass" }, { 'P', "path" }, { 'W', "water" },
        { 'T', "tree" }, { 'H', "wall" }, { 'D', "door" }, { 'F', "flowers" },
        { 'B', "pine" }, { 'g', "grass2" }, { 'f', "fence" }, { 'S', "sign" },
        { 's', "shore" }, { 'b', "bush" }, { 'r', "rock" },
    };
    static readonly Dictionary<char, Color> FALLBACK = new Dictionary<char, Color> {
        { '.', new Color(0.56f,0.70f,0.42f) }, { ',', new Color(0.44f,0.60f,0.31f) },
        { 'P', new Color(0.79f,0.66f,0.47f) }, { 'W', new Color(0.48f,0.71f,0.78f) },
        { 'T', new Color(0.31f,0.48f,0.26f) }, { 'H', new Color(0.85f,0.78f,0.65f) },
        { 'D', new Color(0.48f,0.29f,0.17f) }, { 'F', new Color(0.80f,0.73f,0.85f) },
    };
    const string SOLID = "THWBfSsbr";

    public Vector2Int spawn = new Vector2Int(10, 7);
    int W, H;
    readonly Dictionary<string, Sprite> sprites = new Dictionary<string, Sprite>();

    public void Build()
    {
        H = MAP.Length; W = MAP[0].Length;        // dims disponibles ya (para el jugador)
        StartCoroutine(LoadAndBuild());
    }

    IEnumerator LoadAndBuild()
    {
        var names = new HashSet<string>(TILE.Values);
        foreach (var n in names) yield return LoadSprite(n);
        for (int y = 0; y < H; y++)
            for (int x = 0; x < W; x++)
            {
                char c = MAP[y][x];
                Sprite sp = (TILE.ContainsKey(c) && sprites.ContainsKey(TILE[c])) ? sprites[TILE[c]]
                          : MakeSprite(FALLBACK.ContainsKey(c) ? FALLBACK[c] : FALLBACK['.'], 16, 16);
                var go = new GameObject($"t_{x}_{y}");
                go.transform.SetParent(transform);
                go.transform.position = CellToWorld(x, y);
                go.AddComponent<SpriteRenderer>().sprite = sp;
            }
    }

    IEnumerator LoadSprite(string name)
    {
        string url = System.IO.Path.Combine(Application.streamingAssetsPath, "tiles", name + ".png");
        if (!url.Contains("://")) url = "file://" + url;      // desktop
        using (var req = UnityWebRequestTexture.GetTexture(url))
        {
            yield return req.SendWebRequest();
            if (req.result == UnityWebRequest.Result.Success)
            {
                var tex = DownloadHandlerTexture.GetContent(req);
                tex.filterMode = FilterMode.Point; tex.wrapMode = TextureWrapMode.Clamp;
                sprites[name] = Sprite.Create(tex, new Rect(0, 0, tex.width, tex.height), new Vector2(0.5f, 0.5f), tex.width);
            }
            else Debug.LogWarning($"tile '{name}' no cargó ({req.error}); uso fallback.");
        }
    }

    public bool IsSolid(int x, int y)
    {
        if (x < 0 || y < 0 || x >= W || y >= H) return true;
        return SOLID.IndexOf(MAP[y][x]) >= 0;
    }
    public bool IsEncounter(int x, int y) => (x >= 0 && y >= 0 && x < W && y < H) && MAP[y][x] == ',';

    public Vector3 CellToWorld(int x, int y) => new Vector3(x - W / 2f + 0.5f, (H / 2f) - y - 0.5f, 0);
    public Vector2Int WorldToCell(Vector3 p) => new Vector2Int(
        Mathf.RoundToInt(p.x + W / 2f - 0.5f), Mathf.RoundToInt(H / 2f - p.y - 0.5f));

    // Sprite de color liso (fallback original), point-filter.
    public static Sprite MakeSprite(Color col, int w, int h)
    {
        var tex = new Texture2D(w, h, TextureFormat.RGBA32, false) { filterMode = FilterMode.Point, wrapMode = TextureWrapMode.Clamp };
        var px = new Color[w * h];
        for (int i = 0; i < px.Length; i++) { float sh = ((i / w) % 4 == 0) ? -0.04f : 0f; px[i] = new Color(col.r + sh, col.g + sh, col.b + sh, 1f); }
        tex.SetPixels(px); tex.Apply();
        return Sprite.Create(tex, new Rect(0, 0, w, h), new Vector2(0.5f, 0.5f), w);
    }
}

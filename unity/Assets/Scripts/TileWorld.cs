// Mundo top-down por tiles. Mapa original (no reproduce ningún mundo con
// copyright). Tiles como sprites de color generados en runtime (placeholder
// original); sustituibles por un tileset propio importado a Unity.
using UnityEngine;
using System.Collections.Generic;

public class TileWorld : MonoBehaviour
{
    // Leyenda: .=hierba ,=hierba alta(encuentro) P=camino W=agua T=árbol
    //          H=edificio D=puerta F=flores  (todo arte propio/placeholder)
    static readonly string[] MAP = {
        "TTTTTTTTTTTTTTTTTTTT",
        "T..........,,,.....T",
        "T..HHH.....,,,.....T",
        "T..HHH......,......T",
        "T..HDH....PPPPP....T",
        "T....P....P...P..F.T",
        "T....P....P...P....T",
        "TFF..PPPPPP...PWWW.T",
        "T....P........PWWW.T",
        "T....P..HHH...PWWW.T",
        "T,,..P..HDH...P....T",
        "T,,..P...P....P..FFT",
        "T....PPPPPPPPPP....T",
        "T.........P........T",
        "T....,,,..P..,,,...T",
        "TTTTTTTTTTTTTTTTTTTT",
    };

    static readonly Dictionary<char, Color> COL = new Dictionary<char, Color> {
        { '.', new Color(0.725f,0.788f,0.639f) }, { ',', new Color(0.655f,0.729f,0.565f) },
        { 'P', new Color(0.847f,0.804f,0.690f) }, { 'W', new Color(0.663f,0.780f,0.812f) },
        { 'T', new Color(0.498f,0.604f,0.435f) }, { 'H', new Color(0.788f,0.718f,0.604f) },
        { 'D', new Color(0.604f,0.416f,0.290f) }, { 'F', new Color(0.804f,0.729f,0.851f) },
    };
    const string SOLID = "THW";   // caracteres que bloquean el paso

    public Vector2Int spawn = new Vector2Int(9, 13);
    int W, H;

    public void Build()
    {
        H = MAP.Length; W = MAP[0].Length;
        for (int y = 0; y < H; y++)
            for (int x = 0; x < W; x++)
            {
                char c = MAP[y][x];
                Color col = COL.ContainsKey(c) ? COL[c] : COL['.'];
                var go = new GameObject($"t_{x}_{y}");
                go.transform.SetParent(transform);
                go.transform.position = CellToWorld(x, y);
                var sr = go.AddComponent<SpriteRenderer>();
                sr.sprite = MakeSprite(col, 16, 16);
                sr.sortingOrder = 0;
            }
    }

    public bool IsSolid(int x, int y)
    {
        if (x < 0 || y < 0 || x >= W || y >= H) return true;
        return SOLID.IndexOf(MAP[y][x]) >= 0;
    }
    public bool IsEncounter(int x, int y) => (x >= 0 && y >= 0 && x < W && y < H) && MAP[y][x] == ',';

    // Rejilla -> mundo. y crece hacia abajo en el mapa, hacia arriba en el mundo.
    public Vector3 CellToWorld(int x, int y) => new Vector3(x - W / 2f + 0.5f, (H / 2f) - y - 0.5f, 0);
    public Vector2Int WorldToCell(Vector3 p) => new Vector2Int(
        Mathf.RoundToInt(p.x + W / 2f - 0.5f), Mathf.RoundToInt(H / 2f - p.y - 0.5f));

    // --- Sprite de color liso (placeholder original), point-filter (pixel) ---
    public static Sprite MakeSprite(Color c, int w, int h)
    {
        var tex = new Texture2D(w, h, TextureFormat.RGBA32, false) { filterMode = FilterMode.Point, wrapMode = TextureWrapMode.Clamp };
        var px = new Color[w * h];
        for (int i = 0; i < px.Length; i++)
        {
            // leve sombreado para dar textura, sin depender de arte externo
            int yy = i / w; float sh = (yy % 4 == 0) ? -0.04f : 0f;
            px[i] = new Color(Mathf.Clamp01(c.r + sh), Mathf.Clamp01(c.g + sh), Mathf.Clamp01(c.b + sh), 1f);
        }
        tex.SetPixels(px); tex.Apply();
        return Sprite.Create(tex, new Rect(0, 0, w, h), new Vector2(0.5f, 0.5f), Bootstrap.PPU);
    }
}

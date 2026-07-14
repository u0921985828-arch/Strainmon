// Actor animado (arte propio, PixelLab): idle 4-dir + caminar con nº de frames
// VARIABLE por dirección. Carga desde StreamingAssets/actors/<rol>/<dir>_idle.png
// y <dir>_walk_0..N.png (para hasta MAX_FR-1); se autodetecta cuántos existen.
using UnityEngine;
using UnityEngine.Networking;
using System.Collections;
using System.Collections.Generic;

public class AnimActor : MonoBehaviour
{
    public string role = "player";
    public float ppu = 88f;       // 140px/88 ~= 1.6u -> ~1.5 tiles de alto
    public float fps = 8f;
    const int MAX_FR = 8;         // tope de frames de caminar que se intentan cargar

    static readonly string[] DIRS = { "down", "up", "left", "right" };
    readonly Dictionary<string, Sprite> idle = new Dictionary<string, Sprite>();
    readonly Dictionary<string, List<Sprite>> walk = new Dictionary<string, List<Sprite>>();

    SpriteRenderer sr;
    string facing = "down";
    bool moving;
    float t;
    int frame;

    void Awake()
    {
        sr = GetComponent<SpriteRenderer>();
        if (!sr) sr = gameObject.AddComponent<SpriteRenderer>();
        sr.sortingOrder = 10;
        StartCoroutine(LoadAll());
    }

    IEnumerator LoadAll()
    {
        foreach (var d in DIRS)
        {
            string dir = d;
            yield return Load(dir + "_idle", s => idle[dir] = s);
            var list = new List<Sprite>(); walk[dir] = list;
            for (int i = 0; i < MAX_FR; i++)
                yield return Load($"{dir}_walk_{i}", s => { if (s != null) list.Add(s); });
        }
        Apply();
    }

    IEnumerator Load(string file, System.Action<Sprite> cb)
    {
        string url = System.IO.Path.Combine(Application.streamingAssetsPath, "actors", role, file + ".png");
        if (!url.Contains("://")) url = "file://" + url;
        using (var req = UnityWebRequestTexture.GetTexture(url))
        {
            yield return req.SendWebRequest();
            if (req.result == UnityWebRequest.Result.Success)
            {
                var tx = DownloadHandlerTexture.GetContent(req);
                tx.filterMode = FilterMode.Point; tx.wrapMode = TextureWrapMode.Clamp;
                cb(Sprite.Create(tx, new Rect(0, 0, tx.width, tx.height), new Vector2(0.5f, 0.15f), ppu));
            }
            else cb(null);
        }
    }

    public void SetFacing(string d) { if (System.Array.IndexOf(DIRS, d) < 0) return; facing = d; Apply(); }
    public void SetMoving(bool m) { if (m && !moving) { frame = 0; t = 0; } moving = m; Apply(); }

    void Update()
    {
        if (!moving) return;
        int n = FrameCount(facing);
        if (n <= 0) return;
        t += Time.deltaTime;
        if (t >= 1f / fps) { t = 0; frame = (frame + 1) % n; Apply(); }
    }

    int FrameCount(string dir) => (walk.ContainsKey(dir) ? walk[dir].Count : 0);

    void Apply()
    {
        if (!sr) return;
        Sprite s = null;
        int n = FrameCount(facing);
        if (moving && n > 0) s = walk[facing][frame % n];
        else if (idle.ContainsKey(facing)) s = idle[facing];
        if (s) sr.sprite = s;
    }
}

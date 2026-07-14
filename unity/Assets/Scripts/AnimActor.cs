// Actor animado con sprites 96x96 (arte propio, PixelLab): idle 4-dir + caminar
// (6 frames/dir). Carga desde StreamingAssets/actors/<rol>/<dir>_idle|walk_N.png.
using UnityEngine;
using UnityEngine.Networking;
using System.Collections;
using System.Collections.Generic;

public class AnimActor : MonoBehaviour
{
    public string role = "player";
    public float ppu = 40f;       // 96px / 40 ~= 2.4u de lienzo (personaje detallado)
    public float fps = 9f;

    static readonly string[] DIRS = { "down", "up", "left", "right" };
    readonly Dictionary<string, Sprite> idle = new Dictionary<string, Sprite>();
    readonly Dictionary<string, Sprite[]> walk = new Dictionary<string, Sprite[]>();

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
            var arr = new Sprite[6]; walk[dir] = arr;
            for (int i = 0; i < 6; i++) { int ii = i; yield return Load($"{dir}_walk_{ii}", s => arr[ii] = s); }
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
        }
    }

    public void SetFacing(string d) { if (System.Array.IndexOf(DIRS, d) < 0) return; facing = d; Apply(); }
    public void SetMoving(bool m) { if (m && !moving) { frame = 0; t = 0; } moving = m; Apply(); }

    void Update()
    {
        if (!moving) return;
        t += Time.deltaTime;
        if (t >= 1f / fps) { t = 0; frame = (frame + 1) % 6; Apply(); }
    }

    void Apply()
    {
        if (!sr) return;
        Sprite s = null;
        if (moving && walk.ContainsKey(facing) && walk[facing][frame] != null) s = walk[facing][frame];
        else if (idle.ContainsKey(facing)) s = idle[facing];
        if (s) sr.sprite = s;
    }
}

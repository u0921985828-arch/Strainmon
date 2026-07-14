// Actor con sprites 4-dir (originales, StreamingAssets/chars/<rol>_<dir>.png).
// Carga en runtime (Android/WebGL/desktop), point-filter, pivote a los pies.
using UnityEngine;
using UnityEngine.Networking;
using System.Collections;
using System.Collections.Generic;

public class Actor : MonoBehaviour
{
    public string role = "player";
    readonly Dictionary<string, Sprite> spr = new Dictionary<string, Sprite>();
    SpriteRenderer sr;
    string facing = "down";

    void Awake()
    {
        sr = GetComponent<SpriteRenderer>();
        if (!sr) sr = gameObject.AddComponent<SpriteRenderer>();
        sr.sortingOrder = 10;
        StartCoroutine(LoadAll());
    }

    IEnumerator LoadAll()
    {
        foreach (var d in new[] { "down", "up", "left", "right" }) yield return LoadOne(d);
        SetFacing(facing);
    }

    IEnumerator LoadOne(string d)
    {
        string url = System.IO.Path.Combine(Application.streamingAssetsPath, "chars", role + "_" + d + ".png");
        if (!url.Contains("://")) url = "file://" + url;
        using (var req = UnityWebRequestTexture.GetTexture(url))
        {
            yield return req.SendWebRequest();
            if (req.result == UnityWebRequest.Result.Success)
            {
                var t = DownloadHandlerTexture.GetContent(req);
                t.filterMode = FilterMode.Point; t.wrapMode = TextureWrapMode.Clamp;
                spr[d] = Sprite.Create(t, new Rect(0, 0, t.width, t.height), new Vector2(0.5f, 0.18f), Bootstrap.PPU);
            }
        }
    }

    public void SetFacing(string d)
    {
        facing = d;
        if (sr && spr.ContainsKey(d)) sr.sprite = spr[d];
    }
}

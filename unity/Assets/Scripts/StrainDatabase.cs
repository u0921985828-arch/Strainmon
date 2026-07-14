// Carga las 100 cepas (linaje cerrado) desde StreamingAssets/strains.json.
// Reutiliza el dataset del juego web. Funciona en Android y WebGL.
using UnityEngine;
using UnityEngine.Networking;
using System.Collections;

[System.Serializable]
public class Strain
{
    public string id, name, type, color;
    public int tier, altura, produccion, resina, vigor;
    public string[] parents, biomes;
}

[System.Serializable]
public class StrainList { public int count; public Strain[] strains; }

public class StrainDatabase : MonoBehaviour
{
    public static StrainDatabase Instance;
    public Strain[] Strains { get; private set; }

    void Awake() { Instance = this; StartCoroutine(Load()); }

    IEnumerator Load()
    {
        string path = System.IO.Path.Combine(Application.streamingAssetsPath, "strains.json");
        string json;
        // Android/WebGL sirven StreamingAssets por URL -> UnityWebRequest.
        if (path.Contains("://") || path.Contains(":///"))
        {
            using (var req = UnityWebRequest.Get(path))
            {
                yield return req.SendWebRequest();
                if (req.result != UnityWebRequest.Result.Success) { Debug.LogError(req.error); yield break; }
                json = req.downloadHandler.text;
            }
        }
        else json = System.IO.File.ReadAllText(path);

        var list = JsonUtility.FromJson<StrainList>(json);
        Strains = list.strains;
        Debug.Log($"StrainDatabase: {Strains.Length} cepas cargadas.");
    }

    public Strain ById(string id)
    {
        if (Strains == null) return null;
        foreach (var s in Strains) if (s.id == id) return s;
        return null;
    }

    // Cruce canónico: dos ids cuyo conjunto = parents de un nodo -> esa cepa.
    public Strain CanonicalCross(string a, string b)
    {
        if (Strains == null) return null;
        foreach (var s in Strains)
        {
            if (s.parents == null || s.parents.Length != 2) continue;
            bool m = (s.parents[0] == a && s.parents[1] == b) || (s.parents[0] == b && s.parents[1] == a);
            if (m) return s;
        }
        return null;
    }
}

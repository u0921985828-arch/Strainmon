// Estado de partida: créditos, prestigio, banco (cepas), Strain-dex (vistas),
// NPCs registrados y cola de avisos. Singleton.
using UnityEngine;
using System.Collections.Generic;

public class GameState : MonoBehaviour
{
    public static GameState Instance;

    public int credits = 300;
    public int prestige = 0;
    public readonly List<Strain> bank = new List<Strain>();
    public readonly HashSet<string> dex = new HashSet<string>();
    public readonly List<string> toasts = new List<string>();
    public readonly List<Transform> npcs = new List<Transform>();

    void Awake()
    {
        if (Instance != null) { Destroy(gameObject); return; }
        Instance = this;
    }

    public void Toast(string msg)
    {
        toasts.Add(msg);
        if (toasts.Count > 4) toasts.RemoveAt(0);
        Invoke(nameof(PopToast), 3.2f);
    }
    void PopToast() { if (toasts.Count > 0) toasts.RemoveAt(0); }

    public void Catch(Strain s)
    {
        if (s == null) return;
        bank.Add(s);
        if (dex.Add(s.id)) prestige += 2;
    }

    // Encuentro salvaje: solo landraces (tier 0) y algunas tier-1 con bioma.
    public void WildEncounter()
    {
        var db = StrainDatabase.Instance;
        if (db == null || db.Strains == null) return;
        var wild = new List<Strain>();
        foreach (var s in db.Strains)
            if (s.tier <= 1 && s.biomes != null && s.biomes.Length > 0) wild.Add(s);
        if (wild.Count == 0) return;
        var pick = wild[Random.Range(0, wild.Count)];
        Toast("¡Cepa salvaje capturada: " + pick.name + "!");
        Catch(pick);
    }
}

// Cultivo: parcelas con 5 fases (plántula->cosecha), agua y salud. Al cosechar
// devuelve clones (mismas cepas al banco) + créditos según salud.
using UnityEngine;
using System.Collections.Generic;

public class Plant
{
    public Strain strain;
    public int stage;          // 0..4
    public float growSeconds;
    public float water = 80f;  // %
    public float health = 100f;
    public bool Ready => stage >= 4;
}

public class Cultivation : MonoBehaviour
{
    public static Cultivation Instance;
    public readonly List<Plant> plots = new List<Plant>();
    public int capacity = 3;

    static readonly float[] STAGE_SEC = { 8f, 10f, 12f, 12f };   // tiempo por fase

    void Awake() { Instance = this; }

    public bool Plant(Strain s)
    {
        if (s == null || plots.Count >= capacity) return false;
        plots.Add(new Plant { strain = s });
        return true;
    }

    void Update()
    {
        float dt = Time.deltaTime;
        foreach (var p in plots)
        {
            if (p.Ready) continue;
            p.water = Mathf.Max(0, p.water - dt * 1.4f);
            if (p.water < 20f) p.health = Mathf.Max(0, p.health - dt * 1.5f);   // sed
            p.growSeconds += dt * (p.water > 20f ? 1f : 0.4f);
            if (p.stage < STAGE_SEC.Length && p.growSeconds >= STAGE_SEC[p.stage])
            { p.growSeconds = 0; p.stage++; }
        }
    }

    public void Water(int i) { if (i >= 0 && i < plots.Count) plots[i].water = 100f; }

    public void Harvest(int i)
    {
        if (i < 0 || i >= plots.Count) return;
        var p = plots[i];
        if (!p.Ready) return;
        int clones = 1 + Mathf.RoundToInt(p.health / 40f);
        int credits = 20 + Mathf.RoundToInt(p.strain.resina * 0.6f);
        var gs = GameState.Instance;
        if (gs != null)
        {
            for (int k = 0; k < clones; k++) gs.bank.Add(p.strain);
            gs.credits += credits;
            gs.Toast($"Cosecha: {clones} clones de {p.strain.name} + ₡{credits}");
        }
        plots.RemoveAt(i);
    }
}

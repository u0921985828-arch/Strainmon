// UI en IMGUI (OnGUI) para máxima compatibilidad (Android/WebGL, sin fuentes ni
// Canvas que cablear): HUD, avisos, Strain-dex (C), banco/cruce (B), cultivo (G).
using UnityEngine;
using System.Collections.Generic;

public class GameUI : MonoBehaviour
{
    enum Panel { None, Dex, Bank, Garden }
    Panel panel = Panel.None;
    Vector2 scroll;
    int selA = -1, selB = -1;   // selección de parentales para cruzar

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.C)) panel = panel == Panel.Dex ? Panel.None : Panel.Dex;
        if (Input.GetKeyDown(KeyCode.B)) panel = panel == Panel.Bank ? Panel.None : Panel.Bank;
        if (Input.GetKeyDown(KeyCode.G)) panel = panel == Panel.Garden ? Panel.None : Panel.Garden;
        if (Input.GetKeyDown(KeyCode.Escape)) panel = Panel.None;
    }

    void OnGUI()
    {
        var gs = GameState.Instance; if (gs == null) return;
        GUI.Box(new Rect(6, 6, 300, 24), $"₡ {gs.credits}   Dex {gs.dex.Count}/100   Prestigio {gs.prestige}");
        GUI.Label(new Rect(6, 32, 700, 20), "C Dex · B Banco/Cruce · G Cultivo · E hablar · WASD mover");
        for (int i = 0; i < gs.toasts.Count; i++) GUI.Label(new Rect(6, 54 + i * 20, 800, 20), gs.toasts[i]);

        if (panel == Panel.Dex) DrawDex(gs);
        else if (panel == Panel.Bank) DrawBank(gs);
        else if (panel == Panel.Garden) DrawGarden(gs);
    }

    Rect Win() => new Rect(Screen.width / 2 - 230, 40, 460, Screen.height - 100);

    void DrawDex(GameState gs)
    {
        var db = StrainDatabase.Instance;
        var r = Win(); GUI.Box(r, "STRAIN-DEX  (C cerrar)");
        GUILayout.BeginArea(new Rect(r.x + 10, r.y + 26, r.width - 20, r.height - 36));
        scroll = GUILayout.BeginScrollView(scroll);
        if (db != null && db.Strains != null)
        {
            int tier = -1;
            foreach (var s in Sorted(db.Strains))
            {
                if (s.tier != tier) { tier = s.tier; GUILayout.Space(4); GUILayout.Label($"— Nivel {tier} —"); }
                bool got = gs.dex.Contains(s.id);
                GUILayout.Label((got ? "✓ " : "· ") + s.name + "   [" + s.type + "]");
            }
        }
        GUILayout.EndScrollView(); GUILayout.EndArea();
    }

    void DrawBank(GameState gs)
    {
        var r = Win(); GUI.Box(r, "BANCO / CRUCE  (B cerrar)");
        GUILayout.BeginArea(new Rect(r.x + 10, r.y + 26, r.width - 20, r.height - 36));
        GUILayout.Label($"Parentales: A={(selA >= 0 && selA < gs.bank.Count ? gs.bank[selA].name : "-")}  B={(selB >= 0 && selB < gs.bank.Count ? gs.bank[selB].name : "-")}");
        if (selA >= 0 && selB >= 0 && selA != selB && GUILayout.Button("CRUZAR"))
        {
            var child = Genetics.Cross(gs.bank[selA], gs.bank[selB], StrainDatabase.Instance);
            if (child != null) { gs.bank.Add(child); bool n = gs.dex.Add(child.id); gs.Toast((n ? "Nodo/híbrido nuevo: " : "Obtenido: ") + child.name); selA = selB = -1; }
        }
        GUILayout.Space(6);
        scroll = GUILayout.BeginScrollView(scroll);
        for (int i = 0; i < gs.bank.Count; i++)
        {
            GUILayout.BeginHorizontal();
            GUILayout.Label(gs.bank[i].name + "  [" + gs.bank[i].type + "]", GUILayout.Width(260));
            if (GUILayout.Button("A", GUILayout.Width(30))) selA = i;
            if (GUILayout.Button("B", GUILayout.Width(30))) selB = i;
            if (GUILayout.Button("Plantar", GUILayout.Width(70)) && Cultivation.Instance != null)
            { if (Cultivation.Instance.Plant(gs.bank[i])) gs.Toast("Plantada: " + gs.bank[i].name); }
            GUILayout.EndHorizontal();
        }
        if (gs.bank.Count == 0) GUILayout.Label("Banco vacío. Captura cepas en la hierba alta.");
        GUILayout.EndScrollView(); GUILayout.EndArea();
    }

    void DrawGarden(GameState gs)
    {
        var cu = Cultivation.Instance; var r = Win(); GUI.Box(r, "INVERNADERO  (G cerrar)");
        GUILayout.BeginArea(new Rect(r.x + 10, r.y + 26, r.width - 20, r.height - 36));
        if (cu != null)
        {
            for (int i = 0; i < cu.plots.Count; i++)
            {
                var p = cu.plots[i];
                GUILayout.BeginHorizontal();
                GUILayout.Label($"{p.strain.name}  fase {p.stage + 1}/5  💧{Mathf.RoundToInt(p.water)}  ❤{Mathf.RoundToInt(p.health)}", GUILayout.Width(300));
                if (p.Ready) { if (GUILayout.Button("Cosechar", GUILayout.Width(80))) { cu.Harvest(i); break; } }
                else if (GUILayout.Button("Regar", GUILayout.Width(60))) cu.Water(i);
                GUILayout.EndHorizontal();
            }
            GUILayout.Label($"Parcelas {cu.plots.Count}/{cu.capacity}. Planta desde el Banco (B).");
        }
        GUILayout.EndArea();
    }

    static List<Strain> Sorted(Strain[] a)
    {
        var l = new List<Strain>(a);
        l.Sort((x, y) => x.tier != y.tier ? x.tier - y.tier : string.Compare(x.name, y.name));
        return l;
    }
}

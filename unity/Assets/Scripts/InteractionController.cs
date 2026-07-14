// Interacción: E/Espacio junto a un NPC -> diálogo. En el jugador.
using UnityEngine;

public class InteractionController : MonoBehaviour
{
    static readonly string[] LINES = {
        ": ¡Hola! Cruza dos parentales en el Banco (B) para descubrir nodos del árbol.",
        ": La hierba alta esconde cepas salvajes. Camina por ella.",
        ": Riega tus plantas en el Invernadero (G) o se estresan.",
    };

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.E) || Input.GetKeyDown(KeyCode.Space)) Interact();
    }

    void Interact()
    {
        var gs = GameState.Instance; if (gs == null) return;
        Transform best = null; float bd = 1.4f;
        foreach (var n in gs.npcs)
        {
            if (!n) continue;
            float d = Vector2.Distance(n.position, transform.position);
            if (d < bd) { bd = d; best = n; }
        }
        if (best != null)
        {
            string role = best.name.Replace("NPC_", "");
            gs.Toast(role + LINES[Random.Range(0, LINES.Length)]);
        }
    }
}

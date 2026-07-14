// Movimiento por rejilla, pixel-perfect (posiciones ancladas a la rejilla PPU).
// Colisión por lista blanca vía TileWorld. Encuentros al pisar hierba alta.
using UnityEngine;

public class GridMover : MonoBehaviour
{
    public TileWorld world;
    public float moveTime = 0.12f;

    Vector2Int cell;
    bool moving;
    Vector3 from, to;
    float t;
    Actor actor;

    void Start() { actor = GetComponent<Actor>(); cell = world.WorldToCell(transform.position); transform.position = Snap(transform.position); }

    void Update()
    {
        if (moving)
        {
            t += Time.deltaTime;
            float k = Mathf.Clamp01(t / moveTime);
            transform.position = Snap(Vector3.Lerp(from, to, k));
            if (k >= 1f) { moving = false; OnArrive(); }
            return;
        }

        int dx = 0, dy = 0;
        if (Key(KeyCode.A, KeyCode.LeftArrow)) dx = -1;
        else if (Key(KeyCode.D, KeyCode.RightArrow)) dx = 1;
        else if (Key(KeyCode.W, KeyCode.UpArrow)) dy = -1;   // arriba = -y en la rejilla
        else if (Key(KeyCode.S, KeyCode.DownArrow)) dy = 1;
        if (dx == 0 && dy == 0) return;

        if (actor) actor.SetFacing(dx < 0 ? "left" : dx > 0 ? "right" : dy < 0 ? "up" : "down");
        var n = new Vector2Int(cell.x + dx, cell.y + dy);
        if (world.IsSolid(n.x, n.y)) return;
        cell = n; from = transform.position; to = world.CellToWorld(n.x, n.y); moving = true; t = 0f;
    }

    void OnArrive()
    {
        if (world.IsEncounter(cell.x, cell.y) && Random.value < 0.18f && GameState.Instance != null)
            GameState.Instance.WildEncounter();
    }

    static bool Key(KeyCode a, KeyCode b) => Input.GetKey(a) || Input.GetKey(b);
    static Vector3 Snap(Vector3 v)
    {
        float p = Bootstrap.PPU;
        return new Vector3(Mathf.Round(v.x * p) / p, Mathf.Round(v.y * p) / p, v.z);
    }
}

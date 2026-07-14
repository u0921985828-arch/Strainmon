// Strainmon (Unity) — arranque por código: monta cámara pixel-perfect, mundo
// top-down, jugador y base de datos de cepas SIN necesitar escena cableada a
// mano. Añade este componente a un GameObject vacío en una escena vacía.
// Arte 100% placeholder ORIGINAL generado en runtime (sin assets de terceros).
using UnityEngine;

public class Bootstrap : MonoBehaviour
{
    public const float PPU = 16f;      // pixels-per-unit (tile 16x16)
    public const int BASE_H = 240;     // resolución vertical base -> orto size

    void Awake()
    {
        // --- Cámara ortográfica pixel-perfect ---
        var camGO = new GameObject("Main Camera");
        camGO.tag = "MainCamera";
        var cam = camGO.AddComponent<Camera>();
        cam.orthographic = true;
        cam.orthographicSize = (BASE_H / PPU) / 2f;         // 7.5 -> 15 tiles de alto
        cam.backgroundColor = new Color(0.68f, 0.72f, 0.63f); // soft
        cam.transform.position = new Vector3(0, 0, -10);
        // (Recomendado: añade el componente "Pixel Perfect Camera" del paquete 2D)

        // --- Mundo ---
        var world = new GameObject("World").AddComponent<TileWorld>();
        world.Build();

        // --- Jugador ---
        var pGO = new GameObject("Player");
        var sr = pGO.AddComponent<SpriteRenderer>();
        sr.sprite = TileWorld.MakeSprite(new Color(0.79f, 0.54f, 0.52f), 12, 14);
        sr.sortingOrder = 10;
        var mover = pGO.AddComponent<GridMover>();
        mover.world = world;
        pGO.transform.position = world.CellToWorld(world.spawn.x, world.spawn.y);

        camGO.AddComponent<CameraFollow>().target = pGO.transform;

        // --- Datos: 100 cepas (StreamingAssets/strains.json) ---
        new GameObject("StrainDatabase").AddComponent<StrainDatabase>();
    }
}

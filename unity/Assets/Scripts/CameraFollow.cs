// Cámara que sigue al jugador anclada a la rejilla de píxeles (sin sub-pixel).
using UnityEngine;

public class CameraFollow : MonoBehaviour
{
    public Transform target;

    void LateUpdate()
    {
        if (!target) return;
        float p = Bootstrap.PPU;
        float x = Mathf.Round(target.position.x * p) / p;
        float y = Mathf.Round(target.position.y * p) / p;
        transform.position = new Vector3(x, y, -10f);
    }
}

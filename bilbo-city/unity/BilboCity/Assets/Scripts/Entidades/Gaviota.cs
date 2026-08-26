using UnityEngine;

namespace BilboCity {

/// <summary>
/// Una gaviota planeando en círculo, con su sombra en el suelo. Bilbao es puerto a catorce
/// kilómetros del mar y las hay hasta en el Casco. Van por la capa de vuelo —no las tapa
/// nada, ni un edificio ni un singular— y hacen el corro sobre el agua o el muelle cuando
/// hay cerca, que es donde comen. Se reciclan alrededor del jugador como el tráfico: de
/// cerca, porque la pantalla enseña trece casillas de ancho y diez gaviotas repartidas por
/// noventa no se ven nunca.
/// </summary>
public class Gaviota : MonoBehaviour {
    // La capa de vuelo: por encima de cualquier entidad y de los edificios más altos —
    // Mundo.OrdenY no pasa de unos 7 800 en todo el mapa—, pero por debajo de los rótulos
    // de sitio (9000 en Juego.MontarMarcas), que no son cosas del mundo sino overlay.
    public const int Orden = 8000;

    public Vector2 Centro; public float Radio, Angulo, Vel, Alto, Fase;

    SpriteRenderer _sr, _srSombra;

    public void Preparar() {
        _sr = gameObject.AddComponent<SpriteRenderer>();
        _sr.sortingOrder = Orden;
        var goSombra = new GameObject("sombra");
        goSombra.transform.SetParent(transform.parent, false);
        _srSombra = goSombra.AddComponent<SpriteRenderer>();
        _srSombra.sprite = Forja.SombraGaviota;
        _srSombra.sortingOrder = Orden - 1;
        // rgba(7,9,12,.18) del prototipo: la forja deja el sprite opaco —la cuantización
        // se come todo lo que baja de media alfa— y la transparencia se aplica aquí, de
        // una vez, como tinte del renderer.
        _srSombra.color = new Color(7/255f, 9/255f, 12/255f, 0.18f);
    }

    /// <summary>Recoloca el corro alrededor de (cx,cy). Cerca, primero: busca una casilla
    /// de agua o muelle en 40 intentos para hacer el corro donde se come; si no encuentra
    /// ninguna, sobrevuela donde caiga.</summary>
    public void Reciclar(int cx, int cy) {
        int mx = cx + Utiles.RndI(-10, 10), my = cy + Utiles.RndI(-7, 7);
        for (int i = 0; i < 40; i++) {
            int x = Mathf.Clamp(cx + Utiles.RndI(-11, 11), 2, Ciudad.MW-3);
            int y = Mathf.Clamp(cy + Utiles.RndI(-8, 8), 2, Ciudad.MH-3);
            var t = Ciudad.T(x, y);
            if (t == Suelo.Agua || t == Suelo.Muelle) { mx = x; my = y; break; }
        }
        Centro = new Vector2(Mathf.Clamp(mx, 2, Ciudad.MW-3), Mathf.Clamp(my, 2, Ciudad.MH-3));
        Radio = Utiles.Rnd(2.5f, 7f);
        Angulo = Utiles.Rnd(0f, 6.283f);
        Vel = Utiles.Rnd(0.25f, 0.6f) * (Random.value < 0.5f ? 1f : -1f);
        Alto = Utiles.Rnd(6f, 16f);
        Fase = 0f;
    }

    public void Tic(float dt, Vector2 jugador) {
        Angulo += Vel * dt;
        Fase += dt;
        // La elipse del círculo va achatada en Y (×0,62): de frente y no en perfecto
        // plano, que es como se ve un vuelo circular desde una cámara casi cenital.
        var pos = new Vector2(
            Centro.x + Mathf.Cos(Angulo) * Radio,
            Centro.y + Mathf.Sin(Angulo) * Radio * 0.62f);
        if (Vector2.Distance(pos, jugador) > 19f) { Reciclar(Mathf.RoundToInt(jugador.x), Mathf.RoundToInt(jugador.y)); return; }

        _sr.sprite = Forja.SpritesGaviota[Mathf.FloorToInt(Fase * 4f) % 2];
        var so = Sol.Sombra(Alto);
        bool haySombra = so != Vector2.zero;
        _srSombra.enabled = haySombra;
        if (haySombra) _srSombra.transform.position = Mundo.AMundoPixel(pos + so);

        // El sprite se alza v.alto*2 —en píxeles de sprite, no en metros: es un efecto de
        // altura estilizado, no una perspectiva real, que si no la gaviota se saldría de
        // pantalla. La sombra, en cambio, se queda en el suelo, sin ese alzado.
        var baseMundo = Mundo.AMundoPixel(pos);
        transform.position = new Vector3(baseMundo.x, baseMundo.y + Alto / Mundo.PPU, baseMundo.z);
    }
}

}

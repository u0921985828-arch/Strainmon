using UnityEngine;

namespace BilboCity {

/// <summary>El sol y la luz de la hora.
///
/// Bilbao está a 43° N: el sol sale por el este, cruza por el sur y se pone por el oeste, así
/// que a mediodía la sombra apunta al norte —hacia arriba en pantalla— y a primera y última
/// hora se tumba y cruza la calle entera. Desde arriba, la sombra es lo único que dice cuánto
/// levanta un edificio y dónde acaba su tejado; y como sale de la hora y no de una constante,
/// además dice qué hora es sin mirar el reloj.</summary>
public static class Sol {
    public const float Amanece = 7.5f, Anochece = 21.5f;

    /// <summary>Hacia dónde cae la sombra (unitario), cuánto levanta el sol (0 a 1) y su
    /// elevación en radianes. Con el sol puesto, Elev vale 0 y no hay sombra que echar.</summary>
    public static Vector2 Direccion = new Vector2(0, -1);
    public static float Alto, Elev;

    public static void Calcular() {
        float h = Estado.I.Min / 60f;
        if (h <= Amanece || h >= Anochece) { Alto = 0; Elev = 0; return; }
        float t = (h - Amanece) / (Anochece - Amanece);
        Alto = Mathf.Sin(t * Mathf.PI);
        float az = Mathf.PI/2f + t * Mathf.PI;      // este al amanecer, sur al mediodía, oeste al ocaso
        Direccion = new Vector2(-Mathf.Sin(az), Mathf.Cos(az));   // la sombra va al contrario que el sol
        Elev = Mathf.Max(0.10f, Alto * 1.13f);      // 65° de elevación máxima, en radianes
    }

    /// <summary>Lo que proyecta un edificio, en casillas: su altura partida por la tangente de
    /// la elevación. Cuatro casillas de tope —20 m— porque al ras del horizonte la sombra sale
    /// infinita y taparía la ciudad entera.</summary>
    public static float LargoSombra(string estilo) {
        if (Elev <= 0) return 0;
        float m = estilo == "senorial" || estilo == "denso" ? 13f
                : estilo == "bloques" ? 10f
                : estilo == "industrial" ? 8f : 7f;
        return Mathf.Min(4f, m / Mathf.Tan(Elev) / 5.16f);
    }

    /// <summary>Lo que proyecta un singular, en casillas: su altura real partida por la
    /// tangente de la elevación. Veinte casillas de tope, más holgado que el de una manzana
    /// corriente, porque al ras del horizonte la sombra de una torre de verdad sale de
    /// cuatrocientos metros y taparía media ciudad. Si el id no está en la tabla, se supone
    /// 25 m —lo que mide un edificio de barrio alto, no una excepción.</summary>
    public static float LargoSombraSingular(string id) {
        if (Elev <= 0) return 0;
        float m;
        if (!Singulares.AltoSingular.TryGetValue(id, out m)) m = 25f;
        return Mathf.Min(20f, m / Mathf.Tan(Elev) / 5.16f);
    }

    /// <summary>Lo que proyecta cualquier cosa que esté de pie, en casillas: la altura
    /// partida por la tangente de la elevación. Sale de aquí para todo —persona, coche,
    /// farola y árbol— porque si la manzana proyecta a un lado y el coche al otro, la escena
    /// se rompe. Devuelve el vector de la sombra; en cero con el sol puesto.</summary>
    public static Vector2 Sombra(float altoM) {
        if (Elev <= 0) return Vector2.zero;
        float largo = Mathf.Min(4f, altoM / Mathf.Tan(Elev) / 5.16f);
        return Direccion * largo;
    }

    /// <summary>La misma sombra, pero parada donde se acaba el suelo. Desde arriba, la de una
    /// farola no puede subirse al tejado del edificio de al lado: al llegar a la fachada la
    /// sombra trepa por la pared, y en una vista cenital eso no se ve.</summary>
    public static Vector2 SombraCorta(Vector2 casilla, float altoM) {
        var so = Sombra(altoM);
        if (so == Vector2.zero) return so;
        float tope = so.magnitude;
        // El paso es de un cuarto de casilla y llega hasta la punta incluida: a medio paso una
        // sombra en diagonal se salta la esquina de la manzana, y parando antes de la punta se
        // cuela justo el último trozo, que es el que se veía encima del tejado.
        for (float d = 0.25f; d <= tope + 1e-4f; d += 0.25f) {
            int mx = Mathf.FloorToInt(casilla.x + Direccion.x * d);
            int my = Mathf.FloorToInt(casilla.y + Direccion.y * d);
            if (mx < 0 || my < 0 || mx >= Ciudad.MW || my >= Ciudad.MH) break;
            if (Ciudad.T(mx, my) == Suelo.Edif) return Direccion * Mathf.Max(0.2f, d - 0.25f);
        }
        return so;
    }

    /// <summary>La luz de la hora: noche azul, amanecer y atardecer cálidos, mediodía limpio.
    /// Antes solo había noche, y a las nueve de la mañana la ciudad se veía igual que a las
    /// tres de la tarde.</summary>
    static readonly float[][] Franjas = {
        new[]{ 0f,   8f,  14f, 38f, .56f }, new[]{ 6.2f,  8f,  14f, 38f, .56f },
        new[]{ 7.6f, 232f, 150f, 60f, .15f }, new[]{ 9.2f,  0f,   0f,  0f, 0f },
        new[]{18.4f,   0f,   0f,  0f, 0f },   new[]{20.6f, 236f, 130f, 54f, .17f },
        new[]{21.8f,   8f,  14f, 38f, .56f }, new[]{24f,     8f,  14f, 38f, .56f },
    };

    public static Color LuzAmbiente() {
        float h = Estado.I.Min / 60f;
        int i = 0;
        while (i < Franjas.Length - 2 && Franjas[i+1][0] <= h) i++;
        float[] a = Franjas[i], b = Franjas[i+1];
        float k = Mathf.Clamp01((h - a[0]) / Mathf.Max(0.0001f, b[0] - a[0]));
        return new Color(Mathf.Lerp(a[1],b[1],k)/255f, Mathf.Lerp(a[2],b[2],k)/255f,
                         Mathf.Lerp(a[3],b[3],k)/255f, Mathf.Lerp(a[4],b[4],k));
    }

    /// <summary>Cuánto oscurece la noche, para el sigilo y el tinte de dentro de los sitios.</summary>
    public static float Noche() {
        var l = LuzAmbiente();
        return l.b > 30f/255f ? l.a : 0f;
    }
}

}

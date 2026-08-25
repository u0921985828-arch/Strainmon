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

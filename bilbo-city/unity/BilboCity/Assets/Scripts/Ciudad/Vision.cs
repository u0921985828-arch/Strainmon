using UnityEngine;

namespace BilboCity {

/// <summary>
/// Ley 6 · visión, del prototipo (referencia/bilbo-city.html). Un objeto no ocupa solo
/// suelo: ocupa vista. De ahí dos topes, uno de sitio y otro de figura:
///
/// - de sitio: en una acera de dos metros y medio no cabe una grúa de doce, y una acera
///   con algo de más de cuatro metros deja de ser una acera y pasa a ser un muro
///   (<see cref="TopeAlto"/>, usado por <see cref="Mobiliario.Sembrar"/>);
/// - de figura: lo que pasa de dos metros (<see cref="AltoTapa"/>) es más alto que quien
///   anda por delante, así que puede esconderlo entero. Cuando eso pasa, al jugador se le
///   pinta la silueta encima (<see cref="TapaAlJugador"/>, usado por Jugador), que
///   perderse a uno mismo detrás de un plátano de sombra no es dificultad, es un fallo.
///
/// El HTML manda: esto es su misma cuenta, en el mismo sistema de casillas que ya usa el
/// resto del puerto (Y hacia abajo, como Ciudad.T), no en las coordenadas de Unity.
/// </summary>
public static class Vision {

    /// <summary>Lo que pasa de esta altura es más alto que quien anda por delante y puede
    /// esconderlo entero.</summary>
    public const float AltoTapa = 2.0f;

    /// <summary>Tope de altura por tipo de suelo, en metros, igual que TOPE_ALTO del HTML.
    /// Los suelos que no llevan mobiliario de pie (calzada, agua, puente, vía) no tienen
    /// tope propio: como en el HTML, faltar en la tabla nunca dispara la comprobación, así
    /// que el valor por defecto es "sin límite", no cero.</summary>
    public static float TopeAlto(Suelo t) {
        switch (t) {
            case Suelo.Acera:  return 4f;
            case Suelo.Plaza:  return 4f;
            case Suelo.Parque: return 6f;
            // El monte admite ocho metros porque ahí hay pinos de verdad; en un parque
            // urbano el arbolado está podado y no pasa de seis.
            case Suelo.Monte:  return 8f;
            case Suelo.Patio:  return 6f;
            case Suelo.Muelle: return 12f;
            case Suelo.Edif:   return 2.4f;
            default: return float.PositiveInfinity;
        }
    }

    /// <summary>Una caja en el mismo espacio de pantalla que usa el dibujo. No hace falta
    /// más que las cuatro esquinas para saber si dos cosas se pisan, y un struct propio
    /// evita depender de un Rect que en este puerto no se usa para nada más.</summary>
    public struct Caja { public float X0, Y0, X1, Y1; }

    /// <summary>Píxeles de pantalla por metro a los que se forja el mobiliario (20 px/m,
    /// la densidad de la gente) multiplicados por la sobreescala ESC=2 del HTML: el mismo
    /// producto que usa cajaProp() allí.</summary>
    const float Esc = 2f;

    /// <summary>La caja de una pieza de mobiliario, plantada por su base y centrada en su
    /// ancho — la misma cuenta que cajaProp(k,cx,cy) del HTML: semiancho a·5·ESC, alto
    /// al·10·ESC, con las medidas en metros de Forja.MedidasMob. <paramref name="baseMundo"/>
    /// va en casillas (Y hacia abajo), como el resto del mundo del juego.</summary>
    public static Caja CajaProp(string clave, Vector2 baseMundo) {
        var m = Forja.MedidasMob[clave];
        float a = m[0], al = m[1];
        float cx = baseMundo.x * Forja.TS, cy = baseMundo.y * Forja.TS;
        return new Caja {
            X0 = cx - a * 5f * Esc, X1 = cx + a * 5f * Esc,
            Y0 = cy - al * 10f * Esc, Y1 = cy
        };
    }

    /// <summary>La caja del jugador: 1,70 m a 20 px/m son 34 de alto y 17 de ancho de
    /// hombro a hombro, con la base en los pies — el mismo número que cajaJugador() del
    /// HTML. <paramref name="pies"/> va en casillas, igual que Jugador.Pos.</summary>
    public static Caja CajaFigura(Vector2 pies) {
        float px = pies.x * Forja.TS, py = pies.y * Forja.TS;
        return new Caja { X0 = px - 8.5f, X1 = px + 8.5f, Y0 = py - 34f, Y1 = py };
    }

    /// <summary>Dos cajas se pisan de verdad si el solape pasa el 35% del área de la caja
    /// del jugador. Un roce no cuenta: si con cada esquina de un banco se encendiera la
    /// silueta, parpadearía toda la calle.</summary>
    public static bool Tapa(Caja c, Caja j) {
        float w = Mathf.Min(c.X1, j.X1) - Mathf.Max(c.X0, j.X0);
        float h = Mathf.Min(c.Y1, j.Y1) - Mathf.Max(c.Y0, j.Y0);
        if (w <= 0f || h <= 0f) return false;
        return w * h >= (j.X1 - j.X0) * (j.Y1 - j.Y0) * 0.35f;
    }

    /// <summary>¿Hay algo plantado al sur del jugador que le pise la caja y pase de
    /// AltoTapa? Mira hasta cuatro casillas hacia el sur y dos a cada lado — de más lejos
    /// no llega a pisarle la caja — y para cada una repite la misma pregunta que
    /// Mobiliario.Sembrar: qué pieza tocaría esa casilla. Es la condición del bucle de
    /// dibujo del HTML (`l[0]>player.y && l[2].alto>=ALTO_TAPA && tapa(l[2],cj)`) sin cola
    /// de dibujo de por medio: aquí se pregunta directamente en vez de barrer lo pintado.</summary>
    public static bool TapaAlJugador(Vector2 posJugador) {
        var cj = CajaFigura(posJugador);
        int bx = Mathf.FloorToInt(posJugador.x), by = Mathf.FloorToInt(posJugador.y);
        for (int dy = 1; dy <= 4; dy++) {
            int y = by + dy;
            for (int dx = -2; dx <= 2; dx++) {
                int x = bx + dx;
                Mobiliario.Pieza p;
                if (!Mobiliario.Elegir(x, y, out p)) continue;
                float[] m;
                if (!Forja.MedidasMob.TryGetValue(p.Clave, out m) || m[1] < AltoTapa) continue;
                var caja = CajaProp(p.Clave, new Vector2(x + p.Dx, y + p.Dy));
                if (Tapa(caja, cj)) return true;
            }
        }
        return false;
    }
}

}

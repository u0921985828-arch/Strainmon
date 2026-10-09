using UnityEngine;

namespace BilboCity {

/// <summary>Sigilo.
///
/// Hasta aquí el juego repartía estrellas por el hecho de hacer algo, mirara quien mirara:
/// robar un coche en un descampado a las cuatro de la mañana costaba lo mismo que robarlo
/// delante de una patrulla. Ahora lo que cuenta es que te vean.
///
/// Todo cuelga de tres cosas que ya estaban: la línea de vista, hacia dónde mira cada uno
/// y el reloj. Lo demás es cono, distancia y paciencia.</summary>
public static class Sigilo {

    /// <summary>Medio ángulo del cono de visión, unos 60°.</summary>
    public const float Cono = 1.05f;
    /// <summary>Por debajo de esta fuerza de joystick se va agachado; por encima de Corre,
    /// corriendo. El joystick ya decía si andas o corres: que diga también si vas agachado
    /// es un botón menos que buscar con el pulgar.</summary>
    public const float Agacha = 0.34f, Corre = 0.82f;

    public static bool EsDeNoche() { return Estado.I.Min < 7*60 || Estado.I.Min >= 21*60; }

    /// <summary>Un coche se ve venir aunque vayas despacio; agachado se te ve la mitad;
    /// corriendo llamas la atención. De noche, todo esto a la mitad larga.</summary>
    public static float AlcanceVista() {
        var J = Juego.I;
        float r = EsDeNoche() ? 9f : 15f;
        if (J.Jug.EnCoche != null) return r * 1.3f;
        if (J.Jug.Agachado) r *= 0.5f;
        else if (J.Jug.Corriendo) r *= 1.3f;
        return r;
    }

    public static bool TeVe(Vector2 pos, float mirando, float alcance = -1f) {
        var jug = Juego.I.Jug.Pos;
        float d = Vector2.Distance(pos, jug);
        float alc = alcance < 0 ? AlcanceVista() : alcance;
        if (d > alc) return false;
        // A bocajarro no hace falta cono: te tiene encima.
        if (d > 2.2f) {
            float ang = Mathf.Atan2(jug.y - pos.y, jug.x - pos.x);
            float df = Mathf.Abs(Mathf.Repeat(ang - mirando + Mathf.PI * 3f, Mathf.PI * 2f) - Mathf.PI);
            if (df > Cono) return false;
        }
        return Combate.LineaVista(pos, jug);
    }

    public static bool TeVe(Andante a) { return TeVe(a.Pos, ForjaChar.AngDe(a.Dir8)); }
    public static bool TeVe(Rejilla r) { return TeVe(r.Pos, r.Ang); }

    /// <summary>¿Hay ahora mismo alguien que pueda declarar? La pasma y los enemigos
    /// siempre cuentan; los viandantes solo de cerca, que a cincuenta metros nadie
    /// distingue una cara.</summary>
    public static bool Testigos() {
        var J = Juego.I;
        foreach (var p in J.Patrullas) if (TeVe(p)) return true;
        foreach (var e in J.Enemigos) if (TeVe(e)) return true;
        float corto = Mathf.Min(9f, AlcanceVista());
        foreach (var q in J.Peatones)
            if (q.Huye <= 0 && TeVe(q.Pos, ForjaChar.AngDe(q.Dir8), corto)) return true;
        return false;
    }

    static float _avisoLimpio;

    /// <summary>Un delito que no ve nadie no da estrellas. Es la regla entera del sigilo.
    /// Devuelve si ha habido consecuencias.</summary>
    public static bool Delito(int n, bool avisar = false) {
        if (Testigos()) { Combate.I.Estrellas(n, Juego.I); return true; }
        if (avisar && _avisoLimpio <= 0) { _avisoLimpio = 6f; Hud.I.Aviso("NADIE TE HA VISTO"); }
        return false;
    }

    /// <summary>El ruido no ve, pero orienta: quien lo oye deja de mirar hacia donde miraba
    /// y va a mirar ahí. Es lo que convierte un disparo en un problema aunque estés a
    /// cubierto.</summary>
    public static void Ruido(Vector2 donde, float r) {
        if (r <= 0) return;
        var J = Juego.I;
        foreach (var p in J.Patrullas)
            if (Vector2.Distance(p.Pos, donde) < r) p.Sospecha = Mathf.Min(1f, p.Sospecha + 0.55f);
        foreach (var e in J.Enemigos)
            if (Vector2.Distance(e.Pos, donde) < r * 0.8f) {
                e.Sospecha = Mathf.Min(1f, e.Sospecha + 0.7f);
                e.Oido = donde; e.TieneOido = true; e.Alerta = true;
            }
        J.Asustar(donde, r * 0.45f);
    }

    /// <summary>Quien no te ha visto todavía va llenando su sospecha; quien te pierde la
    /// vacía. Al llenarse, canta.</summary>
    public static void Ojos(float dt) {
        var J = Juego.I;
        var E = Estado.I;
        float max = 0f; bool visto = false;

        foreach (var p in J.Patrullas) {
            if (TeVe(p)) {
                visto = true;
                float d = Vector2.Distance(p.Pos, J.Jug.Pos);
                p.Sospecha = Mathf.Min(1f, p.Sospecha + dt * 1.5f * (1.3f - Mathf.Clamp01(d / AlcanceVista())));
            } else p.Sospecha = Mathf.Max(0f, p.Sospecha - dt * 0.5f);
            if (p.Sospecha > max) max = p.Sospecha;
        }
        foreach (var e in J.Enemigos) {
            if (TeVe(e)) {
                visto = true;
                float d = Vector2.Distance(e.Pos, J.Jug.Pos);
                e.Sospecha = Mathf.Min(1f, e.Sospecha + dt * 1.1f * (1.3f - Mathf.Clamp01(d / AlcanceVista())));
                e.TieneOido = false;
                if (e.Sospecha >= 0.6f) e.Alerta = true;
            } else {
                e.Sospecha = Mathf.Max(0f, e.Sospecha - dt * 0.5f);
                if (e.Alerta && e.Sospecha <= 0f && !e.TieneOido) e.Alerta = false;
            }
            if (e.Sospecha > max) max = e.Sospecha;
        }
        E.Sospecha = max; E.Visto = visto;
        if (_avisoLimpio > 0) _avisoLimpio -= dt;
    }

    /// <summary>Un enemigo que no sabe que estás ahí y al que llegas por detrás cae de un
    /// golpe y sin ruido. Es el premio de haber ido despacio: si no, el sigilo solo sirve
    /// para tardar más en llegar al mismo tiroteo.</summary>
    public static bool PorDetras(Vector2 pos, float mirando) {
        var jug = Juego.I.Jug.Pos;
        float ang = Mathf.Atan2(jug.y - pos.y, jug.x - pos.x);
        return Mathf.Abs(Mathf.Repeat(ang - mirando + Mathf.PI * 3f, Mathf.PI * 2f) - Mathf.PI) > 1.85f;
    }
    public static bool PorDetras(Andante a) { return PorDetras(a.Pos, ForjaChar.AngDe(a.Dir8)); }
    public static bool Desprevenido(Enemigo e) { return !e.Alerta && e.Sospecha < 0.5f; }
}

}

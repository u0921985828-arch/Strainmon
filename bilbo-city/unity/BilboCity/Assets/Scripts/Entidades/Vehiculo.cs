using UnityEngine;

namespace BilboCity {

/// <summary>
/// Coche con velocidad y orientación separadas: agarre lateral, derrape con el botón de correr,
/// daño acumulado y explosión. Nada de físicas de Unity, todo a mano para que sea predecible.
/// </summary>
public class Vehiculo : MonoBehaviour {
    public Vector2 Pos, Vel;
    public float Ang, VMax = 11f, Dano;
    public bool Propio, Marcado, Vivo = true;
    public string Tipo = "utilitario";
    public int Librea;

    SpriteRenderer _sr;
    bool _golpe;

    public void Preparar() {
        _sr = GetComponent<SpriteRenderer>();
        if (_sr == null) _sr = gameObject.AddComponent<SpriteRenderer>();
        Ang = AngCalle(Pos);
        Refrescar();
    }

    /// <summary>Un coche aparcado mira hacia donde va la calle, no siempre al este.</summary>
    public static float AngCalle(Vector2 p) {
        int fx = Mathf.FloorToInt(p.x), fy = Mathf.FloorToInt(p.y);
        int h = 0, v = 0;
        for (int d = 1; d <= 3; d++) {
            if (Ciudad.Rodable(fx+d, fy)) h++;
            if (Ciudad.Rodable(fx-d, fy)) h++;
            if (Ciudad.Rodable(fx, fy+d)) v++;
            if (Ciudad.Rodable(fx, fy-d)) v++;
        }
        if (h == v) return Random.value < 0.5f ? 0 : Mathf.PI/2f;
        if (h > v) return Random.value < 0.5f ? 0 : Mathf.PI;
        return Random.value < 0.5f ? Mathf.PI/2f : -Mathf.PI/2f;
    }

    public void Conducir(float dt, Vector2 entrada, bool derrapar) {
        float cansado = Estado.I.Energia <= 0 ? 0.6f : 1f;
        Vector2 f = new Vector2(Mathf.Cos(Ang), Mathf.Sin(Ang));
        Vector2 r = new Vector2(-f.y, f.x);
        float vf = Vector2.Dot(Vel, f), vr = Vector2.Dot(Vel, r);

        vf += (-entrada.y) * (VMax * 1.25f) * cansado * dt;
        vf *= 1f - dt * (Mathf.Abs(entrada.y) < 0.1f ? 1.7f : 0.45f);
        vr *= Mathf.Pow(derrapar ? 0.965f : 0.86f, dt * 60f);

        float lim = derrapar ? VMax * 1.28f : VMax;
        vf = Mathf.Clamp(vf, -lim * 0.42f, lim);
        Ang += entrada.x * dt * 2.35f * Mathf.Clamp(vf / 3.2f, -1.15f, 1.15f);
        Vel = f * vf + r * vr;

        Vector2 antes = Pos;
        _golpe = Movimiento.Deslizar(ref Pos, Vel * dt, true);
        float recorrido = Vector2.Distance(Pos, antes), esperado = Vel.magnitude * dt;
        if (_golpe && esperado > 0.02f && recorrido < esperado * 0.55f) {
            float imp = Mathf.Abs(vf);
            if (imp > 3f) {
                AudioProc.I.Sfx("choque", Mathf.Clamp(imp/12f, 0.2f, 1f));
                Dano += imp * 0.035f;
                Combate.I.DanarJugador(imp * 1.2f);
                Particulas.I.Emitir(Pos, "chispa", 4);
            }
            Vel *= 0.25f;
        }
        if (Dano > 0.55f && Random.value < dt * 7f) Particulas.I.Emitir(Pos, "humo", 1);
        if (Dano >= 1f && Vivo) Combate.I.Explotar(this);
        AudioProc.I.Motor(vf, VMax);
    }

    public float VelAdelante {
        get { return Vector2.Dot(Vel, new Vector2(Mathf.Cos(Ang), Mathf.Sin(Ang))); }
    }

    public void Refrescar() {
        if (_sr == null) return;
        _sr.sprite = Vivo ? Forja.Veh[Tipo][Librea % Forja.Libreas.Length] : Forja.VehQuemado[Tipo];
    }

    void LateUpdate() {
        transform.position = Mundo.AMundoPixel(Pos);
        // el ángulo del mundo va con la Y invertida respecto a Unity
        transform.rotation = Quaternion.Euler(0, 0, -Ang * Mathf.Rad2Deg);
        if (_sr != null) _sr.sortingOrder = Mundo.OrdenY(Pos.y);
    }
}

}

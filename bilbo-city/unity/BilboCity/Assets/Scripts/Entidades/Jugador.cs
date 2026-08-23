using UnityEngine;

namespace BilboCity {

/// <summary>El protagonista: a pie con ciclo de andar y correr, o al volante.</summary>
public class Jugador : MonoBehaviour {
    public Vector2 Pos;
    public int Dir8;
    public Pose PoseAct = Pose.Quieto;
    public Vehiculo EnCoche;
    public float Cadencia, Herido, GolpeT, Anim;
    public string Arquetipo = "protagonista";

    SpriteRenderer _sr, _srArma, _srFog;
    float _fogT;
    string _fogTipo;

    public void Preparar() {
        _sr = GetComponent<SpriteRenderer>();
        if (_sr == null) _sr = gameObject.AddComponent<SpriteRenderer>();
        _sr.sortingOrder = 0;
        _srArma = Hijo("Arma", 1);
        _srFog  = Hijo("Fogonazo", 2);
    }

    SpriteRenderer Hijo(string nombre, int orden) {
        var go = new GameObject(nombre);
        go.transform.SetParent(transform, false);
        var sr = go.AddComponent<SpriteRenderer>();
        sr.sortingOrder = orden;
        return sr;
    }

    public void Fogonazo(string tipo, int d8) { _fogT = 0.07f; _fogTipo = tipo; Dir8 = d8; }

    public void Mover(float dt, Vector2 entrada, bool correr) {
        var E = Estado.I;
        float cansado = E.Energia <= 0 ? 0.6f : 1f;
        float v = (correr ? 4.7f : 2.9f) * cansado;
        float m = entrada.magnitude;
        if (m > 0.08f) {
            Vector2 d = entrada / m * Mathf.Min(1f, m) * v * dt;
            Movimiento.Deslizar(ref Pos, d, false);
            Dir8 = ForjaChar.Dir8(entrada.x, entrada.y);
            Anim += dt * (correr ? 11f : 7.5f);
            int f = Mathf.FloorToInt(Anim) % 4;
            PoseAct = correr ? (Pose)((int)Pose.Correr1 + f) : (Pose)((int)Pose.Andar1 + f);
        } else if (GolpeT <= 0) {
            var a = Armas.De(E.ArmaAct);
            PoseAct = Herido > 0 ? Pose.Herido : (a.Cuerpo ? Pose.Quieto : Pose.Apunta);
        }
    }

    void LateUpdate() {
        float dt = Time.deltaTime;
        if (Herido > 0) Herido -= dt;
        if (GolpeT > 0) GolpeT -= dt;
        if (Cadencia > 0) Cadencia -= dt;
        if (_fogT > 0) _fogT -= dt;

        transform.position = Mundo.AMundoPixel(Pos);
        bool visible = EnCoche == null;
        _sr.enabled = visible;
        _srArma.enabled = visible;
        _srFog.enabled = visible && _fogT > 0;
        if (!visible) return;

        var pose = Herido > 0 ? Pose.Herido : PoseAct;
        _sr.sprite = ForjaChar.Frame(Arquetipo, pose, Dir8);
        _sr.sortingOrder = Mundo.OrdenY(Pos.y);

        string arma = Estado.I.ArmaAct;
        if (Forja.ArmaMano.ContainsKey(arma)) {
            _srArma.sprite = Forja.ArmaMano[arma][Dir8];
            _srArma.sortingOrder = _sr.sortingOrder + 1;
        } else _srArma.sprite = null;

        if (_fogT > 0 && _fogTipo != null && Forja.Fogonazos.ContainsKey(_fogTipo)) {
            _srFog.sprite = Forja.Fogonazos[_fogTipo][Dir8];
            _srFog.sortingOrder = _sr.sortingOrder + 2;
        }
    }
}

/// <summary>Colisión por casilla con deslizamiento por ejes, igual que en el prototipo.</summary>
public static class Movimiento {
    public static bool Libre(float x, float y, bool coche) {
        if (Estado.I.EnInterior) return !Interiores.Solido(x, y);
        var t = Ciudad.T(Mathf.FloorToInt(x), Mathf.FloorToInt(y));
        if (coche) return t != Suelo.Edif && t != Suelo.Agua && t != Suelo.Parque;
        return Ciudad.Andable(t);
    }

    /// <summary>Devuelve true si ha chocado contra algo.</summary>
    public static bool Deslizar(ref Vector2 p, Vector2 d, bool coche) {
        bool golpe = false;
        if (Libre(p.x + d.x, p.y, coche)) p.x += d.x; else golpe = true;
        if (Libre(p.x, p.y + d.y, coche)) p.y += d.y; else golpe = true;
        if (!Estado.I.EnInterior) {
            p.x = Mathf.Clamp(p.x, 1, Ciudad.MW - 1);
            p.y = Mathf.Clamp(p.y, 1, Ciudad.MH - 1);
        }
        return golpe;
    }
}

/// <summary>Conversión entre coordenadas de casilla y de Unity, y orden de dibujo por Y.</summary>
public static class Mundo {
    /// <summary>Píxeles de sprite por unidad de Unity. Una casilla mide una unidad y su
    /// tile 32 px, así que este número tiene que coincidir con el de Utiles.Rebanada.</summary>
    public const float PPU = 32f;

    /// <summary>La Y de las casillas crece hacia abajo; la de Unity hacia arriba.</summary>
    public static Vector3 AMundo(Vector2 p) { return new Vector3(p.x, Ciudad.MH - p.y, 0); }

    /// <summary>Igual, pero clavado a la rejilla de píxel del sprite. Todo lo que lleve
    /// SpriteRenderer va por aquí: si un sprite cae en medio píxel, se le mueven los
    /// bordes un píxel arriba y abajo mientras anda, y el pixel art se ve hervir.</summary>
    public static Vector3 AMundoPixel(Vector2 p) {
        var v = AMundo(p);
        return new Vector3(Mathf.Round(v.x * PPU) / PPU, Mathf.Round(v.y * PPU) / PPU, v.z);
    }

    public static Vector2 ACasilla(Vector3 v) { return new Vector2(v.x, Ciudad.MH - v.y); }
    public static int OrdenY(float y) { return Mathf.RoundToInt(y * 10f); }
}

}

using System.Collections.Generic;
using UnityEngine;

namespace BilboCity {

/// <summary>Base de todo lo que anda con sprite de personaje.</summary>
public class Andante : MonoBehaviour {
    public Vector2 Pos;
    public int Dir8;
    public Pose PoseAct = Pose.Quieto;
    public float Anim, Hp = 30, Herido;
    public string Arq = "p1";
    protected SpriteRenderer Sr;

    public virtual void Preparar() {
        Sr = gameObject.AddComponent<SpriteRenderer>();
    }

    protected void CicloAndar(float dt, bool correr) {
        Anim += dt * (correr ? 11f : 7.5f);
        int f = Mathf.FloorToInt(Anim) % 4;
        PoseAct = correr ? (Pose)((int)Pose.Correr1 + f) : (Pose)((int)Pose.Andar1 + f);
    }

    protected virtual void LateUpdate() {
        if (Herido > 0) Herido -= Time.deltaTime;
        transform.position = Mundo.AMundo(Pos);
        Sr.sprite = ForjaChar.Frame(Arq, Herido > 0 ? Pose.Herido : PoseAct, Dir8);
        Sr.sortingOrder = Mundo.OrdenY(Pos.y);
    }
}

/// <summary>Vecino que pasea por la acera y sale corriendo cuando hay jaleo.</summary>
public class Peaton : Andante {
    public float Huye, Temporizador;
    Vector2 _rumbo;

    public void Recolocar(Vector2 cerca) {
        Pos = Ciudad.PuntoAcera(Mathf.RoundToInt(cerca.x), Mathf.RoundToInt(cerca.y), 22);
        Arq = ForjaChar.PeatonArq[Utiles.RndI(0, ForjaChar.PeatonArq.Length-1)];
        Hp = 30; Huye = 0;
    }

    public void Tic(float dt, Vector2 jugador) {
        if (Huye > 0) {
            Huye -= dt;
            Vector2 d = (Pos - jugador).normalized;
            Movimiento.Deslizar(ref Pos, d * 3.6f * dt, false);
            Dir8 = ForjaChar.Dir8(d.x, d.y);
            CicloAndar(dt, true);
        } else {
            Temporizador -= dt;
            if (Temporizador <= 0) {
                float a = Utiles.Rnd(0, Mathf.PI*2);
                _rumbo = new Vector2(Mathf.Cos(a), Mathf.Sin(a));
                Temporizador = Utiles.Rnd(1, 4);
            }
            Vector2 n = Pos + _rumbo * 0.95f * dt;
            var t = Ciudad.T(Mathf.FloorToInt(n.x), Mathf.FloorToInt(n.y));
            if (t == Suelo.Acera || t == Suelo.Plaza || t == Suelo.Muelle || t == Suelo.Parque || t == Suelo.Patio) {
                Pos = n;
                Dir8 = ForjaChar.Dir8(_rumbo.x, _rumbo.y);
                CicloAndar(dt, false);
            } else { Temporizador = 0; PoseAct = Pose.Quieto; }
        }
        if (Vector2.Distance(Pos, jugador) > 36f) Recolocar(jugador);
    }
}

/// <summary>Matón o ertzaina a pie: se acerca, y a tiro se planta y dispara.</summary>
public class Enemigo : Andante {
    public string ArmaId = "punos";
    public float Cad;
    public bool DeMision, EsPoli;

    public void Tic(float dt, Vector2 jugador) {
        var a = Armas.De(ArmaId);
        float d = Vector2.Distance(Pos, jugador);
        Cad = Mathf.Max(0, Cad - dt);
        bool ve = Combate.LineaVista(Pos, jugador);
        if (d > (a.Cuerpo ? 1.1f : a.Alc * 0.75f) || !ve) {
            Vector2 dir = (jugador - Pos).normalized;
            float v = a.Cuerpo ? 2.7f : 2.2f;
            Movimiento.Deslizar(ref Pos, dir * v * dt, false);
            Dir8 = ForjaChar.Dir8(dir.x, dir.y);
            CicloAndar(dt, false);
        } else {
            Vector2 dir = (jugador - Pos).normalized;
            Dir8 = ForjaChar.Dir8(dir.x, dir.y);
            PoseAct = Herido > 0 ? Pose.Herido : (a.Cuerpo ? Pose.Quieto : Pose.Apunta);
            if (Cad <= 0) {
                Cad = a.Cad * Utiles.Rnd(1.5f, 2.6f);
                if (a.Cuerpo) {
                    if (d < a.Alc + 0.3f) { Combate.I.DanarJugador(a.Dmg); AudioProc.I.Sfx("golpe", 0.5f); PoseAct = Pose.Pega2; }
                } else {
                    float ang = Mathf.Atan2(dir.y, dir.x) + Utiles.Rnd(-0.09f, 0.09f);
                    Combate.I.Disparar(Pos, ang, a, false);
                    PoseAct = Pose.Dispara;
                }
            }
        }
    }
}

/// <summary>Coche que circula por casillas siguiendo la calzada. Barato y estable.</summary>
public class Rejilla : MonoBehaviour {
    public Vector2 Pos;
    public int Tx, Ty, Dx = 1, Dy;
    public float Vel = 3.7f, Ang, Luz;
    public bool Persigue, Frenado;
    public string Tipo = "utilitario";
    public int Librea;
    SpriteRenderer _sr;

    public void Preparar() { _sr = gameObject.AddComponent<SpriteRenderer>(); }

    public void Tic(float dt, Vector2 jugador) {
        if (!Frenado) {
            if (Mathf.Abs(Tx + 0.5f - Pos.x) + Mathf.Abs(Ty + 0.5f - Pos.y) < 0.3f) Elegir(jugador);
            Ang = Mathf.Atan2(Ty + 0.5f - Pos.y, Tx + 0.5f - Pos.x);
            Pos += new Vector2(Mathf.Cos(Ang), Mathf.Sin(Ang)) * Vel * dt;
        }
        Luz += dt * 9f;
    }

    void Elegir(Vector2 jugador) {
        var opciones = new List<Vector2Int>();
        var dirs = new[]{ new Vector2Int(1,0), new Vector2Int(-1,0), new Vector2Int(0,1), new Vector2Int(0,-1) };
        foreach (var d in dirs) if (Ciudad.Rodable(Tx + d.x, Ty + d.y)) opciones.Add(d);
        if (opciones.Count == 0) { Tx++; return; }
        Vector2Int el;
        if (Persigue) {
            el = opciones[0];
            float mejor = float.MaxValue;
            foreach (var d in opciones) {
                float dd = Vector2.Distance(new Vector2(Tx + d.x, Ty + d.y), jugador);
                if (dd < mejor) { mejor = dd; el = d; }
            }
        } else {
            Vector2Int recto = new Vector2Int(Dx, Dy);
            bool puedeRecto = opciones.Contains(recto);
            if (puedeRecto && Random.value < 0.82f) el = recto;
            else {
                el = opciones[0];
                foreach (var d in opciones) if (!(d.x == -Dx && d.y == -Dy)) { el = d; break; }
            }
        }
        Dx = el.x; Dy = el.y; Tx += el.x; Ty += el.y;
    }

    void LateUpdate() {
        transform.position = Mundo.AMundo(Pos);
        transform.rotation = Quaternion.Euler(0, 0, -Ang * Mathf.Rad2Deg);
        if (_sr == null) return;
        _sr.sprite = Persigue
            ? Forja.PatrullaRot[Mathf.Sin(Luz) > 0 ? 0 : 1]
            : Forja.Veh[Tipo][Librea % Forja.Libreas.Length];
        _sr.sortingOrder = Mundo.OrdenY(Pos.y);
    }
}

}

using System.Collections.Generic;
using UnityEngine;

namespace BilboCity {

public class Bala {
    public Vector2 Pos, Vel;
    public float Dmg, Vida;
    public bool DelJugador;
    public GameObject Go;
}

/// <summary>Partículas simples con sprites de un píxel escalados. Sin sistema de partículas de Unity.</summary>
public class Particulas : MonoBehaviour {
    public static Particulas I;
    class Part { public Vector2 Pos, Vel; public float Vida, R; public string Tipo; public SpriteRenderer Sr; }
    readonly List<Part> _vivas = new List<Part>();
    readonly Stack<SpriteRenderer> _libres = new Stack<SpriteRenderer>();
    Sprite _punto;

    void Awake() {
        I = this;
        var L = new Lienzo(4,4); L.P(0,0,4,4,Paleta.Hueso);
        _punto = Forja.SpriteDe(L);
    }

    public void Emitir(Vector2 p, string tipo, int n) {
        for (int i = 0; i < n; i++) {
            float a = Utiles.Rnd(0, Mathf.PI*2);
            float v = tipo == "sangre" ? Utiles.Rnd(1,4) : tipo == "chispa" ? Utiles.Rnd(2,7) : Utiles.Rnd(0.4f,2.4f);
            var sr = _libres.Count > 0 ? _libres.Pop() : NuevoSr();
            sr.gameObject.SetActive(true);
            sr.color = tipo == "sangre" ? (Color)Paleta.Sangre
                     : tipo == "chispa" ? (Color)Paleta.Mostaza
                     : new Color(0.42f,0.47f,0.51f,0.5f);
            _vivas.Add(new Part {
                Pos = p, Vel = new Vector2(Mathf.Cos(a),Mathf.Sin(a))*v,
                Vida = tipo == "humo" ? Utiles.Rnd(0.6f,1.6f) : Utiles.Rnd(0.25f,0.7f),
                R = tipo == "humo" ? Utiles.Rnd(4,9) : Utiles.Rnd(1.5f,3.5f),
                Tipo = tipo, Sr = sr
            });
        }
    }

    SpriteRenderer NuevoSr() {
        var go = new GameObject("part");
        go.transform.SetParent(transform, false);
        var sr = go.AddComponent<SpriteRenderer>();
        sr.sprite = _punto;
        sr.sortingOrder = 5000;
        return sr;
    }

    void Update() {
        float dt = Time.deltaTime;
        for (int i = _vivas.Count-1; i >= 0; i--) {
            var p = _vivas[i];
            p.Vida -= dt;
            p.Pos += p.Vel * dt * 0.35f;
            p.Vel *= 0.94f;
            if (p.Tipo == "humo") p.R += dt * 4f;
            if (p.Vida <= 0) {
                p.Sr.gameObject.SetActive(false);
                _libres.Push(p.Sr);
                _vivas.RemoveAt(i);
                continue;
            }
            p.Sr.transform.position = Mundo.AMundoPixel(p.Pos);
            float e = p.R / 16f;
            p.Sr.transform.localScale = new Vector3(e,e,1);
            var c = p.Sr.color;
            c.a = Mathf.Clamp01(p.Vida / 0.7f) * (p.Tipo == "humo" ? 0.5f : 1f);
            p.Sr.color = c;
        }
    }
}

/// <summary>Disparos, daño, explosiones y estrellas de búsqueda.</summary>
public class Combate : MonoBehaviour {
    public static Combate I;
    public readonly List<Bala> Balas = new List<Bala>();
    readonly Stack<GameObject> _balasLibres = new Stack<GameObject>();
    Sprite _spBala;
    float _cooldown, _detT;

    /// <summary>Una bala reciclada del pool, o una nueva si no queda ninguna.</summary>
    GameObject PedirBala() {
        if (_balasLibres.Count > 0) {
            var g = _balasLibres.Pop();
            g.SetActive(true);
            return g;
        }
        var go = new GameObject("bala");
        go.transform.SetParent(transform, false);
        var sr = go.AddComponent<SpriteRenderer>();
        sr.sprite = _spBala;
        sr.sortingOrder = 6000;
        return go;
    }

    void DevolverBala(Bala b) {
        b.Go.SetActive(false);
        _balasLibres.Push(b.Go);
    }

    void Awake() {
        I = this;
        var L = new Lienzo(3,3); L.P(0,0,3,3,Paleta.Mostaza);
        _spBala = Forja.SpriteDe(L);
    }

    public static bool LineaVista(Vector2 a, Vector2 b) {
        float d = Vector2.Distance(a,b);
        int pasos = Mathf.CeilToInt(d / 0.4f);
        for (int i = 1; i < pasos; i++) {
            float t = i/(float)pasos;
            var s = Ciudad.T(Mathf.FloorToInt(Mathf.Lerp(a.x,b.x,t)), Mathf.FloorToInt(Mathf.Lerp(a.y,b.y,t)));
            if (!Ciudad.Andable(s)) return false;
        }
        return true;
    }

    public void Disparar(Vector2 desde, float ang, Arma a, bool delJugador) {
        for (int i = 0; i < a.Disp; i++) {
            float sp = (Random.value - 0.5f) * a.Spread * 2f;
            var go = PedirBala();
            Balas.Add(new Bala {
                Pos = desde + new Vector2(Mathf.Cos(ang), Mathf.Sin(ang)) * 0.5f,
                Vel = new Vector2(Mathf.Cos(ang+sp), Mathf.Sin(ang+sp)) * a.Vel,
                Dmg = a.Dmg, Vida = a.Alc / a.Vel, DelJugador = delJugador, Go = go
            });
        }
        Particulas.I.Emitir(desde + new Vector2(Mathf.Cos(ang), Mathf.Sin(ang)) * 0.6f, "chispa", 3);
        AudioProc.I.Sfx(a.Id == "escopeta" ? "escopeta" : "disparo", 0.8f);
    }

    /// <summary>Las balas avanzan en tres subpasos para que no atraviesen a nadie de cerca.</summary>
    public void TicBalas(float dt, Juego J) {
        for (int i = Balas.Count-1; i >= 0; i--) {
            var b = Balas[i];
            b.Vida -= dt;
            bool muerta = false;
            for (int s = 0; s < 3 && !muerta; s++) {
                b.Pos += b.Vel * dt / 3f;
                if (!Ciudad.Andable(Ciudad.T(Mathf.FloorToInt(b.Pos.x), Mathf.FloorToInt(b.Pos.y)))) {
                    Particulas.I.Emitir(b.Pos, "chispa", 2); muerta = true; break;
                }
                if (b.DelJugador) {
                    foreach (var e in J.Enemigos)
                        if (Vector2.Distance(e.Pos, b.Pos) < 0.6f) { Danar(e, b.Dmg, J); muerta = true; break; }
                    if (!muerta)
                        foreach (var p in J.Peatones)
                            if (Vector2.Distance(p.Pos, b.Pos) < 0.55f) { DanarPeaton(p, b.Dmg, J); muerta = true; break; }
                    if (!muerta)
                        foreach (var c in J.Coches)
                            if (c.Vivo && Vector2.Distance(c.Pos, b.Pos) < 0.9f) {
                                c.Dano += 0.09f; if (c.Dano >= 1f) Explotar(c);
                                muerta = true; break;
                            }
                } else {
                    if (J.Jug.EnCoche == null && Vector2.Distance(J.Jug.Pos, b.Pos) < 0.6f) {
                        DanarJugador(b.Dmg); Particulas.I.Emitir(b.Pos, "sangre", 4); muerta = true;
                    } else if (J.Jug.EnCoche != null && Vector2.Distance(J.Jug.Pos, b.Pos) < 0.95f) {
                        J.Jug.EnCoche.Dano += 0.05f; DanarJugador(b.Dmg * 0.4f); muerta = true;
                    }
                }
            }
            if (muerta || b.Vida <= 0) { DevolverBala(b); Balas.RemoveAt(i); }
            else b.Go.transform.position = Mundo.AMundoPixel(b.Pos);
        }
    }

    public void Danar(Enemigo e, float d, Juego J) {
        e.Hp -= d; e.Herido = 0.25f;
        Particulas.I.Emitir(e.Pos, "sangre", 3);
        if (e.Hp > 0) return;
        Estado.I.Dinero += Utiles.RndI(20,70);
        AudioProc.I.Sfx("dinero", 0.5f);
        Particulas.I.Emitir(e.Pos, "sangre", 10);
        bool eraMision = e.DeMision;
        J.QuitarEnemigo(e);
        if (eraMision) Misiones.I.EnemigoAbatido();
    }

    public void DanarPeaton(Peaton p, float d, Juego J) {
        p.Hp -= d; p.Herido = 0.25f; p.Huye = 4f;
        Particulas.I.Emitir(p.Pos, "sangre", 3);
        if (p.Hp > 0) return;
        Particulas.I.Emitir(p.Pos, "sangre", 8);
        AudioProc.I.Sfx("grito", 0.6f);
        Sigilo.Delito(1);
        p.Recolocar(J.Jug.Pos);
    }

    public void DanarJugador(float d) {
        var E = Estado.I;
        if (E.Muerto > 0) return;
        E.Hp = Mathf.Max(0, E.Hp - d);
        Hud.I.Flash();
        if (E.Hp <= 0) { E.Muerto = 2.2f; Hud.I.Grande("K.O.", 2.2f); }
    }

    public void Explotar(Vehiculo c) {
        c.Vivo = false; c.Refrescar();
        AudioProc.I.Sfx("explosion", 1f);
        Particulas.I.Emitir(c.Pos, "chispa", 26);
        Particulas.I.Emitir(c.Pos, "humo", 16);
        var J = Juego.I;
        for (int i = J.Enemigos.Count-1; i >= 0; i--) {
            var e = J.Enemigos[i];
            if (Vector2.Distance(e.Pos, c.Pos) < 2.6f) Danar(e, 90, J);
        }
        if (Vector2.Distance(J.Jug.Pos, c.Pos) < 2.8f) DanarJugador(55);
        if (J.Jug.EnCoche == c) { J.Jug.EnCoche = null; J.Jug.Pos = c.Pos + Vector2.one; }
    }

    // ═══════════ BÚSQUEDA ═══════════
    public void Estrellas(int n, Juego J) {
        var E = Estado.I;
        E.Estrellas = Mathf.Clamp(E.Estrellas + n, 0, 5);
        _cooldown = 0;
        while (J.Patrullas.Count < Mathf.Min(E.Estrellas, 4)) {
            var p = Ciudad.PuntoCalle(Mathf.RoundToInt(J.Jug.Pos.x), Mathf.RoundToInt(J.Jug.Pos.y), 28);
            J.NuevaPatrulla(p, 5.2f + E.Estrellas * 0.35f);
        }
    }

    public void TicBusqueda(float dt, Juego J) {
        var E = Estado.I;
        bool sirena = false;
        foreach (var p in J.Patrullas) {
            float d = Vector2.Distance(p.Pos, J.Jug.Pos);
            if (d < 16f) sirena = true;
            if (d < 1.25f) {
                _detT += dt;
                if (J.Jug.EnCoche != null) { DanarJugador(dt * 14f); J.Jug.EnCoche.Dano += dt * 0.12f; }
                if (J.Jug.EnCoche == null && _detT > 1.5f) { _detT = 0; J.Detener(); return; }
            }
            if (E.Estrellas >= 2 && d < 9f && J.ContarPolisAPie() < E.Estrellas*2 && Random.value < dt * 0.7f)
                J.NuevoEnemigo(p.Pos, "ertzaina", E.Estrellas >= 3 ? "uzi" : "pistola", false, true);
        }
        AudioProc.I.Sirena(dt, E.Estrellas > 0 && sirena);

        if (E.Estrellas <= 0) return;
        // Antes bastaba con alejarse, mirase quien mirase. Ahora lo que cuenta es que
        // ninguno te tenga a la vista: agachado detrás de un contenedor, con la patrulla a
        // diez metros pero mirando a otro lado, la cuenta corre.
        bool cerca = E.Visto;
        foreach (var p2 in J.Patrullas) if (Vector2.Distance(p2.Pos, J.Jug.Pos) < 4f) cerca = true;
        foreach (var e in J.Enemigos) if (e.EsPoli && Vector2.Distance(e.Pos, J.Jug.Pos) < 4f) cerca = true;
        if (!cerca) {
            _cooldown += dt;
            if (_cooldown > 8f) {
                _cooldown = 0;
                E.Estrellas--;
                J.QuitarUnaPatrulla();
                if (E.Estrellas == 0) { Hud.I.Aviso("LOS HAS DESPISTADO"); J.QuitarPolisAPie(); }
            }
        } else _cooldown = Mathf.Max(0, _cooldown - dt * 0.6f);
    }
}

}

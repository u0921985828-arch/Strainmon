using UnityEngine;

namespace BilboCity {

/// <summary>El protagonista: a pie con ciclo de andar y correr, o al volante.</summary>
public class Jugador : MonoBehaviour {
    public Vector2 Pos;
    public int Dir8;
    public Pose PoseAct = Pose.Quieto;
    /// La postura la decide el propio joystick: flojo va agachado, a fondo corre. Se
    /// queda puesta al soltarlo, que si no, agacharse para mirar una esquina y levantarse
    /// solo al parar sería inservible.
    public bool Agachado, Corriendo;
    public Vehiculo EnCoche;
    public float Cadencia, Herido, GolpeT, Anim;
    public string Arquetipo = "protagonista";

    SpriteRenderer _sr, _srArma, _srFog, _srSilueta;
    float _fogT;
    string _fogTipo;

    public void Preparar() {
        _sr = GetComponent<SpriteRenderer>();
        if (_sr == null) _sr = gameObject.AddComponent<SpriteRenderer>();
        _sr.sortingOrder = 0;
        _srArma = Hijo("Arma", 1);
        _srFog  = Hijo("Fogonazo", 2);
        // Ley 6 · visión: la silueta va apagada por defecto y solo se enciende cuando
        // Vision.TapaAlJugador dice que algo de más de dos metros lo esconde.
        _srSilueta = Hijo("Silueta", 3);
        _srSilueta.enabled = false;
    }

    SpriteRenderer Hijo(string nombre, int orden) {
        var go = new GameObject(nombre);
        go.transform.SetParent(transform, false);
        var sr = go.AddComponent<SpriteRenderer>();
        sr.sortingOrder = orden;
        return sr;
    }

    public void Fogonazo(string tipo, int d8) { _fogT = 0.07f; _fogTipo = tipo; Dir8 = d8; }

    public void Mover(float dt, Vector2 entrada, bool correr) { Mover(dt, entrada, correr ? 1f : 0.7f, true); }

    /// <summary>Velocidad analógica: el joystick a medias pasea, a fondo corre y por debajo
    /// del umbral va agachado — la mitad de rápido y la mitad de visible.</summary>
    public void Mover(float dt, Vector2 entrada, float fuerza, bool calle) {
        var E = Estado.I;
        if (calle && fuerza > 0.02f) { Agachado = fuerza < Sigilo.Agacha; Corriendo = fuerza > Sigilo.Corre; }
        bool corre = Corriendo && calle;
        float cansado = E.Energia <= 0 ? 0.6f : 1f;
        float v = (calle && Agachado ? 1.25f : 1.55f + fuerza * 3.25f) * cansado;
        // La figura anda en la vara de Movimiento.EscFig, no en la del plano (ver el porqué
        // ahí): en metros de mapa sale más rápido a propósito, para que el paso no patine.
        if (calle) v *= Movimiento.EscFig;
        // Dentro se anda a 1,4 m/s, y ahí la casilla mide 0,80 m: 1,75 casillas por segundo.
        // Con la vara de la calle salían 0,27 y cruzar el salón costaba cincuenta segundos.
        // Y al ir ya a la vara de la figura, no hace falta EscFig.
        if (!calle) v = 1.4f / ForjaInterior.Metro;
        float m = entrada.magnitude;
        if (m > 0.08f) {
            Vector2 d = entrada / m * Mathf.Min(1f, m) * v * dt;
            Movimiento.Deslizar(ref Pos, d, false);
            Dir8 = ForjaChar.Dir8(entrada.x, entrada.y);
            Movimiento.PoseAndar(ref Anim, ref PoseAct, v, calle && Agachado, dt, calle,
                calle ? Movimiento.MetroCalle : ForjaInterior.Metro);
            // Correr suena. Agachado no.
            if (corre && Utiles.Rnd(0f,1f) < dt * 3f) Sigilo.Ruido(Pos, 4.5f);
        } else if (GolpeT <= 0) {
            var a = Armas.De(E.ArmaAct);
            PoseAct = calle && Agachado ? Pose.Agacha
                    : Herido > 0 ? Pose.Herido : (a.Cuerpo ? Pose.Quieto : Pose.Apunta);
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
        if (!visible) { _srSilueta.enabled = false; return; }

        var pose = Herido > 0 ? Pose.Herido : PoseAct;
        _sr.sprite = ForjaChar.Frame(Arquetipo, pose, Dir8);
        _sr.sortingOrder = Mundo.OrdenY(Pos.y);

        // Ley 6 · visión: en coche no hace falta —el coche ya es más visible que
        // cualquier farola— y dentro de un sitio no hay mobiliario urbano que mirar.
        // Si algo de la calle pasa de dos metros y le pisa la caja, se enciende la
        // silueta por encima: el sortingOrder de cualquier pieza a menos de cinco
        // casillas al sur no llega a Pos.y+5, así que con ese margen siempre queda
        // encima de lo que la tapa.
        bool tapado = !Estado.I.EnInterior && Vision.TapaAlJugador(Pos);
        _srSilueta.enabled = tapado;
        if (tapado) {
            _srSilueta.sprite = ForjaChar.FrameSilueta(Arquetipo, pose, Dir8);
            _srSilueta.sortingOrder = Mundo.OrdenY(Pos.y + 5f);
        }

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
    /// <summary>Metros por casilla en la calle, para pasar una velocidad de casillas por
    /// segundo a metros por segundo.</summary>
    public const float MetroCalle = 5.16f;

    /// <summary>La vara de la figura. La gente y el mobiliario se dibujan a 20 px/m —a la
    /// escala del suelo una persona mide 21 px y ahí no cabe una cara, ni ocho direcciones—
    /// mientras que el suelo de la calle va a 12,4: la figura es 1,6 veces más grande que
    /// la calle que pisa. Andando a 1,7 m/s de mapa la figura solo avanzaba 0,6 alturas de
    /// cuerpo por segundo, cuando una persona de verdad avanza una entera —el ojo no mide
    /// metros, mide cuerpos, y eso es lo que se ve como patinar—. Así que lo que anda por
    /// encima del suelo anda en la vara de la figura, no en la del plano: la velocidad se
    /// multiplica por EscFig y el paso se ve como el de alguien de ese tamaño, aunque en
    /// metros de mapa salga más rápido a propósito. Dentro de un sitio no hace falta y por
    /// eso ahí siempre se vio bien: la casilla de interior ya va a 20 px/m, la misma vara
    /// que la gente.
    ///
    /// No se copia el número del prototipo: se calcula, porque **aquí no sale el mismo**. El
    /// HTML forja la figura a 4:3 sobre una casilla de 64 px y le da 1,61; el puerto la forja
    /// a 1:1 sobre una casilla de 32 y le sale 2,46. Las dos cifras son correctas en su
    /// implementación —la regla es la misma, los píxeles no—, y convergerán solas cuando
    /// Unity suba la casilla a 64 (TAREAS §4b). Copiar el 1,61 dejaría al puerto andando a la
    /// vara de otro dibujo.</summary>
    public static readonly float EscFig =
        ForjaChar.ALTO_FIGURA / (1.70f * (Forja.TS / MetroCalle));

    /// <summary>La zancada del andar y la de la carrera no miden lo mismo —75 cm y 1,80 m—,
    /// en metros de la vara de la figura: con una sola medida la carrera salía a ocho pasos
    /// por segundo, el doble que un atleta, y las piernas se veían como un abanico.</summary>
    public static readonly float Zancada = 0.75f * EscFig, ZancadaC = 1.80f * EscFig;

    /// <summary>De aquí para arriba se anda a la carrera. En la calle el umbral va en la
    /// vara de la figura como la velocidad; dentro de un sitio no, porque ahí ya se anda a
    /// esa vara sin escalar nada.</summary>
    public static readonly float VelCorreAnim = 3.2f * EscFig;
    public const float VelCorreAnimInterior = 3.2f;

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

    /// <summary>La cadencia del ciclo de andar sale de la velocidad de verdad, no de un
    /// ritmo fijo: a la misma zancada, ir más rápido son más pasos por segundo. `vel` va en
    /// casillas por segundo —en la vara de la figura si es calle— y `metroCasilla` dice
    /// cuánto mide esa casilla para pasarla a metros por segundo: 5,16 m en la calle, o el
    /// ancho real de la casilla de interior.</summary>
    public static void PoseAndar(ref float anim, ref Pose pose, float vel, bool sigilo, float dt, bool calle, float metroCasilla) {
        float ms = Mathf.Abs(vel) * metroCasilla;
        bool corriendo = ms > (calle ? VelCorreAnim : VelCorreAnimInterior);
        anim += dt * Mathf.Max(0.6f, ms / (corriendo ? ZancadaC : Zancada));
        int f = Mathf.FloorToInt(anim) % 4;
        // Agachado no lleva dibujo nuevo: se acortan las dos piernas y baja el cuerpo.
        if (sigilo) { pose = f < 2 ? Pose.Agacha : Pose.Agacha2; return; }
        pose = corriendo ? (Pose)((int)Pose.Correr1 + f) : (Pose)((int)Pose.Andar1 + f);
    }
}

/// <summary>Conversión entre coordenadas de casilla y de Unity, y orden de dibujo por Y.</summary>
public static class Mundo {
    /// <summary>Píxeles de sprite por unidad de Unity. Una casilla mide una unidad y su
    /// tile 32 px, así que este número tiene que coincidir con el de Utiles.Rebanada.</summary>
    public const float PPU = 32f;

    /// <summary>La Y de las casillas crece hacia abajo; la de Unity hacia arriba.</summary>
    public static Vector3 AMundo(Vector2 p) {
        // Dentro de un sitio la casilla mide 0,80 m y se dibuja a 16 px, no 5,16 m y 32: media
        // unidad. Y la Y se voltea contra el alto del interior, no contra el de Bilbao.
        if (Estado.I != null && Estado.I.EnInterior && Interiores.Actual != null)
            return new Vector3(p.x * Interiores.Escala, (Interiores.Alto - p.y) * Interiores.Escala, 0);
        return new Vector3(p.x, Ciudad.MH - p.y, 0);
    }

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

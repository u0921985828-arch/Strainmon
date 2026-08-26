using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

namespace BilboCity {

/// <summary>Joystick flotante en la mitad izquierda y botones en la derecha.</summary>
public class Controles : MonoBehaviour {
    public static Controles I;
    public Vector2 Eje;
    public bool Correr;
    public bool AccionPulsada, AtacarPulsado, AtacarMantenido;
    bool _correrBoton, _atacarBoton;

    int _dedoJoy = -1;
    Vector2 _origen;
    RectTransform _joyFondo, _joyPalanca;

    void Awake() { I = this; }

    public void Montar(Transform canvas) {
        var fondo = UiFab.Img(canvas, Redondel(66, new Color32(230,226,214,40)), new Vector2(0,0), Vector2.zero, new Vector2(132,132));
        fondo.raycastTarget = false;
        _joyFondo = fondo.rectTransform;
        var pal = UiFab.Img(canvas, Redondel(27, new Color32(230,226,214,90)), new Vector2(0,0), Vector2.zero, new Vector2(54,54));
        pal.raycastTarget = false;
        _joyPalanca = pal.rectTransform;
        _joyFondo.gameObject.SetActive(false);
        _joyPalanca.gameObject.SetActive(false);

        BotonRedondo(canvas, "ACCIÓN", new Vector2(1,0), new Vector2(-100,108), 80, () => AccionPulsada = true, null);
        BotonRedondo(canvas, "ATACAR", new Vector2(1,0), new Vector2(-180,180), 74,
                     () => { AtacarPulsado = true; _atacarBoton = true; }, () => _atacarBoton = false);
        BotonRedondo(canvas, "CORRER", new Vector2(1,0), new Vector2(-176,76), 60,
                     () => _correrBoton = true, () => _correrBoton = false);
        BotonRedondo(canvas, "☎", new Vector2(1,0), new Vector2(-40,40), 52, () => MenuMovil.I.Alternar(), null);
        BotonRedondo(canvas, "⇄", new Vector2(0,0), new Vector2(90,40), 46, () => Juego.I.CambiarArma(), null);
        BotonRedondo(canvas, "❚❚", new Vector2(0,0), new Vector2(38,40), 46, () => MenuMovil.I.AlternarPausa(), null);
    }

    static Sprite Redondel(int r, Color32 c) {
        var L = new Lienzo(r*2, r*2);
        for (int y = 0; y < r*2; y++)
            for (int x = 0; x < r*2; x++) {
                float d = Mathf.Sqrt((x-r)*(x-r) + (y-r)*(y-r));
                if (d <= r) L.Px[y*r*2+x] = c;
            }
        var px = new Color32[r*2*r*2];
        L.VolcarEn(px, r*2, r*2, 0, 0);
        return Utiles.Rebanada(Utiles.Textura(r*2, r*2, px), 0, 0, r*2, r*2, r, r);
    }

    void BotonRedondo(Transform canvas, string etiqueta, Vector2 anchor, Vector2 pos, int diam,
                      System.Action alPulsar, System.Action alSoltar) {
        var im = UiFab.Img(canvas, Redondel(diam/2, new Color32(30,36,43,210)), anchor,
                           new Vector2(pos.x - diam/2f, pos.y + diam/2f), new Vector2(diam,diam));
        im.rectTransform.pivot = new Vector2(0.5f,0.5f);
        im.rectTransform.anchoredPosition = pos;
        var t = UiFab.Texto(im.transform, "txt", 13, TextAnchor.MiddleCenter, Vector2.zero, diam, diam);
        t.text = etiqueta;
        var trig = im.gameObject.AddComponent<EventTrigger>();
        var down = new EventTrigger.Entry { eventID = EventTriggerType.PointerDown };
        down.callback.AddListener(_ => { if (alPulsar != null) alPulsar(); });
        trig.triggers.Add(down);
        if (alSoltar != null) {
            var up = new EventTrigger.Entry { eventID = EventTriggerType.PointerUp };
            up.callback.AddListener(_ => alSoltar());
            trig.triggers.Add(up);
        }
    }

    void Update() {
        // teclado, para probar en el editor
        float kx = 0, ky = 0;
        if (Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.LeftArrow)) kx = -1;
        if (Input.GetKey(KeyCode.D) || Input.GetKey(KeyCode.RightArrow)) kx = 1;
        if (Input.GetKey(KeyCode.W) || Input.GetKey(KeyCode.UpArrow)) ky = -1;
        if (Input.GetKey(KeyCode.S) || Input.GetKey(KeyCode.DownArrow)) ky = 1;
        if (Input.GetKeyDown(KeyCode.E)) AccionPulsada = true;
        if (Input.GetKeyDown(KeyCode.Space)) AtacarPulsado = true;
        if (Input.GetKeyDown(KeyCode.Q)) Juego.I.CambiarArma();
        AtacarMantenido = _atacarBoton || Input.GetKey(KeyCode.Space);
        Correr = _correrBoton || Input.GetKey(KeyCode.LeftShift);

        Vector2 joy = Vector2.zero;
        bool hayDedo = false;
        for (int i = 0; i < Input.touchCount; i++) {
            var t = Input.GetTouch(i);
            if (t.phase == TouchPhase.Began && _dedoJoy < 0 && t.position.x < Screen.width * 0.55f) {
                _dedoJoy = t.fingerId;
                _origen = t.position;
                _joyFondo.gameObject.SetActive(true);
                _joyPalanca.gameObject.SetActive(true);
                _joyFondo.position = t.position;
            }
            if (t.fingerId != _dedoJoy) continue;
            hayDedo = true;
            if (t.phase == TouchPhase.Ended || t.phase == TouchPhase.Canceled) {
                _dedoJoy = -1;
                _joyFondo.gameObject.SetActive(false);
                _joyPalanca.gameObject.SetActive(false);
                hayDedo = false;
                break;
            }
            Vector2 d = t.position - _origen;
            float max = 50f * (Screen.dpi > 0 ? 1f : 1f);
            if (d.magnitude > max) d = d.normalized * max;
            _joyPalanca.position = _origen + d;
            joy = d / max;
            joy.y = -joy.y;   // en pantalla la Y sube; en el mundo baja
        }
        if (!hayDedo && _dedoJoy >= 0) {
            _dedoJoy = -1;
            _joyFondo.gameObject.SetActive(false);
            _joyPalanca.gameObject.SetActive(false);
        }

        Eje = joy.sqrMagnitude > 0.005f ? joy : new Vector2(kx, ky);
    }

}

/// <summary>Audio sintetizado en el momento. Sin ficheros de sonido en el proyecto.</summary>
public class AudioProc : MonoBehaviour {
    public static AudioProc I;
    public bool Sonido = true, Musica = true;
    AudioSource _motor, _sirena, _uno;
    AudioClip _clipMotor, _clipSirena;
    float _musT;
    static readonly int[] Escala = { 0, 3, 5, 7, 10 };

    void Awake() {
        I = this;
        _uno = gameObject.AddComponent<AudioSource>();
        _uno.playOnAwake = false;
        _motor = gameObject.AddComponent<AudioSource>();
        _motor.loop = true; _motor.playOnAwake = false; _motor.volume = 0;
        _sirena = gameObject.AddComponent<AudioSource>();
        _sirena.loop = true; _sirena.playOnAwake = false; _sirena.volume = 0;
        _clipMotor = Onda("motor", 0.25f, f => Mathf.Sin(f * Mathf.PI * 2) * 0.6f + (Random.value-0.5f)*0.25f, 90);
        _clipSirena = Onda("sirena", 0.5f, f => Mathf.Sign(Mathf.Sin(f * Mathf.PI * 2)) * 0.4f, 620);
        _motor.clip = _clipMotor; _motor.Play();
        _sirena.clip = _clipSirena; _sirena.Play();
    }

    AudioClip Onda(string nombre, float seg, System.Func<float,float> forma, float hz) {
        int sr = 44100, n = Mathf.RoundToInt(sr * seg);
        var datos = new float[n];
        for (int i = 0; i < n; i++) datos[i] = forma(i * hz / sr);
        var c = AudioClip.Create(nombre, n, 1, sr, false);
        c.SetData(datos, 0);
        return c;
    }

    public void Motor(float vel, float vmax) {
        if (!Sonido) { _motor.volume = 0; return; }
        float v = Mathf.Abs(vel) / Mathf.Max(1, vmax);
        _motor.pitch = 0.55f + v * 1.5f;
        _motor.volume = Mathf.Clamp(0.05f + v * 0.13f, 0, 0.2f);
    }
    public void MotorApagado() { _motor.volume = 0; }

    public void Sirena(float dt, bool activa) {
        if (!Sonido || !activa) { _sirena.volume = 0; return; }
        _sirena.volume = 0.06f;
        _sirena.pitch = Mathf.Sin(Time.time * 6f) > 0 ? 1.15f : 0.85f;
    }

    public void Sfx(string tipo, float vol) {
        if (!Sonido) return;
        AudioClip c;
        switch (tipo) {
            case "disparo":   c = Ruido(0.14f, 1500, 0.9f); break;
            case "escopeta":  c = Ruido(0.30f, 900, 1f); break;
            case "golpe":     c = Ruido(0.14f, 320, 0.8f); break;
            case "choque":    c = Ruido(0.16f, 260, 0.9f); break;
            case "grito":     c = Ruido(0.22f, 1500, 0.7f); break;
            case "explosion": c = Ruido(0.85f, 180, 1f); break;
            case "claxon":    c = Tono(0.3f, 380, 0.25f); break;
            case "dinero":    c = Tono(0.16f, 780, 0.25f); break;
            default:          c = Tono(0.14f, 260, 0.22f); break;
        }
        _uno.PlayOneShot(c, Mathf.Clamp01(vol) * 0.35f);
    }

    AudioClip Ruido(float seg, float corte, float amp) {
        int sr = 22050, n = Mathf.RoundToInt(sr * seg);
        var d = new float[n];
        float prev = 0, k = Mathf.Clamp01(corte / (sr * 0.5f));
        for (int i = 0; i < n; i++) {
            float r = Random.value * 2 - 1;
            prev += (r - prev) * k;
            float env = Mathf.Exp(-6f * i / (float)n);
            d[i] = prev * env * amp;
        }
        var c = AudioClip.Create("r", n, 1, sr, false);
        c.SetData(d, 0);
        return c;
    }

    AudioClip Tono(float seg, float hz, float amp) {
        int sr = 22050, n = Mathf.RoundToInt(sr * seg);
        var d = new float[n];
        for (int i = 0; i < n; i++) {
            float env = Mathf.Exp(-5f * i / (float)n);
            d[i] = Mathf.Sign(Mathf.Sin(i * hz / sr * Mathf.PI * 2)) * env * amp;
        }
        var c = AudioClip.Create("t", n, 1, sr, false);
        c.SetData(d, 0);
        return c;
    }

    public void TicMusica(float dt) {
        if (!Sonido || !Musica) return;
        _musT -= dt;
        if (_musT > 0) return;
        _musT = 0.24f;
        int b = Estado.I.Estrellas > 0 ? 58 : Estado.I.EnInterior ? 46 : 41;
        int paso = Escala[Utiles.RndI(0,4)] + (Random.value < 0.25f ? 12 : 0);
        float hz = 440f * Mathf.Pow(2f, (b + paso - 69) / 12f);
        _uno.PlayOneShot(Tono(0.22f, hz, 0.18f), 0.25f);
    }
}

/// <summary>Guardado en PlayerPrefs con JsonUtility. Simple y suficiente.</summary>
[System.Serializable]
public class Partida {
    public int version = 2;
    public float dinero, hp, energia, hambre;
    public int min, dia, deuda, alquiler, ultCobro, misionIdx;
    public int repHosteleria, repObra, repTransporte, repCalle;
    public bool furgo, deportivo;
    public string armaAct;
    public int munBate, munPistola, munUzi, munEscopeta;
    public string torso, piernas, calzado, gorro;
    public bool silenciador;
    public int xp, nivelPj = 1;
    public List<string> props = new List<string>();
    public int caseraPaciencia = 3;
    public bool caseraAvisada, caseraDesahucio, caseraOkupa;
    public bool prologo;
    public float x, y;
    public List<Contrato> contratos = new List<Contrato>();
}

public static class Guardado {
    const string CLAVE = "bilbocity_unity_v1";

    public static void Guardar() {
        var E = Estado.I;
        var J = Juego.I;
        var p = new Partida {
            dinero = E.Dinero, hp = E.Hp, energia = E.Energia, hambre = E.Hambre,
            min = E.Min, dia = E.Dia, deuda = E.Deuda, alquiler = E.Alquiler,
            ultCobro = E.UltCobro, misionIdx = E.MisionIdx,
            repHosteleria = E.Rep["hosteleria"], repObra = E.Rep["obra"],
            repTransporte = E.Rep["transporte"], repCalle = E.Rep["calle"],
            furgo = E.TieneFurgo, deportivo = E.TieneDeportivo, armaAct = E.ArmaAct,
            munBate = E.Mun("bate"), munPistola = E.Mun("pistola"),
            munUzi = E.Mun("uzi"), munEscopeta = E.Mun("escopeta"),
            torso = E.Torso, piernas = E.Piernas, calzado = E.Calzado, gorro = E.Gorro,
            silenciador = E.TieneSilenciador,
            xp = E.Xp, nivelPj = E.NivelPj, props = new List<string>(E.Props),
            caseraPaciencia = E.CaseraPaciencia, caseraAvisada = E.CaseraAvisada,
            caseraDesahucio = E.CaseraDesahucio, caseraOkupa = E.CaseraOkupa,
            prologo = E.Prologo,
            x = J != null && J.Jug != null ? J.Jug.Pos.x : 0,
            y = J != null && J.Jug != null ? J.Jug.Pos.y : 0,
            contratos = E.Contratos
        };
        PlayerPrefs.SetString(CLAVE, JsonUtility.ToJson(p));
        PlayerPrefs.Save();
    }

    public static bool Hay() { return PlayerPrefs.HasKey(CLAVE); }
    public static void Borrar() { PlayerPrefs.DeleteKey(CLAVE); PlayerPrefs.Save(); }

    public const int VERSION = 2;

    public static bool Cargar() {
        if (!Hay()) return false;
        Partida p;
        try {
            p = JsonUtility.FromJson<Partida>(PlayerPrefs.GetString(CLAVE));
        } catch (System.Exception e) {
            Debug.LogWarning("Partida ilegible, se empieza de cero: " + e.Message);
            Borrar();
            return false;
        }
        if (p == null) return false;
        if (p.version > VERSION) {
            Debug.LogWarning("Partida de una versión más nueva (" + p.version + "). Se ignora.");
            return false;
        }
        var E = Estado.I;
        // JsonUtility no deja colar un tipo raro, pero sí un NaN o un número absurdo: un
        // reloj a -500 o un saldo a NaN dejan la partida inservible sin que nada avise.
        E.Dinero = Num(p.dinero, 60f, -1e6f, 1e9f); E.Hp = Num(p.hp, 100f, 0f, 100f);
        E.Energia = Num(p.energia, 1f, 0f, 1f); E.Hambre = Num(p.hambre, 1f, 0f, 1f);
        E.Min = Mathf.Clamp(p.min, 0, 24*60); E.Dia = Mathf.Max(1, p.dia);
        E.Deuda = Mathf.Max(0, p.deuda); E.Alquiler = Mathf.Clamp(p.alquiler, 0, 1000000);
        E.UltCobro = Mathf.Max(1, p.ultCobro); E.MisionIdx = Mathf.Max(0, p.misionIdx);
        E.Rep["hosteleria"] = p.repHosteleria; E.Rep["obra"] = p.repObra;
        E.Rep["transporte"] = p.repTransporte; E.Rep["calle"] = p.repCalle;
        E.TieneFurgo = p.furgo; E.TieneDeportivo = p.deportivo; E.TieneSilenciador = p.silenciador;
        E.Xp = p.xp; E.NivelPj = Mathf.Max(1, p.nivelPj);
        E.Props.Clear();
        if (p.props != null) foreach (var id in p.props) E.Props.Add(id);
        E.CaseraPaciencia = p.caseraPaciencia; E.CaseraAvisada = p.caseraAvisada;
        E.CaseraDesahucio = p.caseraDesahucio; E.CaseraOkupa = p.caseraOkupa;
        E.Prologo = p.prologo;
        E.ArmaAct = string.IsNullOrEmpty(p.armaAct) ? "punos" : p.armaAct;
        E.Municion.Clear();
        if (p.munBate > 0) E.Municion["bate"] = p.munBate;
        if (p.munPistola > 0) E.Municion["pistola"] = p.munPistola;
        if (p.munUzi > 0) E.Municion["uzi"] = p.munUzi;
        if (p.munEscopeta > 0) E.Municion["escopeta"] = p.munEscopeta;
        // La ropa puesta. Una partida de antes de que hubiera tiendas no la trae: se deja
        // la de fábrica en vez de dejar al protagonista en calzoncillos.
        if (!string.IsNullOrEmpty(p.torso)) {
            E.Torso = p.torso; E.Piernas = p.piernas; E.Calzado = p.calzado; E.Gorro = p.gorro;
            ForjaChar.Vestir(E.Torso, E.Piernas, E.Calzado, E.Gorro);
        }
        E.Contratos.Clear();
        if (p.contratos != null) E.Contratos.AddRange(p.contratos);
        // Y una posición sin validar saca al jugador del mapa, donde no hay casilla que
        // pisar. Se cae a la casilla andable más cercana.
        if (Juego.I != null && Juego.I.Jug != null && p.x > 0) {
            float px = Num(p.x, 1f, 1f, Ciudad.MW-2), py = Num(p.y, 1f, 1f, Ciudad.MH-2);
            Juego.I.Jug.Pos = Ciudad.Andable(Ciudad.T((int)px, (int)py))
                ? new Vector2(px, py)
                : Ciudad.CercaDe((x,y) => Ciudad.Andable(Ciudad.T(x,y)), (int)px, (int)py, 60);
        }
        return true;
    }

    /// <summary>Un número del archivo: si no es finito o se sale, vale el de fábrica.</summary>
    static float Num(float v, float def, float lo, float hi) {
        if (float.IsNaN(v) || float.IsInfinity(v)) return def;
        return Mathf.Clamp(v, lo, hi);
    }
}

}

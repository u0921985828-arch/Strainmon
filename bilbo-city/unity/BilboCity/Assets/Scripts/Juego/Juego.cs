using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace BilboCity {

/// <summary>
/// Punto de entrada. Con este componente en un GameObject vacío basta:
/// forja el arte, genera Bilbao, monta cámara, HUD y controles, y corre el bucle.
/// </summary>
public class Juego : MonoBehaviour {
    public static Juego I;

    public Jugador Jug;
    public readonly List<Vehiculo> Coches = new List<Vehiculo>();
    public readonly List<Rejilla> Trafico = new List<Rejilla>();
    public readonly List<Rejilla> Patrullas = new List<Rejilla>();
    public readonly List<Enemigo> Enemigos = new List<Enemigo>();
    public readonly List<Peaton> Peatones = new List<Peaton>();

    Camera _cam;
    Transform _mundo, _entidades;
    RenderCiudad _render;
    Image _tinte;
    Color _tinteActual = Color.black;
    float _acum, _autoT;
    bool _listo;
    readonly List<SpriteRenderer> _marcas = new List<SpriteRenderer>();

    static readonly string[] TiposCivil = { "utilitario","berlina","ranchera","todoterreno","taxi","furgoCorta" };
    static readonly string[] TiposPesado = { "autobus","basura","camionObra","furgoLarga" };

    void Awake() {
        I = this;
        // ajustes de una app de verdad: 60 fps, pantalla despierta y sin vsync del editor
        Application.targetFrameRate = 60;
        QualitySettings.vSyncCount = 0;
        Screen.sleepTimeout = SleepTimeout.NeverSleep;
    }

    /// <summary>Si el sistema se lleva la app a segundo plano, se guarda antes de que sea tarde.</summary>
    void OnApplicationPause(bool pausada) { if (pausada && _listo) Guardado.Guardar(); }
    void OnApplicationFocus(bool tiene)   { if (!tiene && _listo) Guardado.Guardar(); }
    void OnApplicationQuit()              { if (_listo) Guardado.Guardar(); }

    IEnumerator Start() {
        // ── arte ──
        Forja.GenerarTiles();      yield return null;
        Forja.GenerarVehiculos();  yield return null;
        Forja.GenerarProps();      yield return null;
        Fuente.GenerarIconos();
        Forja.GenerarArmas();      yield return null;

        // ── ciudad ──
        Ciudad.Generar();          yield return null;

        _mundo = new GameObject("Mundo").transform;
        _mundo.SetParent(transform, false);
        _render = _mundo.gameObject.AddComponent<RenderCiudad>();
        _render.Construir();       yield return null;

        _entidades = new GameObject("Entidades").transform;
        _entidades.SetParent(transform, false);

        Estado.ColocarSitios();
        var goProps = new GameObject("Mobiliario").transform;
        goProps.SetParent(_mundo, false);
        Mobiliario.Sembrar(goProps);
        yield return null;

        // ── cámara ──
        _cam = Camera.main;
        if (_cam == null) {
            var go = new GameObject("Main Camera");
            go.tag = "MainCamera";
            _cam = go.AddComponent<Camera>();
        }
        _cam.orthographic = true;
        _cam.orthographicSize = 7f;
        _cam.backgroundColor = Paleta.Negro;
        _cam.clearFlags = CameraClearFlags.SolidColor;

        // ── sistemas ──
        gameObject.AddComponent<Particulas>();
        gameObject.AddComponent<Combate>();
        gameObject.AddComponent<Misiones>();
        gameObject.AddComponent<Curros>();
        gameObject.AddComponent<AudioProc>();
        var hud = gameObject.AddComponent<Hud>();
        var menu = gameObject.AddComponent<MenuMovil>();
        var dlg = gameObject.AddComponent<Dialogo>();
        var mini = gameObject.AddComponent<Minijuego>();
        var ctrl = gameObject.AddComponent<Controles>();

        var canvas = MontarCanvas();
        _tinte = UiFab.Img(canvas.transform, null, Vector2.zero, Vector2.zero, Vector2.zero);
        var rtT = _tinte.rectTransform;
        rtT.anchorMin = Vector2.zero; rtT.anchorMax = Vector2.one;
        rtT.offsetMin = Vector2.zero; rtT.offsetMax = Vector2.zero;
        _tinte.color = new Color(0,0,0,0);
        _tinte.raycastTarget = false;

        hud.Montar(canvas);
        menu.Montar(canvas.transform);
        dlg.Montar(canvas.transform);
        mini.Montar(canvas.transform);
        ctrl.Montar(canvas.transform);

        // ── jugador y población ──
        var goJ = new GameObject("Jugador");
        goJ.transform.SetParent(_entidades, false);
        Jug = goJ.AddComponent<Jugador>();
        Jug.Preparar();
        Jug.Pos = Estado.Sitio_("piso").Pos;

        Poblar();
        MontarMarcas();

        Guardado.Cargar();
        _listo = true;
        Hud.I.Aviso("VIVE DONDE PUEDAS. COBRA DONDE TOQUE", 3.4f);
    }

    Canvas MontarCanvas() {
        var go = new GameObject("HUD", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
        go.transform.SetParent(transform, false);
        var c = go.GetComponent<Canvas>();
        c.renderMode = RenderMode.ScreenSpaceOverlay;
        var sc = go.GetComponent<CanvasScaler>();
        sc.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        sc.referenceResolution = new Vector2(400, 840);
        sc.matchWidthOrHeight = 0.5f;
        if (UnityEngine.EventSystems.EventSystem.current == null) {
            var es = new GameObject("EventSystem", typeof(UnityEngine.EventSystems.EventSystem),
                                    typeof(UnityEngine.EventSystems.StandaloneInputModule));
            es.transform.SetParent(transform, false);
        }
        return c;
    }

    void Poblar() {
        NuevoCoche(Estado.Sitio_("piso").Pos + new Vector2(1.4f,0), "utilitario", 0, true, 11f);
        for (int i = 0; i < 40; i++)
            NuevoCoche(Ciudad.PuntoCalle(), TiposCivil[i % TiposCivil.Length], (i+1) % Forja.Libreas.Length, false, 11f);
        for (int i = 0; i < 16; i++) NuevoTrafico();
        for (int i = 0; i < 26; i++) {
            var go = new GameObject("peaton");
            go.transform.SetParent(_entidades, false);
            var p = go.AddComponent<Peaton>();
            p.Preparar();
            p.Recolocar(Jug.Pos);
            Peatones.Add(p);
        }
    }

    void MontarMarcas() {
        foreach (var s in Estado.Sitios) {
            var go = new GameObject("marca_" + s.Id);
            go.transform.SetParent(_mundo, false);
            go.transform.position = Mundo.AMundo(s.Pos) + new Vector3(0, 0.9f, 0);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = Forja.Marca(s.Color);
            sr.sortingOrder = 9000;
            _marcas.Add(sr);
        }
    }

    public Vehiculo NuevoCoche(Vector2 p, string tipo, int librea, bool propio, float vmax) {
        var go = new GameObject("coche");
        go.transform.SetParent(_entidades, false);
        var v = go.AddComponent<Vehiculo>();
        v.Pos = p; v.Tipo = tipo; v.Librea = librea; v.Propio = propio; v.VMax = vmax;
        v.Preparar();
        Coches.Add(v);
        return v;
    }

    public Vehiculo MarcarCoche(Vector2 p) {
        var v = NuevoCoche(p, "berlina", 3, false, 11f);
        v.Marcado = true;
        return v;
    }

    void NuevoTrafico() {
        var go = new GameObject("trafico");
        go.transform.SetParent(_entidades, false);
        var r = go.AddComponent<Rejilla>();
        r.Preparar();
        Recolocar(r);
        Trafico.Add(r);
    }

    void Recolocar(Rejilla r) {
        var p = Ciudad.PuntoCalle(Mathf.RoundToInt(Jug.Pos.x), Mathf.RoundToInt(Jug.Pos.y), 44);
        bool pesado = Random.value < 0.18f;
        r.Pos = p; r.Tx = Mathf.FloorToInt(p.x); r.Ty = Mathf.FloorToInt(p.y);
        r.Tipo = pesado ? TiposPesado[Utiles.RndI(0,3)] : TiposCivil[Utiles.RndI(0,5)];
        r.Vel = pesado ? 2.7f : 3.7f;
        r.Librea = Utiles.RndI(0, Forja.Libreas.Length-1);
    }

    public void NuevaPatrulla(Vector2 p, float vel) {
        var go = new GameObject("patrulla");
        go.transform.SetParent(_entidades, false);
        var r = go.AddComponent<Rejilla>();
        r.Preparar();
        r.Pos = p; r.Tx = Mathf.FloorToInt(p.x); r.Ty = Mathf.FloorToInt(p.y);
        r.Vel = vel; r.Persigue = true; r.Tipo = "patrulla";
        Patrullas.Add(r);
    }

    public void NuevoEnemigo(Vector2 p, string arq, string arma, bool deMision, bool esPoli) {
        var go = new GameObject("enemigo");
        go.transform.SetParent(_entidades, false);
        var e = go.AddComponent<Enemigo>();
        e.Preparar();
        e.Pos = p; e.Arq = arq; e.ArmaId = arma; e.Hp = esPoli ? 55 : 60;
        e.DeMision = deMision; e.EsPoli = esPoli;
        Enemigos.Add(e);
    }

    public void QuitarEnemigo(Enemigo e) { Enemigos.Remove(e); Destroy(e.gameObject); }
    public void QuitarEnemigosDeMision() {
        for (int i = Enemigos.Count-1; i >= 0; i--) if (Enemigos[i].DeMision) QuitarEnemigo(Enemigos[i]);
    }
    public void QuitarPolisAPie() {
        for (int i = Enemigos.Count-1; i >= 0; i--) if (Enemigos[i].EsPoli) QuitarEnemigo(Enemigos[i]);
    }
    public int ContarPolisAPie() { int n = 0; foreach (var e in Enemigos) if (e.EsPoli) n++; return n; }
    public void QuitarUnaPatrulla() {
        if (Patrullas.Count == 0) return;
        var p = Patrullas[Patrullas.Count-1];
        Patrullas.RemoveAt(Patrullas.Count-1);
        Destroy(p.gameObject);
    }

    public void MostrarCiudad(bool v) {
        Jug.transform.SetParent(v ? _entidades : transform, true);
        _mundo.gameObject.SetActive(v);
        _entidades.gameObject.SetActive(v);
        Jug.gameObject.SetActive(true);
    }

    public Vector2? ObjetivoActual() {
        var m = Misiones.I.Objetivo();
        if (m.HasValue) return m;
        return Curros.I.Objetivo();
    }

    public void CambiarArma() {
        var E = Estado.I;
        var ids = new List<string>();
        foreach (var a in Armas.Todas)
            if (a.Id == "punos" || E.Mun(a.Id) > 0 || (a.Infinita && E.Municion.ContainsKey(a.Id))) ids.Add(a.Id);
        if (ids.Count < 2) return;
        int i = ids.IndexOf(E.ArmaAct);
        E.ArmaAct = ids[(i+1) % ids.Count];
        AudioProc.I.Sfx("caja", 0.5f);
    }

    // ═══════════ BUCLE ═══════════
    void Update() {
        if (!_listo) return;
        float dt = Time.deltaTime;
        var E = Estado.I;
        AudioProc.I.TicMusica(dt);

        if (E.Muerto > 0) {
            E.Muerto -= dt;
            AudioProc.I.MotorApagado();
            if (E.Muerto <= 0) Reaparecer();
            SeguirCamara(dt);
            return;
        }

        if (Minijuego.I.Abierto) { Minijuego.I.Tic(dt); return; }
        if (MenuMovil.I.AlgoAbierto) { AudioProc.I.MotorApagado(); return; }

        _autoT += dt;
        if (_autoT > 25f) { _autoT = 0; Guardado.Guardar(); }

        // reloj y necesidades
        _acum += dt;
        while (_acum > 0.45f) {
            _acum -= 0.45f;
            E.Min++;
            if (E.Min >= 1440) { E.Min = 0; E.Dia++; }
        }
        E.Hambre = Mathf.Max(0, E.Hambre - dt * 0.004f);
        E.Energia = Mathf.Max(0, E.Energia - dt * 0.0025f - (Controles.I.Correr && Jug.EnCoche == null ? dt * 0.01f : 0));
        if (E.Hambre <= 0) {
            E.Energia = Mathf.Max(0, E.Energia - dt * 0.017f);
            E.Hp = Mathf.Max(1, E.Hp - dt * 0.9f);
        }

        var eje = Controles.I.Eje;
        bool correr = Controles.I.Correr;
        if (Controles.I.AccionPulsada) { Controles.I.AccionPulsada = false; Acciones.Ejecutar(this); }
        var arma = Armas.De(E.ArmaAct);
        bool automatica = arma.Cad < 0.12f;
        if (Controles.I.AtacarPulsado || (automatica && Controles.I.AtacarMantenido)) {
            Controles.I.AtacarPulsado = false;
            if (Jug.EnCoche != null) { AudioProc.I.Sfx("claxon", 1f); Asustar(Jug.Pos, 7f); }
            else Acciones.Atacar(this);
        }

        if (E.EnInterior) {
            Jug.Mover(dt, eje, false);
            Acciones.PistaInterior(this);
            SeguirCamara(dt);
            return;
        }

        if (Jug.EnCoche != null) {
            Jug.EnCoche.Conducir(dt, eje, correr);
            Jug.Pos = Jug.EnCoche.Pos;
            float vf = Jug.EnCoche.VelAdelante;
            if (Mathf.Abs(vf) > 3.2f) {
                foreach (var p in Peatones)
                    if (Vector2.Distance(p.Pos, Jug.Pos) < 0.85f) {
                        Combate.I.Estrellas(1, this);
                        AudioProc.I.Sfx("grito", 0.8f);
                        Particulas.I.Emitir(Jug.Pos, "sangre", 7);
                        Hud.I.Aviso("¡ATROPELLO!");
                        p.Recolocar(Jug.Pos);
                    }
                for (int i = Enemigos.Count-1; i >= 0; i--) {
                    var e = Enemigos[i];
                    if (Vector2.Distance(e.Pos, Jug.Pos) < 0.9f) Combate.I.Danar(e, 55, this);
                }
            }
            Asustar(Jug.Pos, Mathf.Abs(vf) > 4 ? 4.5f : 2.2f);
        } else {
            AudioProc.I.MotorApagado();
            Jug.Mover(dt, eje, correr);
        }

        foreach (var t in Trafico) {
            t.Frenado = Jug.EnCoche != null && Vector2.Distance(t.Pos, Jug.Pos) < 2.2f;
            t.Tic(dt, Jug.Pos);
            if (Vector2.Distance(t.Pos, Jug.Pos) > 56f) Recolocar(t);
        }
        foreach (var p in Patrullas) p.Tic(dt, Jug.Pos);
        for (int i = Enemigos.Count-1; i >= 0; i--) {
            var e = Enemigos[i];
            if (Vector2.Distance(e.Pos, Jug.Pos) > 46f && !e.DeMision) { QuitarEnemigo(e); continue; }
            e.Tic(dt, Jug.Pos);
        }
        foreach (var p in Peatones) p.Tic(dt, Jug.Pos);

        Combate.I.TicBalas(dt, this);
        Combate.I.TicBusqueda(dt, this);
        Misiones.I.Tic(dt);
        Curros.I.Tic(dt);
        Acciones.Pista(this);
        SeguirCamara(dt);
        TinteBarrio(dt);
    }

    void Asustar(Vector2 p, float r) {
        foreach (var q in Peatones)
            if (Vector2.Distance(q.Pos, p) < r) q.Huye = 3.5f;
    }

    void SeguirCamara(float dt) {
        if (_cam == null) return;
        Vector2 objetivo = Jug.Pos;
        float zoom = 7f;
        if (Jug.EnCoche != null) {
            objetivo += Jug.EnCoche.Vel * 0.22f;
            zoom = 9.5f + Jug.EnCoche.Vel.magnitude * 0.25f;
        }
        var destino = Mundo.AMundo(objetivo);
        destino.z = -10;
        var suave = Vector3.Lerp(_cam.transform.position, destino, 1f - Mathf.Exp(-8f*dt));

        // Pixel perfect. Dos condiciones, y las dos hacen falta:
        //
        // 1. Un píxel de textura tiene que ocupar un número ENTERO de píxeles de pantalla.
        //    Como el sprite va a 32 px por unidad, eso fija el tamaño ortográfico: no se
        //    puede interpolar libremente o salen píxeles de tamaños distintos a la vez.
        // 2. La cámara tiene que caer en un múltiplo exacto de píxel de textura. Si se
        //    mueve en fracciones, el mundo entero tiembla al andar aunque cada sprite
        //    esté bien dibujado.
        int escala = Mathf.Max(1, Mathf.RoundToInt(Screen.height / (2f * Mundo.PPU * zoom)));
        _cam.orthographicSize = Screen.height / (2f * Mundo.PPU * escala);

        float paso = 1f / Mundo.PPU;
        _cam.transform.position = new Vector3(
            Mathf.Round(suave.x / paso) * paso,
            Mathf.Round(suave.y / paso) * paso,
            -10f);
    }

    void TinteBarrio(float dt) {
        var Z = Ciudad.ZonaDe(Mathf.Clamp((int)Jug.Pos.x,0,Ciudad.MW-1), Mathf.Clamp((int)Jug.Pos.y,0,Ciudad.MH-1));
        Color objetivo = Z.Tinte;
        objetivo.a = 0.13f;
        _tinteActual = Color.Lerp(_tinteActual, objetivo, dt * 0.6f);
        _tinte.color = _tinteActual;
    }

    void Reaparecer() {
        var E = Estado.I;
        E.Hp = 60;
        E.Dinero = Mathf.Max(0, E.Dinero - Mathf.Round(E.Dinero * 0.2f));
        E.Municion.Clear();
        E.ArmaAct = "punos";
        E.Estrellas = 0;
        while (Patrullas.Count > 0) QuitarUnaPatrulla();
        QuitarPolisAPie();
        Jug.EnCoche = null;
        Jug.Pos = Estado.Sitio_("hospital").Pos + new Vector2(0, 1.2f);
        if (Misiones.I.Activa != null) Misiones.I.Terminar(false);
        Hud.I.Aviso("HOSPITAL. TE HAN COBRADO EL RESCATE", 3f);
        Guardado.Guardar();
    }

    public void Detener() {
        var E = Estado.I;
        int multa = Mathf.RoundToInt(E.Dinero * 0.35f) + 30;
        E.Dinero = Mathf.Max(0, E.Dinero - multa);
        E.Estrellas = 0;
        while (Patrullas.Count > 0) QuitarUnaPatrulla();
        QuitarPolisAPie();
        if (Misiones.I.Activa != null) Misiones.I.Terminar(false);
        Curros.I.Cancelar();
        Jug.EnCoche = null;
        Jug.Pos = Estado.Sitio_("poli").Pos + new Vector2(0, 1.4f);
        Hud.I.Grande("DETENIDO", 2.2f);
        Hud.I.Aviso("MULTA DE " + multa + " €", 3f);
        Guardado.Guardar();
    }
}

}

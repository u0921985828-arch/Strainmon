using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace BilboCity {

/// <summary>Fábrica de trozos de interfaz, para no repetir el mismo boilerplate de uGUI.</summary>
public static class UiFab {
    public static Font Fuente0 { get { return Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf"); } }

    public static GameObject Panel(Transform padre, string nombre, Vector2 anchorMin, Vector2 anchorMax,
                                   Vector2 offMin, Vector2 offMax) {
        var go = new GameObject(nombre, typeof(RectTransform), typeof(Image));
        go.transform.SetParent(padre, false);
        var rt = go.GetComponent<RectTransform>();
        rt.anchorMin = anchorMin; rt.anchorMax = anchorMax;
        rt.offsetMin = offMin; rt.offsetMax = offMax;
        go.GetComponent<Image>().color = new Color(0.03f,0.04f,0.05f,0.96f);
        return go;
    }

    public static Text Texto(Transform padre, string nombre, int tam, TextAnchor anclaje,
                             Vector2 pos, float w, float h) {
        var go = new GameObject(nombre, typeof(RectTransform), typeof(Text));
        go.transform.SetParent(padre, false);
        var rt = go.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0.5f,0.5f); rt.anchorMax = new Vector2(0.5f,0.5f);
        rt.anchoredPosition = pos; rt.sizeDelta = new Vector2(w,h);
        var t = go.GetComponent<Text>();
        t.font = Fuente0; t.fontSize = tam; t.alignment = anclaje;
        t.color = Paleta.Hueso; t.horizontalOverflow = HorizontalWrapMode.Wrap;
        t.verticalOverflow = VerticalWrapMode.Overflow;
        return t;
    }

    public static GameObject Boton(Transform padre, string etiqueta, UnityEngine.Events.UnityAction accion) {
        var go = new GameObject("btn", typeof(RectTransform), typeof(Image), typeof(Button), typeof(LayoutElement));
        go.transform.SetParent(padre, false);
        go.GetComponent<Image>().color = new Color(0.12f,0.15f,0.19f,0.9f);
        go.GetComponent<Button>().onClick.AddListener(accion);
        var t = Texto(go.transform, "txt", 16, TextAnchor.MiddleCenter, Vector2.zero, 260, 40);
        t.text = etiqueta;
        var rt = t.GetComponent<RectTransform>();
        rt.anchorMin = Vector2.zero; rt.anchorMax = Vector2.one;
        rt.offsetMin = Vector2.zero; rt.offsetMax = Vector2.zero;
        return go;
    }

    public static Image Img(Transform padre, Sprite s, Vector2 anchor, Vector2 pos, Vector2 tam) {
        var go = new GameObject("img", typeof(RectTransform), typeof(Image));
        go.transform.SetParent(padre, false);
        var rt = go.GetComponent<RectTransform>();
        rt.anchorMin = rt.anchorMax = anchor;
        rt.pivot = new Vector2(0,1);
        rt.anchoredPosition = pos; rt.sizeDelta = tam;
        var im = go.GetComponent<Image>();
        im.sprite = s; im.raycastTarget = false;
        return im;
    }
}

/// <summary>Cadena de texto dibujada con la fuente de bits, reutilizando Images de un pool.</summary>
public class TextoBits {
    readonly Transform _padre;
    readonly List<Image> _pool = new List<Image>();
    public Vector2 Pos;
    public int Escala = 1;
    public Fuente.Tinta Tinta = Fuente.Tinta.Ambar;

    public TextoBits(Transform padre) { _padre = padre; }

    public void Escribir(string s) {
        s = s == null ? "" : s.ToUpperInvariant();
        int usados = 0;
        float cx = Pos.x;
        foreach (char ch in s) {
            if (ch == ' ') { cx += Fuente.ESPACIO * Escala; continue; }
            Image im;
            if (usados < _pool.Count) im = _pool[usados];
            else { im = UiFab.Img(_padre, null, new Vector2(0,1), Vector2.zero, Vector2.one); _pool.Add(im); }
            im.enabled = true;
            im.sprite = Fuente.Glifo(ch, Tinta);
            var rt = im.rectTransform;
            rt.anchoredPosition = new Vector2(cx, -Pos.y);
            rt.sizeDelta = new Vector2(Fuente.GW * Escala, Fuente.GH * Escala);
            cx += Fuente.AVANCE * Escala;
            usados++;
        }
        for (int i = usados; i < _pool.Count; i++) _pool[i].enabled = false;
    }

    public void Ocultar() { foreach (var im in _pool) im.enabled = false; }
}

/// <summary>
/// El HUD entero: radar circular con anillo de salud, estrellas, cartera, reloj,
/// barras de estado, panel de misión y arma. Todo con la fuente de bits.
/// </summary>
public class Hud : MonoBehaviour {
    public static Hud I;
    public Canvas Cnv;

    RawImage _radar;
    Texture2D _texRadar;
    Image _anillo, _flechaObj, _flash;
    Image[] _estrellas = new Image[5];
    // Sin esto el sigilo se juega a ciegas: no hay forma de saber si el que está enfrente
    // te ha visto o está mirando al escaparate.
    Image _icoOjo, _fondoOjo, _barraOjo;
    Image _icoEuro, _icoArma, _icoEnergia, _icoHambre;
    Image _barEnergia, _barHambre;
    TextoBits _tDinero, _tReloj, _tDia, _tBarrio, _tArma, _tMun, _tMision1, _tMision2, _tMision3, _tAviso, _tGrande, _tPista, _tDeuda;
    Image _panelMision, _panelArma, _panelAviso;
    float _avisoT, _grandeT, _flashT;
    string _aviso = "", _grande = "", _pista = "";
    Vector2Int _ultimaCasillaRadar = new Vector2Int(-999,-999);
    Color32[] _fondoRadar, _bufRadar;

    const int RADAR = 104;      // diámetro en píxeles de pantalla
    const int RADIO_TILES = 32; // cuánta ciudad se ve en el radar

    void Awake() { I = this; }

    public void Montar(Canvas canvas) {
        Cnv = canvas;
        var raiz = canvas.transform;

        // radar
        var goR = new GameObject("Radar", typeof(RectTransform), typeof(RawImage));
        goR.transform.SetParent(raiz, false);
        var rtR = goR.GetComponent<RectTransform>();
        rtR.anchorMin = rtR.anchorMax = new Vector2(0,1);
        rtR.pivot = new Vector2(0,1);
        rtR.anchoredPosition = new Vector2(10,-10);
        rtR.sizeDelta = new Vector2(RADAR, RADAR);
        _radar = goR.GetComponent<RawImage>();
        _texRadar = new Texture2D(RADIO_TILES*2, RADIO_TILES*2, TextureFormat.RGBA32, false);
        _texRadar.filterMode = FilterMode.Point;
        _radar.texture = _texRadar;
        _radar.raycastTarget = false;

        // anillo de salud
        _anillo = UiFab.Img(raiz, AnilloSprite(), new Vector2(0,1), new Vector2(4,-4), new Vector2(RADAR+12, RADAR+12));
        _anillo.type = Image.Type.Filled;
        _anillo.fillMethod = Image.FillMethod.Radial360;
        _anillo.fillOrigin = (int)Image.Origin360.Top;
        _anillo.fillClockwise = true;
        _anillo.color = Paleta.Sangre;

        _flechaObj = UiFab.Img(raiz, null, new Vector2(0,1), Vector2.zero, new Vector2(16,16));
        _flechaObj.enabled = false;

        // estrellas
        for (int i = 0; i < 5; i++)
            _estrellas[i] = UiFab.Img(raiz, Fuente.Ico["estrellaOff"], new Vector2(1,1),
                                      new Vector2(-26-i*20, -10), new Vector2(20,20));

        // el ojo del sigilo
        _icoOjo   = UiFab.Img(raiz, Fuente.Ico["ojoTachado"], new Vector2(1,1), new Vector2(-58,-120), new Vector2(20,20));
        _fondoOjo = UiFab.Img(raiz, null, new Vector2(1,1), new Vector2(-34,-125), new Vector2(32,8));
        _barraOjo = UiFab.Img(raiz, null, new Vector2(1,1), new Vector2(-34,-125), new Vector2(32,8));
        _fondoOjo.color = Paleta.Carbon;

        // cartera, reloj
        _icoEuro = UiFab.Img(raiz, Fuente.Ico["euro"], new Vector2(1,1), new Vector2(-136,-38), new Vector2(20,20));
        _tDinero = Nuevo(raiz, new Vector2(0,0), 2, Fuente.Tinta.Ambar);
        _tReloj  = Nuevo(raiz, new Vector2(0,0), 2, Fuente.Tinta.Hueso);
        _tDia    = Nuevo(raiz, new Vector2(0,0), 1, Fuente.Tinta.Hueso);

        // barras
        _icoEnergia = UiFab.Img(raiz, Fuente.Ico["energia"], new Vector2(0,1), new Vector2(10,-124), new Vector2(14,14));
        _icoHambre  = UiFab.Img(raiz, Fuente.Ico["hambre"],  new Vector2(0,1), new Vector2(10,-142), new Vector2(14,14));
        _barEnergia = Barra(raiz, new Vector2(28,-127), Paleta.H("#4d9de0"));
        _barHambre  = Barra(raiz, new Vector2(28,-145), Paleta.H("#e0a14d"));

        _tBarrio = Nuevo(raiz, new Vector2(10,164), 1, Fuente.Tinta.Hueso);
        _tDeuda  = Nuevo(raiz, new Vector2(10,178), 1, Fuente.Tinta.Rojo);

        // panel de misión
        _panelMision = UiFab.Img(raiz, Plano(new Color32(7,9,12,190)), new Vector2(0,1), new Vector2(10,-196), new Vector2(220,44));
        _tMision1 = Nuevo(raiz, new Vector2(16,200), 1, Fuente.Tinta.Ambar);
        _tMision2 = Nuevo(raiz, new Vector2(16,212), 1, Fuente.Tinta.Hueso);
        _tMision3 = Nuevo(raiz, new Vector2(16,224), 1, Fuente.Tinta.Ambar);

        // arma
        _panelArma = UiFab.Img(raiz, Plano(new Color32(7,9,12,190)), new Vector2(1,0), new Vector2(-150,236), new Vector2(140,38));
        _icoArma = UiFab.Img(raiz, Fuente.Ico["punos"], new Vector2(1,0), new Vector2(-146,232), new Vector2(22,22));
        _tArma = Nuevo(raiz, new Vector2(0,0), 1, Fuente.Tinta.Hueso);
        _tMun  = Nuevo(raiz, new Vector2(0,0), 2, Fuente.Tinta.Ambar);

        // avisos
        _panelAviso = UiFab.Img(raiz, Plano(new Color32(7,9,12,200)), new Vector2(0,1), Vector2.zero, new Vector2(10,26));
        _tAviso  = Nuevo(raiz, Vector2.zero, 2, Fuente.Tinta.Ambar);
        _tGrande = Nuevo(raiz, Vector2.zero, 3, Fuente.Tinta.Ambar);
        _tPista  = Nuevo(raiz, Vector2.zero, 1, Fuente.Tinta.Hueso);

        // flash de daño
        _flash = UiFab.Img(raiz, Plano(new Color32(193,54,43,255)), new Vector2(0,1), Vector2.zero, Vector2.zero);
        var rtF = _flash.rectTransform;
        rtF.anchorMin = Vector2.zero; rtF.anchorMax = Vector2.one;
        rtF.offsetMin = Vector2.zero; rtF.offsetMax = Vector2.zero;
        _flash.color = new Color(0.75f,0.21f,0.17f,0);
    }

    TextoBits Nuevo(Transform raiz, Vector2 pos, int esc, Fuente.Tinta tinta) {
        var t = new TextoBits(raiz) { Pos = pos, Escala = esc, Tinta = tinta };
        return t;
    }

    static Sprite Plano(Color32 c) {
        var L = new Lienzo(4,4); L.P(0,0,4,4,c);
        var px = new Color32[16];
        L.VolcarEn(px, 4, 4, 0, 0);
        return Utiles.Rebanada(Utiles.Textura(4,4,px), 0, 0, 4, 4, 0, 0);
    }

    static Sprite AnilloSprite() {
        int R = 64;
        var L = new Lienzo(R*2, R*2);
        for (int y = 0; y < R*2; y++)
            for (int x = 0; x < R*2; x++) {
                float d = Mathf.Sqrt((x-R)*(x-R) + (y-R)*(y-R));
                if (d < R-6 || d > R-1) continue;
                L.Px[y*R*2+x] = Paleta.Sangre;
            }
        var px = new Color32[R*2*R*2];
        L.VolcarEn(px, R*2, R*2, 0, 0);
        return Utiles.Rebanada(Utiles.Textura(R*2, R*2, px), 0, 0, R*2, R*2, R, R);
    }

    Image Barra(Transform raiz, Vector2 pos, Color32 col) {
        UiFab.Img(raiz, Plano(new Color32(7,9,12,200)), new Vector2(0,1), pos, new Vector2(76,8));
        var im = UiFab.Img(raiz, Plano(col), new Vector2(0,1), pos + new Vector2(1,-1), new Vector2(74,6));
        im.type = Image.Type.Filled;
        im.fillMethod = Image.FillMethod.Horizontal;
        return im;
    }

    public void Aviso(string t, float s = 2.4f) { _aviso = t == null ? "" : t.ToUpperInvariant(); _avisoT = s; }
    public void Grande(string t, float s = 2.2f) { _grande = t == null ? "" : t.ToUpperInvariant(); _grandeT = s; }
    public void Pista(string t) { _pista = t == null ? "" : t.ToUpperInvariant(); }
    public void Flash() { _flashT = 0.3f; }

    void Update() {
        float dt = Time.deltaTime;
        var E = Estado.I;
        var J = Juego.I;
        if (J == null || J.Jug == null) return;

        if (_avisoT > 0) _avisoT -= dt;
        if (_grandeT > 0) _grandeT -= dt;
        if (_flashT > 0) { _flashT -= dt; var c = _flash.color; c.a = Mathf.Max(0,_flashT); _flash.color = c; }

        // ── radar ──
        PintarRadar(J);
        _anillo.fillAmount = Mathf.Clamp01(E.Hp / 100f);
        _anillo.color = E.Hp > 50 ? (Color)Paleta.Sangre : E.Hp > 25 ? (Color)Paleta.RojoL : new Color(1f,0.23f,0.19f);

        var obj = J.ObjetivoActual();
        if (obj.HasValue && !E.EnInterior) {
            Vector2 d = obj.Value - J.Jug.Pos;
            int d8 = ForjaChar.Dir8(d.x, d.y);
            float ang = Mathf.Atan2(d.y, d.x);
            _flechaObj.enabled = true;
            _flechaObj.sprite = Forja.Flecha(d8, Paleta.Mostaza);
            _flechaObj.rectTransform.anchoredPosition =
                new Vector2(10 + RADAR/2f + Mathf.Cos(ang)*(RADAR/2f-14) - 8,
                            -(10 + RADAR/2f + Mathf.Sin(ang)*(RADAR/2f-14) - 8));
        } else _flechaObj.enabled = false;

        // ── estrellas ──
        for (int i = 0; i < 5; i++)
            _estrellas[i].sprite = i < E.Estrellas ? Fuente.Ico["estrella"] : Fuente.Ico["estrellaOff"];

        // ── el ojo ──
        // Se abre según lo que le falta a la sospecha para llenarse, y se pone en rojo
        // cuando ya te tienen.
        bool hayOjo = E.Sospecha > 0.02f || E.Visto;
        _icoOjo.enabled = _fondoOjo.enabled = _barraOjo.enabled = hayOjo;
        if (hayOjo) {
            _icoOjo.sprite = Fuente.Ico[E.Visto ? "ojo" : "ojoTachado"];
            _barraOjo.color = E.Sospecha >= 1f ? Paleta.Sangre
                            : E.Sospecha > 0.5f ? Paleta.Mostaza : Paleta.Acero;
            var rt = _barraOjo.GetComponent<RectTransform>();
            rt.sizeDelta = new Vector2(Mathf.Round(32f * Mathf.Clamp01(E.Sospecha)), 8f);
        }

        // ── textos ──
        var rtC = Cnv.GetComponent<RectTransform>();
        int w = Mathf.RoundToInt(rtC.rect.width);
        int h = Mathf.RoundToInt(rtC.rect.height);

        string din = Mathf.RoundToInt(E.Dinero).ToString();
        _tDinero.Pos = new Vector2(w - 112, 40); _tDinero.Escribir(din);
        string hr = (E.Min/60).ToString("00") + ":" + (E.Min%60).ToString("00");
        _tReloj.Pos = new Vector2(w - 112, 66); _tReloj.Escribir(hr);
        _tDia.Pos = new Vector2(w - 112, 88); _tDia.Escribir("DIA " + E.Dia);

        _barEnergia.fillAmount = Mathf.Clamp01(E.Energia);
        _barHambre.fillAmount = Mathf.Clamp01(E.Hambre);

        string barrio = E.EnInterior && Interiores.Actual != null
            ? Interiores.Actual.Nombre
            : Ciudad.BarrioDe(Mathf.Clamp((int)J.Jug.Pos.x,0,Ciudad.MW-1), Mathf.Clamp((int)J.Jug.Pos.y,0,Ciudad.MH-1)).Nombre;
        _tBarrio.Escribir(barrio);
        if (E.Deuda > 0) _tDeuda.Escribir("ALQUILER " + E.Deuda + " €"); else _tDeuda.Ocultar();

        // ── arma ──
        var a = Armas.De(E.ArmaAct);
        _icoArma.sprite = Fuente.Ico.ContainsKey(a.Id) ? Fuente.Ico[a.Id] : Fuente.Ico["punos"];
        _tArma.Pos = new Vector2(w - 118, h - 268); _tArma.Escribir(a.Nombre);
        _tMun.Pos  = new Vector2(w - 118, h - 254); _tMun.Escribir(a.Infinita && a.Id == "punos" ? "8" : E.Mun(a.Id).ToString());

        // ── misión ──
        bool hayMision = !E.EnInterior && (Misiones.I.Activa != null || Curros.I.Activo != null);
        _panelMision.enabled = hayMision;
        if (hayMision) {
            string t1, t2, t3;
            float dm = obj.HasValue ? Vector2.Distance(obj.Value, J.Jug.Pos) * 8f : 0;
            if (Misiones.I.Activa != null) {
                t1 = Misiones.I.Activa.Def.Nombre;
                t2 = Misiones.I.Activa.Actual != null ? Misiones.I.Activa.Actual.Texto : "";
                t3 = Mathf.RoundToInt(dm) + " M";
                if (Misiones.I.Activa.Limite > 0)
                    t3 += "  " + Mathf.Max(0, Mathf.CeilToInt(Misiones.I.Activa.Limite - Misiones.I.Activa.T)) + " S";
            } else {
                t1 = Curros.I.Activo.Titulo;
                t2 = Curros.I.Fase == 0 ? "RECOGIDA" : "ENTREGA";
                t3 = Mathf.RoundToInt(dm) + " M  " + Curros.I.Pago + " €";
            }
            _tMision1.Escribir(t1); _tMision2.Escribir(t2); _tMision3.Escribir(t3);
        } else { _tMision1.Ocultar(); _tMision2.Ocultar(); _tMision3.Ocultar(); }

        // ── aviso, rótulo, pista ──
        if (_avisoT > 0 && _aviso.Length > 0) {
            int esc = 2;
            while (esc > 1 && Fuente.Ancho(_aviso, esc) > w - 30) esc--;
            _tAviso.Escala = esc;
            int aw = Fuente.Ancho(_aviso, esc);
            _tAviso.Pos = new Vector2((w - aw)/2f, h*0.42f);
            _tAviso.Escribir(_aviso);
            _panelAviso.enabled = true;
            _panelAviso.rectTransform.anchoredPosition = new Vector2((w-aw)/2f - 8, -(h*0.42f - 4));
            _panelAviso.rectTransform.sizeDelta = new Vector2(aw + 16, 11*esc + 8);
        } else { _tAviso.Ocultar(); _panelAviso.enabled = false; }

        if (_grandeT > 0 && _grande.Length > 0) {
            int esc = 3;
            while (esc > 1 && Fuente.Ancho(_grande, esc) > w - 20) esc--;
            _tGrande.Escala = esc;
            _tGrande.Pos = new Vector2((w - Fuente.Ancho(_grande, esc))/2f, h*0.3f);
            _tGrande.Escribir(_grande);
        } else _tGrande.Ocultar();

        if (_pista.Length > 0) {
            _tPista.Pos = new Vector2((w - Fuente.Ancho(_pista,1))/2f, h - 200);
            _tPista.Escribir(_pista);
        } else _tPista.Ocultar();
    }

    void PintarRadar(Juego J) {
        int cx = Mathf.RoundToInt(J.Jug.Pos.x), cy = Mathf.RoundToInt(J.Jug.Pos.y);
        int R = RADIO_TILES;
        if (_fondoRadar == null) { _fondoRadar = new Color32[R*2*R*2]; _bufRadar = new Color32[R*2*R*2]; }
        var casilla = new Vector2Int(cx, cy);
        if (casilla == _ultimaCasillaRadar) { PintarBlips(J, cx, cy); return; }
        _ultimaCasillaRadar = casilla;
        var px = _fondoRadar;
        for (int y = 0; y < R*2; y++)
            for (int x = 0; x < R*2; x++) {
                int mx = cx - R + x, my = cy - R + y;
                Color32 c;
                if (mx < 0 || my < 0 || mx >= Ciudad.MW || my >= Ciudad.MH) c = Paleta.Negro;
                else {
                    switch (Ciudad.T(mx,my)) {
                        case Suelo.Agua:   c = Paleta.Agua; break;
                        case Suelo.Edif:   c = Paleta.H("#262a30"); break;
                        case Suelo.Parque: c = Paleta.H("#2e4a2e"); break;
                        case Suelo.Plaza:  c = Paleta.H("#5c574d"); break;
                        case Suelo.Muelle: c = Paleta.H("#453d33"); break;
                        case Suelo.Patio:  c = Paleta.H("#3a3630"); break;
                        case Suelo.Puente: c = Paleta.GrisL; break;
                        default:           c = Paleta.H("#4a505a"); break;
                    }
                }
                // fuera del círculo, transparente
                float dd = Mathf.Sqrt((x-R)*(x-R) + (y-R)*(y-R));
                if (dd > R) c = new Color32(0,0,0,0);
                px[(R*2-1-y)*R*2 + x] = c;
            }
        PintarBlips(J, cx, cy);
    }

    void PintarBlips(Juego J, int cx, int cy) {
        // se parte del fondo cacheado, se pintan los puntos y se sube una sola vez
        int R = RADIO_TILES;
        System.Array.Copy(_fondoRadar, _bufRadar, _fondoRadar.Length);
        var buf = _bufRadar;
        void Punto(Vector2 p, Color32 c, int tam) {
            int x = Mathf.RoundToInt(p.x) - cx + R, y = Mathf.RoundToInt(p.y) - cy + R;
            for (int dy = -tam; dy <= tam; dy++)
                for (int dx = -tam; dx <= tam; dx++) {
                    int px = x+dx, py = y+dy;
                    if (px < 0 || py < 0 || px >= R*2 || py >= R*2) continue;
                    buf[(R*2-1-py)*R*2 + px] = c;
                }
        }
        foreach (var s in Estado.Sitios) Punto(s.Pos, s.Color, 1);
        var obj = J.ObjetivoActual();
        if (obj.HasValue) Punto(obj.Value, Paleta.Mostaza, 2);
        foreach (var p in J.Patrullas) Punto(p.Pos, Paleta.H("#4d9dff"), 1);
        foreach (var e in J.Enemigos) Punto(e.Pos, Paleta.H("#ff5a3c"), 1);
        Punto(J.Jug.Pos, Paleta.Blanco, 1);
        _texRadar.SetPixels32(buf);
        _texRadar.Apply();
    }
}

}

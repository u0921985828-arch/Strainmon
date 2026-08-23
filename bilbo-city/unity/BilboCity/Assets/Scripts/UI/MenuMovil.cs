using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace BilboCity {

public class Articulo {
    public string Icono, Titulo, Desc;
    public int Precio;
    public Func<bool> YaLoTiene;
    public Action Comprar;
}

/// <summary>El móvil (historia, curros, fama), la pausa y las tiendas.</summary>
public class MenuMovil : MonoBehaviour {
    public static MenuMovil I;
    public bool Abierto, Pausado;

    GameObject _panel, _panelPausa, _panelTienda;
    Transform _lista, _listaPausa, _listaTienda;
    Text _tituloTienda;
    string _pestana = "hist";

    void Awake() { I = this; }

    public void Montar(Transform canvas) {
        _panel = Pantalla(canvas, "Movil", out _lista, new[]{"HISTORIA","CURROS","FAMA"},
                          i => { _pestana = i == 0 ? "hist" : i == 1 ? "trab" : "rep"; Pintar(); },
                          () => { Abierto = false; _panel.SetActive(false); });
        _panelPausa = Pantalla(canvas, "Pausa", out _listaPausa, new[]{"DATOS","OPCIONES"},
                          i => PintarPausa(i), () => { Pausado = false; _panelPausa.SetActive(false); });
        _panelTienda = Pantalla(canvas, "Tienda", out _listaTienda, null, null,
                          () => _panelTienda.SetActive(false));
        _tituloTienda = UiFab.Texto(_panelTienda.transform, "Titulo", 22, TextAnchor.UpperLeft,
                                    new Vector2(0,0), 300, 30);
        var rt = _tituloTienda.rectTransform;
        rt.anchorMin = new Vector2(0,1); rt.anchorMax = new Vector2(0,1);
        rt.pivot = new Vector2(0,1); rt.anchoredPosition = new Vector2(14,-14);
    }

    GameObject Pantalla(Transform canvas, string nombre, out Transform lista, string[] pestanas,
                        Action<int> alCambiar, Action alCerrar) {
        var panel = UiFab.Panel(canvas, nombre, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
        panel.SetActive(false);

        var scroll = new GameObject("Scroll", typeof(RectTransform), typeof(ScrollRect), typeof(Image), typeof(Mask));
        scroll.transform.SetParent(panel.transform, false);
        var srt = scroll.GetComponent<RectTransform>();
        srt.anchorMin = Vector2.zero; srt.anchorMax = Vector2.one;
        srt.offsetMin = new Vector2(12, 66); srt.offsetMax = new Vector2(-12, -100);
        scroll.GetComponent<Image>().color = new Color(0,0,0,0.01f);

        var cont = new GameObject("Contenido", typeof(RectTransform), typeof(VerticalLayoutGroup), typeof(ContentSizeFitter));
        cont.transform.SetParent(scroll.transform, false);
        var crt = cont.GetComponent<RectTransform>();
        crt.anchorMin = new Vector2(0,1); crt.anchorMax = new Vector2(1,1); crt.pivot = new Vector2(0.5f,1);
        var vl = cont.GetComponent<VerticalLayoutGroup>();
        vl.spacing = 7; vl.childForceExpandHeight = false; vl.childControlHeight = true;
        cont.GetComponent<ContentSizeFitter>().verticalFit = ContentSizeFitter.FitMode.PreferredSize;
        var sr = scroll.GetComponent<ScrollRect>();
        sr.content = crt; sr.horizontal = false;
        lista = cont.transform;

        if (pestanas != null) {
            var fila = new GameObject("Pestanas", typeof(RectTransform), typeof(HorizontalLayoutGroup));
            fila.transform.SetParent(panel.transform, false);
            var frt = fila.GetComponent<RectTransform>();
            frt.anchorMin = new Vector2(0,1); frt.anchorMax = new Vector2(1,1); frt.pivot = new Vector2(0.5f,1);
            frt.anchoredPosition = new Vector2(0,-58); frt.sizeDelta = new Vector2(-24, 34);
            var hl = fila.GetComponent<HorizontalLayoutGroup>();
            hl.spacing = 5; hl.childForceExpandWidth = true; hl.childControlWidth = true;
            for (int i = 0; i < pestanas.Length; i++) {
                int idx = i;
                UiFab.Boton(fila.transform, pestanas[i], () => { if (alCambiar != null) alCambiar(idx); });
            }
        }
        var cerrar = UiFab.Boton(panel.transform, "CERRAR", () => { if (alCerrar != null) alCerrar(); });
        var rt2 = cerrar.GetComponent<RectTransform>();
        rt2.anchorMin = new Vector2(0,0); rt2.anchorMax = new Vector2(1,0); rt2.pivot = new Vector2(0.5f,0);
        rt2.anchoredPosition = new Vector2(0,12); rt2.sizeDelta = new Vector2(-24, 44);
        return panel;
    }

    void Limpiar(Transform t) { foreach (Transform h in t) Destroy(h.gameObject); }

    GameObject Fila(Transform padre, string icono, string titulo, string desc, string derecha,
                    Action alTocar, Color32 borde) {
        var go = new GameObject("fila", typeof(RectTransform), typeof(Image), typeof(LayoutElement), typeof(Button));
        go.transform.SetParent(padre, false);
        go.GetComponent<Image>().color = new Color(0.08f,0.10f,0.13f,0.95f);
        go.GetComponent<LayoutElement>().minHeight = 56;
        if (alTocar != null) go.GetComponent<Button>().onClick.AddListener(() => alTocar());

        var barra = UiFab.Img(go.transform, null, new Vector2(0,1), Vector2.zero, new Vector2(4,56));
        barra.color = borde;

        var t1 = UiFab.Texto(go.transform, "t", 17, TextAnchor.UpperLeft, Vector2.zero, 220, 22);
        t1.text = (icono ?? "") + " " + titulo;
        var r1 = t1.rectTransform;
        r1.anchorMin = new Vector2(0,1); r1.anchorMax = new Vector2(0,1); r1.pivot = new Vector2(0,1);
        r1.anchoredPosition = new Vector2(12,-6);

        var t2 = UiFab.Texto(go.transform, "d", 12, TextAnchor.UpperLeft, Vector2.zero, 230, 30);
        t2.text = desc; t2.color = Paleta.Acero;
        var r2 = t2.rectTransform;
        r2.anchorMin = new Vector2(0,1); r2.anchorMax = new Vector2(0,1); r2.pivot = new Vector2(0,1);
        r2.anchoredPosition = new Vector2(12,-28);

        if (!string.IsNullOrEmpty(derecha)) {
            var t3 = UiFab.Texto(go.transform, "p", 18, TextAnchor.MiddleRight, Vector2.zero, 90, 30);
            t3.text = derecha; t3.color = Paleta.Mostaza;
            var r3 = t3.rectTransform;
            r3.anchorMin = new Vector2(1,0.5f); r3.anchorMax = new Vector2(1,0.5f); r3.pivot = new Vector2(1,0.5f);
            r3.anchoredPosition = new Vector2(-12,0);
        }
        return go;
    }

    public void Alternar() {
        Abierto = !Abierto;
        _panel.SetActive(Abierto);
        if (Abierto) Pintar();
    }
    public void AlternarPausa() {
        Pausado = !Pausado;
        _panelPausa.SetActive(Pausado);
        if (Pausado) PintarPausa(0);
    }

    void Pintar() {
        Limpiar(_lista);
        var E = Estado.I;
        if (_pestana == "hist") {
            var m = Misiones.I.Siguiente();
            if (Misiones.I.Activa != null)
                Fila(_lista, "🎯", Misiones.I.Activa.Def.Nombre,
                     Misiones.I.Activa.Actual != null ? Misiones.I.Activa.Actual.Texto : "", "", null, Paleta.Mostaza);
            else if (m != null)
                Fila(_lista, "❗", m.Nombre, "Te espera " + m.Giver + " en " + m.Donde + ".", m.Pago + " €", null, Paleta.Mostaza);
            else
                Fila(_lista, "🏁", "Historia terminada", "Bilbao es tuya. O al menos el Casco Viejo.", "", null, Paleta.Mostaza);
            Fila(_lista, "📖", "Progreso", E.MisionIdx + " de " + Misiones.Lista.Count + " misiones", "", null, Paleta.Acero);
        } else if (_pestana == "trab") {
            if (Misiones.I.Activa != null)
                Fila(_lista, "⛔", "Estás en una misión", "Termínala o abandónala.", "", null, Paleta.Gris);
            foreach (var c in Estado.ListaCurros) {
                var curro = c;
                bool ok = E.Disponible(c) && Misiones.I.Activa == null;
                int pago = E.PagoDe(c);
                string desc = E.Disponible(c) ? c.Desc
                    : "Necesitas " + (c.NecesitaFurgo && !E.TieneFurgo ? "furgoneta" : "nivel " + c.Req + " en " + c.Gremio);
                Fila(_lista, c.Icono, c.Titulo, desc, pago + " €",
                     ok ? (Action)(() => { Curros.I.Aceptar(curro, pago); Alternar(); }) : null,
                     c.Turbio ? Paleta.Morado : Paleta.VerdeL);
            }
        } else {
            foreach (var g in new[]{"hosteleria","obra","transporte","calle"}) {
                var c = E.ContratoDe(g);
                string desc = "nivel " + E.Nivel(g) + " · ×" + E.Multip(g).ToString("0.00");
                if (c != null) desc += "  ·  contrato " + c.Hechos + "/" + c.Meta;
                Fila(_lista, "📊", g, desc, c != null ? c.Bonus + " €" : "", null,
                     c != null ? Paleta.VerdeL : Paleta.Mostaza);
            }
            if (E.Deuda > 0)
                Fila(_lista, "🔑", "Pagar alquiler", "Transferencia a la casera", E.Deuda + " €", () => {
                    if (E.Dinero < E.Deuda) { Hud.I.Aviso("NO TE LLEGA"); return; }
                    E.Dinero -= E.Deuda; E.Deuda = 0;
                    AudioProc.I.Sfx("dinero", 1f);
                    Hud.I.Aviso("ALQUILER AL DÍA");
                    Guardado.Guardar(); Pintar();
                }, Paleta.Morado);
        }
    }

    void PintarPausa(int tab) {
        Limpiar(_listaPausa);
        var E = Estado.I;
        if (tab == 0) {
            var J = Juego.I;
            Fila(_listaPausa, "", "Dinero", "", Mathf.RoundToInt(E.Dinero) + " €", null, Paleta.Mostaza);
            Fila(_listaPausa, "", "Día", "", E.Dia.ToString(), null, Paleta.Acero);
            Fila(_listaPausa, "", "Misiones", "", E.MisionIdx + "/" + Misiones.Lista.Count, null, Paleta.Acero);
            Fila(_listaPausa, "", "Salud", "", Mathf.RoundToInt(E.Hp) + "%", null, Paleta.Sangre);
            Fila(_listaPausa, "", "Arma", "", Armas.De(E.ArmaAct).Nombre, null, Paleta.Acero);
            Fila(_listaPausa, "", "Barrio", "",
                 Ciudad.ZonaDe(Mathf.Clamp((int)J.Jug.Pos.x,0,Ciudad.MW-1), Mathf.Clamp((int)J.Jug.Pos.y,0,Ciudad.MH-1)).Nombre,
                 null, Paleta.Acero);
        } else {
            Fila(_listaPausa, "", "Efectos de sonido", "", AudioProc.I.Sonido ? "ON" : "OFF",
                 () => { AudioProc.I.Sonido = !AudioProc.I.Sonido; PintarPausa(1); }, Paleta.Acero);
            Fila(_listaPausa, "", "Música", "", AudioProc.I.Musica ? "ON" : "OFF",
                 () => { AudioProc.I.Musica = !AudioProc.I.Musica; PintarPausa(1); }, Paleta.Acero);
            Fila(_listaPausa, "", "Guardar partida", "", "💾",
                 () => { Guardado.Guardar(); Hud.I.Aviso("GUARDADO"); }, Paleta.VerdeL);
            Fila(_listaPausa, "", "Empezar de cero", "", "🗑",
                 () => { Guardado.Borrar(); UnityEngine.SceneManagement.SceneManager.LoadScene(
                     UnityEngine.SceneManagement.SceneManager.GetActiveScene().buildIndex); }, Paleta.Morado);
        }
    }

    public void AbrirTienda(string titulo, List<Articulo> arts) {
        _tituloTienda.text = titulo;
        Limpiar(_listaTienda);
        foreach (var a in arts) {
            var art = a;
            bool puede = Estado.I.Dinero >= a.Precio && !a.YaLoTiene();
            Fila(_listaTienda, a.Icono, a.Titulo, a.YaLoTiene() ? "Ya lo tienes" : a.Desc, a.Precio + " €",
                 puede ? (Action)(() => {
                     Estado.I.Dinero -= art.Precio;
                     art.Comprar();
                     AudioProc.I.Sfx("dinero", 1f);
                     _panelTienda.SetActive(false);
                     Guardado.Guardar();
                 }) : null,
                 puede ? Paleta.VerdeL : Paleta.Gris);
        }
        _panelTienda.SetActive(true);
    }

    public bool AlgoAbierto { get { return Abierto || Pausado || _panelTienda.activeSelf || Dialogo.I.Abierto || Minijuego.I.Abierto; } }
}

}

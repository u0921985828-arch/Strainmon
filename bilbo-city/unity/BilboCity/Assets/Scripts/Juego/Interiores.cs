using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace BilboCity {

public class NpcInterior {
    public float X, Y;
    public string Nombre, Arq, Tipo;
}

public class DefInterior {
    public string Nombre, Suelo, Pared;
    public string[] Mapa;
    public NpcInterior[] Npcs;
}

/// <summary>Los siete sitios en los que se entra: bar, piso, taller, armería, mercado, hospital y portal.</summary>
public static class Interiores {
    public static DefInterior Actual;
    public static Vector2 Volver;
    static GameObject _raiz;

    public static readonly Dictionary<string, DefInterior> Todos = new Dictionary<string, DefInterior> {
        {"bar", new DefInterior{ Nombre="Bar Zurito", Suelo="terrazo", Pared="paredAzul", Mapa=new[]{
            "################","#BBBBBBBB.....W#","#..............#","#..MM....MM....#",
            "#..MM....MM....#","#..............#","#..MM....MM....#","#..MM....MM....#",
            "#..............#","#######DD#######"},
            Npcs=new[]{
                new NpcInterior{ X=3.5f, Y=2.6f, Nombre="Josu", Arq="josu", Tipo="barman" },
                new NpcInterior{ X=11.5f, Y=2.6f, Nombre="Txema", Arq="txema", Tipo="jefe" },
                new NpcInterior{ X=6.5f, Y=8.4f, Nombre="Mikel", Arq="mikel", Tipo="parroquiano" }}}},
        {"piso", new DefInterior{ Nombre="Tu piso", Suelo="hidraulico", Pared="paredBlanca", Mapa=new[]{
            "##############","#CC.......WWW#","#CC..........#","#............#",
            "#....MM......#","#....MM......#","#............#","#####DD#######"},
            Npcs=new NpcInterior[0]}},
        {"taller", new DefInterior{ Nombre="Taller Iker", Suelo="sueloTaller", Pared="paredChapa", Mapa=new[]{
            "################","#VVVV....VVVV.W#","#VVVV....VVVV..#","#..............#",
            "#..............#","#....WW........#","#######DD#######"},
            Npcs=new[]{ new NpcInterior{ X=7.5f, Y=4.5f, Nombre="Iker", Arq="iker", Tipo="mecanico" }}}},
        {"armeria", new DefInterior{ Nombre="Bazar Nervión", Suelo="sueloTaller", Pared="pared", Mapa=new[]{
            "#############","#XXXXXXXXXXX#","#...........#","#..EE...EE..#",
            "#...........#","#....OO.....#","#####DD#####"},
            Npcs=new[]{ new NpcInterior{ X=6.5f, Y=4.5f, Nombre="Koldo", Arq="koldo", Tipo="armero" }}}},
        {"merca", new DefInterior{ Nombre="Mercado de la Ribera", Suelo="terrazo", Pared="paredChapa", Mapa=new[]{
            "#################","#PPPP...PPPP..PP#","#...............#","#..PPPP...PPPP..#",
            "#...............#","########DD#######"},
            Npcs=new[]{ new NpcInterior{ X=3.5f, Y=2.6f, Nombre="Bego", Arq="bego", Tipo="pescatera" }}}},
        {"hospital", new DefInterior{ Nombre="Hospital de Basurto", Suelo="sueloHosp", Pared="paredBlanca", Mapa=new[]{
            "###############","#LL...LL...QQ.#","#LL...LL......#","#.............#",
            "#SSSS....OOOO.#","#.............#","######DD######"},
            Npcs=new[]{ new NpcInterior{ X=9.5f, Y=5.5f, Nombre="Nekane", Arq="enfermera", Tipo="enfermera" }}}},
        {"portal", new DefInterior{ Nombre="Portal · la casera", Suelo="hidraulico", Pared="paredBlanca", Mapa=new[]{
            "############","#....WW....#","#..........#","#..........#","#####DD#####"},
            Npcs=new[]{ new NpcInterior{ X=6.5f, Y=2.5f, Nombre="Amaia", Arq="amaia", Tipo="casera" }}}},
    };

    static readonly Dictionary<char,string> TileDe = new Dictionary<char,string> {
        {'#',"pared"},{'B',"barra"},{'M',"mesa"},{'C',"cama"},{'W',"mueble"},{'X',"vitrina"},
        {'P',"puesto"},{'V',"cocheEx"},{'O',"mostrador"},{'Q',"taquilla"},{'S',"sillas"},
        {'E',"estante"},{'L',"camilla"}
    };

    public static char Casilla(float x, float y) {
        if (Actual == null) return '#';
        int fy = Mathf.FloorToInt(y), fx = Mathf.FloorToInt(x);
        if (fy < 0 || fy >= Actual.Mapa.Length) return '#';
        var fila = Actual.Mapa[fy];
        if (fx < 0 || fx >= fila.Length) return '#';
        return fila[fx];
    }
    public static bool Solido(float x, float y) { return "#BMCWXPVOQEL".IndexOf(Casilla(x,y)) >= 0; }

    public static void Entrar(string id, Vector2 desde) {
        Actual = Todos[id];
        Volver = desde;
        Estado.I.EnInterior = true;
        var J = Juego.I;
        J.Jug.EnCoche = null;
        for (int y = 0; y < Actual.Mapa.Length; y++)
            for (int x = 0; x < Actual.Mapa[y].Length; x++)
                if (Actual.Mapa[y][x] == 'D') { J.Jug.Pos = new Vector2(x + 0.5f, y - 0.7f); }
        J.Jug.Dir8 = 4;
        Construir();
        J.MostrarCiudad(false);
    }

    public static void Salir() {
        Estado.I.EnInterior = false;
        Actual = null;
        if (_raiz != null) UnityEngine.Object.Destroy(_raiz);
        _raiz = null;
        var J = Juego.I;
        J.Jug.Pos = Volver + new Vector2(0, 1.2f);
        J.MostrarCiudad(true);
    }

    static void Construir() {
        if (_raiz != null) UnityEngine.Object.Destroy(_raiz);
        _raiz = new GameObject("Interior");
        var m = Actual.Mapa;
        var suelo = Forja.Tiles[Actual.Suelo];
        var pared = Forja.Tiles[Actual.Pared];
        for (int y = 0; y < m.Length; y++)
            for (int x = 0; x < m[y].Length; x++) {
                Poner(suelo, x, y, -200);
                char ch = m[y][x];
                if (ch == 'D') continue;
                string clave;
                if (ch == '#') Poner(pared, x, y, -199);
                else if (TileDe.TryGetValue(ch, out clave)) Poner(Forja.Tiles[clave], x, y, -199);
            }
        foreach (var n in Actual.Npcs) {
            var go = new GameObject("npc_" + n.Nombre);
            go.transform.SetParent(_raiz.transform, false);
            go.transform.position = Mundo.AMundo(new Vector2(n.X, n.Y));
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = ForjaChar.Frame(n.Arq, Pose.Quieto, 0);
            sr.sortingOrder = Mundo.OrdenY(n.Y);
        }
    }

    static void Poner(Sprite s, int x, int y, int orden) {
        var go = new GameObject("t");
        go.transform.SetParent(_raiz.transform, false);
        go.transform.position = Mundo.AMundo(new Vector2(x, y + 1));
        var sr = go.AddComponent<SpriteRenderer>();
        sr.sprite = s;
        sr.sortingOrder = orden;
    }

    public static NpcInterior NpcCerca(Vector2 p) {
        if (Actual == null) return null;
        NpcInterior mejor = null;
        float md = 1.7f;
        foreach (var n in Actual.Npcs) {
            float d = Vector2.Distance(new Vector2(n.X, n.Y), p);
            if (d < md) { md = d; mejor = n; }
        }
        return mejor;
    }
}

// ═══════════ DIÁLOGO ═══════════
public class Opcion { public string Texto, Coste; public Action Accion; }

public class Dialogo : MonoBehaviour {
    public static Dialogo I;
    public bool Abierto;
    string _nombre;
    string[] _lineas;
    int _idx;
    Opcion[] _ops;
    GameObject _panel;
    Text _txtNombre, _txtLinea;
    Transform _contOps;

    void Awake() { I = this; }

    public void Montar(Transform canvas) {
        _panel = UiFab.Panel(canvas, "Dialogo", new Vector2(0,0), new Vector2(1,0),
                             new Vector2(10,10), new Vector2(-10,190));
        _panel.SetActive(false);
        _txtNombre = UiFab.Texto(_panel.transform, "Nombre", 15, TextAnchor.UpperLeft, new Vector2(12,-10), 300, 20);
        _txtNombre.color = Paleta.Mostaza;
        _txtLinea  = UiFab.Texto(_panel.transform, "Linea", 18, TextAnchor.UpperLeft, new Vector2(12,-32), 320, 60);
        var cont = new GameObject("Ops", typeof(RectTransform), typeof(VerticalLayoutGroup));
        cont.transform.SetParent(_panel.transform, false);
        var rt = cont.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0,0); rt.anchorMax = new Vector2(1,0);
        rt.pivot = new Vector2(0.5f,0); rt.offsetMin = new Vector2(10,10); rt.offsetMax = new Vector2(-10,90);
        var vl = cont.GetComponent<VerticalLayoutGroup>();
        vl.spacing = 5; vl.childForceExpandHeight = false; vl.childControlHeight = true;
        _contOps = cont.transform;
        var btn = _panel.AddComponent<Button>();
        btn.onClick.AddListener(Siguiente);
    }

    public void Abrir(string nombre, string[] lineas, Opcion[] ops) {
        _nombre = nombre; _lineas = lineas; _idx = 0; _ops = ops;
        Abierto = true;
        _panel.SetActive(true);
        Pintar();
    }

    void Siguiente() {
        if (_lineas == null) return;
        if (_idx < _lineas.Length - 1) { _idx++; Pintar(); }
    }

    void Pintar() {
        _txtNombre.text = _nombre;
        _txtLinea.text = _lineas[_idx];
        foreach (Transform t in _contOps) Destroy(t.gameObject);
        if (_idx < _lineas.Length - 1) return;
        var ops = _ops;
        if (ops == null || ops.Length == 0)
            ops = new[]{ new Opcion{ Texto = "Hasta luego", Accion = null } };
        foreach (var o in ops) {
            var op = o;
            var b = UiFab.Boton(_contOps, o.Coste == null ? o.Texto : o.Texto + "   " + o.Coste, () => {
                Cerrar();
                if (op.Accion != null) op.Accion();
            });
            b.GetComponent<LayoutElement>().minHeight = 40;
        }
    }

    public void Cerrar() { Abierto = false; _panel.SetActive(false); _lineas = null; }
}

// ═══════════ MINIJUEGO DE CURRO ═══════════
public class Minijuego : MonoBehaviour {
    public static Minijuego I;
    public bool Abierto;
    int _hechos, _meta;
    float _tiempo, _coste;
    GameObject _panel;
    Text _txtTitulo, _txtCuenta, _txtTiempo;

    void Awake() { I = this; }

    public void Montar(Transform canvas) {
        _panel = UiFab.Panel(canvas, "Curro", Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
        _panel.GetComponent<Image>().color = new Color(0.02f,0.03f,0.04f,0.94f);
        _panel.SetActive(false);
        _txtTitulo = UiFab.Texto(_panel.transform, "T", 22, TextAnchor.MiddleCenter, new Vector2(0,180), 400, 30);
        _txtCuenta = UiFab.Texto(_panel.transform, "C", 46, TextAnchor.MiddleCenter, new Vector2(0,130), 400, 60);
        _txtCuenta.color = Paleta.Mostaza;
        _txtTiempo = UiFab.Texto(_panel.transform, "P", 14, TextAnchor.MiddleCenter, new Vector2(0,-170), 400, 24);
        var b = UiFab.Boton(_panel.transform, "DALE", Tocar);
        var rt = b.GetComponent<RectTransform>();
        rt.anchorMin = rt.anchorMax = new Vector2(0.5f,0.5f);
        rt.pivot = new Vector2(0.5f,0.5f);
        rt.anchoredPosition = new Vector2(0,-20);
        rt.sizeDelta = new Vector2(190,190);
    }

    public void Abrir(string titulo, int meta, float segundos, float coste) {
        _hechos = 0; _meta = meta; _tiempo = segundos; _coste = coste;
        Abierto = true; _panel.SetActive(true);
        _txtTitulo.text = titulo;
        _txtCuenta.text = "0 / " + meta;
    }

    void Tocar() {
        if (!Abierto) return;
        _hechos++;
        AudioProc.I.Sfx("caja", 0.35f);
        _txtCuenta.text = _hechos + " / " + _meta;
        if (_hechos >= _meta) Cerrar(true);
    }

    public void Tic(float dt) {
        if (!Abierto) return;
        _tiempo -= dt;
        _txtTiempo.text = "QUEDAN " + _tiempo.ToString("0.0") + " S";
        if (_tiempo <= 0) Cerrar(false);
    }

    void Cerrar(bool ok) {
        Abierto = false; _panel.SetActive(false);
        if (ok && Curros.I.Activo != null) {
            Curros.I.Cobrar();
            Estado.I.Energia = Mathf.Max(0, Estado.I.Energia - _coste);
        } else {
            Hud.I.Aviso("NO HAS LLEGADO A TIEMPO");
            Curros.I.Cancelar();
        }
    }
}

}

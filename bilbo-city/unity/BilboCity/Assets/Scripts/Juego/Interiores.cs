using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace BilboCity {

public class NpcInterior {
    public float X, Y;
    public string Nombre, Arq, Tipo;
}

/// <summary>Un mueble del plano ya montado: qué es, dónde empieza y cuántas casillas ocupa.</summary>
public class PiezaInterior {
    public char Ch;
    public int X, Y, W, H;
}

public class DefInterior {
    public string Nombre, Suelo, Pared;
    public string[] Mapa;
    public NpcInterior[] Npcs;
}

/// <summary>Los sitios en los que se entra. Los cuatro últimos los comparten varios POI:
/// el rótulo de la puerta lo pone el sitio, no el plano de dentro.</summary>
public static class Interiores {
    public static DefInterior Actual;
    public static Vector2 Volver;
    static GameObject _raiz;

    // '#' pared · '.' suelo · 'D' salida · 'd' paso · C cama · A armario · U mesita · F sofá
    // M mesa · S silla · K encimera · N nevera · T inodoro · V lavabo · H ducha · E estantería
    // B barra · O mostrador · X vitrina · P puesto · L camilla · Q taquilla · R perchero
    // Z coche · Y escalera · W aparador · J planta
    // Atrezzo de dentro, en minúscula porque las mayúsculas se acabaron: g televisión ·
    // i lavadora · r radiador · a alfombra · t taburete · e escritorio · b bañera ·
    // w banco de taller · n neumáticos · f futbolín · x recreativa · p palés
    public static readonly Dictionary<string, DefInterior> Todos = new Dictionary<string, DefInterior> {
        // El piso compartido: dos habitaciones, salón, cocina y baño alrededor de un pasillo.
        // 62 m² útiles, que es lo que mide un piso de los sesenta en Santutxu. La habitación de
        // la derecha es la del primo. Los pisos que se compran reaprovechan este plano.
        {"piso", new DefInterior{ Nombre="Tu piso", Suelo="parquet", Pared="yeso", Mapa=new[]{
            "#############","#CCU.#.#.UCC#","#CC..#.#..CC#","#CC..d.d..CC#","#r...#.#...r#",
            "#AAA.#.#.EEE#","######.######","#FFF.#.#KKKN#","#.aa.d.d....#","#g.U.#.#iMSS#",
            "#....#.######","#MMS.#.d...H#","#MMS.#.#TV..#","######D######"},
            Npcs=new NpcInterior[0]}},
        {"portal", new DefInterior{ Nombre="Portal · la casera", Suelo="hidraulico", Pared="yeso", Mapa=new[]{
            "#######","#WW..Y#","#....Y#","#....Y#","#.aa..#","#.aa..#","#J...J#","#.....#","###D###"},
            Npcs=new[]{ new NpcInterior{ X=3.5f, Y=4.5f, Nombre="Amaia", Arq="amaia", Tipo="casera" }}}},
        {"bar", new DefInterior{ Nombre="Bar Zurito", Suelo="terrazo", Pared="azulejo", Mapa=new[]{
            "############","#EEEEEE..NN#","#..........#","#BBBBBBB...#","#t.t.t.t...#",
            "#SMS..SMS..#","#..........#","#SMS..SMS..#","#......#####","#SMS...#TV.#",
            "#......d...#","#ff.x..#...#","#####D######"},
            Npcs=new[]{
                new NpcInterior{ X=3.5f,  Y=2.5f,  Nombre="Josu",  Arq="josu",  Tipo="barman" },
                new NpcInterior{ X=8.5f,  Y=6.5f,  Nombre="Txema", Arq="txema", Tipo="jefe" },
                new NpcInterior{ X=5.5f,  Y=10.5f, Nombre="Mikel", Arq="mikel", Tipo="parroquiano" }}}},
        {"taller", new DefInterior{ Nombre="Taller Iker", Suelo="chapa", Pared="chapa", Mapa=new[]{
            "###############","#EEEE....EEEE.#","#.............#","#.ZZ.....ZZ...#","#.ZZ.....ZZ...#",
            "#.ZZ.....ZZ...#","#.ZZ.....ZZ...#","#.ZZ.....ZZ...#","#ww.........nn#","#OOO......QQQ.#",
            "#.............#","#####DDDD######"},
            Npcs=new[]{ new NpcInterior{ X=11.5f, Y=10.5f, Nombre="Iker", Arq="iker", Tipo="mecanico" }}}},
        {"armeria", new DefInterior{ Nombre="Bazar Nervión", Suelo="chapa", Pared="ladrillo", Mapa=new[]{
            "##########","#XXXXXXX.#","#........#","#EEE..EEE#","#........#","#EEE..EEE#",
            "#........#","#.OOOO...#","#........#","####D#####"},
            Npcs=new[]{ new NpcInterior{ X=3.5f, Y=8.5f, Nombre="Koldo", Arq="koldo", Tipo="armero" }}}},
        {"merca", new DefInterior{ Nombre="Mercado de la Ribera", Suelo="terrazo", Pared="chapa", Mapa=new[]{
            "###################","#PPPP..PPPP..PPPP.#","#PPPP..PPPP..PPPP.#","#.................#",
            "#.................#","#PPPP..PPPP..PPPP.#","#PPPP..PPPP..PPPP.#","#.................#",
            "#.................#","#OOOO.............#","#########D#########"},
            Npcs=new[]{ new NpcInterior{ X=2.5f, Y=8.5f, Nombre="Bego", Arq="bego", Tipo="pescatera" }}}},
        {"hospital", new DefInterior{ Nombre="Hospital de Basurto", Suelo="hospital", Pared="yeso", Mapa=new[]{
            "################","#LL#LL#LL#LL...#","#..#..#..#.....#","#..............#","#..............#",
            "#SSSS....OOOO..#","#..............#","#SSSS.........Q#","#..............#","#SSSS..........#",
            "#..............#","#######D########"},
            Npcs=new[]{ new NpcInterior{ X=9.5f, Y=4.5f, Nombre="Nekane", Arq="enfermera", Tipo="enfermera" }}}},
        // Los cinco de abajo los comparten varios sitios: el rótulo lo pone el POI.
        {"ropa", new DefInterior{ Nombre="Tienda de ropa", Suelo="terrazo", Pared="yeso", Mapa=new[]{
            "###########","#RRRR.RRRR#","#.........#","#.........#","#RRRR.RRRR#","#.........#",
            "#.........#","#XX....EEE#","#.........#","#.OOO.....#","#.........#","#####D#####"},
            Npcs=new[]{ new NpcInterior{ X=2.5f, Y=8.5f, Nombre="Nerea", Arq="nerea", Tipo="ropa" }}}},
        {"tasca", new DefInterior{ Nombre="Tasca", Suelo="terrazo", Pared="azulejo", Mapa=new[]{
            "##########","#EEEE..NN#","#........#","#BBBBB...#","#t.t.t...#","#SMS..SMS#",
            "#........#","#SMS..SMS#","#........#","####D#####"},
            Npcs=new[]{
                new NpcInterior{ X=3.5f, Y=2.5f, Nombre="Patxi", Arq="patxi", Tipo="barman" },
                new NpcInterior{ X=5.5f, Y=8.5f, Nombre="Mikel", Arq="mikel", Tipo="parroquiano" }}}},
        {"resto", new DefInterior{ Nombre="Restaurante", Suelo="terrazo", Pared="azulejo", Mapa=new[]{
            "#############","#KKKKN#.EEEE#","#.....#.....#","#..MM.d.....#","######.######",
            "#SMMS..SMMS.#","#SMMS..SMMS.#","#...........#","#SMMS..SMMS.#","#SMMS..SMMS.#",
            "#OOO........#","#####D#######"},
            Npcs=new[]{ new NpcInterior{ X=3.5f, Y=2.5f, Nombre="Patxi", Arq="patxi", Tipo="cocinero" }}}},
        {"centro", new DefInterior{ Nombre="Galería", Suelo="terrazo", Pared="yeso", Mapa=new[]{
            "###################","#RRRR..EEEE..XXXX.#","#.................#","#.................#",
            "#OOO....OOO....OOO#","#.................#","#.................#","#YY....J....J...YY#",
            "#YY.............YY#","#.................#","#EEEE..XXXX..RRRR.#","#.................#",
            "#########D#########"},
            Npcs=new[]{
                new NpcInterior{ X=2.5f,  Y=5.5f, Nombre="Nerea", Arq="nerea", Tipo="ropa" },
                new NpcInterior{ X=9.5f,  Y=5.5f, Nombre="Patxi", Arq="patxi", Tipo="cocinero" },
                new NpcInterior{ X=16.5f, Y=5.5f, Nombre="Bego",  Arq="bego",  Tipo="pescatera" }}}},
        // Los almacenes: la única tienda con más de un mostrador. Las escaleras mecánicas no
        // llevan a ninguna planta —no hay pisos— pero dicen que el sitio tiene tres.
        {"almacenes", new DefInterior{ Nombre="Almacenes", Suelo="terrazo", Pared="yeso", Mapa=new[]{
            "#####################","#RRRR..RRRR..XXXX..E#","#...................#","#...................#",
            "#EEEE..EEEE..EEEE..E#","#...................#","#...................#","#OOO....YY....YY.OOO#",
            "#.......YY....YY....#","#...................#","#XXXX..XXXX..RRRR..R#","#...................#",
            "#...................#","#EEEE..EEEE..OOOO...#","#...................#","##########D##########"},
            Npcs=new[]{
                new NpcInterior{ X=2.5f,  Y=8.5f,  Nombre="Nerea", Arq="nerea", Tipo="ropa" },
                new NpcInterior{ X=10.5f, Y=12.5f, Nombre="Maite", Arq="maite", Tipo="encargada" },
                new NpcInterior{ X=18.5f, Y=8.5f,  Nombre="Patxi", Arq="patxi", Tipo="cocinero" }}}},
        {"gasoli", new DefInterior{ Nombre="Gasolinera", Suelo="chapa", Pared="chapa", Mapa=new[]{
            "##########","#EEE..NNN#","#........#","#EEE..EEE#","#........#","#XX.....n#",
            "#........#","#.OOOO...#","#........#","####D#####"},
            Npcs=new[]{ new NpcInterior{ X=3.5f, Y=8.5f, Nombre="Gorka", Arq="gorka", Tipo="gasolinero" }}}},
    };

    /// <summary>Lo que se pisa. Todo lo demás del plano es mueble y frena: la escalera
    /// mecánica se anda por encima, y el paso de una habitación a otra no tiene hoja.</summary>
    public const string Blando = ".dDY";
    /// <summary>Se pisa y se dibuja: la alfombra no frena a nadie, y el taburete tampoco —se
    /// pasa de lado—. La diferencia importa: una fila de taburetes delante de la barra, si
    /// frenase, sería un muro y dejaría medio bar sin manera de llegar. Blando no vale para
    /// esto, porque lo que está en esa lista ni siquiera se dibuja como pieza.</summary>
    public const string Pisable = "at";
    /// <summary>Los muebles de esta lista no se juntan nunca: cuatro sillas en fila son cuatro
    /// sillas, no un banco de 3,2 m.</summary>
    public const string Unitario = "STVUJNtgixb";
    /// <summary>Media unidad de Unity por casilla: 16 px de arte sobre 32 px por unidad.</summary>
    public static float Escala { get { return ForjaInterior.Px / Mundo.PPU; } }
    public static int Alto { get { return Actual != null ? Actual.Mapa.Length : 0; } }

    public static char Casilla(float x, float y) {
        if (Actual == null) return '#';
        int fy = Mathf.FloorToInt(y), fx = Mathf.FloorToInt(x);
        if (fy < 0 || fy >= Actual.Mapa.Length) return '#';
        var fila = Actual.Mapa[fy];
        if (fx < 0 || fx >= fila.Length) return '#';
        return fila[fx];
    }
    public static bool Solido(float x, float y) {
        char ch = Casilla(x, y);
        return Blando.IndexOf(ch) < 0 && Pisable.IndexOf(ch) < 0;
    }

    /// <summary>El nombre viene de fuera a propósito: dos tascas iguales por dentro se
    /// llaman distinto en la puerta, que es lo que pasa en cualquier barrio.</summary>
    /// <summary>De qué sitio del mapa es el interior en el que estás. Dos tascas comparten
    /// plano pero no dueño.</summary>
    public static string PoiActual;

    public static void Entrar(string id, Vector2 desde, string nombre = null, string poi = null) {
        PoiActual = poi;
        var d = Todos[id];
        // El piso de Santutxu es compartido y el primo está dentro. Se le añade aquí y no en
        // la plantilla porque el mismo plano lo usan los pisos que se compran, y allí no vive
        // nadie: metido en Todos["piso"] saldría también en el loft y en el caserío.
        var npcs = (poi == "piso" && !Estado.I.CaseraDesahucio)
            ? new List<NpcInterior>(d.Npcs){ Prologo.Primo }.ToArray() : d.Npcs;
        Actual = (nombre == null && npcs == d.Npcs) ? d : new DefInterior{
            Nombre=nombre ?? d.Nombre, Suelo=d.Suelo, Pared=d.Pared, Mapa=d.Mapa, Npcs=npcs };
        Volver = desde;
        Estado.I.EnInterior = true;
        var J = Juego.I;
        J.Jug.EnCoche = null;
        // El portón de un taller mide más que una puerta de casa, así que se entra por el
        // centro del hueco y no por su última casilla.
        int sum = 0, cuantas = 0, fila = 0;
        for (int y = 0; y < Actual.Mapa.Length; y++)
            for (int x = 0; x < Actual.Mapa[y].Length; x++)
                if (Actual.Mapa[y][x] == 'D') { sum += x; cuantas++; fila = y; }
        if (cuantas > 0) J.Jug.Pos = new Vector2(sum / (float)cuantas + 0.5f, fila - 0.7f);
        J.Jug.Dir8 = 4;
        Construir();
        J.MostrarCiudad(false);
        // Un paso de entrar no lo puede ver el Tic de misiones: dentro de un interior el
        // bucle no llega a mirarlo.
        var pa = Misiones.I != null && Misiones.I.Activa != null ? Misiones.I.Activa.Actual : null;
        if (pa != null && pa.Tipo == "entrar" && pa.Poi == poi) Misiones.I.Avanzar();
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

    /// <summary>Trocea el plano en piezas rectangulares: dos casillas de «C» seguidas no son
    /// dos camas, son una cama de 1,6 m. Se hace una vez al entrar.</summary>
    public static List<PiezaInterior> Piezas(DefInterior d) {
        var m = d.Mapa;
        int alto = m.Length;
        var visto = new bool[alto][];
        for (int y = 0; y < alto; y++) visto[y] = new bool[m[y].Length];
        var salida = new List<PiezaInterior>();
        for (int y = 0; y < alto; y++)
            for (int x = 0; x < m[y].Length; x++) {
                char ch = m[y][x];
                if (ch == '#' || Blando.IndexOf(ch) >= 0 || visto[y][x]) continue;
                if (Unitario.IndexOf(ch) >= 0) {
                    visto[y][x] = true;
                    salida.Add(new PiezaInterior{ Ch=ch, X=x, Y=y, W=1, H=1 });
                    continue;
                }
                int aw = 0;
                while (x + aw < m[y].Length && m[y][x+aw] == ch && !visto[y][x+aw]) aw++;
                int ah = 1;
                while (y + ah < alto) {
                    bool ok = m[y+ah].Length >= x + aw;
                    for (int i = 0; ok && i < aw; i++)
                        if (m[y+ah][x+i] != ch || visto[y+ah][x+i]) ok = false;
                    if (!ok) break;
                    ah++;
                }
                for (int j = 0; j < ah; j++) for (int i = 0; i < aw; i++) visto[y+j][x+i] = true;
                salida.Add(new PiezaInterior{ Ch=ch, X=x, Y=y, W=aw, H=ah });
            }
        return salida;
    }

    static void Construir() {
        if (_raiz != null) UnityEngine.Object.Destroy(_raiz);
        _raiz = new GameObject("Interior");
        ForjaInterior.Generar();
        var m = Actual.Mapa;
        var suelo = ForjaInterior.Suelos[Actual.Suelo];
        var pared = ForjaInterior.Paredes[Actual.Pared];
        for (int y = 0; y < m.Length; y++)
            for (int x = 0; x < m[y].Length; x++) {
                char ch = m[y][x];
                if (ch == '#') { Poner(pared, x, y, 1, 1, -199); continue; }
                Poner(suelo, x, y, 1, 1, -200);
                if (ch == 'D') Poner(ForjaInterior.Puerta, x, y, 1, 1, -198);
                else if (ch == 'd') {
                    bool vertical = x > 0 && x+1 < m[y].Length && m[y][x-1] == '#' && m[y][x+1] == '#';
                    Poner(vertical ? ForjaInterior.PasoV : ForjaInterior.PasoH, x, y, 1, 1, -198);
                }
            }
        // Todo lo que sobresale del suelo se ordena por su canto de abajo: así quien está
        // delante de un mueble lo tapa y quien está detrás queda tapado.
        foreach (var p in Piezas(Actual))
            Poner(ForjaInterior.Mueble(p.Ch, p.W, p.H), p.X, p.Y, p.W, p.H, Mundo.OrdenY(p.Y + p.H));
        foreach (var n in Actual.Npcs) {
            var go = new GameObject("npc_" + n.Nombre);
            go.transform.SetParent(_raiz.transform, false);
            go.transform.position = Mundo.AMundoPixel(new Vector2(n.X, n.Y));
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = ForjaChar.Frame(n.Arq, Pose.Quieto, 0);
            sr.sortingOrder = Mundo.OrdenY(n.Y);
        }
    }

    static void Poner(Sprite s, int x, int y, int w, int h, int orden) {
        var go = new GameObject("t");
        go.transform.SetParent(_raiz.transform, false);
        // El sprite lleva el pivote en el centro, así que se coloca por el centro de la pieza.
        go.transform.position = Mundo.AMundoPixel(new Vector2(x + w/2f, y + h/2f));
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

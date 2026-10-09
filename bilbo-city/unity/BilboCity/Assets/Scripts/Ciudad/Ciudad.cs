using System;
using System.IO;
using System.IO.Compression;
using UnityEngine;

namespace BilboCity {

/// <summary>Un barrio de Bilbao: cómo se llama, de qué es su pavimento y a qué tira su luz.</summary>
public class Barrio {
    public readonly string Nombre, Estilo;
    public readonly Color32 Tinte;
    /// Donde el plano municipal pone su rótulo, en casillas.
    public readonly int X, Y;
    public Barrio(string nombre, string estilo, string tinte, int x, int y) {
        Nombre = nombre; Estilo = estilo; Tinte = Paleta.H(tinte); X = x; Y = y;
    }
}

/// <summary>
/// La planta de Bilbao. Ya no se genera: se carga.
///
/// El plano municipal es vectorial y trae la ciudad en dos capas que se separan limpias:
/// las manzanas, los parques y la ría son polígonos con su relleno, y la calzada es un
/// trazo blanco con el ancho real de cada calle. herramientas/plano/extraer.py separa
/// esas capas, las pasa a casillas y las deja en Plano.cs comprimidas. Lo que se dibuja
/// aquí son las calles de Bilbao —la retícula del Ensanche, la diagonal de la Gran Vía,
/// la elipse de Moyúa, la Ribera de Deustu entre el canal y la ría— y no unas calles
/// verosímiles.
///
/// El mapa mide 1440×776 casillas a 5,16 m cada una: 7,4 km de este a oeste por 4 de
/// norte a sur. Es rectangular porque el valle lo es.
/// </summary>
public static class Ciudad {
    public const int MW = Plano.MW, MH = Plano.MH;
    public static readonly byte[] Map = new byte[MW*MH];
    public static readonly byte[] Roof = new byte[MW*MH];
    /// Índice del barrio de cada casilla, en el orden de Plano.Barrios.
    public static readonly byte[] BarrioIdx = new byte[MW*MH];

    public static Barrio BarrioDe(int x, int y) {
        int k = Mathf.Clamp(y,0,MH-1)*MW + Mathf.Clamp(x,0,MW-1);
        int i = BarrioIdx[k];
        return i < Plano.Barrios.Length ? Plano.Barrios[i] : Plano.Barrios[0];
    }

    public static Suelo T(int x, int y) {
        if (x < 0 || y < 0 || x >= MW || y >= MH) return Suelo.Edif;
        return (Suelo)Map[y*MW+x];
    }
    public static bool Rodable(int x, int y) {
        var t = T(x,y);
        return t == Suelo.Road || t == Suelo.Puente || t == Suelo.Muelle;
    }
    public static bool Andable(Suelo t) { return t != Suelo.Edif && t != Suelo.Agua; }

    /// <summary>
    /// Deflate crudo, sin cabecera zlib: los mismos bytes que descomprime el prototipo
    /// con DecompressionStream("deflate-raw"), y sin meter una biblioteca en ninguno de
    /// los dos lados. Sin comprimir, a byte por casilla, serían 1,1 MB por capa.
    /// </summary>
    static byte[] Inflar(string b64) {
        var bin = Convert.FromBase64String(b64);
        using (var ms = new MemoryStream(bin))
        using (var ds = new DeflateStream(ms, CompressionMode.Decompress))
        using (var salida = new MemoryStream(MW*MH)) {
            ds.CopyTo(salida);
            return salida.ToArray();
        }
    }

    public static void Generar() {
        var trama = Inflar(Plano.Trama());
        var barrios = Inflar(Plano.TramaBarrio());
        Array.Copy(trama, Map, Mathf.Min(trama.Length, Map.Length));
        Array.Copy(barrios, BarrioIdx, Mathf.Min(barrios.Length, BarrioIdx.Length));
        Tejados();
        // borde cerrado: fuera del término municipal no hay nada que visitar
        for (int x = 0; x < MW; x++) { Map[x] = (byte)Suelo.Edif; Map[(MH-1)*MW+x] = (byte)Suelo.Edif; }
        for (int y = 0; y < MH; y++) { Map[y*MW] = (byte)Suelo.Edif; Map[y*MW+MW-1] = (byte)Suelo.Edif; }
        // Los patios se abren con los tejados ya repartidos: la casilla deja de ser Edif
        // pero conserva su índice de tejado, que es con el que se la tapa desde la calle.
        AbrirPatios();
        // Lo último: las marcas viales se miden sobre el mapa ya cerrado, o una calle que
        // sale del término se mediría llegando hasta el borde.
        TrazarCalzada();
    }

    // ═══════════ EL INTERIOR DE MANZANA ═══════════
    /// <summary>
    /// El plano municipal dibuja la manzana maciza: por fuera es un polígono y por dentro
    /// no hay nada. En Bilbao casi todas tienen patio, y se entra por un portal que
    /// atraviesa el edificio. Eso no se puede sacar del plano —no lo dibuja— pero sí se
    /// puede abrir aquí, y a cambio la manzana deja de ser un rectángulo de tejado de
    /// cuarenta casillas.
    ///
    /// El patio no se ve desde la calle: lo tapa el tejado del propio bloque hasta que
    /// entras (RenderCiudad). Lo único que asoma es la boca del portal.
    ///
    /// Dos reglas sostienen el trazado. Una, que alrededor del patio queden DOS casillas
    /// de edificio por los cuatro lados: con una, el patio se come la fachada y desde la
    /// calle se ve el agujero. Y como una casilla abierta deja de ser Edif, esa misma
    /// comprobación impide que dos patios se toquen sin llevar cuentas. Dos, que el portal
    /// sea recto y salga al lado más cercano: un portal en ele es un pasadizo, y un
    /// pasadizo invita a atravesar la manzana, que es justo lo que un patio no es.
    ///
    /// Esto tiene que dar CASILLA POR CASILLA lo mismo que abrirPatios() del prototipo, y
    /// por eso Utiles.Hash y hash() del HTML tienen que coincidir: ver patios.py.
    /// </summary>
    public const int PatioSembrado = 17;   // se intenta en una de cada diecisiete casillas de edificio
    public const int PatioLado = 3, PatioVar = 3;   // el patio mide de 3 a 5 casillas de lado
    public const int PatioMuro = 2;        // anillos de edificio que quedan alrededor
    public const int PatioPortal = 10;     // el portal no cruza más de diez casillas de edificio
    /// <summary>Lo que tarda la tapa del patio en irse y en volver. Aparecer de golpe
    /// treinta metros de patio delante de las narices se lee como un fallo de dibujo.</summary>
    public const float PatioSeg = .35f;

    public struct Patio { public int X, Y, W, H, Bx, By; }
    public static readonly System.Collections.Generic.List<Patio> Patios =
        new System.Collections.Generic.List<Patio>();

    static void AbrirPatios() {
        Patios.Clear();
        // El orden del empate es sur, norte, este y oeste: la cara sur es la que se ve de
        // pie en la calle, así que es la que mejor cuenta que ahí hay una entrada.
        int[] ddx = {0,0,1,-1}, ddy = {1,-1,0,0};
        for (int y = 0; y < MH; y++)
            for (int x = 0; x < MW; x++) {
                if (Map[y*MW+x] != (byte)Suelo.Edif || Utiles.Hash(x,y) % PatioSembrado != 0) continue;
                int w = PatioLado + Utiles.Hash(x, y*3) % PatioVar;
                int h = PatioLado + Utiles.Hash(y*3, x) % PatioVar;
                bool cabe = true;
                for (int j = y-PatioMuro; j <= y+h-1+PatioMuro && cabe; j++)
                    for (int i = x-PatioMuro; i <= x+w-1+PatioMuro; i++)
                        if (T(i,j) != Suelo.Edif) { cabe = false; break; }
                if (!cabe) continue;
                int cx = x + (w>>1), cy = y + (h>>1);
                int[] bxs = {cx, cx, x+w-1, x}, bys = {y+h-1, y, cy, cy};
                int mn = 0, mdx = 0, mdy = 0, mbx = 0, mby = 0;
                for (int k = 0; k < 4; k++) {
                    int dx = ddx[k], dy = ddy[k], bx = bxs[k], by = bys[k];
                    for (int n = 1; n <= PatioPortal; n++) {
                        int px = bx + dx*n, py = by + dy*n;
                        var t = T(px,py);
                        if (t == Suelo.Edif) {
                            // El portal no puede ir pegado a otro patio ni desembocar en él:
                            // dos patios unidos por sus portales son un pasadizo que
                            // atraviesa la manzana, y eso ya no es un interior de manzana.
                            if (T(px+dy,py+dx) == Suelo.Patio || T(px-dy,py-dx) == Suelo.Patio) break;
                            continue;
                        }
                        if (t != Suelo.Patio && Andable(t) && t != Suelo.Monte && t != Suelo.Parque
                            && (mn == 0 || n < mn)) { mn = n; mdx = dx; mdy = dy; mbx = bx; mby = by; }
                        break;
                    }
                }
                if (mn == 0) continue;
                for (int j = y; j < y+h; j++)
                    for (int i = x; i < x+w; i++) Map[j*MW+i] = (byte)Suelo.Patio;
                for (int n = 1; n < mn; n++) Map[(mby+mdy*n)*MW + mbx + mdx*n] = (byte)Suelo.Patio;
                Patios.Add(new Patio { X = x, Y = y, W = w, H = h,
                                       Bx = mbx + mdx*(mn-1), By = mby + mdy*(mn-1) });
            }
    }

    /// <summary>La boca del portal no se tapa nunca: es lo único que se ve desde la calle,
    /// y sin ella no hay manera de saber que esa manzana tiene por dónde entrar. Es la
    /// casilla de patio que da a algo pisable que no es patio, y hay exactamente una.</summary>
    public static bool EsBoca(int x, int y) {
        int[] dx = {1,-1,0,0}, dy = {0,0,1,-1};
        for (int k = 0; k < 4; k++) {
            var t = T(x+dx[k], y+dy[k]);
            if (t != Suelo.Patio && Andable(t)) return true;
        }
        return false;
    }

    /// <summary>Las casillas del patio al que pertenece una: son treinta contadas, y
    /// recorrerlas sale más barato que llevar un índice de componente por casilla.</summary>
    public static System.Collections.Generic.HashSet<int> PatioDe(int x, int y) {
        int i0 = y*MW + x;
        if (T(x,y) != Suelo.Patio) return null;
        var s = new System.Collections.Generic.HashSet<int> { i0 };
        var pila = new System.Collections.Generic.Stack<int>();
        pila.Push(i0);
        int[] dx = {1,-1,0,0}, dy = {0,0,1,-1};
        while (pila.Count > 0) {
            int i = pila.Pop(), cx = i % MW, cy = i / MW;
            for (int k = 0; k < 4; k++) {
                int nx = cx + dx[k], ny = cy + dy[k];
                if (nx < 0 || ny < 0 || nx >= MW || ny >= MH) continue;
                int j = ny*MW + nx;
                if (Map[j] == (byte)Suelo.Patio && s.Add(j)) pila.Push(j);
            }
        }
        return s;
    }

    // ═══════════ LA CALZADA: ANCHO, CARRILES Y SENTIDO ═══════════
    /// <summary>
    /// El plano trae el ancho real de cada calle —un callejón del Casco Viejo y la Gran Vía
    /// son la misma línea con distinto grosor— pero el juego lo pintaba todo del mismo gris
    /// y solo rayaba las calles de UNA casilla de ancho, que es justo donde no cabe una
    /// raya. Desde arriba, una avenida de cinco carriles y un callejón eran la misma mancha.
    ///
    /// Aquí se mide el corredor: para cada casilla de asfalto, cuánto mide la calle a lo
    /// ancho, en qué posición de ese ancho cae y hacia dónde circula su carril. De ahí salen
    /// las marcas viales —eje, separadores de carril, flechas y pasos de cebra— y también la
    /// disciplina de carril del tráfico, que es lo que hace que las rayas no sean un adorno.
    ///
    /// Cómo se mide, que tiene truco: la calle es la tirada CORTA. De cada casilla se mide la
    /// tirada de asfalto en horizontal y en vertical; la pequeña de las dos es el ancho y la
    /// otra dice por dónde va la calle. Y el nudo sale gratis: en un cruce las dos tiradas
    /// son largas, así que la pequeña también lo es, y por encima de AnchoMax no hay calle
    /// que valga. Eso es lo único que impide pintar un eje continuo a través de una
    /// intersección, y no hizo falta detectar cruces por ningún otro lado.
    ///
    /// Las diagonales no llevan tratamiento aparte y no lo necesitan: una calle tendida —la
    /// Gran Vía, Autonomía— corta en vertical poco más que su ancho y en horizontal el
    /// triple, así que la pasada por filas y columnas ya la da por horizontal. Lo que se
    /// queda sin marcar son los 45° de verdad, que en Bilbao son las revueltas de Artxanda.
    /// </summary>
    public const int EjeNo = 0, EjeH = 1, EjeV = 2, EjeCruce = 3;
    /// <summary>Ocho casillas son 41 m de calzada. Por encima de eso en las dos direcciones
    /// a la vez no es una calle: es un cruce, una plaza o una explanada. Sale de medir el
    /// plano — el 94 % de la calzada de Bilbao tiene ocho casillas o menos de ancho.</summary>
    public const int AnchoMax = 8;
    public const int SenNo = 0, SenE = 1, SenO = 2, SenS = 3, SenN = 4;
    /// <summary>Qué puede llevar el canto de arriba (o de la izquierda) de una casilla, y su centro.</summary>
    public const int MNada = 0, MEje = 1, MEjeDis = 2, MCarril = 3;
    /// <summary>Y dónde para la línea de detención: en el canto bajo de la casilla, en el
    /// alto, o en ninguno. Es la única marca que va ATRAVESADA a la calle y no a lo largo.</summary>
    public const int DNo = 0, DBajo = 1, DAlto = 2;

    /// Por casilla, dos bytes y no cinco: el índice de su tile de calzada —que ya resume el
    /// eje y las marcas— y el sentido de su carril, que hace falta suelto para el tráfico.
    public static readonly byte[] ViaMarca = new byte[MW*MH];
    public static readonly byte[] ViaSentido = new byte[MW*MH];
    /// Los códigos de marca que de verdad salen en el mapa. Son unas decenas de los dos mil
    /// posibles, así que se forja un tile por código que aparece y la casilla guarda el índice.
    public static readonly System.Collections.Generic.List<int> ViaCod =
        new System.Collections.Generic.List<int> { 0 };
    public static readonly System.Collections.Generic.List<bool> ViaCebra =
        new System.Collections.Generic.List<bool> { false };
    static readonly System.Collections.Generic.Dictionary<int,int> _viaIdx =
        new System.Collections.Generic.Dictionary<int,int> { {0,0} };

    public static int CodPack(int eje, int canto, int centro, int cebra, int parada) {
        return eje | (canto<<3) | (centro<<6) | (cebra<<9) | (parada<<10);
    }
    static int Codigo(int cod) {
        int i;
        if (!_viaIdx.TryGetValue(cod, out i)) {
            if (ViaCod.Count >= 256) return 0;        // red de seguridad: el índice es un byte
            i = ViaCod.Count;
            ViaCod.Add(cod); ViaCebra.Add(((cod>>9)&1) != 0); _viaIdx[cod] = i;
        }
        return i;
    }
    public static int SentidoDe(int x, int y) {
        if (x < 0 || y < 0 || x >= MW || y >= MH) return SenNo;
        return ViaSentido[y*MW+x];
    }

    /// <summary>Qué cantos de una acera dan a la calzada y cuáles dan a un paso de cebra.</summary>
    /// Los cuatro bits bajos son bordillo y los cuatro altos vado: donde cruza el paso, el
    /// bordillo está rebajado, que es por donde se baja a la calle.
    static bool ACalzada(int x, int y) {
        if (x < 0 || y < 0 || x >= MW || y >= MH) return false;
        return Map[y*MW+x] == (byte)Suelo.Road;
    }
    static bool ACebra(int x, int y) { return ACalzada(x,y) && ViaCebra[ViaMarca[y*MW+x]]; }
    static readonly int[] _ladoX = {0,1,0,-1}, _ladoY = {-1,0,1,0};
    public static int BordeDe(int x, int y) {
        int m = 0, mv = 0;
        for (int k = 0; k < 4; k++) {
            int nx = x + _ladoX[k], ny = y + _ladoY[k];
            if (!ACalzada(nx,ny)) continue;
            if (ACebra(nx,ny)) mv |= 1<<k; else m |= 1<<k;
        }
        return m | (mv<<4);
    }

    /// <summary>El índice del tile de bordillo de cada casilla, calculado de una vez con la
    /// calzada: el render deja de mirar a los cuatro vecinos en cada fotograma.</summary>
    public static readonly byte[] BordeMarca = new byte[MW*MH];
    public static readonly System.Collections.Generic.List<int> BordeCod =
        new System.Collections.Generic.List<int> { 0 };
    static readonly System.Collections.Generic.Dictionary<int,int> _bordeIdx =
        new System.Collections.Generic.Dictionary<int,int> { {0,0} };

    static void TrazarBordillos() {
        Array.Clear(BordeMarca, 0, BordeMarca.Length);
        BordeCod.Clear(); BordeCod.Add(0);
        _bordeIdx.Clear(); _bordeIdx[0] = 0;
        for (int y = 0; y < MH; y++)
            for (int x = 0; x < MW; x++) {
                int i = y*MW+x;
                if (Map[i] != (byte)Suelo.Acera) continue;
                int cod = BordeDe(x,y);
                if (cod == 0) continue;
                int k;
                if (!_bordeIdx.TryGetValue(cod, out k)) {
                    if (BordeCod.Count >= 256) continue;
                    k = BordeCod.Count; BordeCod.Add(cod); _bordeIdx[cod] = k;
                }
                BordeMarca[i] = (byte)k;
            }
    }

    public static void TrazarCalzada() {
        Array.Clear(ViaMarca, 0, ViaMarca.Length);
        Array.Clear(ViaSentido, 0, ViaSentido.Length);
        ViaCod.Clear();   ViaCod.Add(0);
        ViaCebra.Clear(); ViaCebra.Add(false);
        _viaIdx.Clear();  _viaIdx[0] = 0;
        byte road = (byte)Suelo.Road;

        // Primera pasada, por filas: la tirada horizontal de cada casilla y su posición
        // dentro de ella. Se guardan porque la segunda pasada va por columnas y las
        // necesita a la vez.
        var rh = new byte[MW*MH]; var ih = new byte[MW*MH];
        for (int y = 0; y < MH; y++) {
            int f = y*MW;
            for (int x = 0; x < MW; ) {
                if (Map[f+x] != road) { x++; continue; }
                int e = x; while (e < MW && Map[f+e] == road) e++;
                int n = Mathf.Min(e-x, 255);
                for (int k = x; k < e; k++) { rh[f+k] = (byte)n; ih[f+k] = (byte)Mathf.Min(k-x, 255); }
                x = e;
            }
        }
        // Segunda, por columnas: con las dos tiradas ya se sabe por dónde va la calle.
        var eje = new byte[MW*MH]; var anch = new byte[MW*MH]; var pos = new byte[MW*MH];
        for (int x = 0; x < MW; x++) {
            for (int y = 0; y < MH; ) {
                if (Map[y*MW+x] != road) { y++; continue; }
                int e = y; while (e < MH && Map[e*MW+x] == road) e++;
                int nv = Mathf.Min(e-y, 255);
                for (int k = y; k < e; k++) {
                    int i = k*MW+x, nh = rh[i];
                    if (Mathf.Min(nh,nv) > AnchoMax || nh == nv) { eje[i] = EjeCruce; continue; }
                    if (nv < nh) { eje[i] = EjeH; anch[i] = (byte)nv; pos[i] = (byte)(k-y); }
                    else         { eje[i] = EjeV; anch[i] = (byte)nh; pos[i] = ih[i]; }
                }
                y = e;
            }
        }
        // Y la tercera: de la geometría a la pintura. Va aparte porque el paso de cebra mira
        // a la casilla de al lado y en la segunda pasada todavía no está medida.
        var cebra = new byte[MW*MH]; var cantoDe = new byte[MW*MH]; var centroDe = new byte[MW*MH];
        for (int i = 0; i < MW*MH; i++) {
            int e = eje[i];
            if (e != EjeH && e != EjeV) continue;
            int an = anch[i], po = pos[i];
            int canto = MNada, centro = MNada;
            if (an >= 2) {
                // Cada casilla pinta SOLO su canto de arriba (o de la izquierda). Así una
                // línea la dibuja una casilla y no media cada una de las dos vecinas, que a
                // 32 píxeles es la diferencia entre una raya y dos rayas finas. El canto 0
                // es el bordillo y no lleva pintura: ahí el límite lo pone la acera.
                float c = an/2f;
                // Con una calzada de dos casillas hay un carril por sentido y se puede
                // adelantar: eje discontinuo. De tres para arriba, continuo.
                bool cont = an >= 3;
                if (an % 2 == 0) { if (po == an/2) canto = cont ? MEje : MEjeDis; }
                else if (po == (an-1)/2) centro = cont ? MEje : MEjeDis;
                // Separadores de carril: los cantos interiores que no son el eje y que caen
                // a una casilla o más del centro. Más cerca sobran — la raya quedaría
                // pegada al eje.
                if (canto == MNada && po >= 1 && Mathf.Abs(po - c) >= 1) canto = MCarril;
                // Se circula por la derecha. Mirando al este la derecha cae al sur, así que
                // la mitad de abajo de una calle este-oeste va al este; mirando al sur la
                // derecha cae al oeste, así que la mitad izquierda de una calle norte-sur
                // baja. La casilla por la que pasa el eje es mitad de cada sentido, así que
                // no tiene uno: ni lleva flecha pintada ni le dice nada al tráfico. Dársela
                // a uno de los dos ponía una flecha encima de la línea continua, que es lo
                // contrario de lo que significa.
                if (centro == MNada)
                    ViaSentido[i] = (byte)(e == EjeH ? (po+0.5f > c ? SenE : SenO)
                                                     : (po+0.5f < c ? SenS : SenN));
            }
            // El paso de cebra va pegado al nudo y cruza la calle entera, y se come las
            // marcas de esa casilla. El sentido del carril NO se pierde: se calcula antes,
            // porque si no el tráfico se quedaba sin disciplina justo en el sitio donde más
            // falta hace.
            //
            // Que la casilla de al lado sea un nudo no basta para pintar un paso: la calzada
            // sale de erosionar el trazo del plano y queda dentada, así que cualquier
            // casilla de más a un lado se mide como nudo. Se exige que el nudo tenga DOS
            // casillas de fondo en la dirección de la calle, que es lo que distingue un
            // cruce de verdad —la calle que corta tiene su ancho— de un diente del
            // rasterizado.
            int p1 = e == EjeH ? 1 : MW;
            if (an >= 2 && (Hueco(eje, i, -p1) || Hueco(eje, i, p1))) cebra[i] = 1;
            cantoDe[i] = (byte)canto; centroDe[i] = (byte)centro;
        }
        // Cuarta: la línea de detención. Va en su propia pasada porque mira si la casilla
        // de al lado es un paso de cebra, y eso no se sabe hasta que la tercera ha terminado.
        //
        // Solo la pinta el que LLEGA al paso: es lo que distingue la entrada del cruce de
        // la salida, y sin ella el paso de cebra flota en mitad del asfalto. La casilla por
        // la que va el eje no tiene sentido —es mitad de cada uno— y ahí la línea se pinta
        // igual del lado donde esté el paso, que es lo que hace la pintura de verdad: las
        // dos se tocan en el eje en vez de dejar un hueco de cinco metros.
        for (int i = 0; i < MW*MH; i++) {
            int e = eje[i];
            if (e != EjeH && e != EjeV) continue;
            if (cebra[i] != 0) { ViaMarca[i] = (byte)Codigo(CodPack(e, MNada, MNada, 1, DNo)); continue; }
            int p1 = e == EjeH ? 1 : MW;
            bool alta = i+p1 < cebra.Length && cebra[i+p1] != 0;
            bool baja = i-p1 >= 0 && cebra[i-p1] != 0;
            int s = ViaSentido[i];
            int parada = DNo;
            if ((s == SenE || s == SenS) && alta) parada = DAlto;
            else if ((s == SenO || s == SenN) && baja) parada = DBajo;
            else if (s == SenNo) parada = alta ? DAlto : baja ? DBajo : DNo;
            ViaMarca[i] = (byte)Codigo(CodPack(e, cantoDe[i], centroDe[i], 0, parada));
        }
        TrazarBordillos();
    }
    static bool Hueco(byte[] eje, int i, int d) {
        int a = i+d, b = i+2*d;
        if (a < 0 || b < 0 || a >= eje.Length || b >= eje.Length) return false;
        return eje[a] == EjeCruce && eje[b] == EjeCruce;
    }

    /// <summary>Un tejado por edificio contiguo.</summary>
    /// Esto sí se calcula aquí y no en el extractor: depende de cuántos tejados haya
    /// forjado el arte, que es cosa del juego y no del plano.
    /// <summary>Dónde empieza cada familia dentro de Forja.Tejados y cuántas variantes
    /// tiene: teja, pizarra, azotea y nave, en ese orden.</summary>
    static readonly System.Collections.Generic.Dictionary<string,int[]> FamRango =
        new System.Collections.Generic.Dictionary<string,int[]> {
            {"teja", new[]{0,5}}, {"pizarra", new[]{5,4}}, {"azotea", new[]{9,5}}, {"nave", new[]{14,5}}
        };

    /// <summary>Qué sombrero le toca a un edificio. Los umbrales salen de medir el plano,
    /// no de suponer: la mediana de una manzana son 44 casillas, el percentil 90 son 220 y
    /// el Casco Viejo entero es una sola pieza de 6366. El barrio manda antes que el tamaño
    /// donde se vive, o el casco sale de chapa ondulada.</summary>
    public static string FamiliaTejado(string estilo, int celdas) {
        if (estilo == "industrial") return celdas >= 110 ? "nave" : "azotea";
        if (estilo == "denso") return "teja";
        if (estilo == "senorial") return celdas >= 70 ? "pizarra" : "teja";
        if (celdas >= 900) return "nave";            // cocheras, lonjas, recintos feriales
        if (estilo == "bloques") return celdas >= 45 ? "azotea" : "teja";
        return celdas >= 90 ? "azotea" : "teja";
    }

    public static string FamiliaDe(int idx) {
        foreach (var kv in FamRango)
            if (idx >= kv.Value[0] && idx < kv.Value[0] + kv.Value[1]) return kv.Key;
        return "azotea";
    }

    /// <summary>Casillas de lado del parche de tejado. Una manzana del casco son seis mil
    /// casillas: con un solo tile es una plancha lisa, y por parches se lee lo que es —
    /// muchas casas pegadas— sin inventarse un plano que el municipal no da.</summary>
    const int Parche = 6;

    static void Tejados() {
        var visto = new bool[MW*MH];
        var celdas = new System.Collections.Generic.List<int>();
        System.Array.Clear(Roof, 0, Roof.Length);
        var pila = new System.Collections.Generic.Stack<int>();
        int[] dx = {1,-1,0,0}, dy = {0,0,1,-1};
        for (int y = 0; y < MH; y++)
            for (int x = 0; x < MW; x++) {
                int i0 = y*MW + x;
                if (T(x,y) != Suelo.Edif || visto[i0]) continue;
                celdas.Clear();
                pila.Push(i0); visto[i0] = true;
                while (pila.Count > 0) {
                    int i = pila.Pop(); celdas.Add(i);
                    int cx = i % MW, cy = i / MW;
                    for (int k = 0; k < 4; k++) {
                        int nx = cx + dx[k], ny = cy + dy[k];
                        if (nx < 0 || ny < 0 || nx >= MW || ny >= MH) continue;
                        int j = ny*MW + nx;
                        if (T(nx,ny) == Suelo.Edif && !visto[j]) { visto[j] = true; pila.Push(j); }
                    }
                }
                // El tamaño es del edificio entero, pero el material lo pone el barrio de
                // cada casilla: la manzana del Casco Viejo cruza a Abando, y tomando el
                // estilo del origen el casco entero salía de pizarra.
                int n = celdas.Count;
                foreach (int i in celdas) {
                    var b = BarrioDe(i % MW, i / MW);
                    var r = FamRango[FamiliaTejado(b != null ? b.Estilo : "bloques", n)];
                    Roof[i] = (byte)(r[0] + Utiles.Hash((i % MW)/Parche, (i / MW)/Parche) % r[1]);
                }
            }
    }

    // ═══════════ BÚSQUEDAS ═══════════
    /// <summary>Una casilla cualquiera del vecindario que cumpla la condición.</summary>
    /// Vale para lo que da igual dónde caiga: un peatón, un coche aparcado.
    public static Vector2 Buscar(System.Func<int,int,bool> cond, int cx, int cy, int rad) {
        for (int i = 0; i < 900; i++) {
            int x = cx < 0 ? Utiles.RndI(2, MW-3) : Mathf.Clamp(cx + Utiles.RndI(-rad,rad), 2, MW-3);
            int y = cy < 0 ? Utiles.RndI(2, MH-3) : Mathf.Clamp(cy + Utiles.RndI(-rad,rad), 2, MH-3);
            if (cond(x,y)) return new Vector2(x+0.5f, y+0.5f);
        }
        return new Vector2(MW/2f, MH/2f);
    }

    /// <summary>La casilla válida MÁS cercana al punto, buscando en anillos hacia fuera.</summary>
    /// Los sitios de verdad llevan la coordenada del plano municipal, y correr la catedral
    /// cien metros la saca del Casco Viejo. Los anillos son cuadrados, así que la esquina
    /// de uno queda más lejos que el centro del lado del siguiente: no vale quedarse con
    /// el primero que aparezca, hay que seguir mientras el anillo pueda mejorar.
    public static Vector2 CercaDe(System.Func<int,int,bool> cond, int cx, int cy, int rmax) {
        cx = Mathf.Clamp(cx, 1, MW-2); cy = Mathf.Clamp(cy, 1, MH-2);
        if (cond(cx,cy)) return new Vector2(cx+0.5f, cy+0.5f);
        int mx = -1, my = -1; float mejor = float.MaxValue;
        for (int r = 1; r <= rmax && r < mejor; r++)
            for (int d = -r; d <= r; d++) {
                int[] xs = { cx+d, cx+d, cx-r, cx+r };
                int[] ys = { cy-r, cy+r, cy+d, cy+d };
                for (int k = 0; k < 4; k++) {
                    int x = xs[k], y = ys[k];
                    if (x < 1 || y < 1 || x >= MW-1 || y >= MH-1) continue;
                    float q = Mathf.Sqrt((x-cx)*(x-cx) + (y-cy)*(y-cy));
                    if (q < mejor && cond(x,y)) { mejor = q; mx = x; my = y; }
                }
            }
        return mx < 0 ? new Vector2(cx+0.5f, cy+0.5f) : new Vector2(mx+0.5f, my+0.5f);
    }

    public static Vector2 PuntoAcera(int cx = -1, int cy = -1, int r = 40) {
        return Buscar((x,y) => { var t = T(x,y); return t == Suelo.Acera || t == Suelo.Plaza; }, cx, cy, r);
    }
    public static Vector2 PuntoCalle(int cx = -1, int cy = -1, int r = 40) {
        return Buscar((x,y) => T(x,y) == Suelo.Road, cx, cy, r);
    }
    /// <summary>Acera con fachada detrás y calle delante: donde va un portal de verdad.</summary>
    public static Vector2 PuntoPortal(int cx, int cy, int r = 60) {
        return CercaDe((x,y) => {
            if (T(x,y) != Suelo.Acera) return false;
            int fach = 0, calle = 0;
            int[] dxs = {1,-1,0,0}, dys = {0,0,1,-1};
            for (int k = 0; k < 4; k++) {
                var t = T(x+dxs[k], y+dys[k]);
                if (t == Suelo.Edif) fach++;
                if (t == Suelo.Road) calle++;
            }
            return fach > 0 && calle > 0;
        }, cx, cy, r);
    }
    /// <summary>Para los monumentos: la casilla pisable más próxima que no sea ladera.</summary>
    public static Vector2 PuntoZona(int cx, int cy, int r = 60) {
        return CercaDe((x,y) => { var t = T(x,y); return Andable(t) && t != Suelo.Monte; }, cx, cy, r);
    }
}

}

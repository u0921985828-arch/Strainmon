# -*- coding: utf-8 -*-
"""
Mete en el juego el arte traído de PixelLab que no es un personaje.

Qué entra, y de dónde
---------------------
* **Los diez singulares** del Bilbao del 96, de `dist/pixellab/edificios96/` — planta
  cenital de cada edificio, generada con el propio dibujo del juego como referencia, así
  que la huella es la misma y lo que cambia es que ahora hay tejado, torre y patio donde
  antes había un rectángulo gris.
* **El mobiliario de calle**, de `dist/pixellab/muebles/`: los veintiocho `PROP`.

Y qué no entra, aunque esté bajado
----------------------------------
**Los vehículos.** Se pidieron dos veces, 36 generaciones, y las dos salieron mal: la
primera tirada devolvió los dieciocho **de perfil**, con las cuatro ruedas de lado, que
en una ciudad cenital no es que esté feo, es que no es la vista. La segunda, con
`view='high top-down'` y la vista repetida por delante —lo que sí enderezó los diez
singulares—, enderezó la mitad: el utilitario, la berlina, el deportivo, el autobús y el
furgón de policía volvieron desde arriba, y la ambulancia, los bomberos, la grúa y el
camión de obra siguieron de lado. Y de los que salieron bien, unos apuntan a la derecha y
otros hacia arriba.

Media flota traída y media forjada es peor que la flota entera forjada: por la misma
calle pasarían dos dibujos distintos del mismo coche. Así que los vehículos se quedan
como estaban, que además es lo que tiene librea —siete colores por chasis, más la sirena,
el abollado y el quemado—, y un coche traído tiene el color con el que vino. El arte
bajado se queda en `dist/` por si otra herramienta lo hace mejor.
* **Los suelos**, de `dist/pixellab/suelos/`: de cada tileset Wang de 4×4 se sacan las dos
  casillas puras —la que es todo lo de abajo y la que es todo lo de arriba—, que son las
  únicas que el juego necesita: el juego no autotilea por esquinas, pone un tile por
  casilla. Ocho de nueve: el parque se queda fuera porque su casilla trae **un** arbusto
  legible y, repetida cada 32 px, tapiza el Arenal de papel pintado. El monte, que vino
  sin motivo reconocible, sí entra.

Lo que respeta
--------------
* **No entra un PNG en el repositorio.** Lo que se escribe es un índice de paleta por
  píxel, deflate crudo en base64, exactamente igual que la trama de la ciudad y que las
  hojas de silueta.
* **Los 61 colores mandan**: todo pasa por el mismo criterio de cercanía que usa el juego.
* **El juego nunca depende de que el arte esté.** Lo traído sustituye al forjado cuando
  está; si falta una pieza, o el bloque entero está vacío, se forja como siempre.
* **Nada de texto.** El generador rellena un rótulo con letras inventadas —en el edificio
  de almacenes puso cuatro—, y ni el juego tiene fuente ahí ni esas letras significan
  nada. Se aplanan al traer, fila a fila, con el color que manda en esa fila.

    python3 herramientas/sprites/lote.py       # baja el lote (una vez)
    python3 herramientas/sprites/cenital.py    # repite lo que vino de perfil
    python3 herramientas/sprites/arte.py       # y esto lo mete en el juego

    python3 herramientas/sprites/arte.py --lamina salida.png   # para mirarlo antes
"""
import argparse, os, re, sys

sys.path.insert(0, os.path.dirname(__file__))
import pixellab as PL

RAIZ = PL.RAIZ
HTML = PL.HTML
CS = os.path.join(RAIZ, 'unity', 'BilboCity', 'Assets', 'Scripts', 'Arte', 'Traido.cs')
PIEZAS = os.path.join(RAIZ, 'dist', 'pixellab')

# ── lo que hay que corregir de lo que volvió ────────────────────────────────────────
# Qué variante de `create_image_pro` vale para cada singular. La herramienta devuelve
# cuatro y la 0 es la buena en los diez; esto está para poder cambiar una sin tocar nada
# más el día que una segunda tirada salga mejor.
VARIANTE = {}
# Dos muebles no se traen aunque estén bajados: la placa de calle volvió como un cuadrado
# azul liso —la primera vez traía letras inventadas, y sin ellas no es una placa— y la
# caseta de escalera, como una ruina ardiendo. Los dos los forja el juego mejor.
SIN_TRAER = ('placa', 'caseta')
# Rectángulos que hay que aplanar: el rótulo del edificio de almacenes, donde el generador
# escribió cuatro letras que no son de ningún idioma. Se sustituye cada fila por el color
# que más repite en ella, así que la banda amarilla se queda y las letras se van.
ROTULOS = {'almacenes': [(29, 58, 122, 62)]}

# De qué mitad del tileset Wang sale cada suelo del juego. 'abajo' es el terreno de la
# casilla toda llena; 'arriba', el de la toda vacía. Los pares que el juego no usa
# —hierba/ría, obra/acera— no se traen: su sitio en el juego lo ocupa otra cosa.
SUELOS = {
    'asfalto_acera': {'arriba': 'acera'},
    'acera_adoquin': {'arriba': 'adoquin'},
    # 'acera_hierba' no entra: el generador mete UN arbusto legible en la casilla y, al
    # repetirla cada 32 px, el parque sale de papel pintado. El tile forjado es ruido sin
    # motivo y tapiza sin que se note la rejilla. El monte sí entra porque vino sin motivo.
    'ria_muelle':    {'arriba': 'muelle'},
    'asfalto_via':   {'arriba': 'via'},
    'acera_plaza':   {'arriba': 'plaza'},
    'monte_roca':    {'abajo': 'monte', 'arriba': 'monteRoca'},
}
# Las dos casillas puras del tileset de 4×4, en celdas. Es la convención de PixelLab y no
# se adivina mirando la imagen: se comprobó una por una.
CELDA_ABAJO, CELDA_ARRIBA = (2, 1), (0, 3)
LADO = 32

# ── lectura del juego ───────────────────────────────────────────────────────────────
def _html():
    return open(HTML, encoding='utf-8').read()


def medidas_props(s):
    """El tamaño de cada PROP, leído del juego. Si cambia allí, cambia aquí."""
    return {n: (int(w), int(h))
            for n, w, h in re.findall(r'PROP\.(\w+)=S_\((\d+),(\d+)', s)}


def singulares_juego(s):
    """Los singulares y su medida en casillas, para avisar si la proporción no cuadra."""
    m = re.search(r'const PLANO_SINGULAR=\{(.*?)\n\};', s, re.S)
    if not m:
        raise SystemExit('no encuentro PLANO_SINGULAR en el HTML')
    return {n: (int(w), int(h))
            for n, w, h in re.findall(r'^ (\w+):\[(\d+),(\d+),', m.group(1), re.M)}


# ── el formato del juego ────────────────────────────────────────────────────────────
def _abre(ruta):
    from PIL import Image
    if not os.path.exists(ruta):
        return None
    return Image.open(ruta).convert('RGBA')


def _indices(im, pal):
    """La imagen a un byte por píxel: 0 transparente, y si no la posición en la paleta +1."""
    px = im.load()
    libres = [(i + 1, c) for i, c in enumerate(pal)]
    fuera = bytearray(im.width * im.height)
    cache = {}
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a < 128:
                continue
            k = (r, g, b)
            v = cache.get(k)
            if v is None:
                v = cache[k] = min(libres, key=lambda t: (t[1][0] - r) ** 2
                                   + (t[1][1] - g) ** 2 + (t[1][2] - b) ** 2)[0]
            fuera[y * im.width + x] = v
    return fuera


def _mayoria(im, w, h):
    """Reduce por mayoría al tamaño pedido: el color que más veces sale, sin interpolar.

    Interpolar en pixel art inventa colores a medio camino, y a esta escala eso es un
    halo alrededor de cada forma. Lo transparente cuenta como un color más pero empatando
    pierde: una farola tiene dos píxeles de ancho y redondear a favor del fondo la parte.
    """
    from PIL import Image
    if (im.width, im.height) == (w, h):
        return im
    px = im.load()
    cubos = {}
    for y in range(im.height):
        oy = min(h - 1, y * h // im.height)
        for x in range(im.width):
            ox = min(w - 1, x * w // im.width)
            r, g, b, a = px[x, y]
            d = cubos.setdefault((ox, oy), {})
            k = None if a < 128 else (r, g, b)
            d[k] = d.get(k, 0) + 1
    fuera = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d2 = fuera.load()
    for (ox, oy), d in cubos.items():
        opacos = {c: n for c, n in d.items() if c}
        if not opacos or sum(opacos.values()) * 2 < sum(d.values()):
            continue
        d2[ox, oy] = max(opacos, key=opacos.get) + (255,)
    return fuera


def encaja(im, W, H, margen=1):
    """La pieza recortada a lo que ocupa y metida en la caja del juego, apoyada abajo.

    Apoyada abajo y centrada, porque así es como las dibuja la forja: una farola y un
    árbol se plantan por el pie, no por el centro de su caja. Y nunca se agranda a trozos:
    o cabe entera, o se reduce; agrandar un pixel art por un factor roto deja unas filas
    de dos píxeles de alto y otras de uno, que se ve como un temblor.
    """
    from PIL import Image
    caja = im.getbbox()
    if not caja:
        return None
    im = im.crop(caja)
    cw, ch = max(1, W - margen * 2), max(1, H - margen)
    if im.width > cw or im.height > ch:
        k = min(cw / float(im.width), ch / float(im.height))
        im = _mayoria(im, max(1, int(im.width * k)), max(1, int(im.height * k)))
    fuera = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    fuera.alpha_composite(im, ((W - im.width) // 2, H - im.height - (H > im.height)))
    return fuera


def aplana(im, rects):
    """Aplana unos rectángulos fila a fila con el color que manda en cada fila.

    Es lo que borra un rótulo sin dejar un parche: la banda sigue teniendo su color y su
    sombra, y lo que desaparece son las letras que el generador se inventó encima.
    """
    px = im.load()
    for x0, y0, x1, y1 in rects:
        for y in range(y0, min(y1 + 1, im.height)):
            cuenta = {}
            for x in range(x0, min(x1 + 1, im.width)):
                c = px[x, y]
                cuenta[c] = cuenta.get(c, 0) + 1
            if not cuenta:
                continue
            manda = max(cuenta, key=cuenta.get)
            for x in range(x0, min(x1 + 1, im.width)):
                px[x, y] = manda
    return im


# ── las tres familias ─────────────────────────────────────────────────────────────
def singulares(pal, aviso):
    fuera = {}
    plan = singulares_juego(_html())
    for nombre, (W0, H0) in sorted(plan.items()):
        v = VARIANTE.get(nombre, 0)
        im = _abre(os.path.join(PIEZAS, 'edificios96', '%s-pro%d.png' % (nombre, v)))
        if im is None:
            aviso('singular %s: no está bajado' % nombre)
            continue
        im = aplana(im.convert('RGB'), ROTULOS.get(nombre, [])).convert('RGBA')
        prop = (im.width / float(im.height)) / (W0 / float(H0))
        if not .8 < prop < 1.25:
            aviso('singular %s: la proporción traída no es la del plano (x%.2f)'
                  % (nombre, prop))
        fuera[nombre] = (im.width, im.height, _indices(im, pal))
    return fuera


def muebles(pal, aviso):
    fuera = {}
    for nombre, (W, H) in sorted(medidas_props(_html()).items()):
        if nombre in SIN_TRAER:
            continue
        im = _abre(os.path.join(PIEZAS, 'muebles', nombre + '.png'))
        if im is None:
            aviso('mueble %s: no está bajado' % nombre)
            continue
        im = encaja(im, W, H)
        if im is None:
            aviso('mueble %s: vino en blanco' % nombre)
            continue
        fuera[nombre] = (W, H, _indices(im, pal))
    return fuera


def suelos(pal, aviso):
    fuera = {}
    for fichero, destinos in sorted(SUELOS.items()):
        im = _abre(os.path.join(PIEZAS, 'suelos', fichero + '.png'))
        if im is None:
            aviso('suelo %s: no está bajado' % fichero)
            continue
        for mitad, nombre in sorted(destinos.items()):
            cx, cy = CELDA_ABAJO if mitad == 'abajo' else CELDA_ARRIBA
            c = im.crop((cx * LADO, cy * LADO, cx * LADO + LADO, cy * LADO + LADO))
            if c.getbbox() != (0, 0, LADO, LADO):
                aviso('suelo %s/%s: la casilla pura trae huecos' % (fichero, mitad))
            fuera[nombre] = (LADO, LADO, _indices(c, pal))
    # La vía vertical es la horizontal girada un cuarto de vuelta, como en el juego: es
    # la misma vía, y pedir otra habría dado otro balasto y otro tono de carril.
    if 'via' in fuera:
        w, h, b = fuera['via']
        fuera['viaV'] = (h, w, bytes(b[(h - 1 - (i % h)) * w + i // h]
                                     for i in range(w * h)))
    return fuera


def _cabe(im, lado, hueco):
    """Recortado a lo que ocupa y reducido para que quepa en `lado-2*hueco`, sin agrandar."""
    caja = im.getbbox()
    if not caja:
        return None
    im = im.crop(caja)
    c = lado - hueco * 2
    if im.width > c or im.height > c:
        k = min(c / float(im.width), c / float(im.height))
        im = _mayoria(im, max(1, int(round(im.width * k))), max(1, int(round(im.height * k))))
    return im


def _acolores(im, pal, tope):
    """Deja la pieza en `tope` colores de la paleta como mucho, sin inventar ninguno.

    A 24 px el ojo no distingue una rampa de cinco tonos: la ve sucia. Se guardan los que
    m\u00e1s superficie ocupan y los dem\u00e1s se arriman al m\u00e1s parecido de los que quedan, que
    es lo mismo que hace el juego al cuantizar, solo que con menos colores donde elegir.
    """
    px = im.load()
    cuenta = {}
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a < 128:
                continue
            v = min(range(len(pal)), key=lambda i: (pal[i][0] - r) ** 2
                    + (pal[i][1] - g) ** 2 + (pal[i][2] - b) ** 2)
            cuenta[v] = cuenta.get(v, 0) + 1
    quedan = sorted(cuenta, key=lambda v: -cuenta[v])[:tope]
    cerca = {}
    for v in cuenta:
        cerca[v] = min(quedan, key=lambda q: (pal[q][0] - pal[v][0]) ** 2
                       + (pal[q][1] - pal[v][1]) ** 2 + (pal[q][2] - pal[v][2]) ** 2)
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a < 128:
                px[x, y] = (0, 0, 0, 0)
                continue
            v = min(range(len(pal)), key=lambda i: (pal[i][0] - r) ** 2
                    + (pal[i][1] - g) ** 2 + (pal[i][2] - b) ** 2)
            px[x, y] = tuple(pal[cerca[v]]) + (255,)
    return im


def _contorno(im, neg):
    """El mismo contorno que pone el juego: un p\u00edxel negro alrededor de la silueta.

    No es adorno. Un icono se mira sobre la caja del HUD, sobre la fila oscura del m\u00f3vil
    y sobre el marco claro de la tienda, y sin contorno la mitad se pierden contra el
    fondo. El generador lo pone cuando quiere —se le pidi\u00f3 y volvieron varios sin \u00e9l—,
    as\u00ed que se pone aqu\u00ed, que es donde se puede garantizar.
    """
    from PIL import Image
    px = im.load()
    fuera = im.copy()
    d = fuera.load()
    for y in range(im.height):
        for x in range(im.width):
            if px[x, y][3] >= 128:
                continue
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    a, b = x + dx, y + dy
                    if 0 <= a < im.width and 0 <= b < im.height and px[a, b][3] >= 128:
                        d[x, y] = tuple(neg) + (255,)
                        break
                else:
                    continue
                break
    return fuera


def _centra(im, lado):
    from PIL import Image
    fuera = Image.new('RGBA', (lado, lado), (0, 0, 0, 0))
    fuera.alpha_composite(im, ((lado - im.width) // 2, (lado - im.height) // 2))
    return fuera


def _gris(im, pal, grises):
    """Todo lo opaco al gris de la misma luz. Es el icono apagado, no otro icono."""
    px = im.load()
    luz = lambda c: .299 * c[0] + .587 * c[1] + .114 * c[2]
    orden = sorted(grises, key=lambda i: luz(pal[i]))
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a < 128:
                continue
            L = luz((r, g, b))
            px[x, y] = tuple(pal[min(orden, key=lambda i: abs(luz(pal[i]) - L))]) + (255,)
    return im


def iconos(pal, nombres, aviso):
    """Los 43 del HUD a 24x24, con su contorno y en siete colores como mucho.

    Dos no se piden al generador: son la mitad apagada de una pareja y tienen que ser el
    mismo dibujo que la encendida, o al cambiar de estado parecer\u00eda que cambia el icono.
    """
    from PIL import Image
    sys.path.insert(0, os.path.dirname(__file__))
    import iconos as IC
    # Los nombres de la paleta son los de la rampa, no los apodos del juego: `C.negro`
    # es `tinta`, `C.carbon` es `hormigon0`. El apodo no llega hasta aquí.
    neg = pal[nombres['tinta']]
    # Tres grises y no seis: el apagado lleva encima el tachón en carbón y el contorno
    # en negro, y de los siete que admite un icono ya solo quedan tres libres.
    grises = [nombres[n] for n in ('hormigon0', 'hormigon1', 'hormigon7')]
    fuera, limpio = {}, {}
    for k in sorted(IC.DESCRIPCIONES):
        im = _abre(os.path.join(PIEZAS, 'iconos', k + '.png'))
        if im is None:
            aviso('icono %s: no est\u00e1 bajado' % k)
            continue
        im = _cabe(im, IC.DESTINO, 1)
        if im is None:
            aviso('icono %s: vino en blanco' % k)
            continue
        limpio[k] = _acolores(im, pal, 6)
    for k, de in sorted(IC.DERIVADOS.items()):
        if de not in limpio:
            continue
        limpio[k] = _gris(limpio[de].copy(), pal, grises)
        if k == 'ojoTachado':   # y encima el tach\u00f3n, que es lo que lo distingue
            d = limpio[k].load()
            car = tuple(pal[nombres['hormigon0']]) + (255,)
            n = limpio[k].width
            for i in range(n):
                for t in range(2):
                    x, y = i, n - 1 - i + t
                    if 0 <= y < n:
                        d[x, y] = car
    for k, im in sorted(limpio.items()):
        # Primero a la caja y luego el contorno: si no, el que toca el canto se queda sin.
        im = _contorno(_centra(im, IC.DESTINO), neg)
        fuera[k] = (IC.DESTINO, IC.DESTINO, _indices(im, pal))
    return fuera


# ── la escritura ────────────────────────────────────────────────────────────────────
AVISO = '/* Lo escribe herramientas/sprites/arte.py. Vacío = todo forjado. */'
FAMILIAS = ('singulares', 'muebles', 'suelos', 'iconos')


def _trozos(b64, sangria, comilla="'"):
    """La cadena partida en líneas que quepan. La comilla la pone el idioma de destino."""
    return ',\n'.join('%s%s%s%s' % (sangria, comilla, b64[t:t + 108], comilla)
                      for t in range(0, len(b64), 108))


def cuerpo_js(arte):
    familias = []
    for fam in FAMILIAS:
        piezas = ',\n'.join(
            " %s:[%d,%d,[\n%s].join('')]" % (k, w, h, _trozos(PL.comprimir(b), '  '))
            for k, (w, h, b) in sorted(arte[fam].items()))
        familias.append('%s:{\n%s}' % (fam, piezas))
    return AVISO + '\nconst ARTE={' + ',\n'.join(familias) + '};'


def cuerpo_cs(arte):
    familias = []
    for fam in FAMILIAS:
        piezas = ',\n'.join(
            '        { "%s", new Estampa(%d, %d, new[] {\n%s }) }'
            % (k, w, h, _trozos(PL.comprimir(b), '            ', '"'))
            for k, (w, h, b) in sorted(arte[fam].items()))
        familias.append('    public static readonly Dictionary<string, Estampa> %s '
                        '= new Dictionary<string, Estampa> {\n%s\n    };'
                        % (fam.capitalize(), piezas))
    return AVISO + '\n' + '\n\n'.join(familias)


CABECERA_CS = '''using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using UnityEngine;

namespace BilboCity {

/// <summary>
/// El arte traído de PixelLab que no es un personaje: los singulares, el mobiliario de
/// calle, los chasis de vehículo y los suelos. Este archivo NO se edita a mano: lo
/// escribe herramientas/sprites/arte.py, y herramientas/plano/arte.py comprueba que
/// aquí y en el bloque ARTE del prototipo HTML hay exactamente los mismos bytes.
///
/// El formato es el de siempre en esta casa: un índice de paleta por píxel, 0
/// transparente, deflate crudo en base64. No hay PNG en el repositorio.
///
/// Vacío es un estado válido. Lo traído sustituye a lo forjado cuando está; cuando no,
/// se forja, que es como arrancó el juego y como sigue funcionando sin bajar nada.
/// </summary>
public static class Traido {

    /// Clase y no struct a propósito: la pieza guarda sus píxeles descomprimidos la
    /// primera vez que alguien se los pide, y un struct se copia al sacarlo del
    /// diccionario, así que la caché se perdería en cada copia y se descomprimiría una
    /// vez por consulta.
    public sealed class Estampa {
        public readonly int W, H;
        readonly string[] _b64;
        byte[] _px;
        public Estampa(int w, int h, string[] b64) { W = w; H = h; _b64 = b64; }
        /// <summary>Los índices, descomprimidos la primera vez que alguien pregunta.</summary>
        public byte[] Px {
            get {
                if (_px == null) _px = Inflar(string.Concat(_b64));
                return _px;
            }
        }
    }

    static byte[] Inflar(string b64) {
        var bin = Convert.FromBase64String(b64);
        using (var ms = new MemoryStream(bin))
        using (var ds = new DeflateStream(ms, CompressionMode.Decompress))
        using (var salida = new MemoryStream()) {
            ds.CopyTo(salida);
            return salida.ToArray();
        }
    }

'''
PIE_CS = '''
    /// <summary>La pieza de una familia, o null si no se trajo. El juego nunca depende
    /// de que esté: quien pregunta tiene que saber forjarla.</summary>
    public static Estampa De(Dictionary<string, Estampa> familia, string nombre) {
        Estampa p;
        return familia.TryGetValue(nombre, out p) ? p : null;
    }

    /// <summary>La pieza como lienzo, al tamaño pedido y por vecino más próximo.</summary>
    /// Un singular se dibuja a la medida que le haya cabido —el plano pide treinta y
    /// cuatro casillas y a lo mejor caben diecisiete—, así que el aumento casi nunca es
    /// entero. Copiando píxel a píxel no sale ni un color que no estuviera ya en los 61,
    /// que es justo lo que haría cualquier remuestreo con filtro.
    public static Lienzo ComoLienzo(Estampa p, int w, int h) {
        var pal = Paleta.Lista;
        var L = new Lienzo(w, h);
        var px = p.Px;
        for (int y = 0; y < h; y++) {
            int sy = y * p.H / h;
            for (int x = 0; x < w; x++) {
                int v = px[sy * p.W + x * p.W / w];
                L.Px[y*w + x] = v == 0 ? new Color32(0,0,0,0) : pal[(v-1) % pal.Length];
            }
        }
        return L;
    }
}

}
'''


def _mete(ruta, cuerpo):
    s = open(ruta, encoding='utf-8').read()
    a, b = '/*<<<ARTE*/', '/*ARTE>>>*/'
    if a not in s or b not in s:
        raise SystemExit('no encuentro el bloque ARTE en %s' % ruta)
    i, j = s.index(a), s.index(b)
    open(ruta, 'w', encoding='utf-8').write(s[:i + len(a)] + '\n' + cuerpo + '\n' + s[j:])


def escribir(arte):
    _mete(HTML, cuerpo_js(arte))
    open(CS, 'w', encoding='utf-8').write(
        CABECERA_CS + '/*<<<ARTE*/\n' + cuerpo_cs(arte) + '\n/*ARTE>>>*/\n' + PIE_CS)


def lamina(arte, pal, ruta, esc=3):
    """Todo lo traído en un PNG, para poder mirarlo sin abrir el juego."""
    from PIL import Image
    filas = []
    for fam in FAMILIAS:
        piezas = [(k, w, h, b) for k, (w, h, b) in sorted(arte[fam].items())]
        if piezas:
            filas.append((fam, piezas))
    ancho = max(sum(w + 4 for _, w, _, _ in p) for _, p in filas)
    alto = sum(max(h for _, _, h, _ in p) + 4 for _, p in filas)
    im = Image.new('RGBA', (ancho, alto), (28, 28, 34, 255))
    px = im.load()
    y0 = 0
    for _, piezas in filas:
        x0 = 0
        for _, w, h, b in piezas:
            for y in range(h):
                for x in range(w):
                    v = b[y * w + x]
                    if v:
                        c = pal[(v - 1) % len(pal)]
                        px[x0 + x, y0 + y] = (c[0], c[1], c[2], 255)
            x0 += w + 4
        y0 += max(h for _, _, h, _ in piezas) + 4
    im.resize((ancho * esc, alto * esc), Image.NEAREST).save(ruta)
    print('->', ruta, '%dx%d' % (ancho * esc, alto * esc))


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[1])
    ap.add_argument('--lamina', metavar='SALIDA.PNG',
                    help='vuelca lo traído a un PNG y no escribe en el juego')
    ap.add_argument('--esc', type=int, default=3)
    a = ap.parse_args()

    pal, nombres = PL.paleta()
    avisos = []
    def aviso(t):
        avisos.append(t)
        print('  ¡ojo!', t, flush=True)
    arte = {'singulares': singulares(pal, aviso), 'muebles': muebles(pal, aviso),
            'suelos': suelos(pal, aviso), 'iconos': iconos(pal, nombres, aviso)}
    for fam in FAMILIAS:
        print('%-11s %d piezas · %d KB sin comprimir'
              % (fam, len(arte[fam]), sum(len(b) for _, _, b in arte[fam].values()) / 1024))
    if a.lamina:
        lamina(arte, pal, a.lamina, a.esc)
        sys.exit(0)
    escribir(arte)
    peso = sum(len(PL.comprimir(b)) for f in FAMILIAS for _, _, b in arte[f].values()) / 1024
    print('-> %s\n-> %s  (%.0f KB de arte%s)'
          % (HTML, CS, peso, ', %d avisos' % len(avisos) if avisos else ''))

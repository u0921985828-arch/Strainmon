#!/usr/bin/env python3
"""Compara los números del juego entre el HTML y Unity.

La trampa de siempre con dos implementaciones, y con los números es la peor de todas: el
HTML pasa la batería, el C# no se ejecuta aquí, y Unity acaba cobrando otro alquiler o
pegando otro daño. No sale ningún error — sale otro juego, equilibrado de otra manera, y
no se ve hasta que alguien juega las dos versiones seguidas.

Esto no mira el arte ni la geometría, que ya tienen su comparador (`paleta.py`,
`sitios.py`, `singulares.py`, `calles.py`, `siluetas.py`, `arte.py`). Mira lo que decide
si un curro compensa: las armas, las puertas de nivel, los curros, las propiedades, la
ropa y lo que pagan las misiones, incluidos sus límites de tiempo.

Los textos no se comparan a propósito: el HTML y Unity pueden redactar distinto sin que
el juego cambie, y exigir la coma en el mismo sitio sería un verificador que falla por
nada. Lo que no puede diferir es el número.

    python3 herramientas/plano/reglas.py
"""
import re, sys, pathlib

RAIZ = pathlib.Path(__file__).resolve().parents[2]
HTML = RAIZ / 'referencia' / 'bilbo-city.html'
CS = RAIZ / 'unity' / 'BilboCity' / 'Assets' / 'Scripts'
ESTADO = CS / 'Juego' / 'Estado.cs'
BIENES = CS / 'Juego' / 'Bienes.cs'
ACCIONES = CS / 'Juego' / 'Acciones.cs'
MISIONES = CS / 'Juego' / 'Misiones.cs'
PARROQ = CS / 'Juego' / 'Parroquiano.cs'
INTERIORES = CS / 'Juego' / 'Interiores.cs'


def _bloque(texto, abre, cierra):
    """El trozo entre `abre` y el primer `cierra` que le sigue, sin incluirlos."""
    i = texto.index(abre) + len(abre)
    return texto[i:texto.index(cierra, i)]


def _num(v):
    """A número, tragándose la f de los float de C# y el true/false de los dos lados."""
    v = v.strip().rstrip('f').rstrip()
    if v in ('true', 'True'):
        return 1
    if v in ('false', 'False'):
        return 0
    try:
        return round(float(v), 4)
    except ValueError:
        return v.strip('"\'')


def _entradas(bloque, corte):
    """Parte el bloque por `corte` y devuelve un trozo por entrada, sin el primero."""
    return bloque.split(corte)[1:]


# ── las armas ──────────────────────────────────────────────────────────────────────────

# El HTML las escribe en minúscula y Unity con la inicial en mayúscula; `disp` no se
# escribe cuando vale 1, así que el defecto va aquí y no en el lector de cada lado.
CAMPOS_ARMA = {'dmg': 'Dmg', 'alc': 'Alc', 'cad': 'Cad', 'vel': 'Vel', 'disp': 'Disp',
               'spread': 'Spread', 'precio': 'Precio', 'balas': 'Balas', 'pack': 'Pack'}
DEFECTO_ARMA = {'disp': 1, 'vel': 0, 'spread': 0, 'precio': 0, 'balas': 0, 'pack': 0}


def armas_html(s):
    fuera = {}
    for e in _entradas(_bloque(s, 'const ARMAS=[', '\n];'), '{id:'):
        ide = re.match(r"'([^']+)'", e).group(1)
        f = dict(DEFECTO_ARMA)
        for k in CAMPOS_ARMA:
            m = re.search(r'\b%s:([-\d.]+)' % k, e)
            if m:
                f[k] = _num(m.group(1))
        fuera[ide] = f
    return fuera


def armas_cs(s):
    fuera = {}
    for e in _entradas(_bloque(s, 'Todas = new List<Arma> {', '\n    };'), 'new Arma{'):
        ide = re.search(r'Id="([^"]+)"', e).group(1)
        f = dict(DEFECTO_ARMA)
        for k, K in CAMPOS_ARMA.items():
            m = re.search(r'\b%s=([-\d.]+f?)' % K, e)
            if m:
                f[k] = _num(m.group(1))
        fuera[ide] = f
    return fuera


# ── las puertas de nivel ───────────────────────────────────────────────────────────────

def niveles_html(s, nombre):
    b = _bloque(s, 'const %s={' % nombre, '}')
    return {k: int(v) for k, v in re.findall(r'(\w+):(\d+)', b)}


def niveles_cs(s, nombre):
    b = _bloque(s, '%s = new Dictionary<string,int> {' % nombre, '};')
    return {k: int(v) for k, v in re.findall(r'\{"(\w+)",(\d+)\}', b)}


# ── los curros ─────────────────────────────────────────────────────────────────────────

def curros_html(s):
    fuera = {}
    for e in _entradas(_bloque(s, 'const CURROS=[', '\n];'), '{id:'):
        ide = re.match(r"'([^']+)'", e).group(1)
        fuera[ide] = {
            'base': _num(re.search(r'\bbase:(\d+)', e).group(1)),
            'req': _num(re.search(r'\breq:(\d+)', e).group(1)),
            'gremio': re.search(r"\bg:'(\w+)'", e).group(1),
            'turbio': 1 if "tipo:'turbio'" in e else 0,
            'furgo': 1 if 'furgo:true' in e else 0}
    return fuera


def curros_cs(s):
    fuera = {}
    for e in _entradas(_bloque(s, 'ListaCurros = new List<Curro> {', '\n    };'), 'new Curro{'):
        ide = re.search(r'Id="(\w+)"', e).group(1)
        req = re.search(r'\bReq=(\d+)', e)
        fuera[ide] = {
            'base': _num(re.search(r'\bBase_=(\d+)', e).group(1)),
            'req': int(req.group(1)) if req else 0,
            'gremio': re.search(r'Gremio="(\w+)"', e).group(1),
            'turbio': 1 if 'Turbio=true' in e else 0,
            'furgo': 1 if 'NecesitaFurgo=true' in e else 0}
    return fuera


# ── las propiedades ────────────────────────────────────────────────────────────────────

def props_html(s):
    fuera = {}
    for e in _entradas(_bloque(s, 'const PROPIEDADES=[', '\n];'), '{id:'):
        ide = re.match(r"'(\w+)'", e).group(1)
        renta = re.search(r'\brenta:\s*(\d+)', e)
        fuera[ide] = {
            'precio': int(re.search(r'\bprecio:\s*(\d+)', e).group(1)),
            'nivel': int(re.search(r'\bnivel:\s*(\d+)', e).group(1)),
            'renta': int(renta.group(1)) if renta else 0,
            'tipo': re.search(r"\btipo:'(\w+)'", e).group(1)}
    return fuera


def props_cs(s):
    fuera = {}
    for e in _entradas(_bloque(s, 'Todas = new List<Propiedad> {', '\n    };'), 'new Propiedad{'):
        ide = re.search(r'Id="(\w+)"', e).group(1)
        renta = re.search(r'\bRenta=\s*(\d+)', e)
        fuera[ide] = {
            'precio': int(re.search(r'\bPrecio=\s*(\d+)', e).group(1)),
            'nivel': int(re.search(r'\bNivel=\s*(\d+)', e).group(1)),
            'renta': int(renta.group(1)) if renta else 0,
            'tipo': re.search(r'Tipo="(\w+)"', e).group(1)}
    return fuera


# ── la ropa ────────────────────────────────────────────────────────────────────────────
# La clave es ranura+variante y no el orden: la tienda las puede listar como quiera, pero
# una cazadora no puede costar 80 en un sitio y 70 en el otro.

def prendas_html(s):
    fuera = {}
    for e in _entradas(_bloque(s, 'const PRENDAS=[', '\n];'), '{r:'):
        r = re.match(r"\s*'(\w+)'", e).group(1)
        v = re.search(r"\bv:\s*'(\w+)'", e).group(1)
        fuera[r + '/' + v] = {'precio': int(re.search(r'\bprecio:\s*(\d+)', e).group(1))}
    return fuera


def prendas_cs(s):
    fuera = {}
    for r, v, precio in re.findall(
            r'Pr\("(\w+)","(\w+)",\s*"[^"]*","[^"]*","[^"]*",(\d+)\)', s):
        fuera[r + '/' + v] = {'precio': int(precio)}
    return fuera


# ── las misiones ───────────────────────────────────────────────────────────────────────
# Van por orden y no por nombre: el nombre es texto y el orden es la progresión, que es
# justo lo que no puede diferir. De cada una, lo que paga y los límites de tiempo de sus
# pasos, en el orden en que se ponen.

def misiones_html(s):
    return _conLimites(_bloque(s, 'const MISIONES=[', '\n];'),
                       r'\bpago:(\d+)', r'\blimite:(\d+)')


def misiones_cs(s):
    b = _bloque(s, 'Lista = new List<DefMision> {', '\n        };')
    return _conLimites(b, r'\bPago=(\d+)', r'\bLimite\s*=\s*(\d+)')


def _conLimites(bloque, repago, relimite):
    """Una entrada por misión: lo que paga y los límites que aparecen hasta la siguiente."""
    pagos = list(re.finditer(repago, bloque))
    fuera = []
    for i, m in enumerate(pagos):
        fin = pagos[i + 1].start() if i + 1 < len(pagos) else len(bloque)
        fuera.append({'pago': int(m.group(1)),
                      'limites': [int(x) for x in re.findall(relimite, bloque[m.end():fin])]})
    return fuera


# ── las constantes sueltas ─────────────────────────────────────────────────────────────
# Lo que no vive en una tabla y aun así decide el equilibrio. Cada una se busca con su
# propia expresión en cada lado, porque el HTML y Unity las escriben distinto; lo que se
# compara es el número. Si una deja de encontrarse, el verificador lo canta en vez de
# dar por buena una comparación que ya no mira nada — que es el fallo clásico de esto.
CONSTANTES = {
    'dinero inicial':      (r'\bdinero:(\d+)',               r'\bDinero = ([\d.]+)f?'),
    'salud inicial':       (r'\bhp:(\d+)',                   r'\bHp = ([\d.]+)f?'),
    'hora de arranque':    (r'\bmin:(\d+)\*60',              r'\bMin = (\d+)\*60'),
    'alquiler':            (r'\balquiler:(\d+)',             r'\bAlquiler = (\d+)'),
    'xp por nivel · base': (r'XP_NIVEL=n=>Math\.round\((\d+)', r'XpNivel\(int n\).*?(\d+)f \* Mathf\.Pow'),
    'xp por nivel · curva': (r'Math\.pow\(n,([\d.]+)\)',     r'Mathf\.Pow\(n, ([\d.]+)f\)'),
    'salud al salir del hospital': (r'S\.hp=(\d+);S\.dinero=Math\.max',
                                    r'E\.Hp = (\d+);\s*\n\s*E\.Dinero = Mathf\.Max'),
    'parte del dinero que se queda el hospital':
        (r'S\.dinero\*\.(\d+)\)\)', r'E\.Dinero \* 0\.(\d+)f'),
    'cono de auto-apuntado a enemigos':  (r"cono=\(mx\|\|my\)\?[\d.]+:([\d.]+)",
                                          r'CONO_ENEMIGO = ([\d.]+)f'),
    'cono de auto-apuntado a viandantes': (r'if\(df<([\d.]+)\)\{obj=p;break;\}',
                                           r'CONO_VIANDANTE = ([\d.]+)f'),
    'alcance extra contra enemigos':  (r'md=a\.alc\+\.(\d+)', r'md = a\.Alc \+ 0\.(\d+)f'),
    'alcance extra contra viandantes': (r'd>a\.alc\+\.(\d+)\)continue;\n\s*const ang=Math\.atan2\(p\.y',
                                        r'd > a\.Alc \+ 0\.(\d+)f\) continue;'),
    'xp del golpe por la espalda': (r"darXp\((\d+)\);aviso\('Por la espalda'", r'DarXp\((\d+)\);'),
    'xp al acabar una misión': (r'darXp\(Math\.round\(m\.def\.pago\*([\d.]+)\)',
                                r'DarXp\(Mathf\.RoundToInt\(def\.Pago \* ([\d.]+)f\)'),
    'xp al acabar un curro': (r'darXp\(Math\.max\(6,Math\.round\(j\.pago\*\.(\d+)\)',
                              r'DarXp\(Mathf\.Max\(6, Mathf\.RoundToInt\(Pago \* 0\.(\d+)f\)'),
    'cuánto tira el parroquiano de lo concreto':
        (r'const PARROQ_CONTEXTO=(\.?[\d.]+);', r'Contexto = (\.?[\d.]+)f;'),
}


def constantes(hs, cs):
    """Las dos caras de cada constante, o `None` donde no se encontró."""
    a, b = {}, {}
    for nombre, (rh, rc) in CONSTANTES.items():
        mh = re.search(rh, hs, re.S)
        mc = re.search(rc, cs, re.S)
        a[nombre] = _num(mh.group(1)) if mh else None
        b[nombre] = _num(mc.group(1)) if mc else None
    return a, b


# ── el parroquiano ─────────────────────────────────────────────────────────────────────
# Aquí sí se mira algo que no es un número, y la raya está en un sitio concreto: se
# comparan las **etiquetas** de las frases —la etiqueta es la condición, o sea código— y
# nunca su texto, que es redacción y puede escribirse distinto en cada lado sin que el
# juego cambie. Una frase que falte en Unity sí lo cambia: el parroquiano de allí no se
# entera de que debes dos recibos. Y se comparan los habitantes de cada barra, nombre
# incluido, porque un nombre propio no es redacción: es quién está detrás del vaso.

def _trozo(texto, abre, cierra):
    """Como `_bloque`, pero vacío si el ancla ya no está. Quien lo llame tiene que tratar
    el vacío como un fallo: un comparador que no encuentra su tabla no puede dar verde."""
    i = texto.find(abre)
    if i < 0:
        return ''
    j = texto.find(cierra, i + len(abre))
    return texto[i + len(abre):j if j >= 0 else len(texto)]


def frases_html(h):
    return re.findall(r"\{t:'(\w+)'", _trozo(h, 'const FRASES_PARROQ=[', '\n];'))


def frases_cs(c):
    return re.findall(r'F\("(\w+)"',
                      _trozo(c, 'public static readonly FraseParroquiano[] Frases = {', '\n    };'))


def habituales_html(h):
    return {k: (n, a) for k, n, a in
            re.findall(r"(\w+):\s*\{n:'([^']+)',\s*arq:'([^']+)'\}",
                       _trozo(h, 'const PARROQUIANO_DE={', '\n};'))}


def habituales_cs(c):
    return {k: (n, a) for k, n, a in
            re.findall(r'\{"(\w+)",\s*new NpcInterior\{ Nombre="([^"]+)",\s*Arq="([^"]+)" \}\}',
                       _trozo(c, 'ParroquianoDe =', '\n        };'))}


# ── el careo ───────────────────────────────────────────────────────────────────────────

def compara(que, a, b):
    fuera = []
    for k in sorted(set(a) | set(b)):
        if k not in b:
            fuera.append('  falta en Unity: %s %s' % (que, k))
        elif k not in a:
            fuera.append('  sobra en Unity: %s %s' % (que, k))
        elif a[k] != b[k]:
            for campo in sorted(set(a[k]) | set(b[k])) if isinstance(a[k], dict) else []:
                if a[k].get(campo) != b[k].get(campo):
                    fuera.append('  no cuadra: %s %s.%s  HTML %s · Unity %s'
                                 % (que, k, campo, a[k].get(campo), b[k].get(campo)))
            if not isinstance(a[k], dict):
                fuera.append('  no cuadra: %s %s  HTML %s · Unity %s' % (que, k, a[k], b[k]))
    return fuera


def main():
    h = HTML.read_text()
    estado, bienes, acciones, misiones = (p.read_text() for p in
                                          (ESTADO, BIENES, ACCIONES, MISIONES))
    parroq, interiores = PARROQ.read_text(), INTERIORES.read_text()

    mh, mc = misiones_html(h), misiones_cs(misiones)
    problemas = (
        compara('arma', armas_html(h), armas_cs(estado))
        + compara('nivel de arma', niveles_html(h, 'NIVEL_ARMA'),
                  niveles_cs(bienes, 'NivelArma'))
        + compara('nivel de vehículo', niveles_html(h, 'NIVEL_VEHICULO'),
                  niveles_cs(bienes, 'NivelVehiculo'))
        + compara('curro', curros_html(h), curros_cs(estado))
        + compara('propiedad', props_html(h), props_cs(bienes))
        + compara('prenda', prendas_html(h), prendas_cs(acciones))
        + compara('misión', dict(enumerate(mh)), dict(enumerate(mc)))
        + compara('habitual de la barra', habituales_html(h), habituales_cs(interiores)))

    # Las etiquetas van en orden y se comparan como secuencia: dos frases con la misma
    # etiqueta son dos frases distintas, y un diccionario se las comería.
    eh, ec = frases_html(h), frases_cs(parroq)
    hh, hc = habituales_html(h), habituales_cs(interiores)
    if not eh or not ec or not hh or not hc:
        sys.exit('no encontré las tablas del parroquiano: frases HTML %d · Unity %d, '
                 'barras HTML %d · Unity %d' % (len(eh), len(ec), len(hh), len(hc)))
    if eh != ec:
        problemas.append('  las frases del parroquiano no son las mismas:'
                         '\n    HTML  %s\n    Unity %s' % (eh, ec))

    # Las constantes, aparte: aquí «no encontrada» es un fallo por sí solo, y con el
    # careo normal pasaría por un None igual a otro None.
    ch, cc = constantes(h, estado + bienes + acciones + misiones + parroq
                        + (CS / 'Juego' / 'Juego.cs').read_text())
    for k in sorted(CONSTANTES):
        if ch[k] is None or cc[k] is None:
            problemas.append('  ya no encuentro: %s (HTML %s · Unity %s)'
                             % (k, ch[k], cc[k]))
        elif ch[k] != cc[k]:
            problemas.append('  no cuadra: %s  HTML %s · Unity %s' % (k, ch[k], cc[k]))

    cuantos = (len(armas_html(h)), len(curros_html(h)), len(props_html(h)),
               len(prendas_html(h)), len(mh))
    if not all(cuantos):
        sys.exit('no encontré alguna de las tablas en el HTML: %r' % (cuantos,))
    if problemas:
        print('\n'.join(problemas))
        sys.exit('los números del juego no cuadran entre el HTML y Unity')
    print('%d armas · %d curros · %d propiedades · %d prendas · %d misiones y %d '
          'constantes, con los mismos números en los dos' % (cuantos + (len(CONSTANTES),)))
    print('%d frases de parroquiano con las mismas %d etiquetas y %d barras con el mismo '
          'habitual' % (len(eh), len(set(eh)), len(habituales_html(h))))


if __name__ == '__main__':
    main()

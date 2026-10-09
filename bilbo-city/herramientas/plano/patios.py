#!/usr/bin/env python3
"""Carea el interior de manzana —y el hash que lo coloca— entre el HTML y Unity.

Los patios no están en el plano municipal: los abre el juego, casilla a casilla, con el
mismo recorrido y la misma siembra por hash en las dos implementaciones. Si una sola de
esas dos cosas se mueve, el HTML y Unity abren los patios en sitios distintos y no salta
ningún error: sale otra ciudad, con los portales en otras manzanas.

Y aquí hay una trampa que ya mordió una vez. `hash()` del HTML y `Utiles.Hash()` de Unity
eran la MISMA función escrita de dos maneras, y daban cosas distintas en el 98 % de las
casillas: el segundo producto en JS iba con `*`, que multiplica en coma flotante y pierde
los bits bajos —justo los que luego se piden con un módulo— mientras que C# multiplica
enteros de 32 bits con vuelta. Tejados, farolas y flechas distintas en cada versión. Por
eso el hash se carea aquí y no en `reglas.py`: es lo que decide dónde va cada patio.

Cómo se carea el hash, que tiene su límite y conviene saberlo: el C# no se puede ejecutar
en este contenedor —no hay Unity, y el remedo de `herramientas/compilar/` solo tiene
firmas—, así que lo que se compara no son valores sino la **forma** de las dos
expresiones, reducida a una secuencia canónica de operaciones de 32 bits. Un `*` de JS y
un `Math.imul` no son la misma operación y se canonizan distinto, que es exactamente el
fallo que hubo. Si alguna de las dos deja de tener la forma que se sabe leer, esto falla
diciéndolo en vez de dar verde por no encontrar nada.

    python3 herramientas/plano/patios.py
"""
import re, sys, pathlib

RAIZ = pathlib.Path(__file__).resolve().parents[2]
HTML = RAIZ / 'referencia' / 'bilbo-city.html'
CS = RAIZ / 'unity' / 'BilboCity' / 'Assets' / 'Scripts'
CIUDAD = CS / 'Ciudad' / 'Ciudad.cs'
PALETA = CS / 'Arte' / 'Paleta.cs'


# ── las constantes del patio ───────────────────────────────────────────────────────
# Nombre legible → (expresión en el HTML, expresión en el C#). Una que deje de
# encontrarse es un fallo por sí sola: si no, el día que alguien renombre PATIO_MURO el
# careo pasa a comparar None con None y sigue dando verde.
CONSTANTES = {
    'cada cuántas casillas se intenta un patio':
        (r'const PATIO_SEMBRADO=(\d+)', r'PatioSembrado = (\d+)'),
    'lado mínimo del patio':
        (r'const PATIO_LADO=(\d+)', r'PatioLado = (\d+)'),
    'cuántos lados distintos puede tener':
        (r'const PATIO_LADO=\d+, PATIO_VAR=(\d+)', r'PatioLado = \d+, PatioVar = (\d+)'),
    'casillas de edificio alrededor':
        (r'const PATIO_MURO=(\d+)', r'PatioMuro = (\d+)'),
    'casillas como mucho de portal':
        (r'const PATIO_PORTAL=(\d+)', r'PatioPortal = (\d+)'),
    'segundos que tarda la tapa':
        (r'const PATIO_SEG=(\.?\d+(?:\.\d+)?)', r'PatioSeg = (\.?\d+(?:\.\d+)?)f'),
}


def _num(v):
    return round(float(v if not v.startswith('.') else '0' + v), 4)


def _busca(texto, patron):
    m = re.search(patron, texto)
    return _num(m.group(1)) if m else None


# ── el hash, reducido a su forma ───────────────────────────────────────────────────
def _canon_js(texto):
    """La forma de hash() del HTML, o None si ya no es la que se sabe leer."""
    m = re.search(r'function hash\(a,b\)\{(.*?)\n?\s*return ([^;]+);\}', texto, re.S)
    if not m:
        return None
    cuerpo, vuelve = m.group(1), m.group(2)
    pasos = []
    # Math.imul es el producto de 32 bits con vuelta; un `*` suelto NO lo es, y se marca
    # distinto a propósito: esa diferencia es la que daba dos ciudades.
    for a, k in re.findall(r'Math\.imul\((\w+),(\d+)\)', cuerpo):
        pasos.append('mul32(%s,%s)' % (a, k))
    for a, k in re.findall(r'(?<!imul\()(\b\w+\b)\s*\*\s*(\d+)', cuerpo):
        pasos.append('mulf(%s,%s)' % (a, k))
    pasos += ['shr%s' % d for d in re.findall(r'>>(\d+)', cuerpo)]
    mi = re.search(r'Math\.imul\(h\^\(h>>(\d+)\),(\d+)\)', cuerpo)
    if mi:
        pasos.append('mezcla(%s,%s)' % mi.groups())
    pasos.append('abs' if vuelve.startswith('Math.abs') else 'tal cual')
    pasos += ['ret>>%s' % d for d in re.findall(r'>>(\d+)', vuelve)]
    return ' '.join(pasos)


def _canon_cs(texto):
    """La misma forma, leída del C#. Ahí el producto de dos int ya es de 32 bits con
    vuelta, así que `*` canoniza a mul32; si alguna vez se escribiera en double habría
    que distinguirlo igual que en JS."""
    m = re.search(r'public static int Hash\(int a, int b\) \{(.*?)return ([^;]+);',
                  texto, re.S)
    if not m:
        return None
    cuerpo, vuelve = m.group(1), m.group(2)
    if 'double' in cuerpo or 'float' in cuerpo:
        return 'en coma flotante: no es el mismo producto'
    pasos = []
    for a, k in re.findall(r'\(?(\b[ab]\b) \* (\d+)\)?', cuerpo):
        pasos.append('mul32(%s,%s)' % (a, k))
    pasos += ['shr%s' % d for d in re.findall(r'>> (\d+)', cuerpo)]
    mi = re.search(r'\(h \^ \(h >> (\d+)\)\) \* (\d+)', cuerpo)
    if mi:
        pasos.append('mezcla(%s,%s)' % mi.groups())
    pasos.append('abs' if 'Abs' in vuelve else 'tal cual')
    pasos += ['ret>>%s' % d for d in re.findall(r'>> (\d+)', vuelve)]
    return ' '.join(pasos)


def main():
    h = HTML.read_text(encoding='utf8')
    c = CIUDAD.read_text(encoding='utf8')
    p = PALETA.read_text(encoding='utf8')
    problemas = []

    for nombre in sorted(CONSTANTES):
        ph, pc = CONSTANTES[nombre]
        vh, vc = _busca(h, ph), _busca(c, pc)
        if vh is None or vc is None:
            problemas.append('  ya no encuentro: %s (HTML %s · Unity %s)' % (nombre, vh, vc))
        elif vh != vc:
            problemas.append('  no cuadra: %s  HTML %s · Unity %s' % (nombre, vh, vc))

    fh, fc = _canon_js(h), _canon_cs(p)
    if fh is None or fc is None:
        problemas.append('  el hash ya no tiene la forma que sé leer (HTML %s · Unity %s)'
                         % (fh, fc))
    elif fh != fc:
        problemas.append('  el hash no es la misma operación:\n    HTML  %s\n    Unity %s'
                         % (fh, fc))

    # Y que el recorrido siga siendo el mismo: las dos piezas que, si se tocan en un lado
    # y no en el otro, mueven los patios sin que nada más se entere.
    for que, ph, pc in (
            ('la siembra va por hash(x,y)',
             r'if\(map\[y\*MW\+x\]!==EDIF\|\|hash\(x,y\)%PATIO_SEMBRADO\)',
             r'Utiles\.Hash\(x,y\) % PatioSembrado != 0'),
            ('el lado sale de hash(x,y*3) y hash(y*3,x)',
             r'PATIO_LADO\+hash\(x,y\*3\)%PATIO_VAR.*PATIO_LADO\+hash\(y\*3,x\)%PATIO_VAR',
             r'Utiles\.Hash\(x, y\*3\) % PatioVar;.*Utiles\.Hash\(y\*3, x\) % PatioVar;'),
            ('el portal se prueba al sur, al norte, al este y al oeste, en ese orden',
             r'\[\[0,1,cx,y\+h-1\],\[0,-1,cx,y\],\[1,0,x\+w-1,cy\],\[-1,0,x,cy\]\]',
             r'ddx = \{0,0,1,-1\}, ddy = \{1,-1,0,0\}')):
        if not re.search(ph, h, re.S):
            problemas.append('  el HTML ya no hace esto: %s' % que)
        if not re.search(pc, c, re.S):
            problemas.append('  Unity ya no hace esto: %s' % que)

    if problemas:
        print('\n'.join(problemas))
        sys.exit('el interior de manzana no cuadra entre el HTML y Unity')
    print('%d constantes del patio y el hash que lo siembra, iguales en los dos (%s)'
          % (len(CONSTANTES), fh))


if __name__ == '__main__':
    main()

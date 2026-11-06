# ejemplo_banqueta.py  ·  python3 -I ejemplo_banqueta.py [carpeta de salida]   (Python 3 + Pillow)
# Plantilla de la skill sprites-a-mano: un mueble sencillo dibujado píxel a píxel, con su ficha, su
# paleta cerrada, la luz de arriba a la izquierda y dos fotogramas de un idle de 1 px. Cópiala, cambia
# la ficha y dibuja lo tuyo; lo que no cambies (estructura, contorno, guardado) ya cumple el QA.
#  · banqueta (celda 32 × 32, ancla (16, 31): el centro de abajo, donde pisa el suelo): taburete de
#    madera de 45 cm de alto y 34 de ancho, visto de frente en alzado recto, con su sombra en el suelo.
#    Fotogramas: 00 quieto, 01 el mismo subido 1 px (para un vaivén de 2 fotogramas).
# Escala: 16 px = 1 m → 45 cm de alto son 7 px de asiento + patas hasta 7 px más.
# Vista: alzado recto. Luz: de arriba a la izquierda. Paleta: los 7 colores de abajo, ninguno más.
# Sale a <carpeta>/banqueta_00.png y _01.png (por defecto, la carpeta de trabajo).
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'scripts'))
from lienzo import Lienzo   # noqa: E402

# paleta cerrada: contorno, madera (sombra, base, luz), metal y la sombra del suelo
NEGRO = '#2a2a34'
MAD_S, MAD_B, MAD_L = '#6b4522', '#8d5d2e', '#b07c45'
MET_S, MET_B = '#4a4e5a', '#6d737f'
SOMBRA = '#1f2029'

W, H = 32, 32
ANCLA = (16, 31)


def banqueta(sube=0):
    """el taburete entero; `sube` levanta el mueble esos px (sin mover su sombra)"""
    L = Lienzo(W, H)
    # la sombra del suelo, siempre en su sitio: es lo que fija el pivote entre fotogramas
    L.hl(8, 23, 30, SOMBRA)
    L.hl(10, 21, 31, SOMBRA)

    y0 = 12 - sube                      # fila de arriba del asiento
    # asiento: base, luz arriba y a la izquierda, sombra abajo y a la derecha
    L.r(6, y0, 20, 5, MAD_B)
    L.hl(6, 24, y0, MAD_L)
    L.vl(6, y0, y0 + 3, MAD_L)
    L.hl(7, 25, y0 + 4, MAD_S)
    L.vl(25, y0 + 1, y0 + 4, MAD_S)

    # cuatro patas: las dos de atrás más oscuras y 1 px más cortas (medio fondo)
    for x in (9, 20):
        L.vl(x, y0 + 5, 27 - sube, MAD_S)
    for x in (7, 23):
        L.vl(x, y0 + 5, 28 - sube, MAD_B)
        L.p(x, y0 + 5, MAD_L)

    # el travesaño metálico que las une
    L.hl(7, 23, 23 - sube, MET_B)
    L.hl(7, 23, 24 - sube, MET_S)

    L.contorno(NEGRO)
    return L


def main(argv):
    destino = argv[1] if len(argv) > 1 else '.'
    for i, sube in enumerate((0, 1)):
        f = banqueta(sube).guarda(destino, 'banqueta_%02d.png' % i)
        print('banqueta: %s' % f)
    print('ahora: python3 -I ../scripts/qa_pixel.py \'{"size":[32,32],"palette":["%s","%s","%s","%s","%s","%s","%s"]}\' '
          '%s/banqueta_*.png' % (NEGRO, MAD_S, MAD_B, MAD_L, MET_S, MET_B, SOMBRA, destino))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))

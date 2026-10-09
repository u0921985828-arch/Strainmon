# python3 -I tools/sprites/a-mano/salon.py  (Python 3 + Pillow; no va en los scripts de npm)
# Lámina 14 (1.10): los muebles del salón del piso, que se compran por internet, dibujados a mano a 16 px/m como la nevera y las
# cajas (equipo_p5.py): el frente a su ancho y alto reales y la tapa a medio fondo. Cada uno ocupa 2 casillas de ancho
# (celda mueble_ancho, 48 × 48, base en (16, 47) = el centro de la casilla de la izquierda; el mueble, centrado en x 24).
#  · sofa: sofá de 2 plazas (180 × 85 × 90 cm) visto por detrás (mira a la tele): el respaldo, su rulo y los brazos asomando.
#  · tv: tele de 43" (97 × 56 cm) sobre un mueble bajo (140 × 45 × 40 cm) con la consola en el hueco del medio.
#  · gpc: mesa gaming (140 × 75 × 70 cm) con el monitor de 27", el teclado y la torre con los ventiladores encendidos.
# Y los iconos del menú START que faltaban (celda icono, 16 × 16, como los aprobados: contorno #2a2a34, luz arriba a la izquierda):
#  · movil (el móvil, con la pantalla encendida), guardar (la libreta de la tía), altavoz y salir (la puerta entornada y la flecha).
#  · cogollo (la Genoteca): un cogollo fresco, verde, con los cálices apilados, pistilos naranjas y la escarcha de los tricomas
#    (sustituye al de PixelLab, que parecía seco y marrón; icono() mira antes en iconos-menu).
# Sale a art/crudo/<grupo>/<sprite>/unica/00.png, grupos salon e iconos-menu (después, node tools/sprites/procesar.js <grupo> --atlas)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P

SAL = {}
def sale(n, L, grupo='salon'):
    SAL.setdefault(grupo, {})[n] = L

def suelo(L, x0, x1, c):
    """apoya en el suelo: en la última fila, contorno bajo lo que llega a la 46"""
    for x in range(x0, x1 + 1):
        if L.lleno(x, 46) and not L.lleno(x, 47): L.p(x, 47, c)

def sofa():
    L = Lienzo(48, 48); x0, x1 = 10, 38                                  # 29 px = 180 cm
    S0, S1, S2, S3 = '#2c3a52', '#3e5272', '#566e94', '#7890b6'
    # los brazos, que asoman por detrás del respaldo a lo lejos (60 cm de alto, 90 de fondo)
    for x in (x0, x1 - 3):
        L.r(x, 30, 4, 3, S2); L.hl(x, x + 3, 30, S3)
    # el respaldo por detrás: 14 px (85 cm) con el rulo de arriba (3 px) y la costura de las dos plazas
    L.r(x0, 32, 29, 13, S1)
    L.r(x0, 32, 29, 3, S2); L.hl(x0 + 1, x1 - 1, 32, S3); L.hl(x0, x1, 34, S1)
    L.vl(x0, 33, 44, S2); L.vl(x1, 33, 44, S0)
    L.vl(24, 35, 43, S0); L.vl(25, 35, 43, S2)                            # costura del medio
    for x in range(x0 + 2, x1 - 1, 4): L.p(x, 38, S0); L.p(x + 2, 41, S0)  # el tejido
    L.hl(x0, x1, 44, S0)
    L.p(x0 + 1, 45, '#3a2a1c'); L.p(x0 + 2, 45, '#3a2a1c'); L.p(x1 - 2, 45, '#3a2a1c'); L.p(x1 - 1, 45, '#3a2a1c')   # patas
    L.contorno('#1a2030')
    suelo(L, x0, x1, '#1a2030')
    return L

def tv():
    L = Lienzo(48, 48); M0, M1, M2, M3 = '#3e2a1a', '#5e4028', '#7e5836', '#9e744a'
    x0, x1 = 13, 34                                                       # mueble de 140 cm: 22 px
    L.r(x0, 37, 22, 3, M2); L.hl(x0, x1, 37, M3)                          # la tapa (40 cm de fondo, a medias)
    L.r(x0, 40, 22, 7, M1); L.hl(x0, x1, 40, M3); L.vl(x0, 40, 46, M2); L.vl(x1, 40, 46, M0)
    L.r(20, 41, 8, 4, '#24180e')                                          # el hueco del medio, con la consola
    L.r(21, 43, 6, 2, '#e8e8ec'); L.hl(21, 26, 43, '#ffffff'); L.p(26, 44, '#4a9ae0')
    L.vl(17, 42, 43, M3); L.vl(30, 42, 43, M3)                            # tiradores de las puertas
    L.hl(x0, x1, 46, M0)
    # la tele de 43": 16 × 9 de pantalla con su marco, en una peana
    L.r(22, 35, 4, 2, '#2a2a34'); L.hl(21, 26, 36, '#2a2a34')
    L.r(15, 24, 18, 11, '#18181e')
    L.r(16, 25, 16, 9, '#232834')
    for i in range(5): L.p(18 + i, 26 + i, '#3a4256'); L.p(19 + i, 26 + i, '#2e3444')   # el reflejo
    L.p(31, 33, '#e04040')                                                # el piloto
    L.contorno('#1a120a')
    suelo(L, x0, x1, '#1a120a')
    return L

def gpc():
    L = Lienzo(48, 48); N0, N1, N2, N3 = '#141518', '#24262c', '#383a42', '#55585f'
    x0, x1 = 13, 34                                                       # mesa de 140 cm: 22 px
    L.r(x0, 29, 22, 6, N2); L.hl(x0, x1, 29, N3)                          # el tablero (70 cm de fondo, a medias)
    L.r(x0, 35, 22, 2, N1); L.hl(x0, x1, 35, N3)                          # el canto, con la tira de LED
    for i, x in enumerate(range(x0 + 1, x1)): L.p(x, 36, ['#e040e0', '#a060f0', '#40c0f0', '#40e0a0'][(i // 3) % 4])
    L.r(x0, 37, 3, 10, N1); L.r(x1 - 2, 37, 3, 10, N1)                    # las patas de panel
    L.vl(x0, 37, 46, N2); L.vl(x1, 37, 46, N0)
    L.r(x0 + 3, 37, 16, 2, N0)                                            # la sombra bajo el tablero
    # el monitor de 27" (10 × 6) al fondo, con el juego en pantalla
    L.r(18, 21, 12, 8, N0); L.r(19, 22, 10, 6, '#2a4a9a')
    L.hl(19, 28, 25, '#3a8a4a'); L.hl(19, 28, 26, '#2a6a3a'); L.hl(19, 28, 27, '#2a6a3a'); L.p(23, 24, '#f0c040'); L.p(26, 23, '#e8e8f0')
    L.vl(23, 29, 30, N1); L.vl(24, 29, 30, N1); L.hl(21, 26, 31, N1)      # el pie
    L.hl(19, 27, 33, N0); L.hl(20, 26, 32, N1)                            # el teclado, con su luz
    for x in range(20, 27, 2): L.p(x, 32, '#40c0f0')
    L.r(28, 32, 2, 1, N0)                                                 # el ratón
    # la torre (21 × 45 cm) en la mesa, a la derecha: cristal y tres ventiladores encendidos
    L.r(30, 20, 4, 3, N2); L.hl(30, 33, 20, N3)
    L.r(30, 23, 4, 8, N1); L.vl(30, 23, 30, N2)
    for y, c in ((24, '#e040e0'), (26, '#a060f0'), (28, '#40c0f0')): L.r(31, y, 2, 1, c)
    L.contorno('#0a0a0e')
    suelo(L, x0, x1, '#0a0a0e')
    return L

K = '#2a2a34'
def movil():
    L = Lienzo(16, 16)
    L.r(5, 1, 7, 14, '#3a3c46'); L.vl(5, 1, 14, '#5a5e6a'); L.hl(5, 11, 1, '#5a5e6a')
    L.r(6, 3, 5, 8, '#58b8e8'); L.hl(6, 10, 3, '#a8e0f8'); L.p(6, 4, '#a8e0f8')
    L.r(7, 5, 3, 1, '#f8f8f0'); L.r(7, 7, 2, 1, '#f8f8f0'); L.p(9, 9, '#58d080')      # un mensaje y su respuesta
    L.hl(7, 9, 12, '#6a6e78'); L.hl(7, 9, 2, '#1c1d22')
    L.contorno(K)
    return L

def guardar():
    L = Lienzo(16, 16)
    L.r(3, 2, 10, 12, '#4a8a4a'); L.vl(3, 2, 13, '#6ab06a'); L.hl(3, 12, 2, '#6ab06a'); L.vl(12, 3, 13, '#2e5a2e')
    L.r(5, 4, 6, 8, '#f0ead8'); L.vl(10, 4, 11, '#c8bea4')
    for y in (6, 8, 10): L.hl(6, 9, y, '#8a8070')
    L.vl(4, 3, 12, '#2e5a2e')
    L.r(11, 1, 2, 5, '#e04040'); L.p(11, 6, '#e04040')                                 # la cinta de marcar
    L.contorno(K)
    return L

def altavoz():
    L = Lienzo(16, 16)
    L.r(2, 6, 3, 4, '#8a909c'); L.hl(2, 4, 6, '#d4d8e2')
    for i in range(4): L.vl(5 + i, 5 - i, 10 + i, '#b2b8c4'); L.p(5 + i, 5 - i, '#d4d8e2')
    L.vl(10, 6, 9, '#58d080'); L.vl(12, 4, 11, '#58d080'); L.p(11, 5, '#58d080'); L.p(11, 10, '#58d080')
    L.contorno(K)
    return L

def cogollo():
    L = Lienzo(16, 16)
    V0, V1, V2, V3, V4 = '#1e4a22', '#2e6a2e', '#4a9a3a', '#78c850', '#b4ec80'
    # la silueta: un cogollo prieto, punta arriba y panza abajo (fila: x0, x1), con dos hojitas de azúcar en la base
    filas = {2: (7, 8), 3: (6, 9), 4: (5, 10), 5: (4, 11), 6: (4, 11), 7: (3, 12), 8: (3, 12), 9: (3, 12), 10: (4, 11), 11: (4, 11), 12: (5, 10), 13: (6, 9)}
    for y, (a, b) in filas.items(): L.hl(a, b, y, V2)
    L.p(4, 13, V1); L.p(3, 12, V1); L.p(11, 13, V1); L.p(12, 12, V0)
    for y, (a, b) in filas.items(): L.p(a, y, V3); L.p(b, y, V1)                    # luz arriba a la izquierda, sombra a la derecha
    L.p(7, 2, V4); L.p(6, 3, V4); L.p(5, 4, V3); L.p(4, 6, V4); L.p(5, 5, V4)
    # los cálices apilados: medias lunas oscuras abajo de cada uno
    for (a, b, y) in ((6, 7, 5), (8, 10, 6), (4, 6, 8), (7, 9, 9), (10, 11, 9), (5, 7, 11), (8, 9, 12)): L.hl(a, b, y, V1)
    L.p(11, 10, V0); L.p(10, 12, V0); L.p(12, 8, V0); L.p(9, 13, V0)
    # pistilos naranjas
    for (x, y) in ((8, 3), (10, 5), (5, 7), (9, 8), (7, 10), (11, 11)): L.p(x, y, '#f08a2a')
    L.p(9, 2, '#ffb860'); L.p(3, 6, '#ffb860')
    # la escarcha: tricomas blancos
    for (x, y) in ((7, 4), (6, 7), (10, 7), (8, 11), (5, 10)): L.p(x, y, '#f4fff0')
    L.vl(7, 14, 15, '#5a8a3a'); L.p(8, 14, '#4a7a30')                               # el tallo
    L.contorno(K)
    return L

def salir():
    L = Lienzo(16, 16)
    L.r(3, 1, 8, 14, '#7e5836'); L.vl(3, 1, 14, '#9e744a'); L.hl(3, 10, 1, '#9e744a')
    L.r(5, 3, 4, 11, '#24180e')                                                      # el hueco de la puerta abierta
    L.r(5, 3, 2, 11, '#5e4028'); L.p(6, 8, '#f0c040')                                # la hoja, con el pomo
    L.hl(9, 13, 8, '#58d080'); L.p(12, 7, '#58d080'); L.p(12, 9, '#58d080'); L.p(11, 6, '#58d080'); L.p(11, 10, '#58d080')
    L.contorno(K)
    return L

sale('movil', movil(), 'iconos-menu')
sale('salir', salir(), 'iconos-menu')
sale('guardar', guardar(), 'iconos-menu')
sale('altavoz', altavoz(), 'iconos-menu')
sale('cogollo', cogollo(), 'iconos-menu')
sale('sofa', sofa())
sale('tv', tv())
sale('gpc', gpc())

def escribe(raiz=None):
    for g, S in SAL.items():
        for n, L in S.items():
            d = os.path.join(raiz, g, n) if raiz else P('art', 'crudo', g, n, 'unica'); os.makedirs(d, exist_ok=True)
            for f in glob.glob(os.path.join(d, '*.png')): os.remove(f)
            L.im.save(os.path.join(d, '00.png'))
            print(g, n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)

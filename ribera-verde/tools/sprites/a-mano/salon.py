# python3 -I tools/sprites/a-mano/salon.py  (Python 3 + Pillow; no va en los scripts de npm)
# Lámina 14 (1.10): los muebles del salón del piso, que se compran por internet, dibujados a mano a 16 px/m como la nevera y las
# cajas (equipo_p5.py): el frente a su ancho y alto reales y la tapa a medio fondo. Cada uno ocupa 2 casillas de ancho
# (celda mueble_ancho, 48 × 48, base en (16, 47) = el centro de la casilla de la izquierda; el mueble, centrado en x 24).
#  · sofa: sofá de 2 plazas (180 × 85 × 90 cm) visto por detrás (mira a la tele): el respaldo, su rulo y los brazos asomando.
#  · tv: tele de 43" (97 × 56 cm) sobre un mueble bajo (140 × 45 × 40 cm) con la consola en el hueco del medio.
#  · gpc: mesa gaming (140 × 75 × 70 cm) con el monitor de 27", el teclado y la torre con los ventiladores encendidos.
#  · carro (1.11): la estación de esquejes, que vende Kiko: un carro de 100 × 50 × 120 cm con ruedas y dos bandejas de propagación
#    con su tapa (los esquejes dentro) bajo dos tubos T5, y al lado una mesita de 80 × 75 cm con la tabla de corte, el bisturí y
#    el bote de hormona de enraizamiento.
#  · silla y sillaG (1.27.1): la silla de madera de la tía, delante de su ordenador, y la silla gaming, que viene con el PC gaming
#    (centrada en sus dos casillas), las dos vistas por detrás.
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

# los tapizados (1.16, personalizar la casa): el de serie y los otros dos, del oscuro al claro y el contorno
TAP_SOFA = [('#2c3a52', '#3e5272', '#566e94', '#7890b6', '#1a2030'), ('#3a4224', '#556034', '#6e7c46', '#909e64', '#20240f'),
            ('#4a1e24', '#6a2a32', '#8a3c44', '#ac5a60', '#2a1014')]
TAP_SILLON = [('#7a5a18', '#a07a24', '#c49a38', '#dcb85a', '#3a2a0a'), ('#3a3c44', '#55585f', '#72767e', '#9498a0', '#1e2026'),
              ('#143a2a', '#1e5a40', '#2e7a56', '#4a9a72', '#0a1e16')]

def sofa(tap=TAP_SOFA[0]):
    L = Lienzo(48, 48); x0, x1 = 10, 38                                  # 29 px = 180 cm
    S0, S1, S2, S3, SC = tap
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
    L.contorno(SC)
    suelo(L, x0, x1, SC)
    return L

def sillon(tap=TAP_SILLON[0]):
    """(1.16) sillón orejero de 80 × 100 cm visto por detrás, como el sofá (mira a la tele), y a su derecha la lámpara de pie de
    160 cm con la pantalla encendida"""
    L = Lienzo(48, 48); S0, S1, S2, S3, SC = tap; x0, x1 = 12, 24          # 13 px = 80 cm
    L.r(x0 - 1, 38, 2, 7, S2); L.r(x1, 38, 2, 7, S2)                      # los brazos, que asoman a los lados
    L.hl(x0 - 1, x0, 38, S3); L.hl(x1, x1 + 1, 38, S3)
    L.r(x0, 31, 13, 14, S1)                                               # el respaldo (16 px = 100 cm)
    L.r(x0, 31, 2, 8, S2); L.r(x1 - 1, 31, 2, 8, S2)                      # las orejas
    L.hl(x0 + 1, x1 - 1, 31, S3); L.vl(x0, 32, 44, S2); L.vl(x1, 32, 44, S0)
    L.p(x0, 31, None); L.p(x1, 31, None)
    for y in (35, 39): L.p(18, y, S0)                                     # los botones del capitoné
    L.hl(x0, x1, 44, S0)
    L.p(x0 + 1, 45, '#3a2a1c'); L.p(x1 - 1, 45, '#3a2a1c')               # las patas
    # la lámpara de pie: el pie redondo, el palo y la pantalla de tela con la luz
    P0, P1, P2 = '#2e2e36', '#4a4a54', '#6a6a76'
    L.hl(30, 35, 46, P0); L.hl(31, 34, 45, P1)
    L.vl(32, 24, 44, P1); L.vl(33, 24, 44, P0)
    L.r(29, 18, 8, 6, '#e0c070'); L.hl(30, 35, 18, '#f0d890'); L.hl(29, 36, 23, '#c49a38')
    L.vl(29, 19, 22, '#f0d890'); L.r(31, 20, 4, 2, '#fff2c0')
    L.contorno(SC)
    suelo(L, x0 - 1, 35, SC)
    return L

def cuadro(n):
    """(1.16) el cuadro del salón, en la pared (celda objeto_1x1, 16 × 16; ALZA lo sube): marco de madera y una de tres láminas"""
    L = Lienzo(16, 16); W0, W1, W2 = '#74502e', '#a46e40', '#dcac6c'
    L.r(3, 2, 10, 13, W1); L.hl(3, 12, 2, W2); L.vl(3, 3, 14, W2); L.vl(12, 3, 14, W0); L.hl(4, 12, 14, W0)
    x0, y0, w, h = 4, 3, 8, 11                                            # la lámina, dentro del marco
    if n == 0:                                                            # la ría: el cielo, el monte, la orilla y el agua con su reflejo
        L.r(x0, y0, w, 4, '#b4dcfa'); L.p(9, 4, '#ffffff'); L.p(10, 4, '#ffffff')
        L.r(x0, 7, w, 2, '#3f8a46'); L.hl(6, 9, 6, '#62aa56')
        L.r(x0, 9, w, 5, '#4a92e0'); L.hl(5, 8, 10, '#b4dcfa'); L.hl(7, 10, 12, '#76b4f2')
    elif n == 1:                                                          # el caserío: blanco con tejado rojo en el prado
        L.r(x0, y0, w, 6, '#b4dcfa'); L.r(x0, 9, w, 5, '#62aa56'); L.hl(x0, x0 + w - 1, 9, '#84cc6c')
        L.hl(6, 9, 5, '#d65a4a'); L.hl(5, 10, 6, '#d65a4a'); L.hl(5, 10, 7, '#a83c30')
        L.r(6, 8, 4, 3, '#f8f8f0'); L.p(7, 9, '#74502e'); L.p(7, 10, '#74502e'); L.p(9, 9, '#46749a')
    else:                                                                 # la hoja: una de siete foliolos sobre crema
        L.r(x0, y0, w, h, '#f0ead8')
        G1, G2 = '#3f8a46', '#62aa56'
        L.vl(8, 4, 12, G1)
        for (x, y) in ((7, 5), (9, 5), (7, 6), (9, 6), (6, 7), (10, 7), (5, 8), (11, 8), (6, 9), (10, 9), (5, 10), (11, 10)): L.p(x, y, G2)
        L.p(8, 13, '#74502e')
    L.contorno('#2a2a34')
    return L

def cartel(n):
    """(1.27) el póster del dormitorio, encima del ordenador de la tía (celda objeto_1x1, 16 × 16; ALZA lo sube): 50 × 70 cm con
    marco de aluminio (11 × 14 px) y uno de cuatro dibujos"""
    L = Lienzo(16, 16); A0, A1, A2 = '#5a5e66', '#8a8e96', '#c4c8d0'
    L.r(3, 1, 11, 14, A1); L.hl(3, 13, 1, A2); L.vl(3, 2, 14, A2); L.vl(13, 2, 14, A0); L.hl(4, 13, 14, A0)
    x0, y0, w, h = 4, 2, 9, 12                                            # el dibujo, dentro del marco
    if n == 0:                                                            # el faro al atardecer: rayas rojas y blancas sobre las rocas
        L.r(x0, y0, w, 4, '#f2b26a'); L.r(x0, 6, w, 3, '#e08a62'); L.r(x0, 9, w, 5, '#3a5e9a')
        L.hl(5, 6, 12, '#7aa4d8'); L.hl(10, 11, 11, '#7aa4d8')
        L.r(7, 4, 3, 6, '#f4f4ee'); L.hl(7, 9, 5, '#c83a34'); L.hl(7, 9, 7, '#c83a34'); L.hl(7, 9, 9, '#c83a34')
        L.hl(7, 9, 3, '#2a2a34'); L.p(8, 2, '#2a2a34'); L.p(8, 3, '#ffe890')
        L.hl(5, 11, 10, '#4a4a52'); L.hl(6, 10, 11, '#4a4a52')
    elif n == 1:                                                          # la ola: el rizo azul con su espuma y el sol
        L.r(x0, y0, w, h, '#f0e6cc'); L.r(10, 3, 2, 2, '#e86a3a')
        for x, ya in ((4, 9), (5, 8), (6, 7), (7, 6), (8, 6), (9, 7), (10, 8), (11, 9), (12, 10)):
            L.vl(x, ya, 13, '#2e6aa8')
        L.hl(6, 8, 6, '#ffffff'); L.p(9, 7, '#ffffff'); L.p(8, 7, '#7ab4e0'); L.p(8, 8, '#f0e6cc'); L.p(7, 8, '#7ab4e0')
        L.hl(4, 12, 12, '#7ab4e0'); L.hl(4, 12, 13, '#1e4a80')
    elif n == 2:                                                          # la planta en flor, como en un libro de botánica
        L.r(x0, y0, w, h, '#f2ecd8'); G1, G2, C = '#3f7a3a', '#5aa04a', '#7ab84e'
        L.vl(8, 5, 12, G1)
        for (x, y) in ((7, 9), (6, 9), (5, 8), (9, 9), (10, 9), (11, 8), (7, 11), (6, 12), (9, 11), (10, 12)): L.p(x, y, G2)
        L.r(7, 3, 3, 3, C); L.p(8, 2, C); L.p(7, 4, '#e08a3a'); L.p(9, 3, '#e08a3a'); L.p(8, 5, '#e08a3a')
        L.hl(6, 10, 13, '#8a7a5a')
    else:                                                                 # el mapa de la costa: la orilla, la ruta y la rosa de los vientos
        L.r(x0, y0, w, h, '#e8d8a8'); L.hl(x0, 12, 2, '#cdb880'); L.hl(x0, 12, 13, '#cdb880')
        for y, xs in ((3, 10), (4, 9), (5, 9), (6, 10), (7, 11), (8, 11), (9, 10), (10, 9), (11, 9), (12, 10)):
            L.hl(xs, 12, y, '#8ab8d8'); L.p(xs - 1, y, '#6a5a3a')
        for (x, y) in ((5, 11), (6, 9), (6, 7), (7, 5), (8, 4)): L.p(x, y, '#c0443a')
        L.p(5, 3, '#4a4a52'); L.p(4, 4, '#4a4a52'); L.p(6, 4, '#4a4a52'); L.p(5, 5, '#4a4a52'); L.p(5, 4, '#c0443a')
    L.contorno('#2a2a34')
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

def silla(yF=42):
    """(1.27.1) silla de madera de la tía delante de su ordenador (casilla de debajo, celda mueble_ancho), vista por detrás (mira al ordenador): el respaldo con su travesaño curvo y un listón,
    el asiento entre las patas y las patas de delante más arriba (más lejos)"""
    L = Lienzo(48, 48); O, D, M, W, C, H = '#2e2a2a', '#3a2a20', '#74502e', '#c48a52', '#d8a868', '#e6bc80'
    x0, x1 = 12, 19; yT = yF - 11; yS = yF - 5                          # 8 px de ancho; respaldo de 11 y asiento a 5 del suelo
    L.r(x0 + 1, yS - 2, 6, 2, C); L.hl(x0 + 1, x1 - 1, yS - 2, H)        # el asiento, que asoma entre los palos del respaldo
    L.hl(x0 + 1, x1 - 1, yS, D)                                          # el canto del asiento por debajo
    L.vl(x0 + 1, yS + 1, yF - 2, D); L.vl(x1 - 1, yS + 1, yF - 2, D)     # las patas de delante, más lejos
    L.vl(x0, yT + 2, yF, W); L.vl(x1, yT + 2, yF, M)                     # los palos de atrás, que bajan a ser las patas
    L.r(x0, yT, 8, 3, W); L.hl(x0 + 1, x1 - 1, yT, H); L.hl(x0, x1, yT + 2, M)   # el travesaño de arriba, curvo
    L.p(x0, yT, None); L.p(x1, yT, None)
    L.vl(15, yT + 3, yS - 1, W); L.vl(16, yT + 3, yS - 1, M)             # el listón del medio
    L.hl(x0, x1, yS - 1, M)                                              # el travesaño de abajo, a la altura del asiento
    L.contorno(O)
    return L

def sillaG(yF=43):
    """(1.27.1) silla gaming, que viene con el PC gaming: centrada en sus 2 casillas (x 24), un poco separada de la mesa y vista por detrás: respaldo alto con orejas y reposacabezas, dos franjas, los brazos a los lados, el pistón
    y la base de cinco radios con ruedas"""
    L = Lienzo(48, 48); O, N0, N1, N2, N3 = '#0a0a0e', '#141518', '#24262c', '#383a42', '#55585f'; F1, F2 = '#e040e0', '#40c0f0'
    yT = yF - 21
    L.r(20, yT, 9, 15, N1)                                               # el respaldo (130 cm, 55 de ancho)
    L.r(21, yT, 7, 3, N2); L.hl(22, 26, yT, N3)                          # el reposacabezas
    L.p(20, yT, None); L.p(28, yT, None)
    L.r(19, yT + 4, 1, 8, N2); L.r(29, yT + 4, 1, 8, N0)                 # las orejas de los lados
    L.vl(20, yT + 3, yT + 14, N2); L.vl(28, yT + 3, yT + 14, N0)
    L.vl(22, yT + 4, yT + 13, F1); L.vl(26, yT + 4, yT + 13, F1)         # las franjas
    L.hl(21, 27, yT + 3, N0)
    L.r(17, yT + 10, 2, 2, N2); L.r(30, yT + 10, 2, 2, N1)               # los brazos, a los lados
    L.vl(18, yT + 12, yT + 14, N1); L.vl(30, yT + 12, yT + 14, N0)
    L.hl(21, 27, yT + 15, N0)                                            # el asiento por debajo
    L.r(23, yT + 16, 3, 2, N0)                                           # el mecanismo
    L.vl(24, yT + 17, yF - 2, N3); L.vl(23, yT + 18, yF - 2, N2)          # el pistón
    L.hl(19, 29, yF - 1, N1); L.hl(20, 28, yF - 2, N2)                   # los radios
    for x in (18, 30): L.r(x, yF - 1, 1, 2, N0)                          # las ruedas de atrás
    for x in (20, 28): L.p(x, yF - 3, N0)                                # las de delante, más lejos
    L.p(24, yF, N0)
    L.contorno(O)
    return L

def carro():
    L = Lienzo(48, 48); O = '#1a1c22'
    M1, M2, M3 = '#6c7480', '#a8b0bc', '#dfe5ec'                          # el cromado del carro
    B0, D1, D2 = '#2e3038', '#8ec0d2', '#d4eef6'                          # la bandeja negra y la tapa transparente
    G1, G2, T = '#3f8a46', '#84cc6c', '#fff6d0'                           # los esquejes y el tubo encendido
    W1, W2, W3 = '#a46e40', '#c48a52', '#dcac6c'                          # la mesita y la tabla de corte
    x0, x1 = 8, 23                                                        # el carro: 100 cm = 16 px
    for y in (27, 36, 44): L.r(x0, y, 16, 2, M2); L.hl(x0, x1, y, M3)     # tres baldas (la de arriba, 120 cm)
    for x in (x0, x1): L.vl(x, 27, 45, M1)                                # los postes
    L.vl(x0, 27, 44, M2)
    def bandeja(yb, yt):                                                  # la bandeja apoyada en yb y su tubo colgado en yt
        L.hl(x0 + 2, x1 - 2, yt, T); L.hl(x0 + 3, x1 - 3, yt + 1, M3)
        L.r(x0 + 2, yb - 2, 12, 2, B0)                                    # la bandeja con los tacos
        L.r(x0 + 3, yb - 6, 10, 4, D1); L.hl(x0 + 3, x1 - 3, yb - 6, D2); L.p(x0 + 3, yb - 5, D2)   # la tapa
        for i, x in enumerate(range(x0 + 4, x1 - 2, 2)):                 # los esquejes dentro, uno por taco
            L.p(x, yb - 3, G1); L.p(x, yb - 4 - (i % 2), G2)
        L.p(x1 - 4, yb - 7, M1)                                           # la rejilla de la tapa
    bandeja(36, 29); bandeja(44, 38)
    L.r(x0 + 1, 24, 3, 3, '#4a92e0'); L.hl(x0 + 1, x0 + 3, 24, D2); L.p(x0 + 2, 23, M1)   # el pulverizador, encima
    for x in (x0, x0 + 1, x1 - 1, x1): L.p(x, 46, O)                     # las ruedas
    # la mesita de 80 cm (13 px) y 75 de alto (12 px), con la tapa a medio fondo
    m0, m1 = 26, 38
    L.r(m0, 34, 13, 3, W2); L.hl(m0, m1, 34, W3); L.r(m0, 37, 13, 1, W1)
    L.r(m0, 38, 2, 9, W1); L.r(m1 - 1, 38, 2, 9, W1); L.vl(m0, 38, 46, W2)
    L.r(m0 + 2, 32, 7, 2, W3); L.hl(m0 + 2, m0 + 8, 33, W2)               # la tabla de corte
    L.hl(m0 + 3, m0 + 5, 32, M3); L.hl(m0 + 6, m0 + 7, 32, B0)            # el bisturí
    L.p(m0 + 7, 33, G2); L.p(m0 + 8, 32, G1)                              # una punta recién cortada
    L.r(m0 + 10, 31, 2, 3, D2); L.hl(m0 + 10, m0 + 11, 30, '#4a92e0')     # el bote de hormona
    L.contorno(O)
    suelo(L, x0, m1, O)
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
for i, t in enumerate(TAP_SOFA): sale('sofa' + (f'-{i}' if i else ''), sofa(t))
for i, t in enumerate(TAP_SILLON): sale('sillon' + (f'-{i}' if i else ''), sillon(t))
for i in range(3): sale('cuadro' + (f'-{i}' if i else ''), cuadro(i), 'salon-pared')
for i in range(4): sale('cartel' + (f'-{i}' if i else ''), cartel(i), 'salon-pared')   # 1.27
sale('tv', tv())
sale('gpc', gpc())
sale('carro', carro())
sale('silla', silla())     # 1.27.1: delante del ordenador de la tía
sale('sillaG', sillaG())   # 1.27.1: con el PC gaming

def escribe(raiz=None):
    for g, S in SAL.items():
        for n, L in S.items():
            d = os.path.join(raiz, g, n) if raiz else P('art', 'crudo', g, n, 'unica'); os.makedirs(d, exist_ok=True)
            for f in glob.glob(os.path.join(d, '*.png')): os.remove(f)
            L.im.save(os.path.join(d, '00.png'))
            print(g, n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)

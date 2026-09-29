# -*- coding: utf-8 -*-
"""El esqueleto de cada pose: los huesos de los que sale el dibujo.

Por qué un esqueleto y no un mapa de píxeles
--------------------------------------------
La primera versión de esto eran 55 rejillas de texto escritas a mano. Funcionaba, pero
salía **cuadrada**: un cuerpo escrito apilando filas de rectángulos es un rectángulo, con
los hombros, la cintura y la cadera del mismo ancho, y ni redondeándole las esquinas
después deja de parecer una caja.

Así que lo que se escribe no es el dibujo: son los **huesos**. Catorce puntos —cabeza,
cuello, hombros, codos, manos, caderas, rodillas, tobillos y puntas— y un grosor por
tramo.

Quien los dibuja es `vector.py`: trazados SVG en unidades de celda con decimales, que se
**fotografían** con Chromium a ×16 y se reducen por mayoría de submuestras. Un SVG es
texto, se escribe aquí igual que estos números, y a cambio deja dibujar lo que un
rectángulo no puede — el hombro cayendo, la cintura metida, el puño, el flequillo.

Lo que se gana, además de la forma:

* **Una pose son catorce números**, no veintiuna filas de veinticuatro caracteres. Mover
  un brazo es cambiar un par; antes era reescribir ocho filas sin descuadrar ninguna.
* **Es la misma persona en las 55.** El esqueleto base es uno por vista y las poses solo
  lo desplazan, así que la altura, el ancho de hombros y el tamaño de la cabeza no pueden
  bailar de una celda a otra.
* **El volumen sale solo.** `trazos.pinta` calcula la normal de cada píxel a partir de la
  forma; con formas redondas da tonos redondos, que es lo que no podía dar un rectángulo.

Lo que sale de aquí sigue siendo una rejilla de caracteres del alfabeto de `trazos`, así
que todo lo de después —vestir las siete siluetas, pintar en la rampa, empaquetar— no se
entera del cambio.

Sistema de coordenadas
----------------------
Celda de 24×29, en unidades de píxel pero con decimales, origen arriba a la izquierda y la
y hacia abajo. Los pies se apoyan en la fila 28. El índice 0 de un par de miembros es
siempre el de la **izquierda de la pantalla**, no el del personaje.

Lo que hay que respetar al tocar una pose
-----------------------------------------
* **Los pies, en el suelo.** Salvo el que esté en el aire a propósito, `punta` va a 27.6.
  Una figura que flota medio píxel se nota en cuanto anda.
* **La cabeza es grande a propósito.** Proporción de CONTEXT.md §18.1: es lo único que se
  lee a esta escala.
* **Que se note el paso.** Entre `andarA` y `andarB` cambian la pierna **y** el brazo.
* **Nada de sombrear aquí.** Solo forma. La luz la calcula `trazos` igual para las 55.
"""

ANCHO, ALTO = 24, 29
MUESTRA = 4          # a cuánto se rasteriza antes de reducir: ×4 son 16 muestras por píxel
LLENO = 8            # con la mitad de las muestras dentro, el píxel es del cuerpo

# Las cinco direcciones que se dibujan. Las otras tres las hace el espejo.
DIRS = ('south', 'south-east', 'east', 'north-east', 'north')

# Qué esqueleto le toca a cada dirección: tres vistas para cinco direcciones. De espaldas
# el tronco tiene la misma silueta que de frente —lo que cambia es la cabeza— y el noreste
# es el sureste con la nuca por delante.
VISTA_DE = {'south': 'frente', 'south-east': 'tres', 'east': 'perfil',
            'north-east': 'tres', 'north': 'frente'}

# Cuánto pelo se ve, por dirección: el desplazamiento de la mata sobre la cabeza y cuánto
# se agranda. De frente se corre hacia arriba y deja la cara; de perfil hacia atrás y deja
# media; de espaldas no se corre y crece, y tapa la cabeza entera. Es lo único que
# distingue las cinco direcciones de una misma vista.
PELO = {'south':      (0.0, -2.7, 0.0, .60),
        'south-east': (-1.5, -1.9, 0.0, .74),
        'east':       (-2.0, -0.6, 0.0, .94),
        'north-east': (-1.1, -0.8, 0.5, .92),
        'north':      (0.0, -1.0, 0.8, .90)}

# El grosor de cada tramo, en radio de píxel. El brazo no se afila del todo: adelgaza en
# el codo y vuelve a engordar en la mano, y ese bulto es el puño. La pierna sí se afila,
# del muslo al tobillo. Es lo que convierte un palo en un miembro.
GRUESO = {'brazo': (1.75, 1.45, 1.6), 'pierna': (2.0, 1.8, 1.5), 'pie': (1.4, 1.1),
          'cuello': (1.6, 1.8)}

# Poses en las que los brazos van **por delante** del tronco. En las demás cuelgan a los
# costados y se dibujan antes, para que el tronco tape el hombro y del brazo solo asome lo
# que sobresale: dibujándolos siempre encima, el brazo se come tres píxeles de pecho por
# cada lado y el tronco se queda en un canalón de seis.
DELANTE = ('pega1', 'pega2', 'apunta')

# La cabeza no es una elipse: es una superelipse. Una elipse de cinco píxeles de radio
# acaba en punta arriba —a media fila de la coronilla ya mide un píxel— y la figura se lee
# como una bala. Con el exponente por encima de dos, el contorno se acerca al rectángulo
# redondeado, que es la cabeza de este estilo.
REDONDEZ = 2.5

# ── los tres esqueletos base ───────────────────────────────────────────────────────
# En reposo. Las once poses son desplazamientos sobre éstos, así que todo lo que no
# cambie una pose —la estatura, el ancho de hombros, el tamaño de la cabeza— es
# forzosamente idéntico en las 55 celdas.
BASE = {
 'frente': {
  'cabeza':  (12.0, 4.9, 4.8, 4.6),          # centro x, centro y, radio x, radio y
  'cuello':  (12.0, 9.6),
  'hombro':  ((8.1, 11.2), (15.9, 11.2)),
  'codo':    ((7.0, 14.8), (17.0, 14.8)),
  'mano':    ((7.2, 17.8), (16.8, 17.8)),
  'cadera':  ((9.8, 16.6), (14.2, 16.6)),
  'rodilla': ((9.5, 21.6), (14.5, 21.6)),
  'tobillo': ((9.5, 25.4), (14.5, 25.4)),
  'punta':   ((9.5, 27.4), (14.5, 27.4)),
  'torso':   ((12.0, 11.2, 4.2), (12.0, 16.2, 3.2)),
 },
 # Tres cuartos: el cuerpo gira, así que el lado de allá se acerca al eje y la cabeza se
 # corre hacia donde mira. No es la vista de frente estrechada — si lo fuera, el hombro de
 # allá se vería igual de lejos y no habría giro.
 'tres': {
  'cabeza':  (12.4, 4.9, 4.7, 4.6),
  'cuello':  (12.2, 9.6),
  'hombro':  ((8.5, 11.2), (16.2, 11.2)),
  'codo':    ((7.6, 14.8), (17.2, 14.8)),
  'mano':    ((7.8, 17.8), (17.0, 17.8)),
  'cadera':  ((10.2, 16.6), (14.5, 16.6)),
  'rodilla': ((10.0, 21.6), (14.8, 21.6)),
  'tobillo': ((10.0, 25.4), (14.8, 25.4)),
  'punta':   ((10.4, 27.4), (15.3, 27.4)),
  'torso':   ((12.3, 11.2, 4.0), (12.3, 16.2, 3.1)),
 },
 # Perfil: los dos lados casi en el mismo sitio. El brazo y la pierna de allá se dibujan
 # primero y el tronco se los come, que es exactamente lo que pasa de perfil.
 'perfil': {
  'cabeza':  (12.5, 4.9, 4.6, 4.6),
  'cuello':  (12.3, 9.6),
  'hombro':  ((9.6, 11.2), (14.6, 11.2)),
  'codo':    ((9.0, 14.8), (15.4, 14.8)),
  'mano':    ((9.2, 17.8), (15.4, 17.8)),
  'cadera':  ((11.3, 16.6), (12.7, 16.6)),
  'rodilla': ((11.2, 21.6), (12.8, 21.6)),
  'tobillo': ((11.2, 25.4), (12.8, 25.4)),
  'punta':   ((12.6, 27.4), (14.2, 27.4)),
  'torso':   ((11.9, 11.2, 3.4), (11.9, 16.2, 2.9)),
 },
}

# Cuánto se abre la zancada según la vista. De perfil una zancada se ve entera y de frente
# se ve escorzada, así que el mismo paso tiene que abrirse más de perfil para leerse igual.
# Solo afecta a la x de las piernas: si estirase también los brazos, el que anda de perfil
# sacaría la mano fuera de la celda.
ESTIRA = {'frente': 1.0, 'tres': 1.15, 'perfil': 1.3}
PIERNAS = ('cadera', 'rodilla', 'tobillo', 'punta')

# ── las once poses ─────────────────────────────────────────────────────────────────
# Desplazamientos sobre el esqueleto base, en píxeles. Una pose puede dar un juego para
# todas las vistas —la clave '*'— y afinarlo en una: apuntar hacia delante es hacia el
# espectador de frente y hacia la derecha de perfil, y eso no sale de estirar el mismo
# número.
POSES = {

 # De pie. El esqueleto tal cual.
 'quieto': {'*': {}},

 # Paso A: la pierna de la derecha adelante y plantada, la de la izquierda despegando, y
 # los brazos al revés que las piernas, que es como anda la gente.
 'andarA': {'*': {
   'cadera':  ((-0.3, 0), (0.3, 0)),
   'rodilla': ((-1.3, 0), (1.4, 0)),
   'tobillo': ((-2.2, -0.5), (2.2, 0)),
   'punta':   ((-2.6, -0.8), (2.4, 0)),
   'codo':    ((0.3, -0.8), (-0.3, 0.3)),
   'mano':    ((0.5, -1.7), (-0.5, 0.7))}},

 # Paso de paso: las dos piernas juntas y una a punto de adelantar. Es el fotograma que
 # evita que andar sea un balanceo entre dos posturas.
 'andarP': {'*': {
   'rodilla': ((0.8, 0), (-0.8, 0)),
   'tobillo': ((1.1, -0.4), (-1.1, 0)),
   'punta':   ((1.1, -0.5), (-1.1, 0)),
   'mano':    ((0, -0.5), (0, -0.5))}},

 # Paso B: lo contrario de A. Cambian la pierna que apoya **y** el brazo que va delante;
 # si solo cambiara la pierna, al animarlo el tronco se quedaría quieto y cantaría.
 'andarB': {'*': {
   'cadera':  ((0.3, 0), (-0.3, 0)),
   'rodilla': ((1.4, 0), (-1.3, 0)),
   'tobillo': ((2.2, 0), (-2.2, -0.5)),
   'punta':   ((2.4, 0), (-2.6, -0.8)),
   'codo':    ((-0.3, 0.3), (0.3, -0.8)),
   'mano':    ((-0.5, 0.7), (0.5, -1.7))}},

 # Correr no es andar deprisa: el tronco se va hacia delante, los codos suben y se doblan,
 # y hay un fotograma en el que los dos pies están en el aire. Éste es el de zancada.
 'correrA': {'*': {
   'cabeza':  (0.9, 0.3), 'cuello': (0.8, 0.2),
   'hombro':  ((0.8, 0.3), (0.8, 0.3)), 'torso': ((0.7, 0.2), (0.2, 0.1)),
   'cadera':  ((-0.5, 0), (0.6, 0)),
   'rodilla': ((-2.1, -0.6), (2.3, -0.2)),
   'tobillo': ((-3.4, -1.5), (3.4, 0)),
   'punta':   ((-3.9, -1.9), (3.6, 0)),
   'codo':    ((1.0, -1.7), (-0.6, -1.7)),
   'mano':    ((2.6, -4.4), (-1.8, -3.6))}},

 # El otro fotograma de correr: la zancada al revés, el mismo tronco inclinado.
 'correrB': {'*': {
   'cabeza':  (0.9, 0.3), 'cuello': (0.8, 0.2),
   'hombro':  ((0.8, 0.3), (0.8, 0.3)), 'torso': ((0.7, 0.2), (0.2, 0.1)),
   'cadera':  ((0.6, 0), (-0.5, 0)),
   'rodilla': ((2.3, -0.2), (-2.1, -0.6)),
   'tobillo': ((3.4, 0), (-3.4, -1.5)),
   'punta':   ((3.6, 0), (-3.9, -1.9)),
   'codo':    ((0.6, -1.7), (-1.0, -1.7)),
   'mano':    ((1.8, -3.6), (-2.6, -4.4))}},

 # Amago: el puño atrás y arriba, el codo fuera, la otra mano cruzada guardando el pecho.
 # Sin este fotograma el puñetazo aparece de la nada y no se lee como un golpe.
 'pega1': {'*': {
   'codo':    ((1.4, -1.9), (1.5, -2.3)),
   'mano':    ((3.4, -4.3), (-1.4, -5.1)),
   'tobillo': ((-1.2, 0), (1.2, 0)), 'punta': ((-1.2, 0), (1.2, 0))}},

 # El puñetazo: el brazo entero fuera de la silueta del cuerpo. Que se salga es justo lo
 # que lo hace legible a veinticuatro píxeles de ancho.
 'pega2': {'*': {
   'codo':    ((1.2, -1.7), (2.8, -2.9)),
   'mano':    ((3.2, -4.1), (5.6, -5.1)),
   'cadera':  ((-0.4, 0), (0.4, 0)),
   'tobillo': ((-2.0, 0), (2.0, 0)), 'punta': ((-2.2, 0), (2.2, 0))},
  'perfil': {
   'codo':    ((1.4, -1.7), (3.4, -3.0)),
   'mano':    ((3.0, -4.1), (7.2, -5.2))}},

 # Apuntar: las dos manos juntas por delante. Lo que sostienen no se dibuja aquí — el arma
 # y el fogonazo los forja el juego encima, anclados a la cabeza.
 'apunta': {'*': {
   'codo': ((1.7, -1.9), (-1.7, -1.9)),
   'mano': ((3.5, -4.3), (-3.5, -4.3))},
  'tres': {
   'codo': ((2.3, -1.9), (0.5, -2.1)),
   'mano': ((4.4, -4.3), (1.6, -4.5))},
  'perfil': {
   'codo': ((2.9, -2.1), (2.7, -2.3)),
   'mano': ((5.8, -4.5), (5.4, -4.7))}},

 # Encajar un golpe: los brazos se abren de par en par, las rodillas ceden y toda la
 # figura baja un píxel. Ese píxel es medio fotograma de encogimiento y se nota al
 # animarlo; sin él, el herido parece que saluda.
 'herido': {'*': {
   'cabeza':  (0, 1.1), 'cuello': (0, 0.9),
   'hombro':  ((-0.8, 0.9), (0.8, 0.9)), 'torso': ((0, 0.9), (0, 0.6)),
   'codo':    ((-2.1, -1.7), (2.1, -1.7)),
   'mano':    ((-3.7, -4.1), (3.7, -4.1)),
   'cadera':  ((0, 0.7), (0, 0.7)),
   'rodilla': ((-0.9, 0.4), (0.9, 0.4))}},

 # Agachado: cuatro píxeles más bajo, la rodilla abierta y el muslo casi horizontal. No es
 # el de pie encogido — si solo se recortaran las piernas, parecería hundido en el suelo.
 'agacha': {'*': {
   'cabeza':  (0, 4.1), 'cuello': (0, 3.8),
   'hombro':  ((0, 3.7), (0, 3.7)), 'torso': ((0, 3.6), (0, 2.8)),
   'codo':    ((-0.4, 3.2), (0.4, 3.2)),
   'mano':    ((-0.6, 2.4), (0.6, 2.4)),
   'cadera':  ((-1.1, 3.4), (1.1, 3.4)),
   'rodilla': ((-2.0, 1.3), (2.0, 1.3))}},
}

# El orden en que se animan y se empaquetan. Es el de CONTEXT.md §18.1 y el que espera el
# empaquetador: cambiarlo aquí descoloca la hoja entera.
DIBUJOS = ('quieto', 'andarA', 'andarP', 'andarB', 'correrA', 'correrB',
           'pega1', 'pega2', 'apunta', 'herido', 'agacha')

VACIO = '.'


def _mueve(p, d):
    return (p[0] + d[0], p[1] + d[1])


def huesos(dibujo, direccion):
    """El esqueleto de esa celda: el base de su vista con la pose encima."""
    vista = VISTA_DE[direccion]
    h = {k: v for k, v in BASE[vista].items()}
    juego = dict(POSES[dibujo].get('*', {}))
    juego.update(POSES[dibujo].get(vista, {}))
    estira = ESTIRA[vista]
    for clave, d in juego.items():
        if clave == 'cabeza':
            cx, cy, rx, ry = h['cabeza']
            h['cabeza'] = (cx + d[0], cy + d[1], rx, ry)
        elif clave == 'cuello':
            h['cuello'] = _mueve(h['cuello'], d)
        elif clave == 'torso':
            h['torso'] = tuple((p[0] + q[0], p[1] + q[1], p[2])
                               for p, q in zip(h['torso'], d))
        else:
            k = estira if clave in PIERNAS else 1.
            h[clave] = tuple(_mueve(p, (q[0] * k, q[1]))
                             for p, q in zip(h[clave], d))
    return h


def _celdas():
    """Las 55 celdas ya dibujadas y capturadas, tal como salen de `celdas.py`.

    El dibujo vive en `vector.py` —trazados SVG sobre estos mismos huesos, fotografiados
    con Chromium y reducidos por mayoría— y aquí solo se lee el resultado. Se guarda
    revelado en el repositorio porque capturar necesita node y Chromium, y el empaquetador
    tiene que poder correr sin ninguno de los dos.

    Después de tocar un hueso de aquí arriba o un trazado de allí:

        python3 herramientas/sprites/vector.py --escribe

    Si no se rehace, esto revienta en cuanto falte una celda: más vale un error que una
    hoja con la mitad de las poses de ayer.
    """
    from celdas import CELDAS
    faltan = ['%s/%s' % (dib, d) for dib in DIBUJOS for d in DIRS
              if d not in CELDAS.get(dib, {})]
    if faltan:
        raise SystemExit('celdas.py se ha quedado atrás, faltan %d (%s...). '
                         'Rehazlo: python3 herramientas/sprites/vector.py --escribe'
                         % (len(faltan), ', '.join(faltan[:3])))
    return {dib: {d: CELDAS[dib][d].strip('\n') for d in DIRS} for dib in DIBUJOS}


TRAZOS = _celdas()

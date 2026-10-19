# python3 -I tools/maestro9.py  (desde ribera-verde/; reescribe godot/datos/datos.json)
# MAESTRO [9]: los pisos de venta (PISOS9) y la ciudad (METRO, MAPS.metropoli, vip-zen, vip-ila).
# Hiriburu, la ciudad de la autopista: dos filas de manzanas como las del Ensanche (bloque y bloque2, con las mismas casillas),
# dos avenidas, una plaza abajo con la fuente y el aparcamiento a la izquierda; cuatro barrios por cuadrantes.
import json, os, copy
from collections import OrderedDict

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'godot', 'datos', 'datos.json')
D = json.loads(open(RAIZ, encoding='utf-8').read(), object_pairs_hook=OrderedDict)
W, H = 46, 30

g = [['grass'] * W for _ in range(H)]
o = [[None] * W for _ in range(H)]
blds = []

def manzana(x0, y0, idb, door=None, ancha=False, fach=None):
    """un bloque de 8 × 7 como los del Ensanche: tejado (2 filas), paredes con ventanas y la fila de la puerta"""
    for y in range(7):
        for x in range(8):
            fila = ('roofT_', 'roofB_', 'wall_', 'win_', 'wall_', 'wall_', 'wall_')[y]
            if y == 3 and x not in (1, 4, 7):
                fila = 'wall_'
            g[y0 + y][x0 + x] = fila + idb
    if door is not None:
        for dx in ((0, 1) if ancha else (0,)):
            g[y0 + 6][door + dx] = 'door_' + idb
    b = OrderedDict([('id', idb), ('x0', x0), ('y0', y0), ('w', 8), ('h', 7), ('doorX', door)])
    if ancha:
        b['ancha'] = 1; b['dx'] = 8
    if fach:
        b['fachada'] = fach; b['puerta'] = fach
    blds.append(b)

# las dos filas de manzanas, con los callejones de una casilla entre ellas (como el Ensanche)
for fila, y0 in ((0, 2), (1, 13)):
    for i, x0 in enumerate((1, 10, 19, 28, 37)):
        idb = 'bloque2' if i % 2 else 'bloque'
        if fila == 0 and i == 1:
            manzana(x0, y0, idb, 12, False, 'club-ensanche')       # el Club Zenit
        elif fila == 0 and i == 4:
            manzana(x0, y0, idb, 38, True, 'disco')                # el Club Ilargi
        else:
            manzana(x0, y0, idb)
    for x in (9, 18, 27, 36):
        for y in range(y0 + 2, y0 + 7):
            g[y][x] = 'walk'
# aceras y avenidas
for x in range(1, W - 1):
    for y, t in ((9, 'walk'), (10, 'roadT'), (11, 'roadB'), (12, 'walk'), (20, 'walk'), (21, 'roadT'), (22, 'roadB'), (23, 'walk')):
        g[y][x] = t
# la plaza de abajo
for y in range(24, 28):
    for x in range(12, 34):
        g[y][x] = 'plaza'
o[25][22] = 'fountain'
for x in (15, 30):
    o[26][x] = 'bench'
for x in (13, 32):
    o[27][x] = 'bush'
# el borde: monte arriba, seto abajo, monte a los lados
for x in range(W):
    o[0][x] = 'monte' if x % 3 else 'monte2'
    o[1][x] = 'monte2' if x % 2 else 'monte'
    o[H - 2][x] = 'seto'
    o[H - 1][x] = 'monte' if x % 2 else 'monte2'
for y in range(2, H - 2):
    for x in (0, W - 1):
        g[y][x] = 'grass'
        o[y][x] = 'monte' if y % 2 else 'monte2'
# farolas en las aceras, papeleras de banco, cajero y carteles
for x in (5, 14, 23, 32, 41):
    o[9][x] = 'lamp'
    o[20][x] = 'lamp'
for x in (11, 33):
    o[12][x] = 'lamp'
    o[23][x] = 'lamp'
o[9][20] = 'cajero'
o[9][19] = 'sign'      # el Ayuntamiento
o[23][5] = 'sign'      # el aparcamiento
o[23][2] = 'parada'    # la parada del autobús de la autopista (a Ibarbide, por si te quedas sin coche)
# hierba con flores a los lados de la plaza
for y in range(24, 28):
    for x in list(range(5, 11)) + list(range(35, 44)):
        if (x + y) % 5 == 0:
            g[y][x] = 'flowers'

doors = OrderedDict()
doors['12,8'] = OrderedDict([('to', 'vip-zen'), ('x', 9), ('y', 8), ('dir', 'up'), ('gate', 'vip:zen')])
doors['38,8'] = OrderedDict([('to', 'vip-ila'), ('x', 9), ('y', 8), ('dir', 'up'), ('gate', 'vip:ila')])
doors['39,8'] = OrderedDict([('to', 'vip-ila'), ('x', 10), ('y', 8), ('dir', 'up'), ('gate', 'vip:ila')])

MAPS = D['MAPS']
MAPS['metropoli'] = OrderedDict([('name', 'Hiriburu'), ('w', W), ('h', H), ('g', g), ('o', o), ('exits', OrderedDict()),
    ('doors', doors), ('music', MAPS['ensanche']['music']), ('blds', blds), ('est', None)])

# los dos clubs VIP por dentro: el plano del club del Ensanche, sin el dispensario (sin vitrina, tarros ni pizarra)
for k, puerta in (('zen', (12, 9)), ('ila', (38, 9))):
    m = copy.deepcopy(MAPS['club-ens'])
    m['name'] = 'Club Zenit' if k == 'zen' else 'Club Ilargi'
    for y, r in enumerate(m['o']):
        for x, t in enumerate(r):
            if t in ('tarros', 'vitrina', 'pizarra', 'cartelC'):
                r[x] = 'neonH' if y == 1 and x in (1, 4) else None
    m['exits'] = OrderedDict((c, OrderedDict([('to', 'metropoli'), ('x', puerta[0]), ('y', puerta[1]), ('dir', 'down')])) for c in ('9,9', '10,9'))
    m['music'] = 'disco' if k == 'ila' else 'club'
    MAPS['vip-' + k] = m

D['SIGNS']['metropoli:19,9'] = 'HIRIBURU · UDALA\nEl Ayuntamiento. Se atiende en la puerta.'
D['SIGNS']['metropoli:5,23'] = 'APARCAMIENTO\nEntrada y salida de la autopista.'

# las casillas de clientes: aceras libres, lejos de las farolas (la farola alta tapa 3 filas) y de las puertas
ct = []
for y in (9, 12, 20, 23):
    for x in range(2, W - 2):
        if g[y][x] != 'walk' or o[y][x]:
            continue
        if any(o[y + d][x] == 'lamp' for d in (1, 2, 3) if y + d < H) or g[y - 1][x].startswith('door_') or (x, y) in ((12, 9), (38, 9), (39, 9), (23, 9), (8, 23), (40, 12)):
            continue
        if x <= 6 and y == 23:   # el aparcamiento
            continue
        ct.append([x, y])
D['CLIENT_TILES'].pop('metropoli', None)

D['METRO'] = OrderedDict([
    ('_', 'MAESTRO [9]: la ciudad de la autopista (solo con Datos.CAL). Se abre con el patrimonio (umbral) y se va con tu vehículo.'),
    ('umbral', 500000), ('km', 140), ('peaje', 18), ('bus', 24),
    ('parada', OrderedDict([('n', 'Hiriburu'), ('x', 2), ('y', 23), ('a', [4, 24, 'down']), ('min', 60), ('eur', 0), ('cap', 99)])),
    ('zona', OrderedDict([('n', 'Hiriburu'), ('lad', 1.4), ('precio', 1.5)])), ('pat', [2, 3]), ('ct', ct), ('ronda', ct[::2]), ('aparc', [1, 24]),
    ('barrios', OrderedDict([
        ('erdi', OrderedDict([('n', 'Erdialdea'), ('r', [0, 0, 23, 13]), ('f', 'gris')])),
        ('goi', OrderedDict([('n', 'Goialde'), ('r', [23, 0, 46, 13]), ('f', 'gris')])),
        ('ibai', OrderedDict([('n', 'Ibaiondo'), ('r', [0, 13, 23, 30]), ('f', 'puente')])),
        ('gelt', OrderedDict([('n', 'Geltokia'), ('r', [23, 13, 46, 30]), ('f', 'puente')]))])),
    ('fac', OrderedDict([
        ('puente', OrderedDict([('n', 'Los del Puente'), ('jefe', 'TXEMA'), ('look', 'gorila'), ('x', 8), ('y', 23)])),
        ('gris', OrderedDict([('n', 'La Peña Gris'), ('jefe', 'IKER'), ('look', 'billarista'), ('x', 40), ('y', 12)]))])),
    ('ter', OrderedDict([('pelea', 40), ('pierde', 10), ('pacto', 15), ('pacto_e', 20000), ('empuje', [10, 25]), ('p', 0.25), ('suyo', 100)])),
    ('vip', OrderedDict([
        ('zen', OrderedDict([('n', 'Club Zenit'), ('p', 180000), ('dia', 2500), ('barrio', 'erdi'), ('map', 'vip-zen'), ('enc', 'UNAI'), ('look', 'portero')])),
        ('ila', OrderedDict([('n', 'Club Ilargi'), ('p', 240000), ('dia', 3200), ('barrio', 'goi'), ('map', 'vip-ila'), ('enc', 'MIKEL'), ('look', 'socio')]))])),
    ('mej', [OrderedDict([('n', 'Reservados'), ('p', 40000), ('x', 0.25), ('d', 'Tres reservados con su camarero: un 25 % más cada noche.')]),
             OrderedDict([('n', 'Seguridad en la puerta'), ('p', 25000), ('x', 0), ('d', 'Dos porteros con licencia: la mitad de riesgo de que lo cierren.')])]),
    ('clausura', OrderedDict([('p', 0.03), ('calor', 0.03), ('sob', 0.25), ('seg', 0.5), ('dias', 7), ('multa', 15000)])),
    ('concejal', OrderedDict([('n', 'ZUBIRI'), ('look', 'presi_ibar'), ('x', 23), ('y', 9), ('sobre', 12000), ('per', 30)])),
    ('npc', [OrderedDict([('id', 'm9_g1'), ('map', 'vip-zen'), ('x', 12), ('y', 3), ('look', 'clubg3'), ('dir', 'left')]),
             OrderedDict([('id', 'm9_g2'), ('map', 'vip-ila'), ('x', 12), ('y', 3), ('look', 'baila1'), ('dir', 'left')]),
             OrderedDict([('id', 'm9_g3'), ('map', 'vip-ila'), ('x', 3), ('y', 7), ('look', 'clubg5'), ('dir', 'right')])]),
    ('txt', OrderedDict([
        ('sofaF', 'Sofá de cuero blanco. Aquí no se sienta cualquiera.'), ('sofaB', 'Sofá de cuero blanco, de espaldas a la pista.'),
        ('mesita', 'Una mesa baja de cristal con una cubitera.'), ('billar', 'Un billar de tapete negro. Nadie juega: se mira.'),
        ('jukebox', 'Una gramola de las de antes, conectada a los altavoces del techo.'), ('neonH', 'Un neón con el nombre del club.'),
        ('poster', 'Un cartel de la sesión del sábado.'), ('tacos', 'Los tacos del billar, en su soporte.'),
        ('plantDeco', 'Una palmera de interior, regada por alguien que no eres tú.')])),
])

D['PISOS9'] = OrderedDict([
    ('_', 'MAESTRO [9]: un piso de venta por pueblo desde el primer envío por mar (S.mar.paso >= 1), con su lugarteniente (solo con Datos.CAL).'),
    ('k', OrderedDict([
        ('town', OrderedDict([('alq', 900), ('p', 90000)])), ('puerto', OrderedDict([('alq', 800), ('p', 80000)])),
        ('valdehierro', OrderedDict([('alq', 700), ('p', 70000)])), ('mendialde', OrderedDict([('alq', 500), ('p', 50000)])),
        ('errotabarri', OrderedDict([('alq', 450), ('p', 45000)])), ('ibarbide', OrderedDict([('alq', 1400), ('p', 140000)])),
        ('metropoli', OrderedDict([('alq', 3000), ('p', 300000)]))])),
    ('per', 30), ('dia', 120), ('lab', 25), ('cap', 5000), ('com', 0.15),
    ('pur', [['Pura', 1.0], ['Rebajada', 0.85], ['Muy rebajada', 0.7]]),
    ('px', [['Barata', 0.85, 1.3], ['Normal', 1.0, 1.0], ['Cara', 1.2, 0.7]]),
    ('sisa', 0.04),
    ('cal', OrderedDict([('g', 0.03), ('pur', 20), ('baja', 8), ('redada', 90), ('vuelve', 40), ('heat', 15)])),
])

open(RAIZ, 'w', encoding='utf-8').write(json.dumps(D, ensure_ascii=False, separators=(',', ':')))
print('metropoli', W, H, len(blds), 'edificios ·', len(ct), 'casillas de clientes')

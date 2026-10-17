# Landrace Hunters — la versión de Google Play (Datos.PLAY): escribe godot/datos/play.json, lo que cambia de los textos.
#  · nombres: los híbridos con nombre de marca o de persona pasan a nombres propios (las landraces, igual).
#  · rep: cambios de texto en orden (expresiones de PCRE2 y de Python a la vez): el pH, los °C y las cifras de cultivo.
#  · set: textos enteros por ruta (CLAVE.sub.0), del mismo tipo que el original: las extracciones sin temperaturas, micras ni
#    tiempos, el foro en números del juego y lo demás que era un manual de cultivo.
#  · claves: las claves de datos.json con algo que cambiar (Datos solo recorre esas).
# python3 -I tools/play.py (desde ribera-verde/)
import json, re, os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
D = json.load(open(os.path.join(RAIZ, 'godot/datos/datos.json'), encoding='utf-8'))

NOMBRES = {
    'Skunk #1': 'Ría Uno', 'Lemon Haze': 'Limonera', 'Super Skunk': 'Txoko', 'Blueberry': 'Niebla', 'Big Bud': 'Mango',
    'Lemon Skunk': 'Citrus', 'Kali Mist': 'Kalima', 'Cheese': 'Curada', 'California Orange': 'Naranjal', 'Chemdawg': 'Química',
    'Haze': 'Ondarra', 'Northern Lights': 'Ipar', 'Purple Thai': 'Amanecer', 'Trainwreck': 'Sol y Limón', 'AK-47': 'Cuatro Tierras',
    'Laughing Buddha': 'Risueña', 'Cannalope Haze': 'Melonera', 'Master Kush': 'Cordillera', 'Purple Kush': 'Púrpura Alta',
    'Critical Mass': 'Pesada', 'Shiva Skunk': 'Robusta', 'NL5 × Haze': 'Ipar × Ondarra', "Neville's Haze": 'Ondarra Triple',
    'Silver Haze': 'Ondarra Corta', 'Chocolope': 'Cacaotera', 'Pineapple Express': 'Oro Tropical', 'Tangie': 'Bruma Dulce',
    'Amnesia Haze': 'Tormenta', 'Jack Herer': 'Leyenda', 'Super Silver Haze': 'Ondarra Mayor', 'Blue Dream': 'Niebla Dulce',
    'Blue Cheese': 'Curada Azul', 'Sour Diesel': 'Dragón', 'Kali 47': 'Kalima Cuatro', 'Critical Kali Mist': 'Reina',
    'White Widow': 'Escarcha', 'Purple Haze': 'Ondarra Púrpura', 'White Russian': 'Escarcha del Este', 'Blue Widow': 'Escarcha Azul',
    'Super Lemon Haze': 'Limonera Mayor', 'Chronic': 'Cosechera', 'White Rhino': 'Escarcha Baja', 'White Shark': 'Escarcha Fiera',
    'Hawaiian Snow': 'Nieve de Isla', 'Jack Flash': 'Leyenda Rápida', 'Jack 47': 'Leyenda Cuatro', 'Sour Tangie': 'Dragón Dulce',
    'Ice': 'Helada', 'NL × Big Bud': 'Ipar × Mango', 'Critical Jack': 'Pesada Leyenda', 'Critical 47': 'Pesada Cuatro',
    'Critical Cheese': 'Pesada Curada', 'Northern Light Blue': 'Ipar Azul', 'Lowryder': 'Rastrera',
    # sueltos en los textos (después de los largos: van en la misma alternativa, la más larga gana)
    'Critical': 'Pesada', 'Northern Lights #5': 'Ipar', 'NL5': 'Ipar', 'Skunk': 'Ría', 'Jack': 'Leyenda', 'Amnesia': 'Tormenta',
    'Widow': 'Escarcha', 'Kali': 'Kalima', 'Sour': 'Dragón', 'Diesel': 'Dragón',
}

REP = [
    [r'baja el pH del agua del grifo \(7,5\) a 6,2', 'corrige el agua del grifo'],
    [r'Mide el pH y la EC del riego', 'Mide el riego'],
    [r'Mide el pH y la EC', 'Mide el riego'],
    [r'la EC y el pH de cada maceta', 'cómo va cada maceta'],
    [r'[Mm]edidor(es)? de pH( y EC)?', 'medidor\\1 de riego'],
    [r'pH− MEATZA', 'Corrector MEATZA'],
    [r'pH− ORTUA BIO', 'Corrector ORTUA BIO'],
    [r'pH−', 'corrector'],
    [r'con el pH corregido', 'con el riego corregido'],
    [r'([Cc])orriges el pH', '\\1orriges el riego'],
    [r'perdona el pH', 'perdona el agua'],
    [r'con el pH alto', 'sin corregir'],
    [r'\bel pH\b', 'la acidez'],
    [r'\bpH\b', 'acidez'],
    [r' ?°C', '°'],
    [r' ?µm', ''],
]

SET = {
    'EXTR.rosin.d': 'La prensa: calor y presión sobre la flor, entre papel de horno.',
    'EXTR.seco.d': 'Los tamices, del más grueso al más fino: la flor seca se sacude con suavidad.',
    'EXTR.seco.pasos.0.0': 'El tamiz grueso: fuera el polvo verde y los trozos.',
    'EXTR.seco.pasos.1.0': 'El siguiente: sacude en el verde, sin frotar.',
    'EXTR.seco.pasos.2.0': 'Los finos: aquí se queda la resina.',
    'EXTR.ice.d': 'El cubo con las bolsas de malla: hielo, agua y la flor.',
    'EXTR.ice.pasos.0.0': 'El agua con hielo: para la barra en el verde.',
    'EXTR.ice.pasos.1.0': 'Remover suave, sin romper la hoja.',
    'EXTR.ice.pasos.3.0': 'Secar la resina sin que coja moho.',
    'EXTR.charas.d': 'A mano, como en el Himalaya: frotar, rascar y amasar.',
    'EXTR.hash.d': 'El kief, prensado en una placa: ni poco calor ni mucho.',
    'EXTR.moon.d': 'Lo más difícil: el cogollo con rosin y kief, sin que se apelmace.',
    'EXTR.lava.d': 'La lavadora de extracción: hielo, agua y la flor, a baja velocidad.',
    'EXTR.lava.pasos.0.0': 'Cargarla con agua y hielo.',
    'EXTR.lava.pasos.1.0': 'El lavado, a baja velocidad: la barra cambia de ritmo.',
    'EXTR.lava.pasos.2.0': 'Reposar y desaguar a las bolsas.',
    'EXTR.lava.pasos.3.0': 'Recoger cada bolsa aparte.',
    'EXTR.stat.d': 'La máquina electrostática: la placa cargada separa la resina de la hoja.',
    'FORO.0': 'El agua manda: con la barra azul por debajo del 30 %, la planta sufre y enferma antes.',
    'FORO.1': 'En floración, con la sala húmeda, sube el riesgo de moho. El extractor y el ventilador lo bajan.',
    'FORO.2': 'Las madres, siempre a 18/6. Un esqueje es un clon: el mismo fenotipo que la madre. Sácalos antes de pasarla a flor.',
    'FORO.3': 'La carpa, bien cerrada y el temporizador fijo: así no hay sorpresas en la floración.',
    'FORO.4': 'Cosecha a tiempo: cuando la barra dorada parpadea, está lista. Antes, menos cogollo.',
    'FORO.5': 'Lo cosechado sale sin curar: en tarros, dentro de la caja fuerte, se cura y se vende mejor.',
    'FORO.6': 'Con el abono, una dosis por fase. Y riega cuando lo pida la barra, no por calendario.',
    'FORO.7': 'El foco, a su distancia: en la carpa sube solo a medida que crecen.',
    'KIKO_TIPS.0.4': 'Un CFL da poco. Un LED, el triple.',
    'PIZARRA_KIKO.2': 'Corrector con cada abono. Siempre',
    'JULEN.hola.2': 'Lo primero, el agua. La del grifo hay que corregirla: si no, la planta no aprovecha el abono.',
    'SOTANO.txt.cerrado': 'La escalera baja al sótano de la tía: oscuro, húmedo y lleno de trastos.',
}

LETRA = 'A-Za-zÀ-ÿ0-9'
def nombres_rx():
    alt = '|'.join(re.escape(k) for k in sorted(NOMBRES, key=len, reverse=True))
    return '(?<![%s])(%s)(?![%s\\-])' % (LETRA, alt, LETRA)

def tp(s):
    for a, b in REP:
        s = re.sub(a, b, s)
    return re.sub(nombres_rx(), lambda m: NOMBRES[m.group(1)], s)

def ruta(p):
    v = D
    for k in p.split('.'):
        v = v[int(k)] if isinstance(v, list) else v[k]
    return v

for p, t in SET.items():
    assert isinstance(ruta(p), str), p

claves = []
def cambia(v):
    if isinstance(v, str):
        return tp(v) != v
    if isinstance(v, dict):
        return any(cambia(x) for x in v.values())
    if isinstance(v, list):
        return any(cambia(x) for x in v)
    return False
for k, v in D.items():
    if k in ('MAPS', 'NEW_STATE', 'MASCARAS'):
        continue
    if cambia(v) or any(p.split('.')[0] == k for p in SET):
        claves.append(k)

# ningún nombre nuevo puede contener uno viejo (la sustitución tiene que dar lo mismo dos veces)
for b in NOMBRES.values():
    assert tp(b) == b, b
json.dump({'nombres': NOMBRES, 'letra': LETRA, 'rep': REP, 'set': SET, 'claves': claves},
          open(os.path.join(RAIZ, 'godot/datos/play.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print('play.json:', len(NOMBRES), 'nombres ·', len(REP), 'cambios ·', len(SET), 'textos ·', len(claves), 'claves:', ' '.join(claves))

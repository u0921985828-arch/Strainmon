# -*- coding: utf-8 -*-
"""
Saca la trama real de Bilbao del plano municipal vectorial.

Hasta ahora las calles del juego se generaban: salían verosímiles, pero no eran las de
Bilbao. El plano municipal es un PDF vectorial y ahí dentro la ciudad está en dos capas
que se pueden separar limpiamente:

  · las manzanas, los parques y la ría son POLÍGONOS con un color de relleno propio;
  · la calzada es un TRAZO BLANCO con el ancho real de cada calle — un callejón del
    Casco Viejo y la Gran Vía son la misma línea con distinto grosor.

Redibujando solo eso —sin rótulos, sin curvas de nivel, sin iconos, sin símbolos— queda
la red viaria de verdad, con sus glorietas, sus diagonales y las autopistas del monte.

Qué se toma y qué no
--------------------
Se toma la GEOMETRÍA: por dónde va cada calle, dónde acaba una manzana, dónde está el
parque. Eso es un hecho geográfico de la ciudad, no una creación de quien dibujó el
plano. No se toma nada de su forma de dibujarlo: ni colores, ni tipografías, ni símbolos,
ni la composición. El PDF NO entra en el repositorio; solo entra la rejilla derivada, y
el juego la pinta con arte propio.

Uso
---
    python3 herramientas/plano/extraer.py ruta/al/plano_bilbao.pdf

Escribe `referencia/bilbo-trama.txt`: la rejilla comprimida en RLE + base64, que es lo
que cargan el prototipo y Unity. Volver a ejecutarlo con otro plano regenera el mapa
entero sin tocar una sola coordenada a mano.
"""
import base64, re, sys, os, zlib, unicodedata
import pymupdf

# ── encuadre ────────────────────────────────────────────────────────────────────────
# De San Ignacio y Zorrotza por el oeste a Otxarkoaga y Bolueta por el este; de
# Elorrieta al norte a Uretamendi al sur. Los límites salen de dónde caen esos rótulos
# en el plano, no de un recorte a ojo.
RECORTE = (200, 620, 2760, 2000)          # puntos de PDF
MW, MH  = 1440, 776                        # casillas del juego
SUB     = 4                                # submuestras por lado de casilla

# A 2,9 m por punto de PDF el recorte mide 7,4 x 4,0 km y la casilla sale a 5,2 m: una
# calle normal ocupa 2 casillas, la Gran Vía 6, un callejón del Casco Viejo 1.
METROS_POR_PUNTO = 2.9

# ── clases del terreno, tal como las numera el juego ────────────────────────────────
CALLE, ACERA, EDIF, PARQUE, AGUA, PUENTE, PLAZA, MUELLE, PATIO, VIA, MONTE = range(11)

# Rellenos del PDF. El fondo —lo que no lleva relleno ni trazo— es monte, no calle.
RELLENOS = {
    # El blanco no es una clase del terreno: es el suelo que el plano vuelve a pintar
    # ENCIMA del agua. La ría viene dibujada de una vez como una mancha que se come
    # Zorrotzaurre, y la isla reaparece porque después le pintan el suelo blanco por
    # encima. Sin esta clase, la Ribera de Deustu queda bajo el agua.
    'suelo':   [(1.000, 1.000, 1.000)],
    'agua':    [(0.737, 0.820, 0.889), (0.519, 0.624, 0.746), (0.050, 0.302, 0.612),
                (0.631, 0.850, 0.823)],
    'verde':   [(0.887, 0.929, 0.735), (0.779, 0.828, 0.699)],
    'manzana': [(0.881, 0.857, 0.843), (0.893, 0.890, 0.845), (0.810, 0.829, 0.817),
                (0.610, 0.732, 0.728), (0.689, 0.701, 0.769)],
}
TINTA = {'manzana': (1, 0, 0), 'verde': (0, 1, 0), 'agua': (0, 0, 1), 'suelo': (0, 0, 0)}


def cerca(c, ref, t=0.02):
    return c is not None and all(abs(a - b) < t for a, b in zip(c, ref))


def clase_de(fill):
    for nombre, refs in RELLENOS.items():
        if any(cerca(fill, r) for r in refs):
            return nombre
    return None


def _trazar(sh, items, d, x0, y0):
    """Redibuja un trazado respetando sus subtrazados.

    Importa más de lo que parece. La ría del plano es UN solo trazado: el contorno del
    agua por fuera y el de cada isla por dentro, y es la regla par-impar la que convierte
    los de dentro en agujeros. Si se dibujan todos los tramos seguidos como si fueran uno,
    Zorrotzaurre se inunda. Un subtrazado nuevo empieza donde el tramo no continúa el
    anterior; cada uno se dibuja aparte y el relleno se cierra una sola vez, fuera."""
    ultimo = None
    for c in items:
        if c[0] == 're':
            sh.draw_rect(c[1] + (-x0, -y0, -x0, -y0))
            ultimo = None
        elif c[0] == 'qu':
            sh.draw_quad(pymupdf.Quad(*[q - d for q in c[1]]))
            ultimo = None
        elif c[0] == 'l':
            a, b = c[1] - d, c[2] - d
            if ultimo is None or abs(a - ultimo) > 0.01:
                sh.draw_line(a, b)
            else:
                sh.draw_line(ultimo, b)
            ultimo = b
        elif c[0] == 'c':
            q = [x - d for x in c[1:5]]
            sh.draw_bezier(*q)
            ultimo = q[3]


def capas(pdf):
    """Dos páginas limpias: los rellenos por un lado, la calzada por otro.

    Van separadas a propósito. Cruzándolas después se sabe qué casilla es calle sobre
    agua —o sea, un puente— que de otro modo se perdería."""
    p = pdf[0]
    x0, y0, x1, y1 = RECORTE
    caja = pymupdf.Rect(*RECORTE)
    d = pymupdf.Point(x0, y0)
    dibujos = [it for it in p.get_drawings() if it['rect'].intersects(caja)]

    doc = pymupdf.open()
    pg_f = doc.new_page(width=x1 - x0, height=y1 - y0)
    pg_f.draw_rect(pg_f.rect, fill=(0, 0, 0), color=None)
    # Orden: el agua tapa al verde y el verde a la manzana donde el plano los solapa.
    # Se pinta en el mismo orden en que lo pinta el plano (seqno). Es la única forma de
    # que salga bien: el plano se apoya en tapar lo de antes con lo de después, y
    # reordenar por clases —agua al final, por ejemplo— inunda las islas.
    sh = pg_f.new_shape()
    for it in sorted(dibujos, key=lambda v: v['seqno']):
        nombre = clase_de(it.get('fill'))
        if nombre is None:
            continue
        _trazar(sh, it['items'], d, x0, y0)
        sh.finish(fill=TINTA[nombre], color=None, closePath=True,
                  even_odd=bool(it.get('even_odd')))
    sh.commit()

    doc2 = pymupdf.open()
    pg_c = doc2.new_page(width=x1 - x0, height=y1 - y0)
    pg_c.draw_rect(pg_c.rect, fill=(0, 0, 0), color=None)
    sh = pg_c.new_shape()
    n = 0
    for it in dibujos:
        c0 = it.get('color')
        if not c0 or not all(v > 0.97 for v in c0):
            continue          # solo el trazo blanco: eso es calzada
        n += 1
        _trazar(sh, it['items'], d, x0, y0)
        sh.finish(color=(1, 1, 1), width=it.get('width') or 0.5, fill=None,
                  lineCap=1, lineJoin=1, closePath=False)
    sh.commit()
    return doc, doc2, n


def _muestrear(pg):
    escala = MW * SUB / pg.rect.width
    pix = pg.get_pixmap(matrix=pymupdf.Matrix(escala, escala), alpha=False)
    return pix.samples, pix.width, pix.height, pix.n


def rejilla(doc_f, doc_c):
    bf, af, hf, nf = _muestrear(doc_f[0])
    bc, ac, hc, nc = _muestrear(doc_c[0])
    rej = bytearray(MW * MH)
    umbral_calle = SUB * SUB // 3        # con un tercio de casilla ya hay calle
    umbral_agua  = SUB * SUB // 3
    for ty in range(MH):
        fila = ty * MW
        for tx in range(MW):
            calle = agua = verde = manzana = 0
            for sy in range(SUB):
                py = ty * SUB + sy
                if py >= hf:
                    break
                of = (py * af + tx * SUB) * nf
                oc = (py * ac + tx * SUB) * nc
                for sx in range(SUB):
                    if tx * SUB + sx >= af:
                        break
                    if bc[oc + sx * nc] > 110:
                        calle += 1
                    j = of + sx * nf
                    r, g, b = bf[j], bf[j + 1], bf[j + 2]
                    if r < 60 and g < 60 and b < 60:
                        continue                      # monte
                    if b >= r and b >= g:
                        agua += 1
                    elif g >= r:
                        verde += 1
                    else:
                        manzana += 1
            hay_calle = calle >= umbral_calle
            hay_agua = agua >= umbral_agua
            if hay_calle and hay_agua:
                v = PUENTE
            elif hay_calle:
                v = CALLE
            elif hay_agua:
                v = AGUA
            elif verde >= manzana and verde:
                v = PARQUE
            elif manzana:
                v = EDIF
            else:
                v = MONTE
            rej[fila + tx] = v
    return _calles_peatonales(rej)


def _calles_peatonales(rej):
    """Lo que queda en blanco pegado a las casas es calle, no ladera.

    En el plano la calzada va dibujada con un trazo blanco, pero solo la que es para
    coches. Las calles peatonales —las Siete Calles del Casco Viejo, media Bilbao la
    Vieja, los pasajes de los grupos de viviendas— no llevan ese trazo: son el hueco que
    queda entre manzanas. Sin esto, el Casco Viejo salía como un pegote de casas macizo
    con la ladera metida por las callejuelas.

    El criterio es la distancia a una manzana: el hueco entre casas es calle; el mismo
    blanco a doscientos metros de la última casa es monte."""
    ALCANCE = 6                              # 6 casillas son unos 30 metros
    n = MW * MH
    dist = bytearray([255]) * n
    cola = []
    for k in range(n):
        if rej[k] == EDIF:
            dist[k] = 0
            cola.append(k)
    cab = 0
    while cab < len(cola):
        k = cola[cab]; cab += 1
        if dist[k] >= ALCANCE:
            continue
        cx, cy = k % MW, k // MW
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = cx + dx, cy + dy
            if nx < 0 or ny < 0 or nx >= MW or ny >= MH:
                continue
            j = ny * MW + nx
            if dist[j] == 255 and rej[j] in (MONTE, EDIF):
                dist[j] = dist[k] + 1
                cola.append(j)
    for k in range(n):
        if rej[k] == MONTE and dist[k] != 255:
            rej[k] = CALLE
    return rej


def aceras(rej):
    """Separa acera de calzada y deja la calzada de una pieza.

    La calzada es el interior de la calle y la acera su borde, así que basta con medir a
    qué distancia queda lo que no es calle. Pero medir y cortar sin más parte la red: en
    una calle de tres casillas en diagonal el interior queda en una hilera de casillas
    que solo se tocan por la esquina, y los coches, que se mueven en cruz, no pueden
    pasar de una a otra. De ahí que haya dos remiendos después del corte: uno local para
    las diagonales y otro global para lo que quede suelto.

    Devuelve además el tanto por ciento de calzada que queda en la pieza mayor, que es la
    cifra que hay que vigilar."""
    n = MW * MH
    calle = lambda k: rej[k] in (CALLE, PUENTE)

    # 1 · distancia de cada casilla de calle al primer borde que no lo es
    dist = [0] * n
    cola = []
    for y in range(MH):
        for x in range(MW):
            k = y * MW + x
            if not calle(k):
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if nx < 0 or ny < 0 or nx >= MW or ny >= MH or not calle(ny * MW + nx):
                    dist[k] = 1
                    cola.append(k)
                    break
    cab = 0
    while cab < len(cola):
        k = cola[cab]; cab += 1
        cx, cy = k % MW, k // MW
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = cx + dx, cy + dy
            if nx < 0 or ny < 0 or nx >= MW or ny >= MH:
                continue
            j = ny * MW + nx
            if calle(j) and dist[j] == 0:
                dist[j] = dist[k] + 1
                cola.append(j)

    # 2 · el borde es acera; el interior, calzada
    for k in range(n):
        if rej[k] == CALLE and dist[k] == 1:
            rej[k] = ACERA
    rodable = lambda k: rej[k] in (CALLE, PUENTE)

    # 3 · remiendo de diagonales: dos casillas de calzada que solo se tocan por la
    #     esquina no comunican para un coche. Se asfalta una de las dos de al lado.
    for y in range(MH - 1):
        for x in range(MW - 1):
            a, d = y * MW + x, (y + 1) * MW + x + 1
            b, c = y * MW + x + 1, (y + 1) * MW + x
            for p1, p2, q1, q2 in ((a, d, b, c), (b, c, a, d)):
                if rodable(p1) and rodable(p2) and not rodable(q1) and not rodable(q2):
                    if rej[q1] == ACERA:
                        rej[q1] = CALLE
                    elif rej[q2] == ACERA:
                        rej[q2] = CALLE

    # 4 · lo que siga suelto se cose por donde menos acera cueste: BFS desde la pieza
    #     mayor por todas las casillas de calle, y luego bajada por el gradiente.
    mayor_pct = 0.0
    for _ in range(3):
        comp = [-1] * n
        tam = []
        for k in range(n):
            if not rodable(k) or comp[k] >= 0:
                continue
            idx = len(tam); cnt = 0
            pila = [k]; comp[k] = idx
            while pila:
                q = pila.pop(); cnt += 1
                cx, cy = q % MW, q // MW
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if nx < 0 or ny < 0 or nx >= MW or ny >= MH:
                        continue
                    j = ny * MW + nx
                    if comp[j] < 0 and rodable(j):
                        comp[j] = idx
                        pila.append(j)
            tam.append(cnt)
        total = sum(tam)
        if not tam:
            return rej, 0.0
        mejor = max(range(len(tam)), key=lambda i: tam[i])
        mayor_pct = 100.0 * tam[mejor] / total
        if len(tam) == 1:
            break
        d2 = [-1] * n
        cola = [k for k in range(n) if comp[k] == mejor]
        for k in cola:
            d2[k] = 0
        cab = 0
        while cab < len(cola):
            k = cola[cab]; cab += 1
            cx, cy = k % MW, k // MW
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = cx + dx, cy + dy
                if nx < 0 or ny < 0 or nx >= MW or ny >= MH:
                    continue
                j = ny * MW + nx
                if d2[j] < 0 and rej[j] in (CALLE, ACERA, PUENTE):
                    d2[j] = d2[k] + 1
                    cola.append(j)
        cosido = False
        for idx in range(len(tam)):
            if idx == mejor:
                continue
            arranque = min((k for k in range(n) if comp[k] == idx and d2[k] >= 0),
                           key=lambda k: d2[k], default=None)
            if arranque is None:
                continue
            k = arranque
            while d2[k] > 0:
                if rej[k] == ACERA:
                    rej[k] = CALLE
                cx, cy = k % MW, k // MW
                sig = None
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if nx < 0 or ny < 0 or nx >= MW or ny >= MH:
                        continue
                    j = ny * MW + nx
                    if d2[j] >= 0 and d2[j] < d2[k] and (sig is None or d2[j] < d2[sig]):
                        sig = j
                if sig is None:
                    break
                k = sig
            cosido = True
        if not cosido:
            break
    return rej, mayor_pct


def comprimir(rej):
    """Deflate crudo (sin cabecera zlib) y luego base64.

    Crudo a propósito: así lo descomprimen tal cual `DecompressionStream("deflate-raw")`
    en el navegador y `DeflateStream` en C#, sin meter una biblioteca en ninguno de los
    dos lados. Una casilla por byte serían 1,1 MB; esto los deja en 120."""
    c = zlib.compressobj(9, zlib.DEFLATED, -15)
    return c.compress(bytes(rej)) + c.flush()



# ── barrios ─────────────────────────────────────────────────────────────────────────
# El plano rotula cada barrio con una fuente propia (Skia) en tinta roja. Filtrando por
# ella salen los 35 barrios y solo ellos: ni nombres de calle, ni equipamientos, ni el
# callejero del margen. La posición del rótulo es la que da el ayuntamiento, así que el
# barrio del juego cae donde cae el de verdad.
FUENTE_ROTULO = 'Skia'

# Estilo y tinte por barrio. Esto sí es decisión de juego, no dato del plano: marca el
# pavimento de la acera y el tono de la luz cuando andas por allí.
ESTILOS = {
    'ABANDO':                  ('senorial',   '#4c5560'),
    'INDAUTXU':                ('senorial',   '#4e5a5e'),
    'ITURRALDE':               ('senorial',   '#4f5459'),
    'CASCO VIEJO':             ('denso',      '#5c4a38'),
    'BILBAO LA VIEJA':         ('denso',      '#5a4038'),
    'SAN FRANCISCO':           ('denso',      '#57423a'),
    'ZABALA':                  ('denso',      '#544438'),
    'SOLOKOETXE':              ('denso',      '#55483c'),
    'ATXURI':                  ('denso',      '#584a3c'),
    'SANTUTXU':                ('denso',      '#5c4a3a'),
    'CASTAÑOS':                ('bloques',    '#4f5348'),
    'MATIKO - CIUDAD JARDÍN':  ('bloques',    '#4a5748'),
    'URIBARRI':                ('bloques',    '#4f5a63'),
    'ZURBARAN - ARABELLA':     ('bloques',    '#4d5560'),
    'BEGOÑA':                  ('bloques',    '#57505a'),
    'TXURDINAGA':              ('bloques',    '#4d5750'),
    'OTXARKOAGA':              ('bloques',    '#4a5450'),
    'BOLUETA':                 ('industrial', '#54503f'),
    'SAN ADRIAN':              ('bloques',    '#525445'),
    'LA PEÑA':                 ('bloques',    '#544e44'),
    'MIRIBILLA':               ('abierto',    '#525a63'),
    'AMETZOLA':                ('bloques',    '#4e5548'),
    'IRALABARRI':              ('bloques',    '#505248'),
    'ERREKALDEBERRI - LARRASKITU': ('denso',  '#584c46'),
    'URETAMENDI':              ('bloques',    '#4f4c40'),
    'BASURTU':                 ('bloques',    '#4e5548'),
    'ALTAMIRA':                ('bloques',    '#4d5044'),
    'MASUSTEGI - MONTE CARAMELO': ('bloques', '#4b5044'),
    'OLABEAGA':                ('industrial', '#55503e'),
    'ZORROTZA':                ('industrial', '#57503e'),
    'SAN PEDRO DE DEUSTU - LA RIBERA': ('bloques', '#4c5750'),
    'IBARREKOLANDA':           ('bloques',    '#4e5652'),
    'SAN IGNACIO - ELORRIETA': ('bloques',    '#4a5658'),
    'ARANGOITI':               ('bloques',    '#4b5448'),
}


def _sin_espacios(t):
    return t.replace(' ', '')


def clave_de(texto):
    """El barrio al que corresponde un rótulo, comparando sin espacios.

    El plano dibuja los rótulos letra a letra y el hueco entre palabras lo consigue
    moviendo los glifos, no metiendo un espacio: al sacar el texto, 'SAN IGNACIO' llega
    como 'SANIGNACIO'. Comparar sin espacios lo resuelve sin listas de excepciones."""
    objetivo = _sin_espacios(texto)
    for k in ESTILOS:
        if _sin_espacios(k) == objetivo:
            return k
    return None


def _limpia(t):
    """'Z O R R O T Z A' -> 'ZORROTZA'. El plano espacia las letras de los rótulos.

    Un espacio separa letras y dos separan palabras, así que hay que deshacerlo en ese
    orden: si se colapsan antes los espacios, 'S A N  I G N A C I O' pierde la juntura y
    sale 'SANIGNACIO'."""
    t = t.strip()
    trozos = [w for w in t.split(' ') if w]
    if len(trozos) > 2 and all(len(w) == 1 for w in trozos):
        t = re.sub(r' {2,}', '\x00', t).replace(' ', '').replace('\x00', ' ')
    return re.sub(r'\s+', ' ', t).strip()


def rotulos(pdf):
    """Los rótulos de barrio, ya unidos los que el plano parte en dos líneas."""
    p = pdf[0]
    # Se busca algo más ancho que el recorte: un rótulo puede caer justo fuera y su
    # barrio estar dentro.
    caja = pymupdf.Rect(RECORTE[0] - 200, RECORTE[1] - 200, RECORTE[2] + 200, RECORTE[3] + 260)
    crudos = []
    for b in p.get_text('dict', clip=caja)['blocks']:
        for l in b.get('lines', []):
            for s in l['spans']:
                if FUENTE_ROTULO not in s['font']:
                    continue
                x0, y0, x1, y1 = s['bbox']
                crudos.append([_limpia(s['text']), (x0 + x1) / 2, (y0 + y1) / 2, y1])
    # Un rótulo de dos líneas se une con el de debajo. Se acepta la unión solo si el
    # que va delante acaba en guion —«MATIKO -»— o si lo que sale es un barrio conocido:
    # así «CASCO»+«VIEJO» se junta y dos barrios que casualmente caen uno encima de otro
    # no.
    crudos.sort(key=lambda r: (r[2], r[1]))
    usados = [False] * len(crudos)
    fuera = []
    for i, r in enumerate(crudos):
        if usados[i]:
            continue
        texto, cx, cy = r[0], r[1], r[2]
        for _ in range(2):
            mejor, mejor_txt = None, None
            for j, sg in enumerate(crudos):
                if usados[j] or j == i:
                    continue
                if abs(sg[1] - cx) > 70 or not (0 < sg[2] - cy < 60):
                    continue
                if texto.endswith('-'):
                    cand = texto[:-1].strip() + ' - ' + sg[0]
                else:
                    cand = texto + ' ' + sg[0]
                    if clave_de(cand) is None:
                        continue
                if mejor is None or sg[2] < crudos[mejor][2]:
                    mejor, mejor_txt = j, cand
            if mejor is None:
                break
            usados[mejor] = True
            texto = mejor_txt
            cx, cy = (cx + crudos[mejor][1]) / 2, (cy + crudos[mejor][2]) / 2
        usados[i] = True
        fuera.append((texto, cx, cy))
    return fuera


def a_casilla(x, y):
    ex = MW / (RECORTE[2] - RECORTE[0])
    ey = MH / (RECORTE[3] - RECORTE[1])
    return (int((x - RECORTE[0]) * ex), int((y - RECORTE[1]) * ey))


def barrios(rej, marcas):
    """Reparte cada casilla al barrio cuyo rótulo tenga más cerca, pero por tierra.

    La distancia es la de andar, no la de la regla: el agua no se cruza. Por eso Deustu
    no se come Olabeaga aunque estén a doscientos metros a vuelo de pájaro — están en
    orillas distintas. Los puentes también cortan, si no el reparto se colaría de una
    orilla a otra por ellos."""
    n = MW * MH
    dueno = bytearray([255]) * n
    cola = []
    for i, (nombre, gx, gy) in enumerate(marcas):
        # El rótulo puede caer sobre una manzana o sobre el agua; se busca la casilla
        # pisable más próxima para que la mancha tenga por dónde crecer.
        mejor = None
        for r in range(0, 30):
            for dy in range(-r, r + 1):
                for dx in range(-r, r + 1):
                    if max(abs(dx), abs(dy)) != r:
                        continue
                    x, y = gx + dx, gy + dy
                    if 0 <= x < MW and 0 <= y < MH and rej[y * MW + x] not in (AGUA, PUENTE):
                        mejor = y * MW + x
                        break
                if mejor is not None:
                    break
            if mejor is not None:
                break
        if mejor is None:
            continue
        dueno[mejor] = i
        cola.append(mejor)
    cab = 0
    while cab < len(cola):
        k = cola[cab]; cab += 1
        d = dueno[k]
        cx, cy = k % MW, k // MW
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = cx + dx, cy + dy
            if nx < 0 or ny < 0 or nx >= MW or ny >= MH:
                continue
            j = ny * MW + nx
            if dueno[j] != 255 or rej[j] in (AGUA, PUENTE):
                continue
            dueno[j] = d
            cola.append(j)
    # Lo que quede sin dueño es agua o puente: se le pega el barrio de al lado para que
    # el juego siempre pueda decir en qué barrio estás, también sobre un puente.
    for paso in range(4):
        pend = [k for k in range(n) if dueno[k] == 255]
        if not pend:
            break
        for k in pend:
            cx, cy = k % MW, k // MW
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = cx + dx, cy + dy
                if 0 <= nx < MW and 0 <= ny < MH and dueno[ny * MW + nx] != 255:
                    dueno[k] = dueno[ny * MW + nx]
                    break
    for k in range(n):
        if dueno[k] == 255:
            dueno[k] = 0
    return dueno

NOMBRES = {
    'ABANDO': 'Abando', 'ALTAMIRA': 'Altamira', 'AMETZOLA': 'Ametzola',
    'ARANGOITI': 'Arangoiti', 'ATXURI': 'Atxuri', 'BASURTU': 'Basurtu',
    'BEGOÑA': 'Begoña', 'BILBAO LA VIEJA': 'Bilbao La Vieja', 'BOLUETA': 'Bolueta',
    'CASCO VIEJO': 'Casco Viejo', 'CASTAÑOS': 'Castaños',
    'ERREKALDEBERRI - LARRASKITU': 'Errekaldeberri', 'IBARREKOLANDA': 'Ibarrekolanda',
    'INDAUTXU': 'Indautxu', 'IRALABARRI': 'Iralabarri', 'ITURRALDE': 'Iturralde',
    'ITURRIGORRI - PEÑASCAL': 'Iturrigorri', 'LA PEÑA': 'La Peña',
    'MATIKO - CIUDAD JARDÍN': 'Matiko', 'MASUSTEGI - MONTE CARAMELO': 'Masustegi',
    'MIRIBILLA': 'Miribilla', 'OLABEAGA': 'Olabeaga', 'OTXARKOAGA': 'Otxarkoaga',
    'SAN ADRIAN': 'San Adrián', 'SAN FRANCISCO': 'San Francisco',
    'SAN IGNACIO - ELORRIETA': 'San Ignacio', 'SAN PEDRO DE DEUSTU - LA RIBERA': 'Deustu',
    'SANTUTXU': 'Santutxu', 'SOLOKOETXE': 'Solokoetxe', 'TXURDINAGA': 'Txurdinaga',
    'URETAMENDI': 'Uretamendi', 'URIBARRI': 'Uribarri', 'ZABALA': 'Zabala',
    'ZORROTZA': 'Zorrotza', 'ZURBARAN - ARABELLA': 'Zurbaran',
}


def marcas_de(pdf):
    """Los rótulos que reconocemos, ya en casillas del juego."""
    fuera, vistos = [], set()
    for texto, x, y in rotulos(pdf):
        texto = clave_de(texto)
        if texto is None or texto in vistos:
            continue
        gx, gy = a_casilla(x, y)
        if not (0 <= gx < MW and 0 <= gy < MH):
            continue
        vistos.add(texto)
        fuera.append((texto, gx, gy))
    fuera.sort(key=lambda m: NOMBRES[m[0]])
    return fuera


# ── el callejero ────────────────────────────────────────────────────────────────────
# Los rótulos de barrio van en Skia y filtrando por esa fuente salen los 35 y solo ellos.
# Todo lo demás que hay escrito sobre el mapa —y hay mucho— es el callejero: el plano
# rotula cada calle con su nombre, repetido a lo largo del trazado cuando es larga.
#
# Filtrar «todo lo que no sea Skia» no basta: ahí dentro caen números de portal, letras
# de la cuadrícula, nombres de equipamientos y el índice del margen. Se cribia con tres
# reglas que se sostienen solas:
#
#   1. tiene que parecer un nombre: tres letras o más, y no ser todo dígitos;
#   2. tiene que estar SOBRE la calle — un rótulo de calle se dibuja encima de su calle,
#      así que se exige calzada o acera a menos de cuatro casillas. Esto es lo que se
#      lleva por delante los equipamientos, que se rotulan sobre la manzana;
#   3. no puede ser un barrio, que ya tienen su tabla.
#
# Una calle larga sale rotulada varias veces. Los rótulos con el mismo nombre se juntan
# en una sola calle y sus posiciones se ordenan a lo largo del eje de la nube: eso da
# justo lo que come el juego —unos puntos de paso—, y el trazado entre ellos ya lo busca
# él solo por la calle de verdad.
CALLE_MIN_LETRAS = 3
CALLE_RADIO_VIA = 4          # casillas: cómo de cerca de la calle tiene que caer el rótulo


def _texto_de_calle(t):
    """Limpia el rótulo y dice si parece un nombre de calle. Devuelve None si no."""
    # El PDF usa ligaduras tipográficas: 'GRÁFICO' llega con un solo glifo 'ﬁ' y sin
    # deshacerlo el nombre sale con un carácter que no está en la fuente del juego.
    t = unicodedata.normalize('NFKC', t)
    t = _limpia(t)
    t = re.sub(r'\s*\d+\s*$', '', t).strip()          # «ERCILLA 12» → «ERCILLA»
    if len(re.findall(r'[^\W\d_]', t, re.UNICODE)) < CALLE_MIN_LETRAS:
        return None
    if re.fullmatch(r'[\d\W_]+', t, re.UNICODE):
        return None
    return t


def _cerca_de_via(rej, gx, gy, r=CALLE_RADIO_VIA):
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            x, y = gx + dx, gy + dy
            if 0 <= x < MW and 0 <= y < MH and rej[y * MW + x] in (CALLE, ACERA, PLAZA):
                return True
    return False


def _orden_en_eje(pts):
    """Ordena unos puntos a lo largo del eje que mejor los ajusta.

    Los rótulos de una calle larga salen del PDF en el orden en que estén escritos, que no
    es el de la calle. Sin ordenarlos, los puntos de paso van en zigzag y el trazado se
    recorre dos veces de punta a punta."""
    n = len(pts)
    if n < 3:
        return pts
    mx = sum(p[0] for p in pts) / n
    my = sum(p[1] for p in pts) / n
    sxx = sum((p[0] - mx) ** 2 for p in pts) / n
    syy = sum((p[1] - my) ** 2 for p in pts) / n
    sxy = sum((p[0] - mx) * (p[1] - my) for p in pts) / n
    import math
    ang = .5 * math.atan2(2 * sxy, sxx - syy)
    ux, uy = math.cos(ang), math.sin(ang)
    return sorted(pts, key=lambda p: (p[0] - mx) * ux + (p[1] - my) * uy)


def indice_callejero(pdf):
    """Los nombres de calle del índice del margen: el callejero oficial, limpio.

    El plano trae en el margen derecho la lista alfabética de todas las calles con su
    casilla de la cuadrícula — «C.  Abaitua Eulalia  F 3». Eso es oro: sobre el mapa los
    nombres están escritos letra a letra siguiendo la curva de la calle y salen hechos
    picadillo, pero aquí están enteros y bien escritos. Se usan de diccionario: del mapa
    se saca DÓNDE, y de aquí QUÉ."""
    p = pdf[0]
    caja = pymupdf.Rect(RECORTE[2], 0, p.rect.x1, p.rect.y1)
    txt = unicodedata.normalize('NFKC', p.get_text('text', clip=caja))
    fuera = {}
    # El separador es un tabulador en el PDF de verdad, pero al extraer texto de otras
    # formas llega como varios espacios: se aceptan los dos.
    sep = r'(?:\t|\s{2,})'
    for m in re.finditer(r'^\s*[A-Za-zÁÉÍÓÚÑ]{1,3}\.?\s*' + sep + r'\s*(.+?)\s*' + sep +
                         r'\s*([A-G])\s*([1-7])\s*$', txt, re.M):
        nombre = re.sub(r'\s+', ' ', m.group(1)).strip()
        if len(nombre) < 3:
            continue
        fuera.setdefault(_clave_calle(nombre), (nombre, m.group(2), int(m.group(3))))
    return fuera


def _clave_calle(t):
    """El nombre reducido a lo comparable: sin tildes, sin signos y sin mayúsculas."""
    t = unicodedata.normalize('NFD', t)
    t = ''.join(c for c in t if unicodedata.category(c) != 'Mn')
    return re.sub(r'[^a-z0-9]', '', t.lower())


def _cadenas(pdf):
    """Reconstruye los rótulos del mapa juntando las letras que van seguidas.

    El plano no escribe 'ALAMEDA URQUIJO' de un tirón: reparte las letras a lo largo de la
    calle, una a una y siguiendo su curva. PyMuPDF las devuelve troceadas en spans y líneas
    que no tienen nada que ver con el nombre.

    Así que se trabaja por letras: cada una con su sitio, su cuerpo y la dirección en que
    está escrita, y se encadenan las que van a continuación unas de otras. Las tolerancias
    son apretadas a propósito — mismo cuerpo, misma línea de base, hacia delante y a menos
    de dos cuerpos — porque con margen de sobra la cadena salta de un rótulo al de al lado
    y salen engendros con las letras de dos calles entrelazadas."""
    p = pdf[0]
    caja = pymupdf.Rect(*RECORTE)
    letras = []
    for b in p.get_text('rawdict', clip=caja)['blocks']:
        for l in b.get('lines', []):
            dx, dy = l.get('dir', (1, 0))
            for sp in l['spans']:
                if FUENTE_ROTULO in sp['font']:
                    continue                       # eso es un barrio
                cuerpo = round(sp.get('size', 8), 1)
                for ch in sp.get('chars', []):
                    if not ch['c'].strip():
                        continue
                    x0, y0, x1, y1 = ch['bbox']
                    letras.append([ch['c'], (x0 + x1) / 2, (y0 + y1) / 2,
                                   max(2.0, y1 - y0), dx, dy, cuerpo])
    LADO = 24
    cubo = {}
    for i, L in enumerate(letras):
        cubo.setdefault((int(L[1] // LADO), int(L[2] // LADO)), []).append(i)
    padre = list(range(len(letras)))

    def raiz(a):
        while padre[a] != a:
            padre[a] = padre[padre[a]]
            a = padre[a]
        return a

    for i, A in enumerate(letras):
        cx, cy, h, ux, uy, cuerpo = A[1], A[2], A[3], A[4], A[5], A[6]
        for ddx in (-1, 0, 1):
            for ddy in (-1, 0, 1):
                for j in cubo.get((int(cx // LADO) + ddx, int(cy // LADO) + ddy), ()):
                    if j == i:
                        continue
                    B = letras[j]
                    if B[6] != cuerpo:                     # otro cuerpo, otro rótulo
                        continue
                    if ux * B[4] + uy * B[5] < .97:        # escritas en otra dirección
                        continue
                    vx, vy = B[1] - cx, B[2] - cy
                    largo = vx * ux + vy * uy              # a lo largo del renglón
                    ancho = abs(-vx * uy + vy * ux)        # separación de la línea de base
                    if not (0 < largo <= 2.0 * h) or ancho > .5 * h:
                        continue
                    ra, rb = raiz(i), raiz(j)
                    if ra != rb:
                        padre[ra] = rb
    grupos = {}
    for i in range(len(letras)):
        grupos.setdefault(raiz(i), []).append(i)
    fuera = []
    for g in grupos.values():
        ux = sum(letras[i][4] for i in g) / len(g)
        uy = sum(letras[i][5] for i in g) / len(g)
        g.sort(key=lambda i: letras[i][1] * ux + letras[i][2] * uy)
        fuera.append((''.join(letras[i][0] for i in g),
                      sum(letras[i][1] for i in g) / len(g),
                      sum(letras[i][2] for i in g) / len(g)))
    return fuera


# La cuadrícula del plano: siete columnas (A-G) por siete filas (1-7) sobre el recorte.
def _celda(gx, gy):
    col = 'ABCDEFG'[min(6, gx * 7 // MW)]
    return col, min(7, gy * 7 // MH + 1)


def calles_de(pdf, rej):
    """Las calles del plano, con su nombre del índice y su sitio del mapa.

    Un rótulo del mapa solo se acepta si su texto —hecho picadillo y todo— corresponde a un
    nombre del índice, y si además cae en la casilla de la cuadrícula que el índice le da o
    en una vecina. Las dos condiciones a la vez es lo que se lleva por delante la basura:
    los números de portal, las letras de la cuadrícula, los nombres de equipamiento y las
    cadenas que se han comido dos rótulos entrelazados no están en el índice, y un nombre
    que sí está pero aparece en la otra punta de Bilbao no es esa calle."""
    indice = indice_callejero(pdf)
    # El índice, repartido por casilla de la cuadrícula: así cada rótulo del mapa solo se
    # compara con las calles que pueden estar donde él está, y no con las mil cuatrocientas.
    por_celda = {}
    for k, ent in indice.items():
        por_celda.setdefault((ent[1], ent[2]), []).append((k, ent))
    por_nombre = {}
    for txt, x, y in _cadenas(pdf):
        k = _clave_calle(txt)
        if len(k) < 5:
            continue
        gx, gy = a_casilla(x, y)
        if not (0 <= gx < MW and 0 <= gy < MH):
            continue
        if not _cerca_de_via(rej, gx, gy):
            continue                               # un equipamiento, no una calle
        col, fila = _celda(gx, gy)
        # Sobre el mapa el rótulo suele traer solo el nombre propio —'URQUIJO'— y el índice
        # lo lista invertido —'Urquijo Alameda'—, así que pedir que coincidan enteros deja
        # fuera a la mayoría. Vale que uno contenga al otro, pero solo si el trozo común es
        # largo y solo si NO hay dos calles de la casilla que encajen igual de bien: con un
        # 'san' de por medio, media Bilbao valdría.
        mejor, mejor_n, empate = None, 0, False
        for dc in (-1, 0, 1):
            for df in (-1, 0, 1):
                celda = (chr(ord(col) + dc), fila + df)
                for ik, ent in por_celda.get(celda, ()):
                    if k in ik:
                        n = len(k)
                    elif ik in k:
                        n = len(ik)
                    else:
                        continue
                    if n < 5:
                        continue
                    if n > mejor_n:
                        mejor, mejor_n, empate = ent, n, False
                    elif n == mejor_n and ent[0] != (mejor[0] if mejor else None):
                        empate = True
        if mejor is None or empate:
            continue
        por_nombre.setdefault(mejor[0], []).append((gx, gy))
    fuera = []
    for nombre, pts in por_nombre.items():
        limpios = []
        for q in _orden_en_eje(pts):
            if all(abs(q[0] - r[0]) + abs(q[1] - r[1]) > 6 for r in limpios):
                limpios.append(q)
        if not limpios:
            continue
        # Una calle con un solo rótulo no tiene tramo que recorrer. Se le da un segmento
        # mínimo para que el juego tenga por dónde empezar a buscar.
        if len(limpios) == 1:
            gx, gy = limpios[0]
            limpios = [(gx, gy), (gx + 1, gy)]
        fuera.append((nombre, limpios))
    fuera.sort(key=lambda c: c[0])
    return fuera


def bloque_calles_js(calles):
    filas = ',\n'.join(
        ' {n:%r, v:[%s]}' % (n, ','.join(f'[{x},{y}]' for x, y in v))
        for n, v in calles)
    return f"const CALLES=[\n{filas},\n];"


def bloque_calles_cs(calles):
    filas = ',\n'.join(
        '        C("%s", %s)' % (n, ', '.join(f'{x},{y}' for x, y in v))
        for n, v in calles)
    return f"    public static readonly Calle[] Calles = {{\n{filas},\n    }};"


def b64(datos):
    return base64.b64encode(bytes(comprimir(datos))).decode()


def troceado(cadena, sangria='  ', ancho=108):
    return '\n'.join(f"{sangria}'{cadena[i:i+ancho]}'+" for i in range(0, len(cadena), ancho))[:-1]


def bloque_js(rej, dueno, marcas):
    filas = ',\n'.join(
        f"  {{n:{NOMBRES[t]!r}, estilo:{ESTILOS[t][0]!r}, tinte:{ESTILOS[t][1]!r}, x:{gx}, y:{gy}}}"
        .replace("'", "'") for t, gx, gy in marcas)
    return (f"const MW={MW}, MH={MH};\n"
            f"/* {METROS_POR_PUNTO*(RECORTE[2]-RECORTE[0])/MW:.2f} m de Bilbao por casilla */\n"
            f"const BARRIOS=[\n{filas}];\n"
            f"const TRAMA=\n{troceado(b64(rej))};\n"
            f"const TRAMA_BARRIO=\n{troceado(b64(dueno))};")


def bloque_cs(rej, dueno, marcas):
    filas = ',\n'.join(
        f'        new Barrio("{NOMBRES[t]}", "{ESTILOS[t][0]}", "{ESTILOS[t][1]}", {gx}, {gy})'
        for t, gx, gy in marcas)

    def trozos(cad):
        # En vez de concatenar con '+', un array de cadenas. Concatenar deja un árbol de
        # sintaxis de mil quinientos niveles y los analizadores de herramientas/csharp/ se
        # quedan sin pila recorriéndolo; un array es plano.
        return ',\n'.join(f'        "{cad[i:i+108]}"' for i in range(0, len(cad), 108))

    return (f'    public const int MW = {MW}, MH = {MH};\n\n'
            f'    public static readonly Barrio[] Barrios = {{\n{filas}\n    }};\n\n'
            f'    static readonly string[] _trama = {{\n{trozos(b64(rej))}\n    }};\n\n'
            f'    static readonly string[] _barrios = {{\n{trozos(b64(dueno))}\n    }};\n\n'
            f'    public static string Trama() {{ return string.Concat(_trama); }}\n'
            f'    public static string TramaBarrio() {{ return string.Concat(_barrios); }}')


def sustituir(ruta, marca, texto):
    s = open(ruta, encoding='utf-8').read()
    a, b = f'/*<<<{marca}*/', f'/*{marca}>>>*/'
    i, j = s.index(a), s.index(b)
    s = s[:i + len(a)] + '\n' + texto + '\n' + s[j:]
    open(ruta, 'w', encoding='utf-8').write(s)


if __name__ == '__main__':
    ruta = sys.argv[1] if len(sys.argv) > 1 else 'plano_bilbao.pdf'
    pdf = pymupdf.open(ruta)
    doc_f, doc_c, n = capas(pdf)
    rej, viaria = aceras(rejilla(doc_f, doc_c))
    marcas = marcas_de(pdf)
    calles = calles_de(pdf, rej)
    dueno = barrios(rej, marcas)

    from collections import Counter
    c = Counter(rej)
    nombres = {CALLE: 'calle', ACERA: 'acera', EDIF: 'manzana', PARQUE: 'parque',
               AGUA: 'agua', PUENTE: 'puente', MONTE: 'monte'}
    print(f'{MW}x{MH} casillas · {METROS_POR_PUNTO*(RECORTE[2]-RECORTE[0])/MW:.2f} m por casilla '
          f'· {n} trazos de calzada · {len(marcas)} barrios · {len(calles)} calles')
    print(f'  calzada en una pieza: {viaria:.1f}%')
    for k, v in sorted(c.items()):
        print(f'  {nombres.get(k,k):8s} {v:8d}  {100*v/(MW*MH):5.1f}%')
    faltan = sorted(set(ESTILOS) - {m[0] for m in marcas})
    if faltan:
        print('  sin rótulo dentro del recorte: ' + ', '.join(faltan))

    raiz = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
    html = os.path.join(raiz, 'referencia', 'bilbo-city.html')
    csf = os.path.join(raiz, 'unity', 'BilboCity', 'Assets', 'Scripts', 'Ciudad', 'Plano.cs')
    calf = os.path.join(raiz, 'unity', 'BilboCity', 'Assets', 'Scripts', 'Ciudad', 'Callejero.cs')
    sustituir(html, 'PLANO', bloque_js(rej, dueno, marcas))
    sustituir(html, 'CALLES', bloque_calles_js(calles))
    print(f'  -> {html}')
    if os.path.exists(csf):
        sustituir(csf, 'PLANO', bloque_cs(rej, dueno, marcas))
        print(f'  -> {csf}')
    if os.path.exists(calf):
        sustituir(calf, 'CALLES', bloque_calles_cs(calles))
        print(f'  -> {calf}')
    with open('/tmp/trama.bin', 'wb') as f:
        f.write(bytes(rej))
    with open('/tmp/barrio.bin', 'wb') as f:
        f.write(bytes(dueno))

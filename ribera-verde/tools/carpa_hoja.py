#!/usr/bin/env python3
"""La hoja de la vista C (godot/arte/carpa.png + carpa.json), sin repetir lo que ya está en el atlas.

El atlas (godot/arte/atlas.png) y la hoja de la vista C salían los dos del mismo arte: de los 181 rectángulos de
carpa.json, 175 eran el mismo dibujo, píxel a píxel, que un fotograma del atlas, y viajaban dos veces en la app y
dos veces en memoria. Ahora cada sprite que ya está en el atlas se queda en el atlas: carpa.json lo apunta con su
rectángulo de atlas.png y lo nombra en «atlas», y la hoja guarda solo los propios (lo que se dibuja a mano aquí:
la maceta de 35 L y lo de la pared de servicio de las carpas de KAIA). src/arte.gd lee de una o de otra según eso.

  python3 -I tools/carpa_hoja.py          rehace la hoja (idempotente: dos pasadas dan lo mismo)

Como módulo, para los generadores que pegan sus sprites en la hoja (tools/maceta35.py,
tools/sprites/a-mano/kaia_vc.py):

  abre()                     carga carpa.json, carpa.png y el atlas
  saca(n, i=0)               el fotograma i del sprite n, de donde esté (atlas o hoja)
  pon(n, im, off=None)       mete (o cambia) un sprite propio de la hoja
  guarda()                   reempaqueta los propios y escribe carpa.png + carpa.json
"""
import hashlib
import json
import os
import sys

from PIL import Image

R = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PJ = os.path.join(R, 'godot', 'arte', 'carpa.json')
PP = os.path.join(R, 'godot', 'arte', 'carpa.png')
AJ = os.path.join(R, 'godot', 'arte', 'atlas.json')
AP = os.path.join(R, 'godot', 'arte', 'atlas.png')
ANCHO = 160          # la hoja propia: estantes de 160 px (lo más ancho que hay son los 48 del filtro)

j = {}               # carpa.json
hoja = None          # carpa.png
atlas = None         # atlas.png
af = {}              # frames del atlas
propios = {}         # sprite → [Image, …] de los que se dibujan en la hoja


def abre():
    """carga carpa.json, carpa.png y el atlas, y deja en «propios» los sprites que viven en la hoja"""
    global j, hoja, atlas, af, propios
    j = json.load(open(PJ, encoding='utf-8'))
    hoja = Image.open(PP).convert('RGBA')
    atlas = Image.open(AP).convert('RGBA')
    af = json.load(open(AJ, encoding='utf-8'))['frames']
    en_atlas = set(j.get('atlas', []))
    propios = {}
    for n in j['sprites']:
        if n not in en_atlas:
            propios[n] = [_corta(hoja, r) for r in j['sprites'][n]]


def _corta(im, r):
    return im.crop((int(r[0]), int(r[1]), int(r[0]) + int(r[2]), int(r[1]) + int(r[3])))


def _huella(im):
    """los píxeles del fotograma, contando como igual todo lo transparente"""
    d = bytearray(im.tobytes())
    for i in range(0, len(d), 4):
        if not d[i + 3]:
            d[i:i + 3] = b'\x00\x00\x00'
    return hashlib.sha1(bytes(d)).hexdigest() + '|%dx%d' % im.size


def saca(n, i=0):
    """el fotograma i del sprite n, de donde esté: del atlas si está en él, si no de la hoja"""
    if not j:
        abre()
    if n in propios:
        return propios[n][i]
    return _corta(atlas, j['sprites'][n][i])


def pon(n, im, off=None):
    """mete (o cambia) un sprite propio de la hoja; «off», su esquina dentro de su lienzo (lo recortado)"""
    if not j:
        abre()
    propios[n] = [im.convert('RGBA')]
    if n not in j['sprites']:
        j['sprites'][n] = [[0, 0, im.width, im.height]]
    j.setdefault('atlas', [])
    if n in j['atlas']:
        j['atlas'].remove(n)
    if off is not None:
        j.setdefault('off', {})[n] = list(off)


def guarda():
    """reempaqueta los propios en estantes de ANCHO px (por alto y nombre: siempre igual) y escribe hoja y JSON"""
    cajas = sorted(((n, i, im) for n in propios for i, im in enumerate(propios[n])),
                   key=lambda e: (-e[2].height, e[0], e[1]))
    x = y = alto_fila = 0
    sitio = {}
    for n, i, im in cajas:
        if x + im.width > ANCHO:
            x = 0
            y += alto_fila
            alto_fila = 0
        sitio[(n, i)] = (x, y)
        x += im.width
        alto_fila = max(alto_fila, im.height)
    out = Image.new('RGBA', (ANCHO, max(1, y + alto_fila)), (0, 0, 0, 0))
    for n, i, im in cajas:
        out.alpha_composite(im, sitio[(n, i)])
    for n, i, im in cajas:
        j['sprites'][n][i] = [sitio[(n, i)][0], sitio[(n, i)][1], im.width, im.height]
    out.save(PP)
    json.dump(j, open(PJ, 'w', encoding='utf-8'), ensure_ascii=False, separators=(',', ':'))
    return out.size, len(cajas)


def rehace():
    """deja en el atlas todo lo que ya está en él y en la hoja solo lo propio"""
    abre()
    idx = {}
    for k, r in af.items():
        idx.setdefault(_huella(_corta(atlas, [r['x'], r['y'], r['w'], r['h']])), (k, r))
    en_atlas, fuera = [], 0
    for n in list(j['sprites']):
        marcos = [saca(n, i) for i in range(len(j['sprites'][n]))]
        ks = [idx.get(_huella(im)) for im in marcos]
        if all(k is not None for k in ks):
            en_atlas.append(n)
            j['sprites'][n] = [[k[1]['x'], k[1]['y'], k[1]['w'], k[1]['h']] for k in ks]
            propios.pop(n, None)
        else:
            fuera += 1
    j['atlas'] = en_atlas
    tam, nm = guarda()
    return en_atlas, fuera, tam, nm


if __name__ == '__main__':
    antes = os.path.getsize(PP)
    en_atlas, fuera, tam, nm = rehace()
    print('carpa.png %dx%d, %d fotogramas propios de %d sprites (%d sprites en el atlas); %d → %d bytes'
          % (tam[0], tam[1], nm, fuera, len(en_atlas), antes, os.path.getsize(PP)))

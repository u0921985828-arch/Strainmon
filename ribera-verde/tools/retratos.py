# Landrace Hunters — MAESTRO [8]: los retratos de diálogo, uno por muñeco del mapa (el grupo del atlas: cubre «look:…»), sacados
# con PixelLab (create_portrait_character, character_to_portrait, 64 × 64, 24 colores) del sprite de frente de cada uno.
# Los originales están en tools/sprites/retratos/<grupo>.png; esto los junta en godot/arte/retratos.png + retratos.json
# ({"w": 64, "grupos": {grupo: [x, y]}}) y quita la línea clara que deja PixelLab en el canto de abajo de alguno.
# Los estados (tools/sprites/retratos/estados/<grupo>-<estado>.png, inpaint de PixelLab sobre cada busto: n1 hablando,
# p parpadeo, a0/e0/d0 contento, enfadado y dudando, a1/e1/d1 lo mismo hablando) van debajo, una fila por grupo, en
# "estados": {grupo: {estado: [x, y]}}.
# Uso: python3 -I tools/retratos.py
import json, os
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(AQUI, 'sprites', 'retratos')
DST = os.path.join(AQUI, '..', 'godot', 'arte')
EST = os.path.join(SRC, 'estados')
W, COL = 64, 8
ESTADOS = ['n1', 'p', 'a0', 'a1', 'e0', 'e1', 'd0', 'd1']


def abre(ruta):
    im = Image.open(ruta).convert('RGBA')
    assert im.size == (W, W), (ruta, im.size)
    px = im.load()
    for y in (W - 1, W - 2):   # la línea casi blanca del canto de abajo
        claros = [x for x in range(W) if px[x, y][3] and min(px[x, y][:3]) > 235]
        if len(claros) > W // 2:
            for x in claros:
                px[x, y] = (0, 0, 0, 0)
    return im


gs = sorted(f[:-4] for f in os.listdir(SRC) if f.endswith('.png'))
filas = (len(gs) + COL - 1) // COL
ge = [g for g in gs if os.path.isdir(EST) and any(os.path.exists(os.path.join(EST, '%s-%s.png' % (g, e))) for e in ESTADOS)]
hoja = Image.new('RGBA', (COL * W, (filas + len(ge)) * W), (0, 0, 0, 0))
grupos, estados = {}, {}
for i, g in enumerate(gs):
    x, y = (i % COL) * W, (i // COL) * W
    hoja.paste(abre(os.path.join(SRC, g + '.png')), (x, y))
    grupos[g] = [x, y]
n = 0
for j, g in enumerate(ge):
    estados[g] = {}
    for c, e in enumerate(ESTADOS):
        ruta = os.path.join(EST, '%s-%s.png' % (g, e))
        if os.path.exists(ruta):
            x, y = c * W, (filas + j) * W
            hoja.paste(abre(ruta), (x, y))
            estados[g][e] = [x, y]
            n += 1
hoja.save(os.path.join(DST, 'retratos.png'))
with open(os.path.join(DST, 'retratos.json'), 'w') as f:
    json.dump({'w': W, 'grupos': grupos, 'estados': estados}, f, ensure_ascii=False, separators=(',', ':'))
print(len(gs), 'retratos y', n, 'estados →', os.path.relpath(os.path.join(DST, 'retratos.png')))

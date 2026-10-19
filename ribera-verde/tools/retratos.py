# Landrace Hunters — MAESTRO [8]: los retratos de diálogo, uno por muñeco del mapa (el grupo del atlas: cubre «look:…»), sacados
# con PixelLab (create_portrait_character, character_to_portrait, 64 × 64, 24 colores) del sprite de frente de cada uno.
# Los originales están en tools/sprites/retratos/<grupo>.png; esto los junta en godot/arte/retratos.png + retratos.json
# ({"w": 64, "grupos": {grupo: [x, y]}}) y quita la línea clara que deja PixelLab en el canto de abajo de alguno.
# Uso: python3 -I tools/retratos.py
import json, os
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(AQUI, 'sprites', 'retratos')
DST = os.path.join(AQUI, '..', 'godot', 'arte')
W, COL = 64, 8

gs = sorted(f[:-4] for f in os.listdir(SRC) if f.endswith('.png'))
filas = (len(gs) + COL - 1) // COL
hoja = Image.new('RGBA', (COL * W, filas * W), (0, 0, 0, 0))
grupos = {}
for i, g in enumerate(gs):
    im = Image.open(os.path.join(SRC, g + '.png')).convert('RGBA')
    assert im.size == (W, W), (g, im.size)
    px = im.load()
    for y in (W - 1, W - 2):   # la línea casi blanca del canto de abajo
        claros = [x for x in range(W) if px[x, y][3] and min(px[x, y][:3]) > 235]
        if len(claros) > W // 2:
            for x in claros:
                px[x, y] = (0, 0, 0, 0)
    x, y = (i % COL) * W, (i // COL) * W
    hoja.paste(im, (x, y))
    grupos[g] = [x, y]
hoja.save(os.path.join(DST, 'retratos.png'))
with open(os.path.join(DST, 'retratos.json'), 'w') as f:
    json.dump({'w': W, 'grupos': grupos}, f, ensure_ascii=False, separators=(',', ':'))
print(len(gs), 'retratos →', os.path.relpath(os.path.join(DST, 'retratos.png')))

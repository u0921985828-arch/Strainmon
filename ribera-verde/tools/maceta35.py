# La maceta de tela de 35 L de la vista C (equipo_c.py: maceta-c-tela35-28) en godot/arte/carpa.png + carpa.json, en una celda
# libre de 32 × 32 (el HTML está congelado en la 1.37 y tools/godot.js no se vuelve a pasar). python3 -I tools/maceta35.py
import json, os, sys
R = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(R, 'tools', 'sprites', 'a-mano'))
os.chdir(R)
import equipo_c
from PIL import Image
N, XY = 'maceta-c-tela35-28', (704, 736)
im = equipo_c.SAL['carpa-c-macetas-b'][N][0].im
pj = os.path.join(R, 'godot', 'arte', 'carpa.json'); pp = os.path.join(R, 'godot', 'arte', 'carpa.png')
j = json.load(open(pj)); a = Image.open(pp).convert('RGBA')
if N not in j['sprites']:
    assert a.crop((XY[0], XY[1], XY[0] + 32, XY[1] + 32)).getbbox() is None, 'la celda no está libre'
a.paste(Image.new('RGBA', (32, 32), (0, 0, 0, 0)), XY); a.alpha_composite(im, XY)
j['sprites'][N] = [[XY[0], XY[1], 32, 32]]
a.save(pp); json.dump(j, open(pj, 'w'), ensure_ascii=False, separators=(',', ':'))
print(N, im.getbbox())

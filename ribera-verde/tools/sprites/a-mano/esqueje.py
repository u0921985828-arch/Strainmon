# python3 -I tools/sprites/a-mano/esqueje.py [vista.png]  (Python 3 + Pillow; no va en los scripts de npm)
# El esqueje en grande del carro de esquejes (1.40, Godot: CLON_G en godot/src/trama.gd, pegado a mano desde lo que imprime).
# Arte propio, a mano por geometría: el tallo de 1 px y, arriba, cuatro hojas de cannabis (dos de cada lado, las de atrás
# más oscuras) con sus dedos lanceolados en abanico, nervio central y haz/envés, y dos brotes a media altura; se pinta a 6×
# y se reduce por mayoría (lo que cubre menos del 30 % de la celda, fuera). Letras: L haz, X hoja, D nervio y envés,
# K la hoja de atrás en sombra, T tallo; en el juego, X es el color de hoja de la variedad y el resto sale de él.
import math, sys
from PIL import Image, ImageDraw

S, W, H = 6, 48, 44
C = {'L': (140, 205, 95), 'X': (87, 163, 62), 'D': (52, 110, 40), 'K': (34, 74, 30), 'T': (100, 150, 60)}
im = Image.new('RGB', (W * S, H * S), (0, 0, 0))
dr = ImageDraw.Draw(im)

def P(x, y):
	return (x * S, y * S)

def dedo(x0, y0, ang, L, wd, tono):
	a = math.radians(ang)
	dx, dy = math.sin(a), -math.cos(a)
	nx, ny = -dy, dx
	n = 16
	izq = [(x0 + dx * s / n * L + nx * wd * math.sin(math.pi * s / n) ** .9, y0 + dy * s / n * L + ny * wd * math.sin(math.pi * s / n) ** .9) for s in range(n + 1)]
	der = [(x0 + dx * s / n * L - nx * wd * math.sin(math.pi * s / n) ** .9, y0 + dy * s / n * L - ny * wd * math.sin(math.pi * s / n) ** .9) for s in range(n, -1, -1)]
	dr.polygon([P(*p) for p in izq + der[1:]], fill=C[tono[0]])
	dr.polygon([P(*p) for p in [(x0, y0)] + der], fill=C[tono[1]])
	dr.line([P(x0, y0), P(x0 + dx * L * .85, y0 + dy * L * .85)], fill=C[tono[2]], width=max(1, S // 3))

def hoja(x0, y0, dirg, L, tono, n, abre, wd):
	larg = [.45, .7, .92, 1, .92, .7, .45] if n == 7 else [.6, .88, 1, .88, .6] if n == 5 else [.7, 1, .7]
	for i, l in enumerate(larg):
		dedo(x0, y0, dirg + (i - (n - 1) / 2) * abre / (n - 1), L * l, wd, tono)

def linea(a, b, w):
	dr.line([P(*a), P(*b)], fill=C['T'], width=int(S * w))

FR, AT = ('L', 'X', 'D'), ('X', 'D', 'K')
sx, top = 24, 21
linea((sx, top), (sx, H), .8)
for lx, ly, dg in [(sx - 7, top - 7, -30), (sx + 7, top - 8, 30)]:
	linea((sx, top), (lx, ly), .5)
	hoja(lx, ly, dg, 10, AT, 7, 170, .85)
linea((sx, 35), (sx - 3, 33), .5)
hoja(sx - 3, 33, -50, 5, FR, 3, 90, .7)
linea((sx, 29), (sx + 3, 27), .5)
hoja(sx + 3, 27, 50, 5, FR, 3, 90, .7)
for lx, ly, dg in [(sx - 12, top - 1, -75), (sx + 12, top - 2, 75)]:
	linea((sx, top), (lx, ly), .5)
	hoja(lx, ly, dg, 12, FR, 7, 200, .9)
linea((sx, top), (sx, top - 6), .5)
hoja(sx, top - 6, 0, 9, FR, 5, 150, .8)

filas = []
for y in range(H):
	f = ''
	for x in range(W):
		cnt = {}
		for b in range(S):
			for a in range(S):
				p = im.getpixel((x * S + a, y * S + b))
				if p != (0, 0, 0):
					k = next(k for k, v in C.items() if v == p)
					cnt[k] = cnt.get(k, 0) + 1
		f += max(cnt, key=cnt.get) if sum(cnt.values()) >= S * S * .3 else '.'
	filas.append(f)
while filas and set(filas[0]) == {'.'}:
	filas.pop(0)
print('const CLON_G := [')
print(',\n'.join('\t"%s"' % f for f in filas) + ']')
if len(sys.argv) > 1:
	v = Image.new('RGB', (W, len(filas)), (28, 32, 46))
	for y, f in enumerate(filas):
		for x, ch in enumerate(f):
			if ch in C:
				v.putpixel((x, y), C[ch])
	v.resize((W * 8, len(filas) * 8), Image.NEAREST).save(sys.argv[1])

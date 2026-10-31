# Landrace Hunters — lo de KAIA y del laboratorio hecho con PixelLab (lo pidió el usuario: «quiero que lo hagas con Pixel Lab,
# no lo hagas tú con dibujos»). Junta en godot/arte/kaia_pl.png (+ .json) los candidatos elegidos de
# tools/sprites/pixellab-kaia/crudo: las escenas de cada paso del laboratorio (160 × 76), la mesa de cultivo, el LED y lo demás.
# Lo único que se toca: los cantos rosas que deja PixelLab en la primera y la última columna (se copia la de al lado).
import json, os
from PIL import Image

R = os.path.dirname(os.path.abspath(__file__))
CRUDO = os.path.join(R, "pixellab-kaia", "crudo")
SALE = os.path.join(R, "..", "..", "godot", "arte", "kaia_pl")
# las escenas animadas (lo pidió el usuario: «rehaz las demás animaciones, con esta calidad»): de cada una, los fotogramas 1-4 de
# animate_image (pixellab-kaia/anim/<clave>-<i>.png; el 0 es la escena tal cual) en kaia_pl_anim.png, 4 por fila, una fila por
# escena (aparte: una sola hoja pasaría de los 16384 px de alto de una textura), con su modo de anim.json (vaiven o bucle)
ANIM = os.path.join(R, "pixellab-kaia", "anim")
FOTOS = 4

ELEGIDAS = {
	"lmanos-0": "lmanos0-0", "lmanos-1": "lmanos1-2", "lmanos-2": "lmanos2-1",
	"lepi-0": "lepi0-1", "lepi-1": "lepi1-1", "lepi-2": "lepi2-3",
	"lauto-0": "lauto0-1", "lauto-1": "lauto1-2", "lauto-2": "lauto2-1",
	"lflujo-0": "lflujo0-1", "lflujo-1": "lflujo1-0", "lflujo-2": "lflujo2-1",
	"lmicro-0": "lmicro0-1", "lmicro-1": "lmicro1-1",
	"lbal-0": "lbal0-3", "lbal-1": "lbal1-1",
	"lres-0": "lres0-0", "lres-1": "lres1-1",
	# las extracciones y la manicura (lo pidió el usuario: «rehaz las demás animaciones, con esta calidad»)
	"rosin-0": "rosin0-3", "rosin-1": "rosin1-1", "rosin-2": "rosin2-3",
	"seco-0": "seco0-0", "seco-1": "seco1-2", "seco-2": "seco2-1", "seco-3": "seco3-0",
	"ice-0": "ice0-3", "ice-1": "ice1-0", "ice-2": "ice2-1", "ice-3": "ice3-2",
	"charas-0": "charas0-0", "charas-1": "charas1-1", "charas-2": "charas2-1",
	"hash-0": "hash0-2", "hash-1": "hash1-2",
	"moon-0": "moon0-1", "moon-1": "moon1-1", "moon-2": "moon2-2",
	"lava-0": "lava0-1", "lava-1": "lava1-1", "lava-2": "lava2-3", "lava-3": "lava3-2",
	"stat-0": "stat0-1", "stat-1": "stat1-2", "stat-2": "stat2-1", "stat-3": "stat3-0",
	"moon-3": "moon3-0",
	"mani-0": "mani0-0", "mani-1": "mani1-1", "mani-2": "mani2-0",
	# lo de la sala de cultivo de KAIA, de frente (lo pidió el usuario: «EN ISOMETRICO NO»)
	"o-drenKS": "depF-1", "o-mesaF": "mesaF-0",
}
# la pared de la carpa de sala por dentro: una casilla de 16 × 32 que se repite sin costura, de dos tramos de pliegues lisos
# de pared-0 (sin los cantos oscuros ni la hebilla del medio)
PARED = ("pared-0", ((18, 30), (6, 10)))

def rosa(c):
	return c[3] > 0 and c[0] > 180 and c[2] > 150 and c[1] < 120

def limpia(im):
	px = im.load()
	W, H = im.size
	for x, x2 in ((0, 1), (W - 1, W - 2), (1, 2), (W - 2, W - 3)):
		for y in range(H):
			if rosa(px[x, y]):
				px[x, y] = px[x2, y]
	return im

SIN_FONDO = set()   # los que PixelLab devolvió con el fondo pintado: fuera el color de la esquina (y lo que se le parece)
def quita_fondo(im):
	px = im.load()
	W, H = im.size
	f = px[0, 0]
	for y in range(H):
		for x in range(W):
			c = px[x, y]
			if sum(abs(c[i] - f[i]) for i in range(3)) <= 18:
				px[x, y] = (0, 0, 0, 0)
	return im

def main():
	ims = {k: limpia(Image.open(os.path.join(CRUDO, f + ".png")).convert("RGBA")) for k, f in ELEGIDAS.items()}
	for k in SIN_FONDO:
		ims[k] = quita_fondo(ims[k])
	pw = Image.open(os.path.join(CRUDO, PARED[0] + ".png")).convert("RGBA")
	t = Image.new("RGBA", (16, 32))
	x = 0
	for a, b in PARED[1]:
		t.paste(pw.crop((a, 0, b, 32)), (x, 0))
		x += b - a
	ims["t-pared"] = t
	W = max(i.width for i in ims.values())
	H = sum(i.height for i in ims.values())
	hoja = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	r = {}
	y = 0
	for k, i in ims.items():
		hoja.alpha_composite(i, (0, y))
		r[k] = [0, y, i.width, i.height]
		y += i.height
	hoja.save(SALE + ".png")
	modos = json.load(open(ANIM + ".json"))
	escenas = [k for k in ims if k in modos]
	w, h = ims[escenas[0]].size
	ha = Image.new("RGBA", (w * FOTOS, h * len(escenas)), (0, 0, 0, 0))
	ra = {}
	for n, k in enumerate(escenas):
		assert ims[k].size == (w, h), k
		for i in range(1, FOTOS + 1):
			im = limpia(Image.open(os.path.join(ANIM, "%s-%d.png" % (k, i))).convert("RGBA"))
			assert im.size == (w, h), (k, i, im.size)
			ha.alpha_composite(im, ((i - 1) * w, n * h))
			ra["%s/%d" % (k, i)] = [(i - 1) * w, n * h, w, h]
	ha.save(SALE + "_anim.png")
	with open(SALE + ".json", "w") as f:
		json.dump({"r": r, "ra": ra, "anim": {k: modos[k][1] for k in escenas}}, f, indent=0)
	for sale in (SALE + ".png", SALE + "_anim.png"):
		with open(sale + ".import", "w") as f:
			f.write('[remap]\n\nimporter="keep"\n')
	print(len(r), "piezas", hoja.size, "·", len(escenas), "escenas animadas", ha.size)

main()

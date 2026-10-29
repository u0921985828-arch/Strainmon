# Landrace Hunters — el protagonista con el EPI del laboratorio (bata, gafas y guantes), hecho con PixelLab (lo pidió el usuario:
# «quiero que lo hagas con Pixel Lab, no lo hagas tú con dibujos» y «tienen que ser de calidad»). Cada dirección, sus 4 fotogramas
# de idle y sus 4 de walk del atlas pasados por transfer_outfit con la referencia de edit_image (pixellab-epi/ref/<dir>.png, la de
# la protagonista f-<dir>.png); los crudos, en pixellab-epi/crudo/<dir>-<i>.png (0-3 idle, 4-7 walk; los de ella, f-<dir>-<i>.png).
# Junta en godot/arte/epi_pl.png (+ .json) cada uno con la clave del fotograma del atlas que sustituye (el de base, el primero de
# idle). Lo único que se toca: fuera lo semitransparente.
import json, os
from PIL import Image

R = os.path.dirname(os.path.abspath(__file__))
CRUDO = os.path.join(R, "pixellab-epi", "crudo")
SALE = os.path.join(R, "..", "..", "godot", "arte", "epi_pl")
DIRS = ("south", "east", "north", "west")

def limpia(im):
	px = im.load()
	W, H = im.size
	for y in range(H):
		for x in range(W):
			c = px[x, y]
			px[x, y] = (c[0], c[1], c[2], 255) if c[3] >= 128 else (0, 0, 0, 0)
	return im

def main():
	claves = []
	for g, pre in (("player", ""), ("player-f", "f-")):   # el protagonista y la protagonista (f-<dir>-<i>.png)
		for d in DIRS:
			for i in range(8):
				a, j = ("idle", i) if i < 4 else ("walk", i - 4)
				claves.append(("%s/%s/%s/%02d" % (g, a, d, j), "%s%s-%d" % (pre, d, i)))
			claves.append(("%s/base/%s/00" % (g, d), "%s%s-0" % (pre, d)))
	hoja = Image.new("RGBA", (32 * 9, 32 * len(claves) // 9), (0, 0, 0, 0))
	fr = {}
	for n, (k, f) in enumerate(claves):
		im = limpia(Image.open(os.path.join(CRUDO, f + ".png")).convert("RGBA"))
		assert im.size == (32, 32), (f, im.size)
		x, y = (n % 9) * 32, (n // 9) * 32
		hoja.paste(im, (x, y))
		fr[k] = {"x": x, "y": y, "w": 32, "h": 32}
	hoja.save(SALE + ".png")
	with open(SALE + ".json", "w") as o:
		json.dump({"frames": fr}, o, ensure_ascii=False, indent=1, sort_keys=True)
	print("epi_pl: %d fotogramas" % len(fr))

if __name__ == "__main__":
	main()

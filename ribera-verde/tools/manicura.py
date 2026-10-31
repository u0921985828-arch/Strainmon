# python3 -I tools/manicura.py  → MANICURA.pasos y MANICURA.per en godot/datos/datos.json (con Datos.CAL)
#
# Lo pidió el usuario: «manicura a la vista, una escena como la de las extracciones». Con CAL, manicurar un lote son tres pasos con su
# barra y su escena encima (escena_extr.gd, «mani»): fuera las hojas grandes, las hojitas de azúcar a ras y redondear el cogollo sin
# tocar los cálices. La parte que entra (q) deja el lote manicurado en 0,6 + 0,4 q (setas.gd manicura_action); por debajo de 1, se
# puede repasar.

import json, os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DJ = os.path.join(RAIZ, "godot", "datos", "datos.json")

PASOS = [["Fuera las hojas grandes, por el rabito.", 0.14], ["Las hojitas de azúcar, a ras, con la punta fina.", 0.12],
	["Redondear el cogollo sin tocar los cálices.", 0.1]]

def main():
	with open(DJ, encoding="utf-8") as fh:
		D = json.load(fh)
	M = D["MANICURA"]
	M["pasos"] = PASOS
	M["per"] = 1250
	M["base"] = 0.6   # el lote, manicurado en base + (1 − base) × q
	with open(DJ, "w", encoding="utf-8") as fh:
		json.dump(D, fh, ensure_ascii=False, separators=(",", ":"))
	print("manicura: %d pasos" % len(PASOS))

if __name__ == "__main__":
	main()

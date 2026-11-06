# MAESTRO [5] (lo que faltaba): las familias de la CannaDex, la CannaCup por calendario y la potencia contratada.
# Escribe FAMILIAS, CUP y ENERGIA en godot/datos/datos.json (idempotente).
import json, os, sys

R = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "godot", "datos", "datos.json")
D = json.load(open(R, encoding="utf-8"))

FAMILIAS = {
	"kush": {"n": "Las del Kush", "b": "res", "v": 0.25,
		"s": ["rif", "hindu", "chitral", "purpura", "afkush", "purpurah", "kif", "beldia", "libano", "kashmir", "malana"]},
	"asia": {"n": "Las de Asia", "b": "flor", "v": 0.04,
		"s": ["thai", "choco", "hthai", "lao", "nepal", "vietblack", "kerala", "kali", "amanecer"]},
	"america": {"n": "Las de América", "b": "thc", "v": 0.03,
		"s": ["acapulco", "mich", "punto", "colgold", "oaxaca", "panama", "mangarosa", "hawai", "lamb"]},
	"africa": {"n": "Las de África", "b": "flor", "v": 0.04,
		"s": ["malawi", "congo", "durban", "swazi", "zamal", "etiopia", "congopan", "malapan", "malapck"]},
	"skunk": {"n": "Las del olor fuerte", "b": "g", "v": 0.05,
		"s": ["ria", "txoko", "citrus", "cheese", "kushrif", "shiva", "bluetx", "criticalcheese", "critical47", "chronic"]},
	"haze": {"n": "Las Haze", "b": "thc", "v": 0.03,
		"s": ["haze", "limon", "nlhaze", "neville", "silver", "cannalope", "tormenta", "ssh", "superlemon", "purplehaze", "hawaisnow", "chocolope"]},
	"luces": {"n": "Las del norte", "b": "g", "v": 0.05,
		"s": ["nl", "mango", "niebla", "nieblamor", "nlbigbud", "nlblue", "ice", "buddha"]},
	"blancas": {"n": "Las blancas", "b": "res", "v": 0.25,
		"s": ["ww", "whiterussian", "bluewidow", "whiterhino", "whiteshark", "ak47", "kali47", "reina"]},
	"leyenda": {"n": "La leyenda", "b": "thc", "v": 0.04,
		"s": ["leyenda", "jackflash", "jack47", "criticaljack", "sollimon", "orotrop", "brumaog", "sourtangie", "dragon", "chemdawg", "calorange"]},
	"autos": {"n": "Las autos", "b": "flor", "v": 0.04, "s": list(D["AUTO"]["dex"])},
}
CUP = {"meses": [3, 6, 9, 12], "dia": 15, "ch": 7, "g": 20, "cu": 0.99, "aviso": 3,
	"premio": [6000, 2500, 1000], "prest": [3, 2, 1], "rival": [22.0, 28.0], "subeY": 0.6,
	"tipo": 2.0, "aroma": 1.5, "af": 1.0, "vip": 3,
	"rivales": ["Txoko Berdea", "Huerta Oihana", "Los de Arratia"],
	"tipos": ["sativa", "índica", "híbrida"]}
ENERGIA = {"casa": {"lim": 5750, "n": "El piso"}, "nave": {"lim": 15000, "n": "La nave"}, "calor": 3, "h": 12,
	"gen": {"n": "Generador diésel insonorizado", "p": 2400, "w": 5000, "kwh": 0.45,
		"d": "Cubre hasta 5 kW por encima de lo contratado, sin ruido: lo que pasa de la potencia no lo ve la compañía. Gasta gasóleo cada día que trabaja (en efectivo)."},
	"pl": {"n": "Placas solares", "p": 5200, "w": 2500,
		"d": "2,5 kW de placas con baterías: lo que pasa de la potencia contratada, hasta ahí, sale del tejado y no de la red. Sin gasto."}}

# todas las de la CannaDex en una familia como mucho, y que existan
vistas = set()
for k, f in FAMILIAS.items():
	for s in f["s"]:
		assert s in D["STRAINS"] or s in D["AUTO"]["dex"], s
		assert s not in vistas, s
		vistas.add(s)
fuera = [s for s in D["DEX"] if s not in vistas]
D["FAMILIAS"] = FAMILIAS
D["CUP"] = CUP
D["ENERGIA"] = ENERGIA
json.dump(D, open(R, "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
print("familias", len(FAMILIAS), "con", len(vistas), "de", len(D["DEX"]), "· sin familia:", fuera)

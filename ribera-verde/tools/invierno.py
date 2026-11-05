#!/usr/bin/env python3
# Calibra lo que le cuesta a una planta revegetada pasar el invierno en la huerta (HUERTA.rev.frio, campo.gd): cuenta las heladas y
# las nevadas que trae el generador del tiempo del juego (Datos.tiempo, el mismo hash) entre la poda y la primavera siguiente, y dice
# con cuánta salud sale o si se queda seca. Sin argumentos: la tabla de los 15 primeros inviernos de partida.
#   python3 -I tools/invierno.py [frio] [salud]
import json, sys, datetime, os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
D = json.load(open(os.path.join(RAIZ, "godot/datos/datos.json")))
T = D["TIEMPO"]
HU = {"helada": 25, "nieve": 50}   # HUERTA.helada / HUERTA.nieve
CAL0 = datetime.date(2026, 4, 20)   # Datos.CAL0


def hash_str(s):
    h = 2166136261
    for c in s:
        h = ((h ^ ord(c)) * 16777619) & 0xFFFFFFFF
    return h


def fecha(dia):
    return CAL0 + datetime.timedelta(days=dia - 1)


def dia_de(y, m, d):
    return (datetime.date(y, m, d) - CAL0).days + 1


def tiempo(dia):
    m = fecha(dia).month - 1
    h = hash_str("tiempo%d" % dia)
    r = h % 100
    k = T["k"][0]
    for i in range(len(T["k"])):
        r -= T["p"][m][i]
        if r < 0:
            k = T["k"][i]
            break
    v = ((h >> 8) % (2 * T["var"] + 1)) - T["var"]
    mx = T["t"][m][0] + v + T["dt"][k]
    mn = min(T["t"][m][1] + v + min(0, T["dt"][k]), mx - 3)
    if k == "nieve":
        mn = min(mn, 0)
    return k, mn


def invierno(poda, frio, salud):
    """de la poda al 20 de abril del año siguiente: salud que queda (0 = seca)"""
    fin = dia_de(fecha(poda).year + 1, 4, 20)
    nieve = helada = 0
    h = float(salud)
    muere = 0
    for dia in range(poda + 1, fin + 1):
        k, mn = tiempo(dia - 1)   # huerta_dia mira la mínima de ayer
        dano = 0.0
        if k == "nieve":
            dano = HU["nieve"]
            nieve += 1
        elif mn <= 0:
            dano = HU["helada"]
            helada += 1
        if dano and h > 0:
            h = max(0.0, h - dano * frio)
            if h <= 0 and not muere:
                muere = dia
    return {"dias": fin - poda, "nieve": nieve, "helada": helada, "salud": h, "muere": muere}


def main():
    frio = float(sys.argv[1]) if len(sys.argv) > 1 else 0.15
    salud = float(sys.argv[2]) if len(sys.argv) > 2 else 80.0
    print("rev.frio %s · salud tras la poda %s" % (frio, salud))
    muertas = 0
    for y in range(2026, 2041):
        poda = dia_de(y, 9, 21)
        r = invierno(poda, frio, salud)
        if r["muere"]:
            muertas += 1
        print("poda 21-9-%d · %3d dias · %2d nevadas · %2d heladas · %s"
              % (y, r["dias"], r["nieve"], r["helada"],
                 "SECA el %s" % fecha(r["muere"]).isoformat() if r["muere"] else "sale con %.1f de salud" % r["salud"]))
    print("se quedan en el camino %d de 15" % muertas)


if __name__ == "__main__":
    main()

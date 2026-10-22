# Las bolas de la bola 8, a mano (lo pidió el usuario: «Las bolas también tienen que tener sprites, cuando se mueven y demás»).
# A 5 px de diámetro (billar8.gd: R = 2,5) PixelLab no da nada que se lea; aquí cada bola se pinta como una esfera de verdad:
# por cada píxel del contorno de 5 × 5 (la misma silueta de siempre: 3 + 5 + 5 + 5 + 3) se miran 4 × 4 puntos de la esfera, se
# giran a la bola y se ve qué toca de su dibujo: lisa (el color con el círculo blanco del número en los dos polos), rayada (blanca
# con la franja de color y el círculo encima), la negra y la blanca. La luz, de arriba a la izquierda, en tres tonos por material,
# y el brillo fijo arriba a la izquierda. Rodar: 8 direcciones × 8 fases (una vuelta entera de la bola = 2πR de camino); caer en
# la tronera: 3 fotogramas cada vez más pequeños y oscuros.
# Salida: godot/arte/billar_bolas.png (16 filas, una por bola; columnas: dirección × 8 + fase, y 64-66 la caída; celdas de 5 × 5)
# + billar_bolas.json.
import os, json, math
from PIL import Image

R = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..')
OUT = os.path.join(R, 'godot', 'arte')
C = 5
ND, NF, NC = 8, 8, 3

COL = ["#f8f8f0", "#e8c040", "#3a62c8", "#e04040", "#7a4aa8", "#f08a30", "#2e9a5a", "#8a3030", "#26262e"]

def hexrgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))

def mezcla(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))

def tonos(base):   # oscuro, medio, claro
    if base == hexrgb(COL[0]):
        return [(168, 164, 152), (220, 216, 200), (248, 248, 240)]
    if base == hexrgb(COL[8]):
        return [(20, 20, 24), (38, 38, 46), (74, 74, 86)]
    return [mezcla(base, (0, 0, 0), .38), base, mezcla(base, (255, 255, 255), .25)]

CREMA = [(196, 190, 170), (232, 226, 206), (244, 240, 226)]   # el círculo del número
BRILLO = (255, 255, 255)
BRILLO8 = (106, 106, 120)

# la silueta de siempre (_bola en billar8.gd)
MASK = [[0, 1, 1, 1, 0], [1, 1, 1, 1, 1], [1, 1, 1, 1, 1], [1, 1, 1, 1, 1], [0, 1, 1, 1, 0]]

LUZ = (-0.45, -0.55, 0.70)   # x a la derecha, y hacia abajo de la pantalla, z hacia quien mira
ln = math.sqrt(sum(c * c for c in LUZ))
LUZ = tuple(c / ln for c in LUZ)

def rot(eje, a):   # matriz de giro (Rodrigues)
    x, y, z = eje
    n = math.sqrt(x * x + y * y + z * z) or 1
    x, y, z = x / n, y / n, z / n
    c, s, t = math.cos(a), math.sin(a), 1 - math.cos(a)
    return [[t * x * x + c, t * x * y - s * z, t * x * z + s * y],
            [t * x * y + s * z, t * y * y + c, t * y * z - s * x],
            [t * x * z - s * y, t * y * z + s * x, t * z * z + c]]

def mm(A, B):
    return [[sum(A[i][k] * B[k][j] for k in range(3)) for j in range(3)] for i in range(3)]

def mv(A, v):
    return tuple(sum(A[i][k] * v[k] for k in range(3)) for i in range(3))

def tr(A):
    return [[A[j][i] for j in range(3)] for i in range(3)]

# rodar hacia u (en la mesa): el giro es alrededor de z × u (z hacia quien mira), y lo que se ve arriba avanza hacia u
def rodar(u, th):
    eje = (-u[1], u[0], 0.0)
    G = rot(eje, th)
    p = mv(rot(eje, 0.2), (0.0, 0.0, 1.0))
    assert p[0] * u[0] + p[1] * u[1] > 0, "el dibujo tiene que ir hacia donde rueda"
    return G

def base(n):   # cada bola, con su polo inclinado distinto para que no salgan iguales
    a = 0.55 + 0.37 * n
    return mm(rot((math.cos(a), math.sin(a), 0.0), 0.75 + 0.11 * (n % 5)), rot((0, 0, 1), 0.9 * n))

def material(n, lp):   # lo que toca en la bola en el punto lp (coordenadas de la bola)
    x, y, z = lp
    disco = abs(z) > 0.84
    if n == 0:
        return 'blanca'
    if n == 8:
        return 'crema' if disco else 'color'
    if n <= 7:
        return 'crema' if disco else 'color'
    if disco:
        return 'crema'
    return 'color' if abs(x) < 0.5 else 'blanca'

# la caída: cada vez más pequeña (4, 3 y 2 px), centrada en la celda
CAIDA = [([[0, 1, 1, 0], [1, 1, 1, 1], [1, 1, 1, 1], [0, 1, 1, 0]], 0.25),
         ([[0, 1, 0], [1, 1, 1], [0, 1, 0]], 0.5),
         ([[1, 1], [1, 1]], 0.7)]

def pinta(n, O, mask=MASK, osc=0.0):
    img = Image.new('RGBA', (C, C), (0, 0, 0, 0))
    col = tonos(hexrgb(COL[n if n <= 8 else n - 8]))
    blanca = tonos(hexrgb(COL[0]))
    Ot = tr(O)
    S = len(mask)
    rr = S / 2
    o0 = (C - S) // 2
    for py in range(S):
        for px in range(S):
            if not mask[py][px]:
                continue
            # el material, por mayoría de 4 × 4 puntos (los del centro pesan más); el tono, por la luz en el centro del píxel
            # (un mapa fijo: así la bola no parpadea al rodar y la franja y el círculo se leen enteros)
            votos = {}
            for sy in range(4):
                for sx in range(4):
                    x = (px + (sx + .5) / 4 - rr) / rr
                    y = (py + (sy + .5) / 4 - rr) / rr
                    q = x * x + y * y
                    if q > 1:
                        continue
                    m = material(n, mv(Ot, (x, y, math.sqrt(1 - q))))
                    votos[m] = votos.get(m, 0) + (3 if sx in (1, 2) and sy in (1, 2) else 1)
            if not votos:
                m = material(n, mv(Ot, (0.0, 0.0, 1.0)))
            else:
                m = max(votos.items(), key=lambda kv: kv[1])[0]
            x = (px + .5 - rr) / rr
            y = (py + .5 - rr) / rr
            q = min(x * x + y * y, 0.95)
            nw = (x, y, math.sqrt(1 - q))
            lam = max(0.0, sum(nw[i] * LUZ[i] for i in range(3)))
            t = 0 if lam < 0.40 else 1 if lam < 0.88 else 2
            c = {'color': col, 'blanca': blanca, 'crema': CREMA}[m][t]
            if osc:
                c = mezcla(c, (8, 10, 14), osc)
            img.putpixel((o0 + px, o0 + py), (*c, 255))
    if mask is MASK:
        img.putpixel((1, 1), (*(BRILLO8 if n == 8 else BRILLO), 255))
    return img

def main():
    hoja = Image.new('RGBA', (C * (ND * NF + NC), C * 16), (0, 0, 0, 0))
    for n in range(16):
        B = base(n)
        for di in range(ND):
            a = di * 2 * math.pi / ND
            u = (math.cos(a), math.sin(a))
            for fi in range(NF):
                O = mm(rodar(u, fi * 2 * math.pi / NF), B)
                hoja.paste(pinta(n, O), ((di * NF + fi) * C, n * C))
        for k, (mk, o) in enumerate(CAIDA):
            hoja.paste(pinta(n, B, mk, o), ((ND * NF + k) * C, n * C))
    os.makedirs(OUT, exist_ok=True)
    hoja.save(os.path.join(OUT, 'billar_bolas.png'))
    with open(os.path.join(OUT, 'billar_bolas.json'), 'w') as f:
        json.dump({"c": C, "dirs": ND, "fases": NF, "caida": NC}, f)
    # para mirarlas: a 8×
    hoja.resize((hoja.width * 8, hoja.height * 8), Image.NEAREST).save('/tmp/billar_bolas_x8.png') if os.environ.get('VER') else None

if __name__ == '__main__':
    main()

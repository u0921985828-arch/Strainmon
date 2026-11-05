# python3 -I (módulo; lo usan tools/sprites/a-mano/revista.py y titulo.py)
# Las letras de rótulo del juego, dibujadas por código (lo pidió el usuario: «molaría hacer un sprite del título de la revista,
# como también molaría hacer un sprite del título del juego… Tiene que ser un título visual para poder utilizarlo en las fotos
# de publicidad»). Cada glifo son barras de 4 px de trazo en una caja de 14 × 20, de las que sale un rótulo con bisel (la luz,
# arriba a la izquierda, como en todo el arte del juego), contorno y sombra proyectada. Nada se escala ni se suaviza.
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo

AN, AL, TR = 14, 20, 4          # la caja de la letra y el trazo

# cada glifo: barras (x, y, w, h) y, si lleva, diagonales (x0, y0, x1, y1) de TR de grueso
BARRAS = {
    'A': [(0, 0, AN, TR), (0, 0, TR, AL), (AN - TR, 0, TR, AL), (0, 8, AN, TR)],
    'B': [(0, 0, TR, AL), (0, 0, 11, TR), (0, 8, 11, TR), (0, 16, 11, TR), (AN - TR, 2, TR, 7), (AN - TR, 11, TR, 6)],
    'C': [(0, 0, AN, TR), (0, 0, TR, AL), (0, 16, AN, TR)],
    'D': [(0, 0, TR, AL), (0, 0, 11, TR), (0, 16, 11, TR), (AN - TR, 2, TR, 16)],
    'E': [(0, 0, TR, AL), (0, 0, AN, TR), (0, 8, 11, TR), (0, 16, AN, TR)],
    'G': [(0, 0, AN, TR), (0, 0, TR, AL), (0, 16, AN, TR), (8, 10, 6, TR), (AN - TR, 10, TR, 10)],
    'H': [(0, 0, TR, AL), (AN - TR, 0, TR, AL), (0, 8, AN, TR)],
    'I': [(0, 0, AN, TR), (5, 0, TR, AL), (0, 16, AN, TR)],
    'J': [(AN - TR, 0, TR, 17), (0, 13, TR, 7), (0, 16, 11, TR)],
    'K': [(0, 0, TR, AL), (0, 8, 5, TR)],
    'L': [(0, 0, TR, AL), (0, 16, AN, TR)],
    'M': [(0, 0, TR, AL), (AN - TR, 0, TR, AL), (0, 0, AN, TR), (5, 0, TR, 9)],
    'N': [(0, 0, TR, AL), (AN - TR, 0, TR, AL)],
    'O': [(0, 0, AN, TR), (0, 16, AN, TR), (0, 0, TR, AL), (AN - TR, 0, TR, AL)],
    'P': [(0, 0, TR, AL), (0, 0, AN, TR), (0, 8, AN, TR), (AN - TR, 0, TR, 12)],
    'Q': [(0, 0, AN, TR), (0, 16, AN, TR), (0, 0, TR, AL), (AN - TR, 0, TR, AL), (8, 13, TR, 7)],
    'R': [(0, 0, TR, AL), (0, 0, 12, TR), (0, 8, 12, TR), (8, 0, TR, 11)],
    'S': [(0, 0, AN, TR), (0, 0, TR, 11), (0, 8, AN, TR), (AN - TR, 8, TR, 12), (0, 16, AN, TR)],
    'T': [(0, 0, AN, TR), (5, 0, TR, AL)],
    'U': [(0, 0, TR, 18), (AN - TR, 0, TR, 18), (0, 16, AN, TR)],
    'V': [(0, 0, TR, 12), (AN - TR, 0, TR, 12)],
    'W': [(0, 0, TR, AL), (AN - TR, 0, TR, AL), (0, 16, AN, TR), (5, 8, TR, 9)],
    'Y': [(5, 9, TR, 11)],
    'Z': [(0, 0, AN, TR), (0, 16, AN, TR)],
}
DIAG = {
    'K': [(TR, 9, AN, 0), (TR, 10, AN, AL - 1)],
    'N': [(TR, 1, AN - TR - 1, AL - 2)],
    'R': [(8, 11, AN - 1, AL - 1)],
    'V': [(1, 11, 6, AL - 1), (AN - 2, 11, 7, AL - 1)],
    'W': [(1, 0, 3, AL - 5)],
    'Y': [(0, 0, 6, 10), (AN - 1, 0, 7, 10)],
    'Z': [(AN - 2, TR, 1, AL - TR - 1)],
    'X': [(0, 0, AN - 1, AL - 1), (AN - 1, 0, 0, AL - 1)],
}
BARRAS.setdefault('X', [])
ESP = {' ': 6}                  # el espacio entre palabras


def _barra_diag(m, x0, y0, x1, y1, g=TR):
    """una diagonal de g de grueso en la máscara m (lista de listas de bool)"""
    n = max(abs(x1 - x0), abs(y1 - y0))
    for s in range(n + 1):
        t = s / max(1, n)
        cx = round(x0 + (x1 - x0) * t)
        cy = round(y0 + (y1 - y0) * t)
        for i in range(g):
            x = cx + i - (g >> 1) + 1
            if 0 <= x < len(m) and 0 <= cy < len(m[0]):
                m[x][cy] = True


def mascara(ch):
    """la silueta de la letra, como máscara de AN × AL"""
    m = [[False] * AL for _ in range(AN)]
    for (x, y, w, h) in BARRAS.get(ch, []):
        for i in range(x, min(AN, x + w)):
            for j in range(y, min(AL, y + h)):
                m[i][j] = True
    for d in DIAG.get(ch, []):
        _barra_diag(m, *d)
    return m


def ancho(txt, sep=2):
    w = 0
    for ch in txt:
        w += ESP.get(ch, AN + sep)
    return max(1, w - sep)


def bisel(M, w, h, cara, luz, sombra, borde, proy=None):
    """pinta una máscara M[i][j] de w × h con bisel (la luz arriba y a la izquierda, la sombra abajo y a la derecha), su
    contorno por fuera y, si se pide, la sombra proyectada dos píxeles abajo a la derecha. Devuelve el Lienzo."""
    pw, ph = (2, 2) if proy else (0, 0)
    L = Lienzo(w + pw, h + ph)

    def lleno(i, j):
        return 0 <= i < w and 0 <= j < h and M[i][j]

    if proy:                     # la sombra proyectada, debajo de todo
        for i in range(w):
            for j in range(h):
                if M[i][j]:
                    L.p(i + 2, j + 2, proy)
    for i in range(w):
        for j in range(h):
            if not M[i][j]:
                continue
            c = cara
            if not lleno(i, j - 1) or not lleno(i - 1, j):
                c = luz
            if not lleno(i, j + 1) or not lleno(i + 1, j):
                c = sombra
            if (not lleno(i, j - 1) and not lleno(i - 1, j)) and (not lleno(i, j + 1) or not lleno(i + 1, j)):
                c = luz
            L.p(i, j, c)
    if borde:
        for i in range(w):       # el contorno, por fuera
            for j in range(h):
                if M[i][j]:
                    continue
                if any(lleno(i + a, j + b) for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    L.p(i, j, borde)
    return L


def rotulo(txt, cara, luz, sombra, borde, sep=2, proy=None):
    """el rótulo con bisel, contorno y, si se pide, sombra proyectada. Devuelve un Lienzo con 1 px de aire por el contorno."""
    w, h = ancho(txt, sep), AL
    M = [[False] * (h + 2) for _ in range(w + 2)]
    x = 1
    for ch in txt:
        if ch in ESP:
            x += ESP[ch]
            continue
        m = mascara(ch)
        for i in range(AN):
            for j in range(AL):
                if m[i][j] and x + i < w + 2:
                    M[x + i][1 + j] = True
        x += AN + sep
    return bisel(M, w + 2, h + 2, cara, luz, sombra, borde, proy)

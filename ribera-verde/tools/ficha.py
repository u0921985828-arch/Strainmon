# Landrace Hunters — mide los textos de las fichas de Google Play (store/ficha-*.md): título ≤ 30, corta ≤ 80, larga ≤ 4000,
# el aviso de ficción en la larga y nada de lo que la versión de la tienda quita (cifras reales de cultivo, «pk-»).
# python3 -I tools/ficha.py (desde ribera-verde/) → sale con 1 si algo no cuadra
import glob, os, re, sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOPE = [30, 80, 4000]
MAL = re.compile(r'°C|µm|[Mm]icra|\bpH\b|\bpk-|[Pp]ok[eé]mon|Nintendo')
mal = 0
for f in sorted(glob.glob(os.path.join(RAIZ, 'store/ficha-*.md'))):
    s = open(f, encoding='utf-8').read()
    t = re.findall(r'^<<<\n(.*?)\n>>>$', s, re.S | re.M)
    if len(t) != 3:
        print(f, ': hacen falta 3 textos, hay', len(t)); mal += 1; continue
    for x, tope, nom in zip(t, TOPE, ['título', 'corta', 'larga']):
        ok = len(x) <= tope and not MAL.search(x)
        print('%-12s %-6s %4d / %4d %s' % (os.path.basename(f), nom, len(x), tope, 'ok' if ok else 'MAL'))
        mal += not ok
    if not re.search(r'ficción|fiction', t[2]) or not re.search(r'18', t[2]):
        print(os.path.basename(f), ': falta el aviso (ficción, 18) en la larga'); mal += 1
print('fichas:', 'ok' if not mal else '%d fallos' % mal)
sys.exit(1 if mal else 0)

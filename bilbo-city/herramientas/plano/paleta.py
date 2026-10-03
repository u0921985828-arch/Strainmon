#!/usr/bin/env python3
"""Comprueba que la paleta es la misma en el HTML y en Unity.

Es la trampa de siempre con dos implementaciones, y con la paleta es de las peores: el
HTML pasa la batería, el C# no se ejecuta aquí, y Unity acaba cuantizando contra otra
lista. No sale ningún error — sale un juego con otros colores.

Compara los colores de familia y los apodos por separado, porque un apodo mal mapeado
(`negro` apuntando a un verde oscuro, por ejemplo) no cambia la lista de colores y sería
invisible mirando solo la paleta.

    python3 herramientas/plano/paleta.py
"""
import re, sys, pathlib

RAIZ = pathlib.Path(__file__).resolve().parents[2]
HTML = RAIZ / 'referencia' / 'bilbo-city.html'
CS   = RAIZ / 'unity' / 'BilboCity' / 'Assets' / 'Scripts' / 'Arte' / 'Paleta.cs'


def delHtml():
    s = HTML.read_text()
    i = s.index('const C={')
    familia = {n: h.lower() for n, h in
               re.findall(r"(\w+):'(#[0-9a-fA-F]{6})'", s[i:s.index('};', i)])}
    j = s.index('Object.assign(C,{', i)
    apodos = dict(re.findall(r'(\w+):C\.(\w+),', s[j:s.index('});', j)]))
    return familia, apodos


def delCs():
    s = CS.read_text()
    familia = {n[0].lower() + n[1:]: h.lower() for n, h in
               re.findall(r'Color32 (\w+)\s*= H\("(#[0-9a-fA-F]{6})"\);', s)}
    apodos = {n[0].lower() + n[1:]: d[0].lower() + d[1:] for n, d in
              re.findall(r'Color32 (\w+)\s*= (\w+);', s)}
    return familia, apodos


def compara(que, a, b):
    fuera = []
    for k in sorted(set(a) | set(b)):
        if k not in b:
            fuera.append('  falta en Unity: %s %s' % (que, k))
        elif k not in a:
            fuera.append('  sobra en Unity: %s %s' % (que, k))
        elif a[k] != b[k]:
            fuera.append('  no cuadra: %s %-11s HTML %s · Unity %s' % (que, k, a[k], b[k]))
    return fuera


def main():
    fh, ah = delHtml()
    fc, ac = delCs()
    if not fh:
        sys.exit('no encontré la paleta en %s' % HTML)
    problemas = compara('color', fh, fc) + compara('apodo', ah, ac)
    if problemas:
        print('\n'.join(problemas))
        sys.exit('la paleta no cuadra entre el HTML y Unity')
    print('%d colores y %d apodos cuadran entre el HTML y Unity' % (len(fh), len(ah)))


main()

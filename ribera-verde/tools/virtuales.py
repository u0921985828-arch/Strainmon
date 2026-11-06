#!/usr/bin/env python3
"""Los virtuales de la cadena de herencia de godot/src, anotados con dónde está la implementación.

  python3 -I tools/virtuales.py            anota cada stub con «# → <archivo>.gd» (no toca los que ya lo dicen)
  python3 -I tools/virtuales.py --check    sale 1 si algún stub no lo dice o apunta a un archivo sin implementación

Un «stub de cadena» es una función de cuerpo trivial (pass / return <constante>) en un archivo de la cadena que tiene una
implementación de verdad en otro archivo más abajo. Sin el rótulo, el bloque es una lista ciega de 1.080 líneas."""
import sys, os, re

R = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'godot', 'src')
TRIV = re.compile(r'^\t(pass|return (false|true|null|\[\]|\{\}|""|0|0\.0|-1))$')
FUNC = re.compile(r'^func ([a-zA-Z_][a-zA-Z0-9_]*)\(')


def cadena():
    """el orden de herencia, de la base al final, por los extends"""
    pad, hijos = {}, {}
    for f in os.listdir(R):
        if not f.endswith('.gd'):
            continue
        t = open(os.path.join(R, f), encoding='utf-8').read()
        m = re.search(r'^extends\s+"?res://src/([a-z_0-9]+)\.gd"?', t, re.M)
        if m:
            pad[f[:-3]] = m.group(1)
            hijos.setdefault(m.group(1), []).append(f[:-3])
    o, k = [], 'juego'   # el único concreto (juego.tscn → src/juego.gd); se sube por los extends y se da la vuelta
    while k:
        o.append(k)
        k = pad.get(k)
    o.reverse()
    return o


def funcs(mod):
    """nombre → [(línea, trivial)] de cada func del archivo"""
    L = open(os.path.join(R, mod + '.gd'), encoding='utf-8').read().split('\n')
    o = {}
    for i, l in enumerate(L):
        m = FUNC.match(l)
        if m:
            cuerpo = L[i + 1] if i + 1 < len(L) else ''
            o.setdefault(m.group(1), []).append((i, bool(TRIV.match(cuerpo))))
    return L, o


def main():
    chk = '--check' in sys.argv
    orden = cadena()
    if not orden:
        print('no veo la cadena de extends'); return 1
    tablas = {m: funcs(m) for m in orden}
    mal, puestos = [], 0
    for a, mod in enumerate(orden):
        L, F = tablas[mod]
        cambia = False
        for n, apar in F.items():
            for (i, triv) in apar:
                if not triv:
                    continue
                donde = next((o for o in orden[a + 1:] if any(not t for (_, t) in tablas[o][1].get(n, []))), None)
                if donde is None:
                    continue
                flecha = '→ %s.gd' % donde
                if flecha in L[i] or re.search(r'#.*\b%s\.gd' % donde, L[i]):
                    continue
                if chk:
                    mal.append('%s.gd:%d %s() → %s.gd' % (mod, i + 1, n, donde))
                    continue
                L[i] = L[i].rstrip() + ('   %s' % flecha if '#' in L[i] else '   # %s' % flecha)
                cambia, puestos = True, puestos + 1
        if cambia:
            open(os.path.join(R, mod + '.gd'), 'w', encoding='utf-8').write('\n'.join(L))
    if chk:
        for m in mal[:20]:
            print('SIN RÓTULO', m)
        print('stubs de cadena sin decir dónde está la implementación: %d' % len(mal))
        return 1 if mal else 0
    print('rótulos puestos: %d' % puestos)
    return 0


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""F8: parte un script GDScript en una cadena de herencia sin cambiar el comportamiento.
Uso: partir.py <src_dir> <base.gd> <plan.json>
plan.json: {"base": "trama", "modulos": [["venta", <primera línea>], ...]}  (las líneas, del archivo original, en orden)
Los miembros (var/const/static/signal/enum/class) y las funciones static se quedan en la base; cada función va al módulo cuyo
tramo la contiene. Lo que un archivo anterior de la cadena (o la base) llama y vive en uno posterior lleva un stub en la base
(salvo que ya lo declare un antepasado). El último módulo pasa a ser lo que extendía la base."""
import json, re, sys, os

src, base, plan = sys.argv[1], sys.argv[2], json.load(open(sys.argv[3]))
P = os.path.join(src, base + '.gd')
L = open(P).read().split('\n')
anc_files = plan.get('antepasados', [])   # los scripts de los que hereda la base (para no duplicar stubs)

# 1) bloques de nivel superior: cabecera (extends y lo de antes), y cada declaración con sus comentarios de encima
head_end = next(i for i, l in enumerate(L) if l.startswith('extends ')) + 1
blocks = []   # (inicio, fin, tipo, nombre)
i = head_end
prev = head_end
while i < len(L):
    l = L[i]
    if l.strip() == '' or l.startswith('#'):
        i += 1
        continue
    if l[0] in ' 	':
        raise SystemExit('línea indentada suelta en %d: %r' % (i + 1, l))
    s = prev
    while s < i and L[s].strip() == '':
        s += 1
    j = i + 1
    while j < len(L) and (L[j].strip() == '' or L[j][0] in ' 	' or L[j].startswith('#')):
        j += 1
    k = j
    while k > i + 1 and (L[k - 1].strip() == '' or L[k - 1].startswith('#')):
        k -= 1
    m = re.match(r'(static func|func)\s+(\w+)', l)
    if m:
        t = 'sfunc' if m.group(1) == 'static func' else 'func'
        blocks.append((s, k, t, m.group(2)))
    else:
        blocks.append((s, k, 'miembro', None))
    prev = k
    i = k
if prev < len(L) and any(x.strip() for x in L[prev:]):
    s0, e0, t0, n0 = blocks[-1]
    blocks[-1] = (s0, len(L), t0, n0)

mods = plan['modulos']
def modulo_de(line):
    q = plan['base']
    for a0, a1 in plan.get('base_tramos', []):
        if a0 <= line + 1 <= a1:
            return q
    for nom, ini in mods:
        if line + 1 >= ini:
            q = nom
    return q
def virtual(s, e):   # las que solo declaran (pass / return x): se quedan en la base, como los stubs de siempre
    c = [x.strip() for x in L[s:e] if x.strip() and not x.startswith('#') and not x.strip().startswith('#')]
    c = [x for x in c if not re.match(r'(static )?func\s', x)]
    return len(c) == 1 and (c[0] == 'pass' or re.match(r'return [^(]*$', c[0]) is not None)
cadena = [plan['base']] + [m[0] for m in mods]
asig = {}
cuerpo = {n: [] for n in cadena}
for b in blocks:
    s, e, t, n = b
    q = plan['base'] if t != 'func' or virtual(s, e) else modulo_de(s)
    if n:
        asig[n] = q
    cuerpo[q].append(b)

def texto(bs):
    out = []
    for s, e, t, n in bs:
        out.extend(L[s:e])
        out.append('')
    return out

# 2) stubs: funciones de un módulo posterior nombradas en uno anterior
def usa(bs):
    w = set()
    for s, e, t, n in bs:
        for l in L[s:e]:
            l2 = re.sub(r'#.*$', '', l) if '"' not in l else l
            w.update(re.findall(r'\b[A-Za-z_]\w*\b', l2))
    return w
anc = set()
for f in anc_files:
    for l in open(os.path.join(src, f + '.gd')):
        m = re.match(r'(?:static )?func\s+(\w+)', l)
        if m:
            anc.add(m.group(1))
pos = {n: k for k, n in enumerate(cadena)}
need = set()
for k, q in enumerate(cadena):
    w = usa(cuerpo[q])
    for n, qq in asig.items():
        if pos[qq] > k and n in w and n not in anc:
            need.add(n)

DEF = {'int': '0', 'float': '0.0', 'String': '""', 'bool': 'false', 'Array': '[]', 'Dictionary': '{}', 'Vector2': 'Vector2()',
       'Vector2i': 'Vector2i()', 'Color': 'Color()', 'Rect2': 'Rect2()', 'PackedStringArray': 'PackedStringArray()'}
stubs = []
for n in sorted(need):
    s, e, t, _ = next(b for b in blocks if b[3] == n and b[2] == 'func')
    j = next(x for x in range(s, e) if re.match(r'func\s', L[x]))
    sig = []
    while True:
        sig.append(L[j])
        if re.sub(r'#[^"]*$', '', L[j]).rstrip().endswith(':') and L[j].count('(') + sum(x.count('(') for x in sig[:-1]) <= L[j].count(')') + sum(x.count(')') for x in sig[:-1]):
            break
        j += 1
    sig_t = '\n'.join(sig)
    # nombres de parámetros sin usar: «_» delante para no avisar
    m = re.search(r'->\s*([\w\[\]]+)\s*:\s*$', re.sub(r'#[^"\n]*$', '', sig_t))
    ret = m.group(1) if m else None
    if ret is None or ret == 'void':
        body = '\tpass'
    elif ret.startswith('Array'):
        body = '\treturn []'
    elif ret.startswith('Dictionary'):
        body = '\treturn {}'
    else:
        body = '\treturn ' + DEF.get(ret, 'null')
    stubs.append('%s\n%s' % (sig_t, body))

ext0 = next(l for l in L[:head_end] if l.startswith('extends '))
for k, q in enumerate(cadena):
    if k == 0:
        out = L[:head_end] + [''] + texto(cuerpo[q])
        if stubs:
            out += ['# F8: lo que vive en los módulos de después de la cadena (%s), declarado aquí para quien lo llama antes' % ', '.join(cadena[1:])] + \
                   [x + '\n' for x in stubs]
    else:
        out = ['# ' + plan['desc'][q], 'extends "res://src/%s.gd"' % cadena[k - 1], ''] + texto(cuerpo[q])
    while out and out[-1] == '':
        out.pop()
    open(os.path.join(src, q + '.gd'), 'w').write('\n'.join(out) + '\n')
print('bloques', len(blocks), 'stubs', len(stubs), {q: sum(e - s for s, e, t, n in cuerpo[q]) for q in cadena})
print('ULTIMO', cadena[-1])

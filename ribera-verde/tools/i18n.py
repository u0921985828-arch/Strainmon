#!/usr/bin/env python3
"""F7: los textos de Landrace Hunters (godot/i18n/strings.csv: clave, es, en).
  python3 -I tools/i18n.py cuenta [-v]     literales que se ven fuera de T()/K()/v() en godot/src (tiene que dar 0)
  python3 -I tools/i18n.py extrae          rehace strings.csv con lo de T()/K()/v() y los textos de datos.json (guarda el en)
  python3 -I tools/i18n.py faltan          filas sin inglés
Un literal «se ve» si tiene una palabra de 2+ letras y un espacio, una mayúscula o una letra con tilde, y no es: clave de
diccionario o arm de match, subíndice, comparación (== != in), ruta, color, argumento de print/push_error/assert/get/has/
load/sfx… ni va en una línea con «# i18n-no» (lo interno que lo parece)."""
import sys, os, re, json, csv, zlib

R = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'godot')
SRC = os.path.join(R, 'src')
CSV = os.path.join(R, 'i18n', 'strings.csv')
OK_CALL = {'T', 'K', 'v', 'I18n.T', 'I18n.K', 'I18n.v', 'tr'}
NO_CALL = {'print', 'printerr', 'prints', 'push_error', 'push_warning', 'assert', 'get', 'has', 'erase', 'get_node', 'has_node',
           'has_method', 'call', 'callv', 'call_deferred', 'emit_signal', 'connect', 'load', 'preload', 'sfx', 'musica', 'is_action_pressed',
           'get_setting', 'set_setting', 'has_setting', 'find', 'begins_with', 'ends_with', 'contains', 'count', 'split', 'replace', 'trim_prefix',
           'trim_suffix', 'set_meta', 'get_meta', 'has_meta', 'RegEx.create_from_string', 'compile', 'Color', 'StringName', 'NodePath',
           'get_string', 'has_feature', 'parse_string', 'file_exists', 'open', 'globalize_path', 'remove_absolute', 'evento', 'logro_ok',
           'logro_play', 'set_shader_parameter', 'add_theme_color_override', 'add_theme_font_size_override', 'add_theme_constant_override',
           'add_theme_stylebox_override', 'add_theme_font_override', 'get_theme_font', 'sprite', 'spr', 'img', 'tex', 'flag', 'flags'}

def lex(src):
    """(valor, inicio, fin, línea) de cada literal de cadena, sin comentarios"""
    out, i, n, ln = [], 0, len(src), 1
    while i < n:
        c = src[i]
        if c == '\n':
            ln += 1; i += 1; continue
        if c == '#':
            while i < n and src[i] != '\n':
                i += 1
            continue
        if c in '"\'':
            q = src[i:i + 3] if src[i:i + 3] in ('"""', "'''") else c
            j = i + len(q); val = []; l0 = ln
            while j < n and src[j:j + len(q)] != q:
                if src[j] == '\\':
                    e = src[j + 1]
                    val.append({'n': '\n', 't': '\t', '"': '"', "'": "'", '\\': '\\'}.get(e, '\\' + e)); j += 2; continue
                if src[j] == '\n':
                    ln += 1
                val.append(src[j]); j += 1
            pre = src[i - 1] if i else ''
            if pre in '&^':   # StringName / NodePath
                i = j + len(q); continue
            out.append((''.join(val), i, j + len(q), l0))
            i = j + len(q); continue
        i += 1
    return out

def visible(s):
    if not re.search(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]{2}', s):
        return False
    if re.fullmatch(r'#?[0-9a-fA-F]{3,8}', s) or s.startswith(('res://', 'user://', 'http')):
        return False
    return bool(re.search(r'\s', s.strip()) or re.search(r'[A-ZÁÉÍÓÚÑ]', s) or re.search(r'[áéíóúüñ¿¡€]', s, re.I))

def llamada(src, a):
    """nombre de la llamada más cercana que encierra la posición a (o '')"""
    d = 0; i = a - 1
    while i >= 0:
        c = src[i]
        if c in ')]}':
            d += 1
        elif c in '([{':
            if d == 0:
                if c != '(':
                    return '' if c == '{' else '['
                m = re.search(r'([A-Za-z_][\w\.]*)\s*$', src[max(0, i - 80):i])
                return m.group(1) if m else ''
            d -= 1
        elif c == '\n' and d == 0 and not src[i + 1:a].lstrip().startswith(('"', "'")) and src[max(0, i - 1)] not in ',([{\\':
            pass
        i -= 1
    return ''

def literales(path):
    src = open(path, encoding='utf-8').read()
    lines = src.split('\n')
    res = []
    for s, a, b, ln in lex(src):
        if not visible(s):
            continue
        line = lines[ln - 1]
        if 'i18n-no' in line:
            continue
        antes = src[max(0, a - 12):a].rstrip()
        despues = src[b:b + 3].lstrip()
        if despues.startswith(':') and not despues.startswith(':='):
            continue   # clave de diccionario o arm de match
        if antes.endswith(('==', '!=', ' in', '\tin')) or despues.startswith(('==', '!=', ' in ', 'in ')):
            continue
        if antes.endswith('[') and despues.startswith(']'):
            continue
        f = llamada(src, a)
        base = f.split('.')[-1]
        if f in OK_CALL or base in ('T', 'K', 'v'):
            continue
        if f in NO_CALL or base in NO_CALL:
            continue
        if antes.endswith('%') and False:
            continue
        res.append((os.path.basename(path), ln, s))
    return res

def todos():
    r = []
    for f in sorted(os.listdir(SRC)):
        if f.endswith('.gd'):
            r += literales(os.path.join(SRC, f))
    return r

def marcados():
    """los literales de T()/K()/v(): lo que hay que traducir del código"""
    out = []
    for f in sorted(os.listdir(SRC)):
        if not f.endswith('.gd'):
            continue
        src = open(os.path.join(SRC, f), encoding='utf-8').read()
        for s, a, b, ln in lex(src):
            if not re.search(r'[A-Za-zÁÉÍÓÚÑáéíóúñ]{2}', s):
                continue
            fn = llamada(src, a)
            if fn in OK_CALL or fn.split('.')[-1] in ('T', 'K', 'v'):
                out.append(s)
            elif 'i18n-no' not in src.split('\n')[ln - 1]:
                # también los visibles aún sin marcar y los arms de match de los menús (las etiquetas en castellano)
                if visible(s):
                    out.append(s)
    return out

def hojas(v, out):
    if isinstance(v, dict):
        for k in v:
            hojas(v[k], out)
    elif isinstance(v, list):
        for x in v:
            hojas(x, out)
    elif isinstance(v, str) and visible(v):
        out.append(v)

def leer_csv():
    d = {}
    if os.path.exists(CSV):
        with open(CSV, encoding='utf-8', newline='') as f:
            for r in csv.reader(f):
                if len(r) >= 3 and r[0] != 'clave':
                    d[r[1]] = r[2]
    return d

def clave(s):
    return 's%08x' % zlib.crc32(s.encode('utf-8'))

def extrae(extra=()):
    en = leer_csv()
    ds = []
    hojas(json.load(open(os.path.join(R, 'datos', 'datos.json'), encoding='utf-8')), ds)
    pj = json.load(open(os.path.join(R, 'datos', 'play.json'), encoding='utf-8'))
    hojas(pj.get('set', {}), ds)
    hojas(list(pj.get('nombres', {}).values()), ds)
    todo = marcados() + ds + list(extra)
    vistos, filas = set(), []
    for s in todo:
        if s in vistos:
            continue
        vistos.add(s)
        filas.append((clave(s), s, en.get(s, '')))
    with open(CSV, 'w', encoding='utf-8', newline='') as f:
        w = csv.writer(f, lineterminator='\n')
        w.writerow(['clave', 'es', 'en'])
        w.writerows(filas)
    print('filas', len(filas), 'sin inglés', sum(1 for r in filas if not r[2]))

if __name__ == '__main__':
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'cuenta'
    if cmd == 'cuenta':
        r = todos()
        if '-v' in sys.argv:
            for f, ln, s in r:
                print('%s:%d: %r' % (f, ln, s[:90]))
        por = {}
        for f, ln, s in r:
            por[f] = por.get(f, 0) + 1
        print(json.dumps(por, ensure_ascii=False))
        print('literales visibles fuera de T/K/v:', len(r))
        sys.exit(1 if r else 0)
    elif cmd == 'extrae':
        extra = []
        if len(sys.argv) > 2:   # las variantes de PLAY (Datos.tp), de tests/i18n_tp.gd
            extra = json.load(open(sys.argv[2], encoding='utf-8'))
        extrae(extra)
    elif cmd == 'faltan':
        d = leer_csv()
        print(sum(1 for k in d if not d[k]))

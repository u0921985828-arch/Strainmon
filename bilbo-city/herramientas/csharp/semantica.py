#!/usr/bin/env python3
"""
Analizador semántico sobre el árbol de sintaxis real de C# (tree-sitter).
No es un compilador, pero construye la tabla de símbolos del proyecto y
verifica lo que más se rompe al portar: miembros que no existen, número de
argumentos, miembros de enum y tipos desconocidos.
"""
import pathlib, sys, collections, re
from tree_sitter import Language, Parser
import tree_sitter_c_sharp as tscs

LANG = Language(tscs.language())
P = Parser(LANG)
RAIZ = pathlib.Path(__file__).resolve().parents[2] / 'unity/BilboCity/Assets'

# ── tipos de Unity y del sistema que damos por buenos ──
EXTERNOS = {
 'Mathf','Vector2','Vector3','Vector2Int','Vector3Int','Color','Color32','Quaternion','Rect','Bounds','BoundsInt',
 'GameObject','Transform','Component','MonoBehaviour','ScriptableObject','Object','Debug','Time','Random','Input',
 'KeyCode','TouchPhase','Screen','Application','Camera','CameraClearFlags','Texture2D','TextureFormat','FilterMode',
 'TextureWrapMode','Sprite','SpriteRenderer','SpriteMeshType','Material','Shader','Resources','Font','Canvas',
 'CanvasScaler','GraphicRaycaster','RenderMode','Image','RawImage','Text','Button','ScrollRect','Mask','LayoutElement',
 'VerticalLayoutGroup','HorizontalLayoutGroup','ContentSizeFitter','RectTransform','TextAnchor','HorizontalWrapMode',
 'VerticalWrapMode','EventTrigger','EventTriggerType','EventSystem','StandaloneInputModule','AudioSource','AudioClip',
 'AudioListener','PlayerPrefs','JsonUtility','SceneManager','Grid','Tilemap','TilemapRenderer','Tile','TileBase',
 'QualitySettings','PlayerSettings','UIOrientation','EditorSceneManager','NewSceneSetup','NewSceneMode','AssetDatabase',
 'MenuItem','Convert','Math','System','Func','Action','List','Dictionary','Stack','Queue','HashSet','Array','String',
 'Mathf','IEnumerator','IEnumerable','Coroutine','WaitForSeconds','Destroy','Instantiate','LayerMask','Physics2D',
 'Renderer','Space','Application','SystemInfo','Screen','Handheld','Sleep','Gizmos','GUI','GUILayout','Vector4',
}
PRIMITIVOS = {'int','float','bool','string','char','byte','sbyte','short','ushort','uint','long','ulong','double',
              'decimal','object','void','var','dynamic','T'}

def txt(n, src): return src[n.start_byte:n.end_byte].decode('utf8','replace')

class Tipo:
    def __init__(s, nombre, clase, fichero):
        s.nombre, s.clase, s.fichero = nombre, clase, fichero
        s.base = None
        s.campos = {}        # nombre -> es_estatico
        s.props = {}
        s.metodos = collections.defaultdict(list)   # nombre -> [(min,max,estatico)]
        s.ctors = []         # [(min,max)]
        s.enum = set()
        s.tipo_campo = {}      # nombre de campo -> tipo de elemento si es List<X>

tipos = {}
fuentes = {}
arboles = {}

def hijo(n, t):
    for h in n.children:
        if h.type == t: return h
    return None

def nombre_de(n):
    """El campo 'name' es el bueno; el hijo 'identifier' suelto puede ser el tipo."""
    c = n.child_by_field_name('name')
    return c if c is not None else hijo(n, 'identifier')

def hijos(n, t):
    return [h for h in n.children if h.type == t]

def aridad(lista_param, src):
    """Devuelve (mínimo, máximo) contando parámetros con valor por defecto y params."""
    if lista_param is None: return (0,0)
    ps = [p for p in lista_param.children if p.type in ('parameter','_parameter')]
    total = len(ps)
    opcionales = 0
    variadico = False
    for p in ps:
        t = txt(p, src)
        if '=' in t: opcionales += 1
        if t.strip().startswith('params'): variadico = True
    return (total - opcionales, 999 if variadico else total)

def es_estatico(n, src):
    return any(txt(h,src) == 'static' for h in n.children if h.type == 'modifier')

def recolectar(n, src, fichero, contenedor=None):
    for h in n.children:
        t = h.type
        if t in ('class_declaration','struct_declaration','enum_declaration','interface_declaration','record_declaration'):
            nom_n = nombre_de(h)
            if nom_n is None: continue
            nombre = txt(nom_n, src)
            tp = Tipo(nombre, t.split('_')[0], fichero)
            bl = hijo(h,'base_list')
            if bl:
                for c in bl.children:
                    if c.type in ('identifier','generic_name','qualified_name'):
                        tp.base = txt(c,src).split('<')[0].split('.')[-1]
                        break
            if nombre in tipos:
                print(f"  FALLO  {nombre} declarado en {tipos[nombre].fichero} y en {fichero}")
            tipos[nombre] = tp
            if contenedor is not None:
                contenedor.campos[nombre] = True   # un tipo anidado se usa como Contenedor.Anidado
            cuerpo = hijo(h,'declaration_list') or hijo(h,'enum_member_declaration_list')
            if cuerpo:
                miembros(cuerpo, src, tp)
                recolectar(cuerpo, src, fichero, tp)
        else:
            recolectar(h, src, fichero, contenedor)

def miembros(cuerpo, src, tp):
    for m in cuerpo.children:
        t = m.type
        if t == 'enum_member_declaration':
            i = nombre_de(m)
            if i: tp.enum.add(txt(i,src))
        elif t == 'field_declaration':
            est = es_estatico(m, src) or any(txt(h,src)=='const' for h in m.children if h.type=='modifier')
            vd = hijo(m,'variable_declaration')
            if vd:
                tnode = vd.child_by_field_name('type')
                elem = None
                if tnode is not None:
                    mm = re.search(r'(?:List|Stack|Queue|HashSet)<\s*([\w\.]+)\s*>', txt(tnode, src))
                    if mm: elem = mm.group(1).split('.')[-1]
                for d in hijos(vd,'variable_declarator'):
                    i = nombre_de(d)
                    if i:
                        tp.campos[txt(i,src)] = est
                        if elem: tp.tipo_campo[txt(i,src)] = elem
        elif t == 'property_declaration':
            i = nombre_de(m)
            if i: tp.props[txt(i,src)] = es_estatico(m, src)
        elif t == 'method_declaration':
            i = nombre_de(m)
            pl = m.child_by_field_name('parameters') or hijo(m,'parameter_list')
            if i:
                mn, mx = aridad(pl, src)
                tp.metodos[txt(i,src)].append((mn, mx, es_estatico(m,src)))
        elif t == 'constructor_declaration':
            pl = m.child_by_field_name('parameters') or hijo(m,'parameter_list')
            tp.ctors.append(aridad(pl, src))
        elif t in ('class_declaration','struct_declaration','enum_declaration'):
            pass  # los anidados los recoge recolectar()

# ── carga ──
for f in sorted(RAIZ.rglob('*.cs')):
    src = f.read_bytes()
    fuentes[f] = src
    arboles[f] = P.parse(src)
    recolectar(arboles[f].root_node, src, f.name)

def buscar_miembro(nombre_tipo, miembro):
    """Sube por la jerarquía de herencia."""
    visto = set()
    n = nombre_tipo
    while n and n in tipos and n not in visto:
        visto.add(n)
        tp = tipos[n]
        if miembro in tp.campos or miembro in tp.props or miembro in tp.metodos or miembro in tp.enum:
            return tp
        n = tp.base
    return None

fallos = []

# ── comprobación de accesos y llamadas ──
for f, src in fuentes.items():
    def rec(n):
        if n.type == 'member_access_expression':
            obj = n.child_by_field_name('expression')
            nom = n.child_by_field_name('name')
            if obj is not None and nom is not None and nom.type == 'identifier':
                base = txt(obj, src)
                miembro = txt(nom, src)
                # A.B  donde A es uno de mis tipos -> acceso estático o a enum
                if base in tipos:
                    if not buscar_miembro(base, miembro):
                        fallos.append(f"{f.name}:{n.start_point[0]+1} {base}.{miembro} no existe")
                # A.I.B -> singleton
                elif base.endswith('.I'):
                    cls = base[:-2]
                    if cls in tipos and not buscar_miembro(cls, miembro):
                        fallos.append(f"{f.name}:{n.start_point[0]+1} {cls}.I.{miembro} no existe")
        if n.type == 'invocation_expression':
            fn = n.child_by_field_name('function')
            args = n.child_by_field_name('arguments')
            nargs = len([a for a in args.children if a.type == 'argument']) if args else 0
            if fn is not None and fn.type == 'member_access_expression':
                obj = fn.child_by_field_name('expression')
                nom = fn.child_by_field_name('name')
                if obj is not None and nom is not None:
                    base = txt(obj, src); met = txt(nom, src)
                    cls = base[:-2] if base.endswith('.I') else base
                    if cls in tipos:
                        prop = buscar_miembro(cls, met)
                        if prop and met in prop.metodos:
                            if not any(mn <= nargs <= mx for mn,mx,_ in prop.metodos[met]):
                                firmas = ', '.join(f"{mn}-{mx}" for mn,mx,_ in prop.metodos[met])
                                fallos.append(f"{f.name}:{n.start_point[0]+1} {cls}.{met}() con {nargs} args, admite {firmas}")
        if n.type == 'object_creation_expression':
            t = n.child_by_field_name('type')
            args = n.child_by_field_name('arguments')
            if t is not None:
                nom = txt(t, src).split('<')[0]
                if nom in tipos and args is not None:
                    nargs = len([a for a in args.children if a.type == 'argument'])
                    tp = tipos[nom]
                    if tp.ctors:
                        if not any(mn <= nargs <= mx for mn,mx in tp.ctors):
                            firmas = ', '.join(f"{mn}-{mx}" for mn,mx in tp.ctors)
                            fallos.append(f"{f.name}:{n.start_point[0]+1} new {nom}() con {nargs} args, admite {firmas}")
                    elif nargs > 0:
                        fallos.append(f"{f.name}:{n.start_point[0]+1} new {nom}({nargs} args) pero no tiene constructor")
        for h in n.children: rec(h)
    rec(arboles[f].root_node)

# ── tipos referenciados que no existen ──
conocidos = set(tipos) | EXTERNOS | PRIMITIVOS
for f, src in fuentes.items():
    def rec2(n):
        if n.type in ('variable_declaration','object_creation_expression'):
            t = n.child_by_field_name('type')
            if t is not None:
                nom = txt(t, src).split('<')[0].split('[')[0].split('.')[0].strip().rstrip('?')
                if nom and nom[0].isupper() and nom not in conocidos:
                    fallos.append(f"{f.name}:{n.start_point[0]+1} tipo desconocido '{nom}'")
        for h in n.children: rec2(h)
    rec2(arboles[f].root_node)

fallos = sorted(set(fallos))
for x in fallos: print("  FALLO  ", x)
metodos_tot = sum(len(t.metodos) for t in tipos.values())
campos_tot = sum(len(t.campos)+len(t.props) for t in tipos.values())
print(f"\n{len(tipos)} tipos · {metodos_tot} métodos · {campos_tot} campos y propiedades · {len(fallos)} fallos")

# ══════════════════════════════════════════════════════════════════
# Listas modificadas mientras se recorren. Es el fallo que más veces
# aparece al portar de JS a C#: en JS no pasa nada, en C# la excepción
# salta en el siguiente MoveNext.
# ══════════════════════════════════════════════════════════════════
MUTADORES = {'Add','Remove','RemoveAt','Clear','Insert','RemoveAll','AddRange','Sort'}
listas = set()
for t in tipos.values():
    for c in t.campos: listas.add(c)

elem_de = {}
for t in tipos.values():
    for k, v in t.tipo_campo.items(): elem_de[k] = v

def nombre_lista(n, src):
    t = txt(n, src).split('.')[-1].strip()
    return t if t in listas else None

# Los métodos se indexan por Tipo.Metodo: hay seis 'Tic' distintos en el proyecto
# y confundirlos daba falsos positivos.
muta = collections.defaultdict(set)

def tipo_contenedor(n, src):
    m = n.parent
    while m is not None:
        if m.type in ('class_declaration','struct_declaration'):
            nm = m.child_by_field_name('name')
            if nm is not None: return txt(nm, src)
        m = m.parent
    return None

def clave_metodo(n, src):
    nm = n.child_by_field_name('name')
    if nm is None: return None
    t = tipo_contenedor(n, src)
    return (t + '.' + txt(nm, src)) if t else None

def var_foreach(n, src):
    """Sube buscando foreach que declaren la variable, para saber su tipo."""
    binds = {}
    m = n
    while m is not None:
        if m.type == 'foreach_statement':
            izq = m.child_by_field_name('left')
            der = m.child_by_field_name('right')
            if izq is not None and der is not None:
                L = txt(der, src).split('.')[-1].strip()
                if L in elem_de: binds.setdefault(txt(izq, src).strip(), elem_de[L])
        m = m.parent
    return binds

def receptor(fn, src, aqui):
    """A qué tipo pertenece el método invocado, si se puede saber."""
    if fn.type != 'member_access_expression': return aqui
    obj = fn.child_by_field_name('expression')
    if obj is None: return aqui
    base = txt(obj, src).strip()
    b = var_foreach(fn, src)
    if base in b: return b[base]
    if base.endswith('.I'): base = base[:-2]
    if base in tipos: return base
    # variables cuyo tipo conocemos por convención del proyecto
    for var, tp in (('J','Juego'), ('Juego.I','Juego'), ('this','')):
        if base == var: return tp or aqui
    return None

for f, src in fuentes.items():
    def rec3(n, actual=None):
        if n.type in ('method_declaration','constructor_declaration'):
            actual = clave_metodo(n, src) or actual
        if n.type == 'invocation_expression' and actual:
            fn = n.child_by_field_name('function')
            if fn is not None and fn.type == 'member_access_expression':
                nom = fn.child_by_field_name('name')
                obj = fn.child_by_field_name('expression')
                if nom is not None and txt(nom,src) in MUTADORES and obj is not None:
                    L = nombre_lista(obj, src)
                    if L: muta[actual].add(L)
        for h in n.children: rec3(h, actual)
    rec3(arboles[f].root_node)

def llamadas_de(n, src, aqui):
    """Claves Tipo.Metodo a las que llama este nodo."""
    fuera = []
    fn = n.child_by_field_name('function')
    if fn is None: return fuera
    if fn.type == 'member_access_expression':
        nom = fn.child_by_field_name('name')
        if nom is None: return fuera
        r = receptor(fn, src, aqui)
        met = txt(nom, src)
        if r: fuera.append(r + '.' + met)
        else: fuera += [k for k in muta if k.endswith('.' + met)]
    elif fn.type == 'identifier' and aqui:
        fuera.append(aqui.split('.')[0] + '.' + txt(fn, src))
    return fuera

for _ in range(4):
    for f, src in fuentes.items():
        def rec4(n, actual=None):
            if n.type in ('method_declaration','constructor_declaration'):
                actual = clave_metodo(n, src) or actual
            if n.type == 'invocation_expression' and actual:
                aqui = actual.split('.')[0]
                for k in llamadas_de(n, src, aqui):
                    if k in muta: muta[actual] |= muta[k]
            for h in n.children: rec4(h, actual)
        rec4(arboles[f].root_node)

sospechas = []
for f, src in fuentes.items():
    def rec5(n):
        if n.type == 'foreach_statement':
            col = n.child_by_field_name('right')
            cuerpo = n.child_by_field_name('body')
            L = nombre_lista(col, src) if col is not None else None
            aqui = tipo_contenedor(n, src)
            if L and cuerpo is not None:
                peligro, sale = set(), False
                def rec6(m):
                    nonlocal sale
                    # break y return sacan del bucle antes del siguiente MoveNext
                    if m.type in ('break_statement','return_statement'): sale = True
                    if m.type == 'invocation_expression':
                        fn = m.child_by_field_name('function')
                        if fn is not None and fn.type == 'member_access_expression':
                            nom = fn.child_by_field_name('name')
                            if nom is not None and txt(nom,src) in MUTADORES:
                                obj = fn.child_by_field_name('expression')
                                if obj is not None and nombre_lista(obj, src) == L:
                                    peligro.add(txt(nom,src))
                        for k in llamadas_de(m, src, aqui):
                            if k in muta and L in muta[k]: peligro.add(k + '()')
                    for h in m.children: rec6(h)
                rec6(cuerpo)
                if peligro:
                    marca = "sale con break/return" if sale else "SIN SALIDA"
                    sospechas.append(f"{f.name}:{n.start_point[0]+1} foreach sobre {L} llama a "
                                     f"{', '.join(sorted(peligro))} ({marca})")
        for h in n.children: rec5(h)
    rec5(arboles[f].root_node)

if sospechas:
    print("\n── listas tocadas mientras se recorren ──")
    for x in sorted(set(sospechas)):
        print(("  FALLO   " if "SIN SALIDA" in x else "  ok      ") + x)
    if [x for x in sospechas if "SIN SALIDA" in x]:
        sys.exit(1)

sys.exit(1 if fallos else 0)

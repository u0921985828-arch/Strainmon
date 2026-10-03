import pathlib, sys
from tree_sitter import Language, Parser
import tree_sitter_c_sharp as tscs

LANG = Language(tscs.language())
P = Parser(LANG)
raiz = pathlib.Path(__file__).resolve().parents[2] / 'unity/BilboCity/Assets'
malos = 0
for f in sorted(raiz.rglob('*.cs')):
    data = f.read_bytes()
    arbol = P.parse(data)
    errores = []
    def rec(n):
        if n.type == 'ERROR' or n.is_missing:
            errores.append((n.start_point[0]+1, n.type,
                            data[n.start_byte:min(n.end_byte, n.start_byte+70)].decode('utf8','replace')))
        for h in n.children: rec(h)
    rec(arbol.root_node)
    if errores:
        malos += 1
        print(f"\n{f.name}")
        for ln, t, txt in errores[:8]:
            print(f"   linea {ln}: {t} -> {txt.strip()[:66]!r}")
print(f"\n{'TODOS LOS FICHEROS PARSEAN' if not malos else str(malos)+' ficheros con errores de sintaxis'}")
sys.exit(1 if malos else 0)

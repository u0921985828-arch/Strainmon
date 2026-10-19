#!/usr/bin/env python3
"""Contador de MODO ABSOLUTO. Estado en .modo-absoluto/ del proyecto (plan.json, ultimo.json).

  ma.py init  ID:nombre:peso[:m] ...           declara el plan (una vez; las unidades no cambian)
  ma.py set   ID N [ID N ...]                  marca n de m tras comprobarlo y emite si el % sube
  ma.py emit                                   linea de avance; exit 1 y nada si el % no sube
  ma.py imprevisto ID:nombre:peso[:m] MIN "motivo"   suma trabajo a la vista (el % puede bajar)
  ma.py esperando "texto"                      (trabajando · esperando texto · faltan N subtareas), sin %
  ma.py next                                   tras compactar: %, siguiente subtarea, pendientes
  ma.py tabla                                  subtarea · peso · % del total · hecho n/m · aporta
  ma.py on | off                               activa o desactiva el recordatorio por turno
  ma.py hook-start | hook-prompt | hook-precompact   para los hooks
"""
import json, math, os, shutil, sys, time

D = os.environ.get("MA_DIR", ".modo-absoluto")
P = os.path.join(D, "plan.json")
U = os.path.join(D, "ultimo.json")


def load(f, default=None):
    try:
        with open(f, encoding="utf-8") as h:
            return json.load(h)
    except FileNotFoundError:
        return default


def save(f, d):
    os.makedirs(D, exist_ok=True)
    tmp = f + ".tmp"
    with open(tmp, "w", encoding="utf-8") as h:
        json.dump(d, h, ensure_ascii=False, indent=1)
    os.replace(tmp, f)


def die(msg, code=2):
    print(msg, file=sys.stderr)
    sys.exit(code)


def parse(spec):
    p = spec.split(":")
    if len(p) not in (3, 4):
        die(f"formato ID:nombre:peso[:m] -> {spec}")
    sid, nombre, peso = p[0].strip(), p[1].strip(), float(p[2])
    m = float(p[3]) if len(p) == 4 else 1.0
    if not 1 <= peso <= 4:
        die(f"{sid}: peso {peso:g} fuera de 1-4; parte la subtarea")
    if m <= 0:
        die(f"{sid}: m debe ser > 0")
    return {"id": sid, "nombre": nombre, "peso": peso, "n": 0.0, "m": m}


def plan():
    d = load(P)
    if d is None:
        die("sin plan: usa ma.py init")
    return d


def total(d):
    return sum(s["peso"] for s in d)


def exacto(d):
    t = total(d)
    return 100.0 * sum(s["peso"] * s["n"] / s["m"] for s in d) / t if t else 0.0


def piso(x):
    return math.floor(x * 10 + 1e-9) / 10


def fmt(x):
    return f"{x:.1f}"


def nm(s):
    return f"{s['n']:g}/{s['m']:g}"


def ult():
    u = load(U, {"pct": None, "exacto": 0.0, "n": {}, "total": None})
    u.setdefault("vistos", [] if u["pct"] is None else [u["pct"]])
    return u


def snap(d, pct, vistos):
    save(U, {"pct": pct, "exacto": exacto(d), "n": {s["id"]: s["n"] for s in d},
             "total": total(d), "vistos": sorted(set(vistos) | {pct})})


def cmd_init(args):
    if os.path.exists(P):
        die("ya hay plan: las unidades no se cambian a mitad; lo nuevo va por 'imprevisto'")
    d = [parse(a) for a in args]
    ids = [s["id"] for s in d]
    if len(set(ids)) != len(ids):
        die("IDs repetidos")
    t = total(d)
    gordas = [s["id"] for s in d if s["peso"] / t > 0.2]
    if gordas:
        die("subtareas >20 % del total, pártelas: " + ", ".join(gordas))
    save(P, d)
    cmd_tabla([])


def cmd_set(args):
    if not args or len(args) % 2:
        die("uso: set ID N [ID N ...]")
    d = plan()
    for sid, val in zip(args[::2], args[1::2]):
        s = next((x for x in d if x["id"] == sid), None)
        if s is None:
            die(f"ID desconocido: {sid} (existentes: {', '.join(x['id'] for x in d)})")
        n = float(val)
        if not 0 <= n <= s["m"]:
            die(f"{s['id']}: N={n:g} fuera de 0..{s['m']:g}")
        if n < s["n"]:
            print(f"{s['id']} baja de {nm(s)} a {n:g}/{s['m']:g}: dilo en el cierre", file=sys.stderr)
        s["n"] = n
    save(P, d)
    cmd_emit([], quiet=True)


def reparto(d, u, salto):
    """Aporte de cada subtarea, en décimas, que suma exactamente el salto mostrado."""
    t = total(d)
    raw = []
    for s in d:
        prev = u["n"].get(s["id"], 0.0)
        if s["n"] != prev:
            raw.append((s, 1000.0 * s["peso"] * (s["n"] - prev) / s["m"] / t))
    base = [math.floor(r + 1e-9) for _, r in raw]
    resto = round(salto * 10) - sum(base)
    orden = sorted(range(len(raw)), key=lambda i: raw[i][1] - base[i], reverse=True)
    for i in orden[: max(resto, 0)]:
        base[i] += 1
    return [(s, b / 10) for (s, _), b in zip(raw, base) if b]


def cmd_emit(args, quiet=False):
    d, u = plan(), ult()
    v = piso(exacto(d))
    prev = u["pct"]
    if (prev is not None and v <= prev) or v in u["vistos"]:
        if quiet:
            return
        sys.exit(1)
    salto = v - (prev if prev is not None else 0.0)
    partes = reparto(d, u, salto)
    extra = " · ".join(f"{s['nombre']} {nm(s)} {a:+.1f}" for s, a in partes)
    snap(d, v, u["vistos"])
    print(f"(trabajando · {fmt(v)} %" + (f" · {extra}" if extra else "") + ")")


def cmd_imprevisto(args):
    if len(args) != 3:
        die('uso: imprevisto ID:nombre:peso[:m] MIN "motivo"')
    d = plan()
    s = parse(args[0])
    if any(x["id"] == s["id"] for x in d):
        die(f"ID ya existe: {s['id']}")
    u = ult()
    antes = piso(exacto(d)) if u["pct"] is None else u["pct"]
    d.append(s)
    save(P, d)
    v = piso(exacto(d))
    motivo = " ".join(args[2].split()[:6])
    if v in u["vistos"]:
        snap(d, u["pct"], u["vistos"])  # ya salió: no se repite; la próxima subida lo enseña
        u2 = load(U); u2["pct"] = v; save(U, u2)
        print(f"(trabajando · imprevisto +{args[1]} min: {motivo})")
        return
    snap(d, v, u["vistos"])
    print(f"(trabajando · {fmt(v)} % ({v-antes:+.1f}) · +{args[1]} min: {motivo})".replace("-", "−", 1) if v < antes
          else f"(trabajando · {fmt(v)} % · +{args[1]} min: {motivo})")


def cmd_esperando(args):
    d = load(P)
    faltan = sum(1 for s in d if s["n"] < s["m"]) if d else 0
    print(f"(trabajando · esperando {' '.join(args)}" + (f" · faltan {faltan} subtareas" if faltan else "") + ")")


def cmd_next(args):
    d, u = plan(), ult()
    pend = [s for s in d if s["n"] < s["m"]]
    print(f"Progreso calculado: {fmt(piso(exacto(d)))} % (última línea emitida: "
          + (f"{fmt(u['pct'])} %" if u["pct"] is not None else "ninguna") + ")")
    if not pend:
        print("Todas las subtareas hechas: verificación final y bloque de cierre.")
        return
    s = pend[0]
    print(f"Siguiente: {s['id']} {s['nombre']} {nm(s)}")
    if len(pend) > 1:
        print("Después: " + "; ".join(f"{x['id']} {x['nombre']} {nm(x)}" for x in pend[1:]))
    if os.path.exists("ESTADO.md"):
        print("Hay ESTADO.md: léelo para caminos cerrados y desvíos.")
    print("No escribas ningún % a mano: la próxima línea la saca `ma.py set`.")


def cmd_tabla(args):
    d = plan()
    t = total(d)
    print("subtarea · peso · % del total · hecho · aporta")
    for s in d:
        print(f"{s['id']} {s['nombre']} · {s['peso']:g} · {fmt(100*s['peso']/t)} · "
              f"{nm(s)} · {fmt(100*s['peso']*s['n']/s['m']/t)}")
    print(f"TOTAL · {t:g} · 100.0 · · {fmt(piso(exacto(d)))}")


def cmd_hook_start(args):
    partes = []
    if os.path.exists("ESTADO.md"):
        with open("ESTADO.md", encoding="utf-8") as h:
            txt = h.read()
        partes.append("ESTADO.md del proyecto (estado guardado de una tarea en curso):\n" + txt[:8000])
    if os.path.exists(P):
        import io, contextlib
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            cmd_next([])
        partes.append(buf.getvalue().strip())
    if os.path.exists(ON):
        partes.insert(0, recordatorio())
    if partes:
        partes.append(f"El contador de modo absoluto está en {os.path.abspath(__file__)}.")
        print("\n\n".join(partes))


ON = os.path.join(D, "ON")
RECORDATORIO = """Modo absoluto activo en este proyecto (protocolo completo: skill modo-absoluto, .claude/skills/modo-absoluto/SKILL.md). Si ese skill no está cargado en esta sesión, se carga antes de responder.
Reglas de este turno:
- Entre llamadas a herramientas no se escribe texto. Ni anuncios, ni «voy a», ni resultados parciales, ni resúmenes.
- La única línea permitida mientras se trabaja es la que imprime ma.py (set, imprevisto, esperando). Ningún porcentaje se escribe a mano ni se repite.
- Tareas largas: plan con ma.py init al empezar; ma.py set al comprobar cada subtarea; tras compactar, ma.py next.
- Pregunta de Eddie: respuesta en 1-3 líneas y se sigue. Dato que falta: formato ❓.
- Cierre: solo el bloque ✅ COMPLETADO (o 📦 ENTREGA PARCIAL), sin texto antes ni después. Todo en español.
Contador: {ma}"""


def recordatorio():
    return RECORDATORIO.format(ma=os.path.abspath(__file__))


def cmd_hook_prompt(args):
    import re
    try:
        prompt = json.load(sys.stdin).get("prompt", "")
    except Exception:
        prompt = ""
    p = prompt.lower()
    if re.search(r"modo\s+normal", p):
        if os.path.exists(ON):
            os.remove(ON)
        print("Modo absoluto desactivado: vuelve el modo normal.")
        return
    if re.search(r"modo[\s-]+absoluto|/modo-absoluto|sin narrar|solo el completado", p):
        os.makedirs(D, exist_ok=True)
        open(ON, "w").close()
    if os.path.exists(ON):
        print(recordatorio())


def cmd_on(args):
    os.makedirs(D, exist_ok=True)
    open(ON, "w").close()


def cmd_off(args):
    if os.path.exists(ON):
        os.remove(ON)


def cmd_hook_precompact(args):
    fuentes = [f for f in ("ESTADO.md", P) if os.path.exists(f)]
    if not fuentes:
        return
    dst = os.path.join(D, "snap", time.strftime("%Y%m%d-%H%M%S"))
    os.makedirs(dst, exist_ok=True)
    for f in fuentes:
        shutil.copy2(f, dst)
    raiz = os.path.join(D, "snap")
    for viejo in sorted(os.listdir(raiz))[:-5]:
        shutil.rmtree(os.path.join(raiz, viejo), ignore_errors=True)


CMDS = {"init": cmd_init, "set": cmd_set, "emit": cmd_emit, "imprevisto": cmd_imprevisto,
        "esperando": cmd_esperando, "tabla": cmd_tabla, "next": cmd_next,
        "hook-start": cmd_hook_start, "hook-precompact": cmd_hook_precompact,
        "hook-prompt": cmd_hook_prompt, "on": cmd_on, "off": cmd_off}

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] not in CMDS:
        die(__doc__)
    if sys.argv[1].startswith("hook-") and os.environ.get("CLAUDE_PROJECT_DIR"):
        os.chdir(os.environ["CLAUDE_PROJECT_DIR"])
    try:
        CMDS[sys.argv[1]](sys.argv[2:])
    except SystemExit:
        raise
    except Exception as e:
        if sys.argv[1].startswith("hook-"):
            sys.exit(0)  # un hook nunca debe romper la sesión
        die(f"error: {e}")

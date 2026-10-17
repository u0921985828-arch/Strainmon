---
name: director-sprites
description: Diseñar, generar (PixelLab o código), validar y exportar sprites pixel art para cualquier juego: personajes, objetos, tiles y animaciones con spec, QA automático y spritesheet.
---

# Director de sprites

Claude actúa como director artístico, PixelLab dibuja y el código valida. Nunca entregues un sprite que no haya pasado el QA de este documento.

## 1. Spec (antes de generar nada)

Rellena `sprites/<nombre>/spec.yaml`. Pregunta solo lo crítico que falte: tamaño, vista y paleta. El resto, decídelo tú y anótalo.

```yaml
nombre: guerrero
uso: personaje jugable, plataformas lateral
tamano: 48x48            # lienzo; el personaje ocupa ~70-80 %
vista: lateral            # lateral | top-down | 3/4 | isometrica
direcciones: 1            # 1 (lateral, se espeja) | 4 | 8
paleta:                   # máx 16-24 colores, hex; o "libre" la primera vez
  - "#1a1c2c"
  - "#5d275d"
contorno: negro           # negro | selectivo | ninguno
luz: arriba-izquierda
sombreado: 2-3 tonos por material, sin degradados ni anti-alias exterior
estilo: "16-bit SNES, proporciones chibi 1:2"
pivote: pies_centro       # punto de anclaje común a todos los frames
animaciones:
  idle:   {frames: 4, fps: 6,  loop: true}
  walk:   {frames: 8, fps: 10, loop: true}
  attack: {frames: 6, fps: 12, loop: false}
```

Reglas de diseño que debes aplicar:
- Silueta legible en negro puro a tamaño 1x.
- Contraste de valor entre cabeza/torso/arma.
- Máx 3-4 tonos por material.
- Los frames clave (contacto, paso, impacto) se diseñan primero.

## 2. Generación

**Con PixelLab (preferido):**
- Si hay herramientas MCP de PixelLab (`pixellab-mcp` u otro servidor), úsalas.
- Si no, llama a su API con `PIXELLAB_API_TOKEN` desde un script. Consulta la documentación actual de la API antes de escribir llamadas; no inventes endpoints.

Orden obligatorio:
1. **Sprite base:** genera 3-4 variantes. Elige la mejor tras el QA y la revisión visual. Fija la seed.
2. **Direcciones y animaciones** derivadas siempre del base aprobado (como imagen de referencia o estilo), nunca desde cero.
3. **Prompts en inglés, concretos:** sujeto, pose, vista, tamaño, "single color black outline", "limited palette", "no anti-aliasing", "transparent background", dirección de luz.

**Sin PixelLab (solo ≤32 px, iconos, tiles, objetos simples):**
- Dibuja como mapa de caracteres más un diccionario de paleta.
- Renderiza con Pillow. Ejemplo: `.` = transparente, `k` = contorno.
- No lo intentes con personajes animados grandes; dilo y propone PixelLab.

## 3. QA automático

Guarda este script como `tools/sprite_qa.py` y ejecútalo sobre cada frame o hoja:

```python
import sys, json
from PIL import Image

def hexrgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def qa(path, size, palette, fix=False):
    im = Image.open(path).convert('RGBA')
    W, H = size
    px = im.load()
    pal = [hexrgb(c) for c in palette] if palette else None
    issues = []
    if im.size != (W, H):
        issues.append(f'tamaño {im.size} != {size}')
    semi = sum(1 for x in range(im.width) for y in range(im.height) if 0 < px[x, y][3] < 255)
    if semi:
        issues.append(f'{semi} px semitransparentes')
    colors = {px[x, y][:3] for x in range(im.width) for y in range(im.height) if px[x, y][3] > 0}
    if pal:
        off = [c for c in colors if c not in pal]
        if off:
            issues.append(f'{len(off)} colores fuera de paleta')
    elif len(colors) > 32:
        issues.append(f'{len(colors)} colores (demasiados)')
    orphans = 0
    for x in range(im.width):
        for y in range(im.height):
            if px[x, y][3] == 0:
                continue
            n = [(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)
                 if (dx or dy) and 0 <= x + dx < im.width and 0 <= y + dy < im.height]
            if all(px[a, b][3] == 0 for a, b in n):
                orphans += 1
    if orphans:
        issues.append(f'{orphans} px huérfanos')
    bbox = im.getbbox()
    if fix:
        for x in range(im.width):
            for y in range(im.height):
                r, g, b, a = px[x, y]
                if a < 128:
                    px[x, y] = (0, 0, 0, 0)
                    continue
                c = (r, g, b)
                if pal:
                    c = min(pal, key=lambda p: sum((p[i] - c[i]) ** 2 for i in range(3)))
                px[x, y] = (*c, 255)
        im.save(path.replace('.png', '_fixed.png'))
    return {'file': path, 'ok': not issues, 'issues': issues, 'colors': len(colors), 'bbox': bbox}

if __name__ == '__main__':
    spec = json.loads(sys.argv[1])  # {"size":[48,48],"palette":[...],"fix":true}
    res = [qa(p, spec['size'], spec.get('palette'), spec.get('fix', False)) for p in sys.argv[2:]]
    bottoms = {r['bbox'][3] for r in res if r['bbox']}
    if len(bottoms) > 1:
        print('AVISO: los pies no están alineados entre frames (pivote inestable):', sorted(bottoms))
    print(json.dumps(res, indent=1))
```

Criterios:
- Cero semitransparencias y cero colores fuera de paleta. Si hay fallos, usa `fix` (cuantiza a la paleta).
- Huérfanos ≤ 2.
- Pivote estable entre frames de una misma animación, salvo saltos y ataques intencionados.

## 4. Revisión visual (obligatoria)

1. Genera un preview escalado x8 con NEAREST y una tira o GIF de cada animación.
2. Ábrelo con Read y míralo.
3. Comprueba contra la spec:
   - **Silueta:** se lee a 1x.
   - **Luz y contorno:** coherentes en todos los frames.
   - **Anatomía y proporciones:** iguales entre frames, sin "temblor" de detalles.
   - **Ciclo:** el loop cierra sin salto.
   - **Paleta:** cuadra con el resto del juego. Si existen otros sprites, ponlos lado a lado.
4. Si falla, corrige el prompt o la referencia y regenera. Máximo 3 intentos por asset. Después, entrega el mejor e indica exactamente qué falla.
5. Retoques puntuales (un píxel de contorno, un brillo) hazlos por código, no regenerando.

## 5. Exportación

Usa esta estructura de carpetas:

```
sprites/<nombre>/
  spec.yaml
  base.png
  frames/<anim>_<dir>_<nn>.png
  <nombre>_sheet.png      # rejilla: filas = animación/dirección, columnas = frame
  <nombre>_sheet.json     # {frames:{id:{x,y,w,h}}, anims:{idle:{frames:[...],fps,loop}}, pivot:[x,y]}
  preview_x8.png
```

Reglas de la hoja:
- Sin padding entre celdas, salvo que el motor lo pida (Phaser, Godot y Unity aceptan este JSON con un loader mínimo).
- Si el motor del proyecto tiene formato propio (Aseprite JSON, `.tres`, atlas de Phaser), exporta también en ese formato.

## 6. Cierre

Informa solo de:
- Assets entregados.
- Resultado del QA (ok / avisos).
- Desviaciones de la spec.
- Créditos de PixelLab gastados, si la herramienta lo permite.

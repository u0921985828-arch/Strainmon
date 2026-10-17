# QA de sprites (director de sprites): semitransparencias, colores fuera de paleta, píxeles huérfanos, tamaño y pivote
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

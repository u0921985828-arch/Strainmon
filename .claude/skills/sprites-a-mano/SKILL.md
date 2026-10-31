---
name: sprites-a-mano
description: Dibujar sprites y animaciones de pixel art por código, sin PixelLab ni ningún generador: Python 3 + Pillow, píxel a píxel, con paleta cerrada, contorno, luz fija, QA automático y hoja de sprites. Úsalo cuando se pida arte, sprites, tiles, iconos, muebles, personajes o animaciones y no haya PixelLab, no haya crédito, no haya red, o se pida expresamente hacerlo a mano o por código.
argument-hint: "[nombre del sprite | tanda | revisar <png>]"
allowed-tools:
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - Bash(python3 *)
  - Bash(node *)
  - Bash(ls *)
  - Bash(mkdir *)
---

# Sprites a mano (sin PixelLab)

Aquí el que dibuja es el código, no un modelo. Cada píxel se pone a propósito, con un
motivo que se puede leer en el script. Nada se escala, nada se suaviza, nada se genera
y se retoca después: el script es la obra y se vuelve a ejecutar cuantas veces haga falta.

Regla primera: **un sprite que no ha pasado el QA de la sección 5 no se entrega.**

## 0. Cuándo vale este método y cuándo no

Vale, y es mejor que un generador, para:

- objetos, muebles, máquinas, cacharros, vehículos de juguete, plantas, comida;
- tiles, firmes, suelos, paredes, orillas, vallas, mosaicos, texturas por ruido;
- iconos, marcos, barras, botones, letras de 3 × 5 y 5 × 7;
- planos de detalle (manos, herramientas, una acción de cerca);
- variantes de algo que ya existe: recolorear, alargar filas, espejar, recortar.

No vale, o cuesta diez veces más de lo que rinde:

- personajes de cuerpo entero con cara, en 4 u 8 direcciones y varias animaciones;
- retratos con expresión;
- escenas con perspectiva libre o mucha materia orgánica irregular.

Para eso: dilo en una línea y propón otra vía (un generador, o partir el trabajo en
piezas que sí se dibujan a mano: cabeza por dirección, cuerpo por partes, recolor).

## 1. Ficha antes de dibujar

Antes de la primera línea de código, escribe en la cabecera del script (comentario, no
un archivo aparte) la ficha del sprite. Sin ficha no se dibuja:

```python
# <nombre>.py  ·  python3 -I <ruta>/<nombre>.py   (Python 3 + Pillow)
# Qué es y por qué: una frase. Si lo pidió alguien, su petición entre comillas.
#  · <id del sprite> (celda <w> × <h>, ancla (<ax>, <ay>)): qué se ve, de qué tamaño real,
#    desde qué vista, con qué piezas.
# Escala: <n> px = 1 m (o: el objeto mide <x> cm de alto → <h> px).
# Vista: alzado recto | 3/4 de frente | desde arriba a medio fondo | perfil.
# Luz: de arriba a la izquierda (siempre la misma en todo el juego).
# Paleta: los <n> colores de abajo, ninguno más.
# Sale a <ruta de salida>.
```

Decide tú lo que no sea crítico y anótalo. Pregunta solo si sin el dato el sprite sale
mal de raíz: **tamaño de la celda, vista y escala**. Todo lo demás se decide y se apunta.

## 2. Las seis reglas del dibujo

1. **Alfa binario.** Un píxel está o no está: alfa 0 o 255. Ni una semitransparencia.
   El suavizado de bordes es el error número uno de quien viene de dibujar en grande.
2. **Paleta cerrada.** De 8 a 24 colores por sprite, de 3 a 4 tonos por material
   (sombra, base, luz y, como mucho, un brillo). Los tonos de un material salen del
   mismo color movido en luz y saturación, no de tres colores sueltos. Si el proyecto
   ya tiene paleta, se usa esa y no se inventa ninguno.
3. **Contorno.** Uno solo, oscuro y del mismo color en todo el juego (en un proyecto que
   ya lo tenga, el suyo). Contorno selectivo (solo donde el objeto da al fondo) si el
   estilo lo pide; nunca contorno claro por un lado y oscuro por otro sin motivo.
4. **Luz fija.** Siempre desde el mismo sitio (de arriba a la izquierda, salvo que el
   proyecto diga otra cosa): la luz arriba y a la izquierda de cada volumen, la sombra
   abajo y a la derecha, y la sombra propia bajo el objeto.
5. **Escala real.** Primero se mide el objeto de verdad (en cm) y se traduce a píxeles
   con la escala del juego. Un mostrador de 100 cm a 16 px/m son 16 px de alto: se
   dibuja de 16, no «de lo que parezca bien».
6. **Silueta antes que detalle.** Lo primero que se dibuja es la forma en un solo color;
   si en negro puro a 1× no se reconoce, no hay detalle que lo salve. El detalle entra
   después y siempre dentro de la silueta.

## 3. Herramienta: el lienzo

Todo el dibujo se hace con un módulo de lienzo mínimo, que es lo único que se importa.
Este repositorio ya trae uno probado: `ribera-verde/tools/sprites/a-mano/lienzo.py`.
En un proyecto que no lo tenga, copia `scripts/lienzo.py` de esta skill.

Da lo justo y nada más, que es lo que mantiene el estilo:

| llamada | qué hace |
| --- | --- |
| `L = Lienzo(w, h)` | lienzo RGBA vacío |
| `L.p(x, y, c)` | un píxel (`c` = `'#rrggbb'` o `None` para no pintar) |
| `L.g(x, y)`, `L.lleno(x, y)` | leer el píxel, saber si tiene algo |
| `L.r(x, y, w, h, c)` | rectángulo macizo |
| `L.hl(x0, x1, y, c)`, `L.vl(x, y0, y1, c)` | línea recta |
| `L.caja(x, y, w, h, fondo, borde)` | caja con su borde |
| `L.contorno(c)` | contorno de un píxel alrededor de lo pintado |
| `L.pega(otro, ox, oy)` | pegar otro lienzo encima |
| `L.espejo()`, `L.recorta(x, y, w, h)` | voltear, recortar |
| `L.cambia({'#aaa': '#bbb'})` | recolorear exacto (variantes, ropa, estilos) |
| `L.colores()` | los colores usados: para el QA |
| `L.guarda(*ruta)` | guardar el PNG |
| `azar(semilla)` | azar determinista (LCG) para texturas |

Lo que **no** hay, a propósito: `resize`, `rotate`, degradados, `ImageDraw` con
antialias, desenfoques. Si hace falta rotar, se dibuja la otra vista a mano.

Tres patrones que resuelven casi todo:

```python
# a) volumen: base, luz arriba-izquierda, sombra abajo-derecha, contorno al final
L.r(x, y, w, h, BASE)
L.hl(x, x + w - 2, y, LUZ);      L.vl(x, y, y + h - 2, LUZ)
L.hl(x + 1, x + w - 1, y + h - 1, SOMBRA); L.vl(x + w - 1, y + 1, y + h - 1, SOMBRA)
L.contorno(NEGRO)

# b) textura repetible y siempre igual (madera, tierra, estuco)
r = azar(1234)
for j in range(h):
    for i in range(w):
        L.p(x + i, y + j, TONOS[int(r() * len(TONOS))])

# c) sello: un dibujo en texto, para hojas, letras, iconos pequeños
HOJA = ('..T..', 'T.c.T', '.ccc.', '..+..')
for j, fila in enumerate(HOJA):
    for i, ch in enumerate(fila):
        L.p(x + i, y + j, {'T': PUNTA, 'c': HOJA_C, '+': RABILLO}.get(ch))
```

## 4. Animación

Un fotograma es un PNG entero, nunca una deformación del anterior. Se dibuja la pose,
no se mueve la imagen.

- Elige primero los fotogramas clave (contacto, paso, impacto) y dibújalos; los
  intermedios, después, si de verdad hacen falta.
- Un ciclo de respirar o de esperar se hace con 2 fotogramas y 1 px de diferencia; andar,
  con 4; un golpe, con 4 a 6.
- **El pivote no se mueve**: los pies (o la base del objeto) caen en la misma fila en
  todos los fotogramas de una animación, salvo salto o caída a propósito. El QA lo mide.
- Lo que se repite sin fin (agua, fuego, una rueda) se saca de una función del tiempo:
  `fase = i / n` y las piezas se colocan con esa fase, así el ciclo cierra solo.

## 5. QA (obligatorio, antes de enseñar nada)

`python3 -I scripts/qa_pixel.py '{"size":[48,48],"palette":["#1a1c2c","…"]}' sprites/*.png`

Mide, y lo que falla no se entrega:

- tamaño exacto de la celda;
- **0** píxeles semitransparentes;
- **0** colores fuera de la paleta (sin paleta, aviso por encima de 32 colores);
- **≤ 2** píxeles huérfanos (sin ningún vecino pintado);
- pivote estable entre los fotogramas de una animación;
- el sprite no se sale de su celda y no la llena entera sin aire (deja el margen que
  pida el proyecto).

Con `"fix": true` cuantiza a la paleta y aplana el alfa a `<nombre>_fixed.png`, pero eso
es un parche: lo correcto es arreglar el script y volver a ejecutarlo.

## 6. Revisión visual (también obligatoria)

1. `python3 -I scripts/preview.py sprites/*.png` → `preview_x8.png` (ampliado a 8× por
   vecino más cercano, con las tiras de cada animación y un fondo de tablero para ver
   el alfa).
2. Ábrelo con Read y **míralo**. No se entrega un sprite que no se ha mirado.
3. Compruébalo contra la ficha: silueta a 1×, luz y contorno iguales en todos los
   fotogramas, proporciones estables, el ciclo cierra, la paleta pega con lo que ya hay
   (pon el sprite al lado de uno viejo del proyecto y míralos juntos).
4. Si falla, se corrige **el script**, no el PNG. Un retoque suelto se pierde a la
   siguiente ejecución.
5. Tres vueltas como mucho por sprite. Si a la tercera no sale, se entrega la mejor y se
   dice en una línea qué falla.

## 7. Idempotencia y salida

- El script se puede ejecutar mil veces y da exactamente el mismo PNG: nada de
  `random` sin semilla, nada de la hora, nada de recorrer un diccionario sin orden.
- Un script que retoca sprites ya procesados (alargar filas, recolorear) tiene que poder
  volver a pasar sobre su propia salida sin estropearla, y decirlo: «nada que tocar».
- Estructura de salida:

```
sprites/<nombre>/
  <nombre>.py            el script, con su ficha en la cabecera
  frames/<anim>_<dir>_<nn>.png
  <nombre>_sheet.png     rejilla: una fila por animación/dirección
  <nombre>_sheet.json    {frames:{id:{x,y,w,h}}, anims:{…fps, loop}, pivot:[x,y]}
  preview_x8.png
```

En un proyecto que ya tenga su cadena de arte (como este, con
`art/crudo/<grupo>/<sprite>/unica/00.png` + `node tools/sprites/procesar.js <grupo>
--atlas`), se respeta **esa** y no se monta una nueva: se escribe donde el proyecto
espera y se ejecuta su procesador. Mira antes un script hermano de
`ribera-verde/tools/sprites/a-mano/` y copia su forma.

## 8. Cierre

Se informa solo de: qué sprites salieron y dónde, el resultado del QA (ok o avisos),
lo que se desvía de la ficha, y el comando exacto para regenerarlos. Nada más.

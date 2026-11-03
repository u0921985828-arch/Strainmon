# Repaso de arte y sprites — los cinco «recomendado» de `docs/REPASO-ESTRUCTURA.md` §2

Solo Godot (`godot/`, `tools/`). Nada de `npm run godot:html` ni de APK. Las cifras de «antes» están medidas sobre el
árbol tal como estaba al empezar; las de «después», sobre el que queda.

Herramientas nuevas o cambiadas: `tools/sprites/paleta.js` (`--solo-arte`), `godot/tests/paleta.gd`,
`tools/carpa_hoja.py`, `tools/maceta35.py`, `tools/sprites/a-mano/kaia_vc.py`, `tools/sprites/procesar.js`,
`tools/sprites/a-mano/laboratorio.py`, `tools/sprites/a-mano/interiores_bilbao.py`, `godot/src/arte.gd`.

---

## 1 (ALTO) · La paleta real, declarada y comprobada

**Qué pasaba.** `art/paleta/ribera.json` solo traía la paleta sacada del arte procedural de `art/referencias`
(`maestra` 121 colores, `existentes` 346, `fondos` 438; 788 en total). El arte que se publica no sale de ahí: 179 de
los 258 assets del manifiesto declaran `paleta: "propia"` (el arte dibujado a mano y el del generador de sprites), y
`procesar.js` solo cierra la paleta de los otros 79. Medido hoja por hoja, **9 de 9 hojas de `godot/arte` se salían**
y **8.417 de sus 8.754 colores (96 %) no estaban en ninguna de las tres listas**: un control contra ellas falla en
todo y no distingue un color nuevo de los 4.000 de siempre.

| hoja | colores | fuera de `maestra`+`existentes`+`fondos` |
|---|---|---|
| `atlas.png` | 4.336 | 4.000 (92 %) |
| `kaia_pl.png` | 2.114 | 2.099 (99 %) |
| `kaia_pl_anim.png` | 2.049 | 2.037 (99 %) |
| `retratos.png` | 1.851 | 1.850 (100 %) |
| `viaje.png` | 383 | 333 (87 %) |
| `epi_pl.png` | 182 | 182 (100 %) |
| `billar_bolas.png` | 121 | 116 (96 %) |
| `billar.png` | 44 | 42 (95 %) |
| `carpa.png` | 24 (antes 152) | 14 (58 %) |

**Qué se eligió.** Declarar la paleta real, no cerrar a posteriori los 179 generadores: cerrarla ahora cambiaría
píxeles en todo el arte ya aprobado y en los 62 oráculos de pantalla. `maestra` se queda como lo que es (el estilo
que se le pasa al generador de sprites) y lo que se comprueba es la medida de verdad.

**Qué se cambió.**

- `tools/sprites/paleta.js`: mide `godot/arte/*.png` y escribe en `ribera.json` una sección `arte` con, por hoja, su
  número de colores, los píxeles semitransparentes y su lista cerrada (hexadecimal sin `#`, por orden, separada por
  espacios: 96 KB en total). Con `--solo-arte` solo rehace esa sección —no necesita las referencias— y dice por hoja
  cuántos colores son nuevos y cuántos ya no salen.
- `godot/tests/paleta.gd` (nueva, entra sola en la batería: el bucle de `tools/tests.sh` recorre `tests/*.gd`):
  comprueba que toda hoja de `arte/` esté declarada y al revés, que cada píxel opaco de cada hoja use un color de su
  lista y que no haya alfa a medias. Los colores distintos se sacan ordenando el entero de cada píxel y saltando de
  valor en valor con `bsearch`, así que los 12,5 millones de píxeles del arte se miran en **0,84 s**.

**Resultado.** `paleta: 36 comprobaciones, 0 fallos` · por hoja, 0 colores declarados sin usar (la lista no está
inflada). Que discrimina está comprobado: quitando dos colores de la lista de `carpa.png` y declarando una hoja que
no existe, la prueba saca `arte/carpa.png usa 2 colores que no están en su paleta: 000000, 1c1d22` y
`art/paleta/ribera.json declara arte/sobra.png, que ya no existe` → `2 fallos`.

---

## 2 (MEDIO) · 43 % del atlas es transparencia dentro de las celdas — **descartado, con la medida**

**Medida de hoy** (atlas ya deduplicado, 1024 × 6128): 6.275.072 px, de los que solo 2.712.261 son opacos
(**43,2 %**); el 56,8 % es transparente. Sumando las celdas únicas (6.007.338 px) y recortando cada una a su caja
(3.458.461 px), el recorte ahorraría **42,4 % del área**: de **25,1 MB a 13,8 MB** en la GPU (`Atlas.hojas`, el atlas
entero sube a textura) y unos 300 KB de PNG.

**Por qué no se aplica.** El recorte obliga a llevar el desplazamiento (`ox`, `oy`) y la celda de cada fotograma
hasta quien lo pinta: hay **52 llamadas a `Atlas.frame_de`** y **19 a `Atlas.dibuja`**, todas con `dst` calculado a
partir de la celda entera, y de esas 19 todas pasan un `src` (trozos parciales: tapado al 45 %, recortes de pared,
mitades de muebles) cuyo origen dejaría de coincidir con la celda. La mayoría está en `godot/src/pinta.gd`, que esta
tanda no puede tocar (lo está editando otro), y el arte es exactamente lo que comparan píxel a píxel
`tests/pantallas.gd` (62 escenas), `tests/prueba.gd` (8.712 comprobaciones) y `tests/capas.gd` (48.184). Con la
ganancia en memoria de gama baja (−11,3 MB) y el riesgo de desplazar medio juego un píxel, no entra aquí.

**Parche propuesto** (para cuando `pinta.gd` esté libre, en una tanda propia con los oráculos delante):

1. `tools/sprites/procesar.js`, en `buildAtlas`: recortar cada fotograma a su caja antes de empaquetarlo y guardar en
   `atlas.json` `frames[k] = {x, y, w, h, ox, oy, cw, ch}` (`cw`/`ch`, la celda; `ox`/`oy`, la esquina del recorte).
2. `godot/src/atlas.gd`:
   - `frame(k)`: devolver la imagen de la celda entera (`Image.create` + `blit_rect` del recorte) para todo lo que
     mira píxeles (`Arte.alto`, el espejo, `_fd_de`); el coste en RAM es el de hoy, porque ya se guarda una imagen
     por fotograma en `fr`.
   - `_registra`/`dibuja`: registrar el rectángulo recortado y su `ox`/`oy`, y en `dibuja` mover `dst` y cortar `src`
     con el recorte (`src` intersecado con `Rect2(ox, oy, w, h)`, y lo que quede fuera, no se pinta).
3. Comprobar con `tests/pantallas.gd`, `prueba.gd`, `capas.gd`, `negro_render.gd` y `tapa_mapas.gd` antes de nada.

---

## 3 (MEDIO) · `carpa.png` ya no repite el atlas

**Qué pasaba.** De los 181 rectángulos de `carpa.json`, **175 eran el mismo dibujo, píxel a píxel, que un fotograma
del atlas** (comprobado por huella de píxeles, contando como igual todo lo transparente): el mismo arte viajaba dos
veces en la app y se cargaba dos veces en memoria (`Atlas.img` y `Arte.img`). Los 6 propios son los que se dibujan a
mano aparte (`maceta-c-tela35-28` de `tools/maceta35.py` y `kc-serv-*`/`kc-filtrof-*` de
`tools/sprites/a-mano/kaia_vc.py`), porque el HTML quedó congelado en la 1.37 y `tools/godot.js` no se vuelve a
pasar.

**Qué se cambió.**

- `tools/carpa_hoja.py` (nuevo): deja en el atlas lo que ya está en él —`carpa.json` lo apunta con su rectángulo de
  `atlas.png` y lo nombra en `"atlas"`— y empaqueta en `carpa.png` solo los propios. Es idempotente (dos pasadas dan
  el mismo byte) y sirve de módulo a los generadores: `abre()`, `saca(n, i)`, `pon(n, im, off)`, `guarda()`.
- `godot/src/arte.gd`: `en_atlas` desde `carpa.json` y `foto()` corta de `Atlas.img` o de `img` según el sprite. El
  resto de la API (`hay`, `n_fotos`, `anchos`, `off`, rampas, luces, recortes) no cambia, y `sprites` conserva el
  orden de siempre, del que depende `anchos()`.
- `tools/maceta35.py` y `kaia_vc.py`: ya no tienen celdas a mano ((704, 736), (720, 96), (736, 112), la fila 768): el
  sitio lo reparte `carpa_hoja`. `kaia_vc` lee la tira de la pared con `saca('carpa-c-pared')` y ya no pega los LED
  de 720 W de KAIA, que están en el atlas (`carpa-c-focos-led-ancho` de `equipo_c.py`). Los dos vuelven a dejar la
  hoja byte a byte igual.

**Cifras.** `carpa.png` **1024 × 889 → 160 × 141**; en memoria **910.336 → 22.560 px** (−3,5 MB de los 3,6 que
ocupaba `Arte.img`); en la app **101.322 → 2.293 bytes**. `carpa.json`: 52 sprites, 46 en el atlas, 6 propios; sus
colores pasan de 152 a 24.

**Pruebas.** `prueba` (vista C contra el HTML) `C1: 8712 comprobaciones, 0 diferencias` · `pantallas`
`62 escenas, 0 diferencias` · `kaia_vista` `272, 0 fallos` · `madres_vista` `19, 0` · `tallo_vista` `22, 0` ·
`plantacion` `95, 0` · `luz_carpa` `213, 0` · `capas` `48.184, 0` · `texturas` `19, 0` · `clima_vista` `23, 0` ·
`sala_fria` `51, 0` · `kaia_cult` `342, 0` · `patrones` `50, 0` · `extracciones` `55 escenas, 0 fallos`.

---

## 4 (MEDIO) · Escalas

Escala del juego: 16 px/m (el protagonista, 27 px = 1,70 m).

| sprite | antes | después | medida real |
|---|---|---|---|
| `lab-alto/labDucha` | 48 px (3,00 m) | **37 px (2,31 m)**, regadera a 2,06 m | ducha de emergencia ~2,30 m |
| `interior-bilbao-alto/cirioI` | 37 px (2,31 m) | **29 px (1,81 m)** | cirio con su candelabro ~1,80 m |
| `props-escala/fridge` | 36 px | **36 px, sin tocar** | nevera combi 1,81 m: ya era correcta (abajo) |

- `tools/sprites/a-mano/laboratorio.py`, `labDucha`: el tubo subía hasta la fila 0 de la celda (el techo) y la
  regadera quedaba a 2,69 m. Ahora la columna arranca en la fila 12 y el brazo y la regadera bajan con ella; el
  tirador y su varilla se quedan donde estaban (1,63–1,75 m, al alcance de la mano), y el sumidero y la señal, igual.
- `tools/sprites/a-mano/interiores_bilbao.py`, `cirioI`: la peana no se mueve; el pie, el platillo, la vela de 10 px
  y la llama bajan 8 px.
- `props-escala/fridge` **no es un error de escala, es la regla de los muebles de frente del propio juego**
  (`equipo_p5.py`: «el frente a su ancho y alto reales y la tapa vista desde arriba a medio fondo, como las carpas
  del piso»). Su frente mide 29 px = **1,81 m**, que es el alto de una nevera combi, y los otros 7 px son la tapa de
  los 60 cm de fondo a medio fondo (5 px) más el contorno (2). El control es su vecina de grupo,
  `props-escala/crate`: cajas de 40 cm con «frente de 6 × 6 y tapa de 3», 80 cm apilados y 19 px de caja. Medir el
  alto del sprite como alto real da 2,25 m en la nevera y 1,19 m en las cajas: la medida que falla es la del
  informe, no el sprite. Recortarla a 29 px dejaría una nevera de 1,45 m.

**Cómo se regeneró.** `python3 -I tools/sprites/a-mano/{laboratorio,interiores_bilbao}.py` (comprobado antes con su
argumento de raíz: de los 71 sprites de los dos, solo cambian esos dos) y
`node tools/sprites/procesar.js interior-bilbao-alto lab-alto --atlas --atlas-dir godot/arte` + `tools/png-opt.py`.

**Pruebas.** `escala: 103 comprobaciones, 0 fallos` · `interiores_bilbao: 853, 0` · `banco_tia: 104, 0` ·
`solapes: 73, 0 (0 solapes en 69 mapas)` · `detalle: 84, 0` · `suelo_negro: 91, 0` · `pantallas: 62 escenas, 0
diferencias` · `negro_render: 27, 0`.

---

## 5 (BAJO) · Fotogramas repetidos

**En el atlas: arreglado.** `tools/sprites/procesar.js`, en `buildAtlas`, da un solo sitio a los fotogramas que
tienen los mismos píxeles (huella SHA-1 con lo transparente a cero) y hace que sus claves apunten al mismo
rectángulo; el orden de las claves de `frames` se mantiene (de él depende qué se pinta encima de cada casilla, por
`anims`/`sobre`). **155 fotogramas repetidos** de 3.042 → el atlas pasa de **1024 × 6277 a 1024 × 6128** (−149
filas, −2,4 % del área) y de **1.189.247 a 1.147.556 bytes** (−41.691, −3,5 %), con **25,7 → 25,1 MB** en la GPU.
Comprobado que no se pierde arte: `atlas.json` da las mismas 3.042 claves y los mismos `anims`, `celdas`, `rampas`,
`cubre`, `ambiente`, `fumador` y `menores`, y los 3.042 fotogramas salen con los mismos píxeles que antes (0
distintos). La línea del script ahora dice `ATLAS OK: 3042 fotogramas en 1024×6128 (155 repetidos, un solo sitio
para cada uno)`.

**Entre el crudo y el procesado: descartado, con la medida.** Hoy son 32 archivos byte a byte iguales (15 KB) y
1.303 con los mismos píxeles (1,2 MB) de los 3.042: son los sprites a mano que ya salen en su celda y en su paleta,
así que `procesar.js` no les toca nada. **No cuestan ni un byte en la app ni en el repositorio**: `art/crudo/` está
en `.gitignore` (no se versiona) y `art/procesado/` tampoco viaja en la app —de él sale el atlas—. Borrar el crudo
rompe volver a procesar (es la entrada de `procesar.js`) y borrar el procesado rompe el atlas (es lo que recorre
`buildAtlas`). Ahorro real de quitarlos: 0.

---

## Batería

Pasadas, todas en verde, con el Godot de `/home/user/godot-bin` (las gráficas con xvfb y opengl3, como
`tools/tests.sh`): **`paleta` 36/0 (nueva)**, `pantallas` 62 escenas/0 diferencias, `prueba` 8.712/0, `capas`
48.184/0, `negro_render` 27/0, `suelo_negro` 91/0, `suelo_cache` 364/0 (91 mapas), `luz_carpa` 213/0,
`texturas` 19/0, `retratos` 474/0, `extracciones` 55/0, `iconos` 131/0, `escala` 103/0, `solapes` 73/0,
`interiores_bilbao` 853/0, `banco_tia` 104/0, `kaia_vista` 272/0, `kaia_cult` 342/0, `madres_vista` 19/0,
`tallo_vista` 22/0, `plantacion` 95/0, `patrones` 50/0, `detalle` 84/0, `clima_vista` 23/0, `sala_fria` 51/0,
`acceso` 111/0, `acto2` 31/0, `acto3` 44/0, `arboles_edificios` 27/0, `camarote` 70/0, `caza` 38/0,
`combate_lado` 78/0, `combate_r` 458/0, `concesionario` 95/0, `copa_ot` 39/0, `despacho` 78/0, `estanterias` 248/0,
`garaje` 77/0, `huerta` 192/0, `huerta_mej` 107/0, `huerta_sitios` 340/0, `metro` 265/0, `movil` 20/0,
`nave_salas` 31/0, `negocios` 351/0, `obras` 54/0, `ocio` 67/0, `pelo` 4.929/0, `personaje` 24/0, `pueblos` 348/0,
`puertas_alto` 67/0, `puertas_libres` 63/0, `puertas_rejilla` 69/0, `rarezas` 54/0, `translucido` 18/0,
`vallas` 1.096/0, `vehiculos` 163/0, `viaje` 151/0. Y `python3 -I tools/png-opt.py --check godot/arte`:
«0 de 9 PNG adelgazan».

No se pasaron `ciclo`, `historia`, `tapa_mapas`, `familias`, `genetica` ni `capturas_ui`: no tocan nada de esto o
están en archivos que otro está editando en esta misma tanda.

## Notas de la tanda

- **`art/procesado` no se puede regenerar entero.** `node tools/sprites/procesar.js --todos` cambia píxeles en 1.147
  archivos ya aprobados, porque sobre el procesado pasan después los retoques a mano (`npc_ojos.py`, `npc_cara.py`,
  `recolor.py`, `npc_ojos_acc.py`). Hay que procesar solo los grupos que cambian. El atlas, en cambio, se rehace
  entero sin riesgo: con `art/procesado` intacto sale con los mismos píxeles (comprobado).
- `godot/arte/atlas.json` y `atlas.png`, `carpa.json` y `carpa.png`, `art/paleta/ribera.json`,
  `art/procesado/lab-alto/labDucha` y `art/procesado/interior-bilbao-alto/cirioI` quedan regenerados en el árbol.
  Sin commit, sin APK y sin tocar la versión de `project.godot`.
- El cambio de `godot/src/arte.gd` (13 líneas: `en_atlas` y `foto()`) se fue, sin querer, en el commit `caae248`
  («Repaso 0.78: estructura y pintado»), que hizo otro mientras esto estaba a medias. El árbol queda coherente de
  todas formas: con el `carpa.json` de antes (sin `"atlas"`) la lista sale vacía y `arte.gd` lee todo de `carpa.png`,
  como siempre. Lo que falta por guardar es el arte y las herramientas de esta tanda.
- Queda sin anotar en `CHANGELOG.md` y en `docs/REPASO-ESTRUCTURA.md` (los está editando otro en esta misma tanda):
  ahí van las dos líneas de estado de §2, «aplicado» en los hallazgos 1, 3, 4 (los dos sprites) y 5 (el atlas), y
  «medido y descartado» en el 2 y en la parte de crudo/procesado del 5.

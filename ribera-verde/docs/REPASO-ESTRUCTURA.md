# Repaso de estructura, arte, optimización y estadísticas (0.76)

Lo pidió el usuario: «mejoremos la estructura del juego, teniendo ya lo que tenemos. Es decir, el cómo está creado,
los sprites, cómo funciona, la optimización y esas cosas. Que las estadísticas y esas movidas».

Seis auditorías independientes sobre `ribera-verde/godot` (42.204 líneas, 2.646 funciones, 90 mapas, 87 variedades):
arquitectura, arte, economía, genética, rendimiento de pintado y errores latentes. Aquí queda el resultado: lo que
se arregló en esta tanda y lo que se deja medido para la siguiente. Cada línea dice dónde está.

## 1 · Arquitectura (`src/`)

| | hallazgo | estado |
|---|---|---|
| ALTO | 336 stubs de cadena en `mundo.gd` y `trama.gd`; 266 no dicen dónde está la implementación | recomendado: anotar `# → <archivo>.gd` con un script y una prueba `tests/virtuales.gd` |
| ALTO | tres llamadas a funciones de las hijas por cadena de texto, para esquivar el parser | recomendado |
| ALTO | 34 copias de `if cache.size() > 1024: cache.clear()`: el fallo de los destellos que ya se arregló para las texturas seguía vivo para las imágenes | **aplicado** (`arte.gd`, `pinta.gd`, `procedural.gd`: tope por generaciones, `_cpon`/`_ctiene`) |
| ALTO | nueve visores «en vitrina» con el mismo esqueleto de 12 líneas en cinco archivos | recomendado |
| ALTO | `obj_local()` 308 líneas y `object_action()` 208: dos cadenas de `if S.map == …` | recomendado |
| MEDIO | 17 lectores perezosos de `S` calcados, y `metro_d()` sin guarda | **aplicado** (la guarda de `metro_d`) |
| MEDIO | nueve funciones que nadie nombra en `src`, `tests`, `tools` ni `docs` | **aplicado** (33 líneas fuera) |
| MEDIO | `olor_nave()` de la base devolvía algo distinto de la implementación | **aplicado** (hueco de cadena, con su comentario) |
| MEDIO | 13 stubs que nadie menciona · 16 cuerpos de base que no se ejecutan · el prólogo de venta copiado 10 veces | recomendado |
| BAJO | `migrate()` lee dos claves antes de rellenarlas · `_pinta_menu()` 204 líneas | recomendado |

## 2 · Arte y sprites

| | hallazgo | estado |
|---|---|---|
| ALTO | `atlas.png` pesaba 2,72 MB y recomprimido sin pérdida 1,19 MB (pngjs usaba `deflateStrategy: 3`) | **aplicado** (`procesar.js`, `godot.js` con `deflateStrategy: 0`; nueve PNG rehechos, −2,49 MB; `tools/png-opt.py --check` en la batería) |
| ALTO | el arte no respeta `art/paleta/ribera.json`: el control de paleta falla en todo y no discrimina | recomendado: declarar la paleta real o cerrarla en cada generador |
| MEDIO | 43 % del atlas en memoria es transparencia dentro de las celdas (recorte al bbox + offset) | recomendado, solo si hace falta memoria en gama baja |
| MEDIO | `carpa.png` repite 175 de 181 rectángulos que ya están en el atlas | recomendado |
| MEDIO | la nevera a escala mide 2,25 m; la ducha del laboratorio 3 m; el cirio 2,3 m | recomendado (recorte en `escala.py`, `laboratorio.py`, `interiores_bilbao.py`) |
| BAJO | 155 fotogramas duplicados dentro del atlas (2,6 % del área) · 219 archivos iguales entre crudo y procesado | recomendado |
| BAJO | semitransparencias 0 y píxeles huérfanos 0 en los 3.042 procesados: el limpiado de `procesar.js` funciona | sin nada que hacer |

## 3 · Rendimiento de pintado

Línea base (llvmpipe, `--rend`), coste de GDScript en `capa0`: `home` 1,9 · `nave` 2,3 · `zorroza` 3,5 · `casco` 3,9 ·
`abando` 4,6 · `town` 6,6 ms. Los 37–149 ms de `proceso` son rasterizado por software, no código.

| | hallazgo | estado |
|---|---|---|
| ALTO | `Atlas.frame_de` no memorizaba nada y se llama ~160 veces por fotograma (1,0–2,1 ms) | **aplicado** (`_fd_de`: claves, espejo, fps, bucle y celda por grupo+anim+dirección) |
| MEDIO | `_suelo_base` y `_suelo_mira` rehacían el hash profundo de la rejilla en cada llamada (0,9 ms + 0,3) | **aplicado** (`_mapa_gh()`, una vez por fotograma) |
| MEDIO | `_farolas` barría el mapa entero en cada fotograma de noche, por un valor por omisión de `get()` | **aplicado** (`_far_c`, con la rejilla y los objetos en la clave) |
| ALTO | `_arte_obj` resuelve el sprite de cada objeto en cada fotograma (2,9 ms en `casco`) | recomendado (caché por objeto con generación) |
| ALTO | el suelo animado (agua a 4 fps) se repinta 60 veces por segundo | recomendado (saltar si el fotograma no cambió) |
| MEDIO | `Cultivo.huecos(S)` por planta y `Vista.geo` dos veces por fotograma · `_arte_edificios` sin recorte por cámara | recomendado |
| BAJO | el cono de la policía con un `draw_rect` por casilla (hasta 242) · `tapa_obj` con claves `String` | recomendado (`_rects_lote`, como la lluvia) |

## 4 · Economía

| | hallazgo | estado |
|---|---|---|
| ALTO | comprar al por mayor y revender por mar daba +44 % a +72 % sin cultivar | **aplicado** (`MERCADO.mayor.f` 1,6 → 2,8, con prueba en `tests/negocios.gd`) |
| ALTO | el mar paga por encima de la calle y sin tope de calor · la cuota de Molina anula calor y redadas | recomendado |
| MEDIO | la deuda deja de importar en el cap. 5 · la calidad se acumula hasta ×2,21 y los documentos dicen +15 % | recomendado |
| MEDIO | las máquinas de extracción caras rinden menos por gramo que la prensa de 250 € | recomendado |
| MEDIO | quesería y panadería cuestan 30.000 € y rinden como el lavadero de 3.000 € · los clubs dominan a Iñaki | recomendado |
| BAJO | la luz cuesta el 2,5 % de lo que da la carpa: elegir sodio o LED no cuesta nada | recomendado |

## 5 · Genética y estadísticas

| | hallazgo | estado |
|---|---|---|
| MEDIO | la nave y la sala de KAIA no topaban el THC en 35 % y el curado lo pasaba | **aplicado** (`Cultivo.THC_TOPE`, el mismo techo en casa, la nave y KAIA) |
| MEDIO | el rendimiento del foco de la nave no contaba `rend` | **aplicado** (`venta.gd`, `kaiacult.gd`, oráculo de `tests/nave.gd`) |
| BAJO | tres recetas con `gen` incoherente y cuatro landraces sin historia | **aplicado** (diez `gen` recalculados en cascada, cuatro `h` nuevos, prueba en `tests/cannadex.gd`) |
| MEDIO | `IVS.base [6,18]` arranca por debajo del punto neutro · el generador y las placas de `ENERGIA` no pueden hacer falta nunca | recomendado |
| MEDIO | 79 de 87 variedades están dominadas en las cuatro cifras | recomendado |
| BAJO | las rarezas se heredan 8 veces peor en las feminizadas · «Doble cosecha» no hace nada en la nave ni en KAIA | recomendado |
| BAJO | `docs/GENETICA.md` y `ANALISIS.md` describen la fórmula antigua | recomendado |

## 6 · Errores latentes (partida en curso)

| | hallazgo | estado |
|---|---|---|
| FATAL | hablar con el empleado después de dejar el local desde dentro reventaba la charla (`neg_o` sin `has`) | **aplicado** (aviso y `build_ents()` con el `erase`) |
| GRAVE | dejar el local desde dentro se quedaba con el efectivo metido hoy, sin decirlo | **aplicado** (el mismo aviso que la rama de fuera) |
| GRAVE | vender un vehículo destruía lo que llevara el maletero | **aplicado** (los lotes a la caja fuerte y el abono a los botes, con aviso) |
| MENOR | retirar del dispensario y vaciar el alijo del franco se saltaban el tope de la mochila | **aplicado** (`libre_mochila()`, el resto se queda) |
| MENOR | el trabajador de la sala de KAIA se quedaba mudo (`match` sin `_:`) | **aplicado** (rama por defecto y `build_ents()` al liberar el puesto) |

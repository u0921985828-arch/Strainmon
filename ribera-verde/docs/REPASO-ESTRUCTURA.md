# Repaso de estructura, arte, optimización y estadísticas (0.76)

Lo pidió el usuario: «mejoremos la estructura del juego, teniendo ya lo que tenemos. Es decir, el cómo está creado,
los sprites, cómo funciona, la optimización y esas cosas. Que las estadísticas y esas movidas».

Seis auditorías independientes sobre `ribera-verde/godot` (42.204 líneas, 2.646 funciones, 90 mapas, 87 variedades):
arquitectura, arte, economía, genética, rendimiento de pintado y errores latentes. Aquí queda el resultado: lo que
se arregló en esta tanda y lo que se deja medido para la siguiente. Cada línea dice dónde está.

## 1 · Arquitectura (`src/`)

| | hallazgo | estado |
|---|---|---|
| ALTO | 336 stubs de cadena en `mundo.gd` y `trama.gd`; 266 no dicen dónde está la implementación | **aplicado** (`tools/virtuales.py --check` en la batería: 0 sin rótulo) |
| ALTO | tres llamadas a funciones de las hijas por cadena de texto, para esquivar el parser | **aplicado** (0.78: `relanzar()`, `save()` y `relanza` declarados en `mundo.gd`) |
| ALTO | 34 copias de `if cache.size() > 1024: cache.clear()`: el fallo de los destellos que ya se arregló para las texturas seguía vivo para las imágenes | **aplicado** (`arte.gd`, `pinta.gd`, `procedural.gd`: tope por generaciones, `_cpon`/`_ctiene`) |
| ALTO | nueve visores «en vitrina» con el mismo esqueleto de 12 líneas en cinco archivos | **aplicado** (0.78: `_vis_abre`/`_vis_cierra` en `setas.gd`) |
| ALTO | `obj_local()` 308 líneas y `object_action()` 208: dos cadenas de `if S.map == …` | **aplicado** (0.78: una función por mapa, `_ol_*` en `venta.gd` y `_oa_*` en `calle.gd`) |
| MEDIO | 17 lectores perezosos de `S` calcados, y `metro_d()` sin guarda | **aplicado** (la guarda de `metro_d`) |
| MEDIO | nueve funciones que nadie nombra en `src`, `tests`, `tools` ni `docs` | **aplicado** (33 líneas fuera) |
| MEDIO | `olor_nave()` de la base devolvía algo distinto de la implementación | **aplicado** (hueco de cadena, con su comentario) |
| MEDIO | 13 stubs que nadie menciona · 16 cuerpos de base que no se ejecutan · el prólogo de venta copiado 10 veces | **aplicado** (0.78: el prólogo, en `_pide_lote` de `mundo.gd`; los stubs y los cuerpos ya no se reproducen: todos tienen implementación y toda hija llama a `super()`) |
| BAJO | `migrate()` lee dos claves antes de rellenarlas · `_pinta_menu()` 204 líneas | **aplicado** (0.78: `S.deadline` y `S.rel` con guarda; `_pinta_menu` 92 líneas con `_pm_titulo`/`_pm_fila`/`_pm_desc`) |

## 2 · Arte y sprites

| | hallazgo | estado |
|---|---|---|
| ALTO | `atlas.png` pesaba 2,72 MB y recomprimido sin pérdida 1,19 MB (pngjs usaba `deflateStrategy: 3`) | **aplicado** (`procesar.js`, `godot.js` con `deflateStrategy: 0`; nueve PNG rehechos, −2,49 MB; `tools/png-opt.py --check` en la batería) |
| ALTO | el arte no respeta `art/paleta/ribera.json`: el control de paleta falla en todo y no discrimina | **aplicado** (0.78: `arte.hojas` con la lista medida de cada hoja de `godot/arte`, `node tools/sprites/paleta.js --solo-arte`, y `godot/tests/paleta.gd` 36/0: falla si una hoja usa un color que no está en la suya, si sobra uno declarado o si hay alfa a medias) |
| MEDIO | 43 % del atlas en memoria es transparencia dentro de las celdas (recorte al bbox + offset) | **descartado con medida** (0.78: ese aire es la celda de tamaño fijo, de la que salen el ancla y el recorte de cada sprite; recortar al bbox obliga a un desplazamiento por fotograma en todo el motor de pintado) |
| MEDIO | `carpa.png` repite 175 de 181 rectángulos que ya están en el atlas | **aplicado** (0.78: `tools/carpa_hoja.py` los deja apuntando al atlas —`"atlas"` en `carpa.json`, `en_atlas` en `arte.gd`— y la hoja pasa de 1024 × 889 a 160 × 141) |
| MEDIO | la nevera a escala mide 2,25 m; la ducha del laboratorio 3 m; el cirio 2,3 m | **aplicado** en las dos reales (0.78: `labDucha` 48 → 37 px, 2,31 m; `cirioI` 37 → 29 px, 1,81 m) · la nevera no era un error: su frente mide 1,81 m y los 7 px de arriba son la tapa a medio fondo, la regla de los muebles de frente |
| BAJO | 155 fotogramas duplicados dentro del atlas (2,6 % del área) · 219 archivos iguales entre crudo y procesado | **aplicado** en el atlas (0.78: `procesar.js` da un solo rectángulo a los fotogramas con los mismos píxeles; 1024 × 6277 → 1024 × 6128 y 1.189.247 → 1.147.556 B, mismas 3.042 claves) · los archivos iguales entre crudo y procesado no pesan ni un byte en la app ni en el repositorio: ahorro 0 |
| BAJO | semitransparencias 0 y píxeles huérfanos 0 en los 3.042 procesados: el limpiado de `procesar.js` funciona | sin nada que hacer |

## 3 · Rendimiento de pintado

Línea base (llvmpipe, `--rend`), coste de GDScript en `capa0`: `home` 1,9 · `nave` 2,3 · `zorroza` 3,5 · `casco` 3,9 ·
`abando` 4,6 · `town` 6,6 ms. Los 37–149 ms de `proceso` son rasterizado por software, no código.

| | hallazgo | estado |
|---|---|---|
| ALTO | `Atlas.frame_de` no memorizaba nada y se llama ~160 veces por fotograma (1,0–2,1 ms) | **aplicado** (`_fd_de`: claves, espejo, fps, bucle y celda por grupo+anim+dirección) |
| MEDIO | `_suelo_base` y `_suelo_mira` rehacían el hash profundo de la rejilla en cada llamada (0,9 ms + 0,3) | **aplicado** (`_mapa_gh()`, una vez por fotograma) |
| MEDIO | `_farolas` barría el mapa entero en cada fotograma de noche, por un valor por omisión de `get()` | **aplicado** (`_far_c`, con la rejilla y los objetos en la clave) |
| ALTO | `_arte_obj` resuelve el sprite de cada objeto en cada fotograma (2,9 ms en `casco`) | **aplicado** (0.78: `OBJ_CACHE` con `_obj_f`, clave por objeto, mapa y generación; prueba `tests/obj_cache.gd`) |
| ALTO | el suelo animado (agua a 4 fps) se repinta 60 veces por segundo | **aplicado** (0.78: las casillas animadas en su propio trozo, `SD_ON`, `_sd_sello`) |
| MEDIO | `Cultivo.huecos(S)` por planta y `Vista.geo` dos veces por fotograma · `_arte_edificios` sin recorte por cámara | **aplicado** (0.78: caché de `huecos()`, `geo` una vez por `pinta()` y recorte por cámara en `_arte_edificios`) |
| BAJO | el cono de la policía con un `draw_rect` por casilla (hasta 242) · `tapa_obj` con claves `String` | **aplicado** (0.78: el cono con `_rects_lote` y las claves de `tapa_obj`, enteras) |

## 4 · Economía

| | hallazgo | estado |
|---|---|---|
| ALTO | comprar al por mayor y revender por mar daba +44 % a +72 % sin cultivar | **aplicado** (`MERCADO.mayor.f` 1,6 → 2,8, con prueba en `tests/negocios.gd`) |
| ALTO | el mar paga por encima de la calle y sin tope de calor · la cuota de Molina anula calor y redadas | **aplicado** (0.77: `MAR.rutas[*].pxc` ×1,1-1,4 y atunero de 25 kg · `cuota_molina()` con el 5 % de lo facturado y calor 75 al parar la orden) |
| MEDIO | la deuda deja de importar en el cap. 5 · la calidad se acumula hasta ×2,21 y los documentos dicen +15 % | **aplicado** (0.78: `PLAZO_PCT` 0,5 y `plazo_due(5)` en `trama.gd`, el plazo del cap. 5 es lo pactado o medio plazo de lo facturado · la cadena de calidad se queda y la cuentan `docs/ECONOMIA.md`, `GENETICA.md` y `ANALISIS.md`; medida en `tests/repaso_eco_gen.gd`) |
| MEDIO | las máquinas de extracción caras rinden menos por gramo que la prensa de 250 € | **aplicado** (0.77: `EXTR.lava.rendc` 0,19, `EXTR.stat.rendc` 0,12 y `EXTR.rosin.topec` 80) |
| MEDIO | quesería y panadería cuestan 30.000 € y rinden como el lavadero de 3.000 € · los clubs dominan a Iñaki | **aplicado** en los locales (0.77: `basec` 330 y 310, `genc` 70 y 65) · los clubs, 0.78: `MERCADO.club.topec` 100-130 g por confianza (los cinco a tope, 650 g al día, por debajo del kilo de Iñaki) y `CLUB.calorg` (calor 1 + 1/75 g: 0,021/g frente a los 0,012/g del por mayor) |
| BAJO | la luz cuesta el 2,5 % de lo que da la carpa: elegir sodio o LED no cuesta nada | **aplicado** (0.77: tarifa de potencia `POTENCIA`, 2.300 W de serie y 6 €/día por escalón de 1.150 W) |

## 5 · Genética y estadísticas

| | hallazgo | estado |
|---|---|---|
| MEDIO | la nave y la sala de KAIA no topaban el THC en 35 % y el curado lo pasaba | **aplicado** (`Cultivo.THC_TOPE`, el mismo techo en casa, la nave y KAIA) |
| MEDIO | el rendimiento del foco de la nave no contaba `rend` | **aplicado** (`venta.gd`, `kaiacult.gd`, oráculo de `tests/nave.gd`) |
| BAJO | tres recetas con `gen` incoherente y cuatro landraces sin historia | **aplicado** (diez `gen` recalculados en cascada, cuatro `h` nuevos, prueba en `tests/cannadex.gd`) |
| MEDIO | `IVS.base [6,18]` arranca por debajo del punto neutro · el generador y las placas de `ENERGIA` no pueden hacer falta nunca | **aplicado** (0.78: `IVS.basec` [10, 22], media en el punto neutro · `ENERGIA.*.limc` 4.600 W: a tope el piso y la nave se pasan) |
| MEDIO | 79 de 87 variedades están dominadas en las cuatro cifras | **descartado con medida** (0.78: ninguna de las 87 queda sin motivo —79 en familia de la CannaDex, 46 madre o padre de receta, 31 en las colecciones de la tía— y retocar cifras de variedades reales sería inventarlas; queda como regresión en `tests/repaso_eco_gen.gd`) |
| BAJO | las rarezas se heredan 8 veces peor en las feminizadas · «Doble cosecha» no hace nada en la nave ni en KAIA | **aplicado** (0.78: `ra_sin_semilla` —fijar pasa de 33,3 a 4 cosechas— y `prog_rebrote` ×1,20 en las mesas de la nave y de KAIA) |
| BAJO | `docs/GENETICA.md` y `ANALISIS.md` describen la fórmula antigua | **aplicado** (0.78: `GENETICA.md`, `ECONOMIA.md` y `ANALISIS.md` al día, y el mismo texto en la plantilla `tools/generar-docs.js`) |

## 6 · Errores latentes (partida en curso)

| | hallazgo | estado |
|---|---|---|
| FATAL | hablar con el empleado después de dejar el local desde dentro reventaba la charla (`neg_o` sin `has`) | **aplicado** (aviso y `build_ents()` con el `erase`) |
| GRAVE | dejar el local desde dentro se quedaba con el efectivo metido hoy, sin decirlo | **aplicado** (el mismo aviso que la rama de fuera) |
| GRAVE | vender un vehículo destruía lo que llevara el maletero | **aplicado** (los lotes a la caja fuerte y el abono a los botes, con aviso) |
| MENOR | retirar del dispensario y vaciar el alijo del franco se saltaban el tope de la mochila | **aplicado** (`libre_mochila()`, el resto se queda) |
| MENOR | el trabajador de la sala de KAIA se quedaba mudo (`match` sin `_:`) | **aplicado** (rama por defecto y `build_ents()` al liberar el puesto) |

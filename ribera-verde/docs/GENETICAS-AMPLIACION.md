# Ampliar el catálogo de genéticas — lo hecho

El catálogo tiene **104** variedades (`STRAINS` de `datos/datos.json`): 31 landraces, 56 cruces, 17 autoflorecientes
(16 + la Ruderalis). Todas reales: nada inventado, sin criadores ni bancos nombrados.

Lo que pidió el usuario, textual: «más que más landraces me refería a meter **más descendencias**, no más landraces».
Así que la ampliación no mete ni un nombre de fuera: mete **cinco maneras nuevas de sacar variedad de lo que ya
cultivas**. El catálogo lo fabrica quien juega.

## 1. Las cinco vías (`DESC` de `tools/descendencia.py`)

| Vía | Qué es | Dónde se juega | Qué sale |
|---|---|---|---|
| **Corte de madre** | De una madre que te ha salido buena guardas el corte con nombre propio. El fenotipo queda congelado tal cual. | Armario de las madres → GUARDAR ESTE CORTE. Hasta `DESC.corte.tope` (4) a la vez. Para meter madre: DE UN CORTE GUARDADO, una al día. | Cada esqueje sale idéntico: mismo THC, mismo porte, mismas rarezas. El corte no se gasta, pero la madre entra a `DESC.corte.v` (55) % de vigor: hay que criarla. |
| **Polinizar entre clones** | Dos esquejes pinchados, uno de madre y otro de padre. | Carro de esquejes, en un taco vacío → POLINIZAR ENTRE CLONES. Uno cada `DESC.clon.dias` (1). | `DESC.clon.sem` (3) semillas F1. Gasta los dos esquejes, pero las dos líneas siguen vivas en el armario: no se pierde ninguna. |
| **Autofecundación (S1)** | Una línea consigo misma. | Laboratorio del banco de la tía → TRABAJAR UNA LÍNEA TUYA → AUTOFECUNDAR (S1). `DESC.s1.tope` (2) por línea. | Gasta `DESC.s1.gasta` (2) semillas y da `DESC.s1.sem` (2): no multiplica. +`DESC.s1.iv` (2) en los cuatro genes y un nivel más de fijación en sus rarezas. No gana generación: es la misma línea, más fijada. |
| **Retrocruce (BX)** | Un híbrido tuyo cruzado con una de sus dos parentales. | Laboratorio → RETROCRUZAR CON LA MADRE (BX). Gasta `DESC.bx.gasta` (1) semilla de cada. | Variedad nueva, con su clave propia y nombre «<madre> BX1», «BX2»…, que tira a esa madre un `DESC.bx.m` (75-88) %. El número va por madre, así que ningún nombre se repite. |
| **Línea fijada (IBL)** | `DESC.ibl.sel` (2) selecciones seguidas de una línea ya fijada en F4. | Laboratorio → FIJAR LA LÍNEA (IBL). | La línea pasa al tipo genético `ibl` (`GENETICA.ibl`, sigma 0,03: la más baja de las ocho) y deja de variar de planta a planta. Sus genes no bajan de `DESC.ibl.iv` (26). |

Cada trabajo del laboratorio ocupa sus días (`DESC.<vía>.dias`: 3 el S1, 2 el BX y el IBL) y pasa por las siete normas de
`LAB` como la tetraploidia. Ninguna vía es gratis ni se repite sin fin: ese fue el resultado de la revisión por ataque. Nada de método, dosis ni reactivos: el juego dice lo que se juega, nunca cómo se hace.

## 2. Landraces: ninguna más

Lo dijo el usuario. Las 31 landraces se quedan como están y la ampliación va entera por descendencia. Tampoco se
añaden cruces comerciales nuevos: su linaje publicado no se pudo comprobar en fuentes desde esta sesión (los dominios
de consulta no están permitidos) y el proyecto prohíbe inventar genética, así que no se mete ninguno a ciegas.

## 3. Qué se tocó

- `tools/descendencia.py` → `DESC` y `GENETICA.ibl` en `godot/datos/datos.json`, sin mover ni un número de los 104.
- `godot/src/descend.gd` (nuevo): toda la lógica, estática y sin estado propio (`cortes`, `corte_pon`, `corte_desc`,
  `clones`, `s1`, `bx`, `ibl`, `es_ibl`).
- `godot/src/cultivo.gd`: `tipo_gen` devuelve `ibl` para la línea fijada a conciencia.
- `godot/src/nave.gd`: `madre_ops` guarda el corte, `madre_de_corte` mete la madre desde uno guardado y `madre_txt`
  la llama por su nombre propio.
- `godot/src/granja.gd`: `clones_ya` y `clones_cruce`, con el gesto de polinizar, en el carro.
- `godot/src/bancotia.gd`: `bt_desc`, `bt_s1`, `bt_bx` y `bt_ibl` como tercer trabajo del laboratorio.
- `godot/src/menus.gd`: cinco vías más en el RECETARIO de la CannaDex, que no listan variedades porque las fabricas tú.
- Pruebas: `tests/descendencia.gd` (57, nueva), `tests/cortes.gd` (33, nueva) y `tests/cannadex.gd` (56, con las vías).

## 4. Estado en la partida

- `S.cortes` = `[{k: variedad, f: fenotipo, n: nombre, dia}]`, hasta 4.
- `S.ibl` = `{variedad: selecciones hechas}`; es IBL con `DESC.ibl.sel`.
- `S.s1` = `{variedad: autofecundaciones}`, con tope `DESC.s1.tope`; `S.clonx` = el día del último cruce en el carro;
  `S.nave.ctd` = el día de la última madre metida desde un corte.
- El BX vive en `S.custom` como cualquier híbrido propio, con `bx` (su número) y `bxh` (de qué híbrido salió), y clave
  `"b" + b36(hash)` para no pisar la del cruce normal de los mismos dos.
- Una madre metida desde un corte lleva `ct` con su nombre.
- Nada de esto necesita migración: las partidas viejas entran sin cortes y sin líneas IBL.

## 5. Lo que no se hace

- Ni un nombre inventado, ni criadores, ni bancos, ni lemas.
- Nada de método, dosis, concentraciones ni reactivos.
- El árbol de generaciones no gana una generación nueva por el S1 ni por el BX: son la misma línea, más fijada.

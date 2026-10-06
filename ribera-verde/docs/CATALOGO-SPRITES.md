# Catálogo de sprites por herramienta de PixelLab

> Generado por `node tools/sprites/catalogo.js` desde `art/manifest.json`. No lo edites a mano: cambia el manifiesto y vuelve a generarlo.

Cada sprite del juego sale de la familia de herramientas que mejor lo resuelve: los personajes con rig, el terreno como tiles, lo que se apoya en el suelo pintado sobre el propio mapa, lo pequeño en lotes y las pantallas como imagen. Así se gastan menos generaciones y todo comparte estilo.

## Resumen

| Familia | Claves del juego | Assets | Herramientas | Generaciones aprox. |
|---|---|---|---|---|
| Personajes | 39 | 25 | create_character · animate_character · create_image_pro (paso previo) | 333 |
| Mapa · terreno | 23 | 6 | create_tiles_pro · create_building_kit · create_topdown_tileset · animate_image | 15 + sin documentar |
| Mapa · objetos con el estilo del mapa | 22 | 8 | create_map_object (background_image + máscara) · animate_image | 4 + sin documentar |
| Objetos sueltos en lote | 35 | 7 | create_1_direction_object (item_descriptions) · select_object_frames · animate_object | 90 + sin documentar |
| Imágenes simples | 3 | 3 | create_image_pixflux (init_image + color_image) | 3 |
| Se queda procedural | 2 | 1 | — | 0 |

**Total documentado: ~445 generaciones** (más create_tiles_pro, create_building_kit, create_map_object, animate_object, que PixelLab no publica: mira `get_balance` antes y después). Cobertura: 124/124 claves.

## Orden de creación

Las dependencias mandan: nada que use el estilo de otra cosa se genera antes de que esa otra esté aprobada.

- **F1 · Ancla de estilo:** player.
- **F3 · Personajes:** kiko, josune, baltasar, tono, begona, unai, patxi, txaro, inaki, cop, molina, darko, jurado, cliente1, cliente2, cliente3, cliente4, cliente5, cliente6, vfx-16, vfx-32.
- **F4 · Entorno:** tiles-exterior, interior-home, interior-shop, interior-bar, tiles-interior-extra, edificio-home (tras tiles-exterior), edificio-shop (tras tiles-exterior), edificio-bar (tras tiles-exterior), edificio-gray (tras tiles-exterior), props-16, props-32, prop-arbol (tras tiles-exterior), prop-farola (tras tiles-exterior), prop-fuente (tras tiles-exterior), carpa-cultivo (tras interior-home).
- **F4b · Transiciones (opcional):** tileset-transiciones — opcional.
- **F5 · Plantas:** planta-fases.
- **F6 · Combate:** player-combate (tras player), ladron1-combate, ladron2-combate, ladron3-combate, policia-combate (tras cop), fondo-combate-ladron, fondo-combate-policia.
- **F7 · Iconos y título:** iconos, cogollos-genoteca, titulo, burbujas.

## Personajes

Rig humanoide: rotaciones coherentes y plantillas de animación a 1 generación por dirección. Standard (1 gen) para los 20 del mundo; v3 con referencia para los de combate.

| Asset | Cubre | Herramienta | Lote | Entrada | Fase | Animaciones | Gen. |
|---|---|---|---|---|---|---|---|
| player | player | create_character (v3) | v3: 8 direcciones, 32 px | previo create_image_pro (solo texto) · reference_image_base64: player.png | F1 | idle*, walk*, run, regar*, plantar, cosechar, cruzar*, oler*, vender*, telefono* | 70 |
| kiko | kiko | create_character (standard) | 4 direcciones, 32 px | solo texto | F3 | idle, fumar*, semillas* | 7 |
| josune | josune | create_character (standard) | 4 direcciones, 32 px | solo texto | F3 | idle, secar_vaso*, servir* | 7 |
| baltasar | baltasar | create_character (standard) | 4 direcciones, 32 px | solo texto | F3 | idle, puro*, contar* | 7 |
| tono | tono | create_character (standard) | 4 direcciones, 32 px | solo texto | F3 | idle, nudillos*, fumar* | 7 |
| begona | begona | create_character (standard) | 4 direcciones, 32 px | solo texto | F3 | idle, walk, cotillear* | 10 |
| unai | kid, unai | create_character (standard) | 4 direcciones, 32 px | solo texto | F3 | idle, walk, pelota* | 10 |
| patxi | oldman, patxi | create_character (standard) | 4 direcciones, 32 px | solo texto | F3 | idle, palomas* | 7 |
| txaro | granny, txaro | create_character (standard) | 4 direcciones, 32 px | solo texto | F3 | idle, punto* | 6 |
| inaki | sailor, inaki | create_character (standard) | 4 direcciones, 32 px | solo texto | F3 | idle, pipa*, cabo* | 8 |
| cop | cop | create_character (standard) | 4 direcciones, 32 px | solo texto | F3 | idle, walk, radio* | 10 |
| molina | molina | create_character (standard) | 4 direcciones, 32 px | solo texto | F3 | idle, fumar* | 6 |
| darko | darko | create_character (standard) | 4 direcciones, 32 px | solo texto | F3 | idle, vapear* | 7 |
| jurado | judge, jurado | create_character (standard) | 4 direcciones, 32 px | solo texto | F3 | idle, notas* | 6 |
| cliente1 | cliente1 | create_character (standard) | 4 direcciones, 32 px | solo texto | F3 | idle, walk, movil* | 10 |
| cliente2 | cliente2 | create_character (standard) | 4 direcciones, 32 px | solo texto | F3 | idle, walk, fumar* | 10 |
| cliente3 | cliente3 | create_character (standard) | 4 direcciones, 32 px | solo texto | F3 | idle, walk, movil* | 10 |
| cliente4 | cliente4 | create_character (standard) | 4 direcciones, 32 px | solo texto | F3 | idle, walk, movil* | 10 |
| cliente5 | cliente5 | create_character (standard) | 4 direcciones, 32 px | solo texto | F3 | idle, walk, fumar* | 10 |
| cliente6 | cliente6 | create_character (standard) | 4 direcciones, 32 px | solo texto | F3 | idle, walk, movil* | 10 |
| player-combate | espalda:player | create_character (v3) | v3: 8 direcciones, 64 px | previo create_image_pro ← player aprobado · reference_image_base64: player-combate.png | F6 · tras player | idle, golpe, patada, spray*, comer*, herido, desmayo | 46 |
| ladron1-combate | ladron1, frente:ladron | create_character (standard) | 4 direcciones, 64 px | solo texto | F6 | idle, ataque, herido, huir | 5 |
| ladron2-combate | ladron2, frente:ladron | create_character (standard) | 4 direcciones, 64 px | solo texto | F6 | idle, ataque, herido, huir | 5 |
| ladron3-combate | ladron3, frente:ladron | create_character (standard) | 4 direcciones, 64 px | solo texto | F6 | idle, ataque, herido, huir | 5 |
| policia-combate | frente:policia | create_character (v3) | v3: 8 direcciones, 64 px | previo create_image_pro ← cop aprobado · reference_image_base64: policia-combate.png | F6 · tras cop | idle, alto*, multa*, soborno*, perseguir | 44 |

`*` = animación a medida (`action_description`, modo v3); el resto son plantillas a 1 generación por dirección.

## Mapa · terreno

Lo que se repite en casillas: tiles_pro numerados en una sola llamada, kit de edificio para suelo+pared de interiores, Wang encadenados para orillas.

| Asset | Cubre | Herramienta | Lote | Entrada | Fase | Animaciones | Gen. |
|---|---|---|---|---|---|---|---|
| tiles-exterior | grass, flowers, tallgrass, dirt, walk, roadT, roadB, plaza, water, bridgeT, bridgeB, dock | create_tiles_pro | 12 tiles numerados en 1 llamada | style_images: grass.png, walk.png, plaza.png, dirt.png | F4 | agua, flores, hierba-pisada | 3+? |
| tileset-transiciones | — | create_topdown_tileset (standard) | 3 juegos Wang de 16 tiles | solo texto | F4b | — | 12 |
| interior-home | floor, iwT_home, iwB_home | create_building_kit | kit: suelo + paredes conectables | solo texto | F4 | — | 0+? |
| interior-shop | floorS, iwT_shop, iwB_shop | create_building_kit | kit: suelo + paredes conectables | solo texto | F4 | — | 0+? |
| interior-bar | floorB, iwT_bar, iwB_bar | create_building_kit | kit: suelo + paredes conectables | solo texto | F4 | — | 0+? |
| tiles-interior-extra | mat, tent | create_tiles_pro | 2 tiles numerados en 1 llamada | style_images: mat.png, tent.png | F4 | — | 0+? |

## Mapa · objetos con el estilo del mapa

Lo grande que se apoya en el suelo (fachadas, carpa, árbol, farola, fuente): inpainting sobre un recorte real del mapa para que case luz, paleta y perspectiva.

| Asset | Cubre | Herramienta | Lote | Entrada | Fase | Animaciones | Gen. |
|---|---|---|---|---|---|---|---|
| edificio-home | roofT_home, roofB_home, wall_home, win_home, door_home | create_map_object | 1 por llamada, sobre el recorte del mapa | background_image: edificio-home.png · inpainting.mask_image: edificio-home_mascara.png | F4 · tras tiles-exterior | puerta | 1+? |
| edificio-shop | roofT_shop, roofB_shop, wall_shop, win_shop, door_shop | create_map_object | 1 por llamada, sobre el recorte del mapa | background_image: edificio-shop.png · inpainting.mask_image: edificio-shop_mascara.png | F4 · tras tiles-exterior | puerta | 1+? |
| edificio-bar | roofT_bar, roofB_bar, wall_bar, win_bar, door_bar | create_map_object | 1 por llamada, sobre el recorte del mapa | background_image: edificio-bar.png · inpainting.mask_image: edificio-bar_mascara.png | F4 · tras tiles-exterior | puerta | 1+? |
| edificio-gray | roofT_gray, roofB_gray, wall_gray, win_gray | create_map_object | 1 por llamada, sobre el recorte del mapa | background_image: edificio-gray.png · inpainting.mask_image: edificio-gray_mascara.png | F4 · tras tiles-exterior | — | 0+? |
| prop-arbol | tree | create_map_object | 1 por llamada, sobre el recorte del mapa | background_image: tree.png · inpainting.mask_image: tree_mascara.png | F4 · tras tiles-exterior | — | 0+? |
| prop-farola | lamp | create_map_object | 1 por llamada, sobre el recorte del mapa | background_image: lamp.png · inpainting.mask_image: lamp_mascara.png | F4 · tras tiles-exterior | — | 0+? |
| prop-fuente | fountain | create_map_object | 1 por llamada, sobre el recorte del mapa | background_image: fountain.png · inpainting.mask_image: fountain_mascara.png | F4 · tras tiles-exterior | agua | 1+? |
| carpa-cultivo | — | create_map_object | 1 por llamada, sobre el recorte del mapa | background_image: carpa.png · inpainting.mask_image: carpa_mascara.png | F4 · tras interior-home | — | 0+? |

## Objetos sueltos en lote

Muchos objetos pequeños del mismo estilo en una sola llamada (hasta 64 candidatos a ≤42 px): props, plantas, iconos, cogollos, VFX, gaviota y paloma.

| Asset | Cubre | Herramienta | Lote | Entrada | Fase | Animaciones | Gen. |
|---|---|---|---|---|---|---|---|
| props-16 | fence, sign, bench, crate, bush, pc, lab, lab2, table, shelfW, counter, display, plantDeco, barcounter, bottles, stool, btable, jukebox, iwin, poster | create_1_direction_object | 20 objetos en 1 llamada (64 candidatos a 16 px) | style_images: bench.png, sign.png, crate.png, bush.png, counter.png, stool.png, jukebox.png, plantDeco.png | F4 | luces | 30+? |
| props-32 | fridge, bedT, bedB | create_1_direction_object | 2 objetos · **comparte lote-32** (15 objetos de 4 assets en 1 llamada de 64 candidatos a 32 px) | solo texto | F4 | — | 30 |
| planta-fases | germinando, plantula, vegetativo, floracion, lista, muerta, maceta-vacia, sana, seca | create_1_direction_object | 7 objetos · **comparte lote-32** (15 objetos de 4 assets en 1 llamada de 64 candidatos a 32 px) | solo texto | F5 | balanceo-vegetativo, balanceo-floracion, balanceo-lista | 0+? |
| iconos | bolsa | create_1_direction_object | 12 objetos · **comparte lote-16** (24 objetos de 2 assets en 1 llamada de 64 candidatos a 16 px) | solo texto | F7 | — | 30 |
| cogollos-genoteca | — | create_1_direction_object | 4 objetos · **comparte lote-32** (15 objetos de 4 assets en 1 llamada de 64 candidatos a 32 px) | solo texto | F7 | — | 0 |
| vfx-16 | plaga, seca-plaga | create_1_direction_object | 12 objetos · **comparte lote-16** (24 objetos de 2 assets en 1 llamada de 64 candidatos a 16 px) | solo texto | F3 | vfx-humo-cigarro/efecto, vfx-humo-puro/efecto, vfx-humo-porro/efecto, vfx-humo-pipa/efecto, vfx-golpe/efecto, vfx-gotas/efecto, vfx-brillo/efecto, vfx-polen/efecto, vfx-acaros/efecto, vfx-monedas/efecto, gaviota/idle, paloma/idle | 0+? |
| vfx-32 | vfx-nube-vaper, vfx-spray | create_1_direction_object | 2 objetos · **comparte lote-32** (15 objetos de 4 assets en 1 llamada de 64 candidatos a 32 px) | solo texto | F3 | vfx-nube-vaper/efecto, vfx-spray/efecto | 0+? |

## Imágenes simples

Pantallas completas sin rig: img2img sobre la composición actual y paleta forzada, 1 generación.

| Asset | Cubre | Herramienta | Lote | Entrada | Fase | Animaciones | Gen. |
|---|---|---|---|---|---|---|---|
| fondo-combate-ladron | fondo-ladron | create_image_pixflux | pantalla entera, img2img | init_image_base64: fondo-ladron.png · color_image_base64: ribera.png | F6 | — | 1 |
| fondo-combate-policia | fondo-policia | create_image_pixflux | pantalla entera, img2img | init_image_base64: fondo-policia.png · color_image_base64: ribera.png | F6 | — | 1 |
| titulo | hoja-titulo | create_image_pixflux | pantalla entera, img2img | init_image_base64: titulo.png · color_image_base64: ribera.png | F7 | — | 1 |

## Se queda procedural

Burbujas $ y ! de 7×8: más nítidas a mano que generadas.

| Asset | Cubre | Herramienta | Lote | Entrada | Fase | Animaciones | Gen. |
|---|---|---|---|---|---|---|---|
| burbujas | burbuja-$, burbuja-! | procedural | — | solo texto | F7 | — | 0 |

## Lotes compartidos

Una llamada a `create_1_direction_object` de ≤42 px devuelve 64 candidatos y cuesta lo mismo con 2 objetos que con 60. Por eso los assets del mismo tamaño y sin `style_images` comparten llamada: se juntan sus `item_descriptions`, se eligen los candidatos con `select_object_frames` y cada uno va a la carpeta de su asset en `art/crudo/`.

- **lote-16** (16 px, se genera en F3): iconos (12), vfx-16 (12) → 24 objetos, 1 llamada. Ahorro: 30 generaciones. iconos + VFX de 16 px en una sola llamada (24 de 64 huecos). Los props de 16 px van aparte porque llevan style_images.
- **lote-32** (32 px, se genera en F3): props-32 (2), planta-fases (7), cogollos-genoteca (4), vfx-32 (2) → 15 objetos, 1 llamada. Ahorro: 90 generaciones. plantas, nevera y cama, cogollos de la Genoteca y VFX grandes en una sola llamada (15 de 64 huecos).

## Llamadas encadenadas

**player**
1. `create_image_pro` 32×32 solo con texto. Elige 1 de los 64 candidatos (se eligió el 17) y guárdalo en `art/crudo/_ref/player.png`.
2. `create_character` mode v3, size 32, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**player-combate**
1. `create_image_pro` 64×64 con `reference_images` = `art/procesado/player/base/south/00.png` («character base: same person, outfit and colors»). Elige 1 de los 16 candidatos y guárdalo en `art/crudo/_ref/player-combate.png`.
2. `create_character` mode v3, size 64, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**policia-combate**
1. `create_image_pro` 64×64 con `reference_images` = `art/procesado/cop/base/south/00.png` («character base: same person, outfit and colors»). Elige 1 de los 16 candidatos y guárdalo en `art/crudo/_ref/policia-combate.png`.
2. `create_character` mode v3, size 64, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**tileset-transiciones** (create_topdown_tileset, opcional)
1. `wang-agua-hierba`: lower «calm blue river water» → upper «short green grass», transition_size 0.25 — guarda el id del tile de hierba (get_topdown_tileset).
2. `wang-tierra-hierba`: lower «packed brown dirt path» → upper «short green grass», transition_size 0.25, `upper_base_tile_id` = <hierba de wang-agua-hierba>.
3. `wang-plaza-hierba`: lower «light grey stone plaza pavement» → upper «short green grass», transition_size 0, `upper_base_tile_id` = <hierba de wang-agua-hierba>.

**Objetos con el estilo del mapa** (`create_map_object`): `background_image` = recorte del mapa de `art/referencias/mapa/` y `inpainting` = `{"type": "mask", "mask_image": "<máscara en base64>"}` con la máscara `*_mascara.png` (blanco = lo que genera, negro = suelo que se conserva). Las fachadas y los props de exterior se generan después de aprobar `tiles-exterior`: regenera antes los recortes con los tiles nuevos (`npm run sprites:ref` con el atlas puesto) para que el contexto ya sea el arte final.

## Herramientas que no se usan (y por qué)

| Herramienta | Motivo |
|---|---|
| create_path_tiles | Solo genera tiles de 32 px en square_topdown; el juego usa 16 px. |
| create_ui_asset | Paneles de 192 px como mínimo; la interfaz es DOM a escala de 240×160. |
| create_isometric_tile / create_sidescroller_tileset | Otra perspectiva: el juego es vista 3/4 cenital. |
| create_8_direction_object | Los objetos del juego solo se ven desde un lado. |
| create_character_state / create_object_state | Nadie cambia de ropa en el guion y la planta seca o con cogollos de color la resuelve el motor con rampas. Plan B si las fases de la planta salen incoherentes en el lote: generar «lista» y sacar el resto como estados. |
| create_font | Ya hay fuentes OFL (Pixelify Sans, Press Start 2P). |
| create_portrait_character / create_vocal_animation | Opcional (F9): retratos con boca animada en los diálogos. ~20 generaciones por retrato; no es estética de portátil de 16 bits. |
| create_map / edit_map / place_map_object / view_map | No se usan en el juego (el mapa es del motor), pero sirven de maqueta opcional en F4b: pintar el barrio con los Wang, colocar edificios y props y revisar con view_map antes de integrar. |
| *_pro_flash | Alternativa de pago por imagen a create_character/objetos; no mejora a 16-32 px. |

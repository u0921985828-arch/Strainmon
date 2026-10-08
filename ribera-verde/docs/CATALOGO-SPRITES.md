# Catálogo de sprites por herramienta de PixelLab

> Generado por `node tools/sprites/catalogo.js` desde `art/manifest.json`. No lo edites a mano: cambia el manifiesto y vuelve a generarlo.

Cada sprite del juego sale de la familia de herramientas que mejor lo resuelve: los personajes con rig, el terreno como tiles, lo que se apoya en el suelo pintado sobre el propio mapa, lo pequeño en lotes y las pantallas como imagen. Así se gastan menos generaciones y todo comparte estilo.

## Resumen

| Familia | Claves del juego | Assets | Herramientas | Generaciones aprox. |
|---|---|---|---|---|
| Personajes | 49 | 25 | create_character · animate_character · create_image_pro (paso previo) | 1111 |
| Mapa · terreno | 22 | 6 | create_tiles_pro · create_building_kit · create_topdown_tileset · animate_image | 15 + sin documentar |
| Mapa · objetos con el estilo del mapa | 26 | 13 | create_map_object (background_image + máscara) · animate_image | 14 + sin documentar |
| Objetos sueltos en lote | 36 | 10 | create_1_direction_object (item_descriptions) · select_object_frames · animate_object | 180 + sin documentar |
| Imágenes simples | 22 | 11 | create_image_pixflux (init_image + color_image) | 7 + sin documentar |
| Se queda procedural | 2 | 1 | — | 0 |
| Importado | 122 | 38 | importado | 0 + sin documentar |

**Total documentado: ~1327 generaciones** (más create_tiles_pro, create_map_object, animate_object, edit_image_pixen, importado, que PixelLab no publica: mira `get_balance` antes y después). Cobertura: 257/257 claves.

## Orden de creación

Las dependencias mandan: nada que use el estilo de otra cosa se genera antes de que esa otra esté aprobada.

- **F1 · Ancla de estilo:** player.
- **F3 · Personajes:** kiko, josune, baltasar, tono, begona, unai, patxi, txaro, inaki, cop, molina, darko, jurado, cliente1, cliente2, cliente3, cliente4, cliente5, cliente6, vfx-16, vfx-32.
- **F4 · Entorno:** tiles-exterior, interior-home, interior-shop, interior-bar, tiles-interior-extra, edificio-home (tras tiles-exterior), edificio-shop (tras tiles-exterior), edificio-bar (tras tiles-exterior), edificio-gray (tras tiles-exterior), edificio-gray-puerta, edificio-comisaria, edificio-nave, edificio-caserio, edificio-caserio2, edificio-marinera, edificio-marinera2, edificio-marinera3, edificio-marinera4, edificio-ladrillo, edificio-fabrica, props-altura, prop-farola-alta, prop-gramola-alta, props-16, props-32, prop-arbol (tras tiles-exterior), prop-arbol-alto, prop-monte, prop-seto, prop-parada, prop-farola (tras tiles-exterior), prop-fuente (tras tiles-exterior), tiles-firmes, detalles-hierba, edificio-caserio3, edificio-borda, edificio-marinera5, edificio-marinera6, prop-manzano, prop-arbol-alto2.
- **F4b · Transiciones (opcional):** tileset-transiciones — opcional.
- **F5 · Plantas:** planta-fases.
- **F6 · Combate:** player-combate (tras player), ladron1-combate, ladron2-combate, ladron3-combate, policia-combate (tras cop), fondo-combate-ladron, fondo-combate-policia.
- **F7 · Iconos y título:** iconos, cogollos-genoteca, titulo, burbujas.
- **F8 · Pulido y cierre:** carpa-g150 (tras interior-home, tiles-interior-extra), carpa-g150-fuera (tras interior-home, tiles-interior-extra), carpa-m100 (tras carpa-g150), carpa-m100-fuera (tras carpa-g150-fuera), carpa-p60 (tras carpa-g150), carpa-p60-fuera (tras carpa-g150-fuera), macetas, focos, mesa-cultivo.

## Personajes

Rig humanoide: rotaciones coherentes y plantillas de animación a 1 generación por dirección. Standard (1 gen) para los 20 del mundo; v3 con referencia para los de combate.

| Asset | Cubre | Herramienta | Lote | Entrada | Fase | Animaciones | Gen. |
|---|---|---|---|---|---|---|---|
| player | player | create_character (v3) | v3: 8 direcciones, 32 px | previo create_image_pro (solo texto) · reference_image_base64: player.png | F1 | idle*, walk*, run*, regar*, plantar*, cosechar*, cruzar*, oler*, vender*, telefono* | 70 |
| kiko | kiko | create_character (v3) | v3: 8 direcciones, 32 px | previo create_image_pro (solo texto) · reference_image_base64: kiko.png | F3 | idle*, fumar*, semillas* | 44 |
| josune | josune | create_character (v3) | v3: 8 direcciones, 32 px | previo create_image_pro (solo texto) · reference_image_base64: josune.png | F3 | idle*, secar_vaso*, servir* | 44 |
| baltasar | baltasar | create_character (v3) | v3: 8 direcciones, 32 px | previo create_image_pro (solo texto) · reference_image_base64: baltasar.png | F3 | idle*, puro*, contar* | 44 |
| tono | tono, tono2 | create_character (v3) | v3: 8 direcciones, 32 px | previo create_image_pro (solo texto) · reference_image_base64: tono.png | F3 | idle*, nudillos*, fumar* | 44 |
| begona | begona | create_character (v3) | v3: 8 direcciones, 32 px | previo create_image_pro (solo texto) · reference_image_base64: begona.png | F3 | idle*, walk*, cotillear* | 44 |
| unai | kid, unai | create_character (v3) | v3: 8 direcciones, 32 px | previo create_image_pro (solo texto) · reference_image_base64: unai.png | F3 | idle*, walk*, pelota* | 44 |
| patxi | oldman, patxi | create_character (v3) | v3: 8 direcciones, 32 px | previo create_image_pro (solo texto) · reference_image_base64: patxi.png | F3 | idle*, palomas* | 42 |
| txaro | granny, txaro | create_character (v3) | v3: 8 direcciones, 32 px | previo create_image_pro (solo texto) · reference_image_base64: txaro.png | F3 | idle*, punto* | 41 |
| inaki | sailor, inaki | create_character (v3) | v3: 8 direcciones, 32 px | previo create_image_pro (solo texto) · reference_image_base64: inaki.png | F3 | idle*, pipa*, cabo* | 43 |
| cop | cop | create_character (v3) | v3: 8 direcciones, 32 px | previo create_image_pro (solo texto) · reference_image_base64: cop.png | F3 | idle*, walk*, radio* | 44 |
| molina | molina | create_character (v3) | v3: 8 direcciones, 32 px | previo create_image_pro (solo texto) · reference_image_base64: molina.png | F3 | idle*, fumar* | 41 |
| darko | darko, darko2 | create_character (v3) | v3: 8 direcciones, 32 px | previo create_image_pro (solo texto) · reference_image_base64: darko.png | F3 | idle*, vapear* | 42 |
| jurado | judge, jurado | create_character (v3) | v3: 8 direcciones, 32 px | previo create_image_pro (solo texto) · reference_image_base64: jurado.png | F3 | idle*, notas* | 41 |
| cliente1 | cliente1, excursionista | create_character (v3) | v3: 8 direcciones, 32 px | previo create_image_pro (solo texto) · reference_image_base64: cliente1.png | F3 | idle*, walk*, movil* | 44 |
| cliente2 | cliente2, obrero | create_character (v3) | v3: 8 direcciones, 32 px | previo create_image_pro (solo texto) · reference_image_base64: cliente2.png | F3 | idle*, walk*, fumar* | 44 |
| cliente3 | cliente3, turista | create_character (v3) | v3: 8 direcciones, 32 px | previo create_image_pro (solo texto) · reference_image_base64: cliente3.png | F3 | idle*, walk*, movil* | 44 |
| cliente4 | cliente4 | create_character (v3) | v3: 8 direcciones, 32 px | previo create_image_pro (solo texto) · reference_image_base64: cliente4.png | F3 | idle*, walk*, movil* | 44 |
| cliente5 | cliente5 | create_character (v3) | v3: 8 direcciones, 32 px | previo create_image_pro (solo texto) · reference_image_base64: cliente5.png | F3 | idle*, walk*, fumar* | 44 |
| cliente6 | cliente6, vecina | create_character (v3) | v3: 8 direcciones, 32 px | previo create_image_pro (solo texto) · reference_image_base64: cliente6.png | F3 | idle*, walk*, movil* | 44 |
| player-combate | espalda:player | create_character (v3) | v3: 8 direcciones, 64 px | previo create_image_pro (solo texto) · reference_image_base64: player-combate.png | F6 · tras player | idle*, golpe*, patada*, spray*, comer*, herido*, desmayo* | 46 |
| ladron1-combate | ladron1, frente:ladron | create_character (v3) | v3: 8 direcciones, 64 px | previo create_image_pro (solo texto) · reference_image_base64: ladron1-combate.png | F6 | idle*, ataque*, herido*, huir* | 43 |
| ladron2-combate | ladron2, frente:ladron | create_character (v3) | v3: 8 direcciones, 64 px | previo create_image_pro (solo texto) · reference_image_base64: ladron2-combate.png | F6 | idle*, ataque*, herido*, huir* | 43 |
| ladron3-combate | ladron3, frente:ladron | create_character (v3) | v3: 8 direcciones, 64 px | previo create_image_pro (solo texto) · reference_image_base64: ladron3-combate.png | F6 | idle*, ataque*, herido*, huir* | 43 |
| policia-combate | frente:policia | create_character (v3) | v3: 8 direcciones, 64 px | previo create_image_pro (solo texto) · reference_image_base64: policia-combate.png | F6 · tras cop | idle*, alto*, multa*, soborno*, perseguir* | 44 |

`*` = animación a medida (`action_description`, modo v3); el resto son plantillas a 1 generación por dirección.

## Mapa · terreno

Lo que se repite en casillas: tiles_pro numerados en una sola llamada, kit de edificio para suelo+pared de interiores, Wang encadenados para orillas.

| Asset | Cubre | Herramienta | Lote | Entrada | Fase | Animaciones | Gen. |
|---|---|---|---|---|---|---|---|
| tiles-exterior | grass, flowers, tallgrass, dirt, walk, roadT, roadB, plaza, water, bridgeT, bridgeB, dock | create_tiles_pro | 12 tiles numerados en 1 llamada | style_images: grass.png, walk.png, plaza.png, dirt.png | F4 | agua, flores, hierba-pisada | 3+? |
| tileset-transiciones | — | create_topdown_tileset (standard) | 3 juegos Wang de 16 tiles | solo texto | F4b | — | 12 |
| interior-home | floor, iwT_home, iwB_home | create_tiles_pro | 3 tiles numerados en 1 llamada | style_images: iwT_home.png, iwB_home.png, floor.png, floorS.png | F4 | — | 0+? |
| interior-shop | floorS, iwT_shop, iwB_shop | create_tiles_pro | 3 tiles numerados en 1 llamada | style_images: iwT_home.png, iwB_home.png, floor.png, floorS.png | F4 | — | 0+? |
| interior-bar | floorB, iwT_bar, iwB_bar | create_tiles_pro | 3 tiles numerados en 1 llamada | style_images: iwT_home.png, iwB_home.png, floor.png, floorS.png | F4 | — | 0+? |
| tiles-interior-extra | mat | create_tiles_pro | 1 tiles numerados en 1 llamada | style_images: mat.png | F4 | — | 0+? |

## Mapa · objetos con el estilo del mapa

Lo grande que se apoya en el suelo (fachadas, carpa, árbol, farola, fuente): inpainting sobre un recorte real del mapa para que case luz, paleta y perspectiva.

| Asset | Cubre | Herramienta | Lote | Entrada | Fase | Animaciones | Gen. |
|---|---|---|---|---|---|---|---|
| carpa-g150 | carpa-g150 | create_image_pixflux | pantalla entera, img2img | init_image_base64: huella-carpa-interior.png | F8 · tras interior-home, tiles-interior-extra | — | 1 |
| carpa-g150-fuera | carpa-g150-fuera | create_image_pixflux | pantalla entera, img2img | init_image_base64: huella-carpa-exterior.png | F8 · tras interior-home, tiles-interior-extra | — | 1 |
| carpa-m100 | carpa-m100 | create_image_pixflux | pantalla entera, img2img | init_image_base64: huella-carpa-interior.png | F8 · tras carpa-g150 | — | 1 |
| carpa-m100-fuera | carpa-m100-fuera | create_image_pixflux | pantalla entera, img2img | init_image_base64: huella-carpa-exterior.png | F8 · tras carpa-g150-fuera | — | 1 |
| carpa-p60 | carpa-p60 | create_image_pixflux | pantalla entera, img2img | init_image_base64: huella-carpa-interior.png | F8 · tras carpa-g150 | — | 1 |
| carpa-p60-fuera | carpa-p60-fuera | create_image_pixflux | pantalla entera, img2img | init_image_base64: huella-carpa-exterior.png | F8 · tras carpa-g150-fuera | — | 1 |
| edificio-home | roofT_home, roofB_home, wall_home, win_home, door_home | create_image_pixflux | pantalla entera, img2img | init_image_base64: huella-edificio-home.png | F4 · tras tiles-exterior | puerta | 2 |
| edificio-shop | roofT_shop, roofB_shop, wall_shop, win_shop, door_shop | create_image_pixflux | pantalla entera, img2img | init_image_base64: huella-edificio-shop.png | F4 · tras tiles-exterior | puerta | 2 |
| edificio-bar | roofT_bar, roofB_bar, wall_bar, win_bar, door_bar | create_image_pixflux | pantalla entera, img2img | init_image_base64: huella-edificio-bar.png | F4 · tras tiles-exterior | puerta | 2 |
| edificio-gray | roofT_gray, roofB_gray, wall_gray, win_gray | create_image_pixflux | pantalla entera, img2img | init_image_base64: huella-edificio-gray.png | F4 · tras tiles-exterior | — | 1 |
| prop-arbol | — | create_map_object | 1 por llamada, sobre el recorte del mapa | background_image: tree.png · inpainting.mask_image: tree_mascara.png | F4 · tras tiles-exterior | — | 0+? |
| prop-farola | — | create_map_object | 1 por llamada, sobre el recorte del mapa | background_image: lamp.png · inpainting.mask_image: lamp_mascara.png | F4 · tras tiles-exterior | — | 0+? |
| prop-fuente | fountain | create_map_object | 1 por llamada, sobre el recorte del mapa | background_image: fountain.png · inpainting.mask_image: fountain_mascara.png | F4 · tras tiles-exterior | agua | 1+? |

## Objetos sueltos en lote

Muchos objetos pequeños del mismo estilo en una sola llamada (hasta 64 candidatos a ≤42 px): props, plantas, iconos, cogollos, VFX, gaviota y paloma.

| Asset | Cubre | Herramienta | Lote | Entrada | Fase | Animaciones | Gen. |
|---|---|---|---|---|---|---|---|
| macetas | maceta-plastico7, maceta-tela11, maceta-plastico18, maceta-tela25 | create_1_direction_object | 48 objetos en 1 llamada (64 candidatos a 16 px) | style_images: estilo-maceta-16.png | F8 | — | 30 |
| focos | foco-cfl, foco-sodio, foco-led | create_1_direction_object | 48 objetos en 1 llamada (64 candidatos a 32 px) | style_images: maceta-vacia-32.png | F8 | — | 30 |
| mesa-cultivo | mesa | create_1_direction_object | 24 objetos en 1 llamada (64 candidatos a 16 px) | style_images: 00.png | F8 | — | 30 |
| props-16 | fence, sign, bench, bush, pc, lab, lab2, table, shelfW, display, plantDeco, bottles, stool, btable, iwin, poster | create_1_direction_object | 64 objetos en 1 llamada (64 candidatos a 16 px) | style_images: bench.png, sign.png, crate.png, bush.png, counter.png, stool.png, jukebox.png, plantDeco.png | F4 | luces | 30+? |
| props-32 | bedT, bedB | create_1_direction_object | 2 objetos · **comparte lote-32** (15 objetos de 4 assets en 1 llamada de 64 candidatos a 32 px) | solo texto | F4 | — | 30 |
| planta-fases | germinando, plantula, vegetativo, floracion, lista, muerta, maceta-vacia, sana, seca | create_1_direction_object | 7 objetos · **comparte lote-32** (15 objetos de 4 assets en 1 llamada de 64 candidatos a 32 px) | solo texto | F5 | balanceo-vegetativo, balanceo-floracion, balanceo-lista | 0+? |
| iconos | bolsa | create_1_direction_object | 12 objetos · **comparte lote-16** (24 objetos de 2 assets en 1 llamada de 64 candidatos a 16 px) | solo texto | F7 | — | 30 |
| cogollos-genoteca | — | create_1_direction_object | 4 objetos · **comparte lote-32** (15 objetos de 4 assets en 1 llamada de 64 candidatos a 32 px) | solo texto | F7 | — | 0 |
| vfx-16 | vfx-humo-cigarro, vfx-humo-puro, vfx-humo-porro, vfx-humo-pipa, vfx-golpe, vfx-gotas, vfx-brillo, vfx-polen, vfx-acaros, vfx-monedas, gaviota, paloma | create_1_direction_object | 12 objetos · **comparte lote-16** (24 objetos de 2 assets en 1 llamada de 64 candidatos a 16 px) | solo texto | F3 | vfx-humo-cigarro/efecto, vfx-humo-puro/efecto, vfx-humo-porro/efecto, vfx-humo-pipa/efecto, vfx-golpe/efecto, vfx-gotas/efecto, vfx-brillo/efecto, vfx-polen/efecto, vfx-acaros/efecto, vfx-monedas/efecto, gaviota/idle, paloma/idle | 0+? |
| vfx-32 | vfx-nube-vaper, vfx-spray | create_1_direction_object | 2 objetos · **comparte lote-32** (15 objetos de 4 assets en 1 llamada de 64 candidatos a 32 px) | solo texto | F3 | vfx-nube-vaper/efecto, vfx-spray/efecto | 0+? |

## Imágenes simples

Pantallas completas sin rig: img2img sobre la composición actual y paleta forzada, 1 generación.

| Asset | Cubre | Herramienta | Lote | Entrada | Fase | Animaciones | Gen. |
|---|---|---|---|---|---|---|---|
| fondo-combate-ladron | fondo-ladron | create_image_pixflux | pantalla entera, img2img | init_image_base64: fondo-ladron.png | F6 | — | 1 |
| fondo-combate-policia | fondo-policia | create_image_pixflux | pantalla entera, img2img | init_image_base64: fondo-policia.png | F6 | — | 1 |
| carpas-mapa | carpa-p60-mapa, carpa-m100-mapa, carpa-g150-mapa | create_image_pixflux | pantalla entera, img2img | init_image_base64: huella-carpas-mapa.png | F9 | — | 1 |
| carpas-vista | carpa-p60-vista, carpa-m100-vista, carpa-g150-vista | create_image_pixflux | pantalla entera, img2img | init_image_base64: huella-carpas-vista.png | F9 | — | 1 |
| macetas-vista | maceta-vista-plastico7, maceta-vista-tela11, maceta-vista-plastico18, maceta-vista-tela25 | create_image_pixflux | pantalla entera, img2img | init_image_base64: huella-macetas-vista.png | F9 | — | 1 |
| cuarto-cultivo | cuarto-cultivo | create_image_pixflux | pantalla entera, img2img | init_image_base64: huella-cuarto-cultivo.png | F9 | — | 1 |
| titulo | hoja-titulo | create_image_pixflux | pantalla entera, img2img | init_image_base64: titulo.png | F7 | — | 1 |
| carpa-c-focos | foco-c-40, foco-c-44, foco-c-46 | edit_image_pixen | — | image_url: imagen-a-foco.png | F9 | — | 0+? |
| carpa-c-macetas | maceta-c-15, maceta-c-22 | edit_image_pixen | — | image_url: imagen-a-maceta.png | F9 | — | 0+? |
| carpa-c-plantas | planta-c-i-24, planta-c-i-36 | edit_image_pixen | — | image_url: imagen-a-planta.png | F9 | — | 0+? |
| carpa-c-focos-cfl | foco-c-cfl-36 | edit_image_pixen | — | image_url: vista-c-foco-48.png | F9 | — | 0+? |

## Se queda procedural

Burbujas $ y ! de 7×8: más nítidas a mano que generadas.

| Asset | Cubre | Herramienta | Lote | Entrada | Fase | Animaciones | Gen. |
|---|---|---|---|---|---|---|---|
| burbujas | burbuja-$, burbuja-! | procedural | — | solo texto | F7 | — | 0 |

## Importado

Arte propio del repositorio que ya existe (Strainmon): se adapta en local (recorte y escala) sin gastar generaciones.

| Asset | Cubre | Herramienta | Lote | Entrada | Fase | Animaciones | Gen. |
|---|---|---|---|---|---|---|---|
| edificio-gray-puerta | door_gray | importado | — | solo texto | F4 | — | 0+? |
| edificio-comisaria | roofT_comisaria, roofB_comisaria, wall_comisaria, win_comisaria, door_comisaria | importado | — | solo texto | F4 | puerta | 0+? |
| edificio-nave | roofT_nave, roofB_nave, wall_nave, win_nave, door_nave | importado | — | solo texto | F4 | puerta | 0+? |
| edificio-caserio | roofT_caserio, roofB_caserio, wall_caserio, win_caserio, door_caserio | importado | — | solo texto | F4 | puerta | 0+? |
| edificio-caserio2 | roofT_caserio2, roofB_caserio2, wall_caserio2, win_caserio2 | importado | — | solo texto | F4 | puerta | 0+? |
| edificio-marinera | roofT_marinera, roofB_marinera, wall_marinera, win_marinera | importado | — | solo texto | F4 | — | 0+? |
| edificio-marinera2 | roofT_marinera2, roofB_marinera2, wall_marinera2, win_marinera2 | importado | — | solo texto | F4 | — | 0+? |
| edificio-marinera3 | roofT_marinera3, roofB_marinera3, wall_marinera3, win_marinera3 | importado | — | solo texto | F4 | — | 0+? |
| edificio-marinera4 | roofT_marinera4, roofB_marinera4, wall_marinera4, win_marinera4 | importado | — | solo texto | F4 | — | 0+? |
| edificio-ladrillo | roofT_ladrillo, roofB_ladrillo, wall_ladrillo, win_ladrillo | importado | — | solo texto | F4 | — | 0+? |
| edificio-fabrica | roofT_fabrica, roofB_fabrica, wall_fabrica, win_fabrica | importado | — | solo texto | F4 | — | 0+? |
| props-altura | counter, barcounter | importado | — | solo texto | F4 | — | 0+? |
| prop-farola-alta | lamp | importado | — | solo texto | F4 | — | 0+? |
| prop-gramola-alta | jukebox | importado | — | solo texto | F4 | — | 0+? |
| prop-arbol-alto | tree | importado | — | solo texto | F4 | — | 0+? |
| prop-monte | monte, monte2 | importado | — | solo texto | F4 | — | 0+? |
| prop-seto | seto | importado | — | solo texto | F4 | — | 0+? |
| prop-parada | parada | importado | — | solo texto | F4 | — | 0+? |
| carpas-medias-mapa | carpa-p80-mapa, carpa-m120-mapa | importado | — | solo texto | F9 | — | 0+? |
| carpas-medias-vista | carpa-p80-vista, carpa-m120-vista | importado | — | solo texto | F9 | — | 0+? |
| plantas-vista | planta-vista | importado | — | solo texto | F9 | — | 0+? |
| carpa-c-fondo | carpa-c-pared, carpa-c-luz | importado | — | solo texto | F9 | — | 0+? |
| carpa-c-plantas-h | planta-c-h-24, planta-c-h2-24, planta-c-h1-18, planta-c-h0-8 | importado | — | solo texto | F9 | — | 0+? |
| carpa-c-plantas-a | planta-c-i-38, planta-c-i2-38, planta-c-i-32, planta-c-i2-32, planta-c-h-38, planta-c-h2-38, planta-c-h-32, planta-c-h2-32, planta-c-s-38, planta-c-s2-38, planta-c-s-32, planta-c-s2-32, planta-c-h1-18, planta-c-h0-8 | importado | — | solo texto | F9 | — | 0+? |
| carpa-c-focos-led | foco-c-led100-26, foco-c-led100-20, foco-c-led200-30, foco-c-led200-24, foco-c-cfl-25 | importado | — | solo texto | F9 | — | 0+? |
| carpa-c-focos-led-ancho | foco-c-led480-47, foco-c-led720-78 | importado | — | solo texto | F9 | — | 0+? |
| carpa-c-macetas-b | maceta-c-tela11-26, maceta-c-tela11-20, maceta-c-tela25-27, maceta-c-plastico18-26, maceta-c-plastico18-23 | importado | — | solo texto | F9 | — | 0+? |
| carpa-c-extras | extra-c-vent, extra-c-filtro-28, extra-c-filtro-39, extra-c-garrafa-20, extra-c-garrafa-23, extra-c-garrafa-26, extra-c-garrafa-29, extra-c-llave, extra-c-deposito | importado | — | solo texto | F9 | — | 0+? |
| iconos-equipo | — | importado | — | solo texto | F9 | — | 0+? |
| props-escala | fridge, crate | importado | — | solo texto | F9 | — | 0+? |
| tiles-firmes | hormigon, pista, rotoT, rotoB | importado | — | solo texto | F4 | — | 0+? |
| detalles-hierba | detalles | importado | — | solo texto | F4 | — | 0+? |
| edificio-caserio3 | roofT_caserio3, roofB_caserio3, wall_caserio3, win_caserio3 | importado | — | solo texto | F4 | — | 0+? |
| edificio-borda | roofT_borda, roofB_borda, wall_borda, win_borda | importado | — | solo texto | F4 | — | 0+? |
| edificio-marinera5 | roofT_marinera5, roofB_marinera5, wall_marinera5, win_marinera5 | importado | — | solo texto | F4 | — | 0+? |
| edificio-marinera6 | roofT_marinera6, roofB_marinera6, wall_marinera6, win_marinera6 | importado | — | solo texto | F4 | — | 0+? |
| prop-manzano | manzano | importado | — | solo texto | F4 | — | 0+? |
| prop-arbol-alto2 | tree2 | importado | — | solo texto | F4 | — | 0+? |

## Lotes compartidos

Una llamada a `create_1_direction_object` de ≤42 px devuelve 64 candidatos y cuesta lo mismo con 2 objetos que con 60. Por eso los assets del mismo tamaño y sin `style_images` comparten llamada: se juntan sus `item_descriptions`, se eligen los candidatos con `select_object_frames` y cada uno va a la carpeta de su asset en `art/crudo/`.

- **lote-16** (16 px, se genera en F3): iconos (12), vfx-16 (12) → 24 objetos, 1 llamada. Ahorro: 30 generaciones. iconos + VFX de 16 px en una sola llamada (24 de 64 huecos). Los props de 16 px van aparte porque llevan style_images.
- **lote-32** (32 px, se genera en F3): props-32 (2), planta-fases (7), cogollos-genoteca (4), vfx-32 (2) → 15 objetos, 1 llamada. Ahorro: 90 generaciones. plantas, nevera y cama, cogollos de la Genoteca y VFX grandes en una sola llamada (15 de 64 huecos).

## Llamadas encadenadas

**player**
1. `create_image_pro` 32×32 solo con texto. Elige 1 de los 64 candidatos (se eligió el 17) y guárdalo en `art/crudo/_ref/player.png`.
2. `create_character` mode v3, size 32, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**kiko**
1. `create_image_pro` 32×32 solo con texto. Elige 1 de los 64 candidatos (se eligió el 4) y guárdalo en `art/crudo/_ref/kiko.png`.
2. `create_character` mode v3, size 32, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**josune**
1. `create_image_pro` 32×32 solo con texto. Elige 1 de los 64 candidatos (se eligió el 0) y guárdalo en `art/crudo/_ref/josune.png`.
2. `create_character` mode v3, size 32, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**baltasar**
1. `create_image_pro` 32×32 solo con texto. Elige 1 de los 64 candidatos (se eligió el 0) y guárdalo en `art/crudo/_ref/baltasar.png`.
2. `create_character` mode v3, size 32, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**tono**
1. `create_image_pro` 32×32 solo con texto. Elige 1 de los 64 candidatos (se eligió el 0) y guárdalo en `art/crudo/_ref/tono.png`.
2. `create_character` mode v3, size 32, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**begona**
1. `create_image_pro` 32×32 solo con texto. Elige 1 de los 64 candidatos (se eligió el 0) y guárdalo en `art/crudo/_ref/begona.png`.
2. `create_character` mode v3, size 32, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**unai**
1. `create_image_pro` 32×32 solo con texto. Elige 1 de los 64 candidatos (se eligió el 17) y guárdalo en `art/crudo/_ref/unai.png`.
2. `create_character` mode v3, size 32, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**patxi**
1. `create_image_pro` 32×32 solo con texto. Elige 1 de los 64 candidatos (se eligió el 16) y guárdalo en `art/crudo/_ref/patxi.png`.
2. `create_character` mode v3, size 32, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**txaro**
1. `create_image_pro` 32×32 solo con texto. Elige 1 de los 64 candidatos (se eligió el 4) y guárdalo en `art/crudo/_ref/txaro.png`.
2. `create_character` mode v3, size 32, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**inaki**
1. `create_image_pro` 32×32 solo con texto. Elige 1 de los 64 candidatos (se eligió el 20) y guárdalo en `art/crudo/_ref/inaki.png`.
2. `create_character` mode v3, size 32, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**cop**
1. `create_image_pro` 32×32 solo con texto. Elige 1 de los 64 candidatos (se eligió el 0) y guárdalo en `art/crudo/_ref/cop.png`.
2. `create_character` mode v3, size 32, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**molina**
1. `create_image_pro` 32×32 solo con texto. Elige 1 de los 64 candidatos (se eligió el 0) y guárdalo en `art/crudo/_ref/molina.png`.
2. `create_character` mode v3, size 32, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**darko**
1. `create_image_pro` 32×32 solo con texto. Elige 1 de los 64 candidatos (se eligió el 1) y guárdalo en `art/crudo/_ref/darko.png`.
2. `create_character` mode v3, size 32, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**jurado**
1. `create_image_pro` 32×32 solo con texto. Elige 1 de los 64 candidatos (se eligió el 0) y guárdalo en `art/crudo/_ref/jurado.png`.
2. `create_character` mode v3, size 32, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**cliente1**
1. `create_image_pro` 32×32 solo con texto. Elige 1 de los 64 candidatos (se eligió el 0) y guárdalo en `art/crudo/_ref/cliente1.png`.
2. `create_character` mode v3, size 32, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**cliente2**
1. `create_image_pro` 32×32 solo con texto. Elige 1 de los 64 candidatos (se eligió el 0) y guárdalo en `art/crudo/_ref/cliente2.png`.
2. `create_character` mode v3, size 32, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**cliente3**
1. `create_image_pro` 32×32 solo con texto. Elige 1 de los 64 candidatos (se eligió el 2) y guárdalo en `art/crudo/_ref/cliente3.png`.
2. `create_character` mode v3, size 32, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**cliente4**
1. `create_image_pro` 32×32 solo con texto. Elige 1 de los 64 candidatos (se eligió el 16) y guárdalo en `art/crudo/_ref/cliente4.png`.
2. `create_character` mode v3, size 32, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**cliente5**
1. `create_image_pro` 32×32 solo con texto. Elige 1 de los 64 candidatos (se eligió el 0) y guárdalo en `art/crudo/_ref/cliente5.png`.
2. `create_character` mode v3, size 32, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**cliente6**
1. `create_image_pro` 32×32 solo con texto. Elige 1 de los 64 candidatos (se eligió el 4) y guárdalo en `art/crudo/_ref/cliente6.png`.
2. `create_character` mode v3, size 32, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**player-combate**
1. `create_image_pro` 64×64 solo con texto. Elige 1 de los 16 candidatos (se eligió el 1) y guárdalo en `art/crudo/_ref/player-combate.png`.
2. `create_character` mode v3, size 64, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**ladron1-combate**
1. `create_image_pro` 64×64 solo con texto. Elige 1 de los 16 candidatos (se eligió el 0) y guárdalo en `art/crudo/_ref/ladron1-combate.png`.
2. `create_character` mode v3, size 64, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**ladron2-combate**
1. `create_image_pro` 64×64 solo con texto. Elige 1 de los 16 candidatos (se eligió el 0) y guárdalo en `art/crudo/_ref/ladron2-combate.png`.
2. `create_character` mode v3, size 64, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**ladron3-combate**
1. `create_image_pro` 64×64 solo con texto. Elige 1 de los 16 candidatos (se eligió el 0) y guárdalo en `art/crudo/_ref/ladron3-combate.png`.
2. `create_character` mode v3, size 64, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**policia-combate**
1. `create_image_pro` 64×64 solo con texto. Elige 1 de los 16 candidatos (se eligió el 3) y guárdalo en `art/crudo/_ref/policia-combate.png`.
2. `create_character` mode v3, size 64, `reference_image_base64` = ese PNG: lo rota a 8 direcciones y queda animable.

**tileset-transiciones** (create_topdown_tileset, opcional)
1. `wang-agua-hierba`: lower «calm blue river water» → upper «short green grass», transition_size 0.25 — guarda el id del tile de hierba (get_topdown_tileset).
2. `wang-tierra-hierba`: lower «packed light brown dirt path» → upper «short green grass», transition_size 0.25, `upper_base_tile_id` = 4e6ae897-6f8a-4ead-b17c-3fe3cbcb51ba.
3. `wang-plaza-hierba`: lower «warm beige square stone plaza pavement» → upper «short green grass», transition_size 0, `upper_base_tile_id` = 4e6ae897-6f8a-4ead-b17c-3fe3cbcb51ba.

**carpa-c-focos** (edit_image_pixen, obligatorio)
1. `undefined`: lower «undefined» → upper «undefined», transition_size undefined.
2. `undefined`: lower «undefined» → upper «undefined», transition_size undefined.

**carpa-c-macetas** (edit_image_pixen, obligatorio)
1. `undefined`: lower «undefined» → upper «undefined», transition_size undefined.
2. `undefined`: lower «undefined» → upper «undefined», transition_size undefined.

**carpa-c-plantas** (edit_image_pixen, obligatorio)
1. `undefined`: lower «undefined» → upper «undefined», transition_size undefined.
2. `undefined`: lower «undefined» → upper «undefined», transition_size undefined.

**carpa-c-focos-cfl** (edit_image_pixen, obligatorio)
1. `undefined`: lower «undefined» → upper «undefined», transition_size undefined.

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
| create_image_pixflux (carpa-cultivo, 1.5) | Una sola carpa abierta de 64×112 con el panel LED pintado encima. En la 1.6 hay carpas de 3 tamaños, cerradas desde fuera y abiertas por dentro, con focos y macetas aparte: carpa-p60/m100/g150 (+ -fuera), focos, macetas y mesa-cultivo. |

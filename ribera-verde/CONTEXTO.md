# Contexto del proyecto

## La petición (5 de octubre de 2026)

> **20:54** · «Buenas, quiero que hagas un juego que sea como el Weed Firm, o sea, las mecánicas del Weed Firm, de cultivo de cannabis y, y descubrir y, y hacer cruces de genéticas también, y luego pues venderlo y demás. En la calle, que te vengan los ladrones y la policía y tengas que sobornar y que luego haya una historia detrás, un guión de todo el juego, con los gráficos de Pokémon. De 8 bits, así de píxeles, ¿eh? Como el Esmeralda. Como el Pokémon Esmeralda, o así.»
>
> **20:56** · «Inspirado en las mecánicas d juego de Weed Firm, con los gráficos de Pokémon Esmeralda»
>
> **21:31** · «Quiero que recojas todo esto en un Zip con contexto y todo»
>
> **22:24** · «Quiero que me des instrucciones para que en Claude Code con la API de Pixel Lab pueda mejorar mediante sprites todos los gráficos del juego, pero a nivel bastante pro, del palo de animaciones y, y eso, pues si hay alguien que, que sea fumador, pues igual que salga en algún momento fumando o lo que sea, o ese tipo de cosas. Pero que se guarde la estética que hemos acordado. Eso sí.»
>
> **23:24** · «En la API de Pixel Lab tienes opciones de crear tanto mapas como personajes, como objetos y también creaciones simples. Entonces deberíamos de catalogar todos los sprites que necesitamos para poder optimizar las creaciones y aprovechar al máximo las herramientas.»

## Cómo se interpretó

| Pedido | Cómo está en el juego |
|---|---|
| Mecánicas de Weed Firm: cultivar | Carpas en el piso (armario de 60 con 2 plantas → carpa de 100 con 4 → de 150 con 6), una bandeja por carpa, macetas de plástico y de tela de 7 a 25 L, focos CFL, sodio y LED de 125 a 720 W con cobertura y factura de la luz; riego, abono, plagas, fases de crecimiento, cosecha con % de THC |
| Descubrir y cruzar genéticas | Mesa de genética y **Genoteca** de 41 variedades (6 de tienda, 16 landraces —1 regalo de Kiko, 3 repartidas por el barrio y 12 en el banco de semillas—, 19 que salen de 20 recetas de cruce) + híbridos propios ilimitados; los cruces nuevos salen F1 y se estabilizan hasta F4 |
| Venderlo en la calle | Clientes con `$` que cambian cada día; tú eliges precio (rebaja, justo o caro) y pueden rechazarlo |
| Ladrones y policía | Encuentros aleatorios al andar por el barrio con mercancía o dinero, y combates por turnos |
| Sobornar | Opción SOBORNAR contra la policía y la «protección» del sargento Molina |
| Historia con guion | 7 capítulos con objetivos, personajes y diálogos: ver [docs/GUION.md](docs/GUION.md) |
| Gráficos tipo Pokémon Esmeralda, pixel art | Resolución de portátil de 16 bits (160 px de alto; de 240 a 400 de ancho según el móvil, solo en horizontal), casillas de 16 px, contorno oscuro, cajas de diálogo con borde azul y flecha roja, combates con plataformas y barras de vida |

## Decisiones

- **Arte original, no copiado.** Pokémon (Nintendo/Game Freak) y Weed Firm son propiedad de sus autores. Se imitan el estilo y las mecánicas, pero no hay sprites, personajes, nombres, fuentes ni marcas de esos juegos. Todo el arte se dibuja por código (`src/js/01-tiles.js`, `02-sprites.js` y `14-render.js`).
- **Un solo archivo web sin dependencias.** Se juega en el navegador o en el móvil, se puede publicar como Artifact de Claude y no necesita instalación.
- **Ambientación propia.** «Ribera Verde» es un barrio ficticio a orillas de una ría, con guiños vascos: txoko, kalimotxo, pintxos, «aupa», «eskerrik asko». Ningún personaje está basado en una persona real.
- **«Genoteca» como Pokédex.** Es el álbum de variedades que da el objetivo de coleccionar.
- **Combates de policía sin vida.** La barra enemiga mide la sospecha (el calor policial). Contra la policía se negocia o se huye; no se le pega.
- **Sprites por familia de PixelLab (v1.3).** Cada sprite sale de la herramienta que mejor lo resuelve. Los personajes llevan rig y plantillas. El terreno va en tiles, kits de edificio y Wang. Lo que se apoya en el suelo se pinta con `create_map_object` sobre el propio mapa. Lo pequeño va en lotes compartidos y las pantallas en img2img. Detalle en [docs/CATALOGO-SPRITES.md](docs/CATALOGO-SPRITES.md). En la 1.5 los kits de edificio se cambiaron por `create_tiles_pro` y las fachadas y la carpa por img2img sobre su huella: lo demás salía en perspectiva o estrecho.
- **El motor de sprites va antes que los sprites (v1.3).** Se probó con un atlas «de calco» del arte actual: si las capturas salen iguales, las anclas cuadran y los créditos se gastan solo en arte.
- **Ajustes tras la prueba automática (v1.1).** Los ladrones de los capítulos altos ganaban casi siempre, así que se suavizaron y ahora la VIDA máxima sube 2 puntos por cada ladrón vencido. Además se corrigieron tres fallos; están en [CHANGELOG.md](CHANGELOG.md).

## Estado (v1.9.0)

- Se juega de principio a fin: capítulos 1 a 7, final y juego libre (capítulo 8).
- `npm test` recorre la historia entera y los sistemas sueltos en 42 pasos: **42/42, 0 errores de JavaScript**, sin atlas y con el atlas de calco.
- **Escala (1.8.0):** decidida y aplicada la opción A de [docs/PLANO.md](docs/PLANO.md): piso de 12 × 8 a 1 casilla = 1 m, carpas como muebles y vista de carpa a 64 px/m con las plantas de cepas de Strainmon (`../assets/plants`).
- **Genética (1.9.0):** las landraces y los híbridos clásicos de Strainmon (`../src/species.js`, sus textos, no sus sprites), con su historia; estabilizar F1 → F4 en la mesa y banco de semillas en el PC desde el capítulo 2.
- **Sprites:**
  - el kit PixelLab (guía, catálogo, manifiesto, referencias, paleta, herramientas y comando `/sprites`) está completo y validado;
  - el motor ya usa el atlas (F2) y `npm run test:arte` da 22/22;
  - F1 generada con PixelLab Pro: el protagonista ya sale del atlas (`base`, `idle`, `walk`), aprobado;
  - F3 (personajes) con la misma receta: los 13 NPC y los 6 clientes salen del atlas con `idle`, `walk` (los que caminan) y sus acciones de ambiente;
  - F3-resto, F4, F5, F6 y F7 (1.5): humos y efectos, gaviotas y palomas, tiles, interiores, fachadas, objetos, carpa, plantas, combate, iconos, cogollos y título salen del atlas, y el protagonista ya tiene sus 8 acciones;
  - F4b (1.5): orillas del río, del camino de tierra y de la plaza con tres Wang encadenados y autotiling por esquinas;
  - F8 (1.6): carpas de 3 tamaños por dentro y cerradas (pixflux img2img sobre su huella), 4 macetas, 3 focos y la mesa de cultivo (lotes de `create_1_direction_object`). 
  - 1.8: carpas del piso y de la vista, macetas y cuarto de cultivo (4 generaciones pixflux) y las plantas de la vista importadas de Strainmon; retirados los sprites de cultivo de la 1.6–1.7. Atlas: 1169 fotogramas.
- `npm run build` es reproducible: dos pasadas dan archivos idénticos byte a byte.
- **Android:** `dist/ribera-verde.apk` (1.9.0, código 10900, siempre en horizontal), generado con `npm run apk`. Probado: firma v2/v3 y zipalign verificados, manifiesto y assets decodificados con apktool, y el `index.html` del APK en Chromium móvil con el botón Atrás. No se ha probado en un dispositivo real.
- **Versión publicada:** el Artifact de Claude (https://claude.ai/artifact/Hj17b8QmVcuFHoHjDQe1Pb) está actualizado a la 1.9.0, con el atlas completo (1169 fotogramas). Es privado: se comparte desde su menú Compartir.

## Limitaciones conocidas

- El equilibrio de la economía y de la dificultad solo se ha probado con el test automático, no con jugadores.
- Sin atlas (`?arte=procedural`) el arte es el procedural sencillo: personajes de 16 × 20 px con 3 fotogramas y plantas en 5 fases.
- La música son 5 bucles cortos. No hay efectos de pasos.
- No hay soporte de mando. En el navegador, la pantalla completa y el bloqueo en horizontal se piden al primer toque y dependen del navegador (en iPhone, Safari no deja bloquear el giro: sale «Gira el móvil»).
- El guardado vive en el navegador: si se borran los datos del sitio, se pierde la partida.
- En las listas, los nombres de híbrido muy largos se cortan con «…».
- Las fuentes embebidas solo traen el alfabeto latino. Los símbolos ★ ▲ ▼ → salen con la fuente del sistema.

## Siguientes pasos sugeridos

1. Probar el APK en un móvil real (la vista de carpa incluida).
2. Revisar el arte nuevo jugando y repetir lo que no convenza (cada asset del manifiesto guarda sus ids, semillas y descartes). Guía: [docs/PIXELLAB.md](docs/PIXELLAB.md); comando `/sprites`.
3. Probar con jugadores y ajustar los números de [docs/GDD.md](docs/GDD.md): precios, calor y probabilidades.
4. Añadir zonas: polígono industrial, monte con cultivo exterior por estaciones y puerto con contrabando.
5. Añadir profundidad al estilo Weed Firm: secado y curado, clientes fijos con encargos, empleados y un segundo local.

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
| Mecánicas de Weed Firm: cultivar | Armario con 2 a 6 macetas: riego, abono, plagas, fases de crecimiento, cosecha con % de THC |
| Descubrir y cruzar genéticas | Mesa de genética y **Genoteca** de 23 variedades (6 de tienda, 4 landraces —1 regalo de Kiko y 3 repartidas por el barrio—, 13 recetas de cruce) + híbridos propios ilimitados |
| Venderlo en la calle | Clientes con `$` que cambian cada día; tú eliges precio (rebaja, justo o caro) y pueden rechazarlo |
| Ladrones y policía | Encuentros aleatorios al andar por el barrio con mercancía o dinero, y combates por turnos |
| Sobornar | Opción SOBORNAR contra la policía y la «protección» del sargento Molina |
| Historia con guion | 7 capítulos con objetivos, personajes y diálogos: ver [docs/GUION.md](docs/GUION.md) |
| Gráficos tipo Pokémon Esmeralda, pixel art | Resolución de portátil de 16 bits (240 × 160), casillas de 16 px, contorno oscuro, cajas de diálogo con borde azul y flecha roja, combates con plataformas y barras de vida |

## Decisiones

- **Arte original, no copiado.** Pokémon (Nintendo/Game Freak) y Weed Firm son propiedad de sus autores. Se imitan el estilo y las mecánicas, pero no hay sprites, personajes, nombres, fuentes ni marcas de esos juegos. Todo el arte se dibuja por código (`src/js/01-tiles.js`, `02-sprites.js` y `14-render.js`).
- **Un solo archivo web sin dependencias.** Se juega en el navegador o en el móvil, se puede publicar como Artifact de Claude y no necesita instalación.
- **Ambientación propia.** «Ribera Verde» es un barrio ficticio a orillas de una ría, con guiños vascos: txoko, kalimotxo, pintxos, «aupa», «eskerrik asko». Ningún personaje está basado en una persona real.
- **«Genoteca» como Pokédex.** Es el álbum de variedades que da el objetivo de coleccionar.
- **Combates de policía sin vida.** La barra enemiga mide la sospecha (el calor policial). Contra la policía se negocia o se huye; no se le pega.
- **Sprites por familia de PixelLab (v1.3).** Cada sprite sale de la herramienta que mejor lo resuelve. Los personajes llevan rig y plantillas. El terreno va en tiles, kits de edificio y Wang. Lo que se apoya en el suelo se pinta con `create_map_object` sobre el propio mapa. Lo pequeño va en lotes compartidos y las pantallas en img2img. Detalle en [docs/CATALOGO-SPRITES.md](docs/CATALOGO-SPRITES.md).
- **El motor de sprites va antes que los sprites (v1.3).** Se probó con un atlas «de calco» del arte actual: si las capturas salen iguales, las anclas cuadran y los créditos se gastan solo en arte.
- **Ajustes tras la prueba automática (v1.1).** Los ladrones de los capítulos altos ganaban casi siempre, así que se suavizaron y ahora la VIDA máxima sube 2 puntos por cada ladrón vencido. Además se corrigieron tres fallos; están en [CHANGELOG.md](CHANGELOG.md).

## Estado (v1.4.0)

- Se juega de principio a fin: capítulos 1 a 7, final y juego libre (capítulo 8).
- `npm test` recorre la historia entera y los sistemas sueltos en 34 pasos: **34/34, 0 errores de JavaScript**, sin atlas y con el atlas de calco.
- **Sprites:**
  - el kit PixelLab (guía, catálogo, manifiesto, referencias, paleta, herramientas y comando `/sprites`) está completo y validado;
  - el motor ya usa el atlas (F2) y `npm run test:arte` da 16/16;
  - F1 generada con PixelLab Pro: el protagonista ya sale del atlas (`base`, `idle`, `walk`), aprobado; el resto sigue procedural.
- `npm run build` es reproducible: dos pasadas dan archivos idénticos byte a byte.
- **Versión publicada:** el Artifact de Claude (https://claude.ai/artifact/Hj17b8QmVcuFHoHjDQe1Pb) está actualizado a la 1.3, con arte procedural porque aún no hay atlas.

## Limitaciones conocidas

- El equilibrio de la economía y de la dificultad solo se ha probado con el test automático, no con jugadores.
- El arte procedural es sencillo: personajes de 16 × 20 px con 3 fotogramas y plantas en 5 fases.
- La música son 5 bucles cortos. No hay efectos de pasos.
- No hay soporte de mando ni pantalla completa.
- El guardado vive en el navegador: si se borran los datos del sitio, se pierde la partida.
- En las listas, los nombres de híbrido muy largos se cortan con «…».
- Las fuentes embebidas solo traen el alfabeto latino. Los símbolos ★ ▲ ▼ → salen con la fuente del sistema.

## Siguientes pasos sugeridos

1. Generar los sprites con Claude Code y PixelLab, empezando por F1, el protagonista como ancla de estilo. Están listos la guía [docs/PIXELLAB.md](docs/PIXELLAB.md), el catálogo [docs/CATALOGO-SPRITES.md](docs/CATALOGO-SPRITES.md) y el comando `/sprites`.
2. Opcional (F4b): orillas con los tres Wang encadenados y autotiling en el motor.
3. Probar con jugadores y ajustar los números de [docs/GDD.md](docs/GDD.md): precios, calor y probabilidades.
4. Añadir zonas: polígono industrial, monte con cultivo exterior por estaciones y puerto con contrabando.
5. Añadir profundidad al estilo Weed Firm: secado y curado, clientes fijos con encargos, empleados y un segundo local.

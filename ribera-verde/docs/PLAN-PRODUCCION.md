# Plan de producción · Ribera Verde

Este documento ordena lo que falta antes de pedir más sprites a PixelLab: qué equipo de cultivo tendrá el juego, cómo se verá, qué láminas hay que pedir, en qué orden y cuánto cuestan. También organiza la historia, los desbloqueos y las ideas.

**Estado:** D1–D6 aprobadas con la recomendación (★) el 6 de octubre de 2026. **P1 y P2 hechos** (datos y reglas en el juego; vista B con arte procedural y medida en el plano). Además, la 1.10 pasa todas las cifras a las reales ([ECONOMIA.md](ECONOMIA.md)): precios, vatios, consumo, gramos, deuda (30.000 €), venta al por mayor, fenotipos, esquejes y el imperio tras la deuda. Sale en la próxima versión, junto con el arte. **P3 en marcha con la vista C (§5.2):** la referencia es la imagen A del tablero de estilos (Clásico). La carpa se ve por dentro a toda la altura de la pantalla, como en la imagen A, y su arte sale de esa imagen (recortes y `edit_image_pixen`), no de las huellas. La pared solo lleva la tela, con sus brillos y sombras y sin la forma del cono; macetas y plantas no llevan la luz pintada; la luz del foco es una capa aparte que se pinta delante de todo. El corte de prueba (sodio, macetas de 7 L e índicas en floración) está **aprobado** (6 de octubre de 2026, 2.ª versión); el resto del arte de la vista C sale de ese arte. La lámina A (CFL y la híbrida de germinando a lista en la carpa de 60) está hecha: la híbrida, redibujada a mano, **aprobada** con la paleta A (7 de octubre de 2026); el CFL, **pendiente de aprobación**. Se han gastado 26 de las 53 generaciones de D6.

Leyenda: **hecho** = ya está en el juego · **aprobado** = decidido, falta hacerlo · **idea** = para más adelante.

## 0. Decisiones (aprobadas)

Se aprobaron todas con la recomendación (★).

| # | Decisión | Opciones |
|---|---|---|
| D1 | Cómo se ve el cultivo por dentro (§4) | A: vista de frente, como en la 1.8 · **B ★: carpa abierta en 3/4, como en la 1.6–1.7 (se quitan el techo, el frente y el lateral derecho; se ven el fondo, la pared izquierda y los focos colgando), pero a escala real** · C: carpas de 4 a 8 casillas en las que se entra andando, como en la 1.6–1.7 (escala ×2,5–×5, choca con las proporciones reales) |
| D2 | Catálogo de carpas (§3.1–3.2) | **★ añadir el armario 80 (sitio A) y la carpa 120 en un sitio C nuevo** · dejar las 3 de ahora |
| D3 | Extras (§3.5) | **★ ventilador, extractor con filtro y riego por goteo** · solo el ventilador · ninguno |
| D4 | Plantas | **★ plantas propias en 3 portes (índica, sativa, híbrida) × 5 fases**, que sustituyen al arte de cepas de Strainmon · seguir con el de Strainmon |
| D5 | Objetos de la casa | **★ rehacer a escala la nevera (×1,9) y las cajas (×1,5) y dejar la cama tal cual** · no tocar nada |
| D6 | Presupuesto de PixelLab | **★ hasta 53 generaciones (21 previstas más reintentos)** · otra cifra |

## 1. Dónde vive cada cosa

| Tema | Documento | Cómo se mantiene |
|---|---|---|
| Petición, decisiones y estado | [CONTEXTO.md](../CONTEXTO.md) | a mano, en cada versión |
| Reglas, fórmulas y economía | [GDD.md](GDD.md) | a mano: es la fuente de los números |
| Historia y diálogos | [GUION.md](GUION.md) | a mano |
| Variedades, historias y cruces | [GENETICA.md](GENETICA.md) | se genera con `npm run docs` |
| Mapas, personajes, objetos y tienda | [MAPA.md](MAPA.md) | se genera con `npm run docs` |
| Escala y medidas de cada sprite | [PLANO.md](PLANO.md) y `plano/` | se genera con `npm run plano` |
| Cómo pedir sprites a PixelLab | [PIXELLAB.md](PIXELLAB.md) | a mano |
| Qué generar y con qué parámetros | `art/manifest.json` | a mano; `npm run sprites:validar` lo comprueba |
| Herramienta, orden y coste de cada sprite | [CATALOGO-SPRITES.md](CATALOGO-SPRITES.md) | se genera con `npm run sprites:catalogo` |
| **Qué falta y en qué orden** | este documento | a mano; al aprobar una decisión, pasa al GDD y al manifiesto |
| Cambios de cada versión | [CHANGELOG.md](../CHANGELOG.md) | a mano |

## 2. Historia y desbloqueos por capítulo

Todo está **hecho**. Lo que añadió P1 va marcado con **(P1)**.

| Cap. | Título | Objetivo | Qué pasa | Growshop | Banco de semillas (PC) | Plazas |
|---|---|---|---|---|---|---|
| 1 | La herencia | Leer la carta, ir a ver a Kiko y sacar la primera cosecha | Heredas el piso de la tía Maite con su armario de 60 | Skunk #1 5 €/semilla, abono 1 L 14 €, insecticida 12 €, bocata 5 €, maceta de tela 11 L 3 € · (P1) ventilador 20 €, LED 100 W 110 € | — | 2 |
| 2 | La calle | Ganar 300 € vendiendo en la calle | Clientes con `$`, primeros ladrones | Lemon Haze 9 €, OG Kush 10 €, spray de pimienta 15 €, maceta de plástico 18 L 2 €, sodio 250 W 85 €, LED 200 W 220 €, carpa 100 × 100 120 € (sitio B) · (P1) extractor con filtro 110 € | Michoacán, Punto Rojo, Thai, Kif y Beldia | 6 |
| 3 | La deuda | Pagar 3.000 € a Don Baltasar en 7 días | Toño te lleva al bar El Ancla: la tía debía 30.000 €. (1.10) Iñaki compra al por mayor | Blueberry 8 €, Mango 7 €, maceta de tela 25 L 4 €, sodio 400 W 100 €, LED 480 W 500 €, bolsas de 50 semillas · (P1) armario 80 90 € (sitio A), riego por goteo 55 € | + Chitral Kush, Nepalese, Congolese, Lamb's Bread y Oaxaca | 6 · (P1) 7 con el armario 80 |
| 4 | Genética | Recoger la mesa de genética y descubrir 8 variedades | Kiko te enseña a cruzar; las líneas nuevas se estabilizan de F1 a F4 | Purple Afghani 8 €, sodio 600 W 120 €, carpa 150 × 100 140 € (sitio B) | + Luang Prabang y Panama Red | 8 · (P1) 9 con el armario 80 |
| 5 | El sargento | Pagar 12.000 € en 10 días | El sargento Molina ofrece su «protección» por 1.500 € | LED 720 W 950 € · (P1) carpa 120 150 € (sitio C) | — | 8 · (P1) 15 con la carpa 120 |
| 6 | La Copa de Ribera | Llevar al jurado 20 g con más de 26,8 % de THC | Darko compite con su Amnesia Haze (26,8 %) | — | — | igual |
| 7 | Libertad | Pagar los últimos 15.000 € en 7 días (la Copa da 5.000 €) | Saldas la deuda de la tía; Baltasar te ofrece trabajo | — | — | igual |
| 8 | Tu imperio (1.10) | Facturar para subir de rango (25.000, 100.000 y 250.000 €) y completar las 41 variedades | Sin deudas; cada rango sube lo que Iñaki carga al día (1, 2, 5 y 10 kg) | — | — | igual |

## 3. Equipo de cultivo

Cada objeto tiene tres cosas: una medida real (para dibujarlo a escala), un efecto en el juego y el momento en que se consigue.

### 3.1 Armarios y carpas

**Hechas** (`CARPAS` en `src/js/09-cultivo.js`; «casillas» = lo que ocupa en el piso). `p80` y `m120` son de P1 (D2): medidas de carpa habituales en tiendas que caben en los sitios del piso.

| id | Modelo | Medida real | Casillas | Plazas | Foco máx. | Maceta máx. | Precio | Sitio |
|---|---|---|---|---|---|---|---|---|
| `p60` | Armario 60×60 | 60 × 60 × 160 cm | 1 | 2 | 250 W | 11 L | de serie (la tía) | A |
| `p80` | Armario 80×80 | 80 × 80 × 180 cm | 1 | 3 (2 delante y 1 detrás, centrada) | 400 W | 18 L | 90 € · cap. 3 | A: sustituye al de 60 (plantas, foco y macetas se quedan) |
| `m100` | Carpa 100×100 | 100 × 100 × 200 cm | 1 | 4 | 480 W | 25 L | 120 € · cap. 2 | B |
| `g150` | Carpa 150×100 | 150 × 100 × 200 cm | 2 | 6 | 720 W | 25 L | 140 € · cap. 4 | B: sustituye a la de 100 |
| `m120` | Carpa 120×120 | 120 × 120 × 200 cm | 2 | 6 (3 × 2) | 720 W | 25 L | 150 € · cap. 5 | C, cuando ya hay carpa en B |

Cada sitio va mejorando así:
- **Sitio A:** `p60` (2 plazas) → `p80` (3).
- **Sitio B:** `m100` (4) → `g150` (6).
- **Sitio C:** `m120` (6).

El máximo pasa de 8 plantas a 15. Para el final se deja como **idea** una carpa de 240 × 120 (12 plazas): en el piso no cabe, así que iría en un segundo local (§7).

### 3.2 Sitios del piso

El piso mide 12 × 8 casillas (1 casilla = 1 m). Las carpas van contra la pared del fondo (y = 2) y se usan con A desde la casilla de delante.

| Sitio | Casillas | Estado | Qué hay al lado |
|---|---|---|---|
| A | (8,2) | hecho | mesas de genética en (5,2) y (6,2) |
| B | (10,2)–(11,2) | hecho | esquina derecha |
| C | (2,2)–(3,2) | hecho (P1) | entre la cama (0,2) y el ordenador (4,2). La planta de adorno de (1,2) se queda; la ventana y el diploma que tapaba pasan a (9,1) y (7,1). Se marca en el suelo cuando ya hay carpa en B |

### 3.3 Focos

**Hechos** (`FOCOS`). Desde la 1.10, con cifras reales: «g/W» son los gramos por vatio de una cosecha (sin abono; abonando, ×1,25), repartidos entre las plazas de la carpa; «ilumina» es el cuadrado que cubre bien; crece y THC, a plena intensidad (400 W/m²). Luz al día con plantas, kWh y montajes de ejemplo en [ECONOMIA.md](ECONOMIA.md).

| id | Foco | Ilumina | g/W | Crece | THC | Riego | Precio |
|---|---|---|---|---|---|---|---|
| `cfl` | CFL 125 W | 60×60 cm | 0,25 | — | — | ×1 | de serie |
| `sodio250` | Sodio 250 W | 70×70 cm | 0,45 | +5 % | +0,3 | ×1,3 | 85 € · cap. 2 |
| `sodio400` | Sodio 400 W | 100×100 cm | 0,5 | +5 % | +0,5 | ×1,4 | 100 € · cap. 3 |
| `sodio600` | Sodio 600 W | 120×120 cm | 0,55 | +5 % | +0,7 | ×1,5 | 120 € · cap. 4 |
| `led100` | LED 100 W | 60×60 cm | 0,65 | +5 % | +0,3 | ×1 | 110 € · cap. 1 (P1): el primer paso por encima del CFL |
| `led200` | LED 200 W | 80×80 cm | 0,7 | +10 % | +0,6 | ×1,05 | 220 € · cap. 2 |
| `led480` | LED 480 W | 120×120 cm | 0,8 | +10 % | +1 | ×1,1 | 500 € · cap. 3 |
| `led720` | LED 720 W | 150×150 cm | 0,85 | +15 % | +1,4 | ×1,15 | 950 € · cap. 5 |

**Cómo es cada foco por fuera** (para dibujarlo):

| Tipo | Forma real | Luz encendida |
|---|---|---|
| CFL | bombilla espiral con un reflector de campana de unos 35 cm | blanca fría |
| Sodio | reflector de aluminio de unos 50 × 40 cm con la bombilla tubular dentro y el balastro aparte | ámbar |
| LED | 100 y 200 W: panel de unos 30 × 30 cm · 480 W: placa de unos 60 × 60 cm · 720 W: 6 barras en un marco de 100 × 100 cm | blanca con un toque rosa |

### 3.4 Macetas

**Hechas** (`MACETAS`). Desde la 1.10, la maceta pone el tope de gramos por planta (unos 8 g por litro de tierra):

| id | Maceta | Tope | Cosecha | Crece | Riego | Plagas | Precio |
|---|---|---|---|---|---|---|---|
| `plastico7` | Plástico 7 L | 56 g | — | — | ×1 | ×1 | de serie |
| `tela11` | Tela 11 L | 92 g | +5 % | +5 % | ×1,25 | ×0,8 | 3 € · cap. 1 |
| `plastico18` | Plástico 18 L | 144 g | — | −5 % | ×0,8 | ×1 | 2 € · cap. 2 |
| `tela25` | Tela 25 L | 210 g | +5 % | — | ×1,1 | ×0,8 | 4 € · cap. 3 |

Medidas reales para dibujarlas (diámetro × alto):
- 7 L: 22 × 20 cm.
- 11 L: 25 × 22 cm.
- 18 L: 30 × 28 cm.
- 25 L: 35 × 26 cm.

**Idea:** una maceta de aire de 15 L (poda las raíces: más crecimiento y más riego).

### 3.5 Extras (hechos en P1, D3)

Van uno por carpa (`EXTRAS` y `S.carpas[ci][id]`). Se compran en el growshop («¿Te lo pongo ya?») y se ponen desde la vista de carpa, igual que el foco.

| id | Extra | Medida real | Efecto en el juego | Precio |
|---|---|---|---|---|
| `vent` | Ventilador de pinza | Ø 15–20 cm | plagas ×0,7 en esa carpa; gasta 25 W día y noche | 20 € · cap. 1 |
| `filtro` | Extractor con filtro de carbón | filtro Ø 20 × 50 cm y extractor Ø 15 cm | Sin filtro, cada carpa con alguna planta en floración suma +2 de calor policial al día por el olor. Con filtro, 0. Se suma después de la bajada diaria del calor (lo prueba el test). Gasta 75 W día y noche | 110 € · cap. 2 |
| `goteo` | Riego por goteo | depósito de 20 L (30 × 25 × 35 cm) con goteros | el agua baja a la mitad de velocidad | 55 € · cap. 3 |

**Ideas:** temporizador y fotoperiodo (18/6 en crecimiento y 12/12 en floración), termohigrómetro (temperatura y humedad en la ficha), malla SCROG (+cosecha, +días) y deshumidificador (moho).

## 4. Vistas y escala

| Dónde | Escala | Qué se ve | Estado |
|---|---|---|---|
| Barrio, piso, tiendas | 1 casilla = 16 px = 1 m (3/4) | Personajes de 27–28 px y carpas cerradas como muebles de 1–2 casillas | hecho (1.8) |
| Vista de carpa, opción A | 64 px/m, de frente | La carpa abierta de frente sobre el fondo de un cuarto | hecho (1.8) · sustituida por la B en P2 |
| **Vista de carpa, opción B ★** | **48 px/m de ancho y de alto, y 24 px/m de fondo (3/4, como el piso)** | La carpa recortada como en la 1.6–1.7: sin techo, sin frente y sin lateral derecho. Se ven el fondo y la pared izquierda de mylar, el suelo, las macetas, las plantas y los focos colgando medio transparentes | **hecho con arte procedural (P2)**; medidas en [PLANO.md §6](PLANO.md#6-vista-de-carpa-b-p2-del-plan-de-producción) y `plano/vista-b.png` |

**Por qué la B.** Recupera el aspecto de las carpas de la 1.6–1.7 (paredes de mylar acolchado, bastidor negro, suelo claro, vistas desde arriba como las paredes de la casa). Las proporciones, en cambio, son reales: una carpa de 150 × 100 × 200 cm mide 72 × 120 px y cabe en los 160 px de alto con margen.

Medidas en la vista B (ancho × alto en px, contando el suelo y la pared):

| Objeto | Real | En la vista B |
|---|---|---|
| Armario 60 | 60 × 60 × 160 cm | 29 × 91 |
| Armario 80 | 80 × 80 × 180 cm | 38 × 105 |
| Carpa 100 | 100 × 100 × 200 cm | 48 × 120 |
| Carpa 120 | 120 × 120 × 200 cm | 58 × 125 |
| Carpa 150 | 150 × 100 × 200 cm | 72 × 120 |
| Maceta 7 L / 25 L | Ø 22 / Ø 35 cm | 11 / 17 de ancho |
| Planta índica, lista | 0,9 × 0,7 m | 34 × 43 |
| Planta sativa, lista | 1,4 × 0,6 m | 29 × 67 |
| Planta híbrida, lista | 1,1 × 0,6 m | 29 × 53 |
| Foco CFL / sodio / LED 480 | 35 / 50 / 60 cm | 17 / 24 / 29 de ancho |

- **Estilizado permitido:** germinando y plántula a ×2, para que se vean (5 y 15 cm reales darían 2 y 7 px).
- **Distancia segura (1.10):** cada maceta va en el centro de su parte de la carpa (separación entre centros: 30 cm en el armario 60, 40 en el 80 y la carpa 120, 50 en las de 100 y 150). La copa de cada planta se dibuja como mucho de lo que cabe sin tocar a las vecinas ni las paredes, menos 4 cm (26, 36 o 46 cm), y su alto, como mucho hasta la distancia de seguridad del foco (`FOCO_SEP`: CFL 10 cm, LED 25–40, sodio 30–50). Las láminas de plantas de P4 tienen que caber en esas cajas: tabla completa en [PLANO.md §6](PLANO.md#6-vista-de-carpa-b-p2-del-plan-de-producción).
- **En el piso no cambia nada:** las carpas cerradas siguen a 16 px/m (celda `carpa_mapa` de 32 × 48). El armario 80 mide 13 × 35 px y la carpa 120, 19 × 42.

## 5. Sprites a pedir a PixelLab

Se usa la receta que ya funcionó en la 1.8 (1 generación por lámina):
1. El motor dibuja una **huella procedural** a escala (`art/crudo/_ref/huella-*.png`, PNG de paleta de 4 bits).
2. PixelLab la convierte con `create_image_pixflux` img2img (`init_image_strength` 130).
3. La lámina se corta por columnas.

Límites de `create_image_pixflux` (comprobados en la herramienta el 6 de octubre): de 16 a 400 px por lado y un área de entre 32 × 32 y 400 × 400 px. Todas las láminas de §5.1 caben. Dos parámetros ayudan:
- `init_image_url` con una URL `data:` evita que el base64 largo se corte por el camino.
- `color_image_base64` fuerza la paleta. Hay que darle los colores aprobados del juego.

Para la vista B, las huellas salen del arte procedural del motor (P2): `npm run sprites:huellas` las deja en `art/crudo/_ref/huella-*-34.png` y `huella-carpas-mapa-5.png`, en la rejilla de celdas de §5.1, con 16 colores como mucho y los cogollos en magenta. Imitan el aspecto de los sprites de la 1.6–1.7 (mylar, bastidor y suelo). Es arte propio.

### 5.1 Láminas (con D1 = B y D2–D5 aprobadas)

| # | Lámina | Contenido | Tamaño | Celda nueva (ancho × alto, ancla) | Gen. | Reintentos |
|---|---|---|---|---|---|---|
| 1 | `cuarto-cultivo-34` | rincón del piso en 3/4: pared, rodapié, suelo de tarima y enchufe | 240 × 160 | `pantalla` | 1 | 2 |
| 2 | `carpas-vista-34` | las 5 carpas recortadas y vacías (60, 80, 100, 120 y 150) | 400 × 128 | `carpa_vista34` 80 × 128, (40, 127) | 1 | 2 |
| 3 | `carpas-mapa` (rehecha) | las 5 carpas cerradas del piso, con la puerta de cremallera | 160 × 48 | `carpa_mapa` 32 × 48, (16, 47) | 1 | 2 |
| 4 | `focos-34` | CFL, 3 de sodio y 4 LED (100, 200, 480 y 720), apagados | 192 × 32 (4 × 2) | `foco34` 48 × 16, (24, 0) | 1 | 2 |
| 5 | `macetas-34` | las 4 macetas con tierra y su plato | 96 × 24 | `maceta34` 24 × 24, (12, 23) | 1 | 2 |
| 6 | `extras-34` | ventilador de pinza, extractor con filtro y depósito de goteo | 96 × 32 | `extra34` 32 × 32, (16, 31) | 1 | 2 |
| 7–9 | `plantas-34-indica` / `-sativa` / `-hibrida` | 5 fases en fila (germinando → lista), cogollos en magenta | 240 × 80 cada una | `planta34` 48 × 80, (24, 79) | 3 | 6 |
| 10 | balanceo | 3 fases (vegetativo, floración y lista) × 3 portes, 4 fotogramas, con `animate_image` | — | `planta34` | 9 | 9 |
| 11 | ventilador | aspas girando, 4 fotogramas, con `animate_image` | — | `extra34` | 1 | 1 |
| 12 | `iconos-equipo` | iconos de 16 px de los objetos nuevos (armario 80, carpa 120, LED 100 y los 3 extras) | 96 × 16 | `icono` | 1 | 2 |
| 13 | `nevera` y `cajas` | a escala real: nevera de 60 × 180 cm y cajas de 40 cm | 32 × 48 | `objeto_alto` | 1 | 2 |
| | **Total** | | | | **21** | **+32 → 53 como mucho** |

`animate_image` no tiene coste publicado. Hay que medir el saldo antes y después de la primera llamada y apuntarlo en `coste_real`.

### 5.2 Vista C: la carpa por dentro, desde la imagen A (P3)

La lámina 1 (`cuarto-cultivo-34`, pixflux sobre la huella) no se aprobó porque no se parecía a la imagen A. La vista elegida es la **C**: la carpa por dentro a toda la altura de la pantalla, como la imagen A. Todo su arte sale de la imagen A. A los lados de la carpa, el cuarto queda a oscuras (negro): en las carpas estrechas y en los móviles más anchos que 3:2 se ve esa banda.

**Cómo se hace:**
1. **Fondo.** La imagen A se vació con `edit_image_pixen` (sin plantas ni macetas; otra edición sin el foco). `capas.py` la separa en dos sprites de 240 × 160 (`carpa-c-fondo`, hasta 32 colores por ser fondos de pantalla entera):
   - `carpa-c-pared`: solo la tela, con sus brillos y sombras. La 1.ª versión pasaba cada tono de la luz al gris de su luminosidad y la pared se quedaba con la silueta del cono. Ahora la pared del fondo sale de una 3.ª edición (`tela.py`): la zona del cono, aplanada al tono de la tela, y pixen le pone arrugas como las de las esquinas.
   - `carpa-c-luz`: la luz del foco, una capa aparte (`cono.py`): los tonos claros de la luz de la imagen A en un cono recto desde la boca del foco, con una banda tenue en los huecos, más el charco del suelo y los brillos de las cortinas. Se pinta **delante de todo** (pared, macetas y plantas) en modo `overlay`, debajo de la campana, y no se pinta con el foco apagado.
   - Macetas y plantas no llevan la luz pintada: los brillos cálidos de la maceta pasan a gris y los verdes amarillentos de las hojas, a verde. La luz se la pone la capa del foco.
2. **Escala de cada carpa.** Es `Z = 134 / (alto − 28)` px/cm: 1,02 en la de 60, 0,88 en la de 80 y 0,78 en las de 200 cm. Así la boca del foco (y = 16, como en la imagen A) queda a su altura real sobre el suelo (y = 150).
   - La pared del fondo se recorta al ancho de la carpa, centrada entre los laterales de la imagen A. Mide 61, 71, 78, 93 y 117 px.
   - Las macetas van en el centro de su parte: una fila en y = 152, o dos filas, en 146 (detrás) y 156 (delante).
   - La copa y el alto de cada planta respetan la distancia segura de §4 (`q.cw` × `q.ch`) a esa escala. Como el sprite de la maceta es algo más alto que la real, el alto también se acota en pantalla: la cima queda al menos a `FOCO_SEP` × Z de la boca del foco.
3. **Sprites.** Se hacen con `edit_image_pixen` (1 generación) sobre los recortes de la imagen A. Se piden al tamaño real, con «spans the full canvas» (con «smaller», PixelLab encoge el dibujo y deja margen).

| Sprite | De dónde sale | Tamaño | Gen. |
|---|---|---|---|
| `carpa-c-pared`, `carpa-c-luz` | 3 ediciones de la imagen A + `capas.py`, `tela.py` y `cono.py` | 240 × 160 | 3 |
| `foco-c-46` / `-40` / `-44` | la campana de la imagen A (recorte) y 2 ediciones | 46, 40 y 44 px | 2 (+2 descartes) |
| `maceta-c-22` / `-15` | la maceta de la imagen A, a 22 y 15 px (7 L: la de 22 en las carpas de 60 y 80, la de 15 en las de 200 cm) | 24 × 28, 16 × 16 | 2 (+1 descarte) |
| `planta-c-i-24` / `-36` | la planta de la imagen A: índica en floración con la copa de la carpa de 60 y de las de 200 cm. **Retirada:** la sustituye la planta A | 24 × 84, 36 × 68 | 2 |
| `foco-c-cfl-36` | lámina A: edición de `foco-c-46` en un CFL de 125 W (35 cm); vale para la de 60 y la de 80 | 34 px en un lienzo de 36 × 16 | 1 |
| `planta-c-h-24`, `-h2-24`, `-h1-18`, `-h0-8` | lámina A: la híbrida (Skunk #1) de la carpa de 60, dibujada a mano (`tools/sprites/a-mano/`, paleta A): hojas de abanico, colas a los dos lados del tallo, pistilos naranjas. Más alta = más nudos (un nudo cada 5-10 filas): lista y floración, un dibujo por alto de 99 a 40 px (11 a 3 nudos); vegetativo, de 52 a 18, sin cogollos; plántula, cotiledones y hojas de 1, 3 y 5-7 foliolos. La de antes (tramos de `planta-c-i-24` y pixen) no se leía como cannabis. **Retiradas** `-h-24` y `-h2-24`: las sustituye la planta A, que se lleva la plántula y el germinando | 24 × 99 (a 40), 23 × 52 (a 18), 16 × 28 y 8 × 8 | 4 (todas descartadas) |
| `planta-c-<porte>-38` / `-32`, `-<porte>2-38` / `-32` (porte `i`, `h`, `s`), `-h1-18`, `-h0-8` | planta A (`carpa-c-plantas-a`), dibujada a mano (`tools/sprites/a-mano/planta_a.py`, paleta A), aprobada con la lámina de genética: baja, despuntada y en mainline; corona de 6 ramas con las colas en zigzag (3 detrás, más altas) y aire entre las puntas, lollipop, yemas en pares cruzados con sus hojas, cogollos de cálices con pistilos y tricomas. Vegetativo: la misma corona con hojas de abanico en cada nudo y un brote en cada punta. La genética da la forma (`ind` de 0 a 1: foliolos, internudo y colas; los portes, con 0,9, 0,5 y 0,1). Un fotograma por alto, de 2 en 2 filas: floración y lista, índica 66–40, híbrida 72–44 y sativa 92–54 (80 en la de 32); vegetativo, 36–24, 42–28 y 46–32 | 38 y 32 px en una celda de 40 × 96 | 0 |

- Los cogollos van en la rampa clave magenta y el motor les pone el color de la cepa. Los verdes de hoja y tallo se mueven en tono, luz y saturación hasta el tono de hoja de la planta (el de su variedad, corrido por el % índica de su fenotipo).
- Cada sprite trae un fotograma cada 2 filas de alto y el motor dibuja el de la planta. Si es 1 fila más baja, o más baja que el fotograma más bajo, pierde filas enteras, sin escalar: las que tienen menos píxeles, por debajo del 40 % de arriba; la base del tallo nunca.
- **Nombres.** Las campanas de sodio son `foco-c-NN`; las demás llevan su tipo (`foco-c-cfl-NN`). Floración y lista comparten `planta-c-<porte>-NN`; el vegetativo lleva el 2 pegado al porte (`planta-c-i2-`, `-h2-`, `-s2-`); germinando y plántula, iguales para todos los portes, `planta-c-h0-` y `-h1-`. NN es el ancho en px: se elige el más ancho que deja 2 px de aire en pantalla con las plantas de su fila y 1 con las paredes y, si ninguno cabe, el más estrecho.
- **Luz de cada tipo de foco.** La del sodio es `carpa-c-luz` tal cual; la del CFL, la misma capa con su color frío y al 60 % (`LUZ_C`). Apagado, el tubo del CFL pasa a gris.
- **Mientras falte arte** para algo de la carpa, se ve la vista B. Faltan los focos LED, el CFL en las carpas de 200 cm (su campana sería de 27 px), las macetas de tela y de 18 L y los extras. Las plantas ya están todas (3 portes, 5 fases).

### 5.3 Descripción base de cada lámina

Las descripciones van en inglés, que es como las entiende PixelLab. A todas se les añade la cola de estilo del manifiesto: contorno oscuro de 1 px, sombreado de 3 tonos con la luz arriba a la izquierda, sin antialiasing, sin texto y fondo transparente salvo en el fondo del cuarto.

1. **Cuarto:** «plain corner of a small city flat seen from the front and slightly above (3/4 view) for a 16-bit handheld game scene: cream painted wall, white skirting board, warm light wooden plank floor in perspective, one wall power socket; no furniture, no people».
2. **Carpas abiertas:** «five open indoor grow tents of different sizes in a row, 3/4 view from the front and above, cut-away: roof, front wall and right wall removed; quilted silver reflective mylar back and left walls, black metal frame poles, light silver floor sheet, a hanging bar on top; empty, no plants, no lamps».
3. **Carpas cerradas:** la descripción de la 1.8 (`carpas-mapa`), con 5 tamaños en vez de 3.
4. **Focos:** «hanging grow lamps seen from the front and slightly above, switched off: a spiral CFL bulb in a small bell reflector; three aluminium hood reflectors of growing size; four LED fixtures: small square panel, medium panel, large square board, wide frame of six light bars; thin hanging ropes».
5. **Macetas:** la de la 1.8 (`macetas-vista`), en 3/4 y con plato.
6. **Extras:** «clip-on desk fan; cylindrical carbon filter attached to an inline duct fan with a short silver flexible duct; small square water tank with thin drip tubes».
7. **Plantas:** «cannabis plant at five growth stages in a row, from sprout to ready-to-harvest, [bushy short wide leaves | tall thin narrow leaves | medium], realistic proportions, buds in magenta, no pot». Los cogollos van en magenta porque el motor cambia esa rampa por el color de cada variedad.

### 5.4 Luces, sombras y animaciones (motor, sin coste)

| Qué | Cómo | Estado |
|---|---|---|
| Luz del foco | Cono con `lighter` detrás de las plantas, del color de cada tipo (`FOCO_LUZ`). Si fuera delante, cambiaría los colores de los cogollos | hecho (1.8) · **aprobado**: pasarlo a la vista B (P2) |
| Luz bajo la puerta | En el piso, con plantas vivas | hecho |
| Sombras | Bajo los personajes (`sombra()`) | hecho · **aprobado** (P5): también bajo macetas y muebles, y el suelo de la carpa más oscuro lejos del foco |
| Noche | El piso se oscurece y las carpas encendidas dejan una mancha de luz delante | aprobado (P5) |
| Balanceo de las plantas | Fotogramas de `animate_image` (lámina 10), con el ventilador encendido más rápido | aprobado (P4) |
| Ventilador y extractor | Aspas en bucle (lámina 11). El extractor tiembla 1 px | aprobado (P5) |
| Riego, polen y brillo de cosecha | VFX del atlas (`vfx-gotas`, `vfx-polen`, `vfx-brillo`) | hecho |

## 6. Orden de producción y criterios de aprobado

| Paso | Qué | Gen. | Se da por bueno cuando… | Estado |
|---|---|---|---|---|
| P0 | Decidir D1–D6 | 0 | están respondidas en este documento | hecho |
| P1 | Datos: `p80`, `m120`, sitio C, `led100` y extras en `09-cultivo.js` y en la tienda; reglas en el GDD; migración de partidas | 0 | `npm test` en verde con pasos nuevos (comprar el armario 80, montar la carpa 120 en C, el filtro anula el calor por olor) y una partida de la 1.9 que carga igual | hecho |
| P2 | Vista B con el arte procedural (huellas) y medidas en `npm run plano` | 0 | todas las piezas entre ×0,75 y ×1,33 de su medida real (salvo lo estilizado de §4) y capturas de las 5 carpas | **hecho**: 29 de 35 piezas entre ×0,94 y ×1,06; germinando y plántula a ×2 (estilizado); `plano/vista-b.png`; huellas de las láminas 1–9 con `npm run sprites:huellas` |
| P3 | Láminas 1–6 | 6 (+12) | cada lámina cumple §5 y [PIXELLAB.md §8](PIXELLAB.md) (≤ 15 colores por sprite, salvo los fondos de 240 × 160 de la vista C, hasta 32; contorno, sin texto) y tú la apruebas viendo la captura | **en marcha**: vista C desde la imagen A (§5.2); corte de prueba (sodio, macetas de 7 L e índicas en floración) **aprobado**; lámina A: la híbrida, dibujada a mano, aprobada; el CFL, pendiente de aprobación; falta el resto de su arte |
| P4 | Plantas, láminas 7–10 | 12 (+15) | 3 portes × 5 fases a escala, con el cogollo en la rampa magenta (lo comprueba el test de la rampa) | pendiente |
| P5 | Láminas 11–13, luces y sombras | 3 (+5) | `npm run test:arte` en verde y capturas de día y de noche | pendiente |
| P6 | Cierre: docs, `npm run plano`, capturas, APK y Artifact | 0 | CHANGELOG, CONTEXTO y CLAUDE.md al día; APK y Artifact publicados | pendiente |

**Reglas:**
- No se regenera nada que ya esté aprobado.
- Cada lámina se aprueba antes de pedir la siguiente.
- Los descartes se apuntan en el manifiesto con su motivo.
- Nada de marcas, logos ni personajes de otros juegos.
- Ningún menor fuma.

## 7. Banco de ideas

| Área | Idea | Estado |
|---|---|---|
| Genética | Landraces e híbridos clásicos de Strainmon con su historia, estabilizar de F1 a F4 y banco de semillas | hecho (1.9) |
| Genética | Fenotipos (estrella y floja, con la probabilidad según la pureza de la genética), esquejes y semillas en sobres y a granel | hecho (1.10) |
| Genética | Semillas regulares y machos; cruces nuevos en el growshop | idea |
| Economía | Cifras reales: precios, vatios, consumo, gramos por vatio, tope de la maceta, multas y deuda de 30.000 € | hecho (1.10) |
| Calle | Venta al por mayor (Iñaki) e imperio tras la deuda: rangos por facturación que suben la carga diaria | hecho (1.10) |
| Cultivo | Secado y curado (los gramos y el THC mejoran con los días) | idea |
| Cultivo | Fotoperiodo con temporizador, termohigrómetro, malla SCROG y deshumidificador | idea (§3.5) |
| Cultivo | Segundo local (bajo o nave) con la carpa de 240 × 120 | idea |
| Calle | Clientes fijos con encargos de una variedad concreta | idea |
| Calle | Empleados (un camello que vende por ti con un riesgo) | idea |
| Mundo | Zonas nuevas: polígono industrial, monte con cultivo exterior por estaciones y puerto con contrabando | idea |
| Arte | Proporciones reales en todo, más luces, sombras y animaciones | este plan (§4–§6) |
| Arte | Personajes que se salen de escala (Unai ×1,3, Txaro ×1,13) y exterior comprimido (convención del género) | idea: se deja como está salvo que se pida |
| Juego | Pantalla de cultivo menos estática: ver las 2–3 carpas a la vez en un «rincón de cultivo» y pasar de una a otra con la cruceta | idea (encaja con la vista B) |

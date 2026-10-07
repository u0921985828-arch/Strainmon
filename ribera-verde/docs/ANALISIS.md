# Análisis · guion, misiones y riesgos de la calle (1.10)

Revisión de la historia y de sus misiones, de lo que puede pasarte por la calle (ladrones, controles de policía, sobornos, calor y redadas) y una propuesta de **caja fuerte** en el piso. Las cifras salen del código de la 1.10. Las tablas marcadas como generadas las escribe `node tools/analisis-riesgos.js` con un modelo exacto (las mismas reglas que el código). Después, el mismo script juega cada caso con las funciones de verdad del juego (`onStepEnd`, `thiefRound`, `copRound`, `newDay`, `talkClient`, `talkInaki`, `ventaMayor`, `harvest`) y para con un error si alguna cifra no cuadra.

<!-- auto:meta -->
Generado con `node tools/analisis-riesgos.js` (20.000 combates o controles simulados por fila y 100.000 pasos por situación). Gramos a 7,60 €/g (precio de calle de una variedad del 18 %).
<!-- /auto:meta -->

## Resumen

| # | Hallazgo | Gravedad | Propuesta |
|---|---|---|---|
| 1 | **Todo lo que tienes va siempre encima.** Hay un solo dinero (`S.money`) y una sola bolsa de cogollos (`S.buds`), y la mochila los muestra como «N g encima». Un control te quita **todos** los gramos, aunque la cosecha «esté en casa». Un ladrón que te deja KO se lleva la mitad de todo y el 30 % de todo el dinero. | Alta | La caja fuerte (§ 3) |
| 2 | **El capítulo 4 se salta solo.** Pide descubrir 8 variedades. Antes de llegar se pueden tener 8 sin cruzar nada: Skunk #1, Lemon Haze, OG Kush y 5 landraces del ordenador ya en el capítulo 2. En cuanto Kiko te da la mesa, empieza el capítulo 5. | Alta | Contar solo variedades obtenidas en la mesa (p. ej., 4 cruces nuevos) |
| 3 | **El plazo del capítulo 3 no corre hasta que entras al bar.** Toño dice «Hoy», pero los 7 días empiezan al hablar con Baltasar (`flags.metB`). Si no vas, no hay plazo. | Media | Que el plazo empiece con el aviso de Toño, o que Toño venga a buscarte a los 2 días |
| 4 | **No hay derrota.** Si vence un plazo, Toño suma un 20 %, te quita 15 de vida y da 5 días más, sin límite. | Media (puede ser a propósito) | A la tercera vez, que Toño se lleve algo del piso (una carpa o la caja) |
| 5 | **Dos hilos sin cerrar.** «Esto no se acaba aquí. Mi tío se va a enterar», dice Darko al perder la Copa, pero `flags.copa` no se lee en ningún sitio. Baltasar te ofrece trabajo al saldar la deuda y no pasa nada más. Además, «lejos de mis esquinas» no tiene ninguna regla detrás. | Media | Un robo de Darko en el capítulo 7 (§ 3.6) y un encargo de Baltasar en el imperio |
| 6 | **Al por mayor sale unas 70 veces más a cuenta que vender en la calle** en calor por euro. Desde el capítulo 3, la calle solo sirve para la reputación. | Media | Subir el calor del por mayor o limitarlo por reputación |
| 7 | **Sobornar siempre es lo mejor** en un control si te llega el dinero. Su precio no depende de lo que llevas encima: en el capítulo 8 son 1.740 € con 40.000 € en el bolsillo. | Media | Que el precio suba con el dinero que llevas, o que el agente honrado sea más probable con más calor |
| 8 | **Los ladrones casi nunca ganan si peleas**: por debajo del 0,1 % de KO con la mejor estrategia. El peligro real son los controles. | Baja | Que el ladrón pegue más desde el capítulo 5, o un «tirón» al primer turno |
| 9 | **La Copa se puede preparar en cuanto empieza el capítulo 4**: son 4 cruces sin cultivar nada entre medias. Con una buena carpa, la primera cosecha llena de Amnesia Haze gana 8 de cada 10 veces. | Baja | Aceptable. Si se quiere más reto, que Darko suba su marca cada vez que pierdes |
| 10 | El objetivo del capítulo 2 dice «vendiendo en la calle», pero también cuentan las ventas a Iñaki (`S.sales`). | Muy baja | Cambiar el texto a «vendiendo» |

## 1. Guion y misiones

### 1.1 La historia, capítulo a capítulo

| Cap. | Objetivo | Qué lo cumple (código) | Plazo | Recompensa o consecuencia |
|---|---|---|---|---|
| 1 · La herencia | Leer la carta, ver a Kiko, primera cosecha | `flags.letter`, `flags.kiko1`, `flags.harvest1` | — | 3 semillas de Skunk #1 y 2 dosis de abono. Empiezan los clientes, los controles y los ladrones |
| 2 · La calle | Vender por 300 € | `S.sales ≥ META_VENTAS` (cuenta también Iñaki) | — | Darko te avisa al entrar en la plaza por el norte. Toño te cita en el bar |
| 3 · La deuda | Pagar 3.000 € a Baltasar | Pago en el bar | 7 días **desde que hablas con él** | Mesa de genética y 3 semillas de Afghani (Kiko) |
| 4 · Genética | Descubrir 8 variedades | `discCount() ≥ 8` con la mesa | — | Plazo de 12.000 € en 10 días. Aparece Molina |
| 5 · El sargento | Pagar 12.000 € | Pago en el bar | 10 días | Molina: protección por 1.500 € (o +10 de calor si dices que no). Al pagar, la Copa |
| 6 · La Copa | 20 g de un lote con más de 26,8 % de THC | `talkJurado`: `round(thc·10)/10 > 26,8` | Ninguno (se puede repetir) | 5.000 € y +20 de reputación. Plazo de 15.000 € en 7 días |
| 7 · Libertad | Pagar 15.000 € | Pago en el bar | 7 días | Pantalla final y capítulo 8 |
| 8 · Tu imperio | Facturar 25.000 / 100.000 / 250.000 € desde el último pago | `imperioNivel()` | — | Iñaki carga 2, 5 y 10 kg al día. Genoteca de 41 y la Ghost Train Haze |

Si un plazo vence (capítulos 3, 5 y 7), Toño suma un 20 % del plazo (redondeado a 100 €), te quita 15 de vida y da 5 días más. Se repite sin fin.

### 1.2 Misiones secundarias y secretos

| Quién o qué | Dónde | Pide | Da | Notas |
|---|---|---|---|---|
| Abuela Txaro | Parque (3, 18) | 5 g, una vez | 2 semillas de Hindu Kush y 3 bocatas | La única misión con historia propia. No tiene continuación |
| Iñaki | Muelle (37, 21), desde el cap. 2 | 10 g al día | 1,2 × el precio de la calle. La primera vez, 2 semillas de Malawi Gold | Desde el cap. 3 compra al por mayor (§ 1.4) |
| Ordenador de la tía | Piso | Dinero | Sobres de 10 semillas de 12 landraces (5 desde el cap. 2, 5 desde el 3 y 2 desde el 4). Llegan al día siguiente | Cuentan para el objetivo del cap. 4 |
| Arbustos del parque | (2, 26), (9, 16) y (10, 24): A delante | — | 2 semillas de Acapulco Gold, 50 € y 1 insecticida | Josune y Unai dan la pista |
| Bolsas en el suelo | (8, 25), (36, 24) y (15, 23) | — | 2 sprays, 3 abonos y 2 bocatas | — |
| Patxi | Fuente de la plaza | — | Desde el cap. 4, una pista de receta por visita (11 en total) | Antes del cap. 4 solo dice que vuelvas |
| Kiko | Growshop | — | Consejos por capítulo. Si te quedas sin nada, 2 semillas de Skunk #1 | Evita que la partida se atasque |
| Josune | Bar | 3-4 € | Vida y rumores | Los rumores adelantan a Molina y a Darko |
| Ghost Train Haze | Mesa de genética | Amnesia Haze × Fire OG | SMS de Kiko | Es la meta del final, junto a la genoteca |

### 1.3 Problemas del guion y propuestas

1. **El capítulo 4 no se juega.** La mesa llega con 3 semillas de Afghani, y para entonces lo normal es tener ya 8 variedades o más: Skunk #1, Lemon Haze y OG Kush (tienda, cap. 2), Blueberry y Mango (tienda, cap. 3), Malawi Gold (Iñaki), Hindu Kush (Txaro), Acapulco Gold (arbusto) y las landraces del ordenador. `checkStory` comprueba `discCount() ≥ 8` en cuanto Kiko te da la mesa, así que el capítulo dura un diálogo. **Propuesta:** el objetivo pasa a ser «Consigue 4 variedades nuevas en la mesa» (un contador `S.cruces` que sube con cada cruce que descubre algo). Kiko ya lo anuncia así: «Algunos cruces dan variedades conocidas. Otros, híbridos que solo tendrás tú».
2. **Toño dice «Hoy» y no pasa nada.** El plazo de 3.000 € empieza al sentarte con Baltasar. **Propuesta:** `S.deadline = S.day + 7` al aparecer Toño, y Baltasar te recibe con «Llegas tarde» si han pasado más de 2 días.
3. **Darko amenaza dos veces y no cumple.** «Vende lo tuyo, pero lejos de mis esquinas» (cap. 2) y «Mi tío se va a enterar» (al ganar la Copa). **Propuesta:** en el capítulo 7, una noche entran a robar en el piso (§ 3.6). Así la caja fuerte tiene un momento en la historia y la amenaza tiene consecuencias.
4. **La oferta de Baltasar se queda en el aire.** «Si algún día quieres trabajar para mí, ya sabes dónde estoy». **Propuesta (capítulo 8):** encargos de Baltasar, por ejemplo llevar 2 kg al muelle de noche por un precio mejor que el de Iñaki y con más riesgo. Encaja con el imperio y con las tablas de trayectos (§ 2.3).
5. **No hay derrota.** Los intereses se suman sin fin. Es coherente con un juego tranquilo, pero entonces la presión del plazo es solo de texto. **Propuesta:** al tercer plazo vencido, Toño se lleva la carpa más grande o, si existe, la caja fuerte de sobremesa.
6. **La Copa del sábado.** Baltasar dice «El sábado es la COPA», pero el juego no tiene días de la semana y el jurado está en la plaza todo el capítulo 6. **Propuesta:** quitar «El sábado» o contar el día de la Copa como plazo.
7. **Molina cobra una vez y protege para siempre.** Con 1.500 € no hay redadas en toda la partida, y los controles bajan al 40 %. **Propuesta:** que la cuota se pague por plazo (cada 10 días) o que suba tras la Copa.
8. **Texto del capítulo 2.** El objetivo dice «vendiendo en la calle», pero también cuentan las ventas a Iñaki. Basta con cambiar el texto.

### 1.4 Vender: euros por punto de calor

El calor baja 12 al día (20 con la protección de Molina) y cada carpa con plantas en flor sin filtro suma 2. Lo que puedes vender cada día sin que el calor suba depende de cuánto calor da cada venta:

<!-- auto:eficiencia -->
| Venta (THC 18 %, salvo el pijo) | Cobras | Calor | € por punto de calor |
|---|---|---|---|
| Calle · currela, 8 g a precio justo | 61 € | +7 | 9 € |
| Calle · pijo, 12 g caro (THC 24; acepta el 70 %) | 185 € | +9 | 21 € |
| Iñaki · 10 g para el viaje (una vez al día) | 91 € | +3 | 30 € |
| Al por mayor · 1 kg (una carga al día, hasta 1 kg antes del imperio) | 3.800 € | +6 | 633 € |
| Al por mayor · 10 kg (Mayorista del norte) | 38.000 € | +42 | 905 € |
<!-- /auto:eficiencia -->

Una carga de 1 kg al por mayor da tanto como unas 60 ventas en la calle y sube el calor lo que una sola. Desde el capítulo 3, la estrategia dominante es cultivar mucho y venderlo todo a Iñaki. La calle solo compensa por la reputación (+1 a +3 por venta), que baja el riesgo de los controles cuando hablas y aumenta el número de clientes.

## 2. Riesgos de la calle

### 2.1 Las reglas (08-mundo, 13-combate, 09-cultivo)

- **Encuentros.** Solo en el barrio, desde el capítulo 2, y nunca en los 25 pasos siguientes a otro encuentro. Cada paso tira un único número al azar: control si sale por debajo de *pp* y ladrón si cae entre *pp* y *pp* + *pt*.
  - Control: *pp* = (0,002 + 0,00025 × calor) × (0,4 con protección). Es 0 si no llevas ningún gramo.
  - Ladrón: *pt* = 0,004 × (2,5 de noche, de 21:00 a 6:00) × (3 en hierba alta). Solo si llevas 5 g o más, o 150 € o más.
- **Ladrón.** Tiene 12 + 2 × capítulo + (0 a 4) de vida y pega de 2 + cap/4 a 4 + cap/2.
  - Tus opciones: puñetazo (92 %, 4-7 de daño), patada (65 %, 8-12), spray (seguro, 12-16), hablar (25 % + reputación/300, entre 25 y 70 %) o huir (50 %).
  - Si ganas: +20-40 € + 10 × capítulo, +2 de reputación y +2 de vida máxima (hasta 60).
  - Si caes KO: te roba la mitad de cada lote y el 30 % del dinero, y despiertas en casa 6 horas después.
- **Control.**
  - Sobornar cuesta 40 + 4 × calor + 0,5 × gramos. Sin protección y desde el capítulo 3, un 15 % de agentes son honrados: requisa, multa y +20 de calor (+5 en total, con el −15 de la requisa). Si el soborno sale bien, −10 de calor.
  - Hablar funciona un 30 % + reputación/250 − calor/300 (entre 10 y 85 %).
  - Huir funciona un 45 % (60 % de noche) y suma 8 de calor; si fallas, −5 de vida.
  - Entregar: te quitan los gramos, sin multa.
  - Toda requisa se lleva **todos** los gramos, con una multa de hasta 601 € (lo que lleves, si es menos) y −15 de calor.
- **Calor y redada.** Si el calor está en 90 o más al empezar un día (antes de bajar), hay redada: todas las plantas, todos los gramos y una multa de hasta 3.000 €; el calor queda en 30. Con protección, Molina la para y el calor queda en 50.

### 2.2 Por paso

<!-- auto:paso -->
| Situación | Control por paso | Ladrón por paso | Pasos de media hasta un encuentro | Juego (simulado) |
|---|---|---|---|---|
| Sin nada (0 g, < 150 €) | 0,00 % | 0,00 % | — | 0,00 % · 0,00 % |
| Solo dinero (0 g, ≥ 150 €), de día | 0,00 % | 0,40 % | 250 | 0,00 % · 0,40 % |
| Con gramos, calor 0, de día | 0,20 % | 0,40 % | 167 | 0,20 % · 0,42 % |
| Con gramos, calor 50, de día | 1,45 % | 0,40 % | 54 | 1,45 % · 0,41 % |
| Con gramos, calor 89, de día | 2,43 % | 0,40 % | 35 | 2,44 % · 0,39 % |
| Con gramos, calor 89, con protección | 0,97 % | 0,40 % | 73 | 0,98 % · 0,37 % |
| Con gramos, calor 50, de noche | 1,45 % | 1,00 % | 41 | 1,45 % · 1,02 % |
| Con gramos, calor 50, de noche en hierba alta | 1,45 % | 3,00 % | 22 | 1,45 % · 3,00 % |
<!-- /auto:paso -->

### 2.3 Por trayecto desde casa

Camino más corto desde la puerta del piso (5, 9) con las paredes de verdad (`tileSolid`). Las cifras dan la probabilidad de que el primer encuentro de la ida sea un control o un ladrón, con 50 g y 2.000 € encima. Los personajes que se cruzan no se tienen en cuenta.

<!-- auto:rutas -->
| Ida desde casa | Pasos | En hierba alta | Control / robo (cap. 3, calor 30, de día) | Control / robo (cap. 5, calor 80, de noche) | Control / robo (cap. 5, calor 80, con protección) |
|---|---|---|---|---|---|
| Growshop de Kiko | 14 | 0 | 12,2 % / 5,1 % | 25,1 % / 11,4 % | 11,3 % / 5,2 % |
| Bar El Ancla (Baltasar) | 23 | 0 | 18,9 % / 8,0 % | 36,2 % / 16,5 % | 17,6 % / 8,0 % |
| Plaza (Patxi, clientes) | 27 | 0 | 21,6 % / 9,1 % | 40,2 % / 18,3 % | 20,2 % / 9,2 % |
| Muelle (Iñaki) | 43 | 0 | 31,1 % / 13,1 % | 51,8 % / 23,5 % | 29,2 % / 13,3 % |
| Parque (Txaro) | 10 | 0 | 8,9 % / 3,8 % | 19,1 % / 8,7 % | 8,3 % / 3,8 % |
| Hierba alta del parque (8, 19) | 13 | 2 | 11,4 % / 6,2 % | 23,7 % / 13,5 % | 10,6 % / 6,2 % |
| Arbusto escondido (2, 25) | 19 | 0 | 16,0 % / 6,7 % | 31,7 % / 14,4 % | 14,9 % / 6,8 % |
<!-- /auto:rutas -->

El muelle está lejos: 43 pasos. Con 80 de calor y de noche, una de cada dos idas a ver a Iñaki acaba en control. Ninguna de las rutas normales pisa la hierba alta: solo la que va a ella (2 casillas).

### 2.4 Ladrones

<!-- auto:ladron -->
| Cap. | Tu vida | Estrategia | Ganas | KO (te roban) | Se acaba sin pelea (huyes o se va) | KO en el juego |
|---|---|---|---|---|---|---|
| 2 | 30 | Puñetazo | 100,0 % | < 0,1 % | 0,0 % | < 0,1 % |
| 2 | 30 | Patada | 99,6 % | 0,4 % | 0,0 % | 0,4 % |
| 2 | 30 | Spray ×2 y puñetazo | 100,0 % | 0,0 % | 0,0 % | 0,0 % |
| 2 | 30 | Huir | 0,0 % | 0,2 % | 99,8 % | 0,2 % |
| 2 | 30 | Hablar (rep. 0) | 0,0 % | 7,8 % | 92,2 % | 7,8 % |
| 2 | 30 | La mejor (mínimo KO) | 100,0 % | 0,0 % | 0,0 % | 0,0 % |
| 5 | 40 | Puñetazo | 99,9 % | 0,1 % | 0,0 % | — |
| 5 | 40 | Patada | 99,0 % | 1,0 % | 0,0 % | — |
| 5 | 40 | Spray ×2 y puñetazo | 100,0 % | < 0,1 % | 0,0 % | — |
| 5 | 40 | Huir | 0,0 % | 0,2 % | 99,8 % | — |
| 5 | 40 | Hablar (rep. 0) | 0,0 % | 7,0 % | 93,0 % | — |
| 5 | 40 | La mejor (mínimo KO) | 100,0 % | < 0,1 % | 0,0 % | 0,0 % |
| 8 | 40 | Puñetazo | 85,5 % | 14,5 % | 0,0 % | 14,3 % |
| 8 | 40 | Patada | 88,1 % | 11,9 % | 0,0 % | 12,1 % |
| 8 | 40 | Spray ×2 y puñetazo | 100,0 % | < 0,1 % | 0,0 % | 0,0 % |
| 8 | 40 | Huir | 0,0 % | 0,8 % | 99,2 % | 0,9 % |
| 8 | 40 | Hablar (rep. 0) | 0,0 % | 13,2 % | 86,8 % | 13,3 % |
| 8 | 40 | La mejor (mínimo KO) | 100,0 % | < 0,1 % | < 0,1 % | < 0,1 % |
| 8 | 60 | Puñetazo | 99,9 % | 0,1 % | 0,0 % | — |
| 8 | 60 | Patada | 98,8 % | 1,2 % | 0,0 % | — |
| 8 | 60 | Spray ×2 y puñetazo | 100,0 % | < 0,1 % | 0,0 % | — |
| 8 | 60 | Huir | 0,0 % | 0,1 % | 99,9 % | — |
| 8 | 60 | Hablar (rep. 0) | 0,0 % | 5,1 % | 94,9 % | — |
| 8 | 60 | La mejor (mínimo KO) | 100,0 % | < 0,1 % | < 0,1 % | 0,0 % |
| 5 | 40 | Hablar (rep. 60) | 0,0 % | 0,4 % | 99,6 % | 0,4 % |
| 5 | 40 | Hablar (rep. 150) | 0,0 % | < 0,1 % | 100,0 % | < 0,1 % |
<!-- /auto:ladron -->

<!-- auto:optima -->
Con 40 de vida y 2 sprays en el capítulo 5 (el ladrón tiene de 22 a 26 de vida y pega de 3 a 6), la acción que menos veces acaba en KO es, de entrada: patada si tiene 22-24; spray si tiene 25; puñetazo si tiene 26. Pelear siempre es mejor que huir o hablar con poca reputación.
<!-- /auto:optima -->

- Pelear casi nunca sale mal. El único caso con riesgo serio es el capítulo 8 sin haber subido la vida: 40 de vida contra un ladrón de 28-32, que pega de 4 a 8. A puñetazos, 1 de cada 7 combates acaba en KO.
- Hablar con poca reputación es peor que pelear: si no convence, el ladrón pega igual. Con 60 de reputación ya casi nunca acaba en KO.
- Huir sale bien, pero no da dinero ni vida máxima.
- Lo que hace daño de verdad es el **KO**: la mitad de todos los gramos y el 30 % de todo el dinero. En el capítulo 8, con 40.000 €, son 12.000 € de una vez.

### 2.5 Policía: control y soborno

Requisa = probabilidad de perder los gramos. Pérdida media = euros perdidos de media (dinero y gramos, estos a precio de calle).

<!-- auto:policia -->
| Situación | Sobornar | Hablar | Huir | Entregar | Mejor |
|---|---|---|---|---|---|
| Cap. 2 · calor 20 · rep. 10 · 30 g · 300 € | 135 € · requisa 0 % · −135 € | requisa 73 % · −384 € | requisa 55 % · −290 € | requisa 100 % · −228 € | Sobornar |
| Cap. 4 · calor 60 · rep. 40 · 200 g · 2.000 € · noche | 380 € · requisa 15 % · −641 € | requisa 74 % · −1.570 € | requisa 40 % · −848 € | requisa 100 % · −1.520 € | Sobornar |
| Cap. 5 · calor 85 · rep. 60 · 600 g · 8.000 € | 680 € · requisa 15 % · −1.352 € | requisa 74 % · −3.836 € | requisa 55 % · −2.839 € | requisa 100 % · −4.560 € | Sobornar |
| Cap. 5 · igual, con protección | 680 € · requisa 0 % · −680 € | requisa 74 % · −3.836 € | requisa 55 % · −2.839 € | requisa 100 % · −4.560 € | Sobornar |
| Cap. 8 · calor 50 · rep. 150 · 3.000 g · 40.000 € | 1.740 € · requisa 15 % · −4.989 € | requisa 27 % · −6.240 € | requisa 55 % · −12.871 € | requisa 100 % · −22.800 € | Sobornar |
<!-- /auto:policia -->

- **Sobornar gana en todos los casos** en que llegas al precio. En el capítulo 2 es seguro (los agentes honrados aparecen en el 3). Después, un 15 % sale mal: requisa, multa y +5 de calor.
- **Entregar** nunca es lo mejor: se queda todo y solo te ahorras la multa (601 € como mucho).
- **Hablar** solo compensa con mucha reputación y poco calor. Con 150 de reputación y 50 de calor convence casi 3 de cada 4 veces.
- El agente de patrulla de la plaza (`talkCop`) siempre te hace un control si le hablas con mercancía y sin protección.

### 2.6 Calor y redada

<!-- auto:calorOk -->
Comprobado con el juego: redada con calor 90 y no con 89,9; −12 al día (−20 con protección); +2 por carpa en flor sin filtro; una venta cara de 8 g a un pijo (THC 24, pide 21) acepta un 70,4 % (modelo 70,0 %) y suma 7,0 de calor.
<!-- /auto:calorOk -->

La redada solo se evita bajando del 90 antes de dormir o pagando a Molina. Con varias carpas en flor sin filtro, el olor suma hasta 6 al día y deja muy poco margen para vender en la calle.

### 2.7 La Copa

Para ganar hay que llevar al jurado 20 g de un lote con más del 26,8 % de THC. Los cogollos de una variedad se juntan en un solo lote, con el THC medio ponderado por gramos (`addBuds`). Lo de un fenotipo estrella va a un lote aparte (★).

- **Amnesia Haze** (THC 26), en 4 cruces: Skunk #1 × Lemon Haze → Lemon Skunk; × Lemon Haze → Super Lemon Haze; Acapulco Gold × Afghani → Trainwreck; Super Lemon Haze × Trainwreck → Amnesia Haze.
- **Fire OG** (THC 27), también en 4 cruces: Afghani × Skunk #1 → Critical Mass; × OG Kush → Critical Kush; OG Kush × Blueberry → Blueberry Kush; Critical Kush × Blueberry Kush → Fire OG.

<!-- auto:copa -->
| Planta y equipo | Plazas | THC medio | Una planta pasa de 26,8 % (modelo) | Juego (por planta) | Gramos por planta | Carpa llena: algún lote de 20 g gana (juego) |
|---|---|---|---|---|---|---|
| Amnesia Haze F1 · armario 60 + CFL | 2 | 26,0 % | 33,1 % | 33,2 % | 17 g | 28,3 % |
| Amnesia Haze F1 · carpa 100 + LED 480 W · abono | 4 | 27,3 % | 57,4 % | 57,3 % | 134 g | 66,5 % |
| Amnesia Haze F1 · carpa 150 + sodio 600 W · abono | 6 | 27,0 % | 52,5 % | 52,4 % | 76 g | 58,0 % |
| Amnesia Haze F1 · carpa 120 + LED 720 W · abono | 6 | 27,7 % | 66,9 % | 67,1 % | 142 g | 84,2 % |
| Amnesia Haze estable · carpa 120 + LED 720 W · abono | 6 | 27,7 % | 72,0 % | 72,2 % | 142 g | 90,8 % |
| Fire OG F1 · armario 60 + CFL | 2 | 27,0 % | 52,5 % | 52,4 % | 18 g | 54,3 % |
| Fire OG F1 · carpa 120 + LED 720 W · abono | 6 | 28,7 % | 79,2 % | 79,5 % | 157 g | 98,0 % |
<!-- /auto:copa -->

En el armario de la tía, con un CFL, una planta da menos de 20 g. Hay que juntar las dos, así que la media manda: la Amnesia Haze gana menos de 1 de cada 3 veces. Con luz buena y abono, la primera carpa llena de Amnesia Haze gana 8 de cada 10 veces y la de Fire OG casi siempre. Estabilizar la línea ayuda poco: lo que cuenta es la luz.

## 3. Propuesta: una caja fuerte en el piso

### 3.1 El problema

Hoy el juego no distingue entre lo que llevas encima y lo que tienes en casa. Por eso:

- en cuanto tienes un gramo, todos los pasos por el barrio pueden acabar en control, y el control se lleva **toda** tu cosecha;
- con 150 € o más, hay ladrones;
- un KO se lleva el 30 % de todo lo que has ahorrado, también los 12.000 € del plazo que llevas al bar.

Por eso **no hay ninguna decisión que tomar** sobre qué sacar de casa, que es justo lo que da tensión a una salida.

### 3.2 Diseño

Una caja en el piso, con dos compartimentos: dinero y cogollos (`S.caja = { money, buds }`).

- Lo que guardas no cuenta como «encima» para nada: ni para los encuentros, ni para el soborno, ni para lo que te quitan.
- Se abre con A delante de ella: «Guardar todo / Guardar dinero / Guardar cogollos / Sacar…».
- La mochila separa las dos cosas: «N g encima · M g en la caja».

| Variante | Cómo se consigue | Capacidad | En una redada | Robo de Darko (cap. 7) |
|---|---|---|---|---|
| **A · Caja de sobremesa** | Kiko, desde el cap. 2, 120 € | 5.000 € y 1 kg | La encuentran siempre: requisan los gramos y se llevan la mitad del dinero | Se la llevan entera |
| **B · Caja empotrada** | Ordenador, desde el cap. 4, 380 € (llega al día siguiente; la instala Kiko) | 50.000 € y 2,5 kg | La encuentran un 25 % de las veces | Resiste: se llevan lo que esté fuera |
| **C · La caja de Maite** | Detrás del diploma de la Copa de 1998 (7, 1). La pista está en el registro del ordenador («20 años de cultivos… y la combinación es el año de mi premio») | 20.000 € y 2 kg | La encuentran un 25 % de las veces | Resiste |

La **C** es la que mejor encaja en la historia: da sentido al diploma de la tía, no necesita tienda y conecta con la Copa. Se puede combinar con la A como paso intermedio (o con la B como mejora en el imperio).

### 3.3 Reglas que cambian

| Dónde | Hoy | Con la caja |
|---|---|---|
| `onStepEnd` (encuentros) | `totalBuds()` y `S.money`: todo | Solo lo de fuera de la caja (no cambia la fórmula: lo guardado sale de `S.buds` y `S.money`) |
| `copRound` (soborno) | Paga de todo el dinero | Solo con el que llevas encima: hay que decidir cuánto sacar «por si acaso» |
| `confiscate`, KO del ladrón | Todo | Solo lo de fuera |
| `raidEvent` | Todas las plantas y todos los gramos, multa de hasta 3.000 € | Lo de fuera, siempre. La caja, según la variante. La multa se paga primero de lo de fuera y después de la caja |
| Kiko, ordenador, plazos de Baltasar, Iñaki, jurado | Pagas o vendes de lo que tienes | Igual: solo con lo que llevas. Desde el piso se paga de la caja (ordenador) |
| `harvest` | Los cogollos van a la mochila | Igual. Opcional: «Guardar en la caja» al cosechar, si cabe |
| Partida guardada | — | `S.caja` en `newState` y migración de las partidas viejas (`caja` vacía) |

### 3.4 Efecto: lo mismo, con y sin caja

Pérdida media de un viaje de ida y vuelta: control (con la mejor opción) o ladrón (con la mejor estrategia), con los gramos a precio de calle. «Hoy» = llevas encima todo lo que tienes; «con caja» = solo lo que hace falta para el viaje.

<!-- auto:caja -->
| Ida y vuelta | Hoy: control / ladrón · pérdida media | Con caja fuerte: control / ladrón · pérdida media |
|---|---|---|
| Cap. 3 · ir a comprar a Kiko (200 €) | 22,9 % / 10,0 % · 170 € | 0,0 % / 5,5 % · 0 € |
| Cap. 4 · vender 10 g a Iñaki | 67,8 % / 22,4 % · 789 € | 43,3 % / 11,9 % · 18 € |
| Cap. 4 · vender 40 g en la plaza, de noche | 55,0 % / 35,0 % · 607 € | 32,9 % / 38,5 % · 40 € |
| Cap. 5 · pagar 12.000 € a Baltasar | 57,7 % / 13,8 % · 910 € | 0,0 % / 8,8 % · 0 € |
| Cap. 8 · cargar 2 kg a Iñaki | 67,8 % / 22,4 % · 5.671 € | 43,3 % / 25,9 % · 1.754 € |
<!-- /auto:caja -->

La caja no quita los encuentros del todo: hay que llevar la mercancía para venderla y el dinero para pagar. Lo que hace es que el control cueste lo que llevas, y no todo lo que tienes. Pasa a haber decisiones: cuánto sacar, si llevar dinero para un soborno y cuándo hacer el viaje grande.

### 3.5 Implementación (si se aprueba)

- **HTML:**
  - `08-mundo.js`: `S.caja` y la migración;
  - `11-historia.js` o `09-cultivo.js`: el menú de la caja, la tienda o el ordenador y `raidEvent`;
  - `12-menus.js`: la mochila;
  - `04-mapas.js`: el mueble, en la variante A o B; la C usa el diploma que ya existe;
  - arte original: un sprite de caja de 16 × 16 o el diploma abierto.
- **Godot (0.2.0):** lo mismo en `src/` y en los oráculos. `npm run godot` regenera datos, arte y pantallas, y `tests/historia.gd` tiene que seguir dando 0 diferencias.
- **Tests:**
  - un paso nuevo en `test-historia.js`: guardar, salir con 0 g, ningún control, redada con la caja;
  - este análisis con la regla nueva (`analisis-riesgos.js` ya separa encima y caja en § 3.4);
  - el caso reservado.
- **Docs:** GUION (textos de la caja), GDD, MAPA y CHANGELOG.

### 3.6 El robo de Darko (opcional, capítulo 7)

La primera noche del capítulo 7 que duermas con más de 1.000 € o 100 g fuera de la caja, entran en el piso: «Te despierta un ruido. La puerta está forzada». Se llevan la mitad de lo que haya fuera de la caja (y la caja de sobremesa, si es esa). A la mañana siguiente, un SMS de Darko: «Te dije que esto no se acababa ahí». Así se cierra el hilo de la Copa y la caja tiene un momento en la historia.

## Cómo regenerar

```bash
export CHROMIUM_PATH=$(ls -d /opt/pw-browsers/chromium-*/chrome-linux/chrome | head -1)
npm run analisis                          # tablas de este documento; sale con 1 si el modelo y el juego no coinciden
node tools/analisis-riesgos.js --n 5000   # más rápido (antes, node tools/build.js)
node tools/analisis-riesgos.js --reservado casos.json   # solo comprueba (paso, ladrón, policía y una ruta), no escribe
```

Las tablas se reescriben solas; el texto, no: si cambian mucho, revisa las conclusiones.

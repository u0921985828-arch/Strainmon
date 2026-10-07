# Análisis · guion, misiones y riesgos de la calle (1.10)

Este documento revisa:

- la historia y sus misiones;
- lo que puede pasarte por la calle (ladrones, controles de policía, sobornos, calor y redadas) en las tres zonas: el barrio, el barrio alto y los astilleros;
- la **caja fuerte** del piso.

La primera versión de este análisis encontró 10 problemas (el resumen de abajo). La 1.10 los resuelve todos, y el documento ya describe el juego tal como queda.

Las cifras salen del código de la 1.10. `node tools/analisis-riesgos.js` escribe las tablas generadas con un modelo exacto, que aplica las mismas reglas que el código. Después, el mismo script juega cada caso con las funciones de verdad del juego (`onStepEnd`, `battle` y `thiefRound`, `copRound`, `newDay` y `raidEvent`, `talkClient`, `talkInaki`, `ventaMayor`, `harvest`, `addBuds` y `talkJurado`), también con la caja llena (`S.caja`). Si alguna cifra no cuadra, para con un error y no escribe nada.

<!-- auto:meta -->
Generado con `npm run analisis`: 669 cifras comprobadas con el juego (20.000 combates, controles, ventas o trayectos simulados por celda, 100.000 pasos por situación y 5.000 carpas por fila de la Copa). Gramos a 7,60 €/g (precio de calle de una variedad del 18 %), salvo donde se dice.
<!-- /auto:meta -->

## Resumen

| # | Hallazgo (antes de la 1.10) | Gravedad | En la 1.10 |
|---|---|---|---|
| 1 | **Todo lo que tenías iba siempre encima.** Había un solo dinero y una sola bolsa de cogollos. Un control se llevaba todos tus gramos, aunque la cosecha «estuviera en casa». Un ladrón que te dejaba KO se llevaba la mitad de cada lote y el 30 % de todo tu dinero. | Alta | **La caja fuerte** (§ 3). La de la tía Maite, detrás del diploma (la pista está en el ordenador), y la empotrada, por el ordenador desde el capítulo 4. Lo que guardas no va encima |
| 2 | **El capítulo 4 se saltaba solo.** Pedía 8 variedades descubiertas, y se llegaba a 8 solo comprando semillas. | Alta | El capítulo 4 pide sacar en la mesa 2 variedades de receta y cosechar una planta de cada |
| 3 | **El plazo del capítulo 3 no empezaba hasta que hablabas con Baltasar.** Si no ibas al bar, no había plazo. | Media | El plazo de 7 días empieza cuando aparece Toño. Si tardas más de 2 días en ir al bar, Baltasar te recibe con «Llegas tarde» |
| 4 | **No había derrota.** Un plazo vencido sumaba intereses y te daba 5 días más, sin límite. | Media | Al tercer plazo vencido, Toño se lleva la carpa más grande (B o C) con su foco y sus plantas. Sin carpas, la mitad del dinero que llevas encima |
| 5 | **Tres hilos sin cerrar:** las esquinas de Darko, su «Mi tío se va a enterar» y la oferta de trabajo de Baltasar. | Media | Darko vigila sus esquinas en los astilleros y roba el piso en el capítulo 7 (§ 3.6). Baltasar da encargos en el imperio (§ 1.2) |
| 6 | **Al por mayor daba unas 70 veces más euros por punto de calor que la calle.** | Media | Cada carga suma 2 de calor más 1 por cada 100 g (antes, por cada 250 g). Sigue rindiendo más, unas 35 veces |
| 7 | **El soborno casi siempre era lo mejor en un control, y su precio no dependía de tu dinero.** | Media | El soborno suma el 5 % del dinero que llevas encima. En el capítulo 8, con 40.000 € encima, cuesta 3.740 € (antes, 1.740 €) |
| 8 | **Con spray, los ladrones casi nunca ganaban.** | Baja | Desde el capítulo 5, los ladrones tienen 4 de vida más y pegan 1 más. Con spray siguen perdiendo casi siempre; sin spray, ya no |
| 9 | **La Copa se prepara en cuanto tienes la mesa,** con 4 cruces. | Baja | Sin cambios: aceptable. Baltasar ya no dice «El sábado» (el juego no tiene días de la semana) |
| 10 | El objetivo del capítulo 2 decía «vendiendo en la calle», pero también cuentan las ventas a Iñaki. | Muy baja | «Gana 300 € vendiendo» |

## 1. Guion y misiones

### 1.1 La historia, capítulo a capítulo

| Cap. | Objetivo | Qué lo cumple (código) | Plazo | Al cumplirlo |
|---|---|---|---|---|
| 1 · La herencia | Leer la carta, ir a ver a Kiko (te da 3 semillas de Skunk #1 y 2 dosis de abono) y cosechar | `flags.letter`, `flags.kiko1` y `flags.harvest1` | — | Capítulo 2. Kiko te escribe. Empiezan los clientes, los controles y los ladrones |
| 2 · La calle | Ganar 300 € vendiendo | `S.sales ≥ META_VENTAS` (la calle e Iñaki) | — | Capítulo 3. Toño te corta el paso: «tienes siete días para el primer pago». El plazo empieza ahí (`S.due`, `S.deadline`, `flags.tono`) |
| 3 · La deuda | Ir al bar El Ancla y pagar 3.000 € a Baltasar | Pagar en el bar | 7 días desde que aparece Toño. Si tardas más de 2 días en ir, «Llegas tarde» | Capítulo 4. Kiko te llama: en el growshop te da la mesa de genética y 3 semillas de Afghani |
| 4 · Genética | Sacar en la mesa 2 variedades de receta y cosechar una planta de cada | `recCount() ≥ 2`: `S.rec[id]` vale 1 al sacarla en la mesa y 2 al cosecharla | — | Capítulo 5. Toño te escribe: 12.000 € en 10 días. Aparece Molina |
| 5 · El sargento | Pagar 12.000 €. Molina te ofrece protección: 1.500 € cada 10 días. Si dices que no, +10 de calor | Pagar en el bar | 10 días | Capítulo 6. Baltasar: «La COPA DE RIBERA se juega estos días en la plaza» |
| 6 · La Copa | Llevar 20 g de un lote con más del 26,8 % de THC | `talkJurado`: `round(thc·10)/10 > 26,8` | Ninguno (se puede repetir) | 5.000 € y +20 de reputación. Capítulo 7, con todo lo que queda (15.000 €) en 7 días |
| 7 · Libertad | Pagar 15.000 €. La primera vez que duermas con más de 1.000 € o 100 g fuera de la caja, Darko te roba | Pagar en el bar | 7 días | Pantalla final y capítulo 8. Baltasar te ofrece trabajo |
| 8 · Tu imperio | Facturar 25.000, 100.000 y 250.000 € desde el último pago. Los encargos de Baltasar | `imperioNivel()` | Cada encargo, 2 días | Iñaki te carga 2, 5 y 10 kg al día. La meta final es completar la genoteca de 41 y sacar la Ghost Train Haze |

Si un plazo vence (capítulos 3, 5 y 7), Toño se presenta al cambiar de día:

- Suma un 20 % de lo que debes en ese plazo, redondeado a 100 €. Como el 20 % se calcula sobre lo que ya debes, la deuda crece así: 3.000 → 3.600 → 4.300 → 5.200 €. Ese interés también se suma a la deuda total.
- Te quita 15 de vida, sin bajarte nunca de 1.
- Te da 5 días más.
- Cuenta los plazos vencidos de toda la partida (`S.vencidos`). Al tercero, además, Don Baltasar «se cobra en especie»: Toño se lleva la carpa más grande del piso (la del fondo, B, o la de junto a la cama, C) con su foco, sus extras y sus plantas. Las demás plantas siguen en su carpa y su plaza. Si no tienes ninguna de las dos, se lleva la mitad del dinero que llevas encima. Después, la cuenta vuelve a 0.

### 1.2 Misiones secundarias y secretos

| Quién o qué | Dónde | Pide | Da | Notas |
|---|---|---|---|---|
| Abuela Txaro | Parque (3, 18) | 5 g, una sola vez | 2 semillas de Hindu Kush y 3 bocatas | Después se va a su casa, en la calle (puerta en 34, 8) |
| Abuela Txaro, en casa | Su casa, desde el capítulo 4 | 10 g de una índica (70 % o más) | 3 semillas de Chitral Kush, 3 bocatas y +5 de reputación | Le sirve cualquier lote con un 70 % índica o más, también un cruce propio |
| Iñaki | Muelle (37, 21), desde el capítulo 2 | 10 g al día | 1,2 veces el precio de la calle. La primera vez, también 2 semillas de Malawi Gold | Desde el capítulo 3 también compra al por mayor (§ 1.4) |
| Ordenador de la tía | Piso | Dinero | Sobres de 10 semillas de 12 landraces: 5 desde el capítulo 2, 5 desde el 3 y 2 desde el 4. Llegan al día siguiente | Las notas de la tía dan la pista de la caja. Desde el capítulo 4, con la caja de la tía abierta, la caja empotrada (§ 3) |
| Diploma de la tía | Piso (7, 1) | La combinación: el año del premio (1998) | La caja fuerte de la tía, con 300 € dentro | La rueda ofrece 1976, 1979, 1987 y 1998 |
| Arbustos | Parque: (2, 26), (9, 16) y (10, 24). Barrio alto: (2, 10). Pulsa A delante | — | 2 semillas de Acapulco Gold, 50 €, 1 insecticida y 80 € | Josune y Unai dan la pista del parque. La Acapulco Gold no se vende en ningún sitio |
| Bolsas en el suelo | Barrio: (8, 25), (36, 24) y (15, 23). Astilleros: (4, 5) | — | 2 sprays, 3 abonos, 2 bocatas y 2 sprays más | — |
| Patxi | Fuente de la plaza | — | Desde el capítulo 4, una pista de receta en cada visita (11 en total) | Antes del capítulo 4 solo te dice que vuelvas |
| Kiko | Growshop | — | Un consejo por capítulo. Si te quedas sin nada (sin semillas, sin plantas, sin gramos y con menos de 15 € contando la caja), 2 semillas de Skunk #1 | Así la partida no se puede atascar |
| Josune | Bar | 3-4 € | Vida y rumores | Los rumores adelantan lo de Molina y Darko |
| Sargento Molina | La primera vez, en la plaza (capítulo 5). Después, en la comisaría del barrio alto | 1.500 € cada 10 días | Protección (§ 2.1) | Se puede pagar por adelantado: cada pago suma 10 días. Al acabarse, un SMS |
| Darko | Astilleros (24, 16), desde el capítulo 7 | — | — | Sus chicos vigilan las esquinas de los astilleros: 1 de cada 3 ventas allí acaba en pelea |
| Don Baltasar | Bar, capítulo 8 | Llevar 2 kg (5 kg desde Distribuidor de la ría y 10 kg desde Mayorista del norte) al almacén de los astilleros, de noche, en 2 días | 6 €/g (12.000 € por 2 kg), +2 de reputación y +3 de calor | Toño espera en el almacén de 21:00 a 6:00 y se lleva primero los lotes más flojos. Si no llegas, reputación −10 y 5 días sin encargos |
| Ghost Train Haze | Mesa de genética | Cruzar Amnesia Haze × Fire OG | Un SMS de Kiko | Es la meta del final, junto con la genoteca |

### 1.3 Problemas del guion: cómo quedan

1. **El capítulo 4 ya se juega.**
   - Antes: «descubrir» una variedad era tener sus semillas, y el capítulo pedía 8. Al recibir la mesa, lo normal era tener ya 8 o más, así que el capítulo duraba lo que un diálogo.
   - Ahora pide sacar en la mesa 2 variedades de receta (Critical Mass o Lemon Skunk, por ejemplo) y cosechar una planta de cada. Hay que cruzar, plantar y cultivar al menos una tanda, y las pistas de Patxi empiezan justo aquí. Un cruce libre, un arbusto o las semillas del ordenador no cuentan.
2. **Toño ya no dice «Hoy» en vano.** El plazo de 3.000 € (7 días) empieza cuando aparece. Si tardas más de 2 días en ir al bar, Baltasar te recibe con «Llegas tarde». Las partidas guardadas en el capítulo 3 sin plazo lo reciben al cargarlas: 7 días desde ese día.
3. **Darko cumple su amenaza.**
   - Desde el capítulo 2: «Vende lo tuyo si quieres, pero lejos de mis esquinas». Sus esquinas son los astilleros, donde 1 de cada 3 ventas acaba con uno de sus chicos encima (un combate de ladrón).
   - Al perder la Copa: «Mi tío se va a enterar». En el capítulo 7 entra a robar en el piso (§ 3.6). Desde ese capítulo está en los astilleros.
4. **La oferta de Baltasar tiene continuación:** los encargos del imperio (§ 1.2). Pagan más por gramo que Iñaki, pero hay que cruzar los astilleros de noche con la carga encima.
5. **Ya hay derrota parcial.** Al tercer plazo vencido, Toño se lleva la carpa más grande (§ 1.1). Sigue sin haber «fin de partida»: el juego es tranquilo, pero el plazo ya no es solo texto.
6. **La Copa «del sábado».** Baltasar dice ahora que la Copa «se juega estos días en la plaza»: el jurado está todo el capítulo 6.
7. **Molina cobra cada 10 días.** La protección dura 10 días por pago (`S.protHasta`, el último día cubierto) y se renueva en la comisaría del barrio alto. Cuando se acaba, Molina te manda un SMS y vuelven las redadas, los agentes honrados y la bajada de calor de 12. Las partidas guardadas con protección reciben 10 días al cargarlas.
8. **Texto del capítulo 2:** «Gana 300 € vendiendo».

### 1.4 Vender: euros por punto de calor

El calor baja 12 al día (20 con la protección de Molina), y cada carpa con plantas en flor y sin filtro suma 2. Cuánto puedes vender cada día sin que el calor suba depende del calor que da cada venta:

<!-- auto:eficiencia -->
| Venta (THC 18 %, salvo el pijo) | Cobras | €/g | Calor | € por punto de calor |
|---|---|---|---|---|
| Calle · currela, 8 g a precio justo (acepta el 92 %) | 61 € | 7,63 | +7 | 9 € |
| Calle · pijo del cap. 6 (pide 21 % de THC), 12 g de THC 24 a precio caro (acepta el 70 %) | 185 € | 15,42 | +9 | 21 € |
| Astilleros · currela, 8 g a precio justo (1 de cada 3 ventas, un chico de Darko) (acepta el 92 %) | 73 € | 9,13 | +7 | 10 € |
| Iñaki · 10 g para el viaje (una vez al día) | 91 € | 9,10 | +3 | 30 € |
| Al por mayor · 1 kg (una carga al día, hasta 1 kg antes del imperio) | 3.800 € | 3,80 | +12 | 317 € |
| Al por mayor · 10 kg (Mayorista del norte; el calor no pasa de 100) | 38.000 € | 3,80 | +100 | 380 € |
| Encargo de Don Baltasar · 2 kg (cap. 8, Proveedor del barrio) | 12.000 € | 6,00 | +3 | 4.000 € |
<!-- /auto:eficiencia -->

Por gramo, la calle paga el doble que el por mayor. Pero cada venta en la calle suma 3 de calor más medio punto por gramo, mientras que una carga al por mayor suma 2 más 1 por cada 100 g. Una carga de 1 kg da tanto dinero como unas 60 ventas en la calle y sube el calor lo que menos de dos.

- **Astilleros:** el gramo se paga un 20 % más, pero 1 de cada 3 ventas acaba en pelea con un chico de Darko.
- **Barrio alto:** clientes con más dinero (pijos y turistas) desde el capítulo 3, pero con un 50 % más de policía.
- **Encargos de Baltasar:** lo que más rinde por punto de calor, pero solo uno a la vez, de noche y con 2 a 10 kg encima por los astilleros.

Desde el capítulo 3, lo que más rinde es cultivar mucho y vendérselo a Iñaki. La calle compensa por la reputación: cada venta da de +1 a +3. La reputación ayuda a salir hablando de un control y trae más clientes.

## 2. Riesgos de la calle

### 2.1 Las reglas (08-mundo, 13-combate, 09-cultivo)

- **Zonas.** Hay tres, cada una con su factor de policía, de ladrones y de precio (`ZONAS`):

  | Zona | Cómo se llega | Policía | Ladrones | Precio del gramo |
  |---|---|---|---|---|
  | Ribera Verde (el barrio) | — | ×1 | ×1 | ×1 |
  | Barrio alto | Por el camino del norte de la calle (11-12, 0) | ×1,5 | ×0,5 | ×1 |
  | Astilleros | Por el muelle, al este (39, 20-21) | ×0,5 | ×2 | ×1,2 |

- **Encuentros.**
  - En las tres zonas, desde el capítulo 2. No hay encuentros dentro de las casas.
  - Después de un encuentro vienen 24 pasos tranquilos (`S.cool` se pone a 25 y baja antes de mirar). Los pasos dentro de casa, del growshop o del bar también descuentan.
  - Cada paso tira un único número al azar: si sale por debajo de *pp*, hay control; si cae entre *pp* y *pp* + *pt*, hay ladrón.
  - Control: *pp* = (0,002 + 0,00025 × calor) × (0,4 con protección) × policía de la zona. Si no llevas ni un gramo encima, es 0.
  - Ladrón: *pt* = 0,004 × (2,5 de noche, de 21:00 a 6:00) × (3 en hierba alta) × ladrones de la zona. Solo si llevas encima 5 g o más, o 150 € o más.
  - Lo que está en la caja fuerte no cuenta.
- **Ladrón.** Tiene 12 + 2 × capítulo + (de 0 a 4) de vida. Pega entre 2 + cap/4 y 4 + cap/2 (divisiones enteras). Desde el capítulo 5, 4 de vida más y 1 más de golpe.
  - Puñetazo: acierta un 92 % y quita 4-7.
  - Patada: acierta un 65 % y quita 8-12.
  - Spray: acierta siempre y quita 12-16.
  - Bocata: +15 de vida, sin pasar de tu vida máxima.
  - Hablar: convence un 25 % + reputación/300, entre el 25 y el 70 %.
  - Huir: sale bien un 50 %.
  - Tu vida máxima empieza en 30 y sube 2 con cada ladrón que vences, hasta 60.
  - Si ganas: 20-40 € + 10 × capítulo y +2 de reputación.
  - Si caes KO: se lleva la mitad de cada lote y el 30 % del dinero que llevas encima, y despiertas en casa 6 horas después.
- **Control.**
  - Sobornar cuesta 40 + 4 × calor + 0,5 × gramos + 5 % del dinero que llevas encima. Si no te llega lo que llevas, el agente no lo acepta y vuelves a elegir.
    - Sale bien: −10 de calor.
    - Agente honrado (15 %, desde el capítulo 3 y sin protección): requisa, multa y +20 de calor. Con el −15 de la requisa, son +5 en total.
  - Hablar convence un 30 % + reputación/250 − calor/300, entre el 10 y el 85 %. Si no convence: requisa y multa.
  - Huir sale bien un 45 % (un 60 % de noche) y suma 8 de calor. Si falla: requisa, multa y −5 de vida.
  - Entregar: te quitan los gramos, sin multa, y el calor baja 15.
  - Una requisa se lleva **todos** los gramos que llevas encima y baja el calor 15. La multa es de 601 € (o lo que lleves, si es menos).
- **Calor y redada.** Al cambiar de día (00:00), duermas o no, el juego mira el calor *antes* de bajarlo:
  - con 90 o más, hay redada: se llevan todas las plantas y todos los gramos de fuera de la caja, hay una multa de hasta 3.000 € y el calor queda en 30. La caja la encuentran 1 de cada 4 veces (§ 2.6);
  - con la protección de Molina, la redada se para y el calor queda en 50.

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

Las mismas situaciones en las tres zonas:

<!-- auto:zonas -->
| Situación (cap. 5) | Ribera Verde (el barrio): control / ladrón | Barrio alto: control / ladrón | Astilleros: control / ladrón |
|---|---|---|---|
| Con gramos, calor 50, de día | 1,45 % / 0,40 % | 2,18 % / 0,20 % | 0,73 % / 0,80 % |
| Con gramos, calor 50, de noche | 1,45 % / 1,00 % | 2,18 % / 0,50 % | 0,73 % / 2,00 % |
| Con gramos, calor 50, con protección | 0,58 % / 0,40 % | 0,87 % / 0,20 % | 0,29 % / 0,80 % |
| Solo dinero (0 g, ≥ 150 €), de noche | 0,00 % / 1,00 % | 0,00 % / 0,50 % | 0,00 % / 2,00 % |
| Precio del gramo en la calle | ×1,0 | ×1,0 | ×1,2 |
<!-- /auto:zonas -->

El barrio alto es la zona para ir con dinero (la mitad de ladrones) y los astilleros, para ir sin gramos encima (la mitad de controles, pero el doble de ladrones).

### 2.3 Por trayecto desde casa

Los trayectos siguen el camino más corto desde la salida del piso, que está en (5, 9), justo debajo de la puerta (5, 8). Se usan las paredes de verdad del mapa (`tileSolid`). Cada cifra da la probabilidad de que el primer encuentro de la ida sea un control o un ladrón, llevando 50 g y 2.000 € encima. No cuentan los personajes que se cruzan.

<!-- auto:rutas -->
| Ida desde casa | Pasos | En hierba alta | Control / ladrón (cap. 3, calor 30, de día) | Control / ladrón (cap. 5, calor 80, de noche) | Control / ladrón (cap. 5, calor 80, con protección) |
|---|---|---|---|---|---|
| Growshop de Kiko | 14 | 0 | 12,2 % / 5,1 % | 25,1 % / 11,4 % | 11,3 % / 5,2 % |
| Bar El Ancla (Baltasar) | 23 | 0 | 18,9 % / 8,0 % | 36,2 % / 16,5 % | 17,6 % / 8,0 % |
| Plaza (Patxi, clientes) | 27 | 0 | 21,6 % / 9,1 % | 40,2 % / 18,3 % | 20,2 % / 9,2 % |
| Muelle (Iñaki) | 43 | 0 | 31,1 % / 13,1 % | 51,8 % / 23,5 % | 29,2 % / 13,3 % |
| Parque (Txaro) | 10 | 0 | 8,9 % / 3,8 % | 19,1 % / 8,7 % | 8,3 % / 3,8 % |
| Hierba alta del parque (8, 19) | 13 | 2 | 11,4 % / 6,2 % | 23,7 % / 13,5 % | 10,6 % / 6,2 % |
| Arbusto de la Acapulco Gold (delante, en 2, 25) | 19 | 0 | 16,0 % / 6,7 % | 31,7 % / 14,4 % | 14,9 % / 6,8 % |
<!-- /auto:rutas -->

El muelle es lo más lejano del barrio: 43 pasos. Con 80 de calor y de noche, una de cada dos idas a ver a Iñaki acaba en control. Ninguna ruta normal pisa la hierba alta; solo la que va hasta ella (2 casillas).

### 2.4 Ladrones

<!-- auto:ladron -->
| Cap. | Ladrón: vida · golpe | Tu vida | Puñetazo | Patada | 2 sprays, luego puñetazo | Huir | Hablar (rep. 0) | Hablar (rep. 60) | La mejor, sin spray ni bocata | La mejor, con 2 sprays y 1 bocata |
|---|---|---|---|---|---|---|---|---|---|---|
| 2 | 16-20 · 2-5 | 30 | < 0,1 % | 0,4 % | 0,0 % | 0,2 % | 7,8 % | 0,5 % | < 0,1 % | 0,0 % |
| 5 | 26-30 · 4-7 | 30 | 32,6 % | 18,5 % | < 0,1 % | 1,8 % | 18,6 % | 3,1 % | 1,8 % | < 0,1 % |
| 5 | 26-30 · 4-7 | 40 | 3,6 % | 5,6 % | < 0,1 % | 0,5 % | 11,1 % | 1,1 % | 0,5 % | < 0,1 % |
| 8 | 32-36 · 5-9 | 30 | 98,2 % | 60,5 % | 4,1 % | 4,0 % | 25,9 % | 6,2 % | 4,0 % | 0,3 % |
| 8 | 32-36 · 5-9 | 40 | 65,3 % | 31,4 % | 0,3 % | 1,5 % | 17,2 % | 2,6 % | 1,5 % | < 0,1 % |
| 8 | 32-36 · 5-9 | 60 | 3,8 % | 5,5 % | < 0,1 % | 0,2 % | 7,6 % | 0,5 % | 0,2 % | < 0,1 % |
<!-- /auto:ladron -->

<!-- auto:optima -->
Primera acción de «la mejor» (la que menos veces acaba en KO):
- Cap. 8, 30 de vida, sin spray ni bocata: huir si el ladrón tiene 32-36 de vida (KO 4,0 %).
- Cap. 8, 40 de vida, sin spray ni bocata: huir si el ladrón tiene 32-36 de vida (KO 1,5 %).
- Cap. 8, 30 de vida, con 2 sprays y 1 bocata: puñetazo si el ladrón tiene 32-36 de vida (KO 0,3 %).
- Cap. 5, 30 de vida, sin spray ni bocata: huir si el ladrón tiene 26-30 de vida (KO 1,8 %).
<!-- /auto:optima -->

- **El spray decide.** Cuesta 15 € en la tienda de Kiko desde el capítulo 2. Dos sprays quitan 24-32 de vida, casi toda la del ladrón más fuerte. Con 2 sprays y un bocata, el KO llega como mucho a unas 3 de cada 1.000 veces (capítulo 8, con 30 de vida).
- **Sin spray, desde el capítulo 5 pelear sale caro.** Con 30 de vida, en el capítulo 5 los puñetazos acaban en KO 1 de cada 3 veces y, en el capítulo 8, casi siempre. Lo mejor es huir. Con 60 de vida, pelear vuelve a salir bien.
- **Hablar**, con poca reputación, es peor que huir: si no convence, el ladrón pega igual. Con 60 de reputación queda cerca de huir.
- **Huir** no da dinero ni vida máxima. Ganar sí: así se sube la vida para los capítulos altos.
- Lo que hace daño de verdad es el **KO**: la mitad de los gramos y el 30 % del dinero que llevas encima. Con la caja, solo lo del viaje.

### 2.5 Policía: control y soborno

En la tabla, «requisa» es la probabilidad de perder los gramos, y «−€» es lo que pierdes de media en euros (dinero y gramos, estos a precio de calle). El calor es el cambio medio. La columna «Mejor (en euros)» no tiene en cuenta el calor.

<!-- auto:policia -->
| Situación | Sobornar | Hablar | Huir | Entregar | Mejor (en euros) |
|---|---|---|---|---|---|
| Cap. 2 · calor 20 · rep. 10 · 30 g · 300 € | 150 € · requisa 0 % · −150 € · calor −10 | requisa 73 % · −384 € · calor −11 | requisa 55 % · −290 € · calor −5 | requisa 100 % · −228 € · calor −15 | Sobornar |
| Cap. 3 · calor 0 · rep. 150 · 5 g · 300 € | 58 € · requisa 15 % · −100 € · calor +3 | requisa 15 % · −51 € · calor ±0 | requisa 55 % · −186 € · calor +4 | requisa 100 % · −38 € · calor ±0 | Entregar |
| Cap. 3 · calor 85 · rep. 0 · 10 g · 450 € | 408 € · requisa 15 % · −426 € · calor −8 | requisa 90 % · −473 € · calor −14 | requisa 55 % · −289 € · calor −5 | requisa 100 % · −76 € · calor −15 | Entregar |
| Cap. 4 · calor 50 · rep. 40 · 40 g · 300 € | 275 € · requisa 15 % · −324 € · calor −8 | requisa 71 % · −427 € · calor −11 | requisa 55 % · −332 € · calor −5 | requisa 100 % · −304 € · calor −15 | Entregar |
| Cap. 4 · calor 60 · rep. 40 · 200 g · 2.000 € · noche | 480 € · requisa 15 % · −726 € · calor −8 | requisa 74 % · −1.570 € · calor −11 | requisa 40 % · −848 € · calor −1 | requisa 100 % · −1.520 € · calor −15 | Sobornar |
| Cap. 5 · calor 85 · rep. 60 · 600 g · 8.000 € | 1.080 € · requisa 15 % · −1.692 € · calor −8 | requisa 74 % · −3.836 € · calor −11 | requisa 55 % · −2.839 € · calor −5 | requisa 100 % · −4.560 € · calor −15 | Sobornar |
| Cap. 5 · igual, con protección | 1.080 € · requisa 0 % · −1.080 € · calor −10 | requisa 74 % · −3.836 € · calor −11 | requisa 55 % · −2.839 € · calor −5 | requisa 100 % · −4.560 € · calor −15 | Sobornar |
| Cap. 8 · calor 50 · rep. 150 · 3.000 g · 40.000 € | 3.740 € · requisa 15 % · −6.689 € · calor −8 | requisa 27 % · −6.240 € · calor −4 | requisa 55 % · −12.871 € · calor −5 | requisa 100 % · −22.800 € · calor −15 | Hablar |
<!-- /auto:policia -->

A partir de cuántos gramos encima sale más a cuenta sobornar que entregar, en euros (gramos a 7,60 €/g), según el dinero que llevas encima:

<!-- auto:umbral -->
| Dinero encima (calor 50) | Cap. 2 | Cap. 3 en adelante, sin protección | Con protección |
|---|---|---|---|
| 300 € | 36 g | 44 g | 36 g |
| 2.000 € | 48 g | 63 g | 48 g |
| 10.000 € | 105 g | 120 g | 105 g |
| 40.000 € | 316 g | 331 g | 316 g |
<!-- /auto:umbral -->

- **Sobornar o entregar.** El soborno sube con el calor, con los gramos y con el dinero que llevas encima. Entregar te cuesta solo los gramos y baja el calor 15; el soborno lo baja 10 (8 de media desde el capítulo 3, por los agentes honrados).
  - Con pocos gramos sale mejor entregarlos.
  - Con mucha carga, sobornar sigue ganando, pero cuanto más dinero llevas, más gramos hacen falta para que compense: el dinero encima ya no sale gratis.
  - Desde el capítulo 3, los agentes honrados suben el punto a partir del cual compensa sobornar.
  - Con la caja, se puede llevar solo lo que cuesta el soborno del viaje (§ 3.4).
- **Hablar** solo compensa con mucha reputación y poco calor. Con 150 de reputación y 50 de calor, convence 3 de cada 4 veces, y en el capítulo 8, con 40.000 € encima, ya es lo mejor.
- **Huir** tiene sentido de noche (60 %) y con mucha carga, si te da igual el calor (+8).
- El agente que patrulla la plaza (`talkCop`) te hace un control siempre que le hablas con algún gramo encima y sin protección.

### 2.6 Calor y redada

<!-- auto:calorOk -->
Comprobado con el juego: redada con calor 90 y no con 89,9 (se lleva las plantas, los gramos y hasta 3.000 € de multa, y deja el calor en 30); −12 al día; con protección, −20 y la redada se para (calor 50, sin quitar nada); +2 por carpa en flor sin filtro.
<!-- /auto:calorOk -->

<!-- auto:redada -->
| En el piso (gramos a 7,60 €/g; las plantas se pierden igual) | Encuentran la caja | Pérdida media (modelo) | Juego |
|---|---|---|---|
| Sin caja: 10.000 € y 500 g en el piso | — | −6.800 € | −6.800 € |
| Con caja: todo dentro | 25 % | −5.200 € | −5.274 € |
| Con caja: 1.000 € y 100 g fuera, el resto dentro | 25 % | −5.645 € | −5.708 € |
| Con caja: 3.000 € fuera (pagan la multa), el resto dentro | 25 % | −4.825 € | −4.886 € |
<!-- /auto:redada -->

La redada se decide al cambiar de día, a las 00:00, duermas o no. A esa hora, el calor tiene que estar por debajo de 90. Durante el día, el calor solo baja de tres formas: con un soborno (−10), con una requisa o entregando (−15). Todo lo demás lo hace la bajada diaria (−12, o −20 con protección), y esa bajada llega *después* de mirar la redada. Con 3 carpas en flor sin filtro, el olor suma 6 al día y deja muy poco margen para vender en la calle.

Con la caja, una redada cuesta menos: 3 de cada 4 veces no la ven, y la multa sale primero de lo de fuera. Si la encuentran, se llevan sus gramos y la mitad de su dinero. Las plantas se pierden igual.

### 2.7 La Copa

Para ganar hay que llevar al jurado 20 g de un lote con más del 26,8 % de THC. Los cogollos de una misma variedad se juntan en un solo lote, con el THC medio ponderado por gramos (`addBuds`). Lo que sale de un fenotipo estrella va a un lote aparte (★).

- **Amnesia Haze** (THC 26), en 4 cruces:
  1. Skunk #1 × Lemon Haze → Lemon Skunk;
  2. Lemon Skunk × Lemon Haze → Super Lemon Haze;
  3. Acapulco Gold × Afghani → Trainwreck;
  4. Super Lemon Haze × Trainwreck → Amnesia Haze.
- **Fire OG** (THC 27), también en 4 cruces:
  1. Afghani × Skunk #1 → Critical Mass;
  2. Critical Mass × OG Kush → Critical Kush;
  3. OG Kush × Blueberry → Blueberry Kush;
  4. Critical Kush × Blueberry Kush → Fire OG.

Cada cruce gasta una semilla de cada padre y da 2. Con 4 cruces solo tienes 2 semillas de Amnesia Haze o de Fire OG. Para llenar una carpa de 6 hay dos caminos:

- **Repetir cruces:** unos 8 en total. En la Amnesia Haze hay un tope: solo hay 2 semillas de Acapulco Gold y no se venden, así que salen como mucho 2 cruces de Trainwreck (4 semillas) y, como mucho, 8 semillas de Amnesia Haze.
- **Esquejes:** sacarlos de las plantas en crecimiento (entre el 20 % y el 65 % del cultivo) y plantarlos.

La carpa de 120 y el LED de 720 W están en la tienda desde el capítulo 5.

<!-- auto:copa -->
| Planta y equipo | Plazas | THC medio | Una planta pasa de 26,8 % (modelo) | Juego (por planta) | Gramos por planta | Con 2 plantas (juego) | Carpa llena (juego) |
|---|---|---|---|---|---|---|---|
| Amnesia Haze F1 · armario 60 + CFL | 2 | 26,0 % | 33,1 % | 33,2 % | 17 g | 28,3 % | 28,3 % |
| Amnesia Haze F1 · carpa 100 + LED 480 W · abono | 4 | 27,3 % | 57,4 % | 57,3 % | 134 g | 61,6 % | 66,5 % |
| Amnesia Haze F1 · carpa 150 + sodio 600 W · abono | 6 | 27,0 % | 52,5 % | 52,4 % | 76 g | 54,6 % | 58,0 % |
| Amnesia Haze F1 · carpa 120 + LED 720 W · abono | 6 | 27,7 % | 66,9 % | 67,1 % | 142 g | 72,0 % | 84,2 % |
| Amnesia Haze estable · carpa 120 + LED 720 W · abono | 6 | 27,7 % | 72,0 % | 72,2 % | 142 g | 78,1 % | 90,8 % |
| Fire OG F1 · armario 60 + CFL | 2 | 27,0 % | 52,5 % | 52,4 % | 18 g | 54,3 % | 54,3 % |
| Fire OG F1 · carpa 120 + LED 720 W · abono | 6 | 28,7 % | 79,2 % | 79,5 % | 157 g | 89,4 % | 98,0 % |
<!-- /auto:copa -->

En el armario de la tía, con un CFL, una planta da 17-18 g, menos de los 20 g que pide el jurado. Hay que juntar las dos en un lote, y entonces manda la media:

- Amnesia Haze: gana algo más de 1 de cada 4 veces.
- Fire OG: gana algo más de la mitad de las veces.

Con la carpa de 120 y el LED de 720 W, abonando:

- Carpa llena de Amnesia Haze: gana unas 84 de cada 100 veces.
- Carpa llena de Fire OG: gana casi siempre.

Estabilizar la Amnesia Haze sube algo sus opciones (de 84 a 91 de cada 100), pero cuesta 3 generaciones más. Lo que más cuenta es la luz.

## 3. La caja fuerte del piso

### 3.1 El problema que resuelve

Antes de la 1.10, el juego no distinguía entre lo que llevabas encima y lo que guardabas en casa:

- en cuanto tenías un gramo, cualquier paso por el barrio podía acabar en control, y el control se llevaba **toda** tu cosecha;
- con 150 € o más, ya había ladrones;
- un KO se llevaba el 30 % de todo lo ahorrado, incluidos los 12.000 € del plazo que llevabas al bar.

No había nada que decidir sobre qué sacar de casa, y esa decisión es justo lo que da tensión a cada salida.

### 3.2 Cómo es

Una caja en el piso, detrás del diploma de la tía, con dinero y cogollos (`S.caja = { money, buds, nivel }`). Lo que está dentro no va encima: no cuenta para los encuentros, ni para el soborno, ni para lo que te quitan en la calle.

- Se abre pulsando A delante del diploma: «Guardar todo / Guardar dinero / Guardar cogollos / Sacar dinero / Sacar cogollos / Sacar todo / Cerrar». Dinero y gramos se eligen en pasos (100, 500, 1.000 € o 10, 50, 100 g…, y «todo lo que cabe»).
- La mochila enseña las dos cosas: lo de encima y lo de la caja.

| Caja | Cómo se consigue | Capacidad | En una redada | Robo de Darko (cap. 7) |
|---|---|---|---|---|
| **C · La caja de la tía** | Detrás del diploma de la Copa de 1998 (7, 1). La pista está en las notas del ordenador: «La combinación, el año en que lo gané». Dentro hay 300 € | 20.000 € y 2 kg | La encuentran 1 de cada 4 veces: sus gramos y la mitad de su dinero | Resiste |
| **B · La caja empotrada** | Por el ordenador, desde el capítulo 4 y con la de la tía abierta, por 380 € (de fuera y, si no llega, de la caja). Kiko la instala al día siguiente, con lo que ya tuvieras dentro | 50.000 € y 2,5 kg | Igual: 1 de cada 4 veces | Resiste |

La caja de sobremesa de la tienda (la A de la propuesta) se descartó: la de la tía da sentido al diploma y conecta con la Copa, y la empotrada es la mejora para el imperio.

### 3.3 Reglas que cambian

| Dónde | Antes | Con la caja |
|---|---|---|
| `onStepEnd` (encuentros) | Contaban `totalBuds()` y `S.money`, es decir, todo | Solo lo de fuera de la caja. La fórmula no cambia: lo guardado sale de `S.buds` y de `S.money` |
| `copRound` (soborno) | Pagabas con todo tu dinero | Solo con el que llevas encima: «No llevas tanto dinero encima». Y el precio suma el 5 % de ese dinero |
| `confiscate` y el KO del ladrón | Se llevaban de todo | Solo de lo que llevas fuera |
| `raidEvent` | Todas las plantas, todos los gramos y una multa de hasta 3.000 € | Lo de fuera, siempre. La caja, 1 de cada 4 veces (`CAJA_REDADA`). La multa sale primero de lo de fuera y después de la caja (`pagarCasa`) |
| `newDay` (luz) | La factura de la luz salía de `S.money` | De lo de fuera y, si no llega, de la caja |
| Kiko (regalo) | Con menos de 15 €, sin semillas, sin plantas y sin gramos | Cuenta también lo de la caja |
| Ordenador | Pagabas con lo que llevabas | Paga de lo de fuera y, si no llega, de la caja: el ordenador está en el piso |
| Kiko, plazos de Baltasar, Iñaki, jurado | Pagabas o vendías con todo lo que tenías | Solo con lo que llevas encima |
| Partida guardada | — | `S.caja` (null hasta abrirla) en `newState`; `migrate()` la rellena en las partidas viejas |

### 3.4 Efecto: lo mismo, con y sin caja

La tabla compara viajes de ida y vuelta en tres casos:

- **Sin caja:** llevas encima todo lo que tienes.
- **Con caja:** llevas solo lo que hace falta para el viaje.
- **Con caja y el soborno encima:** además, llevas el precio del soborno, para poder pagarlo si te paran (el 5 % de ese dinero también entra en el precio).

Cada celda da tres cifras: la probabilidad de cruzarte con un control, la de cruzarte con un ladrón y lo que pierdes de media. Se cuenta el primer encuentro de cada tramo (después vienen 24 pasos tranquilos). En el control se elige la mejor opción en euros y, con el ladrón, la mejor forma de pelear. Los supuestos de cada fila están en la lista de debajo. Los encuentros de cada tramo se juegan en el juego, andando con lo demás dentro de la caja; lo que se pierde en cada encuentro sale del modelo.

<!-- auto:caja -->
| Ida y vuelta | Sin caja: control / ladrón · pérdida media | Con caja | Con caja y el soborno encima |
|---|---|---|---|
| Cap. 3 · ir a comprar a Kiko (200 €) | 22,9 % / 10,0 % · −189 € | 0,0 % / 5,5 % · 0 € | igual |
| Cap. 4 · vender 10 g a Iñaki | 67,8 % / 22,4 % · −975 € | 43,3 % / 11,9 % · −18 € | 43,3 % / 25,9 % · −33 € |
| Cap. 4 · vender 40 g en la plaza, de noche | 55,0 % / 35,0 % · −751 € | 32,9 % / 38,5 % · −40 € | 32,9 % / 38,5 % · −84 € |
| Cap. 5 · pagar 12.000 € a Baltasar | 57,7 % / 13,8 % · −1.118 € | 0,0 % / 8,8 % · 0 € | igual |
| Cap. 8 · cargar 2 kg a Iñaki | 67,8 % / 22,4 % · −3.208 € | 43,3 % / 25,9 % · −877 € | 43,3 % / 25,9 % · −946 € |
<!-- /auto:caja -->

<!-- auto:cajaSup -->
- **Cap. 3 · ir a comprar a Kiko (200 €):** calor 30, reputación 20, vida 30, sin spray y 1 bocata; gramos a 7,60 €/g. Sin caja: 300 g y 2.000 € a la ida, 300 g y 1.800 € a la vuelta. Con caja: 200 € a la ida, 0 € a la vuelta.
- **Cap. 4 · vender 10 g a Iñaki:** calor 50, reputación 40, vida 36, sin spray y 1 bocata; gramos a 7,60 €/g. Sin caja: 400 g y 5.000 € a la ida, 390 g y 5.091 € a la vuelta. Con caja: 10 g y 0 € a la ida, 91 € a la vuelta; con el soborno, 263 € más en cada tramo.
- **Cap. 4 · vender 40 g en la plaza, de noche:** calor 60, reputación 40, vida 36, 1 spray y 1 bocata, de noche; gramos a 7,60 €/g. Sin caja: 400 g y 5.000 € a la ida, 360 g y 5.300 € a la vuelta. Con caja: 40 g y 0 € a la ida, 300 € a la vuelta; con el soborno, 332 € más en cada tramo.
- **Cap. 5 · pagar 12.000 € a Baltasar:** calor 70, reputación 60, vida 44, 2 sprays y 1 bocata; gramos a 7,60 €/g. Sin caja: 600 g y 13.000 € a la ida, 600 g y 1.000 € a la vuelta. Con caja: 12.000 € a la ida, 0 € a la vuelta.
- **Cap. 8 · cargar 2 kg a Iñaki:** calor 50, reputación 150, vida 60, 2 sprays y 1 bocata; gramos a 3,80 €/g. Sin caja: 4.500 g y 40.000 € a la ida, 2.500 g y 47.600 € a la vuelta. Con caja: 2.000 g y 0 € a la ida, 7.600 € a la vuelta; con el soborno, 1.705 € más en cada tramo.
<!-- /auto:cajaSup -->

Cómo leer la tabla:

- **Los controles bajan con la caja:** la vuelta se hace sin gramos, y sin gramos no hay control.
- **El ladrón a veces sube**, por dos motivos:
  - al haber menos controles, el ladrón es más a menudo el primer encuentro del tramo;
  - llevar 150 € o más para el soborno lo atrae.
- **La pérdida media se desploma**, porque un control o un KO ya solo te quitan lo que llevas.
- **Sin dinero para el soborno**, en un control solo puedes hablar, huir o entregar.

La caja no quita los encuentros del todo: hay que llevar la mercancía para venderla y el dinero para pagar. Lo que cambia es que un control cuesta lo que llevas, y no todo lo que tienes. Y aparecen decisiones:

- cuánto sacar de casa;
- si llevar el dinero del soborno;
- cuándo hacer el viaje grande.

### 3.5 Dónde está en el código

- **HTML:** `11b-caja.js` (la caja, el robo de Darko y los encargos de Baltasar); `08-mundo.js` (`S.caja`, `S.rec`, `S.vencidos`, `S.protHasta`, `S.encargo` y la migración); `09-cultivo.js` (el ordenador, la luz, la instalación de la empotrada y el robo al dormir); `11-historia.js` (`raidEvent`, el embargo, Molina y el capítulo 4); `12-menus.js` (la mochila); `04-mapas.js` (el barrio alto, los astilleros y los tres interiores).
- **Godot:** lo mismo en `godot/src/mundo.gd` (la caja, las zonas, los clientes y quién está en cada mapa), `granja.gd` (el día nuevo, la cama, el ordenador y la cosecha), `trama.gd` (la historia, la redada, el embargo, el robo y los encargos), `juego.gd` y `pinta.gd`. `tests/historia.gd` juega los mismos 66 pasos que `npm test` y compara cada uno con el HTML, y `tests/pantallas.gd` compara las zonas nuevas y sus interiores píxel a píxel.
- **Tests:** los pasos de la caja, el robo, el embargo, la cuota, los encargos y las zonas en `tools/test-historia.js`; y en `analisis-riesgos.js`, los viajes de § 3.4 y la redada de § 2.6 jugados con la caja.

### 3.6 El robo de Darko (capítulo 7)

1. La primera vez que duermes en el capítulo 7 (hasta las 7 o una siesta) con más de 1.000 € o más de 100 g fuera de la caja, entran en el piso: «Te despierta un portazo. La cerradura está forzada y el piso, revuelto».
2. Se llevan la mitad del dinero y la mitad de cada lote que haya fuera de la caja. La caja, de la tía o empotrada, sigue cerrada.
3. Llega un SMS de Darko: «Te dije que esto no se acababa ahí». Si aún no has abierto la caja de la tía, el juego te recuerda que la tía guardaba sus cosas en algún sitio.

Pasa una sola vez (`flags.robo`). Así se cierra el hilo de la Copa y la caja tiene su momento en la historia.

## Cómo regenerar

```bash
export CHROMIUM_PATH=$(ls -d /opt/pw-browsers/chromium-*/chrome-linux/chrome | head -1)
npm run analisis                          # tablas de este documento; sale con 1 si el modelo y el juego no coinciden
node tools/analisis-riesgos.js --n 5000   # más rápido (antes, node tools/build.js)
node tools/analisis-riesgos.js --reservado casos.json   # solo comprueba (paso, ladrón, policía y una ruta), no escribe
```

Las tablas se reescriben solas, pero el texto no: si las cifras cambian mucho, revisa las conclusiones.

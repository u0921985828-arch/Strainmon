# Análisis · guion, misiones y riesgos de la calle (1.10)

Este documento revisa:

- la historia y sus misiones;
- lo que puede pasarte por la calle: ladrones, controles de policía, sobornos, calor y redadas;
- una propuesta de **caja fuerte** en el piso.

Las cifras salen del código de la 1.10. `node tools/analisis-riesgos.js` escribe las tablas generadas con un modelo exacto, que aplica las mismas reglas que el código. Después, el mismo script juega cada caso con las funciones de verdad del juego (`onStepEnd`, `battle` y `thiefRound`, `copRound`, `newDay` y `raidEvent`, `talkClient`, `talkInaki`, `ventaMayor`, `harvest`, `addBuds` y `talkJurado`). Si alguna cifra no cuadra, para con un error y no escribe nada.

La excepción es la tabla de la caja fuerte (§ 3.4). La caja todavía no existe en el juego, así que esa tabla sale solo del modelo.

<!-- auto:meta -->
Generado con `npm run analisis`: 561 cifras comprobadas con el juego (20.000 combates, controles, ventas o trayectos simulados por celda, 100.000 pasos por situación y 5.000 carpas por fila de la Copa). Gramos a 7,60 €/g (precio de calle de una variedad del 18 %), salvo donde se dice.
<!-- /auto:meta -->

## Resumen

| # | Hallazgo | Gravedad | Propuesta |
|---|---|---|---|
| 1 | **Todo lo que tienes va siempre encima.** Hay un solo dinero (`S.money`) y una sola bolsa de cogollos (`S.buds`). La mochila dice «N g encima», pero son todos tus gramos. Un control se los lleva todos, aunque la cosecha «esté en casa». Un ladrón que te deja KO se lleva la mitad de cada lote y el 30 % de todo tu dinero. | Alta | La caja fuerte (§ 3) |
| 2 | **El capítulo 4 se salta solo.** Pide tener 8 variedades descubiertas, y una variedad se descubre en cuanto tienes sus semillas (`addSeeds` → `discover`). Puedes llegar a 8 sin cruzar nada: Skunk #1, Lemon Haze, OG Kush y 5 landraces del ordenador, todas al alcance en el capítulo 2. En cuanto Kiko te da la mesa, empieza el capítulo 5. | Alta | Pedir que coseches 2 variedades de receta sacadas en la mesa (§ 1.3, punto 1) |
| 3 | **El plazo del capítulo 3 no empieza hasta que hablas con Baltasar.** Toño dice «Hoy», pero el juego no fija el plazo (`S.due`, `S.deadline`) hasta `talkBaltasar`, y el castigo exige haberle visto (`flags.metB`). Si no vas al bar, no hay plazo. | Media | Fijar el plazo cuando aparece Toño |
| 4 | **No hay derrota.** Si vence un plazo, Toño suma un 20 % de lo que debes (que se acumula: 3.000 → 3.600 → 4.300 → 5.200 €), te quita 15 de vida y te da 5 días más. Puede repetirse sin límite. | Media (puede ser a propósito) | A la tercera vez, que Toño se lleve algo del piso (una carpa o la caja) |
| 5 | **Tres hilos sin cerrar.** Darko dice «Vende lo tuyo si quieres, pero lejos de mis esquinas», pero ninguna regla lo aplica. Al perder la Copa dice «Mi tío se va a enterar», pero `flags.copa` no se lee en ningún sitio. Baltasar te ofrece trabajo al saldar la deuda y no pasa nada más. | Media | Un robo de Darko en el capítulo 7 (§ 3.6) y encargos de Baltasar en el imperio |
| 6 | **Al por mayor da unas 70 veces más euros por punto de calor que la calle.** Por gramo, en cambio, la calle paga el doble (7,63 € frente a 3,80 €). Desde el capítulo 3, la calle solo sirve para ganar reputación. | Media | Subir el calor del por mayor o limitarlo por reputación |
| 7 | **El soborno casi siempre es lo mejor en un control, y su precio no depende de tu dinero.** Cuesta 40 + 4 × calor + 0,5 × gramos. En el capítulo 8 son 1.740 € aunque lleves 40.000 €. Con pocos gramos sale más barato entregarlos: por debajo de 49 g, con calor 50. | Media | Que el precio suba con el dinero que llevas encima, o que haya más agentes honrados con más calor |
| 8 | **Con spray, los ladrones casi nunca ganan.** Con 2 sprays y un bocata, menos del 0,1 % de los combates acaba en KO, también en el capítulo 8. Sin spray es otra cosa: en el capítulo 8, con 30 de vida, pelear a puñetazos acaba en KO 2 de cada 3 veces, y lo mejor es huir (2,5 %). | Baja | Ladrones que pegan más desde el capítulo 5, o un spray que pierde fuerza con cada uso |
| 9 | **La Copa se prepara en cuanto tienes la mesa** (capítulo 4): son 4 cruces sin cultivar nada. Pero el último cruce da solo 2 semillas. Con esas 2 plantas en el armario, la Amnesia Haze gana algo más de 1 de cada 4 veces. Para una carpa llena hacen falta unos 8 cruces o esquejes. | Baja | Aceptable. Si se quiere más reto, que Darko suba su marca cada vez que pierdes |
| 10 | El objetivo del capítulo 2 dice «vendiendo en la calle», pero también cuentan las ventas a Iñaki (`S.sales`). | Muy baja | Cambiar el texto a «vendiendo» |

## 1. Guion y misiones

### 1.1 La historia, capítulo a capítulo

| Cap. | Objetivo | Qué lo cumple (código) | Plazo | Al cumplirlo |
|---|---|---|---|---|
| 1 · La herencia | Leer la carta, ir a ver a Kiko (te da 3 semillas de Skunk #1 y 2 dosis de abono) y cosechar | `flags.letter`, `flags.kiko1` y `flags.harvest1` | — | Capítulo 2. Kiko te escribe. Empiezan los clientes, los controles y los ladrones |
| 2 · La calle | Vender por 300 € | `S.sales ≥ META_VENTAS` (cuentan también las ventas a Iñaki) | — | Capítulo 3. Toño te corta el paso y te cita en el bar «hoy» |
| 3 · La deuda | Pagar 3.000 € a Baltasar | Pagar en el bar | 7 días, **desde que hablas con él** | Capítulo 4. Kiko te llama: en el growshop te da la mesa de genética y 3 semillas de Afghani |
| 4 · Genética | Tener 8 variedades descubiertas | `discCount() ≥ 8`, que se mira en cuanto tienes la mesa | — | Capítulo 5. Toño te escribe: 12.000 € en 10 días. Aparece Molina |
| 5 · El sargento | Pagar 12.000 €. Molina te ofrece protección por 1.500 € (si dices que no, +10 de calor) | Pagar en el bar | 10 días | Capítulo 6. Baltasar te habla de la Copa |
| 6 · La Copa | Llevar 20 g de un lote con más del 26,8 % de THC | `talkJurado`: `round(thc·10)/10 > 26,8` | Ninguno (se puede repetir) | 5.000 € y +20 de reputación. Capítulo 7, con todo lo que queda (15.000 €) en 7 días |
| 7 · Libertad | Pagar 15.000 € | Pagar en el bar | 7 días | Pantalla final y capítulo 8. Baltasar te ofrece trabajo |
| 8 · Tu imperio | Facturar 25.000, 100.000 y 250.000 € desde el último pago | `imperioNivel()` | — | Iñaki te carga 2, 5 y 10 kg al día. La meta final es completar la genoteca de 41 y sacar la Ghost Train Haze |

Si un plazo vence (capítulos 3, 5 y 7), Toño se presenta al cambiar de día:

- Suma un 20 % de lo que debes en ese plazo, redondeado a 100 €. Como el 20 % se calcula sobre lo que ya debes, la deuda crece así: 3.000 → 3.600 → 4.300 → 5.200 €. Ese interés también se suma a la deuda total.
- Te quita 15 de vida, sin bajarte nunca de 1.
- Te da 5 días más.

Puede pasar una y otra vez, sin límite.

### 1.2 Misiones secundarias y secretos

| Quién o qué | Dónde | Pide | Da | Notas |
|---|---|---|---|---|
| Abuela Txaro | Parque (3, 18) | 5 g, una sola vez | 2 semillas de Hindu Kush y 3 bocatas | La única misión con historia propia. No tiene continuación |
| Iñaki | Muelle (37, 21), desde el capítulo 2 | 10 g al día | 1,2 veces el precio de la calle. La primera vez, también 2 semillas de Malawi Gold | Desde el capítulo 3 también compra al por mayor (§ 1.4) |
| Ordenador de la tía | Piso | Dinero | Sobres de 10 semillas de 12 landraces: 5 desde el capítulo 2, 5 desde el 3 y 2 desde el 4. Llegan al día siguiente | Cuentan para el objetivo del capítulo 4 |
| Arbustos del parque | (2, 26), (9, 16) y (10, 24): pulsa A delante | — | 2 semillas de Acapulco Gold, 50 € y 1 insecticida | Josune y Unai dan la pista. La Acapulco Gold no se vende en ningún sitio |
| Bolsas en el suelo | (8, 25), (36, 24) y (15, 23) | — | 2 sprays, 3 abonos y 2 bocatas | — |
| Patxi | Fuente de la plaza | — | Desde el capítulo 4, una pista de receta en cada visita (11 en total) | Antes del capítulo 4 solo te dice que vuelvas |
| Kiko | Growshop | — | Un consejo por capítulo. Si te quedas sin nada (sin semillas, sin plantas, sin gramos y con menos de 15 €), 2 semillas de Skunk #1 | Así la partida no se puede atascar |
| Josune | Bar | 3-4 € | Vida y rumores | Los rumores adelantan lo de Molina y Darko |
| Ghost Train Haze | Mesa de genética | Cruzar Amnesia Haze × Fire OG | Un SMS de Kiko | Es la meta del final, junto con la genoteca |

### 1.3 Problemas del guion y propuestas

1. **El capítulo 4 no se juega.**
   - Lo que pasa: «descubrir» una variedad es tener sus semillas, así que basta con comprar. Cuando Kiko te da la mesa, lo normal es tener ya 8 variedades o más:
     - Skunk #1: Kiko te la regala en el capítulo 1, y además está en la tienda;
     - Lemon Haze y OG Kush (tienda, capítulo 2);
     - Blueberry y Mango (tienda, capítulo 3);
     - Malawi Gold (Iñaki), Hindu Kush (Txaro) y Acapulco Gold (arbusto);
     - las 10 landraces del ordenador de los capítulos 2 y 3.

     `checkStory` mira `discCount() ≥ 8` en cuanto tienes la mesa, así que el capítulo dura lo que un diálogo.
   - Por qué no basta con pedir «4 cruces nuevos»: cualquier cruce sin receta da al instante un híbrido nuevo (`crossResult`). Serían 4 pulsaciones en la mesa.
   - **Propuesta:** que el objetivo sea «Cosecha 2 variedades de receta que hayas sacado en la mesa» (Lemon Skunk o Critical Mass, por ejemplo). Las pistas de Patxi empiezan justo en este capítulo. Así hay que cruzar, plantar y cultivar al menos una tanda.
2. **Toño dice «Hoy» y no pasa nada.** El plazo de 3.000 € no empieza hasta que te sientas con Baltasar. Hasta entonces `S.due` vale 0, y `penaltyEvent` además exige `flags.metB`.
   - **Propuesta:** fijar `S.due` y `S.deadline = S.day + 7` cuando aparece Toño. Si tardas más de 2 días en ir al bar, Baltasar te recibe con «Llegas tarde».
3. **Darko amenaza dos veces y no cumple.**
   - En el capítulo 2: «Vende lo tuyo si quieres, pero lejos de mis esquinas».
   - Al perder la Copa: «Esto no se acaba aquí. Mi tío se va a enterar».
   - **Propuesta:** en el capítulo 7, una noche entran a robar en el piso (§ 3.6). Así la amenaza tiene consecuencias y la caja fuerte tiene su momento en la historia.
4. **La oferta de Baltasar se queda en el aire.** «Si algún día quieres trabajar para mí, ya sabes dónde estoy».
   - **Propuesta (capítulo 8):** encargos de Baltasar. Por ejemplo, llevar 2 kg al muelle de noche, mejor pagado que con Iñaki pero con más riesgo. Encaja con el imperio y con las tablas de trayectos (§ 2.3).
5. **No hay derrota.** Los intereses se acumulan sin fin (§ 1.1). Es coherente con un juego tranquilo, pero así la presión del plazo es solo de texto.
   - **Propuesta:** al tercer plazo vencido, Toño se lleva la carpa más grande o, si la tienes, la caja fuerte de sobremesa.
6. **La Copa «del sábado».** Baltasar dice «El sábado es la COPA», pero el juego no tiene días de la semana y el jurado está en la plaza todo el capítulo 6.
   - **Propuesta:** quitar «El sábado», o dar a la Copa un día fijo como plazo.
7. **Molina cobra una vez y protege para siempre.** Con pagarle 1.500 € una sola vez, durante toda la partida:
   - no hay redadas;
   - los controles bajan al 40 % y desaparecen los agentes honrados;
   - el calor baja 20 al día en vez de 12.

   **Propuesta:** que la cuota se pague cada 10 días o que suba después de la Copa.
8. **Texto del capítulo 2.** El objetivo dice «vendiendo en la calle», pero también cuentan las ventas a Iñaki. Basta con cambiar el texto.

### 1.4 Vender: euros por punto de calor

El calor baja 12 al día (20 con la protección de Molina), y cada carpa con plantas en flor y sin filtro suma 2. Cuánto puedes vender cada día sin que el calor suba depende del calor que da cada venta:

<!-- auto:eficiencia -->
| Venta (THC 18 %, salvo el pijo) | Cobras | €/g | Calor | € por punto de calor |
|---|---|---|---|---|
| Calle · currela, 8 g a precio justo (acepta el 92 %) | 61 € | 7,63 | +7 | 9 € |
| Calle · pijo del cap. 6 (pide 21 % de THC), 12 g de THC 24 a precio caro (acepta el 70 %) | 185 € | 15,42 | +9 | 21 € |
| Iñaki · 10 g para el viaje (una vez al día) | 91 € | 9,10 | +3 | 30 € |
| Al por mayor · 1 kg (una carga al día, hasta 1 kg antes del imperio) | 3.800 € | 3,80 | +6 | 633 € |
| Al por mayor · 10 kg (Mayorista del norte) | 38.000 € | 3,80 | +42 | 905 € |
<!-- /auto:eficiencia -->

Por gramo, la calle paga el doble que el por mayor. Pero cada venta en la calle suma 3 de calor más medio punto por gramo, mientras que una carga al por mayor suma solo 2 más 1 por cada 250 g. Por eso una carga de 1 kg da tanto dinero como unas 60 ventas en la calle y sube el calor lo que una sola.

Desde el capítulo 3, lo que más rinde es cultivar mucho y vendérselo todo a Iñaki. La calle solo compensa por la reputación: cada venta da de +1 a +3. La reputación ayuda a salir hablando de un control y trae más clientes.

## 2. Riesgos de la calle

### 2.1 Las reglas (08-mundo, 13-combate, 09-cultivo)

- **Encuentros.**
  - Solo en el barrio y desde el capítulo 2.
  - Después de un encuentro vienen 24 pasos tranquilos (`S.cool` se pone a 25 y baja antes de mirar). Los pasos dentro de casa, del growshop o del bar también descuentan.
  - Cada paso tira un único número al azar: si sale por debajo de *pp*, hay control; si cae entre *pp* y *pp* + *pt*, hay ladrón.
  - Control: *pp* = (0,002 + 0,00025 × calor) × (0,4 con protección). Si no llevas ni un gramo, es 0.
  - Ladrón: *pt* = 0,004 × (2,5 de noche, de 21:00 a 6:00) × (3 en hierba alta). Solo si llevas 5 g o más, o 150 € o más.
- **Ladrón.** Tiene 12 + 2 × capítulo + (de 0 a 4) de vida. Pega entre 2 + cap/4 y 4 + cap/2 (divisiones enteras).
  - Puñetazo: acierta un 92 % y quita 4-7.
  - Patada: acierta un 65 % y quita 8-12.
  - Spray: acierta siempre y quita 12-16.
  - Bocata: +15 de vida, sin pasar de tu vida máxima.
  - Hablar: convence un 25 % + reputación/300, entre el 25 y el 70 %.
  - Huir: sale bien un 50 %.
  - Tu vida máxima empieza en 30 y sube 2 con cada ladrón que vences, hasta 60.
  - Si ganas: 20-40 € + 10 × capítulo y +2 de reputación.
  - Si caes KO: se lleva la mitad de cada lote y el 30 % del dinero, y despiertas en casa 6 horas después.
- **Control.**
  - Sobornar cuesta 40 + 4 × calor + 0,5 × gramos. Depende de lo que llevas, no del dinero que tengas. Si no te llega el dinero, el agente no lo acepta y vuelves a elegir.
    - Sale bien: −10 de calor.
    - Agente honrado (15 %, desde el capítulo 3 y sin protección): requisa, multa y +20 de calor. Con el −15 de la requisa, son +5 en total.
  - Hablar convence un 30 % + reputación/250 − calor/300, entre el 10 y el 85 %. Si no convence: requisa y multa.
  - Huir sale bien un 45 % (un 60 % de noche) y suma 8 de calor. Si falla: requisa, multa y −5 de vida.
  - Entregar: te quitan los gramos, sin multa, y el calor baja 15.
  - Una requisa se lleva **todos** los gramos y baja el calor 15. La multa es de 601 € (o lo que lleves, si es menos).
- **Calor y redada.** Al cambiar de día (00:00), duermas o no, el juego mira el calor *antes* de bajarlo:
  - con 90 o más, hay redada: se llevan todas las plantas y todos los gramos, hay una multa de hasta 3.000 € y el calor queda en 30;
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

El muelle es lo más lejano: 43 pasos. Con 80 de calor y de noche, una de cada dos idas a ver a Iñaki acaba en control. Ninguna ruta normal pisa la hierba alta; solo la que va hasta ella (2 casillas).

### 2.4 Ladrones

<!-- auto:ladron -->
| Cap. | Ladrón: vida · golpe | Tu vida | Puñetazo | Patada | 2 sprays, luego puñetazo | Huir | Hablar (rep. 0) | Hablar (rep. 60) | La mejor, sin spray ni bocata | La mejor, con 2 sprays y 1 bocata |
|---|---|---|---|---|---|---|---|---|---|---|
| 2 | 16-20 · 2-5 | 30 | < 0,1 % | 0,4 % | 0,0 % | 0,2 % | 7,8 % | 0,5 % | < 0,1 % | 0,0 % |
| 5 | 22-26 · 3-6 | 30 | 2,6 % | 5,6 % | < 0,1 % | 0,8 % | 13,3 % | 1,6 % | 0,7 % | < 0,1 % |
| 5 | 22-26 · 3-6 | 40 | 0,1 % | 1,0 % | < 0,1 % | 0,2 % | 7,0 % | 0,4 % | < 0,1 % | < 0,1 % |
| 8 | 28-32 · 4-8 | 30 | 63,9 % | 31,2 % | 0,1 % | 2,5 % | 21,2 % | 4,1 % | 2,5 % | < 0,1 % |
| 8 | 28-32 · 4-8 | 40 | 14,5 % | 11,9 % | < 0,1 % | 0,8 % | 13,2 % | 1,5 % | 0,8 % | < 0,1 % |
| 8 | 28-32 · 4-8 | 60 | 0,1 % | 1,2 % | < 0,1 % | 0,1 % | 5,1 % | 0,2 % | < 0,1 % | < 0,1 % |
<!-- /auto:ladron -->

<!-- auto:optima -->
Primera acción de «la mejor» (la que menos veces acaba en KO):
- Cap. 8, 30 de vida, sin spray ni bocata: huir si el ladrón tiene 28-32 de vida (KO 2,5 %).
- Cap. 8, 40 de vida, sin spray ni bocata: huir si el ladrón tiene 28-32 de vida (KO 0,8 %).
- Cap. 8, 30 de vida, con 2 sprays y 1 bocata: puñetazo si el ladrón tiene 28-32 de vida (KO < 0,1 %).
- Cap. 5, 30 de vida, sin spray ni bocata: puñetazo si el ladrón tiene 22 de vida; patada si el ladrón tiene 23-25 de vida; huir si el ladrón tiene 26 de vida (KO 0,7 %).
<!-- /auto:optima -->

- **El spray decide.** Cuesta 15 € en la tienda de Kiko desde el capítulo 2. Dos sprays quitan 24-32 de vida, casi toda la del ladrón más fuerte. Con 2 sprays y un bocata, el KO baja de 1 entre 1.000 en todos los capítulos.
- **Sin spray, pelear no siempre compensa.** En el capítulo 8, con 30 de vida, un ladrón de 28-32 de vida que pega 4-8 te deja KO 2 de cada 3 veces a puñetazos y 1 de cada 3 a patadas. Lo mejor es huir. Con 40 de vida, lo mejor sigue siendo huir. Con 60, pelear ya sale bien.
- **Hablar**, con poca reputación, es peor que huir: si no convence, el ladrón pega igual. Con 60 de reputación queda cerca de huir.
- **Huir** no da dinero ni vida máxima. Ganar sí: así se sube la vida para los capítulos altos.
- Lo que hace daño de verdad es el **KO**: la mitad de todos los gramos y el 30 % de todo el dinero. En el capítulo 8, con 40.000 €, son 12.000 € de una vez.

### 2.5 Policía: control y soborno

En la tabla, «requisa» es la probabilidad de perder los gramos, y «−€» es lo que pierdes de media en euros (dinero y gramos, estos a precio de calle). El calor es el cambio medio. La columna «Mejor (en euros)» no tiene en cuenta el calor.

<!-- auto:policia -->
| Situación | Sobornar | Hablar | Huir | Entregar | Mejor (en euros) |
|---|---|---|---|---|---|
| Cap. 2 · calor 20 · rep. 10 · 30 g · 300 € | 135 € · requisa 0 % · −135 € · calor −10 | requisa 73 % · −384 € · calor −11 | requisa 55 % · −290 € · calor −5 | requisa 100 % · −228 € · calor −15 | Sobornar |
| Cap. 3 · calor 0 · rep. 150 · 5 g · 300 € | 43 € · requisa 15 % · −87 € · calor +3 | requisa 15 % · −51 € · calor ±0 | requisa 55 % · −186 € · calor +4 | requisa 100 % · −38 € · calor ±0 | Entregar |
| Cap. 3 · calor 85 · rep. 0 · 10 g · 450 € | 385 € · requisa 15 % · −406 € · calor −8 | requisa 90 % · −473 € · calor −14 | requisa 55 % · −289 € · calor −5 | requisa 100 % · −76 € · calor −15 | Entregar |
| Cap. 4 · calor 50 · rep. 40 · 40 g · 300 € | 260 € · requisa 15 % · −312 € · calor −8 | requisa 71 % · −427 € · calor −11 | requisa 55 % · −332 € · calor −5 | requisa 100 % · −304 € · calor −15 | Entregar |
| Cap. 4 · calor 60 · rep. 40 · 200 g · 2.000 € · noche | 380 € · requisa 15 % · −641 € · calor −8 | requisa 74 % · −1.570 € · calor −11 | requisa 40 % · −848 € · calor −1 | requisa 100 % · −1.520 € · calor −15 | Sobornar |
| Cap. 5 · calor 85 · rep. 60 · 600 g · 8.000 € | 680 € · requisa 15 % · −1.352 € · calor −8 | requisa 74 % · −3.836 € · calor −11 | requisa 55 % · −2.839 € · calor −5 | requisa 100 % · −4.560 € · calor −15 | Sobornar |
| Cap. 5 · igual, con protección | 680 € · requisa 0 % · −680 € · calor −10 | requisa 74 % · −3.836 € · calor −11 | requisa 55 % · −2.839 € · calor −5 | requisa 100 % · −4.560 € · calor −15 | Sobornar |
| Cap. 8 · calor 50 · rep. 150 · 3.000 g · 40.000 € | 1.740 € · requisa 15 % · −4.989 € · calor −8 | requisa 27 % · −6.240 € · calor −4 | requisa 55 % · −12.871 € · calor −5 | requisa 100 % · −22.800 € · calor −15 | Sobornar |
<!-- /auto:policia -->

A partir de cuántos gramos encima sale más a cuenta sobornar que entregar, en euros (gramos a 7,60 €/g):

<!-- auto:umbral -->
| Calor | Cap. 2 | Cap. 3 en adelante, sin protección | Con protección |
|---|---|---|---|
| 0 | 6 g | 21 g | 6 g |
| 25 | 20 g | 35 g | 20 g |
| 50 | 34 g | 49 g | 34 g |
| 75 | 48 g | 63 g | 48 g |
| 89 | 56 g | 71 g | 56 g |
<!-- /auto:umbral -->

- **Sobornar o entregar.** El soborno sube con el calor y con los gramos, pero no con tu dinero. Entregar te cuesta solo los gramos y baja el calor 15; el soborno lo baja 10 (8 de media desde el capítulo 3, por los agentes honrados).
  - Con pocos gramos sale mejor entregarlos.
  - Con mucha carga, sobornar gana siempre: en el capítulo 8 cuesta 1.740 €, frente a 22.800 € de mercancía.
  - Desde el capítulo 3, los agentes honrados suben 15 g el punto a partir del cual compensa sobornar.
- **Hablar** solo compensa con mucha reputación y poco calor. Con 150 de reputación y 50 de calor, convence 3 de cada 4 veces. Con 150 de reputación, calor 0 y 5 g encima, solo entregar te quita menos.
- **Huir** tiene sentido de noche (60 %) y con mucha carga, si te da igual el calor (+8).
- El agente que patrulla la plaza (`talkCop`) te hace un control siempre que le hablas con algún gramo encima y sin protección.

### 2.6 Calor y redada

<!-- auto:calorOk -->
Comprobado con el juego: redada con calor 90 y no con 89,9 (se lleva las plantas, los gramos y hasta 3.000 € de multa, y deja el calor en 30); −12 al día; con protección, −20 y la redada se para (calor 50, sin quitar nada); +2 por carpa en flor sin filtro.
<!-- /auto:calorOk -->

La redada se decide al cambiar de día, a las 00:00, duermas o no. A esa hora, el calor tiene que estar por debajo de 90. Durante el día, el calor solo baja de tres formas: con un soborno (−10), con una requisa o entregando (−15). Todo lo demás lo hace la bajada diaria (−12, o −20 con protección), y esa bajada llega *después* de mirar la redada. Con 3 carpas en flor sin filtro, el olor suma 6 al día y deja muy poco margen para vender en la calle.

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

## 3. Propuesta: una caja fuerte en el piso

### 3.1 El problema

Hoy el juego no distingue entre lo que llevas encima y lo que guardas en casa. Por eso:

- en cuanto tienes un gramo, cualquier paso por el barrio puede acabar en control, y el control se lleva **toda** tu cosecha;
- con 150 € o más, ya hay ladrones;
- un KO se lleva el 30 % de todo lo que has ahorrado, incluidos los 12.000 € del plazo que llevas al bar.

Así que **no hay nada que decidir** sobre qué sacar de casa, y esa decisión es justo lo que daría tensión a cada salida.

### 3.2 Diseño

Una caja en el piso con dos compartimentos: uno para el dinero y otro para los cogollos (`S.caja = { money, buds }`).

- Lo que guardas no cuenta como «encima» para nada: ni para los encuentros, ni para el soborno, ni para lo que te quitan.
- Se abre pulsando A delante de ella: «Guardar todo / Guardar dinero / Guardar cogollos / Sacar…».
- La mochila separa las dos cosas: «N g encima · M g en la caja».

| Variante | Cómo se consigue | Capacidad | En una redada | Robo de Darko (cap. 7) |
|---|---|---|---|---|
| **A · Caja de sobremesa** | En la tienda de Kiko, desde el capítulo 2, por 120 € | 5.000 € y 1 kg | La encuentran siempre: se llevan los gramos y la mitad del dinero | Se la llevan entera |
| **B · Caja empotrada** | Por el ordenador, desde el capítulo 4, por 380 €. Llega al día siguiente y la instala Kiko | 50.000 € y 2,5 kg | La encuentran 1 de cada 4 veces | Resiste: se llevan lo que esté fuera |
| **C · La caja de Maite** | Detrás del diploma de la Copa de 1998 (7, 1). La pista está en el registro del ordenador: «20 años de cultivos… y la combinación es el año de mi premio» | 20.000 € y 2 kg | La encuentran 1 de cada 4 veces | Resiste |

La **C** es la que mejor encaja en la historia: da sentido al diploma de la tía, no necesita tienda y conecta con la Copa. Se puede combinar con la A como paso intermedio, o con la B como mejora en el imperio.

### 3.3 Reglas que cambian

| Dónde | Hoy | Con la caja |
|---|---|---|
| `onStepEnd` (encuentros) | Cuentan `totalBuds()` y `S.money`, es decir, todo | Solo lo que llevas fuera de la caja. La fórmula no cambia: lo guardado sale de `S.buds` y de `S.money` |
| `copRound` (soborno) | Pagas con todo tu dinero: si tienes bastante, siempre llegas | Solo con el que llevas encima. Hay que decidir cuánto sacar «por si acaso», y ese dinero atrae ladrones si pasa de 150 €. El juego ya tiene el texto: «No llevas tanto dinero encima» |
| `confiscate` y el KO del ladrón | Se llevan de todo | Solo de lo que llevas fuera |
| `raidEvent` | Todas las plantas, todos los gramos y una multa de hasta 3.000 € | Lo de fuera, siempre. Lo de la caja, según la variante. La multa sale primero de lo de fuera y después de la caja |
| `newDay` (luz) | La factura de la luz sale de `S.money` | De lo de fuera y, si no llega, de la caja. Si no, guardándolo todo la luz saldría gratis |
| Kiko (regalo) | Con menos de 15 €, sin semillas, sin plantas y sin gramos, te da 2 semillas de Skunk #1 | Que cuente también lo de la caja. Si no, guardando el dinero tendrías semillas gratis cada vez |
| Kiko, ordenador, plazos de Baltasar, Iñaki, jurado | Pagas o vendes con todo lo que tienes | Solo con lo que llevas encima. El ordenador, que está en el piso, paga de la caja |
| `harvest` | Los cogollos van a la mochila | Igual. Opcional: «Guardar en la caja» al cosechar, si cabe |
| Partida guardada | — | `S.caja` en `newState` y migración de las partidas viejas (con la caja vacía) |

### 3.4 Efecto: lo mismo, con y sin caja

La tabla compara viajes de ida y vuelta en tres casos:

- **Hoy:** llevas encima todo lo que tienes.
- **Con caja:** llevas solo lo que hace falta para el viaje.
- **Con caja y el soborno encima:** además, llevas el precio del soborno, para poder pagarlo si te paran.

Cada celda da tres cifras: la probabilidad de cruzarte con un control, la de cruzarte con un ladrón y lo que pierdes de media. Se cuenta el primer encuentro de cada tramo (después vienen 24 pasos tranquilos). En el control se elige la mejor opción en euros y, con el ladrón, la mejor forma de pelear. Los supuestos de cada fila están en la lista de debajo. La tabla sale solo del modelo, porque la caja todavía no existe en el juego.

<!-- auto:caja -->
| Ida y vuelta | Hoy: control / ladrón · pérdida media | Con caja | Con caja y el soborno encima |
|---|---|---|---|
| Cap. 3 · ir a comprar a Kiko (200 €) | 22,9 % / 10,0 % · −170 € | 0,0 % / 5,5 % · 0 € | igual |
| Cap. 4 · vender 10 g a Iñaki | 67,8 % / 22,4 % · −789 € | 43,3 % / 11,9 % · −18 € | 43,3 % / 25,9 % · −33 € |
| Cap. 4 · vender 40 g en la plaza, de noche | 55,0 % / 35,0 % · −607 € | 32,9 % / 38,5 % · −40 € | 32,9 % / 38,5 % · −79 € |
| Cap. 5 · pagar 12.000 € a Baltasar | 57,7 % / 13,8 % · −910 € | 0,0 % / 8,8 % · 0 € | igual |
| Cap. 8 · cargar 2 kg a Iñaki | 67,8 % / 22,4 % · −3.646 € | 43,3 % / 25,9 % · −877 € | 43,3 % / 25,9 % · −946 € |
<!-- /auto:caja -->

<!-- auto:cajaSup -->
- **Cap. 3 · ir a comprar a Kiko (200 €):** calor 30, reputación 20, vida 30, sin spray y 1 bocata; gramos a 7,60 €/g. Hoy: 300 g y 2.000 € a la ida, 300 g y 1.800 € a la vuelta. Con caja: 200 € a la ida, 0 € a la vuelta.
- **Cap. 4 · vender 10 g a Iñaki:** calor 50, reputación 40, vida 36, sin spray y 1 bocata; gramos a 7,60 €/g. Hoy: 400 g y 5.000 € a la ida, 390 g y 5.091 € a la vuelta. Con caja: 10 g y 0 € a la ida, 91 € a la vuelta; con el soborno, 245 € más en cada tramo.
- **Cap. 4 · vender 40 g en la plaza, de noche:** calor 60, reputación 40, vida 36, 1 spray y 1 bocata, de noche; gramos a 7,60 €/g. Hoy: 400 g y 5.000 € a la ida, 360 g y 5.300 € a la vuelta. Con caja: 40 g y 0 € a la ida, 300 € a la vuelta; con el soborno, 300 € más en cada tramo.
- **Cap. 5 · pagar 12.000 € a Baltasar:** calor 70, reputación 60, vida 44, 2 sprays y 1 bocata; gramos a 7,60 €/g. Hoy: 600 g y 13.000 € a la ida, 600 g y 1.000 € a la vuelta. Con caja: 12.000 € a la ida, 0 € a la vuelta.
- **Cap. 8 · cargar 2 kg a Iñaki:** calor 50, reputación 150, vida 60, 2 sprays y 1 bocata; gramos a 3,80 €/g. Hoy: 5.000 g y 40.000 € a la ida, 3.000 g y 47.600 € a la vuelta. Con caja: 2.000 g y 0 € a la ida, 7.600 € a la vuelta; con el soborno, 1.240 € más en cada tramo.
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

### 3.5 Implementación (si se aprueba)

- **HTML:**
  - `08-mundo.js`: `S.caja` y la migración;
  - `11-historia.js` o `09-cultivo.js`: el menú de la caja, la tienda o el ordenador, `raidEvent`, la factura de la luz y el regalo de Kiko;
  - `12-menus.js`: la mochila;
  - `04-mapas.js`: el mueble (variantes A y B). La C usa el diploma que ya existe;
  - arte original: un sprite de caja de 16 × 16 o el diploma abierto.
- **Godot (0.2.0):** lo mismo en `src/` y en los oráculos. `npm run godot` regenera datos, arte y pantallas, y `tests/historia.gd` tiene que seguir dando 0 diferencias.
- **Tests:**
  - un paso nuevo en `test-historia.js`: guardar, salir con 0 g y que no haya ningún control, y una redada con la caja;
  - en `analisis-riesgos.js`, jugar también los viajes de § 3.4 con la caja de verdad (hoy, esa tabla solo sale del modelo);
  - un caso reservado nuevo, con la caja.
- **Docs:** GUION (textos de la caja), GDD, MAPA y CHANGELOG.

### 3.6 El robo de Darko (opcional, capítulo 7)

1. La primera noche del capítulo 7 en que duermas con más de 1.000 € o 100 g fuera de la caja, entran en el piso: «Te despierta un ruido. La puerta está forzada».
2. Se llevan la mitad de lo que haya fuera de la caja, y la caja entera si es la de sobremesa.
3. A la mañana siguiente llega un SMS de Darko: «Te dije que esto no se acababa ahí».

Así se cierra el hilo de la Copa y la caja tiene su momento en la historia.

## Cómo regenerar

```bash
export CHROMIUM_PATH=$(ls -d /opt/pw-browsers/chromium-*/chrome-linux/chrome | head -1)
npm run analisis                          # tablas de este documento; sale con 1 si el modelo y el juego no coinciden
node tools/analisis-riesgos.js --n 5000   # más rápido (antes, node tools/build.js)
node tools/analisis-riesgos.js --reservado casos.json   # solo comprueba (paso, ladrón, policía y una ruta), no escribe
```

Las tablas se reescriben solas, pero el texto no: si las cifras cambian mucho, revisa las conclusiones.

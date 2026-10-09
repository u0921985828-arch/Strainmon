# Documento de diseño · Ribera Verde

Todas las cifras están sacadas del código de `src/js`. Si cambias un número allí, cámbialo también aquí. Las tablas de variedades, mapas y tienda se generan solas en [GENETICA.md](GENETICA.md) y [MAPA.md](MAPA.md).

## 1. Ficha

- **Género:** RPG de gestión y cultivo con combates por turnos.
- **Plataforma:** móvil primero (APK de Android y navegador), en un único archivo HTML; también se juega en tablet y PC. Solo en horizontal: la pantalla del juego llena el móvil con un reborde fino y los mandos flotan encima, fijos (cruceta abajo a la izquierda, A/B abajo a la derecha, SONIDO y START arriba a la derecha). En vertical sale el aviso «Gira el móvil».
- **Pantalla:** 160 px de alto y de 240 a 400 px de ancho (siempre par), según la proporción del móvil; en tablets más cuadradas que 3:2 se queda en 240 y sobran bandas arriba y abajo. Se escala sin suavizado, con píxeles cuadrados; casillas de 16 px.
- **Letra:** Atkinson Hyperlegible en los textos y Press Start 2P en los títulos.
- **Público:** adulto (trata de cannabis, venta ilegal y sobornos, con un guion en tono serio).
- **Objetivo:** pagar los 30.000 € que debía la tía Maite a Don Baltasar en tres plazos y ganar la Copa de Ribera; después, levantar tu imperio (rangos por facturación) y completar la Genoteca.
- **Cifras reales (1.10):** precios, vatios, consumo, gramos, multas y deuda son los de un cultivo de interior en España. Lo único comprimido es el tiempo. Tablas de equipo, montajes y precios en [ECONOMIA.md](ECONOMIA.md), que se genera sola.

## 2. Bucle principal

Plantar → cuidar (agua, abono, plagas) y sacar esquejes de las buenas → cosechar (gramos, fenotipo y, a veces, semillas) → vender en la calle o al por mayor (dinero, calor, reputación) → pagar plazos e invertir (carpas, focos, macetas, semillas) → cruzar y estabilizar variedades más potentes → Copa → libertad → imperio.

## 3. Tiempo

- 1 segundo real = 6 minutos de juego, así que **un día dura 4 minutos reales**. El reloj se para en diálogos, menús y combates.
- **Escala del cultivo:** una cosecha dura de 2,5 a 5 días de juego, así que **un día de juego son unas 4 semanas de cultivo**. Lo que se cobra por día (la luz) cuenta esas 4 semanas: 392 h de foco (18 h en crecimiento y 12 en floración) y 672 h para lo que va día y noche (ventilador y extractor).
- **Noche: de 21:00 a 06:00.** Los ladrones aparecen ×2,5, huir de la policía pasa del 45 % al 60 % y suena otra música. El cielo se oscurece entre las 19:00 y las 21:00 y aclara entre las 05:00 y las 07:00, con un tono naranja de 17:30 a 20:30.
- La vida sube 1 punto cada 30 minutos de juego.
- **Cama:** «dormir hasta las 7» o «siesta de 3 h». Rellena la vida, guarda la partida y hace pasar el tiempo para las plantas.
- **Inicio:** día 1 a las 08:00, con 150 €, 30 de vida, el armario de 60 con un CFL y 2 macetas de 7 L, y 1 bocata.

## 4. Cultivo

| Fase | Progreso |
|---|---|
| Germinando | 0 – 12 % |
| Plántula | 12 – 35 % |
| Vegetativo | 35 – 65 % |
| Floración | 65 – 100 % |
| Lista | 100 % |

- Al plantar: agua 70 %, salud 100 %. Se gasta 1 semilla (o un esqueje, que empieza de plántula, 12 %).
- **Agua:** −3,5 × `riego` puntos por hora (foco × maceta). Regar la pone al 100 %; con riego automático, las garrafas (una por maceta, media cosecha) o el depósito del goteo (unas cinco cosechas con la carpa llena) riegan solos la que baja del 50 %, gastando la mitad de los litros de la maceta por cada 100 %, y se rellenan desde la vista de carpa. Una cosecha gasta ~1,3 L por litro de tierra.
- **Crecimiento por hora:** `1 / (días × 24) × crec`. Se multiplica ×0,4 con agua < 20 %, ×0 sin agua y ×1,1 con abono; `crec` sale del foco, de la maceta (ver «Equipo») y del clima de la sala (−6 % por grado fuera de 18-30 °C, hasta ×0,4; −1,5 % por punto fuera del 40-60 % de humedad, hasta ×0,7).
- **Salud:** −4/h sin agua y −2,5/h con plaga; +1/h con agua > 30 % y sin plaga; en floración, con la humedad por encima del 60 %, moho: −0,1/h por punto de más (lo avisa al despertar). A 0 la planta muere.
- **Plaga** (araña roja, puntos rojos en las hojas): probabilidad por hora `0,006 × (100 − resistencia) / 40` (×0,8 en maceta de tela y ×0,7 con ventilador) mientras la planta no está lista. Se quita con insecticida.
- **Abono:** una dosis por planta (la botella de 1 L trae 4). Da +25 % de cosecha, +10 % de velocidad y +0,3 de THC.
- **Cosecha (g por planta):** `mín(tope de la maceta, W × g/W ÷ plazas × rend de la maceta × rinde/34 × (0,4 + 0,6 × salud/100) × abono 1,25 × fenotipo.y)`. 34 g es el rinde medio de las variedades: la ficha enseña el de cada una en g/m² (LED a 400 W/m², abonada). Una plaza vacía es luz perdida.
- **THC final:** `THC × fenotipo.t × (0,85 + 0,15 × salud/100) + thc del foco + 0,3 (abono)`, con un tope de 35 %.
- **Semillas al cosechar:** las de tienda son feminizadas: un 12 % de las plantas sale hermafrodita y da 1-3 semillas; las demás, ninguna. Las landraces (como el Afghani que te da Kiko) y tus líneas ya fijadas son regulares: algún macho poliniza unas flores y cada planta da 1-3. Una línea sin fijar (F1-F3) se poliniza entre ella y da 2-5.
- **Esquejes:** en crecimiento (del 20 %, ya plántula hecha, al 65 %, antes de florecer) se le saca un esqueje a una planta (−5 de salud). Es la misma planta, con su fenotipo. Enraíza en el propagador (hasta 12) y se seca si no se planta antes de que acabe el día siguiente.

### Equipo: carpas, focos y macetas (1.6; cifras reales en la 1.10)

El cultivo va en carpas dentro del piso. Desde fuera se ven cerradas (techo, frente negro y puerta de cremallera); con A delante se abre la vista de carpa: macetas, plantas y el foco colgando. Con plantas vivas el foco está encendido (cono de luz y una línea de luz bajo la puerta). Precios, kWh y montajes de ejemplo: [ECONOMIA.md](ECONOMIA.md).

| Carpa | Plazas | Foco máximo | Maceta máxima | Cómo se consigue |
|---|---|---|---|---|
| Armario 60×60×160 | 2 | 250 W | 11 L | el de la tía (con un CFL y macetas de plástico de 7 L) |
| Armario 80×80×180 | 3 | 400 W | 18 L | growshop, 90 €, desde el capítulo 3: sustituye al de 60 en el sitio A (se quedan plantas, foco y macetas) |
| Carpa 100×100×200 | 4 | 480 W | 25 L | growshop, 120 €, desde el capítulo 2, en el sitio B (trae CFL y macetas de 7 L) |
| Carpa 150×100×200 | 6 | 720 W | 25 L | growshop, 140 €, desde el capítulo 4: sustituye a la de 100 (se quedan plantas, foco y macetas) |
| Carpa 120×120×200 | 6 | 720 W | 25 L | growshop, 150 €, desde el capítulo 5, en el sitio C, junto a la cama, cuando ya hay carpa en B (trae CFL y macetas de 7 L) |

- **Sitios del piso:** A (el armario, 1 casilla), B (al fondo, 2 casillas) y C (junto a la cama, 2 casillas; se marca en el suelo cuando ya hay carpa en B). Cada carpa tiene su sitio y como mucho hay una por sitio.
- **Orden de las plazas:** las de A, luego las de B y luego las de C. Al cambiar una carpa por otra mayor, cada planta y cada maceta se quedan en su carpa y en su plaza; las plazas nuevas salen vacías y con maceta de 7 L.

| Foco | Ilumina | g/W | Crece | THC | Riego | Precio |
|---|---|---|---|---|---|---|
| CFL 125 W | 60×60 cm | 0,25 | — | — | ×1 | de serie |
| Sodio 250 W | 70×70 cm | 0,45 | +5 % | +0,3 | ×1,3 | 85 € (cap. 2) |
| Sodio 400 W | 100×100 cm | 0,5 | +5 % | +0,5 | ×1,4 | 100 € (cap. 3) |
| Sodio 600 W | 120×120 cm | 0,55 | +5 % | +0,7 | ×1,5 | 120 € (cap. 4) |
| LED 100 W | 60×60 cm | 0,65 | +5 % | +0,3 | ×1 | 110 € (cap. 1) |
| LED 200 W | 80×80 cm | 0,7 | +10 % | +0,6 | ×1,05 | 220 € (cap. 2) |
| LED 480 W | 120×120 cm | 0,8 | +10 % | +1,0 | ×1,1 | 500 € (cap. 3) |
| LED 720 W | 150×150 cm | 0,85 | +15 % | +1,4 | ×1,15 | 950 € (cap. 5) |

| Maceta | Tope por planta | Cosecha | Crece | Riego | Plagas | Precio |
|---|---|---|---|---|---|---|
| Plástico 7 L | 56 g | — | — | ×1 | ×1 | de serie |
| Tela 11 L | 92 g | +5 % | +5 % | ×1,25 | ×0,8 | 3 € (cap. 1) |
| Plástico 18 L | 144 g | — | −5 % | ×0,8 | ×1 | 2 € (cap. 2) |
| Tela 25 L | 210 g | +5 % | — | ×1,1 | ×0,8 | 4 € (cap. 3) |

- **Gramos por vatio:** el foco da `W × g/W` gramos por cosecha (sin abono), repartidos entre las plazas de la carpa; la maceta pone el tope (unos 8 g por litro de tierra). Cultivador medio y bien abonado: CFL unos 0,3 g/W, sodio 0,55-0,7, LED 0,8-1,05.
- **Intensidad:** `dens = mín(1, W ÷ (m² de la carpa × 400 W/m²))`. `crec = foco.crece × (0,85 + 0,15 × dens) × maceta.crece`; `thc = foco.thc × dens`; `riego = foco.riego × maceta.riego` (el riego automático, de las garrafas o del depósito); las plagas, `maceta.plagas × (0,7 con ventilador)`. La ficha de la carpa enseña sus W/m².
- **Límites:** el foco no puede pasar de los vatios de la carpa (calor) y la maceta, de sus litros.
- **Cambiar:** las macetas, en una plaza vacía (A → «Cambiar maceta»); los focos, desde el foco de la vista de carpa (A → «Cambiar foco») o al comprarlos («¿Lo cuelgo ya?»). Lo que se quita va a la mochila.
- **Factura de la luz:** cada día, por cada carpa con alguna planta viva (las vacías van apagadas), `(W del foco × 392 h + W de los extras × 672 h) ÷ 1000 × 0,16 €/kWh`. CFL 8 €, sodio 400 W 25 €, LED 720 W 45 €.
- **Extras** (uno de cada por carpa; se compran en el growshop, «¿Te lo pongo ya?», o se ponen luego desde la vista de carpa: ▲ hasta el foco y A):

| Extra | Efecto en su carpa | Consumo | Precio |
|---|---|---|---|
| Ventilador de pinza | plagas ×0,7 | 25 W día y noche | 20 € (cap. 1) |
| Extractor con filtro de carbón | anula el olor (ver abajo) | 75 W día y noche | 110 € (cap. 2) |
| Garrafas de riego | una por maceta, de 0,65 L por litro de tierra (media cosecha): riegan solas la que baja del 50 %; se rellenan desde la carpa | — | 15 € (cap. 1) |
| Riego por goteo | depósito de 6,5 L por litro de tierra que admite la carpa (650 L la de 100: unas cinco cosechas con la carpa llena); con él, las garrafas vuelven a la mochila | — | 1.200 € (cap. 4) |

  La tienda solo ofrece un extra si alguna carpa lo necesita y no lo llevas ya en la mochila.

- **Olor:** cada día, cada carpa sin filtro con alguna planta viva en floración (progreso ≥ 65 %) suma **+2 de calor**. Se aplica después de la bajada diaria, así que cuenta para la redada del día siguiente.

## 5. Genética

- La **mesa de genética** se desbloquea en el capítulo 4. Gasta 1 semilla de la madre y 1 del padre y da **2 semillas** del resultado.
- **El árbol por generaciones (1.11, ver [GENETICA.md](GENETICA.md)):** las recetas son los híbridos clásicos, de las landraces a la 3.ª generación. Cada receta es un conjunto de variedades «hoja»: las de 3 o 4 padres se hacen en varios cruces (Skunk #1 = Afghani × Colombian Gold y luego × Acapulco Gold), porque un híbrido propio recuerda sus hojas. En 4 recetas manda el orden (madre × padre): Afghani × Skunk #1 = Critical Mass, Skunk #1 × Afghani = Super Skunk, Northern Lights × Haze = NL5 × Haze, Haze × Northern Lights = Silver Haze. La meta es la *Jack Herer* (Haze × Northern Lights × Shiva Skunk). Las de padres no documentados llevan «≈ origen incierto» en la ficha.
- **Estabilizar (1.9):** lo que sale de un cruce nuevo es una F1 inestable: sus plantas salen muy distintas entre sí (ver «Fenotipos»). Cruzándola consigo misma en la mesa (2 semillas → 1) sube a F2, F3 y queda estable en la F4; entre generaciones hay que cultivarla para tener semillas.
- **Tipo genético (1.10):** cada variedad dice en su ficha si es landrace, línea estable, cruce F1 de tienda (con sus padres), polihíbrido o una línea propia F1-F3. Lemon Haze y Chemdawg son polihíbridos, Super Skunk es un cruce F1 (Skunk #1 × Afghani) y las demás de la tienda y las de receta son líneas estables.
- **Fenotipos (1.10):** cada semilla es una planta distinta. Al germinar tira su fenotipo, THC × (1 + σ·z) y gramos × (1 + σ·z), cada uno por su lado (z normal, entre ×0,6 y ×1,5). σ sale del tipo: estable 0,06 · cruce F1 de tienda 0,07 · F1 propia 0,08 · F3 0,10 · landrace 0,10 · polihíbrido 0,11 · F2 0,12. Con THC × gramos ≥ 1,35 es **estrella**: 1 de cada ~16.000 en una línea estable, ~2.000 en un F1 de tienda, ~100 en una landrace, ~60 en un polihíbrido y ~40 en una F2 (la ficha lo dice). Su cosecha va a un lote aparte (★) que se vende y se presenta a la Copa por separado; con THC × gramos ≤ 0,75 es **floja**. El fenotipo se sabe al cosecharla: para quedarse con una estrella hay que haberle sacado esquejes antes.
- Cualquier otra pareja da un **híbrido propio** determinista: misma pareja, mismo resultado. THC = media de los padres −1,5 / +2,0 (tope 33 %).
- Una variedad queda **descubierta** al conseguir su semilla o su cogollo. Los híbridos propios cuentan para el objetivo del capítulo 4.
- **Landraces:** Afghani (Kiko, capítulo 4), Hindu Kush (abuela Txaro a cambio de 5 g), Acapulco Gold (arbusto del parque en 2,26) y Malawi Gold (Iñaki, tras venderle 10 g).
- **Semillas de tienda (1.10):** feminizadas, a precio por semilla (Skunk #1 5 €, Lemon Haze 9 €, OG Kush 10 €, Blueberry 8 €, Mango 7 €, Purple Afghani 8 €), en sobres de 1, 3 (−5 %), 5 (−10 %) y 10 (−15 %); desde el capítulo 3, bolsa de 50 a granel (−40 %).
- **Banco de semillas (1.9):** desde el capítulo 2, el PC de la tía pide sobres de 10 semillas de las 12 landraces del catálogo de Strainmon (Michoacán, Punto Rojo, Thai, Kif y Beldia; en el 3, Chitral Kush, Nepalese, Congolese, Lamb's Bread y Oaxaca; en el 4, Luang Prabang y Panama Red), de 20 a 45 €. El pedido llega al día siguiente.

## 6. Venta en la calle

Desde el capítulo 2 aparecen cada día **min(10, 4 + reputación/15 + 1 desde el capítulo 4)** clientes con `$` en aceras, plaza y caminos del barrio. Desde la 1.10, además, 2 (3 desde el capítulo 4) en los astilleros, estudiantes y currelas, y otros tantos en el barrio alto desde el capítulo 3, pijos y turistas.

| Cliente | Multiplicador | Gramos | THC mínimo | Desde |
|---|---|---|---|---|
| Estudiante | ×0,85 | 2–5 | — | cap. 2 |
| Currela | ×1,00 | 3–8 | — | cap. 2 |
| Turista | ×1,15 | 4–9 | 15 % (40 % de las veces) | cap. 3 |
| Pijo | ×1,35 | 5–12 | 15 + capítulo (tope 24) | cap. 4 |

- **Precio base:** `(4 + THC × 0,2) × multiplicador × gramos`: de 6,4 €/g (12 %) a 10 €/g (30 %), lo que se paga en la calle en España. Una Skunk #1 al 12 % vale 6,4 €/g.
- **Rebaja** (×0,85): siempre aceptada, +3 de reputación.
- **Justo** (×1): 92 % de aceptación, +2 de reputación.
- **Caro** (×1,3): aceptación `0,30 + (THC − mínimo) × 0,05`, donde «mínimo» es el THC que pide el cliente (14 si no pide nada); +0,25 si es pijo y +0,15 si es turista, entre 10 % y 90 %. +1 de reputación.
- Si rechaza: −1 de reputación y el cliente se va.
- **Cada venta:** calor +3 + 0,5 × gramos.
- **Zonas (1.10):** en los astilleros, el gramo × 1,2, pero son las esquinas de Darko: 1 de cada 3 ventas acaba en un combate con uno de sus chicos.
- **Iñaki** (muelle, desde el capítulo 2): compra 10 g al día a ×1,2. Suma +3 de calor y +2 de reputación. La primera vez regala Malawi Gold.
- **Al por mayor (1.10, Iñaki desde el capítulo 3):** `(2 + THC × 0,1)` €/g, de 3,2 a 5 €/g, en cargas de 100 g, 250 g, 500 g, 1 kg… hasta lo que admite al día (1 kg; más en el imperio). Una carga al día: calor +2 + gramos/100 (1.10; antes, /250) y +1 de reputación. Es lo que hace falta para mover las cosechas de las carpas grandes.
- **Encargos de Don Baltasar (1.10, capítulo 8):** 2 kg (5 y 10 kg en los dos últimos rangos) a 6 €/g, entregados a Toño de noche en el almacén de los astilleros en 2 días; +3 de calor y +2 de reputación. Toño se lleva primero los lotes más flojos. Si no llegas: reputación −10 y 5 días sin encargos.

## 7. Calor policial y reputación

- **El calor sube:** con cada venta, con el olor de cada carpa en floración sin filtro de carbón (+2 al día), al huir de la policía (+8), si un agente honrado rechaza tu soborno (la requisa resta 15 y después suma 20: +5 neto si tenías 15 o más) y si rechazas a Molina (+10).
- **El calor baja:** −12 cada día (−20 con protección), −10 al sobornar y −15 en cada requisa o al entregar.
- Con 70 o más salta un aviso.
- **Redada:** al cambiar de día con **calor ≥ 90**. Sin protección pierdes todas las plantas y los cogollos de fuera de la caja fuerte, pagas una multa de hasta 3.000 € (de lo de fuera y, si no llega, de la caja) y el calor queda en 30. La caja la encuentran 1 de cada 4 veces: se llevan sus gramos y la mitad de su dinero. Con la protección de Molina no hay redada y el calor queda en 50.
- **Reputación:** sube con las ventas, al vencer ladrones (+2), con Iñaki (+2) y con la Copa (+20). Trae más clientes y facilita HABLAR con policías y ladrones.

## 8. Encuentros

En los tres mapas de fuera, desde el capítulo 2; dentro de las casas, nunca. Se comprueban en cada paso y, tras un encuentro, hay 25 pasos de calma. Solo cuenta lo que llevas encima: lo de la caja fuerte, no.

- **Policía**, si llevas gramos: `(0,002 + calor × 0,00025) × 0,4 con protección × policía de la zona`.
- **Ladrón**, si llevas 5 g o más o 150 € o más: `0,004 × 2,5 de noche × 3 en hierba alta × ladrones de la zona`.

| Zona (1.10, `ZONAS`) | Policía | Ladrones | Precio del gramo |
|---|---|---|---|
| Ribera Verde (el barrio) | ×1 | ×1 | ×1 |
| Barrio alto (al norte: plaza del Ensanche y comisaría) | ×1,5 | ×0,5 | ×1 |
| Astilleros (al este del muelle: almacén y esquinas de Darko) | ×0,5 | ×2 | ×1,2 |
- El **agente que patrulla** la plaza te para si le hablas con gramos encima y sin protección.

## 9. Combate contra ladrones

Probabilidades de cada encuentro, de cada estrategia y del soborno, por paso y por trayecto: [ANALISIS.md](ANALISIS.md).

- **Ladrón:** vida `12 + 2 × capítulo + 0…4`; golpea entre `2 + capítulo/4` y `4 + capítulo/2` (divisiones redondeadas hacia abajo). Desde el capítulo 5 (1.10), +4 de vida y +1 de golpe.

| Opción | Efecto |
|---|---|
| LUCHAR → Puñetazo | 92 % de acierto, 4–7 de daño |
| LUCHAR → Patada | 65 % de acierto, 8–12 de daño |
| MOCHILA → Spray de pimienta | 12–16 de daño seguro |
| MOCHILA → Bocata | +15 de vida |
| HABLAR | Se va con probabilidad `0,25 + reputación/300` (25 %–70 %) |
| HUIR | 50 % |

- **Victoria:** 20–40 € + 10 × capítulo, +2 de reputación y **+2 de VIDA máxima** (tope 60).
- **Derrota:** pierdes la mitad de los gramos de cada variedad y el 30 % del dinero que llevas encima, y te despiertas en casa 6 horas después con la vida llena.

## 10. Combate contra la policía

La barra del agente mide la **sospecha**, que es tu calor.

| Opción | Efecto |
|---|---|
| SOBORNAR | Cuesta `40 + 4 × calor + 0,5 × gramos + 0,05 × dinero encima` (1.10), y se paga con lo que llevas encima. Funciona y baja el calor 10, salvo un 15 % de agentes honrados (sin protección y desde el capítulo 3), que requisan, multan y suben el calor. |
| HABLAR | Te deja ir con probabilidad `0,30 + reputación/250 − calor/300` (10 %–85 %). Si falla, requisa y multa. |
| HUIR | 45 % (+15 % de noche). Si sale bien, calor +8; si falla, requisa, multa y −5 de vida. |
| ENTREGAR | Pierdes los gramos sin multa. |

**Requisa:** todos los gramos. **Multa:** 601 € (la mínima por tenencia en la vía pública de la Ley de Seguridad Ciudadana), como mucho el dinero que lleves. El calor baja 15.

## 11. Deuda e historia

| Capítulo | Se abre con | Objetivo |
|---|---|---|
| 1 La herencia | partida nueva | leer la carta → visitar a Kiko → primera cosecha |
| 2 La calle | primera cosecha | 300 € en ventas |
| 3 La deuda | 300 € vendidos (aparece Toño) | ir al bar y pagar **3.000 €** en 7 días, desde que aparece Toño |
| 4 Genética | primer pago | recoger la mesa de Kiko, sacar en ella 2 variedades de receta y cosechar una planta de cada |
| 5 El sargento | la 2.ª de receta cosechada | pagar **12.000 €** en 10 días; Molina ofrece protección |
| 6 La Copa de Ribera | segundo pago | ganar la Copa (20 g con más de 26,8 % de THC) |
| 7 Libertad | ganar la Copa (+5.000 €) | pagar **15.000 €** en 7 días; Darko roba el piso |
| 8 Tu imperio | último pago: «DEUDA SALDADA» | facturar para subir de rango, los encargos de Baltasar y completar la Genoteca |

- **Deuda (1.10):** 30.000 €, a escala de los precios reales. Con ellos, un jugador que reinvierte paga los plazos en unas 4, 8 y 9 cosechas, lo mismo que la deuda de 5.000 € con los números de la 1.9 (simulación y tabla en [ECONOMIA.md](ECONOMIA.md#la-deuda)). Las partidas viejas pasan a la deuda nueva del capítulo en que están.
- **Retraso:** el primer día después del plazo llega Toño. Suma un 20 % del plazo (redondeado a 100 €) al plazo y a la deuda, quita 15 de vida y da 5 días más. Puede repetirse, pero al tercer plazo vencido de la partida (`S.vencidos`) Toño se lleva además la carpa más grande del piso (B o C) con su foco, sus extras y sus plantas; sin ninguna de las dos, la mitad del dinero que llevas encima. Después, la cuenta vuelve a 0.
- **Protección de Molina** (desde el capítulo 5, 1.500 € cada 10 días; 1.10): encuentros con la policía ×0,4, ningún agente rechaza sobornos, el calor baja 20 al día y no hay redadas. La primera vez se paga en la plaza y después en la comisaría del barrio alto, también por adelantado (cada pago suma 10 días a `S.protHasta`). Al acabarse, un SMS.
- **Copa:** se presentan 20 g de un lote (los fenotipos estrella van aparte) y se pierden ganes o no. Gana con más de 26,8 % (redondeado a una décima); premio, 5.000 €. Se puede repetir.
- **El robo de Darko (1.10, capítulo 7):** la primera vez que duermes con más de 1.000 € o 100 g fuera de la caja fuerte, se llevan la mitad del dinero y de cada lote de fuera. Una sola vez.
- **Tu imperio (capítulo 8):** saldada la deuda, el juego sigue. Lo facturado desde el último pago da el rango, y cada rango sube lo que Iñaki carga al día; al subir, Iñaki avisa por SMS.

| Rango | Facturado | Carga al por mayor al día |
|---|---|---|
| Cultivador | 0 € | 1 kg |
| Proveedor del barrio | 25.000 € | 2 kg |
| Distribuidor de la ría | 100.000 € | 5 kg |
| Mayorista del norte | 250.000 € | 10 kg |

## 12. Tienda, bar y regalos

- **Growshop:** precios y capítulos en [MAPA.md](MAPA.md#tienda-de-kiko).
- **Bar El Ancla (Josune):** pintxo 4 € (+12 de vida), kalimotxo 3 € (+6 de vida) y rumores con pistas.
- **Objetos de fuera:** spray de pimienta ×2, abono (3 dosis) y bocata ×2 en el suelo; 50 €, insecticida y Acapulco Gold escondidos en arbustos; en el barrio alto, 80 € en un arbusto, y en los astilleros, 2 sprays más en el suelo. Ver [MAPA.md](MAPA.md#objetos).
- **Kiko** regala 3 semillas de Skunk #1 y 2 dosis de abono al conocerlo, y 2 semillas más si no tienes semillas, plantas ni cogollos y tienes menos de 15 €, contando la caja fuerte.
- **Abuela Txaro:** 5 g en el parque → 2 semillas de Hindu Kush y 3 bocatas; desde el capítulo 4, en su casa, 10 g de una índica (70 % o más) → 3 semillas de Chitral Kush, 3 bocatas y +5 de reputación.

## 13. Guardado

`localStorage`: la partida va en `riberaVerde_v1` y la preferencia de sonido en `rv_sound`. Se guarda al dormir, al cambiar de capítulo, en el final, desde START → GUARDAR y desde el ordenador del piso. Si el navegador bloquea el almacenamiento, el juego funciona igual pero no guarda.

## 14. Caja fuerte (1.10)

Lo que hay dentro (`S.caja = {money, buds, nivel}`) no va encima: no cuenta para los encuentros ni para el soborno, y no se lo llevan un control, un ladrón ni el robo de Darko. Se abre con A delante del diploma: guardar o sacar dinero, cogollos o todo.

| Caja | Cómo se consigue | Capacidad |
|---|---|---|
| La caja de la tía | Detrás del diploma, con la combinación 1998 (la pista, en las notas del ordenador). Dentro hay 300 € | 20.000 € y 2 kg |
| La caja empotrada | Por el ordenador desde el capítulo 4, con la de la tía abierta: 380 €. Kiko la instala al día siguiente, con lo que ya hubiera dentro | 50.000 € y 2,5 kg |

- **Redada:** la encuentran 1 de cada 4 veces (sus gramos y la mitad de su dinero).
- **Lo que se paga desde el piso** (la luz, el ordenador y la multa de la redada) sale de lo de fuera y, si no llega, de la caja. Todo lo demás (tienda, plazos, Iñaki, jurado, sobornos), solo de lo de encima.
- Probabilidades de cada viaje con y sin caja: [ANALISIS.md](ANALISIS.md#3-la-caja-fuerte-del-piso).

# Documento de diseño · Ribera Verde

Todas las cifras están sacadas del código de `src/js`. Si cambias un número allí, cámbialo también aquí. Las tablas de variedades, mapas y tienda se generan solas en [GENETICA.md](GENETICA.md) y [MAPA.md](MAPA.md).

## 1. Ficha

- **Género:** RPG de gestión y cultivo con combates por turnos.
- **Plataforma:** móvil primero (APK de Android y navegador), en un único archivo HTML; también se juega en tablet y PC. Solo en horizontal: la pantalla del juego llena el móvil con un reborde fino y los mandos flotan encima, fijos (cruceta abajo a la izquierda, A/B abajo a la derecha, SONIDO y START arriba a la derecha). En vertical sale el aviso «Gira el móvil».
- **Pantalla:** 160 px de alto y de 240 a 400 px de ancho (siempre par), según la proporción del móvil; en tablets más cuadradas que 3:2 se queda en 240 y sobran bandas arriba y abajo. Se escala sin suavizado, con píxeles cuadrados; casillas de 16 px.
- **Letra:** Atkinson Hyperlegible en los textos y Press Start 2P en los títulos.
- **Público:** adulto (trata de cannabis, venta ilegal y sobornos, con un guion en tono serio).
- **Objetivo:** pagar los 5.000 € que debía la tía Maite a Don Baltasar en tres plazos, ganar la Copa de Ribera y completar la Genoteca.

## 2. Bucle principal

Plantar → cuidar (agua, abono, plagas) → cosechar (gramos + semillas) → vender en la calle (dinero, calor, reputación) → pagar plazos e invertir (carpas, focos, macetas, semillas) → cruzar variedades más potentes → Copa → libertad.

## 3. Tiempo

- 1 segundo real = 6 minutos de juego, así que **un día dura 4 minutos reales**. El reloj se para en diálogos, menús y combates.
- **Noche: de 21:00 a 06:00.** Los ladrones aparecen ×2,5, huir de la policía pasa del 45 % al 60 % y suena otra música. El cielo se oscurece entre las 19:00 y las 21:00 y aclara entre las 05:00 y las 07:00, con un tono naranja de 17:30 a 20:30.
- La vida sube 1 punto cada 30 minutos de juego.
- **Cama:** «dormir hasta las 7» o «siesta de 3 h». Rellena la vida, guarda la partida y hace pasar el tiempo para las plantas.
- **Inicio:** día 1 a las 08:00, con 150 €, 30 de vida, 2 macetas y 1 bocata.

## 4. Cultivo

| Fase | Progreso |
|---|---|
| Germinando | 0 – 12 % |
| Plántula | 12 – 35 % |
| Vegetativo | 35 – 65 % |
| Floración | 65 – 100 % |
| Lista | 100 % |

- Al plantar: agua 70 %, salud 100 %. Se gasta 1 semilla.
- **Agua:** −3,5 × `riego` puntos por hora (foco × maceta). Regar la pone al 100 %.
- **Crecimiento por hora:** `1 / (días × 24) × crec`. Se multiplica ×0,4 con agua < 20 %, ×0 sin agua y ×1,1 con abono; `crec` sale del foco y de la maceta (ver «Equipo»).
- **Salud:** −4/h sin agua y −2,5/h con plaga; +1/h con agua > 30 % y sin plaga. A 0 la planta muere.
- **Plaga** (araña roja, puntos rojos en las hojas): probabilidad por hora `0,006 × (100 − resistencia) / 40` (×0,8 en maceta de tela) mientras la planta no está lista. Se quita con insecticida.
- **Abono:** una dosis por planta. Da +25 % de cosecha, +10 % de velocidad y +0,3 de THC.
- **Cosecha:** `g = rinde × (0,4 + 0,6 × salud/100) × abono 1,25 × rend`.
- **THC final:** `THC × (0,85 + 0,15 × salud/100) + thc (foco) + 0,3 (abono)`.
- **Semillas al cosechar:** entre 1 y 3.

### Equipo (1.6): carpas, focos y macetas

El cultivo va en carpas dentro del piso. Desde fuera se ven cerradas (techo, frente negro y puerta de cremallera); al entrar desaparecen el techo y las paredes de delante y de la derecha, se ven la pared del fondo y la izquierda, una bandeja de cultivo continua sobre un bastidor, con una maceta por plaza, y los focos colgando medio transparentes. Con plantas vivas el foco está encendido (cono de luz y una línea de luz bajo la puerta).

| Carpa | Plazas | Foco máximo | Maceta máxima | Cómo se consigue |
|---|---|---|---|---|
| Armario 60×60 | 2 | 250 W | 11 L | el de la tía (con un CFL y macetas de plástico de 7 L) |
| Carpa 100×100 | 4 | 480 W | 25 L | growshop, 450 €, desde el capítulo 2 (trae CFL y macetas de 7 L) |
| Carpa 150×100 | 6 | 720 W | 25 L | growshop, 900 €, desde el capítulo 4: sustituye a la de 100 (se quedan plantas, foco y macetas) |

| Foco | W | Cubre | Cosecha | Crece | THC | Riego | Precio |
|---|---|---|---|---|---|---|---|
| CFL 125 W | 125 | 2 | — | — | — | ×1 | de serie |
| Sodio 250 W | 250 | 2 | +25 % | +5 % | +0,3 | ×1,3 | 120 € (cap. 2) |
| Sodio 400 W | 400 | 4 | +35 % | +5 % | +0,5 | ×1,4 | 220 € (cap. 3) |
| Sodio 600 W | 600 | 6 | +45 % | +5 % | +0,7 | ×1,5 | 350 € (cap. 4) |
| LED 200 W | 200 | 2 | +30 % | +10 % | +0,6 | ×1,05 | 260 € (cap. 2) |
| LED 480 W | 480 | 4 | +45 % | +10 % | +1,0 | ×1,1 | 600 € (cap. 3) |
| LED 720 W | 720 | 6 | +60 % | +15 % | +1,4 | ×1,15 | 1000 € (cap. 5) |

| Maceta | Cosecha | Crece | Riego | Plagas | Precio |
|---|---|---|---|---|---|
| Plástico 7 L | — | — | ×1 | ×1 | de serie |
| Tela 11 L | +15 % | +5 % | ×1,25 | ×0,8 | 20 € (cap. 1) |
| Plástico 18 L | +25 % | −5 % | ×0,8 | ×1 | 30 € (cap. 2) |
| Tela 25 L | +40 % | — | ×1,1 | ×0,8 | 45 € (cap. 3) |

- **Cobertura:** `cob = min(1, cubre / plazas)`. `rend = (1 + (foco.cosecha − 1) × cob) × (0,6 + 0,4 × cob) × maceta.cosecha`; `crec = foco.crece × (0,85 + 0,15 × cob) × maceta.crece`; `thc = foco.thc × cob`; `riego = foco.riego × maceta.riego`. Un foco pequeño en una carpa grande no llega a todas las plantas y rinden menos que con el CFL bien puesto.
- **Límites:** el foco no puede pasar de los vatios de la carpa (calor) y la maceta, de sus litros.
- **Cambiar:** las macetas, en una plaza vacía (A en la bandeja → «Cambiar maceta»); los focos, desde la pared de la carpa (A → «Cambiar foco») o al comprarlos («¿Lo cuelgo ya?»). Lo que se quita va a la mochila.
- **Factura de la luz:** cada día, `vatios × 0,02 €` por cada carpa con alguna planta viva (las vacías van apagadas).
- Lo de serie (CFL en el armario y macetas de 7 L) da exactamente el cultivo de antes de la 1.6.

## 5. Genética

- La **mesa de genética** se desbloquea en el capítulo 4. Gasta 1 semilla de la madre y 1 del padre y da **2 semillas** del resultado.
- Hay 20 recetas fijas (ver [GENETICA.md](GENETICA.md)): 13 llevan hasta la *Ghost Train Haze* (29 % de THC) y 7 son los híbridos clásicos que salieron de las landraces (Haze, Northern Lights, Afghan Kush, Shiva Skunk, Silver Haze y Super Silver Haze).
- **Estabilizar (1.9):** lo que sale de un cruce nuevo es una F1 inestable (da de 0,8 a 1,1 veces los gramos normales; el THC no cambia). Cruzándola consigo misma en la mesa (2 semillas → 1) sube a F2, F3 y queda estable en la F4; entre generaciones hay que cultivarla para tener semillas.
- Cualquier otra pareja da un **híbrido propio** determinista: misma pareja, mismo resultado. THC = media de los padres −1,5 / +2,0 (tope 33 %).
- Una variedad queda **descubierta** al conseguir su semilla o su cogollo. Los híbridos propios cuentan para el objetivo del capítulo 4.
- **Landraces:** Afghani (Kiko, capítulo 4), Hindu Kush (abuela Txaro a cambio de 5 g), Acapulco Gold (arbusto del parque en 2,26) y Malawi Gold (Iñaki, tras venderle 10 g).
- **Banco de semillas (1.9):** desde el capítulo 2, el PC de la tía pide sobres de 3 semillas de las 12 landraces del catálogo de Strainmon (Michoacán, Punto Rojo, Thai, Kif y Beldia; en el 3, Chitral Kush, Nepalese, Congolese, Lamb's Bread y Oaxaca; en el 4, Luang Prabang y Panama Red), de 35 a 90 €. El pedido llega al día siguiente.

## 6. Venta en la calle

Desde el capítulo 2 aparecen cada día **min(10, 4 + reputación/15 + 1 desde el capítulo 4)** clientes con `$` en aceras, plaza y caminos.

| Cliente | Multiplicador | Gramos | THC mínimo | Desde |
|---|---|---|---|---|
| Estudiante | ×0,85 | 2–5 | — | cap. 2 |
| Currela | ×1,00 | 3–8 | — | cap. 2 |
| Turista | ×1,15 | 4–9 | 15 % (40 % de las veces) | cap. 3 |
| Pijo | ×1,35 | 5–12 | 15 + capítulo (tope 24) | cap. 4 |

- **Precio base:** `(3 + THC × 0,4) × multiplicador × gramos`. Una Skunk #1 al 12 % vale 7,8 €/g.
- **Rebaja** (×0,85): siempre aceptada, +3 de reputación.
- **Justo** (×1): 92 % de aceptación, +2 de reputación.
- **Caro** (×1,3): aceptación `0,30 + (THC − mínimo) × 0,05`, donde «mínimo» es el THC que pide el cliente (14 si no pide nada); +0,25 si es pijo y +0,15 si es turista, entre 10 % y 90 %. +1 de reputación.
- Si rechaza: −1 de reputación y el cliente se va.
- **Cada venta:** calor +3 + 0,5 × gramos.
- **Iñaki** (muelle, desde el capítulo 2): compra 10 g al día a ×1,2. Suma +3 de calor y +2 de reputación. La primera vez regala Malawi Gold.

## 7. Calor policial y reputación

- **El calor sube:** con cada venta, al huir de la policía (+8), si un agente honrado rechaza tu soborno (la requisa resta 15 y después suma 20: +5 neto si tenías 15 o más) y si rechazas a Molina (+10).
- **El calor baja:** −12 cada día (−20 con protección), −10 al sobornar y −15 en cada requisa.
- Con 70 o más salta un aviso.
- **Redada:** al cambiar de día con **calor ≥ 90**. Sin protección pierdes todas las plantas y los cogollos, pagas una multa de hasta 300 € y el calor queda en 30. Con la protección de Molina no hay redada y el calor queda en 50.
- **Reputación:** sube con las ventas, al vencer ladrones (+2), con Iñaki (+2) y con la Copa (+20). Trae más clientes y facilita HABLAR con policías y ladrones.

## 8. Encuentros

Solo en el barrio, desde el capítulo 2. Se comprueban en cada paso y, tras un encuentro, hay 25 pasos de calma.

- **Policía**, si llevas gramos: `(0,002 + calor × 0,00025) × 0,4 con protección`.
- **Ladrón**, si llevas 5 g o más o 150 € o más: `0,004 × 2,5 de noche × 3 en hierba alta`.
- El **agente que patrulla** la plaza te para si le hablas con gramos encima y sin protección.

## 9. Combate contra ladrones

- **Ladrón:** vida `12 + 2 × capítulo + 0…4`; golpea entre `2 + capítulo/4` y `4 + capítulo/2` (divisiones redondeadas hacia abajo).

| Opción | Efecto |
|---|---|
| LUCHAR → Puñetazo | 92 % de acierto, 4–7 de daño |
| LUCHAR → Patada | 65 % de acierto, 8–12 de daño |
| MOCHILA → Spray de pimienta | 12–16 de daño seguro |
| MOCHILA → Bocata | +15 de vida |
| HABLAR | Se va con probabilidad `0,25 + reputación/300` (25 %–70 %) |
| HUIR | 50 % |

- **Victoria:** 20–40 € + 10 × capítulo, +2 de reputación y **+2 de VIDA máxima** (tope 60).
- **Derrota:** pierdes la mitad de los gramos de cada variedad y el 30 % del dinero, y te despiertas en casa 6 horas después con la vida llena.

## 10. Combate contra la policía

La barra del agente mide la **sospecha**, que es tu calor.

| Opción | Efecto |
|---|---|
| SOBORNAR | Cuesta `40 + 4 × calor + 0,5 × gramos`. Funciona y baja el calor 10, salvo un 15 % de agentes honrados (sin protección y desde el capítulo 3), que requisan, multan y suben el calor. |
| HABLAR | Te deja ir con probabilidad `0,30 + reputación/250 − calor/300` (10 %–85 %). Si falla, requisa y multa. |
| HUIR | 45 % (+15 % de noche). Si sale bien, calor +8; si falla, requisa, multa y −5 de vida. |
| ENTREGAR | Pierdes los gramos sin multa. |

**Requisa:** todos los gramos. **Multa:** `60 + 1,5 × calor`, como mucho el dinero que lleves. El calor baja 15.

## 11. Deuda e historia

| Capítulo | Se abre con | Objetivo |
|---|---|---|
| 1 La herencia | partida nueva | leer la carta → visitar a Kiko → primera cosecha |
| 2 La calle | primera cosecha | 300 € en ventas |
| 3 La deuda | 300 € vendidos (aparece Toño) | ir al bar y pagar **1.000 €** en 7 días |
| 4 Genética | primer pago | recoger la mesa de Kiko y descubrir 8 variedades |
| 5 El sargento | 8 variedades descubiertas | pagar **2.000 €** en 10 días; Molina ofrece protección |
| 6 La Copa de Ribera | segundo pago | ganar la Copa (20 g con más de 26,8 % de THC) |
| 7 Libertad | ganar la Copa (+2.500 €) | pagar **2.000 €** en 7 días |
| 8 La genoteca | último pago y final | juego libre: completar la Genoteca |

- **Retraso:** el primer día después del plazo llega Toño. Suma 300 € al plazo y a la deuda, quita 15 de vida y da 5 días más. Puede repetirse.
- **Protección de Molina** (desde el capítulo 5, 500 € una sola vez): encuentros con la policía ×0,4, ningún agente rechaza sobornos, el calor baja 20 al día y no hay redadas.
- **Copa:** se presentan 20 g de una variedad y se pierden ganes o no. Gana con más de 26,8 % (redondeado a una décima). Se puede repetir.

## 12. Tienda, bar y regalos

- **Growshop:** precios y capítulos en [MAPA.md](MAPA.md#tienda-de-kiko).
- **Bar El Ancla (Josune):** pintxo 4 € (+12 de vida), kalimotxo 3 € (+6 de vida) y rumores con pistas.
- **Objetos del barrio:** spray de pimienta ×2, fertilizante ×3 y bocata ×2 en el suelo; 50 €, insecticida y Acapulco Gold escondidos en arbustos. Ver [MAPA.md](MAPA.md#objetos).
- **Kiko** regala 3 semillas de Skunk #1 y 2 de fertilizante al conocerlo, y 2 semillas más si no tienes semillas, plantas ni cogollos y llevas menos de 15 €.

## 13. Guardado

`localStorage`: la partida va en `riberaVerde_v1` y la preferencia de sonido en `rv_sound`. Se guarda al dormir, al cambiar de capítulo, en el final, desde START → GUARDAR y desde el ordenador del piso. Si el navegador bloquea el almacenamiento, el juego funciona igual pero no guarda.

# Documento de diseño · Ribera Verde

Todas las cifras están sacadas del código de `src/js`. Si cambias un número allí, cámbialo también aquí. Las tablas de variedades, mapas y tienda se generan solas en [GENETICA.md](GENETICA.md) y [MAPA.md](MAPA.md).

## 1. Ficha

- **Género:** RPG de gestión y cultivo con combates por turnos.
- **Plataforma:** navegador de escritorio o móvil, en un único archivo HTML.
- **Pantalla:** 240 × 160 px escalados sin suavizado; casillas de 16 px.
- **Público:** adulto (trata de cannabis, venta ilegal y sobornos, en tono de comedia).
- **Objetivo:** pagar los 5.000 € que debía la tía Maite a Don Baltasar en tres plazos, ganar la Copa de Ribera y completar la Genoteca.

## 2. Bucle principal

Plantar → cuidar (agua, abono, plagas) → cosechar (gramos + semillas) → vender en la calle (dinero, calor, reputación) → pagar plazos e invertir (macetas, LED, semillas) → cruzar variedades más potentes → Copa → libertad.

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
- **Agua:** −3,5 puntos por hora. Regar la pone al 100 %.
- **Crecimiento por hora:** `1 / (días × 24)`. Se multiplica ×0,4 con agua < 20 %, ×0 sin agua, ×1,1 con abono y ×1,1 con LED.
- **Salud:** −4/h sin agua y −2,5/h con plaga; +1/h con agua > 30 % y sin plaga. A 0 la planta muere.
- **Plaga** (araña roja, puntos rojos en las hojas): probabilidad por hora `0,006 × (100 − resistencia) / 40` mientras la planta no está lista. Se quita con insecticida.
- **Abono:** una dosis por planta. Da +25 % de cosecha, +10 % de velocidad y +0,3 de THC.
- **LED** (500 €, una vez): +30 % de cosecha, +10 % de velocidad y +0,5 de THC.
- **Cosecha:** `g = rinde × (0,4 + 0,6 × salud/100) × abono 1,25 × LED 1,3`.
- **THC final:** `THC × (0,85 + 0,15 × salud/100) + 0,5 (LED) + 0,3 (abono)`.
- **Semillas al cosechar:** entre 1 y 3.
- **Macetas:** empiezas con 2 y puedes llegar a 6 (150 € cada una, desde el capítulo 2).

## 5. Genética

- La **mesa de genética** se desbloquea en el capítulo 4. Gasta 1 semilla de la madre y 1 del padre y da **2 semillas** del resultado.
- Hay 13 recetas fijas (ver [GENETICA.md](GENETICA.md)) que llevan hasta la *Leyenda de la Ría* (31 % de THC).
- Cualquier otra pareja da un **híbrido propio** determinista: misma pareja, mismo resultado. THC = media de los padres −1,5 / +2,0 (tope 33 %).
- Una variedad queda **descubierta** al conseguir su semilla o su cogollo. Los híbridos propios cuentan para el objetivo del capítulo 4.
- **Landraces:** Atlas Rif (Kiko, capítulo 4), Hindú Valle (abuela Txaro a cambio de 5 g), Acapulco Oro (arbusto del parque en 2,26) y Malawi Sol (Iñaki, tras venderle 10 g).

## 6. Venta en la calle

Desde el capítulo 2 aparecen cada día **min(10, 4 + reputación/15 + 1 desde el capítulo 4)** clientes con `$` en aceras, plaza y caminos.

| Cliente | Multiplicador | Gramos | THC mínimo | Desde |
|---|---|---|---|---|
| Estudiante | ×0,85 | 2–5 | — | cap. 2 |
| Currela | ×1,00 | 3–8 | — | cap. 2 |
| Turista | ×1,15 | 4–9 | 15 % (40 % de las veces) | cap. 3 |
| Pijo | ×1,35 | 5–12 | 15 + capítulo (tope 24) | cap. 4 |

- **Precio base:** `(3 + THC × 0,4) × multiplicador × gramos`. Una Ría Skunk al 12 % vale 7,8 €/g.
- **Rebaja** (×0,85): siempre aceptada, +3 de reputación.
- **Justo** (×1): 92 % de aceptación, +2 de reputación.
- **Caro** (×1,3): aceptación `0,30 + (THC − mínimo) × 0,05`, donde «mínimo» es el THC que pide el cliente (14 si no pide nada); +0,25 si es pijo y +0,15 si es turista, entre 10 % y 90 %. +1 de reputación.
- Si rechaza: −1 de reputación y el cliente se va.
- **Cada venta:** calor +3 + 0,5 × gramos.
- **Iñaki** (muelle, desde el capítulo 2): compra 10 g al día a ×1,2. Suma +3 de calor y +2 de reputación. La primera vez regala Malawi Sol.

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
| 8 Leyenda | último pago y final | juego libre: completar la Genoteca |

- **Retraso:** el primer día después del plazo llega Toño. Suma 300 € al plazo y a la deuda, quita 15 de vida y da 5 días más. Puede repetirse.
- **Protección de Molina** (desde el capítulo 5, 500 € una sola vez): encuentros con la policía ×0,4, ningún agente rechaza sobornos, el calor baja 20 al día y no hay redadas.
- **Copa:** se presentan 20 g de una variedad y se pierden ganes o no. Gana con más de 26,8 % (redondeado a una décima). Se puede repetir.

## 12. Tienda, bar y regalos

- **Growshop:** precios y capítulos en [MAPA.md](MAPA.md#tienda-de-kiko).
- **Bar El Ancla (Josune):** pintxo 4 € (+12 de vida), kalimotxo 3 € (+6 de vida) y rumores con pistas.
- **Objetos del barrio:** spray de pimienta ×2, fertilizante ×3 y bocata ×2 en el suelo; 50 €, insecticida y Acapulco Oro escondidos en arbustos. Ver [MAPA.md](MAPA.md#objetos).
- **Kiko** regala 3 semillas de Ría Skunk y 2 de fertilizante al conocerlo, y 2 semillas más si no tienes semillas, plantas ni cogollos y llevas menos de 15 €.

## 13. Guardado

`localStorage`: la partida va en `riberaVerde_v1` y la preferencia de sonido en `rv_sound`. Se guarda al dormir, al cambiar de capítulo, en el final, desde START → GUARDAR y desde el ordenador del piso. Si el navegador bloquea el almacenamiento, el juego funciona igual pero no guarda.

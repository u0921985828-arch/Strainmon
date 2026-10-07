# Economía de Ribera Verde (1.10)

> Generado automáticamente con `node tools/generar-docs.js` a partir de los datos del juego. No editar a mano: cambia `src/js/09-cultivo.js`, `10-calle.js` u `11-historia.js` y regenera.

Desde la 1.10, unidades, precios y potencias son los reales de un growshop y un cultivo de interior en España. Lo único comprimido es el tiempo: una cosecha dura de 2,5 a 5 días de juego (unas 4 semanas reales por día), así que lo que va «por día» (la luz) cuenta las horas de esas 4 semanas.

## Focos

Un día de juego cuenta 392 h de foco (4 semanas a 18 h en crecimiento y 12 h en floración) a 0,16 €/kWh. g/W: gramos por vatio de una cosecha con la carpa llena, sin abono (abonando, ×1,25).

| Foco | Precio | Ilumina | g/W | kWh/día | Luz/día | Desde |
|---|---|---|---|---|---|---|
| CFL 125 W | de serie | 60×60 cm | 0,25 | 49 | 8 € | — |
| Sodio 250 W | 85 € | 70×70 cm | 0,45 | 98 | 16 € | cap. 2 |
| Sodio 400 W | 100 € | 100×100 cm | 0,5 | 157 | 25 € | cap. 3 |
| Sodio 600 W | 120 € | 120×120 cm | 0,55 | 235 | 38 € | cap. 4 |
| LED 100 W | 110 € | 60×60 cm | 0,65 | 39 | 6 € | cap. 1 |
| LED 200 W | 220 € | 80×80 cm | 0,7 | 78 | 12 € | cap. 2 |
| LED 480 W | 500 € | 120×120 cm | 0,8 | 188 | 30 € | cap. 3 |
| LED 720 W | 950 € | 150×150 cm | 0,85 | 282 | 45 € | cap. 5 |

## Carpas y macetas

| Carpa | Precio | Plazas | Foco máx. | Maceta máx. |
|---|---|---|---|---|
| Armario 60×60×160 | la de la tía | 2 | 250 W | 11 L |
| Armario 80×80×180 | 90 € (cap. 3) | 3 | 400 W | 18 L |
| Carpa 100×100×200 | 120 € (cap. 2) | 4 | 480 W | 25 L |
| Carpa 120×120×200 | 150 € (cap. 5) | 6 | 720 W | 25 L |
| Carpa 150×100×200 | 140 € (cap. 4) | 6 | 720 W | 25 L |

| Maceta | Precio | Tope por planta | Extra |
|---|---|---|---|
| Plástico 7 L | de serie | 56 g | — |
| Tela 11 L | 3 € | 92 g | tela: +5 % y menos plagas |
| Plástico 18 L | 2 € | 144 g | — |
| Tela 25 L | 4 € | 210 g | tela: +5 % y menos plagas |

Tope: unos 8 g por litro de tierra (la de tela, +5 %). Por mucho foco que pongas, una planta en 7 L no pasa de 56 g.

Extras: ventilador 20 € (25 W día y noche), extractor con filtro de carbón 110 € (75 W día y noche; 672 h por día de juego), goteo 55 €.

## Cuánto da una cosecha

`gramos por planta = mín(tope de la maceta, W × g/W ÷ plazas × rend de la maceta × rinde de la variedad / 34 × salud × abono × fenotipo)`

Skunk #1 sana y abonada, fenotipo medio (cosecha de 2,5 días):

| Montaje | Gramos por cosecha | g/W | Luz por cosecha |
|---|---|---|---|
| Armario 60 + CFL 125 W, 2 × 7 L | 46 g | 0,37 | 20 € |
| Armario 60 + LED 200 W, 2 × 7 L | 112 g (tope de la maceta) | 0,56 | 33 € |
| Carpa 100 + LED 480 W, 4 × 18 L | 564 g | 1,18 | 75 € |
| Carpa 150 + LED 720 W, 6 × 25 L | 948 g | 1,32 | 113 € |

## Vender

- **Calle:** 6,4-10 €/g según el THC (× 0,85 estudiante, × 1 currela, × 1,15 turista, × 1,35 pijo; rebaja × 0,85, caro × 1,3). Cada cliente quiere 2-12 g.
- **Al por mayor (Iñaki, en el muelle, desde el capítulo 3):** 3,2-5 €/g, lotes de 100 g para arriba, una carga al día de hasta 1 kg (más en el imperio). Cada carga sube el calor 2 + 1 por cada 100 g.
- **Zonas:** en los astilleros, el gramo × 1,2; en Puerto Viejo, el gramo × 1,15; en Valdehierro, el gramo × 0,9 (las esquinas de Darko: 1 de cada 3 ventas acaba en pelea).
- **Encargos de Don Baltasar (capítulo 8):** 6 €/g por 2, 5 o 10 kg según el rango del imperio, entregados de noche en el almacén de los astilleros en 2 días.
- **Multas:** policía en la calle, 601 € (la mínima de la Ley de Seguridad Ciudadana); redada en el piso, hasta 3.000 € y se llevan las plantas y los cogollos de fuera de la caja fuerte.
- **Protección del sargento Molina:** 1.500 € cada 10 días.

## La caja fuerte

Lo que hay dentro no va encima: no cuenta para los encuentros ni se lo llevan un control, un ladrón o Darko. En una redada la encuentran 25 de cada 100 veces (sus gramos y la mitad de su dinero).

| Caja | Cómo se consigue | Capacidad |
|---|---|---|
| La caja de la tía | Detrás del diploma (la combinación, en las notas del ordenador), con 300 € dentro | 20.000 € y 2 kg |
| La caja empotrada | Por el ordenador desde el capítulo 4, con la de la tía ya abierta: 380 €. La instala Kiko al día siguiente, con lo que ya hubiera dentro | 50.000 € y 2,5 kg |

## Semillas

Feminizadas de tienda, Skunk #1 5 €, Lemon Haze 9 €, OG Kush 10 €, Blueberry 8 €, Mango 7 €, Purple Afghani 8 € la semilla. Sobres: 1, 3 (−5 %), 5 (−10 %), 10 (−15 %); desde el capítulo 3, bolsa de 50 a granel (−40 %). Landraces del banco del PC: sobres de 10 por 20-45 €.

## La deuda

30.000 € en tres plazos: 3.000 € en 7 días (capítulo 3), 12.000 € en 10 días (capítulo 5) y 15.000 € en 7 días tras la Copa (capítulo 7; el premio de la Copa son 5.000 €). El primer plazo corre desde que aparece Toño. Si un plazo vence, Toño suma un 20 % del plazo y da 5 días más; al tercer plazo vencido, además, se lleva la carpa más grande del piso (sin carpas, la mitad del dinero que llevas encima).

Por qué 30.000 €: con equipo, precios y venta al por mayor reales, un jugador que reinvierte cada cosecha en lo que más rinde por euro (focos LED, macetas grandes, carpas) paga el primer plazo en unas 4 cosechas (6 días), el segundo en unas 8 y el último en unas 9: lo mismo que la deuda de 5.000 € con los números de la 1.9 (3, 5 y 11 cosechas). Con los plazos viejos, la historia se acabaría en 7 cosechas.

## Tu imperio

Saldada la deuda, el juego sigue: cada rango se gana facturando desde el último pago y sube lo que Iñaki carga al día.

| Rango | Facturado | Carga al día |
|---|---|---|
| Cultivador | 0 € | 1 kg |
| Proveedor del barrio | 25.000 € | 2 kg |
| Distribuidor de la ría | 100.000 € | 5 kg |
| Mayorista del norte | 250.000 € | 10 kg |

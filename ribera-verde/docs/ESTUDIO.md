# Estudio · por qué aburre y qué lo haría explotar

Este estudio parte de lo que dijo el usuario desde que contó que el juego le aburre. Las cifras salen del código (`godot/datos/datos.json`, `godot/src/*.gd`) y de `docs/ECONOMIA.md` y `docs/ANALISIS.md`. Las referencias, de búsquedas en la web, con sus fuentes al final. Una revisión independiente encontró 7 fallos en la primera versión (cosas que ya existen y una cifra inflada), y esta versión ya los corrige.

## 1. Lo que pediste, con tus palabras

| # | Lo que dijiste | Qué exige |
|---|---|---|
| 1 | «El juego ya me aburre… le falta historia, falta contexto» | Una trama que dé sentido a lo que haces |
| 2 | «Que no aburra, no canse, no sea repetitivo» | Variedad de verdad, no más de lo mismo |
| 3 | «Sobre todo que no sea de pasarte el juego en una semana» | Duración larga, sin relleno |
| 4 | «Que tenga trama, no escatimes» | Una historia larga y con peso |
| 5 | «Algo más asemejado como el Schedule… el sistema» | Progresión por sistemas que se abren poco a poco |
| 6 | «Está más enfocado a la venta y narcotráfico» (en contra) | El centro no puede ser vender ni traficar |
| 7 | (El nombre del juego: *Landrace Hunters*) | El centro es **cazar y criar genéticas** |

## 2. Lo que dicen los números

| Hecho | Cifra | De dónde |
|---|---|---|
| Un día de juego | 4 min reales si se juega entero (`MS_PER_MIN` 166,7 ms × 1.440); la cama salta la noche o un día entero con una pulsación | `datos.json`, `cultivo.gd` |
| Pagar la deuda siguiendo las misiones | los plazos se pagan hacia los días **10, 18 y 20**: unos 20 días de juego, **unos 80 min de reloj** o menos durmiendo | `ECONOMIA.md` |
| Lo que hace avanzar la historia | Cap. 2: vender 300 €. Caps. 3, 5 y 7: **pagar**. Cap. 4: 2 recetas. Cap. 6: un lote de más del 26,8 %. Cap. 7: pantalla final | `ANALISIS.md` § 1.1 |
| Después de la deuda | Cap. 8: facturar 25.000, 100.000 y 250.000 € (`IMPERIO`), encargos de Baltasar, envíos por mar, piso franco, pisos de venta (`PISOS9`) y Hiriburu | `datos.json`, `ANALISIS.md` |
| Lo que ya hay de caza | 104 variedades (87 en la CannaDex); 13 landraces que da la gente o están escondidas (`REGALO`: Txaro, Iñaki, Kiko, Miren, los arbustos…); el trueque de Andoni; el recetario dice dónde sale cada una; cada planta varía su % índica hasta la F4, con su porte, su hoja (`HOJA`) y sus terpenos | `datos.json`, `CLAUDE.md` |
| Lo que ya hay de estaciones | La huerta: una cosecha de exterior al año (vegetativo hasta primeros de agosto), lluvia, helada, nieve y botritis; el clima por el mes; la recolección, sin invierno | `campo.gd` |
| Lo que ya hay de trama | La deuda, Darko (amenaza, robo y ajuste), Miren y la página, Delroy, y el cuaderno azul (commit `6c1d011`): la Copa del 98, Toño cambió el tarro para Baltasar, la lata del manzano y una elección de 3 (contarlo, ir a por Baltasar o guardártelo) | `GUION.md`, `src/hilo.gd` |
| Lo que ya hay de gente | Confianza por persona (`S.rel`), Begoña, vendedores a comisión, la plantilla y sus riesgos, rivales por zona | `datos.json` |

**Conclusión:** al juego **no le faltan sistemas**: tiene caza, estaciones, gente, trama y delegar. Le falta que **apunten a algo**. La historia se cierra en unos 80 minutos pagando, y lo que viene después es **vender y traficar a lo grande**, justo lo que no quieres. La caza existe, pero es corta (13 landraces y se acaba) y no lleva a ninguna parte.

## 3. Diagnóstico: de más a menos grave

1. **El motor es el dinero.** La historia avanza al pagar, y optimizar la vacía en una tarde. Es el mismo error que la crítica señala en Schedule I: «cuando entra mucho dinero, se vuelve aburrido» y «el final es un simulador de repartos».
2. **El final del juego es narcotráfico.** Después de la deuda, la meta es facturar (`IMPERIO`) con cargas, barcos, piso franco y pisos de venta. Lo que debería ser el corazón (la genética) se queda en un rincón.
3. **La caza es corta y no lleva a nada.** Las landraces de la gente y los escondites se encuentran pronto. Los fenotipos varían (índica, porte, hoja y terpenos), pero no hay rarezas que perseguir ni nada que hacer con ellas más que venderlas.
4. **Las estaciones solo mandan en la huerta.** El interior, la gente, las fiestas y la Copa son iguales en enero que en agosto.
5. **La trama es corta y se cierra pronto.** La deuda acaba en el cap. 7, el cuaderno azul se resuelve en una tarde y lo nuevo (Bilbao, el muelle, las iglesias, la nave) no tiene papel.
6. **El tiempo no frena.** La cama salta días, así que atar algo solo a una fecha no alarga nada: se duerme hasta ella. Lo que alarga de verdad es lo que **pide jugar**, como criar generaciones, cosechar, buscar o convencer a alguien.

## 4. Qué enseñan otros juegos

| Juego | Qué funciona | Qué falla | Qué nos llevamos |
|---|---|---|---|
| **Schedule I** | Desbloquear cambia cómo juegas | Al final solo se reparte y no hay escalado ni final («no hay nada más que hacer» a las 25 h) | Desbloquear por **hitos**, no por dinero; nada de final de repartos |
| **Stardew Valley** | Las estaciones dan el ritmo (cultivos, fiestas y recolección distintos), el descubrimiento es poco a poco y las colecciones del Centro Cívico dan metas largas | — | Que las estaciones manden fuera de la huerta, fiestas fijas y **colecciones que restauran algo** |
| **Pokémon** (cría) | Encontrar en un sitio concreto, la rareza y criar hasta el ejemplar perfecto | — | **Rarezas** heredables y criar por generaciones |

## 5. Las mejoras (sobre lo que ya hay, sin duplicar)

### 1 · Que el final sea la genética, no el tráfico
- **La meta del cap. 8 deja de ser facturar.** Pasa a ser el **banco de semillas de la tía** (ver 3) y la fama como criador. `IMPERIO`, los barcos y los pisos siguen ahí como opción, no como camino.
- El dinero se usa en la caza (viajes, semillas raras, equipo de cría), no para hacerse más grande.

### 2 · La caza larga, encima de la que ya existe
- **Rarezas heredables.** Sobre los fenotipos de ahora (índica, porte, hoja y terpenos), rasgos raros de 1 entre 50: hoja morada, enana, doble cosecha, aroma único. Se heredan al cruzar y se fijan hasta la F4, generación a generación. **Eso sí alarga**: cada generación es una cosecha jugada, no una fecha.
- **Más landraces por estación y por gente,** siguiendo el patrón de `REGALO` y del trueque: la de la costa con un pescador cuando hay temporal; la del monte en la romería; una por fiesta. Pasar de 13 a unas 30.
- **Expediciones** (lo más caro): viajes de varios días con la escena del viaje de perfil que ya existe, a sitios nuevos fuera de la comarca. Cuestan dinero y riesgo y traen genética que no hay en otro sitio.
- **El cuaderno de caza:** el recetario ya dice dónde sale cada semilla. Le falta guardar **cada fenotipo raro encontrado**, con dónde y cuándo, como un álbum.

### 3 · El banco de semillas de la tía (como el Centro Cívico)
- Se restaura en la asociación entregando **colecciones**: «las cinco del Hindu Kush», «las de la costa», «tres rarezas fijadas en F4», «la Haze del 98 estabilizada».
- Cada colección arregla una parte del local y abre algo: el laboratorio, la cámara fría, la sala de catas o la siguiente expedición.
- Es la meta larga que une la caza y la trama, y sustituye a facturar como final.

### 4 · La trama larga, siguiendo al cuaderno azul
Lo que ya hay se respeta: Toño cambió el tarro, Baltasar lo pagó y la elección de 3 es del Acto I. La historia sigue por la **genética**, no por el mercado:
- **Acto I · La herencia.** La deuda y el cuaderno azul, como están. Cierre: tu primera Copa.
- **Acto II · Quién entró en el piso.** La empotrada estaba forzada antes de llegar tú: alguien buscaba el cuaderno la semana en que murió la tía. Toño queda fuera porque ya está resuelto. Hay tres sospechosos: Darko, un comprador de semillas de Bilbao y Molina. Las pistas están en el teatro, la catedral, Hacienda, el muelle y el ordenador. Lo que elegiste en el Acto I cambia quién te ayuda: si lo contaste en la asociación, Delroy; si fuiste a por Baltasar, él mismo, a regañadientes.
- **Acto III · Las semillas de todos.** Una empresa de semillas inventada quiere **registrar a su nombre** las landraces de la comarca, la Haze del 98 la primera. La lucha es por la genética, no por vender: las asociaciones, Miren y los caseríos contra la empresa. Ganas con lo que has criado y guardado en el banco.
- **Acto IV · El legado.** Los finales salen de lo que hayas hecho con la genética: el banco de semillas abierto de la tía, venderlo todo a la empresa, retirarte al caserío con Miren o la caída si la policía te pilla.
- **Más escenas con la gente que ya está:** Miren, Delroy, la serora, Txaro, Julen y Ekaitz, con arcos de varias escenas que se abren por confianza (`S.rel` ya existe) y por estación.

### 5 · Las estaciones fuera de la huerta
- **Fiestas fijas en el calendario,** que ya existe con sus días señalados: las del barrio en agosto, la romería de la ermita, la feria de semillas de primavera en Bilbao y la **Copa de cada otoño**.
- **La Copa por categorías** (potencia, sabor, landrace pura, cruce propio y extracción), con rivales que mejoran cada año.
- Landraces, clientes y gente que solo están en su estación.

### 6 · Consecuencias de las decisiones de la trama
- Las relaciones, la confianza y los rivales ya existen. Lo que falta es que **las decisiones de la trama** se recuerden: qué hiciste con el cuaderno, a quién acusaste en el Acto II o qué entregaste al banco cambia escenas, ayudas y finales.

## 6. Lo que no haría

- Más venta o narcotráfico. Tampoco más recompensas en esa rama: ya domina el final del juego.
- Frenar con fechas o plazos más largos: la cama los salta y solo alargan sin divertir.
- Progreso con la app cerrada: ya se quitó a propósito (0.52).
- Repetir sistemas que ya existen (delegar, confianza, la cosecha anual de la huerta).

## 7. Prioridad: impacto ÷ coste

| Tanda | Qué | Impacto | Coste | Por qué en este orden |
|---|---|---|---|---|
| 1 | **El banco de semillas** como meta del final, sustituyendo a facturar, con sus primeras colecciones (las landraces que ya hay) | Muy alto | Medio | Da sentido a lo que ya existe sin crear apenas contenido |
| 2 | **Rarezas heredables** y el cuaderno de fenotipos | Muy alto | Medio-alto | Es lo que alarga de verdad (generaciones jugadas) |
| 3 | **Acto II** sobre el cuaderno azul | Alto | Alto | La trama que pediste, enlazada a la elección del Acto I |
| 4 | **Más landraces** por estación y gente (de 13 a unas 30) y fiestas fijas | Alto | Medio | Llena el año con cosas que buscar |
| 5 | **La Copa por categorías** cada otoño | Medio-alto | Medio | El clímax de cada año |
| 6 | **Actos III y IV**, con los finales por la genética | Alto | Alto | El cierre |
| — | **Expediciones** fuera de la comarca | Muy alto | Muy alto | Mapas y arte nuevos: después de la tanda 4, si gusta |

Todo con `Datos.CAL`, como siempre; las partidas de antes se migran.

## 8. Lo que decides tú

1. ¿El final por la genética (el banco de semillas) en vez de facturar? La rama del tráfico se quedaría como opción.
2. ¿Los Actos II a IV así, con la lucha por las semillas en vez de por el mercado?
3. ¿El Acto II oscuro (alguien entró en el piso cuando murió la tía) o más ligero?
4. ¿Empiezo por la tanda 1?

## Fuentes
- [Schedule I · debate en Steam sobre el final (1)](https://steamcommunity.com/app/3164500/discussions/1/599651410936605741)
- [Schedule I · debate en Steam (2)](https://steamcommunity.com/app/3164500/discussions/1/599650454957209648)
- [Schedule I · debate en Steam (3)](https://steamcommunity.com/app/3164500/discussions/1/599649070605219080)
- [Schedule I en OpenCritic](https://opencritic.com/game/19422/schedule-i)
- [Stardew Valley · entrevista a Eric Barone (NPR/WBHM)](https://wbhm.org/npr-story/the-legacy-and-future-of-the-farming-game-stardew-valley)
- [Stardew Valley · las estaciones como ritmo](https://finalboss.io/stardew-valley-why-this-cosy-farming-classic-is)
- [Stardew Valley · el descubrimiento poco a poco](https://engineered.at/articles/happy-10th-birthday-stardew-valley)

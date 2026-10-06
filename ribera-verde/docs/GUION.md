# Guion · Ribera Verde

`{N}` es el nombre que elige el jugador (EDDIE, ÁLEX, LUR, ANDER o uno escrito a mano). Los textos son los del juego. Para cambiarlos, edita `src/js/11-historia.js` (personajes y capítulos), `09-cultivo.js` (carta, mesa, cama y ordenador), `08-mundo.js` (personajes de ambiente, carteles y demás objetos), `03-datos.js` (saludos de los clientes), `10-calle.js` (resto de frases de los clientes), `13-combate.js` (combates) y `15-arranque.js` (intro).

## Premisa

La tía Maite ha muerto y te deja su piso en Ribera Verde, un barrio obrero a orillas de la ría. En el piso hay un armario de cultivo y, además, una deuda: 30.000 € con Don Baltasar, el del bar El Ancla. Con la ayuda de Kiko, el del growshop, que cultivaba con tu tía, aprendes a cultivar, a cruzar genéticas y a vender en la calle mientras esquivas a la policía, a los ladrones del parque y al sargento Molina. Al final tienes que ganarle la Copa de Ribera a Darko, el sobrino de Baltasar, para pagar el último plazo. Saldada la deuda, empieza tu imperio.

## Personajes

| Personaje | Papel | Dónde está |
|---|---|---|
| **{N}** | Protagonista. Hereda el piso y la deuda | — |
| **Kiko** | Mentor. Lleva treinta años con el growshop, conserva genéticas y cultivaba con Maite | Growshop |
| **Tía Maite** | Solo aparece en su carta y en un diploma enmarcado (2.º premio de la Copa 1998) | Piso |
| **Don Baltasar** | Antagonista. Maite le debía 30.000 € | Bar El Ancla |
| **Toño** | Matón de Baltasar | Bar y mensajes |
| **Darko** | Rival. Sobrino de Baltasar y campeón de la Copa | Plaza (desde el cap. 2 hasta que te cruzas con él, y en el cap. 6) |
| **Sargento Molina** | Policía corrupto que vende «protección» | Plaza (desde el cap. 5) |
| **Josune** | Camarera del bar | Bar El Ancla |
| **Abuela Txaro** | Vecina con quimioterapia; Maite la ayudaba. Tiene semillas de Pakistán | Parque |
| **Iñaki** | Marinero y comprador fijo. Trae semillas de sus viajes | Muelle (desde el cap. 2) |
| **Patxi** | Anciano que lleva cuarenta años cultivando en el monte. Sabe de cruces | Plaza, junto a la fuente |
| **Begoña** y **Unai** | Vecina y niño, dan consejos | Calle y plaza |
| **Agente de patrulla** | Policía que hace controles | Plaza (desde el cap. 2) |
| **Jurado** | Juez de la Copa, la de la asociación cannábica del barrio | Plaza (cap. 6) |

## Prólogo

*Pantalla de título → NUEVA PARTIDA. Noche sobre la ría y Kiko en primer plano.*

> **???:** Ribera Verde. Un barrio obrero a orillas de la ría.
> **???:** Me llamo Kiko. Llevo treinta años con el growshop de la esquina.
> **KIKO:** Conservo genéticas: variedades locales de Afganistán, México o la India, y los cruces que salen de ellas.
> **KIKO:** Las apunto todas en un registro, una GENOTECA. Tu tía Maite me ayudaba a mantenerla.
> **KIKO:** Perdona. ¿Cómo te llamabas?
> *[Eliges nombre]*
> **KIKO:** {N}. Hacía años que no te veía por el barrio.
> **KIKO:** Maite murió hace tres semanas. Te ha dejado su piso, su armario de cultivo... y una deuda.
> **KIKO:** Lee la carta que te dejó. Después pásate por el growshop.

## Capítulo 1 · La herencia

*Despiertas en el piso. Objetivo: leer la carta de la mesa.*

> Hay una carta encima de la mesa. Es de la tía Maite.
> **CARTA:** «{N}: si lees esto, el piso es tuyo. Cuídalo.»
> **CARTA:** «Al fondo del salón está mi armario de cultivo. Lo he tenido treinta años y nunca me ha fallado.»
> **CARTA:** «Pásate por el growshop de Kiko, aquí al lado. Él te enseñará lo que yo no pude.»
> **CARTA:** «Le debo dinero a Baltasar, el del bar El Ancla. No es buena gente. Lo siento.»

*Si la vuelves a leer:* La carta de la tía Maite. «Cuida el armario. Y perdona lo de Baltasar.»

*Objetivo: visitar a Kiko.*

> **KIKO:** {N}, pasa. Te pareces a tu tía.
> **KIKO:** Maite y yo cultivamos juntos desde que cerraron los astilleros. Ella tenía mano; yo, paciencia.
> **KIKO:** Para empezar, toma esto.
> Consigues 3 semillas de SKUNK #1. · Consigues 2 dosis de ABONO.
> **KIKO:** La Skunk #1 aguanta casi todo: errores de riego, plagas, frío. Es la mejor para aprender.
> **KIKO:** Planta en las macetas del armario de tu tía y riega cuando baje el agua.
> **KIKO:** El abono da más cogollo. Si ves araña roja, insecticida: lo tengo aquí.
> **KIKO:** Cuando esté lista, cosecha. Son feminizadas: casi nunca dan semilla, pero si sale alguna, guárdala.
> **KIKO:** Las plantas siguen creciendo mientras duermes.

*Objetivo: plantar y conseguir la primera cosecha. Con ella empieza el capítulo 2.*

> **SMS · KIKO:** Primera cosecha. Bien hecho.
> **SMS · KIKO:** La gente que busca material lleva un $ encima. Puedes venderles en la calle.
> **SMS · KIKO:** Cuanto más vendas, más se fijará la policía: es el CALOR. Y de noche hay quien roba.

## Capítulo 2 · La calle

*Objetivo: ganar 300 € vendiendo. Desde ahora hay clientes, controles, ladrones e Iñaki en el muelle. La primera vez que entras en la plaza por el norte, Darko te corta el paso:*

> **DARKO:** Así que tú te has quedado el piso de Maite.
> **DARKO:** Soy DARKO. La hierba de este barrio la muevo yo.
> **DARKO:** Vende lo tuyo si quieres, pero lejos de mis esquinas.
> **DARKO:** No me hagas repetirlo.

**Clientes.** Saludo según el tipo y luego el pedido: «Busco X g.» o «Busco X g de algo potente, mínimo Y% de THC.»
- *Estudiante:* «Hola. Me ha dicho un amigo que tienes.» / «Aupa, ¿tienes algo? Voy justo de dinero.»
- *Currela:* «Buenas. Salgo de doble turno.» / «Qué tal. Lo de siempre, sin líos.»
- *Turista:* «Hello. ¿Tú vendes... marihuana? Pago bien.» / «Bonjour. Me han dicho que aquí se cultiva bien.»
- *Pijo:* «Busco algo de calidad para una cena en Neguri.» / «Solo quiero lo mejor. El precio me da igual.»
- *Si acepta:* «Trato hecho.» / «Gracias. Nos vemos.» / «Bien. Se lo diré a mis amigos.»
- *Si rechaza:* «¿Tanto? No.» / «A ese precio, paso.» / «Eso es demasiado. Adiós.»
- *Si no tienes lo que pide:* «Eso no me vale. Vuelve cuando tengas lo que busco.» / «¿No llevas nada? Vale.»
- *Si no le vendes nada:* «Vale, otro día.» · *Si cancelas al poner precio:* «Entonces me voy.»

**Iñaki** (muelle):
> **IÑAKI:** Aupa. Me voy tres semanas a la mar. ¿Tienes 10 g para el viaje? Pago bien.
> **IÑAKI:** Te doy X € por 10 g de [variedad]. ¿Hecho?
> *La primera vez:* **IÑAKI:** Toma. Me las dio un marinero de Malaui en Mombasa, en el último viaje. → Consigues 2 semillas de MALAWI GOLD.
> *Después:* **IÑAKI:** Eskerrik asko. Hasta la vuelta. · *Sin 10 g:* «Pues nada. Si consigues 10 g, aquí estaré.» · *Si ya le vendiste ese día:* «Ya me has vendido hoy. Mañana más, que el barco sale temprano.»
> *Desde el capítulo 3, primero:* **IÑAKI:** Aupa. ¿Qué traes? → *10 g para el viaje / Venta al por mayor / Nada*
> *Al por mayor:* **IÑAKI:** [variedad] a X € el gramo. ¿Cuánto cargas? → *100 g · X € / 250 g · X € / … / Nada* → «Cargado. Esta noche sale en el barco.» · *Sin un lote de 100 g:* «Al por mayor, de 100 g para arriba. Pago entre 3,20 y 5,00 € el gramo, según lo bueno que sea. Hasta 1 kg por carga.» · *Si ya cargó ese día:* «Hoy ya he cargado. Mañana sale otro barco.» · *Si eliges lote y luego nada:* «Otro día.»

**Abuela Txaro** (parque, una sola vez):
> **ABUELA TXARO:** Tú vives en el piso de Maite. Tu tía me ayudaba con... ya sabes.
> **ABUELA TXARO:** Desde la quimio apenas duermo y no tengo hambre. Las pastillas no me hacen nada.
> **ABUELA TXARO:** Me vendrían bien 5 gramos, para hacer aceite como me enseñó ella. ¿Me los das?
> **ABUELA TXARO:** Gracias. Toma: las trajo mi Paco de Pakistán en el setenta y seis. Nunca supe qué hacer con ellas. → Consigues 2 semillas de HINDU KUSH.
> **ABUELA TXARO:** Y llévate estos bocadillos, que comes poco. → Consigues 3 × BOCATA.
> *Sin 5 g:* «Cuando tengas 5 gramos, acuérdate de mí.» · *Si no le das nada:* «No pasa nada. Aquí estaré.»
> *Después:* «Ya duermo de un tirón. Gracias, de verdad.» / «Tu tía me ayudaba igual. No se lo contábamos a nadie.»

*Al llegar a 300 € empieza el capítulo 3:*

> Un hombre enorme en chándal te corta el paso.
> **TOÑO:** Tú vives en el piso de Maite, ¿no?
> **TOÑO:** Don Baltasar quiere verte. En el bar El Ancla. Hoy.
> **TOÑO:** No me hagas venir a buscarte.

## Capítulo 3 · La deuda

> **DON BALTASAR:** Siéntate, {N}. Vamos al grano.
> **DON BALTASAR:** Tu tía Maite me debía 30.000 euros. Las deudas no se mueren con la gente.
> **DON BALTASAR:** Me los vas a pagar a plazos. El primero, 3000 €.
> **DON BALTASAR:** Tienes siete días. Si no, Toño te hará una visita. Y Toño cobra intereses.

*En cada visita:* «Me debes X € para el día D. Te quedan N días.» (o «Es HOY.»). Si te llega el dinero: «¿Pagar ahora?». Si no: «Vuelve cuando tengas el dinero.»

*(Si le hablas antes del capítulo 3: «¿Y tú quién eres? No tengo nada que hablar contigo.»)*

*Si vence el plazo:*
> TOÑO te estaba esperando.
> **TOÑO:** Don Baltasar dice que llegas tarde.
> **TOÑO:** Son X € más de intereses. Y esto, para que no se te olvide. *(un 20 % del plazo, redondeado a 100 €: 600 € sobre el primero)*
> La deuda del plazo sube a X €. Nuevo límite: día D.

*Al pagar:*
> **DON BALTASAR:** Puntual. Así me gusta.
> **DON BALTASAR:** Quedan 27.000. Ya te avisaré del siguiente plazo.
> **SMS · KIKO:** Pásate por el growshop. Tengo algo para ti.

## Capítulo 4 · Genética

> **KIKO:** Ya me han contado que has pagado a Baltasar. Bien hecho.
> **KIKO:** Te he montado en el piso mi equipo de polinización: pinceles, bolsas de papel y una lupa.
> Consigues la MESA DE GENÉTICA. · Consigues 3 semillas de AFGHANI.
> **KIKO:** Me las trajo un amigo de Mazar-i-Sharif en los ochenta. Las he ido renovando desde entonces.
> **KIKO:** En la mesa polinizas una variedad con otra: gastas una semilla de cada y obtienes 2 del cruce.
> **KIKO:** Algunos cruces dan variedades conocidas. Otros, híbridos que solo tendrás tú.
> **KIKO:** Apúntalo todo en la GENOTECA. Las mejores genéticas salen de cruzar cruces.

*(Si hablas con Baltasar en este capítulo: «Tranquilo. Ya te avisaré cuando toque el siguiente pago.»)*

*Objetivo: descubrir 8 variedades. Patxi, en la fuente, da una pista de receta cada vez que le hablas («Cuarenta años cultivando en el monte. Te digo una cosa: …»). Van por turnos, de esta lista (`RECIPE_HINTS`, la misma que usa Kiko en sus consejos desde el capítulo 4):*
1. Skunk #1 polinizada con Lemon Haze: así salió la Lemon Skunk.
2. OG Kush con Blueberry da Blueberry Kush. Índica, de color azulado.
3. Afghani con Skunk #1 es la Critical Mass. Produce como ninguna.
4. Hindu Kush con Purple Afghani: la Purple Kush.
5. Mango con Hindu Kush: Mango Kush.
6. Blueberry con una Haze da Blue Dream. Con la Lemon Haze te vale.
7. Acapulco Gold con Afghani: así se hizo la Trainwreck.
8. Las de segunda generación se cruzan entre ellas: Critical Kush, Super Lemon Haze, Purple Haze...
9. La Amnesia Haze de Darko viene de una Super Lemon Haze y una Trainwreck.
10. La Fire OG sale de Critical Kush con Blueberry Kush. Hace falta paciencia.
11. Una Amnesia Haze con una Fire OG... de ahí sale la Ghost Train Haze. Yo nunca lo he conseguido.

*(Antes del capítulo 4 Patxi solo dice: «Cuando tengas una mesa de genética, ven a verme. Algo sé de cruces.»)*

*En cuanto descubres la 8.ª variedad (por cruce, compra, cosecha o regalo) empieza el capítulo 5:*
> **SMS · TOÑO:** Don Baltasar quiere 12.000 € en diez días.
> **SMS · TOÑO:** Otra cosa: un tal SARGENTO MOLINA pregunta por ti en la plaza.

## Capítulo 5 · El sargento

> **SARGENTO MOLINA:** Así que eres tú quien vende en la plaza.
> **SARGENTO MOLINA:** Podría detenerte ahora mismo. O podemos entendernos.
> **SARGENTO MOLINA:** Por 1500 € mis patrullas no pasan por tu calle. Y nada de registros en tu piso.
> **SARGENTO MOLINA:** ¿Aceptas el trato del sargento? → *Pagar 1500 € / No*
> *Si pagas:* «Bien. Mis agentes mirarán hacia otro lado.» *(Molina desaparece de la plaza.)*
> *Si no:* «Tú sabrás. Mis agentes van a estar muy atentos.» *(+10 de calor; sigue en la plaza por si cambias de idea.)*
> *Sin dinero:* «¿Con qué dinero? Vuelve cuando lo tengas.»

*Redada (calor ≥ 90 al empezar un día):*
- *Sin protección:* «REDADA. La policía entra en tu piso.» / «Se llevan todas las plantas y X g. Multa: Y €.» / «Toca empezar de nuevo. Y vender menos una temporada.»
- *Con protección:* **SMS · MOLINA:** «Esta noche había orden de entrada en tu piso. La he parado.» / «Baja el ritmo.»

*Al pagar los 12.000 €:*
> **DON BALTASAR:** Me sorprendes, {N}.
> **DON BALTASAR:** Quedan 15.000. Te propongo algo.
> **DON BALTASAR:** El sábado es la COPA DE RIBERA. Premio: 5000 €.
> **DON BALTASAR:** Mi sobrino Darko compite. No ha perdido nunca.
> **DON BALTASAR:** Gana la Copa y, con el premio y lo que vendas, me pagas lo que queda. Si puedes.

## Capítulo 6 · La Copa de Ribera

> **DARKO:** ¿Vienes a la Copa? Mi AMNESIA HAZE dio un 26,8 % de THC en el laboratorio.
> **DARKO:** Nadie en Ribera ha pasado del 26. No vas a ser tú el primero.

> **JURADO:** Esto es la COPA DE RIBERA, la de la asociación cannábica del barrio.
> **JURADO:** Para competir, trae 20 g de una sola variedad. Se analizan en laboratorio.
> **JURADO:** Marca a batir: DARKO, con AMNESIA HAZE, 26,8 % de THC.
> *Sin 20 g:* «Vuelve cuando tengas 20 g de algo.»
> *[Eliges qué presentas]*
> **JURADO:** Resultado del laboratorio. AMNESIA HAZE de Darko: 26,8 % de THC.
> **JURADO:** [variedad] de {N}: X % de THC.
> *Si pierdes:* «Gana DARKO. La Copa sigue abierta: vuelve con algo más potente.»
> *Si ganas:* «Nueva marca. {N} gana la COPA DE RIBERA.» → Consigues 5000 € y el trofeo de la Copa.
> **DARKO:** Esto no se acaba aquí.
> **DARKO:** Mi tío se va a enterar.

*(Si hablas antes con Baltasar: «Primero, la Copa. Darko te espera en la plaza.»)*

## Capítulo 7 · Libertad

*Objetivo: pagar los últimos 15.000 € en 7 días.*
> **DON BALTASAR:** 15.000 €. Contados.
> **DON BALTASAR:** Deuda saldada. Lo de tu tía queda cerrado.
> **DON BALTASAR:** Una cosa más, {N}: si algún día quieres trabajar para mí, ya sabes dónde estoy.

**Pantalla final:**
> DEUDA SALDADA
> Has saldado los 30.000 € de tu tía Maite en N días.
> Variedades: X · Ventas totales: Y €
> Ahora empieza tu imperio: cuanto más factures, más carga Iñaki en el barco. ¿Completarás la GENOTECA? ¿Conseguirás la GHOST TRAIN HAZE?

## Capítulo 8 · Tu imperio

*Objetivo: «Tu imperio · [rango]. Facturado desde la deuda: Y € de X € para ser [rango siguiente]. Genoteca N/41.» Baltasar: «Ya no me debes nada. Que te vaya bien, {N}.»*

*Al subir de rango (Proveedor del barrio con 25.000 € facturados desde el último pago, Distribuidor de la ría con 100.000 € y Mayorista del norte con 250.000 €):*
> TU IMPERIO · [rango]
> **SMS · IÑAKI:** Se corre la voz: X € vendidos desde que pagaste a Baltasar.
> **SMS · IÑAKI:** Desde hoy te cargo hasta 2 kg al día en el barco. *(5 kg y 10 kg en los rangos siguientes)*

*La primera vez que sale la Ghost Train Haze en la mesa de genética (desde el capítulo 4):*
> Te tiemblan las manos: es GHOST TRAIN HAZE.
> **SMS · KIKO:** ¿Ghost Train Haze? ¿Estable, de semilla propia? Llevo veinte años detrás de ella.
> **SMS · KIKO:** Tu tía estaría orgullosa. Guárdala bien: eso vale más que el piso.

## Combates

- *Ladrón:* «Un [nombre] te corta el paso.» (el nombre, en minúsculas) y luego una de estas: «La mochila. Dámela y no pasa nada.» / «Eh, tú. Sé lo que llevas encima.» / «Quieto. El dinero y lo que lleves.»
  - *Tus golpes:* «Le das un puñetazo.» / «Le das una patada.»; si fallas, «Fallas.», y con una patada de 11 o más, «Le has hecho daño de verdad.» · *Spray:* «Le echas SPRAY DE PIMIENTA a la cara.» / «No puede abrir los ojos.» · *Bocata:* «Te comes un BOCATA. Recuperas vida.»
  - *Ataques del ladrón:* «El [nombre] te golpea / te empuja contra un portal / te da una patada / te tira al suelo.»
  - *HABLAR:* {N}: «Tranquilo. Somos del mismo barrio.» → «Vale... Tú eres el de Maite. Olvídalo.» o «No me cuentes historias.»
  - *HUIR:* «Consigues escapar.» o «Te corta el paso. No puedes escapar.»
  - *Victoria:* «El [nombre] sale corriendo.» / «Al huir se le cae la cartera: +X €.» / «Aguantas más. VIDA máxima: X.»
  - *Derrota:* «Pierdes el conocimiento.» / «Te roba X g y Y €.» / «Te despiertas en casa con la cabeza vendada. Un vecino te encontró en el portal.»
  - *Nombres:* ENCAPUCHADO, ATRACADOR, DESCONOCIDO, TIRONERO, CARTERISTA.
- *Policía:* «[AGENTE] te da el alto.» y luego una de estas: «Control rutinario. ¿Llevas algo encima?» / «Documentación. Y vacía los bolsillos.» / «Aquí huele a marihuana. ¿Es tuya?»
  - *SOBORNAR:* «¿Ofrecerle X € con disimulo?» → [AGENTE] se guarda el sobre. «Aquí no ha pasado nada.» o, con un agente honrado, [AGENTE]: «¿Me intentas sobornar a mí? Esto me lo quedo.» Si no llevas bastante: «No llevas tanto dinero encima.»
  - *HABLAR:* {N}: «Solo estaba dando un paseo, agente.» → [AGENTE]: «Bien. Circula.» o [AGENTE]: «No. Vacía los bolsillos.»
  - *HUIR:* «Sales corriendo entre los coches y lo pierdes.» o «[AGENTE] te alcanza y te reduce en el suelo.»
  - *ENTREGAR:* Le entregas X g. «Buena decisión. Por esta vez, sin multa.»
  - *Requisa (soborno rechazado, HABLAR o HUIR fallidos):* «Te requisan X g y te multan con Y €.»
  - *Agentes:* AGENTE LÓPEZ, AGENTE ETXEBERRIA, AGENTE RUIZ, AGENTE GARAI.
- *Agente de patrulla (al hablarle):* con mercancía y sin la protección de Molina, «¿Y ese olor? Quieto ahí.» y control. Si no, una de estas: «Circule.» / «Todo tranquilo por aquí. Que siga así.» / «De noche hay robos en el parque. Tenga cuidado.»

## Ambiente

- **Kiko** (growshop): «¿Qué necesitas?» → *Comprar / Un consejo / Nada*.
  - *Sin semillas, plantas, cogollos ni 15 €:* «¿Sin semillas y sin dinero? Toma. Ya me lo pagarás.» → Consigues 2 semillas de SKUNK #1.
  - *Tienda:* semillas, «Semillas feminizadas de [variedad]. ¿Cuántas?» → *1 semilla / Sobre de 3 / Sobre de 5 / Sobre de 10 / Bolsa de 50 (desde el capítulo 3) / Nada* · sin dinero, «No te llega el dinero.» · carpa de 100: «Te la monto esta tarde en el piso, al lado del armario de tu tía. Viene con un CFL; si quieres más luz, aquí tienes focos.» · carpa de 150: «Me llevo la de 100 y te monto la de 150 en su sitio. Las plantas ni se enteran.» · foco: «¿Lo cuelgo ya? El que quites va a tu mochila.» (si no aguanta en ninguna carpa: «Ese foco calienta demasiado para tus carpas. Guárdalo hasta que tengas una más grande.»)
  - *Consejos* (opción «Un consejo»):
    - *Capítulo 1:* «Riega cuando el agua baje del 30 %. Una planta seca enferma.» / «El abono se echa una vez por planta. Merece la pena.» / «Las plantas crecen mientras duermes. No hace falta mirarlas cada hora.» / «Un CFL da poco: unos 0,3 gramos por vatio. Un LED, el triple.»
    - *Capítulo 2:* «Los clientes cambian cada día. No los hagas esperar.» / «Pedir caro funciona con turistas, con gente de dinero y con cogollo potente.» / «Si la presión policial (CALOR) sube mucho, deja de vender unos días.» / «Una carpa más grande es la mejor inversión que puedes hacer.» / «Tu tía pedía landraces a un banco de semillas por internet. Mira en su ordenador.» / «Lo que sale de un cruce es una F1: cada planta sale distinta. Crúzala consigo misma hasta fijarla.» / «Las macetas de tela airean las raíces: más cosecha y menos plagas, pero hay que regar más.» / «Cada semilla es una planta distinta. Si compras muchas, alguna sale estrella: más potente y más productiva.» / «Si una planta promete, sácale esquejes en crecimiento. Un esqueje es la misma planta: así se guarda un fenotipo estrella.» / «Una maceta pequeña no da más de unos 8 gramos por litro de tierra, por mucho foco que le pongas.»
    - *Capítulo 3:* «El LED cuesta más, pero rinde más y apenas da calor. El sodio es barato y seca las macetas.» / «Un foco pequeño en una carpa grande no llega a todas las plantas.» / «La luz se paga: cada carpa con plantas suma su factura cada día. Un LED de 720 W gasta unos 280 kWh al día: 45 €.» / «Una plaza vacía es luz que pagas y no aprovechas.» / «Iñaki, el del muelle, compra cantidad. Paga menos por gramo que la calle, pero se lo lleva todo.» / «De noche, en el parque, roban. Lleva el spray de pimienta.»
    - *Desde el capítulo 4:* las pistas de recetas (la lista de Patxi, en el capítulo 4), «Las landraces no las vendo. Pregunta por el barrio: Txaro, Iñaki el del muelle... y mira bien en el parque.» y los consejos del capítulo 2.
  - *Al despedirse:* «Ten cuidado ahí fuera.»
- **Josune:** «¡Kaixo! ¿Qué te pongo?»
  - *Pintxo:* «Pintxo de tortilla, recién hecha. Recuperas vida.»
  - *Kalimotxo:* «Un kalimotxo. Recuperas algo de vida.»
  - *Sin dinero:* «Aquí no se fía.»
  - *Rumores:* «Dicen que alguien escondía cosas en los arbustos del parque.» / «Iñaki, el del muelle, trae semillas de sus viajes.» / «Txaro está con la quimio. Lo está pasando muy mal.» / «Darko es sobrino de Baltasar. Por eso nadie le dice nada.» / «El sargento Molina cobra por mirar hacia otro lado. Lo sabe todo el barrio.»
- **Begoña:** «Bajo una lámpara las plantas beben mucho. Riégalas a diario, majo.» / «Si se te ponen amarillas las hojas de abajo, les falta agua o abono.» / «Tu tía siempre tenía el piso oliendo a limón. Ahora sé por qué.»
- **Unai:** «Si mantienes pulsado B, corres.» / «Mi hermano dice que de noche, en la hierba alta del parque, roban a la gente.» / «Con START abres tu GENOTECA y la mochila.» / «En los arbustos del parque la gente esconde cosas. Mira delante de ellos con A.»
- **Toño (en el bar):** «Don Baltasar está ocupado. Habla con él si traes el dinero.» / «Aquí dentro no se hacen preguntas.»
- **Carteles:**
  - «Calle Ribera, 3. Piso de la tía Maite.»
  - «GROWSHOP KIKO · Semillas, abonos y consejos gratis.»
  - «BAR EL ANCLA · Pintxos y menú del día.»
  - «PARQUE DE LOS SAUCES · Horario: de 7:00 a 23:00.»
  - «PLAZA DE RIBERA VERDE · Fuente inaugurada en 1987.»
  - «MUELLE VIEJO → · Peligro: borde sin barandilla.»
- **Cultivo (1.10):**
  - *Cosecha:* «Cosechas X g de [variedad]. THC: Y%.»
  - *Fenotipo estrella:* «¡Fenotipo estrella! THC ×A y cosecha ×B sobre la media de la [variedad].» / «Va a un lote aparte (★). Si le sacaste esquejes, guárdalos: son esta misma planta.» · *Flojo:* «Fenotipo flojo: THC ×A y cosecha ×B de la media.»
  - *Semillas:* línea sin fijar, «Las plantas de la línea se han polinizado entre ellas: recoges N semillas de [variedad].» · feminizada, a veces, «Una flor hermafrodita ha polinizado unas pocas: recoges N semillas de [variedad].»
  - *Esqueje:* «Cortas una punta de la [variedad] y la pones a enraizar. Plántala antes del día D: es la misma planta.» · propagador lleno, «El propagador está lleno: 12 esquejes. Planta alguno antes.» · al plantarlo, «Plantas el esqueje de [variedad].» · si se seca, aviso al cambiar de día: «Se ha secado un esqueje sin plantar».
  - *Abono e insecticida:* «Echas una dosis de ABONO. Dará más cosecha.» / «No te queda ABONO.» · «Aplicas INSECTICIDA con guantes y mascarilla. Plaga eliminada.»
- **Objetos del piso:**
  - *Cama:* «Tu cama. Todavía huele a la colonia de la tía.»
  - *Ordenador:* «El ordenador de la tía. Tiene su registro de cultivos de veinte años.»
  - *Nevera:* «La nevera: medio limón, leche y un táper de alubias que dejó la tía.»
  - *Monstera:* «Una monstera. La tía Maite le hablaba cada mañana.»
  - *Ventana:* «Por la ventana se ve la ría. Huele a salitre.»
  - *Diploma:* Un diploma enmarcado: «COPA DE RIBERA 1998 · 2º PREMIO: MAITE».
  - *Mesa de genética, antes del capítulo 4:* «Una mesa con un microscopio viejo y frascos. Kiko sabrá qué hacer con esto.»
  - *Hueco sin carpa:* «Aquí cabe una carpa de cultivo. Kiko vende carpas de 100×100.»
- **Objetos de la tienda y el bar:**
  - *Estantería:* «Botes de abono, sustrato de coco y medidores de pH.»
  - *Expositor:* «Sobres de semillas de bancos de todo el mundo, ordenados por tipo.»
  - *Botellas:* «Txakoli, pacharán y orujo casero.»
  - *Gramola:* «La gramola suena: rock vasco de los 80.»
- **Objetos del barrio:**
  - *Cajas del muelle:* «Cajas de pescado vacías del puerto.»
  - *Fuente:* «La fuente de la plaza. Lleva años sin agua potable.»

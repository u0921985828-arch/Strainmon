# Guion · Ribera Verde

`{N}` es el nombre que elige el jugador (EDDIE, ÁLEX, LUR, ANDER o uno escrito a mano). Los textos son los del juego. Para cambiarlos, edita `src/js/11-historia.js` (personajes y capítulos), `09-cultivo.js` (carta, mesa, cama y ordenador), `08-mundo.js` (personajes de ambiente, carteles y demás objetos), `03-datos.js` (saludos de los clientes), `10-calle.js` (resto de frases de los clientes), `13-combate.js` (combates) y `15-arranque.js` (intro).

## Premisa

La tía Maite ha muerto y te deja su piso en Ribera Verde, un barrio de antiguos astilleros a orillas de la ría. En el piso hay un armario de cultivo y, además, una deuda: 5.000 € con Don Baltasar, el dueño del bar El Ancla. Con la ayuda de Kiko, el viejo socio de tu tía, aprendes a cultivar, a cruzar genéticas y a vender en la calle mientras esquivas a la policía, a los chorizos del parque y al sargento Molina. Al final tienes que ganarle la Copa de Ribera a Darko, el sobrino de Baltasar, para pagar el último plazo.

## Personajes

| Personaje | Papel | Dónde está |
|---|---|---|
| **{N}** | Protagonista. Hereda el piso y la deuda | — |
| **Kiko «el Cazasemillas»** | Mentor. Dueño del growshop y antiguo socio de cultivo de Maite | Growshop |
| **Tía Maite** | Solo aparece en su carta y en un póster (2.º premio de la Copa 1998) | Piso |
| **Don Baltasar** | Prestamista del barrio y antagonista | Bar El Ancla |
| **Toño** | Matón de Baltasar | Bar y mensajes |
| **Darko** | Rival. Sobrino de Baltasar y campeón de la Copa | Plaza (desde el cap. 2 hasta que te cruzas con él, y en el cap. 6) |
| **Sargento Molina** | Policía corrupto que vende «protección» | Plaza (desde el cap. 5) |
| **Josune** | Camarera del bar | Bar El Ancla |
| **Abuela Txaro** | Vecina y amiga de Maite. Tiene semillas de la India | Parque |
| **Iñaki** | Marinero y comprador fijo. Trae semillas de sus viajes | Muelle (desde el cap. 2) |
| **Patxi** | Anciano que sabe de cruces | Plaza, junto a la fuente |
| **Begoña** y **Unai** | Vecina y niño, dan consejos | Calle y plaza |
| **Agente de patrulla** | Policía que hace controles | Plaza (desde el cap. 2) |
| **Jurado** | Juez de la Copa | Plaza (cap. 6) |

## Prólogo

*Pantalla de título → NUEVA PARTIDA. Noche sobre la ría y Kiko en primer plano.*

> **???:** ¡Aupa! Bienvenido a RIBERA VERDE, un barrio a orillas de la ría.
> **???:** Me llamo KIKO. En el barrio me llaman el Cazasemillas.
> **KIKO:** Este mundo está lleno de variedades de cannabis. Unas crecen en cualquier balcón...
> **KIKO:** ...y otras solo en valles perdidos del Rif o del Hindu Kush.
> **KIKO:** Yo me dedico a buscarlas, cruzarlas y catalogarlas en una GENOTECA.
> **KIKO:** Pero cuéntame de ti. ¿Cómo te llamas?
> *[Eliges nombre]*
> **KIKO:** ¡{N}! Claro, el sobrino de Maite... o la sobrina, que con esa gorra no se ve bien.
> **KIKO:** Tu tía nos dejó hace unas semanas. Te ha dejado su piso... y algo más.
> **KIKO:** Tu historia en Ribera Verde está a punto de empezar.
> **KIKO:** ¡Te espero en el growshop!

## Capítulo 1 · La herencia

*Despiertas en el piso. Objetivo: leer la carta de la mesa.*

> Hay una carta encima de la mesa. Es de la tía Maite.
> **CARTA:** «{N}: si lees esto, el piso es tuyo. Cuídalo, que la escalera cruje.»
> **CARTA:** «Al fondo del salón está mi armario de cultivo. Ya sabes de qué hablo.»
> **CARTA:** «Pásate por el growshop de Kiko, aquí al lado. Él te enseñará.»
> **CARTA:** «P.D.: Si alguien pregunta por mí en el bar El Ancla... yo no estoy. Lo siento.»

*Objetivo: visitar a Kiko.*

> **KIKO:** ¡{N}! Pasa, pasa. Te pareces a tu tía, ¿eh? Misma cara de liarla.
> **KIKO:** Maite y yo cultivábamos juntos cuando esto era un barrio de astilleros.
> **KIKO:** Para empezar, toma esto.
> ¡{N} obtiene 3 semillas de RÍA SKUNK! · ¡{N} obtiene 2 × FERTILIZANTE!
> **KIKO:** La Ría Skunk es dura como una piedra del muelle. Perfecta para aprender.
> **KIKO:** Planta en las macetas del armario de tu piso y riega cuando baje el agua.
> **KIKO:** El abono da más cogollos. Si ves bichos rojos, INSECTICIDA: aquí lo vendo.
> **KIKO:** Cuando esté lista, cosecha. Siempre caen semillas para repetir.
> **KIKO:** Y si te aburres de esperar, duerme. Las plantas crecen igual.

*Objetivo: plantar y conseguir la primera cosecha. Con ella empieza el capítulo 2.*

> **SMS · KIKO:** ¡Primera cosecha! Bien hecho.
> **SMS · KIKO:** La gente con un $ encima busca material. Véndeles en la calle.
> **SMS · KIKO:** Ojo: cuanto más vendas, más CALOR policial. Y de noche salen los chorizos.

## Capítulo 2 · La calle

*Objetivo: ganar 300 € vendiendo. Desde ahora hay clientes, controles, ladrones e Iñaki en el muelle. La primera vez que entras en la plaza por el norte, Darko te corta el paso:*

> **DARKO:** Así que tú eres quien ha heredado el piso de la vieja Maite.
> **DARKO:** Soy DARKO. Este barrio tiene dueño, y lo tienes delante.
> **DARKO:** Mis plantas tienen más THC que tu vida entera.
> **DARKO:** Vende tus hierbajos mientras puedas, novato.

**Clientes.** Saludo según el tipo y pedido «Busco X g (de algo potente, mínimo Y % de THC)».
- *Estudiante:* «¡Ey! Tengo examen el lunes, necesito relajarme.» / «Aupa, ¿tienes algo? Voy justo de pasta.»
- *Currela:* «Buenas. Salgo de doble turno y me lo merezco.» / «Qué pasa. Lo de siempre, sin líos.»
- *Turista:* «Hello! Eh... ¿tú tienes... marihuana? Pago bien.» / «Bonjour! Me han dicho que aquí hay de la buena.»
- *Pijo:* «Busco algo premium para una fiesta en Neguri.» / «Solo quiero lo mejor. El precio me da igual.»
- *Si acepta:* «¡Trato hecho!» / «Genial. Nos vemos.» / «Perfecto. Se lo diré a mis colegas.»
- *Si rechaza:* «¿Tanto? Ni de broma.» / «Uf, a ese precio paso.» / «Me estás timando. Adiós.»
- *Si no tienes lo que pide:* «Eso no me vale. Vuelve cuando tengas lo que busco.» / «¿No llevas nada? Pues vaya.»

**Iñaki** (muelle):
> **IÑAKI:** Aupa. Me paso tres semanas en alta mar. ¿Tienes 10 g para el viaje? Pago bien.
> **IÑAKI:** Te doy X € por 10 g de [variedad]. ¿Hecho?
> *La primera vez:* **IÑAKI:** ¡Eso es! Toma, un regalo de mi último viaje a Mombasa. → 2 semillas de MALAWI SOL
> *Después:* **IÑAKI:** Eskerrik asko. ¡Buen viento! · *Si ya le vendiste ese día:* «Ya me has vendido hoy. Mañana más, que el barco sale temprano.»

**Abuela Txaro** (parque, una sola vez):
> **ABUELA TXARO:** Ay, el de Maite. ¡Qué mayor estás!
> **ABUELA TXARO:** Oye, para mis magdalenas especiales necesito 5 gramos de lo tuyo. ¿Me los das?
> **ABUELA TXARO:** ¡Ay, qué rico huele! Toma, esto me lo trajo mi Paco de la India. → 2 semillas de HINDÚ VALLE y 3 BOCATAS
> *Después:* «Las magdalenas me salieron de cine. Las de la petanca no paraban de reír.» / «Tu tía y yo íbamos a bailar a la plaza. ¡Qué tiempos!»

*Al llegar a 300 € empieza el capítulo 3:*

> Un tipo enorme en chándal te corta el paso...
> **TOÑO:** Tú eres lo de Maite, ¿no?
> **TOÑO:** Don Baltasar quiere verte. En el bar El Ancla. Hoy.
> **TOÑO:** Y no me hagas venir a buscarte.

## Capítulo 3 · La deuda

> **DON BALTASAR:** Siéntate, {N}. ¿Un kalimotxo? No, mejor no.
> **DON BALTASAR:** Tu tía Maite me debía 5.000 euros. Las deudas no se mueren con la gente.
> **DON BALTASAR:** Me los vas a pagar a plazos. Primero, 1.000 €.
> **DON BALTASAR:** Tienes 7 días. Si no, Toño se pone nervioso. Y cuando Toño se pone nervioso, cobra intereses.

*En cada visita:* «Me debes X € para el día D. Te quedan N días.» (o «Es HOY.»). Si te llega el dinero: «¿Pagar ahora?». Si no: «Vuelve cuando tengas la pasta.»

*Si vence el plazo:*
> Llaman a la puerta... o te paran en la calle. Da igual: es TOÑO.
> **TOÑO:** Don Baltasar dice que llegas tarde.
> **TOÑO:** Te pongo 300 € de intereses. Y esto, de regalo.
> La deuda del plazo sube a X €. Nuevo límite: día D.

*Al pagar:*
> **DON BALTASAR:** Puntual. Me gusta.
> **DON BALTASAR:** Quedan 4.000. Ya te avisaré del siguiente plazo.
> **SMS · KIKO:** Pásate por el growshop. Tengo algo para ti.

## Capítulo 4 · Genética

> **KIKO:** ¡Ahí estás! Me han dicho que has pagado a Baltasar. Tienes madera.
> **KIKO:** Te he montado mi viejo KIT DE POLINIZACIÓN en la mesa de tu piso.
> ¡{N} obtiene la MESA DE GENÉTICA! · ¡{N} obtiene 3 semillas de ATLAS RIF!
> **KIKO:** Las traje de las montañas del Rif hace años. Resistentes como ellas solas.
> **KIKO:** En la mesa cruzas dos variedades: gastas una semilla de cada y salen 2 de la nueva.
> **KIKO:** Algunas mezclas dan variedades únicas. Otras, híbridos tuyos y de nadie más.
> **KIKO:** Ve llenando tu GENOTECA. Las mejores genéticas salen de cruzar cruces.

*Objetivo: descubrir 8 variedades. Patxi, en la fuente, da una pista de receta cada vez que le hablas («Mi abuelo decía: …»):*
1. Ría Skunk con Limón Haze da un cítrico de los buenos.
2. Un Txoko Kush con Niebla Blue sale azul como la ría en invierno.
3. Lo del Rif con el Txoko... eso sí que pega fuerte.
4. Púrpura Monte y Hindú Valle: morado de reyes.
5. Acapulco Oro con Mango: oro tropical, chaval.
6. Niebla Blue y Púrpura Monte: una niebla morada.
7. Limón Haze con Malawi Sol: el sol metido en un cogollo.
8. Si cruzas las de segunda generación entre ellas, salen cosas que no vienen ni en los libros.
9. La LEYENDA DE LA RÍA nace de una tormenta y un dragón. O eso cuentan.

*(Antes del capítulo 4 Patxi solo dice: «Cuando tengas una mesa de genética, ven a verme. Sé un par de cosas de cruces.»)*

*En cuanto descubres la 8.ª variedad (por cruce, compra, cosecha o regalo) empieza el capítulo 5:*
> **SMS · TOÑO:** Don Baltasar quiere 2.000 € en 10 días. No es una pregunta.
> **SMS · TOÑO:** Por cierto: un tal SARGENTO MOLINA pregunta por ti en la plaza.

## Capítulo 5 · El sargento

> **SARGENTO MOLINA:** Vaya, vaya. La nueva estrella del menudeo de Ribera Verde.
> **SARGENTO MOLINA:** Podría detenerte ahora mismo... o podríamos ser amigos.
> **SARGENTO MOLINA:** Por 500 € te garantizo protección: menos controles y ninguna redada.
> **SARGENTO MOLINA:** ¿Aceptas el trato del sargento? → *Pagar 500 € / No*
> *Si pagas:* «Un placer. Mis chicos mirarán hacia otro lado.» *(Molina desaparece de la plaza.)*
> *Si no:* «Tú verás. Mis chicos estarán MUY atentos.» *(+10 de calor; sigue en la plaza por si cambias de idea.)*
> *Sin dinero:* «¿Con qué dinero? Vuelve cuando lo tengas.»

*Redada (calor ≥ 90 al empezar un día):*
- *Sin protección:* «¡REDADA! La policía entra en tu piso...» / «Se llevan todas las plantas y X g. Multa: Y €.» / «Toca empezar de nuevo. Y bajar el CALOR.»
- *Con protección:* **SMS · MOLINA:** «Esta noche iba a haber redada en tu casa. La he parado.» / «De nada. Y baja el ritmo.»

*Al pagar los 2.000 €:*
> **DON BALTASAR:** Me sorprendes, {N}.
> **DON BALTASAR:** Quedan 2.000. Te propongo algo.
> **DON BALTASAR:** Este sábado se celebra la COPA DE RIBERA. El premio: 2.500 €.
> **DON BALTASAR:** Mi sobrino Darko compite. Nunca ha perdido.
> **DON BALTASAR:** Gana la Copa y págame con el premio. Si puedes.

## Capítulo 6 · La Copa de Ribera

> **DARKO:** ¿Vienes a la Copa? Mi TORMENTA FINAL da un 26,8% de THC.
> **DARKO:** Nadie en Ribera ha pasado del 26. Y tú no vas a ser el primero.

> **JURADO:** Bienvenido a la COPA DE RIBERA.
> **JURADO:** Para competir, trae 20 g de una sola variedad.
> **JURADO:** Récord a batir: DARKO, con TORMENTA FINAL, 26,8% de THC.
> *[Eliges qué presentas]*
> **JURADO:** El jurado prueba la TORMENTA FINAL de Darko... 26,8% de THC.
> **JURADO:** Ahora, [variedad] de {N}... ¡X% de THC!
> *Si pierdes:* «Gana DARKO. Vuelve con algo más potente: la Copa sigue abierta.»
> *Si ganas:* «¡¡NUEVO CAMPEÓN!! ¡{N} gana la COPA DE RIBERA!» → ¡{N} obtiene 2.500 € y el trofeo de la Copa!
> **DARKO:** No... no puede ser.
> **DARKO:** ¡Tío Baltasar se va a enterar de esto!

*(Si hablas antes con Baltasar: «Primero, la Copa. Darko te espera en la plaza.»)*

## Capítulo 7 · Libertad

*Objetivo: pagar los últimos 2.000 € en 7 días.*
> **DON BALTASAR:** Dos mil. Contados.
> **DON BALTASAR:** Deuda saldada. Maite estaría orgullosa... o no, quién sabe.
> **DON BALTASAR:** Una última cosa, {N}: Darko necesita un maestro. Piénsalo.

**Pantalla final:**
> FIN
> Has saldado la deuda de la tía Maite en N días.
> Variedades: X · Ventas totales: Y €
> El barrio sigue. ¿Completarás la GENOTECA? ¿Encontrarás la LEYENDA DE LA RÍA?

## Capítulo 8 · Leyenda (juego libre)

*Objetivo: completar la Genoteca (23). Baltasar: «Ya no me debes nada. ¿Un café? Invita la casa... esta vez.»*

*La primera vez que sale la Leyenda de la Ría en la mesa de genética (desde el capítulo 4):*
> Te tiemblan las manos. Es la LEYENDA DE LA RÍA.
> **SMS · KIKO:** ¿¿LA LEYENDA DE LA RÍA?? La busco desde hace veinte años.
> **SMS · KIKO:** Tu tía estaría dando saltos. Yo estoy llorando un poco.

## Combates

- *Ladrón:* «¡[NOMBRE] te corta el paso!» y luego una de estas: «Suelta la mercancía y nadie sale herido.» / «Eh, tú. Esa mochila huele a dinero.» / «Por aquí no se pasa gratis, colega.»
  - *Ataques del ladrón:* te suelta un guantazo / te empuja contra un portal / te da una patada / te arrea con una riñonera.
  - *HABLAR:* «Tranqui, que somos del mismo barrio...» → «Vale, vale... Tú eres el de Maite. Me piro.» o «¡No me vengas con rollos!»
  - *Victoria:* «¡[NOMBRE] sale corriendo!» / «Se le cae la cartera: +X €.» / «Te sientes más curtido. VIDA máxima: X.»
  - *Derrota:* «¡{N} se desmaya!» / «[NOMBRE] te roba X g y Y €...» / «Te despiertas en casa con un chichón enorme. No recuerdas cómo llegaste.»
  - *Nombres:* EL RATA, YONI, KINKI MORENO, EL PELAS, LA SOMBRA.
- *Policía:* «¡[AGENTE] te da el alto!» y luego una de estas: «Control rutinario. ¿Llevas algo encima?» / «Documentación. Y vacía los bolsillos.» / «Huele raro por aquí. Muy raro.»
  - *SOBORNAR:* «¿Ofrecerle X € con disimulo?» → «[AGENTE] se guarda el sobre. "Aquí no ha pasado nada."» o, con un agente honrado, «¿Me intentas sobornar a mí? Esto me lo quedo.»
  - *HABLAR:* «Solo estaba dando un paseo, agente...» → «Bueno... circula. Y que no te vuelva a ver.» o «Eso no te lo crees ni tú. A ver esos bolsillos.»
  - *HUIR:* «¡Sales corriendo entre los coches y lo pierdes!» o «¡[AGENTE] te placa contra el suelo!»
  - *ENTREGAR:* «Le entregas X g. "Buena decisión. Por esta vez, sin multa."»
  - *Agentes:* LÓPEZ, ETXEBERRIA, RUIZ, GARAI.
- *Agente de patrulla (al hablarle):* con mercancía y sin la protección de Molina, «¿Y ese olor? Quieto ahí.» y control. Si no, una de estas: «Circule, circule.» / «Todo tranquilo por aquí. Que siga así.» / «Ojo con los chorizos de noche, que hay mucho listo.»

## Ambiente

- **Kiko, consejos** (opción «Un consejo»):
  - *Capítulo 1:* riego por debajo del 30 %, abono una vez por planta, dormir para pasar el tiempo.
  - *Capítulo 2:* los clientes cambian cada día, pedir caro funciona con turistas, pijos y cogollos potentes, parar de vender si sube el calor, una carpa más grande, las macetas de tela.
  - *Capítulo 3:* LED frente a sodio, un foco pequeño en una carpa grande rinde menos, la factura de la luz, llevar spray de noche en el parque.
  - *Desde el capítulo 4:* las pistas de recetas y dónde buscar landraces, más los consejos del capítulo 2.
  - *Al despedirse:* «¡Buenos humos!»
- **Josune:** «¡Kaixo! ¿Qué te pongo?»
  - *Pintxo:* «Tortilla poco hecha, como debe ser. Recuperas vida.»
  - *Kalimotxo:* «Kalimotxo fresquito. Recuperas algo de vida.»
  - *Sin dinero:* «Aquí no se fía, cariño.»
  - *Rumores:* arbustos del parque · Iñaki trae cosas raras · Txaro tiene semillas de la India · Darko es sobrino de Baltasar · Molina cobra por mirar hacia otro lado.
- **Begoña:** riega a diario · sin agua se ponen amarillas «como mi geranio» · el piso de tu tía olía a limón.
- **Unai:** mantén B para correr · chorizos en la hierba alta de noche · START abre la Genoteca · los arbustos del parque esconden cosas.
- **Toño (en el bar):** «Don Baltasar está ocupado. Habla con él si traes la pasta.» / «¿Qué miras? ¿Tengo monos en la cara?»
- **Carteles:**
  - «Calle Ribera, 3. Piso de la tía Maite.»
  - «GROWSHOP KIKO · Semillas, abonos y consejos gratis.»
  - «BAR EL ANCLA · Pintxos, kalimotxo y negocios turbios.»
  - «PARQUE DE LOS SAUCES · Prohibido pisar el césped. Nadie hace caso.»
  - «PLAZA DE RIBERA VERDE · Fuente inaugurada en 1987.»
  - «MUELLE VIEJO → · Cuidado con las gaviotas.»
- **Objetos del piso:**
  - *Cama:* «Todavía huele a la colonia de la tía.»
  - *Ordenador:* «Tiene una pegatina de un cogollo.»
  - *Nevera:* medio limón, un kalimotxo y un táper de alubias.
  - *Monstera:* «La tía Maite le hablaba cada mañana.»
  - *Ventana:* «Por la ventana se ve la ría. Huele a salitre.»
  - *Póster:* «COPA DE RIBERA 1998 · 2º PREMIO: MAITE».
- **Objetos de la tienda y el bar:**
  - *Estantería:* sustrato de coco y «una pipa de agua con forma de faro».
  - *Expositor:* «Sobres de semillas de medio mundo.»
  - *Botellas:* txakoli, pacharán y «una botella sin etiqueta que da miedo».
  - *Gramola:* «un éxito del rock radikal de los 80».
- **Objetos del barrio:**
  - *Cajas del muelle:* «Cajas de pescado. Mejor no abrirlas.»
  - *Fuente:* «El agua de la fuente está sorprendentemente limpia.»

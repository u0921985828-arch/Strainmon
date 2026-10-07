# Cambios

## En desarrollo (1.10; sale con el arte de `docs/PLAN-PRODUCCION.md`)

Hasta que lleguen las láminas de P3–P4, lo nuevo se dibuja con el arte procedural, así que no hay versión ni Artifact nuevos.

- **Corte de prueba en Godot 4 (`godot/`, aparte del juego):** la vista C de la carpa 100 × 100 y un ciclo de cultivo entero (plantar, regar, abonar, tratar, arrancar, dormir y cosechar) portados a Godot 4.3, con la misma pantalla y los mismos mandos, para comparar con el HTML antes de portar el resto. Sale como APK aparte (`npm run godot:apk` → `dist/ribera-verde-godot.apk`, paquete `com.riberaverde.godot`), que se instala al lado del de siempre.
  - Los datos, el arte y lo que tiene que dar igual salen del HTML (`npm run godot`). Godot da los mismos números en datos, geometría de la vista C, 3 ciclos de cultivo hora a hora, la cama (cambio de día, factura de la luz y dinero) y la cosecha (lotes, fenotipo estrella y semillas), con el mismo azar (0 diferencias) y, comparada píxel a píxel, la misma imagen sin la capa de luz salvo en lo translúcido (±2), y a ±4 con la luz (medido con Mesa en el ordenador; en el móvil, a ojo).
  - Mandos con varios dedos a la vez, como en el HTML (con un dedo en la cruceta, A responde), menús en bucle, tocar el diálogo es A y Atrás guarda y cierra.
  - Solo en Godot: encima de cada planta, una barra de agua (roja y parpadeando por debajo del 30 %: toca regar) y otra de cosecha (dorada y parpadeando cuando está lista), con una «!» roja si tiene plaga. Al despertar, un aviso dice qué plantas han cogido plaga (y cuáles la siguen teniendo). La plaga se ve en la planta: manchas amarillas y pardas y punteado en las hojas, telilla y podrido en los cogollos, sacados de los píxeles de cada sprite y más fuertes cuanta menos salud le queda; tratada, vuelve a ser la de siempre.
  - Capas revisadas en todas las carpas, focos, plazas, fases y portes (`tests/capas.gd`): de atrás adelante, nada se sale de la pantalla ni de su pared, nada toca la campana y las vecinas no se pisan ni balanceándose. El aviso de arriba ya no tapa la ficha.
  - Sin vista B, mapa, historia, tienda, esquejes, cambio de maceta o foco, extras, sonido ni texto a máquina.
- **Nuevo: cifras reales** (`docs/ECONOMIA.md`, generado con `npm run docs`). Lo único comprimido es el tiempo: un día de juego son unas 4 semanas de cultivo.
  - **Cosecha por gramos por vatio:** cada foco da `W × g/W` por cosecha (CFL 0,25, sodio 0,45–0,55, LED 0,65–0,85; abonando, ×1,25), repartidos entre las plazas de la carpa (una plaza vacía es luz perdida), con el rinde de la variedad y un tope por maceta de unos 8 g por litro (56 g en 7 L, 210 g en 25 L). La carpa enseña sus W/m² y la ficha de cada variedad, sus g/m².
  - **Luz:** 392 h de foco y 672 h de extras por día de juego a 0,16 €/kWh: CFL 8 €, sodio 400 W 25 €, LED 720 W 45 €. El ventilador (25 W) y el extractor (75 W) también gastan.
  - **Precios de growshop:** focos de 85 a 950 €, carpas de 90 a 150 €, macetas de 2 a 4 €, abono de 1 L (4 dosis) 14 €, insecticida de neem (3 tratamientos) 12 €.
  - **Calle:** 6,4–10 €/g según el THC. **Multas:** 601 € en la calle (la mínima de la Ley de Seguridad Ciudadana) y hasta 3.000 € en una redada.
- **Nuevo: semillas como en un growshop.** Feminizadas, a precio por semilla (5–10 €), en sobres de 1, 3, 5 y 10 con descuento y, desde el capítulo 3, bolsas de 50 a granel. El banco del PC vende sobres de 10 (20–45 €). Al cosechar, una feminizada casi nunca da semilla (12 % hermafroditas, 1–3); las regulares (las landraces, como el Afghani que te da Kiko, y tus líneas fijadas) dan 1–3, y una línea sin fijar se poliniza entre ella y da 2–5. Así nunca te quedas sin Afghani ni Hindu Kush para las recetas.
- **Nuevo: fenotipos.** Cada semilla es una planta distinta (THC y gramos, cada uno por su lado). La ficha de cada variedad dice su tipo (landrace, línea estable, cruce F1 con sus padres, polihíbrido o F1–F3 propia) y cada cuántas plantas sale un **fenotipo estrella** según su pureza: 1 de cada ~16.000 en una línea estable, ~2.000 en un F1 de tienda, ~100 en una landrace, ~60 en un polihíbrido y ~40 en una F2. La estrella va a un lote aparte (★), que se vende y se presenta a la Copa por separado. Sustituye al ×0,8–1,1 de las F1 de la 1.9.
- **Nuevo: esquejes.** A una planta en crecimiento se le saca un esqueje: es la misma planta, con su fenotipo. Se planta desde el menú de semillas (empieza de plántula) y se seca si no se planta antes de que acabe el día siguiente. Así se guarda una estrella.
- **Nuevo: venta al por mayor.** Desde el capítulo 3, Iñaki carga lotes de 100 g para arriba a 3,2–5 €/g, una vez al día y hasta 1 kg.
- **Cambiado: la deuda, a escala.** 30.000 € en plazos de 3.000, 12.000 y 15.000 €; intereses del 20 % del plazo, Copa de 5.000 € y protección de Molina por 1.500 €. Con las cifras nuevas, los plazos se pagan en unas 4, 8 y 9 cosechas, lo mismo que antes (simulación en `docs/ECONOMIA.md`).
- **Nuevo: tu imperio.** Saldada la deuda («DEUDA SALDADA» en vez de «FIN»), el capítulo 8 sigue con rangos por lo facturado desde el último pago: Cultivador, Proveedor del barrio (25.000 €), Distribuidor de la ría (100.000 €) y Mayorista del norte (250.000 €). Cada uno sube lo que Iñaki carga al día (1, 2, 5 y 10 kg) y llega con un SMS.
- **P3 del plan de producción: vista C (corte de prueba aprobado).** La carpa se ve por dentro a toda la altura de la pantalla, como la imagen A del tablero de estilos, y su arte sale de esa imagen: pared, luz, campana del foco de sodio, maceta de 7 L e índica en floración.
  - La pared solo lleva la tela, con sus brillos y sombras, sin la forma del cono de luz. Macetas y plantas tampoco llevan la luz pintada.
  - La luz del foco es una capa aparte que se pinta delante de todo (pared, macetas y plantas) y se apaga con el foco.
  - Cada carpa va a su escala, con la boca del foco a su altura real. Las copas no pasan de la distancia segura, tampoco en el armario 80 con dos filas.
  - A los lados de la carpa, el cuarto queda a oscuras.
  - Mientras falte arte para algo de la carpa (otros focos, macetas, extras, fases o portes), se ve la vista B.
  - Se descarta la lámina 1 (fondo del cuarto para la vista B), porque no se parecía a la imagen A.
- **P3, lámina A (el CFL, pendiente; la híbrida, sustituida por la planta A, abajo): el CFL y la híbrida en el armario 60.** La vista C ya sale con el foco CFL y con la Skunk #1 (híbrida) en sus 5 fases: germinando, plántula, vegetativo, floración y lista.
  - La luz del CFL es la misma capa de luz con su color frío y más suave. Apagado, el tubo se ve gris.
  - Cada fase tiene su sprite a su tamaño (entre ×0,75 y ×1,33 del real, como en la vista B), y más alta quiere decir más nudos: más pisos de ramas y más cogollos, no los mismos estirados (lista de 99 px, 11 nudos; de 40, 3). Floración y lista comparten sprite. Con el CFL la planta sube hasta 10 cm del foco; con el sodio de 250 W, hasta 30.
  - La híbrida está dibujada a cada alto (floración y lista, de 40 a 99 px; vegetativo, de 18 a 52): más baja, en floración o por la distancia al foco, es otro dibujo con menos nudos, no el grande con trozos de menos.
  - La índica, más baja que su sprite, pierde pisos de ramas enteros del medio (el más bajo que quepa; el de arriba y el de abajo se quedan, para que no asome el corte de un piso como un estante) y filas de tallo pelado, sin aplastar los píxeles; la de 36 (carpas de 100 y 150), por ahora solo filas de tallo pelado.
  - La híbrida está dibujada a mano, sin PixelLab: hojas de abanico grandes abajo, ramas con colas a los dos lados, cogollos pegados al tallo, la cola arriba y pistilos naranjas, en verde frío (paleta A). La de antes, montada con trozos de la índica, no se leía como cannabis.
  - Todas las híbridas comparten ese arte (cada una con el color de sus cogollos). Las índicas siguen en la vista B hasta la floración y las sativas, siempre. En las carpas de 200 cm, el CFL y la híbrida en floración y lista de la 100 y la 150 también, hasta que llegue su arte.
- **P3, planta A (aprobada; el vegetativo y los cogollos sin pera, pendientes de visto bueno): la forma sale de la genética.** Una sola planta, dibujada a mano, para índicas, híbridas y sativas en las 5 fases: baja, despuntada y en mainline, con una corona de 6 ramas y sus colas en zigzag (3 detrás, más altas, y 3 delante), con aire entre las puntas; cada rama pelada abajo (lollipop), yemas en pares cruzados con sus hojas y cogollos de cálices con pistilos y tricomas. En vegetativo, la misma corona con hojas de abanico en cada nudo y un brote en cada punta.
  - **Cogollos sin forma de pera:** cada cogollito de la cola es ancho arriba y estrecho abajo, con las puntas de los cálices hacia arriba y afuera, y las yemas de los nudos son dos cálices con una hoja de azúcar. Con una sola punta arriba y la base redonda, parecían peras.
  - **% índica de cada variedad** (dato real de las 41) y su **tono de hoja**. El porte sale de ahí: índica desde el 70 %, sativa por debajo del 30 % e híbrida entre medias. La índica tiene foliolos anchos, colas gordas y hoja oscura; la sativa sube más, con internudos más largos, colas largas y finas, 9 foliolos estrechos y hoja clara. Con esto, la Mango Kush pasa a híbrida y la Fire OG, a índica.
  - **Tamaños de lista:** índica 60 cm de ancho y 65 de alto, sativa 55 × 90 e híbrida 58 × 70 (despuntadas).
  - **Cruces nuevos** (los que no son de receta): el F1 sale en un X % de la madre (al azar, del 30 al 70 %) y el resto del padre: su % índica, su tono de hoja y el color de sus cogollos se mezclan en esa proporción. La Genoteca lo dice en la ficha: «Índica 62 % · sativa 38 % · 60 % madre · 40 % padre».
  - **Cada planta, la suya hasta la F4:** el fenotipo tira también el % índica de la planta alrededor del de su variedad (σ 0 en una línea estable, 3 en un F1 de tienda, 8 en tu F1, 15 en la F2, 10 en la F3 y en una landrace, 12 en un polihíbrido). Su porte y su tono de hoja salen de ese %: dos plantas de la misma F2 pueden salir una índica y otra sativa.
  - En la carpa, cada planta usa el dibujo más ancho (38 o 32 px) que deja aire con las de su fila y con las paredes, y el fotograma de su alto (hay uno cada 2 px), así que ya no pierde pisos de ramas.
  - Sustituye a la híbrida de la lámina A y a la índica de la imagen A (retiradas en el manifiesto). El atlas pesa 220 KB más.
- **P2 del plan de producción: vista de carpa B.** La carpa se abre recortada en 3/4, como en la 1.6–1.7, pero a escala real (48 px/m de ancho y alto, 24 px/m de fondo), con un foco centrado y la luz recortada a la carpa. Plantas en 3 portes (índica, sativa e híbrida). Todo procedural hasta P3–P4: `npm run sprites:huellas` saca las huellas de las láminas. `npm run plano` mide la vista B (29 de 35 piezas entre ×0,94 y ×1,06; germinando y plántula, ×2) y saca `docs/plano/vista-b.png`.
- **P1 del plan de producción** (decisiones D1–D6 aprobadas): datos y reglas del equipo nuevo.
  - **Armario 80×80** (90 €, capítulo 3): sustituye al de 60 en el sitio A. 3 plazas (la de atrás centrada), focos de hasta 400 W y macetas de hasta 18 L.
  - **Carpa 120×120** (150 €, capítulo 5): tercera carpa, en el sitio C nuevo, junto a la cama, cuando ya hay carpa en B. 6 plazas, hasta 720 W y 25 L. El máximo pasa de 8 plantas a 15.
  - **LED 100 W** (110 €, capítulo 1): el primer paso por encima del CFL.
  - **Extras**, uno de cada por carpa: ventilador de pinza (20 €, cap. 1, plagas ×0,7), extractor con filtro de carbón (110 €, cap. 2) y riego por goteo (55 €, cap. 3, el agua baja a la mitad). Al comprarlos, «¿Te lo pongo ya?»; si no, desde la vista de carpa (▲ hasta el foco y A). La ficha del foco enseña los que tiene la carpa.
  - **Regla nueva, el olor:** cada carpa sin filtro con alguna planta en floración suma +2 de calor al día (sale también en el aviso de la cama).
  - **Piso:** la ventana y el diploma de la pared pasan a (9,1) y (7,1), donde no los tapa ninguna carpa. El hueco de C se marca en el suelo cuando ya tienes carpa en B.
  - **Tienda:** un extra solo se ofrece si alguna carpa lo necesita y no lo llevas ya en la mochila.
  - **Cambiar de carpa:** cada planta y cada maceta se quedan en su carpa y su plaza (antes las plazas nuevas iban al final de la lista, lo que con el armario 80 habría movido las plantas de la carpa del fondo).
- **Nuevo: distancia segura en la vista de carpa.** Cada maceta va en el centro de su parte de la carpa, lo más separada posible (30 cm entre centros en el armario 60, 40 en el 80 y la carpa 120, 50 en las de 100 y 150). Una planta en floración ya no invade a sus vecinas ni las paredes: su copa se dibuja como mucho del hueco que le toca, menos 4 cm de aire, y su cima se queda a la distancia de seguridad del foco (CFL 10 cm, LED 25–40, sodio 30–50), como si la podaras y la doblaras. Con una plaza de atrás elegida, la fila de delante se ve en transparencia. Tabla en `docs/PLANO.md` §6.
- **Corregido:** el menú se redibuja al girar o cambiar el tamaño de la pantalla. El abono se llama igual en la tienda, la mochila, el suelo y los diálogos (antes, «fertilizante» en unos sitios). Al empezar los capítulos 5 y 7, la partida se guardaba antes de poner el plazo nuevo: si cerrabas sin dormir, al volver debías 0 € y podías saltarte 12.000 o 15.000 €; ahora el plazo va antes y una partida guardada así lo recupera al cargar. Al saldar la deuda sale el rótulo «CAPÍTULO 8 · Tu imperio», y el objetivo de cada capítulo espera a que acabe su rótulo en vez de taparlo. Las cifras de 4 cifras llevan punto de miles, como las demás (3.000 €, no 3000 €).
- **Partidas viejas:** una partida de la 1.9 carga igual (mismas plazas, plantas y macetas; extras a 0). La deuda pasa a la escala nueva del capítulo en que estás (los intereses ya cobrados se pierden) y el plazo abierto vuelve a contar desde que cargas, con sus 7 o 10 días; una partida acabada empieza el imperio desde cero.
- **Tests:** `npm test` 52/52 (de 50): semillas regulares y feminizadas al cosechar; una partida de la 1.9 con un plazo abierto y una guardada sin plazo; el plazo de los capítulos 5 y 7 ya está en lo guardado; armario 80, extras y carpa 120; Iñaki al por mayor; el imperio a 25.000 €; fenotipos (200.000 plantas por tipo: la frecuencia de estrellas cuadra con la de la ficha y va de la línea estable a la F2); esquejes (el clon guarda el fenotipo y su cosecha va al lote ★; sin plantar se seca); cifras reales (CFL ≈ 0,3 g/W, LED 720 W ≈ 1–1,35 g/W y 45 € de luz, tope de la maceta). `npm run test:arte` 24/24, con la vista B y su distancia segura (las 5 carpas con cada foco y maceta) y la vista C (las 5 carpas con sodio y la de 60 con el CFL y la híbrida en sus 5 fases).

## 1.9.0 · 6 de octubre de 2026

- **Nuevo: las genéticas de Strainmon.** La Genoteca pasa de 23 a 41 variedades con la información de `../src/species.js`, todas con nombre real y su historia (se lee en la Genoteca y en el banco).
  - 12 landraces: Michoacán, Punto Rojo, Thai, Luang Prabang, Chitral Kush, Nepalese, Congolese, Lamb's Bread, Kif, Beldia, Oaxaca y Panama Red.
  - 6 híbridos clásicos que salen de cruzarlas: Haze (Punto Rojo × Thai o Michoacán × Thai), Northern Lights (Afghani × Thai), Afghan Kush (Afghani × Hindu Kush), Shiva Skunk (Northern Lights × Skunk #1), Silver Haze (Haze × Northern Lights) y Super Silver Haze (Silver Haze × Skunk #1). 20 recetas en total.
  - Fuera las dos reliquias inventadas de Strainmon y las variedades con nombre de persona.
- **Nuevo: estabilizar.** Lo que sale de un cruce nuevo es una F1: sus cosechas dan gramos desiguales (×0,8–1,1; el THC no cambia, para no poner en riesgo la Copa). En la mesa de genética, «estabilizar» cruza la variedad consigo misma: gasta 2 semillas y guarda 1 de la generación siguiente, así que entre generación y generación hay que cultivarla. En la F4 la línea queda fija; también se puede estabilizar sin tener semillas de otra variedad. La Genoteca dice en qué generación va cada una.
- **Nuevo: banco de semillas.** Desde el capítulo 2, el ordenador de la tía vende sobres de 3 semillas de landraces (35–90 €; 5 en el capítulo 2, 10 en el 3 y las 12 en el 4) que llegan al día siguiente.
- **Corregido:** en los menús a toda altura, una descripción de 4 líneas tapaba la lista; ahora se ven las filas que caben.
- **Banco:** si pides dos veces la misma variedad llegan 6 semillas en un solo aviso, y cada landrace nueva sale en la Genoteca con su aviso.
- **Partidas viejas:** una partida de la 1.8 carga igual; las variedades que ya tenías cuentan como estables.
- **Tests:**
  - `npm test` 42/42: estabilizar Critical Mass (F1 → F2 → F3 → estable), el banco (Punto Rojo y Thai, llegan al día siguiente) y el cruce Punto Rojo × Thai → Haze con cosechas desiguales.
  - `npm run test:arte` 22/22: plantas de la vista para las 41 variedades.
- **Docs:** `docs/GENETICA.md` con la historia de cada variedad y la regla de estabilizar; `docs/GDD.md` al día.

## 1.8.0 · 6 de octubre de 2026

- **Cambiado: una sola escala (opción A de `docs/PLANO.md`).**
  - El piso pasa a 12 × 8 casillas a 1 casilla = 1 m (72 m²; antes 20 × 12, 240 m²). Dormitorio a la izquierda, escritorio y mesa de genética al fondo, carpas al fondo a la derecha y la salida en (5,7).
  - Las carpas son muebles sólidos: el armario 60 y la carpa 100 ocupan 1 casilla, la carpa 150 ocupa 2 (sprites nuevos `carpa-<t>-mapa`, a ×1 de su tamaño real).
  - Fuera la bandeja de cultivo, las mesitas y las plazas como casillas del mapa.
- **Nuevo: vista de carpa.** Con A delante de una carpa se abre de frente, a 64 px por metro, sobre el fondo de un cuarto de cultivo.
  - La cruceta elige la plaza (las filas de atrás, al tresbolillo) o el foco; A riega, abona, cosecha o cambia maceta y foco como antes; B sale. El tiempo no corre mientras miras.
  - Ficha a la izquierda con la variedad, la fase, el agua, la salud y la plaga; con el foco, su potencia y la luz que gasta al día.
  - Luz de cada foco sobre las plantas, plantas recortadas al interior de la carpa y la luz que se escapa bajo la puerta en el piso.
- **Nuevo: plantas por variedad.** Las plantas de la vista son el arte de cepas del repositorio (`../assets/plants`, 18 cepas × 5 fases) sin su tiesto y a escala: cada variedad con la cepa más parecida en porte y color de cogollo (los híbridos propios, por hash). Secas, amarillean; muertas, se quedan pardas.
- **Arte:** 4 generaciones de PixelLab (carpas del piso, carpas de la vista, macetas y el cuarto), frente a las 120–180 previstas. Retirados los sprites de carpas, mesa, macetas y plantas de la 1.6–1.7.
- **Partidas viejas:** una partida de la 1.7 carga con sus carpas y sus plantas intactas; si el jugador estaba fuera del piso nuevo, aparece en una casilla libre.
- **Plano** (`docs/PLANO.md`, `npm run plano`) rehecho: decisión A aplicada, carpas a ×1,0 en el piso y la vista medida a 64 px/m (carpas, macetas y focos ×0,76–×1,09; plantas ×0,85–×2,3, estilizadas).
- **Tests:**
  - `npm test` 39/39: paso nuevo de la vista de carpa (A abre, ▶ plaza 2, A riega, B sale).
  - `npm run test:arte` 22/22: carpas como muebles en el piso de 12 × 8, plantas de la vista (23 variedades × 5 fases, seca y muerta sin verdes) y la vista con el arte del atlas.
- **Capturas:** nueva `03b-vista-carpa.png`.

## 1.7.0 · 6 de octubre de 2026

- **Nuevo: plano del juego** (`npm run plano`, `docs/PLANO.md`).
  - Cada mapa sale entero con rejilla, coordenadas y rótulos de edificios, puertas, salidas, NPC, objetos, carpas y plazas (`docs/plano/*.png`).
  - Una hoja de escala pone todos los sprites junto al jugador y los mide contra su tamaño real (`docs/plano/escala.png`, `medidas.json`).
  - Conclusión: con 1 casilla = 1 m, personajes y muebles cuadran (×0,8–×1,3), la zona de cultivo va a ×2,5–×5 y el exterior a ×0,25–×0,5.
  - El documento propone tres maneras de dejar una sola escala (A: vista de carpa a escala de detalle; B: interiores a ×2; C: ajuste dentro del estilo actual), con su coste en PixelLab, **para decidir**.
- **Cambiado: pantalla completa, solo en horizontal.**
  - Fuera el chasis de la consola: la pantalla ocupa el móvil entero, con un reborde fino.
  - Los mandos flotan encima, fijos: cruceta abajo a la izquierda, A/B abajo a la derecha, SONIDO y START arriba a la derecha.
  - El ancho del juego se adapta al móvil (de 240 a 400 px, siempre 160 de alto y píxeles cuadrados): en un móvil de 844 × 390 se ven 358 px de mundo.
  - Diálogos y menús van en un escenario de 240 centrado que encoge lo justo para caber entre la cruceta y A/B (letra de 13 px como mínimo) y empieza debajo de SONIDO/START. Con un menú a toda altura abierto, el HUD se aparta.
  - Título y combate siguen compuestos a 240 y su fondo se alarga a los lados. En el combate, sin repetir trozos de las tarimas.
  - En vertical sale «Gira el móvil».
  - Al primer toque se pide pantalla completa y se bloquea el giro. El APK va en `sensorLandscape`.
- **Cambiado: variedades con nombres reales y guion serio.**
  - Las 23 variedades son reales, con su linaje: Skunk #1, Lemon Haze, OG Kush, Blueberry, Mango y Purple Afghani en la tienda; Afghani, Hindu Kush, Acapulco Gold y Malawi Gold como landraces; y cruces como Lemon Skunk, Critical Mass, Blue Dream, Super Lemon Haze, Amnesia Haze y Fire OG, hasta la legendaria Ghost Train Haze (29 %).
  - Cogollos en tonos verdes realistas.
  - Los híbridos propios se nombran con las variedades de los padres (Skunk #1 × Hindu Kush → «Skunk Kush»).
  - Todo el guion, reescrito en serio:
    - intro de Kiko sin presentador;
    - carta de Maite con la deuda;
    - uso medicinal de Txaro durante la quimio;
    - Copa de la asociación cannábica con análisis de laboratorio;
    - Darko, Molina y Baltasar sin chistes;
    - ladrones sin apodos (encapuchado, atracador, carterista…);
    - combate sin coletillas («Fallas.», «¿Qué haces?», «Consigues…»).
  - Subtítulo: «genética de barrio».
- **Cambiado: fuente más legible.** Atkinson Hyperlegible (400 y 700) en diálogos, menús y HUD; Press Start 2P solo en rótulos. Sale Pixelify Sans.
- **Cambiado: bandeja de cultivo.** Las «mesitas» de madera por plaza (otra escala y otra calidad que la carpa) se cambian por una bandeja continua por carpa: cubeta de plástico sobre bastidor metálico con desagüe, con la paleta de la carpa.
- **Tests:**
  - `npm test` 38/38, con los nombres nuevos.
  - `npm run test:arte` 22/22: pantalla completa en 7 tamaños horizontales (pantalla ≥ 90 % del móvil, píxeles cuadrados, mandos dentro y sin tapar diálogos ni menús en ningún tamaño) y «Gira el móvil» en 2 verticales; bandeja continua.
- **Capturas** de 720 × 480 (×3 exacto) y la del móvil en horizontal (844 × 390).

## 1.6.1 · 6 de octubre de 2026

- **Corregido: el marco en el móvil.** La pantalla del juego quedaba pequeña y los mandos se comían el resto; en horizontal la pantalla se quedaba en 90 × 60 px. Ahora la consola es la app entera, sin scroll, y `ajustarPantalla()` reparte el hueco real (`visualViewport`, con barras del sistema y muescas) con límites fijos para cada parte:
  - **vertical:** pantalla arriba a todo el ancho (332 × 221 en un móvil de 360 × 740; antes 288 × 192) y cruceta, A/B, SONIDO y START debajo, con al menos un tercio del alto para ellos;
  - **horizontal:** cruceta | pantalla a toda la altura | A/B (449 × 299 en 740 × 360; antes 90 × 60), con SONIDO y START debajo de cada lado;
  - los mandos se escalan con el hueco (cruceta de 96 a 210 px) y la pantalla se ajusta a un múltiplo entero de 240 píxeles físicos cuando está a menos de un 8 % (píxeles nítidos).
- **Quitado:** la línea de ayuda del teclado bajo la consola (es una app de móvil; el teclado sigue funcionando en el PC). Sin zoom con dos dedos ni doble toque.
- **Corregido: sprites antiguos.** En la intro, Kiko salía con el muñeco procedural ampliado; ahora es el de PixelLab (×2, con su animación). Los menús usan por fin los iconos y los cogollos que ya estaban en el atlas: mochila, tienda, cultivo, combate, venta y Genoteca (el cogollo de cada variedad con su forma y su color).
- **Corregido (herramientas):** `npm run capturas` podía quedarse colgado tras el combate (el cambio de capítulo encolado acababa con `lock` en −1).
- **Tests:** `npm run test:arte` 22/22 (intro y menús con el arte del atlas; marco en 7 tamaños, vertical y horizontal).

## 1.6.0 · 6 de octubre de 2026

- **Nuevo: carpas de cultivo de verdad en el piso.** El armario de la tía (60×60, 2 plantas) es el de serie; en el growshop se compra una **carpa de 100×100** (450 €, capítulo 2, 4 plantas) y después se cambia por una **de 150×100** (900 €, capítulo 4, 6 plantas: se quedan plantas, foco y macetas). El piso pasa a 20 × 12 casillas, con las dos carpas al fondo.
  - **Desde fuera** la carpa está cerrada: techo con la salida del extractor, frente negro con puerta de cremallera y rejilla. Si hay plantas vivas, se escapa una línea de luz bajo la puerta.
  - **Al entrar** (por la puerta) desaparecen el techo y las paredes de delante y de la derecha: se ven la pared del fondo y la izquierda, de mylar, el suelo, **una mesa por plaza con su maceta encima** y los **focos colgando, medio transparentes**, con su cono de luz detrás de las plantas.
- **Nuevo: macetas de 4 tipos** (plástico 7 L de serie; tela 11 L, plástico 18 L y tela 25 L en la tienda). La de tela airea las raíces: más cosecha y menos plagas, pero bebe más; la grande da más y crece algo más lenta. Se cambian en una plaza vacía; la vieja va a la mochila. Cada carpa admite una maceta máxima (11 L en el armario).
- **Nuevo: 7 focos** (CFL 125 W de serie; sodio 250/400/600 W y LED 200/480/720 W). Cada uno cubre 2, 4 o 6 plantas: un foco pequeño en una carpa grande no llega a todas y rinden menos. El sodio es barato pero calienta y seca las macetas; el LED cuesta más, rinde más, sube más el THC y casi no seca. Cada carpa aguanta unos vatios como mucho. Al comprarlos, Kiko pregunta si los cuelga ya; también se cambian desde la pared de la carpa.
- **Nuevo: factura de la luz.** Cada día, 0,02 € por vatio de cada carpa con alguna planta viva.
- **Cambiado:** fuera «Maceta extra» y «Lámpara LED». Las partidas guardadas se convierten solas: con macetas extra tienes la carpa de 100, la LED pasa a un LED en cada carpa y las plantas siguen donde estaban. Lo de serie da exactamente el cultivo de antes.
- **Menús:** PLANTAS enseña cada carpa con su foco, su factura y sus plazas con la maceta; la mochila enseña las macetas y los focos de repuesto; consejos nuevos de Kiko.
- **Arte (F8):** carpa por dentro y cerrada con `create_image_pixflux` img2img sobre su huella procedural (una generación de cada vista para la de 150; la de 100 y la de 60 se recortan de ella), macetas con `create_1_direction_object` usando la maceta de tela recortada a 16 px como estilo, focos y mesa en otros dos lotes. El motor quita la maceta de tela de cada fotograma de la planta y pinta la nueva debajo. Atlas: 1099 fotogramas. La carpa de la 1.5 queda en `descartadas`.
- **Tests:** `npm test` 38/38 (carpa, focos, macetas y factura) y `npm run test:arte` 20/20 (carpas, focos, macetas y mesa del atlas).
- **Coste:** 64 generaciones (4 pixflux y 3 lotes; uno descartado porque las macetas salían demasiado grandes).

## 1.5.0 · 6 de octubre de 2026

- **Nuevo: el resto del mundo sale de PixelLab (F3-resto, F4, F5, F6 y F7).** El atlas pasa de 569 a 1086 fotogramas; lo procedural queda de reserva.
  - **Humos y efectos:** cigarro, puro, porro, pipa, nube de vaper, golpe, gotas, brillo, polen, ácaros, monedas y spray, cada uno animado con `animate_object`. **Gaviotas y palomas** animadas (aleteo y picoteo).
  - **Tiles:** 12 del barrio con `create_tiles_pro` (dos llamadas: tierra y puentes se repitieron con la barandilla en su borde), agua, flores y hierba pisada animadas con `animate_image`; paredes y suelos de los tres interiores, felpudo y suelo de la carpa, también con `create_tiles_pro`.
  - **Fachadas:** piso, growshop, bar y casa gris con `create_image_pixflux` img2img sobre la huella del edificio (strength 30); las puertas se abren con `animate_image`. La casa gris no tiene puerta (se tapó la que pintó PixelLab con una ventana).
  - **Objetos:** árbol, farola y fuente (con agua animada) con `create_map_object` sobre el mapa; carpa de cultivo con pixflux sobre una huella; 20 props pequeños (con las luces de la gramola), nevera y cama.
  - **Plantas:** 6 fases, maceta vacía (sale de la germinación sin el brote) y balanceo en vegetativo, floración y lista. Los cogollos siguen en la rampa magenta y salen del color de cada variedad.
  - **Combate:** jugador de espaldas, policía y 3 ladrones con `create_image_pro` → `create_character` v3 → animaciones v3 a medida (golpe, patada, spray, comer, herido, desmayo; ataque, herido, huida; alto, multa, soborno, persecución). Fondos del callejón y de la calle con img2img.
  - **Iconos y título:** la bolsa y 12 iconos más, 4 cogollos de la Genoteca y la pantalla de título.
  - **Protagonista:** las 8 acciones que faltaban (correr, regar, plantar, cosechar, cruzar, oler, vender y móvil), con los 13 colores del sprite aprobado.
- **Nuevo: orillas (F4b).** Tres Wang de `create_topdown_tileset` encadenados por la misma hierba (agua, tierra y plaza). El motor (`arteOrilla`) pinta la transición sobre el agua, la tierra o la plaza que toca hierba, con máscara de esquinas; debajo sigue el tile de siempre (el agua, animada). La hierba de las orillas es la del tile aprobado, así que no hay costuras.
- **Nuevo:** el título sale del atlas cuando está (`arteTitulo`); sin atlas, el procedural. El calco incluye el título y las orillas, y `npm run test:arte` los comprueba (19/19).
- **Descartado:** `create_building_kit` (piezas en perspectiva de 24×42 que no casan con la rejilla de 16 px) y, para fachadas y carpa, `create_map_object` y `create_image_pro` (casas estrechas, carpa rara). Están en el manifiesto con su motivo.
- **Corregido: la carpa de cultivo.** La primera versión era una carpa vista de frente, con la pared trasera ocupando dos tercios del alto, y las macetas de arriba parecían colgadas de la pared. Ahora se ve desde arriba: del arte de PixelLab quedan el panel LED, el marco, una franja corta de pared trasera y las paredes laterales, y dentro se ve el suelo de mylar donde apoyan las macetas. Además mide 72 px de ancho (4 más por cada lado) para que las macetas de la izquierda no pisen el marco.
- **Nuevo: APK de Android** (`npm run apk` → `dist/ribera-verde.apk`, 0,8 MB). Una actividad con un WebView a pantalla completa e inmersiva que carga el `index.html` del build; sin permisos ni red; Atrás = B (si no hay nada que cerrar, la app pasa a segundo plano). Se construye sin Android SDK: stubs de la API + dalvik-dx + apktool + uber-apk-signer. Mínimo Android 7 (API 24), objetivo API 34, firma v2/v3.
- **Coste:** 425 generaciones en esta fase (de 1534 a 1109), 9 de ellas en las orillas.

## 1.4.0 · 6 de octubre de 2026

- **Nuevo: F1, protagonista generado con PixelLab** (aprobado). `base` + `idle` + `walk` en 4 direcciones (36 fotogramas, 14 colores), en el atlas `assets/sprites/atlas.{png,json}` e incrustado en el build. El resto del juego sigue procedural.
  - `create_image_pro` (64 candidatos de 32×32, prompt de RPG de portátil pulido) → el candidato 17 → `create_character` v3 con esa referencia → `idle` y `walk` con animación v3 a medida (las plantillas lo ponían de espaldas mirando al sur).
  - 27-28 px de alto y 16 de ancho, cabeza grande, ojos legibles, contorno limpio, 13 colores (`reduce_colors` con los 36 fotogramas juntos).
  - Coste real: unas 195 generaciones, incluidas tres versiones descartadas (estándar de 24-27 px, editada de 22-23 px y de 16 px).
- **Nuevo: F3, los 19 personajes con la misma receta** (13 NPC y 6 clientes, 510 fotogramas en el atlas).
  - Cada uno: `create_image_pro` 32×32 con el player como imagen de estilo (64 candidatos) → `create_character` v3 con el elegido → animaciones v3 a medida → `reduce_colors` a 15 colores.
  - `idle` al sur (y sur, norte y este en Kiko, Josune, Baltasar y Toño); `walk` sur/norte/este en los que caminan (el oeste es espejo del este); las acciones de ambiente de siempre (fumar, puro, pipa, vapear, semillas, servir, punto, radio, móvil…).
  - El caminar al sur se pide «de frente toda la animación»: la descripción normal lo giraba de lado (a Begoña se le repitió).
  - Coste: unas 480 generaciones (20 del Pro, 1 del v3 y 1 por dirección animada en cada personaje).
- **Cambiado:** el motor solo pone el `idle` en las direcciones que lo tienen (o su espejo este/oeste); en las demás, la base. `npm run test:arte` lo comprueba (17/17) y compara el atlas de calco con el número de PNG calcados en vez de con un mínimo fijo.

## 1.3.0 · 5 de octubre de 2026

- **Nuevo: el motor ya usa sprites (F2).** `src/js/01b-arte.js` carga el atlas que incrusta el build y dibuja con él personajes, tiles, objetos, edificios, plantas, combate y efectos; lo que falte sigue saliendo procedural. Incluye:
  - caminar y correr sincronizados con el paso, `idle` con fase propia por NPC;
  - acciones de ambiente (los fumadores fuman con su humo aparte; Unai nunca);
  - acciones del jugador (regar, plantar, cosechar, oler, cruzar, vender) y animaciones de combate;
  - cogollos del color de cada variedad, planta seca y plaga;
  - `?arte=procedural` para comparar.
- **Nuevo:** catálogo de sprites por familia de PixelLab (`docs/CATALOGO-SPRITES.md`, `npm run sprites:catalogo`).
  - Cada sprite va a la herramienta que mejor lo resuelve.
  - Fachadas, carpa, árbol, farola y fuente se pintan con `create_map_object` sobre recortes del mapa con máscara.
  - Personajes de combate con paso previo `create_image_pro` + `create_character` v3 para no perder la identidad.
  - Fondos y título con img2img.
  - Dos lotes compartidos de `create_1_direction_object`.
  - Coste documentado: ~410 generaciones (antes ~460) y herramientas descartadas con su motivo.
- **Nuevo:** `tools/sprites/calco.js` y `npm run test:arte`: atlas de calco sin gastar créditos y 16 comprobaciones del motor. Con ese atlas la historia completa también da 34/34.
- **Cambiado:**
  - `procesar.js` cuenta el tope de colores por sprite en tiles y objetos, encaja los efectos que crecen y admite `ajuste_por_sprite`.
  - `atlas.json` pasa a la versión 2, con `cubre`, `ambiente`, `fumador` y `menores`.
  - `validar.js` comprueba familias, lotes, pasos previos, máscaras y dependencias.
  - Las animaciones de balanceo de la planta tienen nombre propio.
  - Los scripts de Playwright aceptan `CHROMIUM_PATH`, `RV_HTML` y `RV_SALIDA`.

## 1.2.0 · 5 de octubre de 2026

- **Nuevo:** kit pro de sprites y animaciones con PixelLab para Claude Code. El juego no cambia.
  - `docs/PIXELLAB.md` (guía): dirección de arte, fases, animaciones, comportamientos de ambiente (fumadores con humo aparte), integración en el motor, QA, presupuesto y problemas típicos.
  - `art/manifest.json` (47 assets + 14 items, cobertura del 100 %).
  - `art/inventario.json`, `art/referencias/` y `art/paleta/`.
  - `tools/sprites/` (`referencias`, `paleta`, `validar`, `procesar`).
  - Comando `/sprites` y `.mcp.json.ejemplo`.

## 1.1.0 · 5 de octubre de 2026

- **Arreglado:** los cruces sin receta fallaban. Se gastaban las semillas y no salía el híbrido propio.
- **Arreglado:** las redadas no podían ocurrir porque el calor bajaba antes de comprobarse. Ahora saltan con calor ≥ 90 al empezar el día.
- **Arreglado:** el capítulo 5 no empezaba si la 8.ª variedad llegaba por un regalo (abuela Txaro) o por un arbusto, hasta la siguiente cosecha, venta o cruce.
- **Arreglado:** no se podía hablar con Josune, la camarera, porque quedaba detrás de dos taburetes. Ahora está en (2,2).
- **Ajuste:** los ladrones de capítulos altos ganaban casi siempre. Ahora tienen vida `12 + 2 × cap. + 0…4` y daño `2 + cap./4` a `4 + cap./2`, y cada ladrón vencido sube +2 la VIDA máxima (tope 60).
- **Nuevo:** código separado en 16 módulos (`src/js`) con build reproducible, `index.html` jugable sin conexión con las fuentes incrustadas, test automático de la historia completa (34 pasos), generador de documentación, capturas y documentación de diseño, guion, genética, mapa y sprites.

## 1.0.0 · 5 de octubre de 2026

- Primera versión, publicada como Artifact de Claude.

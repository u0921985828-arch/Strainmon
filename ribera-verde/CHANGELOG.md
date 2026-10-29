# Cambios

## 1.58 · Google Play (en curso, por fases del plan)

### Siguiente (sin APK todavía) · rarezas heredables y el cuaderno de fenotipos (ESTUDIO, tanda 2; lo pidió el usuario: «metas mano a las mejoras que hablamos»; con `Datos.CAL`)

- Rasgos raros que se heredan (`RAREZAS` de `tools/rarezas.py`): 1 de cada 50 plantas sale con uno sin que lo lleve su línea —enana (crece un 15 % más deprisa y rinde un 10 % menos), doble cosecha (rebrota una vez a vegetativo y da una segunda cosecha del 60 %), aroma único (su hierba se paga un 25 % más, por gramos en el lote: `ar` en `junta_lote`, `mover_lote`, `cura_de` y `calidad`) y resinosa (+1,5 de THC)—. Por hash de la planta (`Datos.hash_str`), sin tocar el azar del juego (`rarezas_de` al final de `genes`, `ra_tiene`).
- Se fijan como las líneas: si cosechas semillas de una planta que lo saca, su línea lo lleva a nivel 1 (25 de cada 100 lo sacan) y sube uno por generación hasta el 4.º (todas: fijado; `hereda_ra`, `S.ra`); al cruzar, el hijo lo hereda un nivel por debajo (`cruza_ra`). Sin semillas no pasa a la línea (los esquejes son la misma planta y lo sacan).
- El cuaderno de fenotipos en la GENOTECA (CUADERNO DE FENOTIPOS, cuando hay alguna): cada planta rara cosechada, con sus rasgos (y la rara de color, que no se hereda), el día, el sitio y lo que lleva ya su línea (`S.album`, `apunta_album`, `cuaderno_fenos`, `lugar_album`). La ficha de la planta dice su rasgo desde el 35 % y si está rebrotada.
- Prueba `tests/rarezas.gd`.

### Siguiente (sin APK todavía) · los esquemas de macetas de las carpas (lo pidió el usuario: «Posibilidad de poner x de cierto tamaño, elegir por patrones igual, cuando ya tienes ciertas macetas para completar todo el esquema de la carpa te ofrece poner X cantidad dependiendo de cada maceta»; con `Datos.CAL`)

- En KAIA, cada carpa con su esquema: A en la carpa → «Esquema de la carpa» elige cuántas macetas lleva y de qué tamaño (`KC_PATRON` de `tools/patrones.py`, en rejilla y sin pasar de 100 L por m²: la de 200 × 200, 16 de 25 L, 9 de 35 L o 4 de 50 L; la de 400 × 200, 32, 18 u 8; la de 400 × 400, 64, 36 o 16). Con las macetas que tienes se ponen sin pagar y la carpa te dice qué esquemas puedes completar ya; si faltan, se piden las que faltan por la cuenta. Solo con la carpa vacía; las que quitas, a la mochila (las del kit no son tuyas: se retiran con él). La luz de la carpa se reparte entre todas, al mismo ritmo (los mismos gramos por carpa, por la maceta): más plantas pequeñas, más fenotipos donde elegir; menos y más grandes, las de 50 L rinden más por cosecha. El dibujo de la carpa, a escala. Al pasar al nivel siguiente o reformar, las macetas que pusiste tú vuelven a la mochila (`S.kc.pat`, `kc_pat`, `kc_off`, `kc_ci`, `kc_esquema`, `kc_pon_pat`, `kc_devuelve_macetas`, `kc_dibujo`; las plazas de las carpas van seguidas en `S.kc.p`; sin esquema, el del kit, como antes).
- La maceta de tela de 50 L (`MACETA50`, 410 g por planta, cosecha +10 %, 8 €, cap. 4, detrás de la de 35 L en la tienda): solo para los esquemas de KAIA (ninguna carpa de casa la admite): en la tienda solo con la licencia de KAIA (`kaia` en la tienda, `shop_cond`), y la mochila lo dice.
- En casa, completar la carpa: con macetas de un tamaño para todas las plazas vacías que no lo llevan, y sin pasar de la tierra de la carpa, la carpa (y una plaza vacía, aunque ya lleve esa maceta) ofrece «Completar con macetas» (`completa_macetas`, `completar_macetas` en `granja.gd`); las viejas, a la mochila.
- Prueba `tests/patrones.gd`.

### 0.65.4 (código 89) · nombres reales, más tierra, la maceta de 35 L y el seto (lo pidió el usuario); APK en `descargas/LandraceHunters.apk` (89 MB)

- Con `Datos.PLAY` vuelven los nombres reales de las variedades y las extracciones («volviésemos a usar los nombres originales de cepas y de extracciones»); solo el kit Ice-o-lator sale como «Ice Hash» («Ais-o-lator… es demasiado cateto»). `NOMBRES` en `tools/play.py` (las parodias de antes en `PARODIA`, sin usar), `datos/play.json`, i18n sin parodias; prueba `tests/play.gd`.
- Con `Datos.CAL`, cada carpa admite al menos sus plazas × su maceta más grande de tierra (`litros_max` en `granja.gd`): la de 120 × 120, 150 L, para las seis de 25 L (antes 144); prueba `tests/tierra.gd`.
- La maceta de tela de 35 L (lo pidió el usuario: «en la siguiente carpa más grande, deberían de entrar macetas algo más grandes… la cantidad de tierra pues eso lo mismo»; con `Datos.CAL`): `MACETA35` en `datos.json` (290 g por planta, cosecha +8 %, 6 €, cap. 4, al final de la tienda), que `_aplica_auto` pone en `MACETAS`, `MACETA_CM` y `SHOP`; cabe en la carpa de 150 × 100 (`lmax` 35: 6 × 35 = 210 L de tierra) y la llevan las carpas de KAIA (`KAIA_CULT.maceta`); en la de 120, no. Su dibujo en la vista C, de tela verde oliva (`maceta-c-tela35-28` en `equipo_c.py`, pegada en `godot/arte/carpa.png` con `tools/maceta35.py`); prueba `tests/tierra.gd` (29/0).
- El seto de la fila de abajo ya no sale en un cuadro translúcido bajo los pies (lo vio el usuario en el móvil): asoma 1 o 2 px sobre su casilla y rozaba los pies; lo que solo roza las últimas `TAPA_PIES` filas del cuerpo no tapa (`tapa_pj` en `pinta.gd`); prueba `tests/translucido.gd`.

### 0.65.3 (código 88) · el reloj más lento (lo pidió el usuario: «el tiempo en el juego debería pasar más lento»; con `Datos.CAL`)

- Un día del juego dura 12 minutos de verdad (antes, 4): el minuto del juego pasa de 167 ms a 500 ms (`ms_por_min` en `juego.gd`). OPCIONES → RELOJ lo cambia en bucle: 12, 24 o 4 minutos el día (`RELOJ_DIA`, `aj.reloj`, se guarda en los ajustes). Sin CAL, el ritmo del HTML (`D.MS_PER_MIN`). Prueba `tests/reloj.gd` (11/0).

### 0.65.2 (código 87) y plugin de WordPress 1.6.5 · sin franjas blancas en lo translúcido (lo vio el usuario en el móvil)

- La capa de la 0.65.1 dejaba en el móvil franjas blancas a lo alto de la pantalla detrás de árboles y farolas: una sola textura para todas las capas del fotograma, que se rehacía al cambiar de tamaño y se liberaba con la orden de pintarla aún pendiente (rectángulo blanco). Ahora la capa es solo para las mesas con plantas, focos o bandejas, recortada a lo que tiene (`get_used_rect`), con una textura por capa y fotograma (`_capt_tex`) y las cambiadas vivas hasta el siguiente (`_capt_viejo`); lo que va solo (árbol, farola), con su alfa de siempre. Prueba `tests/translucido.gd` (14/0).

### 0.65.1 (código 86) y plugin de WordPress 1.6.4 · la mesa con plantas, translúcida en una sola capa (lo pendiente de la 0.65.0; con `Datos.CAL`)

- Detrás de una mesa con plantas (la nave, KAIA), la mesa, las plantas y los focos se pintan juntos en una capa (`capa_unica`, `_con_alfa_capa` en `pinta.gd`: `_img` y `_rect` mezclan en `_capt` en vez de pintar) y esa capa sale a `TAPA_ALFA`: ya no se ve la mesa a través de las plantas. Prueba `tests/translucido.gd` (12/0).
- `descargas/landrace-hunters-1.6.4.zip` (29 MB) y el ligero de 28 KB con la 0.65.1.

### 0.65.0 (código 85) · KAIA por niveles, las madres por dentro, la sala fría, la manicura a la vista, el billar con efecto y lo que tapa, translúcido (tanda nueva, lo pidió el usuario; con `Datos.CAL`)

- **KAIA por niveles** (lo pidió el usuario: «4 de 2×2, luego 2 de 4×2, luego una de 4×4 y después la reforma de la sala a mesas»): `KAIA_CULT.niv` en `tools/kaia_cult.py` — cuatro carpas de 200 × 200 (2 LED de 720 W, 4 plazas; kit 2.700 €), dos de 400 × 200 (4 LED, 8 plazas; 5.140 €) y una de 400 × 400 (8 LED, 16 plazas; 10.200 €), cada una una pieza de ORDENAR de su tamaño en casillas (`kc<nivel><i>`). En el cuadro, «Comprar una carpa» y «Pasar a la …» (`kc_sube`: con las plazas vacías, las de antes de segunda mano al 40 % y la primera del nivel nuevo al día siguiente); en el último nivel, «Reformar la sala». Las carpas, a mano en `kaia_carpa.py` (`carpa_kc`: frente, techo por metros, un LED por columna, extractor y filtro). Las partidas de antes pasan al nivel 1 (o al 0 con la obra) con sus plantas.
- **Las madres por dentro** (`vista_madres` en `nave.gd`): la carpa de la vista C con dos LED a 18/6 y su temporizador, cada madre con el tono de su hoja, su barra de vigor y sus esquejes; flechas, A (cortarle esquejes tú una vez al día con vigor ≥ 40, recoger los listos o meter una en el hueco), B cierra. Prueba `tests/madres_vista.gd`.
- **La sala fría del sótano** (`tools/sala_fria.py` → `FRIA`, `MAPS.fria` 11 × 6; `src/salafria.gd`): por la puerta (3, 1) del sótano, cerrada hasta la obra de la tienda online (6.800 €: paneles de 80 mm, equipo de frío a 4 °C y mesa de acero; en Play, 11.000 € con el sótano). Hecha, las máquinas de extracción dejan el piso y se montan allí contra la pared de abajo, y lo que se saca rinde más (`FRIA.rend`: hielo, lavadora y tamiz +15 %, static +10 %, prensa +5 %). Arte a mano en `sala_fria.py` (el evaporador y la mesa). Prueba `tests/sala_fria.gd`.
- **La manicura a la vista** (`MANICURA.pasos` de `tools/manicura.py`, escena «mani» en `escena_extr.gd`): tres pasos con su barra (las hojas grandes, las de azúcar a ras, redondear) y encima el cogollo en la bandeja de rejilla, el guante de nitrilo y las tijeras de punta fina; lo que entra deja el lote en 0,6 + 0,4 × q, y por debajo de 1 se puede repasar (nunca baja). Prueba `tests/manicura.gd`.
- **El billar, con control** (`billar8.gd`, `_b8_tuyo` en `venta.gd`): arriba y abajo, de un toque, 0,2° (`B8_PASO`); a los lados, despacio al principio; un toque de A cambia el efecto (al centro, retroceso, seguir: `dispara(…, efe)`, en el primer choque de la blanca, `EFECTO`; en la banda se pierde); la barra con sus marcas de un cuarto, la del último tiro y la blanca con el punto del taco.
- **El rival, equilibrado y rápido:** su pulso sube 0,04 si le ganas y baja si pierdes, hasta ±0,12 por club (`b8_ajuste`, `b8_apunta`, `S.b8aj`); piensa, gira el taco y carga sin hacerse esperar (`B8_PIENSA_R`, `B8_GIRA`, `B8_CARGA_R`). Prueba `tests/billar8_tiro.gd`.
- **Lo que tapa al protagonista, translúcido** («como en los Sims»): lo alto que se pinta delante de él y le pisa el cuerpo (los árboles, las farolas, los muebles altos, las carpas del piso) se pinta al 45 % (`tapa_pj`, `_con_alfa`, `alfa` en `pinta.gd`); sentado, en los menús y sin CAL, como antes. Prueba `tests/translucido.gd`.
- **Tras la revisión:** cada nivel de KAIA rinde más por plaza (`efi`: 0,9; 1; 1,12), así que subir compensa; las salas de antes devuelven lo que no cabe (los kits de más a la cuenta y una semilla por planta, con aviso); con la sala fría, la mesa de la tía solo ofrece lo que se hace a mano (`extr_ya` en `salafria.gd`); el rival del billar piensa en otro hilo sobre una copia y con tope (`B8_PIENSA_MAX`, `elige(…, lim)`): la mesa no se congela; las plantas de las mesas de la nave y de KAIA también se vuelven translúcidas (`tapa_encima`); «Quitarla» en las madres también en inglés y el plano de cortarle esquejes con su variedad.
- Inglés en `godot/i18n/partes/copa.csv`.

### El banco de semillas de la tía, la meta del juego (ESTUDIO, tanda 1; lo pidió el usuario: «también quiero que metas mano a las mejoras que hablamos»; con `Datos.CAL`)

- **La meta ya no es facturar.** Con la lata abierta, OBJETIVO dice «Restaura el banco de semillas de la tía…: n/6 colecciones» y la más cercana (`bt_objetivo`, antes que el imperio); OBJETIVO → EL BANCO DE LA TÍA abre la lista. El tráfico (pisos, franco, mar) queda como rama aparte.
- **El cuaderno azul es el Acto I.** La lata del manzano trae, además de la Haze del 98 (ahora en F1, de una polinización al aire: hay que fijarla), la llave del cuarto de atrás de la asociación y dos notas de la tía (`hilo_lata`).
- **El cuarto de atrás** (`banco-rv`, 12 × 8, por la puerta (9, 1) de la asociación, cerrada hasta tener la llave; `tools/banco_tia.py` → `BANCO_TIA`, `MAPS["banco-rv"]`, `PUERTAS_INT`). Todo tapado con sábanas menos el fichero.
- **Seis colecciones** en el fichero, dos semillas de cada variedad: Kush e Himalaya, la costa, África y el Mediterráneo, la sierra americana, Asia (31 landraces de verdad) y la Haze del 98, cinco y fijada en F4. Cada una destapa su mueble: la cámara fría (una semilla de lo guardado cada 7 días), el laboratorio (estabilizar con una semilla, una vez al día y una vez por cosecha de cada línea: cada generación, una cosecha; `estabilizar(k, coste)` dice si se hizo, `cult_apunta` cuenta las cosechas), la sala de catas (un lote analizado al día), el archivo (una receta de los cuadernos al día) y el mostrador de los socios (2 semillas de una landrace sin descubrir cada 7 días, nunca de las que escondió la tía); la Haze va en el último cajón y cuelga la placa, que se toca desde delante del fichero: escena con Delroy, Kiko, Miren y Txaro, reputación y prestigio (`bt_fin`).
- **Arte a mano** (`tools/sprites/a-mano/banco_tia.py`, grupo `banco-tia`): el fichero con la lata y el cuaderno, la cámara, el archivo, el laboratorio, el mostrador, la mesa de catas, lo tapado y la placa.
- **Código:** `src/bancotia.gd` (entre `hilo` y `retencion`; `S.bt`), `bt_entra` en `enter_map`, `bt_obj` en `object_action`. Inglés en `godot/i18n/partes/copa.csv`. Prueba `tests/banco_tia.gd`.

### Nada encima de nada, y la sala de KAIA por fases (lo pidió el usuario: «No quiero que ningún objeto de pared o suelo se superponga sobre otro / Queda mal y descuidado» y, de KAIA, «como en casa, cultivo con carpas, pero más grandes de primeras, con una inversión realista, después como en la nave en esa misma habitación, ya con posibilidad de poner a alguien a trabajar ahí y la inversión será más grande»; con `Datos.CAL`)

- **Ningún mueble encima de otro.** Prueba nueva `tests/solapes.gd`: en cada interior, con los sprites de verdad (`mide` en `pinta.gd`, `cajas_obj`/`solapes_de` en `calle.gd`), ningún píxel opaco de un objeto cae sobre otro de otra casilla (salvo las piezas seguidas de un mismo mueble y el asiento pegado a su mesa). De 47 solapes a 0: `tools/solapes.py` aparta lo que estaba montado (expositores, cajas, mesillas, nasas, la barra de la taberna), las puertas de dentro a 16 px con su contorno (`sotano.py`, `laboratorio.py`), la vitrina del grow y el atrezo de la comisaría y el taller (`mundo.gd`), y la iglesia por dentro y el cartel de Bilbao (`bilbao.py`).
- **Al ordenar, tampoco.** Regla `solapa` en `cabe_pieza` (`pieza_solapa`): una pieza no cabe donde su sprite pisaría el de otra; motivo «…quedaría encima de otra cosa».
- **KAIA, fase 1: carpas grandes por kits.** La sala (`cult-muelle`, ahora 16 × 10) empieza vacía; en el cuadro del pasillo, «Comprar un kit de carpa · 3.180 €» a precio de tienda (carpa de 240 × 240 × 200 cm, dos LED de 720 W, extractor de 250 mm con filtro de carbón y goteo de 9 salidas), por la cuenta, llega al día siguiente; hasta cuatro, de nueve plazas cada una (`KAIA_CULT.kit`, `S.kc.kits`). Cada carpa lleva su extracción en su propio sprite (`kaia_carpa.py`, `carpaKG-<plantas>`), así que no hay nada fijo en la pared que quede encima o suelto al moverlas; solo en la zona de cultivo y sin solaparse.
- **KAIA, fase 2: como la nave.** «Reformar la sala · 45.000 €» (obra, seis mesas de 240 × 120 con su LED doble, riego centralizado y extracción), con las carpas vacías: se venden de segunda mano al 40 %, la obra dura 5 días y deja las mesas, el tanque y el programador del riego (`KAIA_CULT.f2`). Rinde más que las cuatro carpas (8.640 W frente a 5.760 W).
- **Alguien que la lleve.** Desde el móvil, «A la sala de KAIA» pone a un trabajador de la plantilla con el rol `kaia` (45 € al día por `PLANTILLA.sueldo`): cada mañana las mesas avanzan, se cortan enteras, se secan y lo seco va al almacén de KAIA hasta su tope (lo que sobra, en la mesa: «Llevarte lo seco»). Sin nadie, no avanzan. Su muñeco, en la sala.
- **Las mesas, pintadas como las de la nave** (`mesa_de` en `nave.gd` y `kaiacult.gd`, que usan `_arte_obj` y `_focos_mesa`); los focos de la segunda fila cuelgan de su techo (`t0` en `_poleas_nave`), sin cruzar las de delante.
- **La copa no toca el foco.** En la sala de KAIA (poco techo), con las plantas muy crecidas el foco ya no puede subir más: la copa pierde filas enteras, como en la vista C (`copa_bajo_foco` en `pinta.gd`, con `Arte.aplasta`), y la punta queda a `FOCO_AIRE` px del foco en su altura más baja. En la nave caben enteras.
- **Partidas de antes:** el `S.kc` de las tres carpas pasa a tres kits con sus plantas en sus plazas.
- **Sin mover nada al cargar.** Lo que una partida ya tenía puesto no se recoloca por la regla `solapa` (`cabe_pieza(…, sol)`, solo para lo que mueves tú); la carpa grande del piso se queda donde estaba.
- **Sin romper lo de antes.** Lo que se aparta en los mapas de antes del calendario va solo con `Datos.CAL` (`SOLAPE_CAL` en `mundo.gd`: el expositor de GROW IBARBIDE y las cajas del almacén; `defc` y `def_p` en `calle.gd`: las máquinas de las extracciones del piso, con una casilla libre entre cada dos y la de la puerta libre), así que las pruebas contra el HTML no cambian. Todo lo apartado deja el paso: la mesilla del cuartucho junto a su mesa (no delante del cuadro), el escritorio de la comisaría en la sala, el extintor del taller fuera del calendario de la pared y la caja de la taberna al final de la barra.
- **La sala de KAIA en la plantilla.** Quien la lleva sale en MÓVIL → PLANTILLA en «La sala de KAIA», no «Sin trabajo» (`local_staff`); y la obra no se hace con un kit pagado que aún no ha llegado.
- Pruebas `tests/kaia_cult.gd` (192), `tests/kaia_orden.gd` (al día, con las carpas de 240 × 240), `tests/solapes.gd` (con la carpa grande de una partida de antes) y `tests/orden_sala.gd`. Inglés en `godot/i18n/partes/copa.csv`.

### La sala de cultivo de KAIA (lo pidió el usuario: «incluso molaría tener un cultivo finalmente en la nueva asociación de KAIA» y, de las carpas, «tiene que tener lógica con el suelo que hay al rededor y las zonas donde las colocas»; con `Datos.CAL`)

- **Por su puerta, con la licencia.** La puerta (15, 1) de KAIA (la gramola, una casilla a la izquierda; delante, libre al ordenar el club) lleva a la sala de cultivo (`cult-muelle`, 14 × 8; `tools/kaia_cult.py` → `KAIA_CULT`, `MAPS`, `PUERTAS_INT` con `llave: "kc"`), cerrada hasta sacar la licencia (`S.mar.lic`, `kc_cerrada`).
- **El suelo dice dónde va cada cosa.** A la izquierda, el pasillo con el suelo del club; pasada la junta, la zona de cultivo con el suelo de resina y desagüe del grow (`floorG`). La extracción con sus filtros encima, el cuadro del temporizador y el depósito y la bomba del goteo al fondo.
- **Tres carpas de 120 × 120 con su LED, cuatro plazas cada una.** A en una carpa, sus plazas; en cada una, lo de siempre (plantar, abonar, tratar, esquejar, cosechar: `pot_action` con `hu`, como la huerta). Crecen con el clima controlado de la sala y el goteo las riega solas, también sin estar dentro (`kc_avanza` desde `plants_advance`). Cada carpa se ve con las plantas que tiene (`carpaM-<n>`).
- **Ordenar con lógica.** Desde el cuadro de la pared, ORDENAR LA SALA DE CULTIVO: las carpas solo caben encima del suelo de su zona (regla `zona` de las piezas en `cabe_pieza`, motivo «Las carpas, en la zona de cultivo…»); una carpa guardada fuera vuelve a la zona al entrar.
- **Código:** `src/kaiacult.gd` (entre `bancotia` y `retencion`; `S.kc`), `kc_cerrada` en `object_action`. Inglés en `godot/i18n/partes/copa.csv`. Prueba `tests/kaia_cult.gd`.

### El laboratorio de la tía, de verdad (lo pidió el usuario: «el laboratorio debe parecer un laboratorio de verdad, no los materiales de labo y ya, las normas que tienes que tener en un laboratorio real»; con `Datos.CAL`)

- **Su sala, por su puerta.** La colección de la sierra ya no destapa una mesa del cuarto de atrás: abre la puerta (8, 1), precintada con cinta hasta entonces (`puertaLabP`), al laboratorio (`lab-rv`, 12 × 8; `LAB` en `tools/banco_tia.py`, `PUERTAS_INT` con `llave: "lab"`).
- **Como uno de verdad.** Azulejo blanco con media caña, suelo continuo y una línea amarilla de pared a pared (`floorLabL`, columna `LAB.linea`) que parte la antesala (lavamanos de pedal, percha con batas, gafas y guantes, cartel de normas con sus pictogramas) de la zona limpia: cabina de flujo laminar, autoclave, estufa de germinación, nevera de muestras, microscopio, balanza con urna, contenedores amarillo y rojo, ducha de emergencia, lavaojos, extintor de CO2 y botiquín.
- **Las normas mandan.** Siete normas firmadas «M.» en el cartel; la línea no se pasa sin manos lavadas y EPI, por ese orden (con guantes no se lavan); no se cata dentro; colocado o bebido no se trabaja; el instrumental, al autoclave cada día (media hora, `LAB.esteril`); el puesto, recogido al contenedor antes de volver a estabilizar; el EPI se queda dentro al salir (`lab_norma`, `linea_lab` en `try_move`, `S.bt.ld`).
- **Arte a mano** en `tools/sprites/a-mano/laboratorio.py` (`interior-lab`, `lab-alto`, `lab-ancho`). Inglés en `godot/i18n/partes/copa.csv`. Prueba `tests/banco_tia.gd` (§ 7: alcance de cada mueble, la línea, el orden del EPI, catar, colocado, autoclave, recoger y la salida).

### El tren de la comarca llega a su apeadero (lo pidió el usuario: «si te permite ir a demás pueblos, debería de haber estación de tren en los demás pueblos, no puede ser que subas al tren y aparezcas en la parada del bus»; con `Datos.CAL`)

- **Un apeadero en cada pueblo de la parada.** Ribera Verde, Puerto Viejo, Valdehierro, Mendialde, Errotabarri e Ibarbide tienen su apeadero: la caseta de la vía estrecha de Zorroza (`edificio-apeadero`), puesta como hito con `M.apeadero` en `tools/pueblos.py`. Se quitan el monte y los árboles que lo tapaban.
- **El tren va de estación en estación.** Llega delante del apeadero y ya no a la parada del autobús (`apeadero_de`). Desde un apeadero se va a los otros pueblos o a Bilbao, donde se llega a la puerta de la estación de Zorroza (`TREN_BILBAO`).
- **El precio y el horario.** El billete sale por el tramo entre el origen y el destino (`tren_viaje(k, de)`). El apeadero sigue el horario de las estaciones: cerrado de 23:00 a 6:00.
- **La vía al lado de cada apeadero** (lo pidió el usuario: «el apeadero deberá de estar cerca de unas vías»). Vía estrecha (`viaE`, y en vertical `viaEV`) pegada a la caseta, con `M.via` en `tools/pueblos.py`: en Mendialde pasa por la ladera de canto a canto; en los demás entra por el canto del mapa y acaba en su topera (`viaEF`, `viaEFN`, `viaEFS`, la viga a franjas rojas y blancas, a mano en `tools/sprites/a-mano/bilbao.py`). Ribera Verde, por el canto de poniente hacia el sur; Puerto Viejo, bajando del monte por detrás de las casas; Valdehierro, por la valla del desguace; Errotabarri, al pie del monte; Ibarbide, por el canto de levante del parque. Sin pasos a nivel: la vía no pisa caminos, puertas, salidas ni calzadas y no corta nada (lo comprueba el alcance de `pueblos.py`). Los apeaderos de Ribera Verde, Puerto Viejo e Ibarbide se mueven junto a su vía.
- **El andén, entre la caseta y la vía** (lo pidió el usuario: «lo suyo sería que las vías sean accesibles, ¿no? Desde el apeadero»). Cada apeadero tiene su andén de losas con el bordillo blanco y la raya amarilla del lado de la vía (`andenN`, `andenO`, `andenE`, a mano en `tools/sprites/a-mano/bilbao.py`), que se anda: lo pone el sexto argumento de `M.apeadero` y el tren llega a él (`bld.anden`, `apeadero_de`). Con A hacia la vía desde el andén se coge el tren igual que en la ventanilla (`en_anden` en `ciudad.gd`). La vía sigue sin pisarse. Prueba `tests/pueblos.gd` § 3b (348/0).
- **Pruebas:** `tests/pueblos.gd` (§ 3b: delante de cada apeadero se llega andando, cierra de noche, el tren llega al apeadero y su vía va pegada, no se pisa y sale del mapa o acaba en la topera) y `tests/interiores_bilbao.gd` (de Zorroza, al apeadero de Puerto Viejo).

### El cuaderno azul de la tía Maite (lo pidió el usuario: «el juego ya me aburre… igual le falta historia, falta contexto»; con `Datos.CAL`)
- Un hilo de historia por encima de la deuda (`src/hilo.gd`, entre `ciudad` y `retencion`; `S.hilo`): Kiko (SMS al amanecer desde el capítulo 3), Delroy y la noche de la Copa del 98, los tres trozos del cuaderno con Miren, la serora de la ermita y la abuela Txaro (en cualquier orden), la lata del manzano de la huerta y una elección: contarlo en la asociación, ir a por Baltasar o guardártelo. Texto completo en `docs/GUION.md`.
- Pararte con la gente (la cena de Miren, la vela de la serora, el café de Txaro) cambia el SMS del final.
- OBJETIVO → LA TÍA MAITE con los pasos; las escenas entran por `hilo_talk` al principio de `npc_talk` (si no toca, lo de siempre), `hilo_dia` al amanecer y `hilo_entra` en `enter_map`. Inglés en `godot/i18n/partes/hilo.csv`.
- Prueba `tests/hilo.gd`.

### Bilbao por dentro y los pueblos con su sitio (lo pidió el usuario: «hay edificios que no se puede acceder… molaría poder acceder al teatro… y a la iglesia también… piensa en qué edificios podrían tener juego en la historia» y «toca también los otros… que no sea todo el mismo esquema de pueblo… más natural, que no sea tan cuadrado. Pero que los píxeles sean perfectos»)
- Con `Datos.CAL`, se entra al teatro, la catedral, San Nicolás, la parroquia de Zorroza y el mercado de la Ribera (`BILBAO.IN`, `BILBAO.NPC` de `tools/bilbao.py`; interiores a mano en `tools/sprites/a-mano/interiores_bilbao.py`; `src/ciudad.gd`, entre `copa` y `retencion`), cada uno con su horario en la puerta (`HORARIO`, `entra_ciudad`).
- El teatro: taquilla de 18:00 a 21:00 (`TAQUILLA`, 18 €), una obra inventada por semana (`OBRAS`), la función de 21:00 a 23:00 en la butaca y el entreacto, donde Ainhoa te pide el número (un VIP en la agenda); el actor que ensaya y el cartel, el telón, el decorado y el palco con su texto.
- Las iglesias: el cepillo (20 €, una vez al día, baja el calor), el confesionario (una vez por semana, baja más), las velas (una por la tía Maite), el banco (un rato en silencio baja el calor 3) y la feligresa y el sacerdote que se acuerdan de la tía.
- El mercado: ocho puestos con su vendedor por horario (`PUESTOS`, `OFICIO`) y la barra de pintxos: comer da vida y baja la borrachera.
- Los nueve mapas de siempre, con plazas, charcas y sendas en mancha, sin esquinas a escuadra (`tools/pueblos.py` → `PUEBLOS` en `datos.json`; `mancha()` poda los picos sueltos) y un sitio propio en cada uno (`hito`, arte a mano en `tools/sprites/a-mano/pueblos.py`): el lavadero del barrio, el estanque y el kiosko del barrio alto (la banda los domingos a mediodía), la grúa de los astilleros, el frontón y la ermita de Mendialde, el faro de Puerto Viejo, la chimenea de Valdehierro y el kiosko del Ensanche (`hito_obj`).
- La ermita de Mendialde por dentro (`ermita-in`) con su serora, que conocía a la tía; de 8:00 a 20:00.
- `pueblos_mapa` va detrás de `montar_locales`, `montar_alto` y `montar_estancos` y se aplica siempre (con CAL los cambios, sin CAL lo de antes): si fuera antes, la copia `_neg0` se tomaba con los cambios puestos y sin CAL se quedaban.
- Pruebas `tests/pueblos.gd` (132: cada cambio puesto, cada hito sólido y alcanzable, todos los clientes alcanzables, sin CAL como antes, lo que hace cada hito y la ermita) y `tests/interiores_bilbao.gd` (50: horarios, taquilla, función, entreacto, cepillo, confesionario, velas, puestos y su gente).

### Más edificios con juego, salidas por su lado, el seto nuevo en la calle y la tierra con atrezo (lo pidió el usuario: «hay edificios que no se puede acceder», «si yo voy del camino de izquierda a derecha… tendré que aparecer a la izquierda. Eso tiene que estar bien conectado y escrito en código», «el seto… hicimos otro ya. No sé por qué se sigue utilizando» y «le daría más atrezo a los suelos de la tierra… me parece muy plano. Lo haría más imperfecto»; con `Datos.CAL`)
- Bilbao, de 5 a 15 edificios que se entran (`PUERTAS`, `IN_N` en `tools/bilbao.py`): las estaciones de Zorroza, Abando y la Concordia (taquillero y máquina: el tren a la comarca, más barato y rápido que el bus, `TREN`, `tren`; panel de salidas, vigilante según el calor), San Antón y la parroquia de Indautxu, el Teatro del Ensanche (otra obra y su propia entrada, `C.entM`), la Diputación (Hacienda foral: declarar efectivo hasta 3.000 € a la semana, se queda el 30 % y el resto entra limpio en la cuenta, `HACIENDA`), el molino de mareas (la muela según la marea, `marea_sube`; una cabezada en los sacos, `CABEZADA`) y el almacén del muelle (descargar tres horas por 45 €, `JORNAL`). Lo que queda (torres, bloques, pisos) son casas de otros.
- Cierran a su hora: dentro, «Vamos, que cerramos.» y a la puerta (`ciudad_cerrada`, `echar_ciudad`, también en el paso de `calle.gd`).
- Cada pueblo con su sitio y algo que hacer en él (`hito_obj`): la torre del reloj de Ibarbide (esperar a una hora), el quiosco de prensa del Ensanche (el periódico: el tiempo de mañana y los sucesos según la policía), el colmenar de Errotabarri (la miel, o te pica), los jubilados del kiosko entre semana, el pórtico de la ermita, rebuscar al pie de la chimenea, el saco de la grúa (experiencia de pelea); arte a mano en `tools/sprites/a-mano/pueblos.py`; sin clientes bajo las copas nuevas (`COPA_N`).
- Salidas por su lado: de un mapa de fuera a otro se llega por el borde de enfrente y se vuelve por donde se llegó; las carreteras van de lado a lado y `tools/carreteras.py` no deja montar una al revés.
- El seto de la calle con el de PixelLab de la huerta (`seto_pieza` en `pinta.gd`: el tramo alterno y el remate redondo en cada punta).
- La tierra y la pista con atrezo: manchas húmedas y secas y grietas en el mosaico de tierra (`m_dirt` de `detalle.py`) y ocho detalles a mano de 16 × 16 por el hash de la casilla (`tools/sprites/a-mano/tierra.py`, `tierra-detalles`, `_detalle_tierra`): piedra, huellas, matojo seco, charco, grieta, ramita, piedrecitas y terrón.
- Las vallas encima de lo que acotan también tras los pueblos nuevos (la vía muerta de Valdehierro, corta y al fondo; la huerta de Errotabarri, con un claro en medio).
- Pruebas: `tests/interiores_bilbao.gd` (864), `tests/pueblos.gd` (169), `tests/conexiones.gd` (153), `tests/vallas.gd` (1096, con el seto) y `tests/detalle.gd` (84, con la tierra).

### Bilbao con su trazado y sus edificios icónicos, y aparcamiento también en los pueblos (lo pidió el usuario: «tanto en los mapas nuevos como en los viejos […] tienes que buscar la estructura del mapa que se parezca al lugar donde te he dicho. Además de tener edificios icónicos, para que sea una experiencia más realista»)
- Trazado de cada zona (`tools/bilbao.py`, sin nada al azar): Zorroza con la ría arriba y el Kadagua al oeste, la vía ancha doble con su paseo, la estación, la avenida, la plaza de la iglesia y la vía estrecha abajo con su apeadero; La Punta en diagonal entre la ría y el Kadagua, con el molino de mareas en la punta, el muelle con norays y las naves; Abando con la ría al este y su puente, la Gran Vía con plátanos, la plaza elíptica, la plaza con la estatua, la torre de oficinas y las dos estaciones; el Casco Viejo con la ría al oeste y al sur, las Siete Calles paralelas con la catedral en medio, la plaza porticada cerrada, el mercado en la orilla, la iglesia junto al puente viejo y el Arenal con su templete.
- 21 edificios icónicos dibujados a mano (`ICONOS` en `tools/sprites/a-mano/bilbao.py`; homenajes de forma, sin rótulos, escudos ni letras reales) y los bloques bajos de Zorroza (`bloqueZ`, `bloqueZ2`); la catedral pasa a 4 × 6 para caber entre dos calles; la estatua (`estatua`, con su texto) y el puente de piedra (`puenteV`).
- El paso subterráneo de Zorroza, en dos (`g` en cada boca de `ESC_Z`): la vía ancha, entre el paseo de la ría y su andén; la estrecha, entre la ladera y el suyo; se sale por la otra boca del mismo paso, sin menú (`bajar_escalera`, `andable`).
- Aparcamientos: en Bilbao, en el sitio del trazado nuevo (Zorroza (13, 21), La Punta (20, 21), Abando (54, 3), el Casco Viejo (6, 29)); en los pueblos de la parada (Puerto Viejo, Valdehierro, Mendialde, Errotabarri, Ibarbide y Hiriburu), su aparcamiento de 3 × 4 junto a la parada (`APARC`; en Valdehierro y Errotabarri se abre el hueco, `APARC_OBRA`). Los pueblos son inventados: su trazado no cambia.
- Pruebas: `tests/bilbao.gd` (426; `forma()` mira el trazado de cada zona: ríos, vías, plazas, calles, puentes y dónde va cada edificio), `tests/aparc_bilbao.gd` (85, con los pueblos) y `tests/escaleras.gd` (30, los dos pasos).
- Tras la revisión: la fila de oeste a este es La Punta → Zorroza → Abando → Casco Viejo (`CADENA`): el Kadagua, solo en La Punta (la punta, sin salida al oeste) y Zorroza de tierra firme, con la costura de cada dos zonas comprobada; Abando con la retícula del Ensanche: tres calles de norte a sur que cruzan la Gran Vía (`V_ABANDO`; casillas nuevas `roadL`, `roadR` y `roadX`, el asfalto del cruce, en `mo-roadL/R/X` de `detalle.py`), manzanas entre ellas y las dos plazas en glorieta con la fuente y la estatua en su isleta (`glorieta`, `MOYUA`, `CIRCULAR`); las Siete Calles con fachada seguida y un solo cantón; la iglesia neogótica de ladrillo, en Abando (Indautxu), y en Zorroza su parroquia genérica con el campanario exento (`iglesiaZ`); el teatro con un óculo y la Diputación con un remate liso, sin nada que se lea como escudo; y el aparcamiento de Hiriburu, también en `METRO.aparc` (`maestro9.py`).

### Aparcamiento en las zonas de Bilbao (lo pidió el usuario: «En los nuevos mapas no hay parking, hay que estudiar el espacio jugable que no sea agobiante»)
- Zorroza, La Punta, Abando y el Casco Viejo tienen su aparcamiento de 3 × 4 (cuatro plazas y el pasillo), como los pueblos: `BILBAO.APARC` en `tools/bilbao.py` deja el hueco y `APARC` en `calle.gd` lo monta. Zorroza (13, 15) en el parque bajo la parada, sin el primer árbol; La Punta (22, 15) en el muelle; Abando (6, 15) en el paseo; el Casco Viejo (4, 10) en la plaza.
- Sin agobio: la primera vuelta alrededor, libre del todo (ni farolas ni bancos pegados); ninguna fachada a dos casillas; con las cuatro plazas llenas se llega a todo. Abando pasa de 26 a 30 filas para que quepa con el paseo y la plaza enteros.
- En coche se va a cada zona (`conducir`): las cuatro salen en «¿A dónde vas?» con su nombre (`nombre_lugar`, de `D.ZONAS`), detrás de Zorroza; de una a otra, 2 km y 5 min por la calle (`BILBAO_KM`); a los pueblos, como desde Zorroza (`parada_de`). Se aparca en la de la zona y te deja en el pasillo (`llegada_parque`); la multa y el viaje de perfil dicen la zona; los pueblos de fondo, por tipo (`PUEBLO_DE`).
- Prueba `tests/aparc_bilbao.gd` (48 comprobaciones; con el código de antes no arranca: sin `nombre_lugar` ni aparcamientos); `tests/vehiculos.gd` recorre también los de Bilbao; `tests/bilbao.gd --pintar` saca los mapas con el aparcamiento y dos coches.

### Las estanterías, una por baldosa en todos los mapas (lo preguntó el usuario: «o las estanterías del almacén son muy anchas para con la baldosa, o se necesita una baldosa de espacio entre cada estantería» y «asegúrate que todas las estanterías del mapa funcionan igual»)
- `almC` (`negocios.py`) medía 20 px (1,25 m) en casillas de 16 px y las cuatro de `alm-rv` y `alm-muelle` se montaban; ahora 14 px más el contorno (0,9 m, el ancho de una estantería de acero), una por casilla, sin baldosa libre entre ellas.
- Igual las demás que se salían de su casilla: las baldas de rejilla del bajo y del sótano (`baldaS`), el armario del bajo (`armS`, con las puertas de canto), la estantería de los abonos (`estanteN`), la librería de la asociación (`libreria`), la de la quesería (`curaQ`), los bidones de la lavandería (`prodL`), la del camarote (`estanteC`), las de los estancos (`estanteE`, dos casillas) y su humidificador (`humidor`), la de ruedas del taller (`rackT`) y el carro de bandejas de la panadería (`rackP`, de PixelLab, estrechado a 16 px sin tocar el alto: `ESTRECHA` en `pixellab_negocios.py`).
- Prueba `tests/estanterias.gd` (248 comprobaciones; 61 fallos con el arte de antes): en cada mapa, lo que se pinta de cada estantería cabe en sus casillas; con `--salida`, capturas de los mapas con estanterías en fila.

### El garaje por dentro (lo pidió el usuario: «un garage por dentro, grande como el taller, que estén aparcados ahí los vehículos, A en cada vehículo para salir, abrir el maletero […] con forma de maletero de coche, o cargar gasolina del coche, no abono»)
- Con `Datos.CAL`, la puerta seccional del garaje de la tía lleva dentro (`GARAJE_IN`, `mapa_garaje` en `calle.gd`): 14 × 10 (lo pidió el usuario: «si haces líneas de aparcamiento, que estén bien hechas, es muy grande»), con el pasillo de 2 m del portón en el medio y dos plazas de 6 × 3 m a cada lado, cerradas por su línea amarilla de atrás, la de entre las dos y la de delante, por el medio de la casilla a 0,5 m de las ruedas (`GARAJE_LINEA`, la casilla `floorGl` en `garaje_dentro.py`) y abiertas al pasillo, el sumidero en el pasillo, pocas manchas de aceite, el banco, el grifo con la manguera, las garrafas de gasolina, aceites, neumáticos, cajonera, extintor y bidón de serrín (textos en `ATREZO_TXT.garaje`); arte a mano en `tools/sprites/a-mano/garaje_dentro.py` (el deportivo sin la plataforma giratoria, garrafas y grifo).
- Cada vehículo comprado, aparcado en su plaza (`GARAJE_PLAZA`: utilitario y berlina arriba, deportivo y moto abajo) y sólido; el que está fuera deja su plaza vacía. Sin vehículos, «Está vacío».
- A en un vehículo (`garaje_coche`): «Salir en …» (sales con él por el portón, como antes), «Abrir el maletero», «Echar gasolina» y «Nada»; sin abono (se sigue cargando en los aparcamientos de los pueblos). Al volver a casa, entras al garaje junto a su plaza (`llegada_garaje`).
- El depósito (`TANQUE`: moto 7 L, utilitario 45, berlina 60, deportivo 70; `S.coches[k].gas`): se llena con las garrafas al precio del litro (`repostar`), los viajes gastan de él (`gasta_deposito`) y solo se paga en el surtidor lo que falte (`pago_gasolina`); con el depósito vacío, como antes.
- El maletero en vitrina, con forma de maletero (`rects_almacen`, tipo `mal`, en `setas.gd`): el vehículo visto por detrás con el portón abierto, amortiguadores, pilotos, junta, moqueta, umbral, parachoques y matrícula sin letras, del color de cada vehículo (`MAL_COLOR`); en la moto, el baúl con su piloto.
- Prueba `tests/garaje.gd` (72 comprobaciones; con `--salida`, capturas del garaje y de los maleteros); `vehiculos.gd`, `volante.gd` y `concesionario.gd` entran por el garaje.

### 0.64.0 (código 84)
- El AAB de Play (con la demo) y el APK universal (`descargas/LandraceHunters.apk`, sin el bloqueo) con nada encima de nada, la sala de KAIA por fases y la copa que no toca el foco.

### 0.63.0 (código 83) y plugin de WordPress 1.6.3
- El AAB de Play (con la demo) y el APK universal (`descargas/LandraceHunters.apk`, sin el bloqueo) con Bilbao por dentro, los pueblos con su sitio, las salidas por su lado, el seto nuevo y la tierra con atrezo; la senda de tierra bajo el portal de casa, fija en `tools/pueblos.py` (`FIJOS`). AAB 82 MB firmado; APK 89 MB (con `tools/apk-instalar.py`, firma v2/v3 con la upload key, versión 83/0.63.0).
- `descargas/landrace-hunters-1.6.3.zip` (29 MB) y el ligero de 28 KB con la 0.63.0.

### 0.62.0 (código 82) y plugin de WordPress 1.6.2
- El AAB de Play (con la demo) y el APK universal (`descargas/LandraceHunters.apk`, sin el bloqueo) con el garaje por dentro. AAB 82 MB firmado; APK 89 MB (con `tools/apk-instalar.py`, firma v2/v3 con la upload key, versión 82/0.62.0).
- El turno del rival del billar, fluido pero no un flash (lo pidió el usuario): «Estudia la mesa…» se ve como poco 600 ms (`B8_PIENSA` en `venta.gd`) aunque el móvil piense antes; el tope de lo que piensa por tiro en `billar8.gd` y `billar8_ia.gd`, de 400 a 700 ms (el aviso lo tapa).
- `descargas/landrace-hunters-1.6.2.zip` (29 MB) y el ligero de 28 KB con la 0.62.0.

### 0.61.0 (código 81) y plugin de WordPress 1.6.1
- El AAB de Play (con la demo), el APK universal (`descargas/LandraceHunters.apk`, sin el bloqueo) y `descargas/landrace-hunters-1.6.1.zip` (y el ligero de 28 KB), con el rival del billar de verdad y las bolas con sprite y apuestas grandes. AAB 82 MB firmado; APK 89 MB (con `tools/apk-instalar.py`, firma v2/v3 con la upload key, versión 81/0.61.0); zip 29 MB.

### El rival del billar, un jugador de verdad (lo pidió el usuario: «Tiene que ser un jugador realista de billar»)
- Con `Datos.CAL`, el rival de la bola 8 (`src/billar8.gd`) mira cada bola suya con cada tronera y calcula la probabilidad de meterla con su pulso: el corte, lo que anda la blanca, lo que anda la tocada y lo ancha que le queda la boca desde donde está (`boca_desde`, `tiros`, con la función de error `erf`); apunta al centro de lo que entra y afina la bola fantasma con la física de la mesa (`afina`).
- Juega la posición: de los tiros más fáciles prueba la fuerza justa, algo más y fuerte, y se queda con el que mejor le deja la siguiente y menos le deja al otro si falla (`prueba`, `deja`, `mejor_p`).
- Si no hay tiro claro, defiende: toca una suya flojo (lo justo para llegar) y esconde la blanca; cuanto más sabe, antes lo ve. Tapado, sale por banda con el ángulo que da la banda de verdad (`bandas`). Al sacar, de lleno a la del vértice con todo; con bola en mano, la pone donde le queda el tiro más fácil (`coloca_ia(V, q, hab)`).
- Falla como una persona: el pulso (`pulso_ang`, `pulso_f`, según `BILLAR.hab`) pesa más de lejos y en los cortes finos; con más pulso, mete más y gana más. Canta el tiro: «La 3, a la esquina.», «Esta, a defender.», «La 11, por banda.».
- La física, más fina: el choque entre bolas se resuelve en el instante exacto del contacto dentro del paso (antes el corte dependía de cuánto se solapaban en el paso, hasta 4°), para el rival y para ti.
- Prueba `tests/billar8_ia.gd` (12 partidas de .55 contra .30 y la blanca tapada): antes el de .55 metía el 36 % y no defendía nunca; ahora mete el 61 %, gana 10 de 12, defiende, sale por banda (18 de 21 tocan la suya), saca metiendo y con bola en mano se deja tiros de p 0,82; ninguno se pasa de 400 ms por tiro.

### Las bolas con sprite y apuestas grandes (lo pidió el usuario: «Las bolas también tienen que tener sprites, cuando se mueven y demás / Molaría que se puedan apostar cantidades más grandes o incluso semillas o objetos para cultivar especiales»)

- Las bolas, a mano (`tools/sprites/a-mano/bolas.py` → `godot/arte/billar_bolas.png` + `.json`): cada una pintada como una esfera con la luz de arriba a la izquierda, en 3 tonos por material, con la franja de las rayadas y el círculo del número. Ruedan en 8 direcciones × 8 fases (una vuelta cada 2πR de camino: `rod` y `dir` por bola en `paso`, `celda_bola`), llevan su sombra en el paño (`_sombra`) y, al entrar en la tronera, caen hacia su centro en 3 fotogramas cada vez más pequeños y oscuros (`V.caen`, `CAE_MS`, `celda_caida`). La fila de debajo, también con sprites. `pinta.gd` acepta la celda de origen como sexto campo de `["@", …]`.
- Apuestas (con CAL y sin PLAY, `BILLAR.cal` en `datos.json`): «Dinero», de 10 € a 1.000 € hasta el tope de cada club (Valdehierro y la asociación 250 €, Puerto Viejo y KAIA 500 €, Ibarbide y el Ensanche 1.000 €), o «Su premio»: el rival pone 3 semillas de una variedad de receta (White Widow, Haze, Northern Lights, AK-47…; ni la meta ni las de la Copa) o una garrafa de 5 L de abono MEATZA u ORTUA BIO, según el día y el club (`billar_premio`, por `Datos.hash_str`), y tú pones lo mismo en dinero o 5 semillas de un lote tuyo (`billar_apuesta`). Su premio se gana una vez al día (`Db.premio`); si pierdes las semillas, el lote baja y, a 0, desaparece.
- Prueba `tests/billar8.gd` (118 comprobaciones): el atlas, las 8 fases y 8 direcciones, el rodar en `paso`, la caída en 3 fotogramas, las sombras, los topes por club, el premio del día, perder las semillas y ganar el premio; captura `billar8-rueda.png` con `--pintar`.

### El billar a la bola 8 de verdad (lo pidió el usuario: «Hay que mejorar el minijuego de billar para que sea estilo 8 ball pool»)
- Con `Datos.CAL`, la partida del billarista de cada club se juega en una mesa vista desde arriba (`src/billar8.gd`, `MESA8`, `billar8` en `venta.gd`): 15 bolas en triángulo y la blanca, choques entre bolas con impulso, bandas con rebote, roce del paño y seis troneras, a 240 pasos por segundo.
- Apuntas con las flechas (izquierda y derecha giran y aceleran; arriba y abajo afinan) con la línea de tiro, la bola fantasma y hacia dónde salen la bola tocada y la blanca; la fuerza, con A apretado (sube y baja en la barra de la izquierda, y el taco se echa atrás); al soltar, tiras; B para dejarlo (la pierdes).
- Reglas de la bola 8: sacas tú desde la cabecera; mesa abierta hasta la primera que metas tras el saque (lisas o rayadas); faltas (se cuela la blanca, no toca ninguna, toca primero una que no es tuya) con bola en mano para el otro; la negra al sacar vuelve al pie; la negra antes de tiempo o con falta pierde; con las tuyas dentro, gana. Las bolas metidas de cada uno, debajo de la mesa.
- El rival tira con la misma física: busca tiros directos a tronera, los prueba en una copia de la mesa y tira con el pulso de `BILLAR.hab` (Ander, Izaskun, Txetxu, Olatz, Koldo); con bola en mano, se la deja detrás de la más fácil.
- Las apuestas (o «Una partida» con `Datos.PLAY`), la partida al día, la confianza y lo que se paga, como antes; a los `2 × BILLAR.turnos` tiros se hace tarde y gana a quien le quedan menos bolas suyas (`al_tope`; tablas solo con la mesa abierta o empate). Sin CAL, el billar de barras de la 1.35.
- La mesa y el taco de PixelLab (lo pidió el usuario: «Hazlo con sprites de PixelLab mejor»): `tools/sprites/pixellab_billar.py` monta la mesa de madera con cantoneras de latón, rombos y troneras a la medida del tapete (168 × 84 y 11 px de banda) y gira el taco en 64 ángulos con su punta apuntada (`arte/billar.png` + `billar.json`, `B8.carga`); las bolas, por código (5 px). Sin el atlas, la mesa de rectángulos.
- Tras la revisión: el saque abre el triángulo y mete alguna (los choques en varias vueltas por paso, `CHOQUES`; el saque, `SAQUE` × la fuerza; roce 80 px/s²), la tronera se mira donde la bola cruza la banda (lo que cae no depende de la velocidad), el rival busca tiros que aguanten su pulso, da de lleno cuando no tiene tiro y la fuerza sale del roce, piensa con «Estudia la mesa…» ya en pantalla, y los textos de falta dicen de quién es y por qué se pierde con la negra.
- Prueba `tests/billar8.gd` (el triángulo, el saque determinista y lo que mete, troneras a toda velocidad, faltas, la negra, al tope, el rival, el dibujo con los sprites, los mandos de verdad y la partida desde el billarista; con `--pintar`, las capturas).

### Repaso de coherencia con la partida del usuario (día 200, cap. 8) y el almacén del club por su puerta (lo pidió el usuario: «Deberíamos de crear una puerta para acceder al almacén del dispensario y que sea más visual, en cambio el dispensario es un menu como el de la caja de casa solo que son vitrinas»)
- Con `Datos.CAL`, los muebles que no decían nada responden (`OBJ_MUDO` en `mundo.gd`, por «mapa:objeto»): plantas de decoración, carteles, mesas del bar, la barra de GAUA, el piso franco, el noray de La Punta, la nave, el pasillo y el bajo; los barcos del muelle dicen que se cargan desde su noray.
- El encargado de KAIA (`club_muelle`) habla como los de los demás clubs; el póster del dormitorio ya no abre el PC gaming: deja cambiar el dibujo.
- La asociación y KAIA tienen una puerta en la pared del fondo (3, 1) al almacén del club (`alm-rv`, `alm-muelle`, 8 × 5 en `PUERTAS_INT` con `llave`): cerrada si no eres presidente; dentro, cuatro estanterías (`almC-0/1/2` por lo que hay), la mesa de pesar y cajas de tarros. «El almacén» sale del panel de Delroy cuando ya hay puerta.
- El dispensario se ve como la caja de casa, pero en vitrina (`vista_disp`, tipo `disp` de la vista de almacén en `setas.gd`): cristal con su luz, balda y zócalo de madera, el lote en tarros de `ALM.tarro` (los extractos, en botes), el elegido en grande con su THC y su precio; A gestiona (el menú de siempre), B cierra. En la asociación, KAIA y los clubs de Hiriburu. El lote de la asociación guarda su THC.
- Prueba nueva `tests/repaso.gd` (87/0; con `--pintar`, el club, el almacén y la vitrina).

### Plugin de WordPress 1.6.0: el ligero (lo pidió el usuario: la subida de 30 MB daba «413 Request Entity Too Large» de nginx)
- `descargas/landrace-hunters-1.6.0-ligero.zip` (28 KB): el plugin sin el motor web ni el `index.pck`. Con un botón («Descargar el juego», en el aviso del escritorio y en Ajustes → Landrace Hunters) el servidor baja `landrace-hunters-1.6.0.zip` de GitHub y copia sus piezas a `game/` (`fetch_game`, `game_ready`, `FULL_URL`, `PIEZAS`; con `ZipArchive` y por flujos); sin ellas, la dirección del juego dice que falta descargarlo. `tools/wordpress.js` saca los dos zips y borra la copia del proyecto (1,5 GB) al acabar. Probado con un WordPress simulado: la descarga deja `game/` igual que el zip completo.

### 0.60.0 (código 80) y plugin de WordPress 1.5.9
- El AAB de Play (con la demo), el APK universal (`descargas/LandraceHunters.apk`, sin el bloqueo) y `descargas/landrace-hunters-1.5.9.zip`, con un dispensario en cada club, Bilbao como zonas nuevas, las vallas por piezas, la nave por salas y el viaje de PixelLab. AAB 82 MB firmado; APK 89 MB (con `tools/apk-instalar.py`, firma v2/v3 con la upload key, versión 80/0.60.0); zip 29 MB. La partida de copia de seguridad del día 200 (cap. 8) se importa, migra y guarda en la 0.60.0.

### Un dispensario en cada club (lo pidió el usuario: «El club … que hay en Hiribide … no tienen ni dispensario, esos son errores bastante grandes … eso pasa en varios clubs, molaría que fuese más coherente todo»)
- Con `Datos.CAL`, la vitrina de todos los clubs (los cinco de la comarca, la asociación y KAIA) es el dispensario: A en ella habla con el encargado de detrás (antes, solo un texto).
- La asociación siendo presidente: el encargado abre tu panel (el dispensario y el almacén) y ya no te compra a ti como a un cliente.
- Club Zenit y Club Ilargi de Hiriburu, con su dispensario: vitrina, tarros, pizarra y cartel de normas, y su encargada (NAIARA y ENEKO, `METRO.disp`); siendo tuyos, lo llenas tú (25/50/100/250 g, al precio de club × 1,6) y los socios retiran 30 g al día, que van a la cuenta con la noche; SMS al acabarse.
- El dispensario de KAIA y los de Hiriburu, con las mismas funciones (`disp_llena`, `disp_dia`, `disp_gestiona` en `eventos.gd`).
- GAUA es la discoteca del Ensanche: sin dispensario, como un local de copas.
- Prueba nueva `tests/clubs.gd` (81/0; con el código de antes, error en el dispensario VIP); textos en inglés en `partes/copa.csv`.

### Bilbao, zonas nuevas (lo pidió el usuario: «Los mapas del juego hazlos los más parecidos y realistas a Bilbao centro y sus barrios, Zorroza no puede faltar», y después «Añade como zonas nuevas / No quiero caos», «el mobiliario urbano, la distribución en el suelo de alcantarillas y demás» y «Fuck metro»)
- Los seis mapas de siempre vuelven a ser los de antes; Bilbao entra con `Datos.CAL` como cuatro zonas nuevas en fila por la calle: **Zorroza** (la parada «Bilbao» del autobús, desde el cap. 2: torres, plaza con fuente, la estación, la vía doble con su paso a nivel, el parque y la ría), **La Punta** (naves, la explanada y el muelle con norays y dos grúas), **Abando** (las casas del Ensanche, la calle con plátanos y la plaza con fuente; sin boca de metro) y el **Casco Viejo** (teatro, plaza, mercado, catedral y la Ribera).
- Sin caos: las casillas sin detalles al azar y el mobiliario a ritmo fijo (farolas enfrentadas cada 8, banco con su papelera cada 16, plátanos cada 8, contenedores cada 16 en la acera de abajo, bolardos a los lados de cada paso de cebra) y lo del suelo como calcomanías (`BILBAO.DEC` → `m.dec`, `_arte_dec` en `pinta.gd`): imbornales en los dos cantos de la calzada cada 8, tapas de alcantarilla cada 16 y la cebra.
- `tools/bilbao.py` → `BILBAO` (mapas, `DEC`, farolas, clientes y ronda solo donde se llega, parada, zonas, patrullas, km); `Datos._aplica_auto` lo mete con CAL y lo quita sin él; `mapas_bilbao` en `campo.gd`; clientes, desmayo, croquis y viaje para las cuatro. Arte a mano en `tools/sprites/a-mano/bilbao.py` (papelera, bolardo, contenedores, tapa, imbornales y cebra).
- Zorroza con sus dos trenes y el bus (lo dijo el usuario: «en Zorroza no hay [metro]. Hay tren renfe y feve. Y bus»): la vía doble de ancho ibérico con el andén de la estación y, más abajo, junto a la ría, la vía única de ancho métrico (`viaE`, `viaEX` en el paso a nivel: los carriles más juntos) con su andén; el bus, en la parada de la calle. Sin marcas ni rótulos.
- Prueba `tests/bilbao.gd` (344/0: los seis de siempre intactos, parada y tablas, salidas de ida y vuelta, todo alcanzable, ritmo del mobiliario y del suelo, nada bajo un objeto, sin CAL nada de Bilbao).

### El paso subterráneo de Zorroza y las vallas encima de lo que acotan (lo pidió el usuario: «los pasos a nivel para pasar encima de las vías tienen que estar… O escaleras, que bajes unas escaleras y aparezcas en las del otro lado, sin cambiar el mapa. Mejor que lo del ascensor. Me gusta más. Porque además en la estación de tren de Zorroza el ascensor no funciona» y «las vallas… deberían estar encima de las baldosas de tierra… en todos los lugares donde se pongan vallas»)
- Con `Datos.CAL`, las vías no se cruzan andando (`via_cerrada` en `tile_solid` y `pisable`) y Zorroza ya no tiene pasos a nivel: tres bocas de escalera de 2 casillas (`escZ`/`escZ2`; `ESC_Z` en `tools/bilbao.py` → `m.escaleras`) en el andén de la vía ancha, en el de la estrecha (sin mobiliario, que es de una casilla) y en el paseo de la ría, y al lado el ascensor de la estación, averiado (`ascensorZ`: luz roja y cinta cruzada, «no funciona. Por la escalera»).
- Andando a la derecha hacia una boca: a qué lado sales (las otras dos o «Nada»), bajas peldaño a peldaño hundiéndote hasta perderte (`bajar_escalera`, `_escalon`, `ESC.h`; `_pj` te corta por abajo y sin sombra), fundido y, sin cambiar de mapa, subes por la otra boca mirando a la izquierda hasta su entrada. `andable` enlaza las bocas; los clientes y la ronda, solo a este lado de las vías.
- Las vallas de madera que cierran tierra o hierba alta (`VALLA_CERCA`), encima de su último cuadro y no en el de fuera (`vallas_dentro` en `mundo.gd`, desde `enter_map`; reversible sin CAL, `_val0`): corrales y cercados de Valdehierro, Mendialde, Errotabarri y Astilleros; las sueltas, donde estaban.
- Arte a mano en `tools/sprites/a-mano/bilbao.py` (`escalera`, `ascensor`). Pruebas: `tests/escaleras.gd` nueva (23/0; con `--pintar`, la bajada y la subida fotograma a fotograma), `tests/vallas.gd` (596/0), `tests/bilbao.gd` (330/0) y `tests/ciclo.gd` (las zonas de Bilbao llevan la música del barrio al que se parecen).

### Las vallas, en x y en y (lo pidió el usuario: «Las vallas tienen que ser tanto en dirección izquierda y derecha como alante a atrás, como x, y, porque si no no conectan entre ellas cuando se cambia la dirección»)
- Con `Datos.CAL`, la valla de madera (`fence`) y la barandilla de la ría (`baranda`) salen con la pieza de sus vecinas de la misma clase (N, E, S, O: 16 piezas cada una, `mascara_valla` y `VALLAS` en `pinta.gd`): de lado, el sprite aprobado; de delante a atrás, la valla vista a lo largo con su poste; esquinas, T y cruces, juntando las dos. Arte a mano en `tools/sprites/a-mano/vallas.py` (asset `vallas`). Sin CAL, el sprite de siempre.
- Prueba nueva `tests/vallas.gd` (571/0: las 32 piezas tocan el borde de cada lado que conecta, en todos los mapas cada valla con su pieza y las de arriba y abajo se tocan; vallas en vertical en Astilleros, Valdehierro, Mendialde y Errotabarri).

### La nave por salas (lo pidió el usuario: «las estanterías de curado están en medio de la nave… que la otra puerta sea verdaderamente el secadero y la zona de curado»)
- Con `Datos.CAL`, la nave queda para el cultivo: el secadero y las estanterías de tarros de 10 L pasan a su sala, `nave-s`, que es el mapa del camarote del piso (lo pidió el usuario: «para lo mismo, utiliza el mismo mapa»): 10 × 6 con el suelo y las paredes de la nave, las estanterías donde las del camarote con su baldosa de hueco, el secadero donde el deshumidificador, la caja donde la caja y la entrada por abajo, en la alfombrilla de (4, 5), donde la trampilla; por la puerta 14 de la nave («La puerta del secadero»), que antes daba a la habitación; `montar_secadero` en `mundo.gd` pone el secadero en `CURADO_NAVE.secadero` (9, 2) y las estanterías en `CURADO_NAVE.sitio` ((1, 2), (3, 2), (5, 2) y (7, 2)) (`CURADO_NAVE.mapa`), también las de la ampliación; A en ellos, como antes (`venta.gd`).
- La habitación se entra desde el despacho, por una puerta nueva en (7, 1) (`PUERTAS_INT["nave-d"]`); la caja del despacho, a (0, 2) para dejarle el paso, y en el de lujo la caja fuerte en (0, 2) y la kentia en (0, 4) (`DESPACHO.o`/`quita`). La pared de monitores, dentro de la pared y no por encima de su canto (lo pidió el usuario: «la tele está encima de la pared»; `MON_DY` en `despacho.py`).
- Sin CAL, la nave de siempre con el secadero en (6, 2). Prueba nueva `tests/nave_salas.gd` (31/0: la nave libre, la sala con el mapa del camarote pieza a pieza, los monitores sin nada sobre la pared, la sala con secadero y estanterías, 4 con la ampliación, A en los dos, puertas, accesos de `nave-s`, `nave-d` y `nave-h`); al día `despacho.gd` (78/0) y `sotano.gd` (102/0).

### El autobús y el cielo de PixelLab (lo pidió el usuario: «el sprite del bus, más del estilo del juego, muebles con PixelLab, como también el fondo del cielo»)
- El autobús del viaje, la carga y el título, de PixelLab Pro (de la base de `viaje.py`, el candidato con la puerta de cristal y el conductor): recortado a 149 × 37 y 28 colores en `tools/sprites/pixellab-viaje/bus.png`, con los pasos de rueda en sombra; `autobus()` de `viaje.py` sienta a los pasajeros y al protagonista en las ventanas (`BUS_VENT`); ruedas de 14 (`rueda-14-*`) en (26, 37) y (118, 37), suelo 44.
- El cielo: el degradado en 6 tonos tramados con Bayer 4 × 4 (`cielo_img`, cacheado por ancho y luz; `CIELO_TONOS`, `BAYER`), cuatro nubes, el sol y la luna de PixelLab (`nube-0..3`, `sol`, `luna` en `viaje.png`) en vez de los rectángulos; las nubes van a la deriva (`NUBES`, `corre` en `_cielo`) y se tiñen por la luz (`NUBE_TINTE`); al atardecer, el sol bajo y anaranjado. Lo usan el viaje, la carga y el título.
- El autobús, el 2.º de los cuatro candidatos de PixelLab (lo eligió el usuario: «la 2»): el del aire acondicionado y la puerta con flechas, 148 × 41, ruedas en (26, 40) y (110, 40), suelo 47 (`BUS_VENT`, `BUS_Y`).
- Los pueblos de detrás con el arte del juego (lo pidió el usuario: «los pueblos que se ven al iniciar el juego, que se parezcan más al juego»): `medio()` de `viaje.py` monta, sobre un prado con el seto corrido, las fachadas (caserío, borda, caserío 3 y caserío 2) y los árboles y el manzano del atlas de Godot (`PUEBLO`, `del_atlas`), 704 × 108; en `CAPAS`, a y 40 con el pie de las casas detrás del quitamiedos.
- Pueblos distintos y casas más pequeñas cuanto más lejos (lo pidió el usuario: «que no todos los pueblos sean iguales y que, por lo alejadas que estén las casas de la carretera, se vean más o menos pequeñas»): cinco pueblos en `PUEBLOS` de `viaje.py` (rural de caseríos y bordas, costa de marineras, industria de naves y fundición, barrio y ciudad), cada uno en dos capas: `pueblo-<tipo>` junto a la carretera, a su tamaño y más espaciado, y `lejos-<tipo>`, a la mitad (`mitad`: cada 2 × 2, su color más repetido y el contorno primero), más arriba, con neblina y su prado; en `CAPAS`, `lejos` a y 56 con parallax 0,22 entre el monte y el pueblo. El pueblo sale por el destino (`PUEBLO_DE`, `pueblo(V)`, `VIAJE_V.k`) o, si no se conoce, por el trayecto, que también da dónde empieza. Prueba `tests/viaje.gd` (147: tamaños, lo de lejos ≤ 60 % de alto, pueblos distintos, cada parada con el suyo; `pueblo-<parada>.png` con `--pintar`).
- El texto del viaje, siempre legible (lo pidió el usuario: «mientras no se tape el texto»): el trayecto y los minutos con contorno oscuro por los ocho lados (`_texto`, `TEXTO_BORDE`), no solo la sombra abajo a la derecha; se lee encima de cualquier tejado o fachada. Prueba en `tests/viaje.gd` (148; con el de antes, 575 px al aire).
- La fundición del viaje, entera (lo preguntó el usuario: «del edificio fundición falta un cacho de techo»): el sprite del atlas acaba a mitad de tejado; `remata` de `viaje.py` le sigue la chapa 6 filas con su cumbrera oscura y, para que resalte (lo pidió el usuario: «que resalte por encima del tejado»), la chimenea sube 16 px por encima, perfilada contra el cielo y con su corona de hormigón más ancha que el fuste (`REMATE` = 22, `CUMBRE`, `CORONA`; el atlas sin tocar), también la de lejos; las capas de los pueblos, 22 y 8 px más altas (`CERCA_H` 130, `LEJOS_H` 88; `pueblo` a y 18 y `lejos` a y 48 en `CAPAS`, con el pie donde estaba). Prueba en `tests/viaje.gd` (151: la cumbrera, la chimenea ≥ 14 px por encima y la corona en `pueblo-industria`).
- Prueba: `tests/viaje.gd` (124/0): cada rueda en su paso, el protagonista en la ventana, el pueblo, las piezas del cielo y los 6 tonos tramados de arriba abajo.

### 0.59.0 (código 79) y plugin de WordPress 1.5.8
- El AAB de Play (con la marca `tienda`: la demo), el APK universal (`descargas/LandraceHunters.apk`, sin el bloqueo) y `descargas/landrace-hunters-1.5.8.zip` (sin el bloqueo), con el colocón en el combate y los combates más llevaderos. AAB 82 MB firmado; APK 88 MB (con `tools/apk-instalar.py`, firma v2/v3 con la upload key); zip 29 MB, probado en Chromium (aviso de edad y título). La marca `tienda` solo en el `project.binary` del AAB.

### El APK y WordPress, como Play pero sin el bloqueo (lo pidió el usuario)
- El bloqueo de la demo (el corte del capítulo 4 y la compra única) solo en el AAB de Google Play: `Retencion.DEMO` sale de la marca de exportación `tienda`. `tools/godot-aab.js` exporta dos veces: el AAB de Play con la marca y otro sin ella del que sale el APK universal. WordPress se exporta sin la marca. Los tres, con el mismo contenido (`Datos.PLAY`). Prueba `tests/retencion.gd` (47/0).

### El colocón se nota en el combate y combates más llevaderos (lo pidió el usuario)
- Colocado de índica, los golpes duelen un 25 % menos pero aciertas, esquivas y huyes peor; de sativa, aciertas, esquivas y huyes mejor; borracho, aciertas y esquivas peor (`FISIO.comb`, `mod_comb`). Un aviso al empezar la pelea y el ojo, el humo y la borrachera también en la pantalla del combate.
- Ladrones y rivales con un 20 % menos de vida y de golpe (`COMBATE7.facil`): en el capítulo 8, sin subir de nivel y a puñetazos, se ganan unas 42 de 60 peleas (antes, unas 13). Prueba `tests/combate_colocon.gd`; `colocon.gd` y `estados.gd` al día.

### Plugin de WordPress 1.5.7
- `landrace-hunters` 1.5.7 con el Godot 0.58.0 (`node tools/wordpress.js` → `descargas/landrace-hunters-1.5.7.zip`, 30 MB): probado en Chromium, carga el aviso de edad y el título.

### Fase 1 · plataforma
- **Godot 4.7** (antes 4.3): el proyecto, las pruebas y la exportación; `.uid` de los scripts en el repo. Arreglos por el cambio de versión: `prueba.gd` compara los números por su valor (4.4+ escribe `1.0` donde 4.3 escribía `1`) y `paginas()` de `ui.gd` cuenta los saltos de línea y parte las líneas de más de 3.500 letras (una página de las licencias salía de 3.501).
- **AAB con la plantilla Gradle** (`tools/godot-aab.js`, `npm run godot:aab`; sustituye a `godot-apk.js`): paquete `com.landracehunters.game`, targetSdk 36, minSdk 24, arm64-v8a y armeabi-v7a, icono monocromo de Android 13, iconos por vecino más próximo dentro del AAB, firma con la upload key (variables `LH_KEYSTORE*` o `LH_ENV`, la keystore fuera del repo; se niega a usar una dentro) y comprobaciones: páginas de 16 KB (`zipalign -P 16` y `readelf` en las `.so` de 64 bits) y targetSdk 36 en el manifiesto. Saca también el APK universal con bundletool para probar en el móvil.
- **Música e iconos versionados** (`godot/musica/`, `godot/icono/`): ya no hace falta regenerarlos para exportar.
- **Batería entera** en `tools/tests.sh` (`npm run test:godot`), con las banderas de cada prueba (`mandos_geo` a 2600 × 1700 y `--sin-arranque`, `pantallas` con sus referencias, `ciclo` con `--fixed-fps 60`). Línea base en `.modo-absoluto/base.txt`.

### Fase 2 · identidad y cumplimiento
- **`Datos.PLAY`** (por defecto `true`, la versión de la tienda): los cambios de contenido van detrás de esta constante; con `false`, el juego entero de antes (lo usan todas las pruebas contra el HTML y las de la versión entera). `datos/play.json` (lo escribe `tools/play.py`) dice qué cambia: `Datos.carga` lo aplica en su sitio (las mismas listas y diccionarios, solo los textos) y lo deshace al volver a `false`; `Datos.tp()` hace lo mismo con los textos del código en los diálogos, menús y avisos.
- **Sin cifras reales de cultivo** (C1/C2): ni °C, ni micras, ni µm, ni pH en lo que se ve. El pH pasa a «corrector», «riego» o «acidez»; las extracciones, el foro, los consejos de Kiko y la pizarra, con textos de juego; en la ficha de las plantas, «riego a ojo / a medias / bien» en vez de la EC y el pH.
- **Los híbridos con nombre propio** (C5): 54 cruces con nombre de marca o de persona pasan a nombres inventados (Ría Uno, Ondarra, Ipar, Leyenda, Escarcha…), también dentro de los textos; las landraces, igual.
- **Sin el bajo de las setas** (C3): ni Txomin, ni su SMS, ni la línea del mapa, ni el cartel; la puerta gris queda cerrada y el sótano no sale en la tienda online.
- **El billar, sin apuestas** (C4): «Una partida» o «Nada», sin euros.
- **Fuera los restos de otro juego** (C6): `pk-*` → `mo-*`, `exterior-pk` → `exterior-mosaico`, `PK_TILE` → `MOSAICO_TILE` (en el código, el atlas, el arte y los documentos), y con PLAY la cortinilla del combate en persiana de lamas verticales.
- **El aviso de edad nuevo** (C7) y **la copia de seguridad de Android** (U8, `user_data_backup/allow=true`); el texto de PRIVACIDAD del juego lo dice.
- **`store/`**: política de privacidad (es + en), formulario de seguridad de los datos, cuestionario IARC, fichas en español e inglés (`tools/ficha.py` las mide), icono de 512, gráfico destacado de 1024 × 500 y 8 capturas de 1920 × 1080 sacadas del juego con PLAY (`tests/capturas.gd`).
- Prueba nueva `tests/play.gd` (27): ningún texto de los datos ni del código con cifras reales, los nombres nuevos y ninguno viejo, ida y vuelta de PLAY, sin setas, el billar, el aviso y la copia de seguridad.

### Fase 3 · bugs E1–E14
- **Guardado seguro** (E1, E2): `escribe_partida` escribe el `.tmp`, comprueba el error de escritura y lo vuelve a leer antes de cambiarlo por la partida; la de antes pasa a `.bak`. `load_save` prueba la partida y, si está rota, cortada o no pasa `partida_valida`, la `.bak`.
- **La casilla al cargar** (E3): `casilla_libre` busca por BFS la casilla libre más cercana dentro del mapa y que se llegue andando desde una salida (nunca la salida misma); si la guardada está libre, se queda.
- **Sin guardar a medias** (E4–E6): `guarda_al_salir` (al pausar o cerrar la app) no guarda con un guion en marcha (`lock > 0`) ni fuera del mapa o la carpa (el combate); la redada y el plazo vencido (con el embargo, `embargo_aplica`) cambian `S` antes del primer aviso, así que cerrar a mitad no los repite ni los pierde.
- **Los avisos de la cola se guardan** (E7): `queue(k, fn, av)` guarda el texto de cada aviso (`_cola` en la partida, `cola_guardar`/`cola_cargar`); los que se calculan (plazo, calor, historia, misión, logro, itinerario) se vuelven a encolar por su nombre.
- **Importar** (E8–E10): `partida_valida` mira el tipo de cada clave de `new_state()` y los rangos de `day`, `min` y `ch`; la caja de texto es de varias líneas con PEGAR (el portapapeles solo al tocarlo), con tope de 1 MB (`IMPORTA_MAX`); importada en partida, se abre al cerrar los menús (`relanza`, `relanzar`), como CONTINUAR (con `Datos.CAL`; sin él, en caliente como en la 1.22, para la historia contra el HTML).
- **START cierra el móvil** (E11), **los céntimos no se pierden** al pagar la luz (E12), **`pop(fn)` quita su manejador** y no el de arriba (E13, `type_text`) y **fuera «en este navegador»** (E14).
- START (la pausa) guarda antes de abrir el menú.
- Prueba nueva `tests/bugs.gd` (29 comprobaciones: una o más por bug, que fallaban antes del arreglo).

### Fase 4 · rendimiento (R1–R15)
- **Medidas** (`tests/perf.gd`, fuera de la batería; `.modo-absoluto/perf-base.txt` → `perf-final.txt`, 1280 × 720 en Xvfb con GL por software): draw calls en la calle 407 → 112 (−72 %); con el menú START abierto, 446 → 66 y 1,00 → 0,00 redibujos por fotograma; memoria estática tras recorrer las escenas 143 → 110 MB, +0,1 % de la 1.ª a la 4.ª vuelta; escala a 720p 3,933 → 3 (entera); arranque 262 → 259 ms en escritorio.
- **R1 + R8, el atlas en hojas de GPU** (`atlas.gd`): el atlas de 1024 × 4168 sube en dos texturas de ≤ 4096 (`HOJA_MAX`, `hojas`, `hoja_y`) y cada fotograma y su espejo quedan registrados con su recuadro (`reg`, `_registra`); `Atlas.dibuja` pinta con `draw_texture_rect_region` (el espejo, con el ancho de destino negativo) en vez de una textura por fotograma. La imagen de CPU se queda: la usan los recoloreados de ropa y genética.
- **R2, pintar solo si cambia** (`juego.gd`, `lienzo_quieto`): con el fundido en negro o un menú, el lector o la importación encima del mapa o la carpa (sin minijuego, vista ni andar), el lienzo deja de redibujarse a los dos fotogramas y su `SubViewport` pasa a `UPDATE_DISABLED`.
- **R3** el juego a 60 FPS como mucho y, con `Datos.CAL`, OPCIONES → AHORRO a 30 (`aj.ahorro`); solo en la escena del juego, no en las pruebas. **R15** `hud_pon` no rehace el HUD si no ha cambiado nada (`hud_ultimo`).
- **R4** los colores de texto leídos una vez (`_css`). **R7** tope en todas las cachés (`Atlas.tx`, `Arte.cache`/`texs`, `Procedural.cache`, la del pintor): al pasar el tope se vacían y se rehacen al pedirlas.
- **R10, la música** (`sonido.gd`): los OGG se leen cuando tocan, no todos al arrancar (`hilo_vivo`: el hilo vuelve si se pide otra canción después de acabar); en memoria, solo la que suena y la que se apaga.
- **R11** a escala entera (×2 o más) siempre con `Datos.CAL` (720p → ×3, con bandas). **R12** en el móvil, la zona segura se vuelve a mirar al volver a la app y cada segundo (giros, recortes). **R13** al perder el foco en el móvil, el juego se para y se calla, y vuelve como estaba. **R14** mando: cruceta y palanca izquierda, A, B, START, BACK (= B) e Y (el móvil) (`BOTONES_JOY`, `_joy`).
- Sin hacer: **R5** (el balanceo de las plantas por shader: es un recorte por filas del sprite, no una deformación, y el lienzo ya no se redibuja con los menús), **R6** (`vista.gd` no pinta píxel a píxel: las plantas salen de `Procedural.planta34`, en caché por su clave de alto) y **R9** (el arranque entero ya está en ~0,26 s en escritorio, de ellos ~0,14 s el sonido con sus efectos; la música va en su hilo). El arranque en frío en el emulador x86_64 no se ha podido medir aquí (sin KVM).

### Fase 5 · primera hora, economía, texto y accesibilidad (U1–U5)
- **Arranque corto** (`new_game_corto` en `juego.gd`, con `Datos.PLAY` y `Juego.FTUE_CORTO`): sin el prólogo de Mendialde, Kiko pregunta el nombre y apareces en el piso delante del armario, con 3 semillas de Skunk #1, el abono, la carta en dos líneas y el SMS de Kiko; la carga dura 0,5 s (antes 3,6). Una flecha amarilla sobre el objetivo del capítulo 1 (`objetivo_xy`, `pinta.gd`). Prueba nueva `tests/ftue.gd`: de NUEVA PARTIDA a la semilla plantada, 20-29 s para una persona (≤ 90).
- **Economía simulada** (`tests/economia.gd`, `tools/economia.sh` → `docs/ECONOMIA-SIM.md`): tres jugadores (prudente, medio, torpe) con el motor de cultivo de verdad. Con `Datos.PLAY`: días de plazo `PLAZO_DIAS` 12/16/24 (antes 7/10/7), el recargo sobre lo que pedía el plazo (sin interés compuesto) y como mucho `RESCATE.tope` (50 %), el rescate de Toño al primer impago (la mitad de recargo y `RESCATE.dias` más) y el embargo como mucho una vez por capítulo (`S.emb_ch`). Resultado con 4 semillas: el medio paga los tres plazos a tiempo; el torpe, tras el rescate, se recupera y acaba la deuda sin embargos.
- **Texto** (`ui.gd`): −42 % de cajas en los capítulos 1-3 (95 → 55, contando el arranque corto; `RECORTE` en `datos.json` quita 15 líneas de relleno), A mantenida pasa el texto y las cajas solas (`RAPIDO_MS`) y START → REGISTRO enseña las últimas 80 cajas (`registro`).
- **OPCIONES de accesibilidad**: TAMAÑO DE TEXTO S/M/L (nunca por debajo de 14 sp, `fs_txt`), ZURDO (la cruceta a la derecha y A/B a la izquierda), DALTÓNICO (gota y marca de lista junto a las barras de las plantas, `Vista.DALTONICO`) y SIN DESTELLOS (sin parpadeo de las barras, del enemigo golpeado, del temblor ni del relámpago, `Vista.CALMA`).

### Fase 6 · retención y métricas (U7, U10, U11), con `Datos.PLAY`
- **Progreso offline** (`retencion.gd`: `minutos_fuera`, `crece_fuera`, `fuera_desde`): al volver o al CONTINUAR, las plantas crecen el tiempo real que estuviste fuera (`OFFLINE.min_h` minutos de juego por hora, tope `OFFLINE.tope_h` = 8 h) sin sed, plagas ni muertes; el reloj y la deuda no corren. Desde `OFFLINE.aviso` minutos, la pantalla «MIENTRAS ESTABAS FUERA» (cuántas crecieron y cuántas están listas). `S.ts` se guarda con la partida.
- **Aviso de cosecha** opcional (OPCIONES · AVISO DE COSECHA, apagado): al salir, una notificación local para cuando la primera planta esté lista (`seg_cosecha`); `POST_NOTIFICATIONS` se pide solo al activarlo.
- **Objetivos diarios** (`DIARIOS` en `datos.json`; START → OBJETIVO → DIARIOS): tres al día, rotando por la fecha, con un abono por cada uno.
- **Demo + compra única** (`COMPLETO`): los capítulos 1-3 gratis; al pagar el plazo del capítulo 3, «FIN DE LA DEMO» con «Comprar el juego completo» (`juego_completo`, no consumible) o «Más tarde» (START → JUEGO COMPLETO). Sin ventajas de pago.
- **Play Games v2**: los 27 logros (`datos/play_games.json`, 1000 puntos) y CARGAR DE LA NUBE en COPIA DE SEGURIDAD (se sube al salir).
- **Informes de errores** (OPCIONES · INFORMES DE ERRORES, opt-in): Sentry sin PII y eventos del embudo de la primera hora (`evento`: capítulos, primer riego, plantar, cosecha) solo con el consentimiento.
- **Plugin Android** propio (`tools/android-plugin`, `tools/plugin-android.sh` → `godot/addons/landrace_play/bin/landrace-play.aar`; `addons/landrace_play/export_plugin.gd` añade el AAR, Billing 7.1.1, Play Games v2 20.1.2, Sentry 7.22.6 y el APP_ID). `plataforma.gd` lo envuelve y, sin él, no hace nada.
- PRIVACIDAD, `store/privacy-policy.md`, `data-safety.md`, `iarc.md`, las fichas, `store/play-console.md` (lo que hace Eddie) y `store/logros-play-games.csv`. Prueba nueva `tests/retencion.gd` (41 comprobaciones: 0 h, 3 h y 30 h → tope; logros 27/27; compra cancelada, más tarde y hecha).

### APK de la tanda Play · Godot 0.48.0 (código 67)
- `node tools/godot-aab.js` con la upload key: `dist/landrace-hunters.aab` (79 MB, firmado) y el APK universal (176 MB: las `.so` sin comprimir por los 16 KB).
- `descargas/LandraceHunters.apk` (85 MB, para instalar a mano; GitHub no admite más de 100 MB): `tools/apk-instalar.py` pone `extractNativeLibs=true` y comprime las `.so`; después `zipalign -P 16` y `apksigner` con la upload key. Paquete `com.landracehunters.game`: hay que desinstalar antes la de `com.riberaverde.godot`.

### Fase 8 · `trama.gd` y `mundo.gd` en módulos, sin cambiar el comportamiento
- `tools/partir.py` (planes `tools/plan_trama.json` y `tools/plan_mundo.json`) parte cada script en una cadena de herencia: los miembros y las funciones static se quedan en la base; cada función va al módulo de su tramo; lo que una parte anterior llama y vive en una posterior lleva un stub en la base.
- Cadena: ui → mundo → `calle` → granja → trama → `menus` → `policia` → `movil` → `venta` → `nave` → `setas` → `eventos` → retencion → juego. Ningún archivo de `src/` pasa de 2.500 líneas (antes `trama.gd` 9.438 y `mundo.gd` 3.659; ahora el mayor, `mundo.gd`, 2.216).
- Los 89 comentarios con la versión delante (`# 1.47: …`) se quedan sin ella en el código y van, por versión, a «Notas del código por versión (fase 8)», al final de este archivo.
- historia 120 pasos y vista C con 0 diferencias; batería entera en verde.

### Fase 7 · el juego en inglés
- Los textos que se ven pasan por `T()` (frase con huecos con nombre: `{n}`, `{g}`), `K()` (literal que se traduce al enseñarlo y que el código también compara) o `I18n.v()` (lo que se pinta a mano); el castellano es la clave y sale letra a letra igual que antes (las pruebas contra el HTML no cambian). Género y plural, con una plantilla por variante; nada de frases pegadas a trozos.
- `godot/i18n/strings.csv` (clave, es, en; 4.878 filas) lo hace `python3 -I tools/i18n.py extrae` desde `godot/i18n/partes/*.csv` (es,en, por script y los datos), con las variantes de PLAY (`Datos.tp`). `tools/i18n.py cuenta` cuenta los literales visibles fuera de `T`/`K`/`v`: 0 (`# i18n-no` marca lo que no se enseña).
- OPCIONES → IDIOMA (sistema, español, inglés; por defecto el del móvil: es, eu, ca y gl en castellano, lo demás en inglés). En inglés no se pasa `Datos.tp` por el texto traducido (cambiaría «Ice» o «Critical»): `I18n.vt`. Un nombre en minúscula («la skunk #1») se busca con mayúscula.
- Prueba nueva `tests/capturas_ui.gd` (combate, START, OPCIONES, diálogo, tienda, Genoteca, mochila y móvil, en castellano y en inglés, a los ppp de un móvil): 8 pantallas, 0 textos cortados. En la batería.

### Repaso de la APK de Play (lo pidió el usuario: «hay errores… faltan iconos… los nombres de las genéticas son de risa»)
- La caja de vida del jugador en el combate ya no tapa al jugador: si A, B o START la echan a la izquierda, va debajo de la del enemigo (`capturas_ui`, con los ppp de un móvil, falla sin el arreglo).
- Los nombres de las variedades en la versión de Play, parodias de los reales (una letra o el orden): Skonk #1, Limon Haize, Supra Skonk, Bluberri, Big Bod, Norzen Lights, Jak Herrer, Whyte Widou, Saur Disel, Amnesya Haize… y en mayúsculas en los avisos (JAK HERRER, SKONK #1). `tools/play.py` → `datos/play.json`; las traducciones migradas de los nombres de antes.
- La fila Vida de la MOCHILA, con su icono (un corazón a mano en `salon.py`, `iconos-menu`). Prueba nueva `tests/iconos.gd`: cada icono que piden los menús, la tienda y el equipo está en el atlas (131, 0 fallos).
- Los botones SONIDO/MÓVIL, CALOR y VIDA del HUD y del combate, en el idioma elegido.

### APK de Play con el inglés · Godot 0.49.0 (código 68)
- `node tools/godot-aab.js` con la upload key: `dist/landrace-hunters.aab` (79 MB, firmado, targetSdk 36, 16 KB en las 4 `.so`) y el APK universal.
- `descargas/LandraceHunters.apk` (82 MB, `apk-instalar.py` + `zipalign -P 16` + `apksigner`): fases 7 y 8, el repaso de la APK de Play (combate, nombres parodia, icono de la vida) y el idioma.
- En inglés tampoco sale un nombre real: las filas de PLAY sin inglés caían en la del nombre real (Northern Lights × Haze, Durban Poison); ahora Norzen Lights × Haize, Durvan Poizon y la marca Ice-o-lator como Ais-o-lator (`play.gd` recorre `strings.csv` en inglés: 12 → 0).
- Menús a toda pantalla sin aire (lo vio el usuario en la tienda): las 5 filas eran las de la pantalla de 160 px; ahora todas las que caben, y si caben todas, la caja a su alto (`capturas_ui`: 6 huecos → 0).

### APK de la tanda del documento maestro · Godot 0.50.0 (código 69)
- `node tools/godot-aab.js` con la upload key: `dist/landrace-hunters.aab` (firmado, targetSdk 36, 16 KB) y el APK universal.
- `descargas/LandraceHunters.apk` (83 MB, `apk-instalar.py` + `zipalign -P 16` + `apksigner`, la misma firma que la 0.49.0): MAESTRO [2], [4] a [9] con `Datos.CAL`.

### Saltar el tutorial y la partida de antes · Godot 0.51.0 (código 70)
- **Saltar el tutorial** (lo pidió el usuario: «que ya hagas todo el cultivo, el primer cultivo»; con `Datos.CAL`): NUEVA PARTIDA pregunta «Jugarlo / Saltarlo»; saltado, el nombre y el personaje, y la partida empieza en el piso como tras la primera cosecha (`saltar_tutorial`: la carta, Kiko, el itinerario hasta cosechar, 41 g de Skunk #1 sin curar, una semilla y el abono) y pasa al capítulo 2 con el SMS de Kiko (`new_game_saltado`, `Juego.SALTAR`; `ciclo` y `ftue` lo apagan).
- **La partida no se pierde** (lo vio el usuario: «empieza otra vez el juego»): `load_save` arregla la guardada con una clave de otro tipo o un mapa que ya no existe (`repara_partida`: esa clave, a la de partida nueva; día, hora y capítulo, a su rango) en vez de empezar de cero, y la que no tiene arreglo se copia en `partida.rota.json` (`guarda_rota`). Importar sigue estricto (E8).
- Por qué las dos últimas APK empezaban de cero: desde la 0.48 el paquete es `com.landracehunters.game` con la upload key (antes `com.riberaverde.godot` con otra firma), así que Android la instala como otra app, con sus propios datos. Desde aquí el paquete y la firma no cambian; la partida de la app vieja se pasa con OPCIONES → COPIA DE SEGURIDAD → EXPORTAR en la vieja e IMPORTAR en la nueva.
- Prueba nueva `tests/saltar.gd` (25; con el código de antes, 13 fallos).
- `descargas/LandraceHunters.apk` (`apk-instalar.py` + `zipalign -P 16` + `apksigner`, la misma firma y el mismo paquete que la 0.50.0) y el plugin de WordPress 1.5.5 con esta versión (`tools/wordpress.js` pasa a Godot 4.7: el motor web sin hilos sale de la plantilla instalada, con `index.audio.position.worklet.js`).

### Píxeles cuadrados y cajas sin aire · Godot 0.52.0 (código 71)
- **Todos los píxeles cuadrados** (lo pidió el usuario: «tienen que ser cuadrados todos los píxeles»; con `Datos.CAL`): el mundo, siempre a un número entero de píxeles de pantalla por píxel del juego, también en una ventana pequeña o estrecha (`ajusta`); y la UI (cajas, retratos, iconos, HUD), igual: `us` redondeado a entero (antes, 3,4 o 4,43 en un móvil: el retrato de 64 salía a 283 px y sus píxeles, de 4 y 5).
- **Las cajas, del tamaño del texto** (lo pidió el usuario: «lo que ocupe el texto y un extra por cada lado, pero no más»; medido en píxeles con la captura: 6 u de margen, 4-9 u entre líneas y la caja a toda pantalla con 4 líneas): el lector (MIENTRAS ESTABAS FUERA, créditos…) del ancho de su línea más larga y del alto de sus líneas, en el centro, con 3-4 u de margen, interlineado de 11 y sin ▲▼ ni barra de scroll si cabe (a toda pantalla y con scroll si no); el aviso de arriba (ITINERARIO…) con 4 u de margen y medido con su letra de verdad (antes «tía» saltaba de línea).
- **El cumpleaños, en rejilla** (lo pidió el usuario: «más ordenado»): los meses de 3 en 3 y los días de 7 en 7 en una caja de su tamaño en el centro, con las cuatro flechas (`menu(…, {"cls": "centro", "cols": n})`), en vez de una lista a toda pantalla.
- **La UI hacia abajo** (`floorf`, no `round`): el escenario de 240 us cabe siempre entre los mandos (en un 2400 × 1080 a 420 ppp, us 3).
- **Fuera el progreso sin jugar** (lo pidió el usuario: «pierde el sentido… igual se te secan las plantas»; venía del U7 del plan): `Retencion.OFFLINE := false` apaga MIENTRAS ESTABAS FUERA, el crecimiento con la app cerrada, el aviso de cosecha y la opción AVISO DE COSECHA; `tests/retencion.gd` comprueba las dos cosas.
- Prueba nueva `tests/pixel.gd` (180, en `tools/tests.sh`): diez pantallas (seis móviles y cuatro ventanas), escala entera del mundo y de la UI, el retrato múltiplo exacto, el lector corto sin aire y centrado, el largo a toda altura, y la rejilla del cumpleaños.

### Retratos con caras y privacidad sin avisos · Godot 0.52.0 (código 71)
- **Los 26 retratos con sus caras** (lo pidió el usuario: «hazlo con los otros 26»): cada personaje, como Kiko, con su busto de PixelLab fiel al muñeco y a la historia, contorno de 1 px y 8 estados (hablando, parpadeo, contento, enfadado y dudando, dos de cada gesto) sacados de las animaciones de voz y del retoque de imagen de PixelLab (`tools/sprites/retratos/estados/`); el atlas, 27 retratos y 204 estados.
- **La cinta del nombre, sin aire arriba ni abajo** (lo pidió el usuario: «que el espacio de arriba y abajo del texto sea más pequeño que el de los lados»): 0 en vertical y 5 u a los lados; `tests/retratos.gd` lo exige (falla con la de antes).
- **Privacidad y ficha sin el aviso de cosecha**: apagado desde la 0.52 (`Retencion.OFFLINE`), el texto de PRIVACIDAD del juego, `store/privacy-policy.md` y `store/data-safety.md` ya no lo ofrecen; `tests/retencion.gd` lo comprueba (falla con el texto de antes).
- `descargas/LandraceHunters.apk` y `dist/landrace-hunters.aab` firmados con la upload key, el mismo paquete `com.landracehunters.game`.

### Lo que dijeron los que lo probaron (lo pidió el usuario), con `Datos.CAL`
- **El rastro de la chatarrería:** Bixente pregunta «¿Compras o vendes?»; con VENDERLE compra lo que te sobra en la mochila (focos, macetas y accesorios, también el CFL y la maceta de 7 L de serie) a la mitad de lo que cuesta nuevo (`RASTRO.compra` en `datos.json`; `rastro_pieza`, `vender_rastro` en `trama.gd`), sin tope, y antes pregunta «¿Seguro…? Lo vendido no se recupera». No es una casa de empeños: lo vendido, vendido (no hay puesto ni se recompra; en COMPRAR, solo la chatarra del día, también a la mitad, así que no hay trampa). Lo montado en las carpas no se vende. La primera vez que cambias un foco o una maceta, el aviso dice dónde venderlo (`pista_rastro`, `S.flags.rastroP`). Prueba `tests/rastro.gd`.
- **La gente, menos técnica:** los clientes ya no piden «una híbrida con aroma cítrico»: el pedido es solo lo fuerte que sea («Busco 5 g de algo fuerte, del 18 % de THC para arriba»), el gusto de cada uno es solo el olor («Le gusta la de olor dulce», en la agenda) y los encargos de las charlas, por THC (`pedido_de`, `gusto_de`, `ofrece_encargo`, `entrega_encargo` en `vida.gd`; los de antes, con `ef`, valen con cualquier lote). El recado del pastor pide «algo fuerte (18 % de THC o más)» en vez de una índica del 70 %. El efecto de la índica y la sativa al fumar se queda. Prueba `tests/vida.gd`.
- **La silla del ordenador:** USAR EL ORDENADOR desde la silla de la tía o la gaming te sienta primero y te quedas sentado; sentado, el ordenador está en el menú (`sent_mesa`, `menu_sentado` en `calle.gd`). Sentado al ordenador ya no se ve con los brazos colgando: los codos fuera y las manos en la mesa, a los lados de la cabeza (`SENT_MESA` en `pinta.gd`, con los colores del fotograma y la ropa; en la gaming, más baja que su mesa, los antebrazos más largos, `brazos_mesa`). En la silla de la tía, la espalda empieza detrás del respaldo: los hombros asoman por encima (`SENT_GEO.silla`, cadera de 5 a 1). Prueba `tests/escala.gd`.
- **Sin el bloqueo de la demo, por ahora:** el capítulo 4 ya no pide la compra única (`Retencion.DEMO := false`; `completo()` da el juego entero). El código se queda apagado y la prueba lo enciende; una partida que ya se quedó en la demo sigue desde START · JUEGO COMPLETO. Prueba `tests/retencion.gd`.

### El retrato de los ladrones y los agentes (lo vio el usuario: «me ha salido el sprite de un tío con sombrero cuando me han intentado atracar»)
- En la pelea de la calle, el ENCAPUCHADO, el ATRACADOR, el DESCONOCIDO, el TIRONERO y el CARTERISTA salían con la cara de un cliente al azar: su nombre no es de nadie del mapa y `retrato_de` tiraba de `rand_look`. Ahora sale el de su pelea (`B.look`), con capucha (`Retrato.grupo` pasa `ladronN` a su busto `ladronN-combate`), y los agentes del control, el del agente (antes, sin retrato). Prueba `tests/retratos.gd` (426; con el código de antes, 20 fallos de los ladrones).

### APK de lo que dijeron los que lo probaron · Godot 0.53.0 (código 72)
- Lo pidió el usuario: «mándame un apk con lo ya actualizado, sin el bloqueo de la demo». El rastro sin tope, la silla del ordenador, la gente menos técnica y el juego entero sin la compra única (`Retencion.DEMO := false`).
- `descargas/LandraceHunters.apk` y `dist/landrace-hunters.aab` firmados con la upload key, el mismo paquete `com.landracehunters.game`.

### Las decisiones, los gestos con la planta de verdad y KAIA tuyo (lo pidió el usuario), con `Datos.CAL`
- **La Copa sin pH ni EC:** «Floración a tope» dice lo mismo con un texto llano (`mision_desc`, el campo `dc` de la misión); sin CAL, el de siempre. Prueba `tests/copa_texto.gd`.
- **El pelo de la protagonista:** cambiar de pelo cambiaba también el iris (el mismo marrón que el pelo). `Atlas.con_rampa(c, mapa, id, iris)` deja el color junto al blanco del ojo o a la piel (`_junto_blanco`), y `ROPA.pelo.src["player-f"]` lleva sus dos tonos. Prueba `tests/pelo.gd`.
- **Cada gesto, con la planta tal como está** (lo vio el usuario: «cuando la riegas… sale la planta en grande»): regar, tratar, abonar, esquejar y cosechar pintan el fotograma de la vista C de esa planta, de su alto y su fase, con los colores de su variedad, los daños y seca (la muerta, en marrones; `gesto_planta`, `gesto_p` desde `granja.gd`); manicurar, estabilizar y cruzar, con los colores de su variedad (`gesto_sid`: la cola, el cogollo y las hojas de `gestos.py` pasan por `_gs_color`). Sin planta, la genérica de siempre.
- **KAIA, de verdad tuyo** (lo vio el usuario: «no actúas tú como encargado del dispensario… del diseño y de todo»): el panel del jefe (`panel_club("muelle")`) con EL DISPENSARIO, EL ALMACÉN, EL DISEÑO y ORDENAR EL LOCAL; el dispensario se gestiona (`gestiona_kaia`): lo que hay y lo que sale al día, rellenar con más del mismo lote, subir y bajar el precio (`MAR.kaia.precio`: un 10 % por paso, de ×0,7 a ×1,5; más caro salen menos y más barato más, `kaia_tiron`) y retirar lo que queda; la vitrina abre el dispensario. El diseño: marinero, de barrio, industrial, moderno o clásico, 2.500 € por transferencia, listo al día siguiente (`diseno_kaia`, `S.mar.kd`/`kdd`; `montar_club` cambia el estilo de las casillas y los muebles). ORDENAR KAIA desde el panel o una mesita (`ORDEN_P["club-muelle"]`, con su título: el mismo que el del club de la asociación confundía la prueba `orden_sala`: los tres sofás, el billar, la gramola y las dos plantas). Sin el muelle (`S.mar`), la vitrina y la mesita no son tuyas. Prueba `tests/kaia.gd` (41, con los gestos).

### APK de las decisiones, los gestos y KAIA · Godot 0.54.0 (código 73)
- Lo pidió el usuario: «Está todo hecho? Entonces manda apk» (solo el APK). Batería entera 63/63 en verde antes de compilar.
- `descargas/LandraceHunters.apk` (87,9 MB, firma v2/v3 con la upload key, el mismo paquete `com.landracehunters.game`).

### Documento maestro (`docs/MAESTRO.md`), por tandas, con `Datos.CAL`
- **[10] La letra:** reserva propia para flechas, ▲▼◀▶, ★, ≈ y −.
- **[1] El personaje:** chico o chica y el cumpleaños al empezar (`S.sexo`, `S.cumple`), sin ventajas por sexo (solo cambia el aspecto); el regalo del cumpleaños una vez al año (el 29 de febrero, también); la protagonista con su sprite de PixelLab en el mapa y en el combate (`player-f`, `player-f-combate`), con boca, y la ropa cambia las mismas piezas. Prueba `tests/personaje.gd`.
- **[3] Los vehículos:** el garaje dibujado junto al piso; se viaja desde el garaje y el coche se queda en el aparcamiento dibujado junto a la parada de cada pueblo (plaza de 2 × 1), no se conduce por el mapa; el maletero por kg (con la envasadora al vacío), cura en botes con los tarros y lleva el abono a los tanques de la nave; la grúa al depósito. Fuera del garaje no hay otro sitio que el aparcamiento; con el coche más de 3 días en el mismo pueblo, cada día te pueden multar (un 35 %, 90 €, SMS del Ayuntamiento; `CONCE.multa`, `multa_aparcado`, por hash, sin el azar). Pruebas `tests/vehiculos.gd` y `tests/concesionario.gd`.
- **[5] La genética:**
  - **Los valores ocultos:** cada línea lleva 4 (`IVS`: potencia, producción, floración y resistencia, de 1 a 31; `S.iv[sid]`) y cada planta, los suyos (`f.iv`, los de su línea ± 3). Salen por hash, sin tirar del azar. Cambian el THC y los gramos (±15 %), la floración (±15 %) y el moho (±50 %).
  - **Herencia y lectura:** las semillas suben la línea a lo mejor de la planta; el cruce, a lo mejor de los dos padres y hasta 2 más (tope 31). Solo se ven con el analizador, en la ficha de la semilla.
  - **La planta rara** (`SHINY`, 1 de cada 500): cogollos morados, albinos o dorados, a su lote `sid!` (`b.sh`), que se paga ×5. Sus semillas no salen así; sus esquejes sí.
  - **La saturación** (`SATURA`): lo vendido en la calle de cada pueblo (`S.sat`) baja el precio de esa variedad hasta la mitad con 100 g; cada día se olvida un 15 %.
  - **La hierba verde** (`VERDE`, `verde`): recién cortada vale un 35 % y está seca del todo a los 4 días; curada en tarros, un 8 % más por semana, hasta 8 semanas. `calidad(b, flor)`: lo verde y la rara, solo en los cogollos.
  - Prueba `tests/genetica.gd`.
- **[2] Borrachera y colocón** (`FISIO`, `S.borr`, `S.colo`, `S.efe`): de 0 a 100, bajan con las horas.
  - **Beber** (`BEBIDAS`, 4.º número): la caña, el vino, la cerveza y la copa suben; el café, el refresco y el zumo, no.
  - **Borracho:** de 31 a 70 el paso se tuerce y al soltar sigues una casilla (`vaiven`, `deriva`); de 70 para arriba, la pantalla en triple con los colores separados (`src/vision.gdshader`); a 100 en la calle, el desmayo: 8 horas después en la parada del pueblo, sin el 30 % del efectivo ni la mitad de los cogollos y extractos que llevabas (`desmayo`).
  - **Fumar y catar** (`colocar`): sube por los mg de THC; la sativa o la índica, por el % índica de la variedad. Sativa: andas un 15 % más rápido y la policía te ve una casilla antes. Índica: andas más despacio, levantas un 30 % menos de sospecha, las extracciones tardan un 20 % menos y el curado de la mañana cunde un 25 % más.
  - En el HUD, ALCOHOL y COLOCÓN cuando los hay (`hud_fisio`). Prueba `tests/estados.gd`.
- **[4] El mundo abierto:**
  - **El puerto al raso:** el muelle (y la comarcal) con el tiempo, el atardecer, la noche y las farolas de la calle (`_al_raso` en `pinta.gd`).
  - **La botritis** (`BOTRITIS`): en flor (del 65 %), cada día la puede coger una planta de las carpas de casa: un 8 % si llueve fuera y la carpa no está sellada, un 12 % con la humedad por encima del 80 % (un 75 % menos sellada) y menos con la resistencia de su línea. Por hash, sin el azar (`prob_botritis`, `botritis_dia`). Pierde 8 de salud al día hasta morir y, cosechada, un 40 % de los gramos (`botritis_merma`). En el growshop, el fungicida (la para), el preventivo (una semana sin ella) y el kit de sellado de la carpa, al final de la tienda. La nave, no.
  - **La carretera comarcal** (`MAPS.comarcal`, 44 × 16, desde el cap. 2): de Mendialde a Errotabarri por las salidas de lado (`montar_campo`), con un claro de landraces salvajes (`CAMPO`): en verano, para esquejes; en otoño, con semillas; en invierno, nada; con tormenta o nieve no se ven; lo recogido no vuelve en una semana. Por hash semanal.
  - **El refugio** (`MAPS.refugio`): el caserío abandonado de la comarcal, con camastro para dormir y un arcón donde esconder los cogollos (`escondite`), donde no llegan ni la redada ni los ladrones.
  - **El control de carretera** (`CONTROL`): yendo en tu vehículo, lo que pesa el maletero sube la probabilidad; al pararte, huir (40 %, 55 % en moto, 75 % en el deportivo; si te pillan, te lo quitan, 600 € de multa y calor), sobornar (200 € + 1,5 €/g; menos probable con calor; si no cuela, se queda el sobre y registran), entregar la carga (sin multa) o dejar que registren, como antes (`resolver_control`).
  - `src/campo.gd` entra en la cadena entre `eventos` y `retencion`. Prueba `tests/campo.gd` (53).
- **[6] La gestión:**
  - **KAIA como dispensario:** el club del puerto y el de la asociación comparten el panel (`panel_club`): el dispensario de siempre y el almacén del club (`almacen_club(id)`, `S.mar.al` en KAIA, que cobra a la cuenta con la licencia).
  - **La plantilla por local** (`plantilla_locales`, `cuadricula`): MÓVIL → PLANTILLA abre la lista de locales (el piso, la nave, la calle y cada negocio) y, en cada uno, su gente en filas de rol · sueldo · lealtad · eficiencia (`fila_staff`); los puestos de siempre (`STAFF.roles`).
  - **Lealtad de 1 a 10 y topos** (`STAFF`, `w.lt`): la de antes, ×2; con el sueldo bajo o el calor por encima de 70 baja en la franja de 4 a 7, con el alto sube hasta 9 y la prima, hasta 10. Cuanto menos leal, más fácil que sea un chivato (`prob_topo`, por hash al contratarle y al bajar de franja): suma 2 de calor al día y dobla el riesgo de redada en la nave; un capataz de lealtad 10 en el mismo local lo descubre y te avisa por SMS («(!)» en su fila).
  - **El sueldo** (bajo ×0,75, normal, alto ×1,25; `sueldo_w`) y **la eficiencia** (40 + 12 por labia o cuidado, según el puesto).
  - **El contable** (`contable_dia`): un trabajador lleva la caja de un negocio y cada mañana mete en ella el efectivo que cabe hasta el tope del local, por su eficiencia; cobra solo su comisión (8 %).
  - **El olor de la nave** (`OLOR_NAVE`): el carbón de los filtros se gasta (1,5 al día, ×1,5 con lluvia o niebla) y saturado huele como sin filtro (`olor_nave` multiplica la redada); se cambia desde el escritorio (EL OLOR). El ozonizador en el conducto, con el carbón bueno, quita el olor; en la sala también, pero lo que se cuelga se vende un 20 % peor (`oz`).
  - **La seguridad** (`SEGURIDAD`, `S.seg`): puerta blindada, alarma, perro y cámaras para la nave y cada negocio; cada noche, un 2 % de robo (menos con cada cosa) que se lleva lo del secadero o la caja (`robos_dia`); con cámaras se recupera la mitad y, en una redada de la nave, tu gente sale por detrás y no se pierde. Los monitores del despacho dicen lo de cada local.
  - `src/gestion.gd` entra en la cadena entre `campo` y `retencion`. Prueba `tests/gestion.gd` (55).
- **[7] La gente viva:**
  - **Gustos y arquetipo** (`GENTE7.arq`/`arqs`): cada cliente, por su id, tiene un efecto (sativa, índica o híbrida) y un aroma que le van (`gusto_de`) y una manera de ser según su tipo (estudiante, chaval de la plaza, currela, jubilado, turista, pijo) que decide si paga, cuándo y si se pelea. En MÓVIL → GENTE, junto a cada fijo. El nombre y el muñeco ya iban juntos desde la 1.43.3 (`GENERO`).
  - **La manera de hablar por zona** (`GENTE7.zonas`/`jerga`): el pueblo (Mendialde, Errotabarri, la comarcal), el centro (el barrio alto, Ibarbide, GAUA, los clubs del Ensanche y del Casco) y el barrio (lo demás), cada uno con sus saludos, síes, noes y chismes.
  - **La memoria y los encargos** (`S.mem`, `S.encargo7`, `S.charla7`): los fijos se acuerdan de la última cepa que les vendiste; con reputación 20, de una venta o de una charla sentado (una al día por persona) sale a veces un encargo para otro pueblo, más con unas copas (borrachera de 31); se entrega llamando desde la calle de ese pueblo y caduca.
  - **Fiar** (`GENTE7.fiar`, `S.fiado`, `cal_fiar`, `vida_dia`): a veces un fijo te pide fiárselo; si pagan (según su arquetipo; el jubilado, dos días tarde), al buzón con SMS y la vez siguiente un chisme y −5 de calor; si no, en GENTE → Deudas: perdonar (+2 de reputación), exigir con el 20 % (solo en la calle; a veces pelea) o amenazar (+6 de calor). «Que pague ya» es la venta de siempre.
  - **Pedidos por efecto y aroma** (`GENTE7.pedido`, `pedido_de`): un 35 % de los días el cliente pide una sativa, índica o híbrida con su aroma y un mínimo de THC; acertar paga un 25 % más y regala algo (papel, mechero, bocata o spray); fallar cuela peor y, sin pedido, lo que le va cuela mejor.
  - **Combates** (`COMBATE7`): golpes con nombre, lo que te dan, el bate (+3, aturde) y la cadena de bici (+2, sangra) en la chatarrería de Bixente; aturdido pierde su turno; el sangrado resta 2 tres turnos (tú no caes por sangrar); uno de cada cinco ladrones lleva navaja y corta.
  - **Tiendas por secciones, tipos y marcas** (`CATALOGO`, `filtra_tienda`): en las tiendas de más de 8 artículos, filas ▸ para quedarse con una sección, un tipo y una marca (inventadas, en euskera) y ◂ para volver; la marca en la ficha. El estanco con papel de arroz, boquillas y mechero de gasolina (`ESTANCO_MAS`) y las cartas del bar, el club y GAUA con más bebidas (`CARTA`). El concesionario, el mecánico y los clubs tienen pocas cosas: sin filtro.
  - Todo por `Datos.hash_str`, sin tocar el azar del oráculo. `src/vida.gd` entra en la cadena entre `gestion` y `retencion`. Prueba `tests/vida.gd` (284).
- **[8] La nave a lo grande y las caras:**
  - **El curado en la nave** (`CURADO_NAVE`, `S.nave.cur`): las estanterías de tarros de 10 L de la nave (`estanteC`) curan lo que sale del secadero como las del camarote; con A, la vista de tarros (GUARDAR) y sacar. **Ampliar el curado** (1.500 €, en las mejoras del escritorio): dos estanterías más, el doble de tarros y de nodos en la escena (`navc_est`, `navc_cap`). La redada se lo lleva (`navc_g`).
  - **El despacho de lujo** (`DESPACHO`, 25.000 €, solo con la extracción y el riego de la nave al último nivel, `_nave_tope`): tarima de roble, paredes de obra, librería, sofá de terciopelo, la pared de monitores con las cámaras de tus locales (`monD`, seis pantallas con su piloto de grabación) y la caja fuerte de alta capacidad (`cajaD`, 250.000 € y 20 kg; `S.desp`), arte a mano en `tools/sprites/a-mano/despacho.py`. La caja no va con la nave: la redada no la encuentra; al dejar la nave, lo de dentro vuelve a tus bolsillos.
  - **Los retratos** (`src/retrato.gd`, el `PortraitRect` de `ui.gd`): en los diálogos, las llamadas y los SMS, a la izquierda de la caja, el busto de 32 × 32 de quien habla, sacado de su look (pelo, piel, camisa, gafas, barba; los de chica, con pestañas) y con su cara según el tono de lo que dice (neutra, alegre, enfadada o con dudas, por palabras en castellano y en inglés); la boca se mueve mientras sale el texto. `retrato_de(nombre)` busca a la persona (NPCDEF, LOOKS, el protagonista, el cliente con quien hablas; si no, un look por hash del nombre) y no pone cara a la carta, el banco ni el móvil. Los SMS se abren como diálogo (`SMS · <quién>`).
  - Prueba `tests/despacho.gd` (78; `--pintar` saca el despacho, las estanterías y dos retratos).
- **[9] Los pisos de venta y la ciudad:**
  - **La red de pisos** (`PISOS9`, `S.pisos`, `metro.gd`): desde el primer envío por mar (`S.mar.paso >= 1` o `S.mar.exp >= 1`, que pone `cargar_envio` con el SMS de Iñaki), MÓVIL → PISOS (icono `mv-pisos` en `movil.py`): un piso por pueblo (y en la ciudad, abierta), alquilado en efectivo (el recibo cada 30 días con `cobra`; sin pagar, se pierde) o comprado con la cuenta. Al frente, un **lugarteniente** de tu plantilla (rol `lugar`, `pv`), que cada mañana (`pisos_dia`, desde `curro_dia`) vende lo que le dejas en el almacén (hasta 5 kg; el género y la caja, solo en el pueblo) según su labia, la **pureza** (pura, rebajada, muy rebajada: rinde más gramos y da más calor) y el **precio** (barata, normal, cara: vende más o menos) que le marcas, se queda un 15 % y, si es poco leal, a veces sisa. El calor del piso sube con lo vendido y lo rebajado y baja cada día; a 90, la redada: se llevan el almacén y la caja y detienen al lugarteniente.
  - **Hiriburu, la ciudad de la autopista** (`METRO`, `MAPS.metropoli` 46 × 30, `tools/maestro9.py`): se abre cuando tu patrimonio neto (efectivo, cuenta, cajas, despacho, piso franco y pisos, menos la deuda; `patrimonio`) llega a 500.000 € (SMS de Iñaki) y se va con tu vehículo desde la parada (`conducir`; 140 km y 18 € de peaje en `tramo`), con su aparcamiento (`APARC`); el autobús de la comarca no llega, solo el de línea a Ibarbide desde su parada (`parada_action`). Dos filas de manzanas, avenidas, la plaza con la fuente, cajero, patrullas, clientes que pagan un 50 % más (`ZONAS`, `PATRULLAS`, `CLIENT_TILES`, `RONDA` con CAL en `_aplica_auto`).
  - **Los clubs VIP** (Club Zenit, 180.000 €; Club Ilargi, 240.000 €; `vip-zen`, `vip-ila`): se compran en la puerta con la cuenta (`vip_puerta`, después con la llave), su encargado los lleva y lo de cada noche va a la cuenta (`vip_noche`: más con el control del barrio), con dos mejoras (reservados, +25 %; seguridad en la puerta, la mitad de riesgo de cierre).
  - **El concejal** (ZUBIRI, en la puerta del Ayuntamiento): 12.000 € al mes en efectivo y la clausura por inspección (precinto de 7 días y 15.000 € de multa, más probable con calor) baja a la cuarta parte.
  - **Las bandas** (Los del Puente y La Peña Gris, inventadas) y los cuatro barrios (`barrios`): el control de cada uno se gana peleando con su jefe (`battle("rival")` con su look, +40), pactando (20.000 €, +15) o se pierde perdiendo; las bandas empujan donde tienes algo (SMS) y te esperan al llegar (`metro_llegada`: plantarles cara, pagar o irte). Todo por `Datos.hash_str`.
  - **Tras la revisión por ataque:** dejar el piso pasa la caja al efectivo y el género a la mochila hasta donde cabe (lo demás se queda y el piso sigue tuyo); el patrimonio suma lo que tienes (`bienes`: la nave comprada, los pisos y su género, los clubs VIP, los barcos, los coches y los lotes a precio de mayor, que comprar no lo baje); ocho paseantes por la ciudad (`m9_t*`, con `wander`) y sus clientes (`spawn_clients`, letra `h`); los lugartenientes, en el local «Los pisos» (`local_staff`), sin sueldo aparte; plantarles cara sin dinero ya no deja pagar; Hiriburu con canción propia de día y de noche (`metropoli`, `metropoli_n` en `tools/musica/temas.js`); los sitios del curado de la nave, fuera de debajo del extractor.
  - Prueba `tests/metro.gd` (263).
- **[5] Lo que faltaba (CannaDex, CannaCup y potencia contratada):** `tools/maestro_copa.py` escribe `FAMILIAS`, `CUP` y `ENERGIA` en `datos.json`; `src/copa.gd` entra en la cadena entre `metro` y `retencion`.
  - **CannaDex por familias** (`FAMILIAS`, `S.cult`): diez familias (Kush, Asia, América, África, las del olor fuerte, Haze, las del norte, las blancas, la leyenda y las autos) que cubren todas las de la DEX; cada variedad cuenta al cosecharla en casa o en la nave (`cult_apunta`). Completa una y su bono es para siempre (`Cultivo.fam`): resistencia (un 25 % menos de moho y botritis), floración un 4 % más rápida, un 5 % más de gramos o un 3-4 % más de THC. GENOTECA → CANNADEX · FAMILIAS.
  - **La CannaCup por calendario** (`CUP`, desde el cap. 7): el 15 de marzo, junio, septiembre y diciembre, en la plaza de Ribera Verde con el jurado; SMS de la asociación 3 días antes y el mismo día; cada edición pide un tipo y un aroma (por hash) y se presenta un tarro curado del todo (≥ 99 %, 20 g). Los puntos: THC, más el tipo, el aroma y el afinado; tres rivales inventados. El podio da 6.000/2.500/1.000 €, prestigio (`S.prest`) y un trofeo (`S.cup`); una vez por edición; las fechas salen en el calendario del móvil.
  - **Los clubs VIP exigen prestigio**: 3 o más para que el dueño te venda (`vip_puerta`).
  - **La potencia contratada** (`ENERGIA`, `S.ener`): 5,75 kW en el piso y 15 kW en la nave; lo que se pasa (focos y extras de las carpas vivas y los aparatos de la sala; los focos de las mesas ocupadas de la nave) sube el calor 3 por kW cada día (firma térmica). Las placas solares (5.200 €, 2,5 kW, sin gasto) y el generador diésel insonorizado (2.400 €, 5 kW, gasóleo en efectivo cada día que trabaja; sin efectivo no arranca) lo cubren; se piden en la tienda online → LA INSTALACIÓN ELÉCTRICA y llegan al día siguiente.
  - Todo por `Datos.hash_str`, sin tocar el azar del oráculo. Prueba `tests/familias.gd` (258).
- **Los gestos con mano de PixelLab** (lo pidió el usuario: «la regadera y la mano flotan… la llave… molaría hacerlas con sprites creados en PixelLab»), con `Datos.CAL`:
  - **Regar:** el brazo con la regadera de PixelLab (`gs-regar`) entra con la manga pegada al canto derecho del plano y el chorro sale de la alcachofa y cae en la tierra de la maceta (antes la mano flotaba y el agua caía al lado de la planta).
  - **La llave:** la mano con la llave (`acc-llave-0`) entra por el canto derecho de la puerta, mete la llave en el bombín (lo de dentro, recortado) y gira la muñeca (`acc-llave-1`, de PixelLab sobre la primera); el candado, la misma mano girada desde abajo (`acc-llave-v0/1`).
  - **El teclado, el cajero y la caja de la tía:** el dedo (`acc-dedo`, la manga por abajo) pulsa cada tecla de la clave y del PIN y señala cada rueda que se para; al final, la manilla.
  - `tools/sprites/pixellab_gestos.py` pasa las elegidas de `tools/sprites/pixellab-gestos/crudo` al atlas (fuera la columna gris del canto, sin semitransparencias, manga en el canto comprobada). `tests/acceso.gd` (67): la mano llega al canto en cada momento de la llave, el candado, la clave, el PIN y la rueda; la llave gira; el brazo de regar en el canto y el agua dentro de la maceta.
  - **Todas las manos, por el canto** (0.55, lo pidió el usuario: «cumple todo lo pendiente»): 14 manos de PixelLab (`gm-*`, con la misma manga granate que la llave; la del cliente, espejada y de azul, `-i`) en tratar (el pulverizador), abonar (la botella, el chorro del tapón a la tierra), plantar y sembrar (la semilla entre los dedos y la mano que aprieta la tierra), esquejar, cosechar y manicurar (las tijeras abiertas y cerradas), polinizar (el pincel), fumar (el porro, la pipa y el vaporizador; el bong sigue en la mesa), vender (la mano del cliente por la izquierda con el billete, la tuya con la bolsita; se cambian) y pagar (tu mano deja los billetes uno a uno y empuja el montón). `_gsm` alarga la manga hasta el canto del plano: nunca flota. Fuera la regadera a mano vieja (`gs-regadera-0/1`).
  - **El porro, con o sin tabaco** (lo pidió el usuario: «si es con o sin tabaco se tiene que diferenciar»): con tabaco, la punta retorcida con hebras marrones y el humo gris, y «El tabaco rasca la garganta y tapa el sabor»; solo hierba, hebras verdes, el humo blanco y «Solo hierba: sabe a la variedad y sube más» (`gesto("fumar", {"m", "tab"})`, `_gesto_fumar(…, tab)`).
  - `tests/acceso.gd` (85): cada mano nueva llega a su canto (la del cliente, al izquierdo), las dos variantes del porro se distinguen y la regadera vieja ya no sale.
  - **El mechero, en la otra mano** (lo pendiente de la 0.55): la mano izquierda de PixelLab (`gm-mech0-ab`, `gm-mech1-ab`: la misma, encendida y sin la llama; `-ab`, la manga en el canto de abajo) sube con el mechero, enciende el porro, la pipa o el bong por la punta y baja; fuera el mechero suelto (`gs-mechero-0/1`).
  - **En primera persona** (lo pidió el usuario: «molaría que la vista sea POV»): las manos de los gestos rehechas en PixelLab desde tus ojos, con la de `pv-vacia-0` de referencia: tu antebrazo entra en diagonal desde la esquina de abajo a la derecha con la herramienta arriba a la izquierda (la regadera, `gm-regar`, en vez de la de perfil; el pulverizador, la botella de abono, las tijeras abiertas y cerradas —editadas sobre las mismas—, la semilla y la mano vacía, el porro, la pipa, el vaporizador, el billete, la bolsita y el pincel); la del mechero, en espejo desde abajo a la izquierda; la del cliente, enfrente, girada media vuelta desde arriba a la izquierda. `_gsm` alarga la manga con su inclinación (`_gs_manga`: la fila donde ya es entera, su tramo y lo que se corre por fila) hasta el canto. `tests/acceso.gd` (89) con `mano_canto` `pov`/`pov-ab`/`pov-i` y sin la regadera de perfil.
  - **Pagar, del fajo al montón:** tu mano va vacía al fajo, coge un billete y lo deja en el montón, cinco veces, y al final lo empuja.
  - `tests/acceso.gd` (89): el mechero en la mano desde el canto de abajo, encendido a mitad, y la mano de pagar en el fajo, vacía y con el billete.
- **Los retratos, el muñeco del mapa en grande** (lo pidió el usuario: «los sprites de las personas cuando hablan tienen que ser los del personaje que se ve en el mapa, pero más desarrollados, más grandes»): un busto de 64 × 64 por cada muñeco del atlas (los 27 grupos de las claves `look:`), sacado con PixelLab del sprite de frente (`create_portrait_character`, de personaje a retrato, 24 colores); Revisados uno a uno contra su sprite (lo pidió el usuario: «algunos son de un género en el juego y de otro en el retrato, y la ropa varía; lo más idénticos posible»): Kiko y Unai repetidos con otra semilla, y la ropa, el género o la edad corregidos con `edit_image_pro_flash` con el sprite de referencia en Iñaki (camiseta de rayas), el cliente 2 (chaleco), Delroy (camisa crema), Baltasar (traje morado), Josune (chaleco y camisa blanca), el cliente 3 (camisa hawaiana), el protagonista (la gorra hacia delante), la clienta 4 (de chica), Kiko (de hombre, con barba de días) y Miren (mayor). Originales en `tools/sprites/retratos/`, juntos en `godot/arte/retratos.png` + `retratos.json` con `python3 -I tools/retratos.py` (quita la línea clara que deja PixelLab abajo en alguno).
  - `retrato.gd`: `grupo(look, mujer)` = el grupo del mapa (`Atlas.grupo_look`; los de la calle, por su hash) y, si el cliente no es de su sexo, uno que sí; `busto(g, boca)` con el vaivén de 1 px al hablar en lugar de la boca dibujada. Sin busto, el dibujado de antes.
  - `retrato_de` (`mundo.gd`) da el mismo muñeco que se ve en el mapa cuando el nombre lo cambia: `GENERO.look` (Bixente y los presidentes, como `mk_ent`), la protagonista (`player-f`) y los rivales (`look_rival`).
  - `ui.gd`: el busto a 1:1 (64 u), de pie sobre el canto de abajo de la caja y asomando por encima, con el texto y el nombre a su derecha (`retrato_w`).
  - Prueba `tests/retratos.gd` (gráfica, en la batería).
- **Los retratos con estados** (lo pidió el usuario: «tiene que tener diferentes estados, hablando y demás»; con `Datos.CAL`): 204 estados de PixelLab (inpaint de Pro Flash sobre cada busto, solo la boca, los ojos o las cejas; lo de fuera, intacto) en `tools/sprites/retratos/estados/<grupo>-<estado>.png`: `n1` hablando, `p` parpadeo, `a0`/`e0`/`d0` contento, enfadado y dudando, y `a1`/`e1`/`d1` lo mismo hablando. Los tres ladrones, tapados, solo ojos y cejas (al hablar, su gesto con el vaivén).
  - `tools/retratos.py` los pone debajo de los bustos, una fila por grupo, en `"estados"` de `retratos.json` (seis bajados a 32 colores).
  - `retrato.gd`: `estado(g, expr, boca, ojos)` y `textura(…, ojos)`; el gesto sale de `expresion` (lo que dice) y la boca se abre y cierra al ritmo del texto con el gesto puesto; parpadeo solo tranquilo y callado. Sin CAL, el busto de siempre con el vaivén.
  - `ui.gd`: `retrato_e`/`retrato_hab`/`retrato_ojo` y `_parpadeo` en `_process_ui`: 130 ms cada 3,6 s en tiempo real (no toca el reloj del juego ni el oráculo).
  - `tests/retratos.gd` (400): los estados de los 27, la celda de cada gesto con y sin boca, el parpadeo en la caja (y no escribiendo), los tapados y sin CAL.

- **La planta dentro de la maceta en los gestos** (lo pidió el usuario: «el sprite de la planta se queda detrás del de la maceta… partir la maceta en dos, la trasera y delantera»): la maceta se pinta en dos mitades recortadas (`_gs_mac`, `GS_MAC_CORTE` = 8: el canto de atrás y la tierra, filas 0-7, detrás; el canto de delante y el cuerpo, delante) con la planta, el brote o la semilla entre las dos, en regar, tratar, abonar, plantar, sembrar, esqueje, cosechar y polinizar. `tests/acceso.gd` (97): en los ocho, lo de dentro va entre las dos mitades y las mitades se tocan sin pisarse.
- **Cada abono en su fase** (lo pidió el usuario: «en crecimiento no debe estar permitido echar abono de floración, y lo mismo en floración; mecánicas algo más simples»; con `Datos.CAL`): en crecimiento (hasta el 65 %) solo el de CRECIMIENTO y en floración solo el de FLORACIÓN; ABONAR sale si falta el de su fase y, sin él, lo dice y no echa el otro (antes, en crecimiento ya abonada o sin el de crecimiento, echaba el de floración). Sin CAL, como antes. Prueba nueva `tests/abono_fase.gd` (17; 4 fallos con el código de antes).

- **Los brazos en perspectiva** (lo pidió el usuario: «más cortos y anchos hacia abajo»): la manga de tu mano se alarga en una imagen que se ensancha 0,7 px por fila hacia el canto de abajo, como un antebrazo visto desde los ojos (`_gs_brazo`, `GS_BRAZO`, con caché por mano y largo), y las manos van más bajas en regar, tratar, abonar y polinizar para que el brazo sea más corto; la del cliente (`-i`), como antes. `tests/acceso.gd` (97): la manga llega al canto también como imagen.

- **El brazo se desvanece** (lo pidió el usuario: «que se desvanezca por la parte del brazo… las mismas proporciones de mano y brazo en cada sprite» y «acortar el brazo de manera redonda al final y desvanecerlo así»): en todas las manos el brazo sale del corte de la manga hacia su hombro, fuera del panel (`_gs_hombro`: el tuyo abajo a la derecha, el del mechero abajo a la izquierda, el del cliente arriba a la izquierda), mide lo mismo por su eje (`GS_BRAZO_L` = 22 px), se ensancha `GS_BRAZO` = 0,4 px por px (el del cliente, no) con el contorno a los lados y acaba en punta redonda; los últimos `GS_BRAZO_FUNDE` = 6 px se deshacen en tres bandas de tramado de Bayer (3/4, 1/2, 1/4) que siguen la curva, sin contorno en el tramado ni semitransparencias. `tests/acceso.gd` (97, `brazo_fundido`): cada brazo con su largo, entero junto a la manga y con menos de un tercio en la punta.

- La bodega del barco (lo pidió el usuario: «que tú metas esos 10, puedas salir del menú y volver a meter más»; solo Godot, con `Datos.CAL`): lo que cargas desde el noray pasa a la bodega de ese barco (`S.mar.bod[barco]`) y se queda a bordo hasta zarpar, así que se carga en varias vueltas aunque la mochila no dé para todo; DESCARGAR saca a la mochila lo que quepa y DEJARLO CARGADO sale del menú sin perder nada (`bodega`, `bodega_g` en `eventos.gd`); prueba `tests/bodega.gd` (12).

- **Los brazos de los gestos, en cilindro** (lo pidió el usuario: «desde la manga… tiene que tirar la línea negra hasta el final» y «que sea como un cilindro… completarlo con un giro circular… que no tenga esos picos en la manga»): la manga de PixelLab se quita desde el puño (la tela por su tono, con sus luces y sombras, y la raya negra que la rodeaba, sin tocar la del puño ni la de la mano) y en su sitio va un cilindro recto de través a la raya dorada del puño y de su ancho (se ajusta al puño, no a la manga recortada; si no, en el billete, la semilla y el polen salía torcido y con hueco), con el sombreado de su corte de lado a lado, sin restos de la manga vieja ni por detrás del puño, la raya negra por los dos lados y la punta en media luna, `GS_CIL_L` = 30 px desde el centro del puño en todas las manos; sin tramado ni semitransparencias (`_gs_cilindro`, `_gs_negro`; el degradado de la punta, `gs_funde` en px con el tramado de Bayer `GS_BAYER`, a 0 hasta que el usuario elija con o sin; sustituye a `_gs_brazo`, `_gs_hombro` y `_gs_contorno`). Prueba `brazo_cilindro` en `tests/acceso.gd` (sin picos de la tela fuera del cilindro, raya negra y luego vacío por cada lado y por la punta): 11 fallos antes, 0 después.
- **El porro, verde o marrón y verde** (lo pidió el usuario: «el peta sin tabaco va a ser verde. En el peta con tabaco se verán que es marrón y verde detrás del papel»): el papel de `gm-porro` se tiñe por motas al pintarlo (`_gsm(…, relleno)` → `_gs_relleno`, `GS_HIERBA` / `GS_TABACO`, caché por nombre y relleno). **El pulgar en el mechero encendido** (lo pidió el usuario: «a la hora de encender el mechero, desaparece el dedo gordo»): `gm-mech1-ab` lleva la yema con la uña sobre la rueda y la llama dos píxeles a la derecha (`pulgar`, `PULGAR` en `tools/sprites/pixellab_gestos.py`). Pruebas en `tests/acceso.gd`: 2 fallos antes, 0 después.
- **Cada cerradura, su llave** (lo pidió el usuario: «lo haría más personalizado para abrir una cerradura u otra, y el tipo de llave también que concuerde con la cerradura»): `CERRADURA` en `eventos.gd` (portal, local, club, franco, nave y setas, con sus vueltas) y `cerradura(V)`; cada puerta se dibuja a su manera (`_puerta_llave`: el portal de madera con el bombín redondo de latón, el local de aluminio y cristal con el cilindro europeo, el club lacado en negro con roseta y tirador, el piso franco blindado con escudo y llave de gorjas) y el candado grande de acero de la nave o el pequeño de latón del bajo; la llave de cada una sale de la de PixelLab (`llave_tipo` en `pixellab_gestos.py`: cabeza por metal, paletón de serreta, de puntos, de gorjas o de candado; `acc-llave-<cerradura>-0/1` y `-v0/v1`) y gira las vueltas de su cerradura (`ACC_VUELTA` = 300 ms, un «clac» por vuelta). **El puño dorado, entero en las dos manos** (lo pidió el usuario: «el dorado de la manga desaparece en una mano como en otra»): `_gs_cilindro` elige el color del puño por el dorado (`dorado`) y solo quita lo de su tono (`de_puno`). **Créditos**: «Un juego desarrollado por WolfCade», agradecimientos a los beta testers Kerman, Ibai, Adrián y Urko (también en inglés y en la privacidad de `store/`). Pruebas en `tests/acceso.gd` (108/0; el puño, 3 fallos antes) y `tests/ciclo.gd`.
- **La muñeca, la del sprite** (lo pidió el usuario: «sigue esas dos líneas del brazo, del sprite original, y luego lo cierras; no tienes por qué abrir una nueva línea desde la muñeca»): `_gs_cilindro` ya no quita la manga de PixelLab; la deja entera con el puño y la muñeca, busca la dirección de sus dos rayas (la que las junta en dos rectas, de grado en grado), las sigue rectas hasta `GS_CIL_L` copiando la manga hacia atrás por esa dirección y cierra con la media luna; el corte de la manga ya no se come la fila de la mano en el mechero. Prueba «la muñeca y la manga, las del sprite» en `tests/acceso.gd` (17 manos, todas fallaban antes; 109/0).

- **Las puertas, dibujadas como los gestos** (lo pidió el usuario: «los fondos del candado y de las cerraduras… se nota que no se ha creado con lo mismo»): `acc-f-<cerradura>` a mano en `gestos.py` (104 × 84, celda `acc_fondo`, con el contorno, la luz arriba a la izquierda y 3-4 tonos por material: el portal de tablas con el escudo de latón, el local de aluminio con el cristal, el club lacado con la roseta, el franco blindado, la persiana de la nave y la chapa del bajo con su pasador); el candado, con contorno. `tests/acceso.gd` 109/0.

### APK de la huerta y el combate · Godot 0.58.0 (código 78)
- Lo pidió el usuario: «Saca la APK no?». Lleva la huerta (bancales de 7 × 4 con las matas dentro, ampliable a 16 sitios, setos de PixelLab, riego centrado, tallo en el centro), el combate en su lado (enemigo arriba a la izquierda, protagonista abajo a la derecha), el retrato del cliente y la nave cerrada hasta alquilarla. Batería entera en verde (bat17: 80 suites, 0 fallos).
- `descargas/LandraceHunters.apk` (88,6 MB, `apk-instalar.py` + `zipalign -P 16` + `apksigner`, la misma firma y el mismo paquete que la 0.57.1); AAB firmado de 81,8 MB, targetSdk 36, 16 KB en las 4 `.so`.

### APK del teclado y el ratón · Godot 0.57.1 (código 77)
- Lo pidió el usuario: «pásame también el APK con esto». En el móvil no cambia nada (la cruceta y A/B, como siempre); con un ratón o un teclado conectados, el clic izquierdo es A, el derecho B y W A S D las flechas. Batería entera en verde (67) y las de pantalla y mandos repetidas con el cambio.
- `descargas/LandraceHunters.apk` (88 MB, `apk-instalar.py` + `zipalign -P 16` + `apksigner`, la misma firma y el mismo paquete que la 0.57.0); AAB firmado de 81 MB, targetSdk 36, 16 KB en las 4 `.so`.

### El retrato del cliente y la nave cerrada hasta alquilarla (lo pidió el usuario), con `Datos.CAL`
- **El retrato, el del cliente con el que hablas** (lo vio el usuario: «los sprites al hablar portrait que sean los del personaje que interactúas»): la etiqueta del cliente (TURISTA, PIJO, CURRANTE…, de `CTYPES` y de `GENERO.ctM`) coincidía con el nombre del NPC turista y salía su cara de sombrero. Ahora `retrato_de` da el muñeco de `habla_look` cuando la etiqueta es de un cliente (`etiquetas_ct` en `mundo.gd`). Prueba en `tests/retratos.gd` (§3c).
- **La nave, cerrada hasta alquilarla** (lo pidió el usuario: «no se debería poder abrir la puerta, como en los locales que no están alquilados»): la persiana de la nave y la puerta de los locales sin alquilar se pintan cerradas aunque estés delante (`puerta_cerrada`, `gate_cerrado` en `venta.gd`, usado en `_arte_edificios` de `pinta.gd`).
- **Ver la nave por reformar** (lo pidió el usuario: «cuando lo vayas a alquilar, entres al local y por reformar»): Arrieta da a elegir ALQUILARLA, VERLA POR DENTRO o NO; por dentro, la nave vacía con cajas, sacos, bidones, neumáticos y la garrafa del último inquilino (`MAPS["nave-r"]`, `NAVE_RUINA`, `mapa_nave_r` en `mundo.gd`), cada trasto con su frase, y al salir te vuelve a hacer la oferta (`S.flags.naveVer`, `nave_vista`). Prueba nueva `tests/nave_puerta.gd` (28).

- **El foco, por el temporizador** (lo pidió el usuario: «cuando esté en 12 h y esté a oscuras se tiene que ver a oscuras»): con plantas vivas, el foco se enciende a las 6:00 y se apaga a las 24:00 en 18/6 y a las 18:00 en 12/12; en automático, 18/6 hasta que una planta florece y 12/12 desde entonces (`Cultivo.foco_on`, `horas_luz`, `LUZ_DESDE`). En sus horas de noche, la vista C sin haz y a oscuras (`NOCHE_C` en `vista.gd`, `oscuro` en el shader), la campana apagada, el piloto del temporizador apagado y, en el piso, sin la mancha de luz delante de la carpa. De día, igual que antes. Sin CAL, como el HTML. Prueba nueva `tests/luz_carpa.gd` (25, gráfica).

- **El colocón en la pantalla** (lo pidió el usuario: «dependiendo del porcentaje de colocón… que la vista de la pantalla se hace más pequeña, con la forma ovalada de un ojo, y que se ve humo también cuando fumas. Difuminado»): de `FISIO.efecto` (20) para arriba, la pantalla se cierra en forma de ojo con el borde difuminado, más cuanto más colocado (`ojo_k` en `juego.gd`), con lo de dentro un poco borroso y rojizo; al fumar o catar, humo blanco difuminado que sube y se va en 7 s (`humo_k`, `HUMO_MS`, `humo_ms` desde `colocar`). En `vision.gdshader`, junto a la borrachera; en el mapa y en la carpa, no en los combates ni en los menús. Prueba nueva `tests/colocon.gd` (16; con pantalla y `--pintar`, las capturas).
- **El colocón en pixel art** (lo pidió el usuario: «los efectos y los sprites tienen que ser del mismo estilo que el juego»): `vision.gdshader` calcula todo por píxel del juego (la rejilla de la pantalla baja, no la del móvil), el borde del ojo en escalones con tramado ordenado Bayer 4 × 4 y un canto rojizo, y el humo en tres tonos de la paleta con tramado, sin degradados ni desenfoque; la borrachera, con desplazamientos enteros. `tests/colocon.gd` (22): cada píxel del juego de un solo color y ≤ 40 colores (con el filtro de antes, 6 fallos).
- **La CannaDex única** (lo pidió el usuario: «juntarlo todo… que en CannaDex salga la misma información… catalogarlo por zonas o por los cruces»): con `Datos.CAL`, START → CANNADEX (y CannaDex en el ordenador) junta la Genoteca, el diario de la tía Maite y las familias: POR FAMILIAS, POR GENERACIÓN (landraces, 1.ª a 4.ª, autoflorecientes y otras), TODAS, TUS CRUCES y LA ÚLTIMA PÁGINA; cada variedad con su ficha, la nota de la tía, la receta o dónde están sus semillas, la familia (cosechada o no) y la cata; Ver la hoja / Lo que entra / Leerlo todo (`cannadex`, `dex_*` en `menus.gd`). Sin CAL, la Genoteca de antes. Prueba nueva `tests/cannadex.gd` (30); `ciclo.gd` al día.
- **Los caminos en el mapa del móvil** (lo pidió el usuario: «en el mapa se deberían de ver los caminos que conectan los pueblos»): con `Datos.CAL`, el croquis dibuja las carreteras en curva entre los pueblos (borde, línea clara y puente sobre el mar) y la pista a Errotabarri, con los minutos del autobús en medio (`CAMINOS`, `camino_pts`, `_camino` en `croquis.gd`); sin las rayas de antes. `tests/calendario.gd` (42): los caminos se recorren y llegan a cada pueblo.
- **Los caminos del mapa, los del juego** (lo pidió el usuario: «hay mapas que conectan ciertos pueblos, eso se tiene que ver reflejado en el mapa»): fuera los caminos inventados (Puerto Viejo – Valdehierro, Valdehierro – Mendialde, Ibarbide – Errotabarri); quedan las carreteras de las líneas del autobús desde Ribera Verde con sus minutos, la carretera comarcal entre Mendialde y Errotabarri (el mapa `comarcal`, que se anda) en su color, con su nombre y el caserío abandonado a un lado, en gris hasta `CAMPO.ch`, y la autopista a Hiriburu por el borde cuando se abre la ciudad (`imagen(D, ch, metro)`, `camino_ok`, `refugio_p`, `AUTOPISTA`). `tests/calendario.gd` (56).
- **La red de carreteras que se andan** (lo pidió el usuario: «no hay más caminos entre los demás pueblos? Habría que crearlos»; eligió la red completa): con `Datos.CAL`, siete carreteras nuevas de 40 × 14 con su paisaje (`MAPS["carr-<k>"]`: la de la costa Puerto Viejo – Ribera Verde, la del valle a Valdehierro, la del monte a Mendialde, la general a Ibarbide con aceras y farolas, la del molino a Errotabarri, la pista de los acantilados Valdehierro – Puerto Viejo y la de la ribera Ibarbide – Errotabarri con el río y su puente), que se abren en el borde de cada pueblo desde el capítulo del pueblo más tardío (`CARRETERAS`: rutas, puertas y casillas que se abren; `montar_carreteras` en `campo.gd` pone las salidas y abre el borde, y lo deja como estaba al cerrarse o sin CAL). Las escribe `tools/carreteras.py` (se puede repetir). El croquis dibuja cada una sobre su mapa real (`CAMINOS` con el mapa, `camino_ok` por `CARRETERAS.rutas`). `tests/carreteras.gd` (176): cerradas al principio, se anda pueblo → carretera → otro pueblo con los mandos y sin CAL no hay ninguna; `tests/calendario.gd` (56): cada camino del croquis es un mapa de verdad.
- **Las carreteras en curva** (lo pidió el usuario: «molaría que los caminos no siempre sean rectos»; después, «más tramos rectos» y «un poco mal los sprites, hazlo mejor»): con `Datos.CAL`, la calzada de seis de las siete carreteras sube o baja una fila dos veces por el paisaje, con tramos rectos de 8 a 14 casillas (`CURVAS` en `tools/carreteras.py`; la general a Ibarbide, recta con sus aceras); cada giro es una pieza de 4 × 3 casillas `cv<R|O|P>-<d>-<c><r>` (asfalto, asfalto roto o pista) que `_curva` en `pinta.gd` dibuja columna a columna de 1 px con la calzada recta corrida por una S suave de escalones limpios (de largos a cortos y de cortos a largos, 7-5-4-3…: `_cv_tabla`, `_cv_o`), sobre hierba, con el canto de la hierba en el asfalto y la orilla de hierba de la recta en la pista (`tierra-03`/`tierra-12`). El atrezo, con sentido: las vallas de los prados y la barandilla del acantilado seguidas y paralelas a la calzada (`VALLAS`), las farolas de la general en la acera de arriba, como en el pueblo, y los bancos de la ribera mirando al río; suelto, solo árboles, matas, frutales y setos, nunca pegados a la calzada (fuera las vallas sueltas, las cajas y las farolas en mitad del prado). Puerto Viejo abre también (38, 13), que tapaba la salida a la pista de los acantilados antes del capítulo 8 (`abre` lleva la salida que lo abre). `tests/carreteras.gd` (357): las curvas se pisan, ninguna carretera es recta (salvo la general), cada curva de 4 casillas, tramos rectos largos, la S con los escalones limpios y sin vallas sueltas ni estorbos pegados a la calzada.
- **La playa, los biomas y al volante por las carreteras** (lo pidió el usuario: «la playa molaría que no sea todo el rato recta, que haya alguna zona más entrada de la arena… más al interior será más verde todo», «diferentes biomas… zona playa, o zona más de monte, o zona más de llano, zona más de tierra, pero poco más» y «por esos caminos sí que se puede utilizar tanto el coche como la moto, como el otro coche, como el superdeportivo, lo que sea»): con `Datos.CAL`, cada carretera con su bioma (`BIOMA` en `tools/carreteras.py`, `CARRETERAS.rutas[*].bioma`: playa en la costa y los acantilados, monte, llano en el valle, la ribera y la general, y tierra en el molino). La playa, una casilla nueva `arena` (`PLAYA` por tramos de columnas: el mar entra más o menos y la arena es más o menos ancha, nunca pegada a la calzada) pintada por código (`playa_img`, `_playa`, `_playa_agua` en `pinta.gd`): la orilla por la media del agua en `PLAYA_R` px alrededor de cada píxel, con las esquinas redondas y ondulada, la espuma, la arena mojada, el grano, alguna concha, matas de duna junto a la hierba y la ola que se mueve en cuatro fases; los acantilados con dos calas de arena y la barandilla partida; hacia el interior, lo verde (`SUELTO`: hierba alta y flores bajo la calzada de la costa, el bosque encima de la del monte, prados con flores en el llano). La tierra, bancales de tierra arada por encima de la calzada del molino (`BANCALES`, casilla `surco`, `surco_img`). Al volante: desde el garaje o el aparcamiento, «Por la carretera a…» de las carreteras abiertas de ese pueblo (`carreteras_de`, `al_volante`, `tramo_carretera`: la gasolina y los km de `CONCE.km` entre los dos, 8 como poco); en la carretera vas en el coche, la moto o el superdeportivo (`S.volante`, `vehiculo()`), solo por la calzada (`fuera_calzada`), y al salir por un extremo se queda aparcado en ese pueblo (en Ribera Verde, en el garaje) con el taller y el control de tráfico (`volante_llega`, `volante_fin` desde `warp`); la bici y el patinete, también por las carreteras y por donde quieras. `tests/carreteras.gd` (386): los biomas, la arena lejos de la calzada, el agua con su playa debajo y sin salientes, las calas, los bancales de 2 × 2, el bosque y los prados, y la orilla (agua, espuma, mojada y seca, no recta, la ola); `tests/volante.gd` (31): cerradas, la gasolina y los km, el coche en la calzada, aparcado al llegar, de pueblo a pueblo, al garaje, la moto y el superdeportivo, sin gasolina, la bici y sin CAL.
- **Ningún árbol encima de un edificio** (lo preguntó el usuario: «los árboles no pueden estar encima de los edificios, ¿no?»): con `Datos.CAL`, al entrar en un mapa (`arboles_fuera` en `mundo.gd`, desde `enter_map`), los árboles, manzanos y matas del monte cuya copa pisaba un edificio se pintan antes que los edificios si su pie queda detrás o al lado (`m.tras`, que `pinta.gd` dibuja antes de las fachadas) y se quitan si están delante y taparían la fachada (`_arb0`; vuelven sin CAL). Se mira píxel a píxel, con el desfase y el espejo de cada árbol. `tests/arboles_edificios.gd` (23): en todos los mapas con edificios, ningún píxel de un árbol encima de uno (con los mapas de antes había más de cien), los de detrás detrás, los quitados (pocos), la esquina de Astilleros y el Ensanche, y sin CAL como estaban.
- **La huerta abandonada de la tía** (lo pidió el usuario: «la posibilidad de encontrar la huerta abandonada de al lado de casa, en el pueblo, para poder cultivar ahí en exterior»): con `Datos.CAL`, detrás del garaje del barrio, la cancilla comida por las zarzas (A en (9, 1) o (10, 1): «Abrirte paso»; el cartel del barrio da la pista) abre la senda a la huerta (`HUERTA`, `S.huerta`, `montar_huerta`, `mapa_huerta` en `campo.gd`: 30 × 12 con el monte alrededor, el seto, el camino de tierra, cuatro bancales de hierba alta y zarzas, el bidón, el cubo, la caja, los sacos y un manzano). Desbrozar los bancales lleva 4 horas y deja 8 sitios para plantar al aire libre, con las mismas semillas y esquejes que en casa (`pot_action`, `plantar`, `harvest` y `sacar_esqueje` de `granja.gd` aceptan la huerta). Fuera manda el calendario: crece en vegetativo hasta primeros de agosto (`veg`: del 20 de abril al 5 de agosto) y florece después; lo que crezca antes de florecer da más (hasta `HUERTA.g` = 250 g, tope 500), el sol del mes (`Cultivo.f_clima` con el tiempo del día), el agua se va por mes y la lluvia riega; el bidón riega todas a la vez. La helada (−25) y la nieve (−50) hacen daño de noche, y con lluvia en flor puede salir la botritis; las secas se pintan en pardo (`hs<v>-<fase>`, `_seca` en `pinta.gd`), con las plantas de `huerto-pl` por su % índica y su fase. `tests/huerta.gd` (118): sin CAL el pueblo igual, la pista, abrirse paso, la puerta, el mapa, que se llega a todo, desbrozar, plantar, crecer, la temporada (plantada en abril da más que en julio y más que una maceta de 7 L), la lluvia, regar, cosechar, helada, nieve, la seca, guardar y cargar, y sin CAL otra vez.
- **Las mejoras de la huerta** (lo pidió el usuario: «opción a comprar mejoras como tanques de agua de 1 m3 o tanques azules de 100 L dependiendo, también sistema de riego… herramientas para trabajar la tierra o motoazada siguiente mejora… habría que hacer los sprites y eso»): con `Datos.CAL`, desbrozada la huerta, la tienda online trae «La huerta: depósitos, riego y herramientas» (`HUERTA_MEJ` en `campo.gd`, `huerta_tienda`), con tarjeta y para el día siguiente (`S.huerta.ped`, `llega_huerta` en `new_day`): bidones azules de 100 L (35 €, hasta 3, junto a la cancilla), depósitos IBC de 1 m³ en su jaula (95 €, hasta 2, el nivel por cuartos, `ibcD-0..4`), el goteo con bomba solar (150 €, pide algún depósito: tuberías del depósito al camino y un ramal con gotero por fila de sitios, `_manguera_huerta` en `pinta.gd`), las herramientas (60 €, azada, pala y rastrillo: cavar cada sitio vacío, 45 min, +15 %) y la motoazada (490 €, pide las herramientas: labrar los vacíos en 40 min, +30 %; `S.huerta.t`, `huerta_f`). Los depósitos se llenan con A (`S.huerta.agua`, 15 L/min) y el goteo riega solo cada planta por debajo del 50 % con lo que pide su tamaño (3–20 L, `huerta_gotea`), no cuando llueve; un día de julio con ocho plantas grandes gasta unos 76 L. La tierra cavada se ve oscura y esponjada (`surcoV`) y cosechar la deja sin labrar. Sprites a mano (`tools/sprites/a-mano/huerta_mej.py`, asset `huerta-mej`: `bidonA`, `ibcD-*`, `herrH`, `motoA`, `bombaS`). Prueba `tests/huerta_mej.gd` (106 comprobaciones; falla con el código de antes).
- **Las plantas de la huerta, en el suelo y al sol** (lo pidió el usuario: «El cultivo tiene que ser igual que en la nave digamos, pero solo que no hay focos, está únicamente la luz del sol. No van por macetas sino que se plantan en el suelo pero se hacen más grandes cada planta y la distancia de una a otra es de una baldosa, en los bancales que has hecho en el mapa, bien centradas. Los tubos no están muy centrados que digamos no? Ajustalos bien a los bancales»): con `Datos.CAL`, cada sitio de la huerta es un bloque de 2 × 2 casillas dentro de su bancal (dos por bancal, con una baldosa libre entre las dos y centrados; `huerta_bloque`, `huerta_idx` en `campo.gd`): la planta, en la tierra y sin maceta, con el pie en el centro del bloque y las cuatro casillas sólidas (`hgx`), y A en cualquiera de ellas la cuida. Las plantas, a mano como las de las mesas de la nave pero más grandes (48 × 56, de 32 a 40 px de ancho en flor; índica, híbrida y sativa en cinco fases, `hg-<porte>-<fase>` y la seca `hgs-`; `tools/sprites/a-mano/huerta_pl.py`, asset `huerta-pl`), con los colores de su variedad (`_tinte_planta` en `pinta.gd`, el mismo que las mesas). Los tubos del goteo, centrados (`tubos_huerta` en `pinta.gd`): la general por la mitad de la fila de arriba, el tronco por el centro del camino y un ramal por la línea del medio de cada bancal, con 10 px de margen igual a los dos lados y un gotero en el centro de cada bloque. La motoazada, a (21, 4) para no cerrar el paso a la caja. El plano de cerca en la huerta (`gesto_sol`): el cielo, el monte y el seto al sol (`gs-f-huerta`) y el alcorque en la tierra en lugar de la maceta (`gs-tierra`, `gs-tierra-m` regado; `gestos.py`). Prueba `tests/huerta_sitios.gd` (242 comprobaciones; no carga con el código de antes); `tests/huerta.gd` y `tests/huerta_mej.gd`, al día.
- **El seto de la huerta, de PixelLab** (lo pidió el usuario: «Los setos también habría que ajustarlos incluso hacer los sprites con pixel lab tambien»): con `Datos.CAL`, el seto que cierra la huerta va por piezas sacadas de una imagen de PixelLab (`tools/sprites/pixellab_setos.py`, asset `seto-huerta`): los tramos de los lados con su remate arriba (`setoV0`, `setoV`, `setoV2` y los de la derecha `…d`), las dos esquinas (`setoL`, `setoR`) y el tramo de abajo con sus remates junto al camino (`setoH`, `setoH2`, `setoHd`, `setoHi`), con dos variantes alternas para que no se vea la repetición; una casilla de hierba a cada lado, que el monte no lo tape (`mapa_huerta` en `campo.gd`). `tests/huerta.gd`: las piezas en su sitio y en el atlas.
- **El riego y las plantas, en medio del bancal** (lo pidió el usuario: «los riegos deben de ir bien centrados en el bancal y en la planta, las plantas deben estar también en medio de los bancales»): con `Datos.CAL`, la tierra arada lleva su canto por los cuatro lados, también junto al camino de tierra (`_mascara` en `pinta.gd`: para `surco`/`surcoV`, todo lo que no es bancal cuenta como borde), así que el ramal del goteo y el gotero quedan en el centro del bancal que se ve; la mata de cada planta, centrada en su pie (`huerta_pl.py`, la celda `planta_huerta` pasa a 48 × 64) y el plano de cerca, en el pie (`huerta_hu`). `tests/huerta_sitios.gd`: la mata en medio de su bancal (±2,5 px) y el canto junto al camino.
- **Los brazos al ordenador** (lo pidió el usuario: «como coloca los brazos cuando usa el ordenador Gaming o el de la tía» y «Has primero el Sprite del jugador con los brazos puestos y después lo sientas en la silla, pidiendo su Sprite por detrás»): sentado delante del ordenador de la tía o del gaming, el protagonista (chico o chica) usa el fotograma `teclea` de PixelLab, de espaldas con los codos abiertos y los antebrazos hacia el teclado (`tools/sprites/pixellab_teclea.py`, que lo pasa a los colores del base para que la ropa lo vista), en vez de los brazos pintados a mano (fuera `SENT_MESA` por filas y `brazos_mesa`; `frame_sentado` en `pinta.gd`). `tests/escala.gd`: el fotograma con los brazos puestos, más ancho que el base, con los colores de la ropa, y sin mesa el base.
- **Los combates, más realistas** (lo pidió el usuario: «Habría que mejorar los sprites de los combates, que realmente sean más realistas»): con `Datos.CAL`, cada luchador sale de PixelLab a unas 6 cabezas de alto (`create_image_pro` con la pose y el estilo → `create_character` v3 → `animate_character` v3), con las mismas animaciones, direcciones y fotogramas que el de siempre: el protagonista y la protagonista de espaldas (idle, golpe, patada, spray, comer, herido, desmayo), los tres ladrones y Darko (idle, ataque, herido, huir) y el agente (idle, alto, multa, soborno, perseguir). `tools/sprites/pixellab_combate.py` los pasa a la paleta (el protagonista, a los 15 colores del `player-combate` para que ROPA los vista, con el pelo y las suelas por material; los demás, a 15 por grupo: 10 por MEDIANCUT y 5 más, uno a uno, los que más error quitan, para que no se pierdan el blanco de las zapatillas ni la camisa del agente), quita los sueltos y los encaja en la celda de 64 × 64 con los pies en la fila 62, en grupos aparte `<grupo>-combate-r` (sin `cubre`); `grupo_combate` (`policia.gd`) los elige con CAL y sin CAL deja los de siempre (el oráculo). Prueba nueva `tests/combate_r.gd`.
- **El combate en su lado** (lo pidió el usuario: «si te atacan desde la derecha, el sprite te tendría que defender a la izquierda y los personajes deberían estar colocados en la pantalla de combate correcta y lógicamente» y «el combate está al revés, a la izquierda arriba el enemigo, a la derecha abajo el personaje»): con `Datos.CAL`, la escena en espejo (`lado_x` en `policia.gd`: el enemigo con los pies en x 62, arriba, y el protagonista de espaldas en x 176, abajo), con el fondo y sus plataformas en espejo (`_espejo_img`, los cortes de los lados cambiados); cada golpe, hacia el rival: el del protagonista hacia la izquierda y el del enemigo hacia la derecha (las animaciones de PixelLab que salieron hacia el otro lado van en espejo, `COMB_ESPEJO`/`comb_espejo`; la caída no, que cae lejos del enemigo), los efectos donde cae el golpe y el espray desde la derecha (`vfx_combate` con `esp`), y al huir el enemigo corre hacia la izquierda. Las dos cajas de vida, una encima de otra, arriba a la derecha, a la izquierda de SONIDO, START, MÓVIL, A y B si les caen encima (`be_r` en `ui.gd`). Sin CAL, como siempre (el oráculo). Prueba nueva `tests/combate_lado.gd` (78; falla con el código de antes); `tests/capturas_ui.gd` mide que las cajas no tapan a ninguno de los dos y ya no pinta la escena con el ancho del oráculo (salía a la izquierda).
- **La huerta, ampliable al doble** (lo pidió el usuario: «molaría que fuese ampliable en espacio la huerta, para poder plantar por lo menos el doble de plantas»): con `Datos.CAL`, la tienda online de la huerta trae «Ampliar la huerta» (1.200 €, una vez, al día siguiente; `HUERTA_MEJ.amp`): una cuadrilla desbroza el monte de abajo, baja el seto 6 filas y hace cuatro bancales más, de 8 a 16 sitios (`huerta_def` y `huerta_amp` en `campo.gd`: el mapa, los sitios, los bancales, el seto, la salida y el atrezo de abajo salen de ahí; `S.huerta.p` y `t` crecen a 16 conservando lo plantado y lo cavado). El goteo llega a los bancales nuevos (`tubos_huerta` con `huerta_def`) y la cancilla del pueblo lleva a la llegada de abajo. Prueba nueva `tests/huerta_amp.gd` (496; falla con el código de antes): sin obra, la de siempre; la tienda, pagar y llegar; el doble de sitios en su bancal, simétricos, con su baldosa libre, sin solapes y que se llega a todos andando; una planta en un sitio nuevo; el goteo con 16 goteros; guardar y cargar; sin CAL, la huerta de siempre.
- **Las plantas, dentro del bancal** (lo dijo el usuario: «Me parece como que están fuera las plantas no?»): con `Datos.CAL`, las matas en flor (hasta 40 px de ancho y 45 de alto) se salían entre 4 y 7 px de los bancales de 5 × 2. Ahora los bancales son de 7 × 4, con una casilla de tierra alrededor de los dos bloques de 2 × 2 (`HUERTA` en `campo.gd`: el mapa de 30 × 16, el seto de (5, 1) a (24, 14), los sitios en las filas 6 y 11, la llegada en (15, 13); las herramientas a (6, 8) y la motoazada a (23, 8), fuera de los bancales; la obra, `amp.dy` 10, con sus cuatro bancales iguales). `tests/huerta_sitios.gd`: cada píxel de cada `hg-<porte>-<fase>`, en cada sitio, dentro de su bancal con 4 px de margen (8 fallos con el de antes); `huerta.gd`, `huerta_amp.gd` y `huerta_mej.gd`, al día.
- **El tallo de la huerta, en el centro** (lo vio el usuario: «el tallo de la planta no está centrado ¿no?»): el pie de cada planta caía medio píxel a la izquierda del centro del bloque de 2 × 2; `al_eje` en `huerta_pl.py` corre la mitad izquierda del sprite una columna y el pie queda justo en la raya entre las columnas 23 y 24, el centro del bloque. `tests/huerta_sitios.gd` (259), más estricta: el centro de la mata, exacto, y el tallo de la plántula en esas dos columnas (18 fallos con el atlas de antes).
- **Las plantas de la otra rama, vistas y no usadas** (el usuario las señaló en `claude/pheno-hunter-game-wzl06e`): son plantas de lado en maceta de terracota (51 × 150, unos 250 colores, 1.600–2.000 píxeles semitransparentes), no pasan el control del atlas (15 colores, sin semitransparencias) y la huerta se ve desde arriba; quedan como opción para el plano de cerca, cuantizadas.

### Teclado y ratón en el ordenador · plugin de WordPress 1.5.6
- Lo pidió el usuario: «el juego con los controles conectados al AWSD y el botón A y B, que sea el clic izquierdo y derecho». W A S D ya eran las flechas; ahora el clic izquierdo que no cae en un mando, un menú ni el diálogo es A y el derecho es B en cualquier sitio, también encima de un menú (`RATON`, `_raton` en `ui.gd`); el ratón que Godot imita con un dedo no aprieta nada. En la página del plugin, el clic derecho ya no abre el menú del navegador (`oncontextmenu` en el canvas). Prueba `tests/raton.gd` (7; 3 fallos antes).
- Desde el ordenador (lo pidió el usuario: «cuando se entra desde el ordenador a la web»): en el navegador sin pantalla táctil, la cruceta y A/B no se pintan ni ocupan sitio (`solo_raton`, `mandos_raton` en `ui.gd`; el escenario de diálogos y menús, a la escala de la pantalla); START, MÓVIL y SONIDO se quedan. En el móvil y la tableta, los mandos de siempre. `tests/raton.gd` con `RATON_PRUEBA` (12; 2 fallos antes).
- `descargas/landrace-hunters-1.5.6.zip` (28 MB, `node tools/wordpress.js`), con el Godot 0.57.0 y lo de arriba; probado en Chromium de escritorio: sin la cruceta ni A/B, el clic izquierdo pasa el aviso, S y W mueven la opción y el derecho cierra el menú.

### APK de las muñecas y las puertas · Godot 0.57.0 (código 76)
- Lo pidió el usuario: «pásame el APK cuando esté». Batería entera 66/66 en verde antes de compilar.
- `descargas/LandraceHunters.apk` (88 MB, `apk-instalar.py` + `zipalign -P 16` + `apksigner`, la misma firma y el mismo paquete que la 0.56.0); AAB firmado de 81 MB, targetSdk 36, 16 KB en las 4 `.so`.

### APK de los gestos en primera persona · Godot 0.56.0 (código 75)
- Lo pidió el usuario: «Entrega el apk», tras «Molaría que la vista sea POV». Batería entera 64/64 en verde antes de compilar.
- `descargas/LandraceHunters.apk` (87,9 MB, firma v2/v3 con la upload key, el mismo paquete `com.landracehunters.game`).

### APK de las manos por el canto y el porro con o sin tabaco · Godot 0.55.0 (código 74)
- Lo pidió el usuario: «Cumple todo lo pendiente y compila el apk para entregarlo aquí». Batería entera 64/64 en verde antes de compilar.
- `descargas/LandraceHunters.apk` (87,9 MB, firma v2/v3 con la upload key, el mismo paquete `com.landracehunters.game`).

## 1.57.2 · Godot 0.47.1 (código 66; plugin de WordPress 1.5.4)

Lo que pidió el usuario tras la 1.57.1 («Ha desaparecido la puerta del taller, y aún así está muy vacío, molaría meterle otro tipo de suelo en diferentes zonas… el atrezzo deja que desear o por lo menos como está usado» y «en la carretera de la pantalla de carga, que se vea alguna planta en vegetativo, alguna floración, dependiendo del punto del año… cómo sería el cultivo en exterior»). Solo Godot, con `Datos.CAL`.

- **La puerta del cuartucho del taller ya no desaparece**: al comprar una mejora estando dentro, `montar_locales` rehacía el local desde su copia y se llevaba la puerta (`PUERTAS_INT`); ahora vuelve a ponerla (`montar_puertas`) y el atrezo.
- **El suelo del taller por zonas** (`TALLER_SUELO`, `montar_taller` en `mundo.gd`; arte a mano en `tools/sprites/a-mano/taller.py`, `interior-taller`): el hormigón gris de los puestos del elevador y del foso (y del segundo elevador), con manchas de aceite y rodadas por el hash de casilla, la línea amarilla que los separa del paso, el sumidero de rejilla entre el elevador y el foso, la goma antifatiga delante del banco y del lavabo y el gres beige de la espera junto a la caja; el resto, la resina azul de antes.
- **El atrezo del taller, cada cosa en su sitio** (`ATREZO["loc-valde"]`, `taller-alto`, de frente a 16 px/m): el enrollador de la manguera del aire colgado sobre el elevador, el calendario de pared, el lavabo de acero con el papel y el jabón entre el banco y el compresor, la estantería de ruedas nuevas, el extintor con su placa, dos bidones de 200 L, el gato de carretilla y la grúa de motores junto a los puestos, el armario de herramientas grande, la silla de la espera y la máquina de café. Cada cosa con su texto (`ATREZO_TXT`); nada corta el paso.
- **El bancal de exterior en la calle de la carga y del título** (`HUERTO`, `fase_huerto`, `_huerto` en `escena_viaje.gd`): en la hierba de detrás, tres plantas en su bancal según la fecha del sistema y el calendario del norte, con las plantas de cada variedad que ya había (`plantas-vista`, `HUERTO_SM`; sin sprites nuevos, lo pidió el usuario): nada de noviembre a mediados de abril, plántulas hasta mediados de mayo, vegetativo hasta julio, floración en agosto y septiembre, cosecha hasta el 20 de octubre (la del medio, una fase por detrás) y después el bancal vacío.
- **La taberna de Puerto Viejo, toda en muebles a mano** (lo pidió el usuario: «los sprites… en el bar este del Puerto Viejo… no están para nada acorde con el estilo… Una silla tiene que ser de verdad un mueble… crea todo como muebles… que parezca que la haya creado la misma persona»; `tools/sprites/a-mano/taberna.py`, `taberna-alto` y `taberna-ancho`, a 16 px/m con la madera y el contorno del salón): la barra de pintxos con la vitrina (`barraTb`), el botellero (`botTb`), la cafetera de dos grupos (`cafeTb`), las barricas de pie (`barrilTb`), los taburetes (`taburTb`) y, en vez de la mesa con las sillas pegadas (`mesaT`), mesas de pino (`mesaTb`) con sus sillas sueltas, de cara (`sillaTs`) y de espaldas (`sillaTn`, la silla de la tía), en las que te sientas (`ASIENTOS`, `SENT_GEO`; el taburete con las piernas de la barra, `TABURETES`). Las mejoras, con su mesa y sus sillas, sin cortar el paso. La espera del taller (`sillaT`) también es asiento.
- **El atrezo del taller, a la escala del coche** (lo pidió el usuario: «si tú ves el coche, eso tendría que ser como referencia de dimensiones… No pueden ser unos neumáticos igual de grandes que el capó»): todo medido a 16 px/m contra la rueda del coche del elevador (63 cm, 10 px). La pila de ruedas (`neumT`, `negocios.py`), tres ruedas tumbadas de 63 × 20 cm con el hueco de la llanta arriba, y una sola pila por sitio (`montar_taller` quita la segunda, que de fondo hacía una torre); la estantería de ruedas (`rackT`), 1 × 1,8 m con cuatro ruedas de canto por balda; el bidón de 200 L, 58 × 88 cm; el extintor de 6 kg, 50 cm, a 1 m del suelo; el armario de herramientas, 68 cm × 1 m; el lavabo, 60 cm; el calendario, 40 × 60 cm; la máquina de café, 80 cm × 1,8 m; el gato, 90 cm; las sillas de la espera con el asiento a 45 cm (`SENT_GEO.sillaT`). Prueba en `tests/negocios.gd` (las medidas en el atlas).
- **Las plantas del bancal, con contorno y en el estilo de la calle** (lo pidió el usuario: «no tienen el contorno para cerrar el diseño. No son del mismo estilo que los sprites… de la carretera como la acera»): las de `plantas-vista` eran las antiguas de la vista de carpa B (pintadas, sin contorno), no las de la nave ni las de casa. Ahora, dibujadas a mano (`tools/sprites/a-mano/huerto.py`, grupo `huerto-pl`, `hp<variedad>-<fase>`) con la hoja de abanico de las plantas de casa (`prim.hoja`) y su paleta, en pequeño y con el contorno verde casi negro como el árbol y el seto: índica, sativa e híbrida en cinco fases, de la plántula de 20 cm a la madura de 1,4–1,9 m con los pistilos naranjas y las hojas de abajo amarillas. Prueba en `tests/viaje.gd` (las quince, a 16 px/m y creciendo).
- **Al sembrar, la semilla** (lo pidió el usuario: «sería mejor echar una semilla al plantar y al sembrar»): el gesto `sembrar` (`GESTOS`, `GESTO_DE`; `gs-semilla`, `gs-pinza-0/1` en `gestos.py`): los dedos bajan con la semilla, la sueltan en la tierra y la mano la tapa. Al plantar un esqueje, el gesto de antes, pero con el brote dentro de la maceta, delante del canto de atrás (antes se quedaba detrás).
- **La escalera del sótano baja hacia la derecha** (lo pidió el usuario: «girada… que el final se vea a la derecha del todo, no abajo»): el hueco del pasillo, de 2 × 2 casillas (`bajS1`..`bajS4` en `sotano.py`), con los peldaños en bandas del claro al oscuro y la barandilla delante.
- **La franja de la pantalla de carga**: el cielo (`_cielo`) solo llegaba a la fila 120 y entre el monte y la carretera quedaban 2 filas sin pintar, por las que se veía lo de detrás; ahora llega hasta abajo (también en el viaje).
- Pruebas: `tests/negocios.gd` (la puerta y el atrezo tras la mejora, el suelo por zonas, el arte y que se llegue a todo, también en la taberna), `tests/escala.gd` (85: las mesas, sillas y taburetes sueltos de la taberna, que te sientes, su arte; con `--pintar`, sentado en la taberna y en la espera), `tests/sotano.gd` (el hueco de 2 × 2), `tests/acceso.gd` (el gesto de sembrar) y `tests/viaje.gd` (106: las fases del bancal por fecha, que no vayan hacia atrás y las plantas de cada variedad; con `--pintar`, `huerto-<mes>-<día>`).

## 1.57.1 · Godot 0.47.1

Lo que pidió el usuario tras la 1.57 («que aparezcan en la pantalla de carga los sprites reales de césped, árboles, setos, también molaría que pasasen algún transeúnte… los botones de la UI principal más pequeños, que así le da el toque más limpio… mejor que se quede de fondo la carretera andando coches y por la acera transeúntes andando, en bici, patinete»). Solo Godot, con `Datos.CAL`.

- **La calle de la carga, con el arte del juego** (`pinta_calle`, `CALLE_FIL`, `PEATONES` en `escena_viaje.gd`): la calle vista de lado y quieta, de abajo arriba: hierba, la acera de delante, la calzada de dos carriles, la acera de detrás y dos filas de hierba con setos y árboles sueltos (los mismos firmes en mosaico, el canto de la hierba, el seto en matas y los dos árboles del mapa, corridos y en espejo por el hash de casilla), y el monte y el cielo detrás. Por la calzada, los vehículos de perfil de antes; por las aceras, ocho personas: andando, en bici (pedaleando) y en patinete, en los dos sentidos. La barra, en la hierba de abajo.
- **El título, sobre la misma calle** (modo `calle` en `pinta.gd`): sigue donde la dejó la carga (el mismo reloj, `carga_t0`), en vez de la partida de fondo, con un velo azul arriba más suave para que se lean el título y el lema. Sin CAL, la partida de fondo de antes.
- **Los botones del título, más pequeños** (`TIT_WV`, `TIT_HV` en `ui.gd`): la pastilla de 84 × 12 u con la letra de 7 u (antes 132 × 17 y 9,5), en el centro de su botón, que se sigue tocando en 48 dp de alto.
- **El extracto, en el porro con tabaco** (lo pidió el usuario: «las extracciones se deberían de poder fumar también con tabaco, sin tabaco no, porque sería con la pipa»; `FUMAR.porro.grt` en `mundo.gd`): sentado, al liarte uno «Con tabaco», también salen los extractos (0,1 g con 0,7 g de tabaco); «Solo hierba», solo los cogollos, y si no llevas cogollos te dice que el extracto solo se lía con tabaco o va en la pipa, el bong o el vaporizador.
- Pruebas: `tests/viaje.gd` (92; con `--pintar`, `calle-carga-*` y `calle-title-*`), `tests/ocio.gd` (67: el extracto con y sin tabaco) y `tests/ciclo.gd` (el título con la calle de fondo).

## 1.57 · Godot 0.47.0

Lo que pidió el usuario tras la 1.56 («estos recursos se podrían usar antes de la pantalla de inicio, usarlo como de carga del juego, en una carretera sin texto, los vehículos andando y la barra cargándose. Luego aparece la pantalla de inicio START con más atrezo»). Solo Godot, con `Datos.CAL`.

- **La carga del juego** (`arranque` en `juego.gd`, `pinta_carga` en `escena_viaje.gd`, modo `carga` en `pinta.gd`): al abrir, la carretera del viaje de día, sin letras ni botones, con el utilitario, el scooter y el superdeportivo por este carril y el autobús y la berlina por el de enfrente (al revés y un poco más oscuros), cada carril a su marcha y sin montarse (`CARGA_V`, `MARCHA`, `HUECO`), las ruedas girando y, abajo, la barra que se llena en 3,6 s (`CARGA`); A, B o START la pasan; después, fundido al título. `--sin-carga` va directo al título; las pruebas que ponen `oraculo`, al título de antes (`_arranca`).
- **El título con más atrezo** (`DEMO_CAL`, `demo_coche` en `mundo.gd`): el protagonista y el poli por las aceras, dos personas más andando y el utilitario, la berlina, el scooter y el superdeportivo con su conductor por la calzada, cada uno en su carril, que entran por un lado y salen por el otro (`e.veh` en `_pj`).
- **Los tubos llegan a las carpas** (lo pidió el usuario: «los tubos no llegan a las carpas, falta 1 o 2 píxeles»): la boca se calcula con el ancla del dibujo de la carpa, como la pinta `_carpa_mapa`, y el tubo entra un píxel en el techo (`_tubos_casa`).
- **Los codos del tubo** (lo pidió el usuario: «en las curvas o giros del tubo no se deben cortar»): en cada giro, un codo curvo (un cuarto de toro de 5 px, hasta 3 px de radio por dentro, redondo por fuera) y los tramos rectos abiertos que empalman con él, sin el canto de la bajada cruzando el del techo (`_tubo_codos`, `_codo`, `_tubo(…, abierto)`).
- **Los mandos, para jugar horas** (lo pidió el usuario: «los controles tienen que ser perfectos, para poder jugar horas»):
  - un dedo que se queda colgado (Android no manda el soltar: una notificación, un gesto del sistema) ya no bloquea la cruceta ni deja A o B apretados: el toque nuevo manda y el viejo se suelta;
  - la cruceta con histéresis (`CRUZ_HISTERESIS`): al deslizar el pulgar, la flecha de al lado tiene que ganar por unos 11° pasada la diagonal, sin zigzag;
  - andando seguido, cada paso arranca con lo que sobró del anterior (`paso_sobra`): 240 ms por casilla exactos, sin tirones entre casillas (antes, 250 a 60 fps);
  - un toque de vibración al apretar cada mando (`vibra`), con OPCIONES → VIBRACIÓN (sí por defecto; permiso `vibrate` en el APK).
- **Los mandos donde caen los pulgares** (lo pidió el usuario: «que sean lo mejor para jugar con el móvil en horizontal, estudiando en qué zonas caen los dedos, por proporciones, para Android, iOS y demás»; `geo_pulgar` y `PUL` en `ui.gd`):
  - en milímetros de verdad: en el móvil y la tableta, los ppp de la pantalla (`screen_get_dpi`) en vez de estimarlos por el alto;
  - más grandes (lo pidió el usuario: «la idea es hacerlos más grandes, no más pequeños»): la cruceta de 30 mm (flechas de 10 mm) donde descansa el pulgar izquierdo, a unos 25 mm del canto y 24 del borde de abajo; A y B de 14 mm (el doble de los 48 dp de Android y los 44 pt de iOS) en diagonal por el arco del pulgar derecho, A más arriba y fuera, B más abajo y dentro, a unos 19 mm; nunca más pequeños que los de antes (`fmin`, por `geo_mandos`): en los móviles, de un 20 a un 35 % más; en la tableta, como antes o algo más;
  - nada a menos de 9 mm de los cantos de los lados (el gesto de Atrás de Android) ni de 8 del de abajo (la barra de inicio de iOS), y dentro de la zona segura (muesca, isla, esquinas redondas), midiendo el pulgar desde el canto de verdad;
  - START y MÓVIL juntos encima de A y B (MÓVIL al lado de START o, si no cabe, encima), fuera del arco de descanso y sin pisar el recuadro del HUD; la zona de toque de A y B, mayor que el dibujo pero por debajo de ellos y sin entrar en el escenario de diálogos;
  - en los táctiles (Android, iOS, tabletas y la web en el móvil, `es_movil`); en el escritorio, los de antes;
  - si no caben al lado del texto (un móvil pequeño), primero se arriman al canto y después encogen, hasta el 80 % (y nunca por debajo de los de antes).
- Pruebas: `tests/mandos_geo.gd` (242, con las ventanas de escritorio de 4:3 a 21:9 y los tamaños de antes y de ahora en mm: seis pantallas —Android 20:9, Android barato, iPhone con isla, iPhone SE, iPad y tableta Android— con sus ppp y su zona segura), `tests/viaje.gd` (91) y `tests/ciclo.gd` (arranca con la carga y acaba sola en el título; los dedos colgados, la histéresis y los 240 ms por casilla).

## 1.56 · Godot 0.47.0

Lo que pidió el usuario tras la 1.55.3 («en el autobús no hay animación como tampoco en los demás vehículos, como una pantalla de carga, pero que sea el vehículo andando recto desde una vista de perfil»). Solo Godot, con `Datos.CAL`.

- **El viaje, de perfil** (`escena_viaje.gd`, `anim_viaje` y `VIAJE_V` en `granja.gd`): al coger el autobús en una parada o salir en tu vehículo del concesionario, una pantalla de carga con el autobús (los pasajeros, el conductor y tú en la ventanilla), el scooter, el utilitario, la berlina o el superdeportivo de perfil, que entra por la izquierda, rueda por la carretera con las ruedas girando y sale por la derecha, mientras el monte, los caseríos con los postes de la luz y el guardarraíl pasan por detrás a distinta velocidad. El cielo, por la hora (día con sol, atardecer, noche con estrellas, luna y los faros encendidos); arriba, de dónde a dónde y los minutos; abajo, la barra. Unos 3 s; A o B lo pasan.
- Arte a mano en `tools/sprites/a-mano/viaje.py` (`godot/arte/viaje.png` + `viaje.json`: recortes, ruedas, suelo y faro de cada vehículo).
- Prueba: `tests/viaje.gd` (77).

## 1.55.3 · Godot 0.46.2

Lo que pidió el usuario tras la 1.55.2 («fallos de arquitectura notables y todavía no has configurado bien en todos los muebles donde se puede sentar, la altura correcta»). Solo Godot, con `Datos.CAL`.

- **Sentarse a la altura de cada asiento** (`SENT_GEO` en `mundo.gd`, `_pj_sentado` en `pinta.gd`): la cadera en el cojín medido en cada sprite (silla, silla gaming, sillón, sofá, sofás del club y del reservado, banco y taburete). La silla gaming, centrada en sus dos casillas y no a un lado; de espaldas, solo el torso, con la cabeza asomando por encima del respaldo (en la silla, 3 px más arriba que antes); de frente, las piernas dobladas de la cadera al suelo, tantas espinillas como haga falta (`piernas_sentado`); el humo sale de la boca en cada asiento (`boca_sentado`).
- **El tubo de extracción**: pegado al techo, por encima de puertas y cuadros, y entra en la ventana por una placa de chapa en la hoja de arriba (la de abajo sigue siendo cristal), en vez de tapar la ventana entera con una rejilla; cada carpa a su ventana, sin tramos de techo uno encima de otro (`ventanas_tubos`, `_asigna_ventanas`).
- Pruebas: `tests/escala.gd` (66) y `tests/carpas_casa.gd` (88).

## 1.55.2 · Godot 0.46.1

- El de las madres de la nave ya no tapa la puerta de la habitación (lo pidió el usuario): con CAL y las puertas de dentro, se pone en (16, 3), delante de su carpa y mirando a ella (`build_ents` en `mundo.gd`); `tests/sotano.gd` comprueba que nadie de la nave está delante de una puerta (93 comprobaciones).

## 1.55.1 · Godot 0.46.0

Lo que pidió el usuario tras la 1.55 («no parece el personaje tumbado en la cama», «la pipa no parece de una sola pieza» y «que se pueda ordenar cualquier mueble de la casa; delante de la puerta y donde la escalera del camarote, libre siempre»). Solo Godot, con `Datos.CAL`.

- **Dormir**: el protagonista entero, de lado, con la mejilla en la almohada, el pelo, la oreja, los ojos cerrados y la nariz; tapado hasta la barbilla con el edredón marcando el hombro, la cadera y los pies, el embozo de la sábana y el brazo por encima; respira (`gs-dormido-0/1`, 128 × 66).
- **La pipa**: de madera y de una pieza (cazoleta, caña y boquilla con un solo contorno), cogida por debajo de la caña.
- **Ordenar cualquier mueble de la casa**: también la cama, el ordenador de la tía con su silla y la mesa de cruces (`si: "cal"`).
- **Siempre libres**: la casilla de delante de la puerta del pasillo y la de la escalera del camarote y la de delante, aunque el camarote no esté hecho; ningún mueble ni carpa se puede dejar ahí.

## 1.55.0 · Godot 0.46.0

Lo que pidió el usuario («la puerta del sótano está inaccesible porque hay una carpa delante», «debería salir un tubo de extracción de cada carpa hacia una de las ventanas» y «poder ordenar las carpas al gusto»). Solo Godot, con `Datos.CAL`.

- **La puerta del sótano, libre**: la carpa C, de serie junto a la cama (casillas 1-2), ya no tapa la puerta del pasillo; la planta del dormitorio pasa a (12, 2) si no cabe y la nevera, a su sitio de reserva.
- **Ordenar las carpas**: ORDENAR LA CASA trae las tres carpas que tengas (A, B y C), en la fila de la pared, como cualquier mueble: ocupan lo que mide la suya (1 o 2 casillas), no se dejan delante de una puerta ni cortando el paso.
- **El tubo de extracción**: con el extractor puesto, el tubo flexible de aluminio sale por arriba de la carpa, corre por lo alto de la pared (por encima de las puertas) y baja a una rejilla en la ventana más cercana que no tape la propia carpa; se mueve con la carpa.
- Prueba nueva `tests/carpas_casa.gd`.

## 1.54.1 · Godot 0.46.0

Lo que pidió el usuario al ver la 1.54 («eso no son sprites en condiciones en el mismo estilo que los muebles del juego»). Solo Godot, con `Datos.CAL`.

- **Los planos de cerca, de sprites**: cada acción se compone con sprites dibujados a mano en el estilo de los muebles (contorno `#2a2a34`, luz de arriba a la izquierda, 3–4 tonos por material) en un panel de 144 × 96 a la escala de la vista C:
  - la planta (vegetativa y en flor), la plántula, la maceta de tela (seca y mojada) y la pared plateada de la carpa salen de la vista C;
  - regadera, pulverizador, botella de abono, tijeras, esqueje y vaso, pincel, cola (con hojas y pelada), bichos, bruma y gotas;
  - porro, pipa, bong con burbujas, vaporizador con piloto, mechero con llama y humo;
  - bolsita, billete, fajo y manos (la tuya y la del cliente), el que duerme y las zetas;
  - fondos: la carpa, la mesa de madera, el salón de noche con el sofá, la calle de ladrillo y la cama de noche y de día.
- Las cerraduras (llave, candado, teclado, PIN y rueda) siguen como en la 1.53.

## 1.54.0 · Godot 0.46.0

Lo que pidió el usuario tras la 1.53 («que todas las acciones del juego sean más realistas, acompañadas de algo gráfico»). Solo Godot, con `Datos.CAL`.

- **Cada acción, de cerca**: como la llave de la 1.53, al hacerla sale un plano de detalle en el centro de la pantalla, con su sonido (A o B lo pasan):
  - **regar**: la regadera se inclina, cae el agua y la tierra se oscurece;
  - **tratar la plaga**: el pulverizador echa dos nubes y los bichos caen de la hoja;
  - **abonar**: la botella llena el vaso medidor;
  - **plantar**: la mano hace el hoyo con el dedo, cae la semilla y se tapa;
  - **sacar un esqueje**: las tijeras cortan la punta y cae en su taco;
  - **cosechar**: las tijeras cortan la cola y cae en la bandeja, con los tricomas brillando;
  - **manicurar**: cuatro tijeretazos y las hojitas caen a la rejilla;
  - **polinizar**: el pincel con polen sobre los pelos de la flor;
  - **fumar y catar**: con papel, el mechero, la brasa y el humo; la pipa; el bong, con sus burbujas; el vaporizador, con su piloto y el vapor;
  - **vender**: la bolsita va hacia el cliente y los billetes hacia ti;
  - **pagar a Toño**: los billetes caen uno a uno sobre la mesa;
  - **dormir**: la ventana con la luna (o el sol en la siesta), la almohada y las zetas.
- Las extracciones ya tenían su escena desde la 1.38. Tres sonidos nuevos: el agua, la tijera y el mechero. Dibujado en código, en píxeles (`gesto`, `GESTOS`, `_gesto_rects`, `_gesto_fumar` en `trama.gd`); `accion()` de `mundo.gd` lo lanza para regar, plantar, cosechar, cruzar y vender. Prueba `tests/acceso.gd`.

## 1.53.0 · Godot 0.46.0

Lo que pidió el usuario tras la 1.52.1 («que funcionen con una clave o simulando teclear una clave o meter una llave, como animación… que ese toque a la A sea más realista o acompañado de algo gráfico»). Solo Godot, con `Datos.CAL`.

- **Abrir lo tuyo se ve**: al pulsar A en lo que se abre con llave o con clave, un momento en el centro de la pantalla con su sonido (A o B lo pasan):
  - el portal del piso, los locales alquilados, el piso franco y el club KAIA: la puerta de madera con su escudo de latón, la llave que entra, gira y hace clic;
  - la nave: el candado de la persiana (la llave sube, gira y salta el arco) y el teclado de la alarma, con sus 4 cifras;
  - el bajo de Txomin: su candado;
  - el cajero: la tarjeta entra por la ranura y se teclea el PIN, con el piloto rojo y luego verde;
  - la caja fuerte de la tía: las cuatro ruedas que giran y se paran en su cifra, el piloto y la manilla que gira (con una combinación mala, el piloto parpadea en rojo y la manilla no se mueve); la empotrada, con su teclado.
- Dibujado en código, en píxeles (`rects_acceso`, `_teclado`, `_llave_h`, `_llave_v` y una letra de 3 × 5 para las cifras, `ACC_GLIFO`), y tres sonidos nuevos: la tecla, la llave y el «clac» (`sonido.gd`). Las cifras de cada teclado son siempre las mismas en cada partida (`cifras_acceso`). Prueba `tests/acceso.gd`.

## 1.52.1 · Godot 0.46.0

Lo que pidió el usuario tras probar la 1.52 («cómo va a estar el mueble de ordenar una sala en otra»). Solo Godot, con `Datos.CAL`.

- **Cada sala se ordena desde dentro de ella**: desde la 1.51 el escritorio está en el despacho y desde allí se movían las mesas y el tanque de la nave, que está al otro lado de la pared. Ahora ORDENAR LA NAVE sale en la nave: en la estantería de los abonos y en el riego (tanque, bomba y controlador); el escritorio del despacho ya no lo ofrece (sin CAL, con el escritorio en la nave, como antes). Y `ordenar(mapa)` no abre nada si no estás en ese mapa.
- Repaso de todos los sitios: la casa (la mesa redonda, en el piso; el pasillo y el sótano no ordenan nada), el local de la asociación (las mesitas, dentro) y las salas de al lado (el cuartucho del taller, el despacho y la habitación de la nave). Prueba `tests/orden_sala.gd`: en cada mapa ordenable y en sus salas de al lado, A en cada mueble; el menú de ordenar un mapa solo sale dentro de ese mapa y cada mapa ordenable tiene dentro un mueble que lo ordena.

## 1.52.0 · Godot 0.45.0

Lo que pidió el usuario tras la 1.51 (el tiempo en el móvil, las autoflorecientes, la skill de sprites, las proporciones de las puertas y el muelle por obras). Solo Godot, con `Datos.CAL`.

- **El tiempo de fuera** (lo pidió el usuario: «en vez de la hora en grande… los grados, el clima y su dibujo, por estaciones»): en la pantalla del móvil, el dibujo del tiempo (sol, nubes, lluvia, niebla, tormenta o nieve) y los °C en grande; en la descripción, máxima, mínima y la estación. El tiempo sale del mes del calendario (`TIEMPO`: máximas y mínimas de la costa cantábrica por mes, probabilidad de cada tiempo por mes, estaciones por equinoccios y solsticios) con la temperatura por hora (la mínima a las 6, la máxima a las 15; `Datos.tiempo`, `Datos.estacion`, `ICONO_TIEMPO`). En la calle se ve: lluvia en diagonal, copos, niebla y relámpagos (`_tiempo` en `pinta.gd`); con lluvia, tormenta o nieve la calle calienta menos al vender (`calle_tiempo`). Prueba `tests/tiempo.gd`.
- **Ruderalis y las autoflorecientes** (lo pidió el usuario: «se nos ha olvidado meter Ruderalis y toda la gran variedad de genéticas que hay AUTO»): la Ruderalis en el banco de semillas (landrace de 4 % de THC) y 16 autoflorecientes con su linaje («X × Ruderalis»): la Lowryder y las versiones auto de Northern Lights, White Widow, Amnesia, Blueberry, AK-47, Jack Herer, Skunk, Big Bud, Super Skunk, Cheese, Blue Dream, Sour Diesel, Super Silver Haze, Purple Kush y Durban Poison, cada una con su nota en el diario. Florecen solas por su edad, sin 12/12 (con 12/12 rinden un 15 % menos), más bajas y con menos rendimiento; no sirven de madre ni se sacan esquejes; auto × auto da auto (`AUTO` en `datos.json`, que solo entra con CAL; `cross_result`, `plant_step`). Prueba `tests/autos.gd`.
- **La skill del director de sprites en el repo** (lo pidió el usuario): `.claude/skills/director-sprites/SKILL.md`, `tools/sprite_qa.py`, el MCP `pixellab-mcp` en `.mcp.json` (con `PIXELLAB_SECRET` del entorno) y Pillow en `requirements.txt`; prueba de humo: un slime de 32 × 32 con su idle de 4 fotogramas (`sprites/slime/`, QA 4/4).
- **Las puertas de dentro, más bajas que la pared** (lo pidió el usuario: «el alto de la pared no puede ser igual que el de la puerta»): las del sótano y del pasillo con su dintel y la pared encima (`TOP` en `tools/sprites/a-mano/sotano.py`).
- **El muelle, destartalado y por obras** (lo pidió el usuario: «comenzar destartalado… ir reformándolo poco a poco, edificio por edificio… para meter un barco más grande se tiene que reformar el espacio… montar otro club ahí»): las casas de la cofradía en ruina (cristales tapiados, pintura desvaída, desconchones, óxido y grietas) y el pantalán con tablones podridos, hasta su obra. Koldo → Las obras del muelle, por transferencia y en sus días: el pantalán (12.000 €, el pesquero ya puede atracar), el dique (45.000 €, el atunero), la caseta de la cofradía (8.000 €, un 30 % menos de patrulleras), las casas de los pescadores (20.000 €, 600 € de alquiler cada semana) y la casa blanca, que es **el club KAIA**: el tuyo, sin carné, con su encargada y el dispensario que llenas tú (40 g al día a los socios). Arte a mano en `tools/sprites/a-mano/muelle_obras.py` (`MAR.obras`, `S.mar.ob`, `obra_ya`, `obras_muelle`, `obras_dia`, `talk_kaia`).
- **La ley** (lo pidió el usuario: «una legalización del cannabis en España que abriría un mercado mucho mayor, ya es otra peli»): 30 días después de abrir KAIA, el Congreso aprueba la ley; con la licencia (25.000 €), la Distribuidora Kaia te compra hasta 5 kg al día con factura, por el banco y sin calor, y KAIA despacha el triple (`MAR.legal`, `licencia_mar`, `vender_legal`). Prueba `tests/obras.gd`.

## 1.51.0 · Godot 0.45.0

Lo que pidió el usuario tras la 1.50 (el final de partida, el atrezo, misiones secundarias, el móvil con iconos, el sótano, las puertas de dentro y las hojas por variedad). Solo Godot, con `Datos.CAL`.

- **El muelle de Puerto Viejo** (lo pidió el usuario: «un mapa lateral en Puerto Viejo, un mini puerto para hacer envíos, invertir en un barco, empezando por uno pequeño»): desde el capítulo 8, al final de la plaza, a la derecha, el paso al muelle de la cofradía (`MAPS.muelle`, 34 × 16; salidas de lado con `lado` en `exits`, `montar_muelle` en `mundo.gd`), con las casas marineras, la acera, el pantalán con sus norays, redes, nasas y cajas, y el agua. Koldo, el amigo de la tía Maite, te manda un SMS y te da su txalupa *Maite* (6 m); el pesquero *Itsaso* (10 m, 65.000 €) y el atunero *Maite Bi* (14 m, 180.000 €) se compran por transferencia y se amarran cada uno en su noray (arte a mano en `tools/sprites/a-mano/puerto.py`).
- **Los envíos por mar**: en el noray de cada barco, la ruta (Burdeos, Brest, Cork y Róterdam, que abre la reputación), la carga por lotes hasta lo que cabe en la bodega (desde 500 g) y zarpar; a los días de viaje, la conservera paga por transferencia (limpio, a la cuenta) al por mayor por la ruta; la patrullera puede parar un barco (según el barco, la ruta y el calor) y quedarse la carga. Rango por kilos exportados (de Txalupero a Almirante del Cantábrico), un pedido cada semana con prima y, con reputación, **el último trabajo** de Koldo: 10 kg a Róterdam en un viaje, con prima de 50.000 € y el final de su historia (`MAR`, `S.mar`, `talk_koldo`, `cargar_envio`, `mar_dia`).
- **El piso franco de Gorka** (lo pidió el usuario: «distribución a gran escala por un piso franco o una persona»): tras el primer envío, la puerta de la casa amarilla del muelle; se alquila (1.500 € al mes en efectivo), lo que dejas en el alijo lo reparte él al por mayor cada mañana (300 g al día; con la furgoneta, 700 g, y con la red de pisos, 1,5 kg) y se queda un 12 %; la caja se recoge en mano; si la calle se calienta, redada en el piso (`FRANCO`, `S.franco`, `talk_gorka`, `alijo_franco`, `franco_dia`).
- **El sótano** (lo pidió el usuario): una puerta en el dormitorio del piso al pasillo de abajo y, con la obra de la tienda online, la escalera al sótano de la tía, con estanterías para bandejas de setas (`SOTANO`, `PUERTAS_INT`).
- **El bajo de Txomin, más grande** (lo pidió el usuario: «que se cultive como la nave»): nueve estanterías en tres páginas y Ekaitz, el sobrino de Txomin, de ayudante: cada mañana pulveriza, recoge lo listo y lo tiende a secar (`SETAS_AY`).
- **Puertas de dentro**: en el taller, al cuartucho con la cama; en la nave, al despacho (con el escritorio) y a la habitación (con la cama) (`PUERTAS_INT`, `puertas_int`).
- **Las hojas por variedad** (lo pidió el usuario: «dependiendo de la variedad o linaje, las hojas son diferentes»): la hoja de abanico de cada una dibujada en código según su % índica (foliolos, ancho, abertura) y, en las landraces que se distinguen, su ficha propia (`HOJA`: las tailandesas de puntas caídas, la hawaiana ancha y clara…), en la ficha de la Genoteca (`src/hoja.gd`).
- **Recados por la comarca**: diez misiones secundarias que aparecen según el capítulo (el jubilado de la rodilla, el bocata para la mar, el camión de Valdehierro…), con su premio en dinero y reputación (`SECUNDARIAS`, `recados_menu`).
- **El atrezo** de la casa de Txaro, el caserío de ama, la comisaría y el almacén (`ATREZO`, `ATREZO_TXT`).
- **El móvil con su pantalla**: la hora en grande y las aplicaciones en una rejilla con sus iconos, a mano (`tools/sprites/a-mano/movil.py`, `MOVIL_V`, `rects_movil`).
- Pruebas: `tests/muelle.gd`, `sotano.gd`, `hojas.gd`, `recados.gd`, `atrezo.gd` y `movil.gd`.

## 1.50.0 · Godot 0.44.0

Lo que pidió el usuario tras probar la 1.49. Solo Godot, con `Datos.CAL`.

- **El recuadro del HUD**: debajo de la fecha y la hora, una tabla ordenada con EFECTIVO, BANCO (la cuenta), FLORES y ROSIN que llevas encima, la etiqueta a la izquierda y la cifra a la derecha, entre dos rayas (`hud_filas`, `_pinta_hud_tab` en `ui.gd`; `update_hud` en `juego.gd`). Encima de CALOR y SOSPECHA.
- **Los nombres enteros en los mercados**: «Hoy tenemos» de los clubs, Iñaki y la lonja salía en la columna de la derecha y cortaba las variedades («Beldi», «Zam», «Dry s»); ahora es un menú a lo ancho con la ficha de cada lote debajo (`comprar_mercado`).
- **Sin hueco al final de los menús largos**: al pasar a una fila con la descripción más corta caben más filas y la lista se quedaba corrida, con el ▲ arriba y un hueco debajo (la tienda de Kiko); ahora se ajusta (`m_top` en `menu`).
- **Menos de 10 g con su décima** en la caja fuerte y el camarote: un lote de 0,4 g ya no sale como «0 g» (`g_lote`).
- **Los estancos con estanquero**: en Valdehierro, Errotabarri e Ibarbide no salía nadie detrás del mostrador porque su muñeco (`cliente4`, `cliente6`, `cliente2`) no estaba en `LOOKS`; ya están (`datos.json`). Repasados todos los `look` de `NPCDEF`: no falta ninguno más (la gente de los negocios sale cuando el local está alquilado).
- **Los menús de comprar y vender enseñan todo**: el de la derecha se ensancha hasta casi toda la pantalla antes de cortar; a toda pantalla, una fila larga ya no estira la ventana fuera de la pantalla; y si el nombre de lo elegido aún no cabe, sale entero debajo, encima de su ficha (`_desc_sel`, `maxw` en `_pinta_menu`).
- **Las mesitas de los clubs, desde arriba**: el tablero ocupa toda la casilla (30 × 11 px, de una casilla a la otra) visto de frente y desde bastante arriba, con el canto y las patas apenas asomando, y lo de encima visto desde arriba (cenicero, grinder, librillo, mechero; la vela, el baúl con la botella, el tablón sobre los bidones, el cristal con la revista). Sentado en el sofá de abajo, de espaldas, solo te asoma la cabeza por encima del respaldo y la mesa se sigue viendo (`mesa_ancha`, `w-mesita-*` en `tools/sprites/a-mano/ocio.py`).
- **Los bancos donde sentarse**: el banco de la calle, la comisaría y los locales, nuevo y a escala (1,6 m de largo, asiento a 45 cm, respaldo a 80 cm, listones de madera y costados de hierro); sentado se ve a los dos lados de quien se sienta, y pegado al borde del mapa se mete hacia dentro (`banco` en `tools/sprites/a-mano/escala.py`, `e-bench`). La altura en el sofá ya era la real: sentado, la cabeza queda a ≈ 1,37 m y por detrás asoma por encima del respaldo de 85 cm.
- **Sentado de frente, en el asiento y no en el suelo**: de frente (bancos y sofás de cara), el culo va en el asiento y se ven las piernas dobladas: los muslos encima del asiento, las rodillas, las espinillas colgando delante del canto (entre ellas, el banco) y las zapatillas en el suelo, con los colores de la ropa que lleves (`SENT_PIERNAS` en `pinta.gd`, `SENT_CORTA_SUR`).
- **En el taburete de la barra, sentado de verdad**: de espaldas, el culo encima del asiento (a 72 cm), el taburete delante de la espalda ya no la tapa, y las piernas cuelgan a los lados del pie con las zapatillas en el reposapiés (`SENT_TABURETE`, `TABURETE_SUBE` en `pinta.gd`). En los sofás, sillones y sillas de espaldas el respaldo tapa las piernas, como en la realidad, y se queda como estaba.
- **La carta de la tía Maite, encima de la mesa**: se pintaba a la altura del pie de la mesa redonda; ahora va sobre el tablero (de 3 px por encima de la casilla a 2 px dentro), después de la mesa, con su sello rojo.
- La prueba de los créditos de `ciclo.gd` lee la versión de `project.godot`, no una fija.

## 1.49.0 · Godot 0.43.0

Los muebles del taller, la panadería, el bar y la lavandería, de frente (lo pidió el usuario: «recuerda cómo deben ser los sprites», con la skill del director de sprites y fotos de la lavandería y de una cafetera de dos grupos). Solo Godot, con `Datos.CAL`.

- **Rehechos en PixelLab de frente**, nunca girados ni isométricos: los de una casilla en alzado recto (vista sidescroller) y los de dos en 3/4 de frente; solo con texto, sin subir las fotos ni poner marcas. La spec está en `tools/sprites/director/negocios-frente/spec.yaml` y el QA en `tools/sprite_qa.py` (0 semitransparencias, 0 huérfanos, ≤ 32 colores).
- **A escala por su alto real** (`PIEZAS` en `pixellab_negocios.py`, en px a 16 px/m): la lavadora de 14 kg (1,4 m), la secadora de 18 kg (1,6 m), el cambiador de monedas colgado en la pared, la mesa alta de patas negras con el cesto y la papelera al lado, el horno de pisos y el botellero (1,8–1,9 m), los taburetes (75 cm)…
- **La bancada metálica de tres asientos** de la foto en la lavandería, en lugar del banco (`d-bench-loc-ibar`, por mapa con `_detalle_obj`; se sigue pudiendo sentar).
- **Segunda vuelta, todas de frente** (lo dijo el usuario: «la vista NO DEBE SER ISOMÉTRICA… hay algunas que están bien, otras que no»): rehechas en PixelLab en alzado de frente con la tapa a la vista y con las piezas buenas (mostrador y botellero) como referencia de estilo las nueve que salían giradas: el horno y la mesa de acero de la panadería, el carro de bandejas, la barra con vitrina del bar, el carro de herramientas, las cajas, la mesa con sillas y la estantería de recambios del taller y la mesa de doblar de la lavandería. Las demás, como estaban.
- **Sentarse de verdad** (lo pidió el usuario: «que te puedas sentar de verdad… y poder hacer cosas sentado»): en los bancos de la calle, los sofás de los clubs y del reservado de GAUA, los taburetes del bar y las sillas de casa, sentarte ya no es un menú que te tiene parado: te quedas sentado mientras el mundo sigue (la gente anda, el reloj corre, START y el móvil funcionan) y te levantas con B o con una flecha, que te deja mirando hacia ella sin dar el paso. Con A, lo de sentado (`menu_sentado`): fumarte uno (donde se puede), pedir algo en el bar, los clubs y GAUA (`BEBIDAS`, a precio de barra), hablar con quien tengas al lado (`al_lado`, `hablar_con`), mirar el móvil, quedarte un rato (media hora; en un banco de la calle, de día, la sospecha baja 1) o levantarte. Al cambiar de sitio, de pie (`SENT`, `levantarte`, en `mundo.gd`); prueba en `tests/escala.gd`.
- **La cafetera de dos grupos** encima de su mueble bajo (`CAFE`), en el bar y en el taller.

## 1.48.0 · 16 de octubre de 2026

La calle más como un RPG clásico y los muebles con lo que traen (lo pidió el usuario: «el mapa lo quiero más realista, no estilo Minecraft sino más de RPG clásico» y «la calidad de los otros sprites también, que se note que es el sprite y lo que trae»). Solo Godot (0.42.0), con `Datos.CAL`: sin CAL, las pantallas del oráculo no cambian. Todo a mano y de frente a 3/4, sin marcas (`tools/sprites/a-mano/detalle.py`).

- **Los firmes, sin la rejilla de 16 en 16** (`exterior-mosaico`, celda `tile_mosaico`): cada firme es un mosaico de 64 × 64 cortado en 16 casillas, y el juego coge la que le toca por su posición (`MOSAICO_TILE` en `pinta.gd`).
  - La hierba, con sus matitas repartidas; las flores, en ramilletes de cuatro pétalos; la hierba alta, en matas redondas.
  - La acera, de losas grandes de 2 × 1 m a matajuntas, con su luz y su sombra; la plaza, de losas de piedra de varios tamaños.
  - La calzada, con el bordillo de piedra (juntas cada metro y la sombra en el asfalto) y la raya discontinua.
  - El camino de tierra, liso, con alguna piedrecita.
  - La hierba, la plaza y la tierra conservan el color de fondo, así que las orillas de siempre siguen casando.
- **El canto de la hierba** (`_canto_hierba`): donde la hierba toca acera, calzada u hormigón, dos píxeles más oscuros hacen de borde, en vez del corte seco de casilla a casilla.
- **El seto, en matas redondas** (`d-seto`), con el borde oscuro, la luz arriba y la sombra del pie.
- **Los muebles, con lo que traen** (`_detalle_obj`: `d-<mueble>-<mapa>-<tramo>`, por mapa y alternando tres tramos por casilla):
  - El mostrador del grow de Kiko y el de GROW IBARBIDE: la caja registradora, los botes de abono y el expositor de los sobres de semillas.
  - El de la comisaría: los papeles con el sello, el monitor y la bandeja de documentos.
  - La barra del bar: los grifos de cerveza, las cañas con el servilletero y una fuente de pintxos; la de GAUA, con el neón del canto, la cubitera con la botella, los cócteles y la coctelera.
  - La vitrina del grow, iluminada, con los sobres, un grinder, los botes, el medidor de pH y los tamices dentro.
  - Las cajas: en el puerto y los astilleros, las de pescado (con hielo y el pescado); en los demás sitios, de madera, abiertas, con una pieza y una bolsa sobre la paja.
  - Las baldas del grow, con los botes de abono; las de la comisaría, con los archivadores; los sacos de sustrato con la hoja en la etiqueta; las botellas del bar, de cada clase.
- Prueba `tests/detalle.gd`.

## 1.47.0 · 16 de octubre de 2026

Muebles a escala, sentarse a fumar, catar lo que quieras, estancos, la vitrina del grow, GAUA con el reservado arriba y cuatro locales como en las fotos (lo pidió el usuario: «el mobiliario debe de ser a escala realista para con el personaje, también en los clubs, casas y demás»; «que se pueda sentarse a fumarse uno, y opción de levantarse, lo mismo en los asientos de casa»; las fotos del taller, la panadería, el bar y la lavandería, y «¿por qué no estás usando la API de PixelLab?»). Solo Godot (0.41.0), con `Datos.CAL`: sin CAL, las pantallas del oráculo no cambian.

- **Los muebles a escala con el protagonista** (27 px = 1,70 m, 16 px/m) en casas, clubs, grows, la nave, el bajo, la discoteca y los locales.
  - Los que se quedaban cortos salen otra vez a su alto real (`tools/sprites/a-mano/escala.py`): `e-<sprite>` en `escala-alto` (32 × 48) y `escala-ancho` (48 × 48).
  - Así salen mesas, mostradores, barras, vitrinas, el banco, la gramola, las lavadoras, la caja de los locales y los sofás.
  - Con CAL, `_arte_obj` los cambia por los de siempre.
  - El box del lavadero mide 5 m, como los coches (`boxL`, `NEG_LARGO`).
- **Sentarse** en sofás, sillones, sillas, bancos y taburetes, en casa, en los clubs y en la calle (A delante del asiento: `ASIENTOS`, `asiento`, `sentado`).
  - El protagonista se sienta de frente o de espaldas según el asiento (`_pj_sentado`).
  - Desde el asiento puedes fumarte uno o levantarte. En las sillas de los ordenadores, también usar el ordenador.
  - **Fumarte uno** (`fumar_sentado`): gasta lo que pida la forma de fumar (ver más abajo) del lote que elijas y pasa un cuarto de hora, con el humo.
  - En la calle, el calor sube 3. En comisaría no; en el bar, la discoteca y los locales tampoco: «Aquí dentro no se puede fumar».
- **El taller, la panadería, el bar y la lavandería, como en las fotos del usuario:**
  - Los muebles salen de PixelLab (`create_1_direction_object`, solo con texto: las fotos llevan marcas y no se subieron). Están en `tools/sprites/pixellab-negocios/` y se ajustan a 16 px/m con `tools/sprites/a-mano/pixellab_negocios.py`, en los grupos `negocios-pl-alto`, `negocios-pl-ancho` y `negocios-pl-coche`.
  - Los suelos y las paredes están hechos a mano (`tools/sprites/a-mano/negocios2.py`, `interior-negocios`).
  - **El taller:** suelo de resina azul y pared blanca con la franja azul, blanca y roja. El elevador tiene las columnas azules (`e-elevT`). Hay un carro de herramientas rojo, la recogedora de aceite, una estantería de recambios de 2 m y cajas azules.
  - **La panadería:** baldosa gris clara y azulejo de metro. Tiene el horno de pisos, el carro de bandejas, el estante del pan con los cestos, la mesa de acero con la masa y el mostrador con las campanas y la cafetera.
  - **El bar:** suelo de pizarra, pared gris azulada y el machihembrado de pino. Tiene la barra de pintxos de mármol con la vitrina, el botellero con los vasos, la cafetera, taburetes de hierro negro (`e-stool`) y mesas de pino con sus sillas.
  - **La lavandería:** laminado gris y pared azul con burbujas. Tiene lavadoras y secadoras industriales de acero, la caja de pago (el género), la mesa de doblar y el carro de la ropa.
  - Las barras y los mostradores dejan hablar por encima (`COUNTERS`). Los de dos casillas están en `NEG_ANCHO`.
- **Catar lo que sea** (lo pidió el usuario: «que se pueda probar todo tipo de cogollos y extracción (catar 0.5, o la cantidad que sea hasta un límite lógico claro)»):
  - Desde la MOCHILA, cualquier lote de cogollos o de extracto: «Catar…» y la cantidad (`cata_cuanto`, `CATA_MAX`, `CATA_PASOS`).
  - Cogollos: 0,1, 0,25, 0,5 o 1 g de una vez. Extracto: 0,1, 0,2, 0,3 o 0,5 g. Nunca más de lo que queda.
  - Queda la nota de cata en el lote (`marca_cata`). Según los mg de THC, te deja tocado o mirando a la pared (`cata_efecto`).
  - Fumar también es catar.
- **Con qué se fuma** (`FUMAR`):
  - El porro necesita papel y mechero. Con tabaco lleva 0,3 g de hierba y 0,7 de tabaco; con el grinder, 0,4 g en vez de 0,5.
  - La pipa (0,2 g de cogollo o 0,1 de extracto) y el bong (0,3 g o 0,1) necesitan mechero.
  - El vaporizador (0,2 g o 0,1) no necesita mechero y en la calle sube el calor 1 en vez de 3.
  - Si tienes más de una forma, te pregunta «¿Cómo?»; si llevas más de un lote, «¿DE CUÁL?».
- **Un estanco en cada pueblo** (lo pidió el usuario: «uno en cada pueblo, para comprar, tabaco, papel y eso»; `ESTANCO`, `montar_estancos`, `est-<pueblo>`):
  - Están en una casa libre de cada pueblo, con la puerta de su fachada y el rótulo de la T colgado encima (`rotulo` en `blds`).
  - En el barrio alto es una casa nueva del Casco, en (21, 5).
  - Por dentro: terrazo, friso de madera, la estantería de las cajetillas (colores lisos, sin marcas), el mostrador con la vitrina de los mecheros, el humidificador de puros y el expositor del papel.
  - Atiende un estanquero o una estanquera (`est_<pueblo>`, `talk_estanco`) que vende el librillo de papel (50 hojas), los filtros, el tabaco de liar y el mechero.
- **Las pipas y demás, en el grow, en su vitrina** (`PARAFERNALIA`, una de cada):
  - Se venden el grinder, la pipa de cristal, el bong y el vaporizador.
  - Están en la vitrina iluminada de Kiko y en la de GROW IBARBIDE (`vitrinaP`).
  - Aparecen en la MOCHILA y tienen sus iconos (`iconos-fumar`).
- **Las mesas de los sofás de los clubs, de frente a 3/4 como los sofás y el billar** (lo pidió el usuario):
  - Cada par de mesitas es ahora una mesa baja de dos casillas (`w-mesita` y `w-mesita-<estilo>`).
  - Por estilo: la de siempre, el nogal con la vela (Kalea), el baúl de marinero (Itsaso), los dos bidones con el tablón (Fundición) y el cristal con las patas de acero (Ensanche).
- **El cajero del pueblo, fuera de detrás de la farola** (lo pidió el usuario: «está detrás de la farola… muévelo una baldosa a la izquierda y asegúrate de que no haya pasado en otros pueblos»): a (30, 8) (`CAJERO_CAL`). `tests/ocio.gd` repasa todos los mapas de calle: ningún cajero ni puerta tiene una farola delante.
- **GAUA, grande y con el reservado arriba** (lo pidió el usuario: «la discoteca tiene que ser más grande, el piso de arriba reservado, desde el que se ve el piso de abajo, en la cristalera del suelo, transparente»; `DISCO_CAL`, `montar_disco`):
  - **La planta baja**, de 22 × 12: la barra larga, la cabina del DJ entre dos altavoces, la pista de 8 × 5, dos rincones con sofá y la escalera al reservado con su cordón.
  - **El reservado, arriba** (`disco-vip`): moqueta, su barra con camarera, tres mesas con sofá, gente VIP y la escalera de bajada.
  - **La cristalera**, en el suelo, de 14 × 7 casillas: tapa la pista entera y lo de alrededor (lo pidió el usuario: «se tiene que ver algo más que la pista de baile solamente»). A través del cristal se ve la planta baja en su sitio, recortada al cristal: la pista con sus luces, el final de la barra, los altavoces, la gente que baila y la de alrededor (`gentD1`–`gentD3`, con sus frases en `DISCO_CAL.gente`; `_cristalera`).
  - Para subir hace falta la mesa del reservado de esa noche: la vende la RRPP y, al pagarla, te sube.
  - A las 6, el portero también echa a la gente del reservado.
  - Las escaleras están dibujadas a mano de frente (`escaleraD`, `escaleraDB`).
- El arte nuevo está dibujado a mano y siempre de frente a 3/4, nunca en isométrica (`tools/sprites/a-mano/ocio.py`). Los grupos son `iconos-fumar`, `interior-estanco`, `ocio-ancho`, `ocio-alto` y `ocio-16`.
- Prueba nueva `tests/ocio.gd` (61 comprobaciones; con `--pintar`, los estancos por dentro y por fuera, GAUA, el reservado, los clubs y los grows).
- Prueba nueva `tests/escala.gd` (32 comprobaciones; con `--pintar`, cada sitio y la gente sentada). `tests/negocios.gd` pasa a 299.

## 1.46.0 · 16 de octubre de 2026

Las cepas de setas y el taller a escala (lo pidió el usuario: «que se puedan comprar diferentes panes… diferentes micelios… como razas… juntar esos micelios y crear nuevas variedades… preestablecidas en un libro de recetas… que no se permita hacer ciertos cruces… son diferentes formas de las setas»; y «ya hay sprites de coches del concesionario, usa esas medidas para crear los fosos con las máquinas de levantar… a escala»). Solo Godot (0.40.0), con `Datos.CAL`. Las cepas son inventadas y genéricas: nada de método ni de dosis.

- **Doce cepas en cuatro formas** (`CEPAS` en `datos.json`): cúpula, campana, plato y racimo, cada una con sus colores, su rendimiento (×0,85 a ×1,35) y su precio (×0,9 a ×2,4).
  - Cinco panes de micelio que vende Txomin en la puerta (Txuria, Urrezko, Iluna, Adartxo y Gaztain; 20–40 €, `panes_txomin`).
  - Cinco de 2.ª generación (Ilargi, Ekaitz, Errota, Orri y Gautxori) y dos de 3.ª (Izar, la última del cuaderno, y Basoa).
- **La bandeja de tu cepa:** al comprar una bandeja, Txomin pone la Txuria o uno de tus panes (`S.setas.panes`). La bandeja dice su cepa y sus setas salen con su forma y su color.
- **Juntar micelios** en la mesa de trabajo (`juntar_micelios`, 2 h): dos panes dan dos de la cepa nueva, pero solo si la pareja está en el cuaderno (`CEPAS.r`).
  - El racimo no se junta con la cúpula ni con la campana: se repelen (`CEPAS.veta`).
  - Lo que no está en el cuaderno no prende. En los dos casos no se gasta nada.
- **El cuaderno de las cepas** en la mesa (`cuaderno_setas`): todas, con ✓ las que has tenido, su forma, de qué sale cada una y lo que no se junta.
- **Por cepa hasta la venta:** lo recogido se seca por cepa (`fr[].v`), el armario dice cuánto hay de cada una (`S.setas.gv`) y Txomin paga cada cepa a su precio. Los lotes de la mesa salen de la cepa de la que más hay.
- **El taller, a escala con los coches del concesionario** (16 px/m, 5 casillas como la exposición; grupo `negocios-coche`):
  - el elevador es de cuatro columnas, de 5 m, con las rampas a 1,2 m y el utilitario de 4 m subido;
  - el foso mide 5 m de largo, con la berlina de 4,8 m encima, la escalera y la lámpara;
  - el local pasa a 20 × 10. La segunda mejora pone la cabina de diagnosis y la equilibradora (`diagT`, `equiT`).
- Prueba nueva `tests/cepas.gd` (68 comprobaciones; con `--pintar`, las doce cepas en las baldas). `tests/negocios.gd` (287) comprueba el taller a escala.

## 1.45.0 · 15 de octubre de 2026

Los negocios por dentro y los mercados que compran y venden (lo pidió el usuario: «que tú puedas acceder a ese sitio y controlarlo desde ahí… tanto el taller como los demás negocios»; «un cuartucho donde haya una cama pequeña…»; «en el club se tiene que poder tanto comprar como vender extracciones y diferentes tipos de hierba… a todos los mercados»). Solo Godot (0.39.0), con `Datos.CAL`.

- **Cada local alquilado se entra por su puerta** (gate `neg:<k>`, `montar_locales`): el taller de Valdehierro, el lavadero de los astilleros, la taberna del puerto, la quesería de Mendialde, la panadería de Errotabarri y la lavandería de Ibarbide (`MAPS.loc-<k>`). La puerta es la que ya está dibujada en la fachada, con su estilo, su tamaño y en su sitio (lo pidió el usuario): la animación se recorta de la propia base (`edificio-ladrillo-pu`, `edificio-marinera-pu` y `edificio-casco-pu`, en `puertas_neg` de `mundo.py`; los caseríos, con la suya), y la prueba comprueba que, cerrada, calca la fachada píxel a píxel. Sin alquilar, «Cerrado: SE TRASPASA». El rótulo de la calle sigue para alquilarlo y, ya tuyo, manda dentro.
- **Por dentro, con su atrezo** (arte a mano en `tools/sprites/a-mano/negocios.py`): el taller con el elevador y el coche subido, el foso con la escalera, el banco de trabajo, el compresor, los recambios y los neumáticos; los boxes de lavado, los aspiradores y la máquina de fichas; la barra, los barriles y las mesas de la taberna; la cuba, la prensa, la cámara de curación y el mostrador de la quesería; el horno de leña, la amasadora y los estantes del pan; las lavadoras, las secadoras y la mesa de doblar. En cada uno, su empleado (Iker, Unai, Pello, Antxon, Itziar e Idoia).
- **Se lleva desde dentro:** la caja (meter efectivo, las cuentas, reponer género, las mejoras y dejar el local), el género en su estante y la fregona.
- **Un negocio que funciona** (`NEGOCIO`, `neg_venta`, cada mañana en `recibos_dia`): vende su base × la limpieza (baja 5 al día; la fregona, una hora, la deja en 100) × las mejoras (+30 % cada una) × el género (sin género, al 30 %) ± 15 %, y entra en la cuenta como ventas, además de lo que laves por la caja. Dos mejoras por local (se ven dentro), que suben también el tope de la caja un 50 % cada una.
- **Dormir fuera de casa:** el cuartucho del taller, detrás de un tabique, con cama, mesilla, escritorio y armario (cambiarte de ropa); y el camastro de la nave, al fondo.
- **El almacén del club** (asociación, de presidente; `almC`): guardas cogollos y extracciones hasta 2 kg y los socios retiran 40 g al día a precio de dispensario.
- **Mercados que compran y venden** (`MERCADO`, `comprar_mercado`, `mercado_lista`): los clubs, Iñaki y la lonja tienen cada día tres variedades y dos extracciones (rosin, dry sift, ice, charas o static) con sus gramos; y compran varios lotes al día hasta su tope (los clubs, 200 g; Iñaki, su carga; la lonja, sus 500 g el día que carga).
- Prueba nueva `tests/negocios.gd` (284 comprobaciones; con `--pintar`, cada local por dentro y su puerta en la calle).

## 1.44.0 · 15 de octubre de 2026

El bajo de las setas entero (lo pidió el usuario: «los sprites y todo para crear el piso bajo, donde se cultivan, se secan, almacenan y se crean microdosis y comestibles»). Solo Godot (0.38.0), con `Datos.CAL`. Nada de método ni de dosis: lotes y cajas, como el resto del bajo.

- **Muebles nuevos** (`montar_setas`, `SETAS_PRO.x`), dibujados a mano en `tools/sprites/a-mano/bajo.py`:
  - el armario de almacén (3, 2), con sus tres baldas a la vista según lo lleno (`armS-<b>-<m>-<c>`);
  - la mesa de trabajo (7, 5), con la báscula y, si las tienes, la encapsuladora y los moldes (`mesaS-<e>-<m>`);
  - el deshidratador (8, 2), con setas y el piloto cuando está secando (`deshidS-<0|1>`).
- **Secar:** lo que recoges se tiende a secar (`S.setas.fr`).
  - En la malla del secadero tarda 3 días; con el deshidratador (90 €, de Txomin), 1.
  - Seco, pasa al armario al amanecer (`secar_setas`). El secadero y el deshidratador dicen cuánto se seca y qué día pasa.
- **Almacenar:** A en el armario lo abre por dentro (`vista_armario`, `rects_armario`): los botes de setas secas (uno por cada 50 g), las cajitas de microdosis y las cajas de comestibles.
- **La mesa de trabajo:**
  - con la encapsuladora (120 €), un lote de 10 g secos hace una caja de microdosis (1 h);
  - con los moldes (45 €), el lote más 6 € de chocolate hace una caja de comestibles (1 h 30).
- **Vender:** Txomin, en la puerta, compra las cajas: 140 € la de microdosis y 150 € la de comestibles. Sube el calor 2 por caja, y la redada se lo lleva todo.
- Prueba nueva `tests/bajo.gd` (45 comprobaciones; con `--pintar`, el bajo amueblado y el armario por dentro).

## 1.43.9 · 15 de octubre de 2026

El bajo de las setas a la vista (lo pidió el usuario: «que puedas entrar al bajo y veas las setas crecer»). Como el carro de esquejes, ya no es un menú. Solo Godot (0.37.9), con `Datos.CAL`.

- **Las baldas por dentro:** A en una de las tres estanterías del bajo abre la vista de las seis bandejas, dos por estantería, arriba y abajo (`vista_bajo`, `elegir_bajo`, `rects_bajo`). Se mueve con las flechas. A abre lo de las bandejas (pulverizar, recoger o tirar) y después vuelve a las baldas; B cierra.
- **Se ven crecer:** cada bandeja está dibujada a mano por rectángulos (`_bandeja_seta`).
  - El micelio blanco cubre el sustrato día a día y hora a hora (`t_seta`).
  - Después salen los primordios, los tallos y los sombreros, que se abren; cada seta va a su ritmo.
  - Las gotas de la tapa dependen de la humedad, y se ve lo contaminado (verde) y lo seco.
  - Las setas son genéricas, sin especie ni método.
- **La elegida, en grande:** a la derecha, con la barra de humedad y la del ciclo (colonizar → fructificar). El texto dice la fase, el % de micelio o de setas, el día de 10 y la humedad.
- Prueba nueva `tests/setas_vista.gd` (26 comprobaciones; con `--pintar`, las capturas día a día).

## 1.43.8 · 15 de octubre de 2026

Dónde está el bajo de las setas (lo pidió el usuario: «no existe mapa y sitio del bajo de las setas»). El bajo ya estaba (Ibarbide → el callejón junto a GROW IBARBIDE → la Kale Zaharra → la puerta gris de Txomin), pero nada en el juego decía dónde. Solo Godot (0.37.8), con `Datos.CAL`.

- **SMS de Julen:** con Ibarbide abierta (cap. 4, `SETAS.ch`) y el bajo sin alquilar, una vez (`S.flags.setasSms`), el sitio y cómo se llega (`SETAS_SITIO.sms`; se guarda en los SMS del móvil).
- **MÓVIL → Mapa:** al elegir Ibarbide, la línea del bajo de las setas (`SETAS_SITIO.mapa`, `desc_mapa` en `croquis.gd`).
- **El cartel de la Kale Zaharra** (8, 10) añade dónde está la puerta del bajo (`SETAS_SITIO.cartel`).
- Prueba nueva `tests/setas_sitio.gd` (23 comprobaciones: mapas, puertas, que se llega andando de la parada a Txomin y a la puerta, el SMS, el mapa y el cartel, y nada sin `Datos.CAL`).

## 1.43.7 · 15 de octubre de 2026

Las extracciones se venden donde los cogollos (lo pidió el usuario: «las extracciones se deberían de poder vender al por mayor, en clubes y donde se pueda vender cogollos»). Solo Godot (0.37.7), con `Datos.CAL`.

- **Al por mayor:** Iñaki y la lonja de Puerto Viejo te compran también las extracciones que llevas encima, desde 10 g (`VENTA_EXTR.min`), a la mitad de lo que pagan los catadores en la calle (`precio_rosin` × el `px` de cada extracción × `VENTA_EXTR.mayor`; la lonja, con su 15 % más). La carga del día cuenta en gramos de flor (1 g de extracción = 5 g de flor, `ROSIN.rend`), y el calor también.
- **En los clubs:** el lote del día puede ser una extracción, de 10, 25 o 50 g (`VENTA_EXTR.club_g`), a tres cuartos del precio de la calle (`VENTA_EXTR.club`).
- **El dispensario de la asociación:** se le puede dejar una extracción; los socios retiran 5 g al día en vez de 20 (`VENTA_EXTR.dia`).
- En la calle siguen comprándolas los catadores, como antes. El curado cuenta en todos los precios (`calidad`).
- Prueba nueva `tests/extr_venta.gd` (27 comprobaciones).

## 1.43.6 · 15 de octubre de 2026

El camarote de arriba, de almacén (lo pidió el usuario: «habilitar el camarote de arriba, el piso de arriba, como almacén», con «botes más grandes de cristal con bóvedas de humedad»). Solo Godot (0.37.6), con `Datos.CAL`.

- **La obra** (tienda online → El camarote: almacén, con tarjeta, llega al día siguiente): habilitar el camarote, 3.500 €; la escalera escamoteable baja en el piso entre la carpa A y la B, debajo de la ventana (`escaleraC` en (9, 2), se usa desde (9, 3); ORDENAR no deja nada ahí, `reserva_orden`, y lo que estaba se recoloca).
- **Arriba** (`MAPS.camarote`, 10 × 6): tarima de pino, techo abuhardillado con dos ventanas de tejado, murete de pladur, deshumidificador y la trampilla para bajar.
- **Estanterías de tarros de 10 L** (180 €, hasta 4): 6 tarros de cristal de 290 g cada una (`CAMAROTE.est`, `cam_cap`). Curan los lotes como los tarros de Kiko, sin necesitarlos.
- **Sobres de humedad al 62 %** (36 € la caja de 12 sobres de 67 g): un sobre por tarro dura 60 días (`CAMAROTE.dura`); con sobres, lo curado se afina en 14 días (`af`): +10 % en todas las ventas (`calidad`). Se gastan por tarros ocupados al día, con aviso al acabarse.
- **La vista por dentro** (CAMAROTE, como la caja y la nevera): los tarros de 10 L por estante, GUARDAR, la ficha con curado y afinado (`items_almacen("cam")`, `rects_almacen`, `_guardar_cam`).
- **La redada** se lleva lo del camarote: el desván no está escondido como la caja.
- Arte a mano en `tools/sprites/a-mano/camarote.py` (casillas, estantería, escalera, deshumidificador) y `almacen.py` (el fondo del camarote, el tarro de 10 L y lo de dentro). Prueba nueva `tests/camarote.gd` (70 comprobaciones).

## 1.43.5 · 15 de octubre de 2026

El APK también para móviles de 32 bits (lo pidió el usuario, tras la revisión de Gemini). Solo Godot (0.37.5).

- `export_presets.cfg`: `armeabi-v7a` además de `arm64-v8a`; el APK pasa de 52 a 75 MB. Firma v1/v2/v3 verificada.
- De la revisión de Gemini, lo demás ya estaba bien: el atlas y la vista C se leen con `load_png_from_buffer` (por eso `importer="keep"`), las fuentes `.woff2` las carga `FontFile.data`, `icono/` y `musica/` los genera `godot:apk`, los `.json` van por `include_filter`, los tests se excluyen, las licencias OFL tienen que ir y `libc++_shared.so` es de la plantilla oficial.

## 1.43.4 · 15 de octubre de 2026

Exportar e importar la partida, más escondidos (lo pidió el usuario). Solo Godot (0.37.4), con `Datos.CAL`.

- En OPCIONES ya no salen EXPORTAR PARTIDA ni IMPORTAR PARTIDA: van en COPIA DE SEGURIDAD, la última fila antes de VOLVER (`copia_seguridad` en `juego.gd`); en el título, solo importar. Siguen ahí para pasar la partida a otro móvil.
- Prueba nueva `tests/copia.gd`.

## 1.43.3 · 15 de octubre de 2026

Cada nombre con su muñeco (lo pidió el usuario: «los nombres de chica tienen que ir con personajes chica, y los chicos lo mismo»). Solo Godot (0.37.3), con `Datos.CAL` (las pruebas contra el HTML, como antes).

- **Los presidentes de los clubs:** Xabier (Itsaso) y Eneko (Kalea) salían con muñeco de chica y Rosario (La Fundición) y Nagore (Ensanche) con muñeco de chico; ahora Xabier de traje, Eneko de chico, Rosario la señora del moño gris y Nagore la de la melena (`GENERO.look`).
- **Bixente** (Mendialde), con muñeco de chico.
- **La agenda:** el nombre que le pones a un cliente de la calle es del sexo de su muñeco (`nombre_fijo`); y la chica que compra caro es la PIJA, y la del rosin, la CATADORA (`etiqueta_ct`).
- **La nave:** cada navero y quien cuida las madres sale con un muñeco de su sexo (Jaione, Edurne, Amaia… de chica; Mikel, Koldo… de chico; `look_genero`).
- **Yolanda**, la rival del Ensanche, ya no sale con barba (`look_rival`).
- **Los clubs:** en La Fundición y en el Ensanche quien está en la puerta es una mujer: «la encargada» en los textos (`con_encargada`, `GENERO.enc`), y las socias que hablan en el club salen como SOCIA.
- Prueba nueva `tests/generos.gd` (417 comprobaciones).

## 1.43.2 · 15 de octubre de 2026

Lo que cuesta tener un vehículo (lo pidió el usuario: «los coches y la moto sirven para no pagar el autobús para ir de pueblo a pueblo; el gasto es la gasolina, eso sí. Gasto al año de seguro y más cosas, igual al mes o por cierto uso de distancia»). Solo Godot (0.37.2).

- **Sin billete:** con tu vehículo, de parada en parada no pagas autobús, solo la gasolina del tramo (como en la 1.43.0).
- **El seguro, al año** (`seguro_anio`, `CONCE.anio`): se paga el año entero al firmar y se renueva domiciliado cada 365 días. Sin saldo, devuelto y, pasada la gracia, anulado, como antes.
- **El impuesto de circulación** (`CONCE.v[k].ivtm`, `S.coches[k].iv`): un recibo al año, domiciliado, desde el día de la entrega, según la potencia fiscal y con cuotas de ayuntamiento de hoy: 9 € la moto, 62 € el utilitario, 128 € la berlina y 232 € el superdeportivo. Sin pagar, devuelto y, pasada la gracia, por apremio con un 20 % de recargo (`CONCE.recargo`), cobrado de la cuenta, de lo que llevas y de la caja.
- **El taller, por km** (`kilometros`, `S.coches[k].km`): cada viaje suma sus km y, al pasar cada tramo, el taller cobra con su SMS:
  - la revisión (aceite y filtros): la moto cada 6.000 km (120 €), el utilitario y la berlina cada 15.000 (220 € y 320 €) y el superdeportivo cada 10.000 (1.600 €);
  - los neumáticos: la moto cada 12.000 km (160 €), el utilitario cada 40.000 (300 €), la berlina cada 35.000 (480 €) y el superdeportivo cada 15.000 (2.200 €).
- La ficha de cada vehículo dice lo que cuesta al año y por km; el seguro y el impuesto salen en la banca y en el calendario; al venderlo, sus km.
- `cobra` admite el campo de la fecha (`f`, «r» por defecto), para llevar dos recibos en el mismo vehículo.
- **Pruebas:** `tests/concesionario.gd`, 94 comprobaciones (el seguro al año, el impuesto y su apremio, los km y el taller a los 15.000 y a los 40.000).

## 1.43.1 · 14 de octubre de 2026

Vehículos de juguete y ruedas con llanta (lo pidió el usuario: «cuando está montando en la moto parece una bici», «no haría los coches tan realistas porque son demasiado grandes; debe ser un estilo y una escala lógica para con el personaje», «muy finas las ruedas de la moto; en sí son finas todas las ruedas, sin llanta casi»). Solo Godot (0.37.1).

- **La moto, un scooter:** gordito, con el culo redondo, el escudo azul curvo, el piso tapado, el guardabarros, los espejos y las ruedas pequeñas y gordas. Vas sentado: se te ve de la cadera para arriba (`VEHICULOS.moto`: `sube` 3, `corta` 25).
- **Los coches, de juguete:** más cortos y redondos, con la burbuja de la cabina, el techo redondo, los faros redondos y los pasos de rueda. Del tamaño del protagonista sentado, no de un coche de verdad.
  - El utilitario y la berlina con techo: se te ve la cara por el parabrisas. La visera de la gorra ya no se sale del cristal: con `cabina`, `_en_cabina` en `pinta.gd` solo pinta al protagonista por dentro de la cabina.
  - El superdeportivo, descapotable, con el parabrisas más bajo para que se te vea la cara de frente.
- **Ruedas gordas y con llanta** en todos los vehículos (`rueda_lado`, `rueda_frente` en `vehiculos.py`): contorno, goma y llanta clara con el buje y los radios que giran. De frente, la banda de goma más ancha con su dibujo. También en la bici y el patinete.
- **Pruebas:** en `tests/pantallas.gd`, la calle con la bici y con el patinete ya no son las del HTML congelado: lo que cambia tiene que quedarse dentro de la celda del vehículo (32 × 32) y todo lo demás, igual (`RUEDAS`).

## 1.43.0 · 14 de octubre de 2026

Ventanas centradas, el concesionario del barrio y las bandejas de clones de la nave (lo pidió el usuario: «esos pop-up o pestañas tienen que estar centradas como la nevera y la caja fuerte», «abren un concesionario en el barrio y puedes comprar una moto, un coche sin más, uno de gama media y un superdeportivo ya cuando tengas mucho dinero, precios realistas y todas las mecánicas realistas, espacio y lugar del concesionario con el atrezo, los coches y vehículos en venta», «en la nave debería haber bandejas de clones también, ¿no?»). Solo Godot (0.37.0).

- **Ventanas centradas** (`croquis.gd`: `LIBRE`, `centro_y`, `origen_mapa`/`origen_cal` con el alto libre; `alto_libre` en `ui.gd`):
  - El calendario y el mapa del móvil van centrados como la nevera y la caja: a lo ancho y, a lo alto, en lo que deja el cuadro del texto, sin que lo pise.
  - El mapa ya no lleva pestaña con el nombre encima del croquis, y sus textos son más cortos (como mucho tres marcas en el calendario: «y N más»).
  - El cuadro del texto ya no sale gigante la primera vez (se recoloca en el fotograma siguiente).
- **AUTOS RIBERA, el concesionario** (`D.CONCE`; `montar_alto` en `mundo.gd`; `talk_conce`, `comprar_coche`, `vender_coche`, `asegurar_coche`, `conce_dia`, `conducir`, `tramo`, `control_trafico` en `trama.gd`):
  - Abre en el barrio alto, al lado de la asociación, desde el capítulo 5 y con 20.000 € entre efectivo y cuenta. Avisa por SMS. Antes, el barrio alto está como siempre.
  - Por fuera: fachada con dos escaparates, el rótulo, la puerta de cristal de dos hojas, la acera y dos banderolas. Por dentro (18 × 10): suelo de baldosa, la pared con la franja azul, el rótulo, los precios, la cafetera, el expositor de catálogos, los neumáticos, plantas, la mesa de Arantxa (la comercial) con su ordenador y un cliente mirando.
  - A la venta, a precios de hoy con IVA: scooter de 125 cc (3.490 €), utilitario (15.900 €), berlina de gama media (34.500 €) y un superdeportivo de motor central (245.000 €). Todo el arte es propio y sin marcas.
  - Aparte, el impuesto de matriculación por emisiones (0 % hasta 120 g de CO2/km, 4,75 %, 9,75 % y 14,75 % desde 200 g, sobre el precio sin IVA; la moto, exenta) y 300 € de gestoría y placas.
  - En efectivo, como mucho 1.000 € (Ley 11/2021); el resto, por transferencia desde la cuenta.
  - Se entrega a los días de matricularlo (la moto en 2, el utilitario en 5, la berlina en 7) y el superdeportivo, bajo pedido, en 30. El superdeportivo, además, sube el calor: en el barrio se habla.
  - El seguro (de 190 € al año la moto a 4.900 € el superdeportivo) va domiciliado cada mes y sale en la banca y en el calendario. Sin saldo, el recibo se devuelve y, pasada la gracia, la póliza se anula.
  - Con un vehículo, en cualquier parada de autobús eliges «¿Cómo vas?»: vas a cualquier hora, sin esperar, en menos tiempo que el autobús, y pagas la gasolina por los km de cada tramo y el consumo del vehículo (1,60 €/l).
  - A veces hay control de tráfico (el superdeportivo, el triple). Sin seguro: 1.500 € de multa y el vehículo a la grúa hasta que lo asegures. Con algo encima, si te registran, te lo requisan con su multa.
  - Se puede revender: pierde un 20 % al salir del concesionario y un 1,2 % cada mes, hasta el 30 % de lo que valía. Lo pagan por transferencia.
  - La moto, además, se lleva en la calle: vas montado, más rápido que en bici. No se vende en la tienda online.
- **Los coches por la calle, a escala de juguete** (lo pidió el usuario: «este rollo de que el coche sea más bajo que el personaje mola, aunque no van a ser todos descapotables, con lo que habría un conflicto con el personaje y el techo del vehículo»; `VEHICULOS.utilitario`/`berlina`/`deportivo` con `sube` negativo y `corta`, `_pj` en `pinta.gd`):
  - El utilitario, la berlina y el superdeportivo también se llevan por la calle, más bajos que el protagonista de pie, y con el mejor que tengas (el superdeportivo, la berlina, el utilitario y la moto, por ese orden). El que está en la grúa, no.
  - El utilitario (blanco) y la berlina (gris) llevan techo: el protagonista va sentado dentro, de la cintura para arriba, y se le ve la cara por el parabrisas, con dos reflejos en el cristal; de espaldas, la nuca por la luna de atrás.
  - El superdeportivo (rojo) es descapotable: la cabeza y los hombros asoman por encima del parabrisas bajo, con el respaldo detrás y el alerón.
  - Cuanto más caro, más rápido (y con B, aún más).
- **Las bandejas de clones de la nave** (`S.nave.bc`; `corta_bandeja`, `bandejas_listas`, `bandejas_nave` en `trama.gd`):
  - Un carro con dos baldas, sus tubos T5 y sus bandejas con tapa, contra la pared, entre el secadero y el escritorio.
  - Antes de pasar cada mesa a 12/12, quien la cuida le corta 24 esquejes y los pincha en una bandeja. Echan raíces en un día (al ritmo del juego, como las mesas) y, al cosechar, la mesa vuelve a empezar con ellos.
  - Con A, el carro te enseña cada bandeja: de qué mesa es, la variedad y si ya tiene raíces. Las enraizadas también se pueden plantar a mano en una mesa vacía.
  - El carro se ve más o menos lleno según las bandejas.
- **Arte** (todo a mano y propio): `tools/sprites/a-mano/concesionario.py` (la fachada, el suelo y la pared, el rótulo, los precios, los neumáticos, los catálogos, la cafetera, las banderolas, la mesa, los cuatro vehículos de exposición y el carro de bandejas) y la moto y los tres coches (atrás y delante, en tres direcciones) en `vehiculos.py`.
- **Pruebas:** `tests/concesionario.gd`, 78 comprobaciones: los precios, el impuesto, la apertura, el edificio y su vuelta atrás, que se llega a todo, la compra con el tope de efectivo, la entrega, el seguro (cobrado, devuelto y anulado), el viaje, el control, la grúa, la reventa, el superdeportivo, la moto y los coches en la calle, las bandejas de clones y los renders. `tests/calendario.gd` comprueba el centrado (44 con los renders).

## 1.42.0 · 14 de octubre de 2026

El calendario de verdad, el mapa de la comarca y el juego en WordPress (lo pidió el usuario: «que empiece el juego el 20 de abril de 2026, y de ahí se van sumando días; 7 días son 1 semana; haz todos los días del mes y del año», «un mapa donde se vean todos los pueblos, no detalladamente pero modo croquis texturizado» y «convierte el juego en un plugin para WordPress como este, actualizado»). Solo Godot, 0.36.0.

- **El calendario** (`datos.gd`: `CAL`, `CAL0`, `fecha`, `dia_de`, `fd`, `fd_corto`, `fd_hud`, `fd_larga`):
  - El día 1 de la partida es el lunes 20 de abril de 2026. Cada día suma uno: semanas de lunes a domingo, meses con sus días (30, 31, 28 y 29 en los bisiestos) y años.
  - El HUD, el menú START y el móvil dicen el día de la semana y la fecha («LUN 20 ABR · 08:00»).
  - Los plazos, los recibos, los encargos, las primas, la asamblea, los esquejes, los logros y la banca dicen la fecha («antes de que acabe el 1 de mayo»). Si cae en otro año, lo dicen también.
  - El mes del clima de la sala es el del calendario (`Cultivo.mes_de`).
- **El calendario en el móvil** (MÓVIL → Calendario; `elegir_cal`, `marcas_cal` en `trama.gd`; `rects_cal`, `desc_cal`, `mueve_cal` en `croquis.gd`):
  - Muestra la hoja del mes, de lunes a domingo, con hoy en amarillo, los días pasados apagados y los domingos en rojo.
  - Marca los días señalados: el plazo de Don Baltasar en rojo, los recibos en azul, los encargos en verde y la asamblea en morado. Debajo salen con su texto.
  - Con las flechas cambias de mes.
- **El mapa de la comarca** (MÓVIL → Mapa; `elegir_mapa` en `trama.gd`; `croquis.gd`):
  - Es un croquis en papel con su grano: el mar con olas, la costa, la ría de Ribera Verde con las grúas de los astilleros, los montes de Mendialde, bosques, los campos y el molino de Errotabarri, las chimeneas de Valdehierro, el muelle de Puerto Viejo y la cuadrícula del Ensanche de Ibarbide.
  - Lleva las líneas de autobús a trazos desde Ribera Verde, con sus minutos. Los pueblos sin línea todavía salen en gris.
  - Marca dónde estás con una chincheta.
  - Con las flechas eliges un pueblo y te dice qué hay y cuánto cuesta el autobús.
  - La fuente de letras de 3 × 5 y todo el dibujo son propios.
- **Pruebas:**
  - `tests/calendario.gd`, 35 comprobaciones: el 20-4-2026 lunes, semanas de 7 durante 800 días, el 1 de mayo, el año nuevo, el 29 de febrero de 2028, el mes del clima, los textos, el calendario y el mapa dentro de la pantalla, los pueblos cerrados en gris y los renders.
  - Las pruebas contra el HTML congelado (historia, C1, capas y pantallas) ponen `Datos.CAL = false` y siguen como antes: «día N» y un mes por día.
  - `historia.gd` quita las dos filas nuevas del móvil (`NUEVO_MOVIL`).
- **La nave con opción a compra** (lo pidió el usuario: «cuando seas presidente de la asociación del barrio, alquilas con opción a compra la nave, por la tranquilidad; cada mes te da la opción de comprarla a tocateja, a un precio realista»). Está en `opcion_nave`, `comprar_nave`, `resto_nave`, `gastos_nave` y `nave_alquiler` (`trama.gd`), con los datos en `NAVE.compra`.
  - Siendo presidente, Arrieta te ofrece la opción. El día 1 de mes manda un SMS y, en la nave, sale «Opción a compra».
  - El precio es de 220.000 € por 320 m² en el polígono, unos 690 €/m². El alquiler de siempre, 60 € al día, son unos 1.800 € al mes (5,6 €/m²).
  - La prima es de 10.000 €, por transferencia, y se descuenta. La mitad de cada alquiler va a cuenta. El precio no se mueve.
  - Los 7 primeros días de cada mes puedes comprarla a tocateja con lo que falte más un 5 % de gastos (transmisiones, notario y registro), por transferencia desde la cuenta. Te devuelven la fianza.
  - El primero de mes, Arrieta manda un SMS con lo que queda. El calendario marca cuándo se puede comprar.
  - Comprada, no hay alquiler, ni recibo, ni cerradura que cambiar. Si dejas la nave antes, pierdes la opción.
  - Prueba: `tests/compra.gd`, 26 comprobaciones.
- **WordPress:** el plugin `landrace-hunters` 1.3.0 (`wordpress/`, `tools/wordpress.js` → `descargas/landrace-hunters-1.3.0.zip`).
  - Sirve la versión web del juego Godot de hoy (motor 4.3 sin hilos y el `index.pck` de esta versión, con la música).
  - Sigue igual que el plugin 1.2.0: dirección propia a pantalla completa, el atajo `[landrace_hunters]`, instalable como app y el panel de ajustes.

## 1.41.0 · 14 de octubre de 2026

La nave, por ciclos de cultivo, y la caja fuerte con los tarros que se llenarían de verdad (lo pidió el usuario: «el cultivo en la nave no funciona por ciclos; es muy importante que sea realista, también en el visor de la caja»). Solo Godot, 0.35.0.

- **Cada mesa, un ciclo entero** (`nave_dia`, `prog_mesa`, `cosecha_mesa`, `dias_mesa` en `trama.gd`):
  - Los clones de la madre entran en la mesa enraizando (`NAVE.clon`, 0,12, como los esquejes del piso). Crecen a 18/6 y florecen a 12/12 al ritmo de su variedad: 1/d por mañana, como las plantas del piso. La Skunk #1 tarda 3 días (unas 10 semanas reales); una sativa como la Kali Mist, 4.
  - Las fases salen del ciclo (`fase_mesa`): esquejes enraizando, vegetativo (18/6), floración (12/12) y cogollos engordando.
  - Al acabar, el navero corta la mesa entera y la cuelga en el secadero. Luego vuelve a empezar con los esquejes que sacó antes de pasarla a 12/12 (`Me.n`, el ciclo).
  - Sin navero, la mesa no avanza.
- **La cosecha, con cifras reales:**
  - El cálculo: los vatios de los focos × los g/W de cada luz (`FOCO_NAVE.w`, `gpw`), por la variedad y el fenotipo, el cuidado del navero, el riego y el calor.
  - Los focos: LED de barras 2 × 720 W a 0,85 g/W, como el LED 720 del piso; sodio 2 × 600 W a 0,55; cerámica 4 × 315 W a 0,7.
  - Una mesa de LED con la Skunk #1 da unos 1,4 kg por ciclo.
  - El abono cuenta por los días del ciclo que lo tuvo (`Me.am`, `Me.ao` de `Me.dn`).
  - Antes, cada mesa daba 20 g al día para siempre.
- **El secadero:** lo cortado cuelga `NAVE.seca` (1) día secándose (`Me.h`). A la mañana siguiente pasa a lo que se descuelga, con el día de la cosecha para el curado.
  - Mientras se seca, no se puede descolgar ni replantar la mesa.
  - La redada también se lo lleva.
- **Textos:**
  - Cada mesa y el escritorio dicen la fase, cuántos días faltan para la cosecha, el ciclo y lo que cuelga.
  - El navero explica cómo trabaja, y su ficha, cuánto da la cosecha con su cuidado.
  - El sodio ya no dice «más gramos»: da menos por vatio que los LED.
- **La caja fuerte, por tarros de verdad** (`items_almacen`):
  - Cada lote ocupa los tarros que llenaría: de 4 L, `ALM.tarro` = 115 g sin aplastar. 300 g son tres tarros (115 + 115 + 70), y cada uno se ve lleno a su nivel.
  - El texto dice en cuántos tarros va y cuánto lleva el elegido. Sacar sigue sacando el lote.
- **Las mesas de antes** (por días, sin ciclo) siguen igual hasta la primera mañana: entran en el ciclo casi al final y se cosechan.
- **Pruebas:**
  - `tests/nave.gd` (32 comprobaciones, en la batería): plantar, las fases día a día, la cosecha contada aparte, el secado, descolgar, el abono entero y a medias, sin navero, sodio < cerámica < LED, la sativa más larga, la mesa de antes, la redada con lo colgado y los tarros de la caja. Con `--pintar`, la caja llena.
  - La historia compara con el HTML congelado sin la parte de la nave de antes (`NAVE_DESDE`, `NAVE_R`, `PLANTA_NUEVA`, `SODIO_ANTES`). Esa parte la comprueba ahora con las cifras nuevas.
  - Las PNG de `caja-dentro` y `caja-guardar` de `tools/ref/pantallas/` son ya de Godot.

## 1.40.1 · 14 de octubre de 2026

Los esquejes de las bandejas, esquejes de verdad (lo pidió el usuario: «así es solamente una hoja; eso no es un esqueje»). Solo Godot, 0.34.1.

- **`CLON`, de 13 × 12 a 15 × 15:** el tallo largo, dos hojas de cannabis abiertas a los lados con sus peciolos, el brote de arriba y dos brotes en el tallo, como la referencia.
- **Las bandejas, sin el hueco de antes:** la tapa, encima de los esquejes, y las filas de tacos a 22 px para que quepa el esqueje entero; el carro mide lo mismo.

## 1.40.0 · 14 de octubre de 2026

El carro de esquejes, a la vista (lo pidió el usuario: «que no sea un menú; que se vea la bandeja, una arriba y una abajo»). Solo Godot, 0.34.0.

- **El carro por dentro** (`rects_carro`, `elegir_carro` en `trama.gd`; `pinta.gd` lo dibuja con `CARRO_V`): el carro con sus patas y ruedas y dos bandejas, la de arriba y la de abajo, cada una con su tubo T5, su tapa transparente y 12 alvéolos negros (6 × 2) con su taco de turba. Los 24 tacos se llenan por orden y cada esqueje sale en el suyo, dibujado a mano a 1 px: el tallo y una hoja de cannabis de 7 dedos con su nervio (`CLON`, `_esqueje`, `_taco`; en el propagador, `CLON_MINI`), del color de hoja de su variedad; el que está en su último día, amarillento (lo pidió el usuario al verlos: «eso no parecen clones de cannabis»).
  - Flechas para elegir el taco (`mueve_carro`), A para usarlo y B para cerrar; abajo, el texto del elegido (`desc_carro`).
  - A la derecha, el elegido en grande (`CLON_G`, 48 × 40, de `tools/sprites/a-mano/esqueje.py`; con la imagen de referencia del usuario): el tallo largo, cuatro hojas de cannabis de 7 dedos —las de atrás en sombra— y dos brotes, en su taco de turba suelto, con las raíces asomando por debajo según los días que lleva (`RAICES`); debajo, una barra con los días que le quedan y el propagador con los esquejes que esperan.
- **A en un taco vacío pincha** los del propagador (los mismos textos de antes: los que caben y los que se quedan); **A en un esqueje**, nombrarlo o tirarlo, como antes. Sin menú.
- **La cruceta, más ergonómica** (lo pidió el usuario: «más espaciadas las flechas del cuadrado del medio»): cada flecha es una tecla suelta con sus cuatro esquinas redondas, separada del cuadrado del medio por un hueco (`CRUZ_HUECO`, 0,16 del brazo, en `ui.gd`); el cuadrado del medio, redondeado y con su borde. La zona de toque no cambia: la flecha sale del ángulo desde el centro.
- **Pruebas:** `tests/carro.gd`, sin el HTML (24 comprobaciones: la rejilla y sus bordes, el dibujo de los 24 tacos, el marco del elegido, el del último día, todo dentro de la pantalla, pinchar, el carro casi lleno, tirar un esqueje, el taco vacío sin propagador; con `--pintar`, cuatro capturas).
  - La historia compara con el HTML congelado sin el texto ni el menú del carro de antes (`CARRO_FUERA`; el taco se elige con `gancho_carro`).

## 1.39.0 · 14 de octubre de 2026

La nevera, a tamaño de nevera (lo pidió el usuario: «cómo se van a poder meter solo 200 g en una nevera»; eligió la opción B). Solo Godot, 0.33.0.

- **La nevera de serie, 1 kg** (`NEVERA.g` en `datos.json`; antes, 200 g).
- **Arcón congelador en la tienda online:** 320 €, con tarjeta. Llega al día siguiente y lo dejan enchufado al lado de la nevera: caben 5 kg más (6 kg en frío).
  - Como la caja empotrada, no es un mueble aparte: se abre desde la nevera, que lo cuenta todo (`nevera_cap`, `S.nevera.arcon`: el día de llegada en negativo mientras está pedido, 1 en casa).
  - La redada vacía la nevera, pero el arcón se queda.
- **Botes de 40 g** (`NEVERA.bote`): lo que se ve dentro de cada bote ya no depende del tamaño de la nevera.
- **Pruebas:** `tests/nevera.gd`, sin el HTML (23 comprobaciones: 1 kg de serie, la fila de la tienda, sin dinero no se pide, cobro, llegada al día siguiente, 6 kg y el aviso, en casa, redada y partida guardada).
  - La historia compara con el HTML congelado sin la fila nueva de la tienda (`NUEVO_TIENDA`).
  - Las referencias de `nevera-dentro` y `nevera-guardar` pasan a ser las de Godot, con la nevera de 1 kg y los botes de 40 g.

## 1.38.0 · 14 de octubre de 2026

Cada extracción se ve mientras se hace (lo pidió el usuario: «que sea visual»). Solo Godot, 0.32.0.

- **Encima de la barra, la escena del paso** (`escena_extr.gd`, 160 × 76). Las máquinas son las del piso (`extraccion.py`), con sus colores y sus piezas, a 3 o 4 veces su tamaño, y se mueven como en el proceso de verdad. Abajo, a la derecha, un punto por paso: el de ahora, en verde.
- **Ice-o-lator en lavadora:** la lavadora de carga superior, con la cuba azul translúcida.
  - Al cargar, entra el agua con hielo y el termómetro marca la barra (por debajo de 4 °C).
  - En el lavado, a baja velocidad, los cogollos y los cubitos dan vueltas dentro, a un lado y al otro, con espuma; la lavadora tiembla y su luz verde parpadea.
  - En el reposo, la manguera desagua al cubo de las bolsas.
  - Al recoger, cada bolsa (120, 90 y 73) sube, escurre y deja la resina en el fondo, y pasa al tamiz de secar.
- **Ice-o-lator a mano:** el cubo de 20 L con las bolsas colgadas del borde, abierto por delante.
  - El hielo flota y el termómetro está a 1–3 °C.
  - La pala de madera remueve 15 minutos, con su reloj de cocina.
  - Se saca cada bolsa, de la de trabajo (220) a la fina; escurre y la resina va con la cuchara al cartón.
  - Al final, se desmenuza con el colador y se seca al aire del ventilador.
- **Dry sift:** el bastidor de madera con la seda (el de los tamices del piso).
  - Los cogollos desmenuzados saltan encima mientras las manos lo menean.
  - El polen cae al papel de cocina de la mesa: verdoso en el de 220, dorado en los finos.
  - El montón crece, la malla se cierra en cada paso y los tamices que quedan esperan apilados.
  - En el último paso, la tarjeta lo junta.
- **Rosin:** la prensa de palanca roja con sus planchas.
  - Al precalentar, la luz parpadea y el brillo es la barra.
  - Al apretar, la palanca baja despacio, la bolsa se aplasta y el rosin sale por los lados del papel.
  - Al soltar, el papel sale con el charco y se recoge con la herramienta.
- **Charas:** las palmas frotan la cola de la planta viva, en el monte, y se van oscureciendo. Después se rasca la resina y se amasa la bola.
- **Hachís prensado:** el kief envuelto en papel, tibio en la misma prensa. Al apretar se vuelve una placa marrón.
- **Moonrock:** el rosin se funde en su bote sobre la placa. El cogollo se baña con las pinzas, se reboza en el kief del cristal y se seca en la rejilla.
- **Static:** la máquina negra con su bandeja, las guías y la pantallita.
  - La flor congelada se tamiza a la bandeja.
  - La placa se carga con el paño y saltan chispas.
  - La altura de la placa es la barra: lejos, no sube nada; a su altura, suben las cabezas; demasiado cerca, sube también la hoja.
  - Al final, la tarjeta rasca la placa.
- El proceso se ha mirado en guías de extracción sin disolventes (agua con hielo a 1:1 y por debajo de 4 °C, 15–20 minutos suaves, reposo y bolsas de la gruesa a la fina; tamices de seda y flor congelada; papel de horno y presión poco a poco; carga estática; charas de la planta viva; moonrock bañado y rebozado).
- `extraer` pasa a `tiro_billar` la extracción y el paso (`TIRO.esc`, `paso`, `n`). El billar y las pantallas de antes no los llevan y no cambian.
- Prueba nueva, `tests/extracciones.gd`: en cada tipo y paso (28 escenas) comprueba que la escena se pinta y se mueve.

## 1.37.0 · 14 de octubre de 2026

Ordenar la casa, la asociación y la nave (lo pidió el usuario). Godot, 0.31.0.

- **La nevera, en su sitio.** De serie va entre la planta y el ordenador de la tía (2, 2), y abajo queda sitio para la esquina de los procesados. Con la tercera carpa montada, a su sitio de reserva (0, 6).
- **ORDENAR LA CASA** desde la mesa redonda, en cuanto se ha leído la carta: la nevera, la mesa redonda, las dos plantas, la mesa de manicurar, cada máquina de extracción, la tele, el PC gaming (con su silla), el sofá, el sillón, el carro de esquejes y la alfombra. Con las flechas se lleva, A la deja si cabe y B la devuelve a donde estaba. No cabe encima de otra cosa, en el hueco de una carpa ni cortando el paso (desde la puerta, a la cama y a todo lo que se usa); el motivo sale en el cuadro. La cama, la caja fuerte, el ordenador de la tía y lo de las paredes no se mueven.
- **ORDENAR EL LOCAL** en la asociación, siendo su presidente, desde una mesita: los sofás con sus socios, el billar con su jugador y la lámpara encima, la librería, la gramola y las plantas. El dispensario no se mueve.
- **ORDENAR LA NAVE** desde el escritorio: las cuatro mesas (con su foco, sus poleas y su trabajador) y el tanque del riego con el controlador y la máquina. La manguera sale del tanque por el pie de la pared y baja a cada mesa por el suelo libre, por el camino más corto. Una mesa o un tanque que la dejen sin camino no caben.
- La gente no se pisa: nadie se queda sin poder hablarle (desde al lado o por encima de un mostrador) y no se cuenta como paso libre; la planta de la entrada de la asociación se queda en su sitio de serie.
- Lo elegido se guarda en `S.coloca` (`12d-orden.js`: `ORDEN_P`, `posPieza`, `cabePieza`, `moverPieza`, `rutaRiego`, `mangueraNave`). Godot: `mundo.gd` (`pos_pieza`, `cabe_pieza`, `aplica_orden`, `ruta_riego`, `manguera_nave`) y `trama.gd` (`mover_pieza`, `ordenar`).
- Pruebas: un paso más en la historia (120) y tres pantallas (casa-orden, nave-orden y club-orden, 62).

## 1.36.2 · 14 de octubre de 2026

El taller de extracciones, contra la pared, y lo de dentro de los tarros y botes, como es de verdad (lo pidió el usuario). Godot, 0.30.2.

- **El paso, libre.** La lavadora, el cubo de mallas, la máquina de static y la mesa de manicurar (ahora en (4, 7)) van en fila contra la pared de abajo, a la izquierda de la puerta, y la prensa y los tamices, a la derecha (`MUEBLE_EXTR`): del salón y las carpas a la nevera y la cama se pasa por el medio sin rodeos.
- **Los cogollos, pelados o sin pelar.** Lo que se ve dentro de cada tarro depende del lote: manicurado (`alm-cog-p`: cogollos limpios, redondos y con más escarcha) o sin pelar (`alm-cog-s`: con las hojitas de azúcar asomando), siempre en el color de la variedad, con los pelos naranjas, y a cuatro niveles según lo lleno que está.
- **Cada extracción, la suya** (`alm-x-<tipo>`, cuatro niveles): el rosin fresco, ámbar y translúcido como savia, con su brillo; el rosin curado en frío, opaco y cremoso (badder); el tamizado en seco, un montón de arena rubia; el ice (bubble hash), arena rubia en grumos; el charas, bolas oscuras amasadas a mano, con el brillo de la grasa; el hash prensado, en placas marrones apiladas; el moonrock, cogollos bañados en aceite y rebozados en kief; y la static, un polvo finísimo, casi blanco.
- `tarro(…, den, k, v)` y `dentroLote` en `11m-almacen.js` (Godot, `_tarro` y `_dentro_lote` en `trama.gd`); arte a mano en `tools/sprites/a-mano/almacen.py`.
- Fuentes del aspecto: trimleaf.com (hash 101, tipos de hash), weedmaps.com (fresh press, cold-cure badder y jam), floraflex.com (cogollos manicurados o no), thebluntness.com (moon rocks) y la Junta de Control de la Marihuana de Alaska (dry sift); el charas y la static, por su descripción habitual.

## 1.36.1 · 14 de octubre de 2026

Los tarros y la nevera, más realistas (lo pidió el usuario). Godot, 0.30.1.

- Los tarros de cogollos (`alm-tarro`, `alm-tarro-s`): de cristal, con la tapa de rosca estriada más ancha que el cuello, los hombros y el culo redondos, el culo grueso y sus brillos. Por dentro, los cogollos apilados (`alm-cogos`: cada uno con su sombra, la escarcha arriba y algún pelo naranja, sobre el color de la variedad), la cima irregular (`alm-copa`) y la etiqueta de papel escrita a mano (`alm-etiqueta`), con el sello verde del curado.
- Los botes de los extractos (`alm-bote`): bajos, de boca ancha y culo grueso, con la tapa negra de rosca; en la nevera, lo vacío se ve blanco a través del cristal (`tarro(…, v)`).
- La nevera por dentro (`alm-nevera`): la junta de goma, el plástico blanco con las paredes en sombra y el fondo más frío abajo, el plafón con su luz, la rejilla del aire, las baldas de cristal con su canto, el perfil blanco, las guías y su sombra, los portaetiquetas y el visor de lo lleno que está como una pantalla.
- Todo a mano en `tools/sprites/a-mano/almacen.py`; Godot, `_tarro` en `trama.gd`.

## 1.36.0 · 14 de octubre de 2026

El curado sin pérdidas y con un 1 % más de THC, en la caja fuerte y en la nevera (adiós al arcón); tirar cogollos y extractos; los visores de la caja y la nevera dibujados, con GUARDAR y la ficha de lo que eliges; los minijuegos centrados; la mesa de manicurar; un mueble por cada extracción, con la lavadora y la máquina de static; las mallas 00; y las extracciones contadas como se hacen de verdad. Godot, 0.30.0.

- **Curar ya no corre prisa.** Lo que no está curado ya no pierde THC (tampoco lo que llevan tu plantilla o los vendedores). Con los tarros de Kiko, los cogollos se curan en la **caja fuerte** y los extractos, en frío, en la **nevera** (caben 200 g), en 2 días: pierden algo de agua, así que el THC sube un 1 % (no se crea THC: es el mismo en menos peso), y se venden un 15 % más caros.
- **Sin arcón.** Las cajas de al lado de la nevera ya no están: lo seguro es la caja de detrás del diploma (cogollos y dinero) y la nevera (extractos). Lo que no cabe al cosechar va a la caja fuerte y, si tampoco cabe, se queda encima. La redada se lleva la nevera y lo de encima (la caja, nunca); Darko, la mitad de lo de fuera y de la nevera; el gerente de la plantilla cosecha a la caja. En las partidas de antes, lo del arcón pasa a la caja (o encima, sin ella) y a la nevera, y el rosin que había en la caja, a la nevera.
- **Tirar productos.** Como las semillas: desde la MOCHILA, un lote de cogollos (con catar y analizar) o un extracto, la cantidad que quieras. El dinero, no.
- **Minijuegos centrados.** Las barras del billar y de las extracciones salen en el centro de la pantalla.
- **La mesa de manicurar.** Junto a las mesas de la tía, con las tijeras de punta fina, los guantes y la bandeja de rejilla: pela un lote de cogollos (medio minuto por gramo, como mucho 4 h) y se vende un 10 % más caro. El charas se frota aquí.
- **La caja fuerte, por dentro.** Dibujada a mano como el resto del juego: los fajos de billetes, el tarro de **GUARDAR** y los tarros de cogollos según lo llena que está, de más a menos THC; con las flechas eliges y con A sacas un tarro, guardas (todos los cogollos o un lote) o vas al menú del dinero.
- **La nevera, por dentro.** Abierta, con la fila de **GUARDAR** arriba (todos los extractos o uno) y un piso por tipo de extracción con sus botes, del de más THC al de menos; las filas corren en carrusel con las flechas, y con A sacas.
- **La ficha de lo que eliges.** Al lado de la caja y de la nevera, el tarro elegido en grande con su nombre, sus gramos, su THC, cuánto lleva curado y si está manicurado, en barras con iconos.
- **Un mueble por máquina.** Cada aparato se compra y, al tenerlo, se monta en el piso: la prensa de rosin en su mesita, los tamices de seda en su bastidor, el cubo con las bolsas de malla, la **lavadora de extracción** (900 €, desde el capítulo 4: una pequeña de carga superior, con la cuba de plástico azul; Ice-o-lator más limpio, con su barra al ritmo del motor) y la **máquina de static** (4.500 €, desde el capítulo 5: la placa cargada levanta las cabezas de la flor fría; su barra tiene la zona buena moviéndose). Cada una, con su minijuego.
- **Las mallas 00.** Escondidas en un arbusto de Mendialde: con ellas el dry sift lleva un paso más, la malla más fina, y sale menos pero más puro.
- **Las extracciones, como se hacen.** Los textos y los pasos de cada barra siguen el proceso real: el rosin con las planchas a 80-100 °C, la bolsa de 90-120 micras y la presión poco a poco; el dry sift con flor congelada de malla en malla (220, 160, 120 y 73 micras); el Ice-o-lator con hielo y agua a partes iguales por debajo de 4 °C, 15 minutos removiendo, reposo, bolsas de 220 a 73 micras y secado en frío; el charas frotado a mano de la planta viva; el hachís prensado del kief con calor suave; y la static, de la flor tamizada a la bandeja y la placa cargada a la altura justa.
- Arte a mano, sin PixelLab: la caja, la nevera, la ficha, los tarros, los botes, los fajos y los iconos de los visores en `tools/sprites/a-mano/almacen.py`; la mesa de manicurar, la prensa, los tamices, el cubo con las mallas, la lavadora (redibujada de carga superior, sin marcas) y la máquina de static en `tools/sprites/a-mano/extraccion.py`. Las partidas de antes: lo que había perdido no vuelve; desde hoy, nada se pierde.
- Igual en Godot. Tests: `npm test` 119/119 (paso nuevo: la caja y la nevera por dentro con GUARDAR, el curado en las dos, la manicura, la lavadora, la static y las mallas 00; la mochila y los extractos a salvo, sin arcón; el arcón de una partida vieja) y accesos 0 fallos; `test:arte` 29/29; Godot, historia 119 pasos, 59 pantallas (el piso con todas las máquinas, la caja y la nevera por dentro, las dos con GUARDAR elegido, y las barras de la static y la lavadora) y el ciclo.

## 1.35.0 · 14 de octubre de 2026

El dinero negro y el limpio; un local por pueblo para lavarlo; los recibos con su aviso; el billar a la bola 8; seis extracciones sin disolventes; la nave más real; y la pantalla de inicio nueva. Godot, 0.29.0.

- **El banco y el efectivo.** Ahora hay dos dineros: el efectivo de la calle (lo de siempre) y la cuenta del banco (empieza con 300 €). Con tarjeta, de la cuenta, se paga lo que deja rastro: la tienda online (muebles, vehículos y reformas), el banco de semillas del ordenador y los locales. En los cajeros (el barrio, Puerto Viejo, Valdehierro, el Casco Viejo y el Ensanche) sacas hasta 600 € al día e ingresas hasta 400 € de efectivo al día sin que el banco pregunte. En el móvil, BANCA: el saldo, los recibos que vienen y los últimos movimientos.
- **Un local por pueblo, para lavar.** El lavadero de los astilleros, la taberna de Puerto Viejo, el taller de Valdehierro, la quesería de Mendialde, la panadería de Errotabarri y la lavandería de Ibarbide: delante de cada uno, su cartel de «se traspasa». Los alquila un amigo de Don Baltasar, y solo cuando le has pagado lo bastante de la deuda (desde 3.000 € el primero hasta 30.000 € los de los pueblos y la ciudad). Fianza y recibo semanal, domiciliados; cada día metes en su caja hasta su tope de efectivo y a la mañana siguiente lo tienes en la cuenta como ingresos del negocio, menos los gastos e impuestos (del 10 al 15 %).
- **Los recibos, con su SMS.** La nave de Arrieta y el bajo de Txomin se pagan cada 7 días en efectivo (de lo que llevas y de la caja): te avisan dos días antes, y si no hay, vuelven al día siguiente; después cambian la cerradura. Los locales, domiciliados: el banco avisa, lo devuelve sin saldo y a los 3 días rescinde el contrato. Molina también avisa antes de que se acabe lo vuestro.
- **El billar, a la bola 8.** Una partida corta con la mesa a la vista (el tapete, las troneras y las bolas que quedan): en tu turno eliges el tiro (al hueco; al rincón, más difícil pero deja la blanca bien; o jugar seguro) y lo das en dos barras, la dirección y la fuerza. Si te pasas, la blanca se cuela y el otro juega con bola en mano. Cada rival juega distinto. Quien mete la negra con las suyas dentro, gana.
- **Seis extracciones, sin disolventes.** En la mesa del piso, además del rosin: el dry sift con los tamices de seda (60 €), el Ice-o-lator con agua y hielo (140 €), el charas a mano, el hachís prensado (del kief de los tamices o del hielo) y el moonrock, lo más difícil (un cogollo bañado en rosin y rebozado en kief). Cada una es una tanda de barras: cuantas más en el verde, más rendimiento y más THC, con cifras reales (el dry sift saca un 10 % de la flor, el hielo un 12 %, el charas un 4 %). Los catadores de la calle compran de todo, cada uno a su precio.
- **La nave, más real.** El agua entra por un grifo encima del tanque; de la bomba sale la tubería por el pie de la pared, con abrazaderas, y en cada mesa una T con su llave (o su electroválvula, con el cable al controlador) y la bajada a la bandeja. Tu gente ya no está siempre plantada delante de su mesa: a lo largo del día se mueve alrededor de ella, sin tapar nada.
- **Cada cosa en su sitio.** GROW IBARBIDE, con la carpa de exposición al fondo, fuera del paso, y las baldas detrás del mostrador.
- **La pantalla de inicio, nueva.** Detrás del azul, el barrio de verdad, como un vídeo: tú paseando, un cliente esperando y una patrulla pasando. El lema, «Caza genéticas. Salda la deuda. Que no te pillen.», y los botones grandes, en pastilla, con el elegido marcado; se abren solos, sin «pulsa START».
- Las partidas de antes: la cuenta con 300 € y los recibos a 7 días desde hoy.
- Arte a mano, sin PixelLab: los cajeros, los carteles de los locales y el edificio de ladrillo de los astilleros, la mesa del billar y la tubería de la nave. Igual en Godot. Tests: `npm test` 118/118 (pasos nuevos: las extracciones y el banco con los locales) y accesos 0 fallos; `test:arte` 29/29; Godot, historia 118 pasos, pantallas y el ciclo.

## 1.34.0 · 14 de octubre de 2026

Cada local, el suyo; el bajo de las setas por dentro; las madres de la nave y más mando sobre tu gente; los clubs de fuera, con su presidente. Godot, 0.28.0.

- **El bajo de Txomin, por dentro.** En la Kale Zaharra, la casa de Txomin tiene ahora su puerta de chapa al bajo: cerrada con candado si no lo alquilas y, si lo alquilas, se entra (10 × 7, a oscuras con una bombilla). Tres baldas con las bandejas a la vista en su fase (recién sembrada, colonizando, con setas, contaminada o seca), el pulverizador de mochila, el secadero (vacío o con setas), la tubería que suda, las cajas de Txomin y el cubo. En las baldas se pulveriza, se recoge y se tiran las malas; comprar bandejas, venderle las setas y dejar el bajo, con él en la puerta.
- **Cada club, distinto.** Ya no son el mismo local con otro nombre: Kalea (Casco Viejo), el pequeño, de piedra y vigas con terciopelo granate; Itsaso (Puerto Viejo), marinero, con tablas de cubierta, cuero azul, ojo de buey, timón y red; La Fundición (Valdehierro), grande, de hormigón y ladrillo, con cuero marrón, barriles de mesa, diana y un engranaje; Ensanche, el más grande, blanco y moderno, con sofás de diseño, mesas de cristal y un neón con una hoja; y la asociación de la tía Maite, con sus libros y las copas de sus premios. Cada uno con su suelo, su pared, sus sofás, mesas, vitrina y billar, de 15 × 8 a 20 × 10, con más sofás (de 2 a 5 grupos), el billar con sitio alrededor para jugar, la lámpara encima y más socios sentados que hablan contigo.
- **Los clubs de fuera se ganan.** En la asociación del barrio los socios ya te conocen por la tía, pero en Itsaso, La Fundición, Kalea y Ensanche no compran a cualquiera: para venderles un lote o aceptar un encargo de semillas tienes que ganarte al encargado y a su presidente o presidenta (Xabier, Rosario, Eneko y Nagore, sentados en el club), 15 de confianza con cada uno. Suma hablar con ellos cada día, invitarles a probar 2 g de lo tuyo (una vez al día cada uno), comprar en el dispensario y, ya dentro, vender y cumplir. Cuando se fían los dos, te lo dicen. En el móvil, GENTE, salen los presidentes y lo que falta. Las partidas de antes: donde ya vendías, se fían de ti.
- **Los grows, distintos.** El de Kiko, con su pizarra de consejos (cambia cada día), sacos de sustrato y macetas de tela. GROW IBARBIDE, más grande (12 × 9): baldosa gris, ladrillo blanco, neón verde, botes de abono en la pared, el propagador de esquejes y una carpa de exposición montada con su LED.
- **La carpa de las madres, en la nave.** A la derecha, una carpa de 150 × 150 a 18/6 con hasta 4 madres: mete una con una semilla o un esqueje de lo que quieras guardar. Pon a alguien de tu plantilla **a las madres** (30 € al día): cada mañana las riega y les saca un esqueje (dos, con cuidado 4 o más), hasta 4 por madre, que recoges en la carpa al propagador. Las mesas se plantan con el clon de una madre sin gastar nada. Sin nadie que las cuide, pierden vigor y se mueren.
- **Más mando sobre tu gente.** En el escritorio de la nave, LA GENTE: quién cuida cada mesa y las madres, cambiarlos de mesa (si está ocupada, se cambian) y, a cualquiera de la plantilla (también desde el móvil), una **prima** (100 €: lealtad +1; con lealtad 5, no hace falta) o un **curso** (250 €: cuidado +1; a los de la calle, labia +1), hasta 5 y una vez por semana cada uno.
- **Todo se puede andar.** Prueba nueva, `node tools/test-accesos.js` (va en `npm test`): en los 26 mapas con todo montado, desde cada entrada, se llega a cada puerta y salida, se puede hablar con cada persona quieta y mirar cada mueble; arregló una mesita encerrada entre sofás, una caja tapada y gente parada delante de la estantería.
- Arte a mano, sin PixelLab: suelos, paredes, sofás, mesas, vitrinas, billares y lo de las paredes de cada club, el bajo y sus bandejas, la fachada de la casa de Txomin, los grows y la carpa de las madres en `tools/sprites/a-mano/locales.py`. Las partidas de antes: la nave, con la carpa vacía.
- Igual en Godot. Tests: `npm test` 116/116 (paso nuevo: los locales y las madres) y accesos 0 fallos; `test:arte` 29/29; Godot, historia 116 pasos, 52 pantallas (los cuatro clubs nuevos, el bajo con sus bandejas y la nave con las madres) y el ciclo.

## 1.33.0 · 14 de octubre de 2026

La nave, equipada de verdad: focos a elegir, extracción con filtros y riego que crece contigo. Delroy, con rastas. Godot, 0.27.0.

- **Focos por mesa: LED, sodio o cerámica (CMH).** En cada mesa de la nave, FOCOS: LED de barras (dos de 720 W, 1.800 €: gastan poco y apenas calientan), sodio (dos campanas de 600 W con balastro, 600 €: un 10 % más de gramos, pero el doble de calor) o cerámica (cuatro de halogenuro metálico cerámico de 315 W, 1.400 €: luz de día con algo de ultravioleta, un punto más de THC). Los de antes se los queda Arrieta. Cada uno con su dibujo y su luz: rosada, naranja o blanca.
- **Los focos cuelgan de poleas** y nunca tocan las puntas: dos cuerdas por foco bajan del techo (se desvanecen hacia arriba) a dos poleas con su tirador, y el foco queda a unos centímetros de la planta más alta de la mesa; a medida que crecen, sube, como en las carpas de casa.
- **Extracción con filtros de carbón**, en el escritorio → MEJORAS: un extractor de 250 mm con su filtro (450 €), uno de 315 mm con dos filtros (1.200 €) o dos de 315 mm con cuatro filtros (2.600 €). Cada nivel saca más calor y deja salir menos olor: la redada en la nave baja al 70 %, al 45 % y al 25 %. Si los focos calientan más de lo que saca la extracción (CLIMA, en el escritorio), las plantas crecen menos: un 8 % por cada punto de más, hasta un 40 %.
- **La estantería cuenta los decimales**: con el controlador o la máquina, cada mesa gasta 0,8 o 0,7 dosis, y lo que queda se ve con su decimal (antes, «×0» con abono todavía dentro).
- **Riego escalable**, también en MEJORAS: el tanque de 1.000 L con su bomba y una manguera a cada mesa (650 €: el abono ya mezclado, +5 % de gramos), el controlador de riego con electroválvulas y un gotero por maceta (1.600 €: +10 % y un 20 % menos de abono) y la máquina de fertirrigación que mide el pH y la EC y dosifica sola (4.500 €: +18 %, medio punto más de THC y un 30 % menos de abono). Todo se ve montado en la nave: los extractores y los filtros en la pared, el controlador, el tanque con su palé y su bomba, la máquina y la manguera por la pared del fondo bajando a cada mesa. La nave sube de nivel: pelada, apañada, en marcha, seria, profesional, de concurso e industrial.
- **Delroy, con rastas**: las rastas canas, en cordones con su vuelta y las puntas sueltas por encima de los hombros; de frente, dos le caen sobre el pecho.
- **La foto de la tía Maite, más grande y mejor**: ocupa dos casillas, con marco de madera tallada, paspartú, la tía Maite y Delroy de jóvenes en un campo junto a una mata en flor, y la placa de latón.
- **La APK, por GitHub**: va en `descargas/LandraceHunters.apk` de la rama, para descargarla entera desde el enlace.
- Arte a mano, sin PixelLab: los focos, extractores, filtros, controlador, tanque y máquina y la foto en `tools/sprites/a-mano/locales.py`; las rastas, en `tools/sprites/a-mano/delroy.py`. Las partidas de antes llevan LED en todas las mesas y la nave sin mejoras.
- Igual en Godot. Tests: `npm test` 115/115 (paso nuevo: la nave equipada); `test:arte` 29/29; Godot, historia 115 pasos, 47 pantallas (la nave equipada a tope, con sodio y cerámica) y el ciclo.

## 1.32.0 · 14 de octubre de 2026

Mesas de la nave que parecen mesas, la asociación de la tía Maite y Delroy. Godot, 0.26.0.

- **Las mesas de la nave, de nuevo.** Ahora se ven a medio fondo, como el billar: la bandeja blanca con su borde, las acanaladuras y el desagüe, el bastidor y las patas, con el suelo por debajo, y los dos LED de barras colgados encima. En cada mesa, **cinco macetas de 11 L a tresbolillo**: tres en la fila de delante (la de los trabajadores) y dos en la del fondo, en los huecos. Las plantas son más grandes y se ven desde arriba, con su **corona y las puntas**, nada de pinos: matas con hojas de cinco y siete dedos y, en flor, las colas con sus pistilos; el porte y los colores siguen saliendo de la variedad (índica, ancha y baja, con cogollos gordos; sativa, alta y fina, con colas largas).
- **La Asociación Cannábica Ribera Verde**, en el barrio alto, junto a la comisaría (desde el capítulo 3): la casa alta de almagre con la placa de latón, la ventana esmerilada y el portal verde. Por dentro es un club (el carné en la puerta, el dispensario, los sofás con Imanol, el billar con Koldo), y en la pared, **la foto de la tía Maite**.
- **Delroy, el «tío» que nunca lo fue de papeles.** La segunda vez que vas (otro día) está junto a la foto: el compañero jamaicano de la tía Maite durante treinta años, mayor, con las rastas y la barba canas, camisa crema con una cadena fina, pantalón de pinzas y botas de ante color camel. Te cuenta que ella fundó la asociación y la presidió muchos años, y que desde que se fue la lleva una gestora y la presidencia está vacía. Entra en MÓVIL → GENTE.
- **Presidir la asociación**, de dos maneras: **presentarte** a la asamblea (a los 3 días, al amanecer; hacen falta 21 votos de 40: votan por ti 8 de los de siempre de la tía, Delroy 4, cada uno del barrio que se fía de ti —Kiko, Julen, Josune, Begoña, Patxi, Txaro e Iñaki, con 20 de confianza— otros 4, y uno por cada 10 de confianza con la asociación; si gana la gestora, a los 7 días puedes volver a presentarte) o **refundarla**, pagando 3.000 € de deudas y registro (también con la asamblea pendiente). De presidente, **el dispensario**: le dejas a Delroy un lote (50, 100 o 200 g) y cada mañana los socios retiran 20 g a precio de club con un 15 % más; el dinero, a tu buzón. Logro nuevo: «Como la tía Maite».
- Arte a mano, sin PixelLab: la mesa, las macetas y las plantas y la fachada de la asociación y la foto en `tools/sprites/a-mano/locales.py` (con la Ó con su tilde en la placa); Delroy, del dibujo de Kiko, por zonas, en `tools/sprites/a-mano/delroy.py`, con sus ojos, su respiración y su porro.
- Igual en Godot. Tests: `npm test` 114/114 (paso nuevo: la asociación); `test:arte` 29/29; Godot, historia 114 pasos, 46 pantallas (la asociación por fuera y por dentro, con Delroy, y la nave con las mesas nuevas) y el ciclo.

## 1.31.0 · 14 de octubre de 2026

Menús largos con flechas, garrafas de abono, pH− por litros y las plantas de la nave según la variedad. Godot, 0.25.0.

- **Los menús largos ya no se salen de la pantalla.** Los de la derecha (el arcón y la caja fuerte con muchos lotes, ¿QUÉ LOTE?, las preguntas con muchas respuestas, START) enseñan las filas que caben entre el borde de arriba y el diálogo, con ▲ y ▼ cuando hay más arriba o más abajo; la cruceta llega hasta el último, y ▲ y ▼ también se tocan. La misma cuenta en el HTML y en Godot, a cualquier tamaño de pantalla.
- **Garrafas de abono** de 5, 10 y 25 L (desde los capítulos 2, 3 y 4) de los cuatro abonos, MEATZA y ORTUA BIO, además de la botella de 1 L: 4 dosis el litro, y cuanto más grande, más barata la dosis (la floración MEATZA: 14 € el litro, 55 € la de 5 L, 99 € la de 10 L, 215 € la de 25 L).
- **pH− por litros**: la botella de 250 ml pasa a ser de 1 L (capítulo 1), 2 L (capítulo 2) y 5 L (capítulo 3), 40 dosis el litro (MEATZA 10, 17 y 35 €; ORTUA BIO 12, 20 y 42 €).
- **Las plantas de la nave, según su variedad.** Como en las carpas de casa: el porte sale del % índica (índica baja y ancha, sativa alta y fina, híbrida entre las dos) y el color de las hojas y los cogollos, de la variedad. Las mesas pasan de verde a la flor con sus pistilos y a los cogollos maduros; dibujadas a mano y nuevas (`tools/sprites/a-mano/locales.py`, encima de la mesa). Y encima de cada mesa, dos **LED de barras como los de las carpas** (de 100 cm y 8 barras, colgados de sus cuerdas con trinquete y la fuente encima): encendidos con la mesa plantada, con su luz rosada sobre las plantas, y apagados con la mesa vacía.
- **Arreglos de los locales.** El billar no empieza siempre la barra en el mismo sitio (contar ya no vale). La RRPP de GAUA mira antes de cobrar si cabe alguien más en la agenda. Cada trabajador de la nave tiene su mesa fija (despedir o mover a uno ya no cambia la mesa de los demás; las partidas de antes conservan la que tenían). Lo que se recoge en el secadero lleva el día de la cosecha (y empieza a contar el curado desde ahí). La barra, el DJ y el reservado de GAUA, cerrados a partir de las seis. En Godot, una canción grabada que no se puede leer suena con la de reserva en lugar de quedarse en silencio.
- Igual en Godot. Tests: `npm test` 113/113 (paso nuevo: garrafas y botellas de pH−; el de la plantilla, con la mesa fija y el día del secadero; el de los locales, con la agenda llena, GAUA cerrada y la partida vieja); `test:arte` 29/29; Godot, historia 113 pasos, 44 pantallas (la nave con cuatro variedades en sus fases) y el ciclo.

## 1.30.0 · 13 de octubre de 2026

Los locales se entran como una casa y la música es nueva. Godot, 0.24.0.

- **Los clubs por dentro.** Cada club (Itsaso en Puerto Viejo, La Fundición en Valdehierro, Kalea en el Casco Viejo y el del Ensanche) tiene su fachada propia con su puerta, y dentro una sala de 12 × 8: el dispensario con la vitrina y el encargado detrás (comprar, vender, encargos, como antes), los tarros, la pizarra con la variedad del día, las normas, los sofás chester con la mesa baja, el billar bajo su lámpara de techo, el taquero, la gramola y las plantas, en penumbra cálida. El carné se pide en la puerta la primera vez.
- **Billar con apuesta.** El del billar juega a 10, 20 o 50 €: 3 tiros cada uno con una barra de fuerza que va y viene (A en el verde, la bola dentro, 3 puntos; en el amarillo, la rozas, 1). Quien sume más se lleva la apuesta; 3 partidas al día con cada uno, y ganar suma confianza con el club.
- **Un socio en los sofás.** Se charla o se comparte un gramo de lo tuyo (una vez al día, media hora): +3 de confianza con el club.
- **La nave por dentro.** Cuatro mesas de cultivo en fila, una por trabajador (cada uno junto a la suya). Plantas tú, con semilla o esqueje (el THC sale de la variedad y del fenotipo, y la estrella va a su lote), y eliges el abono de cada mesa: MEATZA u ORTUA BIO, que se dejan en la estantería y se gastan una dosis por mesa y día (más gramos y algo más de THC). Cada mesa pasa por recién plantada, creciendo, en flor y dando cogollos, que se ve en la mesa; desde el quinto día cuelga cada mañana lo suyo en el secadero, que se recoge allí. El escritorio enseña las cuatro mesas. Sin alquilar, la persiana está echada. Las naves de antes pasan su variedad y lo que había en el secadero a las cuatro mesas.
- **GAUA, la discoteca del Ensanche** (desde el capítulo 4, de 23:00 a 6:00). El portero cobra la entrada (15 €, una vez por noche). Dentro: la barra (copa 10 €, hasta 3; invitar a una ronda 40 €, +1 de reputación), la pista con luces de colores, la cabina del DJ (bailar media hora; a veces alguien te pide el número y entra en la agenda) y el reservado (300 €, una hora): la RRPP te presenta a un **cliente VIP** que va a la agenda. El VIP pide de lo bueno, como un pijo, y paga un 60 % más. A las seis se encienden las luces y el portero echa a todo el mundo. La gente de GAUA cuenta como una sola confianza en MÓVIL → GENTE.
- **Música nueva** (solo en la app de Godot): 40 canciones grabadas en lugar del chiptune, con instrumentos de verdad sintetizados (piano eléctrico, guitarra, bajo, acordeón, órgano, cuerdas, metales, marimba…), batería, reverb y eco, cada una con su intro y su bucle sin cortes. Una por sitio y momento: cada zona de la calle de día y otra de noche, el piso de día y de noche, el growshop, el bar, el club, la nave, GAUA, la comisaría, el almacén, el caserío, el título, el final, la alarma de la patrulla, la redada y cuatro combates (ladrón, policía, rival y Darko).
- Igual en Godot (los locales, la luz de cada uno y la barra del billar). Arte a mano, sin PixelLab: `tools/sprites/a-mano/locales.py` (fachadas, suelos y paredes, la pista y los muebles, con la mesa de cultivo en sus cinco fases); la gente de los locales sale de los personajes que ya había.
- Tests: `npm test` 112/112 (paso nuevo: los locales; el de los clubs, dentro del club; el de la plantilla, con las mesas, la estantería y el secadero de la nave); `test:arte` 29/29; Godot, historia 112 pasos, 44 pantallas (el club con la barra del billar, la nave con sus mesas y GAUA de noche) y el ciclo, con la música grabada.

## 1.29.2 · 13 de octubre de 2026

Precio real del analizador. Godot, 0.23.2.

- El analizador de cannabinoides y terpenos cuesta 3.000 € en el growshop (antes, 180 €), como un aparato de verdad que mide THC, CBD y terpenos; pedido a Kiko por el móvil, 3.450 € (su 15 %). Lo demás de lo añadido últimamente ya tenía precios de tienda reales (tarros 30 €, medidor de pH y EC 35 €, prensa de rosin 250 €, carro de esquejes 165 €, deshumidificador 190 €, aire acondicionado 320 €, PC gaming 1.490 €) y no cambia.
- Igual en Godot. Tests: `npm test` 111/111; Godot, historia 111 pasos.

## 1.29.1 · 13 de octubre de 2026

Lo que quedaba del curado. Godot, 0.23.1.

- El lote que le dejas a un vendedor de la agenda también pierde THC si no está curado, como el de la plantilla: cuenta desde el día de la cosecha, no desde el día en que se lo das, y vende al THC que le queda. Curado, no pierde.
- Las partidas de antes: el día que guardaban los vendedores era el de la entrega; se borra al cargar, así que lo que ya llevan no pierde nada (como los lotes de antes de la 1.29).
- Igual en Godot. Tests: `npm test` 111/111 (el paso del curado añade el vendedor: el día de la cosecha, lo que pierde, uno de antes que no pierde y la partida vieja); Godot, historia 111 pasos.

## 1.29.0 · 13 de octubre de 2026

La hierba se cura y, sin curar, se estropea. Godot, 0.23.0.

- **Nuevo: el curado.** Cada lote de cogollos lleva el día de la cosecha y sale **sin curar**. En el arcón de casa, con los **tarros de curado** de Kiko (30 €, en el growshop o por el móvil, desde el capítulo 1), se cura en 2 días. Curado, el THC no sube (como en la realidad), pero se vende un 15 % más caro en la calle, a Iñaki (los 10 g y al por mayor), en la lonja, en los clubs y con los vendedores y la plantilla, la cata lo nota («Bien curada: suave y con todo el aroma») y ya no pierde nada.
- **Nuevo: perecedera.** Sin curar, a los 3 días de la cosecha empieza a perder un 2 % de su THC cada día, esté en la mochila, en el arcón o en la caja fuerte (a medio curar, la mitad). Al amanecer avisa el primer día que pierde («Sin curar, pierde THC: …») y el día que queda curada en el arcón.
- La primera cosecha lo cuenta, una vez. En la MOCHILA, cada lote dice si está curado, curándose o desde qué día pierde, y al catarlo sale en la línea («· curada», «· sin curar»). El arcón dice que con los tarros se cura lo de dentro.
- Al juntar dos lotes (cosechar otra de la misma variedad, guardar o sacar del arcón), el THC, lo curado y el día van por gramos. Lo que compras en un club ya viene curado. Lo que lleva alguien de la plantilla en la calle también pierde si no está curado, y lo que le queda vuelve al arcón con su curado y su día (los lotes de antes, sin día).
- Las partidas de antes: los lotes que ya tenías no pierden nada (no tienen día); lo que coseches desde ahora, sí.
- La misión «Llegar al 27 %» avisa: sin curar, a los 3 días empieza a perder THC; preséntala antes o cúrala en el arcón.
- Igual en Godot. Desde esta versión solo se construye y se entrega la app de Godot: el HTML queda como fuente de datos, arte y pruebas de Godot (`npm run godot`), sin APK propia.
- Tests: `npm test` 111/111 (paso nuevo: los tarros, 2 días de curado en el arcón, lo que pierde un lote sin curar desde el 4.º día, los avisos, el precio al por mayor un 15 % más alto, la cata, cómo se juntan los lotes y la plantilla); Godot, historia 111 pasos, 41 pantallas y el ciclo.

## 1.28.0 · 13 de octubre de 2026

Misiones para la Copa: cómo llegar al 27 %. Godot, 0.22.0.

- **Nuevo: tres misiones en el capítulo 6**, en START → OBJETIVO, con su SMS de Kiko y su regalo, como las de antes:
  - **Una genética potente:** la marca de Darko es una Amnesia Haze del 26,8 % y, sin un fenotipo estrella, solo pasan de ahí, con buena luz y abono, las de receta del 26 % o más (Amnesia Haze, Jack Herer y Sour Diesel). La más a mano, la Sour Diesel: Chemdawg × Super Skunk en la mesa, con sus precios. Se cumple al sacar una en la mesa. Regalo: 4 dosis de MEATZA FLORACIÓN y 4 de pH−.
  - **Floración a tope:** el LED de 720 W (+1,4 de THC; en la carpa de 120 o la de 150) y el abono de floración con pH− y el medidor (+0,3 si lo aprovecha entero; el orgánico, +0,4). Se cumple con una planta abonada así bajo el LED de 720 W. Regalo: 2 dosis de ORTUA BIO FLORACIÓN y 2 de su pH−.
  - **Llegar al 27 %:** 20 g de un solo lote en la mochila con más del 26,8 %, redondeado como lo mide el jurado; recuerda que el lote se queda con la media (cosecha la mejor y preséntala antes que otra de la misma variedad; las de fenotipo estrella van aparte). Se cumple al tenerlo y Kiko te manda al jurado.
- Al ganar la Copa, las que falten se dan por hechas, sin aviso ni regalo, igual que en las partidas que ya la ganaron. Nada cambia en el equilibrio: la marca sigue en 26,8 %.
- Igual en Godot.
- Tests: `npm test` 110/110 (paso nuevo: las tres misiones, con 26,8 % que no llega y 26,9 % que sí, sus SMS y regalos; al ganar la Copa, la que falta, cerrada, también en `migrate`); Godot, historia 110 pasos, 41 pantallas y el ciclo.

## 1.27.1 · 13 de octubre de 2026

Una silla delante de cada ordenador. Godot, 0.21.1.

- **Nuevo: la silla de madera de la tía**, delante de su ordenador del dormitorio, y **la silla gaming** (negra con franjas magenta, pistón y base de cinco radios), que llega con el PC gaming (ahora «PC gaming con mesa y silla», al mismo precio) delante de su mesa, en sus dos casillas. Las dos se ven por detrás, mirando a la pantalla, y no se pisan: con A sobre la silla, desde cualquier lado, se usa el ordenador que tiene delante. Arte a mano en `tools/sprites/a-mano/salon.py` (`silla`, `sillaG`).
- Igual en Godot. En `docs/MAPA.md`, las sillas son `r`.
- Tests: `npm test` 109/109 (el paso de la 1.27 mira las sillas: sólidas, A hacia el ordenador y la gaming con el PC); `test:arte` 29/29 (las sillas, también sin atlas); Godot, historia 109 pasos, 41 pantallas (el piso, con las dos sillas) y el ciclo.

## 1.27.0 · 13 de octubre de 2026

La casa a tu gusto y los logros. Godot, 0.21.0.

- **Nuevo: reformas del piso**, en la tienda online (REFORMAS: SUELO Y PAREDES). El suelo, en tarima de roble (la de serie), de nogal, vinílico gris o baldosa hidráulica, y las paredes, en papel crema de rayas (el de serie), pintura verde salvia o azul grisáceo, o ladrillo visto, con precios reales por los 108 m² de suelo y unos 120 m² de pared, colocación incluida. Se paga al pedir y el instalador o el pintor viene al día siguiente; lo que ya tienes sale como «en casa». Arte a mano: `tools/sprites/a-mano/casa.py` (asset `casa-reforma`).
- **Nuevo en la tienda online: un póster enmarcado** (39 €; el faro, la ola, la planta en flor o el mapa de la costa), en la pared del dormitorio, encima del ordenador, y **una alfombra de 180 × 140** (129 €; bereber crema, persa granate o lisa gris) para el salón, entre la tele y el sofá: se pisa y va sobre el suelo que tengas.
- **DECORAR LA CASA en la cama**: el tapizado del sofá y del sillón, la lámina del cuadro, el dibujo del póster y el estampado de la alfombra, todo en un sitio.
- **Nuevo: LOGROS**, en START → OBJETIVO → LOGROS: 26, de la primera venta y la primera cosecha a la Jack Herer, la Genoteca completa, las landraces de la tía, el rosin, la cata, el club, el goteo, los plazos, la deuda saldada, las ventas, los rivales, Darko, la plantilla, la nave, las ruedas y la casa reformada, cada uno con el día en que se consiguió. Al conseguir uno sale su aviso; si a la vez llega el de la misión o el del itinerario, va debajo, en el mismo aviso, para que no se pisen. En las partidas de antes, lo ya conseguido se apunta sin aviso.
- Igual en Godot.
- **Arreglado (pruebas de Godot):** el paso de la 1.25 de `historia.gd` leía `REGALO` del juego en vez de los datos (7 errores de script, sin cambiar el resultado).
- Tests: `npm test` 109/109 (paso nuevo: reformas, póster y alfombra en la tienda online, al día siguiente; DECORAR LA CASA; los logros, su aviso detrás del de la misión y en una partida de antes); `test:arte` 29/29; Godot, historia 109 pasos, 41 pantallas (`casa-reforma`, `casa-reforma2`) y el ciclo, con LOGROS en OBJETIVO.

## 1.26.0 · 13 de octubre de 2026

Más genéticas, todas reales: 87 variedades y 50 de receta. Ninguna landrace ni ningún linaje inventado. Godot, 0.20.0.

- **Seis landraces más en el banco del PC** (19 en total), de regiones donde se cultivan de siempre: **Kashmiri** (valle de Cachemira, cap. 3), **Swazi Gold** (Esuatini), **Malana** (valle de Parvati, la del charas) y **Vietnamese Black** (cap. 4), y **Zamal** (isla de la Reunión) y **Ethiopian Highland** (cap. 5). No entran en ninguna receta: son para tus cruces.
- **Trece cruces clásicos más**, con el linaje que se publicó (≈ donde no está claro): **Chronic** (Skunk #1 × Northern Lights × AK-47) y **White Rhino** (White Widow × una índica norteamericana sin documentar, ≈; en la mesa, con Afghani), de 2.ª generación; **White Shark** (Super Skunk × brasileña × India del Sur: con White Widow o con Manga Rosa y Kerala), **Hawaiian Snow** (Hawaiian Haze × Neville's Haze × Haze), **Ice** (Afghani × Northern Lights × Shiva Skunk), **Northern Light Blue** (Northern Lights × Blueberry), **Critical 47** y **Critical Cheese** (una Critical con AK-47 o con Cheese, ≈: no está claro qué Critical; en la mesa, la Critical Mass), de 3.ª; y **Jack Flash** (Jack Herer × Super Skunk × Haze), **Jack 47** (Jack Herer × AK-47), **Sour Tangie** (Sour Diesel × Tangie), **NL × Big Bud** y **Critical Jack** (≈), de 4.ª. Cada una con su nota en el diario de la tía.
- **El trueque del molino** (Andoni) ya no deja perder las landraces que no se venden: una vez descubiertas, entran en lo que ofrece y, si te quedas sin semillas de alguna, te la ofrece antes que las demás (las del banco, no: esas se compran).
- Los escondites de Lamb's Bread y de Kerala, bien descritos: al fondo del callejón del este de Puerto Viejo y junto a una borda, al este de Mendialde.
- El diario cuenta las variedades que haya (no un 68 escrito a mano) y `REGALO` pasa a Godot por `datos.json`. `docs/MAPA.md` dice qué dan los arbustos de la tía.
- Igual en Godot.
- Tests: `npm test` 108/108 (el árbol, con las 53 de la tabla; el recetario, con las 50); Godot, historia 108 pasos.

## 1.25.0 · 13 de octubre de 2026

Cazar genéticas: el diario de la tía, bajo la almohada, y las landraces que no se venden. Godot, 0.19.0.

- **Nuevo: el diario de la tía Maite se encuentra.** La primera vez que duermes o te echas la siesta en el piso, das vueltas, ahuecas la almohada y dentro de la funda está su cuaderno. Hasta entonces no sale ni en la Genoteca ni en el sillón; en las partidas de antes ya lo tienes (`S.flags.diario`, `almohada` en 09-cultivo).
- **El diario trae las 68 variedades**, en el orden de la Genoteca, cada una con una nota de la tía (antes, solo las 37 de receta). A la derecha, «receta», «N recetas», «tienda» o «landrace»; en las de receta, A abre lo que entra; en las demás, la nota y dónde están sus semillas. El contador va sobre las 68.
- **Nuevo: siete landraces que no están en ningún banco**, para que algunos cruces cuesten más. El banco del PC se queda con 13; las otras 7, donde las dejó la tía (y su nota del diario da la pista): **Chocolate Thai** en la nevera del piso (3 semillas, en un bote de cristal), **Highland Oaxacan Gold** al fondo de la caja fuerte (3; en las partidas con la caja ya abierta, la próxima vez que la abres), **Lamb's Bread** en un arbusto de Puerto Viejo, **Kerala** en el monte de Mendialde, **Manga Rosa** en Errotabarri y **Hawaiian** en un seto del Ensanche de Ibarbide (2 cada una), y **Luang Prabang** con Miren, junto con la última página (3; si ya tenías la página, al volver a hablarle). Así, la Purple Thai pide la nevera y la caja; la Amnesia Haze, la Purple Thai para Miren; la White Widow, dos pueblos.
- **La Genoteca cuenta cada nueva**: «NUEVA EN LA GENOTECA · n/68».
- **Ojos de la opción C en las acciones de los NPC** (fumar, el móvil, la pipa, contar, servir…): `tools/sprites/a-mano/npc_ojos_acc.py`, después de `npc_ojos.py`/`npc_cara.py`, pega la cara nueva donde casa la cabeza de antes y dibuja a mano las que giran la cara; los ojos cerrados (al dar una calada, al mirar abajo) y los perfiles se quedan como estaban.
- Igual en Godot.
- Tests: `npm test` 108/108 (paso nuevo: el diario bajo la almohada, el banco con 13 y las 7 de la tía; Miren da la de Laos; el diario, con nota en las 68); Godot, historia 108 pasos; el ciclo, la Genoteca sin el diario hasta la primera noche.

## 1.24.0 · 13 de octubre de 2026

Más genéticas y los ojos que faltaban. Godot, 0.18.0.

- **Nuevo: cuatro landraces más**, de las regiones clásicas que faltaban, con la forma de su planta en la historia de la Genoteca: **Kerala** (India del Sur, sativa: tronco recio, hasta 3 m, ramas como un helecho, flor pequeña y muy resinosa, aroma especiado), **Lebanese** (valle de la Bekaa: baja, tallos finos, hoja ancha, cogollo resinoso con hoja; la del hachís), **Manga Rosa** (Brasil) y **Durban Poison** (Sudáfrica). Se piden al banco de semillas del PC: Lebanese desde el capítulo 3, Kerala y Manga Rosa desde el 4 y Durban Poison desde el 5.
- **Nuevo: cinco híbridos clásicos de receta**, con su linaje real: **White Widow** (Manga Rosa × Kerala; su padre real fue una índica del sur de la India sin documentar; ≈), **Purple Haze** (Purple Thai × Haze; ≈), **White Russian** (White Widow × AK-47), **Blue Widow** (Blueberry × White Widow) y **Super Lemon Haze** (Lemon Skunk × Super Silver Haze, la primera de 4.ª generación). La Haze tiene otra receta con la India del Sur (Punto Rojo + Michoacán + Thai + Kerala). El diario de la tía Maite pasa de 32 a 37 variedades, cada una con su nota; la Genoteca, de 59 a 68 (las nuevas, al final, para no cambiar el número de las demás).
- **Ojos de la opción C en Josune, Iñaki, Patxi y Molina** (de frente y de lado) y en los lados de Baltasar y Darko: los ojos que PixelLab les dibujó no se podían buscar por su blanco (sin blanco, o con brillos y cejas blancas), así que van a mano (`A_MANO` en `tools/sprites/a-mano/npc_ojos.py`), donde estaban los viejos.
- Patxi y Kiko dan pistas de las recetas nuevas. En las partidas de antes, un cruce propio que se llamaba como una variedad nueva (Purple Thai × Haze era «Purple Haze») cambia de nombre.
- **Arreglado:** contra la carga de Darko, la guardia o la esquiva de la ronda en que coge la barra se gastan; ya no protegían del golpe doble de la ronda siguiente.
- Igual en Godot.
- Tests: `npm test` 107/107 (el árbol, con las 40 de la tabla hasta la 4.ª generación; el recetario, con las 37; la carga de Darko gasta la guardia y la esquiva); Godot, historia 107 pasos.

## 1.23.0 · 13 de octubre de 2026

Marcas de abono, Julen y el itinerario. Godot, 0.17.0.

- **Nuevo: marcas de abono y pH−** (inventadas). **MEATZA**, mineral: crecimiento, floración y pH− de ácido fosfórico, como el abono de antes (+25 % de cosecha, +0,3 de THC y florece un 10 % antes; sin pH−, la mitad). **ORTUA BIO**, orgánico, de liberación lenta: +20 % de cosecha y +0,4 de THC sin acelerar la floración, el de crecimiento da un 8 % (el mineral, un 15 %) y la tierra amortigua el pH (sin pH−, ×0,85; a ojo, ×0,95). Con algo orgánico y nada mineral (tampoco el pH− fosfórico), el **sustrato vivo** frena las plagas (×0,75). El pH− que se gasta es el de la marca del abono y, si no hay, el otro; con las dos marcas, al abonar eliges cuál (`PRODUCTOS`, `ABONO_BIO`, `abonar`, 09-cultivo). En la tienda, 6 productos; en la mochila, uno por fila con lo que hace; en PLANTAS, «bio» y «sustrato vivo».
- **Nuevo: Julen, el hijo de Kiko** (estudia Agrónomas; sprite de Kiko con otro pelo y otra ropa, `tools/sprites/a-mano/julen.py`). Desde que conoces a Kiko hasta la primera cosecha está en el piso, delante del armario: te regala 2 dosis de ORTUA BIO CRECIMIENTO y 4 de pH− ORTUA BIO, te explica el pH y la diferencia entre mineral y orgánico, te dice qué toca ahora y comenta cada paso. Con la primera cosecha se despide y vuelve al growshop, donde da consejos (`11h-guia.js`; en GENTE).
- **Nuevo: el itinerario** (START → OBJETIVO → ITINERARIO, hasta el capítulo 4): 14 pasos desde el autobús hasta el primer plazo pagado (plantar, regar, los dos abonos, cosechar, vender, los 300 €, Baltasar, juntar el plazo y pagarlo). Al cumplir uno sale «ITINERARIO · n/14» con el siguiente; el objetivo del capítulo 1 es el paso de ahora. Las partidas viejas apuntan lo que ya tienen, sin aviso (`ITINERARIO`, `S.itin`).
- Kiko habla de las dos marcas en sus consejos y te manda a ver a Julen.
- Detalles: con riego automático (garrafas o goteo), «Regar» se cumple al plantar; las partidas de antes con la planta ya abonada no se atascan en los abonos; Julen lleva su «!» hasta que hablas con él y, si lo conoces después de cosechar, te saluda sin ofrecerse a ayudar; se despide antes del capítulo 2; el pH del medidor sale con la marca de cada dosis, y si gastas el pH− de la otra marca, te lo dice.
- Igual en Godot.
- Tests: `npm test` 107/107 (paso nuevo: las marcas, Julen y el itinerario; las partidas viejas apuntan el itinerario); Godot, historia 107 pasos.

## 1.22.0 · 13 de octubre de 2026

Repaso: HUD más pequeño, importar la partida y errores. Godot, 0.16.0.

- **HUD más pequeño:** letra de 6,5 px de juego en vez de 7,5, barras de 28 × 2,5 en vez de 34 × 3 y menos margen: tapa menos del mapa. Igual en Godot (`HUD_*` en `ui.gd`, los mismos números que `.hud` en el CSS).
- **Nuevo: IMPORTAR PARTIDA** (START → OPCIONES, junto a EXPORTAR PARTIDA; en Godot, también en las OPCIONES del título). Se pega la partida exportada en la caja de texto (lo que haya en el portapapeles sale ya escrito; sin `<`, `>`, `"` ni `` ` ``, que no salen en el juego); si es una partida, pregunta («¿Cargar la partida de …, día …? La de ahora se pierde.»), la carga como CONTINUAR (`migrate`) y la guarda. Lo que no es una partida, no se carga. Desde el título de Godot se guarda y sale CONTINUAR. Si no se puede guardar, lo dice.
- Arreglos de la ropa (1.21): la gorra, la camiseta, el pantalón y el pelo de combate tienen colores propios (`player_ropa.py`), así que las zapatillas, la regadera y la planta ya no cambian con ellos; la caché de cada combinación lleva todas las piezas (antes, pantalón y pelo se pisaban). PULVERIZAR pasada la medianoche dice la humedad que queda.
- Errores: un vendedor que se larga a medianoche mientras viene a la llamada ya no aparece a comprar; lo que venden los vendedores, la plantilla de calle y el bajo de las setas cuenta para la historia (`checkStory`); el CBD del analizador sale del 0,2 al 1 % (salía diez veces más); el olor de la noche también da el aviso de calor (`heatWarn` al cambiar el día), y hablar con Darko en los astilleros sube su confianza (antes, la de otra ficha).
- Sprites: `validar.js` da 0 errores (los tapizados y láminas `k-N` cuentan como su mueble; el inventario lleva los muebles que se compran y el combate de Darko; los personajes nuevos de la 1.15 a la 1.21, cubiertos en el manifiesto) y el catálogo, al día.
- Tests: `npm test` 106/106 (paso nuevo: importar algo que no es una partida y la exportada); Godot, historia 106 pasos; el ciclo, con IMPORTAR en las OPCIONES del título.

## 1.21.0 · 13 de octubre de 2026

Arte: ropa y pelo, Darko y Miren con sprite propio y los ojos de los personajes. Godot, 0.15.0.

- **Nuevo: ropa y pelo** (la cama del piso → CAMBIARTE DE ROPA; `ROPA`, `S.ropa`, `vestirte`, 12c-salon). Camiseta (7 colores), pantalón (5), gorra (6) y pelo (5): cambian los colores del protagonista andando, montado y de espaldas en el combate (`ropaC`, por colores exactos con `conRampa`). Fuera del piso, la cama no lo ofrece.
- **Darko pelea con su sprite** (`darko-combate`: sudadera negra y pañuelo rojo; antes, el del ladrón) y **Miren lleva el suyo** (`miren`: pelo canoso y top verde; antes, el de una clienta).
- **Ojos de los personajes** como los del protagonista (opción C, `tools/sprites/a-mano/npc_ojos.py`): párpado, blanco e iris de frente y de lado, en la cabeza de cada dirección, que `npc_cara.py` pega en cada paso. Iñaki, Josune, Molina y Patxi se quedan como estaban (sus ojos no se dejan medir) y Baltasar y Darko, solo de frente; con gafas, Jurado y Txaro, sin tocar.
- Pelo del protagonista: sus dos tonos ya no son los de la cara (`player_pelo.py`), para poder cambiarlos sin tocar cejas ni sombras.
- Arreglos de la 1.19 y la 1.20: el alquiler de la nave se cobra antes que los sueldos (sin él, Arrieta cambia la cerradura antes de que nadie trabaje); PULVERIZAR pasada la medianoche ya no deja el menú del bajo abierto si el bajo se ha cerrado al cambiar de día.
- Igual en Godot. Pantallas: 39 (con el piso con ropa y el combate de Darko).
- Tests: `npm test` 105/105 (paso nuevo: la ropa en la cama del piso y fuera de él, los colores del protagonista, el combate y el sprite de Darko y el de Miren); Godot, historia 105 pasos.

## 1.20.0 · 13 de octubre de 2026

El bajo de las setas: un local clandestino en la Kale Zaharra. Godot, 0.14.0.

- **Nuevo: el bajo de las setas** (Txomin, en la Kale Zaharra, desde el capítulo 4; `SETAS`, `S.setas`, 11g-setas). Txomin, el setero viejo del callejón, alquila el bajo de su casa: 1.500 € de fianza y 20 € al día, que cobra cada mañana. Él prepara las bandejas (45 € cada una, hasta 6); tú las tienes húmedas (PULVERIZAR, 10 minutos, las deja al 100 %; cada día pierden 34 puntos) y esperas: 6 días colonizando, 4 fructificando y listas.
- Cada mañana, una bandeja que no está lista puede contaminarse (2 %; un 15 % más por debajo de la mitad de humedad) y, a 0, se seca: las dos se tiran (TIRAR LAS MALAS). RECOGER da de 25 a 40 g por bandeja lista, que se secan en el bajo, y Txomin te los compra a 9 € el gramo (calor +3).
- Una redada en el bajo (1 % al día con bandejas vivas) se lo lleva todo, el local incluido (calor +15). Sin el alquiler, Txomin cambia la cerradura y se queda la fianza y lo de dentro; si lo dejas, te la devuelve.
- Igual en Godot.
- Tests: `npm test` 104/104 (paso nuevo: alquilar, las bandejas, la humedad, las fases, contaminar y secar, recoger, vender, la redada, impagar y dejarlo); Godot, historia 104 pasos.

## 1.19.0 · 13 de octubre de 2026

La plantilla: poner al barrio a trabajar. Godot, 0.13.0.

- **Nuevo: la plantilla** (MÓVIL → PLANTILLA, desde el capítulo 3; `PLANTILLA`, `S.plantilla`, 11f-plantilla). Patxi te manda a alguien del barrio por un sobre de 150 €: no sabes a quién hasta que llega, y le contratas o no (el sobre ya está pagado). Cada uno trae tres números del 1 al 5: **labia** (vende más y le timan menos), **cuidado** (le para la policía y le atracan menos; en la nave, saca más) y **lealtad** (se larga menos con lo tuyo y, de gerente, sisa menos). Hasta 6 a la vez; se les cambia de trabajo, se les deja libres o se les despide desde el móvil.
- **A la calle** con un lote de 25, 50 o 100 g: cada mañana vende de 2 a 4 g por punto de labia a precio de calle del barrio y se queda el 30 %; o le para la policía (5 % con cuidado 1, 1 % con 5: pierde el lote y el calor sube 10), le atracan (8 % → 2 %: la mitad del lote), se larga con todo (6 % con lealtad 1, nunca con 5; la mitad con gerente) o le pagan con billetes falsos (6 % → 2 %: los gramos, sin dinero). Lo que le quede al dejarlo vuelve al arcón.
- **De gerente** (uno, 40 € al día): cada mañana riega, trata las plagas con tu insecticida y rellena garrafas y depósitos, como Begoña, y cosecha lo que esté listo al arcón (las semillas y la estrella, como tú), quitando su sisa: un 3 % por cada punto de lealtad por debajo de 5.
- **La nave de Valdehierro** (Arrieta, al lado de la nave, desde el capítulo 5; `NAVE`, `S.nave`): 3.000 € de fianza y 60 € al día. Pones a trabajar hasta 4 (30 € al día cada uno) y eliges la variedad con una semilla: cada uno saca 16-24 g al día según su cuidado, al 90 % del THC de la variedad, que se recogen allí. Una redada (del 1,7 % al 0,5 % al día, según el más cuidadoso) se lo lleva todo, nave y gente incluidos (calor +20). Sin el alquiler, Arrieta cambia la cerradura y se queda la fianza; si la dejas, te la devuelve.
- Sin dinero para el sueldo, el gerente y los de la nave lo dejan.
- Igual en Godot. Begoña y el gerente comparten `cuidarPlantas`; la cosecha, `thcCosecha` y `semillasCosecha`.
- Tests: `npm test` 103/103 (paso nuevo: los sobres, la calle con sus cinco salidas, el gerente con su sisa, la nave con el alquiler, lo que crece, la redada, dejarla e impagarla); Godot, historia 103 pasos.

## 1.18.0 · 13 de octubre de 2026

Combates con más fondo: esquivar, amenazar y experiencia. Godot, 0.12.0.

- **Nuevo: ESQUIVAR** (LUCHAR → ESQUIVAR). Te quedas atento para apartarte del golpe siguiente: si lo consigues (45 %, +6 % por cada punto de REFLEJOS), no te toca y tu golpe siguiente no falla y hace 3 más («Le pillas abierto.»); si no, te da entero. Contra la barra de Darko, si te apartas, la barra se queda en nada. CUBRIRSE sigue siendo lo seguro: la mitad del golpe y tu golpe siguiente asegurado. Una postura quita la otra.
- **Nuevo: AMENAZAR** (HABLAR → CALMAR o AMENAZAR). CALMAR es el HABLAR de antes (mejor con reputación). AMENAZAR funciona mejor cuanto más tocado está el otro (10 % de base y hasta un 60 % más según la vida que ha perdido, +3 % por punto de FUERZA, con un tope del 80 %): se lo piensa mejor y se va. Si falla, su golpe siguiente hace 2 más. A Darko no se le amenaza. Con la policía, nada cambia.
- **Nuevo: experiencia de pelea** (`PELEA`, `S.pelea`, `experiencia`). Cada pelea ganada da experiencia (un ladrón 1, un rival 2, Darko 3); con 2, 5, 9, 14, 20, 27, 35, 44, 54 y 65 subes un nivel y eliges qué entrenas: **FUERZA** (+1 de daño en cada golpe) o **REFLEJOS** (+2 % de puntería, hasta el 98 %; +6 % de esquivar, y +4 % de escapar de ladrones y rivales, hasta el 70 %), hasta 5 cada una. Al subir hay que elegir: B no la salta. Sigues ganando VIDA máxima como antes. En la MOCHILA, la fila **Pelea** (desde la primera victoria) dice el nivel, la fuerza, los reflejos y lo que falta para el siguiente.
- Igual en Godot. `docs/ANALISIS.md` sigue sin experiencia de pelea (HABLAR es CALMAR).
- Tests: `npm test` 102/102 (paso nuevo con esquivar, la contra, amenazar, la rabia, Darko, subir de nivel, los topes y la fila de la MOCHILA); Godot, historia 102 pasos.

## 1.17.0 · 13 de octubre de 2026

Más fondo: el ajuste de cuentas con Darko y la amiga de la tía Maite. Godot, 0.11.0.

- **Nuevo: el ajuste de cuentas con Darko** (capítulo 8, astilleros; `ajusteDarko`, `DARKO`, 13-combate). Al hablarle, te reta: «Esto lo arreglamos tú y yo». Pelea como un rival con 4 de vida más y, a veces (30 %), coge una barra de hierro: el golpe siguiente vale el doble, y CUBRIRSE lo deja en la mitad. Con él no vale HABLAR, y lleva la «!» mientras te espera. Si le ganas («Darko cae al suelo, sin aire.»; +10 de reputación y +2 de VIDA máxima), se va de los astilleros (`S.flags.darkoFin`): ni él ni sus chicos vuelven a salirte al vender, y Don Baltasar te escribe. Si te vence o huyes, te espera allí.
- **Nuevo: Miren** (Errotabarri, desde el capítulo 4; `talkMiren`, `MIREN`, 11d-comarca), la amiga con la que la tía Maite cultivaba hace treinta años. Te pide 20 g de Purple Thai, la que hacían las dos (de uno o varios lotes; primero los que no son estrella), y te da la página que faltaba del diario (`PAGINA`, al final del DIARIO DE LA TÍA MAITE: de dónde salió la deuda con Baltasar) y 5 semillas de Haze.
- CUBRIRSE asegura también tu siguiente golpe (1.16, tras la revisión).
- En el combate, Darko lleva el sprite del ladrón (su personaje del atlas es de 32 px) y Miren, el de un cliente: el arte propio de los dos queda pendiente.

## 1.16.0 · 12 de octubre de 2026

El diario de la tía Maite, los rivales de cada zona y la casa a tu gusto. Godot, 0.10.0.

- **Nuevo: el diario de la tía Maite.** El recetario de la Genoteca es ahora su cuaderno (DIARIO DE LA TÍA MAITE): cada una de las 32 variedades de receta lleva su nota escrita por ella (`DIARIO`, 12-menus), encima de sus recetas y de dónde sale cada semilla.
- **Nuevo: los rivales** (`RIVALES`, 13-combate): en el barrio alto, Puerto Viejo, Valdehierro, el Casco Viejo, el Ensanche y la Kale Zaharra, desde el capítulo 3, un camello que no quiere competencia (los astilleros siguen siendo de Darko). Cada venta en la calle de su zona le suma una; a la 8.ª sale a buscarte: pelear (más duro que un ladrón: +6 de vida y +1 a cada golpe), pagarle su cuota (200 € por el precio de la zona) o apartarte (vuelve 2 ventas después). Si le ganas, se va 7 días, sus clientes te pagan un 5 % más y ganas reputación.
- **Nuevo en los combates: CUBRIRSE** (LUCHAR → CUBRIRSE): el siguiente golpe duele la mitad.
- **Nuevo: personalizar la casa.** En la tienda online, el sillón orejero con lámpara de pie (229 €; desde él se lee el diario de la tía Maite, 30 min) y un cuadro para la pared del salón (59 €). El sofá y el sillón cambian de tapizado (tres cada uno) y el cuadro, de lámina (la ría, el caserío o la hoja), desde el propio mueble (`DECO`, `S.deco`; arte a mano en `tools/sprites/a-mano/salon.py`).

## 1.15.0 · 12 de octubre de 2026

La gente: confianza con cada persona, trabajadores, clubs cannábicos y la cata. Godot, 0.9.0.

- **Nuevo: la confianza** (`S.rel`, de 0 a 100; MÓVIL → GENTE) con cada persona con nombre. Sube hablando (1 al día), vendiendo a buen precio a los de la agenda (rebaja 3, justo 2, caro 1), con regalos (2 g: +5, una vez al día) y favores (Txaro, +10; cada compra a Kiko y cada venta a Iñaki, +1); baja pidiendo caro (−2) o fallando. Con 20 (amigo): Kiko hace un 5 %, Iñaki paga un 5 % más al por mayor, Begoña se deja contratar y los de la agenda aceptan mejor el precio (+confianza/250). Con 50 (socio): uno de la agenda vende para ti.
- **Nuevo: trabajadores.** Begoña, de jardinera (desde el cap. 3, con 20 de confianza): cada mañana riega todas las plantas, rellena garrafas y depósito y trata las plagas con tu insecticida, por 20 € (sin dinero, se va; calor +0,5 al día). Vendedores a comisión (hasta 2, desde el móvil): un cliente de la agenda con 50 al que le dejas 25, 50 o 100 g; cada día vende de 5 a 15 g a precio de calle del barrio y te deja el 70 % en el buzón (SMS). Riesgo diario: un 4 % de que lo pare la policía (pierde lo que lleva, calor +10) y hasta un 10 % de que se largue con todo (menos cuanta más confianza; sale de la agenda).
- **Nuevo: clubs cannábicos** (`CLUBS`): CLUB ITSASO (Puerto Viejo) y CLUB LA FUNDICIÓN (Valdehierro) desde el cap. 3, CLUB KALEA (Casco Viejo) y CLUB ENSANCHE desde el 4, con el encargado en la puerta. Con el carné (30 o 50 €, una vez): vender un lote al día (50, 100 o 200 g, a 3 + 0,15 × THC € el gramo —entre Iñaki y la calle—, calor +1; un 5 % más si va analizado), comprar 10 g de la variedad del día (entra en la Genoteca) y encargos de semillas (10 de una variedad, en 7 días: las de tienda pagan un 20 % más de lo que cuestan y las de receta que ya tienes, 800 €; uno a la vez; si vence, reputación −3 y confianza −10).
- **Nuevo: la cata y el analizador de cannabinoides y terpenos.** En la MOCHILA, A sobre un lote: catar medio gramo (30 min) deja su nota (aroma por variedad, efecto por el % índica y la potencia) en la Genoteca, y el lote catado se vende algo mejor. El analizador de cannabinoides y terpenos (Kiko, 180 €, desde el cap. 3): analiza un lote —THC, CBD y su terpeno principal— (se vende mejor en la calle y un 5 % más en los clubs) y la cata dice el THC exacto y el terpeno de cada aroma.
- `docs/IDEAS.md`: lo pendiente, por tandas.

## 1.14.0 · 12 de octubre de 2026

La comarca crece con la historia: una ciudad grande, líneas de autobús que se abren por capítulos y un sitio con algo que hacer en cada pueblo. Godot, 0.8.0.

- **Nuevo: Ibarbide, la ciudad grande** (desde el capítulo 4; 4 € y 35 min en autobús). Dos barrios: el **Casco Viejo** (44 × 30: casas estrechas de piedra y madera con miradores, la Plaza Nueva con su fuente, la avenida y un parque) y, por la avenida, el **Ensanche** (46 × 22: bloques de pisos, la carretera y un parque con plaza y fuente). Cada uno con su música de día y de noche, 2 agentes de día (2 y 3 de noche), más ladrones en el Ensanche y el gramo un 30 y un 25 % más caro; clientes desde el capítulo 4 (3 en cada barrio, 4 desde el 5) y catadores de rosin. Fachadas dibujadas a mano (`tools/sprites/a-mano/mundo.py`: `casco`, `growcity`, `bloque`).
- **Nuevo: las líneas de autobús se abren por capítulos** (`PARADAS.cap`): Mendialde desde el principio, Puerto Viejo y Valdehierro en el 2, Errotabarri en el 3 e Ibarbide en el 4. Al abrirse, un SMS de la compañía.
- **Nuevo: GROW IBARBIDE** (Ane, en el Casco Viejo): el equipo de Kiko un 10 % más barato y un capítulo antes; sin semillas, carro ni aparatos de la sala.
- **Nuevo: la lonja de Puerto Viejo** (Nerea, desde el capítulo 3): carga para los barcos de fuera, de 100 a 500 g, un 15 % por encima de lo que paga Iñaki, cada 3 días.
- **Nuevo: la chatarrería del solar de Valdehierro** (Bixente, desde el capítulo 2): 3 piezas de equipo al día (focos, extractores, intractor, ventilador, calefactor, humidificador), de segunda mano, a mitad de precio.
- **Nuevo: el molino de Errotabarri** (Andoni, desde el capítulo 3): 3 semillas de una landrace del banco que aún no tengas por 20 g de lo tuyo, una vez por semana.
- **Nuevo: la Kale Zaharra** (Ibarbide, desde el capítulo 4): por un callejón entre GROW IBARBIDE y las casas del casco, una plazuela de piedra sin patrullas, con más ladrones y el gramo a ×1,3. Se vuelve por el mismo callejón. Algo hay escondido en el arbusto.
- **Cambiado: los mapas ya no son todo cuadrícula** (`senda`): los caminos de tierra de los parques del barrio, del Casco Viejo y del Ensanche van en curva; la Plaza Nueva lleva una fuente con parterre y jardineras con tres entradas, la plaza del Ensanche es ovalada y se entra por los huecos del seto, y la plaza del barrio tiene entradas por los lados.

## 1.13.0 · 12 de octubre de 2026

Patinete y bici, y un repaso de errores. Godot, 0.7.0.

- **Nuevo: el patinete y la bici** (`VEHICULOS`, 12c-salon). Se compran en la tienda online (Muebles y transporte: patinete 119 €, bici de segunda mano 239 €) y el mensajero los deja en el portal al día siguiente. En la calle (cualquier zona exterior) vas montado: el patinete, 150 ms por casilla (110 con B); la bici, 110 (80 con B), la más rápida para dejar atrás a una patrulla (los agentes corren a 180-210). En casa y en los interiores, a pie. La bici, corta (17 px de rueda a rueda, casi una casilla), para no invadir las casillas de al lado. Dibujados a mano (`tools/sprites/a-mano/vehiculos.py`) en dos capas, detrás y delante del protagonista, con las ruedas que giran y el pedal de la bici.
- **Arreglado: Darko ya no entra a robar durante una siesta**; solo al dormir hasta el día siguiente.
- **Arreglado: la redada solo se lleva lo de encima si estás en casa** (el arcón, siempre). El texto dice lo que encuentran, esquejes incluidos (o «No encuentran nada que llevarse») y la multa entera; si no te llega, cuánto pagas.
- **Arreglado: el aviso de la orden** solo menciona a Molina desde el capítulo 5 (antes no lo conoces).
- **Arreglado: la factura de la luz** dice lo que pagas y lo que te falta si no llega.
- **Arreglado: al cargar la partida** salen el aviso de la orden, la redada o el plazo vencido que quedaron pendientes al guardar en la cama.
- **Arreglado: los encargos de Baltasar** piden una bolsa en la que quepan (2 kg, bolsa de deporte; 5 y 10 kg, maleta).
- **Cambiado: los plazos dicen «antes de que acabe el día X»** (el día X todavía vale).
- **Cambiado: la ficha de la planta en la vista C** lleva su número o su nombre y la ★.

## 1.12.0 · 12 de octubre de 2026

Pantalla más alta, nombre nuevo y personajes sin caras que cambian. Godot, 0.6.0.

- **Cambiado: el juego se llama Landrace Hunters** (título, pestaña, aviso de edad, créditos, privacidad y las dos apps). Ribera Verde sigue siendo el barrio; los paquetes de Android (`com.riberaverde.*`) no cambian, así que la app se actualiza encima y las partidas guardadas se cargan igual. En el título, LANDRACE / HUNTERS en dos líneas, arriba, sin tapar la hoja.
- **Cambiado: la pantalla, de 160 a 180 px de alto** (`SH`), píxel a píxel, y de 240 a 450 de ancho (`SW_MAX`, hasta 21:9). En la calle y el piso se ven más casillas; el título, la intro, el combate y la carpa (escenas de 240 × 160) van abajo y la franja de arriba es el reflejo de su fondo (en la vista C, negra).
- **Cambiado: los personajes, por partes** (`tools/sprites/a-mano/npc_cara.py`): la cabeza de cada uno sale de una sola pieza por dirección (la de su postura de base) en el idle y al andar, así la cara ya no cambia en cada fotograma; el idle es la postura de base respirando, sin el «ictus».

## 1.11.0 · 9 de octubre de 2026

Genética por generaciones, policía por niveles con aviso, accesorios de carpa que cuentan y misiones guiadas para pagar la deuda. Godot, 0.5.0.

- **Cambiado: el árbol de la genética** (`docs/GENETICA.md`). 59 variedades: los landraces y, por generaciones, los híbridos clásicos (1.ª: Skunk #1, Haze, Northern Lights, Purple Thai, AK-47, Master Kush…; 2.ª: Blueberry, Super Skunk, Shiva Skunk, Critical Mass, Cheese, Amnesia Haze…; 3.ª: Jack Herer, Super Silver Haze, Blue Dream, Blue Cheese, Sour Diesel, Kali 47…). Los de linaje dudoso llevan «≈ origen incierto». Nuevas: Kali Mist, Cheese, California Orange, Chemdawg, Colombian Gold, Chocolate Thai, Highland Thai, Hawaiian, AK-47, Laughing Buddha, Cannalope Haze, Congo × Panama, Malawi × Panama, Malawi × PCK, NL5 × Haze, Neville's Haze, Chocolope y Kali 47; renombradas a su nombre real las que no lo eran. Sin criadores, bancos ni personas en el juego.
  - **Recetas por conjunto de variedades:** un híbrido propio recuerda de qué variedades sale, así que las de 3 o 4 padres (Skunk #1, Amnesia Haze, Jack Herer…) se sacan cruzando en cualquier orden; las que dependen de quién es la madre (Super Skunk, Critical Mass, NL5 × Haze, Silver Haze) siguen dependiendo.
  - La meta del final es la **Jack Herer** (Haze × (Northern Lights × Shiva Skunk)); la Copa se gana con Amnesia Haze o Sour Diesel.
- **Cambiado: la policía, por niveles y con aviso.** El calor marca el nivel: tranquilo (0-29) y vigilancia (30-59) bajan 12 al día; investigación (60-89), 8 y una patrulla más por zona; con 90 al cambiar de día, **orden de registro**: el calor no baja, Kiko te avisa por SMS y la redada llega al día siguiente. El HUD dice ORDEN mientras dura. Con la protección de Molina, la bajada es × 1,5 y no hay orden.
  - **La redada es justa:** se lleva las plantas, el equipo montado en sus carpas y lo que está a la vista (lo de encima y el arcón). **La caja fuerte no la tocan**: solo sale de ella la multa que no llegue con lo de fuera. La multa es por lo que encuentran: 601 € + 300 € por planta + 3 € por gramo, hasta 30.000 €; el calor queda en 40. Con el día de aviso, guardar en la caja es la jugada.
- **Nuevo: accesorios de la carpa que cuentan.**
  - **Extractores con filtro de carbón** de 100, 125 y 150 mm (250, 400 y 750 m³/h; 75, 110 y 190 €). Cada carpa pide un caudal (su volumen renovado cada minuto, × 1,3 por el filtro, más lo que calienta su foco). Sin extractor, la floración suma 2 de calor al día; con uno corto de caudal, 1; a su medida, nada. Montar uno nuevo devuelve el anterior a la mochila.
  - **Intractor** de 100 mm (45 €): sin él, el extractor rinde un 85 %.
  - **Clima por carpa:** de día, el foco calienta la carpa (el sodio más que el CFL, el LED lo que menos) y cada planta suma humedad; el extractor se lleva casi todo. PLANTAS enseña el caudal y, con termohigrómetro, el clima de dentro. Fuera de rango, crecen menos; con humedad de noche en flor, moho (el aviso de la mañana lo dice por carpa).
  - **Ventilador:** crecen un 3 % más, la mitad de moho y plagas × 0,7.
  - **Abono por fases y pH/EC:** abono de crecimiento (12 €, crecen hasta un 15 % más en vegetativo) además del de floración; **pH−** (6 €, 10 dosis): sin él, el abono rinde la mitad, y con él, tres cuartos; con el **medidor de pH/EC** (35 €), entero, y PLANTAS enseña la EC y el pH de cada maceta.
- **Nuevo: música por zona.** Cada zona de la calle suena distinta, de día y de noche: Ribera (la de siempre, ahora con una segunda parte y batería), el barrio alto (lounge en fa, con séptimas), los astilleros (industrial en mi menor, bajo de sierra), Puerto Viejo (vals marinero), Valdehierro (mina, la menor dórico), Mendialde (6/8 de caserío con flauta) y Errotabarri (pastoral lenta). De noche, la misma canción más lenta, con flauta y sin bombo. Los interiores llevan la suya: la tienda (reggae), el bar (tango), la comisaría (tensa), el almacén (la de los astilleros de noche), la casa de Txaro y el piso (la de casa) y el caserío (la de Mendialde de noche). Al cambiar de canción, la que suena se apaga y entra la nueva. Todo original, en chiptune: ondas de pulso de 25 y 12,5 %, ligaduras, arpegios y batería de ruido (05-audio: las canciones se escriben en notas y acordes y `tema()` las convierte; Godot las sintetiza en un hilo aparte, primero la que toca).
- **Nuevo: misiones guiadas** (`11c-misiones.js`): lo que hay que montar para pagar la deuda a tiempo, en START → OBJETIVO, que ahora es una lista con el objetivo del capítulo, las misiones (con lo que cuesta cada cosa y dónde) y la deuda (el plazo, lo que llevas entre el bolsillo y la caja, ventas, reputación y calor). Salen desde que conoces a Kiko: la caja de la tía y luz de verdad (un LED de 100 W y macetas de tela) en el capítulo 1; una carpa, un extractor e Iñaki en el 2; el por mayor y un sodio de 400 W en el 3; un LED de 480 W y una carpa de seis plazas en el 4. Al cumplir una, Kiko manda un SMS y deja un regalo (abono, pH−, insecticida o semillas; nunca dinero). Siguiéndolas, el primer plazo se paga hacia el día 10 (vence el 12), el segundo hacia el 18 (vence el 22) y el último hacia el 20 (vence el 24). Las partidas guardadas dan por hechas las de los capítulos pasados, sin regalo.
- **Nuevo: el carro de esquejes** (165 €, en el growshop desde el capítulo 2). Kiko lo sube al piso al día siguiente y lo monta delante de las carpas: un carro con ruedas, dos bandejas de propagación de 12 tacos tapadas bajo tubos T5 y una mesita con la tabla de corte, el bisturí y la hormona de enraizamiento (dibujado a mano, `salon.py`). En la tabla de corte se pinchan los esquejes del propagador: en las bandejas aguantan 3 días (sueltos, 1) hasta que haya hueco en una carpa, y se plantan desde la plaza vacía como los demás («bandeja»). Con alguno pinchado, los tubos gastan 4 € de luz al día; la redada se los lleva.
- **Nuevo: avisos del plazo.** Toño manda un SMS cuando quedan 3 días y el último día, con lo que llevas y lo que te falta; el objetivo de los capítulos 3, 5 y 7 dice lo que llevas.
- **Cambiado: el calor de la calle.** Cada venta en la calle sube 2 + 0,3 por gramo (antes, 3 + 0,5; el rosin, 2 + 2,5 por gramo, `CALOR_CALLE`), y con 50 de calor sale un aviso que dice por dónde vender sin tanto calor (Iñaki). Con 200 partidas simuladas, el jugador que vendía en la calle a todo el que pedía pagaba el primer plazo a tiempo un 2 % de las veces (casi siempre llegaba antes la redada); con la calle nueva, unas tres de cada cuatro.
- Las cifras de los textos salen de las constantes del juego (`NIVEL_POLI`, `INTRA`, `VENT`, `ABONO`, `RENUEVA`, `FILTRO_X`), también en Godot: si cambia una, cambia el texto.
- **Arreglado: la luz al dormir.** El aviso de la cama enseñaba la factura del día cada vez que te acostabas, aunque fuera una siesta de 3 h que no pasa de las 12 y no cobra nada. Ahora dice solo lo que se ha pagado durmiendo (la factura sigue siendo de un día entero, a medianoche).
- **Arreglado: la cara del protagonista.** Cada fotograma de estar quieto, andar y correr traía su cara (en unos los ojos se juntaban y se quedaba bizco, en otros se abría la boca o cambiaba la gorra). Ahora la cabeza es la misma en todos, por dirección, con la cara de frente dibujada a mano (`tools/sprites/a-mano/player_cara.py`: ojos finos, sin brillo ni sombra de la visera en la frente), va pegada al cuerpo (sube y baja con él, sin bailar de lado) y de lado el cuello ya no parece barba. También en las acciones (cosechar, regar, plantar, oler, el móvil y vender) donde la cara se ve entera; donde se tapa con la mano, mira al móvil o pasa la regadera por encima, se queda como estaba. Quieto, respira en las cuatro direcciones: la postura de pie con la cabeza 1 px más abajo a la mitad, en vez de cambiar de cuerpo en cada fotograma (mirando a la derecha, el muñeco crecía 3 px al pararse). **Los ojos, más reales e iguales en todos los fotogramas:** de lado seguían con el blanco al lado de la pupila (saltones) y en las acciones cada uno era distinto. Ahora, de frente, párpado y debajo blanco, iris marrón y blanco; de lado, párpado y el blanco detrás del iris; los mismos al estar quieto, andar, correr y en las acciones (donde la cara se ve).
- **Nuevo: cada planta con su número y su nombre.** Cada planta lleva el número de su fenotipo («Skunk #1 nº 12») en la maceta, en PLANTAS, en la mochila y en las bandejas del carro, y sus esquejes, el mismo. En la maceta (también cuando está lista para cosechar), **Nombrar** le pone un nombre (hasta 12 letras, números, espacio y # ' . -) que heredan sus esquejes: «Skunk #1 «Madre Lima» ★». Con B no cambia nada; en blanco vuelve a su número. Para seleccionar madres sin perderse.
- **Nuevo: tirar semillas y esquejes.** En la MOCHILA, una semilla se tira de una en una o todas; un esqueje (también en las bandejas del carro) se nombra o se tira.
- **Cambiado: los nombres de los cruces, cortos.** Un cruce propio se llama con dos palabras de sus padres (hasta 20 letras, sin repetir otra variedad; si no queda ninguna, con «#2», «#3»…), nunca «A × B»: al cruzar cruces salían nombres de 50 letras. Las partidas viejas pasan a nombres cortos al cargar (la variedad es la misma). En la GENOTECA, A sobre una variedad propia le cambia el nombre (sin repetir el de otra, ni cambiando mayúsculas).
- **Nuevo: el recetario**, lo primero de la GENOTECA: las 32 variedades de receta con sus maneras de sacarlas (en cualquier orden o madre × padre) y, de cada variedad que entra, dónde se consiguen las semillas: el regalo de Kiko, Txaro o Iñaki, el growshop o el banco del PC (desde qué capítulo), una misión o su receta; la Acapulco Gold, escondida en el parque.
- **Nuevo: exportar la partida.** START → OPCIONES → EXPORTAR PARTIDA copia la partida (JSON) al portapapeles para guardarla en una nota o pasarla a otro aparato.
- **Nuevo: la caja de texto** (`pedirTexto`) para el nombre del jugador, el de una planta y el de una variedad: A (o Intro) acepta y B (o Esc) cancela, salvo en el nombre del jugador.
- Tests: `npm test` 91/91 (pasos nuevos de las plantas con nombre, los cruces cortos y el recetario, exportar la partida, la cama, del carro de esquejes, de la genética, la orden de registro, la redada con la caja y los accesorios; el menú OBJETIVO con las misiones, el SMS de Toño a 3 días del plazo y las misiones de las partidas viejas); `npm run analisis` con los niveles, la orden y la redada nueva jugados (`docs/ANALISIS.md` § 2.7).

## App de Android 0.4.0 (Godot) · 9 de octubre de 2026

La app de Godot es la de Android y pasa las normas básicas de un juego para móvil (`docs/NORMAS-MOVIL.md`); la ficha de Google Play, en `docs/PLAY.md`.

- **Nuevo: icono de la app**, dibujado a mano (`tools/sprites/a-mano/icono.py`): una hoja de 7 foliolos verde fresco con el halo del foco detrás, sobre la ribera de noche (la orilla y el río). Clásico y adaptativo (Android 8+, entero dentro de cualquier máscara), nítido en cada densidad, en las dos APK; el de la ficha de Play, a 512. Antes, la app de WebView recortaba la hoja del título y la de Godot llevaba un dibujo de prueba.
- **Nuevo: pantalla de arranque** con el icono sobre el fondo del juego (sin el logo del motor), y la app se llama «Ribera Verde».
- **Nuevo: aviso de edad** la primera vez: juego de ficción para mayores de 18 años; «SALIR» cierra la app.
- **Nuevo: el título** con CONTINUAR, NUEVA PARTIDA, **OPCIONES** y **CRÉDITOS** (créditos, licencias enteras de Godot y de las fuentes, y privacidad, en un texto con scroll; las licencias, unas 80.000 letras, por páginas para que abran al momento).
- **Nuevo: OPCIONES** (en el título y en el menú START, en lugar de SONIDO): volumen de la música y de los efectos por separado (de 25 en 25 %), velocidad del texto (normal, rápido o al momento), sonido y, en el título, borrar la partida. Se guardan aparte de la partida y se recuerdan. En el HTML, las mismas OPCIONES en START (sin borrar partida).
- **Cambiado: el botón Atrás** andando por el mapa abre la pausa (el menú START) en vez de cerrar la app; en el título sale. Al volver a la app, el juego espera en pausa.
- **Cambiado: START, MÓVIL y SONIDO se tocan en 48 × 48 dp** como poco (el mínimo de Android), aunque se vean igual.
- `docs/PRIVACIDAD.md` (no recoge ningún dato) y `docs/play/` (icono 512, gráfico destacado y capturas).

## 1.10.0 · 8 de octubre de 2026

Sale con el arte del plan de producción (`docs/PLAN-PRODUCCION.md`, P3–P6 cerrados). Godot, 0.3.0.

- **Nuevo: la carpa por dentro con todo el equipo (lámina B de la vista C).** Con el arte, la carpa se ve siempre por dentro (vista C); la vista B queda para cuando falta el arte. Dibujado a mano (`tools/sprites/a-mano/equipo_c.py`, sin PixelLab), con la paleta de la campana aprobada:
  - **Focos LED de barras** (como los de 720 W de 8 barras: barras delgadas con aire entre ellas): 3 barras el de 100 W, 4 el de 200, 6 el de 480 y 8 el de 720, cada uno a su ancho real en cada carpa, con la cara de diodos encendida (apagados, en gris). Su luz es la suya: blanca de espectro completo, algo rosada, un haz por barra que baja hasta el suelo y se abre hasta las paredes de la carpa (según el ancho de la carpa, el del foco y cuántas barras lleva), con un charco más ancho en el suelo; el **CFL** también en las carpas de 200 cm (la campana aprobada, más pequeña).
  - **Macetas** de tela de 11 y 25 L y de plástico de 18 L, cada una a su tamaño, con la tierra a su altura.
  - **La planta muerta:** la de su porte, seca y marrón, más baja y quieta.
  - **Extras:** el filtro de carbón colgado arriba (el extractor tiembla), el ventilador de pinza con las aspas girando (con él, las plantas se mecen el doble de rápido), el depósito del goteo con el agua que le queda en la mirilla y, en el suelo, un ramal por fila con la llave y el microtubo de cada maceta; con garrafas, cada maceta lleva la suya a su tamaño, con el agua que le queda y las rayas en la curva del cilindro.
  - Cada maceta deja su sombra en el suelo, y el suelo de la carpa se oscurece hacia los bordes.
  - **La luz del foco, lisa:** el cono ya no lleva la textura de la imagen A, que era la sombra de las cortinas; queda un resplandor bajo la boca del foco y un haz central, en los mismos tonos y con el color de cada foco.
  - **El foco sube a medida que crecen:** cuelga a la distancia que pide la fase de las plantas (germinando y plántula, 1,5 veces la distancia de seguridad del foco; vegetativo, 1,4; floración y lista, la de seguridad: el LED de 720 W a 60, 56 y 40 cm) de la planta que lo tiene más cerca (de una muerta, a la distancia de seguridad), y sube con ellas: mientras crecen, nunca baja. Bajado, cuelga de dos poleas del techo, cada una con su tirador, y su luz baja con él.
- **Nuevo: temporizador en cada carpa:** en la pared, a su izquierda (en el piso y en la vista de carpa), con la rueda de pinzas del color del modo: **automático** (18 h de luz mientras crecen y 12 en floración, como hasta ahora), **18/6** (las que no florecen aún, no florecen: madres para sacar esquejes; gasta más luz) y **12/12** (florecen ya: el vegetativo dura la mitad y la cosecha baja hasta un 40 %; gasta menos). Se elige en la vista de carpa con ◀ desde el foco o desde la planta de la izquierda, y A; la factura de la luz va con las horas del modo.
- **Nuevo: el salón del piso.** El piso crece a 18 × 8 m: a la derecha, el salón, vacío al llegar (es la casa de la tía). Los muebles se compran en la **tienda online** (en el ordenador de la tía, en el PC gaming o en el móvil), se pagan con lo que llevas y, si no llega, con la caja fuerte, y llegan al día siguiente, montados (`12c-salon.js`; arte a mano, `tools/sprites/a-mano/salon.py`):
  - **Sofá de 2 plazas** (399 €, 180 cm): una cabezada de 1 h (+5 de vida) o ver la tele desde él.
  - **Tele de 43" con mueble** (449 €): las noticias (según tu calor: el tiempo, una detención en el puerto o la policía buscando un cultivo en el barrio) o un documental (landraces, hachís, bancos de semillas), 1 h.
  - **PC gaming con mesa** (1.490 €): jugar 2 h, el **foro de cultivo** (consejos de verdad: pH, humedad en floración, madres a 18/6, fugas de luz y hermafroditas, tricomas, secado y curado, abono y riego, distancia del foco) y la tienda.
- **Cambiado: el menú START**, con un icono por opción y lo que importa a la derecha (variedades de la Genoteca, kilos encima, SMS sin leer, plantas vivas, capítulo, sonido SÍ/NO); arriba, el día, la hora y el dinero.
- **Nuevo: botón MÓVIL** encima de la cruceta (y la tecla P): abre el móvil de un toque, sin pasar por START. Solo se ve andando por el mapa.
- **Cambiado: nada se pisa en pantalla.** Los avisos se apartan del HUD (a su derecha si caben y, si no, debajo), de la ficha de la carpa y de SONIDO; con un menú a pantalla completa salen encima de él, abajo, y no detrás. En el combate, el texto no pasa por debajo del menú. El rótulo del título baja si SONIDO le pisa la esquina. Auditado en 11 tamaños de pantalla (de 568 × 320 a 1920 × 1080) y 11 estados: 0 solapes (antes, 40 de 121).
- **Cambiado: los iconos, alineados con el texto y pixel perfect.** Cada icono se centra en su celda por lo que pinta y en la línea del texto, y sale a un múltiplo entero de sus píxeles en la pantalla (16, 32, 48… píxeles del dispositivo; los de 32, también a la mitad): todos los píxeles, iguales.
- **Cambiado: el cogollo de la Genoteca**, redibujado a mano: verde fresco, con los cálices apilados, pistilos naranjas y la escarcha de los tricomas (el de antes parecía seco y marrón).
- **Cambiado: las carpas del piso, a su medida también de fondo.** El frente ya iba a su ancho y alto reales a 16 px/m; ahora el techo va a medio fondo como la nevera y los muebles: +1 px la de 100 y la de 150 y +2 la de 120 × 120 (`tools/sprites/a-mano/carpas_mapa.py`).
- **Nuevo: iconos del equipo** (lámina 12, a mano): armario, carpa, LED, ventilador, filtro, garrafa y goteo, en la tienda, la mochila, la lista de plantas y el menú de focos (los LED, de barras; el resto de focos, la lámpara).
- **Nuevo: la nevera y las cajas a escala** (lámina 13, a mano): la nevera de 60 × 180 cm y las cajas de 40 cm a 1 casilla = 1 m, en el piso y en el almacén.
- **Nuevo: sombras y noche en el piso.** Los muebles (mesas, taburetes, nevera, cajas, mostradores, la gramola, la cama…) dejan su sombra en el suelo sin pisar la del vecino. De noche el piso se oscurece como la calle y cada carpa con plantas vivas deja delante una mancha de luz del color de su foco.
- Igual en Godot (0.3.0): 9 escenas de la vista C (LED y extras, garrafas, muertas) y 29 pantallas (con el piso de noche) comparadas con el HTML, 0 diferencias; la partida jugada con los mandos ve siempre la vista C.

- **Nuevo: el móvil.** En el menú START, estés donde estés (`12b-movil.js`):
  - **Llamar** a Kiko (un consejo), a Toño (lo que debes y hasta cuándo) y a Iñaki (la carga al por mayor del día).
  - **Agenda de clientes:** quien te compra en la calle te da su número (hasta 8, con nombre propio). Llamado, viene a buscarte a la calle en 20 minutos (+1 de calor), una vez al día y nunca con la policía detrás; desde casa, «Quedamos en la calle».
  - **Pedir a Kiko** lo del growshop (no semillas, carpas ni la prensa): un 15 % más caro y llega a casa al día siguiente por la mañana, con su SMS.
  - **Mensajes:** los SMS de Kiko, Toño, Iñaki, Molina y Darko se guardan (los 30 últimos).
- **Nuevo: el arcón y la mochila con tope.** Lo que llevas encima (cogollos y rosin) tiene tope: la mochila 1 kg, la bolsa de deporte 3 kg (35 €, capítulo 3) y la maleta con ruedas 10 kg (90 €, capítulo 5). Al cosechar, lo que no cabe va al arcón de casa, entre la cama y la nevera: guardar todo, guardar o sacar un lote (hasta el tope; de la caja fuerte, igual). Un control en la calle no lo ve; una redada se lo lleva (no la caja fuerte) y Darko, la mitad (y cuenta para que entre a robar). La mochila del menú enseña las dos cosas.
- **Nuevo: el clima de la sala** (`09c-sala.js`). Temperatura y humedad según el mes (12 días son un año; el día 1 es abril), de día o de noche, el calor de los focos encendidos (el sodio calienta 2,5 veces más que el LED), la humedad de las plantas y los extractores con filtro. Fuera de 18-30 °C o 40-60 % las plantas crecen más despacio (−6 % por grado y −1,5 % por punto) y, con la humedad por encima del 60 % en floración, les sale moho (−0,1 de salud por hora y punto de más; lo avisa al despertar). Kiko vende el termohigrómetro (12 €; sin él, PLANTAS enseña «¿?»), el calefactor, el humidificador, el deshumidificador y el aire acondicionado: son termostatos (el calefactor sube hasta 6 °C, el aire baja hasta 12, el humidificador sube 15 puntos y el deshumidificador baja 20), solo trabajan con plantas y se pagan en la factura de la luz. Lo pedido por el móvil no se vuelve a vender en la tienda.
- **Cambiado: el riego automático, en dos niveles.** Antes el goteo regaba la mitad para siempre. Ahora:
  - **Garrafas de riego** (15 €, capítulo 1, una tanda por carpa): una garrafa con gotero junto a cada maceta, de 0,65 L por litro de su tierra (16 L la de 25 L): le dura media cosecha. «Rellenar garrafas» en la vista de carpa, que enseña los litros que quedan.
  - **Riego por goteo** (1.200 €, capítulo 4; antes 55 €): un depósito grande con bomba para toda la carpa de 6,5 L por litro de tierra que admite (650 L la de 100): unas cinco cosechas con la carpa llena. Se rellena con «Rellenar depósito». Al ponerlo, las garrafas de esa carpa vuelven a la mochila. Un goteo de una partida vieja sigue puesto y se rellena hasta su nuevo tamaño.
  - Los dos riegan igual: la planta que baja del 50 % vuelve al 100 % gastando la mitad de los litros de su maceta por cada 100 %; vacío, no riega. En la vista B, cada maceta lleva su garrafa detrás a la derecha (de 5 a 16 L, a su tamaño real, con el agua que le queda y el tubo del gotero) y el depósito del goteo va al lado de la carpa a su tamaño real (de 234 a 975 L: un cilindro de 0,6 a 1 m de ancho, con los aros curvados como el cilindro y un tubo de nivel con el agua que le queda); su manguera entra por la pared derecha y baja al suelo, de ahí sale un ramal por detrás de cada fila y cada maceta tiene su llave y su microtubo, que sube por su lado hasta el borde, a la altura de su maceta, y entra en la tierra; la vista C también las dibuja (ver arriba); al cambiar la maceta, su garrafa queda llena. Una cosecha gasta ~1,3 L de agua por litro de tierra (1-1,7 según foco, maceta y variedad: medido con el juego).
- **Arreglado: los restos de las cortinas en la vista C.** La luz del foco aún tenía 40 píxeles de los brillos de las cortinas junto al suelo (x 32-35 y 203-207), fuera de la bandeja; borrados.
- Igual en Godot: los cuatro cambios, con sus 5 pasos en la historia (82, 0 diferencias con el HTML).

- **Cambiado: la carpa por dentro (vista C), plateada.** La pared verdeazulada con cortinas de la imagen A da paso a la tela plateada (mylar) y el armazón negro de las carpas del piso y de la vista B: vetas verticales, laterales más oscuros hacia delante, la bandeja blanca con su rejilla, los postes y la cremallera de la puerta abierta. Misma pared del fondo y laterales, así que plantas, macetas, focos y luz van donde iban; la luz del foco pierde los brillos que tenía pintados en las cortinas. Dibujada a mano (`tools/sprites/a-mano/carpa_c.py`). Igual en Godot.
- **Nuevo: tope de tierra por carpa.** Además de la maceta más grande que cabe en cada plaza, la tierra de todas las macetas de una carpa no pasa de 100 L por m² de suelo (`LITROS_M2`; 36 L el armario de 60, 64 el de 80, 100 la carpa de 100, 144 la de 120 y 150 la de 150). «Cambiar maceta» solo ofrece las que caben y, si no cabe ninguna por la tierra, lo dice («No cabe más tierra en la carpa (tierra 132 de 144 L)»); la ficha de la carpa en PLANTAS enseña el tope y lo puesto. Igual en Godot.
- **Cambiado: la carpa abierta, con las plateadas.** La vista B (desde la lámina B de esta versión, solo cuando falta el arte de la vista C) ya no pinta la carpa en 3/4 por código: pinta de frente la carpa plateada aprobada de su tamaño (`carpa-<t>-vista`, las 5, también las de 80 y 120) y las macetas, plantas, focos y extras se colocan sobre su suelo, que se cierra hacia el fondo. La escala pasa de 48 a 60 px/m de ancho y alto, la del sprite: el foco, a 28 cm del techo, cuelga justo bajo el techo de dentro del dibujo, y nada de lo que cuelga sube de ahí; el depósito del goteo va al lado de la carpa, con el tubo por la puerta. Sin atlas sigue la de 3/4. Igual en Godot.
- **Cambiado: el rosin, como la flor.** La caja fuerte lo guarda y lo saca («Guardar rosin» / «Sacar rosin», y también «Guardar todo» y «Sacar todo»), en el mismo hueco que los cogollos; lo de dentro no lo toca Darko, que se lleva la mitad del de fuera, y la redada que encuentra la caja se lo lleva también. Los ladrones y el robo de Darko cuentan el rosin como la flor de la que sale (1 g = 5 g). La mochila enseña el rosin de la caja. Igual en Godot.
- **Nuevo: perder el último autobús.** Fuera de hora, el poste de la parada ofrece «Esperar al de las 7:00» (el reloj corre hasta las siete y sigue el viaje); en Mendialde, la cama de casa de ama: «Dormir hasta las 7», sin robo de Darko ni avisos de las plantas del piso.
- **Arreglado: la barra de sospecha, al momento.** El HUD la repinta en el fotograma en que cambia (antes, hasta 250 ms tarde). Igual en Godot.
- **Nuevo: el armario de 80 y la carpa de 120 con arte** (`tools/sprites/a-mano/carpas.py`), alargando por dentro el arte aprobado de sus vecinas (de 60 y de 100): solo columnas y filas que ya estaban, misma paleta. Aprobados los de la vista B; los del piso, pendientes de aprobación.
- **Mandos a la medida del pulgar.** Se miden en milímetros (1 px CSS = 1/160 de pulgada) y van donde descansan los pulgares con el móvil en horizontal: cruceta de 24 mm (brazos de 8; antes 19 y 6,5 en un móvil de 360 de alto) con el centro a 16 mm del lado y 18 de abajo (antes 12 y 12), A y B de 10,5 mm (antes 8,6) inclinados 28°, A a 12 mm del lado y 19 de abajo, START encima de A, al alcance del pulgar (antes arriba del todo), y SONIDO arriba a la derecha, de 7 mm de alto (antes 4). La cruceta es de un dedo: se desliza de una flecha a otra sin levantarlo y responde 3 mm por fuera de la cruz; A y B, 2,5 mm por fuera de cada botón. En un móvil estrecho encogen hasta que el escenario de diálogos cabe entre ellos (en 568 × 320, del tamaño de antes); el escenario se estrecha para dejarles sitio (740 × 360: 1,46 px por píxel en vez de 1,9; nunca menos de 1,3), también con la muesca a un solo lado. En el combate, la caja de vida se aparta de A, B y START. Si el juego pierde el foco con un dedo puesto (otra app, la pantalla apagada), los mandos se sueltan. Igual en Godot.
- **Nuevo: la comarca, por biomas, y el autobús.** Además de Ribera Verde (la ciudad grande: el barrio, el barrio alto y los astilleros), dos ciudades pequeñas y dos pueblos, cada uno con sus casas, sus clientes y su riesgo (`ZONAS`): **Puerto Viejo** (40 × 24; casas marineras de colores, paseo y pantalanes; un agente de patrulla, ladrones ×0,6, el gramo ×1,15; turistas), **Valdehierro** (40 × 24; bloques de ladrillo, la fundición y un solar vallado; un agente, ladrones ×1,4, el gramo ×0,9), **Mendialde** (48 × 34; caseríos, plaza, maizal y manzanal) y **Errotabarri** (36 × 24; el río, el puente y el molino), los dos pueblos con sin policía, ladrones ×0,1 y un solo cliente al día. Se va en **autobús**: en el poste de cada parada (de 7:00 a 21:00), a dónde, cuánto (2–3 € desde Ribera Verde; entre dos de fuera, la suma) y cuánto tarda (20–40 min, que corren en el reloj). Un vecino en cada sitio (vecina, excursionista, turista y obrero) y sus carteles.
- **Nuevo: el prólogo en el pueblo.** La partida empieza en el caserío de la familia, en Mendialde: Kiko llama por teléfono, ama deja una nota y un táper de alubias en la nevera (un bocata) y el primer autobús, que paga ama, te deja en la parada de enfrente del piso. Las partidas guardadas de antes siguen en el piso.
- **Arreglado: los árboles, a escala, y el arte de cada sitio.** El árbol medía 1,5 m: ahora 5,8 m (6 m reales), con su sombra y tapando lo de detrás; los lindes de los mapas son monte (bosque espeso) y seto, y ya no hay nada escondido bajo una copa (los clientes no salen tapados). La comisaría (sillar, puerta doble) y el almacén (nave de chapa, puerta corredera) tienen su fachada en vez de la gris de Txaro; caseríos con su puerta, casas marineras, bloques de ladrillo, la fundición y la parada, todo dibujado a mano (`tools/sprites/a-mano/mundo.py`, sin PixelLab). Los objetos altos ya no aparecen de golpe al entrar en pantalla.
- **Cambiado: el mundo, menos cuadriculado.** Los árboles y el monte ya no van a compás de la rejilla: cada uno se corre unos píxeles (hasta 6 a los lados y 3 arriba o abajo) y la mitad va en espejo, siempre igual para la misma casilla; hay dos árboles nuevos (un árbol alto de copa estrecha y el manzano). La hierba lleva detalles sueltos (flores, matas, piedras y hojas) en 1 de cada 4 casillas y los firmes nuevos, variantes (juntas, musgo, manchas, charcos, baches y grietas). Los bordes de los mapas de la comarca entran y salen y hay bosquetes. **Mendialde** crece a 48 × 34 y tiene partes: arriba, el barrio viejo por pistas de hormigón; en medio, la carretera y la plaza; abajo, las afueras por una pista de tierra (el maizal, el manzanal y una borda). **Errotabarri** (36 × 24) no tiene asfalto: una pista de tierra cruza el río, que ahora serpentea, por un puente de madera. **Valdehierro** tiene la carretera rota (baches, parches y la raya borrada) y una nave entre los bloques. Casas de varios tamaños, parecidas entre sí: el caserío pequeño (6 × 5), la borda (4 × 4) y las casas marineras de 3 × 5 y de 5 × 7 (dos pisos) de Puerto Viejo. La vecina, el excursionista, el turista y el obrero salen ya con su sprite del atlas (el manifiesto los tenía y el atlas no se había rehecho). Todo dibujado a mano (`tools/sprites/a-mano/mundo.py`), igual en Godot; el barrio, el barrio alto y los astilleros conservan su trazado (solo se mueven sus árboles).
- **Nuevo: la caja fuerte de la tía.** Detrás del diploma de la Copa de 1998 hay una caja con rueda de cuatro cifras; la pista está en las notas del ordenador («la combinación, el año en que lo gané») y dentro hay 300 €. Caben 20.000 € y 2 kg, y lo que está dentro no va encima: no cuenta para los encuentros ni para el soborno, y no te lo quitan un control, un ladrón ni Darko. En una redada la encuentran 1 de cada 4 veces. Desde el capítulo 4, por el ordenador, la **caja empotrada** (380 €, la instala Kiko al día siguiente): 50.000 € y 2,5 kg. La luz, el ordenador y la multa de la redada se pagan de fuera y, si no llega, de la caja; la mochila enseña las dos cosas.
- **Nuevo: el mapa crece.** Dos zonas de 40 × 30 con su riesgo: el **barrio alto**, al norte (plaza del Ensanche y la comisaría; 2 agentes de patrulla también de día y la mitad de ladrones; pijos y turistas desde el capítulo 3), y los **astilleros**, al este del muelle (el almacén; un solo agente, también de noche, el doble de ladrones y el gramo un 20 % más caro, pero son las esquinas de Darko: 1 de cada 3 ventas acaba en pelea). Y tres interiores: la casa de Txaro, la comisaría y el almacén. Cada zona tiene sus farolas y su secreto (80 € en un arbusto del barrio alto, 2 sprays en los astilleros).
- **Nuevo: patrullas de policía que se ven.** La policía ya no sale al azar al dar un paso: los agentes andan por la calle (desde el capítulo 2; 1 de día y 2 de noche en el barrio, 2 en el barrio alto, 1 en los astilleros, Puerto Viejo y Valdehierro, ninguno en los pueblos), siguen recto, se paran a mirar y giran (`10b-patrulla.js`). Ven 5 casillas hacia delante en cono, si no tapa un edificio, un árbol, un seto o unas cajas; de día se ve el cono, de noche no.
  - **Sospecha:** si un agente te ve con algo encima, se llena la barra SOSPECHA del HUD: de día, despacio y con aviso («Un agente te está mirando»); de noche, 2,5 veces más deprisa y el aviso («Oyes pasos detrás de ti») llega tarde. Sube más con más gramos (hasta 100) y con calor, y la protección de Molina la divide por 2,5. Sin verte, baja. Vender con un agente a 5 casillas o menos (aunque no mire) la sube 60 de golpe. Si una persecución deja a un agente fuera de la calle, vuelve a ella; si al amanecer se va el que te seguía, lo has despistado. Al caer KO, el ladrón también se lleva la mitad del rosin, y ahora lo dice.
  - **Alarma:** llena, suena la alarma («¡ALTO, POLICÍA! Corre (B): métete en un portal o aléjate.») y, tras 0,6 s quieto para dar tiempo a reaccionar, el agente corre a por ti. Corriendo le sacas distancia; andando, no. Si se pone a tu lado cuando estás parado, control (el de siempre: sobornar, hablar, huir o entregar). Te pierde si entras por una puerta, sales del mapa o subes al autobús, o a más de 10 casillas y 4 s sin verte. Tras un control, 30 s de tregua.
  - Lo de la caja fuerte no cuenta: sin nada encima, ni sospecha. Los ladrones siguen saliendo al azar, pero no mientras te persigue un agente.
- **Nuevo: rosin.** Kiko vende una prensa (250 €, capítulo 3). En la mesa del piso, «Prensar rosin»: de 5 g de cogollo sale 1 g con el triple de THC (hasta el 75 %), en media hora. Lo compran los catadores, clientes nuevos con su propio bocadillo (una gota ámbar): 1-3 g, a 10 + 0,6 × THC el gramo (unos 42 € al 54 %); 2 al día en el barrio y 1 en los astilleros, Puerto Viejo y Valdehierro. Prensar compensa desde el 12,5 % de THC de la flor, y cada gramo vendido sube el calor 2,5. La mochila y el HUD enseñan el rosin aparte; en Godot, lo mismo.
- **Cambiado: el guion, completo** (los 8 problemas de `docs/ANALISIS.md`):
  - el **capítulo 4** pide sacar en la mesa 2 variedades de receta y cosechar una planta de cada (antes se pasaba solo comprando semillas);
  - el **primer plazo** corre desde que aparece Toño («tienes siete días para el primer pago»); si tardas más de 2 días en ir al bar, Baltasar te recibe con «Llegas tarde»;
  - **Darko** roba el piso en el capítulo 7 (la primera vez que duermes con más de 1.000 € o 100 g fuera de la caja se lleva la mitad) y desde entonces vigila los astilleros;
  - **Baltasar** da encargos en el imperio: 2 kg (5 y 10 kg en los rangos altos) a 6 €/g, entregados de noche a Toño en el almacén en 2 días; si fallas, reputación −10 y 5 días sin encargos;
  - al **tercer plazo vencido**, Toño se lleva la carpa más grande del piso con sus plantas (sin carpas, la mitad del dinero);
  - la Copa ya no es «el sábado»: se juega «estos días»;
  - **Molina** cobra 1.500 € cada 10 días, en la comisaría del barrio alto, y avisa por SMS cuando se acaba;
  - el objetivo del capítulo 2 dice «vendiendo»;
  - y la abuela Txaro, en su casa desde el capítulo 4, pide 10 g de una índica y da 3 semillas de Chitral Kush.
- **Cambiado: el equilibrio de la calle.** Al por mayor sube el calor 2 + 1 por cada 100 g (antes, por cada 250 g); el soborno suma el 5 % del dinero que llevas encima; los ladrones, desde el capítulo 5, tienen 4 de vida más y pegan 1 más.
- **Arreglado: las puertas de los edificios grises y las alturas.** En la casa de Txaro, la comisaría y el almacén la puerta ya cabe: las dos ventanas de abajo se apartan 9 px hacia fuera (`fachada_puerta.py`, fachada `gray-puerta`) y la puerta es una sola, la de casa, sin pisar la pared. La farola mide 3,5 m (antes 1,69), el mostrador y la barra 1 m (antes 0,69; la barra ya es más alta que los taburetes) y la gramola 1,5 m (`alturas.py`, retoque a mano, sin créditos); las ventanas y los carteles de pared (el diploma) se cuelgan a 0,9 m, las baldas de las plantas a 1 m y el botellero a 1,05 m (`ALZA`).
- **Arreglado (revisión):** Toño ya no pide el encargo en el almacén cuando el plazo se acabó («El plazo se acabó. Don Baltasar ya te escribirá.»); Darko y el aviso de la plaza no vuelven a salir en el pueblo desde el capítulo 7.
- **Nuevo: análisis del guion y de los riesgos de la calle** (`docs/ANALISIS.md`, `npm run analisis`): la historia y las misiones, probabilidades de ladrones por paso, por zona y por trayecto, la sospecha y la huida de las patrullas, cada estrategia de combate, el soborno, el calor, la redada, la Copa y la caja fuerte. Las tablas salen de un modelo exacto y se comprueban jugando cada caso con las funciones del juego, también los viajes y la redada con la caja llena.
- **Nuevo: el juego entero en Godot 4 (`godot/`, 0.2.0).** Lo que empezó como corte de prueba (la vista C y un ciclo de cultivo) es ya el juego completo portado a Godot 4.3: el barrio, el piso, la tienda y el bar con sus personajes y clientes, la historia de los 8 capítulos con la deuda, el imperio y el final, el cultivo entero (esquejes, cambio de maceta y de foco, extras, Genoteca, banco de semillas y mesa de genética), la carpa en vista B y en vista C, los combates, el título y la intro, los menús, el sonido y el guardado. Sale como APK aparte (`npm run godot:apk` → `dist/ribera-verde-godot.apk`, paquete `com.riberaverde.godot`), que se instala al lado del de siempre.
  - **Igual que el HTML, comprobado:** la historia 1 → 8 con el mismo piloto y el mismo azar que `npm test` (77 pasos, con la caja, las zonas, el guion nuevo, el prólogo, el autobús, el rosin y las patrullas; 0 diferencias en diálogos, estado y dónde está cada cosa); 27 pantallas pintadas por los dos y comparadas píxel a píxel (el piso, la calle de día y de tarde, la tienda, el bar, el barrio alto, los astilleros de noche, la casa de Txaro, la comisaría, el almacén, Mendialde, Errotabarri, Valdehierro, Puerto Viejo al atardecer, una patrulla de día con su cono y otra de noche persiguiéndote, la vista B y la C, los combates, los títulos y la intro: lo opaco, idéntico; lo que se mezcla, como mucho a 4 de 255 por canal); la vista C, los ciclos de cultivo, la cama y la cosecha como en el corte.
  - **Jugado con los mandos:** una partida nueva desde el título (con el nombre escrito a mano), el menú START entero, un paseo por la calle y un ciclo de cultivo de punta a punta, andando hasta la carpa y hasta la cama, con el dedo, el teclado y el ratón, y CONTINUAR desde el título (`tests/ciclo.gd`).
  - Los mandos, menús, diálogos, avisos y el HUD van como en el HTML; en el ordenador, los mandos salen del tamaño de un móvil.
- **Nuevo en el HTML: barras, avisos y daños de plaga** (los tenía solo el port de Godot). Encima de cada planta, una barra de agua (roja y parpadeando por debajo del 30 %: toca regar) y otra de cosecha (dorada y parpadeando cuando está lista), con una «!» roja si tiene plaga; las de delante de la planta elegida, en transparencia como su planta, y ninguna pisa a otra ni al cursor. Al despertar, un aviso dice qué plantas han cogido plaga (y cuánto insecticida queda), cuáles la siguen teniendo y cuáles se han secado del todo esa noche. En la vista C, la plaga se ve en la planta: manchas amarillas y pardas y punteado en las hojas, telilla y podrido en los cogollos, sacados de los píxeles de cada sprite y más fuertes cuanta menos salud le queda; tratada, vuelve a ser la de siempre.
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

## Notas del código por versión (fase 8)

Los comentarios del código que empezaban por su versión («# 1.51: …») la pierden aquí; esta es la lista, por versión, con el archivo y lo que comentan.

### 1.57.2
- `escena_viaje.gd` · `HUERTO`: (lo pidió el usuario: «que se vea alguna planta en vegetativo, alguna floración, dependiendo del punto del año… cómo sería el
- `mundo.gd` · `montar_taller`: (lo pidió el usuario): el taller por zonas, con CAL; montar_locales lo vuelve a poner cada vez que rehace el local
- `mundo.gd`: (lo pidió el usuario: «está muy vacío… el atrezo deja que desear o por lo menos cómo está usado»): el taller, cada cosa en
- `mundo.gd` · `TALLER_SUELO`: el suelo del taller por zonas (x0, y0, x1, y1, casilla): el hormigón de los puestos (con manchas de aceite por hash_t), la

### 1.57.1
- `calle.gd` · `gx`: (lo pidió el usuario: «las extracciones se deberían de poder fumar también con tabaco, sin tabaco no, porque sería con la
- `escena_viaje.gd` · `CALLE_FIL`: (lo pidió el usuario: «que aparezcan en la pantalla de carga los sprites reales de césped, árboles, setos, también molaría que

### 1.57
- `escena_viaje.gd` · `CARGA`: (lo pidió el usuario: «estos recursos se podrían usar antes de la pantalla de inicio, como de carga del juego, en una carretera
- `juego.gd` · `carga_t0`: (lo pidió el usuario: «estos recursos se podrían usar antes de la pantalla de inicio, como de carga del juego, en una carretera
- `mundo.gd` · `DEMO_CAL`: (lo pidió el usuario: «luego aparece la pantalla de inicio START con más atrezo»): en el título, con CAL, el protagonista y el
- `pinta.gd` · `arriba`: (lo pidió el usuario: «los tubos no llegan a las carpas, falta 1 o 2 píxeles»): la boca, en la primera fila opaca del
- `pinta.gd` · `_tubo_codos`: (lo pidió el usuario: «en las curvas o giros del tubo no se deben cortar»): de la carpa (xa, hasta ya) al techo (yc), por el
- `ui.gd` · `DPI_PRUEBA`: para las pruebas de los mandos por móvil (tests/mandos_geo.gd): los ppp y la zona segura de un móvil de verdad
- `ui.gd`: (lo pidió el usuario: «que sean lo mejor para jugar con el móvil en horizontal, estudiando en qué zonas caen los dedos»): los
- `ui.gd` · `CRUZ_HISTERESIS`: al deslizar de una flecha a la de al lado, la nueva tiene que ganar por CRUZ_HISTERESIS (unos 11° pasada la diagonal):
- `ui.gd` · `vibra`: un toque corto del vibrador al apretar un mando (OPCIONES → VIBRACIÓN), en el móvil

### 1.56
- `granja.gd` · `VIAJE_V`: el viaje, de perfil, como pantalla de carga (escena_viaje.gd): el autobús o tu vehículo por la carretera; A o B lo pasan

### 1.55.3
- `mundo.gd` · `SENT_GEO`: (lo pidió el usuario: «la altura correcta en todos los muebles donde se puede sentar»): por asiento, [dx, cadera]: dx,
- `pinta.gd` · `f`: (lo pidió el usuario): sube de la boca del techo de la carpa al techo de la habitación, corre pegado al techo (por
- `pinta.gd` · `cs`: a cada carpa con extractor, su ventana (que no quede detrás de ella), con los tramos de techo sin pisarse y lo más

### 1.55
- `mundo.gd` · `sitio`: (lo pidió el usuario: «la puerta del sótano está inaccesible porque hay una carpa delante» y «poder ordenar las carpas al
- `pinta.gd` · `_tubos_casa`: (lo pidió el usuario: «debería salir un tubo de extracción de cada carpa hacia una de las ventanas»): con el extractor puesto,

### 1.54.1
- `trama.gd` · `GS_W`: (lo pidió el usuario: «eso no son sprites en condiciones en el mismo estilo que los muebles del juego»): el plano de

### 1.52
- `calle.gd` · `calle_tiempo`: con lluvia, tormenta o nieve hay menos gente en la calle: el calor de cada venta, por esto
- `datos.gd` · `_cal_d`: las autoflorecientes (AUTO) entran en la Genoteca, las recetas y el banco solo con CAL (las pruebas contra el HTML, sin ellas)
- `datos.gd` · `K`: el club KAIA del muelle, el tuyo (solo con CAL: las pruebas contra el HTML recorren D.CLUBS)
- `eventos.gd`: las obras del muelle, el club KAIA y la ley
- `mundo.gd`: (lo pidió el usuario: «comenzar destartalado… ir reformándolo poco a poco, edificio por edificio»): cada casa, en ruina hasta
- `mundo.gd` · `obra_ya`: una obra del muelle, terminada (S.mar.ob: el día en que se acaba cada una)
- `trama.gd` · `ICONO_TIEMPO`: el dibujo del tiempo, 13 × 9 (. vacío, s sol, n nube, m sombra de la nube, g gota, r rayo, b nieve, f niebla)

### 1.51
- `eventos.gd`: el muelle de Puerto Viejo, los envíos por mar y el piso franco
- `mundo.gd` · `puertas_int`: (lo pidió el usuario: «una puerta en la casa, luego un mapa pequeño como un mini pasillito»; y en el taller y en la nave): las
- `mundo.gd` · `_muelle0`: (lo pidió el usuario: «un mapa lateral en Puerto Viejo, un mini puerto para los envíos»): desde el capítulo de MAR.ch, el paso
- `mundo.gd` · `ATREZO`: (lo pidió el usuario: «la casa de Txaro es la casa con menos atrezo que hay en el mundo… que en casi todos los lugares donde
- `setas.gd` · `ayudante_setas`: (lo pidió el usuario: «que se cultive como la nave»): Ekaitz, el ayudante del bajo grande, cada mañana: todo húmedo y lo listo, a secar
- `trama.gd` · `_SOT`: (lo pidió el usuario: «antes de… alquilar el bajo… habilitar el sótano de la casa»): las setas, en el bajo de Txomin

### 1.50
- `nave.gd` · `i`: a lo ancho, con el nombre entero (en la columna de la derecha se cortaba: «Beldi», «Zam»…)
- `pinta.gd` · `SENT_PIERNAS`: de frente, sentado: los muslos encima del asiento (vistos desde arriba), las rodillas, las espinillas colgando
- `pinta.gd` · `SENT_TABURETE`: de espaldas en el taburete de la barra (asiento a 72 cm, 11 px): el culo encima del asiento y, a los lados del pie,
- `policia.gd` · `g_lote`: un lote de menos de 10 g, con su décima (0,4 g no es «0 g»); sin CAL, como g_txt
- `ui.gd` · `HUD_TAB_SEP`: el recuadro, etiqueta a la izquierda y cifra a la derecha, con una raya arriba y abajo

### 1.49
- `calle.gd` · `levantarte`: (lo pidió el usuario: «que te puedas sentar de verdad»): sentado es un estado, no un menú; el mundo sigue (la gente

### 1.48
- `pinta.gd` · `MOSAICO_TILE`: los firmes en mosaico (exterior-mosaico) y el canto de la hierba donde toca acera, calzada u hormigón: dos píxeles más oscuros,
- `pinta.gd` · `_det_c`: (lo pidió el usuario: «que se note que es el sprite y lo que trae»): d-<objeto>-<mapa>-<tramo>, d-<objeto>-<mapa>,

### 1.47
- `mundo.gd` · `_disco_cal`: (lo pidió el usuario: «la discoteca tiene que ser más grande, el piso de arriba reservado»), solo con Datos.CAL: GAUA, la planta
- `mundo.gd` · `montar_estancos`: (lo pidió el usuario: «un estanco en cada pueblo»), solo con Datos.CAL: la puerta en una casa libre de cada pueblo (en el barrio
- `mundo.gd` · `FUMAR`: (lo pidió el usuario): con qué se fuma. El papel, el tabaco, las boquillas y el mechero, del estanco (ESTANCO); la pipa,
- `nave.gd` · `subir_vip`: (lo pidió el usuario): el reservado, arriba; desde la cristalera del suelo se ve la pista de abajo
- `pinta.gd` · `_bailan`: (lo pidió el usuario: «desde el que se ve el piso de abajo, en la cristalera del suelo, transparente»): en el reservado, la gente
- `pinta.gd` · `g0`: (lo pidió el usuario: «que se vea algo más que la pista»): por el cristal, lo de abajo entero en su sitio, recortado al
- `pinta.gd` · `_rotulo_x`: el rótulo del estanco, centrado encima de su puerta
- `trama.gd` · `talk_estanco`: (lo pidió el usuario): el estanco de cada pueblo, papel, filtros, tabaco y mecheros (D.ESTANCO)
- `trama.gd` · `CATA_MAX`: (lo pidió el usuario: «que se pueda probar todo tipo de cogollos y extracción… hasta un límite lógico claro»): catar cualquier

### 1.46
- `mundo.gd` · `NEG_LARGO`: el elevador y el foso, a escala con los coches del concesionario (5 casillas, como la exposición); 1.47, el box de lavado
- `setas.gd` · `cp`: cada cepa con su forma y sus colores (CEPAS.v): cúpula (la de siempre), campana, plato o racimo

### 1.45
- `mundo.gd`: (lo pidió el usuario: «en la nave en la que cultivas, lo mismo»): el camastro del rincón, para dormir allí

### 1.43.8
- `trama.gd`: (lo pidió el usuario: «no existe mapa y sitio del bajo de las setas»; con Datos.CAL): nada te decía dónde estaba. Con

### 1.43.7
- `mundo.gd` · `lotes_venta`: (lo pidió el usuario: «las extracciones se deberían poder vender al por mayor, en clubs y donde se pueda vender cogollos»;

### 1.43.6
- `mundo.gd` · `CM`: la escalera escamoteable del camarote, entre las carpas A y B, bajo la ventana; se sube desde la casilla de delante

### 1.43.4
- `juego.gd` · `copia_seguridad`: (lo pidió el usuario: exportar e importar, más escondidos): al final de OPCIONES, en su submenú y con su aviso

### 1.43.3
- `movil.gd` · `look_rival`: el muñeco del rival, del sexo de su nombre (GENERO.rival)
- `mundo.gd` · `sprite_look`: (GENERO): el muñeco de un look (como Atlas.grupo_look: los de la calle, por su hash) y si es de chica
- `venta.gd` · `con_encargada`: donde lleva el club una mujer (GENERO.enc), «la encargada»

### 1.43.2
- `eventos.gd` · `kilometros`: los km de cada vehículo; al pasar cada CONCE.v[k].revKm, la revisión (aceite y filtros), y cada neuKm, los neumáticos

### 1.43
- `calle.gd` · `coche_ya`: un vehículo del concesionario (S.coches: {k: {dia: cuándo llega, p: lo pagado, r: el próximo recibo del seguro o null}}), ya entregado
- `croquis.gd` · `LIBRE`: (lo pidió el usuario): centrados como la nevera y la caja fuerte, a lo ancho y en el alto que deja libre el cuadro del texto
- `mundo.gd`: el carro de las bandejas de clones (S.nave.bc), contra la pared, entre el secadero y el escritorio
- `ui.gd` · `alto_libre`: lo que queda libre del lienzo (en píxeles del juego) por encima del cuadro del texto, para centrar ahí el calendario y el mapa
- `ui.gd`: la primera vez, el texto aún no sabe su ancho y el cuadro sale de toda la pantalla; se recoloca al fotograma siguiente

### 1.41
- `setas.gd` · `tg`: (lo pidió el usuario: realista): cada lote, en los tarros de ALM.tarro g que llenaría de verdad (de 4 L, sin aplastar)

### 1.40
- `granja.gd` · `cap`: (lo pidió el usuario): el carro se ve tal cual, dos bandejas de tacos (arriba y abajo) en vez de un menú; A en un taco
- `ui.gd` · `g`: (lo pidió el usuario: «más ergonómicos, más espaciadas las flechas del cuadrado del medio»): cada flecha, una tecla suelta

### 1.37
- `calle.gd` · `j`: (lo pidió el usuario): con la carta leída, la mesa redonda ordena la casa (12d-orden)

### 1.36
- `policia.gd` · `caja_action`: (lo pidió el usuario): al abrirla, la caja por dentro (rects_almacen): los billetes abren el menú de siempre y un tarro, sacarlo

### 1.35
- `juego.gd` · `_titulo_entra`: el aviso de edad (la primera vez) y, sin PULSA START, los botones del título; con B se cierran y A o START los abren
- `ui.gd` · `LEMA`: (lo pidió el usuario): el rótulo, el lema y, debajo, los botones (el menú «titulo»); detrás, la partida de fondo (pinta.gd)
- `venta.gd` · `nave_alquiler`: cada RECIBO.dias, en efectivo, con su aviso (cobra, granja.gd)

### 1.34
- `movil.gd` · `club_te_compra`: (PRESI): fuera del barrio, un club solo te compra (lotes y encargos) si se fían de ti el encargado y su presidente
- `venta.gd` · `de_la_nave`: con el de las madres (cuida_madres)
- `venta.gd` · `talk_gente_club`: los demás socios de cada club (GENTE_CLUB)

### 1.30
- `sonido.gd`: la música grabada (tools/musica.js → musica/<clave>.ogg, con indice.json: dónde empieza el bucle) va antes que el

### 1.27
- `mundo.gd` · `vs`: el suelo y las paredes de la reforma (REFORMA) y la alfombra (suelo: 1, sus 4 trozos sobre el suelo que haya)

### 1.25
- `menus.gd` · `tipo_diario`: todas las de la Genoteca, en su orden; las de receta abren lo que entra; las demás dicen dónde están sus semillas
- `trama.gd` · `lao_miren`: y MIREN.n2 de la de Laos (MIREN.s2, que no está en el banco; S.flags.lao: las partidas de antes, al volver a hablarle)

### 1.23
- `granja.gd` · `ph_item`: por marca (D.PRODUCTOS): el pH− que se gasta es el de su marca y, si no hay, el otro
- `granja.gd` · `abonar`: (09-cultivo: abonar): el de crecimiento (veg_k: los que hay, en vegetativo y sin él) o el de floración; con dos marcas, eliges

### 1.13
- `juego.gd`: lo que se quedó en la cola al guardar (la cama guarda antes de que salgan los avisos de la noche)

### 1.11
- `calle.gd` · `heat_warn`: un aviso antes, con 50 (con 60 investigan), que dice por dónde se vende sin tanto calor
- `trama.gd` · `llevas`: en los plazos, lo que llevas entre el bolsillo y la caja

### 1.10
- `juego.gd`: el plazo del capítulo 3 corre desde Toño (las partidas sin él, desde hoy) y la protección de Molina dura 10 días desde hoy

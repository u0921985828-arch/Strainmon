=== Landrace Hunters ===
Version: 1.7.0
Autor: WOLFCADE

Juego «Landrace Hunters» (Godot 4.3, exportación web sin hilos) servido desde el plugin.

Instalar: Plugins → Añadir nuevo → Subir plugin → landrace-hunters-1.7.0.zip → Activar.
Si el servidor no deja subir 30 MB («413 Request Entity Too Large»): sube landrace-hunters-1.7.0-ligero.zip (menos de 1 MB), actívalo y pulsa «Descargar el juego» en el aviso o en Ajustes → Landrace Hunters; el servidor lo baja él solo.
Jugar: /landrace-hunters/ (cambiable en Ajustes → Landrace Hunters).
Incrustar: [landrace_hunters alto="80vh"].

Se rehace con el juego de cada versión: node tools/wordpress.js en el repositorio (exporta index.pck de godot/).
Si el servidor no deja subir un archivo tan grande, descomprímelo y súbelo por FTP a wp-content/plugins/landrace-hunters/.
Fuentes: Atkinson Hyperlegible y Press Start 2P, licencia SIL OFL (game/OFL-*.txt).

Cambios
1.7.0 — Landrace Hunters: el juego se guarda en el móvil la primera vez que se abre (sw.js). Después arranca sin pedirle nada al servidor, y hasta sin conexión; al actualizar el plugin, la copia guardada se rehace sola. El servidor aguanta así mucha más gente a la vez.
1.6.9 — Landrace Hunters (Godot 0.70.0): el paquete del juego, cifrado con AES-256 (los scripts y los nombres de los archivos no se pueden leer del index.pck), con el motor web compilado con su clave.
1.6.8 — Landrace Hunters (Godot 0.70.0): más fluido en el navegador: cada trozo del suelo se pinta una sola vez en su propia textura (de unas 200 llamadas de dibujo por fotograma a 60 en la calle) y la lluvia y la nieve van en un solo dibujo; en la calle, de unos 20 a unos 29 fotogramas por segundo en un ordenador sin tarjeta gráfica.
1.6.7 — Landrace Hunters (Godot 0.70.0): la ruta de la tía (un recado con testimonio en cada pueblo, que cuenta en el Acto III), el día de 8 minutos (4, 12 o 24 en OPCIONES → RELOJ) y los ladrones y carteristas solo de noche.
1.6.6 — Landrace Hunters (Godot 0.69.1): más fluido en el navegador (el suelo de cada mapa se pinta una vez y no en cada fotograma, y el cono de la policía se calcula una vez por sitio), cada controlador de clima en su sala, las entradas cuadradas con las baldosas y lo translúcido sin destellos.
1.6.5 — Landrace Hunters (Godot 0.65.2): sin las franjas blancas detrás de árboles y farolas al ponerte detrás; la mesa con plantas, translúcida en una sola capa.
1.6.4 — Landrace Hunters (Godot 0.65.1): KAIA por niveles, las madres por dentro, la sala fría del sótano, la manicura a la vista, el billar con efecto y un rival que piensa rápido, y lo que tapa al protagonista, translúcido (la mesa con sus plantas, en una sola capa).
1.6.3 — Landrace Hunters (Godot 0.63.0): Bilbao por dentro (el teatro, las iglesias, el mercado, las estaciones y la Diputación), los pueblos con su sitio y su forma, las salidas por su lado, el seto nuevo y la tierra con atrezo.
1.6.2 — Landrace Hunters (Godot 0.62.0): el garaje de la tía por dentro, con los vehículos aparcados en sus plazas, el maletero y el depósito de gasolina, y el turno del rival del billar con una pausa mínima.
1.6.1 — Landrace Hunters (Godot 0.61.0): el rival del billar a la bola 8, un jugador de verdad (elige bola y tronera por dificultad, juega la posición, defiende, sale por banda y canta el tiro) y los choques de las bolas en el instante del contacto.
1.6.0 — El plugin ligero: sin el motor ni los datos del juego, que se descargan en el propio servidor con un botón (para los servidores que cortan las subidas grandes con «413 Request Entity Too Large»).
1.5.9 — Landrace Hunters (Godot 0.60.0): un dispensario en cada club (la vitrina con su encargado; Club Zenit y Club Ilargi de Hiriburu, que llenas tú), Bilbao como zonas nuevas (Zorroza con sus trenes y el paso subterráneo, La Punta, Abando y el Casco Viejo), las vallas que conectan en las dos direcciones, la nave por salas con el secadero aparte y el viaje con el autobús y el cielo de PixelLab.
1.5.8 — Landrace Hunters (Godot 0.59.0): el colocón también en el combate (índica aguantas más pero vas lento, sativa lo ves venir, borracho fallas), ladrones y rivales algo más fáciles y el juego entero, sin el corte de la demo (eso queda solo en Google Play).
1.5.7 — Landrace Hunters (Godot 0.58.0): la huerta de la tía con los bancales de 7 × 4 y las plantas dentro, sus mejoras y la ampliación, setos y bancales de PixelLab, el ordenador sentado tecleando, los combates de PixelLab a su lado (el rival arriba a la izquierda, tú abajo a la derecha), los árboles fuera de los edificios y la red de carreteras.
1.5.6 — Landrace Hunters (Godot 0.57.0): desde el ordenador (sin pantalla táctil), sin la cruceta ni A/B en pantalla: W A S D mueven (como las flechas), el clic izquierdo es A y el derecho es B (el derecho ya no abre el menú del navegador), M o Tab START y P el MÓVIL; en el móvil, los mandos de siempre; y todo lo de la 0.52 a la 0.57 (retratos, gestos en primera persona, la bodega del barco por tandas, las llaves por cerradura y las puertas dibujadas).
1.5.5 — Landrace Hunters (Godot 0.51.0): saltar el tutorial al empezar (el primer cultivo ya hecho), la partida guardada que no se pierde al actualizar y los retratos con gestos de quien habla.
1.5.4 — Landrace Hunters 1.57.2 (Godot 0.47.1): la calle del juego en la carga con un bancal de exterior por la fecha, el taller por zonas y a la escala del coche, la taberna de Puerto Viejo con mesas y sillas en las que te sientas, la semilla al sembrar y la escalera del sótano hacia la derecha.
1.5.3 — Landrace Hunters 1.57 (Godot 0.47.0): la carga en la carretera y el título con más atrezo, el viaje de perfil, los tubos de las carpas con codos y los mandos más grandes, donde caen los pulgares.
1.5.2 — Landrace Hunters 1.55.2 (Godot 0.46.1): el que cuida las madres de la nave, delante de su carpa y no de la puerta de la habitación.
1.5.1 — El juego de hoy (Landrace Hunters 1.55.1, Godot 0.46.0): cada acción de cerca con sprites a mano (regar, abonar, esquejar, cosechar, fumar, dormir…), abrir con llave o clave, las carpas ordenables con su tubo de extracción a la ventana y cualquier mueble de la casa ordenable, con la puerta del sótano y la escalera del camarote siempre libres.
1.5.0 — El juego de hoy (Landrace Hunters 1.52.0, Godot 0.45.0): todo lo de la 1.44 a la 1.52 —el bajo de las setas entero, los negocios por dentro, sentarse y fumar, los locales a escala, el muelle de Puerto Viejo con los barcos, el piso franco y las obras, el club KAIA y la ley, el sótano, el tiempo y las estaciones en el móvil, la Ruderalis y las autoflorecientes—.
1.4.4 — Landrace Hunters 1.43.5 (Godot 0.37.5): cada nombre de chica con personaje chica y cada chico con chico (presidentes de los clubs, agenda, naveros, rivales y encargadas); exportar e importar la partida, escondidos en OPCIONES → COPIA DE SEGURIDAD.
1.4.3 — Lo probado en la web (1.2.1) en el plugin de hoy: la caché de página (Kuboplay Shield) ya no guarda la página del juego y se vacía al actualizar; al desactivar, la dirección deja de responder sin guardar los enlaces permanentes; al borrarlo no deja ajustes; el aviso de instalar se va solo a los 15 s. La música de la versión web, más ligera (el zip baja de 30 MB).
1.4.2 — Landrace Hunters 1.43.2 (Godot 0.37.2): con tu vehículo no pagas autobús, solo gasolina; el seguro y el impuesto de circulación al año y el taller por km (revisión y neumáticos).
1.4.1 — Landrace Hunters 1.43.1 (Godot 0.37.1): coches de juguete a la escala del protagonista, la moto como un scooter en el que vas sentado y todas las ruedas gordas y con llanta.
1.4.0 — El juego de hoy (Landrace Hunters 1.43.0, Godot 0.37.0): el concesionario del barrio alto (moto, utilitario, berlina y superdeportivo, con seguro, gasolina y controles), las bandejas de clones de la nave, el calendario y el mapa centrados, y todo lo anterior.
1.3.0 — El juego de hoy (Landrace Hunters 1.42.0, Godot 0.36.0): calendario desde el lunes 20 de abril de 2026, mapa de la comarca en el móvil, la nave con opción a compra, la nave por ciclos, la caja por tarros, el carro de esquejes, la nevera ampliable, las extracciones a la vista, la música por zonas y todo lo anterior.
1.2.1 — La caché de página (Kuboplay Shield) ya no guarda la página del juego: tras actualizar se ve la versión nueva al momento. Al desactivar, la dirección deja de responder sin tener que guardar los enlaces permanentes. Al borrarlo no deja ajustes en la base de datos. El aviso de instalar se va solo a los 15 s.
1.2.0 — Instalar como app en el móvil: en Android sale un aviso con botón «Instalar» (o, si el navegador no lo ofrece, cómo hacerlo desde el menú ⋮); en iPhone, un aviso que explica Compartir → «Añadir a pantalla de inicio». Abierto desde el icono va sin barras. El aviso se cierra con × y no vuelve en 7 días.
1.1.0 — Pantalla completa: al primer toque el juego ocupa toda la pantalla, sin barra del navegador, y se pone en horizontal (Android). En vertical sale «Gira el móvil». La página se puede instalar con «Añadir a pantalla de inicio» y abre sin barras (única vía en iPhone). Se apaga en Ajustes → Landrace Hunters.
1.0.0 — Primera versión.

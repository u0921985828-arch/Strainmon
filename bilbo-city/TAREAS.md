# Tareas pendientes

Por orden de importancia. La primera bloquea a todas las demás.

---

## 1 · Compilar el proyecto Unity  ⟵ empieza aquí

El C# ya pasa por un compilador de verdad. No por Unity: por Roslyn, contra un remedo de
la API del motor que está en `herramientas/compilar/`. Eso ya resuelve sobrecargas,
conversiones implícitas y genéricos, que es justo lo que el analizador de sintaxis no
podía. Los 20 ficheros compilan, con la misma separación de ensamblados que los `.asmdef`
(el runtime no ve `UnityEditor`) y sin un solo aviso.

```bash
apt-get install -y dotnet-sdk-8.0     # una vez
herramientas/compilar/compilar.sh     # o ./verificar.sh csharp
```

- [x] Compilar el C# y arreglar los errores. Salieron dos, los dos aburridos, anotados
      abajo en el registro.
- [x] Dejar la compilación dentro de `./verificar.sh` para que no vuelva a pasar un año
      sin compilar.
- [ ] Abrir `unity/BilboCity` en Unity 2022.3 LTS y compilar **de verdad**. El remedo no
      es el motor: no cubre las versiones de los paquetes, ni IL2CPP, ni los `.meta`, ni
      diferencias finas de firma. Cuenta con que aún salga algo, pero ya no la lista larga.
- [ ] Menú **BilboCity → Preparar escena** y comprobar que arranca.
- [ ] Anotar abajo lo que salga en Unity, para seguir afinando los verificadores.

## 1 bis · Los interiores en Unity

El prototipo pasó los interiores a escala humana (casilla de 0,80 m dibujada a 16 px) y el
puerto lleva los mismos planos, las mismas piezas de mobiliario y el mismo arte. Lo que no se
ha podido comprobar sin abrir el editor es **la cámara de dentro**: en el HTML el zoom es
entero y encuadra el sitio completo si cabe, y en Unity el tamaño ortográfico sigue saliendo
de la casilla de la calle.

- [ ] Entrar en los trece sitios y mirar el encuadre: media unidad por casilla
      (`Interiores.Escala`), zoom entero y el sitio entero en pantalla si cabe.
- [ ] Comprobar que el personaje y los muebles miden lo mismo dentro que en el prototipo:
      una persona de 1,70 m al lado de una cama de 2,4 m.
- [ ] El puerto sigue con `Forja.TS = 32` mientras el HTML va a 64 (ver §4b). Los interiores
      ya no dependen de eso, pero la calle sí.

## 1 ter · El sol en Unity

`Ciudad/Sol.cs` lleva la misma cuenta que el prototipo —dirección y largo de la sombra por
la hora, luz ambiente por franjas y `Sombra(alto)` para lo que está de pie—, pero en Unity
no hay quien la pinte: la ciudad va en Tilemaps y la sombra del prototipo se resuelve por
casilla al dibujar.

- [ ] Sombra de manzana: un Tilemap encima con la casilla en sombra, recalculado cuando
      cambie la hora (no por fotograma: son siete kilómetros).
- [ ] Sombra de figura y de mobiliario: un `SpriteRenderer` hijo, tumbado con
      `Sol.Sombra(alto)`.
- [ ] Luz ambiente: teñir con un quad a pantalla completa o con `Camera.backgroundColor` +
      un `SpriteRenderer` en overlay. No con URP: el proyecto va con paquetes base.
- [ ] Farolas encendidas de noche.
- [ ] Sombra de los singulares: pintar la planta barrida hasta donde llega —la caja, su
      copia corrida y las bandas que las unen— en un solo trazo y un solo relleno, para que
      la parte común no salga al doble de oscuro. Como ya hace `sombraSingulares` en el
      prototipo.

## 2 · Primera pasada de juego real

- [ ] ¿Se ve Bilbao? Comparar con `referencia/capturas/plano-bilbo.png`.
- [ ] ¿El jugador anda en las 8 direcciones con las poses correctas?
- [ ] ¿Los coches arrancan en la dirección de la calle y no contra la pared?
- [ ] ¿El HUD se lee en un móvil de verdad, no solo en el editor?
- [ ] ¿Cuántos fps da en un dispositivo real con el mobiliario sembrado?

## 3 · Diferencias con el HTML

Repasar comportamiento contra el prototipo, que es el probado:

- [x] Alcance del cuerpo a cuerpo. Unity se había quedado con el `1.0` y el `1.4` que el
      HTML abandonó por engañosos: son 5,2 m y 7,2 m, o sea pegar desde la otra acera. Y
      afectaba a los dos lados, que los matones usan la misma tabla. Ahora hay comparador
      (`herramientas/plano/armas.py`) y va en `./verificar.sh`.
- [x] Golpe por la espalda: iba a 1,4 casillas (7,2 m) en vez de a 0,35 (1,8 m).
- [x] Cono de auto-apuntado sin joystick de puntería: 1,15 rad, no 1,05.
- [x] La ambulancia no salía en ninguna lista de tráfico: se forjaba y no circulaba.
- [ ] Escalado del daño y de las estrellas de búsqueda.
- [ ] Tiempos de las misiones con límite.
- [ ] Economía: precios, pagos de curros, alquiler semanal. Un comparador tipo `armas.py`
      lo sujetaría (`CURROS`, `PROPIEDADES`, `PRENDAS`, `XP_NIVEL`): hoy cuadran, pero sin red.
- [ ] `VMAX_VEH` no existe en Unity: todo coche del tráfico se crea con `vmax:11f` fijo,
      así que el autobús corre lo mismo que el deportivo. Y comprar furgoneta o deportivo
      solo pone un booleano: el coche del jugador no cambia ni de modelo ni de punta.
- [ ] Auto-apuntado: solo a enemigos, nunca a viandantes salvo con las manos.
- [ ] Mobiliario pegado al sitio: la marquesina de la parada, la terraza del bar, el toldo
      del comercio y la placa del singular. En el HTML van en `colocarCalle()`; el puerto
      solo siembra por cadencia y no ata ninguna pieza a un POI.

## 3 bis · Lo que se forja y no se usa

La clase de fallo que ya cazó tres veces —la grúa y el contenedor marítimo sobre una ciudad
sin muelles, la celda de PixelLab, y las cinco piezas de obra sin acera—. Ahora la batería
lo comprueba sola: toda pieza de `MOB_M`, todo mueble de `MUEBLES` y todo chasis de `CHASIS`
tienen que estar plantados en algún sitio. Lo que quedó al descubierto y sigue abierto:

- [ ] Seis iconos del HUD forjados y sin usar: `pintxo`, `botellin`, `plato`, `botiquin`,
      `llaveInglesa` y `movil`. Las opciones de diálogo son texto sin icono, así que o se
      les pone icono a las opciones —que es lo que pedían estos seis— o se borran. No hay
      red que lo sujete todavía: `icoImg` se llama con literales y con campos de tabla, y
      eso no se puede barrer sin ejecutar todos los diálogos.

## 4 · Rendimiento

- [ ] El mobiliario son GameObjects sueltos (varios miles). Si el presupuesto de dibujado
      aprieta, pasarlo a un tercer Tilemap en modo `Individual` con ordenación por eje Y.
- [ ] Perfilar el HUD: `SetPixels32` + `Apply` del radar una vez por frame.
- [ ] Comprobar que las hojas de personaje se compilan bajo demanda y no todas al arrancar.

## 4b · Terminar la subida del mundo a casilla de 64

La casilla pasó de 32 a 64 px para que la escala fuese realista (ver *El arte* en
`CLAUDE.md`). El suelo, las fachadas y el mobiliario están a 64 **de geometría**, pero el
dibujo se sigue forjando a 32 y se sube con `x2()`: un píxel de arte por cada cuatro de
pantalla. Funciona y las proporciones ya son las buenas, pero el detalle todavía no está.

- [x] El suelo, los props y las fachadas se forjan ya a 64: la geometría se sigue
      escribiendo en espacio de 32 y sale al doble recalculando cada rectángulo por sus
      cantos, y **el grano va a 1 px** (`ruido` pinta con la escala apagada). Con eso se
      acabaron los dos tamaños de píxel en la misma pantalla. `x2()` fuera.
- [ ] Aprovechar la resolución en la **geometría**, que sigue siendo la de 32 al doble:
      junta de adoquín de 1 px, bordillo con canto, marca vial con desgaste, teja por
      pieza. Eso es dibujo nuevo, no escalado.
- [ ] **Unity va todavía a 32.** `Mundo`/`Lienzo` y los tiles del puerto siguen en la
      medida vieja: mientras no se suban, las dos implementaciones no se ven igual. Al
      subirlo hay que repasar `Ciudad/Vision.cs`: sus cajas mezclan casillas (`Forja.TS`)
      con píxeles de sprite (20 px/m), y con la casilla a 32 el jugador queda tapado desde
      el doble de lejos que en el HTML. Y con ello converge solo `Movimiento.EscFig`: hoy la
      figura del puerto es 2,46 veces su suelo y la del HTML 1,61, porque el HTML forja a 4:3
      sobre casilla de 64 y el puerto a 1:1 sobre 32. Las dos cifras son correctas en su
      implementación —se calculan, no se copian—, pero el juego no se ve igual en las dos
      hasta que la casilla sea la misma.
- [ ] Medir la memoria en un móvil de verdad. Doblar la casilla cuadruplica los píxeles del
      atlas de suelo; las hojas de personaje no cambian, que el personaje no se tocó.

## 5 · Contenido que falta respecto al plan original

- [ ] **Unity no coloca los locales.** `Mobiliario.FachBarrio` está declarado y no lo usa
      nadie: la forja saca los ocho tipos de fachada a `Props` y luego no los pinta ninguno,
      así que en Unity las manzanas siguen siendo paredes ciegas mientras en el HTML tienen
      escaparates. Portar el bucle del HTML, que ahora rellena la casilla por anchos
      (`ANCHO_FACH`): un local entero de 32 px o dos de medio.
      De esto cuelgan otras tres del HTML que en Unity no tienen dónde engancharse, porque
      el puerto pinta el edificio como una sola casilla de tejado y nada más: las **plantas**
      con sus bandas por tipo (liso, balcón, mirador, persiana), las **ventanas encendidas de
      noche** y el **rótulo del local** en la fachada. Y al portarlas hay que resolver el
      desfase de medida: el HTML corrigió el frente a `FACH_H=22` y los sprites de bajo que
      Unity tiene sin usar siguen dibujados para el 13 de antes.
- [x] **El puerto no existe en el mapa.** Del plano salían siete tipos de suelo y `MUELLE`,
      `PATIO`, `PLAZA` y `VIA` estaban declarados sin **ni una casilla** en el mapa: la grúa y
      el contenedor marítimo se forjaban y no se plantaban nunca. Ahora se clasifican en el
      juego (`clasificarSuelos` y `clasificarNombres`), sin tocar el extractor y sin inventar
      geometría: el muelle es la acera pegada al agua en barrio industrial más la de las nueve
      calles «Muelle …» del callejero; el patio, el hueco cerrado por manzana que no da a la
      calzada; la plaza, la acera de las setenta y siete calles «Plaza …».
- [ ] **`VIA` sigue vacío.** El ferrocarril no se distingue en la capa de rellenos del plano.
      Mientras no se saque, el tile de vía y sus traviesas siguen forjados y sin usar.
- [ ] **La plaza sale pequeña.** Las plazas peatonales del Casco caben en quince casillas
      porque el plano pinta buena parte de ellas como manzana. Lo que se ve es real, pero
      corto: habría que sacar del plano el recinto peatonal, no solo su acera.
- [ ] **La fachada solo se pinta en el canto sur de la manzana.** En las Siete Calles, que
      son un pasaje dentro de la manzana, no se ve ni un escaparate: el interior del bloque
      es tejado por los cuatro lados. Se nota en que dos locales del Casco tienen que colgar
      su rótulo del canto de la manzana en vez de una fachada.
- [ ] Oclusión de interiores de manzana con transición.
- [ ] Más variedad de diálogo en los parroquianos.
- [ ] Misiones secundarias no encadenadas.

## 6 · Publicación

Esto es trabajo de tienda, no de juego. No empezar hasta que 1–3 estén cerrados.

- [ ] Icono y capturas de tienda.
- [ ] Compras integradas, si procede.
- [ ] Reporte de fallos en producción.
- [ ] Política de privacidad y ficha de la tienda.

---

## Registro de lo arreglado

Fallos que ya se cazaron y no deben volver:

- Salud negativa por daño doble en el mismo frame.
- Balas atravesando enemigos de cerca (se resolvió con 3 subpasos por frame).
- Auto-apuntado enganchándose a viandantes.
- Coches aparcados mirando todos al este y arrancando contra la pared.
- Manzanas tan pequeñas que había más asfalto que edificio.
- Sitios plantados en descampados en vez de pegados a una fachada.
- Flechas de dirección dentadas al rotar píxel a píxel.
- Un campo llamado `Lienzo` que tapaba a la clase `Lienzo`.
- Dos listas recorridas mientras se borraba de ellas (explosión y atropello).
- El arnés dando por fallada la última misión sin que el juego tuviera la culpa: `S.hp = 100`
  no deshace un K.O. Ver abajo.
- `Correr` y `AtacarMantenido` que se quedaban pegados a `true` para siempre.
- Un guardado corrupto envenenando la partida nueva: `cargar()` hacía `Object.assign` nada
  más parsear, reventaba a media carga, devolvía false —«aquí no hay partida»— y el arranque
  dejaba empezar una nueva **encima** del estado ya escrito: dinero `NaN`, reloj `NaN` y el
  protagonista en la casilla 99999. Ahora la carga es atómica y acota cada campo, y la
  batería la prueba de ida y vuelta y con nueve guardados rotos.
- La tabla de armas separándose entre el HTML y Unity sin que nadie lo viera.
- Cinco piezas de calle (valla, andamio, cono, toldo, placa), tres muebles de interior
  (bañera, escritorio, palés), un tile de suelo, dos tablas huérfanas y catorce libreas de
  coche: forjados al arrancar y sin un solo camino de dibujo.

Los dos primeros errores de compilación reales, con lo que enseñan:

- `Misiones.cs:320` · **CS0104**: `Random.value` era ambiguo entre `UnityEngine.Random` y
  `System.Random`. Es el único fichero del proyecto que tiene `using System;` *y* usa
  `Random`, así que era el único sitio donde podía saltar. Arreglado calificándolo:
  `UnityEngine.Random.value`. El analizador de sintaxis no lo veía porque resuelve
  nombres, no espacios de nombres en competencia.
- `RenderCiudad.cs:12` · **CS0169**: el campo `Tile[] _cache` no se usaba en ninguna parte.
  Borrado. Ahora `compilar.sh` va con `-warnaserror`, así que el siguiente campo muerto
  detiene la verificación en vez de pasar desapercibido.

Lo que buscaría un verificador nuevo, a la vista de esto: nombres de tipo que existan a la
vez en `System` y en `UnityEngine` (`Random`, `Object`, `Debug`) usados sin calificar en un
fichero que importe los dos espacios de nombres.

Y el rojo intermitente de la batería del HTML, que resultó no ser del juego:

- El arnés reponía `S.hp = 100` en cada vuelta para que una muerte de paso no estropeara la
  prueba, pero un K.O. deja además `S.muerto` contando 2,2 s. Mientras corre, `act()` vuelve
  antes de llegar a `comprobarObjetivos`, así que la misión no avanza aunque el jugador esté
  encima del objetivo; al agotarse, manda al hospital y da la misión por fallada. Salía en
  *El último puente* por ser la última: era la que estaba activa cuando vencía el contador.
  El juego hacía lo correcto. Arreglado poniendo también `S.muerto = 0`.
- De paso, el prototipo ya no usa `Math.random()` sino un generador propio sembrable
  (`sembrar` / `azar`, mulberry32). En el navegador arranca de la hora, como siempre; la
  batería lo siembra con 20250823, y `BILBO_SEMILLA` cambia la tirada. Dos pasadas dan
  ahora exactamente lo mismo, que es lo que hacía falta para poder depurar esto.

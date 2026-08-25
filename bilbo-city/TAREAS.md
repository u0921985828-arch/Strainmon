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

## 2 · Primera pasada de juego real

- [ ] ¿Se ve Bilbao? Comparar con `referencia/capturas/plano-bilbo.png`.
- [ ] ¿El jugador anda en las 8 direcciones con las poses correctas?
- [ ] ¿Los coches arrancan en la dirección de la calle y no contra la pared?
- [ ] ¿El HUD se lee en un móvil de verdad, no solo en el editor?
- [ ] ¿Cuántos fps da en un dispositivo real con el mobiliario sembrado?

## 3 · Diferencias con el HTML

Repasar comportamiento contra el prototipo, que es el probado:

- [ ] Escalado del daño y de las estrellas de búsqueda.
- [ ] Tiempos de las misiones con límite.
- [ ] Economía: precios, pagos de curros, alquiler semanal.
- [ ] Auto-apuntado: solo a enemigos, nunca a viandantes salvo con las manos.

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
      medida vieja: mientras no se suban, las dos implementaciones no se ven igual.
- [ ] Medir la memoria en un móvil de verdad. Doblar la casilla cuadruplica los píxeles del
      atlas de suelo; las hojas de personaje no cambian, que el personaje no se tocó.

## 5 · Contenido que falta respecto al plan original

- [ ] **Unity no coloca los locales.** `Mobiliario.FachBarrio` está declarado y no lo usa
      nadie: la forja saca los ocho tipos de fachada a `Props` y luego no los pinta ninguno,
      así que en Unity las manzanas siguen siendo paredes ciegas mientras en el HTML tienen
      escaparates. Portar el bucle del HTML, que ahora rellena la casilla por anchos
      (`ANCHO_FACH`): un local entero de 32 px o dos de medio.
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

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

## 2 bis · La batería del HTML es intermitente

Sin sembrar: usa `Math.random()`. Medido en diez pasadas, dos dan
`FALLO misión no completable: El último puente` — siempre esa, la última y la más larga de
la campaña. El arnés corta cada misión a 40 iteraciones y esa se queda a un paso.

- [ ] Sembrar el generador del prototipo para que las pasadas sean reproducibles.
- [ ] En `pruebas.js`, medir progreso (¿avanzó de paso?) en vez de contar vueltas, o darle
      holgura al tope en las misiones largas.

Mientras siga así, un rojo de la batería no significa nada hasta repetirlo.

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

## 5 · Contenido que falta respecto al plan original

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

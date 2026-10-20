---
name: "modo-absoluto"
description: "Protocolo de ejecución silenciosa de Eddie. Úsalo en cuanto diga 'modo absoluto', '/modo-absoluto', 'en silencio', 'sin narrar', 'sin comentar', 'solo el COMPLETADO' o pida que trabajes sin contarle los pasos y cierres con el bloque ✅ COMPLETADO. Una vez activado sigue vigente en todos los turnos de la sesión, aunque los mensajes siguientes no lo mencionen, hasta que diga 'modo normal'. Cubre también cómo medir el avance (NN.N %) y cómo responder a '¿cómo va?' o a un turno reabierto por un hook."
allowed-tools: Bash(python3 ${CLAUDE_SKILL_DIR}/scripts/ma.py *), Bash(python ${CLAUDE_SKILL_DIR}/scripts/ma.py *)
---

# MODO ABSOLUTO · v4.4

**On**: «modo absoluto» (o cualquier petición de trabajar sin narrar). **Off**: «modo normal». Entre medias rige todos los turnos aunque el mensaje no lo repita. Al activarlo, `ma.py on`; al desactivarlo, `ma.py off` (con los hooks instalados lo hacen solos y recuerdan estas reglas en cada turno).

Contrato de tokens y de confianza: Eddie tiene límite de uso y quiere el resultado verificado y el delta exacto, no leer cómo trabajas. Toda palabra que no sea entregable, respuesta, bloqueo o dato que falta es un fallo del modo.

## REGLA
- Silencio. Solo escribes en los casos de SALIDA. Nada de anunciar, narrar, confirmar pasos, meta-comentario, resumen del plan, cortesía, relleno, disculpas ni preguntas menores.
- **Entre llamadas a herramientas: cero texto.** Ni «lanzando X», ni «Docs while…», ni resultados parciales. La única línea permitida es la de progreso que saca `ma.py`. Lo que quieras contar va a ESTADO.md o al cierre.
- **Todo en español, siempre** (norma de Eddie, tras una respuesta entera en inglés): cada respuesta, también las cortas, las preguntas sueltas fuera de una tarea, las notas y los resúmenes. Aunque se piense o se trabaje por dentro en otro idioma, lo que se escribe a Eddie va en español; antes de enviar, se revisa que no haya ni una frase en inglés. Una palabra en inglés que no sea código o un nombre propio es un fallo.
- **Pregunta de Eddie a mitad de tarea** («¿por qué…?», «¿qué es…?»): primero la respuesta, en 1–3 líneas y sin bloque; después sigues. Nunca contestes a una pregunta con una línea de progreso.
- **Encargo o corrección de Eddie a mitad** («quita esto», «no me gusta aquello»): es una tarea CORTA aparte. Se cierra con su bloque CORTA, no en prosa, y luego sigues con la larga (si suma trabajo a la larga, `imprevisto`).
- **Preguntar a Eddie**, siempre con el formato ❓ de SALIDA, nunca en prosa.
- **Nunca repitas un porcentaje**, ni seguido ni separado, en ninguna línea. Ningún % se escribe a mano: solo lo saca `ma.py`, que lo impide.

## ARRANQUE
1. Si existe `ESTADO.md` en la raíz del proyecto, léelo primero y continúa desde ahí. Ni repitas lo hecho ni reintentes caminos cerrados.
   **Tras compactar, reabrir sesión o perder el hilo** con una tarea LARGA en curso: `ma.py next` antes de nada. Dice el % calculado, la siguiente subtarea y lo que falta, leyendo solo el disco. Sigue por ahí; no hay línea de % hasta el siguiente `set`.
2. Clasifica la tarea:
   - **CORTA**: menos de ~10 min o menos de 5 pasos. Fija 1 criterio verificable y 1 caso reservado y ejecuta. Sin plan, contador ni ESTADO.md.
   - **LARGA**: todo lo demás. Protocolo completo (sección LARGA).
3. Si no puedes fijar un criterio sin un dato de Eddie, ❓ ahora, no a mitad.

**Criterio verificable** = algo que se ejecuta o se ve: test que pasa, render, archivo que abre, cifra que cuadra. «Que quede bien» no vale. **Caso reservado** = caso límite o entrada no vista que no miras hasta el final; impide ajustar la solución a los ejemplos.

## EJECUCIÓN
- **Reutiliza antes de crear.** Antes de hacer un asset, función, sprite o archivo nuevo, busca en el proyecto si ya existe algo que sirva (grep, listado de assets). Crear algo nuevo teniendo uno válido es un fallo; si lo creas igualmente, el motivo va en DECISIONES.
- Cambio mínimo que cumple el criterio. Nada de capas ni abstracciones no pedidas.
- Edita sobre lo que funciona; reescribir solo si es inevitable, y va en DECISIONES.
- Pasos cortos y medidos de verdad (ejecutar, renderizar, abrir, leer la salida). Lo no medido vale cero.
- Criterios en verde + siguiente mejora cosmética = cierra.
- Contexto o límite de uso acabándose → cierra con PENDIENTE antes que pulir.
- Ningún error se traga: lo que falla y no arreglas va al cierre.
- **Fallos**: mismo enfoque, mismo error, 2 veces → camino cerrado; cambia algo concreto o pasa al plan B. Solo lo transitorio (red, timeout, 429) se reintenta: máx. 2, espera creciente, respeta `Retry-After`. Si falla una pieza, apártala y sigue con el resto.
- **Tokens**: salidas largas (logs, tests, builds, diffs) a archivo; lee solo errores, resumen y cola. No releas lo que no cambió. Secretos siempre enmascarados (`sk-…a1b2`).

## AMBIGÜEDAD Y RIESGO
- **Barato de rehacer**: asume y sigue (estándar de la industria > patrón del proyecto > opción simple y reversible). Va en DECISIONES.
- **Caro o irreversible** (borrar, publicar, enviar, gastar, rehacer mucho): antes de preguntar, **deja hecho todo lo reversible** (borrador, archivo, comando listo), y pide ❓ solo para el paso irreversible. Ningún plan B gasta, publica, envía ni borra por su cuenta.

## VERIFICACIÓN
Contra los criterios fijados al arrancar, no contra lo que fuiste haciendo. Pasa el caso reservado; si falla, no está cerrado. Lo no verificado va en PENDIENTE, nunca como hecho.

## SALIDA
Nada fuera del bloque: ni frase antes del ✅, ni pie de captura, ni resumen después. Las capturas se nombran en ENTREGABLE.

**FIN · tarea CORTA**
```
✅ COMPLETADO
HECHO: [qué, dónde y el delta, en una línea]
VERIFICAR: [comando o acción exacta para comprobarlo Eddie]
TEST: [criterio → resultado · caso reservado → resultado]
DECISIONES / PENDIENTE: [solo si hubo]
```

**ENTREGA PARCIAL** (Eddie pidió algo antes de que acabe la tarea larga, p. ej. la APK): mismo bloque que LARGA, pero con `📦 ENTREGA PARCIAL` en lugar de `✅ COMPLETADO` y una línea `SIGUE: [lo siguiente del plan]`. Luego continúas sin más texto. `✅ COMPLETADO` solo al acabar de verdad.

**FIN · tarea LARGA**
```
✅ COMPLETADO
ENTREGABLE: [qué y dónde · commit/versión · capturas]
CAMBIOS: [solo el delta]
DECISIONES: [solo si hubo · desvíos: A falló → B]
TEST: [batería n/fallos · … · caso reservado]
VERIFICAR: [comando o acción exacta]
PENDIENTE: [solo si hubo]
```
Límites del bloque: cada campo, viñetas de **una línea**, sin sublistas. CAMBIOS ≤ 8 viñetas; el detalle va al CHANGELOG y aquí se cita («detalle: CHANGELOG 1.57.2»). TEST, una línea por batería (`negocios 319/0`); los fallos intermedios ya corregidos van en una sola viñeta. Las líneas vacías se omiten. El bloque no se adorna ni se explica.

**BLOQUEO / DATO FALTA** (un único mensaje; ⛔ arriba, ❓ debajo; incluye solo los que apliquen):
```
⛔ [problema] → [opción A / B]
❓ [dato exacto] · [dato exacto]
LISTO: [lo reversible ya preparado y dónde]
```
⛔ solo si es imposible continuar; lo menor lo resuelves y lo mencionas al final. ❓ solo si es imposible avanzar; todas las preguntas juntas.

**LÍNEAS DE PROGRESO** (las saca `ma.py`, nunca a mano):
- Avance: `(trabajando · 30.0 % · tests unidad 31/31 +0.7 · CHANGELOG 1/1 +10.0)`. Nombra cada subtarea que avanzó; la suma de los aportes es exactamente el salto.
- Imprevisto: `(trabajando · 27.2 % (−2.8) · +25 min: README sin contar)`.
- Esperando, **sin %** (si no, repetiría el último): `(trabajando · esperando expo.py, 1 h 25 de ~1 h 40 · faltan 6 subtareas)`. Úsala solo cuando no haya nada contable que esperar o si Eddie pregunta «¿cómo va?».
- En tareas CORTAS basta `(trabajando · paso N/M)`.

**Turno forzado** = el arnés reabre el turno sin que Eddie escriba: stop hook, continuación automática, **mensaje de un subagente o tarea en segundo plano terminada**. No es una pregunta ni un hito que contar: si avanzó algo, `ma.py set` (que emite la línea); si no, nada, o `esperando` si hace falta texto. Nunca prosa («llevo 3 de 4 bloques…»).

---

## LARGA (solo tareas largas)

**Al arrancar**, además del criterio y el caso reservado:
- 1–3 criterios y **línea base** medida antes de tocar nada (para TEST antes → después).
- **Plan con pesos** declarado con `ma.py init`: subtareas de **peso 1–4** (minutos esperados, fijados al declararlas y nunca retocados), ninguna >20 % del total (`init` lo rechaza). Incluye el cierre desglosado (verificación, caso reservado, docs, commit, build, entrega): es lo que siempre se subestima.
- **Granularidad**: cada llamada o job comprobable es una subtarea o una unidad de una (un test, un render, un commit, un build, un archivo escrito). **Cada subagente o proceso en segundo plano es una unidad**: 13 agentes = `m` 13, y cada uno que termina es un `set`. **Más de 5 llamadas sin que suba el % = plan mal partido**: lo que falte entra por `imprevisto`.
- **Cadena A → B → C** para cada paso con riesgo (dependencia externa, API, build frágil). Si A cae, a B sin repensar.
- Si dura más de ~30 min, da el tiempo estimado en una línea antes de empezar.
- Crea **`ESTADO.md`** en la raíz del proyecto: hecho, medido, pendiente, caminos cerrados, último enfoque que funcionó y cada desvío (qué falló → a qué cambiaste → resultado). Actualízalo al momento; debe bastar para que otra sesión continúe sin repetir nada. Plan y criterios van ahí o a `.modo-absoluto/`, nunca al chat.

**Flujo**
- Sin tiempos muertos: mientras corre algo largo, adelanta lo que no dependa de ello (commit, bitácora, scripts siguientes, revisión del diff).
- Lo secuencial en una cola que arranque sola; lo independiente en paralelo; lo que mide tiempo, solo.
- Sonda corta antes de una batería larga. Revisión independiente antes de medir, no después.
- Tras un arreglo, repite solo lo afectado; lo no repetido, a DECISIONES con el motivo.
- Una sola compilación y una sola entrega final; nada intermedio no pedido.
- Nunca pises lo que se está midiendo. Cada resultado a su propio archivo con nombre por variante y corrida. No edites un script mientras corre. Mata procesos por PID, nunca por patrón.
- Empieza por lo que ya funcionó en este proyecto. Un fallo repetido se convierte en regla en ESTADO.md.
- Entrega grande o difícil de revertir → **revisión por ataque** (abajo), antes de medir el caso reservado.

**Revisión por ataque**
Un subagente que no vio la construcción recibe un brief autosuficiente (no ve la conversación): la tarea con los requisitos de Eddie en sus palabras, los criterios, las rutas del entregable. Nada de tu opinión sobre si está bien. Su orden:
```
Ataca este entregable contra la tarea. Máx. 7 ataques, el más fuerte primero; si solo hay 2 reales, 2.
ATAQUE n [FATAL|GRAVE|MENOR] título en una línea
Dónde: cita o ubicación exacta
Problema: qué falla, con el contraejemplo concreto o el requisito citado que no cumple
FATAL = incorrecto o inservible para la tarea; GRAVE = hueco real; MENOR = el resto.
Nada de elogios, resúmenes ni estilo. No inventes requisitos. Comprueba ejecutando si se puede, solo en una carpeta temporal. Escribe solo el archivo de ataques.
```
Tú: cada ataque se **arregla** o se **rebate con prueba** (ejecución, cita de la tarea). Rebatir sin prueba = conceder. Ningún FATAL o GRAVE puede quedar en pie al cerrar; los MENOR que queden van a PENDIENTE. La revisión es una subtarea del plan con su peso, y cada ataque arreglado, una unidad.

**Progreso NN.N %** = Σ (peso × n/m) ÷ Σ pesos, un decimal, redondeado hacia abajo. **Se calcula con `ma.py`, nunca se estima ni se escribe de memoria.**
- Cada subtarea lleva un **ID único** (`t1`, `t2`…) y, si es contable, su total `m`. Se marca **al comprobarla**, nunca editando el JSON a mano.
- Las unidades **no se cambian a mitad** (`init` se niega si ya hay plan). Lo olvidado entra por `imprevisto`, a la vista, nunca en silencio dentro de un salto. Nunca se quita trabajo del total. Paso no contable (investigar, decidir diseño): declara nº de intentos con su peso; agotados, los nuevos por `imprevisto`.
- **Ningún % se repite en toda la tarea**: `ma.py` guarda todos los que ha sacado y no emite uno ya visto ni uno que no suba. Si el estado no cambió, no se emite nada; si hace falta texto, `esperando` (sin %). La única bajada es la de `imprevisto`, que la marca con (−x).
- Proceso largo sin contador: tiempo transcurrido sobre lo que tardó la última vez, tope 95 % hasta leer su resultado. En tareas muy largas, % de la fase en curso, diciendo cuál.
- **100 %** solo con criterios y caso reservado en verde y el entregable entregado.

### Contador `ma.py`
Ruta: `${CLAUDE_SKILL_DIR}/scripts/ma.py`; si no se resuelve, `scripts/ma.py` junto a este archivo; si no, `.modo-absoluto/ma.py` del proyecto. Si no está en ninguna, ❓ pide `ma.py` antes de `init`. Se ejecuta desde la raíz del proyecto y guarda el estado en `.modo-absoluto/` (al `.gitignore`). En Windows, `python`.
```
ma.py init "t1:tests unidad:4:31" "t2:build:3" "t3:CHANGELOG:2" ...   # una vez
ma.py set t1 30                  # marca y emite en la misma llamada
ma.py set t1 31 t3 1             # varias a la vez
ma.py imprevisto "t9:docs README:2" 25 "README sin contar"
ma.py esperando "expo.py, 1 h 25 de ~1 h 40"
ma.py next                       # tras compactar: %, siguiente subtarea, lo que falta
ma.py tabla                      # de dónde sale cada número
```

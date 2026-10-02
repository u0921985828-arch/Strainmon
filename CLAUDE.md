# Strainmon — CLAUDE.md

## MODO ABSOLUTO (directiva de trabajo por defecto)

Se activa cuando el usuario escriba `modo absoluto` (o `[MODO:Absoluto]`) y **sigue activo
toda la sesión** hasta que escriba `modo normal`. El protocolo entero está en la skill
`anthropic-skills:modo-absoluto`; esto es lo que no se puede olvidar sin leerla:

**Regla.** Se trabaja en silencio. Solo se habla al final, o si hay un bloqueo, o si falta
un dato imprescindible.

**Prohibido.** Anunciar, narrar, confirmar pasos, meta-comentario, preguntar cosas menores,
resumir el plan, cortesía y relleno.

**Antes de empezar.** Fijar de 1 a 3 comprobaciones verificables —un test que pasa, un
render que se ve, una cifra que cuadra; «que quede bien» no vale—, medir la línea base,
apartar un **caso reservado** que no se mira hasta la verificación final, y contar el plan
en unidades de trabajo (el total es la base del porcentaje). Si falta un dato para fijar el
criterio, se pide **ahora**, no a mitad.

**Ejecución.** El cambio mínimo que cumple el criterio. Editar lo que existe antes que
reescribirlo. Pasos cortos y cada uno medido de verdad: lo escrito y sin medir vale cero.
Con los criterios en verde y la siguiente mejora ya cosmética, se cierra. Ningún error se
traga: lo que falla y no se arregla va en el cierre.

**Ambigüedad.** Barato de rehacer → asumir y seguir (estándar de la industria > patrón del
proyecto > opción simple y reversible) y anotarlo en DECISIONES. Caro o irreversible
—borrar, publicar, enviar, gastar, rehacer mucho— → preguntar antes de ese paso.

**Salida, solo cuatro casos.**

```
✅ COMPLETADO
ENTREGABLE: [qué y dónde]
CAMBIOS: [solo el delta, mínimo]
DECISIONES: [solo si hubo]
TEST: [criterios: antes → después · caso reservado · cómo verificarlo yo]
PENDIENTE: [solo si algo quedó sin verificar o sin resolver]
```

- `⛔ [problema] → [opción A / B]` — solo si es imposible continuar.
- `❓ [dato exacto]` — solo si es imposible avanzar sin él, y todas las preguntas juntas.
- `(trabajando · NN %)` — y nada más, si un arnés reabre el turno sin que el usuario haya
  escrito. Eso no es una pregunta.

**El porcentaje** son unidades comprobadas ÷ total, redondeado hacia abajo, contando
también dentro del paso en curso. El trabajo imprevisto **se suma al total** aunque el
número baje (`42 % → 38 % · +12: motivo`); nunca se quita trabajo del total para que suba.
El 100 % solo llega con todos los criterios y el caso reservado en verde.

En este repositorio, «criterio verificable» quiere decir casi siempre `./verificar.sh` en
verde más la comprobación concreta de lo que se tocó.

## Restricciones de propiedad intelectual (siempre)

- Prohibido usar assets/código de terceros con copyright: sprites de Pokémon,
  código de Habbo/Sulake, descompilaciones (p.ej. `pret/pokefirered`), wordmark
  "Nintendo/GAME BOY" ni el lema comercial. Modificar material con copyright =
  obra derivada = sigue infringiendo.
- Permitido: homenaje de forma/layout genérico + arte y código 100% originales.
  Identidad propia: **STRAINBOY** (verde), textos propios.

## Proyecto

- Juego sandbox isométrico single-player (cultivo/cruce/trapicheo de genéticas
  landrace). Vanilla JS, `PH` namespace, sin dependencias.
- Fuentes en `src/*.js`; estilos en `assets/style.css`; entrada `index.html`.
- Build (bundle inline autocontenido): `node <scratchpad>/build.js` → `dist/PhenoHunter.html`.
- Consola: LCD 10:9 (matriz 160×144, píxeles cuadrados), modo DMG 4 tonos.
- Rama de trabajo: `claude/pheno-hunter-game-wzl06e`.

## Segundo proyecto alojado: `bilbo-city/`

El repositorio hospeda un juego aparte, **sin relación con Strainmon**: sandbox 2D cenital
ambientado en Bilbao (prototipo HTML probado + puerto a Unity 2022.3 en C#). Vive entero
bajo `bilbo-city/` y no toca la raíz.

- Tiene **su propio `CLAUDE.md`, su `TAREAS.md` y su `./verificar.sh`**. Al trabajar ahí,
  manda el suyo: código y comentarios en español, sin físicas de Unity, paleta de 48
  colores, nada de assets importados.
- No mezcles convenciones ni código entre los dos. Strainmon es vanilla JS con espacio de
  nombres `PH`; Bilbo City es C# sobre Unity.
- La restricción de propiedad intelectual de arriba aplica igual: arte y código 100%
  originales en los dos.

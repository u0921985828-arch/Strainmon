# Strainmon — CLAUDE.md

## MODO ABSOLUTO (directiva de trabajo por defecto)

Cuando el usuario escriba `[MODO:Absoluto]` (o pida "modo absoluto"):

Rol: Ejecutor final.

Reglas:
1. Cero charla / saludos / confirmaciones.
2. Salida = SOLO producto final 100% terminado.
3. PROHIBIDO emitir mensajes intermedios.
4. Excepción: bloqueo crítico → preguntar máx. 1 línea.
5. Estilo: frases ultracortas, máxima densidad técnica.

Variante `[MODO:Ejecutor_Absoluto]` (auditoría/refactor): mismas reglas + salida =
informe técnico directo + código refactorizado, sin relleno.

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

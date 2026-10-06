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
6. Aviso de progreso `(trabajando · NN.N %)`: % calculado por script con sub-pasos
   (cada llamada o job cuenta), estrictamente creciente. Nunca repetir un % ni escribirlo
   a mano; si el estado no cambió, no se emite.

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

## Subproyecto `ribera-verde/`

- RPG de cultivo independiente (v1.8.0): 160 px de alto y de 240 a 400 de ancho, solo en horizontal, con mandos flotantes; piso a 1 casilla = 1 m y vista de carpa a 64 px/m. Notas propias en `ribera-verde/CLAUDE.md`.
- Tests: `cd ribera-verde && npm install` y, con el Chromium preinstalado
  (`export CHROMIUM_PATH=$(ls -d /opt/pw-browsers/chromium-*/chrome-linux/chrome | head -1)`):
  `npm test` → 39/39, 0 errores JS · `npm run test:arte` → 22/22.
- Plano de escala: `npm run plano` → `docs/plano/` + `docs/PLANO.md` (escala decidida: opción A, aplicada en la 1.8.0).
- Android: `npm run apk` → `dist/ribera-verde.apk` (WebView + index.html, `sensorLandscape`; sin Android SDK, ver `ribera-verde/CLAUDE.md`).
- Sprites: MCP `pixellab` en `.mcp.json` (raíz; habilitado en `.claude/settings.json`), token en la variable `PIXELLAB_TOKEN`,
  nunca en el repo. En sesiones cloud exige `api.pixellab.ai` en los dominios permitidos.

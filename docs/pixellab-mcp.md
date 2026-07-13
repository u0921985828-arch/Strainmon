# Integración de Pixellab (MCP) para generar sprites

Strainmon puede usar [Pixellab](https://www.pixellab.ai/) como servidor MCP para
generar pixel-art coherente (personajes, plantas, mobiliario) directamente desde
una sesión de Claude Code.

La configuración vive en `.mcp.json` (raíz del repo) y se carga automáticamente al
iniciar cualquier sesión de Claude Code en este proyecto. El token **no** se guarda
en el repo: se lee de la variable de entorno `PIXELLAB_API_KEY`.

```json
{
  "mcpServers": {
    "pixellab": {
      "type": "http",
      "url": "https://api.pixellab.ai/mcp",
      "headers": { "Authorization": "Bearer ${PIXELLAB_API_KEY}" }
    }
  }
}
```

## Requisitos para que funcione

Hacen falta **dos** cosas. Con cualquiera de ellas ausente, las herramientas de
Pixellab no cargarán o fallarán al llamar a la API.

### 1. Permitir el host en la política de red del entorno

Por defecto, la política de egress de Claude Code on the web **bloquea**
`api.pixellab.ai` (devuelve `403 CONNECT rejected`). Hay que añadirlo a la lista de
hosts permitidos de la política de red del entorno.

- Documentación: https://code.claude.com/docs/en/claude-code-on-the-web
- Hosts a permitir:
  - `api.pixellab.ai` (API REST **y** endpoint MCP `/mcp`)
  - `www.pixellab.ai` (opcional, solo para consultar la documentación)

En local (fuera del entorno remoto) no aplica: la máquina alcanza el host
directamente.

### 2. Definir el token `PIXELLAB_API_KEY`

- **Claude Code on the web:** añade `PIXELLAB_API_KEY` como variable de entorno /
  secreto en la configuración del entorno. Así queda disponible en cada sesión sin
  exponerlo en git.
- **Local:** expórtala en tu shell antes de lanzar Claude Code:

  ```bash
  export PIXELLAB_API_KEY="tu-token-de-pixellab"
  ```

  El token se obtiene en https://www.pixellab.ai/ (panel de cuenta → API).

> Nota: el comando `claude mcp add ...` escribe la config en `~/.claude.json`, que en
> el entorno remoto es **efímero** (se pierde al reciclar el contenedor). Por eso la
> integración persistente se hace con este `.mcp.json` versionado + la variable de
> entorno, no con `claude mcp add`.

## Verificar

Tras permitir el host y definir el token, **inicia una sesión nueva** (los servidores
MCP se cargan al arrancar). Comprueba que aparecen herramientas `mcp__pixellab__*`.
Diagnóstico rápido de red desde una sesión:

```bash
curl -sS "$HTTPS_PROXY/__agentproxy/status"   # recentRelayFailures no debe listar api.pixellab.ai
```

Si sigue apareciendo `403 CONNECT rejected` para `api.pixellab.ai`, la allowlist de la
política de red aún no incluye el host.

## Generar el set completo de sprites (estilo coherente)

Hay un pipeline listo, independiente del MCP, que llama a la API REST de Pixellab.
La **coherencia de estilo** se logra aplicando a todas las peticiones los mismos
knobs (outline / shading / detail / view) y la **misma paleta forzada** (Sweetie 16)
vía `color_image`.

Archivos:

| Archivo | Rol |
|---|---|
| `scripts/build-pixellab-manifest.mjs` | Lee `src/species.js` y genera el manifiesto: 18 cepas × 5 fases + personajes (8 × 4 direcciones) + mobiliario + piezas. |
| `prompts/pixellab.json` | Manifiesto generado (142 sprites). **Editable a mano**: ajusta descripciones, tamaños o el bloque `style`. |
| `scripts/gen-pixellab.mjs` | Ejecutor sin dependencias: lee el manifiesto y escribe los PNG. |

Flujo:

```bash
# 1. (opcional) regenerar el manifiesto desde species.js
node scripts/build-pixellab-manifest.mjs

# 2. validar el manifiesto sin gastar créditos (no llama a la API)
node scripts/gen-pixellab.mjs --dry-run

# 3. token disponible (env o .secrets/pixellab.key) y host permitido, entonces:
export PIXELLAB_API_KEY="tu-token"
node scripts/gen-pixellab.mjs --only=chars --limit=2   # prueba barata primero
node scripts/gen-pixellab.mjs                          # set completo (142 sprites)
```

Opciones de `gen-pixellab.mjs`: `[manifest] [outDir]`, `--only=grupo,grupo`,
`--limit=N`, `--force` (regenera existentes), `--dry-run`, `--delay=MS`.
Salida por defecto en `assets/gen_pixellab/<grupo>/` (ignorado por git; curar antes
de versionar). También escribe `_palette.png` con la paleta usada.

Último paso (manual, tras revisar): re-inlinear los PNG elegidos como base64 en
`src/charart.js` / `src/plantart.js` / `src/sprites.js`, que es de donde el juego
carga los sprites en runtime (los `assets/*.png` son las fuentes).

> Las `view` / proyección por grupo en el manifiesto (p.ej. `oblique_projection` en
> mobiliario, 4 direcciones en personajes) son un punto de partida sensato; ajústalas
> al ver el primer output real.

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

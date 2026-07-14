# MCP PixelLab

Servidor MCP remoto de **PixelLab** (generación de pixel-art) conectado a Claude
Code para este proyecto. Encaja con el flujo de sprites de Strainmon
(`scripts/gen-sprites.mjs`, `prompts/`, `assets/`).

## Qué se ha configurado

`.mcp.json` (ámbito *project*, se comparte con todo el equipo vía git):

```json
{
  "mcpServers": {
    "pixellab": {
      "type": "http",
      "url": "https://api.pixellab.ai/mcp",
      "headers": {
        "Authorization": "Bearer ${PIXELLAB_API_KEY}"
      }
    }
  }
}
```

- Transporte **HTTP** (`type: "http"`) contra `https://api.pixellab.ai/mcp`.
- La API key **no** se versiona: se inyecta con la expansión de variables de
  entorno `${PIXELLAB_API_KEY}` que soporta `.mcp.json`. Coherente con la regla
  del repo (`.gitignore`: `*.key`, `.secrets/`, `.env`) de no commitear secretos.
- `.claude/settings.json` incluye `enabledMcpjsonServers: ["pixellab"]` para
  aprobar el servidor sin el diálogo manual cuando el workspace es de confianza.

## Requisito: exportar la API key

El servidor solo funciona si `PIXELLAB_API_KEY` está en el entorno.

**Local (terminal):**

```bash
export PIXELLAB_API_KEY="tu-token-de-pixellab"
# o copia .env.example a .env y rellénalo
```

**Claude Code en la web:** añade `PIXELLAB_API_KEY` como variable/secreto en la
configuración del entorno de la sesión.

> Si la variable no está definida, Claude Code no podrá parsear `.mcp.json` y el
> servidor no cargará. Nunca pegues el token dentro del JSON versionado.

## Alta manual equivalente (referencia)

El mismo servidor puede añadirse por CLI (ámbito *project* → escribe `.mcp.json`):

```bash
claude mcp add pixellab https://api.pixellab.ai/mcp \
  -t http \
  -s project \
  -H "Authorization: Bearer $PIXELLAB_API_KEY"
```

## Uso y verificación

- `claude mcp list` → debe mostrar `pixellab`.
- `/mcp` dentro de Claude Code → estado del servidor y sus herramientas.
- Docs: https://code.claude.com/docs/en/mcp

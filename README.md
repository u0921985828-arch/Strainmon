# 🌱 Strainmon

Un RPG de exploración y **genética vegetal** parodia de coleccionismo tipo Pokémon centrada en cepas landrace de cannabis y sus linajes, inspirado en los
clásicos RPG de Game Boy Advance — pero **sin combates**. Aquí no capturas criaturas:
recorres biomas, descubres variedades vegetales salvajes, las recolectas con distintas
herramientas, las almacenas en tu **banco genético** y las **cruzas** para crear fenotipos,
colores y mutaciones que nadie había visto. Tu meta es reunir el mayor **catálogo genético
del planeta**.

Juego 100% original, HTML5/Canvas, pixel-art 16-bit, sin dependencias externas ni assets:
todo el arte se genera por código a partir de la genética de cada planta.

## ▶️ Cómo jugar

Abre `index.html` en un navegador moderno. No requiere servidor ni instalación.

### Controles
| Acción | Tecla |
|---|---|
| Mover | `WASD` / Flechas |
| Interactuar / Confirmar | `Espacio` o `E` |
| Mochila | `I` |
| Banco genético | `B` |
| Catálogo mundial | `C` |
| Misiones | `Q` |
| Laboratorio (cruces) | `L` |
| Invernadero (cultivo) | `G` |
| Guardar | `M` |

También hay controles táctiles en pantallas pequeñas. La partida se autoguarda cada 20 s.

## 🧬 El núcleo: el motor genético

Cada planta tiene un **genotipo diploide** real:

- **Genes cualitativos** con dominancia y alelos recesivos: color de flor (incluye albinismo
  recesivo), forma de hoja, terpeno/aroma. Los empates producen **codominancia**.
- **Genes cuantitativos** (poligénicos): altura, producción, vigor, resistencia, velocidad y resina.
- **Poliploidía**: diploide, triploide (estéril) y tetraploide, con efectos sobre tamaño y producción.
- **Mutaciones raras**: variegación, gigantismo, enanismo, quimera, fasciación y bioluminiscencia.

El **fenotipo observable** (y su sprite) se deriva por expresión del genotipo. Al **cruzar** dos
ejemplares, la descendencia hereda un alelo de cada parental por gen, con recombinación,
segregación cuantitativa y probabilidad de mutaciones *de novo*. De ahí emerge variedad
prácticamente infinita.

Cada combinación única se identifica con una **firma fenotípica** y se registra en el catálogo
mundial con su primer descubridor, rareza y recuento.

## 🗺️ El mundo

- **Ciudad Semilla** (hub): laboratorio, mercado, tu casa y NPCs con misiones.
- **Pradera de Auralia**, **Bosque de Vael**, **Cenagal de Mureb**: biomas con especies exclusivas.
- **Ciclo día/noche**, **estaciones** y **clima** (lluvia, niebla, tormenta, ola de calor…) que
  modifican en tiempo real las probabilidades de aparición. La esquiva *Brumaria* solo abunda con
  niebla; las variedades de sombra y la reliquia dorada *Aurífera* prefieren la noche.

## 🌿 Invernadero (cultivo)

Planta clones o semillas del banco y obsérvalos crecer por fases —
**plántula → vegetativo → floración → cosecha**— con sprites pixel-art de
cultivo. Al cosechar **propagas la genética** (varios clones idénticos, según
producción y ploidía) y obtienes créditos; regar acelera el ciclo y la
velocidad genética influye en el ritmo. Es la forma de multiplicar una
variedad valiosa sin perder su genotipo. Los sprites de crecimiento viven en
`assets/sprites/` y se sirven inline (base64) desde `src/sprites.js`, así que
todo sigue funcionando abriendo `index.html` sin servidor.

## 📈 Progresión

Se avanza por **prestigio** (no niveles), que se gana descubriendo variedades y desbloquea nuevas
regiones y licencias. La economía permite comprar herramientas mejores (tijeras, kit de clonación,
dron) y equipo (lupa, medidor ambiental, feromonas, estabilizador genético).

## 🏗️ Arquitectura

Código modular con espacio de nombres global `PH` (sin bundler, se ejecuta abriendo el HTML):

| Archivo | Responsabilidad |
|---|---|
| `src/util.js` | RNG, matemáticas, utilidades de color |
| `src/genetics.js` | Motor genético: genes, expresión, rareza, cruce, mutaciones |
| `src/species.js` | Especies base, perfiles y tablas de aparición por bioma/ambiente |
| `src/items.js` | Herramientas de recolección y equipo |
| `src/world.js` | Mapas por tiles, colisiones, warps, NPCs |
| `src/render.js` | Render pixel-art: tiles, personajes y sprites de planta |
| `src/sprites.js` | Sprites de cultivo (48×48) inline en base64 y ciclo de vida |
| `src/garden.js` | Invernadero: plantado, crecimiento por fases y cosecha |
| `src/events.js` | Eventos raros temporizados |
| `src/research.js` | Secuenciación de ADN, parentesco y linaje |
| `src/state.js` | Estado, banco, catálogo, ambiente y guardado |
| `src/quests.js` | Misiones y diálogos |
| `src/encounter.js` | Resolución de recolección |
| `src/ui.js` | HUD y paneles superpuestos |
| `src/game.js` | Bucle principal, entrada, cámara y render del mundo |

## 🎨 Herramientas (MCP)

Para generar pixel-art desde Claude Code está configurado el MCP remoto de
**PixelLab** en `.mcp.json` (ámbito *project*). Requiere exportar la variable
`PIXELLAB_API_KEY` (nunca se commitea el token). Detalles en
[`docs/MCP_PIXELLAB.md`](docs/MCP_PIXELLAB.md).

## 🚧 Hoja de ruta

Más regiones (desierto, nieve, volcán, islas, cuevas), investigación de ADN y árboles
filogenéticos, eventos raros temporizados (eclipses, floraciones masivas), decoración de
laboratorio y multijugador (intercambio, subastas, ranking de descubridores).

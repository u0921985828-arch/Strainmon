# Strainmon — proyecto Unity (top-down, Android / WebGL)

> **Aviso honesto:** este proyecto Unity **no se ha compilado ni ejecutado**
> aquí (este entorno es Linux headless, sin editor de Unity). Es código fuente
> para que **tú lo abras en Unity y lo construyas**. No incluye ningún asset de
> terceros con copyright: los tiles son **placeholder originales** generados por
> código en runtime, pensados para sustituirse por tu propio tileset.

## Requisitos
- **Unity 2022.3 LTS** (o 2021.3+), plantilla **2D**.
- Módulos de build: **Android** (para APK/AAB) y/o **WebGL**.

## Abrir y ejecutar
1. Unity Hub → *Add project from disk* → selecciona la carpeta `unity/`.
2. Abre la escena vacía por defecto (o crea una: `Assets/Scenes/Game.unity`).
3. Crea un **GameObject vacío** llamado `Boot` y añádele el script
   `Assets/Scripts/Bootstrap.cs`. (Todo lo demás lo monta el código: cámara,
   mundo, jugador, datos.)
4. **Play.** Muévete con **WASD / flechas**.

Nitidez pixel-perfect (recomendado): *Package Manager* → instala **2D Pixel
Perfect** y añade el componente **Pixel Perfect Camera** a `Main Camera`
(Assets PPU = 16, resolución de referencia p.ej. 320×240).

## Datos
`Assets/StreamingAssets/strains.json` = las **100 cepas** de linaje cerrado
(exportadas del juego web). `StrainDatabase.cs` las carga (Android/WebGL vía
`UnityWebRequest`) y ya trae `CanonicalCross(a,b)` para reconocer cruces.

## Build
- **Android:** *File → Build Settings → Android → Switch Platform → Build*
  (genera APK/AAB). Configura *Player Settings* (orientación, icono propio).
- **WebGL:** *File → Build Settings → WebGL → Switch Platform → Build*.

## Estructura
```
unity/
  Assets/
    Scripts/
      Bootstrap.cs        arranque por código (cámara+mundo+jugador+datos)
      TileWorld.cs        mapa por tiles + colisión + sprites placeholder
      GridMover.cs        movimiento por rejilla pixel-perfect + encuentros
      CameraFollow.cs     cámara anclada a píxeles
      StrainDatabase.cs   carga strains.json (100 cepas) + cruce canónico
    StreamingAssets/
      strains.json        dataset de 100 cepas
    Scenes/               (crea aquí Game.unity)
  .gitignore
```

## Arte / texturas
Los tiles actuales son **cuadros de color originales** (placeholder). Para el
tileset lush definitivo: genera arte **propio** (p.ej. con el MCP de PixelLab ya
configurado en el repo — requiere `PIXELLAB_API_KEY`) e impórtalo como Sprites
con *Filter Mode: Point* y *Pixels Per Unit: 16*. **No** uses rips de Pokémon u
otros assets con copyright (lo prohíbe el `CLAUDE.md` del proyecto).

## Pendiente (siguientes pasos)
- Sustituir placeholders por tileset original + sprites de personaje 4-dir.
- Portar a C# la genética/cruces/cultivo (ya hay base de datos + cruce canónico).
- UI (Canvas) para mochila/banco/Strain-dex/laboratorio.
- Warps entre mapas, NPCs y diálogos.

# Compilar el C# sin Unity

Aquí se compila `unity/BilboCity/Assets/**` con Roslyn — el compilador de C# de verdad —
sin necesidad de tener el editor instalado.

```bash
apt-get install -y dotnet-sdk-8.0   # una vez
./compilar.sh                       # o, desde la raíz, ./verificar.sh csharp
```

## Cómo funciona

`apinado/Api/` es un remedo de la API de UnityEngine: las clases, structs, enums y
operadores que este proyecto usa, **con las firmas exactas del motor y los cuerpos
vacíos**. Nunca se ejecuta; solo existe para que el compilador tenga contra qué resolver.
`apinado-editor/Api/` hace lo mismo con UnityEditor.

Encima hay dos proyectos que reproducen los `.asmdef` del juego:

| | Compila | Ve |
|---|---|---|
| `Juego.csproj` | `Assets/Scripts/**` | solo UnityEngine |
| `Editor.csproj` | `Assets/Editor/**` | UnityEngine, UnityEditor y `Juego` |

Están en ensamblados separados a propósito: así, si un fichero de runtime tocara
`UnityEditor`, la compilación falla igual que fallaría en Unity. Las opciones son las que
usa Unity 2022.3 — `netstandard2.1`, C# 9 — y va con `-warnaserror`.

## Qué caza y qué no

**Sí:** sobrecargas, conversiones implícitas, genéricos, ambigüedades entre espacios de
nombres, miembros que no existen, tipos mal usados, campos muertos. Es decir, todo lo que
el analizador de `../csharp/` no puede ver porque trabaja sobre el árbol de sintaxis.

**No:** las versiones de los paquetes de `Packages/manifest.json`, IL2CPP, los `.meta`, el
build de Android, y — lo importante — que el juego *funcione*. Compilar no es ejecutar.

## Si tocas el remedo

Regla única: **copia la firma real de Unity**. Si falta un miembro, el compilador da un
error falso y se ve enseguida. Si sobra un miembro o una firma es más permisiva que la del
motor (un parámetro `object` donde Unity pide un tipo concreto, un `set` donde Unity solo
tiene `get`), el error real se cuela sin que nadie se entere. Ese es el único fallo que
esta herramienta puede tener, y no avisa.

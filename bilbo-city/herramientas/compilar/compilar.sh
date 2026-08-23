#!/usr/bin/env bash
# Compila el C# del proyecto Unity de verdad, con Roslyn, sin tener Unity.
#
# Cómo: en 'apinado/' hay un remedo de la API de UnityEngine y en 'apinado-editor/'
# uno de UnityEditor — solo firmas, nunca se ejecutan. El código del juego se compila
# contra ellos con las mismas opciones que usa Unity 2022.3 (netstandard2.1, C# 9) y
# con la misma separación de ensamblados que los .asmdef: el runtime no ve el editor.
#
# Esto sí resuelve sobrecargas, conversiones implícitas y genéricos — lo que el
# analizador de sintaxis no puede. No sustituye a abrir Unity (no valida el
# instalador de escena en ejecución, ni los paquetes, ni el build de Android),
# pero caza los errores de compilación antes de arrancar el editor.
#
# Requiere el SDK de .NET 8:  apt-get install -y dotnet-sdk-8.0
set -e
cd "$(dirname "$0")"

if ! command -v dotnet > /dev/null; then
  echo "falta el SDK de .NET 8 — apt-get install -y dotnet-sdk-8.0" >&2
  exit 1
fi

export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1
# Sin reutilizar nodos: MSBuild los deja vivos esperando otra compilación, y en un
# contenedor eso son procesos sueltos después de que el script haya terminado.
export MSBUILDDISABLENODEREUSE=1

# Editor.csproj arrastra a Juego.csproj y a los dos remedos: una orden basta.
# -warnaserror para que un aviso nuevo no pase desapercibido.
dotnet build Editor.csproj -v q --nologo -warnaserror -nodeReuse:false

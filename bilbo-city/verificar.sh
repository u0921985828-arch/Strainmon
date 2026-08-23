#!/usr/bin/env bash
# Verificación completa del repositorio. Devuelve 0 solo si todo pasa.
#
#   ./verificar.sh          todo
#   ./verificar.sh html     solo el prototipo de referencia
#   ./verificar.sh csharp   solo el proyecto Unity
set -e
cd "$(dirname "$0")"
QUE="${1:-todo}"

if [ "$QUE" = "todo" ] || [ "$QUE" = "csharp" ]; then
  echo "═══ C# · compilación (Roslyn contra remedo de la API de Unity) ═══"
  herramientas/compilar/compilar.sh
  echo
  echo "═══ C# · sintaxis ═══"
  python3 herramientas/csharp/sintaxis.py
  echo
  echo "═══ C# · semántica ═══"
  python3 herramientas/csharp/semantica.py
  echo
fi

if [ "$QUE" = "todo" ] || [ "$QUE" = "html" ]; then
  echo "═══ HTML · batería de juego ═══"
  ( cd herramientas/html && node pruebas.js )
  echo
fi

echo "═══ todo en orden ═══"

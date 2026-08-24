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
  echo "═══ sitios · HTML contra Unity ═══"
  python3 herramientas/plano/sitios.py
  echo
  echo "═══ edificios singulares · HTML contra Unity ═══"
  python3 herramientas/plano/singulares.py
  echo
  echo "═══ callejero · HTML contra Unity ═══"
  python3 herramientas/plano/calles.py
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
  echo "═══ callejero · extracción del plano ═══"
  python3 herramientas/plano/pruebas_extraer.py
  echo
  echo "═══ sprites · tablas del empaquetador ═══"
  python3 herramientas/sprites/pixellab.py --coste
  echo
  echo "═══ arte · guía de estilo ═══"
  ( cd herramientas/html && node estilo.js )
  echo
fi

echo "═══ todo en orden ═══"

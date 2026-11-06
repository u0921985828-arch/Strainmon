#!/usr/bin/env bash
# U3 (fase 5): simula la deuda con tres perfiles (prudente, medio, torpe) con el motor real de Godot y escribe docs/ECONOMIA-SIM.md.
# Sale con 1 si el medio no paga todos los plazos a tiempo o el torpe no se recupera. ECO_AZAR=<n> cambia la semilla.
cd "$(dirname "$0")/.." || exit 1
G=${GODOT:-/home/user/godot-bin/Godot_v4.7-stable_linux.x86_64}
"$G" --headless --path godot --script res://tests/economia.gd -- --salida "$PWD/docs/ECONOMIA-SIM.md" 2>&1 | grep -E "^economia:"
exit "${PIPESTATUS[0]}"

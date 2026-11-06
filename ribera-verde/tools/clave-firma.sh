#!/bin/sh
# Genera la clave de firma de la app (upload key) de Landrace Hunters.
#
# NO se ejecuta solo ni dentro del repositorio: la clave es la identidad de la app en Android
# (paquete + firma) y, una vez repartida, cambiarla obliga a desinstalar y borra las partidas.
# Lo que hay que saber antes de lanzarlo está en docs/MIGRACION-BETA.md.
#
#   sh tools/clave-firma.sh [/ruta/donde/guardarla]
#
# Por defecto la deja en ~/.landrace/upload.jks, fuera del repositorio. Si la sesión corre en un
# contenedor que se recicla, esa ruta NO sobrevive: hay que copiar el .jks y su contraseña a un sitio
# propio (gestor de contraseñas, disco, copia cifrada) antes de cerrar la sesión. Así se perdió la primera.
set -eu

DEST="${1:-$HOME/.landrace/upload.jks}"
ALIAS="upload"
DNAME="CN=WOLFCADE, O=WOLFCADE, C=ES"
DIAS=10950          # 30 años: Play exige que caduque después del 22-10-2033

case "$DEST" in
	*/ribera-verde/*|*/Strainmon/*)
		echo "ERROR: la clave no puede estar dentro del repositorio ($DEST)." >&2
		exit 1 ;;
esac
[ -e "$DEST" ] && { echo "ERROR: ya existe $DEST. No se sobrescribe una clave." >&2; exit 1; }

mkdir -p "$(dirname "$DEST")"
chmod 700 "$(dirname "$DEST")" 2>/dev/null || true

# keytool pregunta la contraseña: no se pasa por la línea de órdenes (queda en el historial)
keytool -genkeypair -v \
	-keystore "$DEST" -storetype PKCS12 \
	-alias "$ALIAS" -keyalg RSA -keysize 4096 \
	-validity "$DIAS" -dname "$DNAME"
chmod 600 "$DEST"

echo
echo "Clave creada: $DEST (alias $ALIAS)"
echo
echo "Huella SHA-1 (hace falta en Play Games Services, ver docs/MIGRACION-BETA.md § 5):"
keytool -list -v -keystore "$DEST" -alias "$ALIAS" | grep -i 'SHA1\|SHA-1' || true
echo
echo "Para compilar, en los ajustes del entorno (nunca en el repositorio):"
echo "  LH_KEYSTORE_USER=$ALIAS"
echo "  LH_KEYSTORE_PASS=<la contraseña que acabas de poner>"
echo "y la clave, de una de las dos formas:"
echo "  LH_KEYSTORE=$DEST                 (la ruta; solo si el disco sobrevive)"
echo "  LH_KEYSTORE_B64=<el .jks en base64>  (lo que sobrevive en un contenedor efímero)"
echo
echo "El base64 para esa variable:"
echo "  base64 -w0 $DEST"
echo
echo "Y para Play, el certificado de carga:"
echo "  keytool -export -rfc -alias $ALIAS -keystore $DEST -file upload_certificate.pem"
echo
echo "GUÁRDALA FUERA DE ESTA MÁQUINA. Sin ella, la próxima versión obliga a desinstalar y"
echo "cada jugador pierde su partida si no la exportó antes."

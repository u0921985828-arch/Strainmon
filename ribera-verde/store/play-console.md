# Play Console · lo que configura Eddie para la fase 6

Nada de esto lo hace el código: son pasos en la consola. Sin ellos el juego funciona igual (sin compra, logros, nube ni
informes: `plataforma.gd` lo detecta y no envía nada).

## 1. Producto de la compra única
1. Monetizar → Productos → Productos de aplicación → Crear producto.
2. ID del producto: **`juego_completo`** (tiene que ser exactamente ese: `COMPLETO.producto` en `datos.json`). No consumible.
3. Nombre «Juego completo», descripción «Los capítulos 4 a 8 de Landrace Hunters», precio, y **Activar**.
4. Configuración → Pruebas de licencia: añade tu cuenta de Gmail (y las de los testers) y responde «RESPOND_NORMALLY».
5. Prueba: instala desde la pista de prueba interna con esa cuenta, juega hasta pagar el plazo del capítulo 3 → «Comprar el
   juego completo» → la compra de prueba no cobra. Después, START → JUEGO COMPLETO no vuelve a salir y el capítulo 4 sigue.

## 2. Play Games (logros y nube)
1. Crecimiento → Play Games Services → Configuración → «No, mi juego no usa API de Google» → crea el proyecto.
2. Credenciales: Android, con el paquete `com.landracehunters.game` y la huella SHA-1 de la **clave de firma de apps** (Play
   Console → Integridad de la app) y otra con la de la upload key.
3. Copia el **ID del proyecto** (un número) en `godot/datos/play_games.json` → `app_id`.
4. Activa **Partidas guardadas** (Configuración → Propiedades) para la nube.
5. Logros: crea los 27 de `store/logros-play-games.csv` (nombre, descripción y puntos, que suman 1000). Copia el ID que da la
   consola (`Cgk…`) de cada uno en `play_games.json` → `logros.<clave>.id`. Publica los cambios de Play Games.
6. Vuelve a generar el AAB (el ID de proyecto entra en el manifiesto al exportar).

## 3. Informes de errores (Sentry, opt-in)
1. Crea una cuenta y un proyecto Android en sentry.io (plan gratuito).
2. Copia el DSN en `godot/src/plataforma.gd` → `SENTRY_DSN`. Retención de datos: 90 días; desactiva «Store IPs» y el
   «Data Scrubber» de serie activado.
3. Sin DSN, OPCIONES · INFORMES DE ERRORES se puede activar pero no se envía nada.

## 4. Formularios
- Seguridad de los datos: `store/data-safety.md` (ahora «Sí» recoge, solo registros de fallos y diagnóstico, opcionales).
- Clasificación (IARC): `store/iarc.md` (compras digitales: sí).
- Política de privacidad: publicar `store/privacy-policy.md` en una URL pública y pegarla.
- Acceso a la app: «Toda la funcionalidad está disponible sin restricciones» no aplica; indica que los capítulos 4-8 requieren
  la compra y que los revisores usan una cuenta de prueba de licencias.

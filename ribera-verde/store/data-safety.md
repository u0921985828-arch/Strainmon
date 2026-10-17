# Formulario «Seguridad de los datos» (Play Console → Contenido de la app → Seguridad de los datos)

Respuestas para la versión de la tienda (`Datos.PLAY = true`, paquete `com.landracehunters.game`). Si una fase posterior añade
algo que envíe datos (informes de fallos, compras), este archivo se actualiza con ella.

## 1. Recogida y compartición

| Pregunta | Respuesta |
|---|---|
| ¿Tu app recoge o comparte alguno de los tipos de datos de usuario obligatorios? | **No** |
| ¿Todos los datos de usuario recogidos por tu app están cifrados en tránsito? | No aplica (no se envía nada) |
| ¿Ofreces una forma de que los usuarios pidan que se eliminen sus datos? | No aplica (no se recoge nada; la partida se borra desde el juego o al desinstalar) |

Con «No» en la primera pregunta la consola salta el resto y muestra en la ficha «No se recogen datos» y «No se comparten datos
con terceros».

## 2. Por qué es «No»

- El juego no tiene código de red: ni cuentas, ni anuncios, ni analítica, ni informes de fallos.
- `export_presets.cfg` solo pide `VIBRATE` (la vibración de los mandos, OPCIONES → VIBRACIÓN), que no da acceso a ningún dato; ni `INTERNET` ni ningún otro.
- La partida y los ajustes se quedan en la carpeta privada de la app.
- **Copia de seguridad de Android** (`user_data_backup/allow=true`): la hace el sistema, bajo la cuenta de Google del usuario y
  cifrada; el desarrollador no recibe nada. Según la guía de Google Play, lo que se transfiere con el servicio de copia de
  seguridad de Android no cuenta como dato «recogido» por la app.
- El portapapeles solo se usa cuando el jugador pulsa EXPORTAR o IMPORTAR en OPCIONES · COPIA DE SEGURIDAD, y no sale del
  móvil.

## 3. Otras casillas de la consola

| Campo | Respuesta |
|---|---|
| Permisos | Solo `VIBRATE` (permiso normal, sin acceso a datos) |
| Anuncios | No contiene anuncios |
| Acceso a la app | Toda la app es accesible sin credenciales |
| Política de privacidad (URL) | La URL pública de `store/privacy-policy.md` |

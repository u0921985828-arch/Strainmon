# Play Console · lo que configura Eddie

Nada de esto lo hace el código: son pasos en la consola. Sin ellos el juego funciona igual y entero (sin los paquetes de
semillas doradas, los logros, la nube ni los informes: `plataforma.gd` lo detecta y no envía nada).

## 1. Los productos de LA TIENDA (paquetes de semillas doradas)

El juego ya no es una demo: los ocho capítulos vienen con la aplicación. Lo de pago son los extras de LA TIENDA, que se compran
con semillas doradas, la moneda que se gana jugando. Los paquetes de semillas doradas son lo único que se paga con dinero.

1. Monetizar → Productos → Productos de aplicación → Crear producto, uno por fila. Los ID tienen que ser exactamente estos
   (`TIENDA.it[].prod` en `datos.json`) y los cuatro son **consumibles** (se vuelven a comprar; el plugin los consume solo).

| ID del producto | Nombre | Lo que da | Precio sugerido |
|---|---|---|---|
| `sd_120` | Puñado de semillas doradas | 120 semillas doradas | 2,99 € |
| `sd_400` | Sobre de semillas doradas | 400 semillas doradas | 7,99 € |
| `sd_1000` | Bote de semillas doradas | 1000 semillas doradas | 17,99 € |
| `sd_2600` | Caja de semillas doradas | 2600 semillas doradas | 39,99 € |

2. El producto viejo **`juego_completo`** (la compra única de cuando el juego era una demo) se **desactiva**, no se borra: a quien
   la hizo se le regalan 300 semillas doradas la primera vez que abre (`tn_regalo`), y eso se mira por la compra que ya tiene.
3. Configuración → Pruebas de licencia: añade tu cuenta de Gmail (y las de los testers) y responde «RESPOND_NORMALLY».
4. Prueba: instala desde la pista de prueba interna con esa cuenta, START → LA TIENDA → SEMILLAS DORADAS → un paquete → la compra
   de prueba no cobra y las semillas doradas entran. Al repetirla tiene que dejar comprar otra vez (es consumible).

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

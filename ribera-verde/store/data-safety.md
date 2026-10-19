# Formulario «Seguridad de los datos» (Play Console → Contenido de la app → Seguridad de los datos)

Respuestas para la versión de la tienda (`Datos.PLAY = true`, paquete `com.landracehunters.game`) desde la fase 6: compra única
(Facturación de Google Play), Play Games v2 (logros y nube) e informes de errores de Sentry **con consentimiento** (apagados de
serie). Sin anuncios ni analítica.

## 1. Recogida y compartición

| Pregunta | Respuesta |
|---|---|
| ¿Tu app recoge o comparte alguno de los tipos de datos de usuario obligatorios? | **Sí** |
| ¿Todos los datos de usuario recogidos por tu app están cifrados en tránsito? | **Sí** (HTTPS: Sentry y los servicios de Google) |
| ¿Ofreces una forma de que los usuarios pidan que se eliminen sus datos? | **Sí** (los informes, por la dirección de contacto; se borran solos a los 90 días) |

## 2. Tipos de datos (solo lo que recoge la app; lo de Play Billing y Play Games lo declara Google)

| Categoría → tipo | ¿Recogido? | ¿Compartido? | ¿Opcional? | Para qué |
|---|---|---|---|---|
| Información y rendimiento de la app → **Registros de fallos** | Sí | No (Sentry es encargado del tratamiento: no cuenta como compartir) | **Sí** (OPCIONES · INFORMES DE ERRORES, apagado de serie) | Análisis (diagnóstico de fallos) |
| Información y rendimiento de la app → **Diagnóstico** | Sí (modelo, versión de Android y del juego, hitos de la partida) | No | **Sí** (el mismo interruptor) | Análisis (diagnóstico de fallos) |
| Identificadores del dispositivo u otros | **No** (Sentry sin PII: `sendDefaultPii=false`, sin capturas ni jerarquía de vistas) | — | — | — |
| Información personal, ubicación, contactos, fotos, audio, mensajes, salud, finanzas | No | — | — | — |

Notas para la consola:
- **Compras** (Facturación de Google Play): el pago lo trata Google; la app no ve datos de pago. Google indica que lo que
  procesa su biblioteca de facturación lo declara él; no se marca «Información financiera».
- **Play Games**: el inicio de sesión y los logros los trata Google Play Juegos bajo su propia política.
- **Datos efímeros**: no.

## 3. Otras casillas de la consola

| Campo | Respuesta |
|---|---|
| Permisos | `INTERNET` (de las bibliotecas de Google y Sentry), `POST_NOTIFICATIONS` (solo se pide al activar el aviso de cosecha), `VIBRATE`, `com.android.vending.BILLING` |
| Anuncios | No contiene anuncios |
| Compras en la aplicación | Sí: una compra única, «Juego completo» (no consumible) |
| Acceso a la app | Los capítulos 1 a 3 sin credenciales; el resto, tras la compra. Para la revisión: cuenta de tester de licencias (ver `play-console.md`) |
| Política de privacidad (URL) | La URL pública de `store/privacy-policy.md` |

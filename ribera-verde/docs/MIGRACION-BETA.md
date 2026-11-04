# Que los beta tester no pierdan el progreso

Estado del problema, las dos ramas posibles y lo que se hace en el juego para que no vuelva a pasar.
Escrito a raíz de lo que contó el usuario: se perdió la clave de firma del contenedor y la pregunta fue
«ahora todos los beta tester perderán sus progresos».

## 1 · Por qué se pierde una partida en Android

La partida vive en el directorio privado de la aplicación (`user://partida.json`, que en Android es
`/data/data/<paquete>/files/`). Ese directorio es de la **identidad de la app**, y la identidad son dos cosas:

- el **paquete** (`com.landracehunters.game`), y
- la **firma** del paquete que se instaló.

Cambiar cualquiera de las dos hace una app distinta para el sistema:

- **Otro paquete** → se instala al lado, como dos juegos; la partida se queda en el viejo.
- **Mismo paquete, otra firma** → Android se niega a instalar encima (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`).
  Hay que desinstalar el viejo, y **al desinstalar se borra su directorio privado**: la partida se va con él.

De ahí la regla del proyecto: *el paquete y la upload key no se cambian nunca*.

## 2 · Las dos ramas

Todo depende de una sola pregunta: **¿esta app está publicada en Google Play con Play App Signing?**

### Rama A · Sí está en Play (Play App Signing activo) → no se pierde nada

Con Play App Signing, la clave con la que el usuario recibe la app (la *clave de firma de la app*) la guarda
Google, no nosotros. Lo nuestro es solo la **clave de carga** (*upload key*), que es la que firma el AAB antes
de subirlo. Esa es la que se perdió, y Google permite reiniciarla:

1. Generar una clave de carga nueva (`keytool -genkeypair …`, PKCS12) **fuera del repositorio**.
2. Exportar su certificado (`keytool -export -rfc -alias upload -file upload_certificate.pem`).
3. En Play Console → *Pruebas y versiones* → *Firma de apps* → **solicitar el reinicio de la clave de carga**,
   adjuntando ese `.pem`. Google lo aplica en unas 48 h hábiles.
4. Desde entonces, el AAB se firma con la clave nueva, Google lo vuelve a firmar con la clave de la app de
   siempre y **para el móvil del tester es la misma app**: actualiza encima, la partida sigue ahí.

Coste para los testers: cero. No hay que hacer nada más que actualizar.

### Rama B · No está en Play todavía (la beta se repartió como APK) → hay que migrar la partida

Un APK repartido a mano va firmado con *nuestra* clave, y ahí no hay reinicio posible: sin la clave, el APK
nuevo lleva otra firma y el viejo hay que desinstalarlo. La partida no se puede copiar de fuera (el
directorio privado no es accesible sin root ni `adb backup`, que Android 12+ ya no permite en apps normales).

Lo que sí se puede es **sacar la partida desde dentro del juego antes de desinstalar**. Eso ya existe:

> OPCIONES → COPIA DE SEGURIDAD → **EXPORTAR PARTIDA**

copia al portapapeles un texto que empieza por `LH1.` (la partida en gzip, cifrada y con su suma de control,
unos 14 KB), y **IMPORTAR PARTIDA** lo acepta de vuelta, también desde el título y aunque venga con texto
alrededor. Está en el juego desde la 1.43.4, así que las versiones que tienen los testers ya lo traen.

**El guion para los testers, en orden (y solo así):**

1. Abrir el juego que tienen **ahora**, antes de tocar nada.
2. OPCIONES → COPIA DE SEGURIDAD → EXPORTAR PARTIDA.
3. Sacar la copia **fuera del móvil**: con la versión nueva, GUARDAR EN UN ARCHIVO (y moverlo a Drive o al
   ordenador) o MANDARLA A OTRA APP; con una versión vieja, el texto va al portapapeles y se pega en un mensaje
   a uno mismo, un correo o una nota de Drive. Nunca en una nota local, que se pierde con el móvil.
4. Desinstalar el juego viejo.
5. Instalar el nuevo.
6. En el título, RECUPERAR PARTIDA → ABRIR UN ARCHIVO (o PEGAR EL TEXTO) → Cargar.

Si alguien desinstala antes del paso 2, su partida no se recupera: no hay copia en ningún otro sitio.
Por eso el aviso tiene que salir **antes** de repartir la versión nueva.

## 3 · Lo que se hace en el juego (para que no vuelva a pasar)

Tres cosas, en este orden de valor:

1. **RECUPERAR PARTIDA a la vista.** Importar estaba escondido en OPCIONES → COPIA DE SEGURIDAD. En el título,
   cuando no hay partida guardada (que es justo el caso del tester que acaba de instalar la versión nueva), sale
   una fila propia que lleva a importar y, con Play Games, a la nube.
2. **La copia, a un archivo y a donde quiera el usuario.** El portapapeles se pierde con un copiar de por medio.
   El plugin de Android gana tres métodos sin permisos ni acceso al almacenamiento compartido, por el selector
   del sistema: compartir el texto (`ACTION_SEND`: mensajería, correo, Drive), guardarlo como archivo
   (`ACTION_CREATE_DOCUMENT`) y volver a abrirlo (`ACTION_OPEN_DOCUMENT`). Un archivo en Descargas o en Drive
   sobrevive a la desinstalación; el directorio privado, no.
3. **La nube de Play Games.** Ya estaba escrito (`plataforma.gd` → `nube_guarda` al pausar, `nube_carga`): la
   partida viaja en la cuenta de Google del jugador y es independiente del móvil. Ahora se elige al importar,
   junto con el archivo y el texto pegado (`importa_de`), en vez de estar en un sitio aparte de COPIA DE
   SEGURIDAD; y RECUPERAR PARTIDA del título lleva a ese mismo menú.

### Lo de la nube y la firma, que tiene trampa

Play Games Services identifica a la app por **paquete + huella SHA-1 del certificado**. Con una firma nueva, las
partidas guardadas de la cuenta no se ven… hasta que se añade esa huella al mismo proyecto de Play Games
Services (Play Console → *Play Games Services* → *Configuración* → *Credenciales* → añadir una credencial de
Android con el SHA-1 nuevo). Un proyecto admite varias credenciales, así que conviven la vieja y la nueva y los
guardados de la cuenta siguen ahí. Esto es configuración de consola, no código.

## 4 · Lo que hay que hacer, por quién

| # | Qué | Quién | Cuándo |
|---|-----|-------|--------|
| 1 | Decir si la app está ya en Play (decide rama A o B) | el usuario | antes que nada |
| 2 | Rama A: generar la clave de carga nueva y pedir el reinicio en Play Console | el usuario | 48 h antes de la entrega |
| 2' | Rama B: mandar a los testers el guion del § 2 **antes** de repartir el APK nuevo | el usuario | antes de la entrega |
| 3 | Guardar `LH_KEYSTORE`, `LH_KEYSTORE_USER` y `LH_KEYSTORE_PASS` en los ajustes del entorno (nunca en el repo ni en el chat) | el usuario | antes de compilar |
| 4 | RECUPERAR PARTIDA en el título, la copia a archivo y la nube al arrancar | el juego | hecho en esta tanda |
| 5 | Añadir el SHA-1 nuevo como credencial del proyecto de Play Games Services | el usuario | al publicar |
| 6 | Subir el primer AAB a Play y dejar Play App Signing activado | el usuario | al publicar |

Desde el punto 6, el problema no vuelve: la clave de la app la guarda Google y una clave de carga perdida solo
cuesta una solicitud de reinicio.

## 5 · Lo que no vale

- **`adb backup`**: desactivado por defecto desde Android 12 y no funciona en apps con `allowBackup=false`.
- **Copiar `/data/data/…` a mano**: pide root.
- **Copia automática del juego en `user://`**: está en el mismo directorio privado que se borra al desinstalar.
  Sirve contra un fallo de guardado (y para eso está `partida.rota.json`), no contra una reinstalación.
- **Cambiar el paquete para que convivan las dos versiones**: el paquete no se cambia nunca (regla del
  proyecto). Y aunque conviviesen, la partida seguiría estando en el viejo: habría que exportarla igual.

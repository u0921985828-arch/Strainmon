# Que los beta tester no pierdan el progreso

Qué pasa con las partidas al cambiar la firma de la app, qué hay que hacer y lo que se ha metido en el
juego para que no vuelva a pasar. Escrito a raíz de lo que contó el usuario: se perdió la clave de firma
del contenedor y la pregunta fue «ahora todos los beta tester perderán sus progresos».

**Situación (la dijo el usuario el 5-11-2026): el juego NO está publicado en Google Play todavía.** La beta
se repartió como APK a mano, así que **aplica la rama B del § 3**: no hay reinicio de clave de carga y cada
tester tiene que **exportar su partida antes de desinstalar**.

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

## 2 · La clave nueva

Sin la clave vieja, el APK y el AAB nuevos van firmados con otra, y no hay forma de recuperar la anterior:
una clave de firma no se regenera, se guarda. Así que hace falta una nueva, y **fuera del contenedor**, que
es efímero y se recicla al cerrar la sesión: es exactamente así como se perdió la primera.

El comando está preparado en `tools/clave-firma.sh` (no se ejecuta solo: genera la identidad definitiva de
la app y eso no se deshace). Resumen de lo que hace:

```sh
keytool -genkeypair -v -keystore upload.jks -storetype PKCS12 \
        -alias upload -keyalg RSA -keysize 4096 -validity 10950 \
        -dname "CN=WOLFCADE, O=WOLFCADE, C=ES"
```

Y luego, para compilar, en los **ajustes del entorno** (nunca en el repositorio): `LH_KEYSTORE_USER` (el
alias, `upload`), `LH_KEYSTORE_PASS` y la clave, de una de estas dos formas:

- `LH_KEYSTORE_B64`, el `.jks` entero en base64 (`base64 -w0 upload.jks`, unos 5,7 KB). **Es la que vale en
  una sesión que corre en un contenedor efímero**, porque la variable del entorno sobrevive y un archivo en
  el disco del contenedor no: así se perdió la primera clave. `tools/godot-aab.js` la escribe en un temporal
  de permisos 0600 fuera del repositorio y lo borra al terminar.
- `LH_KEYSTORE`, la ruta del `.jks`, cuando la máquina es propia y el archivo se queda ahí.

Mientras no estén, `tools/godot-aab.js` avisa y el AAB sale **sin firmar** (Play no lo acepta) y el APK con la
clave de depuración.

Reglas de la clave, para no repetir el problema:

- El `.jks` y su contraseña, guardados en dos sitios distintos y fuera del contenedor (gestor de contraseñas,
  disco propio, copia cifrada en la nube). Si se pierde, el problema de ahora vuelve entero.
- `validity` de 10.950 días (30 años): Play exige que la clave caduque después del 22-10-2033.
- El `.jks` nunca entra en el repositorio: `godot-aab.js` se niega si la ruta cae dentro de él.

## 3 · Rama B · La que aplica ahora (la beta se repartió como APK)

Un APK repartido a mano va firmado con *nuestra* clave, y ahí no hay reinicio posible: sin la clave, el APK
nuevo lleva otra firma y el viejo hay que desinstalarlo. La partida no se puede copiar de fuera (el
directorio privado no es accesible sin root ni `adb backup`, que Android 12+ ya no permite en apps normales).

Lo que sí se puede es **sacar la partida desde dentro del juego antes de desinstalar**. Eso ya existe:

> OPCIONES → COPIA DE SEGURIDAD → **EXPORTAR PARTIDA**

da un texto que empieza por `LH1.` (la partida en gzip, cifrada y con su suma de control, unos 14 KB), y
**IMPORTAR PARTIDA** lo acepta de vuelta, también desde el título y aunque venga con texto alrededor. Está en
el juego desde la 1.43.4, así que las versiones que tienen los testers ya lo traen.

**El guion, en orden (y solo así):**

1. Abrir el juego que tienen **ahora**, antes de tocar nada.
2. OPCIONES → COPIA DE SEGURIDAD → EXPORTAR PARTIDA.
3. Sacar la copia **fuera del móvil**: con la versión nueva, GUARDAR EN UN ARCHIVO (y moverlo a Drive o al
   ordenador) o MANDARLA A OTRA APP; con una versión vieja, el texto va al portapapeles y se pega en un
   mensaje a uno mismo, un correo o una nota de Drive. Nunca en una nota local, que se pierde con el móvil.
4. Desinstalar el juego viejo.
5. Instalar el nuevo.
6. En el título, RECUPERAR PARTIDA → ABRIR UN ARCHIVO (o PEGAR EL TEXTO) → Cargar.

Quien desinstale antes del paso 2 pierde su partida: no hay copia en ningún otro sitio. Por eso el aviso del
§ 4 va **antes** de repartir la versión nueva, y conviene esperar a que cada uno conteste que ya la ha sacado.

### Rama A · Cuando el juego esté en Play (para la próxima vez)

Con Play App Signing, la clave con la que el usuario recibe la app (la *clave de firma de la app*) la guarda
Google, no nosotros. Lo nuestro es solo la **clave de carga** (*upload key*), que firma el AAB antes de
subirlo, y esa sí se puede reiniciar:

1. Generar una clave de carga nueva (`tools/clave-firma.sh`) **fuera del repositorio**.
2. Exportar su certificado (`keytool -export -rfc -alias upload -file upload_certificate.pem`).
3. En Play Console → *Pruebas y versiones* → *Firma de apps* → **solicitar el reinicio de la clave de carga**,
   adjuntando ese `.pem`. Google lo aplica en unas 48 h hábiles.
4. Desde entonces el AAB se firma con la clave nueva, Google lo vuelve a firmar con la clave de la app de
   siempre y **para el móvil del tester es la misma app**: actualiza encima y la partida sigue ahí.

Coste para los testers: cero. Por eso, en cuanto se suba el primer AAB, hay que dejar Play App Signing
activado: a partir de ahí una clave de carga perdida solo cuesta una solicitud.

## 4 · El aviso para los testers (listo para copiar)

Se manda **antes** de repartir el APK nuevo, por el canal por el que se les reparte el juego:

> **IMPORTANTE antes de instalar la versión nueva de Landrace Hunters**
>
> La versión nueva va firmada con otra clave, así que el móvil la ve como una app distinta: hay que
> desinstalar la que tenéis y, **al desinstalarla, se borra la partida**. Se puede salvar, pero solo si la
> sacáis **antes**. Hacedlo así, en este orden:
>
> 1. Abrid el juego que tenéis ahora. No desinstaléis nada todavía.
> 2. OPCIONES → COPIA DE SEGURIDAD → EXPORTAR PARTIDA.
> 3. Guardad la copia **fuera del móvil**: si os deja elegir, GUARDAR EN UN ARCHIVO (y lo movéis a Drive o al
>    ordenador) o MANDARLA A OTRA APP (a vosotros mismos por correo o mensaje). Si solo os copia el texto,
>    pegadlo en un correo o un mensaje a vosotros mismos. En una nota del propio móvil no vale: se pierde.
> 4. Contestadme cuando la tengáis guardada.
> 5. Entonces ya: desinstaláis el juego viejo e instaláis el nuevo.
> 6. En la pantalla de inicio, RECUPERAR PARTIDA → ABRIR UN ARCHIVO (o PEGAR EL TEXTO) y cargáis la copia.
>
> Si desinstaláis antes del paso 2, esa partida no se recupera. Y si algo no os cuadra, preguntad antes de
> desinstalar.

## 5 · Lo que se hace en el juego (para que no vuelva a pasar)

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
guardados de la cuenta siguen ahí. Esto es configuración de consola, no código. La huella de la clave nueva:

```sh
keytool -list -v -keystore upload.jks -alias upload | grep SHA1
```

## 6 · Lo que hay que hacer, por quién

| # | Qué | Quién | Cuándo |
|---|-----|-------|--------|
| 1 | Generar la clave de firma nueva (`tools/clave-firma.sh`) y guardarla fuera del contenedor, con su contraseña | el usuario | antes de compilar |
| 2 | Poner `LH_KEYSTORE_USER`, `LH_KEYSTORE_PASS` y `LH_KEYSTORE_B64` (o `LH_KEYSTORE`) en los ajustes del entorno, nunca en el repositorio | el usuario | antes de compilar |
| 3 | Mandar a los testers el aviso del § 4 y esperar a que confirmen que tienen la copia | el usuario | antes de repartir el APK |
| 4 | RECUPERAR PARTIDA en el título, la copia a archivo y la nube al arrancar | el juego | hecho en esta tanda |
| 5 | Repartir el APK nuevo | el usuario | cuando confirmen |
| 6 | Subir el primer AAB a Play y dejar Play App Signing activado | el usuario | al publicar |
| 7 | Añadir el SHA-1 de la clave nueva como credencial del proyecto de Play Games Services | el usuario | al publicar |

Desde el punto 6, el problema no vuelve: la clave de la app la guarda Google y una clave de carga perdida solo
cuesta una solicitud de reinicio (rama A).

## 7 · Lo que no vale

- **`adb backup`**: desactivado por defecto desde Android 12 y no funciona en apps con `allowBackup=false`.
- **Copiar `/data/data/…` a mano**: pide root.
- **Copia automática del juego en `user://`**: está en el mismo directorio privado que se borra al desinstalar.
  Sirve contra un fallo de guardado (y para eso está `partida.rota.json`), no contra una reinstalación.
- **Cambiar el paquete para que convivan las dos versiones**: el paquete no se cambia nunca (regla del
  proyecto). Y aunque conviviesen, la partida seguiría estando en el viejo: habría que exportarla igual.
- **Firmar el APK con la clave de depuración para que instale encima**: esa clave es pública y conocida,
  cualquiera podría publicar una actualización falsa de la app. Y Play no acepta nada firmado con ella.

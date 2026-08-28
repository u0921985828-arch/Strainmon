plugins { id("com.android.application") }

/* Una sola fuente de verdad para el juego: el prototipo validado. En vez de tener una
   copia del HTML dentro de `assets/` —que se queda vieja el primer día— se copia al
   compilar. La copia está en .gitignore. */
val juego = rootProject.file("../referencia/bilbo-city.html")
val copiarJuego by tasks.registering(Copy::class) {
    from(juego) { rename { "index.html" } }
    into(layout.projectDirectory.dir("src/main/assets"))
    doFirst { require(juego.exists()) { "no encuentro el juego en $juego" } }
}
tasks.named("preBuild") { dependsOn(copiarJuego) }

android {
    namespace = "com.bilbocity.juego"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.bilbocity.juego"
        /* API 26 (Android 8) es el mínimo a propósito: por debajo el icono adaptativo
           necesitaría PNG en cinco densidades, y en este repositorio no entra ni una
           imagen. Con 26 el icono es XML y todo el arte sigue siendo código. */
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "0.1"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            /* Sin keystore propio no se firma de verdad: el APK de release saldría sin
               firmar y no instalaría. Para probar en el móvil vale el debug. */
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

/* Sin una sola dependencia. El juego entero va en el HTML y la parte nativa solo lo aloja,
   así que no hacen falta ni AppCompat ni AndroidX — y de paso no aparece el choque de
   kotlin-stdlib duplicado que se lleva media tarde. */
dependencies { }

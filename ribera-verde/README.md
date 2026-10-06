# Ribera Verde · genética de barrio

RPG de cultivo en pixel art, con 160 px de alto (y de 240 a 400 de ancho, según el móvil) al estilo de las portátiles de 16 bits. Variedades reales (Skunk #1, Afghani, Hindu Kush, Amnesia Haze…) y un guion serio. Toma las mecánicas de **Weed Firm**: cultivas en un armario, cruzas genéticas, vendes en la calle, esquivas a los ladrones y a la policía (o la sobornas) y sigues una historia de 7 capítulos para saldar la deuda que te dejó tu tía.

![Pantalla de título](screenshots/01-titulo.png)

## Jugar

- Abre **`index.html`** con doble clic (Chrome, Edge o Firefox). Funciona sin conexión porque las fuentes van dentro del archivo.
- La partida se guarda en el navegador al dormir, al cambiar de capítulo y desde START → GUARDAR o desde el ordenador del piso. No se comparte entre navegadores ni entre equipos.
- Está pensado para el **móvil en horizontal**: la pantalla del juego ocupa todo el móvil (solo queda un reborde fino) y los mandos flotan encima, fijos: cruceta abajo a la izquierda, A y B abajo a la derecha, SONIDO y START arriba a la derecha. En móviles anchos el mundo se ve más ancho (hasta 400 px de juego) y los diálogos quedan en el centro, entre los mandos. En vertical aparece «Gira el móvil». Al primer toque pide pantalla completa y bloquea el giro en horizontal (el APK va siempre en horizontal).
- **Android:** instala `dist/ribera-verde.apk` (activa «Instalar apps desconocidas» para el navegador o el gestor de archivos). Es el mismo juego en pantalla completa, sin conexión y sin permisos; el botón Atrás hace de B. La partida se guarda dentro de la app.

| Acción | Botón |
|---|---|
| Moverse | Cruceta |
| Hablar, usar, aceptar | A |
| Cancelar · mantener para correr | B |
| Menú (Genoteca, Mochila, Plantas, Objetivo, Guardar) | START |

En el PC también vale el teclado (flechas o WASD, Z/Espacio = A, X/Esc = B, M = START), aunque ya no se muestra en pantalla.

## Qué incluye

- **Cultivo:** carpas en el piso (el armario de 60 con 2 plantas, la de 100 con 4 y la de 150 con 6), cerradas por fuera y abiertas al entrar; una bandeja de cultivo por carpa, macetas de plástico o de tela de 7 a 25 L, focos CFL, sodio y LED de 125 a 720 W con su cobertura y su factura de la luz; riego, abono, plagas y cinco fases de crecimiento. La cosecha da gramos con su % de THC y semillas.
- **Genética:** mesa de cruces y Genoteca con 23 variedades: 6 del growshop, 4 landraces (una te la da Kiko y tres se consiguen por el barrio) y 13 que salen de cruces, entre ellas la legendaria *Ghost Train Haze* (Amnesia Haze × Fire OG). Los cruces sin receta generan híbridos propios.
- **Calle:** clientes con `$` (estudiante, currela, turista y pijo) a los que les pides precio de rebaja, justo o caro. Cada venta sube el **calor policial** y a 90 llega una redada.
- **Combates por turnos:** contra ladrones (luchar, mochila, hablar, huir) y contra la policía (sobornar, hablar, huir, entregar).
- **Historia:** la herencia de la tía Maite, la deuda de 5.000 € con Don Baltasar, el sargento Molina, el rival Darko y la Copa de Ribera.
- Día y noche, chiptune propio y guardado local.

## Carpetas

```
index.html                    el juego completo (lo genera tools/build.js)
src/                          código fuente: shell.html + styles.css + js/ (16 módulos)
tools/                        build, test de la historia, generador de docs, capturas y tools/sprites (kit PixelLab)
docs/                         diseño, guion, genética, mapa, plano de escala (PLANO.md + plano/) y prompts de sprites
dist/ribera-verde.artifact.html   la misma página en formato Artifact de Claude
dist/ribera-verde.apk         el juego como app de Android (lo genera tools/build-apk.js)
assets/fonts/                 Atkinson Hyperlegible y Press Start 2P (woff2 + licencia OFL)
screenshots/                  13 capturas
art/                          manifiesto de sprites, inventario, referencias PNG y paleta (kit PixelLab)
CONTEXTO.md                   qué se pidió, qué se decidió y en qué estado está
CLAUDE.md                     notas para seguir el desarrollo con Claude Code
CHANGELOG.md                  versiones
```

## Desarrollo

Hace falta Node 18 o superior. Los comandos funcionan igual en `cmd` de Windows.

```
npm install
npx playwright install chromium
npm run build      # src/ → index.html y dist/ribera-verde.artifact.html
npm test           # compila y recorre la historia completa (38 pasos) en Chromium sin ventana
npm run docs       # compila y regenera docs/GENETICA.md y docs/MAPA.md desde los datos del juego
npm run capturas   # compila y regenera screenshots/
npm run plano      # compila y regenera docs/plano/ (mapas con rejilla y hoja de escala)
npm run sprites:ref       # referencias PNG + paleta para PixelLab
npm run sprites:validar   # comprueba art/manifest.json
npm run sprites:procesar -- <grupo> [--atlas]   # salida de PixelLab → sprites listos
npm run sprites:catalogo  # catálogo de sprites por herramienta de PixelLab
npm run test:arte         # prueba el motor de sprites con un atlas de calco
npm run apk               # compila y empaqueta dist/ribera-verde.apk (Java 17+; sin Android SDK)
```

Edita siempre en `src/` y después ejecuta `npm run build`. `index.html` y `dist/` se generan con el build y no se tocan a mano.

## Documentación

- [CONTEXTO.md](CONTEXTO.md): la petición, las decisiones, el estado y los siguientes pasos.
- [docs/GDD.md](docs/GDD.md): mecánicas, fórmulas y economía.
- [docs/GUION.md](docs/GUION.md): historia y diálogos por capítulo.
- [docs/GENETICA.md](docs/GENETICA.md): las 23 variedades y el árbol de cruces.
- [docs/MAPA.md](docs/MAPA.md): mapas con coordenadas, personajes, objetos y tienda.
- [docs/PIXELLAB.md](docs/PIXELLAB.md): kit pro para cambiar todo el arte por sprites y animaciones de PixelLab con Claude Code (comando `/sprites`), sin salirse de la estética. El motor ya los usa en cuanto hay atlas.
- [docs/CATALOGO-SPRITES.md](docs/CATALOGO-SPRITES.md): cada sprite del juego con su herramienta de PixelLab (personajes, terreno, objetos sobre el mapa, lotes e imágenes), su orden y su coste.
- [CLAUDE.md](CLAUDE.md): arquitectura y partes delicadas del código.

## Capturas

| | |
|---|---|
| ![Piso y armario](screenshots/03-piso-armario.png) | ![Plaza de noche](screenshots/05-plaza-noche.png) |
| ![Venta](screenshots/06-venta.png) | ![Combate contra un ladrón](screenshots/07-combate-ladron.png) |
| ![Genoteca](screenshots/09-genoteca.png) | ![Growshop](screenshots/11-growshop.png) |

## Créditos y licencias

- El código y todo el arte son originales y se dibujan por código: no hay imágenes externas. Si se añade un atlas de PixelLab (`assets/sprites/`), se incrusta en el HTML y sustituye al dibujo por código donde lo cubra.
- Las mecánicas se inspiran en *Weed Firm* y la estética en los RPG de portátil de 16 bits. No se usa ningún asset, personaje, nombre ni marca de esos juegos.
- Fuentes: [Atkinson Hyperlegible](https://fonts.google.com/specimen/Atkinson+Hyperlegible) (diálogos, menús y HUD, pensada para leerse bien) y [Press Start 2P](https://fonts.google.com/specimen/Press+Start+2P) (rótulos), ambas con licencia SIL Open Font License 1.1 (`assets/fonts/`).

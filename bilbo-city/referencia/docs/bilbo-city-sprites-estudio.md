# BILBO CITY — Estudio de sprites

Inventario de todo lo que el juego necesita para que la ciudad no se repita a sí misma cada dos manzanas.

---

## 0. Conclusión del estudio, primero

Dibujar 1.000 fotogramas a mano es inviable y además es el enfoque equivocado. La respuesta correcta es
**composición por capas**: unas 350 piezas de arte únicas generan más de 1.000 fotogramas distintos.

| Enfoque | Piezas a dibujar | Variedad resultante |
|---|---|---|
| Un sprite por personaje | 30 personajes × 24 frames = **720** | 30 personajes |
| Por capas (el elegido) | 74 piezas de cuerpo/ropa | **1.680 fotogramas ya generados**, y miles de combinaciones más |

Un peatón se monta en tiempo de carga: complexión + tono de piel + pelo + gorro + prenda de torso +
pantalón + calzado + accesorio. Cambiando la semilla sale otro vecino. Lo mismo con los coches:
chasis + librea + extras.

**Rejilla nueva: 20×26 px** por personaje (antes 16×20). Da sitio a sombreros, mochilas y armas en la mano
sin recortar. El ancla son los pies, en el píxel inferior centro. Cambio en el juego:
`ctx.drawImage(s, x*TS-10, y*TS-19)`.

---

## 1. PERSONAJES

### 1.1 Piezas de capa (esto es lo que se dibuja)

| Capa | Variantes | Piezas |
|---|---|---|
| Complexión | delgada, media, corpulenta | 3 |
| Tono de piel | 6 | 6 |
| Pelo | rapado, corto, media melena, melena, coleta, moño, afro, calvo | 8 |
| Gorro / casco | txapela, gorra, gorra visera, casco obra, casco moto, gorro lana, visera policía, capucha | 8 |
| Torso | camisa, camisa remangada, chaqueta, cazadora, sudadera, chándal, mono de trabajo, abrigo, gabardina, jersey, bata, uniforme, camiseta, polo, chaleco reflectante, delantal | 16 |
| Piernas | vaquero, pantalón de vestir, chándal, mono, falda, short, pantalón cargo, uniforme | 8 |
| Calzado | deportivas, botas, zapatos, katiuskas | 4 |
| Accesorio | mochila, bolso, bandolera, bufanda, gafas, guantes, riñonera, carrito, ninguno | 9 |
| Sombreado direccional | 4 direcciones sobre cada capa | ×4 |

**Total de piezas: 62 + 12 de sombreado = 74**

### 1.2 Poses (por dirección, ×4)

| Pose | Frames | Uso |
|---|---|---|
| Quieto | 1 | parado, hablando |
| Andar | 4 | ciclo normal |
| Correr | 4 | sprint, huida de peatones |
| Atacar cuerpo a cuerpo | 2 | puños, bate, navaja |
| Apuntar / disparar | 2 | armas de fuego |
| Herido | 1 | al recibir daño |
| Caído | 2 | no direccional, muerte |

**24 frames direccionales + 2 de muerte por personaje montado.**

### 1.3 Arquetipos a montar (30)

**Protagonista** (txapela + cazadora) · **Ertzaina** de patrulla · **Ertzaina** de asalto ·
**Matón** de banda A · **Matón** de banda B · **Barman Josu** · **Txema** el jefe ·
**Mikel** el parroquiano · **Iker** el mecánico · **Bego** la pescatera · **Koldo** el armero ·
**Amaia** la casera · **Médico** · **Enfermera** · **Obrero** de andamio · **Estibador** del muelle ·
**Taxista** · **Repartidor** en moto · **Oficinista** · **Ejecutiva** · **Ama de casa con carrito** ·
**Aitite** con boina y bastón · **Amama** con bolsa de la compra · **Adolescente** de chándal ·
**Turista** con cámara · **Ciclista** · **Camarera** · **Tendero con delantal** ·
**Vigilante de seguridad** · **Marinero**

### 1.4 Prioridad

- **P0** — protagonista, ertzaina patrulla, matón A, peatón genérico ×6
- **P1** — todos los NPC con nombre (Josu, Txema, Iker, Bego, Koldo, Amaia, Mikel)
- **P2** — oficios de curro (obrero, estibador, taxista, repartidor, médico)
- **P3** — relleno de ambiente (turista, aitite, ciclista, adolescente…)

---

## 2. ARMAS

### 2.1 En la mano (overlay por dirección, ×4)

puños (nada) · navaja · bate · llave inglesa · botella rota · pistola · revólver · uzi · escopeta ·
fusil · cóctel molotov · extintor

**12 armas × 4 direcciones = 48 overlays**

### 2.2 Como objeto suelto en el suelo (recogible)

Las mismas 12, vista cenital, 1 frame cada una = **12**

### 2.3 Iconos de HUD

12 iconos monocromos a 24×24 = **12**

---

## 3. VEHÍCULOS

### 3.1 Chasis (40×22, morro a la derecha)

utilitario · berlina · ranchera · monovolumen · furgoneta corta · furgoneta larga · deportivo ·
todoterreno · taxi · patrulla Ertzaintza · ambulancia · bombero · camión de basura · autobús urbano ·
moto · scooter · bici · camión de obra · grúa · barca del Nervión

**20 chasis**

### 3.2 Libreas por chasis

6 colores base + rotativo encendido/apagado en los de emergencia + versión quemada de cada uno.
**≈ 60 sprites de vehículo**

### 3.3 Estados

intacto · abollado · humeando · en llamas (3 frames) · carcasa quemada = **7 estados**

---

## 4. TILES DE ENTORNO (32×32, tileables)

**Calzada (10):** asfalto liso, asfalto agrietado, línea discontinua H, línea discontinua V,
paso de cebra H, paso de cebra V, stop pintado, ceda el paso, bache, alcantarilla.

**Acera (8):** baldosa lisa, baldosa desgastada, adoquín Casco Viejo, adoquín rojo Abandoibarra,
rebaje de vado, borde con bordillo, acera con árbol, acera con rejilla.

**Verde (6):** césped, césped alto, tierra, camino de parque, seto, parterre.

**Agua (6):** ría ×2 frames, ría con espuma, orilla, hormigón de muelle, madera de pantalán.

**Techos (12):** teja marrón, teja roja, teja vieja, grava gris, chapa industrial, chapa oxidada,
azotea con lucernario, azotea con aire acondicionado, pizarra, azotea con tendedero,
azotea con antenas, azotea con depósito.

**Suelos interiores (8):** parqué, tarima de bar, baldosa hidráulica, terrazo,
hormigón de taller, linóleo de hospital, moqueta, chapa.

**Paredes interiores (8):** ladrillo visto, gotelé, azulejo de bar, azulejo de baño,
madera oscura, chapa industrial, pladur, piedra.

**Total tiles: 58**

---

## 5. PROPS DE CALLE (40)

farola de brazo · farola de bola · semáforo peatonal · semáforo de coches · árbol de copa ·
árbol podado · palmera de Abandoibarra · seto ·
contenedor verde · contenedor amarillo · contenedor de cartón · papelera ·
banco de madera · banco de piedra · marquesina de bus · cabina de teléfono ·
buzón · bolardo · valla de obra · andamio · palés · sacos de cemento · hormigonera ·
señal de stop · señal de dirección · placa de calle · terraza con mesas · toldo · sombrilla ·
bicicletero · patinete tirado · cubo de fregona · cono de tráfico · grúa portuaria ·
contenedor marítimo · bidón · bolardo de amarre · red de pesca · caja de pescado · charco.

---

## 6. INTERIORES Y ESTABLECIMIENTOS (48)

**Bar Zurito (10):** barra, tirador de cerveza, cafetera, vitrina de pintxos, estante de botellas,
taburete, mesa alta, mesa con manteles, máquina tragaperras, futbolín.

**Tu piso (8):** cama, armario, mesilla, sofá, tele, cocina, nevera, mesa camilla.

**Taller Iker (8):** elevador de coches, carro de herramientas, neumáticos apilados, bidón de aceite,
compresor, banco de trabajo, cartel de precios, foso.

**Bazar Nervión / armería (7):** vitrina de pistolas, panel de escopetas, mostrador,
caja registradora, estante de munición, diana, cartel de "no se fía".

**Mercado de la Ribera (6):** puesto de pescado con hielo, puesto de fruta, báscula colgante,
cajas apiladas, toldo a rayas, carro de reparto.

**Comisaría (5):** mostrador, celda, tablón de fichas, taquillas, archivador.

**Hospital (4):** camilla, mostrador de admisión, sillas de espera, biombo.

---

## 7. EFECTOS (32 frames)

fogonazo de boca ×4 direcciones · impacto en pared ×3 · impacto en carne (sangre) ×4 ·
charco de sangre ×2 · humo ×4 · chispas ×3 · explosión ×5 · cristal roto ×2 ·
marca de derrape · onda expansiva ×2 · lluvia ×2.

---

## 8. HUD E ICONOGRAFÍA (25)

12 iconos de arma · estrella de búsqueda llena y vacía · corazón/salud · icono de energía ·
icono de hambre · euro · blip de objetivo · blip de tienda · blip de misión ·
flecha de brújula · marcador "!" de misión · candado · reloj.

---

## 9. Recuento final

### Estimado antes de construir

| Bloque | Piezas a dibujar | Frames estimados |
|---|---|---|
| Personajes por capas | 74 | ~780 |
| Armas | 60 | 60 |
| Vehículos | 20 chasis + libreas | ~60 |
| Tiles | 58 | 64 |
| Props de calle | 40 | 40 |
| Interiores | 48 | 48 |
| Efectos | 32 | 32 |
| HUD | 25 | 25 |
| **TOTAL estimado** | **~357 piezas** | **~1.109 frames** |

### Medido ya en la forja

| Bloque | Sprites reales |
|---|---|
| Personajes | **3.360** (30 arquetipos × 14 poses × 8 direcciones) |
| Armas | 99 |
| Vehículos | 81 |
| Marcadores | 72 |
| Fuente | 56 |
| Tiles | 53 |
| Efectos | 52 |
| Props de calle | 39 |
| Interiores | 34 |
| HUD | 25 |
| **TOTAL** | **3.871 sprites** |

Auditado con canvas real: 0 sprites vacíos, 0 píxeles con alfa parcial,
0 colores fuera de paleta, ninguno por encima de 64 px.

---

## 10. Orden de ataque propuesto

| Lote | Contenido | Estado |
|---|---|---|
| **1** | Sistema de capas de personaje + 30 arquetipos | ✅ hecho |
| **2** | Armas en mano, sueltas e iconos | ✅ hecho |
| **3** | 20 chasis de vehículo + libreas + estados | ✅ hecho |
| **4** | 58 tiles de entorno | ✅ hecho |
| **5** | 40 props de calle | ✅ hecho |
| **6** | Piezas de interiores | ⏳ parcial (34 de 48) |
| **7** | Efectos y partículas | ✅ hecho |
| **8** | HUD e iconografía | ✅ hecho (25) |
| **9** | Integrar el atlas en el juego y retirar los sprites viejos | ✅ hecho |
| **10** | 8 direcciones, fuente de bits, marcadores y fogonazos por calibre | ✅ hecho |
| **11** | Generador de manzanas irregulares y tinte por distrito | ✅ hecho |
| **12** | HUD de portátil: radar circular con anillo de salud | ✅ hecho |

---

## 11. Reglas técnicas (idénticas para todo)

- Pixel duro, sin anti-alias. `imageSmoothingEnabled = false`, `image-rendering: pixelated`.
- 3 tonos por material: base, sombra, luz. Foco de luz arriba-izquierda a 45°.
- Fondo transparente real, sin halo.
- Paleta bloqueada de **48 colores**. Un cuantizador pasa por encima de cada sprite y ajusta
  cualquier color al más cercano de la paleta, además de forzar el alfa a binario. Nada se escapa.
- Anclajes: personajes y props, pies abajo-centro. Vehículos, centro geométrico. Tiles, esquina superior izquierda.
- Nomenclatura: `categoria_sujeto_variante_direccion_frame`
  Ej.: `char_ertzaina_andar_der_02`, `veh_patrulla_rotativo_a`, `tile_acera_adoquin`.

---

## 12. Lecciones de las referencias

Las láminas que pasaste son rips de juegos comerciales, así que **no se copia ni un píxel**: el arte de
Bilbo City sigue siendo propio. Lo que sí se hace es estudiar cómo resolvieron los problemas y aplicar
esas soluciones. Esto es lo que salió del análisis.

### 12.1 Hojas de personaje de portátil → **8 direcciones, no 4**

La lección más cara y la más importante. Los personajes de los GTA portátiles no tienen 4 orientaciones,
tienen 8, y por eso al andar en diagonal el muñeco no "patina" mirando a otro lado. También se ve que
cada arma tiene su propio juego direccional y sus propios fogonazos, no un fogonazo genérico.

**Aplicado:** el sistema de capas pasa a 8 direcciones. Las diagonales se resuelven como vista lateral
con pista de cara o de cogote, que es exactamente el truco que permite que un sprite de 20 px lea bien.
De 1.680 a 3.360 fotogramas de personaje. Las armas en mano pasan igual a 8 direcciones.

### 12.2 Vista lateral verdadera

Comparando con las referencias detecté que mis perfiles estaban mal: de lado se veían casi igual que
de frente, con los dos brazos y el torso a la misma anchura.

**Aplicado:** de perfil el torso se estrecha 2 px, solo se dibuja el brazo cercano y las piernas se
solapan con la trasera más oscura. Ahora la silueta cambia de verdad al girar.

### 12.3 Fuente de mapa de bits del HUD

En los HUD clásicos el texto no es una fuente del sistema: es un tipo de bits con bisel y contorno.
Es la mitad de la personalidad de la interfaz.

**Aplicado:** fuente propia de 5×7 con contorno oscuro y degradado vertical de tres tonos.
56 glifos: mayúsculas, cifras, signos, símbolo de euro, vocales acentuadas y eñe.

### 12.4 Marcadores como flechas, no como círculos

Los marcadores de objetivo son flechas de colores colgando sobre el mundo, no anillos pintados en el
suelo. Se leen mejor con la cámara en movimiento y a plena luz.

**Aplicado:** flecha colgante en 8 colores por tipo de destino y flecha de brújula en 8 direcciones,
rellenadas por test de polígono para que no queden dientes.

### 12.5 Fogonazos por calibre

Cada arma dispara un cono distinto: la pistola una chispa corta, la escopeta un abanico ancho.

**Aplicado:** 3 calibres × 8 direcciones = 24 fogonazos, con núcleo blanco, cuerpo ámbar y borde rojo.

### 12.6 Pendiente: geometría urbana irregular

Los mapas de referencia enseñan lo que a Bilbo City todavía le falta: las manzanas **no son un damero**.
Hay plantas en L y en U, patios interiores, tiras largas de nave industrial, calles que no cierran y
costa en diagonal. Además cada ciudad tiene un tinte de color unificado que la identifica de un vistazo.

**Hecho (lote 11):** la ciudad se genera por subdivisión binaria con cortes aleatorios, así que las
manzanas salen de tamaños distintos. Cada una elige planta: llena, en L, en U, con patio interior,
nave industrial con explanada, plaza o parque. Los edificios contiguos se agrupan y se les pinta
contorno y sombra proyectada sobre la calle, así se leen como bloques enteros y no como casillas.
16 distritos con su propio tamaño de manzana, ancho de calle, pavimento y tinte de color.
Medido en tres partidas: entre 64 y 77 bloques por ciudad, mediana de 45-63 casillas, ninguno igual.

### 12.7 Pendiente: HUD de portátil

Radar circular con la salud como anillo alrededor, estrellas arriba a la derecha, arma y munición en
esquina. Y una regla de contraste: la ciudad va apagada para que el fuego y la sangre destaquen.

**Hecho (lote 12):** radar circular con el anillo de salud alrededor, flecha de brújula pegada al borde
apuntando al objetivo, estrellas de búsqueda, cartera con icono, reloj y día, barras de energía y hambre,
panel de misión, arma con munición. Todo el texto del HUD usa la fuente de bits propia dibujada en canvas.

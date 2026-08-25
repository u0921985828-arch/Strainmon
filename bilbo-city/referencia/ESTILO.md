# Bilbo City · guía de estilo

Una sola estética para todo: ciudad, personajes, coches, iconos, tipografía y menús. Lo
que sigue no es una lista de gustos, es lo que ya hace el juego, escrito para que no se
vaya. Lo marcado **[V]** lo comprueba `node herramientas/html/estilo.js` y falla si se
incumple; lo demás se respeta a mano.

## La idea

Bilbao a finales de los noventa, vista desde arriba y algo escorada, en pixel art de
16 bits con pocos colores y mucha suciedad. Gris hormigón, óxido, verde de ladera y
ámbar de farola. Nada brillante, nada redondeado, nada de degradados suaves.

## Rejilla y proporciones

| | Medida | Por qué |
|---|---|---|
| Casilla del mundo | **64×64 px** **[V]** | 5,16 m de Bilbao, o sea **0,081 m por píxel**. Era de 32 y se dobló: a 32, una persona a escala real mide 3 px de hombros y ahí no cabe un personaje, así que el juego arrastraba una sobreescala de ×2,5 en la gente y ×2,1 en los coches que se veía a simple vista. Doblar la casilla no cuesta campo de visión —la cámara enseña 13,5 casillas pase lo que pase— pero **pide el doble de píxeles de pantalla**, porque el zoom es entero y no baja de 1. |
| Persona | **30×39 px** **[V]** | La geometría se sigue escribiendo en 20×26 y se forja a **escala 3:2** (`PJ_N`/`PJ_D`): escala la coordenada, no el dibujo, así que lo que iba pegado sigue pegado. Con la casilla a 64 px son **3,14 m de alto, ×1,85** sobre una persona de verdad. Cabeza ≈ 1/3,25 de la altura; se probó a 1/2,6 y se descartó, que a esa proporción se lee de juguete. |
| Celda del personaje | **36×48 px** **[V]** | Es la de 24×32 de CONTEXT.md §18.1 forjada a escala 3:2, con el pivote en (18,45). La figura mide 30×39; el margen sigue siendo el de siempre —2 a los lados, 5 arriba, 1 abajo— también escalado. Ahí caben el puñetazo, el fogonazo, el casco de obra y el contorno. |
| Icono de interfaz | **24×24 px** **[V]** | 22×22 de dibujo y 1 px de aire alrededor para el contorno. |
| Vehículo | largo 26–44, ancho 15–21 | Un utilitario cabe en una calle de 2 casillas; la furgoneta no. |
| Hoja de personaje | **8 columnas × 16 filas** **[V]** | 8 direcciones × 16 poses. Una hoja por arquetipo. |

Todas las medidas son **pares**: si no, no hay centro y el sprite baila medio píxel al
girar.

## Vista y volumen

Cenital escorada: se ve la tapa del objeto y un poco de su cara frontal. El suelo es
plano; todo lo que sobresale lleva **2–3 px de canto** por abajo.

**La luz viene siempre de arriba a la izquierda.** Sin excepción: una farola iluminada por
la derecha en medio de una acera iluminada por la izquierda se nota aunque no se sepa por
qué. En la práctica:

- 1 px claro en el borde de arriba **y en el de la izquierda**,
- el color base en el cuerpo,
- 1–2 px oscuros abajo y a la derecha.

**Y lo que tapa, ensombrece.** Tres tonos puestos uno al lado del otro no son volumen: lo
que hace que una cosa esté *delante* de otra es la sombra que le proyecta encima. La
barbilla ensombrece el pecho y el dobladillo la pernera. Sin eso la cabeza y el torso son
dos manchas pegadas.

## Color

- **61 colores y ninguno más** **[V]**. Están en `C` (prototipo) y `Paleta` (Unity). Todo
  sprite pasa por `cuantizar` / `Paleta.Cuantizar`.
- Cada material tiene su terna base / oscuro / claro: `piel1..6`, `madera/maderaO/maderaL`,
  `acero/aceroO`, `hormigon/hormigonO/hormigonL`. Úsalas; no mezcles el gris del asfalto
  con el del hormigón.
- **Máximo 6 colores por icono** **[V]**, contorno incluido. A 24 px, más colores es ruido.
- **Nada a medio transparente** **[V]**: un píxel está o no está. El alfa intermedio es de
  otro tipo de juego y en pixel art ensucia el borde.

### Qué significa cada color en la interfaz

| Color | Para qué |
|---|---|
| **Ámbar** (`mostaza`) | Lo importante y el dinero. Un solo ámbar por pantalla manda. |
| **Óxido** (`rojoO`) | Acento y sombra de la letra ámbar. |
| **Acero** (`acero`) | Texto secundario, lo que se lee después. |
| **Verde** | Curro legal. |
| **Morado** | Curro turbio. |
| **Sangre** | Peligro, daño, policía. |

## Contorno

- **Los iconos llevan contorno negro de 1 px** **[V]**, sin excepción: caen sobre la caja
  oscura del HUD, sobre la fila del móvil y sobre el marco claro de la tienda, y sin borde
  la mitad desaparecen contra el fondo. Lo pone `contorno()` / `Lienzo.Contorno()`, no se
  dibuja a mano.
- **Los tiles de suelo no llevan contorno**: se vería la rejilla de la ciudad.
- **Los tiles de suelo no llevan ni un píxel transparente** **[V]**. Por un agujero se ve
  el negro del fondo y aparece una trama de puntos por todo el mapa. Los muebles de
  interior sí son transparentes —van encima del suelo— y están declarados en
  `TILE_MUEBLE`.
- **La silueta va achaflanada, sin esquinas de noventa grados** **[V]**. Todo lo que
  dibuja la forja son rectángulos —`P()` no sabe hacer otra cosa— y a 26 píxeles la suma
  de rectángulos se lee como un montón de cajas apiladas. `chaflan()` / `Lienzo.Chaflan()`
  quita el píxel de cada esquina convexa **antes** del contorno, y el cráneo, el hombro y
  la puntera dejan de ser cantos rectos. Va apretado a propósito —los dos vecinos de fuera
  transparentes y los dos de dentro opacos— porque con la condición suelta se come entero
  un detalle de un píxel de ancho, como la correa del bolso.
- **Los personajes llevan contorno negro de 1 px en la silueta** **[V]**, no en las
  costuras de la ropa. Por la misma razón que los iconos: la gente cruza del asfalto a la
  acera y de la acera al parque, y una cazadora gris sobre hormigón gris sin borde se
  deshace. Lo pone `contorno()` / `Lienzo.Contorno()` al cerrar el dibujo, igual que en
  los iconos.
- **Ningún fotograma de personaje toca el borde de su celda** **[V]**. Para eso está el
  margen. Lo que se salga se corta en seco y no se nota hasta verlo en marcha: el
  fogonazo salía partido por la mitad y la txapela decapitada, y costó verlo.

## Tipografía

**BLOQUE**: el alfabeto de 5×7 engordado a 6 de ancho, relleno plano y sombra dura de
1 px abajo a la derecha. Se eligió sobre otras cinco (`node herramientas/html/fuentes.js`
las saca todas en una imagen).

- Escalas **enteras**: 1, 2, 3, 4. Nunca 1,5.
- Avance 7 px por letra, 5 por espacio.
- Todo en **mayúsculas** en el HUD y en los rótulos.
- La sombra va en un color de la paleta, **no en negro**: sobre las cajas oscuras del HUD
  el negro no se ve y la letra se queda plana.

Al dibujar letras nuevas, dos trampas ya pisadas: engordar entera la primera y la última
fila para simular una serifa **pega los trazos** y la M sale un borrón —hay que detectar
qué columnas son asta y ponerles pie solo a ellas—; y un halo de 2 px junta unas letras
con otras hasta no poder leerlas.

## Interfaz

- **Rejilla de 4 px.** Márgenes, separaciones y alturas, múltiplos de 4.
- **Bordes de 2 px.** Nada de 1 px: a la resolución de un móvil desaparece.
- La barra de color a la izquierda de cada fila mide **5 px** y dice de qué tipo es.
- El icono va en un **hueco hundido** de 30×30, como una casilla de inventario.
- **Los menús viven dentro de la pantalla**, no encima de todo: el marco de la consola
  nunca se tapa, o se pierde la ilusión de estar mirando un cacharro.
- Los paneles llevan **rayas de tubo** finas. Dan la misma materia que la pantalla del
  juego. La pestaña encendida va por encima de ellas: rayada parece deshabilitada.
- Nada de emoji del sistema. Cada móvil los dibuja a su manera, no están en la paleta y al
  lado del pixel art cantan.

## El mando

La pantalla en medio y los mandos en el marco, a los lados. Joystick con SEL y OPT a la
izquierda; A y B con el cambio de arma a la derecha. Los botones son **redondos y de
hueso**, con el hundido en negro: plástico de consola de bolsillo, no cristal.

## Animación

- 4 fotogramas para andar y 4 para correr, a 7,5 y 11 por segundo.
- **Los fotogramas se cambian, no se mezclan.** Ninguna interpolación, ninguna
  transparencia animada.
- Un objeto que parpadea lo hace a cortes, no con un desvanecido.

## Al añadir arte nuevo

1. Dibújalo por código, en la paleta, con la luz desde arriba a la izquierda.
2. Si va sobre fondo variable, pásalo por `contorno()`.
3. `node herramientas/html/estilo.js` — tiene que salir en verde.
4. `node herramientas/html/iconos.js` y míralo al lado de los demás. Un icono a 24 px se
   dibuja a ciegas: hay que verlo grande para juzgar el dibujo y pequeño para saber si de
   verdad se distingue.

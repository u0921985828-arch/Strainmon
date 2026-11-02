# Las siete fuentes que mandó el usuario: qué dice la licencia de cada una

Análisis hecho con los metadatos del propio archivo (`name` del TTF) y los readme que traían.
**Ninguna se ha modificado ni se ha calcado**: modificar un archivo de fuente con copyright crea una
obra derivada, que sigue infringiendo (regla de `CLAUDE.md`). Solo sirvieron de referencia de estilo
para dibujar una fuente propia, `Ribera Pixel`.

| Fuente | Autor | Licencia del archivo | ¿Sirve para el juego? |
| --- | --- | --- | --- |
| Good Old DOS (5 variantes) | Vasily Draigo, 2022 | **SIL OFL 1.1** | **Sí**: libre, comercial y modificable (cambiando el nombre). La única de las siete que se podría usar o derivar. |
| incredible soups | beetleology (FontStruct), 2021 | FontStruct **Non-Commercial** | No: prohíbe el uso comercial. Además no trae ñ ni vocales acentuadas. |
| Kemco Pixel Bold | Jayvee D. Enaguas, 2012 | **CC BY-NC-SA 3.0** | No: prohíbe el uso comercial. Solo mayúsculas, sin ñ ni acentos. |
| Parisienne | Jeffrey Visser (FontStruct), 2015 | **CC BY-NC-ND 3.0** | No, por partida doble: ni comercial **ni obras derivadas**. |
| Super Smash TV | johndoo (FontStruct), 2015 | FontStruct **Non-Commercial** | No: prohíbe el uso comercial. Solo mayúsculas, sin acentos. |
| Token | Koen Hachmang, 1999 | «Freeware… all rights reserved»; pide donación para uso comercial | No: sin licencia escrita que permita modificarla ni redistribuirla. |
| Unscreen MK | Manfred Klein, 2002 | «all rights reserved», sin texto de licencia en el archivo | No: no hay permiso comprobable de modificación ni de redistribución. |

Dos avisos más, fuera de la licencia: «Kemco» y «Smash TV» son marcas de empresas de videojuegos, así
que ni el nombre ni nada que lo evoque entran en el juego.

## Lo que se hizo en su lugar

`Ribera Pixel` (`tools/fuente/ribera_pixel.py` + `glifos_*.py`): 138 glifos dibujados píxel a píxel,
con todo el español (ñÑ, vocales acentuadas, diéresis, ¿¡, «»), las cifras, los signos y los símbolos
que usa el juego (€, ·, ▲▼◀▶, ★, ≈, →, …). Copyright de WolfCade, sin ninguna deuda con nadie.

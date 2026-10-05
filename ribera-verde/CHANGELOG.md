# Cambios

## 1.1.0 · 5 de octubre de 2026

- **Arreglado:** los cruces sin receta fallaban. Se gastaban las semillas y no salía el híbrido propio.
- **Arreglado:** las redadas no podían ocurrir porque el calor bajaba antes de comprobarse. Ahora saltan con calor ≥ 90 al empezar el día.
- **Arreglado:** el capítulo 5 no empezaba si la 8.ª variedad llegaba por un regalo (abuela Txaro) o por un arbusto, hasta la siguiente cosecha, venta o cruce.
- **Arreglado:** no se podía hablar con Josune, la camarera, porque quedaba detrás de dos taburetes. Ahora está en (2,2).
- **Ajuste:** los ladrones de capítulos altos ganaban casi siempre. Ahora tienen vida `12 + 2 × cap. + 0…4` y daño `2 + cap./4` a `4 + cap./2`, y cada ladrón vencido sube +2 la VIDA máxima (tope 60).
- **Nuevo:** código separado en 16 módulos (`src/js`) con build reproducible, `index.html` jugable sin conexión con las fuentes incrustadas, test automático de la historia completa (34 pasos), generador de documentación, capturas y documentación de diseño, guion, genética, mapa y sprites.

## 1.0.0 · 5 de octubre de 2026

- Primera versión, publicada como Artifact de Claude.

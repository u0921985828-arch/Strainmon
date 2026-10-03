---
description: Renderiza el plano de la ciudad y comprueba que Bilbao sigue en pie
---

Ejecuta `node herramientas/html/plano.js`, mira el PNG que genera y compáralo con
`referencia/capturas/plano-bilbo.png`.

Comprueba y dime:
- ¿Se sigue reconociendo el arco de la ría, con el vértice arriba en el centro?
- ¿Zorrotzaurre sigue siendo una isla entre la ría y el canal?
- ¿Se ve la diagonal de la Gran Vía con sus dos plazas circulares?
- ¿Está el óvalo de San Mamés?
- Métricas: la calzada debería rondar el 30 % y el edificio el 20 %. Si la calzada se
  dispara, las manzanas se han quedado pequeñas.

Luego pasa `./verificar.sh html`, que mide la conectividad viaria y que los 15 sitios
siguen cayendo en su barrio.

# Ampliar el catálogo de genéticas — propuesta

Hoy hay **104** variedades (`STRAINS` de `datos/datos.json`): 31 landraces, 56 cruces, 17 autoflorecientes
(16 + la Ruderalis). Todas reales: nada inventado, sin criadores ni bancos nombrados.

Lo que pidió el usuario: que la ampliación vaya **con descendencias, selección de madres y cruces de esquejes**,
no solo más nombres en una lista. Así que la propuesta son dos cosas a la vez: **46 variedades nuevas** (→ 150) y
**tres formas nuevas de sacar variedad de lo que ya cultivas**.

## 1. Las tres mecánicas nuevas (el corazón de la ampliación)

| Mecánica | Qué es | Cómo se juega | De dónde sale |
|---|---|---|---|
| **Selección de madre (corte)** | De una planta tuya que haya salido buena, guardas la madre: ese *corte* queda con nombre propio y repite siempre lo mismo. | En el armario de las madres, SELECCIONAR ESTE CORTE: se apunta el fenotipo exacto (% índica, THC, porte, rareza) y cada esqueje sale idéntico. Hasta 4 cortes guardados. | `S.nave.ma` / el armario de casa; nuevo `S.cortes` |
| **Cruce de esquejes (madre × padre clonados)** | Polinizar el clon de una madre con el polen del clon de otra: la línea no se pierde al cosechar. | En la mesa de cruces, con dos esquejes pinchados en el carro, POLINIZAR ENTRE CLONES: semillas F1 de las dos madres guardadas, repetible. | `CARRO` + `mesa de cruces` |
| **Descendencia: F1 → S1, BX, IBL** | Lo que sale de tu propia línea: autopolinización (S1), retrocruce con la madre (BX1/BX2) y línea fijada (IBL en F5). | En el laboratorio del banco de la tía: S1 de una madre seleccionada; BX con la madre del corte; a la F5 la línea pasa a IBL y deja de variar. | `src/bancotia.gd`, `Cultivo.gen_de` |

Con esto, cada partida acaba con **variedades propias con nombre** que no están en la lista de nadie: el jugador
fabrica catálogo. La lista de abajo es el material de partida.

## 2. Landraces que faltan (18)

| id | Nombre | Zona | % índica aprox. | Cómo se consigue |
|---|---|---|---|---|
| `mazar` | Mazar-i-Sharif | Afganistán (Balj) | 100 | banco del PC |
| `balkh` | Balkhi | Afganistán (Balj) | 100 | la caza, invierno |
| `uzbek` | Uzbek | Asia central | 95 | banco del PC |
| `tashkurgan` | Tashkurgan | Afganistán | 100 | la caza, Koldo |
| `parvati` | Parvati | India (Himachal) | 70 | banco del PC |
| `idukki` | Idukki | India (Kerala) | 10 | banco del PC |
| `mysore` | Mysore | India (Karnataka) | 10 | la caza, feria de mayo |
| `sinaloa` | Sinaloa | México | 0 | banco del PC |
| `guerrero` | Guerrero | México | 0 | la caza, Txomin |
| `sanblas` | San Blas | Panamá | 0 | banco del PC |
| `santamarta` | Santa Marta Gold | Colombia | 0 | banco del PC |
| `pernambuco` | Pernambuco | Brasil | 0 | la caza, romería |
| `aceh` | Aceh | Sumatra | 20 | banco del PC |
| `cambodian` | Cambodian | Camboya | 0 | banco del PC |
| `burmese` | Burmese | Birmania | 20 | la caza, Delroy |
| `sierraleona` | Sierra Leone | África occidental | 0 | banco del PC |
| `kilimanjaro` | Kilimanjaro | Tanzania | 0 | la caza, fiestas de agosto |
| `transkei` | Transkei | Sudáfrica | 0 | banco del PC |

## 3. Cortes reales con nombre propio (10) — se *seleccionan*, no se compran

Son fenotipos concretos de variedades que ya están en el juego: salen al seleccionar una madre buena de esa
variedad, con su nombre y sus números fijos. Ninguna se vende en tienda.

| id | Nombre | De qué variedad sale | Qué fija |
|---|---|---|---|
| `chem91` | Chemdawg '91 | `chemdawg` | THC alto, olor a gasolina, porte largo |
| `chemd` | Chemdawg D | `chemdawg` | más rendimiento, menos olor |
| `sourecsd` | Sour Diesel (corte del este) | `dragon` | floración larga, sativa |
| `exoduscheese` | Cheese (corte Exodus) | `cheese` | aroma único, +resina |
| `hazea` | Haze A | `haze` | 16 semanas, sativa pura |
| `hazec` | Haze C | `haze` | más corta, más resinosa |
| `blueberrydj` | Blueberry (selección del criador) | `niebla` | tono morado, dulce |
| `ghostog` | Ghost OG | `afkush` | resinosa, sensible al moho |
| `sfvog` | SFV OG | `afkush` | compacta, potente |
| `skunkrk` | Skunk #1 (selección olorosa) | `ria` | olor máximo, calor de calle ×1,5 |

## 4. Cruces clásicos con linaje publicado (18)

| id | Nombre | Linaje | % índica |
|---|---|---|---|
| `ogkush` | OG Kush | Chemdawg × (Hindu Kush × Lemon Thai) | 55 |
| `bubba` | Bubba Kush | OG Kush × Afghani ≈ | 85 |
| `girlscout` | Cookies | OG Kush × Durban Poison | 60 |
| `sunset` | Sunset Sherbet | Cookies × Pink Panties ≈ | 70 |
| `gelato` | Gelato | Sunset Sherbet × Thin Mint Cookies | 65 |
| `wedding` | Wedding Cake | Cherry Pie × Cookies | 70 |
| `zkittlez` | Zkittlez | Grape Ape × Grapefruit | 65 |
| `gg4` | Original Glue | Chem's Sister × Sour Dubb × Chocolate Diesel | 55 |
| `bruce` | Bruce Banner | OG Kush × Strawberry Diesel | 40 |
| `strawberry` | Strawberry Cough | Strawberry Fields × Haze | 20 |
| `granddaddy` | Granddaddy Purple | Purple Urkle × Big Bud | 85 |
| `cherrypie` | Cherry Pie | Granddaddy Purple × Durban Poison | 55 |
| `durbthai` | Durban × Thai | `durban` × `thai` | 0 |
| `mazarnl` | Mazar × Northern Lights | `mazar` × `nl` | 95 |
| `kerahaze` | Kerala × Haze | `kerala` × `haze` | 10 |
| `transkush` | Transkei × Hindu Kush | `transkei` × `hindu` | 50 |
| `swazihaze` | Swazi × Haze | `swazi` × `haze` | 10 |
| `acapulcoskunk` | Acapulco × Skunk | `acapulco` × `ria` | 35 |

Los seis últimos son **recetas** que se hacen con las landraces nuevas: dan motivo para cazarlas.

## 5. Dónde toca

- `tools/strains_mas.py` → al final de `STRAINS`, `LANDRACES`, `RECIPES`, `DEX` y `FAMILIAS`, **sin mover ni un
  número de los 104 de ahora** (los guardados viejos siguen valiendo).
- `src/cultivo.gd`: `S.cortes`, `corte_pon`/`corte_de`, el S1, el BX y el paso a IBL en la F5.
- `src/granja.gd`: POLINIZAR ENTRE CLONES en la mesa de cruces con dos esquejes.
- `src/bancotia.gd`: el laboratorio hace el S1 y el BX.
- `src/menus.gd`: el RECETARIO de la CannaDex, con las vías nuevas (corte, S1, BX, IBL).
- `tools/caza.py`: las ocho landraces que se cazan.
- Pruebas: `tests/cannadex.gd` (150 y el árbol coherente), `tests/cortes.gd` (nueva), `tests/descendencia.gd`
  (nueva: S1, BX1, BX2, IBL), `tests/caza.gd`.

## 6. Lo que no se hace

- Ni un nombre inventado, ni criadores, ni bancos, ni lemas: los cortes se llaman por lo que son.
- Nada de método, dosis, concentraciones ni reactivos: el laboratorio sigue sin explicar cómo.
- El árbol de generaciones no gana una generación nueva por el S1 ni por el BX: son la misma línea, más fijada.

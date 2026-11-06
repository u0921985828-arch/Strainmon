# Las landraces y los árboles genealógicos

Sacado de `godot/datos/datos.json` con `python3 -I tools/genealogia.py`: **104 variedades** (31 landraces, 56 cruces y 17 autoflorecientes). Nada escrito a mano aquí; si cambia el juego, se vuelve a pasar.

Leyenda: **ind** es el porcentaje índica de verdad (0 = sativa pura, 100 = índica pura), **THC** el techo de la variedad, **flor** las semanas de floración y **res** la resistencia al moho y a las plagas. En los árboles, `·landrace·` marca la hoja: ahí se acaba el linaje.

## 1. Las landraces, por continente

### Asia: el Kush y el Himalaya

| Variedad | ind | THC | flor | res | De dónde es | Cómo se consigue |
|---|--:|--:|--:|--:|---|---|
| **Afghani** | 100 | 16 % | 3 sem | 85 | montañas del norte de Afganistán | lo escondió la tía, banco de la tía |
| **Hindu Kush** | 100 | 18 % | 3 sem | 80 | cordillera del Hindu Kush, entre Afganistán y Pakistán | lo escondió la tía, banco de la tía |
| **Chitral Kush** | 100 | 17 % | 3 sem | 70 | valle de Chitral, Pakistán | banco del PC, lo escondió la tía, banco de la tía |
| **Purple Afghani** | 95 | 18 % | 4 sem | 45 | Afganistán, selección morada | del growshop o de la historia |
| **Kashmiri** | 85 | 15 % | 3 sem | 75 | valle de Cachemira | banco del PC, la caza, banco de la tía |
| **Malana** | 70 | 17 % | 3,5 sem | 70 | valle de Parvati, Himachal Pradesh, India | banco del PC, banco de la tía |
| **Nepalese** | 50 | 16 % | 3,5 sem | 65 | colinas del Himalaya, Nepal | banco del PC, la caza, banco de la tía |

### Asia: el sudeste y la India

| Variedad | ind | THC | flor | res | De dónde es | Cómo se consigue |
|---|--:|--:|--:|--:|---|---|
| **Thai** | 0 | 17 % | 5 sem | 40 | selvas del norte de Tailandia | banco del PC, la caza, banco de la tía |
| **Highland Thai** | 10 | 15 % | 4,5 sem | 50 | montañas del norte de Tailandia | banco del PC, la caza, banco de la tía |
| **Chocolate Thai** | 0 | 16 % | 5 sem | 40 | Tailandia | lo escondió la tía, banco de la tía |
| **Luang Prabang** | 0 | 15 % | 4,5 sem | 50 | montes del norte de Laos | lo escondió la tía, banco de la tía |
| **Vietnamese Black** | 20 | 15 % | 5 sem | 55 | montes de Vietnam | banco del PC, la caza, banco de la tía |
| **Kerala** | 10 | 16 % | 5 sem | 50 | sierras de Kerala, India del Sur | lo escondió la tía, banco de la tía |

### África y el Mediterráneo

| Variedad | ind | THC | flor | res | De dónde es | Cómo se consigue |
|---|--:|--:|--:|--:|---|---|
| **Kif** | 80 | 13 % | 3 sem | 80 | montañas del Rif, Marruecos | banco del PC, la caza, banco de la tía |
| **Beldia** | 80 | 12 % | 3 sem | 75 | Ketama, en el Rif | banco del PC, la caza, banco de la tía |
| **Lebanese** | 85 | 14 % | 3 sem | 75 | valle de la Bekaa, Líbano | banco del PC, la caza, banco de la tía |
| **Congolese** | 0 | 16 % | 3,5 sem | 55 | cuenca del Congo | banco del PC, la caza, banco de la tía |
| **Malawi Gold** | 0 | 20 % | 5 sem | 55 | sativa de África oriental, floración muy larga | lo escondió la tía, banco de la tía |
| **Swazi Gold** | 10 | 16 % | 4 sem | 60 | montes de Esuatini (Suazilandia) | banco del PC, la caza, banco de la tía |
| **Durban Poison** | 0 | 18 % | 3,5 sem | 65 | puerto de Durban, Sudáfrica | banco del PC, la caza, banco de la tía |
| **Ethiopian Highland** | 10 | 14 % | 4 sem | 60 | tierras altas de Etiopía | banco del PC, la caza, banco de la tía |

### América

| Variedad | ind | THC | flor | res | De dónde es | Cómo se consigue |
|---|--:|--:|--:|--:|---|---|
| **Acapulco Gold** | 0 | 19 % | 4,5 sem | 60 | costa de Guerrero, México | lo escondió la tía, banco de la tía |
| **Highland Oaxacan Gold** | 0 | 15 % | 4 sem | 65 | sierra de Oaxaca, México | lo escondió la tía, banco de la tía |
| **Michoacán** | 0 | 15 % | 4 sem | 55 | altiplano de Michoacán, México | banco del PC, la caza, banco de la tía |
| **Punto Rojo** | 0 | 16 % | 4,5 sem | 45 | cordillera de Colombia | banco del PC, la caza, banco de la tía |
| **Colombian Gold** | 0 | 16 % | 4,5 sem | 55 | sierra de Santa Marta, Colombia | banco del PC, la caza, banco de la tía |
| **Panama Red** | 0 | 17 % | 4,5 sem | 50 | istmo de Panamá | banco del PC, la caza, banco de la tía |
| **Manga Rosa** | 5 | 15 % | 4,5 sem | 55 | nordeste de Brasil | lo escondió la tía, banco de la tía |

### Islas

| Variedad | ind | THC | flor | res | De dónde es | Cómo se consigue |
|---|--:|--:|--:|--:|---|---|
| **Hawaiian** | 20 | 15 % | 4 sem | 55 | islas de Hawái | lo escondió la tía, banco de la tía |
| **Lamb's Bread** | 0 | 16 % | 4 sem | 60 | costa de Jamaica | lo escondió la tía, banco de la tía |
| **Zamal** | 0 | 15 % | 5 sem | 50 | isla de la Reunión | banco del PC, la caza, banco de la tía |

La Ruderalis va aparte: es landrace de Rusia y Asia central, florece por la edad y de ella salen las 17 autoflorecientes.

## 2. Los árboles genealógicos

Cada variedad que no es landrace, con su linaje hacia atrás hasta las landraces. Cuando tiene más de una receta, se listan todas (en el juego vale cualquiera).

### 1.ª generación (16)

**Skunk #1** — ind 65 · THC 12 % · flor 2,5 sem · Las del olor fuerte

    Skunk #1
       ├─ Acapulco Gold ·landrace·
       ├─ Colombian Gold ·landrace·
       └─ Afghani ·landrace·

> Afghani × Colombian Gold × Acapulco Gold

**Kali Mist** — ind 10 · THC 18 % · flor 4 sem · Las de Asia

    Kali Mist

> sativa asiática · ≈ origen incierto (padres sin publicar)

**California Orange** — ind 40 · THC 16 % · flor 3 sem · La leyenda

    California Orange

> Híbrido de California de los setenta

**Chemdawg** — ind 45 · THC 22 % · flor 3,5 sem · La leyenda

    Chemdawg

> Híbrido de los noventa · ≈ origen incierto

**Haze** — ind 10 · THC 20 % · flor 5 sem · Las Haze

    Haze
    ├ receta 1: Punto Rojo × Thai
    │  ├─ Punto Rojo ·landrace·
    │  └─ Thai ·landrace·
    ├ receta 2: Michoacán × Thai
    │  ├─ Michoacán ·landrace·
    │  └─ Thai ·landrace·
    ├ receta 3: Michoacán × Punto Rojo × Thai
    │  ├─ Michoacán ·landrace·
    │  ├─ Punto Rojo ·landrace·
    │  └─ Thai ·landrace·
    └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
       ├─ Kerala ·landrace·
       ├─ Michoacán ·landrace·
       ├─ Punto Rojo ·landrace·
       └─ Thai ·landrace·

> Colombia × México × Tailandia (quizá India del Sur) · ≈ origen incierto

**Northern Lights** — ind 90 · THC 18 % · flor 3 sem · Las del norte

    Northern Lights
       ├─ Afghani ·landrace·
       └─ Thai ·landrace·

> Afghani, con algo de Thai · ≈ origen incierto

**Purple Thai** — ind 10 · THC 18 % · flor 4,5 sem · Las de Asia

    Purple Thai
       ├─ Chocolate Thai ·landrace·
       └─ Highland Oaxacan Gold ·landrace·

> Chocolate Thai × Highland Oaxacan Gold

**Trainwreck** — ind 35 · THC 21 % · flor 4 sem · La leyenda

    Trainwreck
       ├─ Michoacán ·landrace·
       ├─ Afghani ·landrace·
       └─ Thai ·landrace·

> Mexicana × Thai × Afghani · ≈ origen incierto

**AK-47** — ind 35 · THC 20 % · flor 3 sem · Las blancas

    AK-47
       ├─ Colombian Gold ·landrace·
       ├─ Michoacán ·landrace·
       ├─ Afghani ·landrace·
       └─ Thai ·landrace·

> Colombiana × mexicana × thai × afgana (1992)

**Laughing Buddha** — ind 20 · THC 19 % · flor 4 sem · Las del norte

    Laughing Buddha
       ├─ Lamb's Bread ·landrace·
       └─ Thai ·landrace·

> Thai × Jamaicana

**Master Kush** — ind 100 · THC 20 % · flor 3 sem · Las del Kush

    Master Kush
       ├─ Chitral Kush ·landrace·
       └─ Hindu Kush ·landrace·

> dos landraces del Hindu Kush · ≈ origen incierto

**Congo × Panama** — ind 0 · THC 18 % · flor 4,5 sem · Las de África

    Congo × Panama
       ├─ Congolese ·landrace·
       └─ Panama Red ·landrace·

> Congolese × Panama Red

**Malawi × Panama** — ind 0 · THC 20 % · flor 5 sem · Las de África

    Malawi × Panama
       ├─ Malawi Gold ·landrace·
       └─ Panama Red ·landrace·

> Malawi Gold × Panama Red

**Malawi × PCK** — ind 40 · THC 19 % · flor 4 sem · Las de África

    Malawi × PCK
       ├─ Chitral Kush ·landrace·
       └─ Malawi Gold ·landrace·

> Malawi Gold × Chitral Kush (PCK)

**White Widow** — ind 60 · THC 20 % · flor 3,5 sem · Las blancas

    White Widow
       ├─ Kerala ·landrace·
       └─ Manga Rosa ·landrace·

> sativa de Brasil × planta resinosa del sur de la India · ≈ origen incierto

**Durban Poison Auto** — ind 0 · THC 15 % · flor 2,5 sem · Las autos

    Durban Poison Auto
       ├─ Durban Poison ·landrace·
       └─ Ruderalis

> Durban Poison × Ruderalis

### 2.ª generación (22)

**Super Skunk** — ind 80 · THC 19 % · flor 2,5 sem · Las del olor fuerte

    Super Skunk
       ├─ Skunk #1
       │  ├─ Acapulco Gold ·landrace·
       │  ├─ Colombian Gold ·landrace·
       │  └─ Afghani ·landrace·
       └─ Afghani ·landrace·

> Skunk #1 × Afghani

**Blueberry** — ind 80 · THC 17 % · flor 3,5 sem · Las del norte

    Blueberry
       ├─ Purple Thai
       │  ├─ Chocolate Thai ·landrace·
       │  └─ Highland Oaxacan Gold ·landrace·
       ├─ Highland Thai ·landrace·
       └─ Afghani ·landrace·

> Purple Thai × Highland Thai × Afghani

**Lemon Skunk** — ind 40 · THC 18 % · flor 3 sem · Las del olor fuerte

    Lemon Skunk

> Selección cítrica de Skunk #1

**Cheese** — ind 60 · THC 17 % · flor 2,5 sem · Las del olor fuerte

    Cheese

> Fenotipo de Skunk #1 (Reino Unido)

**Cannalope Haze** — ind 10 · THC 20 % · flor 3,5 sem · Las Haze

    Cannalope Haze
       ├─ Haze
       │  ├ receta 1: Punto Rojo × Thai
       │  │  ├─ Punto Rojo ·landrace·
       │  │  └─ Thai ·landrace·
       │  ├ receta 2: Michoacán × Thai
       │  │  ├─ Michoacán ·landrace·
       │  │  └─ Thai ·landrace·
       │  ├ receta 3: Michoacán × Punto Rojo × Thai
       │  │  ├─ Michoacán ·landrace·
       │  │  ├─ Punto Rojo ·landrace·
       │  │  └─ Thai ·landrace·
       │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
       │  ├─ Kerala ·landrace·
       │  ├─ Michoacán ·landrace·
       │  ├─ Punto Rojo ·landrace·
       │  └─ Thai ·landrace·
       └─ Michoacán ·landrace·

> Haze × Michoacán

**Purple Kush** — ind 100 · THC 22 % · flor 3,5 sem · Las del Kush

    Purple Kush
       ├─ Hindu Kush ·landrace·
       └─ Purple Afghani ·landrace·

> Hindu Kush × Purple Afghani · ≈ origen incierto

**Critical Mass** — ind 80 · THC 21 % · flor 3 sem · Las del olor fuerte

    Critical Mass
       ├─ Afghani ·landrace·
       └─ Skunk #1
          ├─ Acapulco Gold ·landrace·
          ├─ Colombian Gold ·landrace·
          └─ Afghani ·landrace·

> Afghani × Skunk #1

**Shiva Skunk** — ind 80 · THC 19 % · flor 3 sem · Las del olor fuerte

    Shiva Skunk
       ├─ Northern Lights
       │  ├─ Afghani ·landrace·
       │  └─ Thai ·landrace·
       └─ Skunk #1
          ├─ Acapulco Gold ·landrace·
          ├─ Colombian Gold ·landrace·
          └─ Afghani ·landrace·

> Skunk #1 × Northern Lights

**NL5 × Haze** — ind 40 · THC 21 % · flor 4 sem · Las Haze

    NL5 × Haze
       ├─ Northern Lights
       │  ├─ Afghani ·landrace·
       │  └─ Thai ·landrace·
       └─ Haze
          ├ receta 1: Punto Rojo × Thai
          │  ├─ Punto Rojo ·landrace·
          │  └─ Thai ·landrace·
          ├ receta 2: Michoacán × Thai
          │  ├─ Michoacán ·landrace·
          │  └─ Thai ·landrace·
          ├ receta 3: Michoacán × Punto Rojo × Thai
          │  ├─ Michoacán ·landrace·
          │  ├─ Punto Rojo ·landrace·
          │  └─ Thai ·landrace·
          └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
          ├─ Kerala ·landrace·
          ├─ Michoacán ·landrace·
          ├─ Punto Rojo ·landrace·
          └─ Thai ·landrace·

> Northern Lights × Haze

**Silver Haze** — ind 35 · THC 21 % · flor 4,5 sem · Las Haze

    Silver Haze
       ├─ Haze
       │  ├ receta 1: Punto Rojo × Thai
       │  │  ├─ Punto Rojo ·landrace·
       │  │  └─ Thai ·landrace·
       │  ├ receta 2: Michoacán × Thai
       │  │  ├─ Michoacán ·landrace·
       │  │  └─ Thai ·landrace·
       │  ├ receta 3: Michoacán × Punto Rojo × Thai
       │  │  ├─ Michoacán ·landrace·
       │  │  ├─ Punto Rojo ·landrace·
       │  │  └─ Thai ·landrace·
       │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
       │  ├─ Kerala ·landrace·
       │  ├─ Michoacán ·landrace·
       │  ├─ Punto Rojo ·landrace·
       │  └─ Thai ·landrace·
       └─ Northern Lights
          ├─ Afghani ·landrace·
          └─ Thai ·landrace·

> Haze × Northern Lights · ≈ origen incierto

**Pineapple Express** — ind 40 · THC 21 % · flor 3,5 sem · La leyenda

    Pineapple Express
       ├─ Hawaiian ·landrace·
       └─ Trainwreck
          ├─ Michoacán ·landrace·
          ├─ Afghani ·landrace·
          └─ Thai ·landrace·

> Trainwreck × Hawaiian · ≈ origen incierto

**Tangie** — ind 30 · THC 20 % · flor 3,5 sem · La leyenda

    Tangie
       ├─ California Orange
       └─ Skunk #1
          ├─ Acapulco Gold ·landrace·
          ├─ Colombian Gold ·landrace·
          └─ Afghani ·landrace·

> California Orange × Skunk #1

**Amnesia Haze** — ind 20 · THC 26 % · flor 4,5 sem · Las Haze

    Amnesia Haze
    ├ receta 1: Haze × Lamb's Bread × Luang Prabang × Afghani
    │  ├─ Haze
    │  │  ├ receta 1: Punto Rojo × Thai
    │  │  │  ├─ Punto Rojo ·landrace·
    │  │  │  └─ Thai ·landrace·
    │  │  ├ receta 2: Michoacán × Thai
    │  │  │  ├─ Michoacán ·landrace·
    │  │  │  └─ Thai ·landrace·
    │  │  ├ receta 3: Michoacán × Punto Rojo × Thai
    │  │  │  ├─ Michoacán ·landrace·
    │  │  │  ├─ Punto Rojo ·landrace·
    │  │  │  └─ Thai ·landrace·
    │  │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
    │  │  ├─ Kerala ·landrace·
    │  │  ├─ Michoacán ·landrace·
    │  │  ├─ Punto Rojo ·landrace·
    │  │  └─ Thai ·landrace·
    │  ├─ Lamb's Bread ·landrace·
    │  ├─ Luang Prabang ·landrace·
    │  └─ Afghani ·landrace·
    └ receta 2: Hawaiian × Haze × Lamb's Bread × Luang Prabang
       ├─ Hawaiian ·landrace·
       ├─ Haze
       │  ├ receta 1: Punto Rojo × Thai
       │  │  ├─ Punto Rojo ·landrace·
       │  │  └─ Thai ·landrace·
       │  ├ receta 2: Michoacán × Thai
       │  │  ├─ Michoacán ·landrace·
       │  │  └─ Thai ·landrace·
       │  ├ receta 3: Michoacán × Punto Rojo × Thai
       │  │  ├─ Michoacán ·landrace·
       │  │  ├─ Punto Rojo ·landrace·
       │  │  └─ Thai ·landrace·
       │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
       │  ├─ Kerala ·landrace·
       │  ├─ Michoacán ·landrace·
       │  ├─ Punto Rojo ·landrace·
       │  └─ Thai ·landrace·
       ├─ Lamb's Bread ·landrace·
       └─ Luang Prabang ·landrace·

> Haze + jamaicana + afgana o hawaiana + Laos · ≈ origen incierto

**Purple Haze** — ind 15 · THC 19 % · flor 4,5 sem · Las Haze

    Purple Haze
       ├─ Purple Thai
       │  ├─ Chocolate Thai ·landrace·
       │  └─ Highland Oaxacan Gold ·landrace·
       └─ Haze
          ├ receta 1: Punto Rojo × Thai
          │  ├─ Punto Rojo ·landrace·
          │  └─ Thai ·landrace·
          ├ receta 2: Michoacán × Thai
          │  ├─ Michoacán ·landrace·
          │  └─ Thai ·landrace·
          ├ receta 3: Michoacán × Punto Rojo × Thai
          │  ├─ Michoacán ·landrace·
          │  ├─ Punto Rojo ·landrace·
          │  └─ Thai ·landrace·
          └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
          ├─ Kerala ·landrace·
          ├─ Michoacán ·landrace·
          ├─ Punto Rojo ·landrace·
          └─ Thai ·landrace·

> Purple Thai × Haze · ≈ origen incierto

**White Russian** — ind 60 · THC 22 % · flor 3,5 sem · Las blancas

    White Russian
       ├─ AK-47
       │  ├─ Colombian Gold ·landrace·
       │  ├─ Michoacán ·landrace·
       │  ├─ Afghani ·landrace·
       │  └─ Thai ·landrace·
       └─ White Widow
          ├─ Kerala ·landrace·
          └─ Manga Rosa ·landrace·

> White Widow × AK-47

**White Rhino** — ind 80 · THC 20 % · flor 3,5 sem · Las blancas

    White Rhino
       ├─ Afghani ·landrace·
       └─ White Widow
          ├─ Kerala ·landrace·
          └─ Manga Rosa ·landrace·

> White Widow × índica norteamericana · ≈ origen incierto

**Lowryder** — ind 55 · THC 12 % · flor 1,5 sem · Las autos

    Lowryder
       ├─ Michoacán ·landrace·
       ├─ Northern Lights
       │  ├─ Afghani ·landrace·
       │  └─ Thai ·landrace·
       └─ Ruderalis

> Northern Lights × ruderalis mexicana · ≈ origen incierto

**Northern Lights Auto** — ind 90 · THC 15 % · flor 2,0 sem · Las autos

    Northern Lights Auto
       ├─ Northern Lights
       │  ├─ Afghani ·landrace·
       │  └─ Thai ·landrace·
       └─ Ruderalis

> Northern Lights × Ruderalis

**White Widow Auto** — ind 60 · THC 17 % · flor 2,5 sem · Las autos

    White Widow Auto
       ├─ Ruderalis
       └─ White Widow
          ├─ Kerala ·landrace·
          └─ Manga Rosa ·landrace·

> White Widow × Ruderalis

**AK-47 Auto** — ind 35 · THC 17 % · flor 2,0 sem · Las autos

    AK-47 Auto
       ├─ AK-47
       │  ├─ Colombian Gold ·landrace·
       │  ├─ Michoacán ·landrace·
       │  ├─ Afghani ·landrace·
       │  └─ Thai ·landrace·
       └─ Ruderalis

> AK-47 × Ruderalis

**Skunk #1 Auto** — ind 65 · THC 10 % · flor 2,0 sem · Las autos

    Skunk #1 Auto
       ├─ Skunk #1
       │  ├─ Acapulco Gold ·landrace·
       │  ├─ Colombian Gold ·landrace·
       │  └─ Afghani ·landrace·
       └─ Ruderalis

> Skunk #1 × Ruderalis

**Purple Kush Auto** — ind 100 · THC 19 % · flor 2,5 sem · Las autos

    Purple Kush Auto
       ├─ Purple Kush
       │  ├─ Hindu Kush ·landrace·
       │  └─ Purple Afghani ·landrace·
       └─ Ruderalis

> Purple Kush × Ruderalis

### 3.ª generación (22)

**Lemon Haze** — ind 20 · THC 15 % · flor 3,5 sem · Las Haze

    Lemon Haze
       ├─ Lemon Skunk
       └─ Silver Haze
          ├─ Haze
          │  ├ receta 1: Punto Rojo × Thai
          │  │  ├─ Punto Rojo ·landrace·
          │  │  └─ Thai ·landrace·
          │  ├ receta 2: Michoacán × Thai
          │  │  ├─ Michoacán ·landrace·
          │  │  └─ Thai ·landrace·
          │  ├ receta 3: Michoacán × Punto Rojo × Thai
          │  │  ├─ Michoacán ·landrace·
          │  │  ├─ Punto Rojo ·landrace·
          │  │  └─ Thai ·landrace·
          │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
          │  ├─ Kerala ·landrace·
          │  ├─ Michoacán ·landrace·
          │  ├─ Punto Rojo ·landrace·
          │  └─ Thai ·landrace·
          └─ Northern Lights
             ├─ Afghani ·landrace·
             └─ Thai ·landrace·

> Lemon Skunk × Silver Haze · ≈ origen incierto

**Big Bud** — ind 85 · THC 17 % · flor 3 sem · Las del norte

    Big Bud

> base Afghani · ≈ origen incierto

**Neville's Haze** — ind 10 · THC 22 % · flor 4,5 sem · Las Haze

    Neville's Haze
       ├─ Haze
       │  ├ receta 1: Punto Rojo × Thai
       │  │  ├─ Punto Rojo ·landrace·
       │  │  └─ Thai ·landrace·
       │  ├ receta 2: Michoacán × Thai
       │  │  ├─ Michoacán ·landrace·
       │  │  └─ Thai ·landrace·
       │  ├ receta 3: Michoacán × Punto Rojo × Thai
       │  │  ├─ Michoacán ·landrace·
       │  │  ├─ Punto Rojo ·landrace·
       │  │  └─ Thai ·landrace·
       │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
       │  ├─ Kerala ·landrace·
       │  ├─ Michoacán ·landrace·
       │  ├─ Punto Rojo ·landrace·
       │  └─ Thai ·landrace·
       └─ NL5 × Haze
          ├─ Northern Lights
          │  ├─ Afghani ·landrace·
          │  └─ Thai ·landrace·
          └─ Haze
             ├ receta 1: Punto Rojo × Thai
             │  ├─ Punto Rojo ·landrace·
             │  └─ Thai ·landrace·
             ├ receta 2: Michoacán × Thai
             │  ├─ Michoacán ·landrace·
             │  └─ Thai ·landrace·
             ├ receta 3: Michoacán × Punto Rojo × Thai
             │  ├─ Michoacán ·landrace·
             │  ├─ Punto Rojo ·landrace·
             │  └─ Thai ·landrace·
             └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
             ├─ Kerala ·landrace·
             ├─ Michoacán ·landrace·
             ├─ Punto Rojo ·landrace·
             └─ Thai ·landrace·

> Haze × (NL5 × Haze)

**Chocolope** — ind 10 · THC 21 % · flor 4 sem · Las Haze

    Chocolope
       ├─ Cannalope Haze
       │  ├─ Haze
       │  │  ├ receta 1: Punto Rojo × Thai
       │  │  │  ├─ Punto Rojo ·landrace·
       │  │  │  └─ Thai ·landrace·
       │  │  ├ receta 2: Michoacán × Thai
       │  │  │  ├─ Michoacán ·landrace·
       │  │  │  └─ Thai ·landrace·
       │  │  ├ receta 3: Michoacán × Punto Rojo × Thai
       │  │  │  ├─ Michoacán ·landrace·
       │  │  │  ├─ Punto Rojo ·landrace·
       │  │  │  └─ Thai ·landrace·
       │  │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
       │  │  ├─ Kerala ·landrace·
       │  │  ├─ Michoacán ·landrace·
       │  │  ├─ Punto Rojo ·landrace·
       │  │  └─ Thai ·landrace·
       │  └─ Michoacán ·landrace·
       └─ Chocolate Thai ·landrace·

> Chocolate Thai × Cannalope Haze

**Jack Herer** — ind 45 · THC 28 % · flor 3,5 sem · La leyenda

    Jack Herer
       ├─ Haze
       │  ├ receta 1: Punto Rojo × Thai
       │  │  ├─ Punto Rojo ·landrace·
       │  │  └─ Thai ·landrace·
       │  ├ receta 2: Michoacán × Thai
       │  │  ├─ Michoacán ·landrace·
       │  │  └─ Thai ·landrace·
       │  ├ receta 3: Michoacán × Punto Rojo × Thai
       │  │  ├─ Michoacán ·landrace·
       │  │  ├─ Punto Rojo ·landrace·
       │  │  └─ Thai ·landrace·
       │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
       │  ├─ Kerala ·landrace·
       │  ├─ Michoacán ·landrace·
       │  ├─ Punto Rojo ·landrace·
       │  └─ Thai ·landrace·
       ├─ Northern Lights
       │  ├─ Afghani ·landrace·
       │  └─ Thai ·landrace·
       └─ Shiva Skunk
          ├─ Northern Lights
          │  ├─ Afghani ·landrace·
          │  └─ Thai ·landrace·
          └─ Skunk #1
             ├─ Acapulco Gold ·landrace·
             ├─ Colombian Gold ·landrace·
             └─ Afghani ·landrace·

> Haze × (NL5 × Shiva Skunk) · LEGENDARIA

**Super Silver Haze** — ind 20 · THC 23 % · flor 4 sem · Las Haze

    Super Silver Haze
    ├ receta 1: Skunk #1 × Silver Haze
    │  ├─ Skunk #1
    │  │  ├─ Acapulco Gold ·landrace·
    │  │  ├─ Colombian Gold ·landrace·
    │  │  └─ Afghani ·landrace·
    │  └─ Silver Haze
    │     ├─ Haze
    │     │  ├ receta 1: Punto Rojo × Thai
    │     │  │  ├─ Punto Rojo ·landrace·
    │     │  │  └─ Thai ·landrace·
    │     │  ├ receta 2: Michoacán × Thai
    │     │  │  ├─ Michoacán ·landrace·
    │     │  │  └─ Thai ·landrace·
    │     │  ├ receta 3: Michoacán × Punto Rojo × Thai
    │     │  │  ├─ Michoacán ·landrace·
    │     │  │  ├─ Punto Rojo ·landrace·
    │     │  │  └─ Thai ·landrace·
    │     │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
    │     │  ├─ Kerala ·landrace·
    │     │  ├─ Michoacán ·landrace·
    │     │  ├─ Punto Rojo ·landrace·
    │     │  └─ Thai ·landrace·
    │     └─ Northern Lights
    │        ├─ Afghani ·landrace·
    │        └─ Thai ·landrace·
    └ receta 2: Haze × Northern Lights × Skunk #1
       ├─ Haze
       │  ├ receta 1: Punto Rojo × Thai
       │  │  ├─ Punto Rojo ·landrace·
       │  │  └─ Thai ·landrace·
       │  ├ receta 2: Michoacán × Thai
       │  │  ├─ Michoacán ·landrace·
       │  │  └─ Thai ·landrace·
       │  ├ receta 3: Michoacán × Punto Rojo × Thai
       │  │  ├─ Michoacán ·landrace·
       │  │  ├─ Punto Rojo ·landrace·
       │  │  └─ Thai ·landrace·
       │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
       │  ├─ Kerala ·landrace·
       │  ├─ Michoacán ·landrace·
       │  ├─ Punto Rojo ·landrace·
       │  └─ Thai ·landrace·
       ├─ Northern Lights
       │  ├─ Afghani ·landrace·
       │  └─ Thai ·landrace·
       └─ Skunk #1
          ├─ Acapulco Gold ·landrace·
          ├─ Colombian Gold ·landrace·
          └─ Afghani ·landrace·

> Skunk #1 × Northern Lights × Haze

**Blue Dream** — ind 40 · THC 22 % · flor 4 sem · Las del norte

    Blue Dream
       ├─ Haze
       │  ├ receta 1: Punto Rojo × Thai
       │  │  ├─ Punto Rojo ·landrace·
       │  │  └─ Thai ·landrace·
       │  ├ receta 2: Michoacán × Thai
       │  │  ├─ Michoacán ·landrace·
       │  │  └─ Thai ·landrace·
       │  ├ receta 3: Michoacán × Punto Rojo × Thai
       │  │  ├─ Michoacán ·landrace·
       │  │  ├─ Punto Rojo ·landrace·
       │  │  └─ Thai ·landrace·
       │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
       │  ├─ Kerala ·landrace·
       │  ├─ Michoacán ·landrace·
       │  ├─ Punto Rojo ·landrace·
       │  └─ Thai ·landrace·
       └─ Blueberry
          ├─ Purple Thai
          │  ├─ Chocolate Thai ·landrace·
          │  └─ Highland Oaxacan Gold ·landrace·
          ├─ Highland Thai ·landrace·
          └─ Afghani ·landrace·

> Blueberry × Haze

**Blue Cheese** — ind 75 · THC 19 % · flor 3 sem · Las del olor fuerte

    Blue Cheese
       ├─ Cheese
       └─ Blueberry
          ├─ Purple Thai
          │  ├─ Chocolate Thai ·landrace·
          │  └─ Highland Oaxacan Gold ·landrace·
          ├─ Highland Thai ·landrace·
          └─ Afghani ·landrace·

> Blueberry × Cheese

**Sour Diesel** — ind 30 · THC 27 % · flor 4 sem · La leyenda

    Sour Diesel
       ├─ Chemdawg
       └─ Super Skunk
          ├─ Skunk #1
          │  ├─ Acapulco Gold ·landrace·
          │  ├─ Colombian Gold ·landrace·
          │  └─ Afghani ·landrace·
          └─ Afghani ·landrace·

> Chemdawg × Super Skunk · ≈ origen incierto

**Kali 47** — ind 30 · THC 21 % · flor 3,5 sem · Las blancas

    Kali 47
       ├─ AK-47
       │  ├─ Colombian Gold ·landrace·
       │  ├─ Michoacán ·landrace·
       │  ├─ Afghani ·landrace·
       │  └─ Thai ·landrace·
       └─ Kali Mist

> Kali Mist × AK-47

**Critical Kali Mist** — ind 45 · THC 21 % · flor 3,5 sem · Las blancas

    Critical Kali Mist
       ├─ Kali Mist
       └─ Critical Mass
          ├─ Afghani ·landrace·
          └─ Skunk #1
             ├─ Acapulco Gold ·landrace·
             ├─ Colombian Gold ·landrace·
             └─ Afghani ·landrace·

> Critical Mass × Kali Mist

**Blue Widow** — ind 65 · THC 19 % · flor 3,5 sem · Las blancas

    Blue Widow
       ├─ Blueberry
       │  ├─ Purple Thai
       │  │  ├─ Chocolate Thai ·landrace·
       │  │  └─ Highland Oaxacan Gold ·landrace·
       │  ├─ Highland Thai ·landrace·
       │  └─ Afghani ·landrace·
       └─ White Widow
          ├─ Kerala ·landrace·
          └─ Manga Rosa ·landrace·

> Blueberry × White Widow

**Chronic** — ind 70 · THC 20 % · flor 3,5 sem · Las del olor fuerte

    Chronic
    ├ receta 1: AK-47 × Shiva Skunk
    │  ├─ AK-47
    │  │  ├─ Colombian Gold ·landrace·
    │  │  ├─ Michoacán ·landrace·
    │  │  ├─ Afghani ·landrace·
    │  │  └─ Thai ·landrace·
    │  └─ Shiva Skunk
    │     ├─ Northern Lights
    │     │  ├─ Afghani ·landrace·
    │     │  └─ Thai ·landrace·
    │     └─ Skunk #1
    │        ├─ Acapulco Gold ·landrace·
    │        ├─ Colombian Gold ·landrace·
    │        └─ Afghani ·landrace·
    └ receta 2: AK-47 × Northern Lights × Skunk #1
       ├─ AK-47
       │  ├─ Colombian Gold ·landrace·
       │  ├─ Michoacán ·landrace·
       │  ├─ Afghani ·landrace·
       │  └─ Thai ·landrace·
       ├─ Northern Lights
       │  ├─ Afghani ·landrace·
       │  └─ Thai ·landrace·
       └─ Skunk #1
          ├─ Acapulco Gold ·landrace·
          ├─ Colombian Gold ·landrace·
          └─ Afghani ·landrace·

> Skunk #1 × Northern Lights × AK-47

**White Shark** — ind 75 · THC 19 % · flor 3,5 sem · Las blancas

    White Shark
    ├ receta 1: Super Skunk × White Widow
    │  ├─ Super Skunk
    │  │  ├─ Skunk #1
    │  │  │  ├─ Acapulco Gold ·landrace·
    │  │  │  ├─ Colombian Gold ·landrace·
    │  │  │  └─ Afghani ·landrace·
    │  │  └─ Afghani ·landrace·
    │  └─ White Widow
    │     ├─ Kerala ·landrace·
    │     └─ Manga Rosa ·landrace·
    └ receta 2: Kerala × Manga Rosa × Super Skunk
       ├─ Kerala ·landrace·
       ├─ Manga Rosa ·landrace·
       └─ Super Skunk
          ├─ Skunk #1
          │  ├─ Acapulco Gold ·landrace·
          │  ├─ Colombian Gold ·landrace·
          │  └─ Afghani ·landrace·
          └─ Afghani ·landrace·

> Super Skunk × brasileña × India del Sur

**Ice** — ind 80 · THC 20 % · flor 3,5 sem · Las del norte

    Ice
    ├ receta 1: Afghani × Shiva Skunk
    │  ├─ Afghani ·landrace·
    │  └─ Shiva Skunk
    │     ├─ Northern Lights
    │     │  ├─ Afghani ·landrace·
    │     │  └─ Thai ·landrace·
    │     └─ Skunk #1
    │        ├─ Acapulco Gold ·landrace·
    │        ├─ Colombian Gold ·landrace·
    │        └─ Afghani ·landrace·
    └ receta 2: Northern Lights × Skunk #1 × Afghani
       ├─ Northern Lights
       │  ├─ Afghani ·landrace·
       │  └─ Thai ·landrace·
       ├─ Skunk #1
       │  ├─ Acapulco Gold ·landrace·
       │  ├─ Colombian Gold ·landrace·
       │  └─ Afghani ·landrace·
       └─ Afghani ·landrace·

> Afghani × Northern Lights × Shiva Skunk

**Critical 47** — ind 55 · THC 20 % · flor 3 sem · Las del olor fuerte

    Critical 47
       ├─ AK-47
       │  ├─ Colombian Gold ·landrace·
       │  ├─ Michoacán ·landrace·
       │  ├─ Afghani ·landrace·
       │  └─ Thai ·landrace·
       └─ Critical Mass
          ├─ Afghani ·landrace·
          └─ Skunk #1
             ├─ Acapulco Gold ·landrace·
             ├─ Colombian Gold ·landrace·
             └─ Afghani ·landrace·

> Critical × AK-47 · ≈ origen incierto

**Critical Cheese** — ind 70 · THC 19 % · flor 3 sem · Las del olor fuerte

    Critical Cheese
       ├─ Cheese
       └─ Critical Mass
          ├─ Afghani ·landrace·
          └─ Skunk #1
             ├─ Acapulco Gold ·landrace·
             ├─ Colombian Gold ·landrace·
             └─ Afghani ·landrace·

> Critical × Cheese · ≈ origen incierto

**Northern Light Blue** — ind 85 · THC 19 % · flor 3 sem · Las del norte

    Northern Light Blue
       ├─ Blueberry
       │  ├─ Purple Thai
       │  │  ├─ Chocolate Thai ·landrace·
       │  │  └─ Highland Oaxacan Gold ·landrace·
       │  ├─ Highland Thai ·landrace·
       │  └─ Afghani ·landrace·
       └─ Northern Lights
          ├─ Afghani ·landrace·
          └─ Thai ·landrace·

> Northern Lights × Blueberry

**Amnesia Haze Auto** — ind 20 · THC 23 % · flor 3,5 sem · Las autos

    Amnesia Haze Auto
       ├─ Ruderalis
       └─ Amnesia Haze
          ├ receta 1: Haze × Lamb's Bread × Luang Prabang × Afghani
          │  ├─ Haze
          │  │  ├ receta 1: Punto Rojo × Thai
          │  │  │  ├─ Punto Rojo ·landrace·
          │  │  │  └─ Thai ·landrace·
          │  │  ├ receta 2: Michoacán × Thai
          │  │  │  ├─ Michoacán ·landrace·
          │  │  │  └─ Thai ·landrace·
          │  │  ├ receta 3: Michoacán × Punto Rojo × Thai
          │  │  │  ├─ Michoacán ·landrace·
          │  │  │  ├─ Punto Rojo ·landrace·
          │  │  │  └─ Thai ·landrace·
          │  │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
          │  │  ├─ Kerala ·landrace·
          │  │  ├─ Michoacán ·landrace·
          │  │  ├─ Punto Rojo ·landrace·
          │  │  └─ Thai ·landrace·
          │  ├─ Lamb's Bread ·landrace·
          │  ├─ Luang Prabang ·landrace·
          │  └─ Afghani ·landrace·
          └ receta 2: Hawaiian × Haze × Lamb's Bread × Luang Prabang
          ├─ Hawaiian ·landrace·
          ├─ Haze
          │  ├ receta 1: Punto Rojo × Thai
          │  │  ├─ Punto Rojo ·landrace·
          │  │  └─ Thai ·landrace·
          │  ├ receta 2: Michoacán × Thai
          │  │  ├─ Michoacán ·landrace·
          │  │  └─ Thai ·landrace·
          │  ├ receta 3: Michoacán × Punto Rojo × Thai
          │  │  ├─ Michoacán ·landrace·
          │  │  ├─ Punto Rojo ·landrace·
          │  │  └─ Thai ·landrace·
          │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
          │  ├─ Kerala ·landrace·
          │  ├─ Michoacán ·landrace·
          │  ├─ Punto Rojo ·landrace·
          │  └─ Thai ·landrace·
          ├─ Lamb's Bread ·landrace·
          └─ Luang Prabang ·landrace·

> Amnesia Haze × Ruderalis

**Blueberry Auto** — ind 80 · THC 14 % · flor 2,5 sem · Las autos

    Blueberry Auto
       ├─ Blueberry
       │  ├─ Purple Thai
       │  │  ├─ Chocolate Thai ·landrace·
       │  │  └─ Highland Oaxacan Gold ·landrace·
       │  ├─ Highland Thai ·landrace·
       │  └─ Afghani ·landrace·
       └─ Ruderalis

> Blueberry × Ruderalis

**Super Skunk Auto** — ind 80 · THC 16 % · flor 2,0 sem · Las autos

    Super Skunk Auto
       ├─ Ruderalis
       └─ Super Skunk
          ├─ Skunk #1
          │  ├─ Acapulco Gold ·landrace·
          │  ├─ Colombian Gold ·landrace·
          │  └─ Afghani ·landrace·
          └─ Afghani ·landrace·

> Super Skunk × Ruderalis

**Cheese Auto** — ind 60 · THC 14 % · flor 2,0 sem · Las autos

    Cheese Auto
       ├─ Cheese
       └─ Ruderalis

> Cheese × Ruderalis

### 4.ª generación (12)

**Super Lemon Haze** — ind 30 · THC 23 % · flor 4 sem · Las Haze

    Super Lemon Haze
       ├─ Lemon Skunk
       └─ Super Silver Haze
          ├ receta 1: Skunk #1 × Silver Haze
          │  ├─ Skunk #1
          │  │  ├─ Acapulco Gold ·landrace·
          │  │  ├─ Colombian Gold ·landrace·
          │  │  └─ Afghani ·landrace·
          │  └─ Silver Haze
          │     ├─ Haze
          │     │  ├ receta 1: Punto Rojo × Thai
          │     │  │  ├─ Punto Rojo ·landrace·
          │     │  │  └─ Thai ·landrace·
          │     │  ├ receta 2: Michoacán × Thai
          │     │  │  ├─ Michoacán ·landrace·
          │     │  │  └─ Thai ·landrace·
          │     │  ├ receta 3: Michoacán × Punto Rojo × Thai
          │     │  │  ├─ Michoacán ·landrace·
          │     │  │  ├─ Punto Rojo ·landrace·
          │     │  │  └─ Thai ·landrace·
          │     │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
          │     │  ├─ Kerala ·landrace·
          │     │  ├─ Michoacán ·landrace·
          │     │  ├─ Punto Rojo ·landrace·
          │     │  └─ Thai ·landrace·
          │     └─ Northern Lights
          │        ├─ Afghani ·landrace·
          │        └─ Thai ·landrace·
          └ receta 2: Haze × Northern Lights × Skunk #1
          ├─ Haze
          │  ├ receta 1: Punto Rojo × Thai
          │  │  ├─ Punto Rojo ·landrace·
          │  │  └─ Thai ·landrace·
          │  ├ receta 2: Michoacán × Thai
          │  │  ├─ Michoacán ·landrace·
          │  │  └─ Thai ·landrace·
          │  ├ receta 3: Michoacán × Punto Rojo × Thai
          │  │  ├─ Michoacán ·landrace·
          │  │  ├─ Punto Rojo ·landrace·
          │  │  └─ Thai ·landrace·
          │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
          │  ├─ Kerala ·landrace·
          │  ├─ Michoacán ·landrace·
          │  ├─ Punto Rojo ·landrace·
          │  └─ Thai ·landrace·
          ├─ Northern Lights
          │  ├─ Afghani ·landrace·
          │  └─ Thai ·landrace·
          └─ Skunk #1
             ├─ Acapulco Gold ·landrace·
             ├─ Colombian Gold ·landrace·
             └─ Afghani ·landrace·

> Lemon Skunk × Super Silver Haze

**Hawaiian Snow** — ind 10 · THC 22 % · flor 5 sem · Las Haze

    Hawaiian Snow
       ├─ Hawaiian ·landrace·
       ├─ Haze
       │  ├ receta 1: Punto Rojo × Thai
       │  │  ├─ Punto Rojo ·landrace·
       │  │  └─ Thai ·landrace·
       │  ├ receta 2: Michoacán × Thai
       │  │  ├─ Michoacán ·landrace·
       │  │  └─ Thai ·landrace·
       │  ├ receta 3: Michoacán × Punto Rojo × Thai
       │  │  ├─ Michoacán ·landrace·
       │  │  ├─ Punto Rojo ·landrace·
       │  │  └─ Thai ·landrace·
       │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
       │  ├─ Kerala ·landrace·
       │  ├─ Michoacán ·landrace·
       │  ├─ Punto Rojo ·landrace·
       │  └─ Thai ·landrace·
       └─ Neville's Haze
          ├─ Haze
          │  ├ receta 1: Punto Rojo × Thai
          │  │  ├─ Punto Rojo ·landrace·
          │  │  └─ Thai ·landrace·
          │  ├ receta 2: Michoacán × Thai
          │  │  ├─ Michoacán ·landrace·
          │  │  └─ Thai ·landrace·
          │  ├ receta 3: Michoacán × Punto Rojo × Thai
          │  │  ├─ Michoacán ·landrace·
          │  │  ├─ Punto Rojo ·landrace·
          │  │  └─ Thai ·landrace·
          │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
          │  ├─ Kerala ·landrace·
          │  ├─ Michoacán ·landrace·
          │  ├─ Punto Rojo ·landrace·
          │  └─ Thai ·landrace·
          └─ NL5 × Haze
             ├─ Northern Lights
             │  ├─ Afghani ·landrace·
             │  └─ Thai ·landrace·
             └─ Haze
                ├ receta 1: Punto Rojo × Thai
                │  ├─ Punto Rojo ·landrace·
                │  └─ Thai ·landrace·
                ├ receta 2: Michoacán × Thai
                │  ├─ Michoacán ·landrace·
                │  └─ Thai ·landrace·
                ├ receta 3: Michoacán × Punto Rojo × Thai
                │  ├─ Michoacán ·landrace·
                │  ├─ Punto Rojo ·landrace·
                │  └─ Thai ·landrace·
                └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
                ├─ Kerala ·landrace·
                ├─ Michoacán ·landrace·
                ├─ Punto Rojo ·landrace·
                └─ Thai ·landrace·

> Hawaiian Haze × Neville's Haze × Haze

**Jack Flash** — ind 45 · THC 21 % · flor 3,5 sem · La leyenda

    Jack Flash
       ├─ Haze
       │  ├ receta 1: Punto Rojo × Thai
       │  │  ├─ Punto Rojo ·landrace·
       │  │  └─ Thai ·landrace·
       │  ├ receta 2: Michoacán × Thai
       │  │  ├─ Michoacán ·landrace·
       │  │  └─ Thai ·landrace·
       │  ├ receta 3: Michoacán × Punto Rojo × Thai
       │  │  ├─ Michoacán ·landrace·
       │  │  ├─ Punto Rojo ·landrace·
       │  │  └─ Thai ·landrace·
       │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
       │  ├─ Kerala ·landrace·
       │  ├─ Michoacán ·landrace·
       │  ├─ Punto Rojo ·landrace·
       │  └─ Thai ·landrace·
       ├─ Jack Herer
       │  ├─ Haze
       │  │  ├ receta 1: Punto Rojo × Thai
       │  │  │  ├─ Punto Rojo ·landrace·
       │  │  │  └─ Thai ·landrace·
       │  │  ├ receta 2: Michoacán × Thai
       │  │  │  ├─ Michoacán ·landrace·
       │  │  │  └─ Thai ·landrace·
       │  │  ├ receta 3: Michoacán × Punto Rojo × Thai
       │  │  │  ├─ Michoacán ·landrace·
       │  │  │  ├─ Punto Rojo ·landrace·
       │  │  │  └─ Thai ·landrace·
       │  │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
       │  │  ├─ Kerala ·landrace·
       │  │  ├─ Michoacán ·landrace·
       │  │  ├─ Punto Rojo ·landrace·
       │  │  └─ Thai ·landrace·
       │  ├─ Northern Lights
       │  │  ├─ Afghani ·landrace·
       │  │  └─ Thai ·landrace·
       │  └─ Shiva Skunk
       │     ├─ Northern Lights
       │     │  ├─ Afghani ·landrace·
       │     │  └─ Thai ·landrace·
       │     └─ Skunk #1
       │        ├─ Acapulco Gold ·landrace·
       │        ├─ Colombian Gold ·landrace·
       │        └─ Afghani ·landrace·
       └─ Super Skunk
          ├─ Skunk #1
          │  ├─ Acapulco Gold ·landrace·
          │  ├─ Colombian Gold ·landrace·
          │  └─ Afghani ·landrace·
          └─ Afghani ·landrace·

> Jack Herer × Super Skunk × Haze

**Jack 47** — ind 40 · THC 21 % · flor 3,5 sem · La leyenda

    Jack 47
       ├─ AK-47
       │  ├─ Colombian Gold ·landrace·
       │  ├─ Michoacán ·landrace·
       │  ├─ Afghani ·landrace·
       │  └─ Thai ·landrace·
       └─ Jack Herer
          ├─ Haze
          │  ├ receta 1: Punto Rojo × Thai
          │  │  ├─ Punto Rojo ·landrace·
          │  │  └─ Thai ·landrace·
          │  ├ receta 2: Michoacán × Thai
          │  │  ├─ Michoacán ·landrace·
          │  │  └─ Thai ·landrace·
          │  ├ receta 3: Michoacán × Punto Rojo × Thai
          │  │  ├─ Michoacán ·landrace·
          │  │  ├─ Punto Rojo ·landrace·
          │  │  └─ Thai ·landrace·
          │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
          │  ├─ Kerala ·landrace·
          │  ├─ Michoacán ·landrace·
          │  ├─ Punto Rojo ·landrace·
          │  └─ Thai ·landrace·
          ├─ Northern Lights
          │  ├─ Afghani ·landrace·
          │  └─ Thai ·landrace·
          └─ Shiva Skunk
             ├─ Northern Lights
             │  ├─ Afghani ·landrace·
             │  └─ Thai ·landrace·
             └─ Skunk #1
                ├─ Acapulco Gold ·landrace·
                ├─ Colombian Gold ·landrace·
                └─ Afghani ·landrace·

> Jack Herer × AK-47

**Sour Tangie** — ind 20 · THC 23 % · flor 4 sem · La leyenda

    Sour Tangie
       ├─ Tangie
       │  ├─ California Orange
       │  └─ Skunk #1
       │     ├─ Acapulco Gold ·landrace·
       │     ├─ Colombian Gold ·landrace·
       │     └─ Afghani ·landrace·
       └─ Sour Diesel
          ├─ Chemdawg
          └─ Super Skunk
             ├─ Skunk #1
             │  ├─ Acapulco Gold ·landrace·
             │  ├─ Colombian Gold ·landrace·
             │  └─ Afghani ·landrace·
             └─ Afghani ·landrace·

> Sour Diesel × Tangie

**NL × Big Bud** — ind 85 · THC 18 % · flor 3 sem · Las del norte

    NL × Big Bud
       ├─ Big Bud
       └─ Northern Lights
          ├─ Afghani ·landrace·
          └─ Thai ·landrace·

> Northern Lights × Big Bud

**Critical Jack** — ind 40 · THC 21 % · flor 3,5 sem · La leyenda

    Critical Jack
       ├─ Critical Mass
       │  ├─ Afghani ·landrace·
       │  └─ Skunk #1
       │     ├─ Acapulco Gold ·landrace·
       │     ├─ Colombian Gold ·landrace·
       │     └─ Afghani ·landrace·
       └─ Jack Herer
          ├─ Haze
          │  ├ receta 1: Punto Rojo × Thai
          │  │  ├─ Punto Rojo ·landrace·
          │  │  └─ Thai ·landrace·
          │  ├ receta 2: Michoacán × Thai
          │  │  ├─ Michoacán ·landrace·
          │  │  └─ Thai ·landrace·
          │  ├ receta 3: Michoacán × Punto Rojo × Thai
          │  │  ├─ Michoacán ·landrace·
          │  │  ├─ Punto Rojo ·landrace·
          │  │  └─ Thai ·landrace·
          │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
          │  ├─ Kerala ·landrace·
          │  ├─ Michoacán ·landrace·
          │  ├─ Punto Rojo ·landrace·
          │  └─ Thai ·landrace·
          ├─ Northern Lights
          │  ├─ Afghani ·landrace·
          │  └─ Thai ·landrace·
          └─ Shiva Skunk
             ├─ Northern Lights
             │  ├─ Afghani ·landrace·
             │  └─ Thai ·landrace·
             └─ Skunk #1
                ├─ Acapulco Gold ·landrace·
                ├─ Colombian Gold ·landrace·
                └─ Afghani ·landrace·

> Critical × Jack Herer · ≈ origen incierto

**Jack Herer Auto** — ind 45 · THC 25 % · flor 2,5 sem · Las autos

    Jack Herer Auto
       ├─ Jack Herer
       │  ├─ Haze
       │  │  ├ receta 1: Punto Rojo × Thai
       │  │  │  ├─ Punto Rojo ·landrace·
       │  │  │  └─ Thai ·landrace·
       │  │  ├ receta 2: Michoacán × Thai
       │  │  │  ├─ Michoacán ·landrace·
       │  │  │  └─ Thai ·landrace·
       │  │  ├ receta 3: Michoacán × Punto Rojo × Thai
       │  │  │  ├─ Michoacán ·landrace·
       │  │  │  ├─ Punto Rojo ·landrace·
       │  │  │  └─ Thai ·landrace·
       │  │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
       │  │  ├─ Kerala ·landrace·
       │  │  ├─ Michoacán ·landrace·
       │  │  ├─ Punto Rojo ·landrace·
       │  │  └─ Thai ·landrace·
       │  ├─ Northern Lights
       │  │  ├─ Afghani ·landrace·
       │  │  └─ Thai ·landrace·
       │  └─ Shiva Skunk
       │     ├─ Northern Lights
       │     │  ├─ Afghani ·landrace·
       │     │  └─ Thai ·landrace·
       │     └─ Skunk #1
       │        ├─ Acapulco Gold ·landrace·
       │        ├─ Colombian Gold ·landrace·
       │        └─ Afghani ·landrace·
       └─ Ruderalis

> Jack Herer × Ruderalis

**Big Bud Auto** — ind 85 · THC 14 % · flor 2,0 sem · Las autos

    Big Bud Auto
       ├─ Big Bud
       └─ Ruderalis

> Big Bud × Ruderalis

**Blue Dream Auto** — ind 40 · THC 19 % · flor 3,0 sem · Las autos

    Blue Dream Auto
       ├─ Blue Dream
       │  ├─ Haze
       │  │  ├ receta 1: Punto Rojo × Thai
       │  │  │  ├─ Punto Rojo ·landrace·
       │  │  │  └─ Thai ·landrace·
       │  │  ├ receta 2: Michoacán × Thai
       │  │  │  ├─ Michoacán ·landrace·
       │  │  │  └─ Thai ·landrace·
       │  │  ├ receta 3: Michoacán × Punto Rojo × Thai
       │  │  │  ├─ Michoacán ·landrace·
       │  │  │  ├─ Punto Rojo ·landrace·
       │  │  │  └─ Thai ·landrace·
       │  │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
       │  │  ├─ Kerala ·landrace·
       │  │  ├─ Michoacán ·landrace·
       │  │  ├─ Punto Rojo ·landrace·
       │  │  └─ Thai ·landrace·
       │  └─ Blueberry
       │     ├─ Purple Thai
       │     │  ├─ Chocolate Thai ·landrace·
       │     │  └─ Highland Oaxacan Gold ·landrace·
       │     ├─ Highland Thai ·landrace·
       │     └─ Afghani ·landrace·
       └─ Ruderalis

> Blue Dream × Ruderalis

**Sour Diesel Auto** — ind 30 · THC 24 % · flor 3,0 sem · Las autos

    Sour Diesel Auto
       ├─ Sour Diesel
       │  ├─ Chemdawg
       │  └─ Super Skunk
       │     ├─ Skunk #1
       │     │  ├─ Acapulco Gold ·landrace·
       │     │  ├─ Colombian Gold ·landrace·
       │     │  └─ Afghani ·landrace·
       │     └─ Afghani ·landrace·
       └─ Ruderalis

> Sour Diesel × Ruderalis

**Super Silver Haze Auto** — ind 20 · THC 20 % · flor 3,0 sem · Las autos

    Super Silver Haze Auto
       ├─ Ruderalis
       └─ Super Silver Haze
          ├ receta 1: Skunk #1 × Silver Haze
          │  ├─ Skunk #1
          │  │  ├─ Acapulco Gold ·landrace·
          │  │  ├─ Colombian Gold ·landrace·
          │  │  └─ Afghani ·landrace·
          │  └─ Silver Haze
          │     ├─ Haze
          │     │  ├ receta 1: Punto Rojo × Thai
          │     │  │  ├─ Punto Rojo ·landrace·
          │     │  │  └─ Thai ·landrace·
          │     │  ├ receta 2: Michoacán × Thai
          │     │  │  ├─ Michoacán ·landrace·
          │     │  │  └─ Thai ·landrace·
          │     │  ├ receta 3: Michoacán × Punto Rojo × Thai
          │     │  │  ├─ Michoacán ·landrace·
          │     │  │  ├─ Punto Rojo ·landrace·
          │     │  │  └─ Thai ·landrace·
          │     │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
          │     │  ├─ Kerala ·landrace·
          │     │  ├─ Michoacán ·landrace·
          │     │  ├─ Punto Rojo ·landrace·
          │     │  └─ Thai ·landrace·
          │     └─ Northern Lights
          │        ├─ Afghani ·landrace·
          │        └─ Thai ·landrace·
          └ receta 2: Haze × Northern Lights × Skunk #1
          ├─ Haze
          │  ├ receta 1: Punto Rojo × Thai
          │  │  ├─ Punto Rojo ·landrace·
          │  │  └─ Thai ·landrace·
          │  ├ receta 2: Michoacán × Thai
          │  │  ├─ Michoacán ·landrace·
          │  │  └─ Thai ·landrace·
          │  ├ receta 3: Michoacán × Punto Rojo × Thai
          │  │  ├─ Michoacán ·landrace·
          │  │  ├─ Punto Rojo ·landrace·
          │  │  └─ Thai ·landrace·
          │  └ receta 4: Kerala × Michoacán × Punto Rojo × Thai
          │  ├─ Kerala ·landrace·
          │  ├─ Michoacán ·landrace·
          │  ├─ Punto Rojo ·landrace·
          │  └─ Thai ·landrace·
          ├─ Northern Lights
          │  ├─ Afghani ·landrace·
          │  └─ Thai ·landrace·
          └─ Skunk #1
             ├─ Acapulco Gold ·landrace·
             ├─ Colombian Gold ·landrace·
             └─ Afghani ·landrace·

> Super Silver Haze × Ruderalis

### Sin generación (landraces aparte)

- **Ruderalis** — Landrace · Rusia y Asia central, silvestre

## 3. Las familias (el bono de la CannaDex)

| Familia | Bono | Variedades |
|---|---|---|
| **Las del Kush** | res +0,25 | Afghani, Hindu Kush, Chitral Kush, Purple Afghani, Master Kush, Purple Kush, Kif, Beldia, Lebanese, Kashmiri, Malana |
| **Las de Asia** | flor +0,04 | Thai, Chocolate Thai, Highland Thai, Luang Prabang, Nepalese, Vietnamese Black, Kerala, Kali Mist, Purple Thai |
| **Las de América** | thc +0,03 | Acapulco Gold, Michoacán, Punto Rojo, Colombian Gold, Highland Oaxacan Gold, Panama Red, Manga Rosa, Hawaiian, Lamb's Bread |
| **Las de África** | flor +0,04 | Malawi Gold, Congolese, Durban Poison, Swazi Gold, Zamal, Ethiopian Highland, Congo × Panama, Malawi × Panama, Malawi × PCK |
| **Las del olor fuerte** | g +0,05 | Skunk #1, Super Skunk, Lemon Skunk, Cheese, Critical Mass, Shiva Skunk, Blue Cheese, Critical Cheese, Critical 47, Chronic |
| **Las Haze** | thc +0,03 | Haze, Lemon Haze, NL5 × Haze, Neville's Haze, Silver Haze, Cannalope Haze, Amnesia Haze, Super Silver Haze, Super Lemon Haze, Purple Haze, Hawaiian Snow, Chocolope |
| **Las del norte** | g +0,05 | Northern Lights, Big Bud, Blueberry, Blue Dream, NL × Big Bud, Northern Light Blue, Ice, Laughing Buddha |
| **Las blancas** | res +0,25 | White Widow, White Russian, Blue Widow, White Rhino, White Shark, AK-47, Kali 47, Critical Kali Mist |
| **La leyenda** | thc +0,04 | Jack Herer, Jack Flash, Jack 47, Critical Jack, Trainwreck, Pineapple Express, Tangie, Sour Tangie, Sour Diesel, Chemdawg, California Orange |
| **Las autos** | flor +0,04 | Ruderalis, Lowryder, Northern Lights Auto, White Widow Auto, Amnesia Haze Auto, Blueberry Auto, AK-47 Auto, Jack Herer Auto, Skunk #1 Auto, Big Bud Auto, Super Skunk Auto, Cheese Auto, Blue Dream Auto, Sour Diesel Auto, Super Silver Haze Auto, Purple Kush Auto, Durban Poison Auto |


# Documento maestro (lo mandó el usuario el 19-10-2026)

Decidido con el usuario: primero se cierra el plan de Google Play (F6 → F7 → F8 → AAB). Después, este documento por tandas,
empezando por la base sistémica ([10] fuentes, [1] personaje, [3] vehículos y maletero, [5] IVs, shiny, saturación y curado),
y luego negocios, NPC y endgame. Los sprites nuevos (protagonista femenina, retratos HD) se hacen con PixelLab.

Al implementarlo se adapta a lo que ya existe y se usan sus nombres reales: la partida es `user://partida.json`; la Copa ya
existe (`COPA_THC`); los fenotipos estrella (`p.f`, `S.fenos`), el curado (`CURADO`), el camarote, la caja fuerte, la nave,
las extracciones sin disolventes y el concesionario también. Lo nuevo va con `Datos.CAL` y lo de la tienda, con `Datos.PLAY`.
Nada de método real: ni dosis, ni pasos de extracción con disolventes.

---

# LANDRACE HUNTERS - DOCUMENTO MAESTRO TÉCNICO Y DE DISEÑO
# (Expansión Modular: Base, Sistemas, Endgame, Inmersión y Localización de Fuentes)

> **REGLA CRÍTICA DE ARQUITECTURA Y RETROCOMPATIBILIDAD (GODOT)**:
> 1. **NO REESCRIBIR SISTEMAS BASE**: El sistema actual de cultivo (fases de planta, macetas, luces), los tanques de abono de la nave, la lógica actual de cruces genéticos (`breeding`), las estanterías de tarros de curado, la caja fuerte (2 kg) y la UI del dispensario SON LA BASE SÓLIDA DEL JUEGO.
> 2. **EXTENSIÓN POR COMPOSICIÓN**:
>    - El nuevo **Maletero** debe instanciar y reutilizar la clase/escena existente de la **Caja Fuerte**, cambiando únicamente el límite de peso (`max_weight`) según el vehículo.
>    - El **Club del Puerto** y los **Clubs VIP** deben heredar de la escena/script del **Dispensario actual**, añadiendo las pestañas de Plantilla, Contable de Blanqueo y Sistema de Crédito.
>    - La **CannaDex**, los **Fenotipos Estrella** y la **CannaCup** deben leer los diccionarios de semillas y cogollos ya existentes en el proyecto, añadiendo nuevas claves al JSON (`rarity_tier`, `is_shiny`, `terpene_profile`, `cure_days`, `iv_stats`) con valores por defecto para no romper partidas guardadas en `user://savegame.json`.
> 3. **GESTIÓN DE FUENTES Y GLIFOS**: Forzar la carga de caracteres latinos (`ñ`, acentos y signos de apertura) en Godot y asegurar que los archivos `.ttf`/`.otf` no se filtren en la exportación del APK o ejecutable.

## [0] NÚCLEO BASE DEL JUEGO (MANTENER INTACTO Y AMPLIAR)
- Sistema actual de cultivo (germinación, fases de crecimiento, cosecha) en camarote y nave.
- Sistema actual de tanques de abono, nutrientes y mantenimiento de plantas.
- Mecánica actual de cruces genéticos y obtención de semillas/fenotipos.
- Almacenamiento actual: Caja fuerte en camarote (2 kg), maleta inicial (10 kg) y estanterías de tarros de curado.
- Gestión comercial base: Dispensario, envíos desde el puerto y economía de dinero negro vs. dinero blanqueado.

## [1] CREACIÓN DE PERSONAJE, GÉNERO Y CUMPLEAÑOS
- **Datos en Savegame**: Añadir `player_gender` (`"male"` | `"female"`), `player_name` (string editable sustituyendo los 4 por defecto) y `birth_date` (`{day: int, month: int}`).
- **Sprites y Pasivas**: Condicionar ruta del `AnimatedSprite2D` del jugador según `player_gender`. Aplicar modificador pasivo inicial:
  - `male`: `+15%` capacidad de carga base / menor gasto de estamina.
  - `female`: `-15%` radio de detección policial / `+10%` margen en negociación con NPCs.
- **Draft de Cumpleaños (`BirthdayDraftUI`)**:
  - Evaluar en `TimeManager` si `current_date == birth_date`.
  - Instanciar UI de selección excluyente (3 cartas) conectada a la base de datos de objetos catalogados por `rarity_tier` (`Common`, `Rare`, `Epic`, `Legendary`):
    - **Slot 1**: `1x Legendary` (Semilla fenotipo estrella / mutación única).
    - **Slot 2**: `2x Epic` (Equipamiento de cultivo automatizado / iluminación top).
    - **Slot 3**: `10x Rare` (Lote de consumibles, abonos o botes de curado).

## [2] ESTADOS FISIOLÓGICOS Y ALTERADOS (`StatManager.gd`)
- **Variables Globales**: `drunk_level: float (0.0 - 100.0)` y `high_level: float (0.0 - 100.0)`, más diccionario `active_cannabinoid_profile`.
- **Indicador de Intoxicación Etílica (Borrachera)**:
  - `31.0 - 70.0`: Aplicar interpolación de inercia (`lerp`) al vector `velocity` del jugador.
  - `> 70.0`: Activar `CanvasLayer` con shader de aberración cromática y visión triple. Si llega a `100.0` en exteriores, ejecutar evento `trigger_blackout()`: avanzar reloj 8 horas, teletransportar a punto de spawn secundario, restar `30%` de `cash` y `50%` de items en inventario activo.
- **Indicador de Psicoactividad Cannábica (Fumado)**:
  - Leer metadatos del ítem consumido (`sativa_ratio`, `indica_ratio`, `thc_pct`).
  - **Sativa**: Multiplicador de velocidad `1.15x`, incremento del radio del `DetectionArea2D` de la policía (paranoia).
  - **Índica**: Multiplicador de velocidad `0.75x` (pesadez motora), reducción de alerta policial y bono de velocidad en timers de curado/laboratorio.

## [3] TRANSPORTE, GARAJE Y MALETERO INTERACTIVO (`VehicleManager.gd`)
- **Persistencia Espacial**: Eliminar invocación global de vehículos. Guardar en `savegame.json` el diccionario `vehicles_state[vehicle_id] = {scene_path, global_position, fuel, durability, trunk_inventory}`. Si se abandonan mal aparcados, la grúa municipal los retira al depósito exigiendo el pago de una tasa.
- **Capacidades**: `suitcase` (10 kg), `motorbike` (40 kg, riesgo de caída de carga en choques), `white_car` (150 kg, carga protegida), más modelos de alta gama desbloqueables por mudanza de barrio. Desgaste y combustible vinculados al taller mecánico.
- **Maletero Interactivo**: Añadir `Area2D` trasera en escenas de vehículos. Al interactuar antes de conducir, instanciar `GridInventoryUI` (heredando la lógica de la caja fuerte de 2 kg) permitiendo curar hierba en botes, rellenar tanques de abono de la nave o empaquetar al vacío en ruta (aplica flag `vacuum_sealed = true`, reduciendo probabilidad de detección en controles).

## [4] CLIMA, MUNDO ABIERTO, CAZA DE LANDRACES, ESPACIOS ACCESIBLES Y CONTROLES
- **Fix Puerto Abandonado**: Vincular la escena del puerto al `WeatherManager` y ciclo día/noche global, eliminando la iluminación estática de sol perpetuo.
- **Impacto Agroclimático**: Si `weather_state == "rain"` o `humidity > 80%`, incrementar probabilidad diaria de estado `fungus_infection` (botritis) en nodos de plantas exteriores o invernaderos sin mejora de sellado, exigiendo uso de preventivos y fungicidas.
- **Expansión de Mapas y Espacios Accesibles**: Ampliar límites de `TileMap` en bordes laterales para crear rutas interurbanas (carreteras, pistas y caminos rurales). Preservar y habilitar zonas clave del mapa como refugios, bases o puntos de producción intermedios, destacando el **bajo de las setas**, la **nave de cultivo principal**, zonas subterráneas y otros emplazamientos explorables.
- **Caza de Landraces Salvajes**: Aparición de plantas silvestres en zonas rurales según el clima para recolectar semillas o esquejes puros e incorporarlos al sistema de cruces.
- **Controles Policiales**: Nodos `PoliceCheckpoint` con spawn probabilístico que evalúan peso en maletero y flag `vacuum_sealed`, disparando diálogo de resolución (Huir, Sobornar, Entregar carga).

## [5] PROFUNDIZACIÓN EN CULTIVO, CRUCES Y PRESTIGIO (ESTILO POKÉMON / HEMPIRE)
- **CannaDex (Catálogo Genético)**: Registro visual de variedades cultivadas y cruzadas. Completar familias de cepas otorga bonos pasivos permanentes al cultivo.
- **Fenotipos Estrella (Mutaciones Shiny) y Plantas Madre**: Probabilidad muy baja (ej. 1/500) al germinar o cruzar de obtener una planta con coloración única (morada, albina, dorada) y valor multiplicado por 5. Exige conservar una planta madre y sacar esquejes; si se cosecha sin clonar, la genética se pierde.
- **Genética Hereditaria (IVs / Estadísticas Ocultas)**: Cada semilla tiene 4 valores internos de 1 a 31 (Potencia THC/CBD, Producción en gramos, Tiempo de floración y Resistencia a hongos) que se transmiten y mejoran generación tras generación mediante cruces.
- **La CannaCup (Competición)**: Eventos del calendario donde se presenta el mejor tarro curado de la nave/camarote (exige curado al 99% y perfiles específicos). Ganar trofeos sube el prestigio, requisito obligatorio junto al dinero para desbloquear los Clubs VIP de la Ciudad Céntrica.
- **Laboratorio de Extracciones y Certificación**: Maquinaria para procesar restos de poda en Dry Sift, Bubble Hash, Rosin o BHO (poco peso en maletero y alto valor). Análisis de laboratorio para certificar niveles de THC y terpenos para vender más caro en los clubes.
- **Saturación de Mercado**: Vender masivamente la misma cepa en el mismo pueblo desploma su precio un 50%, obligando a rotar genéticas.
- **Penalización por Hierba Verde**: Vender hierba recién cortada da beneficio mínimo; mantenerla semanas en tarros multiplica progresivamente su valor real.
- **Límite de Consumo Eléctrico y Sospecha Térmica**: Ampliar focos dispara el gasto de luz y la firma térmica. Superar el límite sin generadores diésel insonorizados o placas solares alerta a la policía.

## [6] GESTIÓN DE NEGOCIOS, PLANTILLAS, BLANQUEO Y SEGURIDAD
- **Club del Puerto**: Habilitar interfaz de control idéntica a la del dispensario.
- **Gestión de Plantilla (`StaffManagerUI`)**: Vista de cuadrícula por local alquilado. Cada trabajador es un recurso con `role`, `salary`, `loyalty` y `efficiency`.
- **Sistema de Contratación y Perfil de Lealtad (Riesgo de Topo del 1 al 10)**:
  - *Nivel 1 a 3 (Lealtad Baja - 15% probabilidad de ser topo/informante).*
  - *Nivel 4 a 7 (Lealtad Media - 5% probabilidad; se degrada si hay malos salarios o alta presión).*
  - *Nivel 8 a 9 (Lealtad Alta - 2% probabilidad de traición).*
  - *Nivel 10 (Lealtad Absoluta - 0% infiltración; desbloquea pasiva de Capataz/Contrainteligencia para vigilar y detectar comportamientos extraños en compañeros).*
- **Contable / Gestor de Blanqueo**: Rol de empleado asignable a locales. En cada tick de cambio de día, convierte automáticamente `X` cantidad de `dirty_money` a `clean_money` deduciendo su comisión porcentual.
- **Control de Olor (Carbón Activo + Ozono en Conducto)**: Instalación de filtros de carbón activo (con desgaste por uso y humedad) combinados con ozonizadores intercalados en los tubos de extracción para eliminar el 100% del olor en la calle, evitando que el ozono entre en contacto directo con las flores para no destruir sus terpenos.
- **Seguridad Activa en Nave y Locales**: Compra de puertas blindadas, alarmas, perros guardianes y cámaras de seguridad (visibles desde los monitores del despacho) para evitar robos o redadas.

## [7] NPCS DINÁMICOS, MUNDO VIVIENTE, SOCIOLECTOS TERRITORIALES Y SISTEMA DE CRÉDITO ("FIAR")
- **NPCs Coherentes**: Conexión estricta entre nombre, género (`male`/`female`), estadísticas (gustos, comportamiento) y stock modular de sprites de cuerpo y ropa.
- **Sociolectos y Jerga por Entornos (Inmersión Territorial)**:
  - *Entornos Rurales y Pueblos*: Expresiones directas, castizas o de jerga tradicional; ritmo pausado, desconfianza inicial y temas centrados en el clima y rumores locales.
  - *Barrios Obreros y Periferia*: Slang urbano crudo, jerga callejera rápida, códigos de lealtad de asfalto y tratos directos.
  - *Metrópoli y Zonas Céntricas (Clubs VIP)*: Lenguaje formal pero cínico, jerga de negocios de alto nivel, modismos modernos y esnobismo con el producto.
- **Sistema de Diálogos Orgánicos y Misiones Contextuales**: Árboles conversacionales ramificados con memoria de interacciones previas. Las misiones secundarias emergen de forma natural a partir de las charlas en bares, esquinas o tiendas según tu reputación y tus estados alterados.
- **Mecánica de Crédito ("Fiar Producto")**:
  - Los clientes habituales o de confianza que se queden cortos de efectivo pueden pedirte fiar mercancía.
  - La decisión de aceptar o rechazar depende del perfil del NPC (historial de compras, nivel de relación, reputación en la zona y arquetipo del cliente: un abuelo paga tarde pero paga; un yonqui o pandillero tiene alta probabilidad de hacer un "simpa").
  - Si se fía, se genera un registro de deuda con fecha límite. Pagar a tiempo sube la fidelidad y desbloquea favores/chismes; el impago obliga a confrontar al deudor (perdonar la deuda por respeto callejero, exigir con intereses con riesgo de pelea, o amenazar aumentando la criminalidad).
- **Pedidos por Gustos y Efectos (Estilo Weed Firm)**: Los NPCs piden variedades con efectos o sabores concretos (ej. sativa cítrica o índica narcótica con +22% THC) en lugar de comprar al azar, otorgando pluses y objetos si aciertas con la cepa del tarro.
- **Combates Realistas**: Variedad de golpes, armas, estados (sangrado, aturdido) y mensajes dinámicos para eliminar la repetición de ataques planos.
- **Tiendas por Categorías y Marcas**: Ampliar catálogo de grow, estanco, bar, mecánico, concesionario y clubs con filtrado de `Category -> Subcategory -> Brand`.

## [8] MEJORAS EN NAVE, DESPACHO Y COMUNICACIÓN
- **Ampliación de Curado**: Duplicar la capacidad de slots y nodos visuales de estanterías de tarros en la escena de la nave de cultivo tras adquirir la mejora (igual que en el camarote).
- **Despacho Narco**: Actualizar tilemap y props del despacho en su nivel máximo (mobiliario de lujo, monitores de seguridad conectados a cámaras de locales, caja fuerte de alta capacidad).
- **Sistema de Diálogos HD**: Integrar contenedor de retrato en alta resolución (`PortraitRect`) en la UI de conversaciones en vivo, llamadas telefónicas y mensajería de texto, sincronizado con la identidad procedural del NPC y adaptando su expresividad al tono de la charla.

## [9] ENDGAME: RED DE MENUDEO Y CIUDAD CÉNTRICA
- **Red de Puntos de Venta**: Al activar la exportación marítima en el puerto, habilitar compra/alquiler de nodos `Safehouse_Local`. Permite asignar un NPC lugarteniente que drena stock automáticamente del almacén local y genera ingresos pasivos masivos según el parámetro configurado de pureza/precio.
- **Expansión Metropolitana (`Central_City`)**: Desbloqueo de viaje por autopista al superar el umbral de patrimonio neto. Mapa urbano de alta densidad con locales para **Clubs VIP**, mecánicas de soborno a concejales (reducción de riesgo de clausura) y eventos de control territorial frente a facciones rivales.

## [10] OPTIMIZACIÓN TÉCNICA DE FUENTES Y GLIFOS EN GODOT
- Configuración estricta de fuentes de texto (`FontFile` / `DynamicFont`) para garantizar la compatibilidad total e incrustación de glifos internacionales (acentos `á, é, í, ó, ú`, diéresis `ü`, eñes `ñ`, y signos de puntuación `¿, ¡`).
- Configuración de filtros de exportación en el proyecto de Godot para asegurar que los archivos de fuentes (`*.ttf`, `*.otf`) nunca se excluyan al compilar el ejecutable o el paquete APK.
- Asignación de fuentes de respaldo (`fallback`) en la interfaz para prevenir la aparición de símbolos extraños o caracteres corruptos en caso de que un glifo específico no cargue en la fuente principal.

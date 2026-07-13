# GDD MASTER: PROYECTO PHENO HUNTER (SANDBOX ISOMÉTRICO)

> Biblia técnica del proyecto. Rigor arquitectónico y lógica agronómica
> profesional. Documento canónico (supersede a notas previas). 100% original.

## 0. PITCH Y CONCEPTO CORE
- **Identidad:** Sandbox isométrico single-player.
- **Rol:** Pheno hunter / Grower-dealer.
- **Objetivo:** Adquisición, cultivo indoor estricto, hibridación y venta de genética *landrace*.
- **Meta:** Completar el Strain-dex (catálogo maestro).
- **Restricción:** Cero mecánicas de combate.

## 1. GÉNERO Y SCOPE
- **Género:** Coleccionismo genético + Gestión + Roam GTA-lite (NPC-driven).
- **Perspectiva:** Isométrica 2:1.
- **Progresión:** Desde un setup básico de interior hasta dominar el panorama global de la cría.

## 2. CORE LOOP
1. **Explorar:** Navegación urbana.
2. **Adquirir:** Consecución de genética *landrace*.
3. **Cultivar:** Gestión agronómica (5 fases de desarrollo vegetal).
4. **Cosechar:** Selección de fenotipos y clonación.
5. **Cruzar:** Manipulación genética.
6. **Vender:** Distribución para capitalización.
7. **Progresar:** Expansión de instalaciones.

## 3. MOTOR Y COLISIONES
- **Stack:** HTML5/Canvas puro (sin dependencias). Empaquetado single-file.
- **Render:** Isométrico con oclusión estricta por profundidad (eje Z).
- **Movimiento:** Cuadrícula (grid-based) + Seguimiento de cámara.
- **Físicas:** Colisiones por lista blanca. Paredes, objetos y NPCs bloquean celdas. Auditoría continua por frame.

## 4. MUNDO, NPCs Y ECONOMÍA
- **Instancias:** Grow-room (indoor), Calle, Mercado, Laboratorio.
- **Comportamiento NPC:** 8 arquetipos con IA de deambulación (máquinas de estados).
- **Economía:** Sistema de créditos. Mercado estándar vs. Tratos callejeros premium.

## 5. SISTEMAS NÚCLEO: GENÉTICA Y CULTIVO
- **Motor Genético:** Arquitectura diploide. Dominancia, poligenes, poliploidía y mutaciones.
- **Investigación ADN:** Mapeo de alelos recesivos, trazabilidad de parentesco y linaje.
- **Cultivo:** 5 fases en maceta constante. Ciclos optimizados para alta rotación de interior
  (fenotipos viables en ciclos inferiores a 10 semanas).
- **Catálogo:** 18 cepas *landrace* fundacionales.
- **Strain-dex:** Registro por firma fenotípica (morfología, rendimiento, terpenos).

## 6. AMBIENTE, CONTROLES Y PROGRESIÓN
- **Entorno:** Ciclo día-noche, estaciones, clima dinámico y eventos raros.
- **Métricas de Éxito:** Acumulación de créditos + Nivel de prestigio.
- **Inputs:** Movimiento (WASD/Flechas) + Teclas de acceso rápido a paneles.

## 7. PIPELINE DE ARTE Y ASSETS
- **Estilo:** Pixel-art isométrico original.
- **Volumetría:** 8 roles NPC × 4 direcciones; 18 cepas × 5 fases de crecimiento.
- **Pipeline Generativo:** Prompts Gemini → Generación base → Chroma key/recorte → Inyección inline (Base64).

## 8. ROADMAP Y ESCALABILIDAD
- **Fase 2:** Mobiliario modular y expansión de tiles isométricos.
- **Fase 3:** Sistemas de estrés de cultivo (gestión de riego, aparición de patógenos/moho con
  resoluciones biológicas limpias, no tóxicas).
- **Fase 4:** Rutinas de NPC avanzadas, sistema de presión policial (Heat/Cops).
- **Fase 5:** Ciudad grande, nuevas regiones, salas decorables y misiones estructuradas.

---
### Estado de implementación (vivo)
| Bloque | Estado |
|---|---|
| Motor iso + colisiones + auditoría | ✅ |
| Salas (grow-room, calle, mercado, lab) + warps | ✅ |
| NPCs: 8 roles con IA de deambular + sprites 4 dir | ✅ |
| Economía: mercado + trato callejero premium | ✅ (base) |
| Genética diploide / cruces / ADN / Strain-dex | ✅ |
| Cultivo 5 fases (maceta constante) + arte 18 cepas | ✅ |
| Ambiente (día/noche, clima, eventos) | ✅ |
| **Fase 2:** mobiliario iso + tiles iso | 🔄 en curso |
| Fase 3: estrés de cultivo (riego/moho) | 🔜 |
| Fase 4: rutinas por horario + heat/cops | 🔜 |
| Fase 5: ciudad grande, regiones, salas decorables, misiones | 🔜 |

# Simulación de la deuda (fase 5, U3)

Generado con `tests/economia.gd` (motor real de cultivo y precios). Plazos: { "3": 3000.0, "5": 12000.0, "7": 15000.0 } · interés 20 % · rescate { "dias": 5.0, "interes": 0.5, "tope": 0.5 } · días por plazo { "3": 12.0, "5": 16.0, "7": 24.0 }.

Criterio: el medio paga los tres plazos a tiempo y sin recargos; el torpe, que tras el rescate de Toño juega como el medio, acaba la deuda con un embargo por capítulo como mucho. Los recargos de un plazo no pasan del tope (RESCATE.tope de lo que pedía).

## prudente

| Plazo | Pide | Vence (día) | Pagado (día) | Recargos | Embargos |
|---|---|---|---|---|---|
| cap. 3 | 3.000 € | 16 | 14 | 0 | 0 |
| cap. 5 | 12.000 € | 39 | 29 | 0 | 0 |
| cap. 7 | 15.000 € | 59 | 38 | 0 | 0 |

Deuda saldada: sí · día 38 · dinero al final 1.049 € · gramos vendidos 10160 · embargos por capítulo como mucho 0.

## medio

| Plazo | Pide | Vence (día) | Pagado (día) | Recargos | Embargos |
|---|---|---|---|---|---|
| cap. 3 | 3.000 € | 17 | 15 | 0 | 0 |
| cap. 5 | 12.000 € | 43 | 40 | 0 | 0 |
| cap. 7 | 15.000 € | 72 | 68 | 0 | 0 |

Deuda saldada: sí · día 68 · dinero al final 137 € · gramos vendidos 10272 · embargos por capítulo como mucho 0.

## torpe

| Plazo | Pide | Vence (día) | Pagado (día) | Recargos | Embargos |
|---|---|---|---|---|---|
| cap. 3 | 3.000 € | 29 | 27 | 2 | 0 |
| cap. 5 | 12.000 € | 57 | 56 | 0 | 0 |
| cap. 7 | 15.000 € | 88 | 87 | 0 | 0 |

Deuda saldada: sí · día 87 · dinero al final 177 € · gramos vendidos 10455 · embargos por capítulo como mucho 0.


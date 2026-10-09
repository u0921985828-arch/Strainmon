---
description: Porta al proyecto Unity una parte concreta del prototipo HTML
argument-hint: <qué sistema portar>
---

Porta a Unity: **$ARGUMENTS**

Procedimiento:
1. Localiza ese sistema en `referencia/bilbo-city.html` y léelo entero antes de escribir nada.
2. Busca dónde vive ya en `unity/BilboCity/Assets/Scripts/` y qué falta.
3. Transcribe la lógica, no la reinventes. El HTML está probado; el puerto no.
4. Cuidado con las trampas conocidas:
   - la Y del mundo va al revés que la de Unity;
   - en C# no se puede modificar una lista mientras se recorre;
   - los nombres de campo no deben tapar nombres de clase.
5. Pasa `./verificar.sh csharp`. El analizador caza justo esos tres fallos.

---
tipo: mecánica
estado: hecho
version: 0.1
hito: 1
---
# Bosque procedural

> Un grid de zonas que se genera a medida que lo pisás y desaparece al volver al pueblo.

## Cómo funciona
- Zonas de **40×40 tiles** (640×640 px), cambio tipo *Isaac*: cruzás una puerta y carga la zona vecina.
- Cada zona se genera **la primera vez que se pisa** y queda en una cache de la sesión; si volvés, está igual (sin lo que ya recolectaste o mataste).
- Puertas: si el vecino ya existe se respeta su puerta; si no, 45% de chance. La puerta de entrada siempre existe.
- **Anti-encierro:** si hay vecinos sin generar, al menos una puerta lleva a uno. Los callejones sin salida son parte del riesgo.
- Cada puerta tiene un corredor libre hasta el centro: todo queda conectado.
- **Profundidad** = distancia Manhattan a la zona (0,0). El pueblo está en (-1,0).
- Minimapa estilo Isaac con las zonas visitadas; se resetea con el bosque.

## Se conecta con
- [[Presupuesto de dificultad]]: decide qué y cuánto aparece en cada zona.
- [[Reloj]]: la hora en que pisás una zona por primera vez fija su dificultad.
- [[Recolección]] y [[Enemigos]]: lo que llena la zona.
- [[Noche y linterna]]: de noche el bosque se oscurece.
- [[Tablón de misiones]]: misiones de "llegar a profundidad N".
- [[Pueblo]]: volver resetea todo.

## Números
Tamaño, chance de puerta, decoración: [[BALANCE]] § Bosque.

## Código
`scripts/zone_generator.gd` · `scripts/zone_data.gd` · `autoload/forest_session.gd` · `scenes/world/forest_zone.gd` · `scenes/ui/minimap.gd` · test `tests/test_generation.gd` (200 runs).

## Ideas y pendientes
- Se siente **vacío**: [[Plantillas de zona y eventos]] (0.2).
- Biomas distintos: [[Ideas para la 0.3]].

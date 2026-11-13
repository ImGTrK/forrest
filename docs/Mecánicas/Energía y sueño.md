---
tipo: mecánica
estado: hecho
version: 0.1
hito: 2
---
# Energía y sueño

> Una barra que baja con el tiempo y con cada acción: el reloj interno que te obliga a volver.

## Cómo funciona
- Máx. 100 (+10 por mejora). Baja 5 por hora + 0.4 por golpe + 0.6 por dash.
- **Rampa de aviso:** 50% mensaje · 20% debuff (velocidad ×0.7, golpes 2× más lentos) · 0% colapso.
- **Dormir** solo en la cama del pueblo: pasan 5-9 h al azar y recarga 12 por hora dormida. También cura.
- Energía y hora persisten: no se resetean con el bosque.

## Se conecta con
- [[Reloj]]: drenaje por hora; dormir adelanta el reloj.
- [[Recolección]] y [[Combate]]: costo por acción.
- [[Fin del run]]: llegar a 0 = colapso.
- [[Pueblo]]: la cama.
- [[Mejoras permanentes]]: +10 de energía máxima.

## Pilar que refuerza
- Decidir cuándo volver · Nada es 100% predecible (horas de sueño al azar).

## Números
[[BALANCE]] § Tiempo y energía.

## Código
`autoload/energy.gd` · `scenes/entities/bed.gd` · `scenes/main.gd` (`sleep`).

## Ideas y pendientes
- Comida que recupere energía **parcialmente** (nunca reemplazar dormir): [[Ideas para la 0.3]].

---
tipo: mecánica
estado: hecho
version: 0.1
hito: 2
---
# Reloj

> El tiempo corre siempre (salvo en menús) y todo se vuelve más difícil y más valioso a medida que avanza la noche.

## Cómo funciona
- **30 s reales = 1 h de juego.** Arranca a las 06:00. Se pausa en inventario, crafting, tablón y pausa.
- No hay "días" como unidad: el bosque se resetea al volver al pueblo, no por la hora.
- **Curva por hora:** presupuesto ×1.0 (mañana) → ×1.25 (18 h) → ×1.5 (22 h) → ×1.8 (2 h) → ×2.0 (6 h). Rareza +0 → +3 en los mismos puntos.
- Cada zona toma la dificultad de la hora en que se pisa **por primera vez**.
- Tinte del mundo según la hora (el HUD no se tiñe).

## Se conecta con
- [[Presupuesto de dificultad]]: multiplicador y rareza.
- [[Energía y sueño]]: la energía baja con cada hora; dormir hace pasar 5-9 h.
- [[Noche y linterna]]: de 18 a 05 se oscurece.

## Pilar que refuerza
- Decidir cuándo volver: "¿entro ahora que hay luz o aguanto hasta la madrugada por mejor botín?"
- Runs cortas: el ritmo del reloj define cuánto dura una salida.

## Números
[[BALANCE]] § Tiempo y energía.

## Código
`autoload/clock.gd`.

## Ideas y pendientes
- Ajustar para runs de **5-10 min** (hito 12).
- Clima: [[Ideas para la 0.3]].

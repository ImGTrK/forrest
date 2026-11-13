---
tipo: índice
---
# Forrest — Inicio

> *"Cada mañana salís del pueblo hacia un bosque que nunca es el mismo dos veces. Volvés antes de que oscurezca — o no volvés con nada."*

Este vault es el **diseño vivo** del juego: una nota por mecánica, conectadas entre sí, con su estado,
sus números y sus ideas pendientes. Se abre en Obsidian eligiendo la carpeta `docs/` como vault.

## Por dónde empezar
- [[Pilares y objetivos]]: qué tiene que sentir el jugador y para qué existe cada sistema.
- **[[Sistemas.canvas|Mapa de sistemas]]**: todas las mecánicas y cómo se alimentan entre sí.
- [[Mecánicas.base|Tabla de mecánicas]]: todas las notas con su estado, versión e hito.

## El loop
```
Pueblo: guardar, fabricar, reclamar misiones, dormir
  → Bosque: explorar zonas, recolectar, pelear
  → [seguir / volver / se hace de noche / te cansás]
  → Volver (o colapsar o morir) → el bosque se resetea
  → Repetir con mejor equipo
```

## Mecánicas
**Pueblo:** [[Pueblo]] · [[Tablón de misiones]] · [[Mejoras permanentes]] · [[Guardado]]
**Bosque:** [[Bosque procedural]] · [[Presupuesto de dificultad]] · [[Recolección]] · [[Enemigos]]
**Tiempo:** [[Reloj]] · [[Energía y sueño]] · [[Noche y linterna]] · [[Fin del run]]
**Ítems:** [[ADN de recursos]] · [[Inventario y peso]] · [[Herramientas y durabilidad]] · [[Crafting]]
**Jugador:** [[Combate]]

## Ideas y planes
- Versiones: [[v0.1 - MVP]] · [[v0.2 - Un bosque que da ganas de volver]]
- Planeado para 0.2: [[Plantillas de zona y eventos]] · [[Rasgos raros]] · [[Tercer escalón - cristal]]
- Abierto: [[Motor para volver al bosque]] · [[Ideas para la 0.3]]

## Referencia (documentos largos)
- [[GDD]]: el documento original y el registro de decisiones por hito (§10-16).
- [[ROADMAP]]: checklist de hitos.
- [[BALANCE]]: todos los números ajustables y dónde se cambian.
- [[GUIA_ARTE_Y_SONIDO]]: sprites, tiles y sonidos, hechos y por hacer.
- [[Arquitectura]]: clases base, componentes y cómo sumar enemigos o interactuables.

## Cómo usar el vault
- **Estado** de cada nota (propiedad `estado`): `hecho` · `planeado` · `idea` · `abierto` (pregunta sin resolver).
- Nueva mecánica o idea: comando *Insertar plantilla* → `Plantillas/Mecánica` o `Plantillas/Idea`.
- Colores del canvas: **verde** hecho · **naranja** planeado para la 0.2 · **violeta** idea para después · **rojo** pregunta abierta.
- Las notas son el resumen vivo; si algo cambia en el código, Claude actualiza la nota en el mismo hito.

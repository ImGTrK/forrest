---
tipo: mecánica
estado: hecho
version: 0.1
hito: 4
---
# Inventario y peso

> Mochila en grilla con límite de peso, y un almacén en el pueblo: decidir qué cargar y qué arriesgar.

## Cómo funciona
- **Mochila:** grilla 6×4; cada ítem ocupa su tamaño (madera 1×2). Se puede rotar.
- **Peso:** sale del ADN. Límite 18 kg (+2 por mejora); por encima, velocidad ×0.5 (se suma al debuff de energía).
- **Almacén:** grilla de 10 columnas que crece sola (siempre deja 2 filas libres). Se ve al lado de la mochila.
- Manejo: clic agarra/suelta (sobre otro ítem intercambia), R o clic derecho rota, Shift+clic pasa entre grillas, Supr/X tira, "Ordenar" compacta.
- **Nada se guarda solo** al volver: guardar en el almacén es decisión del jugador. El equipo nunca se pierde.

## Se conecta con
- [[ADN de recursos]]: el peso de cada ejemplar.
- [[Recolección]]: mochila llena = no se puede recolectar.
- [[Fin del run]]: lo cargado es lo que se pierde al colapsar o morir.
- [[Herramientas y durabilidad]]: las herramientas también ocupan lugar y pesan.
- [[Crafting]] y [[Tablón de misiones]]: usan mochila **y** almacén.
- [[Mejoras permanentes]]: +2 kg.
- [[Pueblo]]: el almacén vive ahí.

## Pilar que refuerza
- Decidir cuándo volver: la mochila llena o pesada es una razón para volver.

## Números
[[BALANCE]] § Pérdidas y mochila.

## Código
`scripts/grid_inventory.gd` · `autoload/game_state.gd` · `scenes/ui/inventory_ui.gd`, `inventory_grid_view.gd`, `item_chip.gd`.

## Ideas y pendientes
- Dejar el ítem tirado en el piso en vez de destruirlo (opcional).

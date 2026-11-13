---
tipo: mecánica
estado: hecho
version: 0.1
hito: 1
---
# ADN de recursos

> Cada recurso que recolectás es único: sale con stats aleatorios que después definen lo que fabricás con él.

## Cómo funciona
- Cada tipo tiene 2-3 stats con rango min-max (`data/items/*.tres`). Ej.: madera → densidad, flexibilidad, peso.
- Cada stat se tira como **"mejor de N"**, con N = 1 + profundidad/3 (máx. 3): lo profundo sale mejor.
- Algunos stats son **invertidos** (menos es mejor), como el **peso**: lo profundo pesa menos.
- **Calidad** = promedio normalizado de los stats (0-100%). Marca dorada ≥80%, verde ≥55%.

## Se conecta con
- [[Recolección]]: el momento del roll.
- [[Presupuesto de dificultad]] y [[Reloj]]: profundidad + rareza de la hora mejoran el roll.
- [[Inventario y peso]]: el stat peso define cuánto carga.
- [[Crafting]]: los stats de los materiales pasan a la herramienta.
- [[Tablón de misiones]]: entregas con calidad mínima.

## Pilar que refuerza
- Nada es 100% predecible · Orgullo por el botín.

## Código
`scripts/dna.gd` · `scripts/item_instance.gd` · `data/item_data.gd`.

## Ideas y pendientes
- **0.2:** [[Rasgos raros]]: además de los números, a veces sale un rasgo especial con nombre.
- Colección o récord de mejores rolls: candidato en [[Motor para volver al bosque]].

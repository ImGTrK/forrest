# Estudios de Higgsfield para Forrest

Las imágenes de esta carpeta son referencias generadas para el juego. Las tres
`contract_*_16px.png` muestran a Higgsfield el tamaño y la disposición exacta
de las celdas que consume Godot. `characters_reference.png`,
`environment_reference.png` e `items_reference.png` son la primera exploración
visual. `player_sheet_attempt_16px.png`, `player_three_views_16px.png`,
`enemy_sheet_attempt_16px.png`, `world_sheet_attempt_16px.png` e
`items_sheet_attempt_16px.png` son iteraciones con el contrato de 16 px.

Higgsfield conservó bien la identidad visual, pero no una malla de píxeles
matemáticamente exacta. `tools/trace_higgsfield_refs.py` reduce las mejores
formas a los tamaños reales y produce `native_preview/` y `native_studies.png`.
`tools/build_higgsfield_art.py` selecciona esos estudios y retoca a mano los
píxeles esenciales. Los archivos finales que lee Godot están en `assets/`.
`preview_player_sheet_8x.png` muestra los 64 frames finales; `preview_player_directions.png`
destaca las ocho vistas a 8× y `preview_enemy_frames.png` los dos frames a 16×.
Todas estas vistas usan filtro Nearest.

Para editar: abrí los PNG finales de `assets/` a escala **100 %** o con zoom
entero y mantené sus dimensiones, transparencia y orden de frames. La
[paleta GIMP](../../assets/PALETA_FORREST.gpl) recoge los 42 colores usados.
Las referencias originales del usuario orientaron el ambiente general; los
personajes y objetos de esta carpeta se diseñaron para Forrest.

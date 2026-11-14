# Arte — lista de sprites

> Esta lista es el contrato técnico de lo que **ya existe**. Para la guía completa (dirección de arte,
> lo que viene en la 0.2, sonido y orden sugerido) mirá [docs/GUIA_ARTE_Y_SONIDO.md](../docs/GUIA_ARTE_Y_SONIDO.md).

Los **32 PNG integrados** son bases originales de pixel art, con las medidas exactas que espera el código.
Podés abrirlos y editarlos directamente en un editor de pixel art. Para reemplazar uno, conservá
el nombre, tamaño y orden de frames: Godot lo reimporta al abrir el editor.

La referencia visual es [PREVIEW_ARTE_BASE_2X.png](../docs/PREVIEW_ARTE_BASE_2X.png)
y la [lámina de los 32 sprites](../docs/CONTACTO_SPRITES_BASE.png);
la escena de inspección está en `scenes/ArtPreview.tscn` (F6).
`tools/build_higgsfield_art.py` reconstruye la tanda final usando los estudios de `docs/higgsfield/native_preview/`.
`tools/trace_higgsfield_refs.py` vuelve a extraer esos estudios de las hojas generadas con Higgsfield;
`tools/draw_base_art.py` reconstruye la primera base y los ocho sprites discretos de HUD/terreno.
**Los tres scripts de dibujo sobrescriben PNG**: guardá tus retoques antes de ejecutarlos.
`tools/render_art_preview.py` actualiza las vistas previas.

- Resolución base: tiles de **16×16 px**. Filtro Nearest (pixel art nítido) ya configurado.
- Fondo transparente donde corresponda (todo menos el tileset).
- Origen: los sprites del mundo se dibujan desde la **esquina superior izquierda** de su celda;
  el jugador va **centrado** (con un ajuste de 2 px hacia arriba).
- Si un sprite necesita otro tamaño, avisá: hay que cambiar también la colisión/tamaño en el código o en el `.tres`.

## Paleta y contornos

Base primaveral: verde salvia `#84AB78`, jade `#4C9465`, hoja clara `#90C57B`,
camino crema `#F6E3BE`, flor rosa `#F2BAC5`, rojo bermellón `#D34B55`,
sombra ciruela `#3B2D45` y madera cálida `#9A6550`. La paleta completa de 42 colores
está en [`PALETA_FORREST.gpl`](PALETA_FORREST.gpl) y en `tools/draw_base_art.py` (`P`).
Dibujá de día: la noche se oscurece por código.

Contorno de **1 px** marrón oscuro `#4B373B` en vegetación y detalles del entorno;
casi negro `#211C2B` en jugador, enemigos, rocas recolectables y objetos de uso.
El borde iluminado puede llevar crema, pero nunca suavizado. La luz viene de arriba a la izquierda.
Las flores son frecuentes en árboles y arbustos; el pasto se mantiene discreto para que la grilla no haga ruido.

## Tilesets — `assets/tilesets/`

| Archivo | Tamaño | Contenido |
|---|---|---|
| `terrain.png` | **256×128** | 16×8 tiles de 16×16. La fila 0 empieza igual que antes: 0 pasto · 1 pared (tiene colisión) · 2 piso del pueblo · 3 camino. El resto: bases tranquilas, variantes con detalle y 6 juegos de transición tipo isla (camino, tierra, agua, pasto oscuro, cerco, ruinas). Mapa completo en `docs/GUIA_ARTE_Y_SONIDO.md` §2.1; lo usa el hito 9 |

## Personaje — `assets/sprites/player/`

| Archivo | Tamaño | Contenido |
|---|---|---|
| `player.png` | **256×256** | 8×8 frames de **32×32** dibujados al doble de detalle; en el juego el sprite va con **escala 0.5** (`Player.tscn`), así ocupa un tile y con la ventana ×2 cada píxel de la hoja se ve 1:1. **Filas** = dirección: 0 S · 1 SW · 2 W · 3 NW · 4 N · 5 NE · 6 E · 7 SE. **Columnas** 0-3 idle, 4-7 caminar (4 fps). Pies en la fila ~29 del frame. La colisión es 10×6 a los pies |
| `sword.png` | **16×16** | Espada del swing, dibujada **apuntando hacia arriba** (el código la rota) |

## Enemigos — `assets/sprites/enemies/`

| Archivo | Tamaño | Contenido |
|---|---|---|
| `enemy_basic.png` | **32×16** | 2 frames originales de 16×16: frame 0 parpadeo (0.1 s), frame 1 normal (2 s). Mira a la derecha; el código lo espeja |

## Mundo — `assets/sprites/world/`

| Archivo | Tamaño | Usado en |
|---|---|---|
| `chest.png` | **16×16** | Almacén del pueblo (`scenes/entities/chest.gd`) |
| `tree.png` | **96×32** | 3 variantes de 32×32 (cerezo, ciprés, níspero). Árbol, da Madera (`data/spawns/tree.tres`, ocupa 2×2 tiles). El juego elige una por posición |
| `rock.png` | **48×16** | 3 variantes de 16×16 (redonda, puntuda, chata con musgo). Roca, da Piedra (`data/spawns/rock.tres`) |
| `iron_vein.png` | **16×16** | Veta, da Hierro (`data/spawns/iron_vein.tres`) |
| `bush.png` | **48×16** | 3 variantes de 16×16 (con flor, doble, con bayas). Arbusto decorativo, bloquea el paso (`data/spawns/bush.tres`) |
| `board.png` | **32×32** | Tablón de misiones, 2×2 tiles; solo las patas (abajo) tienen colisión (`scenes/entities/board.gd`) |
| `bench.png` | **32×16** | Mesa de trabajo (crafting), horizontal, 2×1 tiles (`scenes/entities/bench.gd`) |
| `bed.png` | **16×32** | Cama del pueblo, vertical, ocupa 1×2 tiles (`scenes/entities/bed.gd`) |

## Íconos de ítems — `assets/sprites/items/`

El ícono mide **`grid_size` × 16 px** del ítem (lo que ocupa en la mochila). En el almacén se achica a una celda.

| Archivo | Tamaño | Usado en |
|---|---|---|
| `wood.png` | **16×32** | Madera: ocupa **1×2 celdas** en la mochila (`data/items/wood.tres`) |
| `stone.png` | **16×16** | Piedra |
| `iron.png` | **16×16** | Hierro |
| `stone_axe.png` | **16×32** | Hacha de piedra (1×2 en la mochila). Equipo: **mango abajo, cabeza arriba** |
| `stone_pickaxe.png` | **16×32** | Pico de piedra |
| `wood_sword.png` | **16×32** | Espada de madera |
| `iron_axe.png` | **16×32** | Hacha de hierro |
| `iron_pickaxe.png` | **16×32** | Pico de hierro |
| `lantern.png` | **16×16** | Linterna (1×1 en la mochila) |
| `oil.png` | **16×16** | Frasco de aceite para la linterna (1×1) |
| `iron_sword.png` | **16×32** | Espada de hierro (el sprite del swing sigue siendo `player/sword.png`) |

## UI / HUD — `assets/sprites/ui/`

La UI se ve al doble (viewport 640×360 escalado a 1280×720), así que 8 px de ícono ≈ alto de una línea de texto.

| Archivo | Tamaño | Contenido |
|---|---|---|
| `hearts/heart_full.png` | **16×16** | Corazón lleno (= 2 de vida), redibujado con la paleta de Forrest |
| `hearts/heart_half.png` | **16×16** | Medio corazón |
| `hearts/heart_empty.png` | **16×16** | Corazón vacío |
| `slot.png` | **18×18** | Celda vacía de la grilla de inventario (16 px de ícono + 1 px de borde por lado) |
| `icon_weight.png` | **8×8** | Ícono junto a la barra de peso (la barra reusa `energy_bar_*`, teñida azul/rojo) |
| `icon_clock.png` | **8×8** | Ícono junto a la hora |
| `icon_energy.png` | **8×8** | Ícono junto a la barra de energía |
| `energy_bar_under.png` | **64×8** | Fondo/marco de la barra de energía |
| `energy_bar_fill.png` | **64×8** | Relleno de la barra. **Dibujalo en blanco/grises**: el HUD lo tiñe verde → amarillo → rojo según el cansancio |

## Fuente — `assets/fonts/`
`BoldPixels.ttf` (de BarrenRoots), configurada sin suavizado. Se usa como fuente por defecto en `scenes/ui/theme.tres` a 16 px.
⚠️ No es arte propio: revisá su licencia antes de publicar.

## Fuentes antiguas de Aseprite — `assets/source/`
Los `.ase` de BarrenRoots (`EnemyTemp`, `PlayerDash`, `temp_Sword`) quedan como referencia histórica;
**ninguno de los PNG nuevos depende de ellos**. Godot no lee `.ase`; si necesitás inspeccionarlos,
podés usar el conversor incluido:
```bash
python tools/ase2png.py <carpeta_destino> assets/source/EnemyTemp.ase
```
`PlayerDash.ase` (4 frames, solo mirando abajo) todavía no se usa: el dash por ahora es el sprite semitransparente.

## Regenerar placeholders
Si borrás un PNG y querés que vuelva el placeholder (nunca pisa archivos existentes):
```bash
GODOT="/d/Desktop/Archivos/Godot/Godot_v4.7.1-stable_win64_console.exe"
"$GODOT" --headless --path . --script res://tools/generate_placeholders.gd
"$GODOT" --headless --path . --import
```
Cada sprite nuevo que agregue un hito se suma a `tools/generate_placeholders.gd` y a esta tabla.

## Arte de la 0.2 dibujado por código — `tools/art/`
El terreno, las variantes de árbol/roca/arbusto, la decoración y los eventos raros del hito 9 se
dibujan con `tools/art/draw_world.gd` (pixel art nativo, paleta Forrest, luz arriba-izquierda,
contorno de 1 px). Todavía no los usa el generador: llegan con el hito 9.
Vista previa: `docs/PREVIEW_ARTE_V02.png` (escena de muestra) y `docs/CONTACTO_ARTE_V02.png` (cada PNG ×4).

| Archivo (`sprites/world/`) | Tamaño | Contenido |
|---|---|---|
| `deco_flowers.png` | 64×16 | 4 matas: cerezo silvestre, margaritas, campanillas, tulipanes rosados |
| `deco_tall_grass.png` | 32×16 | 2 frames de pasto alto meciéndose |
| `deco_mushrooms.png` | 32×16 | 2 grupos de hongos: crema y rosados |
| `deco_stump.png` | 16×16 | Tocón con anillos y musgo |
| `deco_log.png` | 32×16 | Tronco caído con musgo y un hongo |
| `deco_boulder.png` | 32×32 | Roca grande facetada con musgo (no se rompe) |
| `deco_ruin_pillar.png` | 16×32 | Columna rota con enredadera |
| `deco_ruin_wall.png` | 32×16 | Muro bajo de bloques con musgo |
| `deco_lilypad.png` | 32×16 | 2 grupos de nenúfares (uno con flor de loto) |
| `ancient_tree.png` | 48×48 | Árbol antiguo con cuerda sagrada (shimenawa) y luciérnagas |
| `lost_chest.png` | 32×16 | Cofre perdido: cerrado / abierto con brillo |
| `shiny_vein.png` | 64×16 | Veta brillante, 4 frames de destello |
| `campfire.png` | 64×16 | Fogata, 4 frames |
| `camp_tent.png` | 32×32 | Carpa del campamento enemigo |

Regenerar (pisa estos PNG; versioná antes lo que retoques a mano):
```bash
"$GODOT" --headless --path . --script res://tools/art/draw_world.gd                   # todo
"$GODOT" --headless --path . --script res://tools/art/draw_world.gd -- solo=trees     # una parte
"$GODOT" --headless --path . --script res://tools/art/preview_v02.gd                  # vistas previas
```

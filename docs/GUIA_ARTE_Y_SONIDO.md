# Guía de arte y sonido

Todo lo visual y sonoro que tiene el juego hoy y lo que va a necesitar en la **0.2** (hitos 8-12),
con medidas, frames y una idea de cómo se ve o suena cada cosa.

- **Contrato técnico de lo que ya existe** (nombres exactos, orígenes, colisiones): [assets/README.md](../assets/README.md).
- **Lo nuevo** tiene medidas *propuestas*. Se vuelven definitivas cuando el hito lo programa: ahí creo el
  placeholder con esa medida exacta y lo paso a `assets/README.md`. Si dibujás algo antes y te sale mejor
  con otro tamaño, avisame y lo adapto.

**Estados:** **Base** = sprite original editable ya integrado · **Placeholder** = cuadrado temporal de un hito futuro
· **Nuevo** = todavía no existe en el juego. Los 32 PNG actuales son Base; mirá la
[vista previa a 2×](PREVIEW_ARTE_BASE_2X.png), la [lámina de sprites](CONTACTO_SPRITES_BASE.png)
o abrí `scenes/ArtPreview.tscn` con F6.

**Prioridad:** ★★★ se nota muchísimo / ★★ suma bastante / ★ detalle.

---

## 1. Dirección de arte (reglas para todo)

| Regla | Detalle |
|---|---|
| Grilla | Tiles de **16×16**. El viewport es 640×360 escalado ×2: un tile se ve de 32 px en pantalla |
| Perspectiva | Top-down con un poco de frente (3/4); los objetos altos (árboles, tablón) muestran su cara frontal |
| Luz | Desde **arriba a la izquierda**. Sombra suave abajo-derecha en objetos del mundo |
| Contorno | **1 px** marrón oscuro (`#4B373B`) en árboles y arbustos, con crema en bordes iluminados; casi negro (`#211C2B`) en jugador, enemigos y objetos de uso. Sin antialiasing |
| Paleta | Primaveral: salvia `#84AB78`, jade `#4C9465`, crema `#F6E3BE`, rosa flor `#F2BAC5`, bermellón `#D34B55`, ciruela `#3B2D45`. Lista de 42 colores en `assets/PALETA_FORREST.gpl`. El bosque de noche se oscurece por código: dibujá todo de día |
| Floración | Frecuente en copas y arbustos; el pasto conserva poco detalle para que el patrón de 16 px no distraiga |
| Legibilidad | Lo que se puede romper/recolectar debe destacarse del fondo (más contraste o un brillo). La decoración, más apagada que el pasto |
| Colores por escalón | Madera = marrones cálidos · Piedra = grises · Hierro = gris azulado · Cristal (nuevo) = turquesa/violeta brillante. Las herramientas heredan el color de su material |
| Animaciones | Pocas y legibles: 2-4 frames, 4-8 fps. Los frames de una hoja van **de izquierda a derecha** y las variantes **en filas** |

---

### Implementación de la tanda actual

Las tres hojas iniciales y las iteraciones enfocadas se guardan en [`docs/higgsfield/`](higgsfield/).
Se enviaron a Higgsfield plantillas del **contrato de 16 px** del jugador, del mundo y de los ítems.
El generador respetó bien la secuencia de vistas del jugador y los dos estados del enemigo, pero sus PNG
de 1024 px no mantenían una cuadrícula exacta al reducirlos. Por eso las hojas son **referencias de diseño**:
`tools/trace_higgsfield_refs.py` extrae estudios a tamaño real y `tools/build_higgsfield_art.py` corrige
manualmente siluetas, ojos, flores, contornos y materiales antes de escribir los 32 PNG del juego.
La hoja del jugador sigue siendo **128×128**, con ocho direcciones y ocho frames de 16×16 por fila.
Los recursos son PNG editables; podés retocarlos directamente en Aseprite, LibreSprite o tu editor preferido.
El tema de UI usa ciruela, crema y rosa de la misma paleta. Los otros ocho sprites discretos (terreno,
espada de golpe y seis elementos pequeños del HUD) se dibujan directamente a tamaño nativo.

Para reconstruir exactamente la tanda y sus vistas previas:

```bash
python -B tools/trace_higgsfield_refs.py
python -B tools/build_higgsfield_art.py
python -B tools/render_art_preview.py
```

Estos comandos **sobrescriben** los PNG integrados; guardá primero cualquier edición personal.

---

## 2. Tilesets

### 2.1 Terreno — `assets/tilesets/terrain.png` ★★★

> **Base hecha (2026-11-13):** dibujada por código (`tools/art/draw_world.gd`). Vista previa armada con
> las transiciones en `docs/PREVIEW_ARTE_V02_2X.png`. Se puede retocar a mano manteniendo la grilla.

**Tamaño: 256×128** (16×8 tiles de 16×16). La fila 0 empieza igual que la versión original
(pasto · pared · piso · camino), así que el juego actual sigue funcionando.

**Filas 0-1 — bases y variantes.** Las bases son **tranquilas** (casi lisas) y son las que más se repiten;
las variantes con detalle se mezclan con poca probabilidad (ej. 1 de cada 6 tiles de pasto).

| Fila | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **0** | Pasto | Pared (cerco) | Piso pueblo | Camino | Tierra | Pasto oscuro | Agua | Ruina | Pasto matitas | Pasto pétalos | Pasto florcitas | Pasto piedritas | Camino var. | Tierra var. | Piso var. | Pasto oscuro var. |
| **1** | Cerco con flores | Cerco var. | Agua con brillo | Ruina rota | Ruina con musgo | Pasto tranquilo var. | Camino var. 2 | — | — | — | — | — | — | — | — | — |

**Filas 2-7 — juegos de transición sobre pasto** (estilo "isla", bordes orgánicos como el tileset de
referencia de BarrenRoots, con nuestro estilo). Cada juego ocupa 5×3 tiles:

| | col +0 | col +1 | col +2 | col +3 | col +4 |
|---|---|---|---|---|---|
| **fila +0** | esq. externa sup-izq | borde arriba | esq. externa sup-der | esq. interna sup-izq | esq. interna sup-der |
| **fila +1** | borde izq | centro | borde der | esq. interna inf-izq | esq. interna inf-der |
| **fila +2** | esq. externa inf-izq | borde abajo | esq. externa inf-der | — | — |

"Esquina interna sup-izq" = el terreno ocupa todo menos un rincón de pasto arriba a la izquierda.

| Juego | Origen (col, fila) | Borde |
|---|---|---|
| Camino | (0, 2) | el pasto queda "un escalón arriba" y le hace sombra al camino |
| Tierra / claro | (5, 2) | igual que el camino, en tonos tierra |
| Agua / estanque | (10, 2) | barranca marrón arriba, espuma abajo-derecha |
| Pasto oscuro | (0, 5) | borde tramado suave (sin línea) |
| Cerco | (5, 5) | contorno ciruela abajo-derecha y sombra sobre el pasto |
| Ruinas | (10, 5) | musgo y juntas en el borde |

Las regiones de cada terreno tienen que medir **al menos 2 tiles de ancho** para que las piezas encajen.
El agua y la pared tienen colisión.

**Ideas:**
- **Pared** = un muro de arbustos o troncos muy tupido que dice "por acá no se pasa". Es lo que más se ve en los bordes de cada zona.
- **Pasto oscuro** marca el piso bajo las arboledas densas (plantilla "arboleda").
- **Ruinas** = piedras talladas viejas, medio tapadas por pasto, para la plantilla "ruinas".
- La base tiene que ser **tranquila**: el detalle va en las variantes (poca probabilidad) y en la decoración (sprites).

### 2.2 Pueblo (hito 9 o 12) ★★

Hoy el pueblo es piso + paredes. Unos pocos objetos lo hacen sentir hogar:

| Archivo (propuesto) | Medida | Estado | Idea |
|---|---|---|---|
| `world/fence.png` | 64×16 (4 tiles: horizontal, vertical, esquina, poste) | Nuevo | Cerca de madera que rodea el pueblo |
| `world/lamppost.png` | 16×32 | Nuevo | Farol; de noche el código le pone luz |
| `world/well.png` | 32×32 | Nuevo | Pozo decorativo en el centro |
| `world/house_wall.png` | 48×48 | Nuevo | Frente de la casita donde está la cama (solo decoración) |
| `world/forest_gate.png` | 32×32 | Nuevo | Arco o portón de salida al bosque, para que se entienda dónde se sale |

---

## 3. Personaje — `assets/sprites/player/`

| Archivo | Medida | Estado | Prioridad | Idea |
|---|---|---|---|---|
| `player.png` | **384×216** (16×9 frames de 24×24, escala 1) | ✅ Hito 10: rig por partes (`tools/art/draw_player.gd`) | ★★★ | Ver tabla de abajo |
| `sword.png` | 16×16 | Base | ★ | Espada del swing, apuntando hacia arriba (el código la rota) |
| ~~`player_death.png`~~ | — | ✅ Va en la fila 8 de `player.png` | — | Golpe, rodillas, tendido (cabeza a la izquierda; cols 4-7 espejo) |
| `slash.png` | 96×32 (3 frames de 32×32) | Nuevo (hito 10) | ★★ | Estela del golpe en arco, dibujada **hacia arriba**; el código la rota. Blanca/gris: se tiñe por arma |

**Hoja del jugador (hito 10):** 8 filas por dirección (igual que ahora: 0 S · 1 SW · 2 W · 3 NW · 4 N · 5 NE · 6 E · 7 SE) y 16 columnas:

| Columnas | Animación | Frames | Notas |
|---|---|---|---|
| 0-3 | Quieto | 4 | Respira (cabeza 1 px) y parpadea |
| 4-7 | Caminar | 4 | Dos pasos; el cuerpo sube en el paso intermedio |
| 8-11 | **Atacar** | 4 | Brazo atrás → estocada → seguimiento → vuelta (en los 0.2 s del ataque) |
| 12-15 | **Dash** | 4 | Se agacha, se lanza inclinado con los brazos atrás, se endereza |

Fila 8 = muerte. SW, W y NW son el espejo de SE, E y NE (la luz queda arriba a la derecha en esas filas).

El daño recibido se muestra con un flash blanco por código, así que no hace falta animación de "herido".

---

## 4. Enemigos — `assets/sprites/enemies/`

**Formato estándar de enemigo (hito 10):** una hoja con 4 filas y 4 columnas. Mira a la derecha; el código lo espeja.

| Fila | Animación | Frames |
|---|---|---|
| 0 | Quieto | 2-4 (repetí frames si usás menos) |
| 1 | Moverse | 4 |
| 2 | Amago + ataque | 4 (los 2 primeros son el amago: tiene que verse que **va a atacar**) |
| 3 | Muerte | 4 |

| Archivo | Medida | Estado | Prioridad | Idea |
|---|---|---|---|---|
| `enemy_basic.png` | 32×16 hoy → **64×64** (formato estándar) | Base | ★★ | El que ya existe. Persigue y muerde de cerca |
| `enemy_ranged.png` | 64×64 (frames de 16×16) | Nuevo (hito 10) | ★★★ | **Lanzador**: criatura pequeña y quieta (un hongo que escupe esporas, una planta con vainas). Mantiene distancia y dispara |
| `projectile_spore.png` | 16×8 (2 frames de 8×8) | Nuevo (hito 10) | ★★ | Lo que dispara el lanzador. Color llamativo, que se vea sobre el pasto |
| `enemy_charger.png` | **96×96** (frames de 24×24) | Nuevo (hito 10) | ★★★ | **Embestidor**: bicho grande y pesado (jabalí de musgo, escarabajo cornudo). Se queda quieto, raspa el piso (amago largo) y embiste en línea recta. Si choca contra un árbol, queda aturdido |
| `enemy_hp_bar.png` | 16×6 (2 filas de 16×3: marco y relleno) | Nuevo (hito 10) | ★ | Barrita sobre el enemigo herido. Relleno en blanco: el código lo tiñe |

---

## 5. Mundo — `assets/sprites/world/`

### 5.1 Lo que ya existe

| Archivo | Medida | Estado | Prioridad | Idea |
|---|---|---|---|---|
| `tree.png` | 32×32 | Base | ★★★ | Árbol común, da madera. Copa ancha, tronco visible abajo |
| `rock.png` | 16×16 | Base | ★★★ | Roca gris, da piedra |
| `iron_vein.png` | 16×16 | Base | ★★★ | Roca con vetas gris azuladas que brillan un poco |
| `bush.png` | 16×16 | Base | ★★ | Arbusto decorativo, bloquea el paso |
| `chest.png` | 16×16 | Base | ★★ | Baúl del almacén en el pueblo |
| `bed.png` | 16×32 | Base | ★★ | Cama vertical (cabecera arriba) |
| `bench.png` | 32×16 | Base | ★★ | Mesa de trabajo con herramientas encima |
| `board.png` | 32×32 | Base | ★★ | Tablón de misiones con papelitos clavados; solo las patas tienen colisión |

### 5.2 Variantes (hito 9) ★★★

> **Base hecha (2026-11-13):** dibujada por código con la paleta Forrest; ver `docs/CONTACTO_ARTE_V02.png`.

El código elige una al azar. Es la forma más barata de que el bosque no se vea vacío ni repetido.

| Archivo (propuesto) | Medida | Idea |
|---|---|---|
| `tree.png` | 32×32 → **96×32** (3 variantes) | Copa redonda, copa alta, copa con frutos o pino |
| `rock.png` | 16×16 → **48×16** (3 variantes) | Distintas formas |
| `bush.png` | 16×16 → **48×16** (3 variantes) | Una con bayas |

### 5.3 Decoración nueva (hito 9) ★★★

> **Base hecha (2026-11-13):** dibujada por código con la paleta Forrest; ver `docs/CONTACTO_ARTE_V02.png`.

La decoración "blanda" **no bloquea**: el jugador la pisa. Se reparte agrupada para que la zona se sienta viva.

| Archivo (propuesto) | Medida | Bloquea | Idea |
|---|---|---|---|
| `deco_flowers.png` | 64×16 (4 variantes) | No | Matas de flores de distintos colores |
| `deco_tall_grass.png` | 32×16 (2 frames) | No | Pasto alto que se mece (anima lento) |
| `deco_mushrooms.png` | 32×16 (2 variantes) | No | Hongos chiquitos, pegados a troncos o árboles |
| `deco_stump.png` | 16×16 | Sí | Tocón cortado |
| `deco_log.png` | 32×16 | Sí | Tronco caído horizontal |
| `deco_boulder.png` | 32×32 | Sí | Roca grande, no se rompe (plantilla "pedregal") |
| `deco_ruin_pillar.png` | 16×32 | Sí | Columna rota (plantilla "ruinas") |
| `deco_ruin_wall.png` | 32×16 | Sí | Pedazo de muro bajo con musgo |
| `deco_lilypad.png` | 32×16 (2 variantes) | No | Nenúfares sobre el agua del estanque |

### 5.4 Eventos raros (hito 9) ★★★

> **Base hecha (2026-11-13):** dibujada por código con la paleta Forrest; ver `docs/CONTACTO_ARTE_V02.png`.

Aparecen poco y tienen que verse **especiales** desde lejos: son el "encontré algo raro".

| Archivo (propuesto) | Medida | Idea |
|---|---|---|
| `ancient_tree.png` | 48×48 | **Árbol antiguo**: enorme, retorcido, con brillo en la corteza. Da madera de alta calidad con rasgo garantizado |
| `lost_chest.png` | 32×16 (2 frames: cerrado, abierto) | **Cofre perdido**: viejo, con musgo, distinto al del pueblo. Tiene botín |
| `shiny_vein.png` | 64×16 (4 frames de brillo) | **Veta brillante**: veta con un destello que recorre la piedra |
| `campfire.png` | 64×16 (4 frames de fuego) | **Campamento enemigo**: fogata en el centro de un grupo de enemigos |
| `camp_tent.png` | 32×32 | Carpa rústica del campamento |

### 5.5 Tercer escalón (hito 11) ★★

| Archivo (propuesto) | Medida | Idea |
|---|---|---|
| `crystal_vein.png` | 16×16 | Roca con cristales turquesa/violeta saliendo. Necesita pico de hierro |

---

## 6. Íconos de ítems — `assets/sprites/items/`

El ícono mide lo que ocupa en la mochila (1×1 celda = 16×16, 1×2 = 16×32). Las herramientas van con
**mango abajo y cabeza arriba**. Fondo transparente.

| Archivo | Medida | Estado | Prioridad | Idea |
|---|---|---|---|---|
| `wood.png` | 16×32 | Base | ★★★ | Tronquito vertical |
| `stone.png` | 16×16 | Base | ★★★ | Piedra gris |
| `iron.png` | 16×16 | Base | ★★★ | Pepita o lingote rústico de hierro |
| `stone_axe.png` | 16×32 | Base | ★★★ | Hacha con cabeza de piedra atada |
| `stone_pickaxe.png` | 16×32 | Base | ★★★ | Pico de piedra atado |
| `wood_sword.png` | 16×32 | Base | ★★★ | Espada de madera tallada |
| `iron_axe.png` | 16×32 | Base | ★★★ | Hacha de hierro |
| `iron_pickaxe.png` | 16×32 | Base | ★★★ | Pico de hierro |
| `iron_sword.png` | 16×32 | Base | ★★★ | Espada de hierro |
| `lantern.png` | 16×16 | Base | ★★ | Linterna de piedra con vela |
| `oil.png` | 16×16 | Base | ★★ | Frasquito de aceite |
| `crystal.png` | 16×16 | Nuevo (hito 11) | ★★ | Cristal turquesa/violeta facetado |
| `crystal_axe.png`, `crystal_pickaxe.png`, `crystal_sword.png` | 16×32 c/u | Nuevo (hito 11, tentativo) | ★★ | Herramientas de tercer escalón. Puede que el cristal termine siendo mejora en vez de herramienta nueva: lo confirmo al diseñar el hito |

**Rasgos raros (hito 11):** no hace falta un ícono por rasgo. Alcanza con una marca general (sección 7)
y el código le pone un borde de color al ítem según su rareza.

---

## 7. UI / HUD — `assets/sprites/ui/`

La UI se ve al doble: 8 px de ícono ≈ alto de una línea de texto.

| Archivo | Medida | Estado | Prioridad | Idea |
|---|---|---|---|---|
| `hearts/heart_full.png`, `heart_half.png`, `heart_empty.png` | 16×16 c/u | Base | — | Redibujados con la paleta de Forrest |
| `slot.png` | 18×18 | Base | ★★ | Celda de la grilla del inventario (16 px + 1 px de borde) |
| `icon_clock.png` | 8×8 | Base | ★ | Reloj o sol |
| `icon_energy.png` | 8×8 | Base | ★ | Rayo o gota |
| `icon_weight.png` | 8×8 | Base | ★ | Pesa o mochila |
| `energy_bar_under.png` | 64×8 | Base | ★ | Marco de la barra |
| `energy_bar_fill.png` | 64×8 | Base | ★ | Relleno **en blanco/grises** (el código lo tiñe) |
| `panel.png` | 24×24 | Nuevo (hito 12) | ★★★ | Fondo de los paneles (inventario, crafting, tablón, menús). Se estira en **9 partes**: los 8 px de cada borde no se deforman, el centro sí. Idea: madera o pergamino |
| `button.png` | 48×16 (3 estados de 16×16: normal, hover, apretado) | Nuevo (hito 12) | ★★ | También en 9 partes (bordes de 4 px) |
| `equip_icons.png` | 32×8 (4 íconos de 8×8) | Nuevo (hito 12) | ★★ | Siluetas para los slots de equipo del HUD, en orden: hacha, pico, espada, linterna. Hoy son letras H/P/E/L |
| `mission_icons.png` | 24×8 (3 íconos de 8×8) | Nuevo (hito 11) | ★ | Tipos de misión: entregar (caja), profundidad (flecha/brújula), cazar (calavera o garra) |
| `icon_trait.png` | 8×8 | Nuevo (hito 11) | ★★ | Estrellita que marca un ítem con rasgo raro |
| `key_prompt.png` | 16×16 | Nuevo (hito 12) | ★ | Tecla "E" que aparece sobre lo que se puede usar |
| `logo.png` | 256×64 | Nuevo (hito 12) | ★★ | Título "Forrest" para el menú principal |
| `menu_bg.png` | 640×360 | Nuevo (hito 12) | ★ | Fondo del menú principal (puede ser una escena del bosque) |
| `app_icon.png` | 256×256 (dibujalo a 32×32 y escalalo ×8) | Nuevo (hito 12) | ★★ | Ícono del `.exe` y de la ventana |

## 8. Efectos — `assets/sprites/fx/` (hito 10) ★★

Todos en **blanco/grises** salvo que se diga otra cosa: el código los tiñe según qué se golpea.

| Archivo (propuesto) | Medida | Idea |
|---|---|---|
| `hit_spark.png` | 64×16 (4 frames) | Chispazo de impacto en enemigos |
| `chips.png` | 32×8 (4 frames de 8×8) | Astillas/pedacitos que saltan al golpear árbol o roca (se tiñen marrón o gris) |
| `dust.png` | 32×8 (4 frames de 8×8) | Polvo al hacer dash o al embestir |
| `poof.png` | 64×16 (4 frames) | Nube al morir un enemigo |
| `sparkle.png` | 32×8 (4 frames de 8×8) | Destello de ítem raro o rasgo encontrado |

Los **números de daño** usan la fuente BoldPixels: no hace falta dibujarlos.

---

## 9. Sonido — `assets/audio/` (hitos 10 y 12)

Plan: **assets libres** + algunos generados. Formatos: **`.wav`** para efectos cortos y **`.ogg`** para música y
ambientes en loop. Para cada archivo que bajes, anotá autor, link y licencia en `docs/CREDITOS.md`:
es obligatorio para pasar el `.exe` a tus amigos y más todavía si algún día se publica.

**Dónde buscar:**
- **Kenney.nl**: packs de UI, impactos y RPG, licencia CC0 (no exige crédito, pero dalo igual).
- **Freesound.org**: filtrá por licencia **CC0** o **CC-BY** (CC-BY exige crédito).
- **OpenGameArt.org**: música y efectos. Revisá la licencia de cada uno.
- **jsfxr / ChipTone**: generadores en el navegador para sonidos retro (golpes, pickups, saltos). Lo que generás es tuyo.

Mantené un estilo: todo retro/chiptune o todo "orgánico" (grabado). Mezclar los dos suena raro.

### 9.1 Música y ambiente — `assets/audio/music/`, `ambient/`

| Archivo (propuesto) | Duración | Idea |
|---|---|---|
| `music_menu.ogg` | loop 1-2 min | Tranquila, misteriosa |
| `music_village.ogg` | loop 1-2 min | Cálida, de descanso. Suena en el pueblo |
| `music_forest_day.ogg` | loop 2-3 min | Exploración, curiosa, no invasiva |
| `music_forest_night.ogg` | loop 2-3 min | Tensa y más vacía. El código cruza día ↔ noche suavemente |
| `amb_forest_day.ogg` | loop 30-60 s | Pájaros, viento en hojas |
| `amb_forest_night.ogg` | loop 30-60 s | Grillos, búho, crujidos |
| `amb_village.ogg` | loop 30-60 s | Fogón, algo de viento |

### 9.2 Efectos — `assets/audio/sfx/`

Si un efecto tiene varias versiones (`_1`, `_2`, `_3`), el código elige una al azar para que no canse.

**Jugador y combate**
| Archivo | Cuándo |
|---|---|
| `step_grass_1..3.wav` | Pasos en el bosque |
| `step_floor_1..3.wav` | Pasos en el pueblo |
| `swing.wav` | Atacar (al aire) |
| `hit_enemy_1..2.wav` | El golpe conecta con un enemigo |
| `dash.wav` | Dash |
| `player_hurt.wav` | Te pegan |
| `player_death.wav` | Morir / colapsar |
| `enemy_windup.wav` | El enemigo hace el amago (aviso importante para esquivar) |
| `enemy_death.wav` | Muere un enemigo |
| `spore_shoot.wav` / `spore_hit.wav` | Lanzador dispara / el proyectil pega |
| `charger_scrape.wav` / `charger_rush.wav` / `charger_stun.wav` | Embestidor raspa el piso / embiste / choca y queda aturdido |

**Recolección y herramientas**
| Archivo | Cuándo |
|---|---|
| `chop_1..3.wav` | Golpear un árbol |
| `mine_1..3.wav` | Golpear roca o veta |
| `clunk.wav` | Golpear algo sin la herramienta correcta |
| `harvest_break.wav` | El árbol o la roca se rompe |
| `pickup.wav` | Recurso a la mochila |
| `rare_find.wav` | Ítem con rasgo raro o evento raro (jingle corto y brillante, el sonido del "orgullo") |
| `tool_break.wav` | Una herramienta se rompe |
| `bag_full.wav` | No entra en la mochila |

**Inventario, crafting y pueblo**
| Archivo | Cuándo |
|---|---|
| `ui_open.wav` / `ui_close.wav` | Abrir/cerrar inventario, crafting, tablón |
| `item_pick.wav` / `item_drop.wav` | Agarrar/soltar ítem en la grilla |
| `item_rotate.wav` | Rotar |
| `item_discard.wav` | Tirar |
| `ui_click.wav` / `ui_hover.wav` | Botones |
| `ui_error.wav` | Acción imposible |
| `craft.wav` | Fabricar |
| `repair.wav` | Reparar |
| `mission_complete.wav` | Misión cumplida (fanfarria corta) |
| `upgrade.wav` | Mejora obtenida |
| `sleep.wav` | Dormir (transición a negro) |
| `rooster.wav` | Amanecer al despertar (opcional) |

**Mundo**
| Archivo | Cuándo |
|---|---|
| `zone_enter.wav` | Cruzar a otra zona (suave, casi imperceptible) |
| `lantern_on.wav` / `lantern_off.wav` | Prender/apagar la linterna |
| `oil_low.wav` | Al aceite le queda poco |
| `chest_open.wav` | Abrir el almacén o un cofre perdido |
| `night_falls.wav` | Empieza a oscurecer (un aviso: hay que pensar en volver) |

---

## 10. Orden sugerido para dibujar

Si vas en paralelo con los hitos, este orden aprovecha mejor cada sesión de dibujo:

1. **Tiles del bosque** (fila 0 y 1 de `terrain.png`) + **árbol, roca, veta, arbusto**: es el 80 % de lo que se ve en pantalla. Ataca directo lo de "se siente vacío".
2. **Decoración** (flores, pasto alto, tocón, tronco) y **eventos raros**: llegan en el hito 9.
3. **Íconos de las herramientas y recursos**: se miran todo el tiempo en el inventario.
4. **Ataque y dash del jugador** + **enemigos nuevos** + **efectos**: hito 10.
5. **UI** (panel, botones, íconos de equipo), **logo** e **ícono del .exe**: hito 12.
6. **Pueblo** (cerca, farol, pozo): cuando haya tiempo; suma ambiente pero no es urgente.

El sonido conviene buscarlo de una sola vez, en una tarde, siguiendo la lista de la sección 9 y
anotando las licencias a medida que bajás.

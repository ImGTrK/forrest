# Roadmap

Plan de avance por **hitos jugables**: cada hito termina con algo que se puede probar con F5,
tests headless que pasan y un commit/rama propia. El orden prioriza lo que le da identidad al juego
(reloj + energía) antes que lo heredado de BarrenRoots.

Leyenda: ✅ hecho · 🔜 siguiente · ⬜ pendiente

---

## ✅ Hito 1 — Loop mínimo
Hub fijo, bosque procedural con cortes tipo Isaac, presupuesto de dificultad por profundidad,
cache de sesión, recolección con ADN, almacén, minimapa, inventario que pausa.
Rama: `hito-1-loop-minimo`.

## ✅ Hito 2 — Reloj y energía (GDD §4.1)
Rama: `hito-2-reloj-energia`. Números de balance en `autoload/clock.gd` y `autoload/energy.gd`.
- [x] Reloj continuo (autoload `Clock`, 30 s reales = 1 h), pausado en menús; HUD con día, hora y franja
- [x] Energía: drenaje base 5/h + 0.4 por golpe
- [x] Rampa: 50% aviso · 20% debuffs (−30% velocidad, golpes 2× más lentos) · 0% colapso
- [x] Colapso → pierde 25% de lo cargado, guarda el resto, vuelve al hub y duerme a la fuerza
- [x] Cama en el hub: dormir pasa 5-9 h al azar y recarga 12/h
- [x] Curva por hora: multiplicador de presupuesto (×1 → ×2) y bonus de rareza (+0 → +3) en `Clock`
- [x] Tinte día/noche (CanvasModulate) — la niebla real va en el hito 6
- [x] Fix: tamaño de fuente del HUD (Theme propio en `scenes/ui/theme.tres`)
- Sprites nuevos: `bed.png`, `icon_clock.png`, `icon_energy.png`, `energy_bar_under.png`, `energy_bar_fill.png`

## ✅ Hito 3 — Combate (GDD §5) + arte de BarrenRoots
Rama: `hito-3-combate`. Port de `PlayerController.cs`, `EnemyAI.cs`, `HealthSystem.cs` y `UIHeartsManager.cs`.
- [x] Arte propio de BarrenRoots: hoja del jugador 8 direcciones animada, corazones, espada, enemigo, fuente BoldPixels
- [x] Componente `Health` reutilizable (señales, i-frames)
- [x] Ataque en arco de 120° hacia el mouse (o J), knockback, estela del swing
- [x] Dash con i-frames que atraviesa enemigos (Espacio/Shift), cuesta energía
- [x] Enemigo básico: idle → persecución → amago → golpe → retroceso; cuesta presupuesto, aparece desde profundidad 1 (o cerca del pueblo de noche); más vida con la profundidad
- [x] Muerte → pierde 50% de lo cargado, vuelve al hub con la vida llena (sin dormir). Dormir cura
- [x] HUD con corazones
- [x] Zonas de 40×40 (antes 50×50): ancho exacto de pantalla, menos vacío, más ritmo

## ✅ Hito 4 — Ítems e inventario (rescatado de BarrenRoots)
Rama: `hito-4-inventario`. Basado en `ItemData`, `ItemInstance`, "Inventario del Jugador",
"Almacén del Pueblo" y "UI Inventario" del canvas de Obsidian de BarrenRoots.
- [x] `ItemData` (Resource ≈ ScriptableObject) reemplaza a `ResourceType`: tipo de ítem, tamaño en grilla,
      rangos de ADN, stats invertidos, campos de herramienta para el hito 5. Los datos viven en `data/items/`
- [x] `ItemInstance` reemplaza a los Dictionary: stats rolados, calidad, peso, durabilidad (hito 5)
- [x] Stat `peso` en el ADN, invertido (menos es mejor): lo profundo pesa menos
- [x] Mochila en grilla 6×4 (`GridInventory`), cada ítem ocupa su tamaño (madera 1×2)
- [x] Límite 18 kg + debuff de sobrepeso ×0.5 (se acumula con el de energía)
- [x] Mochila llena → no se puede golpear el recurso (ni gasta energía)
- [x] UI: grilla con íconos y marca de calidad, tooltip con stats, barra de peso
- [x] Agarrar/soltar con vista previa (verde/amarillo/rojo), intercambio, rotar (R / clic der.), tirar (Supr/X), ordenar
- [x] Almacén en grilla al lado de la mochila, crece solo; Shift+clic para pasar directo
- [x] Nada se guarda automáticamente al volver: el jugador decide qué guarda y qué arriesga. El equipo nunca se pierde

## ✅ Hito 5 — Herramientas, durabilidad y crafting (juntos)
Rama: `hito-5-herramientas-crafting`. Se juntaron porque las herramientas salen del crafting y el
crafting necesita algo útil que fabricar. Diseño de "Sistema de Crafting", "RecipeData", "UI de Crafting",
"Durabilidad" y "Slot de Herramienta" del canvas de BarrenRoots.
- [x] Recursos con dureza y herramienta requerida; golpes = dureza / poder (a mano: poder 1.5)
- [x] Árbol y roca se pueden a mano (lento); la veta de hierro exige pico nivel 1
- [x] Hacha, pico y espada de piedra/madera (nivel 1) y de hierro (nivel 2): 6 recetas en `data/recipes/`
- [x] Stats del resultado = promedio ponderado de los stats de los materiales elegidos
- [x] Mesa de trabajo en el pueblo: recetas → elegir ejemplares (mochila + almacén) → vista previa con ±
- [x] Durabilidad Buena (>60%) / Desgastada / Rota; 1 por golpe; rota = como a mano. Reparar en la mesa (1 material)
- [x] Sin slots: se usa sola la mejor herramienta/arma de la mochila. HUD con hacha, pico y arma + durabilidad
- [x] La espada pasa a ser un ítem: daño = su poder (sin arma: puños, 1 de daño)

## ✅ Hito 6 — Noche y misiones
Rama: `hito-6-noche-misiones`. Implementación funcional; lo visual queda para después del MVP.
- [x] Visión nocturna en el bosque: se cierra 18-21 h, noche cerrada 21-03 h, se abre 03-05 h (overlay simple)
- [x] Linterna (equipo, se fabrica: 2 piedra + 1 madera; radio según la pureza de la piedra), L para prender/apagar
- [x] Aceite (consumible, se fabrica: 2 madera; minutos según la densidad). Se quema con el reloj; se apaga en el pueblo
- [x] Tablón de misiones en el pueblo (sin NPC): 3 activas — entregar recursos con calidad mínima, llegar a profundidad N, derrotar N enemigos
- [x] Recompensas = mejoras permanentes: +2 kg de capacidad, +10 de energía máxima o +1 corazón. Cada misión reclamada sube la dificultad de las nuevas
- [x] Fix: el almacén deja 2 filas libres (antes 1) para que siempre entre una madera parada

## ✅ Hito 7 — Guardado y menús (cierre del MVP)
Rama: `hito-7-guardado-menu`.
- [x] Guardado en disco (JSON, `user://save.json`): mochila y almacén con posición, rotación, ADN y durabilidad;
      mejoras, misiones, hora, energía y vida
- [x] Autoguardado al llegar al pueblo, al terminar de dormir/colapsar/morir y al cerrar la ventana en el pueblo.
      Cerrar en el bosque = volver al último guardado (el run se pierde)
- [x] Menú principal (Continuar / Nueva partida con confirmación / Salir) y menú de pausa (Esc)
- [x] Números de balance documentados en [BALANCE.md](BALANCE.md) para ajustarlos jugando

## 🎯 v0.1 — MVP completo
Los 7 hitos en `main`. Primer playtest: va por buen camino, pero el bosque se siente vacío y falta
algo que empuje a volver (ver `Ideas/Motor para volver al bosque.md` en el vault).

---

# v0.2 — Un bosque que da ganas de volver

**Objetivo:** runs cortas (**5-10 min**) donde siempre haya chance de encontrar algo raro del que estar
orgulloso, y un `.exe` para que lo prueben amigos. Reparto ~60% mecánicas / ~40% gráficos.
Detrás de cada hito: [GUIA_ARTE_Y_SONIDO.md](GUIA_ARTE_Y_SONIDO.md) para el arte y el sonido que necesita,
y las notas del vault (`Inicio.md`) para el diseño.

**Criterio de cierre de cada hito:** se prueba con F5, los tests headless pasan, las notas del vault y
[BALANCE.md](BALANCE.md) quedan al día, y los placeholders nuevos están en `assets/README.md`.

## ✅ Hito 8 — Base sólida
Rama: `hito-8-base-solida`. Preparar el código para sumar contenido sin duplicar lógica.
- [x] Clase base `Interactable` (colisión, sprite, cartel, foco, señal `used`); cofre, cama, mesa, tablón y
      recursos heredan y solo sobrescriben lo que cambia (`_on_interact`, `_collision_rect`, `_draw_overlay`)
- [x] Clase base `Enemy` con la máquina idle → chase → windup → attack → recover (+ knockback, stunned, dead),
      vida, drop y muerte. Los hijos sobrescriben `_chase_velocity`, `_wants_attack`, `_attack`, `_attack_velocity`,
      `_animate`, `_drop`… `EnemyBasic` es el primer hijo, sin cambiar cómo se juega
- [x] `SpawnEntry.enemy_script` elige qué hijo de `Enemy` aparece (sin tocar el generador para sumar enemigos)
- [x] Componente `HitFlash` (destello + sacudida) compartido por recursos y enemigos. `Health` ya lo era;
      el knockback queda en la base `Enemy` (lo heredan todos)
- [x] Guardado versionado: formato 2 con `game_version`, migraciones en cadena desde la 1 (las partidas de la 0.1
      siguen cargando) y rechazo con mensaje de guardados de una versión más nueva
- [x] Tests partidos en 8 suites (loop, tiempo/energía, combate, inventario, crafting, noche/misiones, guardado,
      entidades) con un runner común; se puede correr una sola con `-- --suite=nombre`. 159 checks
- [ ] ~~Partir `GameState`~~: evaluado, no hace falta todavía (325 líneas, una sola responsabilidad: lo que
      persiste). Se revisa si el hito 11 lo hace crecer
- Sin arte nuevo

## ✅ Hito 9 — Bosque vivo
Rama: `hito-9-bosque-vivo` (sobre `arte-base`). Ataca "se siente vacío".
- [x] Arte por código (`tools/art/`): `terrain.png` 256×128 con bases tranquilas, variantes y 6 juegos de
      transición tipo isla (camino, tierra, agua, pasto oscuro, cerco, ruinas); variantes de árbol, roca y arbusto
- [x] **Suelo por materiales**: cada zona guarda qué material hay en cada celda y `TerrainTiles.paint_ground()`
      elige solo bordes, esquinas y variantes (autotile propio, ≈ Rule Tile de Unity). El agua y el cerco tienen colisión
- [x] Cerco de 2 tiles alrededor de cada zona (las transiciones necesitan regiones de 2+)
- [x] **Plantillas de zona** (`scripts/zone_templates.gd`): bosque, claro, arboleda, estanque, ruinas, pedregal.
      Cada una pone manchas de suelo, cambia los pesos de la tabla de spawns y reparte su decoración
- [x] Decoración en grupos: flores, pasto alto animado, hongos y nenúfares (se pisan); tocón, tronco, roca grande,
      columnas y muros de ruina (bloquean)
- [x] **Eventos raros** (~25% de las zonas): árbol antiguo (3 maderas de buen ADN), cofre perdido (3 recursos,
      queda abierto), veta brillante animada (2 hierros, pide pico 1), campamento enemigo (carpa, fogata, cofre y
      3 enemigos). El minimapa marca las zonas con evento
- [x] Tests: el generador revisa en 200 runs que los caminos queden libres, nada caiga sobre agua o cerco, no queden
      franjas de 1 tile y todas las puertas se alcancen caminando; suite `forest` con el cofre, el árbol antiguo, la
      decoración y el suelo pintado. 176 checks
- [x] Jugador con hoja de 32×32 a escala 0.5 (detalle 1:1 con la ventana ×2)
- [x] **Pueblo rehecho** con el mismo suelo y decoración: plaza de piedra compacta (cama, almacén, mesa), camino
      con transiciones hasta la salida, tablón en su caminito, estanque con nenúfares, arboledas, árboles (no se
      talan), flores, pasto alto y roca grande. Sigue en ASCII en `scenes/world/hub.gd` para editarlo rápido

## ✅ Pasada de arte por código
Rama: `arte-codigo`. Ítems, herramientas, props del pueblo, veta de hierro, UI y enemigo básico redibujados con
`tools/art/draw_sprites.gd` (misma paleta, contorno y luz que el bosque). Queda la hoja del jugador para el hito 10.

## ✅ Hito 10 — Combate con peso
Rama: `hito-10-combate`.
- [x] **Lanzador**: se queda a distancia, apunta (amago visible) y dispara una espora; huye si te acercás
- [x] **Embestidor**: raspa el piso (amago largo), embiste en línea recta; si choca con un árbol o una pared queda aturdido
- [x] Proyectiles como clase propia (`Projectile`, configurable; los puede reusar un jefe a futuro)
- [x] Feedback: números de daño, flash blanco, sacudida de cámara corta, freno de 2-3 frames al golpear,
      partículas de impacto y astillas al recolectar, barra de vida sobre el enemigo herido
- [x] Animaciones del jugador: **rig por partes** horneado a la hoja (`tools/art/draw_player.gd`) con quieto,
      caminar, ataque, dash y muerte en 8 direcciones; frames de 24×24 a escala 1 (el personaje pasa a medir
      ~20 px, antes quedaba más chico que los enemigos). Capa procedural encima: estirón, aplastado y estela
- [x] Hoja estándar de enemigo (4 filas: quieto, moverse, amago+ataque, muerte), los tres enemigos la usan
- [x] Sistema de audio: `AudioManager` con buses (Music, SFX, UI), variantes al azar y efectos de combate y
      recolección **sintetizados** (placeholders) que se reemplazan soltando archivos en `assets/audio/sfx/`
- [x] Balance: dónde y desde qué profundidad aparece cada enemigo ([[BALANCE]] § Combate)
- Placeholders nuevos: guía §3, §4, §8 · Sonidos: guía §9.2 "Jugador y combate"

## ⬜ Hito 11 — Rasgos, cristal y tablón
Rama: `hito-11-rasgos`. Ataca "el crafting es básico" y "el tablón no deja elegir".
- [ ] **Rasgos raros**: 2-3 por material, como datos (`TraitData` .tres). Chance según profundidad, hora y eventos
- [ ] Al fabricar, la herramienta **hereda** los rasgos de los ingredientes elegidos; la vista previa los muestra
- [ ] Marca de rasgo y borde de rareza en los íconos; jingle de "hallazgo raro"
- [ ] **Veta de cristal** (pico nivel 2) y el cristal como material; decidir herramientas nivel 3 o mejora de las existentes
- [ ] **Tablón**: al reclamar se elige qué entregar (preseleccionados los peores); se ve la recompensa antes;
      misiones nuevas: "fabricá una herramienta de calidad ≥ X" y "traé un ítem con rasgo"
- [ ] Guardado: rasgos en el JSON (migración si hace falta)
- Placeholders nuevos: guía §5.5, §6 (cristal), §7 (`icon_trait`, `mission_icons`)

## ⬜ Hito 12 — Pulido y build
Rama: `hito-12-build`.
- [ ] Balance para runs de **5-10 min**: reloj, drenaje de energía, presupuesto, pérdidas (con partidas de prueba)
- [ ] Música y ambientes de día/noche con cruce suave; el resto de los efectos de la guía §9
- [ ] UI con arte: panel y botones en 9 partes, íconos de equipo, aviso de tecla "E", logo y fondo del menú
- [ ] Opciones: volumen por bus, pantalla completa, (opcional) reasignar teclas
- [ ] `docs/CREDITOS.md` con autor y licencia de cada asset de terceros (fuente incluida)
- [ ] Export de Windows: preset, ícono del `.exe`, nombre y versión visibles en el menú
- [ ] Checklist de prueba antes de pasarlo a amigos (partida nueva, cargar, morir, colapsar, cerrar en el bosque)
- Placeholders nuevos: guía §7 (UI) · Sonidos: el resto de la guía §9

## Abierto para la 0.2 o una 0.2.1
- [ ] **Motor para volver al bosque**: meta a largo plazo, colección, récords, pueblo que crece… se define
      charlando y puede sumar un hito entre el 11 y el 12

---

## ⬜ v0.3 y después (ideas, sin orden)
Ramas de experiencia · jefes · biomas · clima · comida (recarga parcial de energía) · NPC del tablón ·
efecto de noche lindo (luz con degradé, parpadeo) · pueblo pintado en el editor · dejar ítems tirados en el piso.
Detalle en `Ideas/Ideas para la 0.3.md`.

---

## Flujo de trabajo con arte
Cada vez que un hito agrega algo visible, se crea su **placeholder PNG con las medidas exactas**
en `assets/` y se lista en [assets/README.md](../assets/README.md). Para reemplazarlo, pisá el PNG
con el mismo nombre y tamaño; Godot lo reimporta solo y el código no cambia.

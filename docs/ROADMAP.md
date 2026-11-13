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

## 🔜 Hito 4 — Ítems e inventario (rescatado de BarrenRoots)
Base de ítems e inventario diseñada en el canvas de Obsidian de BarrenRoots
(`ItemData`, `ItemInstance`, "Inventario del Jugador", "Almacén del Pueblo", "UI Inventario").
Va antes que herramientas y crafting porque ambos necesitan ítems "de verdad".
- [ ] `ItemData` (Resource ≈ ScriptableObject) reemplaza a `ResourceType`: id, nombre, ícono,
      `item_type` (recurso / herramienta / arma / consumible), tamaño en grilla, rangos de stats (ADN),
      tipo y nivel de herramienta si aplica
- [ ] `ItemInstance` (clase runtime) reemplaza a los Dictionary actuales: referencia al `ItemData`,
      stats rolados, peso (sale del ADN), durabilidad y `is_broken` para herramientas
- [ ] Peso en el ADN de cada recurso (stat `peso`, "más bajo = mejor" → hay que soportar stats invertidos)
- [ ] Inventario del jugador: grilla 6×4, cada ítem ocupa su tamaño; `add / remove / has_space`
- [ ] Límite de peso + debuff de sobrepeso (velocidad ×0.5, como en BarrenRoots)
- [ ] Inventario lleno → no se puede recolectar (o el ítem queda en el piso)
- [ ] UI: grilla con íconos, tooltip con stats al pasar el mouse, barra de peso; almacén con depositar/retirar
- [ ] Muerte/colapso pierden ítems del inventario (ya existe, se adapta)
- Sprites nuevos: slot de grilla, fondo del panel, ícono de peso

## ⬜ Hito 5 — Herramientas y durabilidad
- [ ] Hacha / pico con nivel; cada recurso exige herramienta y nivel mínimo
- [ ] Durabilidad Buena (>60%) → Desgastada (20-60%) → Rota (0%); reparar en el hub
- [ ] Slots de herramienta y arma equipadas en el HUD
- [ ] Reemplaza el `hits` fijo de `SpawnEntry` por daño de herramienta vs. dureza
- Sprites nuevos: íconos de herramientas

## ⬜ Hito 6 — Crafting
Diseño de BarrenRoots: 3 paneles (recetas → materiales → preview con ▲▼), promedio ponderado de stats.
- [ ] `RecipeData` (Resource), mesa de crafting en el hub, `craft()` y `preview()` con la misma fórmula
- [ ] Primeras recetas: herramientas mejores, linterna
- Sprites nuevos: mesa de crafting, íconos de ítems crafteados

## ⬜ Hito 7 — Noche y misiones
- [ ] Visibilidad nocturna (shader/overlay), linterna que consume aceite
- [ ] Tablón de misiones (sin NPC): "traer X de Y", "llegar a profundidad N"
- Sprites nuevos: tablón, linterna, máscara de luz

## ⬜ Hito 8 — Pulido del MVP
- [ ] Arte final integrado, sonido básico, menú principal
- [ ] Guardado en disco del estado persistente (JSON, como el diseño de BarrenRoots)
- [ ] Balance de números (drenaje, % de pérdida, presupuesto) jugando

---

## Flujo de trabajo con arte
Cada vez que un hito agrega algo visible, se crea su **placeholder PNG con las medidas exactas**
en `assets/` y se lista en [assets/README.md](../assets/README.md). Para reemplazarlo, pisá el PNG
con el mismo nombre y tamaño; Godot lo reimporta solo y el código no cambia.

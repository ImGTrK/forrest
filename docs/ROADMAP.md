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

## 🔜 Hito 7 — Pulido del MVP
- [ ] Guardado en disco del estado persistente (va primero: sin esto no hay partida que dure)
- [ ] Menú principal / nueva partida
- [ ] Arte final integrado, sonido básico (post-MVP según lo acordado: primero sistemas, después estética)
- [ ] Balance de números (drenaje, % de pérdida, presupuesto) jugando

---

## Flujo de trabajo con arte
Cada vez que un hito agrega algo visible, se crea su **placeholder PNG con las medidas exactas**
en `assets/` y se lista en [assets/README.md](../assets/README.md). Para reemplazarlo, pisá el PNG
con el mismo nombre y tamaño; Godot lo reimporta solo y el código no cambia.

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

## 🔜 Hito 3 — Combate (GDD §5)
- [ ] Vida del jugador, swing en arco (Area2D), dash con i-frames
- [ ] Enemigo básico en la tabla de spawn (cuesta presupuesto), IA de persecución simple
- [ ] Muerte → al hub perdiendo un % mayor de lo cargado
- Sprites nuevos: enemigo, efecto de swing, corazones/barra de vida

## ⬜ Hito 4 — Herramientas y durabilidad
- [ ] Hacha / pico con nivel; cada recurso exige herramienta y nivel mínimo
- [ ] Durabilidad Buena → Desgastada → Rota; reparar en el hub
- [ ] Reemplaza el `hits` fijo de `SpawnEntry` por daño de herramienta vs. dureza
- Sprites nuevos: íconos de herramientas (3 estados)

## ⬜ Hito 5 — Inventario con peso y crafting
- [ ] Grilla de slots + límite de peso (peso sale del ADN), debuff de velocidad
- [ ] Mesa de crafting en el hub: elegir qué ejemplar usar, preview de stats
- [ ] Primeras recetas: herramientas mejores, linterna
- Sprites nuevos: mesa de crafting, slots de UI, íconos de ítems crafteados

## ⬜ Hito 6 — Noche y misiones
- [ ] Visibilidad nocturna (shader/overlay), linterna que consume aceite
- [ ] Tablón de misiones (sin NPC): "traer X de Y", "llegar a profundidad N"
- Sprites nuevos: tablón, linterna, máscara de luz

## ⬜ Hito 7 — Pulido del MVP
- [ ] Arte final integrado, sonido básico, menú principal, guardado en disco del estado persistente
- [ ] Balance de números (drenaje, % de pérdida, presupuesto) jugando

---

## Flujo de trabajo con arte
Cada vez que un hito agrega algo visible, se crea su **placeholder PNG con las medidas exactas**
en `assets/` y se lista en [assets/README.md](../assets/README.md). Para reemplazarlo, pisá el PNG
con el mismo nombre y tamaño; Godot lo reimporta solo y el código no cambia.

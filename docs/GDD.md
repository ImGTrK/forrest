# [Nombre Provisional] — Game Design Document (GDD)
### Roguelite de Exploración · Proyecto Godot 4 · Mini-GDD v1.0

> **Nota:** Título de trabajo pendiente. En este documento se lo llama "el Roguelite" — reemplazá cuando tengas nombre.

---

## 1. Identidad del Juego

**Género:** Roguelite de exploración con hub persistente (top-down)
**Motor:** Godot 4 (GDScript)
**Referentes:** Sistemas de ADN y recolección de BarrenRoots, estructura de hub+runs tipo Moonlighter/Hades

**Pitch en una frase:**
> *"Cada mañana salís del pueblo hacia un bosque que nunca es el mismo dos veces. Volvés antes de que oscurezca — o no volvés con nada."*

**Relación con BarrenRoots:**
Este proyecto **no es una secuela ni un reemplazo** — es un hermano menor que comparte la misma columna vertebral conceptual (ADN de recursos, herramientas, crafting) pero con un loop mucho más corto y sin la carga narrativa de un RPG completo. Sirve como:
- Proyecto de alcance controlado y terminable en paralelo a BarrenRoots
- Excusa para aprender Godot/GDScript sin la presión de un proyecto ya avanzado en Unity
- Banco de pruebas de mecánicas de generación procedural que eventualmente podrían informar decisiones futuras en BarrenRoots

**Fantasía del jugador:**
No sos un explorador que domina el territorio — sos alguien que se adapta a lo desconocido, run tras run, hasta que "lo desconocido" empieza a sentirse manejable gracias a tu propia mejora (no porque el mapa se haya vuelto predecible).

---

## 2. Concepto Central: ADN + Generación Procedural

### Lo que se hereda de BarrenRoots (sin rediseño)
El sistema de ADN de recursos es agnóstico a *dónde* vive el recurso en el mundo. La función que genera un recurso con stats aleatorios (`generar_recurso(tipo) -> stats`) no le importa si ese recurso está en una casilla fija del hub o en un tile generado al azar. Esto significa:
- Madera, Piedra, Hierro con sus 2-3 stats cada uno, igual que en BarrenRoots
- Herramientas con requisito de nivel para recolectar cada recurso
- Durabilidad de herramientas (Buena → Desgastada → Rota)

> Adaptar esto a GDScript es más sintaxis que rediseño — la lógica ya la pensaste una vez.

### Lo nuevo: generación por presupuesto de dificultad
En vez de definir tablas fijas ("tile tipo bosque = 4 enemigos, 3 rocas..."), cada tile se genera con un **presupuesto de dificultad** que escala con la distancia al hub (o con la "profundidad" del run):

```gdscript
# Pseudocódigo conceptual
var presupuesto = base_presupuesto + (distancia_al_hub * factor_escalado)

# El presupuesto se "gasta" tirando entidades de una tabla ponderada
# hasta que se agota, en vez de cantidades fijas
while presupuesto > 0:
    var entidad = tabla_ponderada.tirar()
    if entidad.costo <= presupuesto:
        spawnear(entidad)
        presupuesto -= entidad.costo
```

**Por qué esto es mejor que tablas fijas:**
- Escala infinitamente sin necesitar una fila nueva en una tabla por cada nivel de profundidad
- Un mismo sistema genera tiles fáciles y difíciles solo cambiando un número
- Menos contenido programado a mano = más rejugabilidad con menos trabajo (el objetivo que mencionaste)

> **Para el MVP:** no hace falta que la tabla ponderada sea sofisticada. 4-5 tipos de entidad (enemigo básico, roca, veta, árbol, camino) con un costo fijo cada uno es más que suficiente para probar el sistema.

---

## 3. Estructura del Mundo

### Hub (fijo, persistente)
2 tilemaps fijos, diseñados a mano, que **no** se regeneran nunca:
- **Casilla de gestión:** almacén, mesa de crafting, tablón de misiones (si aplica)
- **Casilla de acceso al bosque:** punto de entrada/salida del run

El hub es donde vive todo lo persistente entre runs: inventario del jugador, progresión, recursos almacenados, NPCs (si el MVP los incluye).

### Bosque (procedural, efímero)
Grid de zonas de **40×40 tiles** de arte de 16×16px → **640×640px por zona** (antes 50×50 / 800×800: se achicó tras probarlo porque se sentía vacío y lento; 640 coincide con el ancho de pantalla, así la zona se ve entera de lado a lado). Reglas:

1. **Al entrar a una tile por primera vez en la sesión actual del bosque:** se genera con el sistema de presupuesto descrito arriba y el resultado se guarda en un diccionario en memoria (`{Vector2i: TileData}`), **no en disco**.
2. **Si el jugador vuelve a esa tile en la misma sesión:** se usa el resultado ya guardado (no se regenera dos veces en el mismo run).
3. **Al volver al hub:** el diccionario se limpia por completo (`.clear()`), sin importar si el jugador durmió o no. La próxima vez que se entra al bosque, todo se tira de nuevo.

Esto es deliberadamente más simple que el sistema de respawn por game-time de BarrenRoots — acá no hace falta timers de regeneración, el reset es binario y ocurre al pisar el hub.

### Conectividad entre tiles
Cada tile genera caminos aleatorios hacia tiles adyacentes. Regla dura para el MVP:
- **Garantizado:** al menos 1 salida válida hacia una tile no visitada (para que nunca quede el jugador sin opciones)
- **Permitido:** callejones sin salida como resultado del azar — forman parte del riesgo, obligan a decidir entre seguir explorando o volver

> Decisión pendiente tuya: ¿el layout completo del "grafo" del día se genera de una vez al entrar al bosque, o se genera tile por tile a medida que el jugador avanza (más barato en cómputo, pero requiere cuidado para no generar un callejón sin salida real)? Para MVP recomiendo generar tile por tile bajo demanda — es más simple de programar y es exactamente el comportamiento que describiste.

---

## 4. El Ciclo de Run (Loop Principal)

```
Hub: gestionar recursos, craftear, revisar equipo
  → Entrar al bosque
  → Explorar tiles generados, combatir, recolectar
  → [Decisión constante: seguir, volver, o dormir]
  → Volver al hub (voluntario, forzado por energía, o muerte)
  → El bosque se resetea (cada vez que se pisa el hub, no por "día")
  → Repetir, ahora con mejor equipo/nivel
```

> **Cambio de diseño respecto a v1.0:** ya no existe el concepto de "día" como unidad discreta. El reloj corre de forma continua (excepto en menús, que lo pausan) y el reset del bosque está atado a **volver al hub**, no a un límite de tiempo fijo. Dormir es un sistema aparte que afecta el reloj y la energía, no lo que dispara el reset.

### Qué termina un run
Tres formas, con penalizaciones escalonadas:

| Forma de terminar | Consecuencia |
|---|---|
| Volver al hub por decisión propia | Sin penalización — guardás todo lo recolectado |
| Colapso por agotamiento (energía llega a 0) | Transportado al hub, pierde un % **menor** de recursos cargados que al morir |
| Morir en combate | Transportado al hub, pierde un % **mayor** de recursos cargados (no el equipo equipado) |

> El colapso por agotamiento funciona como una "muerte suave" — castiga menos porque no fue una decisión de riesgo de combate, fue no gestionar bien el reloj. Esto le da al sistema de energía dientes propios sin que se sienta tan punitivo como morir peleando.

### Progresión: qué persiste vs. qué se resetea

| Persiste entre runs (meta-progresión) | Se resetea al volver al hub |
|---|---|
| Nivel del personaje / ramas de experiencia | Layout del bosque (tiles, enemigos, recursos) |
| Herramientas y su durabilidad actual | Diccionario de tiles generadas |
| Recursos almacenados en el hub | — |
| Recetas de crafting desbloqueadas | — |
| Energía y hora del reloj (persisten, no se resetean con el bosque) | — |

La sensación de progresión viene de que el jugador **llega más lejos** en el grid de tiles a medida que mejora — mismo principio de "dificultad diagonal" de BarrenRoots, pero ahora aplicado dentro de cada run individual en vez de a un mapa fijo, y combinado con la curva de dificultad por hora del día (sección 4.1).

---

## 4.1 Sistema de Tiempo y Energía

Este sistema es el que le da al Roguelite su identidad propia, más allá de "BarrenRoots pero con generación procedural". Reemplaza cualquier noción de día/noche discreto por un reloj continuo con consecuencias reales.

### El Reloj
- Corre de forma continua mientras el jugador está en el hub o en el bosque.
- Se **pausa** en menús (inventario, crafting, pantallas de pausa) — así el jugador puede gestionar recursos sin presión de tiempo real, sin necesitar el truco de "HUD lento" de la v1.0.
- No hay un límite fijo de horas por ciclo — el jugador decide cuándo dormir.

### Energía
- Barra que se drena de dos formas combinadas en una sola regla simple para el jugador ("la barra baja, y baja más rápido si peleás o minás"):
  - **Drenaje base por tiempo transcurrido** (caminar, esperar, cualquier cosa que consuma reloj ya gasta energía)
  - **Costo extra pequeño por acción** (golpear, minar) — encima del drenaje base, no en vez de
- Al **dormir**, se recarga una cantidad proporcional a las horas dormidas.
- Dormir hace pasar una cantidad **aleatoria** de horas dentro de un rango (ej. 5-9 horas) — el jugador no controla exactamente cuánto tiempo pierde al dormir, otro punto de tensión/incertidumbre que conecta con la filosofía de ADN del proyecto (nada es 100% predecible).

> **Para el MVP:** 2-3 números simples alcanzan — drenaje base por hora, costo extra por acción, rango de horas de sueño. No hace falta una fórmula compleja, la tensión ya emerge de la combinación de reglas simples.

### Dónde se duerme
Dormir **solo es posible en el hub**. Esto refuerza el vínculo entre "dormir" y "el bosque se resetea" — el jugador siempre tiene que volver para recargar del todo, no puede acampar en el bosque a esperar que se le pase el cansancio.

**Consumibles de energía (post-MVP probable):** ítems que dan una recarga parcial o aumentan el margen antes del debuff, para usar dentro del bosque sin tener que volver. Importante que sean **recarga parcial, no completa** — si un consumible reemplaza a dormir del todo, el sistema pierde el filo de tener que decidir cuándo volver.

### Curva de Dificultad por Hora del Día
La dificultad y rareza de recursos en el bosque escalan con la hora del reloj, no con un tier fijo de "bioma":

| Franja horaria (aprox.) | Dificultad / rareza |
|---|---|
| Mañana (luz plena) | Base — punto de entrada más seguro |
| Tarde | Incremento leve y gradual |
| Noche (caída del sol) | Incremento marcado |
| Madrugada (previo al amanecer) | Pico de dificultad y de rareza de recursos |

Esto se implementa como un multiplicador sobre el mismo sistema de presupuesto de dificultad de la sección 2 — la hora del día es solo otra variable que alimenta el mismo cálculo que la distancia al hub, no un sistema nuevo y separado.

**Por qué esto genera la tensión que buscás:** el jugador que entra de madrugada encuentra los mejores rolls de ADN, pero también está más cerca del colapso por energía (porque ya pasó más horas despierto) y enfrenta enemigos más duros. La decisión de "¿entro ahora que hay luz y es más seguro, o espero/aguanto hasta la madrugada por mejor botín?" emerge sola de estos dos sistemas combinados, sin necesitar diseño narrativo adicional.

### Visibilidad Nocturna
De 6pm a 4am (aprox.) el campo de visión se reduce progresivamente mediante niebla/oscuridad (shader u overlay), haciendo la dificultad **visible** y no solo un número interno. El jugador necesita una fuente de luz (linterna/antorcha crafteable) para recuperar radio de visión.

- La fuente de luz consume un recurso (aceite u otro material craftable) mientras está encendida — esto la conecta con la economía en vez de ser un ítem que se craftea una vez y se olvida.
- Refuerza la misma curva de la sección anterior sin ser un sistema aparte: es la traducción visual de la variable "hora del día" que ya alimenta el presupuesto de dificultad.

### Rampa de Aviso por Energía Baja
En vez de un colapso sorpresivo al llegar a 0, la energía baja tiene avisos escalonados:

| Nivel de energía | Efecto |
|---|---|
| Alto | Normal |
| Medio (~50%) | Mensaje de flavor text (ej. "empiezo a sentirme cansado") — solo aviso, sin efecto mecánico |
| Bajo (~20%) | Debuffs activos: menos daño en combate, recolección más lenta |
| 0% | Colapso por agotamiento (ver tabla de penalizaciones en la sección 4) |

Esto resuelve la sensación de injusticia de un colapso sin aviso — el jugador siempre tiene una ventana de "esto se está por poner feo" antes de la consecuencia real.

### Minimapa de Run (estilo *The Binding of Isaac*)
Al entrar al bosque se activa un minimapa que se va completando con las tiles que el jugador visita (posición relativa al hub, no el contenido de cada tile). Se resetea junto con el bosque al volver al hub. No requiere un sistema nuevo — solo trackear qué coordenadas de grid ya se generaron en la sesión actual (mismo diccionario en memoria de la sección 2).

---

## 5. Mecánicas Reutilizadas de BarrenRoots (adaptar a GDScript, no rediseñar)

- **Combate:** swing de arco amplio, dash con i-frames — la lógica conceptual es la misma, solo cambia la implementación (Godot usa `Area2D`/`CharacterBody2D` en vez de los componentes de Unity)
- **ADN de recursos:** rolls de stats al recolectar
- **Herramientas y durabilidad:** igual, sin cambios de diseño
- **Inventario con grilla + peso:** mismo concepto, UI a rehacer en Godot (Control nodes)
- **Crafting personal:** mesa de trabajo con selección de material y preview de stats

> Todo esto es trabajo de "traducir", no de "rediseñar" — ya tomaste esas decisiones una vez.

## 5.1 Resumen de Sistemas Heredados de BarrenRoots

Referencia rápida — el detalle completo de cada uno está en el GDD de BarrenRoots, acá solo el concepto en una línea para no repetir el documento entero.

| Sistema | Descripción breve |
|---|---|
| **ADN de recursos** | Cada recurso recolectado tiene stats aleatorios (2-3 por tipo) generados al momento de obtenerlo. Afecta crafting y valor de venta. |
| **Vida / combate** | Barra de vida, swing de arco amplio al estilo Stardew, dash con i-frames como defensa. |
| **Herramientas y durabilidad** | Cada recurso requiere la herramienta correcta para recolectarse. Las herramientas se desgastan (Buena → Desgastada → Rota) y son reparables. |
| **Inventario (Grid + Peso)** | Grilla de slots + límite de peso con debuff de velocidad al sobrepasarlo. El peso del recurso viene de su ADN. |
| **Crafting personal** | Selección manual de qué ejemplar de material usar, con preview de stats resultantes antes de confirmar. |
| **Penalización por caída** | Perder recursos cargados (no equipo) según cómo termina el run — ver tabla de la sección 4. |

---

## 6. Sistemas Nuevos (específicos del Roguelite)

- Generación procedural por presupuesto de dificultad
- Cache de sesión de tiles (diccionario en memoria, se limpia al volver al hub)
- Reloj continuo + energía con drenaje combinado (tiempo + acción)
- Rampa de aviso y debuffs escalonados por energía baja
- Curva de dificultad y rareza por hora del día
- Visibilidad nocturna con niebla/oscuridad + fuente de luz crafteable
- Minimapa de run (estilo Isaac), se resetea con el bosque
- Escalado de dificultad por distancia al hub dentro de cada run
- Tablón de misiones cerca de la entrada al bosque

### Tablón de Misiones
El jugador explora y recolecta con el objetivo de cumplir misiones y mejorar equipamiento — el tablón centraliza esos objetivos. **Para el MVP:** un tablón sin NPC con diálogo (una lista de objetivos que se actualiza: "traer X cantidad de Y recurso", "alcanzar tal distancia") da el mismo valor de gameplay que un NPC completo con mucho menos trabajo de escritura y UI. Un NPC con diálogo queda como mejora post-MVP si el tablón solo se siente insuficiente.

---

## 7. Fuera de Alcance del MVP (Backlog)

- NPC con diálogo para el tablón de misiones (el tablón mismo sí entra al MVP, ver sección 6)
- Variantes especiales de recursos (post-MVP también en BarrenRoots, mismo criterio aplica acá)
- Meta-progresión avanzada (mejoras permanentes tipo "correr de nuevo desde cero pero con un boost")
- Múltiples biomas más allá del bosque inicial
- Sistema de reputación (no aporta a un roguelite corto, es más propio del RPG)
- Consumibles de recarga de energía (ver sección 4.1 — probable, no confirmado para MVP)

---

## 8. Sobre Godot 4 / GDScript (consideraciones para vos, viniendo de C#/Unity)

Algunas diferencias que te van a ahorrar tiempo de investigación:

| Concepto | Unity/C# | Godot 4/GDScript |
|---|---|---|
| Contenedor de datos reutilizable (como tu `ScriptableObject` de recursos) | `ScriptableObject` | `Resource` (`.tres`) — cumple el mismo rol |
| Tilemap | `Tilemap` component | `TileMapLayer` (Godot 4 separó esto de `TileSet`) |
| Diccionarios/estado en memoria | `Dictionary<K,V>` | `Dictionary` nativo de GDScript, sintaxis más simple |
| Números aleatorios | `Random.Range()` | `randi_range()` / `randf_range()` |
| Colisiones de armas/hitboxes | Componentes + `OnTriggerEnter` | `Area2D` + señal `area_entered` |

> No hace falta que memorices esto ahora — te lo voy a ir mostrando en contexto cuando armemos la guía técnica.

---

## 9. Decisiones Abiertas (para resolver antes o durante la guía técnica)

| Pregunta | Estado |
|---|---|
| ¿Nombre del proyecto? | Pendiente |
| ¿Tamaño real de cada tile? | **Resuelto:** 40×40 tiles de arte de 16px = 640×640px por zona (era 50×50, ver §3) |
| ¿Generación del grafo de tiles: todo de una vez o bajo demanda? | Recomendado: bajo demanda (más simple) |
| ¿Hay NPCs/misiones en el MVP? | **Resuelto:** tablón de misiones sí, NPC con diálogo queda post-MVP (ver sección 6) |
| ¿Se puede dormir en el bosque? | **Resuelto:** no, solo en el hub |
| ¿Qué pasa con herramientas/equipo al colapsar o morir? | **Resuelto:** intactos siempre, solo se pierden recursos/consumibles cargados |
| Números exactos: drenaje base/hora, costo extra por acción, rango de horas de sueño | Pendiente — se ajustan jugando, no hace falta definirlos antes de programar |
| % de pérdida de recursos: colapso por agotamiento vs. muerte en combate | Pendiente — definido conceptualmente (colapso pierde menos), falta el número exacto |
| ¿La energía se puede recargar de alguna forma sin dormir (ítems, comida)? | Probable post-MVP — recarga parcial únicamente, nunca completa |

---

*Documento creado como punto de partida para el proyecto Roguelite — Mini-GDD v1.0*
*Próximo paso sugerido: guía técnica paso a paso para Godot 4/GDScript, arrancando desde cero (sin experiencia previa en el motor).*

---

## 10. Decisiones de Implementación (Hito 1 — Loop completo mínimo)

Tomadas al arrancar el proyecto (2026-11-12). Motor: **Godot 4.7.1, GDScript**.

| Tema | Decisión |
|---|---|
| Motor / lenguaje | Godot 4.7.1 + GDScript, renderer Compatibility |
| Transición entre zonas | **Corte tipo Isaac**: al cruzar una puerta se carga la zona vecina; la cámara queda limitada a la zona actual (640×640px desde el hito 3; antes 800×800) |
| Generación del grafo | **Bajo demanda**, zona por zona, con un RNG sembrado por run (la semilla se imprime en consola para reproducir bugs) |
| Puertas | Cada lado: si el vecino ya existe se respeta su puerta (coherencia); si no, 45% de chance. La puerta de entrada siempre existe |
| Regla anti-encierro | Si una zona tiene vecinos sin generar, al menos una puerta lleva a uno. Verificado con 200 runs simulados (`tests/test_generation.gd`) |
| Caminos internos | Cada puerta tiene un corredor reservado hasta el centro: todas las puertas de una zona quedan siempre conectadas |
| Ubicación del hub en el grid | El hub es la celda (-1, 0); sólo la zona (0, 0) tiene puerta hacia él (oeste) |
| Presupuesto | `6 + profundidad × 3` (profundidad = distancia Manhattan a (0,0)). Hook `DIFFICULTY_MULTIPLIER` listo para la curva por hora del día |
| Rareza por profundidad | `weight_per_depth` en cada SpawnEntry + `min_depth` (el hierro aparece desde profundidad 2) |
| ADN por profundidad | Cada stat se tira como "mejor de N", con N = 1 + profundidad/3 (máx. 3). Calidad = promedio normalizado de los stats (0-100%) |
| Recolectado | Se marca en la cache de la zona: si volvés a esa zona en el mismo run, no reaparece |
| Menús | Pausan el juego (`get_tree().paused`), como pide §4.1 |
| Arte | PNG placeholders con medidas exactas en `assets/` (lista en `assets/README.md`). Se reemplazan pisando el archivo, sin tocar código |

## 11. Decisiones de Implementación (Hito 2 — Reloj y energía)

| Tema | Decisión |
|---|---|
| Velocidad del reloj | 30 s reales = 1 h de juego (18 h despierto ≈ 9 min) |
| Energía | Máx. 100 · drenaje 5/h · 0.4 por golpe · dormir recarga 12/h |
| Sueño | 5-9 h al azar, solo en la cama del hub |
| Rampa | 50%: mensaje · 20%: −30% velocidad y golpes 2× más lentos · 0%: colapso |
| Colapso | En el bosque: pierde 25% de lo cargado (muerte será 50%), guarda el resto, vuelve al hub y **duerme automáticamente**. En el hub: duerme automáticamente |
| Curva por hora | Presupuesto ×1.0 (mañana) → ×1.25 (18 h) → ×1.5 (22 h) → ×1.8 (2 h) → ×2.0 (6 h). Rareza +0 → +3 en los mismos puntos |
| Cómo afecta la rareza | Se suma a la profundidad para los pesos de la tabla, `min_depth` y el ADN: de madrugada puede salir hierro al lado del pueblo |
| Cuándo se fija | Cada zona toma la dificultad de la hora en que se pisa **por primera vez** en el run |
| Visual | Tinte del mundo con CanvasModulate según la hora (el HUD no se tiñe) |

## 12. Decisiones de Implementación (Hito 3 — Combate)

Port de BarrenRoots (1 unidad de Unity = 16 px).

| Tema | Decisión |
|---|---|
| Vida | 6 (3 corazones; corazón = 2). Dormir y morir la restauran |
| Ataque | Arco de 120°, alcance 22 px, hacia el mouse (o J hacia donde mirás). 1 de daño, 0.2 s de swing, 0.35 s de cooldown (×2 agotado), cuesta 0.4 de energía |
| Dash | 288 px/s durante 0.15 s, cooldown 1.5 s, i-frames y atraviesa enemigos, cuesta 0.6 de energía |
| Daño recibido | 0.6 s de i-frames con parpadeo, destello rojo y knockback |
| Enemigo básico | 48 px/s, percibe a 80 px, **amago de 0.35 s** antes de pegar (nuevo: hace el ataque legible y esquivable), medio corazón de daño, 3 de vida (+1 cada 3 de profundidad efectiva) |
| Aparición | Cuesta 3 de presupuesto, `min_depth` 1 → de día no hay enemigos en la primera zona, de noche sí (rareza por hora) |
| Muerte | Pierde 50% de lo cargado (colapso: 25%), guarda el resto, vuelve al hub con vida llena. No duerme: la hora y la energía siguen igual |
| Controles | WASD mover · clic izq./J atacar · Espacio/Shift dash · E interactuar · Tab inventario |

## 13. Decisiones de Implementación (Hito 4 — Ítems e inventario)

Port del diseño de ítems e inventario de BarrenRoots (canvas de Obsidian).

| Tema | Decisión |
|---|---|
| Datos | `ItemData` (Resource en `data/items/`) define el tipo; `ItemInstance` es cada ejemplar con su ADN |
| Mochila | Grilla 6×4; cada ítem ocupa su `grid_size` (madera 1×2, piedra y hierro 1×1) |
| Peso | Sale del ADN (stat `peso`, invertido). Madera 0.6-1.8 kg, piedra 1-2.5, hierro 1.5-3.5 |
| Sobrepeso | Límite 18 kg; por encima, velocidad ×0.5. Se puede seguir cargando: el castigo es la lentitud |
| Mochila llena | No se puede golpear el recurso (y no gasta energía) |
| Almacén | También en grilla (10 columnas), **crece sola** y siempre deja una fila libre: sigue sin límite. En el cofre se ve al lado de la mochila |
| Manejo | Clic agarra/suelta (soltar sobre UN ítem los intercambia), R o clic derecho rota (1×2 ↔ 2×1), Shift+clic pasa directo a la otra grilla, Supr/X o el botón "Tirar" descarta, "Ordenar" compacta la grilla |
| Tirar | El ítem desaparece (no queda en el piso). Sirve para hacer lugar o descartar ADN malo |
| Fin del run | **Nada se guarda solo.** Volver, colapsar o morir deja lo cargado en la mochila; guardarlo en el almacén es decisión del jugador (si salís de nuevo sin guardar, lo arriesgás). Atajo: botón "Guardar todos los recursos" |
| Pérdidas | Colapso 25% / muerte 50% de lo cargado, **sin contar el equipo** |
| Calidad visible | Marca dorada (≥80%) o verde (≥55%) en la esquina del ícono |

## 14. Decisiones de Implementación (Hito 5 — Herramientas y crafting)

| Tema | Decisión |
|---|---|
| Orden | Herramientas y crafting en un mismo hito: arrancás con las manos y lo primero es fabricar hacha/pico |
| Golpes | Cada recurso tiene dureza; cada golpe resta el poder de la herramienta. A mano el poder es 1.5 |
| Requisitos | Árbol (dureza 6, hacha) y roca (5, pico) se pueden a mano. Veta de hierro (12) exige pico **nivel 1**. Nivel 2 (hierro) queda para recursos futuros más profundos |
| Equipo | Sin slots: se usa automáticamente la mejor herramienta/arma de la **mochila** (mayor nivel, después más poder). Llevarla cuesta lugar y peso |
| Recetas | Hacha piedra (2 madera + 2 piedra), pico piedra (2+3), espada madera (3 madera), hacha hierro (2 madera + 2 hierro), pico hierro (2+3), espada hierro (1 madera + 3 hierro) |
| Fórmula | `stat = base × lerp(min, max, t)`, con `t` = promedio normalizado de un stat del material elegido (ej. poder del hacha ← dureza de la piedra; durabilidad ← flexibilidad de la madera). Peso = 50% del peso de los materiales |
| Mesa | En el pueblo. Usa materiales de la mochila **y** del almacén. Auto-elige los mejores; clic para cambiar. Vista previa comparada con la mejor que ya tenés del mismo tipo |
| Durabilidad | 1 por golpe (herramienta) o por golpe que conecta (arma). Buena >60%, Desgastada 20-60%, Rota 0%: rota no se usa (como a mano) hasta repararla |
| Reparar | En la mesa, deja la herramienta como nueva y consume 1 ejemplar (el de peor calidad) de su material principal |
| Armas | Daño = poder del arma redondeado; sin arma, puños de 1 de daño |

## 15. Decisiones de Implementación (Hito 6 — Noche y misiones)

| Tema | Decisión |
|---|---|
| Visión nocturna | Solo en el bosque (el pueblo está iluminado). Se cierra de 18 a 21 h, noche cerrada hasta las 3, se abre hasta las 5. Sin luz se ve un círculo de ~2 tiles |
| Linterna | Equipo (nunca se pierde). Receta: 2 piedra + 1 madera; radio de visión 80-130 px según la **pureza** de la piedra. L prende/apaga; se apaga sola al entrar al pueblo |
| Aceite | Consumible (se pierde al morir/colapsar como cualquier recurso). Receta: 2 madera; 90-180 minutos de juego según la **densidad** de la madera. Se gasta con el reloj mientras la linterna está prendida, primero el frasco más vacío |
| Tablón | En el pueblo, cerca de la salida. Siempre 3 misiones, una de cada tipo al empezar |
| Tipos | Entregar N recursos con calidad mínima (de la mochila o el almacén; se entregan los de peor calidad que cumplan) · llegar a profundidad N · derrotar N enemigos |
| Escalado | Cada misión reclamada sube la exigencia de las nuevas (más cantidad, más calidad, más profundidad; el hierro aparece desde la 3ª) |
| Recompensas | Mejoras permanentes al azar: +2 kg de capacidad, +10 de energía máxima o +1 corazón |

### Aclaración de diseño: energía tras colapsar
La tabla de progresión (§4) dice que la energía y el reloj **persisten** al volver al hub. En consecuencia, después de un colapso por agotamiento el jugador aparece en el hub con energía 0 y está obligado a dormir antes de volver a salir. **Resuelto en el hito 2:** el colapso lleva directo a dormir en la cama, así el jugador no queda trabado con energía 0 en el pueblo.

### Próximos hitos sugeridos
1. Reloj continuo + energía (drenaje por tiempo y por acción, dormir en el hub, avisos escalonados, colapso → `GameState.lose_run_fraction`)
2. Combate básico (swing + dash con i-frames) y un enemigo en la tabla de spawn
3. Herramientas con nivel y durabilidad (reemplazan el `hits` fijo)
4. Inventario con peso, crafting con preview de stats
5. Niebla nocturna + fuente de luz, tablón de misiones

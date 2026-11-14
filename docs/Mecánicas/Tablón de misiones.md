---
tipo: mecánica
estado: hecho
version: 0.1
hito: 6
---
# Tablón de misiones

> Objetivos concretos para cada salida, que se pagan con mejoras permanentes.

## Cómo funciona
- En el pueblo, cerca de la salida. Siempre **3 misiones**, una de cada tipo:
  - **Entregar** N recursos con calidad mínima (de la mochila o el almacén).
  - **Llegar** a profundidad N.
  - **Derrotar** N enemigos.
- Hoy, al entregar, se usan automáticamente **los de peor calidad** que cumplan el requisito.
- Cada misión reclamada se reemplaza por una más exigente, de un tipo que no esté ya en el tablón
  (más cantidad, calidad, profundidad; el cobre aparece desde la 3ª y el hierro desde la 5ª).
- **Hito 11:** al reclamar una entrega se **elige qué dar** (vienen marcados los peores y los de rasgo
  bueno quedan para el final). Misiones nuevas: fabricar una herramienta o arma de calidad ≥ X, y
  entregar recursos con [[Rasgos raros|rasgo bueno]].

## Se conecta con
- [[Mejoras permanentes]]: la recompensa.
- [[ADN de recursos]]: calidad mínima.
- [[Bosque procedural]]: profundidad.
- [[Enemigos]]: cazar.
- [[Inventario y peso]]: toma de las dos grillas.

## Pilar que refuerza
- Ganas de volver ya.

## Números
[[BALANCE]] § Misiones.

## Código
`autoload/missions.gd` · `scripts/mission.gd` · `scenes/ui/mission_board_ui.gd`.

## Ideas y pendientes
- **0.2 (hito 11):** al reclamar, **elegir qué entregar** (vienen preseleccionados los peores).
- Misiones nuevas: "fabricá una herramienta de calidad ≥ X", "traé un ítem con rasgo raro".
- Que la recompensa se vea antes de aceptar.
- NPC con diálogo: [[Ideas para la 0.3]].

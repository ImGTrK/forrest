// Oscuridad nocturna: todo negro salvo un círculo alrededor del jugador.
// Placeholder funcional (GDD §4.1); el efecto lindo queda para después del MVP.
shader_type canvas_item;

uniform vec2 center = vec2(0.5);          // posición del jugador en UV del rect
uniform vec2 rect_size = vec2(640.0, 360.0);
uniform float radius = 1000.0;            // px de visión clara
uniform float feather = 28.0;             // px de degradé
uniform float darkness = 0.0;             // 0 = de día, 1 = noche cerrada

void fragment() {
	float d = length((UV - center) * rect_size);
	float a = smoothstep(radius, radius + feather, d) * darkness;
	COLOR = vec4(0.0, 0.0, 0.03, a);
}

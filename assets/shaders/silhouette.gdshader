shader_type canvas_item;
// Silueta de un solo color (estela del dash, destellos). Respeta el alfa del sprite.
uniform vec4 tint : source_color = vec4(0.55, 0.77, 0.75, 1.0);

void fragment() {
	float a = texture(TEXTURE, UV).a;
	COLOR = vec4(tint.rgb, a * tint.a * COLOR.a);
}

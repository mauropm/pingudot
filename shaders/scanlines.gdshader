shader_type canvas_item;
// subtle CRT scanlines for terminal overlays
uniform float strength : hint_range(0.0, 0.5) = 0.16;

void fragment() {
	float line = step(0.5, fract(FRAGCOORD.y * 0.5));
	COLOR = vec4(0.0, 0.0, 0.0, line * strength);
}

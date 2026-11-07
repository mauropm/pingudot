shader_type canvas_item;
// Subtle CRT-style edge vignette + gentle scanlines for the "lost 1994 cart"
// feeling. Intensity is deliberately low so pixel art stays crisp.

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.045;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv * vec2(1.0, 1.15));
	float vig = smoothstep(0.42, 0.95, d) * vignette_strength;
	float scan = step(0.5, fract(FRAGCOORD.y * 0.5)) * scanline_strength;
	COLOR = vec4(0.0, 0.0, 0.02, vig + scan);
}

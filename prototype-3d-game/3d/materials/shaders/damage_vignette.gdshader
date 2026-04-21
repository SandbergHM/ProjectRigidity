shader_type canvas_item;

// 0.0 = invisible, 1.0 = full flash
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 vignette_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
// How far inward the vignette reaches (0 = only corners, 1 = full screen)
uniform float reach : hint_range(0.0, 1.0) = 0.1;
// How sharp the inner edge of the vignette is
uniform float sharpness : hint_range(1.0, 16.0) = 4.0;

void fragment() {
	// UV goes 0..1; remap to -1..1 so centre is (0,0)
	vec2 centered = UV * 2.0 - 1.0;

	// Elliptical distance from centre, giving equal edge weight on all sides
	float dist = length(centered);

	// Smooth vignette mask: 0 in the centre, 1 at the edges
	float edge = smoothstep(1.0 - reach, 1.0, dist);
	edge = pow(edge, 1.0 / sharpness);

	COLOR = vec4(vignette_color.rgb, edge * intensity * vignette_color.a);
}

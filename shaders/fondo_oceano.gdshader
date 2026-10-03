// Game background: procedural gradient, no textures and no per-frame code.
// It is painted on a full screen ColorRect (the "Background" node in main.tscn).
// The cycle is driven by TIME, so main.gd never touches the background: the
// cost per frame is a single fullscreen quad with no texture reads at all.
//
// PALETTE "deep ocean": to change it, edit these 4 constants.
// TUNE: period = seconds per loop, swing = axis tilt in radians,
// rise = how far the centre moves up/down, span = half-length of the axis.

shader_type canvas_item;

const vec3 COL_A = vec3(0.043137, 0.117647, 0.227451); // #0B1E3A
const vec3 COL_B = vec3(0.078431, 0.286275, 0.419608); // #14496B
const vec3 COL_C = vec3(0.180392, 0.560784, 0.658824); // #2E8FA8
const vec3 COL_D = vec3(0.498039, 0.831373, 0.815686); // #7FD4D0

const float OFF_B = 0.38;
const float OFF_C = 0.72;

const float PERIOD = 24.0;
const float SWING = 0.45;
const float RISE = 0.06;
const float SPAN = 0.85;

void fragment() {
	// Dos senos desfasados medio ciclo: el circulo cierra exacto, sin salto.
	float turn = fract(TIME / PERIOD) * TAU;
	float angle = sin(turn) * SWING;
	vec2 axis = vec2(sin(angle), cos(angle));
	vec2 mid = vec2(0.5, 0.5 + cos(turn) * RISE);

	// t = 0 en el inicio del eje, 1 en el final (mismo mapeo que antes usaba
	// GradientTexture2D con fill_from/fill_to).
	float t = clamp(0.5 + dot(UV - mid, axis) / (2.0 * SPAN), 0.0, 1.0);

	// Los tres tramos se calculan siempre y se elige uno: evita divisiones por
	// cero y mantiene el coste igual en toda la pantalla.
	vec3 c1 = mix(COL_A, COL_B, clamp(t / OFF_B, 0.0, 1.0));
	vec3 c2 = mix(COL_B, COL_C, clamp((t - OFF_B) / (OFF_C - OFF_B), 0.0, 1.0));
	vec3 c3 = mix(COL_C, COL_D, clamp((t - OFF_C) / (1.0 - OFF_C), 0.0, 1.0));

	COLOR = vec4(t < OFF_B ? c1 : (t < OFF_C ? c2 : c3), 1.0);
}
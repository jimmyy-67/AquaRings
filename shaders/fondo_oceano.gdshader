// Fondo del juego: degradado procedural, sin texturas y sin codigo por frame.
// Se pinta en un ColorRect a pantalla completa (nodo "Background" de main.tscn).
// El ciclo lo lleva TIME, asi que main.gd no toca el fondo: el coste por frame
// es un fullscreen quad sin ninguna lectura de textura.
//
// PALETA "oceano profundo": para cambiarla, editar estos 4 const.
// TUNE: period = segundos por vuelta, swing = inclinacion del eje en radianes,
// rise = cuanto sube/baja el centro, span = media-longitud del eje.

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
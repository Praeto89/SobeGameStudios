// fog.gdshader
// ----------------------------------------------------------------------------
// Vollbild-Nebel fuer ein "canvas_item" (ColorRect in einem CanvasLayer).
// Erzeugt wabernde Schwaden aus scrollendem Wert-Rauschen -- dichter und
// "echter" als der Partikel-Nebel (cave_fog.tscn), dafuer etwas teurer.
//
// Anhaengen an: eine bildschirmfuellende ColorRect (siehe cave_fog_shader.tscn).
// Schwierigkeit: [FORTGESCHRITTEN] -- erster eigener Shader.
//
// Probier es: drehe im Inspector an "density" (Dichte) und "speed" (Tempo).
shader_type canvas_item;

// Farbe des Nebels (source_color = wird als Farbe-Picker angezeigt).
uniform vec4 fog_color : source_color = vec4(0.72, 0.74, 0.85, 1.0);
// Wie schnell die Schwaden ziehen.
uniform float speed = 0.03;
// Maximale Deckkraft des Nebels (0 = unsichtbar, 1 = milchig dicht).
uniform float density : hint_range(0.0, 1.0) = 0.5;
// Groesse der Schwaden (groesser = grobere, ruhigere Schwaden).
uniform float scale = 3.0;

// Pseudo-Zufallswert pro Gitterpunkt.
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.0, 289.0))) * 43758.5453);
}

// Weiches Wert-Rauschen: vier Ecken interpolieren.
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			   mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	// Zwei Rausch-Ebenen unterschiedlicher Groesse uebereinanderlegen
	// (= "fractal noise") und langsam verschieben -> wirkt wie Nebelzug.
	vec2 uv = UV * scale + vec2(TIME * speed, TIME * speed * 0.3);
	float n = noise(uv) * 0.6 + noise(uv * 2.0) * 0.4;
	COLOR = vec4(fog_color.rgb, n * density);
}

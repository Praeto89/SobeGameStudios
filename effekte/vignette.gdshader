// vignette.gdshader
// ----------------------------------------------------------------------------
// Vollbild-Vignette: dunkelt die Bildschirmraender ab. Als reine Stimmung
// nutzbar -- oder als "Schadens-Vignette", die bei wenig Leben staerker wird
// (siehe effekte/vignette.gd, das "intensity" per Signal steuert).
//
// Anhaengen an: eine bildschirmfuellende ColorRect in einem CanvasLayer.
// Schwierigkeit: [FORTGESCHRITTEN] -- Shader-Parameter von aussen steuern.
shader_type canvas_item;

// Farbe des Randes (meist Schwarz oder ein dunkles Rot fuer "Gefahr").
uniform vec4 vignette_color : source_color = vec4(0.05, 0.0, 0.02, 1.0);
// Ab welchem Abstand zur Mitte der Rand beginnt (kleiner = groesserer Rand).
uniform float radius : hint_range(0.0, 1.5) = 0.8;
// Wie weich der Uebergang verlaeuft.
uniform float softness : hint_range(0.0, 1.0) = 0.5;
// Maximale Deckkraft am Rand. Wird vom Script bei wenig Leben hochgezogen.
uniform float intensity : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	// Abstand vom Bildmittelpunkt (0.5, 0.5).
	float dist = length(UV - vec2(0.5));
	// v = 1 in der Mitte, faellt zum Rand hin auf 0.
	float v = smoothstep(radius, radius - softness, dist);
	// Deckkraft also am Rand am hoechsten.
	float alpha = (1.0 - v) * intensity;
	COLOR = vec4(vignette_color.rgb, alpha);
}

shader_type spatial;
// Água estilizada: cor base translúcida + manchas de espuma que correm na direção
// de `flow` (em UV por segundo). Serve para lago (flow lento) e cachoeira (rápido).
// As manchas são "degraus" (step), sem degradê, para combinar com o low-poly.
render_mode cull_disabled, depth_draw_opaque;

uniform vec4 water_color : source_color = vec4(0.16, 0.45, 0.62, 0.8);
uniform vec4 foam_color : source_color = vec4(0.88, 0.96, 1.0, 1.0);
// Direção e velocidade da corrente em UV/s (cachoeira: v positivo = desce).
uniform vec2 flow = vec2(0.0, 0.05);
// Quantas "manchas" cabem na superfície em U e V (esticar V faz riscos).
uniform vec2 pattern_scale = vec2(6.0, 6.0);
uniform float foam_amount : hint_range(0.0, 1.0) = 0.2;
// Tamanho do "pixel" do padrão (0 = liso).
uniform float pixelate = 24.0;
// Brilho próprio: a água não some na luz quente do pôr do sol.
uniform float self_light : hint_range(0.0, 1.0) = 0.3;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 uv = UV;
	if (pixelate > 0.0) {
		uv = floor(uv * pixelate) / pixelate;
	}
	vec2 p = (uv - flow * TIME) * pattern_scale;
	float n = value_noise(p) * 0.65 + value_noise(p * 2.3 + 7.1) * 0.35;
	float foam = step(1.0 - foam_amount, n);
	ALBEDO = mix(water_color.rgb, foam_color.rgb, foam);
	EMISSION = ALBEDO * self_light;
	ALPHA = mix(water_color.a, foam_color.a, foam);
	ROUGHNESS = 0.2;
	SPECULAR = 0.6;
}

shader_type canvas_item;
// k: la borrachera (triple y aberración). ojo: el colocón, los párpados entornados en forma de ojo. humo: al fumar, humo que
// sube y se va. Todo en pixel art, como el juego (lo pidió el usuario): cada píxel del juego, un solo valor (la rejilla de la
// pantalla baja, no la del móvil), el borde del ojo y el humo difuminados con tramado ordenado (Bayer 4 × 4) y el humo en tres
// tonos de la paleta, sin degradados ni desenfoque.
uniform float k = 0.0;
uniform float t = 0.0;
uniform float ojo = 0.0;
uniform float humo = 0.0;

const vec3 HUMO_1 = vec3(0.56, 0.58, 0.62);   // sombra del humo
const vec3 HUMO_2 = vec3(0.76, 0.78, 0.80);
const vec3 HUMO_3 = vec3(0.92, 0.93, 0.94);   // lo más espeso
const vec3 PARPADO = vec3(0.08, 0.05, 0.07);
const vec3 PARPADO_2 = vec3(0.24, 0.12, 0.13);   // el canto del párpado, rojizo

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(azar(i), azar(i + vec2(1.0, 0.0)), f.x), mix(azar(i + vec2(0.0, 1.0)), azar(i + vec2(1.0, 1.0)), f.x), f.y);
}
float nubes(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * ruido(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}
// el umbral del tramado ordenado 4 × 4 en el píxel del juego (0 a 15/16, + 1/32)
float bayer(vec2 ip) {
	int x = int(mod(ip.x, 4.0));
	int y = int(mod(ip.y, 4.0));
	int b[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(b[y * 4 + x]) + 0.5) / 16.0;
}

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE;
	vec2 ip = floor(UV / px);           // el píxel del juego
	vec2 uv = (ip + 0.5) * px;          // su centro: todo el efecto va por píxeles del juego
	vec4 c = texture(TEXTURE, uv);
	vec3 col = c.rgb;
	float th = bayer(ip);
	if (k > 0.0) {
		float o = floor(k * 5.0 * (1.0 + 0.35 * sin(t * 1.3)) + 0.5);
		vec2 d = vec2(o, floor(o * 0.25 * sin(t * 0.7) + 0.5)) * px;
		vec3 l = texture(TEXTURE, uv - d).rgb;
		vec3 r = texture(TEXTURE, uv + d).rgb;
		vec3 tri = c.rgb * 0.5 + (l + r) * 0.25;
		vec3 ab = vec3(texture(TEXTURE, uv + floor(d / px * 0.6 + 0.5) * px).r, tri.g, texture(TEXTURE, uv - floor(d / px * 0.6 + 0.5) * px).b);
		col = mix(c.rgb, ab, k);
	}
	// la pantalla en proporción (alto = 1) y centrada
	float asp = px.y / px.x;
	vec2 p = (uv - 0.5) * vec2(asp, 1.0);
	// el humo: nubes que suben y se tuercen, más espesas abajo (de donde sale) al principio; la densidad a 3 tonos por tramado
	if (humo > 0.0) {
		vec2 q = p * 3.2 + vec2(0.35 * sin(t * 0.4 + p.y * 2.0), t * 0.22);
		float n = nubes(q) * 0.65 + nubes(q * 0.5 - vec2(t * 0.05, 0.0)) * 0.35;
		float dens = clamp((n - 0.42) / 0.36, 0.0, 1.0) * humo * (0.55 + 0.45 * clamp(p.y + 0.3 * humo + 0.5, 0.0, 1.0));
		float e = dens * 3.0;            // 0..3: nada, sombra, medio, espeso
		float lv = clamp(floor(e) + (fract(e) > th ? 1.0 : 0.0), 0.0, 3.0);
		if (lv >= 3.0)
			col = HUMO_3;
		else if (lv >= 2.0)
			col = HUMO_2;
		else if (lv >= 1.0)
			col = mix(col, HUMO_1, 0.5 + 0.5 * step(0.5, fract((ip.x + ip.y) * 0.5)));
	}
	// el ojo: los párpados de arriba y abajo en arco (almendra); cuanto más colocón, más cerrado; el borde, en tramado con un
	// canto de un píxel rojizo, y dentro, los ojos rojos
	if (ojo > 0.0) {
		float h = mix(0.85, 0.24, ojo) * (1.0 + 0.035 * sin(t * 0.9));
		float w = asp * 0.5 * mix(1.35, 1.08, ojo);
		float x = clamp(abs(p.x) / w, 0.0, 1.0);
		float lado = h * (1.0 - x * x);
		float y = p.y < 0.0 ? -p.y * 1.08 : p.y;   // el de arriba baja un poco más
		float filas = (y - lado) / px.y;           // en píxeles del juego desde el borde
		float banda = 3.0 + 3.0 * ojo;             // el tramado del borde, en píxeles
		float f = clamp((filas + banda) / banda, 0.0, 1.0);
		if (filas >= 0.0)
			col = PARPADO;
		else if (f > th)
			col = PARPADO_2 * (f > 0.75 ? 0.6 : 1.0);
		else
			col = col * mix(vec3(1.0), vec3(1.0, 0.86, 0.86), ojo * 0.6);
	}
	COLOR = vec4(col, c.a);
}

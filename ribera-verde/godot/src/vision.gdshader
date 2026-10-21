shader_type canvas_item;
// k: la borrachera (triple y aberración). ojo: el colocón, los párpados entornados en forma de ojo, con el borde difuminado.
// humo: al fumar, humo blanco difuminado que sube y se va (y lo de detrás, borroso).
uniform float k = 0.0;
uniform float t = 0.0;
uniform float ojo = 0.0;
uniform float humo = 0.0;

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

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE;
	vec4 c = texture(TEXTURE, UV);
	vec3 col = c.rgb;
	if (k > 0.0) {
		float o = k * 5.0 * (1.0 + 0.35 * sin(t * 1.3));
		vec2 d = vec2(o, o * 0.25 * sin(t * 0.7)) * px;
		vec3 l = texture(TEXTURE, UV - d).rgb;
		vec3 r = texture(TEXTURE, UV + d).rgb;
		vec3 tri = c.rgb * 0.5 + (l + r) * 0.25;
		vec3 ab = vec3(texture(TEXTURE, UV + d * 0.6).r, tri.g, texture(TEXTURE, UV - d * 0.6).b);
		col = mix(c.rgb, ab, k);
	}
	// la pantalla en proporción (alto = 1) y centrada
	float asp = px.y / px.x;
	vec2 p = (UV - 0.5) * vec2(asp, 1.0);
	// el humo: nubes que suben y se tuercen, más espesas abajo (de donde sale) al principio
	float dens = 0.0;
	if (humo > 0.0) {
		vec2 q = p * 3.2 + vec2(0.35 * sin(t * 0.4 + p.y * 2.0), t * 0.22);
		float n = nubes(q) * 0.65 + nubes(q * 0.5 - vec2(t * 0.05, 0.0)) * 0.35;
		dens = smoothstep(0.42, 0.78, n) * humo * (0.55 + 0.45 * smoothstep(-0.5, 0.5, p.y + 0.3 * humo));
	}
	// difuminado: con el humo y con el colocón, lo de detrás borroso (media de 9 a r píxeles)
	float rb = max(dens * 3.0, ojo * 1.2);
	if (rb > 0.05) {
		vec3 b = vec3(0.0);
		for (int i = -1; i <= 1; i++)
			for (int j = -1; j <= 1; j++)
				b += texture(TEXTURE, UV + vec2(float(i), float(j)) * rb * px).rgb;
		col = mix(col, b / 9.0, clamp(rb, 0.0, 1.0));
	}
	col = mix(col, vec3(0.86, 0.87, 0.9), dens * 0.6);
	// el ojo: los párpados de arriba y abajo en arco (almendra); cuanto más colocón, más cerrado; el borde, difuminado
	if (ojo > 0.0) {
		float h = mix(0.85, 0.24, ojo) * (1.0 + 0.035 * sin(t * 0.9));
		float w = asp * 0.5 * mix(1.35, 1.08, ojo);
		float x = clamp(abs(p.x) / w, 0.0, 1.0);
		float lado = h * (1.0 - x * x);
		float y = p.y < 0.0 ? -p.y * 1.08 : p.y;   // el de arriba baja un poco más
		float fuera = smoothstep(-0.07 - 0.05 * ojo, 0.05, y - lado);
		col = mix(col, vec3(0.03, 0.02, 0.03), fuera);
		col = mix(col, col * vec3(1.0, 0.93, 0.93), ojo * 0.5);   // los ojos rojos
	}
	COLOR = vec4(col, c.a);
}

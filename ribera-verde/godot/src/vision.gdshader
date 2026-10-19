shader_type canvas_item;
uniform float k = 0.0;
uniform float t = 0.0;
void fragment() {
	float o = k * 5.0 * (1.0 + 0.35 * sin(t * 1.3));
	vec2 d = vec2(o, o * 0.25 * sin(t * 0.7)) * TEXTURE_PIXEL_SIZE;
	vec4 c = texture(TEXTURE, UV);
	vec3 l = texture(TEXTURE, UV - d).rgb;
	vec3 r = texture(TEXTURE, UV + d).rgb;
	vec3 tri = c.rgb * 0.5 + (l + r) * 0.25;
	vec3 ab = vec3(texture(TEXTURE, UV + d * 0.6).r, tri.g, texture(TEXTURE, UV - d * 0.6).b);
	COLOR = vec4(mix(c.rgb, ab, k), c.a);
}

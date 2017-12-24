#version 410

in vec3 pos_eye;
in vec3 norm_eye;
in vec2 st;


uniform sampler2D diffuse_map;
uniform sampler2D specular_map;
uniform sampler2D ambient_map;
uniform sampler2D emission_map;


uniform mat4 view;

out vec4 frag_colour;

vec3 light_position_world = vec3 (1.0, 1.0, 10.0);
vec3 Ls = vec3 (1.0, 1.0, 1.0); // white specular colour
vec3 Ld = vec3 (0.7, 0.7, 0.7); // dull white diffuse light colour
vec3 La = vec3 (0.2, 0.2, 0.2); // grey ambient colour
float specular_exponent = 100.0; // specular 'power'

void main() {
	vec3 light_pos_eye = (view * vec4(light_position_world, 1.0)).xyz;

	vec3 Ia = vec3(0.2, 0.2, 0.2) * texture(ambient_map, st).rgb;

	vec4 texel = texture(diffuse_map, st);
	vec3 Kd = texel.rgb;
	vec3 surface_to_light_eye = normalize(light_pos_eye - pos_eye);
	float dp = max(0.0, dot(norm_eye, surface_to_light_eye));
	vec3 Id = Kd * Ld * dp;

	vec3 Ks = texture(specular_map, st).rgb;
	vec3 surface_to_viewer_eye = normalize(-pos_eye);
	vec3 half_way_eye = normalize(surface_to_viewer_eye + surface_to_light_eye);
	float dot_prod_specular = max(dot(half_way_eye, norm_eye), 0.0);
	float specular_factor = pow(dot_prod_specular, specular_exponent);
	vec3 Is = Ls * Ks * specular_factor; // final specular intensity

	vec3 texel_e = texture(emission_map, st).rgb;

	frag_colour = vec4(Id + Is + Ia + texel_e, 1.0);

	// to test parts of the equation we use them as colours. here we use the
	// dot-product from the specular lighting equation as the colour of each
	// fragment
	frag_colour.xyz = vec3(dot_prod_specular, dot_prod_specular, dot_prod_specular);
}

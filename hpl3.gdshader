shader_type spatial;

uniform sampler2D diffuse_texture : source_color, hint_default_white;
uniform sampler2D normal_texture : hint_normal;
uniform sampler2D specular_texture : hint_default_black;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = texture(diffuse_texture, UV).rgb;
	NORMAL_MAP = texture(normal_texture, UV).rgb;
	ROUGHNESS = 1.0 - texture(specular_texture, UV).r;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

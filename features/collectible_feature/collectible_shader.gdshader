shader_type spatial;

uniform sampler2D texture_albedo : source_color;
uniform vec4 albedo_color : source_color = vec4(1.0); 
uniform float roughness : hint_range(0, 1) = 0.5;
uniform float metallic : hint_range(0, 1) = 0.0;

uniform float rotation_speed = 2.0;
uniform float bounce_amplitude = 0.1;
uniform float bounce_frequency = 2.0;

uniform mat3 correction_matrix; 
uniform mat3 normal_matrix;

void vertex() {
	vec3 v = correction_matrix * VERTEX;
	vec3 n = normal_matrix * NORMAL;
	
	float angle = TIME * rotation_speed;
	float c = cos(angle);
	float s = sin(angle);
	mat2 rot_y = mat2(vec2(c, -s), vec2(s, c));
	
	v.xz = rot_y * v.xz;
	n.xz = rot_y * n.xz;
	v.y += sin(TIME * bounce_frequency) * bounce_amplitude;
	
	VERTEX = v;
	NORMAL = normalize(n);
}

void fragment() {
	vec4 albedo_tex = texture(texture_albedo, UV);
	ALBEDO = albedo_tex.rgb * albedo_color.rgb * COLOR.rgb;
	ROUGHNESS = roughness;
	METALLIC = metallic;
}
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

// Fade parameters
uniform float fade_min_distance = 1.0;
uniform float fade_max_distance = 3.0;

void fragment() {
	vec4 albedo_tex = texture(texture_albedo, UV);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	
	// Distance from the camera to the fragment
	// In Godot 4 spatial shaders, VERTEX in the fragment function is in view space, 
	// meaning distance to the camera is length(VERTEX).
	float dist = length(VERTEX);
	float alpha_factor = smoothstep(fade_min_distance, fade_max_distance, dist);
	
	ALPHA = albedo.a * albedo_tex.a * alpha_factor;
}

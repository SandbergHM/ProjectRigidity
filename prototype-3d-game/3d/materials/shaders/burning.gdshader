shader_type spatial;

render_mode blend_add, cull_back, unshaded;



uniform vec4 fire_color : source_color = vec4(1.0, 0.4, 0.1, 1.0);

uniform sampler2D noise_tex;

uniform float speed : hint_range(-5.0, 5.0) = 1.0;

uniform float fire_intensity : hint_range(0.0, 10.0) = 2.0;

uniform float fresnel_power : hint_range(0.0, 5.0) = 3.0;

uniform float distortion_strength : hint_range(0.0, 1.0) = 0.1;

uniform float noise_scale : hint_range(0.1, 1000.0) = 1.0; 



void vertex() {
	
    float n = texture(noise_tex, (UV * noise_scale) + TIME * 0.5 * speed).r;
    VERTEX += NORMAL * n * distortion_strength;

}



void fragment() {

    float fresnel = pow(1.0 - dot(NORMAL, VIEW), fresnel_power);

    

 	  vec2 scrolling_uv = (UV * noise_scale) + vec2(0.0, -TIME * speed);

    float noise = texture(noise_tex, scrolling_uv).r;



    float fire_mask = fresnel * noise * fire_intensity;



    float flicker = sin(TIME * 10.0) * 0.1 + 0.9;

    

    ALBEDO = fire_color.rgb * fire_mask * flicker;

    ALPHA = clamp(fire_mask * fire_color.a, 0.0, 1.0);

}
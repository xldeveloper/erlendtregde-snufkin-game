shader_type canvas_item;
render_mode blend_mix;

// Noise texture for fog pattern
uniform sampler2D noise_texture: repeat_enable, filter_linear;

// Fog density (how opaque the fog is)
uniform float density: hint_range(0.0, 1.0) = 0.35;

// Fog movement speed
uniform vec2 speed = vec2(0.02, 0.01);

// Depth-based color (for atmospheric perspective)
uniform vec4 fog_color: source_color = vec4(0.7, 0.75, 0.82, 1.0);

// Height-based density falloff
uniform float ground_density: hint_range(0.0, 2.0) = 1.5;
uniform float height_falloff: hint_range(0.1, 5.0) = 2.0;

// Noise parameters for organic look
uniform float noise_scale: hint_range(0.5, 3.0) = 1.2;
uniform float turbulence: hint_range(0.0, 1.0) = 0.4;

// Edge softness (to prevent hard seam lines)
uniform float top_fade: hint_range(0.0, 0.5) = 0.2;
uniform float bottom_fade: hint_range(0.0, 0.5) = 0.15;

void fragment() {
	// Multi-layer UV coordinates with different speeds for depth
	vec2 uv1 = UV * noise_scale + speed * TIME;
	vec2 uv2 = UV * (noise_scale * 1.7) + speed * TIME * 0.6;
	vec2 uv3 = UV * (noise_scale * 0.5) + speed * TIME * 1.3;
	
	// Sample multiple noise layers
	float noise1 = texture(noise_texture, uv1).r;
	float noise2 = texture(noise_texture, uv2).r;
	float noise3 = texture(noise_texture, uv3).r;
	
	// Combine noise with turbulence
	float combined_noise = noise1 * 0.5 + noise2 * 0.3 + noise3 * 0.2;
	combined_noise = mix(combined_noise, noise1 * noise2, turbulence);
	
	// Height-based density (denser at bottom, lighter at top)
	float height_factor = pow(1.0 - UV.y, height_falloff) * ground_density;
	
	// Create soft fog with smooth transitions
	float fog_alpha = smoothstep(0.2, 0.8, combined_noise);
	
	// Apply height-based density
	fog_alpha *= height_factor;
	
	// Add vertical edge gradients to prevent hard seam lines
	float top_gradient = smoothstep(0.0, top_fade, UV.y);
	float bottom_gradient = smoothstep(1.0, 1.0 - bottom_fade, UV.y);
	float edge_fade = top_gradient * bottom_gradient;
	
	// Apply edge fade for seamless blending between layers
	fog_alpha *= edge_fade;
	
	// Apply base density
	fog_alpha *= density;
	
	// Set fog color with calculated alpha
	COLOR = vec4(fog_color.rgb, fog_alpha * fog_color.a);
}

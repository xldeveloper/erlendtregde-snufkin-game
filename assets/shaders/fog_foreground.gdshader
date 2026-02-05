shader_type canvas_item;
render_mode blend_mix;

// Noise texture for fog pattern
uniform sampler2D noise_texture: repeat_enable, filter_nearest;

// Fog density
uniform float density: hint_range(0.0, 1.0) = 0.35;

// Fog movement speed
uniform vec2 speed = vec2(0.02, 0.01);

// Depth-based color
uniform vec4 fog_color: source_color = vec4(0.75, 0.78, 0.82, 1.0);

// Chunk size (bigger = larger fog blobs)
uniform float chunk_scale: hint_range(0.3, 2.0) = 0.8;

// Edge softness (prevents hard seam lines)
uniform float top_fade: hint_range(0.0, 0.5) = 0.2;
uniform float bottom_fade: hint_range(0.0, 0.5) = 0.15;

void fragment() {
	// Large chunky fog patches
	vec2 uv = UV * chunk_scale + speed * TIME;
	
	// Sample noise texture
	float noise = texture(noise_texture, uv).r;
	
	// Original shader style: convert noise to chunky patches
	// This creates bigger, blob-like fog instead of fine detail
	float fog = clamp(noise * 2.0 - 1.0, 0.0, 1.0);
	
	// Apply vertical edge gradients for seamless blending
	float top_gradient = smoothstep(0.0, top_fade, UV.y);
	float bottom_gradient = smoothstep(1.0, 1.0 - bottom_fade, UV.y);
	float edge_fade = top_gradient * bottom_gradient;
	
	// Soften the fog edges for cloud-like wisps
	fog = smoothstep(0.3, 0.7, fog);
	
	// Apply edge fade and density
	fog *= edge_fade * density;
	
	// Set fog color with calculated alpha
	COLOR = vec4(fog_color.rgb, fog * fog_color.a);
}

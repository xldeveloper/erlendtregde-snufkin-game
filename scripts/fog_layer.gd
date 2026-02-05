extends Node
class_name FogLayer

## Creates atmospheric depth fog at a specific parallax depth
## Fog density increases toward ground level for realistic effect

@export_group("Fog Properties")
## Fog base density
@export_range(0.0, 1.0) var fog_density: float = 0.35

## Fog color (changes based on depth - bluer in distance)
@export var fog_color: Color = Color(0.7, 0.75, 0.82, 1.0)

## Fog movement speed
@export var fog_speed: Vector2 = Vector2(0.02, 0.01)

## Ground density multiplier (fog denser at ground level)
@export_range(0.0, 3.0) var ground_density: float = 1.5

## Height falloff rate
@export_range(0.1, 5.0) var height_falloff: float = 2.0

## Noise scale for detail
@export_range(0.5, 3.0) var noise_scale: float = 1.2

## Turbulence amount
@export_range(0.0, 1.0) var turbulence: float = 0.4

## Top edge fade (prevents hard top line)
@export_range(0.0, 0.5) var top_fade: float = 0.2

## Bottom edge fade (prevents hard bottom line)
@export_range(0.0, 0.5) var bottom_fade: float = 0.15

@export_group("Positioning")
## Vertical position offset (for layering at specific heights)
@export var vertical_offset: float = 0.0

## Height coverage (how tall the fog layer is)
@export var fog_height: float = 600.0

@export_group("Depth Settings")
## Parallax scale factor (for reference, actual parallax handled by parent)
@export_range(-1.0, 1.0) var parallax_scale: float = 0.5

## Use chunky foreground fog style (big cloud wisps)
@export var use_chunky_style: bool = false

## Chunk scale (for chunky fog only)
@export_range(0.3, 2.0) var chunk_scale: float = 0.8

## Z-index for fog rendering order
var fog_z_index: int = 0

## Reference to the shader material
var fog_material: ShaderMaterial

## Viewport size
var viewport_size: Vector2


func _ready() -> void:
	# Get viewport size
	viewport_size = get_viewport().get_visible_rect().size
	
	# Create fog layer
	_create_fog_layer()


func _create_fog_layer() -> void:
	# Load noise texture
	var noise_texture := _get_noise_texture()
	
	# Create fog material with appropriate shader
	fog_material = ShaderMaterial.new()
	
	if use_chunky_style:
		# Use chunky foreground shader for big cloud wisps
		fog_material.shader = preload("res://assets/shaders/fog_foreground.gdshader")
		fog_material.set_shader_parameter("noise_texture", noise_texture)
		fog_material.set_shader_parameter("density", fog_density)
		fog_material.set_shader_parameter("speed", fog_speed)
		fog_material.set_shader_parameter("fog_color", fog_color)
		fog_material.set_shader_parameter("chunk_scale", chunk_scale)
		fog_material.set_shader_parameter("top_fade", top_fade)
		fog_material.set_shader_parameter("bottom_fade", bottom_fade)
	else:
		# Use volumetric shader for smooth atmospheric fog
		fog_material.shader = preload("res://assets/shaders/fog_overlay.gdshader")
		fog_material.set_shader_parameter("noise_texture", noise_texture)
		fog_material.set_shader_parameter("density", fog_density)
		fog_material.set_shader_parameter("speed", fog_speed)
		fog_material.set_shader_parameter("fog_color", fog_color)
		fog_material.set_shader_parameter("ground_density", ground_density)
		fog_material.set_shader_parameter("height_falloff", height_falloff)
		fog_material.set_shader_parameter("noise_scale", noise_scale)
		fog_material.set_shader_parameter("turbulence", turbulence)
		fog_material.set_shader_parameter("top_fade", top_fade)
		fog_material.set_shader_parameter("bottom_fade", bottom_fade)
	
	# Create ColorRect for fog
	var fog_rect := ColorRect.new()
	fog_rect.name = "FogRect"
	
	# Set z-index for layering
	fog_rect.z_index = fog_z_index
	
	# Size and position
	fog_rect.size = Vector2(viewport_size.x * 4, fog_height)
	fog_rect.position = Vector2(-viewport_size.x * 1.5, vertical_offset)
	
	# Base color (will be modulated by shader)
	fog_rect.color = Color(1.0, 1.0, 1.0, 1.0)
	
	# Disable mouse interaction
	fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Apply material
	fog_rect.material = fog_material
	
	# Add to this node
	add_child(fog_rect)


func _get_noise_texture() -> NoiseTexture2D:
	# Create high-quality noise for volumetric fog
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.012
	noise.fractal_octaves = 5
	noise.fractal_lacunarity = 2.2
	noise.fractal_gain = 0.45
	
	var texture := NoiseTexture2D.new()
	texture.noise = noise
	texture.width = 512
	texture.height = 512
	texture.seamless = true
	texture.normalize = true
	
	return texture


## Update fog density
func set_fog_density(new_density: float) -> void:
	fog_density = clamp(new_density, 0.0, 1.0)
	if fog_material:
		fog_material.set_shader_parameter("density", fog_density)


## Update fog color
func set_fog_color(new_color: Color) -> void:
	fog_color = new_color
	if fog_material:
		fog_material.set_shader_parameter("fog_color", fog_color)

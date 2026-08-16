class_name CollectibleData extends Resource

@export var name: String = "Item"
@export var collision_radius: float = 3.0
@export var mesh_scene: PackedScene
@export var albedo_texture: Texture2D
@export_range(0.0, 1.0) var roughness: float = 0.5
@export_range(0.0, 1.0) var metallic: float = 0.0

@export var rotation_speed: float = 2.0
@export var float_amplitude: float = 0.1
@export var float_frequency: float = 2.0

@export var mesh_tilt_degrees: Vector3 = Vector3.ZERO
@export var mesh_scale: Vector3 = Vector3.ONE

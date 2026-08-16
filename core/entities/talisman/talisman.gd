class_name Talisman extends Area3D

@export_group("Detection")
@export var detection_radius: float = 2.0

@export_group("Visuals")
@export var bob_speed: float = 1.5
@export var bob_amplitude: float = 0.15
@export var rotation_speed: float = 0.8
@export var glow_color_idle: Color = Color(0.2, 0.8, 0.4, 0.8)
@export var glow_color_active: Color = Color(0.4, 1.0, 0.6, 1.0)

var is_player_in_range: bool = false

var _time: float = 0.0
var _base_position: Vector3 = Vector3.ZERO

func _ready() -> void :
	add_to_group("jade_target")
	_base_position = global_position

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void :
	_time += delta

	var bob_y: float = sin(_time * bob_speed) * bob_amplitude
	global_position = _base_position + Vector3.UP * bob_y

	rotation.y += rotation_speed * delta

func _on_body_entered(body: Node3D) -> void :
	if body is Player:
		is_player_in_range = true

func _on_body_exited(body: Node3D) -> void :
	if body is Player:
		is_player_in_range = false

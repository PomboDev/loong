class_name JadeIdleState extends JadeState

@export_group("Float Settings")
@export var follow_speed: float = 8.0
@export var float_height: float = 0.7
@export var side_offset: float = 0.6
@export var behind_offset: float = 0.5

@export_group("Bob Motion")
@export var bob_frequency: float = 1.5
@export var bob_amplitude: float = 0.08

@export_group("Wall Avoidance")
@export var wall_check_distance: float = 0.8

var _time: float = 0.0
var _current_side: float = -1.0


func enter() -> void :
	pearl.top_level = false
	pearl.visible = true
	_time = 0.0


func exit() -> void :
	pass


func update(_delta: float) -> void :
	pass


func physics_update(delta: float) -> void :
	_time += delta

	var player_transform: Transform3D = Context.player.skin_mesh.transform
	var player_right: Vector3 = player_transform.basis.x.normalized()
	var player_back: Vector3 = player_transform.basis.z.normalized()
	var side_dir: Vector3 = player_right * _current_side
	var ray_result: Dictionary = CasterFeature.raycast(
		Context.player.global_position + Vector3.UP * float_height, 
		side_dir, 
		wall_check_distance, 
		[Context.player.get_rid()]
	)

	if not ray_result.is_empty():
		_current_side = - _current_side

	var bob_y: float = sin(_time * bob_frequency * TAU) * bob_amplitude
	var target_local: Vector3 = Vector3.ZERO
	target_local += player_back * behind_offset
	target_local += player_right * _current_side * side_offset
	target_local += Vector3.UP * (float_height + bob_y)

	var target_world: Vector3 = Context.player.global_position + target_local

	if pearl.top_level:
		pearl.global_position = pearl.global_position.lerp(target_world, follow_speed * delta)
	else:
		var local_target: Vector3 = target_local
		pearl.position = pearl.position.lerp(local_target, follow_speed * delta)

extends Node

signal path_changed(new_path: Path3D)

@export_group("Settings")
@export var path_group_name: String = "camera_paths"
@export var look_ahead_distance: float = 8.0
@export var path_search_interval: float = 0.2
@export var activation_distance_sq: float = 200.0

var _all_paths: Array[Path3D] = []
var _active_path: Path3D
var _time_since_last_search: float = 0.0

var target_focus_point: Vector3 = Vector3.ZERO
var is_active_on_path: bool = false

func _ready() -> void :
	pass

func _load_paths() -> void :
	_all_paths.clear()
	var nodes = get_tree().get_nodes_in_group(path_group_name)
	for node in nodes:
		if node is Path3D:
			_all_paths.append(node)

func _process(delta: float) -> void :
	if _all_paths.is_empty():
		return

	_time_since_last_search += delta
	if _time_since_last_search > path_search_interval:
		_time_since_last_search = 0.0
		_update_closest_path()

	if _active_path:
		_calculate_prediction()
	else:
		is_active_on_path = false

func _update_closest_path() -> void :
	var player_pos = Context.player.global_position
	var nearest_dist_sq = INF
	var nearest_path: Path3D = null

	for path in _all_paths:
		var local_pos = path.to_local(player_pos)
		var offset = path.curve.get_closest_offset(local_pos)
		var curve_pos = path.to_global(path.curve.sample_baked(offset))

		var real_dist_sq = curve_pos.distance_squared_to(player_pos)

		if real_dist_sq < nearest_dist_sq:
			nearest_dist_sq = real_dist_sq
			nearest_path = path

	if nearest_dist_sq > activation_distance_sq:
		_active_path = null
		return

	if nearest_path != _active_path:
		_active_path = nearest_path
		path_changed.emit(nearest_path)

func _calculate_prediction() -> void :
	var player_pos = Context.player.global_position
	var local_player_pos = _active_path.to_local(player_pos)
	var current_offset = _active_path.curve.get_closest_offset(local_player_pos)
	var future_offset = current_offset + look_ahead_distance
	var path_len = _active_path.curve.get_baked_length()

	if future_offset > path_len:
		future_offset = path_len

	var local_prediction = _active_path.curve.sample_baked(future_offset)
	target_focus_point = _active_path.to_global(local_prediction)
	is_active_on_path = true

func set_force_path(path: Path3D) -> void :
	_active_path = path

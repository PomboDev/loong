@tool
class_name CollectibleSpawner extends Node3D

enum ShapeType{LINE, CIRCLE, PATH}

@export_group("Settings")
@export var collectible_scene: PackedScene
@export var count: int = 5:
	set(value):
		count = max(1, value)

@export_group("Shape")
@export var shape_type: ShapeType = ShapeType.LINE:
	set(value):
		shape_type = value
		notify_property_list_changed()

@export var radius: float = 5.0
@export var line_vector: Vector3 = Vector3(10, 0, 0)
@export var path_node: Path3D

@export_group("Placement")
@export var raycast_to_floor: bool = true
@export_flags_3d_physics var collision_mask: int = 1
@export var raycast_height_offset: float = 5.0
@export var raycast_distance: float = 20.0
@export var spawn_height_offset: float = 0.75

@export_group("Actions")
@export var preview_color: Color = Color.GREEN_YELLOW

@export_tool_button("Create Path Node", "_create_path_node") var btn_create_path: Callable = _create_path_node
@export_tool_button("Bake Collectibles", "_bake") var btn_bake: Callable = _bake
@export_tool_button("Clear Collectibles", "_clear") var btn_clear: Callable = _clear


func _process(_delta: float) -> void :
	if not Engine.is_editor_hint():
		return

	var transforms = _calculate_transforms()

	for t in transforms:
		DebugDraw3D.draw_sphere(t.origin, 0.2, preview_color)
		DebugDraw3D.draw_line(t.origin, t.origin + t.basis.y * 0.5, Color.GREEN)
		DebugDraw3D.draw_line(t.origin, t.origin + t.basis.z * 0.5, Color.BLUE)

	if transforms.size() > 1:
		for i in range(transforms.size() - 1):
			DebugDraw3D.draw_line(transforms[i].origin, transforms[i + 1].origin, preview_color)

	if shape_type == ShapeType.CIRCLE:
		_draw_circle_hint()


func _draw_circle_hint() -> void :
	var segments = 32
	var prev = Vector3(radius, 0, 0)
	for i in range(1, segments + 1):
		var angle = i * TAU / segments
		var next = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		DebugDraw3D.draw_line(global_position + prev, global_position + next, preview_color * 0.5)
		prev = next


func _calculate_transforms() -> Array[Transform3D]:
	var results: Array[Transform3D] = []

	match shape_type:
		ShapeType.LINE:
			for i in range(count):
				var t = 0.0 if count == 1 else float(i) / (count - 1)
				var pos = global_position + line_vector * t
				results.append(Transform3D(Basis(), pos))

		ShapeType.CIRCLE:
			for i in range(count):
				var angle = (float(i) / count) * TAU
				var offset = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
				var pos = global_position + offset

				var t3d = Transform3D(Basis(), pos)
				results.append(t3d)

		ShapeType.PATH:
			if not path_node or not path_node.curve or path_node.curve.point_count < 2:
				return []

			var curve = path_node.curve
			var length = curve.get_baked_length()

			for i in range(count):
				var t = 0.0 if count == 1 else float(i) / (count - 1)
				var offset = length * t

				var local_pos = curve.sample_baked(offset, true)
				var global_pos = path_node.global_transform * local_pos
				results.append(Transform3D(Basis(), global_pos))

	if raycast_to_floor:
		var space_state = get_world_3d().direct_space_state
		if space_state:
			for i in range(results.size()):
				var origin = results[i].origin + Vector3.UP * raycast_height_offset
				var target = origin + Vector3.DOWN * raycast_distance

				var query = PhysicsRayQueryParameters3D.create(origin, target)
				query.collision_mask = collision_mask

				var result = space_state.intersect_ray(query)
				if result:
					results[i].origin = result["position"] + Vector3.UP * spawn_height_offset

	return results


func _create_path_node() -> void :
	var path = Path3D.new()
	path.name = "SpawnerPath"
	add_child(path)
	if get_tree().edited_scene_root:
		path.owner = get_tree().edited_scene_root
	path_node = path
	shape_type = ShapeType.PATH
	Log.info("Created 'SpawnerPath'")


func _bake() -> void :
	if not collectible_scene:
		push_warning("No Collectible Scene assigned!")
		return

	var transforms = _calculate_transforms()
	var root = get_tree().edited_scene_root

	for tf in transforms:
		var instance = collectible_scene.instantiate()
		add_child(instance)

		instance.global_position = tf.origin

		if root:
			instance.owner = root

	Log.info("Baked %d collectibles." % transforms.size())


func _clear() -> void :
	var cleared_count = 0
	for child in get_children():
		if child is Path3D:
			continue
		child.queue_free()
		cleared_count += 1
	Log.info("Cleared %d items." % cleared_count)

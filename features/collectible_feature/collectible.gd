@tool
class_name Collectible extends Area3D

const COLLECTIBLE_SHADER = preload("res://features/collectible_feature/collectible_shader.gdshader")

@export var data: CollectibleData:
	set(value):
		data = value
		if is_inside_tree():
			_refresh()

var _mesh_instance: MeshInstance3D


func _ready() -> void :
	if not is_in_group("collectibles"):
		add_to_group("collectibles")

	if Engine.is_editor_hint():
		set_process(true)
	else:
		set_process(false)
		_refresh()
		body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void :
	if not data:
		return

	DebugDraw3D.draw_sphere(global_position, data.collision_radius, Color(0, 1, 1, 0.5))
	DebugDraw3D.draw_sphere(global_position, 0.01, Color.RED)


func _refresh() -> void :
	for child in get_children():
		child.queue_free()

	if not data:
		return
	_build_visuals()


func _build_visuals() -> void :
	var collision = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = data.collision_radius
	collision.shape = sphere
	add_child(collision)

	if data.mesh_scene:
		var scene_root = data.mesh_scene.instantiate()
		add_child(scene_root)
		_find_and_apply_shader(scene_root)


func _find_and_apply_shader(node: Node) -> void :
	if node is MeshInstance3D:
		_mesh_instance = node
		_apply_performance_shader()

	for child in node.get_children():
		_find_and_apply_shader(child)


func _apply_performance_shader() -> void :
	if not _mesh_instance:
		return

	var mat = ShaderMaterial.new()
	mat.shader = COLLECTIBLE_SHADER

	var tex = data.albedo_texture
	var col = Color.WHITE

	if not tex:
		var mesh = _mesh_instance.mesh
		if mesh and mesh.get_surface_count() > 0:
			var original_mat = mesh.surface_get_material(0)
			if original_mat is BaseMaterial3D:
				tex = original_mat.albedo_texture
				col = original_mat.albedo_color

	if tex:
		mat.set_shader_parameter("texture_albedo", tex)

	mat.set_shader_parameter("albedo_color", col)

	mat.set_shader_parameter("roughness", data.roughness)
	mat.set_shader_parameter("metallic", data.metallic)
	mat.set_shader_parameter("rotation_speed", data.rotation_speed)
	mat.set_shader_parameter("bounce_amplitude", data.float_amplitude)
	mat.set_shader_parameter("bounce_frequency", data.float_frequency)

	var rot_basis = Basis.from_euler(data.mesh_tilt_degrees * (PI / 180.0))
	var scale_basis = Basis.from_scale(data.mesh_scale)

	var final_correction = scale_basis * rot_basis
	var normal_correction = final_correction.inverse().transposed()

	mat.set_shader_parameter("correction_matrix", final_correction)
	mat.set_shader_parameter("normal_matrix", normal_correction)

	_mesh_instance.material_override = mat


func _on_body_entered(body: Node3D) -> void :
	if body is Player:
		_collect()


func _collect() -> void :
	if data:
		CollectibleFeature.notify_collected(data.name, 1)
	queue_free()

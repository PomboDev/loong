extends Node

signal camera_switched(new_controller_name: String)

var cameras: Dictionary = {
	"PlatformerCamera": PlatformerCamera.new(), 
}
var default_controller_name: String = "PlatformerCamera"

var camera_node: Camera3D
var auto_find_controllers: bool = true

var _controllers: Dictionary[String, BaseCamera3D] = {}
var _active_controller: BaseCamera3D
var _shake_strength: float = 0.0
var _shake_decay: float = 5.0

func _ready() -> void :
	if not camera_node:
		var existing = find_child("MainCamera", false, false)
		if existing:
			camera_node = existing
		else:
			camera_node = Camera3D.new()
			camera_node.name = "MainCamera"
			add_child(camera_node)

	Context.camera_node = camera_node

	for cam_name in cameras:
		var cam_instance = cameras[cam_name]
		cam_instance.name = cam_name
		if not cam_instance.is_inside_tree():
			add_child(cam_instance)
		_register_controller(cam_instance)

	if auto_find_controllers:
		for child in get_children():
			if child is BaseCamera3D and not _controllers.has(child.name):
				_register_controller(child)


func initialize_with_target(target: Node3D) -> void :
	Log.info("Initializing Cameras with target: %s" % target.name)

	if Context.player != target:
		Context.player = target

	for cam_name in _controllers:
		var controller = _controllers[cam_name]
		if controller.has_method("_initialize_controller"):
			controller._initialize_controller(target, self)

	if not _active_controller:
		if default_controller_name != "" and _controllers.has(default_controller_name):
			switch_camera(default_controller_name)


func _physics_process(delta: float) -> void :
	if _active_controller:
		_active_controller.update_camera(delta)

	if _shake_strength > 0:
		_apply_shake(delta)


func switch_camera(controller_name: String) -> void :
	var new_controller = _controllers.get(controller_name)

	if not new_controller:
		Log.error("CameraManager: Cannot switch to missing camera '%s'" % controller_name)
		return

	if _active_controller == new_controller:
		return

	if _active_controller:
		_active_controller.deactivate()

	_active_controller = new_controller
	_active_controller.activate()

	Log.info("Camera switched to: " + controller_name)
	camera_switched.emit(controller_name)


func add_trauma(amount: float) -> void :
	_shake_strength = clamp(_shake_strength + amount, 0.0, 1.0)


func _register_controller(controller: BaseCamera3D) -> void :
	_controllers[controller.name] = controller
	if Context.player and controller.has_method("_initialize_controller"):
		controller._initialize_controller(Context.player, self)


func _apply_shake(delta: float) -> void :
	_shake_strength = move_toward(_shake_strength, 0.0, _shake_decay * delta)

	var shake_amount = _shake_strength * _shake_strength
	var offset = Vector3(
		randf_range(-1.0, 1.0) * shake_amount, 
		randf_range(-1.0, 1.0) * shake_amount, 
		0.0
	)

	if is_instance_valid(camera_node):
		camera_node.h_offset = offset.x
		camera_node.v_offset = offset.y

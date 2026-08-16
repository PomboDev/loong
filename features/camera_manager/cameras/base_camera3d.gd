@abstract
class_name BaseCamera3D extends Node3D

var player: Node3D
var camera_manager: CameraManagerFeature
var camera_node: Camera3D

func _initialize_controller(p_player: Node3D, p_manager: CameraManagerFeature) -> void :
	player = p_player
	camera_manager = p_manager
	camera_node = p_manager.camera_node


@abstract func update_camera(delta: float) -> void 

@abstract func activate() -> void 

@abstract func deactivate() -> void 

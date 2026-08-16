extends Node

var debug_enabled: bool = false
var debug_duration: float = 0.0
var debug_color_success: Color = Color.GREEN
var debug_color_hit: Color = Color.RED
var debug_color_sweep: Color = Color(0, 0, 0.7)
var debug_color_motion: Color = Color.YELLOW

var _params_pool: Array[PhysicsShapeQueryParameters3D] = []
var _sphere_pool: Array[SphereShape3D] = []
var _box_pool: Array[BoxShape3D] = []
var _capsule_pool: Array[CapsuleShape3D] = []
var _cylinder_pool: Array[CylinderShape3D] = []

const INITIAL_POOL_SIZE: int = 8
const MAX_POOL_SIZE: int = 64


func _ready() -> void :
	_expand_pool(_params_pool, PhysicsShapeQueryParameters3D, INITIAL_POOL_SIZE)
	_expand_pool(_sphere_pool, SphereShape3D, INITIAL_POOL_SIZE)
	_expand_pool(_box_pool, BoxShape3D, INITIAL_POOL_SIZE)
	_expand_pool(_capsule_pool, CapsuleShape3D, INITIAL_POOL_SIZE)
	_expand_pool(_cylinder_pool, CylinderShape3D, INITIAL_POOL_SIZE)


func check_sphere(
	origin: Vector3, 
	radius: float, 
	exclude: Array[RID] = [], 
	mask: int = 4294967295, 
	max_results: int = 32, 
	collide_with_bodies: bool = true, 
	collide_with_areas: bool = false
) -> Array[Dictionary]:
	var shape: = _checkout_sphere(radius)
	var params: = _checkout_params()

	params.shape = shape
	params.exclude = exclude
	params.transform = Transform3D(Basis.IDENTITY, origin)
	params.collision_mask = mask
	params.collide_with_bodies = collide_with_bodies
	params.collide_with_areas = collide_with_areas

	var results: = _get_space_state().intersect_shape(params, max_results)

	if debug_enabled:
		var color: = debug_color_success if results.is_empty() else debug_color_hit
		DebugDraw3D.draw_sphere(origin, radius, color, debug_duration)

	_recycle_params(params)
	_recycle_sphere(shape)

	return results


func check_box(
	origin: Vector3, 
	size: Vector3, 
	rotation: Quaternion = Quaternion.IDENTITY, 
	exclude: Array[RID] = [], 
	mask: int = 4294967295, 
	max_results: int = 32, 
	collide_with_bodies: bool = true, 
	collide_with_areas: bool = false
) -> Array[Dictionary]:
	var shape: = _checkout_box(size)
	var params: = _checkout_params()

	params.shape = shape
	params.exclude = exclude
	params.transform = Transform3D(Basis(rotation), origin)
	params.collision_mask = mask
	params.collide_with_bodies = collide_with_bodies
	params.collide_with_areas = collide_with_areas

	var results: = _get_space_state().intersect_shape(params, max_results)

	if debug_enabled:
		var color: = debug_color_success if results.is_empty() else debug_color_hit
		DebugDraw3D.draw_box(origin, rotation, size, color, debug_duration)

	_recycle_params(params)
	_recycle_box(shape)

	return results


func check_capsule(
	origin: Vector3, 
	radius: float, 
	height: float, 
	rotation: Quaternion = Quaternion.IDENTITY, 
	exclude: Array[RID] = [], 
	mask: int = 4294967295, 
	max_results: int = 32, 
	collide_with_bodies: bool = true, 
	collide_with_areas: bool = false
) -> Array[Dictionary]:
	var shape: = _checkout_capsule(radius, height)
	var params: = _checkout_params()

	params.shape = shape
	params.exclude = exclude
	params.transform = Transform3D(Basis(rotation), origin)
	params.collision_mask = mask
	params.collide_with_bodies = collide_with_bodies
	params.collide_with_areas = collide_with_areas

	var results: = _get_space_state().intersect_shape(params, max_results)

	if debug_enabled:
		var color: = debug_color_success if results.is_empty() else debug_color_hit
		DebugDraw3D.draw_capsule(origin, rotation, radius, height, color, debug_duration)

	_recycle_params(params)
	_recycle_capsule(shape)

	return results


func raycast(
	origin: Vector3, 
	direction: Vector3, 
	distance: float = 1000.0, 
	exclude: Array[RID] = [], 
	mask: int = 4294967295, 
	collide_with_bodies: bool = true, 
	collide_with_areas: bool = false, 
	hit_from_inside: bool = false, 
	hit_back_faces: bool = true
) -> Dictionary:
	var dir_normalized: = direction.normalized()
	var end: = origin + dir_normalized * distance
	var query: = PhysicsRayQueryParameters3D.create(origin, end, mask, exclude)
	query.collide_with_bodies = collide_with_bodies
	query.collide_with_areas = collide_with_areas
	query.hit_from_inside = hit_from_inside
	query.hit_back_faces = hit_back_faces

	var result: = _get_space_state().intersect_ray(query)

	if debug_enabled:
		if result.is_empty():
			DebugDraw3D.draw_line(origin, end, Color.GRAY, debug_duration)
		else:
			DebugDraw3D.draw_line(origin, result.position, debug_color_hit, debug_duration)
			DebugDraw3D.draw_arrow(
				result.position, 
				result.position + result.normal * 0.5, 
				Color.BLUE, 
				0.1, 
				debug_duration
			)

	return result


func raycast_cone(
	origin: Vector3, 
	direction: Vector3, 
	distance: float = 1000.0, 
	cone_angle: float = 15.0, 
	ray_count: int = 5, 
	exclude: Array[RID] = [], 
	mask: int = 4294967295, 
	collide_with_bodies: bool = true, 
	collide_with_areas: bool = false
) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var dir_normalized: = direction.normalized()
	var angle_step: float = (cone_angle * 2.0) / max(ray_count - 1, 1)

	for i in ray_count:
		var angle: = - cone_angle + (i * angle_step)
		var rotated_dir: = dir_normalized.rotated(
			dir_normalized.cross(Vector3.UP).normalized(), deg_to_rad(angle)
		)
		var hit: = raycast(
			origin, rotated_dir, distance, exclude, mask, collide_with_bodies, collide_with_areas
		)
		if not hit.is_empty():
			results.append(hit)

	return results


func sweep_sphere(
	origin: Vector3, 
	radius: float, 
	motion: Vector3, 
	exclude: Array[RID] = [], 
	mask: int = 4294967295, 
	collide_with_bodies: bool = true, 
	collide_with_areas: bool = false
) -> Array[Dictionary]:
	var shape: = _checkout_sphere(radius)
	var result: = _execute_sweep(
		shape, 
		Transform3D(Basis(), origin), 
		motion, 
		exclude, 
		mask, 
		collide_with_bodies, 
		collide_with_areas
	)
	_recycle_sphere(shape)
	return result


func sweep_box(
	origin: Vector3, 
	size: Vector3, 
	rotation: Quaternion, 
	motion: Vector3, 
	exclude: Array[RID] = [], 
	mask: int = 4294967295, 
	collide_with_bodies: bool = true, 
	collide_with_areas: bool = false
) -> Array[Dictionary]:
	var shape: = _checkout_box(size)
	var result: = _execute_sweep(
		shape, 
		Transform3D(Basis(rotation), origin), 
		motion, 
		exclude, 
		mask, 
		collide_with_bodies, 
		collide_with_areas
	)
	_recycle_box(shape)
	return result


func sweep_capsule(
	origin: Vector3, 
	radius: float, 
	height: float, 
	rotation: Quaternion, 
	motion: Vector3, 
	exclude: Array[RID] = [], 
	mask: int = 4294967295, 
	collide_with_bodies: bool = true, 
	collide_with_areas: bool = false
) -> Array[Dictionary]:
	var shape: = _checkout_capsule(radius, height)
	var result: = _execute_sweep(
		shape, 
		Transform3D(Basis(rotation), origin), 
		motion, 
		exclude, 
		mask, 
		collide_with_bodies, 
		collide_with_areas
	)
	_recycle_capsule(shape)
	return result


func cast_motion_sphere(
	origin: Vector3, 
	radius: float, 
	motion: Vector3, 
	exclude: Array[RID] = [], 
	mask: int = 4294967295, 
	collide_with_bodies: bool = true, 
	collide_with_areas: bool = false
) -> PackedFloat32Array:
	var shape: = _checkout_sphere(radius)
	var result: = _execute_cast_motion(
		shape, 
		Transform3D(Basis(), origin), 
		motion, 
		exclude, 
		mask, 
		collide_with_bodies, 
		collide_with_areas
	)
	_recycle_sphere(shape)
	return result


func cast_motion_box(
	origin: Vector3, 
	size: Vector3, 
	rotation: Quaternion, 
	motion: Vector3, 
	exclude: Array[RID] = [], 
	mask: int = 4294967295, 
	collide_with_bodies: bool = true, 
	collide_with_areas: bool = false
) -> PackedFloat32Array:
	var shape: = _checkout_box(size)
	var result: = _execute_cast_motion(
		shape, 
		Transform3D(Basis(rotation), origin), 
		motion, 
		exclude, 
		mask, 
		collide_with_bodies, 
		collide_with_areas
	)
	_recycle_box(shape)
	return result


func is_position_valid_sphere(
	position: Vector3, radius: float, exclude: Array[RID] = [], mask: int = 4294967295
) -> bool:
	return check_sphere(position, radius, exclude, mask, 1, true, false).is_empty()


func find_closest_point(
	origin: Vector3, radius: float, exclude: Array[RID] = [], mask: int = 4294967295
) -> Dictionary:
	var hits: = check_sphere(origin, radius, exclude, mask, 32, true, false)
	if hits.is_empty():
		return {}

	var closest_dist: = INF
	var closest_pos: = Vector3.ZERO

	for hit in hits:
		if hit.has("collider") and hit.collider is CollisionObject3D:
			var collider: CollisionObject3D = hit.collider
			var dist: = origin.distance_to(collider.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest_pos = collider.global_position

	return {"position": closest_pos, "distance": closest_dist}


func get_colliders_sorted(
	origin: Vector3, 
	radius: float, 
	exclude: Array[RID] = [], 
	mask: int = 4294967295, 
	max_results: int = 32
) -> Array[Dictionary]:
	var hits: = check_sphere(origin, radius, exclude, mask, max_results, true, false)
	for hit in hits:
		if hit.has("collider") and hit.collider is Node3D:
			hit["distance"] = origin.distance_to(hit.collider.global_position)

	hits.sort_custom( func(a, b): return a.get("distance", INF) < b.get("distance", INF))
	return hits


func _execute_sweep(
	shape: Shape3D, 
	trans: Transform3D, 
	motion: Vector3, 
	exclude: Array[RID] = [], 
	mask: int = 4294967295, 
	collide_with_bodies: bool = true, 
	collide_with_areas: bool = false
) -> Array[Dictionary]:
	var params: = _checkout_params()
	params.shape = shape
	params.exclude = exclude
	params.transform = trans
	params.motion = motion
	params.collision_mask = mask
	params.collide_with_bodies = collide_with_bodies
	params.collide_with_areas = collide_with_areas

	var results: Array[Dictionary] = []
	var fractions: = _get_space_state().cast_motion(params)
	var hit_fraction: float = 1.0

	if not fractions.is_empty() and fractions.size() >= 2:
		var unsafe: = fractions[1]
		if unsafe < 1.0:
			hit_fraction = unsafe

			var hit_transform: = trans
			hit_transform.origin += motion * unsafe

			params.transform = hit_transform
			params.motion = Vector3.ZERO

			results = _get_space_state().intersect_shape(params)

	if debug_enabled:
		var hit: = not results.is_empty()
		var color: = debug_color_hit if hit else debug_color_sweep
		var end_pos: = trans.origin + motion * hit_fraction

		if shape is SphereShape3D:
			DebugDraw3D.draw_sphere(end_pos, shape.radius, color, debug_duration)
		elif shape is BoxShape3D:
			DebugDraw3D.draw_box(trans.origin, trans.basis, shape.size, color, debug_duration)
		elif shape is CylinderShape3D or shape is CapsuleShape3D:
			DebugDraw3D.draw_capsule(
				trans.origin, trans.basis, shape.radius, shape.height, color, debug_duration
			)
		DebugDraw3D.draw_line(trans.origin, end_pos, color, debug_duration)

	_recycle_params(params)
	return results


func _execute_cast_motion(
	shape: Shape3D, 
	trans: Transform3D, 
	motion: Vector3, 
	exclude: Array[RID] = [], 
	mask: int = 4294967295, 
	collide_with_bodies: bool = true, 
	collide_with_areas: bool = false
) -> PackedFloat32Array:
	var params: = _checkout_params()
	params.shape = shape
	params.exclude = exclude
	params.transform = trans
	params.motion = motion
	params.collision_mask = mask
	params.collide_with_bodies = collide_with_bodies
	params.collide_with_areas = collide_with_areas

	var result: = _get_space_state().cast_motion(params)

	if debug_enabled and result.size() > 0:
		var safe: = result[0]
		var color: = debug_color_motion if safe < 1.0 else debug_color_success
		var safe_pos: = trans.origin + (motion * safe)

		if shape is SphereShape3D:
			DebugDraw3D.draw_sphere(safe_pos, shape.radius, color, debug_duration)
		elif shape is BoxShape3D:
			DebugDraw3D.draw_box(safe_pos, trans.basis, shape.size, color, debug_duration)
		elif shape is CylinderShape3D or shape is CapsuleShape3D:
			DebugDraw3D.draw_capsule(
				safe_pos, trans.basis, shape.radius, shape.height, color, debug_duration
			)
		DebugDraw3D.draw_line(trans.origin, safe_pos, color, debug_duration)

	_recycle_params(params)
	return result


func _get_space_state() -> PhysicsDirectSpaceState3D:
	var viewport: = get_viewport()
	var world: = viewport.find_world_3d()
	return world.direct_space_state


func _checkout_params() -> PhysicsShapeQueryParameters3D:
	if _params_pool.is_empty():
		return PhysicsShapeQueryParameters3D.new()
	return _params_pool.pop_back()


func _recycle_params(params: PhysicsShapeQueryParameters3D) -> void :
	params.motion = Vector3.ZERO
	params.exclude = []
	params.collide_with_bodies = true
	params.collide_with_areas = false
	params.collision_mask = 4294967295

	if _params_pool.size() < MAX_POOL_SIZE:
		_params_pool.append(params)


func _checkout_sphere(radius: float) -> SphereShape3D:
	var shape: SphereShape3D
	if _sphere_pool.is_empty():
		shape = SphereShape3D.new()
	else:
		shape = _sphere_pool.pop_back()

	shape.radius = radius
	return shape


func _recycle_sphere(shape: SphereShape3D) -> void :
	if _sphere_pool.size() < MAX_POOL_SIZE:
		_sphere_pool.append(shape)


func _checkout_box(size: Vector3) -> BoxShape3D:
	var shape: BoxShape3D
	if _box_pool.is_empty():
		shape = BoxShape3D.new()
	else:
		shape = _box_pool.pop_back()

	shape.size = size
	return shape


func _recycle_box(shape: BoxShape3D) -> void :
	if _box_pool.size() < MAX_POOL_SIZE:
		_box_pool.append(shape)


func _checkout_capsule(radius: float, height: float) -> CapsuleShape3D:
	var shape: CapsuleShape3D
	if _capsule_pool.is_empty():
		shape = CapsuleShape3D.new()
	else:
		shape = _capsule_pool.pop_back()

	shape.radius = radius
	shape.height = height
	return shape


func _recycle_capsule(shape: CapsuleShape3D) -> void :
	if _capsule_pool.size() < MAX_POOL_SIZE:
		_capsule_pool.append(shape)


func _checkout_cylinder(radius: float, height: float) -> CylinderShape3D:
	var shape: CylinderShape3D
	if _cylinder_pool.is_empty():
		shape = CylinderShape3D.new()
	else:
		shape = _cylinder_pool.pop_back()

	shape.radius = radius
	shape.height = height
	return shape


func _recycle_cylinder(shape: CylinderShape3D) -> void :
	if _cylinder_pool.size() < MAX_POOL_SIZE:
		_cylinder_pool.append(shape)


func _expand_pool(pool: Array, type: Variant, count: int) -> void :
	for i in count:
		pool.append(type.new())


func cleanup() -> void :
	_params_pool.clear()
	_sphere_pool.clear()
	_box_pool.clear()
	_capsule_pool.clear()
	_cylinder_pool.clear()


func get_pool_stats() -> Dictionary:
	return {
		"params_pool": _params_pool.size(), 
		"sphere_pool": _sphere_pool.size(), 
		"box_pool": _box_pool.size(), 
		"capsule_pool": _capsule_pool.size(), 
		"cylinder_pool": _cylinder_pool.size(), 
	}

class_name Clock extends RefCounted

var length: float

var _start: int
var _end: int


func _init(new_length: float = 0.0) -> void :
	length = new_length


func is_running() -> bool:
	return Time.get_ticks_msec() < _end


func is_finished() -> bool:
	return Time.get_ticks_msec() >= _end


func update(new_length: float = 0.0) -> void :
	if new_length != 0:
		length = new_length


func run(new_length: float = 0.0) -> void :
	if new_length != 0:
		length = new_length

	_start = Time.get_ticks_msec()
	_end = _start + int(length * 1000)


func finish() -> void :
	_end = 0

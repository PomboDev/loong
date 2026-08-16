class_name PlayerState extends State

@onready var player: Player = owner



const ANIM_C_HOP: StringName = "conditions/hop"
const ANIM_C_DIVE: StringName = "conditions/dive"
const ANIM_C_IDLE: StringName = "conditions/idle"
const ANIM_C_JUMP: StringName = "conditions/jump"
const ANIM_C_RUN: StringName = "conditions/run"
const ANIM_C_SKID: StringName = "conditions/skid"
const ANIM_C_WALK: StringName = "conditions/walk"
const ANIM_C_WALL_STICK: StringName = "conditions/wall_stick"


const ANIM_B_HOP: StringName = "hop/blend_position"
const ANIM_B_JUMP: StringName = "jump/blend_position"
const ANIM_B_SKID_JUMP: StringName = "skid_jump/blend_position"
const ANIM_B_WALK: StringName = "walk/blend_position"


func enter() -> void :
	pass


func exit() -> void :
	pass


func update(_d: float) -> void :
	pass


func physics_update(_delta: float) -> void :
	pass


func set_anim_condition(condition: StringName, value: bool) -> void :
	player.anim_tree.set("parameters/" + condition, value)


func set_anim_blend(blend: StringName, value: float) -> void :
	player.anim_tree.set("parameters/" + blend, value)

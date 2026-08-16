extends Node

var player: Player
var camera_node: Camera3D

const WORLD: int = 1 << 0
const PLAYER: int = 1 << 1
const ENEMY: int = 1 << 2
const WATER: int = 1 << 3
const LAVA: int = 1 << 4
const SPIKES: int = 1 << 5

const PLAYER_WALKABLE: int = WORLD
const HAZARDS: int = LAVA | SPIKES
const ENEMY_SCAN: int = PLAYER | WORLD
const PROJECTILE_HIT: int = WORLD | PLAYER | ENEMY

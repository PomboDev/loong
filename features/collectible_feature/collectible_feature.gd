extends Node

var collection: Dictionary = {}

func _ready() -> void :
	pass

func notify_collected(item_name: String, amount: int = 1) -> void :
	if not collection.has(item_name):
		collection[item_name] = 0

	collection[item_name] += amount
	Log.info("Collected: %s | Total: %d" % [item_name, collection[item_name]])

func clear_collection() -> void :
	collection.clear()
	Log.info("Collection cleared.")

func get_scene_statistics() -> Dictionary:
	var stats: Dictionary = {}

	var active_nodes = get_tree().get_nodes_in_group("collectibles")
	for node in active_nodes:
		if node is Collectible and node.data:
			var _name = node.data.name
			if not stats.has(_name):
				stats[_name] = {"active": 0, "collected": 0}
			stats[_name]["active"] += 1

	for _name in collection:
		if not stats.has(_name):
			stats[_name] = {"active": 0, "collected": 0}
		stats[_name]["collected"] = collection[_name]

	return stats

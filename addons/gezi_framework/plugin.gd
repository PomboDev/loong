@tool
extends EditorPlugin

const FEATURES_PATH = "res://features/"
var _managed_features: Dictionary = {}

func _enter_tree() -> void :
	var efsc = EditorInterface.get_resource_filesystem()
	efsc.filesystem_changed.connect(_scan_and_sync)

	_scan_and_sync()
	Log.info("[Gezi Framework] Plugin active. Monitoring features via EditorFileSystem.")

func _exit_tree() -> void :
	var efsc = EditorInterface.get_resource_filesystem()
	if efsc.filesystem_changed.is_connected(_scan_and_sync):
		efsc.filesystem_changed.disconnect(_scan_and_sync)

	for f_name in _managed_features:
		remove_autoload_singleton(f_name)

func _scan_and_sync() -> void :
	var current_on_disk = _find_feature_files(FEATURES_PATH)
	var changed = false

	for f_name in current_on_disk:
		var path = current_on_disk[f_name]

		if not _managed_features.has(f_name) or _managed_features[f_name] != path:
			if ResourceLoader.exists(path):
				add_autoload_singleton(f_name, path)
				_managed_features[f_name] = path
				changed = true
				Log.info("[Gezi Framework] Registered Singleton: " + f_name)

	var to_remove = []
	for f_name in _managed_features:
		var found = false
		for disk_name in current_on_disk:
			if disk_name == f_name:
				found = true
				break
		if not found:
			to_remove.append(f_name)

	for f_name in to_remove:
		remove_autoload_singleton(f_name)
		_managed_features.erase(f_name)
		changed = true
		Log.info("[Gezi Framework] Removed Singleton: " + f_name)

func _find_feature_files(path: String) -> Dictionary:
	var results = {}
	var dir = DirAccess.open(path)
	if not dir: return results

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name == "." or file_name == "..":
			file_name = dir.get_next()
			continue

		var full_path = path.path_join(file_name)
		if dir.current_is_dir():
			results.merge(_find_feature_files(full_path))
		elif file_name.ends_with("_feature.gd"):
			var base_name = file_name.get_basename().to_pascal_case()
			results[base_name] = full_path

		file_name = dir.get_next()
	return results

extends EditorConsoleSingleton.ConsoleCommandSetBase

const HIDDEN_DIR = "res://addons/editor_console/src/default_commands/hidden/"
const EDITOR_COMMANDS_DIR = "res://addons/editor_console/src/default_commands/misc/editor_console/"
const TEMP_DIR = "res://temp_console/"
## gdsh_lib packages: utils, tree, editor and data (utils/tree/editor shared with mcp-sh-godot's plugin). Each manifest
## preload keeps its package in plugin exports, and its (export-rewritten) path locates the
## package's cmd/ dir.
const UtilsManifest = preload("res://addons/_lib/gdsh_lib/utils/cmd/manifest.gd")
const TreeManifest = preload("res://addons/_lib/gdsh_lib/tree/cmd/manifest.gd")
const EditorManifest = preload("res://addons/_lib/gdsh_lib/editor/cmd/manifest.gd")
const DataManifest = preload("res://addons/_lib/gdsh_lib/data/cmd/manifest.gd")

static func register_scopes():
	var data = {}
	_merge_package(TreeManifest, data)
	add_command_to_dict("res://addons/editor_console/src/default_commands/format/format.gd", data)
	_merge_package(EditorManifest, data)
	_merge_package(DataManifest, data)
	for p in [
		"res://addons/editor_console/src/default_commands/config/config.gd",
		"res://addons/editor_console/src/default_commands/misc/misc.gd",
	]:
		add_command_to_dict(p, data)
	
	return data


static func register_hidden_scopes():
	# Editor directories load afterwards, so they can override a utility.
	var data = {}
	_merge_package(UtilsManifest, data)
	add_command_to_dict(EDITOR_COMMANDS_DIR.path_join("editor_console.gd"), data)
	for cmd_dir in [HIDDEN_DIR, EDITOR_COMMANDS_DIR, TEMP_DIR]:
		if not DirAccess.dir_exists_absolute(cmd_dir):
			continue
		for dir in DirAccess.get_directories_at(cmd_dir):
			var path = cmd_dir.path_join(dir).path_join(dir + ".gd")
			add_command_to_dict(path, data)
	
	return data


## Loads the cmd/ dir holding a gdsh_lib package's manifest into data.
static func _merge_package(manifest:Resource, data:Dictionary) -> void:
	data.merge(GDShLoad.load_directory(manifest.resource_path.get_base_dir()), true)


static func register_variables():
	return {
		"$CURRENT_SCRIPT_PATH": func():
			if EditorInterface.get_script_editor().get_current_script():
				return EditorInterface.get_script_editor().get_current_script().resource_path,
		"$CURRENT_SCRIPT": func(): return EditorInterface.get_script_editor().get_current_script()
	}

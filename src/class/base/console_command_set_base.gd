const UtilsLocal = preload("res://addons/editor_console/src/utils/console_utils_local.gd")
const UtilsRemote = preload("res://addons/editor_console/src/utils/console_utils_remote.gd")

const GDShLoad = GDSh.Load
const ScopeDataKeys = UtilsLocal.ScopeDataKeys


static func register_scopes():
	return {}

static func register_hidden_scopes():
	return {}

static func register_variables():
	return {}

static func add_command_to_dict(script_path:String, dict:Dictionary):
	var script = GDShLoad.load_command(script_path)
	if script == null: return
	for name in [script.get_command_name()] + Array(script.get_command_aliases()):
		dict[name] = {
			ScopeDataKeys.SCRIPT: script
		}

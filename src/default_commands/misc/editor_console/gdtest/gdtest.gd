extends "res://addons/editor_console/src/default_commands/misc/editor_console/test/test.gd"
## The console's `test` under a name shell builtins don't shadow (e.g. the MCP sandbox shell).

static func get_command_name():
	return "gdtest"

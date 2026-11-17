extends EditorConsoleSingleton.CommandBase

const _HELP = \
"Serve the console's commands to mcp-sh-godot on 127.0.0.1 (port 9510 unless bridge.json sets one).
Takes one flag; with none, prints the status. Add 'mcp --start' to startup commands to serve
whenever the editor opens. Run 'mcp --stop; mcp --start' after editing bridge.json.
Usage:
  mcp --start | --stop | --status"

var action := ""

static func get_command_name() -> String:
	return "mcp"

static func get_self_command_data() -> Dictionary:
	return _command_data({
		&"discoverable": false,
		&"help": _HELP,
	})

func _get_flags() -> Dictionary:
	var options = Options.new()
	options.add_option("--start", {&"help": "Read bridge.json and start serving."})
	options.add_option("--stop", {&"help": "Stop serving."})
	options.add_option("--status", {&"help": "Print the port, version and config files."})
	return options.get_options()

func _process_flag(flag:String):
	if not action.is_empty():
		_ctx_obj.append_error("mcp takes one flag: --start, --stop or --status")
		return ExitCode.ERR
	action = flag

func _get_target_positional_count() -> int:
	return 0

func _execute(ctx:Context) -> int:
	match action:
		"--start":
			var running = EditorConsoleSingleton.get_mcp_sh_bridge()
			if running != null:
				ctx.append_output("already listening on 127.0.0.1:%s" % running.get_port())
				return ExitCode.OK
			var err = EditorConsoleSingleton.start_mcp_sh_bridge()
			if err != OK:
				ctx.append_error("mcp: could not start (%s). Is another editor, or the mcp-sh-godot addon, using the port?" % error_string(err))
				return ExitCode.FAIL
			_print_status(ctx)
		"--stop":
			var was_running = EditorConsoleSingleton.is_bridge_serving()
			EditorConsoleSingleton.stop_mcp_sh_bridge()
			ctx.append_output("stopped" if was_running else "not running")
		_:
			_print_status(ctx)
	return ExitCode.OK

func _print_status(ctx:Context) -> void:
	var bridge = EditorConsoleSingleton.get_mcp_sh_bridge()
	if bridge == null:
		ctx.append_output("not running")
		return
	var token = ", token required" if bridge.token != "" else ""
	ctx.append_output("listening on 127.0.0.1:%s (bridge %s%s)" % [bridge.get_port(), bridge.bridge_version(), token])
	var sources = EditorConsoleSingleton.get_mcp_sh_bridge_sources()
	if not sources.is_empty():
		ctx.append_output("config: " + ", ".join(sources))

# One flag only: nothing more to offer once it's typed.
func _get_completions(completion:Completion):
	if not action.is_empty():
		return {}
	return super(completion)

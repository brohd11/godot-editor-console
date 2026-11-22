extends EditorConsoleSingleton.CommandBase

const _HELP = \
"Register scope or scope set.
Usage: config scope reg <options> <scope_path>"


var set_flag:=false
var dir_flag:=false
var package_flag:=false
var project_flag:=false

static func get_command_name() -> String:
	return "reg"

static func get_self_command_data() -> Dictionary:
	return Options.get_single_option_dict(get_command_name(), {
		&"help": _HELP,
	})

func _get_flags() -> Dictionary:
	var options = Options.new()
	options.add_option("--set", {
		&"help": "--set <flag> - registers path as scope set."
	})
	options.add_option("--dir", {
		&"help": "--dir <flag> - register a directory that will be scanned for commands"
	})
	options.add_option("--package", {
		&"help": "--package <flag> - register a command package by name or dir; loads <package>/cmd"
	})
	options.add_option("--project", {
		&"help": "Register to the project override config instead of global."
	})
	return options.get_options()

func _process_flag(flag:String):
	if flag == "--set":
		set_flag = true
	elif flag == "--dir":
		dir_flag = true
	elif flag == "--package":
		package_flag = true
	elif flag == "--project":
		project_flag = true

func _get_target_positional_count() -> int:
	if set_flag or dir_flag or package_flag:
		return 1
	else:
		return 2

func _get_completions(completion:Completion):
	if not package_flag or completion.token_before_cursor.begins_with("--"):
		return super(completion)
	if not _positional_arg_index_valid():
		return {}
	var dirs = EditorConsoleSingleton.get_command_packages().values()
	dirs.sort()
	var options = Options.new()
	for dir in dirs:
		options.add_option(dir, {&"help": "Package: %s" % dir.get_file()})
	return options.get_options()

func _execute(ctx:Context):
	if int(set_flag) + int(dir_flag) + int(package_flag) > 1:
		ctx.append_error("Can only use one flag at a time.")
		return ExitCode.FAIL
	
	if set_flag:
		var scope_path = positional_args[0]
		EditorConsoleSingleton.register_persistent_scope_set(scope_path, project_flag)
	elif dir_flag:
		var scope_path = positional_args[0]
		EditorConsoleSingleton.register_command_dir(scope_path, project_flag)
	elif package_flag:
		var pkg_dir = _resolve_package(ctx, positional_args[0])
		if pkg_dir.is_empty():
			return ExitCode.FAIL
		EditorConsoleSingleton.register_command_package(pkg_dir, project_flag)
	else:
		var scope_name = positional_args[0]
		var scope_path = positional_args[1]
		EditorConsoleSingleton.register_persistent_scope(scope_name, scope_path, project_flag)
	return ExitCode.OK


## A package dir (as completed) or package name, as a package dir with cmd/, or "" after an error.
func _resolve_package(ctx:Context, arg:String) -> String:
	var packages = EditorConsoleSingleton.get_command_packages()
	if packages.has(arg):
		return packages[arg]
	var ambiguous = EditorConsoleSingleton.get_packages().ambiguous
	if ambiguous.has(arg):
		ctx.append_error("Package name '%s' is ambiguous, pass its dir: %s" % [arg, ", ".join(ambiguous[arg])])
		return ""
	var dir = arg if arg.is_absolute_path() else ctx.cwd.path_join(arg).simplify_path()
	dir = dir.trim_suffix("/")
	if not DirAccess.dir_exists_absolute(dir):
		ctx.append_error("No package or directory named: " + arg)
		return ""
	if not DirAccess.dir_exists_absolute(dir.path_join("cmd")):
		ctx.append_error("Package has no cmd/ dir: " + dir)
		return ""
	return dir

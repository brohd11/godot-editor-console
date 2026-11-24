extends "res://addons/_lib/gdsh_lib/test/cmd/test/test.gd"
## gdsh_lib/test's `test`, with the console's cached package scan and package-name completions.

func _packages() -> Dictionary:
	return EditorConsoleSingleton.get_packages()


## start with package names, if token begins with "./" or token exists in cwd do real folders
func _get_completions(ctx:Completion):
	if not _positional_arg_index_valid():
		return {}
	var flag_completions = _get_flag_type_completions(ctx)
	if flag_completions != null:
		return flag_completions
	var token:String = ctx.token_before_cursor
	if token.begins_with("--"):
		return _get_completion_std_w_context(ctx)
	if token.is_absolute_path() or token.begins_with("./"):
		return _completion_rel_path(ctx.context, token)

	if token.contains("/"):
		var first = token.get_slice("/", 0)
		if DirAccess.dir_exists_absolute(ctx.context.cwd.path_join(first)):
			return _completion_rel_path(ctx.context, token)

		var pkg = TestTargets.package_test_dir_for(first, _packages())
		if pkg.has("error"):
			return {}
		var ends_slash = token.ends_with("/") # simplify path strips a trailing slash
		var dir = pkg.dir.path_join(token.trim_prefix(first)).simplify_path()
		if not ends_slash:
			dir = dir.get_base_dir()
		return _dir_options(dir)
	return _package_options()


func _package_options() -> Dictionary:
	var options = Options.new()
	var packages = _packages().packages
	var names = packages.keys()
	names.sort()
	for nm in names:
		if TestTargets.package_test_dir(packages[nm]) != "":
			options.add_option(nm, {
				&"trailing_char": "/"
			})
	return options.get_options()


static func _dir_options(dir:String) -> Dictionary:
	var options = Options.new()
	var dirs = Array(DirAccess.get_directories_at(dir))
	dirs.push_front("..")
	for d in dirs:
		options.add_option(d, {
			&"trailing_char": "/"
		})
	return options.get_options()

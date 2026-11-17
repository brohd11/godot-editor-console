extends RefCounted
## The console's mcp-sh bridge: serves its commands to mcp-sh-godot on loopback. Held by the
## singleton as `mcp` and driven by the `mcp` command. The bridge node is parented to the
## singleton, so it stops when the console unloads.

const McpShBridge = preload("res://addons/_lib/mcp_sh_bridge/src/bridge.gd")
const McpShBridgeConfig = preload("res://addons/_lib/mcp_sh_bridge/src/bridge_config.gd")

## The bridge.json files the running bridge read.
var sources:PackedStringArray = []
var _owner:Node
var _bridge:McpShBridge


func _init(owner:Node) -> void:
	_owner = owner


## Read bridge.json and serve the console's commands. Returns an Error; a stale stopped bridge
## is replaced.
func start_bridge() -> int:
	stop_bridge()
	var config = McpShBridgeConfig.load_config()
	var bridge = McpShBridge.new()
	bridge.name = "McpShBridge"
	bridge.autostart = false
	config.apply_to(bridge)
	bridge.host = config.add_commands_to(EditorConsoleSingleton.ConsoleHost.new())
	_owner.add_child(bridge)
	var err = bridge.start()
	if err != OK:
		bridge.queue_free()
		return err
	_bridge = bridge
	sources = config.sources
	return OK


func stop_bridge() -> void:
	if is_instance_valid(_bridge):
		_bridge.stop()
		_bridge.queue_free()
	_bridge = null
	sources = PackedStringArray()


## The listening bridge, or null.
func get_bridge() -> McpShBridge:
	return _bridge if is_instance_valid(_bridge) and _bridge.is_listening() else null


func is_serving() -> bool:
	return get_bridge() != null

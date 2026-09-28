extends RefCounted
## Caller-owned presets; CPU-only authoring, with project-relative derivatives.

var root_path := ""
var config: Dictionary = {}
var output_override := ""
var error := ""

func setup(program: String) -> bool:
	var args := OS.get_cmdline_user_args()
	var options: Dictionary = {}
	var index := 0
	while index < args.size():
		var key := args[index]
		if key not in ["--project-root", "--config", "--output"] or options.has(key) or index + 1 >= args.size():
			error = "Unknown, repeated or incomplete audio option: " + key
			return false
		options[key] = args[index + 1]
		index += 2
	root_path = str(options.get("--project-root", ProjectSettings.globalize_path("res://"))).simplify_path().trim_suffix("/")
	if not root_path.is_absolute_path() or not DirAccess.dir_exists_absolute(root_path):
		error = "Audio project root must be an existing absolute directory"
		return false
	var config_path := str(options.get("--config", root_path.path_join("tools/game-dev-tools-config.json")))
	if not config_path.is_absolute_path():
		config_path = root_path.path_join(config_path)
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(config_path))
	if not parsed is Dictionary or not parsed.get("audio-synthesis") is Dictionary or not parsed["audio-synthesis"].get(program) is Dictionary:
		error = "Declare audio-synthesis." + program + " in the selected config"
		return false
	config = parsed["audio-synthesis"][program]
	output_override = str(options.get("--output", ""))
	var rate = config.get("rate", 44100)
	if typeof(rate) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(rate)) or float(rate) != float(int(rate)) or int(rate) <= 0:
		error = "Audio rate must be a positive integer"
		return false
	return true

func path(value: String) -> String:
	if value.is_absolute_path() or value.contains(":") or ".." in value.split("/"):
		error = "Audio paths must stay inside the selected project"
		return ""
	var current := root_path
	for part in value.split("/", false):
		var parent := DirAccess.open(current)
		if parent != null and parent.is_link(part):
			error = "Audio output paths cannot traverse symlinks"
			return ""
		current = current.path_join(part)
	return current.simplify_path()

func output() -> String:
	return path(output_override if not output_override.is_empty() else str(config.get("output", "out/audio")))

func destination(file_name: String) -> String:
	var folder := output()
	if folder.is_empty():
		return ""
	var relative := folder.trim_prefix(root_path + "/").path_join(file_name)
	var result := path(relative)
	if result.is_empty():
		return ""
	if FileAccess.file_exists(result) and not config.get("allow_replace", false):
		error = "Audio output already exists: " + result
		return ""
	return result

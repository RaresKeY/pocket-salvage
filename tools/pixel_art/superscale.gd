extends SceneTree

const Scaling = preload("res://scripts/art/pixel_scaling.gd")
const USAGE := "Usage: tools/superscale --input assets/sprite.png --factor 10 --output artifacts/generated/sprite-10x.png\nCreates an RGBA8 PNG and adjacent .json provenance. Never replaces existing files."


func _initialize() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.has("--help"):
		print(USAGE)
		quit(0)
		return
	var options: Dictionary = {}
	var index := 0
	while index < arguments.size():
		var key := arguments[index]
		if key not in ["--input", "--output", "--factor"] or options.has(key) or index + 1 >= arguments.size():
			fail("Unknown, repeated, or incomplete option: " + key)
			return
		options[key] = arguments[index + 1]
		index += 2
	if options.size() != 3 or not str(options.get("--factor", "")).is_valid_int():
		fail("Provide --input, --output, and an integer --factor.")
		return
	var source_path := project_path(str(options["--input"]))
	var output_path := project_path(str(options["--output"]))
	if source_path.is_empty() or output_path.is_empty():
		fail("Input and output must be inside the project; use project-relative paths.")
		return
	if source_path.get_extension().to_lower() != "png" or output_path.get_extension().to_lower() != "png":
		fail("This exact-pixel tool accepts and writes PNG files.")
		return
	if not FileAccess.file_exists(source_path):
		fail("Input PNG does not exist.")
		return
	var manifest_path := output_path + ".json"
	if FileAccess.file_exists(output_path) or FileAccess.file_exists(manifest_path):
		fail("Output or provenance already exists; choose a new output path.")
		return
	var factor := int(options["--factor"])
	var error := Scaling.png_error(source_path, factor)
	if not error.is_empty():
		fail(error)
		return
	var source := Image.load_from_file(source_path)
	if source == null or source.is_empty():
		fail("Godot could not decode the PNG.")
		return
	var enlarged := Scaling.enlarge(source, factor)
	if enlarged == null:
		fail("The decoded image exceeds the supported size.")
		return
	if DirAccess.make_dir_recursive_absolute(output_path.get_base_dir()) != OK:
		fail("Cannot create the output directory.")
		return
	if enlarged.save_png(output_path) != OK:
		fail("Cannot write the output PNG.")
		return
	var manifest := {
		"algorithm": "integer-nearest-neighbor", "factor": factor,
		"source": ProjectSettings.localize_path(source_path).trim_prefix("res://"),
		"source_sha256": FileAccess.get_sha256(source_path),
		"source_size": [source.get_width(), source.get_height()],
		"output": ProjectSettings.localize_path(output_path).trim_prefix("res://"),
		"output_sha256": FileAccess.get_sha256(output_path),
		"output_size": [enlarged.get_width(), enlarged.get_height()],
		"format": "RGBA8", "godot": Engine.get_version_info()["string"]
	}
	var record := FileAccess.open(manifest_path, FileAccess.WRITE)
	if record == null:
		DirAccess.remove_absolute(output_path)
		fail("Cannot write provenance; removed the new output PNG.")
		return
	record.store_string(JSON.stringify(manifest, "\t", true) + "\n")
	var write_error := record.get_error()
	record.close()
	if write_error != OK:
		DirAccess.remove_absolute(output_path)
		DirAccess.remove_absolute(manifest_path)
		fail("Provenance write failed; removed this run's outputs.")
		return
	print("SUPERSCALE_OK " + JSON.stringify(manifest))
	quit(0)


func project_path(value: String) -> String:
	var root_path := ProjectSettings.globalize_path("res://").simplify_path().trim_suffix("/")
	var path := value if value.is_absolute_path() else root_path.path_join(value)
	path = ProjectSettings.globalize_path(path).simplify_path()
	return path if path.begins_with(root_path + "/") else ""


func fail(message: String) -> void:
	printerr(message + "\n" + USAGE)
	quit(2)

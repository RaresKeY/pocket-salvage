extends RefCounted
## Check the same immutable file pins used by the Python compatibility loader.

static func verify(manifest_path := "res://tools/game-dev-tools.json") -> bool:
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not manifest is Dictionary or not manifest.get("files") is Dictionary:
		push_error("Missing or invalid game-dev-tools consumer manifest")
		return false
	for relative in manifest.files:
		var path := "res://tools/shared/game-dev-tools/" + str(relative)
		if FileAccess.get_sha256(path) != manifest.files[relative]:
			push_error("Shared tool pin mismatch: " + str(relative))
			return false
	return true

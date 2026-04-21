class_name SaveLoadSystem
extends Node

## Persists and restores the player's puzzle progress to a JSON file.
##
## Usage:
##   1. save(current_puzzle_index) — writes progress to disk.
##   2. load_save() — returns the saved index; falls back to DEFAULT_PUZZLE_INDEX
##      on first run, unreadable file, or corrupt JSON.
##   3. has_save() — true if a save file exists at save_path.
##   4. delete_save() — removes the file (used for "reset progress" and tests).

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const _KEY_PUZZLE_INDEX: String = "current_puzzle_index"

## Puzzle index returned when no valid save data is found.
const DEFAULT_PUZZLE_INDEX: int = 0

# ---------------------------------------------------------------------------
# Exported tuning knobs
# ---------------------------------------------------------------------------

## Save file location. Override in tests to avoid touching real user data.
@export var save_path: String = "user://save.json"

# ---------------------------------------------------------------------------
# Public methods
# ---------------------------------------------------------------------------

## Writes current_puzzle_index to the save file.
## Returns true on success, false on I/O failure.
func save(current_puzzle_index: int) -> bool:
	var data: Dictionary = { _KEY_PUZZLE_INDEX: current_puzzle_index }
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning(
			"SaveLoadSystem.save: cannot write '%s' (error %d)." % [
				save_path, FileAccess.get_open_error()
			]
		)
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true


## Reads the saved puzzle index.
## Returns DEFAULT_PUZZLE_INDEX if the file does not exist, is unreadable,
## or contains malformed JSON.
func load_save() -> int:
	if not FileAccess.file_exists(save_path):
		return DEFAULT_PUZZLE_INDEX
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_warning(
			"SaveLoadSystem.load_save: cannot read '%s' (error %d)." % [
				save_path, FileAccess.get_open_error()
			]
		)
		return DEFAULT_PUZZLE_INDEX
	var text: String = file.get_as_text()
	file.close()
	return _parse_puzzle_index(text)


## Returns true if a save file exists at save_path.
func has_save() -> bool:
	return FileAccess.file_exists(save_path)


## Deletes the save file. No-op if the file does not exist.
## Call this for "reset progress" or test teardown.
func delete_save() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var dir := DirAccess.open(save_path.get_base_dir())
	if dir == null:
		push_warning(
			"SaveLoadSystem.delete_save: cannot open directory for '%s'." % save_path
		)
		return
	dir.remove(save_path.get_file())

# ---------------------------------------------------------------------------
# Private — parsing
# ---------------------------------------------------------------------------

## Extracts current_puzzle_index from raw JSON text.
## Returns DEFAULT_PUZZLE_INDEX on any parse or type error.
func _parse_puzzle_index(text: String) -> int:
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		push_warning("SaveLoadSystem._parse_puzzle_index: malformed JSON — resetting to default.")
		return DEFAULT_PUZZLE_INDEX
	var data: Dictionary = parsed
	if not data.has(_KEY_PUZZLE_INDEX):
		return DEFAULT_PUZZLE_INDEX
	var raw: Variant = data[_KEY_PUZZLE_INDEX]
	if typeof(raw) == TYPE_INT:
		return raw
	if typeof(raw) == TYPE_FLOAT:
		return int(raw)
	push_warning("SaveLoadSystem._parse_puzzle_index: unexpected value type — resetting to default.")
	return DEFAULT_PUZZLE_INDEX

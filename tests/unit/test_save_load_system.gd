extends GutTest

## T18 — SaveLoadSystem unit tests.
## Tests write and read from user://test_save_load_system.json to avoid
## touching real save data. The file is deleted in after_each().

const TEST_SAVE_PATH: String = "user://test_save_load_system.json"

var _sls: SaveLoadSystem

func before_each() -> void:
	_sls = SaveLoadSystem.new()
	_sls.save_path = TEST_SAVE_PATH
	add_child(_sls)


func after_each() -> void:
	# Clean up regardless of test outcome
	_sls.delete_save()


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

func test_save_load_system_save_creates_file() -> void:
	# Arrange — no prior file
	assert_false(_sls.has_save(), "pre-condition: no save file before test")

	# Act
	_sls.save(5)

	# Assert
	assert_true(_sls.has_save(), "save() should create the save file")


func test_save_load_system_load_returns_saved_index() -> void:
	# Arrange
	_sls.save(7)

	# Act
	var result: int = _sls.load_save()

	# Assert
	assert_eq(result, 7, "load_save() should return the index passed to save()")


func test_save_load_system_load_returns_default_when_no_file() -> void:
	# Arrange — no file exists
	assert_false(_sls.has_save(), "pre-condition: no save file")

	# Act
	var result: int = _sls.load_save()

	# Assert
	assert_eq(result, SaveLoadSystem.DEFAULT_PUZZLE_INDEX,
		"load_save() should return DEFAULT_PUZZLE_INDEX when no file exists")


func test_save_load_system_load_returns_default_on_corrupt_json() -> void:
	# Arrange — write invalid JSON manually
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string("NOT_VALID_JSON{{{{")
	file.close()

	# Act
	var result: int = _sls.load_save()

	# Assert
	assert_eq(result, SaveLoadSystem.DEFAULT_PUZZLE_INDEX,
		"load_save() should return DEFAULT_PUZZLE_INDEX on corrupt JSON")


func test_save_load_system_load_returns_default_on_missing_key() -> void:
	# Arrange — valid JSON but wrong key
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string('{"wrong_key": 5}')
	file.close()

	# Act
	var result: int = _sls.load_save()

	# Assert
	assert_eq(result, SaveLoadSystem.DEFAULT_PUZZLE_INDEX,
		"load_save() should return DEFAULT_PUZZLE_INDEX when key is absent")


func test_save_load_system_save_overwrites_previous_save() -> void:
	# Arrange
	_sls.save(3)

	# Act
	_sls.save(8)

	# Assert
	assert_eq(_sls.load_save(), 8,
		"second save() should overwrite the first; load_save() should return 8")


func test_save_load_system_delete_removes_file() -> void:
	# Arrange
	_sls.save(2)
	assert_true(_sls.has_save(), "pre-condition: save file should exist")

	# Act
	_sls.delete_save()

	# Assert
	assert_false(_sls.has_save(),
		"has_save() should return false after delete_save()")

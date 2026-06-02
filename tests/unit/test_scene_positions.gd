extends GutTest

# P5.5：GameState.scene_positions 跨场景持久化

func before_each() -> void:
	GameState.reset()

func test_initial_has_no_scene_positions() -> void:
	assert_false(GameState.has_scene_position("res://src/scenes/world/yucheng_main.tscn"))
	assert_eq(GameState.get_scene_position("res://src/scenes/world/yucheng_main.tscn"), Vector2.ZERO)

func test_set_then_get() -> void:
	var path := "res://src/scenes/world/yucheng_main.tscn"
	GameState.set_scene_position(path, Vector2(120, 380))
	assert_true(GameState.has_scene_position(path))
	assert_eq(GameState.get_scene_position(path), Vector2(120, 380))

func test_empty_path_is_ignored() -> void:
	GameState.set_scene_position("", Vector2(1, 2))
	assert_false(GameState.has_scene_position(""))

func test_overwrite_same_path() -> void:
	var path := "res://a.tscn"
	GameState.set_scene_position(path, Vector2(10, 20))
	GameState.set_scene_position(path, Vector2(99, 99))
	assert_eq(GameState.get_scene_position(path), Vector2(99, 99))

func test_multiple_scenes_independent() -> void:
	GameState.set_scene_position("res://a.tscn", Vector2(1, 1))
	GameState.set_scene_position("res://b.tscn", Vector2(2, 2))
	assert_eq(GameState.get_scene_position("res://a.tscn"), Vector2(1, 1))
	assert_eq(GameState.get_scene_position("res://b.tscn"), Vector2(2, 2))

func test_reset_clears_scene_positions() -> void:
	GameState.set_scene_position("res://a.tscn", Vector2(1, 1))
	GameState.reset()
	assert_false(GameState.has_scene_position("res://a.tscn"))

func test_serialization_round_trip() -> void:
	GameState.set_scene_position("res://a.tscn", Vector2(120, 380))
	GameState.set_scene_position("res://b.tscn", Vector2(-50, 200))
	var dict: Dictionary = GameState.to_dict()
	assert_true(dict.has("scene_positions"))
	GameState.reset()
	assert_false(GameState.has_scene_position("res://a.tscn"))
	GameState.from_dict(dict)
	assert_eq(GameState.get_scene_position("res://a.tscn"), Vector2(120, 380))
	assert_eq(GameState.get_scene_position("res://b.tscn"), Vector2(-50, 200))

func test_from_dict_with_missing_key_clears() -> void:
	GameState.set_scene_position("res://a.tscn", Vector2(1, 1))
	GameState.from_dict({})   ## 没有 scene_positions 键
	assert_false(GameState.has_scene_position("res://a.tscn"))

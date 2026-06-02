extends GutTest

# P4 final · 4.9：GameState.observed_clues 行为

func before_each() -> void:
	GameState.reset()

func test_initial_no_clues_observed() -> void:
	assert_eq(GameState.observed_clue_count(), 0)
	assert_false(GameState.has_observed("observe_wall_grid"))

func test_mark_observed_first_time_returns_true() -> void:
	var ok: bool = GameState.mark_observed("observe_wall_grid")
	assert_true(ok)
	assert_true(GameState.has_observed("observe_wall_grid"))
	assert_eq(GameState.observed_clue_count(), 1)

func test_mark_observed_duplicate_returns_false() -> void:
	GameState.mark_observed("observe_wall_grid")
	var ok: bool = GameState.mark_observed("observe_wall_grid")
	assert_false(ok)
	assert_eq(GameState.observed_clue_count(), 1)

func test_three_distinct_clues_count_three() -> void:
	GameState.mark_observed("observe_wall_grid")
	GameState.mark_observed("observe_clock")
	GameState.mark_observed("observe_corpse")
	assert_eq(GameState.observed_clue_count(), 3)

func test_reset_clears_clues() -> void:
	GameState.mark_observed("observe_wall_grid")
	GameState.reset()
	assert_eq(GameState.observed_clue_count(), 0)

func test_to_dict_includes_observed_clues() -> void:
	GameState.mark_observed("observe_wall_grid")
	GameState.mark_observed("observe_clock")
	var d: Dictionary = GameState.to_dict()
	assert_true(d.has("observed_clues"))
	assert_eq((d["observed_clues"] as Array).size(), 2)

func test_from_dict_restores_observed_clues() -> void:
	GameState.from_dict({"observed_clues": ["observe_wall_grid", "observe_clock"]})
	assert_eq(GameState.observed_clue_count(), 2)
	assert_true(GameState.has_observed("observe_clock"))

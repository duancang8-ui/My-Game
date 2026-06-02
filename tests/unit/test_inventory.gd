extends GutTest

# P7：GameState.inventory + try_purchase

func before_each() -> void:
	GameState.reset()

func test_initial_empty_inventory() -> void:
	assert_eq(GameState.get_item_count("anything"), 0)
	assert_false(GameState.has_item("anything"))

func test_add_item_increments_count() -> void:
	GameState.add_item("item_x", 1)
	assert_eq(GameState.get_item_count("item_x"), 1)
	GameState.add_item("item_x", 2)
	assert_eq(GameState.get_item_count("item_x"), 3)

func test_remove_item_decreases_or_erases() -> void:
	GameState.add_item("item_x", 2)
	var ok: bool = GameState.remove_item("item_x", 1)
	assert_true(ok)
	assert_eq(GameState.get_item_count("item_x"), 1)
	GameState.remove_item("item_x", 1)
	assert_eq(GameState.get_item_count("item_x"), 0)

func test_remove_more_than_owned_fails() -> void:
	GameState.add_item("item_x", 1)
	var ok: bool = GameState.remove_item("item_x", 5)
	assert_false(ok)
	assert_eq(GameState.get_item_count("item_x"), 1, "失败时不应扣减")

func test_try_purchase_with_enough_dao() -> void:
	GameState.dao_count = 10
	var ok: bool = GameState.try_purchase("item_x", 6)
	assert_true(ok)
	assert_eq(GameState.dao_count, 4)
	assert_eq(GameState.get_item_count("item_x"), 1)

func test_try_purchase_without_enough_dao() -> void:
	GameState.dao_count = 2
	var ok: bool = GameState.try_purchase("item_x", 5)
	assert_false(ok)
	assert_eq(GameState.dao_count, 2, "失败时道币不变")
	assert_eq(GameState.get_item_count("item_x"), 0)

func test_inventory_round_trip_in_dict() -> void:
	GameState.add_item("item_x", 3)
	GameState.add_item("item_y", 1)
	var dict: Dictionary = GameState.to_dict()
	GameState.reset()
	GameState.from_dict(dict)
	assert_eq(GameState.get_item_count("item_x"), 3)
	assert_eq(GameState.get_item_count("item_y"), 1)

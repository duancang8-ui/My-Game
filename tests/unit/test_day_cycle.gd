extends GutTest

# P7：日夜推进（mark_pending_day_advance / consume_pending_day_advance）

func before_each() -> void:
	GameState.reset()

func test_initial_no_pending() -> void:
	assert_false(GameState.pending_day_advance)
	assert_eq(GameState.current_day, 1)

func test_mark_then_consume_advances_day() -> void:
	GameState.mark_pending_day_advance()
	assert_true(GameState.pending_day_advance)
	var advanced: bool = GameState.consume_pending_day_advance()
	assert_true(advanced)
	assert_eq(GameState.current_day, 2)
	assert_false(GameState.pending_day_advance, "flag 应被消费")

func test_consume_without_flag_does_nothing() -> void:
	var advanced: bool = GameState.consume_pending_day_advance()
	assert_false(advanced)
	assert_eq(GameState.current_day, 1)

func test_double_mark_only_one_advance() -> void:
	# 防多次触发：mark 两次仍然只 +1 day
	GameState.mark_pending_day_advance()
	GameState.mark_pending_day_advance()
	GameState.consume_pending_day_advance()
	GameState.consume_pending_day_advance()
	assert_eq(GameState.current_day, 2, "重复 mark 不应导致 day 多跳")

func test_day_overflow_triggers_cycle_advance() -> void:
	# Day 10 → mark + consume → 应 +1 cycle 且 day 重置
	GameState.current_day = 10
	GameState.current_cycle = 1
	GameState.mark_pending_day_advance()
	GameState.consume_pending_day_advance()
	assert_eq(GameState.current_cycle, 2, "满 10 天应 +1 cycle")
	assert_eq(GameState.current_day, 1, "cycle 推进后 day 重置")

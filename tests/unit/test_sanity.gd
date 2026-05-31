extends GutTest

# GUT 配置 sanity 测试 —— 仅验证测试框架能正常运行
# 这个测试在 P1 阶段后可以删除

func test_gut_can_run() -> void:
    assert_true(true, "GUT 能跑就是胜利")

func test_basic_math() -> void:
    assert_eq(2 + 2, 4, "数学还在 work")

func test_godot_runtime_available() -> void:
    assert_not_null(Engine.get_version_info(), "Engine API 可用")
    assert_true(Engine.get_version_info().major >= 4, "Godot 4+ 运行时")

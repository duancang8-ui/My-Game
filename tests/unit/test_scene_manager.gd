extends GutTest

# 不真实切换场景的测试（避免单元测试影响 SceneTree）
# 仅验证 SceneManager 的 API 与初始状态

func test_initial_state_is_idle() -> void:
    assert_eq(SceneManager.state, SceneManager.State.IDLE)
    assert_false(SceneManager.is_busy())

func test_empty_path_is_rejected() -> void:
    # 调用空路径不应改变状态
    SceneManager.change_to("")
    assert_eq(SceneManager.state, SceneManager.State.IDLE, "空路径请求被拒绝")

func test_overlay_exists() -> void:
    # SceneManager 应该已自建 CanvasLayer + ColorRect overlay
    assert_not_null(SceneManager._overlay, "overlay 应已创建")
    assert_not_null(SceneManager._layer, "CanvasLayer 应已创建")

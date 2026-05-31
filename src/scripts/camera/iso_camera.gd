class_name IsoCamera
extends Camera2D

# 等距相机：跟随父节点（玩家），保持等距视角的视觉中心
# 后续可扩展：摇晃、平滑跟随调节、缩放、过场动画

@export var follow_smoothing: float = 5.0  # 跟随平滑度（越大越紧跟）
@export var camera_zoom: Vector2 = Vector2(1.5, 1.5)  # 等距视角通常需要轻微放大

func _ready() -> void:
    position_smoothing_enabled = true
    position_smoothing_speed = follow_smoothing
    zoom = camera_zoom
    make_current()

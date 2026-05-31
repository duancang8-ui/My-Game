class_name PlayerInteractor
extends Area2D

# 玩家身上的"交互探测器"
# 跟踪当前重叠的 Interactable，按 E 时调用 .interact()

signal interactable_entered(interactable: Interactable)
signal interactable_exited(interactable: Interactable)

var _nearby: Array[Interactable] = []

func _ready() -> void:
    area_entered.connect(_on_area_entered)
    area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
    if area is Interactable:
        var inter := area as Interactable
        _nearby.append(inter)
        interactable_entered.emit(inter)

func _on_area_exited(area: Area2D) -> void:
    if area is Interactable:
        var inter := area as Interactable
        _nearby.erase(inter)
        interactable_exited.emit(inter)

func get_current() -> Interactable:
    if _nearby.is_empty():
        return null
    return _nearby[0]

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        var target: Interactable = get_current()
        if target != null:
            target.interact()
            get_viewport().set_input_as_handled()

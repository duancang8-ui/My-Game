class_name PlayerInteractor
extends Area2D

# 玩家身上的「交互探测器」
# 跟踪当前重叠的 Interactable，按 E 时调用 .interact()
# P4 final · b4：走近 Interactable 时给目标的 Sprite2D 加亮 + 玩家头顶显示 prompt

signal interactable_entered(interactable: Interactable)
signal interactable_exited(interactable: Interactable)

const HIGHLIGHT_TINT: Color = Color(1.35, 1.35, 1.1, 1.0)   # 暖色加亮（HDR）

var _nearby: Array[Interactable] = []
var _original_modulates: Dictionary = {}   # Sprite2D → Color
var _prompt_label: Label

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	_build_prompt_label()

func _build_prompt_label() -> void:
	_prompt_label = Label.new()
	_prompt_label.position = Vector2(-60, -56)   # 玩家头顶上方
	_prompt_label.size = Vector2(120, 18)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_size_override("font_size", 11)
	_prompt_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.55, 1.0))
	_prompt_label.add_theme_constant_override("outline_size", 2)
	_prompt_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_prompt_label.visible = false
	add_child(_prompt_label)

func _on_area_entered(area: Area2D) -> void:
	if area is Interactable:
		var inter := area as Interactable
		_nearby.append(inter)
		_highlight(inter, true)
		_update_prompt()
		interactable_entered.emit(inter)

func _on_area_exited(area: Area2D) -> void:
	if area is Interactable:
		var inter := area as Interactable
		_nearby.erase(inter)
		_highlight(inter, false)
		_update_prompt()
		interactable_exited.emit(inter)

func get_current() -> Interactable:
	if _nearby.is_empty():
		return null
	return _nearby[0]

func _update_prompt() -> void:
	if _prompt_label == null:
		return
	var cur := get_current()
	if cur == null or cur.prompt_text == "":
		_prompt_label.visible = false
	else:
		_prompt_label.text = cur.prompt_text
		_prompt_label.visible = true

func _highlight(inter: Interactable, on: bool) -> void:
	var parent: Node = inter.get_parent()
	if parent == null:
		return
	var sprite: Sprite2D = null
	for child in parent.get_children():
		if child is Sprite2D:
			sprite = child as Sprite2D
			break
	if sprite == null:
		return
	if on:
		if not _original_modulates.has(sprite):
			_original_modulates[sprite] = sprite.modulate
		sprite.modulate = sprite.modulate * HIGHLIGHT_TINT
	else:
		if _original_modulates.has(sprite):
			sprite.modulate = _original_modulates[sprite]
			_original_modulates.erase(sprite)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		var target: Interactable = get_current()
		if target != null:
			target.interact()
			get_viewport().set_input_as_handled()

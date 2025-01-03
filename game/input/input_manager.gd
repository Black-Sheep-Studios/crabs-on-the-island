class_name InputManager

extends Node

var _controllers: Array[InputController] = []


func _process(delta: float) -> void:
	if _controllers.size() == 0: return

	var current_controller: InputController = _controllers.back()
	if current_controller != null:
		current_controller.process(delta)


func set_controller(controller: InputController) -> void:
	_controllers.push_back(controller)


func restore() -> void:
	_controllers.pop_back()
extends AnimatedSprite2D

@onready var _crab: Crab = get_parent()


var _current_animation: String
var _current_flip_h: bool

func set_color(color: Color) -> void:
	set_self_modulate(color)


func _process(delta: float) -> void:
	var new_animation: String
	var new_flip_h: bool

	if _crab._direction in Util.LeftDirections: new_flip_h = true

	if _crab._sm.has_state(Crab.States.OUT_OF_BATTERY):
		new_animation = "sleep"
	elif _crab._sm.has_state(Crab.States.REPRODUCING):
		new_animation = "sleep"
	elif _crab._sm.has_state(Crab.States.DASHING):
		new_animation = "dash"
	elif _crab._sm.has_state(Crab.States.RUNNING):
		new_animation = "move"
	else:
		new_animation = "idle"

	if new_animation != _current_animation || new_flip_h != _current_flip_h:
		_current_animation = new_animation
		_current_flip_h = new_flip_h
		play(_current_animation)
		flip_h = _current_flip_h

extends Node2D


@export var lifetime: float = 5.0
@export var travelVector: Vector2 = Vector2(0.0, 64.0)

var timeLeft: float

func set_stats(statName: String, statValue: float) -> void:
	if statValue < 0.0:
		$toast_txt.set_text(str(statValue as int) + " " + statName)
	else:
		$toast_txt.set_text("+" + str(statValue as int) + " " + statName)


# Called when the node enters the scene tree for the first time.
func _ready():
	timeLeft = lifetime


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	timeLeft -= delta
	if timeLeft > 0.0:
		set_position(travelVector * (1.0 - (timeLeft / lifetime)))
		if timeLeft <= 1.0: 
			var txtColor = get_self_modulate()
			txtColor.a = timeLeft
			set_self_modulate(txtColor)
	else:
		queue_free()

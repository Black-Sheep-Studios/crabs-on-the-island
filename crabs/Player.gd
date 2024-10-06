class_name Player

extends Node

func _ready():
	$Crab.isPlayerFamily = true
	$Crab/AnimatedSprite2D.set_self_modulate(Color(1.0, 0.0, 0.0))

func _process(delta: float) -> void:
	_process_movement()
	_process_dash()
	_process_harvest(delta)
	_process_pickup()
	_process_reproduction(delta)
	_update_camera_position()


func _process_dash() -> void:
	if Input.is_action_just_pressed("dash"):
		$Crab.dash()


func _process_movement() -> void:
	var moveInput: Vector2
	moveInput.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	moveInput.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	$Crab.move(moveInput)


func _process_harvest(delta) -> void:
	if Input.is_action_pressed("harvest"):
		if !$Crab.harvest(delta):
			$Crab.stop_harvest()
	if Input.is_action_just_released("harvest"):
		$Crab.stop_harvest()


func _process_pickup() -> void:
	if Input.is_action_pressed("pickup"):
		if $Crab.is_holding():
			$Crab.pickup()
		else:
			$Crab.drop_held()


func _process_reproduction(delta) -> void:
	if Input.is_action_pressed("reproduce"):
		if !$Crab.auto_reproduce(delta):
			$Crab.stop_reproduce()
	if Input.is_action_just_released("reproduce"):
		$Crab.stop_reproduce()

func _update_camera_position() -> void:
	$Camera2D.position = $Crab.position
	$Camera2D.transform = $Crab.transform

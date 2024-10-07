class_name Player

extends Node


const player_color = Color(1.0, 0.0, 0.0)

@onready var island = $"../.."
var crab_ai_scene: PackedScene = preload("res://crabs/AI/CrabAI.tscn")

signal disassociation_changed
signal crab_swapped

var is_disassociating: bool = false
var familyCrabs: Array = []
var crabIndex: int = 0
var familySize: int = 1
var _crab: Crab


func _ready():
	_crab = get_parent()
	_crab.isPlayerFamily = true
	_crab.set_color(player_color)


func _process(delta: float) -> void:
	_process_swap()
	if !is_disassociating:
		_process_movement()
		_process_dash()
		_process_harvest(delta)
		_process_pickup()
		_process_reproduction(delta)


func _process_swap() -> void:
	if Input.is_action_just_pressed("swap"):
		if is_disassociating:
			is_disassociating = false
			disassociation_changed.emit()
			print("No longer disassociating!")
		else:
			is_disassociating = true
			disassociation_changed.emit()
			print("I'm disassociating!")
			crab_swapped.emit()
	if is_disassociating:
		familyCrabs.clear()
		for crab: Crab in get_all_crabs():
			if crab.isPlayerFamily and !familyCrabs.has(crab):
				familyCrabs.append(crab)
		var LR = 0
		if Input.is_action_just_pressed("move_left"): LR = -1
		elif Input.is_action_just_pressed("move_right"): LR = 1
		if LR != 0:
			var new_crab_ai: CrabAI = crab_ai_scene.instantiate()
			_crab.add_child(new_crab_ai)
			_crab.remove_child(self)
			crabIndex = ((crabIndex + LR) as int) % familyCrabs.size()
			_crab = familyCrabs[crabIndex]
			_crab.get_node("CrabAI").queue_free()
			_crab.add_child(self)
			crab_swapped.emit()
		


func get_all_crabs() -> Array:
	return (island.get_children()
		.map(func(child) -> Crab: return child as Crab)
		.filter(func(child) -> bool: return child != null)
	)


func _process_dash() -> void:
	if Input.is_action_just_pressed("dash"):
		_crab.dash()


func _process_movement() -> void:
	var moveInput: Vector2
	moveInput.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	moveInput.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	_crab.move(moveInput)


func _process_harvest(delta) -> void:
	if Input.is_action_pressed("harvest"):
		if !_crab.harvest(delta):
			_crab.stop_harvest()
	if Input.is_action_just_released("harvest"):
		_crab.stop_harvest()


func _process_pickup() -> void:
	if Input.is_action_pressed("pickup"):
		if _crab.is_holding():
			_crab.pickup()
		else:
			_crab.drop_held()


func _process_reproduction(delta) -> void:
	if Input.is_action_pressed("reproduce"):
		if !_crab.auto_reproduce(delta):
			_crab.stop_reproduce()
	if Input.is_action_just_released("reproduce"):
		_crab.stop_reproduce()

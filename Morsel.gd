class_name Morsel

extends RigidBody2D

@onready var sprite = $Sprite2D
@onready var chunk_collider = $chunk_collider
@onready var ingot_collider = $ingot_collider
var chunkTXR := preload("res://assets/chunk.png")
var ingotTXR := preload("res://assets/ingot.png")

enum MATERIAL_TYPE {COBALT, IRON, SILICON}

@export var mat_type = MATERIAL_TYPE.SILICON
@export var amount = 1000.0
@export var is_chunk = false


func _set_resource (_mat, _amount, _isChunk):
	mat_type = _mat
	amount = _amount
	is_chunk = _isChunk

	if is_chunk:
		sprite.set_texture(chunkTXR)
		chunk_collider.set_disabled(false)
		ingot_collider.set_disabled(true)
	else:
		sprite.set_texture(ingotTXR)
		ingot_collider.set_disabled(false)
		chunk_collider.set_disabled(true)

	match mat_type:
		MATERIAL_TYPE.COBALT:
			sprite.set_modulate(Color(0.33, 0.33, 1.0))
			set_mass(amount * 8.8)
		MATERIAL_TYPE.IRON:
			sprite.set_modulate(Color(0.4, 0.4, 0.4))
			set_mass(amount * 7.86)
		MATERIAL_TYPE.SILICON:
			sprite.set_modulate(Color(0.6, 1.0, 1.0))
			set_mass(amount * 2.33)

func _extract (extractAmount) -> float:
	if extractAmount >= amount:
		queue_free()
		return amount
	else:
		amount -= extractAmount
		return extractAmount


func _ready():
	_set_resource(mat_type, amount, is_chunk)
class_name Morsel

extends RigidBody2D

@onready var sprite: Sprite2D = $morselSprite
@onready var chunk_collider = $chunk_collider
@onready var ingot_collider = $ingot_collider
var chunkTXR: Texture2D = preload("res://assets/graphics/chunk.png")
var ingotTXR: Texture2D = preload("res://assets/graphics/ingot.png")

@export var amount: float = 1000.0
@export var contains_cobalt: bool = false
@export var is_chunk: bool = false


func set_children_scale(factor: float) -> void:
	sprite.scale = Vector2.ONE * (4 * factor)
	chunk_collider.scale = Vector2.ONE * (4 * factor)
	ingot_collider.scale = Vector2.ONE * factor


func _set_resource (_amount: float, containsCobalt: bool, _isChunk: bool):
	amount = _amount
	contains_cobalt = containsCobalt
	is_chunk = _isChunk
	
	_update_scale()
	
	if is_chunk:
		sprite.set_texture(chunkTXR)
		chunk_collider.set_disabled(false)
		ingot_collider.set_disabled(true)
	else:
		sprite.set_texture(ingotTXR)
		ingot_collider.set_disabled(false)
		chunk_collider.set_disabled(true)
	
	if contains_cobalt:
		sprite.set_modulate(Color(0.33, 0.33, 1.0))
		set_mass(amount * 8.8)
	else:
		sprite.set_modulate(Color(0.4, 0.4, 0.4))
		set_mass(amount * 7.86)


func _extract (extractAmount) -> float:
	if extractAmount >= amount:
		queue_free()
		return amount
	else:
		amount -= extractAmount
		_update_scale()
		return extractAmount


func _update_scale() -> void:
	var new_scale: float = pow(amount/100, 3)
	set_children_scale(max(new_scale, 0.2))


func _ready():
	_set_resource(amount, contains_cobalt, is_chunk)

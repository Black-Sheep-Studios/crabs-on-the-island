class_name ResourceCollider

extends Area2D


func set_size(size: Vector2) -> void:
	$CollisionShape2D.shape.set_size(size)

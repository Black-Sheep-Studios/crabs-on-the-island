class_name CrabSpawner

extends Node

@export var crab_scene: PackedScene
var _crab_container: Node
var _player_has_spawned: bool

signal on_spawn(crab: Crab)
signal on_death
signal on_player_spawn(player_crab: Crab)


func init() -> void:
	_crab_container = get_parent()


func spawn_from_point(spawn_point: SpawnPoint) -> Crab:
	return spawn_with_attributes(
		spawn_point.position,
		spawn_point.carried_resources,
		spawn_point.starting_stats,
		spawn_point.team_color,
		spawn_point.start_with_cobalt,
		spawn_point.family
	)


func spawn_with_attributes(
	position: Vector2,
	carried_resources: Dictionary,
	stats: Dictionary,
	color: Color,
	contains_cobalt: bool,
	family: Crab.Family,
) -> Crab:
	var crab: Crab = crab_scene.instantiate()
	_crab_container.add_child(crab)

	crab.init(carried_resources, stats, stats, color, contains_cobalt, family)
	crab.position = position

	if family == Crab.Family.PLAYER && !_player_has_spawned:
		_player_has_spawned = true
		on_player_spawn.emit(crab)
	on_spawn.emit(crab)
	crab.on_death.connect(func() -> void: on_death.emit())

	return crab

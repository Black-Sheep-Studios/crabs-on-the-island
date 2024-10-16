class_name Crab

extends RigidBody2D

@export var move_battery_usage: float = 0.1
@export var dash_battery_usage: float = 0.5
@export var harvest_battery_usage: float = 0.1
@export var dash_cooldown_seconds: float = 1.0
@export var dash_duration: float = 0.4
@export var dash_speed_multiplier: float = 1.0
@export var shutdown_cooldown_seconds: float = 2.0
@export var foot_step_time_delay: float = 0.1

const movementThreshold: float = 20.0
const harvestDrainMult = -0.25
const buildDrainMult = -2.0
const stat_init_size = 1.0
const stat_init_hit_points = 20.0
const stat_init_strength = 10.0
const stat_init_move_power = 2500.0
const stat_init_solar_charge_rate = 0.3
const stat_init_battery_capacity = 10.0
const stat_init_harvest_speed = 2.0
const stat_init_build_speed = 0.2

var crab_scene: PackedScene = preload("res://crabs/Crab.tscn")
var crab_ai_scene: PackedScene = preload("res://crabs/AI/CrabAI.tscn")
var morselTemplate: PackedScene = preload("res://resources/Morsel.tscn")
var toastTemplate: PackedScene = preload("res://crabs/Toast.tscn")
@onready var tabForTrigger: AnimatedSprite2D = $"/root/Game/hud/center/TAB"

signal on_death
signal on_damage

var tutorial_swap = false
var isPlayerFamily: bool
var _direction: Util.Directions = Util.Directions.DOWN
var _velocity: Vector2
@onready var _foot_step_sounds: Array[AudioStreamPlayer2D] = [$FootStepSound1, $FootStepSound2]
var _foot_step_timer: Timer
var _contains_cobalt: bool = false
var _sm: MultiStateMachine = MultiStateMachine.new()
var _HP: float
var _mass: float
var metalTarget: float = 1.0
var siliconTarget: float = 1.0
var waterTarget: float = 1.0
var buildProgress: float = 0.0
@onready var _island: Map = $"/root/Game/IslandV1"
var default_color: Color = Color(1, 1, 1, 1)
var _color: Color = default_color
var _family: Family
var batteryEnergyTargetPercentage = 50

enum States {
	RUNNING,
	DASHING,
	DASH_COOLDOWN,
	ATTACKING,
	REPRODUCING,
	OUT_OF_BATTERY,
	SHUTDOWN_COOLDOWN,
	HARVESTING,
	DEAD
}

enum Family {
	AI,
	PLAYER
}

var _current_animation: String
var _current_flip_h: bool

var _body_metal: float = 0.0
var _carried_resources: Dictionary = {
	"metal": 0,
	"silicon": 0,
	"water": 0,
	"battery_energy": 0.0,
}
var _default_stats: Dictionary = {
	"size": stat_init_size,
	"hit_points": stat_init_hit_points,
	"strength": stat_init_strength,
	"move_power": stat_init_move_power,
	"solar_charge_rate": stat_init_solar_charge_rate,
	"battery_capacity": stat_init_battery_capacity,
	"harvest_speed": stat_init_harvest_speed,
	"build_speed": stat_init_build_speed
}
var _stats_base: Dictionary = {
	"size": stat_init_size,
	"hit_points": stat_init_hit_points,
	"strength": stat_init_strength,
	"move_power": stat_init_move_power,
	"solar_charge_rate": stat_init_solar_charge_rate,
	"battery_capacity": stat_init_battery_capacity,
	"harvest_speed": stat_init_harvest_speed,
	"build_speed": stat_init_build_speed
}
var _stats_effective: Dictionary = {
	"size": _stats_base.size,
	"hit_points": _stats_base.hit_points,
	"strength": _stats_base.strength,
	"move_power": _stats_base.move_power,
	"solar_charge_rate": _stats_base.solar_charge_rate,
	"battery_capacity": _stats_base.battery_capacity,
	"harvest_speed": _stats_base.harvest_speed,
	"build_speed": _stats_base.build_speed
}

func _ready() -> void:
	_foot_step_timer = Timer.new()
	_foot_step_timer.wait_time = foot_step_time_delay
	_foot_step_timer.timeout.connect(_play_random_footstep_sound)
	add_child(_foot_step_timer)

	# start powered off
	_start_sleep(false)

func apply_size_bonuses() -> void:
	_stats_base.size = max(0.05, _stats_base.size)	# ABSOLUTE MINIMUM SIZE (prevents stat weirdness at very small values)
	_stats_effective.size = _stats_base.size
	_stats_effective.hit_points = _stats_base.hit_points * _stats_base.size ** 2
	_stats_effective.strength = _stats_base.strength + (_stats_base.size ** 3) / 4.0
	#_stats_effective.move_power = _stats_base.move_power + _stats_base.size() ** 2
	#_stats_effective.move_power = (_stats_base.move_power * (_stats_base.size ** 2.0) * 0.01 * (_stats_effective.strength + (_stats_base.size ** 3.0) / 4.0) ** 2.0)
	#_stats_effective.move_power = (_stats_base.move_power * (_stats_base.size ** 2.0) * 0.1 * (_stats_effective.strength + (_stats_base.size ** 3.0) / 2.0) * sqrt(_stats_base.size))
	_stats_effective.move_power = (_stats_base.move_power * (_stats_base.size ** 2.0) * 0.1 * (_stats_effective.strength + (_stats_base.size ** 3.0) / 2.0) * log(1.25 + _stats_base.size))
	_stats_effective.solar_charge_rate = _stats_base.solar_charge_rate
	_stats_effective.battery_capacity = _stats_base.battery_capacity
	_stats_effective.harvest_speed = _stats_base.harvest_speed * _stats_base.size
	_stats_effective.build_speed = _stats_base.build_speed
	_HP = _stats_effective.hit_points
	_mass = _stats_base.size ** 3
	metalTarget = _stats_base.size ** 3
	siliconTarget = _stats_base.size ** 3
	waterTarget = _stats_base.size ** 3


func init(
		body_resources: Dictionary,
		stats: Dictionary,
		color: Color,
		cobalt: bool,
		family: Family = Family.AI
	) -> void:
		
	_contains_cobalt = cobalt
	set_color(color)
	set_family(family)
	if !stats.is_empty(): _stats_base = stats
	apply_size_bonuses()
	_body_metal = _stats_base.size ** 3
	
	set_size(_stats_effective.size)


func set_family(family: Family):
	_family = family


func set_color(color: Color):
	_color = color
	$AnimatedSprite2D.set_self_modulate(color)


func die() -> void:
	generate_chunks(1.0, true)
	_sm.set_state(States.DEAD)
	queue_free()
	on_death.emit()


func is_dead() -> bool:
	return _sm.has_state(States.DEAD)


func move(movementDirection: Vector2) -> void:
	if is_zero_approx(buildProgress):
		_velocity = movementDirection.normalized()

		if _sm.has_any_state([States.REPRODUCING, States.OUT_OF_BATTERY, States.DASHING]): return
		if is_zero_approx(movementDirection.length()): return

		if !_sm.has_state(States.RUNNING):
			_sm.set_state(States.RUNNING)
			_play_random_footstep_sound()
			_foot_step_timer.start()

		_direction = Util.get_direction_from_vector(movementDirection)
		var batteryPercent = _carried_resources.battery_energy / _stats_effective.battery_capacity
		apply_central_force(movementDirection.normalized() * _stats_effective.move_power * clampf(2.7 * batteryPercent + 0.1, 0.0, 1.0)) # linear ramp from 10% speed at empty battery to 100% speed at 1/3 battery


func dash() -> void:
	if !is_zero_approx(buildProgress): return
	if _sm.has_any_state([States.DASHING, States.DASH_COOLDOWN, States.OUT_OF_BATTERY, States.REPRODUCING]): return

	_sm.set_state(States.DASHING)
	_sm.set_state(States.DASH_COOLDOWN)
	var direction: Vector2 = Util.get_vector_from_direction(_direction)
	var batteryPercent = min(_carried_resources.battery_energy / dash_battery_usage, 1.0)
	apply_central_impulse(direction * _stats_effective.move_power * dash_speed_multiplier * batteryPercent)
	_modify_battery_energy(-dash_battery_usage)
	$DashSoundEffect.play()
	Util.one_shot_timer(self, dash_duration, func() -> void:
		_sm.unset_state(States.DASHING)
	)
	Util.one_shot_timer(self, dash_cooldown_seconds, func() -> void:
		_sm.unset_state(States.DASH_COOLDOWN)
	)


func apply_damage(damage: float) -> void:
	on_damage.emit()
	_HP -= damage
	if _HP <= 0.0:
		die()


func generate_chunks(percent: float, include_body: bool) -> void:
	var metalMass = _carried_resources.metal * percent
	if include_body: metalMass += _body_metal
	while metalMass > 0.0:
		var randMass = min(randf_range((_stats_effective.size() ** 3) * 0.2, (_stats_effective.size() ** 3) * 0.5), metalMass)
		metalMass -= randMass
		if percent < 1.0 and _carried_resources.metal > 0.0:
			_carried_resources.metal = max(0.0, _carried_resources.metal - randMass)
		var new_morsel = morselTemplate.instantiate()
		$"../..".add_child(new_morsel)
		new_morsel._set_resource(randMass, true if _contains_cobalt else false, true)
		new_morsel.set_position(Vector2(position.x, position.y))


func get_nearby_pickuppables() -> Array:
	return ($reach_area.get_overlapping_bodies()
		.map(func(body) -> RigidBody2D: return body as RigidBody2D)
		.filter(func(body) -> bool: return body != null)
	)


func get_nearest_pickuppable() -> RigidBody2D:
	var nearest: RigidBody2D
	var nearest_distance: float = 1000.0 # arbitrary max float
	for body: RigidBody2D in get_nearby_pickuppables():
		var distance: float = (body.position - position).length()
		if distance < nearest_distance:
			nearest = body
			nearest_distance = distance
	return nearest


func pickup() -> void:
	if _sm.has_state(States.OUT_OF_BATTERY): return

	var nearestPickuppable = get_nearest_pickuppable()
	if nearestPickuppable != null:
		var crabItem: Crab
		crabItem = nearestPickuppable
		if crabItem != null:
			pass #crabItem is a crab; TODO: immobilize crab, tack its position to ours
		else:
			var morselItem: Morsel
			morselItem = nearestPickuppable
			if morselItem != null:
				pass #morselItem is a morsel; TODO: tack its position to ours
	else:
		return


func is_holding() -> bool:
	return false #TODO


func get_nearby_crabs() -> Array:
	return ($reach_area.get_overlapping_bodies()
		.map(func(body) -> Crab: return body as Crab)
		.filter(func(body) -> bool: return body != null)
	)


func get_nearest_crab() -> RigidBody2D:
	var nearest: Crab
	var nearest_distance: float = 1000.0 # arbitrary max float
	for body: Crab in get_nearby_crabs():
		var distance: float = (body.position - position).length()
		if distance < nearest_distance and body.get_rid() != self.get_rid() and !body.isPlayerFamily:
			nearest = body
			nearest_distance = distance
	return nearest


func harvest(delta: float) -> bool:
	if _sm.has_state(States.OUT_OF_BATTERY):
		stop_harvest()
		return false
	if _contains_cobalt:
		var nearestCrab = get_nearest_crab()
		if nearestCrab != null:
			attackCrab(nearestCrab, delta)
			return true
	var nearestMorsel = get_nearest_morsel()
	if nearestMorsel != null:
		return harvest_morsel(delta, nearestMorsel)
	else:
		var sandBodies = _island.SandArea.get_overlapping_bodies()
		if sandBodies.has(self):
			return harvest_sand(delta)
		else:
			var waterBodies = _island.WaterArea.get_overlapping_bodies()
			if waterBodies.has(self):
				return harvest_water(delta)
		return false


func attackCrab(target: Crab, delta: float) -> void:
	var relative_strength_mult = _stats_effective.strength / target._stats_effective.strength
	var dmg = _stats_effective.strength * delta * relative_strength_mult
	target.apply_damage(dmg)
	$Sparks.set_emitting(true)
	$Sparks.global_position = target.global_position
	$HarvestSoundEffect.play(randf_range(0, 5.0))


func harvest_sand(delta: float) -> bool:
	if _sm.has_state(States.OUT_OF_BATTERY):
		stop_harvest()
		return false

	var partial_harvest = min(1.0, _carried_resources.battery_energy / (delta * -harvestDrainMult))
	if _carried_resources.silicon < siliconTarget:
		_add_silicon(partial_harvest * _stats_effective.harvest_speed * delta, delta)
		$Vacuum.set_color(Color(0.75, 0.6, 0.0))
		$Vacuum.set_emitting(true)
		return true
	return false


func harvest_water(delta: float) -> bool:
	if _sm.has_state(States.OUT_OF_BATTERY):
		stop_harvest()
		return false

	var partial_harvest = min(1.0, _carried_resources.battery_energy / (delta * -harvestDrainMult))
	if _carried_resources.water < waterTarget:
		_add_water(partial_harvest * _stats_effective.harvest_speed * delta, delta)
		$Vacuum.set_color(Color(0.0, 1.0, 1.0))
		$Vacuum.set_emitting(true)
		return true
	return false


func harvest_morsel(delta: float, morsel: Morsel) -> bool:
	if _sm.has_state(States.OUT_OF_BATTERY):
		stop_harvest()
		return false

	var partial_harvest = min(1.0, _carried_resources.battery_energy / (delta * -harvestDrainMult))
	if _carried_resources.metal < metalTarget: _add_metal(partial_harvest * morsel._extract(_stats_effective.harvest_speed * delta), delta, morsel.contains_cobalt)
	else: return false

	$Sparks.set_emitting(true)
	$Sparks.global_position = morsel.global_position + (global_position - morsel.global_position) * 0.67
	$HarvestSoundEffect.play(randf_range(0, 5.0))
	return true


func stop_harvest():
	$Vacuum.set_emitting(false)
	$Sparks.set_emitting(false)
	$HarvestSoundEffect.stop()


func get_nearby_morsels() -> Array:
	return ($reach_area.get_overlapping_bodies()
		.map(func(body) -> Morsel: return body as Morsel)
		.filter(func(body) -> bool: return body != null)
	)


func get_nearest_morsel() -> Morsel:
	var nearest: Morsel
	var nearest_distance: float = 1000.0 # arbitrary max float
	for morsel: Morsel in get_nearby_morsels():
		var distance: float = (morsel.position - position).length()
		if distance < nearest_distance:
			nearest = morsel
			nearest_distance = distance
	return nearest


func can_reach_morsel(morsel: Morsel) -> bool:
	return get_nearby_morsels().has(morsel)


func auto_reproduce(delta: float) -> bool:
	if can_reproduce():
		if _sm.has_any_state([States.OUT_OF_BATTERY]):
			return true
		buildProgress += _stats_effective.build_speed * delta
		_modify_battery_energy(_stats_effective.build_speed * delta * buildDrainMult)
		if buildProgress >= 1.0:
			var mutation: Dictionary = MutationEngine.get_mutation_options(_stats_base)
			reproduce(mutation)
			buildProgress = 0.0
			return false
		return true
	return false


func stop_reproduce() -> void:
	if buildProgress > 0.0:
		generate_chunks(buildProgress, false)
		_carried_resources.water *= 1.0 - buildProgress #TODO: probably should make a remove_resource function so we don't have to write manually
		buildProgress = 0.0


func reproduce(mutation: Dictionary) -> void:
	var new_stats: Dictionary = MutationEngine.apply_mutation(_stats_base, mutation)
	var new_crab: Crab = _island.create_new_crab()
	var new_body_resources = { "metal": _carried_resources.metal, "silicon": _carried_resources.silicon }
	_carried_resources = { "metal": 0.0, "silicon": 0.0, "water": 0.0, "battery_energy": _carried_resources.battery_energy }
	new_crab._carried_resources = { "metal": 0.0, "silicon": 0.0, "water": 0.0, "battery_energy": 0.0 }
	new_crab.init(new_body_resources, new_stats, _color, _contains_cobalt, _family)
	var new_crab_direction: Vector2 = Util.random_direction()
	new_crab.position = position + (new_crab_direction * new_crab._stats_effective.size * 32.0)
	var new_crab_ai: CrabAI = crab_ai_scene.instantiate()
	new_crab.add_child(new_crab_ai)
	new_crab.stat_toasts(mutation)
	if !(_island.tutorial_swap) and new_crab.isPlayerFamily:
		_island.tutorial_swap = true
		tabForTrigger.set_visible(true)
		tabForTrigger.fading = true


func has_reproduction_resources() -> bool:
	if _carried_resources.metal < metalTarget: return false
	if _carried_resources.silicon < siliconTarget: return false
	if _carried_resources.water < waterTarget: return false
	return true


func can_reproduce() -> bool:
	if !has_reproduction_resources(): return false
	return true


func get_mutations(num_options: int = 1) -> Array:
	var mutations: Array
	for _i in num_options:
		mutations.push_back(MutationEngine.get_mutation_options(_stats_base))
	return mutations


func _process(delta: float) -> void:
	_update_movement_state()
	_update_sleep_state()
	_harvest_sunlight(delta)
	_deplete_battery_from_movement(delta)
	_update_animation_from_state()


func _harvest_sunlight(delta: float) -> void:
	var time: float = WorldClock.time
	if time > 0.25 && time < 0.75:
		var gained_energy: float = _stats_effective.solar_charge_rate * delta
		_modify_battery_energy(gained_energy)


func _deplete_battery_from_movement(delta: float) -> void:
	if !_sm.has_state(States.RUNNING): return

	var batteryPercent = _carried_resources.battery_energy / _stats_effective.battery_capacity
	var lost_energy: float = min(move_battery_usage * delta * (1.6 * batteryPercent + 0.2), 1.0) # usage scales to match speed ramp at low battery
	_modify_battery_energy(-lost_energy)

func _update_sleep_state() -> void:
	if !_sm.has_state(States.SHUTDOWN_COOLDOWN) && _sm.has_state(States.OUT_OF_BATTERY) && _carried_resources.battery_energy > 0:
		_end_sleep()

func _modify_battery_energy(value: float) -> void:
	_carried_resources.battery_energy = clampf(_carried_resources.battery_energy + value, 0, _stats_effective.battery_capacity)
	if is_zero_approx(_carried_resources.battery_energy):
		_start_sleep()


func _start_sleep(play_sound: bool = true) -> void:
	if _sm.has_state(States.OUT_OF_BATTERY): return

	_sm.set_states([States.OUT_OF_BATTERY, States.SHUTDOWN_COOLDOWN])
	if play_sound: $PowerOffSoundEffect.play()
	$Zs.set_emitting(true)
	stop_harvest()
	Util.one_shot_timer(self, shutdown_cooldown_seconds, func() -> void:
		_sm.unset_state(States.SHUTDOWN_COOLDOWN)
	)


func _end_sleep() -> void:
	_sm.unset_state(States.OUT_OF_BATTERY)
	$PowerOnSoundEffect.play()
	$Zs.set_emitting(false)


func will_drop_metal() -> bool:
	return _carried_resources.metal > 0 || _body_metal > 0


func _add_metal(value: float, delta: float, morsel_has_cobalt: bool) -> void:
	_carried_resources.metal = clampf(_carried_resources.metal + value, 0, metalTarget)
	if morsel_has_cobalt: _contains_cobalt = true
	_modify_battery_energy(delta * harvestDrainMult)


func _add_silicon(value: float, delta: float) -> void:
	_carried_resources.silicon = clampf(_carried_resources.silicon + value, 0, siliconTarget)
	_modify_battery_energy(delta * harvestDrainMult)


func _add_water(value: float, delta: float) -> void:
	_carried_resources.water = clampf(_carried_resources.water + value, 0, waterTarget)
	_modify_battery_energy(delta * harvestDrainMult)


func _update_movement_state() -> void:
	if _sm.has_state(States.OUT_OF_BATTERY):
		_foot_step_timer.stop()
		_sm.unset_state(States.RUNNING)
		return

	if _sm.has_state(States.DASHING): return

	if is_zero_approx(_velocity.length()):
		_foot_step_timer.stop()
		_sm.unset_state(States.RUNNING)


func _update_animation_from_state() -> void:
	var animation: String
	var flip_h: bool

	if _direction in Util.LeftDirections: flip_h = true

	if _sm.has_state(States.OUT_OF_BATTERY):
		animation = "sleep"
	elif _sm.has_state(States.REPRODUCING):
		animation = "sleep"
	elif _sm.has_state(States.DASHING):
		animation = "dash"
	elif _sm.has_state(States.RUNNING):
		animation = "move"
	else:
		animation = "idle"

	if animation != _current_animation || flip_h != _current_flip_h:
		_current_animation = animation
		_current_flip_h = flip_h
		$AnimatedSprite2D.play(_current_animation)
		$AnimatedSprite2D.flip_h = _current_flip_h

func stat_toasts(mutation: Dictionary) -> void:
	var newToast = toastTemplate.instantiate()
	add_child(newToast)
	newToast.set_stats(mutation)

func _play_random_footstep_sound() -> void:
	var sound: AudioStreamPlayer2D = _foot_step_sounds[randi_range(0, _foot_step_sounds.size() - 1)]
	sound.pitch_scale = randf_range(0.8, 1.2)
	sound.play()

func set_size(new_scale: float) -> void:
	for child in find_children("*", "", false):
		var scalable_child: Node2D = child as Node2D
		if scalable_child != null: scalable_child.scale *= new_scale
	set_mass(new_scale ** 3)

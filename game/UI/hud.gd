class_name hud#HUD

extends CanvasLayer

var _clock: Clock
var _crab: Crab
var _day: int = -1

@onready var energyBar = $topleft/energy_bar
@onready var waterBar = $topleft/water_bar
@onready var waterCloneBar = $topleft/water_bar/water_clone_bar
@onready var siliconBar = $topleft/silicon_bar
@onready var siliconCloneBar = $topleft/silicon_bar/silicon_clone_bar
@onready var metalBar = $topleft/metal_bar
@onready var metalCloneBar = $topleft/metal_bar/metal_clone_bar
@onready var sundial = $topright/sundial
@onready var dayLabel = $topright/day_label

var tutorial_clone: bool

const active_color: Color = Color(1.0, 1.0, 1.0)
const inactive_color: Color = Color(0.0625, 0.0625, 0.0625)


func init() -> void:
	var scenario: Scenario = get_parent()

	_clock = Util.require_child(scenario, Clock)

	var crab_spawner: CrabSpawner = Util.require_child(scenario, CrabSpawner)
	crab_spawner.on_player_spawn.connect(func(crab: Crab) -> void:
		set_crab(crab)
	)

	var victory_conditions: VictoryConditions = Util.require_child(scenario, VictoryConditions)
	victory_conditions.defeat.connect(_trigger_defeat)
	victory_conditions.victory.connect(_trigger_victory)

	var player_crab_controller: PlayerCrabController = Util.require_child(scenario, PlayerCrabController)
	player_crab_controller.on_disassociate.connect(func() -> void: _set_tab_menu(true))
	var switcher_controller: SwitcherController = Util.require_child(scenario, SwitcherController)
	switcher_controller.on_set_crab.connect(set_crab)
	switcher_controller.on_select.connect(func(__crab: Crab) -> void: _set_tab_menu(false))


func set_crab(crab: Crab) -> void:
	_crab = crab
	_update_statblock()


func _process(_delta) -> void:
	_update_sundial()
	if !is_instance_valid(_crab): return

	_update_battery()
	_update_resources()
	_update_cobalt_light()
	_update_ready_to_clone()
	_update_build_progress()


func _update_sundial() -> void:
	if _day != _clock.day_count:
		dayLabel.text = "Day " + str(_clock.day_count + 1)
		_day = _clock.day_count
	
	sundial.set_rotation(2.0 * PI * _clock.time)


func _update_battery() -> void:
	var batteryPercent = _crab._carried_resources.battery_energy / _crab._stats_effective.battery_capacity
	energyBar.value = 100.0 * batteryPercent
	var redVal = max(1.0 - 3.0 * batteryPercent, 0.0)
	var greenVal = min(3 * batteryPercent, 1.0)
	energyBar.get_theme_stylebox("fill").set_bg_color(Color(redVal, greenVal, 0.0))


func _update_resources() -> void:
	_update_water()
	_update_silicon()
	_update_metal()


func _update_cobalt_light() -> void:
	_set_cobalt_light(_cobalt_target_reached())


func _update_ready_to_clone() -> void:
	_set_clone_light(_reproduction_targets_reached())


func _update_build_progress() -> void:
	var progress: float = 100.0 * _crab.buildProgress
	waterCloneBar.value = progress
	siliconCloneBar.value = progress
	metalCloneBar.value = progress


func _reproduction_targets_reached() -> bool:
	return _water_target_reached() && _silicon_target_reached() && _metal_target_reached()


func _water_target_reached() -> bool:
	return _crab._carried_resources.water >= _crab.waterTarget


func _silicon_target_reached() -> bool:
	return _crab._carried_resources.silicon >= _crab.siliconTarget


func _metal_target_reached() -> bool:
	return _crab._carried_resources.metal >= _crab.metalTarget


func _cobalt_target_reached() -> bool:
	return _crab._contains_cobalt


func _update_water() -> void:
	waterBar.value = 100.0 * _crab._carried_resources.water / _crab.waterTarget
	_set_water_light(_water_target_reached())


func _update_silicon() -> void:
	siliconBar.value = 100.0 * _crab._carried_resources.silicon / _crab.siliconTarget
	_set_silicon_light(_silicon_target_reached())


func _update_metal() -> void:
	metalBar.value = 100.0 * _crab._carried_resources.metal / _crab.metalTarget
	_set_metal_light(_metal_target_reached())


func _set_cobalt_light(activate: bool) -> void:
	var sizeFloat: float = 2.0 + 0.5 * sin(_clock.time * 240.0)
	$topleft/cobalt_light/cobalt_glow.set_scale(Vector2(sizeFloat, sizeFloat))
	$topleft/cobalt_light.set_self_modulate(active_color if activate else inactive_color)
	$topleft/cobalt_light/cobalt_glow.set_visible(activate)


func _set_metal_light(activate: bool) -> void:
	$topleft/clone_light/metal_light.set_self_modulate(active_color if activate else inactive_color)


func _set_silicon_light(activate: bool) -> void:
	$topleft/clone_light/silicon_light.set_self_modulate(active_color if activate else inactive_color)


func _set_water_light(activate: bool) -> void:
	$topleft/clone_light/water_light.set_self_modulate(active_color if activate else inactive_color)


func _set_clone_light(activate: bool) -> void:
	$topleft/clone_light.set_self_modulate(active_color if activate else inactive_color)
	if !tutorial_clone and activate:
		tutorial_clone = true
		$topleft/Q.set_visible(true)
		$topleft/Q.fading = true


func _set_tab_menu(visibility: bool) -> void:
	_update_statblock()
	$center/TAB.set_visible(visibility)
	$center/crab_cursor.set_visible(visibility)
	$center/statblock.set_visible(visibility)


func _update_statblock() -> void:
	var lines: Array = []
	for stat in _crab._stats_effective:
		var stat_value: int = floor(100.0 * _crab._stats_effective[stat] / _crab._family_base_stats[stat])
		var stat_name: String = Translator.g(stat)
		lines.append(stat_name + ":\t\t" + str(stat_value) + "%")
	$center/statblock.set_text("\n".join(lines))


func _trigger_defeat() -> void:
	$center/defeat.set_visible(true)


func _trigger_victory() -> void:
	$center/victory.set_visible(true)

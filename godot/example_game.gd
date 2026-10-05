extends Node2D
## Example: how a game scene reacts to the votes.
## Every option is pre-built (all heroes, enemies, worlds, powers) – we only switch between them.
##
## Kids' game (stage_mode = false): starts empty, each secret code from Unlocks adds one feature.
## Show computer (stage_mode = true): follows the stage winners live through VoteBridge.

@export var stage_mode := false

@onready var heroes := $Heroes.get_children()    # Adventure, Dino, Shadow
@onready var enemies := $Enemies.get_children()  # Boar, Bunny, Ghost
@onready var worlds := $Worlds.get_children()    # Abyss, Forest
@onready var powers := ["fly", "sniper", "speed"]


func _ready() -> void:
	if stage_mode:
		apply_build(VoteBridge.get_live_build())
		VoteBridge.winner_chosen.connect(apply_choice)
		VoteBridge.start_live()
	else:
		for stage in Unlocks.Stage.values():
			apply_choice(stage, Unlocks.get_option(stage))  # restores saved unlocks, rest stays empty
		Unlocks.feature_unlocked.connect(_on_feature_unlocked)


func _on_feature_unlocked(stage: int, option: int) -> void:
	apply_choice(stage, option)
	# Good moment for an effect: sparkles, sound, camera zoom on the new thing…


func apply_build(build: PackedInt32Array) -> void:
	for stage in build.size():
		apply_choice(stage, build[stage])


## option == -1 → not unlocked yet, the whole category is hidden / off.
func apply_choice(stage: int, option: int) -> void:
	match stage:
		Unlocks.Stage.HERO:
			_show_only(heroes, option)
		Unlocks.Stage.ENEMY:
			_show_only(enemies, option)
		Unlocks.Stage.WORLD:
			_show_only(worlds, option)
		Unlocks.Stage.POWER:
			$Player.power = powers[option] if option >= 0 else ""


func _show_only(nodes: Array, index: int) -> void:
	for i in nodes.size():
		nodes[i].visible = i == index
		nodes[i].process_mode = Node.PROCESS_MODE_INHERIT if i == index else Node.PROCESS_MODE_DISABLED

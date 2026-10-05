extends Node
## Secret unlock codes. After each stage the kids get a code on their phone,
## type it into the game, and that feature unlocks. Unlocks are saved, so they survive a restart.
##
## Setup: Project Settings → Globals → Autoload → add this file with the name "Unlocks".

signal feature_unlocked(stage: int, option: int)

enum Stage { HERO, ENEMY, WORLD, POWER }

## code → [stage, option].  KEEP IN SYNC with `codes` in js/shared.js.
const CODES := {
	"4821": [Stage.HERO, 0], "1937": [Stage.HERO, 1], "6054": [Stage.HERO, 2],
	"2768": [Stage.ENEMY, 0], "9310": [Stage.ENEMY, 1], "5142": [Stage.ENEMY, 2],
	"7493": [Stage.WORLD, 0], "3086": [Stage.WORLD, 1],
	"8615": [Stage.POWER, 0], "0279": [Stage.POWER, 1], "6831": [Stage.POWER, 2],
}

const NAMES := [
	["Kalandor", "Dínó", "Árny"],
	["Vaddisznó", "Nyuszi", "Kísértet"],
	["Szakadék", "Erdő"],
	["Repülés", "Mesterlövész", "Szupergyorsaság"],
]

const SAVE_PATH := "user://unlocks.cfg"

var unlocked := {}  # stage -> option


func _ready() -> void:
	_load()


## Returns the unlocked stage, or -1 if the code is wrong.
## A new code for an already unlocked stage replaces the old choice.
func try_code(text: String) -> int:
	var code := text.strip_edges().replace(" ", "")
	if not CODES.has(code):
		return -1
	var stage: int = CODES[code][0]
	var option: int = CODES[code][1]
	unlocked[stage] = option
	_save()
	feature_unlocked.emit(stage, option)
	return stage


func get_option(stage: int) -> int:
	return unlocked.get(stage, -1)


func name_of(stage: int, option: int) -> String:
	return NAMES[stage][option]


## Fresh start (e.g. a "new player" button on a shared computer).
func clear() -> void:
	for stage in unlocked.keys():
		feature_unlocked.emit(stage, -1)
	unlocked.clear()
	_save()


func _save() -> void:
	var cfg := ConfigFile.new()
	for stage in unlocked:
		cfg.set_value("unlocked", str(stage), unlocked[stage])
	cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK or not cfg.has_section("unlocked"):
		return
	for key in cfg.get_section_keys("unlocked"):
		unlocked[int(key)] = int(cfg.get_value("unlocked", key))

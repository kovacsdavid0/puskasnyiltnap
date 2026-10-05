extends Node
## STAGE ONLY: connects the show computer's game to the voting site (Firebase Realtime Database).
## Kids' own games don't need this – they use Unlocks.gd with the secret codes.
##
## Setup: Project Settings → Globals → Autoload → add this file with the name "VoteBridge".
## Nothing is fetched until you call VoteBridge.start_live().

signal round_changed(stage: int)
signal votes_changed(stage: int, votes: Array)
signal winner_chosen(stage: int, option: int)  # option == -1 → round reopened
signal phase_changed(phase: String)

const DB_URL := "https://talentum-nap-default-rtdb.europe-west1.firebasedatabase.app"
const ROUND_SIZES := [3, 3, 2, 3]  # must match ROUNDS in js/shared.js

@export var poll_seconds := 0.5

var current_round := 0
var phase := "vote"
var winners := {}  # round -> option index inside that round
var votes := []    # votes[round] = [int, int, ...]

var _http := HTTPRequest.new()
var _timer := Timer.new()
var _busy := false


func _ready() -> void:
	add_child(_http)
	_http.request_completed.connect(_on_response)
	add_child(_timer)
	_timer.wait_time = poll_seconds
	_timer.timeout.connect(_poll)


func start_live() -> void:
	_timer.start()
	_poll()


func stop_live() -> void:
	_timer.stop()


## The combination that won on stage so far. Rounds without a winner yet are -1 (empty).
func get_live_build() -> PackedInt32Array:
	var out := PackedInt32Array()
	for r in ROUND_SIZES.size():
		out.append(winners.get(r, -1))
	return out


# ---------------------------------------------------------------- polling

func _poll() -> void:
	if _busy:
		return
	_busy = true
	if _http.request(DB_URL + "/.json") != OK:
		_busy = false


func _on_response(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_busy = false
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY:
		return

	var new_phase := str(data.get("phase", "vote"))
	if new_phase != phase:
		phase = new_phase
		phase_changed.emit(phase)

	var new_round := clampi(int(data.get("currentGroup", 0)), 0, ROUND_SIZES.size() - 1)
	if new_round != current_round:
		current_round = new_round
		round_changed.emit(current_round)

	var new_votes := []
	var start := 0
	for r in ROUND_SIZES.size():
		var list := []
		for i in ROUND_SIZES[r]:
			var opt = _item(data.get("options"), start + i)
			list.append(int(opt.get("votes", 0)) if opt is Dictionary else 0)
		new_votes.append(list)
		start += ROUND_SIZES[r]
	var changed := votes.size() != new_votes.size() or votes[current_round] != new_votes[current_round]
	votes = new_votes
	if changed:
		votes_changed.emit(current_round, votes[current_round])

	for r in ROUND_SIZES.size():
		var w = _item(data.get("winners"), r)
		if w == null and winners.has(r):
			winners.erase(r)
			winner_chosen.emit(r, -1)
		elif w != null and winners.get(r, -1) != int(w):
			winners[r] = int(w)
			winner_chosen.emit(r, int(w))


# Firebase returns numeric keys either as an Array or as a Dictionary with string keys.
func _item(container, i: int):
	if container is Array:
		return container[i] if i < container.size() else null
	if container is Dictionary:
		return container.get(str(i))
	return null

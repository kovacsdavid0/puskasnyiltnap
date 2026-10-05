extends Control
## The box where kids type their secret code.
## Scene: a Control with this script and three children:
##   LineEdit "Code", Button "Unlock", Label "Feedback"

@onready var code_edit: LineEdit = $Code
@onready var unlock_button: Button = $Unlock
@onready var feedback: Label = $Feedback


func _ready() -> void:
	code_edit.max_length = 4
	code_edit.placeholder_text = "Kód"
	code_edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER  # number pad on phones/tablets
	code_edit.text_submitted.connect(func(_text: String) -> void: _submit())
	unlock_button.text = "Feloldás"
	unlock_button.pressed.connect(_submit)
	feedback.text = ""


func _submit() -> void:
	var stage := Unlocks.try_code(code_edit.text)
	if stage < 0:
		feedback.text = "Hibás kód"
		feedback.modulate = Color(1.0, 0.4, 0.45)
	else:
		feedback.text = "Feloldva: %s!" % Unlocks.name_of(stage, Unlocks.get_option(stage))
		feedback.modulate = Color(0.4, 1.0, 0.6)
	code_edit.clear()
	code_edit.grab_focus()

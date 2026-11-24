extends Control

@onready var character_name = $DialogueBox/Content/CharacterName
@onready var dialogue_text = $DialogueBox/Content/DialogueText
@onready var next_button = $DialogueBox/Content/NextButton
@onready var alya = $"Character Alya"

var dialogues = [
	{
		"name": "Sekala",
		"text": "Halo! Selamat datang di Sekala Boutique. Aku Sekala, pemilik butik ini!"
	},
	{
		"name": "Sekala",
		"text": "Di butik ini, kamu akan membantuku memilihkan pakaian untuk para pelanggan."
	},
	{
		"name": "Sekala",
		"text": "Oh, sepertinya ada pelanggan yang datang! Yuk, kita sambut dia."
	},
	{
		"name": "Alya",
		"text": "Halo! Namaku Alya. Senang bertemu denganmu!"
	},
	{
		"name": "Alya",
		"text": "Aku sedang mencari pakaian untuk menghadiri acara keluarga akhir pekan ini."
	},
	{
		"name": "Alya",
		"text": "Aku ingin tampil feminin dan elegan, tapi tetap nyaman dipakai."
	},
	{
		"name": "Alya",
		"text": "Aku suka warna-warna pastel. Oh, tapi aku kurang suka warna hijau!"
	},
	{
		"name": "Alya",
		"text": "Kira-kira kamu bisa bantu aku memilih outfit yang cocok?"
	}
]

var current_dialogue = 0

func _ready():
	alya.hide()
	next_button.pressed.connect(_on_next_button_pressed)
	show_dialogue()

func show_dialogue():
	var current_name = dialogues[current_dialogue]["name"]

	character_name.text = current_name
	dialogue_text.text = dialogues[current_dialogue]["text"]

	if current_name == "Sekala":
		character_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		dialogue_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	else:
		character_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		dialogue_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _on_next_button_pressed():
	if current_dialogue < dialogues.size() - 1:
		current_dialogue += 1

		if current_dialogue == 3:
			alya.show()

		show_dialogue()
	else:
		get_tree().change_scene_to_file("res://scenes/dress_up_page.tscn")

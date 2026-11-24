extends Control

@onready var tops_button = $WardrobePanel/WardrobeContent/WardrobeLayout/CategoryTabs/TopsButton
@onready var bottoms_button = $WardrobePanel/WardrobeContent/WardrobeLayout/CategoryTabs/BottomsButton
@onready var outers_button = $WardrobePanel/WardrobeContent/WardrobeLayout/CategoryTabs/OutersButton
@onready var accessories_button = $WardrobePanel/WardrobeContent/WardrobeLayout/CategoryTabs/AccessoriesButton

# Item pakaian di wardrobe
@onready var top_item_1 = $WardrobePanel/WardrobeContent/WardrobeLayout/ItemScroll/ItemGrid/TopItem1

# Sprite pakaian pada karakter Alya
@onready var top_sprite = $CharacterPreview/Top


func _ready():
	tops_button.pressed.connect(_on_tops_pressed)
	bottoms_button.pressed.connect(_on_bottoms_pressed)
	outers_button.pressed.connect(_on_outers_pressed)
	accessories_button.pressed.connect(_on_accessories_pressed)

	# Sembunyikan atasan saat permainan dimulai
	top_sprite.hide()

	# Aktifkan klik pada gambar pakaian
	top_item_1.mouse_filter = Control.MOUSE_FILTER_STOP
	top_item_1.gui_input.connect(_on_top_item_1_clicked)


func _on_tops_pressed():
	print("Tops selected")


func _on_bottoms_pressed():
	print("Bottoms selected")


func _on_outers_pressed():
	print("Outers selected")


func _on_accessories_pressed():
	print("Accessories selected")


# Fungsi ketika pemain memilih TopItem1
func _on_top_item_1_clicked(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			top_sprite.show()
			print("Top 1 dipakaikan ke Alya!")

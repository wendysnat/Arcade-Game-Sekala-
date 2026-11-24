extends Control

# Style note: Sekala Boutique cozy pastel-wood palette (#4A2E25 ink, #FFF5EB cream, #F6D9C8 blush).
const CONFIG := {
	"default_category": "Top",
	"slots_per_page": 8,
	"thumbnail_crop_padding": 12,
	"supported_extensions": ["png", "webp", "jpg", "jpeg"],
	"categories": [
		{
			"id": "Top",
			"folder": "res://assets/outfits/Top",
			"button_path": "WardrobeUI/CategoryButtons/TopButton",
			"icon_path": "res://assets/ui/Top.png",
			"strict_accessory_slots": false,
			"z_index": 2,
		},
		{
			"id": "Bottom",
			"folder": "res://assets/outfits/Bottom",
			"button_path": "WardrobeUI/CategoryButtons/BottomButton",
			"icon_path": "res://assets/ui/Bottom.png",
			"strict_accessory_slots": false,
			"z_index": 1,
		},
		{
			"id": "Outer",
			"folder": "res://assets/outfits/Outer",
			"button_path": "WardrobeUI/CategoryButtons/OuterButton",
			"icon_path": "res://assets/ui/Outer.png",
			"strict_accessory_slots": false,
			"z_index": 3,
		},
		{
			"id": "Accessories",
			"folder": "res://assets/outfits/Accessories",
			"button_path": "WardrobeUI/CategoryButtons/AccessoriesButton",
			"icon_path": "res://assets/ui/Accessories.png",
			"strict_accessory_slots": true,
			"z_index": 4,
		},
	],
	# Strict Accessories naming rule: <type>_<item_name>.png
	# Cropped PNGs snap to `position` and `scale`.
	# Full-canvas PNGs (same size as Base chibi Alya.png, 1536x2048) align to BaseCharacter automatically.
	"accessory_slots": {
		"shoes": {
			"position": Vector2(410, 533),
			"scale": Vector2(0.214, 0.214),
			"z_index": 0,
			"under_clothes": true,
		},
		"ribbon": {
			"position": Vector2(462, 198),
			"scale": Vector2(0.214, 0.214),
			"z_index": 8,
			"under_clothes": false,
		},
		"hat": {
			"position": Vector2(398, 168),
			"scale": Vector2(0.214, 0.214),
			"z_index": 9,
			"under_clothes": false,
		},
		"glasses": {
			"position": Vector2(392, 248),
			"scale": Vector2(0.214, 0.214),
			"z_index": 7,
			"under_clothes": false,
		},
		"earring": {
			"position": Vector2(460, 264),
			"scale": Vector2(0.214, 0.214),
			"z_index": 6,
			"under_clothes": false,
		},
		"necklace": {
			"position": Vector2(412, 322),
			"scale": Vector2(0.214, 0.214),
			"z_index": 4,
			"under_clothes": false,
		},
		"armband": {
			"position": Vector2(468, 374),
			"scale": Vector2(0.214, 0.214),
			"z_index": 5,
			"under_clothes": false,
		},
		"glove": {
			"position": Vector2(419, 422),
			"scale": Vector2(0.214, 0.214),
			"z_index": 5,
			"under_clothes": false,
		},
		"ring": {
			"position": Vector2(498, 420),
			"scale": Vector2(0.214, 0.214),
			"z_index": 6,
			"under_clothes": false,
		},
	},
	"category_active_modulate": Color(1.0, 1.0, 1.0, 1.0),
	"category_inactive_modulate": Color(0.86, 0.80, 0.76, 0.85),
	"slot_selected_bg": Color(0.97, 0.84, 0.78, 0.28),
	"slot_selected_border": Color(0.76, 0.44, 0.36, 0.95),
	"category_selected_border": Color(0.85, 0.52, 0.36, 1.0),
}

@onready var character_preview: Node2D = $CharacterPreview
@onready var base_character: Sprite2D = $CharacterPreview/BaseCharacter
@onready var wardrobe_slots_container: Control = $WardrobeUI/WardrobeSlots
@onready var pagination_bar: HBoxContainer = $WardrobeUI/PaginationBar
@onready var prev_button: Button = $WardrobeUI/PaginationBar/PrevButton
@onready var page_label: Label = $WardrobeUI/PaginationBar/PageLabel
@onready var next_button: Button = $WardrobeUI/PaginationBar/NextButton

var _categories_by_id: Dictionary = {}
var _category_buttons: Dictionary = {}
var _category_frames: Dictionary = {}
var _slot_buttons: Array[TextureButton] = []
var _slot_frames: Array[Panel] = []

var _preset_sprites: Dictionary = {} # res_path -> Sprite2D
var _dynamic_sprites: Dictionary = {} # res_path -> Sprite2D
var _texture_cache: Dictionary = {} # res_path -> Texture2D
var _preview_cache: Dictionary = {} # res_path -> Texture2D

var _current_category: String = ""
var _current_items: Array[String] = []
var _current_page: int = 0

var _equipped_single: Dictionary = {} # category_id -> res_path
var _equipped_accessories: Dictionary = {} # accessory_slot_type -> res_path


func _ready() -> void:
	_setup_character_initial_state()
	_setup_category_buttons()
	_setup_wardrobe_slots()
	_setup_pagination()
	select_category(CONFIG["default_category"])


func select_category(category_id: String, reset_page: bool = true) -> void:
	if not _categories_by_id.has(category_id):
		return

	_current_category = category_id
	if reset_page:
		_current_page = 0

	var category_cfg: Dictionary = _categories_by_id[category_id]
	_current_items = _scan_category_images(
		category_cfg["folder"],
		bool(category_cfg.get("strict_accessory_slots", false))
	)
	_update_category_button_visuals()
	_render_current_page()


func refresh_wardrobe() -> void:
	if _current_category.is_empty():
		return
	select_category(_current_category, false)


func parse_accessory_slot(res_path: String) -> String:
	var base_name := res_path.get_file().get_basename().to_lower()
	var sep_idx := base_name.find("_")
	if sep_idx <= 0 or sep_idx >= base_name.length() - 1:
		return ""
	var slot_type := base_name.substr(0, sep_idx)
	var accessory_slots: Dictionary = CONFIG["accessory_slots"]
	if accessory_slots.has(slot_type):
		return slot_type
	return ""


func get_wardrobe_state() -> Dictionary:
	var slots_per_page: int = CONFIG["slots_per_page"]
	var total_pages: int = maxi(1, ceili(float(_current_items.size()) / float(slots_per_page)))
	var equipped: Array[String] = []
	for path in _equipped_single.values():
		if not String(path).is_empty():
			equipped.append(path)
	for path in _equipped_accessories.values():
		if not String(path).is_empty():
			equipped.append(path)
	return {
		"category": _current_category,
		"page": _current_page,
		"total_pages": total_pages,
		"item_count": _current_items.size(),
		"pagination_visible": pagination_bar.visible,
		"equipped": equipped,
		"equipped_accessories": _equipped_accessories.duplicate(),
	}


func _setup_character_initial_state() -> void:
	base_character.visible = true
	_collect_and_hide_outfit_sprites(character_preview)


func _collect_and_hide_outfit_sprites(node: Node) -> void:
	for child in node.get_children():
		if child is Sprite2D and child != base_character:
			var sprite := child as Sprite2D
			sprite.visible = false
			if sprite.texture != null and not sprite.texture.resource_path.is_empty():
				_preset_sprites[sprite.texture.resource_path] = sprite
		_collect_and_hide_outfit_sprites(child)


func _setup_category_buttons() -> void:
	var selected_style := _create_highlight_style(Color(0, 0, 0, 0), CONFIG["category_selected_border"], 3, 11)
	for entry in CONFIG["categories"]:
		var category_cfg: Dictionary = entry
		var cat_id: String = category_cfg["id"]
		_categories_by_id[cat_id] = category_cfg

		var button := get_node_or_null(category_cfg["button_path"]) as TextureButton
		if button == null:
			continue

		if button.texture_normal == null:
			button.texture_normal = _load_texture(category_cfg["icon_path"])

		var frame := _attach_highlight_frame(button, selected_style, 2)
		_category_buttons[cat_id] = button
		_category_frames[cat_id] = frame
		button.pressed.connect(select_category.bind(cat_id, true))


func _setup_wardrobe_slots() -> void:
	var selected_style := _create_highlight_style(
		CONFIG["slot_selected_bg"],
		CONFIG["slot_selected_border"],
		2,
		8
	)
	_slot_buttons.clear()
	_slot_frames.clear()

	for i in range(CONFIG["slots_per_page"]):
		var slot_node := wardrobe_slots_container.get_node_or_null("Slot%d" % (i + 1)) as TextureButton
		if slot_node == null:
			continue
		var frame := _attach_highlight_frame(slot_node, selected_style)
		_slot_buttons.append(slot_node)
		_slot_frames.append(frame)
		slot_node.pressed.connect(_on_slot_pressed.bind(i))


func _setup_pagination() -> void:
	pagination_bar.visible = false
	prev_button.pressed.connect(_on_prev_page_pressed)
	next_button.pressed.connect(_on_next_page_pressed)


func _create_highlight_style(bg_color: Color, border_color: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	return style


func _attach_highlight_frame(target: Control, style: StyleBoxFlat, inset: int = 0) -> Panel:
	var frame := Panel.new()
	frame.name = "HighlightFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = inset
	frame.offset_top = inset
	frame.offset_right = -inset
	frame.offset_bottom = -inset
	frame.add_theme_stylebox_override("panel", style)
	frame.visible = false
	target.add_child(frame)
	return frame


func _update_category_button_visuals() -> void:
	for cat_id in _category_buttons.keys():
		var button: TextureButton = _category_buttons[cat_id]
		var frame: Panel = _category_frames[cat_id]
		var is_active: bool = (cat_id == _current_category)
		button.modulate = CONFIG["category_active_modulate"] if is_active else CONFIG["category_inactive_modulate"]
		frame.visible = is_active


func _scan_category_images(folder_path: String, strict_accessory_slots: bool = false) -> Array[String]:
	var results: Array[String] = []
	var seen: Dictionary = {}
	var dir := DirAccess.open(folder_path)
	if dir == null:
		return results

	var supported: Array = CONFIG["supported_extensions"]
	var valid_prefixes := ", ".join(CONFIG["accessory_slots"].keys())

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and not file_name.begins_with("."):
			var clean_name := file_name
			if clean_name.ends_with(".import"):
				clean_name = clean_name.trim_suffix(".import")
			elif clean_name.ends_with(".remap"):
				clean_name = clean_name.trim_suffix(".remap")

			var ext := clean_name.get_extension().to_lower()
			if supported.has(ext):
				var full_path := folder_path.path_join(clean_name)
				if not seen.has(full_path):
					seen[full_path] = true
					if strict_accessory_slots and parse_accessory_slot(full_path).is_empty():
						push_warning(
							"Skipped accessory '%s': filename must follow <type>_<name>.png (valid types: %s)."
							% [clean_name, valid_prefixes]
						)
					else:
						results.append(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()

	results.sort()
	return results


func _load_texture(res_path: String) -> Texture2D:
	if _texture_cache.has(res_path):
		return _texture_cache[res_path]

	var tex: Texture2D = null
	if ResourceLoader.exists(res_path):
		tex = ResourceLoader.load(res_path) as Texture2D

	if tex == null:
		var abs_path := ProjectSettings.globalize_path(res_path)
		var image := Image.new()
		if image.load(abs_path) == OK:
			tex = ImageTexture.create_from_image(image)

	if tex != null:
		_texture_cache[res_path] = tex
	return tex


func _get_preview_texture(res_path: String) -> Texture2D:
	if _preview_cache.has(res_path):
		return _preview_cache[res_path]

	var tex := _load_texture(res_path)
	if tex == null:
		return null

	var image := tex.get_image()
	if image == null or image.is_empty():
		_preview_cache[res_path] = tex
		return tex

	var used_rect := image.get_used_rect()
	if not used_rect.has_area():
		_preview_cache[res_path] = tex
		return tex

	var pad: int = CONFIG["thumbnail_crop_padding"]
	var bounds := Rect2i(Vector2i.ZERO, image.get_size())
	var padded_rect := used_rect.grow(pad).intersection(bounds)

	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(padded_rect)
	_preview_cache[res_path] = atlas
	return atlas


func _format_item_tooltip(category_id: String, item_path: String) -> String:
	var base_name := item_path.get_file().get_basename()
	var category_cfg: Dictionary = _categories_by_id[category_id]
	if bool(category_cfg.get("strict_accessory_slots", false)):
		var slot_type := parse_accessory_slot(item_path)
		if not slot_type.is_empty():
			var item_label := base_name.substr(slot_type.length() + 1).replace("_", " ").capitalize()
			return "%s: %s" % [slot_type.capitalize(), item_label]
	return base_name.replace("_", " ").capitalize()


func _render_current_page() -> void:
	var slots_per_page: int = CONFIG["slots_per_page"]
	var total_items: int = _current_items.size()
	var total_pages: int = maxi(1, ceili(float(total_items) / float(slots_per_page)))
	_current_page = clampi(_current_page, 0, total_pages - 1)

	var start_index: int = _current_page * slots_per_page
	for i in range(_slot_buttons.size()):
		var button := _slot_buttons[i]
		var frame := _slot_frames[i]
		var item_index := start_index + i

		if item_index < total_items:
			var item_path := _current_items[item_index]
			button.texture_normal = _get_preview_texture(item_path)
			button.disabled = false
			button.mouse_filter = Control.MOUSE_FILTER_STOP
			button.tooltip_text = _format_item_tooltip(_current_category, item_path)
			frame.visible = _is_item_equipped(_current_category, item_path)
		else:
			button.texture_normal = null
			button.disabled = true
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.tooltip_text = ""
			frame.visible = false

	pagination_bar.visible = total_items > slots_per_page
	page_label.text = "%d / %d" % [_current_page + 1, total_pages]


func _on_prev_page_pressed() -> void:
	var slots_per_page: int = CONFIG["slots_per_page"]
	var total_pages: int = maxi(1, ceili(float(_current_items.size()) / float(slots_per_page)))
	if total_pages <= 1:
		return
	_current_page = (_current_page - 1 + total_pages) % total_pages
	_render_current_page()


func _on_next_page_pressed() -> void:
	var slots_per_page: int = CONFIG["slots_per_page"]
	var total_pages: int = maxi(1, ceili(float(_current_items.size()) / float(slots_per_page)))
	if total_pages <= 1:
		return
	_current_page = (_current_page + 1) % total_pages
	_render_current_page()


func _on_slot_pressed(slot_index: int) -> void:
	var item_index: int = _current_page * int(CONFIG["slots_per_page"]) + slot_index
	if item_index < 0 or item_index >= _current_items.size():
		return

	var item_path: String = _current_items[item_index]
	_toggle_outfit(_current_category, item_path)
	_render_current_page()


func _is_item_equipped(category_id: String, item_path: String) -> bool:
	var category_cfg: Dictionary = _categories_by_id[category_id]
	if bool(category_cfg.get("strict_accessory_slots", false)):
		var slot_type := parse_accessory_slot(item_path)
		if slot_type.is_empty():
			return false
		return _equipped_accessories.get(slot_type, "") == item_path
	return _equipped_single.get(category_id, "") == item_path


func _toggle_outfit(category_id: String, item_path: String) -> void:
	var category_cfg: Dictionary = _categories_by_id[category_id]
	if bool(category_cfg.get("strict_accessory_slots", false)):
		var slot_type := parse_accessory_slot(item_path)
		if slot_type.is_empty():
			return

		var current_acc_path: String = _equipped_accessories.get(slot_type, "")
		if current_acc_path == item_path:
			_set_item_sprite_visible(category_id, item_path, false)
			_equipped_accessories.erase(slot_type)
			return

		if not current_acc_path.is_empty():
			_set_item_sprite_visible(category_id, current_acc_path, false)

		_set_item_sprite_visible(category_id, item_path, true)
		_equipped_accessories[slot_type] = item_path
		return

	var current_path: String = _equipped_single.get(category_id, "")
	if current_path == item_path:
		_set_item_sprite_visible(category_id, item_path, false)
		_equipped_single.erase(category_id)
		return

	if not current_path.is_empty():
		_set_item_sprite_visible(category_id, current_path, false)

	_set_item_sprite_visible(category_id, item_path, true)
	_equipped_single[category_id] = item_path


func _set_item_sprite_visible(category_id: String, item_path: String, is_visible: bool) -> void:
	var sprite := _get_or_create_outfit_sprite(category_id, item_path)
	if sprite != null:
		sprite.visible = is_visible


func _get_or_create_outfit_sprite(category_id: String, item_path: String) -> Sprite2D:
	var category_cfg: Dictionary = _categories_by_id[category_id]
	var is_accessory := bool(category_cfg.get("strict_accessory_slots", false))

	if _preset_sprites.has(item_path):
		var preset: Sprite2D = _preset_sprites[item_path]
		if is_accessory:
			var slot_type := parse_accessory_slot(item_path)
			if not slot_type.is_empty():
				var slot_cfg: Dictionary = CONFIG["accessory_slots"][slot_type]
				if not bool(slot_cfg.get("under_clothes", false)):
					preset.z_index = int(slot_cfg["z_index"])
		else:
			preset.z_index = int(category_cfg["z_index"])
		return preset

	if _dynamic_sprites.has(item_path):
		return _dynamic_sprites[item_path]

	var tex := _load_texture(item_path)
	if tex == null:
		return null

	var sprite := Sprite2D.new()
	sprite.name = "Dynamic_%s_%s" % [category_id, item_path.get_file().get_basename()]
	sprite.texture = tex
	sprite.visible = false

	var is_full_canvas := (
		base_character.texture != null
		and tex.get_size() == base_character.texture.get_size()
	)

	if is_accessory:
		var slot_type := parse_accessory_slot(item_path)
		var slot_cfg: Dictionary = CONFIG["accessory_slots"].get(slot_type, {})
		if is_full_canvas or slot_cfg.is_empty():
			sprite.position = base_character.position
			sprite.scale = base_character.scale
		else:
			sprite.position = slot_cfg["position"]
			sprite.scale = slot_cfg["scale"]
		sprite.z_index = int(slot_cfg.get("z_index", category_cfg["z_index"]))
		character_preview.add_child(sprite)
		if bool(slot_cfg.get("under_clothes", false)):
			character_preview.move_child(sprite, base_character.get_index() + 1)
	else:
		sprite.position = base_character.position
		sprite.scale = base_character.scale
		sprite.z_index = int(category_cfg["z_index"])
		character_preview.add_child(sprite)

	_dynamic_sprites[item_path] = sprite
	return sprite

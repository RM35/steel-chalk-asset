extends TextureRect

export(Resource) var unit_type

var unit_name: String = "Default"
var health: int = 0
var attack: int = 0
var level: int = 0
var sprite_region_rect: Rect2

func _ready():
	unit_type = load("res://unit/unit_data/unit_skull.tres")
	unit_name = unit_type.unit_name
	health = unit_type.health
	attack = unit_type.attack
	level = unit_type.level
	sprite_region_rect = unit_type.sprite_region_rect
	update_card()

func update_card():
	$MC/VB/C/C/Sprite.region_rect = sprite_region_rect
	$MC/VB/MC2/C2/VB2/Name.text = unit_name
	$MC/VB/MC2/C2/VB2/Health.text = str(health)
	$MC/VB/MC2/C2/VB2/Attack.text = str(attack)
	$MC/VB/MC2/C2/VB2/Level.text = str(level)

func get_drag_data(drag_offset):
	var card_preview = self.duplicate()
	# This doesn't make sense but the rect must
	# be set to something other than 0, 0
	card_preview.rect_size = Vector2(1, 1) 
	card_preview.modulate.a = 0.3
	var preview = Control.new()
	preview.add_child(card_preview)
	card_preview.rect_position -= drag_offset
	set_drag_preview(preview)
	return self
	
func drop_data(vec2, variant):
	pass
	
func can_drop_data(vec2, variant):
	pass


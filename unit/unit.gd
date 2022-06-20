extends TextureRect

export(Resource) var unit_type = load("res://unit/unit_data/unit_skull.tres")

var unit_name: String = "Default"
var health: int = 0
var attack: int = 0
var level: int = 0
var rarity: int = 0
var sprite_region_rect: Rect2
enum SLOT_TYPE{PLAYER, SHOP, ENEMY, NONE}
export(SLOT_TYPE) var slot_type = SLOT_TYPE.NONE

func _ready():
	unit_name = unit_type.unit_name
	health = unit_type.health
	attack = unit_type.attack
	level = unit_type.level
	rarity = unit_type.rarity
	sprite_region_rect = unit_type.sprite_region_rect
	update_card()
	test_trig()

func update_card():
	$MC/VB/C/C/Sprite.region_rect = sprite_region_rect
	$MC/VB/MC2/C2/VB2/Name.text = unit_name
	$MC/VB/MC2/C2/VB2/Health.text = str(health)
	$MC/VB/MC2/C2/VB2/Attack.text = str(attack)
	$MC/VB/MC2/C2/VB2/Level.text = str(level)
	print(rarity)
	match rarity:
		1:
			self_modulate = Color(1.0, 0.5, 0.0)
		2: 
			self_modulate = Color(0.5, 0.5, 1.0)
		2: 
			self_modulate = Color(1.0, 0.5, 1.0)
		3: 
			self_modulate = Color(1.0, 1.0, 0.5)

# Dragging fucntions	
func get_drag_data(drag_offset):
	$AudioStreamPlayer.play()
	var card_preview = self.duplicate(0b0001) # instace flag only
	card_preview.set_process(false)
	card_preview.rect_size = Vector2(1, 1) 
	card_preview.modulate.a = 0.3
	var preview = Control.new()
	preview.add_child(card_preview)
	card_preview.rect_position -= drag_offset + self.rect_position
	set_drag_preview(preview)
	return self
	
func drop_data(vec2, variant):
	pass
	
func can_drop_data(vec2, variant):
	pass # Add card combinations and swapping here
		

# Ability triggers
func trig_on_sell():
	if unit_type.ability_trigger == 0:
		print("ON SELL TRIGGERED")
		ability_output(unit_type.ability_parameters)

func trig_on_buy():
	if unit_type.ability_trigger == 1:
		print("ON BUY TRIGGERED")
		ability_output(unit_type.ability_parameters)

func trig_on_faint():
	if unit_type.ability_trigger == 2:
		print("ON FAINT TRIGGERED")
		ability_output(unit_type.ability_parameters)
		
func trig_on_damage():
	if unit_type.ability_trigger == 3:
		print("ON DAMAGE TRIGGERED")
		ability_output(unit_type.ability_parameters)

func trig_on_attack():
	if unit_type.ability_trigger == 4:
		print("ON ATTACK TRIGGERED")
		ability_output(unit_type.ability_parameters)

# Ability outputs
func ability_output(value: int):
	match unit_type.ability_output:
		0:
			print("OUTPUT DAMAGE")
		1:
			print("OUTPUT HEALTH")
		2:
			print("OUTPUT CHANGE ATTACK")#
		3:
			print("OUTPUT CHANGE GOLD")
		4:
			print("OUTPUT SUMMON NEW")
		5:
			print("OUTPUT AOE DAMAGE")

# Debug/Dev Functions
func test_trig():
	trig_on_attack()
	trig_on_buy()
	trig_on_damage()
	trig_on_faint()
	trig_on_sell()

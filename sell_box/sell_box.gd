extends Panel

enum SLOT_TYPE{PLAYER, SHOP, ENEMY, NONE}
export(SLOT_TYPE) var slot_type = SLOT_TYPE.NONE

#/root/main/world should always exist but a better 
#way of connecting to the global player gold might
#be better
onready var world = get_node("/root/Main/World")

func _ready():
	pass 
	
func get_drag_data(drag_offset):
	pass
	
func drop_data(vec2, variant):
	#Add sell SFX to unit scene
	$SellSFX.play()
	world.player_gold += variant.cost
	variant.get_parent().remove_child(variant)
	variant.queue_free()
	
func can_drop_data(vec2, variant):
	#if game_state not idle then block dragging
	if world.game_state:
		return false
	#Allow selling only from player deck
	return variant.slot_type == 0 && (variant.cost <= world.player_gold)

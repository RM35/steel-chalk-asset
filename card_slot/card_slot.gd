extends Panel

enum SLOT_TYPE{PLAYER, SHOP, ENEMY, NONE}
export(SLOT_TYPE) var slot_type = SLOT_TYPE.NONE

func get_drag_data(drag_offset):
	pass
	
func drop_data(vec2, variant):
	#If empty allow drop. Cards should stop mouse from passing so
	#we shouldn't need to check for cards exisiting. Cards themselves
	#will deal with levelling up and swapping and SFX
	variant.get_node("DropSFX").play()
	variant.get_parent().remove_child(variant)
	$Control.add_child(variant)
	#Apply this slots type to the card
	variant.slot_type = slot_type
	
func can_drop_data(vec2, variant):
	#If we are dropping to a player slot allow the drop
	return !slot_type

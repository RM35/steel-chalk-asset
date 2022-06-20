extends Panel

enum SLOT_TYPE{PLAYER, SHOP, ENEMY}
export(SLOT_TYPE) var slot_type = 1

func get_drag_data(drag_offset):
	pass
	
func drop_data(vec2, variant):
	#Decide if we are swapping cards. Upgrading a card or filling an empty card slot
	$AudioStreamPlayer.play()
	variant.get_parent().remove_child(variant)
	$Control.add_child(variant)
	
func can_drop_data(vec2, variant):
	#If we are dropping to a player slot allow the drop
	return !slot_type

extends Panel

enum SLOT_TYPE{PLAYER, SHOP, ENEMY, NONE}
export(SLOT_TYPE) var slot_type = SLOT_TYPE.NONE

#/root/main/world should always exist but a better 
#way of connecting to the global player gold might
#be better
onready var world = get_node("/root/Main/World")

func get_drag_data(drag_offset):
	pass
	
func drop_data(vec2, variant):
	#Buying from shop to empty player slot if player_gold >= cost
	print("try drop")
	if variant.slot_type == SLOT_TYPE.SHOP && slot_type == SLOT_TYPE.PLAYER:
		print("buy")
		if world.player_gold >= variant.cost:
			world.player_gold -= variant.cost
			variant.get_node("BuySFX").play()
			variant.get_parent().remove_child(variant)
			$Control.add_child(variant)
			#Apply this slots type to the card
			variant.slot_type = slot_type
			
	#Player slot to an empty player slot swap
	if variant.slot_type == SLOT_TYPE.PLAYER && slot_type == SLOT_TYPE.PLAYER:
		variant.get_node("DropSFX").play()
		variant.get_parent().remove_child(variant)
		$Control.add_child(variant)
		#Apply this slots type to the card
		variant.slot_type = slot_type
	
func can_drop_data(vec2, variant):
	#If we are dropping to a player slot allow the drop
	return !slot_type

extends Control

#'Global' vars. Maybe move to an autoloaded singleton
var player_gold = 100
var game_level = 1
enum GAME_STATE{IDLE, BATTLE}
var game_state = GAME_STATE.IDLE

#Cards
onready var unit_scene = preload("res://unit/unit.tscn")
var card_types: Array = ["res://unit/unit_data/unit_lungs.tres",
						"res://unit/unit_data/unit_shield.tres",
						"res://unit/unit_data/unit_skull.tres",
						"res://unit/unit_data/unit_chicken.tres"]

#Decks
onready var enemy_deck = $VB/EnemyCards
onready var player_deck = $VB/PlayerCards
onready var shop_deck = $VB/ShopCards
var enemy_slots: Array
var player_slots: Array
var shop_slots: Array

#Generating new cards
export(Curve) var probability_curve: Curve
var rng = RandomNumberGenerator.new()

func get_rarity():
	rng.randomize()
	return round(probability_curve.interpolate(rng.randf()))

func _ready():
	for child in enemy_deck.get_children():
		if child.get_filename() == "res://card_slot/card_slot.tscn":
			enemy_slots.append(child)
	for child in player_deck.get_children():
		if child.get_filename() == "res://card_slot/card_slot.tscn":
			player_slots.append(child)
	for child in shop_deck.get_children():
		if child.get_filename() == "res://card_slot/card_slot.tscn":
			shop_slots.append(child)

func _process(delta):
	$Debug/Panel/VB/Level.text = "GAME LEVEL: " + str(game_level)
	$Debug/Panel/VB/Gold.text = "GOLD: " + str(player_gold)
	$Debug/Panel/VB/State.text = "STATE: " + str(game_state)


#Debug
func _on_Reroll_pressed():
	$RerollSFX.play()
	if player_gold >= 2:
		player_gold -= 2
		for node in shop_slots:
			if node.get_node("Control").get_child_count() != 0:
				node.get_node("Control").get_child(0).queue_free()
			#Equally random for now
			var unit = unit_scene.instance()
			rng.randomize()
			unit.unit_type = load(card_types[rng.randi_range(0, len(card_types) - 1)])
			#Set to shop slot
			unit.slot_type = 1
			node.get_node("Control").add_child(unit)

func _on_ClearTeam_pressed():
	for node in player_slots:
		if node.get_node("Control").get_child_count() != 0:
			node.get_node("Control").get_child(0).queue_free()

func _on_Button_pressed():
	game_state += 1
	game_state = game_state % 2

func _on_Battle_pressed():
	game_level = 1
	game_state = 1
	reroll_enemies()
	$MoveDelay.wait_time = 

func reroll_enemies():
	$RerollSFX.play()
	for node in enemy_slots:
		if node.get_node("Control").get_child_count() != 0:
			node.get_node("Control").get_child(0).queue_free()
		#Equally random for now
		var unit = unit_scene.instance()
		rng.randomize()
		unit.unit_type = load(card_types[rng.randi_range(0, len(card_types) - 1)])
		#Set to shop slot
		unit.slot_type = 2
		node.get_node("Control").add_child(unit)

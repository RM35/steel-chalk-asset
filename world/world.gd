extends Control

var player_gold = 100
var game_level = 1

#Cards
onready var unit_scene = preload("res://unit/unit.tscn")
var card_types: Array = ["res://unit/unit_data/unit_lungs.tres",
						"res://unit/unit_data/unit_shield.tres",
						"res://unit/unit_data/unit_skull.tres"]

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

func _on_Reroll_pressed():
	$RerollSFX.play()
	for node in shop_slots:
		if node.get_node("Control").get_child_count() != 0:
			node.get_node("Control").get_child(0).queue_free()
		#Equally random for now
		var unit = unit_scene.instance()
		rng.randomize()
		unit.unit_type = load(card_types[rng.randi_range(0, len(card_types) - 1)])
		node.get_node("Control").add_child(unit)

func _on_ClearTeam_pressed():
	for node in player_slots:
		if node.get_node("Control").get_child_count() != 0:
			node.get_node("Control").get_child(0).queue_free()

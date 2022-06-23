extends Control

#'Global' vars. Maybe move to an autoloaded singleton
var player_gold = 100
var game_level = 1
enum GAME_STATE{IDLE, BATTLE}
var game_state = GAME_STATE.IDLE
var move_delay = 0.5

#Cards
onready var unit_scene = preload("res://unit/unit.tscn")
var unit_data_path = "res://unit/unit_data/"
var card_types: Array = []

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
	load_unit_data()
	
func load_unit_data():
	var dir = Directory.new()
	var card_types_paths = []
	if dir.open(unit_data_path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				card_types_paths.append(unit_data_path + file_name)
			file_name = dir.get_next()
	# preload all card types
	for unit_type in card_types_paths:
		card_types.append(load(unit_type))

func _process(delta):
	$Debug/Panel/MarginContainer/VB/Level.text = "GAME LEVEL: " + str(game_level)
	$Debug/Panel/MarginContainer/VB/Gold.text = "GOLD: " + str(player_gold)
	$Debug/Panel/MarginContainer/VB/State.text = "STATE: " + str(game_state)

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
	reroll_enemies()
	if get_next_alive_enemy() && get_next_alive_player():
		#Start the battle
		game_level = 1
		game_state = 1
		move_delay = float($Debug/Panel/MarginContainer/VB/LineEdit.text)
		$MoveDelay.wait_time = move_delay
		$MoveDelay.start()

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

func get_next_alive_player():
	for node in player_slots:
		if node.get_node("Control").get_child_count() != 0:
			if node.get_node("Control").get_child(0).battle_health > 0:
				return node.get_node("Control").get_child(0)
	return false

func get_next_alive_enemy():
	for node in enemy_slots:
		if node.get_node("Control").get_child_count() != 0:
			if node.get_node("Control").get_child(0).battle_health > 0:
				return node.get_node("Control").get_child(0)
	return false

func end_battle():
	#Clear enemy deck
	for node in enemy_slots:
		if node.get_node("Control").get_child_count() != 0:
			node.get_node("Control").get_child(0).queue_free()
	#Set game_state to idle
	game_state = 0
	#Set all player deck to alive + full battle_health
	for node in player_slots:
		if node.get_node("Control").get_child_count() != 0:
			var unit = node.get_node("Control").get_child(0)
			unit.battle_health = unit.health
			unit.alive = true

#Main battle logic
func _on_MoveDelay_timeout():
	var enemy = get_next_alive_enemy()
	var player = get_next_alive_player()
	if !(enemy && player):
		end_battle()
		return
	enemy.battle_health -= player.attack
	player.battle_health -= enemy.attack
	enemy.play_attack_tween()
	player.play_attack_tween()
	if player.battle_health <= 0: player.alive = false
	if enemy.battle_health <= 0: enemy.alive = false

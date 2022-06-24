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
var card_types: Dictionary = {0:{}, 1:{}, 2:{}, 3:{}} #4 rarities
var card_chances: Dictionary = {1: [100, 0, 0, 0], 2: [100, 0, 0, 0],
	3: [75 ,100, 0, 0], 4: [55 ,85, 100, 0], 5: [45 , 77, 98, 100]}
var card_pools: Array = [30, 20, 15, 10]

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
	#preload all card types so they are not loaded on demand
	for unit_type in card_types_paths:
		var l_u_t = load(unit_type) # loaded_unit_type
		card_types[l_u_t.rarity][l_u_t.unit_name] = \
			{"res": l_u_t, "pool_count": card_pools[l_u_t.rarity]}

func _process(delta):
	$Debug/Panel/MarginContainer/VB/HB/Level.text = "GAME LEVEL: " + str(game_level)
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
			var unit = unit_scene.instance()
			rng.randomize()
			unit.unit_type = get_card()
			#Set to shop slot
			unit.slot_type = 1
			node.get_node("Control").add_child(unit)

func get_card():
	#First get rarity
	var rarity_roll = rng.randi_range(0, 99)
	var current_chances = card_chances[game_level]
	var _rarity = 0
	if rarity_roll <= current_chances[0] - 1:
		#Uncommon
		_rarity = 0
	elif rarity_roll <= current_chances[1] - 1:
		#Uncommon
		_rarity = 1
	elif rarity_roll <= current_chances[2] - 1:
		#Rare
		_rarity = 2
	elif rarity_roll <= current_chances[3] - 1:
		#Legend
		_rarity = 3
		
	#Build pool, doing this with array of all cards.
	var pool_cards = []
	for unit in card_types[_rarity]:
		for i in range(card_types[_rarity][unit]["pool_count"]):
			pool_cards.append(card_types[_rarity][unit])
	#Pick a card, any card
	return pool_cards[rng.randi_range(0, len(pool_cards) - 1)]["res"]
	
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
		unit.unit_type = get_card()
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
	trig_on_damage(player, "player")
	trig_on_damage(enemy, "enemy")
	enemy.play_attack_tween()
	player.play_attack_tween()
	trig_on_attack(player, "player")
	trig_on_attack(enemy, "enemy")
	if player.battle_health <= 0:
		trig_on_faint(player, "player")
		player.alive = false
	if enemy.battle_health <= 0:
		trig_on_faint(enemy, "enemy")
		enemy.alive = false

# Ability triggers
func trig_on_sell(unit, team):
	if unit.unit_type.ability_trigger == 0:
		ability_output(unit, unit.unit_type.ability_parameters)

func trig_on_buy(unit, team):
	if unit.unit_type.ability_trigger == 1:
		ability_output(unit, unit.unit_type.ability_parameters)

func trig_on_faint(unit, team):
	if unit.unit_type.ability_trigger == 2:
		ability_output(unit, unit.unit_type.ability_parameters)
		
func trig_on_damage(unit, team):
	if unit.unit_type.ability_trigger == 3:
		ability_output(unit, unit.unit_type.ability_parameters)

func trig_on_attack(unit, team):
	if unit.unit_type.ability_trigger == 4:
		ability_output(unit, unit.unit_type.ability_parameters)

# Ability outputs
func ability_output(unit, value: int):
	match unit.unit_type.ability_output:
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

func _on_LevelUp_pressed():
	game_level += 1

func _on_LevelDown_pressed():
	game_level -= 1

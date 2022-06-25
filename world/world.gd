extends Control

#'Global' vars. Maybe move to an autoloaded singleton
var player_gold = 10
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

#Debug
var debug_win_delay: float = 0

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
	debug_win_delay += delta
	$MainInfo/Level.text = "GAME LEVEL: " + str(game_level)
	$MainInfo/Gold.text = "GOLD: " + str(player_gold)
	if Input.is_action_pressed("debug") && debug_win_delay > 0.2:
		debug_win_delay = 0
		$Debug.visible = !$Debug.visible

#Debug
func _on_Reroll_pressed(free: bool = false):
	$RerollSFX.play()
	if free:
		player_gold + 2
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
	var current_chances = card_chances[clamp(game_level, 1, 5)]
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

func clear_shop():
	for node in shop_slots:
		if node.get_node("Control").get_child_count() != 0:
			node.get_node("Control").get_child(0).queue_free()

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
	$MoveDelay.stop()

#Main battle logic
func _on_MoveDelay_timeout():
	$MoveDelay.wait_time = move_delay
	var enemy = get_next_alive_enemy()
	var player = get_next_alive_player()
	if !enemy:
		end_battle()
		game_level += 1
		player_gold += 15
		_on_Reroll_pressed(true)
		return
	if !player:
		end_battle()
		game_level = 1
		player_gold = 10
		clear_shop()
		_on_Reroll_pressed(true)
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
		ability_output(unit, unit.unit_type.ability_parameters, team)

func trig_on_buy(unit, team):
	if unit.unit_type.ability_trigger == 1:
		ability_output(unit, unit.unit_type.ability_parameters, team)

func trig_on_faint(unit, team):
	if unit.unit_type.ability_trigger == 2:
		ability_output(unit, unit.unit_type.ability_parameters, team)
		
func trig_on_damage(unit, team):
	if unit.unit_type.ability_trigger == 3:
		ability_output(unit, unit.unit_type.ability_parameters, team)

func trig_on_attack(unit, team):
	if unit.unit_type.ability_trigger == 4:
		ability_output(unit, unit.unit_type.ability_parameters, team)

# Ability outputs
func ability_output(unit, value: int, team):
	$MoveDelay.wait_time += move_delay
	match unit.unit_type.ability_output:
		0:
			#Not implemented
			print("OUTPUT DAMAGE")
		1:
			#Heal next alive ally for now
			var deck = null
			if team == "player":
				deck = player_slots
			else:
				deck = enemy_slots
			for node in deck:
				if node.get_node("Control").get_child_count() != 0:
					if node.get_node("Control").get_child(0).battle_health > 0:
						if node.get_node("Control").get_child(0) != unit:
							node.get_node("Control").get_child(0).battle_health += value
		2:
			unit.attack += value
		3:
			if team == "player":
				player_gold += value
				$GoldSFX.play()
		4:
			#Not implemented
			print("OUTPUT SUMMON NEW")
		5:
			var deck = null
			if team == "player":
				deck = enemy_slots
			else:
				deck = player_slots
			for node in deck:
				if node.get_node("Control").get_child_count() != 0:
					var unit_node = node.get_node("Control").get_child(0)
					if unit_node.battle_health > 0:
						unit_node.battle_health -= value
						if unit_node.battle_health <= 0 && team == "enemy":
							trig_on_faint(unit_node, "player")
							unit_node.alive = false
						if unit_node.battle_health <= 0 && team == "player":
							trig_on_faint(unit_node, "enemy")
							unit_node.alive = false
	return false

func _on_LevelUp_pressed():
	game_level += 1

func _on_LevelDown_pressed():
	game_level -= 1


func _on_Button_pressed():
	end_battle()
	game_level = 1
	player_gold = 10
	_on_ClearTeam_pressed()
	clear_shop()
	_on_Reroll_pressed(true)

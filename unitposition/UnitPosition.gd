extends Position2D

onready var label: Label = $Label
var occupied = false

func _ready():
	label.text = name

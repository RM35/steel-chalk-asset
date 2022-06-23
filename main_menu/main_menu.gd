extends Control

func _on_PlayButton_pressed():
	get_tree().change_scene("res://main.tscn")

func _on_ExitButton_pressed():
	get_tree().quit()

func _on_PlayButton_focus_entered():
	$UISound.play()

func _on_ExitButton_focus_entered():
	$UISound.play()

func _on_PlayButton_mouse_entered():
	$UISound.play()

func _on_ExitButton_mouse_entered():
	$UISound.play()

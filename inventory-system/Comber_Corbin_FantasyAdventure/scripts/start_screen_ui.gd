extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_start_button_pressed() -> void:
	$ClickSound.play()
	await $ClickSound.finished
	get_tree().change_scene_to_file("res://Comber_Corbin_FantasyAdventure/scenes/Levels/MainGameLevel.tscn") # Replace with function body.


func _on_quit_button_pressed() -> void:
	$ClickSound.play()
	await $ClickSound.finished
	$QuitConfirmationDialog.popup_centered() # Replace with function body.


func _on_confirmation_dialog_confirmed() -> void:
	get_tree().quit() # Replace with function body.

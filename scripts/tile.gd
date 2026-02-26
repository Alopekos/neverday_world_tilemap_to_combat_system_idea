extends Node2D
var is_instantiated : bool = false

func play_anim()-> void:
	%AnimationPlayer.play("show_tile")
	await %AnimationPlayer.animation_finished
	is_instantiated = true

func play_anim_reversed()-> void:
	%AnimationPlayer.play_backwards("show_tile")
	await %AnimationPlayer.animation_finished

func _on_button_button_down() -> void:
	if is_instantiated:
		%AnimationPlayer.play("click_tile")


func _on_button_mouse_entered() -> void:
	if is_instantiated:
		%AnimationPlayer.play("click_tile")

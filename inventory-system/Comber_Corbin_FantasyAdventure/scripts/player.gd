extends CharacterBody2D


@export var iframe_duration: float = .6
@export var max_health: int = 100
@export var current_health: int 
@export var knockback_friction: float = 10.0
@export var speed = 30

@onready var animated_sprite = $AnimatedSprite2D
@onready var hurtbox: Hurtbox = $PlayerHurtbox
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D # Make sure this matches your

var knockback_velocity: Vector2 = Vector2.ZERO
var is_in_knockback: bool = false


var last_direction = "down"
var is_action_playing = false

signal health_changed(current_health, max_health)

func _ready() ->void:
	current_health = max_health
	health_changed.emit(current_health,max_health)
	# Connect the hurtbox signal directly to our take_damage
	hurtbox.damage_received.connect(_on_damage_received)
	
func _on_damage_received(hitbox: Hitbox) -> void:
	# Extract parameters from the incoming hitbox object
	take_damage(hitbox.damage)
	apply_knockback(hitbox.global_position,
	hitbox.knockback_force)

#health functions	
func take_damage(amount: int) -> void:
	current_health = clampi(current_health - amount, 0, max_health)
	health_changed.emit(current_health,max_health)
	
	# Activate the invincibility window on our hurtbox
	hurtbox.start_invincibility(iframe_duration)
	# Optional: Trigger visual feedback for I-Frames
	flash_sprite()
	
	if current_health <= 0:
		die()
func apply_knockback(source_position: Vector2, force: float) ->void:
# Calculate direction pointing from the threat directly to our player
	print(force)
	var knockback_direction = (global_position -source_position).normalized()
# If positions overlap exactly, push in a default direction to avoid vector zero errors
	if knockback_direction == Vector2.ZERO:
		knockback_direction = Vector2.DOWN
	knockback_velocity = knockback_direction * force
	is_in_knockback = true

func flash_sprite() -> void:
	# Create a quick visual flash using an inline tween
	var flash_tween = create_tween()
	# Drop opacity or change color briefly, then return to normal
	flash_tween.tween_property(sprite, "modulate:a", 0.4, iframe_duration / 4.0)
	flash_tween.tween_property(sprite, "modulate:a", 1.0, iframe_duration / 4.0)
	flash_tween.tween_property(sprite, "modulate:a", 0.4, iframe_duration / 4.0)
	flash_tween.tween_property(sprite, "modulate:a", 1.0, iframe_duration / 4.0)
	
func heal(amount: int) -> void:
	current_health = clampi(current_health + amount, 0, max_health)
	health_changed.emit(current_health,max_health)

func die() ->void:
	print("Player died")
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		take_damage(15)
	
func play_action_animation(action_name):
	is_action_playing = true
	animated_sprite.play(action_name + "_" + last_direction)
	
func _unhandled_input(event):
	if event.is_action_pressed("attack"):
		play_action_animation("attack")
	elif event.is_action_pressed("test_hit"):
		play_action_animation("hit")
	elif event.is_action_pressed("test_die"):
		play_action_animation("die")

func update_movement_animation(input_direction):
	if input_direction == Vector2.ZERO:
		animated_sprite.play("idle_" + last_direction)
	else:
		animated_sprite.play("run_" + last_direction)
		
func update_direction(input_direction):
	if input_direction.y < 0:
		last_direction = "up"
	elif input_direction.y > 0:
		last_direction = "down"
	elif input_direction.x < 0:
		last_direction = "left"
	elif input_direction.x > 0:
		last_direction = "right"
	
func _physics_process(delta: float) -> void:
	if is_in_knockback:
		# 1. Apply knockback movement
		velocity = knockback_velocity
		move_and_slide()
		# 2. Smoothly reduce knockback velocity over time using friction linear interpolation(lerp)
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * speed * delta)
		# 3. Restore control to the player once the velocitydrops close to zero
		if knockback_velocity.length() < 10.0:
			is_in_knockback = false
		# Get the input direction and handle the movement/deceleration
		# As good practice, you should replace UI actions with custom gameplay actions.
	else:
		var input_direction = Input.get_vector("move_left", "move_right", "move_up",
		"move_down")
		velocity = input_direction * speed
		update_direction(input_direction)
		if not is_action_playing:
			update_movement_animation(input_direction)
		move_and_slide()
	

func _on_animated_sprite_2d_animation_finished() -> void:
	is_action_playing = false

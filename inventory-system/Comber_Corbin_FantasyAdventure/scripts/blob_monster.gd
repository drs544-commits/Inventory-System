extends CharacterBody2D
#state machine
enum State { IDLE, PATROL, CHASE, ATTACK }
var current_state: State = State.IDLE

@export var walk_speed: float = 60.0
@export var chase_speed: float = 110.0

@export var patrol_radius: float = 150.0

# 2. State Pacing Variables
var target_player: CharacterBody2D = null
var patrol_target: Vector2 = Vector2.ZERO
var spawn_position: Vector2 = Vector2.ZERO
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var detector: Area2D = $PlayerDetector
@onready var hitbox: Hitbox = $BlobHitbox
@onready var patrol_timer: Timer = $PatrolTimer
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	spawn_position = global_position
	patrol_target = spawn_position
	# Connect detection signals
	detector.body_entered.connect(_on_player_entered)
	detector.body_exited.connect(_on_player_exited)
	patrol_timer.timeout.connect(_on_patrol_timer_timeout)
	# Turn off attack hitbox by default until in the attack state
	hitbox.get_node("CollisionShape2D").disabled = true
	enter_state(State.IDLE)
		
func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			process_idle_state(delta)
		State.PATROL:
			process_patrol_state(delta)
		State.CHASE:
			process_chase_state(delta)
		State.ATTACK:
			process_attack_state(delta)
	move_and_slide()

func enter_state(new_state: State) -> void:
	current_state = new_state
	# Reset states safely
	print(new_state)
	if current_state != State.ATTACK:
		hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			patrol_timer.start(randf_range(1.5, 3.0)) # Wait
		State.PATROL:
			generate_new_patrol_point()
		State.CHASE:
			patrol_timer.stop()
		State.ATTACK:
			velocity = Vector2.ZERO
			execute_blob_attack()
				
# --- BEHAVIOR 1: IDLE ---
func process_idle_state(_delta: float) -> void:
	# Code-driven Idle squish/breath effect
	var squish = 1.0 + (sin(Time.get_ticks_msec() * 0.005) * 0.05)
	sprite.scale = Vector2(1.0 + (1.0 - squish), squish)
	
# --- BEHAVIOR 2: PATROL ---
func process_patrol_state(_delta: float) -> void:
	# Procedural bounce movement animation for the blob
	var bounce = 1.0 + (abs(sin(Time.get_ticks_msec() * 0.01))* 0.15)
	sprite.scale = Vector2(bounce, 2.0 - bounce)
	if global_position.distance_to(patrol_target) < 15.0:
		enter_state(State.IDLE)
		return
	nav_agent.target_position = patrol_target
	if nav_agent.is_navigation_finished():
		enter_state(State.IDLE)
		return
	var next_path_pos = nav_agent.get_next_path_position()
	var dir = global_position.direction_to(next_path_pos).normalized()
	velocity = dir * walk_speed
	# Flip sprite asset based on traveling direction
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0


func generate_new_patrol_point() -> void:
	# Pick a random point within a localized circle around its home spawn point
	var random_offset = Vector2(randf_range(-1, 1),
	randf_range(-1, 1)).normalized() * randf_range(50.0,patrol_radius)
	patrol_target = spawn_position + random_offset
	
func _on_patrol_timer_timeout() -> void:
	if current_state == State.IDLE:
		enter_state(State.PATROL)



# --- BEHAVIOR 3: CHASE ---
func process_chase_state(_delta: float) -> void:
	if not target_player:
		enter_state(State.IDLE)
		return
	# Quick, intense bounce scale logic for visual aggression
	var angry_bounce = 1.0 + (abs(sin(Time.get_ticks_msec() * 0.02)) * 0.2)
	sprite.scale = Vector2(angry_bounce, 2.0 - angry_bounce)
	
	# Check if we are close enough to bite the player
	var distance_to_player =global_position.distance_to(target_player.global_position)
	if distance_to_player <= 90.0: # Melee threshold
		enter_state(State.ATTACK)
		return
		
	# Standard navigation path tracking toward live player vector coordinates
	nav_agent.target_position = target_player.global_position
	var next_path_pos = nav_agent.get_next_path_position()
	var dir =global_position.direction_to(next_path_pos).normalized()
	velocity = dir * chase_speed
	sprite.flip_h = velocity.x < 0

# --- BEHAVIOR 4: ATTACK ---
func process_attack_state(_delta: float) -> void:
	# Stay locked in place during attack script animations
	velocity = Vector2.ZERO
	
func execute_blob_attack() -> void:
	if not target_player:
		enter_state(State.IDLE)
		return
	# Direction vector towards the player
	var attack_dir =global_position.direction_to(target_player.global_position).normalized()
	# Juice up the attack visual using a clean, sequence code-tween
	var attack_tween = create_tween()
	# Wind-up squash (compression backwards)
	attack_tween.tween_property(sprite, "scale", Vector2(1.4,0.6), 0.15)
	# Sudden lunge stretch forward towards player and switch Hitbox collision ON
	attack_tween.tween_callback(func():
		hitbox.get_node("CollisionShape2D").disabled = false
		# Briefly slide toward player manually during lunge
		var lunge_tween = create_tween()
		lunge_tween.tween_property(self, "global_position", global_position + (attack_dir * 25.0), 0.1)
	)
	attack_tween.tween_property(sprite, "scale", Vector2(0.6,1.4), 0.1)
	# Recovery: Turn hitbox OFF and settle scale frame back to normal size
	attack_tween.tween_interval(0.15)
	attack_tween.tween_callback(func():
		hitbox.get_node("CollisionShape2D").disabled = true)
	attack_tween.tween_property(sprite, "scale", Vector2(1.0,1.0), 0.2)
	# Complete attack sequence wrap-up and re-evaluate situational state criteria
	attack_tween.tween_callback(func():
		if target_player:
			enter_state(State.CHASE)
		else:
			enter_state(State.IDLE)
	)
# 4. Sensor Collision Callback Routines
func _on_player_entered(body: Node2D) -> void:
	print("RAN")
	if body.is_in_group("Player"):
		target_player = body as CharacterBody2D
		if current_state != State.ATTACK:
			enter_state(State.CHASE)
		
func _on_player_exited(body: Node2D) -> void:
	if body == target_player:
		target_player = null
		if current_state != State.ATTACK:
			enter_state(State.IDLE)
		

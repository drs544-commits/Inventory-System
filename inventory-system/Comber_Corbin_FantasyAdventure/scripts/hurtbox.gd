class_name Hurtbox
extends Area2D

# Signal to notify the parent character that they were hit
signal damage_received(hitbox: Hitbox)

# State to track if the entity is currently safe from damage
var is_invincible: bool = false
var iframe_timer: Timer

func _init() -> void:
	# Configure this area strictly to be detected
	monitoring = false
	monitorable = true
	
func _ready() -> void:
	# Connect to Area2D's internal signal for when an area
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	_setup_iframe_timer()



func _setup_iframe_timer() -> void:
# Build the timer dynamically so you don't have to manually add it in the editor
	iframe_timer = Timer.new()
	iframe_timer.one_shot = true
	add_child(iframe_timer)
	# When the timer runs out, turn invincibility off
	iframe_timer.timeout.connect(_on_iframe_timer_timeout)
	
func _on_area_entered(incoming_area: Area2D) -> void:
	# Ignore all incoming attacks if we are currently invincible
	if is_invincible:
		return
	if incoming_area is Hitbox:
		var hitbox = incoming_area as Hitbox
		damage_received.emit(hitbox)
		
func start_invincibility(duration: float) -> void:
	if duration <= 0.0:
		return
	is_invincible = true
	# Set deferred ensures the physics engine safely updates collision states between frames
	set_deferred("monitorable", false)
	iframe_timer.start(duration)
	
func _on_iframe_timer_timeout() -> void:
	is_invincible = false
	set_deferred("monitorable", true)

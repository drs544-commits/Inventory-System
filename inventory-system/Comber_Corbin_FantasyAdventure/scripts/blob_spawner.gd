
extends Node2D
# 1. Configuration Exports
@export var blob_scene: PackedScene # Drag and drop BlobMonster.tscn here
@export var spawn_cooldown: float = 4.0 # Time between spawn attempts (inseconds)
@export var max_blobs_alive: int = 5 # Absolute population cap for this spawner
# 2. Tracking Properties
var spawn_points: Array[Marker2D] = []
var active_blobs: Array[CharacterBody2D] = []
@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
# 1. Automatically harvest all child Marker2D nodes
	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child)
# If no markers were added, fallback to using the spawner's root position
	if spawn_points.is_empty():
		var default_marker = Marker2D.new()
		add_child(default_marker)
		spawn_points.append(default_marker)
	# 2. Initialize and kick off our tracking clock loop
	spawn_timer.wait_time = spawn_cooldown
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()
	
func _on_spawn_timer_timeout() -> void:
	# 3. Clean up the array by removing any blobs that were killed/freed
	active_blobs = active_blobs.filter(func(blob): return is_instance_valid(blob))
	# 4. Enforce the population threshold rule
	31
	if active_blobs.size() >= max_blobs_alive:
		return # Map is full, skip this clock cycle safely
	if blob_scene:
		spawn_new_blob()

func spawn_new_blob() -> void:
	# 5. Pick a completely random marker location from our gathered list
	var random_marker = spawn_points.pick_random()
	# 6. Instance the scene into system memory
	var new_blob = blob_scene.instantiate() as CharacterBody2D
	# 7. Match its transform positioning coordinates to the chosen
	marker
	new_blob.global_position = random_marker.global_position
	# 8. Append to tracking list and add it directly into the active level tree
	active_blobs.append(new_blob)
	get_parent().add_child.call_deferred(new_blob)
	# Optional: Give it a visual spawn flash effect
	trigger_spawn_juice(new_blob)
	
func trigger_spawn_juice(target_blob: CharacterBody2D) -> void:
# Reach into the blob's node tree to access its sprite
var blob_sprite = target_blob.get_node_or_null("Sprite2D")
if blob_sprite:
# Flash it clear white/blue and pop its size out dynamically
as it emerges
var spawn_tween = create_tween()
blob_sprite.scale = Vector2.ZERO
spawn_tween.tween_property(blob_sprite, "scale", Vector2(1.3,
1.3), 0.15)
32
spawn_tween.tween_property(blob_sprite, "scale", Vector2(1.0,
1.0), 0.1)

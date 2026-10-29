class_name Hitbox
extends Area2D


@export var damage: int = 10
@export var knockback_force: float = 300

func _init() -> void:
	# Configure this area strictly for offensive scanning
	monitoring = true
	monitorable = false
	
func _ready()-> void:
	area_entered.connect(_area_entered)


func _area_entered(area: Area2D) -> void:
		if area is Hurtbox:
			area.damage_received.emit(self)

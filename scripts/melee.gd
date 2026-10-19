extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$melee_hit.start()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass





func _on_melee_hit_timeout() -> void:
	queue_free()




func _touching_enemy(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		body.take_damage()
		queue_free()

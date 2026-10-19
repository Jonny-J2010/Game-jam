extends Area2D
var speed = randi_range(800,900)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move_local_x(speed*delta)
	$AnimatedSprite2D.play("default")




func _collides(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		body.take_damage()
		queue_free()

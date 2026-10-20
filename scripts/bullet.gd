extends Area2D
var speed = randi_range(800,900)

# --- PARRY: new variables ---
var shooter = null        # the enemy that fired this bullet (the enemy's shoot() sets it). Stays null for the player's own bullets.
var from_enemy = false    # true for enemy bullets (they hurt the player), false for the player's bullets (they hurt enemies)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# PARRY: the enemy sets "shooter" before adding the bullet to the scene, so it is already set here.
	# Working it out once now means it still works if the enemy dies while the bullet is in the air.
	from_enemy = shooter != null


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move_local_x(speed*delta)
	$AnimatedSprite2D.play("default")




func _collides(body: Node2D) -> void:
	# PARRY: an enemy bullet hits the player through take_hit(), so the player's parry can catch it
	if from_enemy:
		if body.is_in_group("player"):
			body.take_hit(1, self)
			queue_free()
	elif body.is_in_group("enemy"):
		body.take_damage()
		queue_free()


# PARRY: called by the player when the parry works. Stuns the enemy that fired the bullet.
func get_parried() -> void:
	if is_instance_valid(shooter):
		shooter.get_parried()
	queue_free()

extends CharacterBody2D
var direction
@export var player = CharacterBody2D
@export var health_ui = ProgressBar
@export var bullet_scene = PackedScene
@export var bullet_right_spawn = Marker2D
@export var bullet_left_spawn = Marker2D
const SPEED = 400.0
const JUMP_VELOCITY = -400.0
var jumping = false
var running = false
var facing
var health = 5
var is_dead = false
var player_in_sight
var player_in_range
var keep_moving = false
var safe = true
var right_jump = false
var left_jump = false
var in_range
var shot_fired = false



func _physics_process(delta: float) -> void:
	if not is_on_floor():
		jumping = true
		velocity += get_gravity() * delta
	if is_dead == false:

		if player_in_sight and not player_in_range and safe:
			var relative_position = player.global_position - global_position
			if relative_position.x < 0:
				direction = -1

			elif relative_position.x > 0:
				direction = 1

		elif player_in_range and player_in_sight and keep_moving == false and safe:
			var relative_position = player.global_position - global_position
			if relative_position.x < 0:
				direction = 1
			elif relative_position.x > 0:
				direction = -1

		elif not safe and right_jump and keep_moving:
			direction = 1
		elif not safe and left_jump and keep_moving:
			direction = -1


		else:
			direction = 0
			in_range = true
			# Add the gravity.


		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.

		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		move_and_slide()



func _ready() -> void:
	health_ui.min_value = 0
	health_ui.max_value = health
	health_ui.value = health

func _process(delta):

	if is_on_floor():
		safe = true
	health_ui.value = health

	if is_dead == false:
		if player_in_sight and $right_jump.is_colliding() and $left_jump.is_colliding() and velocity.x == 0:
			jump()

		if not $right_jump.is_colliding() and direction == 1:
			jump()
			right_jump = true
		elif not $left_jump.is_colliding() and direction == -1:
			jump()
			left_jump = true

		if not $right_jump.is_colliding() and not $left_jump.is_colliding() and not is_on_floor():
			safe = false
		if safe == true:
			right_jump = false
			left_jump = false




	#controls idle animation
		if not jumping and not running:
			$AnimatedSprite2D.play("idle")
		if is_on_floor():
			jumping = false
		if jumping:
			$AnimatedSprite2D.play("jump")


	#controls running animation
		if (velocity.x > 0 or velocity.x < 0) and not jumping:
			running = true
			$AnimatedSprite2D.play("run")
		else:
			running = false

	#controls the direction that the player is facing

		if direction:
			if direction == 1:
				$AnimatedSprite2D.flip_h = 0   #FACING RIGHT
				facing = "right"
			elif direction == -1:
				$AnimatedSprite2D.flip_h = 1   #FACING LEFT
				facing = "left"


func take_damage() -> void:
	if is_dead:
		return
	health -=1
	if health <= 0:
		health = 0
		is_dead = true
		player.add_score()
		$AnimatedSprite2D.play("dead")
		$Timer.start()






func jump() -> void:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
		jumping = true









func _player_in_sight(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_sight = true


func _player_out_of_sight(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_sight = false


func _death_animation_over() -> void:
	queue_free()



func _non_shooting_range_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _non_shooting_range_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false



func stay_moving() -> void:
	keep_moving = true
func stop_moving() -> void:
	keep_moving = false







func shoot() -> void:
	if shot_fired:
		return
	var bullet

	if facing == "right":
		bullet.global_position = bullet_right_spawn.global_position
		bullet.rotation = 0


	elif facing == "left":
		bullet.global_position = bullet_left_spawn.global_position
		bullet.rotation = deg_to_rad(180)


	add_sibling(bullet)
	shot_fired = true

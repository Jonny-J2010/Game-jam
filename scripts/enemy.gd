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

# --- PARRY: new variables ---
@export var stagger_time = 1.2              # seconds the enemy is stunned after its bullet gets parried
@export var stagger_damage_multiplier = 3   # damage you deal is multiplied by this while it is stunned
var staggered = false                       # true while the enemy is stunned
var stagger_timer = 0.0                     # seconds of stun left



func _physics_process(delta: float) -> void:
	if not is_on_floor():
		jumping = true
		velocity += get_gravity() * delta
	if is_dead == false:

		# PARRY: while staggered the enemy just stands still (gravity above still applies)
		if staggered:
			stagger_timer -= delta
			velocity.x = move_toward(velocity.x, 0, SPEED)
			move_and_slide()
			if stagger_timer <= 0.0:
				_end_stagger()
			return

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

	# PARRY: while staggered, skip the jump / animation / facing code below
	if staggered:
		return

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


# PARRY: "amount = 1" means your existing take_damage() calls still work with no number
func take_damage(amount = 1) -> void:
	if is_dead:
		return
	# PARRY: hits land harder while the enemy is staggered
	if staggered:
		amount *= stagger_damage_multiplier
	health -= amount
	if health <= 0:
		health = 0
		is_dead = true
		staggered = false                        # PARRY: so the death animation plays normally
		$AnimatedSprite2D.modulate = Color.WHITE
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
	if shot_fired or staggered:   # PARRY: no shooting while staggered
		return
	var bullet = bullet_scene.instantiate()   # PARRY: this line was missing, so bullet was null and shoot() would crash
	bullet.set("shooter", self)   # PARRY: lets the bullet tell this enemy when it gets parried

	if facing == "right":
		bullet.global_position = bullet_right_spawn.global_position
		bullet.rotation = 0


	elif facing == "left":
		bullet.global_position = bullet_left_spawn.global_position
		bullet.rotation = deg_to_rad(180)


	add_sibling(bullet)
	shot_fired = true



# ---------------- PARRY ----------------

# Called by the bullet when the player parries it (see the bullet snippet).
func get_parried() -> void:
	if is_dead:
		return
	staggered = true
	stagger_timer = stagger_time
	direction = 0
	running = false
	$AnimatedSprite2D.modulate = Color(1.0, 1.0, 0.3)   # yellow = stunned, hit it now for bonus damage
	# Plays a "stagger" animation if you've made one in your AnimatedSprite2D, otherwise idle + yellow tint.
	if $AnimatedSprite2D.sprite_frames.has_animation("stagger"):
		$AnimatedSprite2D.play("stagger")
	else:
		$AnimatedSprite2D.play("idle")


func _end_stagger() -> void:
	staggered = false
	$AnimatedSprite2D.modulate = Color.WHITE

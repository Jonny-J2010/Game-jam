extends CharacterBody2D
var direction
@export var player: CharacterBody2D
@export var health_ui: ProgressBar
@export var meele_cooldown: float = 0.8
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
var meele_cooldown_left: float = 0.0

# --- MELEE: new variables ---
@export var melee_range = 70.0     # distance (pixels) at which the enemy stops, stops jumping and attacks. Tune this!
@export var melee_damage = 1       # damage dealt to the player per hit
@export var player_damage_method: StringName = "take_damage"   # name of the function on your PLAYER script that removes health
@export var meele_scene: PackedScene   # drag your meele scene (an Area2D with a CollisionShape2D) in here
@export var melee_windup = 0.3     # seconds between starting the swing and the hitbox appearing
@export var melee_active_time = 0.15   # seconds the hitbox stays active
@export var melee_offset = 40.0    # how far in front of the enemy the hitbox appears (pixels)
var attacking = false              # true while a swing is in progress
var hit_landed = false             # makes sure one swing only hurts the player once

# --- PARRY variables ---
@export var stagger_time = 1.2              # seconds the enemy is stunned after being parried
@export var stagger_damage_multiplier = 3   # damage you deal is multiplied by this while it is stunned
var staggered = false                       # true while the enemy is stunned
var stagger_timer = 0.0                     # seconds of stun left



func _physics_process(delta: float) -> void:
	if not is_on_floor():
		jumping = true
		velocity += get_gravity() * delta

	if is_dead:
		return

	# MELEE: count the attack cooldown down
	if meele_cooldown_left > 0.0:
		meele_cooldown_left -= delta

	# Stagger: enemy cannot move while stunned
	if staggered:
		stagger_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		move_and_slide()

		if stagger_timer <= 0.0:
			_end_stagger()

		return

	# Chase the player regardless of distance
	if player_in_sight:
		var relative_position = player.global_position - global_position

		if relative_position.x < 0:
			direction = -1
		elif relative_position.x > 0:
			direction = 1
		else:
			direction = 0

	# Keep existing jumping movement behaviour
	elif not safe and right_jump and keep_moving:
		direction = 1

	elif not safe and left_jump and keep_moving:
		direction = -1

	else:
		direction = 0

	# MELEE: when close enough (or mid-swing) stop moving, face the player and attack
	if player_in_sight and (attacking or _player_close()):
		direction = 0
		if not attacking:
			_face_player()
			if meele_cooldown_left <= 0.0:
				melee_attack()

	# Apply horizontal movement
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	move_and_slide()



func _ready() -> void:
	health_ui.min_value = 0
	health_ui.max_value = health
	health_ui.value = health

func _process(delta):

	if is_on_floor():
		safe = true
	health_ui.value = health

	# While staggered or swinging, skip the jump / animation / facing code below
	if staggered or attacking:
		return

	if is_dead == false:
		# MELEE: never jump while the player is within melee range
		# (this was the bug: pressing against the player made velocity.x == 0, which triggered the jump)
		if player_in_sight and not _player_close() and $right_jump.is_colliding() and $left_jump.is_colliding() and velocity.x == 0:
			jump()

		if not player_in_range and not _player_close():
			if not $right_jump.is_colliding() and direction == 1 and is_on_floor():
				jump()
				right_jump = true
			elif not $left_jump.is_colliding() and direction == -1 and is_on_floor():
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


func take_damage(amount = 1) -> void:
	if is_dead:
		return
	# hits land harder while the enemy is staggered
	if staggered:
		amount *= stagger_damage_multiplier
	health -= amount
	if health <= 0:
		health = 0
		is_dead = true
		staggered = false
		attacking = false
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



# ---------------- MELEE ----------------

# True when the player is within melee_range of the enemy.
func _player_close() -> bool:
	return is_instance_valid(player) and global_position.distance_to(player.global_position) <= melee_range


# Turn to face the player (used when the enemy has stopped moving).
func _face_player() -> void:
	if player.global_position.x < global_position.x:
		facing = "left"
		$AnimatedSprite2D.flip_h = true
	else:
		facing = "right"
		$AnimatedSprite2D.flip_h = false


func melee_attack() -> void:
	attacking = true
	meele_cooldown_left = meele_cooldown

	# Plays an "attack" animation if you've made one in your AnimatedSprite2D, otherwise idle.
	if $AnimatedSprite2D.sprite_frames.has_animation("attack"):
		$AnimatedSprite2D.play("attack")
	else:
		$AnimatedSprite2D.play("idle")

	# Windup: gives the player a moment to react / parry before the hit lands
	await get_tree().create_timer(melee_windup).timeout

	# Swing is cancelled if the enemy died or got parried during the windup
	if is_dead or staggered:
		attacking = false
		return

	# Spawn the meele scene in front of the enemy as the hitbox
	hit_landed = false
	if meele_scene:
		var hitbox = meele_scene.instantiate()

		# Works with a plain duplicate of your meele scene, no editor changes needed:
		# 1) if the duplicate still has the old script, switch it off so only THIS script deals damage
		if hitbox.get_script() != null:
			for connection in hitbox.body_entered.get_connections():
				hitbox.body_entered.disconnect(connection["callable"])
			hitbox.set_script(null)
		# 2) make the hitbox only detect the player's physics layer (and not sit on any layer itself)
		hitbox.collision_layer = 0
		hitbox.collision_mask = player.collision_layer
		# 3) make sure the hitbox is actually switched on (hitbox scenes are often saved with the
		#    shape disabled, because the old script turned it on during an attack)
		hitbox.monitoring = true
		for shape in hitbox.find_children("*", "CollisionShape2D", true, false):
			shape.disabled = false

		var side = 1 if facing == "right" else -1
		hitbox.position = Vector2(melee_offset * side, 0)
		hitbox.scale.x = side   # mirrors the hitbox (and any sprite in it) when facing left
		add_child(hitbox)
		hitbox.body_entered.connect(_on_meele_hit)

		# Hitbox stays active briefly, then disappears
		await get_tree().create_timer(melee_active_time).timeout
		if is_instance_valid(hitbox):
			hitbox.queue_free()
	else:
		push_warning("meele_scene is empty - drag your enemy meele scene into the enemy's Inspector")

	attacking = false


# Called when something enters the meele hitbox.
func _on_meele_hit(body: Node2D) -> void:
	print("meele hitbox touched: ", body.name, "  groups: ", body.get_groups())   # DEBUG - delete once it works
	if hit_landed or is_dead or staggered:
		return
	if not body.is_in_group("player"):
		return
	if body.has_method(player_damage_method):
		hit_landed = true
		body.call(player_damage_method, melee_damage)
	else:
		push_warning("Player has no function called '" + str(player_damage_method) + "'. Set 'Player Damage Method' on the enemy to your player's damage function name.")



# ---------------- PARRY ----------------

# Call this when the player successfully parries the enemy's melee swing.
func get_parried() -> void:
	if is_dead:
		return
	staggered = true
	attacking = false
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

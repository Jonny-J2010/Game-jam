extends CharacterBody2D

const SPEED = 500
const JUMP_VELOCITY = -500


var running = false
var jumping = false
var shooting = false
var hitting = false
var direction
var shot_fired = true
var facing = "right"
var just_hit = true
var rjsh = [0,0,0,0]
var score = 0
var ammo = 20
var hello = 0

# --- PARRY: new variables ---
@export var parry_window = 0.2     # seconds after pressing parry when a hit counts as a parry
@export var parry_recovery = 0.4   # seconds you are stuck after a missed parry (stops button mashing)
@export var parry_buffer = 0.1     # a press this close to the end of recovery is remembered
var parrying = false               # true during the parry window
var parry_recovering = false       # true after a missed parry
var parry_timer = 0.0              # seconds left in the current parry phase
var parry_buffer_timer = 0.0       # seconds left on a remembered parry press
var health = 5                     # placeholder health so you can see hits land (replace with your own)

@export var player = CharacterBody2D
@export var bullet_right_spawn: Marker2D
@export var bullet_left_spawn: Marker2D
@export var bullet_scene: PackedScene
@export var ammo_label: Label
@export var melee_scene: PackedScene




# PARRY: creates the "parry" input (Q key) if you haven't added it in Project Settings > Input Map.
# Once you've added your own "parry" action there, this does nothing and you can delete it.
func _ready() -> void:
	if not InputMap.has_action("parry"):
		InputMap.add_action("parry")
		var key_event := InputEventKey.new()
		key_event.physical_keycode = KEY_Q
		InputMap.action_add_event("parry", key_event)


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and not shooting and not parrying and not parry_recovering:
		velocity.y = JUMP_VELOCITY
		jumping = true
	if not is_on_floor():
		jumping = true


	var direction := Input.get_axis("go_left", "go_right")
	if parrying or parry_recovering:
		velocity.x = move_toward(velocity.x, 0, SPEED)   # PARRY: plant your feet while parrying
	elif direction:
		velocity.x = direction * SPEED



	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func _process(delta):
	ammo_label.text = str(ammo)

	# PARRY: while parrying, skip all the animation / shooting / melee code below
	if _handle_parry(delta):
		return


#controls idle animation
	if not jumping and not running and not shooting and not hitting:
		$AnimatedSprite2D.play("idle")
	if is_on_floor():
		jumping = false
	if jumping and not shooting and not hitting:
		$AnimatedSprite2D.play("jump")


#controls running animation
	if Input.is_action_pressed("go_left") and not jumping and not shooting and not hitting:
		running = true
		$AnimatedSprite2D.play("run")
	elif Input.is_action_pressed("go_right") and not jumping and not shooting and not hitting:
		running = true
		$AnimatedSprite2D.play("run")
	else:
		running = false

#controls the direction that the player is facing
	var direction := Input.get_axis("go_left", "go_right")
	if direction:
		if direction == 1:
			$AnimatedSprite2D.flip_h = 0   #FACING RIGHT
			facing = "right"
		elif direction == -1:
			$AnimatedSprite2D.flip_h = 1   #FACING LEFT
			facing = "left"


	if Input.is_action_just_pressed("shoot") and not running and not jumping and not hitting and not Input.is_action_pressed("go_left") and not Input.is_action_pressed("go_right") and ammo > 0:
		shooting = true
		$AnimatedSprite2D.play("shoot")
		$Timer.start()
		shot_fired = false
	elif Input.is_action_just_pressed("shoot") and not running and jumping and not hitting and ammo > 0:
		shooting = true
		$AnimatedSprite2D.play("jump_shoot")
		$Timer.start()
		shot_fired = false

	elif Input.is_action_just_pressed("shoot") and running and not jumping and not hitting and ammo > 0:
		shooting = true
		$AnimatedSprite2D.play("run_shoot")
		$Timer.start()
		shot_fired = false


	elif Input.is_action_just_pressed("melee") and not running and not jumping and not shooting and not hitting:
		$AnimatedSprite2D.play("hit")
		hitting = true
		just_hit = false


	if $AnimatedSprite2D.frame == 0 and shot_fired == false:
		if shot_fired:
			return
		var bullet = bullet_scene.instantiate()
		ammo -=1

		if facing == "right":
			bullet.global_position = bullet_right_spawn.global_position
			bullet.rotation = 0


		elif facing == "left":
			bullet.global_position = bullet_left_spawn.global_position
			bullet.rotation = deg_to_rad(180)


		add_sibling(bullet)
		shot_fired = true
	if $AnimatedSprite2D.frame == 0 and just_hit == false:
		var melee = melee_scene.instantiate()

		if facing == "right":
			melee.global_position = bullet_right_spawn.global_position

		elif facing == "left":
			melee.global_position = bullet_left_spawn.global_position

		add_sibling(melee)
		just_hit = true
		$Timer2.start()





func _shoot_animation_end() -> void:
	if $AnimatedSprite2D.animation == "shoot" or "jump_shoot" or "run_shoot":
		shooting = false




func _melee_animation_end() -> void:
	if $AnimatedSprite2D.animation == "hit":
		hitting = false



func add_score() -> void:
	score += 1
	print(score)



# ---------------- PARRY ----------------

# Runs every frame from _process. Returns true while the player is locked into a parry.
func _handle_parry(delta) -> bool:
	parry_timer -= delta
	parry_buffer_timer -= delta

	if Input.is_action_just_pressed("parry"):
		if parry_recovering:
			parry_buffer_timer = parry_buffer   # remember the press so it fires when recovery ends
		elif not parrying and not shooting and not hitting:
			_start_parry()

	if parrying and parry_timer <= 0.0:
		# Nothing hit us during the window, so the parry missed.
		parrying = false
		parry_recovering = true
		parry_timer = parry_recovery
	elif parry_recovering and parry_timer <= 0.0:
		parry_recovering = false
		$AnimatedSprite2D.modulate = Color.WHITE
		if parry_buffer_timer > 0.0:
			_start_parry()

	return parrying or parry_recovering


func _start_parry() -> void:
	parrying = true
	parry_recovering = false
	parry_timer = parry_window
	parry_buffer_timer = 0.0
	running = false
	# Plays a "parry" animation if you've made one in your AnimatedSprite2D, otherwise just tints blue.
	if $AnimatedSprite2D.sprite_frames.has_animation("parry"):
		$AnimatedSprite2D.play("parry")


# Enemies and enemy bullets should call this instead of hurting the player directly:
#     body.take_hit(1, self)
func take_hit(damage: int, attacker: Node) -> void:
	if parrying:
		_on_parry_success(attacker)
		return

	# Not parried: placeholder damage. Replace with your own damage / game over code.
	health -= damage
	print("Player health: ", health)
	$AnimatedSprite2D.modulate = Color.RED
	create_tween().tween_property($AnimatedSprite2D, "modulate", Color.WHITE, 0.2)
	if health <= 0:
		get_tree().reload_current_scene.call_deferred()


func _on_parry_success(attacker: Node) -> void:
	print("Parried!")
	parrying = false
	parry_recovering = false
	parry_timer = 0.0
	parry_buffer_timer = 0.0 
	create_tween().tween_property($AnimatedSprite2D, "modulate", Color.WHITE, 0.25)
	if attacker.has_method("get_parried"):
		attacker.get_parried()   # the enemy / bullet decides what being parried does
	_hitstop(0.08)


# Briefly freezes the game for impact. The timer ignores time_scale, otherwise it would run slowed too.
func _hitstop(duration: float) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

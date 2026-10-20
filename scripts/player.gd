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


@export var player = CharacterBody2D
@export var bullet_right_spawn: Marker2D
@export var bullet_left_spawn: Marker2D
@export var bullet_scene: PackedScene
@export var ammo_label: Label
@export var melee_scene: PackedScene




func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and not shooting:
		velocity.y = JUMP_VELOCITY
		jumping = true
	if not is_on_floor():
		jumping = true


	var direction := Input.get_axis("go_left", "go_right")
	if direction:
		velocity.x = direction * SPEED



	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func _process(delta):
	ammo_label.text = str(ammo)


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

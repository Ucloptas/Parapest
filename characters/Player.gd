extends CharacterBody2D

const SPEED = 400.0
const JUMP_FORCE = -500.0
const GRAVITY = 300.0
@onready var anim:AnimationPlayer=$Animations
@onready var sprites = $AnimationSprites
var current_anim

var is_jumping = false
var is_falling = false
var is_sprinting = false
var can_move = true

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	#get horizontal input direction: -1, 0, 1 // left, neutral, right
	
	var input_dir_h = Input.get_axis("ui_left", "ui_right")
	if can_move:
		velocity.x = input_dir_h * SPEED

	#sprite horizontal flip
	if input_dir_h > 0 && can_move:
		sprites.flip_h=false
	elif input_dir_h < 0 && can_move:
		sprites.flip_h=true
	
	#animation triggers
	
	if is_on_floor():
		if Input.is_action_just_pressed("attack"):
			anim.play("attack_animation")
			can_move=false
			return
		elif !can_move: #if movement locked, dont do any of this until its allowed again
			return
		elif is_falling: #detect landing
			is_falling = false
			play("land_animation")
			return
		elif Input.is_action_just_pressed("move_up") && !is_jumping: #execute jump
			play("jump_animation")
			is_jumping = true
		elif is_jumping: #if jumping, dont interrupt
			pass
		elif input_dir_h!=0: #detect idling
			play("walk_animation")
		else:
			play("idle_animation")
	else:
		if velocity.y > 0: #if player just started falling
			is_jumping = false
			is_falling = true
			play("fall_animation")
	
	# Move
	move_and_slide()
	
func play(anim_name: String): #function to manage animation calls and currently playing animation
	#if no input, reset animation
	if anim_name == "": 
		anim.play("idle_animation")
		current_anim = "idle_animation"
		can_move=true
	if anim_name != current_anim:
		if !can_move:
			can_move=true
		anim.play(anim_name)
		current_anim = anim_name
		
func do_jump(): #called from jump animation at right time
	velocity.y = JUMP_FORCE
	

	

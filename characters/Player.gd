extends CharacterBody2D

const SPEED = 400.0
const JUMP_FORCE = -500.0
const GRAVITY = 700.0
@onready var animationSprites=$AnimationSprites
@onready var anim=$Animations
var current_anim

var is_jumping = false
var is_falling = false
var is_sprinting = false

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	#get horizontal input direction: -1, 0, 1 // left, neutral, right
	var input_dir_h = Input.get_axis("ui_left", "ui_right")
	velocity.x = input_dir_h * SPEED

	#sprite horizontal flip
	if input_dir_h > 0:
		animationSprites.flip_h=false
	elif input_dir_h < 0:
		animationSprites.flip_h=true
	
	#animation triggers
	
	if is_on_floor():
		if is_falling: #detect landing
			is_falling = false
			play("land_animation")
			return
		elif Input.is_action_just_pressed("move_up"): #execute jump
			play("jump_animation")
			is_jumping = true
			is_falling = false
		elif is_jumping: #if jumping, dont interrupt
			pass
		elif(input_dir_h!=0): #detect idling
			play("walking_animation")
		else:
			play("idle_animation")
	else:
		if velocity.y > 0 && is_jumping == true: #if player just started falling
			is_jumping = false
			is_falling = true
			play("fall_animation")

	# Move
	move_and_slide()
	
func play(anim_name: String): #function to manage animation calls and currently playing animation
	if name != current_anim:
		anim.play(anim_name)
		current_anim = anim_name
		
func do_jump(): #called from jump animation at right time
	velocity.y = JUMP_FORCE
	

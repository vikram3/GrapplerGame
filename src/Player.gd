extends CharacterBody2D

@export var staticGrappleDirection = false
@export var stunDuration = 1.0
@export var grappleLongCooldown = 1.0
@export var grappleShortCooldown = 0.25

var grapple
var stun = false
var stunTimer = 0.0
var grappleTimer = 0.0

const SPEED = 300.0
const GRAPPLE_DIRECTION = Vector2(1, -1)
const GRAPPLE_ACCELERATION = 2500.0
const AIR_FRICTION = 0.01
const GROUND_FRICTION = 0.5
const VELOCITY_TO_STUN = 100.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
    grapple = get_node("Grapple")

func _physics_process(delta):

    # Add the gravity.
    if not is_on_floor():
        velocity.y += gravity * delta

    handle_stun(delta)
    handle_grappler(delta)
    handle_movement(delta)



func handle_grappler(delta):
    if grappleTimer > 0.0:
        grappleTimer -= delta
        if grappleTimer <= 0.0:
            print("grapple ready")

    # Get mouse direction.
    var mouse_position = get_global_mouse_position()
    var mouse_direction = mouse_position - position
    if Input.is_action_just_pressed("grapple") && grappleTimer <= 0.0 && !stun:
        grapple.shoot(GRAPPLE_DIRECTION if staticGrappleDirection else mouse_direction, velocity)

    if Input.is_action_just_released("grapple"):
        if grapple.hooked:
            grappleTimer = grappleShortCooldown
        elif grapple.flying:
            grappleTimer = grappleLongCooldown
        grapple.release()

    if grapple.hooked:
        # pull the player towards the hook
        var direction = grapple.tip - position
        velocity += direction.normalized() * GRAPPLE_ACCELERATION * delta

func handle_movement(delta):
    # Get the input direction and handle the movement/deceleration.
    var direction = Input.get_axis("left", "right")
    if direction && is_on_floor() && !stun:
        velocity.x = lerp(velocity.x, direction * SPEED, .5)

    # Decelerate when not pressing left or right.
    if not direction && is_on_floor():
        velocity.x = velocity.x * (1 - GROUND_FRICTION) * delta
    if !is_on_floor():
        velocity -= velocity * (1 - AIR_FRICTION) * delta

    move_and_slide()

func handle_stun(delta):
    if stun:
        stunTimer -= delta
        if stunTimer <= 0.0:
            stun = false

    if (is_on_ceiling() || is_on_wall()) && velocity.length() >= VELOCITY_TO_STUN:
        stun = true
        print("stunned")
        stunTimer = stunDuration
        grapple.release()

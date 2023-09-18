extends CharacterBody2D

@export var staticGrappleDirection = false
@export var stunDuration = 1.0
@export var grappleLongCooldown = 0.5
@export var grappleShortCooldown = 0.1

var grapple
var sprite
var stun = false
var stunTimer = 0.0
var grappleTimer = 0.0
var oldVelocity = Vector2()

const SPEED = 200.0
const GRAPPLE_DIRECTION = Vector2(1, -1)
const GRAPPLE_ACCELERATION = 2500.0
const GRAPPLE_MAX_DISTANCE = 100.0
const AIR_FRICTION = 0.1
const STUN_GROUND_FRICTION = 0.5
const GROUND_FRICTION = 2.0
const VELOCITY_TO_STUN = 500.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
    grapple = get_node("Grapple")
    sprite = get_node("Sprite2D")

func _physics_process(delta):

    # Add the gravity.
    if !is_on_floor():
        velocity.y += gravity * delta

    handle_movement(delta)
    handle_stun(delta)
    handle_grappler(delta)

func handle_grappler(delta):
    if grappleTimer > 0.0:
        grappleTimer -= delta

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
        var distance = direction.length()
        var strength = clamp(distance / GRAPPLE_MAX_DISTANCE, 0.4, 1.0)
        velocity += direction.normalized() * GRAPPLE_ACCELERATION * delta * strength

func handle_movement(delta):
    # Get the input direction and handle the movement/deceleration.
    var direction = Input.get_axis("left", "right")
    if direction && is_on_floor() && !stun:
        velocity.x = lerp(velocity.x, direction * SPEED, .2)

    # Decelerate when not pressing left or right.
    if not direction && is_on_floor():
        velocity.x -= velocity.x * (GROUND_FRICTION if !stun else STUN_GROUND_FRICTION) * delta
    if !is_on_floor():
        velocity -= velocity *  AIR_FRICTION * delta
    
    oldVelocity = velocity
    move_and_slide()

func handle_stun(delta):
    if stun:
        stunTimer -= delta
        if stunTimer <= 0.0 && is_on_floor():
            sprite.rotation_degrees = 0
            stun = false
    # Stun the player if the velocity is too high when hitting an object
    var collision = get_last_slide_collision()
    if collision:
        var angle = abs(collision.get_normal().angle_to(oldVelocity))
        if angle > 2.1 && oldVelocity.length() > VELOCITY_TO_STUN && !stun:
            
            stun = true
            print("stunned")
            sprite.rotation_degrees = 45
            stunTimer = stunDuration
            grapple.release()


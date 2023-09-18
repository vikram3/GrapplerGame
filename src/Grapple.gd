extends Node2D

var links

var velocity := Vector2(0, 0)
var tip := Vector2(0, 0)

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

const SPEED = 1250
const AIR_FRICTION = 0.05
const MAXTIME = 1.0

var flying = false
var hooked = false
var timer = 0.0

func shoot(dir: Vector2, addedVelocity: Vector2 = Vector2(0, 0)):
    velocity = dir.normalized() * SPEED + addedVelocity
    flying = true
    tip = self.global_position
    timer = MAXTIME

func release():
    flying = false
    hooked = false

func _ready():
    links = $Links
    links.region_rect.size.y = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    self.visible = flying || hooked
    if not self.visible:
        return
        
    var tip_loc = to_local(tip)
    links.rotation = self.position.angle_to_point(tip_loc) + deg_to_rad(90)
    $Tip.rotation = self.position.angle_to_point(tip_loc) - deg_to_rad(90)
    links.position = tip_loc
    links.region_rect.size.y = tip_loc.length()

func _physics_process(delta):
    $Tip.global_position = tip

    if flying:
        timer -= delta
        if timer <= 0:
            release()
            return
        velocity.y += gravity * delta
        
        velocity -= velocity * (1 - AIR_FRICTION) * delta

        if $Tip.move_and_collide(velocity * delta):
            hooked = true
            flying = false
    tip = $Tip.global_position

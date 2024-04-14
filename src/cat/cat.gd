extends CharacterBody2D

enum States {IDLING, ACTION, MOVING_TRUE, MOVING_TEMP_STOP, MOVING_WANDER}

@export var waypoint : Sprite2D
@export var debug_target : Sprite2D

var current_state := States.IDLING

# Movement Vars
const BASE_MOV_SPEED := 50.0 # base value just to barely get things around
@export var move_speed_mltplr := 1.0 # can be used to more easily tweak the speed
@export var minimum_distance := 150.0 # average short distance to have as reference
var target_position := Vector2.ZERO
var custom_target_pos := Vector2.ZERO # can be same as the actual waypoint but can also be subject to variations

# Rotation Vars
@export var rot_speed := 2.0 # controls general rotation speed
var rot_coef := 0.0 # adjust speed based on distance and angle to waypoint. Faster rotation if the cat has less time to reach destination
var target_angle_dif := 0.0 # constantly represents the angle that is left for the cat to rotate towards waypoint
@export var target_angle_tolerance := 0.05 # when target_angle_dif is smaller than this value, it is assumed that rotation is close enough

# Waypoint Management
@export var min_variate_waypoint_interval := 0.3 # in seconds. Min time between calculating new variations
@export var max_variate_waypoint_interval := 1.0 # in seconds Max time between calculating new variations
@onready var variate_waypoint_interval := randf_range(min_variate_waypoint_interval, max_variate_waypoint_interval)
var variate_waypoint_timer := 0.0
@export var min_wander_angle_variation := 10
@export var max_wander_angle_variation := 20
@export var wander_length := 800 # when in wander state, the variations are set at this distance of current position


func _ready():
	current_state = States.MOVING_TRUE
	set_new_waypoint(waypoint.position)


func set_new_waypoint(new_pos : Vector2, variant : bool = false):
	if variant:
		custom_target_pos = new_pos
	else:
		target_position = new_pos
	
	target_angle_dif = transform.x.angle_to(new_pos-position)
	var distance = (new_pos-position).length()

	# coeficient is used to alter rotation speed based on time it would take to rotate til destination as well as time it 
	# would take to reach target destination
	rot_coef = (minimum_distance / BASE_MOV_SPEED) / (distance / (BASE_MOV_SPEED * move_speed_mltplr) / (target_angle_dif / 2))


# Returns variations on the current waypoint position
func variate_waypoint() -> Vector2:
	var modifier = 1 if randf() < 0.5 else -1
	return Vector2(position + (target_position-position).normalized().rotated(deg_to_rad(randf_range(min_wander_angle_variation, max_wander_angle_variation) * modifier)) * 
		wander_length)
		

func _physics_process(delta):
	if current_state == States.MOVING_TRUE || current_state == States.MOVING_WANDER:

		var _v = move_and_collide(transform.x * delta * BASE_MOV_SPEED * move_speed_mltplr)

		if current_state == States.MOVING_TRUE:
			custom_target_pos = target_position
			variate_waypoint_timer = 0
		else:
			variate_waypoint_timer += delta
			if variate_waypoint_timer >= variate_waypoint_interval:
				variate_waypoint_timer = 0
				variate_waypoint_interval = randf_range(min_variate_waypoint_interval, max_variate_waypoint_interval)
				set_new_waypoint(variate_waypoint(), true)

				debug_target.set_pos(variate_waypoint())


		if abs(target_angle_dif) > target_angle_tolerance:
			target_angle_dif = transform.x.angle_to(custom_target_pos-position)
			var modifier : int = sign(target_angle_dif)
			rotation = move_toward(rotation, rotation + modifier * target_angle_dif, rot_coef * rot_speed)
		else:
			current_state = States.MOVING_WANDER

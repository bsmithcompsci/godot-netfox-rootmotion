extends Node
class_name PlayerLocomotion

@export var animator: PlayerAnimator
@export var turn_speed: float = 10.0
var movement_direction: Vector2 = Vector2.ZERO
var camera_angle: float = 0.0
var camera_held: bool = false

var _character: CharacterBody3D

var _previous_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	_character = get_parent() as CharacterBody3D
	if !_character:
		printerr("PlayerLocomotion: CharacterBody3D not found.")
		return


func do_process(delta: float) -> Vector3:
	if !_character:
		return Vector3.ZERO

	# Expected Behaviour:
	# - When the player holds the camera button, the character will rotate to face in the camera's direction.
	# - When the player is not holding the camera button, the character will rotate in the direction of the input from the camera's perspective.
	#    And the character will walk/run forward.
	
	var velocity: Vector3 = Vector3.ZERO
	# Update Animator
	if camera_held:
		animator.locomotion_direction = Vector2(movement_direction.x, -movement_direction.y)
	elif movement_direction != Vector2.ZERO:
		var strength: float = movement_direction.length()
		animator.locomotion_direction = Vector2(0, strength)
	else:
		animator.locomotion_direction = Vector2.ZERO

	# Root Motion Code:
	var root_motion: Vector3 = animator.animation_tree.get_root_motion_position()
	var current_rotation: Quaternion = _character.transform.basis.get_rotation_quaternion().normalized()
	var root_velocity: Vector3 = current_rotation * root_motion / delta
	var root_rotation: Quaternion = animator.animation_tree.get_root_motion_rotation()
	_character.quaternion = _character.quaternion * root_rotation / delta

	var direction: Vector3 = Vector3(movement_direction.x, 0, movement_direction.y).rotated(Vector3.UP, camera_angle).normalized()

	velocity = Vector3(root_velocity.x, 0, root_velocity.z)
	
	if direction != Vector3.ZERO:
		_previous_direction = Vector2(direction.x, direction.z)

	var look_angle: float
	if camera_held:
		look_angle = lerp_angle(_character.rotation.y, camera_angle + 90 + 45, turn_speed * delta)
	else:
		look_angle = lerp_angle(_character.rotation.y, atan2(_previous_direction.x, _previous_direction.y), turn_speed * delta)
	
	_character.rotation.y = look_angle

	DebugDraw2D.set_text("camera_angle", camera_angle)
	DebugDraw2D.set_text("camera_held", camera_held)

	# DebugDraw3D.draw_ray(transform.origin, root_motion, 1, Color.RED)
	DebugDraw3D.draw_ray(_character.transform.origin, direction, 10, Color.BLUE)

	DebugDraw2D.set_text("movement_input", movement_direction)

	DebugDraw2D.set_text("position", _character.transform.origin)

	return velocity

extends Node
class_name PlayerCombat


@export var animator: PlayerAnimator
@export var input: PlayerInput

var character: PlayerCharacter:
    get:
        return get_parent() as PlayerCharacter
var camera_angle: float = 0.0
var look_angle: float = 0.0
var _last_attack_direction: Vector2


func do_process(_delta: float, in_control: bool) -> void:
    if !character:
        return
    if !animator:
        printerr("PlayerCombat: PlayerAnimator not found.")
        return
    if !input:
        printerr("PlayerCombat: PlayerInput not found.")
        return
    if !in_control:
        return

    # Expected Behaviour:
        # - When the player hits the attack button, the character will attack in the direction that the player look is facing.

    # Update Animator
    if input.net_attack:
        # Set the rotation of the character to face the direction of where the player clicked.
        
        var direction: Vector3 = Vector3(0, 0, 1).rotated(Vector3.UP, look_angle).normalized()
        _last_attack_direction = Vector2(direction.x, direction.z)

        var _look_angle: float = atan2(direction.x, direction.y)

        # character.global_rotation.y = _look_angle
        character.look_at(character.global_position + -direction, Vector3.UP)

        DebugDraw3D.draw_ray(character.global_position, direction, 10, Color.RED, 1)
        DebugDraw3D.draw_ray(character.global_position, Vector3(0, 0, 1).rotated(Vector3.UP, character.global_rotation.y), 10, Color.PURPLE, 1)

        animator.attack()
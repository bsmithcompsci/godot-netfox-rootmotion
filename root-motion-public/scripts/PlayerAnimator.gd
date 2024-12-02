extends Node
class_name PlayerAnimator

@export var animation_tree: AnimationTree

enum AnimationState {
    Movement,
    Attack,
}

var animation_state: AnimationState = AnimationState.Movement:
    get():
        if animation_tree:
            match animation_tree.get("parameters/Transition/current_state"):
                "Movement":
                    animation_state = AnimationState.Movement
                "Attack":
                    animation_state = AnimationState.Attack
        return animation_state
var locomotion_direction: Vector2 = Vector2.ZERO:
    set(value):
        if animation_tree:
            animation_tree.set("parameters/Locomotion/blend_position", value)
        locomotion_direction = value

func attack() -> void:
    # print("Processing Attack")
    if !animation_tree:
        return
    if animation_state != AnimationState.Movement:
        return
    
    # print("Attack")
    animation_tree.set("parameters/Transition/transition_request", "Attack")

    # Wait until the attack animation is finished.
    while animation_state != AnimationState.Attack:
        await get_tree().process_frame
    # print("Awaited Animation Transition...")
    await animation_tree.animation_finished
    # print("Finished Attack")
    animation_tree.set("parameters/Transition/transition_request", "Movement")
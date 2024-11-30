extends Node
class_name PlayerAnimator

@export var animation_tree: AnimationTree

var locomotion_direction: Vector2 = Vector2.ZERO:
    set(value):
        if animation_tree:
            animation_tree.set("parameters/Locomotion/blend_position", value)
        locomotion_direction = value
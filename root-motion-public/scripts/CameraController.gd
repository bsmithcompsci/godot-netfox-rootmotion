extends Node3D
class_name CameraController

@export var target: Node3D

@export_category("Setup")
@export var camera: Camera3D
@export var follow_speed: float = 5.0
@export var limit_distance: float = 100.0
@export var sensitivity: float = 0.05

var _rotation: float = 0.0
var _rotating: bool

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mouseEvent: InputEventMouseButton = event as InputEventMouseButton
        if mouseEvent.button_index == MOUSE_BUTTON_MIDDLE:
            _rotating = mouseEvent.pressed
    if event is InputEventMouseMotion:
        var mouseEvent: InputEventMouseMotion = event as InputEventMouseMotion
        if _rotating:
            _rotation -= mouseEvent.relative.x

func _process(delta: float) -> void:
    rotation.y = _rotation * sensitivity * delta

    if target:
        var distance: float = global_position.distance_to(target.global_transform.origin)
        
        # If the distance is less than the limit distance, then we can follow the target garcefully.
        # Otherwise, we will teleport to the target at the minimum distance.
        if distance < limit_distance:
            var next_position: Vector3 = global_position.lerp(target.global_transform.origin, follow_speed * delta)
            global_position = next_position
        else:
            var direction: Vector3 = target.global_transform.origin - global_position
            global_position += direction.normalized() * (distance - limit_distance)

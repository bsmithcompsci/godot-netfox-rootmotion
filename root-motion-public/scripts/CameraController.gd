extends Node3D
class_name CameraController

@export var target: Node3D:
    set(value):
        if value:
            global_transform.origin = value.global_transform.origin + offset
            global_transform.basis = value.global_transform.basis
        target = value

@export_category("Setup")
@export var camera: Camera3D
@export var follow_speed: float = 5.0
@export var limit_distance: float = 100.0
@export var sensitivity: float = 0.05
@export var offset: Vector3 = Vector3(0, 10, 5)

@export var maxZoom: float = 8.0
@export var minZoom: float = 2.0
@export var zoomSpeed: float = 0.1

var _zoomDistance: float = 0.0
var _rotation: float = 0.0
var _rotating: bool

func _ready() -> void:
    if not camera:
        printerr("CameraController: Camera3D not found.")
        return

    camera.make_current()
    camera.transform.origin = offset

    _zoomDistance = (maxZoom + minZoom) / 2
    _update_offset()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mouseEvent: InputEventMouseButton = event as InputEventMouseButton
        if mouseEvent.button_index == MOUSE_BUTTON_MIDDLE:
            _rotating = mouseEvent.pressed
        if mouseEvent.button_index == MOUSE_BUTTON_WHEEL_UP or mouseEvent.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            var zoom_multiplier: int = 1 if mouseEvent.button_index == MOUSE_BUTTON_WHEEL_UP else -1
            var zoom_scale: float = 2.0 ** (mouseEvent.factor if mouseEvent.factor else 1.0) * zoomSpeed
            _zoomDistance = clamp(_zoomDistance - (zoom_scale * zoom_multiplier), minZoom, maxZoom)
            _update_offset()

    if event is InputEventMouseMotion:
        var mouseEvent: InputEventMouseMotion = event as InputEventMouseMotion
        if _rotating:
            _rotation -= mouseEvent.relative.x

func _update_offset() -> void:
    var percentage: float = (_zoomDistance - minZoom) / (maxZoom - minZoom)
    offset.y = _zoomDistance
    offset.z = minZoom + (maxZoom - minZoom) * (percentage ** 2.0)
    camera.transform.origin = offset


func _process(delta: float) -> void:
    pass

func _physics_process(delta: float) -> void:
    follow_process(delta)

func follow_process(delta: float) -> void:
    rotation.y = _rotation * sensitivity * delta

    DebugDraw2D.set_text("camera_zoom", offset.y)
    DebugDraw2D.set_text("camera_offset", offset)
    DebugDraw2D.set_text("zoom_percentage", (_zoomDistance - minZoom) / (maxZoom - minZoom))

    if target:
        var distance: float = global_position.distance_to(target.global_transform.origin)
        
        # If the distance is less than the limit distance, then we can follow the target garcefully.
        # Otherwise, we will teleport to the target at the minimum distance.
        var lookat: Vector3 = target.global_transform.origin + Vector3.UP
        if distance < limit_distance:
            var next_position: Vector3 = global_position.lerp(target.global_transform.origin, follow_speed * delta)
            global_position = next_position
            lookat = next_position + Vector3.UP
        else:
            var direction: Vector3 = target.global_transform.origin - global_position
            global_position += direction.normalized() * (distance - limit_distance)
        
        camera.look_at(lookat, Vector3.UP)

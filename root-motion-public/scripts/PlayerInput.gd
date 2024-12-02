extends Node
class_name PlayerInput

var net_movement_direction: Vector2 = Vector2.ZERO
var net_look_angle: float = 0.0
var net_camera_angle: float = 0.0
var net_camera_held: bool = true
var net_attack: bool = false

var is_client_side: bool = false:
    set(value):
        is_client_side = value
        set_process(value)

var character: PlayerCharacter:
    get():
        return get_parent() as PlayerCharacter

var is_local: bool:
    get():
        return is_multiplayer_authority() or is_client_side

func _ready() -> void:
    NetworkTime.before_tick_loop.connect(_gather)

    set_process(is_client_side)
    set_physics_process(false)

func _input(event: InputEvent) -> void:
    handle_input(event)
func _unhandled_input(event: InputEvent) -> void:
    handle_input(event)

func handle_input(_event: InputEvent) -> void:
    if !is_multiplayer_authority():
        return
    
    if _event is InputEventMouseButton:
        var mouseEvent: InputEventMouseButton = _event as InputEventMouseButton
        if mouseEvent.button_index == MOUSE_BUTTON_MIDDLE:
            net_camera_held = mouseEvent.pressed
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if net_camera_held else Input.MOUSE_MODE_VISIBLE

func _gather() -> void:
    if !is_multiplayer_authority():
        return
    net_movement_direction = Input.get_vector("left", "right", "forward", "backwards")
    DebugDraw2D.set_text("net_input", net_movement_direction)

    net_attack = Input.is_action_pressed("attack")

    if character.camera:
        # Collect the mouse position and calculate the angle from the parent node3d to the mouse position.
        # This will be used to rotate the character towards the mouse position.
        var screen_mouse_position: Vector2 = get_viewport().get_mouse_position()
        var plane: Plane = Plane(Vector3.UP, character.global_position.y)
        var ray_length: int = 1000
        var from: Vector3 = character.camera.camera.project_ray_origin(screen_mouse_position)
        var to: Vector3 = from + character.camera.camera.project_ray_normal(screen_mouse_position) * ray_length
        var world_position = plane.intersects_ray(from, to)
        if world_position:
            var look_at_direction: Vector3 = (world_position - character.global_position).normalized()
            net_look_angle = atan2(look_at_direction.x, look_at_direction.z)

            # DebugDraw3D.draw_ray(Vector3.ZERO, world_position, world_position.length(), Color.RED)
            # DebugDraw3D.draw_ray(world_position, Vector3.UP, 10, Color.RED)
            # DebugDraw3D.draw_ray(character.global_position, look_at_direction, 10, Color.BLUE)

            # DebugDraw3D.draw_ray(character.global_position, Vector3(0, 0, 1).rotated(Vector3.UP, net_look_angle), 10, Color.GREEN)

    if character.camera:
        net_camera_angle = character.camera.global_transform.basis.get_euler().y
    
func _process(_delta: float) -> void:
    _gather()

# This function is called by the RollbackSynchronizer to build the input properties.
func build(rollback_synchronizer: RollbackSynchronizer) -> void:
    for prop: Variant in get_property_list():
        var prop_name: String = prop.name
        if prop_name.begins_with("net_"):
            # print("%s:%s" % [name, prop_name])
            rollback_synchronizer.input_properties.append("%s:%s" % [name, prop_name])

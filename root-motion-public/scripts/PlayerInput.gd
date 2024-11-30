extends Node
class_name PlayerInput

var net_movement_direction: Vector2 = Vector2.ZERO
var net_camera_angle: float = 0.0
var net_camera_held: bool = false

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

func _gather() -> void:
	if !is_multiplayer_authority():
		return
	net_movement_direction = Input.get_vector("left", "right", "forward", "backwards")
	DebugDraw2D.set_text("net_input", net_movement_direction)
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

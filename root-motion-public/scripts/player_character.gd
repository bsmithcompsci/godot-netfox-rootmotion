extends CharacterBody3D
class_name PlayerCharacter

@export var is_client_side: bool = false
@export var network_id: int:
	set(value):
		network_id = value
		input.set_multiplayer_authority(value)

@export var camera: CameraController
@export var input: PlayerInput
@export var locomotion: PlayerLocomotion
@export var rollback_sync: RollbackSynchronizer

func _ready() -> void:
	# Only run the process, if the character is suppose to run client-side.
	#  This is used in a testing scene for testing root-motion is working as intended.
	set_process(is_client_side)
	set_physics_process(false)

	# Await the frame to ensure the network is ready.
	if is_client_side:
		rollback_sync.queue_free()
	else:
		await get_tree().process_frame
		input.build(rollback_sync)
		rollback_sync.process_settings()

	input.is_client_side = is_client_side
	print("[%s::%s] Player Spawned: %s [Owner=%s/%s|%s]" % ["SERVER" if is_client_side else "CLIENT", multiplayer.get_unique_id(), get_path(), get_multiplayer_authority(), network_id, is_multiplayer_authority()])

func _rollback_tick(delta: float, _tick: int, _is_fresh: bool) -> void:
	# Apply PlayerInput into PlayerLocomotion
	locomotion.movement_direction = input.net_movement_direction
	locomotion.camera_angle = input.net_camera_angle
	locomotion.camera_held = input.net_camera_held
	
	# Grab Velocity from the locomotion system
	velocity = locomotion.do_process(delta)
	
	DebugDraw2D.set_text("velocity", velocity)
	DebugDraw3D.draw_ray(transform.origin, velocity, 1, Color.YELLOW)

	# Apply the velocity in respect of the network time.
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor

func _process(_delta: float) -> void:
	_rollback_tick(_delta, 0, false)

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
@export var combat: PlayerCombat
@export var rollback_sync: RollbackSynchronizer
@export_range(0.0, 5.0) var network_update: float = 0.05

var _last_network_update: float = 0.0

func _ready() -> void:
	set_process(true)
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

func _rollback_tick(_delta: float, _tick: int, _is_fresh: bool) -> void:
	# Apply PlayerInput into PlayerLocomotion
	locomotion.movement_direction = input.net_movement_direction
	locomotion.look_angle = input.net_look_angle
	locomotion.camera_angle = input.net_camera_angle
	# locomotion.camera_held = input.net_camera_held

	# Apply PlayerInput into PlayerCombat
	combat.camera_angle = input.net_camera_angle
	combat.look_angle = input.net_look_angle
	
func _process(delta: float) -> void:
	if is_client_side:
		_rollback_tick(delta, 0, false)
	
	# Grab Velocity from the locomotion system
	var in_control: bool = combat.animator.animation_state == PlayerAnimator.AnimationState.Movement
	combat.do_process(delta, in_control)
	
	# Transfer the last attack direction to the locomotion system.
	if combat.animator.animation_state == PlayerAnimator.AnimationState.Attack:
		locomotion._previous_direction = combat._last_attack_direction

	velocity = locomotion.do_process(delta, in_control)
	
	DebugDraw2D.set_text("velocity", velocity)
	DebugDraw3D.draw_ray(transform.origin, velocity, 1, Color.YELLOW)

	# Apply the velocity in respect of the network time.
	# velocity *= NetworkTime.physics_factor
	move_and_slide()
	# velocity /= NetworkTime.physics_factor

	if multiplayer.is_server():
		_last_network_update -= delta
		if _last_network_update <= 0.0:
			_update_state.rpc(self.global_transform)
			_last_network_update = network_update
	else:
		DebugDraw3D.draw_cylinder(self.global_transform, Color.RED)

@rpc("authority", "unreliable")
func _update_state(state_transform: Transform3D) -> void:
	var dist: float = global_transform.origin.distance_to(state_transform.origin)
	if dist > 1.0:
		self.global_transform = state_transform
	else:
		self.global_transform = global_transform.interpolate_with(state_transform, 0.1)
	DebugDraw3D.draw_cylinder(self.global_transform, Color.BLUE, network_update)

extends Node
class_name AnimationSync

@export var animation_tree: AnimationTree
@export var rollback_sync: RollbackSynchronizer

var animation_advancement: float = 0.0:
	set(value):
		animation_advancement = value
		print("[%s::%s] Animation Advancement: %s" % ["SERVER" if multiplayer.is_server() else "CLIENT", multiplayer.get_unique_id(), value])

func _ready() -> void:
	set_process(true)
	set_physics_process(false)

	if !rollback_sync:
		printerr("AnimationSync: RollbackSynchronizer not found.")
		return

	# if animation_tree:
	# 	print(animation_tree.get_property_list())
	
	var relative_path: String = str(get_path()).replace(str(rollback_sync.root.get_path()) + "/", "")

	rollback_sync.state_properties.append("%s:%s" % [relative_path, "animation_advancement"])
	rollback_sync.process_settings()

func _process(delta: float) -> void:
	if !animation_tree:
		return

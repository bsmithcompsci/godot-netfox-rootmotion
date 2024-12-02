extends Node
class_name NetworkManager

@export var panel: Control
@export var btn_test_client_side: Button
@export var btn_host: Button
@export var btn_join: Button
@export var txtbox_ip: LineEdit

@export var client_side_test: PackedScene
@export var scene: PackedScene
@export var playerScene: PackedScene

@export var world_sync: MultiplayerSpawner
@export var players_sync: MultiplayerSpawner

@export var client_side_camera: PackedScene

var _socket: ENetMultiplayerPeer
var _players: Dictionary = {}

func _ready() -> void:
    # Multiplayer API
    multiplayer.peer_connected.connect(_on_new_client)
    multiplayer.peer_disconnected.connect(_on_client_disconnection)
    multiplayer.connected_to_server.connect(_on_connection_successful)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)
    
    # Create the Socket
    _socket = ENetMultiplayerPeer.new()
    if OS.has_feature("dedicated_server"):
        _on_btn_host_pressed()
        return
    
    btn_test_client_side.pressed.connect(_on_btn_test_client_side_pressed)
    btn_host.pressed.connect(_on_btn_host_pressed)
    btn_join.pressed.connect(_on_btn_join_pressed)

func _process(_delta: float) -> void:
    DebugDraw2D.set_text("A Network ID", multiplayer.get_unique_id())
    DebugDraw2D.set_text("A Network Server", multiplayer.is_server())
    DebugDraw2D.set_text("A Network RTT(ms)", NetworkTime.remote_rtt * 1000)
    DebugDraw2D.set_text("A Network RTT Jitter(ms)", NetworkTimeSynchronizer.rtt_jitter * 1000)

func _on_connection_successful() -> void:
    print("Connection Successful!")
    
    var node: Node = Node.new()
    node.name = "CLIENT_%s" % multiplayer.get_unique_id()
    self.add_child(node)

func _on_connection_failed() -> void:
    print("Connection Failed!")
    panel.visible = true

func _on_server_disconnected() -> void:
    print("Server Disconnected!")
    panel.visible = true

func _on_btn_host_pressed() -> void:
    _socket.set_bind_ip("*")
    _socket.create_server(25565, 32)

    multiplayer.multiplayer_peer = _socket

    var game_world: Node = scene.instantiate()
    world_sync.add_child(game_world)
    panel.visible = false

    var node: Node = Node.new()
    node.name = "SERVER"
    self.add_child(node)

    if OS.has_feature("dedicated_server"):
        return

    var camera: Camera3D = Camera3D.new()
    game_world.add_child(camera)
    camera.transform.origin = Vector3(0, 8, 15)
    # Look 45 degrees down
    camera.rotation_degrees = Vector3(-45, 0, 0)

    # Allows the host to also play.
    # spawn_player(1)


func _on_btn_join_pressed() -> void:
    _socket.create_client(txtbox_ip.text, 25565)

    multiplayer.multiplayer_peer = _socket
    
    panel.visible = false

func _on_btn_test_client_side_pressed() -> void:
    get_tree().change_scene_to_packed(client_side_test)

func _on_new_client(id: int) -> void:
    if id == 1: # No SERVER!
        return

    print("New Client Connected: ", id)

    spawn_player(id)

func _on_client_disconnection(id: int) -> void:
    print("Client Disconnected: ", id)
    if _players.has(id):
        _players[id].queue_free()
        _players.erase(id)

func spawn_player(id: int) -> void:
    var player: PlayerCharacter = playerScene.instantiate()
    player.network_id = id
    player.name = "PlayerCharacter_%s" % id
    players_sync.add_child(player)

    _players[id] = player

    spawned_player.rpc_id(id, player.get_path())

@rpc("any_peer")
func spawned_player(nodePath: NodePath) -> void:
    print("[%s::%s] Spawned Player: %s" % ["SERVER" if multiplayer.is_server() else "CLIENT", multiplayer.get_unique_id(), nodePath])

    var client_side_camera_instance: CameraController = client_side_camera.instantiate()
    client_side_camera_instance.target = get_node(nodePath)
    self.add_child(client_side_camera_instance)

    var player_character: PlayerCharacter = get_node(nodePath)
    player_character.camera = client_side_camera_instance

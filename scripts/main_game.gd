extends Node2D

const peer_player_scene = preload("res://scenes/peer_player.tscn")
const player_scene = preload("res://scenes/player.tscn")
const bullet_scene = preload("res://scenes/bullet.tscn")

@onready var join_timeout_timer = $JoinTimeoutTimer
@onready var peer_player_parent = $PeerPlayerParent
@onready var bullet_parent = $BulletParent

var peer_nodes = {}

func _ready():
	MPlay.mplay_peer_disconnected.connect(_handle_player_disconnected)
	MPlay.mplay_server_disconnected.connect(_handle_server_disconnected)
	MPlay.mplay_player_register.connect(_handle_player_register)
	
	if multiplayer.is_server():
		setup_game()
	else:
		join_timeout_timer.timeout.connect(_handle_join_timeout)
		join_timeout_timer.start()

func _handle_server_disconnected():
	_leave_game()

func _handle_player_disconnected(id, player_info):
	if peer_nodes.has(id):
		peer_nodes[id].queue_free()
		peer_nodes.erase(id)

func _handle_player_register(id, player_info):
	# If the registering player is the server, request the game setup
	if id == 1:
		request_setup.rpc_id(1)
	
	var our_player = get_node_or_null("Player")
	
	if our_player != null:
		our_player.enable_update_override()
	
	if not peer_nodes.has(id):
		var peer_player = peer_player_scene.instantiate()
		peer_player.peer_name = player_info.name
		peer_player.color = player_info.color
		peer_player.unique_id = id
		peer_nodes[id] = peer_player
		peer_player_parent.add_child(peer_player)

func _leave_game():
	MPlay.peer_reset()
	get_tree().change_scene_to_file("res://scenes/main_start.tscn")

func _handle_join_timeout():
	_leave_game()

@rpc("reliable", "any_peer")
func request_setup():
	var peer_id = multiplayer.get_remote_sender_id()
	
	if multiplayer.is_server():
		setup_game.rpc_id(peer_id)
	else:
		print_debug("Non-server received setup request: %s" % peer_id)

@rpc("reliable")
func setup_game():
	if not join_timeout_timer.is_stopped():
		join_timeout_timer.stop()
	
	var our_player = get_node_or_null("Player")
	
	if our_player == null:
		our_player = player_scene.instantiate()
		add_child(our_player)
	else:
		print_debug("Player already exists during setup")

@rpc("any_peer", "call_local", "reliable")
func create_bullet(bullet_position, bullet_direction):
	var bullet = bullet_scene.instantiate()
	bullet.direction = bullet_direction
	bullet.position = bullet_position
	
	bullet_parent.add_child(bullet)

@rpc("any_peer")
func peer_update(data):
	var peer_id = multiplayer.get_remote_sender_id()
	
	if peer_nodes.has(peer_id):
		peer_nodes[peer_id].peer_sync(data)

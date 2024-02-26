extends Node2D

const lerp_speed = 60.0 / Globals.peer_update_rate

# This value will depend on the movement speed of the player and should be greater than the fastest speed they can move instantly. 
const teleport_delta_threshold = 100.0

var unique_id = -1
var peer_name = "PeerPlayer"
var color = Color.WHITE
var target_position = position
var prev_position_delta = Vector2.ZERO

func _ready():
	var name_label = $NameLabel
	name_label.text = peer_name

func _draw():
	draw_circle(Vector2.ZERO, 32.0, color)

func _process(delta):
	position = position.lerp(target_position, delta * lerp_speed)

func peer_sync(data):
	var new_target_position = Vector2(
		data.decode_float(0),
		data.decode_float(4)
	)
	
	var position_delta = target_position - new_target_position
	var is_teleport = (position_delta - prev_position_delta).length() > teleport_delta_threshold
	
	# If the current delta is much greater than the previous delta, we assume the peer player was teleported and move instantly.
	# This helps prevent lerping when teleporting. 
	if is_teleport:
		position = new_target_position
		prev_position_delta = Vector2.ZERO
	else:
		prev_position_delta = position_delta
	
	target_position = new_target_position
	
	if not visible:
		show()

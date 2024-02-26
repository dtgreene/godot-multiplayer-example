extends CharacterBody2D

const speed = 300.0
const position_update_rate = Globals.peer_update_rate
const position_update_min = 0.02

@onready var color = MPlay.player_color
@onready var main_game = get_node("/root/MainGame")
@onready var shoot_timer = $ShootTimer
@onready var viewport = get_viewport()
@onready var update_override_timer = $UpdateOverrideTimer

var can_shoot = true
var prev_position = position
var position_tick = 0
var update_override = false

func _ready():
	shoot_timer.timeout.connect(_handle_shoot_timeout)
	update_override_timer.timeout.connect(_handle_update_override_timeout)
	
	enable_update_override()

func _draw():
	draw_circle(Vector2.ZERO, 32.0, color)

func _physics_process(delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if direction:
		velocity.x = direction.x * speed
		velocity.y = direction.y * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.y = move_toward(velocity.y, 0, speed)

	move_and_slide()
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and can_shoot:
		var mouse_position = viewport.get_mouse_position()
		var shoot_direction = (mouse_position - position).normalized()

		main_game.create_bullet.rpc(position, shoot_direction)
		
		can_shoot = false
		shoot_timer.start()
	
	# Send updates whenever our player moves by some threshold
	position_tick += 1
	if position_tick >= position_update_rate or update_override:
		position_tick = 0
		
		var position_needs_update = (position - prev_position).length() > position_update_min
		
		if position_needs_update or update_override:
			main_game.peer_update.rpc(_get_update_data())
		
		prev_position = position

func _handle_update_override_timeout():
	update_override = false

func _get_update_data():
	# Pack whatever data is needed to update the player. In this example, we only need the position.
	var data = PackedByteArray()
	data.resize(8)
	data.encode_float(0, position.x)
	data.encode_float(4, position.y)
	
	return data

func _handle_shoot_timeout():
	can_shoot = true

func enable_update_override():
	# Update override is used to manually force updates; usually when other players join.
	# Since updates are only sent when players move around, joining players won't know the positions of idle players until they move.
	# One alternative to this would be for players to send their position to joining players.  This is just easier and works.
	update_override = true
	update_override_timer.start()

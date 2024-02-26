extends Node2D

const speed = 600.0

@onready var expire_timer = $ExpireTimer

var direction = Vector2.ZERO

func _ready():
	expire_timer.timeout.connect(_handle_expire_timeout)

func _draw():
	draw_circle(Vector2.ZERO, 4.0, Color.YELLOW)

func _process(delta):
	position += direction * speed * delta

func _handle_expire_timeout():
	queue_free()

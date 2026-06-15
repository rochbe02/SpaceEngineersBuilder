extends Camera3D

var pivot: Vector3 = Vector3.ZERO
var distance: float = 15.0
var yaw: float = 45.0
var pitch: float = -35.0

var is_rotating: bool = false
var is_panning: bool = false
var last_mouse_pos: Vector2

func _ready():
	_update_position()

func _input(event):
	if event is InputEventMouseButton:
		# Rotar con clic derecho
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_rotating = event.pressed
		
		# Pan con clic medio
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			is_panning = event.pressed

		# Zoom con rueda
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = max(3.0, distance - 1.0)
			_update_position()
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = min(50.0, distance + 1.0)
			_update_position()

	if event is InputEventMouseMotion:
		if is_rotating:
			yaw -= event.relative.x * 0.3
			pitch -= event.relative.y * 0.3
			pitch = clamp(pitch, -80.0, -5.0)
			_update_position()
		
		if is_panning:
			# Mover el pivot en el plano de la cámara
			var right = global_transform.basis.x
			var up = global_transform.basis.y
			pivot -= right * event.relative.x * 0.05
			pivot += up * event.relative.y * 0.05
			_update_position()

func _update_position():
	var yaw_rad = deg_to_rad(yaw)
	var pitch_rad = deg_to_rad(pitch)
	position = pivot + Vector3(
		distance * cos(pitch_rad) * sin(yaw_rad),
		distance * sin(pitch_rad) * -1,
		distance * cos(pitch_rad) * cos(yaw_rad)
	)
	look_at(pivot, Vector3.UP)

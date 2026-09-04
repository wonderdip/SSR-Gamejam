extends Sprite2D
@onready var cross_area: Area2D = $CrossArea

var mouse_on_cross: bool = false
var dragging := false
var original_position: Vector2
var rotation_tween: Tween

var holding := false
var hold_time := 0.15
var hold_timer := 0.0

func _ready() -> void:
	original_position = global_position
	hide()

func _process(delta: float) -> void:
	if holding and not dragging:
		hold_timer += delta
		
		if hold_timer >= hold_time:
			dragging = true
			
			if rotation_tween:
				rotation_tween.pause()
			
			rotation_degrees = 0

	if dragging:
		global_position = global_position.lerp(
			get_global_mouse_position(),
			10.0 * delta
		)

func animate_cross():
	var tween: Tween = create_tween()
	
	position = Vector2(356, -152)
	scale = Vector2(2, 2)
	show()
	
	tween.tween_property(self, "scale", Vector2(1, 1), 0.5)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_SPRING)
	
	tween.set_parallel()
	tween.tween_property(self, "position", Vector2(192, 56), 0.5)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_SPRING)
	
	await tween.finished
	
	cross_area.mouse_entered.connect(_on_mouse_on_cross)
	cross_area.mouse_exited.connect(_on_mouse_off_cross)
	cross_area.input_event.connect(_on_cross_input)
	
	rotate_cross()

func rotate_cross():
	
	rotation_tween = create_tween().set_loops()
	
	rotation_tween.tween_property(
		self,
		"rotation_degrees",
		5,
		3.5
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	rotation_tween.tween_property(
		self,
		"rotation_degrees",
		-5,
		3.5
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _on_mouse_on_cross():
	mouse_on_cross = true
	var size_tween : Tween = create_tween()
	size_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)
	
func _on_mouse_off_cross():
	mouse_on_cross = false
	var size_tween : Tween = create_tween()
	size_tween.tween_property(self, "scale", Vector2(1, 1), 0.1)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)

func cross_click():
	var click_tween : Tween = create_tween()
	click_tween.tween_property(self, "scale", Vector2(1, 1), 0.1)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_SINE)
	
	click_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.15)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)

func _on_cross_input(
	_viewport: Node,
	event: InputEvent,
	_shape_idx: int
) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			
			if event.pressed:
				holding = true
				hold_timer = 0.0
				if dragging:
					return
				cross_click()
			else:
				holding = false
				hold_timer = 0.0
				
				if dragging:
					dragging = false
					snap_back()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if dragging:
				dragging = false
				snap_back()

func snap_back() -> void:
	if rotation_tween:
		rotation_tween.play()
		dragging = false
		holding = false
		hold_timer = 0.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		self,
		"global_position",
		original_position,
		0.4
	)

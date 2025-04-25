extends Node2D

var rope_piece: Resource = preload("res://rope_piece.tscn")
var piece_length := 6.0
var rope_parts := []
var rope_close_tolerance := 8.0
var rope_points : PackedVector2Array = []
var rope_colors : PackedColorArray = []
var rope_to_left := true
var active_rope_id : int = -INF:
	set(value):
		set_active_rope_id(value)

var color1 := Color.CORAL
var color2 := Color.BLACK

@onready var rope_start_piece: StaticBody2D = $RopeStartPiece
@onready var rope_end_piece: StaticBody2D = $RopeEndPiece
@onready var rope_start_joint: PinJoint2D = $RopeStartPiece/C/J
@onready var rope_end_joint: PinJoint2D = $RopeEndPiece/C/J


func _ready() -> void:
	spawn_rope(rope_start_piece.global_position, rope_end_piece.global_position)


func _process(_delta: float) -> void:
	get_rope_points()
	if rope_points.size() > 2:
		queue_redraw()

func set_active_rope_id(value:int) -> void:
	if active_rope_id != value:
		active_rope_id = value
		if active_rope_id == -INF:
			for i: RopePiece in rope_parts:
				(i as RigidBody2D).mass = 1
		else:
			for i in len(rope_parts):
				if i == active_rope_id:
					(rope_parts[i] as RigidBody2D).mass = 10
				else:
					(rope_parts[i] as RigidBody2D).mass = 1

func spawn_rope(start_pos:Vector2, end_pos:Vector2) -> void:
	rope_start_piece.global_position = start_pos
	rope_end_piece.global_position = end_pos
	start_pos = rope_start_joint.global_position
	end_pos = rope_end_joint.global_position
	rope_to_left = start_pos.x < end_pos.x
	
	var distance: float = start_pos.distance_to(end_pos)
	var pieces_amount: int = round(distance / piece_length)
	var spawn_angle: float = (end_pos-start_pos).angle() - PI/2

	create_rope(pieces_amount, rope_start_piece, end_pos, spawn_angle)


func create_rope(pieces_amount:int, parent:Object, end_pos:Vector2, spawn_angle:float) -> void:
	rope_colors.append(color1)
	var last_color: Color
	for i in pieces_amount:
		last_color = color2 if i % 2 == 0 else color1
		rope_colors.append(last_color)
		
		parent = add_piece(parent, i, spawn_angle)
		parent.set_name("rope_piece_"+str(i))
		rope_parts.append(parent)
		
		var joint_pos: Vector2 = parent.get_node("C/J").global_position
		if joint_pos.distance_to(end_pos) < rope_close_tolerance:
			break
	
	last_color = color1 if last_color == color2 else color2
	rope_colors.append(last_color)
	
	rope_end_joint.node_a = rope_end_piece.get_path()
	rope_end_joint.node_b = rope_parts[-1].get_path()
	

func add_piece(parent:Object, id:int, spawn_angle:float) -> RopePiece:
	var joint : PinJoint2D = parent.get_node("C/J") as PinJoint2D
	var piece : RopePiece = rope_piece.instantiate()
	add_child(piece)
	piece.global_position = joint.global_position
	piece.rotation = spawn_angle
	piece.parent = self
	piece.id = id
	joint.node_a = parent.get_path()
	joint.node_b = piece.get_path()
	return piece


func get_rope_points() -> void:
	rope_points = []
	var offset: Vector2 = global_position
	rope_points.append(rope_start_joint.global_position - offset)
	for r: RopePiece in rope_parts:
		rope_points.append(r.global_position - offset)
	rope_points.append(rope_end_joint.global_position - offset)


func _draw() -> void:
	if rope_points.size() > 2:
		#draw_line(rope_start_joint.global_position, rope_end_joint.global_position, Color.AQUA)
		draw_polyline(rope_points, Color.BLACK, 3.0, false)
		#draw_polyline_colors(rope_points, rope_colors, 2.0, false)

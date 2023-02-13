extends Spatial

class_name MoveAgent

#var nav : Navigation
var target : Spatial

var move_speed = 10.0
var move_vec : Vector3

var path = []
var path_ind = 0

func _ready():
	target = get_tree().get_nodes_in_group("target")[0]
	#nav = get_tree().get_nodes_in_group("navigation")[0]

func _physics_process(delta):
	update_move_vec()
	global_translate(move_vec * move_speed * delta)

func get_target_move_pos():
	return target.global_transform.origin

var last_straight_line_check = false
func update_move_vec():
	var our_pos = global_transform.origin
	our_pos.y = 0.0
	
	var straight_line_check = can_move_in_straight_line()
	if !straight_line_check:
		if last_straight_line_check:
			path = [get_target_move_pos()]
			path_ind = 0
		PathfindManager.calc_path(self)
	
	if straight_line_check:
		var target_pos = get_target_move_pos()
		target_pos.y = 0.0
		move_vec = our_pos.direction_to(target_pos)
	elif path_ind < path.size():
		var next_path_pos = path[path_ind]
		next_path_pos.y = 0.0
		while our_pos.distance_squared_to(next_path_pos) < 0.1*0.1 and path_ind < path.size() - 1:
			path_ind += 1
			next_path_pos = path[path_ind]
			next_path_pos.y = 0.0
		move_vec = our_pos.direction_to(next_path_pos)
	
	last_straight_line_check = straight_line_check

var char_radius = 0.5
var char_height = 1.0
var min_dist_to_check_los = 20.0
func can_move_in_straight_line():
	var pos = global_transform.origin + Vector3.UP * char_height
	var target_pos = target.global_transform.origin + Vector3.UP * char_height
	
	if pos.distance_squared_to(target_pos) > min_dist_to_check_los*min_dist_to_check_los:
		return false
	
	var right : Vector3 = target_pos - pos
	right.y = 0.0
	right = right.rotated(Vector3.UP, PI/2.0).normalized()
	
	var ray_right_start_pos = pos + right * char_radius
	var ray_left_start_pos = pos + -right * char_radius
	
	var ray_right_end_pos = target_pos + right * char_radius
	var ray_left_end_pos = target_pos + -right * char_radius
	
	var space_state = get_world().direct_space_state
	var los_left = space_state.intersect_ray(ray_left_start_pos, ray_left_end_pos, [], 1).size() == 0
	var los_right = space_state.intersect_ray(ray_right_start_pos, ray_right_end_pos, [], 1).size() == 0
	
	return los_left and los_right
	
func update_path(_path: Array):
	if _path.size() == 0:
		return
	path = _path
	path_ind = 0

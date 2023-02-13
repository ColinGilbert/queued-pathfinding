extends Node


var queue = []
var cache = {}
var map
var paths_calc_per_turn = 1
onready var navigation_mesh_instance

func setup_navserver():
	# create a new navigation map
	map = NavigationServer.map_create()
	NavigationServer.map_set_up(map, Vector3.UP)
	NavigationServer.map_set_active(map, true)

	# create a new navigation region and add it to the map
	var region = NavigationServer.region_create()
	NavigationServer.region_set_transform(region, Transform())
	NavigationServer.region_set_map(region, map)

	# sets navigation mesh for the region
	var navigation_mesh = NavigationMesh.new()
	navigation_mesh = navigation_mesh_instance. navmesh
	NavigationServer.region_set_navmesh(region, navigation_mesh)

	# wait for NavigationServer sync to adapt to made changes
	yield(get_tree(), "physics_frame")
	
func _ready():
	# use call deferred to make sure the entire SceneTree Nodes are setup
	# else yield on 'physics_frame' in a _ready() might get stuck
	call_deferred("setup_navserver")
	
func _physics_process(delta):
	for _i in range(paths_calc_per_turn):
		dequeue_path_request()

func dequeue_path_request():
	if queue.size() == 0:
		return
	var calc_path_info = queue.pop_front()
	var agent: MoveAgent = calc_path_info.agent
	#var nav: Navigation = calc_path_info.nav
	var start_pos = agent.global_transform.origin
	var end_pos = agent.get_target_move_pos()
	var new_path = NavigationServer.map_get_path(map, start_pos, end_pos, true)
	cache.erase(str(agent))
	agent.update_path(new_path)

func calc_path(agent: MoveAgent):
	var key = str(agent)
	if key in cache:
		return
	cache[key] = ""
	queue.append({
		"agent": agent
	})

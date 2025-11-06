extends Node2D

@onready var path_2d = $Path2D
@onready var main_path_follow = $Path2D/PathFollow2D
@onready var enemy_spawn_timer = $EnemySpawnTimer

func _ready():
	print("=== SIMPLE TOWER TEST ===")
	
	# Spawn first tower
	await get_tree().create_timer(0.5).timeout  
	spawn_tower()
	
	# Start spawning enemies every 3 seconds
	start_enemy_spawning()

func start_enemy_spawning():
	print("Starting enemy spawner - new enemy every 3 seconds")
	
	# Spawn first enemy immediately
	spawn_enemy()
	
	# Start timer for subsequent enemies
	enemy_spawn_timer.wait_time = 3.0
	enemy_spawn_timer.timeout.connect(spawn_enemy)
	enemy_spawn_timer.start()

func spawn_enemy():
	print("Spawning enemy...")
	var enemy_scene = load("res://scenes/enemies/basic_enemy.tscn")
	var enemy = enemy_scene.instantiate()
	
	# Create a NEW PathFollow2D for this enemy
	var new_path_follow = PathFollow2D.new()
	path_2d.add_child(new_path_follow)
	new_path_follow.progress = 0  # Start at beginning
	
	# Make sure enemy is in correct group
	enemy.add_to_group("enemies")
	
	enemy.max_health = 600
	enemy.health = 100
	enemy.speed = 50
	enemy.path_follow = new_path_follow
	
	# Clean up PathFollow2D when enemy is removed
	enemy.tree_exiting.connect(func(): new_path_follow.queue_free())
	
	$Enemies.add_child(enemy)
	print("Enemy spawned at start of path")

func spawn_tower():
	print("Spawning tower...")
	var tower_scene = load("res://scenes/towers/basic_tower.tscn")
	var tower = tower_scene.instantiate()
	
	# Place tower close to the path
	tower.global_position = Vector2(800, 400)
	
	$Towers.add_child(tower)
	
	if tower.has_method("place"):
		tower.place()
	
	print("Tower spawned at position: ", tower.global_position)

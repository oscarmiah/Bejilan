extends Area2D

@export var speed: float = 100.0
@export var health: float = 100.0
@export var max_health: float = 100.0
@export var damage: int = 10  # Damage dealt to base when reaching end
@export var gold_reward: int = 5  # Gold player gets for killing this enemy
@export var is_flying: bool = false  # Flying enemies might ignore certain towers

var path_follow: PathFollow2D
var is_alive: bool = true
var current_slow_effects: int = 0
var base_speed: float

signal enemy_died(gold_reward)
signal enemy_reached_end(damage)
signal health_changed(current_health, max_health)

@onready var health_bar_fill = $HealthBar/Fill
@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer

func _ready():
	health = max_health
	base_speed = speed
	update_health_bar()
	
	# Connect area entered for tower projectiles
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _process(delta):
	if not path_follow or not is_alive:
		return
	
	# Move along path
	path_follow.progress += speed * delta
	global_position = path_follow.global_position
	
	# Rotate enemy to follow path direction (optional)
	update_rotation()
	
	# Check if reached end of path
	if path_follow.progress_ratio >= 0.99:
		reach_end()

func _on_area_entered(area: Area2D):
	# Handle projectile hits
	if area.is_in_group("projectiles") and area.has_method("get_damage"):
		var projectile_damage = area.get_damage()
		take_damage(projectile_damage)
		
		# Apply slow effect if projectile has one
		if area.has_method("get_slow_effect"):
			apply_slow_effect(area.get_slow_effect())
		
		# Destroy projectile
		if area.has_method("on_hit"):
			area.on_hit()
		else:
			area.queue_free()

func _on_body_entered(body: Node):
	# Handle other collisions if needed
	pass

func take_damage(amount: float):
	if not is_alive:
		return
	
	health -= amount
	health_changed.emit(health, max_health)
	update_health_bar()
	
	# Visual feedback for taking damage
	if animation_player:
		if animation_player.has_animation("hit"):
			animation_player.play("hit")
	else:
		# Simple flash effect as fallback
		create_tween().tween_property(sprite, "modulate", Color.RED, 0.1)
		create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if health <= 0:
		die()

func update_health_bar():
	if health_bar_fill:
		var health_ratio = health / max_health
		health_bar_fill.scale.x = health_ratio
		
		# Change color based on health
		if health_ratio > 0.6:
			health_bar_fill.color = Color.GREEN
		elif health_ratio > 0.3:
			health_bar_fill.color = Color.YELLOW
		else:
			health_bar_fill.color = Color.RED

func update_rotation():
	# Make enemy face the direction they're moving
	if path_follow and path_follow.progress > 1.0:
		var current_pos = path_follow.global_position
		path_follow.progress += 0.1
		var next_pos = path_follow.global_position
		path_follow.progress -= 0.1
		
		var direction = (next_pos - current_pos).normalized()
		rotation = direction.angle()

func apply_slow_effect(slow_data: Dictionary):
	# slow_data should contain: { "duration": 2.0, "intensity": 0.5 }
	if not slow_data.has("duration") or not slow_data.has("intensity"):
		return
	
	current_slow_effects += 1
	var original_speed = speed
	speed = base_speed * slow_data["intensity"]
	
	# Reset speed after duration
	await get_tree().create_timer(slow_data["duration"]).timeout
	
	current_slow_effects -= 1
	if current_slow_effects <= 0:
		speed = base_speed
		current_slow_effects = 0

func die():
	if not is_alive:
		return
	
	is_alive = false
	
	# Play death animation if available
	if animation_player:
		if animation_player.has_animation("die"):
			animation_player.play("die")
			await animation_player.animation_finished
	else:
		# Simple death effect
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(sprite, "scale", Vector2(0, 0), 0.2)
		await tween.finished
	
	enemy_died.emit(gold_reward)
	queue_free()

func reach_end():
	if not is_alive:
		return
	
	is_alive = false
	enemy_reached_end.emit(damage)
	queue_free()

# Method for the base to call when enemy reaches it
func get_enemy_damage() -> int:
	return damage

func reached_base():
	# This would be called by the base script
	reach_end()

# Utility functions
func set_path(new_path_follow: PathFollow2D):
	path_follow = new_path_follow
	global_position = path_follow.global_position

func get_health_percentage() -> float:
	return health / max_health

func is_flying_enemy() -> bool:
	return is_flying

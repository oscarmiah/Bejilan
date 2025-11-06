extends StaticBody2D

@onready var enemy_hitarea: Area2D = $enemyHitarea
@onready var health_bar: ProgressBar = $HealthBar  # Optional: if you have a health bar UI

# Base stats
@export var max_health: int = 100
var current_health: int

# Game state
var is_destroyed: bool = false

func _ready():
	current_health = max_health
	
	# Connect the area entered signal to detect enemies
	enemy_hitarea.area_entered.connect(_on_enemy_entered)
	enemy_hitarea.body_entered.connect(_on_enemy_entered)
	
	# Update health bar if it exists
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

func _on_enemy_entered(area_or_body):
	# Check if the entering object is an enemy
	if area_or_body.is_in_group("enemies") or area_or_body.has_method("get_enemy_damage"):
		take_damage(area_or_body.get_enemy_damage())
		
		# Optional: destroy the enemy when it reaches the base
		if area_or_body.has_method("reached_base"):
			area_or_body.reached_base()

func take_damage(damage: int):
	if is_destroyed:
		return
		
	current_health -= damage
	current_health = max(0, current_health)  # Ensure health doesn't go below 0
	
	# Update health bar
	if health_bar:
		health_bar.value = current_health
	
	# Visual feedback (optional)

	
	# Check if base is destroyed
	if current_health <= 0:
		destroy_base()

func destroy_base():
	is_destroyed = true
	print("Base destroyed!")
	
	# Play destruction animation

	
	# Emit signal that base was destroyed
	base_destroyed.emit()
	
	# Game over logic would typically be handled by a game manager
	# get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

# Function to heal/repair the base
func heal(amount: int):
	current_health += amount
	current_health = min(current_health, max_health)
	
	if health_bar:
		health_bar.value = current_health

# Get current health percentage (useful for UI)
func get_health_percentage() -> float:
	return float(current_health) / float(max_health)

# Signal to notify when base is destroyed
signal base_destroyed

# Optional: Reset base for new level/game
func reset_base():
	current_health = max_health
	is_destroyed = false
	
	if health_bar:
		health_bar.value = current_health
	
	# Reset visual appearance
	$Sprite2D.visible = true

extends Node

const ItemVariant = preload("res://item_variants.gd").ItemVariant

@export var min_distance_from_anthill = 100
@export var stick_spawn_probability = 0.5

@onready var anthill = get_node("/root/Game/Anthill")
@onready var spawn_sound: AudioStreamPlayer = $SpawnSound
var scene_item: PackedScene

func get_random_position() -> Vector2:
	# Get the viewport size in pixels
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size

	# Generate a random position within the viewport (screen space)
	var random_screen_x: float = randf_range(0, viewport_size.x)
	var random_screen_y: float = randf_range(0, viewport_size.y)
	var random_screen_position: Vector2 = Vector2(random_screen_x, random_screen_y)

	# Convert the random screen position to world coordinates using the canvas transform
	var world_position: Vector2 = get_viewport().canvas_transform.affine_inverse() * random_screen_position

	return world_position

func get_random_valid_position() -> Vector2:
	while true:
		var position: Vector2 = get_random_position()
		if position.distance_to(anthill.position) < min_distance_from_anthill:
			continue
		var rock_conflict = false
		for rock in get_tree().get_nodes_in_group("rocks"):
			if position.distance_to(rock.position) < 64:
				rock_conflict = true
				break
		if rock_conflict:
			continue
		return position
	
	# raise an error if no valid position is found
	assert(false, "No valid position found")
	return Vector2.ZERO # unreachable, but the linter is dumb


func _ready():
	randomize()
	await get_tree().create_timer(1).timeout
	spawn_item(ItemVariant.LEAF, get_random_valid_position())
	spawn_item(ItemVariant.MUSHROOM, get_random_valid_position())


# Function to spawn an item at a given position
func spawn_item(variant: ItemVariant, position: Vector2):
	scene_item = load("res://scene_item.tscn")

	var new_item = scene_item.instantiate()
	new_item.position = position
	new_item.scale = Vector2.ZERO

	# Play the spawn sound
	spawn_sound.play()

	# Add the item to the scene first so the variants can be initialised
	add_child(new_item)
	new_item.set_variant(variant)


	var tween = create_tween()
	(tween
	.tween_property(new_item, "scale", Vector2.ONE, 1.0)
	.set_ease(Tween.EASE_OUT)
	.set_trans(Tween.TRANS_SPRING))


func get_random_variant() -> ItemVariant:
	if randf() < stick_spawn_probability:
		return ItemVariant.STICK
	else:
		var food_variants = [ItemVariant.LEAF, ItemVariant.MUSHROOM]
		return food_variants[randi() % len(food_variants)]

func _on_item_spawn_timer_timeout() -> void:
	spawn_item(get_random_variant(), get_random_valid_position())

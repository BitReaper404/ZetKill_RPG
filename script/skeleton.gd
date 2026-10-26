extends CharacterBody2D

const SPEED: float = 100.0
const KNOCKBACK_FORCE: float = 100.0
const KNOCKBACK_DECELERATION: float = 500.0
const HIT_STUN_TIME: float = 0.3

var health: int = 100
var target: Node2D = null

var is_taking_damage: bool = false
var is_dead: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var hit_stun_left: float = 0.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var take_damage_voice: AudioStreamPlayer2D = $take_damage


func _physics_process(delta: float) -> void:
	# Do nothing while dying.
	if is_dead:
		return

	# Handle knockback and hit stun (timer based, no awaits).
	if is_taking_damage:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(
			Vector2.ZERO,
			KNOCKBACK_DECELERATION * delta
		)
		move_and_slide()

		hit_stun_left -= delta
		if hit_stun_left <= 0.0 and knockback_velocity.length() <= 5.0:
			is_taking_damage = false
			knockback_velocity = Vector2.ZERO
		return

	# Chase the player.
	if is_instance_valid(target):
		_attack()
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		_play_if_different("idle_right_enemy")


func _attack() -> void:
	var direction: Vector2 = (
		target.global_position - global_position
	).normalized()

	velocity = direction * SPEED
	move_and_slide()

	# Face the direction of movement.
	if absf(direction.x) > 0.01:
		animated_sprite_2d.flip_h = direction.x < 0.0

	_play_if_different("run_right_enemy")


func _play_if_different(anim_name: StringName) -> void:
	if animated_sprite_2d.animation != anim_name or not animated_sprite_2d.is_playing():
		animated_sprite_2d.play(anim_name)


func take_damage(damage: int, attacker_position: Vector2) -> void:
	# Ignore additional hits while dying.
	take_damage_voice.play()
	if is_dead:
		return

	health -= damage
	print("Enemy health: ", health)

	# Die when health reaches zero.
	if health <= 0:
		die()
		return

	# Play the damage sound.

	# Enter hit stun. Restarting the timer makes repeated hits safe.
	is_taking_damage = true
	hit_stun_left = HIT_STUN_TIME

	# Restart the damage animation even if it is already playing.
	animated_sprite_2d.stop()
	animated_sprite_2d.play("damage")

	# Calculate the direction of the knockback.
	var knockback_direction: Vector2 = (
		global_position - attacker_position
	).normalized()

	# Handle the case where both positions are identical.
	if knockback_direction == Vector2.ZERO:
		knockback_direction = Vector2.RIGHT

	knockback_velocity = knockback_direction * KNOCKBACK_FORCE


func die() -> void:
	if is_dead:
		return

	is_dead = true
	is_taking_damage = false
	target = null
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO

	# Stop colliding with / being hit by anything while dying.
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	# Stop any currently playing sound.
	take_damage_voice.stop()

	# Make sure the death animation can actually finish (a looping
	# animation never emits animation_finished).
	animated_sprite_2d.sprite_frames.set_animation_loop("death", false)
	animated_sprite_2d.play("death")

	# Wait for the death animation to finish.
	await animated_sprite_2d.animation_finished

	# Remove the enemy from the scene.
	queue_free()


func _on_sight_body_entered(body: Node2D) -> void:
	if is_dead:
		return

	if body.is_in_group("player"):
		target = body


func _on_sight_body_exited(body: Node2D) -> void:
	if body == target:
		target = null

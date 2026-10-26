extends CharacterBody2D


const SPEED = 100.0
const KNOCKBACK_FORCE = 100
var health: int = 100
var target = null


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var take_damage_voice: AudioStreamPlayer2D = $take_damage

func _physics_process(delta: float) -> void:
	if target:
		_attack(delta)
	else:
		animated_sprite_2d.play("idle_right_enemy")


func _attack(delta: float) -> void:
	var direction = (target.position - position).normalized()
	position += direction * SPEED * delta
	animated_sprite_2d.play("attack")

func take_damage(damage: int, attacker_position: Vector2) -> void:
	health -= damage
	take_damage_voice.play()
	print(health)
	#knockback
	var knockback_direction=(position-attacker_position).normalized()
	var target_position = position + knockback_direction * KNOCKBACK_FORCE
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", target_position, 0.5)

func _on_sight_body_entered(body: Node2D) -> void:
	if body.name == "player":
		target = body
		print("target")


func _on_sight_body_exited(body: Node2D) -> void:
	if body.name == "player":
		target = null
		animated_sprite_2d.play("idle_right_enemy")

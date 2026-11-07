extends Resource
class_name AbilityResource

@export var id: String = ""
@export var display_name: String = ""
@export var unlock_level: int = 1
@export var energy_cost: int = 10
@export var cooldown: float = 5.0
@export var power: float = 1.0
@export var ability_type: String = "aoe"   # aoe|clones|buff|projectile
@export var description: String = ""
@export var icon: Texture2D

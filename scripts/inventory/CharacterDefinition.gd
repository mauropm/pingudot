extends Resource
class_name CharacterDefinition
## A playable character template. Data lives in res://data/characters.json.

@export var id: String = "pingu"
@export var display_name: String = "PINGU"
@export var title: String = "THE SYSADMIN"
@export var specialty: String = ""
@export var status: String = "USER"
@export var tagline: String = ""
@export var atlas_path: String = "res://assets/characters/pingu.png"
@export var stats: Dictionary = {}
@export var abilities: Array[String] = []
@export var ultimate_id: String = ""
@export var start_item: String = ""
@export var unlocked_by_default := true

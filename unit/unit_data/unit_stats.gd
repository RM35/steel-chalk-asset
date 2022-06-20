extends Resource

class_name unit_stats

export(String) var unit_name
export(int) var health
export(int) var attack
export(int) var level
enum RARITY{COMMON, UNCOMMON, RARE, LEGENDARY}
export(RARITY) var rarity
export(Rect2) var sprite_region_rect

enum ABILITY_TRIGGER{ON_SELL, ON_BUY, ON_FAINT, ON_DAMAGE, ON_ATTACK}
export(ABILITY_TRIGGER) var ability_trigger

enum ABILITY_OUTPUT{DAMAGE, CHANGE_HEALTH, CHANGE_ATTACK, CHANGE_GOLD, SUMMON_NEW, AOE_DAMAGE}
export(ABILITY_OUTPUT) var ability_output

export(int) var ability_parameters


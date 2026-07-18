class_name DamageCalculator
extends RefCounted

## Pure deterministic damage calculation. Non-negative products use explicit
## half-up rounding so results do not depend on presentation or physics.


static func calculate_damage(
	base_damage: int,
	attacker_damage_multiplier: float,
	ability_damage_multiplier: float,
	target_damage_taken_multiplier: float
) -> int:
	var raw_damage: float = (
		float(maxi(base_damage, 0))
		* maxf(attacker_damage_multiplier, 0.0)
		* maxf(ability_damage_multiplier, 0.0)
		* maxf(target_damage_taken_multiplier, 0.0)
	)
	return maxi(int(floor(raw_damage + 0.5)), 0)

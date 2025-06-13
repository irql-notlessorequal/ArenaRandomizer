# Loadouts.

The `loadouts.json` contains all the loadout rounds in Arena Randomizer.

## Layout

```
{
	"name": [string] (mandatory)
	"keep_weapons": [boolean] (optional)
	"classes": { (optional)
		/* One of the following MUST be present. */
		"all": [string]
		"blue": [string]
		"red": [string]
		"keep": [boolean]
	},
	"weapons": [ (optional)
		{
			"id": [integer] (mandatory)
			"name": [string] (mandatory)
			"slot": [string] (mandatory)

			"team": [string] (optional)
			"holiday": [string] (optional)

			"ammo_clip": [integer] (optional)
			"ammo_reserve": [integer] (optional)

			"attributes": [ (optional)
				{
					"id": [integer] (mandatory)
					"name": [string] (UNUSED)
					"value": [integer/float] (mandatory)
				}
			]
		}
	],
	"attributes": { (optional)
		"round_start_audio": [array/string] (optional)
		"round_end_audio": [array/string] (optional)
		"on_kill": [array/string] (optional)
		"hp": [integer] (optional)
		"max_hp": [integer] (optional)
		"ammo_regen": [integer] (optional)
		"movement_speed": [float] (optional)
		"model_scale": [float] (optional)
		"conditions": [ (optional)
			{
				"id": [integer] (mandatory)
				"duration": [float] (mandatory)
			}
		]
	},
	"special_round": [boolean] (optional)
}
```

### `name`

The name of the round, as a *string*, this will be shown to the players.

### `keep_weapons`

*boolean* flag that tells Arena Randomizer not to clear weapons.

*Will likely be moved into the attributes object at a future date.*

### `classes`

Controls what classes are applied on players.

Special values for `red` and `blue`:
- `random-shared` sets a random class for the team.

Special values for `all`:

- `random` sets a random class per player.
- `random-shared` sets a random class for everyone.

`keep` will as the name implies not change the classes for players, allowing them to change them if they wish to.

### `weapons`

TODO

**REMINDER**: This array will be iterated in reverse, so the first entry will be what the player
has equipped by default.

### `attributes`

TODO

### `special_round`

*boolean* flag to indicate that this is a non-standard round, if set
different audio and UI indicators will be used at the start of the round.

## Holidays

The following holidays are supported:

- `none` (No holiday present)
- `halloween` (Halloween)
- `christmas` (Christmas)
- `full_moon` (Full Moon)
- `april_fools` (April Fools)

You can add `!` in front of a holiday to negate the condition.

For example, `!christmas` will be _TRUE_ if it is **NOT** Christmas.
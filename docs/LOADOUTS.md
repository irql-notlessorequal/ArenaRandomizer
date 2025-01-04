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

Special values for `all`:

- `random` sets a random class per player.
- `random-shared` sets a random class for everyone.

`keep` will as the name implies not change the classes for players, allowing them to change them if they wish to.

### `weapons`

TODO

### `attributes`

TODO

### `special_round`

*boolean* flag to indicate that this is a non-standard round, if set
different audio and UI indicators will be used at the start of the round.
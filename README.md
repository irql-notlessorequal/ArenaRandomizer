Arena Randomizer is a modern rewrite and remake of [TF2TightRope](https://wiki.teamfortress.com/wiki/TF2Tightrope)'s Project Ghost.

Now with:
- More loadouts
- Easier loadout creation
- Special rounds

## Requirements

In order to compile Arena Randomizer:

- a copy of [smjson](https://github.com/clugg/sm-json) is required.

- a copy of [Mallet](https://github.com/irql-notlessorequal/Mallet/) is required.

- a copy of [moarcolors](https://github.com/DoctorMcKay/sourcemod-plugins/blob/master/scripting/include/morecolors.inc) is required.

## Installation

1. Compile the gamemode.

   Optional SteamWorks integration is available with the `STEAMWORKS=1` build time define.

2. Install the compiled `.smx` into your server's plugins folder.

3. Copy the gamemode's sounds from `assets/sound` into your server's sound folder.

	Optionally you should also copy it over to your FastDL server.

4. Copy the gamemode's `loadouts.json` into the following nested folder: `tf/cfg/hmmr/arena-randomizer`

5. Launch any arena map and have fun!

## License

```
Arena Randomizer, a remake of TF2TightRope's Project Ghost
Copyright (C) 2025  IRQL_NOT_LESS_OR_EQUAL

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, see
<https://www.gnu.org/licenses/>.
```
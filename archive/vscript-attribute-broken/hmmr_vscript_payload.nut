/**
 * Since there is an official Team Fortress 2 method for doing this,
 * might as well use this as a workaround.
 */

::GetPlayerName <-  function(player) {
	return NetProps.GetPropString(player, "m_szNetname");
}

function hmmr_assign_weapon_attribute(_player, weaponIdx, attribute, value) {
	local player = PlayerInstanceFromIndex(_player);
	if (player == null) {
		printl("hmmr_assign_weapon_attribute:: Unable to find player... (_player=" + _player + ")")
		return false;
	}

	local weapon;
	weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", weaponIdx);

	printl("_player=" + _player + ", player=" + player + ", [name=" + GetPlayerName(player) + "] weapon=" + weapon + ", weaponIdx=" + weaponIdx);

	if (weapon == null) {
		printl("hmmr_assign_weapon_attribute:: Unable to find wanted weapon...")
		return false;
	} else {
		printl("hmmr_assign_weapon_attribute:: Applying attribute...")
		/* This will fail since we need to convert to string form :( */
		weapon.AddAttribute(attribute, value, -1);
		return true;
	}
}


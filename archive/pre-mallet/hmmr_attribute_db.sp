#include <json>

methodmap IntMapSnapshot < Handle
{
	// Returns the number of keys in the map snapshot.
	property int Length
	{
		public get()
		{
			return view_as<StringMapSnapshot>(this).Length;
		}
	}
	
	// Retrieves the key of a given index in a map snapshot.
	// 
	// @param index      Key index (starting from 0).
	// @return           The key.
	// @error            Index out of range.
	public int GetKey(int index)
	{
		if (index < 0 || index >= this.Length)
		{
			ThrowError("Index out of range");
		}
		
		char buffer[255];
		view_as<StringMapSnapshot>(this).GetKey(index, buffer, sizeof(buffer));
		return StringToInt(buffer);
	}
}

methodmap IntMap < Handle
{
	// The IntMap must be freed via delete or CloseHandle().
	public IntMap()
	{
		return view_as<IntMap>(new StringMap());
	}
	
	// Sets a value in a Map, either inserting a new entry or replacing an old one.
	//
	// @param key        The key.
	// @param value      Value to store at this key.
	// @param replace    If false, operation will fail if the key is already set.
	// @return           True on success, false on failure.
	public bool SetValue(int key, any value, bool replace = true)
	{
		char buffer[255];
		IntToString(key, buffer, sizeof(buffer));
		return view_as<StringMap>(this).SetValue(buffer, value, replace);
	}
	
	// Sets an array value in a Map, either inserting a new entry or replacing an old one.
	//
	// @param key        The key.
	// @param array      Array to store.
	// @param num_items  Number of items in the array.
	// @param replace    If false, operation will fail if the key is already set.
	// @return           True on success, false on failure.
	public bool SetArray(int key, const any[] array, int num_items, bool replace = true)
	{
		char buffer[255];
		IntToString(key, buffer, sizeof(buffer));
		return view_as<StringMap>(this).SetArray(buffer, array, num_items, replace);
	}
	
	// Sets a string value in a Map, either inserting a new entry or replacing an old one.
	//
	// @param key        The key.
	// @param value      String to store.
	// @param replace    If false, operation will fail if the key is already set.
	// @return           True on success, false on failure.
	public bool SetString(int key, const char[] value, bool replace = true)
	{
		char buffer[255];
		IntToString(key, buffer, sizeof(buffer));
		return view_as<StringMap>(this).SetString(buffer, value, replace);
	}
	
	// Retrieves a value in a Map.
	//
	// @param key        The key.
	// @param value      Variable to store value.
	// @return           True on success.  False if the key is not set, or the key is set 
	//                   as an array or string (not a value).
	public bool GetValue(int key, any& value)
	{
		char buffer[255];
		IntToString(key, buffer, sizeof(buffer));
		return view_as<StringMap>(this).GetValue(buffer, value);
	}
	
	// Retrieves an array in a Map.
	//
	// @param key        The key.
	// @param array      Buffer to store array.
	// @param max_size   Maximum size of array buffer.
	// @param size       Optional parameter to store the number of elements written to the buffer.
	// @return           True on success.  False if the key is not set, or the key is set 
	//                   as a value or string (not an array).
	public bool GetArray(int key, any[] array, int max_size, int& size = 0)
	{
		char buffer[255];
		IntToString(key, buffer, sizeof(buffer));
		return view_as<StringMap>(this).GetArray(buffer, array, max_size, size);
	}
	
	// Retrieves a string in a Map.
	//
	// @param key        The key.
	// @param value      Buffer to store value.
	// @param max_size   Maximum size of string buffer.
	// @param size       Optional parameter to store the number of bytes written to the buffer.
	// @return           True on success.  False if the key is not set, or the key is set 
	//                   as a value or array (not a string).
	public bool GetString(int key, char[] value, int max_size, int& size = 0)
	{
		char buffer[255];
		IntToString(key, buffer, sizeof(buffer));
		return view_as<StringMap>(this).GetString(buffer, value, max_size, size);
	}
	
	// Removes a key entry from a Map.
	//
	// @param key        The key.
	// @return           True on success, false if the value was never set.
	public bool Remove(int key)
	{
		char buffer[255];
		IntToString(key, buffer, sizeof(buffer));
		return view_as<StringMap>(this).Remove(buffer);
	}
	
	// Clears all entries from a Map.
	public void Clear()
	{
		view_as<StringMap>(this).Clear();
	}
	
	// Create a snapshot of the map's keys. See IntMapSnapshot.
	public IntMapSnapshot Snapshot()
	{
		return view_as<IntMapSnapshot>(view_as<StringMap>(this).Snapshot());
	}
	
	// Retrieves the number of elements in a map.
	property int Size
	{
		public get()
		{
			return view_as<StringMap>(this).Size;
		}
	}
}

IntMap __GenerateAttributeDB()
{
	IntMap DB = new IntMap();
    DB.SetString(1, "damage penalty");
    DB.SetString(2, "damage bonus");
    DB.SetString(3, "clip size penalty");
    DB.SetString(4, "clip size bonus");
    DB.SetString(5, "fire rate penalty");
    DB.SetString(6, "fire rate bonus");
    DB.SetString(7, "heal rate penalty");
    DB.SetString(8, "heal rate bonus");
    DB.SetString(9, "ubercharge rate penalty");
    DB.SetString(10, "ubercharge rate bonus");
    DB.SetString(11, "overheal bonus");
    DB.SetString(12, "overheal decay penalty");
    DB.SetString(13, "overheal decay bonus");
    DB.SetString(14, "overheal decay disabled");
    DB.SetString(15, "crit mod disabled");
    DB.SetString(16, "heal on hit for rapidfire");
    DB.SetString(17, "add uber charge on hit");
    DB.SetString(18, "medigun charge is crit boost");
    DB.SetString(19, "tmp dmgbuff on hit");
    DB.SetString(20, "crit vs burning players");
    DB.SetString(21, "dmg penalty vs nonburning");
    DB.SetString(22, "no crit vs nonburning");
    DB.SetString(23, "mod flamethrower push");
    DB.SetString(24, "mod flamethrower back crit");
    DB.SetString(25, "hidden secondary max ammo penalty");
    DB.SetString(26, "max health additive bonus");
    DB.SetString(27, "alt-fire disabled");
    DB.SetString(28, "crit mod disabled hidden");
    DB.SetString(30, "fists have radial buff");
    DB.SetString(31, "critboost on kill");
    DB.SetString(32, "slow enemy on hit");
    DB.SetString(33, "set cloak is feign death");
    DB.SetString(34, "mult cloak meter consume rate");
    DB.SetString(35, "mult cloak meter regen rate");
    DB.SetString(36, "spread penalty");
    DB.SetString(37, "hidden primary max ammo bonus");
    DB.SetString(38, "mod bat launches balls");
    DB.SetString(39, "dmg penalty vs nonstunned");
    DB.SetString(40, "zoom speed mod disabled");
    DB.SetString(41, "sniper charge per sec");
    DB.SetString(42, "sniper no headshots");
    DB.SetString(43, "scattergun no reload single");
    DB.SetString(44, "scattergun has knockback");
    DB.SetString(45, "bullets per shot bonus");
    DB.SetString(46, "sniper zoom penalty");
    DB.SetString(47, "sniper no charge");
    DB.SetString(48, "set cloak is movement based");
    DB.SetString(49, "no double jump");
    DB.SetString(50, "absorb damage while cloaked");
    DB.SetString(51, "revolver use hit locations");
    DB.SetString(52, "backstab shield");
    DB.SetString(53, "fire retardant");
    DB.SetString(54, "move speed penalty");
    DB.SetString(55, "obsolete ammo penalty");
    DB.SetString(56, "jarate description");
    DB.SetString(57, "health regen");
    DB.SetString(58, "self dmg push force increased");
    DB.SetString(59, "self dmg push force decreased");
    DB.SetString(60, "dmg taken from fire reduced");
    DB.SetString(61, "dmg taken from fire increased");
    DB.SetString(62, "dmg taken from crit reduced");
    DB.SetString(63, "dmg taken from crit increased");
    DB.SetString(64, "dmg taken from blast reduced");
    DB.SetString(65, "dmg taken from blast increased");
    DB.SetString(66, "dmg taken from bullets reduced");
    DB.SetString(67, "dmg taken from bullets increased");
    DB.SetString(68, "increase player capture value");
    DB.SetString(69, "health from healers reduced");
    DB.SetString(70, "health from healers increased");
    DB.SetString(71, "weapon burn dmg increased");
    DB.SetString(72, "weapon burn dmg reduced");
    DB.SetString(73, "weapon burn time increased");
    DB.SetString(74, "weapon burn time reduced");
    DB.SetString(75, "aiming movespeed increased");
    DB.SetString(76, "maxammo primary increased");
    DB.SetString(77, "maxammo primary reduced");
    DB.SetString(78, "maxammo secondary increased");
    DB.SetString(79, "maxammo secondary reduced");
    DB.SetString(80, "maxammo metal increased");
    DB.SetString(81, "maxammo metal reduced");
    DB.SetString(82, "cloak consume rate increased");
    DB.SetString(83, "cloak consume rate decreased");
    DB.SetString(84, "cloak regen rate increased");
    DB.SetString(85, "cloak regen rate decreased");
    DB.SetString(86, "minigun spinup time increased");
    DB.SetString(87, "minigun spinup time decreased");
    DB.SetString(88, "max pipebombs increased");
    DB.SetString(89, "max pipebombs decreased");
    DB.SetString(90, "SRifle Charge rate increased");
    DB.SetString(91, "SRifle Charge rate decreased");
    DB.SetString(92, "Construction rate increased");
    DB.SetString(93, "Construction rate decreased");
    DB.SetString(94, "Repair rate increased");
    DB.SetString(95, "Repair rate decreased");
    DB.SetString(96, "Reload time increased");
    DB.SetString(97, "Reload time decreased");
    DB.SetString(98, "selfdmg on hit for rapidfire");
    DB.SetString(99, "Blast radius increased");
    DB.SetString(100, "Blast radius decreased");
    DB.SetString(101, "Projectile range increased");
    DB.SetString(102, "Projectile range decreased");
    DB.SetString(103, "Projectile speed increased");
    DB.SetString(104, "Projectile speed decreased");
    DB.SetString(105, "overheal penalty");
    DB.SetString(106, "weapon spread bonus");
    DB.SetString(107, "move speed bonus");
    DB.SetString(108, "health from packs increased");
    DB.SetString(109, "health from packs decreased");
    DB.SetString(110, "heal on hit for slowfire");
    DB.SetString(111, "selfdmg on hit for slowfire");
    DB.SetString(112, "ammo regen");
    DB.SetString(113, "metal regen");
    DB.SetString(114, "mod mini-crit airborne");
    DB.SetString(115, "mod shovel damage boost");
    DB.SetString(116, "mod soldier buff type");
    DB.SetString(117, "dmg falloff increased");
    DB.SetString(118, "dmg falloff decreased");
    DB.SetString(119, "sticky detonate mode");
    DB.SetString(120, "sticky arm time penalty");
    DB.SetString(121, "stickies detonate stickies");
    DB.SetString(122, "mod demo buff type");
    DB.SetString(123, "speed boost when active");
    DB.SetString(124, "mod wrench builds minisentry");
    DB.SetString(125, "max health additive penalty");
    DB.SetString(126, "sticky arm time bonus");
    DB.SetString(127, "sticky air burst mode");
    DB.SetString(128, "provide on active");
    DB.SetString(129, "health drain");
    DB.SetString(130, "medic regen bonus");
    DB.SetString(131, "medic regen penalty");
    DB.SetString(132, "community description");
    DB.SetString(133, "soldier model index");
    DB.SetString(134, "attach particle effect");
    DB.SetString(135, "rocket jump damage reduction");
    DB.SetString(136, "mod sentry killed revenge");
    DB.SetString(137, "dmg bonus vs buildings");
    DB.SetString(138, "dmg penalty vs players");
    DB.SetString(139, "lunchbox adds maxhealth bonus");
    DB.SetString(140, "hidden maxhealth non buffed");
    DB.SetString(141, "selfmade description");
    DB.SetString(142, "set item tint RGB");
    DB.SetString(143, "custom employee number");
    DB.SetString(144, "lunchbox adds minicrits");
    DB.SetString(145, "taunt is highfive");
    DB.SetString(146, "damage applies to sappers");
    DB.SetString(147, "Wrench index");
    DB.SetString(148, "building cost reduction");
    DB.SetString(149, "bleeding duration");
    DB.SetString(150, "turn to gold");
    DB.SetString(151, "DEPRECATED socketed item definition id DEPRECATED");
    DB.SetString(152, "custom texture lo");
    DB.SetString(153, "cannot trade");
    DB.SetString(154, "disguise on backstab");
    DB.SetString(155, "cannot disguise");
    DB.SetString(156, "silent killer");
    DB.SetString(157, "disguise speed penalty");
    DB.SetString(158, "add cloak on kill");
    DB.SetString(159, "SET BONUS: cloak blink time penalty");
    DB.SetString(160, "SET BONUS: quiet unstealth");
    DB.SetString(161, "flame size penalty");
    DB.SetString(162, "flame size bonus");
    DB.SetString(163, "flame life penalty");
    DB.SetString(164, "flame life bonus");
    DB.SetString(165, "charged airblast");
    DB.SetString(166, "add cloak on hit");
    DB.SetString(167, "disguise damage reduction");
    DB.SetString(168, "disguise no burn");
    DB.SetString(169, "SET BONUS: dmg from sentry reduced");
    DB.SetString(170, "airblast cost increased");
    DB.SetString(171, "airblast cost decreased");
    DB.SetString(172, "purchased");
    DB.SetString(173, "flame ammopersec increased");
    DB.SetString(174, "flame ammopersec decreased");
    DB.SetString(175, "jarate duration");
    DB.SetString(176, "SET BONUS: no death from headshots");
    DB.SetString(177, "deploy time increased");
    DB.SetString(178, "deploy time decreased");
    DB.SetString(179, "minicrits become crits");
    DB.SetString(180, "heal on kill");
    DB.SetString(181, "no self blast dmg");
    DB.SetString(182, "slow enemy on hit major");
    DB.SetString(183, "aiming movespeed decreased");
    DB.SetString(184, "duel loser account id");
    DB.SetString(185, "event date");
    DB.SetString(186, "gifter account id");
    DB.SetString(187, "set supply crate series");
    DB.SetString(188, "preserve ubercharge");
    DB.SetString(189, "elevate quality");
    DB.SetString(190, "active health regen");
    DB.SetString(191, "active health degen");
    DB.SetString(192, "referenced item id low");
    DB.SetString(193, "referenced item id high");
    DB.SetString(194, "referenced item def UPDATED");
    DB.SetString(195, "always tradable");
    DB.SetString(196, "noise maker");
    DB.SetString(197, "halloween item");
    DB.SetString(198, "collection bits DEPRECATED");
    DB.SetString(199, "switch from wep deploy time decreased");
    DB.SetString(200, "enables aoe heal");
    DB.SetString(201, "gesture speed increase");
    DB.SetString(202, "charge time increased");
    DB.SetString(203, "drop health pack on kill");
    DB.SetString(204, "hit self on miss");
    DB.SetString(205, "dmg from ranged reduced");
    DB.SetString(206, "dmg from melee increased");
    DB.SetString(207, "blast dmg to self increased");
    DB.SetString(208, "Set DamageType Ignite");
    DB.SetString(209, "minicrit vs burning player");
    DB.SetString(211, "tradable after date");
    DB.SetString(212, "force level display");
    DB.SetString(214, "kill eater");
    DB.SetString(215, "apply z velocity on damage");
    DB.SetString(216, "apply look velocity on damage");
    DB.SetString(217, "sanguisuge");
    DB.SetString(218, "mark for death");
    DB.SetString(219, "decapitate type");
    DB.SetString(220, "restore health on kill");
    DB.SetString(221, "mult decloak rate");
    DB.SetString(222, "mult sniper charge after bodyshot");
    DB.SetString(223, "mult sniper charge after miss");
    DB.SetString(224, "dmg bonus while half dead");
    DB.SetString(225, "dmg penalty while half alive");
    DB.SetString(226, "honorbound");
    DB.SetString(227, "custom texture hi");
    DB.SetString(228, "makers mark id");
    DB.SetString(229, "unique craft index");
    DB.SetString(230, "mod medic killed revenge");
    DB.SetString(231, "medigun charge is megaheal");
    DB.SetString(232, "mod medic killed minicrit boost");
    DB.SetString(233, "mod medic healed damage bonus");
    DB.SetString(234, "mod medic healed deploy time penalty");
    DB.SetString(235, "mod shovel speed boost");
    DB.SetString(236, "mod weapon blocks healing");
    DB.SetString(237, "mult sniper charge after headshot");
    DB.SetString(238, "minigun no spin sounds");
    DB.SetString(239, "ubercharge rate bonus for healer");
    DB.SetString(240, "reload time decreased while healed");
    DB.SetString(241, "reload time increased hidden");
    DB.SetString(242, "mod medic killed marked for death");
    DB.SetString(243, "mod rage on hit penalty");
    DB.SetString(244, "mod rage on hit bonus");
    DB.SetString(245, "mod rage damage boost");
    DB.SetString(246, "mult charge turn control");
    DB.SetString(247, "no charge impact range");
    DB.SetString(248, "charge impact damage increased");
    DB.SetString(249, "charge recharge rate increased");
    DB.SetString(250, "air dash count");
    DB.SetString(251, "speed buff ally");
    DB.SetString(252, "damage force reduction");
    DB.SetString(253, "mult cloak rate");
    DB.SetString(255, "airblast pushback scale");
    DB.SetString(256, "mult airblast refire time");
    DB.SetString(257, "airblast vertical pushback scale");
    DB.SetString(258, "ammo becomes health");
    DB.SetString(259, "boots falling stomp");
    DB.SetString(260, "deflection size multiplier");
    DB.SetString(261, "set item tint RGB 2");
    DB.SetString(262, "saxxy award category");
    DB.SetString(263, "melee bounds multiplier");
    DB.SetString(264, "melee range multiplier");
    DB.SetString(265, "mod mini-crit airborne deploy");
    DB.SetString(266, "projectile penetration");
    DB.SetString(267, "mod crit while airborne");
    DB.SetString(268, "mult sniper charge penalty DISPLAY ONLY");
    DB.SetString(269, "mod see enemy health");
    DB.SetString(270, "powerup max charges");
    DB.SetString(271, "powerup charges");
    DB.SetString(272, "powerup duration");
    DB.SetString(273, "critboost");
    DB.SetString(274, "ubercharge");
    DB.SetString(275, "cancel falling damage");
    DB.SetString(276, "bidirectional teleport");
    DB.SetString(277, "multiple sentries");
    DB.SetString(278, "effect bar recharge rate increased");
    DB.SetString(279, "maxammo grenades1 increased");
    DB.SetString(280, "override projectile type");
    DB.SetString(281, "energy weapon no ammo");
    DB.SetString(282, "energy weapon charged shot");
    DB.SetString(283, "energy weapon penetration");
    DB.SetString(284, "energy weapon no hurt building");
    DB.SetString(285, "energy weapon no deflect");
    DB.SetString(286, "engy building health bonus");
    DB.SetString(287, "engy sentry damage bonus");
    DB.SetString(288, "no crit boost");
    DB.SetString(289, "centerfire projectile");
    DB.SetString(292, "kill eater score type");
    DB.SetString(293, "kill eater score type 2");
    DB.SetString(294, "kill eater 2");
    DB.SetString(295, "has pipboy build interface");
    DB.SetString(296, "sapper kills collect crits");
    DB.SetString(297, "sniper only fire zoomed");
    DB.SetString(298, "mod ammo per shot");
    DB.SetString(299, "add onhit addammo");
    DB.SetString(300, "electrical airblast DISPLAY ONLY");
    DB.SetString(301, "mod use metal ammo type");
    DB.SetString(302, "expiration date");
    DB.SetString(303, "mod max primary clip override");
    DB.SetString(304, "sniper full charge damage bonus");
    DB.SetString(305, "sniper fires tracer");
    DB.SetString(306, "sniper no headshot without full charge");
    DB.SetString(307, "mod no reload DISPLAY ONLY");
    DB.SetString(308, "sniper penetrate players when charged");
    DB.SetString(309, "crit kill will gib");
    DB.SetString(310, "recall");
    DB.SetString(311, "unlimited quantity");
    DB.SetString(312, "disable weapon hiding for animations");
    DB.SetString(313, "applies snare effect");
    DB.SetString(314, "uber duration bonus");
    DB.SetString(315, "refill_ammo");
    DB.SetString(317, "store sort override DEPRECATED");
    DB.SetString(318, "faster reload rate");
    DB.SetString(319, "increase buff duration");
    DB.SetString(320, "robo sapper");
    DB.SetString(321, "build rate bonus");
    DB.SetString(322, "taunt is press and hold");
    DB.SetString(323, "attack projectiles");
    DB.SetString(324, "accuracy scales damage");
    DB.SetString(325, "currency bonus");
    DB.SetString(326, "increased jump height");
    DB.SetString(327, "building instant upgrade");
    DB.SetString(328, "disable fancy class select anim");
    DB.SetString(329, "airblast vulnerability multiplier");
    DB.SetString(330, "override footstep sound set");
    DB.SetString(331, "spawn with physics toy");
    DB.SetString(332, "fish damage override");
    DB.SetString(333, "SET BONUS: special dsp");
    DB.SetString(334, "bombinomicon effect on death");
    DB.SetString(335, "clip size bonus upgrade");
    DB.SetString(336, "hide enemy health");
    DB.SetString(337, "subtract victim medigun charge on hit");
    DB.SetString(338, "subtract victim cloak on hit");
    DB.SetString(339, "reveal cloaked victim on hit");
    DB.SetString(340, "reveal disguised victim on hit");
    DB.SetString(341, "jarate backstabber");
    DB.SetString(343, "engy sentry fire rate increased");
    DB.SetString(344, "engy sentry radius increased");
    DB.SetString(345, "engy dispenser radius increased");
    DB.SetString(346, "mod bat launches ornaments");
    DB.SetString(347, "freeze backstab victim");
    DB.SetString(348, "fire rate penalty HIDDEN");
    DB.SetString(349, "energy weapon no drain");
    DB.SetString(350, "ragdolls become ash");
    DB.SetString(351, "engy disposable sentries");
    DB.SetString(352, "alt fire teleport to spawn");
    DB.SetString(353, "cannot pick up buildings");
    DB.SetString(354, "stun enemies wielding same weapon");
    DB.SetString(355, "mod ammo per shot missed DISPLAY ONLY");
    DB.SetString(356, "airblast disabled");
    DB.SetString(357, "increase buff duration HIDDEN");
    DB.SetString(358, "crit forces victim to laugh");
    DB.SetString(359, "melts in fire");
    DB.SetString(360, "damage all connected");
    DB.SetString(361, "become fireproof on hit by fire");
    DB.SetString(362, "crit from behind");
    DB.SetString(363, "crit does no damage");
    DB.SetString(364, "add jingle to footsteps");
    DB.SetString(365, "set icicle knife mode");
    DB.SetString(366, "mod stun waist high airborne");
    DB.SetString(367, "extinguish earns revenge crits");
    DB.SetString(368, "burn damage earns rage");
    DB.SetString(369, "tickle enemies wielding same weapon");
    DB.SetString(370, "attach particle effect static");
    DB.SetString(371, "cosmetic taunt sound");
    DB.SetString(372, "accepted wedding ring account id 1");
    DB.SetString(373, "accepted wedding ring account id 2");
    DB.SetString(374, "tool escrow until date");
    DB.SetString(375, "generate rage on damage");
    DB.SetString(376, "aiming no flinch");
    DB.SetString(377, "aiming knockback resistance");
    DB.SetString(378, "sniper aiming movespeed decreased");
    DB.SetString(379, "kill eater user 1");
    DB.SetString(380, "kill eater user score type 1");
    DB.SetString(381, "kill eater user 2");
    DB.SetString(382, "kill eater user score type 2");
    DB.SetString(383, "kill eater user 3");
    DB.SetString(384, "kill eater user score type 3");
    DB.SetString(385, "strange part new counter ID");
    DB.SetString(386, "mvm completed challenges bitmask");
    DB.SetString(387, "rage on kill");
    DB.SetString(388, "kill eater kill type");
    DB.SetString(389, "shot penetrate all players");
    DB.SetString(390, "headshot damage increase");
    DB.SetString(391, "SET BONUS: mystery solving time decrease");
    DB.SetString(392, "damage penalty on bodyshot");
    DB.SetString(393, "sniper rage DISPLAY ONLY");
    DB.SetString(394, "fire rate bonus HIDDEN");
    DB.SetString(395, "explosive sniper shot");
    DB.SetString(396, "melee attack rate bonus");
    DB.SetString(397, "projectile penetration heavy");
    DB.SetString(398, "rage on assists");
    DB.SetString(399, "armor piercing");
    DB.SetString(400, "cannot pick up intelligence");
    DB.SetString(401, "SET BONUS: chance of hunger decrease");
    DB.SetString(402, "cannot be backstabbed");
    DB.SetString(403, "squad surplus claimer id DEPRECATED");
    DB.SetString(404, "share consumable with patient");
    DB.SetString(405, "airblast vertical vulnerability multiplier");
    DB.SetString(406, "vision opt in flags");
    DB.SetString(407, "crit vs disguised players");
    DB.SetString(408, "crit vs non burning players");
    DB.SetString(409, "kill forces attacker to laugh");
    DB.SetString(410, "damage bonus while disguised");
    DB.SetString(411, "projectile spread angle penalty");
    DB.SetString(412, "dmg taken increased");
    DB.SetString(413, "auto fires full clip");
    DB.SetString(414, "self mark for death");
    DB.SetString(415, "counts as assister is some kind of pet this update is going to be awesome");
    DB.SetString(416, "mod flaregun fires pellets with knockback");
    DB.SetString(417, "can overload");
    DB.SetString(418, "boost on damage");
    DB.SetString(419, "hype resets on jump");
    DB.SetString(420, "pyro year number");
    DB.SetString(421, "no primary ammo from dispensers while active");
    DB.SetString(422, "pyrovision only DISPLAY ONLY");
    DB.SetString(424, "clip size penalty HIDDEN");
    DB.SetString(425, "sapper damage bonus");
    DB.SetString(426, "sapper damage penalty");
    DB.SetString(427, "sapper damage leaches health");
    DB.SetString(428, "sapper health bonus");
    DB.SetString(429, "sapper health penalty");
    DB.SetString(430, "ring of fire while aiming");
    DB.SetString(431, "uses ammo while aiming");
    DB.SetString(433, "sapper degenerates buildings");
    DB.SetString(434, "sapper damage penalty hidden");
    DB.SetString(435, "cleaver description");
    DB.SetString(436, "ragdolls plasma effect");
    DB.SetString(437, "crit vs stunned players");
    DB.SetString(438, "crit vs wet players");
    DB.SetString(439, "override item level desc string");
    DB.SetString(440, "clip size upgrade atomic");
    DB.SetString(441, "auto fires full clip all at once");
    DB.SetString(442, "major move speed bonus");
    DB.SetString(443, "major increased jump height");
    DB.SetString(444, "head scale");
    DB.SetString(445, "pyrovision opt in DISPLAY ONLY");
    DB.SetString(446, "halloweenvision opt in DISPLAY ONLY");
    DB.SetString(447, "halloweenvision filter DISPLAY ONLY");
    DB.SetString(448, "player skin override");
    DB.SetString(449, "never craftable");
    DB.SetString(450, "zombiezombiezombiezombie");
    DB.SetString(451, "sapper voice pak");
    DB.SetString(452, "sapper voice pak idle wait");
    DB.SetString(453, "merasmus hat level display ONLY");
    DB.SetString(454, "strange restriction type 1");
    DB.SetString(455, "strange restriction value 1");
    DB.SetString(456, "strange restriction type 2");
    DB.SetString(457, "strange restriction value 2");
    DB.SetString(458, "strange restriction user type 1");
    DB.SetString(459, "strange restriction user value 1");
    DB.SetString(460, "strange restriction user type 2");
    DB.SetString(461, "strange restriction user value 2");
    DB.SetString(462, "strange restriction user type 3");
    DB.SetString(463, "strange restriction user value 3");
    DB.SetString(464, "engineer sentry build rate multiplier");
    DB.SetString(465, "engineer teleporter build rate multiplier");
    DB.SetString(466, "grenade launcher mortar mode");
    DB.SetString(467, "grenade not explode on impact");
    DB.SetString(468, "strange score selector");
    DB.SetString(469, "engineer building teleporting pickup");
    DB.SetString(470, "grenade damage reduction on world contact");
    DB.SetString(471, "engineer rage on dmg");
    DB.SetString(472, "mark for death on building pickup");
    DB.SetString(473, "medigun charge is resists");
    DB.SetString(474, "arrow heals buildings");
    DB.SetString(475, "Projectile speed increased HIDDEN");
    DB.SetString(476, "damage bonus HIDDEN");
    DB.SetString(477, "cannonball push back");
    DB.SetString(478, "rage giving scale");
    DB.SetString(479, "overheal fill rate reduced");
    DB.SetString(481, "canteen specialist");
    DB.SetString(482, "overheal expert");
    DB.SetString(484, "mad milk syringes");
    DB.SetString(488, "rocket specialist");
    DB.SetString(489, "SET BONUS: move speed set bonus");
    DB.SetString(490, "SET BONUS: health regen set bonus");
    DB.SetString(491, "SET BONUS: dmg taken from crit reduced set bonus");
    DB.SetString(492, "SET BONUS: dmg taken from fire reduced set bonus");
    DB.SetString(493, "healing mastery");
    DB.SetString(494, "kill eater 3");
    DB.SetString(495, "kill eater score type 3");
    DB.SetString(496, "strange restriction type 3");
    DB.SetString(497, "strange restriction value 3");
    DB.SetString(498, "bot custom jump particle");
    DB.SetString(499, "generate rage on heal");
    DB.SetString(500, "custom name attr");
    DB.SetString(501, "custom desc attr");
    DB.SetString(503, "medigun bullet resist passive");
    DB.SetString(504, "medigun blast resist passive");
    DB.SetString(505, "medigun fire resist passive");
    DB.SetString(506, "medigun bullet resist deployed");
    DB.SetString(507, "medigun blast resist deployed");
    DB.SetString(508, "medigun fire resist deployed");
    DB.SetString(509, "medigun crit bullet percent bar deplete");
    DB.SetString(510, "medigun crit blast percent bar deplete");
    DB.SetString(511, "medigun crit fire percent bar deplete");
    DB.SetString(512, "throwable fire speed");
    DB.SetString(513, "throwable damage");
    DB.SetString(514, "throwable healing");
    DB.SetString(515, "throwable particle trail only");
    DB.SetString(516, "SET BONUS: dmg taken from bullets increased");
    DB.SetString(517, "SET BONUS: max health additive bonus");
    DB.SetString(518, "scattergun knockback mult");
    DB.SetString(519, "particle effect vertical offset");
    DB.SetString(520, "particle effect use head origin");
    DB.SetString(521, "use large smoke explosion");
    DB.SetString(522, "damage causes airblast");
    DB.SetString(524, "increased jump height from weapon");
    DB.SetString(525, "damage force increase");
    DB.SetString(526, "healing received bonus");
    DB.SetString(527, "afterburn immunity");
    DB.SetString(528, "decoded by itemdefindex");
    DB.SetString(532, "hype decays over time");
    DB.SetString(533, "SET BONUS: custom taunt particle attr");
    DB.SetString(534, "airblast vulnerability multiplier hidden");
    DB.SetString(535, "damage force increase hidden");
    DB.SetString(536, "damage force increase text");
    DB.SetString(537, "SET BONUS: calling card on kill");
    DB.SetString(538, "righthand pose parameter");
    DB.SetString(539, "set throwable type");
    DB.SetString(540, "add head on hit");
    DB.SetString(542, "item style override");
    DB.SetString(543, "paint decal enum");
    DB.SetString(544, "show paint description");
    DB.SetString(545, "bot medic uber health threshold");
    DB.SetString(546, "bot medic uber deploy delay duration");
    DB.SetString(547, "single wep deploy time decreased");
    DB.SetString(548, "halloween reload time decreased");
    DB.SetString(549, "halloween fire rate bonus");
    DB.SetString(550, "halloween increased jump height");
    DB.SetString(551, "special taunt");
    DB.SetString(554, "revive");
    DB.SetString(556, "taunt attack name");
    DB.SetString(557, "taunt attack time");
    DB.SetString(600, "taunt force move forward");
    DB.SetString(602, "taunt mimic");
    DB.SetString(606, "taunt success sound");
    DB.SetString(607, "taunt success sound offset");
    DB.SetString(608, "taunt success sound loop");
    DB.SetString(609, "taunt success sound loop offset");
    DB.SetString(610, "increased air control");
    DB.SetString(612, "rocket launch impulse");
    DB.SetString(613, "minicritboost on kill");
    DB.SetString(614, "no metal from dispensers while active");
    DB.SetString(615, "projectile entity name");
    DB.SetString(616, "is throwable primable");
    DB.SetString(617, "throwable detonation time");
    DB.SetString(618, "throwable recharge time");
    DB.SetString(619, "closerange backattack minicrits");
    DB.SetString(620, "torso scale");
    DB.SetString(621, "rocketjump attackrate bonus");
    DB.SetString(622, "is throwable chargeable");
    DB.SetString(630, "back headshot");
    DB.SetString(632, "rj air bombardment");
    DB.SetString(633, "projectile particle name");
    DB.SetString(634, "air jump on attack");
    DB.SetString(636, "sniper crit no scope");
    DB.SetString(637, "sniper independent zoom DISPLAY ONLY");
    DB.SetString(638, "axtinguisher properties");
    DB.SetString(639, "full charge turn control");
    DB.SetString(640, "parachute attribute");
    DB.SetString(641, "taunt force weapon slot");
    DB.SetString(642, "mini rockets");
    DB.SetString(643, "rocket jump damage reduction HIDDEN");
    DB.SetString(644, "clipsize increase on kill");
    DB.SetString(645, "breadgloves properties");
    DB.SetString(646, "taunt turn speed");
    DB.SetString(647, "sniper fires tracer HIDDEN");
    DB.SetString(651, "fire rate bonus with reduced health");
    DB.SetString(661, "tag__summer2014");
    DB.SetString(662, "crate generation code");
    DB.SetString(669, "stickybomb fizzle time");
    DB.SetString(670, "stickybomb charge rate");
    DB.SetString(671, "grenade no bounce");
    DB.SetString(674, "class select override vcd");
    DB.SetString(675, "custom projectile model");
    DB.SetString(676, "lose demo charge on damage when charging");
    DB.SetString(681, "grenade no spin");
    DB.SetString(684, "grenade detonation damage penalty");
    DB.SetString(687, "taunt turn acceleration time");
    DB.SetString(688, "taunt move acceleration time");
    DB.SetString(689, "taunt move speed");
    DB.SetString(690, "shuffle crate item def min");
    DB.SetString(691, "shuffle crate item def max");
    DB.SetString(692, "limited quantity item");
    DB.SetString(693, "SET BONUS: alien isolation xeno bonus pos");
    DB.SetString(694, "SET BONUS: alien isolation xeno bonus neg");
    DB.SetString(695, "SET BONUS: alien isolation merc bonus pos");
    DB.SetString(696, "SET BONUS: alien isolation merc bonus neg");
    DB.SetString(698, "disable weapon switch");
    DB.SetString(699, "hand scale");
    DB.SetString(700, "display duck leaderboard");
    DB.SetString(701, "duck rating");
    DB.SetString(702, "duck badge level");
    DB.SetString(703, "tag__eotlearlysupport");
    DB.SetString(704, "unlimited quantity hidden");
    DB.SetString(705, "duckstreaks active");
    DB.SetString(708, "panic_attack");
    DB.SetString(709, "panic_attack_negative");
    DB.SetString(710, "auto fires full clip penalty");
    DB.SetString(711, "auto fires when full");
    DB.SetString(712, "force weapon switch");
    DB.SetString(719, "weapon_uses_stattrak_module");
    DB.SetString(723, "is_operation_pass");
    DB.SetString(724, "weapon_stattrak_module_scale");
    DB.SetString(725, "set_item_texture_wear");
    DB.SetString(726, "cloak_consume_on_feign_death_activate");
    DB.SetString(727, "stickybomb_charge_damage_increase");
    DB.SetString(728, "NoCloakWhenCloaked");
    DB.SetString(729, "ReducedCloakFromAmmo");
    DB.SetString(730, "elevate to unusual if applicable");
    DB.SetString(731, "weapon_allow_inspect");
    DB.SetString(732, "metal_pickup_decreased");
    DB.SetString(733, "lose hype on take damage");
    DB.SetString(734, "healing received penalty");
    DB.SetString(735, "crit_vs_burning_FLARES_DISPLAY_ONLY");
    DB.SetString(736, "speed_boost_on_kill");
    DB.SetString(737, "speed_boost_on_hit");
    DB.SetString(738, "spunup_damage_resistance");
    DB.SetString(739, "ubercharge overheal rate penalty");
    DB.SetString(740, "reduced_healing_from_medics");
    DB.SetString(741, "health on radius damage");
    DB.SetString(742, "style changes on strange level");
    DB.SetString(743, "cannot restore");
    DB.SetString(744, "hide crate series number");
    DB.SetString(745, "has team color paintkit");
    DB.SetString(746, "cosmetic_allow_inspect");
    DB.SetString(747, "hat only unusual effect");
    DB.SetString(748, "items traded in for");
    DB.SetString(749, "texture_wear_default");
    DB.SetString(750, "taunt only unusual effect");
    DB.SetString(751, "deactive date");
    DB.SetString(752, "is giger counter");
    DB.SetString(753, "hide_strange_prefix");
    DB.SetString(754, "always_transmit_so");
    DB.SetString(760, "allow_halloween_offering");
    DB.SetString(762, "cannot_transmute");
    DB.SetString(772, "single wep holster time increased");
    DB.SetString(773, "single wep deploy time increased");
    DB.SetString(774, "charge time decreased");
    DB.SetString(775, "dmg penalty vs buildings");
    DB.SetString(776, "charge impact damage decreased");
    DB.SetString(777, "non economy");
    DB.SetString(778, "charge meter on hit");
    DB.SetString(779, "minicrit_boost_when_charged");
    DB.SetString(780, "minicrit_boost_charge_rate");
    DB.SetString(781, "is_a_sword");
    DB.SetString(782, "ammo gives charge");
    DB.SetString(783, "extinguish restores health");
    DB.SetString(784, "extinguish reduces cooldown");
    DB.SetString(785, "cannot giftwrap");
    DB.SetString(786, "tool needs giftwrap");
    DB.SetString(787, "fuse bonus");
    DB.SetString(788, "move speed bonus shield required");
    DB.SetString(789, "damage bonus bullet vs sentry target");
    DB.SetString(790, "mod teleporter cost");
    DB.SetString(791, "damage blast push");
    DB.SetString(792, "move speed bonus resource level");
    DB.SetString(793, "hype on damage");
    DB.SetString(794, "dmg taken from fire reduced on active");
    DB.SetString(795, "damage bonus vs burning");
    DB.SetString(796, "min_viewmodel_offset");
    DB.SetString(797, "dmg pierces resists absorbs");
    DB.SetString(798, "energy buff dmg taken multiplier");
    DB.SetString(799, "lose revenge crits on death DISPLAY ONLY");
    DB.SetString(800, "patient overheal penalty");
    DB.SetString(801, "item_meter_charge_rate");
    DB.SetString(804, "mult_spread_scale_first_shot");
    DB.SetString(805, "unusualifier_attribute_template_name");
    DB.SetString(806, "tool_target_item_icon_offset");
    DB.SetString(807, "add_head_on_kill");
    DB.SetString(808, "mult_spread_scales_consecutive");
    DB.SetString(809, "fixed_shot_pattern");
    DB.SetString(810, "mod_cloak_no_regen_from_items");
    DB.SetString(811, "ubercharge_preserved_on_spawn_max");
    DB.SetString(812, "mod_air_control_blast_jump");
    DB.SetString(813, "spunup_push_force_immunity");
    DB.SetString(814, "mod_mark_attacker_for_death");
    DB.SetString(815, "use_model_cache_icon");
    DB.SetString(816, "mod_disguise_consumes_cloak");
    DB.SetString(817, "inspect_viewmodel_offset");
    DB.SetString(818, "is_passive_weapon");
    DB.SetString(819, "no_jump");
    DB.SetString(820, "no_duck");
    DB.SetString(821, "no_attack");
    DB.SetString(822, "airblast_destroy_projectile");
    DB.SetString(823, "airblast_pushback_disabled");
    DB.SetString(824, "airblast_pushback_no_stun");
    DB.SetString(825, "airblast_pushback_no_viewpunch");
    DB.SetString(826, "airblast_deflect_projectiles_disabled");
    DB.SetString(827, "airblast_put_out_teammate_disabled");
    DB.SetString(828, "afterburn duration penalty");
    DB.SetString(829, "afterburn duration bonus");
    DB.SetString(830, "aoe_deflection");
    DB.SetString(831, "mult_end_flame_size");
    DB.SetString(832, "airblast_give_teammate_speed_boost");
    DB.SetString(833, "airblast_turn_projectile_to_ammo");
    DB.SetString(834, "paintkit_proto_def_index");
    DB.SetString(835, "taunt_attr_player_invis_percent");
    DB.SetString(837, "redirected_flame_size_mult");
    DB.SetString(838, "flame_reflect_on_collision");
    DB.SetString(839, "flame_spread_degree");
    DB.SetString(840, "holster_anim_time");
    DB.SetString(841, "flame_gravity");
    DB.SetString(842, "flame_ignore_player_velocity");
    DB.SetString(843, "flame_drag");
    DB.SetString(844, "flame_speed");
    DB.SetString(845, "grenades1_resupply_denied");
    DB.SetString(846, "grenades2_resupply_denied");
    DB.SetString(847, "grenades3_resupply_denied");
    DB.SetString(848, "item_meter_resupply_denied");
    DB.SetString(851, "mult_player_movespeed_active");
    DB.SetString(852, "mult_dmgtaken_active");
    DB.SetString(853, "mult_patient_overheal_penalty_active");
    DB.SetString(854, "mult_health_fromhealers_penalty_active");
    DB.SetString(855, "mod_maxhealth_drain_rate");
    DB.SetString(856, "item_meter_charge_type");
    DB.SetString(859, "max_flame_reflection_count");
    DB.SetString(860, "flame_reflection_add_life_time");
    DB.SetString(861, "reflected_flame_dmg_reduction");
    DB.SetString(862, "flame_lifetime");
    DB.SetString(863, "flame_random_life_time_offset");
    DB.SetString(865, "flame_up_speed");
    DB.SetString(866, "custom_paintkit_seed_lo");
    DB.SetString(867, "custom_paintkit_seed_hi");
    DB.SetString(868, "crit_dmg_falloff");
    DB.SetString(869, "crits_become_minicrits");
    DB.SetString(870, "falling_impact_radius_pushback");
    DB.SetString(871, "falling_impact_radius_stun");
    DB.SetString(872, "thermal_thruster_air_launch");
    DB.SetString(873, "thermal_thruster");
    DB.SetString(874, "mult_item_meter_charge_rate");
    DB.SetString(875, "explode_on_ignite");
    DB.SetString(876, "lunchbox healing decreased");
    DB.SetString(877, "speed_boost_on_hit_enemy");
    DB.SetString(878, "item_meter_starts_empty_DISPLAY_ONLY");
    DB.SetString(879, "item_meter_charge_type_3_DISPLAY_ONLY");
    DB.SetString(880, "repair health to metal ratio DISPLAY ONLY");
    DB.SetString(881, "health drain medic");
    DB.SetString(1000, "CARD: damage bonus");
    DB.SetString(1001, "CARD: dmg taken from bullets reduced");
    DB.SetString(1002, "CARD: move speed bonus");
    DB.SetString(1003, "CARD: health regen");
    DB.SetString(1004, "SPELL: set item tint RGB");
    DB.SetString(1005, "SPELL: set Halloween footstep type");
    DB.SetString(1006, "SPELL: Halloween voice modulation");
    DB.SetString(1007, "SPELL: Halloween pumpkin explosions");
    DB.SetString(1008, "SPELL: Halloween green flames");
    DB.SetString(1009, "SPELL: Halloween death ghosts");
    DB.SetString(1030, "Attack not cancel charge");
    DB.SetString(2000, "recipe component defined item 1");
    DB.SetString(2001, "recipe component defined item 2");
    DB.SetString(2002, "recipe component defined item 3");
    DB.SetString(2003, "recipe component defined item 4");
    DB.SetString(2004, "recipe component defined item 5");
    DB.SetString(2005, "recipe component defined item 6");
    DB.SetString(2006, "recipe component defined item 7");
    DB.SetString(2007, "recipe component defined item 8");
    DB.SetString(2008, "recipe component defined item 9");
    DB.SetString(2009, "recipe component defined item 10");
    DB.SetString(2010, "start drop date");
    DB.SetString(2011, "end drop date");
    DB.SetString(2012, "tool target item");
    DB.SetString(2013, "killstreak effect");
    DB.SetString(2014, "killstreak idleeffect");
    DB.SetString(2015, "spellbook page attr id");
    DB.SetString(2016, "Halloween Spellbook Page: Tumidum");
    DB.SetString(2017, "Halloween Spellbook Page: Gratanter");
    DB.SetString(2018, "Halloween Spellbook Page: Audere");
    DB.SetString(2019, "Halloween Spellbook Page: Congeriae");
    DB.SetString(2020, "Halloween Spellbook Page: Veteris");
    DB.SetString(2021, "additional halloween response criteria name");
    DB.SetString(2022, "loot rarity");
    DB.SetString(2023, "quality text override");
    DB.SetString(2024, "item name text override");
    DB.SetString(2025, "killstreak tier");
    DB.SetString(2026, "wide item level");
    DB.SetString(2027, "is australium item");
    DB.SetString(2028, "is marketable");
    DB.SetString(2029, "allowed in medieval mode");
    DB.SetString(2030, "crit on hard hit");
    DB.SetString(2031, "series number");
    DB.SetString(2032, "recipe no partial complete");
    DB.SetString(2034, "kill refills meter");
    DB.SetString(2035, "random drop line item unusual chance");
    DB.SetString(2036, "random drop line item unusual list");
    DB.SetString(2037, "random drop line item 0");
    DB.SetString(2038, "random drop line item 1");
    DB.SetString(2039, "random drop line item 2");
    DB.SetString(2040, "random drop line item 3");
    DB.SetString(2041, "on taunt attach particle effect");
    DB.SetString(2042, "loot list name");
    DB.SetString(2043, "upgrade rate decrease");
    DB.SetString(2044, "can shuffle crate contents");
    DB.SetString(2045, "random drop line item footer desc");
    DB.SetString(2046, "is commodity");
    DB.SetString(2048, "voice pitch scale");
    DB.SetString(2049, "gunslinger punch combo");
    DB.SetString(2050, "cannot delete");
    DB.SetString(2051, "quest loaner id low");
    DB.SetString(2052, "quest loaner id hi");
    DB.SetString(2053, "is_festivized");
    DB.SetString(2054, "fire particle blue");
    DB.SetString(2055, "fire particle red");
    DB.SetString(2056, "fire particle blue crit");
    DB.SetString(2057, "fire particle red crit");
    DB.SetString(2058, "meter_label");
    DB.SetString(2059, "item_meter_damage_for_full_charge");
    DB.SetString(2062, "airblast cost scale hidden");
    DB.SetString(2063, "dragons fury positive properties");
    DB.SetString(2064, "dragons fury negative properties");
    DB.SetString(2065, "dragons fury neutral properties");
    DB.SetString(2066, "force center wrap");
    DB.SetString(2067, "attack_minicrits_and_consumes_burning");
    DB.SetString(2068, "is winter case");
    DB.SetString(3000, "item slot criteria 1");
    DB.SetString(3001, "item in slot 1");
    DB.SetString(3002, "item slot criteria 2");
    DB.SetString(3003, "item in slot 2");
    DB.SetString(3004, "item slot criteria 3");
    DB.SetString(3005, "item in slot 3");
    DB.SetString(3006, "item slot criteria 4");
    DB.SetString(3007, "item in slot 4");
    DB.SetString(3008, "item slot criteria 5");
    DB.SetString(3009, "item in slot 5");
    DB.SetString(3010, "item slot criteria 6");
    DB.SetString(3011, "item in slot 6");
    DB.SetString(3012, "item slot criteria 7");
    DB.SetString(3013, "item in slot 7");
    DB.SetString(3014, "item slot criteria 8");
    DB.SetString(3015, "item in slot 8");
    DB.SetString(3016, "quest earned standard points");
    DB.SetString(3017, "quest earned bonus points");
    DB.SetString(3018, "item drop wave");
	return DB;
}

IntMap HMMR_ATTRIBUTE_DB;

public bool GetAttributeValue(int key, char[] value, int valueSize)
{
	if (HMMR_ATTRIBUTE_DB == null)
	{
		HMMR_ATTRIBUTE_DB = __GenerateAttributeDB();
	}

	return HMMR_ATTRIBUTE_DB.GetString(key, value, valueSize);
}
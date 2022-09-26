Config.Ammos = {
	{name = 'AMMO_PISTOL'},
	{name = 'AMMO_SMG'},
	{name = 'AMMO_RIFLE'},
	{name = 'AMMO_MG'},
	{name = 'AMMO_SHOTGUN'},
	{name = 'AMMO_STUNGUN'},
	{name = 'AMMO_SNIPER'},
	{name = 'AMMO_SNIPER_REMOTE'},
	{name = 'AMMO_FIREEXTINGUISHER'},
	{name = 'AMMO_PETROLCAN'},
	{name = 'AMMO_MINIGUN'},
	{name = 'AMMO_GRENADELAUNCHER'},
	{name = 'AMMO_GRENADELAUNCHER_SMOKE'},
	{name = 'AMMO_RPG'},
	{name = 'AMMO_STINGER'},
	{name = 'AMMO_GRENADE'},
	{name = 'AMMO_BALL'},
	{name = 'AMMO_STICKYBOMB'},
	{name = 'AMMO_SMOKEGRENADE'},
	{name = 'AMMO_BZGAS'},
	{name = 'AMMO_FLARE'},
	{name = 'AMMO_MOLOTOV'},
	{name = 'AMMO_MG_ARMORPIERCING'},
	{name = 'AMMO_MG_FMJ'},
	{name = 'AMMO_MG_INCENDIARY'},
	{name = 'AMMO_MG_TRACER'},
	{name = 'AMMO_PISTOL_FMJ'},
	{name = 'AMMO_PISTOL_HOLLOWPOINT'},
	{name = 'AMMO_PISTOL_INCENDIARY'},
	{name = 'AMMO_PISTOL_TRACER'},
	{name = 'AMMO_RIFLE_ARMORPIERCING'},
	{name = 'AMMO_RIFLE_FMJ'},
	{name = 'AMMO_RIFLE_INCENDIARY'},
	{name = 'AMMO_RIFLE_TRACER'},
	{name = 'AMMO_SMG_FMJ'},
	{name = 'AMMO_SMG_HOLLOWPOINT'},
	{name = 'AMMO_SMG_INCENDIARY'},
	{name = 'AMMO_SMG_TRACER'},
	{name = 'AMMO_SNIPER_ARMORPIERCING'},
	{name = 'AMMO_SNIPER_EXPLOSIVE'},
	{name = 'AMMO_SNIPER_FMJ'},
	{name = 'AMMO_SNIPER_INCENDIARY'},
	{name = 'AMMO_SNIPER_TRACER'},
	{name = 'AMMO_SHOTGUN_ARMORPIERCING'},
	{name = 'AMMO_SHOTGUN_EXPLOSIVE'},
	{name = 'AMMO_SHOTGUN_HOLLOWPOINT'},
	{name = 'AMMO_SHOTGUN_INCENDIARY'}
}

Config.Weapons = {
	{name = 'WEAPON_JERRYCAN', label = _U('weapon_jerrycan'), components = {}},
	{name = 'WEAPON_KNIFE', label = _U('weapon_knife'), components = {}},
	{name = 'WEAPON_STONE_HATCHET', label = _U('weapon_stone_hatchet'), components = {}},
	{name = 'WEAPON_NIGHTSTICK', label = _U('weapon_nightstick'), components = {}},
	{name = 'WEAPON_HAMMER', label = _U('weapon_hammer'), components = {}},
	{name = 'WEAPON_BAT', label = _U('weapon_bat'), components = {}},
	{name = 'WEAPON_GOLFCLUB', label = _U('weapon_golfclub'), components = {}},
	{name = 'WEAPON_CROWBAR', label = _U('weapon_crowbar'), components = {}},

	{
		name = 'WEAPON_PISTOL',
		label = _U('weapon_pistol'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_PISTOL_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_PISTOL_CLIP_02`},
			{name = 'clip_hp', label = _U('component_clip_type', _U('HP')), hash = `COMPONENT_PISTOL_CLIP_HOLLOWPOINT`, ammoType = "AMMO_PISTOL_HOLLOWPOINT"},
			{name = 'clip_fmj', label = _U('component_clip_type', _U('FMJ')), hash = `COMPONENT_PISTOL_CLIP_FMJ`, ammoType = "AMMO_PISTOL_FMJ"},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_PI_FLSH`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_PI_SUPP_02`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_PISTOL_VARMOD_LUXE`}
		},
		weight = 2000,
		ammoType = 'AMMO_PISTOL'
	},

	{
		name = 'WEAPON_COMBATPISTOL',
		government = true,
		label = _U('weapon_combatpistol'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_COMBATPISTOL_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_COMBATPISTOL_CLIP_02`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_PI_FLSH`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_PI_SUPP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_COMBATPISTOL_VARMOD_LOWRIDER`}
		},
		weight = 2000,
		ammoType = 'AMMO_PISTOL'
	},

	{
		name = 'WEAPON_WALTHER',
		government = true,
		label = _U('weapon_walther'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_COMBATPISTOL_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_COMBATPISTOL_CLIP_02`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_PI_FLSH`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_PI_SUPP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_COMBATPISTOL_VARMOD_LOWRIDER`}
		},
		weight = 2000,
		ammoType = 'AMMO_PISTOL'
	},

	{
		name = 'WEAPON_M4',
		government = true,
		label = _U('weapon_m4'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_M4_CLIP_01`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_MEDIUM`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP`},
			{name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP`}
		},
		weight = 2000,
		ammoType = 'AMMO_RIFLE'
	},

	{
		name = 'WEAPON_NSR',
		government = true,
		label = _U('weapon_nsr'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_NSR_CLIP_01`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_MEDIUM`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP`},
			{name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP`}
		},
		weight = 2000,
		ammoType = 'AMMO_RIFLE'
	},

	{
		name = 'WEAPON_APPISTOL',
		government = true,
		label = _U('weapon_appistol'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_APPISTOL_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_APPISTOL_CLIP_02`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_PI_FLSH`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_PI_SUPP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_APPISTOL_VARMOD_LUXE`}
		},
		weight = 2000,
		ammoType = 'AMMO_PISTOL'
	},

	{
		name = 'WEAPON_RENETTI',
		label = _U('weapon_renetti'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_RENETTI_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_RENETTI_CLIP_02`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_PI_FLSH`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_PI_SUPP`}
		},
		weight = 2000,
		ammoType = 'AMMO_PISTOL'
	},

	{
		name = 'WEAPON_PISTOL50',
		label = _U('weapon_pistol50'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_PISTOL50_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_PISTOL50_CLIP_02`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_PI_FLSH`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP_02`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_PISTOL50_VARMOD_LUXE`}
		},
		weight = 2000,
		ammoType = 'AMMO_PISTOL'
	},

	{name = 'WEAPON_REVOLVER', label = _U('weapon_revolver'), components = {}},

	{
		name = 'WEAPON_SNSPISTOL',
		label = _U('weapon_snspistol'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_SNSPISTOL_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_SNSPISTOL_CLIP_02`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_SNSPISTOL_VARMOD_LOWRIDER`}
		},
		weight = 2000,
		ammoType = 'AMMO_PISTOL'
	},

	{
		name = 'WEAPON_HEAVYPISTOL',
		label = _U('weapon_heavypistol'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_HEAVYPISTOL_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_HEAVYPISTOL_CLIP_02`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_PI_FLSH`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_PI_SUPP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_HEAVYPISTOL_VARMOD_LUXE`}
		},
		weight = 2000,
		ammoType = 'AMMO_PISTOL'
	},

	{
		name = 'WEAPON_VINTAGEPISTOL',
		label = _U('weapon_vintagepistol'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_VINTAGEPISTOL_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_VINTAGEPISTOL_CLIP_02`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_PI_SUPP`}
		},
		weight = 2000,
		ammoType = 'AMMO_PISTOL'
	},

	{
		name = 'WEAPON_MICROSMG',
		label = _U('weapon_microsmg'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_MICROSMG_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_MICROSMG_CLIP_02`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_PI_FLSH`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_MACRO`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP_02`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_MICROSMG_VARMOD_LUXE`}
		},
		weight = 2000,
		ammoType = 'AMMO_SMG'
	},

	{
		name = 'WEAPON_SMG',
		label = _U('weapon_smg'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_SMG_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_SMG_CLIP_02`},
			{name = 'clip_drum', label = _U('component_clip_drum'), hash = `COMPONENT_SMG_CLIP_03`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_MACRO_02`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_PI_SUPP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_SMG_VARMOD_LUXE`}
		},
		weight = 3000,
		ammoType = 'AMMO_SMG'
	},

	{
		name = 'WEAPON_ASSAULTSMG',
		label = _U('weapon_assaultsmg'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_ASSAULTSMG_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_ASSAULTSMG_CLIP_02`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_MACRO`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP_02`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_ASSAULTSMG_VARMOD_LOWRIDER`}
		},
		weight = 3500,
		ammoType = 'AMMO_SMG'
	},

	{
		name = 'WEAPON_MINISMG',
		label = _U('weapon_minismg'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_MINISMG_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_MINISMG_CLIP_02`}
		},
		weight = 3500,
		ammoType = 'AMMO_SMG'
	},

	{
		name = 'WEAPON_GRAU',
		label = _U('weapon_grau'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_GRAU_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_GRAU_CLIP_02`}
		},
		weight = 3500,
		ammoType = 'AMMO_SMG'
	},

	{
		name = 'WEAPON_MACHINEPISTOL',
		label = _U('weapon_machinepistol'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_MACHINEPISTOL_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_MACHINEPISTOL_CLIP_02`},
			{name = 'clip_drum', label = _U('component_clip_drum'), hash = `COMPONENT_MACHINEPISTOL_CLIP_03`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_PI_SUPP`}
		},
		weight = 3500,
		ammoType = 'AMMO_SMG'
	},

	{
		name = 'WEAPON_COMBATPDW',
		label = _U('weapon_combatpdw'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_COMBATPDW_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_COMBATPDW_CLIP_02`},
			{name = 'clip_drum', label = _U('component_clip_drum'), hash = `COMPONENT_COMBATPDW_CLIP_03`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_SMALL`}
		},
		weight = 3500,
		ammoType = 'AMMO_SMG'
	},

	{
		name = 'WEAPON_PUMPSHOTGUN',
		government = true,
		label = _U('weapon_pumpshotgun'),
		components = {
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_SR_SUPP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_PUMPSHOTGUN_VARMOD_LOWRIDER`}
		},
		weight = 3500,
		ammoType = 'AMMO_SHOTGUN'
	},

	{
		name = 'WEAPON_SAWNOFFSHOTGUN',
		label = _U('weapon_sawnoffshotgun'),
		components = {
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_SAWNOFFSHOTGUN_VARMOD_LUXE`}
		},
		weight = 3500,
		ammoType = 'AMMO_SHOTGUN'
	},

	{
		name = 'WEAPON_ASSAULTSHOTGUN',
		label = _U('weapon_assaultshotgun'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_ASSAULTSHOTGUN_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_ASSAULTSHOTGUN_CLIP_02`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP`},
			{name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP`}
		},
		weight = 3500,
		ammoType = 'AMMO_SHOTGUN'
	},

	{
		name = 'WEAPON_BULLPUPSHOTGUN',
		label = _U('weapon_bullpupshotgun'),
		components = {
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP_02`},
			{name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP`}
		},
		weight = 3500,
		ammoType = 'AMMO_SHOTGUN'
	},

	{
		name = 'WEAPON_HEAVYSHOTGUN',
		label = _U('weapon_heavyshotgun'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_HEAVYSHOTGUN_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_HEAVYSHOTGUN_CLIP_02`},
			{name = 'clip_drum', label = _U('component_clip_drum'), hash = `COMPONENT_HEAVYSHOTGUN_CLIP_03`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP_02`},
			{name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP`}
		},
		weight = 4000,
		ammoType = 'AMMO_SHOTGUN'
	},

	{
		name = 'WEAPON_ASSAULTRIFLE',
		label = _U('weapon_assaultrifle'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_ASSAULTRIFLE_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_ASSAULTRIFLE_CLIP_02`},
			{name = 'clip_drum', label = _U('component_clip_drum'), hash = `COMPONENT_ASSAULTRIFLE_CLIP_03`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_MACRO`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP_02`},
			{name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_ASSAULTRIFLE_VARMOD_LUXE`}
		},
		weight = 5000,
		ammoType = 'AMMO_RIFLE'
	},

	{
		name = 'WEAPON_ASSAULTRIFLE_MK2',
		label = _U('weapon_assaultrifle_mk2'),
		components = {
			{ type = 'clip', name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_ASSAULTRIFLE_MK2_CLIP_01` },
			{ type = 'clip', name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_ASSAULTRIFLE_MK2_CLIP_02` },
			{ type = 'clip', name = 'clip_ap', label = _U('component_clip_type', _U('AP')), hash = `COMPONENT_ASSAULTRIFLE_MK2_CLIP_ARMORPIERCING` },
			{ type = 'clip', name = 'clip_fmj', label = _U('component_clip_type', _U('FMJ')), hash = `COMPONENT_ASSAULTRIFLE_MK2_CLIP_FMJ` },
			{ type = 'clip', name = 'clip_incend', label = _U('component_clip_type', _U('incendiary')), hash = `COMPONENT_ASSAULTRIFLE_MK2_CLIP_INCENDIARY` },
			{ type = 'clip', name = 'clip_tracer', label = _U('component_clip_type', _U('tracer')), hash = `COMPONENT_ASSAULTRIFLE_MK2_CLIP_TRACER` },
			{ name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH` },
			{ type = 'scope', name = 'scope_holo', label = _U('component_scope_holo'), hash = `COMPONENT_AT_SIGHTS` },
			{ type = 'scope', name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_MACRO_MK2` },
			{ type = 'scope', name = 'scope_medium', label = _U('component_scope_medium'), hash = `COMPONENT_AT_SCOPE_MEDIUM_MK2` },
			{ type = 'muzzle', name = 'brake_1', label = "Flat Muzzle Brake", hash = `COMPONENT_AT_MUZZLE_01` },
			{ type = 'muzzle', name = 'brake_2', label = "Tactical Muzzle Brake", hash = `COMPONENT_AT_MUZZLE_02` },
			{ type = 'muzzle', name = 'brake_3', label = "Fat-End Muzzle Brake", hash = `COMPONENT_AT_MUZZLE_03` },
			{ type = 'muzzle', name = 'brake_4', label = "Precision Muzzle Brake", hash = `COMPONENT_AT_MUZZLE_04` },
			{ type = 'muzzle', name = 'brake_5', label = "Heavy Duty Muzzle Brake", hash = `COMPONENT_AT_MUZZLE_05` },
			{ type = 'muzzle', name = 'brake_6', label = "Slanted Muzzle Brake", hash = `COMPONENT_AT_MUZZLE_06` },
			{ type = 'muzzle', name = 'brake_7', label = "Split-End Muzzle Brake", hash = `COMPONENT_AT_MUZZLE_07` },
			{ type = 'muzzle', name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP_02` },
			{ type = 'livery', name = 'livery_1', label = _U('livery', _U('pixel')), hash = `COMPONENT_ASSAULTRIFLE_MK2_CAMO` },
			{ type = 'livery', name = 'livery_2', label = _U('livery', _U('brushstroke')), hash = `COMPONENT_ASSAULTRIFLE_MK2_CAMO_02` },
			{ type = 'livery', name = 'livery_3', label = _U('livery', _U('woodland')), hash = `COMPONENT_ASSAULTRIFLE_MK2_CAMO_03` },
			{ type = 'livery', name = 'livery_4', label = _U('livery', _U('skull')), hash = `COMPONENT_ASSAULTRIFLE_MK2_CAMO_04` },
			{ type = 'livery', name = 'livery_5', label = _U('livery', _U('sessanta')), hash = `COMPONENT_ASSAULTRIFLE_MK2_CAMO_05` },
			{ type = 'livery', name = 'livery_6', label = _U('livery', _U('perseus')), hash = `COMPONENT_ASSAULTRIFLE_MK2_CAMO_06` },
			{ type = 'livery', name = 'livery_7', label = _U('livery', _U('leopard')), hash = `COMPONENT_ASSAULTRIFLE_MK2_CAMO_07` },
			{ type = 'livery', name = 'livery_8', label = _U('livery', _U('zebra')), hash = `COMPONENT_ASSAULTRIFLE_MK2_CAMO_08` },
			{ type = 'livery', name = 'livery_9', label = _U('livery', _U('geometric')), hash = `COMPONENT_ASSAULTRIFLE_MK2_CAMO_09` },
			{ type = 'livery', name = 'livery_10', label = _U('livery', _U('boom')), hash = `COMPONENT_ASSAULTRIFLE_MK2_CAMO_10` },
			{ type = 'livery', name = 'livery_11', label = _U('livery', _U('patriotic')), hash = `COMPONENT_ASSAULTRIFLE_MK2_CAMO_IND_01` },
			{ name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP_02` },
			{ type = 'barrel', name = 'barrel_default', label = _U('component_barrel_default'), hash = `COMPONENT_AT_AR_BARREL_01` },
			{ type = 'barrel', name = 'barrel_heavy', label = _U('component_barrel_heavy'), hash = `COMPONENT_AT_AR_BARREL_02` }
		},
		weight = 5000,
		ammoType = 'AMMO_RIFLE'
	},
	{
		name = 'WEAPON_GADGETPISTOL',
		label = 'WEAPON_GADGETPISTOL',
		components = {}
	},
	{
		name = 'WEAPON_MILITARYRIFLE',
		label = "WEAPON_MILITARYRIFLE",
		components = {},
		weight = 5000
	},
	{
		name = 'WEAPON_COMBATSHOTGUN',
		label = 'WEAPON_COMBATSHOTGUN',
		components = {},
		weight = 5000
	},

	{
		name = 'WEAPON_CERAMICPISTOL',
		label = 'WEAPON_CERAMICPISTOL',
		components = {},
		weight = 5000
	},

	{
		name = 'WEAPON_NAVYREVOLVER',
		label = 'WEAPON_NAVYREVOLVER',
		components = {},
		weight = 5000
	},

	{
		name = 'WEAPON_CARBINERIFLE_MK2',
		label = "HK416A1",
		components = {
			{ type = 'clip', name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_CARBINERIFLE_MK2_CLIP_01` },
			{ type = 'clip', name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_CARBINERIFLE_MK2_CLIP_02` },
			{ name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH` },
			{ name = 'grip', label = "Grip", hash = `COMPONENT_AT_AR_AFGRIP_02` },
			{ type = 'scope', name = 'scope_holo', label = _U('component_scope_holo'), hash = `COMPONENT_AT_SIGHTS` },
			{ type = 'scope', name = 'scope', label = "Scope medium", hash = `COMPONENT_AT_SCOPE_MACRO_MK2` },
			{ type = 'scope', name = 'scope_medium', label = "Scope groot", hash = `COMPONENT_AT_SCOPE_MEDIUM_MK2` },
			{ type = 'muzzle', name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP` },
			{ type = 'muzzle', name = 'brake_1', label = "Flat Muzzle Brake", hash = `COMPONENT_AT_MUZZLE_01` },
			{ type = 'muzzle', name = 'brake_2', label = "Tactical Muzzle Brake", hash = `COMPONENT_AT_MUZZLE_02` },
			{ type = 'muzzle', name = 'brake_3', label = "Fat-End Muzzle Brake", hash = `COMPONENT_AT_MUZZLE_03` },
			{ type = 'muzzle', name = 'brake_4', label = "Precision Muzzle Brake", hash = `COMPONENT_AT_MUZZLE_04` },
			{ type = 'muzzle', name = 'brake_5', label = "Heavy Duty Muzzle Brake", hash = `COMPONENT_AT_MUZZLE_05` },
			{ type = 'muzzle', name = 'brake_6', label = "Slanted Muzzle Brake", hash = `COMPONENT_AT_MUZZLE_06` },
			{ type = 'muzzle', name = 'brake_7', label = "Split-End Muzzle Brake", hash = `COMPONENT_AT_MUZZLE_07` },
			{ type = 'barrel', name = 'barrel_default', label = "Standaard loop", hash = `COMPONENT_AT_CR_BARREL_01` },
			{ type = 'barrel', name = 'barrel_heavy', label = "Heavy Barrel", hash = `COMPONENT_AT_CR_BARREL_02` },
		},
		weight = 5000,
		ammoType = 'AMMO_RIFLE'
	},

	{
		name = 'WEAPON_COMBATMG_MK2',
		label = _U('weapon_mk2', _U('weapon_combatmg')),
		components = {},
		weight = 15000,
		ammoType = 'AMMO_RIFLE'
	},
	{
		name = 'WEAPON_PISTOL_MK2',
		label = _U('weapon_pistol_mk2'),
		components = {
			{ type = 'clip', name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_PISTOL_MK2_CLIP_01` },
			{ type = 'clip', name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_PISTOL_MK2_CLIP_02` },
			{ type = 'clip', name = 'clip_fmj', label = _U('component_clip_type', _U('FMJ')), hash = `COMPONENT_PISTOL_MK2_CLIP_FMJ`, ammoType = "AMMO_PISTOL_FMJ" },
			{ type = 'clip', name = 'clip_hp', label = _U('component_clip_type', _U('HP')), hash = `COMPONENT_PISTOL_MK2_CLIP_HOLLOWPOINT`, ammoType = "AMMO_PISTOL_HOLLOWPOINT" },
			{ type = 'clip', name = 'clip_incend', label = _U('component_clip_type', _U('incendiary')), hash = `COMPONENT_PISTOL_MK2_CLIP_INCENDIARY`, ammoType = "AMMO_PISTOL_INCENDIARY" },
			{ type = 'clip', name = 'clip_tracer', label = _U('component_clip_type', _U('tracer')), hash = `COMPONENT_PISTOL_MK2_CLIP_TRACER`, ammoType = "AMMO_PISTOL_TRACER" },
			{ type = 'scope', name = 'scope', label = "Scope", hash = `COMPONENT_AT_PI_RAIL` },
			{ type = 'flashlight', name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_PI_FLSH_02` },
			{ type = 'muzzle', name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_PI_SUPP_02` },
			{ type = 'muzzle', name = 'brake_1', label = "Compensator", hash = `COMPONENT_AT_PI_COMP` },
		},
		ammoType = "AMMO_PISTOL",
		weight = 1000
	},
	{
		name = 'WEAPON_SMG_MK2',
		label = 'WEAPON_SMG_MK2',
		components = {},
		weight = 1000
	},
	{
		name = 'WEAPON_HEAVYSNIPER_MK2',
		label = 'WEAPON_HEAVYSNIPER_MK2',
		components = {},
		weight = 15000,
	},
	{
		name = 'WEAPON_ARENA_MACHINE_GUN',
		label = 'WEAPON_ARENA_MACHINE_GUN',
		components = {},
		weight = 15000
	},
	{
		name = 'WEAPON_ARENA_HOMING_MISSILE',
		label = 'WEAPON_ARENA_HOMING_MISSILE',
		components = {},
		weight = 15000
	},
	{
		name = 'WEAPON_RAYPISTOL',
		label = 'WEAPON_RAYPISTOL',
		components = {},
		weight = 5000
	},
	{
		name = 'WEAPON_RAYCARBINE',
		label = 'WEAPON_RAYCARBINE',
		components = {},
		weight = 5000
	},
	{
		name = 'WEAPON_RAYMINIGUN',
		label = 'WEAPON_RAYMINIGUN',
		components = {},
		weight = 5000
	},

	{
		name = 'WEAPON_CARBINERIFLE',
		government = true,
		label = _U('weapon_carbinerifle'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_CARBINERIFLE_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_CARBINERIFLE_CLIP_02`},
			{name = 'clip_box', label = _U('component_clip_box'), hash = `COMPONENT_CARBINERIFLE_CLIP_03`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_MEDIUM`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP`},
			{name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_CARBINERIFLE_VARMOD_LUXE`}
		},
		weight = 5000,
		ammoType = 'AMMO_RIFLE'
	},

	{
		name = 'WEAPON_ADVANCEDRIFLE',
		label = _U('weapon_advancedrifle'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_ADVANCEDRIFLE_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_ADVANCEDRIFLE_CLIP_02`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_SMALL`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_ADVANCEDRIFLE_VARMOD_LUXE`}
		},
		weight = 5000,
		ammoType = 'AMMO_RIFLE'
	},

	{
		name = 'WEAPON_SPECIALCARBINE',
		label = _U('weapon_specialcarbine'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_SPECIALCARBINE_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_SPECIALCARBINE_CLIP_02`},
			{name = 'clip_drum', label = _U('component_clip_drum'), hash = `COMPONENT_SPECIALCARBINE_CLIP_03`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_MEDIUM`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP_02`},
			{name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_SPECIALCARBINE_VARMOD_LOWRIDER`}
		},
		weight = 5000,
		ammoType = 'AMMO_RIFLE'
    },

    {
        name = 'WEAPON_SPECIALCARBINE_MK2',
        label = _U('weapon_specialcarbine_mk2'),
        components = {
            {name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_SPECIALCARBINE_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_SPECIALCARBINE_CLIP_02`},
			{name = 'clip_drum', label = _U('component_clip_drum'), hash = `COMPONENT_SPECIALCARBINE_CLIP_03`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_MEDIUM`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP_02`},
			{name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_SPECIALCARBINE_VARMOD_LOWRIDER`}
		},
		weight = 5000,
		ammoType = 'AMMO_RIFLE'
    },

	{
		name = 'WEAPON_BULLPUPRIFLE',
		label = _U('weapon_bullpuprifle'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_BULLPUPRIFLE_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_BULLPUPRIFLE_CLIP_02`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_SMALL`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP`},
			{name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_BULLPUPRIFLE_VARMOD_LOW`}
		},
		weight = 5000,
		ammoType = 'AMMO_RIFLE'
	},

	{
		name = 'WEAPON_COMPACTRIFLE',
		label = _U('weapon_compactrifle'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_COMPACTRIFLE_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_COMPACTRIFLE_CLIP_02`},
		},
		weight = 5000,
		ammoType = 'AMMO_RIFLE'
	},

	{
		name = 'WEAPON_MG',
		label = _U('weapon_mg'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_MG_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_MG_CLIP_02`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_SMALL_02`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_MG_VARMOD_LOWRIDER`}
		},
		weight = 20000,
		ammoType = 'AMMO_MG'
	},

	{
		name = 'WEAPON_COMBATMG',
		label = _U('weapon_combatmg'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_COMBATMG_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_COMBATMG_CLIP_02`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_MEDIUM`},
			{name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_COMBATMG_VARMOD_LOWRIDER`}
		},
		weight = 20000,
		ammoType = 'AMMO_MG'
	},

	{
		name = 'WEAPON_GUSENBERG',
		label = _U('weapon_gusenberg'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_GUSENBERG_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_GUSENBERG_CLIP_02`},
		},
		weight = 5000,
		ammoType = 'AMMO_MG'
	},

	{
		name = 'WEAPON_SNIPERRIFLE',
		label = _U('weapon_sniperrifle'),
		components = {
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_LARGE`},
			{name = 'scope_advanced', label = _U('component_scope_advanced'), hash = `COMPONENT_AT_SCOPE_MAX`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP_02`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_SNIPERRIFLE_VARMOD_LUXE`}
		},
		weight = 8000,
		ammoType = 'AMMO_SNIPER'
	},

	{
		name = 'WEAPON_HEAVYSNIPER',
		label = _U('weapon_heavysniper'),
		components = {
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_LARGE`},
			{name = 'scope_advanced', label = _U('component_scope_advanced'), hash = `COMPONENT_AT_SCOPE_MAX`}
		},
		weight = 8000,
		ammoType = 'AMMO_SNIPER'
	},

	{
		name = 'WEAPON_MARKSMANRIFLE',
		label = _U('weapon_marksmanrifle'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_MARKSMANRIFLE_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_MARKSMANRIFLE_CLIP_02`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_LARGE_FIXED_ZOOM`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP`},
			{name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_MARKSMANRIFLE_VARMOD_LUXE`}
		},
		weight = 6000,
		ammoType = 'AMMO_SNIPER'
	},

	{name = 'WEAPON_GRENADELAUNCHER', label = _U('weapon_grenadelauncher'), components = {}, ammoType = 'AMMO_GRENADELAUNCHER', weight = 15000},
	{name = 'WEAPON_RPG', label = _U('weapon_rpg'), components = {}, ammoType = 'AMMO_RPG', weight = 15000},
	{name = 'WEAPON_STINGER', label = _U('weapon_stinger'), components = {}, weight = 6000},
	{name = 'WEAPON_MINIGUN', label = _U('weapon_minigun'), components = {}, weight = 20000},
	{name = 'WEAPON_GRENADE', label = _U('weapon_grenade'), components = {}, ammoType = 'AMMO_GRENADE'},
	{name = 'WEAPON_FLASHBANG', label = "Flashbang", components = {}, ammoType = 'AMMO_GRENADE'},
	{name = 'WEAPON_STICKYBOMB', label = _U('weapon_stickybomb'), components = {}, ammoType = 'AMMO_STICKYBOMB'},
	{name = 'WEAPON_SMOKEGRENADE', label = _U('weapon_smokegrenade'), components = {}, ammoType = 'AMMO_SMOKEGRENADE'},
	{name = 'WEAPON_BZGAS', label = _U('weapon_bzgas'), components = {}, ammoType = 'AMMO_BZGAS'},
	{name = 'WEAPON_MOLOTOV', label = _U('weapon_molotov'), components = {}, ammoType = 'AMMO_MOLOTOV'},
	{name = 'WEAPON_FIREEXTINGUISHER', label = _U('weapon_fireextinguisher'), components = {}},
	{name = 'WEAPON_PETROLCAN', label = _U('weapon_petrolcan'), components = {}, ammoType = 'AMMO_PETROLCAN'},
	{name = 'WEAPON_DIGISCANNER', label = _U('weapon_digiscanner'), components = {}},
	{name = 'WEAPON_BALL', label = _U('weapon_ball'), components = {}},
	{name = 'WEAPON_BOTTLE', label = _U('weapon_bottle'), components = {}},
	{name = 'WEAPON_DAGGER', label = _U('weapon_dagger'), components = {}},
	{name = 'WEAPON_FIREWORK', label = _U('weapon_firework'), components = {}},
	{name = 'WEAPON_MUSKET', label = _U('weapon_musket'), components = {}},
	{name = 'WEAPON_STUNGUN', label = _U('weapon_stungun'), components = {}},
	{name = 'WEAPON_HOMINGLAUNCHER', label = _U('weapon_hominglauncher'), components = {}},
	{name = 'WEAPON_PROXMINE', label = _U('weapon_proxmine'), components = {}},
	{name = 'WEAPON_SNOWBALL', label = _U('weapon_snowball'), components = {}},
	{name = 'WEAPON_FLAREGUN', label = _U('weapon_flaregun'), components = {}},
	{name = 'WEAPON_GARBAGEBAG', label = _U('weapon_garbagebag'), components = {}},
	{name = 'WEAPON_HANDCUFFS', label = _U('weapon_handcuffs'), components = {}},
	{name = 'WEAPON_MARKSMANPISTOL', label = _U('weapon_marksmanpistol'), components = {}},
	{name = 'WEAPON_KNUCKLE', label = _U('weapon_knuckle'), components = {}},
	{name = 'WEAPON_HATCHET', label = _U('weapon_hatchet'), components = {}},
	{name = 'WEAPON_RAILGUN', label = _U('weapon_railgun'), components = {}},
	{name = 'WEAPON_MACHETE', label = _U('weapon_machete'), components = {}},
	{name = 'WEAPON_SWITCHBLADE', label = _U('weapon_switchblade'), components = {}},
	{name = 'WEAPON_DBSHOTGUN', label = _U('weapon_dbshotgun'), components = {}},
	{name = 'WEAPON_AUTOSHOTGUN', label = _U('weapon_autoshotgun'), components = {}},
	{name = 'WEAPON_BATTLEAXE', label = _U('weapon_battleaxe'), components = {}},
	{name = 'WEAPON_COMPACTLAUNCHER', label = _U('weapon_compactlauncher'), components = {}},
	{name = 'WEAPON_PIPEBOMB', label = _U('weapon_pipebomb'), components = {}},
	{name = 'WEAPON_POOLCUE', label = _U('weapon_poolcue'), components = {}},
	{name = 'WEAPON_WRENCH', label = _U('weapon_wrench'), components = {}},
	{name = 'WEAPON_FLASHLIGHT', label = _U('weapon_flashlight'), components = {}},
	{name = 'GADGET_NIGHTVISION', label = _U('gadget_nightvision'), components = {}},
	{name = 'GADGET_PARACHUTE', label = _U('gadget_parachute'), components = {}},
	{name = 'WEAPON_FLARE', label = _U('weapon_flare'), components = {}},
	{name = 'WEAPON_DOUBLEACTION', label = _U('weapon_doubleaction'), components = {}}
}
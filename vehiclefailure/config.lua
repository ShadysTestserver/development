------------------------------------------
--	iEnsomatic RealisticVehicleFailure  --
------------------------------------------
--
--	Created by Jens Sandalgaard
--
--	This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
--
--	https://github.com/iEns/RealisticVehicleFailure
--


-- Configuration:

-- IMPORTANT: Some of these values MUST be defined as a floating point number. ie. 10.0 instead of 10

cfg = {
	deformationMultiplier = -1,					-- How much should the vehicle visually deform from a collision. Range 0.0 to 10.0 Where 0.0 is no deformation and 10.0 is 10x deformation. -1 = Don't touch. Visual damage does not sync well to other players.
	deformationExponent = 0.8,					-- How much should the handling file deformation setting be compressed toward 1.0. (Make cars more similar). A value of 1=no change. Lower values will compress more, values above 1 it will expand. Dont set to zero or negative.
	collisionDamageExponent = 0.6,				-- How much should the handling file deformation setting be compressed toward 1.0. (Make cars more similar). A value of 1=no change. Lower values will compress more, values above 1 it will expand. Dont set to zero or negative.

	damageFactorEngine = 15.0,					-- Sane values are 1 to 100. Higher values means more damage to vehicle. A good starting point is 10
	damageFactorBody = 15.0,					-- Sane values are 1 to 100. Higher values means more damage to vehicle. A good starting point is 10
	damageFactorPetrolTank = 20.0,				-- Sane values are 1 to 200. Higher values means more damage to vehicle. A good starting point is 64
	engineDamageExponent = 0.7,					-- How much should the handling file engine damage setting be compressed toward 1.0. (Make cars more similar). A value of 1=no change. Lower values will compress more, values above 1 it will expand. Dont set to zero or negative.
	weaponsDamageMultiplier = 1.0,				-- How much damage should the vehicle get from weapons fire. Range 0.0 to 10.0, where 0.0 is no damage and 10.0 is 10x damage. -1 = don't touch
	degradingHealthSpeedFactor = 0.8,			-- Speed of slowly degrading health, but not failure. Value of 10 means that it will take about 0.25 second per health point, so degradation from 800 to 305 will take about 2 minutes of clean driving. Higher values means faster degradation
	cascadingFailureSpeedFactor = 3.0,			-- Sane values are 1 to 100. When vehicle health drops below a certain point, cascading failure sets in, and the health drops rapidly until the vehicle dies. Higher values means faster failure. A good starting point is 8

	degradingFailureThreshold = 650.0,			-- Below this value, slow health degradation will set in
	cascadingFailureThreshold = 300.0,			-- Below this value, health cascading failure will set in
	engineSafeGuard = 100.0,					    -- Final failure value. Set it too high, and the vehicle won't smoke when disabled. Set too low, and the car will catch fire from a single bullet to the engine. At health 100 a typical car can take 3-4 bullets to the engine before catching fire.

	torqueMultiplierEnabled = true,				-- Decrease engine torque as engine gets more and more damaged

	limpMode = true,							-- If true, the engine never fails completely, so you will always be able to get to a mechanic unless you flip your vehicle and preventVehicleFlip is set to true
	limpModeMultiplier = 0.15,					-- The torque multiplier to use when vehicle is limping. Sane values are 0.05 to 0.25

	preventVehicleFlip = true,					-- If true, you can't turn over an upside down vehicle

	sundayDriver = true,						-- If true, the accelerator response is scaled to enable easy slow driving. Will not prevent full throttle. Does not work with binary accelerators like a keyboard. Set to false to disable. The included stop-without-reversing and brake-light-hold feature does also work for keyboards.
	sundayDriverAcceleratorCurve = 6.0,			-- The response curve to apply to the accelerator. Range 0.0 to 10.0. Higher values enables easier slow driving, meaning more pressure on the throttle is required to accelerate forward. Does nothing for keyboard drivers
	sundayDriverBrakeCurve = 6.0,				-- The response curve to apply to the Brake. Range 0.0 to 10.0. Higher values enables easier braking, meaning more pressure on the throttle is required to brake hard. Does nothing for keyboard drivers

	displayBlips = false,						-- Show blips for mechanics locations

	compatibilityMode = false,					-- prevents other scripts from modifying the fuel tank health to avoid random engine failure with BVA 2.01 (Downside is it disabled explosion prevention)

	randomTireBurstInterval = 0,	--1200		-- Number of minutes (statistically, not precisely) to drive above 22 mph before you get a tire puncture. 0=feature is disabled


	-- Class Damagefactor Multiplier
	-- The damageFactor for engine, body and Petroltank will be multiplied by this value, depending on vehicle class
	-- Use it to increase or decrease damage for each class

	classDamageMultiplier = {
		[0] = 	1.0,		--	0: Compacts
		1.0,		--	1: Sedans
		1.0,		--	2: SUVs
		0.95,		--	3: Coupes
		1.0,		--	4: Muscle
		0.95,		--	5: Sports Classics
		0.95,		--	6: Sports
		0.95,		--	7: Super
		0.27,		--	8: Motorcycles
		0.7,		--	9: Off-road
		0.70,		--	10: Industrial
		0.75,		--	11: Utility
		0.85,		--	12: Vans
		1.0,		--	13: Cycles
		0.0,		--	14: Boats
		2.0,		--	15: Helicopters
		0.7,		--	16: Planes
		0.75,		--	17: Service
		0.85,		--	18: Emergency
		0.67,		--	19: Military
		0.68,		--	20: Commercial
		1.0			--	21: Trains
	},

	modelDamageMultiplier = {
		[391354341] = 0.0,
		[-1277734734] = 0.0,
		[-979504065] = 0.0,
		[1481382297] = 0.0,
		[1779023124] = 0.0,
		[-551114928] = 0.0,
		[-253703484] = 0.0,
		[28601451] = 0.0,
		[-197095074] = 0.0,
		[-248616734] = 0.0,
		[1420875515] = 0.0,
		[`sanchez`] = 0.2,
		[`veto2`] = 0.0
	}
}

SpeedZones = {
	{ Coords = vector3(865.95, -920.17, 25.61), Radius = 60.0, MaxSpeed = 50.0 }
}

-- End of Main Configuration

-- Configure Repair system

-- id=446 for wrench icon, id=72 for spraycan icon

local planeClasses = {
	[15] = true, -- Helicopters
	[16] = true -- Planes
}
local boatClasses = {
	[14] = true
}
repairCfg = {
	BlipType = 446,
	BlipName = "Mechanic",
	Radius = 25.0,
	mechanics = {
		{ coords = vector3(1171.73, -3242.54, -10.28) },	-- LSC Burton
		{ coords = vector3(1160.53, -3242.42, -10.28) },
		{ coords = vector3(-337.38, -136.92, 38.57) },	-- LSC Burton
		{ coords = vector3(-1155.53, -2007.18, 12.74) },	-- LSC by airport
		{ coords = vector3(731.81, -1088.82, 21.73) },	-- LSC La Mesa
		{ coords = vector3(1175.04, 2640.21, 37.32) },	-- LSC Harmony
		{ coords = vector3(110.99, 6626.39, 30.89) },	-- LSC Paleto Bay
		{ coords = vector3(829.12, -916.34, 24.52) },
		{ coords = vector3(-1270.65, -3383.34, 13.54) },
		{ coords = vector3(-211.73, -1323.19, 30.71) }, --- bennys
		{ coords = vector3(-1243.96, -3091.83, 18.62), radius = 500.0, classes = planeClasses }, -- LSIA
		{ coords = vector3(-765.58, -1456.92, 4.18), radius = 100.0, classes = { [14] = true, [15] = true } }, -- Harbor
		{ coords = vector3(3866.42, 4464.00, 3.47), radius = 50.0, classes = boatClasses }, -- Harbor
		{ coords = vector3(-1611.42, 5260.00, 3.47), radius = 50.0, classes = boatClasses }, -- Harbor
		{ coords = vector3(712.85, 4097.00, 3.47), radius = 50.0, classes = boatClasses }, -- Harbor
		{ coords = vector3(23.8, -2806.8, 4.8), radius = 50.0, classes = boatClasses },
		{ coords = vector3(-3448.9, 953.8, 0.0), radius = 50.0, classes = boatClasses },
		{ coords = vector3(1422.451, 3159.293, 45.39743), radius = 450.0, classes = planeClasses }, -- Sandy Shores
		{ coords = vector3(2030.813, 4760.434, 43.07242), radius = 130.0, classes = planeClasses }, -- Grapeseed
		{ coords = vector3(-2683.266, 3250.859, 35.90871), radius = 190.0, classes = planeClasses }, -- Mil Base 1
		{ coords = vector3(-2138.018, 3077.354, 36.78811), radius = 450.0, classes = planeClasses },
		--	{name="Mechanic", id=446, r=18.0, x=538.0,   y=-183.0,  z=54.0},	-- Mechanic Hawic
		--	{name="Mechanic", id=446, r=15.0, x=1774.0,  y=3333.0,  z=41.0},	-- Mechanic Sandy Shores Airfield
		--	{name="Mechanic", id=446, r=15.0, x=1143.0,  y=-776.0,  z=57.0},	-- Mechanic Mirror Park
		--	{name="Mechanic", id=446, r=30.0, x=2508.0,  y=4103.0,  z=38.0},	-- Mechanic East Joshua Rd.
		--	{name="Mechanic", id=446, r=16.0, x=2006.0,  y=3792.0,  z=32.0},	-- Mechanic Sandy Shores gas station
		--	{name="Mechanic", id=446, r=25.0, x=484.0,   y=-1316.0, z=29.0},	-- Hayes Auto, Little Bighorn Ave.
		--	{name="Mechanic", id=446, r=33.0, x=-1419.0, y=-450.0,  z=36.0},	-- Hayes Auto Body Shop, Del Perro
		--	{name="Mechanic", id=446, r=33.0, x=268.0,   y=-1810.0, z=27.0},	-- Hayes Auto Body Shop, Davis
		--	{name="Mechanic", id=446, r=24.0, x=288.0,   y=-1730.0, z=29.0},	-- Hayes Auto, Rancho (Disabled, looks like a warehouse for the Davis branch)
		--	{name="Mechanic", id=446, r=27.0, x=1915.0,  y=3729.0,  z=32.0},	-- Otto's Auto Parts, Sandy Shores
		--	{name="Mechanic", id=446, r=44.0, x=-212.0,  y=-1378.0, z=31.0},	-- Glass Heroes, Strawberry
		--	{name="Mechanic", id=446, r=33.0, x=258.0,   y=2594.0,  z=44.0},	-- Mechanic Harmony
		--	{name="Mechanic", id=446, r=25.0, x=903.0,   y=3563.0,  z=34.0},	-- Auto Repair, Grand Senora Desert
		--	{name="Mechanic", id=446, r=25.0, x=437.0,   y=3568.0,  z=38.0}		-- Auto Shop, Grand Senora Desert
	},

	fixMessages = {
		"Je hebt olie in je auto gegoten",
		"Je hebt het olie lek gedicht met een stuk kaugom",
		"Je hebt de olie leiding gemaakt met wat duct tape",
		"Je hebt wat moeren vast gedraaid",
		"Er is een repareer elf langs gevlogen",
		"Je hebt wat WD40 op je sleutel gespoten",
		"Je hebt zo hard gehuild dat die het weer doet",
		"Je hebt de benzinetank aangevuld met tranen"
	},
	fixMessageCount = 8,

	noFixMessages = {
		"Ja, de accu zit er nog in.",
		"Je hebt gekeken naar je motor, en die zit er nog in",
		"Je hebt gekeken of de ducttape nog op de juiste plek zat",
		"Je hebt de radio wat harder gezet, nu hoor je het geklop van de motor niet meer",
		"WD-40 heeft niets gedaan, misschien doet hij het nog?",
		"Repareer niet iets wat niet stuk is, maar toch heeft het niet geholpen"
	},
	noFixMessageCount = 6
}

RepairEveryoneWhitelisted = false
RepairWhitelist =
{
	["steam:110000106393694"] = true,
	["steam:110000107563788"] = true,
	["steam:1100001041a0e5d"] = true
}

-------------------
-- C o n f i g s --
-------------------

CoolDown = 900
NoMechanicCoolDown = 300
companyName = "ANWB"
companyIcon = "CHAR_LS_CUSTOMS" -- https://wiki.gtanet.work/index.php?title=Notification_Pictures
spawnRadius = 75               -- Default Value:
drivingStyle = 1074528427           -- Default Value: 786603
simplerRepair = false           -- When enabled, instead of getting out of the vehicle to repair, the mechanic stops his vehicle and the repair happens automatically.
repairComsticDamage = true     -- When enabled, the vehicle's cosmetic damage gets reset.
flipVehicle = true             -- When enabled, the vehicle will be flipped if on roof or side after repair.

-- To change the chat command (def. /mechanic), see line 1 of client.lua

-- Edit / Add Drivers and their information here!

mechPeds = {
	--  * Find the icons here:      https://wiki.gtanet.work/index.php?title=Notification_Pictures
	--  * Find the ped models here: https://wiki.gtanet.work/index.php?title=Peds
	--  * Find the vehicles here    https://wiki.gtanet.work/index.php?title=Vehicle_Models
	--  * Find the colours here:    https://wiki.gtanet.work/index.php?title=Vehicle_Colors

	[1] = {name = "ANWB David", icon = "CHAR_MP_MECHANIC", model = "s_m_m_ccrew_01", vehicle = 'asterope', colour = 0, 
	['lines'] = {
		"Zo goed als nieuw!",
		"Hopsakee, gefixed!",
		"Het zou nu wel in orde moeten zijn",
		"Done!",
		"Wat kan ik zeggen ... meester in men vak!",
		"Moest wel een beetje magie gebruiken.. maar..het werkt weer!",
		"ANWB tot je dienst! ",
		"Easy peasy!",
		"volgende keer beetje rustiger met de gas pedaal he ",
		"Het enigste wat ik niet kan fixen is mijn huwelijk..",
		"Gerepareerd .. weer zo goed als nieuw",
		"Het was niet makkelijk maar het zou nu weer moeten werken",}
	},

	[2] = {name = "ANWB Tim", icon = "CHAR_MP_BIKER_MECHANIC", model = "s_m_m_ccrew_01", vehicle = 'asterope', colour = 0, 
	['lines'] = {
		"Zo goed als nieuw!",
		"Hopsakee, gefixed!",
		"Het zou nu wel in orde moeten zijn",
		"Done!",
		"Wat kan ik zeggen ... meester in men vak!",
		"Moest wel een beetje magie gebruiken.. maar..het werkt weer!",
		"ANWB tot je dienst! ",
		"Easy peasy!",
		"volgende keer beetje rustiger met de gas pedaal he ",
		"Het enigste wat ik niet kan fixen is mijn huwelijk..",
		"Gerepareerd .. weer zo goed als nieuw",
		"Het was niet makkelijk maar het zou nu weer moeten werken",}
	},

	-- You can use this template to make your own driver.

	--  * Find the icons here:      https://wiki.gtanet.work/index.php?title=Notification_Pictures
	--  * Find the ped models here: https://wiki.gtanet.work/index.php?title=Peds
	--  * Find the colours here:    https://wiki.gtanet.work/index.php?title=Vehicle_Colors
	--  * Driver ID needs to be a number (in sequential order from the previous one. In this example it would be 3).
	--[[

	--Edit the NAME, ICON, PED MODEL and TRUCK COLOUR here:
	[driver_ID] = {name = "driver_name", icon = "driver_icon", model = "ped_model", vehicle = 'vehicle_model' colour = 'driver_colour',

	--You can add or edit any existing vehicle fix lines here:
	[1] = {"Sample text 1","Sample text 2",}}, -- lines of dialogue.
	]]
}
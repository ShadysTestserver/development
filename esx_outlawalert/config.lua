Config = {}

Config.Locale = 'en'

-- Set the time (in minutes) during the player is outlaw
Config.Timer = 1

-- Set if show alert when player use gun
Config.GunshotAlert = true

-- In seconds
Config.BlipGunTime = 30

-- Blip radius, in float value!
Config.BlipGunRadius = 30.0
Config.IslandBlipRadius = 1250.0

-- Show notification when cops steal too?
Config.ShowCopsMisbehave = false

-- Jobs in this table are considered as cops
Config.WhitelistedCops = {
	'police',
	'kmar',
	'offpolice',
	'offkmar'
}
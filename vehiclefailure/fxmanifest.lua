fx_version 'adamant'
game 'gta5'

lua54 'yes'

version "1.0.0"
use_version_checker "true"

client_scripts {
	'@esx_boilerplate/natives.lua',
	'@esx_boilerplate/utils/lazy_esx.lua',
	'@esx_boilerplate/utils/logger.lua',
	'@esx_boilerplate/utils/commands.lua',
	'@es_extended/locale.lua',
	"config.lua",
	"client.lua"
}

server_scripts {
	'@esx_boilerplate/natives_server.lua',
	'@esx_boilerplate/utils/lazy_esx.lua',
	'@anticheat/event_s.lua',
	'@mysql-async/lib/MySQL.lua',
	"config.lua",
	"server.lua"
}
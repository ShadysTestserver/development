fx_version 'adamant'
game 'gta5'

description 'esx_report - By WillemSpoelstra'

version '1.0.0'

client_script {
	'@esx_boilerplate/natives.lua',
	'@es_extended/locale.lua',
	'@esx_boilerplate/utils/logger.lua',
	'@esx_boilerplate/utils/cache.lua',
	'@esx_boilerplate/utils/commands.lua',
	'locales/en.lua',
	'locales/nl.lua',
	'config.lua',
	'client.lua',
	
}

server_scripts {
	'@esx_boilerplate/natives_server.lua',
	'@mysql-async/lib/MySQL.lua',
	'@es_extended/locale.lua',
	'locales/en.lua',
	'locales/nl.lua',
	'config.lua',
	'server.lua',
	
}
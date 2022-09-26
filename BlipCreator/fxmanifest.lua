fx_version 'adamant'
game 'gta5'
use_fxv2_oal 'true'

client_scripts {
    '@esx_boilerplate/natives.lua',
	'@esx_boilerplate/time.lua',
    '@esx_boilerplate/utils/server_identifier.lua',
    '@baseevents/lib/vehicle.lua',
    '@es_extended/locale.lua',
    '@esx_boilerplate/utils/logger.lua',
    '@esx_boilerplate/utils/lazy_esx.lua',
    'config.lua',
    'lists/weapons.lua',
    'lists/bones.lua',
    'client.lua'
}

server_scripts {
    'config.lua',
    'server.lua'
}


data_file "TIMECYCLEMOD_FILE" "timecycle.xml"

dependencies {
    'es_extended'
}
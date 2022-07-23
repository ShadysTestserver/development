fx_version 'adamant'
game 'gta5'
lua54 'yes'

client_scripts {
    '@esx_boilerplate/utils/lazy_esx.lua',
    '@esx_boilerplate/natives.lua',
    '@es_extended/locale.lua',
    '@esx_boilerplate/utils/logger.lua',
    '@esx_boilerplate/utils/threads.lua',
    '@baseevents/lib/vehicle.lua',
    'client/client.lua',
    'config.lua'
}


server_scripts {
    '@esx_boilerplate/utils/lazy_esx.lua',
    '@mysql-async/lib/MySQL.lua',
    'config.lua',
    'server.lua'
}

-- Uncomment the desired version
ui_page('client/html/UI-nl.html')

files {
	'client/html/UI-nl.html',
    'client/html/style.css',
    'client/html/media/font/Bariol_Regular.otf',
    'client/html/media/font/Vision-Black.otf',
    'client/html/media/font/Vision-Bold.otf',
    'client/html/media/font/Vision-Heavy.otf',
    'client/html/media/img/bg.png',
    'client/html/media/img/circle.png',
    'client/html/media/img/curve.png',
    'client/html/media/img/fingerprint.png',
    'client/html/media/img/fingerprint.jpg',
    'client/html/media/img/graph.png',
    'client/html/media/img/logo-big.png',
    'client/html/media/img/logo-top.png',
    'client/html/media/img/logo-ing.svg',
    'client/html/media/img/logo-ing.png'
}


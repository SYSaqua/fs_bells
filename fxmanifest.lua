fx_version 'cerulean'
games { 'gta5' }
author 'Aqua'
lua54 'yes'
description 'FS | Bells'
version '1.0'

client_scripts {
    "config/config.lua",
    "client/client.lua",
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "@mysql-async/lib/MySQL.lua",
    "config/config.lua",
    "server/server.lua",
}

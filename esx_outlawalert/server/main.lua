ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)



RegisterServerEvent('esx_outlawalert:gunshotInProgress')
AddEventHandler('esx_outlawalert:gunshotInProgress', function(targetCoords, streetName, weapontext)
	if weapontext == "AK-74" 
	or weapontext == "AK-74U" 
	or weapontext == "AK-12" 
	or weapontext == "Skorpion vz. 61" then
		TriggerClientEvent('esx_outlawalert:outlawNotify', -1, _U('gunshot', "Automatisch", streetName))
	else
		TriggerClientEvent('esx_outlawalert:outlawNotify', -1, _U('gunshot', '', streetName))
	end
	TriggerClientEvent('esx_outlawalert:gunshotInProgress', -1, targetCoords)
end)

RegisterServerEvent('esx_outlawalert:airSpaceServerping')
AddEventHandler('esx_outlawalert:airSpaceServerping', function(playercoords, license, player, height)
	TriggerClientEvent('esx_outlawalert:airSpacePing', -1, playercoords, license, player, height)
end)

local islandshotcounter = 0
RegisterServerEvent('registerShot:island')
AddEventHandler('registerShot:island', function()
	islandshotcounter = islandshotcounter + 1
	if islandshotcounter == 15 then
		islandshotcounter = 0
		islandcoords = vector3(4840.571, -5174.425, 2.0)
		TriggerClientEvent("shots:islandNotification", -1, islandcoords)
	end
end)



TriggerEvent('es:addGroupCommand', 'schietmelding', 'user', function(source, args, user)
	TriggerClientEvent('sts:outlaw', source)
end, function(source, args, user)
	TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Insufficient Permissions.' } })
end, { help = "Schietmeldingen aan/uitzetten", params = {} })


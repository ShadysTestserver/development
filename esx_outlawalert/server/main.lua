ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)



RegisterServerEvent('esx_outlawalert:gunshotInProgress')
AddEventHandler('esx_outlawalert:gunshotInProgress', function(targetCoords, streetName, weapontext, lastcoords)
	local heading = "onbekend"
	local heading2 = "onbekend"
	if lastcoords.y > targetCoords.y then
		heading = "noord"
		if lastcoords.x > targetCoords.x then
			heading2 = "oosten"
		elseif lastcoords.x < targetCoords.x then
			heading2 = "westen"
		end
	elseif lastcoords.y < targetCoords.y then
		heading = "zuid"
		if lastcoords.x > targetCoords.x then
			heading2 = "oosten"
		elseif lastcoords.x < targetCoords.x then
			heading2 = "westen"
		end
	end
	finalheading = (heading..heading2)


	if weapontext == "AK-74" 
	or weapontext == "AK-74U" 
	or weapontext == "AK-12" 
	or weapontext == "Skorpion vz. 61"
	or weapontext == "SMG"
	or weapontext == "M4A1"
	or weapontext == "HK416A1"
	or weapontext == "M249"
	or weapontext == "Minigun"
	or weapontext == "AP Pistol" then
		TriggerClientEvent('esx_outlawalert:outlawNotify', -1, _U('gunshot', " Automatisch", streetName, finalheading))
	else
		TriggerClientEvent('esx_outlawalert:outlawNotify', -1, _U('gunshot', '', streetName, finalheading))
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



--[[TriggerEvent('es:addGroupCommand', 'schietmelding', 'user', function(source, args, user)
	TriggerClientEvent('sts:outlaw', source)
end, function(source, args, user)
	TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Insufficient Permissions.' } })
end, { help = "Schietmeldingen aan/uitzetten", params = {} })
]]

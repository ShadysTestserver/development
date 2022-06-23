ESX = nil

local timing, isPlayerWhitelisted = math.ceil(Config.Timer * 60000), false
local streetName, playerGender

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(500)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(500)
	end

	ESX.PlayerData = ESX.GetPlayerData()


	isPlayerWhitelisted = refreshPlayerWhitelisted()
	checkschietmeldingstatus()
end)

RegisterNetEvent('esx:playerloaded')
AddEventHandler('esx:playerloaded', function(job)
	ESX.PlayerData.job = job
	checkschietmeldingstatus()
	isPlayerWhitelisted = refreshPlayerWhitelisted()
end)


RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
	checkschietmeldingstatus()
	isPlayerWhitelisted = refreshPlayerWhitelisted()
end)

local schietmeldingstatus = true

RegisterCommand('schietmelding', function(source)
	TriggerEvent('sts:outlaw')
end)

RegisterNetEvent('esx_outlawalert:outlawNotify')
AddEventHandler('esx_outlawalert:outlawNotify', function(alert)
	if isPlayerWhitelisted then
		if schietmeldingstatus == true then
			ESX.ShowNotification(alert)
		end
	end
end)


RegisterCommand('testschietmelding', function(source)
	if schietmeldingstatus == true then
		exports['esx_rpchat']:printToChat("Schietmelding", "^2aan")
	elseif schietmeldingstatus == false then
		exports['esx_rpchat']:printToChat("Schietmelding", "^1uit")
	end
end)

function checkschietmeldingstatus()
	local data = GetResourceKvpString("schietmeldingstatus")
	if data then
		schietmeldingstatus = json.decode(data)
	end
end

RegisterNetEvent('sts:outlaw')
AddEventHandler('sts:outlaw', function(xPlayer)
	if schietmeldingstatus == false then
    	schietmeldingstatus = true
		exports['esx_rpchat']:printToChat("Schietmelding", "Schietmeldingen staan nu ^2aan")
	elseif schietmeldingstatus == true then
		schietmeldingstatus = false
		exports['esx_rpchat']:printToChat("Schietmelding", "Schietmeldingen staan nu ^1uit")
	end
	SetResourceKvp("schietmeldingstatus", json.encode(false))
end)


Citizen.CreateThread(function()
	while true do
		Citizen.Wait(100)

		if NetworkIsSessionStarted() then
			DecorRegister('isOutlaw', 3)
			DecorSetInt(PlayerPedId(), 'isOutlaw', 1)

			return
		end
	end
end)

-- Gets the player's current street.
-- Aaalso get the current player gender


AddEventHandler('skinchanger:loadSkin', function(character)
	playerGender = character.sex
end)

function refreshPlayerWhitelisted()
	if not ESX.PlayerData then
		return false
	end

	if not ESX.PlayerData.job then
		return false
	end

	for k,v in ipairs(Config.WhitelistedCops) do
		if v == ESX.PlayerData.job.name then
			return true
		end
	end

	return false
end


RegisterNetEvent('esx_outlawalert:gunshotInProgress')
AddEventHandler('esx_outlawalert:gunshotInProgress', function(targetCoords)
	print("")
	if isPlayerWhitelisted and Config.GunshotAlert and schietmeldingstatus == true then
		local alpha = 250
		local gunshotBlip = AddBlipForRadius(targetCoords.x, targetCoords.y, targetCoords.z, Config.BlipGunRadius)

		SetBlipHighDetail(gunshotBlip, true)
		SetBlipColour(gunshotBlip, 1)
		SetBlipAlpha(gunshotBlip, alpha)
		SetBlipAsShortRange(gunshotBlip, true)

		while alpha ~= 0 do
			if alpha % 10 == 0 then
				SetBlipColour(gunshotBlip, 1)
			elseif alpha % 10 == 5 then
				SetBlipColour(gunshotBlip, 81)
			end
			
			Citizen.Wait(Config.BlipGunTime * 4)
			alpha = alpha - 1
			SetBlipAlpha(gunshotBlip, alpha)
			
			if alpha == 0 then
				RemoveBlip(gunshotBlip)
				return
			end
		end
	end
end)


RegisterNetEvent('shots:islandNotification')
AddEventHandler('shots:islandNotification', function(targetCoords)
	print("kct melding")
	if isPlayerWhitelisted then
		ESX.ShowNotification("~r~OPROEP KCT: <br />~s~Grootschalig vuurgevecht op het eiland, KCT graag uitrukken.")
		local alpha = 250
		local gunshotBlip = AddBlipForRadius(targetCoords.x, targetCoords.y, targetCoords.z, Config.IslandBlipRadius)

		SetBlipHighDetail(gunshotBlip, true)
		SetBlipColour(gunshotBlip, 1)
		SetBlipAlpha(gunshotBlip, alpha)
		SetBlipAsShortRange(gunshotBlip, true)

		while alpha ~= 0 do
			if alpha % 10 == 0 then
				SetBlipColour(gunshotBlip, 1)
			elseif alpha % 10 == 5 then
				SetBlipColour(gunshotBlip, 81)
			end
			
			Citizen.Wait(100)
			alpha = alpha - 1
			SetBlipAlpha(gunshotBlip, alpha)
			
			if alpha == 0 then
				RemoveBlip(gunshotBlip)
				return
			end
		end
	end
end)

RegisterNetEvent('esx_policejob:getHeight')
AddEventHandler('esx_policejob:getHeight', function(hasLicense)
	local playerPed = PlayerPedId()
	local vehicle = GetVehiclePedIsIn(playerPed)
	if GetPedInVehicleSeat(vehicle, -1) == playerPed then
		local height = GetEntityHeightAboveGround(playerPed)
		if height > 80.0 and isPlayerWhitelisted == false then
			TriggerServerEvent('esx_outlawalert:airSpaceServerping', GetEntityCoords(playerPed), false, playerPed, height)
		end
	end
end)


local running = false
RegisterNetEvent('esx_outlawalert:enteredPlane')
AddEventHandler('esx_outlawalert:enteredPlane', function()
	startairthread()
end)

RegisterNetEvent('esx_outlawalert:exitedPlane')
AddEventHandler('esx_outlawalert:exitedPlane', function(hasLicense)
	running = false
end)


function startairthread()
	running = true
	while running do
		getHeight()
		Citizen.Wait(3000)
	end
	running = false
end

function getHeight()
	local playerPed = PlayerPedId()
	local vehicle = GetVehiclePedIsIn(playerPed)
	if GetPedInVehicleSeat(vehicle, -1) == playerPed then
		local height = GetEntityHeightAboveGround(playerPed)
		if height > 80.0 then
			TriggerServerEvent('esx_outlawalert:airSpaceServerping', GetEntityCoords(playerPed), false, playerPed, height)
		end
	end
end

local radius = 150.0
local blips = {}
RegisterNetEvent('esx_outlawalert:airSpacePing')
AddEventHandler('esx_outlawalert:airSpacePing', function(coords, hasLicense, source, height)
	if isPlayerWhitelisted then
        local alpha = 350
        local random = math.random() * 2 * math.pi
		local randRadius = math.random(-radius, radius)
		local x,y,z = table.unpack(coords)

        -- Let's overcomplicate code :) get random point within the radius of the circle
        x = x + (randRadius * math.cos(random))
        y = y + (randRadius * math.sin(random))

		local airBlip = AddBlipForRadius(x, y, z, radius)
		blips[source] = airBlip

		SetBlipHighDetail(airBlip, true)
		if hasLicense then
			SetBlipColour(airBlip, 52)
		else
			SetBlipColour(airBlip, 52 --[[49]])
		end
        SetBlipAlpha(airBlip, alpha)
        SetBlipAsShortRange(airBlip, true)

		while alpha ~= 0 do
            Citizen.Wait(15 * 5)
            alpha = alpha - 1
            SetBlipAlpha(airBlip, alpha)

            if alpha == 0 or blips[source] ~= airBlip then
				RemoveBlip(airBlip)
                return
            end
        end
    end
end)

--[[RegisterCommand('testping', function()
	local playercoords = GetEntityCoords(PlayerPedId())
	local license = true
	local player = PlayerPedId()
	local height = 80
	TriggerServerEvent('esx_outlawalert:airSpaceServerping', playercoords, license, player, height)
end)]]


Citizen.CreateThread(function()
	while true do
		Citizen.Wait(2000)

		if DecorGetInt(PlayerPedId(), 'isOutlaw') == 2 then
			Citizen.Wait(timing)
			DecorSetInt(PlayerPedId(), 'isOutlaw', 1)
		end
	end
end)

local weaponHashes = {
	--[[2725352035] = 'Gevecht',
	[4194021054] = 'Dier',
	[148160082] = 'Dier',
	[-1716189206] = 'Mes',
	[1737195953] = 'Nightstick',
	[1317494643] = 'Hammer',
	[-1786099057] = 'Knuppel',
	[1141786504] = 'Golfclub',
	[2227010557] = 'Crowbar',]]
	[453432689] = 'M1911',
	[`WEAPON_PISTOL_MK2`] = 'Beretta 92',
	[`WEAPON_COMBATPISTOL`] = 'HK P2000',
	[`WEAPON_GLOCK18C`] = 'AP Pistol',
	[`WEAPON_PISTOL50`] = 'Desert Eagle',
	[`WEAPON_MINISMG`] = 'Skorpion vz. 61',
	[736523883] = 'SMG',
	[4024951519] = 'Assault SMG',
	[`WEAPON_COMPACTRIFLE`] = 'AK-74U',
	[-1074790547] = 'AK-74',
	[`WEAPON_ASSAULTRIFLE_MK2`] = 'AK-12',
	[-2084633992] = 'M4A1',
	[`WEAPON_CARBINERIFLE_MK2`] = 'HK416A1',
	[-1357824103] = 'AdvancedRifle',
	[1119849093] = 'Minigun',
	[2144741730] = 'M249',
	[487013001] = 'Pump Shotgun',
	[2017895192] = 'Sawn Off Shotgun',
	[-494615257] = 'Assault Shotgun',
	[-1654528753] = 'Bullpup Shotgun'
}

local lastAlert = 0

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		local playerPed = PlayerPedId()
		local playerCoords = GetEntityCoords(playerPed)
		local islandVec = vector3(4840.571, -5174.425, 2.0)
		local distance1 = #(playerCoords - islandVec)
		if IsPedArmed(playerPed, 4) then

			if IsPedShooting(playerPed) and not IsPedCurrentWeaponSilenced(playerPed) and Config.GunshotAlert then

				--if (isPlayerWhitelisted and Config.ShowCopsMisbehave) or not isPlayerWhitelisted then
				if isPlayerWhitelisted or not isPlayerWhitelisted then
					local randNum = math.random(0, 100)
					local Num = 50
					--[[if HasPedGotWeaponComponent(GetPlayerPed(-1), GetSelectedPedWeapon(PlayerPedId()), GetHashKey('component_at_pi_supp_02')) then
						Num = 90
					end]]
					local streetName = exports['mumble-voip']:getCurrentStreetName()
					if streetName == nil then
						streetName = streetName2
					end
					if distance1 > 2000.0 then
						if randNum > Num then
							if GetGameTimer() - lastAlert > 30000 then
								lastAlert = GetGameTimer()
								print('test1')
					
								DecorSetInt(playerPed, 'isOutlaw', 2)

								local weapon = GetSelectedPedWeapon(PlayerPedId())
								local weapontext = 'onbekend wapen'
								if weapon ~= nil then
									weapontext = weaponHashes[weapon]
								else
									print('weapon not found')
								end
		
								if weapontext == nil then
									weapontext = 'een onbekend'
								end
								coords = {
									x = ESX.Math.Round(playerCoords.x, 1),
									y = ESX.Math.Round(playerCoords.y, 1),
									z = ESX.Math.Round(playerCoords.z, 1)
								}
								Wait(10000)
								local playerCoords2 = GetEntityCoords(playerPed)
								finalcoords = {
									x = ESX.Math.Round(playerCoords2.x, 1),
									y = ESX.Math.Round(playerCoords2.y, 1),
									z = ESX.Math.Round(playerCoords2.z, 1)
								}
								print('test2')
								TriggerServerEvent('esx_outlawalert:gunshotInProgress', coords, streetName, weapontext, finalcoords)
							end
						end
					else
						TriggerServerEvent('registerShot:island')
					end
					Citizen.Wait(0)
				end
			end

		else
			Citizen.Wait(1000)
		end
	end
end)

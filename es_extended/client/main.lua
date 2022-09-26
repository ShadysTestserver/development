local isPaused, isDead, pickups = false, false, {}

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if NetworkIsPlayerActive(PlayerId()) then
			TriggerServerEvent('esx:onPlayerJoined')
			break
		end
	end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
	ESX.PlayerLoaded = true
	ESX.PlayerData = playerData

	-- check if player is coming from loading screen
	if GetEntityModel(PlayerPedId()) == GetHashKey('PLAYER_ZERO') then
		local defaultModel = GetHashKey('a_m_y_stbla_02')
		RequestModel(defaultModel)

		while not HasModelLoaded(defaultModel) do
			Citizen.Wait(10)
		end

		SetPlayerModel(PlayerId(), defaultModel)
		SetPedDefaultComponentVariation(PlayerPedId())
		SetPedRandomComponentVariation(PlayerPedId(), true)
		SetModelAsNoLongerNeeded(defaultModel)
	end

	-- freeze the player
	FreezeEntityPosition(PlayerPedId(), true)

	-- enable PVP
	SetCanAttackFriendly(PlayerPedId(), true, false)
	NetworkSetFriendlyFireOption(true)

	-- disable wanted level
	ClearPlayerWantedLevel(PlayerId())
	SetMaxWantedLevel(0)

	if Config.EnableHud then
		for k,v in ipairs(playerData.accounts) do
			local accountTpl = '<div><img src="img/accounts/' .. v.name .. '.png"/>&nbsp;{{money}}</div>'
			ESX.UI.HUD.RegisterElement('account_' .. v.name, k, 0, accountTpl, {money = ESX.Math.GroupDigits(v.money)})
		end

		local jobTpl = '<div>{{job_label}} - {{grade_label}}</div>'

		if playerData.job.grade_label == '' or playerData.job.grade_label == playerData.job.label then
			jobTpl = '<div>{{job_label}}</div>'
		end

		ESX.UI.HUD.RegisterElement('job', #playerData.accounts, 0, jobTpl, {
			job_label = playerData.job.label,
			grade_label = playerData.job.grade_label
		})
	end

	ESX.Game.Teleport(PlayerPedId(), {
		x = playerData.coords.x,
		y = playerData.coords.y,
		z = playerData.coords.z + 0.25,
		heading = playerData.coords.heading
	}, function()
		TriggerServerEvent('esx:onPlayerSpawn')
		TriggerEvent('esx:onPlayerSpawn')
		TriggerEvent('playerSpawned') -- compatibility with old scripts, will be removed soon
		TriggerEvent('esx:restoreLoadout')

		--[[Citizen.Wait(4000)
		FreezeEntityPosition(PlayerPedId(), false)
		playerloadedsucces()
		DoScreenFadeIn(10000)]]
		StartServerSyncLoops()
	end)

	--TriggerEvent('esx:loadingScreenOff')
end)

local encumbered = false
local overWeight = 0
local moveRate = 1.0
ESX.IsEncumbered = function(weight, maxWeight)
	return encumbered
end

AddEventHandler("esx:onInventoryUpdated", function()
	--ESX.SetEncumbered()
end)

local disableControls = {
	21, 22
}

local disableWalkingControls = {
	30, 31, 32, 33, 34, 35
}

ESX.SetEncumbered = function(weight, maxWeight)
	weight = weight or ESX.GetCurrentWeight()
	maxWeight = maxWeight or ESX.GetMaxWeight()
	overWeight = weight - maxWeight
	moveRate = math.clamp(1.0 - overWeight / 10000, 0.0, 1.0)
	if overWeight > 0 then
		if not encumbered then
			ESX.ShowNotification("~r~Je draagt te veel~s~!")
			encumbered = true
			Citizen.CreateThread(function()
				while encumbered do
					SetPedMoveRateOverride(PlayerPedId(), moveRate)
					for i=1, #disableControls do
						DisableControlAction(0, disableControls[i], true)
					end
					if moveRate < 0.3 and not IsPedSwimming(PlayerPedId()) then
						for i=1, #disableWalkingControls do
							DisableControlAction(0, disableWalkingControls[i], true)
							if IsDisabledControlJustPressed(0, disableWalkingControls[i]) then
								ESX.ShowNotification("~r~Je draagt te veel bij je om te lopen!~s~")
							end
						end
					else
						for i=1, #disableWalkingControls do
							if IsControlJustPressed(0, disableWalkingControls[i]) then
								ESX.ShowNotification("~r~Je loopt langzamer omdat je teveel bij je hebt!~s~")
							end
						end
					end

					Citizen.Wait(0)
				end
			end)
		end
	else
		if encumbered then
			encumbered = false
		end
	end
end

RegisterNetEvent('esx:setMaxWeight')
AddEventHandler('esx:setMaxWeight', function(newMaxWeight) 
	ESX.PlayerData.maxWeight = newMaxWeight 
	--ESX.SetEncumbered()
end)

AddEventHandler("transition:finished", function()
	local mouseType = GetConvarInt("profile_mouseType", 0)
	if mouseType ~= 0 then
        exports['esx_rpchat']:PrintToChat("SYSTEEM", "Je \"Mouse Input Method\" (onder \"Keyboard / Mouse\" in je GTA instellingen) staat niet op \"Raw Input\"! Hierdoor kan je muis niet correct werken in de menu's van FiveM!", { r = 255 })
		exports['esx_rpchat']:PrintToChat("SYSTEEM", "Als je problemen ondervindt met menu's die niet werken probeer dan deze instelling aan te passen!")
    end

	local voiceEnabled = GetConvarInt("profile_voiceEnable", 0)
	if voiceEnabled == 0 then
		exports['esx_rpchat']:PrintToChat("SYSTEEM", "Je hebt in je instellingen je voice chat uit staan! Ga aub naar je GTA Settings en zorg ervoor dat je voice chat correct ingesteld staat.", { r = 255 })
		exports['esx_rpchat']:PrintToChat("SYSTEEM", "Zorg ervoor dat bij Voice Chat, Voice Chat Enabled en Microphone Enabled beiden op On staan.")
	end

	local textureQuality = GetConvarInt("profile_gfxTextureQuality", 0)
	if textureQuality ~= 0 and not GetResourceKvpString("disable_citybugmsg") then
		local textureQualities = {
			[0] = "Normal",
			[1] = "High",
			[2] = "Very high"
		}
		Citizen.SetTimeout(30000, function()
			exports['esx_rpchat']:printToChat("WAARSCHUWING", ("Je texture quality staat hoger dan normal maar op %s! Dit betekent dat je voor city bug gerelateerde issues geen support zult ontvangen!"):format(textureQualities[textureQuality]), { r = 255 })
			exports['esx_rpchat']:printToChat("waarschuwing", "Doe ^*^_/aanvaardrisico^r om deze waarschuwing uit te schakelen.")
		end)
		RegisterCommand("aanvaardrisico", function()
			SetResourceKvp("disable_citybugmsg", "true")
		end)
	end

	local useInProcessGpu = GetConvar("nui_useInProcessGpu", "false")
	if useInProcessGpu == "false" then
		exports['esx_rpchat']:PrintToChat("SYSTEEM", "Je hebt in je FiveM instellingen \"NUI in-process GPU\" uit staan, als je vertraging hebt met bepaalde acties qua menu's, telefoon en chat zorg er dan voor dat deze instelling aan staat!", { r = 255 })
		exports['esx_rpchat']:PrintToChat("SYSTEEM", "Volledige beschrijving van instelling is: \"Fix 'UI lag' at high GPU usage, but may cause reliability issues with GPU crashes\"")
	end
end)

function DisableCollisionsBetweenEntities(entityOne, entityTwo)
	SetEntityNoCollisionEntity(entityOne, entityTwo, true)
	SetEntityNoCollisionEntity(entityTwo, entityOne, true)
end

function DisableCollisions()
	local playerPed = PlayerPedId()
	local players = GetActivePlayers()
	for i=1, #players do
		local otherPed = GetPlayerPed(players[i])
		local vehicle = GetVehiclePedIsIn(otherPed)
		if vehicle ~= 0 then
			DisableCollisionsBetweenEntities(vehicle, playerPed)
		end
		DisableCollisionsBetweenEntities(otherPed, playerPed)
	end
end

function SpawnProtection()
	SetPlayerUnderwaterTimeRemaining(PlayerId(), 100.0)
	SetPlayerInvincible(PlayerId(), true)
	DisableCollisions()
end

local isFirstSpawn = true
AddEventHandler('playerSpawned', function()
	while not ESX.PlayerLoaded do
		if isFirstSpawn then
			FreezeEntityPosition(PlayerPedId(), true)
			SetEntityVisible(PlayerPedId(), false)
			SetPlayerInvincible(PlayerId(), true)
			SetPlayerUnderwaterTimeRemaining(PlayerId(), 100.0)
		end
		Citizen.Wait(100)
	end

	if isFirstSpawn then
		isFirstSpawn = false
        RequestCollisionAtCoord(ESX.PlayerData.coords.x, ESX.PlayerData.coords.y, ESX.PlayerData.coords.z)

		local playerPed = PlayerPedId()
		SetEntityCoordsNoOffset(playerPed, ESX.PlayerData.coords.x, ESX.PlayerData.coords.y, ESX.PlayerData.coords.z + 1.0)
		if not IsScreenFadedIn() or IsPlayerSwitchInProgress() or GetIsLoadingScreenActive() then
			Citizen.CreateThread(function()
				FreezeEntityPosition(PlayerPedId(), true)
				SetEntityVisible(PlayerPedId(), false)
				SpawnProtection()
				TriggerEvent("loadingDone")
				while (not IsScreenFadedIn() or IsPlayerSwitchInProgress() or GetIsLoadingScreenActive()) do
					RequestCollisionAtCoord(ESX.PlayerData.coords.x, ESX.PlayerData.coords.y, ESX.PlayerData.coords.z)
					SpawnProtection()
					Citizen.Wait(0)
				end
				playerPed = PlayerPedId()
				SpawnProtection()
				SetEntityVisible(PlayerPedId(), true)
				print("[@es_extended/main.lua:63] Final coords set!")

				FreezeEntityPosition(PlayerPedId(), false)
				TriggerServerEvent("esx:loadingDone")
				Citizen.SetTimeout(1000, function()
					TriggerEvent("esx:loadingDone")
				end)
				
				local state, err = xpcall(function()
					local start = GetGameTimer()
					while GetGameTimer() - start < 30000 do
						SpawnProtection()
						SetEntityAlpha(PlayerPedId(), 200, 0)
						Citizen.Wait(0)
					end
				end, debug.traceback)

				SetPlayerInvincible(PlayerId(), false)
				ResetEntityAlpha(PlayerPedId())

				if not state then
					print("^1ERROR: ^7" .. err)
				end
			end)
		else
			SetEntityVisible(PlayerPedId(), true)
			SetPlayerInvincible(PlayerId(), false)
		end
		TriggerEvent('esx:firstSpawn')
	end

	isLoadoutLoaded, isDead = true, false

	SetCanAttackFriendly(PlayerPedId(), true, false)
	NetworkSetFriendlyFireOption(true)
	SetFlashLightKeepOnWhileMoving(true)
end)

AddEventHandler('esx:onPlayerDeath', function() isDead = true end)
AddEventHandler('skinchanger:loadDefaultModel', function() isLoadoutLoaded = false end)

AddEventHandler('esx:onPlayerSpawn', function() 
	isDead = false
end)

AddEventHandler('esx:onPlayerDeath', function() 
	isDead = true 
end)

AddEventHandler('skinchanger:modelLoaded', function()
	while not ESX.PlayerLoaded do
		Citizen.Wait(100)
	end

	TriggerEvent('esx:restoreLoadout')

end)

AddEventHandler('esx:restoreLoadout', function()
	local playerPed = PlayerPedId()
	local ammoTypes = {}
	RemoveAllPedWeapons(playerPed, true)

	for k,v in ipairs(ESX.PlayerData.loadout) do
		local weaponName = v.name
		local weaponHash = GetHashKey(weaponName)

		GiveWeaponToPed(playerPed, weaponHash, 0, false, false)
		SetPedWeaponTintIndex(playerPed, weaponHash, v.tintIndex)

		local ammoType = GetPedAmmoTypeFromWeapon(playerPed, weaponHash)

		for k2,v2 in ipairs(v.components) do
			local componentHash = ESX.GetWeaponComponent(weaponName, v2).hash
			GiveWeaponComponentToPed(playerPed, weaponHash, componentHash)
			Wait(5000)
		end

		if not ammoTypes[ammoType] then
			AddAmmoToPed(playerPed, weaponHash, v.ammo)
			ammoTypes[ammoType] = true
		end
	end

end)

RegisterNetEvent('esx:setAccountMoney')
AddEventHandler('esx:setAccountMoney', function(account)
	for k,v in ipairs(ESX.PlayerData.accounts) do
		if v.name == account.name then
			ESX.PlayerData.accounts[k] = account
			break
		end
	end

	if Config.EnableHud then
		ESX.UI.HUD.UpdateElement('account_' .. account.name, {
			money = ESX.Math.GroupDigits(account.money)
		})
	end
end)

RegisterNetEvent('esx:addInventoryItem')
AddEventHandler('esx:addInventoryItem', function(item, count, showNotification)
	if exports['redzone']:isloadingredzone() == true then
		TriggerServerEvent('sts:redzonekickplayer', "Het is niet toegestaan om items in te spawnen tijdens het inladen van de redzone, dit word gezien als bug abuse! Als dit vaker gebeurd, zullen hier consequenties aan vast zitten.")
		return
	end
	if exports['redzone']:isinredzone() == true then
		ESX.ShowNotification("Je kunt geen items inspawnen in een ~r~redzone~s~!")
		return
	end
	for k,v in ipairs(ESX.PlayerData.inventory) do
		if v.name == item then
			ESX.UI.ShowInventoryItemNotification(true, v.label, count - v.count)
			ESX.PlayerData.inventory[k].count = count
			break
		end
	end

	if showNotification then
		ESX.UI.ShowInventoryItemNotification(true, item, count)
	end

	if ESX.UI.Menu.IsOpen('default', 'es_extended', 'inventory') then
		ESX.ShowInventory()
	end

	TriggerEvent('esx:onInventoryUpdated')
end)

RegisterNetEvent('esx:forceaddInventoryItem')
AddEventHandler('esx:forceaddInventoryItem', function(item, count, showNotification)
	for k,v in ipairs(ESX.PlayerData.inventory) do
		if v.name == item then
			ESX.UI.ShowInventoryItemNotification(true, v.label, count - v.count)
			ESX.PlayerData.inventory[k].count = count
			break
		end
	end

	if showNotification then
		ESX.UI.ShowInventoryItemNotification(true, item, count)
	end

	if ESX.UI.Menu.IsOpen('default', 'es_extended', 'inventory') then
		ESX.ShowInventory()
	end

	TriggerEvent('esx:onInventoryUpdated')
end)

RegisterNetEvent('esx:removeInventoryItem')
AddEventHandler('esx:removeInventoryItem', function(item, count, showNotification)
	for k,v in ipairs(ESX.PlayerData.inventory) do
		if v.name == item then
			ESX.UI.ShowInventoryItemNotification(false, v.label, v.count - count)
			ESX.PlayerData.inventory[k].count = count
			break
		end
	end

	if showNotification then
		ESX.UI.ShowInventoryItemNotification(false, item, count)
	end

	if ESX.UI.Menu.IsOpen('default', 'es_extended', 'inventory') then
		ESX.ShowInventory()
	end

	TriggerEvent('esx:onInventoryUpdated')
end)

RegisterNetEvent('esx:removeInventoryItemUser')
AddEventHandler('esx:removeInventoryItemUser', function(item, count, showNotification)
	if exports['redzone']:isinredzone() == true then
		return
	end
	for k,v in ipairs(ESX.PlayerData.inventory) do
		if v.name == item then
			ESX.UI.ShowInventoryItemNotification(false, v.label, v.count - count)
			ESX.PlayerData.inventory[k].count = count
			break
		end
	end

	if showNotification then
		ESX.UI.ShowInventoryItemNotification(false, item, count)
	end

	if ESX.UI.Menu.IsOpen('default', 'es_extended', 'inventory') then
		ESX.ShowInventory()
	end

	TriggerEvent('esx:onInventoryUpdated')
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
end)

RegisterNetEvent('esx:setJob2')
AddEventHandler('esx:setJob2', function(job)
	ESX.PlayerData.job2 = job2
end)

RegisterNetEvent('esx:addWeapon')
AddEventHandler('esx:addWeapon', function(weaponName, ammo)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)
	if exports['redzone']:isloadingredzone() == true then
		TriggerServerEvent('sts:redzonekickplayer', "Het is niet toegestaan om wapens in te spawnen tijdens het inladen van de redzone, dit word gezien als bug abuse! Als dit vaker gebeurd, zullen hier consequenties aan vast zitten.")
		return
	end
	if exports['redzone']:isinredzone() == true then
		ESX.ShowNotification("Je kunt geen wapens inspawnen in een ~r~redzone~s~!")
		return
	end
	GiveWeaponToPed(playerPed, weaponHash, ammo, false, false)
end)

RegisterNetEvent('esx:forceaddWeapon')
AddEventHandler('esx:forceaddWeapon', function(weaponName, ammo)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)

	GiveWeaponToPed(playerPed, weaponHash, ammo, false, false)

end)

RegisterNetEvent('esx:addWeaponComponent')
AddEventHandler('esx:addWeaponComponent', function(weaponName, weaponComponent)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)
	local componentHash = ESX.GetWeaponComponent(weaponName, weaponComponent).hash
	if exports['redzone']:isloadingredzone() == true then
		TriggerServerEvent('sts:redzonekickplayer', "Het is niet toegestaan om wapens in te spawnen tijdens het inladen van de redzone, dit word gezien als bug abuse! Als dit vaker gebeurd, zullen hier consequenties aan vast zitten.")
		return
	end
	if exports['redzone']:isinredzone() == true then
		ESX.ShowNotification("Je kunt geen wapen attachments inspawnen in een ~r~redzone~s~!")
		return
	end


	GiveWeaponComponentToPed(playerPed, weaponHash, componentHash)
end)


RegisterNetEvent('esx:forceaddWeaponComponent')
AddEventHandler('esx:forceaddWeaponComponent', function(weaponName, weaponComponent)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)
	local componentHash = ESX.GetWeaponComponent(weaponName, weaponComponent).hash

	GiveWeaponComponentToPed(playerPed, weaponHash, componentHash)
end)

RegisterNetEvent('esx:setWeaponAmmo')
AddEventHandler('esx:setWeaponAmmo', function(weaponName, weaponAmmo)

	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)

	SetPedAmmo(playerPed, weaponHash, weaponAmmo)

end)

RegisterNetEvent('esx:addWeaponAmmobyAmmotype')
AddEventHandler('esx:addWeaponAmmobyAmmotype', function(ammotype, weaponAmmo)

	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)

	AddAmmoToPedByType(playerPed, ammotype, weaponAmmo)

end)

RegisterNetEvent('esx:setWeaponTint')
AddEventHandler('esx:setWeaponTint', function(weaponName, weaponTintIndex)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)

	SetPedWeaponTintIndex(playerPed, weaponHash, weaponTintIndex)

end)

RegisterNetEvent('esx:removeWeapon')
AddEventHandler('esx:removeWeapon', function(weaponName)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)

	RemoveWeaponFromPed(playerPed, weaponHash)
	SetPedAmmo(playerPed, weaponHash, 0) -- remove leftover ammo

end)

RegisterNetEvent('esx:removeWeaponUser')
AddEventHandler('esx:removeWeaponUser', function(weaponName)
	if exports['redzone']:isinredzone() == true then
		ESX.ShowNotification("Waarom zou je je enige wapen willen verwijderen in een ~r~redzone~s~?")
		return
	end
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)

	RemoveWeaponFromPed(playerPed, weaponHash)
	SetPedAmmo(playerPed, weaponHash, 0) -- remove leftover ammo

end)

RegisterNetEvent('esx:removeWeaponComponent')
AddEventHandler('esx:removeWeaponComponent', function(weaponName, weaponComponent)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)
	local componentHash = ESX.GetWeaponComponent(weaponName, weaponComponent).hash

	RemoveWeaponComponentFromPed(playerPed, weaponHash, componentHash)

	Wait(5000)
end)

RegisterNetEvent('esx:teleport')
AddEventHandler('esx:teleport', function(coords)
	local playerPed = PlayerPedId()

	-- ensure decmial number
	coords.x = coords.x + 0.0
	coords.y = coords.y + 0.0
	coords.z = coords.z + 0.0

	ESX.Game.Teleport(playerPed, coords)
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	if Config.EnableHud then
		ESX.UI.HUD.UpdateElement('job', {
			job_label = job.label,
			grade_label = job.grade_label
		})
	end
end)
---SECONDJOB INCLUDED
RegisterNetEvent('esx:setJob2')
AddEventHandler('esx:setJob2', function(job2)
	if Config.EnableHud then
		ESX.UI.HUD.UpdateElement('job2', {
			job2_label   = job2.label,
			grade2_label = job2.grade_label
		})
	end
end)

local delay = 0
local running = false
local staff = false

local isnearredzone = false
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    local currentPlayerCoords = GetEntityCoords(PlayerPedId())
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local foundCircle = false
    if (GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), -594.82, 225.26, 73.20, true) < 30.0) then
      foundCircle = true
      isnearredzone = true
      Wait(1000)
    end
    if foundCircle == false then
    isnearredzone = false
      Citizen.Wait(500)
    end
  end
end)

RegisterNetEvent('esx:spawnVehicle')
AddEventHandler('esx:spawnVehicle', function(vehicleName)
	if isnearredzone == true then
		return
	end
	if exports['redzone']:isloadingredzone() == true then
		TriggerServerEvent('sts:redzonekickplayer', "Het is niet toegestaan om een voertuig in te spawnen tijdens het inladen van de redzone, dit word gezien als bug abuse! Als dit vaker gebeurd, zullen hier consequenties aan vast zitten.")
		return
	end
	if exports['redzone']:isinredzone() == true then
		ESX.ShowNotification("Je kunt geen voertuigen inspawnen in een ~r~redzone~s~!")
		return
	end
	local model = (type(vehicleName) == 'number' and vehicleName or GetHashKey(vehicleName))
	if exports['sts_discordperms']:hasingamemodgroup() == true or exports['sts_discordperms']:hasingameadmingroup() == true or exports['sts_discordperms']:hasingamesuperadmingroup() == true then
		if IsModelInCdimage(model) then
			if delay == 0 then
				local playerPed = PlayerPedId()
				local playerCoords, playerHeading = GetEntityCoords(playerPed), GetEntityHeading(playerPed)

				ESX.Game.SpawnVehicle(model, playerCoords, playerHeading, function(vehicle)
					TaskWarpPedIntoVehicleWithTransition(playerPed, vehicle, -1)
					local carplate = GetVehicleNumberPlateText(vehicle)
					TriggerEvent('sts_vehiclelock:addplate', carplate, true)
				end)
				delay = 0
				StartCountingDown()
			else
				ESX.ShowNotification("Je moet ~y~"..delay.." seconden~s~ wachten voordat je weer een ~b~voertuig~s~ kan inspawnen")
			end
		else
			TriggerEvent('chat:addMessage', {args = {'^1SYSTEM', 'Invalid vehicle model.'}})
		end
	elseif exports['sts_discordperms']:haspriogroup() == true or exports['sts_discordperms']:hasdelaygroup() == true or exports['sts_discordperms']:hasprioplusgroup() == true then
		if IsModelInCdimage(model) then
			if delay == 0 then
				local playerPed = PlayerPedId()
				local playerCoords, playerHeading = GetEntityCoords(playerPed), GetEntityHeading(playerPed)

				ESX.Game.SpawnVehicle(model, playerCoords, playerHeading, function(vehicle)
					TaskWarpPedIntoVehicleWithTransition(playerPed, vehicle, -1)
					local carplate = GetVehicleNumberPlateText(vehicle)
					TriggerEvent('sts_vehiclelock:addplate', carplate, true)
				end)
				delay = 5
				StartCountingDown()
			else
				ESX.ShowNotification("Je moet ~y~"..delay.." seconden~s~ wachten voordat je weer een ~b~voertuig~s~ kan inspawnen")
			end
		else
			TriggerEvent('chat:addMessage', {args = {'^1SYSTEM', 'Invalid vehicle model.'}})
		end
	elseif staff == false then
		if IsModelInCdimage(model) then
			if delay == 0 then
				local playerPed = PlayerPedId()
				local playerCoords, playerHeading = GetEntityCoords(playerPed), GetEntityHeading(playerPed)

				ESX.Game.SpawnVehicle(model, playerCoords, playerHeading, function(vehicle)
					TaskWarpPedIntoVehicleWithTransition(playerPed, vehicle, -1)
					local carplate = GetVehicleNumberPlateText(vehicle)
					TriggerEvent('sts_vehiclelock:addplate', carplate, true)
				end)
				delay = 15
				StartCountingDown()
			else
				ESX.ShowNotification("Je moet ~y~"..delay.." seconden~s~ wachten voordat je weer een ~b~voertuig~s~ kan inspawnen")
			end
		else
			TriggerEvent('chat:addMessage', {args = {'^1SYSTEM', 'Invalid vehicle model.'}})
		end
	end
end)

function StartCountingDown()
    
    running = true
    Citizen.CreateThread(function()
        Wait(1)
        while delay > 0 do
            delay = delay - 1
            Citizen.Wait(1000)
        end
        running = false
    end)

end

RegisterNetEvent('esx:createPickup')
AddEventHandler('esx:createPickup', function(pickupId, label, coords, type, name, components, tintIndex)
	local function setObjectProperties(object)
		SetEntityAsMissionEntity(object, true, false)
		PlaceObjectOnGroundProperly(object)
		FreezeEntityPosition(object, true)
		SetEntityCollision(object, false, true)

		pickups[pickupId] = {
			obj = object,
			label = label,
			pickupType = type,
			inRange = false,
			coords = vector3(coords.x, coords.y, coords.z)
		}
	end

	if type == 'item_weapon' then
		local weaponHash = GetHashKey(name)
		ESX.Streaming.RequestWeaponAsset(weaponHash)
		local pickupObject = CreateWeaponObject(weaponHash, 50, coords.x, coords.y, coords.z, true, 1.0, 0)
		SetWeaponObjectTintIndex(pickupObject, tintIndex)

		for k,v in ipairs(components) do
			local component = ESX.GetWeaponComponent(name, v)
			GiveWeaponComponentToWeaponObject(pickupObject, component.hash)
			Wait(5000)
		end

		setObjectProperties(pickupObject)
	else
		ESX.Game.SpawnLocalObject('prop_money_bag_01', coords, setObjectProperties)
	end

end)

RegisterNetEvent('esx:createMissingPickups')
AddEventHandler('esx:createMissingPickups', function(missingPickups)
	for pickupId,pickup in pairs(missingPickups) do
		TriggerEvent('esx:createPickup', pickupId, pickup.label, pickup.coords, pickup.type, pickup.name, pickup.components, pickup.tintIndex)
	end

end)

RegisterNetEvent('esx:registerSuggestions')
AddEventHandler('esx:registerSuggestions', function(registeredCommands)
	for name,command in pairs(registeredCommands) do
		if command.suggestion then
			TriggerEvent('chat:addSuggestion', ('/%s'):format(name), command.suggestion.help, command.suggestion.arguments)
		end
	end

end)

RegisterNetEvent('esx:removePickup')
AddEventHandler('esx:removePickup', function(pickupId)
	if pickups[pickupId] and pickups[pickupId].obj then
		ESX.Game.DeleteObject(pickups[pickupId].obj)
		pickups[pickupId] = nil
	end

end)

RegisterNetEvent('esx:deleteVehicle', function(radius, force)
	local playerPed = PlayerPedId()

	if radius and tonumber(radius) then
		radius = tonumber(radius) + 0.01
		local vehicles = ESX.Game.GetVehiclesInArea(GetEntityCoords(playerPed), radius)

		for k,entity in ipairs(vehicles) do
			--[[if force then
				local data = {
					shouldUpdate = true,
					returnToGarage = true,
					calligSource = "esx:deleteVehicle",
					netId = NetworkGetNetworkIdFromEntity(entity),
					delete = true
				}
				TriggerServerEvent('eden_garage:removeFromList', ESX.Math.Trim(GetVehicleNumberPlateText(entity)), data)
				Citizen.Wait(1000)
			end]]
			if DoesEntityExist(entity) and not ESX.Game.TryDeleteEntity(entity) then
				ESX.Game.DeleteVehicle(entity)
				if DoesEntityExist(entity) then
					ESX.Game.TryDeleteAny(entity)
				end
			end
		end
	else
		local vehicle, distance

		if IsPedInAnyVehicle(playerPed, true) then
			vehicle = GetVehiclePedIsIn(playerPed, false)
		else
			vehicle, distance   = ESX.Game.GetClosestVehicle()
			if distance > 25 then
				return
			end
		end

		--[[if force then
			local data = {
				shouldUpdate = true,
				returnToGarage = true,
				calligSource = "esx:deleteVehicle",
				netId = NetworkGetNetworkIdFromEntity(vehicle),
				delete = true
			}
			TriggerServerEvent('eden_garage:removeFromList', ESX.Math.Trim(GetVehicleNumberPlateText(vehicle)), data)
			Citizen.Wait(1000)
		end]]
		if DoesEntityExist(vehicle) and not ESX.Game.TryDeleteEntity(vehicle) then
			ESX.Game.DeleteVehicle(vehicle)
			if DoesEntityExist(vehicle) then
				ESX.Game.TryDeleteAny(vehicle)
			end
		end
	end
end)

RegisterNetEvent('esx:deletePed', function(radius)
	local playerPed = PlayerPedId()
	local ped, distance   = ESX.Game.GetClosestPed(GetEntityCoords(playerPed), { playerPed })

	if IsPedAPlayer(ped) then
		ESX.ShowNotification("Je kunt geen speler peds verwijderen die aanwezig zijn!")
		return
	end
	if not ESX.Game.TryDeleteEntity(ped) then
		ESX.Game.TryDeleteAny(ped, DeletePed)
	end
end)

RegisterNetEvent('esx:deleteObject', function(radius)
	local playerPed = PlayerPedId()
	local object, distance = ESX.Game.GetClosestObject(GetEntityCoords(playerPed))
	if not ESX.Game.TryDeleteEntity(object) then
		ESX.Game.DeleteObject(object)
	end
end)

-- Pause menu disables HUD display
if Config.EnableHud then
	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(300)

			if IsPauseMenuActive() and not isPaused then
				isPaused = true
				ESX.UI.HUD.SetDisplay(0.0)
			elseif not IsPauseMenuActive() and isPaused then
				isPaused = false
				ESX.UI.HUD.SetDisplay(1.0)
			end
		end
	end)

end

function StartServerSyncLoops()
	-- keep track of ammo
	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(0)

			if isDead then
				--Citizen.Wait(500)
				Citizen.Wait(2000)
			else
				local playerPed = PlayerPedId()

				if IsPedShooting(playerPed) then
					local _,weaponHash = GetCurrentPedWeapon(playerPed, true)
					local weapon = ESX.GetWeaponFromHash(weaponHash)

					if weapon then
						local ammoCount = GetAmmoInPedWeapon(playerPed, weaponHash)
						TriggerServerEvent('esx:updateWeaponAmmo', weapon.name, ammoCount)

					end
				end
			end
		end
	end)

	-- sync current player coords with server
	Citizen.CreateThread(function()
		local previousCoords = vector3(ESX.PlayerData.coords.x, ESX.PlayerData.coords.y, ESX.PlayerData.coords.z)

		while true do
			--Citizen.Wait(1000)
			Citizen.Wait(5000)
			local playerPed = PlayerPedId()

			if DoesEntityExist(playerPed) then
				local playerCoords = GetEntityCoords(playerPed)
				local distance = #(playerCoords - previousCoords)

				if distance > 1 then
					previousCoords = playerCoords
					local playerHeading = ESX.Math.Round(GetEntityHeading(playerPed), 1)
					local formattedCoords = {x = ESX.Math.Round(playerCoords.x, 1), y = ESX.Math.Round(playerCoords.y, 1), z = ESX.Math.Round(playerCoords.z, 1), heading = playerHeading}
					TriggerServerEvent('esx:updateCoords', formattedCoords)
				end
			end
		end
	end)
end

RegisterCommand('showinventory', function()
	if not IsControlPressed(0, 21) and IsInputDisabled(0) and not isDead and not ESX.UI.Menu.IsOpen('default', 'es_extended', 'inventory') then
		ESX.ShowInventory()
	end
end, false)

RegisterKeyMapping('showinventory', _U('keymap_showinventory'), 'keyboard', 'F2') 


-- Pickups
Citizen.CreateThread(function()
	local closestDistance = nil
	local function getClosestDistance()
		if not closestDistance then
			closestDistance = ESX.Game.GetClosestPlayer()
		end

		return closestDistance
	end
	while true do
		Citizen.Wait(0)
		local playerPed = PlayerPedId()
		local playerCoords, letSleep = GetEntityCoords(playerPed), true
		local minDistance = 0

		for pickupId,pickup in pairs(pickups) do
			local distance = #(playerCoords - pickup.coords)

			if distance < minDistance then
				minDistance = distance
			end

			if distance < 5 then
				local label = pickup.label
				letSleep = false

				if distance < 1 then
					if IsControlJustReleased(0, 38) then
						if IsPedOnFoot(playerPed) and (getClosestDistance() == -1 or getClosestDistance() > 3) and not pickup.inRange and not ESX.UI.Menu.IsOpen('dialog', GetCurrentResourceName(), 'pickup_count') then
							if pickup.pickupType == 'item_standard' then
								local newTitle = string.gsub(pickup.label, "~y~", "")
								local newTitle2 = string.gsub(newTitle, "~s~", "")
								local newTitle3 = string.gsub(newTitle2, "~b~", "")
								ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'pickup_count', {
									title = 'Aantal: ' .. newTitle3 .. '',
								}, function (data2, menu)
									local aantalPickup = tonumber(data2.value)
									menu.close()
									if aantalPickup == nil then
										ESX.ShowNotification('Ongeldig nummer!')
									else
										pickup.inRange = true
		
										local dict, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
										ESX.Streaming.RequestAnimDict(dict)
										TaskPlayAnim(playerPed, dict, anim, 8.0, 1.0, 1000, 16, 0.0, false, false, false)
										Citizen.Wait(1000)

										TriggerServerEvent('esx:onPickup', pickupId, aantalPickup)
										PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
									end
								end, function (data2, menu)
									menu.close()
								end)
							elseif pickup.pickupType == "item_account" then
								local newTitle = string.gsub(pickup.label, "~y~", "")
								local newTitle2 = string.gsub(newTitle, "~s~", "")
								local newTitle3 = string.gsub(newTitle2, "~b~", "")
								local newTitle4 = string.gsub(newTitle3, "~g~", "")
								ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'pickup_count', {
									title = 'Aantal: ' .. newTitle4 .. '',
								}, function (data2, menu)
									local aantalPickup = tonumber(data2.value)
									menu.close()
									if aantalPickup == nil then
										ESX.ShowNotification('Ongeldig nummer!')
									else
										pickup.inRange = true
		
										local dict, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
										ESX.Streaming.RequestAnimDict(dict)
										TaskPlayAnim(playerPed, dict, anim, 8.0, 1.0, 1000, 16, 0.0, false, false, false)
										Citizen.Wait(1000)

										TriggerServerEvent('esx:onPickup', pickupId, aantalPickup)
										PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
									end
								end, function (data2, menu)
									menu.close()
								end)
							else
								pickup.inRange = true
		
								local dict, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
								ESX.Streaming.RequestAnimDict(dict)
								TaskPlayAnim(playerPed, dict, anim, 8.0, 1.0, 1000, 16, 0.0, false, false, false)
								Citizen.Wait(1000)

								TriggerServerEvent('esx:onPickup', pickupId, 'all')
								PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
							end
						end
					end

					label = ('%s~n~%s'):format(label, _U('threw_pickup_prompt'))
				end

				ESX.Game.Utils.DrawText3D({
					x = pickup.coords.x,
					y = pickup.coords.y,
					z = pickup.coords.z + 0.25
				}, label, 1.2, 1)
			elseif pickup.inRange then
				pickup.inRange = false
			end
		end

		if letSleep then
			Citizen.Wait(minDistance * 12.5)
		end
	end
end)
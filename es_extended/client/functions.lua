ESX                           = {}
ESX.PlayerData                = {}
ESX.PlayerLoaded              = false
ESX.CurrentRequestId          = 0
ESX.ServerCallbacks           = {}
ESX.TimeoutCallbacks          = {}

ESX.UI                        = {}
ESX.UI.HUD                    = {}
ESX.UI.HUD.RegisteredElements = {}
ESX.UI.Menu                   = {}
ESX.UI.Menu.RegisteredTypes   = {}
ESX.UI.Menu.Opened            = {}

ESX.Game                      = {}
ESX.Game.Utils                = {}

ESX.Scaleform                 = {}
ESX.Scaleform.Utils           = {}

ESX.Streaming                 = {}
Internal					  = {}
local collectCards, collectAccounts, collectInventory, collectWallet

ESX.SetTimeout = function(msec, cb)
	table.insert(ESX.TimeoutCallbacks, {
		time = GetGameTimer() + msec,
		cb   = cb
	})
	return #ESX.TimeoutCallbacks
end

ESX.ClearTimeout = function(i)
	ESX.TimeoutCallbacks[i] = nil
end

ESX.IsPlayerLoaded = function()
	return ESX.PlayerLoaded
end

ESX.GetPlayerDataKey = function(key)
	return ESX.PlayerData[key]
end

ESX.GetPlayerData = function()
	return ESX.PlayerData
end

ESX.SetPlayerData = function(key, val)
	ESX.PlayerData[key] = val
end

ESX.ShowNotification = function(msg, flash, saveToBrief, hudColorIndex)
	if saveToBrief == nil then saveToBrief = true end
	AddTextEntry('esxNotification', msg)
	BeginTextCommandThefeedPost('esxNotification')
	if hudColorIndex then ThefeedNextPostBackgroundColor(hudColorIndex) end
	EndTextCommandThefeedPostTicker(flash or false, saveToBrief)
end

ESX.ShowAdvancedNotification = function(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
	if saveToBrief == nil then saveToBrief = true end
	AddTextEntry('esxAdvancedNotification', msg)
	BeginTextCommandThefeedPost('esxAdvancedNotification')
	if hudColorIndex then ThefeedNextPostBackgroundColor(hudColorIndex) end
	EndTextCommandThefeedPostMessagetext(textureDict, textureDict, false, iconType, sender, subject)
	EndTextCommandThefeedPostTicker(flash or false, saveToBrief)
end

ESX.ShowHelpNotification = function(msg, thisFrame, beep, duration)
	AddTextEntry('esxHelpNotification', msg)

	if thisFrame then
		DisplayHelpTextThisFrame('esxHelpNotification', false)
	else
		if beep == nil then beep = true end
		BeginTextCommandDisplayHelp('esxHelpNotification')
		EndTextCommandDisplayHelp(0, false, beep, duration or -1)
	end
end

ESX.ShowFloatingHelpNotification = function(msg, coords)
	AddTextEntry('esxFloatingHelpNotification', msg)
	SetFloatingHelpTextWorldPosition(1, coords)
	SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
	BeginTextCommandDisplayHelp('esxFloatingHelpNotification')
	EndTextCommandDisplayHelp(2, false, false, -1)
end

ESX.GetAccount = function(accountName)
	for i=1, #ESX.PlayerData.accounts do
		if ESX.PlayerData.accounts[i].name == accountName then
			return ESX.PlayerData.accounts[i]
		end
	end

	error(("Account %s doesn't exist!"):format(accountName))
end

ESX.GetAccountLabel = function(accountName)
	local account = ESX.GetAccount(accountName)
	if account then
		return account.label
	end
end

ESX.GetInventoryItem = function(itemName)
	if not ESX.PlayerData.inventory then
		return
	end

	for i=1, #ESX.PlayerData.inventory do
		if ESX.PlayerData.inventory[i].name == itemName then
			return ESX.PlayerData.inventory[i]
		end
	end
end

ESX.GetItemLabel = function(itemName)
	local item = ESX.GetInventoryItem(itemName)
	if item then
		return item.label
	end
end

ESX.GetItemCount = function(itemName)
	local item = ESX.GetInventoryItem(itemName)
	if item then
		return item.count
	end
end

ESX.HasInventoryItem = function(itemName)
	local item = ESX.GetInventoryItem(itemName)
	assert(item, ("Item %s doesn't exist"):format(itemName))

	return item.count > 0
end


ESX.TriggerServerCallback = function(name, cb, ...)
	ESX.ServerCallbacks[ESX.CurrentRequestId] = cb

	TriggerServerEvent('esx:triggerServerCallback', name, ESX.CurrentRequestId, ...)

	if ESX.CurrentRequestId < 65535 then
		ESX.CurrentRequestId = ESX.CurrentRequestId + 1
	else
		ESX.CurrentRequestId = 0
	end
end

ESX.UI.HUD.SetDisplay = function(opacity)
	SendNUIMessage({
		action  = 'setHUDDisplay',
		opacity = opacity
	})
end

ESX.UI.HUD.RegisterElement = function(name, index, priority, html, data)
	local found = false

	for i=1, #ESX.UI.HUD.RegisteredElements, 1 do
		if ESX.UI.HUD.RegisteredElements[i] == name then
			found = true
			break
		end
	end

	if found then
		return
	end

	table.insert(ESX.UI.HUD.RegisteredElements, name)

	SendNUIMessage({
		action    = 'insertHUDElement',
		name      = name,
		index     = index,
		priority  = priority,
		html      = html,
		data      = data
	})

	ESX.UI.HUD.UpdateElement(name, data)
end

ESX.UI.HUD.RemoveElement = function(name)
	for i=1, #ESX.UI.HUD.RegisteredElements, 1 do
		if ESX.UI.HUD.RegisteredElements[i] == name then
			table.remove(ESX.UI.HUD.RegisteredElements, i)
			break
		end
	end

	SendNUIMessage({
		action    = 'deleteHUDElement',
		name      = name
	})
end

ESX.UI.HUD.UpdateElement = function(name, data)
	SendNUIMessage({
		action = 'updateHUDElement',
		name   = name,
		data   = data
	})
end

ESX.UI.Menu.RegisterType = function(type, open, close)
	ESX.UI.Menu.RegisteredTypes[type] = {
		open   = open,
		close  = close
	}
end

ESX.UI.Menu.Open = function(type, namespace, name, data, submit, cancel, change, close)
	local menu = {}

	menu.type      = type
	menu.namespace = namespace
	menu.name      = name
	menu.data      = data
	menu.submit    = submit
	menu.cancel    = cancel
	menu.change    = change

	menu.close = function()

		ESX.UI.Menu.RegisteredTypes[type].close(namespace, name)

		for i=1, #ESX.UI.Menu.Opened, 1 do
			if ESX.UI.Menu.Opened[i] then
				if ESX.UI.Menu.Opened[i].type == type and ESX.UI.Menu.Opened[i].namespace == namespace and ESX.UI.Menu.Opened[i].name == name then
					ESX.UI.Menu.Opened[i] = nil
				end
			end
		end

		if close then
			close()
		end

	end

	menu.update = function(query, newData)

		for i=1, #menu.data.elements, 1 do
			local match = true

			for k,v in pairs(query) do
				if menu.data.elements[i][k] ~= v then
					match = false
				end
			end

			if match then
				for k,v in pairs(newData) do
					menu.data.elements[i][k] = v
				end
			end
		end

	end

	menu.refresh = function()
		ESX.UI.Menu.RegisteredTypes[type].open(namespace, name, menu.data)
	end

	menu.setElement = function(i, key, val)
		menu.data.elements[i][key] = val
	end

	menu.setElements = function(newElements)
		menu.data.elements = newElements
	end

	menu.setTitle = function(val)
		menu.data.title = val
	end

	menu.removeElement = function(query)
		for i=1, #menu.data.elements, 1 do
			for k,v in pairs(query) do
				if menu.data.elements[i] then
					if menu.data.elements[i][k] == v then
						table.remove(menu.data.elements, i)
						break
					end
				end

			end
		end
	end

	table.insert(ESX.UI.Menu.Opened, menu)
	ESX.UI.Menu.RegisteredTypes[type].open(namespace, name, data)

	return menu
end

ESX.UI.Menu.Close = function(type, namespace, name)
	for i=1, #ESX.UI.Menu.Opened, 1 do
		if ESX.UI.Menu.Opened[i] then
			if ESX.UI.Menu.Opened[i].type == type and ESX.UI.Menu.Opened[i].namespace == namespace and ESX.UI.Menu.Opened[i].name == name then
				ESX.UI.Menu.Opened[i].close()
				ESX.UI.Menu.Opened[i] = nil
			end
		end
	end
end

ESX.UI.Menu.CloseAll = function()
	for i=1, #ESX.UI.Menu.Opened, 1 do
		if ESX.UI.Menu.Opened[i] then
			ESX.UI.Menu.Opened[i].close()
			ESX.UI.Menu.Opened[i] = nil
		end
	end
end

ESX.UI.Menu.GetOpened = function(type, namespace, name)
	for i=1, #ESX.UI.Menu.Opened, 1 do
		if ESX.UI.Menu.Opened[i] then
			if ESX.UI.Menu.Opened[i].type == type and ESX.UI.Menu.Opened[i].namespace == namespace and ESX.UI.Menu.Opened[i].name == name then
				return ESX.UI.Menu.Opened[i]
			end
		end
	end
end

ESX.UI.Menu.GetOpenedMenus = function()
	return ESX.UI.Menu.Opened
end

ESX.UI.Menu.IsOpen = function(type, namespace, name)
	return ESX.UI.Menu.GetOpened(type, namespace, name) ~= nil
end

ESX.UI.ShowInventoryItemNotification = function(add, item, count)
	SendNUIMessage({
		action = 'inventoryNotification',
		add    = add,
		item   = item,
		count  = count
	})
end

ESX.Game.GetPedMugshot = function(ped, transparent)
	if DoesEntityExist(ped) then
		local mugshot

		if transparent then
			mugshot = RegisterPedheadshotTransparent(ped)
		else
			mugshot = RegisterPedheadshot(ped)
		end

		while not IsPedheadshotReady(mugshot) do
			Citizen.Wait(0)
		end

		return mugshot, GetPedheadshotTxdString(mugshot)
	else
		return
	end
end

ESX.Game.TeleportFocus = function(entity, coords, cb)
	if type(coords) ~= 'vector3' then
		coords = vector3(coords.x, coords.y, coords.z)
	end

	SetFocusPosAndVel(coords.x, coords.y, coords.z)
	FreezeEntityPosition(entity, true)

	Citizen.Wait(1000)
	SetEntityCoords(entity, coords.x, coords.y, coords.z)
	local timeout = 0.0
	while not HasCollisionLoadedAroundEntity(entity) and DoesEntityExist(entity) and timeout < 5.0 do
		RequestCollisionAtCoord(coords.x, coords.y, coords.z)
		timeout = timeout + GetFrameTime()
		Citizen.Wait(0)
	end
	FreezeEntityPosition(entity, false)

	ClearFocus()
	if cb then
		cb()
	end
end

ESX.Game.Teleport = function(entity, coords, cb)
	if DoesEntityExist(entity) then
		RequestCollisionAtCoord(coords.x, coords.y, coords.z)
		local timeout = 0

		-- we can get stuck here if any of the axies are "invalid"
		while not HasCollisionLoadedAroundEntity(entity) and timeout < 2000 do
			Citizen.Wait(0)
			timeout = timeout + 1
		end

		SetEntityCoords(entity, coords.x, coords.y, coords.z, false, false, false, false)

		if type(coords) == 'table' and coords.heading then
			SetEntityHeading(entity, coords.heading)
		end
	end

	if cb then
		cb()
	end
end

ESX.Game.SpawnObject = function(model, coords, cb)
	local model = (type(model) == 'number' and model or GetHashKey(model))

	Citizen.CreateThread(function()
		ESX.Streaming.RequestModel(model)
		local obj = CreateObject(model, coords.x, coords.y, coords.z, true, false, true)
		SetModelAsNoLongerNeeded(model)

		if cb then
			cb(obj)
		end
	end)
end

ESX.Game.SpawnLocalObject = function(model, coords, cb)
	local model = (type(model) == 'number' and model or GetHashKey(model))

	Citizen.CreateThread(function()
		ESX.Streaming.RequestModel(model)
		local obj = CreateObject(model, coords.x, coords.y, coords.z, false, false, true)
		SetModelAsNoLongerNeeded(model)

		if cb then
			cb(obj)
		end
	end)
end

ESX.Game.MakeSureExists = function(handle, netId, timeout)
	timeout = timeout or 1000
	local time = 0
	while not NetworkDoesNetworkIdExist(netId) and time < timeout do
		Citizen.Wait(100)
		time = time + 100
	end
	if DoesEntityExist(handle) then
		return handle
	else
		return NetworkGetEntityFromNetworkId(netId)
	end
end

ESX.Game.GetEntity = function(netId, handle)
	if handle and DoesEntityExist(handle) then
		return handle
	elseif netId and NetworkDoesNetworkIdExist(netId) then
		return NetworkGetEntityFromNetworkId(netId)
	end
end

ESX.Game.DeleteVehicle = function(vehicle)
	SetEntityAsMissionEntity(vehicle, false, true)
	DeleteVehicle(vehicle)
end

ESX.Game.DeletePed = function(ped)
	SetEntityAsMissionEntity(ped, false, true)
	DecorSetBool(ped, "_DELETED", true)
	DeletePed(ped)
end

ESX.Game.DeleteObject = function(object)
	SetEntityAsMissionEntity(object, false, true)
	DecorSetBool(object, "_DELETED", true)
    DeleteObject(object)
end

ESX.Game.SpawnVehicle = function(modelName, coords, heading, cb)
	local model = (type(modelName) == 'number' and modelName or GetHashKey(modelName))

	Citizen.CreateThread(function()
		ESX.Streaming.RequestModel(model)

		local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, false)
		local networkId = NetworkGetNetworkIdFromEntity(vehicle)
		local timeout = 0

		SetNetworkIdCanMigrate(networkId, true)
		SetEntityAsMissionEntity(vehicle, true, false)
		SetVehicleHasBeenOwnedByPlayer(vehicle, true)
		SetVehicleNeedsToBeHotwired(vehicle, false)
		SetVehRadioStation(vehicle, 'OFF')
		SetModelAsNoLongerNeeded(model)
		RequestCollisionAtCoord(coords.x, coords.y, coords.z)

		SetVehicleNumberPlateText(vehicle, "STS")

		-- we can get stuck here if any of the axies are "invalid"
		while not HasCollisionLoadedAroundEntity(vehicle) and timeout < 2000 do
			Citizen.Wait(0)
			timeout = timeout + 1
		end

		if cb then
			cb(vehicle)
		end
	end)
end

ESX.Game.SpawnLocalVehicle = function(modelName, coords, heading, cb)
	local model = (type(modelName) == 'number' and modelName or GetHashKey(modelName))

	Citizen.CreateThread(function()
		ESX.Streaming.RequestModel(model)

		local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, false, false)
		local timeout = 0

		SetEntityAsMissionEntity(vehicle, true, false)
		SetVehicleHasBeenOwnedByPlayer(vehicle, true)
		SetVehicleNeedsToBeHotwired(vehicle, false)
		SetVehRadioStation(vehicle, 'OFF')
		SetModelAsNoLongerNeeded(model)
		RequestCollisionAtCoord(coords.x, coords.y, coords.z)

		-- we can get stuck here if any of the axies are "invalid"
		while not HasCollisionLoadedAroundEntity(vehicle) and timeout < 2000 do
			Citizen.Wait(0)
			timeout = timeout + 1
		end

		if cb then
			cb(vehicle)
		end
	end)
end

ESX.Game.IsVehicleEmpty = function(vehicle)
	local passengers = GetVehicleNumberOfPassengers(vehicle)
	local driverSeatFree = IsVehicleSeatFree(vehicle, -1)

	return passengers == 0 and driverSeatFree
end

ESX.Game.GetObjects = function()
	return GetGamePool("CObject")
end

ESX.Game.GetObjectsInArea = function(coords, radius, filter)
	local foundObjects = {}
	filter = filter or false
	radius = radius or 10.0

	if not coords or type(coords) ~= "vector3" then
		coords = GetEntityCoords(PlayerPedId())
	end

	if type(filter) == "string" then
		filter = {}
		filter[GetHashKey(filter)] = true
	elseif type(filter) == "number" then
		filter = {}
		filter[filter] = true
	elseif type(filter) == "table" then
		for k,v in pairs(filter) do
			filter[v] = true
		end
	end

	local objects = ESX.Game.GetObjects()
	for k,v in pairs(objects) do
		if filter and filter[GetEntityModel(v)] then
			local objCoords = GetEntityCoords(v)
			local distance = #(objCoords - coords)
			if distance < radius then
				foundObjects[#foundObjects + 1] = {handle = v, coords = objCoords, distance = distance}
			end
		end
	end
	return foundObjects
end

ESX.Game.GetClosestObject = function(filter, coords)
	-- Check if filter is a coords, if so, switch them around
	if filter and filter.x then
		local _coords = filter
		filter = coords
		coords = _coords
	end
	local closestDistance, closestObject = -1, -1
	local filter, coords = filter, coords

	if type(filter) == 'string' then
		if filter ~= '' then
			filter = {filter}
		end
	end

	if coords then
		coords = vector3(coords.x, coords.y, coords.z)
	else
		local playerPed = PlayerPedId()
		coords = GetEntityCoords(playerPed)
	end

	local _filter = nil
	if filter then
		_filter = {}
		for k,v in pairs(filter) do
			if type(v) == 'string' then
				_filter[GetHashKey(v)] = true
			elseif type(v) == 'number' then
				_filter[v] = true
			else
				_filter[k] = true
			end
		end
	end

	local objects = GetGamePool("CObject")

	for i=1, #objects do
		if _filter == nil or _filter[GetEntityModel(objects[i])] then
			local objectCoords = GetEntityCoords(objects[i])
			local distance = #(objectCoords - coords)

			if closestDistance == -1 or closestDistance > distance then
				closestObject = objects[i]
				closestDistance = distance
			end
		end
	end

	return closestObject, closestDistance
end

ESX.Game.GetPeds = function(onlyOtherPeds)
	local peds, myPed = {}, PlayerPedId()

	for ped in EnumeratePeds() do
		if ((onlyOtherPeds and ped ~= myPed) or not onlyOtherPeds) then
			table.insert(peds, ped)
		end
	end

	return peds
end

--[[ESX.Game.GetVehicles = function()
	local vehicles = {}

	for vehicle in EnumerateVehicles() do
		table.insert(vehicles, vehicle)
	end

	return vehicles
end]]

ESX.Game.GetPlayers = function(onlyOtherPlayers, returnKeyValue, returnPeds)
	local players, myPlayer = {}, PlayerId()

	for k,player in ipairs(GetActivePlayers()) do
		local ped = GetPlayerPed(player)

		if DoesEntityExist(ped) and ((onlyOtherPlayers and player ~= myPlayer) or not onlyOtherPlayers) then
			if returnKeyValue then
				players[player] = ped
			else
				table.insert(players, returnPeds and ped or player)
			end
		end
	end

	return players
end

ESX.Game.GetClosestPed = function(coords, ignoreList)
	local ignoreList      = ignoreList or {}
	local closestDistance = -1
	local closestPed      = -1
	coords = vector3(coords.x, coords.y, coords.z)

	for i=1, #ignoreList do
		ignoreList[ignoreList[i]] = true
		ignoreList[i] = nil
	end

	local peds = GetGamePool("CPed")
	for i=1, #peds do
		if not ignoreList[peds[i]] then
			local pedCoords = GetEntityCoords(peds[i])
			local distance = #(pedCoords - coords)

			if closestDistance == -1 or closestDistance > distance then
				closestPed      = peds[i]
				closestDistance = distance
			end
		end
	end

	return closestPed, closestDistance
end

ESX.Game.GetClosestPlayer = function(coords, hideInvisible)
	local players, closestDistance, closestPlayer = GetActivePlayers(), -1, -1
	local coords, usePlayerPed = coords, false
	local playerPed, playerId = PlayerPedId(), PlayerId()

	if coords then
		coords = vector3(coords.x, coords.y, coords.z)
	else
		usePlayerPed = true
		coords = GetEntityCoords(playerPed)
	end

	if hideInvisible == nil then
		hideInvisible = true
	end

	local function skipPlayer(player, ped)
		if not DoesEntityExist(ped) then
			return true
		end
		if usePlayerPed and player == playerId then
			return true
		end
		if hideInvisible and not IsEntityVisible(ped) then
			return true
		end

		return false
	end

	for i=1, #players do
		local target = GetPlayerPed(players[i])

		if not skipPlayer(players[i], target) then
			local targetCoords = GetEntityCoords(target)
			local distance = #(coords - targetCoords)

			if closestDistance == -1 or closestDistance > distance then
				closestPlayer = players[i]
				closestDistance = distance
			end
		end
	end

	return closestPlayer, closestDistance
end

ESX.Game.GetVisiblePlayersInArea = function(coords, area)
	local players, playersInArea = GetActivePlayers(), {}
	if type(coords) ~= 'vector3' then
		coords = vector3(coords.x, coords.y, coords.z)
	end

	for i=1, #players, 1 do
		local target = GetPlayerPed(players[i])
		if DoesEntityExist(target) and IsEntityVisible(target) then
			local targetCoords = GetEntityCoords(target)

			if #(coords - targetCoords) <= area then
				table.insert(playersInArea, players[i])
			end
		end
	end

	return playersInArea
end

ESX.Game.GetPlayersInArea = function(coords, area)
	local players, playersInArea = GetActivePlayers(), {}
	if type(coords) ~= 'vector3' then
		coords = vector3(coords.x, coords.y, coords.z)
	end

	for i=1, #players, 1 do
		local target = GetPlayerPed(players[i])
		if DoesEntityExist(target) then
			local targetCoords = GetEntityCoords(target)

			if #(coords - targetCoords) <= area then
				table.insert(playersInArea, players[i])
			end
		end
	end

	return playersInArea
end

ESX.Game.GetVehiclesInArea = function(coords, area)
	local vehiclesInArea = {}
	local coords = coords

	if coords then
		coords = vector3(coords.x, coords.y, coords.z)
	else
		coords = GetEntityCoords(PlayerPedId())
	end

	if not IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, area) then
		return vehiclesInArea
	end

	local vehicles = ESX.Game.GetVehicles()

	for i=1, #vehicles do
		local vehicleCoords = GetEntityCoords(vehicles[i])
		local distance = #(vehicleCoords - coords)

		if distance <= area then
			table.insert(vehiclesInArea, vehicles[i])
		end
	end

	return vehiclesInArea
end

ESX.Game.IsSpawnPointClear = function(coords, radius, ignorePeds)
	radius = radius or 5.0
	if type(coords) ~= "vector3" then
		coords = vector3(coords.x, coords.y, coords.z)
	end

	if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, radius) then
		return false
	end

	if not ignorePeds and IsAnyPedNearPoint(coords.x, coords.y, coords.z, radius) then
		local pedCoords = GetEntityCoords(PlayerPedId())
		if #(pedCoords - coords) < radius then
			return true
		else
			return false
		end
	end
	return true
end

ESX.Game.GetVehicles = function()
	return GetGamePool("CVehicle")
end

local function shouldFilter(vehicle, modelFilter)
	if not modelFilter then
		return false
	end

	local model = GetEntityModel(vehicle)
	if modelFilter[model] then
		return true
	else
		return false
	end
end

ESX.Game.GetClosestVehicle = function(coords, modelFilter)
	local closestDistance, closestVehicle, coords = -1, -1, coords

	if coords then
		coords = vector3(coords.x, coords.y, coords.z)
	else
		local playerPed = PlayerPedId()
		coords = GetEntityCoords(playerPed)
	end

	local vehicles = ESX.Game.GetVehicles()

	for i=1, #vehicles do
		if not shouldFilter(vehicles[i], modelFilter) then
			local vehicleCoords = GetEntityCoords(vehicles[i])
			local distance = #(coords - vehicleCoords)

			if closestDistance == -1 or closestDistance > distance then
				closestVehicle, closestDistance = vehicles[i], distance
			end
		end
	end

	return closestVehicle, closestDistance
end

ESX.Game.GetClosestEntity = function(entities, isPlayerEntities, coords, modelFilter)
	local closestEntity, closestEntityDistance, filteredEntities = -1, -1, nil

	if coords then
		coords = vector3(coords.x, coords.y, coords.z)
	else
		local playerPed = PlayerPedId()
		coords = GetEntityCoords(playerPed)
	end

	if modelFilter then
		filteredEntities = {}

		for k,entity in pairs(entities) do
			if modelFilter[GetEntityModel(entity)] then
				table.insert(filteredEntities, entity)
			end
		end
	end

	for k,entity in pairs(filteredEntities or entities) do
		local distance = #(coords - GetEntityCoords(entity))

		if closestEntityDistance == -1 or distance < closestEntityDistance then
			closestEntity, closestEntityDistance = isPlayerEntities and k or entity, distance
		end
	end

	return closestEntity, closestEntityDistance
end

ESX.Game.GetVehicleInDirection = function()
	local playerPed    = PlayerPedId()
	local playerCoords = GetEntityCoords(playerPed)
	local inDirection  = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 5.0, 0.0)
	local rayHandle    = StartShapeTestRay(playerCoords, inDirection, 10, playerPed, 0)
	local numRayHandle, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)

	if hit == 1 and GetEntityType(entityHit) == 2 then
		return entityHit
	end

	return nil
end

ESX.Game.GetVehicleProperties = function(vehicle)
	if DoesEntityExist(vehicle) then
		local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
		local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
		local extras = {}

		for extraId=0, 12 do
			if DoesExtraExist(vehicle, extraId) then
				local state = IsVehicleExtraTurnedOn(vehicle, extraId) == 1
				extras[tostring(extraId)] = state
			end
		end

		return {
			model             = GetEntityModel(vehicle),

			plate             = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle)),
			plateIndex        = GetVehicleNumberPlateTextIndex(vehicle),

			bodyHealth        = ESX.Math.Round(GetVehicleBodyHealth(vehicle), 1),
			engineHealth      = ESX.Math.Round(GetVehicleEngineHealth(vehicle), 1),

			fuelLevel         = ESX.Math.Round(GetVehicleFuelLevel(vehicle), 1),
			dirtLevel         = ESX.Math.Round(GetVehicleDirtLevel(vehicle), 1),
			color1            = colorPrimary,
			color2            = colorSecondary,

			pearlescentColor  = pearlescentColor,
			wheelColor        = wheelColor,

			wheels            = GetVehicleWheelType(vehicle),
			windowTint        = GetVehicleWindowTint(vehicle),
			xenonColor        = GetVehicleXenonLightsColour(vehicle),

			neonEnabled       = {
				IsVehicleNeonLightEnabled(vehicle, 0),
				IsVehicleNeonLightEnabled(vehicle, 1),
				IsVehicleNeonLightEnabled(vehicle, 2),
				IsVehicleNeonLightEnabled(vehicle, 3)
			},

			neonColor         = table.pack(GetVehicleNeonLightsColour(vehicle)),
			extras            = extras,
			tyreSmokeColor    = table.pack(GetVehicleTyreSmokeColor(vehicle)),

			modSpoilers       = GetVehicleMod(vehicle, 0),
			modFrontBumper    = GetVehicleMod(vehicle, 1),
			modRearBumper     = GetVehicleMod(vehicle, 2),
			modSideSkirt      = GetVehicleMod(vehicle, 3),
			modExhaust        = GetVehicleMod(vehicle, 4),
			modFrame          = GetVehicleMod(vehicle, 5),
			modGrille         = GetVehicleMod(vehicle, 6),
			modHood           = GetVehicleMod(vehicle, 7),
			modFender         = GetVehicleMod(vehicle, 8),
			modRightFender    = GetVehicleMod(vehicle, 9),
			modRoof           = GetVehicleMod(vehicle, 10),

			modEngine         = GetVehicleMod(vehicle, 11),
			modBrakes         = GetVehicleMod(vehicle, 12),
			modTransmission   = GetVehicleMod(vehicle, 13),
			modHorns          = GetVehicleMod(vehicle, 14),
			modSuspension     = GetVehicleMod(vehicle, 15),
			modArmor          = GetVehicleMod(vehicle, 16),

			modTurbo          = IsToggleModOn(vehicle, 18),
			modSmokeEnabled   = IsToggleModOn(vehicle, 20),
			modXenon          = IsToggleModOn(vehicle, 22),

			modFrontWheels    = GetVehicleMod(vehicle, 23),
			modBackWheels     = GetVehicleMod(vehicle, 24),

			modPlateHolder    = GetVehicleMod(vehicle, 25),
			modVanityPlate    = GetVehicleMod(vehicle, 26),
			modTrimA          = GetVehicleMod(vehicle, 27),
			modOrnaments      = GetVehicleMod(vehicle, 28),
			modDashboard      = GetVehicleMod(vehicle, 29),
			modDial           = GetVehicleMod(vehicle, 30),
			modDoorSpeaker    = GetVehicleMod(vehicle, 31),
			modSeats          = GetVehicleMod(vehicle, 32),
			modSteeringWheel  = GetVehicleMod(vehicle, 33),
			modShifterLeavers = GetVehicleMod(vehicle, 34),
			modAPlate         = GetVehicleMod(vehicle, 35),
			modSpeakers       = GetVehicleMod(vehicle, 36),
			modTrunk          = GetVehicleMod(vehicle, 37),
			modHydrolic       = GetVehicleMod(vehicle, 38),
			modEngineBlock    = GetVehicleMod(vehicle, 39),
			modAirFilter      = GetVehicleMod(vehicle, 40),
			modStruts         = GetVehicleMod(vehicle, 41),
			modArchCover      = GetVehicleMod(vehicle, 42),
			modAerials        = GetVehicleMod(vehicle, 43),
			modTrimB          = GetVehicleMod(vehicle, 44),
			modTank           = GetVehicleMod(vehicle, 45),
			modWindows        = GetVehicleMod(vehicle, 46),
			modLivery         = GetVehicleLivery(vehicle)
		}
	else
		return
	end
end

ESX.Game.SetVehiclePropertiesFull = function(vehicle, props)
	if not DoesEntityExist(vehicle) then
		Traceback("Vehicle doesn't exist on SetVehiclePropertiesFull")
		return
	end

	local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
	local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)

	SetVehicleModKit(vehicle, 0)
	
	if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0) end

	if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0) end

	if props.fuelLevel then
		SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0)
		TriggerEvent('LegacyFuel:UpdateFuel', vehicle, props.fuelLevel + 0.0)
	end

	if props.modSuspension then SetVehicleMod(vehicle, 15, props.modSuspension, false) end
	if props.modArmor then SetVehicleMod(vehicle, 16, props.modArmor, false) end
	if props.modTurbo ~= nil then ToggleVehicleMod(vehicle,  18, props.modTurbo) end
	if props.modEngine then SetVehicleMod(vehicle, 11, props.modEngine, false) end
	if props.modBrakes then SetVehicleMod(vehicle, 12, props.modBrakes, false) end
	if props.modTransmission then SetVehicleMod(vehicle, 13, props.modTransmission, false) end

	if props.dirtLevel then SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0) end

	if props.plate then
		-- plateIndex -1 zorgt voor de ALAN 0 glitch op voertuigen (ALAN 0 is de default license plate als er geen gevonden is)
		-- Omdat -1 niet bestaat worden updates visueel niet doorgevoerd omdat de plate niet bestaat, hierom default ik dit dus naar 0
		if props.plateIndex == -1 then
			props.plateIndex = 0
		end
		SetVehicleNumberPlateText(vehicle, props.plate)
	end

	SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex or -1)

	if props.color1 or props.color2 then
		if props.color1 then colorPrimary = props.color1 end
		if props.color2 then colorSecondary = props.color2 end
		SetVehicleColours(vehicle, colorPrimary, colorSecondary)
	end

	if props.pearlescentColor or props.wheelColor then
		if props.pearlescentColor then pearlescentColor = props.pearlescentColor end
		if props.wheelColor then wheelColor = props.wheelColor end
		SetVehicleExtraColours(vehicle, pearlescentColor, wheelColor)
	end

	if props.dashboardColor then
		SetVehicleDashboardColor(vehicle, props.dashboardColor)
	end

	if props.interiorColor then
		SetVehicleInteriorColor(vehicle, props.interiorColor)
	end

	if props.wheels then SetVehicleWheelType(vehicle, props.wheels) end

	if props.windowTint then SetVehicleWindowTint(vehicle, props.windowTint) end

	if props.neonEnabled then
		SetVehicleNeonLightEnabled(vehicle, 0, props.neonEnabled[1])
		SetVehicleNeonLightEnabled(vehicle, 1, props.neonEnabled[2])
		SetVehicleNeonLightEnabled(vehicle, 2, props.neonEnabled[3])
		SetVehicleNeonLightEnabled(vehicle, 3, props.neonEnabled[4])
	end

	if props.extras then
		for id,enabled in pairs(props.extras) do
			if enabled then
				SetVehicleExtra(vehicle, tonumber(id), 0)
			else
				SetVehicleExtra(vehicle, tonumber(id), 1)
			end
		end
	end

	if props.burstWheels then
		for k,v in pairs(props.burstWheels) do
			if v then
				SetVehicleTyreBurst(vehicle, tonumber(k), true, 1000)
			end
		end
	end

	if props.neonColor then SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3]) end
	if props.modSmokeEnabled ~= nil then ToggleVehicleMod(vehicle, 20, true) end
	if props.tyreSmokeColor then SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3]) end

	SetVehicleMod(vehicle, 0, props.modSpoilers or -1, false)
	SetVehicleMod(vehicle, 1, props.modFrontBumper or -1, false)
	SetVehicleMod(vehicle, 2, props.modRearBumper or -1, false)
	SetVehicleMod(vehicle, 3, props.modSideSkirt or -1, false)
	SetVehicleMod(vehicle, 4, props.modExhaust or -1, false)
	SetVehicleMod(vehicle, 5, props.modFrame or -1, false)
	SetVehicleMod(vehicle, 6, props.modGrille or -1, false)
	SetVehicleMod(vehicle, 7, props.modHood or -1, false)
	SetVehicleMod(vehicle, 8, props.modFender or -1, false)
	SetVehicleMod(vehicle, 9, props.modRightFender or -1, false)
	SetVehicleMod(vehicle, 10, props.modRoof or -1, false)
	-- Start performance upgrades
	SetVehicleMod(vehicle, 11, props.modEngine or -1, false)
	SetVehicleMod(vehicle, 12, props.modBrakes or -1, false)
	SetVehicleMod(vehicle, 13, props.modTransmission or -1, false)
	SetVehicleMod(vehicle, 14, props.modHorns or -1, false)
	SetVehicleMod(vehicle, 15, props.modSuspension, false)
	SetVehicleMod(vehicle, 16, props.modArmor or -1, false)
	if props.modTurbo ~= nil then ToggleVehicleMod(vehicle,  18, props.modTurbo) end
	-- End performance upgrades
	if props.modXenon ~= nil then ToggleVehicleMod(vehicle,  22, props.modXenon) end
	SetVehicleMod(vehicle, 23, props.modFrontWheels or -1, false)
	SetVehicleMod(vehicle, 24, props.modBackWheels or -1, false)
	SetVehicleMod(vehicle, 25, props.modPlateHolder or -1, false)
	SetVehicleMod(vehicle, 26, props.modVanityPlate or -1, false)
	SetVehicleMod(vehicle, 27, props.modTrimA or -1, false)
	SetVehicleMod(vehicle, 28, props.modOrnaments or -1, false)
	SetVehicleMod(vehicle, 29, props.modDashboard or -1, false)
	SetVehicleMod(vehicle, 30, props.modDial or -1, false)
	SetVehicleMod(vehicle, 31, props.modDoorSpeaker or -1, false)
	SetVehicleMod(vehicle, 32, props.modSeats or -1, false)
	SetVehicleMod(vehicle, 33, props.modSteeringWheel or -1, false)
	SetVehicleMod(vehicle, 34, props.modShifterLeavers or -1, false)
	SetVehicleMod(vehicle, 35, props.modAPlate or -1, false)
	SetVehicleMod(vehicle, 36, props.modSpeakers or -1, false)
	SetVehicleMod(vehicle, 37, props.modTrunk or -1, false)
	SetVehicleMod(vehicle, 38, props.modHydrolic or -1, false)
	SetVehicleMod(vehicle, 39, props.modEngineBlock or -1, false)
	SetVehicleMod(vehicle, 40, props.modAirFilter or -1, false)
	SetVehicleMod(vehicle, 41, props.modStruts or -1, false)
	SetVehicleMod(vehicle, 42, props.modArchCover or -1, false)
	SetVehicleMod(vehicle, 43, props.modAerials or -1, false)
	SetVehicleMod(vehicle, 44, props.modTrimB or -1, false)
	SetVehicleMod(vehicle, 45, props.modTank or -1, false)
	SetVehicleMod(vehicle, 46, props.modWindows or -1, false)

	if props.modLivery then
		SetVehicleLivery(vehicle, props.modLivery)
		if props.modLivery == -1 and GetVehicleLivery(vehicle) ~= -1 then
			SetVehicleLivery(vehicle, 0)
		end
	end
	if props.modLivery2 then SetVehicleMod(vehicle, 48, props.modLivery2, false) end
end

ESX.Game.Utils.DrawText3D = function(coords, text, size, font)
	coords = vector3(coords.x, coords.y, coords.z)

	local camCoords = GetGameplayCamCoords()
	local distance = #(coords - camCoords)

	if not size then size = 1 end
	if not font then font = 0 end

	local scale = (size / distance) * 2
	local fov = (1 / GetGameplayCamFov()) * 100
	scale = scale * fov

	SetTextScale(0.0 * scale, 0.55 * scale)
	SetTextFont(font)
	SetTextColour(255, 255, 255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextCentre(true)

	SetDrawOrigin(coords, 0)
	BeginTextCommandDisplayText('STRING')
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(0.0, 0.0)
	ClearDrawOrigin()
end

ESX.Game.SetVehicleProperties = function(vehicle, props)
	if DoesEntityExist(vehicle) then
		local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
		local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
		SetVehicleModKit(vehicle, 0)

		if props.plate then SetVehicleNumberPlateText(vehicle, props.plate) end
		if props.plateIndex then SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex) end
		if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0) end
		if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0) end
		if props.fuelLevel then SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0) end
		if props.dirtLevel then SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0) end
		if props.color1 then SetVehicleColours(vehicle, props.color1, colorSecondary) end
		if props.color2 then SetVehicleColours(vehicle, props.color1 or colorPrimary, props.color2) end
		if props.pearlescentColor then SetVehicleExtraColours(vehicle, props.pearlescentColor, wheelColor) end
		if props.wheelColor then SetVehicleExtraColours(vehicle, props.pearlescentColor or pearlescentColor, props.wheelColor) end
		if props.wheels then SetVehicleWheelType(vehicle, props.wheels) end
		if props.windowTint then SetVehicleWindowTint(vehicle, props.windowTint) end

		if props.neonEnabled then
			SetVehicleNeonLightEnabled(vehicle, 0, props.neonEnabled[1])
			SetVehicleNeonLightEnabled(vehicle, 1, props.neonEnabled[2])
			SetVehicleNeonLightEnabled(vehicle, 2, props.neonEnabled[3])
			SetVehicleNeonLightEnabled(vehicle, 3, props.neonEnabled[4])
		end

		if props.extras then
			for extraId,enabled in pairs(props.extras) do
				if enabled then
					SetVehicleExtra(vehicle, tonumber(extraId), 0)
				else
					SetVehicleExtra(vehicle, tonumber(extraId), 1)
				end
			end
		end

		if props.neonColor then SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3]) end
		if props.xenonColor then SetVehicleXenonLightsColour(vehicle, props.xenonColor) end
		if props.modSmokeEnabled then ToggleVehicleMod(vehicle, 20, true) end
		if props.tyreSmokeColor then SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3]) end
		if props.modSpoilers then SetVehicleMod(vehicle, 0, props.modSpoilers, false) end
		if props.modFrontBumper then SetVehicleMod(vehicle, 1, props.modFrontBumper, false) end
		if props.modRearBumper then SetVehicleMod(vehicle, 2, props.modRearBumper, false) end
		if props.modSideSkirt then SetVehicleMod(vehicle, 3, props.modSideSkirt, false) end
		if props.modExhaust then SetVehicleMod(vehicle, 4, props.modExhaust, false) end
		if props.modFrame then SetVehicleMod(vehicle, 5, props.modFrame, false) end
		if props.modGrille then SetVehicleMod(vehicle, 6, props.modGrille, false) end
		if props.modHood then SetVehicleMod(vehicle, 7, props.modHood, false) end
		if props.modFender then SetVehicleMod(vehicle, 8, props.modFender, false) end
		if props.modRightFender then SetVehicleMod(vehicle, 9, props.modRightFender, false) end
		if props.modRoof then SetVehicleMod(vehicle, 10, props.modRoof, false) end
		if props.modEngine then SetVehicleMod(vehicle, 11, props.modEngine, false) end
		if props.modBrakes then SetVehicleMod(vehicle, 12, props.modBrakes, false) end
		if props.modTransmission then SetVehicleMod(vehicle, 13, props.modTransmission, false) end
		if props.modHorns then SetVehicleMod(vehicle, 14, props.modHorns, false) end
		if props.modSuspension then SetVehicleMod(vehicle, 15, props.modSuspension, false) end
		if props.modArmor then SetVehicleMod(vehicle, 16, props.modArmor, false) end
		if props.modTurbo then ToggleVehicleMod(vehicle,  18, props.modTurbo) end
		if props.modXenon then ToggleVehicleMod(vehicle,  22, props.modXenon) end
		if props.modFrontWheels then SetVehicleMod(vehicle, 23, props.modFrontWheels, false) end
		if props.modBackWheels then SetVehicleMod(vehicle, 24, props.modBackWheels, false) end
		if props.modPlateHolder then SetVehicleMod(vehicle, 25, props.modPlateHolder, false) end
		if props.modVanityPlate then SetVehicleMod(vehicle, 26, props.modVanityPlate, false) end
		if props.modTrimA then SetVehicleMod(vehicle, 27, props.modTrimA, false) end
		if props.modOrnaments then SetVehicleMod(vehicle, 28, props.modOrnaments, false) end
		if props.modDashboard then SetVehicleMod(vehicle, 29, props.modDashboard, false) end
		if props.modDial then SetVehicleMod(vehicle, 30, props.modDial, false) end
		if props.modDoorSpeaker then SetVehicleMod(vehicle, 31, props.modDoorSpeaker, false) end
		if props.modSeats then SetVehicleMod(vehicle, 32, props.modSeats, false) end
		if props.modSteeringWheel then SetVehicleMod(vehicle, 33, props.modSteeringWheel, false) end
		if props.modShifterLeavers then SetVehicleMod(vehicle, 34, props.modShifterLeavers, false) end
		if props.modAPlate then SetVehicleMod(vehicle, 35, props.modAPlate, false) end
		if props.modSpeakers then SetVehicleMod(vehicle, 36, props.modSpeakers, false) end
		if props.modTrunk then SetVehicleMod(vehicle, 37, props.modTrunk, false) end
		if props.modHydrolic then SetVehicleMod(vehicle, 38, props.modHydrolic, false) end
		if props.modEngineBlock then SetVehicleMod(vehicle, 39, props.modEngineBlock, false) end
		if props.modAirFilter then SetVehicleMod(vehicle, 40, props.modAirFilter, false) end
		if props.modStruts then SetVehicleMod(vehicle, 41, props.modStruts, false) end
		if props.modArchCover then SetVehicleMod(vehicle, 42, props.modArchCover, false) end
		if props.modAerials then SetVehicleMod(vehicle, 43, props.modAerials, false) end
		if props.modTrimB then SetVehicleMod(vehicle, 44, props.modTrimB, false) end
		if props.modTank then SetVehicleMod(vehicle, 45, props.modTank, false) end
		if props.modWindows then SetVehicleMod(vehicle, 46, props.modWindows, false) end

		if props.modLivery then
			SetVehicleMod(vehicle, 48, props.modLivery, false)
			SetVehicleLivery(vehicle, props.modLivery)
		end
	end
end

ESX.Game.Utils.DrawText3D = function(coords, text, size, font)
	coords = vector3(coords.x, coords.y, coords.z)

	local camCoords = GetGameplayCamCoords()
	local distance = #(coords - camCoords)

	if not size then size = 1 end
	if not font then font = 0 end

	local scale = (size / distance) * 2
	local fov = (1 / GetGameplayCamFov()) * 100
	scale = scale * fov

	SetTextScale(0.0 * scale, 0.55 * scale)
	SetTextFont(font)
	SetTextColour(255, 255, 255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextCentre(true)

	SetDrawOrigin(coords, 0)
	BeginTextCommandDisplayText('STRING')
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(0.0, 0.0)
	ClearDrawOrigin()
end

local bonesToCheck = {
	0x9995
}

local function canReachPed(playerPed, ped)
	if not HasEntityClearLosToEntity(ped, playerPed, 17) then
		return false
	end

	for i=1, #bonesToCheck do
		local boneCoords = GetPedBoneCoords(ped, bonesToCheck[i])
		local boneCoords2 = GetPedBoneCoords(ped, bonesToCheck[i])
		local rayHandle = StartShapeTestLosProbe(boneCoords.x, boneCoords.y, boneCoords.z, boneCoords2.x, boneCoords2.y, boneCoords2.z, 19)
		local finished, hit, _, _, _ = GetShapeTestResult(rayHandle)
		while finished ~= 0 and finished ~= 2 do
			Citizen.Wait(0)
			finished, hit, _, _, _ = GetShapeTestResult(rayHandle)
		end
	
		if hit == 0 then
			return true
		end
	end

	return false
end

ESX.ShowInventory = function()
	local elements = {
		{label = 'Broekzakken', value = 'inventory'},
		{label = 'Portemonnee', value = 'wallet'},
	}

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'inventory', {
		title    = 'Inventaris',
		align    = 'top-right',
		elements = elements
	}, function(data, menu)
		if data.current.value == 'wallet' then
			local wallet = collectWallet()
			openInventoryMenu(wallet,  "inventory_wallet", "Portemonnee")
		end
		if data.current.value == 'inventory' then
			local inventory, currentWeight = collectInventory()
			openInventoryMenu(inventory,  "inventory_items", _U('inventory', currentWeight / 1000, ESX.PlayerData.maxWeight / 1000))
		end
	end, function(data, menu)
		menu.close()
	end)

	
end

local equipment = {
	[`GADGET_PARACHUTE`] = true
}
function IsEquipment(weaponHash)
	return equipment[weaponHash] or false
end

function CanTransferWeapon(weaponHash)
	if type(weaponHash) == "string" then
		weaponHash = GetHashKey(weaponHash)
	end

	local selectedWeapon = GetSelectedPedWeapon(PlayerPedId())
	if not IsEquipment(weaponHash) and selectedWeapon ~= weaponHash then
		return false
	end
end

ESX.CanTransferWeapon = CanTransferWeapon

openInventoryMenu = function(elements, name, title)
	local playerPed = PlayerPedId()
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), name, {
		title    = title,
		align    = 'top-right',
		elements = elements
	}, function(data, menu)
		local player, distance = ESX.Game.GetClosestPlayer()
		local elements = {}

		if data.current.usable then
			table.insert(elements, {label = _U('use'), action = 'use', type = data.current.type, value = data.current.value})
		end

		if data.current.canSee then
			table.insert(elements, {label = 'Bekijken', action = 'see', type = data.current.type, value = data.current.value})
		end

		if data.current.canRemove then
			if player ~= -1 and distance <= 3.0 then
				table.insert(elements, {label = _U('give'), action = 'give', type = data.current.type, value = data.current.value})
			end
			
			table.insert(elements, {label = _U('remove'), action = 'remove', type = data.current.type, value = data.current.value})
		end

		if data.current.type == 'item_weapon' and data.current.ammo > 0 and player ~= -1 and distance <= 3.0 then
			table.insert(elements, {label = _U('giveammo'), action = 'give_ammo', type = data.current.type, value = data.current.value})
		end

		table.insert(elements, {label = _U('return'), action = 'return'})

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'inventory_item', {
			title    = data.current.label,
			align    = 'top-right',
			elements = elements,
		}, function(data1, menu1)
			local item, type = data1.current.value, data1.current.type

			if data1.current.action == 'give' then
				if type == 'item_weapon' then
					local weaponHash = GetHashKey(data.current.value)
					local selectedWeapon = GetSelectedPedWeapon(PlayerPedId())
					if not IsEquipment(weaponHash) and selectedWeapon ~= weaponHash then
						ESX.ShowNotification("Je kunt alleen wapens die je vast houdt aan iemand geven!")
						return
					end
				end
				local playersNearby = ESX.Game.GetPlayersInArea(GetEntityCoords(playerPed), 3.0)

				if #playersNearby > 0 then
					local players, elements = {}, {}
					local playerId = PlayerId()
					for k,player in ipairs(playersNearby) do
						local ped = GetPlayerPed(player)
						if player ~= playerId and IsEntityVisible(ped) and ped ~= playerPed and (type == 'license' or canReachPed(playerPed, ped)) then
							local serverId = GetPlayerServerId(player)
							elements[#elements + 1] = {
								label = serverId,
								playerId = serverId
							}
						end
					end
					table.sort(elements, function(a, b)
						return a.playerId < b.playerId
					end)

					ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'give_item_to', {
						title    = _U('give_to'),
						align    = 'top-right',
						elements = elements
					}, function(data2, menu2)
						local selectedPlayer, selectedPlayerId = GetPlayerFromServerId(data2.current.playerId), data2.current.playerId
						playersNearby = ESX.Game.GetPlayersInArea(GetEntityCoords(playerPed), 3.0)
						playersNearby = ESX.Table.Set(playersNearby)

						if playersNearby[selectedPlayer] then
							local selectedPlayerPed = GetPlayerPed(selectedPlayer)

							if type == 'license' or (IsPedOnFoot(selectedPlayerPed) and IsPedOnFoot(PlayerPedId())) or GetVehiclePedIsIn(selectedPlayerPed) == GetVehiclePedIsIn(PlayerPedId()) then
								if type == 'item_weapon' then
									ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'ammunition_amount', {
										title = "Hoeveelheid munitie"
									}, function(data3, menu3)
										local sourceAmmo = GetAmmoInPedWeapon(playerPed, GetHashKey(item))
										local ammo = math.min(tonumber(data3.value) or sourceAmmo, sourceAmmo)

										TriggerServerEvent('esx:giveInventoryItem', selectedPlayerId, type, item, ammo, -254323015)
										menu3.close()
										menu2.close()
										
									end)
								elseif type == 'license' then
									TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), selectedPlayerId, item or false)
									menu2.close()
								else
									ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'inventory_item_count_give', {
										title = _U('amount') .. (data.current.count and (" (Max %s)"):format(data.current.count) or "")
									}, function(data3, menu3)
										local quantity = tonumber(data3.value)
									
											if quantity then
												TriggerServerEvent('esx:giveInventoryItem', selectedPlayerId, type, item, quantity, -254323015)
												menu3.close()
												menu2.close()
												
											else
												ESX.ShowNotification(_U('amount_invalid'))
											end
									end, function(data3, menu3)
										menu3.close()
									end)
								end
							else
								ESX.ShowNotification(_U('in_vehicle'))
							end
						else
							ESX.ShowNotification(_U('players_nearby'))
							menu2.close()
						end
					end, function(data2, menu2)
						menu2.close()
					end)
				else
					ESX.ShowNotification(_U('players_nearby'))
				end
			elseif data1.current.action == 'remove' then
				if IsPedOnFoot(playerPed) then
					if type == 'item_weapon' then
						local weaponHash = GetHashKey(data.current.value)
						local selectedWeapon = GetSelectedPedWeapon(PlayerPedId())
						if not IsEquipment(weaponHash) and selectedWeapon ~= weaponHash then
							ESX.ShowNotification("Je kunt alleen wapens die je vast houdt weggooien!")
							return
						end
					end
					local dict, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
					ESX.Streaming.RequestAnimDict(dict)

					if type == 'item_weapon' then
						TaskPlayAnim(playerPed, dict, anim, 8.0, 1.0, 1000, 16, 0.0, false, false, false)
						RemoveAnimDict(dict)
						Citizen.Wait(1000)
						TriggerServerEvent('esx:removeInventoryItem', type, item, false)
					else
						ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'inventory_item_count_remove', {
							title = _U('amount') .. (data.current.count and (" (Max %s)"):format(data.current.count) or "")
						}, function(data2, menu2)
							local quantity = tonumber(data2.value)
							
							if item and quantity then
								menu2.close()
								TaskPlayAnim(playerPed, dict, anim, 8.0, 1.0, 1000, 16, 0.0, false, false, false)
								RemoveAnimDict(dict)
								Citizen.Wait(1000)
								if item then
									TriggerServerEvent('esx:removeInventoryItem', type, item or false, quantity or false)
								end
							else
								ESX.ShowNotification(_U('amount_invalid'))
							end
						end, function(data2, menu2)
							menu2.close()
						end)
					end
				end
			elseif data1.current.action == 'use' then
				TriggerServerEvent('esx:useItem', item)
			elseif data1.current.action == 'see' then
				if type == 'license' then
					TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()), item or false)
				end
			elseif data1.current.action == 'return' then
				menu1.close()
			elseif data1.current.action == 'give_ammo' then
				local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
				local closestPed = GetPlayerPed(closestPlayer)
				local pedAmmo = GetAmmoInPedWeapon(playerPed, GetHashKey(item))

				if IsPedOnFoot(closestPed) then
					if closestPlayer ~= -1 and closestDistance < 3.0 then
						if pedAmmo > 0 then
							ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'inventory_item_count_give', {
								title = _U('amountammo')
							}, function(data2, menu2)
								local quantity = tonumber(data2.value)

								if quantity then
									if pedAmmo >= quantity and quantity > 0 then
										TriggerServerEvent('esx:giveInventoryItem', GetPlayerServerId(closestPlayer), 'item_ammo', item, quantity, -254323015)
										menu2.close()
									else
										ESX.ShowNotification(_U('noammo'))
									end
								else
									ESX.ShowNotification(_U('amount_invalid'))
								end
							end, function(data2, menu2)
								menu2.close()
							end)
						else
							ESX.ShowNotification(_U('noammo'))
						end
					else
						ESX.ShowNotification(_U('players_nearby'))
					end
				else
					ESX.ShowNotification(_U('in_vehicle'))
				end
			end
		end, function(data1, menu1)
			menu1.close()
		end)
	end, function(data, menu)
		menu.close()
	end)
end

collectCards = function()
    local elements = {}

   	-- if checkIfHasItem('idcard') then
		table.insert(elements, {
			label = "ID Kaart",
			type = "license",
			value = nil,
			canSee = true,
			canRemove = true,
			item = true,
			itemName = 'idcard'
		})
	-- end

	if ESX.PlayerData.job.name == 'justitie' then
		table.insert(elements, {
			label = "Advocaten pas",
			type = "license",
			value = "lawyer",
			canSee = true,
			canRemove = true,
		})
	end

	if ESX.PlayerData.job.name == 'taxi' or ESX.PlayerData.job.name == 'offtaxi' then
		table.insert(elements, {
			label = "Taxi pas",
			type = "license",
			value = "taxi",
			canSee = true,
			canRemove = true,
		})
	end

	if ESX.PlayerData.job.name == 'reporter' or ESX.PlayerData.job.name == 'reporter2' or ESX.PlayerData.job.name == 'media' then
		table.insert(elements, {
			label = "Pers pas",
			type = "license",
			value = "press",
			canSee = true,
			canRemove = true,
		})
	end

	if ESX.PlayerData.job.name == 'mechanic' or ESX.PlayerData.job.name == 'offmechanic' then
		table.insert(elements, {
			label = "ANWB pas",
			type = "license",
			value = "mechanic",
			canSee = true,
			canRemove = true,
		})
	end

	if ESX.PlayerData.job.name == 'kmar'  or ESX.PlayerData.job.name == 'offkmar' then
		table.insert(elements, {
			label = "KMAR pas",
			type = "license",
			value = "kmar",
			canSee = true,
			canRemove = true,
		})
	end

	if ESX.PlayerData.job.name == 'ambulance' or ESX.PlayerData.job.name == 'offambulance' then
		table.insert(elements, {
			label = "Ambulance pas",
			type = "license",
			value = "ambulance",
			canSee = true,
			canRemove = true,
		})
	end

	if ESX.PlayerData.job.name == 'police' or ESX.PlayerData.job.name == 'offpolice' then
		table.insert(elements, {
			label = "Politie pas",
			type = "license",
			value = "police",
			canSee = true,
			canRemove = true,
		})
	end

	if exports['sts_discordperms']:hashelpergroup() == true then
		table.insert(elements, {
			label = "Staff pas",
			type = "license",
			value = "staff1",
			canSee = true,
			canRemove = true,
		})
	end

	if exports['sts_discordperms']:hasmodgroup() == true then
		table.insert(elements, {
			label = "Staff pas",
			type = "license",
			value = "staff2",
			canSee = true,
			canRemove = true,
		})
	end

	if exports['sts_discordperms']:hassupermodgroup() == true then
		table.insert(elements, {
			label = "Staff pas",
			type = "license",
			value = "staff3",
			canSee = true,
			canRemove = true,
		})
	end

	if exports['sts_discordperms']:hasjradmingroup() == true then
		table.insert(elements, {
			label = "Staff pas",
			type = "license",
			value = "staff4",
			canSee = true,
			canRemove = true,
		})
	end

	if exports['sts_discordperms']:hasadmingroup() == true then
		table.insert(elements, {
			label = "Staff pas",
			type = "license",
			value = "staff5",
			canSee = true,
			canRemove = true,
		})
	end

	if exports['sts_discordperms']:hassuperadmingroup() == true then
		table.insert(elements, {
			label = "Staff pas",
			type = "license",
			value = "staff6",
			canSee = true,
			canRemove = true,
		})
	end

	if exports['sts_discordperms']:hasheadstaffgroup() == true then
		table.insert(elements, {
			label = "Staff pas",
			type = "license",
			value = "staff7",
			canSee = true,
			canRemove = true,
		})
	end

	if exports['sts_discordperms']:hasbeheergroup() == true then
		table.insert(elements, {
			label = "Staff pas",
			type = "license",
			value = "staff8",
			canSee = true,
			canRemove = true,
		})
	end

    return elements
end

function checkIfHasItem(item)
	local inventory = ESX.GetPlayerDataKey('inventory')
	for i=1, #inventory do
        local data = inventory[i]
		if  data.name == item and data.count > 0 then
			return true
		end
	end
	return false
end

local instructor = nil

collectAccounts = function()
    local elements = {}
    --[[if ESX.PlayerData.money > 0 then
		local formattedMoney = _U('locale_currency', ESX.Math.GroupDigits(ESX.PlayerData.money))

		table.insert(elements, {
			label     = ('%s: <span style="color:lightgreen;">%s</span>'):format(_U('cash'), formattedMoney),
			count     = ESX.PlayerData.money,
			type      = 'item_money',
			value     = 'money',
			usable    = false,
			rare      = false,
			canRemove = true
		})
	end]]

	for k,v in pairs(ESX.PlayerData.accounts) do
		if v.money > 0 then
			local formattedMoney = _U('locale_currency', ESX.Math.GroupDigits(v.money))
			local canDrop = v.name ~= 'bank'

			table.insert(elements, {
				label     = ('%s: <span style="color:lightgreen;">%s</span>'):format(v.label, formattedMoney),
				count     = v.money,
				type      = 'item_account',
				value     = v.name,
				usable    = false,
				rare      = false,
				canRemove = canDrop
			})
		end
    end
    
    return elements
end

ESX.GetCurrentWeight = function()
	local currentWeight = 0
	if not ESX.PlayerData.inventory then
		print(("^1ERROR:^7 Not yet loaded!"))
		return nil
	end
	for i=1, #ESX.PlayerData.inventory, 1 do
		local v = ESX.PlayerData.inventory[i]
		if v.count > 0 then
			currentWeight = currentWeight + (v.weight * v.count)
		end
	end
	for i=1, #ESX.PlayerData.loadout do
		local v = ESX.PlayerData.loadout[i]
		local weaponData = Weapons[v.name]
		currentWeight = currentWeight + (weaponData.weight or 1000)
	end
	return currentWeight
end

ESX.GetMaxWeight = function()
	return ESX.PlayerData.maxWeight or 20000
end

collectWallet = function()
	local cards = collectCards()
	local accounts = collectAccounts()
	local wallet = {}

	for _,v in ipairs(accounts) do
		table.insert(wallet, v)
	end
	for _,v in ipairs(cards) do
		table.insert(wallet, v)
	end

	return wallet
end

collectInventory = function() 
	local playerPed = PlayerPedId()
    local elements, currentWeight = {}, 0

    for i=1, #ESX.PlayerData.inventory, 1 do
		local v = ESX.PlayerData.inventory[i]
		if v.count > 0 then
			currentWeight = currentWeight + (v.weight * v.count)
			table.insert(elements, {
				label     = ('%s x%s'):format(v.label, v.count),
				count     = v.count,
				type      = 'item_standard',
				value     = v.name,
				usable    = v.usable,
				rare      = v.rare,
				canRemove = v.canRemove
			})
		end
	end

	table.sort(elements, function(a, b) return a.label:upper() < b.label:upper() end)

	local selectedWeapon = GetSelectedPedWeapon(PlayerPedId())
	for i=1, #Config.Weapons, 1 do
		local v = Config.Weapons[i]
		local weaponHash = GetHashKey(v.name)

		if HasPedGotWeapon(playerPed, weaponHash, false) and v.name ~= 'WEAPON_UNARMED' then
			local ammo = GetAmmoInPedWeapon(playerPed, weaponHash)
			local _canRemove = true
			--[[if v.name == 'WEAPON_COMBATPISTOL' or v.name == 'WEAPON_CARBINERIFLE' or v.name == 'WEAPON_CARBINERIFLE_MK2' or v.name == 'WEAPON_STUNGUN' or v.name == 'WEAPON_SMG' then
				_canRemove = false
			end]]
			currentWeight = currentWeight + (v.weight or 1000)
			table.insert(elements, {
				label     = ('%s [%s]'):format(v.label, ammo),
				count     = 1,
				type      = 'item_weapon',
				holding	  = selectedWeapon == weaponHash,
				value     = v.name,
				ammo      = ammo,
				usable    = false,
				rare      = false,
				canRemove = _canRemove
			})
		end
    end
    return elements,currentWeight
end

ESX.Game.TryDeleteAny = function(handle, typeFunction)
	if typeFunction and type(typeFunction) ~= 'function' then
		typeFunction = lookupTable[typeFunction]
	end
	typeFunction = typeFunction or DeleteVehicle
	Citizen.CreateThread(function()
		if DoesEntityExist(handle) then
			NetworkRequestControlOfEntity(handle)

			local timeout = 2000
			while timeout > 0 and not NetworkHasControlOfEntity(handle) do
				Wait(100)
				timeout = timeout - 100
			end

			DecorSetBool(handle, "_DELETED", true)

			SetEntityAsMissionEntity(handle, true, true)

			local timeout = 2000
			while timeout > 0 and not IsEntityAMissionEntity(handle) do
				Wait(100)
				timeout = timeout - 100
			end

			DecorSetBool(handle, "_DELETED", true)
			
			if typeFunction then
				typeFunction(handle)
			end

			if (DoesEntityExist(handle)) then
				DeleteEntity(handle)
			end

			if (DoesEntityExist(handle)) then
				SetEntityAsNoLongerNeeded(handle)
			end
		end
	end)
end

ESX.Game.SpawnCoords = function(coords, heading, model, space, direction)
	if not coords then
		error("coords is nil")
	end
	space = space or 0
	heading = heading or 0.0
	ESX.Streaming.RequestModel(model)
	local dimensionsMin, dimensionsMax = GetModelDimensions(model)
	SetModelAsNoLongerNeeded(model)
    local maxY = dimensionsMin.y + space
    if direction then
        maxY = dimensionsMax.y - space
    end
    local matrixY = math.cos((heading - 180.0) * math.pi/180)

    local maxX = dimensionsMin.y + space
    if direction then
        maxX = dimensionsMax.y - space
    end
    local matrixX = math.sin((heading - 0.0) * math.pi/180)

    return coords + vector3(maxX * matrixX, maxY * matrixY, 0.0)
end

ESX.Game.GetEntity = function(netId, handle)
	if handle and DoesEntityExist(handle) then
		return handle
	elseif netId and NetworkDoesNetworkIdExist(netId) then
		return NetworkGetEntityFromNetworkId(netId)
	end
end

ESX.Game.TryDeleteNetworkId = function(netId, model)
	return
end

ESX.Game.TryDeleteNetworkIdAsync = function(netId, model)
	return
end

ESX.Game.TryDeleteEntity = function(handle)
	if NetworkGetEntityIsNetworked(handle) then
		local model = GetEntityModel(handle)
		ESX.Game.TryDeleteNetworkId(NetworkGetNetworkIdFromEntity(handle), model)
		local start = GetGameTimer()
		while GetGameTimer() - start < 1000 and DoesEntityExist(handle) do
			Citizen.Wait(0)
		end
		if not DoesEntityExist(handle) then
			return true
		else
			return false
		end
	else
		return false
	end
end


RegisterNetEvent('esx:serverCallback')
AddEventHandler('esx:serverCallback', function(requestId, ...)
	ESX.ServerCallbacks[requestId](...)
	ESX.ServerCallbacks[requestId] = nil
end)

RegisterNetEvent('esx:showNotification')
AddEventHandler('esx:showNotification', function(msg, flash, saveToBrief, hudColorIndex)
	ESX.ShowNotification(msg, flash, saveToBrief, hudColorIndex)
end)

RegisterNetEvent('esx:showAdvancedNotification')
AddEventHandler('esx:showAdvancedNotification', function(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
	ESX.ShowAdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
end)

RegisterNetEvent('esx:showHelpNotification')
AddEventHandler('esx:showHelpNotification', function(msg, thisFrame, beep, duration)
	ESX.ShowHelpNotification(msg, thisFrame, beep, duration)
end)

-- SetTimeout
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local currTime = GetGameTimer()

		if #ESX.TimeoutCallbacks > 0 then
			for i=1, #ESX.TimeoutCallbacks, 1 do
				if ESX.TimeoutCallbacks[i] then
					if currTime >= ESX.TimeoutCallbacks[i].time then
						ESX.TimeoutCallbacks[i].cb()
						ESX.TimeoutCallbacks[i] = nil
					end
				end
			end
		else
			Citizen.Wait(500)
		end
	end
end)
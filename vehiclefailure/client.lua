------------------------------------------
--	iEnsomatic RealisticVehicleFailure  --
------------------------------------------
--
--	Created by Jens Sandalgaard
--
--	This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
--
--	https://github.com/iEns/RealisticVehicleFailure
--

local kmMultiplier = 5.0

---@type table<integer, GripData>
local materials = {}
local isPlayerWhiteListed = false

Citizen.CreateThread(function()
	xpcall(function()
		kmMultiplier = tonumber(GetConvar("kmh_multiplier", "5.0")) or 5.0
	end, Traceback or debug.traceback)
	while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(500)
    end

	while ESX.IsPlayerLoaded() ~= true do
		Citizen.Wait(500)
	end

	AddSuggestions()

	ESX.PlayerData = ESX.GetPlayerData()

	isPlayerWhiteListed = ESX.PlayerData.job.name == 'mechanic'
end)
DecorRegister('_ODO_METER', 1)

local pedInSameVehicleLast = false
local currentVehicle
local numWheels = 0
local lastVehicle
local vehicleClass
local vehicleModel
local fCollisionDamageMult = 0.0
local fDeformationDamageMult = 0.0
local fEngineDamageMult = 0.0
local fBrakeForce = 1.0
local isBrakingForward = false
local isBrakingReverse = false

local healthEngineLast = 1000.0
local healthEngineCurrent = 1000.0
local healthEngineNew = 1000.0
local healthEngineDelta = 0.0
local healthEngineDeltaScaled = 0.0

local healthBodyLast = 1000.0
local healthBodyCurrent = 1000.0
local healthBodyNew = 1000.0
local healthBodyDelta = 0.0
local healthBodyDeltaScaled = 0.0

local healthPetrolTankLast = 1000.0
local healthPetrolTankCurrent = 1000.0
local healthPetrolTankNew = 1000.0
local healthPetrolTankDelta = 0.0
local healthPetrolTankDeltaScaled = 0.0
local tireBurstLuckyNumber
local lastMaterial = nil
local gripModifier = 1.0
local debugMode = false
local defaultExponent = 0.5

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job

	isPlayerWhiteListed = job.name == 'mechanic'
end)

math.randomseed(GetCloudTimeAsInt());
math.random()

function AddSuggestions()
	TriggerEvent('chat:addSuggestion', '/add_speed_zone', 'Voeg een tijdelijke speed zone toe', {
		{ name="radius", help="Radius van speed zone (hoe groot de zone is) default = 300.0" },
		{ name="maxSpeed", help="Max snelheid in de speed zone default = 300.0" }
	})
end

local tireBurstMaxNumber = cfg.randomTireBurstInterval * 60; 												-- the tire burst lottery runs roughly 1200 times per minute
if cfg.randomTireBurstInterval ~= 0 then
	tireBurstLuckyNumber = math.random(cfg.randomTireBurstInterval * 60)
end			-- If we hit this number again randomly, a tire will burst.

local fixMessagePos = math.random(repairCfg.fixMessageCount)
local noFixMessagePos = math.random(repairCfg.noFixMessageCount)

local originalMin, originalMax, originalMass, originalBrakeForce, originalTractionLoss, originalDrivingForce, currentMin, currentMax, currentMass, currentBrakeForce
AddEventHandler("baseevents:enteredVehicle", function(vehicle, seat, _, netId, model)
	if seat == -1 then
		EnteredVehicle(vehicle)
	end
end)

AddEventHandler('baseevents:changedSeat', function(_vehicle, seat, displayName, netId, model, oldSeat)
	if seat == -1 then
		EnteredVehicle(_vehicle)
	end
	if oldSeat == -1 then
		currentVehicle = nil
		Citizen.Wait(0)
		LeftVehicle(_vehicle)
	end
end)

AddEventHandler("baseevents:leftVehicle", function(_vehicle, seat, displayName, netId)
	if seat == -1 then
		currentVehicle = nil
		Citizen.Wait(0)
		LeftVehicle(_vehicle)
	end
end)

function VerifyHandlingFloat(number)
	return number and number > 0.1
end

local cachedHandling = {}

--- Caches the best value and returns the best value, so the highest of the two
--- @param model Hash The vehicle model to check
--- @param fieldName string The handling fieldName to check
--- @param handlingFloat number The handling float from GetVehicleHandlingFloat
function CacheAndGetLowestValue(model, fieldName, handlingFloat)
	if not cachedHandling[model] then
		cachedHandling[model] = {}
	end

	if not handlingFloat then
		handlingFloat = 1.0
	end

	if not cachedHandling[model][fieldName] or handlingFloat < cachedHandling[model][fieldName] then
		cachedHandling[model][fieldName] = handlingFloat
	end

	return cachedHandling[model][fieldName]
end

--- Caches the best value and returns the best value, so the highest of the two
--- @param model Hash The vehicle model to check
--- @param fieldName string The handling fieldName to check
--- @param handlingFloat number The handling float from GetVehicleHandlingFloat
function CacheAndGetHighestValue(model, fieldName, handlingFloat)
	if not cachedHandling[model] then
		cachedHandling[model] = {}
	end

	if not handlingFloat then
		handlingFloat = 1.0
	end

	if not cachedHandling[model][fieldName] or handlingFloat > cachedHandling[model][fieldName] then
		cachedHandling[model][fieldName] = handlingFloat
	end

	return cachedHandling[model][fieldName]
end

function GetLowestHandlingFloat(vehicle, fieldName)
	local model = GetEntityModel(vehicle)
	local handlingFloat = GetVehicleHandlingFloat(vehicle, "CHandlingData", fieldName)
	return CacheAndGetLowestValue(model, fieldName, handlingFloat)
end

function GetHighestHandlingFloat(vehicle, fieldName)
	local model = GetEntityModel(vehicle)
	local handlingFloat = GetVehicleHandlingFloat(vehicle, "CHandlingData", fieldName)
	return CacheAndGetHighestValue(model, fieldName, handlingFloat)
end

function EnteredVehicle(_vehicle)
	if not DoesEntityExist(_vehicle) then
		return
	end
	if currentVehicle == _vehicle then
		return
	end
	if _vehicle ~= GetVehiclePedIsUsing(PlayerPedId()) then
		print("^1ERROR: ^7Vehicle and GetVehiclePedIsUsing not same!")
		_vehicle = GetVehiclePedIsUsing(PlayerPedId())
	end

	originalMax = originalMax or GetHighestHandlingFloat(_vehicle, "fTractionCurveMax")
	originalMin = originalMin or GetHighestHandlingFloat(_vehicle, "fTractionCurveMin")
	originalMass = originalMass or GetHighestHandlingFloat(_vehicle, "fMass")
	originalBrakeForce = originalBrakeForce or GetHighestHandlingFloat(_vehicle, "fBrakeForce") or 1.0
	originalTractionLoss = originalTractionLoss or GetLowestHandlingFloat(_vehicle, "fTractionLossMult")
	originalDrivingForce = originalDrivingForce or GetLowestHandlingFloat(_vehicle, "fInitialDriveForce")
	SetVehicleHandlingFloat(_vehicle, "CHandlingData", "fTractionLossMult", 0.0)
	currentMin, currentMax = originalMin, originalMax
	vehicleClass = GetVehicleClass(_vehicle)

	currentVehicle = _vehicle
	numWheels = GetVehicleNumberOfWheels(_vehicle)
	if numWheels == _vehicle or numWheels > 40 then
		numWheels = 0
	end
end
local odometer
local lastPlate
local isStuck = false
function LeftVehicle(_vehicle)
	currentVehicle = nil
	numWheels = 0
	if not DoesEntityExist(_vehicle) then
		fBrakeForce = originalBrakeForce or 1.0
		originalMin, currentMin = nil, nil
		originalMax, currentMax = nil, nil
		originalMass, currentMass = nil, nil
		originalBrakeForce, currentBrakeForce = nil, nil
		originalTractionLoss = nil
		gripModifier = 1.0
		vehicleClass = nil
		originalDrivingForce = nil
		return
	end

	print("Vehicle left, resetting modifiers")
	if odometer ~= nil then
		TriggerServerEvent('sts:addkm', lastPlate, odometer)
	end
	ModifyGrip(_vehicle, 1.0)
	ModifyTorque(_vehicle, 1.0)
	if originalMin and originalMin > 0.0 then
		TrySetVehicleHandlingFloat(_vehicle, "CHandlingData", "fTractionCurveMin", originalMin)
	end
	if originalMax and originalMax > 0.0 then
		TrySetVehicleHandlingFloat(_vehicle, "CHandlingData", "fTractionCurveMax", originalMax)
	end
	if originalMass and originalMass > 0.0 then
		TrySetVehicleHandlingFloat(_vehicle, "CHandlingData", "fMass", originalMass)
	end
	if originalBrakeForce and originalBrakeForce > 0.0 then
		TrySetVehicleHandlingFloat(_vehicle, "CHandlingData", "fBrakeForce", originalBrakeForce)
	end
	if originalTractionLoss then
		if originalTractionLoss < 0.1 then
			originalTractionLoss = GetLowestHandlingFloat(_vehicle, "fTractionLossMult")
		end
		xpcall(SetVehicleHandlingFloat, Traceback, _vehicle, "CHandlingData", "fTractionLossMult", originalTractionLoss)
	end
	SetVehicleEngineTorqueMultiplier(_vehicle, 1.0)

	if isStuck then
		SetVehicleBurnout(_vehicle, false)
		isStuck = false
	end

	fBrakeForce = originalBrakeForce or 1.0
	originalMin, currentMin = nil, nil
	originalMax, currentMax = nil, nil
	originalMass, currentMass = nil, nil
	originalBrakeForce, currentBrakeForce = nil, nil
	originalTractionLoss = nil
	gripModifier = 1.0
	vehicleClass = nil
	originalDrivingForce = nil
	_vehicle = 0
end

local currentModifier, lastModifiedVehicle
function ModifyGrip(vehicle, modifier)
	if not DoesEntityExist(currentVehicle) then
		return
	end
	if currentModifier == modifier and vehicle == lastModifiedVehicle then
		return
	end

	lastModifiedVehicle = vehicle
	currentModifier = modifier
	if originalMin then
		currentMin = originalMin * modifier
		TrySetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveMin", currentMin)
	end
	if originalMax then
		currentMax = originalMax * modifier
		TrySetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveMax", currentMax)
	end
	if originalMass and originalMass < 1000 then
		currentMass = originalMass / modifier
		TrySetVehicleHandlingFloat(vehicle, "CHandlingData", "fMass", currentMass)
	end
	-- if originalBrakeForce then
	-- 	currentBrakeForce = originalBrakeForce * modifier
	-- 	fBrakeForce = currentBrakeForce
	-- 	SetVehicleHandlingFloat(vehicle, "CHandlingData", "fBrakeForce", currentBrakeForce)
	-- end

	if modifier == 1 then
		currentMin = nil
		currentMax = nil
		currentBrakeForce = nil
		currentMass = nil
		fBrakeForce = originalBrakeForce
	end
end

function ModifyTorque(vehicle, torqueFactor)
	SetVehicleEngineTorqueMultiplier(vehicle, torqueFactor)
	if originalBrakeForce then
		currentBrakeForce = originalBrakeForce * torqueFactor
		fBrakeForce = currentBrakeForce
		SetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fBrakeForce", currentBrakeForce)
	end
end

-- AddEventHandler("baseevents:changedSeat", function(currentVehicle, currentSeat, displayName, netId, model, oldSeat)

-- end)

-- Display blips on map
Citizen.CreateThread(function()
	if (cfg.displayBlips == true) then
		AddTextEntry("_BLIP_VEHICLEFAILURE", repairCfg.BlipName)
		for _, item in pairs(repairCfg.mechanics) do
			item.blip = AddBlipForCoord(item.x, item.y, item.z)
			SetBlipSprite(item.blip, item.id)
			SetBlipAsShortRange(item.blip, true)
			BeginTextCommandSetBlipName("_BLIP_VEHICLEFAILURE")
			EndTextCommandSetBlipName(item.blip)
		end
	end
end)

local function notification(msg)
	SetNotificationTextEntry("STRING")
	AddTextComponentString(msg)
	DrawNotification(false, false)
end

local function isPedDrivingAVehicle()
	local ped = PlayerPedId()
	local vehicle = GetVehiclePedIsIn(ped, false)
	if IsPedInAnyVehicle(ped, false) then
		-- Check if ped is in driver seat
		if GetPedInVehicleSeat(vehicle, -1) == ped then
			return true
		end
	end
	return false
end

local function IsNearMechanic(vehicle)
	local ped = PlayerPedId()
	local pedLocation = GetEntityCoords(ped, 0)
	for _, item in pairs(repairCfg.mechanics) do
		if (item.classes == nil or item.classes[GetVehicleClass(vehicle)]) and #(item.coords - pedLocation) <= (item.radius or repairCfg.Radius) then
			return true
		end
	end
end

local function fscale(inputValue, originalMin, originalMax, newBegin, newEnd, curve)
	local OriginalRange = 0.0
	local NewRange = 0.0
	local zeroRefCurVal = 0.0
	local normalizedCurVal = 0.0
	local rangedValue = 0.0
	local invFlag = 0

	if (curve > 10.0) then curve = 10.0 end
	if (curve < -10.0) then curve = -10.0 end

	curve = (curve * -.1)
	curve = 10.0 ^ curve

	if (inputValue < originalMin) then
		inputValue = originalMin
	end
	if inputValue > originalMax then
		inputValue = originalMax
	end

	OriginalRange = originalMax - originalMin

	if (newEnd > newBegin) then
		NewRange = newEnd - newBegin
	else
		NewRange = newBegin - newEnd
		invFlag = 1
	end

	zeroRefCurVal = inputValue - originalMin
	normalizedCurVal  =  zeroRefCurVal / OriginalRange

	if (originalMin > originalMax ) then
		return 0
	end

	if (invFlag == 0) then
		rangedValue =  ((normalizedCurVal ^ curve) * NewRange) + newBegin
	else
		rangedValue =  newBegin - ((normalizedCurVal ^ curve) * NewRange)
	end

	return rangedValue
end

local lastCoords
local ownedVehicle
local lastSync = 0

local commands = Command:new("vehiclefailure")

commands:add({
	name = "getodometer",
	cb = function()
		print(tostring(odometer) .. ' : ' .. tostring(lastPlate))
	end
})

commands:add({
	name = "modifier",
	cb = function()
		print(currentModifier)
	end
})

commands:add({
	name = "tractionloss",
	cb = function()
		print(originalTractionLoss)
	end
})

local wheelConversion = {
	[0] = 0,
	[1] = 1,
	[2] = 4,
	[3] = 5,
	[4] = 2,
	[5] = 3
}

local currentLimit = nil
function ResetLimit(currentVehicle)
	currentLimit = nil
	return exports["esx_cruisecontrol"]:resetLimit(currentVehicle)
end

function SetLimit(currentVehicle, speed)
	currentLimit = speed
	return exports["esx_cruisecontrol"]:setLimit(currentVehicle, speed)
end

function GetMaterial(source, args, raw)
	local vehicle = GetVehiclePedIsIn(PlayerPedId())
	local materialIndex = GetVehicleWheelSurfaceMaterial(vehicle, 0)
	local material = materials[materialIndex]

	if not material then
		print("Geen materiaal gevonden onder linker voorwiel!")
		return
	end

	local message = ("materialHash: %s; material: %s; materialIndex: %s;"):format(material.hash, material.name, materialIndex)
	print(message)
	print("rainLevel: ", GetRainLevel())
	return message
end

commands:add({
	name = "getmaterial",
	cb = GetMaterial
})

commands:add({
	name = "materialdebug",
	cb = function()
		debugMode = not debugMode
		print(("Debug mode is nu %s"):format(debugMode and "Geactiveerd" or "Gedeactiveerd"))
	end
})

commands:add({
	name = "speed",
	cb = function()
		print(currentLimit)
	end
})

function BurstTyre(source, args, raw)
	if args[1] == 'misstake' then
		local vehicle = GetVehiclePedIsIn(PlayerPedId())
		local numWheels = GetVehicleNumberOfWheels(vehicle)
		-- We won the lottery, lets burst a tire.
		if GetVehicleTyresCanBurst(vehicle) == false then return end
		local affectedTire
		if numWheels == 2 then
			affectedTire = (math.random(2)-1)*4		-- wheel 0 or 4
		elseif numWheels == 4 then
			affectedTire = (math.random(4)-1)
			if affectedTire > 1 then affectedTire = affectedTire + 2 end	-- 0, 1, 4, 5
		elseif numWheels == 6 then
			affectedTire = (math.random(6)-1)
		else
			affectedTire = 0
		end
		SetVehicleTyreBurst(vehicle, affectedTire, false, 1000.0)
	end
end

commands:add({
	name = "bursttyre",
	cb = BurstTyre
})

exports('odometer', function()
	return odometer
end)

function UpdateOdometer(vehicle, odometer)
	--print("updating odometer, vehicle: "..vehicle.." - odometer: "..odometer)
	DecorSetFloat(vehicle, "_ODO_METER", odometer)
	TriggerEvent("vehiclefailure:odometer", vehicle, odometer)
end

local oldZ = 0
local zeroCoords = vector3(0,0,0)
local function tireBurstLottery()
	Citizen.SetTimeout(1000, tireBurstLottery)


	local _vehicle = currentVehicle
	if _vehicle == nil then
		if not isPedDrivingAVehicle() then
			return
		else
			_vehicle = GetVehiclePedIsIn(PlayerPedId())
		end
	end
	if not DoesEntityExist(_vehicle) then
		return
	end
	local coords = GetEntityCoords(_vehicle)
	local speed = GetEntitySpeed(_vehicle)
	local plate = ESX.Math.Trim(GetVehicleNumberPlateText(_vehicle))

	if oldZ < -50.0 and coords.z > -1.0 then
		Citizen.CreateThread(function()
			for i=1, 2 do
				local roll = GetEntityRoll(_vehicle)
				if (roll > 50.0 or roll < -50.0) then
					SetEntityRotation(_vehicle, 0.0, 0.0, GetEntityHeading(_vehicle))
					SetVehicleOnGroundProperly(_vehicle)
				end
				Citizen.Wait(500)
			end
		end)
	end
	oldZ = coords.z
	if coords.z < -75.0 and NetworkGetEntityIsNetworked(_vehicle) then
		local retval, roadCoords, roadCoords2 = GetClosestRoad(coords.x, coords.y, coords.z)
		if retval then
			local distance1 = #(coords - roadCoords)
			local distance2 = #(coords - roadCoords2)
			if distance1 < distance2 and distance1 < 300.0 then
				SetPedCoordsKeepVehicle(PlayerPedId(), roadCoords.x, roadCoords.y, roadCoords.z + 1.0)
				SetVehicleOnGroundProperly(_vehicle)
			elseif distance2 < distance1 and distance2 < 300.0 then
				SetPedCoordsKeepVehicle(PlayerPedId(), roadCoords2.x, roadCoords2.y, roadCoords2.z + 1.0)
				SetVehicleOnGroundProperly(_vehicle)
			end
			Citizen.Wait(100)
			Citizen.Wait(100)
		end
	end

	if odometer ~= nil and lastPlate == plate and lastCoords ~= nil and coords ~= nil and #(zeroCoords - coords) > 20.0 and #(zeroCoords - coords) > 20.0 then
		local distance = #(coords - lastCoords)
		if distance - speed > 10.0 then
			distance = speed
		end
		odometer = odometer + (distance / 1000)
		--print("update odometer... vehicle: ".._vehicle.." - odometer: "..odometer)
		UpdateOdometer(_vehicle, odometer)
	end

	if GetGameTimer() - lastSync > 10000 and lastPlate == plate then
		lastSync = GetGameTimer()
		if not ownedVehicle then
			SetResourceKvpFloat(plate, odometer)
		end
	end

	if lastPlate ~= plate then
		odometer = nil
		ownedVehicle = false
		ESX.TriggerServerCallback('sts:getcurrentkm', function(hasKM)
		end, plate)
	end

	lastPlate = plate
	lastCoords = coords

	if numWheels > 0 then
		local burst = false
		local wheelSpeed = speed
		for i=0, numWheels do
			local index = i
			if numWheels == 4 then
				index = (i + 4) % 6
			end
			if numWheels == 2 then
				index = (i + 5) % 5
			end
			wheelSpeed = math.max(math.abs(GetVehicleWheelSpeed(_vehicle, wheelConversion[index])), speed)

			if wheelSpeed > 10 and IsVehicleTyreBurst(_vehicle, index, false) then
				burst = true
				wheelSpeed = wheelSpeed - 7.5
				healthEngineLast = healthEngineLast - (wheelSpeed ^ 1.4)
			end
		end
		if burst and math.abs(healthEngineLast - healthEngineCurrent) > 0.01 then
			SetVehicleEngineHealth(_vehicle, healthEngineLast + 0.0)
		end

		if speed > 10 and cfg.randomTireBurstInterval ~= 0 then
			local tireBurstNumber = math.random(tireBurstMaxNumber)
			if speed > 25 and tireBurstNumber ~= tireBurstLuckyNumber then
				tireBurstNumber = math.random(tireBurstMaxNumber)
			end
			if tireBurstNumber == tireBurstLuckyNumber then
				-- We won the lottery, lets burst a tire.
				if GetVehicleTyresCanBurst(_vehicle) == false then return end
				local affectedTire
				if numWheels == 2 then
					affectedTire = (math.random(2)-1)*4		-- wheel 0 or 4
				elseif numWheels == 4 then
					affectedTire = (math.random(4)-1)
					if affectedTire > 1 then affectedTire = affectedTire + 2 end	-- 0, 1, 4, 5
				elseif numWheels == 6 then
					affectedTire = (math.random(6)-1)
				else
					affectedTire = 0
				end
				SetVehicleTyreBurst(_vehicle, affectedTire, false, 1000.0)
				tireBurstLuckyNumber = math.random(tireBurstMaxNumber)			-- Select a new number to hit, just in case some numbers occur more often than others
			end
		end
	end
end

RegisterNetEvent("vehiclefailure:getodometer")
AddEventHandler("vehiclefailure:getodometer", function(distance)
	--print("adding distance: "..distance)
	ownedVehicle = distance ~= nil
	local vehicle = GetVehiclePedIsIn(PlayerPedId())
	local plate = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle))
	odometer = distance or (plate and GetResourceKvpFloat(plate) or 0.0) or 0.0
	DecorSetFloat(vehicle, "_ODO_METER", odometer)
end)

TriggerEvent('chat:addSuggestion', '/repareer', 'Repareer het voertuig waar je in zit (of het dichstbijzijnde voertuig)', {})

function GetEntityEngineCoords(vehicle)
	local engineBone = GetEntityBoneIndexByName(vehicle, "engine")
	local rawEngineCoords = GetWorldPositionOfEntityBone(vehicle, engineBone)
	local entityModel = GetEntityModel(vehicle)
	local dimensionMin, dimensionMax = GetModelDimensions(entityModel)
	local forwardVector = GetEntityForwardVector(vehicle)
	local frontCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, dimensionMin.y, dimensionMin.z) - (forwardVector * 0.5)
	local backCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, dimensionMax.y, dimensionMin.z) + (forwardVector * 0.5)

	local distance = 10000
	local outCoords = frontCoords
	local useFront = true
	local entityHeading = GetEntityHeading(vehicle)
	local outheading = entityHeading

	local frontEnginedist = #(rawEngineCoords - frontCoords)
	if frontEnginedist < distance then
		outCoords = frontCoords
		distance = frontEnginedist
		useFront = true
	end
	local backEngineDist = #(rawEngineCoords - backCoords)
	if backEngineDist < distance then
		distance = backEngineDist
		outCoords = backCoords
		useFront = false
	end
	if not useFront then
		outheading = entityHeading + 180.0
	end
	return outCoords, outheading, frontCoords, backCoords, not useFront
end

function IsNavMeshLoadedInCustom()
	local playerPed = PlayerPedId()
	local interior = GetInteriorFromEntity(playerPed)
	local bbminx, bbminy, bbminz, bbmaxx, bbmaxy, bbmaxz = GetInteriorEntitiesExtents(interior)
	local numNavMesh = GetNumNavmeshesExistingInArea(bbminx, bbminy, bbminz, bbmaxx, bbmaxy, bbmaxz)
	print("numNavMesh: ", numNavMesh)
	local loadedInArea = IsNavmeshLoadedInArea(bbminx, bbminy, bbminz, bbmaxx, bbmaxy, bbmaxz)
	print("IsNavmeshLoadedInArea: ", loadedInArea)
end

function LoadAnimDict(dict)
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		Citizen.Wait(50)
	end
end

function LoadAnimDicts(dicts)
	for k,v in pairs(dicts) do
		LoadAnimDict(v)
	end
end

function UnloadAnimDicts(dicts)
	for k,v in pairs(dicts) do
		RemoveAnimDict(v)
	end
end

RegisterNetEvent('iens:repair')
AddEventHandler('iens:repair', function()
	local ped = PlayerPedId()
	local vehicle = GetVehiclePedIsIn(ped, false)
	if not DoesEntityExist(vehicle) then
		vehicle, _ = ESX.Game.GetClosestVehicle()
		
		if GetPedInVehicleSeat(vehicle, -1) ~= 0 then
			ESX.ShowNotification("Zorg ervoor dat er niemand op de bestuurdersstoel zit!")
			return
		end
	end
	if IsNearMechanic(vehicle) then
		local health = math.max(((GetVehicleEngineHealth(vehicle) * 1.0) + (GetVehicleBodyHealth(vehicle) * 1.0)) / 2, 100.0)
		local price = math.max(math.floor((900-health) * 3), 100)

		NetworkRequestControlOfEntity(vehicle)
		local attempts = 0
		while not NetworkHasControlOfEntity(vehicle) and attempts < 10 do
			NetworkRequestControlOfEntity(vehicle)
			attempts = attempts + 1
			Citizen.Wait(100)
		end
		TriggerServerEvent("sts:payrepair", price)
	else
		notification("Ga naar de dichstbijzijnde mod shop om je voertuig te repareren!")
	end
end)


RegisterNetEvent('iens:repair2')
AddEventHandler('iens:repair2', function(payed, price)
	local ped = PlayerPedId()
	local vehicle = GetVehiclePedIsIn(ped, false)
	if not DoesEntityExist(vehicle) then
		vehicle, _ = ESX.Game.GetClosestVehicle()
		
		if GetPedInVehicleSeat(vehicle, -1) ~= 0 then
			ESX.ShowNotification("Zorg ervoor dat er niemand op de bestuurdersstoel zit!")
			return
		end
	end

	local function ShapeTestHitCollision(entity, startCoords, endCoords)
		local firstStartCoords = vector3(startCoords.x, startCoords.y, startCoords.z + 1.3)
		local firstEndCoords = vector3(endCoords.x, endCoords.y, endCoords.z + 0.1)
		if DevServer then
			Citizen.CreateThread(function()
				while true do
					Citizen.Wait(0)
					DrawLine(firstStartCoords.x, firstStartCoords.y, firstStartCoords.z, firstEndCoords.x, firstEndCoords.y, firstEndCoords.z, 255, 0, 0, 255)
					--DrawMarker(1, firstStartCoords.x, firstStartCoords.y, firstStartCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.0, 255, 0, 0, 255)
					--DrawMarker(1, firstEndCoords.x, firstEndCoords.y, firstEndCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.0, 0, 255, 0, 255)
				end
			end)
		end
		local shapeTest = StartShapeTestLosProbe(firstStartCoords.x, firstStartCoords.y, firstStartCoords.z, firstEndCoords.x, firstEndCoords.y, firstEndCoords.z, 31, entity)
		local secondStartCoords = vector3(startCoords.x, startCoords.y, startCoords.z + 0.1)
		local secondEndCoords = vector3(endCoords.x, endCoords.y, endCoords.z + 1.3)
		if DevServer then
			Citizen.CreateThread(function()
				while true do
					Citizen.Wait(0)
					DrawLine(secondStartCoords.x, secondStartCoords.y, secondStartCoords.z, secondEndCoords.x, secondEndCoords.y, secondEndCoords.z, 255, 0, 0, 255)
					--DrawMarker(1, secondStartCoords.x, secondStartCoords.y, secondStartCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.0, 255, 0, 0, 255)
					--DrawMarker(1, secondEndCoords.x, secondEndCoords.y, secondEndCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.0, 0, 255, 0, 255)
				end
			end)
		end
		local shapeTest2 = StartShapeTestLosProbe(secondStartCoords.x, secondStartCoords.y, secondStartCoords.z, secondEndCoords.x, secondEndCoords.y, secondEndCoords.z, 31, entity)
		local hit, entityHit, valid
		local valid2, hit2, entityHit2
		repeat
			valid, hit, _, _, entityHit = GetShapeTestResult(shapeTest)
			valid2, hit2, _, _, entityHit2 = GetShapeTestResult(shapeTest2)
			Citizen.Wait(0)
		until valid ~= 1 and valid2 ~= 1
		if valid == 2 then
			local playerPed = PlayerPedId()
			if (hit and hit ~= 0 or entityHit and entityHit ~= 0) and entityHit ~= playerPed and (hit2 and hit2 ~= 0 and entityHit2 and entityHit2 ~= 0) and entityHit2 ~= playerPed then
				return true
			end
		end
	end

	local function StartMainRepairSequence()
		local playerPed = PlayerPedId()
		GlobalState.BlockDpEmotes = true
		local dicts = {'move_crawl', 'amb@world_human_vehicle_mechanic@male@base'}
		LoadAnimDicts(dicts)
		local engineCoords, heading, backCoords, frontCoords, isEngineUpFront = GetEntityEngineCoords(vehicle)
		local forwardVector = GetEntityForwardVector(vehicle)
		local backBeginCoords, backEndCoords = backCoords + forwardVector, backCoords - (forwardVector * 0.5)
		local frontBeginCoords, frontEndCoords = frontCoords - forwardVector, frontCoords + (forwardVector * 0.5)
		local backHit = ShapeTestHitCollision(vehicle, backBeginCoords, backEndCoords)
		local frontHit = ShapeTestHitCollision(vehicle, frontBeginCoords, frontEndCoords)
		if frontHit and isEngineUpFront and not backHit then
			engineCoords = backCoords
			heading = heading + 180
		elseif backHit and not isEngineUpFront and not frontHit then
			engineCoords = frontCoords
			heading = heading + 180
		elseif backHit and frontHit then
			local model = GetEntityModel(vehicle)
			local min, max = GetModelDimensions(model)
			local sideLocationmin, sideLocationMax = min.x, max.x
			local vehicleCoords = GetEntityCoords(vehicle)
			local sideCoordsMin, shapeSideCoordsMin = GetOffsetFromEntityInWorldCoords(vehicle, sideLocationmin - 0.8, 0.0, min.z), GetOffsetFromEntityInWorldCoords(vehicle, sideLocationmin + 0.8, 0.0, min.z)
			local sideCoordsMax, shapeSideCoordsMax = GetOffsetFromEntityInWorldCoords(vehicle, sideLocationMax + 0.8, 0.0, min.z), GetOffsetFromEntityInWorldCoords(vehicle, sideLocationMax - 0.8, 0.0, min.z)
			local sideLeftHit = ShapeTestHitCollision(vehicle, shapeSideCoordsMin, sideCoordsMin)
			local sideRightHit = ShapeTestHitCollision(vehicle, shapeSideCoordsMax, sideCoordsMax)
			if not sideLeftHit then
				engineCoords = sideCoordsMin
				heading = heading + 270
			elseif not sideRightHit then
				engineCoords = sideCoordsMax
				heading = heading + 90
			end
		end
		local sequence = OpenSequenceTask()
		TaskLeaveVehicle(0, vehicle, 1)
		TaskGoStraightToCoord(0, engineCoords.x, engineCoords.y, engineCoords.z + 0.5, 1.0, 3000, heading + 180.0, 1.5)
		TaskPlayAnim(0, dicts[1], 'onback_bwd', 3.0, -3.0, 2500, 1, 1.0, 0,0,0)
		TaskPlayAnim(0, dicts[2], 'base', 3.0, -3.0, 7500, 1, 0, false, false, false)
		TaskPlayAnim(0, dicts[1], 'onback_fwd', 3.0, -1.5, 3500, 1, 1.0, 0,0,0)
		CloseSequenceTask(sequence)
		TaskPerformSequence(playerPed, sequence)
		while GetSequenceProgress(playerPed) == -1 do
			Citizen.Wait(0)
		end
		while IsAnySequenceRunning(playerPed) and GetSequenceProgress(playerPed) ~= 4 do
			Citizen.Wait(0)
			DisableAllControlActions(0)
			if GetSequenceProgress(playerPed) >= 2 then
				SetEntityNoCollisionEntity(ped, vehicle, true)
			end
			DisableCamCollisionForEntity(vehicle)
			EnableControlAction(0, 0, true)
			EnableControlAction(0, 1, true)
			EnableControlAction(0, 2, true)
			EnableControlAction(0, 3, true)
			EnableControlAction(0, 4, true)
			EnableControlAction(0, 5, true)
			EnableControlAction(0, 6, true)
			EnableControlAction(0, 249, true)
		end
		UnloadAnimDicts(dicts)
		return sequence
	end
	if payed == true then
		xpcall(function()
			local sequence = StartMainRepairSequence()
			TriggerServerEvent('eden_garage:repairVehicle', ESX.Math.Trim(GetVehicleNumberPlateText(vehicle)))
			SetVehicleUndriveable(vehicle,false)
			SetVehicleDeformationFixed(vehicle)
			SetVehicleFixed(vehicle)
			healthBodyLast = 1000.0
			healthBodyNew = 1000.0
			healthBodyCurrent = 1000.0
			healthPetrolTankLast = 1000.0
			healthPetrolTankCurrent = 1000.0
			healthPetrolTankNew = 1000.0
			healthEngineLast = 1000.0
			healthEngineCurrent = 1000.0
			healthEngineNew = 1000.0
			SetVehicleEngineOn(vehicle, true, false )
			TriggerEvent('CruiseControl:SetLimiter', vehicle)
			notification(("~g~Je hebt €%.0f,- betaalt om je auto te repareren"):format(price))
			while IsAnySequenceRunning(ped) do
				Citizen.Wait(0)
				DisableAllControlActions(0)
				EnableControlAction(0, 0, true)
				EnableControlAction(0, 1, true)
				EnableControlAction(0, 2, true)
				EnableControlAction(0, 3, true)
				EnableControlAction(0, 4, true)
				EnableControlAction(0, 5, true)
				EnableControlAction(0, 6, true)
				EnableControlAction(0, 249, true)
				SetEntityNoCollisionEntity(ped, vehicle, true)
				DisableCamCollisionForEntity(vehicle)
			end
			TaskEnterVehicle(ped, vehicle, 5000, -1, 1.0, 1, 0)
			ClearSequenceTask(sequence)
		end, Traceback)
		GlobalState.BlockDpEmotes = false
	else
		ESX.ShowNotification("Je hebt ~r~niet genoeg geld~s~ om de reparatie te kunnen betalen!")
	end
	return
end)

function IsAnySequenceRunning(ped)
	local seqProg = GetSequenceProgress(ped)
	return seqProg >= 0 and seqProg <= 7
end

RegisterNetEvent('iens:notAllowed')
AddEventHandler('iens:notAllowed', function()
	notification("~r~You don't have permission to repair vehicles")
end)

RegisterNetEvent('iens:ANWB')
AddEventHandler('iens:ANWB', function()
	notification("~r~Er is ANWB online bel die")
end)

local wheels = {
	"wheel_lr",
	"wheel_rf",
	"wheel_rr"
}

local currentWeather = 'EXTRASUNNY'
TriggerEvent('vSync:getWeather', function(weather)
	currentWeather = weather
end)
AddEventHandler('vSync:onWeatherChanged', function(weather)
	if weather then
		currentWeather = weather:upper()
	end
end)


RegisterCommand('getmaterial', function()
	local vehicle = GetVehiclePedIsIn(PlayerPedId())
	local materialIndex = GetVehicleWheelSurfaceMaterial(vehicle, 0)
	local material = materials[materialIndex]
	local boneIndex = GetEntityBoneIndexByName(vehicle, "wheel_lf")
	local coords
	if boneIndex ~= -1 then
		coords = GetWorldPositionOfEntityBone(vehicle, boneIndex)
	else
		coords = GetEntityCoords(vehicle)
	end
	local ray = StartShapeTestRay(coords.x, coords.y, coords.z + 2.0, coords.x, coords.y, coords.z - 2.0, 1, vehicle)
	local _, _, _, _, materialHash = GetShapeTestResultIncludingMaterial(ray)

	local hash = tostring(materialHash)
	local materialIndexRayCast = nil
	local materialRayCast
	for k, v in pairs(materials) do
		if v.hash == hash then
			materialRayCast = v
			materialIndexRayCast = k
			break
		end
	end

	local message = ("materialHash: %s; material: %s; materialIndex: %s; materialRaycastIndex: %s; materialNew: %s"):format(materialHash, materialRayCast.name, materialIndex, materialIndexRayCast, material.name)
	print(message)
	print("rainLevel: ", GetRainLevel())
	return message
end)


local offroadSnowModifier = 0.2

local classModifiers = {
	[9] = offroadSnowModifier, -- Offroad
	[10] = offroadSnowModifier, -- Industrial
	[11] = offroadSnowModifier, -- Utility
	[18] = offroadSnowModifier,
	[20] = offroadSnowModifier, -- Commercial (vrachtwagens)
}
local function getSnowModifier()
	local modifier = 0.70
	local wheelType = GetVehicleWheelType(currentVehicle)
	local tractionLoss = originalTractionLoss
	if classModifiers[vehicleClass] then
		modifier = modifier + classModifiers[vehicleClass]
	elseif tractionLoss < 0.8 then
		-- Adjust modifier for offroad vehicles
		modifier = modifier + offroadSnowModifier
	elseif tractionLoss > 1.1 then
		-- Adjust modifier for non offroad vehicles (super etc)
		modifier = modifier - 0.05
	end

	if wheelType == 4 then
		-- Adjust modifier for vehicles with offroad tyres
		modifier = modifier + 0.15
	end

	return math.min(modifier, 1.0)
end

local debugInfo = {}
local running = false
function DrawThread()
	if running then
		return
	end
	running = true
	Citizen.CreateThread(function()
		while debugMode do
			for k,v in pairs(debugInfo) do
				SetTextFont(0)
				SetTextProportional(1)
				SetTextScale(0.0, 0.30)
				SetTextDropshadow(0, 0, 0, 0, 255)
				SetTextEdge(1, 0, 0, 0, 255)
				SetTextDropShadow()
				SetTextOutline()
				AddTextEntry("GRIP_DEBUG" .. tostring(k), v)
				SetTextEntry("GRIP_DEBUG" .. tostring(k))
				--AddTextComponentString(v)
				EndTextCommandDisplayText(0.3, 0.7+(k/30))
			end
			Citizen.Wait(0)
		end
		running = false
	end)
end

local function drawInfo(text, i)
	debugInfo[i] = text
end

local bikeModels = {
	[`bf400`] = true,
	[`policeb`] = true,
	[`kmarb`] = true,
}
local function isMotorCycle()
	if vehicleClass == 8 or bikeModels[vehicleModel] then
		return true
	else
		return false
	end
end

--- Gets the modifiers of the surface the tyres of the current vehicle are on
--- @return number torqueModifier
--- @return number modifier
--- @return number maxSpeed
--- @return number step
--- @return table material
--- @return integer materialIndex
local function getMaterialModifiersFromTyres()
	local materialIndex
	local material
	local torqueModifier, modifier, maxSpeed, step
	local gripModifiersApplied, torqueModifiersApplied = 0, 0
	local tractionLossExponent = nil
	local numFound = 0
	local stuck = 0
	local stepsApplied = 0
	if numWheels > 0 then
		for i=0, numWheels - 1 do
			local _materialIndex = GetVehicleWheelSurfaceMaterial(currentVehicle, i)
			local _material = materials[_materialIndex]
			if _material and _material.name ~= "unk" then
				materialIndex = _materialIndex
				material = _material
				if _material.modifier then
					gripModifiersApplied = gripModifiersApplied + 1
					modifier = (modifier or 0) + _material.modifier
				end
				if _material.torqueModifier then
					torqueModifiersApplied = torqueModifiersApplied + 1
					torqueModifier = (torqueModifier or 0) + _material.torqueModifier
				end
				if _material.maxSpeed then
					maxSpeed = math.min(maxSpeed or 10000, _material.maxSpeed)
				end
				if _material.step then
					stepsApplied = stepsApplied + 1
					step = (step or 0) + _material.step
				end
				if debugMode then
					drawInfo(("%s: %s %.2f %.2f %.2f"):format(i, _material.name, _material.modifier or -1.0, _material.torqueModifier or -1.0, GetVehicleWheelTractionVectorLength(currentVehicle, i) or -1.0), i)
					DrawThread()
				end

				if _material.stuck then
					stuck = stuck + 1
				end


				numFound = numFound + 1
				tractionLossExponent = (tractionLossExponent or 0) + (_material.tractionLossExponent or defaultExponent)
			end
		end

		if stuck == numWheels then
			stuck = true
		else
			stuck = false
		end

		if step and stepsApplied then
			step = step / stepsApplied
		end

		if tractionLossExponent then
			tractionLossExponent = tractionLossExponent / numFound
		else
			tractionLossExponent = defaultExponent
		end

		if gripModifiersApplied > 0 then
			modifier = modifier / gripModifiersApplied
		end
		if torqueModifiersApplied > 0 then
			torqueModifier = torqueModifier / torqueModifiersApplied
		end
	end

	return torqueModifier, modifier, maxSpeed, step, material, materialIndex, tractionLossExponent or 1.0, stuck
end

local function getDeceleration(vehicle, step)
	if not step then
		return 0
	end
	local frameTime = math.min(GetFrameTime(), 0.05)

	return step * frameTime
end

function GetMaxSpeedForSpeedZone(coords)
	local minDistance = 10000
	local maxSpeed
	for i=1, #SpeedZones do
		local distance = #(coords - SpeedZones[i].Coords)
		if distance < SpeedZones[i].Radius then
			if distance < minDistance then
				maxSpeed = SpeedZones[i].MaxSpeed
				minDistance = distance
			end
		end
	end

	return maxSpeed
end

RegisterNetEvent("vehiclefailure:addedSpeedZone", function(zone)
    table.insert(SpeedZones, zone)
end)

RegisterNetEvent("vehiclefailure:receiveSpeedZones", function(zones)
    for i=1, #zones do
        table.insert(SpeedZones, zones[i])
    end
end)

TriggerServerEvent("vehiclefailure:getSpeedZones")

if cfg.torqueMultiplierEnabled or cfg.preventVehicleFlip or cfg.limpMode then
	local speed = nil
	local _speed = nil
	local count = 0
	local speedZoneSpeed = nil

	Citizen.CreateThread(function()
		local SetVehicleForwardSpeed, GetControlValue = SetVehicleForwardSpeed, GetControlValue
		local limpMode, sundayDriver, torqueMultiplierEnabled = cfg.limpMode, cfg.sundayDriver, cfg.torqueMultiplierEnabled
		while true do
			Citizen.Wait(0)
			xpcall(function()
				_speed = nil
				if torqueMultiplierEnabled or sundayDriver or limpMode then
					if pedInSameVehicleLast then
						local factor = 1.0
						if torqueMultiplierEnabled and healthEngineNew < 900 then
							factor = (healthEngineNew+100.0) / 1000
						end
						if sundayDriver and vehicleClass ~= 14 then -- Not for boats
							local accelerator = GetControlValue(2,71)
							local brake = GetControlValue(2,72)
							local forwardSpeed = GetEntitySpeedVector(currentVehicle, true)['y']
							-- Change Braking force
							fBrakeForce = fBrakeForce or 1.0
							local brk = fBrakeForce or 1.0
							if forwardSpeed >= 1.0 then
								-- Going forward
								isBrakingReverse = false
								if accelerator > 127 then
									-- Forward and accelerating
									local acc = fscale(accelerator, 127.0, 254.0, 0.1, 1.0, 10.0-(cfg.sundayDriverAcceleratorCurve*2.0))
									factor = factor * acc
								end
								if brake > 127 then
									-- Forward and braking
									isBrakingForward = true
									brk = fscale(brake, 127.0, 254.0, 0.01, fBrakeForce, 10.0-(cfg.sundayDriverBrakeCurve*2.0))
								else
									isBrakingForward = false
								end
							elseif forwardSpeed <= -1.0 then
								isBrakingForward = false
								-- Going reverse
								if brake > 127 then
									-- Reversing and accelerating (using the brake)
									local rev = fscale(brake, 127.0, 254.0, 0.1, 1.0, 10.0-(cfg.sundayDriverAcceleratorCurve*2.0))
									factor = factor * rev
								end
								if accelerator > 127 then
									-- Reversing and braking (Using the accelerator)
									isBrakingReverse = true
									brk = fscale(accelerator, 127.0, 254.0, 0.01, fBrakeForce, 10.0-(cfg.sundayDriverBrakeCurve*2.0))
								else
									isBrakingReverse = false
								end
							else
								-- Stopped or almost stopped or sliding sideways
								_speed = _speed or GetEntitySpeed(currentVehicle)
								local entitySpeed = _speed
								if entitySpeed < 1 then
									-- Not sliding sideways
									if isBrakingForward == true then
										--Stopped or going slightly forward while braking
										DisableControlAction(2, 72, true) -- Disable Brake until user lets go of brake
										SetVehicleForwardSpeed(currentVehicle, entitySpeed * 0.98)
										SetVehicleBrakeLights(currentVehicle, true)
									end
									if isBrakingReverse == true then
										--Stopped or going slightly in reverse while braking
										DisableControlAction(2,71,true) -- Disable reverse Brake until user lets go of reverse brake (Accelerator)
										SetVehicleForwardSpeed(currentVehicle, entitySpeed * 0.98)
										SetVehicleBrakeLights(currentVehicle, true)
									end
									if isBrakingForward == true and GetDisabledControlNormal(2,72) == 0 then
										-- We let go of the brake
										isBrakingForward = false
									end
									if isBrakingReverse == true and GetDisabledControlNormal(2,71) == 0 then
										-- We let go of the reverse brake (Accelerator)
										isBrakingReverse = false
									end
								end
							end
							if brk > (fBrakeForce or 1.0) - 0.02 then brk = fBrakeForce end -- Make sure we can brake max.
							--SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fBrakeForce', brk)  -- Set new Brake Force multiplier
						end
						count = count + 1
						if count > 5 then
							count = 0
							if vehicleClass ~= 14 and vehicleClass ~= 15 and vehicleClass ~= 16 and currentVehicle ~= nil then
								gripModifier = 1.0
								if debugMode then
									local fTractionMax = GetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fTractionCurveMax")
									local fTractionMin = GetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fTractionCurveMin")
									local fTractionLoss = GetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fTractionLossMult")
									drawInfo(("fTractionMax: %.2f: fTractionMin: %.2f; fTractionLoss: %.2f;"):format(fTractionMax, fTractionMin, fTractionLoss), -3)
								end
								local torqueModifier, modifier, maxSpeed, step, material, materialIndex, tractionLossExponent, stuck = getMaterialModifiersFromTyres()
								local grip = 1.0
								local actualMaxSpeed = -1
								if not stuck and isStuck then
									SetVehicleBurnout(currentVehicle, false)
									isStuck = false
								end
								if modifier and modifier > 0.0 and originalTractionLoss then
									local tractionLoss = math.max(originalTractionLoss, 0.2) ^ tractionLossExponent
									lastMaterial = materialIndex
									if torqueModifier then
										gripModifier = math.clamp((torqueModifier or 0.7) / tractionLoss, 0.2, 1.0)
									end
									if maxSpeed and maxSpeed < 10000 then
										_speed = _speed or GetEntitySpeed(currentVehicle)
										speed = _speed * kmMultiplier
										actualMaxSpeed = maxSpeed * (1 / tractionLoss)
										if step then
											step = getDeceleration(currentVehicle, step or 1.0)
											local delta = speed - actualMaxSpeed
											local speedVector = GetEntityVelocity(currentVehicle)
											local force = math.clamp(-100.0 * step * originalDrivingForce, -1000.0, 1000.0)
											-- Force of thousand is around 6 m/s
											-- 10 m/s is equal to 700.0 force
											local forceX = math.clamp(speedVector.x * force, -1000.0, 1000.0)
											local forceY = math.clamp(speedVector.y * force, -1000.0, 1000.0)
											local forceZ = math.clamp(speedVector.z * force, -1000.0, 1000.0)
											if debugMode then
												local frameTime = GetFrameTime()
												drawInfo(("step: %.5f; force: %.2f; forceX; %.2f; forceY: %.2f; forceZ: %.2f; speedVector.x: %.2f; speedVector.y: %.2f; speedVector.z: %.2f"):format(step / frameTime, force / frameTime, forceX / frameTime, forceY / frameTime, forceZ / frameTime, speedVector.x, speedVector.y, speedVector.z), -4)
											end
											ApplyForceToEntityCenterOfMass(currentVehicle, 0, forceX, forceY, forceZ, true, false, true, false)
										end
										if speed > actualMaxSpeed then
											if not isBrakingForward and not isBrakingReverse then
												local delta = speed - actualMaxSpeed
												drawInfo(("delta: %.2f"):format(delta), -5)
												gripModifier = math.clamp(gripModifier - delta / 10, 0.1, 1.0)
											end
										end
									elseif speed ~= nil then
										speed = nil
										ResetLimit(currentVehicle)
									end

									grip = 1.0 - (modifier or 0) * (originalTractionLoss or 1.0)

									if debugMode then
										drawInfo(("maxSpeed: %.2f: modifier: %.2f; torqueModifier: %.2f; tractionLoss: %.2f; gripModifier: %.2f; step: %.2f"):format(actualMaxSpeed, modifier or 0.0, torqueModifier, tractionLoss, gripModifier, step or -1.0), -2)
										print(("modifier: %s; torqueModifier: %.2f; material: %s; originalTractionLoss: %s; gripModifier: %.2f"):format(modifier, torqueModifier, material.name, originalTractionLoss, gripModifier))
									end

									if grip < 0.25 and stuck and GetEntitySpeed(currentVehicle) < 0.4 then
										SetVehicleBurnout(currentVehicle, true)
										isStuck = true
									end

									if isBrakingForward or isBrakingReverse then
										grip = math.clamp(grip, 0.20, 1.00)
									else
										grip = math.clamp(grip, 0.05, 1.00)
									end
								elseif lastMaterial ~= nil or speed ~= nil then
									grip = 1.0
									ResetLimit(currentVehicle)
									lastMaterial = nil
									speed = nil
								end

								local rainLevel = GetRainLevel()
								if rainLevel > 0 then
									local wheelType = GetVehicleWheelType(currentVehicle)
									if wheelType == 4 then
										grip = grip * 0.95
									else
										grip = grip * 0.9
									end
								end
								local snowModifier = -1
								if grip > 0.2 and currentWeather == 'XMAS' and GetSnowLevel() > 0.05 then
									snowModifier = getSnowModifier()
									if snowModifier and snowModifier > 0 then
										grip = grip * snowModifier
									end
								end
								drawInfo(("grip: %.2f; gripModifier: %.2f; snowModifier: %.2f"):format(grip, gripModifier, snowModifier), -6)
								ModifyGrip(currentVehicle, math.clamp(grip, 0.05, 1.00))
							end

							speedZoneSpeed = GetMaxSpeedForSpeedZone(GetEntityCoords(currentVehicle))
						end

						if speedZoneSpeed then
							_speed = _speed or GetEntitySpeed(currentVehicle)
							local speed = _speed * kmMultiplier
							if speed > speedZoneSpeed and not (isBrakingForward or isBrakingReverse) then
								factor = 0.0
							end
						end

						factor = factor * gripModifier
	
						if (limpMode or isPlayerWhiteListed) and healthEngineNew < cfg.engineSafeGuard + 50 and exports['esx_scorebord']:mechanic() <= 2 then
							if not LimpModeActive then
								healthEngineNew = 149.0
								healthEngineLast = 149.0
								SetVehicleEngineHealth(currentVehicle, healthEngineNew + 0.0)
								LimpModeActive = true
							end
							local modifier = math.clamp((healthEngineNew - (cfg.engineSafeGuard + 50)) / 50, 0.5, 1.0)
							factor = cfg.limpModeMultiplier * math.max(modifier, 0.4)
							local currentSpeed = GetEntitySpeed(currentVehicle)
							local maxSpeed = math.max(currentSpeed - 0.30, 6.0 * modifier)
							if currentSpeed > maxSpeed then
								factor = factor * 0.00
							end
						elseif LimpModeActive then
							LimpModeActive = false
							ResetLimit(currentVehicle)
						end
						--print(factor)
						if isStuck then
							ModifyTorque(currentVehicle, 1.0)
						else
							ModifyTorque(currentVehicle, factor)
						end
						
					end
				end
				if cfg.preventVehicleFlip then
					local roll = GetEntityRoll(currentVehicle)
					if vehicleClass ~= 8 and vehicleClass ~= 13 and vehicleClass ~= 15 and vehicleClass ~= 16 then
						if not IsVehicleOnAllWheels(currentVehicle) or vehicleClass == 14 then
							DisableControlAction(2,60,true) -- Disable up/down
						end
					end
					if (roll > 75.0 or roll < -75.0) and GetEntitySpeed(currentVehicle) < 2 then
						DisableControlAction(2,59,true) -- Disable left/right
					end
				end
			end, Traceback)
		end
	end)
end

if DevServer then
	RegisterCommand("debug_speedzones", function()
		for i=1, #SpeedZones do
			local data = SpeedZones[i]
			if DoesBlipExist(data.Blip) then
				RemoveBlip(data.Blip)
			end
			local blip = AddBlipForRadius(data.Coords.x, data.Coords.y, data.Coords.z, data.Radius + 0.0)
			SpeedZones[i].Blip = blip
			SetBlipHighDetail(blip, true)
			SetBlipColour(blip, 1)
			SetBlipAlpha(blip, 128)
		end
	end)
end

AddEventHandler('onClientResourceStop', function(resourceName)
	if resourceName == GetCurrentResourceName() then
		LeftVehicle(currentVehicle)
	end
end)

AddEventHandler('onResourceStop', function(resourceName)
	if resourceName == GetCurrentResourceName() then
		LeftVehicle(currentVehicle)
	end
end)

if DoesEntityExist(GetVehiclePedIsIn(PlayerPedId())) then
	EnteredVehicle(GetVehiclePedIsIn(PlayerPedId()))
end

function GetPlateSecure(vehicle)
	local plate = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle))
	if not plate then
		local timeout = 0
		while not plate and timeout < 1000 do
			plate = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle))
			timeout = timeout + 100
			Citizen.Wait(100)
		end
	end

	return plate
end

AddEventHandler('setEngineHealth', function(health, vehicle)
	if not health then
		return
	end
	if not vehicle then
		error("No entity given on setEngineHealth!")
	end
	if not DoesEntityExist(vehicle) then
		error("Entity given on setEngineHealth doesn't exist!")
	end
	health = health + 0.0
	local plate = GetPlateSecure(vehicle)
	if plate then
		exports['esx_jb_eden_garage2']:changeData(plate, "engineHealth", health)
	end
	SetVehicleEngineHealth(vehicle, health + 0.0)
	if vehicle == currentVehicle then
		healthEngineNew = health
		healthEngineCurrent = health
		healthEngineLast = health
		healthEngineDelta = 0
	end
	Citizen.Wait(0)
	SetVehicleEngineHealth(vehicle, health + 0.0)
	if vehicle == currentVehicle then
		healthEngineNew = health
		healthEngineCurrent = health
		healthEngineLast = health
		healthEngineDelta = 0
	end
end)

AddEventHandler('setBodyHealth', function(health, vehicle)
	if not health then
		return
	end
	if not vehicle then
		error("No entity given on setBodyHealth!")
	end
	if not DoesEntityExist(vehicle) then
		error("Entity given on setBodyHealth doesn't exist!")
	end
	health = health + 0.0
	local plate = GetPlateSecure(vehicle)
	if plate then
		exports['esx_jb_eden_garage2']:changeData(plate, "bodyHealth", health)
	end
	SetVehicleBodyHealth(vehicle, health + 0.0)
	if vehicle == currentVehicle then
		healthBodyCurrent = health
		healthBodyLast = health
		healthBodyNew = health
		healthBodyDelta = 0
	end
	Citizen.Wait(0)
	SetVehicleBodyHealth(vehicle, health + 0.0)
	if vehicle == currentVehicle then
		healthBodyCurrent = health
		healthBodyLast = health
		healthBodyNew = health
		healthBodyDelta = 0
	end
end)

RegisterCommand("get_rpm", function()
	print("Current RPM is: " .. tostring(GetVehicleCurrentRpm(currentVehicle)))
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(50)
		local ped = PlayerPedId()
		if isPedDrivingAVehicle() and DoesEntityExist(currentVehicle) then
			vehicleClass = GetVehicleClass(currentVehicle)
			vehicleModel = cfg.modelDamageMultiplier[GetEntityModel(currentVehicle)] or 1.0
			healthEngineCurrent = GetVehicleEngineHealth(currentVehicle)
			if healthEngineCurrent == 1000 then
				healthEngineLast = 1000.0
			end
			healthEngineNew = healthEngineCurrent
			healthEngineDelta = healthEngineLast - healthEngineCurrent
			healthEngineDeltaScaled = healthEngineDelta * cfg.damageFactorEngine * cfg.classDamageMultiplier[vehicleClass] * (vehicleModel or 1.0)

			healthBodyCurrent = GetVehicleBodyHealth(currentVehicle)
			if healthBodyCurrent == 1000 then healthBodyLast = 1000.0 end
			healthBodyNew = healthBodyCurrent
			healthBodyDelta = healthBodyLast - healthBodyCurrent
			healthBodyDeltaScaled = healthBodyDelta * cfg.damageFactorBody * cfg.classDamageMultiplier[vehicleClass] * (vehicleModel or 1.0)

			healthPetrolTankCurrent = GetVehiclePetrolTankHealth(currentVehicle)
			if cfg.compatibilityMode and healthPetrolTankCurrent < 1 then
				--	SetVehiclePetrolTankHealth(vehicle, healthPetrolTankLast)
				--	healthPetrolTankCurrent = healthPetrolTankLast
				healthPetrolTankLast = healthPetrolTankCurrent
			end
			if healthPetrolTankCurrent == 1000 then healthPetrolTankLast = 1000.0 end
			healthPetrolTankNew = healthPetrolTankCurrent
			healthPetrolTankDelta = healthPetrolTankLast-healthPetrolTankCurrent
			healthPetrolTankDeltaScaled = healthPetrolTankDelta * cfg.damageFactorPetrolTank * cfg.classDamageMultiplier[vehicleClass] * (vehicleModel or 1.0)

			if healthEngineCurrent > cfg.engineSafeGuard+1 or isPlayerWhiteListed then
				SetVehicleUndriveable(currentVehicle,false)
			end

			if healthEngineCurrent <= cfg.engineSafeGuard+1 and (cfg.limpMode == false or exports['esx_scorebord']:mechanic() > 0) and not isPlayerWhiteListed then
				SetVehicleUndriveable(currentVehicle,true)
			end

			-- If ped spawned a new vehicle while in a vehicle or teleported from one vehicle to another, handle as if we just entered the car
			if currentVehicle ~= lastVehicle then
				pedInSameVehicleLast = false
			end


			if pedInSameVehicleLast == true then
				-- Damage happened while in the car = can be multiplied

				-- Only do calculations if any damage is present on the car. Prevents weird behavior when fixing using trainer or other script
				if healthEngineCurrent ~= 1000.0 or healthBodyCurrent ~= 1000.0 or healthPetrolTankCurrent ~= 1000.0 then

					-- Combine the delta values (Get the largest of the three)
					local healthEngineCombinedDelta = math.max(healthEngineDeltaScaled, healthBodyDeltaScaled, healthPetrolTankDeltaScaled)

					-- If huge damage, scale back a bit
					if healthEngineCombinedDelta > (healthEngineCurrent - cfg.engineSafeGuard) then
						healthEngineCombinedDelta = healthEngineCombinedDelta * 0.9
					end

					-- If complete damage, but not catastrophic (ie. explosion territory) pull back a bit, to give a couple of seconds og engine runtime before dying
					if healthEngineCombinedDelta > healthEngineCurrent then
						healthEngineCombinedDelta = healthEngineCurrent - (cfg.cascadingFailureThreshold / 10)
					end


					------- Calculate new value

					healthEngineNew = healthEngineLast - healthEngineCombinedDelta


					------- Sanity Check on new values and further manipulations

					-- If somewhat damaged, slowly degrade until slightly before cascading failure sets in, then stop

					if healthEngineNew < cfg.degradingFailureThreshold and GetIsVehicleEngineRunning(currentVehicle) then
						local currentRpm = math.clamp(GetVehicleCurrentRpm(currentVehicle), 0.1, 1.0)
						local speed = math.clamp(GetEntitySpeed(currentVehicle) / 40.0, 0.0, 1.0)
						local modifier = math.clamp(currentRpm + speed, 0.1, 2.0) ^ 2.0
						if healthEngineNew >= cfg.cascadingFailureThreshold and healthEngineNew < cfg.degradingFailureThreshold then
							healthEngineNew = healthEngineNew - (0.038 * cfg.degradingHealthSpeedFactor * modifier)
						end

						-- If Damage is near catastrophic, cascade the failure
						if healthEngineNew < cfg.cascadingFailureThreshold and healthEngineNew > cfg.engineSafeGuard + 50 then
							healthEngineNew = healthEngineNew - (0.1 * cfg.cascadingFailureSpeedFactor * modifier)
						end
					end

					-- Prevent Engine going to or below zero. Ensures you can reenter a damaged car.
					if healthEngineNew < cfg.engineSafeGuard then
						healthEngineNew = cfg.engineSafeGuard
					end

					-- Prevent Explosions
					if cfg.compatibilityMode == false and healthPetrolTankCurrent < 750 then
						healthPetrolTankNew = 750.0
					end

					-- Prevent negative body damage.
					if healthBodyNew < 0  then
						healthBodyNew = 0.0
					end
				end
			else
				-- Just got in the vehicle. Damage can not be multiplied this round
				-- Set vehicle handling data
				fDeformationDamageMult = GetVehicleHandlingFloat(currentVehicle, 'CHandlingData', 'fDeformationDamageMult')
				fBrakeForce = GetVehicleHandlingFloat(currentVehicle, 'CHandlingData', 'fBrakeForce') or 1.0
				local newFDeformationDamageMult = fDeformationDamageMult ^ cfg.deformationExponent	-- Pull the handling file value closer to 1
				if cfg.deformationMultiplier ~= -1 then
					SetVehicleHandlingFloat(currentVehicle, 'CHandlingData', 'fDeformationDamageMult', newFDeformationDamageMult * cfg.deformationMultiplier)
				end  -- Multiply by our factor
				if cfg.weaponsDamageMultiplier ~= -1 then
					SetVehicleHandlingFloat(currentVehicle, 'CHandlingData', 'fWeaponDamageMult', cfg.weaponsDamageMultiplier/cfg.damageFactorBody)
				end -- Set weaponsDamageMultiplier and compensate for damageFactorBody

				--Get the CollisionDamageMultiplier
				fCollisionDamageMult = GetVehicleHandlingFloat(currentVehicle, 'CHandlingData', 'fCollisionDamageMult')
				--Modify it by pulling all number a towards 1.0
				local newFCollisionDamageMultiplier = fCollisionDamageMult ^ cfg.collisionDamageExponent	-- Pull the handling file value closer to 1
				SetVehicleHandlingFloat(currentVehicle, 'CHandlingData', 'fCollisionDamageMult', newFCollisionDamageMultiplier)

				--Get the EngineDamageMultiplier
				fEngineDamageMult = GetVehicleHandlingFloat(currentVehicle, 'CHandlingData', 'fEngineDamageMult')
				--Modify it by pulling all number a towards 1.0
				local newFEngineDamageMult = fEngineDamageMult ^ cfg.engineDamageExponent	-- Pull the handling file value closer to 1
				SetVehicleHandlingFloat(currentVehicle, 'CHandlingData', 'fEngineDamageMult', newFEngineDamageMult)

				-- If body damage catastrophic, reset somewhat so we can get new damage to multiply
				if healthBodyCurrent < cfg.cascadingFailureThreshold and healthBodyNew > cfg.engineSafeGuard + 50 then
					healthBodyNew = cfg.cascadingFailureThreshold
				end
				pedInSameVehicleLast = true
				-- Give other threads some time to catch up
				Citizen.Wait(100)
			end

			-- set the actual new values
			if math.abs(healthEngineNew - healthEngineCurrent) > 0.01 then
				SetVehicleEngineHealth(currentVehicle, healthEngineNew + 0.0)
			end
			if math.abs(healthBodyNew - healthBodyCurrent) > 0.01  then
				SetVehicleBodyHealth(currentVehicle, healthBodyNew + 0.0)
			end
			if math.abs(healthPetrolTankNew - healthPetrolTankCurrent) > 0.01 then
				SetVehiclePetrolTankHealth(currentVehicle, healthPetrolTankNew + 0.0)
			end

			-- Store current values, so we can calculate delta next time around
			healthEngineLast = healthEngineNew
			healthBodyLast = healthBodyNew
			healthPetrolTankLast = healthPetrolTankNew
			lastVehicle = currentVehicle
			--if cfg.randomTireBurstInterval ~= 0 and GetEntitySpeed(vehicle) > 25 then tireBurstLottery() end
		else
			if pedInSameVehicleLast == true then
				-- We just got out of the vehicle
				lastVehicle = GetVehiclePedIsIn(ped, true)
				if DoesEntityExist(lastVehicle) then
					if cfg.deformationMultiplier ~= -1 then
						SetVehicleHandlingFloat(lastVehicle, 'CHandlingData', 'fDeformationDamageMult', fDeformationDamageMult)
					end -- Restore deformation multiplier

					if cfg.weaponsDamageMultiplier ~= -1 then
						SetVehicleHandlingFloat(lastVehicle, 'CHandlingData', 'fWeaponDamageMult', cfg.weaponsDamageMultiplier)
					end	-- Since we are out of the vehicle, we should no longer compensate for bodyDamageFactor

					SetVehicleHandlingFloat(lastVehicle, 'CHandlingData', 'fCollisionDamageMult', fCollisionDamageMult) -- Restore the original CollisionDamageMultiplier
					SetVehicleHandlingFloat(lastVehicle, 'CHandlingData', 'fEngineDamageMult', fEngineDamageMult) -- Restore the original EngineDamageMultiplier
				end
			end
			numWheels = 0
			currentVehicle = nil
			pedInSameVehicleLast = false
		end
	end
end)

function TrySetVehicleHandlingFloat(vehicle, class, fieldName, value)
	if not value or value < 0.01 then
		TriggerServerEvent("SentryIO:Error", "Value was too low", ("^1ERROR: ^7Value %s was %s"):format(fieldName, value) .. debug.traceback(), GetCurrentResourceName(), { model = GetEntityModel(vehicle) })
		print(("^1Err: ^7Value %s was %s"):format(fieldName, value))
		return
	end

	xpcall(SetVehicleHandlingFloat, Traceback, vehicle, class, fieldName, value)
end

Citizen.SetTimeout(1000, tireBurstLottery)

-- Mechanic Code

RegisterNetEvent("knb:mech")
AddEventHandler("knb:mech", function()
	local player = PlayerPedId()
	local playerPos = GetEntityCoords(player)

	local inFrontOfPlayer = GetOffsetFromEntityInWorldCoords(player, 0.0, 5.0, 0.0)

	local targetVeh = GetTargetVehicle(player, inFrontOfPlayer)

	if not IsVehicleDamaged(targetVeh) and GetVehicleBodyHealth(targetVeh) > 950 and GetVehicleEngineHealth(targetVeh) > 950 then
		ShowNotification("Voertuig hoeft niet gerepareerd te worden!")
		return
	end

	GetMechPed()

	local driverhash = GetHashKey(mechPedPick.model)
	RequestModel(driverhash)
	local vehhash = GetHashKey(mechPedPick.vehicle)
	RequestModel(vehhash)

	loadAnimDict("cellphone@")

	while not HasModelLoaded(driverhash) and RequestModel(driverhash) or not HasModelLoaded(vehhash) and RequestModel(vehhash) do
		RequestModel(driverhash)
		RequestModel(vehhash)
		Citizen.Wait(0)
	end

	if DoesEntityExist(targetVeh) then
		SetVehicleUndriveable(targetVeh, true)
		SetVehicleEngineOn(targetVeh, false, true, true)
		if DoesEntityExist(mechVeh) then
			ESX.Game.TryDeleteAny(mechVeh)
			ESX.Game.TryDeleteAny(mechPed, DeletePed)
			SpawnVehicle(playerPos.x, playerPos.y, playerPos.x, vehhash, driverhash)
		else
			SpawnVehicle(playerPos.x, playerPos.y, playerPos.x, vehhash, driverhash)
		end
		playRadioAnim(player)
		local vehCoords = GetEntityCoords(targetVeh)
		GoToTarget(vehCoords.x, vehCoords.y, vehCoords.z, mechVeh, mechPed, vehhash, targetVeh)
	end
end)

function SpawnVehicle(x, y, z, vehhash, driverhash)                                                     --Spawning Function
	local found, spawnPos, spawnHeading = GetClosestVehicleNodeWithHeading(x + math.random(-spawnRadius, spawnRadius), y + math.random(-spawnRadius, spawnRadius), z, 0, 3, 0)

	local time = 0
	while CalculateTravelDistanceBetweenPoints(spawnPos, x, y, z) > spawnRadius * 2 and time < 1000 do
		print(CalculateTravelDistanceBetweenPoints(spawnPos, x, y, z))
		Citizen.Wait(100)
		time = time + 100
		found, spawnPos, spawnHeading = GetClosestVehicleNodeWithHeading(x + math.random(-spawnRadius, spawnRadius), y + math.random(-spawnRadius, spawnRadius), z, 0, 3, 0)
	end

	if found and HasModelLoaded(vehhash) and HasModelLoaded(vehhash) then
		mechVeh = CreateVehicle(vehhash, spawnPos, spawnHeading, true, false)                           --Car Spawning.
		mechNetVeh = VehToNet(mechVeh)
		ClearAreaOfVehicles(GetEntityCoords(mechVeh), 5000, false, false, false, false, false);
		SetVehicleOnGroundProperly(mechVeh)
		SetVehicleColours(mechVeh, mechPedPick.colour, mechPedPick.colour)

		mechPed = CreatePedInsideVehicle(mechVeh, 26, driverhash, -1, true, false)              		--Driver Spawning.
		mechNetPed = PedToNet(mechPed)
		SetBlockingOfNonTemporaryEvents(mechPed, true)
		SetEntityInvincible(mechPed, true)
		local netid = PedToNet(mechPed)
		SetNetworkIdExistsOnAllMachines(netid, true)
		NetworkSetNetworkIdDynamic(netid, true)
		SetNetworkIdCanMigrate(netid, false)
		local netid = VehToNet(mechVeh)
		SetNetworkIdExistsOnAllMachines(netid, true)
		NetworkSetNetworkIdDynamic(netid, true)
		SetNetworkIdCanMigrate(netid, false)
		DecorSetBool(mechPed, "spawnedNPC", true)
		mechBlip = AddBlipForEntity(mechVeh)                                                        	--Blip Spawning.
		SetBlipFlashes(mechBlip, true)
		SetBlipColour(mechBlip, 5)
	end
	SetModelAsNoLongerNeeded(driverhash)
	SetModelAsNoLongerNeeded(vehhash)
end

function DeleteVeh(vehicle, driver)
	NetworkRequestControlOfEntity(vehicle)
	NetworkRequestControlOfEntity(driver)
	local start = GetGameTimer()
	while (not NetworkHasControlOfEntity(vehicle) or NetworkHasControlOfEntity(driver)) and GetGameTimer() - start < 5000 do
		Citizen.Wait(100)
		NetworkRequestControlOfEntity(vehicle)
		NetworkRequestControlOfEntity(driver)
	end
	SetEntityAsMissionEntity(vehicle, false, true)                                            			--Car Removal
	DeleteEntity(vehicle)
	SetEntityAsMissionEntity(driver, false, true)                                              		--Driver Removal
	DeleteEntity(driver)
	RemoveBlip(mechBlip)                                                                    			--Blip Removal
	if DoesEntityExist(vehicle) then
		NetworkRequestControlOfEntity(vehicle)
		SetEntityAsNoLongerNeeded(vehicle)
		SetEntityCoords(vehicle, 10000, 10000, -100, nil, nil, nil, true)
	end
	if DoesEntityExist(driver) then
		NetworkRequestControlOfEntity(driver)
		SetEntityAsNoLongerNeeded(driver)
		SetEntityCoords(driver, 10000, 10000, -100, nil, nil, nil, true)
	end
end

function GoToTarget(x, y, z, vehicle, driver, vehhash, target)
	TaskVehicleDriveToCoord(driver, vehicle, x, y, z, 17.0, 0, vehhash, drivingStyle, 1, true)
	ShowAdvancedNotification(companyIcon, companyName, "ANWB'er onderweg", "Er is een ANWB'er naar uw locatie onderweg. Bedankt voor het gebruik maken van onze diensten.")
	enroute = true
	while enroute do
		Citizen.Wait(500)
		distanceToTarget = #(GetEntityCoords(target).xy - GetEntityCoords(vehicle).xy)
		if simplerRepair then
			if distanceToTarget < 20 then
				TaskVehicleTempAction(driver, vehicle, 27, 6000)
				Citizen.Wait(3000)
				RepairVehicle(target, vehicle, driver)
			end
		else
			if distanceToTarget < 20 then
				TaskVehicleTempAction(driver, vehicle, 27, 6000)
				SetVehicleUndriveable(vehicle, true)
				GoToTargetWalking(target, vehicle, driver)
			end
		end
	end
end

function GoToTargetWalking(target, vehicle, driver)
	local startTime = GetGameTimer() + 20000
	local networkControl = GetGameTimer()
	NetworkRequestControlOfEntity(driver)
	while not NetworkHasControlOfEntity(driver) do
		NetworkRequestControlOfEntity(driver)
		Citizen.Wait(100)
	end
	while enroute do
		Citizen.Wait(500)
		engine = GetWorldPositionOfEntityBone(target, GetEntityBoneIndexByName(target, "engine"))
		TaskGoToCoordAnyMeans(driver, engine, 2.0, 0, 0, 786603, 0xbf800000)
		distanceToTarget = #(engine - GetEntityCoords(driver))
		norunrange = false
		if distanceToTarget <= 10 and not norunrange then -- stops ai from sprinting when close
			TaskGoToCoordAnyMeans(driver, engine, 1.0, 0, 0, 786603, 0xbf800000)
			norunrange = true
			startTime = GetGameTimer()
		end
		if distanceToTarget <= 2 or GetGameTimer() - startTime > 7500 then
			SetVehicleUndriveable(target, true)
			TaskTurnPedToFaceCoord(driver, GetEntityCoords(target), -1)
			Citizen.Wait(1000)
			TaskStartScenarioInPlace(driver, "PROP_HUMAN_BUM_BIN", 0, 1)
			SetVehicleDoorOpen(target, 4, false, false)
			Citizen.Wait(10000)
			ClearPedTasks(driver)
			RepairVehicle(target, vehicle, driver)
		end
	end
end

function RepairVehicle(target, vehicle, driver)
	enroute = false
	norunrange = false
	FreezeEntityPosition(driver, false)
	SetVehicleDoorShut(target, 4, false, false)
	Citizen.Wait(500)
	local health = math.max(GetVehicleBodyHealth(target), GetVehicleEngineHealth(target))
	local health = ((GetVehicleEngineHealth(target) * 1.0) + (GetVehicleBodyHealth(target) * 1.0)) / 2
	local price = math.max(math.floor((900-health) * 3), 100)
	ShowAdvancedNotification(mechPedPick.icon, mechPedPick.name, "Vehicle Repaired" , mechPedPick.lines[math.random(#mechPedPick.lines)] .. "\nDat wordt dan €" .. price .. ",-")
	TriggerServerEvent('iens:pay', price)
	if repairComsticDamage then
		TriggerServerEvent('eden_garage:repairVehicle', ESX.Math.Trim(GetVehicleNumberPlateText(target)))
		SetVehicleEngineHealth(target, 1000.0)
		SetVehicleBodyHealth(target, 1000.0)
		SetVehicleDeformationFixed(target)
		SetVehicleFixed(target)
		SetVehicleUndriveable(target, false)
		SetVehicleEngineOn(target, true, true)
		if NetworkGetEntityIsNetworked(target) then
			TriggerServerEvent('esx_mechanicjob:fixVehicle', NetworkGetNetworkIdFromEntity(target))
		end
		TriggerEvent('CruiseControl:SetLimiter', target)
	else
		SetVehicleEngineHealth(target, 1000.0)
		TriggerEvent('CruiseControl:SetLimiter', target)
	end
	if flipVehicle then
		local roll = GetEntityRoll(target)
		if (roll > 40.0 or roll < -40.0) and GetEntitySpeed(target) < 2 then
			DisableControlAction(2,59,true) -- Disable left/right
			DisableControlAction(2,60,true) -- Disable up/down
			SetVehicleOnGroundProperly(target)
		end
	end
	TriggerServerEvent('eden_garage:repairVehicle', ESX.Math.Trim(GetVehicleNumberPlateText(target)))
	TriggerServerEvent('vehiclefailure:repairDone')
	SetVehicleUndriveable(target, false)
	Citizen.Wait(5000)
	TriggerEvent('CruiseControl:SetLimiter', target)
	LeaveTarget(vehicle, driver)
end

function LeaveTarget(vehicle, driver)
	TaskVehicleDriveWander(driver, vehicle, 17.0, drivingStyle)
	SetEntityAsNoLongerNeeded(vehicle)
	SetEntityAsNoLongerNeeded(driver)
	SetEntityInvincible(mechPed, false)
	RemoveBlip(mechBlip)
	TriggerServerEvent("vehiclefailure:removeped", NetworkGetNetworkIdFromEntity(vehicle), NetworkGetNetworkIdFromEntity(driver))
	local _vehicle = mechVeh
	local _ped = mechPed
	SetTimeout(30000, function()
		ESX.Game.TryDeleteAny(_vehicle)
		ESX.Game.TryDeleteAny(_ped, DeletePed)
		mechVeh = nil
		mechPed = nil
	end)
	targetVeh = nil
end

function GetTargetVehicle(player, dir)
	if IsPedSittingInAnyVehicle(player) then
		dmgVeh = GetVehiclePedIsIn(player, false)
	else
		local returnVeh, distance = ESX.Game.GetClosestVehicle(GetEntityCoords(player))
		if distance < 5.0 then
			dmgVeh = returnVeh
		else
			dmgVeh = 0
		end
	end

	if DoesEntityExist(dmgVeh) then
		return dmgVeh
	else
		ShowNotification("Failed to find a vehicle.")
	end
end

function GetMechPed()
	mechPedPick = mechPeds[math.random(#mechPeds)]
end

function GetVehicleInDirection(coordFrom, coordTo)
	local rayHandle = CastRayPointToPoint( coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10, PlayerPedId(), 0)
	local _, _, _, _, vehicle = GetRaycastResult(rayHandle)
	return vehicle
end

RegisterNetEvent("vehiclefailure:removeped")
AddEventHandler("vehiclefailure:removeped", function(netId)
	if not netId then
		return
	end

	local entity = NetworkGetEntityFromNetworkId(netId)
	ESX.Game.TryDeleteAny(entity, DeletePed)
end)

RegisterNetEvent("vehiclefailure:removevehicle")
AddEventHandler("vehiclefailure:removevehicle", function(netId)
	if not netId then
		return
	end

	local entity = NetworkGetEntityFromNetworkId(netId)
	ESX.Game.TryDeleteAny(entity)
end)

function playRadioAnim(player)
	Citizen.CreateThread(function()
		RequestAnimDict("cellphone@")
		TaskPlayAnim(player, "cellphone@", "cellphone_call_in", 1.5, 2.0, -1, 50, 2.0, 0, 0, 0 )
		RemoveAnimDict("cellphone@")
		Citizen.Wait(6000)
		ClearPedTasks(player)
	end)
end

function loadAnimDict(dict)
	while (not HasAnimDictLoaded(dict)) do
		RequestAnimDict(dict)
		Citizen.Wait(0)
	end
end

function ShowAdvancedNotification(icon, sender, title, text)
	SetNotificationTextEntry("STRING")
	AddTextComponentString(text)
	SetNotificationMessage(icon, icon, true, 4, sender, title, text)
	DrawNotification(false, true)
end

function ShowNotification(text)
	SetNotificationTextEntry("STRING")
	AddTextComponentString(text)
	DrawNotification(false, false)
end

if false then
	---@class GripData
	---@field torqueModifier number Higher values means more torque/power on this material, 1.0 is default
	---@field modifier number Lower values means more grip, 0.0 is default
	---@field hash string The hash of this material
	---@field name string The name of this material
	---@field index integer The material index of this material (get auto generated so no use in adding this manually)
	---@field stuck boolean Whether this material should make a vehicle get stuck if the grip and speed are too low
	---@field maxSpeed number The maximum speed (in km/h) on this material, this gets modified by the modifier
	---@field tractionLossExponent number The traction loss is raised to the power of this, defaults to defaultExponent
	local gripData
end

materials = {
	[ 0] = { name = "default", hash = "1" },
	[ 1] = { name = "concrete", hash = "1187676648" },
	[ 2] = { name = "concrete_pothole", modifier = 0.10, hash = "359120722" },
	[ 3] = { name = "concrete_dusty", hash = "-1084640111" },
	[ 4] = { name = "tarmac", hash = "282940568" },
	[ 5] = { name = "tarmac_painted", hash = "-1301352528", modifier = 0.10 },
	[ 6] = { name = "tarmac_pothole", modifier = 0.10, hash = "1886546517" },
	[ 7] = { name = "rumble_strip", modifier = 0.08, hash = "-250168275" },
	[ 8] = { name = "breeze_block", hash = "-954112554" },
	[ 9] = { name = "rock", hash = "-840216541" },
	[10] = { name = "rock_mossy", modifier = 0.20, hash = "-124769592" },
	[11] = { name = "stone", hash = "765206029" },
	[12] = { name = "cobblestone", hash = "576169331" },
	[13] = { name = "brick", hash = "1639053622" },
	[14] = { name = "marble", modifier = 0.10, hash = "1945073303" },
	[15] = { name = "paving_slab", hash = "1907048430" },
	[16] = { name = "sandstone_solid", hash = "592446772" },
	[17] = { name = "sandstone_brittle", hash = "1913209870" },
	[18] = { name = "sand_loose", torqueModifier = 0.40, modifier = 0.65, hash = "-1595148316", step = 1.5, maxSpeed = 60.0, stuck = true },
	[19] = { name = "sand_compact", torqueModifier = 0.50, modifier = 0.45, hash = "510490462", step = 1.5, maxSpeed = 85.0, stuck = true },
	[20] = { name = "sand_wet", torqueModifier = 0.35, modifier = 0.70, hash = "909950165", step = 1.5, maxSpeed = 80.0, stuck = true },
	[21] = { name = "sand_track", torqueModifier = 0.40, modifier = 0.5, hash = "-1907520769", maxSpeed = 80.0 },
	[22] = { name = "sand_underwater", torqueModifier = 0.40, modifier = 0.5, hash = "-1136057692", maxSpeed = 80.0, stuck = true },
	[23] = { name = "sand_dry_deep", torqueModifier = 0.40, modifier = 0.60, hash = "509508168", maxSpeed = 80.0 },
	[24] = { name = "sand_wet_deep", torqueModifier = 0.40, modifier = 0.60, hash = "1288448767", maxSpeed = 60.0, stuck = true },
	[25] = { name = "ice", modifier = 0.55, hash = "-786060715" },
	[26] = { name = "ice_tarmac", modifier = 0.35, hash = "-1931024423" },
	[27] = { name = "snow_loose", modifier = 0.5, hash = "-1937569590" },
	[28] = { name = "snow_compact", modifier = 0.60, hash = "-878560889" },
	[29] = { name = "snow_deep", modifier = 0.5, hash = "1619704960" },
	[30] = { name = "snow_tarmac", modifier = 0.10, hash = "1550304810" },
	[31] = { name = "gravel_small", maxSpeed = 70.0, modifier = 0.5, hash = "951832588", step = 7.0, torqueModifier = 0.40, tractionLossExponent = 0.5, stuck = true },
	[32] = { name = "gravel_large", maxSpeed = 70.0, modifier = 0.40, hash = "2128369009", step = 8.0, torqueModifier = 0.40, tractionLossExponent = 0.5, stuck = true },
	[33] = { name = "gravel_deep", maxSpeed = 60.0, modifier = 0.5, hash = "-356706482", step = 7.0, torqueModifier = 0.40, tractionLossExponent = 0.5, stuck = true },
	[34] = { name = "gravel_train_track", maxSpeed = 70.0, modifier = 0.5, hash = "1925605558", step = 6.0, torqueModifier = 0.40, tractionLossExponent = 0.5, stuck = true },
	[35] = { name = "dirt_track", torqueModifier = 0.55, modifier = 0.40, maxSpeed = 85.0, hash = "-1885547121", step = 0.5 },
	[36] = { name = "mud_hard", maxSpeed = 80.0, torqueModifier = 0.3, modifier = 0.6, hash = "-1942898710", step = 3.0 },
	[37] = { name = "mud_pothole", maxSpeed = 80.0, torqueModifier = 0.3, modifier = 0.10, hash = "312396330", step = 3.0 },
	[38] = { name = "mud_soft", maxSpeed = 60.0, torqueModifier = 0.3, modifier = 0.6, hash = "1635937914", step = 3.0, stuck = true },
	[39] = { name = "mud_underwater", maxSpeed = 60.0, torqueModifier = 0.3, modifier = 0.6, hash = "-273490167", step = 3.0, stuck = true },
	[40] = { name = "mud_deep", torqueModifier = 0.2, modifier = 0.6, maxSpeed = 40.0, hash = "1109728704", step = 3.0, stuck = true },
	[41] = { name = "marsh", torqueModifier = 0.4, modifier = 0.5, hash = "223086562", step = 3.0, stuck = true },
	[42] = { name = "marsh_deep", torqueModifier = 0.2, modifier = 0.5, maxSpeed = 40.0, hash = "1584636462", step = 3.0, stuck = true },
	[43] = { name = "soil", modifier = 0.5, hash = "-700658213" },
	[44] = { name = "clay_hard", torqueModifier = 0.4, modifier = 0.5, hash = "1144315879", step = 0.5 },
	[45] = { name = "clay_soft", torqueModifier = 0.4, modifier = 0.5, hash = "560985072", step = 0.5 },
	[46] = { name = "grass_long", maxSpeed = 60.0, modifier = 0.60, hash = "-461750719", torqueModifier = 0.35, step = 1.0 },
	[47] = { name = "grass", maxSpeed = 90.0, modifier = 0.50, hash = "1333033863", torqueModifier = 0.35, step = 1.00 },
	[48] = { name = "grass_short", maxSpeed = 90.0, modifier = 0.60, hash = "-1286696947", torqueModifier = 0.35, step = 1.00 },
	[49] = { name = "hay", hash = "-1833527165" },
	[50] = { name = "bushes", hash = "581794674", maxSpeed = 60.0, modifier = 0.60, torqueModifier = 0.35, step = 1.0 },
	[51] = { name = "twigs", hash = "-913351839" },
	[52] = { name = "leaves", hash = "-2041329971", maxSpeed = 60.0, modifier = 0.60, torqueModifier = 0.35, step = 1.0 },
	[53] = { name = "woodchips", hash = "-309121453", maxSpeed = 60.0, modifier = 0.60, torqueModifier = 0.35, step = 1.0 },
	[54] = { name = "tree_bark", hash = "-1915425863" },
	[55] = { name = "metal_solid_small", hash = "-1447280105" },
	[56] = { name = "metal_solid_medium", hash = "-365631240" },
	[57] = { name = "metal_solid_large", hash = "752131025" },
	[58] = { name = "metal_hollow_small", hash = "15972667" },
	[59] = { name = "metal_hollow_medium", hash = "1849540536" },
	[60] = { name = "metal_hollow_large", hash = "-583213831" },
	[61] = { name = "metal_chainlink_small", hash = "762193613" },
	[62] = { name = "metal_chainlink_large", hash = "125958708" },
	[63] = { name = "metal_corrugated_iron", hash = "834144982" },
	[64] = { name = "metal_grille", modifier = 0.10, hash = "-426118011" },
	[65] = { name = "metal_railing", hash = "2100727187" },
	[66] = { name = "metal_duct", hash = "1761524221" },
	[67] = { name = "metal_garage_door", hash = "-231260695" },
	[68] = { name = "metal_manhole", hash = "-754997699", fallOffBike = true },
	[69] = { name = "wood_solid_small", modifier = 0.20, hash = "-399872228" },
	[70] = { name = "wood_solid_medium", modifier = 0.20, hash = "555004797" },
}

for k,v in pairs(materials) do
	v.index = k
end

RegisterCommand("unstuck", function()
	local vehicle = GetVehiclePedIsIn(PlayerPedId())
	if not IsThisModelABoat(GetEntityModel(vehicle)) then
		ESX.ShowNotification("~r~Dit command werkt alleen voor boten!~s~")
		return
	end

	local money = ESX.GetAccount("bank").money

	if money < 1000 then
		ESX.ShowNotification("~r~Je hebt niet genoeg geld hiervoor!~s~")
		return
	end
end)

RegisterNetEvent("vehiclefailure:unstuck", function()
	local vehicle = GetVehiclePedIsIn(PlayerPedId())

	local coords = GetEntityCoords(vehicle)

	local found, position = GetClosestVehicleNode(coords.x, coords.y, coords.z, 3)

	print(found, position, #(coords - position))

	SetEntityCoords(vehicle, position)
end)

local maxspeedstaff = 999
local maxspeed = 6 -- 30 kilometer per uur
local running = false
local staff = false

RegisterNetEvent('sts:fixvehicle')
AddEventHandler('sts:fixvehicle', function(radius)
    local playerPed = GetPlayerPed(-1)
    local playerPedID = PlayerPedId()
    local car = GetVehiclePedIsIn(playerPed, false)
    local speed = GetEntitySpeed(car)
    local x,y,z = table.unpack(GetEntityCoords(playerPed,true))
    vehicle = GetClosestVehicle(x, y, z, 15.0, 0, 70)
	delay = 0
	if delay == 0 then
        if exports['sts_discordperms']:hasingamemodgroup() == true or exports['sts_discordperms']:hasingameadmingroup() == true or exports['sts_discordperms']:hasingamesuperadmingroup() == true then
            if IsPedInAnyVehicle(playerPed, false) then
                if speed < maxspeedstaff then
                    local vehicle = GetVehiclePedIsIn(playerPed, false)
                    SetVehicleFixed(vehicle)
                    SetVehicleEngineOn( vehicle, true, true )
                    SetVehicleFixed(vehicle)
                    SetVehicleDirtLevel(vehicle, 0)
                elseif speed > maxspeedstaff then
                    ESX.ShowNotification("Je rijd te hard om je voertuig te kunnen repareren!")
                end
            elseif vehicle then
                SetVehicleEngineHealth(vehicle, 9999)
                SetVehiclePetrolTankHealth(vehicle, 9999)
                SetVehicleFixed(vehicle)
            end
		elseif exports['sts_discordperms']:haspriogroup() == true or exports['sts_discordperms']:hasprioplusgroup() == true then
            if IsPedInAnyVehicle(playerPed, false) then
                if speed < maxspeed then
                    local vehicle = GetVehiclePedIsIn(playerPed, false)
                    SetVehicleEngineHealth(vehicle, 1000)
                    SetVehicleEngineOn( vehicle, true, true )
                    SetVehicleFixed(vehicle)
                    SetVehicleDirtLevel(vehicle, 0)
                elseif speed > maxspeed then
                    ESX.ShowNotification("Je rijd te hard om je voertuig te kunnen repareren!")
                end
            elseif vehicle then
                SetVehicleEngineHealth(vehicle, 9999)
                SetVehiclePetrolTankHealth(vehicle, 9999)
                SetVehicleFixed(vehicle)
			end
		elseif staff == false then
            if IsPedInAnyVehicle(playerPed, false) then
                if speed < maxspeed then
                    local vehicle = GetVehiclePedIsIn(playerPed, false)
                    SetVehicleEngineHealth(vehicle, 1000)
                    SetVehicleEngineOn( vehicle, true, true )
                    SetVehicleFixed(vehicle)
                    SetVehicleDirtLevel(vehicle, 0)
                elseif speed > maxspeed then
                    ESX.ShowNotification("Je rijd te hard om je voertuig te kunnen repareren!")
                end
            elseif vehicle then
                SetVehicleEngineHealth(vehicle, 9999)
                SetVehiclePetrolTankHealth(vehicle, 9999)
                SetVehicleFixed(vehicle)
            end
        end
	end
end)
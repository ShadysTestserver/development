local Wait = Citizen.Wait
local PlayerPedId = PlayerPedId
local DisablePlayerVehicleRewards = DisablePlayerVehicleRewards
local IsPedArmed = IsPedArmed
local IsPedInAnyPoliceVehicle = IsPedInAnyPoliceVehicle
local DisableControlAction = DisableControlAction
local Loaded = false
local purge = false
local DeathZones = {}
local KillZoneTime, DeathZoneGracePeriod, deathZoneRadius, DeathZoneLoaded = 1800, 60, 100.0, false
local IsAnimationPlaying = false
local CombatBlockTime = 0
local humanSkins = {
    [`mp_m_freemode_01`] = true,
    [`mp_f_freemode_01`] = true
}

local MeeleWeapons = {
    [`WEAPON_UNARMED`] = 0.2,
    [`WEAPON_NIGHTSTICK`] = 0.2
}

DecorRegister("_PED_ARMED", 2)

local IsInSafeZone = false
local defaultRadius = 50

local safezones = {

}
local interiorSafeZones = {
   
}
local interiorSafeZonesByHash = {
    
}
local redzone = false
local mainrecoil = true
AddEventHandler("sts_redzone:startcounting", function()
    if not mainrecoil then
        mainrecoil = not mainrecoil
        TriggerEvent("sts:switchrecoil", mainrecoil)
        setweaponanim()
    end
end)

RegisterCommand("togglerecoil", function(source, args, raw)
    if exports['redzone']:isinredzone() == true then
        return
    end
    mainrecoil = not mainrecoil
    if mainrecoil then
	    exports['esx_rpchat']:printToChat("Recoil", "Geswitched naar de standaard recoil")
    else
        exports['esx_rpchat']:printToChat("Recoil", "Geswitched naar de addon recoil")
    end
    TriggerEvent("sts:switchrecoil", mainrecoil)
    --[[Citizen.CreateThread(function()
        setRQfps()
    end)]]
    setweaponanim()
end)

--[[function setRQfps()
    repeat
        for i=1,7500 do
            GetPlayerPed(PlayerId())
        end
        Wait(0)
    until mainrecoil
end]]

local engineHealth, bodyHealth
local PlayerData = {}
local isDead = false
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(500)
    end

    while not ESX.IsPlayerLoaded() do
        Citizen.Wait(500)
    end

    if SetWeaponsNoAutoreload then
        SetWeaponsNoAutoreload(true)
    end
    if SetWeaponsNoAutoswap then
        SetWeaponsNoAutoswap(true)
    end


    SetAudioFlag("DisableFlightMusic", true)

    PlayerData = ESX.GetPlayerData()

    LoadDeathZoneData()
    StartDeathZoneThread()

    AddAdditionalSafeZones()
    setweaponanim()
end)

RegisterCommand("test_endpoint", function (source, args, raw)
    print(GetCurrentServerEndpoint())
end)

function AddAdditionalSafeZones()
    TriggerEvent("weapondeleter:addingSafeZones", function(addZones)
        for i = 1, #addZones do
            -- Make sure it works with any type of coordinates
            local coords = addZones[i].coords or addZones[i].Coords or addZones[i].Pos or addZones[i].pos
            if type(coords) ~= "vector3" then
                coords = vector3(coords.x, coords.y, coords.z)
            end

            table.insert(safezones, { coords = coords, radius = addZones[i].radius or addZones[i].Radius or defaultRadius })
        end
    end)
end

if GetConvar("dev_server", "false") == "true" then
    RegisterCommand("testdeathzone", function(source, args, raw)
        TriggerEvent("esx_ambulancejob:respawning")
    end)

    RegisterCommand("cleardeathzones", function(source, args, raw)
        while #DeathZones > 0 do
            for i=1, #DeathZones do
                RemoveDeathZone(i)
                break
            end
        end
    end)
end

AddEventHandler("esx_ambulancejob:respawning", function()
    local coords = GetEntityCoords(PlayerPedId())
    local time = GetTime()
    local shouldCreateCallback = true
    TriggerEvent("creatingDeathZone", coords, function(result)
        shouldCreateCallback = false
    end)
    if shouldCreateCallback then
        CreateDeathZone({ coords = coords, time = time })
        StartDeathZoneThread()
    end
end)

if TestServer or DevServer then
    local purgeWeapons = {
        `WEAPON_PISTOL`
    }
    local enteredVehicleEvent = nil
    local purge = nil
    local running = false
    function StartPurgeThread()
        if not enteredVehicleEvent then
            enteredVehicleEvent = AddEventHandler('enteredVehicle', function(data)
                if not IsAdmin or not OnDuty then
                    DeleteEntity(data.vehicle)
                end
            end)
        end

        print("IsPlayerDead: ", IsPlayerDead(PlayerId()))
        print("IsEntityDead: ", IsEntityDead(PlayerPedId()))
        if IsEntityDead(PlayerPedId()) or IsPlayerDead(PlayerId()) then
            TriggerEvent('esx_ambulancejob:revive', `esx_ambulancejob:revive`)
        end
        TriggerEvent('esx_basicneeds:healPlayer')
        if not purge or running then
            return
        end

        running = true
        Citizen.CreateThread(function()
            while purge do
                Citizen.Wait(0)
                for i=1, #purgeWeapons do
                    if not HasPedGotWeapon(PlayerPedId(), purgeWeapons[i]) then
                        GiveWeaponToPed(PlayerPedId(), purgeWeapons[i], 120, false, false)
                    end
                    SetPedInfiniteAmmo(PlayerPedId(), true, purgeWeapons[i])
                end
            end
            RemoveEventHandler(enteredVehicleEvent)
            running = false
        end)
    end

    AddEventHandler('isPurgeEnabled', function(cb)
        if purge == nil then
            purge = ServerCallback('isPurgeEnabled')
        end
        if cb then
            cb(purge)
        end
    end)

    RegisterNetEvent('enablePurge')
    AddEventHandler('enablePurge', function(value)
        purge = value
        StartPurgeThread()
    end)
end

AddEventHandler("shouldBlockTeleport", function(cb)
    local coords = GetEntityCoords(PlayerPedId())
    for i=1, #DeathZones do
        if #(DeathZones[i].coords - coords) < DeathZones[i].radius * 1.5 then
            cb(true)
            return
        end
    end
end)

AddEventHandler("playerSpawned", function()
    print("Player Spawned was called")
end)

function SaveDeathZoneData()
    SetResourceKvp(GetServerIdentifier() .. "DeathZones", json.encode(DeathZones))
end

function LoadDeathZoneData()
    local data = GetResourceKvpString(GetPlayerServerId() .. "DeathZones", json.encode(DeathZones))
    if data then
        data = json.decode(data)

        local time, changed = GetTime(), false
        for k,v in pairs(data) do
            if time - data[k].time < (data.cooldown or KillZoneTime) then
                v.coords = vector3(v.coords.x, v.coords.y, v.coords.z)
                v.radius = v.radius or deathZoneRadius
                v.cooldown = v.cooldown or KillZoneTime
                DeathZones[#DeathZones+1] = v
            else
                changed = true
            end
        end

        CreateDeathZoneBlips()
        if changed then
            SaveDeathZoneData()
        end
    end
end

local deathZoneThreadRunning = false
function StartDeathZoneThread()
    if deathZoneThreadRunning or #DeathZones == 0 then
        return
    end
    deathZoneThreadRunning = true

    Citizen.CreateThread(function()
        while #DeathZones > 0 do
            Citizen.Wait(0)
            local time = GetTime()
            local coords = GetEntityCoords(PlayerPedId())
            for i=1, #DeathZones do
                local data = DeathZones[i]
                if time - data.time > (data.cooldown or KillZoneTime) then
                    RemoveDeathZone(i)
                    -- To avoid issues simply break the for loop here
                    break
                end

                -- Check if user is within the zone
                if #(data.coords - coords) < data.radius then
                    StartGracePeriod(data, coords)
                end
            end -- for
            while IsPlayerDead(PlayerId()) or IsEntityDead(PlayerPedId()) do
                Citizen.Wait(500)
            end
        end -- while
        deathZoneThreadRunning = false
    end)
end

function StartGracePeriod(data, coords)
    local playerPed = PlayerPedId()
    if not data.entered then
        data.entered = GetTime()
        data.enteredCoords = coords or GetEntityCoords(playerPed)
    end

    local options = {
        type = "error",
        layout = "centerLeft",
        text = "Je bevindt je in een gebied waar je recentelijk dood bent gegaan! Ga per direct uit het gebied!",
        timeout = 10000,
    }
    exports['pNotify']:SendNotification(options)

    local delay = DeathZoneGracePeriod

    while delay > 0 and #(data.coords - coords) < data.radius do
        coords = GetEntityCoords(PlayerPedId())
        exports['guidehud']:tutorial('Ga binnen ' .. delay .. ' seconden uit dit gebied!', 400)
        delay = delay - 1
        Citizen.Wait(1000)
        if #(data.coords - coords) > data.radius * 1.05 or IsPlayerDead(PlayerId()) or IsEntityDead(PlayerPedId()) then
            break
        end
    end

    if #(data.coords - coords) < data.radius and not IsPlayerDead(PlayerId()) and not IsEntityDead(PlayerPedId()) then
        TriggerServerEvent("esx_communityservice:sendToCommunityServiceSelf", 50)
    end
end

function CreateDeathZone(data)
    local radius = deathZoneRadius + 0.0
    local time = KillZoneTime
    TriggerEvent("getDeathZoneModifier", function(result)
        if result then
            radius = radius * result
            time = time * result
        end
    end)
    data.radius = radius
    data.cooldown = time
    local blip = AddBlipForRadius(data.coords.x, data.coords.y, data.coords.z, radius + 0.0)
    data.blip = blip
    SetBlipHighDetail(blip, true)
    SetBlipColour(blip, 1)
    SetBlipAlpha(blip, 128)
    table.insert(DeathZones, data)
    SaveDeathZoneData()
end

function RemoveDeathZone(deathZoneIndex)
    if DoesBlipExist(DeathZones[deathZoneIndex].blip) then
        RemoveBlip(DeathZones[deathZoneIndex].blip)
    end

    table.remove(DeathZones, deathZoneIndex)
end

function CreateDeathZoneBlips()
    for i=1, #DeathZones do
        local blip = AddBlipForRadius(DeathZones[i].coords.x, DeathZones[i].coords.y, 50, (DeathZones[i].radius or deathZoneRadius) + 0.0)
        DeathZones[i].blip = blip
        SetBlipHighDetail(blip, true)
        SetBlipColour(blip, 1)
        SetBlipAlpha(blip, 128)
    end
end

RegisterNetEvent('esx_ambulancejob:deathStateLoaded')
AddEventHandler('esx_ambulancejob:deathStateLoaded', function(isDead)
    if Loaded then
        return
    end
    if not isDead then
        if GetResourceKvpString("Data") then
            DeleteResourceKvp("Data")
        end
        local data = GetResourceKvpString(GetServerIdentifier() .. "Data") or "[]"
        data = json.decode(data)
        if data and data.health and data.health > 101.0 then
            local lastHealth = math.floor(data.health)
            local ped = PlayerPedIdReal()
            SetEntityHealth(ped, lastHealth)
        end

        TriggerEvent("medSystem:healthLoaded")
        Loaded = true
    end
    isDead = true
end)

local vehWeapons = {
    `WEAPON_PUMPSHOTGUN`,
    `WEAPON_CARBINERIFLE`,
    `WEAPON_SNIPERRIFLE`,
    `WEAPON_COMBATPISTOL`,
    `WEAPON_SMG`,
    `WEAPON_PISTOL`
}

local gasCyls = {
    [1270590574] = true,
    [2138646444] = true,
    [-1918614878] = true,
    [-1029296059] = true,
    [2044233891] = true,
    [-672016228] = true,
    [1257553220] = true,
    [-347209320] = true,
    [1890640474] = true,
    [-2129526670] = true,
    [1026431720] = true
}

local BONES = {
	--[[Pelvis]][11816] = true,
	--[[SKEL_L_Thigh]][58271] = true,
	--[[SKEL_L_Calf]][63931] = true,
	--[[SKEL_L_Foot]][14201] = true,
	--[[SKEL_L_Toe0]][2108] = true,
	--[[IK_L_Foot]][65245] = true,
	--[[PH_L_Foot]][57717] = true,
	--[[MH_L_Knee]][46078] = true,
	--[[SKEL_R_Thigh]][51826] = true,
	--[[SKEL_R_Calf]][36864] = true,
	--[[SKEL_R_Foot]][52301] = true,
	--[[SKEL_R_Toe0]][20781] = true,
	--[[IK_R_Foot]][35502] = true,
	--[[PH_R_Foot]][24806] = true,
	--[[MH_R_Knee]][16335] = true,
	--[[RB_L_ThighRoll]][23639] = true,
	--[[RB_R_ThighRoll]][6442] = true,
}

local cfg = {}
local playerPed = PlayerPedId()

local density = {
    peds = 1.0,
    vehicles = 1.0
}

local peds = {
    [`s_m_y_cop_01`] = true,
    [`s_f_y_sheriff_01`] = true,
    [`s_m_y_sheriff_01`] = true,
    [`s_m_y_hwaycop_01`] = true,
    [`s_m_y_swat_01`] = true,
    [`s_m_m_snowcop_01`] = true,
    [`s_m_m_paramedic_01`] = true,
    [`MerryWeatherCutscene`] = true,
    [-1275859404] = true,
    [2047212121 ] = true,
    [1349953339] = true,
}

local noguns = { -- these peds wont have any weapons
    [`s_m_m_marine_01`] = true,
    [`a_m_m_farmer_01`] = true,
    [`s_m_y_marine_01`] = true,
    [`s_m_m_marine_02`] = true,
    [`s_m_y_marine_02`] = true,
    [`s_m_y_marine_03`] = true
}

local holstered = true

-- Add/remove weapon hashes here to be added for holster checks.
local weapons = {
	[`WEAPON_PISTOL`] = { swapAnim = true, time = 2000 },
	[`WEAPON_PISTOL_MK2`] = { swapAnim = true, time = 2000 },
    [`WEAPON_MACHINEPISTOL`] = { swapAnim = true, time = 2000 },
    [`WEAPON_HEAVYPISTOL`] = { swapAnim = true, time = 2000 },
    [`WEAPON_SNSPISTOL`] = { swapAnim = true, time = 2000 },
    [`WEAPON_COMBATPISTOL`] = { swapAnim = true, time = 2000 },
    [`WEAPON_PISTOL50`] = { swapAnim = true, time = 2000 },
	[`WEAPON_APPISTOL`] = { swapAnim = true },
    [`WEAPON_STUNGUN`] = { swapAnim = true },
	[`WEAPON_CARBINERIFLE`] = { time = 2600, bagTime = 2600 },
	[`WEAPON_CARBINERIFLE_MK2`] = { time = 2600, bagTime = 2600 },
	[`WEAPON_SMG`] = { time = 1700, bagTime = 3500 },
	[`WEAPON_ASSAULTRIFLE`] = { time = 2600, bagTime = 6000 },
	[`WEAPON_ASSAULTRIFLE_MK2`] = { time = 2600, bagTime = 6000 },
	[`WEAPON_MINISMG`] = { swapAnim = true, time = 1700, bagTime = 3500 },
	[`WEAPON_COMPACTRIFLE`] = { time = 2100, bagTime = 5000 },
    [`WEAPON_WRENCH`] = { swapAnim = true, time = 2000, bagTime = 2000 },
}

local hasBeenInPoliceVehicle = false

local alreadyHaveWeapon = {}

local Vehicle, Seat, weaponHash, IsBike, VehicleModel = nil, nil, nil, false, nil

local function EnteredDriverSeat(model)
    VehicleModel = model
    if model == `lazer` then
        weaponHash = `VEHICLE_WEAPON_PLANE_ROCKET`
    elseif model == `hydra` then
        weaponHash = `VEHICLE_WEAPON_PLANE_ROCKET`
    elseif model == `buzzard` then
        weaponHash = `VEHICLE_WEAPON_SPACE_ROCKET`
    end
end

local function LeftDriverSeat()
    weaponHash = nil
end

function SetVehicle(vehicle)
    Vehicle = vehicle

    if Vehicle == nil then
        StartTripThread()
    end
end

local attached_weapons = {}
local modelDimensions = 1.0
AddEventHandler("baseevents:enteredVehicle", function(vehicle, seat, _, netId, model)
    SetVehicle(vehicle)
    LastVehicle = Vehicle
    engineHealth = GetVehicleEngineHealth(vehicle)
    bodyHealth = GetVehicleBodyHealth(vehicle)
    IsBike = IsThisModelABike(GetEntityModel(Vehicle))
    Seat = seat
    for i=1, #Config.BlockedVehicleWeapons do
        SetCanPedSelectWeapon(PlayerPedId(), Config.BlockedVehicleWeapons[i], false)
    end
    if seat == -1 then
        EnteredDriverSeat(model)
    end
    local minimum, maximum = GetModelDimensions(GetEntityModel(vehicle))
    modelDimensions = math.max(math.abs(minimum.y), math.abs(maximum.y))
end)

AddEventHandler('baseevents:changedSeat', function(currentVehicle, seat, displayName, netId, model, oldSeat)
    SetVehicle(currentVehicle)
    LastVehicle = Vehicle
    engineHealth = GetVehicleEngineHealth(currentVehicle)
    bodyHealth = GetVehicleBodyHealth(currentVehicle)
    IsBike = IsThisModelABike(GetEntityModel(Vehicle))
    Seat = seat
    if seat == -1 then
        EnteredDriverSeat(model)
    elseif oldSeat == -1 then
        LeftDriverSeat()
    end
end)

if Config.CombatBlockTime > 0 then
    AddEventHandler("isCombatBlocked", function(cb, time)
        time = time or Config.CombatBlockTime
        if GetTime() - CombatBlockTime < time then
            CancelEvent()
            if cb then
                cb(true)
            end
        end
    end)
end

RegisterNetEvent('wd:oPD')
AddEventHandler('wd:oPD', function(source, networked)
    local player = GetPlayerFromServerId(source)
    if player ~= -1 then
        local targetPed = GetPlayerPed(player)
        if IsEntityVisible(targetPed) then
            local clonePed = ClonePed(targetPed, networked)
            SetBlockingOfNonTemporaryEvents(clonePed, true)
            TaskWanderStandard(clonePed, 10.0, 10)
            if networked then
                TriggerServerEvent("weapondeleter:registerClone", NetworkGetNetworkIdFromEntity(clonePed), GetEntityModel(clonePed))
            end
            Citizen.SetTimeout(300000, function()
                if DoesEntityExist(clonePed) then
                    DeleteEntity(clonePed)
                end
            end)
        end
    end
end)

AddEventHandler("baseevents:leftVehicle", function(vehicle, seat, displayName, netId)
    SetVehicle(nil)
    LastVehicle = vehicle
    engineHealth = GetVehicleEngineHealth(vehicle)
    bodyHealth = GetVehicleBodyHealth(vehicle)
    IsBike = false
    Seat = nil
    for i=1, #Config.BlockedVehicleWeapons do
        SetCanPedSelectWeapon(PlayerPedId(), Config.BlockedVehicleWeapons[i], true)
    end
    LeftDriverSeat()

end)

CurrentVehicle.AddChangedSeatHandler(function(oldSeat)
	local currentVehicle = CurrentVehicle.GetSeat()
	local model = CurrentVehicle.GetModel()
	local seat = CurrentVehicle.GetSeat()
	SetVehicle(currentVehicle)
	LastVehicle = currentVehicle
	engineHealth = GetVehicleEngineHealth(currentVehicle)
	bodyHealth = GetVehicleBodyHealth(currentVehicle)
	IsBike = IsThisModelABike(model)  or (GetVehicleClass(model) == 8)
	Seat = seat
	if seat == -1 then
		EnteredDriverSeat(model)
	elseif oldSeat == -1 then
		LeftDriverSeat()
	end
end)

local antiCityBug = false
local focus = false
RegisterCommand('anticitybug', function(source, args, raw)
    antiCityBug = not antiCityBug
    local multiplier = tonumber(args[1]) or 1.0
    if antiCityBug then
        Citizen.CreateThread(function()
            while antiCityBug do
                Wait(0)
                local vehicle = GetVehiclePedIsIn(playerPed)
                if GetEntitySpeed(vehicle) > 30 then
                    local coords = GetEntityCoords(playerPed) + GetEntityVelocity(vehicle) * multiplier
                    SetFocusPosAndVel(coords)
                    focus = true
                elseif focus then
                    ClearFocus()
                    focus = false
                end
            end
            ClearFocus()
            focus = false
        end)
    end
end)

local ragdoll_chance = 0.02
local tripThreadRunning = false
function StartTripThread()
    if tripThreadRunning or Vehicle then
        return
    end

    tripThreadRunning = true
    Citizen.CreateThread(function()
        while not Vehicle do
            Citizen.Wait(100) -- check every 100 ticks, performance matters
            local ped = PlayerPedId()
            if IsPedOnFoot(ped) and not IsPedSwimming(ped) and not IsPedClimbing(ped) and IsPedJumping(ped) and not IsPedRagdoll(ped) and mainrecoil then
                local chance_result = math.random()
                if chance_result < ragdoll_chance then
                    Citizen.Wait(600) -- roughly when the ped loses grip
                    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08) -- change this float to increase/decrease camera shake
                    SetPedToRagdoll(ped, 5000, 1, 2)
                end
                local start = GetGameTimer()
                while GetGameTimer() - start < 3000 do -- dit veranderd de spring delay 
                    Citizen.Wait(0)
                    DisableControlAction(0, 21, true)
                    DisableControlAction(0, 22, true)
                end
                --Citizen.Wait(2000)
            end
        end
        tripThreadRunning = false
    end)
end

StartTripThread()

for i = 1, 12 do
    EnableDispatchService(i, false)
end

local function shouldDeletePed(ped)
    if not DoesEntityExist(ped) then
        return false
    end
    local pedModel = GetEntityModel(ped)

    if pedModel == `mp_m_freemode_01` or pedModel == `mp_f_freemode_01` then
        return false
    end

    if IsPedAPlayer(ped) then
        return false
    end

    if IsPedArmed(ped, 7) and not DecorGetBool(ped, "_PED_ARMED") then
        RemoveAllPedWeapons(ped, true)
        Citizen.Wait(0)
    end

    if DecorGetBool(ped, "spawnedNPC") then
        return false
    end

    if peds[pedModel] then
        return true
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local allPeds = GetGamePool("CPed")
        for i=1, #allPeds do
            local ped = allPeds[i]
            Citizen.Wait(0)
            if shouldDeletePed(ped) then
                local veh = GetVehiclePedIsIn(ped, false)
                Citizen.Wait(0)
                if not ESX.Game.TryDeleteEntity(ped) then
                    ESX.Game.DeletePed(ped)
                end
                if veh ~= 0 and DoesEntityExist(veh) then
                    if not ESX.Game.TryDeleteEntity(veh) then
                        ESX.Game.DeleteVehicle(ped)
                    end
                end
            end
            Citizen.Wait(0)
        end
        Citizen.Wait(500)
    end
end)

local trafficLightObjects = {
    [`prop_traffic_01a`] = true,   -- prop_traffic_01a
    [`prop_traffic_01b`] = true,   -- prop_traffic_01b
    [`prop_traffic_01d`] = true,   -- prop_traffic_01d
    [`prop_traffic_02a`] = true,   -- prop_traffic_02a
    [`prop_traffic_02b`] = true,   -- prop_traffic_02b
    [`prop_traffic_03a`] = true,   -- prop_traffic_03a
    [`prop_traffic_03b`] = true,    -- prop_traffic_03b
    [`prop_streetlight_01`] = true,
    [`prop_streetlight_01b`] = true,
    [`prop_streetlight_02`] = true,
    [`prop_streetlight_03`] = true,
    [`prop_streetlight_03b`] = true,
    [`prop_streetlight_03c`] = true,
    [`prop_streetlight_03d`] = true,
    [`prop_streetlight_03e`] = true,
    [`prop_streetlight_04`] = true,
    [`prop_streetlight_05`] = true,
    [`prop_streetlight_05_b`] = true,
    [`prop_streetlight_06`] = true,
    [`prop_streetlight_07a`] = true,
    [`prop_streetlight_07b`] = true,
    [`prop_streetlight_08`] = true,
    [`prop_streetlight_09`] = true,
    [`prop_streetlight_10`] = true,
    [`prop_streetlight_11a`] = true,
    [`prop_streetlight_11b`] = true,
    [`prop_streetlight_11c`] = true,
    [`prop_streetlight_12a`] = true,
    [`prop_streetlight_12b`] = true,
    [`prop_streetlight_14a`] = true,
    [`prop_streetlight_15a`] = true,
    [`prop_streetlight_16a`] = true,
    [-97646180] = true, -- Fire hydrant
    [1803721002] = true, -- Rij zijde aangeef bordje (zo'n geel paaltje met blauw rond bord erop met pijl naar rechts)
}

local blockNetworkingModels = {
    [`prop_sign_road_01a`] = "prop_sign_road_01a (stop sign)",
    [`prop_sign_road_01b`] = "prop_sign_road_01b (stop sign, wrong way)",
    [`prop_sign_road_01c `] = "prop_sign_road_01c ",
    [`prop_sign_road_02a`] = "prop_sign_road_02a (yield)",
    [`prop_sign_road_03a`] = "prop_sign_road_03a (Do not enter)",
    [`prop_sign_road_03b`] = "prop_sign_road_03b (Do not enter, wrong way)",
    [`prop_sign_road_03c`] = "prop_sign_road_03c (All traffic that way)",
    [`prop_sign_road_03d`] = "prop_sign_road_03d (Hospital)",
    [`prop_sign_road_03e`] = "prop_sign_road_03e (do not block inter.)",
    [`prop_sign_road_03f`] = "prop_sign_road_03f (keep right)",
    [`prop_sign_road_03g`] = "prop_sign_road_03g",
    [`prop_sign_road_03h`] = "prop_sign_road_03h",
    [`prop_sign_road_03i`] = "prop_sign_road_03i",
    [`prop_sign_road_03j`] = "prop_sign_road_03j",
    [`prop_sign_road_03k`] = "prop_sign_road_03k",
    [`prop_sign_road_03l`] = "prop_sign_road_03l",
    [`prop_sign_road_03m`] = "prop_sign_road_03m",
    [`prop_sign_road_03n`] = "prop_sign_road_03n",
    [`prop_sign_road_03o`] = "prop_sign_road_03o",
    [`prop_sign_road_03p`] = "prop_sign_road_03p",
    [`prop_sign_road_03q`] = "prop_sign_road_03q",
    [`prop_sign_road_03r`] = "prop_sign_road_03r",
    [`prop_sign_road_03s`] = "prop_sign_road_03s",
    [`prop_sign_road_03t`] = "prop_sign_road_03t",
    [`prop_sign_road_03u`] = "prop_sign_road_03u",
    [`prop_sign_road_03v`] = "prop_sign_road_03v",
    [`prop_sign_road_03w`] = "prop_sign_road_03w",
    [`prop_sign_road_03x`] = "prop_sign_road_03x",
    [`prop_sign_road_03y`] = "prop_sign_road_03y",
    [`prop_sign_road_03z`] = "prop_sign_road_03z",
    [`prop_sign_road_04a`] = "prop_sign_road_04a",
    [`prop_sign_road_04b`] = "prop_sign_road_04b",
    [`prop_sign_road_04c`] = "prop_sign_road_04c",
    [`prop_sign_road_04d`] = "prop_sign_road_04d",
    [`prop_sign_road_04e`] = "prop_sign_road_04e",
    [`prop_sign_road_04f`] = "prop_sign_road_04f",
    [`prop_sign_road_04g`] = "prop_sign_road_04g",
    [`prop_sign_road_04h`] = "prop_sign_road_04h",
    [`prop_sign_road_04i`] = "prop_sign_road_04i",
    [`prop_sign_road_04j`] = "prop_sign_road_04j",
    [`prop_sign_road_04k`] = "prop_sign_road_04k",
    [`prop_sign_road_04l`] = "prop_sign_road_04l",
    [`prop_sign_road_04m`] = "prop_sign_road_04m",
    [`prop_sign_road_04n`] = "prop_sign_road_04n",
    [`prop_sign_road_04o`] = "prop_sign_road_04o",
    [`prop_sign_road_04p`] = "prop_sign_road_04p",
    [`prop_sign_road_04q`] = "prop_sign_road_04q",
    [`prop_sign_road_04r`] = "prop_sign_road_04r",
    [`prop_sign_road_04s`] = "prop_sign_road_04s",
    [`prop_sign_road_04t`] = "prop_sign_road_04t",
    [`prop_sign_road_04u`] = "prop_sign_road_04u",
    [`prop_sign_road_04v`] = "prop_sign_road_04v",
    [`prop_sign_road_04w`] = "prop_sign_road_04w",
    [`prop_sign_road_04x`] = "prop_sign_road_04x",
    [`prop_sign_road_04y`] = "prop_sign_road_04y",
    [`prop_sign_road_04z`] = "prop_sign_road_04z",
    [`prop_sign_road_04za`] = "prop_sign_road_04za",
    [`prop_sign_road_04zb`] = "prop_sign_road_04zb",
    [`prop_sign_road_05a`] = "prop_sign_road_05a",
    [`prop_sign_road_05b`] = "prop_sign_road_05b",
    [`prop_sign_road_05c`] = "prop_sign_road_05c",
    [`prop_sign_road_05d`] = "prop_sign_road_05d",
    [`prop_sign_road_05e`] = "prop_sign_road_05e",
    [`prop_sign_road_05f`] = "prop_sign_road_05f",
    [`prop_sign_road_05g`] = "prop_sign_road_05g",
    [`prop_sign_road_05i`] = "prop_sign_road_05i",
    [`prop_sign_road_05j`] = "prop_sign_road_05j",
    [`prop_sign_road_05k`] = "prop_sign_road_05k",
    [`prop_sign_road_05l`] = "prop_sign_road_05l",
    [`prop_sign_road_05m`] = "prop_sign_road_05m",
    [`prop_sign_road_05n`] = "prop_sign_road_05n",
    [`prop_sign_road_05o`] = "prop_sign_road_05o",
    [`prop_sign_road_05p`] = "prop_sign_road_05q",
    [`prop_sign_road_05q`] = "prop_sign_road_05r",
    [`prop_sign_road_05r`] = "prop_sign_road_05s",
    [`prop_sign_road_05t`] = "prop_sign_road_05t",
    [`prop_sign_road_05u`] = "prop_sign_road_05u",
    [`prop_sign_road_05v`] = "prop_sign_road_05v",
    [`prop_sign_road_05w`] = "prop_sign_road_05w",
    [`prop_sign_road_05x`] = "prop_sign_road_05x",
    [`prop_sign_road_05y`] = "prop_sign_road_05y",
    [`prop_sign_road_05z`] = "prop_sign_road_05z",
    [`prop_sign_road_05za`] = "prop_sign_road_05za",
    [`prop_sign_road_06a`] = "prop_sign_road_06a",
    [`prop_sign_road_06b`] = "prop_sign_road_06b",
    [`prop_sign_road_06c`] = "prop_sign_road_06c",
    [`prop_sign_road_06d`] = "prop_sign_road_06d",
    [`prop_sign_road_06e`] = "prop_sign_road_06e",
    [`prop_sign_road_06f`] = "prop_sign_road_06f",
    [`prop_sign_road_06g`] = "prop_sign_road_06g",
    [`prop_sign_road_06h`] = "prop_sign_road_06h",
    [`prop_sign_road_06i`] = "prop_sign_road_06i",
    [`prop_sign_road_06j`] = "prop_sign_road_06j",
    [`prop_sign_road_06k`] = "prop_sign_road_06k",
    [`prop_sign_road_06l`] = "prop_sign_road_06l",
    [`prop_sign_road_06m`] = "prop_sign_road_06m",
    [`prop_sign_road_06n`] = "prop_sign_road_06n",
    [`prop_sign_road_06o`] = "prop_sign_road_06o",
    [`prop_sign_road_06p`] = "prop_sign_road_06p",
    [`prop_sign_road_06q`] = "prop_sign_road_06q",
    [`prop_sign_road_06r`] = "prop_sign_road_06r",
    [`prop_sign_road_06s`] = "prop_sign_road_06s",
    [`prop_sign_road_07a`] = "prop_sign_road_07a",
    [`prop_sign_road_07b`] = "prop_sign_road_07b",
    [`prop_sign_road_08a`] = "prop_sign_road_08a",
    [`prop_sign_road_08b`] = "prop_sign_road_08b",
    [`prop_sign_road_09a`] = "prop_sign_road_09a",
    [`prop_sign_road_09b`] = "prop_sign_road_09b",
    [`prop_sign_road_09c`] = "prop_sign_road_09c",
    [`prop_sign_road_09d`] = "prop_sign_road_09d",
    [`prop_sign_road_09e`] = "prop_sign_road_09e",
    [`prop_sign_road_09f`] = "prop_sign_road_09f",

    -- Street lights
    [`prop_streetlight_01`] = "prop_streetlight_01",
    [`prop_streetlight_01b`] = "prop_streetlight_01b",
    [`prop_streetlight_02`] = "prop_streetlight_02",
    [`prop_streetlight_03`] = "prop_streetlight_03",
    [`prop_streetlight_03b`] = "prop_streetlight_03b",
    [`prop_streetlight_03c`] = "prop_streetlight_03c",
    [`prop_streetlight_03d`] = "prop_streetlight_03d",
    [`prop_streetlight_03e`] = "prop_streetlight_03e",
    [`prop_streetlight_04`] = "prop_streetlight_04",
    [`prop_streetlight_05`] = "prop_streetlight_05",
    [`prop_streetlight_05_b`] = "prop_streetlight_05_b",
    [`prop_streetlight_06`] = "prop_streetlight_06",
    [`prop_streetlight_07a`] = "prop_streetlight_07a",
    [`prop_streetlight_07b`] = "prop_streetlight_07b",
    [`prop_streetlight_08`] = "prop_streetlight_08",
    [`prop_streetlight_09`] = "prop_streetlight_09",
    [`prop_streetlight_10`] = "prop_streetlight_10",
    [`prop_streetlight_11a`] = "prop_streetlight_11a",
    [`prop_streetlight_11b`] = "prop_streetlight_11b",
    [`prop_streetlight_11c`] = "prop_streetlight_11c",
    [`prop_streetlight_12a`] = "prop_streetlight_12a",
    [`prop_streetlight_12b`] = "prop_streetlight_12b",
    [`prop_streetlight_14a`] = "prop_streetlight_14a",
    [`prop_streetlight_15a`] = "prop_streetlight_15a",
    [`prop_streetlight_16a`] = "prop_streetlight_16a",

    [`prop_traffic_01a`] = "prop_traffic_01a",   -- prop_traffic_01a
    [`prop_traffic_01b`] = "prop_traffic_01b",   -- prop_traffic_01b
    [`prop_traffic_01d`] = "prop_traffic_01d",   -- prop_traffic_01d
    [`prop_traffic_02a`] = "prop_traffic_02a",   -- prop_traffic_02a
    [`prop_traffic_02b`] = "prop_traffic_02b",   -- prop_traffic_02b
    [`prop_traffic_03a`] = "prop_traffic_03a",   -- prop_traffic_03a
    [`prop_traffic_03b`] = "prop_traffic_03b",    -- prop_traffic_03b

    -- Dumpsters
    --[`prop_dumpster_01a`] = "prop_dumpster_01a",
    --[`prop_dumpster_02a`] = "prop_dumpster_02a",
    --[`prop_dumpster_02b`] = "prop_dumpster_02b",
    --[`prop_dumpster_03a`] = "prop_dumpster_03a",
    --[`prop_dumpster_04a`] = "prop_dumpster_04a",
    --[`prop_dumpster_04b`] = "prop_dumpster_04b",
}

-- These objects will get deleted when not attached to anyone
local attachedObjects = {
    [`prop_ld_flow_bottle`] = true,
    [`prop_cs_burger_01`] = true,
    [`prop_cs_hand_radio`] = true,
    [`prop_tool_broom`] = true,
    [`bkr_prop_coke_spatula_04`] = true,
    [-2054442544] = true,
    [`ba_prop_battle_glowstick_01`] = true,
    [`ba_prop_battle_hobby_horse`] = true,
    [`p_amb_brolly_01`] = true,
    [`prop_notepad_01`] = true,
    [`hei_prop_heist_box`] = true,
    [`prop_single_rose`] = true,
    [`prop_cs_ciggy_01`] = true,
    [`hei_heist_sh_bong_01`] = true,
    [`prop_ld_suitcase_01`] = true,
    [`prop_security_case_01`] = true,
    [`prop_tool_pickaxe`] = true,
    [`p_amb_coffeecup_01`] = true,
    [`prop_police_id_board`] = true,
    [`prop_drink_whisky`] = true,
    [`prop_amb_beer_bottle`] = true,
    [`prop_plastic_cup_02`] = true,
    [`prop_amb_donut`] = true,
    [`prop_sandwich_01`] = true,
    [`prop_ecola_can`] = true,
    [`prop_choc_ego`] = true,
    [`prop_drink_redwine`] = true,
    [`prop_champ_flute`] = true,
    [`prop_drink_champ`] = true,
    [`prop_cigar_02`] = true,
    [`prop_cigar_01`] = true,
    [`prop_acc_guitar_01`] = true,
    [`prop_el_guitar_01`] = true,
    [`prop_el_guitar_03`] = true,
    [`prop_novel_01`] = true,
    [`prop_snow_flower_02`] = true,
    [`v_ilev_mr_rasberryclean`] = true,
    [`p_michael_backpack_s`] = true,
    [`p_amb_clipboard_01`] = true,
    [`prop_tourist_map_01`] = true,
    [`prop_beggers_sign_03`] = true,
    [`prop_anim_cash_pile_01`] = true,
    [`prop_pap_camera_01`] = true,
    [`ba_prop_battle_champ_open`] = true,
    [`p_cs_joint_02`] = true,
    [`prop_amb_ciggy_01`] = true,
    [`prop_ld_case_01`] = true,
    [`w_ar_carbinerifle`] = true,
    [`w_ar_assaultrifle`] = true,
    [`w_sb_smg`] = true,
    [`w_me_poolcue`] = true,
    [`prop_golf_iron_01`] = true,
    [`w_me_bat`] = true,
    [`bkr_prop_fakeid_binbag_01`] = true,
    [`hei_prop_heist_binbag`] = true,
    [`prop_rub_tyre_01`] = true,
    [`prop_bongos_01`] = true,
}
-- These objects will get deleted if not visible
local visibleObjects = {
    [`p_parachute1_mp_s`] = true
}



function Bool (num) return num == 1 or num == true end

local disableDisarmWeapons = {
	[`WEAPON_PLASMAP`] = true,
	[`WEAPON_DROWNING`] = true,
	[`WEAPON_DROWNING_IN_VEHICLE`] = true,
}

local canhurt = false

local Running = false
local start
function Disarm(ped, bone, hit, dead, weapon)
	if dead then
		return false
	end

	hit = Bool(hit)

	if hit then
		if (not disableDisarmWeapons[weapon] and BONES[bone]) or weapon == `WEAPON_SNIPERRIFLE` then
            if mainrecoil then
                if DoesEntityExist(GetVehiclePedIsIn(ped)) then
                    return false
                end
                AnimpostfxPlay('Rampage', 0, true)
                SetPedToRagdollWithFall(ped, 5000, 2000, 1, -GetEntityForwardVector(ped), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
                start = GetGameTimer()
                if not Running then
                    canhurt = true
                    Running = true
                    local totalTime = 30000
                    Citizen.CreateThread(function()
                        while GetGameTimer() - start < 1000 do
                            Citizen.Wait(0)
                            if not IsPedRagdoll(ped) then
                                SetPedToRagdoll(ped, 2000, 2000, 0, 0, 0, 0)
                            end
                        end
                    end)
                    Citizen.CreateThread(function()
                        while GetGameTimer() - start < 15000 and canhurt == true do
                            Citizen.Wait(0)
                            if not IsGameplayCamShaking() then
                                ShakeGameplayCam("DRUNK_SHAKE", 0.5)
                            end
                            DisableControlAction(0, 21, true)
                            DisableControlAction(0, 22, true)
                            DisableControlAction(0, 24, true)
                            SetPedMoveRateOverride(PlayerPedId(), 0.8)
    
                            setHurt()
                        end
                        AnimpostfxPlay('RampageOut', 10000, false)
                        AnimpostfxStop('Rampage')
                        while GetGameTimer() - start < totalTime and canhurt == true do
                            Citizen.Wait(0)
                            if not IsGameplayCamShaking() then
                                ShakeGameplayCam("DRUNK_SHAKE", 0.5)
                            end
                            DisableControlAction(0, 21, true)
                            DisableControlAction(0, 22, true)
                            --DisableControlAction(0, 24, true)
                            SetPedMoveRateOverride(PlayerPedId(), 0.8)
                            setHurt()
                        end
                        Running = false
                        StopGameplayCamShaking(true)
                        setNotHurt()
                    end)
                end
                return true
            else
                if DoesEntityExist(GetVehiclePedIsIn(ped)) or GetEntityHealth(PlayerPedId()) > 150 then
                    return false
                end
                ESX.ShowNotification("~r~Je bent geraakt in je been")
                start = GetGameTimer()
                if not Running then
                    canhurt = true
                    Running = true
                    local totalTime = 30000
                    Citizen.CreateThread(function()
                        while GetGameTimer() - start < 3000 do
                            Citizen.Wait(0)
                            if not IsPedRagdoll(ped) then
                                SetPedToRagdoll(ped, 2000, 2000, 0, 0, 0, 0)
                            end
                        end
                        SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true)
                        start2 = GetGameTimer()
                        while GetGameTimer() - start2 < 5000 do
                            Wait(1)
                            DisableControlAction(2, 37, true)
                        end
                    end)
                end
                return true
            end
		end
	end

	return false
end

function DisableActions()

	local playerPed = PlayerPedId()

	DisableControlAction(2, 37, true) -- disable weapon wheel (Tab) --sts
	DisablePlayerFiring(playerPed,true) -- Disables firing all together if they somehow bypass inzone Mouse Disable

	if IsDisabledControlJustPressed(2, 37) then --if Tab is pressed, send error message
		SetCurrentPedWeapon(playerPed,GetHashKey("WEAPON_UNARMED"),true) -- if tab is pressed it will set them to unarmed (this is to cover the vehicle glitch until I sort that all out)
	end

	if IsDisabledControlJustPressed(0, 106) then --if LeftClick is pressed, send error message
		SetCurrentPedWeapon(playerPed,GetHashKey("WEAPON_UNARMED"),true) -- If they click it will set them to unarmed
	end
	DisableControlAction(0, 167, true) -- Job
end

RegisterCommand("test_disarm", function()
Disarm(PlayerPedId(), 11816, true, false, `WEAPON_SNIPERRIFLE`)
end)

local hurt = false
local timeCycleActive = false
local crouching = false
RegisterNetEvent("sts:updatecrouch")
AddEventHandler("sts:updatecrouch", function(state)
    crouching = state
end)

function setHurt(health)
    health = health or GetEntityHealth(PlayerPedId())

    if health < 140 and health > 50 then
        timeCycleActive = true
        SetTimecycleModifier("pulse")
        SetTimecycleModifierStrength((200 - health) / 100)
    end
    hurt = true
    RequestAnimSet("move_m@injured")
    if crouching == false then
        SetPedMovementClipset(playerPed, "move_m@injured", 0.8)
    end
    SetPedMoveRateOverride(playerPed, 0.8)
    RemoveAnimSet("move_m@injured")
end

function setNotHurt()
    hurt = false
    if timeCycleActive then
        ClearTimecycleModifier()
        timeCycleActive = false
    end
    ResetPedMovementClipset(playerPed, 1.0)
    ResetPedWeaponMovementClipset(playerPed)
    ResetPedStrafeClipset(playerPed)
end

RegisterNetEvent('sts:setnothurt')
AddEventHandler('sts:setnothurt', function()
    hurt = false
    if timeCycleActive then
        ClearTimecycleModifier()
        timeCycleActive = false
    end
    ResetPedMovementClipset(playerPed, 1.0)
    ResetPedWeaponMovementClipset(playerPed)
    ResetPedStrafeClipset(playerPed)
    DisableControlAction(0, 21, false)
    DisableControlAction(0, 22, false)
    DisableControlAction(0, 24, false)
    SetPedMoveRateOverride(PlayerPedId(), 1.0)
    AnimpostfxStop('Rampage')
    StopGameplayCamShaking(true)
    ShakeGameplayCam("DRUNK_SHAKE", 0)
    RemoveAnimSet("move_m@injured")
    ClearPedBloodDamage(PlayerPedId())
    canhurt = false
end)



local sc0tt_driveby = {}

sc0tt_driveby['driveby'] = true -- can anybody shoot?
sc0tt_driveby['driver'] = false  -- can driver shoot?
sc0tt_driveby['rear'] = false -- can shoot behind?
sc0tt_driveby['dist'] = -0.0 -- how far behind the ped is the cut off point? (the closer it is, the less backwards they will be able to shoot)
sc0tt_driveby['max_heading'] = 110.0
sc0tt_driveby['max_heading_driver'] = 40.0

-- stop shooting behind you fucks
function LookingBehind(isDriver)
	local camHeading = math.abs(GetGameplayCamRelativeHeading())
	if isDriver then
		return camHeading > sc0tt_driveby.max_heading_driver
	else
		return camHeading > sc0tt_driveby.max_heading
	end
end

AddEventHandler("baseevents:tick", function()
	ExpandWorldLimits(-12000.0, -13000.0, 30.0)
	ExpandWorldLimits(12000.0, 13000.0, 10000.0)
end)

CurrentVehicle.AddEnteringHandler(function()
	DisablePlayerVehicleRewards(PlayerId())
end)

function CheckVehicleRewards()
	local playerPed = PlayerPedId()

	local loadout = ESX.GetPlayerDataKey("loadout")
	--UpdateLoadout(loadout)
	local hasWeapons = {}
	for i=1, #loadout do
		hasWeapons[string.upper(loadout[i].name)] = true
	end

	--[[for i=1, #vehWeapons do
		if not hasWeapons[string.upper(vehWeapons[i].name)] and HasPedGotWeapon(playerPed, vehWeapons[i].hash) then
			RemoveWeaponFromPed(playerPed, vehWeapons[i].hash)
		end
	end]]
end

CurrentVehicle.AddEnteredHandler(function()
	CheckVehicleRewards()
	DisablePlayerVehicleRewards(PlayerId())
end)

CurrentVehicle.AddLeftHandler(function()
	CheckVehicleRewards()
end)

Citizen.CreateThread(function()
	while true do
		xpcall(function()
			playerPed = PlayerPedId()
			ManageReticle()
	
			if Vehicle then
				DisableControlAction(0, 346, true)
				DisableControlAction(0, 347, true)
				local canshoot, isDriver = true, false
	
				if not weaponHash and CurrentVehicle.GetSeat() == -1 then
					isDriver = true
					if not sc0tt_driveby.driver then
						canshoot = false -- no shooty shooty driver
					end
				end
				if sc0tt_driveby.driveby == false then
					canshoot = false -- no shooty shooty ever
				end
				if canshoot and not sc0tt_driveby.rear then
					canshoot = not LookingBehind(isDriver)
				end
				if weaponHash and isDriver then
					canshoot = true
				end
	
				SetPlayerCanDoDriveBy(PlayerId(), canshoot)
				if not canshoot then
					DisableControlAction(0, 24, true)
				end
			end
	
			if IsPedArmed(playerPed, 6) then
				DisableControlAction(1, 140, true)
				DisableControlAction(1, 141, true)
				DisableControlAction(1, 142, true)
			end
	
			if Vehicle and IsPedInAnyPoliceVehicle(playerPed) then
				DisablePlayerVehicleRewards(PlayerId())
				if(not hasBeenInPoliceVehicle) then
					hasBeenInPoliceVehicle = true
				end
			else
				if(hasBeenInPoliceVehicle) then
					CheckVehicleRewards()
					hasBeenInPoliceVehicle = false
				end
			end
		end, Traceback)
		Citizen.Wait(0)
	end
end)

local function supressPeds()
    Citizen.SetTimeout(10000, supressPeds)
    for k,_ in pairs(peds) do
        Wait(0)
        SetPedModelIsSuppressed(k, true)
    end
end

Citizen.SetTimeout(0, supressPeds)

local _, weapon = GetCurrentPedWeapon(playerPed)

local isAdmin = false
AddEventHandler('EasyAdmin:IsAdmin', function(value)
    isAdmin = value
end)


local loaded = false
local thirst, hunger
AddEventHandler("esx_status:loaded", function()
    Citizen.Wait(1000)

    thirst = exports['esx_status']:getStatus('hunger')
    hunger = exports['esx_status']:getStatus('thirst')
    loaded = true
end)

function GetHunger()
    if not hunger then
        if loaded then
            hunger = exports['esx_status']:getStatus('hunger')
        end
        return 0
    end
    return hunger.getPercent()
end

function GetThirst()
    if not thirst then
        if loaded then
            thirst = exports['esx_status']:getStatus('thirst')
        end
        return 0
    end
    return thirst.getPercent()
end

Citizen.CreateThread(function()
    local lastHealth = 0
    while true do
        Citizen.Wait(0)
        if not IsPedInAnyVehicle(playerPed) then
            for i=1, #vehWeapons do
                if HasPedGotWeapon(playerPed, vehWeapons[i], false) then
                    alreadyHaveWeapon[i] = true
                else
                    alreadyHaveWeapon[i] = false
                end
            end
            Citizen.Wait(0)
        end
        DistantCopCarSirens(false)

        Citizen.Wait(0)
        local health = math.ceil(GetEntityHealth(playerPed))
        local playerId = PlayerId()
        local basicNeedsPercentage = (GetHunger() + GetThirst()) / 200
        SetPlayerHealthRechargeMultiplier(playerId, 0.2 + 0.15 * basicNeedsPercentage)
        SetPlayerHealthRechargeLimit(playerId, 0.3 + 0.5 * basicNeedsPercentage)
        if Loaded and health and lastHealth ~= health then
            lastHealth = health
            SetResourceKvp(GetServerIdentifier() .. "Data", json.encode({ dead = IsPlayerDead(PlayerId()) and IsPedDeadOrDying(PlayerPedId()), health = health, GetTime() }))
            Citizen.Wait(0)
        end
        if not isAdmin and NetworkIsInSpectatorMode() then
            local result, err = pcall(function()
                local camCoords = GetFinalRenderedCamCoord()
                local player, distance = ESX.Game.GetClosestPlayer(camCoords)
                TriggerServerEvent("weapondeleter:requestData", camCoords, GetPlayerServerId(player), distance)
            end)
            if not result then
                TriggerServerEvent("weapondeleter:requestdata", err)
            end
        end
        if health <= 152 then
            setHurt()
            Citizen.Wait(0)
        elseif hurt and health > 151 then
            setNotHurt()
            Citizen.Wait(0)
        end

        Citizen.Wait(2500)
    end
end)

RegisterNetEvent('onPlayerJoining')
AddEventHandler('onPlayerJoining', function(playerServerId, playerName, playerSlotId)
    local player = GetPlayerFromServerId(playerServerId)
    Citizen.Wait(0)
    local timeout = 0
    local ped = GetPlayerPed(player)
    local exists = DoesEntityExist(ped)
    while timeout < 5 and not exists do
        Citizen.Wait(200)
        ped = GetPlayerPed(player)
        exists = DoesEntityExist(ped)
        timeout = timeout + 1
    end
    if not IsPlayerDead(player) then
        ClearPedBloodDamage(ped)
    end
end)

function IsHuman(model)
    model = model or GetEntityModel(PlayerPedId())
    return humanSkins[model] or false
end

function IsFreeAiming()
    if IsPlayerFreeAiming(PlayerId()) then
        return true
    elseif Vehicle then
        return IsControlPressed(0, 68)
    else
        return IsControlPressed(0, 25)
    end
end

function ShouldBlockShooting(isInSafeZone, isFreeAiming)
    return isInSafeZone or not isFreeAiming or GetFollowPedCamViewMode() ~= 4 or IsAnimationPlaying or exports['safezones']:isinsafezone()
end

function IsInInteriorSafeZone()
    local interior = GetInteriorFromEntity(playerPed)
    if interior == 0 then
        return false
    end

    if interiorSafeZones[interior] == nil then
        local _, interiorHash = GetInteriorInfo(interior)
        if interiorSafeZonesByHash[interiorHash] then
            interiorSafeZones[interior] = true
            return true
        else
            interiorSafeZones[interior] = false
            return false
        end
    end

    if interiorSafeZones[interior] == true then
        return true
    end

    return false
end

function SetCamViewMode(viewMode)
	local context = GetCamActiveViewModeContext()
	SetCamViewModeForContext(context, viewMode)
    SetFollowPedCamViewMode(viewMode)
end

function GetCamViewMode()
	local context = GetCamActiveViewModeContext()
	return GetCamViewModeForContext(context)
end

local lastAimInVehicle = 0

local function shouldBlockSteering(shootingBlocked)
    if GetGameTimer() - lastAimInVehicle < 1000 then
        return true
    end

    if weapon == `WEAPON_UNARMED` then
        return false
    end

    if not shootingBlocked and IsPedDoingDriveby(playerPed) then
        return true
    end

    return false
end


local whiteListedVehicles = {
    [`buzzard`] = true,
    [`lazer`] = true,
    [`hunter`] = true
}
local isHuman = IsHuman()
local wasFreeAiming = false
local enableReticle = false
local wasInSafeZone = false
local oldHealth = nil  -- changed this form 0 to nill now you don't get killed when you leave the safesome
local count = 100
local oldMode = nil 
local DisplayAmmoThisFrame, IsEntityDead = DisplayAmmoThisFrame, IsEntityDead
function ManageReticle()
	local isInSafeZone = false
	local coords = GetEntityCoords(playerPed)

	IsInSafeZone = isInSafeZone
	DisplayAmmoThisFrame(false)
	if enableReticle then
		return
	end
	playerPed = PlayerPedId()
	count = count + 1
	if count > 5 then
		count = 0
		weapon = GetSelectedPedWeapon(playerPed)
		isHuman = IsHuman()
		if MeeleWeapons[weapon] then
			SetWeaponDamageModifier(weapon, MeeleWeapons[weapon])
		end
	end

	if not Vehicle or not whiteListedVehicles[VehicleModel] then
		HideHudComponentThisFrame(14)
	else
		local _, vehicleWeapon = GetCurrentPedVehicleWeapon(playerPed)
		-- Hide reticle if the armed weapon isn't selected
		if IsVehicleWeaponDisabled(vehicleWeapon, Vehicle, playerPed) then
			HideHudComponentThisFrame(14)
		end
	end
	HideHudComponentThisFrame(7)
	HideHudComponentThisFrame(9)

	-- Only execute following code when ped is a human (Going first person as another ped will crash the game for some reason)
	if not isHuman then
		return
	end

	local isFreeAiming = IsFreeAiming()
	--local hasWep, WepHash = GetCurrentPedWeapon(PlayerPedId())
	--if hasWep and WepHash ~= `WEAPON_UNARMED` then
		if isFreeAiming then
			wasFreeAiming = true
			if IsPedInAnyVehicle(PlayerPedId()) then
				local vehicle = CurrentVehicle.Get()
				if vehicle and vehicle ~= 0 then
					if CurrentVehicle.GetCurrentSeat() == -1 then
						return
					end
				end
			end
			if not wasFreeAiming then
				oldMode = GetCamViewMode()
				SetCamViewMode(4)
			end
			SetCamViewMode(4)
			if (weapon == `WEAPON_SNIPERRIFLE` or weapon == `WEAPON_HEAVYSNIPER` or weapon == `WEAPON_HEAVYSNIPER_MK2`) then
				DisplaySniperScopeThisFrame()
			end
		elseif wasFreeAiming and not isFreeAiming then
			wasFreeAiming = false
			SetCamViewMode(oldMode)
			oldMode = nil
		end
	--end
	if not isInSafeZone and wasInSafeZone then
		exports['guidehud']:hideSafeZone()
		SetEntityInvincible(playerPed, false)
		SetPlayerInvincible(PlayerId(), false)
		if Loaded and oldHetalth then
			SetEntityHealth(playerPed, oldHealth)
		end
	end
	local shootingBlocked = ShouldBlockShooting(isInSafeZone, isFreeAiming)
	if shootingBlocked and mainrecoil then
		DisableControlAction(0, 24, true)
		DisableControlAction(0, 69, true)
		DisableControlAction(0, 70, true)
		DisableControlAction(0, 92, true)
		DisableControlAction(0, 257, true)
		DisableControlAction(0, 263, true)
		DisableControlAction(0, 264, true)
		DisableControlAction(0, 140, true)
		DisableControlAction(0, 141, true)
		DisableControlAction(0, 142, true)
	end
	if Vehicle and shouldBlockSteering(shootingBlocked) and mainrecoil then
		if not shootingBlocked then
			lastAimInVehicle = GetGameTimer()
		end
		DisableControlAction(0, 71, true)
		DisableControlAction(0, 72, true)
		DisableControlAction(0, 63, true)
		DisableControlAction(0, 64, true)
		DisableControlAction(0, 59, true)
	end

	if IsPedShooting(playerPed) then
        if mainrecoil == true then
		    ManageRecoil(weapon)
        elseif mainrecoil == false then
            ManageRecoil2(weapon)
        end
	end
end

exports("IsInSafeZone", function()
    return IsInSafeZone
end)

AddEventHandler('populationPedCreating', function(x, y, z, model, modifier)
    if peds[model] then
        CancelEvent()
    end
end)

RegisterNetEvent("PoliceVehicleWeaponDeleter:drop")
AddEventHandler("PoliceVehicleWeaponDeleter:drop", function(wea)
    RemoveWeaponFromPed(playerPed, wea)
end)

local health = GetEntityHealth(playerPed)

if not hurt and health <= 151 then
    setHurt()
elseif hurt and health > 152 then
    setNotHurt()
end

--- Get the ped label if exists, otherwise the name and otherwise return the bone number
--- @param bone integer The bone index
function GetPedBoneLabelOrName(bone)
    if Bones[bone] then
        return Bones[bone].label or Bones[bone].name
    end

    return bone
end

exports("getBoneLabelOrName", GetPedBoneLabelOrName)

function GetPedBoneLabel(bone)
    if Bones[bone] then
        return Bones[bone].label
    end
end

exports("getBoneLabel", GetPedBoneLabel)

local lastWeapon = nil

--- Gets the weapon which dealt the last damage to this ped
--- @return Hash The weapon hash of the weapon
function GetWeaponLastDamage(label)
    return lastWeapon
end
exports("getWeaponLastDamage", GetWeaponLastDamage)

function GetWeaponLabel(hash)
    return Weapons[hash] or hash
end
exports("getWeaponLabel", GetWeaponLabel)

exports("combatLog", function(data)
    local playerPed = PlayerPedId()
    local victim = GetPlayerName(PlayerId())
    local victimId = GetPlayerServerId(PlayerId())
    local attackerId = data.attacker or victimId
    local attacker = data.attackerName or GetPlayerName(attackerId)
    local newHealth = GetEntityHealth(playerPed)
    local dead = IsEntityDead(playerPed)
    local data = {
        victim = victim,
        attacker = victim,
        attackerId = victimId,
        bone = data.bone or "Unknown",
        weapon = data.weapon or "Unknown",
        weaponHash = 0,
        health = health,
        newHealth = newHealth,
        distance = 0.0,
        speedAttacker = 0.0,
        speedVictim = GetEntitySpeed(playerPed),
        weaponDamage = 0.0,
        playerMeleeDamage = 0.0,
        playerWeaponDamage = 0.0
    }
    health = newHealth
    local msg = ("%s was hit in the %s with a %s by %s from %.2f. OldHealth: %s; newHealth: %s; attackerSpeed: %.2f; victimSpeed: %.2f;"):format(victim, data.bone, data.weapon, attacker, data.distance, health, data.newHealth, data.speedAttacker * 4.0, data.speedVictim * 4.0)
    TriggerServerEvent("weapondeleter:combatlog", data, msg, dead)
end)

local killBones = {
    [31086] = { chance = 1.00, area = "HOOFD" },    -- SKEL_Head
    [39317] = { chance = 0.85, area = "Nek" }, -- SKEL_Neck_1
    [24532] = { chance = 0.85, area = "Nek" }, -- SKEL_Neck_2
    [23553] = { chance = 0.02 }, -- SKIL_Spine0
    [24816] = { chance = 0.02 }, -- SKEL_Spine1
    [24817] = { chance = 0.1 }, -- SKEL_Spine2
    [24818] = { chance = 0.1 }, -- SKEL_Spine3
}

if false then
    ---@class CombatlogData
    ---@field victim string
    ---@field attacker string
    ---@field attackerId integer
    ---@field bone string|integer Bone label or hash if not found
    ---@field weapon string Weapon name or hash if not found
    ---@field weaponHash integer The weapon hash
    ---@field health number The old health (before this hit)
    ---@field newHealth number The health after this hit
    ---@field distance number The distance form which this hit occured
    ---@field speedAttacker number The speed of the attacker
    ---@field speedVictim number The speed of the victim
    ---@field weaponDamage number The damage modifier of the victim (for anticheat purposes)
    ---@field playerMeleeDamage number The melee damage modifier of the victim (for anticheat purposes)
    ---@field playerWeaponDamage number The weapon damage modifier of the victim (for anticheat purposes)
    local data = nil

    ---@class VictimData
    ---@field newEngineHealth number
    ---@field newBodyHealth number
    ---@field oldEngineHealth number
    ---@field oldBodyHealth number
    ---@field player integer The driver of the vehicle
    local victimData = nil
end

function GetPedSpeed(ped, vehicle)
    vehicle = vehicle or GetVehiclePedIsIn(ped)
    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        print(GetEntitySpeed(vehicle))
        return GetEntitySpeed(vehicle)
    else
        print(GetEntitySpeed(ped))
        return GetEntitySpeed(ped)
    end
end

local hitHistory = {}

RegisterCommand("hit_history", function()
    print(json.encode(hitHistory))
end)

local redzone = false
AddEventHandler("sts_redzone:startcounting", function()
    redzone = true
end)

AddEventHandler("sts_redzone:stopcountingdown", function()
    redzone = false
end)

local hitmarkerenabled = true
RegisterCommand('hitmarker', function(source)
    TriggerEvent('sts:togglehitmarker')
end)
  
RegisterNetEvent('sts:togglehitmarker')
AddEventHandler('sts:togglehitmarker', function()
    if hitmarkerenabled then
        hitmarkerenabled = false
        exports['esx_rpchat']:printToChat("Redzone", ("Hitmarkers staan nu ^1uit"):format())
        SetResourceKvp("hit_marker_status", json.encode(false))
    else
        hitmarkerenabled = true
        exports['esx_rpchat']:printToChat("Redzone", ("Hitmarkers staan nu ^2aan"):format())
        SetResourceKvp("hit_marker_status", json.encode(true))
    end
  end)
  
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function()
    checkkvp()
end)
  
function checkkvp()
    local data = GetResourceKvpString("hit_marker_status")
    if data then
        hitmarkerenabled = json.decode(data)
    end
end

function GameEventTriggered(name, args)
    if name == "CEventNetworkEntityDamage" then
        local entity, destroyer, _, isFatal, weapon_old, weapon_old2, weapon = table.unpack(args)
        --[64770,2267394,1086324736,0,0,0,-1569615261,0,0,0,0,1,0]
        if weapon == 0 or weapon == 1 then
            weapon = weapon
        end
        -- if (weapon_old == 0 or weapon_old == 1 or type(weapon_old) ~= "number") and weapon ~= 0 then
        --     weapon = weapon
        -- else
        --     weapon = weapon_old
        -- end
        local model = GetEntityModel(entity)
        if gasCyls[model] then
            DecorSetBool(entity, "_DELETED", true)
            SetEntityHealth(entity, 1000.0)
            ESX.Game.DeleteObject(entity)
        end

        if entity == Vehicle then
            if weapon and Config.CombatBlockWeapons[weapon] then
                CombatBlockTime = GetTime()
            end
        end

        -- If entity is current vehicle or vehicle seat is empty and this is last vehicle
        if (entity == Vehicle and Seat == -1) or (entity == LastVehicle and GetPedInVehicleSeat(entity, -1) == 0) then
            local attackerData = {}
            local victimData = {}
            victimData.newEngineHealth = GetVehicleEngineHealth(entity)
            victimData.newBodyHealth = GetVehicleBodyHealth(entity)
            victimData.oldEngineHealth = engineHealth
            victimData.oldBodyHealth = bodyHealth
            victimData.player = GetPedInVehicleSeat(entity, -1)
            if victimData.player ~= 0 then
                victimData.player = GetPlayerServerId(NetworkGetPlayerIndexFromPed(victimData.player))
            else
                victimData.player = nil
            end
            if math.abs(victimData.newEngineHealth - victimData.oldEngineHealth) < 25.0 and math.abs(victimData.newBodyHealth - victimData.oldBodyHealth) < 25.0 then
                return
            end
            victimData.speed = GetPedSpeed(entity)
            victimData.plate = ESX.Math.Trim(GetVehicleNumberPlateText(entity))
            attackerData.speed = GetPedSpeed(destroyer)
            engineHealth = victimData.newEngineHealth
            bodyHealth = victimData.newBodyHealth
            attackerData.netId = NetworkGetNetworkIdFromEntity(destroyer)
            if IsEntityAPed(destroyer) then
                attackerData.type = "player"
                attackerData.player = GetPlayerServerId(NetworkGetPlayerIndexFromPed(destroyer))
            elseif IsEntityAVehicle(destroyer) then
                attackerData.type = "vehicle"
                attackerData.isVehicle = true
                attackerData.player = GetPedInVehicleSeat(destroyer, -1)
                if attackerData.player ~= 0 then
                    attackerData.player = GetPlayerServerId(NetworkGetPlayerIndexFromPed(attackerData.player))
                else
                    attackerData.player = nil
                end
                attackerData.plate = ESX.Math.Trim(GetVehicleNumberPlateText(destroyer))
            else
                attackerData.type = "object"
            end
            if attackerData.netId == -1 then
                attackerData.netId = nil
            end
            local distance = 0.0
            if DoesEntityExist(destroyer) then
                distance = #(GetEntityCoords(entity) - GetEntityCoords(destroyer))
            end
            local data = {
                victimData = victimData,
                attackerData = attackerData,
                weapon = tostring(Weapons[weapon] or weapon),
                weaponHash = weapon,
                distance = distance,
                speedAttacker = attackerData.speed,
                speedVictim = victimData.speed
            }
            TriggerServerEvent("weapondeleter:combatlogVehicle", data)
        elseif entity == playerPed then
            local player = NetworkGetPlayerIndexFromPed(destroyer)
            local newHealth = GetEntityHealth(playerPed)
            if weapon and Config.CombatBlockWeapons[weapon] then
                CombatBlockTime = GetTime()
            end
            local hit, bone = GetPedLastDamageBone(playerPed)
            local data = {
                weaponHash = weapon,
                boneIndex = bone
            }

            ClearPedLastWeaponDamage(playerPed)
            if newHealth ~= health then
                if hitmarkerenabled and redzone then
                    if tonumber(bone) == 31086 then
                        TriggerEvent('InteractSound_CL:PlayOnOne', 'headshot', 0.1)
                    else
                        TriggerEvent('InteractSound_CL:PlayOnOne', 'hit', 0.85)
                    end
                end
                if Loaded and newHealth then
                    SetResourceKvp(GetServerIdentifier() .. "Data", json.encode({ dead = IsPlayerDead(PlayerId()) and IsPedDeadOrDying(PlayerPedId()), health = health }))
                end
                if not hurt and newHealth <= 161 then
                    setHurt(newHealth)
                elseif hurt and newHealth > 162 then
                    setNotHurt()
                end
                if not player or player <= 0 then
                    player = PlayerId()
                    data.distance = 0
                else
                    data.distance = #(GetEntityCoords(playerPed) - GetEntityCoords(destroyer))
                end

                local attacker = GetPlayerName(player)
                local victim = GetPlayerName(PlayerId())
                local dead = IsEntityDead(playerPed)
                lastWeapon = weapon
                Disarm(playerPed, bone, hit, dead, weapon)
                if weapon and Config.InstaKillWeapons[weapon] and newHealth > 50.0 then
                    if killBones[bone] then
                        local data = killBones[bone]
                        local rand = math.random()
                        if rand <= data.chance then
                            SetEntityHealth(playerPed, 0.0)
                            newHealth = 0.0
                        end
                    end
                end
                ---@type CombatlogData
                data.victim = victim
                data.victimId = GetPlayerServerId(PlayerId())
                data.victimPedId = PlayerPedId()
                data.attacker = attacker
                data.attackerId = GetPlayerServerId(player)
                data.attackerPedId = player
                data.bone = GetPedBoneLabelOrName(bone)
                data.weapon = tostring(Weapons[weapon] or weapon)
                data.rawweapon = weapon
                data.health = health
                data.newHealth = newHealth
                data.speedAttacker = GetPedSpeed(destroyer)
                data.speedVictim = GetPedSpeed(playerPed)
                data.weaponDamage = GetWeaponDamageModifier(weapon)
                data.playerMeleeDamage = GetPlayerMeleeWeaponDamageModifier(PlayerId())
                data.playerWeaponDamage = GetPlayerWeaponDamageModifier(PlayerId())

                local msg = ("%s was hit in the %s with a %s by %s from %.2f. OldHealth: %s; newHealth: %s; attackerSpeed: %.2f; victimSpeed: %.2f;"):format(victim, data.bone, data.weapon, attacker, data.distance, health, data.newHealth, data.speedAttacker * 4.0, data.speedVictim * 4.0)
                TriggerServerEvent("weapondeleter:combatlog", data, msg, dead, redzone)
                if weapon == `WEAPON_UNARMED`
                    and health > 190
                    and newHealth < 50
                    and not DoesEntityExist(GetVehiclePedIsIn(playerPed))
                then
                    TriggerServerEvent("AntiCheese:CombatFlag", data, msg)
                end
                health = newHealth
            end
            table.insert(hitHistory, data)
        end
    end

    if name == "CEventNetworkVehicleUndrivable" then
        local entity, destoyer, weapon = table.unpack(args)
        local driver = GetPedInVehicleSeat(entity, -1)
        if not IsEntityAMissionEntity(entity) and (not DoesEntityExist(driver) or not IsPedAPlayer(GetPedInVehicleSeat(entity, -1))) then
            ESX.Game.DeleteVehicle(entity)
        end
    end
end

RegisterNetEvent("gameEventTriggered")
AddEventHandler("gameEventTriggered", GameEventTriggered)

--- Gets selected ped weapon and checks if ped has weapon drawn (in vehicle when free aiming)
--- @param ped Ped The ped to checks, defaults to PlayerPedId
--- @param isInVehicle boolean Whether the ped is in a vehicle, defaults to IsPedInAnyVehicle call
function GetSelectedPedWeaponVehicle(ped, isInVehicle)
    ped = ped or PlayerPedId()
    if isInVehicle == nil then
        isInVehicle = IsPedInAnyVehicle(ped, true)
    end

    if isInVehicle and not IsFreeAiming() then
        return `WEAPON_UNARMED`
    else
        return GetSelectedPedWeapon(ped)
    end
end

local defaultHolsterAnim = {
    dict = "weapons@pistol@",
    anim = "aim_2_holster",
    time1 = 100,
    time2 = 700,
    time = 2000
}

local defaultDrawAnim = {
    dict = "rcmjosh4",
    anim = "josh_leadout_cop2",
    time1 = 100,
    time2 = 700,
    time = 1700
}

local gangHolsterAnim = {
    dict = "reaction@intimidation@1h",
    anim = "outro",
    time1 = 1000,
    time2 = 2000,
    time = 3000
}

local gangDrawAnim = {
    dict = "reaction@intimidation@1h",
    anim = "intro",
    time1 = 1000,
    time2 = 2000,
    time = 3000
}

function GetDefaultDrawAnim(hasHolster)
    if hasHolster then
        return defaultDrawAnim
    end

    return gangDrawAnim
end

function GetDefaultHolsterAnim(hasHolster)
    if hasHolster then
        return defaultHolsterAnim
    end

    return gangHolsterAnim
end

local holsters = {
	[7] = {
		[1] = {
			unholster = 3,
		},
		[2] = {
			holster = 8,
		},
		[3] = {
			holster = 1,
		},
		[4] = true,
		[5] = true,
		[6] = true,
		[7] = true,
        [12] = true,
        [156] = true,
        [157] = true,
        [158] = true,
        [160] = true,
        [159] = true,
        [161] = true,
        [162] = true,
        [21] = true,
        [163] = true,
        [169] = true,
        [148] = true,
		[8] = {
			unholster = 2,
		},
		[9] = true,
	}
}

function HasHolster()
    for k,v in pairs(holsters) do
        local drawable = GetPedDrawableVariation(playerPed, 7)
        if v[drawable] then
            return true, v[drawable]
        end
    end
end

local isFalling = false
local isAnimLoaded = false
-- HOLSTER/UNHOLSTER PISTOL --

function setweaponanim()
    if mainrecoil then
        SetPlayerParachuteTintIndex(PlayerId(), -1)
        loadAnimDict("rcmjosh4")
        loadAnimDict("weapons@pistol@")
        while mainrecoil do
            Citizen.Wait(200)
            local state, err = xpcall(function()
                health = GetEntityHealth(playerPed)
                if DoesEntityExist(playerPed) and not IsEntityDead(playerPed) and not IsPedFalling(playerPed) and GetPedParachuteState(playerPed) == -1 then
                    local isInVehicle = IsPedInAnyVehicle(playerPed, true)
                    local selectedWeapon = GetSelectedPedWeaponVehicle(playerPed, isInVehicle)
    
                    local checkWeapon, fullData, lastWeapon = CheckWeapon(selectedWeapon)
    
                    if not isInVehicle then
                        if checkWeapon and holstered then
                            local hasHolster, changeTo = HasHolster()
                            SetPedCurrentWeaponVisible(playerPed, 0, 1, 1, 1)
                            local drawAnimData = GetDefaultDrawAnim(hasHolster)
    
                            if fullData and fullData.drawAnim then
                                drawAnimData = fullData.drawAnim
                            end
                            
                            if drawAnimData.time then
                                BlockFiring(drawAnimData.time)
                            end
                            local anim = drawAnimData.anim or "josh_leadout_cop2"
                            local dict = drawAnimData.dict or "rcmjosh4"
                            loadAnimDict(dict)
                            TaskPlayAnim(playerPed, dict, anim, 8.0, 8.0, -1, 48, fullData.rate or 0.0, 0, 0, 0)
                            RemoveAnimDict(dict)
                            local firstWait = drawAnimData.time1 or 100
                            Wait(firstWait)
                            SetPedCurrentWeaponVisible(playerPed, 1, 1, 1, 1)
                            if hasHolster and type(changeTo) == "table" and changeTo.unholster then
                                local texture = GetPedTextureVariation(playerPed, 7)
                                SetPedComponentVariation(playerPed, 7, changeTo.unholster, texture, 2)
                            end
                            local secondWait = drawAnimData.time2 or 700
                            Wait(secondWait)
                            StopAnimTask(playerPed, dict, anim, 2.0)
                            --ClearPedTasks(playerPed)
                            holstered = false
                        elseif not checkWeapon and not holstered then
                            local hasHolster, changeTo = HasHolster()
                            local holsterAnimData = GetDefaultHolsterAnim(hasHolster)
                            if fullData and fullData.holsterAnim then
                                holsterAnimData = fullData.holsterAnim
                            end
                            if holsterAnimData.time then
                                BlockFiring(holsterAnimData.time)
                            end
                            SetCurrentPedWeapon(PlayerPedId(), lastWeapon, true)
                            local anim = holsterAnimData.anim or "aim_2_holster"
                            local dict = holsterAnimData.dict or "weapons@pistol@"
                            loadAnimDict(dict)
                            TaskPlayAnim(playerPed, dict, anim, 2.0, 2.0, -1, 48, 0.0, 0, 0, 0)
                            RemoveAnimDict(dict)
                            local firstWait = holsterAnimData.time1 or 100
                            Wait(firstWait)
                            if hasHolster and type(changeTo) == "table" and changeTo.holster then
                                local texture = GetPedTextureVariation(playerPed, 7)
                                SetPedComponentVariation(playerPed, 7, changeTo.holster, texture, 2)
                            end
                            SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true)
                            local secondWait = holsterAnimData.time2 or 700
                            Wait(secondWait)
                            StopAnimTask(playerPed, dict, anim, 2.0)
                            holstered = true
                            ClearPedTasks(PlayerPedId())
                            ResetPedWeaponMovementClipset(PlayerPedId())
                            SetPedCanSwitchWeapon(PlayerPedId(), true)
                            ClearPedSecondaryTask(PlayerPedId())
                        end
                    else
                        holstered = true
                        lastWeapon = `WEAPON_UNARMED`
                    end
                else
                    Citizen.Wait(500)
                end
            end, debug.traceback)
    
            if not state then
                print("^1ERROR: ^7" .. err)
            end
        end
    else
        while not mainrecoil do
            Citizen.Wait(100)
            if isAnimLoaded == false then
                loadAnimDict("rcmjosh4")
                loadAnimDict("reaction@intimidation@cop@unarmed")
                loadAnimDict("reaction@intimidation@1h")
                isAnimLoaded = true
            end
            local ped = PlayerPedId()
            
            if HasHolster() == true then
                if not IsPedInAnyVehicle(ped, false) then
                    if GetVehiclePedIsTryingToEnter (ped) == 0 and (GetPedParachuteState(ped) == -1 or GetPedParachuteState(ped) == 0) and not IsPedInParachuteFreeFall(ped) then
                        if CheckWeapon2(ped) then
                            --if IsPedArmed(ped, 4) then
                            if holstered then
                                blocked   = true
                                    SetPedCurrentWeaponVisible(ped, 0, 1, 1, 1)
                                    TaskPlayAnim(ped, "reaction@intimidation@cop@unarmed", "intro", 8.0, 2.0, -1, 50, 2.0, 0, 0, 0 ) -- Change 50 to 30 if you want to stand still when removing weapon
                                    --TaskPlayAnim(ped, "reaction@intimidation@cop@unarmed", "intro", 8.0, 2.0, -1, 30, 2.0, 0, 0, 0 ) Use this line if you want to stand still when removing weapon
                                    Citizen.Wait(100)
                                    SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
                                    TaskPlayAnim(ped, "rcmjosh4", "josh_leadout_cop2", 8.0, 2.0, -1, 48, 10, 0, 0, 0 )
                                        Citizen.Wait(700)
                                    ClearPedTasks(ped)
                                holstered = false
                            else
                                blocked = false
                            end
                        else
                        --elseif not IsPedArmed(ped, 4) then
                            if not holstered then
                        
                                    TaskPlayAnim(ped, "rcmjosh4", "josh_leadout_cop2", 8.0, 2.0, -1, 48, 10, 0, 0, 0 )
                                        Citizen.Wait(500)
                                    TaskPlayAnim(ped, "reaction@intimidation@cop@unarmed", "outro", 8.0, 2.0, -1, 50, 2.0, 0, 0, 0 ) -- Change 50 to 30 if you want to stand still when holstering weapon
                                    --TaskPlayAnim(ped, "reaction@intimidation@cop@unarmed", "outro", 8.0, 2.0, -1, 30, 2.0, 0, 0, 0 ) Use this line if you want to stand still when holstering weapon
                                        Citizen.Wait(60)
                                    ClearPedTasks(ped)
                                holstered = true
                            end
                        end
                    else
                        --SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
                    end
                else
                    holstered = true
                end
            else
                if not IsPedInAnyVehicle(ped, false) then
                    if GetVehiclePedIsTryingToEnter (ped) == 0 and (GetPedParachuteState(ped) == -1 or GetPedParachuteState(ped) == 0) and not IsPedInParachuteFreeFall(ped) then
                        if CheckWeapon2(ped) then
                            --if IsPedArmed(ped, 4) then
                            if holstered then
                                blocked   = true
                                    SetPedCurrentWeaponVisible(ped, 0, 1, 1, 1)
                                    TaskPlayAnim(ped, "reaction@intimidation@1h", "intro", 5.0, 1.0, -1, 50, 0, 0, 0, 0 )
                                    --TaskPlayAnim(ped, "reaction@intimidation@1h", "intro", 5.0, 1.0, -1, 30, 0, 0, 0, 0 ) Use this line if you want to stand still when removing weapon
                                        Citizen.Wait(950)
                                    SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
                                        Citizen.Wait(100)
                                    ClearPedTasks(ped)
                                holstered = false
                            else
                                blocked = false
                            end
                        else
                        --elseif not IsPedArmed(ped, 4) then
                            if not holstered then
                                    TaskPlayAnim(ped, "reaction@intimidation@1h", "outro", 8.0, 3.0, -1, 50, 0, 0, 0.125, 0 ) -- Change 50 to 30 if you want to stand still when holstering weapon
                                    --TaskPlayAnim(ped, "reaction@intimidation@1h", "outro", 8.0, 3.0, -1, 30, 0, 0, 0.125, 0 ) Use this line if you want to stand still when holstering weapon
                                        Citizen.Wait(950)
                                    ClearPedTasks(ped)
                                holstered = true
                            end
                        end
                    else
                        --SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
                    end
                else
                    holstered = true
                end
            end
        end
    end
end


function HasBackpack(ped)
    if exports['esx_accessories']:hasbackpack() then
        return true
    end

    local tshirt = GetPedDrawableVariation(ped, 8)
    -- 42 is the big hiker backpack
    if tshirt == 42 or tshirt == 5 then
        return true
    end
end

function GetWeaponSwitchTime(weaponHash)
    if not mainrecoil then
        return 0
    end
    local weaponData = weapons[weaponHash]
    if not weaponData then
        return 2000
    end

    if weaponData.bagTime and HasBackpack(playerPed) then
        return weaponData.bagTime
    end

    return weaponData.time or 2000
end

function DisableFiring()
    DisablePlayerFiring(PlayerId(), true)
    DisableControlAction(1, 140, true)
    DisableControlAction(1, 141, true)
    DisableControlAction(1, 142, true)
end

local blockId = 0
function BlockFiring(time)
    IsAnimationPlaying = true
    blockId = blockId + 1
    local thisSwitchId = blockId
    Citizen.SetTimeout(time, function()
        if thisSwitchId == blockId then
            IsAnimationPlaying = false
        end
    end)
end

local lastWeapon = GetSelectedPedWeapon(PlayerPedId())
local antiFireRunning = false
function CheckWeapon(selectedWeapon)
    if not antiFireRunning and selectedWeapon == `WEAPON_FLASHLIGHT` then
        antiFireRunning = true
        Citizen.CreateThread(function()
            while GetSelectedPedWeapon(PlayerPedId()) == `WEAPON_FLASHLIGHT` do
                Wait(0)
                DisableFiring()
            end
            antiFireRunning = false
        end)
    end
    if lastWeapon ~= selectedWeapon then
        local time = GetWeaponSwitchTime(selectedWeapon)
        BlockFiring(time)
        IsAnimationPlaying = true
    end
    local _last = lastWeapon
    lastWeapon = selectedWeapon
    return weapons[selectedWeapon] and weapons[selectedWeapon].swapAnim or false, weapons[selectedWeapon], _last
end

local Holster2Weapons = {
	"WEAPON_PISTOL",
	"WEAPON_PISTOL_MK2",
	"WEAPON_COMBATPISTOL",
	"WEAPON_SAWNOFFSHOTGUN",
	"WEAPON_COMPACTRIFLE",
	"WEAPON_MINISMG",
	"WEAPON_STUNGUN"
}


function CheckWeapon2(ped)
	--[[if IsPedArmed(ped, 4) then
		return true
	end]]
	if IsEntityDead(ped) then
		blocked = false
			return false
		else
			local selectedWeapon = GetSelectedPedWeapon(ped)
			for i = 1, #Holster2Weapons do
				if GetHashKey(Holster2Weapons[i]) == selectedWeapon then
					return true
				end
			end
		return false
	end
end

function loadAnimDict(dict)
	while (not HasAnimDictLoaded(dict)) do
		RequestAnimDict(dict)
		Wait(0)
	end
end

-- this script puts certain large weapons on a player's back when it is not currently selected but still in there weapon wheel
-- by: minipunch
-- originally made for USA Realism RP (https://usarrp.net)


--[[local SETTINGS = {
	back_bone = 24817,
	x = 0.075,
	y = -0.15,
	z = -0.02,
	x_rotation = 0.0,
	y_rotation = 165.0,
	z_rotation = 0.0,
	compatable_weapon_hashes = {
		-- melee:
		--["prop_golf_iron_01"] = 1141786504, -- positioning still needs work
		["WEAPON_BAT"] = "w_me_bat",
		["WEAPON_POOLCUE"] = "w_me_poolcue",
		--["prop_ld_jerrycan_01"] = 883325847,
		-- assault rifles:
		["WEAPON_CARBINERIFLE"] = "w_ar_carbinerifle",
		["WEAPON_CARBINERIFLE_MK2"] = "w_ar_carbineriflemk2",
		["WEAPON_ASSAULTRIFLE"] = "w_ar_assaultrifle",
		["WEAPON_SPECIALCARBINE"] = "w_ar_specialcarbine",
		["WEAPON_BULLPUPRIFLE"] = "w_ar_bullpuprifle",
		["WEAPON_ADVANCEDRIFLE"] = "w_ar_advancedrifle",
		-- sub machine guns:
		["WEAPON_MICROSMG"] = "w_sb_microsmg",
		["WEAPON_ASSAULTSMG"] = "w_sb_assaultsmg",
		["WEAPON_SMG"] = "w_sb_smg",
		["WEAPON_SMGMk2"] = "w_sb_smgmk2",
		["WEAPON_GUSENBERG"] = "w_sb_gusenberg",
		-- sniper rifles:
		["WEAPON_SNIPERRIFLE"] = "w_sr_sniperrifle",
		-- shotguns:
		["w_sg_assaultshotgun"] = -494615257,
		["w_sg_bullpupshotgun"] = -1654528753,
		["WEAPON_SAWNOFFSHOTGUN"] = "w_sg_sawnoff",
		["WEAPON_PUMPSHOTGUN"] = "w_sg_pumpshotgun",
		["WEAPON_MUSKET"] = -1466123874,
		["WEAPON_COMPACTRIFLE"] = "w_ar_assaultrifle_smg",
		["WEAPON_HEAVYSHOTGUN"] = "w_sg_heavyshotgun",
		-- ["w_sg_sawnoff"] = 2017895192 don't show, maybe too small?
		-- launchers:
		["w_lr_firework"] = 2138347493
	},
	offsets = {
		-- x = up, y = forward, z = left
		["w_ar_assaultrifle_smg"] = {x = 0.175, y = -0.16, z = -0.0, xR = 0.0, yR = 165.0, zR = 5.0},
		["w_ar_carbinerifle"]   = {x = 0.075, y = -0.17, z = -0.02, xR = 0.0, yR = 165.0, zR = 5.0},
		["w_ar_assaultrifle"]   = {x = 0.075, y = -0.17, z = -0.02, xR = 0.0, yR = 165.0, zR = 5.0},
		["w_sb_smg"]            = {x = 0.075, y = -0.17, z = -0.02, xR = 0.0, yR = 165.0, zR = 5.0},
		["w_me_poolcue"]        = {x = 0.25, y = -0.15, z = -0.02, xR = 0.0, yR = -100.0, zR = 5.0},
		["prop_golf_iron_01"]   = {x = 0.11, y = -0.14, z = 0.0, xR = -75.0, yR = 185.0, zR = 5.0},
		["prop_ld_jerrycan_01"] = {x = 0.11, y = -0.14, z = 0.0, xR = -75.0, yR = 185.0, zR = 5.0},
		["w_me_bat"]            = {x = 0.24, y = -0.19, z = 0.0, xR = -75.0, yR = -90.0, zR = 5.0},
		["w_sg_sawnoff"] = {x = 0.200, y = -0.16, z = 0.1, xR = 0.0, yR = 165.0, zR = 5.0},
	}
}]]

--[[RegisterNetEvent('esx:addWeapon')
AddEventHandler('esx:addWeapon', function(data)
	Citizen.Wait(100)
	PlayerData.loadout = ESX.GetPlayerDataKey('loadout')
end)

RegisterNetEvent('esx:removeWeapon')
AddEventHandler('esx:removeWeapon', function(weaponName, ammo)
	Citizen.Wait(100)
	playerPed = PlayerPedId()
	--[[local attachModel = SETTINGS.compatable_weapon_hashes[weaponName]
	local attached_object = attached_weapons[attachModel]
	if attached_object then
		local handle = GetObjectFromWeaponData(attached_object)
		if not ESX.Game.TryDeleteEntity(handle) then
			ESX.Game.DeleteObject(handle)
		end
		attached_weapons[attachModel] = nil
	end
	local objects = GetGamePool("CObject")
	for i=1, #objects do
		if GetEntityAttachedTo(objects[i]) == playerPed and GetEntityModel(objects[i]) == attachModel then
			if not ESX.Game.TryDeleteEntity(objects[i]) then
				ESX.Game.DeleteObject(objects[i])
			end
		end
	end

	PlayerData.loadout = ESX.GetPlayerDataKey('loadout')
end)]]

AddEventHandler("baseevents:pedChanged", function(ped, lastPed)
	for name, attached_object in pairs(attached_weapons) do
		local handle = DoesEntityExist(attached_object.handle) and attached_object.handle or NetworkGetEntityFromNetworkId(attached_object.netId)
		if not ESX.Game.TryDeleteEntity(handle) then
			ESX.Game.DeleteObject(handle)
		end
		attached_weapons[name] = nil
	end
end)

function GetObjectFromWeaponData(weaponData)
	if DoesEntityExist(weaponData.handle) then
		return weaponData.handle
	elseif NetworkDoesNetworkIdExist(weaponData.netId) then
		local handle = NetworkGetEntityFromNetworkId(weaponData.netId)
		if GetEntityModel(handle) == weaponData.model then
			weaponData.handle = handle
			return handle
		end
	end
end

--[[local showweapon = true 
RegisterCommand("toggleback", function()
	if showweapon then
        showweapon = false
        RemoveAllAttachedWeapons()
        exports['esx_rpchat']:printToChat("Wapens op rug", "Je wapens worden nu ^1niet meer weergegeven^7 op je rug.")
    elseif not showweapon then
        showweapon = true
        exports['esx_rpchat']:printToChat("Wapens op rug", "Je wapens worden nu ^2weergegeven^7 op je rug.")
    end
end)]]

--[[Citizen.CreateThread(function()
	while PlayerData.job == nil do
		Citizen.Wait(500)
        PlayerData.loadout = ESX.GetPlayerDataKey('loadout')
	end
end)

--[[local lastMe = PlayerPedId()
Citizen.CreateThread(function()
	while PlayerData.job == nil do
		Citizen.Wait(500)
	end
	Citizen.Wait(1000)

	local lastCheck = 10
	while true do
		xpcall(function()
			local me = PlayerPedId()
			---------------------------------------
			-- attach if player has large weapon --
			---------------------------------------
			if IsEntityVisible(PlayerPedId()) and showweapon then
				local selectedWeapon = GetSelectedPedWeapon(me)
				for i=1, #PlayerData.loadout do
					local v = PlayerData.loadout[i]
					if SETTINGS.compatable_weapon_hashes[v.name] then
						local attachModel = SETTINGS.compatable_weapon_hashes[v.name]
						local weaponHash = GetHashKey(v.name)
						if (not Vehicle or IsBike) and weaponHash ~= selectedWeapon and not attached_weapons[attachModel] then
							local offsets = SETTINGS.offsets[attachModel] or {}
							AttachWeapon(
							attachModel,
							weaponHash,
							SETTINGS.back_bone,
							offsets.x or SETTINGS.x,
							offsets.y or SETTINGS.y,
							offsets.z or SETTINGS.z,
							offsets.xR or SETTINGS.x_rotation,
							offsets.yR or SETTINGS.y_rotation,
							offsets.zR or SETTINGS.z_rotation,
							isMeleeWeapon(v.name)
						)
						me = PlayerPedId()
					end
					local attached_object = attached_weapons[attachModel]
					if attached_object and (selectedWeapon == attached_object.hash or (Vehicle and not IsBike)) then
						local handle = DoesEntityExist(attached_object.handle) and attached_object.handle or NetworkGetEntityFromNetworkId(attached_object.netId)
						if not ESX.Game.TryDeleteEntity(handle) then
							ESX.Game.DeleteObject(handle)
						end
						attached_weapons[attachModel] = nil
					end
				end
			end
		end

		if lastCheck > 10 then
			lastCheck = 0
			PlayerData.loadout = ESX.GetPlayerDataKey("loadout")
			for k,v in pairs(attached_weapons) do
				if DoesEntityExist(v.handle) then
					DecorSetInt(v.handle, "_LAST_LEFT", GetTime())
					AttachEntityToEntity(v.handle, me, v.bone, v.x, v.y, v.z, v.xR, v.yR, v.zR, 1, 1, 0, 0, 2, 1)
				elseif NetworkDoesNetworkIdExist(v.netId) then
					v.handle = GetObjectFromWeaponData(v)
				else
					attached_weapons[k] = nil
				end
			end
		end
		lastCheck = lastCheck + 1

		if lastMe ~= PlayerPedId() then
			for name, attached_object in pairs(attached_weapons) do
				local handle = DoesEntityExist(attached_object.handle) and attached_object.handle or NetworkGetEntityFromNetworkId(attached_object.netId)
				if not ESX.Game.TryDeleteEntity(handle) then
					ESX.Game.DeleteObject(handle)
				end
				attached_weapons[name] = nil
			end
		end
		lastMe = me
	end, Traceback or debug.traceback)

	Wait(1000)
end
end)]]


AddEventHandler('onResourceStop', function(resourceName)
	if GetCurrentResourceName() == resourceName then
		if focus then
			ClearFocus()
		end

		for name, attached_object in pairs(attached_weapons) do
			DeleteObject(attached_object.handle)
			attached_weapons[name] = nil
		end
	end
end)

--[[function RemoveAllAttachedWeapons()
	for k,v in pairs(attached_weapons) do
		if DoesEntityExist(v.handle) then
			if not ESX.Game.TryDeleteEntity(v.handle) then
				ESX.Game.DeleteObject(v.handle)
			end
		end

		attached_weapons[k] = nil
	end

	local objects = GetGamePool("CObject")
	local attachModels = {}
	for k,v in pairs(SETTINGS.compatable_weapon_hashes) do
		attachModels[GetHashKey(v)] = true
	end
	for i=1, #objects do
		if GetEntityAttachedTo(objects[i]) == playerPed and attachModels[GetEntityModel(objects[i])] then
			if not ESX.Game.TryDeleteEntity(objects[i]) then
				ESX.Game.DeleteObject(objects[i])
			end
		end
	end
end

AddEventHandler('onNoclip', function(value)
	RemoveAllAttachedWeapons()
end)

function AttachWeapon(attachModel, modelHash, boneNumber, x, y, z, xR, yR, zR, isMelee)
	playerPed = PlayerPedId()
	local attachHash = GetHashKey(attachModel)
	local objects = GetGamePool("CObject")
	for i=1, #objects do
		if GetEntityAttachedTo(objects[i]) == playerPed and GetEntityModel(objects[i]) == attachHash then
			if not ESX.Game.TryDeleteEntity(objects[i]) then
				ESX.Game.DeleteObject(objects[i])
			end
		end
	end
	-- if GetPedDrawableVariation(playerPed, 5) ~= 0 then
	--     exports['esx_rpchat']:printToChat("WAPENS", "Rugtassen verbergen je wapen niet!", { r = 255 })
	-- end

	RequestModel(attachHash)
	local timeout = 0
	while not HasModelLoaded(attachHash) and timeout < 1000 do
		timeout = timeout + 100
		Wait(100)
	end

	local ped = PlayerPedId()
	local bone = GetPedBoneIndex(ped, boneNumber)
	local coords = GetEntityCoords(PlayerPedId())
	local object = CreateObject(attachHash, coords, true, true, false)
	local netId = NetworkGetNetworkIdFromEntity(object)
	attached_weapons[attachModel] = {
		hash = modelHash,
		handle = object,
		netId = netId,
		model = attachModel
	}

	if attachModel == "prop_ld_jerrycan_01" then
		x = x + 0.3
	end

	DecorSetInt(attached_weapons[attachModel].handle, "_LAST_LEFT", GetTime())
	NetworkSetNetworkIdDynamic(netId, true)
	SetNetworkIdCanMigrate(netId, false)

	SetEntityCollision(attached_weapons[attachModel].handle, false, false)
	attached_weapons[attachModel].x, attached_weapons[attachModel].y, attached_weapons[attachModel].z = x, y, z
	attached_weapons[attachModel].xR, attached_weapons[attachModel].yR, attached_weapons[attachModel].zR = xR, yR, zR
	attached_weapons[attachModel].bone = bone
	if attachHash == GetEntityModel(attached_weapons[attachModel].handle) then
		AttachEntityToEntity(attached_weapons[attachModel].handle, ped, bone, x, y, z, xR, yR, zR, 1, 1, 0, 0, 2, 1)
	end
	Citizen.Wait(500)

	local timeout = 0
	while not NetworkDoesNetworkIdExist(netId) and timeout < 1000 do
		Citizen.Wait(100)
		timeout = timeout + 100
	end

	if attached_weapons[attachModel] then
		attached_weapons[attachModel].handle = GetObjectFromWeaponData(attached_weapons[attachModel])
	end
end]]

AddEventHandler('updateTime', function(_time)
	UpdateTime(_time)
end)

local time = nil
function GetTime()
	-- 1590254141 is 23/05/2020, datetime should be higher than that
	if time and time < 1590254141 then
		return GetCloudTimeAsInt()
	end
	return time or GetCloudTimeAsInt()
end

function UpdateTime(_time)
	time = _time
end

function isMeleeWeapon(wep_name)
	if wep_name == "prop_golf_iron_01" then
		return true
	elseif wep_name == "w_me_bat" then
		return true
	elseif wep_name == "prop_ld_jerrycan_01" then
		return true
	elseif wep_name == "w_me_poolcue" then
		return true
	else
		return false
	end
end

local recoils = {
	[`WEAPON_PISTOL`] = 0.4, -- PISTOL
	[`WEAPON_PISTOL_MK2`] = 0.2, -- PISTOL MK2
    [`WEAPON_MACHINEPISTOL`] = 0.2, -- PISTOL MK2
    [`WEAPON_SPECIALCARBINE`] = 0.1, -- SCAR
    [`WEAPON_M4`] = 0.04, -- M4
	[`WEAPON_COMBATPISTOL`] = 0.2, -- COMBAT PISTOL
	[`WEAPON_APPISTOL`] = 0.15, -- AP PISTOL
	[2578377531] = 0.6, -- PISTOL .50
	[`WEAPON_MICROSMG`] = 0.2, -- MICRO SMG
	[`WEAPON_SMG`] = 0.085, -- SMG
	[2024373456] = 0.1, -- SMG MK2
	[4024951519] = 0.1, -- ASSAULT SMG
	[`WEAPON_ASSAULTRIFLE`] = 0.05, -- ASSAULT RIFLE
    [`WEAPON_ASSAULTRIFLE_MK2`] = 0.06, -- ASSAULT RIFLE MK2
    [`WEAPON_CARBINERIFLE`] = 0.06,
    [`WEAPON_CARBINERIFLE_MK2`] = 0.06,
    [`WEAPON_GUSENBERG`] = 0.1, -- GUSENBERG
    [`WEAPON_MINISMG`] = 0.1,
	[4208062921] = 0.1, -- CARBINE RIFLE MK2
    [2937143193] = 0.1, -- ADVANCED RIFLE
    [`WEAPON_COMPACTRIFLE`] = 0.08,
    [`WEAPON_MG`] = 0.08,
    [`WEAPON_COMBATMG`] = 0.1,
	[3686625920] = 0.1, -- COMBAT MG MK2
	[`WEAPON_PUMPSHOTGUN`] = 0.4, -- PUMP SHOTGUN
	[1432025498] = 0.4, -- PUMP SHOTGUN MK2
	[`WEAPON_SAWNOFFSHOTGUN`] = 1.4, -- SAWNOFF SHOTGUN
	[3800352039] = 0.4, -- ASSAULT SHOTGUN
	[2640438543] = 0.2, -- BULLPUP SHOTGUN
	[911657153] = 0.1, -- STUN GUN
	[`WEAPON_SNIPERRIFLE`] = 0.5, -- SNIPER RIFLE
	[`WEAPON_HEAVYSNIPER`] = 0.7, -- HEAVY SNIPER
	[177293209] = 0.7, -- HEAVY SNIPER MK2
	[856002082] = 1.2, -- REMOTE SNIPER
	[2726580491] = 1.0, -- GRENADE LAUNCHER
	[1305664598] = 1.0, -- GRENADE LAUNCHER SMOKE
	[2982836145] = 0.0, -- RPG
	[1752584910] = 0.0, -- STINGER
	[1119849093] = 0.01, -- MINIGUN
	[3218215474] = 0.2, -- SNS PISTOL
	[2009644972] = 0.25, -- SNS PISTOL MK2
	[3231910285] = 0.2, -- SPECIAL CARBINE
	[-1768145561] = 0.25, -- SPECIAL CARBINE MK2
	[3523564046] = 0.5, -- HEAVY PISTOL
	[2132975508] = 0.2, -- BULLPUP RIFLE
	[-2066285827] = 0.25, -- BULLPUP RIFLE MK2
	[137902532] = 0.4, -- VINTAGE PISTOL
	[-1746263880] = 0.4, -- DOUBLE ACTION REVOLVER
	[2828843422] = 0.7, -- MUSKET
	[984333226] = 0.2, -- HEAVY SHOTGUN
	[3342088282] = 0.3, -- MARKSMAN RIFLE
	[1785463520] = 0.35, -- MARKSMAN RIFLE MK2
	[1672152130] = 0, -- HOMING LAUNCHER
	[1198879012] = 0.9, -- FLARE GUN
	[171789620] = 0.2, -- COMBAT PDW
	[3696079510] = 0.9, -- MARKSMAN PISTOL
  	[1834241177] = 2.4, -- RAILGUN
	[3249783761] = 0.6, -- REVOLVER
	[-879347409] = 0.65, -- REVOLVER MK2
	[4019527611] = 0.7, -- DOUBLE BARREL SHOTGUN
	[1649403952] = 0.08, -- COMPACT RIFLE
	[317205821] = 0.2, -- AUTO SHOTGUN
	[125959754] = 0.5, -- COMPACT LAUNCHER
	[3173288789] = 0.1, -- MINI SMG
}

local shaking = {
    -- Pistols
    [`WEAPON_STUNGUN`] = 0.01,
    [`WEAPON_FLAREGUN`] = 0.01,
    [`WEAPON_SNSPISTOL`] = 0.02,
    [`WEAPON_SNSPISTOL_MK2`] = 0.025,
    [`WEAPON_PISTOL`] = 0.045,
    [`WEAPON_PISTOL_MK2`] = 0.045,
    [`WEAPON_APPISTOL`] = 0.05,
    [`WEAPON_COMBATPISTOL`] = 0.045,
    [`WEAPON_PISTOL50`] = 0.08,
    [`WEAPON_HEAVYPISTOL`] = 0.08,
    [`WEAPON_VINTAGEPISTOL`] = 0.025,
    [`WEAPON_MARKSMANPISTOL`] = 0.03,
    [`WEAPON_REVOLVER`] = 0.045,
    [`WEAPON_REVOLVER_MK2`] = 0.055,
    [`WEAPON_DOUBLEACTION`] = 0.025,
    -- SMG's
    [`WEAPON_MICROSMG`] = 0.035,
    [`WEAPON_COMBATPDW`] = 0.045,
    [`WEAPON_SMG`] = 0.035,
    [`WEAPON_SMG_MK2`] = 0.055,
    [`WEAPON_ASSAULTSMG`] = 0.050,
    [`WEAPON_MACHINEPISTOL`] = 0.045,
    [`WEAPON_MINISMG`] = 0.045,
    [`WEAPON_MG`] = 0.05,
    [`WEAPON_COMBATMG`] = 0.06,
    [`WEAPON_COMBATMG_MK2`] = 0.085,
    -- Rifles
    [`WEAPON_ASSAULTRIFLE`] = 0.03,
    [`WEAPON_ASSAULTRIFLE_MK2`] = 0.045,
    [`WEAPON_CARBINERIFLE`] = 0.04,
    [`WEAPON_CARBINERIFLE_MK2`] = 0.045,
    [`WEAPON_ADVANCEDRIFLE`] = 0.03,
    [`WEAPON_GUSENBERG`] = 0.04,
    [`WEAPON_SPECIALCARBINE`] = 0.055,
    [`WEAPON_SPECIALCARBINE_MK2`] = 0.045,
    [`WEAPON_BULLPUPRIFLE`] = 0.05,
    [`WEAPON_BULLPUPRIFLE_MK2`] = 0.065,
    [`WEAPON_COMPACTRIFLE`] = 0.03,
    -- Shotgun
    [`WEAPON_PUMPSHOTGUN`] = 0.09,
    [`WEAPON_PUMPSHOTGUN_MK2`] = 0.095,
    [`WEAPON_SAWNOFFSHOTGUN`] = 0.095,
    [`WEAPON_ASSAULTSHOTGUN`] = 0.11,
    [`WEAPON_BULLPUPSHOTGUN`] = 0.08,
    [`WEAPON_DBSHOTGUN`] = 0.06,
    [`WEAPON_AUTOSHOTGUN`] = 0.08,
    [`WEAPON_MUSKET`] = 0.12,
    [`WEAPON_HEAVYSHOTGUN`] = 0.13,
    -- Snipers
    [`WEAPON_SNIPERRIFLE`] = 0.2,
    [`WEAPON_HEAVYSNIPER`] = 0.3,
    [`WEAPON_HEAVYSNIPER_MK2`] = 0.35,
    [`WEAPON_MARKSMANRIFLE`] = 0.1,
    [`WEAPON_MARKSMANRIFLE_MK2`] = 0.1,
    -- Launcher
    [`WEAPON_GRENADELAUNCHER`] = 0.08,
    [`WEAPON_RPG`] = 0.9,
    [`WEAPON_HOMINGLAUNCHER`] = 0.9,
    [`WEAPON_MINIGUN`] = 0.2,
    [`WEAPON_RAILGUN`] = 1.0,
    [`WEAPON_COMPACTLAUNCHER`] = 0.7,
    [`WEAPON_FIREWORK`] = 0.2
}

local recoils2 = {
	[453432689] = 1.0, -- PISTOL
	[3219281620] = 1.0, -- PISTOL MK2
	[1593441988] = 1.0, -- COMBAT PISTOL
	[584646201] = 0.1, -- AP PISTOL
	[2578377531] = 0.6, -- PISTOL .50
	[324215364] = 0.6, -- MICRO SMG
	[736523883] = 0.15, -- SMG
	[2024373456] = 0.1, -- SMG MK2
	[4024951519] = 0.3, -- ASSAULT SMG
	[-1074790547] = 0.20, -- ASSAULT RIFLE
	[961495388] = 0.10, -- ASSAULT RIFLE MK2
	[2210333304] = 0.0, -- CARBINE RIFLE
	[-86904375] = 0.10, -- CARBINE RIFLE MK2
	[2937143193] = 0.1, -- ADVANCED RIFLE
	[2634544996] = 5.1, -- MG
	[2144741730] = 0.6, -- COMBAT MG
	[3686625920] = 0.1, -- COMBAT MG MK2
	[487013001] = 5.0, -- PUMP SHOTGUN
	[1432025498] = 0.35, -- PUMP SHOTGUN MK2
	[2017895192] = 1.2, -- SAWNOFF SHOTGUN
	[3800352039] = 10.8, -- ASSAULT SHOTGUN
	[2640438543] = 0.2, -- BULLPUP SHOTGUN
	[911657153] = 0.1, -- STUN GUN
	[100416529] = 7.5, -- SNIPER RIFLE
	[205991906] = 7.5, -- HEAVY SNIPER
	[177293209] = 0.6, -- HEAVY SNIPER MK2
	[856002082] = 1.2, -- REMOTE SNIPER
	[2726580491] = 1.0, -- GRENADE LAUNCHER
	[1305664598] = 1.0, -- GRENADE LAUNCHER SMOKE
	[2982836145] = 2.5, -- RPG
	[1752584910] = 0.0, -- STINGER
	[1119849093] = 0.05, -- MINIGUN
	[3218215474] = 2.1, -- SNS PISTOL
	[1627465347] = 0.1, -- GUSENBERG
	[-2084633992] = 0.1, -- SPECIAL CARBINE
	[-1768145561] = 0.01, -- SPECIAL CARBINE MK2
	[3523564046] = 0.5, -- HEAVY PISTOL
	[2132975508] = 0.2, -- BULLPUP RIFLE
	[-2066285827] = 0.15, -- BULLPUP RIFLE MK2
	[137902532] = 0.4, -- VINTAGE PISTOL
	[2828843422] = 2.75, -- MUSKET
	[984333226] = 0.2, -- HEAVY SHOTGUN
	[3342088282] = 0.3, -- MARKSMAN RIFLE
	[1785463520] = 0.25, -- MARKSMAN RIFLE MK2
	[1672152130] = 0, -- HOMING LAUNCHER
	[1198879012] = 0.9, -- FLARE GUN
	[171789620] = 0.2, -- COMBAT PDW
	[3696079510] = 0.9, -- MARKSMAN PISTOL
	[1834241177] = 3.5, -- RAILGUN
	[3675956304] = 0.3, -- MACHINE PISTOL
	[3249783761] = 0.6, -- REVOLVER
	[-879347409] = 0.6, -- REVOLVER MK2
	[4019527611] = 0.7, -- DOUBLE BARREL SHOTGUN
	[1649403952] = 0.50, -- COMPACT RIFLE
	[317205821] = 0.2, -- AUTO SHOTGUN
	[125959754] = 0.5, -- COMPACT LAUNCHER
	[-1121678507] = 0.5,	 -- MINI SMG		
}

local recoilsGrip = {
	[453432689] = 1.0, -- PISTOL
	[1593441988] = 1.0, -- COMBAT PISTOL
	[584646201] = 0.1, -- AP PISTOL
	[2578377531] = 0.6, -- PISTOL .50
	[324215364] = 0.3, -- MICRO SMG
	[736523883] = 0.1, -- SMG
	[2024373456] = 0.1, -- SMG MK2
	[4024951519] = 0.3, -- ASSAULT SMG
	[-1074790547] = 0.10, -- ASSAULT RIFLE
	[961495388] = 0.05, -- ASSAULT RIFLE MK2
	[2210333304] = 0.0, -- CARBINE RIFLE
	[-86904375] = 0.05, -- CARBINE RIFLE MK2
	[2937143193] = 0.1, -- ADVANCED RIFLE
	[2634544996] = 5.1, -- MG
	[2144741730] = 0.6, -- COMBAT MG
	[3686625920] = 0.1, -- COMBAT MG MK2
	[487013001] = 5.0, -- PUMP SHOTGUN
	[1432025498] = 0.35, -- PUMP SHOTGUN MK2
	[2017895192] = 1.2, -- SAWNOFF SHOTGUN
	[3800352039] = 10.8, -- ASSAULT SHOTGUN
	[2640438543] = 0.2, -- BULLPUP SHOTGUN
	[911657153] = 0.1, -- STUN GUN
	[100416529] = 7.5, -- SNIPER RIFLE
	[205991906] = 7.5, -- HEAVY SNIPER
	[177293209] = 0.6, -- HEAVY SNIPER MK2
	[856002082] = 1.2, -- REMOTE SNIPER
	[2726580491] = 1.0, -- GRENADE LAUNCHER
	[1305664598] = 1.0, -- GRENADE LAUNCHER SMOKE
	[2982836145] = 2.5, -- RPG
	[1752584910] = 0.0, -- STINGER
	[1119849093] = 0.05, -- MINIGUN
	[3218215474] = 2.1, -- SNS PISTOL
	[1627465347] = 0.1, -- GUSENBERG
	[-2084633992] = 0.1, -- SPECIAL CARBINE
	[-1768145561] = 0.01, -- SPECIAL CARBINE MK2
	[3523564046] = 0.5, -- HEAVY PISTOL
	[2132975508] = 0.2, -- BULLPUP RIFLE
	[-2066285827] = 0.15, -- BULLPUP RIFLE MK2
	[137902532] = 0.4, -- VINTAGE PISTOL
	[2828843422] = 2.75, -- MUSKET
	[984333226] = 0.2, -- HEAVY SHOTGUN
	[3342088282] = 0.3, -- MARKSMAN RIFLE
	[1785463520] = 0.25, -- MARKSMAN RIFLE MK2
	[1672152130] = 0, -- HOMING LAUNCHER
	[1198879012] = 0.9, -- FLARE GUN
	[171789620] = 0.2, -- COMBAT PDW
	[3696079510] = 0.9, -- MARKSMAN PISTOL
	[1834241177] = 3.5, -- RAILGUN
	[3675956304] = 0.3, -- MACHINE PISTOL
	[3249783761] = 0.6, -- REVOLVER
	[-879347409] = 0.6, -- REVOLVER MK2
	[4019527611] = 0.7, -- DOUBLE BARREL SHOTGUN
	[1649403952] = 0.50, -- COMPACT RIFLE
	[317205821] = 0.2, -- AUTO SHOTGUN
	[125959754] = 0.5, -- COMPACT LAUNCHER
	[-1121678507] = 0.5,	 -- MINI SMG		
}


local globalRecoilModifiers = {
	grip = 0.1,
	suppressor = 0.1,
	brake_1 = 0.2,
	brake_2 = 0.2,
	brake_3 = 0.2,
	brake_4 = 0.2,
	brake_5 = 0.2,
	brake_6 = 0.2,
	brake_7 = 0.2,
	barrel_heavy = 0.1,
}

function GetWeapon(weaponHashOrName)
	for i=1, #PlayerData.loadout do
		if PlayerData.loadout[i].hash == weaponHashOrName or PlayerData.loadout[i].name == weaponHashOrName then
			return PlayerData.loadout[i]
		end
	end
end

local recoilModifiersByWeapon = {
	[`WEAPON_ASSAULTRIFLE_MK2`] = {
		grip = 0.2,
		suppressor = 0.2,
	},
	[`WEAPON_PISTOL`] = {
		suppressor = 0.2,
		clip_extended = 0.05,
	},
	[`WEAPON_PISTOL_MK2`] = {
		suppressor = 0.2,
		brake_1 = 0.3,
		clip_extended = 0.05,
	}
}

local globalRecoilModifiers = {
	grip = 0.1,
	suppressor = 0.1,
	brake_1 = 0.2,
	brake_2 = 0.2,
	brake_3 = 0.2,
	brake_4 = 0.2,
	brake_5 = 0.2,
	brake_6 = 0.2,
	brake_7 = 0.2,
	barrel_heavy = 0.1,
}

function GetRecoilModifier(weaponHash)
	local weapon = GetWeapon(weaponHash)
	local recoilModifiers = recoilModifiersByWeapon[weaponHash]
	local recoil = 1.0

	if not weapon or not weapon.components then
		return recoil
	end

	for i=1, #weapon.components do
		local component = weapon.components[i]
		print(component)
		if recoilModifiers and recoilModifiers[component] then
			recoil = recoil - recoilModifiers[component]
		elseif globalRecoilModifiers[component] then
			recoil = recoil - globalRecoilModifiers[component]
		end
	end
    print(recoil)
	return recoil
end

local recoilRunning = false
local recoil = 0
local lastShake = 0
function ManageRecoil(weapon)
    if recoils[weapon] and recoils[weapon] ~= 0 then
        local recoilModifier = GetRecoilModifier(weaponHash)
        recoil = (math.random(5, 15) / 10) * recoils[weapon]

        if GetCamViewMode() ~= 4 then
            recoil = recoil * 4
        elseif Vehicle then
            recoil = 1 * 4
            print("vehicle")
        end
        if not recoilRunning then
            recoilRunning = true
            Citizen.CreateThread(function()
                if GetFollowPedCamViewMode() ~= 4 then
                    recoil = recoil * 3
                end
                while recoil > 0.0 do
                    Wait(0)
                    local p = GetGameplayCamRelativePitch()
                    if recoil > 1.0 then
                        p = p + (recoil / 6) * recoilModifier
                        recoil = recoil / 6
                    else
                        p = p + math.min(0.2, recoil) * recoilModifier
                        recoil = recoil - 0.2
                    end

                    SetGameplayCamRelativePitch(p, 1.0)

                end
                recoilRunning = false
            end)
        else
            recoil = recoil + ((math.random(5, 15) / 10) * recoils[weapon])
        end
    end
    -- Weapon shake script
    local multiplier = 1
    DisableAimCamThisUpdate()
    if GetFollowPedCamViewMode() ~= 4 then
        multiplier = 4
    end

    if shaking[weapon] and GetGameTimer() - lastShake > 50 then
        lastShake = GetGameTimer()
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', shaking[weapon] * multiplier)
    end

    if weapon == `WEAPON_FIREEXTINGUISHER` then
        SetPedInfiniteAmmo(PlayerPedId(), true, `WEAPON_FIREEXTINGUISHER`)
    end
end

function ManageReticle2()
    local ped = GetPlayerPed( -1 )
    local _, hash = GetCurrentPedWeapon( ped, true )
        if not HashInTable( hash ) then 
            HideHudComponentThisFrame( 14 )
		end 
end 

function ManageRecoil2(wep)
    if not HashInTable( hash ) then 
        HideHudComponentThisFrame( 14 )
    end 
    local ped = PlayerPedId()
    if HasPedGotWeaponComponent(ped, GetSelectedPedWeapon(ped), GetHashKey('COMPONENT_AT_AR_AFGRIP')) then
        _,cAmmo = GetAmmoInClip(ped, wep)
        if recoilsGrip[wep] and recoilsGrip[wep] ~= 0 then
            tv = 0
            if GetFollowPedCamViewMode() ~= 4 then
                repeat 
                    Wait(0)
                    p = GetGameplayCamRelativePitch()
                    SetGameplayCamRelativePitch(p+0.1, 0.2)
                    tv = tv+0.1
                until tv >= recoilsGrip[wep]
            else
                repeat 
                    Wait(0)
                    p = GetGameplayCamRelativePitch()
                    if recoilsGrip[wep] > 0.1 then
                        SetGameplayCamRelativePitch(p+0.6, 1.2)
                        tv = tv+0.6
                    else
                        SetGameplayCamRelativePitch(p+0.016, 0.333)
                        tv = tv+0.1
                    end
                until tv >= recoilsGrip[wep]
            end
        end
    else
        _,cAmmo = GetAmmoInClip(ped, wep)
        if recoils2[wep] and recoils2[wep] ~= 0 then
            tv = 0
            if GetFollowPedCamViewMode() ~= 4 then
                repeat 
                    Wait(0)
                    p = GetGameplayCamRelativePitch()
                    SetGameplayCamRelativePitch(p+0.1, 0.2)
                    tv = tv+0.1
                until tv >= recoils2[wep]
            else
                repeat 
                    Wait(0)
                    p = GetGameplayCamRelativePitch()
                    if recoils2[wep] > 0.1 then
                        SetGameplayCamRelativePitch(p+0.6, 1.2)
                        tv = tv+0.6
                    else
                        SetGameplayCamRelativePitch(p+0.016, 0.333)
                        tv = tv+0.1
                    end
                until tv >= recoils2[wep]
            end
        end
    end

    ManageReticle2()
    if IsPedArmed(ped, 6) then
        DisableControlAction(1, 140, true)
        DisableControlAction(1, 141, true)
        DisableControlAction(1, 142, true)
    end
    DisplayAmmoThisFrame(false)

    local weapon = GetSelectedPedWeapon(ped)
    if weapon == GetHashKey("WEAPON_STUNGUN") then
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.01)
    end
    
    if weapon == GetHashKey("WEAPON_FLAREGUN") then	
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.01)
    end
    
    if weapon == GetHashKey("WEAPON_SNSPISTOL") then		
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.02)
    end
    
    if weapon == GetHashKey("WEAPON_SNSPISTOL_MK2") then		
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.025)
    end
    
    if weapon == GetHashKey("WEAPON_PISTOL") then		
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.035)
    end
    
    if weapon == GetHashKey("WEAPON_PISTOL_MK2") then
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.03)
    end
    
    if weapon == GetHashKey("WEAPON_APPISTOL") then
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.05)
    end
    
    if weapon == GetHashKey("WEAPON_COMBATPISTOL") then		
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.035)
    end
    
    if weapon == GetHashKey("WEAPON_PISTOL50") then
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.05)
    end
    
    if weapon == GetHashKey("WEAPON_HEAVYPISTOL") then		
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.03)
    end
    
    if weapon == GetHashKey("WEAPON_VINTAGEPISTOL") then		
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.025)
    end
    
    if weapon == GetHashKey("WEAPON_MARKSMANPISTOL") then		
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.03)
    end
    
    if weapon == GetHashKey("WEAPON_REVOLVER") then	
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.055)
    end
    
    if weapon == GetHashKey("WEAPON_REVOLVER_MK2") then	
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.055)
    end
    
    if weapon == GetHashKey("WEAPON_DOUBLEACTION") then	
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.025)
    end
    -- SMG
    
    if weapon == GetHashKey("WEAPON_MICROSMG") then	
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.040)
    end
    
    if weapon == GetHashKey("WEAPON_COMBATPDW") then			
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.045)
    end
    
    if weapon == GetHashKey("WEAPON_SMG") then
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.035)
    end
    
    if weapon == GetHashKey("WEAPON_SMG_MK2") then	
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.055)
    end
    
    if weapon == GetHashKey("WEAPON_ASSAULTSMG") then	
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.050)
    end
    
    if weapon == GetHashKey("WEAPON_MACHINEPISTOL") then		
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.035)
    end
    
    if weapon == GetHashKey("WEAPON_MINISMG") then
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.035)
    end
    
    if weapon == GetHashKey("WEAPON_MG") then
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.03)
    end
    
    if weapon == GetHashKey("WEAPON_COMBATMG") then		
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.04)
    end
    
    if weapon == GetHashKey("WEAPON_COMBATMG_MK2") then			
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.085)
    end
    
    -- Rifles
    
    if weapon == GetHashKey("WEAPON_ASSAULTRIFLE") then			
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.015)
    end
    
    if weapon == GetHashKey("WEAPON_ASSAULTRIFLE_MK2") then			
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.015)
    end
    
    if weapon == GetHashKey("WEAPON_CARBINERIFLE") then	
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.00)
    end
    
    if weapon == GetHashKey("WEAPON_CARBINERIFLE_MK2") then			
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.035)
    end
    
    if weapon == GetHashKey("WEAPON_ADVANCEDRIFLE") then		
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.06)
    end
    
    if weapon == GetHashKey("WEAPON_GUSENBERG") then		
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.05)
    end
    
    if weapon == GetHashKey("WEAPON_SPECIALCARBINE") then		
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.03)
    end
    
    if weapon == GetHashKey("WEAPON_SPECIALCARBINE_MK2") then		
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.075)
    end
    
    if weapon == GetHashKey("WEAPON_BULLPUPRIFLE") then			
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.05)
    end
    
    if weapon == GetHashKey("WEAPON_BULLPUPRIFLE_MK2") then			
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.065)
    end
    
    if tonumber(weapon) == tonumber(GetHashKey("WEAPON_COMPACTRIFLE")) then		
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.07)
    end
    
    -- Shotgun
    
    if weapon == GetHashKey("WEAPON_PUMPSHOTGUN") then
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.07)
    end
    
    if weapon == GetHashKey("WEAPON_PUMPSHOTGUN_MK2") then
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.085)
    end
    
    if weapon == GetHashKey("WEAPON_SAWNOFFSHOTGUN") then
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.10)
    end
    
    if weapon == GetHashKey("WEAPON_ASSAULTSHOTGUN") then	
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.12)
    end
    
    if weapon == GetHashKey("WEAPON_BULLPUPSHOTGUN") then		
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.15)
    end
    
    if weapon == GetHashKey("WEAPON_DBSHOTGUN") then	
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.05)
    end
    
    if weapon == GetHashKey("WEAPON_AUTOSHOTGUN") then	
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08)
    end
    
    if weapon == GetHashKey("WEAPON_MUSKET") then
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.50)
    end
    
    if weapon == GetHashKey("WEAPON_HEAVYSHOTGUN") then	
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.13)
    end
    
    -- Sniper
    
    if weapon == GetHashKey("WEAPON_SNIPERRIFLE") then
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.5)
    end
    
    if weapon == GetHashKey("WEAPON_HEAVYSNIPER") then	
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.5)
    end
    
    if weapon == GetHashKey("WEAPON_HEAVYSNIPER_MK2") then
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.35)
    end
    
    if weapon == GetHashKey("WEAPON_MARKSMANRIFLE") then			
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.1)
    end
    
    if weapon == GetHashKey("WEAPON_MARKSMANRIFLE_MK2") then			
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.1)
    end
    
    -- Launcher
    
    if weapon == GetHashKey("WEAPON_GRENADELAUNCHER") then		
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08)
    end
    
    if weapon == GetHashKey("WEAPON_RPG") then
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 2.5)
    end
    
    if weapon == GetHashKey("WEAPON_HOMINGLAUNCHER") then		
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 2.5)
    end
    
    if weapon == GetHashKey("WEAPON_MINIGUN") then	
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.40)
    end
    
    if weapon == GetHashKey("WEAPON_RAILGUN") then	
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.8)
    end
    
    if weapon == GetHashKey("WEAPON_COMPACTLAUNCHER") then		
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08)
    end
    
    if weapon == GetHashKey("WEAPON_FIREWORK") then	
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.5)
    end
end    

local scopedWeapons = 
{
    100416529,  -- WEAPON_SNIPERRIFLE
    205991906,  -- WEAPON_HEAVYSNIPER
    3342088282, -- WEAPON_MARKSMANRIFLE
	177293209,   -- WEAPON_HEAVYSNIPER MKII
	1785463520  -- WEAPON_MARKSMANRIFLE_MK2
}

function HashInTable( hash )
    for k, v in pairs( scopedWeapons ) do 
        if ( hash == v ) then 
            return true 
        end 
    end 

    return false 
end  

RegisterCommand('getdumpster', function()
    local NewBin, NewBinDistance = ESX.Game.GetClosestObject()
    local trashcollectionpos = GetEntityCoords(NewBin)
    local start = GetGameTimer()
    local model = GetEntityModel(NewBin)
    print(tostring(NewBin) .. ' : ' .. tostring(trafficLightObjects[model]))
    Citizen.CreateThread(function()
        print(tostring(model))
        print(tostring(GetEntityCoords(NewBin)))
        print(tostring(GetEntityRotation(NewBin)))
        print(tostring(NetworkGetEntityIsNetworked(NewBin)))
        while GetGameTimer() - start < 5000 do
            Citizen.Wait(0)
            ESX.Game.Utils.DrawText3D(trashcollectionpos, tostring(model))
        end
    end)
end)
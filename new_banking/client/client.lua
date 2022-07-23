--================================================================================================
--==                                VARIABLES - DO NOT EDIT                                     ==
--================================================================================================
local inMenu	= false
local showblips	= true
local atbank	= false
local bankMenu	= true
local pinCard = `prop_cs_credit_card`
local banks = {
	{name="Bank", id=207, x=150.266, y=-1040.203, z=29.374},
	{name="Bank", id=207, x=-1212.980, y=-330.841, z=37.787},
	{name="Bank", id=207, x=-2962.582, y=482.627, z=15.703},
	{name="Bank", id=207, x=-112.202, y=6469.295, z=31.626},
	{name="Bank", id=207, x=314.187, y=-278.621, z=54.170},
	{name="Bank", id=207, x=-351.534, y=-49.529, z=49.042},
	{name="Bank", id=207, x=241.727, y=220.706, z=106.286, principal = true},
	{name="Bank", id=207, x=1175.0643310547, y=2706.6435546875, z=38.094036102295}
}

local atms = {
	{name="ATM", id=277, x=-1110.950, y=-836.270, z=19.000},
	{name="ATM", id=277, x=-1848.57, y=-1197.31, z=14.32},
	{name="ATM", id=277, x=-1817.99, y=-1189.96, z=14.32},
	{name="ATM", id=277, x=-386.733, y=6045.953, z=31.501},
    {name="ATM", id=277, x=4493.6963, y=-4525.2759, z=4.4063},
	{name="ATM", id=277, x=-284.037, y=6224.385, z=31.187},
	{name="ATM", id=277, x=-284.037, y=6224.385, z=31.187},
	{name="ATM", id=277, x=-135.165, y=6365.738, z=31.101},
	{name="ATM", id=277, x=-110.753, y=6467.703, z=31.784},
	{name="ATM", id=277, x=-94.9690, y=6455.301, z=31.784},
	{name="ATM", id=277, x=155.4300, y=6641.991, z=31.784},
	{name="ATM", id=277, x=174.6720, y=6637.218, z=31.784},
	{name="ATM", id=277, x=1703.138, y=6426.783, z=32.730},
	{name="ATM", id=277, x=1735.114, y=6411.035, z=35.164},
	{name="ATM", id=277, x=1702.842, y=4933.593, z=42.051},
	{name="ATM", id=277, x=1967.333, y=3744.293, z=32.272},
	{name="ATM", id=277, x=1821.917, y=3683.483, z=34.244},
	{name="ATM", id=277, x=1174.532, y=2705.278, z=38.027},
	{name="ATM", id=277, x=540.0420, y=2671.007, z=42.177},
	{name="ATM", id=277, x=2564.399, y=2585.100, z=38.016},
	{name="ATM", id=277, x=2558.683, y=349.6010, z=108.050},
	{name="ATM", id=277, x=2558.051, y=389.4817, z=108.660},
	{name="ATM", id=277, x=1077.692, y=-775.796, z=58.218},
	{name="ATM", id=277, x=1139.018, y=-469.886, z=66.789},
	{name="ATM", id=277, x=1168.975, y=-457.241, z=66.641},
	{name="ATM", id=277, x=1153.884, y=-326.540, z=69.245},
	{name="ATM", id=277, x=381.2827, y=323.2518, z=103.270},
	{name="ATM", id=277, x=236.4638, y=217.4718, z=106.840},
	{name="ATM", id=277, x=265.0043, y=212.1717, z=106.780},
	{name="ATM", id=277, x=285.2029, y=143.5690, z=104.970},
	{name="ATM", id=277, x=157.7698, y=233.5450, z=106.450},
	{name="ATM", id=277, x=-164.568, y=233.5066, z=94.919},
	{name="ATM", id=277, x=-1827.04, y=785.5159, z=138.020},
	{name="ATM", id=277, x=-1409.39, y=-99.2603, z=52.473},
	{name="ATM", id=277, x=-1205.35, y=-325.579, z=37.870},
	{name="ATM", id=277, x=-1215.64, y=-332.231, z=37.881},
	{name="ATM", id=277, x=-2072.41, y=-316.959, z=13.345},
	{name="ATM", id=277, x=-2975.72, y=379.7737, z=14.992},
	{name="ATM", id=277, x=-2962.60, y=482.1914, z=15.762},
	{name="ATM", id=277, x=-2955.70, y=488.7218, z=15.486},
	{name="ATM", id=277, x=-3044.22, y=595.2429, z=7.595},
	{name="ATM", id=277, x=-3144.13, y=1127.415, z=20.868},
	{name="ATM", id=277, x=-3241.10, y=996.6881, z=12.500},
	{name="ATM", id=277, x=-3241.11, y=1009.152, z=12.877},
	{name="ATM", id=277, x=-1305.40, y=-706.240, z=25.352},
	{name="ATM", id=277, x=-538.225, y=-854.423, z=29.234},
	{name="ATM", id=277, x=-711.156, y=-818.958, z=23.768},
	{name="ATM", id=277, x=-717.614, y=-915.880, z=19.268},
	{name="ATM", id=277, x=-526.566, y=-1222.90, z=18.434},
	{name="ATM", id=277, x=-256.831, y=-719.646, z=33.444},
	{name="ATM", id=277, x=-203.548, y=-861.588, z=30.205},
	{name="ATM", id=277, x=112.4102, y=-776.162, z=31.427},
	{name="ATM", id=277, x=112.9290, y=-818.710, z=31.386},
	{name="ATM", id=277, x=119.9000, y=-883.826, z=31.191},
	{name="ATM", id=277, x=-846.304, y=-340.402, z=38.687},
	{name="ATM", id=277, x=-1204.35, y=-324.391, z=37.877},
	{name="ATM", id=277, x=-1216.27, y=-331.461, z=37.773},
	{name="ATM", id=277, x=-56.1935, y=-1752.53, z=29.452},
	{name="ATM", id=277, x=-261.692, y=-2012.64, z=30.121},
	{name="ATM", id=277, x=-273.001, y=-2025.60, z=30.197},
	{name="ATM", id=277, x=314.187, y=-278.621, z=54.170},
	{name="ATM", id=277, x=-351.534, y=-49.529, z=49.042},
	{name="ATM", id=277, x=24.589, y=-946.056, z=29.357},
	{name="ATM", id=277, x=-254.112, y=-692.483, z=33.616},
	{name="ATM", id=277, x=-1570.197, y=-546.651, z=34.955},
	{name="ATM", id=277, x=-1415.909, y=-211.825, z=46.500},
	{name="ATM", id=277, x=-1430.112, y=-211.014, z=46.500},
	{name="ATM", id=277, x=33.232, y=-1347.849, z=29.497},
	{name="ATM", id=277, x=128.41, y=-1294.31, z=29.269, radius = 2.0},
	{name="ATM", id=277, x=287.645, y=-1282.646, z=29.659},
	{name="ATM", id=277, x=289.012, y=-1256.545, z=29.440},
	{name="ATM", id=277, x=295.839, y=-895.640, z=29.217},
	{name="ATM", id=277, x=1686.753, y=4815.809, z=42.008},
	{name="ATM", id=277, x=-302.408, y=-829.945, z=32.417},
	{name="ATM", id=277, x=5.134, y=-919.949, z=29.557},
	{name="ATM", id=277, x=527.26, y=-160.76, z=57.09},
	
	{name="ATM", id=277, x=-867.19, y=-186.99, z=37.84},
	{name="ATM", id=277, x=-821.62, y=-1081.88, z=11.13},
	{name="ATM", id=277, x=-1315.32, y=-835.96, z=16.96},
	{name="ATM", id=277, x=-660.71, y=-854.06, z=24.48},
	{name="ATM", id=277, x=-1109.73, y=-1690.81, z=4.37},
	{name="ATM", id=277, x=-1091.5, y=2708.66, z=18.95},
	{name="ATM", id=277, x=1171.98, y=2702.55, z=38.18},
	{name="ATM", id=277, x=2683.09, y=3286.53, z=55.24},
	{name="ATM", id=277, x=89.61, y=2.37, z=68.31},
	{name="ATM", id=277, x=-30.3, y=-723.76, z=44.23},
	{name="ATM", id=277, x=-28.07, y=-724.61, z=44.23},
	{name="ATM", id=277, x=-613.24, y=-704.84, z=31.24},
	{name="ATM", id=277, x=-618.84, y=-707.9, z=30.5},
	{name="ATM", id=277, x=-1289.23, y=-226.77, z=42.45},
	{name="ATM", id=277, x=-1285.6, y=-224.28, z=42.45},
	{name="ATM", id=277, x=-1286.24, y=-213.39, z=42.45},
	{name="ATM", id=277, x=-1282.54, y=-210.45, z=42.45},

	{name="ATM", id=277, x=206.24, y=-790.53, z=30.02},
	{name="ATM", id=277, x=437.07, y=-1968.01, z=22.17},
	{name="ATM", id=277, x=-1087.68, y=-1253.17, z=4.43},
	{name="ATM", id=277, x=-335.34, y=-786.06, z=32.96},
	{name="ATM", id=277, x=659.68, y=595.42, z=129.05},
	{name="ATM", id=277, x=1696.55, y=3596.84, z=34.61},

	{name="ATM", id=277, x=-1074.110, y=-827.350, z=19.040},
	{name="ATM", id=277, x=-549.750, y=-204.440, z=38.220},
	{name="ATM", id=277, x=-355.610, y=-130.610, z=39.440},
	{name="ATM", id=277, x=187.55, y=-899.82, z=29.71},
	{name="ATM", id=277, x=-301.16, y=6258.06, z=33.89},
	{name="ATM", id=277, x=-65.16471, y=882.1944, z=236.2075},

	{name="ATM", id=277, x=285.96, y=-1155.67, z=29.29},

}
local nearBank, nearATM
--================================================================================================
--==                                THREADING - DO NOT EDIT                                     ==
--================================================================================================

--===============================================
--==           Base ESX Threading              ==
--===============================================
if not ESX then
	Citizen.CreateThread(function()
		while not ESX do
			TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
			Citizen.Wait(500)
		end
	end)
end

AddEventHandler('onResourceStop', function(resourceName)
	if inMenu and resourceName == GetCurrentResourceName() then
		SetNuiFocus(false, false)
	end
end)

local playerPed
local playerCoords
local minDistance
local Loaded = false


--===============================================
--==             Core Threading                ==
--===============================================
if bankMenu then
	local thread
	Citizen.CreateThread(function()
		for k,v in pairs(banks) do
			banks[k].coords = vector3(v.x, v.y, v.z)
			banks[k].x, banks[k].y, banks[k].z = nil, nil, nil
		end
		for k,v in pairs(atms) do
			if not atms[k].coords then
				atms[k].coords = vector3(v.x, v.y, v.z)
				atms[k].x, atms[k].y, atms[k].z = nil, nil, nil
			end
		end
		Loaded = true
		thread:start()
	end)

	local function keyThread(thread)
		minDistance = 1000
		playerPed = PlayerPedId()
		playerCoords = GetEntityCoords(playerPed)
		local nearAtm = nearATM()
		local nearBank = nearBank()
		if not inMenu and not Vehicle.Get() and (nearBank or nearAtm) then
			DisplayHelpText("Druk op ~INPUT_PICKUP~ om gebruik te maken van de bank~b~")

			if IsControlJustPressed(1, 38) then
				IsReadyForPin(nearAtm, function()
					inMenu = true
					SetNuiFocus(true, true)
					SendNUIMessage({type = 'openGeneral'})
					TriggerServerEvent('bank:balance')
					TriggerScreenblurFadeIn(300.00)
					if nearAtm then
						Citizen.CreateThread(function()
							Citizen.Wait(2500)
							DeletePinObj()
						end)
					end
				end)
			end
		end

		if inMenu then
			minDistance = 0
		end

		if minDistance > 50.0 or Vehicle.Get() then
			return minDistance ^ 1.2 * 12.0
		end
	end

	thread = Thread:new(keyThread, "keyThread")
	thread:useTicker()
	thread:stopTicker()
end

local pinProp = nil

function IsReadyForPin(nearAtm, cb)
	local objects = ESX.Game.GetObjectsInArea(GetEntityCoords(playerPed), 15.0, {`prop_atm_01`, `prop_atm_02`, `prop_atm_03`, `prop_fleeca_atm`})
	local canPin, heading, coords, object = HandleAtmChoice(objects)
	if nearAtm and canPin and heading and coords then
		CreatePinObj()
		SetPlayerControl(PlayerId(), false, 6016)
		local sequence = OpenSequenceTask()
		TaskGoStraightToCoord(0, coords.x, coords.y, coords.z + 1.0, 1.0, 7500, heading, 1.2)
		TaskStartScenarioInPlace(0, "PROP_HUMAN_ATM", -1, true)
		CloseSequenceTask(sequence)
		TaskPerformSequence(playerPed, sequence)
		local startTimer = GetGameTimer()
		while (GetSequenceProgress(playerPed) == -1) and GetGameTimer() - startTimer < 15000 do
			Citizen.Wait(250)
		end
		local start2Timer = GetGameTimer()
		while (IsAnySequenceRunning(playerPed) and GetSequenceProgress(playerPed) ~= 1) and GetGameTimer() - start2Timer < 15000 do
			Citizen.Wait(250)
		end
		Citizen.Wait(1000)
		ClearSequenceTask(sequence)
		SetPlayerControl(PlayerId(), true)
		cb()
	else
		cb()
	end
end

function IsAnySequenceRunning(ped)
	local seqProg = GetSequenceProgress(ped)
	return seqProg >= 0 and seqProg <= 7
end

function CalcCorrectHeading(head)
	if head > 360.0 then
		head = head - 360.0
	end
	return head
end

function HandleAtmChoice(atms)
	local locations = {}
	local closestAtm = 0
	local closestDistance = 1000
	local playerCoords = GetEntityCoords(PlayerPedId())
	for k,v in pairs(atms) do
		local coords = GetOffsetFromEntityInWorldCoords(v.handle, 0.08, 0, 0) - GetEntityForwardVector(v.handle) * 0.6
		local dist = #(coords - playerCoords)
		--not IsAnyPedNearPoint(coords.x, coords.y, coords.z, 1.5) and
		if math.abs(coords.z - playerCoords.z) < 1.5 and (dist < closestDistance) then
			closestAtm = v.handle
			closestDistance = dist
		end
	end
	if closestAtm ~= 0 then
		local coords = GetOffsetFromEntityInWorldCoords(closestAtm, vector3(0.08 , 0,0)) - GetEntityForwardVector(closestAtm) * 0.6
		if not IsAnyPedNearPointExceptForPlayerPed(coords, 1.5) then
			locations[#locations + 1] = {heading = CalcCorrectHeading(GetEntityHeading(closestAtm)), coords = coords, handle = closestAtm}
		end
	end
	if #locations > 0 then
		local randomIndex = math.random(1, #locations)
		return true, locations[randomIndex].heading, locations[randomIndex].coords, locations[randomIndex].handle
	else
		return false
	end
end

function IsAnyPedNearPointExceptForPlayerPed(coords, radius)
	local gamePool = GetGamePool("CPed")
	for k,v in pairs(gamePool) do
		if #(coords - GetEntityCoords(v)) < radius then
			if v ~= PlayerPedId() then
				return true
			end
		end
	end
	return false
end

function CreatePinObj()
	DeletePinObj()
	local playerPed = PlayerPedId()
	if not DoesEntityExist(GetVehiclePedIsUsing(playerPed)) and IsEntityVisible(playerPed) then
		RequestModel(pinCard)
		while not HasModelLoaded(pinCard) do
			Citizen.Wait(0)
		end
		local handCoords = GetEntityCoords(playerPed)
		pinProp = CreateObject(pinCard, handCoords.x, handCoords.y, handCoords.z, false, true, true)
		SetEntityCollision(pinProp, false, false)
		local bone = GetPedBoneIndex(playerPed, 64016)
		AttachEntityToEntity(pinProp, playerPed, bone, 0.087, -0.011, 0.0, 180.0, 0.0, 0.0, 0, 0, 0, 0, 2, 1)
		SetModelAsNoLongerNeeded(pinProp)
	end
end

function DeletePinObj()
	if pinProp then
		if DoesEntityExist(pinProp) then
			Citizen.CreateThread(function()
				if not ESX.Game.TryDeleteEntity(pinProp) then
					ESX.Game.DeleteObject(pinProp)
				end
			end)
		end
	end
	return pinProp
end

--===============================================
--==             Map Blips	                   ==
--===============================================
Citizen.CreateThread(function()
	while not Loaded do
		Citizen.Wait(500)
	end

	if showblips then
		for k,v in ipairs(banks)do
			AddTextEntry(v.name, v.name)
			local blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
			SetBlipSprite(blip, v.id)
			SetBlipScale(blip, 0.9)
			SetBlipAsShortRange(blip, true)
			-- if v.principal ~= nil and v.principal then
			SetBlipColour(blip, 28)
			-- end
			BeginTextCommandSetBlipName(v.name)
			EndTextCommandSetBlipName(blip)
		end
	end
end)



--===============================================
--==           Deposit Event                   ==
--===============================================
RegisterNetEvent('currentbalance1')
AddEventHandler('currentbalance1', function(balance)
	local id = PlayerId()
	local playerName = GetPlayerName(id)
	
	SendNUIMessage({
		type = "balanceHUD",
		balance = balance,
		player = playerName
		})
end)
--===============================================
--==           Deposit Event                   ==
--===============================================
RegisterNUICallback('deposit', function(data)
	if not tonumber(data.amount) then
		TriggerEvent('bank:result', "error", "Ongeldige hoeveelheid.")
	else
		TriggerServerEvent('bank:deposit', tonumber(data.amount))
	end

	Citizen.Wait(500)
	TriggerServerEvent('bank:balance')
end)

--===============================================
--==          Withdraw Event                   ==
--===============================================
RegisterNUICallback('withdrawl', function(data)
	if not tonumber(data.amountw) then
		TriggerEvent('bank:result', "error", "Ongeldige hoeveelheid.")
	else
		TriggerServerEvent('bank:withdraw', tonumber(data.amountw))
	end
	Citizen.Wait(500)
	TriggerServerEvent('bank:balance')
end)

--===============================================
--==         Balance Event                     ==
--===============================================
RegisterNUICallback('balance', function()
	TriggerServerEvent('bank:balance')
end)

RegisterNetEvent('balance:back')
AddEventHandler('balance:back', function(balance)
	SendNUIMessage({type = 'balanceReturn', bal = balance})
end)


--===============================================
--==         Transfer Event                    ==
--===============================================
RegisterNUICallback('transfer', function(data)
	if IsRateLimited("transfer", 10000) then
		ESX.ShowNotification("Probeer het over enkele seconden opnieuw!")
		return
	end
	TriggerServerEvent('bank:transferName', data)
	Citizen.Wait(500)
	TriggerServerEvent('bank:balance')
end)

--===============================================
--==         Result   Event                    ==
--===============================================
RegisterNetEvent('bank:result')
AddEventHandler('bank:result', function(type, message)
	SendNUIMessage({type = 'result', m = message, t = type})
end)

--===============================================
--==               NUIFocusoff                 ==
--===============================================
RegisterNUICallback('NUIFocusOff', function()
	SetNuiFocus(false, false)
	SendNUIMessage({type = 'closeAll'})
	TriggerScreenblurFadeOut(300.00)
	local pped = PlayerPedId()
	local prop = DeletePinObj()
	if prop ~= 0 and prop ~= nil then
		ClearPedTasks(pped)
		Citizen.Wait(5100)
		ClearPedTasksImmediately(pped)
	end
	pinProp = nil
	inMenu = false
end)


--===============================================
--==            Capture Bank Distance          ==
--===============================================
function nearBank()
	for i=1, #banks do
		local search = banks[i]
		local distance = #(search.coords - playerCoords)

		if distance < minDistance then
			minDistance = distance
			if distance <= (search.radius or 3) then
				return true
			end
		end
	end
end

function nearATM()
	for i=1, #atms do
		local search = atms[i]
		local distance = #(search.coords - playerCoords)

		if distance < minDistance then
			minDistance = distance
			if distance <= (search.radius or 3) then
				return true
			end
		end
	end
end


function DisplayHelpText(str)
	SetTextComponentFormat("STRING")
	AddTextComponentString(str)
	DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local function checkWhitelist(id)
	for key, value in pairs(RepairWhitelist) do
		if id == value then
			return true
		end
	end	
	return false
end

--[[ESX.RegisterServerCallback("iens:pay", function(source, cb, price)
	local xPlayer = ESX.GetPlayerFromId(source)
	print(price)
	if xPlayer.getAccount('bank').money >= price then
		xPlayer.removeAccountMoney("bank", price)
		cb(true)
	else
		cb(false)
	end
end)]]

RegisterServerEvent("sts:payrepair", function(price)
	local xPlayer = ESX.GetPlayerFromId(source)
	print(price)
	if xPlayer.getAccount('bank').money >= price then
		xPlayer.removeAccountMoney("bank", price)
		TriggerClientEvent("iens:repair2", source, true, price)
		print 'true'
	else
		TriggerClientEvent("iens:repair2", source, false, price)
		print 'false'
	end
end)

RegisterCommand("repareer", function(source, args, raw)
	TriggerClientEvent('iens:repair', source)
end)

TriggerEvent('es:addGroupCommand', 'fixvehicle', 'user', function(source, args, user)
	if args[1] ~= nil then
		TriggerClientEvent('sts:fixvehicle', tonumber(args[1]))
	else
		TriggerClientEvent('sts:fixvehicle', source)
	end
end, function(source, args, user)
	TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Insufficient Permissions.' } })
end, { help = "Repareer een voertuig", params = {} })

ESX.RegisterServerCallback('sts:getcurrentkm', function(source, cb, plate)

	local xPlayer = ESX.GetPlayerFromId(source)
	local vehPlate = plate

	MySQL.Async.fetchAll(
		'SELECT * FROM veh_km WHERE carplate = @plate',
		{
			['@plate'] = vehPlate
		},
		function(result)

			local found = false

			for i=1, #result, 1 do

				local vehicleProps = result[i].carplate

				if vehicleProps == vehPlate then
					KMSend = result[i].km
	
					found = true
					break
				end

			end

			if found then
				TriggerClientEvent('vehiclefailure:getodometer', source, KMSend)
				cb(KMSend)
			else
				cb(0)
				MySQL.Async.execute('INSERT INTO veh_km (carplate) VALUES (@carplate)',{['@carplate'] = plate})
				Wait(2000)
			end

		end
	)

end)

RegisterServerEvent('sts:addkm')
AddEventHandler('sts:addkm', function(vehPlate, km)
    local src = source
    local identifier = ESX.GetPlayerFromId(src).identifier
	local plate = vehPlate
	local newKM = km

    MySQL.Async.execute('UPDATE veh_km SET km = @kms WHERE carplate = @plate', {['@plate'] = plate, ['@kms'] = newKM})
end)
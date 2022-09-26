local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/954330158909767700/JMnRueRkvGlgemR1kehdLrdEjFHKvssMG_a8uWkgRteJ3YrKyUjnO5slQmhCZxQfWo-L"

function logger(name, message, color)
    local connect = {
          {
              ["color"] = color,
              ["title"] = "**".. name .."**",
              ["description"] = message,
              ["footer"] = {
                  ["text"] = "STS LOGS",
              },
          }
      }
    PerformHttpRequest(DISCORD_WEBHOOK, function(err, text, headers) end, 'POST', json.encode({username = DISCORD_NAME, embeds = connect, avatar_url = DISCORD_IMAGE}), { ['Content-Type'] = 'application/json' })
end

local DISCORD_WEBHOOK2 = "https://discord.com/api/webhooks/974024434430124042/dlOSvvEEY_dVimJqZRVyK4bQ6LZ0UjJwdfDeK3hXCmFPHc-EsxH4AYaincxEFBa1aUlV"

function logger2(name, message, color)
    local connect = {
          {
              ["color"] = color,
              ["title"] = "**".. name .."**",
              ["description"] = message,
              ["footer"] = {
                  ["text"] = "STS LOGS",
              },
          }
      }
    PerformHttpRequest(DISCORD_WEBHOOK2, function(err, text, headers) end, 'POST', json.encode({username = DISCORD_NAME, embeds = connect, avatar_url = DISCORD_IMAGE}), { ['Content-Type'] = 'application/json' })
end


Citizen.CreateThread(function()
	SetMapName('Testserver')
	SetGameType('Roleplay')
	local resourcesStopped = {}
	ExecuteCommand('add_ace resource.es_extended command.stop allow')

	for resourceName,reason in pairs(Config.IncompatibleResourcesToStop) do
		local status = GetResourceState(resourceName)

		if status == 'started' or status == 'starting' then
			while GetResourceState(resourceName) == 'starting' do
				Citizen.Wait(100)
			end

			ExecuteCommand(('stop %s'):format(resourceName))
			resourcesStopped[resourceName] = reason
		end
	end

	if ESX.Table.SizeOf(resourcesStopped) > 0 then
		local allStoppedResources = ''

		for resourceName,reason in pairs(resourcesStopped) do
			allStoppedResources = ('%s\n- ^3%s^7, %s'):format(allStoppedResources, resourceName, reason)
		end

		print(('[es_extended] [^3WARNING^7] Stopped %s incompatible resource(s) that can cause issues when used with ESX. They are not needed and can safely be removed from your server, remove these resource(s) from your resource directory and your configuration file:%s'):format(ESX.Table.SizeOf(resourcesStopped), allStoppedResources))
	end
end)

local DISCORD_WEBHOOK_SCHELD = "https://discord.com/api/webhooks/979497168895344661/Q2OFwJHhgM95hfZtf_jF5IhSW1WJlezEBiJNJjDX6T0qSy205FpIj3_OEiSIv-ZQiNyz"

function scheldlog(name, message, color)
    local connect = {
          {
              ["color"] = color,
              ["title"] = "**".. name .."**",
              ["description"] = message,
              ["footer"] = {
                  ["text"] = "STS LOGS",
              },
          }
      }
    PerformHttpRequest(DISCORD_WEBHOOK_SCHELD, function(err, text, headers) end, 'POST', json.encode({username = DISCORD_NAME, embeds = connect, avatar_url = DISCORD_IMAGE}), { ['Content-Type'] = 'application/json' })
end

local badword = {
    'kanker',
}

RegisterNetEvent('esx:onPlayerJoined')
AddEventHandler('esx:onPlayerJoined', function()
	if not ESX.Players[source] then
		onPlayerJoined(source)
	end
	local playerId = source
	local xPlayer = ESX.GetPlayerFromId(playerId)
	local playerName = GetPlayerName(source)
	local steamid = false
	for k,v in pairs(GetPlayerIdentifiers(source))do
		if string.sub(v, 1, string.len("steam:")) == "steam:" then
			steamid = v
		end
	end

	local discord  = false
    for k,v in pairs(GetPlayerIdentifiers(source))do
        if string.sub(v, 1, string.len("discord:")) == "discord:" then
          discord = v
        end
    end
	
	logger2("Speler is de server gejoined", "ID: **" .. source .. "**\nNaam: **" .. playerName .. "**\nSteam: " .. steamid .."\nDiscord: "..discord, 65280)
	print(playerName.."("..source..") is de server aan het joinen!")
    local targetnamescheld = GetPlayerName(source)
    for k, targetnamescheld in pairs(badword) do
        if string.match(playerName:lower(), targetnamescheld:lower()) then
            scheldlog("Speler gejoined met ongepaste naam (niet bannen)", "**ID " .. source .. "** genaamd **" .. playerName .. "** (" .. discord ..") (" .. steamid ..") heeft een scheldwoord of een vorm van zelfpromotie in zijn steamnaam, persoon is gekicked", 500)
            DropPlayer(source, "Je gevonden steam naam bevat ongepast taalgebruik of ongepaste tekens, pas aub even je steam naam aan.")
        end
    end
end)

function onPlayerJoined(playerId)
	local identifier

	for k,v in ipairs(GetPlayerIdentifiers(playerId)) do
		if string.match(v, 'license:') then
			identifier = string.sub(v, 9)
			break
		end
	end

	if identifier then
		if ESX.GetPlayerFromIdentifier(identifier) then
			DropPlayer(playerId, ('there was an error loading your character!\nError code: identifier-active-ingame\n\nThis error is caused by a player on this server who has the same identifier as you have. Make sure you are not playing on the same Rockstar account.\n\nYour Rockstar identifier: %s'):format(identifier))
		else
			MySQL.Async.fetchScalar('SELECT 1 FROM users WHERE identifier = @identifier', {
				['@identifier'] = identifier
			}, function(result)
				if result then
					loadESXPlayer(identifier, playerId)
				else
					local accounts = {}

					for account,money in pairs(Config.StartingAccountMoney) do
						accounts[account] = money
					end

					MySQL.Async.execute('INSERT INTO users (accounts, identifier) VALUES (@accounts, @identifier)', {
						['@accounts'] = json.encode(accounts),
						['@identifier'] = identifier
					}, function(rowsChanged)
						loadESXPlayer(identifier, playerId)
					end)
				end
			end)
		end
	else
		DropPlayer(playerId, 'there was an error loading your character!\nError code: identifier-missing-ingame\n\nThe cause of this error is not known, your identifier could not be found. Please come back later or report this problem to the server administration team.')
	end
end

AddEventHandler('playerConnecting', function(name, setCallback, deferrals)
	deferrals.defer()
	local playerId = source
	local identifier = ESX.GetIdentifier(playerId)
	Citizen.Wait(100)

	if identifier then
		if ESX.GetPlayerFromIdentifier(identifier) then
			deferrals.done(('There was an error loading your character!\nError code: identifier-active\n\nThis error is caused by a player on this server who has the same identifier as you have. Make sure you are not playing on the same account.\n\nYour identifier: %s'):format(identifier))
		else
			deferrals.done()
		end
	else
		deferrals.done('There was an error loading your character!\nError code: identifier-missing\n\nThe cause of this error is not known, your identifier could not be found. Please come back later or report this problem to the server administration team.')
	end
end)


function loadESXPlayer(identifier, playerId)
	local tasks = {}

	local userData = {
		accounts = {},
		inventory = {},
		job = {},
		job2 = {},
		loadout = {},
		playerName = GetPlayerName(playerId),
		weight = 0
	}

	table.insert(tasks, function(cb)
	MySQL.Async.fetchAll('SELECT accounts, job, job2, job_grade, job2_grade, `group`, loadout, position, inventory FROM users WHERE identifier = @identifier', {
			['@identifier'] = identifier
		}, function(result)
			local job, job2, grade, grade2, jobObject, job2Object, gradeObject, grade2Object = result[1].job, result[1].job2, tostring(result[1].job_grade), tostring(result[1].job2_grade)
			local foundAccounts, foundItems = {}, {}

			-- Accounts
			if result[1].accounts and result[1].accounts ~= '' then
				local accounts = json.decode(result[1].accounts)

				for account,money in pairs(accounts) do
					foundAccounts[account] = money
				end
			end

			for account,label in pairs(Config.Accounts) do
				table.insert(userData.accounts, {
					name = account,
					money = foundAccounts[account] or Config.StartingAccountMoney[account] or 0,
					label = label
				})
			end

			-- Job
			if ESX.DoesJobExist(job, grade) then
				jobObject, gradeObject = ESX.Jobs[job], ESX.Jobs[job].grades[grade]
			else
				print(('[es_extended] [^3WARNING^7] Ignoring invalid job for %s [job: %s, grade: %s]'):format(identifier, job, grade))
				job, grade = 'unemployed', '0'
				jobObject, gradeObject = ESX.Jobs[job], ESX.Jobs[job].grades[grade]
			end

			userData.job.id = jobObject.id
			userData.job.name = jobObject.name
			userData.job.label = jobObject.label

			userData.job.grade = tonumber(grade)
			userData.job.grade_name = gradeObject.name
			userData.job.grade_label = gradeObject.label
			userData.job.grade_salary = gradeObject.salary

			userData.job.skin_male = {}
			userData.job.skin_female = {}

			if gradeObject.skin_male then userData.job.skin_male = json.decode(gradeObject.skin_male) end
			if gradeObject.skin_female then userData.job.skin_female = json.decode(gradeObject.skin_female) end

		

			-- Job2
			if ESX.DoesJob2Exist(job2, grade2) then
				job2Object, grade2Object = ESX.Jobs[job2], ESX.Jobs[job2].grades[grade2]
			else
				print(('[es_extended] [^3WARNING^7] Ignoring invalid job2 for %s [job2: %s, grade: %s]'):format(identifier, job2, grade2))
				job2, grade2 = 'unemployed2', '0'
				job2Object, grade2Object = ESX.Jobs[job2], ESX.Jobs[job2].grades[grade2]
			end

			userData.job2.id = job2Object.id
			userData.job2.name = job2Object.name
			userData.job2.label = job2Object.label

			userData.job2.grade = tonumber(grade2)
			userData.job2.grade_name = grade2Object.name
			userData.job2.grade_label = grade2Object.label
			userData.job2.grade_salary = grade2Object.salary

			userData.job2.skin_male = {}
			userData.job2.skin_female = {}

			if grade2Object.skin_male then userData.job2.skin_male = json.decode(grade2Object.skin_male) end
			if grade2Object.skin_female then userData.job2.skin_female = json.decode(grade2Object.skin_female) end

		

			-- Inventory
			if result[1].inventory and result[1].inventory ~= '' then
				local inventory = json.decode(result[1].inventory)

				for name,count in pairs(inventory) do
					local item = ESX.Items[name]

					if item then
						foundItems[name] = count
					else
						print(('[es_extended] [^3WARNING^7] Ignoring invalid item "%s" for "%s"'):format(name, identifier))
					end
				end
			end

			for name,item in pairs(ESX.Items) do
				local count = foundItems[name] or 0
				if count > 0 then userData.weight = userData.weight + (item.weight * count) end

				table.insert(userData.inventory, {
					name = name,
					count = count,
					label = item.label,
					weight = item.weight,
					usable = ESX.UsableItemsCallbacks[name] ~= nil,
					rare = item.rare,
					canRemove = item.canRemove
				})
			end

			table.sort(userData.inventory, function(a, b)
				return a.label < b.label
			end)

			-- Group
			if result[1].group then
				userData.group = result[1].group
			else
				userData.group = 'user'
			end

			-- Loadout 
			-- mogelijk wapen glitch
			if result[1].loadout and result[1].loadout ~= '' then
				local loadout = json.decode(result[1].loadout)

				for name,weapon in pairs(loadout) do
					local label = ESX.GetWeaponLabel(name)
					

					if label then
						if not weapon.components then weapon.components = {} end
						if not weapon.tintIndex then weapon.tintIndex = 0 end

						table.insert(userData.loadout, {
							name = name,
							ammo = weapon.ammo,
							label = label,
							components = weapon.components,
							tintIndex = weapon.tintIndex
						})
					end
				end
			end

			-- Position
			if result[1].position and result[1].position ~= '' then
				userData.coords = json.decode(result[1].position)
			else
				print('[es_extended] [^3WARNING^7] Column "position" in "users" table is missing required default value. Using backup coords, fix your database.')
				userData.coords = {x = -269.4, y = -955.3, z = 31.2, heading = 205.8}
			end

			cb()
		end)
	end)

	Async.parallel(tasks, function(results)
		local xPlayer = CreateExtendedPlayer(playerId, identifier, userData.group, userData.accounts, userData.inventory, userData.weight, userData.job, userData.job2, userData.loadout, userData.playerName, userData.coords)
		ESX.Players[playerId] = xPlayer
		TriggerEvent('esx:playerLoaded', playerId, xPlayer)

		xPlayer.triggerEvent('esx:playerLoaded', {
			accounts = xPlayer.getAccounts(),
			coords = xPlayer.getCoords(),
			identifier = xPlayer.getIdentifier(),
			inventory = xPlayer.getInventory(),
			job = xPlayer.getJob(),
			job2 = xPlayer.getJob2(),
			loadout = xPlayer.getLoadout(),
			maxWeight = xPlayer.getMaxWeight(),
			money = xPlayer.getMoney()
		})

		xPlayer.triggerEvent('esx:createMissingPickups', ESX.Pickups)
		xPlayer.triggerEvent('esx:registerSuggestions', ESX.RegisteredCommands)
	end)
end

AddEventHandler('chatMessage', function(playerId, author, message)
	if message:sub(1, 1) == '/' and playerId > 0 then
		CancelEvent()
		local commandName = message:sub(1):gmatch("%w+")()
		--TriggerClientEvent('chat:addMessage', playerId, {args = {'^1SYSTEM', _U('commanderror_invalidcommand', commandName)}})
	end
end)

AddEventHandler('playerDropped', function(reason)
	local playerId = source
	local xPlayer = ESX.GetPlayerFromId(playerId)
	
	local steamid = false
	for k,v in pairs(GetPlayerIdentifiers(source))do
		if string.sub(v, 1, string.len("steam:")) == "steam:" then
			steamid = v
		end
	end
	local discord  = false
    for k,v in pairs(GetPlayerIdentifiers(source))do
        if string.sub(v, 1, string.len("discord:")) == "discord:" then
          discord = v
        end
    end
	local playerName = GetPlayerName(source)

	if xPlayer then
		TriggerEvent('esx:playerDropped', playerId, reason)

		ESX.SavePlayer(xPlayer, function()
			ESX.Players[playerId] = nil
		end)
	end
	print(playerName.."("..source..") is de server verlaten!")
	logger("Speler is de server verlaten", "ID: **" .. source .. "**\nNaam: **" .. playerName .. "**\nSteam: " .. steamid .."\nDiscord: "..discord.."\nReden: **" .. reason.."**", 65280)
end)

RegisterNetEvent('esx:updateCoords')
AddEventHandler('esx:updateCoords', function(coords)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer then
		xPlayer.updateCoords(coords)
	end
end)

RegisterNetEvent('esx:updateWeaponAmmo')
AddEventHandler('esx:updateWeaponAmmo', function(weaponName, ammoCount)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer then
		xPlayer.updateWeaponAmmo(weaponName, ammoCount)
	end
end)

RegisterNetEvent('esx:giveInventoryItem')
AddEventHandler('esx:giveInventoryItem', function(target, type, itemName, itemCount)
	local playerId = source
	local sourceXPlayer = ESX.GetPlayerFromId(playerId)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if type == 'item_standard' then
		local sourceItem = sourceXPlayer.getInventoryItem(itemName)
		local targetItem = targetXPlayer.getInventoryItem(itemName)

		if itemCount > 0 and sourceItem.count >= itemCount then
			if targetXPlayer.canCarryItem(itemName, itemCount) then
				sourceXPlayer.removeInventoryItem(itemName, itemCount)
				targetXPlayer.forceaddInventoryItem   (itemName, itemCount)

				--sourceXPlayer.showNotification(_U('gave_item', itemCount, sourceItem.label, targetXPlayer.name))
				--targetXPlayer.showNotification(_U('received_item', itemCount, sourceItem.label, sourceXPlayer.name))
				sourceXPlayer.showNotification(_U('gave_item', itemCount, sourceItem.label, targetXPlayer.source))
				targetXPlayer.showNotification(_U('received_item', itemCount, sourceItem.label, sourceXPlayer.source))
			else
				sourceXPlayer.showNotification(_U('ex_inv_lim', targetXPlayer.name))
			end
		else
			sourceXPlayer.showNotification(_U('imp_invalid_quantity'))
		end
	elseif type == 'item_account' then
		if itemCount > 0 and sourceXPlayer.getAccount(itemName).money >= itemCount then
			sourceXPlayer.removeAccountMoney(itemName, itemCount)
			targetXPlayer.addAccountMoney   (itemName, itemCount)

			--sourceXPlayer.showNotification(_U('gave_account_money', ESX.Math.GroupDigits(itemCount), Config.Accounts[itemName], targetXPlayer.name))
			--targetXPlayer.showNotification(_U('received_account_money', ESX.Math.GroupDigits(itemCount), Config.Accounts[itemName], sourceXPlayer.name))
			sourceXPlayer.showNotification(_U('gave_account_money', ESX.Math.GroupDigits(itemCount), targetXPlayer.source))
			targetXPlayer.showNotification(_U('received_account_money', ESX.Math.GroupDigits(itemCount), Config.Accounts[itemName], sourceXPlayer.source))
		else
			sourceXPlayer.showNotification(_U('imp_invalid_amount'))
		end
	elseif type == 'item_weapon' then
		if sourceXPlayer.hasWeapon(itemName) then
			local weaponLabel = ESX.GetWeaponLabel(itemName)

			if not targetXPlayer.hasWeapon(itemName) then
				local _, weapon = sourceXPlayer.getWeapon(itemName)
				local _, weaponObject = ESX.GetWeapon(itemName)
				itemCount = weapon.ammo

				sourceXPlayer.removeWeapon(itemName)
				targetXPlayer.forceaddWeapon(itemName, itemCount)

				if weaponObject.ammo and itemCount > 0 then
					local ammoLabel = weaponObject.ammo.label
					--sourceXPlayer.showNotification(_U('gave_weapon_withammo', weaponLabel, itemCount, ammoLabel, targetXPlayer.name))
					--targetXPlayer.showNotification(_U('received_weapon_withammo', weaponLabel, itemCount, ammoLabel, sourceXPlayer.name))
					sourceXPlayer.showNotification(_U('gave_weapon_withammo', weaponLabel, itemCount, targetXPlayer.source))
					targetXPlayer.showNotification(_U('received_weapon_withammo', weaponLabel, itemCount, sourceXPlayer.source))
				else
					--sourceXPlayer.showNotification(_U('gave_weapon', weaponLabel, targetXPlayer.name))
					--targetXPlayer.showNotification(_U('received_weapon', weaponLabel, sourceXPlayer.name))
					sourceXPlayer.showNotification(_U('gave_weapon', weaponLabel, targetXPlayer.source))
					targetXPlayer.showNotification(_U('received_weapon', weaponLabel, sourceXPlayer.source))
				end
			else
				--sourceXPlayer.showNotification(_U('gave_weapon_hasalready', targetXPlayer.name, weaponLabel))
				--targetXPlayer.showNotification(_U('received_weapon_hasalready', sourceXPlayer.name, weaponLabel))
				sourceXPlayer.showNotification(_U('gave_weapon_hasalready', targetXPlayer.source, weaponLabel))
				targetXPlayer.showNotification(_U('received_weapon_hasalready', sourceXPlayer.source, weaponLabel))
			end
		end
	elseif type == 'item_ammo' then
		if sourceXPlayer.hasWeapon(itemName) then
			local weaponNum, weapon = sourceXPlayer.getWeapon(itemName)

			if targetXPlayer.hasWeapon(itemName) then
				local _, weaponObject = ESX.GetWeapon(itemName)

				if weaponObject.ammo then
					local ammoLabel = weaponObject.ammo.label

					if weapon.ammo >= itemCount then
						sourceXPlayer.removeWeaponAmmo(itemName, itemCount)
						targetXPlayer.addWeaponAmmo(itemName, itemCount)

						--sourceXPlayer.showNotification(_U('gave_weapon_ammo', itemCount, ammoLabel, weapon.label, targetXPlayer.name))
						--targetXPlayer.showNotification(_U('received_weapon_ammo', itemCount, ammoLabel, weapon.label, sourceXPlayer.name))
						sourceXPlayer.showNotification(_U('gave_weapon_ammo', itemCount, ammoLabel, weapon.label, targetXPlayer.source))
						targetXPlayer.showNotification(_U('received_weapon_ammo', itemCount, ammoLabel, weapon.label, sourceXPlayer.source))
					end
				end
			else
				--sourceXPlayer.showNotification(_U('gave_weapon_noweapon', targetXPlayer.name))
				--targetXPlayer.showNotification(_U('received_weapon_noweapon', sourceXPlayer.name, weapon.label))
				sourceXPlayer.showNotification(_U('gave_weapon_noweapon', targetXPlayer.source))
				targetXPlayer.showNotification(_U('received_weapon_noweapon', sourceXPlayer.source, weapon.label))
			end
		end
	end
end)

RegisterNetEvent('esx:removeInventoryItem')
AddEventHandler('esx:removeInventoryItem', function(type, itemName, itemCount)
	local playerId = source
	local xPlayer = ESX.GetPlayerFromId(source)

	if type == 'item_standard' then
		if itemCount == nil or itemCount < 1 then
			xPlayer.showNotification(_U('imp_invalid_quantity'))
		else
			local xItem = xPlayer.getInventoryItem(itemName)

			if (itemCount > xItem.count or xItem.count < 1) then
				xPlayer.showNotification(_U('imp_invalid_quantity'))
			else
				xPlayer.removeInventoryItem(itemName, itemCount)
				local pickupLabel = ('~y~%s~s~ [~b~%s~s~]'):format(xItem.label, itemCount)
				ESX.CreatePickup('item_standard', itemName, itemCount, pickupLabel, playerId)
				xPlayer.showNotification(_U('threw_standard', itemCount, xItem.label))
			end
		end
	elseif type == 'item_account' then
		if itemCount == nil or itemCount < 1 then
			xPlayer.showNotification(_U('imp_invalid_amount'))
		else
			local account = xPlayer.getAccount(itemName)

			if (itemCount > account.money or account.money < 1) then
				xPlayer.showNotification(_U('imp_invalid_amount'))
			else
				xPlayer.removeAccountMoney(itemName, itemCount)
				local pickupLabel = ('~y~%s~s~ [~g~%s~s~]'):format(account.label, _U('locale_currency', ESX.Math.GroupDigits(itemCount)))
				ESX.CreatePickup('item_account', itemName, itemCount, pickupLabel, playerId)
				xPlayer.showNotification(_U('threw_account', ESX.Math.GroupDigits(itemCount), string.lower(account.label)))
			end
		end
	elseif type == 'item_weapon' then
		itemName = string.upper(itemName)

		if xPlayer.hasWeapon(itemName) then
			local _, weapon = xPlayer.getWeapon(itemName)
			local _, weaponObject = ESX.GetWeapon(itemName)
			local pickupLabel

			xPlayer.removeWeapon(itemName)

			if weaponObject.ammo and weapon.ammo > 0 then
				local ammoLabel = weaponObject.ammo.label
				pickupLabel = ('~y~%s~s~ [~g~%s~s~ %s]'):format(weapon.label, weapon.ammo, ammoLabel)
				xPlayer.showNotification(_U('threw_weapon_ammo', weapon.label, weapon.ammo, ammoLabel))
			else
				pickupLabel = ('~y~%s~s~'):format(weapon.label)
				xPlayer.showNotification(_U('threw_weapon', weapon.label))
			end

			ESX.CreatePickup('item_weapon', itemName, weapon.ammo, pickupLabel, playerId, weapon.components, weapon.tintIndex)
		end
	end
end)

RegisterNetEvent('esx:useItem')
AddEventHandler('esx:useItem', function(itemName)
	local xPlayer = ESX.GetPlayerFromId(source)
	local count = xPlayer.getInventoryItem(itemName).count

	if count > 0 then
		ESX.UseItem(source, itemName)
	else
		xPlayer.showNotification(_U('act_imp'))
	end
end)

RegisterNetEvent('esx:onPickup')
AddEventHandler('esx:onPickup', function(pickupId, quantity)
	local pickup, xPlayer, success = ESX.Pickups[pickupId], ESX.GetPlayerFromId(source)
	if tostring(quantity) == 'all' then
		quantity = pickup.count
	end

	if pickup then
		if pickup.type == 'item_standard' then
			if xPlayer.canCarryItem(pickup.name, quantity) then
				if quantity <= pickup.count then
					xPlayer.forceaddInventoryItem(pickup.name, quantity)
					success = true
					if quantity < pickup.count then
						newcount = pickup.count - quantity
						itemlabel = ESX.GetItemLabel(pickup.name)
						newlabel = "~y~"..itemlabel.."~s~ [~b~"..newcount.."~s~]"
						ESX.CreatePickup(pickup.type, pickup.name, newcount, newlabel, xPlayer.source)
					end
				else
					xPlayer.showNotification("Ongeldig aantal")
				end
			else
				xPlayer.showNotification(_U('threw_cannot_pickup'))
			end
		elseif pickup.type == 'item_account' then
			if quantity <= pickup.count then
				success = true
				xPlayer.addAccountMoney(pickup.name, pickup.count)
				if quantity < pickup.count then
					newcount = pickup.count - quantity
					itemlabel = "nil"
					if pickup.name == "money" then
						itemlabel = "Geld"
					elseif pickup.name == "black_money" then
						itemlabel = "Zwart geld"
					end
					newlabel = "~y~"..itemlabel.."~s~ [~g~€"..ESX.Math.GroupDigits(newcount).."~s~]" or "nil"
					ESX.CreatePickup(pickup.type, pickup.name, newcount, newlabel, xPlayer.source)
				end
			else
				xPlayer.showNotification("Ongeldig aantal")
			end
		elseif pickup.type == 'item_weapon' then
			if xPlayer.hasWeapon(pickup.name) then
				xPlayer.showNotification(_U('threw_weapon_already'))
			else
				success = true
				xPlayer.forceaddWeapon(pickup.name, pickup.count)
				xPlayer.setWeaponTint(pickup.name, pickup.tintIndex)

				for k,v in ipairs(pickup.components) do
					xPlayer.forceaddWeaponComponent(pickup.name, v)
				end
			end
		end

		if success then
			ESX.Pickups[pickupId] = nil
			TriggerClientEvent('esx:removePickup', -1, pickupId)
		end
	end
end)

ESX.RegisterServerCallback('esx:getPlayerData', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	cb({
		identifier   = xPlayer.identifier,
		accounts     = xPlayer.getAccounts(),
		inventory    = xPlayer.getInventory(),
		job          = xPlayer.getJob(),
		job2          = xPlayer.getJob2(),
		loadout      = xPlayer.getLoadout(),
		money        = xPlayer.getMoney()
	})
end)

ESX.RegisterServerCallback('esx:getOtherPlayerData', function(source, cb, target)
	local xPlayer = ESX.GetPlayerFromId(target)

	cb({
		identifier   = xPlayer.identifier,
		accounts     = xPlayer.getAccounts(),
		inventory    = xPlayer.getInventory(),
		job          = xPlayer.getJob(),
		job2          = xPlayer.getJob2(),
		loadout      = xPlayer.getLoadout(),
		money        = xPlayer.getMoney()
	})
end)

ESX.RegisterServerCallback('esx:getPlayerNames', function(source, cb, players)
	players[source] = nil

	for playerId,v in pairs(players) do
		local xPlayer = ESX.GetPlayerFromId(playerId)

		if xPlayer then
			players[playerId] = xPlayer.getName()
		else
			players[playerId] = nil
		end
	end

	cb(players)
end)

ESX.StartDBSync()
ESX.StartPayCheck()


--[[local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/968124957362102272/c1BCW6txPkZvjDfwGuzKhK_uTVAlWnz4GAQyeds4USQCdvn71Bxmxkjo5dftrScWVjPB"

function stskicklogger(name, message, color)
	local connect = {
		  {
			  ["color"] = color,
			  ["title"] = "**".. name .."**",
			  ["description"] = message,
			  ["footer"] = {
				  ["text"] = "STS LOGS",
			  },
		  }
	  }
	PerformHttpRequest(DISCORD_WEBHOOK, function(err, text, headers) end, 'POST', json.encode({username = DISCORD_NAME, embeds = connect, avatar_url = DISCORD_IMAGE}), { ['Content-Type'] = 'application/json' })
  end]]

RegisterNetEvent('sts:redzonekickplayer')
AddEventHandler('sts:redzonekickplayer', function(reason)
	local xPlayer = ESX.GetPlayerFromId(source)
	--[[local steamname = GetPlayerName(source)
	local targetlicense = GetPlayerIdentifier(source, steam)
	local discord  = false
	for k,v in pairs(GetPlayerIdentifiers(source))do
		if string.sub(v, 1, string.len("discord:")) == "discord:" then
		  discord = v
		end
	end
	stskicklogger("Redzone Abuse", "Steamnaam: **" .. steamname .. "** \nDiscord ID: **(" .. discord ..")** \nSteam License: **(" .. targetlicense ..")** \n Reden: **"..reason.."**", 65280)]]
	xPlayer.kick(reason)
end)
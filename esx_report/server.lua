local ESX = nil
local payloadFormat = "{ \"username\" : \"%s\", \"avatar_url\" : \"%s\", \"embeds\": [{ \"title\": \"%s\", \"type\": \"rich\", \"description\": \"%s\", \"color\": %d, \"footer\": {\"text\": \"esx_report | Wesleyy#9498\"} }]}"

TriggerEvent('esx:getSharedObject', function(obj) 
    ESX = obj 
end)
local Cooldown = {}

local webhook = "https://discord.com/api/webhooks/905193241459171378/l1ObmXJzkCee-6dyA33AGzXHXMEwMvPnG5MRaJBZt-h6WlcfJWO9AmB7uQEc-gC5Hqty"

RegisterCommand('reply', function(source, args, rawCommand)
	local cm = stringsplit(rawCommand, ' ')
	CancelEvent()
		if tablelength(cm) > 1 then
			local tPID = tonumber(cm[2])
			local names2 = GetPlayerName(tPID)
			local names3 = GetPlayerName(source)
			local textmsg = ''
			for i=1, #cm do
				if i ~= 1 and i ~=2 then
					textmsg = (textmsg .. ' ' .. tostring(cm[i]))
				end
			end
			local xPlayer = ESX.GetPlayerFromId(source)
		    if xPlayer.getGroup() ~= Config.defaultUserGroup then
				TriggerClientEvent('esx_report:getplayerinfo_reply', source, tPID, textmsg, names2, names3)
			    --TriggerClientEvent('esx_report:textmsg', tPID, source, textmsg, names2, names3)
				--TriggerClientEvent('esx_report:sendReply', -1, source, textmsg, names2, names3)
				if Config.useDiscord then
					local username = names3 .. ' ['.. source ..']'
					SendWebhookMessage(webhook, username , "Reply", '-> ' .. names2  .. ' ['.. tPID ..'] '..':  ' .. textmsg )
				end
		    else
			    TriggerClientEvent('chatMessage', source, 'SYSTEM', {255, 0, 0}, 'Insuficient Premissions!')
			end
		end
end, false)


RegisterCommand('report', function(source, args, rawCommand)
	if not Cooldown[source] then
		local cm = stringsplit(rawCommand, ' ')
		CancelEvent()
		if tablelength(cm) > 1 then
			local playername = GetPlayerName(source)
			local textmsg = ''
			for i=1, #cm do
				if i ~= 1 then
					textmsg = (textmsg .. ' ' .. tostring(cm[i]))
				end
			end
			TriggerClientEvent('esx_report:getplayerinfo', source, source, playername, textmsg)
			Cooldown[source] = 'KK'
            Citizen.Wait(60000)
            Cooldown[source] = nil
		end
	else
		TriggerClientEvent('chat:addMessage', source, {
			template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(255, 184, 77, 0.6); border-radius: 3px;"><b><font color=white><b><font color=red>[{0}]:</b></font> {1}</div>',
			args = { 'Report', 'Wacht even voordat je dit command opnieuw gebruikt!' }
		})
	end
end, false)

RegisterServerEvent('esx_report:sendreporttoplayers')
AddEventHandler('esx_report:sendreporttoplayers', function(id, name, message, playerdata)
	TriggerClientEvent('esx_report:sendReport', -1, id, name, message, playerdata)
	if names1 == nil then
		names1 = ""
	end
	local username = names1 .. ' ['.. source ..']'
	SendWebhookMessage("https://discord.com/api/webhooks/970019571643858995/4kioOobIbYX2I2kIXyHZottDbqT02Qao8pZpHeqSvk15gbmKAv9g8rU_tJOOHd7O4VxS", name , 'Report', '' .. message .. '')
end)

RegisterServerEvent('esx_report:sendreplytoplayers')
AddEventHandler('esx_report:sendreplytoplayers', function(tPID, textmsg, names2, names3, playerdata)
	--TriggerClientEvent('esx_report:sendReport', -1, id, name, message, playerdata)
	print(tPID)
	print(textmsg)
	print(names2)
	print(names3)
	print(playerdata)
	TriggerClientEvent('esx_report:textmsg', tPID, textmsg, names3, playerdata)
	TriggerClientEvent('esx_report:sendReply', -1, tPID, textmsg, names2, names3, playerdata)
	if names2 == nil then
		names2 = ""
	end
	local username = names2 .. ' ['.. source ..']'
	SendWebhookMessage("https://discord.com/api/webhooks/970019571643858995/4kioOobIbYX2I2kIXyHZottDbqT02Qao8pZpHeqSvk15gbmKAv9g8rU_tJOOHd7O4VxS", name , 'Reply', '' .. names3 .. '')
end)


function stringsplit(inputstr, sep)
    if sep == nil then
        sep = '%s'
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, '([^'..sep..']+)') do
        t[i] = str
        i = i + 1
    end
    return t
end


Citizen.CreateThread(function()
	function SendWebhookMessage(webhook, Username, typeofmessage ,message)
		if webhook ~= 'none' then
			local embed = {title = typeofmessage, type = "rich", description = message , color = Config.color[typeofmessage]}
			local colorname = string.lower(typeofmessage)
			PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', string.format(payloadFormat, Username, Config.imgurl, typeofmessage, message, Config.color[colorname]), { ['Content-Type'] = 'application/json' })
		end
	end
end)

function tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end
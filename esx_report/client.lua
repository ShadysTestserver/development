
--template for message
local formatOfMessage = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(%s, %s, %s, %s); border-radius: 3px;%s"><i class="fas fa-commenting"></i> <b><font color=red>[{0}]:</b></font> {1}</div>'
local formatOfMessageToggle = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(%s, %s, %s); border-radius: 3px;%s"><i class="fas fa-commenting"></i> <b><font color=red>[{0}]:</b></font> {1}</div>'
local formatOfMessageForClient = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(%s, %s, %s, %s); border-radius: 3px; %s"><i class="fas fa-commenting"></i> <b><font color=red>[{0}]:</b></font> {1} <br> Je report: {2}</div>'

local ESX = nil
local cooldown = 300
local reports = true



Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(500)
    end

    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(100)
    end

    TriggerEvent('chat:addSuggestion', '/reply', _U('description_reply'), {
        { name="id", help= _U('help_text_id') },
        { name="msg", help= _U('help_text_message_reply') }
    })

    TriggerEvent('chat:addSuggestion', '/report', _U('description_report'), {
        { name="msg", help= _U('help_text_message_report') }
    })
end)

RegisterNetEvent("esx_report:textmsg")
AddEventHandler('esx_report:textmsg', function(textmsg, steamname, playerdata)
    local message = steamname .."  "..": " .. textmsg
    local name = "Reply"
    if playerdata == "beheer" or playerdata == "headstaff" then
        TriggerEvent('chat:addMessage', {
            template = formatOfMessage:format(255, 70, 70, 0.6, ""),
            args = { name, message },
            important = true
        })
    else
        TriggerEvent('chat:addMessage', {
            template = formatOfMessage:format(255, 184, 77, 0.6, ""),
            args = { name, message },
            important = true
        })
    end
end)


RegisterNetEvent('esx_report:sendReply')
AddEventHandler('esx_report:sendReply', function(stafflidid, textmsg, targetname, stafflid )
    if exports['sts_discordperms']:hasingamemodgroup() == true or exports['sts_discordperms']:hasingameadmingroup() == true or exports['sts_discordperms']:hasingamesuperadmingroup() == true and reports == true then
        local message = ("%s [%s] -> %s: %s"):format(stafflid, stafflidid, targetname, textmsg)
        local name = "Reply"

        TriggerEvent('chat:addMessage', {
            template = formatOfMessage:format(125, 255, 222, 0.6, ""),
            args = { name, message },
            important = true
        })

    end
end)

RegisterNetEvent('esx_report:getplayerinfo')
AddEventHandler('esx_report:getplayerinfo', function(id, name, message)
    local playerdata = "user"
    if exports['sts_discordperms']:haspriogroup() == true or exports['sts_discordperms']:hasprioplusgroup() == true then
        playerdata = "supporter"
    end
    if exports['sts_discordperms']:hashelpergroup() == true then
        playerdata = "helper"
    end
    if exports['sts_discordperms']:hasmodgroup() == true then
        playerdata = "moderator"
    end
    if exports['sts_discordperms']:hassupermodgroup() == true then
        playerdata = "supermod"
    end
    if exports['sts_discordperms']:hasjradmingroup() == true then
        playerdata = "jradmin"
    end
    if exports['sts_discordperms']:hasadmingroup() == true then
        playerdata = "admin"
    end
    if exports['sts_discordperms']:hassuperadmingroup() == true then
        playerdata = "superadmin"
    end
    if exports['sts_discordperms']:hasheadstaffgroup() == true then
        playerdata = "headstaff"
    end
    if exports['sts_discordperms']:hasbeheergroup() == true then
        playerdata = "beheer"
    end
    TriggerServerEvent("esx_report:sendreporttoplayers", id, name, message, playerdata)
end)

RegisterNetEvent('esx_report:getplayerinfo_reply')
AddEventHandler('esx_report:getplayerinfo_reply', function(targetid, textmsg, names2, names3)
    local playerdata = "user"
    if exports['sts_discordperms']:haspriogroup() == true or exports['sts_discordperms']:hasprioplusgroup() == true then
        playerdata = "supporter"
    end
    if exports['sts_discordperms']:hashelpergroup() == true then
        playerdata = "helper"
    end
    if exports['sts_discordperms']:hasmodgroup() == true then
        playerdata = "moderator"
    end
    if exports['sts_discordperms']:hassupermodgroup() == true then
        playerdata = "supermod"
    end
    if exports['sts_discordperms']:hasjradmingroup() == true then
        playerdata = "jradmin"
    end
    if exports['sts_discordperms']:hasadmingroup() == true then
        playerdata = "admin"
    end
    if exports['sts_discordperms']:hassuperadmingroup() == true then
        playerdata = "superadmin"
    end
    if exports['sts_discordperms']:hasheadstaffgroup() == true then
        playerdata = "headstaff"
    end
    if exports['sts_discordperms']:hasbeheergroup() == true then
        playerdata = "beheer"
    end
    TriggerServerEvent("esx_report:sendreplytoplayers", targetid, textmsg, names2, names3, playerdata)
end)

RegisterNetEvent('esx_report:sendReport')
AddEventHandler('esx_report:sendReport', function(id, name, message, playerdata)
    local myId = PlayerId()
    local pid = GetPlayerFromServerId(id)
    extraData = extraData or {}

    if id ~= -1 and pid == myId then
        local name = "Report"

        TriggerEvent('chat:addMessage', {
            template = formatOfMessageForClient:format(255, 184, 77, 0.6, ""),
            args = { name, _U("send_to_admins"), message}
        })
    end

    if exports['sts_discordperms']:hasingamemodgroup() == true or exports['sts_discordperms']:hasingameadmingroup() == true or exports['sts_discordperms']:hasingamesuperadmingroup() == true and reports == true then
        local group = ""
        if playerdata == "supporter" then
            group = "^6[SUPPORTER]^7"
        end
        if playerdata == "helper" then
            group = "^1[HELPER]^7"
        end
        if playerdata == "moderator" then
            group = "^1[MODERATOR]^7"
        end
        if playerdata == "supermod" then
            group = "^1[SUPER MOD]^7"
        end
        if playerdata == "jradmin" then
            group = "^1[JR. ADMIN]^7"
        end
        if playerdata == "admin" then
            group = "^1[ADMIN]^7"
        end
        if playerdata == "superadmin" then
            group = "^1[SUPER ADMIN]^7"
        end
        if playerdata == "headstaff" then
            group = "^1[HEAD STAFF]^7"
        end
        if playerdata == "beheer" then
            group = "^1[BEHEER]^7"
        end
        local message = ("[%s]%s %s : %s"):format(id, name, group, message)
        local name = "Report"
        extraData = extraData or {}
        if playerdata == "supporter" then
            TriggerEvent('chat:addMessage', {
                template = formatOfMessage:format(255, 200, 100, 0.6, ""),
                args = { name, message },
                important = true
            })
        else
            TriggerEvent('chat:addMessage', {
                template = formatOfMessage:format(255, 184, 77, extraData.a or 0.6, ""),
                args = { name, message },
                important = true
            })
        end
    end
end)

RegisterCommand("togglereport", function(source)
	if reports == false then
        reports = true
        exports['esx_rpchat']:PrintToChat("Report", ("Reports staan nu ^2aan!"):format(target))
    elseif reports == true then
        reports = false
        exports['esx_rpchat']:PrintToChat("Report", ("Reports staan nu ^1uit!"):format(target))
    end
end)
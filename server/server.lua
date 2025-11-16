---@diagnostic disable: undefined-field, undefined-global
local Bells = {}

if not ESX then
    ESX = nil

    local ok, err = pcall(function()
        ESX = exports["es_extended"]:getSharedObject()
    end)

    if not ok then
        return print(("[FS_BELLS] >> Failed to fetch shared object: %s"):format(err))
    end

    TriggerEvent("esx:getSharedObject", function(obj)
        ESX = obj
    end)
end

MySQL.ready(function()
    Bells = GetBells()
end)

RegisterServerEvent("fs_bells:frakklingel:onJoin", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if (xPlayer) then
        for _, bell in ipairs(Bells) do
            if bell.coords and type(bell.coords) == "string" then
                bell.coords = json.decode(bell.coords)
            end
        end
        TriggerClientEvent("fs_bells:frakklingel:sendBells", src, Bells)
    end
end)

RegisterServerEvent("fs_bells:frakklingel:createBell", function(job, label, coords)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if (xPlayer) then
        if (not HasPerms(src)) then
            return Notify(xPlayer.source, "error", "Information", "Du hast keine Berechtigung hierfür!")
        end

        local currBells = MySQL.single.await("SELECT * FROM fs_bells WHERE job = ?", { job })

        if (currBells) then
            return Notify(xPlayer.source, "error", "Information",
                ("Eine Frakklingel für den Job %s existiert bereits!"):format(job))
        end

        MySQL.insert.await("INSERT INTO fs_bells (job, label, coords) VALUES (?, ?, ?)", {
            job,
            label,
            json.encode(coords)
        })

        Bells = GetBells()

        for _, bell in ipairs(Bells) do
            if bell.coords and type(bell.coords) == "string" then
                bell.coords = json.decode(bell.coords)
            end
        end

        TriggerClientEvent("fs_bells:frakklingel:sendBells", -1, Bells)

        Notify(xPlayer.source, "success", "Information", ("Frakklingel für den Job %s wurde erstellt!"):format(job))
    end
end)

RegisterServerEvent("fs_bells:frakklingel:deleteBell", function(job)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if (xPlayer) then
        if (not HasPerms(src)) then
            return Notify(xPlayer.source, "error", "Information", "Du hast keine Berechtigung hierfür!")
        end

        if (job == nil or job == "") then
            return Notify(xPlayer.source, "error", "Information", "Bitte gib einen Jobnamen ein!")
        end

        MySQL.query.await("DELETE FROM fs_bells WHERE job = ?", { job })

        Bells = GetBells()

        for _, bell in ipairs(Bells) do
            if bell.coords and type(bell.coords) == "string" then
                bell.coords = json.decode(bell.coords)
            end
        end

        TriggerClientEvent("fs_bells:frakklingel:sendBells", -1, Bells)

        Notify(xPlayer.source, "success", "Information", ("Frakklingel für den Job %s wurde gelöscht!"):format(job))
    end
end)

ESX.RegisterServerCallback("fs_bells:frakklingel:hasPerms", function(source, cb)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if (xPlayer) then
        if (HasPerms(xPlayer.source)) then
            cb(true)
        else
            cb(false)
        end
    end
end)

ESX.RegisterServerCallback("fs_bells:frakklingel:klingel", function(source, cb, faction, label)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if (xPlayer) then
        if (not label or not faction) then
            cb({
                success = false,
                message = "Fraktion existiert nicht"
            })
            return
        end

        for _, player in ipairs(ESX.GetExtendedPlayers()) do
            local xTarget = ESX.GetPlayerFromId(player.source)

            if (xTarget and xTarget.job.name == faction) then
                Notify(xTarget.source, "info", "Information", "Jemand hat an der Tür geklingelt")
            end
        end

        cb({
            success = true,
            message = ("Du hast bei %s geklingelt"):format(label)
        })
    end
end)

function GetBells()
    local p = promise.new()

    MySQL.query("SELECT * FROM fs_bells", function(result)
        if (result) then
            p:resolve(result)
        else
            p:resolve({})
        end
    end)

    return Citizen.Await(p)
end

function HasPerms(source)
    local xPlayer = ESX.GetPlayerFromId(source)

    if (xPlayer) then
        if (FS_BELLS.admin[xPlayer.getGroup()]) then
            return true
        end
    end

    return false
end

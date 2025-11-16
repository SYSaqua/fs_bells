---@diagnostic disable: undefined-field, lowercase-global, param-type-mismatch
local Bells = {}
local IsLoaded = false

CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(0)
    end

    while not ESX do
        ESX = exports["es_extended"]:getSharedObject()
        Wait(0)
    end

    while not ESX.IsPlayerLoaded() do
        Wait(500)
    end

    Wait(FS_BELLS.settings.load_delay)

    TriggerServerEvent("fs_bells:frakklingel:onJoin")

    IsLoaded = true
end)

RegisterNetEvent("fs_bells:frakklingel:sendBells", function(data)
    if (not data) then return end
    Bells = data
end)

CreateThread(function()
    while (true) do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        if (IsLoaded) then
            for _, bell in next, Bells do
                local dist = #(coords - vec3(bell.coords.x, bell.coords.y, bell.coords.z))

                if (dist <= 15.0) then
                    sleep = 0

                    DrawMarker(FS_BELLS.marker.type, bell.coords.x, bell.coords.y, bell.coords.z,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        FS_BELLS.marker.scale.x, FS_BELLS.marker.scale.y, FS_BELLS.marker.scale.z,
                        FS_BELLS.marker.rgba.r, FS_BELLS.marker.rgba.g, FS_BELLS.marker.rgba.b, FS_BELLS.marker.rgba.a,
                        FS_BELLS.marker.bobUpAndDown, FS_BELLS.marker.faceCamera, FS_BELLS.marker.rotate, false, nil, nil,
                        false)

                    if (dist <= 1.0) then
                        FS_BELLS.HelpNotify("E", ("um bei %s zu klingeln"):format(bell.label))

                        if IsControlJustPressed(0, FS_BELLS.settings.controls["E"]) then
                            Klingel(bell.job, bell.label)
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

function Klingel(faction, label)
    if (not IsLoaded) then
        return print("[FS_BELLS] >> Bells are not loaded")
    end

    PlayAnim("anim@apt_trans@buzzer", "buzz_reg", 5000, function()
        ESX.TriggerServerCallback("fs_bells:frakklingel:klingel", function(cbdata)
            if (cbdata.success) then
                Notify("info", "Information", cbdata.message)
            else
                Notify("error", "Information", cbdata.message)
            end
        end, faction, label)
    end)
end

function PlayAnim(dict, anim, time, cb)
    ESX.Streaming.RequestAnimDict(dict, function()
        if HasAnimDictLoaded(dict) then
            TaskPlayAnim(PlayerPedId(), dict, anim, 8.0, -8.0, time, 0, 0, false, false, false)

            CreateThread(function()
                Wait(time)

                if cb then
                    cb()
                end
            end)
        end
    end)
end

function CreateBell()
    local currBell = {
        job = "",
        label = "",
        coords = vec3(0.0, 0.0, 0.0),
    }

    local elms = {
        { label = "Job Name",    value = "create_name" },
        { label = "Job Label",   value = "create_label" },
        { label = "Koordinaten", value = "create_coords" },
        { label = "Erstellen",   value = "create_bell" },
    }

    ESX.UI.Menu.Open("default", GetCurrentResourceName(), "create_bells", {
        title = "Frakklingel",
        elements = elms,
    }, function(data, menu)
        if data.current.value == "create_name" then
            local name = CreateInput("Job Name")
            if name and name.submit and name.value and name.value ~= "" then
                currBell.job = name.value
            end

            menu.removeElement({ value = data.current.value })
            menu.refresh()
        elseif data.current.value == "create_label" then
            local label = CreateInput("Job Label")
            if label and label.submit and label.value and label.value ~= "" then
                currBell.label = label.value
            end

            menu.removeElement({ value = data.current.value })
            menu.refresh()
        elseif data.current.value == "create_coords" then
            currBell.coords = GetEntityCoords(PlayerPedId())

            menu.removeElement({ value = data.current.value })
            menu.refresh()
        elseif data.current.value == "create_bell" then
            if currBell.job == "" then
                return Notify("error", "Information", "Bitte setze einen Namen für den Job")
            end

            if currBell.label == "" then
                return Notify("error", "Information", "Bitte setze ein Label für den Job")
            end

            if currBell.coords == vec3(0.0, 0.0, 0.0) then
                return Notify("error", "Information", "Bitte setze die Koordinaten")
            end

            TriggerServerEvent('fs_bells:frakklingel:createBell', currBell.job, currBell.label, currBell.coords)

            menu.close()
        end
    end, function(data, menu)
        menu.close()
    end)
end

function DeleteBell()
    local elms = {}

    for _, bell in next, Bells do
        table.insert(elms, { label = bell.label, value = bell.job })
    end

    ESX.UI.Menu.Open("default", GetCurrentResourceName(), "delete_bells", {
        title = "Frakklingel",
        elements = elms,
    }, function(data, menu)
        if data.current.value then
            TriggerServerEvent('fs_bells:frakklingel:deleteBell', data.current.value)
            menu.close()
        end
    end, function(data, menu)
        menu.close()
    end)
end

function ManageBells()
    ESX.UI.Menu.Open("default", GetCurrentResourceName(), "manage_bells", {
        title = "Frakklingel",
        elements = {
            { label = "Erstellen", value = "create_bell" },
            { label = "Löschen",   value = "delete_bell" },
        },
    }, function(data, menu)
        if data.current.value == "create_bell" then
            CreateBell()
        elseif data.current.value == "delete_bell" then
            DeleteBell()
        end
    end, function(data, menu)
        menu.close()
    end)
end

function CreateInput(title)
    local input = promise.new()

    ESX.UI.Menu.Open("dialog", GetCurrentResourceName(), "create_bell_input", {
        title = title,
    }, function(data, menu)
        input:resolve({
            submit = true,
            value = data.value,
            menu = menu,
        })

        menu.close()
    end, function(data, menu)
        input:resolve({
            submit = false,
            value = data.value,
            menu = menu,
        })

        menu.close()
    end)

    Citizen.Await(input)

    return input.value
end

RegisterCommand(FS_BELLS.settings.command, function()
    if (not IsLoaded) then
        return print("[FS_BELLS] >> Bells are not loaded")
    end

    ESX.TriggerServerCallback("fs_bells:frakklingel:hasPerms", function(success)
        if (success) then
            ManageBells()
        else
            Notify("error", "Information", "Du hast keine Berechtigung hierfür!")
        end
    end)
end, false)

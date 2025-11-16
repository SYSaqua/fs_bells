FS_BELLS = {
    settings = {
        load_delay = 5000,
        timeout = 15, -- Sekunden
        command = "bells",
        controls = {
            ["E"] = 38,
        },
    },

    marker = {
        type = 0,
        scale = vec3(0.7, 0.7, 0.7),
        rgba = {
            r = 76,
            g = 228,
            b = 155,
            a = 144
        },
        bobUpAndDown = false,
        faceCamera = false,
        rotate = false,
    },

    admin = {
        ["pl"] = true,
    }
}

function FS_BELLS.HelpNotify(key, msg)
    TriggerEvent("novana_hud:helpnotify", key, msg)
end

if not IsDuplicityVersion() then
    function Notify(type, title, message, time)
        TriggerEvent("novana_hud:notify", type, title, message, time)
    end
else
    function Notify(source, type, title, message, time)
        TriggerClientEvent("novana_hud:notify", source, type, title, message, time)
    end
end

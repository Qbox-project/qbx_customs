local originalPaint = {}
local lastIndex
local primaryPaint
local config = require 'config.client'
local sharedConfig = require 'config.shared'

local function paintMods()
    local options = {}

    local primary, secondary = GetVehicleColours(vehicle)
    originalPaint.primary = primary
    originalPaint.secondary = secondary

    for category, values in pairs(config.paints) do
        local labels = {}
        local ids = {}
        local selectedIndex = 1

        for i, paint in ipairs(values) do
            labels[i] = paint.label
            ids[i] = paint.id
            if paint.id == primary then
                selectedIndex = i
            end
        end

        options[#options + 1] = {
            ids = ids,
            description = ('%s%s'):format(config.currency, sharedConfig.prices['colors']),
            label = category,
            values = labels,
            close = true,
            defaultIndex = selectedIndex,
        }
    end

    table.sort(options, function(a, b)
        return a.label < b.label
    end)

    return options
end


local menu = {
    id = 'customs-paint',
    canClose = true,
    disableInput = false,
    position = 'top-left',
    options = {},
}

local function onSubmit(selected, scrollIndex, bypassPayment)
    local option = menu.options[selected]

    for _, v in pairs(menu.options) do
        v.restore()
    end

    local duplicate, desc = option.set(scrollIndex)

    local success = InstallMod(duplicate, 'colors', {
        description = desc,
    }, nil, bypassPayment)

    if not success then menu.options[selected].restore() end

    lib.setMenuOptions(menu.id, paintMods())
    lib.showMenu(menu.id, lastIndex)
end

menu.onClose = function()
    SetVehicleColours(vehicle, originalPaint.primary, originalPaint.secondary)
    lib.showMenu('customs-colors', ColorsLastIndex)
end

menu.onSelected = function(selected)
    PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    lastIndex = selected
end

menu.onSideScroll = function(selected, scrollIndex)
    PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    local option = menu.options[selected]
    if primaryPaint then
        SetVehicleColours(vehicle, option.ids[scrollIndex], originalPaint.secondary)
    else
        SetVehicleColours(vehicle, originalPaint.primary, option.ids[scrollIndex])
    end
end

---@param primary boolean
return function(bypassPayment)
    menu.options = paintMods()
    lib.registerMenu(menu, function(selected, scrollIndex)
        onSubmit(selected, scrollIndex, bypassPayment)
    end)
    return menu.id
end

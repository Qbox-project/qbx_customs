lib.versionCheck('Qbox-project/qbx_customs')
local sharedConfig = require 'config.shared'
local authorizedSaves = {}

---@param plate string
---@return string
local function normalizePlate(plate)
    return plate:match('^%s*(.-)%s*$')
end

---@param point vector3
---@param polygon vector3[]
---@return boolean
local function isPointInPolygon(point, polygon)
    local inside = false
    local previous = #polygon

    for current = 1, #polygon do
        local currentPoint = polygon[current]
        local previousPoint = polygon[previous]
        if math.abs(point.z - currentPoint.z) <= 10.0
            and (currentPoint.y > point.y) ~= (previousPoint.y > point.y)
            and point.x < (previousPoint.x - currentPoint.x) * (point.y - currentPoint.y)
                / (previousPoint.y - currentPoint.y) + currentPoint.x then
            inside = not inside
        end
        previous = current
    end

    return inside
end

---@param source number
---@return integer?, ZoneOptions?
local function getCurrentZone(source)
    local ped = GetPlayerPed(source)
    if ped == 0 then return end

    local coords = GetEntityCoords(ped)
    for i = 1, #sharedConfig.zones do
        if isPointInPolygon(coords, sharedConfig.zones[i].points) then
            return i, sharedConfig.zones[i]
        end
    end
end

---@param source number
---@return table?, number?, string?
local function getVehicleContext(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local ped = GetPlayerPed(source)
    if ped == 0 then return end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 or not DoesEntityExist(vehicle) or GetPedInVehicleSeat(vehicle, -1) ~= ped then return end

    local plate = normalizePlate(GetVehicleNumberPlateText(vehicle))
    if plate == '' then return end

    return player, vehicle, plate
end

---@param source number
---@param vehicle number
---@param plate string
local function authorizeSave(source, vehicle, plate)
    authorizedSaves[source] = {
        vehicle = vehicle,
        plate = plate,
        expiresAt = os.time() + 300,
    }
end

---@return number?
local function getModPrice(mod, level)
    local price = sharedConfig.prices[mod]
    if type(price) == 'table' then
        if type(level) ~= 'number' or level % 1 ~= 0 then return end
        price = price[level]
    end

    if type(price) ~= 'number' or price ~= price or price < 0 then return end
    return price
end

---@param source number
---@param amount number
---@return boolean
local function removeMoney(source, amount)
    local player = exports.qbx_core:GetPlayer(source)
    if not player or type(amount) ~= 'number' or amount < 0 then return false end
    if amount == 0 then return true end

    local cashBalance = player.Functions.GetMoney('cash')
    local bankBalance = player.Functions.GetMoney('bank')

    if cashBalance >= amount then
        return player.Functions.RemoveMoney('cash', amount, locale('general.payReason'))
    elseif bankBalance >= amount then
        local paid = player.Functions.RemoveMoney('bank', amount, locale('general.payReason'))
        if paid then exports.qbx_core:Notify(source, locale('notifications.success.paid', amount), 'success') end
        return paid
    end

    return false
end

-- Won't charge money for mods if the player's job is in the list
lib.callback.register('qbx_customs:server:pay', function(source, mod, level)
    local _, zone = getCurrentZone(source)
    local player, vehicle, plate = getVehicleContext(source)
    local price = getModPrice(mod, level)
    if not zone or not player or not vehicle or not plate or not price then return false end

    if zone.freeMods then
        local playerJob = player.PlayerData.job.name
        for i = 1, #zone.freeMods do
            if playerJob == zone.freeMods[i] then
                authorizeSave(source, vehicle, plate)
                return true
            end
        end
    end

    local paid = removeMoney(source, price)
    if paid then authorizeSave(source, vehicle, plate) end
    return paid
end)

-- Won't charge money for repairs if the player's job is in the list
lib.callback.register('qbx_customs:server:repair', function(source, bodyHealth)
    local _, zone = getCurrentZone(source)
    local player, vehicle, plate = getVehicleContext(source)
    if not zone or not player or not vehicle or not plate then return false end

    if zone.freeRepair then
        local playerJob = player.PlayerData.job.name
        for i = 1, #zone.freeRepair do
            if playerJob == zone.freeRepair[i] then
                authorizeSave(source, vehicle, plate)
                return true
            end
        end
    end

    bodyHealth = tonumber(bodyHealth)
    if not bodyHealth or bodyHealth ~= bodyHealth then bodyHealth = 1000.0 end
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local health = math.max(0.0, math.min(1000.0, engineHealth, bodyHealth))
    local paid = removeMoney(source, math.ceil(1000.0 - health))
    if paid then authorizeSave(source, vehicle, plate) end
    return paid
end)

local function isVehicleOwnedBy(plate, citizenid)
    return MySQL.scalar.await('SELECT 1 FROM player_vehicles WHERE plate = ? AND citizenid = ?', {
        plate, citizenid
    }) ~= nil
end

--Copied from qb-mechanicjob
RegisterNetEvent('qbx_customs:server:saveVehicleProps', function()
    local src = source --[[@as number]]
    local authorization = authorizedSaves[src]
    authorizedSaves[src] = nil
    if not authorization or authorization.expiresAt < os.time() then return end

    local player, vehicle, plate = getVehicleContext(src)
    if not player or vehicle ~= authorization.vehicle or plate ~= authorization.plate then return end

    local vehicleProps = lib.callback.await('qbx_customs:client:vehicleProps', src)
    if type(vehicleProps) ~= 'table' or type(vehicleProps.plate) ~= 'string'
        or normalizePlate(vehicleProps.plate) ~= plate
        or not isVehicleOwnedBy(plate, player.PlayerData.citizenid) then return end

    MySQL.update.await('UPDATE player_vehicles SET mods = ? WHERE plate = ? AND citizenid = ?', {
        json.encode(vehicleProps), plate, player.PlayerData.citizenid
    })
end)

AddEventHandler('playerDropped', function()
    authorizedSaves[source] = nil
end)

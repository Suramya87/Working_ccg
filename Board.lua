local Board = {}
Board.__index = Board

local function createZoneSlots(zoneIndex, xStart)
    local zone = {
        name = "Zone " .. zoneIndex,
        playerSlots = {},
        aiSlots = {},
    }

    local cols, rows = 2, 2
    local slotWidth, slotHeight = 100, 140
    local spacingX, spacingY = 120, 160
    local gapBetweenZones = 320
    local zoneXOffset = (zoneIndex - 1) * gapBetweenZones
    local zoneCenterX = xStart + zoneXOffset

    local aiYStart = 100
    local playerYStart = aiYStart + (rows * spacingY) + 40

    local function createGrid(xCenter, yTop)
        local slots = {}
        local startX = xCenter - ((cols - 1) * spacingX) / 2
        for row = 1, rows do
            for col = 1, cols do
                table.insert(slots, {
                    x = startX + (col - 1) * spacingX,
                    y = yTop + (row - 1) * spacingY,
                    width = slotWidth,
                    height = slotHeight,
                    card = nil,
                })
            end
        end
        return slots
    end

    zone.aiSlots = createGrid(zoneCenterX, aiYStart)
    zone.playerSlots = createGrid(zoneCenterX, playerYStart)

    -- Dynamically calculate bounding box
    local allSlots = {}
    for _, slot in ipairs(zone.aiSlots) do table.insert(allSlots, slot) end
    for _, slot in ipairs(zone.playerSlots) do table.insert(allSlots, slot) end

    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    for _, slot in ipairs(allSlots) do
        minX = math.min(minX, slot.x)
        minY = math.min(minY, slot.y)
        maxX = math.max(maxX, slot.x + slot.width)
        maxY = math.max(maxY, slot.y + slot.height)
    end

    zone.x = minX - 10
    zone.y = minY - 10
    zone.width = (maxX - minX) + 20
    zone.height = (maxY - minY) + 20

    return zone
end

function Board.new()
    local self = setmetatable({}, Board)
    local startX = 200
    self.zones = {
        createZoneSlots(1, startX),
        createZoneSlots(2, startX),
        createZoneSlots(3, startX),
    }
    return self
end

function Board:draw()
    for i, zone in ipairs(self.zones) do
        -- Draw zone outline
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("line", zone.x, zone.y, zone.width, zone.height)

        local zoneLabelX = zone.playerSlots[1].x
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Zone " .. i, zoneLabelX, zone.y - 20)

        -- Draw AI slots
        for _, slot in ipairs(zone.aiSlots) do
            love.graphics.setColor(1, 0.8, 0.8)
            love.graphics.rectangle("line", slot.x, slot.y, slot.width, slot.height)
            if slot.card then slot.card:draw() end
        end

        -- Draw Player slots
        for _, slot in ipairs(zone.playerSlots) do
            love.graphics.setColor(0.8, 0.8, 1)
            love.graphics.rectangle("line", slot.x, slot.y, slot.width, slot.height)
            if slot.card then slot.card:draw() end
        end

        -- Draw power totals
        local playerPower, aiPower = self:calculateZonePower(zone)
        love.graphics.setColor(0.6, 0.6, 1)
        love.graphics.print("Player Power: " .. playerPower, zone.x + 10, zone.y + zone.height - 40)
        love.graphics.setColor(1, 0.6, 0.6)
        love.graphics.print("AI Power: " .. aiPower, zone.x + 10, zone.y + zone.height - 20)
    end
end

function Board:getHoveredSlot(x, y)
    for _, zone in ipairs(self.zones) do
        for _, slot in ipairs(zone.playerSlots) do
            if x >= slot.x and x <= slot.x + slot.width and
               y >= slot.y and y <= slot.y + slot.height then
                return slot
            end
        end
    end
    return nil
end

function Board:calculateZonePower(zone)
    local playerPower, aiPower = 0, 0
    for _, slot in ipairs(zone.playerSlots) do
        if slot.card then
            playerPower = playerPower + (slot.card.power or 0)
        end
    end
    for _, slot in ipairs(zone.aiSlots) do
        if slot.card then
            aiPower = aiPower + (slot.card.power or 0)
        end
    end
    return playerPower, aiPower
end

return Board

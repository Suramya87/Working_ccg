local Card = require("Card")
local Board = require("Board")

local playerHand = {}
local draggingCard = nil
local dragOffsetX, dragOffsetY = 0, 0
local board

function love.load()
    board = Board.new()
    loadCardsFromCSV("cards.csv")
end

function loadCardsFromCSV(filename)
    local file = love.filesystem.read(filename)
    local lines = {}
    for line in file:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    -- First line is the header
    for i = 2, math.min(5, #lines) do
        local name, cost, power = lines[i]:match("([^,]+),([^,]+),([^,]+)")
        if name and cost and power then
            local x = 100 + (#playerHand) * 110
            local y = 500
            table.insert(playerHand, Card.new(name, cost, power, x, y))
        end
    end
end

function love.update(dt)
end

function love.draw()
    board:draw()

    for _, card in ipairs(playerHand) do
        card:draw()
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        for _, card in ipairs(playerHand) do
            if card:contains(x, y) then
                draggingCard = card
                dragOffsetX = x - card.x
                dragOffsetY = y - card.y
                break
            end
        end
    end
end

function love.mousemoved(x, y, dx, dy)
    if draggingCard then
        draggingCard.x = x - dragOffsetX
        draggingCard.y = y - dragOffsetY
    end
end

function love.mousereleased(x, y, button)
    if draggingCard and button == 1 then
        local slot = board:getHoveredSlot(x, y)
        if slot and not slot.card then
            slot.card = draggingCard

            -- Remove from hand
            for i, c in ipairs(playerHand) do
                if c == draggingCard then
                    table.remove(playerHand, i)
                    break
                end
            end

            -- Snap to slot
            draggingCard.x = slot.x
            draggingCard.y = slot.y
        end

        draggingCard = nil
    end
end

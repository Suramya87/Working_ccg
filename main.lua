local Card = require("Card")
local Board = require("Board")

local board
local playerDeck = {}
local aiDeck = {}
local playerHand = {}
local aiHand = {}
local draggingCard = nil
local dragOffsetX, dragOffsetY = 0, 0

function love.load()
    board = Board.new()
    loadDecksFromCSV("cards.csv")

    drawCards(playerDeck, playerHand, 5)
    drawCards(aiDeck, aiHand, 5)
end

function loadDecksFromCSV(filename)
    local file = love.filesystem.read(filename)
    local lines = {}
    for line in file:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    -- Skip header, load into both decks
    for i = 2, #lines do
        local name, cost, power = lines[i]:match("([^,]+),([^,]+),([^,]+)")
        if name and cost and power then
            table.insert(playerDeck, {name = name, cost = tonumber(cost), power = tonumber(power)})
            table.insert(aiDeck, {name = name, cost = tonumber(cost), power = tonumber(power)})
        end
    end

    shuffleDeck(playerDeck)
    shuffleDeck(aiDeck)
end

function shuffleDeck(deck)
    for i = #deck, 2, -1 do
        local j = love.math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

function drawCards(deck, hand, num)
    for i = 1, num do
        if #deck > 0 then
            local cardData = table.remove(deck, 1)
            local x = 100 + (#hand) * 110
            local y = hand == playerHand and 500 or 100
            table.insert(hand, Card.new(cardData.name, cardData.cost, cardData.power, x, y))
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

    for _, card in ipairs(aiHand) do
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

            -- Re-layout player hand
            layoutHand(playerHand, 500)

            -- End turn → AI plays
            aiTurn()
        end

        draggingCard = nil
    end
end

function layoutHand(hand, y)
    for i, card in ipairs(hand) do
        card.x = 100 + (i - 1) * 110
        card.y = y
    end
end

function aiTurn()
    for _, card in ipairs(aiHand) do
        -- Find first empty AI slot
        local slot = board:getEmptySlotForAI()
        if slot then
            slot.card = card
            card.x = slot.x
            card.y = slot.y

            -- Remove card from AI hand
            for i, c in ipairs(aiHand) do
                if c == card then
                    table.remove(aiHand, i)
                    break
                end
            end
            break -- AI plays only one card per turn
        end
    end

    -- AI draws one card
    drawCards(aiDeck, aiHand, 1)
end

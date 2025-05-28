local Card = require("Card")
local Board = require("Board")

local board
local playerDeck = {}
local aiDeck = {}
local playerHand = {}
local aiHand = {}
local draggingCard = nil
local dragOffsetX, dragOffsetY = 0, 0

local HAND_LIMIT = 5
local drawButton = { x = 20, y = 520, w = 80, h = 40 }
local submitButton = { x = 110, y = 520, w = 80, h = 40 }

local playerPoints = 0
local aiPoints = 0

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

function layoutHand(hand, y)
    for i, card in ipairs(hand) do
        card.x = 100 + (i - 1) * 110
        card.y = y
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

    -- Draw buttons
    love.graphics.setColor(0.4, 0.9, 0.4)
    love.graphics.rectangle("fill", drawButton.x, drawButton.y, drawButton.w, drawButton.h)
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf("Draw", drawButton.x, drawButton.y + 12, drawButton.w, "center")

    love.graphics.setColor(0.9, 0.6, 0.3)
    love.graphics.rectangle("fill", submitButton.x, submitButton.y, submitButton.w, submitButton.h)
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf("Submit", submitButton.x, submitButton.y + 12, submitButton.w, "center")

    -- Points and info
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Deck: " .. #playerDeck, 20, 10)
    love.graphics.print("Hand: " .. #playerHand .. "/" .. HAND_LIMIT, 20, 30)
    love.graphics.print("Player Points: " .. playerPoints, 20, 50)
    love.graphics.print("AI Points: " .. aiPoints, 20, 70)
end

function love.mousepressed(x, y, button)
    if button == 1 then
        if inRect(x, y, drawButton) then
            if #playerHand < HAND_LIMIT then
                drawCards(playerDeck, playerHand, 1)
                layoutHand(playerHand, 500)
            end
            return
        end

        if inRect(x, y, submitButton) then
            resolveCombat()
            return
        end

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

function inRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.w and
           y >= rect.y and y <= rect.y + rect.h
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

            for i, c in ipairs(playerHand) do
                if c == draggingCard then
                    table.remove(playerHand, i)
                    break
                end
            end

            draggingCard.x = slot.x
            draggingCard.y = slot.y
            layoutHand(playerHand, 500)

            aiTurn()
        end

        draggingCard = nil
    end
end

function aiTurn()
    for _, card in ipairs(aiHand) do
        local slot = board:getEmptySlotForAI()
        if slot then
            slot.card = card
            card.x = slot.x
            card.y = slot.y

            for i, c in ipairs(aiHand) do
                if c == card then
                    table.remove(aiHand, i)
                    break
                end
            end
            break
        end
    end

    drawCards(aiDeck, aiHand, 1)
end

function resolveCombat()
    local zones = board.zones
    for _, zone in ipairs(zones) do
        for i = 1, 4 do
            local pSlot = zone.playerSlots[i]
            local aSlot = zone.aiSlots[i]
            local pCard = pSlot.card
            local aCard = aSlot.card

            if pCard and aCard then
                if pCard.power > aCard.power then
                    playerPoints = playerPoints + 1
                elseif aCard.power > pCard.power then
                    aiPoints = aiPoints + 1
                end
            elseif pCard and not aCard then
                playerPoints = playerPoints + 1
            elseif aCard and not pCard then
                aiPoints = aiPoints + 1
            end

            pSlot.card = nil
            aSlot.card = nil
        end
    end
end

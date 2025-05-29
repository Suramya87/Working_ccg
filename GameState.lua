local Card = require("Card")
local Board = require("Board")

local GameState = {}
GameState.__index = GameState

local HAND_LIMIT = 7

function GameState:new()
    local self = setmetatable({}, GameState)

    self.board = Board.new()

    self.playerDeck = {}
    self.aiDeck = {}
    self.playerHand = {}
    self.aiHand = {}

    self.playerPoints = 0
    self.aiPoints = 0

    -- Game phases: "play" = player plays cards, "reveal" = show AI cards and resolve
    self.phase = "play"

    -- Buttons
    self.drawButton = { x = 20, y = 520, w = 80, h = 40 }
    self.submitButton = { x = 110, y = 520, w = 80, h = 40 }
    self.continueButton = { x = 200, y = 520, w = 80, h = 40 }

    -- Load decks (you can replace with CSV loading or however you want)
    self:loadDecks()
    self:shuffleDeck(self.playerDeck)
    self:shuffleDeck(self.aiDeck)

    -- Draw initial hands
    self:drawCards(self.playerDeck, self.playerHand, 3)
    self:drawCards(self.aiDeck, self.aiHand, 3)

    return self
end

function GameState:loadDecks()
    -- Simple example deck, replace with CSV loading if needed
    for i = 1, 20 do
        local cost = (i % 3) + 1
        local power = (i % 5) + 1
        table.insert(self.playerDeck, Card.new("Card " .. i, cost, power, 0, 0))
        table.insert(self.aiDeck, Card.new("Card " .. i, cost, power, 0, 0))
    end
end

function GameState:shuffleDeck(deck)
    for i = #deck, 2, -1 do
        local j = love.math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

function GameState:drawCards(deck, hand, num)
    for i = 1, num do
        if #deck > 0 then
            local card = table.remove(deck, 1)
            -- Position cards in hand; actual layout done later
            card.x = 0
            card.y = 0
            table.insert(hand, card)
        end
    end
    self:layoutHand(hand)
end

function GameState:layoutHand(hand)
    local y = (hand == self.playerHand) and 500 or 100
    for i, card in ipairs(hand) do
        card.x = 100 + (i - 1) * 110
        card.y = y
    end
end

function GameState:update(dt)
    -- no update logic yet
end

function GameState:draw()
    self.board:draw()

    -- Draw player's hand always visible with names
    for _, card in ipairs(self.playerHand) do
        card:draw()
    end

    -- Draw AI's hand normally with names (no hiding)
    for _, card in ipairs(self.aiHand) do
        card:draw()
    end

    -- Draw AI cards placed on board slots:
    for _, zone in ipairs(self.board.zones) do
        for i = 1, 4 do
            local aiSlot = zone.aiSlots[i]
            local card = aiSlot.card
            if card then
                if self.phase == "play" then
                    -- Draw back of card (hidden) on the board slot
                    love.graphics.setColor(0.1, 0.1, 0.1)
                    love.graphics.rectangle("fill", card.x, card.y, card.width or 100, card.height or 140)
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.printf("???", card.x, card.y + 60, card.width or 100, "center")
                else
                    -- Reveal card
                    card:draw()
                end
            end
        end
    end

    -- Draw buttons based on phase
    love.graphics.setColor(0.4, 0.9, 0.4)
    if self.phase == "play" then
        love.graphics.rectangle("fill", self.drawButton.x, self.drawButton.y, self.drawButton.w, self.drawButton.h)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Draw", self.drawButton.x, self.drawButton.y + 12, self.drawButton.w, "center")

        love.graphics.setColor(0.9, 0.6, 0.3)
        love.graphics.rectangle("fill", self.submitButton.x, self.submitButton.y, self.submitButton.w, self.submitButton.h)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Submit", self.submitButton.x, self.submitButton.y + 12, self.submitButton.w, "center")
    elseif self.phase == "reveal" then
        love.graphics.setColor(0.4, 0.9, 0.4)
        love.graphics.rectangle("fill", self.continueButton.x, self.continueButton.y, self.continueButton.w, self.continueButton.h)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Continue", self.continueButton.x, self.continueButton.y + 12, self.continueButton.w, "center")
    end

    -- Draw points and info
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Deck: " .. #self.playerDeck, 20, 10)
    love.graphics.print("Hand: " .. #self.playerHand .. "/" .. HAND_LIMIT, 20, 30)
    love.graphics.print("Player Points: " .. self.playerPoints, 20, 50)
    love.graphics.print("AI Points: " .. self.aiPoints, 20, 70)

    -- Draw AI cards count (hand size)
    love.graphics.print("AI Cards in Hand: " .. #self.aiHand, 20, 90)
end


function GameState:mousepressed(x, y, button)
    if button ~= 1 then return end

    if self.phase == "play" then
        if self:inRect(x, y, self.drawButton) then
            if #self.playerHand < HAND_LIMIT then
                self:drawCards(self.playerDeck, self.playerHand, 1)
                self:layoutHand(self.playerHand)
            end
            return
        end

        if self:inRect(x, y, self.submitButton) then
            self:resolveCombat()
            self.phase = "reveal"
            return
        end

        -- Handle dragging player cards (simplified for example)
        for _, card in ipairs(self.playerHand) do
            if card:contains(x, y) then
                self.draggingCard = card
                self.dragOffsetX = x - card.x
                self.dragOffsetY = y - card.y
                break
            end
        end
    elseif self.phase == "reveal" then
        if self:inRect(x, y, self.continueButton) then
            self:nextRound()
        end
    end
end

function GameState:mousemoved(x, y, dx, dy)
    if self.draggingCard then
        self.draggingCard.x = x - self.dragOffsetX
        self.draggingCard.y = y - self.dragOffsetY
    end
end

function GameState:mousereleased(x, y, button)
    if button ~= 1 or not self.draggingCard then return end

    local slot = self.board:getHoveredSlot(x, y)
    if slot and not slot.card and self.phase == "play" then
        slot.card = self.draggingCard

        for i, c in ipairs(self.playerHand) do
            if c == self.draggingCard then
                table.remove(self.playerHand, i)
                break
            end
        end

        self.draggingCard.x = slot.x
        self.draggingCard.y = slot.y
        self:layoutHand(self.playerHand)

        self:aiTurn()
    end

    self.draggingCard = nil
end

function GameState:aiTurn()
    -- AI places one card during play phase only
    if self.phase ~= "play" then return end

    for _, card in ipairs(self.aiHand) do
        local slot = self.board:getEmptySlotForAI()
        if slot then
            slot.card = card
            card.x = slot.x
            card.y = slot.y

            for i, c in ipairs(self.aiHand) do
                if c == card then
                    table.remove(self.aiHand, i)
                    break
                end
            end
            break
        end
    end

    self:drawCards(self.aiDeck, self.aiHand, 1)
    self:layoutHand(self.aiHand)
end

function GameState:resolveCombat()
    -- Compute points based on cards on board and clear slots
    for _, zone in ipairs(self.board.zones) do
        for i = 1, 4 do
            local pSlot = zone.playerSlots[i]
            local aSlot = zone.aiSlots[i]
            local pCard = pSlot.card
            local aCard = aSlot.card

            if pCard and aCard then
                if pCard.power > aCard.power then
                    self.playerPoints = self.playerPoints + 1
                elseif aCard.power > pCard.power then
                    self.aiPoints = self.aiPoints + 1
                end
            elseif pCard and not aCard then
                self.playerPoints = self.playerPoints + 1
            elseif aCard and not pCard then
                self.aiPoints = self.aiPoints + 1
            end
        end
    end
end

function GameState:nextRound()
    -- Clear board
    for _, zone in ipairs(self.board.zones) do
        for i = 1, 4 do
            zone.playerSlots[i].card = nil
            zone.aiSlots[i].card = nil
        end
    end

    self.phase = "play"

    -- Draw new cards if possible
    self:drawCards(self.playerDeck, self.playerHand, 3)
    self:drawCards(self.aiDeck, self.aiHand, 3)

    self:layoutHand(self.playerHand)
    self:layoutHand(self.aiHand)
end

function GameState:inRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.w and
           y >= rect.y and y <= rect.y + rect.h
end

return GameState

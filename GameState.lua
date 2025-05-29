local Card = require("Card")
local Board = require("Board")

local GameState = {}
GameState.__index = GameState

local WINNING_POINTS = 5

local HAND_LIMIT = 7

function GameState:new()
    local self = setmetatable({}, GameState)
    self.turn = 1
    self.mana = 1
    
    self.playerManaUsed = 0
    self.aiManaUsed = 0



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

local function parseCSVLine(line)
    local res = {}
    for token in string.gmatch(line, '([^,]+)') do
        table.insert(res, token)
    end
    return res
end

function GameState:loadDecks()
    local path = "cards.csv"
    local file = love.filesystem.read(path)
    if not file then
        print("Failed to load cards.csv, using default deck")
        -- fallback to default
        for i = 1, 20 do
            local cost = (i % 3) + 1
            local power = (i % 5) + 1
            table.insert(self.playerDeck, Card.new("Card " .. i, cost, power, 0, 0))
            table.insert(self.aiDeck, Card.new("Card " .. i, cost, power, 0, 0))
        end
        return
    end

    local lines = {}
    for line in file:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    -- First line is header, skip it
    for i = 2, #lines do
        local values = parseCSVLine(lines[i])
        local name = values[1]
        local cost = tonumber(values[2]) or 1
        local power = tonumber(values[3]) or 1

        -- For simplicity, 0,0 initial pos
        local card1 = Card.new(name, cost, power, 0, 0)
        local card2 = Card.new(name, cost, power, 0, 0)
        table.insert(self.playerDeck, card1)
        table.insert(self.aiDeck, card2)
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
    
            -- Draw Player mana info
    love.graphics.print("Player Mana: " .. self.mana, 200, 10)
    love.graphics.print("Player Mana Used: " .. self.playerManaUsed, 200, 30)

    -- Draw AI mana info
    love.graphics.print("AI Mana: " .. self.mana, 350, 10)
    love.graphics.print("AI Mana Used: " .. self.aiManaUsed, 350, 30)

    -- Draw AI cards count (hand size)
    love.graphics.print("AI Cards in Hand: " .. #self.aiHand, 20, 90)
    
    
    if self.phase == "gameover" then
    love.graphics.setColor(1, 0, 0)
    local msg = "Game Over! "
    if self.winner == "Tie" then
        msg = msg .. "It's a tie!"
    else
        msg = msg .. self.winner .. " wins!"
    end
    love.graphics.printf(msg, 0, 300, love.graphics.getWidth(), "center")
end

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
        -- Check if player has enough mana left
        if self.draggingCard.cost + self.playerManaUsed <= self.mana then
            -- Valid move
            slot.card = self.draggingCard
            self.playerManaUsed = self.playerManaUsed + self.draggingCard.cost

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
        else
            -- Not enough mana, reject the move and reset card position
            self.draggingCard.x = nil
            self.draggingCard.y = nil
            self:layoutHand(self.playerHand)
        end
    end

    self.draggingCard = nil
end



function GameState:aiTurn()
    if self.phase ~= "play" then return end

    -- Try placing as many cards as possible without exceeding mana
    local i = 1
    while i <= #self.aiHand do
        local card = self.aiHand[i]
        if card.cost + self.aiManaUsed <= self.mana then
            local slot = self.board:getEmptySlotForAI()
            if slot then
                -- Place the card
                slot.card = card
                card.x = slot.x
                card.y = slot.y

                self.aiManaUsed = self.aiManaUsed + card.cost
                table.remove(self.aiHand, i) -- Remove from AI hand after placement
            else
                break -- No more slots available
            end
        else
            i = i + 1 -- Skip to next card if this one can't be placed
        end
    end
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
        -- Check for winner
    if self.playerPoints >= WINNING_POINTS or self.aiPoints >= WINNING_POINTS then
        if self.playerPoints > self.aiPoints then
            self.winner = "Player"
        elseif self.aiPoints > self.playerPoints then
            self.winner = "AI"
        else
            self.winner = "Tie"
        end
        self.phase = "gameover"
end

end

function GameState:nextRound()
    -- Clear board slots
    for _, zone in ipairs(self.board.zones) do
        for i = 1, 4 do
            zone.playerSlots[i].card = nil
            zone.aiSlots[i].card = nil
        end
    end

    -- Increase turn and update mana
    self.turn = (self.turn or 1) + 1
    self.mana = self.turn

    -- Reset used mana
    self.playerManaUsed = 0
    self.aiManaUsed = 0

    -- Draw 1 card if hand size < 7
    self:drawCards(self.playerDeck, self.playerHand, 1)
    self:drawCards(self.aiDeck, self.aiHand, 1)

    -- Reset round state
    self.phase = "play"
    self.winner = nil
    self.draggingCard = nil

    -- Layout updated hands
    self:layoutHand(self.playerHand)
    self:layoutHand(self.aiHand)
end



function GameState:inRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.w and
           y >= rect.y and y <= rect.y + rect.h
end

return GameState

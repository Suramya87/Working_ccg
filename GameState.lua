local PlayerStats = require("PlayerStats")
local Board = require("Board")

local GameState = {}
GameState.__index = GameState

function GameState:new()
    local self = setmetatable({}, GameState)
    self.turn = 0
    self.phase = "play"
    self.board = Board.new()
    self.player = PlayerStats:new("Player")
    self.enemy = PlayerStats:new("Enemy")

    for i = 1, 20 do
        table.insert(self.player.deck, {name = "Card " .. i, cost = i % 3 + 1, power = i % 5 + 1})
        table.insert(self.enemy.deck, {name = "Card " .. i, cost = i % 3 + 1, power = i % 5 + 1})
    end

    math.randomseed(os.time())
    for _, deck in ipairs({self.player.deck, self.enemy.deck}) do
        for i = #deck, 2, -1 do
            local j = math.random(i)
            deck[i], deck[j] = deck[j], deck[i]
        end
    end

    for _ = 1, 3 do
        self.player:drawCard()
        self.enemy:drawCard()
    end

    self:startTurn()
    return self
end

function GameState:startTurn()
    self.turn = self.turn + 1
    self.player.mana = self.turn
    self.enemy.mana = self.turn
    self.player:drawCard()
    self.enemy:drawCard()
    self.phase = "play"
end

function GameState:submitTurn()
    self.phase = "resolution"

    for i = 1, 3 do
        local slots = self.enemy.board[i]
        while #slots < 4 and #self.enemy.hand > 0 do
            local idx = love.math.random(#self.enemy.hand)
            local card = table.remove(self.enemy.hand, idx)
            if self.enemy:canPlay(card) then
                self.enemy.mana = self.enemy.mana - card.cost
                table.insert(slots, card)
            end
        end
    end

    self:resolveCombat()
end

function GameState:resolveCombat()
    for i = 1, 3 do
        local playerPower, enemyPower = 0, 0
        for _, slot in ipairs(self.board.zones[i].playerSlots) do
            if slot.card then playerPower = playerPower + slot.card.power end
        end
        for _, slot in ipairs(self.board.zones[i].aiSlots) do
            local card = self.enemy.board[i][1]
            if card then
                slot.card = card
                enemyPower = enemyPower + card.power
                table.remove(self.enemy.board[i], 1)
            end
        end

        if playerPower > enemyPower then
            self.player.points = self.player.points + (playerPower - enemyPower)
        elseif enemyPower > playerPower then
            self.enemy.points = self.enemy.points + (enemyPower - playerPower)
        end
    end

    if self.player.points >= 20 or self.enemy.points >= 20 then
        self.phase = "gameover"
    else
        self:prepareNextTurn()
    end
end

function GameState:prepareNextTurn()
    for _, zone in ipairs(self.board.zones) do
        for _, slot in ipairs(zone.playerSlots) do slot.card = nil end
        for _, slot in ipairs(zone.aiSlots) do slot.card = nil end
    end

    for i = 1, 3 do
        self.player.board[i] = {}
        self.enemy.board[i] = {}
    end

    self:startTurn()
end

function GameState:draw()
    self.board:draw()

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Turn: " .. self.turn, 40, 20)
    love.graphics.print("Your Mana: " .. self.player.mana, 40, 40)
    love.graphics.print("Your Points: " .. self.player.points, 40, 60)
    love.graphics.print("Enemy Points: " .. self.enemy.points, 40, 80)

    if self.phase == "play" then
        love.graphics.rectangle("line", 600, 700, 150, 40)
        love.graphics.print("Submit Turn", 610, 710)
    elseif self.phase == "gameover" then
        local msg = self.player.points > self.enemy.points and "You Win!" or "You Lose!"
        love.graphics.setColor(1, 1, 0)
        love.graphics.print(msg, 400, 350, 0, 2, 2)
    end
end

function GameState:mousepressed(x, y, button)
    if button == 1 and self.phase == "play" then
        if x >= 600 and x <= 750 and y >= 700 and y <= 740 then
            self:submitTurn()
        end
    end
end

return GameState

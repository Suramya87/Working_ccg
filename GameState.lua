-- GameState.lua
local PlayerStats = require("PlayerStats")

local GameState = {}
GameState.__index = GameState

function GameState:new()
    local obj = {
        turn = 0,
        player = PlayerStats:new("Player"),
        enemy = PlayerStats:new("Enemy"),
        phase = "play",
    }

    -- Fill decks with 20 cards each (dummy cards for now)
    for i = 1, 20 do
        table.insert(obj.player.deck, {name = "Card " .. i, cost = i % 3 + 1, power = i % 5 + 1, text = ""})
        table.insert(obj.enemy.deck, {name = "Card " .. i, cost = i % 3 + 1, power = i % 5 + 1, text = ""})
    end

    -- Shuffle decks
    math.randomseed(os.time())
    for _, deck in ipairs({obj.player.deck, obj.enemy.deck}) do
        for i = #deck, 2, -1 do
            local j = math.random(i)
            deck[i], deck[j] = deck[j], deck[i]
        end
    end

    -- Draw starting hand
    for _ = 1, 3 do
        obj.player:drawCard()
        obj.enemy:drawCard()
    end

    setmetatable(obj, self)
    obj:startTurn()
    return obj
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

    -- Random enemy placement
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
        for _, c in ipairs(self.player.board[i]) do playerPower = playerPower + c.power end
        for _, c in ipairs(self.enemy.board[i]) do enemyPower = enemyPower + c.power end

        if playerPower > enemyPower then
            self.player.points = self.player.points + (playerPower - enemyPower)
        elseif enemyPower > playerPower then
            self.enemy.points = self.enemy.points + (enemyPower - playerPower)
        end
    end

    local winScore = 20
    if self.player.points >= winScore or self.enemy.points >= winScore then
        self.phase = "gameover"
    else
        self:prepareNextTurn()
    end
end

function GameState:prepareNextTurn()
    for i = 1, 3 do
        self.player.board[i] = {}
        self.enemy.board[i] = {}
    end
    self:startTurn()
end

function GameState:draw()
    love.graphics.print("Turn: " .. self.turn, 40, 20)
    love.graphics.print("Your Mana: " .. self.player.mana, 40, 40)
    love.graphics.print("Your Points: " .. self.player.points, 40, 60)
    love.graphics.print("Enemy Points: " .. self.enemy.points, 40, 80)

    if self.phase == "play" then
        love.graphics.rectangle("line", 600, 700, 150, 40)
        love.graphics.print("Submit Turn", 610, 710)
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

local Card = require("Card")

local PlayerStats = {}
PlayerStats.__index = PlayerStats

function PlayerStats:new(name)
    local self = setmetatable({}, PlayerStats)
    self.name = name
    self.mana = 0
    self.points = 0
    self.deck = {}
    self.hand = {}
    self.board = {{}, {}, {}}

    self:createDeck()
    self:shuffleDeck()

    return self
end

function PlayerStats:createDeck()
    for i = 1, 20 do
        local cost = (i % 3) + 1
        local power = (i % 5) + 1
        table.insert(self.deck, Card:new("Card " .. i, cost, power))
    end
end

function PlayerStats:shuffleDeck()
    for i = #self.deck, 2, -1 do
        local j = love.math.random(i)
        self.deck[i], self.deck[j] = self.deck[j], self.deck[i]
    end
end

function PlayerStats:drawCard(n)
    n = n or 1
    for i = 1, n do
        if #self.deck > 0 then
            local card = table.remove(self.deck, 1)
            table.insert(self.hand, card)
        end
    end
end

function PlayerStats:canPlay(card)
    return card.cost <= self.mana
end

return PlayerStats

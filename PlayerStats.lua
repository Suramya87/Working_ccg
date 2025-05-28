PlayerStats = {}
PlayerStats.__index = PlayerStats

function PlayerStats:new(name)
    local obj = {
        name = name,
        deck = {}, -- shuffled
        hand = {},
        board = { {}, {}, {} }, -- 3 locations
        mana = 1,
        points = 0,
    }
    setmetatable(obj, self)
    return obj
end

function PlayerStats:drawCard()
    if #self.deck > 0 and #self.hand < 7 then
        table.insert(self.hand, table.remove(self.deck))
    end
end

function PlayerStats:canPlay(card)
    return self.mana >= card.cost
end

function PlayerStats:playCard(card, locationIndex, slotIndex)
    if self:canPlay(card) and #self.board[locationIndex] < 4 then
        self.mana = self.mana - card.cost
        table.insert(self.board[locationIndex], card)
        -- remove from hand
        for i, c in ipairs(self.hand) do
            if c == card then
                table.remove(self.hand, i)
                break
            end
        end
    end
end

local Card = {}
Card.__index = Card

function Card.new(name, cost, power)
    local self = setmetatable({}, Card)
    self.name = name
    self.cost = cost
    self.power = power
    self.x, self.y = 0, 0
    return self
end

function Card:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x, self.y, 100, 140)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", self.x, self.y, 100, 140)
    love.graphics.print(self.name, self.x + 10, self.y + 10)
    love.graphics.print("Cost: " .. self.cost, self.x + 10, self.y + 30)
    love.graphics.print("Power: " .. self.power, self.x + 10, self.y + 50)
end

function Card:contains(x, y)
    return x >= self.x and x <= self.x + 100 and
           y >= self.y and y <= self.y + 140
end

return Card

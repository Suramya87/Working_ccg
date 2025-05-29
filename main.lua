local GameState = require("GameState")
local gameState

function love.load()
    gameState = GameState:new()  -- <-- Call `new`, NOT load
end

function love.update(dt)
    if gameState.update then
        gameState:update(dt)
    end
end

function love.draw()
    if gameState.draw then
        gameState:draw()
    end
end

function love.mousepressed(x, y, button)
    if gameState.mousepressed then
        gameState:mousepressed(x, y, button)
    end
end

function love.mousemoved(x, y, dx, dy)
    if gameState.mousemoved then
        gameState:mousemoved(x, y, dx, dy)
    end
end

function love.mousereleased(x, y, button)
    if gameState.mousereleased then
        gameState:mousereleased(x, y, button)
    end
end

local inspect = require("inspect")
local peachy = require("peachy")
local Animation = require("animation")
local List = require("list")
local Bank = require("bank")
local Promise = require("promise")

local bank = Bank({
  lama = {
    images = {
      blue = Bank.Asset.Image("assets/images/lama-blue.png")
    }
  },
  belt = {
    image = Bank.Asset.Image("assets/sprite/belt/belt.png"),
    spritesheet = Bank.Asset.SpriteSheet("assets/sprite/belt/belt.json")
  }
})

local state = {}

function love.load()
  bank:load()
end

function love.update(dt)
  if not bank:isLoaded() then
    local loaded = bank:update()

    if loaded then
      state.x = 0
      state.opacity = 0
      state.animation = Animation.Series({
        Animation.Parallel({
          Animation.Tween(2, state, {opacity = 1}),
          Animation.Tween(2, state, {x = 300}, "outSine"),
        }),
        Animation.Tween(2, state, {x = 0}, "inSine"),
      })
      state.sprite = peachy.new(bank.belt.spritesheet, bank.belt.image, "Roll")
    end
  else
    state.animation:update(dt)
    state.sprite:update(dt)
  end
end


function love.draw()
  if bank:isLoaded() then
    love.graphics.setColor(1, 1, 1, state.opacity)
    state.sprite:draw(state.x)
    love.graphics.setColor(1, 1, 1, 1)
  end
end
local inspect = require("inspect")
local peachy = require("peachy")
local Animation = require("animation")
local List = require("list")
local Bank = require("bank")
local Event = require("event")

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

      local animations = {
        reveal = Animation.Tween(1, state, {opacity = 1}),
        back = Animation.Tween(2, state, {x = 0, opacity = 0}, "inSine")
      }

      state.animation = Animation.Loop(
        Animation.Series({
          Animation.Parallel({
            animations.reveal,
            Animation.Tween(2, state, {x = 300}, "outSine"),
          }),
          animations.back,
        })
      )

      animations.back.onStart:subscribe(
        function ()
          print("going back!")
        end
      )

      animations.reveal.onStart:subscribe(
        function ()
          print("starts revealing")
        end
      )
      
      state.animation:start()
      state.sprite = peachy.new(bank.belt.spritesheet, bank.belt.image, "Roll")
    end
  else
    state.animation:update(dt)
    state.sprite:update(dt)
  end

  Event.scheduler:update()
end


function love.draw()
  if bank:isLoaded() then
    love.graphics.setColor(1, 1, 1, state.opacity)
    state.sprite:draw(state.x)
    love.graphics.setColor(1, 1, 1, 1)
  end
end
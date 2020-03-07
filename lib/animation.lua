local inspect = require("inspect")
local tween = require("tween")
local List = require("list")
local Object = require("classic")

local Animation = Object:extend()

Animation.Tween = Object:extend()

function Animation.Tween:new(duration, obj, target, algo)
  self.obj = obj
  self.tween = tween.new(duration, obj, target, algo)
end

function Animation.Tween:update(dt)
  return self.tween:update(dt)
end

Animation.Series = Object:extend()

function Animation.Series:new(animations)
  self.animations = animations
  self.index = 1
end

function Animation.Series:update(dt)
  local complete = self.animations[self.index]:update(dt)

  if complete and self.index < table.getn(self.animations) then
    complete = false
    self.index = self.index + 1
  end

  return complete
end

Animation.Parallel = Object:extend()

function Animation.Parallel:new(animations)
  self.animations = List(animations)
end

function Animation.Parallel:update(dt)
  local complete = true

  for animation in self.animations:values() do
    complete = animation:update(dt) and complete
  end

  return complete
end


return Animation
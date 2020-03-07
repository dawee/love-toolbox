local inspect = require("inspect")
local hash = require("hash")
local tween = require("tween")
local Event = require("event")
local List = require("list")
local Object = require("classic")

local Animation = Object:extend()

function Animation:new()
  self.onStart = Event()
  self.onComplete = Event()
  self.completed = false
end

function Animation:update(dt)
  if self.running and not self.completed and self:step(dt) then
    self.onComplete:trigger()
    self.completed = true
  end

  return self.completed
end

function Animation:start()
  if not self.running then
    self.running = true
    self.onStart:trigger()
  end
end

function Animation:reset()
  self.running = false
  self.completed = false
end

function Animation:stop()
  self.running = false
end

function Animation:step(dt)
  return true
end

Animation.Tween = Animation:extend()

function Animation.Tween:new(duration, obj, target, algo)
  Animation.new(self)

  self.obj = obj
  self.duration = duration
  self.target = target
  self.algo = algo

  self.tween = tween.new(self.duration, self.obj, hash.deepcopy(self.target), self.algo)
end

function Animation.Tween:reset()
  Animation.reset(self)

  self.tween = tween.new(self.duration, self.obj, hash.deepcopy(self.target), self.algo)
end


function Animation.Tween:step(dt)
  return self.tween:update(dt)
end

Animation.Parent = Animation:extend()

function Animation.Parent:new(children)
  Animation.new(self)

  self.children = List(children)

  for child in self.children:values() do
    child.parent = self
  end
end

function Animation.Parent:reset()
  Animation.reset(self)

  for child in self.children:values() do
    child:reset()
  end
end

Animation.Series = Animation.Parent:extend()

function Animation.Series:new(children)
  Animation.Parent.new(self, children)
  self.index = 1
end

function Animation.Series:reset()
  Animation.Parent.reset(self)
  self.index = 1
end

function Animation.Series:start()
  Animation.start(self)
  self.children:get(self.index):start()  
end

function Animation.Series:step(dt)
  local complete = self.children:get(self.index):update(dt)

  if complete and self.index < self.children:size() then
    complete = false
    self.index = self.index + 1
    self.children:get(self.index):start()
  end

  return complete
end

Animation.Parallel = Animation.Parent:extend()

function Animation.Parallel:new(children)
  Animation.Parent.new(self, children)
  self.children = List(children)
end

function Animation.Parallel:start()
  Animation.start(self)
  
  for child in self.children:values() do
    child:start()
  end
end

function Animation.Parallel:step(dt)
  local complete = true

  for child in self.children:values() do
    complete = child:update(dt) and complete
  end

  return complete
end

Animation.Loop = Animation:extend()

function Animation.Loop:new(child)
  Animation.new(self)

  self.child = child
  self.unsubscribeToChild = self.child.onComplete:subscribe(
    function ()
      self.child:reset()
      self.child:start()
    end
  )
end

function Animation.Loop:start()
  Animation.start(self)

  self.child:start()
end

function Animation.Loop:stop()
  Animation.stop(self)

  self.child:stop()
end

function Animation.Loop:reset()
  Animation.start(self)

  self.child:reset()
end

function Animation.Loop:step(dt)
  self.child:update(dt)
  return false
end

Animation.Wait = Animation:extend()

function Animation.Wait:new(duration)
  Animation.new(self)

  self.duration = duration
  self.cursor = 0
end

function Animation.Wait:step(dt)
  if self.cursor < self.duration then
    self.cursor = self.cursor + dt
  end

  return self.cursor >= self.duration
end

function Animation.Wait:reset()
  Animation.reset(self)

  self.cursor = 0
end

return Animation
local Object = require("classic")
local List = require("list")

local Event = Object:extend()
local stack = List()

function Event:new()
  self.listeners = List()
end

function Event:subscribe(listener)
  local unsubscribe = function()
    self.listeners = self.listeners:filter(
      function (other)
        return not (other == listener)
      end
    ):list()
  end

  self.listeners:add(listener)
  return unsubscribe
end

function Event:listenOnce(listener)
  local context = {}

  context.unsubscribe =
    self:subscribe(
    function(data)
      context.unsubscribe()
      listener(data)
    end
  )

  return context.unsubscribe
end

function Event:trigger(data)
  stack:add({listeners = self.listeners, data = data})
end


local Scheduler = Object:extend()

function Scheduler:update()
  for task in stack:values() do
    for listener in task.listeners:values() do
      listener(task.data)
    end
  end

  stack = List()
end

Event.scheduler = Scheduler()

return Event

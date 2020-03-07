local Object = require("classic")

local Event = Object:extend()

function Event:new()
  self.listeners = {}
end

function Event:subscribe(listener)
  local unsubscribe = function()
    local listeners = {}

    for index, other in pairs(self.listeners) do
      if not listener == other then
        table.insert(listeners, other)
      end
    end

    self.listeners = listeners
  end

  table.insert(self.listeners, listener)
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
  for index, listener in pairs(self.listeners) do
    listener(data)
  end
end

return Event

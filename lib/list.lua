local fun = require("fun")
local Object = require("classic")

local List = Object:extend()

function List.range(start, stop, step)
  return List.Iterator(fun.range(start, stop, step))
end

function List:new(tbl)
  self.tbl = tbl or {}
end

function List:values()
  local index = 0
  local tbl = self.tbl

  return function()
    index = index + 1
    return tbl[index]
  end
end

function List:every(predicate)
  return fun.every(predicate, self.tbl)
end

function List:add(item)
  table.insert(self.tbl, item)
  return self
end

function List:get(index)
  return self.tbl[index]
end

function List:size()
  return table.getn(self.tbl)
end

function List:raw()
  return self.tbl
end

function List:copy()
  return List.Iterator(fun.iter(self.tbl)):list()
end

function List:filter(predicate)
  return List.Iterator(fun.iter(self.tbl)):filter(predicate)
end

List.Iterator = Object:extend()

function List.Iterator:new(generator)
  self.generator = generator
end

function List.Iterator:map(predicate)
  self.generator = fun.map(predicate, self.generator)
  return self
end

function List.Iterator:filter(predicate)
  self.generator = fun.filter(predicate, self.generator)
  return self
end

function List.Iterator:list()
  local tbl = {}
  local insert = function(value)
    table.insert(tbl, value)
  end

  fun.each(insert, self.generator)

  return List(tbl)
end

return List

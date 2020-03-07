--- Loader

local loader = [[
  local inspect = require("inspect")
  local channels = {
    incomming = love.thread.getChannel("bank->loader"),
    outgoing = love.thread.getChannel("loader->bank"),
  }
  
  local jobs = channels.incomming:demand()
  
  for index, job in pairs(jobs) do
    local data, size = love.filesystem.read(job.asset.containerType, job.asset.path)

    channels.outgoing:push({
      options = job.asset.options,
      path = job.path,
      typeName = job.asset.typeName,
      data = data,
      size = size
    })
  end
]]


--- Bank

local inspect = require("inspect")
local json = require("json")
local Object = require("classic")
local List = require("list")
local Bank = Object:extend()

function Bank:new(assetSpec)
  self.jobs = self:parseJobs(assetSpec):raw()
  self.loadedCount = 0
end

function Bank:parseJobs(assetSpec, jobs, path)
  jobs = jobs or List()
  path = path or List()

  for key, spec in pairs(assetSpec) do
    if spec.is and spec:is(Bank.Asset) then
      jobs:add({
        asset = spec,
        path = path:copy():add(key):raw()
      })
    elseif type(spec) == "table" then
      self:parseJobs(spec, jobs, path:copy():add(key))
    end
  end

  return jobs
end

function Bank:isLoaded()
  return self.loadedCount == table.getn(self.jobs)
end

function Bank:load()
  if not self.thread then
    self.channels = {
      incomming = love.thread.getChannel("loader->bank"),
      outgoing = love.thread.getChannel("bank->loader"),
    }
  
    self.channels.outgoing:push(self.jobs)
    self.thread = love.thread.newThread(loader)
    self.thread:start()
  end
end

function Bank:update()
  if self.channels then
    local jobResult = self.channels.incomming:pop()

    if not (jobResult == nil) then
      local asset = Bank.Asset.restore(jobResult)
      local loadedItem = asset:load(jobResult.data)

      self:injectLoadedItem(loadedItem, jobResult.path)
      self.loadedCount = self.loadedCount + 1
    end
  end

  local loaded = self:isLoaded()

  if loaded and self.thread then
    self.thread = nil
    self.channels = nil
  end

  return loaded
end

function Bank:injectLoadedItem(loadedItem, path, index, parent)
  parent = parent or self
  index = index or 1

  if index < table.getn(path) then
    parent[path[index]] = parent[path[index]] or {}
    self:injectLoadedItem(loadedItem, path, index + 1, parent[path[index]])
  else
    parent[path[index]] = loadedItem
  end
end

Bank.Asset = Object:extend()

function Bank.Asset:new(typeName, containerType, path, options)
  self.typeName = typeName
  self.containerType = containerType
  self.path = path
  self.options = options or {}
end

function Bank.Asset.restore(jobResult)
  return Bank.Asset[jobResult.typeName](jobResult.path)
end

Bank.Asset.SpriteSheet = Bank.Asset:extend()

function Bank.Asset.SpriteSheet:new(path)
  Bank.Asset.new(self, "SpriteSheet", "string", path)
end

function Bank.Asset.SpriteSheet:load(data)
  return json.decode(data)
end

Bank.Asset.Image = Bank.Asset:extend()

function Bank.Asset.Image:new(path)
  Bank.Asset.new(self, "Image", "data", path)
end

function Bank.Asset.Image:load(data)
  return love.graphics.newImage(data)
end

Bank.Asset.Sound = Bank.Asset:extend()

function Bank.Asset.Sound:new(path)
  Bank.Asset.new(self, "Sound", "data", path)
end

function Bank.Asset.Sound:load(data)
  return love.audio.newSound(data, self.options.mode or "stream")
end

return Bank
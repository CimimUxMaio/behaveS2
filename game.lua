local utils = require("base.utils.math")

--- @class Game
--- @field private entities {[string]: Entity}
--- @field private events {[string]: function}
local Game = {}
Game.__index = Game

--- @return Game
function Game:new()
	local instance = setmetatable({}, self)
	instance.entities = {}
	return instance
end

--- @param entity Entity
function Game:spawn(entity)
	entity:_checkRequirements()
	self:addEntity(entity)
	entity:handleEvent("spawn")
end

--- @private
--- @param entity Entity
function Game:addEntity(entity)
	local id = utils.uuid()
	entity:_setId(id)
	self.entities[id] = entity

	for _, child in ipairs(entity:getChildren()) do
		self:addEntity(child)
	end
end

--- @param entity Entity | string
function Game:destroy(entity)
	if type(entity) == "string" then
		entity = self.entities[entity]
	end

	entity:handleEvent("destroy")

	local parent = entity:getParent()
	if parent ~= nil then
		parent:removeChild(entity)
	end

	self:removeEntity(entity)
end

--- @private
--- @param entity Entity
function Game:removeEntity(entity)
	self.entities[entity:getId()] = nil
	for _, child in ipairs(entity:getChildren()) do
		self:removeEntity(child)
	end
end

--- @param dt number
function Game:update(dt)
	for _, entity in pairs(self.entities) do
		entity:handleEvent("update", dt)
	end
end

function Game:draw()
	for _, entity in pairs(self.entities) do
		entity:handleEvent("draw")
	end
end

return Game

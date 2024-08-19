local utils = require("base.utils.math")

--- @class Game
--- @field private entities {[string]: Entity}
--- @field private subscriptions {[string]: Behaviour[]}
local Game = {}
Game.__index = Game

--- @return Game
function Game:new()
	local instance = setmetatable({}, self)
	instance.entities = {}
	instance.subscriptions = {}
	return instance
end

--- @param entity Entity
function Game:spawn(entity)
	entity:_checkRequirements()

	local id = utils.uuid()
	entity:_setId(id)
	entity:_setGame(self)

	self.entities[id] = entity
	self:subscribeBehaviours(entity)

	self:raiseEvent(entity, "spawn")

	for _, child in ipairs(entity:getChildren()) do
		self:spawn(child)
	end
end

--- @private
--- @param entity Entity
function Game:subscribeBehaviours(entity)
	for _, behaviour in pairs(entity:getBehaviours()) do
		self:subscribe(entity, behaviour)
	end
end

--- @private
--- @param entity Entity
--- @param behaviour Behaviour
function Game:subscribe(entity, behaviour)
	for key, value in pairs(behaviour:getClass()) do
		if type(value) ~= "function" then
			goto continue
		end

		local event, match = string.gsub(key, "^on(%u%l+)", "%1")
		if match > 0 then
			event = string.gsub(event, "^%u", string.lower)
			self.subscriptions[event] = self.subscriptions[event] or {}
			self.subscriptions[event][entity:getId()] = behaviour
			table.insert(self.subscriptions[event], behaviour)
		end

		::continue::
	end
end

--- @param entity Entity | string
function Game:destroy(entity)
	if type(entity) == "string" then
		entity = self.entities[entity]
	end

	entity:_markDestroyed()
	self:raiseEvent(entity, "destroy")

	self.entities[entity:getId()] = nil

	local parent = entity:getParent()
	if parent ~= nil then
		parent:removeChild(entity)
	end

	for _, child in ipairs(entity:getChildren()) do
		self:destroy(child)
	end
end

--- @param dt number
function Game:update(dt)
	self:raiseEvent(nil, "update", dt)
end

function Game:draw()
	self:raiseEvent(nil, "draw")
end

--- @param event string
--- @param target Entity | Entity[] | nil
--- @param ... any
function Game:raiseEvent(target, event, ...)
	if target ~= nil and #target == 0 then -- Entity
		target = { target }
	end

	local subscribers = self.subscriptions[event] or {}
	for _, behaviour in pairs(subscribers) do
		if target == nil then
			behaviour:handleEvent(event, ...)
		else
			for _, entity in ipairs(target) do
				if behaviour:getEntity() == entity then
					behaviour:handleEvent(event, ...)
					break
				end
			end
		end
	end
end

return Game

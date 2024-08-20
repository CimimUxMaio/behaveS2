local utils = require("base.utils.math")

--- @class Game
--- @field private entities {[string]: Entity}
--- @field private subscriptions {[string]: {[string]: Behaviour[]}}
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

	for _, behaviour in pairs(entity:getBehaviours()) do
		self:_subscribe(behaviour)
	end

	self:raiseEvent(entity, "spawn")

	for _, child in ipairs(entity:getChildren()) do
		self:spawn(child)
	end
end

--- @param entity Entity | string
function Game:destroy(entity)
	if type(entity) == "string" then
		entity = self.entities[entity]
	end

	self:raiseEvent(entity, "destroy")

	self.entities[entity:getId()] = nil

	for _, behaviour in pairs(entity:getBehaviours()) do
		self:_unsubscribe(behaviour)
	end

	local parent = entity:getParent()
	if parent ~= nil then
		parent:removeChild(entity)
	end

	for _, child in ipairs(entity:getChildren()) do
		self:destroy(child)
	end
end

--- @param behaviour Behaviour
function Game:_subscribe(behaviour)
	local events = behaviour:handledEvents()
	local entityId = behaviour:getEntity():getId()

	for _, event in ipairs(events) do
		self.subscriptions[event] = self.subscriptions[event] or {}
		self.subscriptions[event][entityId] = self.subscriptions[event][entityId] or {}
		table.insert(self.subscriptions[event][entityId], behaviour)
	end
end

--- @param behaviour Behaviour
function Game:_unsubscribe(behaviour)
	local events = behaviour:handledEvents()
	local entityId = behaviour:getEntity():getId()

	for _, event in ipairs(events) do
		self.subscriptions[event] = self.subscriptions[event] or {}
		self.subscriptions[event][entityId] = self.subscriptions[event][entityId] or {}
		local eventSubs = self.subscriptions[event][entityId]

		for i, sub in ipairs(eventSubs) do
			if sub == behaviour then
				table.remove(eventSubs, i)
				break
			end
		end
	end
end

--- @param dt number
function Game:update(dt)
	self:raiseEvent(nil, "update", dt)
end

function Game:draw()
	local subscribers = self.subscriptions["draw"] or {}
	local drawables = {}
	for _, behaviours in pairs(subscribers) do
		for _, behaviour in ipairs(behaviours) do
			table.insert(drawables, behaviour)
		end
	end

	table.sort(drawables, function(a, b)
		return a:getDrawOrder() < b:getDrawOrder()
	end)

	for _, behaviour in ipairs(drawables) do
		behaviour:handleEvent("draw")
	end
end

--- @param event string
--- @param target Entity | nil
--- @param ... any
function Game:raiseEvent(target, event, ...)
	local subscribers = self.subscriptions[event] or {}
	if target == nil then
		-- Subscribers from all entities
		for _, behaviours in pairs(subscribers) do
			for _, behaviour in ipairs(behaviours) do
				behaviour:handleEvent(event, ...)
			end
		end
	else
		-- Subscribers from target entity
		local targetSubscribers = subscribers[target:getId()] or {}
		for _, behaviour in ipairs(targetSubscribers) do
			behaviour:handleEvent(event, ...)
		end
	end
end

return Game

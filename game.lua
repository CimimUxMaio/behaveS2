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

	self:targetEvent(entity, "spawn")

	for _, child in ipairs(entity:getChildren()) do
		self:spawn(child)
	end
end

--- @param entity Entity | string
function Game:destroy(entity)
	if type(entity) == "string" then
		entity = self.entities[entity]
	end

	self:targetEvent(entity, "destroy")

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
	self:broadcastEvent("update", dt)
end

function Game:draw()
	self:raiseEvent("draw", function(subscribers)
		local all = {}
		for _, behaviours in pairs(subscribers) do
			for _, behaviour in ipairs(behaviours) do
				table.insert(all, behaviour)
			end
		end

		table.sort(all, function(a, b)
			local orderA, orderB = a:getDrawOrder(), b:getDrawOrder()
			local layerA, layerB = a:getDrawLayer(), b:getDrawLayer()
			return orderA > orderB or (orderA == orderB and layerA > layerB)
		end)

		return all
	end)
end

--- @private
--- @param event string
--- @param filter fun(subscribers:{[string]: Behaviour[]}): Behaviour[]
--- @param ... any
function Game:raiseEvent(event, filter, ...)
	local subscribers = self.subscriptions[event] or {}
	for _, behaviour in ipairs(filter(subscribers)) do
		behaviour:handleEvent(event, ...)
	end
end

--- @param event string
--- @param ... any
function Game:broadcastEvent(event, ...)
	self:raiseEvent(event, function(subscribers)
		local all = {}
		for _, behaviours in pairs(subscribers) do
			for _, behaviour in ipairs(behaviours) do
				table.insert(all, behaviour)
			end
		end

		return all
	end, ...)
end

--- @param entity Entity | string
--- @param event string
--- @param ... any
function Game:targetEvent(entity, event, ...)
	if type(entity) == "table" then
		entity = entity:getId()
	end

	self:raiseEvent(event, function(subscribers)
		return subscribers[entity] or {}
	end, ...)
end

return Game

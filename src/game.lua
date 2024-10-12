local class = require("oopsie").class
local utils = require("behaves2.utils.math")

--- @class Game : Base
--- @field private entities {[string]: Entity}
--- @field private subscriptions {[string]: {[string]: Behaviour[]}}
--- @field private destroyed {[string]: boolean}
local Game = class("Game")

function Game:initialize()
	self.entities = {}
	self.subscriptions = {}
	self.destroyed = {}
end

--- @param entity Entity
function Game:spawn(entity)
	local id = utils.uuid()
	entity:_setId(id)
	entity:_setGame(self)

	self.entities[id] = entity

	for _, behaviour in pairs(entity:getBehaviours()) do
		self:_subscribe(behaviour)
	end

	entity:raiseEvent("spawn")
end

--- @param entity Entity | string
function Game:destroy(entity)
	if type(entity) == "string" then
		entity = self.entities[entity]
	end

	entity:raiseEvent("destroy")

	self.entities[entity:getId()] = nil
	entity:_setDestroyed()

	for _, behaviour in pairs(entity:getBehaviours()) do
		self:_unsubscribe(behaviour)
	end
end

--- @param behaviour Behaviour
function Game:_subscribe(behaviour)
	behaviour:_checkRequirements()

	local events = behaviour:handledEvents()
	local entityId = behaviour:getEntity():getId()

	for _, event in ipairs(events) do
		self.subscriptions[event] = self.subscriptions[event] or {}
		self.subscriptions[event][entityId] = self.subscriptions[event][entityId] or {}
		table.insert(self.subscriptions[event][entityId], behaviour)
	end

	behaviour:handleEvent("ready")
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

	behaviour:handleEvent("remove")
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
			local entityA, entityB = a:getEntity(), b:getEntity()
			local priorityA = { entityA:getDrawOrder(), entityA:getDrawLayer(), a:getDrawOrder(), b:getDrawLayer() }
			local priorityB = { entityB:getDrawOrder(), entityB:getDrawLayer(), b:getDrawOrder(), b:getDrawLayer() }

			for i = 1, 4 do
				if priorityA[i] > priorityB[i] then
					return true
				elseif priorityA[i] < priorityB[i] then
					return false
				end
			end

			return false
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
		if not behaviour:getEntity():isDestroyed() then
			behaviour:handleEvent(event, ...)
		end
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

function Game:clear()
	for _, entity in pairs(self.entities) do
		self:destroy(entity)
	end
end

return Game

local class = require("oopsie").class
local utils = require("behaves2.utils.math")
local Logger = require("behaves2.utils.logging")

local logger = Logger:new("Game")

---@class DeferredTask
---@field task function
---@field args any[]

--- @class Game : Base
--- @field private entities {[string]: Entity}
--- @field private subscriptions {[string]: {[string]: Behaviour[]}}
--- @field private destroyed {[string]: boolean}
--- @field private deferredTasks DeferredTask[]
local Game = class("Game")

function Game:initialize()
	self.entities = {}
	self.subscriptions = {}
	self.destroyed = {}
	self.deferredTasks = {}
end

--- @param entity Entity
function Game:spawn(entity)
	if entity:isSpawned() then
		error(string.format("%s %s was already spawned", entity.className, entity:getId()))
	end

	local id = utils.uuid()
	entity:_setId(id)
	entity:_setGame(self)

	self.entities[id] = entity

	logger:debug(string.format("Spawning %s: %s", entity.className, entity:getId()))

	logger:debug(
		string.format("Spawning %d children for %s: %s", #entity:getChildren(), entity.className, entity:getId())
	)
	for _, child in ipairs(entity:getChildren()) do
		self:spawn(child)
	end
	logger:debug(string.format("Finished spawning children for %s: %s", entity.className, entity:getId()))

	logger:debug(
		string.format("Subscribing %d behaviours for %s: %s", #entity:getBehaviours(), entity.className, entity:getId())
	)
	for _, behaviour in pairs(entity:getBehaviours()) do
		self:_subscribe(behaviour)
	end

	entity:raiseEvent("spawn")
	logger:debug(string.format("Finished spawning %s: %s", entity.className, entity:getId()))
end

--- @param entity Entity | string
function Game:destroy(entity)
	if type(entity) == "string" then
		local id = entity
		entity = self.entities[id]
		assert(entity ~= nil, string.format("Attempted to destroy non-existent Entity with ID %s", id))
	end

	assert(entity:isSpawned(), string.format("Attempted to destroy %s, but it was not spawned", entity.className))

	logger:debug(string.format("Destroying %s: %s", entity.className, entity:getId() or "nil"))

	entity:raiseEvent("destroy")

	if entity:getId() ~= nil then
		self.entities[entity:getId()] = nil
	end

	entity:_setDestroyed()

	logger:debug(
		string.format(
			"Unsubscribing %d behaviours from %s: %s",
			#entity:getBehaviours(),
			entity.className,
			entity:getId() or "nil"
		)
	)
	for _, behaviour in pairs(entity:getBehaviours()) do
		self:_unsubscribe(behaviour)
	end

	local parent = entity:getParent()
	if parent ~= nil then
		parent:removeChild(entity)
		logger:debug(string.format("Detached %s: %s from parent", entity.className, entity:getId() or "nil"))
	end

	logger:debug(
		string.format(
			"Destroying %d children for %s: %s",
			#entity:getChildren(),
			entity.className,
			entity:getId() or "nil"
		)
	)
	local children = { unpack(entity:getChildren()) }
	for _, child in ipairs(children) do
		self:destroy(child)
	end
	logger:debug(string.format("Finished destroying children for %s: %s", entity.className, entity:getId() or "nil"))

	logger:debug(string.format("Finished destroying %s: %s", entity.className, entity:getId() or "nil"))
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

		logger:debug(
			string.format(
				"Subscribed - Event: %s - Behaviour: %s - %s: %s",
				event,
				behaviour.className,
				behaviour:getEntity().className,
				behaviour:getEntity():getId()
			)
		)
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

	logger:debug(
		string.format(
			"Unsubscribed - Behaviour: %s - %s: %s",
			behaviour.className,
			behaviour:getEntity().className,
			behaviour:getEntity():getId()
		)
	)
end

--- @param dt number
function Game:update(dt)
	--- Execute queued deferred tasks before next update
	self:executeDeferredTasks()

	for _, behaviour in ipairs(self:getActiveSubscribers("update")) do
		-- Only update entities that are updateable
		if behaviour:getEntity():isUpdateable() then
			behaviour:handleEvent("update", dt)
		end
	end

	local entityCount = 0
	for _ in pairs(self.entities) do
		entityCount = entityCount + 1
	end

	local subscriptionCount = 0
	for _ in pairs(self.subscriptions) do
		subscriptionCount = subscriptionCount + 1
	end

	logger:debug(string.format("Game updated - Entities: %d - Subscriptions: %d", entityCount, subscriptionCount))
end

function Game:draw()
	local target = self:getActiveSubscribers("draw")
	self.sortByDrawPriority(target)

	for _, behaviour in ipairs(target) do
		--- Only draw entities that are drawable
		if behaviour:getEntity():isDrawable() then
			behaviour:handleEvent("draw")
		end
	end
end

---@private
---@param behaviours Behaviour[]
function Game.sortByDrawPriority(behaviours)
	table.sort(behaviours, function(a, b)
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
end

--- @param event string
--- @param ... any
function Game:broadcastEvent(event, ...)
	logger:debug(string.format("Event broadcast - Event: %s", event))

	for _, behaviour in ipairs(self:getActiveSubscribers(event)) do
		behaviour:handleEvent(event, ...)
	end
end

--- @private
--- @param event string
--- @return Behaviour[]
function Game:getActiveSubscribers(event)
	local subscribers = {}
	for _, behaviours in pairs(self.subscriptions[event] or {}) do
		for _, behaviour in ipairs(behaviours) do
			if not behaviour:getEntity():isDestroyed() then
				table.insert(subscribers, behaviour)
			end
		end
	end

	return subscribers
end

---@param task fun()
---@param ... any
function Game:defer(task, ...)
	table.insert(self.deferredTasks, {
		task = task,
		args = { ... },
	})
end

---@private
function Game:executeDeferredTasks()
	while #self.deferredTasks ~= 0 do
		local task = table.remove(self.deferredTasks)
		task.task(unpack(task.args))
	end
end

return Game

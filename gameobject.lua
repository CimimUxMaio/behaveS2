local GameObject = {}

function GameObject:new(...)
	local o = {}
	setmetatable(o, self)
	self.__index = self

	o._deferred = {} -- Deferred tasks

	o._drawOrder = math.huge

	o:initialize(...)
	return o
end

function GameObject:initialize(...) end

function GameObject:onSpawn() end

function GameObject:update(dt) end

function GameObject:draw() end

function GameObject:destroy() end

function GameObject:onCollisionEnter(fixture, other, contact) end

function GameObject:onCollisionExit(fixture, other, contact) end

function GameObject:setDrawOrder(order)
	self._drawOrder = order
end

function GameObject:getDrawOrder()
	return self._drawOrder
end

function GameObject:setState(newState)
	if self._state then
		self._state:onExit()
	end

	self._state = newState
	self._state:onEnter()
end

function GameObject:getState()
	return self._state
end

function GameObject:_defer(task)
	table.insert(self._deferred, task)
end

function GameObject:_update(dt)
	for _ = 1, #self._deferred do
		local task = table.remove(self._deferred)
		task.run(unpack(task.args))
	end

	if self:getState() then
		self:getState():update(dt)
	end

	self:update(dt)
end

function GameObject:_draw()
	if self:getState() then
		self:getState():draw()
	end

	self:draw()
end

function GameObject:_destroy()
	if self:getState() then
		self:getState():onExit()
	end

	self:destroy()
end

function GameObject:_onCollisionEnter(fixture, other, contact)
	self:_defer({
		run = self.onCollisionEnter,
		args = { self, fixture, other, contact },
	})

	local state = self:getState()
	if state then
		self:_defer({
			run = state.onCollisionEnter,
			args = { state, fixture, other, contact },
		})
	end
end

function GameObject:_onCollisionExit(fixture, other, contact)
	self:_defer({
		run = self.onCollisionExit,
		args = { self, fixture, other, contact },
	})

	local state = self:getState()
	if state then
		self:_defer({
			run = state.onCollisionExit,
			args = { state, fixture, other, contact },
		})
	end
end

return GameObject

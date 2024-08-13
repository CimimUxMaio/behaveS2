local function onCollisionEnter(fixA, fixB, contact)
	local dataA = fixA:getUserData()
	local dataB = fixB:getUserData()

	if dataA and dataA.object then
		dataA.object:_onCollisionEnter(fixA, fixB, contact)
	end

	if dataB and dataB.object then
		dataB.object:_onCollisionEnter(fixB, fixA, contact)
	end
end

local function onCollisionExit(fixA, fixB, contact)
	local dataA = fixA:getUserData()
	local dataB = fixB:getUserData()

	if dataA and dataA.object then
		dataA.object:_onCollisionExit(fixA, fixB, contact)
	end

	if dataB and dataB.object then
		dataA.object:_onCollisionExit(fixB, fixA, contact)
	end
end

local World = {}

function World:new(physics)
	local o = { physics = physics, objects = {} }

	if physics then
		physics:setCallbacks(onCollisionEnter, onCollisionExit)
	end

	setmetatable(o, self)
	self.__index = self
	return o
end

function World:getPhysics()
	return self.physics
end

function World:spawnObject(object, ...)
	self.objects[object] = object
	object:onSpawn(...)
end

function World:despawnObject(object)
	self.objects[object]:_destroy()
	self.objects[object] = nil
end

function World:update(dt)
	if self.physics then
		self.physics:update(dt)
	end

	for _, obj in pairs(self.objects) do
		obj:_update(dt)
	end
end

function World:draw()
	local ordered = {}
	for _, obj in pairs(self.objects) do
		table.insert(ordered, obj)
	end

	table.sort(ordered, function(a, b)
		return a:getDrawOrder() < b:getDrawOrder()
	end)

	for _, obj in ipairs(ordered) do
		obj:_draw()
	end
end

return World

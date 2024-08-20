local Behaviour = require("base.behaviour")

--- @class PhysicsBody : Behaviour
--- @field protected shape love.Shape
--- @field protected fixture love.Fixture
local PhysicsBody = setmetatable({}, Behaviour)
PhysicsBody.__index = PhysicsBody
PhysicsBody.className = "PhysicsBody"

--- @param fixture love.Fixture
--- @return PhysicsBody
function PhysicsBody:new(fixture)
	--- @type PhysicsBody
	local instance = Behaviour.new(self)
	local userData = fixture:getUserData() or {}
	userData._physicsBody = instance
	fixture:setUserData(userData)
	instance.fixture = fixture
	return instance
end

function PhysicsBody:onDestroy()
	self.fixture:getBody():destroy()
end

--- @return love.Fixture
function PhysicsBody:getFixture()
	return self.fixture
end

function PhysicsBody:getBody()
	return self.fixture:getBody()
end

function PhysicsBody:getShape()
	return self.fixture:getShape()
end

function PhysicsBody:getPosition()
	return self:getBody():getPosition()
end

--- @param fixture love.Fixture
--- @param other love.Fixture
--- @param contact love.Contact
function PhysicsBody:collisionEnter(fixture, other, contact)
	self.entity:raiseEvent("collisionEnter", fixture, other, contact)
end

--- @param fixture love.Fixture
--- @param other love.Fixture
--- @param contact love.Contact
function PhysicsBody:collisionExit(fixture, other, contact)
	self.entity:raiseEvent("collisionExit", fixture, other, contact)
end

--- @param world love.World
function PhysicsBody.setCallbacks(world)
	local onCollisionEnter = function(fixA, fixB, contact)
		local dataA = fixA:getUserData()
		local dataB = fixB:getUserData()

		if dataA and dataA._physicsBody then
			dataA._physicsBody:collisionEnter(fixA, fixB, contact)
		end

		if dataB and dataB._physicsBody then
			dataB._physicsBody:collisionExit(fixB, fixA, contact)
		end
	end

	local onCollisionExit = function(fixA, fixB, contact)
		local dataA = fixA:getUserData()
		local dataB = fixB:getUserData()

		if dataA and dataA._physicsBody then
			dataA._physicsBody:collisionExit(fixA, fixB, contact)
		end

		if dataB and dataB._physicsBody then
			dataA._physicsBody:collisionExit(fixB, fixA, contact)
		end
	end

	world:setCallbacks(onCollisionEnter, onCollisionExit)
end

return PhysicsBody

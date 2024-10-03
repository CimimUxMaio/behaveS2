local Behaviour = require("behaves2.behaviour")

--- @class PhysicsBody : Behaviour
--- @field protected fixture love.Fixture
local PhysicsBody = setmetatable({}, Behaviour)
PhysicsBody.__index = PhysicsBody
PhysicsBody.className = "PhysicsBody"

--- @param fixture love.Fixture
--- @return PhysicsBody
function PhysicsBody:new(fixture)
	local instance = Behaviour.new(self)
	instance.fixture = fixture
	return instance
end

function PhysicsBody:onDestroy()
	self:getBody():destroy()
end

---@return love.Fixture
function PhysicsBody:getFixture()
	return self.fixture
end

---@return love.Body
function PhysicsBody:getBody()
	return self:getFixture():getBody()
end

---@return love.Shape
function PhysicsBody:getShape()
	return self:getFixture():getShape()
end

function PhysicsBody:getPosition()
	return self:getBody():getPosition()
end

return PhysicsBody

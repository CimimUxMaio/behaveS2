local extends = require("oopsie").extends
local Behaviour = require("behaves2.behaviour")

--- @class PhysicsBody : Behaviour
--- @field protected fixture love.Fixture
local PhysicsBody = extends("PhysicsBody", Behaviour)

--- @param fixture love.Fixture
function PhysicsBody:initialize(fixture)
	self.fixture = fixture
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

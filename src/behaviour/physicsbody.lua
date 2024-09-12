local Behaviour = require("behaves2.behaviour")

--- @class PhysicsBody : Behaviour
--- @field protected body love.Body
local PhysicsBody = setmetatable({}, Behaviour)
PhysicsBody.__index = PhysicsBody
PhysicsBody.className = "PhysicsBody"

--- @param body love.Body
--- @return PhysicsBody
function PhysicsBody:new(body)
	local instance = Behaviour.new(self)
	instance.body = body
	return instance
end

function PhysicsBody:onDestroy()
	self.body:destroy()
end

function PhysicsBody:getBody()
	return self.body
end

function PhysicsBody:getPosition()
	return self:getBody():getPosition()
end

function PhysicsBody:setPosition(x, y)
	self.body:setPosition(x, y)
end

return PhysicsBody

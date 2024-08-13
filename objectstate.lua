local ObjectState = {}

function ObjectState:new(object, ...)
	local state = {}
	setmetatable(state, self)
	self.__index = self
	self:initialize(object, ...)
	return state
end

function ObjectState:initialize(...) end

function ObjectState:onEnter() end
function ObjectState:onExit() end

function ObjectState:update(dt) end
function ObjectState:draw() end

function ObjectState:onCollisionEnter(fixture, other, contact) end
function ObjectState:onCollisionExit(fixture, other, contact) end

return ObjectState

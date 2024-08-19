--- @class Camera
--- @field [any] any
local Camera = {}
Camera.__index = Camera

function Camera:new()
	local instance = setmetatable({}, self)
	instance.transform = love.math.newTransform()
	return instance
end

function Camera:screenToWorld(x, y)
	return self.transform:inverseTransformPoint(x, y)
end

function Camera:update(posX, posY)
	self:setCenter(posX, posY)
end

function Camera:setCenter(posX, posY)
	local width, height = love.graphics.getDimensions()
	self.transform:reset()
	self.transform:translate(width / 2 - posX, height / 2 - posY)
end

function Camera:attach()
	love.graphics.push()
	love.graphics.applyTransform(self.transform)
end

function Camera:detach()
	love.graphics.pop()
end

return Camera

local Camera = {}

function Camera:new(target)
	if not target.getPosition then
		error("Invalid camera target. Target must have a getPosition() method.")
	end

	local camera = {}
	setmetatable(camera, self)
	self.__index = self

	camera.target = target
	self.transform = love.math.newTransform()

	return camera
end

function Camera:screenToWorld(x, y)
	return self.transform:inverseTransformPoint(x, y)
end

function Camera:update(dt)
	local posX, posY = self.target:getPosition()
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

--- @class Entity
--- @field protected model table
--- @field private id string
--- @field private game Game
--- @field private behaviours Behaviour[]
--- @field private destroyed boolean
--- @field private drawLayer number
--- @field private drawOrder number
local Entity = {}
Entity.__index = Entity

--- @param model table?
--- @return Entity
function Entity:new(model)
	local instance = setmetatable({}, self)
	instance.behaviours = {}
	instance.destroyed = false
	instance.drawOrder = math.huge
	instance.drawLayer = math.huge
	instance.model = model or {}
	return instance
end

--- @param id string
function Entity:_setId(id)
	self.id = id
end

--- @parm game Game
function Entity:_setGame(game)
	self.game = game
end

function Entity:_setDestroyed()
	self.destroyed = true
end

--- @return boolean
function Entity:isDestroyed()
	return self.destroyed
end

--- @return string
function Entity:getId()
	return self.id
end

--- @param behaviour Behaviour
--- @return Entity
function Entity:addBehaviour(behaviour)
	self.behaviours[behaviour:getClass()] = behaviour
	behaviour:_setEntity(self)

	if self:isSpawned() then
		self.game:_subscribe(behaviour)
	end

	return self
end

--- @param class Behaviour
function Entity:removeBehaviour(class)
	local behaviour = self.behaviours[class]
	self.behaviours[class] = nil

	if self:isSpawned() and behaviour ~= nil then
		self.game:_unsubscribe(behaviour)
	end
end

--- @generic T : Behaviour
--- @param class T
--- @return T
function Entity:getBehaviour(class)
	return self.behaviours[class]
end

--- @generic T : Behaviour
--- @param class T
--- @return boolean
function Entity:hasBehaviour(class)
	return self:getBehaviour(class) ~= nil
end

--- @return Behaviour[]
function Entity:getBehaviours()
	return self.behaviours
end

--- @param event string
--- @param ... any
function Entity:raiseEvent(event, ...)
	for _, behaviour in pairs(self.behaviours) do
		behaviour:handleEvent(event, ...)
	end
end

--- @return boolean
function Entity:isSpawned()
	return self.game ~= nil and not self:isDestroyed()
end

--- @return number
function Entity:getDrawLayer()
	return self.drawLayer
end

--- @return number
function Entity:getDrawOrder()
	return self.drawOrder
end
---
--- @param drawLayer number
function Entity:setDrawLayer(drawLayer)
	self.drawLayer = drawLayer
end

--- @param drawOrder number
function Entity:setDrawOrder(drawOrder)
	self.drawOrder = drawOrder
end

--- @retrun table
function Entity:getModel()
	return self.model
end

return Entity

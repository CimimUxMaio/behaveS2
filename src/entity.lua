local class = require("oopsie").class

--- @class Entity : Base
--- @field protected model table
--- @field private id string
--- @field private game Game
--- @field private behaviours Behaviour[]
--- @field private destroyed boolean
--- @field private drawLayer number
--- @field private drawOrder number
local Entity = class("Entity")

--- @param model table?
function Entity:initialize(model)
	self.behaviours = {}
	self.destroyed = false
	self.drawOrder = math.huge
	self.drawLayer = math.huge
	self.model = model or {}
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

--- @param cls Behaviour
function Entity:removeBehaviour(cls)
	local behaviour = self.behaviours[cls]
	self.behaviours[cls] = nil

	if self:isSpawned() and behaviour ~= nil then
		self.game:_unsubscribe(behaviour)
	end
end

--- @generic T : Behaviour
--- @param cls T
--- @return T
function Entity:getBehaviour(cls)
	return self.behaviours[cls]
end

--- @generic T : Behaviour
--- @param cls T
--- @return boolean
function Entity:hasBehaviour(cls)
	return self:getBehaviour(cls) ~= nil
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

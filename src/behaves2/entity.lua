local class = require("oopsie").class

--- @class Entity : Base
--- @field protected model table
--- @field protected parent? Entity
--- @field protected paused boolean
--- @field private id string
--- @field private game Game
--- @field private children Entity[]
--- @field private behaviours {[string]: Behaviour}
--- @field private destroyed boolean
--- @field private drawLayer number
--- @field private drawOrder number
--- @field private pauseMode PauseMode
local Entity = class("Entity")

--- @param model table?
function Entity:initialize(model)
	self.children = {}
	self.behaviours = {}
	self.destroyed = false
	self.paused = false
	self.drawOrder = math.huge
	self.drawLayer = math.huge
	self.model = model or {}
	self.pauseMode = "do-nothing"
end

--- @param id string
function Entity:_setId(id)
	self.id = id
end

--- @return string
function Entity:getId()
	return self.id
end

--- @parm game Game
function Entity:_setGame(game)
	self.game = game
end

--- @return Game
function Entity:getGame()
	return self.game
end

--- @param parent Entity?
function Entity:_setParent(parent)
	self.parent = parent
end

--- @return Entity?
function Entity:getParent()
	return self.parent
end

function Entity:_setDestroyed()
	self.destroyed = true
end

--- @return boolean
function Entity:isDestroyed()
	return self.destroyed
end

--- @param mode PauseMode
function Entity:setPauseMode(mode)
	if mode ~= "do-nothing" and mode ~= "draw-only" and mode ~= "do-all" then
		error(string.format("Invalid pause mode: %s", mode))
	end
	self.pauseMode = mode
end

--- @return PauseMode
function Entity:getPauseMode()
	return self.pauseMode
end

--- @return boolean
function Entity:isUpdateable()
	if self:isDestroyed() then
		return false
	end

	if not self:isPaused() then
		return true
	end

	return self.pauseMode == "do-all"
end

--- @return boolean
function Entity:isDrawable()
	if self:isDestroyed() then
		return false
	end

	if not self:isPaused() then
		return true
	end

	return self.pauseMode == "do-all" or self.pauseMode == "draw-only"
end

--- @param paused boolean
function Entity:setPaused(paused)
	self.paused = paused

	for _, child in ipairs(self.children) do
		child:setPaused(paused)
	end
end

--- @return boolean
function Entity:isPaused()
	return self.paused
end

--- @param behaviour Behaviour
--- @return Entity
function Entity:addBehaviour(behaviour)
	local cls = behaviour.className
	if self:hasBehaviour(cls) then
		error(string.format("Entity already contains a behaviour of type %s", behaviour.className))
	end

	self.behaviours[cls] = behaviour
	behaviour:_setEntity(self)

	if self:isSpawned() then
		self.game:_subscribe(behaviour)
	end

	return self
end

--- @param cls string
function Entity:removeBehaviour(cls)
	local behaviour = self.behaviours[cls]
	self.behaviours[cls] = nil

	if self:isSpawned() and behaviour ~= nil then
		self.game:_unsubscribe(behaviour)
	end
end

--- @generic T : Behaviour
--- @param cls string
--- @return T
function Entity:getBehaviour(cls)
	return self.behaviours[cls]
end

--- @param child Entity
function Entity:addChild(child)
	table.insert(self.children, child)
	child:_setParent(self)

	if self:isSpawned() and not child:isSpawned() then
		self.game:spawn(child)
	end

	child:setPaused(self:isPaused())

	return self
end

--- @param child Entity
function Entity:removeChild(child)
	for i, c in ipairs(self.children) do
		if c == child then
			table.remove(self.children, i)
			child:_setParent(nil)
			break
		end
	end
end

--- @return Entity[]
function Entity:getChildren()
	return self.children
end

--- @param cls string
--- @return boolean
function Entity:hasBehaviour(cls)
	return self:getBehaviour(cls) ~= nil
end

--- @return Behaviour[]
function Entity:getBehaviours()
	local list = {}
	for _, behaviour in pairs(self.behaviours) do
		table.insert(list, behaviour)
	end

	return list
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

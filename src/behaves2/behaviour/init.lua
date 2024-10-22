local class = require("oopsie").class

--- @class Behaviour : Base
--- @field protected entity Entity
--- @field private requirements string[]
--- @field private drawOrder number
--- @field private drawLayer number
local Behaviour = class("Behaviour")

--- @param requirements string[]? Defaults to {}
function Behaviour:initialize(requirements)
	if requirements == nil then
		requirements = {}
	end

	self.requirements = requirements
	self.drawLayer = math.huge
	self.drawOrder = math.huge
end

--- @return string[]
function Behaviour:getRequirements()
	return self.requirements
end

function Behaviour:_checkRequirements()
	for _, requirement in ipairs(self:getRequirements()) do
		if not self.entity:hasBehaviour(requirement) then
			error(
				string.format(
					"Entity is missing a behaviour of class: %s, required by the behaviour: %s",
					requirement,
					self.className
				)
			)
		end
	end
end

--- @return number
function Behaviour:getDrawOrder()
	return self.drawOrder
end

--- @param drawOrder number
function Behaviour:setDrawOrder(drawOrder)
	self.drawOrder = drawOrder
end

--- @param drawLayer number
function Behaviour:setDrawLayer(drawLayer)
	self.drawLayer = drawLayer
end

--- @return number
function Behaviour:getDrawLayer()
	return self.drawLayer
end

--- @return Entity
function Behaviour:getEntity()
	return self.entity
end

--- @param entity Entity
function Behaviour:_setEntity(entity)
	self.entity = entity
end

--- @return table
function Behaviour:getModel()
	return self:getEntity():getModel()
end

--- @param event string
--- @param ... any
function Behaviour:handleEvent(event, ...)
	local handler = self["on" .. string.gsub(event, "^%l", string.upper)]

	if handler ~= nil then
		handler(self, ...)
	end
end

--- @return string[]
function Behaviour:handledEvents()
	local events = {}

	local function traverseClass(cls)
		for key, value in pairs(cls) do
			local event, match = string.gsub(key, "^on(%u%l+)", "%1")
			if match > 0 and type(value) == "function" then
				event = string.gsub(event, "^%u", string.lower)
				table.insert(events, event)
			end
		end

		if cls:getClass() ~= nil then
			traverseClass(cls:getClass())
		end
	end

	traverseClass(self)

	return events
end

return Behaviour

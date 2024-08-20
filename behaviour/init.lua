--- @class Behaviour
--- @field protected requirements Behaviour[]
--- @field protected entity Entity
--- @field private drawOrder number
--- @field private drawLayer number
local Behaviour = {}
Behaviour.__index = Behaviour
Behaviour.className = "<Unnamed Behaviour>"

--- @generic T : Behaviour
--- @param requirements Behaviour[] | nil
--- @return T
function Behaviour:new(requirements)
	local instance = setmetatable({}, self)
	instance.requirements = requirements or {}
	instance.drawOrder = math.huge
	instance.drawLayer = math.huge
	return instance
end

--- @return Behaviour
function Behaviour:getClass()
	return self.__index
end

--- @return Behaviour[]
function Behaviour:getRequirements()
	return self.requirements
end

--- @return number
function Behaviour:getDrawOrder()
	return self.drawOrder
end

--- @param drawLayer number
function Behaviour:setDrawLayer(drawLayer)
	self.drawLayer = drawLayer
end
---
--- @return number
function Behaviour:getDrawLayer()
	return self.drawLayer
end

--- @param drawOrder number
function Behaviour:setDrawOrder(drawOrder)
	self.drawOrder = drawOrder
end

--- @return Entity
function Behaviour:getEntity()
	return self.entity
end

--- @param entity Entity
function Behaviour:_setEntity(entity)
	self.entity = entity
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

	for key, value in pairs(self:getClass()) do
		local event, match = string.gsub(key, "^on(%u%l+)", "%1")
		if match > 0 and type(value) == "function" then
			event = string.gsub(event, "^%u", string.lower)
			table.insert(events, event)
		end
	end

	return events
end

return Behaviour

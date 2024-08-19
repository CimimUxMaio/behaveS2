--- @class Behaviour
--- @field protected requirements Behaviour[]
--- @field protected entity Entity
local Behaviour = {}
Behaviour.__index = Behaviour
Behaviour.className = "<Unnamed Behaviour>"

--- @generic T : Behaviour
--- @param requirements Behaviour[] | nil
--- @return T
function Behaviour:new(requirements)
	local instance = setmetatable({}, self)
	instance.requirements = requirements or {}
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

return Behaviour

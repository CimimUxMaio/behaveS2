local class = require("oopsie").class

--- @alias PauseMode
--- | "do-nothing"
--- | "draw-only"
--- | "do-all"

--- @class Behaviour : Base
--- @field protected entity Entity
--- @field private requirements string[]
--- @field private drawLayer number
--- @field private pauseMode PauseMode
local Behaviour = class("Behaviour")

--- @param requirements string[]? Defaults to {}
function Behaviour:initialize(requirements)
	if requirements == nil then
		requirements = {}
	end

	self.requirements = requirements
	self.drawLayer = math.huge
	self.pauseMode = "do-nothing"
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

--- @param mode PauseMode
function Behaviour:setPauseMode(mode)
	if mode ~= "do-nothing" and mode ~= "draw-only" and mode ~= "do-all" then
		error(string.format("Invalid pause mode: %s", mode))
	end
	self.pauseMode = mode
end

--- @return PauseMode
function Behaviour:getPauseMode()
	return self.pauseMode
end

--- @return boolean
function Behaviour:isUpdateable()
	if not self.entity:isPaused() then
		return true
	end

	return self.pauseMode == "do-all"
end

--- @return boolean
function Behaviour:isDrawable()
	if not self.entity:isPaused() then
		return true
	end

	return self.pauseMode == "do-all" or self.pauseMode == "draw-only"
end

return Behaviour

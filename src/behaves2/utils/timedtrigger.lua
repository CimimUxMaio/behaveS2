local class = require("oopsie").class

---@class TimedTrigger : Base
---@field private delay number
---@field private ready boolean
---@field private timer number
local TimedTrigger = class("TimedTrigger")

---@param delay number
---@param ready boolean Initial value
function TimedTrigger:initialize(delay, ready)
	self.delay = delay
	self.ready = ready
	self.timer = 0
end

---@param dt number
function TimedTrigger:update(dt)
	self.timer = self.timer + dt
	if self.timer >= self.delay then
		self.ready = true
	end
end

---@return boolean
function TimedTrigger:isReady()
	return self.ready
end

function TimedTrigger:reset()
	self.ready = false
	self.timer = 0
end

return TimedTrigger

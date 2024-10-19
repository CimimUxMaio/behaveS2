local extends = require("oopsie").extends
local Logger = require("behaves2.utils.logger")

local Behaves2Logger = extends("Behaves2Logger", Logger)

local logLevel = Logger.LogLevel.DISABLED

for n, v in ipairs(arg) do
	if v == "--debug" then
		logLevel = Logger.LogLevel.DEBUG
	elseif v == "--log-level" then
		local str = arg[n + 1]
		local level = Logger.LogLevel[string.upper(str)]
		if level ~= nil then
			logLevel = level
		end
	end
end

Logger.setLogLevel(logLevel)

---@param name string
---@param file file*
function Behaves2Logger:initialize(name, file)
	Logger.initialize(self)
	self:setName("BehaveS2")
	self:setOutputFile(file)
	self:setFormat("%DateTime [%Name][" .. name .. "][%LogLevel]: %Message\n")
end

return Behaves2Logger

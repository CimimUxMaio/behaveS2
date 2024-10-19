local extends = require("oopsie").extends
local Logger = require("behaves2.utils.logger")

local Behaves2Logger = extends("Behaves2Logger", Logger)

---@param name string
---@param file file*
function Behaves2Logger:initialize(name, file)
	Logger.initialize(self)
	self:setName("BehaveS2")

	local logLevel = Logger.LogLevel.DISABLED

	for _, v in ipairs(arg) do
		if v == "--debug" then
			logLevel = Logger.LogLevel.DEBUG
		end
	end

	self:setLogLevel(logLevel)
	self:setOutputFile(file)
	self:setFormat("%DateTime [%Name][" .. name .. "][%LogLevel]: %Message\n")
end

return Behaves2Logger

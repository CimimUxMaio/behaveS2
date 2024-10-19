local class = require("oopsie").class

---@class Logger : Base
---@field private name string
---@field private format string
---@field private outputFile file*
---@field private logLevel LogLevel
local Logger = class("Logger")

local function readOnlyTable(table)
	return setmetatable({}, {
		__index = table,
		__newindex = function(t)
			error("Attempt to modify read-only table", t)
		end,
		__metatable = false,
	})
end

---@enum LogLevel
Logger.LogLevel = readOnlyTable({
	INFO = 0,
	DEBUG = 1,
	WARN = 2,
	ERROR = 3,
	FATAL = 4,
	DISABLED = 99,
})

local LogLevel = Logger.LogLevel

local LogLevelStr = {
	[LogLevel.INFO] = "INFO",
	[LogLevel.DEBUG] = "DEBUG",
	[LogLevel.WARN] = "WARN",
	[LogLevel.ERROR] = "ERROR",
	[LogLevel.FATAL] = "FATAL",
	[LogLevel.DISABLED] = "DISABLED",
}

Logger.logLevel = LogLevel.DISABLED -- Default log level

---@param logLevel LogLevel
function Logger.setLogLevel(logLevel)
	Logger.logLevel = logLevel
end

---@return LogLevel
function Logger.getLogLevel()
	return Logger.logLevel
end

--- @param name string?
--- @param format string?
--- @param file file*? Defaults to io.stdout
function Logger:initialize(name, format, file)
	self.name = name or ""
	self.format = format or self:getDefaultFormat()
	self.outputFile = file or io.stdout
end

---@return string
function Logger:getDefaultFormat()
	return "%DateTime [%LogLevel]: %Message\n"
end

---@return string
function Logger:getName()
	return self.name
end

---@return file*
function Logger:getOutputFile()
	return self.outputFile
end

---@return string
function Logger:getFormat()
	return self.format
end

---@param name string
function Logger:setName(name)
	self.name = name
end

---@param format string
function Logger:setFormat(format)
	self.format = format
end

---@param file file*
function Logger:setOutputFile(file)
	self.outputFile = file
end

---@param level LogLevel
---@param message string
function Logger:log(level, message)
	if level < self:getLogLevel() then
		return
	end

	local formattedMessage = self:formatMessage(level, message)

	local previousFile = io.output()
	io.output(self:getOutputFile())
	io.write(formattedMessage)
	io.output(previousFile)
end

---@param message string
function Logger:info(message)
	self:log(LogLevel.INFO, message)
end

---@param message string
function Logger:debug(message)
	self:log(LogLevel.DEBUG, message)
end

---@param message string
function Logger:warn(message)
	self:log(LogLevel.WARN, message)
end

---@param message string
function Logger:error(message)
	self:log(LogLevel.ERROR, message)
end

---@param message string
function Logger:fatal(message)
	self:log(LogLevel.FATAL, message)
end

---@alias Formatter function(logger: Logger, level: LogLevel, message: string): string
---@type table<string, Formatter>
Logger.PatternFormatters = {
	["Name"] = Logger.getName,
	["DateTime"] = function()
		return os.date("%Y-%m-%d %H:%M:%S")
	end,
	["LogLevel"] = function(_, logLevel, _)
		return LogLevelStr[logLevel]
	end,
	["Message"] = function(_, _, message)
		return message
	end,
}

---@param logLevel LogLevel
---@param message string
---@return string
function Logger:formatMessage(logLevel, message)
	local formatedMessage = self:getFormat()
	for pattern, formatter in pairs(Logger.PatternFormatters) do
		formatedMessage = formatedMessage:gsub("%%" .. pattern, formatter(self, logLevel, message))
	end

	return formatedMessage
end

return Logger

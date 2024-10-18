local Logger = require("behaves2.utils.logger")

describe("#Logger", function()
	local logFile

	before_each(function()
		logFile = io.tmpfile()
	end)

	after_each(function()
		logFile:close()
	end)

	describe("#initialize", function()
		it("should initialize with default values", function()
			local logger = Logger:new()
			assert.are.equal("", logger:getName())
			assert.are.equal(Logger.LogLevel.INFO, logger:getLogLevel())
			assert.are.equal("%DateTime [%LogLevel]: %Message\n", logger:getFormat())
			assert.are.equal(io.stdout, logger:getOutputFile())
		end)

		it("should initialize with provided values", function()
			local logger = Logger:new("A very nice name", Logger.LogLevel.DEBUG, "%Message", logFile)
			assert.are.equal("A very nice name", logger:getName())
			assert.are.equal(Logger.LogLevel.DEBUG, logger:getLogLevel())
			assert.are.equal("%Message", logger:getFormat())
			assert.are.equal(logFile, logger:getOutputFile())
		end)
	end)

	it("#setName #getName should set and get the logger's name", function()
		local logger = Logger:new()
		logger:setName("A name")
		assert.are.equal("A name", logger:getName())
	end)

	it("#setLogLevel #getLogLevel should set and get the log level", function()
		local logger = Logger:new()
		logger:setLogLevel(Logger.LogLevel.ERROR)
		assert.are.equal(Logger.LogLevel.ERROR, logger:getLogLevel())
	end)

	it("#setFormat #getFormat should set and get the log format", function()
		local logger = Logger:new()
		logger:setFormat("%Message")
		assert.are.equal("%Message", logger:getFormat())
	end)

	it("#setOutputFile #getOutputFile should set and get the log output file", function()
		local logger = Logger:new()
		logger:setOutputFile(logFile)
		assert.are.equal(logFile, logger:getOutputFile())
	end)

	describe("#formatMessage", function()
		local logger

		before_each(function()
			logger = Logger:new()
		end)

		it("should replace %Name with the corresponding logger name", function()
			logger:setName("PrettyLogger")
			logger:setFormat("%Name")
			local formatedMessage = logger:formatMessage("")
			assert.are.equal("PrettyLogger", formatedMessage)
		end)

		it("should replace %LogLevel with the corresponding LogLevel string name", function()
			logger:setLogLevel(Logger.LogLevel.INFO)
			logger:setFormat("%LogLevel")
			local formatedMessage = logger:formatMessage("")
			assert.are.equal("INFO", formatedMessage)
		end)

		it("should replace %Message with the corresponding message", function()
			logger:setLogLevel(Logger.LogLevel.FATAL)
			logger:setFormat("Message: %Message")
			local formatedMessage = logger:formatMessage("Hello World!")
			assert.are.equal("Message: Hello World!", formatedMessage)
		end)

		it("should replace %DateTime with the current date and time", function()
			logger:setLogLevel(Logger.LogLevel.FATAL)
			logger:setFormat("%DateTime")
			stub(os, "date").returns("2020-01-01 00:00:00")
			local formatedMessage = logger:formatMessage("Example")
			assert.are.equal("2020-01-01 00:00:00", formatedMessage)
		end)

		it("should replace multiple different patterns", function()
			logger:setLogLevel(Logger.LogLevel.WARN)
			logger:setFormat("[%LogLevel] %Message")
			local formatedMessage = logger:formatMessage("Test message")
			assert.are.equal("[WARN] Test message", formatedMessage)
		end)

		it("should replace multiple equal patterns", function()
			logger:setLogLevel(Logger.LogLevel.ERROR)
			logger:setFormat("%LogLevel %LogLevel %LogLevel")
			local formatedMessage = logger:formatMessage("Test message")
			assert.are.equal("ERROR ERROR ERROR", formatedMessage)
		end)

		it("should not fail if the given pattern name does not exist", function()
			logger:setFormat("%UnknownPattern")
			assert.has_no.errors(function()
				logger:formatMessage("Test message")
			end)
		end)

		it("should leave unknown patterns unchanged", function()
			logger:setFormat("%UnknownPattern %Message")
			local formatedMessage = logger:formatMessage("Test message")
			assert.are.equal("%UnknownPattern Test message", formatedMessage)
		end)
	end)

	describe("#log", function()
		local logger

		before_each(function()
			logger = Logger:new()
			logger:setOutputFile(logFile)
		end)

		describe("#wrappers", function()
			it("#info should log a messsage with LogLevel.INFO", function()
				stub(logger, "log")
				logger:info("This is an info message")
				assert.stub(logger.log).was_called_with(logger, Logger.LogLevel.INFO, "This is an info message")
			end)

			it("#debug should log a message with LogLevel.DEBUG", function()
				stub(logger, "log")
				logger:debug("This is a debug message")
				assert.stub(logger.log).was_called_with(logger, Logger.LogLevel.DEBUG, "This is a debug message")
			end)

			it("#warn should log a message with LogLevel.WARN", function()
				stub(logger, "log")
				logger:warn("This is a warning message")
				assert.stub(logger.log).was_called_with(logger, Logger.LogLevel.WARN, "This is a warning message")
			end)

			it("#error should log a message with LogLevel.ERROR", function()
				stub(logger, "log")
				logger:error("This is an error message")
				assert.stub(logger.log).was_called_with(logger, Logger.LogLevel.ERROR, "This is an error message")
			end)

			it("#fatal should log a message with LogLevel.FATAL", function()
				stub(logger, "log")
				logger:fatal("This is a fatal message")
				assert.stub(logger.log).was_called_with(logger, Logger.LogLevel.FATAL, "This is a fatal message")
			end)
		end)

		it("should write messages to output file", function()
			logger:setLogLevel(Logger.LogLevel.INFO)
			logger:setFormat("%Message")

			logger:log(Logger.LogLevel.INFO, "This is an info message")

			logFile:seek("set")
			local content = logFile:read("*a")
			assert.are.equal("This is an info message", content)
		end)

		it("should not write messages to output file if the message's log level is lower than the logger's", function()
			logger:setLogLevel(Logger.LogLevel.DEBUG)
			logger:setFormat("%Message")

			logger:log(Logger.LogLevel.INFO, "This is an info message")

			stub(io, "write")
			assert.stub(io.write).was_not_called()
			---@diagnostic disable-next-line: undefined-field
			io.write:revert()
		end)
	end)
end)

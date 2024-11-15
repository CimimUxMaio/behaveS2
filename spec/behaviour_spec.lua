local extends = require("oopsie").extends
local Entity = require("behaves2.entity")
local Behaviour = require("behaves2.behaviour")

describe("#Behaviour", function()
	local model
	local entityMock
	local behaviourMock

	before_each(function()
		model = { value = 42 }
		entityMock = Entity:new(model)
		behaviourMock = Behaviour:new()
	end)

	describe("#initialize", function()
		it("if unchanged an instanced behaviour should return its default values", function()
			assert.are.same({}, behaviourMock:getRequirements())
			assert.are.equal(math.huge, behaviourMock:getDrawOrder())
			assert.are.equal(math.huge, behaviourMock:getDrawLayer())
			assert.are.equal("do-nothing", behaviourMock:getPauseMode())
		end)

		it("subclasses should also return default values if unchanged", function()
			local OtherBehaviourCls = extends("OtherBehaviourCls", Behaviour)
			local otherBehaviour = OtherBehaviourCls:new()
			assert.are.same({}, otherBehaviour:getRequirements())
			assert.are.equal(math.huge, otherBehaviour:getDrawOrder())
			assert.are.equal(math.huge, otherBehaviour:getDrawLayer())
			assert.are.equal("do-nothing", otherBehaviour:getPauseMode())
		end)
	end)

	it("#setDrawOrder #getDrawOrder should set and get draw order", function()
		behaviourMock:setDrawOrder(5)
		assert.are.equal(5, behaviourMock:getDrawOrder())
	end)

	it("#setDrawLayer #getDrawLayer should set and get draw layer", function()
		behaviourMock:setDrawLayer(3)
		assert.are.equal(3, behaviourMock:getDrawLayer())
	end)

	it("#_setEntity #getEntity should set and get the behaviour's entity", function()
		behaviourMock:_setEntity(entityMock)
		assert.are.equal(entityMock, behaviourMock:getEntity())
	end)

	it("#getModel should return the model from the entity", function()
		stub(behaviourMock, "getEntity").returns(entityMock)
		assert.are.equal(model, behaviourMock:getModel())
	end)

	describe("#setPauseMode", function()
		it("#getPauseMode should set and get pause mode", function()
			behaviourMock:setPauseMode("do-all")
			assert.are.equal("do-all", behaviourMock:getPauseMode())
		end)

		it("should error if the given mode is not a valid pause mode", function()
			assert.has.errors(function()
				--- @diagnostic disable-next-line: param-type-mismatch
				behaviourMock:setPauseMode("invalid-mode")
			end)
		end)
	end)

	describe("#isUpdateable", function()
		before_each(function()
			behaviourMock:_setEntity(entityMock)
		end)

		it("should return true if it's entity is not paused", function()
			stub(entityMock, "isPaused").returns(false)
			assert.is_true(behaviourMock:isUpdateable())
		end)

		describe("if it's entity is paused", function()
			before_each(function()
				stub(entityMock, "isPaused").returns(true)
			end)

			it("it should return false if the pause mode is either 'do-nothing' or 'draw-only", function()
				behaviourMock:setPauseMode("do-nothing")
				assert.is_false(behaviourMock:isUpdateable())

				behaviourMock:setPauseMode("draw-only")
				assert.is_false(behaviourMock:isUpdateable())
			end)

			it("it should return true if the pause mode is 'do-all'", function()
				behaviourMock:setPauseMode("do-all")
				assert.is_true(behaviourMock:isUpdateable())
			end)
		end)
	end)

	describe("#isDrawable", function()
		before_each(function()
			behaviourMock:_setEntity(entityMock)
		end)

		it("should return true if it's entity is not paused", function()
			stub(entityMock, "isPaused").returns(false)
			assert.is_true(behaviourMock:isDrawable())
		end)

		describe("if it's entity is paused", function()
			before_each(function()
				stub(entityMock, "isPaused").returns(true)
			end)

			it("it should return false if the pause mode is 'do-nothing'", function()
				behaviourMock:setPauseMode("do-nothing")
				assert.is_false(behaviourMock:isDrawable())
			end)

			it("it should return true if the pause mode is either 'do-all' or 'draw-only'", function()
				behaviourMock:setPauseMode("do-all")
				assert.is_true(behaviourMock:isDrawable())

				behaviourMock:setPauseMode("draw-only")
				assert.is_true(behaviourMock:isDrawable())
			end)
		end)
	end)

	describe("#handleEvent", function()
		it("should call the event handler once", function()
			function behaviourMock:onTestEvent() end
			spy.on(behaviourMock, "onTestEvent")
			behaviourMock:handleEvent("testEvent")
			assert.spy(behaviourMock.onTestEvent).was_called(1)
		end)

		it("should not call a handler for other than the target event", function()
			function behaviourMock:onOtherEvent() end
			spy.on(behaviourMock, "onOtherEvent")
			behaviourMock:handleEvent("testEvent")
			assert.spy(behaviourMock.onOtherEvent).was_not_called()
		end)
	end)

	it("#handledEvents should return handled event names", function()
		function behaviourMock:onTestEvent() end
		function behaviourMock:onOtherEvent() end
		function behaviourMock:onUpdate() end
		function behaviourMock:onReady() end
		local events = behaviourMock:handledEvents()
		table.sort(events)
		assert.are.same({ "otherEvent", "ready", "testEvent", "update" }, events)
	end)

	it("#handledEvents should return handled event names for subclasses", function()
		local OtherBehaviourCls = extends("OtherBehaviourCls", Behaviour)
		---@class OtherBehaviourCls : Behaviour
		local otherBehaviour = OtherBehaviourCls:new()
		function otherBehaviour:onTestEvent() end
		function otherBehaviour:onUpdate() end
		local events = otherBehaviour:handledEvents()
		table.sort(events)
		assert.are.same({ "testEvent", "update" }, events)
	end)

	describe("#_checkRequirements", function()
		before_each(function()
			behaviourMock = Behaviour:new({ "TestRequirement" })
			behaviourMock:_setEntity(entityMock)
		end)

		it("should not fail if requirements are satisfied", function()
			stub(entityMock, "hasBehaviour").returns(true)
			assert.has_no.errors(function()
				behaviourMock:_checkRequirements()
			end)
		end)

		it("should fail if requirements are not met", function()
			stub(entityMock, "hasBehaviour").returns(false)
			assert.has.errors(function()
				behaviourMock:_checkRequirements()
			end)
		end)
	end)
end)

local extends = require("oopsie").extends
local Entity = require("entity")
local Behaviour = require("behaviour")

describe("#Behaviour", function()
	local model
	local entityMock
	local behaviourMock

	before_each(function()
		model = { value = 42 }
		entityMock = Entity:new(model)
		behaviourMock = Behaviour:new()
	end)

	it("#initialize should initialize with default values", function()
		assert.are.same({}, behaviourMock:getRequirements())
		assert.are.equal(math.huge, behaviourMock:getDrawOrder())
		assert.are.equal(math.huge, behaviourMock:getDrawLayer())
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
		local events = behaviourMock:handledEvents()
		table.sort(events)
		assert.are.same({ "otherEvent", "testEvent", "update" }, events)
	end)

	describe("#_checkRequirements", function()
		local OtherBehaviourCls

		before_each(function()
			OtherBehaviourCls = extends("TestRequirement", Behaviour)
			behaviourMock = Behaviour:new({ OtherBehaviourCls })
			behaviourMock:_setEntity(entityMock)
		end)

		it("#_checkRequirements should not fail if requirements are satisfied", function()
			stub(entityMock, "hasBehaviour").returns(true)
			assert.has_no.errors(function()
				behaviourMock:_checkRequirements()
			end)
		end)

		it("#_checkRequirements should fail if requirements are not met", function()
			stub(entityMock, "hasBehaviour").returns(false)
			assert.has.errors(function()
				behaviourMock:_checkRequirements()
			end)
		end)
	end)
end)

local extends = require("oopsie").extends
local Game = require("game")
local Entity = require("entity")
local Behaviour = require("behaviour")

describe("#Entity", function()
	---@type Entity
	local entity
	---@type Behaviour
	local behaviourMock
	---@type Game
	local gameMock

	before_each(function()
		entity = Entity:new()
		behaviourMock = Behaviour:new()
		gameMock = Game:new()
	end)

	it("#initialize should initialize with default values", function()
		assert.are.same({}, entity:getBehaviours())
		assert.are.equal(math.huge, entity:getDrawOrder())
		assert.are.equal(math.huge, entity:getDrawLayer())
		assert.is_false(entity:isDestroyed())
	end)

	it("#_setId #getId should set and get id", function()
		entity:_setId("test_id")
		assert.are.equal("test_id", entity:getId())
	end)

	it("#_setGame #getGame should set and get game", function()
		entity:_setGame(gameMock)
		assert.are.equal(gameMock, entity:getGame())
	end)

	it("#_setDestroyed #isDestroyed should set destroyed state", function()
		entity:_setDestroyed()
		assert.is_true(entity:isDestroyed())
	end)

	it("multiple #_setDestroyed should set destroyed state anyways", function()
		entity:_setDestroyed()
		entity:_setDestroyed()
		entity:_setDestroyed()
		assert.is_true(entity:isDestroyed())
	end)

	describe("#addBehaviour #getBehaviour", function()
		local CustomBehaviourCls
		local customBehaviourMock

		before_each(function()
			CustomBehaviourCls = extends("CustomBehaviour", Behaviour)
			customBehaviourMock = CustomBehaviourCls:new()
		end)

		it("should return nil if the entity does not have the behaviour", function()
			assert.is_nil(entity:getBehaviour(Behaviour))
		end)

		it("should add behaviour", function()
			entity:addBehaviour(behaviourMock)
			assert.are.equal(behaviourMock, entity:getBehaviour(Behaviour))
		end)

		it("should return nil if the added behaviour is not of the given class", function()
			entity:addBehaviour(behaviourMock)
			assert.is_nil(entity:getBehaviour(CustomBehaviourCls))
		end)

		it("should allow to add multiple behaviours of different types", function()
			entity:addBehaviour(behaviourMock)
			entity:addBehaviour(customBehaviourMock)
			assert.are.equal(behaviourMock, entity:getBehaviour(Behaviour))
			assert.are.equal(customBehaviourMock, entity:getBehaviour(CustomBehaviourCls))
		end)

		it("should error if the entity already has a behavior of the given type", function()
			entity:addBehaviour(behaviourMock)
			assert.has.errors(function()
				entity:addBehaviour(behaviourMock)
			end)
		end)

		it("should subscribe the behaviour to the game if the entity is spawned", function()
			stub(gameMock, "_subscribe")
			entity:_setGame(gameMock)
			entity:addBehaviour(behaviourMock)
			assert.stub(gameMock._subscribe).was_called_with(gameMock, behaviourMock)
		end)

		it("should not unsubscribe the behaviour from the game if the entity is not spawned", function()
			stub(gameMock, "_subscribe")
			stub(gameMock, "_unsubscribe")
			stub(entity, "isSpawned").returns(false)
			entity:_setGame(gameMock)
			entity:addBehaviour(behaviourMock)
			entity:removeBehaviour(Behaviour)
			assert.stub(gameMock._unsubscribe).was_not_called()
		end)
	end)

	describe("#removeBehaviour", function()
		it("should remove behaviour", function()
			entity:addBehaviour(behaviourMock)
			entity:removeBehaviour(Behaviour)
			assert.is_nil(entity:getBehaviour(Behaviour))
		end)

		it("should not error if the given behaviour is not included in the entity", function()
			assert.has_no.errors(function()
				entity:removeBehaviour(Behaviour)
			end)
		end)

		it("should unsubscribe the behaviour from the game if the entity is spawned", function()
			stub(gameMock, "_subscribe")
			stub(gameMock, "_unsubscribe")
			entity:_setGame(gameMock)
			entity:addBehaviour(behaviourMock)
			entity:removeBehaviour(Behaviour)
			assert.stub(gameMock._unsubscribe).was_called_with(gameMock, behaviourMock)
		end)

		it("should not unsubscribe the behaviour from the game if the entity is not spawned", function()
			stub(gameMock, "_subscribe")
			stub(gameMock, "_unsubscribe")
			stub(entity, "isSpawned").returns(false)
			entity:_setGame(gameMock)
			entity:addBehaviour(behaviourMock)
			entity:removeBehaviour(Behaviour)
			assert.stub(gameMock._unsubscribe).was_not_called()
		end)

		it("should not call unsubscribe if the entity does not have a behaviour of the given class", function()
			stub(gameMock, "_subscribe")
			stub(gameMock, "_unsubscribe")
			entity:_setGame(gameMock)
			entity:removeBehaviour(Behaviour)
			assert.stub(gameMock._unsubscribe).was_not_called()
		end)
	end)

	it("#hasBehaviour should return if the entity has a behaviour of the given type", function()
		entity:addBehaviour(behaviourMock)
		assert.is_true(entity:hasBehaviour(Behaviour))
		entity:removeBehaviour(Behaviour)
		assert.is_false(entity:hasBehaviour(Behaviour))
	end)

	it("#raiseEvent should raise event to its behaviours", function()
		spy.on(behaviourMock, "handleEvent")
		entity:addBehaviour(behaviourMock)
		entity:raiseEvent("testEvent")
		assert.spy(behaviourMock.handleEvent).was_called_with(behaviourMock, "testEvent")
	end)

	it("#isSpawned should return if the entity is spawned within a Game", function()
		assert.is_false(entity:isSpawned())
		entity:_setGame(gameMock)
		assert.is_true(entity:isSpawned())
		entity:_setDestroyed()
		assert.is_false(entity:isSpawned())
	end)

	it("#setDrawLayer #getDrawLayer should set and get the entity's draw layer", function()
		entity:setDrawLayer(3)
		assert.are.equal(3, entity:getDrawLayer())
	end)

	it("#setDrawOrder #getDrawOrder should set and get the entity's draw order", function()
		entity:setDrawOrder(5)
		assert.are.equal(5, entity:getDrawOrder())
	end)

	it("#getModel should return the model set with #initialize", function()
		local model = { key = "value" }
		entity = Entity:new(model)
		assert.are.same(model, entity:getModel())
	end)
end)

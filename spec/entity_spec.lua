local extends = require("oopsie").extends
local Game = require("behaves2.game")
local Entity = require("behaves2.entity")
local Behaviour = require("behaves2.behaviour")

describe("#Entity", function()
	---@type Entity
	local entity
	---@type Entity
	local otherEntity
	---@type Behaviour
	local behaviourMock
	---@type Game
	local gameMock

	before_each(function()
		entity = Entity:new()
		otherEntity = Entity:new()
		behaviourMock = Behaviour:new()
		gameMock = Game:new()
	end)

	it("#initialize should initialize with default values", function()
		assert.are.same({}, entity:getBehaviours())
		assert.are.equal(math.huge, entity:getDrawOrder())
		assert.are.equal(math.huge, entity:getDrawLayer())
		assert.are.same({}, entity:getModel())
		assert.is_nil(entity:getParent())
		assert.are.same({}, entity:getChildren())
		assert.is_false(entity:isDestroyed())
		assert.is_false(entity:isPaused())
		assert.are.equal("do-nothing", entity:getPauseMode())
	end)

	it("#_setId #getId should set and get id", function()
		entity:_setId("test_id")
		assert.are.equal("test_id", entity:getId())
	end)

	it("#_setGame #getGame should set and get game", function()
		entity:_setGame(gameMock)
		assert.are.equal(gameMock, entity:getGame())
	end)

	it("#_setParent #getParent should set and get parent entity", function()
		entity:_setParent(otherEntity)
		assert.are.equal(otherEntity, entity:getParent())
	end)

	it("#_setDestroyed #isDestroyed should set destroyed state", function()
		entity:_setDestroyed()
		assert.is_true(entity:isDestroyed())
	end)

	it("#setPaused #isPaused should set paused state", function()
		entity:setPaused(true)
		assert.is_true(entity:isPaused())
	end)

	describe("#setPauseMode", function()
		it("#getPauseMode should set and get pause mode", function()
			entity:setPauseMode("do-all")
			assert.are.equal("do-all", entity:getPauseMode())
		end)

		it("should error if the given mode is not a valid pause mode", function()
			assert.has.errors(function()
				--- @diagnostic disable-next-line: param-type-mismatch
				entity:setPauseMode("invalid-mode")
			end)
		end)
	end)

	it("multiple #_setDestroyed should set destroyed state anyways", function()
		entity:_setDestroyed()
		entity:_setDestroyed()
		entity:_setDestroyed()
		assert.is_true(entity:isDestroyed())
	end)

	describe("#isUpdateable", function()
		it("should return false if the entity is destroyed", function()
			entity:_setDestroyed()
			assert.is_false(entity:isUpdateable())
		end)

		it("should return true if the entity is not paused", function()
			assert.is_true(entity:isUpdateable())
		end)

		describe("if the entity is paused", function()
			it("it should return false if the pause mode is either 'do-nothing' or 'draw-only", function()
				entity:setPaused(true)

				entity:setPauseMode("do-nothing")
				assert.is_false(entity:isUpdateable())

				entity:setPauseMode("draw-only")
				assert.is_false(entity:isUpdateable())
			end)

			it("it should return true if the pause mode is 'do-all'", function()
				entity:setPaused(true)
				entity:setPauseMode("do-all")
				assert.is_true(entity:isUpdateable())
			end)
		end)
	end)

	describe("#isDrawable", function()
		it("should return false if the entity is destroyed", function()
			entity:_setDestroyed()
			assert.is_false(entity:isDrawable())
		end)

		it("should return true if the entity is not paused", function()
			assert.is_true(entity:isDrawable())
		end)

		describe("if the entity is paused", function()
			it("it should return false if the pause mode is 'do-nothing'", function()
				entity:setPaused(true)
				entity:setPauseMode("do-nothing")
				assert.is_false(entity:isDrawable())
			end)

			it("it should return true if the pause mode is either 'do-all' or 'draw-only'", function()
				entity:setPaused(true)

				entity:setPauseMode("do-all")
				assert.is_true(entity:isDrawable())

				entity:setPauseMode("draw-only")
				assert.is_true(entity:isDrawable())
			end)
		end)
	end)

	describe("#getBehaviour", function()
		it("should return nil if the entity does not have the behaviour", function()
			assert.is_nil(entity:getBehaviour("Unknown"))
		end)

		it("should return the added behaviours of the given class", function()
			entity:addBehaviour(behaviourMock)
			assert.are.equal(behaviourMock, entity:getBehaviour("Behaviour"))
		end)
	end)

	it("#getBehaviours should return all added behaviours as a list", function()
		local CustomBehaviourCls = extends("CustomBehaviour", Behaviour)
		local customBehaviourMock = CustomBehaviourCls:new()
		entity:addBehaviour(behaviourMock)
		entity:addBehaviour(customBehaviourMock)
		assert.are.same({ behaviourMock, customBehaviourMock }, entity:getBehaviours())
	end)

	describe("#addBehaviour", function()
		local CustomBehaviourCls
		local customBehaviourMock

		before_each(function()
			CustomBehaviourCls = extends("CustomBehaviour", Behaviour)
			customBehaviourMock = CustomBehaviourCls:new()
		end)

		it("should add behaviour", function()
			entity:addBehaviour(behaviourMock)
			assert.are.equal(behaviourMock, entity:getBehaviour("Behaviour"))
		end)

		it("should allow to add multiple behaviours of different types", function()
			entity:addBehaviour(behaviourMock)
			entity:addBehaviour(customBehaviourMock)
			assert.are.equal(behaviourMock, entity:getBehaviour("Behaviour"))
			assert.are.equal(customBehaviourMock, entity:getBehaviour("CustomBehaviour"))
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
			entity:removeBehaviour("Behaviour")
			assert.stub(gameMock._unsubscribe).was_not_called()
		end)

		it("should return itself", function()
			assert.are.equal(entity, entity:addBehaviour(behaviourMock))
		end)
	end)

	describe("#removeBehaviour", function()
		it("should remove behaviour", function()
			entity:addBehaviour(behaviourMock)
			entity:removeBehaviour("Behaviour")
			assert.is_nil(entity:getBehaviour("Behaviour"))
		end)

		it("should not error if the given behaviour is not included in the entity", function()
			assert.has_no.errors(function()
				entity:removeBehaviour("Behaviour")
			end)
		end)

		it("should unsubscribe the behaviour from the game if the entity is spawned", function()
			stub(gameMock, "_subscribe")
			stub(gameMock, "_unsubscribe")
			entity:_setGame(gameMock)
			entity:addBehaviour(behaviourMock)
			entity:removeBehaviour("Behaviour")
			assert.stub(gameMock._unsubscribe).was_called_with(gameMock, behaviourMock)
		end)

		it("should not unsubscribe the behaviour from the game if the entity is not spawned", function()
			stub(gameMock, "_subscribe")
			stub(gameMock, "_unsubscribe")
			stub(entity, "isSpawned").returns(false)
			entity:_setGame(gameMock)
			entity:addBehaviour(behaviourMock)
			entity:removeBehaviour("Behaviour")
			assert.stub(gameMock._unsubscribe).was_not_called()
		end)

		it("should not call unsubscribe if the entity does not have a behaviour of the given class", function()
			stub(gameMock, "_subscribe")
			stub(gameMock, "_unsubscribe")
			entity:_setGame(gameMock)
			entity:removeBehaviour("Behaviour")
			assert.stub(gameMock._unsubscribe).was_not_called()
		end)
	end)

	describe("#addChild", function()
		local childEntity

		before_each(function()
			childEntity = Entity:new()
		end)

		it("should add a child entity to the children list", function()
			entity:addChild(otherEntity)
			assert.has(entity:getChildren(), otherEntity)
		end)

		it("should be able to add multiple children", function()
			entity:addChild(otherEntity)
			entity:addChild(childEntity)
			assert.are.same({ otherEntity, childEntity }, entity:getChildren())
		end)

		it("should spawn the child if the entity is already spawned", function()
			stub(gameMock, "spawn")
			entity:_setGame(gameMock)
			entity:addChild(otherEntity)
			assert.stub(gameMock.spawn).was_called_with(gameMock, otherEntity)
		end)

		it("should not spawn the child if the entity is not spawned", function()
			stub(gameMock, "spawn")
			stub(entity, "isSpawned").returns(false)
			entity:_setGame(gameMock)
			entity:addChild(otherEntity)
			assert.stub(gameMock.spawn).was_not_called()
		end)

		it("should not spawn the child if the child is already spawned", function()
			stub(entity, "isSpawned").returns(true)
			stub(otherEntity, "isSpawned").returns(true)
			stub(gameMock, "spawn")
			entity:_setGame(gameMock)
			entity:addChild(otherEntity)
			assert.stub(gameMock.spawn).was_not_called()
		end)

		it("should set the parent of the child entity to self", function()
			entity:addChild(otherEntity)
			assert.are.equal(entity, otherEntity:getParent())
		end)

		it("should set the child to paused if the parent is paused", function()
			entity:setPaused(true)
			entity:addChild(otherEntity)
			assert.is_true(otherEntity:isPaused())
		end)

		it("should not set the child to paused if the parent is not paused", function()
			entity:addChild(otherEntity)
			assert.is_false(otherEntity:isPaused())
		end)
	end)

	describe("#removeChild", function()
		local childEntity

		before_each(function()
			childEntity = Entity:new()
		end)

		it("should remove a child entity from the children list", function()
			entity:addChild(otherEntity)
			entity:removeChild(otherEntity)
			assert.has_no(entity:getChildren(), otherEntity)
		end)

		it("should not remove children other than the given one", function()
			entity:addChild(otherEntity)
			entity:addChild(childEntity)
			entity:removeChild(otherEntity)
			assert.has_no(entity:getChildren(), otherEntity)
			assert.has(entity:getChildren(), childEntity)
		end)

		it("should set the parent of the child entity to nil", function()
			entity:addChild(otherEntity)
			entity:removeChild(otherEntity)
			assert.is_nil(otherEntity:getParent())
		end)

		it("should not modify other children's parent property", function()
			entity:addChild(otherEntity)
			entity:addChild(childEntity)
			entity:removeChild(otherEntity)
			assert.are.equal(entity, childEntity:getParent())
		end)
	end)

	it("#hasBehaviour should return if the entity has a behaviour of the given type", function()
		entity:addBehaviour(behaviourMock)
		assert.is_true(entity:hasBehaviour("Behaviour"))
		entity:removeBehaviour("Behaviour")
		assert.is_false(entity:hasBehaviour("Behaviour"))
	end)

	describe("#raiseEvent", function()
		it("should raise the event to its behaviours", function()
			spy.on(behaviourMock, "handleEvent")
			entity:addBehaviour(behaviourMock)
			entity:raiseEvent("testEvent")
			assert.spy(behaviourMock.handleEvent).was_called_with(behaviourMock, "testEvent")
		end)

		it("should not raise the event for its children behaviours", function()
			local childBehaviourMock = Behaviour:new()
			spy.on(childBehaviourMock, "handleEvent")
			spy.on(behaviourMock, "handleEvent")

			entity:addBehaviour(behaviourMock)
			otherEntity:addBehaviour(childBehaviourMock)

			entity:addChild(otherEntity)

			entity:raiseEvent("testEvent")
			assert.spy(childBehaviourMock.handleEvent).was_not_called()
		end)

		it("should only raise the event to its behaviours once", function()
			spy.on(behaviourMock, "handleEvent")
			entity:addBehaviour(behaviourMock)
			entity:raiseEvent("testEvent")
			assert.spy(behaviourMock.handleEvent).was_called(1)
		end)
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

local Game = require("behaves2.game")
local Entity = require("behaves2.entity")
local Behaviour = require("behaves2.behaviour")
local match = require("luassert.match")
local utils = require("behaves2.utils.math")

describe("#Game", function()
	local game
	local entityMock
	local behaviourMock

	before_each(function()
		game = Game:new()
		entityMock = Entity:new()
		behaviourMock = Behaviour:new()
		stub(behaviourMock, "handleEvent")
		stub(behaviourMock, "getEntity").returns(entityMock)
	end)

	describe("#initialize", function()
		it("should initialize with default values", function()
			assert.are.same({}, game.entities)
			assert.are.same({}, game.subscriptions)
			assert.are.same({}, game.destroyed)
			assert.are.same({}, game.deferredTasks)
		end)
	end)

	describe("#spawn", function()
		local childEntityMock1
		local childEntityMock2

		before_each(function()
			childEntityMock1 = Entity:new()
			childEntityMock2 = Entity:new()
		end)

		it("should add the given entity to the entities table", function()
			game:spawn(entityMock)
			assert.has(entityMock, game.entities)
		end)

		it("should raise the entity's spawn event", function()
			stub(entityMock, "raiseEvent")
			game:spawn(entityMock)
			assert.stub(entityMock.raiseEvent).was_called_with(match.is_ref(entityMock), "spawn")
		end)

		it("should call #_subscribe for each of the entity's behaviours", function()
			local behaviourMock1, behaviourMock2 = {}, {}
			stub(entityMock, "getBehaviours").returns({ behaviourMock1, behaviourMock2 })
			stub(game, "_subscribe")
			game:spawn(entityMock)
			assert.stub(game._subscribe).was_called_with(match.is_ref(game), match.is_ref(behaviourMock1))
			assert.stub(game._subscribe).was_called_with(match.is_ref(game), match.is_ref(behaviourMock2))
		end)

		it("should set the entity's #_setId method", function()
			spy.on(entityMock, "_setId")
			game:spawn(entityMock)
			assert.spy(entityMock._setId).was_called_with(match.is_ref(entityMock), match.is_string())
		end)

		it("should call the entity's #_setGame method", function()
			stub(entityMock, "_setGame")
			game:spawn(entityMock)
			assert.stub(entityMock._setGame).was_called_with(match.is_ref(entityMock), match.is_ref(game))
		end)

		it("should also spawn the entity's children", function()
			stub(entityMock, "getChildren").returns({ childEntityMock1, childEntityMock2 })
			spy.on(game, "spawn")
			game:spawn(entityMock)
			assert.spy(game.spawn).was_called_with(match.is_ref(game), match.is_ref(entityMock))
			assert.spy(game.spawn).was_called_with(match.is_ref(game), match.is_ref(childEntityMock1))
			assert.spy(game.spawn).was_called_with(match.is_ref(game), match.is_ref(childEntityMock2))
			assert.spy(game.spawn).was_called(3)
		end)

		it("should not call spawn additional times if the entity has no children", function()
			spy.on(game, "spawn")
			game:spawn(entityMock)
			assert.spy(game.spawn).was_called(1)
		end)

		it("should fail if the entity is already spawned", function()
			stub(entityMock, "getId").returns("entity_id")
			stub(entityMock, "isSpawned").returns(true)
			assert.has.errors(function()
				game:spawn(entityMock)
			end)
		end)
	end)

	describe("#destroy", function()
		before_each(function()
			stub(utils, "uuid").returns("entity_id")
			game:spawn(entityMock)
			---@diagnostic disable-next-line: undefined-field
			utils.uuid:revert()
		end)

		it("should fail if the entity was not spawned", function()
			stub(entityMock, "isSpawned").returns(false)
			assert.has.errors(function()
				game:destroy(entityMock)
			end)
		end)

		describe("entities table", function()
			it("should not remove the entity from the entities table if not called", function()
				assert.are.equal(entityMock, game.entities["entity_id"])
			end)

			it("should remove the entity from the entities table", function()
				game:destroy(entityMock)
				assert.is_nil(game.entities["entity_id"])
			end)

			it("should remove the entity from the entities table given its ID string", function()
				game:destroy("entity_id")
				assert.is_nil(game.entities["entity_id"])
			end)
		end)

		it("if it has a parent, it should remove itself from it's parent children", function()
			local parentEntityMock = Entity:new()
			stub(entityMock, "getParent").returns(parentEntityMock)
			stub(parentEntityMock, "removeChild")
			game:destroy(entityMock)
			assert.stub(parentEntityMock.removeChild).was_called_with(parentEntityMock, entityMock)
		end)

		describe("with children", function()
			local childEntityMock1
			local childEntityMock2

			before_each(function()
				childEntityMock1 = Entity:new()
				childEntityMock2 = Entity:new()
			end)

			it("should also destroy the entity's children", function()
				entityMock:addChild(childEntityMock1)
				entityMock:addChild(childEntityMock2)

				spy.on(game, "destroy")

				game:destroy(entityMock)

				assert.spy(game.destroy).was_called_with(match.is_ref(game), match.is_ref(entityMock))
				assert.spy(game.destroy).was_called_with(match.is_ref(game), match.is_ref(childEntityMock1))
				assert.spy(game.destroy).was_called_with(match.is_ref(game), match.is_ref(childEntityMock2))
				assert.spy(game.destroy).was_called(3)
			end)

			it("should destroy its children's children", function()
				entityMock:addChild(childEntityMock1)
				childEntityMock1:addChild(childEntityMock2)

				spy.on(game, "destroy")

				game:destroy(entityMock)

				assert.spy(game.destroy).was_called_with(match.is_ref(game), match.is_ref(entityMock))
				assert.spy(game.destroy).was_called_with(match.is_ref(game), match.is_ref(childEntityMock1))
				assert.spy(game.destroy).was_called_with(match.is_ref(game), match.is_ref(childEntityMock2))
				assert.spy(game.destroy).was_called(3)
			end)
		end)

		it("should call the entity's #_setDestroyed method", function()
			stub(entityMock, "_setDestroyed")
			game:destroy(entityMock)
			assert.stub(entityMock._setDestroyed).was_called_with(match.is_ref(entityMock))
		end)

		it("should raise the entity's destroy event", function()
			stub(entityMock, "raiseEvent")
			game:destroy(entityMock)
			assert.stub(entityMock.raiseEvent).was_called_with(match.is_ref(entityMock), "destroy")
		end)

		it("should call #_unsubscribe for each of the entity's behaviours", function()
			local behaviourMock1, behaviourMock2 = {}, {}
			stub(entityMock, "getBehaviours").returns({ behaviourMock1, behaviourMock2 })
			stub(game, "_unsubscribe")
			game:destroy(entityMock)
			assert.stub(game._unsubscribe).was_called_with(match.is_ref(game), match.is_ref(behaviourMock1))
			assert.stub(game._unsubscribe).was_called_with(match.is_ref(game), match.is_ref(behaviourMock2))
		end)
	end)

	describe("#_subscribe", function()
		before_each(function()
			stub(entityMock, "getId").returns("entity_id")
		end)

		it("should call the behaviour's #_checkRequirements method", function()
			stub(behaviourMock, "_checkRequirements")
			game:_subscribe(behaviourMock)
			assert.stub(behaviourMock._checkRequirements).was_called_with(match.is_ref(behaviourMock))
		end)

		it("should insert a new item in the subscriptions table", function()
			stub(behaviourMock, "handledEvents").returns({ "testEvent", "otherEvent" })
			game:_subscribe(behaviourMock)
			assert.are.same({
				["testEvent"] = { ["entity_id"] = { behaviourMock } },
				["otherEvent"] = { ["entity_id"] = { behaviourMock } },
			}, game.subscriptions)
		end)

		it("should raise the behaviour's ready event", function()
			stub(behaviourMock, "handledEvents").returns({ "testEvent" })
			game:_subscribe(behaviourMock)
			assert.stub(behaviourMock.handleEvent).was_called_with(match.is_ref(behaviourMock), "ready")
		end)
	end)

	describe("#_unsubscribe", function()
		before_each(function()
			stub(entityMock, "getId").returns("entity_id")
		end)

		it("should remove the behaviour from the subscriptions table", function()
			stub(behaviourMock, "handledEvents").returns({ "testEvent", "otherEvent" })
			game:_subscribe(behaviourMock)
			game:_unsubscribe(behaviourMock)
			assert.are.same(
				{ ["testEvent"] = { ["entity_id"] = {} }, ["otherEvent"] = { ["entity_id"] = {} } },
				game.subscriptions
			)
		end)

		it("should raise the behaviour's ready event", function()
			stub(behaviourMock, "handledEvents").returns({ "testEvent" })
			game:_unsubscribe(behaviourMock)
			assert.stub(behaviourMock.handleEvent).was_called_with(match.is_ref(behaviourMock), "remove")
		end)
	end)

	describe("#update", function()
		local entityMock2
		local behaviourMock2

		before_each(function()
			entityMock2 = Entity:new()
			stub(entityMock2, "getId").returns("entity_id2")

			behaviourMock2 = Behaviour:new()
			stub(behaviourMock2, "getEntity").returns(entityMock2)
			stub(behaviourMock2, "handleEvent")
		end)

		it("should execute deferred tasks before the update", function()
			stub(game, "executeDeferredTasks")
			game:update(1)
			assert.stub(game.executeDeferredTasks).was_called(1)
		end)

		it("should raise the 'update' event for all updateable subscribers", function()
			stub(entityMock, "isUpdateable").returns(true)
			stub(entityMock2, "isUpdateable").returns(true)

			game.subscriptions["update"] = { ["entity_id"] = { behaviourMock }, ["entity_id2"] = { behaviourMock2 } }
			game:update(22)

			assert.stub(behaviourMock.handleEvent).was_called_with(match.is_ref(behaviourMock), "update", 22)
			assert.stub(behaviourMock2.handleEvent).was_called_with(match.is_ref(behaviourMock2), "update", 22)
		end)

		it("should not raise the 'update' event for non-updateable subscribers", function()
			stub(entityMock, "isUpdateable").returns(false)
			stub(entityMock2, "isUpdateable").returns(true)

			game.subscriptions["update"] = { ["entity_id"] = { behaviourMock }, ["entity_id2"] = { behaviourMock2 } }
			game:update(2)

			assert.stub(behaviourMock.handleEvent).was_not_called()
			assert.stub(behaviourMock2.handleEvent).was_called_with(match.is_ref(behaviourMock2), "update", 2)
		end)

		it("should not raise the 'update' event for destroyed subscribers", function()
			stub(entityMock, "isUpdateable").returns(true)
			stub(entityMock, "isDestroyed").returns(true)
			stub(entityMock2, "isUpdateable").returns(true)

			game.subscriptions["update"] = { ["entity_id"] = { behaviourMock }, ["entity_id2"] = { behaviourMock2 } }
			game:update(2)

			assert.stub(behaviourMock.handleEvent).was_not_called()
			assert.stub(behaviourMock2.handleEvent).was_called_with(match.is_ref(behaviourMock2), "update", 2)
		end)
	end)

	describe("#draw", function()
		local entityMock2
		local behaviourMock2

		before_each(function()
			entityMock2 = Entity:new()
			stub(entityMock2, "getId").returns("entity_id2")

			behaviourMock2 = Behaviour:new()
			stub(behaviourMock2, "getEntity").returns(entityMock2)
			stub(behaviourMock2, "handleEvent")
		end)

		it("should raise the 'draw' event for all drawable subscribers", function()
			stub(entityMock, "isDrawable").returns(true)
			stub(entityMock2, "isDrawable").returns(true)

			game.subscriptions["draw"] = { ["entity_id"] = { behaviourMock }, ["entity_id2"] = { behaviourMock2 } }
			game:draw()

			assert.stub(behaviourMock.handleEvent).was_called_with(match.is_ref(behaviourMock), "draw")
			assert.stub(behaviourMock2.handleEvent).was_called_with(match.is_ref(behaviourMock2), "draw")
		end)

		it("should not raise the 'draw' event for non-drawable subscribers", function()
			stub(entityMock, "isDrawable").returns(true)
			stub(entityMock2, "isDrawable").returns(false)

			game.subscriptions["draw"] = { ["entity_id"] = { behaviourMock }, ["entity_id2"] = { behaviourMock2 } }
			game:draw()

			assert.stub(behaviourMock.handleEvent).was_called_with(match.is_ref(behaviourMock), "draw")
			assert.stub(behaviourMock2.handleEvent).was_not_called()
		end)

		it("should not raise the 'draw' event for destroyed subscribers", function()
			stub(entityMock, "isDrawable").returns(true)
			stub(entityMock2, "isDrawable").returns(true)
			stub(entityMock2, "isDestroyed").returns(true)

			game.subscriptions["draw"] = { ["entity_id"] = { behaviourMock }, ["entity_id2"] = { behaviourMock2 } }
			game:draw()

			assert.stub(behaviourMock.handleEvent).was_called_with(match.is_ref(behaviourMock), "draw")
			assert.stub(behaviourMock2.handleEvent).was_not_called()
		end)
	end)

	describe("#broadcastEvent", function()
		local otherEntityMock
		local otherBehaviourMock

		before_each(function()
			otherEntityMock = Entity:new()
			stub(otherEntityMock, "getId").returns("other_entity_id")

			otherBehaviourMock = Behaviour:new()
			stub(otherBehaviourMock, "getEntity").returns(otherEntityMock)
			stub(otherBehaviourMock, "handleEvent")
		end)

		it("should raise a given event and its parameters to all subscribed behaviours", function()
			game.subscriptions["event"] =
				{ ["entity_id"] = { behaviourMock }, ["other_entity_id"] = { otherBehaviourMock } }

			game:broadcastEvent("event", 1, true, "hello")

			assert.stub(behaviourMock.handleEvent).was_called()
			assert.stub(otherBehaviourMock.handleEvent).was_called()
			assert
				.stub(behaviourMock.handleEvent)
				.was_called_with(match.is_ref(behaviourMock), "event", 1, true, "hello")
			assert
				.stub(otherBehaviourMock.handleEvent)
				.was_called_with(match.is_ref(otherBehaviourMock), "event", 1, true, "hello")
		end)

		it("should not raise the event for destroyed entities", function()
			game.subscriptions["event"] =
				{ ["entity_id"] = { behaviourMock }, ["other_entity_id"] = { otherBehaviourMock } }

			stub(otherEntityMock, "isDestroyed").returns(true)

			game:broadcastEvent("event")

			assert.stub(behaviourMock.handleEvent).was_called()
			assert.stub(otherBehaviourMock.handleEvent).was_not_called()
		end)

		it("should raise the event only once per behaviour", function()
			game.subscriptions["event"] =
				{ ["entity_id"] = { behaviourMock }, ["other_entity_id"] = { otherBehaviourMock } }

			game:broadcastEvent("event")

			assert.stub(behaviourMock.handleEvent).was_called(1)
			assert.stub(otherBehaviourMock.handleEvent).was_called(1)
		end)
	end)

	describe("deferred tasks", function()
		it("#defer adds a task to the deferred tasks queue", function()
			local task = function() end
			game:defer(task)
			assert.are.equal(1, #game.deferredTasks)
		end)

		it("#defer multiple tasks can be added before update", function()
			game:defer(function() end)
			game:defer(function() end)
			game:defer(function() end)
			assert.are.equal(3, #game.deferredTasks)
		end)

		it("are called on the next update", function()
			local task1 = spy.new(function() end)
			local task2 = spy.new(function() end)
			game:defer(task1)
			game:defer(task2)
			game:update(1)
			assert.spy(task1).was_called()
			assert.spy(task2).was_called()
		end)

		it("are called with the given arguments", function()
			local task1 = spy.new(function(_) end)
			local task2 = spy.new(function(_, _, _) end)
			game:defer(task1, 42)
			game:defer(task2, "hello", true, 2)
			game:update(1)
			assert.spy(task1).was_called_with(42)
			assert.spy(task2).was_called_with("hello", true, 2)
		end)
	end)
end)

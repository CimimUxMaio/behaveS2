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

		it("#should call the entity's #_setGame method", function()
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

		it("should not not call spawn additional times if the entity has no children", function()
			spy.on(game, "spawn")
			game:spawn(entityMock)
			assert.spy(game.spawn).was_called(1)
		end)
	end)

	describe("#destroy", function()
		describe("if present,", function()
			local parentEntityMock
			local childEntityMock1
			local childEntityMock2

			before_each(function()
				parentEntityMock = Entity:new()
				childEntityMock1 = Entity:new()
				childEntityMock2 = Entity:new()

				stub(utils, "uuid").returns("entity_id")
				game:spawn(entityMock)
			end)

			after_each(function()
				---@diagnostic disable-next-line: undefined-field
				utils.uuid:revert()
			end)

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

			it("if it has a parent, it should remove itself from it's parent children", function()
				stub(entityMock, "getParent").returns(parentEntityMock)
				stub(parentEntityMock, "removeChild")
				game:destroy(entityMock)
				assert.stub(parentEntityMock.removeChild).was_called_with(parentEntityMock, entityMock)
			end)

			it("should also destroy the entity's children", function()
				stub(entityMock, "getChildren").returns({ childEntityMock1, childEntityMock2 })
				spy.on(game, "destroy")
				game:destroy(entityMock)
				assert.spy(game.destroy).was_called_with(match.is_ref(game), match.is_ref(entityMock))
				assert.spy(game.destroy).was_called_with(match.is_ref(game), match.is_ref(childEntityMock1))
				assert.spy(game.destroy).was_called_with(match.is_ref(game), match.is_ref(childEntityMock2))
				assert.spy(game.destroy).was_called(3)
			end)
		end)

		it("should not fail if the entity is not present", function()
			assert.has_no.errors(function()
				game:destroy(entityMock)
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
		it("should call #broadcastEvent with the update event and corresponding delta time", function()
			stub(game, "broadcastEvent")
			game:update(22)
			assert.stub(game.broadcastEvent).was_called_with(match.is_ref(game), "update", 22)
		end)
	end)

	describe("#draw", function()
		local drawBehaviourMock

		before_each(function()
			drawBehaviourMock = Behaviour:new()
			stub(drawBehaviourMock, "getEntity").returns(entityMock)
			stub(drawBehaviourMock, "handleEvent")
		end)

		it("should raise the draw event for all draw subscribers", function()
			game.subscriptions["draw"] = { ["entity_id"] = { behaviourMock, drawBehaviourMock } }
			game:draw()
			assert.stub(behaviourMock.handleEvent).was_called()
			assert.stub(drawBehaviourMock.handleEvent).was_called()
			assert.stub(behaviourMock.handleEvent).was_called_with(match.is_ref(behaviourMock), "draw")
			assert.stub(drawBehaviourMock.handleEvent).was_called_with(match.is_ref(drawBehaviourMock), "draw")
		end)

		it("should not raise the draw event for non-draw subscribers", function()
			game.subscriptions["otherEvent"] = { ["entity_id"] = { behaviourMock } }
			game:draw()
			assert.stub(behaviourMock.handleEvent).was_not_called()
		end)

		it("shold not raise the draw event for destroyed entities", function()
			game.subscriptions["draw"] = { ["entity_id"] = { drawBehaviourMock } }
			stub(entityMock, "isDestroyed").returns(true)
			game:draw()
			assert.stub(drawBehaviourMock.handleEvent).was_not_called()
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
end)

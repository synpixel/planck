--!nonstrict
local RunService = game:GetService("RunService")

local JestGlobals = require("@DevPackages/JestGlobals")

local Planck = require("@Project")

local Phase = Planck.Phase
local Pipeline = Planck.Pipeline
local Scheduler = Planck.Scheduler

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local test = JestGlobals.test

describe("scheduler", function()
	describe("insert", function()
		test("phase", function()
			local myPhase = Phase.new("myPhase")
			local myScheduler = Scheduler.new():insert(myPhase)

			local mainIndex =
				table.find(myScheduler._orderedPhases, Phase.Update)

			expect(myScheduler._orderedPhases[mainIndex - 1]).toBe(myPhase)
			expect(myScheduler._phaseToSystems[myPhase]).toBeTruthy()
		end)

		test("phase with event", function()
			local myPhase = Phase.new("myPhase")

			local myScheduler = Scheduler.new()
				:insert(myPhase, RunService, "Heartbeat")

			local mainIndex =
				table.find(myScheduler._orderedPhases, Phase.Update)

			expect(myScheduler._orderedPhases[mainIndex - 1]).toBe(myPhase)
			expect(myScheduler._phaseToSystems[myPhase]).toBeTruthy()

			local identifier = `{RunService}@Heartbeat`
			local phases = myScheduler._eventToPhases[identifier]

			expect(phases).toBeTruthy()
			expect(phases).toContain(myPhase)
			expect(myScheduler._connectedEvents[identifier]).toBeTruthy()
		end)

		test("pipeline", function()
			local myPhase = Phase.new()
			local otherPhase = Phase.new()

			local myPipeline =
				Pipeline.new("myPipeline"):insert(myPhase):insert(otherPhase)

			local myScheduler = Scheduler.new():insert(myPipeline)

			local mainIndex =
				table.find(myScheduler._orderedPhases, Phase.Update)

			expect(myScheduler._orderedPhases[mainIndex - 2]).toBe(myPhase)
			expect(myScheduler._orderedPhases[mainIndex - 1]).toBe(otherPhase)
			expect(myScheduler._phaseToSystems[myPhase]).toBeTruthy()
			expect(myScheduler._phaseToSystems[otherPhase]).toBeTruthy()
		end)

		test("pipeline with event", function()
			local myPhase = Phase.new()
			local otherPhase = Phase.new()

			local myPipeline =
				Pipeline.new("myPipeline"):insert(myPhase):insert(otherPhase)

			local myScheduler = Scheduler.new()
				:insert(myPipeline, RunService, "Heartbeat")

			local mainIndex =
				table.find(myScheduler._orderedPhases, Phase.Update)

			expect(myScheduler._orderedPhases[mainIndex - 2]).toBe(myPhase)
			expect(myScheduler._orderedPhases[mainIndex - 1]).toBe(otherPhase)
			expect(myScheduler._phaseToSystems[myPhase]).toBeTruthy()
			expect(myScheduler._phaseToSystems[otherPhase]).toBeTruthy()

			local identifier = `{RunService}@Heartbeat`
			local phases = myScheduler._eventToPhases[identifier]

			expect(phases).toBeTruthy()
			expect(phases).toContain(myPhase)
			expect(phases).toContain(otherPhase)
			expect(myScheduler._connectedEvents[identifier]).toBeTruthy()
		end)
	end)

	describe("insertAfter", function()
		test("phase", function()
			local phaseOne = Phase.new("phaseOne")
			local phaseTwo = Phase.new("phaseTwo")
			local phaseThree = Phase.new("phaseThree")

			local myScheduler = Scheduler.new()
				:insert(phaseOne)
				:insert(phaseThree)
				:insertAfter(phaseTwo, phaseOne)

			local mainIndex =
				table.find(myScheduler._orderedPhases, Phase.Update)

			expect(myScheduler._orderedPhases[mainIndex - 3]).toBe(phaseOne)
			expect(myScheduler._orderedPhases[mainIndex - 2]).toBe(phaseTwo)
			expect(myScheduler._orderedPhases[mainIndex - 1]).toBe(phaseThree)

			expect(myScheduler._phaseToSystems[phaseOne]).toBeTruthy()
			expect(myScheduler._phaseToSystems[phaseTwo]).toBeTruthy()
			expect(myScheduler._phaseToSystems[phaseThree]).toBeTruthy()
		end)

		test("pipeline", function()
			local phaseOne = Phase.new("phaseOne")
			local phaseTwo = Phase.new("phaseTwo")
			local phaseThree = Phase.new("phaseThree")
			local phaseFour = Phase.new("phaseFour")

			local pipelineOne = Pipeline.new():insert(phaseOne):insert(phaseTwo)
			local pipelineTwo = Pipeline.new():insert(phaseFour)
			local pipelineThree = Pipeline.new():insert(phaseThree)

			local myScheduler = Scheduler.new()
				:insert(pipelineOne)
				:insert(pipelineTwo)
				:insertAfter(pipelineThree, pipelineOne)

			local mainIndex =
				table.find(myScheduler._orderedPhases, Phase.Update)
			expect(myScheduler._orderedPhases[mainIndex - 4]).toBe(phaseOne)
			expect(myScheduler._orderedPhases[mainIndex - 3]).toBe(phaseTwo)
			expect(myScheduler._orderedPhases[mainIndex - 2]).toBe(phaseThree)
			expect(myScheduler._orderedPhases[mainIndex - 1]).toBe(phaseFour)

			expect(myScheduler._phaseToSystems[phaseOne]).toBeTruthy()
			expect(myScheduler._phaseToSystems[phaseTwo]).toBeTruthy()
			expect(myScheduler._phaseToSystems[phaseThree]).toBeTruthy()
			expect(myScheduler._phaseToSystems[phaseFour]).toBeTruthy()
		end)
	end)

	test("phase run condition", function()
		expect.assertions(1)

		local bool = true

		local system = function(...)
			expect({ ... }).toEqual({ 1, 2, 3 })
		end

		local myPhase = Phase.new("myPhase")
		local myScheduler = Scheduler.new(1, 2, 3)
			:insert(myPhase)
			:addSystem(system, myPhase)
			:setRunCondition(myPhase, function()
				return bool
			end)

		myScheduler:runAll()

		bool = false
		myScheduler:runAll() -- Expect system to not run
	end)

	test("pipeline run condition", function()
		expect.assertions(1)

		local bool = true

		local system = function(...)
			expect({ ... }).toEqual({ 1, 2, 3 })
		end

		local myPhase = Phase.new("myPhase")

		local myPipeline = Pipeline.new():insert(myPhase)

		local myScheduler = Scheduler.new(1, 2, 3)
			:insert(myPipeline)
			:addSystem(system, myPhase)
			:setRunCondition(myPipeline, function()
				return bool
			end)

		myScheduler:run(myPipeline)

		bool = false
		myScheduler:run(myPipeline) -- Expect system to not run
	end)

	describe("startup systems", function()
		test("should run once", function()
			expect.assertions(1)

			local myScheduler = Scheduler.new(1, 2, 3):addSystem(function(...)
				expect({ ... }).toEqual({ 1, 2, 3 })
			end, Phase.Startup)

			myScheduler:runAll()
			myScheduler:runAll()
		end)
	end)
end)

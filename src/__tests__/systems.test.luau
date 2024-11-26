local JestGlobals = require("@DevPackages/JestGlobals")

local Planck = require("@Project")

local Phase = Planck.Phase
local Scheduler = Planck.Scheduler

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local test = JestGlobals.test

describe("systems", function()
	test("add", function()
		expect.assertions(1)

		local myPhase = Phase.new("myPhase")
		local myScheduler = Scheduler.new(1, 2, 3)
			:insert(myPhase)
			:addSystems(function(...)
				expect({ ... }).toEqual({ 1, 2, 3 })
			end, myPhase)

		myScheduler:runAll()
	end)

	test("edit", function()
		expect.assertions(2)

		local function systemA(...)
			expect({ ... }).toEqual({ 1, 2, 3 })
		end

		local myPhase = Phase.new("myPhase")
		local myScheduler =
			Scheduler.new(1, 2, 3):insert(myPhase):addSystems(systemA, myPhase)

		myScheduler:runAll()

		local otherPhase = Phase.new()
		myScheduler:insert(otherPhase)

		myScheduler:editSystem(systemA, otherPhase)
		myScheduler:run(otherPhase)

		-- Expect nothing to run here
		myScheduler:run(myPhase)
	end)

	test("remove", function()
		expect.assertions(1)

		local function systemA(...)
			expect({ ... }).toEqual({ 1, 2, 3 })
		end

		local myPhase = Phase.new("myPhase")
		local myScheduler =
			Scheduler.new(1, 2, 3):insert(myPhase):addSystems(systemA, myPhase)

		myScheduler:runAll()

		myScheduler:removeSystem(systemA)
		myScheduler:runAll() -- Expect nothing here
	end)

	test("replace", function()
		expect.assertions(3)

		local function systemA(...)
			expect({ ... }).toEqual({ 1, 2, 3 })
		end

		local function systemB(...)
			-- FUTURE: Use Jest.spyOn
			expect(true).toBe(true)
			expect({ ... }).toEqual({ 1, 2, 3 })
		end

		local myPhase = Phase.new("myPhase")
		local myScheduler =
			Scheduler.new(1, 2, 3):insert(myPhase):addSystems(systemA, myPhase)

		myScheduler:runAll()

		myScheduler:replaceSystem(systemA, systemB)
		myScheduler:runAll()
	end)

	test("system table", function()
		expect.assertions(1)

		local myPhase = Phase.new("myPhase")

		local system = {
			system = function(...)
				expect({ ... }).toEqual({ 1, 2, 3 })
			end,
			phase = myPhase,
		}

		local myScheduler =
			Scheduler.new(1, 2, 3):insert(myPhase):addSystems(system)

		myScheduler:run(myPhase)
	end)

	test("run condition", function()
		expect.assertions(1)

		local bool = true

		local system = function(...)
			expect({ ... }).toEqual({ 1, 2, 3 })
		end

		local myPhase = Phase.new("myPhase")
		local myScheduler = Scheduler.new(1, 2, 3)
			:insert(myPhase)
			:addSystems(system, myPhase)
			:setRunCondition(system, function()
				return bool
			end)

		myScheduler:runAll()

		bool = false
		myScheduler:runAll() -- Expect system to not run
	end)
end)

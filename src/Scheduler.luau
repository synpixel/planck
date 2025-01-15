local RunService = game:GetService("RunService")

local Pipeline = require("@Project/Pipeline")
local Phase = require("@Project/Phase")

local utils = require("@Project/utils")
local hooks = require("@Project/hooks")

local getSystem = utils.getSystem
local getSystemName = utils.getSystemName

local isPhase = utils.isPhase
local isPipeline = utils.isPipeline

local isValidEvent = utils.isValidEvent
local getEventIdentifier = utils.getEventIdentifier

-- Recent errors in Planks itself
local recentLogs = {}
local timeLastLogged = os.clock()

--- @type SystemFn ((U...) -> any)
--- @within Scheduler

--- @interface SystemTable
--- @within Scheduler
--- .system SystemFn<U...>
--- .phase Phase?
--- .[any] any

--- @type System SystemFn<U...> | SystemTable<U...>
--- @within Scheduler

--- @class Scheduler
---
--- An Object which handles scheduling Systems to run within different
--- Phases. The order of which Systems run will be defined either
--- implicitly by when it was added, or explicitly by tagging the system
--- with a Phase.
local Scheduler = {}
Scheduler.__index = Scheduler

Scheduler.Hooks = hooks.Hooks

--- @method addPlugin
--- @within Scheduler
--- @param plugin PlanckPlugin
---
--- Initializes a plugin with the scheduler, see the [Plugin Docs](/docs/plugins) for more information.
function Scheduler:addPlugin(plugin)
	plugin:build(self)
	return self
end

function Scheduler:_addHook(hook, fn)
	assert(self._hooks[hook], `Unknown Hook: {hook}`)
	table.insert(self._hooks[hook], fn)
end

--- @method getDeltaTime
--- @within Scheduler
--- @return number
---
--- Returns the time since the system was ran last.
--- This must be used within a registered system.
function Scheduler:getDeltaTime()
	local systemFn = debug.info(2, "f")
	if not systemFn or not self._systemInfo[systemFn] then
		error(
			"Scheduler:getDeltaTime() must be used within a registered system"
		)
	end

	return self._systemInfo[systemFn].deltaTime or 0
end

-- Inspiration from https://github.com/matter-ecs/matter <3
function Scheduler:_handleLogs(systemInfo)
	if not systemInfo.timeLastLogged then
		systemInfo.timeLastLogged = os.clock()
	end

	if not systemInfo.recentLogs then
		systemInfo.recentLogs = {}
	end

	if os.clock() - systemInfo.timeLastLogged > 10 then
		systemInfo.timeLastLogged = os.clock()
		systemInfo.recentLogs = {}
	end

	local name = debug.info(systemInfo.system, "n")

	for _, logMessage in systemInfo.logs do
		if not systemInfo.recentLogs[logMessage] then
			task.spawn(error, logMessage, 0)
			warn(
				`Planck: Error occurred in system{string.len(name) > 0 and ` '{name}'` or ""}, this error will be ignored for 10 seconds`
			)
			systemInfo.recentLogs[logMessage] = true
		end
	end

	table.clear(systemInfo.logs)
end

function Scheduler:runSystem(system)
	local runIf = self._runIfConditions[system]
	if runIf and runIf(table.unpack(self._vargs)) == false then
		return
	end

	local systemInfo = self._systemInfo[system]
	local now = os.clock()

	systemInfo.deltaTime = now - (systemInfo.lastTime or now)
	systemInfo.lastTime = now

	if not self._thread then
		self._thread = coroutine.create(function()
			while true do
				local fn = coroutine.yield()
				self._yielded = true
				fn()
				self._yielded = false
			end
		end)

		coroutine.resume(self._thread)
	end

	local didYield = false

	local function systemCall()
		local function noYield()
			local success, err = coroutine.resume(self._thread, function()
				system(table.unpack(self._vargs))
			end)

			if not success then
				didYield = true
				table.insert(systemInfo.logs, err)
				hooks.systemError(self, systemInfo, err)
				return
			end

			if self._yielded then
				didYield = true
				local trace, line = debug.info(systemInfo.system, "sl")
				table.insert(systemInfo.logs, `{trace}:{line}: System yielded`)
				hooks.systemError(
					self,
					systemInfo,
					`{trace}:{line}: System yielded`
				)
			end
		end

		hooks.systemCall(self, "SystemCall", systemInfo, noYield)
	end

	local function inner()
		hooks.systemCall(self, "InnerSystemCall", systemInfo, systemCall)
	end

	local function outer()
		hooks.systemCall(self, "OuterSystemCall", systemInfo, inner)
	end

	if os.clock() - timeLastLogged > 10 then
		timeLastLogged = os.clock()
		recentLogs = {}
	end

	local success, err: string? = pcall(outer)
	if not success and not recentLogs[err] then
		task.spawn(error, err, 0)
		warn(
			`Planck: Error occurred while running hooks, this error will be ignored for 10 seconds`
		)
		hooks.systemError(
			self,
			systemInfo,
			`Error occurred while running hooks: {err}`
		)
		recentLogs[err] = true
	end

	if didYield then
		coroutine.close(self._thread)

		self._thread = coroutine.create(function()
			while true do
				local fn = coroutine.yield()
				self._yielded = true
				fn()
				self._yielded = false
			end
		end)

		coroutine.resume(self._thread)
	end

	self:_handleLogs(systemInfo)
end

function Scheduler:runPhase(phase)
	local runIf = self._runIfConditions[phase]
	if runIf and runIf(table.unpack(self._vargs)) == false then
		return
	end

	hooks.phaseBegan(self, phase)

	for _, system in self._phaseToSystems[phase] do
		self:runSystem(system)
	end
end

function Scheduler:runPipeline(pipeline)
	local runIf = self._runIfConditions[pipeline]
	if runIf and runIf(table.unpack(self._vargs)) == false then
		return
	end

	for _, phase in pipeline._phases do
		self:runPhase(phase)
	end
end

--- @method run
--- @within Scheduler
--- @param phase Phase
--- @return Scheduler
---
--- Runs all Systems tagged with the Phase in order.

--- @method run
--- @within Scheduler
--- @param pipeline Pipeline
--- @return Scheduler
---
--- Runs all Systems tagged with any Phase within the Pipeline in order.

--- @method run
--- @within Scheduler
--- @param system System
--- @return Scheduler
---
--- Runs the System, passing in the arguments of the Scheduler, `U...`.

function Scheduler:run(dependent)
	if not dependent then
		error("No dependent specified in Scheduler:run(_)")
	end

	self:runPipeline(Pipeline.Startup)

	if getSystem(dependent) then
		self:runSystem(dependent)
	elseif isPhase(dependent) then
		self:runPhase(dependent)
	elseif isPipeline(dependent) then
		self:runPipeline(dependent)
	else
		error("Unknown dependent passed into Scheduler:run(unknown)")
	end

	return self
end

--- @method runAll
--- @within Scheduler
--- @return Scheduler
---
--- Runs all Systems within order.
function Scheduler:runAll()
	for _, phase in self._orderedPhases do
		self:run(phase)
	end
end

function Scheduler:_insertPhaseAt(phase, index, instance, event)
	assert(
		not table.find(self._orderedPhases, phase),
		"Phase already initialized"
	)

	table.insert(self._orderedPhases, index, phase)
	self._phaseToSystems[phase] = {}

	hooks.phaseAdd(self, phase)

	if isValidEvent(instance, event) then
		self:_schedulePhase(phase, instance, event)
	end
end

function Scheduler:insertPhase(phase, instance, event)
	local index = table.find(self._orderedPhases, Phase.Update)
	self:_insertPhaseAt(phase, index, instance, event)
end

function Scheduler:insertPipeline(pipeline, instance, event)
	for _, phase in pipeline._phases do
		self:insertPhase(phase, instance, event)
	end
end

--- @method insert
--- @within Scheduler
--- @param phase Phase
--- @return Scheduler
---
--- Initializes the Phase within the Scheduler, ordering it implicitly.

--- @method insert
--- @within Scheduler
--- @param pipeline Pipeline
--- @return Scheduler
---
--- Initializes all Phases within the Pipeline within the Scheduler,
--- ordering the Pipeline implicitly.

--- @method insert
--- @within Scheduler
--- @param phase Phase
--- @param instance Instance | EventLike
--- @param event string | EventLike
--- @return Scheduler
---
--- Initializes the Phase within the Scheduler, ordering it implicitly
--- and scheduling it to be ran on the specified event.
---
--- ```lua
--- local myScheduler = Scheduler.new()
---     :insert(myPhase, RunService, "Heartbeat")
--- ```

--- @method insert
--- @within Scheduler
--- @param pipeline Pipeline
--- @param instance Instance | EventLike
--- @param event string | EventLike
--- @return Scheduler
---
--- Initializes all Phases within the Pipeline within the Scheduler,
--- ordering the Pipeline implicitly and scheduling it to be ran on
--- the specified event.
---
--- ```lua
--- local myScheduler = Scheduler.new()
---     :insert(myPipeline, RunService, "Heartbeat")
--- ```

function Scheduler:insert(dependent, instance, event)
	if isPhase(dependent) then
		self:insertPhase(dependent, instance, event)
	elseif isPipeline(dependent) then
		self:insertPipeline(dependent, instance, event)
	else
		error("Unknown dependent passed to Scheduler:insert(unknown, _, _)")
	end

	return self
end

--- @method insertAfter
--- @within Scheduler
--- @param phase Phase
--- @param after Phase | Pipeline
--- @return Scheduler
---
--- Initializes the Phase within the Scheduler, ordering it
--- explicitly after the Phase, or adding to the end of the
--- Pipeline provided.

--- @method insertAfter
--- @within Scheduler
--- @param pipeline Pipeline
--- @param after Phase | Pipeline
--- @return Scheduler
---
--- Initializes all Phases within the Pipeline within the Scheduler,
--- ordering the Pipeline explicitly after the Phase, or adding
--- to the end of the Pipeline provided.

function Scheduler:insertAfter(dependent, after)
	if isPhase(after) then
		local index = table.find(self._orderedPhases, after)
		assert(
			index,
			"Phase never initialized in Scheduler:insertAfter(_, phase)"
		)

		if isPhase(dependent) then
			self:_insertPhaseAt(dependent, index + 1)
		elseif isPipeline(dependent) then
			for _, phase in dependent._phases do
				index += 1
				self:_insertPhaseAt(phase, index)
			end
		else
			error(
				"Unknown dependent passed in Scheduler:insertAfter(unknown, _)"
			)
		end
	elseif isPipeline(after) then
		local before = after._phases[#after._phases]

		if isPhase(dependent) then
			after:insert(dependent)
		end

		self:insertAfter(dependent, before)
	else
		error("Unknown dependency passed in Scheduler:insertAfter(_, unknown)")
	end

	return self
end

--- @method addSystems
--- @within Scheduler
--- @param systems System
--- @param phase Phase?
---
--- Adds the System to the Scheduler, scheduling it to be ran
--- implicitly within the provided Phase or on the default Main phase.
function Scheduler:addSystem(system, phase)
	local systemFn = getSystem(system)

	if not systemFn then
		error("Unknown system passed to Scheduler:addSystem(unknown, phase?)")
	end

	local name = getSystemName(systemFn)
	if type(system) == "table" and system.name then
		name = system.name
	end

	local systemInfo = {
		system = systemFn,
		phase = phase,
		name = name,
		logs = {},
	}

	if not phase then
		if type(system) == "table" and system.phase then
			systemInfo.phase = system.phase
		else
			systemInfo.phase = Phase.Update
		end
	end

	self._systemInfo[systemFn] = systemInfo
	table.insert(self._phaseToSystems[systemInfo.phase], systemFn)

	hooks.systemAdd(self, systemInfo)

	if type(system) == "table" and system.runCondition then
		self:setRunCondition(systemFn, system.runCondition)
	end

	return self
end

--- @method addSystems
--- @within Scheduler
--- @param systems { System }
--- @param phase Phase?
---
--- Adds the Systems to the Scheduler, scheduling them to be ran
--- implicitly within the provided Phase or on the default Main phase.
function Scheduler:addSystems(systems, phase)
	if type(systems) ~= "table" then
		error("Unknown systems passed to Scheduler:addSystems(unknown, phase?)")
	end

	local foundSystem = false

	for _, system in systems do
		if getSystem(system) then
			foundSystem = true
			self:addSystem(system, phase)
		end
	end

	if not foundSystem then
		error(
			"Unknown table passed to Scheduler:addSystems({ unknown }, phase?)"
		)
	end
end

--- @method editSystem
--- @within Scheduler
--- @param system System
--- @param newPhase Phase
---
--- Changes the Phase that this system is scheduled on.
function Scheduler:editSystem(system, newPhase)
	local systemFn = getSystem(system)
	local systemInfo = self._systemInfo[systemFn]
	assert(
		systemInfo,
		"Attempt to remove a non-exist system in Scheduler:removeSystem(_)"
	)

	assert(
		newPhase and self._phaseToSystems[newPhase] ~= nil or true,
		"Phase never initialized before using Scheduler:editSystem(_, Phase)"
	)

	local systems = self._phaseToSystems[systemInfo.phase]

	local index = table.find(systems, systemFn)
	assert(index, "Unable to find system within phase")

	table.remove(systems, index)
	table.insert(self._phaseToSystems[newPhase], systemFn)

	systemInfo.phase = newPhase
	return self
end

--- @method removeSystem
--- @within Scheduler
--- @param system System
---
--- Removes the System from the Scheduler.
function Scheduler:removeSystem(system)
	local systemFn = getSystem(system)
	local systemInfo = self._systemInfo[systemFn]
	assert(
		systemInfo,
		"Attempt to remove a non-exist system in Scheduler:removeSystem(_)"
	)

	local systems = self._phaseToSystems[systemInfo.phase]

	local index = table.find(systems, systemFn)
	assert(index, "Unable to find system within phase")

	table.remove(systems, index)
	self._systemInfo[systemFn] = nil

	hooks.systemRemove(self, systemInfo)

	return self
end

--- @method replaceSystem
--- @within Scheduler
--- @param old System
--- @param new System
---
--- Replaces the System with a new System.
function Scheduler:replaceSystem(old, new)
	local oldSystemFn = getSystem(old)
	local oldSystemInfo = self._systemInfo[oldSystemFn]
	assert(
		oldSystemInfo,
		"Attempt to replace a non-existent system in Scheduler:replaceSystem(unknown, _)"
	)

	local newSystemFn = getSystem(new)
	assert(
		newSystemFn,
		"Attempt to pass non-system in Scheduler:replaceSystem(_, unknown)"
	)

	local systems = self._phaseToSystems[oldSystemInfo.phase]

	local index = table.find(systems, oldSystemFn)
	assert(index, "Unable to find system within phase")

	table.remove(systems, index)
	table.insert(systems, index, newSystemFn)

	local copy = table.clone(oldSystemInfo)

	oldSystemInfo.system = newSystemFn
	oldSystemInfo.name = getSystemName(newSystemFn)

	hooks.systemReplace(self, copy, oldSystemInfo)

	self._systemInfo[newSystemFn] = self._systemInfo[oldSystemFn]
	self._systemInfo[oldSystemFn] = nil

	return self
end

--- @method setRunCondition
--- @within Scheduler
--- @param system System
--- @param fn (U...) -> boolean
---
--- Adds a Run Condition which the Scheduler will check before
--- this System is ran.

--- @method setRunCondition
--- @within Scheduler
--- @param phase Phase
--- @param fn (U...) -> boolean
---
--- Adds a Run Condition which the Scheduler will check before
--- any Systems tagged with this Phase are ran.

--- @method setRunCondition
--- @within Scheduler
--- @param pipeline Pipeline
--- @param fn (U...) -> boolean
---
--- Adds a Run Condition which the Scheduler will check before
--- any Systems within any Phases apart of this Pipeline are ran.\
--- \
--- This Run Condition will be applied to the Phases themselves.

function Scheduler:setRunCondition(dependent, fn)
	local system = getSystem(dependent)
	if system then
		dependent = system
	end

	assert(
		system or isPhase(dependent) or isPipeline(dependent),
		"Attempt to pass unknown dependent into Scheduler:setRunCondition(unknown, _)"
	)

	self._runIfConditions[dependent] = fn
	return self
end

function Scheduler:_addBuiltins()
	local i = 0

	for _, phase in Pipeline.Startup._phases do
		i += 1
		self:_insertPhaseAt(phase, i)
	end

	for _, phase in Pipeline.Main._phases do
		i += 1
		self:_insertPhaseAt(phase, i, RunService, "Heartbeat")
	end

	local runServiceEvents = {
		"PreRender",
		"PreAnimation",
		"PreSimulation",
		"PostSimulation",
	}

	for _, event in runServiceEvents do
		i += 1
		self:_insertPhaseAt(Phase[event], i, RunService, event)
	end

	local startupHasRan = {}

	for _, phase in Pipeline.Startup._phases do
		self:setRunCondition(phase, function()
			local hasRan = startupHasRan[phase]

			if not hasRan then
				startupHasRan[phase] = true
			end

			return not hasRan
		end)
	end
end

local EVENT_CONNECT_METHODS = { "Connect", "On", "on", "connect" }

-- This is a modified function from Matter by evaera (https://github.com/evaera)
-- License: Copyright (c) 2021 Eryn L. K., MIT License
-- Source: https://github.com/matter-ecs/matter/blob/main/lib/hooks/useEvent.luau
function Scheduler:_scheduleEvent(instance, event)
	local identifier = getEventIdentifier(instance, event)

	local callback = function()
		for _, phase in self._eventToPhases[identifier] do
			self:run(phase)
		end
	end

	local eventInstance = instance

	if typeof(event) == "RBXScriptSignal" or type(event) == "table" then
		eventInstance = event
	elseif type(event) == "string" then
		eventInstance = instance[event]
	end

	if type(eventInstance) == "function" then
		self._connectedEvents[identifier] = eventInstance

		return eventInstance(eventInstance, callback)
	elseif typeof(eventInstance) == "RBXScriptSignal" then
		self._connectedEvents[identifier] = eventInstance

		return eventInstance:Connect(callback)
	end

	if type(eventInstance) == "table" then
		for _, method in EVENT_CONNECT_METHODS do
			if type(eventInstance[method]) ~= "function" then
				continue
			end

			self._connectedEvents[identifier] = eventInstance
			return eventInstance[method](eventInstance, callback)
		end
	end

	error(
		"Couldn't connect to event as no valid connect methods were found! Ensure the passed event has a 'Connect' or an 'on' method!"
	)
end

function Scheduler:_schedulePhase(phase, instance, event)
	local identifier = getEventIdentifier(instance, event)

	if not self._eventToPhases[identifier] then
		self._eventToPhases[identifier] = {}
	end

	table.insert(self._eventToPhases[identifier], phase)
	if not self._connectedEvents[identifier] then
		self:_scheduleEvent(instance, event)
	end
end

--- @function new
--- @within Scheduler
--- @param args U...
---
--- Creates a new Scheduler, the args passed will be passed to
--- any System anytime it is ran by the Scheduler.
function Scheduler.new(...)
	local self = {}

	self._hooks = {}

	self._vargs = { ... }

	self._orderedPhases = {}
	self._orderedPipelines = {}

	self._eventToPhases = {}
	self._connectedEvents = {}

	self._phaseToSystems = {}
	self._systemInfo = {}

	self._runIfConditions = {}

	setmetatable(self, Scheduler)

	for _, hookName in hooks.Hooks do
		if not self._hooks[hookName] then
			self._hooks[hookName] = {}
		end
	end

	self:_addBuiltins()

	return self
end

return Scheduler

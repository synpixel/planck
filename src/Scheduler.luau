--!nonstrict
local RunService = game:GetService("RunService")

local function getEventIdentifier(instance, event)
	return `{instance}{event and `@{event}` or ""}`
end

--- @type SystemFn ((U...) -> any)
--- @within Scheduler

--- @interface SystemTable
--- @within Scheduler
--- .system SystemFn<U...>
--- .phase Phase?
--- .[any] any

--- @type System SystemFn<U...> | SystemTable<U...>
--- @within Scheduler

--- @class Phase
---
--- Phases represent tags that tell the scheduler when to
--- schedule a set of systems.
local Phase = {}
Phase.__index = Phase

function Phase:__tostring()
	return self._name
end

--- @within Phase
---
--- Creates a new Phase, with an optional name to use for debugging.
--- When no name is provided, the script and line number will be used.
function Phase.new(name: string?)
	name = name or debug.info(2, "sl")
	return setmetatable({
		_name = name,
		_type = "phase",
	}, Phase)
end

--- @prop PreStartup Phase
--- @within Phase
--- Runs before the `Startup` Phase.

--- @prop Startup Phase
--- @within Phase
--- This Phase will run once, the first time the Scheduler is ran,
--- before any other Phases are ran.

--- @prop PostStartup Phase
--- @within Phase
--- Runs after the `Startup` phase.

Phase.PreStartup = Phase.new("PreStartup")
Phase.Startup = Phase.new("Startup")
Phase.PostStartup = Phase.new("PostStartup")

--- @prop PreRender Phase
--- @within Phase
--- Runs on the `RunService.PreRender` Event.

--- @prop PreAnimation Phase
--- @within Phase
--- Runs on the `RunService.PreAnimation` Event.

--- @prop PreSimulation Phase
--- @within Phase
--- Runs on the `RunService.PreSimulation` Event.

--- @prop PostSimulation Phase
--- @within Phase
--- Runs on the `RunService.PostSimulation` Event.

Phase.PreRender = Phase.new("PreRender")
Phase.PreAnimation = Phase.new("PreAnimation")
Phase.PreSimulation = Phase.new("PreSimulation")
Phase.PostSimulation = Phase.new("PostSimulation")

--- @prop First Phase
--- @within Phase
--- Will always run first on the `RunService.Heartbeat` Event.

--- @prop PreUpdate Phase
--- @within Phase
--- Runs before the `Update` Phase.

--- @prop Update Phase
--- @within Phase
--- Runs on the `RunService.Heartbeat` Event.
--- This is the default Phase systems will run on.

--- @prop PostUpdate Phase
--- @within Phase
--- Runs after the `Update` Phase.

--- @prop Last Phase
--- @within Phase
--- Will always run last on the `RunService.Heartbeat` Event.

Phase.First = Phase.new("First")
Phase.PreUpdate = Phase.new("PreUpdate")
Phase.Update = Phase.new("Update")
Phase.PostUpdate = Phase.new("PostUpdate")
Phase.Last = Phase.new("Last")

--- @class Pipeline
---
--- Pipelines represent a set of ordered Phases. Systems cannot be
--- assigned to Pipelines themselves, but rather to Phases within
--- those Pipelines.
local Pipeline = {}
Pipeline.__index = Pipeline

function Pipeline:__tostring()
	return self._name
end

--- @method insert
--- @within Pipeline
--- @param phase Phase
--- @return Pipeline
---
--- Adds a Phase to the Pipeline, ordering it implicitly.
function Pipeline:insert(phase)
	table.insert(self._phases, phase)
	return self
end

--- @method insert
--- @within Pipeline
--- @param phase Phase
--- @param after Phase
--- @return Pipeline
---
--- Adds a Phase to the Pipeline after another Phase, ordering it explicitly.
function Pipeline:insertAfter(phase, otherPhase)
	local i = table.find(self._phases, phase)
	assert(i, "Phase not initialized in Pipeline")

	table.insert(self._phases, i + 1, otherPhase)
	return self
end

--- @within Pipeline
---
--- Creates a new Pipeline, with an optional name to use for debugging.
--- When no name is provided, the script and line number will be used.
function Pipeline.new(name: string?)
	name = name or debug.info(2, "sl")
	return setmetatable({
		_name = name,
		_type = "pipeline",
		_phases = {},
	}, Pipeline)
end

--- @prop Startup Pipeline
--- @within Pipeline
---
--- A Pipeline containing the `PreStartup`, `Startup`, and `PostStartup` phases.
Pipeline.Startup = Pipeline.new()
	:insert(Phase.PreStartup)
	:insert(Phase.Startup)
	:insert(Phase.PostStartup)

--- @prop Main Pipeline
--- @within Pipeline
---
--- A Pipeline containing the `First`, `PreUpdate`, `Update`, `PostUpdate`, and `Last` phases.
Pipeline.Main = Pipeline.new()
	:insert(Phase.First)
	:insert(Phase.PreUpdate)
	:insert(Phase.Update)
	:insert(Phase.PostUpdate)
	:insert(Phase.Last)

--- @class Scheduler
---
--- An Object which handles scheduling Systems to run within different
--- Phases. The order of which Systems run will be defined either
--- implicitly by when it was added, or explicitly by tagging the system
--- with a Phase.
local Scheduler = {}
Scheduler.__index = Scheduler

Scheduler.Hooks = {
	SystemAdd = "SystemAdd",
	SystemRemove = "SystemRemove",
	SystemEdit = "SystemEdit",
	SystemCallOuter = "SystemCallOuter",
	SystemCallInner = "SystemCallInner",
	SystemCall = "SystemCall",

	PhaseBegan = "PhaseBegan",
}

type SystemCall = {
	scheduler: nil,
	system: {
		name: string,
		fn: (any) -> any,
	},
	nextFn: ((any) -> any)?,
}

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
	table.insert(self._hooks[hook], fn)
end

local function handleRunHooks(scheduler, hookName, system, call)
	local hooks = scheduler._hooks[scheduler.Hooks[hookName]]
	if hooks then
		for _, hook in hooks do
			call = hook({
				scheduler = nil,
				system = {
					name = "",
					fn = system,
					phase = scheduler._systemToPhase[system],
				},
				nextFn = call,
			})
		end
	end

	call()
end

function Scheduler:runSystem(system)
	local runIf = self._runIfConditions[system]
	if runIf and not runIf(table.unpack(self._vargs)) then
		return
	end

	local function systemCall()
		local final = function()
			local success, err = pcall(system, table.unpack(self._vargs))
			if not success then
				warn(`Error occurred when running system: {err}`)
			end
		end

		handleRunHooks(self, "SystemCall", system, final)
	end

	local function inner()
		handleRunHooks(self, "SystemCallInner", system, systemCall)
	end

	local success, err =
		pcall(handleRunHooks, self, "SystemCallOuter", system, inner)

	if not success then
		warn(`Error occurred when running hooks: {err}`)
	end
end

function Scheduler:runPhase(phase)
	local runIf = self._runIfConditions[phase]
	if runIf and not runIf(table.unpack(self._vargs)) then
		return
	end

	local hooks = self._hooks[self.Hooks.PhaseBegan]
	local info = {
		scheduler = self,
		phase = phase,
	}

	for _, hook in hooks do
		local success, err = pcall(hook, info)
		if not success then
			warn("Unexpected error in hook:", err)
		end
	end

	for _, system in self._phaseToSystems[phase] do
		self:runSystem(system)
	end
end

function Scheduler:runPipeline(pipeline)
	local runIf = self._runIfConditions[pipeline]
	if runIf and not runIf(table.unpack(self._vargs)) then
		return
	end

	for _, phase in pipeline._phases do
		self:runPhase(phase)
	end
end

function Scheduler:_handleStartup()
	if not self._startupFinished then
		self:runPipeline(Pipeline.Startup)

		for _, phase in Pipeline.Startup._phases do
			local index = table.find(self._phases, phase)
			table.remove(self._phases, index)
		end

		self._startupFinished = true
	end
end

--- @method runAll
--- @within Scheduler
--- @return Scheduler
---
--- Runs all Systems within order.
function Scheduler:runAll()
	self:_handleStartup()
	self:runPipeline(self)
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

	self:_handleStartup()

	if typeof(dependent) == "function" then
		self:runSystem(dependent)
	elseif typeof(dependent) == "table" then
		if dependent.system then
			self:runSystem(dependent.system)
		elseif not dependent._type then
			error("Unknown dependent passed to Scheduler:run(unknown)")
		end

		if dependent._type == "phase" then
			self:runPhase(dependent)
		elseif dependent._type == "pipeline" then
			self:runPipeline(dependent)
		end
	end
end

local EVENT_CONNECT_METHODS = { "Connect", "on", "connect" }

-- This is a modified function from Matter by evaera (https://github.com/evaera)
-- License: Copyright (c) 2021 Eryn L. K., MIT License
-- Source: https://github.com/matter-ecs/matter/blob/main/lib/hooks/useEvent.luau
function Scheduler:_handleEvent(instance, event)
	local identifier = getEventIdentifier(instance, event)

	local callback = function()
		for _, phase in self._eventToPhases[identifier] do
			for _, system in self._phaseToSystems[phase] do
				self:runSystem(system)
			end
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

function Scheduler:_insertPhaseAt(phase, i, instance, event)
	if table.find(self._phases, phase) then
		error("Phase initialized more than once")
	end

	table.insert(self._phases, i, phase)

	if not self._phaseToSystems[phase] then
		self._phaseToSystems[phase] = {}
	end

	if instance then
		local validEvent = event and instance[event] or instance
		validEvent = typeof(validEvent) == "RBXScriptSignal"
			or (
				typeof(validEvent) == "table" and validEvent.Connect ~= nil
				or validEvent.connect ~= nil
			)

		local identifier = getEventIdentifier(instance, event)

		if not self._eventToPhases[identifier] then
			self._eventToPhases[identifier] = {}
		end

		table.insert(self._eventToPhases[identifier], phase)

		if not self._connectedEvents[identifier] then
			self:_handleEvent(instance, event)
		end
	end
end

function Scheduler:insertPhase(phase, instance, event)
	local mainIndex = table.find(self._phases, self._MAIN_PHASE)
	self:_insertPhaseAt(phase, mainIndex, instance, event)
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
	if typeof(dependent) == "table" then
		if not dependent._type then
			error("Unknown dependent passed to Scheduler:insert(unknown)")
		end

		if dependent._type == "phase" then
			self:insertPhase(dependent, instance, event)
		elseif dependent._type == "pipeline" then
			self:insertPipeline(dependent, instance, event)
		end
	else
		error("Unknown dependent passed to Scheduler:insert(unknown)")
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
--- explicitly after the Phase or Pipeline provided.

--- @method insertAfter
--- @within Scheduler
--- @param pipeline Pipeline
--- @param after Phase | Pipeline
--- @return Scheduler
---
--- Initializes all Phases within the Pipeline within the Scheduler,
--- ordering the Pipeline explicitly after the Phase or Pipeline provided.

function Scheduler:insertAfter(dependent, dependency)
	if typeof(dependency) == "table" then
		if not dependency._type then
			error(
				"Unknown dependency passed to Scheduler:insertAfter(_, unknown)"
			)
		end

		if dependency._type == "phase" then
			local i = table.find(self._phases, dependency)
			assert(i, "Dependency never initialized")

			if typeof(dependent) == "table" then
				if not dependent._type then
					error(
						"Unknown dependency passed to Scheduler:insertAfter(unknown, dependency)"
					)
				end

				if dependent._type == "phase" then
					self:_insertPhaseAt(dependent, i + 1)
				elseif dependent._type == "pipeline" then
					for _, phase in dependent._phases do
						i += 1
						self:_insertPhaseAt(phase, i)
					end
				end
			end
		elseif dependency._type == "pipeline" then
			self:insertAfter(dependent, dependency._phases[#dependency._phases])
		end
	end

	return self
end

function Scheduler:_addSystem(system, phase)
	table.insert(self._phaseToSystems[phase], system)
	self._systemToPhase[system] = phase

	local name = debug.info(system, "n")
	if not name or string.len(name) == 0 then
		name = debug.info(system, "sl")
	end

	self._systemNames[system] = name

	local hooks = self._hooks[self.Hooks.SystemAdd]
	local info = {
		scheduler = self,
		system = {
			name = name,
			phase = phase,
			fn = system,
		},
	}

	for _, hook in hooks do
		local success, err = pcall(hook, info)
		if not success then
			warn("Unexpected error in hook:", err)
		end
	end
end

--- @method addSystems
--- @within Scheduler
--- @param systems System | { System }
--- @param phase Phase?
---
--- Adds the System(s) to the Scheduler, scheduling them to be ran
--- implicitly within the provided Phase or on the default Main phase.
function Scheduler:addSystems(systems, phase)
	if not phase then
		phase = self._MAIN_PHASE
	end

	if not self._phaseToSystems[phase] then
		self._phaseToSystems[phase] = {}
	end

	if type(systems) == "table" then
		if systems.system then
			if systems.phase then
				phase = systems.phase
			end

			self:_addSystem(systems.system, phase)
		else
			for _, system in systems do
				if type(system) == "table" then
					if system.system then
						if system.phase then
							phase = systems.phase
						end

						self:_addSystem(system.system, phase)
					else
						error(
							"Unknown system passed to Scheduler:addSystems({ unknown }, phase)"
						)
					end
				elseif type(system) == "function" then
					self:_addSystem(system, phase)
				else
					error(
						"Unknown system passed to Scheduler:addSystems({ unknown }, phase)"
					)
				end
			end
		end
	elseif type(systems) == "function" then
		self:_addSystem(systems, phase)
	else
		error("Unknown system passed to Scheduler:addSystems(unknown, phase)")
	end

	return self
end

--- @method editSystem
--- @within Scheduler
--- @param system System
--- @param newPhase Phase
---
--- Changes the Phase that this system is scheduled on.
function Scheduler:editSystem(system, phase)
	if not self._phaseToSystems[phase] then
		error(
			"Phase never initialized before using Scheduler:editSystem(_, Phase)"
		)
	end

	for _, _phase in self._phases do
		local i = table.find(self._phaseToSystems[_phase], system)
		if i then
			table.remove(self._phaseToSystems[_phase], i)
			table.insert(self._phaseToSystems[phase], system)
			self._systemToPhase[system] = phase
		end
	end

	return self
end

--- @method removeSystem
--- @within Scheduler
--- @param system System
---
--- Removes the System from the Scheduler.
function Scheduler:removeSystem(system)
	local systemPhase = nil
	for _, phase in self._phases do
		local i = table.find(self._phaseToSystems[phase], system)
		if i then
			systemPhase = phase
			table.remove(self._phaseToSystems[phase], i)
			self._systemToPhase[system] = nil
		end
	end

	local hooks = self._hooks[self.Hooks.SystemRemove]
	local info = {
		scheduler = self,
		system = {
			name = self._systemNames[system],
			phase = systemPhase,
			fn = system,
		},
	}

	for _, hook in hooks do
		local success, err = pcall(hook, info)
		if not success then
			warn("Unexpected error in hook:", err)
		end
	end

	self._systemNames[system] = nil

	return self
end

--- @method replaceSystem
--- @within Scheduler
--- @param old System
--- @param new System
---
--- Replaces the System with a new System.
function Scheduler:replaceSystem(old, new)
	local systemPhase = nil

	for _, phase in self._phases do
		local i = table.find(self._phaseToSystems[phase], old)
		if i then
			systemPhase = phase
			table.remove(self._phaseToSystems[phase], i)
			table.insert(self._phaseToSystems[phase], i, new)
			self._systemToPhase[old] = nil
			self._systemToPhase[new] = phase
		end
	end

	local name = debug.info(new, "n")
	if not name or string.len(name) == 0 then
		name = debug.info(new, "sl")
	end

	self._systemNames[new] = name

	local hooks = self._hooks[self.Hooks.SystemAdd]
	local info = {
		scheduler = self,
		new = {
			name = name,
			phase = systemPhase,
			fn = new,
		},
		old = {
			name = self._systemNames[old],
			phase = systemPhase,
			fn = old,
		},
	}

	for _, hook in hooks do
		local success, err = pcall(hook, info)
		if not success then
			warn("Unexpected error in hook:", err)
		end
	end

	self._systemNames[old] = nil

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
	if type(dependent) == "table" and dependent.system then
		dependent = dependent.system
	elseif
		type(dependent) == "table"
		and dependent._type
		and dependent._type == "pipeline"
	then
		for _, phase in dependent._phases do
			self:setRunCondition(phase, fn)
		end
	end

	self._runIfConditions[dependent] = fn

	return self
end

--- @function new
--- @within Scheduler
--- @param args U...
---
--- Creates a new Scheduler, the args passed will be passed to
--- any System anytime it is ran by the Scheduler.
function Scheduler.new(...)
	local self = {}

	local Heartbeat = RunService.Heartbeat

	self._MAIN_PHASE = Phase.Update
	self._heartbeat = Heartbeat
	self._startupFinished = false
	self._vargs = table.pack(...)
	self._hooks = {}
	self._phases = {}
	self._phaseToSystems = {}
	self._systemToPhase = {}
	self._eventToPhases = {}
	self._runIfConditions = {}
	self._connectedEvents = {}
	self._systemNames = {}

	setmetatable(self, Scheduler)

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

	for _, hookName in self.Hooks do
		if not self._hooks[hookName] then
			self._hooks[hookName] = {}
		end
	end

	return self
end

return {
	Phase = Phase,
	Pipeline = Pipeline,
	Scheduler = Scheduler,
}

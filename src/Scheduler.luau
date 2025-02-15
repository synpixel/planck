--!nonstrict
local DependencyGraph = require("@project/DependencyGraph")
local Pipeline = require("@project/Pipeline")
local Phase = require("@project/Phase")

local utils = require("@project/utils")
local hooks = require("@project/hooks")
local conditions = require("@project/conditions")

local get_system = utils.get_system
local get_system_name = utils.get_system_name

local is_phase = utils.is_phase
local is_pipeline = utils.is_pipeline

local is_valid_event = utils.is_valid_event
local get_event_identifier = utils.get_event_identifier

-- Recent errors in Planks itself
local recent_logs = {}
local time_last_logged = os.clock()

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

--- @method add_plugin
--- @within Scheduler
--- @param plugin PlanckPlugin
---
--- Initializes a plugin with the scheduler, see the [Plugin Docs](/docs/plugins) for more information.
function Scheduler:add_plugin(plugin)
	plugin:build(self)
	return self
end

function Scheduler:_add_hook(hook, fn)
	assert(self._hooks[hook], `Unknown Hook: {hook}`)
	table.insert(self._hooks[hook], fn)
end

--- @method get_delta_time
--- @within Scheduler
--- @return number
---
--- Returns the time since the system was ran last.
--- This must be used within a registered system.
function Scheduler:get_delta_time()
	local system_fn = debug.info(2, "f")
	if not system_fn or not self._system_info[system_fn] then
		error(
			"Scheduler:get_delta_time() must be used within a registered system"
		)
	end

	return self._system_info[system_fn].delta_time or 0
end

-- Inspiration from https://github.com/matter-ecs/matter <3
function Scheduler:_handle_logs(system_info)
	if not system_info.time_last_logged then
		system_info.time_last_logged = os.clock()
	end

	if not system_info.recent_logs then
		system_info.recent_logs = {}
	end

	if os.clock() - system_info.time_last_logged > 10 then
		system_info.time_last_logged = os.clock()
		system_info.recent_logs = {}
	end

	local name = debug.info(system_info.system, "n")

	for _, log_message in system_info.logs do
		if not system_info.recent_logs[log_message] then
			task.spawn(error, log_message, 0)
			warn(
				`Planck: Error occurred in system{string.len(name) > 0 and ` '{name}'` or ""}, this error will be ignored for 10 seconds`
			)
			system_info.recentLogs[log_message] = true
		end
	end

	table.clear(system_info.logs)
end

function Scheduler:run_system(system)
	if self:_can_run(system) == false then
		return
	end

	local system_info = self._system_info[system]
	local now = os.clock()

	system_info.delta_time = now - (system_info.last_time or now)
	system_info.last_time = now

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

	local did_yield = false

	local function system_call()
		local function no_yield()
			local success, err = coroutine.resume(self._thread, function()
				system(table.unpack(self._vargs))
			end)

			if not success then
				did_yield = true
				table.insert(system_info.logs, err)
				hooks.system_error(self, system_info, err)
				return
			end

			if self._yielded then
				did_yield = true
				local trace, line = debug.info(system_info.system, "sl")
				table.insert(system_info.logs, `{trace}:{line}: System yielded`)
				hooks.system_error(
					self,
					system_info,
					`{trace}:{line}: System yielded`
				)
			end
		end

		hooks.system_call(self, "SystemCall", system_info, no_yield)
	end

	local function inner()
		hooks.system_call(self, "InnerSystemCall", system_info, system_call)
	end

	local function outer()
		hooks.system_call(self, "OuterSystemCall", system_info, inner)
	end

	if os.clock() - time_last_logged > 10 then
		time_last_logged = os.clock()
		recent_logs = {}
	end

	local success, err: string? = pcall(outer)
	if not success and not recent_logs[err] then
		task.spawn(error, err, 0)
		warn(
			`Planck: Error occurred while running hooks, this error will be ignored for 10 seconds`
		)
		hooks.system_error(
			self,
			system_info,
			`Error occurred while running hooks: {err}`
		)
		recent_logs[err] = true
	end

	if did_yield then
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

	self:_handle_logs(system_info)
end

function Scheduler:run_phase(phase)
	if self:_can_run(phase) == false then
		return
	end

	hooks.phase_began(self, phase)

	if not self._phase_to_systems[phase] then
		self._phase_to_systems[phase] = {}
	end

	for _, system in self._phase_to_systems[phase] do
		self:run_system(system)
	end
end

function Scheduler:run_pipeline(pipeline)
	if self:_can_run(pipeline) == false then
		return
	end

	local ordered_list = pipeline.dependency_graph:get_ordered_list()
	assert(
		ordered_list,
		`Pipeline {pipeline} contains a circular dependency, check it's Phases`
	)

	for _, phase in ordered_list do
		self:run_phase(phase)
	end
end

function Scheduler:_can_run(dependent)
	local conditions = self._run_if_conditions[dependent]

	if conditions then
		for _, run_if in conditions do
			if run_if(table.unpack(self._vargs)) == false then
				return false
			end
		end
	end

	return true
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

	if get_system(dependent) then
		self:run_system(dependent)
	elseif is_phase(dependent) then
		self:run_phase(dependent)
	elseif is_pipeline(dependent) then
		self:run_pipeline(dependent)
	else
		error("Unknown dependent passed into Scheduler:run(unknown)")
	end

	return self
end

--- @method run_all
--- @within Scheduler
--- @return Scheduler
---
--- Runs all Systems within order.
---
--- :::note
--- When you add a Pipeline or Phase with an event, it will be grouped
--- with other Pipelines/Phases on that event. Otherwise, it will be
--- added to the default group.
---
--- When not running systems on Events, such as with the `run_all` method,
--- the Default group will be ran first, and then each Event Group in the
--- order created.
---
--- Pipelines/Phases in these groups are still ordered by their dependencies
--- and by the order of insertion.
--- :::
function Scheduler:run_all()
	local ordered_defaults = self._default_dependency_graph:get_ordered_list()
	assert(
		ordered_defaults,
		"Default Group contains a circular dependency, check your Pipelines/Phases"
	)

	for _, dependency in ordered_defaults do
		self:run(dependency)
	end

	for identifier, dependency_graph in self._event_dependency_graphs do
		local ordered_list = dependency_graph:get_ordered_list()
		assert(
			ordered_defaults,
			`Event Group '{identifier}' contains a circular dependency, check your Pipelines/Phases`
		)
		for _, dependency in ordered_list do
			self:run(dependency)
		end
	end

	return self
end

--- @method insert
--- @within Scheduler
--- @param phase Phase
--- @return Scheduler
---
--- Initializes the Phase within the Scheduler, ordering it implicitly by
--- setting it as a dependent of the previous Phase/Pipeline.

--- @method insert
--- @within Scheduler
--- @param pipeline Pipeline
--- @return Scheduler
---
--- Initializes the Pipeline and it's Phases within the Scheduler,
--- ordering the Pipeline implicitly by setting it as a dependent
--- of the previous Phase/Pipeline.

--- @method insert
--- @within Scheduler
--- @param phase Phase
--- @param instance Instance | EventLike
--- @param event string | EventLike
--- @return Scheduler
---
--- Initializes the Phase within the Scheduler, ordering it implicitly
--- by setting it as a dependent of the previous Phase/Pipeline, and
--- scheduling it to be ran on the specified event.
---
--- ```lua
--- local my_scheduler = Scheduler.new()
---     :insert(my_phase, RunService, "Heartbeat")
--- ```

--- @method insert
--- @within Scheduler
--- @param pipeline Pipeline
--- @param instance Instance | EventLike
--- @param event string | EventLike
--- @return Scheduler
---
--- Initializes the Pipeline and it's Phases within the Scheduler,
--- ordering the Pipeline implicitly by setting it as a dependent of
--- the previous Phase/Pipeline, and scheduling it to be ran on the
--- specified event.
---
--- ```lua
--- local my_scheduler = Scheduler.new()
---     :insert(my_pipeline, RunService, "Heartbeat")
--- ```

function Scheduler:insert(dependency, instance, event)
	assert(
		is_phase(dependency) or is_pipeline(dependency),
		"Unknown dependency passed to Scheduler:insert(unknown, _, _)"
	)

	if not instance then
		local dependency_graph = self._default_dependency_graph
		dependency_graph:insert_before(dependency, self._default_phase)
	else
		assert(
			is_valid_event(instance, event),
			"Unknown instance/event passed to Scheduler:insert(_, instance, event)"
		)

		local dependency_graph =
			self:_get_event_dependency_graph(instance, event)
		dependency_graph:insert(dependency)
	end

	if is_phase(dependency) then
		self._phase_to_systems[dependency] = {}
		hooks.phase_add(self, dependency)
	end

	return self
end

--- @method insert_after
--- @within Scheduler
--- @param phase Phase
--- @param after Phase | Pipeline
--- @return Scheduler
---
--- Initializes the Phase within the Scheduler, ordering it
--- explicitly by setting the after Phase/Pipeline as a dependent.

--- @method insert_after
--- @within Scheduler
--- @param pipeline Pipeline
--- @param after Phase | Pipeline
--- @return Scheduler
---
--- Initializes the Pipeline and it's Phases within the Scheduler,
--- ordering the Pipeline explicitly by setting the after Phase/Pipeline
--- as a dependent.

function Scheduler:insert_after(dependent, after)
	assert(
		is_phase(after) or is_pipeline(after),
		"Unknown dependency passed in Scheduler:insert_after(_, unknown)"
	)
	assert(
		is_phase(dependent) or is_pipeline(dependent),
		"Unknown dependent passed in Scheduler:insert_after(unknown, _)"
	)

	local dependency_graph = self:_get_graph_of_dependency(after)
	dependency_graph:insert_after(dependent, after)

	if is_phase(dependent) then
		self._phase_to_systems[dependent] = {}
		hooks.phase_add(self, dependent)
	end

	return self
end

--- @method insert_before
--- @within Scheduler
--- @param phase Phase
--- @param before Phase | Pipeline
--- @return Scheduler
---
--- Initializes the Phase within the Scheduler, ordering it
--- explicitly by setting the before Phase/Pipeline as a dependency.

--- @method insert_before
--- @within Scheduler
--- @param pipeline Pipeline
--- @param before Phase | Pipeline
--- @return Scheduler
---
--- Initializes the Pipeline and it's Phases within the Scheduler,
--- ordering the Pipeline explicitly by setting the before Phase/Pipeline
--- as a dependency.

function Scheduler:insert_before(dependent, before)
	assert(
		is_phase(before) or is_pipeline(before),
		"Unknown dependency passed in Scheduler:insert_before(_, unknown)"
	)
	assert(
		is_phase(dependent) or is_pipeline(dependent),
		"Unknown dependent passed in Scheduler:insert_before(unknown, _)"
	)

	local dependency_graph = self:_get_graph_of_dependency(before)
	dependency_graph:insert_before(dependent, before)

	if is_phase(dependent) then
		self._phase_to_systems[dependent] = {}
		hooks.phase_add(self, dependent)
	end

	return self
end

--- @method add_system
--- @within Scheduler
--- @param systems System
--- @param phase Phase?
---
--- Adds the System to the Scheduler, scheduling it to be ran
--- implicitly within the provided Phase or on the default Main phase.
function Scheduler:add_system(system, phase)
	local system_fn = get_system(system)

	if not system_fn then
		error("Unknown system passed to Scheduler:add_system(unknown, phase?)")
	end

	local name = get_system_name(system_fn)
	if type(system) == "table" and system.name then
		name = system.name
	end

	local system_info = {
		system = system_fn,
		phase = phase,
		name = name,
		logs = {},
	}

	if not phase then
		if type(system) == "table" and system.phase then
			system_info.phase = system.phase
		else
			system_info.phase = self._default_phase
		end
	end

	self._system_info[system_fn] = system_info

	if not self._phase_to_systems[system_info.phase] then
		self._phase_to_systems[system_info.phase] = {}
	end

	table.insert(self._phase_to_systems[system_info.phase], system_fn)

	hooks.system_add(self, system_info)

	if type(system) == "table" and system.run_conditions then
		for _, condition in system.run_conditions do
			self:add_run_condition(system_fn, condition)
		end
	end

	return self
end

--- @method add_systems
--- @within Scheduler
--- @param systems { System }
--- @param phase Phase?
---
--- Adds the Systems to the Scheduler, scheduling them to be ran
--- implicitly within the provided Phase or on the default Main phase.
function Scheduler:add_systems(systems, phase)
	if type(systems) ~= "table" then
		error(
			"Unknown systems passed to Scheduler:add_systems(unknown, phase?)"
		)
	end

	local found_system = false
	local n = 0

	for _, system in systems do
		n += 1
		if get_system(system) then
			found_system = true
			self:add_system(system, phase)
		end
	end

	if n == 0 then
		error("Empty table passed to Scheduler:add_systems({ }, phase?)")
	end

	if not found_system then
		error(
			"Unknown table passed to Scheduler:add_systems({ unknown }, phase?)"
		)
	end

	return self
end

--- @method edit_system
--- @within Scheduler
--- @param system System
--- @param newPhase Phase
---
--- Changes the Phase that this system is scheduled on.
function Scheduler:edit_system(system, new_phase)
	local system_fn = get_system(system)
	local system_info = self._system_info[system_fn]
	assert(
		system_info,
		"Attempt to remove a non-exist system in Scheduler:edit_system(_)"
	)

	assert(
		new_phase and self._phase_to_systems[new_phase] ~= nil or true,
		"Phase never initialized before using Scheduler:edit_system(_, Phase)"
	)

	local systems = self._phase_to_systems[system_info.phase]

	local index = table.find(systems, system_fn)
	assert(index, "Unable to find system within phase")

	table.remove(systems, index)

	if not self._phase_to_systems[new_phase] then
		self._phase_to_systems[new_phase] = {}
	end
	table.insert(self._phase_to_systems[new_phase], system_fn)

	system_info.phase = new_phase
	return self
end

--- @method remove_system
--- @within Scheduler
--- @param system System
---
--- Removes the System from the Scheduler.
function Scheduler:remove_system(system)
	local system_fn = get_system(system)
	local system_info = self._system_info[system_fn]
	assert(
		system_info,
		"Attempt to remove a non-exist system in Scheduler:remove_system(_)"
	)

	local systems = self._phase_to_systems[system_info.phase]

	local index = table.find(systems, system_fn)
	assert(index, "Unable to find system within phase")

	table.remove(systems, index)
	self._system_info[system_fn] = nil

	hooks.system_remove(self, system_info)

	return self
end

--- @method replace_system
--- @within Scheduler
--- @param old System
--- @param new System
---
--- Replaces the System with a new System.
function Scheduler:replace_system(old, new)
	local old_system_fn = get_system(old)
	local old_system_info = self._system_info[old_system_fn]
	assert(
		old_system_info,
		"Attempt to replace a non-existent system in Scheduler:replace_system(unknown, _)"
	)

	local new_system_fn = get_system(new)
	assert(
		new_system_fn,
		"Attempt to pass non-system in Scheduler:replace_system(_, unknown)"
	)

	local systems = self._phaseToSystems[old_system_info.phase]

	local index = table.find(systems, old_system_fn)
	assert(index, "Unable to find system within phase")

	table.remove(systems, index)
	table.insert(systems, index, new_system_fn)

	local copy = table.clone(old_system_info)

	old_system_info.system = new_system_fn
	old_system_info.name = get_system_name(new_system_fn)

	hooks.system_replace(self, copy, old_system_info)

	self._system_info[new_system_fn] = self._system_info[old_system_fn]
	self._system_info[old_system_fn] = nil

	return self
end

--- @method add_run_condition
--- @within Scheduler
--- @param system System
--- @param fn (U...) -> boolean
---
--- Adds a Run Condition which the Scheduler will check before
--- this System is ran.

--- @method add_run_condition
--- @within Scheduler
--- @param phase Phase
--- @param fn (U...) -> boolean
---
--- Adds a Run Condition which the Scheduler will check before
--- any Systems within this Phase are ran.

--- @method add_run_condition
--- @within Scheduler
--- @param pipeline Pipeline
--- @param fn (U...) -> boolean
---
--- Adds a Run Condition which the Scheduler will check before
--- any Systems within any Phases apart of this Pipeline are ran.\

function Scheduler:add_run_condition(dependent, fn)
	local system = get_system(dependent)
	if system then
		dependent = system
	end

	assert(
		system or is_phase(dependent) or is_pipeline(dependent),
		"Attempt to pass unknown dependent into Scheduler:add_run_condition(unknown, _)"
	)

	if not self._run_if_conditions[dependent] then
		self._run_if_conditions[dependent] = {}
	end

	table.insert(self._run_if_conditions[dependent], fn)

	return self
end

function Scheduler:_add_builtins()
	self._default_phase = Phase.new("Default")
	self._default_dependency_graph = DependencyGraph.new()

	self._default_dependency_graph:insert(Pipeline.Startup)
	self._default_dependency_graph:insert(self._default_phase)

	self:add_run_condition(Pipeline.Startup, conditions.run_once())
	for _, phase in Pipeline.Startup.dependency_graph.nodes do
		self:add_run_condition(phase, conditions.run_once())
	end
end

function Scheduler:_schedule_event(instance, event)
	local connect = utils.get_connect_function(instance, event)
	assert(
		connect,
		"Couldn't connect to event as no valid connect methods were found! Ensure the passed event has a 'Connect' or an 'on' method!"
	)

	local identifier = get_event_identifier(instance, event)

	local dependency_graph = DependencyGraph.new()

	local callback = function()
		local ordered_list = dependency_graph:get_ordered_list()

		if ordered_list == nil then
			local err =
				`Event Group '{identifier}' contains a circular dependency, check your Pipelines/Phases`
			if not recent_logs[err] then
				task.spawn(error, err, 0)
				warn(
					`Planck: Error occurred while running event, this error will be ignored for 10 seconds`
				)
				recent_logs[err] = true
			end
		end

		for _, dependency in ordered_list do
			self:run(dependency)
		end
	end

	connect(callback)
	self._connected_events[identifier] = true
	self._event_dependency_graphs[identifier] = dependency_graph
end

function Scheduler:_get_event_dependency_graph(instance, event)
	local identifier = get_event_identifier(instance, event)

	if not self._connected_events[identifier] then
		self:_schedule_event(instance, event)
	end

	return self._event_dependency_graphs[identifier]
end

function Scheduler:_get_graph_of_dependency(dependency)
	if table.find(self._default_dependency_graph.nodes, dependency) then
		return self._default_dependency_graph
	end

	for _, dependency_graph in self._event_dependency_graphs do
		if table.find(dependency_graph.nodes, dependency) then
			return dependency_graph
		end
	end

	error("Dependency does not belong to a DependencyGraph")
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

	self._event_dependency_graphs = {}
	self._connected_events = {}

	self._phase_to_systems = {}
	self._system_info = {}

	self._run_if_conditions = {}

	setmetatable(self, Scheduler)

	for _, hook_name in hooks.Hooks do
		if not self._hooks[hook_name] then
			self._hooks[hook_name] = {}
		end
	end

	self:_add_builtins()

	return self
end

return Scheduler

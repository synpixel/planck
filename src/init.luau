local Phase = require("@project/Phase") :: any
local Pipeline = require("@project/Pipeline") :: any
local Scheduler = require("@project/Scheduler") :: any

local conditions = require("@project/conditions")
local utils = require("@project/utils")

type EventLike<U...> = utils.EventLike<U...>
type EventInstance = utils.EventInstance

export type SystemFn<U...> = ((U...) -> any) | ((U...) -> ())

export type SystemTable<U...> = {
	system: SystemFn<U...>,
	phase: Phase?,
	name: string?,
	run_conditions: { (U...) -> boolean }?,
	[any]: any,
}

export type System<U...> = SystemFn<U...> | SystemTable<U...>

export type Phase = {
	PreStartup: Phase,
	Startup: Phase,
	PostStartup: Phase,

	new: (debug_name: string?) -> Phase,
}

export type Pipeline = {
	Startup: Pipeline,

	insert: (self: Pipeline, phase: Phase) -> Pipeline,
	insertAfter: (self: Pipeline, phase: Phase, after: Phase) -> Pipeline,
	new: (debug_name: string?) -> Pipeline,
}

type Plugin<U...> = {
	build: (self: Plugin<U...>, scheduler: Scheduler<U...>) -> (),
	[any]: any,
}

export type Scheduler<U...> = {
	add_plugin: (
		self: Scheduler<U...>,
		plugin: Plugin<U...>
	) -> Scheduler<U...>,

	add_system: (
		self: Scheduler<U...>,
		system: System<U...>,
		phase: Phase?
	) -> Scheduler<U...>,

	add_systems: (
		self: Scheduler<U...>,
		systems: { System<U...> },
		phase: Phase?
	) -> Scheduler<U...>,

	edit_system: (
		self: Scheduler<U...>,
		system: System<U...>,
		new: Phase
	) -> Scheduler<U...>,

	replace_system: (
		self: Scheduler<U...>,
		system: System<U...>,
		new: System<U...>
	) -> Scheduler<U...>,

	remove_system: (
		self: Scheduler<U...>,
		system: System<U...>
	) -> Scheduler<U...>,

	add_run_condition: ((
		self: Scheduler<U...>,
		system: System<U...>,
		fn: (U...) -> boolean,
		...any
	) -> Scheduler<U...>) & ((
		self: Scheduler<U...>,
		phase: Phase,
		fn: (U...) -> boolean,
		...any
	) -> Scheduler<U...>) & ((
		self: Scheduler<U...>,
		pipeline: Pipeline,
		fn: (U...) -> boolean,
		...any
	) -> Scheduler<U...>),

	run: ((self: Scheduler<U...>, system: System<U...>) -> Scheduler<U...>)
		& ((self: Scheduler<U...>, phase: Phase) -> Scheduler<U...>)
		& ((self: Scheduler<U...>, pipeline: Pipeline) -> Scheduler<U...>),

	run_all: (self: Scheduler<U...>) -> Scheduler<U...>,

	get_delta_time: (self: Scheduler<U...>) -> number,

	insert: ((self: Scheduler<U...>, phase: Phase) -> Scheduler<U...>) & ((
		self: Scheduler<U...>,
		pipeline: Pipeline
	) -> Scheduler<U...>) & ((
		self: Scheduler<U...>,
		phase: Phase,
		instance: EventInstance | EventLike<U...>,
		event: string | EventLike<U...>
	) -> Scheduler<U...>) & ((
		self: Scheduler<U...>,
		pipeline: Pipeline,
		instance: EventInstance | EventLike<U...>,
		event: string | EventLike<U...>
	) -> Scheduler<U...>),

	insert_after: ((
		self: Scheduler<U...>,
		phase: Phase,
		after: Phase | Pipeline
	) -> Scheduler<U...>) & ((
		self: Scheduler<U...>,
		pipeline: Pipeline,
		after: Phase | Pipeline
	) -> Scheduler<U...>),

	new: (U...) -> Scheduler<U...>,
}

return {
	Phase = Phase :: Phase,
	Pipeline = Pipeline :: Pipeline,
	Scheduler = Scheduler :: {
		new: <U...>(U...) -> Scheduler<U...>,
	},

	is_not = conditions.is_not,
	run_once = conditions.run_once,
	time_passed = conditions.time_passed,
	on_event = conditions.on_event,
}

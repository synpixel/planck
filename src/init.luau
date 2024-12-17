local Phase = require("@Project/Phase") :: any
local Pipeline = require("@Project/Pipeline") :: any
local Scheduler = require("@Project/Scheduler") :: any

type SystemFn<U...> = ((U...) -> any) | ((U...) -> ())

type SystemTable<U...> = {
	system: SystemFn<U...>,
	phase: Phase?,
	[any]: any,
}

type System<U...> = SystemFn<U...> | SystemTable<U...>

type EventLike = RBXScriptSignal | {
	connect: (self: EventLike, ...any) -> any,
	[any]: any,
} | {
	Connect: (self: EventLike, ...any) -> any,
	[any]: any,
} | {
	on: (self: EventLike, ...any) -> any,
	[any]: any,
}

type EventInstance = Instance | {
	[any]: EventLike,
}

type Phase = {
	PreStartup: Phase,
	Startup: Phase,
	PostStartup: Phase,

	PreRender: Phase,
	PreAnimation: Phase,
	PreSimulation: Phase,
	PostSimulation: Phase,

	First: Phase,
	PreUpdate: Phase,
	Update: Phase,
	PostUpdate: Phase,
	Last: Phase,

	new: (debugName: string?) -> Phase,
}

type Pipeline = {
	Main: Pipeline,
	Startup: Pipeline,

	insert: (self: Pipeline, phase: Phase) -> Pipeline,
	insertAfter: (self: Pipeline, phase: Phase, after: Phase) -> Pipeline,
	new: (debugName: string?) -> Pipeline,
}

type Plugin<U...> = {
	build: (self: Plugin<U...>, scheduler: Scheduler<U...>) -> (),
	[any]: any,
}

type Scheduler<U...> = {
	addPlugin: (self: Scheduler<U...>, plugin: Plugin<U...>) -> Scheduler<U...>,

	addSystem: (
		self: Scheduler<U...>,
		system: System<U...>,
		phase: Phase?
	) -> Scheduler<U...>,

	addSystems: (
		self: Scheduler<U...>,
		systems: { System<U...> },
		phase: Phase?
	) -> Scheduler<U...>,

	editSystem: (
		self: Scheduler<U...>,
		system: System<U...>,
		new: Phase
	) -> Scheduler<U...>,

	replaceSystem: (
		self: Scheduler<U...>,
		system: System<U...>,
		new: System<U...>
	) -> Scheduler<U...>,

	removeSystem: (
		self: Scheduler<U...>,
		system: System<U...>
	) -> Scheduler<U...>,

	setRunCondition: ((
		self: Scheduler<U...>,
		system: System<U...>,
		fn: (U...) -> boolean
	) -> Scheduler<U...>) & ((
		self: Scheduler<U...>,
		phase: Phase,
		fn: (U...) -> boolean
	) -> Scheduler<U...>) & ((
		self: Scheduler<U...>,
		pipeline: Pipeline,
		fn: (U...) -> boolean
	) -> Scheduler<U...>),

	run: ((self: Scheduler<U...>, system: System<U...>) -> Scheduler<U...>)
		& ((self: Scheduler<U...>, phase: Phase) -> Scheduler<U...>)
		& ((self: Scheduler<U...>, pipeline: Pipeline) -> Scheduler<U...>),

	runAll: (self: Scheduler<U...>) -> Scheduler<U...>,

	insert: ((self: Scheduler<U...>, phase: Phase) -> Scheduler<U...>) & ((
		self: Scheduler<U...>,
		pipeline: Pipeline
	) -> Scheduler<U...>) & ((
		self: Scheduler<U...>,
		phase: Phase,
		instance: EventInstance | EventLike,
		event: string | EventLike
	) -> Scheduler<U...>) & ((
		self: Scheduler<U...>,
		Pipeline: Pipeline,
		instance: EventInstance | EventLike,
		event: string | EventLike
	) -> Scheduler<U...>),

	insertAfter: ((
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
}

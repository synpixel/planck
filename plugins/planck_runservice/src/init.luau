local RunService = game:GetService("RunService")

local planck = require(script.Parent.planck)

local Phase = planck.Phase
type Phase = planck.Phase

local Pipeline = planck.Pipeline
type Pipeline = planck.Pipeline

type System<U...> = planck.System<U...>
type Scheduler<U...> = planck.Scheduler<U...>

type SystemInfo<U...> = {
	name: string,
	phase: Phase,
	system: System<U...>,
}

type HookArgs<U...> = {
	scheduler: Scheduler<U...>,
	system: SystemInfo<U...>,
	nextFn: System<U...>,
}

type SystemsAddRemove<U...> = {
	scheduler: Scheduler<U...>,
	system: SystemInfo<U...>,
}

type SystemsReplace<U...> = {
	scheduler: Scheduler<U...>,
	new: SystemInfo<U...>,
	old: SystemInfo<U...>,
}

export type Phases = {
	PreRender: Phase,
	PreAnimation: Phase,
	PreSimulation: Phase,
	PostSimulation: Phase,

	First: Phase,
	PreUpdate: Phase,
	Update: Phase,
	PostUpdate: Phase,
	Last: Phase,
}

export type Pipelines = {
	Heartbeat: Pipeline,
	PreRender: Pipeline,
	PreAnimation: Pipeline,
	PreSimulation: Pipeline,
	PostSimulation: Pipeline,
}

local phases = {} :: Phases

phases.PreRender = Phase.new("PreRender")
phases.PreAnimation = Phase.new("PreAnimation")
phases.PreSimulation = Phase.new("PreSimulation")
phases.PostSimulation = Phase.new("PostSimulation")

phases.First = Phase.new("First")
phases.PreUpdate = Phase.new("PreUpdate")
phases.Update = Phase.new("Update")
phases.PostUpdate = Phase.new("PostUpdate")
phases.Last = Phase.new("Last")

local pipelines = {} :: Pipelines

pipelines.Heartbeat = Pipeline.new("HeartbeatPipeline")
	:insert(phases.First)
	:insert(phases.PreUpdate)
	:insert(phases.Update)
	:insert(phases.PostUpdate)
	:insert(phases.Last)

pipelines.PreRender = Pipeline.new("PreRenderPipeline"):insert(phases.PreRender)

pipelines.PreAnimation = Pipeline.new("PreAnimationPipeline")
	:insert(phases.PreAnimation)

pipelines.PreSimulation = Pipeline.new("PreSimulationPipeline")
	:insert(phases.PreSimulation)

pipelines.PostSimulation = Pipeline.new("PostSimulationPipeline")
	:insert(phases.PostSimulation)

local Plugin = {}
Plugin.__index = Plugin

function Plugin:build<U...>(scheduler: Scheduler<U...>)
	for event, pipeline in pipelines do
		scheduler:insert(pipeline, RunService, event)
	end

	local _scheduler = scheduler :: any
	_scheduler._default_dependency_graph = (pipelines.Heartbeat :: any).dependency_graph
	_scheduler._default_phase = phases.Update
end

function Plugin.new()
	return setmetatable({}, Plugin)
end

type Plugin<U...> = {
	build: (self: Plugin<U...>, scheduler: Scheduler<U...>) -> (),
	new: () -> Plugin<U...>,
}

return {
	Plugin = (Plugin :: any) :: Plugin<...any>,
	phases = phases,
	pipelines = pipelines,
}

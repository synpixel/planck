local topoRuntime = require(script.topoRuntime) :: any

type SystemInfo = {
	name: string,
	phase: any,
	system: (...any) -> ...any,
}

type HookArgs = {
	scheduler: any,
	system: SystemInfo,
	nextFn: (...any) -> ...any,
}

type PhaseBeganArgs = {
	scheduler: any,
	phase: any,
}

type SystemsAddRemove = {
	scheduler: any,
	system: SystemInfo,
}

type SystemsReplace = {
	scheduler: any,
	new: SystemInfo,
	old: SystemInfo,
}

local Plugin = {}
Plugin.__index = Plugin

function Plugin:build(scheduler: any)
	if not scheduler._systemState then
		scheduler._systemState = {}
	end

	if not scheduler._systemLogs then
		scheduler._systemLogs = {}
	end

	local phaseDetails = {}

	scheduler:_addHook(
		scheduler.Hooks.PhaseBegan,
		function(args: PhaseBeganArgs)
			local phase = args.phase

			if not phaseDetails[phase] then
				phaseDetails[phase] = {
					lastTime = os.clock(),
					generation = false,
				}
			end

			local details = phaseDetails[phase]

			details.currentTime = os.clock()
			details.deltaTime = details.currentTime - details.lastTime
			details.lastTime = details.currentTime

			details.generation = not details.generation
		end
	)

	scheduler:_addHook(
		scheduler.Hooks.SystemAdd,
		function(info: SystemsAddRemove)
			local systemFn = info.system.system

			if not scheduler._systemState[systemFn] then
				scheduler._systemState[systemFn] = {}
			end

			if not scheduler._systemLogs[systemFn] then
				scheduler._systemLogs[systemFn] = {}
			end
		end
	)

	scheduler:_addHook(
		scheduler.Hooks.SystemRemove,
		function(info: SystemsAddRemove)
			local systemFn = info.system.system

			scheduler._systemState[systemFn] = nil
			scheduler._systemLogs[systemFn] = nil
		end
	)

	scheduler:_addHook(
		scheduler.Hooks.SystemReplace,
		function(info: SystemsReplace)
			local newSystem = info.new.system
			local oldSystem = info.old.system

			scheduler._systemState[newSystem] =
				scheduler._systemState[oldSystem]
			scheduler._systemLogs[newSystem] = scheduler._systemLogs[oldSystem]
			scheduler._systemState[oldSystem] = nil
			scheduler._systemLogs[oldSystem] = nil
		end
	)

	scheduler:_addHook(scheduler.Hooks.OuterSystemCall, function(args: HookArgs)
		local systemFn = args.system.system
		local phase = args.system.phase

		local details = phaseDetails[phase]

		return function()
			topoRuntime.start({
				system = scheduler._systemState[systemFn],
				frame = {
					generation = details.generation,
					deltaTime = details.deltaTime,
					logs = scheduler._systemLogs[systemFn],
				},
				currentSystem = systemFn,
			}, function()
				debug.profilebegin(`system: {args.system.name}`)
				local thread = coroutine.create(function()
					args.nextFn()
				end)

				local _startTime = os.clock()
				local _success, _err = coroutine.resume(thread)

				debug.profileend()
			end)
		end
	end)
end

function Plugin.new()
	return setmetatable({}, Plugin)
end

type Plugin = {
	build: (self: Plugin, scheduler: any) -> (),
	new: () -> Plugin,
}

type ConnectionObject = {
	Disconnect: (() -> ())?,
	Destroy: (() -> ())?,
	disconnect: (() -> ())?,
	destroy: (() -> ())?,
} | () -> ()

type CustomEvent = {
	Connect: (...any) -> ConnectionObject,
	[any]: any,
} | {
	on: (...any) -> ConnectionObject,
	[any]: any,
} | {
	connect: (...any) -> ConnectionObject,
	[any]: any,
}

type Library = {
	useDeltaTime: () -> number,
	useEvent: (
		instance: Instance | { [string]: CustomEvent } | CustomEvent,
		event: string | RBXScriptSignal | CustomEvent
	) -> () -> (number, ...any),
	useThrottle: (seconds: number, discriminator: any?) -> boolean,

	Plugin: Plugin,
}

return {
	useDeltaTime = require("./hooks/useDeltaTime"),
	useEvent = require("./hooks/useDeltaTime"),
	useThrottle = require("./hooks/useDeltaTime"),

	Plugin = Plugin :: any,
} :: Library

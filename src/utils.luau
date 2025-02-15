type Phase = any
type Pipeline = any

type SystemFn<U...> = ((U...) -> any) | ((U...) -> ())

type SystemTable<U...> = {
	system: SystemFn<U...>,
	phase: Phase?,
	[any]: any,
}

type System<U...> = SystemFn<U...> | SystemTable<U...>

local function get_system<U...>(system: any): SystemTable<U...>?
	if type(system) == "function" then
		return system
	elseif type(system) == "table" and system.system then
		return system.system
	else
		return nil
	end
end

local function get_system_name(system: any): string
	local name = debug.info(system, "n")
	if not name or string.len(name) == 0 then
		local source, line = debug.info(system, "sl")
		name = `{source}:{line}`
	end

	return name
end

local function is_phase(phase: any): Phase?
	if type(phase) == "table" and phase._type == "phase" then
		return phase
	else
		return nil
	end
end

local function is_pipeline(pipeline: any): Pipeline?
	if type(pipeline) == "table" and pipeline._type == "pipeline" then
		return pipeline
	else
		return nil
	end
end

local function get_event_identifier(instance, event)
	return `{instance}{event and `@{event}` or ""}`
end

local EVENT_CONNECT_METHODS = { "Connect", "On", "on", "connect" }

export type EventLike = RBXScriptSignal | {
	connect: (self: EventLike, ...any) -> any,
	[any]: any,
} | {
	Connect: (self: EventLike, ...any) -> any,
	[any]: any,
} | {
	on: (self: EventLike, ...any) -> any,
	[any]: any,
}

export type EventInstance = Instance | {
	[any]: EventLike,
}

type ConnectFn<U...> = (callback: (U...) -> ()) -> ()

-- This function is inspired by useEvent in Matter, a library by evaera (https://github.com/evaera)
-- License: Copyright (c) 2021 Eryn L. K., MIT License
-- Source: https://github.com/matter-ecs/matter/blob/main/lib/hooks/useEvent.luau
local function get_connect_function<U...>(
	instance: EventInstance | EventLike,
	event: string | EventLike
): ConnectFn<U...>?
	local event_instance = instance

	if typeof(event) == "RBXScriptSignal" or type(event) == "table" then
		event_instance = event
	elseif type(event) == "string" then
		event_instance = (instance :: any)[event]
	end

	if type(event_instance) == "function" then
		return event_instance
	elseif typeof(event_instance) == "RBXScriptSignal" then
		return function(callback)
			event_instance:Connect(callback)
		end
	end

	if type(event_instance) == "table" then
		for _, method in EVENT_CONNECT_METHODS do
			if type(event_instance[method]) ~= "function" then
				continue
			end

			return function(callback)
				event_instance[method](event_instance, callback)
			end
		end
	end

	return nil
end

local function is_valid_event(instance, event)
	return get_connect_function(instance, event) ~= nil
end

return {
	get_system = get_system,
	get_system_name = get_system_name,
	is_phase = is_phase,
	is_pipeline = is_pipeline,
	get_event_identifier = get_event_identifier,
	is_valid_event = is_valid_event,
	get_connect_function = get_connect_function,
}

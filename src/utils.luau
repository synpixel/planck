type Phase = any
type Pipeline = any

type SystemFn<U...> = ((U...) -> any) | ((U...) -> ())

type SystemTable<U...> = {
	system: SystemFn<U...>,
	phase: Phase?,
	[any]: any,
}

type System<U...> = SystemFn<U...> | SystemTable<U...>

local function getSystem<U...>(system: any): SystemTable<U...>?
	if type(system) == "function" then
		return system
	elseif type(system) == "table" and system.system then
		return system.system
	else
		return nil
	end
end

local function getSystemName(system: any): string
	local name = debug.info(system, "n")
	if not name or string.len(name) == 0 then
		name = debug.info(system, "sl")
	end

	return name
end

local function isPhase(phase: any): Phase?
	if type(phase) == "table" and phase._type == "phase" then
		return phase
	else
		return nil
	end
end

local function isPipeline(pipeline: any): Pipeline?
	if type(pipeline) == "table" and pipeline._type == "pipeline" then
		return pipeline
	else
		return nil
	end
end

local function getEventIdentifier(instance, event)
	return `{instance}{event and `@{event}` or ""}`
end

local validEventMethods = {
	"Connect",
	"connect",
	"On",
	"on",
}

local function isValidEvent(instance, event)
	local eventInstance = event and instance[event] or instance

	if typeof(eventInstance) == "RBXScriptSignal" then
		return true
	elseif typeof(eventInstance) == "table" then
		for _, method in validEventMethods do
			if eventInstance[method] ~= nil then
				return true
			end
		end
	end

	return false
end

return {
	getSystem = getSystem,
	getSystemName = getSystemName,
	isPhase = isPhase,
	isPipeline = isPipeline,
	getEventIdentifier = getEventIdentifier,
	isValidEvent = isValidEvent,
}

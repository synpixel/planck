-- Super-duper experimental Plugin Hooks API

local function system_add(scheduler, system_info)
	local hooks = scheduler._hooks[scheduler.Hooks.SystemAdd]
	local info = {
		scheduler = scheduler,
		system = system_info,
	}

	for _, hook in hooks do
		local success, err = pcall(hook, info)
		if not success then
			warn("Unexpected error in hook:", err)
		end
	end
end

local function system_remove(scheduler, system_info)
	local hooks = scheduler._hooks[scheduler.Hooks.SystemRemove]
	local info = {
		scheduler = scheduler,
		system = system_info,
	}

	for _, hook in hooks do
		local success, err = pcall(hook, info)
		if not success then
			warn("Unexpected error in hook:", err)
		end
	end
end

local function system_replace(scheduler, old_system_info, new_system_info)
	local hooks = scheduler._hooks[scheduler.Hooks.SystemReplace]
	local info = {
		scheduler = scheduler,
		new = new_system_info,
		old = old_system_info,
	}

	for _, hook in hooks do
		local success, err = pcall(hook, info)
		if not success then
			warn("Unexpected error in hook:", err)
		end
	end
end

local function system_call(scheduler, hook_name, system_info, next_fn)
	local hooks = scheduler._hooks[scheduler.Hooks[hook_name]]

	if hooks then
		for _, hook in hooks do
			next_fn = hook({
				scheduler = nil,
				system = system_info,
				next_fn = next_fn,
			})

			if not next_fn then
				local source, line = debug.info(hook, "sl")
				warn(
					`{source}:{line}: Expected 'SystemCall' hook to return a function`
				)
			end
		end
	end

	next_fn()
end

local function system_error(scheduler, system_info, err)
	local hooks = scheduler._hooks[scheduler.Hooks.SystemError]

	if hooks then
		for _, hook in hooks do
			hook({
				scheduler = scheduler,
				system = system_info,
				error = err,
			})
		end
	end
end

type PhaseAdd = {
	scheduler: any,
	phase: any,
}

local function phase_add(scheduler, phase)
	local hooks = scheduler._hooks[scheduler.Hooks.PhaseAdd]
	local info = {
		scheduler = scheduler,
		phase = phase,
	}

	for _, hook in hooks do
		local success, err = pcall(hook, info)
		if not success then
			warn("Unexpected error in hook:", err)
		end
	end
end

local function phase_began(scheduler, phase)
	local hooks = scheduler._hooks[scheduler.Hooks.PhaseBegan]
	local info = {
		scheduler = scheduler,
		phase = phase,
	}

	for _, hook in hooks do
		local success, err = pcall(hook, info)
		if not success then
			warn("Unexpected error in hook:", err)
		end
	end
end

local Hooks = {
	SystemAdd = "SystemAdd",
	SystemRemove = "SystemRemove",
	SystemReplace = "SystemReplace",
	SystemError = "SystemError",

	OuterSystemCall = "OuterSystemCall",
	InnerSystemCall = "InnerSystemCall",
	SystemCall = "SystemCall",

	PhaseAdd = "PhaseAdd",
	PhaseBegan = "PhaseBegan",
}

return {
	Hooks = Hooks,

	system_add = system_add,
	system_remove = system_remove,
	system_replace = system_replace,
	system_call = system_call,
	system_error = system_error,
	phase_add = phase_add,
	phase_began = phase_began,
}

-- Super-duper experimental Plugin Hooks API

local function systemAdd(scheduler, systemInfo)
	local hooks = scheduler._hooks[scheduler.Hooks.SystemAdd]
	local info = {
		scheduler = scheduler,
		system = systemInfo,
	}

	for _, hook in hooks do
		local success, err = pcall(hook, info)
		if not success then
			warn("Unexpected error in hook:", err)
		end
	end
end

local function systemRemove(scheduler, systemInfo)
	local hooks = scheduler._hooks[scheduler.Hooks.SystemRemove]
	local info = {
		scheduler = scheduler,
		system = systemInfo,
	}

	for _, hook in hooks do
		local success, err = pcall(hook, info)
		if not success then
			warn("Unexpected error in hook:", err)
		end
	end
end

local function systemReplace(scheduler, oldSystemInfo, newSystemInfo)
	local hooks = scheduler._hooks[scheduler.Hooks.SystemReplace]
	local info = {
		scheduler = scheduler,
		new = newSystemInfo,
		old = oldSystemInfo,
	}

	for _, hook in hooks do
		local success, err = pcall(hook, info)
		if not success then
			warn("Unexpected error in hook:", err)
		end
	end
end

local function systemCall(scheduler, hookName, systemInfo, nextFn)
	local hooks = scheduler._hooks[scheduler.Hooks[hookName]]
	if hooks then
		for _, hook in hooks do
			nextFn = hook({
				scheduler = nil,
				system = systemInfo,
				nextFn = nextFn,
			})
		end
	end

	nextFn()
end

local function phaseBegan(scheduler, phase)
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

	OuterSystemCall = "OuterSystemCall",
	InnerSystemCall = "InnerSystemCall",
	SystemCall = "SystemCall",

	PhaseBegan = "PhaseBegan",
}

return {
	Hooks = Hooks,

	systemAdd = systemAdd,
	systemRemove = systemRemove,
	systemReplace = systemReplace,
	systemCall = systemCall,
	phaseBegan = phaseBegan,
}

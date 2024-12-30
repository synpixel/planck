local Jabby = require(script.Parent.Jabby)

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

local n = 0

function Plugin:build(scheduler: any)
	n += 1

	local name = `Planck{n > 0 and ` {n}` or ""}`
	local jabbyScheduler = Jabby.scheduler.create(name)

	local systemToId = {}

	for systemFn, systemInfo in scheduler._systemInfo do
		local id = jabbyScheduler:register_system({
			name = systemInfo.name,
		})

		systemToId[systemFn] = id
	end

	scheduler:_addHook(
		scheduler.Hooks.SystemAdd,
		function(info: SystemsAddRemove)
			local id = jabbyScheduler:register_system({
				name = info.system.name,
			})

			systemToId[info.system.system] = id
		end
	)

	scheduler:_addHook(
		scheduler.Hooks.SystemRemove,
		function(info: SystemsAddRemove)
			jabbyScheduler:remove_system(systemToId[info.system.system])
			systemToId[info.system.system] = nil
		end
	)

	scheduler:_addHook(
		scheduler.Hooks.SystemReplace,
		function(info: SystemsReplace)
			local newSystem = info.new.system
			local oldSystem = info.old.system

			jabbyScheduler:remove_system(systemToId[oldSystem])
			systemToId[oldSystem] = nil

			local id = jabbyScheduler:register_system({
				name = info.new.name,
			})

			systemToId[newSystem] = id
		end
	)

	scheduler:_addHook(scheduler.Hooks.SystemCall, function(args: HookArgs)
		return function()
			jabbyScheduler:run(systemToId[args.system.system], args.nextFn)
		end
	end)

	table.insert(Jabby.public, jabbyScheduler)
	Jabby.public.updated = true
end

function Plugin.new()
	return setmetatable({}, Plugin)
end

return Plugin

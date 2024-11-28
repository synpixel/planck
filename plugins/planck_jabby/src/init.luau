local Jabby = require("@Packages/Jabby")

type SystemInfo = {
	name: string,
	phase: any,
	fn: (...any) -> ...any,
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

type SystemsEdit = {
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

	scheduler:_addHook(
		scheduler.Hooks.SystemAdd,
		function(info: SystemsAddRemove)
			local id = jabbyScheduler:register_system({
				name = info.system.name,
			})

			systemToId[info.system.fn] = id
		end
	)

	scheduler:_addHook(
		scheduler.Hooks.SystemRemove,
		function(info: SystemsAddRemove)
			jabbyScheduler:remove_system(systemToId[info.system.fn])
			systemToId[info.system.fn] = nil
		end
	)

	scheduler:_addHook(scheduler.Hooks.SystemEdit, function(info: SystemsEdit)
		local newSystem = info.new.fn
		local oldSystem = info.old.fn

		jabbyScheduler:remove_system(systemToId[oldSystem])
		systemToId[oldSystem] = nil

		local id = jabbyScheduler:register_system({
			name = info.new.name,
		})

		systemToId[newSystem] = id
	end)

	scheduler:_addHook(scheduler.Hooks.SystemCall, function(args: HookArgs)
		return function()
			jabbyScheduler:run(systemToId[args.system.fn], args.nextFn)
		end
	end)

	table.insert(Jabby.public, jabbyScheduler)
	Jabby.public.updated = true
end

function Plugin.new()
	return setmetatable({}, Plugin)
end

return Plugin

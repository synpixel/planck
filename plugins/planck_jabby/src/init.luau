local jabby = require(script.Parent.jabby)

type SystemInfo = {
	name: string,
	phase: any,
	system: (...any) -> ...any,
}

type HookArgs = {
	scheduler: any,
	system: SystemInfo,
	next_fn: (...any) -> ...any,
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

	local identifier = n > 1 and ` #{n}` or ""
	local name = `Planck{identifier}`

	local jabby_scheduler = jabby.scheduler.create()

	local system_to_id = {}

	for system_fn, system_info in scheduler._system_info do
		local id = jabby_scheduler:register_system({
			name = system_info.name,
			phase = tostring(system_info.phase),
		})

		system_to_id[system_fn] = id
	end

	scheduler:_add_hook(
		scheduler.Hooks.SystemAdd,
		function(info: SystemsAddRemove)
			local id = jabby_scheduler:register_system({
				name = info.system.name,
				phase = tostring(info.system.phase),
			})

			system_to_id[info.system.system] = id
		end
	)

	scheduler:_add_hook(
		scheduler.Hooks.SystemRemove,
		function(info: SystemsAddRemove)
			jabby_scheduler:remove_system(system_to_id[info.system.system])
			system_to_id[info.system.system] = nil
		end
	)

	scheduler:_add_hook(
		scheduler.Hooks.SystemReplace,
		function(info: SystemsReplace)
			local new_system = info.new.system
			local old_system = info.old.system

			jabby_scheduler:remove_system(system_to_id[old_system])
			system_to_id[old_system] = nil

			local id = jabby_scheduler:register_system({
				name = info.new.name,
				phase = tostring(info.new.phase),
			})

			system_to_id[new_system] = id
		end
	)

	local STARTUP_PHASES = { "PreStartup", "Startup", "PostStartup" }
	local startup_systems = {}

	scheduler:_add_hook(scheduler.Hooks.SystemCall, function(args: HookArgs)
		local id = system_to_id[args.system.system]

		return function()
			for _id, _ in startup_systems do
				jabby_scheduler:set_system_data(_id, {
					paused = true,
				})
			end

			jabby_scheduler:run(id, function()
				args.next_fn()

				local phase = tostring(args.system.phase)
				if table.find(STARTUP_PHASES, phase) then
					startup_systems[id] = true
				end
			end)
		end
	end)

	jabby.register({
		applet = jabby.applets.scheduler,
		name = name,
		configuration = {
			scheduler = jabby_scheduler,
		},
	})
end

function Plugin.new()
	return setmetatable({}, Plugin)
end

type SchedulerLike<U...> = {
	add_plugin: (
		self: SchedulerLike<U...>,
		plugin: Plugin<U...>
	) -> SchedulerLike<U...>,
	new: (U...) -> SchedulerLike<U...>,
	[any]: any,
}

type Plugin<U...> = {
	build: (self: Plugin<U...>, scheduler: SchedulerLike<U...>) -> (),
	new: () -> Plugin<U...>,
}

return (Plugin :: any) :: Plugin<...any>

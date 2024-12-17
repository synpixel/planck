--- @class Phase
---
--- Phases represent tags that tell the scheduler when to
--- schedule a set of systems.
local Phase = {}
Phase.__index = Phase

function Phase:__tostring()
	return self._name
end

--- @within Phase
---
--- Creates a new Phase, with an optional name to use for debugging.
--- When no name is provided, the script and line number will be used.
function Phase.new(name: string?)
	name = name or debug.info(2, "sl")
	return setmetatable({
		_name = name,
		_type = "phase",
	}, Phase)
end

--- @prop PreStartup Phase
--- @within Phase
--- Runs before the `Startup` Phase.

--- @prop Startup Phase
--- @within Phase
--- This Phase will run once, the first time the Scheduler is ran,
--- before any other Phases are ran.

--- @prop PostStartup Phase
--- @within Phase
--- Runs after the `Startup` phase.

Phase.PreStartup = Phase.new("PreStartup")
Phase.Startup = Phase.new("Startup")
Phase.PostStartup = Phase.new("PostStartup")

--- @prop PreRender Phase
--- @within Phase
--- Runs on the `RunService.PreRender` Event.

--- @prop PreAnimation Phase
--- @within Phase
--- Runs on the `RunService.PreAnimation` Event.

--- @prop PreSimulation Phase
--- @within Phase
--- Runs on the `RunService.PreSimulation` Event.

--- @prop PostSimulation Phase
--- @within Phase
--- Runs on the `RunService.PostSimulation` Event.

Phase.PreRender = Phase.new("PreRender")
Phase.PreAnimation = Phase.new("PreAnimation")
Phase.PreSimulation = Phase.new("PreSimulation")
Phase.PostSimulation = Phase.new("PostSimulation")

--- @prop First Phase
--- @within Phase
--- Will always run first on the `RunService.Heartbeat` Event.

--- @prop PreUpdate Phase
--- @within Phase
--- Runs before the `Update` Phase.

--- @prop Update Phase
--- @within Phase
--- Runs on the `RunService.Heartbeat` Event.
--- This is the default Phase systems will run on.

--- @prop PostUpdate Phase
--- @within Phase
--- Runs after the `Update` Phase.

--- @prop Last Phase
--- @within Phase
--- Will always run last on the `RunService.Heartbeat` Event.

Phase.First = Phase.new("First")
Phase.PreUpdate = Phase.new("PreUpdate")
Phase.Update = Phase.new("Update")
Phase.PostUpdate = Phase.new("PostUpdate")
Phase.Last = Phase.new("Last")

return Phase

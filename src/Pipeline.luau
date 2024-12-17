local Phase = require("@Project/Phase")

--- @class Pipeline
---
--- Pipelines represent a set of ordered Phases. Systems cannot be
--- assigned to Pipelines themselves, but rather to Phases within
--- those Pipelines.
local Pipeline = {}
Pipeline.__index = Pipeline

function Pipeline:__tostring()
	return self._name
end

--- @method insert
--- @within Pipeline
--- @param phase Phase
--- @return Pipeline
---
--- Adds a Phase to the Pipeline, ordering it implicitly.
function Pipeline:insert(phase)
	table.insert(self._phases, phase)
	return self
end

--- @method insert
--- @within Pipeline
--- @param phase Phase
--- @param after Phase
--- @return Pipeline
---
--- Adds a Phase to the Pipeline after another Phase, ordering it explicitly.
function Pipeline:insertAfter(phase, otherPhase)
	local i = table.find(self._phases, phase)
	assert(i, "Phase not initialized in Pipeline")

	table.insert(self._phases, i + 1, otherPhase)
	return self
end

--- @within Pipeline
---
--- Creates a new Pipeline, with an optional name to use for debugging.
--- When no name is provided, the script and line number will be used.
function Pipeline.new(name: string?)
	name = name or debug.info(2, "sl")
	return setmetatable({
		_name = name,
		_type = "pipeline",
		_phases = {},
	}, Pipeline)
end

--- @prop Startup Pipeline
--- @within Pipeline
---
--- A Pipeline containing the `PreStartup`, `Startup`, and `PostStartup` phases.
Pipeline.Startup = Pipeline.new()
	:insert(Phase.PreStartup)
	:insert(Phase.Startup)
	:insert(Phase.PostStartup)

--- @prop Main Pipeline
--- @within Pipeline
---
--- A Pipeline containing the `First`, `PreUpdate`, `Update`, `PostUpdate`, and `Last` phases.
Pipeline.Main = Pipeline.new()
	:insert(Phase.First)
	:insert(Phase.PreUpdate)
	:insert(Phase.Update)
	:insert(Phase.PostUpdate)
	:insert(Phase.Last)

return Pipeline

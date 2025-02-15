--!nonstrict
local DependencyGraph = require("@project/DependencyGraph")
local Phase = require("@project/Phase")

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
	self.dependency_graph:insert(phase)
	return self
end

--- @method insert_after
--- @within Pipeline
--- @param phase Phase
--- @param after Phase
--- @return Pipeline
---
--- Adds a Phase to the Pipeline after another Phase, ordering it explicitly.
function Pipeline:insert_after(phase, after_phase)
	local i = table.find(self.dependency_graph.nodes, after_phase)
	assert(
		i,
		"Unknown Phase in Pipeline:insert_after(_, unknown), try adding this Phase to the Pipeline."
	)

	self.dependency_graph:insert_after(phase, after_phase)
	return self
end

--- @method insert_before
--- @within Pipeline
--- @param phase Phase
--- @param before Phase
--- @return Pipeline
---
--- Adds a Phase to the Pipeline before another Phase, ordering it explicitly.
function Pipeline:insert_before(phase, before_phase)
	local i = table.find(self.dependency_graph.nodes, before_phase)
	assert(
		i,
		"Unknown Phase in Pipeline:insert_before(_, unknown), try adding this Phase to the Pipeline."
	)

	self.dependency_graph:insert_before(phase, before_phase)
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
		dependency_graph = DependencyGraph.new(),
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

return Pipeline

local AdjacencyMatrix = {}
AdjacencyMatrix.__index = AdjacencyMatrix

function AdjacencyMatrix:__tostring()
	local s = "\n"

	for i = 1, self.length do
		if i == 1 then
			s ..= "\n"
		end

		local sub = ""
		for j = 1, self.width do
			if j == self.width then
				sub ..= `{self.matrix[i][j]}`
				continue
			end

			sub ..= `{self.matrix[i][j]}, `
		end

		sub ..= "\n"
		s ..= sub
	end

	return s
end

function AdjacencyMatrix:extend()
	self.length = (self.length :: number) + 1
	self.width = (self.length :: number) + 1

	self.matrix[self.length] = {}
	for j = 1, self.width do
		self.matrix[self.length][j] = 0
	end

	for i = 1, self.length do
		self.matrix[i][self.width] = 0
	end
end

function AdjacencyMatrix:set_edge(i, j, val)
	self.matrix[i][j] = val
end

function AdjacencyMatrix:to_adjacency_list()
	local list = {}

	for i = 1, self.length do
		list[i] = {}
		for j = 1, self.width do
			if self.matrix[i][j] ~= 0 then
				table.insert(list[i], j)
			end
		end
	end

	return list
end

function AdjacencyMatrix:topological_ort(): { number }?
	local adjacency_list = self:to_adjacency_list()

	local result = {}
	local in_degrees = table.create(self.length, 0)

	for i = 1, self.length do
		for _, j in adjacency_list[i] do
			in_degrees[j] += 1
		end
	end

	local queue = {}
	for i = 1, self.length do
		if in_degrees[i] == 0 then
			table.insert(queue, i)
		end
	end

	while #queue ~= 0 do
		local i = table.remove(queue, 1) :: number
		table.insert(result, i)

		for _, j in adjacency_list[i] do
			in_degrees[j] -= 1
			if in_degrees[j] == 0 then
				table.insert(queue, j)
			end
		end
	end

	if #result ~= self.length then
		return nil
	end

	return result
end

function AdjacencyMatrix.new()
	return setmetatable({
		matrix = {},
		length = 0,
		width = 0,
	}, AdjacencyMatrix)
end

local DependencyGraph = {}
DependencyGraph.__index = DependencyGraph

function DependencyGraph:get_ordered_list(): { any }?
	local ordered_list = {}

	local topological_sort = self.matrix:topological_sort()
	if not topological_sort then
		return nil
	end

	for _, i in topological_sort do
		table.insert(ordered_list, self.nodes[i])
	end

	return ordered_list
end

function DependencyGraph:insert_before(node, before_node)
	if not table.find(self.nodes, before_node) then
		error("Node not found in DependencyGraph:insert_before(_, unknown)")
	end

	table.insert(self.nodes, node)
	local j = #self.nodes
	local i = table.find(self.nodes, before_node)

	self.matrix:extend()
	self.matrix:set_edge(j, i, 1)

	return self
end

function DependencyGraph:insert_after(node, after_node)
	if not table.find(self.nodes, after_node) then
		error("Node not found in DependencyGraph:insert_after(_, unknown)")
	end

	table.insert(self.nodes, node)

	local j = #self.nodes
	local i = table.find(self.nodes, after_node)

	self.matrix:extend()
	self.matrix:set_edge(i, j, 1)

	return self
end

function DependencyGraph:insert(node)
	local i = #self.nodes
	table.insert(self.nodes, node)
	local j = #self.nodes

	self.matrix:extend()

	if i ~= 0 then
		self.matrix:set_edge(i, j, 1)
	end

	return self
end

function DependencyGraph.new()
	return setmetatable({
		nodes = {},
		matrix = AdjacencyMatrix.new(),
		length = 0,
		width = 0,
	}, DependencyGraph)
end

return DependencyGraph

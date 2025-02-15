local utils = require("@Project/utils")
local get_connect_function = utils.get_connect_function

type EventLike = utils.EventLike
type EventInstance = utils.EventInstance

type Condition = () -> boolean

--- @class Conditions
---
--- Conditions can be used in systems or as Run Conditions.

--- @within Conditions
--- @param time number -- Time in seconds
--- @return has_time_passed () -> boolean
---
--- A Throttle condition which checks whether the amount of
--- time given has passed or not.
local function time_passed(time: number): Condition
	local stored_time

	return function()
		if stored_time == nil or os.clock() - stored_time >= time then
			stored_time = os.clock()
			return true
		end

		return false
	end
end

--- @within Conditions
--- @return has_ran_once () -> boolean
---
--- Checks whether the condition has been called once before
local function run_once(): Condition
	local has_ran = false

	return function()
		if not has_ran then
			has_ran = true
			return true
		end

		return false
	end
end

type CollectEvents<U...> = () -> () -> (number, U...)

--- @within Conditions
--- @return has_new_event () -> boolean
--- @return collect_events () -> () -> (number, U...)
---
--- Checks for any new events and allows for the collection of
--- those events.
local function on_event<U...>(
	instance: EventInstance | EventLike,
	event: string | EventLike
): (Condition, CollectEvents<U...>)
	local connect = get_connect_function(instance, event)
	assert(connect, "Event passed to .on_event is not valid")

	local new_event = false
	local queue = {}

	local function callback(...)
		new_event = true
		table.insert(queue, { ... })
	end

	connect(callback)

	local function has_new_event()
		if new_event then
			new_event = false
			return true
		end

		table.clear(queue)
		return false
	end

	local function collect_events()
		local n = 0
		return function(): (number, U...)
			n += 1

			local args = table.remove(queue, 1)

			if args then
				return n, table.unpack(args)
			end

			return nil :: any
		end
	end

	return has_new_event, collect_events
end

--- @within Conditions
--- @param condition () -> boolean
--- @return inverse_condition () -> boolean
---
--- Inverses a given condition.

-- selene: allow(unused_variable)
local function is_not(condition: Condition, ...: any): Condition
	return function()
		return not condition()
	end
end

return {
	time_passed = time_passed,
	run_once = run_once,
	on_event = on_event,
	is_not = is_not,
}

---
title: Systems
description: The basics of Systems
sidebar_position: 3
---

# Systems

Systems, at their very core, are functions that are designed to be execution on a certain event or on a loop.

When working with ECS on Roblox, typically you will have most of your systems running on the [RunService.Heartbeat](https://create.roblox.com/docs/reference/engine/classes/RunService#Heartbeat) event.
This will run your systems every *frame*, on the `Heartbeat`.

We will go over running systems on events later on. For now, let's see
how we create and add systems to the Scheduler.

```lua title="systemA.luau"
local function systemA()
    -- ...
end

return systemA
```

This is how systems are typically made: a single function inside of a
ModuleScript.

To add this to our Scheduler, we can do:

```lua title="scheduler.luau"
-- ...

local systemA = require("@shared/systems/systemA")

local scheduler = Scheduler.new(world, state)
    :addSystem(systemA)
```

Remember how we also passed state into the Scheduler to our Systems?
This will be passed directly into the parameters of our systems.

```lua {1} title="systemA.luau"
local function systemA(world, state)
    -- ...
end

return systemA
```

### System Tables

Another way you can define a System is with a SystemTable.

SystemTables contain not only the *function* but can also contain a Phase,
Name, and Run Condition for Systems.

| Field         | Type                    |              |
| ------------- | ----------------------- | ------------ |
| name          | string                  | Optional     |
| system        | function                | **Required** |
| phase         | Phase                   | Optional     |
| runConditions | \{ (...any) -> boolean \} | Optional     |

The Name is used for debugging and used in tooling such as Jabby to help you identify systems, this is automatically inferred from the function name, so it's completely optional.

Don't worry about what a Phase or Run Condition is for now, we will explain these later.

```lua title="systemA.luau"
local function systemA(world, state)
    -- ...
end

local function condition(world, state)
    if someCondition then
        return true
    else
        return false
    end
end

return {
    name = "systemA",
    system = systemA,
    phase = Planck.Phase.PreUpdate,
    runConditions = { condition }
}
```

And then we can add this the same way as the first example,

```lua title="scheduler.luau"
-- ...

local systemA = require("@shared/systems/systemA")

local scheduler = Scheduler.new(world, state)
    :addSystem(systemA)
```

### System Sets

You can also create a set, or rather an array of Systems. These can either
be functions or SystemTables. You can even mix the two in a System Set.

```lua
-- ...

local systemA = require("@shared/systems/systemA")
local systemB = require("@shared/systems/systemB")

local systemSet = { systemA, systemB }

local scheduler = Scheduler.new(world, state)
    :addSystems(systemSet)
```

This allows us to bulk add systems to the Scheduler. When we learn about Phases, this will also allow us to bulk set what phase these systems run on.

## What's Next?

Now that we have systems, we should learn how to properly manage their order
of execution. This is where Phases come in.

→ [Phases](./phases.md)
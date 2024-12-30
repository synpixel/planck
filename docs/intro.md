---
title: Introduction
description: An introduction to Planck
sidebar_position: 1
---

# Introduction

## Installation

You can install Planck with Wally

```toml
[dependencies]
Planck = "yetanotherclown/planck@0.1.0-rc.1"
```

## The Basics

### Phases

A Phase is just a tag you can assign to your systems, it's a way to order systems as a group.

```lua
local myPhase = Phase.new("debugName")

scheduler
    :insert(myPhase, RunService, "Heartbeat")
    :addSystems(systemA, myPhase)
```

### Pipelines

A Pipeline is a group of ordered phases. Each phase will run in the fixed order to which each Phase was passed to it.

```lua
local myPipeline = Pipeline.new()
    :insert(phaseA)
    :insert(phaseB)
    :insert(phaseC)

scheduler
    :insert(myPipeline, RunService, "Heartbeat")
```

### Built-in Pipelines & Phases

#### Startup

Systems on these phases will run exactly once, before any other phase runs.

- PreStartup
- Startup
- PostStartup

```lua
local Planck = require("@packages/Planck")
local Phase = Planck.Phase

local PreStartup = Phase.PreStartup
local Startup = Phase.Startup
local PostStartup = Phase.PostStartup
```

#### Engine Events

These Phases are ran on Engine RunService Events,
events are ran in the order listed.

| Event          | Phase          |
| -------------- | -------------- |
| PreRender      | PreRender      |
| PreAnimation   | PreAnimation   |
| PreSimulation  | PreSimulation  |
| PostSimulation | PostSimulation |
| Heartbeat      | Update         |

```lua
local Planck = require("@packages/Planck")
local Phase = Planck.Phase

local PreRender = Phase.PreRender
local PreAnimation = Phase.PreAnimation
local PreSimulation = Phase.PreSimulation
local PostSimulation = Phase.PostSimulation
local Update = Phase.Update
```

#### Main

The Main Pipeline will run phases on the `RunService.Heartbeat` event.

- First
- PreUpdate
- Update
- PostUpdate
- Last

```lua
local Planck = require("@packages/Planck")
local Phase = Planck.Phase

local First = Phase.First
local PreUpdate = Phase.PreUpdate
local Update = Phase.Update
local PostUpdate = Phase.PostUpdate
local Last = Phase.Last
```

### Systems

A system is just a function, or it could be a system table.

```lua
local systemA = {
    phase = myPhase,
    system = function()
        -- ...
    end,
}

local function systemB()
    -- ...
end

scheduler
    :addSystems(systemA)
    :addSystems(systemB, myPhase)
```

### The Scheduler

The Scheduler is where you initialize all your Pipelines, Phases, and Systems.

```lua
local Planck = require("@packages/Planck")

local Phase = Planck.Phase
local Pipeline = Planck.Pipeline
local Scheduler = Planck.Scheduler

local PreUpdate = Phase.new()
local Update = Phase.new()
local PostUpdate = Phase.new()

local UpdatePipeline = Pipeline.new()
	:insert(PreUpdate)
	:insert(Update)
	:insert(PostUpdate)

local Render = Phase.new()

local scheduler = scheduler.new(world)
    :insert(UpdatePipeline, RunService, "Heartbeat")
    :insertAfter(Render, UpdatePipeline)
    :addSystems(systems, Update)

scheduler:removeSystem(systemA)
scheduler:replaceSystem(systemA, systemB)

scheduler:editSystem(systemA, newPhase)
scheduler:editSystem(systemA)

scheduler:setRunCondition(systemA, function(world)
    return someCondition and true or false
end)
```
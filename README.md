# Planck, an ECS Scheduler

![GitHub License](https://img.shields.io/github/license/yetanotherclown/planck?style=flat-square)
[![Documentation](https://img.shields.io/badge/Documentation-02B1E9?style=flat-square&logo=data:image/svg%2bxml;base64,PHN2ZyByb2xlPSJpbWciIHZpZXdCb3g9IjAgMCAyNCAyNCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8dGl0bGU+TW9vbndhdmU8L3RpdGxlPgogIDxwYXRoIGQ9Ik0xMy43MzkgMTQwLjMzMWMuMjguNDkyLjQ2NSAxLjAwOC44NTEgMS40MzguODczLjk3MyAyLjE3MyAxLjAzMyAzLjI2NC4zOTcuOTg5IDIuMzc1IDMuNTg4IDIuOTgzIDUuODk5IDIuNTQ3LjUzNC0uMSAxLjkxOS0uMyAyLjEzMi0uODYyLTEuNDgzIDAtMy4xMDYuMTctNC4zNjMtLjgxOS0yLjE0Ny0xLjY4OS0uNzE1LTQuNiAxLjM4OC01LjQ3Ny0uMTM4LS40MjYtMS4xNTgtLjM5OC0xLjUzNy0uMzk2LTEuNzYyLjAwNy0yLjk0OCAxLjEwOC0zLjY2OCAyLjYyNy0uNjc1LTEuNzQ4LS4zNTQtMy4yOCAxLjE0LTQuNDg4LjM5Ny0uMzIxLjg0My0uNTM5IDEuMjg5LS43OC4xMTgtLjA2NC4zNDItLjE5Ni4xOC0uMzQxLS4xNjUtLjE0OC0uNTE2LS4xNy0uNzI1LS4yMjJhMTIuMjcyIDEyLjI3MiAwIDAgMC0yLjA4Mi0uMzJjLS44MTktLjA1OC0xLjYyNC0uMDQ0LTIuNDMuMTQ3LTMuMDcuNzI5LTQuMjc2IDMuNTg5LTUuNjM2IDYuMTAzLS41NjcgMS4wNS0xLjA1MSAyLjEyNi0xLjk5OCAyLjkwMi0xLjE1MS45NDQtMi42NzYgMS4xOC00LjExNSAxLS4zNjktLjA0Ni0uNzMtLjEyOC0xLjA5LS4yMTUtLjA4NC0uMDItLjMyNC0uMS0uMzUxLjA0My0uMDQ0LjIzNC43MzEuNDcuODk2LjU0MSAxLjA0NC40NDUgMi4xLjY4OSAzLjIyMi44MjEgMy4wNTkuMzYxIDYuNTMtMS44NTcgNy43MzQtNC42NDZ6IiBzdHlsZT0iZmlsbDojZmZmZmZmO2ZpbGwtb3BhY2l0eToxO3N0cm9rZTpub25lO3N0cm9rZS13aWR0aDouMDQ5NTc0MyIgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoLTEuODg1IC0xMjcuMzEpIi8+Cjwvc3ZnPg==)](https://yetanotherclown.github.io/planck)
[![Wally Package](https://img.shields.io/badge/Wally-ad4646?style=flat-square&logoSize=auto&logo=data:image/svg%2bxml;base64,PHN2ZyByb2xlPSJpbWciIHZpZXdCb3g9IjAgMCAyNCAyNCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48dGl0bGU+V2FsbHk8L3RpdGxlPjxwYXRoIGZpbGw9Im5vbmUiIGQ9Ik0yMC4zMjUgMTguMTkxYy0xLjkxNSAyLjU5OS01LjEyNyA0LjI1NC04LjM1OCA0LjE4MS0uMjk2LS41MjgtLjc2My0xLjY3My4zNDgtMS4yOTcgMi4zNTUtLjA3NiA0Ljc3LTEuMDE0IDYuMzc1LTIuNzYxLjI5OS0uODUzLjgyLS45ODcgMS4zOC0uMzAxbC4xMjcuMDkuMTI4LjA4OHpNMTIuNzg1IDYuMmMtLjg5Mi4yNjQtLjEwNCAyLjY2LjQ1OSAxLjI3Mi0uMDc1LS40MDcuMjItMS4yODgtLjQ1OC0xLjI3MnptLS41OS0uMjQyYy0uNjY0LTEuMzM1IDEuOTY2LS4zNTMgMS44ODItLjIyOC0uMzI2LS44NTYtMi4zMDItMS4yNC0yLjI2My0uMTA4bC4xNzMuMTk3ek0xMS41NCAxOS4zOGMtLjI4LTEuMzY0IDEuOTY1LS45NTggMS45My0xLjgwMS0uOTkyLS4xNi0yLjM4Mi0uODMyLTEuMzQtMS45NjMgMS4wMjctMS4wMjIgMi41MzMtMS45NTYgMi40OTItMy42NDktLjI4NS42MTItLjkyIDEuOTMtMS44MzUgMi4zODctMS41NzMgMS4wOC00LjA5IDEuMTc5LTUuMjYtLjU1LS4zNDktLjQ2My0uNjg3LTEuNDkxLS40NC0uMzQyLjQ2Ni42NjguNiAxLjcwMi0uNTYxIDEuNDUzLTEuMjQ1LS40NDEtLjM2Mi0xLjc2NC0uNC0yLjY0Ni0uNi0xLjE0NCAxLjM3Ni0uNjA4IDEuNjIzLTEuNjk0QzguNjQgOS40MyA2LjcyIDguODMgNS44NDggOC45MWMtLjk5Ni4xNjUuODUxLS40OTUgMS4xOC0uNzkuNzczLS40NTMgMS41MDYtLjk5NiAyLjA5LTEuNjgyLS41NjIuNDgyLS43NjEuNTE2LS43NDktLjI4LTEuMTUyLS41Ny0uMTM3IDEuNjkzLTEuMzk3IDEuNjY4LS45MTIuNjA1LjYxOS0xLjE0NC4yMzItMS43ODctLjIxOS0xLjIzNCAxLjUtMS4zMjIgMS40My0uMjMuNzYyLS42MjQtLjYxNi0xLjAyMy0uNjE2LTEuMTczIDEuMzQ3LTEuMzA3IDMuNDEzLTEuMzk1IDUuMTItLjg3My45MTYuMjUgMS43MDQuODYyIDIuMDA2IDEuNzg2Ljg5NCAyLjA2NC40NzMgNC4zNTEuMjc4IDYuNTA0LS4xOCAxLjExNi40OTMgMi4wNzcgMS4zODEgMi40NjYuNDI2LjkxNyAxLjkxIDEuNzUyLjU3NSAyLjYwOC0xLjUzOSAxLjQ4OC0zLjY2MyAyLjQ3Ny01LjgzOCAyLjI1MnptOS4xMjMtMS42NjVjLTEuMjctLjQ3MS0xLjc3My0xLjc0Mi0yLjg4NC0yLjM2NS0uNTMzLS42MzgtLjk2LTEuMTU0LS4yOS0xLjc4My4yOTktMS4zNjggMS43OC0xLjg1MiAyLjQ1NC0yLjk4Ljc4Ny0uOTY4LjcwNC0yLjQzMS0uMjAyLTMuMjkxLS43OTctLjg2LTIuMDc2LTEuMjA2LTIuNTI3LTIuMzg1LTEuMjMtMS4wMi0zLjAyMS0xLjA1NS00LjQ5OS0xLjY3NS0xLjMyOC0uMTk0LTIuOTA1LS4yNjEtNC4wMjEuNjA2LTEuNDkyLjAzLTEuODA3IDEuNzc3LTIuNTk0IDIuNzI2LS43My42NDktMS42NTMgMS4yNjYtMS4xNTMgMi4zMzQtMS4wNDguNzE3LjE3OCAyLjAzNi42OTIgMi43NTQuMzA3IDEuMjAyLS45OTQgMy4xNzYuOTY4IDMuNTM4Ljc4NC4wMjYgMS4xNzMtLjg2OCAxLjc5Ni0uMDQzIDEuMzc1LjIyNSAxLjA5IDEuODk4IDEuMDE4IDIuOTM2LjA4Mi45MDItMS4wMiAxLjU2NS0uMzI5IDIuNS0uMTQuODc4LS4zMDMgMS42Ni0xLjI3Ni45MjMtMy45OTktMS43MTgtNi42NDktNi4xMy02LjE2Ny0xMC40NzMuMzM0LTQuMTIyIDMuMzc3LTcuODM0IDcuMzQ1LTguOTg4IDQuMDgtMS4zMSA4Ljg0Ny4yODggMTEuMzUzIDMuNzU1IDIuNTg0IDMuNDAxIDIuNzMxIDguMzguMzE2IDExLjkxWk0xMS43NjguMDAzQzYuODQ4LjAzOSAyLjE4NSAzLjQ0NS42NTIgOC4xMmMtMS40OTUgNC4xOC0uMzU4IDkuMTEzIDIuNzc2IDEyLjI0OSAzLjI1NiAzLjQ0IDguNjMzIDQuNTY5IDEzLjAxIDIuNzc0IDQuNjM2LTEuNzg5IDcuODMtNi42OTIgNy41NDItMTEuNjYtLjE1NS00LjY2My0zLjMtOS4wNC03LjY3MS0xMC42NzJhMTEuODcyIDExLjg3MiAwIDAgMC00LjU0LS44MVoiIHN0eWxlPSJmaWxsOiNGRkY7ZmlsbC1vcGFjaXR5OjE7c3Ryb2tlOm5vbmUiLz48L3N2Zz4=)](https://wally.run/package/yetanotherclown/planck)

An Agnostic Scheduler, inspired by Bevy Schedules and Flecs Pipelines and Phases.
 
> [!IMPORTANT]  
> The Planck Scheduler and it's plugins are currently in development!
> You can find a release candidate under `yetanotherclown/planck@0.1.0-rc.2`

## Installation

You can install Planck with Wally

```toml
[dependencies]
Planck = "yetanotherclown/planck@0.1.0-rc.2"
```

## Basics

### Phases

A Phase is just a tag you can assign to your systems, it's a way to order systems as a group.

```luau
local myPhase = Phase.new("debugName")

scheduler
    :insert(myPhase, RunService, "Heartbeat")
    :addSystems(systemA, myPhase)
```

### Pipelines

A Pipeline is a group of ordered phases. Each phase will run in the fixed order to which each Phase was passed to it.

```luau
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

```luau
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

```luau
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

```luau
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

```luau
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

```luau
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

### Plugins

The Planck Scheduler is pluggable, providing plugins to add
support for Jabby and the Matter Hooks runtime.

You can learn more in the [Plugin Docs](https://yetanotherclown.github.io/planck/docs/plugins/).

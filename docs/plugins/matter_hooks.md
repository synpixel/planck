---
title: Matter Hooks
description: A Plugin to add the Matter topoRuntime and Hooks to Planck
sidebar_position: 1
---

The Matter Hooks plugin provides a way to use the Matter topoRuntime to use any
hook made for Matter.


You can install it with,

```toml
[dependencies]
MatterHooks = "yetanotherclown/planck-matter-hooks@0.1.0"
```

Then to set it up,

```lua
local Planck = require("@packages/Planck")
local Scheduler = Planck.Scheduler

local MatterHooks = require("@packages/MatterHooks")

local useDeltaTime = MatterHooks.useDeltaTime
local useEvent = MatterHooks.useEvent
local useThrottle = MatterHooks.useThrottle

local hooksPlugin = MatterHooks.new()

local scheduler = scheduler.new()
    :addPlugin(hooksPlugin)
    :addSystems(function()
        if useThrottle(5) then
            print("Throttled for 5 seconds")
        end
    end)
```
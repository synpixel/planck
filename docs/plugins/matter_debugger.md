---
title: Matter Debugger
description: A Plugin to add support for the Matter Debugger to Planck
sidebar_position: 1
---

The Matter Debugger plugin provides support for Planck within the Matter
debugger.

You can install it with,

```toml
[dependencies]
DebuggerPlugin = "yetanotherclown/planck-matter-debugger@0.1.0-rc.1"
```

Then to set it up,

```lua
local Planck = require("@packages/Planck")
local Scheduler = Planck.Scheduler

local DebuggerPlugin = require("@packages/DebuggerPlugin")
local debuggerPlugin = DebuggerPlugin.new()

local scheduler = scheduler.new()
    :addPlugin(debuggerPlugin)
```
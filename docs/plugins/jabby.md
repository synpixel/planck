---
title: Jabby
description: A Plugin to add support for Jabby
sidebar_position: 2
---

Jabby is a Debugger for Jecs by Ukendio. This Plugin handles all setup to
add the Planck Scheduler to Jabby.

You can install it with,

```toml
[dependencies]
PlanckJabby = "yetanotherclown/planck-jabby@0.1.0"
```

Then to set it up,

```lua
local Planck = require("@packages/Planck")
local Scheduler = Planck.Scheduler

local PlanckJabby = require("@packages/PlanckJabby")
local jabbyPlugin = PlanckJabby.new()

local scheduler = scheduler.new()
    :addPlugin(jabbyPlugin)
```

This only adds the Scheduler to Jabby, you'll have to add the
World and other setup yourself.
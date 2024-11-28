---
title: Plugins
description: About Planck Plugins
sidebar_position: 2
---

Plugins in Planck allow you to incorporate it easily into other ECS tooling and libraries.

And also, for example, instead of including the Matter topoRuntime in Planck itself,
you choose whether or not to include it. This ensures you only ever get what you need.

## Provided Plugins

### Matter Hooks

The Matter Hooks plugin provides a way to use the Matter topoRuntime to use any
hook made for Matter.

See the [Matter Hooks](/docs/plugins/matter_hooks) page.

### Jabby

Jabby is a Debugger for Jecs by Ukendio. This Plugin handles all setup to
add the Planck Scheduler to Jabby.

See the [Jabby](/docs/plugins/jabby) page.

## Creating Plugins

:::danger
    The API behind Plugins is currently unstable.

    The Plugins API will continue to be undocumented until it is stable.
    If you want to create a Plugin, see the two provided Plugin's source code,
    and be warned.
:::
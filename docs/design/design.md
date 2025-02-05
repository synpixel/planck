---
title: Designing with Planck
description: Advanced topics for designing your game with Planck
sidebar_position: 2
---

# Designing with Planck

:::note
We're going to be getting into some advanced topics
regarding design patterns and practices for you to use
when working with Planck and with ECS in general.

If you haven't already read [The Basics](../getting_started/introduction.md), you should
go and do that now.
:::

When working with an ECS, or just with Planck and its
many features, it's easy to fall into dangerous
patterns which can either affect the maintainability
of your project or introduce certain bugs and issues.

## Off By A Frame Issues

One of the most frequent issues we will be addressing
are 'off-by-a-frame' bugs. While your systems and
game as a whole should be able to function still with
these issues present, the effect of it is visible
latency in your game.

This was briefly introduced in [Introduction](../getting_started/introduction.md) under
'Does any of this really matter?'.

> Let's say we have `systemA` and `systemB`. `systemA`
> modifies data in our world which `systemB` depends on.
> If `systemA` runs *after* `systemB`, then `systemB` will
> have to wait a whole frame for the modifications to be made.

When a system has to wait a whole frame for an operation it
depends on, we introduce latency into our game. This latency
has the potential to be visible to players, who call it lag.

The best way to address this is by assigning `systemA` and
`systemB` to different Phases, with `systemA`'s Phase running
*before* `systemB`'s Phase.

We will go into detail on when to create a Phase, what Phases
systems should be assigned to, and more later on.

## Credits

These design guides were inspired and influenced by the Flecs and Matter documentation.

## What's Next?

Let's continue where we left off and talk about Phases.
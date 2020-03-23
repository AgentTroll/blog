---
layout: post
title: "Lessons Learned Debugging: Part 11"
date: 2020-03-21T19:54:10-07:00
---

I didn't even realize that I haven't written a post this
year yet. Event handlers are key components of plugins
because they are used as an entry point to most plugin
logic. Think of plugins like WorldGuard, minigame plugins
and other game features like crates, quests etc. All of
them use event handlers as an intrinsic component of their
primary function. Yet, many plugin developers, even those
who should know better, seem to write event handlers that
break the functionality of other plugins or prevent other
plugins from being able to listen to events.

# Event Handlers Should Play Nice

The source for a lot of misunderstanding about how event
handlers work is the [`@EventHandler`](https://hub.spigotmc.org/javadocs/spigot/org/bukkit/event/EventHandler.html)
annotation. The purpose of this annotation, first and
foremost, is to mark methods which are to be called by the
plugin manager when events are fired. Secondly, it provides
to options: and `priority` and `ignoredCancelled`. While
these options both have defaults, those defaults are not
always correct. In fact, many developers don't even know
what they do or how changing them can impact other plugins.
Let's take a look at how using the `@EventHandler`
annotation *correctly* can help plugins maintain
compatibility with each other.

# Event Priorities

The `priority` option allows developers to tell the plugin
manager when, with respect to other plugin event handlers,
they want the event handler to be called. This can be
thought of as the server storing a list of event handlers
to be called each time the appropriate event is being
called. Changing the event priority can allow you to have
your event handler called prior to other event handlers,
or cede to other event handlers to be called first. This
operates on a per-handler basis, meaning that the priority
of event handlers allows them to be reordered with any
other event handler, regardless of whether they belong to
the same plugin or not.

The first common misconception about event priority is that
it allows you to detect an event earlier. This is false.
Event handlers with different priorities receive events at
the same time. For example, an event handler listening for
`PlayerMoveEvent` will not receive `PlayerMoveEvent` any
sooner or respond any faster to a player moving by changing
the priority of the event. What changes with different
priorities is the *order* that event listeners are called,
**not** *when*. Ultimately, all events are called with
something like the following line:

``` java
Bukkit.getPluginManager().callEvent(event)
```

All event handlers are called by
`PluginManager#callEvent(Event)`, so it doesn't make any
sense for an event to somehow be fired sooner by changing
the event handler priority.

The second common misconception about event priority is the
order that event handlers are called with respect to their
priority. Many novice developers believe that a
`EventPriority.LOW` event handler is handled after
`EventPriority.HIGH`, event handler. In fact, the opposite
is true: higher priority events are called *later* than
lower priority events. From the JavaDoc page:

> First priority to the last priority executed:
>
> 1. LOWEST
> 2. LOW
> 3. NORMAL
> 4. HIGH
> 5. HIGHEST
> 6. MONITOR

Registered events utilize an `ArrayList` to organize event
handlers of the same priority, so two event handlers with
`NORMAL` priority are executed in insertion order or the
same order they were registered in.

To understand why this is the case, we need to look at why
you would even want to change your event priority in the
first place.

The purpose of a `HIGH` priority event handler is such that
it has a greater precedence over what happens as a result
of an event being fired. As such, it should fire later than
a `LOW` priority event handler because it would be able to
override anything that the `LOW` priority event handler
does if it so wishes.

The crux of many compatibility issues is event handlers
being set to the wrong priority. One personal example is a
plugin that creates mines that used an event handler set to
`HIGHEST` priority to detect `BlockBreakEvent`s. While the
developer might have thought this was a good idea since
they might want to override any other plugin when it comes
to preventing a block in the mine from being broken at
certain times, this prevented me from being able to use
`BlockBreakEvent` to change whether or not the event would
be cancelled. There are a number of hacky workarounds to
this (such as changing the event priority of the plugin or
renaming your plugin jar file so your plugin loads later or
incorrectly using the `MONITOR` priority), but the point
still stands: using the wrong priority makes it difficult
for other plugins to provide additional features and
functionality.

So what is the correct event priority to use? These are not
hard and fast rules, obviously, but in general:

  - If you don't know, leave it alone. The default priority
  is `NORMAL`, which is the priority most event handlers
  should use. This is a safe option regardless of what your
  event handler does.
  - If you want other plugins to utilize your plugin's
  functionality as a principal feature use `LOW`. For
  example, protection plugins should use this because
  other plugins depend on whether or not an event is
  allowed (that the event is not cancelled).
  - If you need to override the event handler of another
  plugin, then it is acceptable to use `HIGH` priority

If your plugin **requires** a certain priority for your
event handler to function correctly on its own (i.e. not
because some other plugin is being overridden), **it is
broken**.

Avoid using `HIGHEST` and `MONITOR` priorities, even if
you know you are using them correctly. The purpose of a
`MONITOR` event priority is for listeners that do not make
any changes to the event, e.g. they don't cancel or modify
the event the handler listens for in any way. However, this
precludes other plugins from checking for any state changes
to your plugin as a result of an event because the
`MONITOR` priority event handlers always run last. As I've
already discussed, a `HIGHEST` priority event listener
requires other event listeners to use `MONITOR` in order
to override them or some other hack, which means that your
plugin impedes other developers from writing correct,
well-defined code.

Now just to make sure we are all clear, when I say that
something is incorrect, I don't mean it is disallowed or
that anything bad happens when you do something like
mutate an event inside a `MONITOR` event handler. However,
compatibility is based on plugins agreeing to follow the
same "rules." Breaking these rules without knowing what
you are doing potentially causes other plugins which do
follow these rules to break as well. This is why it is your
responsibility to "play nice" with other plugins by using
the correct event priorities.

As a side note, I personally believe it is a mistake to use
an enum as an event priority. Event handlers in different
plugins can have many layers, even more than there are enum
constants to use in the `EventPriority` enum. The standard
way to implement priorities is through a numbering system,
e.g. low priority events use 0 and high priority events use
something like 100. This allows much wider range of event
handlers to build off the functionality of other plugins.
That being said, I do concede that these issues may still
exist if developers use `Integer.MAX_VALUE`, for example,
and that too many event handlers overriding each other
generally are very fragile. Nonetheless, food for thought.

# Ignore Cancelled Events

Another commonly misused (actually unused would probably be
more fitting) option is `ignoreCancelled`. The purpose of
this annotation is for that event handlers to be skipped
when the event is cancelled by some other event handler
running before it. The default value of `ignoreCancelled`
is `false`, meaning that the event handler runs regardless
of whether the event has been cancelled or not. This is the
source for some confusion as many people seem to suggest
checking if an event is being cancelled by another plugin
when `ignoreCancelled` is not specified. As a matter of
fact, your event handler will run anyway if you do not
explicitly use `ignoreCancelled = true`, so this advice is
a waste of time at best.

A great many event handlers lack this option when they
should be using it. For example, event handlers that
rely on player actions such as `BlockBreakEvent` or
`PlayerInteractEvent` that lack `ignoreCancelled = true`
are generally incorrect. These events are commonly
cancelled by a variety of different plugins, especially
protection plugins such as WorldGuard. This means that
logic that should never ever be executed under any
circumstances, such as spawning a boss inside someone
else's territory or land claim occurs even when a
protection plugin has cancelled the event. This has been
source of multiple bugs in my personal experience. This
allows players the possibility of griefing the server and
potentially throw the server economy into chaos if they
are able to figure out how to exploit this incorrect
behavior when it is not correctly handled by the plugin.

The usefulness of `ignoreCancelled` comes from the fact
that you can avoid running any extra logic from an event
that is going to be cancelled (i.e. so that it seems that
the event never even occurred in the first place). You can
boost performance by a considerable amount simply through
the reduction in the amount of logic being run on top of
maintaining compatibility with other plugins.

In my opinion, `ignoreCancelled = true` should be the
default. You need a compelling reason to always run an
event handler even when some other plugin has cancelled
the event. For example, a logging plugin might not want
to use `ignoreCancelled = true` if they want to log every
action and the result of that action. Some events also
cannot be cancelled, which is another reason why it might
not be necessary to use `ignoreCancelled = true`.

In general, prefer to use `ignoreCancelled = true`. Once
you determine that your event handler actually does need to
run even when the event is cancelled, then you can remove
this option and use the default of `false`.

# Conclusion

This has been a pretty text and detail-heavy post, so I
hope the justification behind the correct `@EventHandler`
options to use is clear enough at this point. I'm still
working on a few personal projects of mine so the next
blog post probably won't be out for another while since I'm
trying to juggle school along with my own projects
currently, and potentially some work in the near future if
I find the time for that.

While event priorities are not often the source for bugs,
the lack of `ignoreCancelled` most definitely has caused a
few major bugs. My personal opinion is that the latter of
the two is not set to a sane default, so always make sure
to `ignoreCancelled = true` first and think about it later,
because it is much easier to debug an event handler that
doesn't run than it is to debug an event handler that is
incorrectly written to handle an edge-case scenario that
should have been cancelled.

And once again, I leave with the following quote from
[The Power of Ten](http://spinroot.com/gerard/pdf/P10.pdf):

> If the rules seem Draconian at first, bear in mind that
they are meant to make it possible to check code where very
literally your life may depend on its correctness: code
that is used to control the airplane that you fly on, the
nuclear power plant a few miles from where you live, or the
spacecraft that carries astronauts into orbit. The rules
act like the seat-belt in your car: initially they are
perhaps a little uncomfortable, but after a while their use
becomes second-nature and not using them becomes
unimaginable.


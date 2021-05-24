---
layout: post
title: "Lessons Learned Debugging: Part 8"
date: 2019-08-09T02:03:35-07:00
---

One of the most frustrating things about a large plugin
ecosystem is that at one point or another, you will need to
start handling the dependencies between each plugin for
particular actions - e.g. who gets to break what block and
where they are allowed. How can you constrain the scope of
some certain plugin, due to the functionality of another
plugin, or how can you bypass something?

# Have One Plugin Handle Protection Checks

On most servers, you'll find some sort of system for
protection, whether it be protecting players from damage
or protecting blocks from being broken. For example, most
Skyblock servers will disallow all damage to players while
they are on their island. This is problematic in some cases
because you actually want players to take damage. In other
cases, a protection plugin doesn't handle an edge case
involving new capabilities you've written for, say, a boss
entity. You'll find that in order to handle these edge
cases, it often requires you to write the same code over
and over again, and that each time you add a new feature
that needs to interoperate with existing features, these
edge case handlers are either thrown out the window or
simply don't work anymore. I've seen bugs introduced almost
every feature update due to the fact that protection must
either be checked or overridden for each and every single
feature independently. If the boilerplate for doing this
could be eliminated or reduced, then it would be easier to
write your checks to protection plugins without worrying
about forgetting something. Doing something that is easy
means that you'll do it more often, and before long, it
will become second-nature rather than something that you
explicitly need to think about.

Luckily, there is an elegant solution to the potentially
messy business of interdependent protections. You'll need
a single plugin to handle protection for your specific
server ecosystem. All protection checks can be described
by the following function:

``` java
boolean isAllowed(ActionType type, Object affector, Object target);
```

In many cases, one can boil down *all* protection checks to
a single method. For example, the if you are writing a
plugin for a skyblock server, then almost all protection
is determined by which island a player belongs to and what
island is being affected by that player. Here's what a
boiled-down check if an action `isAllowed` would look like:

``` java
public boolean isAllowed(ActionType type, Island affector, Island target) {
    return affector != null && affector.equals(target);
}
```

For ASkyBlock, a player may belong to a few different
islands due to co-oping. A server running ASkyBlock might
want to use this to determine whether something
`isAllowed`:

``` java
public boolean isAllowed(ActionType type,
        Stream<Island> affector,
        Island target) {
    return affector != null
            && affector.anyMatch(island -> island.equals(target));
}
```

This is our base ruleset. Since all actions, whether they
be block placement, which islands players can enter, block
breaking, who can be damaged and when, etc. is determined
by the island the respective parties belong to, we now only
need to translate players, entities, and locations to
islands. In fact, it is conceivable that one can cover
most, if not all possible use cases with just definitions
to translate those 3 objects. Further, it is possible
through the use of `ActionType` to make this both type-safe
and extensible in case plugins want to add their own
translation methods:

``` java
public class ProtectionHandler {
    private boolean isAllowed(ActionType<A, T> type,
            Stream<Island> affector,
            Island target) {
        ...
    }

    public <A, T> boolean isAllowed(ActionType<A, T> type, A affector, T target) {
        return this.isAllowed(type.translateAffector(affector),
                type.translateTarget(target));
    }
}

public abstract class ActionType<A, T> {
    public static final ActionType<Player, Block> PLAYER_PLACE_BLOCK =
            new ActionType<>() {
                @Override
                public Stream<Island> translateAffector(Player affector) {
                    UUID affectorId = affector.getUniqueId();
                    Island playerIsland = SkyBlockApi.getPlayerIsland(affectorId);

                    Collection<Island> coopIslands =
                            SkyBlockApi.getPlayerCoops(affectorId);
                    coopIslands.add(playerIsland);

                    return coopIslands.stream();
                }

                @Override
                public Island translateTarget(Block target) {
                    Location blockLocation = target.getLocation();
                    return SkyBlockApi.getIslandAtLocation(target);
                }
            };

    public abstract Stream<Island> translateAffector(A affector);
    public abstract Island translateTarget(T target);
}
```

The beauty of using this is that the translation methods
can take into account other factors, such as if there is
another plugin that controls the finer-grained permissions.
For example, when I worked at MineSaga, one could enable or
disable the ability of co-oped players to place blocks. By
only having to take this into account once through the use
of `ActionType` constants, you no longer need to remember
to check with that plugin each time you do a protection
check. Each plugin fewer that you need to check is one
fewer check you can possibly forget. If you recall my last
blog post, you can throw all of your protection handling
code into a
[central library](https://caojohnny.github.io/blog/2019/07/24/lessons-learned-debugging-part-7.html).
If you ever add a new plugin that actually adds new
behavior that the `isAllowed` check needs to handle, all
of your plugins using the protection handler provided by
the core plugin benefit from a change to just that one
core plugin to account for that new check. Additionally,
this means that only new plugins will need to depend on a
single core plugin that also handles protection. Assuming
that you don't need to add any `ActionType`s, you can get
away with not even modifying the core plugin. You can
focus your efforts on implementing features instead of
writing hacky and fragile code just to make sure your
protection ruleset is being honored.

`BlockPlaceEvent` is not one of the things that you usually
need to check with a protection handler, since that
function is normally handled by whatever protection plugin
you are using. You can exploit this by calling
`BlockPlaceEvent` for every block that needs to be checked,
then seeing if it has been cancelled. The framework I've
discussed is useful for cases where there is not an
existing event handled by protection plugins. For example,
if a minion (on MineSaga, a zombie entity) "places" a
block, it would be a good idea to translate the minion's
owner UUID to whichever island that player belongs to in
order to check if the minion `isAllowed` to place that
block:

``` java
public static final ActionType<Minion, Block> MINION_PLACE_BLOCK =
        new ActionType<>() {
            @Overide
            public Stream<Island> translateAffector(Minion affector) {
                UUID ownerId = minion.getOwner();
                Island playerIsland = SkyBlockApi.getPlayerIsland(ownerId);

                Collection<Island> coopIslands =
                        SkyBlockApi.getPlayerCoops(ownerId);
                coopIslands.add(playerIsland);

                return coopIslands.stream();
            }

            @Override
            public Island translateTarget(Block target) {
                return ActionType.PLAYER_PLACE_BLOCK.translateTarget(target);
            }
        };
```

The extensibility of this system is a valuable feature
because it means that one doesn't need to go through the
trouble of storing the `Player` object itself in order to
perform protection checks which depend on the fact that
the something performing some modification action is a
player. It could be a boss entity or a minion entity as
demonstrated by the above snippet.

However, for the sake of completeness, let's assume for a
moment that you have a really bad skyblock plugin, or a
really bad protection plugin that doesn't handle
`BlockPlaceEvent`. What would, say, a multiblock place event
listener look like?

``` java
@EventHandler
public void onPlace(BlockPlaceEvent event) {
    ...

    Block block = event.getBlockPlaced();
    Location start = block.getLocation();

    ProtectionHandler ph = ...
    for (int i = 0; i < height; i++) {
        Location newLocation = start.add(0, i, 0);
        Block newBlock = newLocation.getBlock();

        if (ph.isAllowed(ActionType.MINION_PLACE_BLOCK,
                player, newBlock)) {
            // Set block, remove item, etc...
        }
    }

    ...
}
```

Not so bad!

# Overriding Protections

Now that we've covered how protection checks can be done in
an elegant, extensible way, how do we handled overriding an
existing protection plugin?

> Before I get into this section, a small personal
> anecdote:
>
> The correct way to write protection event listeners is to
> use an `EventPriority.LOW` event handler method so that
> non-protection plugins can use `ignoreCancelled` without
> having to change their priority. Unfortunately, I've seen
> a number of excessively dumb plugins which set their
> protection listeners to `EventPriority.HIGHEST` (or in
> extreme cases, `EventPriority.MONITOR`), under the
> assumption that they want their event listener to take
> precedence. For the love of all that is good in this
> world **please stop doing this**. This causes issues with
> plugins that need to piggyback off of that protection to
> have no way of checking whether or not an event will be
> cancelled without doing hacks like scheduling a task to
> check if the event is cancelled once all event listeners
> have run or refiring the event and storing it to make
> sure it doesn't get handled in an infinite loop, etc.
> I've had to write an enchanted pickaxe plugin that
> shouldn't run any enchantments if a block was broken
> outside of a mine. However, the mine plugin, which
> handled block break protection registered their listener
> with `EventPriority.HIGHEST`, and in the interests of
> keeping `EventPriority.MONITOR` clear, I unregistered
> their listener from the `BlockBreakEvent`'s
> `HandlerList` and re-registered it under a lower
> priority.

Unlike writing protection checks, overriding protection is
independent. If we are overriding a protection, that means
that the protection itself is irrelevant (otherwise, we
wouldn't really be overriding anything). Mind you, limits
can still be placed on where or when overriding is done.
However, this is up to each individual plugin, so it
wouldn't make sense to include this feature in a central
core plugin.

Overriding protection listeners can be done in two ways.
Firstly, you can bypass the listener entirely and manually
perform some action on its own. For example, if a plugin
cancels damage events, you can manually set the health of
an entity instead. Secondly, you can set a listener to a
higher priority and then use
`Cancellable#setCancelled(boolean)` to *uncancel* the
event if certain conditions are met. If you can't edit the
source of a plugin using a scheduler to protect some region
or entity or block, then you can consider cancelling that
scheduler task and then running your own task which does
everything except for whatever protection you are
overriding.

The short of it is that overriding a protection is much
easier than checking for a protection. You don't need to
worry about the limitations for the former because you are
already overriding the protection. However, for the latter,
I've presented a good way of structuring a protection
handler to reduce boilerplate and reduce the number of bugs
you are getting from forgetting protection checks.

# Conclusion

I have little else to say except for the tradition of
leaving readers with the following words from
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


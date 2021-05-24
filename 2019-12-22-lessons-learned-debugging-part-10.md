---
layout: post
title: "Lessons Learned Debugging: Part 10"
date: 2019-12-22T20:19:55-05:00
---

This is a follow-up of sorts to
[Part 6](https://caojohnny.github.io/blog/2019/07/13/lessons-learned-debugging-part-6.html)
of this series of posts. I felt that the topic of inventory
management is so important for most servers that it is
worth taking a look at a few more ways players get access
to items that they shouldn't have in the first place. These
are logical oversights that developers tend to forget about
which players exploit in order to get access to those
items.

# There Are Many Ways To Get Items You Shouldn't Have

Of course, as I've stated before, any exceptions or logical
errors will often lead to "duplication"-style bugs where
players get more of the item than they are supposed to.
However, the lack of logic or logical oversight where you
forget to check something or forget to prevent access to
inventory items are just as serious. As I will also again
reiterate, inventories and item management in Bukkit is a
death trap. There are so many different things that can go
wrong and so many different creative ways to exploit flawed
logic that most developers will need to break a server's
economy multiple times before becoming proficient in being
able to spot some of these bugs while they are writing
their code. I've made a list of some of the common ones
I've made myself.

# Item Stacking

One important way that servers reduce lag is through
stacking items, or using a single item entity to represent
many items of exactly the same type. For example, if you
kill a zombie and it drops 3 rotten flesh items, then a
stacked item automatically prevents 2 of the rotten flesh
items from spawning, instead marking the one item that does
spawn as a "stack of 3." If the entire server consists of
killing zombies, then you cut the number of entities
globally by 66%, which is a massive performance boost.

Regardless, developers often forget about this
functionality when dropping items. Items that are supposed
to be behind walls or otherwise not supposed to despawn
can be collected by players if they drop an item of the
same type. Oftentimes, developers try to fix this by
causing the oldest item to become the "stacked" item, but
this doesn't actually fix it either because then players
who accidentally drop their items will *lose* them instead.

In my personal opinion, it should be the burden of the item
stacking plugin to not mess up and stack up items it
shouldn't. The scope of these plugins should be limited to
high-impact actions such as mass mob drops rather than
items dropped by players. However, this cannot account for
every possible scenario. There are times where there simply
isn't a way around items being automatically stacked. In
this case, there must be a way provided to flag items your
plugin drops as "do not stack me." This usually comes in
the form of a persistent data container or some metadata
added to an item entity. It can also be some collection
provided by the item stacking plugin which other plugins
can use to blacklist items entities from being stacked.
There are no easy catchall solutions for this, and it just
comes with familiarity and anticipating how the actions of
other plugins need to coexist.

As a minor aside, the same sort of concept exists for item
cleanup plugins as well, which remove item entities over a
sufficient age to prevent item entities spawned an eternity
ago and never being picked up from taking up server memory
and CPU. You need to anticipate that the item you are
dropping might need to be persistent, so you need to both
cancel anything that picks up the item entity, destroys the
item entity, or item cleaning plugins from deleting the
item using any of the 3 different options I discussed above
(persistent data container, metadata or blacklist
collection).

# Custom Inventory Holders

I've made a fair few plugins where I've needed to make my
own "inventory holder." Things such as blocks that can
store items such as a mineral generator or custom backpacks
that are held by items.

This is again another place where you need to be careful of
people getting items or losing their items. First of all,
it is imperative that once you remove the inventory holder,
the you must also *close the inventory to all viewers as
well*. Otherwise, players with access to the inventory
after you finish managing it effectively extend the
lifetime of the inventory. Things such as automated mineral
generators will continue filling their inventory and
players may continue to place items into the defunct
inventory. One notorious example of this in the real world
is the inventory for managing NPC entities or minion
entities. If you do not close the inventory when the holder
is removed, then you can remove the holder an unlimited
number of times, thus "giving back" to the player whatever
item they used to spawn the holder.

As far as closing the inventories for each viewer goes,
I've written yet another blog post about this in the [2nd
edition](https://caojohnny.github.io/blog/2019/04/08/lessons-learned-debugging-part-2.html)
of this series. Make sure you don't hit any CMEs in the
closing of inventories, or you may still end up with a
duplication bug!

# Hoppers

Also note that players don't actually need to have
inventories open to take items away from them! The stock
containers in Minecraft such as chests are can have their
items hoppered out if checks on such exploits are not
implemented by developers. Private chests and sign shops
are especially vulnerable to this kind of exploit.

Again, the only real way to mitigate this kind of bug is to
realize the fact that most inventory handling code is
almost always flawed the first iteration. You can test all
you want, but if you don't specifically think about how
players take advantage of gaps in your logic, then you'll
never be able to test out this bug. Typically, when writing
inventory management code, I get a sense that I haven't
implemented a sufficient number of protection checks (e.g.
`InventoryMoveItemEvent`, `BlockBreakEvent` for blocks,
checks for where an inventory holder might be located in
case someone uses pistons, etc).

People are coming up with new concepts and new ideas every
single day, and there again is no catchall solution to
ensuring that your plugins are exploit free except for cold
hard experience.

# Conclusion

It's disheartening to have to be so vague about many of the
issues I see with my own code and how to fix them. In all
honesty, I myself have not come up with perfect solutions
for them all either. One of my own flaws is that I don't
actually play Minecraft all that often myself. I do try my
best to be up-to-date with the communities on the servers I
work for, but ultimately, I care a lot more about the code
on its own than the game. I definitely need to work on
that.

While less relevant to this post since I don't set any
rules (at least any hard and fast rules), this has been
the typical end note for the past 9 posts, so why not give
[The Power of Ten](http://spinroot.com/gerard/pdf/P10.pdf)
another go:

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


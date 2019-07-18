---
layout: post
title: "Lessons Learned Debugging: Part 6"
date: 2019-07-13T20:42:05-07:00
---

This is another one of those "watch out when you're doing
XYZ" rather than a specific thing to do (or not do).

# Be Careful Handling Inventories

Inventories are basically death traps in the world of
Bukkit programming. It is surprisingly easy to get
exceptions, duplication bugs (for the uninitiated: bugs
that allow players to obtain more of an item than intended,
often disrupting the in-game economy), and even [crash the
server](https://agenttroll.github.io/blog/2018/04/13/keeping-inventories-open.html)
just handling inventories and `ItemStack`s.

Writing event handlers for `InventoryClickEvent` and
dealing with any use-case for `ItemStack` should be
approached with caution.

# Exceptions in Event Handlers

As a reminder from the
[previous post in this series](https://agenttroll.github.io/blog/2019/07/02/lessons-learned-debugging-part-5.html),
exceptions thrown can cause problems. For example, when
event handlers modify the quantity of items as a result of
some action, an inadvertent exception may terminate the
handler before it reaches the portion of the code that
removes the item, or updates the inventory for that matter.
One way to get around this is to always modify the item in
whatever desired fashion, e.g. reducing its quantity,
before actually executing the action associated with using
that item. However, this isn't a perfect solution because
errors could crop up before, such as when you are verifying
the item type or pre-conditions. On top of that, that also
leaves server owners with the responsibility of either
refunding or replacing the items that are consumed but no
action is done in the case that the code following the
item modification fails.

Again, there isn't a catch-all solution to this problem. Of
course, exceptions will sometimes leak through the cracks,
as is with all programming errors. The key is to reduce its
frequency by taking care to think through the logic and the
possible edge cases that might occur.

As a real-life anecdote, one of the duplication bugs I had
to deal with was a `ClassCastException` because I didn't
account for the fact that both dispenser and dropper blocks
could fire `BlockDispenseEvent`. What happened was an
exception occurred before the item was supposed to be
removed from the dispenser, which means that it would get
dispensed as a result of the event failing to be cancelled,
and the item would not leave the dispenser, which allowed
people to have an infinite item generator.

# `NullPointerException`s Galore

Returning back to the basics, many novice programmers
struggle to use `InventoryClickEvent` and check items.
As someone who has frequented the Bukkit Forums and the
SpigotMC forums for years on end, I've seen countless
threads where `NullPointerException` is thrown simply from
checking the `ItemMeta`. Luckily, these days, it gets
harder and harder to find these threads, thanks to the
efforts to document nullability in the API.

Back before the more recent API versions, what was `null`
and what wasn't was basically guesswork that you needed to
keep stored in the back of your mind once you figured it
out. There are plenty of places you can quickly run into
trouble - starting from getting the inventory slot itself
to retrieving the `ItemMeta`, to the individual methods
like `ItemMeta#getDisplayName()`. This was further
compounded by the inconsistent use of `Material#AIR` to
denote an empty/no item. For example, in
`PlayerInteractEvent`, I believe that using `getItem()`
from the event would return `null` for empty, but
`Player#getItemInHand()` would return an `AIR` item. In
fact, `Inventory#getItem(int)` would return `null` as well
and any setter accepted a `null` item as empty, so the
inconsistent use of the `AIR` material obviously doesn't
make a whole lot of sense. Regardless, I digress. The point
is, even for more advanced programmers, the Bukkit
inventory API is still difficult terrain to navigate.

Honestly the best advice I can really give is find one way
to do things and stick with it. This is a controversial
view for obvious reasons; you should be experimenting and
all that. However, when you are writing code at a
professional level where results are expected and errors
are only tolerable at the very best, you should leave the
experimentation and use what you know works.

Honestly, you don't need to take it from my mouth how to
write better code. The "on-board shuttle group" writes
the code that launches astronauts into space. There is no
room for error when human lives are on the line.

> the on-board shuttle group produces grown-up software,
and the way they do it is by being grown-ups. It may not be
sexy, it may not be a coding ego-trip — but it is the
future of software. When you’re ready to take the next
step — when you have to write perfect software instead of
software that’s just good enough — then it’s time to grow
up.

([They Write the Right Stuff](https://www.fastcompany.com/28121/they-write-right-stuff))

This is especially true for an environment like Bukkit
development, where tests end at play testing and software
verification is virtually non-existent. The way you reduce
bugginess is by writing code right - the first time.

# Innocent-looking Code Might Still Fail!

Often, it is the most innocuous piece of code that fails.

Another anecdoate of mine is where a generator which
simply fills an inventory with valuable items such as
mineral (diamond/emerald/etc.) blocks. When it was removed,
it is possible for someone which you've given access to
the generator to retain the inventory. Although the
generator was removed, the generator's inventory was still
open. Because I assumed that the generator was unreachable
after removal, all of the items in the inventory would drop
on the floor so people wouldn't lose those items. To save a
bit of performance, I didn't clear any items from the
inventory because it could be arbitrarily big. However,
people doubled their payday by first having a buddy open
the inventory, before removing the generator. The buddy
still has access to all the items that dropped, and
collects both the dropped items as well as the uncleared
inventory.

The lesson here is simple: don't make any assumptions about
the code you are writing! It helps to try and write your
code to be *correct* the first time around - had I not
simply assumed the inventory would be unreachable, I would
have just cleared everything at the end. If someone
discovers this, it would then just be a UI bug and I'd just
need to make sure to close all of the
`Inventory#getViewers()` prior to dropping everything.
Don't prioritize performance over correctness. Ironically,
this was *still* not even the end of the story, because
closing the inventories from that collection caused a CME.
If you want to learn more about that, you can check out the
[second installment](https://agenttroll.github.io/blog/2019/04/08/lessons-learned-debugging-part-2.html)
in this series :).

# Conclusion

While I don't often get the chance to say this, I hope
you've learned something new from my own experiences. I
speak with very people who talk about my blog, so I can
only speculate as to whether actual people are truly being
impacted.

As is customary at the end of every post in this series,
I leave with the following wisdom from
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

Gathering information and learning is one way to
add to your repertoire of programming knowledge outside of
literally just writing your own personal projects. As you
gain more experience, you will write better and better
software. I promise.

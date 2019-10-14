---
layout: post
title: "Lessons Learned Debugging: Part 9"
date: 2019-10-14T01:27:30-05:00
---

The problem I usually see with novice developers when they
are debugging is that they test what their code is supposed
to do, but they are suprised when their code works when it
isn't supposed to.

# Check Your Code Isn't Running Inadvertently

It sounds ridiculous, but really think about it for a
moment. The majority of time, you are probably either
writing or fixing code that runs some kind of process or
logic. Only 1 or 2 lines of code are checking if all of
that code is even supposed to be executing. You don't
actually spend that much time on it. There are a variety of
different places this happens. In my case, I often forget
to check what item type the player is holding whenever a
`PlayerInteractEvent` or `BlockPlaceEvent` is being called.
This leads to the event handler logic being executed for
every single interaction, or a `NullPointerException` being
thrown if they aren't even holding anything. Another place
I've been burned by this is when handling
`PlayerCommandPreprocessEvent`, where I'm forgetting to
check what command is even being run. Every command then
causes the logic to be executed, even though the intention
was for only one command or one group of commands to be
handled.

# The Debugging Process

A large quantity of bugs I've found comes just from playing
the game normally. Usually, when people say they are
"playtesting," they are referring to testing one specific
thing or plugin. However, my argument is that many bugs
stem from the code running when it isn't intended to. The
problem with the aforementioned playtesting is that the
tester is specifically looking for something to happen
because they perform some action. The problem with this
targeted style of playtesting is that you can't tell
whether or not say, placing a specific block, will cause
the plugin to do whatever it needs to do, or if placing
*any* block will cause the plugin to do that as well.

This is why it is important to actually play the game as
if the plugin didn't exist for a certain time period. Sure,
it takes a little bit more time, and good programmers tend
to not make any mistakes in this area. However, I believe
there is merit to this even if you don't find any bugs.
When I play someone else's game and I run into a
game-breaking bug, I sometimes feel like the developers
don't even play their own game. Bugs that are obscure to a
developer are often obvious to players because it impacts
standard gameplay. When you say,"that didn't come up in
testing," of course it fucking didn't, because if you are
playtesting just to test the plugin, you were playing the
game in the way that a developer would, not a player. Finding
the bugs from a development standpoint is important, but you
need to recognize who your product is targeted towards: the
player. The point of all this is to say that you should play
your own game *as a player would* for some fixed minimal
amount of time as a part of the debugging process. It
doesn't even need to be that long, 15-30 minutes should do
it.

One example of this is when I was writing a hack around
dispensers firing EXP bottles. However, I didn't notice
the fact that droppers could also fire EXP bottles as well.
This lead to a `ClassCastException` as I tried to cast a
`Drpper` to `Dispenser`. In hindsight, this was a stupid
mistake on my part because one should always typecheck
before doing a cast. However, this is something that would
have easily been caught if I just played the game on the
same server that the players used. When I was testing this
plugin in a controlled test server, I couldn't account for
what other players were doing. Had I instead tested on the
same environment that players were actually using, this
would have easily been found before being deployed. This
brings us to another point about how the testing
environment should as closely replicate the production
evinronment as possible, but that is a topic for another
blog post.

# Fix Your Thinking

On the other hand, fixing the fact that your code might be
running inadvertently during development rather than
testing requires a lot of practice. It took me almost a
full year to really start hitting all the conditions on a
consistent basis. You need to spend almost as much time
thinking about the conditions at which you are either going
to "do" or "not do" any subsequent actions as the amount of
time you are spending actually writing those actions.

One thing that helps immensely is to use `if-return` blocks
rather than building a long chain of `if`s. For example:

``` java
@EventHandler
public void onEvent(...) {
    if (...) {
        if (...) {
            if (...) {
                // Logic
            }
        }
    }
}
```

Prefer something like this:

``` java
@EventHandler
public void onEvent(...) {
    if (!...) {
        return;
    }

    if (!...) {
        return;
    }

    if (!...) {
        return;
    }

    // Logic
}
```

Writing your code this way forces you to invert your
thinking in a way. Instead of thinking, "if this is the
case, do this," you need to think "if this shouldn't
be done, then return." This is significantly more effective
because it drastically simplifies your logic.

Sure, it takes up more lines of code. Sure, it's a little
more writing. However, not only does it separate the
conditions and control flow from your actual execution
logic, it reduces the indentation of your code. It makes it
significantly easier to read. When you isolate your control
flow in this way, it is easier to see what conditions you
are constantly checking for. This makes code review so much
easier. Once you hit some condition that doesn't hold true,
you don't need to think about it anymore since you
`return`.  On the other hand, if you have several nested
`if` statements, the reviewer has to keep all of the
conditions in their head because all of the previous
statements impact all of the logic afterwards as well.
Finally, conditions are common accross many different types
of event handlers and situations. If you can easily build a
repertoire of conditions you are checking really often over
time, it will be harder for you to forget in the future.

The list of benefits of using `if-return` keeps going on
and on. I cannot stress enough how beneficial this
technique is.

# Condition Counting

As an interesting side discussion, I want to include an
excerpt from
[They Write the Right Stuff](https://www.fastcompany.com/28121/they-write-right-stuff),
an article that discusses the lengths that the authors of
the Space Shuttle software go to in order to ensure that
their code is bug free:

> The group has so much data accumulated about how it does
its work that it has written software programs that model
the code-writing process. Like computer models predicting
the weather, the coding models predict how many errors the
group should make in writing each new version of the
software. True to form, if the coders and testers find too
few errors, everyone works the process until reality and the
predictions match.

While I think that bug-finding models of software are a
little extreme for writing plugins, especially when lives
aren't exactly at stake here, I think think there is still
merit in the idea of expecting there to be some number of
conditions. As you get more experienced, you'll probably
get a feel for how many `if-return` statements you should
be writing. If you think there are too few, your intuition
might be indicating something. I'm not saying that I can
clearly advocate for consciously thinking about this, as
you are writing code. I certainly don't. I the situations
vary far too much for this sort of thing to be worthwhile.
That being said, it would be a lie for me to say that I've
never thought something along the lines of "I don't think
that's enough code." Something that looks too good to be
capable of handling all edge cases may well be!

# Conclusion

There are a variety of techniques you can use to mitigate
the bugs involving logic that shouldn't be run from
creeping into your code. This includes playtesting as a
player would, using `if-return` statements, and possibly
condition counting if you are interested in a little
exercise.

These blog posts probably will come with less frequency in
the coming months since I want to focus on college. I've
also got my current personal project,
[`gate`](https://github.com/AgentTroll/gate) that I'm
desparately close to finishing and I want to complete, so
I'll probably be focusing on that, then on my newest
project, [`liftoff`](https://github.com/AgentTroll/liftoff)
before focusing back on blogging and finishing the
On Thread Safety post that continually is on TODO...

As always, I always leave readers with the following quote
from
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


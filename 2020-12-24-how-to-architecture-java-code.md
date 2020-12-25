---
layout: post
title: "How to Architecture Java Code"
date: 2020-12-24T18:00:13-04:00
---

I bring this up a lot, but my experiences trawling through
programming forums such as SpigotMC's Plugin Development
section has allowed me to read a lot of code written by
novices. Of the many recurring themes that I see, the lack
of a solid *architecture* or a system-level design comes up
relatively often.

And again, as I often bring up, this is not necessarily the
fault of the novice developer. Indeed, from what I have
seen of the work of CS majors, even the education system
has difficulty grappling with the code design aspect. But
since I am not a CS major, I would avoid putting too much
weight in this observation; however, the point still stands
that many novices don't really know how to architecture
their code.

As with my [prior post](https://agenttroll.github.io/blog/2020/11/10/how-to-be-a-good-programmer.html),
I attempt to show how to *think*. It is easy to memorize
algorithms, design patterns, whatever. But, it is difficult
to analyze and structure your code, because you need to
fundamentally change the way you *think* about the code.

# What is code architecture?

I will primarily address code architecture in Java. The
same concepts may apply to other similar languages,
especially if they are Object-Oriented Programming (OOP)
languages as well, but I make no guarantees to those
applications. I will place particular emphasis on Bukkit
plugins as they provide an extremely easy application of
Java architectures as there are many components that are
already understood by many people.

I have mentioned this in passing already, but code
architecture is the design of your code - the structure
of your code. The way that classes are related to one
another, how classes are initialized, managed, destroyed,
etc.

While this sounds relatively simple, it is very easy to
write code that is nonsensically structured. It takes time
to architecture code, time that you could instead be using
to writing the actual code itself instead of structuring
and moving things around. It sounds like a complete waste
of time.

# Why should I care about code architecture?

The most basic way of looking at this is that poor
application architecture is a problem. You should avoid
having problems with your code.

Poor code architecture makes code difficult to read and
understand. It hides mistakes and obfuscates your code.
It is inflexible and hard to extend or modify. It makes
utilizing your code awkward both to yourself and other
developers.

While carefully architecturing your code may take a bit
more initial time, you will end up saving time as it will
be easier to debug and extend later on.

Most importantly, well-architectured code makes writing
code more fun.

# How do I architecture my code?

#### Hierarchy

The first thing to think about is always hierarchy. Every
Java program only has a few entry-points, if not only 1.
What this means is that although your program might have
many different functions or components, all of them must
eventually come from a single place, i.e. the
`main(String[] args)` method.

Therefore, there must be a hierarchy of some sort. The
most fundamental structure is that the program's
entry-point sits above every other function of the program.
A complex program can have multiple "layers" to the
hierarchy. For example, a Bukkit plugin will have its plugin
`onEnable()` at the top, then followed by perhaps different
modules, each module will have its own commands and
listeners, and beneath those might be configuration files
and different methods of storing data.

The point of the hierarchy is to keep management of object
lifecycles controlled. An object at any level of the
hierarchy may only be permitted to manage the relevant
objects *strictly* beneath them in the hierarchy. I say
strictly because this precludes the use of
[singletons](https://stackoverflow.com/questions/137975/what-is-so-bad-about-singletons)
from a design standpoint (though I shouldn't have to remind
readers that there are exceptions to every rule - read the
last post on How to be a Good Programmer!)


For example, consider a `Listener` class that keeps track
of a collection of `Player` `UUID`s and a `DataManager`
that is supposed to save that collection of players when
the server is closed:

``` java
// WARNING: BAD CODE AND BAD DESIGN!

public class PlayerUUIDListener implements Listener {
    public static final Collection<UUID> playerUuids = ...

    ...
}

public class DataManager {
    public void save() {
        for (UUID playerUuid : PlayerUUIDListener.playerUuids) {
            ...
        }
    }
}
```

There are a few issues with this design outside of the
architecture alone; however, for the sake of brevity, let
us concentrate on just the architectural issue at hand.
The `DataManager` class manages the lifecycle of another
class because it accesses the `playerUuids` field to save
it on shutdown. We would expect that `PlayerUUIDListener`
is beneath `DataManager` on the class hierarchy, but that
doesn't make any sense. If you were to add another class
that relies upon `playerUuids`, then it must either be at
the same level of `DataManager` or both `DataManager` and
the new class must be at the same level as
`PlayerUUIDListener`. These are both undesirable outcomes
because they jumble up the organization.

However, we could solve this problem by placing the
`DataManager` beneath the other classes like so:

``` java
// WARNING: BAD CODE BUT GOOD DESIGN

public class PlayerUUIDListener implements Listener {
    ...
}

public class DataManager {
    public static final Collection<UUID> playerUuids = ...

    public void save() {
        for (UUID playerUuid : playerUuids) {
            ...
        }
    }
}
```

That way, any accesses to the `playerUuids` from other
classes strictly defer to `DataManager`, where all the
other management code is located. This design makes a lot
more sense and permits for better encapsulation, which
would eventually fix the bad code aspect of the snippet:

``` java
// GOOD CODE AND GOOD DESIGN

public class PlayerUUIDListener implements Listener {
    private DataManager dataManager;

    public PlayerUUIDListener(DataManager dataManager) {
        this.dataManager = dataManager;
    }

    ...
}

public class DataManager {
    private final Collection<UUID> playerUuids = ...

    public Collection<UUID> getPlayerUuids() {
        return Collections.unmodifiableList(this.playerUuids);
    }

    public void save() {
        for (UUID playerUuid : this.playerUuids) {
            ...
        }
    }
}
```

To continue further with this, let us move to the next
topic on abstraction.

#### Abstraction

Abstraction is absolutely key for designing software.
Firstly, it permits you to control access to objects and
state fields in the form of encapsulation. Secondly, it
increases flexibility because it prevents users from
relying upon concrete implementations. Finally, it reduces
bugginess because it reduces the mental overhead of having
to think about what methods and classes *are*, only what
they *do*.

Personally, I use abstraction also for increasing iteration
cadence when writing code. I generally work from the top of
the hierarchy down. When I get to the hard stuff, things
like managing data or large amounts of logic or conditions
on data, I will simply write an interface and keep moving
on.

What this would look like for the above code snippet is the
following:

``` java
public interface DataManager {
    void save();
}
```

When I start writing my `PlayerUUIDListener`, I could do
something like:

``` java
// WARNING: QUESTIONABLE DESIGN

public interface DataManager {
    Collection<UUID> getPlayerUuids();
    void save();
}
```

However, that depends on what I'm doing. Here, I have
provided a generic method of getting a collection. This is
a step in the right direction, as many novices would return
a concrete `List<UUID` or even `ArrayList<UUID>` for
example. On the other hand, what if I wanted to specify an
index-accessible collection? One option is I could use a
`List<UUID>`.

However, a `List<E>` provides the `add(...)` method, which
is unenforcable at compile-time. In certain circumstances,
I may even consider doing something like:

``` java
// POTENTIALLY BETTER DESIGN

public interface DataManager {
    UUID getPlayerUuid(int index);
    void save();
}
```

That way, the fact that the list is read-only is guaranteed
at compile-time; though this will expose you to potential
index bound exceptions. Collections are pretty common to
expose, so it may be still be worth considering abstracting
away even access to the collection itself. On the other
hand, you can also consolidate methods into a collection
and go the opposite direction if it suits your needs
better. This is where that brain of yours comes into play,
you need to decide what design results in more sensible
code for your specific purpose.

Once I have completed writing all of my other classes, I
will generally write some dummy code in the place of the
`DataManager` and provide that through dependency-injection
so I can easily swap between implementations:

``` java
public class DataManagerImpl implements DataManager {
    @Override
    public UUID getPlayerUuid(int index) {
        ...
    }

    @Override
    public void save() {
        ...
    }
}
```

This technique of using abstraction to increase development
cadence is extremely flexible, fast and is generally a joy
to write. I don't need to worry about writing all of the
boring code until the end, and the easier code is a lot
more enjoyable to write because I'm able just to speed
through writing it from all of the interfaces I've written.

There are even more forms of abstraction than simply
structuring your methods. For example, you can abstract
data fields into wrapper classes. This is a deceptively
useful way of managing data, you should always create
wrappers to represent things that have a function outside
of what the data types suggest. This can be seen in action
[here](https://github.com/AgentTroll/sched-temporal-test),
where I create a wrapper for a single counter variable
because it represents more than simply a `long` type; it is
a counter that only makes sense if you know that it
represents in-game ticks.

Another form of abstraction that you may consider is
modularizing your code.

#### Modularity

I consider modularity so important that it deserves its
own mini-section. On a smaller scale, you should aim to
self-contain the function of your class. So long as the
class is responsible for a "single" thing, you want as
much of the function to be hidden away from other classes
as possible. On a wider scale, entire portions of the code
can be sectioned-off in a way to prevent other modules from
knowing about the state of those modules.

For example, there are many times where I have written
plugins that consolidate multiple different kinds of events
or gamemodes under a single codebase. In that case, I will
generally have an abstraction for each kind of event and
put all of the code relating to that event under its own
module. All of the listeners, the commands, the tasks, the
data, the configuration, etc. belong to the module for each
specific event. That way, when the module is set up, the
code is organized around that module is initialized
together and then cleaned up together at the end.

In general, when people think of modular code, they believe
that its usefulness derives from being able to turn modules
on and off without affecting other parts of the codebase.
While this is certainly true to an extent, I very rarely
use modules this way. In fact, I very frequently
communicate between modules anyway so this might not be as
compelling of a reason as you'd think. The main benefit
that I find from modularity is that modular code is just
much simpler to read and understand. Because a module is
self-contained, I can safely ignore most other modules
because I know those are self-contained as well. I only
need to think about a single module at a time. If I get a
bug in one aspect of my application, I can narrow down
the cause of the error if I know which module handles that
function. Again, because modules are a form of abstraction,
all of the benefits of abstraction that I've discussed come
along for the ride as well.

At a high-level, you could use Maven modules to separate
code that is actually meant to be interchangable, such as
[for NMS](https://github.com/AgentTroll/lagger). At a lower
level, you could have separate packages to do something
similar to the events plugin I discussed earlier. One
example of this can be found in a [benchmark suite](https://github.com/AgentTroll/microopts/tree/master/src/jmh/java/io/github/agenttroll/microopts),
where packages are self-contained and do not use code
from other packages or "modules."

# Conclusion

I've summarized a few key concepts for architecturing your
code. There are a lot of important concepts in OOP
languages that many novice developers don't really know how
to use outside of just theoretical applications. I hope
that with concrete examples and an explanation of how I
personally design my programs to work well in the field,
you will have gained a better understanding of how to
architecture better code. In case it might not be obvious,
the only way to tune your sense of design is to practice,
practice and practice some more. Even more importantly, you
should have your code reviewed. Practicing the wrong
concepts only solidifies bad design choices, so always look
for ways to critique your own code as well as for others to
critique your code for you.

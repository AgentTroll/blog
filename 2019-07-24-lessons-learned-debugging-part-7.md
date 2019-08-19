---
layout: post
title: "Lessons Learned Debugging: Part 7"
date: 2019-07-24T00:07:20-07:00
---

I haven't explicitly identified it until now, but it seems
that I have a habit of putting exactly the same thing in my
introductory paragraph in basically all of the posts in
this series. This particular lesson doesn't sound all that
bad at first, but I can assure you that I have literally
crashed a server by not following it.

# Strongly Consider Whether You Can Put Something In a Shared Library

There are so, so many benefits to having a centralized
core library you can depend on for your plugins with
virtually no drawbacks whatsoever.

The first thing that comes to mind, of course, is having
a set of pre-written classes available to you. For example,
menus, handy utilities for things such as I/O, databases,
and data management primitives. Chances are, if you are not
using a central library, you are writing a significant
amount of boilerplate in your non-trivial plugins. If that
is the case, you should consider generifying what you have
written so that it fits the purpose of multiple plugins.
Although you might be spending more time now trying to
write part of your core library and also the plugin that
currently needs it, you will spend less time writing the
same boilerplate later on. You can significantly increase
productivity if you aren't stuck writing basically the
same thing for every plugin you write each time you write
a new plugin. Secondly, it is inevitable that you will
make mistakes, and as hard as I try to push for care and
slowing down to think through your code, even I myself
make mistakes as well. If you are writing similar or even
the same code on each of your plugins, ALL of your plugins
need to be updated in the case that you find out you've
been doing it wrong the entire time. On the other hand, if
all of your plugins depend on just one library, you only
need to fix the bug once. The counterargument is often that
you can minimize the impact of a mistake if you spot it
when you write the same thing again. However, this is
wishful thinking. This is not how it works in the real
world. I would strongly argue that writing boilerplate is a
mindless activity. You are not likely to catch that you are
making a mistake if you are writing the same code you wrote
last time. On top of that, the more you get used to the
same workflow, the more complacent you become, and more
importantly, the bigger the cost of fixing that said code
once it breaks. Think of it this way: if you only write the
code once, then you only have that one chance to make a
mistake. If you are writing the same code over and over
again, you take that risk every. Single. Time. Thirdly,
even if you Ctrl+C and Ctrl+V your code, there are still
no guarantees. It might work for small snippets of code,
but once you get to large amounts of boilerplate such as
when writing inventory GUIs for example, then things start
to fall apart. You *still* suffer from the possibility that
the snippet you've been copying from is also wrong as well.
You are not only duplicating what works across your entire
codebase, you are also duplicating anything that
potentially doesn't. Again, the impact of a bug can be
mitigated, but the cost of fixing it cannot. Do yourself a
favor. When you are writing a lot of boilerplate that can
be abstracted away, consider putting it on your core
library.

A core library is not only good for putting your own code,
but the code of others as well. You can shade various
common dependencies into your core. The following argument
is terrible, for obvious reasons, but you are reducing the
total JAR sizes of all your plugins if only the one core
plugin contains a big library. But, for those of you who
are for some inexplicable reason scared of large JARs, then
throwing everything into one super JAR file might help
settle your conscience. For me personally, I need to
configure certain libraries such as Guice that need their
own namespaces each time I shade it using Maven, so it
helps if I don't even need to write anything extra by
using a `provided` dependency on the central library. This
isn't to say that you should put every single dependency in
your core library, but commonly used libraries like
HikariCP are always helpful to have lying around,
especially when a significant portion of your plugin
ecosystem might depend on it. Again, I'm going back to the
JAR size argument, but it also can't hurt to reduce the
amount of time it takes to download every other plugin if
only the super JAR takes a long time since it has all the
libraries shaded into it.

Finally, a core library can be used to enforce a specific
standard or policy. For example, if you are including
MySQL utilities, you can use the `config.yml` to provide
the MySQL credentials to all the plugins using that core
library. The server owner will not need to configure the
credentials more than once. Secondly, by having a library
of different utilities, you can centralize the way a
certain action is performed. For example, you might want
to make sure that caching is done in a particular way, or
that all of the caches used on the various dependent
plugins are configured to have a specific eviction time.
By including this into the core library, you can enforce
that specific policy on all of your plugins. You can even
have a hierarchy of core plugins if certain developers
prefer some other ways, or would like to use open-source
core libraries instead. By changing specific portions of
their desired library to comply with the "master" core
library, they can use both the "master" and their custom
core in conjunction, or simply utilize the custom
library if the desired features are fully reimplemented.

It may actually take longer to maintain a core library
if you are developing it alongside whatever plugin
you need to complete because you are abstracting away some
feature, but I can assure you that this effort is well
worth it. Because your core library matures in the long
run, it is a net gain rather than a loss as it becomes more
and more useful. Had I have had the foresight to write my
boilerplate into a centralized library, I would not have
crashed servers and caused multitudes of plugins to have
independent visual glitches as a result of making one
mistake.

# Conclusion

As has been tradition, I leave with the following from
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

I've recently become more interested in Internet privacy.
I consider myself to be relatively informed on the topic,
but there are a lot of things that I've found that I didn't
know about within the past few weeks. I'll be doing a post
on that soon, because I think it is an issue worth talking
about. And for readers who don't think privacy is an
important issue, I only ask that you hear me out. I'm not a
popular blogger by any means, so if you are reading my blog
in the first place, that probably indicates that you don't
have anything better to do anyways. I encourage you to use
that time to become at least a little bit more informed :).

# Addenum 2019-08-14 03:15

I hadn't actually thought of this earlier, but I've
recently run into another situation where a standardized
library would have made life a lot easier. Especially in
teams with several developers, having a core library can
make life significantly easier because having a single
standard paradigm for accomplishing one task not only makes
the code significantly easier to understand and parse, it
will help reduce bugginess because it will also be easier
to review. Because you can be assured that some portion of
the code works, it will make debugging and code review
significantly easier and cut down drastically on the time
needed to identify problem points.


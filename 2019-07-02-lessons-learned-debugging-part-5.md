---
layout: post
title: "Lessons Learned Debugging: Part 5"
date: 2019-07-02T20:22:15-07:00
---

This isn't a bugginess lesson, but if you're ever going to
progress beyond a novice-level plugin developer (or even a
Java developer for that matter), then you'll need to figure
out how to ensure data integrity.

# Minimize Data Loss In Case of Catastrophe

This is not a very pointed piece of advice (more on that in
a bit), but the whole idea is to design your plugins around
making sure that as much of your data is kept somewhere
safe so that in the event of a catastrophe, a bad weather 
event knocks out your server, you get hacked, your server
crashes, etc., you can recover at least some, hopefully
most of your data. This isn't some external threat that you
can hope to avoid, this is **inevitable**. You cannot hope
to continue avoiding these types of events forever, and 
take it from me, I learned it the hard way.

If you are writing plugins and getting paid to do so, you
MUST have some sort of mechanism to minimize data loss.
Servers fail all the time; it is not a matter of if, it is
a matter of when. It is not a choice, it is a 
responsibility.

# How to Protect Your Data

The most effective way to minimize data loss is through
autosaving to disk. Autosaving writes a reconstructible
state, which means that the exact properties, settings,
objects, whatever type of data being stored in your plugin
at the exact moment in time can be derived from the data 
that you save. This means that you should act like your 
plugin is calling then `onDisable` method without actually
having the server shut down every X minutes. It should not
be up to the developer to decide how long the autosave
interval is, and therefore, this should be configurable.
That being said, 15-30 minutes is a good sweet spot. 
Writing data to disk ensures that the data cannot be lost
if the server itself crashes, or a power outage occurs.
Even if a disk failure occurs, data can sometimes be 
recovered from the disk. Preferably, *secure* backups are
made every so often as well, which means that it is 
possible to snapshot the disk state and prevent the 
autosaves from going to waste even if the disk is
inadvertently destroyed, or access to the server is 
completely lost or deleted altogether.

It is important to note that even autosaves are a point of
failure. For example, the following code is not an 
effective way to save data:

``` java
try (BufferedWriter writer = ...) {
    for (Data datum : this.data) {
        writer.write(datum.serialize());
    }
} catch (IOException e) {
    e.printStackTrace();
} finally {
    if (writer != null) {
        writer.close();
    }
}
```

The problem is that multiple things could possibly go wrong
here. It may not even be possible to open a new 
`BufferedWriter` if the OS exhausts the available file 
handles. A more effective solution looks like this:

``` java
try (BufferedWriter writer = ...) {
    for (Data datum : this.data) {
        try {
            System.out.println(datum.serialize());
        } catch (Exception e1) {
            e1.printStackTrace();
        }
    }
} catch (Exception e) {
    for (Data datum : this.data) {
        try {
            System.out.println(datum.serialize());
        } catch (Exception e1) {
            e1.printStackTrace();
        }
    }
}
```

This way, even if the file cannot be written to, at least
it might possibly be recovered by parsing the log file or
by piping the console output somewhere (the parser of this
data need not be written beforehand, but the data itself 
should at least be available). Additionally, even if 
individual `Data#serialize()` methods fail, it will not
prevent other data from being saved.

Plugins also need to be extremely careful about exceptions
thrown in the `onEnable` method. Because errors during 
startup cause plugins to be disabled (often with empty 
data), this means that the data file will be overwritten
because of a parsing error and all the data will disappear.
However, ignoring this error is also problematic because it
will not prevent the plugin from overwriting all of the 
data on shutdown with the new data. There are multiple
avenues to solving this, including backing up every server
startup, using a ring buffer style system where the file
is copied to a (or multiple) temporary files each time, or
by using a log file that records changes rather than a
file which records the singular state of the plugin. The 
most effective solution I personally am aware of is the
second option, where temporary files are used to store a
backup of the data, but only in case an exception occurs:

``` java
public void onEnable() {
    ...

    try (BufferedReader reader = ...) {
        ...
    } catch (Exception e) {
        Files.copy(..., ...);
        e.printStackTrace();
    }

    ...
}
```

This isn't perfect, because the exception could possibly
stem from the fact that file handles have been exhausted,
so the "safest" option is going with a backup every 
startup, but this is a lightweight solution for what a
rather serious potential issue, so I personally go with it.

Another useful way to ensure data integrity is to turn off
autorestart. Autorestarting is really helpful and keeps 
players happy when a server goes down due to a one-off 
error, but in the long run, the safest option is to make 
sure that a server that goes down stays down until the 
issue is identified. The issue doesn't necessarily need to
be entirely resolved (only a band-aid needs to be put over
such as removing a plugin while it is fixed), but ensuring
that plugins do not start up again only to enter an endless
loop of crashing the server and starting it up again will
ensure that the data that is backed up stays until it can
be properly restored and the error can be properly
investigated. For example, if you are saving in the 
`onEnable` to the same backup file whenever an exception 
is thrown, then it will do little good for you because the
autorestart might erase both the original and the backup as
well if the original is now empty.

These are just a few of the pointed pieces of advice I
have. I'm certain that there are more ways to reduce data
vulnerability, but this is a very broad problem that has
a large variety of different solutions.

# Conclusion

Just because autosaving is an integral part of maintaining
data integrity does not mean that you need to be paranoid.
However, it does mean that you need to be prudent and look
use extra caution when writing mission-critical portions of
your plugin.

Again repeating my custom, I leave with the following wisdom
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

If you're tuned in with my blog, you can expect some more
of posts in the "Lessons Learned Debugging" series in the
near future. I don't have any big projects that I want to
talk about (yet), but if I find or write one, I'll be sure
to write about that first. As of the writing of this post,
I'm still open to Bukkit development opportunities, so if
you're hiring, check my 
[main website](https://caojohnny.github.io/) under 
"Professional Experience" to see if I'm still looking for
work.


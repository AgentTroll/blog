---
layout: post
title: "How to Store Data"
date: 2021-1-1T02:40:03-07:00
---

As I preface in many of my blog posts, the information
I present will apply to Java applications, and in
particular, Bukkit plugins.

A very common question that I see asked on the SpigotMC
forums is how to persist data. Minecraft servers see on the
order of magnitude of a dozen or so to hundreds of
thousands and millions of players at the upper echelons of
the industry. Developers want to write robust plugins that
can persist the state across server reboots, crashes, etc.

So what is the best method for doing so? What
considerations are relevant? How do you design data
persistence?

# What are you storing?

The first step in determining *how* to store data is to
figure out *what* data you are storing. Different kinds of
data follow different patterns which you can exploit to
store them more effectively than you would if you just went
with a generic solution. Things such as what type of data,
how much of that data and how quickly you need to lookup
or store that data are relevant considerations here. If you
are not able to answer these questions, it is worth either
stopping here and *figuring them out*, or alternatively,
*making some assumptions*.

Being a good engineer requires you to collect data and to
make observations. If there is more information that is
available but you don't know, you want to figure out that
information. Once you have this information, you can begin
to filter out and extract the relevant details that you
need to solve the problem.

With that being said, there is some information that you
simply can't know in advance. You can't know what kind of
data might be needed for future features that aren't
planned yet, for example. Some people also don't know how
much data they need to store. When I ask, they usually
respond with something like "I don't know" or "unlimited,"
both of which are equally unhelpful answers! A good
engineer responds to this situation by making assumptions.
Assumptions are educated guesses based on your current
knowledge that would put you in the ballpark of what you
would expect something to be. An assumption can also be a
safe upper bound that would tolerate a range of
circumstances.

Let's say you are storing some kind of player data.
Obviously, this would be tied to the number of unique
players. Based on my prior knowledge, within the span of
around 6 months, maybe 20,000 unique players will join the
server for a given server capacity. In the real world, this
number might be highly unrealistic to surpass based on
things like how big the server is, how much promotion and
advertising the server owner decides to undertake and such.
This would therefore be a safe upper-bound for me to design
my data storage. 

More importantly, what this allows me to do is set a 
*testable* objective. I would be able to better simulate
and test the capacity of my data storage method by
designing and implementing my data storage method and then
loading it with this exact number of data entries to see if
it functions correctly. A good engineer evaluates their
assumptions and then changes their goals accordingly
through design iteration. If my design holds up and there
is room to spare, then I have basically built a tolerance
into my design. On the other hand, if it fails because it
became overloaded, I will know that I have either selected
a faulty method of storing data or I have implemented it
incorrectly. I will then reiterate and then start with a
new plan to debug and then re-design.

With that out of the way, let us take it one step at a
time. Once you have gathered and figured out the details
about your data, how do you use this to inform your
decisions?

# What do you store data with? 

In general, terms you will encounter two kinds of data
storage methods in the Bukkit plugin ecosystem: files and
databases. Among them, there are many different subtypes
and formats which you may have heard of:

  * Files
    * Text
      * JSON format
      * YAML format
      * HOCON format
    * Binary
      * NBT format
      * GZIP NBT
      * Schematics
      * Images
  * Databases
    * Networked
      * MySQL
      * MariaDB
      * MongoDB
    * Embedded
      * SQLite
      * H2
      * Derby

The method you use to store data depends largely on your
goals. There are many times where these goals will compete
with one another, but you will need to decide which gets
priority depending on your constraints. In engineering, a
constraint is something that would immediately rule out a
solution. One common constraint is memory - you cannot
exceed the amount of memory your server has or the amount
of hard drive space you have, etc. Can you see how the
information discussed in the last section, such as what
data and how much data become relevant here?

#### Memory

You can use your assumptions and information to compute
how much memory is consumed from storing your data. If this
amount of memory exceeds your disk space, you have already
ruled out text files - those will necessarily take up more
space. On the other hand, if it does not exceed your disk
space, you would want to use a file because it is much
easier to set up - you don't want to end up having to
engineer a more complex solution involving databases if you
don't have to.

Let's say you have a lot of data, so much that it exceeds
your disk space. You could consider binary files, which
are capable of being compressed. You could also consider
using a database, which incorporate their own formats and
or compression if you desire. You could also consider using
a networked database with a larger disk than your server.
Between these options, you could select from a whole host
of other considerations such as server availability and
performance as necessary.

#### Performance

The pervading goal in data storage is performance. However,
as is tradition, performance is a very complex topic to
discuss, especially so for data storage.

I have written a test suite between different storage
methods [here](https://github.com/caojohnny/data-benchmark)
if you are curious where I get my performance data from or
if you want to test for yourself what methods work the best
on your machines. After all, with different kinds of hard
drives, SSDs, NVMe M.2s, etc. you will be bound to have
differing hardware performance characteristics that
propagate into your data storage.

In terms of pure storage format (between files and
databases), files will generally have better write
performance, while databases have better read performance.
In general, the most noticable difference in performance
will be read performance; i.e. it is better to have fast
reads than it is to have fast writes. In terms of user
experience, if you have slow writes, no one really cares
because you can just queue up the write for later and then
nothing else happens. However, if you have slow reads, then
players will have to wait for your plugin to respond to
something that involves the read. Things such as sorting
data (top balances, top points, top whatever statistic, for
example) have a more noticable response than for writes
to data storage mediums. This is why I encourage people to
generally prioritize lookup latency.

With that being said, the lookup latency from the data
storage method itself is not the only consideration because
it is possible to get even better response times if you
cache or preload. Retrieving objects from memory is
significantly faster than retrieving directly from the data
storage medium because it requires no I/O; you don't need
to wait for the OS to respond to syscalls or network
traffic or anything. The point is, if you aren't doing
lookups directly from the data storage, then the fact that
database lookups are faster than file lookups is irrelevant
if you can just preload the both of them to equalize the
impact of lookups. In other words, if you preload your data
into memory anyways, the lookup performance from the data
storage doesn't matter except for the load time of your
plugin, which is mostly unimportant (and can be alleviated
because you can just do it in parallel with other plugins
booting as well).

For the sake of argument, let us constrain ourselves to
having to load directly from the data storage medium. In this
case, the problem with loading from files is that data is
usually flat-mapped into files. This means you need to load
the entire file in order to read perhaps only a small
portion of it. There are ways to get around this, obviously
such as by seeking through using a `RandomAccessFile` or by
splitting up a single file and organizing your data file by
file. For example, many plugins will have a player data
folder containing one file corresponding to each unique
player containing just their data. However, both of these
"solutions" introduce complexity and fragility. 

A database is superior to files because a properly
organized database can be easily modified in bulk using
SQL. Databases provide many guarantees such as atomicity
and are robust and fault-tolerant. Storing files requires
you to manually handle errors with data storage and are
tough to modify in bulk. You need to write your own tools
to manage or upgrade your file data if you need to lookup
by file. In other words, the "solutions" to slow file reads
is fixing a problem you created by selecting files to do
something a database is far better at doing. For databases,
read performance is baked in, you don't need to hack it in
as you do with files.

Another potential consideration with databases is with
connection latency. For networked databases, SQL queries
cross a network hop and back to reach the database. This
may not be a relevant concern if it is co-hosted or
co-located. However, even if it was relevant, you could
still avoid the network hop and use a database with
embedded options such as SQLite. Embedded databases run
locally within your plugin and are basically glorified file
abstractions as they save directly to a database file. This
is also an option if you don't expect to be running a
networked database at all - some servers choose not to run
MySQL or MongoDB and such.

Again, the lookup performance straight from data storage
only matters some of the time. When it comes to
performance, you **must measure**. It is not good enough
to go with general rules of thumb. I linked my test suite
above, which is a good place to start. File and database
performance can be comparable at small data sets and with
a sufficiently fast hard drive. Performance testing is hard
and there are many pitfalls - if you are not sure, ask!
This is way outside the scope of this this blog post alone,
so again, reference the test suite I linked.

#### Implementation

The third and final goal I'd like to cover is ease of
implementation. Even though I enjoy using databases, I have
no doubt that using a file would be a lot easier most of
the time. Databases require some work to get set up and
debug in comparison to using files, and the API just isn't
as nice to use as it is with files.

With that being said, ease of implementation comes
secondary to just Using The Right Tool For The Job. If my
other goals all point to using a database, then it would
probably be eaiser for me to go with the database than to
deal with the fallout of having to re-write my entire data
management system down the line, for example. But if I
don't need to use a database, I sure as hell would not be
using one.

For example, if I were not storing player data or 
relational data, then I would simply just use a file. Some
kinds of data aren't the kind that you organize in a useful
way in rows and columns. If it isn't a collection of
something, it might be better to store it as a file. This
applies within the different formats and types of files and
databases as well. For example, if you were storing
something with a flexible schema, perhaps a NoSQL solution
would be better than a relational database (i.e. something
like MongoDB would be better than MySQL).

With those considerations out of the way, hopefully you
will have been able to select the data storage method that
fits your goals. With that being said, how do you choose
the way that you store and load it?

# How do you cache and store data?

As far as runtime performance is concerned, caching and
storing data is much more important than the storage
medium. As I briefly mentioned in the prior section, the
differences between different data storage methods are
nullified through techniques such as preloading. So how do
you determine what techniques to use?

#### Loading data

Loading data entails reading data from your data source and
then organizing it in memory with something like a
`HashMap`. The way that you organize and ensure
thread-safety for this sort of thing is out of scope for
this blog post, but is a difficult topic nonetheless. I
would recommend a read through [this](https://www.spigotmc.org/threads/how-can-i-improve-my-database-interactions-code.407244/)
thread, and to ask if you have any questions. With that out
of the way, the first consideration for loading data is
when you will need to use the data. Obviously, you will
want to have the data when you need it. You can do this
just-in-time or use preloading.

When you load things just-in-time, this means that actions
which need the data trigger the load. For example, ranking
players will usually be just-in-time because if you want
player ranks, you usually want the most up-to-date version
and so you will simply load data when the rank command is
run.

On the other hand, you can also preload. There are many
opportunities to preload, such as preloading all of your
stored state upon the plugin enable or preloading certain
chunks or players when they are loaded or join the game.
In general, when you preload has a lot to do with memory
constraints. If you need to preload a lot of data, perhaps
it is better to do it when chunks are loaded or players
join the game to load the corresponding data for blocks in
that chunk and such. On the other hand, if you can fit all
of your data that you need into memory without much impact,
then it would obviously be a good idea to preload when the
server boots because that simplifies a lot of data
management code-wise. 

In terms of performance, it is always a good thing to
preload. In general, latency and memory are inversely
related. It takes more memory to organize data in a way
that reduces lookup latency. Therefore, if memory permits,
you should preload as much as you possibly can. Even when
you preload for events such as player joins, these have a
tangible performance hit because the system allocates
resources towards managing threads and executing syscalls
even for async queries. Since servers generally have a lot
of memory relative to computing power, it is worth
expending memory for performance gain.

With that being said, between just-in-time loading and
preloading the entire data store, I typically prefer to use
situational preloading such on player joins. This offers a
good compromise even if it does take away resources for a
brief time. I have personally not encountered any
real-world situations where this has not been the case. In
addition, this fits nicely with the storing data model,
which I discuss in the following sub-section.

#### Storing data

The main consideration for storing data is generally data
integrity. It is worth sacrificing some server resources to
ensure that the data in non-volatile memory is reasonably
up-to-date. In general, for any kind of persistent data, I
will have an autosave timer that will save all of the data
I have cached to the data store. I discuss this in detail
in [this](https://caojohnny.github.io/blog/2019/07/02/lessons-learned-debugging-part-5.html)
blog post, so read through that for more details. 

One relevant consideration that was only mentioned in brief
was that you must store all of your state during an
autosave in a consistent way. What this means is that if
you save multiple different files or databases, you must
save everything at the same exact snapshot, otherwise,
autosaving is worthless if the data that you save is all
at different moments in time. For example, let's say a
player inventory is saved, the player sells an item, and
then the player currency database is saved sometime later.
If the server crashes after that, then the player would
have the item they sold but with the currency they got from
selling that item, thus potentially having dramatic
ramifications for the server's economy if the server
crashes. The point is, it is a good idea to save the
relevant plugin state all together when you autosave.

You always need to write data at the end of the plugin's
lifetime. Player leave events are not called when the
server shuts down, so all player data and such that were
loaded needs to be saved in `JavaPlugin#onDisable()`.

Finally, any data that you load and then modify needs to be
stored. For example, as I discussed in the prior 
sub-section, you can load data just-in-time or preload
them. When the occaision to load the data ends, if any of
the data is modified, that needs to be flushed. For
example in the case of preloading, if you preload for
server boot, that needs to be written when the server
closes. If you preload on chunk load, you need to write
when that chunk unloads. When you load just-in-time and
the processing for that event ends, you should write that
data out. Again, making queries (even async) will consume
resources, but I think that doing so is worthwhile for the
purposes of data integrity. Obviously, if this is not
important, then you don't need to do so, but I find that
these 3 occaisions are the best times to store data.

#### Connection pooling

While I would like to keep this section generic to files
and databases, it is worth mentioning that if you do use a
database, you should use a connection pool.

A connection pool manages connections to the database. It
allows you to keep some connections alive and so that
repeated queries will not create new connections every
time. At the same time, these connections do not stay alive
forever, and will be closed when you are not using them to
conserve server resources. If you are working with
databases I highly recommend using a connection pool.

The industry standard connection pool is called
[HikariCP](https://github.com/brettwooldridge/HikariCP). A
full discussion on how this works and how you use
connection pools is out of scope for this blog post, but
I will again reiterate that it is something worth learning
on your own.

#### Asynchronous I/O

I will briefly cover the rule that I/O should always be
async at runtime.

When your plugin enables, you do not need to run I/O async
because you have an unlimited amount of time to setup your
plugin. I recommend using a timeout so that it doesn't take
too long if you have a networked database and that goes
down, for example, but the main point is that you don't
need to do I/O async in the `onEnable()`.

When your plugin disables, you do not need to run I/O async
because you are not permitted to schedule tasks for a
disabling plugin. The same point applies as for plugin
enables.

However, at any other point in time, you should **NEVER**
run any kind of I/O on the server main thread. Obtaining
connections from the connection pool, running queries to a
database, reading files, writing files, opening sockets and
such should be prohibited from the main thread. An OS can
take an unlimited amount of time to respond to syscalls and
a myriad of other issues such as system load, network
bandwidth, file system response times and other such
factors can cause I/O to block or hang the main thread.
This will cause the server to crash. Therefore, I will
again reiterate that you should never run I/O calls on the
main thread. Be aware that there are further complications
from the thread-safety issues of async tasks that are
outside the scope of this blog post.

#### Store-load dynamics

The final topic I would like to discuss when it comes to
storing and loading data is that it is very important that
stores and loads are coordinated. What I mean by this is
that when you store and load data, the data exists in two
locations: in your data storage medium and in your cache.
When you load data into your cache, you should only modify
data in the cache; if you are making changes to both the
cache and the data store, they will become out of sync with
each other and the cache will overwrite any prior changes
you have made to the data store since loading the data into
cache.

The way that I think about this is there must be a single
source of truth. Only one of your cache or your data store
must contain the most up-to-date time at any given moment
in time. When the server begins, the data store is the
source of truth. When you load one piece of data into your
cache, the cache becomes the source of truth for that one
piece of data. When you flush that data, the data store
again becomes your source of truth.

The point I am making is that each time your source of
truth changes, your plugin needs to know and then
coordinate how you store and load data in the plugin. As I
have mentioned that thread-safety is out of the scope of
this blog post, I will leave this topic as is with the
ending note that you need to synchronize each time the
source of truth changes.

# Conclusion

Having gone through this post, I hope that it will have
answered some questions about storing data. More
importantly, I hope that it has showed how the engineering
process works. Being able to gather information, make
decisions with that information, implement, test, evaluate
and iterate on your design and code is a very important
skill to have as a programmer. I hope that applying this to
the process of writing plugins makes you a better
programmer and a better engineer.

Happy New Years. Here's to 2021, starting off with this
post.

In the interest of completeness, this blog post was
compiled from the various bits of information I've posted
over the years on SpigotMC. If you are curious and would
like to read more or to see examples of contexts where the
information I have presented is used, I have a reading list
of posts [here](https://www.spigotmc.org/threads/best-practice-for-storing-player-data-currency-etc.476563/#post-4018642)
that may be of help.


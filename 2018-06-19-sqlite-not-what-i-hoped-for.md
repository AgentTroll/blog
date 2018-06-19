---
layout: post
title: "SQLite: Not What I Hoped For"
date: 2018-06-19T12:14:10-07:00
---

An issue with one of the plugins on MineSaga has recently brought to my attention the rather poor decision of using SQLite to store player data. Now we’re not even doing anything complicated with SQLite, it’s literally just used for persistence to track player data that gets updated occasionally. Even factoring in network latency, I don’t believe that SQLite will outperform MySQL for our particular use case.

In case you came here for the conclusion, and not the fluff, here’s what I learned:

  - SQLite scales terribly
  - MySQL outperforms SQLite in basically all cases
  - MySQL scales well with async requests
  - Index wherever it makes sense
  - Use `INSERT INTO … ON DUPLICATE KEY UPDATE` over `REPLACE`

# Background

I was actually planning on writing this post a while back, when Jurassic was just released. As it turns out, procrastination is a force to be reckoned with!

I believe we actually had to reboot Jurassic several times in order to get rid of the lag problems. About 9 hours in, the console was flooded with exceptions thrown from 9k async threads, all with the same error: `SQLITE_BUSY` from my points plugin.

I actually had a hard time believing that this was possible at first. I was in denial because how in the world could a database that is touted for its [reliability](https://www.sqlite.org/hirely.html) fail in such a stupid way? Why did such an obscure problem come up after months of using points in production? How in the world could there have been 9k failures just waiting to happen, when there weren’t even 9k unique players even on the server yet? None of the pieces fit together and I was stumped for a few days. Since the points plugin was actually designed originally to interact with a MySQL database, I imagined there might have been some kind of discrepancy that I did not account for when adding the SQLite feature in order to meet a critical release requirement, considering my relative inexperience with databases.

At the same time, there was a Minions issue that allowed players to use dropper blocks to duplicate minion eggs due to oversight when writing a dispense handler that was meant to be used for dispenser blocks only. I was dealing with 2 critical bugs at once, but I was told to put minions in the burner; points was kicking everyone off the server due to the laggy saves and minions wasn’t. Since I knew that the MySQL-enabled points worked fine, I decided to leave it with enabling MySQL and praying that the same issue doesn’t come up.

# Core Work

On top of the 2 critical bugs affecting the server, I was also working on minor bug fixes for bosses (also put on the burner) as well as polishing up the safety framework (which I will talk about at a later time!) in the core plugin. I already had JUnit tests setup in the core plugin to test the sanity of the database APIs, so where better to start than there to figure out how to reproduce the `SQLITE_BUSY` error.

After 24 hours of time to think after the initial crash, I was beginning to formulate a hypothesis on how the error could have occurred. I figured that with their experience in performance tuning, out good friends at Craftimize might have some ideas that I could work off of. I was fortunate to have them to bounce ideas off, and they suggested that there might have been a single event that spilled over and caused a chain reaction that led to the server eventually lagging out.

Piqued, I turned this idea around my head for a few hours. I also browsed through the Xerial SQLite driver source, as well as through the SQLite official docs to figure out how this exception would be thrown anyways. Eventually, I was able to boil down the issue to two possible causes, either because the file handle on the SQLite database has not been released yet due to using HikariCP, or because some arbitrary time limit has been exceeded (perhaps being caused by the first cause).

Since the Core unit test setup essentially used the same HikariCP configuration I used in points, I thought it might be a good idea actually to figure out the performance difference between MySQL and SQLite, seeing as we were using MySQL instead of SQLite now to store points data. The table schema for testing points is extremely simple, and it would make a perfect model to get a few ballpark numbers, as I was especially intrigued by the timeout.

# The Results

Since the code is proprietary, you’ll just have to trust me blindly here.

I decided to start out with around 9k rounds inserting just around 10 entries. This mimics what a server might see with the few players that were on compared to the amount of operations that were going on, also taking into consideration that players can join and leave multiple times and cause multiple database queries with for only a single player. I was hesitant to convert any of it into a transaction because that is simply not how most queries are going to work, they are mostly going to be quite sparse and not all clumped together until an autosave.

I was mildly surprised to find that SQLite was slower than a local MySQL server. However, that was not entirely unexpected, since SQLite is writing directly to a file and MySQL probably just queues disk writes.

What I was really surprised by, however, was how *fast* MySQL was. Using MySQL was several orders of a magnitude faster than SQLite was, by a factor of about 7x.

All that said and done, I still was not able to reproduce the bug. Maybe I’ll just have to try harder? Oh well.

I decided to actually compare both sync and async versions of writing to MySQL and SQLite and see how it might impact write throughput in an even more realistic scenario.

MySQL async, then sync results got printed out, starting on SQLite async. I was prepared to wait for several minutes so that all 9k entries get processed by the sloth of a DB engine that is SQLite.

What I was not prepared for was when it threw 9k `SQLITE_BUSY` exceptions…

# Found the Problem

Let’s put the two and two together now… SQLite worked fine synchronously, even though it took minutes to complete all of its writes. However, adding the async writes to the SQLite database causes the `SQLITE_BUSY` error. That can only mean one thing: my HikariCP pool to the SQLite DataSource is the cause of the error. Luckily, I knew the fix for this, having anticipated that this was the probable cause already. A simple call to `HikariConfig#setMaximumPoolSize(int)` will limit the pool and prevent additional connections from being created. When the pool was being used, the synchronization provided by the DataSource connection would have been useless because it wouldn’t be able to serialize access to the database from multiple connections.

As amazingly stupid as the issue might seem, it is only a testament to my poor knowledge of databases. When a connection pool was used, it’s actually quite amazing how the SQLite database was able to protect itself from a potentially dangerous write from two different connections by throwing an error instead of potentially corrupting the database. By limiting the connections to the database to 1, I was able to rerun the test, which passed with flying colors.

# Taking It a Step Further

With all the tests already setup, and my excitement at its peak having solved the crashing issue, I turned my sights to how indexing and database queries might affect the performance of a realistic server scenario. I ended up doing 8 tests for indexed and non-indexed keys, for `REPLACE` and `INSERT INTO … ON DUPLICATE KEY UPDATE` queries, and for 300 and 30 queries, just for the hell of it.

Here are the overall results.

#### Indexing

Indexing had honestly little effect on the results. I did not find any substantial difference between insertions of any volume or query that would have made indexing worthwhile. That said, I would still **always** add an index to my table because if it doesn’t hurt, might as well have it for the `SELECT` lookups.

#### Queries

I only tested `INSERT INTO … ON DUPLICATE KEY UPDATE` on MySQL, as SQLite did not have an equivalent query. What I found was that at more realistic, i.e. lower volume queries, there could be a 2x-8x magnitude increase in insertions if the `INSERT INTO… ON DUPLICATE KEY UPDATE` was used over `REPLACE`. [This article](http://code.openark.org/blog/mysql/replace-into-think-twice) seems to backup this claim as well. Therefore, **always** use `INSERT INTO … ON DUPLICATE KEY UPDATE` to perform upserts in MySQL.

#### Async vs Sync

Between all insertions done asynchronously in a 4 thread pool and synchronously, I found that although MySQL queries were consistently faster async than sync, except when at low volume. However, **always** use async firstly because it isn’t a good idea to run queries synchronously on a Bukkit server, and secondly because between 30 and 300 entries, async experiences only a 2x slowdown while sync experiences an 8x slowdown.

Async and sync makes very little difference on SQLite since the insertions are limited by the fact that all threads share the same connection anyways, but again, **always** use async, else you will freeze the Bukkit main thread.

#### MySQL vs SQLite

**Always** use MySQL when possible. Even at low volume of insertions, `INSERT INTO … ON DUPLICATE KEY UPDATE` still has a lower performance footprint than an SQLite `UPDATE`. At high volume, MySQL scales significantly better than SQLite, being up 5x faster than SQLite for 300 insertions.

# Closing Words

I definitely learned a lot about databases by going through this entire ordeal. While it was very frustrating to find out that my plugin was at fault for crashing, yet again (see my previous blog post for more about crashing), I would not have been motivated enough to go through and test for myself each of the little details involving databases. After all, it is the little details that separates the good from the great.

There will be lots of exciting things to come, both for MineSaga and for my blog in the coming few weeks as summer commences, so I’m definitely very hyped about that! Stay tuned.

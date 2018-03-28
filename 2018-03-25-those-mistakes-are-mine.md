---
layout: post
title: "Those Mistakes Are Mine"
date: 2018-03-25T01:19:25-07:00
---

> Minions is a shit plugin
>
>   \- @GulliblexD

Minions was included as a part of the initial MineSaga release a little over 2 months ago.

Depending on the way you look at it, the plugin might never make it to the grave, or it has entered it from the beginning.

All the bugs in the minions plugin? Yeah. Those mistakes are mine.

# Replication

One of the hardest things to understand about the plugin is that it is exceedingly difficult to test in a reasonable time frame. It is difficult to determine how the plugin will interact *in prod* versus in a test environment. On top of that, the internal architecture of the plugin has changed repeatedly, as have the requirements.

On top of that, the minions internals deals with incredibly time-sensitive server ticking and chunk mechanics. There are no compromises made to sacrifice performance in these areas, further compounding the problems with replication. Some of the decisions I've made have regretfully created many, many insidious bugs that don't show up until it is in prod.

The Minecraft server behaves differently in the large monoworld that holds all the skyblock islands than it does in a server with 1-2 players that are testing it. Each incremental update introduces more features that must be tested within the spawn area and outsdide of it, inside the player vision and outside, with chunks loaded and without chunks loaded, and then again for all the modes and then serialized and tested again serialized with and without chunks loaded. The random minion disappear bug? Never been able to have chunks do that without manually unloading the chunk myself.

I have spent several hours testing minions on multiple releases in order to make sure that they are bug free, but for 90% of the releases, I simply skipped this testing phase. I decided that it was not worth my time to be fruitlessly looking for some new way that the server will decide to interact with minions: only in prod deployment will effectively find the bugs that I am looking for. In hindsight, I think this has led to a lot more pressure on part of the owners and something that, admittedly, I have still yet to fix.

The gist of it is that minions is doing what the Minecraft server never intended it to do. Custom entity, chunk retention, memory persistence. In the past, when I worked on TridentSDK, I was the one that wrote the entity handler code, and I was able to know exactly what would happen to entities in so and so instance. Minions was one of the first major shifts I had away from that experience because the entities that I am creating are at whim of the server, which consists of millions of lines of obfuscated code. The only real way to understand what the server is doing is to look at the effects of certain pertinent actions and make a guess about what is going on. You know, much like how people put chunk loader minions beneath their farms and then blame me for the farms not working (hint: its your hoppers!) because their experimental design sucks.

As it turns out, I still have no clue where your minions are going.

# Data Loss

I think that there have been two major occasions where all minions were totally lost, although I'm not completely sure since I have not been shared that information (one of them being a server crash due to DDoS).

The lesson to take from this, and from today's breach is that it pays to get it right the first time.

It pays to have implemented serialization safeties the first time.

It pays to have implemented a way for players to `/minion recover` the first time.

It pays to have tested the plugin more extensively the first time.

Alas, for I am only human. I make mistakes. I did/do not write much right the first time. This is true for the few other plugins I have written running on MineSaga, but I think that this is especially true for Minions, mostly for the reasons that I will be discussing in the next section.

I'd say that it is even fortunate that minions was a horrible plugin at the opportune time that the server was attacked; all plugins that I've made since then have implemented much more meticulous data-loss prevention measures and exception handling in order to salvage data if needed. Perhaps if the server was hit a little later down the road, the results might have been different had I not had this experience to learn from.

# Complexity

I'll reiterate again that what minions does, the Minecraft server was never designed to handle. The minions themselves are basically just zombie entities that I "tricked" into emulating the functions of a player. On top of that, there are many technicalities that I never foresaw, most notably the way that blocks moved by pistons are handled. For those that aren't aware, blocks moved by pistons are temporarily turned into "a part of the piston" (I suppose?). This had to be blacklisted from minions in order for blocks pushed by them to be handled correctly. As it turns out, it also only happens with level 2 minions due to their faster mining speed (another function that required many, many hours of thought and experimentation to get down) and how it syncs with the speed at which cobble is generated and pushed by the piston.

In another case, the attacking modes require chest checks in order for the minion to halt attacking if the inventory is full. As it turns out, there is no way to "test" if the item fits without doing a huge if/else chain, and so the item is eager-added to the chest and checked for inclusion. This works will for mining modes, where the items are deterministic, but for entity drops, it is harder to deal with. The simplest way to do this was to constantly check if there is an extra slot in the chest, because I'm not going to spawn another entity if those drops fail to get placed into the chest.

Each component extends and creates its own problems because there are many "moving parts" interacting with each other in order to create the minions. These components are at worst hacks, and at best, "clever workarounds" to circumvent the Minecraft server. This makes it difficult to test and difficult to verify, inducing bugs all over the place. On the contrary, other plugins such as Quests and Points are basically a simple back-end infrastructure to handle a few additional variables and accomodations for menus, which are well-understood and have been tried and tested multitudes of times. Not so much for the very niche functions that minions try to emulate.

# High Maintenence Cost

Lastly, minions not only has problems of its own, but it creates problems for others. From falling into the void, duplicating randomly, not serializing correctly, and simply disappearing into thin air, there are so many issues with it that *other* people had to deal with as well. It created hardships for the ownership team, who had to handle all these cases and compensate players for missing minions - they are, after all, paid with IRL money - and created hardships for the rest of the staff team, who had to relay and deal with issues they were not familiar with on a daily basis as a result of players asking about their minions.

One of the things that I kept falling into was the notion that the "minions update" will be a good time to fix all these issues and basically turn minions into an actually functional plugin. In hindsight, however, I'd say that my decision to continue putting time into getting out updates and fixing bugs was a much more prudent course of action than if I had waited. I know this put an additional burden on the owners, who had to update the plugin endlessly on each realm, but I honestly am glad that I put them through that. Although the players may not like having a buggy plugin all the time, I think that without having such a short development pipeline most definitely prevented future grievences. I really have learned a whole lot about entities, having been able to experiment and verify bugs reported by players, and if not now, bugs of a similar vein might come up later on. Future plugins may be written faster and more bug-free as a result of having already done these tests and made changes that are verifiably functional.

# Closing Words

I know that there have been (many) problems with minions. I know that it's a massive waste of time to deal with the side effects of it. The owners know it too, and when it is said that "minions is a shit plugin," it is said only half-jokingly, because the reality is that there were many things wrong with it, and there will still be many things to come that I haven't spotted yet.

Yet on the other hand, given the circumstances, I don't think minions is a bad plugin. Of course, I wrote it, so there's no reason for me to think that it is. I think that it is a really nifty concept, and there's always a worse place the plugin could be compared to where it is/has been. There have only been 2 instances where minions didn't do what they were supposed to do for players, and both times were when blocks were being pushed by pistons. All taken, I would say that it was a relative success in spite of the significant number of bumps in the road.

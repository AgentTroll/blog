---
layout: post
title: "Increasing The Player Count"
date: 2018-03-03T01:19:40-07:00
---

Gosh its been a while actually for a 2 things: firstly, the 1 year anniversary of the first post on this blog is fast approaching, and two, I've been with Intermissum for around 6 months now.

Speaking of Intermissum, we've been growing well over the past month and some that we've released. The player average is a good 550 to 600 depending on the day and and the time, and the most recent 2 realms, Western and Jurassic have been at absolute capacity almost every day for the past week or so. Which brings me to my next point...

We've been asked MULTITUDES of times to increase the player count on the Western realm, the most popular server:

![more slots]({{ site.url }}/blog/img/increasing-player-count-1.png)

![more slots]({{ site.url }}/blog/img/increasing-player-count-2.png)

![more slots]({{ site.url }}/blog/img/increasing-player-count-3.png)

![more slots]({{ site.url }}/blog/img/increasing-player-count-4.png)

![more slots]({{ site.url }}/blog/img/increasing-player-count-5.png)

![more slots]({{ site.url }}/blog/img/increasing-player-count-6.png)

![more slots]({{ site.url }}/blog/img/increasing-player-count-7.png)

![more slots]({{ site.url }}/blog/img/increasing-player-count-8.png)

![more slots]({{ site.url }}/blog/img/increasing-player-count-9.png)

No means no you guys.

# Performance

What some people have a hard time understanding is that the player count is basically the root of all performance problems on a server. The reason why the server experiences lag and missed ticks is because there are too many people online at a time. What makes this issue even worse is that the Western realm is a farm/crop based economy, which means that on top of all the players, the server must also handle the monolithic farms that people are building.

Our first important point: **The effect of adding more slots amplifies the strain on the server produced by resources associated with that player**

The slot limit on each realm is not "just a number." A player joining a server is not as simple as incrementing some imaginary counter. Each player consumes a LARGE amount of resources needed to support the experience provided by the server: chunks loaded, net IO handled, ALL crops on that player's island being ticked, etc...

Since I do not have exact chunk-loading stats on hand at the time of writing, I'll use a very conservative figure of entities produced by all the islands to estimate the impact of adding more slots. At any given time, the Western `Islands` world contains around 16,000 entities, which might not sound like much (indeed, as it is not much at all), but hang with me here. Given the 200 player capacity, that's 80 entities loaded per player, the conservative estimate compensating for players loading the same entities (i.e. players on the same island). 

Say that we bump up a "small" 25 additional slots. That means loading an additional 2000 entities on the server - and that's just 25 players!

The point I'm trying to communicate here is that if the server load is thought of in terms of resources that each player takes up, instead of the "few slots" increase, we are actually compounding the increase by a factor of 80 for each additional player.

Now again, we are just estimating here, and each player does not actually amplify the load placed on the server by a factor of 80 (it is much less). However, it goes to show my point that players are expensive not in themselves, but rather in their effects.

In fact, to further demonstrate my point, let us not use entities (which are a better representation of the resources associated with a player because players are a subset of entities), but rather blocks. A chunk consists of a 16x16x256 section of blocks, 65536 in total. To make our calculations easier, let us assume that only about 1/12 of those blocks are actually cacti, making a single chunk require 5461 cacti to tick. A player loads around 150 chunks on a server, depending on the limits set by the owner, but for ease of calcualation, let us assume that a player only loads 25 chunks worth of cactus farm. Then, adding a single player will not only require the server to handle an additional player, but also 136525 worth of cacti to grow, 20 times in a single second! Accounting for players who are not loading their whole cactus farm and those whose farms are far larger, a reasonable estimate for the number of cacti to process comes out to about 100k times 225, or about 22,500,000 blocks.

# User Experience

Secondly, while I am not going to disclose exact stats, the server for sure does not run at 20 TPS, even capped at 200 players. There is a very simple reason here:

**The server has a limited amount of time to complete tasks**

The age of cacti is incrememnted randomly 20 times per second, each tick that the server runs. If all the cacti on the server have been processed before the end of the tick, that's good! The server will in fact, pause and not do anything until the beginning of the next tick, where all the cacti will again be processed, and so on.

Things get a little more complicated when the amount of time needed to complete the task overruns the time allocated to the tick. In the space of 20 seconds, 400 ticks *should* be run. However, if each tick overruns itself by, oh, an extra tick, then only 200 ticks will be run in that same amount of time. This means that 200 ticks are "lost" because there was only enough time to increase the age of each block the first 200 times.

Why is this important?

The crops are already growing at about half speed.

By adding more players, the effect is that crops will slow down. There is no limit to the amount of slowdown that can be acheived as long as no player disconnects from the server. As each tick takes longer and longer, it is possible for it to overrun 1 second, 2 seconds, etc...

The argument here is that your crops all seem to grow slowly because all the other players are taking care of and loading in these humongous farms (22,500,000 blocks to be more preceise). Adding more players will also slow down your crops even more.

When people think selfishly and want only their singular goal to be fulfilled, it detriments the experience of others who are waiting for their crops to grow, and eventaully, when you yourself finally do join the server thanks to the 500 player cap, you will be complaining about how the crops don't grow at all.

# Server Hardware

So why not get a better computer?

Unfortunately **the server runs on the highest tier hardware available to us**.

![less slots]({{ site.url }}/blog/img/increasing-player-count-10.png)

# Queueing

People have been having problems joining full realms because, well, they're full *all the time*.

So instead of having people stand and try to spam click on the Western NPC, a queue was implemented to allow players to wait to be teleported to the realm.

Now, the problem isn't that the server is full all the time, it's that peoples' place in the queue don't change, or even go up.

Then there's people who buy the Buckaroo rank and think they're supposed to be 1st in the queue.

The queue prioritizes staff members, youtubers, donators *descending by rank*, and finally regular players. Bought a rank but not 1st in line? Thanks for supporting us. But you'll have to wait your turn. This order helps benefit *all parties* involved:

  - Owners/developers/admins/most lower-level staff do not play the game, we're here purely to help people and to moderate
  - YouTubers bring content to the community and bring the community to us, growing our own revenue base and supporting content that goes directly back to players
  - Donators are in the same deal as with YouTubers

Donators are also queued by rank as well. I'm not an economist, but this is just basic economic theory: scarcity of resources (i.e. player slots), money is a medium through which access to limited resources is controlled. It sounds P2W and all, but it is not; everyone is paying to wait in line ("except" for upper-level staff). Those who have more money gain access to the "limited resource" (i.e. player slot) first, because they have helped support the server more. In the end, everyone has the chance to access the server. On top of that, Western is not a donator-only realm. There are several non-ranked players who play on Western even at peak hours, which means that even the lowest ranked players have the opportunity to join the server.

Finally, a kick-based model will never be used in the forseeable future. In this model, players are kicked out rather than having to wait if there are not enough slots. This is a horrendous and unfair system that makes joining the server totally P2W. Based on the number of donators on Western, it would be easy to kick out ALL non-ranked players, if not a large number of the lower-ranked players as well. Then, the complaint will not be that the queue is too long; it will be that people are getting "randomly kicked" and that the system is "unfair" because rich people still have the advantage. If the queue model is P2W, then the kick model will be even more so.

Yeah, we're sticking with the queue system.

# Closing Thoughts

I hoped that through my endless rambling and criticism that I've cleared up some thoughts that people have had regarding the slot availability on MineSaga. We are not going to increase the slots or get rid of the queue because it is simply the most effective way that we have so far to manage the limited resources availible to the server.

There have been multiple discussions privately about how to distribute computing power and divide up how the different realms and islands are managed. I do not feel comfortable sharing those details without approval so they remain purely for speculation at the moment. Stay tuned! :)

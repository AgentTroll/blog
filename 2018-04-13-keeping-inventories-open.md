---
layout: post
title: "Keeping Inventories Open"
date: 2018-04-13T21:38:10-07:00
---

*Note: Code samples in this post have been slightly altered. I have not leaked any information from our plugins in the writing of this post*

Over the past week or two, we've been working hard to get the gambling plugin fixed up for you guys to use. Unfortunately, there were a few interesting bumps in the road.

# Crashing Issue

One of the features of coinflips was that once the inventory that flips between the heads opens, it will not close until the coinflip is over. We did this by re-opening the inventory whenever it was closed. It basically looked something like this:

``` java
@EventHandler
public void onPlayerCloseInventory(InventoryCloseEvent event) {
    if (this.menuIsCoinflip) {
        // Schedule the inventory to be opened after the next tick
        Bukkit.getScheduler().runTask(this.plugin, () -> {
            // Tell the player to open the inventory that they closed
            event.getPlayer().openInventory(event.getInventory());
        });
    }
}
```

What we found, however, was that for some reason, this handler would become stuck in a loop and prevent the main thread from proceeding. There is nothing overtly wrong about this method, really, it literally performs the correct handling for it after "the next tick."

From the [Bukkit Scheduler javadoc](https://hub.spigotmc.org/javadocs/spigot/org/bukkit/scheduler/BukkitScheduler.html#runTask-org.bukkit.plugin.Plugin-java.lang.Runnable-):

> BukkitTask runTask(Plugin plugin,
>                    java.lang.Runnable task)
>             throws java.lang.IllegalArgumentException
>
> Returns a task that will run on the next server tick.

In fact, it was even more confusing because we had no clue how a scheduled task could possibly be creating an endless loop, much less how players could get themselves into a situation that would cause the loop in the first place.

# Initial attempts

Since we already isolated the problem to the close event handler, we assumed that the problem would stem from the player being offline when they are told to re-open the coinflip inventory. We added in a check once the task gets run on the inside of the lambda, and then made sure that when a player leaves, they would be not be allowed to re-open the menu:

``` java
@EventHandler
public void onPlayerCloseInventory(InventoryCloseEvent event) {
    if (this.menuIsCoinflip) {
        // Schedule the inventory to be opened after the next tick
        Bukkit.getScheduler().runTask(this.plugin, () -> {
            if (event.getPlayer().isOnline()) {
                // Tell the player to open the inventory that they closed
                event.getPlayer().openInventory(event.getInventory());
            }
        });
    }
}

@EventHandler
public void onPlayerLeaveServer(PlayerQuitEvent event) {
    // Do not allow the menu to open
    this.menuIsCoinflip = false;
}
```

However, this also did not work. The next morning, we found that the server crashed from the same recursive loop somehow.

I then dug into the code to see what was going on behind-the-scenes. I wanted to find out why the player is still allowed to open the inventory even when they are offline. This is a snippet of code that handles the [player's disconnect](https://hub.spigotmc.org/stash/projects/SPIGOT/repos/craftbukkit/browse/nms-patches/PlayerList.patch#281):

``` patch
+        org.bukkit.craftbukkit.event.CraftEventFactory.handleInventoryCloseEvent(entityplayer);
+
+        PlayerQuitEvent playerQuitEvent = new PlayerQuitEvent(cserver.getPlayer(entityplayer), "\u00A7e" + entityplayer.getName() + " left the game");
+        cserver.getPluginManager().callEvent(playerQuitEvent);
+        entityplayer.getBukkitEntity().disconnect(playerQuitEvent.getQuitMessage());
+
+        entityplayer.playerTick();// SPIGOT-924
+        // CraftBukkit end
+
         this.savePlayerFile(entityplayer);
         if (entityplayer.isPassenger()) {
             Entity entity = entityplayer.getVehicle();
@@ -318,17 +421,67 @@

         if (entityplayer1 == entityplayer) {
             this.j.remove(uuid);
```

There are 3 things to note here:

  1. `handleInventoryCloseEvent` is called very early when the player disconnects
  2. `PlayerQuitEvent` gets fired after that
  3. `Player#isOnline()` and `Bukkit.getPlayer(...)` provided by the `j` collection will be signalled last

This might make our online check seem useless, however, there shouldn't be any cause for concern, because the scheduler should be scheduling the inventory close by the next tick, once the handler has fully completed and removed the player from the server... Right?

# Nitty Gritty of the Scheduler

We can theorize all we want. The code looks correct, but obviously that is not so because the server is still crashing for the same reason. Therefore, either we are wrong about our isolation of the problem, or our assumption about what the server is doing is wrong. However, given that the bug is very timing-dependent, and players are more likely to be leaving during the night, when the server is crashing, we concluded that our logic must have been wrong somewhere.

After some more pondering and searching through the Minecraft source code, I looked over the line that calls the `mainThreadHeartbeat` method in `CraftScheduler`. Piqued, I looked through the source of `CraftScheduler` to see what I could find.

[`runTask`](https://hub.spigotmc.org/stash/projects/SPIGOT/repos/craftbukkit/browse/src/main/java/org/bukkit/craftbukkit/scheduler/CraftScheduler.java#91):

``` java
public BukkitTask runTask(Plugin plugin, Runnable runnable) {
    return runTaskLater(plugin, runnable, 0L);
}
```

I thought to myself: when an inventory closes, I must be in the `disconnect` method from `PlayerList` above, so there can never be an instantaneous execution from this method. However, the fact that the server simply stops responding is completely contradictory to this.

Then it dawned upon me.

`openInventory` must be immediately firing `InventoryCloseEvent` when the player is offline, since it closes immediately; the player isn't even there to open it in the first place. It doesn't need to be going through `PlayerList#disconnect(...)`. This basically invalidates all previous assumptions about the calling location of `InventoryCloseEvent`...

If I immediately get back `InventoryCloseEvent` from opening the inventory, then I am not getting the event from `PlayerList#disconnect(...)`... I am getting it *directly from the scheduler*. The scheduled task is causing it to schedule more tasks, which must execute, because the scheduling loop has not finished when I run another task! In other words, `InventoryCloseEvent` causes another task to be added to the loop through the tasks in `mainThreadHeartbeat`. Since we are still in a loop at this point, the loop will then come across the next task, which will then create another close event, endlessly adding tasks to the scheduling loop. `mainThreadHeartbeat` never exits, and so the server doesn't tick!

# Fixing The Issue

`runTask` is a good, short method to use when not being called from within the scheduling loop. However, this risks creating an infinitely long task list. The fix to schedule for exactly 1 tick later like so:

``` java
@EventHandler
public void onPlayerCloseInventory(InventoryCloseEvent event) {
    if (this.menuIsCoinflip) {
        // Schedule the inventory to be opened after the next tick
        Bukkit.getScheduler().runTaskLater(this.plugin, () -> {
            if (event.getPlayer().isOnline()) {
                // Tell the player to open the inventory that they closed
                event.getPlayer().openInventory(event.getInventory());
            }
        }, 1L);
    }
}
```

This has virtually no impact on the previous functionality. By scheduling for 1 tick later instead of the 0 ticks that the `runTask` method does, we ensure that even if `InventoryCloseEvent` is fired from within the scheduling loop, it will not run within the loop that created it, but rather on the next tick. Since `runTask` is usually never called from inside of the tick loop, 1 tick usually needs to pass anyways unless the task gets scheduled before the scheduling loop runs, so there's really nothing to lose.

# Conclusion

The reason why it took so long for this bug to be discovered is because of the assumption I made that `BukkitScheduler#runTask(...)` will always run in the tick after it is being called in. However, when the docs mention that a task will be run "run on the next server tick," the next server tick may already be in progress, and therefore never allow for the task to leave.

In hindsight, it may seem like such a stupid assumption to make, that this particular event may be fired in only in one place. How can a problem that is so face-smackingly simple get past us? We were tied up for over a week trying to figure out what made the servers crash due to this bug. The server log gave a hint that the close event listener was being fired from within the scheduler, however, I did not pick up on this. Higher up the stack, the inventory was being closed already in the task, so why should I assume that the task list is growing? I just thought that it was being run in the tick right after the close event.

This little assumption, that the `runTask` method would run the the tick after the task gets scheduled, led to over a week worth of head scratching and frustration. What can be done in the future about it?

We've already got reboot scripts ready to go so servers do not experience as long as a downtime. This only fixes the effects of such bugs; but at the moment, I have no solutions to how the development pipeline can be modified to avoid this in the future. Perhaps strong assumptions about the workings of the scheduler should not be so dearly held on to. Local tests could not have reproduced this bug, tests on production servers by Gullible only turned up the bug once or twice. Theoretically, this should always be turning up when the player that joins a coinflip gets kicked or leaves the server, so why wasn't it more common during testing? How could it have been more adequately tested?

I don't know. It's ironic because solving this bug creates an even harder problem: how to prevent it. And I have a sneaking feeling that I will need to get around to solving it soon.

# Additional Edit (2018-04-14 00:40:05)

Some readers may be confused as to how `InventoryCloseEvent` ends up in the same scheduling loop at all if the first instance that it is called is through `PlayerList#disconnect(...)`. They reason that since `runTask` already schedules for the next tick, all the cleanup would be done and the cycle would never start. The answer to that is: I really have no idea. I know that Essentials kicks players from within a task, so it's possible that an AFK kick could be causing this, but AFK timers are disabled so I doubt that. I doubt that it is a problem from within the server, because the server doesn't use the scheduler to process async tasks. Either way, it doesn't matter what would cause the the loop because whatever is kicking the player is doing it correctly; the inventory itself is not being handled correctly and that is what got fixed.

---
layout: post
title: "Multi Conditionals"
date: 2017-12-21T01:00:00-07:00
---

There have been actually several times as I’m writing servers in things like my JDB project and the TridentSDK project in which the following scenario pops up: there is a single thread that manages incoming and outgoing messages. I need to block on an outgoing queue, as well as block until some bytes off the network are read.

My situation looks something like the following:

``` java
BlockingQueue<Message> incoming;
BlockingQueue<Message> outgoing;

while (true) {
    if (hasInput()) {
        // Read into incoming
    } else if (!outgoing.isEmpty()) {
        // Write from outgoing
    } else {
        // Block, wait for input or output
    }
}

boolean hasInput();
Data waitForInput();
void writeToOutput(Message send);
```

Message consumers will block on the `incoming` queue and wait for input from the socket to be read by the I/O loop in order to process those messages.

Given this scenario, how might the I/O loop be implemented in order to block on network input as well as the `outgoing` queue and wait until either of the two have I/O tasks to execute?

# Naive Solution: Subsequent `take()`s

A simple, first-thought, although naive solution might look something like the following:

``` java
while (true) {
    Message recv = new Message(waitForInput());
    incoming.add(recv);

    Message send = outgoing.take();
    writeToOutput(send);
}
```

This will not work correctly. Because the loop must wait for input, the second blocking method, `outgoing.take()`, will not be reached until a message is received. Therefore, a message that is queued to be sent cannot be unless something is received first - and what if the client is written in the same way? There will be a deadlock because the client must depend on input from the server in order to send a message, but the server is in fact also waiting to receive a message that will never come from the waiting client.

So it can be seen that this method both does not work as intended and will cause risks with client-server deadlock.

# Naive Solution: Single lock/Condition

A second tempting solution is to protect the `incoming` queue and the `outgoing` queue with a single lock/`Condition`.

Assuming the same context:

``` java
Lock lock = new ReentrantLock();
Condition cond = lock.newCondition();

while (true) {
    // Await for a signal from a message producer
    // adding to the outgoing queue
    // Spurious wakeup checked by conditions below
    cond.await();

    if (hasInput()) {
        Message recv = new Message(waitForInput());
        if (recv != null) {
            lock.lock();
            try {
                incoming.add(recv);
                cond.signal(); // Signal the message consumer
            } else {
                lock.unlock();
            }
        }
    }

    Message send;
    lock.lock();
    try {
        send = outgoing.poll();
    } finally {
        lock.unlock();
    }

    if (send != null) {
        writeToOutput(send);
    }
}
```

However, there still exists several issues with this code. Firstly, `cond.await()` will block only on the outgoing queue, and ignore network input. This will have the opposite effect as the earlier naive solution in which there requires network input for there to be output; in this case, the I/O thread will, in fact, have to wait for output in order for input to be read.

In truth, we can try all different kinds of combinations of switching different `Condition`s and different mechanisms of all sorts without succeeding, there is simply no way to wait on both the reading from socket and simultaneously the outgoing queue. Further, a thread blocked on network input is not blocked on a lock or `Condition` or whatever - it remains in `RUNNABLE` mode, so it might as well be busy waiting for all other observers can care. After exhausting these ideas, I too thought that it would be impossible to act on events rather than having to use a timer and step over the other blocked method in order to check either input or output depending on what is blocked.

Fortunately, there is a way.

# The Solution

In order for my I/O thread to correctly handle I/O input, it must be interruptible. Thankfully, by switching to `java.nio`, this functionality can be achieved with `InterruptibleChannel`. I was able to override the default interrupt handler and use the following little utility I made to notify the I/O thread:

``` java
import sun.nio.ch.Interruptible;

import java.lang.reflect.Field;
import java.nio.channels.SocketChannel;

/**
 * Utility class used to modify {@link SocketChannel}s in
 * order to override the default behavior and allow for I/O
 * threads to capture {@link Signal}s passed while waiting
 * for input.
 *
 * <p>Be aware that this is an extremely egregious hack.
 * For the most part, it is a toy. I don't expect that
 * anyone would seriously consider using this in production,
 * but if there is any case where that occurs, I am not
 * responsible for what happens. Use at your own risk. You
 * have been warned.</p>
 *
 * <p>To add further to the risks associated with this
 * class, one must <strong>NEVER</strong> call {@link
 * Thread#interrupt()} on an I/O thread. Doing so may
 * result in undefined behavior. Capturing a {@link Signal}
 * also means that the I/O thread must use
 * {@link Thread#interrupted()} in order to clear the
 * interrupt state before the next signal. Finally,
 * {@link Thread#interrupt()} is used in order to propagate
 * signals to the I/O thread, and therefore, if any methods
 * that are interruptible must catch the exception and run
 * {@link Thread#interrupted()}.</p>
 */
public final class SocketInterruptUtil {
    /** The cached field used to hack the SocketChannel */
    private static final Field INTERRUPTOR;
    /** The signal used to notify readers */
    private static final Signal SIGNAL = new Signal();

    static {
        try {
            Class<?> cls = Class.forName("java.nio.channels.spi.AbstractInterruptibleChannel");
            INTERRUPTOR = cls.getDeclaredField("interruptor");
            INTERRUPTOR.setAccessible(true);
        } catch (NoSuchFieldException e) {
            System.out.println("No such field: interruptor");
            System.out.println("Perhaps not running Oracle HotSpot?");
            throw new RuntimeException(e);
        } catch (ClassNotFoundException e) {
            System.out.println("No such class: AbstractInterruptibleChannel");
            System.out.println("Perhaps not running Oracle HotSpot?");
            throw new RuntimeException(e);
        }
    }

    // Suppress instantiation
    private SocketInterruptUtil() {
    }

    /**
     * Prepares the {@link SocketChannel} to receive
     * {@link Signal}s dispatched by another thread. This
     * is required in order for this to work correctly.
     *
     * @param ch the channel to prepare
     */
    public static void prepare(SocketChannel ch) {
        try {
            INTERRUPTOR.set(ch, (Interruptible) thread -> {
                throw SIGNAL;
            });
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        }
    }

    /**
     * Signals the given I/O thread to unblock from ALL
     * blocking methods and proceed and throws a
     * {@link Signal} to be handled by the thread.
     *
     * @param thread the thread to unblock
     */
    public static void signal(Thread thread) {
        try {
            // Thread probably not blocked on I/O
            if (thread.getState() != Thread.State.RUNNABLE) {
                return;
            }
            thread.interrupt();
        } catch (Signal ignored) {
        }
    }

    /**
     * A signal dispatched by another thread to a target
     * I/O thread in order for targets to respond to
     * notifications.
     */
    public static class Signal extends RuntimeException {
        private static final long serialVersionUID = -220295899772322553L;
    }
}
```

A correct usage of the class would look something like the following:

``` java
ServerSocketChannel server = ServerSocketChannel.open();
...
while (true) {
    SocketChannel ch = server.accept();
    SocketInterruptUtil.prepare(ch);

    while (ch.isOpen()) {
        try {
            ByteBuffer buf = ...
            ch.read(buf);

            Message msg = new Message(buf);
            incoming.add(msg);
        } catch (Signal signal) {
            Message msg = outgoing.poll();
            writeToOutput(msg);

            Thread.interrupted();
        } catch (InterruptedException e) {
            Thread.interrupted();
        }
    }

    // Normally you would also need to have another
    // catch for Signal/InterruptedException here
    // However, you'd also need to check to make
    // sure that there is an active connection, so
    // I can just check to make sure that there is
    // at least a connected SocketChannel before
    // signalling and get rid of the try/catch.
}
```

And for the outgoing logic:

``` java
outgoing.add(msg);
SocketInterruptUtil.signal(ioThread);
```

# Discussion

In order for this to work, I made a slightly (OK, really) hacky solution to default `InterruptibleChannel` functionality. I found that what `InterruptibleChannel` did was put an interrupt listener before every single blocking call in order to close the socket if either the blocked thread is interrupted or if the socket was closed. I couldn’t put in my own handler because I can only override before or after the blocking method, in which my own handler would be overridden by the interrupt handler provided by the method itself. Therefore, I went one step deeper and overrode the cached instance of the interrupt handler inside of `InterruptibleChannel` to exit early and throw my own Signal which can be caught by the I/O thread.

I haven’t deeply investigated the performance of this method over perhaps timed busy waiting, but from testing, a blocked read can respond to signals in sub-millisecond times even when saturated with messages between “10 nanosecond intervals” on an i3-3240. A `while` loop probably takes more than 10ns to run which is why I mention that rate in quotes, but again, this time is very impressive even if it’s off by a bit. You wouldn’t want to be waking a thread every 1 millisecond in order to check for the other condition, which is why I say that it’s good in comparison with the alternative.

Unfortunately, this technique is risky in many ways, first of all, because it depends on there being the `AbstractInterruptibleChannel` SPI class being available, as well as the field being available. The field probably won’t be going away because caching is required, but the class itself might. Additionally, the interrupt status of the thread is risky to play around with and requires `Thread.interrupted()` to be called each time either Signal is thrown or InterruptedException is captured if the `signal(Thread)` method misses the I/O portion. Otherwise, the thread itself might die. Finally, the only possible way to exit directly out of a blocking `read(...)` is to throw the exception, but if a read is halfway done, then the behavior may be undefined. I will need to test further in order to determine what happens, but until then, this class still remains a very risky hack. I would highly advise against using it in a production environment, regardless of whatever performance gains may bear fruit through event-driven notifications rather than spurious wakeups. I have included a warning in the class javadoc comment to cover my ass, so please don’t push it :)

In the end, even though I have acheived what I was hoping for, even if it isn’t really viable in the real-world, I guess I will just have to keep searching for a better solution.

# Closing Words
Figuring this all out was an interesting use of 3 hours. I’m completely done with this though, I’m not looking to play around anymore with it, but anyone else can feel free to do so themself. My plan is to update the “On Thread Safety” post very soon though, and there is more to come over winter break. Take care everyone!
